/**
 * Unified Ship - Complete integration of physics and subsystems
 *
 * Single entity that exists in BOTH the physics world AND has all subsystems
 */
import { Vector3 } from './math-utils';
import { World } from './world';
import { IntegratedShip } from './integrated-ship';
import { ShipConfig } from './ship-configuration';
/**
 * Unified Ship that seamlessly integrates physics and subsystems
 */
export declare class UnifiedShip {
    private integratedShip;
    private completeShip;
    constructor(config: ShipConfig, world: World);
    /**
     * Update - automatically syncs physics and subsystems
     */
    update(dt: number): void;
    /**
     * Sync state from physics representation to subsystems
     */
    private syncFromPhysics;
    /**
     * Calculate ship radius from mass (rough estimate)
     */
    private calculateRadius;
    /**
     * Apply thrust (future feature - connects subsystems to physics)
     */
    applyThrust(direction: Vector3, magnitude: number): void;
    /**
     * Get complete ship status
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
    /**
     * Get ship ID
     */
    get id(): string;
    /**
     * Get ship name
     */
    get name(): string;
    /**
     * Get current position (from physics)
     */
    getPosition(): Vector3;
    /**
     * Get current velocity (from physics)
     */
    getVelocity(): Vector3;
    /**
     * Access subsystems directly
     */
    get power(): import("./power-budget").PowerBudgetSystem;
    get thermal(): import("./thermal-budget").ThermalBudgetSystem;
    get lifeSupport(): import("./life-support").LifeSupportSystem;
    get systemDamage(): import("./system-damage").SystemDamageManager;
    get damageControl(): import("./damage-control").DamageControlSystem;
    get combatComputer(): import("./combat-computer").CombatComputer;
    get hull(): import("./hull-damage").HullStructure;
    /**
     * Access physics ship (for adding to simulation)
     */
    get physicsBody(): IntegratedShip;
}
//# sourceMappingURL=unified-ship.d.ts.map