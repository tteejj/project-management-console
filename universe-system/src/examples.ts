/**
 * examples.ts
 * Example configurations and usage demonstrations
 */

import { createUniverse, UniverseDesigner, UniverseConfig } from './UniverseDesigner';
import { generateStarSystem, StarSystem } from './StarSystem';
import { StarClass } from './CelestialBody';

/**
 * Example 1: Small sandbox universe for testing
 */
export function createSandboxUniverse(): UniverseDesigner {
  const config: UniverseConfig = {
    seed: 12345,
    numSystems: 5,
    galaxyRadius: 20, // light years
    campaignMode: 'SANDBOX',
    difficultyProgression: false
  };

  return createUniverse(config);
}

/**
 * Example 2: Large open world universe
 */
export function createOpenWorldUniverse(): UniverseDesigner {
  const config: UniverseConfig = {
    seed: 67890,
    numSystems: 50,
    galaxyRadius: 200,
    campaignMode: 'OPEN_WORLD',
    difficultyProgression: true
  };

  return createUniverse(config);
}

/**
 * Example 3: Linear campaign universe
 */
export function createCampaignUniverse(): UniverseDesigner {
  const config: UniverseConfig = {
    seed: 11111,
    numSystems: 15,
    galaxyRadius: 50,
    campaignMode: 'LINEAR',
    difficultyProgression: true,
    startingSystem: 'system-0' // Sol equivalent
  };

  return createUniverse(config);
}

/**
 * Example 4: Single custom star system
 */
export function createSolSystem(): StarSystem {
  return generateStarSystem('Sol', {
    seed: 1,
    starClass: StarClass.G,
    numPlanets: { min: 8, max: 8 }, // Exactly 8 planets
    allowAsteroidBelt: true,
    allowStations: true,
    allowHazards: true,
    civilizationLevel: 8
  });
}

/**
 * Example 5: Dangerous frontier system
 */
export function createFrontierSystem(): StarSystem {
  return generateStarSystem('Frontier Outpost', {
    seed: 99999,
    starClass: StarClass.M, // Red dwarf
    numPlanets: { min: 3, max: 6 },
    allowAsteroidBelt: true,
    allowStations: true,
    allowHazards: true,
    civilizationLevel: 2 // Low tech
  });
}

/**
 * Example 6: High-tech core world system
 */
export function createCoreWorldSystem(): StarSystem {
  return generateStarSystem('Core Prime', {
    seed: 55555,
    starClass: StarClass.F, // Bright star
    numPlanets: { min: 5, max: 10 },
    allowAsteroidBelt: true,
    allowStations: true,
    allowHazards: false, // Core systems are safer
    civilizationLevel: 10 // Maximum tech
  });
}

/**
 * Demo: Full universe playthrough example
 */
