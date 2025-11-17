/**
 * Waypoint Navigation System
 *
 * Manages navigation waypoints for mission planning:
 * - Waypoint creation and management
 * - Distance and bearing calculations
 * - Waypoint sequencing
 * - Arrival detection
 * - Navigation guidance to waypoints
 */

export interface Vector3 {
  x: number;
  y: number;
  z: number;
}

export interface Waypoint {
  id: string;
  name: string;
  latitude: number;        // degrees
  longitude: number;       // degrees
  altitude: number;        // meters above surface
  arrivalRadius: number;   // meters (considered "arrived" when within this distance)
  type: 'surface' | 'orbit' | 'custom';
  active: boolean;
  visited: boolean;
}

export interface WaypointGuidance {
  waypoint: Waypoint;
  distance: number;             // meters
  bearing: number;              // degrees (0=north, 90=east)
  heading: number;              // degrees to target
  timeToArrival: number;        // seconds (at current velocity)
  isArrived: boolean;
  deltaV: Vector3;              // Delta-V vector to waypoint
  elevation: number;            // Elevation angle (degrees, + = above horizon)
}

export class WaypointManager {
  private waypoints: Map<string, Waypoint> = new Map();
  private activeWaypoint: string | null = null;
  private waypointSequence: string[] = [];
  private sequenceIndex: number = 0;

  private readonly MOON_RADIUS = 1737400;  // meters

  /**
   * Add a waypoint
   */
  addWaypoint(waypoint: Omit<Waypoint, 'visited'>): void {
    const fullWaypoint: Waypoint = {
      ...waypoint,
      visited: false
    };
    this.waypoints.set(waypoint.id, fullWaypoint);
  }

  /**
   * Create surface waypoint from lat/lon
   */
  createSurfaceWaypoint(
    id: string,
    name: string,
    latitude: number,
    longitude: number,
    arrivalRadius: number = 100
  ): void {
    this.addWaypoint({
      id,
      name,
      latitude,
      longitude,
      altitude: 0,  // On surface
      arrivalRadius,
      type: 'surface',
      active: false
    });
  }

  /**
   * Create orbital waypoint
   */
  createOrbitalWaypoint(
    id: string,
    name: string,
    latitude: number,
    longitude: number,
    altitude: number,
    arrivalRadius: number = 1000
  ): void {
    this.addWaypoint({
      id,
      name,
      latitude,
      longitude,
      altitude,
      arrivalRadius,
      type: 'orbit',
      active: false
    });
  }

  /**
   * Set active waypoint
   */
  setActiveWaypoint(id: string): boolean {
    const waypoint = this.waypoints.get(id);
    if (!waypoint) return false;

    // Deactivate all others
    for (const wp of this.waypoints.values()) {
      wp.active = false;
    }

    waypoint.active = true;
    this.activeWaypoint = id;
    return true;
  }

  /**
   * Create waypoint sequence
   */
  setWaypointSequence(ids: string[]): boolean {
    // Validate all waypoints exist
    for (const id of ids) {
      if (!this.waypoints.has(id)) return false;
    }

    this.waypointSequence = ids;
    this.sequenceIndex = 0;

    if (ids.length > 0) {
      this.setActiveWaypoint(ids[0]);
    }

    return true;
  }

  /**
   * Advance to next waypoint in sequence
   */
  nextWaypoint(): boolean {
    if (this.waypointSequence.length === 0) return false;

    this.sequenceIndex++;
    if (this.sequenceIndex >= this.waypointSequence.length) {
      // Completed sequence
      this.activeWaypoint = null;
      return false;
    }

    return this.setActiveWaypoint(this.waypointSequence[this.sequenceIndex]);
  }

  /**
   * Calculate guidance to a waypoint
   */
  getGuidance(
    waypointId: string,
    shipPosition: Vector3,
    shipVelocity: Vector3,
    terrainElevation: number
  ): WaypointGuidance | null {
    const waypoint = this.waypoints.get(waypointId);
    if (!waypoint) return null;

    // Convert waypoint to 3D position
    const waypointPos = this.latLonAltToPosition(
      waypoint.latitude,
      waypoint.longitude,
      waypoint.altitude
    );

    // Calculate distance
    const dx = waypointPos.x - shipPosition.x;
    const dy = waypointPos.y - shipPosition.y;
    const dz = waypointPos.z - shipPosition.z;
    const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);

