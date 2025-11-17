# Universe System

A comprehensive procedural universe generation system for space games. Generate entire galaxies with star systems, planets, moons, asteroids, space stations, environmental hazards, missions, and more.

## Features

### 🌟 **Star Systems**
- **7 Star Classes**: O, B, A, F, G, K, M (plus neutron stars and black holes)
- **Realistic physics**: Mass, luminosity, temperature, habitable zones
- **Orbital mechanics**: Full Keplerian orbits for all bodies

### 🌍 **Planets & Moons**
- **8 Planet Classes**:
  - Gas Giant (Jupiter-like)
  - Ice Giant (Neptune-like)
  - Terrestrial (Earth-like)
  - Desert (Mars-like)
  - Ice (Europa-like)
  - Lava (Io-like)
  - Ocean (Water worlds)
  - Toxic (Venus-like)
- **Procedural generation**: Unique planets every time
- **Realistic properties**: Mass, radius, gravity, atmosphere, temperature
- **Resource system**: Planets contain various resources (water, metals, rare earths, etc.)
- **Moon generation**: Planets get appropriate numbers of moons

### 🛰️ **Space Stations**
- **9 Station Types**:
  - Orbital Stations
  - Trading Hubs
  - Military Bases
  - Research Facilities
  - Mining Platforms
  - Shipyards
  - Fuel Depots
  - Relay Stations
  - Deep Space Outposts
- **7 Factions**: United Earth, Mars Federation, Belt Alliance, Outer Colonies, Independent, Corporate, Pirate
- **Services**: Refueling, repairs, trading, missions, ship upgrades, medical
- **Docking system**: Multiple port sizes (small, medium, large, capital)
- **Dynamic economy**: Commodity prices, supply/demand, wealth levels

### ⚠️ **Environmental Hazards**
- **Solar Storms**: Radiation bursts from stars
- **Radiation Belts**: Van Allen-like zones around planets
- **Debris Fields**: Dangerous space junk
- **Ion Storms**: Moving electromagnetic chaos
- **Gravity Wells**: Dangerous gravity gradients
- **Magnetic Anomalies**: Navigation disruption
- **5 Severity Levels**: Low to Lethal
- **Dynamic effects**: Hull damage, radiation, heat, electrical interference, navigation disruption

### 🎮 **Game Systems**
- **Universe Management**: Multiple star systems with jump routes
- **Mission System**: Delivery, combat, exploration, rescue, mining, escort missions
- **Progression**: Discovery, reputation, credits
- **Campaign Modes**: Sandbox, Linear, Open World
- **FTL Travel**: Jump between star systems
- **Difficulty Scaling**: Systems get harder with distance from core

## Installation

```typescript
import { createUniverse, UniverseDesigner } from './universe-system';
```

## Quick Start

### Create a Simple Universe

```typescript
import { createUniverse } from './universe-system';

// Create a universe with default settings
const universe = createUniverse({
  seed: 12345,
  numSystems: 10,
  galaxyRadius: 100, // light years
  campaignMode: 'OPEN_WORLD'
});

// Get statistics
const stats = universe.getStatistics();
console.log(`Generated ${stats.totalSystems} systems with ${stats.totalPlanets} planets`);

// Get current system
const system = universe.getCurrentSystem();
console.log(`Starting in ${system.name}`);
```

### Create a Single Star System

```typescript
import { generateStarSystem, StarClass } from './universe-system';

// Generate a Sol-like system
const solSystem = generateStarSystem('Sol', {
  seed: 1,
  starClass: StarClass.G,
  numPlanets: { min: 8, max: 8 },
  allowAsteroidBelt: true,
  allowStations: true,
  civilizationLevel: 8
});

// Explore the system
console.log(`Star: ${solSystem.star.name} (${solSystem.star.starClass})`);
console.log(`Planets: ${solSystem.planets.length}`);
console.log(`Moons: ${solSystem.moons.length}`);
console.log(`Stations: ${solSystem.stations.length}`);
```

## Usage Examples

### Example 1: Exploring Planets

```typescript
const system = universe.getCurrentSystem();

// List all planets
system.planets.forEach(planet => {
  console.log(`${planet.name}:`);
  console.log(`  Class: ${planet.planetClass}`);
  console.log(`  Mass: ${planet.physical.mass / 5.972e24} Earth masses`);
  console.log(`  Temperature: ${planet.surfaceTemperature}K`);
  console.log(`  Habitable: ${planet.isHabitable}`);
  console.log(`  Moons: ${planet.children.length}`);

  // Check resources
  if (planet.resources.size > 0) {
    console.log(`  Resources:`);
    planet.resources.forEach((abundance, resource) => {
      console.log(`    ${resource}: ${(abundance * 100).toFixed(0)}%`);
    });
  }
});
```

