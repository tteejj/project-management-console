/**
 * Spacecraft Integration Module
 *
 * Integrates all physics modules into a unified spacecraft simulation:
 * - Fuel System
 * - Electrical System
 * - Compressed Gas System
 * - Thermal System
 * - Coolant System
 * - Main Engine
 * - RCS System
 * - Ship Physics Core
 *
 * Handles:
 * - System interconnections
 * - Resource management
 * - Power distribution
 * - Thermal coupling
 * - Complete update loop
 */

import { FuelSystem } from './fuel-system';
import { ElectricalSystem } from './electrical-system';
import { CompressedGasSystem } from './compressed-gas-system';
import { ThermalSystem } from './thermal-system';
import { CoolantSystem } from './coolant-system';
import { MainEngine } from './main-engine';
import { RCSSystem } from './rcs-system';
import { ShipPhysics } from './ship-physics';

export interface SpacecraftConfig {
  // Optional system configurations
  fuelConfig?: any;
  electricalConfig?: any;
  gasConfig?: any;
  thermalConfig?: any;
  coolantConfig?: any;
  mainEngineConfig?: any;
  rcsConfig?: any;
  shipPhysicsConfig?: any;
}

export class Spacecraft {
  // All subsystems
  public fuel: FuelSystem;
  public electrical: ElectricalSystem;
  public gas: CompressedGasSystem;
  public thermal: ThermalSystem;
  public coolant: CoolantSystem;
  public mainEngine: MainEngine;
  public rcs: RCSSystem;
  public physics: ShipPhysics;

  // Simulation time
  public simulationTime: number = 0;

  constructor(config?: SpacecraftConfig) {
    this.fuel = new FuelSystem(config?.fuelConfig);
    this.electrical = new ElectricalSystem(config?.electricalConfig);
    this.gas = new CompressedGasSystem(config?.gasConfig);
    this.thermal = new ThermalSystem(config?.thermalConfig);
    this.coolant = new CoolantSystem(config?.coolantConfig);
    this.mainEngine = new MainEngine(config?.mainEngineConfig);
    this.rcs = new RCSSystem(config?.rcsConfig);
    this.physics = new ShipPhysics(config?.shipPhysicsConfig);
  }

  /**
   * Master update loop - integrates all systems
   */
  update(dt: number): void {
    const t = this.simulationTime;

    // 1. Update electrical system (power generation)
    this.electrical.update(dt, t);

    // 2. Update main engine
    this.mainEngine.update(dt, t);

    // 3. Update RCS system
    this.rcs.update(dt, t);

    // 4. Get propellant consumption from engines
    const mainEngineRates = this.mainEngine.getConsumptionRates();
    const rcsFuelConsumption = this.rcs.consumeFuel(dt, this.getAvailableRCSFuel());

    // 5. Consume fuel from tanks
    const mainFuelTank = this.fuel.getTank('main_1')!;
    const mainOxidizerTank = this.fuel.getTank('main_2')!;
    const rcsTank = this.fuel.getTank('rcs')!;

    const mainFuelAmount = mainEngineRates.fuelKgPerSec * dt;
    const mainOxidizerAmount = mainEngineRates.oxidizerKgPerSec * dt;

    this.fuel.consumeFuel('main_1', mainFuelAmount);
    this.fuel.consumeFuel('main_2', mainOxidizerAmount);

    this.mainEngine.consumePropellant(dt, mainFuelTank.fuelMass, mainOxidizerTank.fuelMass);

    this.fuel.consumeFuel('rcs', rcsFuelConsumption);

    // 6. Update ship mass in physics
    const totalPropellantMass = this.fuel.getTotalFuelMass();
    this.physics.propellantMass = totalPropellantMass;

    // 7. Get thrust and torque vectors
    const mainEngineThrust = this.mainEngine.getThrustVector();
    const mainEngineTorque = { x: 0, y: 0, z: 0 };  // Gimbal torque (simplified for now)

    const rcsThrust = this.rcs.getTotalThrustVector();
    const rcsTorque = this.rcs.getTotalTorque();

    // 8. Update ship physics
    const totalPropellantConsumed = mainFuelAmount + mainOxidizerAmount + rcsFuelConsumption;

    this.physics.update(
      dt,
      mainEngineThrust,
      mainEngineTorque,
      rcsThrust,
      rcsTorque,
      totalPropellantConsumed
    );

    // 9. Update thermal system with heat generation
    const componentTemps = new Map<string, number>();

    // Main engine generates heat
    const mainEngineHeat = this.mainEngine.getHeatGenerationW();
    this.thermal.setHeatGeneration('main_engine', mainEngineHeat);

    // Reactor generates heat
    const reactorHeat = this.electrical.reactor.heatGenerationW;
    this.thermal.setHeatGeneration('reactor', reactorHeat);

    // Battery generates heat during discharge (simplified)
    // Heat generation proportional to discharge rate
    const batteryHeat = this.electrical.battery.chargeKWh < this.electrical.battery.capacityKWh ? 50 : 0;
    this.thermal.setHeatGeneration('battery', batteryHeat);

    this.thermal.update(dt, t);

    // 10. Update coolant system with component temperatures
    for (const [name, component] of this.thermal.heatSources) {
      componentTemps.set(name, component.temperature);
    }

    this.coolant.update(dt, t, componentTemps);

    // 11. Update compressed gas system
    this.gas.update(dt, t);

    // 12. Update fuel system
    this.fuel.update(dt, t);

    // 13. Increment time
    this.simulationTime += dt;
  }

  /**
   * Get available RCS fuel
   */
  private getAvailableRCSFuel(): number {
    const rcsTank = this.fuel.getTank('rcs');
    return rcsTank ? rcsTank.fuelMass : 0;
  }

  /**
   * Get comprehensive spacecraft state
   */
  getState() {
    return {
      simulationTime: this.simulationTime,
      physics: this.physics.getState(),
      fuel: this.fuel.getState(),
      electrical: this.electrical.getState(),
      gas: this.gas.getState(),
      thermal: this.thermal.getState(),
      coolant: this.coolant.getState(),
      mainEngine: this.mainEngine.getState(),
      rcs: this.rcs.getState()
    };
  }

  /**
   * Command interface: Ignite main engine
   */
  igniteMainEngine(): boolean {
    return this.mainEngine.ignite();
  }

  /**
   * Command interface: Shutdown main engine
   */
  shutdownMainEngine(): void {
    this.mainEngine.shutdown();
  }

  /**
   * Command interface: Set main engine throttle
   */
  setMainEngineThrottle(throttle: number): void {
    this.mainEngine.setThrottle(throttle);
  }

  /**
   * Command interface: Activate RCS group
   */
  activateRCS(groupName: string): boolean {
    return this.rcs.activateGroup(groupName);
  }

  /**
   * Command interface: Deactivate RCS group
   */
  deactivateRCS(groupName: string): void {
    this.rcs.deactivateGroup(groupName);
  }

  /**
   * Command interface: Start reactor
   */
  startReactor(): boolean {
    return this.electrical.startReactor();
  }

  /**
   * Command interface: Start coolant pump
   */
  startCoolantPump(loopId: number): boolean {
    return this.coolant.startPump(loopId);
  }

  /**
   * Get all system events
   */
  getAllEvents() {
    return {
      fuel: this.fuel.getEvents(),
      electrical: this.electrical.getEvents(),
      gas: this.gas.getEvents(),
      thermal: this.thermal.getEvents(),
      coolant: this.coolant.getEvents(),
      mainEngine: this.mainEngine.getEvents(),
      rcs: this.rcs.getEvents(),
      physics: this.physics.getEvents()
    };
  }
}
