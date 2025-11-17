/**
 * World Environment System
 *
 * Manages celestial bodies, n-body gravity, spatial queries
 * NO RENDERING - physics only, accessed through sensors
 */
import { Vector3 } from './math-utils';
export type CelestialBodyType = 'planet' | 'moon' | 'station' | 'asteroid' | 'comet' | 'satellite' | 'derelict' | 'debris';
export interface CelestialBody {
    id: string;
    name: string;
    type: CelestialBodyType;
    mass: number;
    radius: number;
    position: Vector3;
    velocity: Vector3;
    radarCrossSection: number;
    thermalSignature: number;
    collisionDamage: number;
    hardness: number;
    collisionEnabled?: boolean;
    orbitalElements?: {
        semiMajorAxis: number;
        eccentricity: number;
        inclination: number;
        argOfPeriapsis: number;
        longOfAscNode: number;
        meanAnomalyAtEpoch: number;
        epoch: number;
    };
    isStatic?: boolean;
    parentBodyId?: string;
}
export interface AABB {
    min: Vector3;
    max: Vector3;
}
export declare class World {
    bodies: Map<string, CelestialBody>;
    private simulationTime;
    private G;
    private spatialCellSize;
    constructor();
    /**
     * Add a celestial body to the world
     */
    addBody(body: CelestialBody): void;
    /**
     * Remove a celestial body
     */
    removeBody(id: string): void;
    /**
     * Get a celestial body by ID
     */
    getBody(id: string): CelestialBody | undefined;
    /**
     * Get all celestial bodies
     */
    getAllBodies(): CelestialBody[];
    /**
     * Update world physics (orbital mechanics, n-body gravity)
     */
    update(dt: number): void;
    /**
     * Update orbital position using Keplerian elements (simplified)
     */
    private updateOrbitalPosition;
    /**
     * Update ballistic motion (non-orbiting bodies)
     */
    private updateBallisticMotion;
    /**
     * Calculate gravitational acceleration at a position from all bodies
     * N-body gravity: g = Σ(G * M / r²) * r̂
     */
    getGravityAt(position: Vector3, excludeId?: string): Vector3;
    private calculateGravityAt;
    /**
     * Get all bodies within a radius of a position
     */
    getBodiesInRange(position: Vector3, radius: number): CelestialBody[];
    /**
     * Get bodies in AABB region
     */
    getBodiesInRegion(bounds: AABB): CelestialBody[];
    /**
     * Raycast - find first body intersected by ray
     */
    raycast(origin: Vector3, direction: Vector3, maxRange: number): {
        body: CelestialBody;
        distance: number;
    } | null;
    /**
     * Get dominant gravitational body at position (sphere of influence)
     */
    getDominantBody(position: Vector3): CelestialBody | null;
    /**
     * Find closest body to position
     */
    findClosestBody(position: Vector3, filter?: (body: CelestialBody) => boolean): CelestialBody | null;
    /**
     * Get current simulation time
     */
    getTime(): number;
    /**
     * Clear all bodies
     */
    clear(): void;
    /**
     * Get body count
     */
    getBodyCount(): number;
    /**
     * Get all bodies of a specific type
     */
    getBodiesByType(type: CelestialBodyType): CelestialBody[];
    /**
     * Calculate escape velocity at position
     */
    getEscapeVelocity(position: Vector3): number;
    /**
     * Calculate orbital velocity at position
     */
    getOrbitalVelocity(position: Vector3): number;
}
/**
 * Helper functions for creating common celestial bodies
 */
export declare class CelestialBodyFactory {
    static createMoon(): CelestialBody;
    static createStation(id: string, name: string, position: Vector3, velocity: Vector3): CelestialBody;
    static createAsteroid(id: string, position: Vector3, velocity: Vector3, radius: number): CelestialBody;
    static createDebris(id: string, position: Vector3, velocity: Vector3, size: number): CelestialBody;
}
//# sourceMappingURL=world.d.ts.map