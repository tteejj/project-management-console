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
    position: Vector3;
    velocity: Vector3;
    attitude: Quaternion;
    angularVelocity: Vector3;
    dryMass: number;
    propellantMass: number;
}
export interface ShipConfig {
    dryMass?: number;
    initialPropellantMass?: number;
    momentOfInertia?: Vector3;
    planetMass?: number;
    planetRadius?: number;
    initialPosition?: Vector3;
    initialVelocity?: Vector3;
    initialAttitude?: Quaternion;
}
export declare class ShipPhysics {
    position: Vector3;
    velocity: Vector3;
    attitude: Quaternion;
    angularVelocity: Vector3;
    dryMass: number;
    propellantMass: number;
    momentOfInertia: Vector3;
    planetMass: number;
    planetRadius: number;
    surfaceElevation: number;
    simulationTime: number;
    events: Array<{
        time: number;
        type: string;
        data: any;
    }>;
    private readonly G;
    constructor(config?: ShipConfig);
    /**
     * Main physics update
     */
    update(dt: number, mainEngineThrust: Vector3, // N in body frame
    mainEngineTorque: Vector3, // N·m from gimbal
    rcsThrust: Vector3, // N in body frame
    rcsTorque: Vector3, // N·m from RCS
    propellantConsumed: number): void;
    /**
     * Update rotational motion
     * Uses Euler's rotation equations: I·ω̇ = τ - ω × (I·ω)
     */
    private updateRotation;
    /**
     * Integrate quaternion based on angular velocity
     * q̇ = 0.5 * q * ω
     */
    private integrateQuaternion;
    /**
     * Calculate gravitational acceleration
     * g = -G * M / r² * r̂
     */
    private calculateGravity;
    /**
     * Get altitude above surface
     */
    getAltitude(): number;
    /**
     * Get local gravity magnitude at current position
     * Returns scalar value in m/s²
     */
    getLocalGravity(): number;
    /**
     * Get total mass
     */
    getTotalMass(): number;
    /**
     * Get speed (magnitude of velocity)
     */
    getSpeed(): number;
    /**
     * Get vertical speed (radial component of velocity)
     */
    getVerticalSpeed(): number;
    /**
     * Get surface-relative velocity (accounts for rotation)
     */
    getSurfaceRelativeVelocity(): Vector3;
    /**
     * Convert quaternion to Euler angles (roll, pitch, yaw in degrees)
     */
    getEulerAngles(): {
        roll: number;
        pitch: number;
        yaw: number;
    };
    /**
     * Set surface elevation at current position (for terrain collision)
     */
    setSurfaceElevation(elevation: number): void;
    /**
     * Check for events
     */
    private checkEvents;
    /**
     * Consume propellant
     */
    consumePropellant(massKg: number): void;
    private addVectors;
    private subtractVectors;
    private scaleVector;
    private dotProduct;
    private crossProduct;
    private vectorMagnitude;
    /**
     * Rotate vector from body frame to inertial frame using quaternion
     */
    private rotateVector;
    private multiplyQuaternions;
    private conjugateQuaternion;
    private normalizeQuaternion;
    /**
     * Get current state
     */
    getState(): {
        position: {
            x: number;
            y: number;
            z: number;
        };
        velocity: {
            x: number;
            y: number;
            z: number;
        };
        altitude: number;
        speed: number;
        verticalSpeed: number;
        attitude: {
            w: number;
            x: number;
            y: number;
            z: number;
        };
        eulerAngles: {
            roll: number;
            pitch: number;
            yaw: number;
        };
        angularVelocity: {
            x: number;
            y: number;
            z: number;
        };
        dryMass: number;
        propellantMass: number;
        totalMass: number;
        simulationTime: number;
    };
    /**
     * Log an event
     */
    private logEvent;
    /**
     * Get all events
     */
    getEvents(): {
        time: number;
        type: string;
        data: any;
    }[];
    /**
     * Clear events
     */
    clearEvents(): void;
}
//# sourceMappingURL=ship-physics.d.ts.map