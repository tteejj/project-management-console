# World Environment & Celestial Bodies System Design

## Philosophy

The world exists in full 3D physics simulation, but **you never see it directly**. Like a submarine, you navigate by instruments, sensors, and displayed data only.

---

## Celestial Body System

### Body Types

```typescript
type BodyType =
  | 'planet'      // Large gravitational body
  | 'moon'        // Satellite of planet
  | 'station'     // Artificial structure (docking target)
  | 'asteroid'    // Small rocky body
  | 'comet'       // Icy body with tail
  | 'satellite'   // Small artificial object
  | 'derelict'    // Abandoned ship
  | 'debris';     // Space junk

interface CelestialBody {
  // Identity
  id: string;
  name: string;
  type: BodyType;

  // Physics (in 3D space)
  mass: number;              // kg
  radius: number;            // m (for collision sphere)
  position: Vector3;         // m (inertial frame)
  velocity: Vector3;         // m/s

  // Orbital (if orbiting)
  orbiting?: string;         // ID of parent body
  orbitalElements?: {
    semiMajorAxis: number;   // m
    eccentricity: number;    // 0-1
    inclination: number;     // radians
    longitudeAscNode: number;// radians
    argPeriapsis: number;    // radians
    meanAnomalyEpoch: number;// radians at t=0
  };

  // Gravitational influence
  sphereOfInfluence?: number;// m (where this body dominates gravity)
  surfaceGravity?: number;   // m/s² (for reference)

  // Sensor properties (how it appears on sensors)
  radarCrossSection: number; // m² (how visible on radar)
  thermalSignature: number;  // K (temperature, IR visibility)

  // Collision properties
  collisionDamage: number;   // Base damage on impact
  hardness: number;          // 0-1 (1 = solid rock, 0 = debris)
}
```

---

## World Environment

### World State Management

```typescript
interface WorldEnvironment {
  // All bodies in the world
  bodies: Map<string, CelestialBody>;

  // Current time
  simulationTime: number;    // seconds since epoch

  // Physics constants
  gravitationalConstant: number;  // G = 6.674e-11

  // Spatial partitioning (for performance)
  spatialGrid: SpatialGrid;
}

class World {
  private bodies: Map<string, CelestialBody> = new Map();
  private time: number = 0;
  private G: number = 6.674e-11;

  // Add/remove bodies
  addBody(body: CelestialBody): void;
  removeBody(id: string): void;
  getBody(id: string): CelestialBody | undefined;
  getBodiesInRange(position: Vector3, radius: number): CelestialBody[];

  // Physics updates
  update(dt: number): void {
    this.time += dt;

    // Update orbiting bodies
    this.updateOrbits(dt);

    // Update spatial grid (for fast queries)
    this.spatialGrid.rebuild(this.bodies);
  }

  // Calculate gravity at position from all nearby bodies
  getGravityAt(position: Vector3): Vector3 {
    const gravity = { x: 0, y: 0, z: 0 };

    // Get nearby bodies (within SOI or within query radius)
    const nearbyBodies = this.getBodiesInRange(position, 500000); // 500km

    for (const body of nearbyBodies) {
      const toBody = subtract(body.position, position);
      const distSq = magnitudeSquared(toBody);
      const dist = Math.sqrt(distSq);

      // Skip if inside body (handled by collision)
      if (dist < body.radius) continue;

      // F = -G * m1 * m2 / r²
      // a = F / m1 = -G * m2 / r²
      const forceMag = -this.G * body.mass / distSq;
      const forceDir = normalize(toBody);

      gravity.x += forceDir.x * forceMag;
      gravity.y += forceDir.y * forceMag;
      gravity.z += forceDir.z * forceMag;
    }

    return gravity;
  }

  // Update orbital positions (for moving bodies)
  private updateOrbits(dt: number): void {
    for (const body of this.bodies.values()) {
      if (!body.orbiting || !body.orbitalElements) continue;

      const parent = this.bodies.get(body.orbiting);
      if (!parent) continue;

      // Calculate orbital position at current time
      const orbitalPos = this.calculateOrbitalPosition(
        body.orbitalElements,
        this.time
      );

      // Transform to inertial frame
      body.position = add(parent.position, orbitalPos);

      // Calculate orbital velocity (perpendicular to position)
      body.velocity = this.calculateOrbitalVelocity(
        body.orbitalElements,
        orbitalPos,
        parent.mass
      );
    }
  }

  // Kepler's equations for orbital position
  private calculateOrbitalPosition(
    elements: OrbitalElements,
    time: number
  ): Vector3 {
    // Mean motion: n = sqrt(G*M/a³)
    // Mean anomaly: M = M₀ + n*t
    // Solve Kepler's equation: E - e*sin(E) = M
    // Position in orbital plane: x = a*(cos(E) - e), y = a*sqrt(1-e²)*sin(E)
    // Rotate by orbital elements to get 3D position

    // (Implementation of orbital mechanics math)
    // ... see standard orbital mechanics textbooks

    return { x: 0, y: 0, z: 0 }; // Placeholder
  }
}
```

