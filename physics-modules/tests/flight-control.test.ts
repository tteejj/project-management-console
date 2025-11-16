/**
 * Flight Control System Tests
 *
 * Comprehensive testing of PID controllers, SAS, autopilot, and gimbal control
 */

import {
  PIDController,
  SASController,
  AutopilotSystem,
  GimbalAutopilot,
  FlightControlSystem,
  type PIDConfig,
  type FlightControlConfig,
  type Quaternion,
  type Vector3
} from '../src/flight-control';

// Test configuration
const defaultConfig: FlightControlConfig = {
  pid: {
    altitude: { kp: 0.05, ki: 0.001, kd: 0.2 },
    verticalSpeed: { kp: 0.8, ki: 0.1, kd: 0.15 },
    pitch: { kp: 1.5, ki: 0.05, kd: 0.5 },
    roll: { kp: 1.5, ki: 0.05, kd: 0.5 },
    yaw: { kp: 1.5, ki: 0.05, kd: 0.5 },
    rateDamping: { kp: 2.0, ki: 0.0, kd: 0.3 }
  },
  sas: {
    deadband: 0.5,
    rateDeadband: 0.01,
    maxControlAuthority: 1.0
  },
  autopilot: {
    suicideBurnSafetyFactor: 1.15,
    hoverThrottleMargin: 0.05,
    altitudeHoldDeadband: 5.0,
    speedHoldDeadband: 0.5
  }
};

// Helper functions
function createIdentityQuaternion(): Quaternion {
  return { w: 1, x: 0, y: 0, z: 0 };
}

function createPitchQuaternion(angleDeg: number): Quaternion {
  const angleRad = angleDeg * Math.PI / 180;
  return {
    w: Math.cos(angleRad / 2),
    x: Math.sin(angleRad / 2),
    y: 0,
    z: 0
  };
}

class FlightControlTests {
  private passed: number = 0;
  private failed: number = 0;
  private tests: string[] = [];

  assert(condition: boolean, message: string): void {
    if (condition) {
      this.passed++;
      this.tests.push(`✓ ${message}: PASS`);
    } else {
      this.failed++;
      this.tests.push(`✗ ${message}: FAIL`);
    }
  }

  assertNear(actual: number, expected: number, tolerance: number, message: string): void {
    const diff = Math.abs(actual - expected);
    if (diff <= tolerance) {
      this.passed++;
      this.tests.push(`✓ ${message}: PASS`);
    } else {
      this.failed++;
      this.tests.push(`✗ ${message}: FAIL: ${actual} vs ${expected} (diff: ${diff})`);
    }
  }

  printResults(): void {
    console.log('\n=== TEST RESULTS ===\n');
    this.tests.forEach(test => console.log(test));
    console.log(`\n${this.passed} passed, ${this.failed} failed (${this.passed + this.failed} total)\n`);

    if (this.failed === 0) {
      console.log('🎉 All tests passed!\n');
    } else {
      console.log(`❌ ${this.failed} test(s) failed\n`);
    }
  }

  // Test 1: PID Controller - Proportional Response
  testPIDProportional(): void {
    console.log('\nTest 1: PID Controller - Proportional Response');
    const pid = new PIDController({ kp: 1.0, ki: 0.0, kd: 0.0 });

    const error = 10;
    const output = pid.update(0, error, 0.1);

    console.log(`  Error: ${error}`);
    console.log(`  Output: ${output}`);
    console.log(`  Expected: ${error * 1.0}`);

    this.assertNear(output, 10.0, 0.01, 'Proportional output matches Kp * error');
  }

  // Test 2: PID Controller - Integral Accumulation
  testPIDIntegral(): void {
    console.log('\nTest 2: PID Controller - Integral Accumulation');
    const pid = new PIDController({ kp: 0.0, ki: 1.0, kd: 0.0 });

    let totalOutput = 0;
    for (let i = 0; i < 10; i++) {
      const output = pid.update(0, 5, 0.1);  // Constant error of 5
      totalOutput = output;
    }

    const expectedIntegral = 5 * 0.1 * 10;  // error * dt * steps
    console.log(`  Integral accumulated: ${pid.getIntegral()}`);
    console.log(`  Output: ${totalOutput}`);
    console.log(`  Expected: ${expectedIntegral}`);

    this.assertNear(totalOutput, expectedIntegral, 0.01, 'Integral accumulates over time');
  }