    // Check arrival
    const isArrived = distance <= waypoint.arrivalRadius;
    if (isArrived && !waypoint.visited) {
      waypoint.visited = true;
    }

    // Calculate bearing (horizontal direction)
    const bearing = Math.atan2(dy, dx) * 180 / Math.PI;

    // Calculate heading (3D direction)
    const heading = Math.atan2(dy, dx) * 180 / Math.PI;

    // Calculate elevation angle
    const horizontalDist = Math.sqrt(dx * dx + dy * dy);
    const elevation = Math.atan2(dz, horizontalDist) * 180 / Math.PI;

    // Time to arrival (at current velocity)
    const speed = Math.sqrt(
      shipVelocity.x ** 2 + shipVelocity.y ** 2 + shipVelocity.z ** 2
    );
    const timeToArrival = speed > 0.1 ? distance / speed : Infinity;

    // Delta-V required (simplified: point velocity toward waypoint)
    const desiredSpeed = 50;  // m/s approach speed
    const dirX = dx / distance;
    const dirY = dy / distance;
    const dirZ = dz / distance;

    const deltaV: Vector3 = {
      x: dirX * desiredSpeed - shipVelocity.x,
      y: dirY * desiredSpeed - shipVelocity.y,
      z: dirZ * desiredSpeed - shipVelocity.z
    };

    return {
      waypoint,
      distance,
      bearing,
      heading,
      timeToArrival,
      isArrived,
      deltaV,
      elevation
    };
  }

  /**
   * Get guidance to active waypoint
   */
  getActiveGuidance(
    shipPosition: Vector3,
    shipVelocity: Vector3,
    terrainElevation: number
  ): WaypointGuidance | null {
    if (!this.activeWaypoint) return null;
    return this.getGuidance(
      this.activeWaypoint,
      shipPosition,
      shipVelocity,
      terrainElevation
    );
  }

  /**
   * Get all waypoints
   */
  getAllWaypoints(): Waypoint[] {
    return Array.from(this.waypoints.values());
  }

  /**
   * Get waypoint by ID
   */
  getWaypoint(id: string): Waypoint | undefined {
    return this.waypoints.get(id);
  }

  /**
   * Remove waypoint
   */
  removeWaypoint(id: string): boolean {
    if (this.activeWaypoint === id) {
      this.activeWaypoint = null;
    }
    return this.waypoints.delete(id);
  }

  /**
   * Clear all waypoints
   */
  clearAll(): void {
    this.waypoints.clear();
    this.activeWaypoint = null;
    this.waypointSequence = [];
    this.sequenceIndex = 0;
  }

  /**
   * Convert lat/lon/alt to 3D position
   */
  private latLonAltToPosition(lat: number, lon: number, alt: number): Vector3 {
    const latRad = (lat * Math.PI) / 180;
    const lonRad = (lon * Math.PI) / 180;
    const r = this.MOON_RADIUS + alt;

    return {
      x: r * Math.cos(latRad) * Math.cos(lonRad),
      y: r * Math.cos(latRad) * Math.sin(lonRad),
      z: r * Math.sin(latRad)
    };
  }

  /**
   * Get state
   */
  getState() {
    return {
      numWaypoints: this.waypoints.size,
      activeWaypoint: this.activeWaypoint,
      sequenceProgress: this.waypointSequence.length > 0
        ? `${this.sequenceIndex + 1}/${this.waypointSequence.length}`
        : 'N/A',
      waypoints: this.getAllWaypoints()
    };
  }
}

/**
 * Create default practice waypoints
 */
export function createPracticeWaypoints(manager: WaypointManager): void {
  // Landing site
  manager.createSurfaceWaypoint(
    'landing_zone',
    'Landing Zone Alpha',
    0, 0,  // Equator, prime meridian
    50     // 50m arrival radius
  );

  // Nearby surface waypoint
  manager.createSurfaceWaypoint(
    'surface_waypoint_1',
    'Surface Checkpoint 1',
    0.1, 0.1,  // ~11km away
    100
  );

  // Orbital waypoint
  manager.createOrbitalWaypoint(
    'orbit_waypoint_1',
    'Orbital Checkpoint',
    0, 0,
    15000,  // 15km altitude
    500
  );

  // Create sequence
  manager.setWaypointSequence([
    'orbit_waypoint_1',
    'landing_zone',
    'surface_waypoint_1'
  ]);
}
