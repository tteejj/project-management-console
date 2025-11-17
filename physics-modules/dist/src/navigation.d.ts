/**
 * Navigation System
 *
 * Provides trajectory prediction, navball display, velocity decomposition,
 * and enhanced telemetry for spacecraft navigation.
 */
import type { TerrainSystem } from './terrain-system';
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
    lat: number;
    lon: number;
}
export interface ImpactPrediction {
    impactTime: number;
    impactPosition: Vector3;
    impactVelocity: Vector3;
    impactSpeed: number;
    coordinates: LatLon;
    willImpact: boolean;
}
export interface SuicideBurnData {
    burnAltitude: number;
    currentAltitude: number;
    timeUntilBurn: number;
    shouldBurn: boolean;
    burnDuration: number;
    finalSpeed: number;
}
export interface VelocityBreakdown {
    total: number;
    vertical: number;
    horizontal: number;
    north: number;
    east: number;
    prograde: number;
    normal: number;
}
export interface FlightTelemetry {
    altitude: number;
    radarAltitude: number;
    verticalSpeed: number;
    horizontalSpeed: number;
    totalSpeed: number;
    timeToImpact: number;
    impactSpeed: number;
    impactCoordinates: LatLon;
    suicideBurnAltitude: number;
    timeToSuicideBurn: number;
    pitch: number;
    roll: number;
    yaw: number;
    heading: number;
    angleFromVertical: number;
    thrust: number;
    throttle: number;
    twr: number;
    fuelRemaining: number;
    fuelRemainingPercent: number;
    estimatedBurnTime: number;
    deltaVRemaining: number;
    distanceToTarget: number | null;
    bearingToTarget: number | null;
}
/**
 * Trajectory Predictor
 * Numerically integrates trajectory to predict impact point
 */
export declare class TrajectoryPredictor {
    private readonly MOON_MASS;
    private readonly MOON_RADIUS;
    private readonly G;
    predict(position: Vector3, velocity: Vector3, mass: number, thrust: number, thrustDirection: Vector3, // Unit vector
    maxSimTime?: number): ImpactPrediction;
    private calculateGravity;
    private getAltitude;
    private positionToLatLon;
    private magnitude;
}
/**
 * Suicide Burn Calculator
 * Calculates optimal deceleration burn parameters
 */
export declare class SuicideBurnCalculator {
    private readonly MOON_GRAVITY;
    calculate(altitude: number, verticalSpeed: number, mass: number, maxThrust: number, safetyFactor?: number): SuicideBurnData;
}
/**
 * Velocity Decomposer
 * Breaks down velocity into meaningful components
 */
export declare class VelocityDecomposer {
    decompose(velocity: Vector3, position: Vector3): VelocityBreakdown;
    private magnitude;
    private normalize;
    private dot;
    private crossProduct;
}
/**
 * Navball Display
 * Renders attitude reference display (ASCII art)
 */
export declare class NavballDisplay {
    private readonly GRID_SIZE;
    render(attitude: Quaternion, velocity: Vector3, targetDirection?: Vector3): string;
    private quaternionToEuler;
}
/**
 * Navigation System
 * Main integration point for all navigation subsystems
 */
export declare class NavigationSystem {
    private predictor;
    private suicideBurn;
    private velocityDecomp;
    private navball;
    private terrain;
    private targetPosition;
    private readonly MOON_MASS;
    private readonly MOON_RADIUS;
    private readonly G;
    constructor(terrain?: TerrainSystem);
    /**
     * Set terrain system for realistic radar altitude calculations
     */
    setTerrain(terrain: TerrainSystem): void;
    setTarget(position: Vector3): void;
    clearTarget(): void;
    getTelemetry(position: Vector3, velocity: Vector3, attitude: Quaternion, mass: number, thrust: number, thrustDirection: Vector3, throttle: number, fuelMass: number, fuelCapacity: number, specificImpulse: number): FlightTelemetry;
    renderNavball(attitude: Quaternion, velocity: Vector3): string;
    predictImpact(position: Vector3, velocity: Vector3, mass: number, thrust: number, thrustDirection: Vector3): ImpactPrediction;
    calculateSuicideBurn(altitude: number, verticalSpeed: number, mass: number, maxThrust: number): SuicideBurnData;
    decomposeVelocity(velocity: Vector3, position: Vector3): VelocityBreakdown;
    private magnitude;
    private normalize;
    private dot;
    private rotateVector;
    private quaternionMultiply;
    private quaternionToEuler;
}
//# sourceMappingURL=navigation.d.ts.map