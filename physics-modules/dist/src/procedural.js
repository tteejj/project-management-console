"use strict";
/**
 * Procedural Generation System
 *
 * Generates asteroid fields, debris clouds, and random celestial bodies
 * Uses seeded RNG for deterministic generation
 * NO RENDERING - physics only
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProceduralGenerator = exports.SeededRandom = void 0;
/**
 * Seeded pseudorandom number generator
 * Uses Linear Congruential Generator (LCG)
 */
class SeededRandom {
    constructor(seed) {
        this.seed = seed % 2147483647;
        if (this.seed <= 0)
            this.seed += 2147483646;
    }
    /**
     * Get next random number [0, 1)
     */
    next() {
        this.seed = (this.seed * 16807) % 2147483647;
        return (this.seed - 1) / 2147483646;
    }
    /**
     * Get random integer in range [min, max]
     */
    nextInt(min, max) {
        return Math.floor(this.next() * (max - min + 1)) + min;
    }
    /**
     * Get random float in range [min, max)
     */
    nextFloat(min, max) {
        return this.next() * (max - min) + min;
    }
    /**
     * Get random boolean
     */
    nextBool() {
        return this.next() > 0.5;
    }
    /**
     * Get random point in sphere
     */
    nextPointInSphere(radius) {
        // Marsaglia's method for uniform distribution in sphere
        let x, y, z, normSq;
        do {
            x = this.nextFloat(-1, 1);
            y = this.nextFloat(-1, 1);
            z = this.nextFloat(-1, 1);
            normSq = x * x + y * y + z * z;
        } while (normSq > 1 || normSq === 0);
        return {
            x: x * radius,
            y: y * radius,
            z: z * radius
        };
    }
    /**
     * Get random vector with magnitude
     */
    nextVector(magnitude) {
        const point = this.nextPointInSphere(1);
        const norm = Math.sqrt(point.x * point.x + point.y * point.y + point.z * point.z);
        return {
            x: (point.x / norm) * magnitude,
            y: (point.y / norm) * magnitude,
            z: (point.z / norm) * magnitude
        };
    }
}
exports.SeededRandom = SeededRandom;
/**
 * Procedural content generator
 */