### Example 2: Finding Habitable Planets

```typescript
const habitablePlanets = system.getHabitablePlanets();

console.log(`Found ${habitablePlanets.length} habitable planets:`);
habitablePlanets.forEach(planet => {
  const orbitAU = planet.orbital.semiMajorAxis / 1.496e11;
  console.log(`  ${planet.name} - ${orbitAU.toFixed(2)} AU`);
});
```

### Example 3: Docking at a Station

```typescript
const stations = system.stations;

if (stations.length > 0) {
  const station = stations[0];

  console.log(`Approaching ${station.name}`);
  console.log(`Type: ${station.stationType}`);
  console.log(`Faction: ${station.faction}`);

  // Find available docking port
  const port = station.findAvailableDock('SMALL');

  if (port) {
    // Dock ship
    const success = station.dockShip('my-ship-id', 'SMALL');
    if (success) {
      console.log('Docked successfully!');

      // Check available services
      if (station.services.refueling) console.log('- Refueling available');
      if (station.services.repairs) console.log('- Repairs available');
      if (station.services.trading) console.log('- Trading available');

      // Get missions
      const missions = universe.getMissionsAtStation(station.id);
      console.log(`${missions.length} missions available`);
    }
  } else {
    console.log('No docking ports available');
  }
}
```

### Example 4: Checking for Hazards

```typescript
// Check hazards at current position
const playerPos = { x: 0, y: 0, z: 0 };
const hazards = system.hazardSystem.getHazardsAt(playerPos);

if (hazards.length > 0) {
  console.log('WARNING: Hazards detected!');
  hazards.forEach(hazard => {
    console.log(`  ${hazard.name} (${hazard.type})`);
    console.log(`  Severity: ${hazard.severity}/5`);
  });

  // Get combined effects
  const effects = system.hazardSystem.getCombinedEffectsAt(playerPos, 1.0);
  if (effects.hullDamagePerSecond) {
    console.log(`  Hull damage: ${effects.hullDamagePerSecond}/s`);
  }
  if (effects.radiationPerSecond) {
    console.log(`  Radiation: ${effects.radiationPerSecond}/s`);
  }
}
```

### Example 5: FTL Jump to Another System

```typescript
// Get available jump routes
const jumpRoutes = universe.getAvailableJumps();

console.log('Available destinations:');
jumpRoutes.forEach(route => {
  const targetSystem = universe.systems.get(route.to);
  console.log(`  ${targetSystem.name}`);
  console.log(`    Distance: ${route.distance.toFixed(2)} light years`);
  console.log(`    Fuel cost: ${route.fuelCost} units`);
});

// Jump to first available system
if (jumpRoutes.length > 0) {
  const result = universe.jumpToSystem(jumpRoutes[0].to);
  console.log(result.message);
}
```

### Example 6: Mission System

```typescript
// Find missions at a station
const station = system.stations[0];
const missions = universe.getMissionsAtStation(station.id);

console.log(`Missions at ${station.name}:`);
missions.forEach(mission => {
  console.log(`  [${mission.type}] ${mission.title}`);
  console.log(`    ${mission.description}`);
  console.log(`    Reward: ${mission.reward} credits`);
  console.log(`    Difficulty: ${mission.difficulty}/10`);
});

// Accept a mission
if (missions.length > 0) {
  const mission = missions[0];
  universe.acceptMission(mission.id);
  console.log(`Accepted: ${mission.title}`);

  // Later... complete the mission
  const result = universe.completeMission(mission.id);
  if (result.success) {
    console.log(`Mission complete! Earned ${result.reward} credits`);
  }
}
```

### Example 7: Time Progression

```typescript
// Update universe simulation
const deltaTime = 60; // 1 minute

universe.update(deltaTime);

// Planets move in their orbits
// Stations orbit their parent bodies
// Hazards update and move
// Mission timers count down
```

## Configuration Options

### UniverseConfig

```typescript
interface UniverseConfig {
  seed?: number;              // Random seed for reproducibility
  numSystems?: number;        // Number of star systems (default: 10)
  galaxyRadius?: number;      // Galaxy size in light years (default: 100)
  campaignMode?: 'SANDBOX' | 'LINEAR' | 'OPEN_WORLD';
  startingSystem?: string;    // Starting system ID
  difficultyProgression?: boolean; // Scale difficulty with distance
}
```

### StarSystemConfig

