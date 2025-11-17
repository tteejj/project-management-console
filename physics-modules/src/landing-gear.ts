/**
 * Landing Gear System
 *
 * Implements realistic landing gear physics:
 * - 4-leg landing gear with independent suspension
 * - Spring-damper physics for shock absorption
 * - Ground contact detection and forces
 * - Stability analysis (tip-over detection)
 * - Damage model for hard landings
 * - Landing torques from off-center contact
 */

export interface Vector3 {
  x: number;
  y: number;
  z: number;
}

export interface LandingLeg {
  position: Vector3;      // Position in body frame (meters from CoM)
  extended: boolean;      // Is leg deployed?
  compressed: number;     // Current compression (0-1, 0=fully extended)
  velocity: number;       // Compression velocity (m/s)
  inContact: boolean;     // Is leg touching ground?
  health: number;         // Leg health (0-100%)
  contactForce: number;   // Current contact force (N)
}

export interface LandingGearConfig {
  numLegs?: number;           // Number of legs (default: 4)
  legLength?: number;         // Extended leg length (m)
  legRadius?: number;         // Radial distance from CoM (m)
  springConstant?: number;    // Spring stiffness (N/m)
  damperConstant?: number;    // Damping coefficient (N⋅s/m)
  maxCompression?: number;    // Maximum compression distance (m)
  footRadius?: number;        // Foot contact radius (m)
  breakingForce?: number;     // Force that breaks leg (N)
}

const DEFAULT_CONFIG: Required<LandingGearConfig> = {
  numLegs: 4,
  legLength: 2.0,           // 2m legs
  legRadius: 1.5,           // 1.5m from center
  springConstant: 50000,    // 50 kN/m (stiff spring)
  damperConstant: 5000,     // 5 kN⋅s/m (critical damping)
  maxCompression: 0.5,      // 0.5m max compression
  footRadius: 0.2,          // 20cm foot radius
  breakingForce: 100000     // 100 kN breaks leg
};

export interface LandingGearState {
  deployed: boolean;
  numLegsInContact: number;
  totalContactForce: number;
  centerOfPressure: Vector3;
  isStable: boolean;
  tipAngle: number;         // Angle from vertical (degrees)
  avgCompression: number;   // Average compression across all legs
  maxLegForce: number;      // Maximum force on any leg
  damagedLegs: number;
}

export class LandingGear {
  private config: Required<LandingGearConfig>;
  private legs: LandingLeg[] = [];
  private deployed: boolean = false;

