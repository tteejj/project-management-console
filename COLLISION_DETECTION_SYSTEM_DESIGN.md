# Collision Detection & Response System Design

## Overview

**Purpose:** Detect when ship collides with celestial bodies, calculate impact physics, trigger damage

**Integrations:**
- World Environment (what can we hit?)
- Hull Damage System (apply impact damage)
- Ship Physics (momentum transfer, bounce)
- Sensor System (proximity warnings)

**Requirements:**
- Accurate collision detection (no tunneling)
- Efficient (handle many objects)
- Realistic physics response
- Special cases (docking, fuel transfer)

---

## Collision Shapes

### Basic Shapes

```typescript
enum CollisionShapeType {
  SPHERE,           // Simplest - most celestial bodies
  AABB,             // Axis-aligned bounding box - stations, large asteroids
  CAPSULE,          // Ship hulls (cylinder with rounded ends)
  COMPOUND          // Multiple shapes combined
}

interface CollisionShape {
  type: CollisionShapeType;
  localPosition: Vector3;   // Relative to body center
  localRotation: Quaternion;
}

// Sphere - simplest and fastest
interface SphereCollider extends CollisionShape {
  type: CollisionShapeType.SPHERE;
  radius: number;
}

// AABB - axis-aligned box
interface AABBCollider extends CollisionShape {
  type: CollisionShapeType.AABB;
  min: Vector3;     // Minimum corner
  max: Vector3;     // Maximum corner
}

// Capsule - good for elongated ships
interface CapsuleCollider extends CollisionShape {
  type: CollisionShapeType.CAPSULE;
  radius: number;
  height: number;
  axis: 'x' | 'y' | 'z';
}

// Compound - multiple shapes
interface CompoundCollider extends CollisionShape {
  type: CollisionShapeType.COMPOUND;
  children: CollisionShape[];
}
```

### Body Collision Representation

```typescript
interface CelestialBody {
  // ... other properties

  // Collision
  collider: CollisionShape;
  collisionEnabled: boolean;
  isStatic: boolean;        // Planets don't move on collision
}

// Example: Moon
const moon: CelestialBody = {
  id: 'moon',
  name: 'The Moon',
  type: 'planet',
  mass: 7.342e22,
  radius: 1737400,
  position: { x: 0, y: 0, z: 0 },
  velocity: { x: 0, y: 0, z: 0 },
  collider: {
    type: CollisionShapeType.SPHERE,
    localPosition: { x: 0, y: 0, z: 0 },
    localRotation: { x: 0, y: 0, z: 0, w: 1 },
    radius: 1737400
  },
  collisionEnabled: true,
  isStatic: true
};

// Example: Space Station (compound shape)
const station: CelestialBody = {
  id: 'station_alpha',
  name: 'Station Alpha',
  type: 'station',
  mass: 50000,
  radius: 20,
  position: { x: 100000, y: 0, z: 50000 },
  velocity: { x: 0, y: 0, z: 0 },
  collider: {
    type: CollisionShapeType.COMPOUND,
    localPosition: { x: 0, y: 0, z: 0 },
    localRotation: { x: 0, y: 0, z: 0, w: 1 },
    children: [
      // Central hub
      {
        type: CollisionShapeType.SPHERE,
        localPosition: { x: 0, y: 0, z: 0 },
        radius: 10
      } as SphereCollider,
      // Docking ring
      {
        type: CollisionShapeType.CAPSULE,
        localPosition: { x: 0, y: 0, z: 15 },
        radius: 3,
        height: 10,
        axis: 'z'
      } as CapsuleCollider
    ]
  },
  collisionEnabled: true,
  isStatic: false
};
```

---

## Collision Detection Algorithms

### 1. Sphere vs Sphere (Fastest)

