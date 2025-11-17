/**
 * Navigation System
 *
 * Provides trajectory prediction, navball display, velocity decomposition,
 * and enhanced telemetry for spacecraft navigation.
 */

export interface Vector3 {
  x: number;
  y: number;
  z: number;
}

export interface Quaternion {
  w: number;
  x: number;
  y: number;
  z: number;
}

export interface LatLon {
  lat: number;   // degrees
  lon: number;   // degrees
}

export interface ImpactPrediction {
  impactTime: number;           // seconds until impact
  impactPosition: Vector3;      // position at impact
  impactVelocity: Vector3;      // velocity at impact
  impactSpeed: number;          // magnitude of impact velocity
  coordinates: LatLon;          // lat/lon of impact point
  willImpact: boolean;          // false if escaping
}

export interface SuicideBurnData {
  burnAltitude: number;         // altitude to start burn (m)
  currentAltitude: number;      // current altitude (m)
  timeUntilBurn: number;        // seconds until burn should start
  shouldBurn: boolean;          // true if should burn now
  burnDuration: number;         // estimated burn duration (s)
  finalSpeed: number;           // predicted final speed (m/s)
}

export interface VelocityBreakdown {
  total: number;                // Total speed magnitude (m/s)
  vertical: number;             // Radial component (toward/away from surface)
  horizontal: number;           // Tangential component (parallel to surface)
  north: number;                // North component (m/s)
  east: number;                 // East component (m/s)
  prograde: number;             // Along velocity vector (m/s)
  normal: number;               // Perpendicular to orbital plane (m/s)
}

export interface FlightTelemetry {
  // Position & Velocity
  altitude: number;             // Orbital altitude (m)
  radarAltitude: number;        // Terrain-relative altitude (m)
  verticalSpeed: number;        // Radial velocity (m/s)
  horizontalSpeed: number;      // Tangential velocity (m/s)
  totalSpeed: number;           // Total velocity magnitude (m/s)

  // Trajectory
  timeToImpact: number;         // Seconds until surface impact
  impactSpeed: number;          // Predicted impact speed (m/s)
  impactCoordinates: LatLon;    // Impact lat/lon
  suicideBurnAltitude: number;  // Altitude to start decel burn (m)
  timeToSuicideBurn: number;    // Seconds until burn start

  // Attitude
  pitch: number;                // Pitch angle (degrees)
  roll: number;                 // Roll angle (degrees)
  yaw: number;                  // Yaw angle (degrees)
  heading: number;              // Compass heading (degrees, 0=North)
  angleFromVertical: number;    // Angle from local vertical (degrees)

  // Propulsion
  thrust: number;               // Current thrust (N)
  throttle: number;             // Throttle setting (0-1)
  twr: number;                  // Thrust-to-weight ratio

  // Resources
  fuelRemaining: number;        // Total fuel mass (kg)
  fuelRemainingPercent: number; // Fuel as percent of capacity
  estimatedBurnTime: number;    // Time until fuel depletion (s)
  deltaVRemaining: number;      // Remaining delta-v (m/s)

  // Navigation (if target set)
  distanceToTarget: number | null;  // Distance to target (m)
  bearingToTarget: number | null;   // Bearing to target (degrees)
}

/**
 * Trajectory Predictor
 * Numerically integrates trajectory to predict impact point
 */
export class TrajectoryPredictor {
  private readonly MOON_MASS = 7.342e22;        // kg
  private readonly MOON_RADIUS = 1737400;       // m
  private readonly G = 6.674e-11;               // N⋅m²/kg²

  predict(
    position: Vector3,
    velocity: Vector3,
    mass: number,
    thrust: number,
    thrustDirection: Vector3,  // Unit vector
    maxSimTime: number = 1000   // seconds
  ): ImpactPrediction {
    // Copy initial state
    let pos = { ...position };
    let vel = { ...velocity };
    const dt = 0.1;
    let time = 0;

    while (time < maxSimTime) {
      const altitude = this.getAltitude(pos);

      // Check if impacted
      if (altitude <= 0) {
        const impactSpeed = this.magnitude(vel);
        return {
          impactTime: time,
          impactPosition: pos,
          impactVelocity: vel,
          impactSpeed,
          coordinates: this.positionToLatLon(pos),
          willImpact: true
        };
      }

      // Calculate acceleration
      const gravity = this.calculateGravity(pos);
      const thrustAccel = {
        x: (thrust * thrustDirection.x) / mass,
        y: (thrust * thrustDirection.y) / mass,
        z: (thrust * thrustDirection.z) / mass
      };

      const accel = {
        x: gravity.x + thrustAccel.x,
        y: gravity.y + thrustAccel.y,
        z: gravity.z + thrustAccel.z
      };

      // Integrate velocity and position
      vel.x += accel.x * dt;
      vel.y += accel.y * dt;
      vel.z += accel.z * dt;

      pos.x += vel.x * dt;
      pos.y += vel.y * dt;
      pos.z += vel.z * dt;

      time += dt;
    }

    // Didn't impact within simulation time - escaping or very long time
    return {
      impactTime: Infinity,
      impactPosition: pos,
      impactVelocity: vel,
      impactSpeed: this.magnitude(vel),
      coordinates: this.positionToLatLon(pos),
      willImpact: false
    };
  }

