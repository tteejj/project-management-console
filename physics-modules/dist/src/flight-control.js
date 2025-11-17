"use strict";
/**
 * Flight Control System
 *
 * Provides autopilot, PID control, and stability augmentation for spacecraft.
 * Implements closed-loop control systems for automated flight operations.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.FlightControlSystem = exports.GimbalAutopilot = exports.AutopilotSystem = exports.SASController = exports.PIDController = void 0;
/**
 * PID Controller
 * Implements proportional-integral-derivative control
 */
class PIDController {
    constructor(config) {
        this.integral = 0;
        this.previousError = 0;
        this.firstUpdate = true;
        this.kp = config.kp;
        this.ki = config.ki;
        this.kd = config.kd;
        this.integralLimit = config.integralLimit ?? 100;
    }
    update(currentValue, targetValue, dt) {
        const error = targetValue - currentValue;
        // Integral with anti-windup
        this.integral += error * dt;
        this.integral = Math.max(-this.integralLimit, Math.min(this.integralLimit, this.integral));
        // Derivative (avoid spike on first update)
        let derivative = 0;
        if (!this.firstUpdate) {
            derivative = (error - this.previousError) / dt;
        }
        this.firstUpdate = false;
        this.previousError = error;
        const output = (this.kp * error) + (this.ki * this.integral) + (this.kd * derivative);
        return output;
    }
    reset() {
        this.integral = 0;
        this.previousError = 0;
        this.firstUpdate = true;
    }
    getIntegral() {
        return this.integral;
    }
}
exports.PIDController = PIDController;
/**
 * Stability Augmentation System (SAS)
 * Provides attitude stabilization and automatic orientation control
 */
