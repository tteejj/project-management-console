/**
 * Integrated Game Spacecraft
 *
 * Combines spacecraft physics with new physical world systems:
 * - IntegratedShip (existing spacecraft + world integration)
 * - LandingGear (4-leg spring-damper suspension)
 * - Terrain collision and elevation tracking
 * - Environment interaction
 */

import { IntegratedShip, ShipConfiguration } from '../dist/src/integrated-ship';
import { LandingGear, LandingGearConfig } from './landing-gear';
import { GameWorld } from './game-world';
import { Vector3, Quaternion } from './types';

export interface GameSpacecraftConfig {
  /** Initial position (meters from moon center) */
  initialPosition?: Vector3;
  /** Initial velocity (m/s) */
  initialVelocity?: Vector3;
  /** Initial attitude (quaternion) */
  initialAttitude?: Quaternion;
  /** Spacecraft dry mass (kg) */
  dryMass?: number;
  /** Initial propellant mass (kg) */
  propellantMass?: number;
  /** Landing gear configuration */
  landingGearConfig?: Partial<LandingGearConfig>;
}

/**
 * Complete spacecraft with all systems integrated
 */
export class GameSpacecraft {
  // Core systems
  private ship: IntegratedShip;
  private landingGear: LandingGear;
  private gameWorld: GameWorld;

  // State tracking
  private isLanded: boolean = false;
  private lastTerrainContact: number = 0;

  constructor(config: GameSpacecraftConfig, gameWorld: GameWorld) {
    this.gameWorld = gameWorld;

    // Default starting position: 15km altitude above equator
    const moonRadius = 1737400; // meters
    const defaultPosition = config.initialPosition || {
      x: moonRadius + 15000, // 15km altitude
      y: 0,
      z: 0,
    };

    const defaultVelocity = config.initialVelocity || {
      x: 0,
      y: 0,
      z: 0,
    };

    // Create ship configuration for IntegratedShip
    const shipConfig: ShipConfiguration = {
      mass: (config.dryMass || 15000) + (config.propellantMass || 8000),
      radius: 5, // 5m radius spacecraft
      position: defaultPosition,
      velocity: defaultVelocity,
      orientation: config.initialAttitude,
    };

    // Create integrated ship
    this.ship = new IntegratedShip(shipConfig, gameWorld.world);

    // Create landing gear
    this.landingGear = new LandingGear(config.landingGearConfig);

    // Listen for collision events
    this.ship.on('collision', (event: any) => {
      this.handleCollision(event);
    });
  }

  /**
   * Main update loop
   */
  update(dt: number): void {
    // Get current state
    const position = this.ship.getPosition();
    const velocity = this.ship.getVelocity();

    // Convert position to lat/lon
    const posLen = Math.sqrt(
      position.x * position.x +
      position.y * position.y +
      position.z * position.z
    );
    const latitude = Math.asin(position.z / posLen) * (180 / Math.PI);
    const longitude = Math.atan2(position.y, position.x) * (180 / Math.PI);

    // Get terrain elevation and normal
    const terrainElevation = this.gameWorld.getTerrainElevation(latitude, longitude);
    const surfaceNormal = this.gameWorld.getSurfaceNormal(latitude, longitude);

    // Get altitude above ground level (AGL)
    const moonRadius = 1737400; // meters
    const altitudeMSL = posLen - moonRadius; // altitude above mean sea level
    const altitudeAGL = altitudeMSL - terrainElevation; // altitude above ground level

    // Update landing gear
    // Note: For now using simplified quaternion (identity)
    // Real implementation would get actual attitude from ship
    const attitude: Quaternion = { w: 1, x: 0, y: 0, z: 0 };
    const shipMass = 15000; // kg (would get from ship in real implementation)

    const landingGearForce = this.landingGear.update(
      dt,
      position,
      attitude,
      velocity,
      terrainElevation,
      surfaceNormal,
      shipMass
    );

    // Apply landing gear forces to ship
    if (landingGearForce) {
      // Convert force to impulse (F * dt = m * Δv)
      // Note: IntegratedShip.applyForce() may need to be used differently
      // For now, we'll apply as impulse
      const impulse: Vector3 = {
        x: landingGearForce.force.x * dt,
        y: landingGearForce.force.y * dt,
        z: landingGearForce.force.z * dt,
      };

      // Only apply if force is significant (landing gear is in contact)
      const forceMagnitude = Math.sqrt(
        landingGearForce.force.x ** 2 +
        landingGearForce.force.y ** 2 +
        landingGearForce.force.z ** 2
      );

      if (forceMagnitude > 1.0) { // More than 1N of force
        this.ship.applyForce(landingGearForce.force);
        this.lastTerrainContact = this.gameWorld.getTime();
      }
    }

    // Update ship physics
    this.ship.update(dt);

    // Check landing status
    const contactStatus = this.landingGear.getContactStatus();
    const timeSinceContact = this.gameWorld.getTime() - this.lastTerrainContact;
    this.isLanded = contactStatus.legsInContact >= 3 && timeSinceContact < 0.1;
  }

