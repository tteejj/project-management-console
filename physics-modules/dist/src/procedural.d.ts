/**
 * Procedural Generation System
 *
 * Generates asteroid fields, debris clouds, and random celestial bodies
 * Uses seeded RNG for deterministic generation
 * NO RENDERING - physics only
 */
import { Vector3 } from './math-utils';
import { CelestialBody } from './world';
export interface AsteroidFieldConfig {
    count: number;
    center: Vector3;
    radius: number;
    minSize: number;
    maxSize: number;
    minMass: number;
    maxMass: number;
    velocityVariation?: number;
}
export interface DebrisCloudConfig {
    count: number;
    center: Vector3;
    radius: number;
    minSize: number;
    maxSize: number;
    minMass: number;
    maxMass: number;
    velocityVariation?: number;
}
export interface StationPlacementConfig {
    count: number;
    minDistanceFromCenter: number;
    maxDistanceFromCenter: number;
    center: Vector3;
    orbitalVelocity: number;
}
/**
 * Seeded pseudorandom number generator
 * Uses Linear Congruential Generator (LCG)
 */
export declare class SeededRandom {
    private seed;
    constructor(seed: number);
    /**
     * Get next random number [0, 1)
     */
    next(): number;
    /**
     * Get random integer in range [min, max]
     */
    nextInt(min: number, max: number): number;
    /**
     * Get random float in range [min, max)
     */
    nextFloat(min: number, max: number): number;
    /**
     * Get random boolean
     */
    nextBool(): boolean;
    /**
     * Get random point in sphere
     */
    nextPointInSphere(radius: number): Vector3;
    /**
     * Get random vector with magnitude
     */
    nextVector(magnitude: number): Vector3;
}
/**
 * Procedural content generator
 */
export declare class ProceduralGenerator {
    private rng;
    private idCounter;
    constructor(seed: number);
    /**
     * Generate asteroid field
     */
    generateAsteroidField(config: AsteroidFieldConfig): CelestialBody[];
    /**
     * Generate debris cloud
     */
    generateDebrisCloud(config: DebrisCloudConfig): CelestialBody[];
    /**
     * Generate stations in orbit
     */
    generateStations(config: StationPlacementConfig): CelestialBody[];
    /**
     * Reset ID counter (for testing)
     */
    resetIdCounter(): void;
}
//# sourceMappingURL=procedural.d.ts.map