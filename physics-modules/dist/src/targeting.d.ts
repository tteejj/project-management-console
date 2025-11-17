/**
 * Targeting and Intercept Planning System
 *
 * Handles lead calculations, intercept trajectories, and rendezvous planning
 * NO RENDERING - physics only
 */
import { Vector3 } from './math-utils';
import { World, CelestialBody } from './world';
export declare enum InterceptType {
    BALLISTIC = "ballistic",// Simple ballistic intercept
    ORBITAL = "orbital",// Orbital transfer
    PURSUIT = "pursuit"
}
export interface LeadParams {
    shooterPosition: Vector3;
    shooterVelocity: Vector3;
    targetPosition: Vector3;
    targetVelocity: Vector3;
    projectileSpeed: number;
}
export interface LeadSolution {
    aimPoint: Vector3;
    leadAngle: number;
    timeToImpact: number;
    relativeVelocity: Vector3;
}
export interface RendezvousParams {
    shipPosition: Vector3;
    shipVelocity: Vector3;
    targetPosition: Vector3;
    targetVelocity: Vector3;
    maxDeltaV: number;
}
export interface Maneuver {
    time: number;
    deltaV: Vector3;
    duration: number;
}
export interface RendezvousSolution {
    maneuvers: Maneuver[];
    transferTime: number;
    deltaVBudget: number;
    interceptPoint: Vector3;
}
export interface InterceptParams {
    shipPosition: Vector3;
    shipVelocity: Vector3;
    targetId: string;
    interceptType: InterceptType;
    projectileSpeed?: number;
}
export interface InterceptSolution {
    aimDirection: Vector3;
    timeToIntercept: number;
    interceptPoint: Vector3;
    deltaVRequired?: Vector3;
}
export interface ClosestApproach {
    distance: number;
    time: number;
    position1: Vector3;
    position2: Vector3;
}
/**
 * Lead calculation for ballistic intercepts
 */
export declare class LeadCalculator {
    /**
     * Calculate lead angle and aim point for moving target
     * Solves: |target_pos + target_vel * t - shooter_pos| = projectile_speed * t
     */
    static calculateLead(params: LeadParams): LeadSolution | null;
}
/**
 * Rendezvous planning for orbital transfers
 */
export declare class RendezvousPlanner {
    private world;
    constructor(world: World);
    /**
     * Plan a rendezvous maneuver (simplified Hohmann transfer)
     */
    planRendezvous(params: RendezvousParams): RendezvousSolution | null;
}
/**
 * Main targeting system
 */
export declare class TargetingSystem {
    private world;
    private targets;
    private planner;
    constructor(world: World);
    /**
     * Find intercept solution for a target
     */
    findInterceptSolution(params: InterceptParams): InterceptSolution | null;
    /**
     * Calculate closest approach between two objects on current trajectory
     */
    calculateClosestApproach(pos1: Vector3, vel1: Vector3, pos2: Vector3, vel2: Vector3): ClosestApproach;
    /**
     * Add a target to tracking
     */
    addTarget(id: string, target: CelestialBody): void;
    /**
     * Remove a target from tracking
     */
    removeTarget(id: string): void;
    /**
     * Get a tracked target
     */
    getTarget(id: string): CelestialBody | undefined;
    /**
     * Get all tracked targets
     */
    getAllTargets(): CelestialBody[];
    /**
     * Update a tracked target
     */
    updateTarget(id: string, target: CelestialBody): void;
}
//# sourceMappingURL=targeting.d.ts.map