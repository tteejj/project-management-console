"use strict";
/**
 * Moon Landing Demonstration
 *
 * Demonstrates a complete powered descent and landing sequence
 * from 10km altitude using the integrated spacecraft simulation.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const spacecraft_1 = require("../src/spacecraft");
console.log('='.repeat(70));
console.log('SPACECRAFT PHYSICS SIMULATION - MOON LANDING DEMONSTRATION');
console.log('='.repeat(70));
console.log('');
// Create spacecraft starting at 10km altitude
const spacecraft = new spacecraft_1.Spacecraft({
    shipPhysicsConfig: {
        initialPosition: { x: 0, y: 0, z: 1737400 + 10000 }, // 10km altitude
        initialVelocity: { x: 0, y: 0, z: -30 } // Descending at 30 m/s
    }
});
console.log('📍 INITIAL CONDITIONS');
console.log('  Altitude: 10,000 m');
console.log('  Vertical speed: -30 m/s (descending)');
console.log('  Mass: 8,000 kg (5,000 kg dry + 3,000 kg propellant)');
console.log('');
// Phase 1: System Startup
console.log('⚡ PHASE 1: SYSTEM STARTUP');
console.log('  Starting nuclear reactor...');
spacecraft.startReactor();
// Fast-forward through reactor startup
let stepCount = 0;
while (spacecraft.getState().electrical.reactor.status !== 'online') {
    spacecraft.update(0.1);
    stepCount++;
    if (stepCount % 100 === 0) {
        console.log(`  Reactor startup progress: ${(stepCount / 350 * 100).toFixed(0)}%`);
    }
}
console.log('  ✓ Reactor online!');
console.log('  Starting coolant pumps...');
spacecraft.startCoolantPump(0);
spacecraft.startCoolantPump(1);
spacecraft.update(0.1);
console.log('  ✓ Coolant system active');
console.log('');
// Phase 2: Initial Descent
console.log('🌙 PHASE 2: INITIAL DESCENT (Freefall)');
console.log('  Falling under Moon gravity (1.623 m/s²)...');
for (let i = 0; i < 100; i++) { // 10 seconds freefall
    spacecraft.update(0.1);
}
let state = spacecraft.getState();
console.log(`  Altitude: ${state.physics.altitude.toFixed(0)} m`);
console.log(`  Vertical speed: ${state.physics.verticalSpeed.toFixed(1)} m/s`);
console.log('');
// Phase 3: Main Engine Ignition
console.log('🔥 PHASE 3: MAIN ENGINE IGNITION');
const igniteSuccess = spacecraft.igniteMainEngine();
console.log(`  Engine ignition command: ${igniteSuccess ? 'SUCCESS' : 'FAILED'}`);
// Wait for ignition sequence (2 seconds)
for (let i = 0; i < 20; i++) {
    spacecraft.update(0.1);
}
state = spacecraft.getState();
console.log(`  Engine status: ${state.mainEngine.status}`);
console.log(`  Current thrust: ${state.mainEngine.currentThrustN.toFixed(0)} N`);
console.log('');
// Phase 4: Powered Descent
console.log('🚀 PHASE 4: POWERED DESCENT');
console.log('  Throttling engine for controlled descent...');
console.log('');
spacecraft.setMainEngineThrottle(0.7); // 70% throttle for efficiency
let lastAltitude = state.physics.altitude;
let minVerticalSpeed = state.physics.verticalSpeed;
// Descent control loop
while (state.physics.altitude > 0) {
    spacecraft.update(0.1);
    state = spacecraft.getState();
    const altitude = state.physics.altitude;
    const vertSpeed = state.physics.verticalSpeed;
    // Track minimum vertical speed (most upward velocity)
    if (vertSpeed > minVerticalSpeed) {
        minVerticalSpeed = vertSpeed;
    }
    // Adaptive throttle control
    if (altitude < 2000 && vertSpeed < -20) {
        spacecraft.setMainEngineThrottle(1.0); // Full throttle
    }
    else if (altitude < 1000 && vertSpeed < -10) {
        spacecraft.setMainEngineThrottle(0.9);
    }
    else if (altitude < 500 && vertSpeed < -5) {
        spacecraft.setMainEngineThrottle(0.8);
    }
    else if (altitude < 100 && vertSpeed < -3) {
        spacecraft.setMainEngineThrottle(1.0); // Emergency full throttle
    }
    // Progress updates every 1000m
    if (Math.floor(altitude / 1000) < Math.floor(lastAltitude / 1000)) {
        const fuelRemaining = state.fuel.totalFuel;
        console.log(`  ${(altitude / 1000).toFixed(1)}km | Speed: ${vertSpeed.toFixed(1)} m/s | Fuel: ${fuelRemaining.toFixed(0)}kg | Throttle: ${(state.mainEngine.throttle * 100).toFixed(0)}%`);
    }
    lastAltitude = altitude;
    // Safety: Break if simulation runs too long
    if (state.simulationTime > 300) {
        console.log('  Simulation timeout - aborting');
        break;
    }
}
// Phase 5: Landing Analysis
console.log('');
console.log('🎯 PHASE 5: TOUCHDOWN ANALYSIS');
console.log('='.repeat(70));
const finalState = spacecraft.getState();
const impactSpeed = Math.abs(finalState.physics.verticalSpeed);
const fuelUsed = 3000 - finalState.fuel.totalFuel;
console.log('');
console.log('📊 LANDING RESULTS:');
console.log(`  Impact speed: ${impactSpeed.toFixed(2)} m/s`);
console.log(`  Final altitude: ${finalState.physics.altitude.toFixed(2)} m`);
console.log(`  Flight time: ${finalState.simulationTime.toFixed(1)} seconds`);
console.log(`  Fuel consumed: ${fuelUsed.toFixed(0)} kg (${(fuelUsed / 3000 * 100).toFixed(1)}%)`);
console.log(`  Fuel remaining: ${finalState.fuel.totalFuel.toFixed(0)} kg`);
console.log('');
// Landing quality assessment
if (impactSpeed < 2.0) {
    console.log('🌟 RESULT: PERFECT LANDING!');
    console.log('   Excellent piloting! Impact speed < 2 m/s');
}
else if (impactSpeed < 3.0) {
    console.log('✅ RESULT: SOFT LANDING');
    console.log('   Safe landing achieved! Impact speed < 3 m/s');
}
else if (impactSpeed < 5.0) {
    console.log('⚠️  RESULT: HARD LANDING');
    console.log('   Spacecraft survived but damaged. Impact speed < 5 m/s');
}
else if (impactSpeed < 10.0) {
    console.log('❌ RESULT: CRASH LANDING');
    console.log('   Severe damage. Impact speed < 10 m/s');
}
else {
    console.log('💥 RESULT: CATASTROPHIC IMPACT');
    console.log('   Total loss of spacecraft.');
}
console.log('');
// System status report
console.log('🔧 FINAL SYSTEM STATUS:');
console.log(`  Main Engine: ${finalState.mainEngine.status} (Health: ${finalState.mainEngine.health.toFixed(1)}%)`);
console.log(`  Reactor: ${finalState.electrical.reactor.status} (Output: ${finalState.electrical.reactor.outputKW.toFixed(1)} kW)`);
console.log(`  Battery: ${finalState.electrical.battery.chargePercent.toFixed(1)}%`);
console.log(`  Coolant Loop 0: ${finalState.coolant.loops[0].temperature.toFixed(1)}K`);
console.log(`  Coolant Loop 1: ${finalState.coolant.loops[1].temperature.toFixed(1)}K`);
const reactorTemp = finalState.thermal.components.find((c) => c.name === 'reactor')?.temperature || 0;
const engineTemp = finalState.thermal.components.find((c) => c.name === 'main_engine')?.temperature || 0;
console.log(`  Reactor Temp: ${reactorTemp.toFixed(0)}K`);
console.log(`  Engine Temp: ${engineTemp.toFixed(0)}K`);
console.log('');
// Physics summary
console.log('📐 PHYSICS VALIDATION:');
console.log(`  Max upward velocity achieved: ${minVerticalSpeed.toFixed(1)} m/s`);
console.log(`  Average fuel consumption: ${(fuelUsed / finalState.simulationTime).toFixed(2)} kg/s`);
console.log(`  Heat radiated to space: ${(finalState.coolant.totalHeatRejected / 1e6).toFixed(2)} MJ`);
console.log('');
console.log('='.repeat(70));
console.log('DEMONSTRATION COMPLETE');
console.log('='.repeat(70));
//# sourceMappingURL=landing-demo.js.map