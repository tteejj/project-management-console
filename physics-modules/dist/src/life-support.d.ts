/**
 * Life Support System
 *
 * Manages oxygen, CO2, pressure, and crew health
 * Critical for submarine simulator feel - crew needs air!
 */
import { HullStructure } from './hull-damage';
export declare enum CrewStatus {
    HEALTHY = "healthy",
    HYPOXIA = "hypoxia",
    UNCONSCIOUS = "unconscious",
    DEAD = "dead"
}
export interface CrewMember {
    id: string;
    name: string;
    location: string;
    health: number;
    oxygenLevel: number;
    status: CrewStatus;
}
export interface LifeSupportConfig {
    oxygenGenerationRate: number;
    co2ScrubberRate: number;
    powered?: boolean;
}
export interface LifeSupportStatistics {
    oxygenConsumed: number;
    co2Produced: number;
    healthyCrew: number;
    hypoxicCrew: number;
    unconsciousCrew: number;
    deadCrew: number;
}
/**
 * Life Support System
 */
export declare class LifeSupportSystem {
    private hull;
    private crew;
    private config;
    private totalOxygenConsumed;
    private totalCO2Produced;
    private readonly OXYGEN_CONSUMPTION_RATE;
    private readonly CO2_PRODUCTION_RATE;
    private readonly HYPOXIA_PRESSURE;
    private readonly CRITICAL_PRESSURE;
    private readonly OXYGEN_RECOVERY_RATE;
    private readonly OXYGEN_DEPLETION_RATE;
    constructor(hull: HullStructure, crew: CrewMember[], config: LifeSupportConfig);
    /**
     * Update life support system
     */
    update(dt: number): void;
    /**
     * Update crew member health
     */
    private updateCrewHealth;
    /**
     * Get statistics
     */
    getStatistics(): LifeSupportStatistics;
    /**
     * Set power state
     */
    setPowered(powered: boolean): void;
    /**
     * Get all crew
     */
    getCrew(): CrewMember[];
}
//# sourceMappingURL=life-support.d.ts.map