```typescript
function detectSphereSphere(
  pos1: Vector3, radius1: number,
  pos2: Vector3, radius2: number
): CollisionResult | null {
  const delta = subtract(pos2, pos1);
  const distance = magnitude(delta);
  const minDistance = radius1 + radius2;

  if (distance < minDistance) {
    // Collision detected
    const penetrationDepth = minDistance - distance;
    const normal = normalize(delta);

    return {
      collided: true,
      point: add(pos1, scale(normal, radius1 - penetrationDepth / 2)),
      normal,
      penetrationDepth
    };
  }

  return null;
}
```

### 2. Sphere vs AABB

```typescript
function detectSphereAABB(
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

  const delta = subtract(closestPoint, sphereCenter);
  const distanceSquared = dot(delta, delta);

  if (distanceSquared < sphereRadius * sphereRadius) {
    const distance = Math.sqrt(distanceSquared);
    const penetrationDepth = sphereRadius - distance;
    const normal = distance > 0 ? scale(delta, 1 / distance) : { x: 0, y: 1, z: 0 };

    return {
      collided: true,
      point: closestPoint,
      normal,
      penetrationDepth
    };
  }

  return null;
}
```

### 3. AABB vs AABB

```typescript
function detectAABBAABB(
  min1: Vector3, max1: Vector3,
  min2: Vector3, max2: Vector3
): CollisionResult | null {
  // Check for overlap on all axes
  if (max1.x < min2.x || min1.x > max2.x) return null;
  if (max1.y < min2.y || min1.y > max2.y) return null;
  if (max1.z < min2.z || min1.z > max2.z) return null;

  // Collision detected - calculate penetration
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
```

### 4. Continuous Collision Detection (No Tunneling)

```typescript
// Detect collision along movement path
function detectContinuousCollision(
  object: MovingObject,
  dt: number,
  staticBodies: CelestialBody[]
): CollisionResult | null {
  const startPos = object.position;
  const endPos = add(startPos, scale(object.velocity, dt));

  // Sweep test along path
  for (const body of staticBodies) {
    const collision = sweepTest(
      object.collider,
      startPos,
      endPos,
      body.collider,
      body.position
    );

    if (collision) {
      // Collision will occur during this timestep
      // Return time of impact (0-1 fraction of dt)
      return {
        ...collision,
        timeOfImpact: collision.t * dt
      };
    }
  }

  return null;
}

// Sphere sweep (moving sphere vs static sphere)
function sweepSphereSphere(
  movingSphere: SphereCollider,
  startPos: Vector3,
  endPos: Vector3,
  staticSphere: SphereCollider,
  staticPos: Vector3
): { t: number; point: Vector3; normal: Vector3 } | null {
  const path = subtract(endPos, startPos);
  const toStatic = subtract(staticPos, startPos);
  const radiusSum = movingSphere.radius + staticSphere.radius;

  // Solve quadratic for time of impact
  const a = dot(path, path);
  const b = -2 * dot(path, toStatic);
  const c = dot(toStatic, toStatic) - radiusSum * radiusSum;

  const discriminant = b * b - 4 * a * c;

  if (discriminant < 0) return null; // No collision

  const t = (-b - Math.sqrt(discriminant)) / (2 * a);

  if (t < 0 || t > 1) return null; // Collision outside this timestep

  const impactPos = add(startPos, scale(path, t));
  const normal = normalize(subtract(staticPos, impactPos));

  return {
    t,
    point: add(impactPos, scale(normal, movingSphere.radius)),
    normal
  };
}
```

---

## Spatial Partitioning (Performance)

### Octree for 3D Space

