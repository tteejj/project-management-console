"use strict";
/**
 * Navigation System
 *
 * Provides trajectory prediction, navball display, velocity decomposition,
 * and enhanced telemetry for spacecraft navigation.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.NavigationSystem = exports.NavballDisplay = exports.VelocityDecomposer = exports.SuicideBurnCalculator = exports.TrajectoryPredictor = void 0;
/**
 * Trajectory Predictor
 * Numerically integrates trajectory to predict impact point
 */
class TrajectoryPredictor {
    constructor() {
        this.MOON_MASS = 7.342e22; // kg
        this.MOON_RADIUS = 1737400; // m
        this.G = 6.674e-11; // N⋅m²/kg²
    }
    predict(position, velocity, mass, thrust, thrustDirection, // Unit vector
    maxSimTime = 1000 // seconds
    ) {
        // Copy initial state
        let pos = { ...position };
        let vel = { ...velocity };
        const dt = 0.1;
        let time = 0;
        while (time < maxSimTime) {
            const altitude = this.getAltitude(pos);
            // Check if impacted
            if (altitude <= 0) {
                const impactSpeed = this.magnitude(vel);
                return {
                    impactTime: time,
                    impactPosition: pos,
                    impactVelocity: vel,
                    impactSpeed,
                    coordinates: this.positionToLatLon(pos),
                    willImpact: true
                };
            }
            // Calculate acceleration
            const gravity = this.calculateGravity(pos);
            const thrustAccel = {
                x: (thrust * thrustDirection.x) / mass,
                y: (thrust * thrustDirection.y) / mass,
                z: (thrust * thrustDirection.z) / mass
            };
            const accel = {
                x: gravity.x + thrustAccel.x,
                y: gravity.y + thrustAccel.y,
                z: gravity.z + thrustAccel.z
            };
            // Integrate velocity and position
            vel.x += accel.x * dt;
            vel.y += accel.y * dt;
            vel.z += accel.z * dt;
            pos.x += vel.x * dt;
            pos.y += vel.y * dt;
            pos.z += vel.z * dt;
            time += dt;
        }
        // Didn't impact within simulation time - escaping or very long time
        return {
            impactTime: Infinity,
            impactPosition: pos,
            impactVelocity: vel,
            impactSpeed: this.magnitude(vel),
            coordinates: this.positionToLatLon(pos),
            willImpact: false
        };
    }
    calculateGravity(position) {
        const r = this.magnitude(position);
        if (r < 1e-10)
            return { x: 0, y: 0, z: 0 };
        const gMag = -this.G * this.MOON_MASS / (r * r);
        const rNorm = {
            x: position.x / r,
            y: position.y / r,
            z: position.z / r
        };
        return {
            x: gMag * rNorm.x,
            y: gMag * rNorm.y,
            z: gMag * rNorm.z
        };
    }
    getAltitude(position) {
        return this.magnitude(position) - this.MOON_RADIUS;
    }
    positionToLatLon(position) {
        const r = this.magnitude(position);
        if (r < 1e-10)
            return { lat: 0, lon: 0 };
        const lat = Math.asin(position.z / r) * 180 / Math.PI;
        const lon = Math.atan2(position.y, position.x) * 180 / Math.PI;
        return { lat, lon };
    }
    magnitude(v) {
        return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    }
}
exports.TrajectoryPredictor = TrajectoryPredictor;
/**
 * Suicide Burn Calculator
 * Calculates optimal deceleration burn parameters
 */
class SuicideBurnCalculator {
    constructor() {
        this.MOON_GRAVITY = 1.62; // m/s²
    }
    calculate(altitude, verticalSpeed, mass, maxThrust, safetyFactor = 1.15) {
        // Account for local gravity
        const acceleration = (maxThrust / mass) - this.MOON_GRAVITY;
        if (acceleration <= 0) {
            // Cannot decelerate - thrust too low
            return {
                burnAltitude: Infinity,
                currentAltitude: altitude,
                timeUntilBurn: Infinity,
                shouldBurn: true, // Burn NOW!
                burnDuration: Infinity,
                finalSpeed: Math.abs(verticalSpeed)
            };
        }
        // Calculate stopping distance: d = v² / (2a)
        const stopDistance = (verticalSpeed * verticalSpeed) / (2 * acceleration);
        const burnAltitude = stopDistance * safetyFactor;
        // Time until should start burn
        const timeUntilBurn = Math.abs(verticalSpeed) > 0.1 ?
            (altitude - burnAltitude) / Math.abs(verticalSpeed) : 0;
        // Burn duration: t = v / a
        const burnDuration = Math.abs(verticalSpeed) / acceleration;
        // Final speed (should be near zero with safety factor)
        const finalSpeed = Math.max(0, Math.abs(verticalSpeed) - acceleration * burnDuration);
        return {
            burnAltitude,
            currentAltitude: altitude,
            timeUntilBurn: Math.max(0, timeUntilBurn),
            shouldBurn: altitude <= burnAltitude && verticalSpeed < -0.1,
            burnDuration,
            finalSpeed
        };
    }
}
exports.SuicideBurnCalculator = SuicideBurnCalculator;
/**
 * Velocity Decomposer
 * Breaks down velocity into meaningful components
 */
