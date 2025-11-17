/**
 * Orbital Mechanics System
 *
 * Keplerian orbital mechanics for spacecraft navigation:
 * - Orbital elements (a, e, i, Ω, ω, ν)
 * - State vector ↔ orbital elements conversion
 * - Orbit propagation (Kepler's equation)
 * - Hohmann transfers
 * - Lambert's problem (rendezvous trajectories)
 * - Two-body problem dynamics
 */

/**
 * Keplerian orbital elements
 */
export interface OrbitalElements {
  // Classical orbital elements
  semiMajorAxis: number; // a (km)
  eccentricity: number; // e (0 = circular, 0-1 = ellipse, 1 = parabola, >1 = hyperbola)
  inclination: number; // i (degrees)
  longitudeAscendingNode: number; // Ω (degrees) - RAAN
  argumentOfPeriapsis: number; // ω (degrees)
  trueAnomaly: number; // ν (degrees)

  // Derived elements
  semiMinorAxis?: number; // b (km)
  period?: number; // T (seconds)
  meanMotion?: number; // n (radians/second)
  apoapsisAltitude?: number; // km
  periapsisAltitude?: number; // km
}

/**
 * Orbital state vector
 */
export interface OrbitalState {
  position: { x: number; y: number; z: number }; // km
  velocity: { x: number; y: number; z: number }; // km/s
  time: number; // seconds since epoch
}

/**
 * Hohmann transfer parameters
 */
export interface HohmannTransfer {
  // Initial orbit
  r1: number; // Initial radius (km)
  v1: number; // Initial velocity (km/s)

  // Final orbit
  r2: number; // Final radius (km)
  v2: number; // Final velocity (km/s)

  // Transfer orbit
  deltaV1: number; // First burn (km/s)
  deltaV2: number; // Second burn (km/s)
  totalDeltaV: number; // Total Δv (km/s)
  transferTime: number; // Transfer duration (seconds)

  // Burn times
  burnTime1: number; // Time of first burn (seconds)
  burnTime2: number; // Time of second burn (seconds)

  // Phase angle
  phaseAngle: number; // Required phase angle at departure (degrees)
}

/**
 * Lambert's problem solution
 */
export interface LambertSolution {
  v1: { x: number; y: number; z: number }; // Departure velocity (km/s)
  v2: { x: number; y: number; z: number }; // Arrival velocity (km/s)
  transferTime: number; // Time of flight (seconds)
  deltaV: number; // Total Δv required (km/s)
  semiMajorAxis: number; // Transfer orbit semi-major axis (km)
  eccentricity: number; // Transfer orbit eccentricity
}

/**
 * Celestial body parameters
 */
export interface CelestialBody {
  name: string;
  mass: number; // kg
  radius: number; // km
  mu: number; // Gravitational parameter GM (km³/s²)
  rotationPeriod?: number; // seconds
  siderealDay?: number; // seconds
}

/**
 * Standard celestial bodies
 */
export const CELESTIAL_BODIES: Record<string, CelestialBody> = {
  Sun: {
    name: 'Sun',
    mass: 1.989e30,
    radius: 696000,
    mu: 132712440018, // km³/s²
    rotationPeriod: 25.05 * 86400
  },
  Earth: {
    name: 'Earth',
    mass: 5.972e24,
    radius: 6371,
    mu: 398600.4418, // km³/s²
    rotationPeriod: 86164.1, // sidereal day
    siderealDay: 86164.1
  },
  Moon: {
    name: 'Moon',
    mass: 7.342e22,
    radius: 1737.4,
    mu: 4902.8, // km³/s²
    rotationPeriod: 27.32 * 86400
  },
  Mars: {
    name: 'Mars',
    mass: 6.4171e23,
    radius: 3389.5,
    mu: 42828.37, // km³/s²
    rotationPeriod: 88775.244,
    siderealDay: 88775.244
  }
};

/**
 * Orbital Mechanics System
 */
export class OrbitalMechanicsSystem {
  private centralBody: CelestialBody;
  private mu: number; // Gravitational parameter

  // Constants
  private readonly DEG_TO_RAD = Math.PI / 180;
  private readonly RAD_TO_DEG = 180 / Math.PI;
  private readonly KEPLER_TOL = 1e-8; // Kepler equation convergence tolerance
  private readonly KEPLER_MAX_ITER = 50; // Max iterations for Kepler equation