---

## MVP World Configuration

### Simplified for MVP

For the MVP, we don't need full orbital mechanics. Static or simplified motion:

```typescript
// MVP: Simple system with fixed positions
const createMVPWorld = (): World => {
  const world = new World();

  // Central planet (Moon)
  world.addBody({
    id: 'moon',
    name: 'Luna',
    type: 'planet',
    mass: 7.342e22,        // kg
    radius: 1737400,       // m (1737 km)
    position: { x: 0, y: 0, z: 0 },
    velocity: { x: 0, y: 0, z: 0 },
    surfaceGravity: 1.62,  // m/s²
    radarCrossSection: 1e12, // Huge
    thermalSignature: 250,  // K (cold)
    collisionDamage: 1000,  // Instant death
    hardness: 1.0
  });

  // Station Alpha (docking target)
  world.addBody({
    id: 'station_alpha',
    name: 'Station Alpha',
    type: 'station',
    mass: 50000,           // kg (50 tons)
    radius: 25,            // m (50m diameter)
    position: { x: 0, y: 0, z: 1737400 + 15000 }, // 15km altitude
    velocity: { x: 1200, y: 0, z: 0 }, // Orbital velocity
    orbiting: 'moon',      // In orbit around moon
    radarCrossSection: 100, // m²
    thermalSignature: 300,  // K (warm, powered)
    collisionDamage: 50,
    hardness: 0.8
  });

  // Station Bravo (alternate target)
  world.addBody({
    id: 'station_bravo',
    name: 'Station Bravo',
    type: 'station',
    mass: 80000,
    radius: 30,
    position: { x: 25000, y: 0, z: 1737400 + 20000 }, // 20km alt, 25km away
    velocity: { x: 1150, y: 0, z: 0 },
    orbiting: 'moon',
    radarCrossSection: 150,
    thermalSignature: 295,
    collisionDamage: 60,
    hardness: 0.8
  });

  return world;
};
```

**MVP Simplifications:**
- Fixed station positions (or very slow orbital motion)
- Only 1 planet (Moon)
- 2-3 stations
- No asteroids yet (added for events)

---

## Asteroid Fields & Debris (Events)

### Dynamic Content