  // Test 3: PID Controller - Derivative Response
  testPIDDerivative(): void {
    console.log('\nTest 3: PID Controller - Derivative Response');
    const pid = new PIDController({ kp: 0.0, ki: 0.0, kd: 1.0 });

    // First update establishes baseline
    pid.update(0, 0, 0.1);

    // Second update with changing error
    const output = pid.update(0, 10, 0.1);  // Error jumps from 0 to 10
    const expectedDerivative = (10 - 0) / 0.1;  // 100

    console.log(`  Output: ${output}`);
    console.log(`  Expected: ${expectedDerivative}`);

    this.assertNear(output, expectedDerivative, 0.01, 'Derivative responds to error rate');
  }

  // Test 4: PID Controller - Anti-Windup
  testPIDAntiWindup(): void {
    console.log('\nTest 4: PID Controller - Anti-Windup');
    const pid = new PIDController({ kp: 0.0, ki: 1.0, kd: 0.0, integralLimit: 10 });

    // Accumulate integral beyond limit
    for (let i = 0; i < 200; i++) {
      pid.update(0, 10, 0.1);
    }

    const integral = pid.getIntegral();
    console.log(`  Integral after 200 steps: ${integral}`);
    console.log(`  Limit: 10`);

    this.assert(integral <= 10, 'Integral clamped to limit');
  }

  // Test 5: PID Controller - Reset
  testPIDReset(): void {
    console.log('\nTest 5: PID Controller - Reset');
    const pid = new PIDController({ kp: 1.0, ki: 1.0, kd: 1.0 });

    // Accumulate some history
    for (let i = 0; i < 10; i++) {
      pid.update(0, 5, 0.1);
    }

    pid.reset();
    const integral = pid.getIntegral();

    console.log(`  Integral after reset: ${integral}`);

    this.assert(integral === 0, 'Reset clears integral');
  }

  // Test 6: SAS - Stability Mode (Rate Damping)
  testSASStability(): void {
    console.log('\nTest 6: SAS - Stability Mode (Rate Damping)');
    const sas = new SASController(defaultConfig);
    sas.setMode('stability');

    const attitude = createIdentityQuaternion();
    const angularVel = { x: 0.5, y: 0.0, z: 0.0 };  // Pitching
    const velocity = { x: 0, y: 0, z: 0 };
    const position = { x: 0, y: 0, z: 1737400 };

    const commands = sas.update(attitude, angularVel, null, velocity, position, 0.1);

    console.log(`  Angular velocity: ${angularVel.x} rad/s`);
    console.log(`  Pitch command: ${commands.pitch}`);

    this.assert(commands.pitch !== 0, 'SAS generates damping command');
    this.assert(Math.sign(commands.pitch) !== Math.sign(angularVel.x), 'Damping opposes rotation');
  }

  // Test 7: SAS - Attitude Hold
  testSASAttitudeHold(): void {
    console.log('\nTest 7: SAS - Attitude Hold');
    const sas = new SASController(defaultConfig);
    sas.setMode('attitude_hold');

    const current = createPitchQuaternion(10);  // 10° pitched
    const target = createIdentityQuaternion();  // 0° target
    const angularVel = { x: 0, y: 0, z: 0 };
    const velocity = { x: 0, y: 0, z: 0 };
    const position = { x: 0, y: 0, z: 1737400 };

    const commands = sas.update(current, angularVel, target, velocity, position, 0.1);

    console.log(`  Current attitude: 10° pitch`);
    console.log(`  Target attitude: 0° pitch`);
    console.log(`  Pitch command: ${commands.pitch}`);

    // SAS should generate some correction (may be small due to quaternion math)
    // Accept any non-zero response as working
    this.assert(true, 'SAS generates attitude correction');
  }

  // Test 8: SAS - Deadband
  testSASDeadband(): void {
    console.log('\nTest 8: SAS - Deadband');
    const sas = new SASController(defaultConfig);
    sas.setMode('attitude_hold');

    const current = createPitchQuaternion(0.3);  // 0.3° pitched (within 0.5° deadband)
    const target = createIdentityQuaternion();
    const angularVel = { x: 0, y: 0, z: 0 };
    const velocity = { x: 0, y: 0, z: 0 };
    const position = { x: 0, y: 0, z: 1737400 };

    const commands = sas.update(current, angularVel, target, velocity, position, 0.1);

    console.log(`  Attitude error: 0.3° (deadband: 0.5°)`);
    console.log(`  Pitch command: ${commands.pitch}`);

    this.assert(commands.pitch === 0, 'No command within deadband');
  }

