"use strict";
/**
 * Weapon Systems
 *
 * Implements railguns, coilguns, missiles, lasers, and projectile physics
 * NO RENDERING - physics only
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProjectileManager = exports.WeaponSystem = exports.Projectile = exports.WeaponType = void 0;
const math_utils_1 = require("./math-utils");
var WeaponType;
(function (WeaponType) {
    WeaponType["RAILGUN"] = "railgun";
    WeaponType["COILGUN"] = "coilgun";
    WeaponType["MISSILE"] = "missile";
    WeaponType["LASER"] = "laser";
})(WeaponType || (exports.WeaponType = WeaponType = {}));
/**
 * Projectile - physical projectile in space
 */
class Projectile {
    constructor(config) {
        this.alive = true;
        this.eventListeners = new Map();
        this.position = { ...config.position };
        this.velocity = { ...config.velocity };
        this.mass = config.mass;
        this.damage = config.damage;
        this.lifetime = config.lifetime;
    }
    /**
     * Update projectile physics
     */
    update(dt, world) {
        if (!this.alive)
            return;
        // PHASE 1: Apply gravity
        const gravity = world.getGravityAt(this.position);
        this.velocity = math_utils_1.VectorMath.add(this.velocity, math_utils_1.VectorMath.scale(gravity, dt));
        // PHASE 2: Calculate new position
        const displacement = math_utils_1.VectorMath.scale(this.velocity, dt);
        const newPosition = math_utils_1.VectorMath.add(this.position, displacement);
        // PHASE 3: Check for hits using sweep test
        const hit = this.checkHit(this.position, newPosition, world);
        if (hit) {
            this.handleImpact(hit.body, hit.point, world);
            this.alive = false;
            return;
        }
        // PHASE 4: Update position
        this.position = newPosition;
        // PHASE 5: Lifetime decay
        this.lifetime -= dt;
        if (this.lifetime <= 0) {
            this.alive = false;
        }
    }
    /**
     * Check for hits along trajectory
     */
    checkHit(startPos, endPos, world) {
        const bodies = world.getAllBodies();
        const direction = math_utils_1.VectorMath.normalize(math_utils_1.VectorMath.subtract(endPos, startPos));
        const distance = math_utils_1.VectorMath.distance(startPos, endPos);
        let closestHit = null;
        for (const body of bodies) {
            // Simple sphere intersection
            const toBody = math_utils_1.VectorMath.subtract(body.position, startPos);
            const projection = math_utils_1.VectorMath.dot(toBody, direction);
            // Check if body is ahead of us
            if (projection < 0 || projection > distance)
                continue;
            const closestPoint = math_utils_1.VectorMath.add(startPos, math_utils_1.VectorMath.scale(direction, projection));
            const distToBody = math_utils_1.VectorMath.distance(closestPoint, body.position);
            if (distToBody <= body.radius) {
                const hitDistance = projection - Math.sqrt(body.radius * body.radius - distToBody * distToBody);
                if (!closestHit || hitDistance < closestHit.distance) {
                    const hitPoint = math_utils_1.VectorMath.add(startPos, math_utils_1.VectorMath.scale(direction, hitDistance));
                    closestHit = { body, point: hitPoint, distance: hitDistance };
                }
            }
        }
        if (closestHit) {
            return { body: closestHit.body, point: closestHit.point };
        }
        return null;
    }
    /**
     * Handle impact with target
     */
    handleImpact(target, point, world) {
        // Emit hit event
        this.emit('hit', { target, point, damage: this.damage });
        // TODO: Apply damage to IntegratedShip if target is a ship
        // This requires checking if the body belongs to a ship and accessing its damage system
    }
    /**
     * Event listener
     */
    on(event, callback) {
        if (!this.eventListeners.has(event)) {
            this.eventListeners.set(event, []);
        }
        this.eventListeners.get(event).push(callback);
    }
    /**
     * Emit event
     */
    emit(event, ...args) {
        const listeners = this.eventListeners.get(event);
        if (listeners) {
            for (const callback of listeners) {
                callback(...args);
            }
        }
    }
    // Getters
    getPosition() {
        return { ...this.position };
    }
    getVelocity() {
        return { ...this.velocity };
    }
    isAlive() {
        return this.alive;
    }
}
exports.Projectile = Projectile;
/**
 * Weapon System - manages all weapons on a ship
 */
