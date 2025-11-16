/**
 * Spacecraft Integration Tests
 *
 * Demonstrates complete system integration with realistic scenarios:
 * 1. System startup sequence
 * 2. Powered descent from orbit
 * 3. Attitude control with RCS
 * 4. Power management
 * 5. Thermal management
 * 6. Complete landing simulation
 */

import { Spacecraft } from '../src/spacecraft';

interface TestResult {
  name: string;
  passed: boolean;
  message?: string;
  data?: any;
}

class SpacecraftIntegrationTester {
  private results: TestResult[] = [];

  runAll(): TestResult[] {
    console.log('=== SPACECRAFT INTEGRATION TESTS ===\n');

    this.testSystemStartup();
    this.testPoweredDescent();
    this.testAttitudeControl();
    this.testPowerManagement();
    this.testThermalIntegration();
    this.testCompleteLandingSequence();

    this.printResults();
    return this.results;
  }

  private assert(condition: boolean, name: string, message: string, data?: any): void {
    this.results.push({
      name,
      passed: condition,
      message: condition ? 'PASS' : `FAIL: ${message}`,
      data
    });
  }

  /**
   * TEST 1: System Startup Sequence
   * Verify all systems can be initialized and started
   */
  private testSystemStartup(): void {
    console.log('Test 1: System Startup Sequence');

    const spacecraft = new Spacecraft();

    console.log('  Initializing spacecraft...');

    const initialState = spacecraft.getState();

    this.assert(
      initialState.electrical.reactor.status === 'offline',
      'Reactor starts offline',
      'Should be offline initially'
    );

    this.assert(
      initialState.mainEngine.status === 'off',
      'Main engine starts off',
      'Should be off initially'
    );

    // Start reactor
    const reactorStarted = spacecraft.startReactor();

    console.log(`  Reactor start command: ${reactorStarted}`);

    this.assert(
      reactorStarted,
      'Reactor start succeeds',
      'Should allow reactor start'
    );

    // Run for 35 seconds (reactor startup time)
    for (let i = 0; i < 350; i++) {
      spacecraft.update(0.1);
    }

    const stateAfterStartup = spacecraft.getState();

    console.log(`  After 35s: reactor status = ${stateAfterStartup.electrical.reactor.status}`);

    this.assert(
      stateAfterStartup.electrical.reactor.status === 'online',
      'Reactor comes online after startup time',
      'Should be online after 30s'
    );

    // Start coolant pumps
    spacecraft.startCoolantPump(0);
    spacecraft.startCoolantPump(1);

    spacecraft.update(0.1);

    const coolantState = spacecraft.getState().coolant;

    console.log(`  Coolant pump 0 active: ${coolantState.loops[0].pumpActive}`);
    console.log(`  Coolant pump 1 active: ${coolantState.loops[1].pumpActive}`);

    this.assert(
      coolantState.loops[0].pumpActive && coolantState.loops[1].pumpActive,
      'Coolant pumps activated',
      'Both pumps should be running'
    );

    console.log('');
  }

  /**
   * TEST 2: Powered Descent
   * Verify main engine can slow descent
   */
  private testPoweredDescent(): void {
    console.log('Test 2: Powered Descent Simulation');

    const spacecraft = new Spacecraft({
      shipPhysicsConfig: {
        initialPosition: { x: 0, y: 0, z: 1737400 + 2000 },  // 2km altitude
        initialVelocity: { x: 0, y: 0, z: -20 }  // Descending at 20 m/s
      }
    });

    // Start systems
    spacecraft.startReactor();

    // Run reactor startup
    for (let i = 0; i < 350; i++) {
      spacecraft.update(0.1);
    }

    const initialState = spacecraft.getState();

    console.log(`  Initial altitude: ${initialState.physics.altitude.toFixed(0)}m`);
    console.log(`  Initial vertical speed: ${initialState.physics.verticalSpeed.toFixed(1)} m/s`);

    // Ignite main engine
    const engineIgnited = spacecraft.igniteMainEngine();

    console.log(`  Main engine ignition: ${engineIgnited}`);

    this.assert(
      engineIgnited,
      'Main engine ignites successfully',
      'Should allow ignition'
    );

    // Set full throttle
    spacecraft.setMainEngineThrottle(1.0);

    // Burn for 10 seconds
    for (let i = 0; i < 100; i++) {
      spacecraft.update(0.1);
    }

    const finalState = spacecraft.getState();

    console.log(`  After 10s burn:`);
    console.log(`    Altitude: ${finalState.physics.altitude.toFixed(0)}m`);
    console.log(`    Vertical speed: ${finalState.physics.verticalSpeed.toFixed(1)} m/s`);
    console.log(`    Fuel consumed: ${initialState.fuel.totalFuel - finalState.fuel.totalFuel} kg`);

    this.assert(
      finalState.physics.verticalSpeed > initialState.physics.verticalSpeed,
      'Vertical speed decreases (slowing descent)',
      'Engine should reduce descent rate'
    );

    this.assert(
      finalState.fuel.totalFuel < initialState.fuel.totalFuel,
      'Fuel mass decreases during burn',
      'Should consume fuel'
    );

    console.log('');
  }