  /**
   * Handle collision with terrain or other bodies
   */
  private handleCollision(event: any): void {
    console.log(`Collision detected: ${event.otherBody.name}`);
    console.log(`  Impact velocity: ${event.relativeVelocity.toFixed(2)} m/s`);
    console.log(`  Damage applied: ${event.damageApplied.toFixed(1)}`);
  }

  /**
   * Deploy or retract landing gear
   */
  setLandingGearDeployed(deployed: boolean): void {
    if (deployed) {
      this.landingGear.deploy();
    } else {
      this.landingGear.retract();
    }
  }

  /**
   * Get landing gear status
   */
  getLandingGearStatus() {
    return {
      deployed: this.landingGear.isDeployed(),
      contact: this.landingGear.getContactStatus(),
      health: this.landingGear.getHealthStatus(),
    };
  }

  /**
   * Get current position
   */
  getPosition(): Vector3 {
    return this.ship.getPosition();
  }

  /**
   * Get current velocity
   */
  getVelocity(): Vector3 {
    return this.ship.getVelocity();
  }

  /**
   * Get altitude above ground level
   */
  getAltitudeAGL(): number {
    const position = this.ship.getPosition();
    const posLen = Math.sqrt(
      position.x * position.x +
      position.y * position.y +
      position.z * position.z
    );
    const latitude = Math.asin(position.z / posLen) * (180 / Math.PI);
    const longitude = Math.atan2(position.y, position.x) * (180 / Math.PI);

    const terrainElevation = this.gameWorld.getTerrainElevation(latitude, longitude);
    const moonRadius = 1737400; // meters
    const altitudeMSL = posLen - moonRadius;

    return altitudeMSL - terrainElevation;
  }

  /**
   * Get altitude above mean sea level (moon radius)
   */
  getAltitudeMSL(): number {
    const position = this.ship.getPosition();
    const posLen = Math.sqrt(
      position.x * position.x +
      position.y * position.y +
      position.z * position.z
    );
    const moonRadius = 1737400; // meters
    return posLen - moonRadius;
  }

  /**
   * Check if spacecraft is landed
   */
  isSpacecraftLanded(): boolean {
    return this.isLanded;
  }

  /**
   * Get hull integrity (0-1)
   */
  getHullIntegrity(): number {
    return this.ship.getHullIntegrity();
  }

  /**
   * Get vertical speed (positive = ascending)
   */
  getVerticalSpeed(): number {
    const position = this.ship.getPosition();
    const velocity = this.ship.getVelocity();

    // Normalize position vector (radial direction)
    const posLen = Math.sqrt(
      position.x * position.x +
      position.y * position.y +
      position.z * position.z
    );

    const radialDir = {
      x: position.x / posLen,
      y: position.y / posLen,
      z: position.z / posLen,
    };

    // Dot product of velocity with radial direction
    return (
      velocity.x * radialDir.x +
      velocity.y * radialDir.y +
      velocity.z * radialDir.z
    );
  }

  /**
   * Get horizontal speed (tangential velocity)
   */
  getHorizontalSpeed(): number {
    const totalSpeed = Math.sqrt(
      this.ship.getVelocity().x ** 2 +
      this.ship.getVelocity().y ** 2 +
      this.ship.getVelocity().z ** 2
    );

    const verticalSpeed = Math.abs(this.getVerticalSpeed());

    return Math.sqrt(Math.max(0, totalSpeed ** 2 - verticalSpeed ** 2));
  }

  /**
   * Apply impulse (instantaneous velocity change)
   */
  applyImpulse(impulse: Vector3): void {
    this.ship.applyImpulse(impulse);
  }

  /**
   * Apply force
   */
  applyForce(force: Vector3): void {
    this.ship.applyForce(force);
  }

  /**
   * Get latitude and longitude
   */
  getLatLon(): { latitude: number; longitude: number } {
    const position = this.ship.getPosition();
    const posLen = Math.sqrt(
      position.x * position.x +
      position.y * position.y +
      position.z * position.z
    );

    return {
      latitude: Math.asin(position.z / posLen) * (180 / Math.PI),
      longitude: Math.atan2(position.y, position.x) * (180 / Math.PI),
    };
  }
}