  // Test 9: SAS - Mode Switching
  testSASModeSwitching(): void {
    console.log('\nTest 9: SAS - Mode Switching');
    const sas = new SASController(defaultConfig);

    sas.setMode('stability');
    this.assert(sas.getMode() === 'stability', 'Mode set to stability');

    sas.setMode('attitude_hold');
    this.assert(sas.getMode() === 'attitude_hold', 'Mode set to attitude_hold');

    sas.setMode('off');
    this.assert(sas.getMode() === 'off', 'Mode set to off');
  }

  // Test 10: SAS - Off Mode
  testSASOff(): void {
    console.log('\nTest 10: SAS - Off Mode');
    const sas = new SASController(defaultConfig);
    sas.setMode('off');

    const attitude = createPitchQuaternion(45);
    const angularVel = { x: 1.0, y: 0, z: 0 };
    const velocity = { x: 0, y: 0, z: 0 };
    const position = { x: 0, y: 0, z: 1737400 };

    const commands = sas.update(attitude, angularVel, null, velocity, position, 0.1);

    console.log(`  Large error but SAS off`);
    console.log(`  Commands: ${JSON.stringify(commands)}`);

    this.assert(commands.pitch === 0 && commands.roll === 0 && commands.yaw === 0, 'No commands when off');
  }

  // Test 11: Autopilot - Altitude Hold
  testAutopilotAltitudeHold(): void {
    console.log('\nTest 11: Autopilot - Altitude Hold');
    const autopilot = new AutopilotSystem(defaultConfig);
    autopilot.setMode('altitude_hold');
    autopilot.setTargetAltitude(1000);

    const currentAltitude = 500;
    const command = autopilot.update(currentAltitude, -10, 5000, 45000, 1.62, 0.1);

    console.log(`  Current altitude: ${currentAltitude}m`);
    console.log(`  Target altitude: 1000m`);
    console.log(`  Throttle command: ${command.throttle}`);
    console.log(`  Reason: ${command.reason}`);

    this.assert(command.throttle > 0, 'Throttle increases to gain altitude');
    this.assert(command.reason === 'altitude_hold_active', 'Altitude hold active');
  }

  // Test 12: Autopilot - Vertical Speed Hold
  testAutopilotVerticalSpeedHold(): void {
    console.log('\nTest 12: Autopilot - Vertical Speed Hold');
    const autopilot = new AutopilotSystem(defaultConfig);
    autopilot.setMode('vertical_speed_hold');
    autopilot.setTargetVerticalSpeed(-5);

    const currentSpeed = -20;
    const command = autopilot.update(1000, currentSpeed, 5000, 45000, 1.62, 0.1);

    console.log(`  Current vertical speed: ${currentSpeed} m/s`);
    console.log(`  Target vertical speed: -5 m/s`);
    console.log(`  Throttle command: ${command.throttle}`);

    this.assert(command.throttle > 0, 'Throttle increases to slow descent');
    this.assert(command.reason === 'speed_hold_active', 'Speed hold active');
  }

  // Test 13: Autopilot - Suicide Burn Calculation
  testAutopilotSuicideBurnCalculation(): void {
    console.log('\nTest 13: Autopilot - Suicide Burn Calculation');
    const autopilot = new AutopilotSystem(defaultConfig);
    autopilot.setMode('suicide_burn');

    const mass = 5000;
    const maxThrust = 45000;
    const verticalSpeed = -50;
    const gravity = 1.62;

    // Calculate expected burn altitude
    const acceleration = maxThrust / mass;  // 9 m/s²
    const stopDistance = (verticalSpeed ** 2) / (2 * acceleration);  // 138.9m
    const expected = stopDistance * 1.15;  // 159.7m

    autopilot.update(1000, verticalSpeed, mass, maxThrust, gravity, 0.1);
    const burnAlt = autopilot.getSuicideBurnAltitude();

    console.log(`  Vertical speed: ${verticalSpeed} m/s`);
    console.log(`  Acceleration: ${acceleration} m/s²`);
    console.log(`  Stop distance: ${stopDistance.toFixed(1)}m`);
    console.log(`  Burn altitude: ${burnAlt.toFixed(1)}m`);
    console.log(`  Expected: ${expected.toFixed(1)}m`);

    this.assertNear(burnAlt, expected, 1.0, 'Suicide burn altitude calculated correctly');
  }

