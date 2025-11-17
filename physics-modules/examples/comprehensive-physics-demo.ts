/**
 * Comprehensive Physics Demonstration
 *
 * Showcases all enhanced physics features:
 * - Atmospheric drag & re-entry
 * - G-force effects on crew
 * - Radiation exposure tracking
 * - Thermal radiation to space
 * - Collision response physics
 * - Stefan-Boltzmann cooling
 */

import { Spacecraft } from '../src/spacecraft';

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m'
};

/**
 * Scenario 1: High-G Atmospheric Re-entry
 */
function scenario1_ReentryWithAtmosphere() {
  console.log(`\n${colors.bright}${colors.cyan}=== SCENARIO 1: HIGH-G ATMOSPHERIC RE-ENTRY ===${colors.reset}\n`);

  // Create spacecraft with atmosphere enabled
  const spacecraft = new Spacecraft({
    shipPhysicsConfig: {
      hasAtmosphere: true,
      seaLevelDensity: 1.225,  // kg/m³ (Earth-like)
      atmosphericScaleHeight: 8500,  // m
      dragCoefficient: 2.2,  // Blunt re-entry capsule
      crossSectionalArea: 12,  // m²
      initialPosition: { x: 0, y: 0, z: 1737400 + 80000 },  // 80km altitude
      initialVelocity: { x: 0, y: 0, z: -200 }  // 200 m/s descent
    }
  });

  // Start systems
  spacecraft.startReactor();
  spacecraft.startCoolantPump(0);

  console.log(`${colors.yellow}Initial conditions:${colors.reset}`);
  console.log(`  Altitude: 80,000 m`);
  console.log(`  Velocity: 200 m/s downward`);
  console.log(`  Atmosphere: Earth-like (ρ₀ = 1.225 kg/m³)`);
  console.log(`  Drag coefficient: 2.2 (blunt body)`);
  console.log(`\n${colors.bright}Entering atmosphere...${colors.reset}\n`);

  // Simulate re-entry
  const dt = 0.5;  // 0.5 second timesteps
  const reportInterval = 10;  // Report every 10 steps (5 seconds)

  for (let i = 0; i < 200; i++) {
    spacecraft.update(dt);

    if (i % reportInterval === 0) {
      const state = spacecraft.getState();
      const physics = state.physics;
      const crew = state.crew;

      // Calculate G-forces from deceleration
      const gForce = physics.peakGForce;

      console.log(`t = ${(i * dt).toFixed(1)}s:`);
      console.log(`  Altitude: ${physics.altitude.toFixed(0)} m`);
      console.log(`  Speed: ${physics.speed.toFixed(1)} m/s`);
      console.log(`  Atmospheric density: ${physics.atmosphericDensity.toFixed(4)} kg/m³`);
      console.log(`  Dynamic pressure: ${physics.dynamicPressure.toFixed(0)} Pa`);
      console.log(`  Mach number: ${physics.machNumber.toFixed(2)}`);
      console.log(`  ${colors.red}G-force: ${gForce.toFixed(2)} G${colors.reset}`);
      console.log(`  Drag energy dissipated: ${(physics.totalDragEnergy / 1e6).toFixed(2)} MJ`);

      // Crew status
      console.log(`  ${colors.cyan}Crew Status:${colors.reset}`);
      console.log(`    Alive: ${crew.alive} / Incapacitated: ${crew.incapacitated}`);

      if (gForce > 3) {
        console.log(`    ${colors.yellow}⚠ Crew experiencing discomfort!${colors.reset}`);
      }
      if (gForce > 5) {
        console.log(`    ${colors.red}⚠⚠ INJURY THRESHOLD EXCEEDED!${colors.reset}`);
      }
      if (gForce > 9) {
        console.log(`    ${colors.red}⚠⚠⚠ G-LOC (BLACKOUT) RISK!${colors.reset}`);
      }

      console.log('');

      // Stop if landed
      if (physics.altitude <= 0) {
        console.log(`${colors.green}✓ Landed safely${colors.reset}`);
        break;
      }
    }
  }

  // Final report
  const finalState = spacecraft.getState();
  console.log(`\n${colors.bright}=== FINAL REPORT ===${colors.reset}`);
  console.log(`Peak G-force: ${colors.red}${finalState.physics.peakGForce.toFixed(2)} G${colors.reset}`);
  console.log(`Total drag energy: ${(finalState.physics.totalDragEnergy / 1e6).toFixed(2)} MJ`);
  console.log(`Crew casualties: ${finalState.crew.dead}`);
  console.log(`Crew injured: ${finalState.crew.injured}`);
}

/**
 * Scenario 2: Radiation Belt Passage
 */