class SASController {
    constructor(config) {
        this.mode = 'off';
        this.config = config.sas;
        this.pitchPID = new PIDController(config.pid.pitch);
        this.rollPID = new PIDController(config.pid.roll);
        this.yawPID = new PIDController(config.pid.yaw);
        this.pitchRatePID = new PIDController(config.pid.rateDamping);
        this.rollRatePID = new PIDController(config.pid.rateDamping);
        this.yawRatePID = new PIDController(config.pid.rateDamping);
    }
    setMode(mode) {
        this.mode = mode;
        // Reset PIDs when mode changes
        this.pitchPID.reset();
        this.rollPID.reset();
        this.yawPID.reset();
        this.pitchRatePID.reset();
        this.rollRatePID.reset();
        this.yawRatePID.reset();
    }
    getMode() {
        return this.mode;
    }
    update(currentAttitude, currentAngularVel, targetAttitude, velocity, position, dt) {
        if (this.mode === 'off') {
            return { pitch: 0, roll: 0, yaw: 0 };
        }
        // Determine target orientation based on mode
        let target = targetAttitude;
        if (this.mode === 'prograde') {
            target = this.calculateProgradeAttitude(velocity);
        }
        else if (this.mode === 'retrograde') {
            target = this.calculateRetrogradeAttitude(velocity);
        }
        else if (this.mode === 'radial_in') {
            target = this.calculateRadialInAttitude(position);
        }
        else if (this.mode === 'radial_out') {
            target = this.calculateRadialOutAttitude(position);
        }
        else if (this.mode === 'attitude_hold' && !target) {
            target = currentAttitude; // Hold current attitude
        }
        if (this.mode === 'stability') {
            // Pure rate damping, no attitude control
            return this.calculateRateDamping(currentAngularVel, dt);
        }
        if (!target) {
            return { pitch: 0, roll: 0, yaw: 0 };
        }
        // Calculate attitude error
        const errorQuat = this.quaternionDifference(target, currentAttitude);
        const errorAngles = this.quaternionToEuler(errorQuat);
        // PID control for each axis (within deadband check)
        let pitchCmd = 0;
        let rollCmd = 0;
        let yawCmd = 0;
        const deadband = this.config.deadband * (Math.PI / 180); // Convert to radians
        if (Math.abs(errorAngles.pitch) > deadband) {
            pitchCmd = this.pitchPID.update(0, errorAngles.pitch, dt);
        }
        if (Math.abs(errorAngles.roll) > deadband) {
            rollCmd = this.rollPID.update(0, errorAngles.roll, dt);
        }
        if (Math.abs(errorAngles.yaw) > deadband) {
            yawCmd = this.yawPID.update(0, errorAngles.yaw, dt);
        }
        // Add rate damping
        const rateDamping = this.calculateRateDamping(currentAngularVel, dt);
        pitchCmd += rateDamping.pitch;
        rollCmd += rateDamping.roll;
        yawCmd += rateDamping.yaw;
        // Clamp to control authority
        const maxAuth = this.config.maxControlAuthority;
        return {
            pitch: Math.max(-maxAuth, Math.min(maxAuth, pitchCmd)),
            roll: Math.max(-maxAuth, Math.min(maxAuth, rollCmd)),
            yaw: Math.max(-maxAuth, Math.min(maxAuth, yawCmd))
        };
    }
    calculateRateDamping(angularVel, dt) {
        const deadband = this.config.rateDeadband;
        let pitchDamp = 0;
        let rollDamp = 0;
        let yawDamp = 0;
        if (Math.abs(angularVel.x) > deadband) {
            pitchDamp = this.pitchRatePID.update(angularVel.x, 0, dt);
        }
        if (Math.abs(angularVel.y) > deadband) {
            rollDamp = this.rollRatePID.update(angularVel.y, 0, dt);
        }
        if (Math.abs(angularVel.z) > deadband) {
            yawDamp = this.yawRatePID.update(angularVel.z, 0, dt);
        }
        return { pitch: pitchDamp, roll: rollDamp, yaw: yawDamp };
    }
    calculateProgradeAttitude(velocity) {
        // Point spacecraft in direction of velocity
        const velNorm = this.normalize(velocity);
        return this.vectorToQuaternion(velNorm);
    }
    calculateRetrogradeAttitude(velocity) {
        // Point spacecraft opposite to velocity
        const velNorm = this.normalize(velocity);
        return this.vectorToQuaternion({ x: -velNorm.x, y: -velNorm.y, z: -velNorm.z });
    }
    calculateRadialInAttitude(position) {
        // Point toward planet center (opposite to position vector)
        const posNorm = this.normalize(position);
        return this.vectorToQuaternion({ x: -posNorm.x, y: -posNorm.y, z: -posNorm.z });
    }
    calculateRadialOutAttitude(position) {
        // Point away from planet center
        const posNorm = this.normalize(position);
        return this.vectorToQuaternion(posNorm);
    }
    vectorToQuaternion(direction) {
        // Align Z-axis with direction vector
        // Build orthonormal basis: [right, up, forward]
        // Normalize direction to get forward vector
        const forward = this.normalize(direction);
        // Choose a reasonable up vector (avoid singularity when direction is vertical)
        let up = { x: 0, y: 1, z: 0 };
        if (Math.abs(forward.y) > 0.99) {
            // If nearly vertical, use X-axis as reference
            up = { x: 1, y: 0, z: 0 };
        }
        // Right = up × forward
        const right = this.normalize(this.crossProduct(up, forward));
        // Recalculate up = forward × right (ensure orthogonality)
        const newUp = this.crossProduct(forward, right);
        // Build rotation matrix (column-major: [right, up, forward])
        // Convert rotation matrix to quaternion using standard algorithm
        const trace = right.x + newUp.y + forward.z;
        if (trace > 0) {
            const s = 0.5 / Math.sqrt(trace + 1.0);
            return {
                w: 0.25 / s,
                x: (newUp.z - forward.y) * s,
                y: (forward.x - right.z) * s,
                z: (right.y - newUp.x) * s
            };
        }
        else if (right.x > newUp.y && right.x > forward.z) {
            const s = 2.0 * Math.sqrt(1.0 + right.x - newUp.y - forward.z);
            return {
                w: (newUp.z - forward.y) / s,
                x: 0.25 * s,
                y: (newUp.x + right.y) / s,
                z: (forward.x + right.z) / s
            };
        }
        else if (newUp.y > forward.z) {
            const s = 2.0 * Math.sqrt(1.0 + newUp.y - right.x - forward.z);
            return {
                w: (forward.x - right.z) / s,
                x: (newUp.x + right.y) / s,
                y: 0.25 * s,
                z: (forward.y + newUp.z) / s
            };
        }
        else {
            const s = 2.0 * Math.sqrt(1.0 + forward.z - right.x - newUp.y);
            return {
                w: (right.y - newUp.x) / s,
                x: (forward.x + right.z) / s,
                y: (forward.y + newUp.z) / s,
                z: 0.25 * s
            };
        }
    }
    quaternionDifference(target, current) {
        // q_error = q_target * q_current^(-1)
        const currentInv = this.quaternionInverse(current);
        return this.quaternionMultiply(target, currentInv);
    }
    quaternionInverse(q) {
        // For unit quaternions: q^(-1) = q* (conjugate)
        return { w: q.w, x: -q.x, y: -q.y, z: -q.z };
    }
    quaternionMultiply(a, b) {
        return {
            w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
            x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
            y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
            z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
        };
    }
    quaternionToEuler(q) {
        // Convert quaternion to Euler angles (X-Y-Z convention)
        const sinr_cosp = 2 * (q.w * q.x + q.y * q.z);
        const cosr_cosp = 1 - 2 * (q.x * q.x + q.y * q.y);
        const roll = Math.atan2(sinr_cosp, cosr_cosp);
        const sinp = 2 * (q.w * q.y - q.z * q.x);
        const pitch = Math.abs(sinp) >= 1 ? Math.sign(sinp) * Math.PI / 2 : Math.asin(sinp);
        const siny_cosp = 2 * (q.w * q.z + q.x * q.y);
        const cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z);
        const yaw = Math.atan2(siny_cosp, cosy_cosp);
        return { pitch, roll, yaw };
    }
    normalize(v) {
        const mag = Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
        if (mag < 1e-10)
            return { x: 0, y: 0, z: 1 };
        return { x: v.x / mag, y: v.y / mag, z: v.z / mag };
    }
    crossProduct(a, b) {
        return {
            x: a.y * b.z - a.z * b.y,
            y: a.z * b.x - a.x * b.z,
            z: a.x * b.y - a.y * b.x
        };
    }
}
exports.SASController = SASController;
/**
 * Autopilot System
 * Provides automated throttle control for various flight modes
 */
