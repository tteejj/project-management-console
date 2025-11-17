/**
 * Terrain System
 *
 * Provides realistic lunar terrain with:
 * - Perlin noise base elevation
 * - Major crater database (Tycho, Copernicus, etc.)
 * - Procedural small craters
 * - Height map storage with bilinear interpolation
 * - Surface normal and slope calculations
 * - Collision detection
 */
export interface Vector3 {
    x: number;
    y: number;
    z: number;
}
export interface LatLon {
    lat: number;
    lon: number;
}
export type TerrainType = 'flat' | 'rocky' | 'cratered' | 'slope' | 'maria' | 'highlands';
export interface TerrainSample {
    elevation: number;
    slope: number;
    normal: Vector3;
    terrainType: TerrainType;
    boulderDensity: number;
}
export interface Crater {
    id: string;
    name: string;
    centerLat: number;
    centerLon: number;
    radius: number;
    depth: number;
    rimHeight: number;
    age: 'fresh' | 'degraded' | 'ancient';
}
export interface TerrainConfig {
    bodyRadius: number;
    heightMapResolution: number;
    maxElevation: number;
    minElevation: number;
    seed: number;
    enableProcedural: boolean;
    proceduralCraterCount: number;
}
export interface ContactPoint {
    position: Vector3;
    normal: Vector3;
    penetration: number;
}
/**
 * Terrain System
 * Manages lunar surface elevation, craters, and terrain queries
 */
export declare class TerrainSystem {
    private config;
    private noise3D;
    private majorCraters;
    private proceduralCraters;
    private heightMapCache;
    private readonly MOON_RADIUS;
    constructor(config?: Partial<TerrainConfig>);
    /**
     * Seeded random number generator for reproducible terrain
     */
    private seededRandom;
    /**
     * Initialize major lunar craters (real crater data)
     */
    private initializeMajorCraters;
    /**
     * Generate procedural small craters
     */
    private generateProceduralCraters;
    /**
     * Get base elevation from Perlin noise (before craters)
     */
    private getBaseElevation;
    /**
     * Get elevation contribution from a single crater
     */
    private getCraterElevation;
    /**
     * Calculate haversine distance between two lat/lon points (km)
     */
    private haversineDistance;
    /**
     * Get elevation at a specific lat/lon
     * Main API method
     */
    getElevation(lat: number, lon: number): number;
    /**
     * Get slope at a location (degrees from horizontal)
     */
    getSlope(lat: number, lon: number): number;
    /**
     * Get surface normal at a location
     * Uses finite difference to compute gradient
     * Returns normal in local tangent plane coordinates (x=east, y=north, z=up)
     */
    getSurfaceNormal(lat: number, lon: number): Vector3;
    /**
     * Get boulder density at a location (0-1)
     * Based on terrain roughness and crater age
     */
    getBoulderDensity(lat: number, lon: number): number;
    /**
     * Get complete terrain sample
     */
    getTerrainSample(lat: number, lon: number): TerrainSample;
    /**
     * Convert lat/lon to 3D position
     */
    latLonToPosition(lat: number, lon: number, altitude?: number): Vector3;
    /**
     * Convert 3D position to lat/lon
     */
    positionToLatLon(position: Vector3): LatLon;
    /**
     * Check if position is below surface (collision)
     */
    checkCollision(position: Vector3): boolean;
    /**
     * Get closest point on surface to given position
     */
    getClosestSurfacePoint(position: Vector3): ContactPoint;
    /**
     * Get all craters (for visualization/debugging)
     */
    getMajorCraters(): Crater[];
    /**
     * Get terrain statistics
     */
    getStats(): {
        majorCraters: number;
        proceduralCraters: number;
        cacheSize: number;
        config: TerrainConfig;
    };
    /**
     * Find nearest crater to a given position
     */
    getNearestCrater(lat: number, lon: number): {
        crater: Crater;
        distance: number;
    } | null;
    /**
     * Clear cache (useful if memory becomes an issue)
     */
    clearCache(): void;
}
//# sourceMappingURL=terrain-system.d.ts.map