/**
 * Simple Spacecraft System
 *
 * Simplified spacecraft physics without external dependencies
 * Integrates with landing gear and terrain
 */

import { LandingGear } from './landing-gear';
import { SimpleWorld } from './simple-world';
import { Vector3, Quaternion } from './types';

export interface SimpleSpacecraftConfig {
  initialPosition?: Vector3;
  initialVelocity?: Vector3;
  mass?: number;
}

/**
 * Simple spacecraft with basic physics and landing gear
 */
export class SimpleSpacecraft {
  public position: Vector3;
  public velocity: Vector3;
  public readonly mass: number;

  private landingGear: LandingGear;
  private world: SimpleWorld;
  private readonly MOON_RADIUS = 1737400; // meters

  constructor(config: SimpleSpacecraftConfig, world: SimpleWorld) {
    this.position = config.initialPosition || { x: this.MOON_RADIUS + 15000, y: 0, z: 0 };
    this.velocity = config.initialVelocity || { x: 0, y: 0, z: 0 };
    this.mass = config.mass || 23000; // kg
    this.world = world;

    this.landingGear = new LandingGear({
      numLegs: 4,
      legLength: 2.0,
      legRadius: 1.5,
    });

    // Deploy landing gear
    this.landingGear.deploy();
  }

  update(dt: number): void {
    // Get gravity acceleration
    const gravity = this.world.getGravityAcceleration(this.position);

    // Get terrain information
    const { latitude, longitude } = this.getLatLon();
    const terrainElevation = this.world.terrain.getElevation(latitude, longitude);
    const surfaceNormal = this.world.terrain.getSurfaceNormal(latitude, longitude);

    // Update landing gear (identity quaternion for simplicity)
    const attitude: Quaternion = { w: 1, x: 0, y: 0, z: 0 };
    const landingForces = this.landingGear.update(
      dt,
      this.position,
      attitude,
      this.velocity,
      terrainElevation,
      surfaceNormal,
      this.mass
    );

    // Apply gravity
    const accel = {
      x: gravity.x + (landingForces.force.x / this.mass),
      y: gravity.y + (landingForces.force.y / this.mass),
      z: gravity.z + (landingForces.force.z / this.mass),
    };

    // Update velocity and position (Euler integration)
    this.velocity.x += accel.x * dt;
    this.velocity.y += accel.y * dt;
    this.velocity.z += accel.z * dt;

    this.position.x += this.velocity.x * dt;
    this.position.y += this.velocity.y * dt;
    this.position.z += this.velocity.z * dt;
  }

  getLatLon(): { latitude: number; longitude: number } {
    const r = Math.sqrt(
      this.position.x ** 2 +
      this.position.y ** 2 +
      this.position.z ** 2
    );

    return {
      latitude: Math.asin(this.position.z / r) * (180 / Math.PI),
      longitude: Math.atan2(this.position.y, this.position.x) * (180 / Math.PI),
    };
  }

  getAltitudeMSL(): number {
    const r = Math.sqrt(
      this.position.x ** 2 +
      this.position.y ** 2 +
      this.position.z ** 2
    );
    return r - this.MOON_RADIUS;
  }

  getAltitudeAGL(): number {
    const { latitude, longitude } = this.getLatLon();
    const terrainElevation = this.world.terrain.getElevation(latitude, longitude);
    return this.getAltitudeMSL() - terrainElevation;
  }

  getVerticalSpeed(): number {
    const r = Math.sqrt(
      this.position.x ** 2 +
      this.position.y ** 2 +
      this.position.z ** 2
    );

    const radial_x = this.position.x / r;
    const radial_y = this.position.y / r;
    const radial_z = this.position.z / r;

    return (
      this.velocity.x * radial_x +
      this.velocity.y * radial_y +
      this.velocity.z * radial_z
    );
  }

  getHorizontalSpeed(): number {
    const totalSpeed = Math.sqrt(
      this.velocity.x ** 2 +
      this.velocity.y ** 2 +
      this.velocity.z ** 2
    );

    const verticalSpeed = Math.abs(this.getVerticalSpeed());

    return Math.sqrt(Math.max(0, totalSpeed ** 2 - verticalSpeed ** 2));
  }

  getLandingGearStatus() {
    return {
      deployed: this.landingGear.isDeployed(),
      contact: this.landingGear.getContactStatus(),
      health: this.landingGear.getHealthStatus(),
    };
  }

  isLanded(): boolean {
    const status = this.landingGear.getContactStatus();
    return status.legsInContact >= 3 && status.isStable;
  }
}
