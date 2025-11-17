/**
 * Collision Detection System
 *
 * Handles collision shapes, detection algorithms, and spatial partitioning
 * NO RENDERING - physics only
 */
import { Vector3 } from './math-utils';
import { CelestialBody } from './world';
export declare enum CollisionShapeType {
    SPHERE = "sphere",
    AABB = "aabb",
    CAPSULE = "capsule",
    COMPOUND = "compound"
}
export interface CollisionShape {
    type: CollisionShapeType;
    localPosition: Vector3;
}
export interface SphereCollider extends CollisionShape {
    type: CollisionShapeType.SPHERE;
    radius: number;
}
export interface AABBCollider extends CollisionShape {
    type: CollisionShapeType.AABB;
    min: Vector3;
    max: Vector3;
}
export interface CapsuleCollider extends CollisionShape {
    type: CollisionShapeType.CAPSULE;
    radius: number;
    height: number;
    axis: 'x' | 'y' | 'z';
}
export interface CompoundCollider extends CollisionShape {
    type: CollisionShapeType.COMPOUND;
    children: CollisionShape[];
}
export interface CollisionResult {
    collided: boolean;
    point: Vector3;
    normal: Vector3;
    penetrationDepth: number;
    timeOfImpact?: number;
}
export interface CollisionPair {
    bodyA: CelestialBody;
    bodyB: CelestialBody;
    result: CollisionResult;
}
/**
 * Collision detection algorithms
 */
export declare class CollisionDetector {
    /**
     * Sphere vs Sphere collision (fastest)
     */
    static detectSphereSphere(pos1: Vector3, radius1: number, pos2: Vector3, radius2: number): CollisionResult | null;
    /**
     * Sphere vs AABB collision
     */
    static detectSphereAABB(sphereCenter: Vector3, sphereRadius: number, boxMin: Vector3, boxMax: Vector3): CollisionResult | null;
    /**
     * AABB vs AABB collision
     */
    static detectAABBAABB(min1: Vector3, max1: Vector3, min2: Vector3, max2: Vector3): CollisionResult | null;
    /**
     * Continuous collision detection - sphere sweep
     */
    static sweepSphereSphere(movingSphere: {
        center: Vector3;
        radius: number;
    }, startPos: Vector3, endPos: Vector3, staticSphere: {
        center: Vector3;
        radius: number;
    }): CollisionResult | null;
}
/**
 * Octree for spatial partitioning
 */
export interface AABB {
    min: Vector3;
    max: Vector3;
}
export declare class Octree {
    private root;
    private maxDepth;
    private maxObjects;
    constructor(bounds: AABB);
    insert(body: CelestialBody): void;
    query(region: AABB): CelestialBody[];
    queryRadius(point: Vector3, radius: number): CelestialBody[];
}
/**
 * Main collision system
 */
export declare class CollisionSystem {
    private octree;
    private worldBounds;
    constructor(worldBounds: AABB);
    rebuild(bodies: CelestialBody[]): void;
    checkCollision(bodyA: CelestialBody, bodyB: CelestialBody): CollisionResult | null;
    checkSweep(body: CelestialBody, startPos: Vector3, endPos: Vector3, staticBody: CelestialBody): CollisionResult | null;
    findCollisions(body: CelestialBody, otherBodies: CelestialBody[]): CollisionPair[];
    queryNearby(position: Vector3, radius: number): CelestialBody[];
}
//# sourceMappingURL=collision.d.ts.map