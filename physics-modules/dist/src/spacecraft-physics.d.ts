/**
 * Spacecraft Physics (Simplified for Integration)
 *
 * Basic rigid body physics for spacecraft
 * This is a simplified version - full spacecraft systems from earlier work
 * can be integrated later
 */
import { Vector3, Quaternion } from './math-utils';
export interface SpacecraftConfig {
    mass: number;
    momentOfInertia: Vector3;
    position: Vector3;
    velocity: Vector3;
    orientation: Quaternion;
    angularVelocity: Vector3;
}
/**
 * Basic spacecraft rigid body physics
 */
export declare class SpacecraftPhysics {
    private mass;
    private momentOfInertia;
    private position;
    private velocity;
    private orientation;
    private angularVelocity;
    private accumulatedForce;
    private accumulatedTorque;
    constructor(config: SpacecraftConfig);
    /**
     * Apply force to spacecraft
     */
    applyForce(force: Vector3): void;
    /**
     * Apply torque to spacecraft
     */
    applyTorque(torque: Vector3): void;
    /**
     * Update physics
     */
    update(dt: number): void;
    getMass(): number;
    getPosition(): Vector3;
    getVelocity(): Vector3;
    getOrientation(): Quaternion;
    getAngularVelocity(): Vector3;
    setPosition(position: Vector3): void;
    setVelocity(velocity: Vector3): void;
    setOrientation(orientation: Quaternion): void;
    setAngularVelocity(angularVelocity: Vector3): void;
}
//# sourceMappingURL=spacecraft-physics.d.ts.map