  constructor(centralBody: CelestialBody = CELESTIAL_BODIES.Earth) {
    this.centralBody = centralBody;
    this.mu = centralBody.mu;
  }

  /**
   * Convert orbital state vector to Keplerian elements
   * Uses classical orbital mechanics algorithms
   */
  public stateToElements(state: OrbitalState): OrbitalElements {
    const r = state.position;
    const v = state.velocity;

    // Position and velocity magnitudes
    const rMag = Math.sqrt(r.x**2 + r.y**2 + r.z**2);
    const vMag = Math.sqrt(v.x**2 + v.y**2 + v.z**2);

    // Specific angular momentum vector h = r × v
    const h = {
      x: r.y * v.z - r.z * v.y,
      y: r.z * v.x - r.x * v.z,
      z: r.x * v.y - r.y * v.x
    };
    const hMag = Math.sqrt(h.x**2 + h.y**2 + h.z**2);

    // Node vector N = k × h (pointing to ascending node)
    const N = {
      x: -h.y,
      y: h.x,
      z: 0
    };
    const NMag = Math.sqrt(N.x**2 + N.y**2);

    // Eccentricity vector e = ((v² - μ/r) * r - (r · v) * v) / μ
    const rdotv = r.x * v.x + r.y * v.y + r.z * v.z;
    const eMag2 = 1 - (hMag**2) / (this.mu * rMag); // Alternative calculation

    const e = {
      x: ((vMag**2 - this.mu / rMag) * r.x - rdotv * v.x) / this.mu,
      y: ((vMag**2 - this.mu / rMag) * r.y - rdotv * v.y) / this.mu,
      z: ((vMag**2 - this.mu / rMag) * r.z - rdotv * v.z) / this.mu
    };
    const eMag = Math.sqrt(e.x**2 + e.y**2 + e.z**2);

    // Specific orbital energy ε = v²/2 - μ/r
    const energy = (vMag**2) / 2 - this.mu / rMag;

    // Semi-major axis a = -μ / (2ε)
    const a = -this.mu / (2 * energy);

    // Inclination i = arccos(h_z / |h|)
    const i = Math.acos(h.z / hMag) * this.RAD_TO_DEG;

    // RAAN Ω = arccos(N_x / |N|)
    let RAAN = 0;
    if (NMag > 1e-10) {
      RAAN = Math.acos(N.x / NMag) * this.RAD_TO_DEG;
      if (N.y < 0) {
        RAAN = 360 - RAAN;
      }
    }

    // Argument of periapsis ω = arccos(N · e / (|N| * |e|))
    let argPe = 0;
    if (eMag > 1e-10 && NMag > 1e-10) {
      const cosArgPe = (N.x * e.x + N.y * e.y) / (NMag * eMag);
      argPe = Math.acos(Math.max(-1, Math.min(1, cosArgPe))) * this.RAD_TO_DEG;
      if (e.z < 0) {
        argPe = 360 - argPe;
      }
    }

    // True anomaly ν = arccos(e · r / (|e| * |r|))
    let nu = 0;
    if (eMag > 1e-10) {
      const cosNu = (e.x * r.x + e.y * r.y + e.z * r.z) / (eMag * rMag);
      nu = Math.acos(Math.max(-1, Math.min(1, cosNu))) * this.RAD_TO_DEG;
      if (rdotv < 0) {
        nu = 360 - nu;
      }
    } else {
      // Circular orbit - measure from ascending node
      if (NMag > 1e-10) {
        const cosNu = (N.x * r.x + N.y * r.y) / (NMag * rMag);
        nu = Math.acos(Math.max(-1, Math.min(1, cosNu))) * this.RAD_TO_DEG;
        if (r.z < 0) {
          nu = 360 - nu;
        }
      } else {
        // Equatorial and circular
        nu = Math.atan2(r.y, r.x) * this.RAD_TO_DEG;
        if (nu < 0) nu += 360;
      }
    }

    // Derived parameters
    const b = a * Math.sqrt(1 - eMag**2); // Semi-minor axis
    const period = 2 * Math.PI * Math.sqrt(a**3 / this.mu); // Orbital period
    const meanMotion = Math.sqrt(this.mu / a**3); // Mean motion

    // Apoapsis and periapsis altitudes
    const rPe = a * (1 - eMag);
    const rAp = a * (1 + eMag);
    const periapsisAlt = rPe - this.centralBody.radius;
    const apoapsisAlt = rAp - this.centralBody.radius;

    return {
      semiMajorAxis: a,
      eccentricity: eMag,
      inclination: i,
      longitudeAscendingNode: RAAN,
      argumentOfPeriapsis: argPe,
      trueAnomaly: nu,
      semiMinorAxis: b,
      period,
      meanMotion,
      periapsisAltitude: periapsisAlt,
      apoapsisAltitude: apoapsisAlt
    };
  }

