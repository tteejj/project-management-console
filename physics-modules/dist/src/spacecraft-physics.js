"use strict";
/**
 * Spacecraft Physics (Simplified for Integration)
 *
 * Basic rigid body physics for spacecraft
 * This is a simplified version - full spacecraft systems from earlier work
 * can be integrated later
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.SpacecraftPhysics = void 0;
const math_utils_1 = require("./math-utils");
/**
 * Basic spacecraft rigid body physics
 */
class SpacecraftPhysics {
    constructor(config) {
        this.mass = config.mass;
        this.momentOfInertia = config.momentOfInertia;
        this.position = { ...config.position };
        this.velocity = { ...config.velocity };
        this.orientation = { ...config.orientation };
        this.angularVelocity = { ...config.angularVelocity };
        this.accumulatedForce = math_utils_1.VectorMath.zero();
        this.accumulatedTorque = math_utils_1.VectorMath.zero();
    }
    /**
     * Apply force to spacecraft
     */
    applyForce(force) {
        this.accumulatedForce = math_utils_1.VectorMath.add(this.accumulatedForce, force);
    }
    /**
     * Apply torque to spacecraft
     */
    applyTorque(torque) {
        this.accumulatedTorque = math_utils_1.VectorMath.add(this.accumulatedTorque, torque);
    }
    /**
     * Update physics
     */
    update(dt) {
        // Linear motion: F = ma
        const acceleration = math_utils_1.VectorMath.scale(this.accumulatedForce, 1 / this.mass);
        this.velocity = math_utils_1.VectorMath.add(this.velocity, math_utils_1.VectorMath.scale(acceleration, dt));
        this.position = math_utils_1.VectorMath.add(this.position, math_utils_1.VectorMath.scale(this.velocity, dt));
        // Angular motion: τ = I * α
        const angularAcceleration = {
            x: this.accumulatedTorque.x / this.momentOfInertia.x,
            y: this.accumulatedTorque.y / this.momentOfInertia.y,
            z: this.accumulatedTorque.z / this.momentOfInertia.z
        };
        this.angularVelocity = math_utils_1.VectorMath.add(this.angularVelocity, math_utils_1.VectorMath.scale(angularAcceleration, dt));
        // Update orientation
        const angularSpeed = math_utils_1.VectorMath.magnitude(this.angularVelocity);
        if (angularSpeed > 1e-6) {
            const axis = math_utils_1.VectorMath.normalize(this.angularVelocity);
            const angle = angularSpeed * dt;
            const rotation = {
                w: Math.cos(angle / 2),
                x: axis.x * Math.sin(angle / 2),
                y: axis.y * Math.sin(angle / 2),
                z: axis.z * Math.sin(angle / 2)
            };
            this.orientation = math_utils_1.QuaternionMath.multiply(this.orientation, rotation);
            // Normalize to prevent drift
            const mag = Math.sqrt(this.orientation.w ** 2 +
                this.orientation.x ** 2 +
                this.orientation.y ** 2 +
                this.orientation.z ** 2);
            this.orientation = {
                w: this.orientation.w / mag,
                x: this.orientation.x / mag,
                y: this.orientation.y / mag,
                z: this.orientation.z / mag
            };
        }
        // Clear accumulated forces
        this.accumulatedForce = math_utils_1.VectorMath.zero();
        this.accumulatedTorque = math_utils_1.VectorMath.zero();
    }
    // Getters
    getMass() {
        return this.mass;
    }
    getPosition() {
        return { ...this.position };
    }
    getVelocity() {
        return { ...this.velocity };
    }
    getOrientation() {
        return { ...this.orientation };
    }
    getAngularVelocity() {
        return { ...this.angularVelocity };
    }
    // Setters
    setPosition(position) {
        this.position = { ...position };
    }
    setVelocity(velocity) {
        this.velocity = { ...velocity };
    }
    setOrientation(orientation) {
        this.orientation = { ...orientation };
    }
    setAngularVelocity(angularVelocity) {
        this.angularVelocity = { ...angularVelocity };
    }
}
exports.SpacecraftPhysics = SpacecraftPhysics;
//# sourceMappingURL=spacecraft-physics.js.map