  private calculateGravity(position: Vector3): Vector3 {
    const r = this.magnitude(position);
    if (r < 1e-10) return { x: 0, y: 0, z: 0 };

    const gMag = -this.G * this.MOON_MASS / (r * r);
    const rNorm = {
      x: position.x / r,
      y: position.y / r,
      z: position.z / r
    };

    return {
      x: gMag * rNorm.x,
      y: gMag * rNorm.y,
      z: gMag * rNorm.z
    };
  }

  private getAltitude(position: Vector3): number {
    return this.magnitude(position) - this.MOON_RADIUS;
  }

  private positionToLatLon(position: Vector3): LatLon {
    const r = this.magnitude(position);
    if (r < 1e-10) return { lat: 0, lon: 0 };

    const lat = Math.asin(position.z / r) * 180 / Math.PI;
    const lon = Math.atan2(position.y, position.x) * 180 / Math.PI;

    return { lat, lon };
  }

  private magnitude(v: Vector3): number {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  }
}

/**
 * Suicide Burn Calculator
 * Calculates optimal deceleration burn parameters
 */
export class SuicideBurnCalculator {
  private readonly MOON_GRAVITY = 1.62;  // m/s²

  calculate(
    altitude: number,
    verticalSpeed: number,
    mass: number,
    maxThrust: number,
    safetyFactor: number = 1.15
  ): SuicideBurnData {
    // Account for local gravity
    const acceleration = (maxThrust / mass) - this.MOON_GRAVITY;

    if (acceleration <= 0) {
      // Cannot decelerate - thrust too low
      return {
        burnAltitude: Infinity,
        currentAltitude: altitude,
        timeUntilBurn: Infinity,
        shouldBurn: true,  // Burn NOW!
        burnDuration: Infinity,
        finalSpeed: Math.abs(verticalSpeed)
      };
    }

    // Calculate stopping distance: d = v² / (2a)
    const stopDistance = (verticalSpeed * verticalSpeed) / (2 * acceleration);
    const burnAltitude = stopDistance * safetyFactor;

    // Time until should start burn
    const timeUntilBurn = Math.abs(verticalSpeed) > 0.1 ?
      (altitude - burnAltitude) / Math.abs(verticalSpeed) : 0;

    // Burn duration: t = v / a
    const burnDuration = Math.abs(verticalSpeed) / acceleration;

    // Final speed (should be near zero with safety factor)
    const finalSpeed = Math.max(0, Math.abs(verticalSpeed) - acceleration * burnDuration);

    return {
      burnAltitude,
      currentAltitude: altitude,
      timeUntilBurn: Math.max(0, timeUntilBurn),
      shouldBurn: altitude <= burnAltitude && verticalSpeed < -0.1,
      burnDuration,
      finalSpeed
    };
  }
}

/**
 * Velocity Decomposer
 * Breaks down velocity into meaningful components
 */
export class VelocityDecomposer {
  decompose(
    velocity: Vector3,
    position: Vector3
  ): VelocityBreakdown {
    const total = this.magnitude(velocity);

    // Radial (vertical) component - projection onto position vector
    const posNorm = this.normalize(position);
    const vertical = this.dot(velocity, posNorm);

    // Horizontal is perpendicular to radial
    const horizontalVec = {
      x: velocity.x - vertical * posNorm.x,
      y: velocity.y - vertical * posNorm.y,
      z: velocity.z - vertical * posNorm.z
    };
    const horizontal = this.magnitude(horizontalVec);

    // North/East decomposition (simplified - assume Z is north, Y is east)
    const north = velocity.z;
    const east = velocity.y;

    // Prograde is just the velocity direction
    const prograde = total;

    // Normal (perpendicular to orbital plane)
    // For circular orbit, this would be cross product of position and velocity
    const orbitalAngMom = this.crossProduct(position, velocity);
    const normal = this.magnitude(orbitalAngMom) / this.magnitude(position);

    return {
      total,
      vertical,
      horizontal,
      north,
      east,
      prograde,
      normal
    };
  }

  private magnitude(v: Vector3): number {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  }

  private normalize(v: Vector3): Vector3 {
    const mag = this.magnitude(v);
    if (mag < 1e-10) return { x: 0, y: 0, z: 1 };
    return { x: v.x / mag, y: v.y / mag, z: v.z / mag };
  }

