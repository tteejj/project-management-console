"use strict";
/**
 * World Environment System
 *
 * Manages celestial bodies, n-body gravity, spatial queries
 * NO RENDERING - physics only, accessed through sensors
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.CelestialBodyFactory = exports.World = void 0;
const math_utils_1 = require("./math-utils");
class World {
    constructor() {
        this.bodies = new Map();
        this.simulationTime = 0;
        this.G = math_utils_1.G;
        // Spatial partitioning (simple for MVP - can upgrade to octree later)
        this.spatialCellSize = 100000; // 100km cells
    }
    /**
     * Add a celestial body to the world
     */
    addBody(body) {
        this.bodies.set(body.id, body);
    }
    /**
     * Remove a celestial body
     */
    removeBody(id) {
        this.bodies.delete(id);
    }
    /**
     * Get a celestial body by ID
     */
    getBody(id) {
        return this.bodies.get(id);
    }
    /**
     * Get all celestial bodies
     */
    getAllBodies() {
        return Array.from(this.bodies.values());
    }
    /**
     * Update world physics (orbital mechanics, n-body gravity)
     */
    update(dt) {
        this.simulationTime += dt;
        // Update positions for orbiting bodies
        for (const body of this.bodies.values()) {
            if (body.orbitalElements && body.parentBodyId) {
                this.updateOrbitalPosition(body, dt);
            }
            else if (!body.isStatic) {
                // Update non-orbital bodies (simple ballistic motion)
                this.updateBallisticMotion(body, dt);
            }
        }
    }
    /**
     * Update orbital position using Keplerian elements (simplified)
     */
    updateOrbitalPosition(body, dt) {
        if (!body.orbitalElements || !body.parentBodyId)
            return;
        const parent = this.bodies.get(body.parentBodyId);
        if (!parent)
            return;
        const elements = body.orbitalElements;
        // Calculate mean motion: n = sqrt(G * M / a³)
        const n = Math.sqrt(this.G * parent.mass / Math.pow(elements.semiMajorAxis, 3));
        // Update mean anomaly: M = M₀ + n * t
        const meanAnomaly = elements.meanAnomalyAtEpoch + n * (this.simulationTime - elements.epoch);
        // Solve Kepler's equation for eccentric anomaly (simplified - assume low eccentricity)
        let E = meanAnomaly;
        for (let i = 0; i < 5; i++) {
            E = meanAnomaly + elements.eccentricity * Math.sin(E);
        }
        // True anomaly
        const trueAnomaly = 2 * Math.atan2(Math.sqrt(1 + elements.eccentricity) * Math.sin(E / 2), Math.sqrt(1 - elements.eccentricity) * Math.cos(E / 2));
        // Orbital radius
        const r = elements.semiMajorAxis * (1 - elements.eccentricity * Math.cos(E));
        // Position in orbital plane
        const x = r * Math.cos(trueAnomaly);
        const y = r * Math.sin(trueAnomaly);
        // Rotate to 3D (simplified - ignore inclination and node for now)
        const cosW = Math.cos(elements.argOfPeriapsis);
        const sinW = Math.sin(elements.argOfPeriapsis);
        const positionRelative = {
            x: cosW * x - sinW * y,
            y: sinW * x + cosW * y,
            z: 0 // Simplified - would use inclination here
        };
        // Add parent position
        body.position = math_utils_1.VectorMath.add(parent.position, positionRelative);
        // Calculate orbital velocity
        const v = Math.sqrt(this.G * parent.mass * (2 / r - 1 / elements.semiMajorAxis));
        const velocityDirection = {
            x: -Math.sin(trueAnomaly),
            y: Math.cos(trueAnomaly),
            z: 0
        };
        const velocityRelative = math_utils_1.VectorMath.scale(math_utils_1.VectorMath.normalize(velocityDirection), v);
        body.velocity = math_utils_1.VectorMath.add(parent.velocity, velocityRelative);
    }
    /**
     * Update ballistic motion (non-orbiting bodies)
     */
    updateBallisticMotion(body, dt) {
        // Calculate n-body gravity
        const gravity = this.calculateGravityAt(body.position, body.id);
        // Update velocity
        body.velocity = math_utils_1.VectorMath.add(body.velocity, math_utils_1.VectorMath.scale(gravity, dt));
        // Update position
        body.position = math_utils_1.VectorMath.add(body.position, math_utils_1.VectorMath.scale(body.velocity, dt));
    }
    /**
     * Calculate gravitational acceleration at a position from all bodies
     * N-body gravity: g = Σ(G * M / r²) * r̂
     */
    getGravityAt(position, excludeId) {
        return this.calculateGravityAt(position, excludeId);
    }
    calculateGravityAt(position, excludeId) {
        let totalGravity = math_utils_1.VectorMath.zero();
        for (const body of this.bodies.values()) {
            // Skip excluded body (usually the object we're calculating for)
            if (body.id === excludeId)
                continue;
            // Skip very small masses
            if (body.mass < 1)
                continue;
            const toBody = math_utils_1.VectorMath.subtract(body.position, position);
            const distSq = math_utils_1.VectorMath.magnitudeSquared(toBody);
            // Avoid singularity and too-close calculations
            if (distSq < body.radius * body.radius)
                continue;
            const dist = Math.sqrt(distSq);
            // g = G * M / r²
            const gMag = this.G * body.mass / distSq;
            // Direction: toward body
            const direction = math_utils_1.VectorMath.scale(toBody, 1 / dist);
            // Add to total
            const bodyGravity = math_utils_1.VectorMath.scale(direction, gMag);
            totalGravity = math_utils_1.VectorMath.add(totalGravity, bodyGravity);
        }
        return totalGravity;
    }
    /**
     * Get all bodies within a radius of a position
     */
    getBodiesInRange(position, radius) {
        const results = [];
        const radiusSq = radius * radius;
        for (const body of this.bodies.values()) {
            const distSq = math_utils_1.VectorMath.distanceSquared(position, body.position);
            if (distSq <= radiusSq) {
                results.push(body);
            }
        }
        return results;
    }
    /**
     * Get bodies in AABB region
     */
    getBodiesInRegion(bounds) {
        const results = [];
        for (const body of this.bodies.values()) {
            // Simple AABB vs point test
            if (body.position.x >= bounds.min.x && body.position.x <= bounds.max.x &&
                body.position.y >= bounds.min.y && body.position.y <= bounds.max.y &&
                body.position.z >= bounds.min.z && body.position.z <= bounds.max.z) {
                results.push(body);
            }
        }
        return results;
    }
    /**
     * Raycast - find first body intersected by ray
     */
    raycast(origin, direction, maxRange) {
        const dir = math_utils_1.VectorMath.normalize(direction);
        let closestHit = null;
        for (const body of this.bodies.values()) {
            // Ray-sphere intersection
            const toBody = math_utils_1.VectorMath.subtract(body.position, origin);
            const projection = math_utils_1.VectorMath.dot(toBody, dir);
            // Behind ray origin
            if (projection < 0)
                continue;
            // Beyond max range
            if (projection > maxRange)
                continue;
            // Closest point on ray to sphere center
            const closestPoint = math_utils_1.VectorMath.add(origin, math_utils_1.VectorMath.scale(dir, projection));
            const distToCenter = math_utils_1.VectorMath.distance(closestPoint, body.position);
            // Check if ray intersects sphere
            if (distToCenter <= body.radius) {
                // Calculate actual intersection distance
                const offset = Math.sqrt(body.radius * body.radius - distToCenter * distToCenter);
                const distance = projection - offset;
                if (!closestHit || distance < closestHit.distance) {
                    closestHit = { body, distance };
                }
            }
        }
        return closestHit;
    }
    /**
     * Get dominant gravitational body at position (sphere of influence)
     */
    getDominantBody(position) {
        let dominant = null;
        let maxInfluence = 0;
        for (const body of this.bodies.values()) {
            // Skip small bodies
            if (body.mass < 1000)
                continue;
            const distance = math_utils_1.VectorMath.distance(position, body.position);
            // Avoid division by zero
            if (distance < body.radius)
                continue;
            // Gravitational influence = M / r²
            const influence = body.mass / (distance * distance);
            if (influence > maxInfluence) {
                maxInfluence = influence;
                dominant = body;
            }
        }
        return dominant;
    }
    /**
     * Find closest body to position
     */
    findClosestBody(position, filter) {
        let closest = null;
        let minDistance = Infinity;
        for (const body of this.bodies.values()) {
            if (filter && !filter(body))
                continue;
            const distance = math_utils_1.VectorMath.distance(position, body.position);
            if (distance < minDistance) {
                minDistance = distance;
                closest = body;
            }
        }
        return closest;
    }
    /**
     * Get current simulation time
     */
    getTime() {
        return this.simulationTime;
    }
    /**
     * Clear all bodies
     */
    clear() {
        this.bodies.clear();
        this.simulationTime = 0;
    }
    /**
     * Get body count
     */
    getBodyCount() {
        return this.bodies.size;
    }
    /**
     * Get all bodies of a specific type
     */
    getBodiesByType(type) {
        return Array.from(this.bodies.values()).filter(b => b.type === type);
    }
    /**
     * Calculate escape velocity at position
     */
    getEscapeVelocity(position) {
        const dominant = this.getDominantBody(position);
        if (!dominant)
            return 0;
        const distance = math_utils_1.VectorMath.distance(position, dominant.position);
        // v_escape = sqrt(2 * G * M / r)
        return Math.sqrt(2 * this.G * dominant.mass / distance);
    }
    /**
     * Calculate orbital velocity at position
     */
    getOrbitalVelocity(position) {
        const dominant = this.getDominantBody(position);
        if (!dominant)
            return 0;
        const distance = math_utils_1.VectorMath.distance(position, dominant.position);
        // v_orbital = sqrt(G * M / r)
        return Math.sqrt(this.G * dominant.mass / distance);
    }
}
exports.World = World;
/**
 * Helper functions for creating common celestial bodies
 */
