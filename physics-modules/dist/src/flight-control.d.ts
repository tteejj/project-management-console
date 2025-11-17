/**
 * Flight Control System
 *
 * Provides autopilot, PID control, and stability augmentation for spacecraft.
 * Implements closed-loop control systems for automated flight operations.
 */
export type SASMode = 'off' | 'stability' | 'attitude_hold' | 'prograde' | 'retrograde' | 'radial_in' | 'radial_out' | 'normal' | 'anti_normal';
export type AutopilotMode = 'off' | 'altitude_hold' | 'vertical_speed_hold' | 'suicide_burn' | 'hover';
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
export interface PIDConfig {
    kp: number;
    ki: number;
    kd: number;
    integralLimit?: number;
}
export interface RCSCommands {
    pitch: number;
    roll: number;
    yaw: number;
}
export interface ThrottleCommand {
    throttle: number;
    reason: string;
}
export interface GimbalCommand {
    pitch: number;
    yaw: number;
}
export interface FlightControlConfig {
    pid: {
        altitude: PIDConfig;
        verticalSpeed: PIDConfig;
        pitch: PIDConfig;
        roll: PIDConfig;
        yaw: PIDConfig;
        rateDamping: PIDConfig;
    };
    sas: {
        deadband: number;
        rateDeadband: number;
        maxControlAuthority: number;
    };
    autopilot: {
        suicideBurnSafetyFactor: number;
        hoverThrottleMargin: number;
        altitudeHoldDeadband: number;
        speedHoldDeadband: number;
    };
}
export interface FlightControlState {
    sasMode: SASMode;
    autopilotMode: AutopilotMode;
    targetAltitude: number | null;
    targetVerticalSpeed: number | null;
    targetAttitude: Quaternion | null;
    suicideBurnActive: boolean;
    suicideBurnAltitude: number;
    hoverActive: boolean;
    rcsCommands: RCSCommands;
    throttleCommand: ThrottleCommand;
    gimbalCommand: GimbalCommand;
}
/**
 * PID Controller
 * Implements proportional-integral-derivative control
 */
export declare class PIDController {
    private kp;
    private ki;
    private kd;
    private integralLimit;
    private integral;
    private previousError;
    private firstUpdate;
    constructor(config: PIDConfig);
    update(currentValue: number, targetValue: number, dt: number): number;
    reset(): void;
    getIntegral(): number;
}
/**
 * Stability Augmentation System (SAS)
 * Provides attitude stabilization and automatic orientation control
 */
export declare class SASController {
    private mode;
    private config;
    private pitchPID;
    private rollPID;
    private yawPID;
    private pitchRatePID;
    private rollRatePID;
    private yawRatePID;
    constructor(config: FlightControlConfig);
    setMode(mode: SASMode): void;
    getMode(): SASMode;
    update(currentAttitude: Quaternion, currentAngularVel: Vector3, targetAttitude: Quaternion | null, velocity: Vector3, position: Vector3, dt: number): RCSCommands;
    private calculateRateDamping;
    private calculateProgradeAttitude;
    private calculateRetrogradeAttitude;
    private calculateRadialInAttitude;
    private calculateRadialOutAttitude;
    private vectorToQuaternion;
    private quaternionDifference;
    private quaternionInverse;
    private quaternionMultiply;
    private quaternionToEuler;
    private normalize;
    private crossProduct;
}
/**
 * Autopilot System
 * Provides automated throttle control for various flight modes
 */
export declare class AutopilotSystem {
    private mode;
    private config;
    private altitudePID;
    private verticalSpeedPID;
    private targetAltitude;
    private targetVerticalSpeed;
    private suicideBurnActive;
    private suicideBurnAltitude;
    constructor(config: FlightControlConfig);
    setMode(mode: AutopilotMode): void;
    getMode(): AutopilotMode;
    setTargetAltitude(altitude: number): void;
    setTargetVerticalSpeed(speed: number): void;
    update(altitude: number, verticalSpeed: number, mass: number, maxThrust: number, gravity: number, dt: number): ThrottleCommand;
    getSuicideBurnAltitude(): number;
    isSuicideBurnActive(): boolean;
    private updateAltitudeHold;
    private updateVerticalSpeedHold;
    private updateSuicideBurn;
    private updateHover;
}
/**
 * Gimbal Autopilot
 * Automatically vectors thrust to null horizontal velocity
 */
export declare class GimbalAutopilot {
    private enabled;
    private maxGimbalAngle;
    setEnabled(enabled: boolean): void;
    isEnabled(): boolean;
    update(velocity: Vector3, thrust: number, mass: number): GimbalCommand;
}
/**
 * Flight Control System
 * Main integration point for all flight control subsystems
 */
export declare class FlightControlSystem {
    private config;
    private sas;
    private autopilot;
    private gimbalAutopilot;
    constructor(config?: Partial<FlightControlConfig>);
    setSASMode(mode: SASMode): void;
    getSASMode(): SASMode;
    setAutopilotMode(mode: AutopilotMode): void;
    getAutopilotMode(): AutopilotMode;
    setTargetAltitude(altitude: number): void;
    setTargetVerticalSpeed(speed: number): void;
    setGimbalAutopilot(enabled: boolean): void;
    isGimbalAutopilotEnabled(): boolean;
    update(currentAttitude: Quaternion, currentAngularVel: Vector3, targetAttitude: Quaternion | null, velocity: Vector3, position: Vector3, altitude: number, verticalSpeed: number, mass: number, maxThrust: number, currentThrust: number, gravity: number, dt: number): FlightControlState;
    getState(): FlightControlState;
}
//# sourceMappingURL=flight-control.d.ts.map