  /**
   * Convert Keplerian elements to orbital state vector
   */
  public elementsToState(elements: OrbitalElements, time: number = 0): OrbitalState {
    const a = elements.semiMajorAxis;
    const e = elements.eccentricity;
    const i = elements.inclination * this.DEG_TO_RAD;
    const RAAN = elements.longitudeAscendingNode * this.DEG_TO_RAD;
    const argPe = elements.argumentOfPeriapsis * this.DEG_TO_RAD;
    const nu = elements.trueAnomaly * this.DEG_TO_RAD;

    // Distance from central body
    const r = (a * (1 - e**2)) / (1 + e * Math.cos(nu));

    // Position and velocity in orbital plane (perifocal frame)
    const rPQW = {
      x: r * Math.cos(nu),
      y: r * Math.sin(nu),
      z: 0
    };

    const sqrtMuOverP = Math.sqrt(this.mu / (a * (1 - e**2)));
    const vPQW = {
      x: -sqrtMuOverP * Math.sin(nu),
      y: sqrtMuOverP * (e + Math.cos(nu)),
      z: 0
    };

    // Rotation matrices
    const cosRAAN = Math.cos(RAAN);
    const sinRAAN = Math.sin(RAAN);
    const cosArgPe = Math.cos(argPe);
    const sinArgPe = Math.sin(argPe);
    const cosI = Math.cos(i);
    const sinI = Math.sin(i);

    // Combined rotation matrix from perifocal to inertial frame
    // R = R_z(-RAAN) * R_x(-i) * R_z(-argPe)
    const R11 = cosRAAN * cosArgPe - sinRAAN * sinArgPe * cosI;
    const R12 = -cosRAAN * sinArgPe - sinRAAN * cosArgPe * cosI;
    const R21 = sinRAAN * cosArgPe + cosRAAN * sinArgPe * cosI;
    const R22 = -sinRAAN * sinArgPe + cosRAAN * cosArgPe * cosI;
    const R31 = sinArgPe * sinI;
    const R32 = cosArgPe * sinI;

    // Transform to inertial frame
    const position = {
      x: R11 * rPQW.x + R12 * rPQW.y,
      y: R21 * rPQW.x + R22 * rPQW.y,
      z: R31 * rPQW.x + R32 * rPQW.y
    };

    const velocity = {
      x: R11 * vPQW.x + R12 * vPQW.y,
      y: R21 * vPQW.x + R22 * vPQW.y,
      z: R31 * vPQW.x + R32 * vPQW.y
    };

    return {
      position,
      velocity,
      time
    };
  }

  /**
   * Propagate orbit forward in time using Kepler's equation
   */
  public propagateOrbit(initialState: OrbitalState, dt: number): OrbitalState {
    // Convert to orbital elements
    const elements = this.stateToElements(initialState);

    const a = elements.semiMajorAxis;
    const e = elements.eccentricity;
    const nu0 = elements.trueAnomaly * this.DEG_TO_RAD;

    // Mean motion
    const n = Math.sqrt(this.mu / a**3);

    // Eccentric anomaly at t0
    const E0 = this.trueToEccentricAnomaly(nu0, e);

    // Mean anomaly at t0
    const M0 = E0 - e * Math.sin(E0);

    // Mean anomaly at t
    const M = M0 + n * dt;

    // Solve Kepler's equation for E
    const E = this.solveKeplerEquation(M, e);

    // Convert back to true anomaly
    const nu = this.eccentricToTrueAnomaly(E, e);

    // Update elements with new true anomaly
    const newElements: OrbitalElements = {
      ...elements,
      trueAnomaly: nu * this.RAD_TO_DEG
    };

    // Convert back to state vector
    return this.elementsToState(newElements, initialState.time + dt);
  }

