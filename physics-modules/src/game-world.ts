/**
 * Integrated Game World
 *
 * Combines all physics systems into a complete game environment:
 * - World (celestial bodies, gravity, spatial queries)
 * - Terrain (elevation, craters, surface normals)
 * - Environment (solar position, thermal, dust)
 * - Orbital Bodies (satellites with Kepler mechanics)
 * - Waypoints (navigation markers)
 * - Landing Gear (4-leg suspension system)
 */

import { World, CelestialBody, CelestialBodyFactory } from './world';
import { TerrainSystem } from './terrain-system';
import { EnvironmentSystem } from './environment';
import { OrbitalBodiesManager, createDefaultSatellite } from './orbital-bodies';
import { WaypointManager, createPracticeWaypoints } from './waypoints';
import { Vector3 } from './types';

export interface GameWorldConfig {
  /** Create default moon surface */
  createMoon?: boolean;
  /** Create practice satellite */
  createSatellite?: boolean;
  /** Create practice waypoints */
  createWaypoints?: boolean;
  /** Terrain seed for procedural generation */
  terrainSeed?: number;
}

/**
 * Complete game world with all physics systems
 */
export class GameWorld {
  // Core systems
  public readonly world: World;
  public readonly terrain: TerrainSystem;
  public readonly environment: EnvironmentSystem;
  public readonly orbitalBodies: OrbitalBodiesManager;
  public readonly waypoints: WaypointManager;

  // World reference body (the Moon)
  private moonBody: CelestialBody | null = null;

  constructor(config: GameWorldConfig = {}) {
    // Initialize core world
    this.world = new World();

    // Initialize terrain system
    this.terrain = new TerrainSystem({
      seed: config.terrainSeed || 12345,
      bodyRadius: 1737400, // Moon radius in meters
    });

    // Initialize environment system
    this.environment = new EnvironmentSystem({
      lunarDay: 2551443, // 29.5 Earth days in seconds
    });

    // Initialize orbital bodies manager
    this.orbitalBodies = new OrbitalBodiesManager();

    // Initialize waypoint manager
    this.waypoints = new WaypointManager();

    // Create default world objects
    if (config.createMoon !== false) {
      this.createMoon();
    }

    if (config.createSatellite) {
      this.createDefaultSatellite();
    }

    if (config.createWaypoints) {
      this.createDefaultWaypoints();
    }
  }

  /**
   * Create the Moon as the primary celestial body
   */
  private createMoon(): void {
    this.moonBody = CelestialBodyFactory.createMoon();
    this.world.addBody(this.moonBody);
  }

  /**
   * Create a practice satellite in orbit
   */
  private createDefaultSatellite(): void {
    const satelliteConfig = createDefaultSatellite();
    this.orbitalBodies.addBody(satelliteConfig);

    // Get the satellite that was just added
    const satellite = this.orbitalBodies.getBody(satelliteConfig.name);
    if (!satellite) {
      console.error('Failed to create satellite');
      return;
    }

    // Add satellite to world as a celestial body
    const satelliteWorldBody: CelestialBody = {
      id: 'practice-satellite',
      name: satelliteConfig.name,
      type: 'satellite',
      mass: satelliteConfig.mass,
      radius: satelliteConfig.radius,
      position: satellite.position,
      velocity: satellite.velocity,
      radarCrossSection: 50, // m²
      thermalSignature: 300, // K (spacecraft thermal signature)
      collisionDamage: 100,
      hardness: 50,
      collisionEnabled: true,
      orbitalElements: {
        semiMajorAxis: satelliteConfig.semiMajorAxis,
        eccentricity: satelliteConfig.eccentricity,
        inclination: satelliteConfig.inclination,
        argOfPeriapsis: satelliteConfig.argOfPeriapsis,
        longOfAscNode: satelliteConfig.longitudeOfAN,
        meanAnomalyAtEpoch: satelliteConfig.meanAnomalyEpoch,
        epoch: 0,
      },
    };

    this.world.addBody(satelliteWorldBody);
  }

  /**
   * Create default practice waypoints
   */
  private createDefaultWaypoints(): void {
    createPracticeWaypoints(this.waypoints);
  }

  /**
   * Update all world systems
   */
  update(dt: number): void {
    // Update world physics (celestial body motion, gravity)
    this.world.update(dt);

    // Update environment (solar position, thermal)
    this.environment.update(dt);

    // Update orbital bodies (satellite positions using Kepler mechanics)
    const currentTime = this.world.getTime();
    this.orbitalBodies.update(dt, currentTime);

    // Sync orbital body positions to world bodies
    this.syncOrbitalBodiesToWorld();
  }

