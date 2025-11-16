/**
 * Collision Detection System
 *
 * Handles collision shapes, detection algorithms, and spatial partitioning
 * NO RENDERING - physics only
 */

import { Vector3, VectorMath } from './math-utils';
import { CelestialBody } from './world';

export enum CollisionShapeType {
  SPHERE = 'sphere',
  AABB = 'aabb',
  CAPSULE = 'capsule',
  COMPOUND = 'compound'
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
export class CollisionDetector {
  /**
   * Sphere vs Sphere collision (fastest)
   */
  static detectSphereSphere(
    pos1: Vector3,
    radius1: number,
    pos2: Vector3,
    radius2: number
  ): CollisionResult | null {
    const delta = VectorMath.subtract(pos2, pos1);
    const distanceSq = VectorMath.magnitudeSquared(delta);
    const minDistance = radius1 + radius2;
    const minDistanceSq = minDistance * minDistance;

    if (distanceSq < minDistanceSq) {
      const distance = Math.sqrt(distanceSq);
      const penetrationDepth = minDistance - distance;

      // Avoid division by zero
      const normal = distance > 1e-10
        ? VectorMath.scale(delta, 1 / distance)
        : { x: 0, y: 0, z: 1 };

      const point = VectorMath.add(
        pos1,
        VectorMath.scale(normal, radius1 - penetrationDepth / 2)
      );

      return {
        collided: true,
        point,
        normal,
        penetrationDepth
      };
    }

    return null;
  }

  /**
   * Sphere vs AABB collision
   */
  static detectSphereAABB(
    sphereCenter: Vector3,
    sphereRadius: number,
    boxMin: Vector3,
    boxMax: Vector3
  ): CollisionResult | null {
    // Find closest point on box to sphere center
    const closestPoint = {
      x: Math.max(boxMin.x, Math.min(sphereCenter.x, boxMax.x)),
      y: Math.max(boxMin.y, Math.min(sphereCenter.y, boxMax.y)),
      z: Math.max(boxMin.z, Math.min(sphereCenter.z, boxMax.z))
    };

    const delta = VectorMath.subtract(closestPoint, sphereCenter);
    const distanceSquared = VectorMath.magnitudeSquared(delta);

    if (distanceSquared < sphereRadius * sphereRadius) {
      const distance = Math.sqrt(distanceSquared);
      const penetrationDepth = sphereRadius - distance;

      // Normal points from box to sphere (direction to separate)
      const normal = distance > 1e-10
        ? VectorMath.scale(delta, -1 / distance)
        : { x: 0, y: 1, z: 0 };

      return {
        collided: true,
        point: closestPoint,
        normal,
        penetrationDepth
      };
    }

    return null;
  }

  /**
   * AABB vs AABB collision
   */
  static detectAABBAABB(
    min1: Vector3,
    max1: Vector3,
    min2: Vector3,
    max2: Vector3
  ): CollisionResult | null {
    // Check for overlap on all axes
    if (max1.x < min2.x || min1.x > max2.x) return null;
    if (max1.y < min2.y || min1.y > max2.y) return null;
    if (max1.z < min2.z || min1.z > max2.z) return null;

    // Calculate penetration on each axis
    const overlapX = Math.min(max1.x - min2.x, max2.x - min1.x);
    const overlapY = Math.min(max1.y - min2.y, max2.y - min1.y);
    const overlapZ = Math.min(max1.z - min2.z, max2.z - min1.z);

    // Use smallest overlap as separation axis
    let normal: Vector3;
    let penetrationDepth: number;

    if (overlapX < overlapY && overlapX < overlapZ) {
      penetrationDepth = overlapX;
      normal = { x: max1.x > max2.x ? 1 : -1, y: 0, z: 0 };
    } else if (overlapY < overlapZ) {
      penetrationDepth = overlapY;
      normal = { x: 0, y: max1.y > max2.y ? 1 : -1, z: 0 };
    } else {
      penetrationDepth = overlapZ;
      normal = { x: 0, y: 0, z: max1.z > max2.z ? 1 : -1 };
    }

    const point = {
      x: (Math.max(min1.x, min2.x) + Math.min(max1.x, max2.x)) / 2,
      y: (Math.max(min1.y, min2.y) + Math.min(max1.y, max2.y)) / 2,
      z: (Math.max(min1.z, min2.z) + Math.min(max1.z, max2.z)) / 2
    };

    return {
      collided: true,
      point,
      normal,
      penetrationDepth
    };
  }

