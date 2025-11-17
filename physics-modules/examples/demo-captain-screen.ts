#!/usr/bin/env node

/**
 * Demo of Enhanced Captain Screen
 * Shows all new flight control, navigation, and autopilot features
 */

import { Spacecraft } from '../src/spacecraft';

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m'
};

console.log(colors.bright + colors.cyan);
console.log('╔═══════════════════════════════════════════════════════════════════════════╗');
console.log('║                                                                           ║');
console.log('║         🌙 VECTOR MOON LANDER - ENHANCED CAPTAIN SCREEN DEMO 🚀           ║');
console.log('║                                                                           ║');
console.log('╚═══════════════════════════════════════════════════════════════════════════╝');
console.log(colors.reset);
console.log();

// Create spacecraft
const spacecraft = new Spacecraft();

// Initialize systems
console.log(colors.cyan + 'Initializing spacecraft systems...' + colors.reset);
spacecraft.startReactor();
spacecraft.startCoolantPump(0);

// Set initial conditions (15km altitude, descending)
spacecraft.physics.position = { x: 0, y: 0, z: 1737400 + 15000 };  // 15km above surface
spacecraft.physics.velocity = { x: 0, y: 0, z: -40 };  // -40 m/s vertical
spacecraft.physics.propellantMass = 160;  // 160 kg fuel

console.log(colors.green + '✓ Systems initialized' + colors.reset);
console.log();

// Demonstrate Flight Control features
console.log(colors.bright + '═══ FLIGHT CONTROL DEMONSTRATION ═══' + colors.reset);
console.log();

console.log('1. Enabling SAS (Stability Mode)...');
spacecraft.setSASMode('stability');
console.log(colors.green + `   ✓ SAS Mode: ${spacecraft.getSASMode()}` + colors.reset);
console.log();

console.log('2. Igniting Main Engine...');
spacecraft.igniteMainEngine();
spacecraft.update(2.0);  // Wait for ignition
console.log(colors.green + `   ✓ Engine Status: ${spacecraft.mainEngine.getState().status}` + colors.reset);
console.log();

console.log('3. Setting Throttle to 50%...');
spacecraft.setMainEngineThrottle(0.5);
console.log(colors.green + `   ✓ Throttle: ${(spacecraft.mainEngine.getState().throttle * 100).toFixed(0)}%` + colors.reset);
console.log();

console.log('4. Enabling Gimbal Autopilot...');
spacecraft.setGimbalAutopilot(true);
console.log(colors.green + `   ✓ Gimbal Autopilot: ENABLED` + colors.reset);
console.log();

console.log('5. Setting Autopilot to Altitude Hold (10km)...');
spacecraft.setTargetAltitude(10000);
spacecraft.setAutopilotMode('altitude_hold');
const fcState = spacecraft.flightControl.getState();
console.log(colors.green + `   ✓ Autopilot Mode: ${fcState.autopilotMode}` + colors.reset);
console.log(colors.green + `   ✓ Target Altitude: ${fcState.targetAltitude}m` + colors.reset);
console.log();

// Demonstrate Navigation features
console.log(colors.bright + '═══ NAVIGATION DEMONSTRATION ═══' + colors.reset);
console.log();

const navData = spacecraft.getNavigationTelemetry();

console.log('Navigation Telemetry:');
console.log(`  Altitude:          ${navData.altitude.toFixed(0)} m`);
console.log(`  Vertical Speed:    ${navData.verticalSpeed.toFixed(2)} m/s`);
console.log(`  Horizontal Speed:  ${navData.horizontalSpeed.toFixed(2)} m/s`);
console.log(`  Delta-V Remaining: ${navData.deltaVRemaining.toFixed(0)} m/s`);
console.log(`  TWR:               ${navData.twr.toFixed(2)}`);
console.log();

console.log('Suicide Burn Calculation:');
const suicideBurn = spacecraft.getSuicideBurnData();
console.log(`  Burn Altitude:     ${suicideBurn.burnAltitude.toFixed(0)} m`);
console.log(`  Time Until Burn:   ${suicideBurn.timeUntilBurn.toFixed(1)} s`);
console.log(`  Should Burn:       ${suicideBurn.shouldBurn ? colors.red + 'YES!' + colors.reset : colors.green + 'No' + colors.reset}`);
console.log();

console.log('Trajectory Prediction:');
const trajectory = spacecraft.predictTrajectory();
if (trajectory.willImpact) {
  console.log(`  Time to Impact:    ${trajectory.impactTime.toFixed(1)} s`);
  console.log(`  Impact Speed:      ${trajectory.impactSpeed.toFixed(2)} m/s`);
  console.log(`  Impact Location:   ${trajectory.coordinates.lat.toFixed(3)}°, ${trajectory.coordinates.lon.toFixed(3)}°`);
} else {
  console.log(colors.yellow + '  No impact predicted (escaping)' + colors.reset);
}
console.log();

