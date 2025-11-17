# Real World Implementation Plan

**Goal**: Make ONE thing GREAT - a complete, realistic physical world for flight operations

**Focus Areas**:
1. Real terrain with elevation, craters, boulders
2. Real weather/environmental effects
3. Real landing gear physics
4. Real waypoint navigation
5. Real orbital bodies (satellite for rendezvous/docking)

---

## Table of Contents

1. [Terrain System Design](#1-terrain-system-design)
2. [Weather & Environment Design](#2-weather--environment-design)
3. [Landing Gear Design](#3-landing-gear-design)
4. [Waypoint Navigation Design](#4-waypoint-navigation-design)
5. [Orbital Bodies & Docking Design](#5-orbital-bodies--docking-design)
6. [Implementation Phases](#6-implementation-phases)
7. [Testing Strategy](#7-testing-strategy)
8. [Performance Considerations](#8-performance-considerations)

---

## 1. Terrain System Design

### 1.1 Requirements

**Must Have**:
- Real elevation data (not flat sphere)
- Crater generation with realistic profiles
- Boulder fields as landing hazards
- Collision detection with terrain features
- Radar altitude = orbital altitude - terrain elevation
- Performance: <10ms terrain lookup

**Nice to Have**:
- Different terrain types (maria, highlands, crater rims)
- Erosion patterns
- Regolith texture variations

### 1.2 Data Structure

```typescript
/**
 * NEW FILE: terrain-system.ts
 */

export interface TerrainConfig {
  bodyRadius: number;        // 1737400m for Moon
  heightMapResolution: number; // Samples per degree
  maxElevation: number;      // Highest point (m)
  minElevation: number;      // Lowest point (m)
  seed: number;              // For procedural generation
}

export interface TerrainSample {
  elevation: number;         // Meters above/below reference
  slope: number;             // Degrees from horizontal
  normal: Vector3;           // Surface normal vector
  terrainType: TerrainType;  // maria, highlands, crater, etc.
  boulderDensity: number;    // 0-1
  regolithDepth: number;     // Meters
}

export interface Crater {
  id: string;
  centerLat: number;         // Degrees
  centerLon: number;         // Degrees
  radius: number;            // Meters
  depth: number;             // Meters
  rimHeight: number;         // Meters above surroundings
  age: 'fresh' | 'degraded' | 'ancient';
}

export class TerrainSystem {
  private heightMap: Float32Array;  // Elevation data
  private craters: Crater[];
  private noiseGenerator: PerlinNoise3D;

  // Core API
  getElevation(lat: number, lon: number): number;
  getSlope(lat: number, lon: number): number;
  getSurfaceNormal(lat: number, lon: number): Vector3;
  getBoulderDensity(lat: number, lon: number): number;
  getTerrainSample(lat: number, lon: number): TerrainSample;

  // Collision
  checkCollision(position: Vector3): boolean;
  getClosestSurfacePoint(position: Vector3): Vector3;
  raycastToSurface(origin: Vector3, direction: Vector3): RaycastHit | null;

  // Generation
  generateTerrain(config: TerrainConfig): void;
  addCrater(crater: Crater): void;
  addBoulderField(center: LatLon, radius: number, density: number): void;
}
```

### 1.3 Elevation Model

**Base Terrain**: Perlin noise for rough surface

```typescript
// 3D Perlin noise based on position on sphere
function getBaseElevation(lat: number, lon: number): number {
  // Convert lat/lon to 3D position on unit sphere
  const x = Math.cos(lat * Math.PI / 180) * Math.cos(lon * Math.PI / 180);
  const y = Math.cos(lat * Math.PI / 180) * Math.sin(lon * Math.PI / 180);
  const z = Math.sin(lat * Math.PI / 180);

  // Multi-octave Perlin noise
  let elevation = 0;
  let frequency = 1.0;
  let amplitude = 100.0;  // 100m base roughness

  for (let octave = 0; octave < 6; octave++) {
    elevation += perlin3D(x * frequency, y * frequency, z * frequency) * amplitude;
    frequency *= 2.0;
    amplitude *= 0.5;
  }

  return elevation;
}
```

**Crater Addition**: Mathematical crater profile

```typescript
function getCraterElevation(
  lat: number,
  lon: number,
  crater: Crater
): number {
  const distKm = haversineDistance(lat, lon, crater.centerLat, crater.centerLon);
  const dist = distKm * 1000; // meters

  if (dist > crater.radius * 1.5) return 0; // Outside crater influence

  const normalizedDist = dist / crater.radius;

  if (normalizedDist < 0.8) {
    // Interior bowl: parabolic depression
    const interiorNorm = normalizedDist / 0.8;
    return -crater.depth * (1 - interiorNorm * interiorNorm);
  } else if (normalizedDist < 1.0) {
    // Rim: raised edge
    const rimNorm = (normalizedDist - 0.8) / 0.2;
    return crater.rimHeight * Math.sin(rimNorm * Math.PI);
  } else {
    // Ejecta blanket: gentle slope down
    const ejectaNorm = (normalizedDist - 1.0) / 0.5;
    return crater.rimHeight * 0.3 * Math.exp(-ejectaNorm * ejectaNorm * 3);
  }
}
```

**Combined Elevation**:

```typescript
getElevation(lat: number, lon: number): number {
  let elevation = this.getBaseElevation(lat, lon);

  // Add all craters
  for (const crater of this.craters) {
    elevation += this.getCraterElevation(lat, lon, crater);
  }

  // Add regional variations (maria vs highlands)
  elevation += this.getRegionalBias(lat, lon);

  return elevation;
}
```

### 1.4 Collision Detection

**Ground Contact**:

```typescript
interface ContactPoint {
  position: Vector3;       // World position of contact
  normal: Vector3;         // Surface normal
  penetration: number;     // How far below surface (m)
  velocity: Vector3;       // Relative velocity at contact
}

function checkGroundContact(
  spacecraft: Spacecraft,
  terrain: TerrainSystem
): ContactPoint[] {
  const contacts: ContactPoint[] = [];

  // Check each landing gear leg
  for (const leg of spacecraft.landingGear.legs) {
    const footPosition = leg.getFootWorldPosition();
    const coords = positionToLatLon(footPosition);
    const surfaceElevation = terrain.getElevation(coords.lat, coords.lon);
    const surfaceRadius = MOON_RADIUS + surfaceElevation;
    const footRadius = magnitude(footPosition);

    if (footRadius <= surfaceRadius) {
      // Contact detected
      const normal = terrain.getSurfaceNormal(coords.lat, coords.lon);
      const penetration = surfaceRadius - footRadius;

      contacts.push({
        position: footPosition,
        normal,
        penetration,
        velocity: leg.getVelocity()
      });
    }
  }

  return contacts;
}
```

### 1.5 Height Map Storage

**Memory-Efficient Storage**:

```typescript
class HeightMap {
  private resolution: number;    // Samples per degree
  private data: Float32Array;    // Elevation values

  constructor(resolution: number) {
    this.resolution = resolution;
    // 360° lon × 180° lat × resolution²
    const samples = 360 * resolution * 180 * resolution;
    this.data = new Float32Array(samples);
  }

  // Convert lat/lon to array index
  private getIndex(lat: number, lon: number): number {
    // Normalize to 0-1
    const latNorm = (lat + 90) / 180;
    const lonNorm = (lon + 180) / 360;

    const latIdx = Math.floor(latNorm * 180 * this.resolution);
    const lonIdx = Math.floor(lonNorm * 360 * this.resolution);

    return latIdx * (360 * this.resolution) + lonIdx;
  }

  set(lat: number, lon: number, elevation: number): void {
    this.data[this.getIndex(lat, lon)] = elevation;
  }

  get(lat: number, lon: number): number {
    return this.data[this.getIndex(lat, lon)];
  }

  // Bilinear interpolation for smooth values
  getInterpolated(lat: number, lon: number): number {
    // Get 4 nearest samples and interpolate
    // ... (standard bilinear interpolation)
  }
}
```

**Memory Usage**:
- Resolution 10 samples/degree: 360 × 10 × 180 × 10 × 4 bytes = 25.9 MB
- Resolution 100 samples/degree: 2.59 GB (too large, use chunking)

**Recommended**: 10-20 samples per degree with procedural detail

### 1.6 Crater Database

**Pre-defined Major Craters**:

```typescript
const MAJOR_CRATERS: Crater[] = [
  {
    id: 'tycho',
    centerLat: -43.3,
    centerLon: -11.2,
    radius: 43000,      // 43 km
    depth: 4800,        // 4.8 km
    rimHeight: 1500,    // 1.5 km above surroundings
    age: 'fresh'
  },
  {
    id: 'copernicus',
    centerLat: 9.62,
    centerLon: -20.08,
    radius: 46500,      // 46.5 km
    depth: 3760,        // 3.76 km
    rimHeight: 1200,
    age: 'fresh'
  },
  {
    id: 'mare_imbrium',
    centerLat: 35.9,
    centerLon: -15.6,
    radius: 563000,     // 563 km (huge)
    depth: -3000,       // Actually a low plain
    rimHeight: 0,
    age: 'ancient'
  },
  // Add 20-30 more major craters
];
```

**Procedural Small Craters**:

```typescript
function generateRandomCraters(count: number, seed: number): Crater[] {
  const rng = new SeededRandom(seed);
  const craters: Crater[] = [];

  for (let i = 0; i < count; i++) {
    const lat = rng.range(-90, 90);
    const lon = rng.range(-180, 180);

    // Size distribution: mostly small, few large
    const radius = rng.exponential(500); // Mean 500m
    const depth = radius * 0.2;          // Depth ≈ 20% of radius
    const rimHeight = depth * 0.15;      // Rim ≈ 15% of depth

    craters.push({
      id: `crater_${i}`,
      centerLat: lat,
      centerLon: lon,
      radius,
      depth,
      rimHeight,
      age: rng.choice(['fresh', 'degraded', 'ancient'])
    });
  }

  return craters;
}
```

---

## 2. Weather & Environment Design

### 2.1 Environmental Factors

**Lunar Environment** (no atmosphere):
- ✅ Solar radiation (affects power, thermal)
- ✅ Day/night thermal cycling
- ✅ Micrometeorites
- ✅ Solar wind particles
- ✅ Surface dust behavior (from plume)
- ❌ Wind (no atmosphere)
- ❌ Rain (no atmosphere)
- ❌ Clouds (no atmosphere)

### 2.2 Data Structure

```typescript
/**
 * NEW FILE: environment-system.ts
 */

export interface EnvironmentConfig {
  solarConstant: number;     // 1361 W/m² at lunar orbit
  rotationPeriod: number;    // 27.3 Earth days
  axialTilt: number;         // 1.54°
  micrometeorites: boolean;
  solarWind: boolean;
}

export interface SolarPosition {
  azimuth: number;           // Degrees, 0 = North
  elevation: number;         // Degrees above horizon
  intensity: number;         // W/m² (0 at night, ~1300 in sunlight)
}

export interface EnvironmentState {
  time: number;              // Mission elapsed time (s)
  solarPosition: SolarPosition;
  isDay: boolean;
  surfaceTemp: number;       // K (100-400K range on Moon)
  ambientRadiation: number;  // W/m²
  dustDensity: number;       // 0-1 (from plume effects)
}

export class EnvironmentSystem {
  private config: EnvironmentConfig;
  private missionStartTime: number;

  // Core API
  update(dt: number, spacecraftPosition: Vector3): void;
  getSolarPosition(position: Vector3, time: number): SolarPosition;
  getSurfaceTemperature(lat: number, lon: number): number;
  getAmbientRadiation(position: Vector3): number;

  // Effects
  checkMicrometeorites(dt: number): MicrometeoiteHit[];
  calculatePlumeEffect(position: Vector3, thrust: number): PlumeEffect;
  calculateSolarPressure(area: number): Vector3;
}
```

### 2.3 Solar Position Calculation

```typescript
getSolarPosition(position: Vector3, time: number): SolarPosition {
  // Simplified: assume Sun at fixed direction
  // Real implementation would calculate orbital mechanics

  const coords = positionToLatLon(position);

  // Lunar day = 27.3 Earth days = 2,358,720 seconds
  const LUNAR_DAY = 27.3 * 24 * 3600;
  const dayPhase = (time % LUNAR_DAY) / LUNAR_DAY; // 0-1

  // Solar longitude = function of time
  const solarLon = (dayPhase * 360) - 180; // -180 to +180

  // Elevation depends on latitude and solar longitude
  const solarElevation = this.calculateSolarElevation(
    coords.lat,
    coords.lon,
    solarLon
  );

  const intensity = Math.max(0, Math.sin(solarElevation * Math.PI / 180) * 1361);

  return {
    azimuth: this.calculateSolarAzimuth(coords.lat, coords.lon, solarLon),
    elevation: solarElevation,
    intensity
  };
}
```

### 2.4 Thermal Environment

```typescript
getSurfaceTemperature(lat: number, lon: number, time: number): number {
  const solar = this.getSolarPosition(positionFromLatLon(lat, lon, MOON_RADIUS), time);

  if (solar.elevation < 0) {
    // Night side: very cold
    return 100; // K (~-173°C)
  } else {
    // Day side: hot, depends on solar elevation
    const maxTemp = 400; // K (~127°C) at subsolar point
    const minTemp = 100; // K

    // Temperature ∝ cos(solar angle)^0.25 (Stefan-Boltzmann approximation)
    const tempFactor = Math.pow(Math.sin(solar.elevation * Math.PI / 180), 0.25);
    return minTemp + (maxTemp - minTemp) * tempFactor;
  }
}
```

### 2.5 Micrometeorite Impacts

```typescript
interface MicrometeoiteHit {
  position: Vector3;         // Impact location on spacecraft
  velocity: Vector3;         // Impact velocity (m/s)
  mass: number;              // kg (typically 1e-9 to 1e-6)
  energy: number;            // Joules
  damage: number;            // 0-1 damage factor
}

checkMicrometeorites(dt: number, exposedArea: number): MicrometeoiteHit[] {
  const hits: MicrometeoiteHit[] = [];

  // Flux: ~1e-12 kg/m²/s in lunar orbit
  const FLUX = 1e-12; // kg/m²/s
  const impactMass = FLUX * exposedArea * dt;

  if (Math.random() < impactMass * 1e9) {
    // Hit occurred (probabilistic)
    const velocity = {
      x: (Math.random() - 0.5) * 20000,
      y: (Math.random() - 0.5) * 20000,
      z: (Math.random() - 0.5) * 20000
    }; // 10-20 km/s typical

    const mass = Math.random() * 1e-6; // Up to 1 microgram
    const speed = magnitude(velocity);
    const energy = 0.5 * mass * speed * speed;

    hits.push({
      position: this.getRandomExposedPoint(),
      velocity,
      mass,
      energy,
      damage: Math.min(1.0, energy / 1e-3) // 1 mJ causes full damage
    });
  }

  return hits;
}
```

### 2.6 Plume-Surface Interaction

```typescript
interface PlumeEffect {
  dustDensity: number;       // 0-1 visibility reduction
  kickupForce: Vector3;      // Force from ejecta hitting spacecraft
  thermalLoad: number;       // W thermal load from hot gas reflection
}

calculatePlumeEffect(
  position: Vector3,
  thrust: number,
  altitude: number
): PlumeEffect {
  // Only significant below 100m
  if (altitude > 100 || thrust === 0) {
    return { dustDensity: 0, kickupForce: {x:0, y:0, z:0}, thermalLoad: 0 };
  }

  // Intensity increases as altitude decreases
  const intensity = (100 - altitude) / 100; // 0-1

  // Dust kickup (regolith particles ejected by plume)
  const dustDensity = intensity * (thrust / 45000) * 0.9; // Max 90% obscuration

  // Thermal load from gas reflection (hot exhaust bounces back)
  const thermalLoad = intensity * thrust * 0.01; // 1% of thrust power

  // Kickup force (particles hitting spacecraft)
  // Simplified: upward force proportional to thrust and proximity
  const kickupMagnitude = intensity * thrust * 0.001; // 0.1% of thrust
  const normal = normalize(position);
  const kickupForce = scalarMultiply(normal, kickupMagnitude);

  return { dustDensity, kickupForce, thermalLoad };
}
```

---

## 3. Landing Gear Design

### 3.1 Requirements

**Must Have**:
- 3-4 landing legs with shock absorption
- Deployment/retraction mechanism
- Ground contact detection
- Suspension physics (spring-damper)
- Tip-over detection
- Damage model for hard landings

**Nice to Have**:
- Hydraulic system integration
- Gear health monitoring
- Auto-deployment at altitude trigger

### 3.2 Data Structure

```typescript
/**
 * NEW FILE: landing-gear.ts
 */

export interface LandingLeg {
  id: string;
  mountPosition: Vector3;      // Attachment point on spacecraft (body frame)
  restLength: number;           // Uncompressed strut length (m)
  currentLength: number;        // Current strut length (m)
  maxCompression: number;       // Max travel (m)
  deployed: boolean;
  damaged: boolean;

  // Physics
  springConstant: number;       // N/m
  dampingConstant: number;      // N⋅s/m

  // Contact
  inContact: boolean;
  contactPoint: Vector3 | null;
  contactNormal: Vector3 | null;
  contactForce: Vector3;
}

export interface LandingGearConfig {
  legCount: number;             // 3 or 4
  legSpacing: number;           // Distance from center (m)
  strutLength: number;          // Extended length (m)
  springConstant: number;       // Stiffness (N/m)
  dampingConstant: number;      // Damping (N⋅s/m)
  maxCompression: number;       // Max travel (m)
  deploymentTime: number;       // Seconds to deploy
}

export class LandingGearSystem {
  private legs: LandingLeg[];
  private deployed: boolean = false;
  private deploying: boolean = false;
  private deploymentProgress: number = 0;

  // Control
  deploy(): void;
  retract(): void;

  // Physics
  update(
    dt: number,
    spacecraftPosition: Vector3,
    spacecraftAttitude: Quaternion,
    spacecraftVelocity: Vector3,
    terrain: TerrainSystem
  ): void;

  // Collision
  checkGroundContact(terrain: TerrainSystem): ContactPoint[];
  calculateContactForces(contacts: ContactPoint[]): Vector3;
  calculateContactTorques(contacts: ContactPoint[]): Vector3;

  // State
  isFullyDeployed(): boolean;
  isStable(): boolean;          // Check if tipped over
  getTotalForce(): Vector3;
  getTotalTorque(): Vector3;
  getState(): LandingGearState;
}
```

### 3.3 Leg Geometry

```typescript
function createLandingLegs(config: LandingGearConfig): LandingLeg[] {
  const legs: LandingLeg[] = [];

  if (config.legCount === 3) {
    // Triangular arrangement
    for (let i = 0; i < 3; i++) {
      const angle = (i * 120) * Math.PI / 180;
      const x = config.legSpacing * Math.cos(angle);
      const y = config.legSpacing * Math.sin(angle);

      legs.push({
        id: `leg_${i}`,
        mountPosition: { x, y, z: -2.0 }, // 2m below spacecraft center
        restLength: config.strutLength,
        currentLength: 0, // Retracted
        maxCompression: config.maxCompression,
        deployed: false,
        damaged: false,
        springConstant: config.springConstant,
        dampingConstant: config.dampingConstant,
        inContact: false,
        contactPoint: null,
        contactNormal: null,
        contactForce: { x: 0, y: 0, z: 0 }
      });
    }
  } else {
    // 4-leg square arrangement
    const positions = [
      { x: config.legSpacing, y: config.legSpacing },
      { x: -config.legSpacing, y: config.legSpacing },
      { x: -config.legSpacing, y: -config.legSpacing },
      { x: config.legSpacing, y: -config.legSpacing }
    ];

    for (let i = 0; i < 4; i++) {
      legs.push({
        id: `leg_${i}`,
        mountPosition: { ...positions[i], z: -2.0 },
        restLength: config.strutLength,
        currentLength: 0,
        maxCompression: config.maxCompression,
        deployed: false,
        damaged: false,
        springConstant: config.springConstant,
        dampingConstant: config.dampingConstant,
        inContact: false,
        contactPoint: null,
        contactNormal: null,
        contactForce: { x: 0, y: 0, z: 0 }
      });
    }
  }

  return legs;
}
```

### 3.4 Spring-Damper Physics

```typescript
calculateLegForce(
  leg: LandingLeg,
  penetration: number,      // How far into surface (m)
  velocity: number          // Compression velocity (m/s)
): number {
  // Spring force: F = -k⋅x (Hooke's law)
  const springForce = leg.springConstant * penetration;

  // Damping force: F = -c⋅v
  const dampingForce = leg.dampingConstant * velocity;

  // Total force (upward, against penetration)
  const totalForce = springForce + dampingForce;

  return Math.max(0, totalForce); // Only push, don't pull
}
```

### 3.5 Contact Detection

```typescript
checkGroundContact(
  spacecraftPosition: Vector3,
  spacecraftAttitude: Quaternion,
  terrain: TerrainSystem
): ContactPoint[] {
  const contacts: ContactPoint[] = [];

  for (const leg of this.legs) {
    if (!leg.deployed) continue;

    // Transform leg foot position from body frame to world frame
    const footBody = {
      x: leg.mountPosition.x,
      y: leg.mountPosition.y,
      z: leg.mountPosition.z - leg.currentLength
    };

    const footWorld = bodyToWorld(footBody, spacecraftPosition, spacecraftAttitude);

    // Get terrain elevation at foot position
    const coords = positionToLatLon(footWorld);
    const surfaceElevation = terrain.getElevation(coords.lat, coords.lon);
    const surfaceRadius = MOON_RADIUS + surfaceElevation;
    const footRadius = magnitude(footWorld);

    if (footRadius <= surfaceRadius) {
      // Contact!
      const penetration = surfaceRadius - footRadius;
      const normal = terrain.getSurfaceNormal(coords.lat, coords.lon);

      leg.inContact = true;
      leg.contactPoint = footWorld;
      leg.contactNormal = normal;

      contacts.push({
        legId: leg.id,
        position: footWorld,
        normal,
        penetration,
        velocity: this.getLegVelocity(leg, spacecraftVelocity, spacecraftAttitude)
      });
    } else {
      leg.inContact = false;
      leg.contactPoint = null;
      leg.contactNormal = null;
    }
  }

  return contacts;
}
```

### 3.6 Stability Check

```typescript
isStable(): boolean {
  // Check if center of mass is within support polygon
  const contactLegs = this.legs.filter(leg => leg.inContact);

  if (contactLegs.length < 3) {
    return false; // Need at least 3 contact points
  }

  // Calculate support polygon (convex hull of contact points)
  const contactPoints2D = contactLegs.map(leg => ({
    x: leg.contactPoint!.x,
    y: leg.contactPoint!.y
  }));

  const hull = convexHull(contactPoints2D);

  // Check if spacecraft center (0, 0) is inside hull
  return pointInPolygon({ x: 0, y: 0 }, hull);
}
```

---

## 4. Waypoint Navigation Design

### 4.1 Requirements

**Must Have**:
- Create waypoint list
- Navigate to waypoint
- Auto-sequence to next waypoint
- Distance/bearing to waypoint
- ETA calculation

**Nice to Have**:
- Route optimization
- Fuel planning per waypoint
- Approach procedures
- Visual waypoint markers

### 4.2 Data Structure

```typescript
/**
 * EXTEND: navigation.ts
 */

export interface Waypoint {
  id: string;
  name: string;
  position: Vector3;           // Target position in world frame
  coordinates: LatLon;         // Lat/lon for display
  altitude: number;            // Target altitude (m)

  // Constraints
  maxApproachSpeed: number;    // m/s
  approachDirection?: Vector3; // Preferred approach vector

  // Status
  visited: boolean;
  arrivalTime?: number;        // Mission time when arrived
}

export interface Route {
  waypoints: Waypoint[];
  currentIndex: number;
  totalDistance: number;       // Sum of leg distances
  estimatedFuel: number;       // kg
  estimatedTime: number;       // seconds
}

export class WaypointManager {
  private waypoints: Waypoint[] = [];
  private currentWaypointIndex: number = 0;

  // Waypoint management
  addWaypoint(waypoint: Waypoint): void;
  removeWaypoint(id: string): void;
  clearWaypoints(): void;
  reorderWaypoints(newOrder: string[]): void;

  // Navigation
  getCurrentWaypoint(): Waypoint | null;
  getNextWaypoint(): Waypoint | null;
  advanceToNextWaypoint(): void;

  // Route planning
  calculateRoute(): Route;
  optimizeRoute(): void;        // Shortest path

  // State
  getWaypoints(): Waypoint[];
  getProgress(): { current: number; total: number };
}
```

### 4.3 Waypoint Arrival Detection

```typescript
checkWaypointArrival(
  position: Vector3,
  waypoint: Waypoint,
  arrivalRadius: number = 100  // meters
): boolean {
  const distance = magnitude({
    x: position.x - waypoint.position.x,
    y: position.y - waypoint.position.y,
    z: position.z - waypoint.position.z
  });

  return distance <= arrivalRadius;
}

update(dt: number, spacecraftPosition: Vector3): void {
  const current = this.getCurrentWaypoint();
  if (!current || current.visited) return;

  if (this.checkWaypointArrival(spacecraftPosition, current)) {
    current.visited = true;
    current.arrivalTime = this.missionTime;

    // Auto-advance to next
    this.advanceToNextWaypoint();

    // Trigger event
    this.emit('waypoint-reached', current);
  }
}
```

### 4.4 Route Planning

```typescript
calculateRoute(): Route {
  let totalDistance = 0;
  let estimatedFuel = 0;
  let estimatedTime = 0;

  for (let i = 0; i < this.waypoints.length - 1; i++) {
    const from = this.waypoints[i];
    const to = this.waypoints[i + 1];

    const leg = this.calculateLeg(from, to);
    totalDistance += leg.distance;
    estimatedFuel += leg.fuel;
    estimatedTime += leg.time;
  }

  return {
    waypoints: this.waypoints,
    currentIndex: this.currentWaypointIndex,
    totalDistance,
    estimatedFuel,
    estimatedTime
  };
}

private calculateLeg(from: Waypoint, to: Waypoint): LegEstimate {
  const distance = magnitude({
    x: to.position.x - from.position.x,
    y: to.position.y - from.position.y,
    z: to.position.z - from.position.z
  });

  // Simplified: assume constant velocity cruise
  const cruiseSpeed = 100; // m/s
  const time = distance / cruiseSpeed;

  // Fuel estimate: delta-v needed for velocity changes
  const deltaV = this.estimateDeltaV(from, to);
  const fuel = this.fuelForDeltaV(deltaV);

  return { distance, time, fuel };
}
```

---

## 5. Orbital Bodies & Docking Design

### 5.1 Requirements

**Orbital Bodies**:
- Satellite in lunar orbit (for rendezvous practice)
- Orbital station (for docking practice)
- N-body gravity (Moon + satellite)
- Orbital prediction

**Docking**:
- Docking port alignment
- Approach velocity limits
- Soft capture mechanism
- Hard dock locking
- Resource transfer

### 5.2 Data Structure

```typescript
/**
 * NEW FILE: orbital-bodies.ts
 */

export interface OrbitalBody {
  id: string;
  name: string;
  type: 'moon' | 'satellite' | 'station' | 'debris';

  // Orbital elements
  position: Vector3;
  velocity: Vector3;
  mass: number;                // kg
  radius: number;              // m (for collision)

  // For satellites
  orbitalPeriod?: number;      // seconds
  semiMajorAxis?: number;      // meters
  eccentricity?: number;
  inclination?: number;        // degrees

  // For dockable bodies
  dockingPorts?: DockingPort[];

  update(dt: number, gravitySource: OrbitalBody): void;
}

export interface DockingPort {
  id: string;
  position: Vector3;           // Relative to body center (body frame)
  orientation: Quaternion;     // Docking direction
  type: 'active' | 'passive';  // Active has capture mechanism
  diameter: number;            // meters
  docked: boolean;
  dockedTo?: string;           // ID of docked spacecraft/port
}

export class OrbitalBodyManager {
  private bodies: Map<string, OrbitalBody> = new Map();

  // Body management
  addBody(body: OrbitalBody): void;
  removeBody(id: string): void;
  getBody(id: string): OrbitalBody | null;
  getAllBodies(): OrbitalBody[];

  // Physics
  update(dt: number): void;
  calculateGravity(position: Vector3): Vector3;

  // Queries
  getBodiesInRange(position: Vector3, range: number): OrbitalBody[];
  findNearestBody(position: Vector3): OrbitalBody | null;
}
```

### 5.3 Satellite Orbit

```typescript
function createLunarSatellite(): OrbitalBody {
  // 100km circular orbit above Moon
  const orbitalAltitude = 100000; // m
  const orbitalRadius = MOON_RADIUS + orbitalAltitude;

  // Orbital velocity: v = √(GM/r)
  const orbitalSpeed = Math.sqrt(G * MOON_MASS / orbitalRadius);

  // Start at equator, moving east
  return {
    id: 'lunar_satellite_1',
    name: 'Lunar Survey Satellite',
    type: 'satellite',

    position: { x: orbitalRadius, y: 0, z: 0 },
    velocity: { x: 0, y: orbitalSpeed, z: 0 },

    mass: 500,              // kg
    radius: 2,              // m (small satellite)

    orbitalPeriod: 2 * Math.PI * orbitalRadius / orbitalSpeed,
    semiMajorAxis: orbitalRadius,
    eccentricity: 0,
    inclination: 0,

    dockingPorts: []        // Not dockable
  };
}
```

### 5.4 Orbital Station

```typescript
function createLunarStation(): OrbitalBody {
  // 200km circular orbit
  const orbitalAltitude = 200000; // m
  const orbitalRadius = MOON_RADIUS + orbitalAltitude;
  const orbitalSpeed = Math.sqrt(G * MOON_MASS / orbitalRadius);

  return {
    id: 'lunar_station_gateway',
    name: 'Gateway Lunar Station',
    type: 'station',

    position: { x: 0, y: orbitalRadius, z: 0 },
    velocity: { x: -orbitalSpeed, y: 0, z: 0 },

    mass: 50000,            // kg (large station)
    radius: 20,             // m

    orbitalPeriod: 2 * Math.PI * orbitalRadius / orbitalSpeed,
    semiMajorAxis: orbitalRadius,
    eccentricity: 0,
    inclination: 0,

    dockingPorts: [
      {
        id: 'port_alpha',
        position: { x: 0, y: 0, z: 15 },  // 15m from center
        orientation: { w: 1, x: 0, y: 0, z: 0 },  // Pointing +Z
        type: 'passive',
        diameter: 1.2,      // meters
        docked: false
      },
      {
        id: 'port_beta',
        position: { x: 0, y: 0, z: -15 },
        orientation: { w: 0, x: 0, y: 0, z: 1 },  // Pointing -Z
        type: 'passive',
        diameter: 1.2,
        docked: false
      }
    ]
  };
}
```

### 5.5 Docking System

```typescript
/**
 * NEW FILE: docking-system.ts
 */

export interface DockingState {
  status: 'undocked' | 'approaching' | 'aligned' | 'capturing' | 'docked';
  targetPort: DockingPort | null;
  distance: number;            // meters to port
  relativeVelocity: Vector3;   // m/s
  alignmentError: number;      // degrees
  readyToDock: boolean;
}

export class DockingComputer {
  private state: DockingState;

  // Control
  initiateApproach(targetPort: DockingPort): void;
  cancelApproach(): void;
  attemptDock(): boolean;
  undock(): void;

  // Guidance
  calculateApproachVector(
    spacecraftPos: Vector3,
    spacecraftVel: Vector3,
    targetPort: DockingPort,
    targetBody: OrbitalBody
  ): { targetVelocity: Vector3; targetAttitude: Quaternion };

  // State
  update(dt: number, spacecraft: Spacecraft, target: OrbitalBody): void;
  getState(): DockingState;
  canDock(): boolean;
}

// Docking criteria
function checkDockingCriteria(
  distance: number,
  relativeSpeed: number,
  alignmentError: number
): boolean {
  // NASA docking criteria (simplified)
  const MAX_DISTANCE = 0.5;          // 50cm
  const MAX_SPEED = 0.1;             // 10cm/s
  const MAX_ALIGNMENT_ERROR = 5;     // 5 degrees

  return distance < MAX_DISTANCE &&
         relativeSpeed < MAX_SPEED &&
         alignmentError < MAX_ALIGNMENT_ERROR;
}
```

### 5.6 Rendezvous Planning

```typescript
interface RendezvousManeuver {
  time: number;                // When to execute (mission time)
  deltaV: Vector3;             // Velocity change needed
  duration: number;            // Burn duration
  description: string;
}

class RendezvousPlanner {
  // Hohmann transfer to target orbit
  calculateRendezvous(
    spacecraftOrbit: OrbitalElements,
    targetOrbit: OrbitalElements
  ): RendezvousManeuver[] {
    const maneuvers: RendezvousManeuver[] = [];

    // Maneuver 1: Change orbit to intercept
    const interceptDeltaV = this.calculateHohmannDeltaV(
      spacecraftOrbit.semiMajorAxis,
      targetOrbit.semiMajorAxis
    );

    maneuvers.push({
      time: this.findOptimalTransferTime(spacecraftOrbit, targetOrbit),
      deltaV: interceptDeltaV,
      duration: this.estimateBurnTime(magnitude(interceptDeltaV)),
      description: 'Transfer burn to target orbit'
    });

    // Maneuver 2: Circularize at target altitude
    const circularizeDeltaV = this.calculateCircularizationDeltaV(
      spacecraftOrbit,
      targetOrbit
    );

    maneuvers.push({
      time: maneuvers[0].time + this.calculateTransferTime(spacecraftOrbit, targetOrbit),
      deltaV: circularizeDeltaV,
      duration: this.estimateBurnTime(magnitude(circularizeDeltaV)),
      description: 'Circularization burn'
    });

    // Maneuver 3: Final approach
    maneuvers.push({
      time: maneuvers[1].time + 3600, // 1 hour after circularization
      deltaV: { x: 0, y: 0, z: 5 },    // 5 m/s approach
      duration: 10,
      description: 'Final approach to docking port'
    });

    return maneuvers;
  }
}
```

---

## 6. Implementation Phases

### Phase 1: Terrain System (2 weeks)

**Week 1**: Core terrain
- [ ] Implement Perlin noise generator
- [ ] Create `TerrainSystem` class
- [ ] Add height map storage
- [ ] Implement `getElevation()` with interpolation
- [ ] Add major crater database (20-30 craters)
- [ ] Test elevation calculations

**Week 2**: Integration
- [ ] Fix radar altitude calculation in `navigation.ts`
- [ ] Add terrain collision detection
- [ ] Update landing detection to use terrain
- [ ] Add boulder field generation
- [ ] Update landing zones with real elevation data
- [ ] Add 20+ tests for terrain system

---

### Phase 2: Landing Gear (1 week)

**Days 1-2**: Basic structure
- [ ] Create `LandingGearSystem` class
- [ ] Implement leg geometry (3 or 4 legs)
- [ ] Add deployment/retraction mechanism
- [ ] Add to `Spacecraft` integration

**Days 3-4**: Physics
- [ ] Implement spring-damper forces
- [ ] Add ground contact detection
- [ ] Calculate contact forces and torques
- [ ] Integrate with `ShipPhysics` update loop

**Day 5**: Polish
- [ ] Add stability checker (tip-over detection)
- [ ] Add damage model for hard landings
- [ ] Add 15+ tests for landing gear
- [ ] Update interactive game to show gear status

---

### Phase 3: Environment System (1.5 weeks)

**Week 1**: Solar and thermal
- [ ] Create `EnvironmentSystem` class
- [ ] Implement solar position calculation
- [ ] Add day/night thermal cycling
- [ ] Update thermal system to use environment temps
- [ ] Test thermal effects on spacecraft

**Days 4-5**: Dynamic effects
- [ ] Implement plume-surface interaction
- [ ] Add dust kickup visualization
- [ ] Add micrometeorite impacts (optional)
- [ ] Add 10+ tests for environment

---

### Phase 4: Waypoint Navigation (3 days)

**Day 1**: Core functionality
- [ ] Extend `NavigationSystem` with `WaypointManager`
- [ ] Implement waypoint add/remove
- [ ] Add arrival detection

**Day 2**: Route planning
- [ ] Implement route calculation
- [ ] Add fuel/time estimates
- [ ] Add ETA to waypoint

**Day 3**: Integration
- [ ] Add waypoint display to interactive game
- [ ] Add keyboard commands for waypoint management
- [ ] Add 8+ tests for waypoints

---

### Phase 5: Orbital Bodies & Docking (2 weeks)

**Week 1**: Orbital bodies
- [ ] Create `OrbitalBodyManager` class
- [ ] Implement satellite in lunar orbit
- [ ] Add orbital station
- [ ] Update physics to handle multiple gravity sources
- [ ] Add relative position/velocity calculations
- [ ] Test orbital mechanics

**Week 2**: Docking
- [ ] Create `DockingSystem` class
- [ ] Implement docking port alignment
- [ ] Add approach guidance
- [ ] Implement capture mechanism
- [ ] Add resource transfer during docking
- [ ] Add 15+ tests for docking
- [ ] Update interactive game with docking controls

---

### Phase 6: Documentation & Polish (1 week)

**Days 1-2**: Documentation
- [ ] Update README with new features
- [ ] Document terrain system API
- [ ] Document landing gear usage
- [ ] Document waypoint navigation
- [ ] Document docking procedures
- [ ] Update CAPTAIN_SCREEN.md

**Days 3-5**: Polish
- [ ] Fix any remaining bugs
- [ ] Optimize performance
- [ ] Add visual improvements
- [ ] Create demo missions showcasing new features
- [ ] Record demo videos/GIFs

---

## 7. Testing Strategy

### 7.1 Unit Tests (New: ~100 tests)

**Terrain System** (25 tests):
- Perlin noise output validation
- Height map storage/retrieval
- Crater profile calculations
- Elevation interpolation accuracy
- Collision detection correctness

**Landing Gear** (20 tests):
- Deployment mechanics
- Spring-damper force calculations
- Contact detection accuracy
- Stability checker correctness
- Damage model thresholds

**Environment** (15 tests):
- Solar position calculations
- Thermal cycling behavior
- Plume effect formulas
- Micrometeorite probability

**Waypoints** (10 tests):
- Waypoint management (add/remove)
- Arrival detection
- Route calculation
- ETA accuracy

**Orbital Bodies** (15 tests):
- Orbital mechanics integration
- Multi-body gravity
- Satellite orbit stability
- Docking alignment checks
- Capture mechanism

**Docking** (15 tests):
- Alignment verification
- Approach guidance
- Velocity limits
- Capture success conditions
- Resource transfer

### 7.2 Integration Tests (New: ~30 tests)

- Terrain + Landing Gear: Realistic landing scenarios
- Environment + Thermal: Day/night thermal cycling
- Waypoints + Navigation: Multi-waypoint missions
- Orbital Bodies + Physics: Rendezvous maneuvers
- Docking + Resource Transfer: Complete docking sequence

### 7.3 End-to-End Tests (New: 5 scenarios)

1. **Complete Landing Mission**:
   - Start in orbit
   - Navigate to waypoint over rough terrain
   - Land on crater rim with landing gear
   - Handle day/night thermal cycling

2. **Rendezvous Mission**:
   - Start in low orbit
   - Perform Hohmann transfer to satellite
   - Match orbits
   - Approach to close range

3. **Docking Mission**:
   - Rendezvous with station
   - Align with docking port
   - Perform soft capture
   - Transfer fuel resources

4. **Exploration Mission**:
   - Fly to multiple waypoints
   - Land at each location
   - Takeoff and continue
   - Complete circuit

5. **Survival Mission**:
   - Land during lunar day
   - Survive night (extreme cold)
   - Survive day (extreme heat)
   - Manage micrometeorite impacts

---

## 8. Performance Considerations

### 8.1 Terrain System

**Height Map Memory**:
- 10 samples/degree: 25.9 MB (acceptable)
- 100 samples/degree: 2.59 GB (too large)
- **Solution**: 10-20 samples/degree with procedural detail

**Elevation Lookup Performance**:
- Target: <1ms per lookup
- Use spatial hashing for crater database
- Cache recent lookups

**Collision Detection**:
- Only check legs currently deployed
- Use bounding sphere pre-test
- Optimize raycasting

### 8.2 Environment System

**Solar Calculations**:
- Cache solar position (only recalculate every 10s)
- Pre-compute day/night map for current rotation

**Plume Effects**:
- Only calculate when altitude < 100m and engine on
- Simplify dust model (no particle simulation)

### 8.3 Orbital Bodies

**N-Body Gravity**:
- Only calculate gravity for bodies within 10x orbital radius
- Use 2-body approximation (Moon dominant, satellite perturbation)
- Higher timestep for distant bodies

**Collision Detection**:
- Spatial grid for body positions
- Only check nearby bodies

### 8.4 Overall Performance Target

**Frame Budget**: 100ms (10 FPS)
- Physics update: 40ms
- Terrain queries: 10ms
- Environment update: 5ms
- Orbital bodies: 10ms
- Rendering: 20ms
- Reserve: 15ms

---

## 9. File Structure

```
physics-modules/
├── src/
│   ├── types.ts                      [existing]
│   ├── fuel-system.ts                [existing]
│   ├── electrical-system.ts          [existing]
│   ├── compressed-gas-system.ts      [existing]
│   ├── thermal-system.ts             [existing]
│   ├── coolant-system.ts             [existing]
│   ├── main-engine.ts                [existing]
│   ├── rcs-system.ts                 [existing]
│   ├── ship-physics.ts               [existing]
│   ├── flight-control.ts             [existing]
│   ├── navigation.ts                 [existing - extend with waypoints]
│   ├── mission.ts                    [existing]
│   ├── spacecraft.ts                 [existing - integrate new systems]
│   │
│   ├── terrain-system.ts             [NEW]
│   ├── environment-system.ts         [NEW]
│   ├── landing-gear.ts               [NEW]
│   ├── orbital-bodies.ts             [NEW]
│   ├── docking-system.ts             [NEW]
│   └── utils/
│       ├── perlin-noise.ts           [NEW]
│       ├── convex-hull.ts            [NEW]
│       └── orbital-mechanics.ts      [NEW]
│
├── tests/
│   ├── terrain-system.test.ts        [NEW]
│   ├── environment.test.ts           [NEW]
│   ├── landing-gear.test.ts          [NEW]
│   ├── waypoints.test.ts             [NEW]
│   ├── orbital-bodies.test.ts        [NEW]
│   └── docking.test.ts               [NEW]
│
├── examples/
│   ├── interactive-game.ts           [UPDATE with new features]
│   ├── terrain-demo.ts               [NEW]
│   ├── landing-gear-demo.ts          [NEW]
│   ├── rendezvous-demo.ts            [NEW]
│   └── docking-demo.ts               [NEW]
│
└── docs/
    ├── README.md                     [UPDATE]
    ├── FLIGHT_SYSTEMS_DESIGN.md      [existing]
    ├── CAPTAIN_SCREEN.md             [UPDATE]
    ├── CRITICAL_REVIEW.md            [NEW - this document]
    ├── REAL_WORLD_IMPLEMENTATION.md  [NEW - implementation plan]
    ├── TERRAIN_GUIDE.md              [NEW]
    ├── LANDING_GEAR_GUIDE.md         [NEW]
    ├── WAYPOINT_GUIDE.md             [NEW]
    └── DOCKING_GUIDE.md              [NEW]
```

---

## 10. Dependencies

### New NPM Packages Needed

```json
{
  "dependencies": {
    "simplex-noise": "^4.0.1"  // For Perlin/Simplex noise generation
  }
}
```

All other features can be implemented with existing dependencies.

---

## 11. Configuration

### New Config Files

**terrain-config.json**:
```json
{
  "bodyRadius": 1737400,
  "heightMapResolution": 10,
  "maxElevation": 10000,
  "minElevation": -9000,
  "seed": 42,
  "majorCraters": "data/craters.json"
}
```

**landing-gear-config.json**:
```json
{
  "legCount": 4,
  "legSpacing": 2.5,
  "strutLength": 3.0,
  "springConstant": 50000,
  "dampingConstant": 5000,
  "maxCompression": 0.5,
  "deploymentTime": 5.0
}
```

**environment-config.json**:
```json
{
  "solarConstant": 1361,
  "rotationPeriod": 2358720,
  "axialTilt": 1.54,
  "micrometeorites": true,
  "solarWind": true
}
```

---

## 12. Success Criteria

### Terrain System Success
- [ ] Can generate realistic lunar surface with craters
- [ ] Elevation lookup < 1ms
- [ ] Radar altitude reflects actual terrain elevation
- [ ] Landing zones have varied terrain (flat, slopes, rims)
- [ ] Collision detection works for landing gear

### Environment Success
- [ ] Day/night cycle affects thermal management
- [ ] Solar position accurately calculated
- [ ] Plume creates dust when landing (visibility reduction)
- [ ] Environmental challenges add gameplay depth

### Landing Gear Success
- [ ] Realistic suspension physics (spring-damper)
- [ ] Smooth landings absorb impact
- [ ] Hard landings cause damage
- [ ] Stability checker prevents tip-overs
- [ ] Deployment/retraction works smoothly

### Waypoint Success
- [ ] Can create route with multiple waypoints
- [ ] Auto-advance to next waypoint
- [ ] Accurate distance/bearing displayed
- [ ] ETA and fuel estimates helpful
- [ ] Easy to use in interactive game

### Orbital Bodies Success
- [ ] Satellite maintains stable orbit
- [ ] Station orbits predictably
- [ ] Can rendezvous with moving targets
- [ ] Orbital prediction accurate

### Docking Success
- [ ] Can align with docking port
- [ ] Approach guidance works smoothly
- [ ] Soft capture feels realistic
- [ ] Hard dock locks securely
- [ ] Resource transfer works during docking

---

## 13. Timeline Summary

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **Phase 1: Terrain** | 2 weeks | Terrain system, craters, elevation, collision |
| **Phase 2: Landing Gear** | 1 week | Spring-damper physics, contact forces, stability |
| **Phase 3: Environment** | 1.5 weeks | Solar position, thermal cycling, plume effects |
| **Phase 4: Waypoints** | 3 days | Route planning, auto-sequencing, ETA |
| **Phase 5: Orbital Bodies** | 2 weeks | Satellite orbit, station, docking system |
| **Phase 6: Documentation** | 1 week | Updated docs, demos, polish |
| **TOTAL** | **8 weeks** | **Complete real-world flight simulator** |

---

## 14. Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Terrain performance | Medium | High | Use spatial hashing, cache lookups |
| Landing gear instability | Medium | High | Constraint solver, damping tuning |
| Docking alignment precision | High | Medium | Visual aids, autopilot assistance |
| Multi-body orbital divergence | Low | High | Validated integrator, timestep limits |
| Memory usage (height maps) | Low | Medium | Resolution limits, chunked loading |
| Scope creep | High | High | Stick to plan, defer nice-to-haves |

---

**END OF IMPLEMENTATION PLAN**

Ready to implement Phase 1: Terrain System!