class AutopilotSystem {
    constructor(config) {
        this.mode = 'off';
        this.targetAltitude = null;
        this.targetVerticalSpeed = null;
        this.suicideBurnActive = false;
        this.suicideBurnAltitude = 0;
        this.config = config.autopilot;
        this.altitudePID = new PIDController(config.pid.altitude);
        this.verticalSpeedPID = new PIDController(config.pid.verticalSpeed);
    }
    setMode(mode) {
        this.mode = mode;
        this.altitudePID.reset();
        this.verticalSpeedPID.reset();
        this.suicideBurnActive = false;
    }
    getMode() {
        return this.mode;
    }
    setTargetAltitude(altitude) {
        this.targetAltitude = altitude;
    }
    setTargetVerticalSpeed(speed) {
        this.targetVerticalSpeed = speed;
    }
    update(altitude, verticalSpeed, mass, maxThrust, gravity, dt) {
        if (this.mode === 'off') {
            return { throttle: 0, reason: 'autopilot_off' };
        }
        switch (this.mode) {
            case 'altitude_hold':
                return this.updateAltitudeHold(altitude, verticalSpeed, dt);
            case 'vertical_speed_hold':
                return this.updateVerticalSpeedHold(verticalSpeed, dt);
            case 'suicide_burn':
                return this.updateSuicideBurn(altitude, verticalSpeed, mass, maxThrust, gravity, dt);
            case 'hover':
                return this.updateHover(altitude, mass, maxThrust, gravity, dt);
            default:
                return { throttle: 0, reason: 'unknown_mode' };
        }
    }
    getSuicideBurnAltitude() {
        return this.suicideBurnAltitude;
    }
    isSuicideBurnActive() {
        return this.suicideBurnActive;
    }
    updateAltitudeHold(altitude, verticalSpeed, dt) {
        if (this.targetAltitude === null) {
            return { throttle: 0, reason: 'no_target_altitude' };
        }
        const deadband = this.config.altitudeHoldDeadband;
        const error = this.targetAltitude - altitude;
        if (Math.abs(error) < deadband && Math.abs(verticalSpeed) < this.config.speedHoldDeadband) {
            // Within deadband and stable
            return { throttle: 0, reason: 'altitude_hold_stable' };
        }
        const throttleCmd = this.altitudePID.update(altitude, this.targetAltitude, dt);
        const throttle = Math.max(0, Math.min(1, throttleCmd));
        return { throttle, reason: 'altitude_hold_active' };
    }
    updateVerticalSpeedHold(verticalSpeed, dt) {
        if (this.targetVerticalSpeed === null) {
            return { throttle: 0, reason: 'no_target_speed' };
        }
        const deadband = this.config.speedHoldDeadband;
        const error = this.targetVerticalSpeed - verticalSpeed;
        if (Math.abs(error) < deadband) {
            // Within deadband
            return { throttle: 0, reason: 'speed_hold_stable' };
        }
        const throttleCmd = this.verticalSpeedPID.update(verticalSpeed, this.targetVerticalSpeed, dt);
        const throttle = Math.max(0, Math.min(1, throttleCmd));
        return { throttle, reason: 'speed_hold_active' };
    }
    updateSuicideBurn(altitude, verticalSpeed, mass, maxThrust, gravity, dt) {
        // Calculate suicide burn altitude
        const acceleration = maxThrust / mass;
        const stopDistance = (verticalSpeed * verticalSpeed) / (2 * acceleration);
        const safetyFactor = this.config.suicideBurnSafetyFactor;
        this.suicideBurnAltitude = stopDistance * safetyFactor;
        if (altitude <= this.suicideBurnAltitude && verticalSpeed < -0.1) {
            this.suicideBurnActive = true;
            return { throttle: 1.0, reason: 'suicide_burn_active' };
        }
        if (this.suicideBurnActive && Math.abs(verticalSpeed) < 1.0) {
            // Nearly stopped, reduce throttle
            return { throttle: 0.5, reason: 'suicide_burn_final' };
        }
        this.suicideBurnActive = false;
        return { throttle: 0, reason: 'suicide_burn_waiting' };
    }
    updateHover(altitude, mass, maxThrust, gravity, dt) {
        // Calculate hover throttle: T = mg
        const hoverThrust = mass * gravity;
        let hoverThrottle = hoverThrust / maxThrust;
        // Add margin for stability
        hoverThrottle += this.config.hoverThrottleMargin;
        // Clamp to valid range
        hoverThrottle = Math.max(0, Math.min(1, hoverThrottle));
        return { throttle: hoverThrottle, reason: 'hover_active' };
    }
}
exports.AutopilotSystem = AutopilotSystem;
/**
 * Gimbal Autopilot
 * Automatically vectors thrust to null horizontal velocity
 */
