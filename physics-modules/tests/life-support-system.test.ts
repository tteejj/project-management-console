/**
 * Life Support System Tests
 */

import { LifeSupportSystem } from '../src/life-support-system';

export function runLifeSupportTests() {
  const tests: { name: string; fn: () => boolean }[] = [];

  // Test 1: Initialization with default compartments
  tests.push({
    name: 'Has 6 default compartments',
    fn: () => {
      const ls = new LifeSupportSystem();
      const state = ls.getState();
      return state.compartments.length === 6;
    }
  });

  // Test 2: Initial atmosphere is Earth-like
  tests.push({
    name: 'Initial O2 ~21%',
    fn: () => {
      const ls = new LifeSupportSystem();
      const state = ls.getState();
      const centerComp = state.compartments.find(c => c.id === 'center');
      return centerComp && Math.abs(centerComp.o2Percent - 21) < 1;
    }
  });

  // Test 3: Initial pressure ~101 kPa
  tests.push({
    name: 'Initial pressure ~101 kPa',
    fn: () => {
      const ls = new LifeSupportSystem();
      const state = ls.getState();
      const centerComp = state.compartments.find(c => c.id === 'center');
      return centerComp && Math.abs(centerComp.pressureKPa - 101) < 5;
    }
  });

  // Test 4: O2 generation increases O2
  tests.push({
    name: 'O2 generator increases O2',
    fn: () => {
      const ls = new LifeSupportSystem();
      const stateBefore = ls.getState();
      const initialO2 = stateBefore.compartments.reduce((sum, c) => sum + (c.volume * c.o2Percent / 100), 0);

      ls.o2GeneratorActive = true;
      for (let i = 0; i < 100; i++) {
        ls.update(0.1);
      }

      const stateAfter = ls.getState();
      const finalO2 = stateAfter.compartments.reduce((sum, c) => sum + (c.volume * c.o2Percent / 100), 0);

      return finalO2 > initialO2;
    }
  });

  // Test 5: O2 reserves deplete
  tests.push({
    name: 'O2 reserves deplete during generation',
    fn: () => {
      const ls = new LifeSupportSystem();
      const initialReserves = ls.getState().o2Generator.reservesKg;

      ls.o2GeneratorActive = true;
      for (let i = 0; i < 100; i++) {
        ls.update(0.1);
      }

      const finalReserves = ls.getState().o2Generator.reservesKg;
      return finalReserves < initialReserves;
    }
  });

  // Test 6: CO2 scrubbing reduces CO2
  tests.push({
    name: 'CO2 scrubber reduces CO2',
    fn: () => {
      const ls = new LifeSupportSystem();

      // Add CO2 to a compartment
      const centerComp = ls.compartments.find(c => c.id === 'center');
      if (!centerComp) return false;
      centerComp.co2Mass = 5.0; // Add 5kg CO2

      const initialCO2 = centerComp.co2Mass;

      ls.co2ScrubberActive = true;
      for (let i = 0; i < 100; i++) {
        ls.update(0.1);
      }

      const finalCO2 = centerComp.co2Mass;
      return finalCO2 < initialCO2;
    }
  });

  // Test 7: Fire consumes O2
  tests.push({
    name: 'Fire consumes O2',
    fn: () => {
      const ls = new LifeSupportSystem();
      const comp = ls.compartments.find(c => c.id === 'center');
      if (!comp) return false;

      const initialO2 = comp.o2Mass;
      ls.startFire('center', 50);

      for (let i = 0; i < 100; i++) {
        ls.update(0.1);
      }

      return comp.o2Mass < initialO2;
    }
  });

  // Test 8: Fire produces CO2
  tests.push({
    name: 'Fire produces CO2',
    fn: () => {
      const ls = new LifeSupportSystem();
      const comp = ls.compartments.find(c => c.id === 'center');
      if (!comp) return false;

      const initialCO2 = comp.co2Mass;
      ls.startFire('center', 50);

      for (let i = 0; i < 100; i++) {
        ls.update(0.1);
      }

      return comp.co2Mass > initialCO2;
    }
  });

  // Test 9: Fire spreads if O2 available
  tests.push({
    name: 'Fire intensity increases with O2',
    fn: () => {
      const ls = new LifeSupportSystem();
      ls.startFire('center', 10);

      const initialIntensity = ls.compartments.find(c => c.id === 'center')?.fireIntensity || 0;

      for (let i = 0; i < 50; i++) {
        ls.update(0.1);
      }

      const finalIntensity = ls.compartments.find(c => c.id === 'center')?.fireIntensity || 0;
      return finalIntensity > initialIntensity;
    }
  });

  // Test 10: Fire dies with low O2
  tests.push({
    name: 'Fire dies when O2 depleted',
    fn: () => {
      const ls = new LifeSupportSystem();
      const comp = ls.compartments.find(c => c.id === 'center');
      if (!comp) return false;

      // Remove most O2
      comp.o2Mass = 0.5;
      ls.startFire('center', 50);

      for (let i = 0; i < 200; i++) {
        ls.update(0.1);
      }

      return !comp.onFire || comp.fireIntensity < 10;
    }
  });

  // Test 11: Fire suppression works
  tests.push({
    name: 'Fire suppression reduces intensity',
    fn: () => {
      const ls = new LifeSupportSystem();
      ls.startFire('center', 80);

      const initialIntensity = ls.compartments.find(c => c.id === 'center')?.fireIntensity || 0;
      ls.fireSuppress('center');

      const finalIntensity = ls.compartments.find(c => c.id === 'center')?.fireIntensity || 0;
      return finalIntensity < initialIntensity;
    }
  });

  // Test 12: Fire suppression uses Halon
  tests.push({
    name: 'Fire suppression depletes Halon',
    fn: () => {
      const ls = new LifeSupportSystem();
      ls.startFire('center', 80);

      const initialHalon = ls.getState().halon.remainingKg;
      ls.fireSuppress('center');
      const finalHalon = ls.getState().halon.remainingKg;

      return finalHalon < initialHalon;
    }
  });

  // Test 13: Hull breach vents atmosphere
  tests.push({
    name: 'Hull breach vents atmosphere',
    fn: () => {
      const ls = new LifeSupportSystem();
      const comp = ls.compartments.find(c => c.id === 'center');
      if (!comp) return false;

      const initialPressure = ls.getPressureKPa(comp);
      ls.causeBreach('center', 0.01); // 10cm² hole

      for (let i = 0; i < 100; i++) {
        ls.update(0.1);
      }

      const finalPressure = ls.getPressureKPa(comp);
      return finalPressure < initialPressure;
    }
  });

  // Test 14: Emergency vent removes all atmosphere
  tests.push({
    name: 'Emergency vent removes atmosphere',
    fn: () => {
      const ls = new LifeSupportSystem();
      ls.emergencyVent('center');

      const state = ls.getState();
      const comp = state.compartments.find(c => c.id === 'center');

      return comp && comp.pressureKPa < 1;
    }
  });

  // Test 15: Emergency vent kills fire
  tests.push({
    name: 'Emergency vent extinguishes fire',
    fn: () => {
      const ls = new LifeSupportSystem();
      ls.startFire('center', 80);
      ls.emergencyVent('center');

      const comp = ls.compartments.find(c => c.id === 'center');
      return comp && !comp.onFire;
    }
  });

  // Test 16: Door toggle works
  tests.push({
    name: 'Door can be opened/closed',
    fn: () => {
      const ls = new LifeSupportSystem();
      const comp = ls.compartments.find(c => c.id === 'center');
      if (!comp) return false;

      const conn = comp.connections.find(c => c.compartmentId === 'bow');
      if (!conn) return false;

      const initialState = conn.doorOpen;
      ls.toggleDoor('center', 'bow');
      const newState = conn.doorOpen;

      return initialState !== newState;
    }
  });

  // Test 17: Gas equalization with open doors
  tests.push({
    name: 'Atmosphere equalizes between compartments',
    fn: () => {
      const ls = new LifeSupportSystem();
      const bow = ls.compartments.find(c => c.id === 'bow');
      const center = ls.compartments.find(c => c.id === 'center');
      if (!bow || !center) return false;

      // Create pressure difference
      bow.o2Mass = 10.0;
      center.o2Mass = 2.0;

      const initialDiff = Math.abs(bow.o2Mass - center.o2Mass);

      // Equalize for a while
      for (let i = 0; i < 100; i++) {
        ls.update(0.1);
      }

      const finalDiff = Math.abs(bow.o2Mass - center.o2Mass);
      return finalDiff < initialDiff;
    }
  });

  // Test 18: Closed doors prevent equalization
  tests.push({
    name: 'Closed doors block gas flow',
    fn: () => {
      const ls = new LifeSupportSystem();
      const bow = ls.compartments.find(c => c.id === 'bow');
      const center = ls.compartments.find(c => c.id === 'center');
      if (!bow || !center) return false;

      // Close door
      ls.toggleDoor('bow', 'center');

      // Create pressure difference
      bow.o2Mass = 10.0;
      center.o2Mass = 2.0;

      const initialBowO2 = bow.o2Mass;

      // Try to equalize
      for (let i = 0; i < 50; i++) {
        ls.update(0.1);
      }

      // Should be roughly the same (allowing tiny floating point drift)
      return Math.abs(bow.o2Mass - initialBowO2) < 0.1;
    }
  });

  // Test 19: Breach seal stops venting
  tests.push({
    name: 'Sealing breach stops atmosphere loss',
    fn: () => {
      const ls = new LifeSupportSystem();
      ls.causeBreach('center', 0.01);

      // Vent for a bit
      for (let i = 0; i < 50; i++) {
        ls.update(0.1);
      }

      const comp = ls.compartments.find(c => c.id === 'center');
      if (!comp) return false;

      // Seal breach
      ls.sealBreach('center');
      const pressureAfterSeal = ls.getPressureKPa(comp);

      // Continue simulation
      for (let i = 0; i < 50; i++) {
        ls.update(0.1);
      }

      const finalPressure = ls.getPressureKPa(comp);

      // Pressure should stay roughly constant (allowing for minor equalization)
      return Math.abs(finalPressure - pressureAfterSeal) < 2;
    }
  });

  // Test 20: Scrubber media degrades
  tests.push({
    name: 'Scrubber media degrades with use',
    fn: () => {
      const ls = new LifeSupportSystem();

      // Add CO2
      for (const comp of ls.compartments) {
        comp.co2Mass = 2.0;
      }

      const initialMedia = ls.getState().co2Scrubber.mediaPercent;

      ls.co2ScrubberActive = true;
      for (let i = 0; i < 500; i++) {
        ls.update(0.1);
      }

      const finalMedia = ls.getState().co2Scrubber.mediaPercent;
      return finalMedia < initialMedia;
    }
  });

  // Run all tests
  let passed = 0;
  let failed = 0;

  for (const test of tests) {
    try {
      const result = test.fn();
      if (result) {
        console.log(`✓ ${test.name}: PASS`);
        passed++;
      } else {
        console.log(`✗ ${test.name}: FAIL`);
        failed++;
      }
    } catch (error) {
      console.log(`✗ ${test.name}: ERROR - ${error}`);
      failed++;
    }
  }

  console.log(`\n${passed} passed, ${failed} failed (${tests.length} total)\n`);

  return { passed, failed, total: tests.length };
}

// Auto-run if executed directly
if (require.main === module) {
  runLifeSupportTests();
}
