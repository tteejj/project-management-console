/**
 * Electrical System Physics Tests
 *
 * Tests validate:
 * 1. Reactor startup sequence (30 second delay)
 * 2. Reactor power generation and throttle control
 * 3. Reactor SCRAM behavior (emergency shutdown)
 * 4. Battery charge/discharge dynamics
 * 5. Capacitor bank fast charge/discharge
 * 6. Circuit breaker overcurrent protection
 * 7. Power bus load calculation
 * 8. Cross-tie load balancing
 * 9. Battery thermal effects
 * 10. Battery health degradation
 * 11. Blackout behavior
 * 12. Warning generation
 */

import { ElectricalSystem } from '../src/electrical-system';

interface TestResult {
  name: string;
  passed: boolean;
  message?: string;
  data?: any;
}

class ElectricalSystemTester {
  private results: TestResult[] = [];

  runAll(): TestResult[] {
    console.log('=== ELECTRICAL SYSTEM PHYSICS TESTS ===\n');

    this.testReactorStartup();
    this.testReactorPowerGeneration();
    this.testReactorSCRAM();
    this.testBatteryCharge();
    this.testBatteryDischarge();
    this.testCapacitorOperation();
    this.testCircuitBreakerOvercurrent();
    this.testPowerBusLoads();
    this.testCrosstie();
    this.testBatteryThermal();
    this.testBatteryHealthDegradation();
    this.testBlackout();
    this.testWarnings();

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
   * TEST 1: Reactor Startup Sequence
   * Verify 30-second startup delay before power generation
   */
  private testReactorStartup(): void {
    console.log('Test 1: Reactor Startup Sequence');

    const system = new ElectricalSystem();

    // Initially offline
    this.assert(
      system.reactor.status === 'offline',
      'Reactor starts offline',
      'Reactor should be offline initially'
    );

    // Start reactor
    const started = system.startReactor();

    this.assert(started, 'Reactor start command succeeds', 'Should accept start command');
    this.assert(
      system.reactor.status === 'starting',
      'Reactor enters starting state',
      'Should transition to starting'
    );

    console.log(`  Status after start command: ${system.reactor.status}`);

    // Simulate 10 seconds - should still be starting
    for (let i = 0; i < 10; i++) {
      system.update(1.0, i);
    }

    this.assert(
      system.reactor.status === 'starting',
      'Reactor still starting after 10 seconds',
      'Should not be online yet'
    );

    console.log(`  Status after 10 seconds: ${system.reactor.status}`);

    // Simulate to 30 seconds - should be online
    for (let i = 10; i < 30; i++) {
      system.update(1.0, i);
    }

    this.assert(
      system.reactor.status === 'online',
      'Reactor online after 30 seconds',
      'Should complete startup'
    );

    console.log(`  Status after 30 seconds: ${system.reactor.status}\n`);

    // Check for reactor_online event
    const events = system.getEvents();
    const onlineEvent = events.find(e => e.type === 'reactor_online');

    this.assert(
      onlineEvent !== undefined,
      'Reactor online event generated',
      'Should log online event'
    );
  }

  /**
   * TEST 2: Reactor Power Generation
   * Verify power output at different throttle settings
   */
  private testReactorPowerGeneration(): void {
    console.log('Test 2: Reactor Power Generation');

    const system = new ElectricalSystem();

    // Start reactor and wait for online
    system.startReactor();
    for (let i = 0; i < 31; i++) {
      system.update(1.0, i);
    }

    // Set throttle to 50%
    system.setReactorThrottle(0.5);
    system.update(1.0, 31);

    const state = system.getState();
    const expectedPower = system.reactor.maxOutputKW * 0.5;

    console.log(`  Throttle: 50%, Output: ${state.reactor.outputKW.toFixed(2)} kW (expected: ${expectedPower.toFixed(2)} kW)`);

    this.assertClose(
      state.reactor.outputKW,
      expectedPower,
      0.01,
      'Power output matches throttle setting (50%)'
    );

    // Set throttle to 100%
    system.setReactorThrottle(1.0);
    system.update(1.0, 32);

    const fullState = system.getState();
    const expectedFullPower = system.reactor.maxOutputKW;

    console.log(`  Throttle: 100%, Output: ${fullState.reactor.outputKW.toFixed(2)} kW (expected: ${expectedFullPower.toFixed(2)} kW)`);

    this.assertClose(
      fullState.reactor.outputKW,
      expectedFullPower,
      0.01,
      'Power output matches throttle setting (100%)'
    );

    // Verify heat generation
    const thermalEfficiency = system.reactor.thermalEfficiency;
    const totalEnergy = expectedFullPower / thermalEfficiency;
    const expectedWasteHeat = (totalEnergy - expectedFullPower) * 1000; // in Watts

    console.log(`  Heat generation: ${fullState.reactor.heatGenerationW.toFixed(0)} W (expected: ${expectedWasteHeat.toFixed(0)} W)\n`);

    this.assertClose(
      fullState.reactor.heatGenerationW,
      expectedWasteHeat,
      10,
      'Waste heat generation calculated correctly'
    );
  }

  /**
   * TEST 3: Reactor SCRAM
   * Verify emergency shutdown when overtemp
   */
  private testReactorSCRAM(): void {
    console.log('Test 3: Reactor SCRAM (Emergency Shutdown)');

    const system = new ElectricalSystem({
      reactor: {
        temperature: 850, // Start below SCRAM temp
        status: 'online' // Start online to skip startup delay
      }
    });

    system.setReactorThrottle(1.0);

    // Run one update to generate power
    system.update(1.0, 0);

    // Now increase temperature above SCRAM threshold
    system.reactor.temperature = 910;

    console.log(`  Temperature before update: ${system.reactor.temperature}K (SCRAM at 900K)`);

    // Update - should trigger SCRAM
    system.update(1.0, 1);

    console.log(`  Status after update: ${system.reactor.status}`);
    console.log(`  Output after SCRAM: ${system.reactor.currentOutputKW} kW`);
    console.log(`  Throttle after SCRAM: ${system.reactor.throttle}`);

    this.assert(
      system.reactor.status === 'scrammed',
      'Reactor SCRAMs when overtemp',
      'Should emergency shutdown'
    );

    this.assertClose(
      system.reactor.currentOutputKW,
      0,
      0.01,
      'Power output zero after SCRAM'
    );

    this.assertClose(
      system.reactor.throttle,
      0,
      0.01,
      'Throttle reset to zero after SCRAM'
    );

    // Check SCRAM event
    const events = system.getEvents();
    const scramEvent = events.find(e => e.type === 'reactor_scram');

    this.assert(
      scramEvent !== undefined,
      'SCRAM event generated',
      'Should log SCRAM event'
    );

    // Test reset (should fail - still hot)
    const resetSuccess = system.resetReactor();

    this.assert(
      !resetSuccess,
      'Cannot reset reactor while hot',
      'Should prevent reset when temp too high'
    );

    // Cool down and test reset
    system.reactor.temperature = 700; // below maxSafeTemp
    const resetSuccess2 = system.resetReactor();

    this.assert(
      resetSuccess2,
      'Can reset reactor when cooled',
      'Should allow reset when safe'
    );

    this.assert(
      system.reactor.status === 'offline',
      'Reactor offline after reset',
      'Should return to offline state'
    );

    console.log('');
  }

  /**
   * TEST 4: Battery Charge
   * Verify battery charges when surplus power available
   */
  private testBatteryCharge(): void {
    console.log('Test 4: Battery Charging');

    const system = new ElectricalSystem({
      battery: {
        chargeKWh: 4.0 // Half capacity
      },
      capacitorBank: {
        chargeKJ: 100, // Fully charged so battery gets the surplus
        capacityKJ: 100,
        chargeRateKW: 10,
        dischargeRateKW: 50
      }
    });

    // Start reactor and bring online
    system.startReactor();
    for (let i = 0; i < 31; i++) {
      system.update(1.0, i);
    }

    // Set throttle to generate power
    system.setReactorThrottle(1.0); // 8 kW

    // Turn off most breakers to create surplus
    for (const [key, breaker] of system.breakers) {
      if (!breaker.essential) {
        system.toggleBreaker(key, false);
      }
    }

    const initialCharge = system.battery.chargeKWh;
    console.log(`  Initial battery: ${initialCharge.toFixed(2)} kWh`);
    console.log(`  Reactor output: ${system.reactor.currentOutputKW.toFixed(2)} kW`);

    const state = system.getState();
    console.log(`  Total load: ${state.totalLoad.toFixed(2)} kW`);

    // Simulate charging for 60 seconds to see measurable change
    for (let i = 31; i < 91; i++) {
      system.update(1.0, i);
    }

    const finalCharge = system.battery.chargeKWh;
    console.log(`  After 60 seconds: ${finalCharge.toFixed(2)} kWh`);

    this.assert(
      finalCharge > initialCharge,
      'Battery charges from surplus power',
      'Charge should increase'
    );

    // Battery should not exceed capacity
    this.assert(
      finalCharge <= system.battery.capacityKWh,
      'Battery does not overcharge',
      'Should respect capacity limit'
    );

    console.log('');
  }

  /**
   * TEST 5: Battery Discharge
   * Verify battery discharges when power deficit
   */
  private testBatteryDischarge(): void {
    console.log('Test 5: Battery Discharge');

    const system = new ElectricalSystem({
      battery: {
        chargeKWh: 8.0
      },
      capacitorBank: {
        chargeKJ: 0, // Empty so battery supplies the deficit
        capacityKJ: 100,
        chargeRateKW: 10,
        dischargeRateKW: 50
      }
    });

    // Reactor offline, all systems drawing power
    const initialCharge = system.battery.chargeKWh;
    console.log(`  Initial battery: ${initialCharge.toFixed(2)} kWh`);
    console.log(`  Reactor: ${system.reactor.status}`);

    // Simulate for 10 seconds
    for (let i = 0; i < 10; i++) {
      system.update(1.0, i);
    }

    const finalCharge = system.battery.chargeKWh;
    console.log(`  After 10 seconds: ${finalCharge.toFixed(2)} kWh`);

    this.assert(
      finalCharge < initialCharge,
      'Battery discharges to supply load',
      'Charge should decrease'
    );

    // Battery should not go negative
    this.assert(
      finalCharge >= 0,
      'Battery does not go negative',
      'Should stop at zero'
    );

    console.log('');
  }

  /**
   * TEST 6: Capacitor Operation
   * Verify capacitor handles transient loads
   */
  private testCapacitorOperation(): void {
    console.log('Test 6: Capacitor Bank Operation');

    const system = new ElectricalSystem();

    const initialCapCharge = system.capacitorBank.chargeKJ;
    console.log(`  Initial capacitor: ${initialCapCharge} kJ`);

    // Create power deficit (reactor offline, loads on)
    // Capacitor should discharge first (fast)
    system.update(1.0, 0);

    const afterDeficit = system.capacitorBank.chargeKJ;
    console.log(`  After 1 second deficit: ${afterDeficit.toFixed(2)} kJ`);

    this.assert(
      afterDeficit < initialCapCharge,
      'Capacitor discharges during deficit',
      'Should supply power during deficit'
    );

    // Now create surplus (start reactor, disable loads)
    system.startReactor();
    for (let i = 0; i < 31; i++) {
      system.update(1.0, i);
    }

    system.setReactorThrottle(1.0);

    for (const [key, breaker] of system.breakers) {
      if (!breaker.essential) {
        system.toggleBreaker(key, false);
      }
    }

    const beforeCharge = system.capacitorBank.chargeKJ;
    console.log(`  Before surplus charging: ${beforeCharge.toFixed(2)} kJ`);

    system.update(1.0, 31);

    const afterCharge = system.capacitorBank.chargeKJ;
    console.log(`  After 1 second surplus: ${afterCharge.toFixed(2)} kJ`);

    this.assert(
      afterCharge > beforeCharge,
      'Capacitor charges from surplus',
      'Should charge during surplus'
    );

    console.log('');
  }

  /**
   * TEST 7: Circuit Breaker Overcurrent Protection
   * Verify breakers trip when overcurrent detected
   */
  private testCircuitBreakerOvercurrent(): void {
    console.log('Test 7: Circuit Breaker Overcurrent Protection');

    const system = new ElectricalSystem();

    // Create a breaker that will trip (high load, low threshold)
    system.breakers.set('test_breaker', {
      name: 'Test',
      bus: 'A',
      on: true,
      loadW: 1000, // 1000W
      essential: false,
      tripThreshold: 20, // 20 amps
      tripped: false
    });

    console.log('  Added test breaker: 1000W load, 20A threshold');

    // Calculate current: I = P / V = 1000W / 28V = 35.7A (exceeds 20A threshold)
    const voltage = system.buses[0].voltage;
    const expectedCurrent = 1000 / voltage;
    console.log(`  Expected current: ${expectedCurrent.toFixed(1)}A (threshold: 20A)`);

    // Update should trip the breaker
    system.update(1.0, 0);

    const breaker = system.breakers.get('test_breaker')!;

    console.log(`  Breaker tripped: ${breaker.tripped}`);
    console.log(`  Breaker on: ${breaker.on}`);

    this.assert(
      breaker.tripped,
      'Breaker trips on overcurrent',
      'Should trip when current exceeds threshold'
    );

    this.assert(
      !breaker.on,
      'Breaker opens when tripped',
      'Should turn off when tripped'
    );

    // Check for trip event
    const events = system.getEvents();
    const tripEvent = events.find(e => e.type === 'breaker_tripped');

    this.assert(
      tripEvent !== undefined,
      'Breaker trip event generated',
      'Should log trip event'
    );

    console.log('');
  }

  /**
   * TEST 8: Power Bus Load Calculation
   * Verify bus loads calculated correctly
   */
  private testPowerBusLoads(): void {
    console.log('Test 8: Power Bus Load Calculation');

    const system = new ElectricalSystem();

    // Calculate expected loads
    let expectedBusA = 0;
    let expectedBusB = 0;

    for (const [key, breaker] of system.breakers) {
      if (breaker.on && !breaker.tripped) {
        if (breaker.bus === 'A') {
          expectedBusA += breaker.loadW / 1000;
        } else {
          expectedBusB += breaker.loadW / 1000;
        }
      }
    }

    system.update(1.0, 0);

    const state = system.getState();
    const busA = state.buses.find(b => b.name === 'A')!;
    const busB = state.buses.find(b => b.name === 'B')!;

    console.log(`  Bus A: ${busA.loadKW.toFixed(2)} kW (expected: ${expectedBusA.toFixed(2)} kW)`);
    console.log(`  Bus B: ${busB.loadKW.toFixed(2)} kW (expected: ${expectedBusB.toFixed(2)} kW)`);

    this.assertClose(
      busA.loadKW,
      expectedBusA,
      0.01,
      'Bus A load calculated correctly'
    );

    this.assertClose(
      busB.loadKW,
      expectedBusB,
      0.01,
      'Bus B load calculated correctly'
    );

    console.log('');
  }

  /**
   * TEST 9: Cross-tie Operation
   * Verify cross-tie balances loads between buses
   */
  private testCrosstie(): void {
    console.log('Test 9: Power Bus Cross-tie');

    const system = new ElectricalSystem();

    // Get initial loads
    system.update(1.0, 0);
    const beforeState = system.getState();
    const busABefore = beforeState.buses.find(b => b.name === 'A')!;
    const busBBefore = beforeState.buses.find(b => b.name === 'B')!;

    console.log(`  Before cross-tie:`);
    console.log(`    Bus A: ${busABefore.loadKW.toFixed(2)} kW`);
    console.log(`    Bus B: ${busBBefore.loadKW.toFixed(2)} kW`);

    // Enable cross-tie
    system.setCrosstie(true);
    system.update(1.0, 1);

    const afterState = system.getState();
    const busAAfter = afterState.buses.find(b => b.name === 'A')!;
    const busBAfter = afterState.buses.find(b => b.name === 'B')!;

    console.log(`  After cross-tie:`);
    console.log(`    Bus A: ${busAAfter.loadKW.toFixed(2)} kW`);
    console.log(`    Bus B: ${busBAfter.loadKW.toFixed(2)} kW`);

    // Loads should be balanced (equal)
    this.assertClose(
      busAAfter.loadKW,
      busBAfter.loadKW,
      0.01,
      'Cross-tie balances bus loads'
    );

    // Total load should be conserved
    const totalBefore = busABefore.loadKW + busBBefore.loadKW;
    const totalAfter = busAAfter.loadKW + busBAfter.loadKW;

    this.assertClose(
      totalAfter,
      totalBefore,
      0.01,
      'Total load conserved with cross-tie'
    );

    console.log('');
  }

  /**
   * TEST 10: Battery Thermal Effects
   * Verify battery temperature changes during charge/discharge
   */
  private testBatteryThermal(): void {
    console.log('Test 10: Battery Thermal Effects');

    const system = new ElectricalSystem({
      battery: {
        chargeKWh: 4.0,
        temperature: 293 // Room temp
      }
    });

    const initialTemp = system.battery.temperature;
    console.log(`  Initial temperature: ${initialTemp.toFixed(1)}K`);

    // Discharge battery (reactor off, loads on)
    for (let i = 0; i < 30; i++) {
      system.update(1.0, i);
    }

    const tempAfterDischarge = system.battery.temperature;
    console.log(`  After 30s discharge: ${tempAfterDischarge.toFixed(1)}K`);

    this.assert(
      tempAfterDischarge > initialTemp,
      'Battery heats up during discharge',
      'Inefficiency generates heat'
    );

    // Let it cool down - turn off ALL loads (including essential) for testing
    for (const [key, breaker] of system.breakers) {
      breaker.on = false; // Directly set to bypass essential protection
    }

    for (let i = 30; i < 60; i++) {
      system.update(1.0, i);
    }

    const tempAfterCooling = system.battery.temperature;
    console.log(`  After 30s passive cooling: ${tempAfterCooling.toFixed(1)}K`);

    this.assert(
      tempAfterCooling < tempAfterDischarge,
      'Battery cools down passively',
      'Should cool toward ambient'
    );

    console.log('');
  }

  /**
   * TEST 11: Battery Health Degradation
   * Verify battery health degrades after charge cycles
   */
  private testBatteryHealthDegradation(): void {
    console.log('Test 11: Battery Health Degradation');

    const system = new ElectricalSystem({
      battery: {
        chargeCycles: 499, // Start near degradation threshold
        health: 100,
        chargeKWh: 0.5, // Start at 50% of reduced capacity
        capacityKWh: 1.0, // Much smaller battery for faster cycling
        maxChargeRateKW: 2.0,
        maxDischargeRateKW: 3.5
      }
    });

    console.log(`  Initial health: ${system.battery.health}%, cycles: ${system.battery.chargeCycles.toFixed(1)}`);

    // Simulate many charge cycles
    // Each full charge/discharge cycle increments by 1.0 (0.5 for charge + 0.5 for discharge)
    // We need to exceed 500 cycles to see degradation

    // Set up for rapid cycling (start reactor, cycle loads)
    system.startReactor();
    for (let i = 0; i < 31; i++) {
      system.update(1.0, i);
    }
    system.setReactorThrottle(1.0);

    // Run for extended time to accumulate cycles
    for (let i = 0; i < 10000; i++) {
      // Alternate between charging and discharging
      if (i % 100 < 50) {
        // Charging phase - turn off loads
        for (const [key, breaker] of system.breakers) {
          if (!breaker.essential) {
            system.toggleBreaker(key, false);
          }
        }
      } else {
        // Discharging phase - turn on loads
        for (const [key, breaker] of system.breakers) {
          if (!breaker.essential && !breaker.tripped) {
            system.toggleBreaker(key, true);
          }
        }
      }

      system.update(1.0, 31 + i);
    }

    console.log(`  After extended operation: health: ${system.battery.health.toFixed(1)}%, cycles: ${system.battery.chargeCycles.toFixed(1)}`);

    this.assert(
      system.battery.chargeCycles > 500,
      'Charge cycles accumulate over time',
      'Should track cycles'
    );

    this.assert(
      system.battery.health < 100,
      'Battery health degrades after 500 cycles',
      'Health should decrease'
    );

    console.log('');
  }

  /**
   * TEST 12: Blackout Behavior
   * Verify non-essential breakers trip during blackout
   */
  private testBlackout(): void {
    console.log('Test 12: Blackout Behavior');

    const system = new ElectricalSystem({
      battery: {
        chargeKWh: 0.001 // Nearly depleted
      },
      capacitorBank: {
        chargeKJ: 0, // Empty so battery drains faster
        capacityKJ: 100,
        chargeRateKW: 10,
        dischargeRateKW: 50
      }
    });

    // Reactor offline, high load will drain battery quickly
    console.log(`  Initial battery: ${system.battery.chargeKWh.toFixed(2)} kWh`);
    console.log(`  Reactor: ${system.reactor.status}`);

    // Count non-essential breakers that are on
    let nonEssentialOnBefore = 0;
    for (const [key, breaker] of system.breakers) {
      if (!breaker.essential && breaker.on) {
        nonEssentialOnBefore++;
      }
    }

    console.log(`  Non-essential breakers on: ${nonEssentialOnBefore}`);

    // Run until blackout
    for (let i = 0; i < 100; i++) {
      system.update(1.0, i);
      if (system.battery.chargeKWh <= 0) {
        break;
      }
    }

    console.log(`  Battery after drain: ${system.battery.chargeKWh.toFixed(2)} kWh`);

    // Count non-essential breakers after blackout
    let nonEssentialOnAfter = 0;
    for (const [key, breaker] of system.breakers) {
      if (!breaker.essential && breaker.on) {
        nonEssentialOnAfter++;
      }
    }

    console.log(`  Non-essential breakers on after blackout: ${nonEssentialOnAfter}`);

    this.assert(
      nonEssentialOnAfter < nonEssentialOnBefore,
      'Blackout trips non-essential breakers',
      'Should shed non-essential loads'
    );

    // Essential breakers should still be on
    const o2Gen = system.breakers.get('o2_generator')!;
    const co2Scrub = system.breakers.get('co2_scrubber')!;

    this.assert(
      o2Gen.on,
      'Essential breakers remain on (O2 Gen)',
      'Should protect essential systems'
    );

    this.assert(
      co2Scrub.on,
      'Essential breakers remain on (CO2 Scrubber)',
      'Should protect essential systems'
    );

    // Check for blackout event
    const events = system.getEvents();
    const blackoutEvent = events.find(e => e.type === 'blackout');

    this.assert(
      blackoutEvent !== undefined,
      'Blackout event generated',
      'Should log blackout event'
    );

    console.log('');
  }

  /**
   * TEST 13: Warning Generation
   * Verify system generates appropriate warnings
   */
  private testWarnings(): void {
    console.log('Test 13: Warning Generation');

    // Test low battery warning
    const system1 = new ElectricalSystem({
      battery: {
        chargeKWh: 1.0 // < 20% of 12 kWh capacity
      }
    });

    system1.update(1.0, 0);
    system1.update(1.0, 1);

    const lowBattEvent = system1.getEvents().find(e => e.type === 'battery_low');

    this.assert(
      lowBattEvent !== undefined,
      'Low battery warning generated',
      'Should warn when battery < 20%'
    );

    console.log(`  Low battery warning: ✓`);

    // Test reactor overtemp warning
    const system2 = new ElectricalSystem({
      reactor: {
        temperature: 850, // above maxSafeTemp (800K) but below SCRAM (900K)
        status: 'online'
      }
    });

    system2.update(1.0, 0);
    system2.update(1.0, 1);

    const overtempEvent = system2.getEvents().find(e => e.type === 'reactor_overtemp');

    this.assert(
      overtempEvent !== undefined,
      'Reactor overtemp warning generated',
      'Should warn when temp > maxSafeTemp'
    );

    console.log(`  Reactor overtemp warning: ✓`);

    // Test battery overtemp warning
    const system3 = new ElectricalSystem({
      battery: {
        temperature: 330 // above warning threshold (320K)
      }
    });

    system3.update(1.0, 0);
    system3.update(1.0, 1);

    const battOvertempEvent = system3.getEvents().find(e => e.type === 'battery_overtemp');

    this.assert(
      battOvertempEvent !== undefined,
      'Battery overtemp warning generated',
      'Should warn when battery too hot'
    );

    console.log(`  Battery overtemp warning: ✓`);

    // Test bus overload warning
    const system4 = new ElectricalSystem();

    // Add high loads to exceed bus capacity
    system4.breakers.set('heavy_load_1', {
      name: 'Heavy1',
      bus: 'A',
      on: true,
      loadW: 3000,
      essential: false,
      tripThreshold: 200,
      tripped: false
    });

    system4.breakers.set('heavy_load_2', {
      name: 'Heavy2',
      bus: 'A',
      on: true,
      loadW: 3000,
      essential: false,
      tripThreshold: 200,
      tripped: false
    });

    system4.update(1.0, 0);
    system4.update(1.0, 1);

    const overloadEvent = system4.getEvents().find(e => e.type === 'bus_overload');

    this.assert(
      overloadEvent !== undefined,
      'Bus overload warning generated',
      'Should warn when bus exceeds capacity'
    );

    console.log(`  Bus overload warning: ✓`);

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
const tester = new ElectricalSystemTester();
tester.runAll();
