/**
 * Simple World System
 *
 * Simplified version without external dependencies
 * Combines all new physics systems
 */

import { TerrainSystem } from './terrain-system';
import { EnvironmentSystem } from './environment';
import { OrbitalBodiesManager, createDefaultSatellite } from './orbital-bodies';
import { WaypointManager, createPracticeWaypoints } from './waypoints';
import { Vector3 } from './types';

export interface SimpleWorldConfig {
  terrainSeed?: number;
  createSatellite?: boolean;
  createWaypoints?: boolean;
}

/**
 * Simple integrated world for the game
 */
export class SimpleWorld {
  public readonly terrain: TerrainSystem;
  public readonly environment: EnvironmentSystem;
  public readonly orbitalBodies: OrbitalBodiesManager;
  public readonly waypoints: WaypointManager;

  private simulationTime: number = 0;
  private readonly MOON_MASS = 7.342e22; // kg
  private readonly MOON_RADIUS = 1737400; // meters
  private readonly G = 6.674e-11; // Gravitational constant

  constructor(config: SimpleWorldConfig = {}) {
    this.terrain = new TerrainSystem({
      seed: config.terrainSeed || 42,
      bodyRadius: this.MOON_RADIUS,
    });

    this.environment = new EnvironmentSystem({
      lunarDay: 29.5 * 24 * 3600, // ~29.5 Earth days in seconds
    });

    this.orbitalBodies = new OrbitalBodiesManager();
    this.waypoints = new WaypointManager();

    if (config.createSatellite) {
      const satelliteConfig = createDefaultSatellite();
      this.orbitalBodies.addBody(satelliteConfig);
    }

    if (config.createWaypoints) {
      createPracticeWaypoints(this.waypoints);
    }
  }

  update(dt: number): void {
    this.environment.update(dt);
    this.orbitalBodies.update(dt, this.simulationTime);
    this.simulationTime += dt;
  }

  getGravityAcceleration(position: Vector3): Vector3 {
    const r = Math.sqrt(
      position.x ** 2 +
      position.y ** 2 +
      position.z ** 2
    );

    const g_mag = this.G * this.MOON_MASS / (r * r);
    const r_hat_x = -position.x / r;
    const r_hat_y = -position.y / r;
    const r_hat_z = -position.z / r;

    return {
      x: g_mag * r_hat_x,
      y: g_mag * r_hat_y,
      z: g_mag * r_hat_z,
    };
  }

  getTime(): number {
    return this.simulationTime;
  }
}