// Demonstrate all autopilot modes
console.log(colors.bright + '═══ AUTOPILOT MODES ═══' + colors.reset);
console.log();

const modes = ['off', 'altitude_hold', 'vertical_speed_hold', 'suicide_burn', 'hover'];
for (const mode of modes) {
  spacecraft.setAutopilotMode(mode as any);
  const state = spacecraft.flightControl.getState();
  const color = mode === 'off' ? colors.dim : colors.green;
  console.log(`  ${color}${mode.padEnd(20)}${colors.reset} - ${getAutopilotDescription(mode)}`);
}
console.log();

// Demonstrate SAS modes
console.log(colors.bright + '═══ SAS MODES ═══' + colors.reset);
console.log();

const sasModes = ['off', 'stability', 'prograde', 'retrograde', 'radial_in', 'radial_out',
                   'normal', 'anti_normal', 'target', 'anti_target'];
for (const mode of sasModes) {
  const color = mode === 'off' ? colors.dim : colors.green;
  console.log(`  ${color}${mode.padEnd(20)}${colors.reset} - ${getSASDescription(mode)}`);
}
console.log();

// Show comprehensive spacecraft state
console.log(colors.bright + '═══ COMPLETE SPACECRAFT STATE ═══' + colors.reset);
console.log();

const state = spacecraft.getState();

console.log(colors.yellow + '┌─ ORBITAL STATUS ──────────────────────────────────────────┐' + colors.reset);
console.log(`│ Altitude:       ${state.physics.altitude.toFixed(1).padStart(10)} m`);
console.log(`│ Vertical Speed: ${state.physics.verticalSpeed.toFixed(2).padStart(10)} m/s`);
console.log(`│ Total Speed:    ${state.physics.speed.toFixed(2).padStart(10)} m/s`);
console.log(colors.yellow + '└────────────────────────────────────────────────────────────┘' + colors.reset);
console.log();

console.log(colors.yellow + '┌─ FLIGHT CONTROL ───────────────────────────────────────────┐' + colors.reset);
console.log(`│ SAS Mode:       ${colors.green}${state.flightControl.sasMode.toUpperCase().padStart(16)}${colors.reset}`);
console.log(`│ Autopilot:      ${colors.green}${state.flightControl.autopilotMode.replace('_', ' ').toUpperCase().padStart(16)}${colors.reset}`);
console.log(`│ Gimbal Ctrl:    ${colors.green}ENABLED${colors.reset.padStart(7)}`);
console.log(colors.yellow + '└────────────────────────────────────────────────────────────┘' + colors.reset);
console.log();

console.log(colors.cyan + '┌─ NAVIGATION ───────────────────────────────────────────────┐' + colors.reset);
console.log(`│ Time to Impact: ${navData.timeToImpact !== Infinity ? navData.timeToImpact.toFixed(1).padStart(10) + ' s' : colors.dim + 'NO IMPACT' + colors.reset}`);
console.log(`│ Suicide Burn:   ${suicideBurn.burnAltitude.toFixed(0).padStart(10)} m`);
console.log(`│ Delta-V Remain: ${navData.deltaVRemaining.toFixed(0).padStart(10)} m/s`);
console.log(`│ TWR:            ${navData.twr.toFixed(2).padStart(10)}`);
console.log(colors.cyan + '└────────────────────────────────────────────────────────────┘' + colors.reset);
console.log();

console.log(colors.green + '✓ Enhanced Captain Screen Demo Complete!' + colors.reset);
console.log();
console.log('New features include:');
console.log('  • SAS (Stability Augmentation System) with 10 modes');
console.log('  • Autopilot with 5 modes (off, altitude hold, V/S hold, suicide burn, hover)');
console.log('  • Gimbal autopilot for automated thrust vectoring');
console.log('  • Real-time navigation telemetry (delta-V, TWR, impact prediction)');
console.log('  • Suicide burn calculator with warnings');
console.log('  • Trajectory prediction');
console.log('  • Mission system (ready for future integration)');
console.log();

function getAutopilotDescription(mode: string): string {
  const descriptions: any = {
    'off': 'Manual control',
    'altitude_hold': 'Maintain specific altitude',
    'vertical_speed_hold': 'Maintain constant descent/ascent rate',
    'suicide_burn': 'Automated optimal deceleration burn',
    'hover': 'Maintain altitude at zero vertical speed'
  };
  return descriptions[mode] || 'Unknown mode';
}

function getSASDescription(mode: string): string {
  const descriptions: any = {
    'off': 'SAS disabled',
    'stability': 'Dampen rotation, maintain current attitude',
    'prograde': 'Point velocity vector forward',
    'retrograde': 'Point velocity vector backward (for braking)',
    'radial_in': 'Point toward planet center',
    'radial_out': 'Point away from planet center',
    'normal': 'Point normal to orbital plane',
    'anti_normal': 'Point anti-normal to orbital plane',
    'target': 'Point toward navigation target',
    'anti_target': 'Point away from navigation target'
  };
  return descriptions[mode] || 'Unknown mode';
}
