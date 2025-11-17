/**
 * Targeting and Intercept Planning System
 *
 * Handles lead calculations, intercept trajectories, and rendezvous planning
 * NO RENDERING - physics only
 */

import { Vector3, VectorMath, G } from './math-utils';
import { World, CelestialBody } from './world';

export enum InterceptType {
  BALLISTIC = 'ballistic',        // Simple ballistic intercept
  ORBITAL = 'orbital',            // Orbital transfer
  PURSUIT = 'pursuit'             // Pursuit course (continuous burn)
}

export interface LeadParams {
  shooterPosition: Vector3;
  shooterVelocity: Vector3;
  targetPosition: Vector3;
  targetVelocity: Vector3;
  projectileSpeed: number;
}

export interface LeadSolution {
  aimPoint: Vector3;              // Where to aim
  leadAngle: number;              // Angular lead in radians
  timeToImpact: number;           // seconds
  relativeVelocity: Vector3;      // Relative velocity at impact
}

export interface RendezvousParams {
  shipPosition: Vector3;
  shipVelocity: Vector3;
  targetPosition: Vector3;
  targetVelocity: Vector3;
  maxDeltaV: number;              // Maximum deltaV budget (m/s)
}

export interface Maneuver {
  time: number;                   // Time to execute (seconds from now)
  deltaV: Vector3;                // Velocity change vector
  duration: number;               // Burn duration (seconds)
}

export interface RendezvousSolution {
  maneuvers: Maneuver[];
  transferTime: number;           // Total transfer time (seconds)
  deltaVBudget: number;           // Total deltaV required (m/s)
  interceptPoint: Vector3;
}

export interface InterceptParams {
  shipPosition: Vector3;
  shipVelocity: Vector3;
  targetId: string;
  interceptType: InterceptType;
  projectileSpeed?: number;       // For ballistic intercepts
}

export interface InterceptSolution {
  aimDirection: Vector3;          // Unit vector to aim
  timeToIntercept: number;        // seconds
  interceptPoint: Vector3;
  deltaVRequired?: Vector3;       // For orbital/pursuit intercepts
}

export interface ClosestApproach {
  distance: number;               // Minimum distance (meters)
  time: number;                   // Time of closest approach (seconds)
  position1: Vector3;             // Ship position at closest approach
  position2: Vector3;             // Target position at closest approach
}

/**
 * Lead calculation for ballistic intercepts
 */
export class LeadCalculator {
  /**
   * Calculate lead angle and aim point for moving target
   * Solves: |target_pos + target_vel * t - shooter_pos| = projectile_speed * t
   */
  static calculateLead(params: LeadParams): LeadSolution | null {
    const {
      shooterPosition,
      shooterVelocity,
      targetPosition,
      targetVelocity,
      projectileSpeed
    } = params;

    if (projectileSpeed <= 0) return null;

    // Relative position and velocity
    const relPos = VectorMath.subtract(targetPosition, shooterPosition);
    const relVel = VectorMath.subtract(targetVelocity, shooterVelocity);

    // Quadratic equation coefficients for intercept time
    // |relPos + relVel * t| = projectileSpeed * t
    // (relPos + relVel * t) · (relPos + relVel * t) = (projectileSpeed * t)²

    const a = VectorMath.dot(relVel, relVel) - projectileSpeed * projectileSpeed;
    const b = 2 * VectorMath.dot(relPos, relVel);
    const c = VectorMath.dot(relPos, relPos);

    // Solve quadratic
    const discriminant = b * b - 4 * a * c;

    if (discriminant < 0) {
      // No solution - can't intercept
      // Fallback: aim at current position
      const distance = VectorMath.magnitude(relPos);
      return {
        aimPoint: targetPosition,
        leadAngle: 0,
        timeToImpact: distance / projectileSpeed,
        relativeVelocity: relVel
      };
    }

    // Take the smaller positive root (earliest intercept)
    const t1 = (-b - Math.sqrt(discriminant)) / (2 * a);
    const t2 = (-b + Math.sqrt(discriminant)) / (2 * a);

    let timeToImpact: number;
    if (t1 > 0) {
      timeToImpact = t1;
    } else if (t2 > 0) {
      timeToImpact = t2;
    } else {
      // Both negative - target moving away faster than projectile
      timeToImpact = Math.abs(t1) < Math.abs(t2) ? t1 : t2;
    }

    // Calculate aim point
    const aimPoint = VectorMath.add(
      targetPosition,
      VectorMath.scale(targetVelocity, timeToImpact)
    );

    // Calculate lead angle
    const toTarget = VectorMath.normalize(relPos);
    const toAimPoint = VectorMath.normalize(VectorMath.subtract(aimPoint, shooterPosition));
    const leadAngle = Math.acos(Math.max(-1, Math.min(1, VectorMath.dot(toTarget, toAimPoint))));

    return {
      aimPoint,
      leadAngle,
      timeToImpact: Math.abs(timeToImpact),
      relativeVelocity: relVel
    };
  }
}

