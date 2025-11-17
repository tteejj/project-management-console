"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.Spacecraft = void 0;
const fuel_system_1 = require("./fuel-system");
const electrical_system_1 = require("./electrical-system");
const compressed_gas_system_1 = require("./compressed-gas-system");
const thermal_system_1 = require("./thermal-system");
const coolant_system_1 = require("./coolant-system");
const main_engine_1 = require("./main-engine");
const rcs_system_1 = require("./rcs-system");
const ship_physics_1 = require("./ship-physics");
const flight_control_1 = require("./flight-control");
const navigation_1 = require("./navigation");
const mission_1 = require("./mission");
const terrain_system_1 = require("./terrain-system");
class Spacecraft {
    constructor(config) {
        // Simulation time
        this.simulationTime = 0;
        // Initial fuel capacity (for delta-V calculations)
        this.initialFuelCapacity = 0;
        // Initialize core physics systems
        this.fuel = new fuel_system_1.FuelSystem(config?.fuelConfig);
        this.electrical = new electrical_system_1.ElectricalSystem(config?.electricalConfig);
        this.gas = new compressed_gas_system_1.CompressedGasSystem(config?.gasConfig);
        this.thermal = new thermal_system_1.ThermalSystem(config?.thermalConfig);
        this.coolant = new coolant_system_1.CoolantSystem(config?.coolantConfig);
        this.mainEngine = new main_engine_1.MainEngine(config?.mainEngineConfig);
        this.rcs = new rcs_system_1.RCSSystem(config?.rcsConfig);
        this.physics = new ship_physics_1.ShipPhysics(config?.shipPhysicsConfig);
        // Initialize terrain system
        this.terrain = new terrain_system_1.TerrainSystem(config?.terrainConfig);
        // Initialize advanced flight systems
        this.flightControl = new flight_control_1.FlightControlSystem(config?.flightControlConfig);
        this.navigation = new navigation_1.NavigationSystem(this.terrain);
        this.mission = new mission_1.MissionSystem();
        // Store initial fuel capacity for delta-V calculations
        this.initialFuelCapacity = this.fuel.getState().totalFuel;
    }
    /**
     * Master update loop - integrates all systems
     */
    update(dt) {
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
        const flightControlState = this.flightControl.update(physicsState.attitude, physicsState.angularVelocity, null, // targetAttitude (can be set by autopilot mode)
        physicsState.velocity, physicsState.position, physicsState.altitude, physicsState.verticalSpeed, totalMass, maxThrust, currentThrust, gravity, dt);
        // 6. Apply autopilot throttle commands (if active)
        if (flightControlState.autopilotMode !== 'off' && mainEngineState.status === 'running') {
            this.mainEngine.setThrottle(flightControlState.throttleCommand.throttle);
        }
        // 7. Apply gimbal autopilot commands (if active)
        if (this.flightControl.isGimbalAutopilotEnabled() && mainEngineState.status === 'running') {
            this.mainEngine.setGimbal(flightControlState.gimbalCommand.pitch, flightControlState.gimbalCommand.yaw);
        }
        // 8. Get propellant consumption from engines
        const mainEngineRates = this.mainEngine.getConsumptionRates();
        const rcsFuelConsumption = this.rcs.consumeFuel(dt, this.getAvailableRCSFuel());
        // 9. Consume fuel from tanks
        const mainFuelTank = this.fuel.getTank('main_1');
        const mainOxidizerTank = this.fuel.getTank('main_2');
        const rcsTank = this.fuel.getTank('rcs');
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
        const mainEngineTorque = { x: 0, y: 0, z: 0 }; // Gimbal torque (simplified for now)
        const rcsThrust = this.rcs.getTotalThrustVector();
        const rcsTorque = this.rcs.getTotalTorque();
        // 12. Calculate terrain elevation at current position
        const coords = this.terrain.positionToLatLon(this.physics.position);
        const terrainElevation = this.terrain.getElevation(coords.lat, coords.lon);
        this.physics.setSurfaceElevation(terrainElevation);
        // 13. Update ship physics
        const totalPropellantConsumed = mainFuelAmount + mainOxidizerAmount + rcsFuelConsumption;
        this.physics.update(dt, mainEngineThrust, mainEngineTorque, rcsThrust, rcsTorque, totalPropellantConsumed);
        // 14. Update thermal system with heat generation
        const componentTemps = new Map();
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
        // 15. Update coolant system with component temperatures
        for (const [name, component] of this.thermal.heatSources) {
            componentTemps.set(name, component.temperature);
        }
        this.coolant.update(dt, t, componentTemps);
        // 16. Update compressed gas system
        this.gas.update(dt, t);
        // 17. Update fuel system
        this.fuel.update(dt, t);
        // 18. Update mission checklists (if mission loaded)
        this.mission.updateChecklists();
        // 19. Increment time
        this.simulationTime += dt;
    }
    /**
     * Get available RCS fuel
     */
    getAvailableRCSFuel() {
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
            mission: this.mission.getCurrentMission()
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
        const thrustDir = { x: 0, y: 0, z: 1 }; // Local Z-axis
        return this.navigation.getTelemetry(physicsState.position, physicsState.velocity, physicsState.attitude, totalMass, this.mainEngine.currentThrustN, thrustDir, mainEngineState.throttle, fuelState.totalFuel, this.initialFuelCapacity, this.mainEngine.specificImpulseSec);
    }
    /**
     * Command interface: Ignite main engine
     */
    igniteMainEngine() {
        return this.mainEngine.ignite();
    }
    /**
     * Command interface: Shutdown main engine
     */
    shutdownMainEngine() {
        this.mainEngine.shutdown();
    }
    /**
     * Command interface: Set main engine throttle
     */
    setMainEngineThrottle(throttle) {
        this.mainEngine.setThrottle(throttle);
    }
    /**
     * Command interface: Activate RCS group
     */
    activateRCS(groupName) {
        return this.rcs.activateGroup(groupName);
    }
    /**
     * Command interface: Deactivate RCS group
     */
    deactivateRCS(groupName) {
        this.rcs.deactivateGroup(groupName);
    }
    /**
     * Command interface: Start reactor
     */
    startReactor() {
        return this.electrical.startReactor();
    }
    /**
     * Command interface: Start coolant pump
     */
    startCoolantPump(loopId) {
        return this.coolant.startPump(loopId);
    }
    // =============================================================================
    // Flight Control System Commands
    // =============================================================================
    /**
     * Set SAS mode
     */
    setSASMode(mode) {
        this.flightControl.setSASMode(mode);
    }
    /**
     * Get current SAS mode
     */
    getSASMode() {
        return this.flightControl.getSASMode();
    }
    /**
     * Set autopilot mode
     */
    setAutopilotMode(mode) {
        this.flightControl.setAutopilotMode(mode);
    }
    /**
     * Get current autopilot mode
     */
    getAutopilotMode() {
        return this.flightControl.getAutopilotMode();
    }
    /**
     * Set target altitude for altitude hold autopilot
     */
    setTargetAltitude(altitude) {
        this.flightControl.setTargetAltitude(altitude);
    }
    /**
     * Set target vertical speed for vertical speed hold autopilot
     */
    setTargetVerticalSpeed(speed) {
        this.flightControl.setTargetVerticalSpeed(speed);
    }
    /**
     * Enable/disable gimbal autopilot
     */
    setGimbalAutopilot(enabled) {
        this.flightControl.setGimbalAutopilot(enabled);
    }
    // =============================================================================
    // Navigation System Commands
    // =============================================================================
    /**
     * Set navigation target
     */
    setNavigationTarget(position) {
        this.navigation.setTarget(position);
    }
    /**
     * Clear navigation target
     */
    clearNavigationTarget() {
        this.navigation.clearTarget();
    }
    /**
     * Get trajectory prediction
     */
    predictTrajectory() {
        const physicsState = this.physics.getState();
        const totalMass = this.physics.dryMass + this.physics.propellantMass;
        const thrustDir = { x: 0, y: 0, z: 1 };
        return this.navigation.predictImpact(physicsState.position, physicsState.velocity, totalMass, this.mainEngine.currentThrustN, thrustDir);
    }
    /**
     * Get suicide burn data
     */
    getSuicideBurnData() {
        const physicsState = this.physics.getState();
        const totalMass = this.physics.dryMass + this.physics.propellantMass;
        return this.navigation.calculateSuicideBurn(physicsState.altitude, physicsState.verticalSpeed, totalMass, this.mainEngine.maxThrustN);
    }
    /**
     * Render navball display
     */
    renderNavball() {
        const physicsState = this.physics.getState();
        return this.navigation.renderNavball(physicsState.attitude, physicsState.velocity);
    }
    // =============================================================================
    // Mission System Commands
    // =============================================================================
    /**
     * Load mission
     */
    loadMission(mission) {
        this.mission.loadMission(mission);
    }
    /**
     * Start mission
     */
    startMission() {
        this.mission.startMission(this.simulationTime);
    }
    /**
     * Get current mission
     */
    getCurrentMission() {
        return this.mission.getCurrentMission();
    }
    /**
     * Complete mission objective
     */
    completeObjective(objectiveId) {
        this.mission.completeObjective(objectiveId);
    }
    /**
     * Calculate mission score
     */
    calculateMissionScore(landingSpeed, landingAngle) {
        const physicsState = this.physics.getState();
        const fuelState = this.fuel.getState();
        const currentMission = this.mission.getCurrentMission();
        if (!currentMission) {
            throw new Error('No active mission');
        }
        // Get target position from landing zone
        const targetPos = { x: 0, y: 0, z: 1737400 }; // Simplified
        return this.mission.calculateMissionScore(landingSpeed, landingAngle, physicsState.position, targetPos, fuelState.totalFuel, 95, // System health (simplified)
        this.simulationTime);
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
exports.Spacecraft = Spacecraft;
//# sourceMappingURL=spacecraft.js.map