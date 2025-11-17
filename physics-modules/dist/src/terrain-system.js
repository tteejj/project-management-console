"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.TerrainSystem = void 0;
const simplex_noise_1 = require("simplex-noise");
const DEFAULT_CONFIG = {
    bodyRadius: 1737400, // Moon radius in meters
    heightMapResolution: 10, // 10 samples per degree (manageable memory)
    maxElevation: 10000, // 10km max (highest lunar mountains ~10.8km)
    minElevation: -9000, // -9km min (deepest craters ~9km)
    seed: 42,
    enableProcedural: true,
    proceduralCraterCount: 1000
};
/**
 * Terrain System
 * Manages lunar surface elevation, craters, and terrain queries
 */
class TerrainSystem {
    constructor(config) {
        this.majorCraters = [];
        this.proceduralCraters = [];
        this.heightMapCache = new Map();
        this.config = { ...DEFAULT_CONFIG, ...config };
        this.MOON_RADIUS = this.config.bodyRadius;
        // Initialize noise generator with seed
        this.noise3D = (0, simplex_noise_1.createNoise3D)(() => this.seededRandom());
        // Initialize major craters
        this.initializeMajorCraters();
        // Generate procedural craters if enabled
        if (this.config.enableProcedural) {
            this.generateProceduralCraters();
        }
    }
    /**
     * Seeded random number generator for reproducible terrain
     */
    seededRandom() {
        const x = Math.sin(this.config.seed++) * 10000;
        return x - Math.floor(x);
    }
    /**
     * Initialize major lunar craters (real crater data)
     */
    initializeMajorCraters() {
        this.majorCraters = [
            {
                id: 'tycho',
                name: 'Tycho',
                centerLat: -43.3,
                centerLon: -11.2,
                radius: 43000, // 43 km
                depth: 4800, // 4.8 km
                rimHeight: 1500, // 1.5 km above surroundings
                age: 'fresh'
            },
            {
                id: 'copernicus',
                name: 'Copernicus',
                centerLat: 9.62,
                centerLon: -20.08,
                radius: 46500, // 46.5 km
                depth: 3760, // 3.76 km
                rimHeight: 1200,
                age: 'fresh'
            },
            {
                id: 'plato',
                name: 'Plato',
                centerLat: 51.6,
                centerLon: -9.3,
                radius: 50800, // 50.8 km
                depth: 2000, // 2 km
                rimHeight: 800,
                age: 'ancient'
            },
            {
                id: 'clavius',
                name: 'Clavius',
                centerLat: -58.8,
                centerLon: -14.1,
                radius: 112500, // 112.5 km (large)
                depth: 3500,
                rimHeight: 1000,
                age: 'degraded'
            },
            {
                id: 'aristarchus',
                name: 'Aristarchus',
                centerLat: 23.7,
                centerLon: -47.4,
                radius: 20000, // 20 km
                depth: 3000,
                rimHeight: 1500,
                age: 'fresh'
            },
            {
                id: 'kepler',
                name: 'Kepler',
                centerLat: 8.1,
                centerLon: -38.0,
                radius: 16000, // 16 km
                depth: 2600,
                rimHeight: 900,
                age: 'fresh'
            },
            {
                id: 'gassendi',
                name: 'Gassendi',
                centerLat: -17.5,
                centerLon: -39.9,
                radius: 55000, // 55 km
                depth: 1800,
                rimHeight: 700,
                age: 'degraded'
            },
            {
                id: 'eratosthenes',
                name: 'Eratosthenes',
                centerLat: 14.5,
                centerLon: -11.3,
                radius: 29000, // 29 km
                depth: 3600,
                rimHeight: 1100,
                age: 'fresh'
            },
            {
                id: 'archimedes',
                name: 'Archimedes',
                centerLat: 29.7,
                centerLon: -4.0,
                radius: 41500, // 41.5 km
                depth: 2100,
                rimHeight: 600,
                age: 'ancient'
            },
            {
                id: 'ptolemaeus',
                name: 'Ptolemaeus',
                centerLat: -9.3,
                centerLon: -1.9,
                radius: 77000, // 77 km
                depth: 2400,
                rimHeight: 800,
                age: 'degraded'
            },
            // Mare Imbrium (not really a crater, but a low plain)
            {
                id: 'mare_imbrium',
                name: 'Mare Imbrium',
                centerLat: 35.9,
                centerLon: -15.6,
                radius: 563000, // 563 km (huge impact basin)
                depth: -2000, // Actually a low plain
                rimHeight: 0,
                age: 'ancient'
            },
            // Mare Serenitatis
            {
                id: 'mare_serenitatis',
                name: 'Mare Serenitatis',
                centerLat: 28.0,
                centerLon: 17.5,
                radius: 350000, // 350 km
                depth: -1500,
                rimHeight: 0,
                age: 'ancient'
            }
        ];
    }
    /**
     * Generate procedural small craters
     */
    generateProceduralCraters() {
        this.proceduralCraters = [];
        for (let i = 0; i < this.config.proceduralCraterCount; i++) {
            const lat = (this.seededRandom() * 180) - 90;
            const lon = (this.seededRandom() * 360) - 180;
            // Exponential distribution: mostly small craters, few large
            const radius = -Math.log(this.seededRandom()) * 200; // Mean ~200m, range 10m-10km
            const depth = radius * 0.2; // Depth ≈ 20% of radius
            const rimHeight = depth * 0.15; // Rim ≈ 15% of depth
            const ages = ['fresh', 'degraded', 'ancient'];
            const age = ages[Math.floor(this.seededRandom() * 3)];
            this.proceduralCraters.push({
                id: `proc_crater_${i}`,
                name: `Crater ${i}`,
                centerLat: lat,
                centerLon: lon,
                radius: Math.min(radius, 10000), // Cap at 10km
                depth,
                rimHeight,
                age
            });
        }
    }
    /**
     * Get base elevation from Perlin noise (before craters)
     */
    getBaseElevation(lat, lon) {
        // Convert lat/lon to 3D position on unit sphere
        const latRad = (lat * Math.PI) / 180;
        const lonRad = (lon * Math.PI) / 180;
        const x = Math.cos(latRad) * Math.cos(lonRad);
        const y = Math.cos(latRad) * Math.sin(lonRad);
        const z = Math.sin(latRad);
        // Multi-octave Perlin noise for realistic terrain
        let elevation = 0;
        let frequency = 1.0;
        let amplitude = 100.0; // 100m base roughness
        for (let octave = 0; octave < 6; octave++) {
            elevation += this.noise3D(x * frequency, y * frequency, z * frequency) * amplitude;
            frequency *= 2.0;
            amplitude *= 0.5;
        }
        return elevation;
    }
    /**
     * Get elevation contribution from a single crater
     */
    getCraterElevation(lat, lon, crater) {
        const distKm = this.haversineDistance(lat, lon, crater.centerLat, crater.centerLon);
        const dist = distKm * 1000; // Convert to meters
        if (dist > crater.radius * 1.5) {
            return 0; // Outside crater influence
        }
        const normalizedDist = dist / crater.radius;
        if (normalizedDist < 0.8) {
            // Interior bowl: parabolic depression
            const interiorNorm = normalizedDist / 0.8;
            return -crater.depth * (1 - interiorNorm * interiorNorm);
        }
        else if (normalizedDist < 1.0) {
            // Rim: raised edge (sinusoidal profile)
            const rimNorm = (normalizedDist - 0.8) / 0.2;
            return crater.rimHeight * Math.sin(rimNorm * Math.PI);
        }
        else {
            // Ejecta blanket: gentle slope down
            const ejectaNorm = (normalizedDist - 1.0) / 0.5;
            return crater.rimHeight * 0.3 * Math.exp(-ejectaNorm * ejectaNorm * 3);
        }
    }
    /**
     * Calculate haversine distance between two lat/lon points (km)
     */
    haversineDistance(lat1, lon1, lat2, lon2) {
        const R = this.MOON_RADIUS / 1000; // Moon radius in km
        const dLat = ((lat2 - lat1) * Math.PI) / 180;
        const dLon = ((lon2 - lon1) * Math.PI) / 180;
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
    /**
     * Get elevation at a specific lat/lon
     * Main API method
     */
    getElevation(lat, lon) {
        // Check cache first
        const cacheKey = `${lat.toFixed(3)},${lon.toFixed(3)}`;
        if (this.heightMapCache.has(cacheKey)) {
            return this.heightMapCache.get(cacheKey);
        }
        // Start with base elevation (Perlin noise)
        let elevation = this.getBaseElevation(lat, lon);
        // Add all major craters
        for (const crater of this.majorCraters) {
            elevation += this.getCraterElevation(lat, lon, crater);
        }
        // Add nearby procedural craters (optimize: only check nearby)
        for (const crater of this.proceduralCraters) {
            // Quick distance check before expensive calculation
            const roughDist = Math.abs(lat - crater.centerLat) + Math.abs(lon - crater.centerLon);
            if (roughDist < 5) { // Within ~5 degrees
                elevation += this.getCraterElevation(lat, lon, crater);
            }
        }
        // Clamp to min/max
        elevation = Math.max(this.config.minElevation, Math.min(this.config.maxElevation, elevation));
        // Cache result
        this.heightMapCache.set(cacheKey, elevation);
        return elevation;
    }
    /**
     * Get slope at a location (degrees from horizontal)
     */
    getSlope(lat, lon) {
        const normal = this.getSurfaceNormal(lat, lon);
        // For local tangent plane, up is (0, 0, 1)
        // Slope is the angle between the normal and vertical
        // This is simply the angle from vertical, which equals angle from horizontal
        // When normal.z = 1 (flat), angleFromVertical = 0°, slope = 0°
        // When normal.z = 0 (vertical cliff), angleFromVertical = 90°, slope = 90°
        const angleFromVertical = Math.acos(Math.max(-1, Math.min(1, normal.z)));
        const slope = (angleFromVertical * 180) / Math.PI;
        return slope;
    }
    /**
     * Get surface normal at a location
     * Uses finite difference to compute gradient
     * Returns normal in local tangent plane coordinates (x=east, y=north, z=up)
     */
    getSurfaceNormal(lat, lon) {
        const delta = 0.001; // ~0.1 degree spacing (~170m at equator)
        // Get elevations at nearby points
        const elevCenter = this.getElevation(lat, lon);
        const elevEast = this.getElevation(lat, lon + delta);
        const elevWest = this.getElevation(lat, lon - delta);
        const elevNorth = this.getElevation(lat + delta, lon);
        const elevSouth = this.getElevation(lat - delta, lon);
        // Compute gradients (central difference for better accuracy)
        const dElevEast = (elevEast - elevWest) / (2 * delta);
        const dElevNorth = (elevNorth - elevSouth) / (2 * delta);
        // Convert gradient to meters per degree
        const latRad = (lat * Math.PI) / 180;
        const metersPerDegLat = (Math.PI / 180) * this.MOON_RADIUS;
        const metersPerDegLon = metersPerDegLat * Math.cos(latRad);
        // Slope in radians
        const slopeEast = Math.atan(dElevEast / metersPerDegLon);
        const slopeNorth = Math.atan(dElevNorth / metersPerDegLat);
        // Normal in local tangent plane (before normalization)
        const normal = {
            x: -Math.sin(slopeEast),
            y: -Math.sin(slopeNorth),
            z: 1.0
        };
        // Normalize to unit vector
        const mag = Math.sqrt(normal.x * normal.x + normal.y * normal.y + normal.z * normal.z);
        return {
            x: normal.x / mag,
            y: normal.y / mag,
            z: normal.z / mag
        };
    }
    /**
     * Get boulder density at a location (0-1)
     * Based on terrain roughness and crater age
     */
    getBoulderDensity(lat, lon) {
        // Fresh craters have more boulders
        let density = 0.1; // Base density
        for (const crater of this.majorCraters) {
            const distKm = this.haversineDistance(lat, lon, crater.centerLat, crater.centerLon);
            const dist = distKm * 1000;
            if (dist < crater.radius * 1.2) {
                // Inside crater or near rim
                if (crater.age === 'fresh') {
                    density += 0.4;
                }
                else if (crater.age === 'degraded') {
                    density += 0.2;
                }
            }
        }
        // Add randomness from noise
        const latRad = (lat * Math.PI) / 180;
        const lonRad = (lon * Math.PI) / 180;
        const x = Math.cos(latRad) * Math.cos(lonRad);
        const y = Math.cos(latRad) * Math.sin(lonRad);
        const z = Math.sin(latRad);
        const noiseDensity = (this.noise3D(x * 10, y * 10, z * 10) + 1) / 2; // 0-1
        density += noiseDensity * 0.3;
        return Math.min(1.0, density);
    }
    /**
     * Get complete terrain sample
     */
    getTerrainSample(lat, lon) {
        const elevation = this.getElevation(lat, lon);
        const slope = this.getSlope(lat, lon);
        const normal = this.getSurfaceNormal(lat, lon);
        const boulderDensity = this.getBoulderDensity(lat, lon);
        // Determine terrain type
        let terrainType = 'flat';
        if (slope > 20)
            terrainType = 'slope';
        else if (boulderDensity > 0.5)
            terrainType = 'rocky';
        else if (elevation < -500)
            terrainType = 'maria'; // Low plains
        else if (elevation > 2000)
            terrainType = 'highlands';
        else
            terrainType = 'flat';
        return {
            elevation,
            slope,
            normal,
            terrainType,
            boulderDensity
        };
    }
    /**
     * Convert lat/lon to 3D position
     */
    latLonToPosition(lat, lon, altitude = 0) {
        const latRad = (lat * Math.PI) / 180;
        const lonRad = (lon * Math.PI) / 180;
        const elevation = this.getElevation(lat, lon);
        const radius = this.MOON_RADIUS + elevation + altitude;
        return {
            x: radius * Math.cos(latRad) * Math.cos(lonRad),
            y: radius * Math.cos(latRad) * Math.sin(lonRad),
            z: radius * Math.sin(latRad)
        };
    }
    /**
     * Convert 3D position to lat/lon
     */
    positionToLatLon(position) {
        const r = Math.sqrt(position.x * position.x + position.y * position.y + position.z * position.z);
        const lat = (Math.asin(position.z / r) * 180) / Math.PI;
        const lon = (Math.atan2(position.y, position.x) * 180) / Math.PI;
        return { lat, lon };
    }
    /**
     * Check if position is below surface (collision)
     */
    checkCollision(position) {
        const coords = this.positionToLatLon(position);
        const surfaceElevation = this.getElevation(coords.lat, coords.lon);
        const surfaceRadius = this.MOON_RADIUS + surfaceElevation;
        const positionRadius = Math.sqrt(position.x * position.x +
            position.y * position.y +
            position.z * position.z);
        return positionRadius <= surfaceRadius;
    }
    /**
     * Get closest point on surface to given position
     */
    getClosestSurfacePoint(position) {
        const coords = this.positionToLatLon(position);
        const surfaceElevation = this.getElevation(coords.lat, coords.lon);
        const surfaceRadius = this.MOON_RADIUS + surfaceElevation;
        const positionRadius = Math.sqrt(position.x * position.x +
            position.y * position.y +
            position.z * position.z);
        // Normalize to surface
        const scale = surfaceRadius / positionRadius;
        const surfacePoint = {
            x: position.x * scale,
            y: position.y * scale,
            z: position.z * scale
        };
        const normal = this.getSurfaceNormal(coords.lat, coords.lon);
        const penetration = Math.max(0, surfaceRadius - positionRadius);
        return {
            position: surfacePoint,
            normal,
            penetration
        };
    }
    /**
     * Get all craters (for visualization/debugging)
     */
    getMajorCraters() {
        return [...this.majorCraters];
    }
    /**
     * Get terrain statistics
     */
    getStats() {
        return {
            majorCraters: this.majorCraters.length,
            proceduralCraters: this.proceduralCraters.length,
            cacheSize: this.heightMapCache.size,
            config: this.config
        };
    }
    /**
     * Find nearest crater to a given position
     */
    getNearestCrater(lat, lon) {
        let nearest = null;
        let minDistance = Infinity;
        // Check major craters
        for (const crater of this.majorCraters) {
            const dist = this.haversineDistance(lat, lon, crater.centerLat, crater.centerLon);
            if (dist < minDistance) {
                minDistance = dist;
                nearest = { crater, distance: dist };
            }
        }
        // Check procedural craters (only nearby ones)
        for (const crater of this.proceduralCraters) {
            // Quick distance check first
            const roughDist = Math.abs(lat - crater.centerLat) + Math.abs(lon - crater.centerLon);
            if (roughDist < 10) {
                const dist = this.haversineDistance(lat, lon, crater.centerLat, crater.centerLon);
                if (dist < minDistance) {
                    minDistance = dist;
                    nearest = { crater, distance: dist };
                }
            }
        }
        return nearest;
    }
    /**
     * Clear cache (useful if memory becomes an issue)
     */
    clearCache() {
        this.heightMapCache.clear();
    }
}
exports.TerrainSystem = TerrainSystem;
//# sourceMappingURL=terrain-system.js.map