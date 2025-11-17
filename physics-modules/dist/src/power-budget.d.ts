/**
 * Power Budget System
 *
 * Manages power generation, distribution, brownouts, and battery management
 * Critical for submarine simulator feel - power management affects everything!
 */
export declare enum PowerSourceType {
    REACTOR = "reactor",
    SOLAR = "solar",
    RTG = "rtg",// Radioisotope Thermoelectric Generator
    FUEL_CELL = "fuel_cell"
}
export declare enum PowerPriority {
    CRITICAL = 0,// Life support, flight control
    HIGH = 1,// Sensors, RCS
    MEDIUM = 2,// Weapons, non-essential systems
    LOW = 3
}
export interface PowerSource {
    id: string;
    type: PowerSourceType;
    maxOutput: number;
    currentOutput: number;
    efficiency: number;
    powered: boolean;
    sunExposure?: number;
}
export interface PowerConsumer {
    id: string;
    name: string;
    powerDraw: number;
    priority: PowerPriority;
    powered: boolean;
    actualPower: number;
}
export interface BatteryBank {
    id: string;
    capacity: number;
    currentCharge: number;
    maxChargeRate: number;
    maxDischargeRate: number;
    efficiency: number;
}
export interface PowerBudgetConfig {
    sources: PowerSource[];
    consumers: PowerConsumer[];
    batteries: BatteryBank[];
}
export interface PowerStatistics {
    totalGeneration: number;
    totalConsumption: number;
    totalEnergyConsumed: number;
    totalEnergyGenerated: number;
    batteryCharge: number;
    batteryCapacity: number;
    brownoutActive: boolean;
    powerDeficit: number;
}
/**
 * Power Budget System
 */
export declare class PowerBudgetSystem {
    private sources;
    private consumers;
    private batteries;
    private totalEnergyConsumed;
    private totalEnergyGenerated;
    private brownoutActive;
    private powerDeficit;
    constructor(config: PowerBudgetConfig);
    /**
     * Update power budget system
     */
    update(dt: number): void;
    /**
     * Charge batteries from excess power
     */
    private chargeBatteries;
    /**
     * Discharge batteries to meet power deficit
     */
    private dischargeBatteries;
    /**
     * Redistribute additional power from batteries
     */
    private redistributePower;
    /**
     * Get total battery discharge capacity
     */
    private getTotalBatteryDischargeCapacity;
    /**
     * Get consumer by ID
     */
    getConsumer(id: string): PowerConsumer | undefined;
    /**
     * Get source by ID
     */
    getSource(id: string): PowerSource | undefined;
    /**
     * Get battery by ID
     */
    getBattery(id: string): BatteryBank | undefined;
    /**
     * Get statistics
     */
    getStatistics(): PowerStatistics;
    /**
     * Add power source
     */
    addSource(source: PowerSource): void;
    /**
     * Add power consumer
     */
    addConsumer(consumer: PowerConsumer): void;
    /**
     * Add battery
     */
    addBattery(battery: BatteryBank): void;
}
//# sourceMappingURL=power-budget.d.ts.map