  /**
   * TEST 3: Attitude Control
   * Verify RCS can control spacecraft orientation
   */
  private testAttitudeControl(): void {
    console.log('Test 3: Attitude Control with RCS');

    const spacecraft = new Spacecraft();

    const initialAttitude = spacecraft.getState().physics.eulerAngles;

    console.log(`  Initial pitch: ${initialAttitude.pitch.toFixed(2)}°`);

    // Activate pitch up
    spacecraft.activateRCS('pitch_up');

    // Run for 5 seconds
    for (let i = 0; i < 50; i++) {
      spacecraft.update(0.1);
    }

    const finalAttitude = spacecraft.getState().physics.eulerAngles;

    console.log(`  After 5s pitch up: ${finalAttitude.pitch.toFixed(2)}°`);

    this.assert(
      Math.abs(finalAttitude.pitch - initialAttitude.pitch) > 5,
      'RCS creates attitude change',
      'Pitch should change significantly'
    );

    // Deactivate
    spacecraft.deactivateRCS('pitch_up');

    console.log('');
  }

  /**
   * TEST 4: Power Management
   * Verify electrical system powers all subsystems
   */
  private testPowerManagement(): void {
    console.log('Test 4: Power Management Integration');

    const spacecraft = new Spacecraft();

    // Start all power consumers
    spacecraft.startReactor();
    spacecraft.startCoolantPump(0);
    spacecraft.startCoolantPump(1);

    // Run reactor startup
    for (let i = 0; i < 350; i++) {
      spacecraft.update(0.1);
    }

    const powerState = spacecraft.getState().electrical;

    console.log(`  Reactor output: ${powerState.reactor.outputKW.toFixed(1)} kW`);
    console.log(`  Total load: ${powerState.totalLoad.toFixed(1)} kW`);
    console.log(`  Battery charge: ${powerState.battery.chargeKWh.toFixed(2)} kWh`);

    this.assert(
      powerState.reactor.status === 'online',
      'Reactor online',
      'Should be generating power'
    );

    const netPower = powerState.reactor.outputKW - powerState.totalLoad;

    console.log(`  Net power: ${netPower.toFixed(1)} kW`);

    this.assert(
      netPower > 0 || powerState.battery.chargeKWh > 0,
      'Sufficient power available',
      'Should have power surplus or battery backup'
    );

    console.log('');
  }

  /**
   * TEST 5: Thermal Integration
   * Verify heat flows from components to coolant
   */
  private testThermalIntegration(): void {
    console.log('Test 5: Thermal Management Integration');

    const spacecraft = new Spacecraft();

    // Start systems
    spacecraft.startReactor();
    spacecraft.startCoolantPump(0);

    // Run reactor startup
    for (let i = 0; i < 350; i++) {
      spacecraft.update(0.1);
    }

    // Ignite engine and burn
    spacecraft.igniteMainEngine();
    spacecraft.setMainEngineThrottle(1.0);

    // Run for 30 seconds
    for (let i = 0; i < 300; i++) {
      spacecraft.update(0.1);
    }

    const thermalState = spacecraft.getState().thermal;
    const coolantState = spacecraft.getState().coolant;

    const reactorTemp = thermalState.components.find((c: any) => c.name === 'reactor')?.temperature || 0;
    const engineTemp = thermalState.components.find((c: any) => c.name === 'main_engine')?.temperature || 0;

    console.log(`  Reactor temperature: ${reactorTemp.toFixed(1)}K`);
    console.log(`  Engine temperature: ${engineTemp.toFixed(1)}K`);
    console.log(`  Coolant loop 0 temp: ${coolantState.loops[0].temperature.toFixed(1)}K`);
    console.log(`  Heat rejected: ${coolantState.totalHeatRejected.toFixed(0)} J`);

    this.assert(
      engineTemp > 293,
      'Engine heats up during burn',
      'Should generate heat'
    );

    this.assert(
      coolantState.totalHeatRejected > 0,
      'Coolant rejects heat to space',
      'Should radiate heat'
    );

    console.log('');
  }