export function demoUniversePlaythrough(): void {
  console.log('=== UNIVERSE GENERATION DEMO ===\n');

  // Create universe
  const universe = createSandboxUniverse();
  const stats = universe.getStatistics();

  console.log('Universe Statistics:');
  console.log(`- Total Systems: ${stats.totalSystems}`);
  console.log(`- Total Planets: ${stats.totalPlanets}`);
  console.log(`- Total Moons: ${stats.totalMoons}`);
  console.log(`- Total Stations: ${stats.totalStations}`);
  console.log(`- Total Asteroids: ${stats.totalAsteroids}`);
  console.log(`- Habitable Planets: ${stats.habitablePlanets}`);
  console.log(`- Available Missions: ${stats.availableMissions}\n`);

  // Get current system
  const currentSystem = universe.getCurrentSystem();
  if (!currentSystem) return;

  console.log(`Current System: ${currentSystem.name}`);
  console.log(`- Star: ${currentSystem.star.name} (${currentSystem.star.starClass})`);
  console.log(`- Planets: ${currentSystem.planets.length}`);
  console.log(`- Moons: ${currentSystem.moons.length}`);
  console.log(`- Stations: ${currentSystem.stations.length}`);
  console.log(`- Asteroids: ${currentSystem.asteroids.length}\n`);

  // List planets
  console.log('Planets:');
  currentSystem.planets.forEach((planet, i) => {
    console.log(`  ${i + 1}. ${planet.name}`);
    console.log(`     Class: ${planet.planetClass}`);
    console.log(`     Mass: ${(planet.physical.mass / 5.972e24).toFixed(2)} Earth masses`);
    console.log(`     Radius: ${(planet.physical.radius / 6.371e6).toFixed(2)} Earth radii`);
    console.log(`     Temperature: ${planet.surfaceTemperature.toFixed(0)}K`);
    console.log(`     Habitable: ${planet.isHabitable ? 'Yes' : 'No'}`);
    console.log(`     Moons: ${planet.children.length}`);
    if (planet.resources.size > 0) {
      console.log(`     Resources: ${Array.from(planet.resources.keys()).join(', ')}`);
    }
    console.log('');
  });

  // List stations
  if (currentSystem.stations.length > 0) {
    console.log('Space Stations:');
    currentSystem.stations.forEach((station, i) => {
      console.log(`  ${i + 1}. ${station.name}`);
      console.log(`     Type: ${station.stationType}`);
      console.log(`     Faction: ${station.faction}`);
      console.log(`     Population: ${station.population.toLocaleString()}`);
      console.log(`     Docking Ports: ${station.dockingPorts.length}`);
      console.log(`     Services: ${Object.entries(station.services)
        .filter(([_, v]) => v)
        .map(([k]) => k)
        .join(', ')}`);

      // Show missions at this station
      const missions = universe.getMissionsAtStation(station.id);
      if (missions.length > 0) {
        console.log(`     Missions: ${missions.length}`);
        missions.forEach(m => {
          console.log(`       - [${m.type}] ${m.title} (${m.reward} credits, difficulty ${m.difficulty})`);
        });
      }
      console.log('');
    });
  }

  // List available jump routes
  console.log('Available Jump Routes:');
  const jumpRoutes = universe.getAvailableJumps();
  jumpRoutes.forEach(route => {
    const targetSystem = universe.systems.get(route.to);
    console.log(`  - ${targetSystem?.name || route.to}`);
    console.log(`    Distance: ${route.distance.toFixed(2)} LY`);
    console.log(`    Fuel Cost: ${route.fuelCost.toFixed(0)} units`);
    console.log(`    Discovered: ${route.discovered ? 'Yes' : 'No'}`);
  });
  console.log('');

  // Show hazards
  const hazards = currentSystem.hazardSystem.getActiveHazards();
  if (hazards.length > 0) {
    console.log('Active Hazards:');
    hazards.forEach(hazard => {
      console.log(`  - ${hazard.name} (${hazard.type})`);
      console.log(`    Severity: ${hazard.severity}/5`);
      console.log(`    Radius: ${(hazard.radius / 1000).toFixed(0)} km`);
    });
    console.log('');
  }

  // Simulate time progression
  console.log('=== SIMULATING TIME PROGRESSION ===\n');
  const deltaTime = 3600; // 1 hour
  console.log('Updating universe for 1 hour...');
  universe.update(deltaTime);
  console.log('Universe updated.\n');

  // Simulate jumping to another system
  if (jumpRoutes.length > 0) {
    console.log('=== JUMPING TO ANOTHER SYSTEM ===\n');
    const targetRoute = jumpRoutes[0];
    const result = universe.jumpToSystem(targetRoute.to);

    console.log(result.message);
    console.log(`Success: ${result.success}\n`);

    if (result.success) {
      const newSystem = universe.getCurrentSystem();
      if (newSystem) {
        console.log(`Now in: ${newSystem.name}`);
        console.log(`Planets: ${newSystem.planets.length}`);
        console.log(`Stations: ${newSystem.stations.length}\n`);
      }
    }
  }

  // Game state
  console.log('=== GAME STATE ===');
  console.log(`Credits: ${universe.gameState.credits}`);
  console.log(`Systems Discovered: ${universe.gameState.discoveredSystems.size}`);
  console.log(`Systems Visited: ${universe.gameState.visitedSystems.size}`);
  console.log(`Missions Completed: ${universe.gameState.completedMissions.length}`);
  console.log('');
}

