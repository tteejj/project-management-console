/**
 * System Damage Integration
 *
 * Links hull damage to system failures, handles cascading failures
 */
import { HullStructure } from './hull-damage';
export declare enum SystemType {
    POWER = "power",
    LIFE_SUPPORT = "life_support",
    PROPULSION = "propulsion",
    WEAPONS = "weapons",
    SENSORS = "sensors",
    CONTROL = "control",
    THERMAL = "thermal",
    UTILITY = "utility"
}
export declare enum SystemStatus {
    ONLINE = "online",
    DEGRADED = "degraded",
    OFFLINE = "offline",
    DESTROYED = "destroyed"
}
export interface ShipSystem {
    id: string;
    name: string;
    type: SystemType;
    compartmentId: string;
    integrity: number;
    status: SystemStatus;
    operational: boolean;
    powerDraw: number;
    requiresAtmosphere?: boolean;
    dependencies?: string[];
    isCritical?: boolean;
}
export interface SystemDamageConfig {
    systems: ShipSystem[];
    hull: HullStructure;
}
export interface SystemFailure {
    systemId: string;
    systemName: string;
    integrity: number;
    reason: string;
    isCritical: boolean;
}
export interface DamageReport {
    damagedSystems: SystemFailure[];
    criticalFailures: SystemFailure[];
    totalSystems: number;
    operationalSystems: number;
}
/**
 * System Damage Manager
 */
export declare class SystemDamageManager {
    private systems;
    private hull;
    private readonly DEGRADED_THRESHOLD;
    private readonly OFFLINE_THRESHOLD;
    private readonly DESTROYED_THRESHOLD;
    constructor(config: SystemDamageConfig);
    /**
     * Update system damage
     */
    update(dt: number): void;
    /**
     * Update system status based on integrity
     */
    private updateSystemStatus;
    /**
     * Apply damage from compartment state
     */
    private applyCompartmentDamage;
    /**
     * Check system dependencies
     */
    private checkDependencies;
    /**
     * Get damage report
     */
    getDamageReport(): DamageReport;
    /**
     * Get failure reason for system
     */
    private getFailureReason;
    /**
     * Get system effectiveness (0-1 based on integrity and status)
     */
    getSystemEffectiveness(systemId: string): number;
    /**
     * Get system by ID
     */
    getSystem(id: string): ShipSystem | undefined;
    /**
     * Add system
     */
    addSystem(system: ShipSystem): void;
    /**
     * Get all systems
     */
    getAllSystems(): ShipSystem[];
}
//# sourceMappingURL=system-damage.d.ts.map