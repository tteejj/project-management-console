/**
 * Spacecraft Physics (Simplified for Integration)
 *
 * Basic rigid body physics for spacecraft
 * This is a simplified version - full spacecraft systems from earlier work
 * can be integrated later
 */

import { Vector3, VectorMath, Quaternion, QuaternionMath } from './math-utils';

export interface SpacecraftConfig {
  mass: number;
  momentOfInertia: Vector3;
  position: Vector3;
  velocity: Vector3;
  orientation: Quaternion;
  angularVelocity: Vector3;
}

/**
 * Basic spacecraft rigid body physics
 */
export class SpacecraftPhysics {
  private mass: number;
  private momentOfInertia: Vector3;

  private position: Vector3;
  private velocity: Vector3;
  private orientation: Quaternion;
  private angularVelocity: Vector3;

  private accumulatedForce: Vector3;
  private accumulatedTorque: Vector3;

  constructor(config: SpacecraftConfig) {
    this.mass = config.mass;
    this.momentOfInertia = config.momentOfInertia;
    this.position = { ...config.position };
    this.velocity = { ...config.velocity };
    this.orientation = { ...config.orientation };
    this.angularVelocity = { ...config.angularVelocity };

    this.accumulatedForce = VectorMath.zero();
    this.accumulatedTorque = VectorMath.zero();
  }

  /**
   * Apply force to spacecraft
   */
  applyForce(force: Vector3): void {
    this.accumulatedForce = VectorMath.add(this.accumulatedForce, force);
  }

  /**
   * Apply torque to spacecraft
   */
  applyTorque(torque: Vector3): void {
    this.accumulatedTorque = VectorMath.add(this.accumulatedTorque, torque);
  }

  /**
   * Update physics
   */
  update(dt: number): void {
    // Linear motion: F = ma
    const acceleration = VectorMath.scale(this.accumulatedForce, 1 / this.mass);
    this.velocity = VectorMath.add(
      this.velocity,
      VectorMath.scale(acceleration, dt)
    );

    this.position = VectorMath.add(
      this.position,
      VectorMath.scale(this.velocity, dt)
    );

    // Angular motion: τ = I * α
    const angularAcceleration: Vector3 = {
      x: this.accumulatedTorque.x / this.momentOfInertia.x,
      y: this.accumulatedTorque.y / this.momentOfInertia.y,
      z: this.accumulatedTorque.z / this.momentOfInertia.z
    };

    this.angularVelocity = VectorMath.add(
      this.angularVelocity,
      VectorMath.scale(angularAcceleration, dt)
    );

    // Update orientation
    const angularSpeed = VectorMath.magnitude(this.angularVelocity);
    if (angularSpeed > 1e-6) {
      const axis = VectorMath.normalize(this.angularVelocity);
      const angle = angularSpeed * dt;

      const rotation: Quaternion = {
        w: Math.cos(angle / 2),
        x: axis.x * Math.sin(angle / 2),
        y: axis.y * Math.sin(angle / 2),
        z: axis.z * Math.sin(angle / 2)
      };

      this.orientation = QuaternionMath.multiply(this.orientation, rotation);

      // Normalize to prevent drift
      const mag = Math.sqrt(
        this.orientation.w ** 2 +
        this.orientation.x ** 2 +
        this.orientation.y ** 2 +
        this.orientation.z ** 2
      );

      this.orientation = {
        w: this.orientation.w / mag,
        x: this.orientation.x / mag,
        y: this.orientation.y / mag,
        z: this.orientation.z / mag
      };
    }

    // Clear accumulated forces
    this.accumulatedForce = VectorMath.zero();
    this.accumulatedTorque = VectorMath.zero();
  }

  // Getters
  getMass(): number {
    return this.mass;
  }

  getPosition(): Vector3 {
    return { ...this.position };
  }

  getVelocity(): Vector3 {
    return { ...this.velocity };
  }

  getOrientation(): Quaternion {
    return { ...this.orientation };
  }

  getAngularVelocity(): Vector3 {
    return { ...this.angularVelocity };
  }

  // Setters
  setPosition(position: Vector3): void {
    this.position = { ...position };
  }

  setVelocity(velocity: Vector3): void {
    this.velocity = { ...velocity };
  }

  setOrientation(orientation: Quaternion): void {
    this.orientation = { ...orientation };
  }

  setAngularVelocity(angularVelocity: Vector3): void {
    this.angularVelocity = { ...angularVelocity };
  }
}
