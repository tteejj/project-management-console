# Procedural Content Generation System Design

## Overview

**Purpose:** Generate game content dynamically - asteroid fields, debris, system layouts, encounters

**Goals:**
- Infinite replayability (different systems each run)
- Deterministic (same seed = same content)
- Performance-friendly (generate on-demand)
- Balanced difficulty
- Interesting scenarios

**What to Generate:**
1. Star systems (planets, moons, stations, asteroids)
2. Asteroid fields (for navigation events)
3. Debris clouds (for hazard events)
4. Derelict ships (for exploration events)
5. Random encounters (distress calls, anomalies)

---

## Seeded Random Number Generation

### Deterministic PRNG

```typescript
// Mulberry32 PRNG - fast, good quality, deterministic
class SeededRandom {
  private state: number;

  constructor(seed: number) {
    this.state = seed;
  }

  // Returns float [0, 1)
  next(): number {
    let t = (this.state += 0x6D2B79F5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  // Returns int [min, max)
  nextInt(min: number, max: number): number {
    return Math.floor(this.next() * (max - min)) + min;
  }

  // Returns float [min, max)
  nextFloat(min: number, max: number): number {
    return this.next() * (max - min) + min;
  }

  // Returns true with probability p
  chance(p: number): boolean {
    return this.next() < p;
  }

  // Pick random element from array
  pick<T>(array: T[]): T {
    return array[this.nextInt(0, array.length)];
  }

  // Shuffle array (Fisher-Yates)
  shuffle<T>(array: T[]): T[] {
    const result = [...array];
    for (let i = result.length - 1; i > 0; i--) {
      const j = this.nextInt(0, i + 1);
      [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
  }

  // Normal distribution (Box-Muller transform)
  nextGaussian(mean: number = 0, stddev: number = 1): number {
    const u1 = this.next();
    const u2 = this.next();
    const z0 = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
    return z0 * stddev + mean;
  }
}
```

---

## Star System Generation

### System Layout

