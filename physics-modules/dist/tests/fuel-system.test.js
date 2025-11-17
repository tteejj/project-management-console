"use strict";
/**
 * Fuel System Physics Tests
 *
 * Tests validate:
 * 1. Pressure dynamics (pressurant expansion)
 * 2. Fuel consumption
 * 3. Center of mass calculation
 * 4. Crossfeed operation
 * 5. Venting behavior
 * 6. Warning generation
 */
Object.defineProperty(exports, "__esModule", { value: true });
const fuel_system_1 = require("../src/fuel-system");
class FuelSystemTester {
    constructor() {
        this.results = [];
    }
    runAll() {
        console.log('=== FUEL SYSTEM PHYSICS TESTS ===\n');
        this.testPressureDynamics();
        this.testFuelConsumption();
        this.testCenterOfMass();
        this.testCrossfeed();
        this.testVenting();
        this.testWarnings();
        this.testFuelLines();
        this.printResults();
        return this.results;
    }
    assert(condition, name, message, data) {
        this.results.push({
            name,
            passed: condition,
            message: condition ? 'PASS' : `FAIL: ${message}`,
            data
        });
    }
    assertClose(actual, expected, tolerance, name) {
        const diff = Math.abs(actual - expected);
        const passed = diff <= tolerance;
        this.assert(passed, name, `Expected ${expected}, got ${actual} (diff: ${diff}, tolerance: ${tolerance})`, { actual, expected, diff });
    }
    /**
     * TEST 1: Pressure Dynamics
     * Verify that pressurant gas expands correctly as fuel is consumed
     */
    testPressureDynamics() {
        console.log('Test 1: Pressure Dynamics');
        const fuelSystem = new fuel_system_1.FuelSystem();
        const tank = fuelSystem.getTank('main_1');
        // Record initial pressure
        fuelSystem.update(0, 0);
        const initialPressure = tank.pressureBar;
        const initialFuel = tank.fuelMass;
        console.log(`  Initial: ${initialFuel}kg fuel, ${initialPressure.toFixed(2)} bar`);
        // Consume half the fuel
        const consumeAmount = initialFuel / 2;
        fuelSystem.consumeFuel('main_1', consumeAmount);
        // Update to recalculate pressure
        fuelSystem.update(0, 0);
        const newPressure = tank.pressureBar;
        console.log(`  After consuming ${consumeAmount}kg: ${tank.fuelMass}kg fuel, ${newPressure.toFixed(2)} bar`);
        // Pressure should DECREASE when fuel consumed (ullage volume increases)
        // With ideal gas: P1*V1 = P2*V2, as V increases, P decreases
        this.assert(newPressure < initialPressure, 'Pressure decreases as fuel consumed', `Pressure should decrease, but went from ${initialPressure} to ${newPressure}`);
        // Consume more fuel
        fuelSystem.consumeFuel('main_1', tank.fuelMass * 0.9); // consume 90% of remaining
        fuelSystem.update(0, 0);
        const finalPressure = tank.pressureBar;
        console.log(`  After consuming 90% more: ${tank.fuelMass.toFixed(2)}kg fuel, ${finalPressure.toFixed(2)} bar\n`);
        this.assert(finalPressure < newPressure, 'Pressure continues to decrease', `Pressure should keep decreasing`);
    }
    /**
     * TEST 2: Fuel Consumption
     * Verify fuel consumption tracking and tank emptying
     */
    testFuelConsumption() {
        console.log('Test 2: Fuel Consumption');
        const fuelSystem = new fuel_system_1.FuelSystem();
        const tank = fuelSystem.getTank('main_1');
        const initialFuel = tank.fuelMass;
        // Try to consume fuel
        const consumed = 10; // kg
        const success = fuelSystem.consumeFuel('main_1', consumed);
        this.assert(success, 'Fuel consumption succeeds', 'Should be able to consume fuel');
        this.assertClose(tank.fuelMass, initialFuel - consumed, 0.01, 'Fuel mass reduced correctly');
        // Try to consume more than available
        const excessive = tank.fuelMass + 50;
        const shouldFail = fuelSystem.consumeFuel('main_1', excessive);
        this.assert(!shouldFail, 'Cannot consume more than available', 'Should reject excessive consumption');
        this.assertClose(tank.fuelMass, initialFuel - consumed, 0.01, 'Fuel mass unchanged after failed consumption');
        console.log(`  Total consumed tracked: ${fuelSystem.totalFuelConsumed}kg\n`);
    }
    /**
     * TEST 3: Center of Mass Calculation
     * Verify that unbalanced fuel creates COM offset
     */
    testCenterOfMass() {
        console.log('Test 3: Center of Mass');
        const fuelSystem = new fuel_system_1.FuelSystem();
        // Initially balanced (both tanks ~80kg and 75kg)
        fuelSystem.update(0, 0);
        const initialBalance = fuelSystem.getFuelBalance();
        console.log(`  Initial balance offset: (${initialBalance.offset.x.toFixed(2)}, ${initialBalance.offset.y.toFixed(2)}), magnitude: ${initialBalance.magnitude.toFixed(2)}`);
        // Empty one tank completely
        const tank1 = fuelSystem.getTank('main_1');
        fuelSystem.consumeFuel('main_1', tank1.fuelMass);
        fuelSystem.update(0, 0);
        const unbalancedBalance = fuelSystem.getFuelBalance();
        console.log(`  After emptying main_1: (${unbalancedBalance.offset.x.toFixed(2)}, ${unbalancedBalance.offset.y.toFixed(2)}), magnitude: ${unbalancedBalance.magnitude.toFixed(2)}`);
        // COM should shift toward tank 2 (position y: 10)
        this.assert(unbalancedBalance.magnitude > initialBalance.magnitude, 'Imbalance increases COM offset', 'Magnitude should increase when tanks are unbalanced');
        this.assert(unbalancedBalance.offset.y > initialBalance.offset.y, 'COM shifts toward fuller tank', 'Should shift toward tank 2');
        // Empty all tanks
        fuelSystem.consumeFuel('main_2', fuelSystem.getTank('main_2').fuelMass);
        fuelSystem.consumeFuel('rcs', fuelSystem.getTank('rcs').fuelMass);
        fuelSystem.update(0, 0);
        const emptyBalance = fuelSystem.getFuelBalance();
        console.log(`  With all tanks empty: magnitude: ${emptyBalance.magnitude.toFixed(2)}\n`);
        this.assertClose(emptyBalance.magnitude, 0, 0.01, 'Empty tanks have zero COM offset');
    }
    /**
     * TEST 4: Crossfeed Operation
     * Verify fuel transfer between tanks
     */
    testCrossfeed() {
        console.log('Test 4: Crossfeed Operation');
        const fuelSystem = new fuel_system_1.FuelSystem();
        const tank1 = fuelSystem.getTank('main_1');
        const tank2 = fuelSystem.getTank('main_2');
        const initial1 = tank1.fuelMass;
        const initial2 = tank2.fuelMass;
        console.log(`  Initial: Tank1=${initial1}kg, Tank2=${initial2}kg`);
        // Set up crossfeed from tank1 to tank2
        fuelSystem.setCrossfeed('main_1', 'main_2');
        // Simulate for 10 seconds
        for (let i = 0; i < 10; i++) {
            fuelSystem.update(1.0, i);
        }
        console.log(`  After 10 seconds: Tank1=${tank1.fuelMass.toFixed(2)}kg, Tank2=${tank2.fuelMass.toFixed(2)}kg`);
        // Tank1 should have less fuel, tank2 should have more (if pressure allows)
        // With similar initial fuel levels, transfer may be minimal due to pressure balance
        // Let's empty tank2 first to create pressure differential
        fuelSystem.consumeFuel('main_2', tank2.fuelMass - 10); // Leave only 10kg
        fuelSystem.setCrossfeed('main_1', 'main_2');
        const beforeTransfer1 = tank1.fuelMass;
        const beforeTransfer2 = tank2.fuelMass;
        console.log(`  Before pressure-driven transfer: Tank1=${beforeTransfer1.toFixed(2)}kg, Tank2=${beforeTransfer2.toFixed(2)}kg`);
        // Simulate crossfeed
        for (let i = 0; i < 5; i++) {
            fuelSystem.update(1.0, 10 + i);
        }
        console.log(`  After 5 seconds: Tank1=${tank1.fuelMass.toFixed(2)}kg, Tank2=${tank2.fuelMass.toFixed(2)}kg`);
        this.assert(tank1.fuelMass < beforeTransfer1, 'Source tank loses fuel during crossfeed', 'Tank1 should have less fuel');
        this.assert(tank2.fuelMass > beforeTransfer2, 'Destination tank gains fuel during crossfeed', 'Tank2 should have more fuel');
        console.log('');
    }
    /**
     * TEST 5: Venting
     * Verify fuel venting behavior
     */
    testVenting() {
        console.log('Test 5: Venting');
        const fuelSystem = new fuel_system_1.FuelSystem();
        const tank = fuelSystem.getTank('main_1');
        const initialFuel = tank.fuelMass;
        console.log(`  Initial fuel: ${initialFuel}kg`);
        // Open vent
        fuelSystem.setValve('main_1', 'vent', true);
        // Simulate venting for 5 seconds
        for (let i = 0; i < 5; i++) {
            fuelSystem.update(1.0, i);
        }
        console.log(`  After 5 seconds venting: ${tank.fuelMass.toFixed(2)}kg`);
        this.assert(tank.fuelMass < initialFuel, 'Venting reduces fuel mass', 'Fuel should be vented');
        // Close vent
        fuelSystem.setValve('main_1', 'vent', false);
        const afterVent = tank.fuelMass;
        // Simulate without venting
        fuelSystem.update(1.0, 5);
        this.assertClose(tank.fuelMass, afterVent, 0.1, 'Fuel stable when vent closed');
        console.log('');
    }
    /**
     * TEST 6: Warning Generation
     * Verify that system generates appropriate warnings
     */
    testWarnings() {
        console.log('Test 6: Warning Generation');
        const fuelSystem = new fuel_system_1.FuelSystem();
        const tank = fuelSystem.getTank('main_1');
        // Consume fuel to trigger low fuel warning
        fuelSystem.consumeFuel('main_1', tank.fuelMass * 0.95); // Leave 5%
        fuelSystem.update(0, 0);
        fuelSystem.update(0, 1); // Trigger warning
        const events = fuelSystem.getEvents();
        const lowFuelWarning = events.find(e => e.type === 'fuel_low');
        console.log(`  Events generated: ${events.length}`);
        events.forEach(e => console.log(`    - ${e.type}: ${JSON.stringify(e.data)}`));
        this.assert(lowFuelWarning !== undefined, 'Low fuel warning generated', 'Should generate low fuel warning');
        // Consume more to trigger empty warning
        fuelSystem.consumeFuel('main_1', tank.fuelMass);
        fuelSystem.clearEvents();
        fuelSystem.update(0, 2);
        const emptyWarning = fuelSystem.getEvents().find(e => e.type === 'tank_empty');
        this.assert(emptyWarning !== undefined, 'Tank empty warning generated', 'Should generate empty tank warning');
        console.log('');
    }
    /**
     * TEST 7: Fuel Line Pressure
     * Verify fuel line pressure calculation
     */
    testFuelLines() {
        console.log('Test 7: Fuel Line Pressure');
        const fuelSystem = new fuel_system_1.FuelSystem();
        // Connect main engine to tank 1
        fuelSystem.connectFuelLine('mainEngine', 'main_1');
        fuelSystem.setValve('main_1', 'feedToEngine', true);
        fuelSystem.update(0, 0);
        const tank = fuelSystem.getTank('main_1');
        const state = fuelSystem.getState();
        console.log(`  Tank pressure: ${tank.pressureBar.toFixed(2)} bar`);
        console.log(`  Line pressure (no pump): ${state.fuelLines.mainEngine.pressure.toFixed(2)} bar`);
        this.assertClose(state.fuelLines.mainEngine.pressure, tank.pressureBar, 0.01, 'Line pressure equals tank pressure without pump');
        // Activate fuel pump
        fuelSystem.setFuelPump('mainEngine', true);
        fuelSystem.update(0, 0);
        const pumpedState = fuelSystem.getState();
        console.log(`  Line pressure (with pump): ${pumpedState.fuelLines.mainEngine.pressure.toFixed(2)} bar`);
        this.assert(pumpedState.fuelLines.mainEngine.pressure > tank.pressureBar, 'Pump increases line pressure', 'Fuel pump should boost pressure');
        this.assertClose(pumpedState.fuelLines.mainEngine.pressure, tank.pressureBar + 5, 0.01, 'Pump adds 5 bar');
        console.log('');
    }
    printResults() {
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
        }
        else {
            console.log('\n❌ Some tests failed');
        }
    }
}
// Run tests
const tester = new FuelSystemTester();
tester.runAll();