  /**
   * Solve Kepler's equation M = E - e*sin(E) for E using Newton-Raphson
   */
  private solveKeplerEquation(M: number, e: number): number {
    // Normalize M to [0, 2π)
    M = M % (2 * Math.PI);
    if (M < 0) M += 2 * Math.PI;

    // Initial guess
    let E = M + e * Math.sin(M);

    // Newton-Raphson iteration
    for (let i = 0; i < this.KEPLER_MAX_ITER; i++) {
      const f = E - e * Math.sin(E) - M;
      const fPrime = 1 - e * Math.cos(E);

      const delta = f / fPrime;
      E = E - delta;

      if (Math.abs(delta) < this.KEPLER_TOL) {
        return E;
      }
    }

    // Failed to converge
    console.warn('Kepler equation failed to converge');
    return E;
  }

  /**
   * Convert true anomaly to eccentric anomaly
   */
  private trueToEccentricAnomaly(nu: number, e: number): number {
    const cosE = (e + Math.cos(nu)) / (1 + e * Math.cos(nu));
    const sinE = (Math.sqrt(1 - e**2) * Math.sin(nu)) / (1 + e * Math.cos(nu));
    return Math.atan2(sinE, cosE);
  }

  /**
   * Convert eccentric anomaly to true anomaly
   */
  private eccentricToTrueAnomaly(E: number, e: number): number {
    const cosNu = (Math.cos(E) - e) / (1 - e * Math.cos(E));
    const sinNu = (Math.sqrt(1 - e**2) * Math.sin(E)) / (1 - e * Math.cos(E));
    return Math.atan2(sinNu, cosNu);
  }

  /**
   * Calculate orbital velocity at given radius
   */
  public orbitalVelocity(r: number, a: number): number {
    return Math.sqrt(this.mu * (2/r - 1/a));
  }

  /**
   * Calculate circular orbital velocity
   */
  public circularVelocity(r: number): number {
    return Math.sqrt(this.mu / r);
  }

  /**
   * Calculate escape velocity
   */
  public escapeVelocity(r: number): number {
    return Math.sqrt(2 * this.mu / r);
  }

  /**
   * Get orbital period
   */
  public orbitalPeriod(a: number): number {
    return 2 * Math.PI * Math.sqrt(a**3 / this.mu);
  }

  /**
   * Get central body
   */
  public getCentralBody(): CelestialBody {
    return this.centralBody;
  }

  /**
   * Set central body
   */
  public setCentralBody(body: CelestialBody): void {
    this.centralBody = body;
    this.mu = body.mu;
  }

  /**
   * Calculate Hohmann transfer between two circular orbits
   */
  public calculateHohmannTransfer(r1: number, r2: number): HohmannTransfer {
    // Velocities in initial and final circular orbits
    const v1 = this.circularVelocity(r1);
    const v2 = this.circularVelocity(r2);

    // Semi-major axis of transfer orbit
    const aTransfer = (r1 + r2) / 2;

    // Velocities at periapsis and apoapsis of transfer orbit
    const vPeriapsis = this.orbitalVelocity(r1, aTransfer);
    const vApoapsis = this.orbitalVelocity(r2, aTransfer);

    // Delta-V calculations
    const deltaV1 = Math.abs(vPeriapsis - v1);
    const deltaV2 = Math.abs(v2 - vApoapsis);
    const totalDeltaV = deltaV1 + deltaV2;

    // Transfer time (half period of transfer orbit)
    const transferTime = Math.PI * Math.sqrt(aTransfer**3 / this.mu);

    // Phase angle: angle target must be ahead/behind at departure
    // φ = 180° - (180° * sqrt(((r1+r2)/(2*r2))^3))
    const phaseAngle = 180 - 180 * Math.sqrt(Math.pow((r1 + r2) / (2 * r2), 3));

    return {
      r1,
      v1,
      r2,
      v2,
      deltaV1,
      deltaV2,
      totalDeltaV,
      transferTime,
      burnTime1: 0, // First burn at departure
      burnTime2: transferTime, // Second burn at arrival
      phaseAngle
    };
  }

