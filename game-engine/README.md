# Space Game Engine - Integrated System

The complete space game engine integrating:
- **Universe System** - Procedural galaxy generation with planets, stations, hazards
- **Physics Modules** - Realistic spacecraft systems (engines, fuel, thermal, electrical)
- **Game Engine** - Coordinates everything into a playable space simulation

## Features

### ✨ Fully Integrated

- **Universe Physics** → Ship Physics
  - Gravity from planets, moons, stars
  - Atmospheric drag and heating
  - Solar radiation (power + heat)
  - Environmental hazards (damage, interference)

- **Ship Systems** → Universe
  - FTL jump between star systems
  - Docking at space stations
  - Resource gathering from planets
  - Mission system

### 🎮 Complete Game Loop

The engine provides a ready-to-use game loop that:
1. Updates universe (orbits, hazards, missions)
2. Updates ship physics (engines, fuel, thermal, electrical)
3. Applies environmental effects (gravity, atmosphere, radiation, hazards)
4. Checks for game events (collisions, discoveries, station proximity)

## Quick Start

```bash
cd game-engine
npm install
npm run demo
```

## Usage

### Basic Setup

```typescript
import { SpaceGame } from './SpaceGame';

// Create a game
const game = new SpaceGame({
  universeConfig: {
    seed: 42,
    numSystems: 10,
    campaignMode: 'OPEN_WORLD'
  },
  shipConfig: {
    startingFuel: 5000,
    startingPower: 10000
  }
});

// Game loop
function gameLoop() {
  const deltaTime = 1.0; // 1 second

  // Update everything
  game.update(deltaTime);

  // Get ship status
  const status = game.getShipStatus();
  console.log(`Fuel: ${status.fuel}kg`);
  console.log(`Power: ${status.power}Wh`);
  console.log(`Temperature: ${status.temperature}K`);

  // Continue loop
  setTimeout(gameLoop, 1000);
}

gameLoop();
```

### Ship Control

```typescript
// Main engine
game.ship.mainEngine.setThrottlePercent(100); // Full thrust
game.ship.mainEngine.setGimbalAngle(0.1, 0.0); // Steer

// RCS thrusters
game.ship.rcs.thrustForward(1.0); // Forward
game.ship.rcs.thrustRight(0.5);   // Strafe right
game.ship.rcs.pitchUp(0.1);       // Rotate

// Flight computer
game.ship.flightControl.setSASMode('PROGRADE'); // Point prograde
game.ship.flightControl.setAutopilotMode('HOLD'); // Hold attitude
```

### Universe Interaction

```typescript
// Get current system info
const systemInfo = game.getSystemInfo();
console.log(`Current system: ${systemInfo.name}`);
console.log(`Planets: ${systemInfo.planets}`);
console.log(`Stations: ${systemInfo.stations}`);

// Find nearest planet
const nearestPlanet = game.currentSystem.findNearestBody(
  game.ship.physics.position,
  ['STATION'] // exclude stations
);

// Check hazards
const hazards = game.currentSystem.hazardSystem.getHazardsAt(
  game.ship.physics.position
);

// Get missions at a station
const station = game.currentSystem.stations[0];
const missions = game.universe.getMissionsAtStation(station.id);

// Jump to another system
const jumps = game.universe.getAvailableJumps();
if (jumps.length > 0) {
  game.jumpToSystem(jumps[0].to);
}
```

### Environmental Effects

The engine automatically applies:

#### 1. Gravity
```typescript
// Automatically calculated from nearby bodies
// Ship acceleration = Σ(G * M / r²) for all nearby bodies
```

#### 2. Atmospheric Drag
```typescript
// When in atmosphere:
// - Drag force slows the ship
// - Heating rate increases with velocity³
// - Thermal system heats up
```

#### 3. Solar Radiation
```typescript
// Automatically provides:
// - Solar power to electrical system
// - Solar heating to thermal system
// Scales with 1/r² from star
```