```typescript
// Generate asteroid field for event
interface AsteroidFieldConfig {
  center: Vector3;       // Field center position
  radius: number;        // Field radius (m)
  density: number;       // Asteroids per cubic km
  minSize: number;       // Minimum asteroid radius (m)
  maxSize: number;       // Maximum asteroid radius (m)
  velocityRange: number; // Random velocity magnitude (m/s)
  seed: number;          // For deterministic generation
}

class AsteroidField {
  asteroids: CelestialBody[] = [];

  generate(config: AsteroidFieldConfig): void {
    const rng = seededRandom(config.seed);
    const volume = (4/3) * Math.PI * Math.pow(config.radius, 3);
    const volumeKm3 = volume / 1e9; // Convert to km³
    const count = Math.floor(config.density * volumeKm3);

    for (let i = 0; i < count; i++) {
      // Random position within sphere
      const theta = rng() * Math.PI * 2;
      const phi = Math.acos(2 * rng() - 1);
      const r = Math.pow(rng(), 1/3) * config.radius;

      const pos = {
        x: config.center.x + r * Math.sin(phi) * Math.cos(theta),
        y: config.center.y + r * Math.sin(phi) * Math.sin(theta),
        z: config.center.z + r * Math.cos(phi)
      };

      // Random velocity
      const velTheta = rng() * Math.PI * 2;
      const velPhi = Math.acos(2 * rng() - 1);
      const velMag = rng() * config.velocityRange;

      const vel = {
        x: velMag * Math.sin(velPhi) * Math.cos(velTheta),
        y: velMag * Math.sin(velPhi) * Math.sin(velTheta),
        z: velMag * Math.cos(velPhi)
      };

      // Random size
      const radius = config.minSize + rng() * (config.maxSize - config.minSize);

      this.asteroids.push({
        id: `asteroid_${i}`,
        name: `Asteroid ${i}`,
        type: 'asteroid',
        mass: (4/3) * Math.PI * Math.pow(radius, 3) * 3000, // Rock density
        radius,
        position: pos,
        velocity: vel,
        radarCrossSection: Math.PI * radius * radius, // Projected area
        thermalSignature: 100, // Cold rock
        collisionDamage: 10 * radius, // Bigger = more damage
        hardness: 1.0
      });
    }
  }

  update(dt: number): void {
    // Simple ballistic motion
    for (const asteroid of this.asteroids) {
      asteroid.position.x += asteroid.velocity.x * dt;
      asteroid.position.y += asteroid.velocity.y * dt;
      asteroid.position.z += asteroid.velocity.z * dt;
    }
  }

  // Add to world temporarily for event
  addToWorld(world: World): void {
    for (const asteroid of this.asteroids) {
      world.addBody(asteroid);
    }
  }

  // Remove after event
  removeFromWorld(world: World): void {
    for (const asteroid of this.asteroids) {
      world.removeBody(asteroid.id);
    }
  }
}
```

**Usage in Events:**
```typescript
// Navigation event: "Asteroid Field Threading"
const event = {
  onStart: () => {
    const field = new AsteroidField();
    field.generate({
      center: { x: 10000, y: 0, z: 1752400 },
      radius: 2000,      // 2km radius field
      density: 50,       // 50 asteroids per km³
      minSize: 5,        // 5m minimum
      maxSize: 50,       // 50m maximum
      velocityRange: 10, // 0-10 m/s random motion
      seed: 12345
    });
    field.addToWorld(world);

    // Player must navigate through without collision
  },

  onComplete: () => {
    field.removeFromWorld(world);
  }
};
```

---

## Spatial Partitioning (Performance)

### Quadtree/Octree for Fast Queries

```typescript
class SpatialGrid {
  private cellSize: number = 10000; // 10km cells
  private grid: Map<string, CelestialBody[]> = new Map();

  rebuild(bodies: Map<string, CelestialBody>): void {
    this.grid.clear();

    for (const body of bodies.values()) {
      const cellKey = this.getCellKey(body.position);

      if (!this.grid.has(cellKey)) {
        this.grid.set(cellKey, []);
      }

      this.grid.get(cellKey)!.push(body);
    }
  }

  getBodiesNear(position: Vector3, radius: number): CelestialBody[] {
    const cellsToCheck = this.getCellsInRadius(position, radius);
    const bodies: CelestialBody[] = [];

    for (const cellKey of cellsToCheck) {
      const cellBodies = this.grid.get(cellKey);
      if (cellBodies) {
        // Filter by actual distance
        for (const body of cellBodies) {
          const dist = distance(body.position, position);
          if (dist <= radius) {
            bodies.push(body);
          }
        }
      }
    }

    return bodies;
  }

  private getCellKey(pos: Vector3): string {
    const cx = Math.floor(pos.x / this.cellSize);
    const cy = Math.floor(pos.y / this.cellSize);
    const cz = Math.floor(pos.z / this.cellSize);
    return `${cx},${cy},${cz}`;
  }

  private getCellsInRadius(pos: Vector3, radius: number): string[] {
    const cells: string[] = [];
    const cellRadius = Math.ceil(radius / this.cellSize);

    const centerCell = this.getCellKey(pos);
    const [cx, cy, cz] = centerCell.split(',').map(Number);

    for (let dx = -cellRadius; dx <= cellRadius; dx++) {
      for (let dy = -cellRadius; dy <= cellRadius; dy++) {
        for (let dz = -cellRadius; dz <= cellRadius; dz++) {
          cells.push(`${cx + dx},${cy + dy},${cz + dz}`);
        }
      }
    }

    return cells;
  }
}
```