  private dot(a: Vector3, b: Vector3): number {
    return a.x * b.x + a.y * b.y + a.z * b.z;
  }

  private crossProduct(a: Vector3, b: Vector3): Vector3 {
    return {
      x: a.y * b.z - a.z * b.y,
      y: a.z * b.x - a.x * b.z,
      z: a.x * b.y - a.y * b.x
    };
  }
}

/**
 * Navball Display
 * Renders attitude reference display (ASCII art)
 */
export class NavballDisplay {
  private readonly GRID_SIZE = 9;

  render(
    attitude: Quaternion,
    velocity: Vector3,
    targetDirection?: Vector3
  ): string {
    const euler = this.quaternionToEuler(attitude);
    const pitch = euler.pitch * 180 / Math.PI;
    const roll = euler.roll * 180 / Math.PI;
    const yaw = euler.yaw * 180 / Math.PI;

    // Render navball grid
    let display = '\n';
    display += '        N (0°)\n';
    display += '    NW  ↑  NE\n';
    display += '  W ← [◉] → E\n';
    display += '    SW  ↓  SE\n';
    display += '        S (180°)\n\n';

    // Add marker legend
    display += 'Markers:\n';
    display += '  ⊕ Prograde (direction of motion)\n';
    display += '  ⊗ Retrograde (opposite motion)\n';

    if (targetDirection) {
      display += '  ◎ Target\n';
    }

    display += '\n';
    display += `Attitude:\n`;
    display += `  Pitch: ${pitch.toFixed(1)}°\n`;
    display += `  Roll:  ${roll.toFixed(1)}°\n`;
    display += `  Yaw:   ${yaw.toFixed(1)}°\n`;

    return display;
  }

  private quaternionToEuler(q: Quaternion): { pitch: number; roll: number; yaw: number } {
    const sinr_cosp = 2 * (q.w * q.x + q.y * q.z);
    const cosr_cosp = 1 - 2 * (q.x * q.x + q.y * q.y);
    const roll = Math.atan2(sinr_cosp, cosr_cosp);

    const sinp = 2 * (q.w * q.y - q.z * q.x);
    const pitch = Math.abs(sinp) >= 1 ? Math.sign(sinp) * Math.PI / 2 : Math.asin(sinp);

    const siny_cosp = 2 * (q.w * q.z + q.x * q.y);
    const cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z);
    const yaw = Math.atan2(siny_cosp, cosy_cosp);

    return { pitch, roll, yaw };
  }
}

/**
 * Navigation System
 * Main integration point for all navigation subsystems
 */
export class NavigationSystem {
  private predictor: TrajectoryPredictor;
  private suicideBurn: SuicideBurnCalculator;
  private velocityDecomp: VelocityDecomposer;
  private navball: NavballDisplay;

  private targetPosition: Vector3 | null = null;

  private readonly MOON_MASS = 7.342e22;
  private readonly MOON_RADIUS = 1737400;
  private readonly G = 6.674e-11;

  constructor() {
    this.predictor = new TrajectoryPredictor();
    this.suicideBurn = new SuicideBurnCalculator();
    this.velocityDecomp = new VelocityDecomposer();
    this.navball = new NavballDisplay();
  }

  setTarget(position: Vector3): void {
    this.targetPosition = position;
  }

  clearTarget(): void {
    this.targetPosition = null;
  }

