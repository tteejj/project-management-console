"use strict";
/**
 * Integrated Ship - Ship-World Bridge
 *
 * Connects spacecraft physics to world simulation
 * Makes ship a first-class celestial body that can be sensed, targeted, and collided with
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.SimulationController = exports.IntegratedShip = void 0;
const math_utils_1 = require("./math-utils");
const hull_damage_1 = require("./hull-damage");
const collision_1 = require("./collision");
const spacecraft_physics_1 = require("./spacecraft-physics");
/**
 * Integrated ship that exists in both spacecraft physics and world physics
 */
class IntegratedShip {
    constructor(config, world) {
        this.collisionHistory = [];
        this.eventListeners = new Map();
        if (config.mass <= 0) {
            throw new Error('Ship mass must be positive');
        }
        this.id = `ship-${IntegratedShip.shipCounter++}`;
        this.world = world;
        // Create spacecraft physics
        this.spacecraftPhysics = new spacecraft_physics_1.SpacecraftPhysics({
            mass: config.mass,
            momentOfInertia: this.calculateMomentOfInertia(config.mass, config.radius),
            position: config.position,
            velocity: config.velocity,
            orientation: config.orientation || { w: 1, x: 0, y: 0, z: 0 },
            angularVelocity: config.angularVelocity || { x: 0, y: 0, z: 0 }
        });
        // Create world body (ship as celestial body)
        this.worldBody = {
            id: this.id,
            name: `Ship ${this.id}`,
            type: 'satellite', // Ships are satellites in the celestial body system
            mass: config.mass,
            radius: config.radius,
            position: { ...config.position },
            velocity: { ...config.velocity },
            radarCrossSection: this.calculateRCS(config.radius),
            thermalSignature: 300, // Ships are warm (life support, electronics)
            collisionDamage: config.mass / 1000,
            hardness: 400
        };
        // Add to world
        this.world.addBody(this.worldBody);
        // Initialize hull damage system if config provided
        if (config.hullConfig) {
            const hull = new hull_damage_1.HullStructure(config.hullConfig);
            this.hullDamageSystem = new hull_damage_1.HullDamageSystem(hull);
        }
    }
    /**
     * Main update loop - integrates ship with world
     */
    update(dt) {
        // PHASE 1: Get gravity from world
        const gravity = this.world.getGravityAt(this.spacecraftPhysics.getPosition(), this.id // Exclude self from gravity calculation
        );
        // PHASE 2: Apply gravity to spacecraft
        const gravityForce = math_utils_1.VectorMath.scale(gravity, this.spacecraftPhysics.getMass());
        this.spacecraftPhysics.applyForce(gravityForce);
        // PHASE 3: Update spacecraft physics
        this.spacecraftPhysics.update(dt);
        // PHASE 4: Sync to world body
        this.syncToWorldBody();
        // PHASE 5: Check for collisions
        this.checkCollisions();
        // PHASE 6: Update damage systems
        if (this.hullDamageSystem) {
            this.hullDamageSystem.updatePressure(dt);
        }
    }
    /**
     * Sync spacecraft physics state to world body
     */
    syncToWorldBody() {
        const position = this.spacecraftPhysics.getPosition();
        const velocity = this.spacecraftPhysics.getVelocity();
        this.worldBody.position = { ...position };
        this.worldBody.velocity = { ...velocity };
    }
    /**
     * Check for collisions with world bodies
     */
    checkCollisions() {
        const bodies = this.world.getAllBodies();
        const shipPos = this.spacecraftPhysics.getPosition();
        const shipVel = this.spacecraftPhysics.getVelocity();
        for (const body of bodies) {
            // Skip self
            if (body.id === this.id)
                continue;
            // Detect collision
            const collision = collision_1.CollisionDetector.detectSphereSphere(shipPos, this.worldBody.radius, body.position, body.radius);
            if (collision && collision.collided) {
                this.handleCollision(body, collision);
            }
        }
    }
    /**
     * Handle collision with another body
     */
    handleCollision(otherBody, collision) {
        const shipVel = this.spacecraftPhysics.getVelocity();
        const relVel = math_utils_1.VectorMath.subtract(shipVel, otherBody.velocity);
        const relSpeed = math_utils_1.VectorMath.magnitude(relVel);
        // Calculate collision impulse (simplified elastic collision)
        const totalMass = this.spacecraftPhysics.getMass() + otherBody.mass;
        const impulse = math_utils_1.VectorMath.scale(collision.normal, -2 * relSpeed * (otherBody.mass / totalMass));
        // Apply impulse to ship
        this.applyImpulse(impulse);
        // Apply damage
        let damageApplied = 0;
        if (this.hullDamageSystem) {
            const impactResult = this.hullDamageSystem.processImpact({
                position: collision.point,
                velocity: relVel,
                mass: otherBody.mass * 0.1, // Effective mass
                damageType: hull_damage_1.DamageType.COLLISION,
                impactAngle: 0
            });
            damageApplied = impactResult.damageApplied;
        }
        // Record collision
        const event = {
            timestamp: Date.now(),
            otherBody,
            point: collision.point,
            normal: collision.normal,
            relativeVelocity: relSpeed,
            damageApplied
        };
        this.collisionHistory.push(event);
        // Emit event
        this.emit('collision', event);
    }
    /**
     * Apply force to ship
     */
    applyForce(force) {
        this.spacecraftPhysics.applyForce(force);
    }
    /**
     * Apply impulse to ship (instantaneous velocity change)
     */
    applyImpulse(impulse) {
        const velocityChange = math_utils_1.VectorMath.scale(impulse, 1 / this.spacecraftPhysics.getMass());
        const newVelocity = math_utils_1.VectorMath.add(this.spacecraftPhysics.getVelocity(), velocityChange);
        this.spacecraftPhysics.setVelocity(newVelocity);
    }
    /**
     * Get ship position
     */
    getPosition() {
        return this.spacecraftPhysics.getPosition();
    }
    /**
     * Get ship velocity
     */
    getVelocity() {
        return this.spacecraftPhysics.getVelocity();
    }
    /**
     * Get hull integrity (0-1)
     */
    getHullIntegrity() {
        if (!this.hullDamageSystem)
            return 1.0;
        const integrity = this.hullDamageSystem.getHull().getOverallIntegrity();
        return integrity.structural;
    }
    /**
     * Get collision history
     */
    getCollisionHistory() {
        return [...this.collisionHistory];
    }
    /**
     * Get world body
     */
    getWorldBody() {
        return this.worldBody;
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
    /**
     * Calculate moment of inertia (sphere approximation)
     */
    calculateMomentOfInertia(mass, radius) {
        const I = (2 / 5) * mass * radius * radius;
        return { x: I, y: I, z: I };
    }
    /**
     * Calculate radar cross section
     */
    calculateRCS(radius) {
        // RCS for sphere: π * r²
        return Math.PI * radius * radius;
    }
    /**
     * Cleanup
     */
    destroy() {
        this.world.removeBody(this.id);
    }
}
exports.IntegratedShip = IntegratedShip;
IntegratedShip.shipCounter = 0;
/**
 * Simulation controller - manages world and all ships
 */
class SimulationController {
    constructor(world) {
        this.ships = new Map();
        this.simulationTime = 0;
        this.world = world;
    }
    /**
     * Add ship to simulation
     */
    addShip(config) {
        const ship = new IntegratedShip(config, this.world);
        this.ships.set(ship.id, ship);
        return ship;
    }
    /**
     * Remove ship from simulation
     */
    removeShip(shipId) {
        const ship = this.ships.get(shipId);
        if (ship) {
            ship.destroy();
            this.ships.delete(shipId);
        }
    }
    /**
     * Main update loop
     */
    update(dt) {
        // PHASE 1: Update world (orbits, n-body)
        this.world.update(dt);
        // PHASE 2: Update all ships
        for (const ship of this.ships.values()) {
            ship.update(dt);
        }
        // PHASE 3: Check ship-ship collisions
        this.checkShipCollisions();
        // PHASE 4: Update simulation time
        this.simulationTime += dt;
    }
    /**
     * Check collisions between ships
     */
    checkShipCollisions() {
        const shipArray = Array.from(this.ships.values());
        for (let i = 0; i < shipArray.length; i++) {
            for (let j = i + 1; j < shipArray.length; j++) {
                const ship1 = shipArray[i];
                const ship2 = shipArray[j];
                const collision = collision_1.CollisionDetector.detectSphereSphere(ship1.getPosition(), ship1.getWorldBody().radius, ship2.getPosition(), ship2.getWorldBody().radius);
                if (collision && collision.collided) {
                    // Apply symmetric collision response
                    const relVel = math_utils_1.VectorMath.subtract(ship1.getVelocity(), ship2.getVelocity());
                    const relSpeed = math_utils_1.VectorMath.magnitude(relVel);
                    const totalMass = ship1.getWorldBody().mass + ship2.getWorldBody().mass;
                    const impulse1 = math_utils_1.VectorMath.scale(collision.normal, -relSpeed * (ship2.getWorldBody().mass / totalMass));
                    const impulse2 = math_utils_1.VectorMath.scale(collision.normal, relSpeed * (ship1.getWorldBody().mass / totalMass));
                    ship1.applyImpulse(impulse1);
                    ship2.applyImpulse(impulse2);
                }
            }
        }
    }
    /**
     * Get simulation time
     */
    getSimulationTime() {
        return this.simulationTime;
    }
    /**
     * Get all ships
     */
    getShips() {
        return Array.from(this.ships.values());
    }
    /**
     * Get ship by ID
     */
    getShip(id) {
        return this.ships.get(id);
    }
}
exports.SimulationController = SimulationController;
//# sourceMappingURL=integrated-ship.js.map