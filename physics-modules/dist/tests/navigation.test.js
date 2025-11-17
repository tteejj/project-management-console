"use strict";
/**
 * Navigation System Tests
 *
 * Comprehensive testing of trajectory prediction, suicide burn calculation,
 * velocity decomposition, navball display, and telemetry generation
 */
Object.defineProperty(exports, "__esModule", { value: true });
const navigation_1 = require("../src/navigation");
// Helper functions
function createIdentityQuaternion() {
    return { w: 1, x: 0, y: 0, z: 0 };
}
function magnitude(v) {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
}
class NavigationTests {
    constructor() {
        this.passed = 0;
        this.failed = 0;
        this.tests = [];
        this.MOON_RADIUS = 1737400; // m
    }
    assert(condition, message) {
        if (condition) {
            this.passed++;
            this.tests.push(`✓ ${message}: PASS`);
        }
        else {
            this.failed++;
            this.tests.push(`✗ ${message}: FAIL`);
        }
    }
    assertNear(actual, expected, tolerance, message) {
        const diff = Math.abs(actual - expected);
        if (diff <= tolerance) {
            this.passed++;
            this.tests.push(`✓ ${message}: PASS`);
        }
        else {
            this.failed++;
            this.tests.push(`✗ ${message}: FAIL: ${actual} vs ${expected} (diff: ${diff})`);
        }
    }
    printResults() {
        console.log('\n=== TEST RESULTS ===\n');
        this.tests.forEach(test => console.log(test));
        console.log(`\n${this.passed} passed, ${this.failed} failed (${this.passed + this.failed} total)\n`);
        if (this.failed === 0) {
            console.log('🎉 All tests passed!\n');
        }
        else {
            console.log(`❌ ${this.failed} test(s) failed\n`);
        }
    }
    // Test 1: Trajectory Predictor - Freefall Impact
    testTrajectoryFreefallImpact() {
        console.log('\nTest 1: Trajectory Predictor - Freefall Impact');
        const predictor = new navigation_1.TrajectoryPredictor();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS + 1000 }; // 1km altitude
        const velocity = { x: 0, y: 0, z: -50 }; // 50 m/s downward
        const thrust = 0; // No thrust
        const thrustDir = { x: 0, y: 0, z: 1 };
        const prediction = predictor.predict(position, velocity, 5000, thrust, thrustDir, 100);
        console.log(`  Initial altitude: 1000m`);
        console.log(`  Initial velocity: -50 m/s`);
        console.log(`  Impact time: ${prediction.impactTime.toFixed(1)}s`);
        console.log(`  Impact speed: ${prediction.impactSpeed.toFixed(1)} m/s`);
        console.log(`  Will impact: ${prediction.willImpact}`);
        this.assert(prediction.willImpact === true, 'Predicts impact');
        this.assert(prediction.impactTime > 0 && prediction.impactTime < 100, 'Impact time reasonable');
        this.assert(prediction.impactSpeed > 50, 'Impact speed > initial speed (accelerated)');
    }
    // Test 2: Trajectory Predictor - With Thrust
    testTrajectoryWithThrust() {
        console.log('\nTest 2: Trajectory Predictor - With Thrust');
        const predictor = new navigation_1.TrajectoryPredictor();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS + 500 };
        const velocity = { x: 0, y: 0, z: -40 };
        const thrust = 5000; // 5kN thrust (slight deceleration)
        const thrustDir = { x: 0, y: 0, z: 1 }; // Upward
        const prediction1 = predictor.predict(position, velocity, 5000, 0, thrustDir, 50); // No thrust
        const prediction2 = predictor.predict(position, velocity, 5000, thrust, thrustDir, 50); // With thrust
        console.log(`  No thrust impact speed: ${prediction1.impactSpeed.toFixed(1)} m/s`);
        console.log(`  With thrust impact speed: ${prediction2.impactSpeed.toFixed(1)} m/s`);
        console.log(`  Difference: ${(prediction1.impactSpeed - prediction2.impactSpeed).toFixed(1)} m/s`);
        this.assert(prediction2.impactSpeed < prediction1.impactSpeed, 'Thrust reduces impact speed');
        this.assert(typeof prediction2.impactTime === 'number', 'Impact time calculated');
    }
    // Test 3: Trajectory Predictor - Escaping
    testTrajectoryEscaping() {
        console.log('\nTest 3: Trajectory Predictor - Escaping');
        const predictor = new navigation_1.TrajectoryPredictor();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS + 5000 };
        const velocity = { x: 0, y: 0, z: 2000 }; // Very high upward velocity
        const thrust = 0;
        const thrustDir = { x: 0, y: 0, z: 1 };
        const prediction = predictor.predict(position, velocity, 5000, thrust, thrustDir, 50);
        console.log(`  High upward velocity: 2000 m/s`);
        console.log(`  Will impact: ${prediction.willImpact}`);
        console.log(`  Impact time: ${prediction.impactTime}`);
        this.assert(prediction.willImpact === false, 'Does not predict impact');
        this.assert(prediction.impactTime === Infinity, 'Impact time is infinity');
    }
    // Test 4: Trajectory Predictor - Coordinates
    testTrajectoryCoordinates() {
        console.log('\nTest 4: Trajectory Predictor - Coordinates');
        const predictor = new navigation_1.TrajectoryPredictor();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS + 500 };
        const velocity = { x: 0, y: 0, z: -50 };
        const thrust = 0;
        const thrustDir = { x: 0, y: 0, z: 1 };
        const prediction = predictor.predict(position, velocity, 5000, thrust, thrustDir, 50);
        console.log(`  Impact coordinates: ${prediction.coordinates.lat.toFixed(2)}°N, ${prediction.coordinates.lon.toFixed(2)}°E`);
        this.assert(prediction.coordinates !== undefined, 'Coordinates provided');
        this.assert(typeof prediction.coordinates.lat === 'number', 'Latitude is number');
        this.assert(typeof prediction.coordinates.lon === 'number', 'Longitude is number');
    }
    // Test 5: Suicide Burn - Basic Calculation
    testSuicideBurnBasic() {
        console.log('\nTest 5: Suicide Burn - Basic Calculation');
        const calculator = new navigation_1.SuicideBurnCalculator();
        const altitude = 1000;
        const verticalSpeed = -50;
        const mass = 5000;
        const maxThrust = 45000;
        const data = calculator.calculate(altitude, verticalSpeed, mass, maxThrust);
        // Expected: a = F/m - g = 45000/5000 - 1.62 = 9 - 1.62 = 7.38 m/s²
        // Stop distance: d = v²/(2a) = 2500/(2*7.38) = 169.4m
        // With 1.15 safety: 169.4 * 1.15 = 194.8m
        console.log(`  Vertical speed: ${verticalSpeed} m/s`);
        console.log(`  Burn altitude: ${data.burnAltitude.toFixed(1)}m`);
        console.log(`  Time until burn: ${data.timeUntilBurn.toFixed(1)}s`);
        console.log(`  Burn duration: ${data.burnDuration.toFixed(1)}s`);
        this.assertNear(data.burnAltitude, 194.8, 5.0, 'Burn altitude calculated correctly');
        this.assert(data.shouldBurn === false, 'Should not burn yet (above threshold)');
    }
    // Test 6: Suicide Burn - Should Burn Now
    testSuicideBurnShouldBurn() {
        console.log('\nTest 6: Suicide Burn - Should Burn Now');
        const calculator = new navigation_1.SuicideBurnCalculator();
        const altitude = 150; // Below burn altitude
        const verticalSpeed = -50;
        const mass = 5000;
        const maxThrust = 45000;
        const data = calculator.calculate(altitude, verticalSpeed, mass, maxThrust);
        console.log(`  Altitude: ${altitude}m`);
        console.log(`  Burn altitude: ${data.burnAltitude.toFixed(1)}m`);
        console.log(`  Should burn: ${data.shouldBurn}`);
        this.assert(data.shouldBurn === true, 'Should burn now');
        this.assert(data.timeUntilBurn === 0, 'Time until burn is zero');
    }
    // Test 7: Suicide Burn - Insufficient Thrust
    testSuicideBurnInsufficientThrust() {
        console.log('\nTest 7: Suicide Burn - Insufficient Thrust');
        const calculator = new navigation_1.SuicideBurnCalculator();
        const altitude = 1000;
        const verticalSpeed = -50;
        const mass = 100000; // Very heavy
        const maxThrust = 1000; // Low thrust
        const data = calculator.calculate(altitude, verticalSpeed, mass, maxThrust);
        console.log(`  T/W ratio: ${(maxThrust / (mass * 1.62)).toFixed(2)}`);
        console.log(`  Burn altitude: ${data.burnAltitude}`);
        console.log(`  Should burn: ${data.shouldBurn}`);
        this.assert(data.burnAltitude === Infinity, 'Burn altitude infinite');
        this.assert(data.shouldBurn === true, 'Should burn immediately (cannot stop)');
    }
    // Test 8: Suicide Burn - Safety Factor
    testSuicideBurnSafetyFactor() {
        console.log('\nTest 8: Suicide Burn - Safety Factor');
        const calculator = new navigation_1.SuicideBurnCalculator();
        const altitude = 1000;
        const verticalSpeed = -50;
        const mass = 5000;
        const maxThrust = 45000;
        const data1 = calculator.calculate(altitude, verticalSpeed, mass, maxThrust, 1.0);
        const data2 = calculator.calculate(altitude, verticalSpeed, mass, maxThrust, 1.5);
        console.log(`  Burn altitude (1.0x): ${data1.burnAltitude.toFixed(1)}m`);
        console.log(`  Burn altitude (1.5x): ${data2.burnAltitude.toFixed(1)}m`);
        console.log(`  Ratio: ${(data2.burnAltitude / data1.burnAltitude).toFixed(2)}`);
        this.assertNear(data2.burnAltitude / data1.burnAltitude, 1.5, 0.01, 'Safety factor applied correctly');
    }
    // Test 9: Velocity Decomposer - Vertical Component
    testVelocityDecomposerVertical() {
        console.log('\nTest 9: Velocity Decomposer - Vertical Component');
        const decomposer = new navigation_1.VelocityDecomposer();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS };
        const velocity = { x: 0, y: 0, z: -50 }; // Pure radial
        const breakdown = decomposer.decompose(velocity, position);
        console.log(`  Vertical: ${breakdown.vertical.toFixed(2)} m/s`);
        console.log(`  Horizontal: ${breakdown.horizontal.toFixed(2)} m/s`);
        console.log(`  Total: ${breakdown.total.toFixed(2)} m/s`);
        this.assertNear(breakdown.vertical, -50, 0.1, 'Vertical component correct');
        this.assertNear(breakdown.horizontal, 0, 0.1, 'Horizontal component zero');
        this.assertNear(breakdown.total, 50, 0.1, 'Total speed correct');
    }
    // Test 10: Velocity Decomposer - Horizontal Component
    testVelocityDecomposerHorizontal() {
        console.log('\nTest 10: Velocity Decomposer - Horizontal Component');
        const decomposer = new navigation_1.VelocityDecomposer();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS };
        const velocity = { x: 100, y: 0, z: 0 }; // Pure tangential
        const breakdown = decomposer.decompose(velocity, position);
        console.log(`  Vertical: ${breakdown.vertical.toFixed(2)} m/s`);
        console.log(`  Horizontal: ${breakdown.horizontal.toFixed(2)} m/s`);
        this.assertNear(breakdown.vertical, 0, 0.1, 'Vertical component zero');
        this.assertNear(breakdown.horizontal, 100, 0.1, 'Horizontal component correct');
    }
    // Test 11: Velocity Decomposer - Mixed Velocity
    testVelocityDecomposerMixed() {
        console.log('\nTest 11: Velocity Decomposer - Mixed Velocity');
        const decomposer = new navigation_1.VelocityDecomposer();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS };
        const velocity = { x: 30, y: 40, z: -50 }; // Mixed
        const breakdown = decomposer.decompose(velocity, position);
        const expectedTotal = Math.sqrt(30 * 30 + 40 * 40 + 50 * 50); // 70.71
        console.log(`  Vertical: ${breakdown.vertical.toFixed(2)} m/s`);
        console.log(`  Horizontal: ${breakdown.horizontal.toFixed(2)} m/s`);
        console.log(`  Total: ${breakdown.total.toFixed(2)} m/s`);
        this.assertNear(breakdown.vertical, -50, 0.1, 'Vertical component correct');
        this.assertNear(breakdown.total, expectedTotal, 0.1, 'Total speed correct');
        this.assert(breakdown.horizontal > 0, 'Horizontal component non-zero');
    }
    // Test 12: Navball Display - Render
    testNavballDisplay() {
        console.log('\nTest 12: Navball Display - Render');
        const navball = new navigation_1.NavballDisplay();
        const attitude = createIdentityQuaternion();
        const velocity = { x: 0, y: 0, z: 50 };
        const display = navball.render(attitude, velocity);
        console.log('  Navball display:\n' + display);
        this.assert(display.includes('◉'), 'Contains center marker');
        this.assert(display.includes('Pitch'), 'Contains pitch');
        this.assert(display.includes('Roll'), 'Contains roll');
        this.assert(display.includes('Yaw'), 'Contains yaw');
    }
    // Test 13: Navball Display - With Target
    testNavballDisplayWithTarget() {
        console.log('\nTest 13: Navball Display - With Target');
        const navball = new navigation_1.NavballDisplay();
        const attitude = createIdentityQuaternion();
        const velocity = { x: 0, y: 0, z: 50 };
        const target = { x: 1000, y: 0, z: 0 };
        const display = navball.render(attitude, velocity, target);
        console.log('  Display includes target marker');
        this.assert(display.includes('◎ Target'), 'Contains target marker');
    }
    // Test 14: Navigation System - Telemetry Generation
    testNavigationTelemetry() {
        console.log('\nTest 14: Navigation System - Telemetry Generation');
        const nav = new navigation_1.NavigationSystem();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS + 5000 };
        const velocity = { x: 0, y: 0, z: -50 };
        const attitude = createIdentityQuaternion();
        const thrustDir = { x: 0, y: 0, z: 1 };
        const telemetry = nav.getTelemetry(position, velocity, attitude, 5000, // mass
        45000, // thrust
        thrustDir, 1.0, // throttle
        200, // fuel mass
        300, // fuel capacity
        311 // Isp
        );
        console.log(`  Altitude: ${telemetry.altitude.toFixed(1)}m`);
        console.log(`  Vertical speed: ${telemetry.verticalSpeed.toFixed(1)} m/s`);
        console.log(`  Total speed: ${telemetry.totalSpeed.toFixed(1)} m/s`);
        console.log(`  TWR: ${telemetry.twr.toFixed(2)}`);
        console.log(`  Fuel: ${telemetry.fuelRemainingPercent.toFixed(1)}%`);
        this.assertNear(telemetry.altitude, 5000, 1, 'Altitude correct');
        this.assertNear(telemetry.verticalSpeed, -50, 1, 'Vertical speed correct');
        this.assertNear(telemetry.totalSpeed, 50, 1, 'Total speed correct');
        this.assert(telemetry.twr > 0, 'TWR calculated');
        this.assertNear(telemetry.fuelRemainingPercent, 66.67, 1, 'Fuel percent correct');
    }
    // Test 15: Navigation System - Impact Prediction
    testNavigationImpactPrediction() {
        console.log('\nTest 15: Navigation System - Impact Prediction');
        const nav = new navigation_1.NavigationSystem();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS + 1000 };
        const velocity = { x: 0, y: 0, z: -50 };
        const thrustDir = { x: 0, y: 0, z: 1 };
        const prediction = nav.predictImpact(position, velocity, 5000, 0, thrustDir);
        console.log(`  Impact time: ${prediction.impactTime.toFixed(1)}s`);
        console.log(`  Will impact: ${prediction.willImpact}`);
        this.assert(prediction.willImpact === true, 'Predicts impact');
        this.assert(prediction.impactTime > 0, 'Impact time positive');
    }
    // Test 16: Navigation System - Suicide Burn Calculation
    testNavigationSuicideBurn() {
        console.log('\nTest 16: Navigation System - Suicide Burn Calculation');
        const nav = new navigation_1.NavigationSystem();
        const data = nav.calculateSuicideBurn(1000, -50, 5000, 45000);
        console.log(`  Burn altitude: ${data.burnAltitude.toFixed(1)}m`);
        console.log(`  Should burn: ${data.shouldBurn}`);
        this.assert(data.burnAltitude > 0, 'Burn altitude calculated');
        this.assert(typeof data.shouldBurn === 'boolean', 'Should burn flag present');
    }
    // Test 17: Navigation System - Velocity Decomposition
    testNavigationVelocityDecomp() {
        console.log('\nTest 17: Navigation System - Velocity Decomposition');
        const nav = new navigation_1.NavigationSystem();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS };
        const velocity = { x: 0, y: 0, z: -50 };
        const breakdown = nav.decomposeVelocity(velocity, position);
        console.log(`  Vertical: ${breakdown.vertical.toFixed(1)} m/s`);
        console.log(`  Horizontal: ${breakdown.horizontal.toFixed(1)} m/s`);
        this.assertNear(breakdown.vertical, -50, 1, 'Vertical correct');
        this.assertNear(breakdown.horizontal, 0, 1, 'Horizontal correct');
    }
    // Test 18: Navigation System - Target Setting
    testNavigationTarget() {
        console.log('\nTest 18: Navigation System - Target Setting');
        const nav = new navigation_1.NavigationSystem();
        const target = { x: 10000, y: 0, z: this.MOON_RADIUS };
        nav.setTarget(target);
        const position = { x: 0, y: 0, z: this.MOON_RADIUS + 5000 };
        const velocity = { x: 0, y: 0, z: -50 };
        const attitude = createIdentityQuaternion();
        const thrustDir = { x: 0, y: 0, z: 1 };
        const telemetry = nav.getTelemetry(position, velocity, attitude, 5000, 45000, thrustDir, 1.0, 200, 300, 311);
        console.log(`  Distance to target: ${telemetry.distanceToTarget?.toFixed(1)}m`);
        console.log(`  Bearing to target: ${telemetry.bearingToTarget?.toFixed(1)}°`);
        this.assert(telemetry.distanceToTarget !== null, 'Distance calculated');
        this.assert(telemetry.bearingToTarget !== null, 'Bearing calculated');
    }
    // Test 19: Navigation System - Clear Target
    testNavigationClearTarget() {
        console.log('\nTest 19: Navigation System - Clear Target');
        const nav = new navigation_1.NavigationSystem();
        const target = { x: 10000, y: 0, z: this.MOON_RADIUS };
        nav.setTarget(target);
        nav.clearTarget();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS + 5000 };
        const velocity = { x: 0, y: 0, z: -50 };
        const attitude = createIdentityQuaternion();
        const thrustDir = { x: 0, y: 0, z: 1 };
        const telemetry = nav.getTelemetry(position, velocity, attitude, 5000, 45000, thrustDir, 1.0, 200, 300, 311);
        console.log(`  Distance to target: ${telemetry.distanceToTarget}`);
        this.assert(telemetry.distanceToTarget === null, 'Target cleared');
        this.assert(telemetry.bearingToTarget === null, 'Bearing null');
    }
    // Test 20: Telemetry - Delta-V Remaining
    testTelemetryDeltaV() {
        console.log('\nTest 20: Telemetry - Delta-V Remaining');
        const nav = new navigation_1.NavigationSystem();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS + 5000 };
        const velocity = { x: 0, y: 0, z: -50 };
        const attitude = createIdentityQuaternion();
        const thrustDir = { x: 0, y: 0, z: 1 };
        const mass = 5000;
        const fuelMass = 200;
        const Isp = 311;
        const telemetry = nav.getTelemetry(position, velocity, attitude, mass, 45000, thrustDir, 1.0, fuelMass, 300, Isp);
        // Expected: Δv = Isp * g0 * ln(m / (m - fuel))
        // = 311 * 9.80665 * ln(5000 / 4800)
        // = 3049.9 * ln(1.0417)
        // = 3049.9 * 0.0408
        // = 124.4 m/s
        console.log(`  Delta-V remaining: ${telemetry.deltaVRemaining.toFixed(1)} m/s`);
        this.assertNear(telemetry.deltaVRemaining, 124.4, 5, 'Delta-V calculated correctly');
    }
    // Test 21: Telemetry - Burn Time Estimation
    testTelemetryBurnTime() {
        console.log('\nTest 21: Telemetry - Burn Time Estimation');
        const nav = new navigation_1.NavigationSystem();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS + 5000 };
        const velocity = { x: 0, y: 0, z: -50 };
        const attitude = createIdentityQuaternion();
        const thrustDir = { x: 0, y: 0, z: 1 };
        const telemetry = nav.getTelemetry(position, velocity, attitude, 5000, // mass
        45000, // thrust
        thrustDir, 1.0, // throttle
        200, // fuel mass
        300, // fuel capacity
        311 // Isp
        );
        console.log(`  Estimated burn time: ${telemetry.estimatedBurnTime.toFixed(1)}s`);
        this.assert(telemetry.estimatedBurnTime > 0, 'Burn time calculated');
        this.assert(telemetry.estimatedBurnTime < 1000, 'Burn time reasonable');
    }
    // Test 22: Telemetry - TWR Calculation
    testTelemetryTWR() {
        console.log('\nTest 22: Telemetry - TWR Calculation');
        const nav = new navigation_1.NavigationSystem();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS + 5000 };
        const velocity = { x: 0, y: 0, z: -50 };
        const attitude = createIdentityQuaternion();
        const thrustDir = { x: 0, y: 0, z: 1 };
        const mass = 5000;
        const thrust = 45000;
        const telemetry = nav.getTelemetry(position, velocity, attitude, mass, thrust, thrustDir, 1.0, 200, 300, 311);
        // Expected TWR: T / (m * g) = 45000 / (5000 * 1.62) = 45000 / 8100 = 5.56
        console.log(`  TWR: ${telemetry.twr.toFixed(2)}`);
        this.assertNear(telemetry.twr, 5.56, 0.1, 'TWR calculated correctly');
    }
    // Test 23: Telemetry - Angle From Vertical
    testTelemetryAngleFromVertical() {
        console.log('\nTest 23: Telemetry - Angle From Vertical');
        const nav = new navigation_1.NavigationSystem();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS + 5000 };
        const velocity = { x: 0, y: 0, z: -50 };
        const attitude = createIdentityQuaternion(); // Pointing up
        const thrustDir = { x: 0, y: 0, z: 1 }; // Thrust upward
        const telemetry = nav.getTelemetry(position, velocity, attitude, 5000, 45000, thrustDir, 1.0, 200, 300, 311);
        console.log(`  Angle from vertical: ${telemetry.angleFromVertical.toFixed(1)}°`);
        // Should be close to 0° (vertical)
        this.assertNear(telemetry.angleFromVertical, 0, 5, 'Angle from vertical correct');
    }
    // Test 24: Velocity Decomposer - Prograde Component
    testVelocityDecomposerPrograde() {
        console.log('\nTest 24: Velocity Decomposer - Prograde Component');
        const decomposer = new navigation_1.VelocityDecomposer();
        const position = { x: 0, y: 0, z: this.MOON_RADIUS };
        const velocity = { x: 50, y: 50, z: -50 };
        const breakdown = decomposer.decompose(velocity, position);
        const expectedPrograde = Math.sqrt(50 * 50 + 50 * 50 + 50 * 50);
        console.log(`  Prograde: ${breakdown.prograde.toFixed(1)} m/s`);
        console.log(`  Expected: ${expectedPrograde.toFixed(1)} m/s`);
        this.assertNear(breakdown.prograde, expectedPrograde, 0.1, 'Prograde equals total speed');
    }
    // Test 25: Suicide Burn - Zero Vertical Speed
    testSuicideBurnZeroSpeed() {
        console.log('\nTest 25: Suicide Burn - Zero Vertical Speed');
        const calculator = new navigation_1.SuicideBurnCalculator();
        const data = calculator.calculate(1000, 0, 5000, 45000);
        console.log(`  Vertical speed: 0 m/s`);
        console.log(`  Burn altitude: ${data.burnAltitude.toFixed(1)}m`);
        console.log(`  Should burn: ${data.shouldBurn}`);
        this.assertNear(data.burnAltitude, 0, 1, 'Burn altitude zero for zero speed');
        this.assert(data.shouldBurn === false, 'Should not burn');
    }
    runAllTests() {
        console.log('=== NAVIGATION SYSTEM TESTS ===');
        this.testTrajectoryFreefallImpact();
        this.testTrajectoryWithThrust();
        this.testTrajectoryEscaping();
        this.testTrajectoryCoordinates();
        this.testSuicideBurnBasic();
        this.testSuicideBurnShouldBurn();
        this.testSuicideBurnInsufficientThrust();
        this.testSuicideBurnSafetyFactor();
        this.testSuicideBurnZeroSpeed();
        this.testVelocityDecomposerVertical();
        this.testVelocityDecomposerHorizontal();
        this.testVelocityDecomposerMixed();
        this.testVelocityDecomposerPrograde();
        this.testNavballDisplay();
        this.testNavballDisplayWithTarget();
        this.testNavigationTelemetry();
        this.testNavigationImpactPrediction();
        this.testNavigationSuicideBurn();
        this.testNavigationVelocityDecomp();
        this.testNavigationTarget();
        this.testNavigationClearTarget();
        this.testTelemetryDeltaV();
        this.testTelemetryBurnTime();
        this.testTelemetryTWR();
        this.testTelemetryAngleFromVertical();
        this.printResults();
    }
}
// Run tests
const tests = new NavigationTests();
tests.runAllTests();
// Export test count for CI
const exitCode = tests['failed'] > 0 ? 1 : 0;
process.exit(exitCode);