```typescript
class Octree {
  private root: OctreeNode;
  private maxDepth: number = 6;
  private maxObjects: number = 8;

  constructor(bounds: AABB) {
    this.root = new OctreeNode(bounds, 0);
  }

  // Insert body into octree
  insert(body: CelestialBody): void {
    this.root.insert(body, this.maxDepth, this.maxObjects);
  }

  // Query bodies in region
  query(region: AABB): CelestialBody[] {
    return this.root.query(region);
  }

  // Query bodies near point
  queryRadius(point: Vector3, radius: number): CelestialBody[] {
    const region: AABB = {
      min: { x: point.x - radius, y: point.y - radius, z: point.z - radius },
      max: { x: point.x + radius, y: point.y + radius, z: point.z + radius }
    };
    return this.query(region);
  }
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
    // Check if body intersects this node
    if (!this.intersects(body)) return;

    // If room, add to this node
    if (this.objects.length < maxObjects || this.depth >= maxDepth) {
      this.objects.push(body);
      return;
    }

    // Otherwise, subdivide and distribute
    if (!this.divided) {
      this.subdivide();
    }

    for (const child of this.children) {
      child.insert(body, maxDepth, maxObjects);
    }
  }

  query(region: AABB): CelestialBody[] {
    let results: CelestialBody[] = [];

    // Check if region intersects this node
    if (!this.intersectsAABB(region)) return results;

    // Add objects in this node
    results.push(...this.objects);

    // Query children
    if (this.divided) {
      for (const child of this.children) {
        results.push(...child.query(region));
      }
    }

    return results;
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
```

---

## Collision System Architecture

### Main Collision Manager

```typescript
interface CollisionResult {
  collided: boolean;
  point: Vector3;           // World space collision point
  normal: Vector3;          // Surface normal at collision
  penetrationDepth: number; // How far objects overlap
  timeOfImpact?: number;    // For continuous detection
}

interface CollisionPair {
  bodyA: CelestialBody;     // Usually the ship
  bodyB: CelestialBody;     // What we hit
  result: CollisionResult;
}

class CollisionSystem {
  private octree: Octree;
  private collisionPairs: CollisionPair[] = [];

  constructor(worldBounds: AABB) {
    this.octree = new Octree(worldBounds);
  }

  // Rebuild octree each frame (or when bodies move significantly)
  rebuild(bodies: CelestialBody[]): void {
    this.octree = new Octree(this.calculateWorldBounds(bodies));
    for (const body of bodies) {
      if (body.collisionEnabled) {
        this.octree.insert(body);
      }
    }
  }

  // Check ship against world
  checkShipCollisions(
    ship: Spacecraft,
    dt: number
  ): CollisionPair[] {
    this.collisionPairs = [];

    // Query nearby bodies
    const searchRadius = magnitude(scale(ship.state.velocity, dt)) + ship.radius * 2;
    const nearbyBodies = this.octree.queryRadius(ship.state.position, searchRadius);

    for (const body of nearbyBodies) {
      if (!body.collisionEnabled) continue;

      // Continuous collision detection
      const collision = this.detectCollision(
        ship.collider,
        ship.state.position,
        ship.state.velocity,
        body.collider,
        body.position,
        body.velocity,
        dt
      );

      if (collision) {
        this.collisionPairs.push({
          bodyA: ship as any, // Cast to CelestialBody interface
          bodyB: body,
          result: collision
        });
      }
    }

    return this.collisionPairs;
  }

  // Dispatch to appropriate detection algorithm
  private detectCollision(
    colliderA: CollisionShape,
    posA: Vector3,
    velA: Vector3,
    colliderB: CollisionShape,
    posB: Vector3,
    velB: Vector3,
    dt: number
  ): CollisionResult | null {
    // Use continuous detection for fast-moving objects
    const relativeSpeed = magnitude(subtract(velA, velB));
    const useContinuous = relativeSpeed * dt > 1.0; // Moving >1m per frame

    if (useContinuous) {
      return this.continuousDetection(colliderA, posA, velA, colliderB, posB, velB, dt);
    } else {
      return this.discreteDetection(colliderA, posA, colliderB, posB);
    }
  }

  private discreteDetection(
    colliderA: CollisionShape,
    posA: Vector3,
    colliderB: CollisionShape,
    posB: Vector3
  ): CollisionResult | null {
    // Dispatch based on shape types
    if (colliderA.type === CollisionShapeType.SPHERE &&
        colliderB.type === CollisionShapeType.SPHERE) {
      return detectSphereSphere(
        posA,
        (colliderA as SphereCollider).radius,
        posB,
        (colliderB as SphereCollider).radius
      );
    }

    if (colliderA.type === CollisionShapeType.SPHERE &&
        colliderB.type === CollisionShapeType.AABB) {
      const box = colliderB as AABBCollider;
      return detectSphereAABB(
        posA,
        (colliderA as SphereCollider).radius,
        add(posB, box.min),
        add(posB, box.max)
      );
    }

    // ... other shape combinations

    return null;
  }
}
```

