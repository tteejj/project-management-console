"use strict";
/**
 * Collision Detection System
 *
 * Handles collision shapes, detection algorithms, and spatial partitioning
 * NO RENDERING - physics only
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.CollisionSystem = exports.Octree = exports.CollisionDetector = exports.CollisionShapeType = void 0;
const math_utils_1 = require("./math-utils");
var CollisionShapeType;
(function (CollisionShapeType) {
    CollisionShapeType["SPHERE"] = "sphere";
    CollisionShapeType["AABB"] = "aabb";
    CollisionShapeType["CAPSULE"] = "capsule";
    CollisionShapeType["COMPOUND"] = "compound";
})(CollisionShapeType || (exports.CollisionShapeType = CollisionShapeType = {}));
/**
 * Collision detection algorithms
 */
class CollisionDetector {
    /**
     * Sphere vs Sphere collision (fastest)
     */
    static detectSphereSphere(pos1, radius1, pos2, radius2) {
        const delta = math_utils_1.VectorMath.subtract(pos2, pos1);
        const distanceSq = math_utils_1.VectorMath.magnitudeSquared(delta);
        const minDistance = radius1 + radius2;
        const minDistanceSq = minDistance * minDistance;
        if (distanceSq < minDistanceSq) {
            const distance = Math.sqrt(distanceSq);
            const penetrationDepth = minDistance - distance;
            // Avoid division by zero
            const normal = distance > 1e-10
                ? math_utils_1.VectorMath.scale(delta, 1 / distance)
                : { x: 0, y: 0, z: 1 };
            const point = math_utils_1.VectorMath.add(pos1, math_utils_1.VectorMath.scale(normal, radius1 - penetrationDepth / 2));
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
    static detectSphereAABB(sphereCenter, sphereRadius, boxMin, boxMax) {
        // Find closest point on box to sphere center
        const closestPoint = {
            x: Math.max(boxMin.x, Math.min(sphereCenter.x, boxMax.x)),
            y: Math.max(boxMin.y, Math.min(sphereCenter.y, boxMax.y)),
            z: Math.max(boxMin.z, Math.min(sphereCenter.z, boxMax.z))
        };
        const delta = math_utils_1.VectorMath.subtract(closestPoint, sphereCenter);
        const distanceSquared = math_utils_1.VectorMath.magnitudeSquared(delta);
        if (distanceSquared < sphereRadius * sphereRadius) {
            const distance = Math.sqrt(distanceSquared);
            const penetrationDepth = sphereRadius - distance;
            // Normal points from box to sphere (direction to separate)
            const normal = distance > 1e-10
                ? math_utils_1.VectorMath.scale(delta, -1 / distance)
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
    static detectAABBAABB(min1, max1, min2, max2) {
        // Check for overlap on all axes
        if (max1.x < min2.x || min1.x > max2.x)
            return null;
        if (max1.y < min2.y || min1.y > max2.y)
            return null;
        if (max1.z < min2.z || min1.z > max2.z)
            return null;
        // Calculate penetration on each axis
        const overlapX = Math.min(max1.x - min2.x, max2.x - min1.x);
        const overlapY = Math.min(max1.y - min2.y, max2.y - min1.y);
        const overlapZ = Math.min(max1.z - min2.z, max2.z - min1.z);
        // Use smallest overlap as separation axis
        let normal;
        let penetrationDepth;
        if (overlapX < overlapY && overlapX < overlapZ) {
            penetrationDepth = overlapX;
            normal = { x: max1.x > max2.x ? 1 : -1, y: 0, z: 0 };
        }
        else if (overlapY < overlapZ) {
            penetrationDepth = overlapY;
            normal = { x: 0, y: max1.y > max2.y ? 1 : -1, z: 0 };
        }
        else {
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
    static sweepSphereSphere(movingSphere, startPos, endPos, staticSphere) {
        const path = math_utils_1.VectorMath.subtract(endPos, startPos);
        const toStatic = math_utils_1.VectorMath.subtract(staticSphere.center, startPos);
        const radiusSum = movingSphere.radius + staticSphere.radius;
        // Solve quadratic for time of impact
        const a = math_utils_1.VectorMath.dot(path, path);
        const b = -2 * math_utils_1.VectorMath.dot(path, toStatic);
        const c = math_utils_1.VectorMath.dot(toStatic, toStatic) - radiusSum * radiusSum;
        const discriminant = b * b - 4 * a * c;
        if (discriminant < 0)
            return null; // No collision
        const t = (-b - Math.sqrt(discriminant)) / (2 * a);
        if (t < 0 || t > 1)
            return null; // Collision outside this timestep
        const impactPos = math_utils_1.VectorMath.add(startPos, math_utils_1.VectorMath.scale(path, t));
        const normal = math_utils_1.VectorMath.normalize(math_utils_1.VectorMath.subtract(staticSphere.center, impactPos));
        const point = math_utils_1.VectorMath.add(impactPos, math_utils_1.VectorMath.scale(normal, movingSphere.radius));
        return {
            collided: true,
            point,
            normal,
            penetrationDepth: 0,
            timeOfImpact: t
        };
    }
}
exports.CollisionDetector = CollisionDetector;
class OctreeNode {
    constructor(bounds, depth) {
        this.objects = [];
        this.children = [];
        this.divided = false;
        this.bounds = bounds;
        this.depth = depth;
    }
    insert(body, maxDepth, maxObjects) {
        if (!this.intersects(body))
            return;
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
    query(region) {
        let results = [];
        if (!this.intersectsAABB(region))
            return results;
        results.push(...this.objects);
        if (this.divided) {
            for (const child of this.children) {
                results.push(...child.query(region));
            }
        }
        return results;
    }
    intersects(body) {
        // Simple sphere vs AABB test
        const { min, max } = this.bounds;
        const pos = body.position;
        const r = body.radius;
        return (pos.x + r >= min.x && pos.x - r <= max.x &&
            pos.y + r >= min.y && pos.y - r <= max.y &&
            pos.z + r >= min.z && pos.z - r <= max.z);
    }
    intersectsAABB(region) {
        const { min: min1, max: max1 } = this.bounds;
        const { min: min2, max: max2 } = region;
        return (min1.x <= max2.x && max1.x >= min2.x &&
            min1.y <= max2.y && max1.y >= min2.y &&
            min1.z <= max2.z && max1.z >= min2.z);
    }
    subdivide() {
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
class Octree {
    constructor(bounds) {
        this.maxDepth = 6;
        this.maxObjects = 8;
        this.root = new OctreeNode(bounds, 0);
    }
    insert(body) {
        this.root.insert(body, this.maxDepth, this.maxObjects);
    }
    query(region) {
        const results = this.root.query(region);
        // Deduplicate and filter by actual intersection
        const seen = new Set();
        return results.filter(body => {
            if (seen.has(body.id))
                return false;
            seen.add(body.id);
            // Check if body actually intersects the query region (considering radius)
            const { min, max } = region;
            const pos = body.position;
            const r = body.radius;
            return (pos.x + r >= min.x && pos.x - r <= max.x &&
                pos.y + r >= min.y && pos.y - r <= max.y &&
                pos.z + r >= min.z && pos.z - r <= max.z);
        });
    }
    queryRadius(point, radius) {
        const region = {
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
            const distSq = dx * dx + dy * dy + dz * dz;
            return distSq <= radiusSq + body.radius * body.radius;
        });
    }
}
exports.Octree = Octree;
/**
 * Main collision system
 */
class CollisionSystem {
    constructor(worldBounds) {
        this.octree = null;
        this.worldBounds = worldBounds;
    }
    rebuild(bodies) {
        this.octree = new Octree(this.worldBounds);
        for (const body of bodies) {
            if (body.collisionEnabled !== false) {
                this.octree.insert(body);
            }
        }
    }
    checkCollision(bodyA, bodyB) {
        // For now, assume all bodies are spheres (simplest case)
        return CollisionDetector.detectSphereSphere(bodyA.position, bodyA.radius, bodyB.position, bodyB.radius);
    }
    checkSweep(body, startPos, endPos, staticBody) {
        return CollisionDetector.sweepSphereSphere({ center: body.position, radius: body.radius }, startPos, endPos, { center: staticBody.position, radius: staticBody.radius });
    }
    findCollisions(body, otherBodies) {
        const pairs = [];
        for (const other of otherBodies) {
            if (other.id === body.id)
                continue;
            if (other.collisionEnabled === false)
                continue;
            const result = this.checkCollision(body, other);
            if (result) {
                pairs.push({ bodyA: body, bodyB: other, result });
            }
        }
        return pairs;
    }
    queryNearby(position, radius) {
        if (!this.octree)
            return [];
        return this.octree.queryRadius(position, radius);
    }
}
exports.CollisionSystem = CollisionSystem;
//# sourceMappingURL=collision.js.map