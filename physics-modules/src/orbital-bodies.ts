/**
 * Orbital Bodies System
 *
 * Manages orbital objects (satellites, stations) in the game world:
 * - Two-body orbital mechanics (Kepler orbits)
 * - Docking ports with alignment requirements
 * - Target tracking for weapons practice
 * - Rendezvous guidance calculations
 */

export interface Vector3 {
  x: number;
  y: number;
  z: number;
}

export interface DockingPort {
  position: Vector3;      // Position in body frame
  direction: Vector3;     // Docking direction (unit vector)
  radius: number;         // Docking radius (m)
  occupied: boolean;      // Is something docked?
}

export interface OrbitalBodyConfig {
  name: string;
  mass: number;           // kg
  radius: number;         // m (size of the body)
  // Orbital elements
  semiMajorAxis: number;  // m
  eccentricity: number;   // 0-1
  inclination: number;    // radians
  longitudeOfAN: number;  // radians (Ω - longitude of ascending node)
  argOfPeriapsis: number; // radians (ω - argument of periapsis)
  meanAnomalyEpoch: number; // radians (M0 - mean anomaly at epoch)
  // Docking
  hasDockingPort?: boolean;
  dockingPortPosition?: Vector3;
  dockingPortDirection?: Vector3;
  dockingRadius?: number;
  // Target
  isTargetable?: boolean;
}

export interface OrbitalBodyState {
  name: string;
  position: Vector3;
  velocity: Vector3;
  mass: number;
  radius: number;
  orbitalPeriod: number;
  altitude: number;
  speed: number;
  dockingPort?: DockingPort;
  isTargetable: boolean;
}

export class OrbitalBody {
  public name: string;
  private mass: number;
  private radius: number;

  // Orbital elements
  private a: number;  // semi-major axis
  private e: number;  // eccentricity
  private i: number;  // inclination
  private Omega: number;  // longitude of ascending node
  private omega: number;  // argument of periapsis
  private M0: number;  // mean anomaly at epoch

  // Current state
  public position: Vector3;
  public velocity: Vector3;

  // Docking
  public dockingPort?: DockingPort;

  // Target
  public isTargetable: boolean;

  // Constants
  private readonly G = 6.67430e-11;
  private readonly MOON_MASS = 7.342e22;  // kg

  constructor(config: OrbitalBodyConfig) {
    this.name = config.name;
    this.mass = config.mass;
    this.radius = config.radius;

    this.a = config.semiMajorAxis;
    this.e = config.eccentricity;
    this.i = config.inclination;
    this.Omega = config.longitudeOfAN;
    this.omega = config.argOfPeriapsis;
    this.M0 = config.meanAnomalyEpoch;

    this.isTargetable = config.isTargetable ?? true;

    // Initialize docking port
    if (config.hasDockingPort) {
      this.dockingPort = {
        position: config.dockingPortPosition || { x: 0, y: 0, z: this.radius },
        direction: config.dockingPortDirection || { x: 0, y: 0, z: 1 },
        radius: config.dockingRadius || 2.0,
        occupied: false
      };
    }

    // Calculate initial position and velocity from orbital elements
    this.position = { x: 0, y: 0, z: 0 };
    this.velocity = { x: 0, y: 0, z: 0 };
    this.updateOrbit(0);
  }

  /**
   * Update orbital position using Kepler's equations
   */
  update(dt: number, time: number): void {
    this.updateOrbit(time);
  }