---

## Collision Response (Physics)

### Momentum Transfer & Bounce

```typescript
class CollisionResolver {
  // Apply collision physics to both bodies
  resolveCollision(
    pair: CollisionPair,
    restitution: number = 0.3  // Coefficient of restitution (bounciness)
  ): void {
    const { bodyA, bodyB, result } = pair;

    // 1. Separate objects (resolve penetration)
    this.separateBodies(bodyA, bodyB, result);

    // 2. Calculate relative velocity at contact point
    const relativeVel = subtract(
      bodyA.velocity,
      bodyB.velocity
    );

    // 3. Velocity along normal
    const normalVelocity = dot(relativeVel, result.normal);

    // Already separating?
    if (normalVelocity > 0) return;

    // 4. Calculate impulse (J = -(1 + e) * v_n / (1/m_a + 1/m_b))
    const impulse = -(1 + restitution) * normalVelocity /
                    (1 / bodyA.mass + 1 / bodyB.mass);

    const impulseVector = scale(result.normal, impulse);

    // 5. Apply impulse to both bodies
    if (!bodyA.isStatic) {
      bodyA.velocity = add(
        bodyA.velocity,
        scale(impulseVector, 1 / bodyA.mass)
      );
    }

    if (!bodyB.isStatic) {
      bodyB.velocity = subtract(
        bodyB.velocity,
        scale(impulseVector, 1 / bodyB.mass)
      );
    }

    // 6. Apply angular impulse (if rotating bodies)
    if (bodyA.angularVelocity && !bodyA.isStatic) {
      const torque = cross(
        subtract(result.point, bodyA.position),
        impulseVector
      );
      bodyA.angularVelocity = add(
        bodyA.angularVelocity,
        scale(torque, 1 / bodyA.momentOfInertia)
      );
    }
  }

  private separateBodies(
    bodyA: CelestialBody,
    bodyB: CelestialBody,
    result: CollisionResult
  ): void {
    const separation = scale(result.normal, result.penetrationDepth);

    if (!bodyA.isStatic && !bodyB.isStatic) {
      // Both moving - split separation
      const totalMass = bodyA.mass + bodyB.mass;
      const ratioA = bodyB.mass / totalMass;
      const ratioB = bodyA.mass / totalMass;

      bodyA.position = add(bodyA.position, scale(separation, ratioA));
      bodyB.position = subtract(bodyB.position, scale(separation, ratioB));
    } else if (!bodyA.isStatic) {
      // Only A moves
      bodyA.position = add(bodyA.position, separation);
    } else if (!bodyB.isStatic) {
      // Only B moves
      bodyB.position = subtract(bodyB.position, separation);
    }
  }
}
```

---

## Integration with Hull Damage

### Collision → Damage Pipeline