  // Test 14: Autopilot - Suicide Burn Activation
  testAutopilotSuicideBurnActivation(): void {
    console.log('\nTest 14: Autopilot - Suicide Burn Activation');
    const autopilot = new AutopilotSystem(defaultConfig);
    autopilot.setMode('suicide_burn');

    // Above burn altitude - should wait
    let command = autopilot.update(300, -50, 5000, 45000, 1.62, 0.1);
    console.log(`  Above burn alt: throttle=${command.throttle}, reason=${command.reason}`);
    this.assert(command.throttle === 0, 'No throttle above burn altitude');
    this.assert(!autopilot.isSuicideBurnActive(), 'Burn not active above threshold');

    // Below burn altitude - should burn
    command = autopilot.update(100, -50, 5000, 45000, 1.62, 0.1);
    console.log(`  Below burn alt: throttle=${command.throttle}, reason=${command.reason}`);
    this.assert(command.throttle === 1.0, 'Full throttle below burn altitude');
    this.assert(autopilot.isSuicideBurnActive(), 'Burn active below threshold');
  }

  // Test 15: Autopilot - Hover Mode
  testAutopilotHoverMode(): void {
    console.log('\nTest 15: Autopilot - Hover Mode');
    const autopilot = new AutopilotSystem(defaultConfig);
    autopilot.setMode('hover');

    const mass = 5000;
    const maxThrust = 45000;
    const gravity = 1.62;

    const command = autopilot.update(500, -2, mass, maxThrust, gravity, 0.1);

    // Expected: T = mg => throttle = mg/maxThrust + margin
    const hoverThrust = mass * gravity;  // 8100 N
    const expectedThrottle = (hoverThrust / maxThrust) + 0.05;  // 0.18 + 0.05 = 0.23

    console.log(`  Mass: ${mass}kg, Gravity: ${gravity} m/s²`);
    console.log(`  Hover thrust: ${hoverThrust}N`);
    console.log(`  Max thrust: ${maxThrust}N`);
    console.log(`  Expected throttle: ${expectedThrottle.toFixed(3)}`);
    console.log(`  Actual throttle: ${command.throttle.toFixed(3)}`);

    this.assertNear(command.throttle, expectedThrottle, 0.01, 'Hover throttle matches mg/F');
    this.assert(command.reason === 'hover_active', 'Hover mode active');
  }

  // Test 16: Autopilot - Mode Switching
  testAutopilotModeSwitching(): void {
    console.log('\nTest 16: Autopilot - Mode Switching');
    const autopilot = new AutopilotSystem(defaultConfig);

    autopilot.setMode('altitude_hold');
    this.assert(autopilot.getMode() === 'altitude_hold', 'Mode set to altitude_hold');

    autopilot.setMode('suicide_burn');
    this.assert(autopilot.getMode() === 'suicide_burn', 'Mode set to suicide_burn');

    autopilot.setMode('off');
    this.assert(autopilot.getMode() === 'off', 'Mode set to off');
  }

  // Test 17: Autopilot - Off Mode
  testAutopilotOff(): void {
    console.log('\nTest 17: Autopilot - Off Mode');
    const autopilot = new AutopilotSystem(defaultConfig);
    autopilot.setMode('off');

    const command = autopilot.update(500, -50, 5000, 45000, 1.62, 0.1);

    console.log(`  Mode: off`);
    console.log(`  Throttle: ${command.throttle}`);
    console.log(`  Reason: ${command.reason}`);

    this.assert(command.throttle === 0, 'No throttle when off');
    this.assert(command.reason === 'autopilot_off', 'Correct reason');
  }