```typescript
interface SystemConfig {
  seed: number;
  systemType: 'inner' | 'outer' | 'belt' | 'deep';
  difficulty: number; // 0-1 (affects hazard density)
}

interface GeneratedSystem {
  seed: number;
  name: string;

  // Celestial bodies
  centralBody: CelestialBody; // Planet or moon
  stations: CelestialBody[];
  asteroids: CelestialBody[];
  derelicts: CelestialBody[];

  // Regions
  asteroidFields: AsteroidField[];
  debrisClouds: DebrisCloud[];

  // Metadata
  difficulty: number;
  objectives: string[]; // Possible mission objectives
}

class SystemGenerator {
  generate(config: SystemConfig): GeneratedSystem {
    const rng = new SeededRandom(config.seed);

    // 1. Central body (planet/moon)
    const centralBody = this.generateCentralBody(config, rng);

    // 2. Stations (2-4)
    const stations = this.generateStations(config, rng, centralBody);

    // 3. Asteroid fields (1-3)
    const asteroidFields = this.generateAsteroidFields(config, rng, centralBody);

    // 4. Debris clouds (0-2)
    const debrisClouds = this.generateDebrisClouds(config, rng);

    // 5. Derelicts (0-2)
    const derelicts = this.generateDerelicts(config, rng);

    // 6. Individual asteroids (scattered)
    const asteroids = this.scatterAsteroids(config, rng, asteroidFields);

    // 7. Generate name
    const name = this.generateSystemName(config.seed, rng);

    // 8. Determine objectives
    const objectives = this.generateObjectives(stations, derelicts, rng);

    return {
      seed: config.seed,
      name,
      centralBody,
      stations,
      asteroids,
      derelicts,
      asteroidFields,
      debrisClouds,
      difficulty: config.difficulty,
      objectives
    };
  }

  private generateCentralBody(config: SystemConfig, rng: SeededRandom): CelestialBody {
    // Moon for inner system, small planet for outer
    const isMoon = config.systemType === 'inner' || rng.chance(0.7);

    if (isMoon) {
      return {
        id: 'central_body',
        name: 'Moon',
        type: 'moon',
        mass: 7.342e22,
        radius: 1737400, // 1737 km
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 },
        radarCrossSection: 1e12,
        thermalSignature: 250, // Cool surface
        collisionDamage: 1000,
        hardness: 1000,
        collider: {
          type: CollisionShapeType.SPHERE,
          radius: 1737400
        }
      };
    } else {
      // Small planet
      return {
        id: 'central_body',
        name: 'Planet',
        type: 'planet',
        mass: 6.4e23, // Mars-like
        radius: 3390000,
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 },
        radarCrossSection: 1e14,
        thermalSignature: 210,
        collisionDamage: 1000,
        hardness: 1000,
        collider: {
          type: CollisionShapeType.SPHERE,
          radius: 3390000
        }
      };
    }
  }

  private generateStations(
    config: SystemConfig,
    rng: SeededRandom,
    centralBody: CelestialBody
  ): CelestialBody[] {
    const stations: CelestialBody[] = [];
    const numStations = rng.nextInt(2, 5); // 2-4 stations

    const stationNames = [
      'Alpha Station', 'Beta Outpost', 'Gamma Base',
      'Delta Port', 'Epsilon Hub', 'Zeta Terminal'
    ];

    for (let i = 0; i < numStations; i++) {
      // Orbital radius (100km - 500km above surface)
      const altitude = rng.nextFloat(100000, 500000);
      const orbitalRadius = centralBody.radius + altitude;

      // Random position on orbit
      const angle = rng.nextFloat(0, Math.PI * 2);
      const position = {
        x: Math.cos(angle) * orbitalRadius,
        y: Math.sin(angle) * orbitalRadius,
        z: rng.nextFloat(-10000, 10000) // Slight vertical offset
      };

      // Orbital velocity (circular orbit)
      const orbitalSpeed = Math.sqrt(G * centralBody.mass / orbitalRadius);
      const velocity = {
        x: -Math.sin(angle) * orbitalSpeed,
        y: Math.cos(angle) * orbitalSpeed,
        z: 0
      };

      const station: CelestialBody = {
        id: `station_${i}`,
        name: stationNames[i] || `Station ${i}`,
        type: 'station',
        mass: rng.nextFloat(20000, 80000), // 20-80 tons
        radius: rng.nextFloat(15, 30), // 15-30m
        position,
        velocity,
        radarCrossSection: rng.nextFloat(200, 400),
        thermalSignature: rng.nextFloat(400, 600), // Warm
        collisionDamage: 500,
        hardness: 300,
        collider: {
          type: CollisionShapeType.COMPOUND,
          children: [
            {
              type: CollisionShapeType.SPHERE,
              radius: rng.nextFloat(10, 15)
            }
          ]
        }
      };

      stations.push(station);
    }

    return stations;
  }
}
```

---

## Asteroid Field Generation

### Clustered Distribution