  constructor(config?: LandingGearConfig) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.initializeLegs();
  }

  /**
   * Initialize landing legs in a symmetric pattern
   */
  private initializeLegs(): void {
    const numLegs = this.config.numLegs;
    const radius = this.config.legRadius;

    for (let i = 0; i < numLegs; i++) {
      const angle = (i / numLegs) * 2 * Math.PI;

      this.legs.push({
        position: {
          x: radius * Math.cos(angle),
          y: radius * Math.sin(angle),
          z: -this.config.legLength  // Legs point downward
        },
        extended: false,
        compressed: 0,
        velocity: 0,
        inContact: false,
        health: 100,
        contactForce: 0
      });
    }
  }

  /**
   * Deploy landing gear
   */
  deploy(): void {
    this.deployed = true;
    for (const leg of this.legs) {
      leg.extended = true;
    }
  }

  /**
   * Retract landing gear
   */
  retract(): void {
    this.deployed = false;
    for (const leg of this.legs) {
      leg.extended = false;
      leg.compressed = 0;
      leg.inContact = false;
    }
  }

  /**
   * Update landing gear physics
   *
   * @param dt Time step (seconds)
   * @param shipPosition Ship position in world frame
   * @param shipAttitude Ship attitude quaternion
   * @param shipVelocity Ship velocity
   * @param terrainElevation Terrain elevation at ship position
   * @param terrainNormal Surface normal at ship position
   * @param shipMass Ship mass (kg)
   * @returns Contact forces and torques
   */
  update(
    dt: number,
    shipPosition: Vector3,
    shipAttitude: { w: number; x: number; y: number; z: number },
    shipVelocity: Vector3,
    terrainElevation: number,
    terrainNormal: Vector3,
    shipMass: number
  ): { force: Vector3; torque: Vector3 } {
    if (!this.deployed) {
      return { force: { x: 0, y: 0, z: 0 }, torque: { x: 0, y: 0, z: 0 } };
    }

    let totalForce = { x: 0, y: 0, z: 0 };
    let totalTorque = { x: 0, y: 0, z: 0 };

    // Process each leg
    for (const leg of this.legs) {
      if (leg.health <= 0) continue;

      // Convert leg position from body frame to world frame
      const legWorldPos = this.rotateVector(leg.position, shipAttitude);
      const footPosition = {
        x: shipPosition.x + legWorldPos.x,
        y: shipPosition.y + legWorldPos.y,
        z: shipPosition.z + legWorldPos.z
      };

      // Check ground contact
      const MOON_RADIUS = 1737400;
      const footAltitude = this.magnitude(footPosition) - MOON_RADIUS - terrainElevation;

      if (footAltitude <= 0) {
        leg.inContact = true;

        // Calculate compression
        const penetration = -footAltitude;
        const maxComp = this.config.maxCompression;
        leg.compressed = Math.min(1.0, penetration / maxComp);

        // Spring-damper force (F = -kx - cv)
        const springForce = this.config.springConstant * penetration;

        // Calculate compression velocity (project ship velocity onto surface normal)
        const legVelWorld = this.rotateVector(
          { x: 0, y: 0, z: leg.velocity },
          shipAttitude
        );
        const normalVel = this.dot(shipVelocity, terrainNormal);
        const damperForce = this.config.damperConstant * Math.max(0, -normalVel);

        // Total force in surface normal direction
        const totalForceMag = springForce + damperForce;
        leg.contactForce = totalForceMag;

        // Apply force along surface normal (upward)
        const force = {
          x: terrainNormal.x * totalForceMag,
          y: terrainNormal.y * totalForceMag,
          z: terrainNormal.z * totalForceMag
        };

        totalForce = this.add(totalForce, force);

        // Calculate torque (r × F)
        const torque = this.cross(legWorldPos, force);
        totalTorque = this.add(totalTorque, torque);

        // Check for leg damage
        if (totalForceMag > this.config.breakingForce) {
          const damage = (totalForceMag - this.config.breakingForce) / this.config.breakingForce * 100;
          leg.health = Math.max(0, leg.health - damage);
        }

        // Update compression velocity (for damping next frame)
        leg.velocity = -normalVel;

      } else {
        leg.inContact = false;
        leg.compressed = 0;
        leg.velocity = 0;
        leg.contactForce = 0;
      }
    }

    return { force: totalForce, torque: totalTorque };
  }

  /**
   * Get landing gear state
   */
  getState(): LandingGearState {
    const legsInContact = this.legs.filter(leg => leg.inContact);
    const totalForce = legsInContact.reduce((sum, leg) => sum + leg.contactForce, 0);

    // Calculate center of pressure
    let cop = { x: 0, y: 0, z: 0 };
    if (legsInContact.length > 0) {
      for (const leg of legsInContact) {
        cop.x += leg.position.x * leg.contactForce;
        cop.y += leg.position.y * leg.contactForce;
        cop.z += leg.position.z * leg.contactForce;
      }
      cop.x /= totalForce;
      cop.y /= totalForce;
      cop.z /= totalForce;
    }

    // Check stability (CoP should be within support polygon)
    const isStable = this.checkStability(legsInContact);

    // Calculate average compression
    const avgCompression = legsInContact.length > 0
      ? legsInContact.reduce((sum, leg) => sum + leg.compressed, 0) / legsInContact.length
      : 0;

    // Maximum leg force
    const maxForce = Math.max(...this.legs.map(leg => leg.contactForce), 0);

    // Count damaged legs
    const damagedLegs = this.legs.filter(leg => leg.health < 100).length;

    return {
      deployed: this.deployed,
      numLegsInContact: legsInContact.length,
      totalContactForce: totalForce,
      centerOfPressure: cop,
      isStable,
      tipAngle: 0, // TODO: Calculate from attitude
      avgCompression,
      maxLegForce: maxForce,
      damagedLegs
    };
  }

  /**
   * Check if landing is stable (CoP within support polygon)
   */
  private checkStability(legsInContact: LandingLeg[]): boolean {
    if (legsInContact.length < 3) return false;

    // For 4 legs, check if CoP is within the quad
    // Simplified: check if we have at least 3 legs in contact
    return legsInContact.length >= 3;
  }

  /**
   * Get individual leg states
   */
  getLegs(): LandingLeg[] {
    return [...this.legs];
  }

  /**
   * Check if landing gear is deployed
   */
  isDeployed(): boolean {
    return this.deployed;
  }

  /**
   * Get contact status
   */
  getContactStatus() {
    const legsInContact = this.legs.filter(leg => leg.inContact).length;
    const isStable = this.checkStability(this.legs.filter(leg => leg.inContact));

    return {
      legsInContact,
      isStable,
      deployed: this.deployed,
    };
  }

  /**
   * Get health status
   */
  getHealthStatus() {
    const totalHealth = this.legs.reduce((sum, leg) => sum + leg.health, 0) / this.legs.length;
    const damagedLegs = this.legs.filter(leg => leg.health < 100).length;
    const brokenLegs = this.legs.filter(leg => leg.health === 0).length;

    return {
      totalHealth,
      damagedLegs,
      brokenLegs,
      legs: this.legs.map(leg => ({ health: leg.health, inContact: leg.inContact })),
    };
  }

  // ========== Vector Math Utilities ==========

  private rotateVector(v: Vector3, q: { w: number; x: number; y: number; z: number }): Vector3 {
    // Quaternion rotation: v' = q * v * q^-1
    const qv = {
      w: 0,
      x: v.x,
      y: v.y,
      z: v.z
    };

    // q * qv
    const temp = this.quatMult(q, qv);

    // temp * q^-1 (conjugate)
    const qConj = { w: q.w, x: -q.x, y: -q.y, z: -q.z };
    const result = this.quatMult(temp, qConj);

    return { x: result.x, y: result.y, z: result.z };
  }

  private quatMult(
    a: { w: number; x: number; y: number; z: number },
    b: { w: number; x: number; y: number; z: number }
  ): { w: number; x: number; y: number; z: number } {
    return {
      w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
      x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
      y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
      z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
    };
  }

  private add(a: Vector3, b: Vector3): Vector3 {
    return { x: a.x + b.x, y: a.y + b.y, z: a.z + b.z };
  }

  private cross(a: Vector3, b: Vector3): Vector3 {
    return {
      x: a.y * b.z - a.z * b.y,
      y: a.z * b.x - a.x * b.z,
      z: a.x * b.y - a.y * b.x
    };
  }

  private dot(a: Vector3, b: Vector3): number {
    return a.x * b.x + a.y * b.y + a.z * b.z;
  }

  private magnitude(v: Vector3): number {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  }
}