  /**
   * TEST 6: Complete Landing Sequence
   * Realistic landing from low orbit
   */
  private testCompleteLandingSequence(): void {
    console.log('Test 6: Complete Landing Sequence Simulation');

    const spacecraft = new Spacecraft({
      shipPhysicsConfig: {
        initialPosition: { x: 0, y: 0, z: 1737400 + 5000 },  // 5km altitude
        initialVelocity: { x: 0, y: 0, z: -50 }  // Fast descent
      }
    });

    console.log('  Starting landing sequence from 5km...');

    // Emergency startup (fast)
    spacecraft.startReactor();
    spacecraft.startCoolantPump(0);
    spacecraft.startCoolantPump(1);

    // Fast-forward reactor startup
    for (let i = 0; i < 350; i++) {
      spacecraft.update(0.1);
    }

    // Ignite engine
    spacecraft.igniteMainEngine();
    spacecraft.setMainEngineThrottle(1.0);

    // Wait for ignition
    for (let i = 0; i < 20; i++) {
      spacecraft.update(0.1);
    }

    let landedSuccessfully = false;
    let crashLanded = false;
    let simSteps = 0;
    const maxSteps = 2000;  // 200 seconds max

    // Run until landed or crash
    while (simSteps < maxSteps) {
      spacecraft.update(0.1);
      simSteps++;

      const state = spacecraft.getState();

      // Check if landed
      if (state.physics.altitude <= 0) {
        const impactSpeed = Math.abs(state.physics.verticalSpeed);

        console.log(`\n  TOUCHDOWN!`);
        console.log(`    Time: ${state.simulationTime.toFixed(1)}s`);
        console.log(`    Impact speed: ${impactSpeed.toFixed(2)} m/s`);
        console.log(`    Remaining fuel: ${state.fuel.totalFuel.toFixed(0)} kg`);

        if (impactSpeed < 3.0) {
          landedSuccessfully = true;
          console.log(`    Result: SOFT LANDING ✓`);
        } else {
          crashLanded = true;
          console.log(`    Result: HARD LANDING (> 3 m/s)`);
        }

        break;
      }

      // Altitude feedback control (simple)
      const altitude = state.physics.altitude;
      const vertSpeed = state.physics.verticalSpeed;

      // Reduce throttle as we get closer
      if (altitude < 1000 && vertSpeed > -10) {
        spacecraft.setMainEngineThrottle(0.6);
      }

      if (altitude < 500 && vertSpeed > -5) {
        spacecraft.setMainEngineThrottle(0.4);
      }

      // Log progress every 50 steps
      if (simSteps % 50 === 0) {
        console.log(`    t=${state.simulationTime.toFixed(1)}s: alt=${altitude.toFixed(0)}m, v=${vertSpeed.toFixed(1)} m/s`);
      }
    }

    this.assert(
      landedSuccessfully || crashLanded,
      'Landing sequence completes',
      'Should reach surface'
    );

    this.assert(
      landedSuccessfully,
      'Soft landing achieved',
      'Should land safely'
    );

    console.log('');
  }

  private printResults(): void {
    console.log('=== TEST RESULTS ===\n');

    const passed = this.results.filter(r => r.passed).length;
    const failed = this.results.filter(r => !r.passed).length;

    this.results.forEach(result => {
      const status = result.passed ? '✓' : '✗';
      console.log(`${status} ${result.name}: ${result.message}`);
    });

    console.log(`\n${passed} passed, ${failed} failed (${this.results.length} total)`);

    if (failed === 0) {
      console.log('\n🎉 All integration tests passed!');
    } else {
      console.log('\n❌ Some integration tests failed');
    }
  }
}

// Run tests
const tester = new SpacecraftIntegrationTester();
tester.runAll();