class WeaponSystem {
    constructor(ship) {
        this.weapons = new Map();
        this.ship = ship;
    }
    /**
     * Add weapon to ship
     */
    addWeapon(weapon) {
        this.weapons.set(weapon.id, weapon);
    }
    /**
     * Fire a weapon
     */
    fire(weaponId, aimDirection) {
        const weapon = this.weapons.get(weaponId);
        if (!weapon) {
            return { success: false, reason: 'weapon_not_found' };
        }
        // Check cooldown
        if (weapon.cooldown > 0) {
            return { success: false, reason: 'on_cooldown' };
        }
        // Check ammo
        if (weapon.ammoRemaining !== undefined && weapon.ammoRemaining <= 0) {
            return { success: false, reason: 'out_of_ammo' };
        }
        // Fire based on weapon type
        let projectile;
        switch (weapon.type) {
            case WeaponType.RAILGUN:
            case WeaponType.COILGUN:
                projectile = this.fireProjectileWeapon(weapon, aimDirection);
                break;
            case WeaponType.LASER:
                // Instant hit - no projectile
                // TODO: Implement hitscan laser
                break;
            case WeaponType.MISSILE:
                // TODO: Implement guided missile
                break;
        }
        // Consume ammo
        if (weapon.ammoRemaining !== undefined) {
            weapon.ammoRemaining--;
        }
        // Set cooldown
        weapon.cooldown = 60 / weapon.rateOfFire;
        return {
            success: true,
            projectile
        };
    }
    /**
     * Fire projectile weapon (railgun/coilgun)
     */
    fireProjectileWeapon(weapon, aimDirection) {
        // Calculate projectile position (mount point + ship position)
        const shipPos = this.ship.getPosition();
        const projectilePos = math_utils_1.VectorMath.add(shipPos, weapon.mountPoint);
        // Calculate projectile velocity (ship velocity + weapon velocity)
        const shipVel = this.ship.getVelocity();
        const weaponVelocity = math_utils_1.VectorMath.scale(math_utils_1.VectorMath.normalize(aimDirection), weapon.projectileSpeed || 0);
        const projectileVel = math_utils_1.VectorMath.add(shipVel, weaponVelocity);
        // Create projectile
        const projectile = new Projectile({
            position: projectilePos,
            velocity: projectileVel,
            mass: weapon.projectileMass || 1,
            damage: weapon.damage,
            lifetime: 60 // 1 minute default
        });
        // Apply recoil to ship
        const recoilMomentum = math_utils_1.VectorMath.scale(weaponVelocity, -(weapon.projectileMass || 1));
        this.ship.applyImpulse(recoilMomentum);
        return projectile;
    }
    /**
     * Update all weapons
     */
    update(dt) {
        for (const weapon of this.weapons.values()) {
            if (weapon.cooldown > 0) {
                weapon.cooldown = Math.max(0, weapon.cooldown - dt);
            }
        }
    }
    /**
     * Get weapon by ID
     */
    getWeapon(id) {
        return this.weapons.get(id);
    }
    /**
     * Get all weapons
     */
    getAllWeapons() {
        return Array.from(this.weapons.values());
    }
}
exports.WeaponSystem = WeaponSystem;
/**
 * Projectile Manager - tracks all projectiles in the world
 */
class ProjectileManager {
    constructor() {
        this.projectiles = [];
    }
    /**
     * Add projectile to tracking
     */
    addProjectile(projectile) {
        this.projectiles.push(projectile);
    }
    /**
     * Update all projectiles
     */
    update(dt, world) {
        // Update all projectiles
        for (const projectile of this.projectiles) {
            if (projectile.isAlive()) {
                projectile.update(dt, world);
            }
        }
        // Remove dead projectiles
        this.projectiles = this.projectiles.filter(p => p.isAlive());
    }
    /**
     * Get projectile count
     */
    getProjectileCount() {
        return this.projectiles.length;
    }
    /**
     * Get all projectiles
     */
    getAllProjectiles() {
        return [...this.projectiles];
    }
}
exports.ProjectileManager = ProjectileManager;
//# sourceMappingURL=weapons.js.map