  /**
   * Synchronize orbital body positions to world celestial bodies
   */
  private syncOrbitalBodiesToWorld(): void {
    const bodies = this.orbitalBodies.getAllBodies();
    bodies.forEach(body => {
      // Map orbital body name to world body ID
      const worldBodyId = 'practice-satellite'; // For now, we only have one satellite
      const worldBody = this.world.getBody(worldBodyId);
      if (worldBody) {
        worldBody.position = body.position;
        worldBody.velocity = body.velocity;
      }
    });
  }

  /**
   * Get terrain elevation at a position
   */
  getTerrainElevation(latitude: number, longitude: number): number {
    return this.terrain.getElevation(latitude, longitude);
  }

  /**
   * Get surface normal at a position
   */
  getSurfaceNormal(latitude: number, longitude: number): Vector3 {
    return this.terrain.getSurfaceNormal(latitude, longitude);
  }

  /**
   * Get surface conditions (temperature, illumination, etc.) at a position
   */
  getSurfaceConditions(position: Vector3, surfaceNormal: Vector3) {
    return this.environment.getSurfaceConditions(position, surfaceNormal);
  }

  /**
   * Calculate plume-dust interaction when spacecraft fires thrusters near surface
   */
  calculatePlumeInteraction(
    thrustN: number,
    exhaustVelocity: number,
    altitudeAGL: number,
    surfacePosition: Vector3
  ) {
    return this.environment.calculatePlumeInteraction(
      thrustN,
      exhaustVelocity,
      altitudeAGL,
      surfacePosition
    );
  }

  /**
   * Get waypoint guidance for navigation
   */
  getWaypointGuidance(
    waypointId: string,
    shipPosition: Vector3,
    shipVelocity: Vector3
  ) {
    const moonRadius = 1737400; // meters

    // Convert ship position to lat/lon to get terrain elevation
    const posLen = Math.sqrt(
      shipPosition.x * shipPosition.x +
      shipPosition.y * shipPosition.y +
      shipPosition.z * shipPosition.z
    );
    const lat = Math.asin(shipPosition.z / posLen) * (180 / Math.PI);
    const lon = Math.atan2(shipPosition.y, shipPosition.x) * (180 / Math.PI);
    const terrainElevation = this.terrain.getElevation(lat, lon);

    return this.waypoints.getGuidance(
      waypointId,
      shipPosition,
      shipVelocity,
      terrainElevation
    );
  }

  /**
   * Get active waypoint guidance
   */
  getActiveWaypointGuidance(shipPosition: Vector3, shipVelocity: Vector3) {
    const moonRadius = 1737400; // meters

    // Convert ship position to lat/lon to get terrain elevation
    const posLen = Math.sqrt(
      shipPosition.x * shipPosition.x +
      shipPosition.y * shipPosition.y +
      shipPosition.z * shipPosition.z
    );
    const lat = Math.asin(shipPosition.z / posLen) * (180 / Math.PI);
    const lon = Math.atan2(shipPosition.y, shipPosition.x) * (180 / Math.PI);
    const terrainElevation = this.terrain.getElevation(lat, lon);

    return this.waypoints.getActiveGuidance(shipPosition, shipVelocity, terrainElevation);
  }

  /**
   * Get nearest orbital body for rendezvous/targeting
   */
  getNearestOrbitalBody(shipPosition: Vector3, shipVelocity: Vector3) {
    return this.orbitalBodies.findNearestBody(shipPosition);
  }

  /**
   * Get rendezvous guidance to an orbital body
   */
  getRendezvousGuidance(bodyId: string, shipPosition: Vector3, shipVelocity: Vector3) {
    const body = this.orbitalBodies.getBody(bodyId);
    if (!body) {
      return null;
    }

    return body.calculateRendezvousGuidance(shipPosition, shipVelocity);
  }

  /**
   * Get current simulation time
   */
  getTime(): number {
    return this.world.getTime();
  }

  /**
   * Get all celestial bodies in the world
   */
  getAllBodies(): CelestialBody[] {
    return this.world.getAllBodies();
  }

  /**
   * Get gravity at a position
   */
  getGravityAt(position: Vector3, excludeId?: string): Vector3 {
    return this.world.getGravityAt(position, excludeId);
  }
}