class GimbalAutopilot {
    constructor() {
        this.enabled = false;
        this.maxGimbalAngle = 6; // degrees
    }
    setEnabled(enabled) {
        this.enabled = enabled;
    }
    isEnabled() {
        return this.enabled;
    }
    update(velocity, thrust, mass) {
        if (!this.enabled || thrust < 100) {
            return { pitch: 0, yaw: 0 };
        }
        // Calculate horizontal velocity
        const horizontalVel = { x: velocity.x, y: velocity.y };
        const horizontalSpeed = Math.sqrt(horizontalVel.x ** 2 + horizontalVel.y ** 2);
        if (horizontalSpeed < 0.1) {
            // Negligible horizontal velocity
            return { pitch: 0, yaw: 0 };
        }
        // Calculate required gimbal angle to counter horizontal drift
        const thrustAccel = thrust / mass;
        let gimbalAngle = Math.atan2(horizontalSpeed, thrustAccel);
        gimbalAngle = Math.min(gimbalAngle, this.maxGimbalAngle * Math.PI / 180);
        // Calculate gimbal direction (oppose horizontal velocity)
        const direction = {
            x: -horizontalVel.x / horizontalSpeed,
            y: -horizontalVel.y / horizontalSpeed
        };
        const gimbalDeg = gimbalAngle * 180 / Math.PI;
        return {
            pitch: direction.y * gimbalDeg,
            yaw: direction.x * gimbalDeg
        };
    }
}
exports.GimbalAutopilot = GimbalAutopilot;
/**
 * Flight Control System
 * Main integration point for all flight control subsystems
 */
