/**
 * Propulsion System Tests
 *
 * Tests thrusters, fuel consumption, power usage, thermal generation
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  PropulsionSystem,
  ThrusterConfig,
  ThrusterType,
  PropellantType,
  FuelTankInterface,
  PowerBudgetInterface
} from '../src/propulsion-system';
import { Vector3 } from '../src/math-utils';

// Mock fuel tank
class MockFuelTank implements FuelTankInterface {
  constructor(
    private mass: number,
    private pressure: number = 101325
  ) {}

  getCurrentMass(): number {
    return this.mass;
  }

  consume(amount: number): boolean {
    if (this.mass >= amount) {
      this.mass -= amount;
      return true;
    }
    return false;
  }

  getPressure(): number {
    return this.pressure;
  }

  setPressure(p: number): void {
    this.pressure = p;
  }
}

// Mock power budget
class MockPowerBudget implements PowerBudgetInterface {
  constructor(private availablePower: number) {}

  requestPower(consumerId: string, amount: number): boolean {
    return this.availablePower >= amount;
  }

  setAvailablePower(power: number): void {
    this.availablePower = power;
  }
}

describe('Propulsion System', () => {
  let propulsion: PropulsionSystem;
  let fuelTank: MockFuelTank;
  let powerBudget: MockPowerBudget;

  beforeEach(() => {
    propulsion = new PropulsionSystem();
    fuelTank = new MockFuelTank(1000);  // 1000 kg fuel
    powerBudget = new MockPowerBudget(100);  // 100 kW available
  });

  describe('Thruster Configuration', () => {
    it('should add thruster to system', () => {
      const config: ThrusterConfig = createMainEngine('main-1');
      propulsion.addThruster(config);

      const retrievedConfig = propulsion.getThrusterConfig('main-1');
      expect(retrievedConfig).toBeDefined();
      expect(retrievedConfig!.id).toBe('main-1');
    });

    it('should initialize thruster state', () => {
      const config: ThrusterConfig = createMainEngine('main-2');
      propulsion.addThruster(config);

      const state = propulsion.getThrusterState('main-2');
      expect(state).toBeDefined();
      expect(state!.enabled).toBe(false);
      expect(state!.throttle).toBe(0);
      expect(state!.actualThrust).toBe(0);
      expect(state!.integrity).toBe(1.0);
    });
  });

  describe('Thrust Control', () => {
    it('should fire thruster at specified throttle', () => {
      const config: ThrusterConfig = createMainEngine('main-3');
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      const success = propulsion.fireThruster('main-3', 0.8);

      expect(success).toBe(true);
      const state = propulsion.getThrusterState('main-3');
      expect(state!.enabled).toBe(true);
      expect(state!.throttle).toBe(0.8);
    });

    it('should respect minimum throttle for main engines', () => {
      const config: ThrusterConfig = createMainEngine('main-4');
      config.minThrottle = 0.4;
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      propulsion.fireThruster('main-4', 0.2);  // Below minimum

      const state = propulsion.getThrusterState('main-4');
      expect(state!.throttle).toBe(0);  // Should shut off
      expect(state!.enabled).toBe(false);
    });

    it('should treat RCS as ON/OFF only', () => {
      const config: ThrusterConfig = createRCS('rcs-1');
      propulsion.addThruster(config);
      propulsion.registerFuelTank('rcs-tank', fuelTank);

      propulsion.fireThruster('rcs-1', 0.6);  // Try to throttle to 60%

      const state = propulsion.getThrusterState('rcs-1');
      expect(state!.throttle).toBe(1.0);  // Should be full thrust (ON)
    });

    it('should not fire damaged thruster', () => {
      const config: ThrusterConfig = createMainEngine('main-5');
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      const state = propulsion.getThrusterState('main-5')!;
      state.damaged = true;

      const success = propulsion.fireThruster('main-5', 1.0);

      expect(success).toBe(false);
    });
  });

  describe('Thrust Vectoring', () => {
    it('should set gimbal angle for thruster', () => {
      const config: ThrusterConfig = createMainEngine('main-6');
      config.canGimbal = true;
      config.gimbalRange = 15;
      propulsion.addThruster(config);

      const success = propulsion.setGimbal('main-6', { x: 10, y: 5, z: 0 });

      expect(success).toBe(true);
      const state = propulsion.getThrusterState('main-6');
      expect(state!.gimbalAngle.x).toBe(10);
      expect(state!.gimbalAngle.y).toBe(5);
    });

    it('should clamp gimbal to range', () => {
      const config: ThrusterConfig = createMainEngine('main-7');
      config.canGimbal = true;
      config.gimbalRange = 15;
      propulsion.addThruster(config);

      propulsion.setGimbal('main-7', { x: 25, y: -20, z: 0 });  // Exceed range

      const state = propulsion.getThrusterState('main-7');
      expect(state!.gimbalAngle.x).toBe(15);  // Clamped to +15
      expect(state!.gimbalAngle.y).toBe(-15);  // Clamped to -15
    });

    it('should fail to gimbal if thruster cannot gimbal', () => {
      const config: ThrusterConfig = createRCS('rcs-2');
      config.canGimbal = false;
      propulsion.addThruster(config);

      const success = propulsion.setGimbal('rcs-2', { x: 10, y: 0, z: 0 });

      expect(success).toBe(false);
    });
  });

  describe('Fuel Consumption', () => {
    it('should consume fuel based on thrust and ISP', () => {
      const config: ThrusterConfig = createMainEngine('main-8');
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      propulsion.fireThruster('main-8', 1.0);

      const initialFuel = fuelTank.getCurrentMass();
      propulsion.update(1.0);  // 1 second burn
      const finalFuel = fuelTank.getCurrentMass();

      expect(finalFuel).toBeLessThan(initialFuel);

      // Calculate expected fuel consumption
      // ṁ = F / (Isp × g₀)
      const expectedFlow = config.maxThrust / (config.isp * 9.80665);
      const expectedConsumed = expectedFlow * 1.0;

      expect(initialFuel - finalFuel).toBeCloseTo(expectedConsumed, 3);
    });

    it('should shutdown when fuel depleted', () => {
      const config: ThrusterConfig = createMainEngine('main-9');
      propulsion.addThruster(config);

      const smallTank = new MockFuelTank(0.1);  // Very small tank (0.1 kg)
      propulsion.registerFuelTank('main-tank', smallTank);
      propulsion.registerPowerBudget(powerBudget);

      propulsion.fireThruster('main-9', 1.0);

      const initialFuel = smallTank.getCurrentMass();

      // Burn for 1 second - should attempt to consume ~14.57 kg but only has 0.1 kg
      propulsion.update(1.0);

      const state = propulsion.getThrusterState('main-9');

      // Either depleted immediately or consumed some fuel before shutting down
      expect(smallTank.getCurrentMass()).toBeLessThanOrEqual(initialFuel);
      expect(state!.enabled).toBe(false);  // Shut down due to insufficient fuel
    });

    it('should not consume fuel if thruster disabled', () => {
      const config: ThrusterConfig = createMainEngine('main-10');
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      // Don't fire thruster

      const initialFuel = fuelTank.getCurrentMass();
      propulsion.update(1.0);
      const finalFuel = fuelTank.getCurrentMass();

      expect(finalFuel).toBe(initialFuel);  // No consumption
    });
  });

  describe('Power Consumption', () => {
    it('should consume power for pumps', () => {
      const config: ThrusterConfig = createMainEngine('main-11');
      config.pumpPower = 5;  // 5 kW pumps
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);
      propulsion.registerPowerBudget(powerBudget);

      propulsion.fireThruster('main-11', 1.0);
      const output = propulsion.update(1.0);

      expect(output.powerConsumed).toBeGreaterThan(0);
      expect(output.powerConsumed).toBeCloseTo(5, 1);  // 5 kW for pumps
    });

    it('should consume power for gimbal', () => {
      const config: ThrusterConfig = createMainEngine('main-12');
      config.pumpPower = 5;
      config.canGimbal = true;
      config.gimbalPower = 0.5;  // 0.5 kW for gimbal
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);
      propulsion.registerPowerBudget(powerBudget);

      propulsion.fireThruster('main-12', 1.0);
      propulsion.setGimbal('main-12', { x: 10, y: 0, z: 0 });

      const output = propulsion.update(1.0);

      expect(output.powerConsumed).toBeCloseTo(5.5, 1);  // 5 kW pump + 0.5 kW gimbal
    });

    it('should shutdown pump-fed thruster if no power', () => {
      const config: ThrusterConfig = createMainEngine('main-13');
      config.pumpPower = 5;
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      const noPowerBudget = new MockPowerBudget(0);  // No power available
      propulsion.registerPowerBudget(noPowerBudget);

      propulsion.fireThruster('main-13', 1.0);
      const output = propulsion.update(1.0);

      expect(output.force.x).toBe(0);  // No thrust without power
      expect(output.force.y).toBe(0);
      expect(output.force.z).toBe(0);
    });

    it('should allow pressure-fed RCS without power', () => {
      const config: ThrusterConfig = createRCS('rcs-3');
      config.pumpPower = undefined;  // Pressure-fed (no pumps)
      propulsion.addThruster(config);
      propulsion.registerFuelTank('rcs-tank', fuelTank);

      const noPowerBudget = new MockPowerBudget(0);  // No power
      propulsion.registerPowerBudget(noPowerBudget);

      propulsion.fireThruster('rcs-3', 1.0);
      const output = propulsion.update(1.0);

      expect(output.force).not.toEqual({ x: 0, y: 0, z: 0 });  // Should still thrust
    });
  });

  describe('Heat Generation', () => {
    it('should generate heat from thruster operation', () => {
      const config: ThrusterConfig = createMainEngine('main-14');
      config.efficiency = 0.6;  // 40% becomes heat
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      propulsion.fireThruster('main-14', 1.0);
      const output = propulsion.update(1.0);

      expect(output.heatGenerated).toBeGreaterThan(0);
    });

    it('should increase thruster temperature when firing', () => {
      const config: ThrusterConfig = createMainEngine('main-15');
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      propulsion.fireThruster('main-15', 1.0);

      const initialTemp = propulsion.getThrusterState('main-15')!.temperature;

      // Burn for 5 seconds
      for (let i = 0; i < 5; i++) {
        propulsion.update(1.0);
      }

      const finalTemp = propulsion.getThrusterState('main-15')!.temperature;

      expect(finalTemp).toBeGreaterThan(initialTemp);
    });

    it('should reduce thrust when overheating', () => {
      const config: ThrusterConfig = createMainEngine('main-16');
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      const state = propulsion.getThrusterState('main-16')!;
      state.temperature = 900;  // Very hot (above 800K threshold)

      propulsion.fireThruster('main-16', 1.0);
      propulsion.update(1.0);

      expect(state.actualThrust).toBeLessThan(config.maxThrust);
    });

    it('should damage thruster from critical overheating', () => {
      const config: ThrusterConfig = createMainEngine('main-17');
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      const state = propulsion.getThrusterState('main-17')!;
      state.temperature = 1300;  // Critical temp (>1200K)

      propulsion.fireThruster('main-17', 1.0);

      const initialIntegrity = state.integrity;

      // Run for several seconds
      for (let i = 0; i < 10; i++) {
        propulsion.update(1.0);
      }

      expect(state.integrity).toBeLessThan(initialIntegrity);
    });
  });

  describe('Thrust Calculation', () => {
    it('should calculate correct thrust force vector', () => {
      const config: ThrusterConfig = createMainEngine('main-18');
      config.direction = { x: 0, y: 0, z: 1 };  // +Z direction
      config.maxThrust = 10000;  // 10 kN
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      propulsion.fireThruster('main-18', 1.0);
      propulsion.update(1.0);

      const { force } = propulsion.getThrustVector('main-18');

      expect(force.z).toBeGreaterThan(0);
      expect(Math.abs(force.z)).toBeCloseTo(10000, -2);  // ~10 kN
    });

    it('should calculate torque from off-center thruster', () => {
      const config: ThrusterConfig = createMainEngine('main-19');
      config.position = { x: 2, y: 0, z: 0 };  // 2m offset in X
      config.direction = { x: 0, y: 0, z: 1 };  // Thrust in +Z
      config.maxThrust = 5000;
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      propulsion.fireThruster('main-19', 1.0);
      propulsion.update(1.0);

      const { torque } = propulsion.getThrustVector('main-19');

      // Torque = r × F
      // r = (2, 0, 0), F = (0, 0, ~5000)
      // τ = (2, 0, 0) × (0, 0, 5000) = (0, -10000, 0)
      expect(torque.y).not.toBe(0);  // Should have Y-axis torque
      expect(Math.abs(torque.y)).toBeGreaterThan(0);
    });

    it('should modify thrust direction with gimbal', () => {
      const config: ThrusterConfig = createMainEngine('main-20');
      config.direction = { x: 0, y: 0, z: 1 };
      config.canGimbal = true;
      config.gimbalRange = 15;
      propulsion.addThruster(config);
      propulsion.registerFuelTank('main-tank', fuelTank);

      propulsion.fireThruster('main-20', 1.0);
      propulsion.setGimbal('main-20', { x: 0, y: 15, z: 0 });  // Gimbal 15° in Y

      propulsion.update(1.0);

      const { force } = propulsion.getThrustVector('main-20');

      // With gimbal, thrust should have X component
      expect(Math.abs(force.x)).toBeGreaterThan(0);
    });
  });

  describe('Tank Pressure Effects', () => {
    it('should reduce thrust when tank pressure low', () => {
      const config: ThrusterConfig = createMainEngine('main-21');
      propulsion.addThruster(config);

      const lowPressureTank = new MockFuelTank(100, 20000);  // 0.2 bar (low)
      propulsion.registerFuelTank('main-tank', lowPressureTank);

      propulsion.fireThruster('main-21', 1.0);
      propulsion.update(1.0);

      const state = propulsion.getThrusterState('main-21');
      expect(state!.actualThrust).toBeLessThan(config.maxThrust);
    });

    it('should maintain full thrust at normal pressure', () => {
      const config: ThrusterConfig = createMainEngine('main-22');
      propulsion.addThruster(config);

      const normalPressureTank = new MockFuelTank(100, 101325);  // 1 bar
      propulsion.registerFuelTank('main-tank', normalPressureTank);

      propulsion.fireThruster('main-22', 1.0);
      propulsion.update(1.0);

      const state = propulsion.getThrusterState('main-22');
      // Should be close to max thrust (within integrity/efficiency factors)
      expect(state!.actualThrust).toBeGreaterThan(config.maxThrust * 0.8);
    });
  });

  describe('Multiple Thrusters', () => {
    it('should combine thrust from multiple thrusters', () => {
      const config1: ThrusterConfig = createMainEngine('main-23');
      config1.direction = { x: 0, y: 0, z: 1 };
      config1.maxThrust = 5000;

      const config2: ThrusterConfig = createMainEngine('main-24');
      config2.direction = { x: 0, y: 0, z: 1 };
      config2.maxThrust = 5000;

      propulsion.addThruster(config1);
      propulsion.addThruster(config2);
      propulsion.registerFuelTank('main-tank', fuelTank);

      propulsion.fireThruster('main-23', 1.0);
      propulsion.fireThruster('main-24', 1.0);

      const output = propulsion.update(1.0);

      // Combined thrust should be ~10 kN
      expect(output.force.z).toBeGreaterThan(9000);
    });

    it('should accumulate fuel consumption from all thrusters', () => {
      const config1: ThrusterConfig = createRCS('rcs-4');
      const config2: ThrusterConfig = createRCS('rcs-5');

      propulsion.addThruster(config1);
      propulsion.addThruster(config2);
      propulsion.registerFuelTank('rcs-tank', fuelTank);

      propulsion.fireThruster('rcs-4', 1.0);
      propulsion.fireThruster('rcs-5', 1.0);

      const initialFuel = fuelTank.getCurrentMass();
      propulsion.update(1.0);
      const finalFuel = fuelTank.getCurrentMass();

      const consumed = initialFuel - finalFuel;

      // Should be ~2x single thruster consumption
      const expectedSingleFlow = config1.maxThrust / (config1.isp * 9.80665);
      expect(consumed).toBeCloseTo(expectedSingleFlow * 2, 3);
    });
  });

  describe('Statistics', () => {
    it('should track thruster statistics', () => {
      propulsion.addThruster(createMainEngine('main-25'));
      propulsion.addThruster(createRCS('rcs-6'));
      propulsion.registerFuelTank('main-tank', fuelTank);

      propulsion.fireThruster('main-25', 1.0);
      propulsion.update(1.0);

      const stats = propulsion.getStatistics();

      expect(stats.totalThrusters).toBe(2);
      expect(stats.activeThrusters).toBe(1);
      expect(stats.damagedThrusters).toBe(0);
      expect(stats.totalThrust).toBeGreaterThan(0);
    });
  });
});

// Helper functions
function createMainEngine(id: string): ThrusterConfig {
  return {
    id,
    type: ThrusterType.MAIN_ENGINE,
    position: { x: 0, y: 0, z: -5 },  // 5m aft
    direction: { x: 0, y: 0, z: 1 },  // Thrust forward
    maxThrust: 50000,  // 50 kN
    isp: 350,  // Seconds
    propellantType: PropellantType.LOX_LH2,
    fuelTankId: 'main-tank',
    canGimbal: false,
    minThrottle: 0.4,
    pumpPower: 5,  // 5 kW pumps
    efficiency: 0.7  // 70% efficient
  };
}

function createRCS(id: string): ThrusterConfig {
  return {
    id,
    type: ThrusterType.RCS,
    position: { x: 1, y: 1, z: 0 },
    direction: { x: -1, y: 0, z: 0 },
    maxThrust: 400,  // 400 N
    isp: 120,  // Seconds
    propellantType: PropellantType.HYDRAZINE,
    fuelTankId: 'rcs-tank',
    canGimbal: false,
    minThrottle: 1.0,  // ON/OFF only
    pumpPower: undefined,  // Pressure-fed
    efficiency: 0.5  // 50% efficient
  };
}