  private updateOrbit(time: number): void {
    // Calculate mean motion
    const mu = this.G * this.MOON_MASS;
    const n = Math.sqrt(mu / (this.a * this.a * this.a));

    // Mean anomaly
    const M = this.M0 + n * time;

    // Solve Kepler's equation for eccentric anomaly (E)
    const E = this.solveKeplerEquation(M, this.e);

    // True anomaly (ν)
    const nu = 2 * Math.atan2(
      Math.sqrt(1 + this.e) * Math.sin(E / 2),
      Math.sqrt(1 - this.e) * Math.cos(E / 2)
    );

    // Distance from focus
    const r = this.a * (1 - this.e * Math.cos(E));

    // Position in orbital plane
    const xOrb = r * Math.cos(nu);
    const yOrb = r * Math.sin(nu);

    // Velocity in orbital plane
    const vFactor = Math.sqrt(mu * this.a) / r;
    const vxOrb = -vFactor * Math.sin(E);
    const vyOrb = vFactor * Math.sqrt(1 - this.e * this.e) * Math.cos(E);

    // Rotate to inertial frame using orbital elements
    this.position = this.orbitalToInertial({ x: xOrb, y: yOrb, z: 0 });
    this.velocity = this.orbitalToInertial({ x: vxOrb, y: vyOrb, z: 0 });
  }

  /**
   * Solve Kepler's equation: M = E - e*sin(E)
   * Using Newton-Raphson iteration
   */
  private solveKeplerEquation(M: number, e: number): number {
    let E = M;  // Initial guess
    const tolerance = 1e-8;
    const maxIterations = 10;

    for (let i = 0; i < maxIterations; i++) {
      const f = E - e * Math.sin(E) - M;
      const fPrime = 1 - e * Math.cos(E);
      const dE = f / fPrime;

      E -= dE;

      if (Math.abs(dE) < tolerance) break;
    }

    return E;
  }

  /**
   * Transform from orbital plane to inertial frame
   */
  private orbitalToInertial(v: Vector3): Vector3 {
    const cosOmega = Math.cos(this.Omega);
    const sinOmega = Math.sin(this.Omega);
    const cosomega = Math.cos(this.omega);
    const sinomega = Math.sin(this.omega);
    const cosi = Math.cos(this.i);
    const sini = Math.sin(this.i);

    // Rotation matrix elements
    const P11 = cosOmega * cosomega - sinOmega * sinomega * cosi;
    const P12 = -cosOmega * sinomega - sinOmega * cosomega * cosi;
    const P21 = sinOmega * cosomega + cosOmega * sinomega * cosi;
    const P22 = -sinOmega * sinomega + cosOmega * cosomega * cosi;
    const P31 = sinomega * sini;
    const P32 = cosomega * sini;

    return {
      x: P11 * v.x + P12 * v.y,
      y: P21 * v.x + P22 * v.y,
      z: P31 * v.x + P32 * v.y
    };
  }

  /**
   * Get current state
   */
  getState(): OrbitalBodyState {
    const MOON_RADIUS = 1737400;
    const altitude = this.magnitude(this.position) - MOON_RADIUS;
    const speed = this.magnitude(this.velocity);

    const mu = this.G * this.MOON_MASS;
    const orbitalPeriod = 2 * Math.PI * Math.sqrt(this.a * this.a * this.a / mu);

    return {
      name: this.name,
      position: this.position,
      velocity: this.velocity,
      mass: this.mass,
      radius: this.radius,
      orbitalPeriod,
      altitude,
      speed,
      dockingPort: this.dockingPort ? { ...this.dockingPort } : undefined,
      isTargetable: this.isTargetable
    };
  }

  /**
   * Get docking port position in world frame
   */
  getDockingPortPosition(): Vector3 | null {
    if (!this.dockingPort) return null;

    // For now, assume body is not rotating
    // In full implementation, would rotate based on body attitude
    return {
      x: this.position.x + this.dockingPort.position.x,
      y: this.position.y + this.dockingPort.position.y,
      z: this.position.z + this.dockingPort.position.z
    };
  }

  /**
   * Check if a position is within docking range
   */
  isInDockingRange(shipPosition: Vector3): boolean {
    if (!this.dockingPort) return false;

    const portPos = this.getDockingPortPosition()!;
    const distance = this.distance(shipPosition, portPos);

    return distance <= this.dockingPort.radius;
  }