/**
 * Rendezvous planning for orbital transfers
 */
export class RendezvousPlanner {
  private world: World;

  constructor(world: World) {
    this.world = world;
  }

  /**
   * Plan a rendezvous maneuver (simplified Hohmann transfer)
   */
  planRendezvous(params: RendezvousParams): RendezvousSolution | null {
    const {
      shipPosition,
      shipVelocity,
      targetPosition,
      targetVelocity,
      maxDeltaV
    } = params;

    // Calculate relative position and velocity
    const relPos = VectorMath.subtract(targetPosition, shipPosition);
    const relVel = VectorMath.subtract(targetVelocity, shipVelocity);

    // For simplified rendezvous, use a two-impulse maneuver
    // 1. Match velocity with target
    // 2. Translate to target position

    const maneuvers: Maneuver[] = [];

    // First maneuver: match orbital plane and velocity
    const deltaV1 = relVel;
    const deltaV1Mag = VectorMath.magnitude(deltaV1);

    if (deltaV1Mag > maxDeltaV) {
      return null;  // Exceeds deltaV budget
    }

    maneuvers.push({
      time: 0,
      deltaV: deltaV1,
      duration: deltaV1Mag / 10  // Assume 10 m/s² acceleration
    });

    // Second maneuver: translate to target (simplified)
    const distance = VectorMath.magnitude(relPos);
    const transferTime = distance / 100;  // Simplified: assume 100 m/s average velocity

    const deltaV2Direction = VectorMath.normalize(relPos);
    const deltaV2Mag = Math.min(100, distance / transferTime);  // Cap at 100 m/s

    if (deltaV1Mag + deltaV2Mag > maxDeltaV) {
      return null;  // Exceeds deltaV budget
    }

    const deltaV2 = VectorMath.scale(deltaV2Direction, deltaV2Mag);

    maneuvers.push({
      time: transferTime / 2,
      deltaV: deltaV2,
      duration: deltaV2Mag / 10
    });

    // Third maneuver: decelerate to match target
    maneuvers.push({
      time: transferTime,
      deltaV: VectorMath.scale(deltaV2, -1),
      duration: deltaV2Mag / 10
    });

    const totalDeltaV = deltaV1Mag + deltaV2Mag * 2;

    return {
      maneuvers,
      transferTime,
      deltaVBudget: totalDeltaV,
      interceptPoint: targetPosition
    };
  }
}

/**
 * Main targeting system
 */
export class TargetingSystem {
  private world: World;
  private targets: Map<string, CelestialBody> = new Map();
  private planner: RendezvousPlanner;

  constructor(world: World) {
    this.world = world;
    this.planner = new RendezvousPlanner(world);
  }

