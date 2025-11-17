/**
 * Weapon Systems
 *
 * Implements railguns, coilguns, missiles, lasers, and projectile physics
 * NO RENDERING - physics only
 */
import { Vector3 } from './math-utils';
import { World } from './world';
import { IntegratedShip } from './integrated-ship';
export declare enum WeaponType {
    RAILGUN = "railgun",
    COILGUN = "coilgun",
    MISSILE = "missile",
    LASER = "laser"
}
export interface Weapon {
    id: string;
    type: WeaponType;
    mountPoint: Vector3;
    aimDirection: Vector3;
    damage: number;
    projectileSpeed?: number;
    projectileMass?: number;
    range: number;
    rateOfFire: number;
    powerDraw: number;
    heatGeneration: number;
    ammoCapacity?: number;
    ammoRemaining?: number;
    cooldown: number;
    compartmentId: string;
}
export interface FiringResult {
    success: boolean;
    reason?: string;
    projectile?: Projectile;
}
export interface ProjectileConfig {
    position: Vector3;
    velocity: Vector3;
    mass: number;
    damage: number;
    lifetime: number;
}
type EventCallback = (...args: any[]) => void;
/**
 * Projectile - physical projectile in space
 */
export declare class Projectile {
    private position;
    private velocity;
    private mass;
    private damage;
    private lifetime;
    private alive;
    private eventListeners;
    constructor(config: ProjectileConfig);
    /**
     * Update projectile physics
     */
    update(dt: number, world: World): void;
    /**
     * Check for hits along trajectory
     */
    private checkHit;
    /**
     * Handle impact with target
     */
    private handleImpact;
    /**
     * Event listener
     */
    on(event: string, callback: EventCallback): void;
    /**
     * Emit event
     */
    private emit;
    getPosition(): Vector3;
    getVelocity(): Vector3;
    isAlive(): boolean;
}
/**
 * Weapon System - manages all weapons on a ship
 */
export declare class WeaponSystem {
    private ship;
    private weapons;
    constructor(ship: IntegratedShip);
    /**
     * Add weapon to ship
     */
    addWeapon(weapon: Weapon): void;
    /**
     * Fire a weapon
     */
    fire(weaponId: string, aimDirection: Vector3): FiringResult;
    /**
     * Fire projectile weapon (railgun/coilgun)
     */
    private fireProjectileWeapon;
    /**
     * Update all weapons
     */
    update(dt: number): void;
    /**
     * Get weapon by ID
     */
    getWeapon(id: string): Weapon | undefined;
    /**
     * Get all weapons
     */
    getAllWeapons(): Weapon[];
}
/**
 * Projectile Manager - tracks all projectiles in the world
 */
export declare class ProjectileManager {
    private projectiles;
    /**
     * Add projectile to tracking
     */
    addProjectile(projectile: Projectile): void;
    /**
     * Update all projectiles
     */
    update(dt: number, world: World): void;
    /**
     * Get projectile count
     */
    getProjectileCount(): number;
    /**
     * Get all projectiles
     */
    getAllProjectiles(): Projectile[];
}
export {};
//# sourceMappingURL=weapons.d.ts.map