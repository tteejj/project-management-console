/**
 * Ship Physics Core Module
 *
 * Integrates:
 * - Orbital mechanics (position, velocity in 3D space)
 * - Rotational dynamics (attitude, angular velocity, moment of inertia)
 * - Gravitational acceleration (inverse square law)
 * - Thrust from main engine (with gimbal)
 * - Torque from RCS and main engine gimbal
 * - Mass tracking (dry mass + propellant)
 * - Quaternion-based rotation (no gimbal lock)
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

export interface ShipState {
  // Position and velocity (inertial frame)
  position: Vector3;        // meters from planet center
  velocity: Vector3;        // m/s

  // Rotation and angular velocity (body frame)
  attitude: Quaternion;     // orientation quaternion
  angularVelocity: Vector3; // rad/s in body frame

  // Mass
  dryMass: number;          // kg (empty ship)
  propellantMass: number;   // kg (fuel + oxidizer)
}

export interface ShipConfig {
  dryMass?: number;                 // kg
  initialPropellantMass?: number;   // kg
  momentOfInertia?: Vector3;        // kg·m² (Ix, Iy, Iz)
  planetMass?: number;              // kg (for gravity)
  planetRadius?: number;            // m
  initialPosition?: Vector3;
  initialVelocity?: Vector3;
  initialAttitude?: Quaternion;
  dragCoefficient?: number;         // Dimensionless (0.5-2.0 typical)
  crossSectionalArea?: number;      // m² (frontal area)
  atmosphericScaleHeight?: number;  // m (atmosphere decay constant)
  seaLevelDensity?: number;         // kg/m³ (atmospheric density at surface)
  hasAtmosphere?: boolean;          // Does planet have atmosphere?
}

export class ShipPhysics {
  // State
  public position: Vector3;
  public velocity: Vector3;
  public attitude: Quaternion;
  public angularVelocity: Vector3;
  public dryMass: number;
  public propellantMass: number;

  // Configuration
  public momentOfInertia: Vector3;  // Principal moments (Ix, Iy, Iz)
  public planetMass: number;
  public planetRadius: number;

  // Atmospheric properties
  public dragCoefficient: number;
  public crossSectionalArea: number;
  public atmosphericScaleHeight: number;
  public seaLevelDensity: number;
  public hasAtmosphere: boolean;

  // Tracking
  public simulationTime: number = 0;
  public events: Array<{ time: number; type: string; data: any }> = [];
  public totalDragEnergy: number = 0;  // J (cumulative drag energy dissipated)
  public peakGForce: number = 0;       // Maximum G-force experienced

  // Constants
  private readonly G = 6.67430e-11;  // Gravitational constant m³/(kg·s²)

  constructor(config?: ShipConfig) {
    this.dryMass = config?.dryMass || 5000;  // 5 metric tons dry
    this.propellantMass = config?.initialPropellantMass || 3000;  // 3 tons propellant

    this.momentOfInertia = config?.momentOfInertia || { x: 2000, y: 2000, z: 500 };  // kg·m²

    // Moon parameters (default)
    this.planetMass = config?.planetMass || 7.342e22;      // kg (Moon)
    this.planetRadius = config?.planetRadius || 1737400;   // m (Moon)

    // Atmospheric parameters (Moon has no atmosphere by default)
    this.hasAtmosphere = config?.hasAtmosphere ?? false;
    this.dragCoefficient = config?.dragCoefficient || 2.0;  // Blunt body
    this.crossSectionalArea = config?.crossSectionalArea || 10;  // m² (10m² frontal area)
    this.atmosphericScaleHeight = config?.atmosphericScaleHeight || 8500;  // m (Earth-like if atmosphere exists)
    this.seaLevelDensity = config?.seaLevelDensity || 1.225;  // kg/m³ (Earth sea level)

    // Initial state
    this.position = config?.initialPosition || { x: 0, y: 0, z: this.planetRadius + 15000 };  // 15km altitude
    this.velocity = config?.initialVelocity || { x: 0, y: 0, z: 0 };

    this.attitude = config?.initialAttitude || { w: 1, x: 0, y: 0, z: 0 };  // Identity quaternion
    this.angularVelocity = { x: 0, y: 0, z: 0 };
  }

  /**
   * Main physics update
   */
  update(
    dt: number,
    mainEngineThrust: Vector3,      // N in body frame
    mainEngineTorque: Vector3,      // N·m from gimbal
    rcsThrust: Vector3,             // N in body frame
    rcsTorque: Vector3,             // N·m from RCS
    propellantConsumed: number      // kg consumed this timestep
  ): void {

    // 1. Update mass
    this.propellantMass = Math.max(0, this.propellantMass - propellantConsumed);

    // 2. Calculate total mass
    const totalMass = this.getTotalMass();

    // 3. Combine thrust forces (in body frame)
    const totalThrustBody = this.addVectors(mainEngineThrust, rcsThrust);

    // 4. Rotate thrust to inertial frame
    const totalThrustInertial = this.rotateVector(totalThrustBody, this.attitude);

    // 5. Calculate gravity (inertial frame)
    const gravity = this.calculateGravity();

    // 5.5. Calculate atmospheric drag (if atmosphere exists)
    const drag = this.calculateDrag();

    // 5.6. Calculate tidal forces (if significant)
    const tidalForce = this.calculateTidalForce();

    // 6. Total acceleration (inertial frame)
    const thrustAccel = this.scaleVector(totalThrustInertial, 1 / totalMass);
    const dragAccel = this.scaleVector(drag, 1 / totalMass);
    const tidalAccel = this.scaleVector(tidalForce, 1 / totalMass);

    let totalAccel = this.addVectors(thrustAccel, gravity);
    totalAccel = this.addVectors(totalAccel, dragAccel);
    totalAccel = this.addVectors(totalAccel, tidalAccel);

    // 6.5. Track G-forces
    this.trackGForces(totalAccel);

    // 7. Update velocity and position (inertial frame)
    const deltaV = this.scaleVector(totalAccel, dt);
    this.velocity = this.addVectors(this.velocity, deltaV);
    this.position = this.addVectors(this.position, this.scaleVector(this.velocity, dt));

    // 7.5. Track drag energy dissipation
    if (this.hasAtmosphere) {
      const dragMag = this.vectorMagnitude(drag);
      const speedChange = this.vectorMagnitude(deltaV);
      this.totalDragEnergy += dragMag * speedChange * totalMass;  // E = F * d
    }

    // 8. Rotational dynamics (body frame)
    this.updateRotation(dt, mainEngineTorque, rcsTorque);

    // 9. Update simulation time
    this.simulationTime += dt;

    // 10. Check for events
    this.checkEvents();
  }

  /**
   * Update rotational motion
   * Uses Euler's rotation equations: I·ω̇ = τ - ω × (I·ω)
   */
  private updateRotation(dt: number, mainEngineTorque: Vector3, rcsTorque: Vector3): void {
    const I = this.momentOfInertia;
    const ω = this.angularVelocity;

    // Total torque
    const totalTorque = this.addVectors(mainEngineTorque, rcsTorque);

    // I·ω
    const Iω = {
      x: I.x * ω.x,
      y: I.y * ω.y,
      z: I.z * ω.z
    };

    // ω × (I·ω)
    const gyroscopic = this.crossProduct(ω, Iω);

    // τ - ω × (I·ω)
    const netTorque = this.subtractVectors(totalTorque, gyroscopic);

    // ω̇ = (τ - ω × (I·ω)) / I
    const angularAccel = {
      x: netTorque.x / I.x,
      y: netTorque.y / I.y,
      z: netTorque.z / I.z
    };

    // Update angular velocity
    this.angularVelocity = this.addVectors(
      this.angularVelocity,
      this.scaleVector(angularAccel, dt)
    );

    // Update attitude quaternion
    this.integrateQuaternion(dt);

    // Normalize quaternion to prevent drift
    this.normalizeQuaternion();
  }

  /**
   * Integrate quaternion based on angular velocity
   * q̇ = 0.5 * q * ω
   */
  private integrateQuaternion(dt: number): void {
    const q = this.attitude;
    const ω = this.angularVelocity;

    // Quaternion derivative: q̇ = 0.5 * q * [0, ω]
    const ωQuat = { w: 0, x: ω.x, y: ω.y, z: ω.z };
    const qDot = this.multiplyQuaternions(q, ωQuat);

    // Scale by 0.5
    qDot.w *= 0.5;
    qDot.x *= 0.5;
    qDot.y *= 0.5;
    qDot.z *= 0.5;

    // Integrate: q_new = q + q̇ * dt
    this.attitude.w += qDot.w * dt;
    this.attitude.x += qDot.x * dt;
    this.attitude.y += qDot.y * dt;
    this.attitude.z += qDot.z * dt;
  }

  /**
   * Calculate gravitational acceleration
   * g = -G * M / r² * r̂
   */
  private calculateGravity(): Vector3 {
    const r = this.getAltitude() + this.planetRadius;  // Distance from center
    const rMag = this.vectorMagnitude(this.position);

    if (rMag < 1) return { x: 0, y: 0, z: 0 };  // Avoid division by zero

    const gMag = -this.G * this.planetMass / (rMag * rMag);

    // Direction: toward planet center (negative position vector)
    const rHat = this.scaleVector(this.position, 1 / rMag);

    return this.scaleVector(rHat, gMag);
  }

  /**
   * Calculate atmospheric drag force
   * F_drag = -0.5 * ρ * v² * C_d * A * v̂
   *
   * Where:
   * - ρ = atmospheric density (kg/m³) - exponential decay with altitude
   * - v = velocity magnitude (m/s)
   * - C_d = drag coefficient (dimensionless)
   * - A = cross-sectional area (m²)
   * - v̂ = velocity unit vector (direction)
   */
  private calculateDrag(): Vector3 {
    if (!this.hasAtmosphere) return { x: 0, y: 0, z: 0 };

    const altitude = this.getAltitude();
    if (altitude < 0) return { x: 0, y: 0, z: 0 };  // Below surface

    // Atmospheric density: ρ(h) = ρ₀ * e^(-h/H)
    // Where H is scale height (8500m for Earth)
    const density = this.seaLevelDensity * Math.exp(-altitude / this.atmosphericScaleHeight);

    // Velocity magnitude
    const speed = this.getSpeed();
    if (speed < 0.1) return { x: 0, y: 0, z: 0 };  // Negligible drag at very low speeds

    // Drag force magnitude: F = 0.5 * ρ * v² * C_d * A
    const dragMagnitude = 0.5 * density * speed * speed * this.dragCoefficient * this.crossSectionalArea;

    // Drag direction: opposite to velocity
    const velocityDirection = this.scaleVector(this.velocity, 1 / speed);
    const dragForce = this.scaleVector(velocityDirection, -dragMagnitude);

    return dragForce;
  }

  /**
   * Calculate tidal forces (gradient of gravity field)
   *
   * Tidal force creates differential acceleration across the ship's extent.
   * F_tidal ≈ 2 * G * M * d / r³
   *
   * Where:
   * - d = characteristic ship dimension (~10m)
   * - r = distance from planet center
   *
   * This is typically very small except near massive bodies or black holes.
   */
  private calculateTidalForce(): Vector3 {
    const rMag = this.vectorMagnitude(this.position);
    if (rMag < 1) return { x: 0, y: 0, z: 0 };

    // Characteristic ship dimension (assume 10m)
    const shipSize = 10;  // meters

    // Tidal force magnitude: F_tidal = 2 * G * M * d / r³
    const tidalMag = 2 * this.G * this.planetMass * shipSize / (rMag * rMag * rMag);

    // Direction: radial (along position vector)
    const rHat = this.scaleVector(this.position, 1 / rMag);

    // Tidal forces stretch the ship radially
    const tidalForce = this.scaleVector(rHat, tidalMag);

    return tidalForce;
  }

  /**
   * Track G-forces experienced by the ship
   *
   * G-force = |a_total| / g₀
   * where g₀ = 9.81 m/s² (Earth surface gravity, standard)
   */
  private trackGForces(acceleration: Vector3): void {
    const accelMag = this.vectorMagnitude(acceleration);
    const gForce = accelMag / 9.81;  // Convert to G's

    if (gForce > this.peakGForce) {
      this.peakGForce = gForce;
    }

    // Log high-G events
    if (gForce > 5.0) {
      this.logEvent(this.simulationTime, 'high_g_force', {
        gForce: gForce.toFixed(2),
        acceleration: accelMag.toFixed(2)
      });
    }
  }

  /**
   * Get altitude above surface
   */
  getAltitude(): number {
    const r = this.vectorMagnitude(this.position);
    return r - this.planetRadius;
  }

  /**
   * Get local gravity magnitude at current position
   * Returns scalar value in m/s²
   */
  getLocalGravity(): number {
    const rMag = this.vectorMagnitude(this.position);
    if (rMag < 1) return 0;  // Avoid division by zero
    return this.G * this.planetMass / (rMag * rMag);
  }

  /**
   * Get atmospheric density at current altitude
   * ρ(h) = ρ₀ * e^(-h/H)
   */
  getAtmosphericDensity(): number {
    if (!this.hasAtmosphere) return 0;

    const altitude = this.getAltitude();
    if (altitude < 0) return this.seaLevelDensity;  // At or below surface

    return this.seaLevelDensity * Math.exp(-altitude / this.atmosphericScaleHeight);
  }

  /**
   * Get current G-force magnitude
   * Based on last calculated acceleration
   */
  getCurrentGForce(): number {
    return this.peakGForce;
  }

  /**
   * Get dynamic pressure (q)
   * q = 0.5 * ρ * v²
   * Used for aerodynamic load calculations
   */
  getDynamicPressure(): number {
    const density = this.getAtmosphericDensity();
    const speed = this.getSpeed();
    return 0.5 * density * speed * speed;
  }

  /**
   * Get Mach number (approximate)
   * Assumes speed of sound ~340 m/s at sea level, varies with altitude
   */
  getMachNumber(): number {
    if (!this.hasAtmosphere) return 0;

    const altitude = this.getAltitude();
    // Speed of sound decreases with altitude (simplified model)
    const speedOfSound = 340 * Math.sqrt(Math.max(0.2, 1 - altitude / 50000));
    const speed = this.getSpeed();

    return speed / speedOfSound;
  }

  /**
   * Get total mass
   */
  getTotalMass(): number {
    return this.dryMass + this.propellantMass;
  }

  /**
   * Get speed (magnitude of velocity)
   */
  getSpeed(): number {
    return this.vectorMagnitude(this.velocity);
  }

  /**
   * Get vertical speed (radial component of velocity)
   */
  getVerticalSpeed(): number {
    // Project velocity onto position vector
    const rMag = this.vectorMagnitude(this.position);
    if (rMag < 1) return 0;

    const rHat = this.scaleVector(this.position, 1 / rMag);
    return this.dotProduct(this.velocity, rHat);
  }

  /**
   * Get surface-relative velocity (accounts for rotation)
   */
  getSurfaceRelativeVelocity(): Vector3 {
    // For now, assume non-rotating frame (Moon rotates slowly)
    return this.velocity;
  }

  /**
   * Convert quaternion to Euler angles (roll, pitch, yaw in degrees)
   */
  getEulerAngles(): { roll: number; pitch: number; yaw: number } {
    const q = this.attitude;

    // Roll (x-axis rotation)
    const sinr_cosp = 2 * (q.w * q.x + q.y * q.z);
    const cosr_cosp = 1 - 2 * (q.x * q.x + q.y * q.y);
    const roll = Math.atan2(sinr_cosp, cosr_cosp);

    // Pitch (y-axis rotation)
    const sinp = 2 * (q.w * q.y - q.z * q.x);
    const pitch = Math.abs(sinp) >= 1
      ? Math.sign(sinp) * Math.PI / 2  // Use 90 degrees if out of range
      : Math.asin(sinp);

    // Yaw (z-axis rotation)
    const siny_cosp = 2 * (q.w * q.z + q.x * q.y);
    const cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z);
    const yaw = Math.atan2(siny_cosp, cosy_cosp);

    // Convert to degrees
    return {
      roll: roll * 180 / Math.PI,
      pitch: pitch * 180 / Math.PI,
      yaw: yaw * 180 / Math.PI
    };
  }

  /**
   * Check for events
   */
  private checkEvents(): void {
    const altitude = this.getAltitude();

    // Ground impact
    if (altitude <= 0) {
      const speed = this.getSpeed();
      this.logEvent(this.simulationTime, 'ground_impact', {
        speed,
        verticalSpeed: this.getVerticalSpeed()
      });
    }

    // Low altitude warning
    if (altitude > 0 && altitude < 100) {
      this.logEvent(this.simulationTime, 'low_altitude', {
        altitude
      });
    }
  }

  /**
   * Consume propellant
   */
  consumePropellant(massKg: number): void {
    this.propellantMass = Math.max(0, this.propellantMass - massKg);
  }

  // ========== Vector/Quaternion Math ==========

  private addVectors(a: Vector3, b: Vector3): Vector3 {
    return { x: a.x + b.x, y: a.y + b.y, z: a.z + b.z };
  }

  private subtractVectors(a: Vector3, b: Vector3): Vector3 {
    return { x: a.x - b.x, y: a.y - b.y, z: a.z - b.z };
  }

  private scaleVector(v: Vector3, s: number): Vector3 {
    return { x: v.x * s, y: v.y * s, z: v.z * s };
  }

  private dotProduct(a: Vector3, b: Vector3): number {
    return a.x * b.x + a.y * b.y + a.z * b.z;
  }

  private crossProduct(a: Vector3, b: Vector3): Vector3 {
    return {
      x: a.y * b.z - a.z * b.y,
      y: a.z * b.x - a.x * b.z,
      z: a.x * b.y - a.y * b.x
    };
  }

  private vectorMagnitude(v: Vector3): number {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  }

  /**
   * Rotate vector from body frame to inertial frame using quaternion
   */
  private rotateVector(v: Vector3, q: Quaternion): Vector3 {
    // v' = q * v * q^(-1)
    const vQuat = { w: 0, x: v.x, y: v.y, z: v.z };
    const qConj = this.conjugateQuaternion(q);

    const temp = this.multiplyQuaternions(q, vQuat);
    const result = this.multiplyQuaternions(temp, qConj);

    return { x: result.x, y: result.y, z: result.z };
  }

  private multiplyQuaternions(a: Quaternion, b: Quaternion): Quaternion {
    return {
      w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
      x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
      y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
      z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
    };
  }

  private conjugateQuaternion(q: Quaternion): Quaternion {
    return { w: q.w, x: -q.x, y: -q.y, z: -q.z };
  }

  private normalizeQuaternion(): void {
    const q = this.attitude;
    const mag = Math.sqrt(q.w * q.w + q.x * q.x + q.y * q.y + q.z * q.z);

    if (mag > 0.001) {
      this.attitude.w /= mag;
      this.attitude.x /= mag;
      this.attitude.y /= mag;
      this.attitude.z /= mag;
    } else {
      // Reset to identity if degenerate
      this.attitude = { w: 1, x: 0, y: 0, z: 0 };
    }
  }

  /**
   * Get current state
   */
  getState() {
    const euler = this.getEulerAngles();

    return {
      position: { ...this.position },
      velocity: { ...this.velocity },
      altitude: this.getAltitude(),
      speed: this.getSpeed(),
      verticalSpeed: this.getVerticalSpeed(),
      attitude: { ...this.attitude },
      eulerAngles: euler,
      angularVelocity: { ...this.angularVelocity },
      dryMass: this.dryMass,
      propellantMass: this.propellantMass,
      totalMass: this.getTotalMass(),
      simulationTime: this.simulationTime,
      // New physics data
      atmosphericDensity: this.getAtmosphericDensity(),
      dynamicPressure: this.getDynamicPressure(),
      machNumber: this.getMachNumber(),
      peakGForce: this.peakGForce,
      totalDragEnergy: this.totalDragEnergy
    };
  }

  /**
   * Log an event
   */
  private logEvent(time: number, type: string, data: any): void {
    // Only log each event type once per second to avoid spam
    const recentEvent = this.events.find(
      e => e.type === type && time - e.time < 1.0
    );

    if (!recentEvent) {
      this.events.push({ time, type, data });
    }
  }

  /**
   * Get all events
   */
  getEvents() {
    return this.events;
  }

  /**
   * Clear events
   */
  clearEvents(): void {
    this.events = [];
  }
}
