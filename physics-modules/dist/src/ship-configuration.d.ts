/**
 * Ship Configuration - Unified ship definition
 *
 * Ties together all subsystems into a complete, simulated spacecraft
 */
import { Vector3 } from './math-utils';
import { HullStructure, Compartment, ArmorLayer } from './hull-damage';
import { LifeSupportSystem, CrewMember, LifeSupportConfig } from './life-support';
import { PowerBudgetSystem, PowerSource, PowerConsumer, BatteryBank } from './power-budget';
import { ThermalBudgetSystem, ThermalComponent, ThermalCompartment, CoolingSystem } from './thermal-budget';
import { SystemDamageManager, ShipSystem } from './system-damage';
import { DamageControlSystem } from './damage-control';
import { CombatComputer } from './combat-computer';
/**
 * Complete ship configuration
 */
export interface ShipConfig {
    id: string;
    name: string;
    class: string;
    mass: number;
    position: Vector3;
    velocity: Vector3;
    compartments: Compartment[];
    armorLayers: ArmorLayer[];
    powerSources: PowerSource[];
    powerConsumers: PowerConsumer[];
    batteries: BatteryBank[];
    thermalComponents: ThermalComponent[];
    thermalCompartments: ThermalCompartment[];
    coolingSystems: CoolingSystem[];
    systems: ShipSystem[];
    crew: CrewMember[];
    lifeSupport: LifeSupportConfig;
    weapons?: any[];
}
/**
 * Complete Ship - integrates all subsystems
 */
export declare class CompleteShip {
    id: string;
    name: string;
    class: string;
    hull: HullStructure;
    lifeSupport: LifeSupportSystem;
    power: PowerBudgetSystem;
    thermal: ThermalBudgetSystem;
    systemDamage: SystemDamageManager;
    damageControl: DamageControlSystem;
    combatComputer: CombatComputer;
    position: Vector3;
    velocity: Vector3;
    mass: number;
    constructor(config: ShipConfig);
    /**
     * Update all ship systems
     */
    update(dt: number): void;
    /**
     * Get ship status summary
     */
    getStatus(): {
        ship: {
            id: string;
            name: string;
            class: string;
            position: Vector3;
            velocity: Vector3;
            mass: number;
        };
        power: {
            generation: number;
            consumption: number;
            batteryCharge: number;
            batteryCapacity: number;
            brownout: boolean;
        };
        thermal: {
            averageTemp: number;
            hottestComponent: string;
            hottestTemp: number;
        };
        damage: {
            totalSystems: number;
            operational: number;
            criticalFailures: number;
        };
        lifeSupport: {
            crewHealthy: number;
            crewTotal: number;
            oxygenConsumed: number;
        };
        combat: {
            tracks: number;
        };
    };
}
/**
 * Example ship configurations
 */
export declare class ShipTemplates {
    /**
     * Small frigate - basic combat ship
     */
    static createFrigate(id: string, position: Vector3, velocity: Vector3): CompleteShip;
}
//# sourceMappingURL=ship-configuration.d.ts.map