function scenario2_RadiationExposure() {
  console.log(`\n${colors.bright}${colors.magenta}=== SCENARIO 2: RADIATION BELT PASSAGE ===${colors.reset}\n`);

  const spacecraft = new Spacecraft({
    shipPhysicsConfig: {
      hasAtmosphere: false,  // Vacuum
      initialPosition: { x: 0, y: 0, z: 1737400 + 50000 },  // 50km altitude
      initialVelocity: { x: 1500, y: 0, z: 100 }  // Orbital velocity
    }
  });

  spacecraft.startReactor();
  spacecraft.setSunlight(true);  // In sunlight

  console.log(`${colors.yellow}Initial conditions:${colors.reset}`);
  console.log(`  Altitude: 50,000 m`);
  console.log(`  In sunlight: Yes`);
  console.log(`  Mission duration: 2 hours`);
  console.log(`\n${colors.bright}Monitoring radiation exposure...${colors.reset}\n`);

  // Simulate 2 hours in orbit
  const dt = 10;  // 10 second timesteps
  const duration = 2 * 3600;  // 2 hours
  const reportInterval = 360;  // Report every hour

  for (let t = 0; t < duration; t += dt) {
    spacecraft.update(dt);

    if (t % reportInterval === 0) {
      const state = spacecraft.getState();
      const crew = state.crew;
      const crewMembers = spacecraft.getCrewMembers();

      console.log(`t = ${(t / 3600).toFixed(1)} hours:`);
      console.log(`  Radiation rate: ${(state.environment.radiationRate * 1000).toFixed(3)} mSv/hour`);
      console.log(`  Altitude: ${state.physics.altitude.toFixed(0)} m`);
      console.log(`  In sunlight: ${state.environment.inSunlight ? 'Yes' : 'No'}`);

      // Show individual crew member exposure
      for (const member of crewMembers) {
        const dose = member.radiationDose;
        let status = colors.green + '✓ Healthy' + colors.reset;
        if (dose > 0.5) status = colors.yellow + '⚠ Mild symptoms' + colors.reset;
        if (dose > 2) status = colors.red + '⚠⚠ Radiation sick' + colors.reset;
        if (dose > 8) status = colors.red + '⚠⚠⚠ LETHAL DOSE' + colors.reset;

        console.log(`    ${member.name}: ${dose.toFixed(3)} Sv [${status}]`);
      }

      console.log('');
    }

    // Simulate entering high-radiation zone at 150km altitude
    const altitude = spacecraft.getState().physics.altitude;
    if (altitude > 100000 && altitude < 500000) {
      // High radiation zone
      spacecraft['radiationExposureRate'] = 0.0005;  // 0.5 mSv/hour
    }
  }

  // Final report
  const finalCrewMembers = spacecraft.getCrewMembers();
  console.log(`\n${colors.bright}=== FINAL RADIATION EXPOSURE ===${colors.reset}`);
  for (const member of finalCrewMembers) {
    const dose = member.radiationDose;
    console.log(`${member.name}: ${colors.cyan}${dose.toFixed(3)} Sv${colors.reset} (${(dose * 1000).toFixed(1)} mSv)`);
  }
}

/**
 * Scenario 3: Thermal Management in Space
 */
function scenario3_ThermalRadiation() {
  console.log(`\n${colors.bright}${colors.blue}=== SCENARIO 3: THERMAL MANAGEMENT ===${colors.reset}\n`);

  const spacecraft = new Spacecraft({
    thermalConfig: {
      externalSurfaceArea: 100,  // m²
      surfaceEmissivity: 0.85,
      solarFlux: 1361,  // W/m² (Earth orbit)
      solarAbsorptivity: 0.3,  // White paint
      inSunlight: true
    },
    shipPhysicsConfig: {
      hasAtmosphere: false,
      initialPosition: { x: 0, y: 0, z: 1737400 + 200000 },  // 200km
      initialVelocity: { x: 1600, y: 0, z: 0 }
    }
  });

  spacecraft.startReactor();
  spacecraft.startCoolantPump(0);
  spacecraft.startCoolantPump(1);

  console.log(`${colors.yellow}Initial conditions:${colors.reset}`);
  console.log(`  Surface area: 100 m²`);
  console.log(`  Emissivity: 0.85`);
  console.log(`  Solar flux: 1361 W/m²`);
  console.log(`  Starting in full sunlight`);
  console.log(`\n${colors.bright}Monitoring thermal balance...${colors.reset}\n`);

  // Simulate thermal cycling
  const dt = 1;
  const cycleDuration = 600;  // 10 minute cycle

  for (let cycle = 0; cycle < 3; cycle++) {
    console.log(`${colors.bright}--- Cycle ${cycle + 1}: ${cycle % 2 === 0 ? 'SUNLIGHT' : 'SHADOW'} ---${colors.reset}`);

    spacecraft.setSunlight(cycle % 2 === 0);

    for (let t = 0; t < cycleDuration; t += dt) {
      spacecraft.update(dt);

      if (t % 120 === 0) {  // Report every 2 minutes
        const state = spacecraft.getState();
        const thermal = state.thermal;

        const avgTemp = thermal.compartments.reduce((sum: number, c: any) => sum + c.temperature, 0) / thermal.compartments.length;

        console.log(`t = ${(cycle * cycleDuration + t).toFixed(0)}s:`);
        console.log(`  Average ship temp: ${avgTemp.toFixed(1)} K (${(avgTemp - 273).toFixed(1)}°C)`);
        console.log(`  Radiative power out: ${(thermal.radiativePower / 1000).toFixed(2)} kW`);
        console.log(`  Solar power in: ${(thermal.solarPower / 1000).toFixed(2)} kW`);
        console.log(`  Net heat flow: ${((thermal.solarPower - thermal.radiativePower) / 1000).toFixed(2)} kW`);
        console.log(`  Total radiated: ${(thermal.totalHeatRadiated / 1e6).toFixed(2)} MJ`);
        console.log('');
      }
    }
  }

  console.log(`${colors.green}✓ Thermal cycling complete${colors.reset}`);
}

