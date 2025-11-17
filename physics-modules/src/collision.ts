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
  relativeVelocity?: Vector3;
  impulseMagnitude?: number;
}

export interface PhysicsBody {
  position: Vector3;
  velocity: Vector3;
  angularVelocity?: Vector3;
  mass: number;
  momentOfInertia?: Vector3;
  restitution?: number;  // Coefficient of restitution (0-1, bounciness)
  friction?: number;     // Coefficient of friction (0-1)
  isStatic?: boolean;    // If true, infinite mass (immovable)
}

export interface CollisionResponse {
  linearImpulse: Vector3;
  angularImpulseA?: Vector3;
  angularImpulseB?: Vector3;
  separationVelocity: number;
  impactEnergy: number;  // Joules
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
 * Collision Response - Impulse-based physics
 *
 * Implements:
 * - Linear impulse for velocity changes
 * - Angular impulse for rotation changes
 * - Coefficient of restitution (elasticity)
 * - Friction (tangential impulse)
 */
export class CollisionResponse {
  /**
   * Resolve collision between two bodies using impulse-based method
   *
   * Physics:
   * 1. Calculate relative velocity at contact point
   * 2. Calculate impulse magnitude: j = -(1 + e) * v_rel · n / (1/m_a + 1/m_b + ...)
   * 3. Apply linear impulse: Δv = j * n / m
   * 4. Apply angular impulse: Δω = (r × j*n) / I
   * 5. Apply friction impulse (tangential)
   *
   * @param bodyA First body
   * @param bodyB Second body
   * @param collision Collision result with normal and contact point
   * @returns Collision response with impulses
   */
  static resolve(
    bodyA: PhysicsBody,
    bodyB: PhysicsBody,
    collision: CollisionResult
  ): CollisionResponse {
    const normal = collision.normal;
    const contactPoint = collision.point;

    // Calculate contact point relative to body centers
    const rA = VectorMath.subtract(contactPoint, bodyA.position);
    const rB = VectorMath.subtract(contactPoint, bodyB.position);

    // Calculate velocity at contact point (linear + angular)
    const vA = CollisionResponse.getVelocityAtPoint(bodyA, rA);
    const vB = CollisionResponse.getVelocityAtPoint(bodyB, rB);

    // Relative velocity: v_rel = v_b - v_a
    const relativeVelocity = VectorMath.subtract(vB, vA);

    // Velocity along normal (closing speed)
    const velocityAlongNormal = VectorMath.dot(relativeVelocity, normal);

    // If separating, no impulse needed
    if (velocityAlongNormal > 0) {
      return {
        linearImpulse: VectorMath.zero(),
        separationVelocity: velocityAlongNormal,
        impactEnergy: 0
      };
    }

    // Coefficient of restitution (average of both bodies)
    const restitution = ((bodyA.restitution || 0.3) + (bodyB.restitution || 0.3)) / 2;

    // Mass terms
    const invMassA = bodyA.isStatic ? 0 : 1 / bodyA.mass;
    const invMassB = bodyB.isStatic ? 0 : 1 / bodyB.mass;

    // Angular terms (if bodies have rotation)
    let angularTermA = 0;
    let angularTermB = 0;

    if (bodyA.angularVelocity && bodyA.momentOfInertia && !bodyA.isStatic) {
      const rACrossN = VectorMath.cross(rA, normal);
      const temp = {
        x: rACrossN.x / bodyA.momentOfInertia.x,
        y: rACrossN.y / bodyA.momentOfInertia.y,
        z: rACrossN.z / bodyA.momentOfInertia.z
      };
      angularTermA = VectorMath.dot(VectorMath.cross(temp, rA), normal);
    }

    if (bodyB.angularVelocity && bodyB.momentOfInertia && !bodyB.isStatic) {
      const rBCrossN = VectorMath.cross(rB, normal);
      const temp = {
        x: rBCrossN.x / bodyB.momentOfInertia.x,
        y: rBCrossN.y / bodyB.momentOfInertia.y,
        z: rBCrossN.z / bodyB.momentOfInertia.z
      };
      angularTermB = VectorMath.dot(VectorMath.cross(temp, rB), normal);
    }

    // Calculate impulse magnitude
    // j = -(1 + e) * v_rel · n / (1/m_a + 1/m_b + angular_terms)
    const numerator = -(1 + restitution) * velocityAlongNormal;
    const denominator = invMassA + invMassB + angularTermA + angularTermB;
    const impulseMagnitude = numerator / denominator;

    // Linear impulse: J = j * n
    const linearImpulse = VectorMath.scale(normal, impulseMagnitude);

    // Calculate separation velocity after impulse
    const separationVelocity = -velocityAlongNormal * restitution;

    // Calculate impact energy: E = 0.5 * m_reduced * v²
    const reducedMass = (bodyA.mass * bodyB.mass) / (bodyA.mass + bodyB.mass);
    const impactSpeed = Math.abs(velocityAlongNormal);
    const impactEnergy = 0.5 * reducedMass * impactSpeed * impactSpeed;

    // Calculate angular impulses
    let angularImpulseA: Vector3 | undefined;
    let angularImpulseB: Vector3 | undefined;

    if (bodyA.angularVelocity && bodyA.momentOfInertia && !bodyA.isStatic) {
      // Δω_a = (r_a × J) / I_a
      const torque = VectorMath.cross(rA, linearImpulse);
      angularImpulseA = {
        x: torque.x / bodyA.momentOfInertia.x,
        y: torque.y / bodyA.momentOfInertia.y,
        z: torque.z / bodyA.momentOfInertia.z
      };
    }

    if (bodyB.angularVelocity && bodyB.momentOfInertia && !bodyB.isStatic) {
      // Δω_b = -(r_b × J) / I_b (negative because impulse is in opposite direction)
      const torque = VectorMath.cross(rB, VectorMath.scale(linearImpulse, -1));
      angularImpulseB = {
        x: torque.x / bodyB.momentOfInertia.x,
        y: torque.y / bodyB.momentOfInertia.y,
        z: torque.z / bodyB.momentOfInertia.z
      };
    }

    // Apply friction (tangential impulse)
    const friction = CollisionResponse.calculateFriction(
      bodyA,
      bodyB,
      relativeVelocity,
      normal,
      impulseMagnitude
    );

    // Combine normal and friction impulses
    const totalLinearImpulse = VectorMath.add(linearImpulse, friction);

    return {
      linearImpulse: totalLinearImpulse,
      angularImpulseA,
      angularImpulseB,
      separationVelocity,
      impactEnergy
    };
  }