```typescript
class CollisionDamageHandler {
  handleCollision(
    ship: Spacecraft,
    collision: CollisionPair
  ): void {
    const { bodyB: target, result } = collision;

    // 1. Calculate impact velocity
    const relativeVel = subtract(ship.state.velocity, target.velocity);
    const impactSpeed = magnitude(relativeVel);

    // 2. Calculate impact angle (from surface normal)
    const impactAngle = Math.acos(
      dot(normalize(relativeVel), result.normal)
    );

    // 3. Find which hull compartment was hit
    const compartment = ship.hull.findCompartmentAtPosition(result.point);

    if (!compartment) return;

    // 4. Create impact event
    const impact: ImpactEvent = {
      projectile: {
        mass: target.mass,
        velocity: target.velocity,
        radius: target.radius || 1,
        hardness: this.getHardness(target.type),
        material: this.getMaterial(target.type)
      },
      target: compartment,
      impactPosition: result.point,
      impactVelocity: relativeVel,
      impactAngle,
      kineticEnergy: 0.5 * target.mass * impactSpeed * impactSpeed,
      momentum: scale(relativeVel, target.mass)
    };

    // 5. Apply damage
    ship.hullIntegrity.applyImpact(impact);

    // 6. Trigger warnings
    if (impact.penetrated) {
      this.triggerCollisionWarning(ship, target, impact);
    }
  }

  private getHardness(bodyType: string): number {
    switch (bodyType) {
      case 'asteroid': return 500;  // Rock
      case 'station': return 300;   // Steel
      case 'debris': return 200;    // Metal fragments
      case 'planet': return 1000;   // Very hard
      default: return 100;
    }
  }

  private getMaterial(bodyType: string): 'rock' | 'ice' | 'metal' | 'composite' {
    switch (bodyType) {
      case 'asteroid': return 'rock';
      case 'station': return 'metal';
      case 'debris': return 'metal';
      default: return 'rock';
    }
  }
}
```

---

## Special Cases

### 1. Docking (Controlled Collision)

```typescript
interface DockingPort {
  position: Vector3;        // Relative to station
  orientation: Vector3;     // Approach vector
  captureRadius: number;    // m
  maxApproachSpeed: number; // m/s
  aligned: boolean;         // Is ship properly aligned?
}

class DockingSystem {
  checkDocking(
    ship: Spacecraft,
    station: CelestialBody,
    port: DockingPort
  ): DockingResult {
    // 1. Check proximity
    const portWorldPos = add(station.position, port.position);
    const distance = magnitude(subtract(ship.state.position, portWorldPos));

    if (distance > port.captureRadius) {
      return { status: 'too_far', distance };
    }

    // 2. Check relative velocity
    const relativeVel = subtract(ship.state.velocity, station.velocity);
    const approachSpeed = magnitude(relativeVel);

    if (approachSpeed > port.maxApproachSpeed) {
      return { status: 'too_fast', speed: approachSpeed };
    }

    // 3. Check alignment
    const shipForward = ship.getForwardVector();
    const portNormal = port.orientation;
    const alignmentAngle = Math.acos(dot(shipForward, portNormal));

    if (alignmentAngle > 5 * DEG_TO_RAD) { // 5 degree tolerance
      return { status: 'misaligned', angle: alignmentAngle };
    }

    // 4. All checks passed - DOCK!
    return { status: 'docked' };
  }
}

type DockingResult =
  | { status: 'too_far'; distance: number }
  | { status: 'too_fast'; speed: number }
  | { status: 'misaligned'; angle: number }
  | { status: 'docked' };
```

### 2. Proximity Warnings

```typescript
class ProximityWarningSystem {
  private warningLevels = {
    caution: 1000,    // 1km
    warning: 500,     // 500m
    critical: 100     // 100m
  };

  update(
    ship: Spacecraft,
    nearbyBodies: CelestialBody[]
  ): ProximityWarning[] {
    const warnings: ProximityWarning[] = [];

    for (const body of nearbyBodies) {
      const distance = magnitude(subtract(body.position, ship.state.position));

      // Time to impact (if on collision course)
      const relativeVel = subtract(ship.state.velocity, body.velocity);
      const closingSpeed = -dot(
        normalize(subtract(body.position, ship.state.position)),
        relativeVel
      );

      if (closingSpeed <= 0) continue; // Not approaching

      const timeToImpact = distance / closingSpeed;

      let level: 'caution' | 'warning' | 'critical' | null = null;

      if (distance < this.warningLevels.critical || timeToImpact < 5) {
        level = 'critical';
      } else if (distance < this.warningLevels.warning || timeToImpact < 15) {
        level = 'warning';
      } else if (distance < this.warningLevels.caution || timeToImpact < 30) {
        level = 'caution';
      }

      if (level) {
        warnings.push({
          target: body,
          distance,
          closingSpeed,
          timeToImpact,
          level
        });
      }
    }

    return warnings;
  }
}

interface ProximityWarning {
  target: CelestialBody;
  distance: number;
  closingSpeed: number;
  timeToImpact: number;
  level: 'caution' | 'warning' | 'critical';
}
```