class VelocityDecomposer {
    decompose(velocity, position) {
        const total = this.magnitude(velocity);
        // Radial (vertical) component - projection onto position vector
        const posNorm = this.normalize(position);
        const vertical = this.dot(velocity, posNorm);
        // Horizontal is perpendicular to radial
        const horizontalVec = {
            x: velocity.x - vertical * posNorm.x,
            y: velocity.y - vertical * posNorm.y,
            z: velocity.z - vertical * posNorm.z
        };
        const horizontal = this.magnitude(horizontalVec);
        // North/East decomposition (simplified - assume Z is north, Y is east)
        const north = velocity.z;
        const east = velocity.y;
        // Prograde is just the velocity direction
        const prograde = total;
        // Normal (perpendicular to orbital plane)
        // For circular orbit, this would be cross product of position and velocity
        const orbitalAngMom = this.crossProduct(position, velocity);
        const normal = this.magnitude(orbitalAngMom) / this.magnitude(position);
        return {
            total,
            vertical,
            horizontal,
            north,
            east,
            prograde,
            normal
        };
    }
    magnitude(v) {
        return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    }
    normalize(v) {
        const mag = this.magnitude(v);
        if (mag < 1e-10)
            return { x: 0, y: 0, z: 1 };
        return { x: v.x / mag, y: v.y / mag, z: v.z / mag };
    }
    dot(a, b) {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }
    crossProduct(a, b) {
        return {
            x: a.y * b.z - a.z * b.y,
            y: a.z * b.x - a.x * b.z,
            z: a.x * b.y - a.y * b.x
        };
    }
}
exports.VelocityDecomposer = VelocityDecomposer;
/**
 * Navball Display
 * Renders attitude reference display (ASCII art)
 */