```typescript
interface AsteroidField {
  id: string;
  center: Vector3;
  radius: number;      // m
  density: number;     // Asteroids per km³
  asteroidCount: number;
  minSize: number;     // m
  maxSize: number;     // m
}

interface AsteroidFieldConfig {
  center: Vector3;
  radius: number;
  density: number;
  velocityRange: [number, number]; // m/s
}

class AsteroidFieldGenerator {
  generate(
    config: AsteroidFieldConfig,
    rng: SeededRandom
  ): { field: AsteroidField; asteroids: CelestialBody[] } {
    const asteroidCount = Math.floor(
      (4/3) * Math.PI * (config.radius ** 3) * (config.density / 1e9) // Convert to m³
    );

    const asteroids: CelestialBody[] = [];

    for (let i = 0; i < asteroidCount; i++) {
      const asteroid = this.generateAsteroid(config, rng, i);
      asteroids.push(asteroid);
    }

    const field: AsteroidField = {
      id: `field_${Math.floor(rng.next() * 10000)}`,
      center: config.center,
      radius: config.radius,
      density: config.density,
      asteroidCount,
      minSize: 1,
      maxSize: 100
    };

    return { field, asteroids };
  }

  private generateAsteroid(
    config: AsteroidFieldConfig,
    rng: SeededRandom,
    index: number
  ): CelestialBody {
    // Random position within sphere (uniform distribution)
    const theta = rng.nextFloat(0, Math.PI * 2);
    const phi = Math.acos(rng.nextFloat(-1, 1));
    const r = config.radius * Math.cbrt(rng.next()); // Cube root for uniform volume

    const position = {
      x: config.center.x + r * Math.sin(phi) * Math.cos(theta),
      y: config.center.y + r * Math.sin(phi) * Math.sin(theta),
      z: config.center.z + r * Math.cos(phi)
    };

    // Random velocity
    const speed = rng.nextFloat(config.velocityRange[0], config.velocityRange[1]);
    const velTheta = rng.nextFloat(0, Math.PI * 2);
    const velPhi = Math.acos(rng.nextFloat(-1, 1));

    const velocity = {
      x: speed * Math.sin(velPhi) * Math.cos(velTheta),
      y: speed * Math.sin(velPhi) * Math.sin(velTheta),
      z: speed * Math.cos(velPhi)
    };

    // Size (power law distribution - more small asteroids than large)
    const sizeExponent = -2.5; // Real asteroid size distribution
    const u = rng.next();
    const minSize = 1; // 1m
    const maxSize = 100; // 100m
    const size = minSize * Math.pow(maxSize / minSize, Math.pow(u, 1 / (sizeExponent + 1)));

    // Mass (assume rocky density ~2500 kg/m³)
    const density = 2500;
    const volume = (4/3) * Math.PI * (size ** 3);
    const mass = volume * density;

    return {
      id: `asteroid_${index}`,
      name: `Asteroid ${index}`,
      type: 'asteroid',
      mass,
      radius: size,
      position,
      velocity,
      radarCrossSection: Math.PI * (size ** 2),
      thermalSignature: 50, // Very cold
      collisionDamage: mass * 0.001, // Proportional to mass
      hardness: 500,
      collider: {
        type: CollisionShapeType.SPHERE,
        radius: size
      }
    };
  }
}
```

---

## Debris Cloud Generation

### High-Density Hazard

```typescript
interface DebrisCloud {
  id: string;
  center: Vector3;
  size: number;        // m (radius)
  particleCount: number;
  velocityDispersion: number; // m/s (how spread out velocities are)
}

class DebrisCloudGenerator {
  generate(
    center: Vector3,
    size: number,
    particleCount: number,
    rng: SeededRandom
  ): { cloud: DebrisCloud; debris: CelestialBody[] } {
    const debris: CelestialBody[] = [];

    // Mean velocity (debris field might be orbiting or stationary)
    const meanVelocity = {
      x: rng.nextFloat(-10, 10),
      y: rng.nextFloat(-10, 10),
      z: rng.nextFloat(-10, 10)
    };

    const velocityDispersion = size / 100; // Larger fields = more velocity variation

    for (let i = 0; i < particleCount; i++) {
      // Gaussian distribution for position (clustered in center)
      const position = {
        x: center.x + rng.nextGaussian(0, size / 3),
        y: center.y + rng.nextGaussian(0, size / 3),
        z: center.z + rng.nextGaussian(0, size / 3)
      };

      // Gaussian distribution for velocity (around mean)
      const velocity = {
        x: meanVelocity.x + rng.nextGaussian(0, velocityDispersion),
        y: meanVelocity.y + rng.nextGaussian(0, velocityDispersion),
        z: meanVelocity.z + rng.nextGaussian(0, velocityDispersion)
      };

      // Very small debris (0.1m - 5m)
      const size = rng.nextFloat(0.1, 5);
      const mass = (4/3) * Math.PI * (size ** 3) * 3000; // Metal density

      debris.push({
        id: `debris_${i}`,
        name: `Debris ${i}`,
        type: 'debris',
        mass,
        radius: size,
        position,
        velocity,
        radarCrossSection: Math.PI * (size ** 2) * 0.1, // Low RCS
        thermalSignature: 10, // Very cold
        collisionDamage: mass * 0.01,
        hardness: 200,
        collider: {
          type: CollisionShapeType.SPHERE,
          radius: size
        }
      });
    }

    return {
      cloud: {
        id: `debris_cloud_${Math.floor(rng.next() * 10000)}`,
        center,
        size,
        particleCount,
        velocityDispersion
      },
      debris
    };
  }
}
```