  /**
   * Calculate bi-elliptic transfer (more efficient for large radius ratios)
   */
  public calculateBiellipticTransfer(r1: number, r2: number, rb: number): HohmannTransfer {
    // rb is the intermediate apoapsis radius (should be > r2)
    const v1 = this.circularVelocity(r1);
    const v2 = this.circularVelocity(r2);

    // First transfer orbit (r1 to rb)
    const a1 = (r1 + rb) / 2;
    const vPeriapsis1 = this.orbitalVelocity(r1, a1);
    const vApoapsis1 = this.orbitalVelocity(rb, a1);

    // Second transfer orbit (rb to r2)
    const a2 = (rb + r2) / 2;
    const vPeriapsis2 = this.orbitalVelocity(r2, a2);
    const vApoapsis2 = this.orbitalVelocity(rb, a2);

    // Delta-V calculations
    const deltaV1 = Math.abs(vPeriapsis1 - v1);
    const deltaV2 = Math.abs(vApoapsis2 - vApoapsis1);
    const deltaV3 = Math.abs(v2 - vPeriapsis2);
    const totalDeltaV = deltaV1 + deltaV2 + deltaV3;

    // Transfer times
    const transferTime1 = Math.PI * Math.sqrt(a1**3 / this.mu);
    const transferTime2 = Math.PI * Math.sqrt(a2**3 / this.mu);
    const totalTime = transferTime1 + transferTime2;

    return {
      r1,
      v1,
      r2,
      v2,
      deltaV1,
      deltaV2: deltaV2 + deltaV3,
      totalDeltaV,
      transferTime: totalTime,
      burnTime1: 0,
      burnTime2: transferTime1,
      phaseAngle: 0 // Not calculated for bi-elliptic
    };
  }

  /**
   * Solve Lambert's problem: find transfer orbit between two position vectors
   * Given r1, r2, and time of flight, find v1 and v2
   *
   * Uses universal variable formulation
   */
  public solveLambert(
    r1Vec: { x: number; y: number; z: number },
    r2Vec: { x: number; y: number; z: number },
    tof: number,
    prograde: boolean = true
  ): LambertSolution | null {
    const r1 = Math.sqrt(r1Vec.x**2 + r1Vec.y**2 + r1Vec.z**2);
    const r2 = Math.sqrt(r2Vec.x**2 + r2Vec.y**2 + r2Vec.z**2);

    // Angle between position vectors
    const cosNu = (r1Vec.x * r2Vec.x + r1Vec.y * r2Vec.y + r1Vec.z * r2Vec.z) / (r1 * r2);
    const nu = Math.acos(Math.max(-1, Math.min(1, cosNu)));

    // Determine transfer angle (prograde or retrograde)
    const crossProd = {
      x: r1Vec.y * r2Vec.z - r1Vec.z * r2Vec.y,
      y: r1Vec.z * r2Vec.x - r1Vec.x * r2Vec.z,
      z: r1Vec.x * r2Vec.y - r1Vec.y * r2Vec.x
    };
    const crossMag = Math.sqrt(crossProd.x**2 + crossProd.y**2 + crossProd.z**2);

    let transferAngle = nu;
    if (!prograde) {
      transferAngle = 2 * Math.PI - nu;
    }

    // Calculate A parameter
    const A = Math.sin(transferAngle) * Math.sqrt(r1 * r2 / (1 - Math.cos(transferAngle)));

    if (A === 0) {
      return null; // Degenerate case
    }

    // Initial guess for z (universal variable)
    let z = 0;
    const maxIter = 50;
    const tol = 1e-8;

    for (let i = 0; i < maxIter; i++) {
      const { C, S } = this.stumpffFunctions(z);

      const y = r1 + r2 + A * (z * S - 1) / Math.sqrt(C);

      if (y < 0) {
        // Adjust z
        z = z + 0.1;
        continue;
      }

      const chi = Math.sqrt(y / C);
      const tofCalc = (chi**3 * S + A * Math.sqrt(y)) / Math.sqrt(this.mu);

      const error = tofCalc - tof;

      if (Math.abs(error) < tol) {
        // Found solution
        const f = 1 - y / r1;
        const g = A * Math.sqrt(y / this.mu);
        const gDot = 1 - y / r2;

        const v1 = {
          x: (r2Vec.x - f * r1Vec.x) / g,
          y: (r2Vec.y - f * r1Vec.y) / g,
          z: (r2Vec.z - f * r1Vec.z) / g
        };

        const v2 = {
          x: (gDot * r2Vec.x - r1Vec.x) / g,
          y: (gDot * r2Vec.y - r1Vec.y) / g,
          z: (gDot * r2Vec.z - r1Vec.z) / g
        };

        const v1Mag = Math.sqrt(v1.x**2 + v1.y**2 + v1.z**2);
        const v2Mag = Math.sqrt(v2.x**2 + v2.y**2 + v2.z**2);

        // Calculate transfer orbit parameters
        const vMag = v1Mag;
        const rMag = r1;
        const energy = vMag**2 / 2 - this.mu / rMag;
        const a = -this.mu / (2 * energy);
        const h = crossMag;
        const e = Math.sqrt(1 - h**2 / (this.mu * a));

        const deltaV = Math.abs(v1Mag) + Math.abs(v2Mag); // Simplified

        return {
          v1,
          v2,
          transferTime: tof,
          deltaV,
          semiMajorAxis: a,
          eccentricity: e
        };
      }

      // Newton-Raphson update
      const dtdz = this.derivativeTimeWrtZ(z, A, y, r1, r2, C, S);
      z = z - error / dtdz;
    }

    // Failed to converge
    console.warn('Lambert solver failed to converge');
    return null;
  }