class ProceduralGenerator {
    constructor(seed) {
        this.idCounter = 0;
        this.rng = new SeededRandom(seed);
    }
    /**
     * Generate asteroid field
     */
    generateAsteroidField(config) {
        const asteroids = [];
        for (let i = 0; i < config.count; i++) {
            // Random position in sphere
            const offset = this.rng.nextPointInSphere(config.radius);
            const position = {
                x: config.center.x + offset.x,
                y: config.center.y + offset.y,
                z: config.center.z + offset.z
            };
            // Random size and mass
            const radius = this.rng.nextFloat(config.minSize, config.maxSize);
            const mass = this.rng.nextFloat(config.minMass, config.maxMass);
            // Random velocity if specified
            let velocity = { x: 0, y: 0, z: 0 };
            if (config.velocityVariation) {
                const speed = this.rng.nextFloat(0, config.velocityVariation);
                velocity = this.rng.nextVector(speed);
            }
            // Random properties
            const rcs = radius * radius * this.rng.nextFloat(0.5, 2.0); // Rough RCS estimate
            const thermalSig = this.rng.nextFloat(200, 300); // Cold objects
            const hardness = this.rng.nextFloat(300, 800);
            const asteroid = {
                id: `asteroid-${this.idCounter++}`,
                name: `Asteroid ${i + 1}`,
                type: 'asteroid',
                mass,
                radius,
                position,
                velocity,
                radarCrossSection: rcs,
                thermalSignature: thermalSig,
                collisionDamage: mass / 100,
                hardness
            };
            asteroids.push(asteroid);
        }
        return asteroids;
    }
    /**
     * Generate debris cloud
     */
    generateDebrisCloud(config) {
        const debris = [];
        for (let i = 0; i < config.count; i++) {
            // Random position in sphere
            const offset = this.rng.nextPointInSphere(config.radius);
            const position = {
                x: config.center.x + offset.x,
                y: config.center.y + offset.y,
                z: config.center.z + offset.z
            };
            // Random size and mass
            const radius = this.rng.nextFloat(config.minSize, config.maxSize);
            const mass = this.rng.nextFloat(config.minMass, config.maxMass);
            // Random velocity if specified
            let velocity = { x: 0, y: 0, z: 0 };
            if (config.velocityVariation) {
                const speed = this.rng.nextFloat(0, config.velocityVariation);
                velocity = this.rng.nextVector(speed);
            }
            // Debris has lower RCS and thermal signature
            const rcs = radius * radius * this.rng.nextFloat(0.1, 0.5);
            const thermalSig = this.rng.nextFloat(250, 280);
            const piece = {
                id: `debris-${this.idCounter++}`,
                name: `Debris ${i + 1}`,
                type: 'debris',
                mass,
                radius,
                position,
                velocity,
                radarCrossSection: rcs,
                thermalSignature: thermalSig,
                collisionDamage: mass / 50,
                hardness: this.rng.nextFloat(100, 300)
            };
            debris.push(piece);
        }
        return debris;
    }
    /**
     * Generate stations in orbit
     */
    generateStations(config) {
        const stations = [];
        for (let i = 0; i < config.count; i++) {
            // Random orbital distance
            const distance = this.rng.nextFloat(config.minDistanceFromCenter, config.maxDistanceFromCenter);
            // Random orbital position (spherical coordinates)
            const theta = this.rng.nextFloat(0, Math.PI * 2); // Azimuthal angle
            const phi = this.rng.nextFloat(0, Math.PI); // Polar angle
            const position = {
                x: config.center.x + distance * Math.sin(phi) * Math.cos(theta),
                y: config.center.y + distance * Math.sin(phi) * Math.sin(theta),
                z: config.center.z + distance * Math.cos(phi)
            };
            // Orbital velocity (perpendicular to position vector)
            // Simplified: circular orbit velocity
            const speed = config.orbitalVelocity;
            // Velocity perpendicular to radial direction
            const radial = {
                x: position.x - config.center.x,
                y: position.y - config.center.y,
                z: position.z - config.center.z
            };
            const radialMag = Math.sqrt(radial.x ** 2 + radial.y ** 2 + radial.z ** 2);
            const radialNorm = {
                x: radial.x / radialMag,
                y: radial.y / radialMag,
                z: radial.z / radialMag
            };
            // Perpendicular direction (simplified - use cross product with up vector)
            const up = { x: 0, y: 0, z: 1 };
            const perpendicular = {
                x: radialNorm.y * up.z - radialNorm.z * up.y,
                y: radialNorm.z * up.x - radialNorm.x * up.z,
                z: radialNorm.x * up.y - radialNorm.y * up.x
            };
            const perpMag = Math.sqrt(perpendicular.x ** 2 + perpendicular.y ** 2 + perpendicular.z ** 2);
            let velocity;
            if (perpMag > 0.01) {
                velocity = {
                    x: (perpendicular.x / perpMag) * speed,
                    y: (perpendicular.y / perpMag) * speed,
                    z: (perpendicular.z / perpMag) * speed
                };
            }
            else {
                // If perpendicular is zero, use a different tangent
                velocity = {
                    x: speed,
                    y: 0,
                    z: 0
                };
            }
            // Station properties
            const mass = this.rng.nextFloat(50000, 200000); // Large stations
            const radius = this.rng.nextFloat(20, 50);
            const station = {
                id: `station-${this.idCounter++}`,
                name: `Station ${i + 1}`,
                type: 'station',
                mass,
                radius,
                position,
                velocity,
                radarCrossSection: this.rng.nextFloat(500, 2000), // High RCS
                thermalSignature: this.rng.nextFloat(280, 320), // Warm (life support)
                collisionDamage: mass / 500,
                hardness: this.rng.nextFloat(400, 600)
            };
            stations.push(station);
        }
        return stations;
    }
    /**
     * Reset ID counter (for testing)
     */
    resetIdCounter() {
        this.idCounter = 0;
    }
}
exports.ProceduralGenerator = ProceduralGenerator;
//# sourceMappingURL=procedural.js.map