---

## Derelict Ship Generation

### Exploration Targets

```typescript
interface Derelict {
  ship: CelestialBody;
  condition: 'intact' | 'damaged' | 'destroyed';
  powerOnline: boolean;
  fuelRemaining: number; // kg
  cargoType: 'fuel' | 'parts' | 'salvage' | 'none';
  cargoAmount: number;
  backstory: string;
}

class DerelictGenerator {
  private backstories = [
    'Lost during the Solar Storm of 2187',
    'Abandoned after engine failure',
    'Crew evacuated - unknown cause',
    'Collision victim - structural damage',
    'Fuel depleted - adrift for weeks',
    'Emergency shutdown - reactor failure'
  ];

  generate(
    position: Vector3,
    velocity: Vector3,
    rng: SeededRandom
  ): Derelict {
    const condition = rng.pick(['intact', 'damaged', 'destroyed'] as const);

    // Ship specs
    const shipMass = rng.nextFloat(5000, 20000);
    const shipSize = rng.nextFloat(8, 15);

    const ship: CelestialBody = {
      id: `derelict_${Math.floor(rng.next() * 10000)}`,
      name: `Derelict ${this.generateShipName(rng)}`,
      type: 'derelict',
      mass: shipMass,
      radius: shipSize,
      position,
      velocity,
      radarCrossSection: Math.PI * (shipSize ** 2),
      thermalSignature: rng.chance(0.1) ? 200 : 50, // 10% chance still warm
      collisionDamage: 300,
      hardness: 200,
      collider: {
        type: CollisionShapeType.CAPSULE,
        radius: shipSize / 2,
        height: shipSize,
        axis: 'x'
      }
    };

    // Resources
    const fuelRemaining = condition === 'intact' ?
      rng.nextFloat(100, 500) :
      rng.nextFloat(0, 100);

    const cargoType = rng.pick(['fuel', 'parts', 'salvage', 'none'] as const);
    const cargoAmount = cargoType !== 'none' ? rng.nextFloat(50, 300) : 0;

    return {
      ship,
      condition,
      powerOnline: rng.chance(0.1), // 10% still have emergency power
      fuelRemaining,
      cargoType,
      cargoAmount,
      backstory: rng.pick(this.backstories)
    };
  }

  private generateShipName(rng: SeededRandom): string {
    const prefixes = ['Star', 'Void', 'Cosmos', 'Nova', 'Nebula'];
    const suffixes = ['Runner', 'Wanderer', 'Explorer', 'Pioneer', 'Voyager'];
    const numbers = rng.nextInt(100, 999);

    return `${rng.pick(prefixes)}-${rng.pick(suffixes)}-${numbers}`;
  }
}
```

---

## Mission Objective Generation

### Procedural Objectives

```typescript
enum ObjectiveType {
  DOCK_AT_STATION,
  INVESTIGATE_DERELICT,
  TRAVERSE_ASTEROID_FIELD,
  AVOID_DEBRIS_CLOUD,
  RESCUE_SURVIVORS,
  DELIVER_CARGO,
  SCAN_ANOMALY
}

interface MissionObjective {
  type: ObjectiveType;
  target: string; // ID of celestial body
  description: string;
  rewards: {
    fuel?: number;
    parts?: number;
    credits?: number;
  };
  timeLimit?: number; // seconds
}

class MissionGenerator {
  generateObjectives(
    system: GeneratedSystem,
    rng: SeededRandom
  ): MissionObjective[] {
    const objectives: MissionObjective[] = [];

    // Always have at least one docking objective
    if (system.stations.length > 0) {
      const station = rng.pick(system.stations);
      objectives.push({
        type: ObjectiveType.DOCK_AT_STATION,
        target: station.id,
        description: `Dock at ${station.name} for refueling`,
        rewards: { fuel: 500, parts: 5 }
      });
    }

    // Add derelict investigation if available
    if (system.derelicts.length > 0 && rng.chance(0.7)) {
      const derelict = rng.pick(system.derelicts);
      objectives.push({
        type: ObjectiveType.INVESTIGATE_DERELICT,
        target: derelict.id,
        description: `Investigate ${derelict.name}`,
        rewards: { parts: rng.nextInt(10, 30), credits: rng.nextInt(100, 500) }
      });
    }

    // Add asteroid field traverse if available
    if (system.asteroidFields.length > 0 && rng.chance(0.5)) {
      const field = rng.pick(system.asteroidFields);
      objectives.push({
        type: ObjectiveType.TRAVERSE_ASTEROID_FIELD,
        target: field.id,
        description: `Navigate through asteroid field`,
        rewards: { credits: rng.nextInt(200, 800) },
        timeLimit: 300 // 5 minutes
      });
    }

    return objectives;
  }
}
```

