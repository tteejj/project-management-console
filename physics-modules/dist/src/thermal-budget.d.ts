/**
 * Thermal Budget System
 *
 * Manages heat generation, transfer, cooling, and thermal limits
 * Critical for long-duration missions - heat management is survival!
 */
export declare enum CoolingType {
    LIQUID_LOOP = "liquid_loop",
    RADIATOR = "radiator",
    HEAT_PIPE = "heat_pipe",
    THERMOELECTRIC = "thermoelectric"
}
export interface ThermalComponent {
    id: string;
    name: string;
    temperature: number;
    mass: number;
    specificHeat: number;
    surfaceArea: number;
    heatGeneration: number;
    compartmentId: string;
    maxSafeTemp?: number;
    exposedToSpace?: boolean;
    powerDraw?: number;
    efficiency?: number;
    emissivity?: number;
}
export interface ThermalCompartment {
    id: string;
    name: string;
    temperature: number;
    volume: number;
    airMass: number;
    connectedCompartments: string[];
}
export interface CoolingSystem {
    id: string;
    type: CoolingType;
    coolingCapacity: number;
    powerDraw: number;
    efficiency: number;
    targetComponentIds: string[];
    active: boolean;
    flowRate?: number;
}
export interface ThermalConfig {
    components: ThermalComponent[];
    compartments: ThermalCompartment[];
    coolingSystems: CoolingSystem[];
}
export interface ThermalWarning {
    componentId: string;
    type: 'overheating' | 'critical';
    temperature: number;
    maxSafe: number;
}
export interface ThermalStatistics {
    totalHeatGenerated: number;
    totalHeatRejected: number;
    averageTemperature: number;
    hottestComponent: string;
    hottestTemperature: number;
}
/**
 * Thermal Budget System
 */
export declare class ThermalBudgetSystem {
    private components;
    private compartments;
    private coolingSystems;
    private totalHeatGenerated;
    private totalHeatRejected;
    private readonly STEFAN_BOLTZMANN;
    private readonly AIR_SPECIFIC_HEAT;
    private readonly CONVECTION_COEFF;
    private readonly CONDUCTION_COEFF;
    constructor(config: ThermalConfig);
    /**
     * Update thermal budget system
     */
    update(dt: number): void;
    /**
     * Get thermal warnings
     */
    getWarnings(): ThermalWarning[];
    /**
     * Get statistics
     */
    getStatistics(): ThermalStatistics;
    /**
     * Get component by ID
     */
    getComponent(id: string): ThermalComponent | undefined;
    /**
     * Get compartment by ID
     */
    getCompartment(id: string): ThermalCompartment | undefined;
    /**
     * Get cooling system by ID
     */
    getCoolingSystem(id: string): CoolingSystem | undefined;
    /**
     * Add component
     */
    addComponent(component: ThermalComponent): void;
    /**
     * Add compartment
     */
    addCompartment(compartment: ThermalCompartment): void;
    /**
     * Add cooling system
     */
    addCoolingSystem(cooling: CoolingSystem): void;
}
//# sourceMappingURL=thermal-budget.d.ts.map