/**
 * Thermal System Physics Module
 *
 * Simulates:
 * - Per-component heat tracking
 * - Temperature dynamics with mass and specific heat
 * - Heat transfer between components and compartments
 * - Thermal conduction through bulkheads
 * - Heat generation from inefficiencies
 * - Passive cooling and radiation
 */
export interface HeatSource {
    name: string;
    heatGenerationW: number;
    temperature: number;
    mass: number;
    specificHeat: number;
    compartmentId: number;
}
export interface Compartment {
    id: number;
    name: string;
    volume: number;
    gasMass: number;
    temperature: number;
    neighborIds: number[];
}
interface ThermalSystemConfig {
    heatSources?: HeatSource[];
    compartments?: Compartment[];
    thermalConductivity?: number;
    ambientSpaceTemp?: number;
}
export declare class ThermalSystem {
    heatSources: Map<string, HeatSource>;
    compartments: Compartment[];
    thermalConductivity: number;
    ambientSpaceTemp: number;
    totalHeatGenerated: number;
    events: Array<{
        time: number;
        type: string;
        data: any;
    }>;
    constructor(config?: ThermalSystemConfig);
    private createDefaultHeatSources;
    private createDefaultCompartments;
    /**
     * Main update loop
     */
    update(dt: number, simulationTime: number): void;
    /**
     * Update component temperatures based on heat generation
     */
    private updateComponentTemperatures;
    /**
     * Transfer heat from hot components to compartment air
     */
    private transferHeatToCompartments;
    /**
     * Conduct heat between adjacent compartments
     */
    private conductHeatBetweenCompartments;
    /**
     * Check for overheating warnings
     */
    private checkWarnings;
    /**
     * Track total heat generation
     */
    private trackHeatGeneration;
    /**
     * Get thermal conductance for a component (W/K)
     */
    private getThermalConductance;
    /**
     * Get temperature limit for component (K)
     */
    private getTemperatureLimit;
    /**
     * Add heat to a specific component
     */
    addHeat(componentName: string, joules: number): void;
    /**
     * Set heat generation rate for a component
     */
    setHeatGeneration(componentName: string, watts: number): void;
    /**
     * Get component temperature
     */
    getComponentTemperature(componentName: string): number;
    /**
     * Get compartment temperature
     */
    getCompartmentTemperature(compartmentId: number): number;
    /**
     * Set compartment temperature (for external cooling/heating)
     */
    setCompartmentTemperature(compartmentId: number, tempK: number): void;
    /**
     * Get component by name
     */
    getComponent(name: string): HeatSource | undefined;
    /**
     * Get compartment by ID
     */
    getCompartment(id: number): Compartment | undefined;
    /**
     * Get current state for debugging/testing
     */
    getState(): {
        components: {
            name: string;
            temperature: number;
            heatGeneration: number;
            compartmentId: number;
        }[];
        compartments: {
            id: number;
            name: string;
            temperature: number;
            gasMass: number;
        }[];
        totalHeatGenerated: number;
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
//# sourceMappingURL=thermal-system.d.ts.map