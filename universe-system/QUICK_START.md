# Quick Start Guide

## Installation

1. Navigate to the universe-system directory:
```bash
cd universe-system
```

2. Install dependencies:
```bash
npm install
```

3. Build the project:
```bash
npm run build
```

## Running the Demos

### Option 1: TypeScript (Development)
```bash
npm run demo
```

### Option 2: Compiled JavaScript
```bash
npm run build
npm test
```

## Your First Universe

Create a file `my-universe.ts`:

```typescript
import { createUniverse } from './src';

// Create a small universe
const universe = createUniverse({
  seed: 42,
  numSystems: 5,
  campaignMode: 'SANDBOX'
});

// Get current system
const system = universe.getCurrentSystem();
console.log(`Welcome to ${system?.name}!`);

// List planets
system?.planets.forEach(planet => {
  console.log(`- ${planet.name} (${planet.planetClass})`);
});
```

Run it:
```bash
ts-node my-universe.ts
```

## Integration with Existing Physics Engine

The universe system provides celestial bodies with standard physics properties that integrate with your existing physics modules.

### Example Integration

```typescript
import { createUniverse } from './universe-system';
// Import your existing physics modules
// import { OrbitalMechanics } from './physics-modules/OrbitalMechanics';
// import { ThermalDynamics } from './physics-modules/ThermalDynamics';

const universe = createUniverse();
const system = universe.getCurrentSystem();

// Ship position in the universe
const shipPosition = { x: 0, y: 0, z: 0 };

// 1. Gravity Calculations
// Find nearby bodies
const nearbyBodies = system?.findBodiesInRadius(shipPosition, 1e9) || [];

// Calculate total gravitational force
let totalForce = { x: 0, y: 0, z: 0 };
for (const body of nearbyBodies) {
  const force = body.gravitationalForce({
    position: shipPosition,
    physical: { mass: 1000 } // Ship mass
  } as any);

  totalForce.x += force.x;
  totalForce.y += force.y;
  totalForce.z += force.z;
}

// 2. Atmospheric Effects
// Check if ship is in atmosphere
const nearestBody = system?.findNearestBody(shipPosition);
if (nearestBody?.isInAtmosphere(shipPosition)) {
  const density = nearestBody.getAtmosphericDensity(shipPosition);
  console.log(`Atmospheric density: ${density} kg/m³`);

  // Apply drag force using your existing atmospheric module
  // const drag = AtmosphericDrag.calculate(density, velocity, crossSection);
}

// 3. Radiation and Heat
// Get solar radiation from the star
if (system) {
  const distanceFromStar = Math.sqrt(
    Math.pow(shipPosition.x - system.star.position.x, 2) +
    Math.pow(shipPosition.y - system.star.position.y, 2) +
    Math.pow(shipPosition.z - system.star.position.z, 2)
  );

  const radiation = system.star.getRadiationAt(distanceFromStar);
  console.log(`Solar radiation: ${radiation} W/m²`);

  // Apply to your thermal dynamics module
  // ThermalDynamics.addExternalHeat(radiation * surfaceArea);
}

// 4. Environmental Hazards
// Check for hazards
const hazards = system?.hazardSystem.getHazardsAt(shipPosition) || [];
if (hazards.length > 0) {
  const effects = system.hazardSystem.getCombinedEffectsAt(shipPosition, 1.0);

  if (effects.hullDamagePerSecond) {
    // Apply hull damage
    console.log(`Taking ${effects.hullDamagePerSecond} damage/sec`);
  }

  if (effects.radiationPerSecond) {
    // Accumulate radiation exposure
    console.log(`Radiation: ${effects.radiationPerSecond} rads/sec`);
  }
}

// 5. Navigation
// Find nearest station for docking
const stations = system?.stations || [];
let nearestStation = null;
let minDistance = Infinity;

for (const station of stations) {
  const dx = station.position.x - shipPosition.x;
  const dy = station.position.y - shipPosition.y;
  const dz = station.position.z - shipPosition.z;
  const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);

  if (distance < minDistance) {
    minDistance = distance;
    nearestStation = station;
  }
}

if (nearestStation && minDistance < 10000) {
  console.log(`Nearest station: ${nearestStation.name} (${minDistance}m)`);
}

// 6. Update Loop
// In your game loop:
function gameLoop(deltaTime: number) {
  // Update universe (planets orbit, hazards move, etc.)
  universe.update(deltaTime);

  // Your existing physics updates
  // ship.update(deltaTime);
  // orbitalMechanics.update(deltaTime);
  // thermalDynamics.update(deltaTime);
}
```

## Common Use Cases

### 1. Landing on a Planet