/**
 * Scenario 4: High-G Combat Maneuver
 */
function scenario4_CombatManeuver() {
  console.log(`\n${colors.bright}${colors.red}=== SCENARIO 4: HIGH-G COMBAT MANEUVER ===${colors.reset}\n`);

  const spacecraft = new Spacecraft({
    shipPhysicsConfig: {
      hasAtmosphere: false,
      initialPosition: { x: 0, y: 0, z: 1737400 + 100000 },
      initialVelocity: { x: 1700, y: 0, z: 0 }
    },
    mainEngineConfig: {
      maxThrustN: 100000  // 100 kN for high acceleration
    }
  });

  spacecraft.startReactor();

  // Wait for reactor startup
  for (let i = 0; i < 350; i++) {
    spacecraft.update(0.1);
  }

  console.log(`${colors.yellow}Combat maneuver: Emergency evasion${colors.reset}`);
  console.log(`  Engine: 100 kN max thrust`);
  console.log(`  Ship mass: ~8000 kg`);
  console.log(`  Expected acceleration: ~12.5 m/s² (1.3 G)`);
  console.log(`\n${colors.bright}Executing full-throttle burn...${colors.reset}\n`);

  spacecraft.igniteMainEngine();
  spacecraft.setMainEngineThrottle(1.0);  // Full throttle

  const burnDuration = 60;  // 1 minute burn
  const dt = 0.1;

  for (let t = 0; t < burnDuration; t += dt) {
    spacecraft.update(dt);

    if (Math.floor(t) !== Math.floor(t - dt)) {  // Report every second
      const state = spacecraft.getState();
      const gForce = state.physics.peakGForce;
      const crewStatus = state.crew;

      console.log(`t = ${t.toFixed(0)}s: G-force = ${colors.red}${gForce.toFixed(2)} G${colors.reset}, Speed = ${state.physics.speed.toFixed(0)} m/s, Crew OK: ${crewStatus.alive - crewStatus.incapacitated}/${crewStatus.alive}`);

      if (gForce > 5) {
        console.log(`  ${colors.yellow}⚠ CREW INJURY WARNING${colors.reset}`);
      }
    }
  }

  spacecraft.shutdownMainEngine();

  const finalState = spacecraft.getState();
  console.log(`\n${colors.bright}=== MANEUVER COMPLETE ===${colors.reset}`);
  console.log(`Peak G-force: ${colors.red}${finalState.physics.peakGForce.toFixed(2)} G${colors.reset}`);
  console.log(`Delta-V achieved: ${(finalState.physics.speed - 1700).toFixed(0)} m/s`);
  console.log(`Crew status: ${finalState.crew.alive} alive, ${finalState.crew.incapacitated} incapacitated`);
}

/**
 * Main demonstration
 */
function main() {
  console.log(`${colors.bright}${colors.cyan}`);
  console.log(`╔════════════════════════════════════════════════════════════╗`);
  console.log(`║  COMPREHENSIVE PHYSICS DEMONSTRATION                       ║`);
  console.log(`║  Enhanced Spacecraft Simulation                            ║`);
  console.log(`╚════════════════════════════════════════════════════════════╝`);
  console.log(colors.reset);

  // Run all scenarios
  scenario1_ReentryWithAtmosphere();
  scenario2_RadiationExposure();
  scenario3_ThermalRadiation();
  scenario4_CombatManeuver();

  console.log(`\n${colors.bright}${colors.green}All scenarios complete!${colors.reset}\n`);
}

// Run if executed directly
if (require.main === module) {
  main();
}

export { main };