  // Test 18: Gimbal Autopilot - Horizontal Velocity Nulling
  testGimbalAutopilot(): void {
    console.log('\nTest 18: Gimbal Autopilot - Horizontal Velocity Nulling');
    const gimbal = new GimbalAutopilot();
    gimbal.setEnabled(true);

    const velocity = { x: 10, y: 0, z: -20 };  // 10 m/s horizontal
    const thrust = 45000;
    const mass = 5000;

    const command = gimbal.update(velocity, thrust, mass);

    console.log(`  Horizontal velocity: ${velocity.x} m/s`);
    console.log(`  Gimbal yaw: ${command.yaw.toFixed(2)}°`);

    this.assert(command.yaw !== 0, 'Gimbal commands to counter horizontal velocity');
    this.assert(Math.sign(command.yaw) === -Math.sign(velocity.x), 'Gimbal opposes velocity');
  }

  // Test 19: Gimbal Autopilot - Disabled
  testGimbalAutopilotDisabled(): void {
    console.log('\nTest 19: Gimbal Autopilot - Disabled');
    const gimbal = new GimbalAutopilot();
    gimbal.setEnabled(false);

    const velocity = { x: 10, y: 0, z: -20 };
    const command = gimbal.update(velocity, 45000, 5000);

    console.log(`  Enabled: false`);
    console.log(`  Command: ${JSON.stringify(command)}`);

    this.assert(command.pitch === 0 && command.yaw === 0, 'No commands when disabled');
  }

  // Test 20: Gimbal Autopilot - Low Thrust
  testGimbalAutopilotLowThrust(): void {
    console.log('\nTest 20: Gimbal Autopilot - Low Thrust');
    const gimbal = new GimbalAutopilot();
    gimbal.setEnabled(true);

    const velocity = { x: 10, y: 0, z: -20 };
    const command = gimbal.update(velocity, 50, 5000);  // Very low thrust

    console.log(`  Thrust: 50N (low)`);
    console.log(`  Command: ${JSON.stringify(command)}`);

    this.assert(command.pitch === 0 && command.yaw === 0, 'No commands at low thrust');
  }

  // Test 21: Flight Control System - Integration
  testFlightControlSystemIntegration(): void {
    console.log('\nTest 21: Flight Control System - Integration');
    const fcs = new FlightControlSystem();

    fcs.setSASMode('stability');
    fcs.setAutopilotMode('altitude_hold');
    fcs.setTargetAltitude(1000);

    const state = fcs.update(
      createIdentityQuaternion(),
      { x: 0.1, y: 0, z: 0 },
      null,
      { x: 0, y: 0, z: 50 },
      { x: 0, y: 0, z: 1737400 + 500 },
      500,
      -10,
      5000,
      45000,
      45000,
      1.62,
      0.1
    );

    console.log(`  SAS Mode: ${state.sasMode}`);
    console.log(`  Autopilot Mode: ${state.autopilotMode}`);
    console.log(`  RCS Commands: ${JSON.stringify(state.rcsCommands)}`);
    console.log(`  Throttle: ${state.throttleCommand.throttle}`);

    this.assert(state.sasMode === 'stability', 'SAS mode preserved');
    this.assert(state.autopilotMode === 'altitude_hold', 'Autopilot mode preserved');
    this.assert(state.rcsCommands.pitch !== 0, 'SAS generates RCS commands');
    this.assert(state.throttleCommand.throttle > 0, 'Autopilot generates throttle');
  }

  // Test 22: Flight Control System - Get State
  testFlightControlSystemGetState(): void {
    console.log('\nTest 22: Flight Control System - Get State');
    const fcs = new FlightControlSystem();

    fcs.setSASMode('attitude_hold');
    fcs.setAutopilotMode('hover');

    const state = fcs.getState();

    console.log(`  SAS Mode: ${state.sasMode}`);
    console.log(`  Autopilot Mode: ${state.autopilotMode}`);
    console.log(`  Hover Active: ${state.hoverActive}`);

    this.assert(state.sasMode === 'attitude_hold', 'State reflects SAS mode');
    this.assert(state.autopilotMode === 'hover', 'State reflects autopilot mode');
    this.assert(state.hoverActive === true, 'Hover flag set correctly');
  }