  /**
   * Continuous collision detection - sphere sweep
   */
  static sweepSphereSphere(
    movingSphere: { center: Vector3; radius: number },
    startPos: Vector3,
    endPos: Vector3,
    staticSphere: { center: Vector3; radius: number }
  ): CollisionResult | null {
    const path = VectorMath.subtract(endPos, startPos);
    const toStatic = VectorMath.subtract(staticSphere.center, startPos);
    const radiusSum = movingSphere.radius + staticSphere.radius;

    // Solve quadratic for time of impact
    const a = VectorMath.dot(path, path);
    const b = -2 * VectorMath.dot(path, toStatic);
    const c = VectorMath.dot(toStatic, toStatic) - radiusSum * radiusSum;

    const discriminant = b * b - 4 * a * c;

    if (discriminant < 0) return null; // No collision

    const t = (-b - Math.sqrt(discriminant)) / (2 * a);

    if (t < 0 || t > 1) return null; // Collision outside this timestep

    const impactPos = VectorMath.add(startPos, VectorMath.scale(path, t));
    const normal = VectorMath.normalize(
      VectorMath.subtract(staticSphere.center, impactPos)
    );

    const point = VectorMath.add(
      impactPos,
      VectorMath.scale(normal, movingSphere.radius)
    );

    return {
      collided: true,
      point,
      normal,
      penetrationDepth: 0,
      timeOfImpact: t
    };
  }
}

/**
 * Octree for spatial partitioning
 */
export interface AABB {
  min: Vector3;
  max: Vector3;
}

class OctreeNode {
  private bounds: AABB;
  private depth: number;
  private objects: CelestialBody[] = [];
  private children: OctreeNode[] = [];
  private divided: boolean = false;

  constructor(bounds: AABB, depth: number) {
    this.bounds = bounds;
    this.depth = depth;
  }

  insert(body: CelestialBody, maxDepth: number, maxObjects: number): void {
    if (!this.intersects(body)) return;

    // If at max depth or haven't exceeded capacity, store here
    if (this.depth >= maxDepth || (!this.divided && this.objects.length < maxObjects)) {
      this.objects.push(body);
      return;
    }

    // Need to subdivide
    if (!this.divided) {
      this.subdivide();

      // Move existing objects to children
      const existingObjects = [...this.objects];
      this.objects = [];

      for (const obj of existingObjects) {
        for (const child of this.children) {
          child.insert(obj, maxDepth, maxObjects);
        }
      }
    }

    // Insert new object into children
    for (const child of this.children) {
      child.insert(body, maxDepth, maxObjects);
    }
  }

  query(region: AABB): CelestialBody[] {
    let results: CelestialBody[] = [];

    if (!this.intersectsAABB(region)) return results;

    results.push(...this.objects);

    if (this.divided) {
      for (const child of this.children) {
        results.push(...child.query(region));
      }
    }

    return results;
  }

  private intersects(body: CelestialBody): boolean {
    // Simple sphere vs AABB test
    const { min, max } = this.bounds;
    const pos = body.position;
    const r = body.radius;

    return (
      pos.x + r >= min.x && pos.x - r <= max.x &&
      pos.y + r >= min.y && pos.y - r <= max.y &&
      pos.z + r >= min.z && pos.z - r <= max.z
    );
  }

  private intersectsAABB(region: AABB): boolean {
    const { min: min1, max: max1 } = this.bounds;
    const { min: min2, max: max2 } = region;

    return (
      min1.x <= max2.x && max1.x >= min2.x &&
      min1.y <= max2.y && max1.y >= min2.y &&
      min1.z <= max2.z && max1.z >= min2.z
    );
  }

