/**
 * Coolant System Physics Tests
 *
 * Tests validate:
 * 1. Heat absorption from components (Q = m*c*ΔT)
 * 2. Stefan-Boltzmann radiation (P = ε*σ*A*T⁴)
 * 3. Flow rate proportional to coolant mass
 * 4. Freezing behavior (<253K)
 * 5. Boiling behavior (>393K)
 * 6. Coolant leaks and loss
 * 7. Cross-connect balancing
 * 8. Pump power consumption
 * 9. Warning generation
 */

import { CoolantSystem } from '../src/coolant-system';

interface TestResult {
  name: string;
  passed: boolean;
  message?: string;
  data?: any;
}

class CoolantSystemTester {
  private results: TestResult[] = [];

  runAll(): TestResult[] {
    console.log('=== COOLANT SYSTEM PHYSICS TESTS ===\n');

    this.testHeatAbsorption();
    this.testRadiationToSpace();
    this.testFlowRateDynamics();
    this.testFreezingBehavior();
    this.testBoilingBehavior();
    this.testCoolantLeaks();
    this.testCrossConnectBalancing();
    this.testPumpPowerConsumption();
    this.testWarningGeneration();
    this.testCoolantRefill();

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

  private assertClose(actual: number, expected: number, tolerance: number, name: string): void {
    const diff = Math.abs(actual - expected);
    const passed = diff <= tolerance;
    this.assert(
      passed,
      name,
      `Expected ${expected}, got ${actual} (diff: ${diff}, tolerance: ${tolerance})`,
      { actual, expected, diff }
    );
  }

  /**
   * TEST 1: Heat Absorption from Components
   * Verify coolant absorbs heat from hot components
   */
  private testHeatAbsorption(): void {
    console.log('Test 1: Heat Absorption from Hot Components');

    const system = new CoolantSystem();

    const loop = system.getLoop(0)!;
    const initialTemp = loop.temperature;

    console.log(`  Initial coolant temp: ${initialTemp}K`);

    // Start pump and provide hot component data
    system.startPump(0);

    const componentTemps = new Map<string, number>();
    componentTemps.set('reactor', 400);      // Hot reactor
    componentTemps.set('main_engine', 350);  // Hot engine

    console.log(`  Component temps: reactor=400K, engine=350K`);

    // Simulate heat absorption
    for (let i = 0; i < 60; i++) {
      system.update(1.0, i, componentTemps);
    }

    const finalTemp = loop.temperature;

    console.log(`  After 60s: ${finalTemp.toFixed(1)}K (ΔT = ${(finalTemp - initialTemp).toFixed(1)}K)`);

    this.assert(
      finalTemp > initialTemp,
      'Coolant absorbs heat from hot components',
      'Temperature should increase'
    );

    this.assert(
      finalTemp < 350, // Should be cooler than components due to radiation
      'Heat is balanced by radiation',
      'Should not reach component temperature'
    );

    console.log('');
  }

  /**
   * TEST 2: Stefan-Boltzmann Radiation
   * Verify radiator rejects heat via T⁴ radiation law
   */
  private testRadiationToSpace(): void {
    console.log('Test 2: Stefan-Boltzmann Radiation to Space');

    const system = new CoolantSystem({
      loops: [{
        id: 0,
        name: 'Test Loop',
        coolantMassKg: 30,
        maxCapacityKg: 30,
        temperature: 350, // Hot coolant
        flowRateLPerMin: 0,
        maxFlowRateLPerMin: 50,
        pumpActive: false,
        pumpPowerW: 400,
        cooledComponents: [],
        radiatorAreaM2: 10.0, // Large radiator
        radiatorTemperature: 350,
        leakRateLPerMin: 0,
        frozen: false,
        boiling: false
      }]
    });

    const loop = system.getLoop(0)!;
    const initialTemp = loop.temperature;

    console.log(`  Initial temp: ${initialTemp}K`);
    console.log(`  Radiator area: ${loop.radiatorAreaM2} m²`);

    // Calculate expected radiation power
    const sigma = 5.67e-8; // W/(m²·K⁴)
    const emissivity = 0.9;
    const expectedPowerW = emissivity * sigma * loop.radiatorAreaM2 * Math.pow(initialTemp, 4);

    console.log(`  Expected radiation power: ${expectedPowerW.toFixed(0)}W`);

    // Simulate cooling
    for (let i = 0; i < 100; i++) {
      system.update(1.0, i);
    }

    const finalTemp = loop.temperature;

    console.log(`  After 100s: ${finalTemp.toFixed(1)}K (cooled by ${(initialTemp - finalTemp).toFixed(1)}K)`);

    this.assert(
      finalTemp < initialTemp,
      'Radiator cools via Stefan-Boltzmann radiation',
      'Temperature should decrease'
    );

    const state = system.getState();
    console.log(`  Total heat rejected: ${state.totalHeatRejected.toFixed(0)} J`);

    this.assert(
      state.totalHeatRejected > 0,
      'Heat rejection tracked',
      'Should track radiated energy'
    );

    console.log('');
  }

  /**
   * TEST 3: Flow Rate Dynamics
   * Verify flow rate depends on pump state and coolant mass
   */
  private testFlowRateDynamics(): void {
    console.log('Test 3: Flow Rate Dynamics');

    const system = new CoolantSystem();

    const loop = system.getLoop(0)!;

    console.log(`  Initial flow rate (pump off): ${loop.flowRateLPerMin} L/min`);

    this.assert(
      loop.flowRateLPerMin === 0,
      'No flow when pump is off',
      'Flow rate should be zero'
    );

    // Start pump
    system.startPump(0);
    system.update(1.0, 0);

    console.log(`  Flow rate (pump on, full): ${loop.flowRateLPerMin.toFixed(1)} L/min`);

    this.assert(
      loop.flowRateLPerMin > 0,
      'Flow starts when pump activated',
      'Should have positive flow'
    );

    this.assertClose(
      loop.flowRateLPerMin,
      loop.maxFlowRateLPerMin,
      1.0,
      'Flow rate at maximum when full'
    );

    // Reduce coolant mass to 50%
    loop.coolantMassKg = loop.maxCapacityKg * 0.5;
    system.update(1.0, 1);

    console.log(`  Flow rate (50% full): ${loop.flowRateLPerMin.toFixed(1)} L/min`);

    this.assertClose(
      loop.flowRateLPerMin,
      loop.maxFlowRateLPerMin * 0.5,
      2.0,
      'Flow rate proportional to coolant mass'
    );

    // Stop pump
    system.stopPump(0);
    system.update(1.0, 2);

    console.log(`  Flow rate (pump stopped): ${loop.flowRateLPerMin} L/min`);

    this.assert(
      loop.flowRateLPerMin === 0,
      'No flow when pump stopped',
      'Flow rate should return to zero'
    );

    console.log('');
  }

  /**
   * TEST 4: Freezing Behavior
   * Verify coolant freezes below freezing point
   */
  private testFreezingBehavior(): void {
    console.log('Test 4: Freezing Behavior');

    const system = new CoolantSystem();

    const loop = system.getLoop(0)!;
    system.startPump(0);

    console.log(`  Freezing point: ${system['freezingPoint']}K`);
    console.log(`  Initial temp: ${loop.temperature}K, frozen: ${loop.frozen}`);

    // Cool coolant below freezing
    loop.temperature = 250; // Below 253K freezing point

    system.update(1.0, 0);

    console.log(`  After cooling to 250K: frozen=${loop.frozen}, pump=${loop.pumpActive}`);

    this.assert(
      loop.frozen,
      'Coolant freezes below freezing point',
      'Should be frozen'
    );

    this.assert(
      !loop.pumpActive,
      'Pump stops when frozen',
      'Frozen pump should stop'
    );

    const events = system.getEvents();
    const freezeEvent = events.find(e => e.type === 'coolant_frozen');

    this.assert(
      freezeEvent !== undefined,
      'Freeze event generated',
      'Should log freeze event'
    );

    // Warm up
    loop.temperature = 270;
    system.update(1.0, 10);

    console.log(`  After warming to 270K: frozen=${loop.frozen}`);

    this.assert(
      !loop.frozen,
      'Coolant thaws when warmed',
      'Should not be frozen'
    );

    console.log('');
  }

  /**
   * TEST 5: Boiling Behavior
   * Verify coolant boils above boiling point
   */
  private testBoilingBehavior(): void {
    console.log('Test 5: Boiling Behavior');

    const system = new CoolantSystem();

    const loop = system.getLoop(0)!;

    console.log(`  Boiling point: ${system['boilingPoint']}K`);
    console.log(`  Initial temp: ${loop.temperature}K, boiling: ${loop.boiling}`);

    // Heat coolant above boiling
    loop.temperature = 400; // Above 393K boiling point

    system.update(1.0, 0);

    console.log(`  After heating to 400K: boiling=${loop.boiling}`);

    this.assert(
      loop.boiling,
      'Coolant boils above boiling point',
      'Should be boiling'
    );

    const events = system.getEvents();
    const boilEvent = events.find(e => e.type === 'coolant_boiling');

    this.assert(
      boilEvent !== undefined,
      'Boiling event generated',
      'Should log boiling event'
    );

    // Cool down
    loop.temperature = 370;
    system.update(1.0, 15);

    console.log(`  After cooling to 370K: boiling=${loop.boiling}`);

    this.assert(
      !loop.boiling,
      'Coolant stops boiling when cooled',
      'Should not be boiling'
    );

    console.log('');
  }

  /**
   * TEST 6: Coolant Leaks
   * Verify coolant loss from leaks
   */
  private testCoolantLeaks(): void {
    console.log('Test 6: Coolant Leak Handling');

    const system = new CoolantSystem();

    const loop = system.getLoop(0)!;
    const initialMass = loop.coolantMassKg;

    console.log(`  Initial coolant: ${initialMass}kg`);

    // Create leak: 1 L/min
    system.createLeak(0, 1.0);

    console.log(`  Leak created: 1.0 L/min`);

    // Simulate leak for 60 seconds
    for (let i = 0; i < 60; i++) {
      system.update(1.0, i);
    }

    const afterLeakMass = loop.coolantMassKg;
    const lossKg = initialMass - afterLeakMass;

    console.log(`  After 60s: ${afterLeakMass.toFixed(2)}kg (lost ${lossKg.toFixed(2)}kg)`);

    // 1 L/min for 60s = 1 liter = ~1.05 kg
    const expectedLoss = 1.05;

    this.assertClose(
      lossKg,
      expectedLoss,
      0.1,
      'Coolant loss matches leak rate'
    );

    // Repair leak
    system.repairLeak(0);
    const massBefore = loop.coolantMassKg;

    system.update(1.0, 100);

    console.log(`  After repair: ${loop.coolantMassKg.toFixed(2)}kg (no change)`);

    this.assertClose(
      loop.coolantMassKg,
      massBefore,
      0.01,
      'No more loss after repair'
    );

    console.log('');
  }

  /**
   * TEST 7: Cross-Connect Balancing
   * Verify temperature equalization between loops
   */
  private testCrossConnectBalancing(): void {
    console.log('Test 7: Cross-Connect Temperature Balancing');

    const system = new CoolantSystem();

    const loop1 = system.getLoop(0)!;
    const loop2 = system.getLoop(1)!;

    // Set different temperatures
    loop1.temperature = 330; // Hot
    loop2.temperature = 290; // Cool

    console.log(`  Initial: Loop1=${loop1.temperature}K, Loop2=${loop2.temperature}K`);
    console.log(`  Temperature difference: ${loop1.temperature - loop2.temperature}K`);

    // Open cross-connect
    system.openCrossConnect();
    console.log(`  Cross-connect opened`);

    // Simulate balancing
    for (let i = 0; i < 100; i++) {
      system.update(1.0, i);
    }

    console.log(`  After 100s: Loop1=${loop1.temperature.toFixed(1)}K, Loop2=${loop2.temperature.toFixed(1)}K`);
    console.log(`  Temperature difference: ${(loop1.temperature - loop2.temperature).toFixed(1)}K`);

    this.assert(
      Math.abs(loop1.temperature - loop2.temperature) < 20,
      'Temperatures equalize with cross-connect',
      'Should reduce temperature difference'
    );

    console.log('');
  }

  /**
   * TEST 8: Pump Power Consumption
   * Verify power draw when pumps active
   */
  private testPumpPowerConsumption(): void {
    console.log('Test 8: Pump Power Consumption');

    const system = new CoolantSystem();

    let powerDraw = system.getPumpPowerDraw();

    console.log(`  Power draw (no pumps): ${powerDraw}W`);

    this.assert(
      powerDraw === 0,
      'No power when pumps off',
      'Power should be zero'
    );

    // Start both pumps
    system.startPump(0);
    system.startPump(1);

    powerDraw = system.getPumpPowerDraw();

    const loop1 = system.getLoop(0)!;
    const loop2 = system.getLoop(1)!;
    const expectedPower = loop1.pumpPowerW + loop2.pumpPowerW;

    console.log(`  Power draw (both pumps): ${powerDraw}W (expected: ${expectedPower}W)`);

    this.assert(
      powerDraw === expectedPower,
      'Power draw matches sum of active pumps',
      'Should equal combined pump power'
    );

    // Stop one pump
    system.stopPump(1);
    powerDraw = system.getPumpPowerDraw();

    console.log(`  Power draw (one pump): ${powerDraw}W (expected: ${loop1.pumpPowerW}W)`);

    this.assert(
      powerDraw === loop1.pumpPowerW,
      'Power draw updates when pump stopped',
      'Should equal single pump power'
    );

    console.log('');
  }

  /**
   * TEST 9: Warning Generation
   * Verify warnings for various conditions
   */
  private testWarningGeneration(): void {
    console.log('Test 9: Warning Generation');

    const system = new CoolantSystem();

    const loop = system.getLoop(0)!;

    // High temperature warning
    loop.temperature = 360;
    system.update(1.0, 0);

    const events = system.getEvents();
    const highTempEvent = events.find(e => e.type === 'coolant_high_temp');

    console.log(`  High temp warning (360K): ${highTempEvent ? '✓' : '✗'}`);

    this.assert(
      highTempEvent !== undefined,
      'High temperature warning generated',
      'Should warn at high temperature'
    );

    // Low coolant warning
    system.clearEvents();
    loop.temperature = 293;
    loop.coolantMassKg = loop.maxCapacityKg * 0.2; // 20% full

    system.update(1.0, 5);

    const lowCoolantEvent = system.getEvents().find(e => e.type === 'coolant_low');

    console.log(`  Low coolant warning (20% full): ${lowCoolantEvent ? '✓' : '✗'}`);

    this.assert(
      lowCoolantEvent !== undefined,
      'Low coolant warning generated',
      'Should warn when coolant low'
    );

    // Pump failure (pump running then loses coolant)
    system.clearEvents();
    loop.coolantMassKg = 10; // Start with some coolant
    system.startPump(0);      // Start pump while there's coolant

    system.update(1.0, 6);    // Pump is running

    // Sudden coolant loss (catastrophic leak)
    loop.coolantMassKg = 0;

    system.update(1.0, 10);   // This should trigger warning

    const pumpFailEvent = system.getEvents().find(e => e.type === 'pump_failure');

    console.log(`  Pump failure warning (empty): ${pumpFailEvent ? '✓' : '✗'}`);

    this.assert(
      pumpFailEvent !== undefined,
      'Pump failure warning when empty',
      'Should warn when pump runs dry'
    );

    console.log('');
  }

  /**
   * TEST 10: Coolant Refill
   * Verify adding coolant to loops
   */
  private testCoolantRefill(): void {
    console.log('Test 10: Coolant Refill Operation');

    const system = new CoolantSystem();

    const loop = system.getLoop(0)!;
    const initialMass = loop.coolantMassKg;

    // Drain some coolant
    loop.coolantMassKg = 10;

    console.log(`  Coolant before refill: ${loop.coolantMassKg}kg`);

    // Refill
    const success = system.addCoolant(0, 15);

    console.log(`  Refill 15kg: success=${success}, new mass=${loop.coolantMassKg}kg`);

    this.assert(
      success,
      'Refill succeeds',
      'Should allow adding coolant'
    );

    this.assert(
      loop.coolantMassKg === 25,
      'Coolant mass increases correctly',
      'Should add requested amount'
    );

    // Try to overfill
    const overfillSuccess = system.addCoolant(0, 100);

    console.log(`  Overfill attempt: success=${overfillSuccess}, mass=${loop.coolantMassKg}kg`);

    this.assert(
      loop.coolantMassKg <= loop.maxCapacityKg,
      'Cannot overfill beyond capacity',
      'Should not exceed maximum'
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
      console.log('\n🎉 All tests passed!');
    } else {
      console.log('\n❌ Some tests failed');
    }
  }
}

// Run tests
const tester = new CoolantSystemTester();
tester.runAll();