class CelestialBodyFactory {
    static createMoon() {
        return {
            id: 'moon',
            name: 'Moon',
            type: 'moon',
            mass: 7.342e22, // kg
            radius: 1737400, // 1737 km
            position: { x: 0, y: 0, z: 0 },
            velocity: { x: 0, y: 0, z: 0 },
            radarCrossSection: 1e12,
            thermalSignature: 250,
            collisionDamage: 1000,
            hardness: 1000,
            collisionEnabled: true,
            isStatic: true
        };
    }
    static createStation(id, name, position, velocity) {
        return {
            id,
            name,
            type: 'station',
            mass: 50000, // 50 tons
            radius: 20, // 20m
            position,
            velocity,
            radarCrossSection: 300,
            thermalSignature: 500,
            collisionDamage: 500,
            hardness: 300,
            collisionEnabled: true,
            isStatic: false
        };
    }
    static createAsteroid(id, position, velocity, radius) {
        // Assume rocky density ~2500 kg/m³
        const volume = (4 / 3) * Math.PI * Math.pow(radius, 3);
        const mass = volume * 2500;
        return {
            id,
            name: `Asteroid ${id}`,
            type: 'asteroid',
            mass,
            radius,
            position,
            velocity,
            radarCrossSection: Math.PI * radius * radius,
            thermalSignature: 50,
            collisionDamage: mass * 0.001,
            hardness: 500,
            collisionEnabled: true,
            isStatic: false
        };
    }
    static createDebris(id, position, velocity, size) {
        // Assume metal density ~3000 kg/m³
        const volume = (4 / 3) * Math.PI * Math.pow(size, 3);
        const mass = volume * 3000;
        return {
            id,
            name: `Debris ${id}`,
            type: 'debris',
            mass,
            radius: size,
            position,
            velocity,
            radarCrossSection: Math.PI * size * size * 0.1,
            thermalSignature: 10,
            collisionDamage: mass * 0.01,
            hardness: 200,
            collisionEnabled: true,
            isStatic: false
        };
    }
}
exports.CelestialBodyFactory = CelestialBodyFactory;
//# sourceMappingURL=world.js.map