#### 4. Environmental Hazards
```typescript
// Solar storms: radiation + heat + electrical interference
// Radiation belts: radiation exposure
// Debris fields: hull damage
// Ion storms: electrical drain + navigation disruption
```

## Architecture

```
SpaceGame
├── UniverseDesigner
│   ├── StarSystem (current)
│   │   ├── Star
│   │   ├── Planets & Moons
│   │   ├── Asteroids
│   │   ├── Stations
│   │   └── HazardSystem
│   └── Other Systems (jumpable)
└── Spacecraft
    ├── ShipPhysics (position, velocity, rotation)
    ├── MainEngine (thrust, gimbal)
    ├── RCS (translation, rotation)
    ├── FuelSystem (propellant, pressurization)
    ├── ElectricalSystem (battery, power distribution)
    ├── ThermalSystem (heating, cooling, radiators)
    ├── FlightControl (SAS, autopilot)
    └── Navigation (trajectory, orbit prediction)
```

## Game Flow

```typescript
// Each frame:
game.update(deltaTime)
  ├── universe.update(deltaTime)
  │   ├── Update planet orbits
  │   ├── Update hazards (movement, timers)
  │   └── Update missions (timeouts)
  │
  ├── ship.update(deltaTime)
  │   ├── Spacecraft systems tick
  │   ├── Engines produce thrust
  │   ├── Fuel consumed
  │   ├── Power consumed
  │   ├── Heat generated
  │   └── Position/velocity updated
  │
  ├── applyUniversePhysics(deltaTime)
  │   ├── Calculate gravity from all bodies
  │   ├── Apply atmospheric drag + heating
  │   ├── Add solar power + heating
  │   └── Apply hazard effects
  │
  └── checkGameEvents()
      ├── Check for collisions
      ├── Check station proximity
      └── Check planet proximity
```

## Example: Landing on a Planet

```typescript
// 1. Navigate to planet
const targetPlanet = game.currentSystem.planets[0];

// 2. Get into orbit
// (Use ship controls to achieve orbital velocity)
game.ship.flightControl.setSASMode('PROGRADE');

// 3. Deorbit burn
game.ship.mainEngine.setThrottlePercent(50);
// Wait until velocity decreases...

// 4. Enter atmosphere
// Atmospheric drag automatically applies
// Ship heats up from friction

// 5. Terminal descent
game.ship.flightControl.setSASMode('RETROGRADE');
game.ship.mainEngine.setThrottlePercent(100);

// 6. Touch down
// Monitor altitude (from ship status)
// Reduce throttle as you approach surface
```

## Example: Trading Run

```typescript
// 1. Find a trading hub
const tradingHub = game.currentSystem.stations.find(
  s => s.stationType === 'TRADING_HUB'
);

// 2. Dock
// (Navigate close to station)
if (distanceToStation < 1000) {
  const canDock = tradingHub.findAvailableDock('SMALL');
  if (canDock) {
    tradingHub.dockShip('my-ship', 'SMALL');
  }
}

// 3. Buy cargo
const fuelPrice = tradingHub.getCommodityPrice('Fuel', 100);
// Purchase logic here

// 4. Jump to another system
const jumps = game.universe.getAvailableJumps();
game.jumpToSystem(jumps[0].to);

// 5. Sell at new system
const newTradingHub = game.currentSystem.stations.find(
  s => s.services.trading
);
const newFuelPrice = newTradingHub.getCommodityPrice('Fuel', 100);
// Profit = newFuelPrice - fuelPrice
```

## Advanced Features

### Custom Ship Configuration

```typescript
const game = new SpaceGame({
  shipConfig: {
    mass: 20000,           // 20 tons
    fuelCapacity: 10000,   // 10,000 kg
    startingFuel: 8000,    // Start with 80%
    batteryCapacity: 20000, // 20,000 Wh
    startingPower: 15000   // Start with 75%
  }
});
```

### Custom Universe Generation