```typescript
interface StarSystemConfig {
  seed?: number;
  starClass?: StarClass;      // Force specific star class
  numPlanets?: { min: number; max: number };
  allowAsteroidBelt?: boolean;
  allowStations?: boolean;
  allowHazards?: boolean;
  civilizationLevel?: number; // 0-10 (0=uninhabited, 10=high tech)
  position?: Vector3;         // Position in galaxy
}
```

## Architecture

```
UniverseDesigner
├── StarSystem 1
│   ├── Star
│   ├── Planets
│   │   └── Moons
│   ├── Asteroids
│   ├── Stations
│   └── HazardSystem
│       ├── Radiation Belts
│       ├── Debris Fields
│       └── Ion Storms
├── StarSystem 2
│   └── ...
└── JumpRoutes
```

## Physics & Realism

The system implements realistic physics:

- **Orbital Mechanics**: Keplerian orbits with semi-major axis, eccentricity, inclination
- **Gravitational Physics**: N-body gravitational forces
- **Stellar Radiation**: Inverse square law for solar radiation
- **Atmospheric Physics**: Exponential atmosphere density model
- **Thermal Dynamics**: Temperature calculation based on stellar flux and greenhouse effect
- **Tsiolkovsky Rocket Equation**: For delta-v and fuel consumption (if integrated with ship physics)

## Performance Considerations

- **Selective Updates**: Only the current system is updated each frame
- **Spatial Partitioning**: Use `findBodiesInRadius()` for efficient proximity queries
- **Lazy Loading**: Systems can be generated on-demand
- **Seeded Generation**: Same seed always produces same universe (reproducible)

## Integration with Existing Physics

The universe system is designed to work with your existing physics engine. All bodies have:

- `position: Vector3` - 3D position in meters
- `velocity: Vector3` - 3D velocity in m/s
- `physical.mass` - Mass in kg
- `physical.radius` - Radius in meters
- `gravitationalForce(other)` - Calculate forces between bodies

You can integrate with your existing:
- Quaternion rotation system
- Orbital mechanics module
- Thermal dynamics
- Navigation systems

## Examples

Run the included examples:

```bash
# If using TypeScript directly
ts-node universe-system/src/examples.ts

# Or compile and run
tsc universe-system/src/examples.ts
node universe-system/src/examples.js
```

This will run three demos:
1. **Universe Playthrough** - Full universe exploration
2. **Custom System** - Sol-like system creation
3. **Station Trading** - Economy and trading demonstration

## File Structure

```
universe-system/
├── src/
│   ├── CelestialBody.ts      # Base classes for all celestial objects
│   ├── PlanetGenerator.ts    # Procedural planet/moon generation
│   ├── StationGenerator.ts   # Space station generation
│   ├── HazardSystem.ts       # Environmental hazards
│   ├── StarSystem.ts         # Star system management
│   ├── UniverseDesigner.ts   # Universe manager and game coordinator
│   ├── examples.ts           # Usage examples and demos
│   └── index.ts              # Main exports
└── README.md                 # This file
```

## API Reference

### Main Classes

- **`UniverseDesigner`** - Main universe manager
- **`StarSystem`** - Individual star system with all bodies
- **`CelestialBody`** - Base class for all space objects
- **`Star`** - Star with luminosity and radiation
- **`Planet`** - Planet with atmosphere and resources
- **`Moon`** - Natural satellite
- **`Asteroid`** - Small rocky body
- **`SpaceStation`** - Artificial structure with services
- **`HazardSystem`** - Manages environmental hazards

### Key Methods

- `createUniverse(config)` - Create a new universe
- `generateStarSystem(name, config)` - Create a single star system
- `universe.update(deltaTime)` - Update simulation
- `universe.jumpToSystem(id)` - FTL travel
- `universe.getCurrentSystem()` - Get current star system
- `system.findNearestBody(position)` - Find closest body
- `system.getHabitablePlanets()` - Find Earth-like worlds
- `hazardSystem.getHazardsAt(position)` - Check for dangers

## Future Enhancements

Potential additions:
- [ ] Binary/trinary star systems
- [ ] Black holes and neutron stars
- [ ] Nebulae and gas clouds
- [ ] Wormholes for fast travel
- [ ] Derelict ships and ancient artifacts
- [ ] Dynamic economy simulation
- [ ] Faction warfare and territory control
- [ ] Procedural quest chains
- [ ] Fleet management
- [ ] Colony building

## License

Part of the Project Management Console / Space Game project.

## Credits

Created for a comprehensive space flight simulator with realistic physics and procedural generation.