  /**
   * Calculate friction impulse (tangential)
   *
   * Coulomb friction: F_friction = μ * F_normal
   */
  private static calculateFriction(
    bodyA: PhysicsBody,
    bodyB: PhysicsBody,
    relativeVelocity: Vector3,
    normal: Vector3,
    normalImpulseMagnitude: number
  ): Vector3 {
    // Average friction coefficient
    const friction = ((bodyA.friction || 0.5) + (bodyB.friction || 0.5)) / 2;

    // Tangential velocity (perpendicular to normal)
    const normalVelocity = VectorMath.scale(normal, VectorMath.dot(relativeVelocity, normal));
    const tangentialVelocity = VectorMath.subtract(relativeVelocity, normalVelocity);

    const tangentialSpeed = VectorMath.magnitude(tangentialVelocity);

    if (tangentialSpeed < 0.01) return VectorMath.zero();  // Static friction threshold

    // Tangent direction
    const tangent = VectorMath.scale(tangentialVelocity, 1 / tangentialSpeed);

    // Coulomb friction magnitude
    const frictionMagnitude = friction * normalImpulseMagnitude;

    // Friction impulse opposes tangential motion
    return VectorMath.scale(tangent, -frictionMagnitude);
  }

  /**
   * Get velocity at a point on a body
   * v = v_linear + ω × r
   */
  private static getVelocityAtPoint(body: PhysicsBody, r: Vector3): Vector3 {
    if (!body.angularVelocity) {
      return body.velocity;
    }

    // v = v_linear + ω × r
    const angularContribution = VectorMath.cross(body.angularVelocity, r);
    return VectorMath.add(body.velocity, angularContribution);
  }

  /**
   * Apply impulse to a body
   * Updates velocity and angular velocity
   */
  static applyImpulse(
    body: PhysicsBody,
    linearImpulse: Vector3,
    angularImpulse?: Vector3
  ): void {
    if (body.isStatic) return;  // Static bodies don't move

    // Linear velocity change: Δv = J / m
    const deltaV = VectorMath.scale(linearImpulse, 1 / body.mass);
    body.velocity = VectorMath.add(body.velocity, deltaV);

    // Angular velocity change: Δω = (r × J) / I (already calculated in resolve)
    if (angularImpulse && body.angularVelocity) {
      body.angularVelocity = VectorMath.add(body.angularVelocity, angularImpulse);
    }
  }

  /**
   * Separate penetrating bodies
   * Moves bodies apart by penetration depth
   */
  static separateBodies(
    bodyA: PhysicsBody,
    bodyB: PhysicsBody,
    collision: CollisionResult
  ): void {
    if (collision.penetrationDepth <= 0) return;

    const normal = collision.normal;
    const depth = collision.penetrationDepth;

    // Mass ratio for separation
    const totalMass = bodyA.mass + bodyB.mass;
    const ratioA = bodyA.isStatic ? 0 : bodyB.mass / totalMass;
    const ratioB = bodyB.isStatic ? 0 : bodyA.mass / totalMass;

    // Move bodies apart
    const separationA = VectorMath.scale(normal, depth * ratioA);
    const separationB = VectorMath.scale(normal, -depth * ratioB);

    if (!bodyA.isStatic) {
      bodyA.position = VectorMath.add(bodyA.position, separationA);
    }

    if (!bodyB.isStatic) {
      bodyB.position = VectorMath.add(bodyB.position, separationB);
    }
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
