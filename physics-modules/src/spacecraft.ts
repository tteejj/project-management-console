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
 * - Flight Control System (PID, SAS, Autopilot)
 * - Navigation System (Trajectory, Telemetry)
 * - Mission System (Objectives, Scoring)
 *
 * Handles:
 * - System interconnections
 * - Resource management
 * - Power distribution
 * - Thermal coupling
 * - Flight automation
 * - Navigation and guidance
 * - Mission management
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
import { FlightControlSystem, type SASMode, type AutopilotMode } from './flight-control';
import { NavigationSystem } from './navigation';
import { MissionSystem, type Mission } from './mission';
import { LifeSupportSystem } from './life-support-system';

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
  flightControlConfig?: any;
  navigationConfig?: any;
  missionConfig?: any;
  lifeSupportConfig?: any;
}

export class Spacecraft {
  // Core physics subsystems
  public fuel: FuelSystem;
  public electrical: ElectricalSystem;
  public gas: CompressedGasSystem;
  public thermal: ThermalSystem;
  public coolant: CoolantSystem;
  public mainEngine: MainEngine;
  public rcs: RCSSystem;
  public physics: ShipPhysics;
  public lifeSupport: LifeSupportSystem;

  // Advanced flight systems
  public flightControl: FlightControlSystem;
  public navigation: NavigationSystem;
  public mission: MissionSystem;

  // Simulation time
  public simulationTime: number = 0;

  // Initial fuel capacity (for delta-V calculations)
  private initialFuelCapacity: number = 0;

