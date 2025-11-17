/**
 * Main Engine Physics Module
 *
 * Simulates:
 * - Rocket engine combustion and thrust
 * - Tsiolkovsky rocket equation and specific impulse
 * - Gimbal control for thrust vectoring
 * - Fuel/oxidizer consumption from tanks
 * - Chamber pressure and temperature dynamics
 * - Ignition sequence and startup transients
 * - Engine health degradation
 * - Thermal effects and cooling requirements
 */
export interface MainEngineConfig {
    maxThrustN?: number;
    specificImpulseSec?: number;
    maxGimbalDeg?: number;
    ignitionTimeS?: number;
    shutdownTimeS?: number;
    minThrottle?: number;
    chamberPressureBar?: number;
    chamberTempK?: number;
    nozzleAreaM2?: number;
    fuelOxidizerRatio?: number;
}
export declare class MainEngine {
    maxThrustN: number;
    specificImpulseSec: number;
    maxGimbalDeg: number;
    ignitionTimeS: number;
    shutdownTimeS: number;
    minThrottle: number;
    chamberPressureBar: number;
    chamberTempK: number;
    nozzleAreaM2: number;
    fuelOxidizerRatio: number;
    status: 'off' | 'igniting' | 'running' | 'shutdown';
    throttle: number;
    currentThrustN: number;
    gimbalPitchDeg: number;
    gimbalYawDeg: number;
    private ignitionProgress;
    private shutdownProgress;
    currentChamberPressureBar: number;
    currentChamberTempK: number;
    health: number;
    totalFiredSeconds: number;
    ignitionCount: number;
    restartCooldownS: number;
    totalFuelConsumedKg: number;
    totalOxidizerConsumedKg: number;
    events: Array<{
        time: number;
        type: string;
        data: any;
    }>;
    private readonly G0;
    constructor(config?: MainEngineConfig);
    /**
     * Main update loop
     */
    update(dt: number, simulationTime: number): void;
    /**
     * Update engine state machine
     */
    private updateEngineState;
    /**
     * Calculate thrust output
     * F = ṁ * v_e
     * where v_e = Isp * g0
     */
    private calculateThrust;
    /**
     * Degrade engine health based on usage
     */
    private degradeHealth;
    /**
     * Calculate mass flow rate
     * ṁ = F / (Isp * g0)
     */
    getMassFlowRateKgPerSec(): number;
    /**
     * Get fuel and oxidizer consumption rates
     */
    getConsumptionRates(): {
        fuelKgPerSec: number;
        oxidizerKgPerSec: number;
    };
    /**
     * Consume propellant for this timestep
     * Returns actual consumption (may be limited by available propellant)
     */
    consumePropellant(dt: number, availableFuelKg: number, availableOxidizerKg: number): {
        fuelConsumed: number;
        oxidizerConsumed: number;
    };
    /**
     * Ignite the engine
     */
    ignite(): boolean;
    /**
     * Shutdown the engine
     */
    shutdown(): void;
    /**
     * Set throttle (0.0 to 1.0)
     */
    setThrottle(throttle: number): void;
    /**
     * Set gimbal angles
     */
    setGimbal(pitchDeg: number, yawDeg: number): void;
    /**
     * Get thrust vector components
     * Returns [x, y, z] in Newtons (assuming z is thrust axis)
     */
    getThrustVector(): {
        x: number;
        y: number;
        z: number;
    };
    /**
     * Get heat generation from engine
     */
    getHeatGenerationW(): number;
    /**
     * Get current state
     */
    getState(): {
        status: "off" | "igniting" | "running" | "shutdown";
        throttle: number;
        currentThrustN: number;
        currentThrustKN: number;
        gimbalPitch: number;
        gimbalYaw: number;
        chamberPressureBar: number;
        chamberTempK: number;
        health: number;
        totalFiredSeconds: number;
        ignitionCount: number;
        massFlowRateKgPerSec: number;
        totalFuelConsumedKg: number;
        totalOxidizerConsumedKg: number;
        restartCooldownS: number;
    };
    /**
     * Log an event
     */
    private logEvent;
    /**
     * Get all events
     */
    getEvents(): {
        time: number;
        type: string;
        data: any;
    }[];
    /**
     * Clear events
     */
    clearEvents(): void;
}
//# sourceMappingURL=main-engine.d.ts.map