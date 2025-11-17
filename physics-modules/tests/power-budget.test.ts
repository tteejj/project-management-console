/**
 * Power Budget System Tests
 *
 * Tests power generation, distribution, brownouts, battery management
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  PowerBudgetSystem,
  PowerSource,
  PowerSourceType,
  PowerConsumer,
  PowerPriority,
  BatteryBank,
  PowerBudgetConfig,
  PowerStatistics
} from '../src/power-budget';

describe('Power Budget System', () => {
  describe('Power Generation', () => {
    it('should generate power from reactor', () => {
      const reactor: PowerSource = {
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 100,      // 100 kW
        currentOutput: 0,
        efficiency: 0.95,
        powered: true
      };

      const powerBudget = new PowerBudgetSystem({
        sources: [reactor],
        consumers: [],
        batteries: []
      });

      powerBudget.update(1);

      const stats = powerBudget.getStatistics();
      expect(stats.totalGeneration).toBeGreaterThan(0);
      expect(stats.totalGeneration).toBeLessThanOrEqual(100);
    });

    it('should generate power from solar panels', () => {
      const solar: PowerSource = {
        id: 'solar-1',
        type: PowerSourceType.SOLAR,
        maxOutput: 10,       // 10 kW
        currentOutput: 0,
        efficiency: 0.20,    // 20% efficient
        powered: true,
        sunExposure: 1.0     // Full sun
      };

      const powerBudget = new PowerBudgetSystem({
        sources: [solar],
        consumers: [],
        batteries: []
      });

      powerBudget.update(1);

      const stats = powerBudget.getStatistics();
      expect(stats.totalGeneration).toBeCloseTo(10 * 0.20, 1);  // 2 kW
    });

    it('should reduce solar output when shadowed', () => {
      const solar: PowerSource = {
        id: 'solar-1',
        type: PowerSourceType.SOLAR,
        maxOutput: 10,
        currentOutput: 0,
        efficiency: 0.20,
        powered: true,
        sunExposure: 0.5     // 50% sun (partial shadow)
      };

      const powerBudget = new PowerBudgetSystem({
        sources: [solar],
        consumers: [],
        batteries: []
      });

      powerBudget.update(1);

      const stats = powerBudget.getStatistics();
      expect(stats.totalGeneration).toBeCloseTo(10 * 0.20 * 0.5, 1);  // 1 kW
    });

    it('should generate constant power from RTG', () => {
      const rtg: PowerSource = {
        id: 'rtg-1',
        type: PowerSourceType.RTG,
        maxOutput: 0.5,      // 500 W
        currentOutput: 0.5,
        efficiency: 1.0,     // Always on
        powered: true
      };

      const powerBudget = new PowerBudgetSystem({
        sources: [rtg],
        consumers: [],
        batteries: []
      });

      powerBudget.update(1);

      const stats = powerBudget.getStatistics();
      expect(stats.totalGeneration).toBeCloseTo(0.5, 2);
    });
  });

  describe('Power Consumption', () => {
    it('should consume power from consumers', () => {
      const reactor: PowerSource = {
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 100,
        currentOutput: 0,
        efficiency: 1.0,
        powered: true
      };

      const lifeSupport: PowerConsumer = {
        id: 'life-support',
        name: 'Life Support',
        powerDraw: 5,        // 5 kW
        priority: PowerPriority.CRITICAL,
        powered: true,
        actualPower: 0
      };

      const powerBudget = new PowerBudgetSystem({
        sources: [reactor],
        consumers: [lifeSupport],
        batteries: []
      });

      powerBudget.update(1);

      const stats = powerBudget.getStatistics();
      expect(stats.totalConsumption).toBeCloseTo(5, 1);
    });

    it('should distribute power to multiple consumers', () => {
      const reactor: PowerSource = {
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 100,
        currentOutput: 0,
        efficiency: 1.0,
        powered: true
      };

      const consumers: PowerConsumer[] = [
        {
          id: 'life-support',
          name: 'Life Support',
          powerDraw: 5,
          priority: PowerPriority.CRITICAL,
          powered: true,
          actualPower: 0
        },
        {
          id: 'sensors',
          name: 'Sensors',
          powerDraw: 2,
          priority: PowerPriority.HIGH,
          powered: true,
          actualPower: 0
        },
        {
          id: 'lighting',
          name: 'Lighting',
          powerDraw: 1,
          priority: PowerPriority.LOW,
          powered: true,
          actualPower: 0
        }
      ];

      const powerBudget = new PowerBudgetSystem({
        sources: [reactor],
        consumers,
        batteries: []
      });

      powerBudget.update(1);

      const stats = powerBudget.getStatistics();
      expect(stats.totalConsumption).toBeCloseTo(8, 1);  // 5 + 2 + 1
    });
  });

  describe('Brownouts and Priority', () => {
    it('should shed low-priority loads during shortage', () => {
      const reactor: PowerSource = {
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 10,       // Only 10 kW available
        currentOutput: 0,
        efficiency: 1.0,
        powered: true
      };

      const consumers: PowerConsumer[] = [
        {
          id: 'life-support',
          name: 'Life Support',
          powerDraw: 5,
          priority: PowerPriority.CRITICAL,
          powered: true,
          actualPower: 0
        },
        {
          id: 'sensors',
          name: 'Sensors',
          powerDraw: 3,
          priority: PowerPriority.HIGH,
          powered: true,
          actualPower: 0
        },
        {
          id: 'lighting',
          name: 'Lighting',
          powerDraw: 5,
          priority: PowerPriority.LOW,
          powered: true,
          actualPower: 0
        }
      ];

      const powerBudget = new PowerBudgetSystem({
        sources: [reactor],
        consumers,
        batteries: []
      });

      powerBudget.update(1);

      // Critical and high priority should get full power
      const lifeSupport = powerBudget.getConsumer('life-support')!;
      const sensors = powerBudget.getConsumer('sensors')!;
      const lighting = powerBudget.getConsumer('lighting')!;

      expect(lifeSupport.actualPower).toBe(5);      // Full power
      expect(sensors.actualPower).toBe(3);          // Full power
      expect(lighting.actualPower).toBeLessThan(5); // Reduced or off
    });

    it('should maintain power to critical systems first', () => {
      const reactor: PowerSource = {
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 6,        // Only 6 kW
        currentOutput: 0,
        efficiency: 1.0,
        powered: true
      };

      const consumers: PowerConsumer[] = [
        {
          id: 'life-support',
          name: 'Life Support',
          powerDraw: 5,
          priority: PowerPriority.CRITICAL,
          powered: true,
          actualPower: 0
        },
        {
          id: 'weapons',
          name: 'Weapons',
          powerDraw: 10,
          priority: PowerPriority.MEDIUM,
          powered: true,
          actualPower: 0
        }
      ];

      const powerBudget = new PowerBudgetSystem({
        sources: [reactor],
        consumers,
        batteries: []
      });

      powerBudget.update(1);

      const lifeSupport = powerBudget.getConsumer('life-support')!;
      const weapons = powerBudget.getConsumer('weapons')!;

      expect(lifeSupport.actualPower).toBe(5);      // Full power
      expect(weapons.actualPower).toBeLessThanOrEqual(1);  // Only 1 kW left
    });
  });

  describe('Battery Management', () => {
    it('should charge batteries from excess power', () => {
      const reactor: PowerSource = {
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 20,
        currentOutput: 0,
        efficiency: 1.0,
        powered: true
      };

      const battery: BatteryBank = {
        id: 'battery-1',
        capacity: 100,           // 100 kWh
        currentCharge: 50,       // 50% charged
        maxChargeRate: 10,       // 10 kW max
        maxDischargeRate: 10,
        efficiency: 0.95
      };

      const consumer: PowerConsumer = {
        id: 'life-support',
        name: 'Life Support',
        powerDraw: 5,
        priority: PowerPriority.CRITICAL,
        powered: true,
        actualPower: 0
      };

      const powerBudget = new PowerBudgetSystem({
        sources: [reactor],
        consumers: [consumer],
        batteries: [battery]
      });

      const initialCharge = battery.currentCharge;
      powerBudget.update(3600);  // 1 hour

      // Excess power = 20 - 5 = 15 kW, but limited by charge rate (10 kW)
      // Energy added = 10 kW * 1 h * 0.95 efficiency = 9.5 kWh
      expect(battery.currentCharge).toBeCloseTo(initialCharge + 9.5, 0);
    });

    it('should discharge batteries when generation insufficient', () => {
      const reactor: PowerSource = {
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 3,        // Only 3 kW
        currentOutput: 0,
        efficiency: 1.0,
        powered: true
      };

      const battery: BatteryBank = {
        id: 'battery-1',
        capacity: 100,
        currentCharge: 50,
        maxChargeRate: 10,
        maxDischargeRate: 10,
        efficiency: 0.95
      };

      const consumer: PowerConsumer = {
        id: 'life-support',
        name: 'Life Support',
        powerDraw: 8,        // 8 kW needed
        priority: PowerPriority.CRITICAL,
        powered: true,
        actualPower: 0
      };

      const powerBudget = new PowerBudgetSystem({
        sources: [reactor],
        consumers: [consumer],
        batteries: [battery]
      });

      const initialCharge = battery.currentCharge;
      powerBudget.update(3600);  // 1 hour

      // Deficit = 8 - 3 = 5 kW
      // Energy drawn = 5 kWh
      expect(battery.currentCharge).toBeCloseTo(initialCharge - 5, 0);
    });

    it('should not overcharge batteries', () => {
      const reactor: PowerSource = {
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 20,
        currentOutput: 0,
        efficiency: 1.0,
        powered: true
      };

      const battery: BatteryBank = {
        id: 'battery-1',
        capacity: 100,
        currentCharge: 99,       // Almost full
        maxChargeRate: 10,
        maxDischargeRate: 10,
        efficiency: 0.95
      };

      const powerBudget = new PowerBudgetSystem({
        sources: [reactor],
        consumers: [],
        batteries: [battery]
      });

      powerBudget.update(3600);  // 1 hour

      expect(battery.currentCharge).toBeLessThanOrEqual(100);
    });

    it('should not discharge below zero', () => {
      const reactor: PowerSource = {
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 0,        // No generation
        currentOutput: 0,
        efficiency: 1.0,
        powered: true
      };

      const battery: BatteryBank = {
        id: 'battery-1',
        capacity: 100,
        currentCharge: 1,        // Very low
        maxChargeRate: 10,
        maxDischargeRate: 10,
        efficiency: 0.95
      };

      const consumer: PowerConsumer = {
        id: 'life-support',
        name: 'Life Support',
        powerDraw: 100,      // Huge load
        priority: PowerPriority.CRITICAL,
        powered: true,
        actualPower: 0
      };

      const powerBudget = new PowerBudgetSystem({
        sources: [reactor],
        consumers: [consumer],
        batteries: [battery]
      });

      powerBudget.update(3600);  // 1 hour

      expect(battery.currentCharge).toBeGreaterThanOrEqual(0);
    });
  });

  describe('Statistics', () => {
    it('should track total energy consumed', () => {
      const reactor: PowerSource = {
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 10,
        currentOutput: 0,
        efficiency: 1.0,
        powered: true
      };

      const consumer: PowerConsumer = {
        id: 'life-support',
        name: 'Life Support',
        powerDraw: 5,
        priority: PowerPriority.CRITICAL,
        powered: true,
        actualPower: 0
      };

      const powerBudget = new PowerBudgetSystem({
        sources: [reactor],
        consumers: [consumer],
        batteries: []
      });

      powerBudget.update(3600);  // 1 hour

      const stats = powerBudget.getStatistics();
      expect(stats.totalEnergyConsumed).toBeCloseTo(5, 1);  // 5 kWh
    });

    it('should track brownout events', () => {
      const reactor: PowerSource = {
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 5,
        currentOutput: 0,
        efficiency: 1.0,
        powered: true
      };

      const consumer: PowerConsumer = {
        id: 'life-support',
        name: 'Life Support',
        powerDraw: 10,       // More than available
        priority: PowerPriority.CRITICAL,
        powered: true,
        actualPower: 0
      };

      const powerBudget = new PowerBudgetSystem({
        sources: [reactor],
        consumers: [consumer],
        batteries: []
      });

      powerBudget.update(1);

      const stats = powerBudget.getStatistics();
      expect(stats.brownoutActive).toBe(true);
      expect(stats.powerDeficit).toBeCloseTo(5, 1);
    });
  });

  describe('Transient Loads', () => {
    it('should handle weapon firing spike', () => {
      const reactor: PowerSource = {
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 10,
        currentOutput: 0,
        efficiency: 1.0,
        powered: true
      };

      const battery: BatteryBank = {
        id: 'battery-1',
        capacity: 100,
        currentCharge: 50,
        maxChargeRate: 50,       // High rate for transients
        maxDischargeRate: 50,
        efficiency: 0.95
      };

      const weapon: PowerConsumer = {
        id: 'weapon',
        name: 'Railgun',
        powerDraw: 0,        // Normally off
        priority: PowerPriority.HIGH,
        powered: true,
        actualPower: 0
      };

      const powerBudget = new PowerBudgetSystem({
        sources: [reactor],
        consumers: [weapon],
        batteries: [battery]
      });

      // Fire weapon - set high power draw
      weapon.powerDraw = 100;  // 100 kW spike
      powerBudget.update(0.1);  // 0.1 second burst

      // Weapon should get power from battery
      expect(weapon.actualPower).toBeGreaterThan(0);
      expect(battery.currentCharge).toBeLessThan(50);
    });
  });
});