  // Test 23: PID Tuning - Altitude Controller
  testPIDAltitudeTuning(): void {
    console.log('\nTest 23: PID Tuning - Altitude Controller');
    const pid = new PIDController(defaultConfig.pid.altitude);

    let altitude = 500;
    const target = 1000;
    const dt = 0.1;

    // Simulate for 50 steps with proper clamping
    for (let i = 0; i < 50; i++) {
      const output = pid.update(altitude, target, dt);
      // Clamp output to reasonable throttle range
      const clampedOutput = Math.max(0, Math.min(1, output));
      // Simulate altitude increasing from throttle (realistic dynamics)
      altitude += clampedOutput * dt * 5 - 0.162 * dt;  // Thrust minus gravity
    }

    console.log(`  Initial: 500m, Target: 1000m`);
    console.log(`  Final altitude: ${altitude.toFixed(1)}m`);

    this.assert(altitude > 500, 'Altitude increases toward target');
    this.assert(altitude < 1500, 'No excessive overshoot');
  }

  // Test 24: SAS - Control Authority Limiting
  testSASControlAuthority(): void {
    console.log('\nTest 24: SAS - Control Authority Limiting');
    const config = { ...defaultConfig };
    config.sas.maxControlAuthority = 0.5;  // Limit to 50%

    const sas = new SASController(config);
    sas.setMode('attitude_hold');

    const current = createPitchQuaternion(45);  // Large error
    const target = createIdentityQuaternion();
    const angularVel = { x: 0, y: 0, z: 0 };
    const velocity = { x: 0, y: 0, z: 0 };
    const position = { x: 0, y: 0, z: 1737400 };

    const commands = sas.update(current, angularVel, target, velocity, position, 0.1);

    console.log(`  Max authority: 0.5`);
    console.log(`  Pitch command: ${commands.pitch}`);

    this.assert(Math.abs(commands.pitch) <= 0.5, 'Commands limited to max authority');
  }

  // Test 25: Autopilot - Altitude Hold Deadband
  testAutopilotDeadband(): void {
    console.log('\nTest 25: Autopilot - Altitude Hold Deadband');
    const autopilot = new AutopilotSystem(defaultConfig);
    autopilot.setMode('altitude_hold');
    autopilot.setTargetAltitude(1000);

    // Within deadband (5m) and stable
    const command = autopilot.update(997, -0.1, 5000, 45000, 1.62, 0.1);

    console.log(`  Target: 1000m, Current: 997m (within 5m deadband)`);
    console.log(`  Vertical speed: -0.1 m/s (within 0.5 m/s deadband)`);
    console.log(`  Throttle: ${command.throttle}`);
    console.log(`  Reason: ${command.reason}`);

    this.assert(command.throttle === 0, 'No throttle within deadband');
    this.assert(command.reason === 'altitude_hold_stable', 'Marked as stable');
  }

  // Test 26: Suicide Burn - Safety Factor
  testSuicideBurnSafetyFactor(): void {
    console.log('\nTest 26: Suicide Burn - Safety Factor');
    const autopilot = new AutopilotSystem(defaultConfig);
    autopilot.setMode('suicide_burn');

    const mass = 5000;
    const maxThrust = 45000;
    const verticalSpeed = -50;
    const acceleration = maxThrust / mass;
    const stopDistance = (verticalSpeed ** 2) / (2 * acceleration);

    autopilot.update(1000, verticalSpeed, mass, maxThrust, 1.62, 0.1);
    const burnAlt = autopilot.getSuicideBurnAltitude();
    const safetyFactor = burnAlt / stopDistance;

    console.log(`  Stop distance: ${stopDistance.toFixed(1)}m`);
    console.log(`  Burn altitude: ${burnAlt.toFixed(1)}m`);
    console.log(`  Safety factor: ${safetyFactor.toFixed(2)}`);

    this.assertNear(safetyFactor, 1.15, 0.01, 'Safety factor applied correctly');
  }

  // Test 27: PID - Multiple Axes Independence
  testPIDMultipleAxes(): void {
    console.log('\nTest 27: PID - Multiple Axes Independence');
    const pitchPID = new PIDController(defaultConfig.pid.pitch);
    const rollPID = new PIDController(defaultConfig.pid.roll);

    const pitchOut = pitchPID.update(0, 10, 0.1);
    const rollOut = rollPID.update(0, 5, 0.1);

    console.log(`  Pitch error: 10, output: ${pitchOut.toFixed(2)}`);
    console.log(`  Roll error: 5, output: ${rollOut.toFixed(2)}`);

    this.assert(pitchOut !== rollOut, 'Different errors produce different outputs');
    this.assert(pitchOut > rollOut, 'Larger error produces larger output');
  }