---

## Player Display Integration

### Collision Warnings (Audio + Visual)

```
PROXIMITY WARNING
┌─────────────────────────────────┐
│ ⚠️  COLLISION ALERT  ⚠️          │
│                                 │
│ OBJECT: Asteroid                │
│ RANGE:  245 m                   │
│ CLOSING: 18 m/s                 │
│ IMPACT:  13 seconds             │
│                                 │
│ RECOMMEND:                      │
│ - FIRE RCS BOW THRUSTERS        │
│ - REDUCE VELOCITY               │
│ - ALTER HEADING +15°            │
│                                 │
│ [EXECUTE AVOIDANCE]             │
└─────────────────────────────────┘
```

### Post-Collision Damage Report

```
COLLISION DETECTED
┌─────────────────────────────────┐
│ 🔴 IMPACT EVENT 🔴               │
│                                 │
│ STRUCK: Asteroid (500kg)        │
│ SPEED: 25 m/s                   │
│ ANGLE: 45° (glancing)           │
│ ENERGY: 156 kJ                  │
│                                 │
│ DAMAGE REPORT:                  │
│ - BOW SECTION: -35% integrity   │
│ - MINOR BREACH (0.12m)          │
│ - RADAR: DAMAGED                │
│ - VENTING: 0.8 kg/s             │
│                                 │
│ IMMEDIATE ACTIONS:              │
│ [SEAL BREACH]                   │
│ [EMERGENCY PATCH]               │
│ [DAMAGE CONTROL]                │
└─────────────────────────────────┘
```

---

## Performance Optimization

### Broad Phase → Narrow Phase

```typescript
class OptimizedCollisionSystem {
  // Broad phase: Quick rejection of distant objects
  broadPhase(ship: Spacecraft, world: World): CelestialBody[] {
    // Use octree spatial query
    const searchRadius = magnitude(ship.state.velocity) * 2 + ship.radius;
    return this.octree.queryRadius(ship.state.position, searchRadius);
  }

  // Narrow phase: Precise collision detection
  narrowPhase(ship: Spacecraft, candidates: CelestialBody[]): CollisionPair[] {
    const collisions: CollisionPair[] = [];

    for (const body of candidates) {
      // Bounding sphere check first (cheap)
      const distance = magnitude(subtract(body.position, ship.state.position));
      if (distance > ship.radius + body.radius + 10) continue;

      // Precise collision detection
      const result = this.detectCollision(ship.collider, ship.state.position,
                                         body.collider, body.position);

      if (result) {
        collisions.push({ bodyA: ship, bodyB: body, result });
      }
    }

    return collisions;
  }
}
```

---

## Summary

**Collision Detection:**
- Multiple shape types (sphere, AABB, capsule, compound)
- Continuous detection (no tunneling at high speeds)
- Spatial partitioning (octree for performance)
- Broad phase → narrow phase optimization

**Collision Response:**
- Realistic physics (impulse, momentum transfer)
- Coefficient of restitution (bounce)
- Separation resolution (prevent overlap)
- Angular momentum (rotation from off-center impacts)

**Damage Integration:**
- Collision → hull damage pipeline
- Impact parameters (velocity, angle, energy)
- Compartment-specific damage
- Player warnings and reports

**Special Cases:**
- Docking (controlled collision with tolerances)
- Proximity warnings (time to impact)
- Different collision materials (rock, ice, metal)

**Player Experience:**
- Warnings before collision
- Damage reports after collision
- Avoidance suggestions
- No visual rendering - all through instruments

**Next:** Target selection and intercept planning system design.
