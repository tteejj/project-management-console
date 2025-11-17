/**
 * Thermal System Physics Tests
 *
 * Tests validate:
 * 1. Component temperature rise from heat generation (Q = mcΔT)
 * 2. Heat transfer to compartment air
 * 3. Thermal conduction between compartments
 * 4. Overheating warnings
 * 5. Heat tracking and accumulation
 * 6. Temperature equilibration
 */

import { ThermalSystem } from '../src/thermal-system';

interface TestResult {
  name: string;
  passed: boolean;
  message?: string;
  data?: any;
}

class ThermalSystemTester {
  private results: TestResult[] = [];

  runAll(): TestResult[] {
    console.log('=== THERMAL SYSTEM PHYSICS TESTS ===\n');

    this.testComponentHeating();
    this.testHeatTransferToCompartment();
    this.testCompartmentConduction();
    this.testOverheatingWarnings();
    this.testHeatAccumulation();
    this.testTemperatureEquilibration();
    this.testMultipleHeatSources();

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
   * TEST 1: Component Heating
   * Verify Q = m*c*ΔT for component temperature rise
   */
  private testComponentHeating(): void {
    console.log('Test 1: Component Temperature Rise from Heat Generation');

    const system = new ThermalSystem();

    const reactor = system.getComponent('reactor')!;
    const initialTemp = reactor.temperature;

    console.log(`  Initial reactor temp: ${initialTemp}K`);

    // Generate 10kW for 10 seconds
    system.setHeatGeneration('reactor', 10000); // 10kW

    for (let i = 0; i < 10; i++) {
      system.update(1.0, i);
    }

    const finalTemp = reactor.temperature;

    console.log(`  After 10kW for 10s: ${finalTemp.toFixed(1)}K`);

    // Calculate expected temperature rise
    // Q = P * t = 10000W * 10s = 100000 J
    // ΔT = Q / (m * c) = 100000 / (200 * 450) = 1.11K
    const energyJ = 10000 * 10;
    const expectedDeltaT = energyJ / (reactor.mass * reactor.specificHeat);
    const expectedTemp = initialTemp + expectedDeltaT;

    console.log(`  Expected: ${expectedTemp.toFixed(1)}K (ΔT = ${expectedDeltaT.toFixed(2)}K)`);

    this.assert(
      finalTemp > initialTemp,
      'Component heats up with heat generation',
      'Temperature should increase'
    );

    this.assertClose(
      finalTemp,
      expectedTemp,
      5.0, // Allow some tolerance for heat transfer to compartment
      'Temperature rise matches Q = mcΔT'
    );

    console.log('');
  }

  /**
   * TEST 2: Heat Transfer to Compartment
   * Verify heat flows from hot component to cooler compartment
   */
  private testHeatTransferToCompartment(): void {
    console.log('Test 2: Heat Transfer to Compartment Air');

    const system = new ThermalSystem({
      heatSources: [{
        name: 'test_heater',
        heatGenerationW: 5000, // 5kW constant
        temperature: 400, // Hot component
        mass: 50,
        specificHeat: 500,
        compartmentId: 0
      }],
      compartments: [{
        id: 0,
        name: 'Test',
        volume: 30,
        gasMass: 36,
        temperature: 293, // Cool air
        neighborIds: []
      }]
    });

    const component = system.getComponent('test_heater')!;
    const compartment = system.getCompartment(0)!;

    const initialCompTemp = component.temperature;
    const initialAirTemp = compartment.temperature;

    console.log(`  Initial: Component=${initialCompTemp}K, Air=${initialAirTemp}K`);

    // Simulate heat transfer
    for (let i = 0; i < 30; i++) {
      system.update(1.0, i);
    }

    const finalCompTemp = component.temperature;
    const finalAirTemp = compartment.temperature;

    console.log(`  After 30s: Component=${finalCompTemp.toFixed(1)}K, Air=${finalAirTemp.toFixed(1)}K`);

    this.assert(
      finalAirTemp > initialAirTemp,
      'Compartment air heats up',
      'Should absorb heat from hot component'
    );

    this.assert(
      finalCompTemp < initialCompTemp + 150, // With cooling, shouldn't runaway
      'Component temperature stabilizes',
      'Heat transfer prevents runaway heating'
    );

    console.log('');
  }

  /**
   * TEST 3: Thermal Conduction Between Compartments
   * Verify heat flows between adjacent compartments
   */
  private testCompartmentConduction(): void {
    console.log('Test 3: Thermal Conduction Between Compartments');

    const system = new ThermalSystem({
      compartments: [
        {
          id: 0,
          name: 'Hot',
          volume: 30,
          gasMass: 36,
          temperature: 350, // Hot
          neighborIds: [1]
        },
        {
          id: 1,
          name: 'Cold',
          volume: 30,
          gasMass: 36,
          temperature: 250, // Cold
          neighborIds: [0]
        }
      ]
    });

    const hot = system.getCompartment(0)!;
    const cold = system.getCompartment(1)!;

    const initialHot = hot.temperature;
    const initialCold = cold.temperature;

    console.log(`  Initial: Hot=${initialHot}K, Cold=${initialCold}K`);
    console.log(`  Temperature difference: ${initialHot - initialCold}K`);

    // Simulate conduction
    for (let i = 0; i < 100; i++) {
      system.update(1.0, i);
    }

    const finalHot = hot.temperature;
    const finalCold = cold.temperature;

    console.log(`  After 100s: Hot=${finalHot.toFixed(1)}K, Cold=${finalCold.toFixed(1)}K`);
    console.log(`  Temperature difference: ${(finalHot - finalCold).toFixed(1)}K`);

    this.assert(
      finalHot < initialHot,
      'Hot compartment cools',
      'Should lose heat'
    );

    this.assert(
      finalCold > initialCold,
      'Cold compartment warms',
      'Should gain heat'
    );

    this.assert(
      (finalHot - finalCold) < (initialHot - initialCold),
      'Temperature difference decreases',
      'Compartments equilibrate'
    );

    console.log('');
  }

  /**
   * TEST 4: Overheating Warnings
   * Verify warnings generated when components overheat
   */
  private testOverheatingWarnings(): void {
    console.log('Test 4: Overheating Warnings');

    const system = new ThermalSystem();

    // Heat battery beyond its limit (330K)
    // Battery: 80kg * 800 J/(kg·K) = 64,000 J/K thermal mass
    // To reach 330K from 293K = 37K rise = 2,368,000 J needed
    // Use 150kW for 20s to ensure we exceed the limit
    system.setHeatGeneration('battery', 150000);

    for (let i = 0; i < 20; i++) {
      system.update(1.0, i);
    }

    const battery = system.getComponent('battery')!;
    console.log(`  Battery temperature: ${battery.temperature.toFixed(1)}K (limit: 330K)`);

    const events = system.getEvents();
    const overheatEvent = events.find(e => e.type === 'component_overheating' && e.data.component === 'battery');

    this.assert(
      overheatEvent !== undefined,
      'Overheating warning generated',
      'Should warn when component exceeds limit'
    );

    if (overheatEvent) {
      console.log(`  Warning at ${overheatEvent.data.temperature.toFixed(1)}K`);
    }

    console.log('');
  }

  /**
   * TEST 5: Heat Accumulation Tracking
   * Verify total heat generation is tracked
   */
  private testHeatAccumulation(): void {
    console.log('Test 5: Heat Accumulation Tracking');

    const system = new ThermalSystem();

    // Generate known amount of heat
    system.setHeatGeneration('reactor', 8000); // 8kW

    const duration = 10; // seconds

    for (let i = 0; i < duration; i++) {
      system.update(1.0, i);
    }

    const state = system.getState();
    const totalHeat = state.totalHeatGenerated;

    const expectedHeat = 8000 * duration; // 80000 J

    console.log(`  Generated: ${totalHeat} J`);
    console.log(`  Expected: ${expectedHeat} J`);

    this.assertClose(
      totalHeat,
      expectedHeat,
      100,
      'Heat accumulation tracked correctly'
    );

    console.log('');
  }

  /**
   * TEST 6: Temperature Equilibration
   * Verify system reaches thermal equilibrium
   */
  private testTemperatureEquilibration(): void {
    console.log('Test 6: Temperature Equilibration');

    const system = new ThermalSystem({
      heatSources: [{
        name: 'steady_heater',
        heatGenerationW: 1000, // Steady 1kW
        temperature: 293,
        mass: 100,
        specificHeat: 500,
        compartmentId: 0
      }],
      compartments: [{
        id: 0,
        name: 'Test',
        volume: 50,
        gasMass: 60,
        temperature: 293,
        neighborIds: []
      }]
    });

    const component = system.getComponent('steady_heater')!;
    const compartment = system.getCompartment(0)!;

    // Run for extended period
    const temps: number[] = [];

    for (let i = 0; i < 200; i++) {
      system.update(1.0, i);

      if (i % 50 === 0) {
        temps.push(component.temperature);
      }
    }

    console.log('  Component temperatures over time:');
    temps.forEach((t, i) => {
      console.log(`    t=${i * 50}s: ${t.toFixed(1)}K`);
    });

    // Check if temperature stabilizes (rate of change decreases)
    const tempChange1 = temps[1] - temps[0]; // 0-50s
    const tempChange2 = temps[3] - temps[2]; // 100-150s

    console.log(`  Rate of change: Early=${tempChange1.toFixed(2)}K/50s, Late=${tempChange2.toFixed(2)}K/50s`);

    this.assert(
      Math.abs(tempChange2) < Math.abs(tempChange1),
      'Temperature stabilizes over time',
      'Rate of change should decrease'
    );

    console.log('');
  }

  /**
   * TEST 7: Multiple Heat Sources
   * Verify multiple components can generate heat simultaneously
   */
  private testMultipleHeatSources(): void {
    console.log('Test 7: Multiple Heat Sources in Same Compartment');

    const system = new ThermalSystem();

    const compartment = system.getCompartment(1)!; // Engineering
    const initialTemp = compartment.temperature;

    console.log(`  Initial compartment temp: ${initialTemp}K`);

    // Multiple components generating heat in Engineering
    // Use high power levels to demonstrate significant heating
    system.setHeatGeneration('reactor', 20000);
    system.setHeatGeneration('hydraulic_pump_1', 2000);
    system.setHeatGeneration('hydraulic_pump_2', 2000);
    system.setHeatGeneration('coolant_pump_1', 2000);

    const totalPower = 20000 + 2000 + 2000 + 2000; // 26kW

    console.log(`  Total heat generation: ${totalPower}W`);

    // Run for longer to allow heat transfer from components to air
    for (let i = 0; i < 200; i++) {
      system.update(1.0, i);
    }

    const finalTemp = compartment.temperature;

    console.log(`  After 200s: ${finalTemp.toFixed(1)}K (ΔT = ${(finalTemp - initialTemp).toFixed(1)}K)`);

    this.assert(
      finalTemp > initialTemp,
      'Compartment heats from multiple sources',
      'Should accumulate heat'
    );

    this.assert(
      finalTemp > initialTemp + 5,
      'Significant heating from multiple sources',
      'Combined heat should be noticeable'
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
const tester = new ThermalSystemTester();
tester.runAll();
