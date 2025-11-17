/**
 * Hull Damage System
 *
 * Handles armor penetration, hull breaches, structural damage, and atmospheric pressure
 * NO RENDERING - physics only
 */
import { Vector3 } from './math-utils';
export declare enum MaterialType {
    STEEL = "steel",
    TITANIUM = "titanium",
    ALUMINUM = "aluminum",
    COMPOSITE = "composite",
    CERAMIC = "ceramic"
}
export declare enum DamageType {
    KINETIC = "kinetic",
    THERMAL = "thermal",
    EXPLOSIVE = "explosive",
    COLLISION = "collision"
}
export interface ArmorLayer {
    id: string;
    material: MaterialType;
    thickness: number;
    hardness: number;
    density: number;
    integrity: number;
    ablationDepth: number;
}
export interface Breach {
    id: string;
    position: Vector3;
    area: number;
    sealed: boolean;
    damageType: DamageType;
}
export interface Compartment {
    id: string;
    name: string;
    volume: number;
    pressure: number;
    atmosphereIntegrity: number;
    structuralIntegrity: number;
    breaches: Breach[];
    systems: string[];
    connectedCompartments: string[];
}
export interface PenetrationParams {
    projectileMass: number;
    velocity: number;
    diameter: number;
    impactAngle: number;
    armorThickness: number;
    armorHardness: number;
    armorDensity: number;
}
export interface PenetrationResult {
    penetrated: boolean;
    penetrationDepth: number;
    residualEnergy: number;
    spalling?: {
        fragmentCount: number;
        fragmentEnergy: number;
    };
}
export interface ImpactParams {
    position: Vector3;
    velocity: Vector3;
    mass: number;
    damageType: DamageType;
    impactAngle: number;
    thermalEnergy?: number;
    explosiveYield?: number;
}
export interface ImpactResult {
    damageApplied: number;
    breachCreated: boolean;
    affectedCompartments: string[];
    armorPenetrated: boolean;
}
/**
 * Armor penetration calculations
 */
export declare class PenetrationCalculator {
    /**
     * Calculate kinetic energy penetration using simplified DeMarre formula
     * Actual formula is complex - this is a game-appropriate approximation
     */
    static calculateKineticPenetration(params: PenetrationParams): PenetrationResult;
    /**
     * Calculate thermal damage (laser ablation)
     */
    static calculateThermalDamage(thermalEnergy: number, armorThickness: number, armorDensity: number, material: MaterialType): number;
}
/**
 * Hull structure management
 */
export declare class HullStructure {
    private compartments;
    private armorLayers;
    constructor(config: {
        compartments: Compartment[];
        armorLayers: ArmorLayer[];
    });
    getCompartment(id: string): Compartment | undefined;
    getArmorLayer(id: string): ArmorLayer | undefined;
    getCompartmentAtPosition(position: Vector3): Compartment | undefined;
    getOverallIntegrity(): {
        structural: number;
        armor: number;
    };
    getAllCompartments(): Compartment[];
    getAllArmorLayers(): ArmorLayer[];
}
/**
 * Main damage system
 */
export declare class HullDamageSystem {
    private hull;
    private breachIdCounter;
    constructor(hull: HullStructure);
    processImpact(params: ImpactParams): ImpactResult;
    private createBreach;
    /**
     * Update atmospheric pressure in compartments over time
     */
    updatePressure(dt: number): void;
    getHull(): HullStructure;
}
//# sourceMappingURL=hull-damage.d.ts.map