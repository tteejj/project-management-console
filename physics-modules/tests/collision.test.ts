/**
 * Tests for Collision Detection System
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  CollisionDetector,
  CollisionSystem,
  Octree,
  AABB,
  CollisionShapeType
} from '../src/collision';
import { CelestialBody } from '../src/world';
import { VectorMath } from '../src/math-utils';

describe('Collision Detection System', () => {
  describe('Sphere vs Sphere Collision', () => {
    it('should detect collision when spheres overlap', () => {
      const result = CollisionDetector.detectSphereSphere(
        { x: 0, y: 0, z: 0 },
        5,  // radius 5m
        { x: 8, y: 0, z: 0 },
        5   // radius 5m, centers 8m apart (total radius 10m)
      );

      expect(result).toBeDefined();
      expect(result?.collided).toBe(true);
      expect(result?.penetrationDepth).toBeCloseTo(2, 5);  // 10 - 8 = 2m overlap
    });

    it('should not detect collision when spheres are separated', () => {
      const result = CollisionDetector.detectSphereSphere(
        { x: 0, y: 0, z: 0 },
        5,
        { x: 15, y: 0, z: 0 },
        5   // 15m apart, need 10m to touch
      );

      expect(result).toBeNull();
    });

    it('should calculate correct collision normal', () => {
      const result = CollisionDetector.detectSphereSphere(
        { x: 0, y: 0, z: 0 },
        5,
        { x: 8, y: 0, z: 0 },
        5
      );

      expect(result?.normal.x).toBeCloseTo(1, 5);  // Points toward sphere 2
      expect(result?.normal.y).toBeCloseTo(0, 5);
      expect(result?.normal.z).toBeCloseTo(0, 5);
    });

    it('should calculate collision point between spheres', () => {
      const result = CollisionDetector.detectSphereSphere(
        { x: 0, y: 0, z: 0 },
        5,
        { x: 8, y: 0, z: 0 },
        5
      );

      // Point should be at surface of sphere 1, toward sphere 2
      expect(result?.point.x).toBeGreaterThan(3);
      expect(result?.point.x).toBeLessThan(5);
    });

    it('should handle sphere at same position', () => {
      const result = CollisionDetector.detectSphereSphere(
        { x: 0, y: 0, z: 0 },
        5,
        { x: 0, y: 0, z: 0 },
        5
      );

      expect(result?.collided).toBe(true);
      expect(result?.penetrationDepth).toBeCloseTo(10, 5);  // Full overlap
    });
  });

  describe('Sphere vs AABB Collision', () => {
    it('should detect collision when sphere overlaps box', () => {
      const result = CollisionDetector.detectSphereAABB(
        { x: 0, y: 0, z: 0 },  // Sphere center
        5,                      // Sphere radius
        { x: 3, y: -2, z: -2 }, // Box min
        { x: 10, y: 2, z: 2 }   // Box max
      );

      expect(result).toBeDefined();
      expect(result?.collided).toBe(true);
    });

    it('should not detect collision when sphere and box are separated', () => {
      const result = CollisionDetector.detectSphereAABB(
        { x: 0, y: 0, z: 0 },
        5,
        { x: 10, y: 0, z: 0 },  // Box far away
        { x: 15, y: 5, z: 5 }
      );

      expect(result).toBeNull();
    });

    it('should detect collision when sphere center is inside box', () => {
      const result = CollisionDetector.detectSphereAABB(
        { x: 5, y: 0, z: 0 },  // Center inside box
        3,
        { x: 0, y: -5, z: -5 },
        { x: 10, y: 5, z: 5 }
      );

      expect(result).toBeDefined();
      expect(result?.collided).toBe(true);
    });

    it('should calculate correct normal for face collision', () => {
      const result = CollisionDetector.detectSphereAABB(
        { x: -3, y: 0, z: 0 },  // Sphere approaching from left
        5,
        { x: 0, y: -2, z: -2 },
        { x: 10, y: 2, z: 2 }
      );

      // Normal should point left (negative X)
      expect(result?.normal.x).toBeLessThan(0);
    });
  });

  describe('AABB vs AABB Collision', () => {
    it('should detect collision when boxes overlap', () => {
      const result = CollisionDetector.detectAABBAABB(
        { x: 0, y: 0, z: 0 },
        { x: 10, y: 10, z: 10 },
        { x: 5, y: 5, z: 5 },
        { x: 15, y: 15, z: 15 }
      );

      expect(result).toBeDefined();
      expect(result?.collided).toBe(true);
    });

    it('should not detect collision when boxes are separated', () => {
      const result = CollisionDetector.detectAABBAABB(
        { x: 0, y: 0, z: 0 },
        { x: 10, y: 10, z: 10 },
        { x: 15, y: 0, z: 0 },
        { x: 25, y: 10, z: 10 }
      );

      expect(result).toBeNull();
    });

    it('should calculate smallest penetration depth', () => {
      const result = CollisionDetector.detectAABBAABB(
        { x: 0, y: 0, z: 0 },
        { x: 10, y: 10, z: 10 },
        { x: 8, y: 2, z: 2 },  // 2m overlap in X, 8m in Y and Z
        { x: 15, y: 15, z: 15 }
      );

      // Should use X axis as separation (smallest overlap)
      expect(result?.penetrationDepth).toBeCloseTo(2, 5);
      expect(Math.abs(result!.normal.x)).toBeCloseTo(1, 5);
      expect(result!.normal.y).toBeCloseTo(0, 5);
    });

    it('should calculate collision point at center of overlap', () => {
      const result = CollisionDetector.detectAABBAABB(
        { x: 0, y: 0, z: 0 },
        { x: 10, y: 10, z: 10 },
        { x: 5, y: 5, z: 5 },
        { x: 15, y: 15, z: 15 }
      );

      // Overlap region is from (5,5,5) to (10,10,10), center at (7.5,7.5,7.5)
      expect(result?.point.x).toBeCloseTo(7.5, 5);
      expect(result?.point.y).toBeCloseTo(7.5, 5);
      expect(result?.point.z).toBeCloseTo(7.5, 5);
    });
  });

  describe('Continuous Collision Detection (Sweep)', () => {
    it('should detect collision along movement path', () => {
      const result = CollisionDetector.sweepSphereSphere(
        { center: { x: 0, y: 0, z: 0 }, radius: 2 },
        { x: -10, y: 0, z: 0 },  // Start
        { x: 10, y: 0, z: 0 },   // End
        { center: { x: 0, y: 0, z: 0 }, radius: 3 }
      );

      expect(result).toBeDefined();
      expect(result?.collided).toBe(true);
      expect(result?.timeOfImpact).toBeGreaterThan(0);
      expect(result?.timeOfImpact).toBeLessThan(1);
    });

    it('should not detect collision when paths miss', () => {
      const result = CollisionDetector.sweepSphereSphere(
        { center: { x: 0, y: 0, z: 0 }, radius: 2 },
        { x: -10, y: 10, z: 0 },  // Start above
        { x: 10, y: 10, z: 0 },   // End above
        { center: { x: 0, y: 0, z: 0 }, radius: 3 }
      );

      expect(result).toBeNull();
    });

    it('should calculate time of impact correctly', () => {
      const result = CollisionDetector.sweepSphereSphere(
        { center: { x: 0, y: 0, z: 0 }, radius: 2 },
        { x: -10, y: 0, z: 0 },
        { x: 10, y: 0, z: 0 },
        { center: { x: 0, y: 0, z: 0 }, radius: 3 }
      );

      // Should hit when center-to-center distance = radius1 + radius2 = 5
      // Starting at -10, moving to 10 (20m total)
      // Hits at distance 5 from center, so at x=-5
      // That's 5m into the 20m path = t=0.25
      expect(result?.timeOfImpact).toBeCloseTo(0.25, 2);
    });

    it('should not detect collision that already happened', () => {
      // Start already past the static sphere
      const result = CollisionDetector.sweepSphereSphere(
        { center: { x: 0, y: 0, z: 0 }, radius: 2 },
        { x: 10, y: 0, z: 0 },
        { x: 20, y: 0, z: 0 },
        { center: { x: 0, y: 0, z: 0 }, radius: 3 }
      );

      expect(result).toBeNull();  // Collision is in the past (negative t)
    });
  });

  describe('Octree Spatial Partitioning', () => {
    let octree: Octree;
    let bodies: CelestialBody[];

    beforeEach(() => {
      const bounds: AABB = {
        min: { x: -1000, y: -1000, z: -1000 },
        max: { x: 1000, y: 1000, z: 1000 }
      };
      octree = new Octree(bounds);

      // Create test bodies
      bodies = [
        {
          id: 'body1',
          name: 'Body 1',
          type: 'asteroid',
          mass: 100,
          radius: 5,
          position: { x: 0, y: 0, z: 0 },
          velocity: { x: 0, y: 0, z: 0 },
          radarCrossSection: 10,
          thermalSignature: 50,
          collisionDamage: 10,
          hardness: 100
        },
        {
          id: 'body2',
          name: 'Body 2',
          type: 'asteroid',
          mass: 100,
          radius: 5,
          position: { x: 500, y: 0, z: 0 },
          velocity: { x: 0, y: 0, z: 0 },
          radarCrossSection: 10,
          thermalSignature: 50,
          collisionDamage: 10,
          hardness: 100
        },
        {
          id: 'body3',
          name: 'Body 3',
          type: 'asteroid',
          mass: 100,
          radius: 5,
          position: { x: -500, y: 500, z: 0 },
          velocity: { x: 0, y: 0, z: 0 },
          radarCrossSection: 10,
          thermalSignature: 50,
          collisionDamage: 10,
          hardness: 100
        }
      ];

      for (const body of bodies) {
        octree.insert(body);
      }
    });

    it('should insert and query bodies', () => {
      const queryRegion: AABB = {
        min: { x: -100, y: -100, z: -100 },
        max: { x: 100, y: 100, z: 100 }
      };

      const results = octree.query(queryRegion);

      expect(results.length).toBeGreaterThan(0);
      expect(results.some(b => b.id === 'body1')).toBe(true);
    });

    it('should query by radius', () => {
      const results = octree.queryRadius({ x: 0, y: 0, z: 0 }, 100);

      expect(results.length).toBeGreaterThan(0);
      expect(results.some(b => b.id === 'body1')).toBe(true);
      expect(results.some(b => b.id === 'body2')).toBe(false);  // Too far
    });

    it('should only return bodies in queried region', () => {
      const queryRegion: AABB = {
        min: { x: 400, y: -100, z: -100 },
        max: { x: 600, y: 100, z: 100 }
      };

      const results = octree.query(queryRegion);

      expect(results.some(b => b.id === 'body2')).toBe(true);
      expect(results.some(b => b.id === 'body1')).toBe(false);
      expect(results.some(b => b.id === 'body3')).toBe(false);
    });

    it('should handle empty queries', () => {
      const queryRegion: AABB = {
        min: { x: 2000, y: 2000, z: 2000 },  // Outside world bounds
        max: { x: 3000, y: 3000, z: 3000 }
      };

      const results = octree.query(queryRegion);

      expect(results.length).toBe(0);
    });
  });

  describe('Collision System Integration', () => {
    let collisionSystem: CollisionSystem;
    let bodies: CelestialBody[];

    beforeEach(() => {
      const bounds: AABB = {
        min: { x: -1000, y: -1000, z: -1000 },
        max: { x: 1000, y: 1000, z: 1000 }
      };
      collisionSystem = new CollisionSystem(bounds);

      bodies = [
        {
          id: 'ship',
          name: 'Ship',
          type: 'satellite',
          mass: 5000,
          radius: 5,
          position: { x: 0, y: 0, z: 0 },
          velocity: { x: 0, y: 0, z: 0 },
          radarCrossSection: 10,
          thermalSignature: 100,
          collisionDamage: 50,
          hardness: 200
        },
        {
          id: 'asteroid1',
          name: 'Asteroid 1',
          type: 'asteroid',
          mass: 100,
          radius: 3,
          position: { x: 7, y: 0, z: 0 },  // Just touching (5+3=8, distance=7)
          velocity: { x: 0, y: 0, z: 0 },
          radarCrossSection: 5,
          thermalSignature: 50,
          collisionDamage: 10,
          hardness: 100
        },
        {
          id: 'asteroid2',
          name: 'Asteroid 2',
          type: 'asteroid',
          mass: 100,
          radius: 3,
          position: { x: 100, y: 0, z: 0 },  // Far away
          velocity: { x: 0, y: 0, z: 0 },
          radarCrossSection: 5,
          thermalSignature: 50,
          collisionDamage: 10,
          hardness: 100
        }
      ];

      collisionSystem.rebuild(bodies);
    });

    it('should detect collision between two bodies', () => {
      const result = collisionSystem.checkCollision(bodies[0], bodies[1]);

      expect(result).toBeDefined();
      expect(result?.collided).toBe(true);
    });

    it('should not detect collision between separated bodies', () => {
      const result = collisionSystem.checkCollision(bodies[0], bodies[2]);

      expect(result).toBeNull();
    });

    it('should find all collisions for a body', () => {
      const pairs = collisionSystem.findCollisions(bodies[0], bodies);

      expect(pairs.length).toBe(1);  // Only asteroid1 is colliding
      expect(pairs[0].bodyB.id).toBe('asteroid1');
    });

    it('should query nearby bodies using octree', () => {
      const nearby = collisionSystem.queryNearby({ x: 0, y: 0, z: 0 }, 50);

      expect(nearby.length).toBeGreaterThan(0);
      expect(nearby.some(b => b.id === 'ship')).toBe(true);
      expect(nearby.some(b => b.id === 'asteroid1')).toBe(true);
      expect(nearby.some(b => b.id === 'asteroid2')).toBe(false);  // Too far
    });

    it('should respect collision enabled flag', () => {
      bodies[1].collisionEnabled = false;
      collisionSystem.rebuild(bodies);

      const pairs = collisionSystem.findCollisions(bodies[0], bodies);

      expect(pairs.length).toBe(0);  // asteroid1 disabled
    });

    it('should check sweep collision', () => {
      const result = collisionSystem.checkSweep(
        bodies[0],
        { x: -20, y: 0, z: 0 },
        { x: 20, y: 0, z: 0 },
        bodies[1]
      );

      expect(result).toBeDefined();
      expect(result?.collided).toBe(true);
      expect(result?.timeOfImpact).toBeGreaterThan(0);
    });
  });

  describe('Edge Cases', () => {
    it('should handle zero-radius spheres', () => {
      const result = CollisionDetector.detectSphereSphere(
        { x: 0, y: 0, z: 0 },
        0,
        { x: 0, y: 0, z: 0 },
        5
      );

      expect(result).toBeDefined();
      expect(result?.collided).toBe(true);
    });

    it('should handle very small penetration depths', () => {
      const result = CollisionDetector.detectSphereSphere(
        { x: 0, y: 0, z: 0 },
        5,
        { x: 9.999, y: 0, z: 0 },  // Almost touching
        5
      );

      expect(result).toBeDefined();
      expect(result?.penetrationDepth).toBeLessThan(0.01);
    });

    it('should handle grazing collisions', () => {
      const result = CollisionDetector.sweepSphereSphere(
        { center: { x: 0, y: 0, z: 0 }, radius: 2 },
        { x: -10, y: 4.9, z: 0 },  // Just barely grazes
        { x: 10, y: 4.9, z: 0 },
        { center: { x: 0, y: 0, z: 0 }, radius: 3 }
      );

      expect(result).toBeDefined();
      expect(result?.collided).toBe(true);
    });
  });
});
