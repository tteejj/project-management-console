/**
 * Compressed Gas System Physics Module
 *
 * Simulates:
 * - High-pressure gas bottles (N2, O2, He)
 * - Ideal gas law for pressure-temperature relationship
 * - Gas consumption and pressure drop
 * - Temperature effects from environment
 * - Overpressure warnings and rupture
 * - Regulated output pressure
 */
export interface GasBottle {
    gas: 'N2' | 'O2' | 'He';
    pressureBar: number;
    volumeL: number;
    massKg: number;
    maxPressureBar: number;
    temperature: number;
    uses: string[];
    ruptured: boolean;
}
export interface Regulator {
    name: string;
    inputBottleIndex: number;
    outputPressureBar: number;
    flowRateLPerMin: number;
    active: boolean;
}
interface CompressedGasSystemConfig {
    bottles?: GasBottle[];
    regulators?: Regulator[];
    ambientTemperature?: number;
}
export declare class CompressedGasSystem {
    bottles: GasBottle[];
    regulators: Regulator[];
    ambientTemperature: number;
    totalGasConsumed: Map<string, number>;
    events: Array<{
        time: number;
        type: string;
        data: any;
    }>;
    constructor(config?: CompressedGasSystemConfig);
    private createDefaultBottles;
    private createDefaultRegulators;
    /**
     * Main update loop
     */
    update(dt: number, simulationTime: number): void;
    /**
     * Update bottle temperatures - they equilibrate with ambient
     */
    private updateBottleTemperatures;
    /**
     * Update bottle pressures using ideal gas law
     * P = (n * R * T) / V
     * where n = mass / molar_mass
     */
    private updateBottlePressures;
    /**
     * Check for overpressure and handle rupture
     */
    private checkOverpressure;
    /**
     * Rupture a bottle (catastrophic failure)
     */
    private ruptureBottle;
    /**
     * Check for warning conditions
     */
    private checkWarnings;
    /**
     * Consume gas from a specific bottle
     * Returns actual mass consumed (may be less than requested)
     */
    consumeGas(bottleIndex: number, massKg: number): number;
    /**
     * Activate a regulator to provide gas flow
     * Returns actual flow rate achieved (L/min)
     */
    activateRegulator(regulatorName: string): number;
    /**
     * Deactivate a regulator
     */
    deactivateRegulator(regulatorName: string): void;
    /**
     * Get regulated output pressure from a regulator
     */
    getRegulatorPressure(regulatorName: string): number;
    /**
     * Transfer gas between bottles (if needed for balancing)
     */
    transferGas(fromBottleIndex: number, toBottleIndex: number, massKg: number): boolean;
    /**
     * Get molar mass for gas type (in kg/mol for consistency with massKg)
     */
    private getMolarMass;
    /**
     * Get bottle by index
     */
    getBottle(index: number): GasBottle | undefined;
    /**
     * Get bottle by gas type
     */
    getBottleByGas(gasType: 'N2' | 'O2' | 'He'): GasBottle | undefined;
    /**
     * Set ambient temperature (from compartment/thermal system)
     */
    setAmbientTemperature(tempK: number): void;
    /**
     * Get current state for debugging/testing
     */
    getState(): {
        bottles: {
            index: number;
            gas: "N2" | "O2" | "He";
            pressureBar: number;
            massKg: number;
            temperature: number;
            percentFull: number;
            ruptured: boolean;
        }[];
        regulators: {
            name: string;
            active: boolean;
            outputPressure: number;
            inputBottle: number;
        }[];
        totalConsumed: {
            [k: string]: number;
        };
        ambientTemperature: number;
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
//# sourceMappingURL=compressed-gas-system.d.ts.map