class NavballDisplay {
    constructor() {
        this.GRID_SIZE = 9;
    }
    render(attitude, velocity, targetDirection) {
        const euler = this.quaternionToEuler(attitude);
        const pitch = euler.pitch * 180 / Math.PI;
        const roll = euler.roll * 180 / Math.PI;
        const yaw = euler.yaw * 180 / Math.PI;
        // Render navball grid
        let display = '\n';
        display += '        N (0°)\n';
        display += '    NW  ↑  NE\n';
        display += '  W ← [◉] → E\n';
        display += '    SW  ↓  SE\n';
        display += '        S (180°)\n\n';
        // Add marker legend
        display += 'Markers:\n';
        display += '  ⊕ Prograde (direction of motion)\n';
        display += '  ⊗ Retrograde (opposite motion)\n';
        if (targetDirection) {
            display += '  ◎ Target\n';
        }
        display += '\n';
        display += `Attitude:\n`;
        display += `  Pitch: ${pitch.toFixed(1)}°\n`;
        display += `  Roll:  ${roll.toFixed(1)}°\n`;
        display += `  Yaw:   ${yaw.toFixed(1)}°\n`;
        return display;
    }
    quaternionToEuler(q) {
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
}
exports.NavballDisplay = NavballDisplay;
/**
 * Navigation System
 * Main integration point for all navigation subsystems
 */
class NavigationSystem {
    constructor(terrain) {
        this.terrain = null;
        this.targetPosition = null;
        this.MOON_MASS = 7.342e22;
        this.MOON_RADIUS = 1737400;
        this.G = 6.674e-11;
        this.predictor = new TrajectoryPredictor();
        this.suicideBurn = new SuicideBurnCalculator();
        this.velocityDecomp = new VelocityDecomposer();
        this.navball = new NavballDisplay();
        this.terrain = terrain || null;
    }
    /**
     * Set terrain system for realistic radar altitude calculations
     */
    setTerrain(terrain) {
        this.terrain = terrain;
    }
    setTarget(position) {
        this.targetPosition = position;
    }
    clearTarget() {
        this.targetPosition = null;
    }
    getTelemetry(position, velocity, attitude, mass, thrust, thrustDirection, throttle, fuelMass, fuelCapacity, specificImpulse) {
        // Position & Velocity
        const altitude = this.magnitude(position) - this.MOON_RADIUS;
        // Radar altitude: Use terrain system if available, otherwise fallback to orbital altitude
        let radarAltitude = altitude;
        if (this.terrain) {
            const coords = this.terrain.positionToLatLon(position);
            const terrainElevation = this.terrain.getElevation(coords.lat, coords.lon);
            radarAltitude = altitude - terrainElevation;
        }
        const velBreakdown = this.velocityDecomp.decompose(velocity, position);
        // Trajectory
        const impact = this.predictor.predict(position, velocity, mass, thrust, thrustDirection, 500);
        const suicideBurnData = this.suicideBurn.calculate(altitude, velBreakdown.vertical, mass, thrust > 0 ? thrust / throttle : 0 // Max thrust
        );
        // Attitude
        const euler = this.quaternionToEuler(attitude);
        const pitch = euler.pitch * 180 / Math.PI;
        const roll = euler.roll * 180 / Math.PI;
        const yaw = euler.yaw * 180 / Math.PI;
        const heading = (yaw + 360) % 360;
        // Angle from vertical
        const verticalDir = this.normalize(position);
        const thrustDir = this.rotateVector(thrustDirection, attitude);
        const angleFromVertical = Math.acos(this.dot(thrustDir, verticalDir)) * 180 / Math.PI;
        // Propulsion
        const gravity = this.G * this.MOON_MASS / (this.magnitude(position) ** 2);
        const twr = mass > 0 ? thrust / (mass * gravity) : 0;
        // Resources
        const fuelPercent = fuelCapacity > 0 ? (fuelMass / fuelCapacity) * 100 : 0;
        const massFlowRate = thrust > 0 ? thrust / (specificImpulse * 9.80665) : 0;
        const estimatedBurnTime = massFlowRate > 0 ? fuelMass / massFlowRate : Infinity;
        const deltaVRemaining = mass > 0 ?
            specificImpulse * 9.80665 * Math.log(mass / (mass - fuelMass)) : 0;
        // Navigation to target
        let distanceToTarget = null;
        let bearingToTarget = null;
        if (this.targetPosition) {
            const toTarget = {
                x: this.targetPosition.x - position.x,
                y: this.targetPosition.y - position.y,
                z: this.targetPosition.z - position.z
            };
            distanceToTarget = this.magnitude(toTarget);
            bearingToTarget = Math.atan2(toTarget.y, toTarget.x) * 180 / Math.PI;
        }
        return {
            altitude,
            radarAltitude,
            verticalSpeed: velBreakdown.vertical,
            horizontalSpeed: velBreakdown.horizontal,
            totalSpeed: velBreakdown.total,
            timeToImpact: impact.impactTime,
            impactSpeed: impact.impactSpeed,
            impactCoordinates: impact.coordinates,
            suicideBurnAltitude: suicideBurnData.burnAltitude,
            timeToSuicideBurn: suicideBurnData.timeUntilBurn,
            pitch,
            roll,
            yaw,
            heading,
            angleFromVertical,
            thrust,
            throttle,
            twr,
            fuelRemaining: fuelMass,
            fuelRemainingPercent: fuelPercent,
            estimatedBurnTime,
            deltaVRemaining,
            distanceToTarget,
            bearingToTarget
        };
    }
    renderNavball(attitude, velocity) {
        return this.navball.render(attitude, velocity, this.targetPosition || undefined);
    }
    predictImpact(position, velocity, mass, thrust, thrustDirection) {
        return this.predictor.predict(position, velocity, mass, thrust, thrustDirection);
    }
    calculateSuicideBurn(altitude, verticalSpeed, mass, maxThrust) {
        return this.suicideBurn.calculate(altitude, verticalSpeed, mass, maxThrust);
    }
    decomposeVelocity(velocity, position) {
        return this.velocityDecomp.decompose(velocity, position);
    }
    magnitude(v) {
        return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    }
    normalize(v) {
        const mag = this.magnitude(v);
        if (mag < 1e-10)
            return { x: 0, y: 0, z: 1 };
        return { x: v.x / mag, y: v.y / mag, z: v.z / mag };
    }
    dot(a, b) {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }
    rotateVector(v, q) {
        // Rotate vector by quaternion: v' = q * v * q^(-1)
        const qv = { w: 0, x: v.x, y: v.y, z: v.z };
        const qInv = { w: q.w, x: -q.x, y: -q.y, z: -q.z };
        const temp = this.quaternionMultiply(q, qv);
        const result = this.quaternionMultiply(temp, qInv);
        return { x: result.x, y: result.y, z: result.z };
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
}
exports.NavigationSystem = NavigationSystem;
//# sourceMappingURL=navigation.js.map