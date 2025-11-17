/**
 * Electrical System Physics Module
 *
 * Simulates:
 * - Reactor power generation (RTG or small fission)
 * - Battery charge/discharge with thermal effects
 * - Capacitor bank for high-draw surges
 * - Dual power buses (A and B) for redundancy
 * - Circuit breakers with overcurrent protection
 * - Power cross-tie capability
 * - Blackout recovery
 * - Heat generation from inefficiency
 */
export interface Reactor {
    fuelRemaining: number;
    fuelDegradationRate: number;
    throttle: number;
    maxOutputKW: number;
    currentOutputKW: number;
    temperature: number;
    maxSafeTemp: number;
    scramTemp: number;
    status: 'offline' | 'starting' | 'online' | 'scrammed';
    startupTime: number;
    startupTimer: number;
    thermalEfficiency: number;
    heatGenerationW: number;
}
export interface Battery {
    chargeKWh: number;
    capacityKWh: number;
    maxChargeRateKW: number;
    maxDischargeRateKW: number;
    temperature: number;
    health: number;
    chargeCycles: number;
}
export interface CapacitorBank {
    chargeKJ: number;
    capacityKJ: number;
    chargeRateKW: number;
    dischargeRateKW: number;
}
export interface PowerBus {
    name: 'A' | 'B';
    voltage: number;
    maxCapacityKW: number;
    currentLoadKW: number;
    faults: number;
    connected: boolean;
    crosstieEnabled: boolean;
}
export interface CircuitBreaker {
    name: string;
    bus: 'A' | 'B';
    on: boolean;
    loadW: number;
    essential: boolean;
    tripThreshold: number;
    tripped: boolean;
}
interface ElectricalSystemConfig {
    reactor?: Partial<Reactor>;
    battery?: Partial<Battery>;
    capacitorBank?: Partial<CapacitorBank>;
    buses?: PowerBus[];
    breakers?: Map<string, CircuitBreaker>;
}
export declare class ElectricalSystem {
    reactor: Reactor;
    battery: Battery;
    capacitorBank: CapacitorBank;
    buses: PowerBus[];
    breakers: Map<string, CircuitBreaker>;
    totalPowerGenerated: number;
    totalPowerConsumed: number;
    events: Array<{
        time: number;
        type: string;
        data: any;
    }>;
    constructor(config?: ElectricalSystemConfig);
    private createDefaultBreakers;
    /**
     * Main update loop
     */
    update(dt: number, simulationTime: number): void;
    /**
     * Update reactor state
     */
    private updateReactor;
    /**
     * Calculate current load on each bus
     */
    private calculateBusLoads;
    /**
     * Check for overcurrent and trip breakers
     */
    private checkOvercurrent;
    /**
     * Handle power cross-tie between buses
     */
    private handleCrosstie;
    /**
     * Manage power balance between generation and consumption
     */
    private managePowerBalance;
    /**
     * Update battery thermal state
     */
    private updateBatteryThermal;
    /**
     * Check for warning conditions
     */
    private checkWarnings;
    /**
     * Update statistics tracking
     */
    private updateStatistics;
    /**
     * Start reactor
     */
    startReactor(): boolean;
    /**
     * Emergency reactor shutdown (SCRAM)
     */
    SCRAM(time: number): void;
    /**
     * Reset reactor from SCRAM (requires manual intervention)
     */
    resetReactor(): boolean;
    /**
     * Set reactor throttle
     */
    setReactorThrottle(throttle: number): void;
    /**
     * Toggle circuit breaker
     */
    toggleBreaker(key: string, on: boolean): boolean;
    /**
     * Enable/disable bus crosstie
     */
    setCrosstie(enable: boolean): void;
    /**
     * Blackout - trip all non-essential breakers
     */
    private blackout;
    /**
     * Get current state for debugging/testing
     */
    getState(): {
        reactor: {
            status: "online" | "offline" | "starting" | "scrammed";
            outputKW: number;
            throttle: number;
            fuelRemaining: number;
            temperature: number;
            heatGenerationW: number;
        };
        battery: {
            chargeKWh: number;
            chargePercent: number;
            temperature: number;
            health: number;
            chargeCycles: number;
        };
        capacitor: {
            chargeKJ: number;
            chargePercent: number;
        };
        buses: {
            name: "A" | "B";
            loadKW: number;
            capacityKW: number;
            loadPercent: number;
            crosstieEnabled: boolean;
        }[];
        totalLoad: number;
        netPower: number;
        breakerStatus: {
            key: string;
            name: string;
            on: boolean;
            tripped: boolean;
            bus: "A" | "B";
        }[];
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
export {};
//# sourceMappingURL=electrical-system.d.ts.map