  /**
   * Stumpff functions C(z) and S(z) for universal variable formulation
   */
  private stumpffFunctions(z: number): { C: number; S: number } {
    let C: number;
    let S: number;

    if (z > 1e-6) {
      // Elliptical orbit
      const sqrtZ = Math.sqrt(z);
      C = (1 - Math.cos(sqrtZ)) / z;
      S = (sqrtZ - Math.sin(sqrtZ)) / (sqrtZ**3);
    } else if (z < -1e-6) {
      // Hyperbolic orbit
      const sqrtMinusZ = Math.sqrt(-z);
      C = (1 - Math.cosh(sqrtMinusZ)) / z;
      S = (Math.sinh(sqrtMinusZ) - sqrtMinusZ) / (sqrtMinusZ**3);
    } else {
      // Parabolic orbit (z ≈ 0)
      C = 0.5;
      S = 1.0 / 6.0;
    }

    return { C, S };
  }

  /**
   * Derivative of time with respect to z for Newton-Raphson
   */
  private derivativeTimeWrtZ(
    z: number,
    A: number,
    y: number,
    r1: number,
    r2: number,
    C: number,
    S: number
  ): number {
    if (z === 0) {
      return Math.sqrt(2) / 40 * y**1.5 + A / 8 * (Math.sqrt(y) + A * Math.sqrt(1 / (2 * y)));
    }

    const chi = Math.sqrt(y / C);
    const dyDz = (1 / (2 * z)) * (C - 3 * S / (2 * C));

    return (chi**3 / Math.sqrt(this.mu)) * (dyDz * (3 * S * C - 1) / (2 * C) + A / 8 * (3 * S / C * Math.sqrt(y) + A / chi));
  }

  /**
   * Calculate relative phase angle between two orbiting objects
   */
  public calculatePhaseAngle(
    elements1: OrbitalElements,
    elements2: OrbitalElements
  ): number {
    // Calculate mean longitudes
    const L1 = elements1.longitudeAscendingNode +
                elements1.argumentOfPeriapsis +
                elements1.trueAnomaly;

    const L2 = elements2.longitudeAscendingNode +
                elements2.argumentOfPeriapsis +
                elements2.trueAnomaly;

    // Phase angle
    let phaseAngle = L2 - L1;

    // Normalize to [0, 360)
    while (phaseAngle < 0) phaseAngle += 360;
    while (phaseAngle >= 360) phaseAngle -= 360;

    return phaseAngle;
  }

  /**
   * Calculate synodic period between two orbits
   */
  public synodicPeriod(period1: number, period2: number): number {
    return Math.abs((period1 * period2) / (period1 - period2));
  }
}