---

## Integration with Existing Physics

### Connecting to Spacecraft

```typescript
class Spacecraft {
  // Existing physics
  private shipPhysics: ShipPhysics;

  // NEW: World reference
  private world: World;

  update(dt: number): void {
    // Get gravity from all nearby bodies (not just one planet)
    const gravity = this.world.getGravityAt(this.shipPhysics.position);

    // Apply to ship physics
    this.shipPhysics.update(dt, mainThrust, rcsThrust, rcsTorque, gravity);

    // Check for collisions (handled in collision system)
  }
}
```

---

## Data Queries for Sensors

### What Sensors Need from World

```typescript
interface SensorQuery {
  // Get all bodies detectable by radar
  getRadarContacts(
    sensorPosition: Vector3,
    maxRange: number,
    minCrossSection: number
  ): RadarContact[];

  // Get all bodies detectable by thermal
  getThermalContacts(
    sensorPosition: Vector3,
    maxRange: number,
    minTemperature: number
  ): ThermalContact[];

  // Get closest body for collision warning
  getClosestBody(
    position: Vector3,
    excludeTypes?: BodyType[]
  ): { body: CelestialBody, distance: number };

  // Get targetable bodies (stations, derelicts)
  getTargetableBodies(): CelestialBody[];
}

interface RadarContact {
  id: string;
  name: string;
  range: number;         // m
  bearing: number;       // radians (0 = north)
  elevation: number;     // radians (0 = horizon)
  relativeVelocity: Vector3; // m/s
  closingRate: number;   // m/s (negative = opening)
  type: BodyType;
}
```

**Important:** Sensors return **processed data**, not raw body positions. This is what gets displayed on screens.

---

## World Files (Data-Driven)

### JSON Configuration

```json
{
  "systemName": "Lunar Sector",
  "bodies": [
    {
      "id": "moon",
      "name": "Luna",
      "type": "planet",
      "mass": 7.342e22,
      "radius": 1737400,
      "position": [0, 0, 0],
      "velocity": [0, 0, 0],
      "radarCrossSection": 1e12,
      "thermalSignature": 250,
      "collisionDamage": 1000,
      "hardness": 1.0
    },
    {
      "id": "station_alpha",
      "name": "Station Alpha",
      "type": "station",
      "mass": 50000,
      "radius": 25,
      "position": [0, 0, 1752400],
      "velocity": [1200, 0, 0],
      "orbiting": "moon",
      "radarCrossSection": 100,
      "thermalSignature": 300,
      "collisionDamage": 50,
      "hardness": 0.8
    }
  ]
}
```

Load from file for different scenarios/sectors.

---

## Summary

**World Environment:**
- Manages all celestial bodies in 3D space
- Calculates gravity from multiple sources
- Updates orbital motion (for moving stations, asteroids)
- Provides spatial queries for sensors and collision detection

**Bodies Include:**
- Planets (1 for MVP)
- Stations (2-3 docking targets)
- Asteroids (generated for events)
- Derelicts (encounter events)
- Debris (hazards)

**No Rendering:**
- World exists in pure physics/data
- Sensors query world for contacts
- Displays show sensor returns (numbers, blips, bearings)
- Like submarine sonar - you see data, not the world itself

**Next:** Hull damage system with armor penetration and angle of impact.
