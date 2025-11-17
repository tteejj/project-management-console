"use strict";
/**
 * Unified Ship - Complete integration of physics and subsystems
 *
 * Single entity that exists in BOTH the physics world AND has all subsystems
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.UnifiedShip = void 0;
const integrated_ship_1 = require("./integrated-ship");
const ship_configuration_1 = require("./ship-configuration");
/**
 * Unified Ship that seamlessly integrates physics and subsystems
 */
class UnifiedShip {
    constructor(config, world) {
        // Create subsystems ship
        this.completeShip = new ship_configuration_1.CompleteShip(config);
        // Create physics ship with matching parameters
        const physicsConfig = {
            mass: config.mass,
            radius: this.calculateRadius(config.mass), // Estimate from mass
            position: config.position,
            velocity: config.velocity,
            hullConfig: {
                compartments: config.compartments,
                armorLayers: config.armorLayers
            }
        };
        this.integratedShip = new integrated_ship_1.IntegratedShip(physicsConfig, world);
    }
    /**
     * Update - automatically syncs physics and subsystems
     */
    update(dt) {
        // PHASE 1: Update physics (gravity, collisions, orbital mechanics)
        this.integratedShip.update(dt);
        // PHASE 2: Sync position/velocity from physics to subsystems
        this.syncFromPhysics();
        // PHASE 3: Update all subsystems
        this.completeShip.update(dt);
        // No need to sync back - subsystems don't affect position
        // (except for future RCS/thrusters which would apply forces to IntegratedShip)
    }
    /**
     * Sync state from physics representation to subsystems
     */
    syncFromPhysics() {
        this.completeShip.position = this.integratedShip.getPosition();
        this.completeShip.velocity = this.integratedShip.getVelocity();
        this.completeShip.combatComputer.updateOwnShip(this.completeShip.position, this.completeShip.velocity);
    }
    /**
     * Calculate ship radius from mass (rough estimate)
     */
    calculateRadius(mass) {
        // Assume roughly spherical ship with density ~500 kg/m³ (mostly hollow)
        // V = m / ρ = (4/3)πr³  →  r = ∛(3m / 4πρ)
        const density = 500;
        const volume = mass / density;
        return Math.pow((3 * volume) / (4 * Math.PI), 1 / 3);
    }
    /**
     * Apply thrust (future feature - connects subsystems to physics)
     */
    applyThrust(direction, magnitude) {
        // Check if engines operational
        // Apply force to IntegratedShip
        // Consume fuel
        // Generate heat
        // Future implementation
    }
    /**
     * Get complete ship status
     */
    getStatus() {
        return this.completeShip.getStatus();
    }
    /**
     * Get ship ID
     */
    get id() {
        return this.completeShip.id;
    }
    /**
     * Get ship name
     */
    get name() {
        return this.completeShip.name;
    }
    /**
     * Get current position (from physics)
     */
    getPosition() {
        return this.integratedShip.getPosition();
    }
    /**
     * Get current velocity (from physics)
     */
    getVelocity() {
        return this.integratedShip.getVelocity();
    }
    /**
     * Access subsystems directly
     */
    get power() {
        return this.completeShip.power;
    }
    get thermal() {
        return this.completeShip.thermal;
    }
    get lifeSupport() {
        return this.completeShip.lifeSupport;
    }
    get systemDamage() {
        return this.completeShip.systemDamage;
    }
    get damageControl() {
        return this.completeShip.damageControl;
    }
    get combatComputer() {
        return this.completeShip.combatComputer;
    }
    get hull() {
        return this.completeShip.hull;
    }
    /**
     * Access physics ship (for adding to simulation)
     */
    get physicsBody() {
        return this.integratedShip;
    }
}
exports.UnifiedShip = UnifiedShip;
//# sourceMappingURL=unified-ship.js.map