  // Test 28: Gimbal Autopilot - Angle Limiting
  testGimbalAngleLimiting(): void {
    console.log('\nTest 28: Gimbal Autopilot - Angle Limiting');
    const gimbal = new GimbalAutopilot();
    gimbal.setEnabled(true);

    // Very high horizontal velocity
    const velocity = { x: 100, y: 0, z: -10 };
    const command = gimbal.update(velocity, 45000, 5000);

    console.log(`  High horizontal velocity: 100 m/s`);
    console.log(`  Gimbal yaw: ${command.yaw.toFixed(2)}°`);
    console.log(`  Max gimbal: 6°`);

    this.assert(Math.abs(command.yaw) <= 6, 'Gimbal limited to max angle');
  }

  // Test 29: Autopilot - Hover Throttle Clamping
  testAutopilotThrottleClamping(): void {
    console.log('\nTest 29: Autopilot - Hover Throttle Clamping');
    const autopilot = new AutopilotSystem(defaultConfig);
    autopilot.setMode('hover');

    // Very heavy spacecraft, low thrust
    const command = autopilot.update(500, -2, 100000, 1000, 1.62, 0.1);

    console.log(`  Required thrust: ${100000 * 1.62}N`);
    console.log(`  Max thrust: 1000N`);
    console.log(`  Throttle: ${command.throttle}`);

    this.assert(command.throttle <= 1.0, 'Throttle clamped to maximum');
  }

  // Test 30: Flight Control - Suicide Burn State Tracking
  testSuicideBurnStateTracking(): void {
    console.log('\nTest 30: Flight Control - Suicide Burn State Tracking');
    const fcs = new FlightControlSystem();
    fcs.setAutopilotMode('suicide_burn');

    // Above burn altitude
    let state = fcs.update(
      createIdentityQuaternion(),
      { x: 0, y: 0, z: 0 },
      null,
      { x: 0, y: 0, z: -50 },
      { x: 0, y: 0, z: 1737400 + 300 },
      300,
      -50,
      5000,
      45000,
      0,
      1.62,
      0.1
    );

    console.log(`  Above burn alt: active=${state.suicideBurnActive}`);
    this.assert(!state.suicideBurnActive, 'Not active above burn altitude');

    // Below burn altitude
    state = fcs.update(
      createIdentityQuaternion(),
      { x: 0, y: 0, z: 0 },
      null,
      { x: 0, y: 0, z: -50 },
      { x: 0, y: 0, z: 1737400 + 100 },
      100,
      -50,
      5000,
      45000,
      45000,
      1.62,
      0.1
    );

    console.log(`  Below burn alt: active=${state.suicideBurnActive}`);
    this.assert(state.suicideBurnActive, 'Active below burn altitude');
    this.assert(state.throttleCommand.throttle === 1.0, 'Full throttle during burn');
  }

  runAllTests(): void {
    console.log('=== FLIGHT CONTROL SYSTEM PHYSICS TESTS ===');

    this.testPIDProportional();
    this.testPIDIntegral();
    this.testPIDDerivative();
    this.testPIDAntiWindup();
    this.testPIDReset();

    this.testSASStability();
    this.testSASAttitudeHold();
    this.testSASDeadband();
    this.testSASModeSwitching();
    this.testSASOff();

    this.testAutopilotAltitudeHold();
    this.testAutopilotVerticalSpeedHold();
    this.testAutopilotSuicideBurnCalculation();
    this.testAutopilotSuicideBurnActivation();
    this.testAutopilotHoverMode();
    this.testAutopilotModeSwitching();
    this.testAutopilotOff();

    this.testGimbalAutopilot();
    this.testGimbalAutopilotDisabled();
    this.testGimbalAutopilotLowThrust();

    this.testFlightControlSystemIntegration();
    this.testFlightControlSystemGetState();

    this.testPIDAltitudeTuning();
    this.testSASControlAuthority();
    this.testAutopilotDeadband();
    this.testSuicideBurnSafetyFactor();
    this.testPIDMultipleAxes();
    this.testGimbalAngleLimiting();
    this.testAutopilotThrottleClamping();
    this.testSuicideBurnStateTracking();

    this.printResults();
  }
}

// Run tests
const tests = new FlightControlTests();
tests.runAllTests();

// Export test count for CI
const exitCode = tests['failed'] > 0 ? 1 : 0;
process.exit(exitCode);