  /**
   * Calculate rendezvous guidance to this body
   */
  calculateRendezvousGuidance(shipPosition: Vector3, shipVelocity: Vector3): {
    distance: number;
    relativeVelocity: Vector3;
    timeToClosestApproach: number;
    closestApproachDistance: number;
    deltaVRequired: Vector3;
  } {
    // Relative position and velocity
    const relPos = {
      x: this.position.x - shipPosition.x,
      y: this.position.y - shipPosition.y,
      z: this.position.z - shipPosition.z
    };

    const relVel = {
      x: this.velocity.x - shipVelocity.x,
      y: this.velocity.y - shipVelocity.y,
      z: this.velocity.z - shipVelocity.z
    };

    const distance = this.magnitude(relPos);
    const relSpeed = this.magnitude(relVel);

    // Time to closest approach (if on collision course)
    const closingRate = this.dot(relPos, relVel) / distance;
    const timeToCA = closingRate < 0 ? -distance / closingRate : Infinity;

    // Closest approach distance
    const perpVel = Math.sqrt(Math.max(0, relSpeed * relSpeed - closingRate * closingRate));
    const closestDistance = perpVel * timeToCA;

    // Delta-V required for rendezvous (simplified Hohmann-like)
    // This is a simplified calculation; full orbital mechanics would be more complex
    const deltaV = {
      x: -relVel.x,
      y: -relVel.y,
      z: -relVel.z
    };

    return {
      distance,
      relativeVelocity: relVel,
      timeToClosestApproach: timeToCA,
      closestApproachDistance: closestDistance,
      deltaVRequired: deltaV
    };
  }

  // ========== Vector Math ==========

  private magnitude(v: Vector3): number {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  }

  private distance(a: Vector3, b: Vector3): number {
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const dz = b.z - a.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  private dot(a: Vector3, b: Vector3): number {
    return a.x * b.x + a.y * b.y + a.z * b.z;
  }
}

/**
 * Orbital Bodies Manager
 * Manages multiple orbital bodies in the scene
 */
export class OrbitalBodiesManager {
  private bodies: Map<string, OrbitalBody> = new Map();

  /**
   * Add an orbital body
   */
  addBody(config: OrbitalBodyConfig): void {
    const body = new OrbitalBody(config);
    this.bodies.set(config.name, body);
  }

  /**
   * Update all orbital bodies
   */
  update(dt: number, time: number): void {
    for (const body of this.bodies.values()) {
      body.update(dt, time);
    }
  }

  /**
   * Get body by name
   */
  getBody(name: string): OrbitalBody | undefined {
    return this.bodies.get(name);
  }

  /**
   * Get all bodies
   */
  getAllBodies(): OrbitalBody[] {
    return Array.from(this.bodies.values());
  }

  /**
   * Find nearest body to a position
   */
  findNearestBody(position: Vector3): { body: OrbitalBody; distance: number } | null {
    let nearest: { body: OrbitalBody; distance: number } | null = null;
    let minDist = Infinity;

    for (const body of this.bodies.values()) {
      const dx = body.position.x - position.x;
      const dy = body.position.y - position.y;
      const dz = body.position.z - position.z;
      const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);

      if (dist < minDist) {
        minDist = dist;
        nearest = { body, distance: dist };
      }
    }

    return nearest;
  }

  /**
   * Get all targetable bodies
   */
  getTargetableBodies(): OrbitalBody[] {
    return this.getAllBodies().filter(b => b.isTargetable);
  }
}

/**
 * Create a default satellite for practice
 */
export function createDefaultSatellite(): OrbitalBodyConfig {
  const MOON_RADIUS = 1737400;

  return {
    name: 'Practice Satellite',
    mass: 5000,  // 5 ton satellite
    radius: 3,   // 3m radius
    // Circular orbit at 100km altitude
    semiMajorAxis: MOON_RADIUS + 100000,
    eccentricity: 0.0,
    inclination: 0,  // Equatorial orbit
    longitudeOfAN: 0,
    argOfPeriapsis: 0,
    meanAnomalyEpoch: 0,
    hasDockingPort: true,
    dockingPortPosition: { x: 0, y: 0, z: 3 },
    dockingPortDirection: { x: 0, y: 0, z: 1 },
    dockingRadius: 2.0,
    isTargetable: true
  };
}