  getTelemetry(
    position: Vector3,
    velocity: Vector3,
    attitude: Quaternion,
    mass: number,
    thrust: number,
    thrustDirection: Vector3,
    throttle: number,
    fuelMass: number,
    fuelCapacity: number,
    specificImpulse: number
  ): FlightTelemetry {
    // Position & Velocity
    const altitude = this.magnitude(position) - this.MOON_RADIUS;
    const radarAltitude = altitude;  // Simplified - same as orbital for now

    const velBreakdown = this.velocityDecomp.decompose(velocity, position);

    // Trajectory
    const impact = this.predictor.predict(position, velocity, mass, thrust, thrustDirection, 500);
    const suicideBurnData = this.suicideBurn.calculate(
      altitude,
      velBreakdown.vertical,
      mass,
      thrust > 0 ? thrust / throttle : 0  // Max thrust
    );

    // Attitude
    const euler = this.quaternionToEuler(attitude);
    const pitch = euler.pitch * 180 / Math.PI;
    const roll = euler.roll * 180 / Math.PI;
    const yaw = euler.yaw * 180 / Math.PI;
    const heading = (yaw + 360) % 360;

    // Angle from vertical
    const verticalDir = this.normalize(position);
    const thrustDir = this.rotateVector(thrustDirection, attitude);
    const angleFromVertical = Math.acos(this.dot(thrustDir, verticalDir)) * 180 / Math.PI;

    // Propulsion
    const gravity = this.G * this.MOON_MASS / (this.magnitude(position) ** 2);
    const twr = mass > 0 ? thrust / (mass * gravity) : 0;

    // Resources
    const fuelPercent = fuelCapacity > 0 ? (fuelMass / fuelCapacity) * 100 : 0;
    const massFlowRate = thrust > 0 ? thrust / (specificImpulse * 9.80665) : 0;
    const estimatedBurnTime = massFlowRate > 0 ? fuelMass / massFlowRate : Infinity;
    const deltaVRemaining = mass > 0 ?
      specificImpulse * 9.80665 * Math.log(mass / (mass - fuelMass)) : 0;

    // Navigation to target
    let distanceToTarget = null;
    let bearingToTarget = null;

    if (this.targetPosition) {
      const toTarget = {
        x: this.targetPosition.x - position.x,
        y: this.targetPosition.y - position.y,
        z: this.targetPosition.z - position.z
      };
      distanceToTarget = this.magnitude(toTarget);
      bearingToTarget = Math.atan2(toTarget.y, toTarget.x) * 180 / Math.PI;
    }

    return {
      altitude,
      radarAltitude,
      verticalSpeed: velBreakdown.vertical,
      horizontalSpeed: velBreakdown.horizontal,
      totalSpeed: velBreakdown.total,

      timeToImpact: impact.impactTime,
      impactSpeed: impact.impactSpeed,
      impactCoordinates: impact.coordinates,
      suicideBurnAltitude: suicideBurnData.burnAltitude,
      timeToSuicideBurn: suicideBurnData.timeUntilBurn,

      pitch,
      roll,
      yaw,
      heading,
      angleFromVertical,

      thrust,
      throttle,
      twr,

      fuelRemaining: fuelMass,
      fuelRemainingPercent: fuelPercent,
      estimatedBurnTime,
      deltaVRemaining,

      distanceToTarget,
      bearingToTarget
    };
  }

  renderNavball(attitude: Quaternion, velocity: Vector3): string {
    return this.navball.render(attitude, velocity, this.targetPosition || undefined);
  }

  predictImpact(
    position: Vector3,
    velocity: Vector3,
    mass: number,
    thrust: number,
    thrustDirection: Vector3
  ): ImpactPrediction {
    return this.predictor.predict(position, velocity, mass, thrust, thrustDirection);
  }

  calculateSuicideBurn(
    altitude: number,
    verticalSpeed: number,
    mass: number,
    maxThrust: number
  ): SuicideBurnData {
    return this.suicideBurn.calculate(altitude, verticalSpeed, mass, maxThrust);
  }

  decomposeVelocity(velocity: Vector3, position: Vector3): VelocityBreakdown {
    return this.velocityDecomp.decompose(velocity, position);
  }

  private magnitude(v: Vector3): number {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  }

  private normalize(v: Vector3): Vector3 {
    const mag = this.magnitude(v);
    if (mag < 1e-10) return { x: 0, y: 0, z: 1 };
    return { x: v.x / mag, y: v.y / mag, z: v.z / mag };
  }

  private dot(a: Vector3, b: Vector3): number {
    return a.x * b.x + a.y * b.y + a.z * b.z;
  }

  private rotateVector(v: Vector3, q: Quaternion): Vector3 {
    // Rotate vector by quaternion: v' = q * v * q^(-1)
    const qv = { w: 0, x: v.x, y: v.y, z: v.z };
    const qInv = { w: q.w, x: -q.x, y: -q.y, z: -q.z };

    const temp = this.quaternionMultiply(q, qv);
    const result = this.quaternionMultiply(temp, qInv);

    return { x: result.x, y: result.y, z: result.z };
  }

  private quaternionMultiply(a: Quaternion, b: Quaternion): Quaternion {
    return {
      w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
      x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
      y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
      z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
    };
  }

  private quaternionToEuler(q: Quaternion): { pitch: number; roll: number; yaw: number } {
    const sinr_cosp = 2 * (q.w * q.x + q.y * q.z);
    const cosr_cosp = 1 - 2 * (q.x * q.x + q.y * q.y);
    const roll = Math.atan2(sinr_cosp, cosr_cosp);

    const sinp = 2 * (q.w * q.y - q.z * q.x);
    const pitch = Math.abs(sinp) >= 1 ? Math.sign(sinp) * Math.PI / 2 : Math.asin(sinp);

    const siny_cosp = 2 * (q.w * q.z + q.x * q.y);
    const cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z);
    const yaw = Math.atan2(siny_cosp, cosy_cosp);

    return { pitch, roll, yaw };
  }
}