```typescript
const planet = system?.planets[0];

if (planet) {
  // Get surface position
  const landingPosition = {
    x: planet.position.x + planet.physical.radius,
    y: planet.position.y,
    z: planet.position.z
  };

  // Check if in atmosphere
  const inAtmosphere = planet.isInAtmosphere(landingPosition);
  console.log(`In atmosphere: ${inAtmosphere}`);

  // Get surface gravity
  const gravity = planet.physical.surfaceGravity;
  console.log(`Surface gravity: ${gravity} m/s²`);

  // Get temperature
  console.log(`Surface temperature: ${planet.surfaceTemperature}K`);
}
```

### 2. Mining Asteroids

```typescript
const asteroids = system?.asteroids || [];

// Find valuable asteroids
const metalAsteroids = asteroids.filter(
  ast => ast.composition === 'METAL' && ast.mineralWealth > 0.7
);

console.log(`Found ${metalAsteroids.length} valuable metal asteroids`);

metalAsteroids.forEach(ast => {
  console.log(`${ast.name}: ${(ast.mineralWealth * 100).toFixed(0)}% mineral content`);
});
```

### 3. Trading at Stations

```typescript
const tradingHub = system?.stations.find(
  s => s.stationType === 'TRADING_HUB'
);

if (tradingHub) {
  // Check if trading is available
  if (tradingHub.services.trading) {
    // Get commodity prices
    const fuelPrice = tradingHub.getCommodityPrice('Fuel', 100);
    const metalPrice = tradingHub.getCommodityPrice('Metals', 200);

    console.log(`Fuel: ${fuelPrice} credits`);
    console.log(`Metals: ${metalPrice} credits`);

    // Check what the station wants to buy/sell
    console.log(`Buying: ${tradingHub.economy.demandGoods.join(', ')}`);
    console.log(`Selling: ${tradingHub.economy.supplyGoods.join(', ')}`);
  }
}
```

### 4. Exploring Unknown Space

```typescript
// Generate a new system on the fly
import { generateStarSystem } from './universe-system';

const newSystem = generateStarSystem('Unknown System', {
  seed: Math.random() * 1000000,
  civilizationLevel: 0, // Uninhabited
  allowHazards: true
});

console.log(`Discovered: ${newSystem.name}`);
console.log(`Star type: ${newSystem.star.starClass}`);
console.log(`Planets: ${newSystem.planets.length}`);
console.log(`Habitable planets: ${newSystem.getHabitablePlanets().length}`);
```

### 5. Campaign Progression

```typescript
// Create a universe with difficulty scaling
const campaignUniverse = createUniverse({
  numSystems: 20,
  campaignMode: 'LINEAR',
  difficultyProgression: true
});

// Start at Sol
campaignUniverse.jumpToSystem('system-0');

// Progress through the universe
const jumps = campaignUniverse.getAvailableJumps();
console.log(`${jumps.length} systems accessible from starting position`);

// Complete missions to unlock new systems
const currentSystem = campaignUniverse.getCurrentSystem();
const stations = currentSystem?.stations || [];

for (const station of stations) {
  const missions = campaignUniverse.getMissionsAtStation(station.id);
  console.log(`${station.name}: ${missions.length} missions`);
}
```

## Performance Tips

1. **Only update current system**:
   ```typescript
   // Good: Only updates active system
   universe.update(deltaTime);

   // Bad: Don't manually update all systems
   // for (const system of universe.systems.values()) {
   //   system.update(deltaTime);
   // }
   ```

2. **Use spatial queries efficiently**:
   ```typescript
   // Good: Only check nearby bodies
   const nearby = system.findBodiesInRadius(position, 1e9);

   // Bad: Don't iterate all bodies
   // const all = system.getAllBodies();
   ```

3. **Cache calculations**:
   ```typescript
   // Calculate once per frame
   const nearestBody = system.findNearestBody(shipPosition);

   // Reuse the result
   if (nearestBody) {
     const gravity = nearestBody.physical.surfaceGravity;
     const atmosphere = nearestBody.isInAtmosphere(shipPosition);
   }
   ```

4. **Update hazards selectively**:
   ```typescript
   // Hazards auto-update with universe.update()
   // Only query when needed
   if (hazardCheckTimer > 1.0) {
     const hazards = system.hazardSystem.getHazardsAt(shipPosition);
     hazardCheckTimer = 0;
   }
   ```

## Next Steps

1. Read the full [README.md](./README.md) for detailed API documentation
2. Explore [examples.ts](./src/examples.ts) for more usage patterns
3. Check individual module files for advanced features
4. Integrate with your ship physics and flight control systems

## Troubleshooting

**Issue**: TypeScript errors about missing types

**Solution**: Make sure you have TypeScript installed:
```bash
npm install -D typescript @types/node
```

**Issue**: "Cannot find module" errors

**Solution**: Build the project first:
```bash
npm run build
```

**Issue**: Examples don't run

**Solution**: Install ts-node for development:
```bash
npm install -D ts-node
```

## Support

For questions or issues, check:
- README.md for API documentation
- Source code comments for implementation details
- Examples.ts for usage patterns
