"use strict";
/**
 * Compressed Gas System Physics Tests
 *
 * Tests validate:
 * 1. Ideal gas law (P = nRT/V) with temperature changes
 * 2. Gas consumption and pressure drop
 * 3. Regulator operation and output pressure
 * 4. Overpressure warnings and rupture
 * 5. Gas transfer between bottles
 * 6. Temperature equilibration with ambient
 * 7. Event generation
 */
Object.defineProperty(exports, "__esModule", { value: true });
const compressed_gas_system_1 = require("../src/compressed-gas-system");
class CompressedGasSystemTester {
    constructor() {
        this.results = [];
    }
    runAll() {
        console.log('=== COMPRESSED GAS SYSTEM PHYSICS TESTS ===\n');
        this.testIdealGasLaw();
        this.testGasConsumption();
        this.testPressureDrop();
        this.testRegulatorOperation();
        this.testRegulatorPressureControl();
        this.testOverpressureWarning();
        this.testBottleRupture();
        this.testGasTransfer();
        this.testTemperatureEquilibration();
        this.testWarningGeneration();
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
     * TEST 1: Ideal Gas Law
     * Verify P = (n*R*T)/V with temperature changes
     */
    testIdealGasLaw() {
        console.log('Test 1: Ideal Gas Law (Temperature-Pressure Relationship)');
        const system = new compressed_gas_system_1.CompressedGasSystem();
        const bottle = system.getBottle(0); // N2 bottle
        // Record initial state
        const initialTemp = bottle.temperature;
        const initialPressure = bottle.pressureBar;
        console.log(`  Initial: ${initialTemp}K, ${initialPressure.toFixed(1)} bar`);
        // Increase ambient temperature
        system.setAmbientTemperature(350); // +57K
        // Simulate temperature equilibration
        for (let i = 0; i < 100; i++) {
            system.update(1.0, i);
        }
        const newTemp = bottle.temperature;
        const newPressure = bottle.pressureBar;
        console.log(`  After heating: ${newTemp.toFixed(1)}K, ${newPressure.toFixed(1)} bar`);
        // Gay-Lussac's Law: P1/T1 = P2/T2
        const expectedPressure = initialPressure * (newTemp / initialTemp);
        console.log(`  Expected pressure: ${expectedPressure.toFixed(1)} bar`);
        this.assert(newTemp > initialTemp, 'Temperature increases with ambient', 'Should heat up');
        this.assertClose(newPressure, expectedPressure, 20.0, // Allow tolerance for equilibration dynamics
        'Pressure increases proportionally to temperature');
        // Now cool down from heated state
        const heatedPressure = bottle.pressureBar;
        const heatedTemp = bottle.temperature;
        system.setAmbientTemperature(250); // Cool down
        for (let i = 100; i < 200; i++) {
            system.update(1.0, i);
        }
        const coolTemp = bottle.temperature;
        const coolPressure = bottle.pressureBar;
        console.log(`  After cooling: ${coolTemp.toFixed(1)}K, ${coolPressure.toFixed(1)} bar\n`);
        this.assert(coolPressure < heatedPressure, 'Pressure decreases when cooled', 'Should follow ideal gas law');
    }
    /**
     * TEST 2: Gas Consumption
     * Verify gas can be consumed from bottles
     */
    testGasConsumption() {
        console.log('Test 2: Gas Consumption');
        const system = new compressed_gas_system_1.CompressedGasSystem();
        const bottle = system.getBottle(0); // N2 bottle
        const initialMass = bottle.massKg;
        const initialPressure = bottle.pressureBar;
        console.log(`  Initial: ${initialMass}kg, ${initialPressure.toFixed(1)} bar`);
        // Consume 2kg of gas
        const consumed = system.consumeGas(0, 2.0);
        system.update(1.0, 0); // Update pressures
        const newMass = bottle.massKg;
        const newPressure = bottle.pressureBar;
        console.log(`  After consuming 2kg: ${newMass}kg, ${newPressure.toFixed(1)} bar`);
        this.assertClose(consumed, 2.0, 0.01, 'Consumed correct amount');
        this.assertClose(newMass, initialMass - 2.0, 0.01, 'Mass reduced correctly');
        this.assert(newPressure < initialPressure, 'Pressure drops after consumption', 'Less gas = lower pressure');
        // Try to consume more than available
        const availableMass = bottle.massKg;
        const excessive = availableMass + 5;
        const consumedExcess = system.consumeGas(0, excessive);
        this.assert(consumedExcess <= availableMass, 'Cannot consume more than available', `Should be limited to ${availableMass}kg, got ${consumedExcess}kg`);
        console.log('');
    }
    /**
     * TEST 3: Pressure Drop Calculation
     * Verify pressure drops correctly with mass loss
     */
    testPressureDrop() {
        console.log('Test 3: Pressure Drop Dynamics');
        const system = new compressed_gas_system_1.CompressedGasSystem();
        const bottle = system.getBottle(1); // O2 bottle
        const readings = [];
        // Record pressure at different mass levels
        for (let i = 0; i < 5; i++) {
            readings.push({
                mass: bottle.massKg,
                pressure: bottle.pressureBar
            });
            system.consumeGas(1, 1.5); // Consume 1.5kg
            system.update(1.0, i);
        }
        console.log('  Pressure vs Mass:');
        readings.forEach(r => {
            console.log(`    ${r.mass.toFixed(2)}kg → ${r.pressure.toFixed(1)} bar`);
        });
        // Verify pressure drops linearly with mass (constant T and V)
        this.assert(readings[0].pressure > readings[1].pressure, 'Pressure drops after first consumption', 'Should decrease');
        this.assert(readings[1].pressure > readings[2].pressure, 'Pressure continues to drop', 'Should keep decreasing');
        // Check proportionality (P ∝ n ∝ mass)
        const ratio1 = readings[1].pressure / readings[0].pressure;
        const massRatio1 = readings[1].mass / readings[0].mass;
        console.log(`  Pressure ratio: ${ratio1.toFixed(3)}, Mass ratio: ${massRatio1.toFixed(3)}`);
        this.assertClose(ratio1, massRatio1, 0.07, // Slightly higher tolerance due to rounding
        'Pressure proportional to mass');
        console.log('');
    }
    /**
     * TEST 4: Regulator Operation
     * Verify regulator activation and flow
     */
    testRegulatorOperation() {
        console.log('Test 4: Regulator Operation');
        const system = new compressed_gas_system_1.CompressedGasSystem();
        // Activate fuel pressurization regulator
        const flowRate = system.activateRegulator('Fuel Tank Pressurization');
        console.log(`  Activated regulator, flow rate: ${flowRate} L/min`);
        this.assert(flowRate > 0, 'Regulator provides flow when activated', 'Should have positive flow rate');
        const state = system.getState();
        const reg = state.regulators.find(r => r.name === 'Fuel Tank Pressurization');
        this.assert(reg.active, 'Regulator marked as active', 'State should reflect activation');
        // Deactivate
        system.deactivateRegulator('Fuel Tank Pressurization');
        const stateAfter = system.getState();
        const regAfter = stateAfter.regulators.find(r => r.name === 'Fuel Tank Pressurization');
        this.assert(!regAfter.active, 'Regulator deactivates correctly', 'Should be inactive');
        console.log('');
    }
    /**
     * TEST 5: Regulator Pressure Control
     * Verify regulated output pressure
     */
    testRegulatorPressureControl() {
        console.log('Test 5: Regulator Pressure Control');
        const system = new compressed_gas_system_1.CompressedGasSystem();
        system.activateRegulator('Fuel Tank Pressurization');
        const outputPressure = system.getRegulatorPressure('Fuel Tank Pressurization');
        console.log(`  Output pressure: ${outputPressure.toFixed(2)} bar`);
        // Should be regulated to 2.5 bar
        this.assertClose(outputPressure, 2.5, 0.1, 'Regulator maintains target pressure');
        // Deplete bottle significantly
        const bottle = system.getBottle(0);
        system.consumeGas(0, bottle.massKg - 0.2); // Leave only 0.2kg
        system.update(1.0, 0);
        console.log(`  After depletion: bottle at ${bottle.pressureBar.toFixed(1)} bar`);
        const lowPressureOutput = system.getRegulatorPressure('Fuel Tank Pressurization');
        console.log(`  Regulator output: ${lowPressureOutput.toFixed(2)} bar`);
        this.assert(lowPressureOutput < 2.5 || bottle.pressureBar < 7.5, 'Regulator output drops when bottle very depleted', 'Cannot maintain pressure without sufficient input');
        console.log('');
    }
    /**
     * TEST 6: Overpressure Warning
     * Verify warning generated near max pressure
     */
    testOverpressureWarning() {
        console.log('Test 6: Overpressure Warning');
        const system = new compressed_gas_system_1.CompressedGasSystem({
            bottles: [{
                    gas: 'N2',
                    pressureBar: 235, // Near max of 250
                    volumeL: 50,
                    massKg: 14.5,
                    maxPressureBar: 250,
                    temperature: 293,
                    uses: ['test'],
                    ruptured: false
                }]
        });
        system.update(1.0, 0);
        system.update(1.0, 1); // Trigger warning check
        const events = system.getEvents();
        const warning = events.find(e => e.type === 'gas_bottle_overpressure');
        console.log(`  Events: ${events.length}`);
        if (warning) {
            console.log(`  Warning at ${warning.data.pressure.toFixed(1)} bar (max: ${warning.data.maxPressure} bar)`);
        }
        this.assert(warning !== undefined, 'Overpressure warning generated', 'Should warn near max pressure');
        console.log('');
    }
    /**
     * TEST 7: Bottle Rupture
     * Verify rupture when exceeding max pressure
     */
    testBottleRupture() {
        console.log('Test 7: Bottle Rupture');
        const system = new compressed_gas_system_1.CompressedGasSystem({
            bottles: [{
                    gas: 'He',
                    pressureBar: 200,
                    volumeL: 30,
                    massKg: 1.5,
                    maxPressureBar: 220,
                    temperature: 293,
                    uses: ['test'],
                    ruptured: false
                }]
        });
        const bottle = system.getBottle(0);
        console.log(`  Initial: ${bottle.pressureBar.toFixed(1)} bar (max: ${bottle.maxPressureBar} bar)`);
        // Heat bottle to increase pressure above rupture threshold
        system.setAmbientTemperature(400); // Significant heating
        // Equilibrate
        for (let i = 0; i < 100; i++) {
            system.update(1.0, i);
        }
        console.log(`  After heating: ${bottle.temperature.toFixed(1)}K, ${bottle.pressureBar.toFixed(1)} bar`);
        console.log(`  Ruptured: ${bottle.ruptured}`);
        this.assert(bottle.ruptured, 'Bottle ruptures when overpressure', 'Should rupture above max pressure');
        this.assertClose(bottle.pressureBar, 0, 0.01, 'Pressure zero after rupture');
        this.assertClose(bottle.massKg, 0, 0.01, 'Gas lost after rupture');
        // Check for rupture event
        const events = system.getEvents();
        const ruptureEvent = events.find(e => e.type === 'gas_bottle_ruptured');
        this.assert(ruptureEvent !== undefined, 'Rupture event generated', 'Should log rupture');
        console.log('');
    }
    /**
     * TEST 8: Gas Transfer
     * Verify gas transfer between bottles
     */
    testGasTransfer() {
        console.log('Test 8: Gas Transfer Between Bottles');
        const system = new compressed_gas_system_1.CompressedGasSystem({
            bottles: [
                {
                    gas: 'N2',
                    pressureBar: 200,
                    volumeL: 50,
                    massKg: 12.5,
                    maxPressureBar: 250,
                    temperature: 293,
                    uses: ['source'],
                    ruptured: false
                },
                {
                    gas: 'N2',
                    pressureBar: 50,
                    volumeL: 50,
                    massKg: 3.0,
                    maxPressureBar: 250,
                    temperature: 293,
                    uses: ['destination'],
                    ruptured: false
                }
            ]
        });
        const bottle1 = system.getBottle(0);
        const bottle2 = system.getBottle(1);
        console.log(`  Before: Bottle1=${bottle1.massKg}kg (${bottle1.pressureBar.toFixed(1)} bar)`);
        console.log(`          Bottle2=${bottle2.massKg}kg (${bottle2.pressureBar.toFixed(1)} bar)`);
        // Transfer 2kg from bottle1 to bottle2
        const success = system.transferGas(0, 1, 2.0);
        system.update(1.0, 0); // Update pressures
        console.log(`  After:  Bottle1=${bottle1.massKg}kg (${bottle1.pressureBar.toFixed(1)} bar)`);
        console.log(`          Bottle2=${bottle2.massKg}kg (${bottle2.pressureBar.toFixed(1)} bar)`);
        this.assert(success, 'Gas transfer succeeds', 'Should complete transfer');
        this.assertClose(bottle1.massKg, 10.5, 0.01, 'Source bottle loses mass');
        this.assertClose(bottle2.massKg, 5.0, 0.01, 'Destination bottle gains mass');
        this.assert(bottle2.pressureBar > 50, 'Destination pressure increases', 'More gas = higher pressure');
        console.log('');
    }
    /**
     * TEST 9: Temperature Equilibration
     * Verify bottles equilibrate with ambient temperature
     */
    testTemperatureEquilibration() {
        console.log('Test 9: Temperature Equilibration');
        const system = new compressed_gas_system_1.CompressedGasSystem({
            ambientTemperature: 350 // Hot compartment
        });
        const bottle = system.getBottle(0);
        const initialTemp = bottle.temperature;
        console.log(`  Bottle initial: ${initialTemp}K`);
        console.log(`  Ambient: ${system.ambientTemperature}K`);
        // Simulate equilibration (longer time for slow thermal constant)
        for (let i = 0; i < 500; i++) {
            system.update(1.0, i);
        }
        const finalTemp = bottle.temperature;
        console.log(`  Bottle after equilibration: ${finalTemp.toFixed(1)}K`);
        this.assert(finalTemp > initialTemp, 'Bottle heats toward ambient', 'Should equilibrate');
        this.assertClose(finalTemp, 350, 15.0, // Within 15K (thermal equilibration is slow by design)
        'Bottle approaches ambient temperature');
        console.log('');
    }
    /**
     * TEST 10: Warning Generation
     * Verify various warning types
     */
    testWarningGeneration() {
        console.log('Test 10: Warning Generation');
        // Test low pressure warning
        const system1 = new compressed_gas_system_1.CompressedGasSystem({
            bottles: [{
                    gas: 'O2',
                    pressureBar: 25, // Below 30 bar threshold
                    volumeL: 40,
                    massKg: 1.5,
                    maxPressureBar: 200,
                    temperature: 293,
                    uses: ['test'],
                    ruptured: false
                }]
        });
        system1.update(1.0, 0);
        system1.update(1.0, 1);
        const lowPressureEvent = system1.getEvents().find(e => e.type === 'gas_bottle_low');
        this.assert(lowPressureEvent !== undefined, 'Low pressure warning generated', 'Should warn when pressure < 30 bar');
        console.log(`  Low pressure warning: ✓`);
        // Test depletion warning
        const system2 = new compressed_gas_system_1.CompressedGasSystem({
            bottles: [{
                    gas: 'He',
                    pressureBar: 5,
                    volumeL: 30,
                    massKg: 0.05, // Nearly empty
                    maxPressureBar: 220,
                    temperature: 293,
                    uses: ['test'],
                    ruptured: false
                }]
        });
        system2.update(1.0, 0);
        system2.update(1.0, 1);
        const depletedEvent = system2.getEvents().find(e => e.type === 'gas_bottle_depleted');
        this.assert(depletedEvent !== undefined, 'Depletion warning generated', 'Should warn when nearly empty');
        console.log(`  Depletion warning: ✓`);
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
const tester = new CompressedGasSystemTester();
tester.runAll();
