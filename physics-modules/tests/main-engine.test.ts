/**
 * Main Engine Physics Tests
 *
 * Tests validate:
 * 1. Ignition sequence and timing (2 second startup)
 * 2. Thrust calculation: F = ṁ * v_e where v_e = Isp * g0
 * 3. Mass flow rate: ṁ = F / (Isp * g0)
 * 4. Fuel/oxidizer consumption with mixture ratio
 * 5. Throttle control and minimum throttle
 * 6. Gimbal control for thrust vectoring
 * 7. Shutdown sequence
 * 8. Health degradation
 * 9. Propellant starvation
 * 10. Restart cooldown
 */

import { MainEngine } from '../src/main-engine';

interface TestResult {
  name: string;
  passed: boolean;
  message?: string;
  data?: any;
}

class MainEngineTester {
  private results: TestResult[] = [];

  runAll(): TestResult[] {
    console.log('=== MAIN ENGINE PHYSICS TESTS ===\n');

    this.testIgnitionSequence();
    this.testThrustCalculation();
    this.testMassFlowRate();
    this.testPropellantConsumption();
    this.testThrottleControl();
    this.testGimbalControl();
    this.testShutdownSequence();
    this.testHealthDegradation();
    this.testPropellantStarvation();
    this.testRestartCooldown();
    this.testThrustVector();

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
   * TEST 1: Ignition Sequence
   * Verify engine takes 2 seconds to reach full thrust
   */
  private testIgnitionSequence(): void {
    console.log('Test 1: Ignition Sequence and Startup Time');

    const engine = new MainEngine();

    console.log(`  Initial status: ${engine.status}`);

    this.assert(
      engine.status === 'off',
      'Engine starts offline',
      'Should be off initially'
    );

    // Ignite
    const igniteSuccess = engine.ignite();

    console.log(`  Ignition command: ${igniteSuccess}, status: ${engine.status}`);

    this.assert(
      igniteSuccess,
      'Ignition succeeds',
      'Should allow ignition'
    );

    this.assert(
      engine.status === 'igniting',
      'Engine enters igniting state',
      'Should be igniting'
    );

    // Set throttle to 100%
    engine.setThrottle(1.0);

    // Simulate for 1 second (halfway through ignition)
    for (let i = 0; i < 10; i++) {
      engine.update(0.1, i * 0.1);
    }

    const halfwayThrust = engine.currentThrustN;

    console.log(`  Thrust after 1s: ${halfwayThrust.toFixed(0)}N (${(halfwayThrust / engine.maxThrustN * 100).toFixed(1)}%)`);

    this.assert(
      engine.status === 'igniting',
      'Still igniting after 1 second',
      'Should not be fully started yet'
    );

    // Continue to 2 seconds
    for (let i = 0; i < 10; i++) {
      engine.update(0.1, 1.0 + i * 0.1);
    }

    console.log(`  Status after 2s: ${engine.status}`);
    console.log(`  Thrust after 2s: ${engine.currentThrustN.toFixed(0)}N (${(engine.currentThrustN / engine.maxThrustN * 100).toFixed(1)}%)`);

    this.assert(
      engine.status === 'running',
      'Engine running after ignition time',
      'Should be fully started'
    );

    this.assertClose(
      engine.currentThrustN,
      engine.maxThrustN,
      1000,
      'Thrust at maximum after startup'
    );

    console.log('');
  }

  /**
   * TEST 2: Thrust Calculation
   * Verify F = ṁ * v_e where v_e = Isp * g0
   */
  private testThrustCalculation(): void {
    console.log('Test 2: Thrust Calculation (F = ṁ * v_e)');

    const engine = new MainEngine({
      maxThrustN: 45000,
      specificImpulseSec: 311
    });

    engine.ignite();
    engine.setThrottle(1.0);

    // Run until fully started
    for (let i = 0; i < 30; i++) {
      engine.update(0.1, i * 0.1);
    }

    const thrust = engine.currentThrustN;
    const massFlow = engine.getMassFlowRateKgPerSec();
    const g0 = 9.80665;
    const exhaustVelocity = engine.specificImpulseSec * g0;

    console.log(`  Max thrust: ${engine.maxThrustN}N`);
    console.log(`  Isp: ${engine.specificImpulseSec}s`);
    console.log(`  Exhaust velocity: ${exhaustVelocity.toFixed(1)} m/s`);
    console.log(`  Mass flow rate: ${massFlow.toFixed(3)} kg/s`);
    console.log(`  Calculated thrust: ${thrust.toFixed(0)}N`);

    // Verify F = ṁ * v_e
    const calculatedThrust = massFlow * exhaustVelocity;

    console.log(`  Expected thrust (ṁ * v_e): ${calculatedThrust.toFixed(0)}N`);

    this.assertClose(
      thrust,
      calculatedThrust,
      100,
      'Thrust matches F = ṁ * v_e'
    );

    console.log('');
  }

  /**
   * TEST 3: Mass Flow Rate
   * Verify ṁ = F / (Isp * g0)
   */
  private testMassFlowRate(): void {
    console.log('Test 3: Mass Flow Rate Calculation');

    const engine = new MainEngine();

    engine.ignite();
    engine.setThrottle(0.6); // 60% throttle

    // Run until started
    for (let i = 0; i < 30; i++) {
      engine.update(0.1, i * 0.1);
    }

    const thrust = engine.currentThrustN;
    const massFlow = engine.getMassFlowRateKgPerSec();
    const g0 = 9.80665;

    const expectedMassFlow = thrust / (engine.specificImpulseSec * g0);

    console.log(`  Throttle: 60%`);
    console.log(`  Thrust: ${thrust.toFixed(0)}N`);
    console.log(`  Mass flow: ${massFlow.toFixed(3)} kg/s`);
    console.log(`  Expected: ${expectedMassFlow.toFixed(3)} kg/s`);

    this.assertClose(
      massFlow,
      expectedMassFlow,
      0.01,
      'Mass flow rate calculated correctly'
    );

    console.log('');
  }

  /**
   * TEST 4: Propellant Consumption
   * Verify fuel and oxidizer consumption with correct mixture ratio
   */
  private testPropellantConsumption(): void {
    console.log('Test 4: Propellant Consumption with Mixture Ratio');

    const engine = new MainEngine({
      fuelOxidizerRatio: 1.6 // 1.6:1 O/F ratio
    });

    engine.ignite();
    engine.setThrottle(1.0);

    // Run until started
    for (let i = 0; i < 30; i++) {
      engine.update(0.1, i * 0.1);
    }

    console.log(`  Fuel/Oxidizer ratio: ${engine.fuelOxidizerRatio}:1`);

    const rates = engine.getConsumptionRates();

    console.log(`  Fuel rate: ${rates.fuelKgPerSec.toFixed(4)} kg/s`);
    console.log(`  Oxidizer rate: ${rates.oxidizerKgPerSec.toFixed(4)} kg/s`);

    const actualRatio = rates.oxidizerKgPerSec / rates.fuelKgPerSec;

    console.log(`  Actual ratio: ${actualRatio.toFixed(2)}:1`);

    this.assertClose(
      actualRatio,
      engine.fuelOxidizerRatio,
      0.01,
      'Mixture ratio correct'
    );

    // Verify total matches mass flow
    const totalFlow = engine.getMassFlowRateKgPerSec();
    const sumRates = rates.fuelKgPerSec + rates.oxidizerKgPerSec;

    console.log(`  Total mass flow: ${totalFlow.toFixed(4)} kg/s`);
    console.log(`  Sum of rates: ${sumRates.toFixed(4)} kg/s`);

    this.assertClose(
      sumRates,
      totalFlow,
      0.001,
      'Consumption rates sum to total mass flow'
    );

    // Consume propellant for 10 seconds
    const initialFuel = engine.totalFuelConsumedKg;
    const initialOxidizer = engine.totalOxidizerConsumedKg;

    for (let i = 0; i < 100; i++) {
      engine.update(0.1, 3.0 + i * 0.1);
      engine.consumePropellant(0.1, 1000, 1000); // Plenty available
    }

    const fuelConsumed = engine.totalFuelConsumedKg - initialFuel;
    const oxidizerConsumed = engine.totalOxidizerConsumedKg - initialOxidizer;

    console.log(`  After 10s: Fuel=${fuelConsumed.toFixed(3)}kg, Oxidizer=${oxidizerConsumed.toFixed(3)}kg`);

    const consumedRatio = oxidizerConsumed / fuelConsumed;

    console.log(`  Consumed ratio: ${consumedRatio.toFixed(2)}:1`);

    this.assertClose(
      consumedRatio,
      engine.fuelOxidizerRatio,
      0.05,
      'Consumed propellant maintains mixture ratio'
    );

    console.log('');
  }

  /**
   * TEST 5: Throttle Control
   * Verify throttle affects thrust and minimum throttle enforcement
   */
  private testThrottleControl(): void {
    console.log('Test 5: Throttle Control and Minimum Throttle');

    const engine = new MainEngine({
      minThrottle: 0.4 // 40% minimum
    });

    engine.ignite();

    // Test different throttle levels
    const throttles = [1.0, 0.7, 0.4, 0.2]; // Last one is below minimum

    for (const targetThrottle of throttles) {
      engine.setThrottle(targetThrottle);

      // Run until stable
      for (let i = 0; i < 30; i++) {
        engine.update(0.1, i * 0.1);
      }

      const actualThrottle = engine.throttle;
      const thrust = engine.currentThrustN;
      const thrustPercent = (thrust / engine.maxThrustN) * 100;

      console.log(`  Set: ${(targetThrottle * 100).toFixed(0)}% -> Actual: ${(actualThrottle * 100).toFixed(0)}%, Thrust: ${thrustPercent.toFixed(1)}%`);

      if (targetThrottle < engine.minThrottle && targetThrottle > 0) {
        this.assertClose(
          actualThrottle,
          engine.minThrottle,
          0.01,
          `Throttle clamped to minimum (${(targetThrottle * 100).toFixed(0)}% -> ${(engine.minThrottle * 100).toFixed(0)}%)`
        );
      } else {
        this.assertClose(
          actualThrottle,
          targetThrottle,
          0.01,
          `Throttle set correctly (${(targetThrottle * 100).toFixed(0)}%)`
        );
      }
    }

    console.log('');
  }

  /**
   * TEST 6: Gimbal Control
   * Verify gimbal angles are limited to maximum
   */
  private testGimbalControl(): void {
    console.log('Test 6: Gimbal Control and Angle Limits');

    const engine = new MainEngine({
      maxGimbalDeg: 6
    });

    console.log(`  Maximum gimbal: ±${engine.maxGimbalDeg}°`);

    // Test various gimbal commands
    const testCases = [
      { pitch: 3, yaw: 2, expectPitch: 3, expectYaw: 2 },
      { pitch: 10, yaw: 0, expectPitch: 6, expectYaw: 0 },    // Exceeds max
      { pitch: 0, yaw: -8, expectPitch: 0, expectYaw: -6 },    // Exceeds max
      { pitch: -3, yaw: 4, expectPitch: -3, expectYaw: 4 }
    ];

    for (const test of testCases) {
      engine.setGimbal(test.pitch, test.yaw);

      console.log(`  Set: (${test.pitch}°, ${test.yaw}°) -> Actual: (${engine.gimbalPitchDeg.toFixed(1)}°, ${engine.gimbalYawDeg.toFixed(1)}°)`);

      this.assertClose(
        engine.gimbalPitchDeg,
        test.expectPitch,
        0.1,
        `Pitch gimbal ${test.pitch}° -> ${test.expectPitch}°`
      );

      this.assertClose(
        engine.gimbalYawDeg,
        test.expectYaw,
        0.1,
        `Yaw gimbal ${test.yaw}° -> ${test.expectYaw}°`
      );
    }

    console.log('');
  }

  /**
   * TEST 7: Shutdown Sequence
   * Verify engine shuts down gracefully
   */
  private testShutdownSequence(): void {
    console.log('Test 7: Shutdown Sequence');

    const engine = new MainEngine({
      shutdownTimeS: 0.5
    });

    // Start engine
    engine.ignite();
    engine.setThrottle(1.0);

    for (let i = 0; i < 30; i++) {
      engine.update(0.1, i * 0.1);
    }

    console.log(`  Running at: ${engine.currentThrustN.toFixed(0)}N`);

    // Shutdown
    engine.shutdown();

    console.log(`  Shutdown commanded, status: ${engine.status}`);

    this.assert(
      engine.status === 'shutdown',
      'Engine enters shutdown state',
      'Should be shutting down'
    );

    // Halfway through shutdown
    for (let i = 0; i < 3; i++) {
      engine.update(0.1, 3.0 + i * 0.1);
    }

    const halfwayThrust = engine.currentThrustN;

    console.log(`  Thrust after 0.3s shutdown: ${halfwayThrust.toFixed(0)}N`);

    this.assert(
      engine.status === 'shutdown',
      'Still shutting down',
      'Should not be off yet'
    );

    // Complete shutdown
    for (let i = 0; i < 5; i++) {
      engine.update(0.1, 3.3 + i * 0.1);
    }

    console.log(`  Status after 0.5s: ${engine.status}`);
    console.log(`  Thrust: ${engine.currentThrustN}N`);

    this.assert(
      engine.status === 'off',
      'Engine fully shutdown',
      'Should be off'
    );

    this.assert(
      engine.currentThrustN === 0,
      'Zero thrust when off',
      'Thrust should be zero'
    );

    console.log('');
  }

  /**
   * TEST 8: Health Degradation
   * Verify engine health decreases with use
   */
  private testHealthDegradation(): void {
    console.log('Test 8: Engine Health Degradation');

    const engine = new MainEngine();

    const initialHealth = engine.health;

    console.log(`  Initial health: ${initialHealth}%`);

    engine.ignite();
    engine.setThrottle(1.0);

    // Run for extended period
    for (let i = 0; i < 1000; i++) {
      engine.update(0.1, i * 0.1);
    }

    const finalHealth = engine.health;
    const firedTime = engine.totalFiredSeconds;

    console.log(`  After ${firedTime.toFixed(1)}s: ${finalHealth.toFixed(2)}%`);

    this.assert(
      finalHealth < initialHealth,
      'Health degrades with use',
      'Should decrease over time'
    );

    this.assert(
      engine.totalFiredSeconds > 0,
      'Fired time tracked',
      'Should track total firing time'
    );

    console.log('');
  }

  /**
   * TEST 9: Propellant Starvation
   * Verify engine shuts down when propellant runs out
   */
  private testPropellantStarvation(): void {
    console.log('Test 9: Propellant Starvation and Flameout');

    const engine = new MainEngine();

    engine.ignite();
    engine.setThrottle(1.0);

    // Run until started
    for (let i = 0; i < 30; i++) {
      engine.update(0.1, i * 0.1);
    }

    console.log(`  Engine running at ${engine.currentThrustN.toFixed(0)}N`);

    // Simulate fuel starvation (limited fuel available)
    const rates = engine.getConsumptionRates();
    const limitedFuel = rates.fuelKgPerSec * 0.1; // Only 10% of needed fuel
    const fullOxidizer = rates.oxidizerKgPerSec * 1.0;

    engine.update(1.0, 5.0);
    engine.consumePropellant(1.0, limitedFuel, fullOxidizer);

    console.log(`  After starvation, status: ${engine.status}`);

    this.assert(
      engine.status === 'shutdown' || engine.status === 'off',
      'Engine shuts down on starvation',
      'Should shutdown when starved'
    );

    console.log('');
  }

  /**
   * TEST 10: Restart Cooldown
   * Verify engine cannot be restarted immediately
   */
  private testRestartCooldown(): void {
    console.log('Test 10: Restart Cooldown Timer');

    const engine = new MainEngine();

    engine.ignite();

    console.log(`  Ignition 1: success`);
    console.log(`  Cooldown: ${engine.restartCooldownS.toFixed(1)}s`);

    this.assert(
      engine.restartCooldownS > 0,
      'Cooldown timer set',
      'Should have cooldown after ignition'
    );

    // Shutdown immediately
    engine.shutdown();

    for (let i = 0; i < 10; i++) {
      engine.update(0.1, i * 0.1);
    }

    // Try to restart immediately
    const restartSuccess = engine.ignite();

    console.log(`  Immediate restart: ${restartSuccess} (cooldown: ${engine.restartCooldownS.toFixed(1)}s)`);

    this.assert(
      !restartSuccess,
      'Cannot restart during cooldown',
      'Should prevent immediate restart'
    );

    // Wait for cooldown
    for (let i = 0; i < 50; i++) {
      engine.update(0.1, 5.0 + i * 0.1);
    }

    const delayedRestartSuccess = engine.ignite();

    console.log(`  Restart after 5s: ${delayedRestartSuccess}`);

    this.assert(
      delayedRestartSuccess,
      'Can restart after cooldown',
      'Should allow restart after cooldown'
    );

    console.log('');
  }

  /**
   * TEST 11: Thrust Vector Components
   * Verify thrust vector calculation with gimbal
   */
  private testThrustVector(): void {
    console.log('Test 11: Thrust Vector with Gimbal');

    const engine = new MainEngine();

    engine.ignite();
    engine.setThrottle(1.0);

    // Run until started
    for (let i = 0; i < 30; i++) {
      engine.update(0.1, i * 0.1);
    }

    // No gimbal - pure axial thrust
    engine.setGimbal(0, 0);
    const vectorNoGimbal = engine.getThrustVector();

    console.log(`  No gimbal: x=${vectorNoGimbal.x.toFixed(0)}N, y=${vectorNoGimbal.y.toFixed(0)}N, z=${vectorNoGimbal.z.toFixed(0)}N`);

    this.assertClose(
      vectorNoGimbal.x,
      0,
      100,
      'No X component without gimbal'
    );

    this.assertClose(
      vectorNoGimbal.y,
      0,
      100,
      'No Y component without gimbal'
    );

    this.assertClose(
      vectorNoGimbal.z,
      engine.currentThrustN,
      100,
      'Z component equals thrust'
    );

    // With gimbal
    engine.setGimbal(5, 3); // 5° pitch, 3° yaw

    const vectorWithGimbal = engine.getThrustVector();

    console.log(`  With gimbal (5°, 3°): x=${vectorWithGimbal.x.toFixed(0)}N, y=${vectorWithGimbal.y.toFixed(0)}N, z=${vectorWithGimbal.z.toFixed(0)}N`);

    this.assert(
      Math.abs(vectorWithGimbal.x) > 100,
      'X component present with pitch gimbal',
      'Should have X component'
    );

    this.assert(
      Math.abs(vectorWithGimbal.y) > 100,
      'Y component present with yaw gimbal',
      'Should have Y component'
    );

    // Verify magnitude equals thrust
    const magnitude = Math.sqrt(
      vectorWithGimbal.x ** 2 +
      vectorWithGimbal.y ** 2 +
      vectorWithGimbal.z ** 2
    );

    console.log(`  Vector magnitude: ${magnitude.toFixed(0)}N (thrust: ${engine.currentThrustN.toFixed(0)}N)`);

    this.assertClose(
      magnitude,
      engine.currentThrustN,
      100,
      'Vector magnitude equals thrust'
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
const tester = new MainEngineTester();
tester.runAll();