  /**
   * Find intercept solution for a target
   */
  findInterceptSolution(params: InterceptParams): InterceptSolution | null {
    const target = this.world.getBody(params.targetId);
    if (!target) return null;

    switch (params.interceptType) {
      case InterceptType.BALLISTIC: {
        if (!params.projectileSpeed) return null;

        const lead = LeadCalculator.calculateLead({
          shooterPosition: params.shipPosition,
          shooterVelocity: params.shipVelocity,
          targetPosition: target.position,
          targetVelocity: target.velocity,
          projectileSpeed: params.projectileSpeed
        });

        if (!lead) return null;

        const aimDirection = VectorMath.normalize(
          VectorMath.subtract(lead.aimPoint, params.shipPosition)
        );

        return {
          aimDirection,
          timeToIntercept: lead.timeToImpact,
          interceptPoint: lead.aimPoint
        };
      }

      case InterceptType.ORBITAL: {
        const rendezvous = this.planner.planRendezvous({
          shipPosition: params.shipPosition,
          shipVelocity: params.shipVelocity,
          targetPosition: target.position,
          targetVelocity: target.velocity,
          maxDeltaV: 1000  // Default budget
        });

        if (!rendezvous) return null;

        const firstManeuver = rendezvous.maneuvers[0];
        const aimDirection = VectorMath.normalize(firstManeuver.deltaV);

        return {
          aimDirection,
          timeToIntercept: rendezvous.transferTime,
          interceptPoint: rendezvous.interceptPoint,
          deltaVRequired: firstManeuver.deltaV
        };
      }

      case InterceptType.PURSUIT: {
        // Pursuit course: continuously accelerate toward target
        const toTarget = VectorMath.subtract(target.position, params.shipPosition);
        const aimDirection = VectorMath.normalize(toTarget);
        const distance = VectorMath.magnitude(toTarget);

        // Estimate time (simplified)
        const relVel = VectorMath.subtract(target.velocity, params.shipVelocity);
        const closingSpeed = -VectorMath.dot(relVel, aimDirection);
        const timeToIntercept = distance / Math.max(1, closingSpeed);

        return {
          aimDirection,
          timeToIntercept,
          interceptPoint: target.position
        };
      }
    }

    return null;
  }

  /**
   * Calculate closest approach between two objects on current trajectory
   */
  calculateClosestApproach(
    pos1: Vector3,
    vel1: Vector3,
    pos2: Vector3,
    vel2: Vector3
  ): ClosestApproach {
    const relPos = VectorMath.subtract(pos2, pos1);
    const relVel = VectorMath.subtract(vel2, vel1);

    // Time of closest approach: t = -(relPos · relVel) / |relVel|²
    const relVelSq = VectorMath.magnitudeSquared(relVel);

    let timeOfClosest: number;
    if (relVelSq < 1e-6) {
      // Stationary relative velocity - already at closest
      timeOfClosest = 0;
    } else {
      timeOfClosest = -VectorMath.dot(relPos, relVel) / relVelSq;
      timeOfClosest = Math.max(0, timeOfClosest);  // Can't go back in time
    }

    // Positions at closest approach
    const position1 = VectorMath.add(pos1, VectorMath.scale(vel1, timeOfClosest));
    const position2 = VectorMath.add(pos2, VectorMath.scale(vel2, timeOfClosest));

    const distance = VectorMath.distance(position1, position2);

    return {
      distance,
      time: timeOfClosest,
      position1,
      position2
    };
  }

  /**
   * Add a target to tracking
   */
  addTarget(id: string, target: CelestialBody): void {
    this.targets.set(id, target);
  }

  /**
   * Remove a target from tracking
   */
  removeTarget(id: string): void {
    this.targets.delete(id);
  }

  /**
   * Get a tracked target
   */
  getTarget(id: string): CelestialBody | undefined {
    return this.targets.get(id);
  }

  /**
   * Get all tracked targets
   */
  getAllTargets(): CelestialBody[] {
    return Array.from(this.targets.values());
  }

  /**
   * Update a tracked target
   */
  updateTarget(id: string, target: CelestialBody): void {
    this.targets.set(id, target);
  }
}
