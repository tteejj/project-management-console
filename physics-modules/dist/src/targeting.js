"use strict";
/**
 * Targeting and Intercept Planning System
 *
 * Handles lead calculations, intercept trajectories, and rendezvous planning
 * NO RENDERING - physics only
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.TargetingSystem = exports.RendezvousPlanner = exports.LeadCalculator = exports.InterceptType = void 0;
const math_utils_1 = require("./math-utils");
var InterceptType;
(function (InterceptType) {
    InterceptType["BALLISTIC"] = "ballistic";
    InterceptType["ORBITAL"] = "orbital";
    InterceptType["PURSUIT"] = "pursuit"; // Pursuit course (continuous burn)
})(InterceptType || (exports.InterceptType = InterceptType = {}));
/**
 * Lead calculation for ballistic intercepts
 */
class LeadCalculator {
    /**
     * Calculate lead angle and aim point for moving target
     * Solves: |target_pos + target_vel * t - shooter_pos| = projectile_speed * t
     */
    static calculateLead(params) {
        const { shooterPosition, shooterVelocity, targetPosition, targetVelocity, projectileSpeed } = params;
        if (projectileSpeed <= 0)
            return null;
        // Relative position and velocity
        const relPos = math_utils_1.VectorMath.subtract(targetPosition, shooterPosition);
        const relVel = math_utils_1.VectorMath.subtract(targetVelocity, shooterVelocity);
        // Quadratic equation coefficients for intercept time
        // |relPos + relVel * t| = projectileSpeed * t
        // (relPos + relVel * t) · (relPos + relVel * t) = (projectileSpeed * t)²
        const a = math_utils_1.VectorMath.dot(relVel, relVel) - projectileSpeed * projectileSpeed;
        const b = 2 * math_utils_1.VectorMath.dot(relPos, relVel);
        const c = math_utils_1.VectorMath.dot(relPos, relPos);
        // Solve quadratic
        const discriminant = b * b - 4 * a * c;
        if (discriminant < 0) {
            // No solution - can't intercept
            // Fallback: aim at current position
            const distance = math_utils_1.VectorMath.magnitude(relPos);
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
        let timeToImpact;
        if (t1 > 0) {
            timeToImpact = t1;
        }
        else if (t2 > 0) {
            timeToImpact = t2;
        }
        else {
            // Both negative - target moving away faster than projectile
            timeToImpact = Math.abs(t1) < Math.abs(t2) ? t1 : t2;
        }
        // Calculate aim point
        const aimPoint = math_utils_1.VectorMath.add(targetPosition, math_utils_1.VectorMath.scale(targetVelocity, timeToImpact));
        // Calculate lead angle
        const toTarget = math_utils_1.VectorMath.normalize(relPos);
        const toAimPoint = math_utils_1.VectorMath.normalize(math_utils_1.VectorMath.subtract(aimPoint, shooterPosition));
        const leadAngle = Math.acos(Math.max(-1, Math.min(1, math_utils_1.VectorMath.dot(toTarget, toAimPoint))));
        return {
            aimPoint,
            leadAngle,
            timeToImpact: Math.abs(timeToImpact),
            relativeVelocity: relVel
        };
    }
}
exports.LeadCalculator = LeadCalculator;
/**
 * Rendezvous planning for orbital transfers
 */
class RendezvousPlanner {
    constructor(world) {
        this.world = world;
    }
    /**
     * Plan a rendezvous maneuver (simplified Hohmann transfer)
     */
    planRendezvous(params) {
        const { shipPosition, shipVelocity, targetPosition, targetVelocity, maxDeltaV } = params;
        // Calculate relative position and velocity
        const relPos = math_utils_1.VectorMath.subtract(targetPosition, shipPosition);
        const relVel = math_utils_1.VectorMath.subtract(targetVelocity, shipVelocity);
        // For simplified rendezvous, use a two-impulse maneuver
        // 1. Match velocity with target
        // 2. Translate to target position
        const maneuvers = [];
        // First maneuver: match orbital plane and velocity
        const deltaV1 = relVel;
        const deltaV1Mag = math_utils_1.VectorMath.magnitude(deltaV1);
        if (deltaV1Mag > maxDeltaV) {
            return null; // Exceeds deltaV budget
        }
        maneuvers.push({
            time: 0,
            deltaV: deltaV1,
            duration: deltaV1Mag / 10 // Assume 10 m/s² acceleration
        });
        // Second maneuver: translate to target (simplified)
        const distance = math_utils_1.VectorMath.magnitude(relPos);
        const transferTime = distance / 100; // Simplified: assume 100 m/s average velocity
        const deltaV2Direction = math_utils_1.VectorMath.normalize(relPos);
        const deltaV2Mag = Math.min(100, distance / transferTime); // Cap at 100 m/s
        if (deltaV1Mag + deltaV2Mag > maxDeltaV) {
            return null; // Exceeds deltaV budget
        }
        const deltaV2 = math_utils_1.VectorMath.scale(deltaV2Direction, deltaV2Mag);
        maneuvers.push({
            time: transferTime / 2,
            deltaV: deltaV2,
            duration: deltaV2Mag / 10
        });
        // Third maneuver: decelerate to match target
        maneuvers.push({
            time: transferTime,
            deltaV: math_utils_1.VectorMath.scale(deltaV2, -1),
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
exports.RendezvousPlanner = RendezvousPlanner;
/**
 * Main targeting system
 */
class TargetingSystem {
    constructor(world) {
        this.targets = new Map();
        this.world = world;
        this.planner = new RendezvousPlanner(world);
    }
    /**
     * Find intercept solution for a target
     */
    findInterceptSolution(params) {
        const target = this.world.getBody(params.targetId);
        if (!target)
            return null;
        switch (params.interceptType) {
            case InterceptType.BALLISTIC: {
                if (!params.projectileSpeed)
                    return null;
                const lead = LeadCalculator.calculateLead({
                    shooterPosition: params.shipPosition,
                    shooterVelocity: params.shipVelocity,
                    targetPosition: target.position,
                    targetVelocity: target.velocity,
                    projectileSpeed: params.projectileSpeed
                });
                if (!lead)
                    return null;
                const aimDirection = math_utils_1.VectorMath.normalize(math_utils_1.VectorMath.subtract(lead.aimPoint, params.shipPosition));
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
                    maxDeltaV: 1000 // Default budget
                });
                if (!rendezvous)
                    return null;
                const firstManeuver = rendezvous.maneuvers[0];
                const aimDirection = math_utils_1.VectorMath.normalize(firstManeuver.deltaV);
                return {
                    aimDirection,
                    timeToIntercept: rendezvous.transferTime,
                    interceptPoint: rendezvous.interceptPoint,
                    deltaVRequired: firstManeuver.deltaV
                };
            }
            case InterceptType.PURSUIT: {
                // Pursuit course: continuously accelerate toward target
                const toTarget = math_utils_1.VectorMath.subtract(target.position, params.shipPosition);
                const aimDirection = math_utils_1.VectorMath.normalize(toTarget);
                const distance = math_utils_1.VectorMath.magnitude(toTarget);
                // Estimate time (simplified)
                const relVel = math_utils_1.VectorMath.subtract(target.velocity, params.shipVelocity);
                const closingSpeed = -math_utils_1.VectorMath.dot(relVel, aimDirection);
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
    calculateClosestApproach(pos1, vel1, pos2, vel2) {
        const relPos = math_utils_1.VectorMath.subtract(pos2, pos1);
        const relVel = math_utils_1.VectorMath.subtract(vel2, vel1);
        // Time of closest approach: t = -(relPos · relVel) / |relVel|²
        const relVelSq = math_utils_1.VectorMath.magnitudeSquared(relVel);
        let timeOfClosest;
        if (relVelSq < 1e-6) {
            // Stationary relative velocity - already at closest
            timeOfClosest = 0;
        }
        else {
            timeOfClosest = -math_utils_1.VectorMath.dot(relPos, relVel) / relVelSq;
            timeOfClosest = Math.max(0, timeOfClosest); // Can't go back in time
        }
        // Positions at closest approach
        const position1 = math_utils_1.VectorMath.add(pos1, math_utils_1.VectorMath.scale(vel1, timeOfClosest));
        const position2 = math_utils_1.VectorMath.add(pos2, math_utils_1.VectorMath.scale(vel2, timeOfClosest));
        const distance = math_utils_1.VectorMath.distance(position1, position2);
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
    addTarget(id, target) {
        this.targets.set(id, target);
    }
    /**
     * Remove a target from tracking
     */
    removeTarget(id) {
        this.targets.delete(id);
    }
    /**
     * Get a tracked target
     */
    getTarget(id) {
        return this.targets.get(id);
    }
    /**
     * Get all tracked targets
     */
    getAllTargets() {
        return Array.from(this.targets.values());
    }
    /**
     * Update a tracked target
     */
    updateTarget(id, target) {
        this.targets.set(id, target);
    }
}
exports.TargetingSystem = TargetingSystem;
//# sourceMappingURL=targeting.js.map