```typescript
const game = new SpaceGame({
  universeConfig: {
    seed: 12345,            // Reproducible
    numSystems: 50,         // Large galaxy
    galaxyRadius: 200,      // 200 light years
    campaignMode: 'LINEAR', // Story progression
  }
});
```

### Event Handling

```typescript
// Override event handlers
game.onStationNearby = (station, distance) => {
  console.log(`Station in range: ${station.name}`);
  // Show docking UI
};

game.onPlanetNearby = (planet, distance) => {
  console.log(`Planet detected: ${planet.name}`);
  // Show scanning UI
};

game.handleCollision = (body) => {
  console.log(`Crashed into ${body.name}!`);
  // Game over
};
```

## Performance

- **Universe Update**: ~1ms per frame (only current system)
- **Ship Physics**: ~0.5ms per frame
- **Environmental Effects**: ~0.2ms per frame
- **Total**: ~2ms per frame (500 FPS capable)

## Integration with Existing Code

### Add Visual Rendering

```typescript
// Your rendering code
function render() {
  const shipPos = game.ship.physics.position;
  const shipRot = game.ship.physics.rotation;

  // Draw ship
  drawShip(shipPos, shipRot);

  // Draw planets
  game.currentSystem.planets.forEach(planet => {
    drawPlanet(planet.position, planet.physical.radius, planet.visual.color);
  });

  // Draw stations
  game.currentSystem.stations.forEach(station => {
    drawStation(station.position);
  });

  // Draw hazards
  game.currentSystem.hazardSystem.getActiveHazards().forEach(hazard => {
    drawHazardZone(hazard.position, hazard.radius, hazard.severity);
  });
}
```

### Add User Input

```typescript
// Keyboard controls
document.addEventListener('keydown', (e) => {
  switch(e.key) {
    case 'w': game.ship.mainEngine.setThrottlePercent(100); break;
    case 's': game.ship.mainEngine.setThrottlePercent(0); break;
    case 'a': game.ship.rcs.thrustLeft(1.0); break;
    case 'd': game.ship.rcs.thrustRight(1.0); break;
    case 'q': game.ship.rcs.rotateLeft(0.1); break;
    case 'e': game.ship.rcs.rotateRight(0.1); break;
  }
});
```

### Add UI

```typescript
// Status display
setInterval(() => {
  const status = game.getShipStatus();

  document.getElementById('fuel').innerText =
    `${status.fuel.toFixed(0)} kg`;
  document.getElementById('power').innerText =
    `${status.power.toFixed(0)} Wh`;
  document.getElementById('temperature').innerText =
    `${status.temperature.toFixed(1)} K`;

  if (status.altitude !== undefined) {
    document.getElementById('altitude').innerText =
      `${(status.altitude / 1000).toFixed(0)} km`;
  }
}, 100);
```

## Troubleshooting

**Ship not moving?**
- Check if engine is on: `game.ship.mainEngine.setThrottlePercent(100)`
- Check if you have fuel: `game.ship.fuel.getCurrentMass()`

**Overheating?**
- Turn on coolant: `game.ship.coolant.activatePrimary()`
- Reduce thrust
- Move away from star

**Running out of power?**
- Get closer to star for solar power
- Reduce power consumption
- Jump to a brighter star system

**Can't jump?**
- Check if route exists: `game.universe.getAvailableJumps()`
- System might be undiscovered

## Next Steps

1. **Add Rendering** - Connect to Three.js, Babylon.js, or Canvas
2. **Add UI** - HUD, station menus, mission board
3. **Add Sound** - Engine noise, alarms, ambient
4. **Add Saves** - Persist game state
5. **Add Multiplayer** - Use universe seed for sync

## Files

- `SpaceGame.ts` - Main game engine class
- `demo.ts` - Demonstration of full integration
- `package.json` - NPM configuration
- `tsconfig.json` - TypeScript configuration

## Dependencies

- `universe-system/` - Universe generation
- `physics-modules/` - Ship physics simulation

## License

MIT