/**
 * Demo: Custom system exploration
 */
export function demoCustomSystem(): void {
  console.log('=== CUSTOM SYSTEM DEMO ===\n');

  const system = createSolSystem();

  console.log(`System: ${system.name}`);
  console.log(`Star: ${system.star.starClass} class`);
  console.log(`Luminosity: ${(system.star.luminosity / 3.828e26).toFixed(2)} solar luminosities`);
  console.log(`Temperature: ${system.star.temperature}K\n`);

  // Habitable zone
  const habitableZone = system.star.getHabitableZone();
  console.log('Habitable Zone:');
  console.log(`  Inner: ${(habitableZone.inner / 1.496e11).toFixed(2)} AU`);
  console.log(`  Outer: ${(habitableZone.outer / 1.496e11).toFixed(2)} AU\n`);

  // Find habitable planets
  const habitablePlanets = system.getHabitablePlanets();
  console.log(`Habitable Planets: ${habitablePlanets.length}`);
  habitablePlanets.forEach(planet => {
    const orbitAU = planet.orbital!.semiMajorAxis / 1.496e11;
    console.log(`  - ${planet.name}`);
    console.log(`    Orbit: ${orbitAU.toFixed(2)} AU`);
    console.log(`    Temperature: ${planet.surfaceTemperature.toFixed(0)}K (${(planet.surfaceTemperature - 273).toFixed(0)}°C)`);
    console.log(`    Atmosphere: ${planet.physical.atmospherePressure?.toFixed(0)} Pa`);
    console.log(`    Gravity: ${planet.physical.surfaceGravity.toFixed(2)} m/s²`);
  });
  console.log('');
}

/**
 * Demo: Station and trading example
 */
export function demoStationTrading(): void {
  console.log('=== STATION TRADING DEMO ===\n');

  const system = createCoreWorldSystem();

  if (system.stations.length === 0) {
    console.log('No stations in this system.');
    return;
  }

  const station = system.stations[0];

  console.log(`Station: ${station.name}`);
  console.log(`Type: ${station.stationType}`);
  console.log(`Faction: ${station.faction}`);
  console.log(`Population: ${station.population.toLocaleString()}\n`);

  console.log('Services:');
  Object.entries(station.services).forEach(([service, available]) => {
    console.log(`  ${service}: ${available ? 'Available' : 'Not Available'}`);
  });
  console.log('');

  console.log('Commodity Prices:');
  const commodities = ['Fuel', 'Food', 'Metals', 'Electronics'];
  commodities.forEach(commodity => {
    const basePrice = 100; // Example base price
    const price = station.getCommodityPrice(commodity, basePrice);
    console.log(`  ${commodity}: ${price.toFixed(2)} credits`);
  });
  console.log('');

  console.log('Economy:');
  console.log(`  Wealth Level: ${(station.economy.wealthLevel * 100).toFixed(0)}%`);
  console.log(`  Trade Volume: ${station.economy.tradeVolume.toLocaleString()} credits/day`);
  console.log(`  Supply: ${station.economy.supplyGoods.join(', ')}`);
  console.log(`  Demand: ${station.economy.demandGoods.join(', ')}`);
  console.log('');

  console.log('Docking:');
  console.log(`  Total Ports: ${station.dockingPorts.length}`);
  const portCounts = station.dockingPorts.reduce((acc, port) => {
    acc[port.type] = (acc[port.type] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);
  Object.entries(portCounts).forEach(([type, count]) => {
    console.log(`  ${type}: ${count}`);
  });
}

// Run all demos if this file is executed directly
if (require.main === module) {
  console.log('Running Universe System Demos...\n');
  console.log('===============================================\n');

  demoUniversePlaythrough();
  console.log('\n===============================================\n');

  demoCustomSystem();
  console.log('\n===============================================\n');

  demoStationTrading();
  console.log('\n===============================================\n');

  console.log('Demos complete!');
}
