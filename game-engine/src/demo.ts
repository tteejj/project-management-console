/**
 * demo.ts
 * Demonstration of the integrated space game
 */

import { SpaceGame } from './SpaceGame';

/**
 * Main demo - shows the integrated universe and physics system
 */
function runGameDemo() {
  console.log('╔═══════════════════════════════════════════════════════╗');
  console.log('║    INTEGRATED SPACE GAME DEMO                         ║');
  console.log('║    Universe + Physics + Ship Systems                  ║');
  console.log('╚═══════════════════════════════════════════════════════╝\n');

  // Create game
  const game = new SpaceGame({
    universeConfig: {
      seed: 42,
      numSystems: 5,
      campaignMode: 'OPEN_WORLD'
    }
  });

  console.log('\n═══ INITIAL STATUS ═══\n');

  // System info
  const systemInfo = game.getSystemInfo();
  console.log(`📍 Current System: ${systemInfo.name}`);
  console.log(`   ⭐ Star Class: ${systemInfo.starClass}`);
  console.log(`   🌍 Planets: ${systemInfo.planets}`);
  console.log(`   🛰️ Stations: ${systemInfo.stations}`);
  console.log(`   ⚠️  Hazards: ${systemInfo.hazards}\n`);

  // Ship status
  const shipStatus = game.getShipStatus();
  console.log('🚀 Ship Status:');
  console.log(`   Position: (${shipStatus.position.x.toExponential(2)}, ${shipStatus.position.y.toExponential(2)}, ${shipStatus.position.z.toExponential(2)})`);
  console.log(`   Fuel: ${shipStatus.fuel.toFixed(0)} kg (${((shipStatus.fuel / 5000) * 100).toFixed(0)}%)`);
  console.log(`   Power: ${shipStatus.power.toFixed(0)} Wh (${((shipStatus.power / 10000) * 100).toFixed(0)}%)`);
  console.log(`   Temperature: ${shipStatus.temperature.toFixed(1)}K`);
  if (shipStatus.altitude !== undefined) {
    console.log(`   Altitude: ${(shipStatus.altitude / 1000).toFixed(0)} km above ${shipStatus.nearestBody}`);
  }

  console.log('\n═══ EXPLORING THE SYSTEM ═══\n');

  // List planets
  console.log('Planets in system:');
  game.currentSystem.planets.forEach((planet, i) => {
    const orbitAU = planet.orbital!.semiMajorAxis / 1.496e11;
    console.log(`  ${i + 1}. ${planet.name}`);
    console.log(`     Class: ${planet.planetClass}`);
    console.log(`     Orbit: ${orbitAU.toFixed(2)} AU`);
    console.log(`     Mass: ${(planet.physical.mass / 5.972e24).toFixed(2)} Earth masses`);
    console.log(`     Temperature: ${planet.surfaceTemperature.toFixed(0)}K`);
    console.log(`     Habitable: ${planet.isHabitable ? '✅ YES' : '❌ No'}`);
    console.log(`     Moons: ${planet.children.length}`);
    if (planet.resources.size > 0) {
      const resources = Array.from(planet.resources.entries())
        .filter(([_, abundance]) => abundance > 0.5)
        .map(([resource, abundance]) => `${resource} (${(abundance * 100).toFixed(0)}%)`)
        .join(', ');
      if (resources) console.log(`     Rich in: ${resources}`);
    }
    console.log('');
  });

  // List stations
  if (game.currentSystem.stations.length > 0) {
    console.log('Space Stations:');
    game.currentSystem.stations.forEach((station, i) => {
      console.log(`  ${i + 1}. ${station.name}`);
      console.log(`     Type: ${station.stationType}`);
      console.log(`     Faction: ${station.faction}`);
      console.log(`     Population: ${station.population.toLocaleString()}`);

      const services = Object.entries(station.services)
        .filter(([_, available]) => available)
        .map(([service]) => service)
        .join(', ');
      console.log(`     Services: ${services}`);

      // Missions
      const missions = game.universe.getMissionsAtStation(station.id);
      if (missions.length > 0) {
        console.log(`     Missions Available: ${missions.length}`);
        missions.slice(0, 2).forEach(mission => {
          console.log(`       - [${mission.type}] ${mission.title} (${mission.reward} credits)`);
        });
      }
      console.log('');
    });
  }

  console.log('\n═══ SIMULATION: FLYING IN SPACE ═══\n');

  // Simulate some time
  console.log('Simulating 10 minutes of flight...\n');

  // Turn on main engine
  console.log('🔥 Main engine: 50% thrust');
  game.ship.mainEngine.setThrottlePercent(50);

  // Simulate
  const simSteps = 60; // 60 steps = 10 minutes
  const stepTime = 10; // 10 seconds per step

  for (let i = 0; i < simSteps; i++) {
    game.update(stepTime);

    // Print status every minute
    if (i % 6 === 0) {
      const status = game.getShipStatus();
      const velocity = Math.sqrt(
        status.velocity.x ** 2 + status.velocity.y ** 2 + status.velocity.z ** 2
      );

      console.log(`T+${(i * stepTime / 60).toFixed(1)}min:`);
      console.log(`  Velocity: ${velocity.toFixed(1)} m/s`);
      console.log(`  Fuel: ${status.fuel.toFixed(0)} kg (${((status.fuel / 5000) * 100).toFixed(1)}%)`);
      console.log(`  Power: ${status.power.toFixed(0)} Wh (${((status.power / 10000) * 100).toFixed(1)}%)`);
      console.log(`  Temperature: ${status.temperature.toFixed(1)}K`);
      if (status.altitude !== undefined) {
        console.log(`  Altitude: ${(status.altitude / 1000).toFixed(0)} km`);
      }
      console.log('');
    }
  }

  // Turn off engine
  game.ship.mainEngine.setThrottlePercent(0);
  console.log('🛑 Main engine off\n');

  console.log('\n═══ FINAL STATUS ═══\n');

  const finalStatus = game.getShipStatus();
  const finalVelocity = Math.sqrt(
    finalStatus.velocity.x ** 2 + finalStatus.velocity.y ** 2 + finalStatus.velocity.z ** 2
  );

  console.log('🚀 Ship Status:');
  console.log(`   Velocity: ${finalVelocity.toFixed(1)} m/s`);
  console.log(`   Fuel: ${finalStatus.fuel.toFixed(0)} kg (${((finalStatus.fuel / 5000) * 100).toFixed(0)}%)`);
  console.log(`   Power: ${finalStatus.power.toFixed(0)} Wh (${((finalStatus.power / 10000) * 100).toFixed(0)}%)`);
  console.log(`   Temperature: ${finalStatus.temperature.toFixed(1)}K`);
  if (finalStatus.altitude !== undefined) {
    console.log(`   Altitude: ${(finalStatus.altitude / 1000).toFixed(0)} km above ${finalStatus.nearestBody}`);
  }

  console.log('\n═══ JUMP TO ANOTHER SYSTEM ═══\n');

  // Get available jumps
  const jumps = game.universe.getAvailableJumps();
  console.log(`Available jump destinations: ${jumps.length}\n`);

  jumps.forEach((route, i) => {
    const targetSystem = game.universe.systems.get(route.to);
    console.log(`  ${i + 1}. ${targetSystem?.name || route.to}`);
    console.log(`     Distance: ${route.distance.toFixed(2)} light years`);
    console.log(`     Fuel cost: ${route.fuelCost.toFixed(0)} units\n`);
  });

  if (jumps.length > 0) {
    // Jump to first system
    console.log('Initiating jump...\n');
    const success = game.jumpToSystem(jumps[0].to);

    if (success) {
      const newSystemInfo = game.getSystemInfo();
      console.log(`✨ Arrived in ${newSystemInfo.name}`);
      console.log(`   ⭐ Star Class: ${newSystemInfo.starClass}`);
      console.log(`   🌍 Planets: ${newSystemInfo.planets}`);
      console.log(`   🛰️ Stations: ${newSystemInfo.stations}\n`);
    }
  }

  console.log('\n═══ GAME STATISTICS ═══\n');

  const stats = game.getStats();
  console.log('Universe:');
  console.log(`  Total Systems: ${stats.universeStats.totalSystems}`);
  console.log(`  Total Planets: ${stats.universeStats.totalPlanets}`);
  console.log(`  Habitable Planets: ${stats.universeStats.habitablePlanets}`);
  console.log(`  Total Stations: ${stats.universeStats.totalStations}`);
  console.log(`  Discovered Systems: ${stats.universeStats.discoveredSystems}`);
  console.log(`  Available Missions: ${stats.universeStats.availableMissions}\n`);

  console.log('Ship:');
  console.log(`  Fuel: ${stats.shipStats.fuelPercent.toFixed(0)}%`);
  console.log(`  Power: ${stats.shipStats.powerPercent.toFixed(0)}%`);
  console.log(`  Temperature: ${stats.shipStats.temperature.toFixed(1)}K\n`);

  console.log(`Game Time: ${(stats.gameTime / 60).toFixed(1)} minutes\n`);

  console.log('╔═══════════════════════════════════════════════════════╗');
  console.log('║              DEMO COMPLETE!                           ║');
  console.log('║                                                       ║');
  console.log('║  You now have a fully functional space game with:    ║');
  console.log('║  ✅ Procedural universe generation                    ║');
  console.log('║  ✅ Realistic orbital mechanics                       ║');
  console.log('║  ✅ Ship physics simulation                           ║');
  console.log('║  ✅ Atmospheric effects                               ║');
  console.log('║  ✅ Solar radiation                                   ║');
  console.log('║  ✅ Environmental hazards                             ║');
  console.log('║  ✅ FTL travel between systems                        ║');
  console.log('║  ✅ Space stations with economy                       ║');
  console.log('║  ✅ Mission system                                    ║');
  console.log('╚═══════════════════════════════════════════════════════╝\n');
}

// Run the demo
if (require.main === module) {
  try {
    runGameDemo();
  } catch (error) {
    console.error('Error running demo:', error);
  }
}

export { runGameDemo };
