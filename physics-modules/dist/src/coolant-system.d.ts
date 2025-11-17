/**
 * Coolant System Physics Module
 *
 * Simulates:
 * - Dual redundant coolant loops with fluid dynamics
 * - Heat absorption from thermal system components
 * - Radiator panels with Stefan-Boltzmann radiation
 * - Coolant temperature and flow rate tracking
 * - Pump operation and power consumption
 * - Loop isolation and cross-connect for redundancy
 * - Coolant loss from leaks
 * - Freezing and boiling conditions
 */
export interface CoolantLoop {
    id: number;
    name: string;
    coolantMassKg: number;
    maxCapacityKg: number;
    temperature: number;
    flowRateLPerMin: number;
    maxFlowRateLPerMin: number;
    pumpActive: boolean;
    pumpPowerW: number;
    cooledComponents: string[];
    radiatorAreaM2: number;
    radiatorTemperature: number;
    leakRateLPerMin: number;
    frozen: boolean;
    boiling: boolean;
}
export interface CoolantSystemConfig {
    loops?: CoolantLoop[];
    coolantSpecificHeat?: number;
    freezingPoint?: number;
    boilingPoint?: number;
    crossConnectOpen?: boolean;
}
export declare class CoolantSystem {
    loops: CoolantLoop[];
    coolantSpecificHeat: number;
    freezingPoint: number;
    boilingPoint: number;
    crossConnectOpen: boolean;
    totalHeatRejected: number;
    events: Array<{
        time: number;
        type: string;
        data: any;
    }>;
    private readonly STEFAN_BOLTZMANN;
    private readonly COOLANT_DENSITY;
    constructor(config?: CoolantSystemConfig);
    private createDefaultLoops;
    /**
     * Main update loop
     */
    update(dt: number, simulationTime: number, componentTemperatures?: Map<string, number>): void;
    /**
     * Update pump states and flow rates
     */
    private updatePumps;
    /**
     * Absorb heat from components being cooled
     */
    private absorbHeatFromComponents;
    /**
     * Radiate heat to space via radiator panels
     * Uses Stefan-Boltzmann law: P = ε * σ * A * T⁴
     */
    private radiateHeatToSpace;
    /**
     * Handle coolant loss from leaks
     */
    private handleLeaks;
    /**
     * Check for freezing or boiling
     */
    private checkPhaseChanges;
    /**
     * Balance coolant between loops when cross-connect is open
     */
    private balanceLoops;
    /**
     * Check for warning conditions
     */
    private checkWarnings;
    /**
     * Start a coolant pump
     */
    startPump(loopId: number): boolean;
    /**
     * Stop a coolant pump
     */
    stopPump(loopId: number): void;
    /**
     * Open cross-connect valve
     */
    openCrossConnect(): void;
    /**
     * Close cross-connect valve
     */
    closeCrossConnect(): void;
    /**
     * Add coolant to a loop (refill)
     */
    addCoolant(loopId: number, massKg: number): boolean;
    /**
     * Create a leak in a loop
     */
    createLeak(loopId: number, leakRateLPerMin: number): void;
    /**
     * Repair a leak
     */
    repairLeak(loopId: number): void;
    /**
     * Get total pump power consumption
     */
    getPumpPowerDraw(): number;
    /**
     * Get loop by ID
     */
    getLoop(loopId: number): CoolantLoop | undefined;
    /**
     * Get current state for debugging/testing
     */
    getState(): {
        loops: {
            id: number;
            name: string;
            coolantMassKg: number;
            percentFull: number;
            temperature: number;
            radiatorTemperature: number;
            flowRateLPerMin: number;
            pumpActive: boolean;
            pumpPowerW: number;
            frozen: boolean;
            boiling: boolean;
            leaking: boolean;
        }[];
        crossConnectOpen: boolean;
        totalHeatRejected: number;
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
//# sourceMappingURL=coolant-system.d.ts.map