---

## On-Demand Generation (Streaming)

### Generate As Needed

```typescript
class StreamingWorldGenerator {
  private generated: Map<string, CelestialBody[]> = new Map();
  private generationRadius: number = 100000; // 100km

  update(shipPosition: Vector3, system: GeneratedSystem): void {
    // Check which asteroid fields are nearby
    for (const field of system.asteroidFields) {
      const distance = magnitude(subtract(field.center, shipPosition));

      if (distance < field.radius + this.generationRadius) {
        // Generate asteroids for this field (if not already done)
        if (!this.generated.has(field.id)) {
          const rng = new SeededRandom(hashString(field.id));
          const config: AsteroidFieldConfig = {
            center: field.center,
            radius: field.radius,
            density: field.density,
            velocityRange: [1, 20]
          };

          const { asteroids } = new AsteroidFieldGenerator().generate(config, rng);
          this.generated.set(field.id, asteroids);

          // Add to world
          for (const asteroid of asteroids) {
            system.asteroids.push(asteroid);
          }
        }
      } else {
        // Far away - can unload to save memory
        if (this.generated.has(field.id)) {
          // Remove from world
          const asteroids = this.generated.get(field.id)!;
          system.asteroids = system.asteroids.filter(
            a => !asteroids.includes(a)
          );
          this.generated.delete(field.id);
        }
      }
    }
  }
}

function hashString(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32-bit integer
  }
  return hash >>> 0; // Unsigned
}
```

---

## Event Triggers

### Random Encounters

```typescript
enum EncounterType {
  DISTRESS_SIGNAL,
  DEBRIS_FIELD,
  SOLAR_FLARE,
  EQUIPMENT_MALFUNCTION,
  ANOMALY_DETECTED
}

interface RandomEncounter {
  type: EncounterType;
  position: Vector3;
  description: string;
  trigger: (ship: Spacecraft) => void;
}

class EncounterGenerator {
  generateEncounters(
    system: GeneratedSystem,
    rng: SeededRandom,
    count: number
  ): RandomEncounter[] {
    const encounters: RandomEncounter[] = [];

    for (let i = 0; i < count; i++) {
      const type = rng.pick(Object.values(EncounterType));

      // Random position in system
      const position = {
        x: rng.nextFloat(-500000, 500000),
        y: rng.nextFloat(-500000, 500000),
        z: rng.nextFloat(-50000, 50000)
      };

      let description: string;
      let trigger: (ship: Spacecraft) => void;

      switch (type) {
        case EncounterType.DISTRESS_SIGNAL:
          description = 'Distress signal detected on emergency frequency';
          trigger = (ship) => {
            // Trigger rescue mission
            ship.communications.receiveMessage({
              sender: 'Unknown',
              message: 'MAYDAY - Reactor failure - 2 hours oxygen remaining',
              priority: 'critical'
            });
          };
          break;

        case EncounterType.DEBRIS_FIELD:
          description = 'Debris field ahead - reduce velocity';
          trigger = (ship) => {
            // Spawn debris cloud
            const debris = new DebrisCloudGenerator().generate(
              position,
              5000, // 5km
              50,
              rng
            );
            // Add to world
          };
          break;

        case EncounterType.ANOMALY_DETECTED:
          description = 'Unknown sensor contact - possible anomaly';
          trigger = (ship) => {
            // Add strange sensor reading
            ship.sensors.addGhostContact(position);
          };
          break;

        // ... other encounter types
      }

      encounters.push({ type, position, description, trigger });
    }

    return encounters;
  }
}
```