  private subdivide(): void {
    const { min, max } = this.bounds;
    const mid = {
      x: (min.x + max.x) / 2,
      y: (min.y + max.y) / 2,
      z: (min.z + max.z) / 2
    };

    // Create 8 children (octants)
    this.children = [
      new OctreeNode({ min: min, max: mid }, this.depth + 1),
      new OctreeNode({ min: { x: mid.x, y: min.y, z: min.z }, max: { x: max.x, y: mid.y, z: mid.z } }, this.depth + 1),
      new OctreeNode({ min: { x: min.x, y: mid.y, z: min.z }, max: { x: mid.x, y: max.y, z: mid.z } }, this.depth + 1),
      new OctreeNode({ min: { x: mid.x, y: mid.y, z: min.z }, max: { x: max.x, y: max.y, z: mid.z } }, this.depth + 1),
      new OctreeNode({ min: { x: min.x, y: min.y, z: mid.z }, max: { x: mid.x, y: mid.y, z: max.z } }, this.depth + 1),
      new OctreeNode({ min: { x: mid.x, y: min.y, z: mid.z }, max: { x: max.x, y: mid.y, z: max.z } }, this.depth + 1),
      new OctreeNode({ min: { x: min.x, y: mid.y, z: mid.z }, max: { x: mid.x, y: max.y, z: max.z } }, this.depth + 1),
      new OctreeNode({ min: mid, max: max }, this.depth + 1)
    ];

    this.divided = true;
  }
}

export class Octree {
  private root: OctreeNode;
  private maxDepth: number = 6;
  private maxObjects: number = 8;

  constructor(bounds: AABB) {
    this.root = new OctreeNode(bounds, 0);
  }

  insert(body: CelestialBody): void {
    this.root.insert(body, this.maxDepth, this.maxObjects);
  }

  query(region: AABB): CelestialBody[] {
    const results = this.root.query(region);

    // Deduplicate and filter by actual intersection
    const seen = new Set<string>();
    return results.filter(body => {
      if (seen.has(body.id)) return false;
      seen.add(body.id);

      // Check if body actually intersects the query region (considering radius)
      const { min, max } = region;
      const pos = body.position;
      const r = body.radius;

      return (
        pos.x + r >= min.x && pos.x - r <= max.x &&
        pos.y + r >= min.y && pos.y - r <= max.y &&
        pos.z + r >= min.z && pos.z - r <= max.z
      );
    });
  }

  queryRadius(point: Vector3, radius: number): CelestialBody[] {
    const region: AABB = {
      min: { x: point.x - radius, y: point.y - radius, z: point.z - radius },
      max: { x: point.x + radius, y: point.y + radius, z: point.z + radius }
    };
    const results = this.query(region);

    // Filter by actual distance (AABB query is conservative)
    const radiusSq = radius * radius;
    return results.filter(body => {
      const dx = body.position.x - point.x;
      const dy = body.position.y - point.y;
      const dz = body.position.z - point.z;
      const distSq = dx*dx + dy*dy + dz*dz;
      return distSq <= radiusSq + body.radius * body.radius;
    });
  }
}

/**
 * Main collision system
 */
export class CollisionSystem {
  private octree: Octree | null = null;
  private worldBounds: AABB;

  constructor(worldBounds: AABB) {
    this.worldBounds = worldBounds;
  }

  rebuild(bodies: CelestialBody[]): void {
    this.octree = new Octree(this.worldBounds);
    for (const body of bodies) {
      if (body.collisionEnabled !== false) {
        this.octree.insert(body);
      }
    }
  }

  checkCollision(
    bodyA: CelestialBody,
    bodyB: CelestialBody
  ): CollisionResult | null {
    // For now, assume all bodies are spheres (simplest case)
    return CollisionDetector.detectSphereSphere(
      bodyA.position,
      bodyA.radius,
      bodyB.position,
      bodyB.radius
    );
  }

  checkSweep(
    body: CelestialBody,
    startPos: Vector3,
    endPos: Vector3,
    staticBody: CelestialBody
  ): CollisionResult | null {
    return CollisionDetector.sweepSphereSphere(
      { center: body.position, radius: body.radius },
      startPos,
      endPos,
      { center: staticBody.position, radius: staticBody.radius }
    );
  }

  findCollisions(
    body: CelestialBody,
    otherBodies: CelestialBody[]
  ): CollisionPair[] {
    const pairs: CollisionPair[] = [];

    for (const other of otherBodies) {
      if (other.id === body.id) continue;
      if (other.collisionEnabled === false) continue;

      const result = this.checkCollision(body, other);
      if (result) {
        pairs.push({ bodyA: body, bodyB: other, result });
      }
    }

    return pairs;
  }

  queryNearby(position: Vector3, radius: number): CelestialBody[] {
    if (!this.octree) return [];
    return this.octree.queryRadius(position, radius);
  }
}