  constructor(config?: SpacecraftConfig) {
    // Initialize core physics systems
    this.fuel = new FuelSystem(config?.fuelConfig);
    this.electrical = new ElectricalSystem(config?.electricalConfig);
    this.gas = new CompressedGasSystem(config?.gasConfig);
    this.thermal = new ThermalSystem(config?.thermalConfig);
    this.coolant = new CoolantSystem(config?.coolantConfig);
    this.mainEngine = new MainEngine(config?.mainEngineConfig);
    this.rcs = new RCSSystem(config?.rcsConfig);
    this.physics = new ShipPhysics(config?.shipPhysicsConfig);
    this.lifeSupport = new LifeSupportSystem(config?.lifeSupportConfig);

    // Initialize advanced flight systems
    this.flightControl = new FlightControlSystem(config?.flightControlConfig);
    this.navigation = new NavigationSystem();
    this.mission = new MissionSystem();

    // Store initial fuel capacity for delta-V calculations
    this.initialFuelCapacity = this.fuel.getState().totalFuel;
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

    // 4. Get current physics state for flight control
    const physicsState = this.physics.getState();
    const mainEngineState = this.mainEngine.getState();

    // 5. Update flight control system (SAS, autopilot)
    const maxThrust = this.mainEngine.maxThrustN;
    const currentThrust = this.mainEngine.currentThrustN;
    const totalMass = this.physics.dryMass + this.physics.propellantMass;
    const gravity = this.physics.getLocalGravity();

    const flightControlState = this.flightControl.update(
      physicsState.attitude,
      physicsState.angularVelocity,
      null, // targetAttitude (can be set by autopilot mode)
      physicsState.velocity,
      physicsState.position,
      physicsState.altitude,
      physicsState.verticalSpeed,
      totalMass,
      maxThrust,
      currentThrust,
      gravity,
      dt
    );

    // 6. Apply autopilot throttle commands (if active)
    if (flightControlState.autopilotMode !== 'off' && mainEngineState.status === 'running') {
      this.mainEngine.setThrottle(flightControlState.throttleCommand.throttle);
    }

    // 7. Apply gimbal autopilot commands (if active)
    if (this.flightControl.isGimbalAutopilotEnabled() && mainEngineState.status === 'running') {
      this.mainEngine.setGimbal(
        flightControlState.gimbalCommand.pitch,
        flightControlState.gimbalCommand.yaw
      );
    }

    // 8. Get propellant consumption from engines
    const mainEngineRates = this.mainEngine.getConsumptionRates();
    const rcsFuelConsumption = this.rcs.consumeFuel(dt, this.getAvailableRCSFuel());

    // 9. Consume fuel from tanks
    const mainFuelTank = this.fuel.getTank('main_1')!;
    const mainOxidizerTank = this.fuel.getTank('main_2')!;
    const rcsTank = this.fuel.getTank('rcs')!;

    const mainFuelAmount = mainEngineRates.fuelKgPerSec * dt;
    const mainOxidizerAmount = mainEngineRates.oxidizerKgPerSec * dt;

    this.fuel.consumeFuel('main_1', mainFuelAmount);
    this.fuel.consumeFuel('main_2', mainOxidizerAmount);

    this.mainEngine.consumePropellant(dt, mainFuelTank.fuelMass, mainOxidizerTank.fuelMass);

    this.fuel.consumeFuel('rcs', rcsFuelConsumption);

    // 10. Update ship mass in physics
    const totalPropellantMass = this.fuel.getTotalFuelMass();
    this.physics.propellantMass = totalPropellantMass;

    // 11. Get thrust and torque vectors
    const mainEngineThrust = this.mainEngine.getThrustVector();
    const mainEngineTorque = { x: 0, y: 0, z: 0 };  // Gimbal torque (simplified for now)

    const rcsThrust = this.rcs.getTotalThrustVector();
    const rcsTorque = this.rcs.getTotalTorque();

    // 12. Update ship physics
    const totalPropellantConsumed = mainFuelAmount + mainOxidizerAmount + rcsFuelConsumption;

    this.physics.update(
      dt,
      mainEngineThrust,
      mainEngineTorque,
      rcsThrust,
      rcsTorque,
      totalPropellantConsumed
    );

    // 13. Update thermal system with heat generation
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

    // 14. Update coolant system with component temperatures
    for (const [name, component] of this.thermal.heatSources) {
      componentTemps.set(name, component.temperature);
    }

    this.coolant.update(dt, t, componentTemps);

    // 15. Update compressed gas system
    this.gas.update(dt, t);

    // 16. Update fuel system
    this.fuel.update(dt, t);

    // 17. Update mission checklists (if mission loaded)
    this.mission.updateChecklists();

    // 18. Update life support system
    this.lifeSupport.update(dt);

    // 19. Increment time
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
      rcs: this.rcs.getState(),
      flightControl: this.flightControl.getState(),
      navigation: this.getNavigationTelemetry(),
      mission: this.mission.getCurrentMission(),
      lifeSupport: this.lifeSupport.getState()
    };
  }

  /**
   * Get navigation telemetry
   */
  getNavigationTelemetry() {
    const physicsState = this.physics.getState();
    const mainEngineState = this.mainEngine.getState();
    const fuelState = this.fuel.getState();
    const totalMass = this.physics.dryMass + this.physics.propellantMass;

    // Get thrust direction from ship attitude (simplified)
    const thrustDir = { x: 0, y: 0, z: 1 };  // Local Z-axis

    return this.navigation.getTelemetry(
      physicsState.position,
      physicsState.velocity,
      physicsState.attitude,
      totalMass,
      this.mainEngine.currentThrustN,
      thrustDir,
      mainEngineState.throttle,
      fuelState.totalFuel,
      this.initialFuelCapacity,
      this.mainEngine.specificImpulseSec
    );
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

  // =============================================================================
  // Flight Control System Commands
  // =============================================================================

  /**
   * Set SAS mode
   */
  setSASMode(mode: SASMode): void {
    this.flightControl.setSASMode(mode);
  }

  /**
   * Get current SAS mode
   */
  getSASMode(): SASMode {
    return this.flightControl.getSASMode();
  }

  /**
   * Set autopilot mode
   */
  setAutopilotMode(mode: AutopilotMode): void {
    this.flightControl.setAutopilotMode(mode);
  }

  /**
   * Get current autopilot mode
   */
  getAutopilotMode(): AutopilotMode {
    return this.flightControl.getAutopilotMode();
  }

  /**
   * Set target altitude for altitude hold autopilot
   */
  setTargetAltitude(altitude: number): void {
    this.flightControl.setTargetAltitude(altitude);
  }

  /**
   * Set target vertical speed for vertical speed hold autopilot
   */
  setTargetVerticalSpeed(speed: number): void {
    this.flightControl.setTargetVerticalSpeed(speed);
  }

  /**
   * Enable/disable gimbal autopilot
   */
  setGimbalAutopilot(enabled: boolean): void {
    this.flightControl.setGimbalAutopilot(enabled);
  }

  // =============================================================================
  // Navigation System Commands
  // =============================================================================

  /**
   * Set navigation target
   */
  setNavigationTarget(position: { x: number; y: number; z: number }): void {
    this.navigation.setTarget(position);
  }

  /**
   * Clear navigation target
   */
  clearNavigationTarget(): void {
    this.navigation.clearTarget();
  }

  /**
   * Get trajectory prediction
   */
  predictTrajectory() {
    const physicsState = this.physics.getState();
    const totalMass = this.physics.dryMass + this.physics.propellantMass;
    const thrustDir = { x: 0, y: 0, z: 1 };

    return this.navigation.predictImpact(
      physicsState.position,
      physicsState.velocity,
      totalMass,
      this.mainEngine.currentThrustN,
      thrustDir
    );
  }

  /**
   * Get suicide burn data
   */
  getSuicideBurnData() {
    const physicsState = this.physics.getState();
    const totalMass = this.physics.dryMass + this.physics.propellantMass;

    return this.navigation.calculateSuicideBurn(
      physicsState.altitude,
      physicsState.verticalSpeed,
      totalMass,
      this.mainEngine.maxThrustN
    );
  }

  /**
   * Render navball display
   */
  renderNavball(): string {
    const physicsState = this.physics.getState();
    return this.navigation.renderNavball(
      physicsState.attitude,
      physicsState.velocity
    );
  }

  // =============================================================================
  // Mission System Commands
  // =============================================================================

  /**
   * Load mission
   */
  loadMission(mission: Mission): void {
    this.mission.loadMission(mission);
  }

  /**
   * Start mission
   */
  startMission(): void {
    this.mission.startMission(this.simulationTime);
  }

  /**
   * Get current mission
   */
  getCurrentMission(): Mission | null {
    return this.mission.getCurrentMission();
  }

  /**
   * Complete mission objective
   */
  completeObjective(objectiveId: string): void {
    this.mission.completeObjective(objectiveId);
  }

  /**
   * Calculate mission score
   */
  calculateMissionScore(landingSpeed: number, landingAngle: number) {
    const physicsState = this.physics.getState();
    const fuelState = this.fuel.getState();
    const currentMission = this.mission.getCurrentMission();

    if (!currentMission) {
      throw new Error('No active mission');
    }

    // Get target position from landing zone
    const targetPos = { x: 0, y: 0, z: 1737400 };  // Simplified

    return this.mission.calculateMissionScore(
      landingSpeed,
      landingAngle,
      physicsState.position,
      targetPos,
      fuelState.totalFuel,
      95,  // System health (simplified)
      this.simulationTime
    );
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