---

## Performance Optimization

### Spatial Partitioning

```typescript
class ChunkedWorldGenerator {
  private chunkSize: number = 50000; // 50km chunks
  private activeChunks: Map<string, CelestialBody[]> = new Map();

  // Determine which chunk a position is in
  private getChunkKey(position: Vector3): string {
    const chunkX = Math.floor(position.x / this.chunkSize);
    const chunkY = Math.floor(position.y / this.chunkSize);
    const chunkZ = Math.floor(position.z / this.chunkSize);
    return `${chunkX},${chunkY},${chunkZ}`;
  }

  // Get all chunk keys within radius
  private getActiveChunkKeys(center: Vector3, radius: number): string[] {
    const keys: string[] = [];
    const chunksRadius = Math.ceil(radius / this.chunkSize);

    const centerChunk = {
      x: Math.floor(center.x / this.chunkSize),
      y: Math.floor(center.y / this.chunkSize),
      z: Math.floor(center.z / this.chunkSize)
    };

    for (let x = -chunksRadius; x <= chunksRadius; x++) {
      for (let y = -chunksRadius; y <= chunksRadius; y++) {
        for (let z = -chunksRadius; z <= chunksRadius; z++) {
          keys.push(`${centerChunk.x + x},${centerChunk.y + y},${centerChunk.z + z}`);
        }
      }
    }

    return keys;
  }

  update(shipPosition: Vector3, system: GeneratedSystem): void {
    const activeKeys = this.getActiveChunkKeys(shipPosition, 100000);

    // Load new chunks
    for (const key of activeKeys) {
      if (!this.activeChunks.has(key)) {
        const bodies = this.generateChunk(key, system);
        this.activeChunks.set(key, bodies);
      }
    }

    // Unload distant chunks
    for (const [key, bodies] of this.activeChunks) {
      if (!activeKeys.includes(key)) {
        this.activeChunks.delete(key);
        // Remove bodies from world
      }
    }
  }

  private generateChunk(key: string, system: GeneratedSystem): CelestialBody[] {
    // Parse chunk coordinates
    const [x, y, z] = key.split(',').map(Number);
    const chunkCenter = {
      x: (x + 0.5) * this.chunkSize,
      y: (y + 0.5) * this.chunkSize,
      z: (z + 0.5) * this.chunkSize
    };

    // Generate content for this chunk based on seed + chunk position
    const seed = system.seed ^ hashString(key);
    const rng = new SeededRandom(seed);

    const bodies: CelestialBody[] = [];

    // Chance of asteroid in this chunk
    if (rng.chance(0.1)) {
      const asteroid = new AsteroidFieldGenerator().generateAsteroid(
        {
          center: chunkCenter,
          radius: this.chunkSize / 2,
          density: 0.001,
          velocityRange: [1, 10]
        },
        rng,
        Math.floor(rng.next() * 10000)
      );
      bodies.push(asteroid);
    }

    return bodies;
  }
}
```

---

## Summary

**Procedural Generation:**
- Seeded RNG (deterministic, same seed = same content)
- Star systems (planets, stations, asteroids, derelicts)
- Asteroid fields (clustered distribution, size distribution)
- Debris clouds (Gaussian distribution, high density)
- Derelict ships (exploration targets with backstories)
- Mission objectives (generated from system content)

**Optimization:**
- On-demand generation (only generate what's nearby)
- Chunk-based streaming (load/unload chunks as ship moves)
- Spatial partitioning (octree/chunks for performance)
- Memory management (unload distant content)

**Random Encounters:**
- Distress signals
- Debris fields
- Equipment malfunctions
- Anomalies
- Dynamic events during flight

**Replayability:**
- Different seed = different system
- Infinite variety
- Balanced difficulty
- Interesting scenarios every run

**Player Experience:**
- Discover new systems each playthrough
- Procedurally generated challenges
- Exploration rewards (derelicts, salvage)
- Dynamic mission objectives

**All design documents complete!**