class FlightControlSystem {
    constructor(config) {
        this.config = {
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
            },
            ...config
        };
        this.sas = new SASController(this.config);
        this.autopilot = new AutopilotSystem(this.config);
        this.gimbalAutopilot = new GimbalAutopilot();
    }
    // SAS Controls
    setSASMode(mode) {
        this.sas.setMode(mode);
    }
    getSASMode() {
        return this.sas.getMode();
    }
    // Autopilot Controls
    setAutopilotMode(mode) {
        this.autopilot.setMode(mode);
    }
    getAutopilotMode() {
        return this.autopilot.getMode();
    }
    setTargetAltitude(altitude) {
        this.autopilot.setTargetAltitude(altitude);
    }
    setTargetVerticalSpeed(speed) {
        this.autopilot.setTargetVerticalSpeed(speed);
    }
    // Gimbal Autopilot
    setGimbalAutopilot(enabled) {
        this.gimbalAutopilot.setEnabled(enabled);
    }
    isGimbalAutopilotEnabled() {
        return this.gimbalAutopilot.isEnabled();
    }
    // Main Update
    update(currentAttitude, currentAngularVel, targetAttitude, velocity, position, altitude, verticalSpeed, mass, maxThrust, currentThrust, gravity, dt) {
        // Update SAS
        const rcsCommands = this.sas.update(currentAttitude, currentAngularVel, targetAttitude, velocity, position, dt);
        // Update Autopilot
        const throttleCommand = this.autopilot.update(altitude, verticalSpeed, mass, maxThrust, gravity, dt);
        // Update Gimbal Autopilot
        const gimbalCommand = this.gimbalAutopilot.update(velocity, currentThrust, mass);
        return {
            sasMode: this.sas.getMode(),
            autopilotMode: this.autopilot.getMode(),
            targetAltitude: null,
            targetVerticalSpeed: null,
            targetAttitude,
            suicideBurnActive: this.autopilot.isSuicideBurnActive(),
            suicideBurnAltitude: this.autopilot.getSuicideBurnAltitude(),
            hoverActive: this.autopilot.getMode() === 'hover',
            rcsCommands,
            throttleCommand,
            gimbalCommand
        };
    }
    getState() {
        return {
            sasMode: this.sas.getMode(),
            autopilotMode: this.autopilot.getMode(),
            targetAltitude: null,
            targetVerticalSpeed: null,
            targetAttitude: null,
            suicideBurnActive: this.autopilot.isSuicideBurnActive(),
            suicideBurnAltitude: this.autopilot.getSuicideBurnAltitude(),
            hoverActive: this.autopilot.getMode() === 'hover',
            rcsCommands: { pitch: 0, roll: 0, yaw: 0 },
            throttleCommand: { throttle: 0, reason: 'idle' },
            gimbalCommand: { pitch: 0, yaw: 0 }
        };
    }
}
exports.FlightControlSystem = FlightControlSystem;
//# sourceMappingURL=flight-control.js.map