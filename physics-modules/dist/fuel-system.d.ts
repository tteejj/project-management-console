/**
 * Fuel System Physics Module
 *
 * Simulates:
 * - Multiple fuel tanks with pressurization
 * - Pressurant gas expansion (ideal gas law)
 * - Fuel flow and pressure dynamics
 * - Fuel transfer between tanks
 * - Center of mass calculation for ship balance
 * - Temperature effects on pressure
 */
import { FuelTank, FuelLine, Vector2 } from './types';
interface FuelSystemConfig {
    tanks: FuelTank[];
    fuelLines: {
        mainEngine: FuelLine;
        rcsManifold: FuelLine;
    };
}
export declare class FuelSystem {
    private tanks;
    private fuelLines;
    totalFuelConsumed: number;
    events: Array<{
        time: number;
        type: string;
        data: any;
    }>;
    constructor(config?: Partial<FuelSystemConfig>);
    private createDefaultTanks;
    /**
     * Main update loop - should be called every simulation step
     */
    update(dt: number, simulationTime: number): void;
    /**
     * Update tank pressures based on pressurant gas expansion
     * Uses ideal gas law: PV = nRT
     */
    private updateTankPressures;
    /**
     * Update fuel line pressures based on connected tanks and pumps
     */
    private updateFuelLines;
    /**
     * Handle fuel transfers between tanks (crossfeed)
     */
    private handleFuelTransfers;
    /**
     * Handle fuel venting to space
     */
    private handleVenting;
    /**
     * Check for warning conditions
     */
    private checkWarnings;
    /**
     * Consume fuel from a specific tank
     */
    consumeFuel(tankId: string, massKg: number): boolean;
    /**
     * Calculate center of mass for fuel distribution
     * Returns offset from ship centerline
     */
    getFuelBalance(): {
        offset: Vector2;
        magnitude: number;
    };
    /**
     * Get total fuel mass across all tanks
     */
    getTotalFuelMass(): number;
    /**
     * Get tank by ID
     */
    getTank(id: string): FuelTank | undefined;
    /**
     * Connect a fuel line to a tank
     */
    connectFuelLine(line: 'mainEngine' | 'rcsManifold', tankId: string): boolean;
    /**
     * Open/close a valve
     */
    setValve(tankId: string, valve: keyof FuelTank['valves'], open: boolean): boolean;
    /**
     * Set up crossfeed between tanks
     */
    setCrossfeed(sourceTankId: string, destTankId: string | undefined): boolean;
    /**
     * Set fuel pump state
     */
    setFuelPump(line: 'mainEngine' | 'rcsManifold', active: boolean): void;
    /**
     * Get current state for debugging/testing
     */
    getState(): {
        tanks: {
            id: string;
            fuelMass: number;
            pressureBar: number;
            temperature: number;
            fuelPercent: number;
        }[];
        fuelLines: {
            mainEngine: FuelLine;
            rcsManifold: FuelLine;
        };
        totalFuel: number;
        balance: {
            offset: Vector2;
            magnitude: number;
        };
        totalConsumed: number;
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
//# sourceMappingURL=fuel-system.d.ts.map