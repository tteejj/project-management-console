/**
 * Ship Physics Core Tests
 *
 * Tests validate:
 * 1. Gravitational acceleration: g = -G*M/r²
 * 2. Position/velocity integration
 * 3. Rotational dynamics: I·ω̇ = τ - ω × (I·ω)
 * 4. Quaternion math and normalization
 * 5. Thrust integration (body to inertial frame)
 * 6. Mass tracking
 * 7. Altitude calculation
 * 8. Euler angle conversion
 */

import { ShipPhysics, Vector3, Quaternion } from '../src/ship-physics';

interface TestResult {
  name: string;
  passed: boolean;
  message?: string;
  data?: any;
}

class ShipPhysicsTester {
  private results: TestResult[] = [];

  runAll(): TestResult[] {
    console.log('=== SHIP PHYSICS CORE TESTS ===\n');

    this.testGravitationalAcceleration();
    this.testFreefall();
    this.testThrustIntegration();
    this.testRotationalDynamics();
    this.testQuaternionNormalization();
    this.testMassTracking();
    this.testAltitudeCalculation();
    this.testEulerAngleConversion();
    this.testGroundImpact();
    this.testGyroscopicEffect();

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
      `Expected ${expected.toExponential(3)}, got ${actual.toExponential(3)} (diff: ${diff.toExponential(3)}, tol: ${tolerance.toExponential(3)})`,
      { actual, expected, diff }
    );
  }

  /**
   * TEST 1: Gravitational Acceleration
   * Verify g = -G*M/r² at Moon surface
   */
  private testGravitationalAcceleration(): void {
    console.log('Test 1: Gravitational Acceleration (g = -G*M/r²)');

    const ship = new ShipPhysics({
      planetMass: 7.342e22,      // Moon mass (kg)
      planetRadius: 1737400,     // Moon radius (m)
      initialPosition: { x: 0, y: 0, z: 1737400 },  // At surface
      initialVelocity: { x: 0, y: 0, z: 0 }
    });

    // Update with no thrust to calculate gravity
    ship.update(0.1, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, 0);

    const velocity = ship.velocity;
    const accel = velocity.z / 0.1;  // a = Δv / Δt

    // Expected surface gravity: g = G*M/r² = 6.674e-11 * 7.342e22 / (1737400)² ≈ 1.62 m/s²
    const G = 6.67430e-11;
    const M = 7.342e22;
    const r = 1737400;
    const expectedG = G * M / (r * r);

    console.log(`  Calculated acceleration: ${Math.abs(accel).toFixed(3)} m/s²`);
    console.log(`  Expected Moon gravity: ${expectedG.toFixed(3)} m/s²`);

    this.assertClose(
      Math.abs(accel),
      expectedG,
      0.01,
      'Surface gravity matches g = G*M/r²'
    );

    console.log('');
  }

  /**
   * TEST 2: Freefall Motion
   * Verify position integration during freefall
   */
  private testFreefall(): void {
    console.log('Test 2: Freefall Motion Integration');

    const ship = new ShipPhysics({
      initialPosition: { x: 0, y: 0, z: 1737400 + 1000 },  // 1km altitude
      initialVelocity: { x: 0, y: 0, z: 0 }
    });

    const initialAltitude = ship.getAltitude();

    console.log(`  Initial altitude: ${initialAltitude.toFixed(1)}m`);

    // Freefall for 10 seconds
    for (let i = 0; i < 100; i++) {
      ship.update(0.1, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, 0);
    }

    const finalAltitude = ship.getAltitude();
    const verticalSpeed = ship.getVerticalSpeed();

    console.log(`  After 10s: altitude=${finalAltitude.toFixed(1)}m, vertical speed=${verticalSpeed.toFixed(2)} m/s`);

    this.assert(
      finalAltitude < initialAltitude,
      'Altitude decreases during freefall',
      'Ship should fall'
    );

    this.assert(
      verticalSpeed < -5,
      'Falling with significant downward velocity',
      'Should be moving down'
    );

    // Verify using kinematics: v = gt, s = 0.5*g*t²
    const t = 10;
    const g = 1.62;  // Moon gravity
    const expectedSpeed = -g * t;
    const expectedDrop = 0.5 * g * t * t;

    console.log(`  Expected vertical speed: ${expectedSpeed.toFixed(2)} m/s`);
    console.log(`  Expected altitude drop: ${expectedDrop.toFixed(1)}m`);

    this.assertClose(
      verticalSpeed,
      expectedSpeed,
      2.0,
      'Vertical speed matches v = gt'
    );

    console.log('');
  }

  /**
   * TEST 3: Thrust Integration
   * Verify thrust is correctly rotated from body to inertial frame
   */
  private testThrustIntegration(): void {
    console.log('Test 3: Thrust Integration (Body to Inertial Frame)');

    const ship = new ShipPhysics({
      initialPosition: { x: 0, y: 0, z: 1737400 + 10000 },
      initialVelocity: { x: 0, y: 0, z: 0 },
      initialAttitude: { w: 1, x: 0, y: 0, z: 0 }  // No rotation
    });

    const totalMass = ship.getTotalMass();

    console.log(`  Ship mass: ${totalMass}kg`);

    // Apply 45kN thrust in +Z direction (body frame)
    const thrust = { x: 0, y: 0, z: 45000 };

    console.log(`  Thrust: ${thrust.z}N in body +Z`);

    // Run for 5 seconds
    for (let i = 0; i < 50; i++) {
      ship.update(0.1, thrust, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, 0);
    }

    const finalVelocity = ship.velocity;

    console.log(`  Final velocity: x=${finalVelocity.x.toFixed(2)}, y=${finalVelocity.y.toFixed(2)}, z=${finalVelocity.z.toFixed(2)} m/s`);

    // Expected: a = F/m = 45000/8000 = 5.625 m/s²
    // After 5s: v = at = 5.625 * 5 = 28.125 m/s (minus gravity effect)
    const expectedAccel = 45000 / totalMass;
    const g = 1.62;
    const netAccel = expectedAccel - g;  // Thrust minus gravity
    const expectedVelocity = netAccel * 5;

    console.log(`  Expected velocity: ${expectedVelocity.toFixed(2)} m/s`);

    this.assertClose(
      finalVelocity.z,
      expectedVelocity,
      3.0,
      'Velocity matches thrust acceleration'
    );

    console.log('');
  }

  /**
   * TEST 4: Rotational Dynamics
   * Verify torque creates angular acceleration
   */
  private testRotationalDynamics(): void {
    console.log('Test 4: Rotational Dynamics (I·ω̇ = τ)');

    const ship = new ShipPhysics({
      momentOfInertia: { x: 2000, y: 2000, z: 500 }
    });

    const I_y = 2000;  // kg·m²

    console.log(`  Moment of inertia (Y-axis): ${I_y} kg·m²`);

    // Apply 125 N·m pitch torque (Y-axis)
    const torque = { x: 0, y: 125, z: 0 };

    console.log(`  Applied torque: ${torque.y} N·m`);

    // Run for 5 seconds
    for (let i = 0; i < 50; i++) {
      ship.update(0.1, { x: 0, y: 0, z: 0 }, torque, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, 0);
    }

    const angularVel = ship.angularVelocity;

    console.log(`  Angular velocity: ωy=${angularVel.y.toFixed(4)} rad/s`);

    // Expected: α = τ/I = 125/2000 = 0.0625 rad/s²
    // After 5s: ω = αt = 0.0625 * 5 = 0.3125 rad/s
    const expectedAngularAccel = torque.y / I_y;
    const expectedAngularVel = expectedAngularAccel * 5;

    console.log(`  Expected: ω=${expectedAngularVel.toFixed(4)} rad/s (α=${expectedAngularAccel.toFixed(4)} rad/s²)`);

    this.assertClose(
      angularVel.y,
      expectedAngularVel,
      0.01,
      'Angular velocity matches τ/I'
    );

    console.log('');
  }

  /**
   * TEST 5: Quaternion Normalization
   * Verify quaternion remains normalized
   */
  private testQuaternionNormalization(): void {
    console.log('Test 5: Quaternion Normalization');

    const ship = new ShipPhysics();

    // Apply constant torque for extended time
    for (let i = 0; i < 1000; i++) {
      ship.update(0.1, { x: 0, y: 0, z: 0 }, { x: 10, y: 20, z: 5 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, 0);
    }

    const q = ship.attitude;
    const magnitude = Math.sqrt(q.w * q.w + q.x * q.x + q.y * q.y + q.z * q.z);

    console.log(`  Quaternion magnitude after 1000 steps: ${magnitude.toFixed(6)}`);

    this.assertClose(
      magnitude,
      1.0,
      0.001,
      'Quaternion remains normalized'
    );

    console.log('');
  }

  /**
   * TEST 6: Mass Tracking
   * Verify mass decreases with propellant consumption
   */
  private testMassTracking(): void {
    console.log('Test 6: Mass Tracking and Propellant Consumption');

    const ship = new ShipPhysics({
      dryMass: 5000,
      initialPropellantMass: 3000
    });

    const initialMass = ship.getTotalMass();

    console.log(`  Initial mass: ${initialMass}kg (dry: ${ship.dryMass}kg, propellant: ${ship.propellantMass}kg)`);

    // Consume propellant over time (100 kg total)
    for (let i = 0; i < 100; i++) {
      ship.update(0.1, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, 1.0);  // 1 kg/timestep
    }

    const finalMass = ship.getTotalMass();
    const consumed = initialMass - finalMass;

    console.log(`  Final mass: ${finalMass}kg`);
    console.log(`  Propellant consumed: ${consumed}kg`);

    this.assertClose(
      consumed,
      100,
      0.1,
      'Mass decreases by consumed propellant'
    );

    this.assertClose(
      finalMass,
      7900,
      1.0,
      'Final mass = dry + remaining propellant'
    );

    console.log('');
  }

  /**
   * TEST 7: Altitude Calculation
   * Verify altitude = |position| - planetRadius
   */
  private testAltitudeCalculation(): void {
    console.log('Test 7: Altitude Calculation');

    const planetRadius = 1737400;
    const ship = new ShipPhysics({
      planetRadius,
      initialPosition: { x: 0, y: 0, z: planetRadius + 5000 }
    });

    const altitude = ship.getAltitude();

    console.log(`  Position magnitude: ${Math.sqrt(ship.position.x**2 + ship.position.y**2 + ship.position.z**2).toFixed(1)}m`);
    console.log(`  Planet radius: ${planetRadius}m`);
    console.log(`  Calculated altitude: ${altitude.toFixed(1)}m`);

    this.assertClose(
      altitude,
      5000,
      1.0,
      'Altitude calculated correctly'
    );

    // Test with off-axis position
    ship.position = { x: 3000, y: 4000, z: planetRadius };
    const offAxisAltitude = ship.getAltitude();

    // |position| = sqrt(3000² + 4000² + 1737400²) ≈ 1737407.2
    // altitude = 1737407.2 - 1737400 = 7.2m

    console.log(`  Off-axis position: (3000, 4000, ${planetRadius})`);
    console.log(`  Off-axis altitude: ${offAxisAltitude.toFixed(1)}m`);

    this.assertClose(
      offAxisAltitude,
      7.2,
      1.0,
      'Off-axis altitude correct'
    );

    console.log('');
  }

  /**
   * TEST 8: Euler Angle Conversion
   * Verify quaternion to Euler angle conversion
   */
  private testEulerAngleConversion(): void {
    console.log('Test 8: Euler Angle Conversion');

    const ship = new ShipPhysics({
      initialAttitude: { w: 1, x: 0, y: 0, z: 0 }  // Identity
    });

    let euler = ship.getEulerAngles();

    console.log(`  Identity quaternion: roll=${euler.roll.toFixed(2)}°, pitch=${euler.pitch.toFixed(2)}°, yaw=${euler.yaw.toFixed(2)}°`);

    this.assertClose(
      euler.roll,
      0,
      0.1,
      'Identity quaternion gives zero roll'
    );

    this.assertClose(
      euler.pitch,
      0,
      0.1,
      'Identity quaternion gives zero pitch'
    );

    // Apply pitch torque to create rotation
    for (let i = 0; i < 50; i++) {
      ship.update(0.1, { x: 0, y: 0, z: 0 }, { x: 0, y: 100, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, 0);
    }

    euler = ship.getEulerAngles();

    console.log(`  After pitch rotation: roll=${euler.roll.toFixed(2)}°, pitch=${euler.pitch.toFixed(2)}°, yaw=${euler.yaw.toFixed(2)}°`);

    this.assert(
      Math.abs(euler.pitch) > 5,
      'Pitch angle changes after pitch torque',
      'Should have noticeable pitch'
    );

    console.log('');
  }

  /**
   * TEST 9: Ground Impact Detection
   * Verify ground impact event when altitude <= 0
   */
  private testGroundImpact(): void {
    console.log('Test 9: Ground Impact Detection');

    const ship = new ShipPhysics({
      initialPosition: { x: 0, y: 0, z: 1737400 + 50 },  // 50m altitude
      initialVelocity: { x: 0, y: 0, z: -10 }  // Falling at 10 m/s
    });

    console.log(`  Initial altitude: ${ship.getAltitude().toFixed(1)}m, descending at ${ship.getVerticalSpeed().toFixed(1)} m/s`);

    // Fall until impact
    for (let i = 0; i < 100; i++) {
      ship.update(0.1, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, 0);

      if (ship.getAltitude() <= 0) {
        break;
      }
    }

    const finalAltitude = ship.getAltitude();
    const events = ship.getEvents();
    const impactEvent = events.find(e => e.type === 'ground_impact');

    console.log(`  Final altitude: ${finalAltitude.toFixed(1)}m`);
    console.log(`  Impact event: ${impactEvent ? '✓' : '✗'}`);

    this.assert(
      impactEvent !== undefined,
      'Ground impact event generated',
      'Should detect impact'
    );

    if (impactEvent) {
      console.log(`  Impact speed: ${impactEvent.data.speed.toFixed(2)} m/s`);
    }

    console.log('');
  }

  /**
   * TEST 10: Gyroscopic Effect
   * Verify ω × (I·ω) gyroscopic term
   */
  private testGyroscopicEffect(): void {
    console.log('Test 10: Gyroscopic Effect (ω × I·ω)');

    const ship = new ShipPhysics({
      momentOfInertia: { x: 2000, y: 2000, z: 500 }
    });

    // Spin up around Z-axis
    for (let i = 0; i < 50; i++) {
      ship.update(0.1, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 100 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, 0);
    }

    const spinRate = ship.angularVelocity.z;

    console.log(`  Spin rate (Z-axis): ${spinRate.toFixed(3)} rad/s`);

    // Now apply pitch torque while spinning
    const initialAngularVelX = ship.angularVelocity.x;

    for (let i = 0; i < 10; i++) {
      ship.update(0.1, { x: 0, y: 0, z: 0 }, { x: 0, y: 50, z: 0 }, { x: 0, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }, 0);
    }

    const finalAngularVelX = ship.angularVelocity.x;

    console.log(`  X angular velocity before pitch torque: ${initialAngularVelX.toFixed(4)} rad/s`);
    console.log(`  X angular velocity after pitch torque: ${finalAngularVelX.toFixed(4)} rad/s`);

    // Gyroscopic coupling should cause X-axis motion when Y torque applied while spinning in Z
    this.assert(
      Math.abs(finalAngularVelX) > Math.abs(initialAngularVelX),
      'Gyroscopic coupling affects rotation',
      'Should see coupling between axes'
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
const tester = new ShipPhysicsTester();
tester.runAll();
