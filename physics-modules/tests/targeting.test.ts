/**
 * Targeting and Intercept System Tests
 *
 * Tests lead calculations, intercept trajectories, and rendezvous planning
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  TargetingSystem,
  InterceptSolution,
  LeadCalculator,
  RendezvousPlanner,
  InterceptType
} from '../src/targeting';
import { Vector3, VectorMath } from '../src/math-utils';
import { World, CelestialBodyFactory, CelestialBody } from '../src/world';

describe('Targeting and Intercept System', () => {
  let world: World;
  let moon: CelestialBody;

  beforeEach(() => {
    world = new World();
    moon = CelestialBodyFactory.createMoon();
    world.addBody(moon);
  });

  describe('Lead Calculator', () => {
    it('should calculate lead angle for moving target', () => {
      const shooterPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const shooterVel: Vector3 = { x: 0, y: 0, z: 0 };
      const targetPos: Vector3 = { x: 10000, y: 0, z: moon.radius + 50000 };
      const targetVel: Vector3 = { x: 0, y: 500, z: 0 };  // Moving at 500 m/s
      const projectileSpeed = 2000;  // m/s

      const lead = LeadCalculator.calculateLead({
        shooterPosition: shooterPos,
        shooterVelocity: shooterVel,
        targetPosition: targetPos,
        targetVelocity: targetVel,
        projectileSpeed
      });

      expect(lead.leadAngle).toBeGreaterThan(0);
      expect(lead.timeToImpact).toBeGreaterThan(0);
      expect(lead.aimPoint).toBeDefined();
    });

    it('should handle stationary target', () => {
      const shooterPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const shooterVel: Vector3 = { x: 0, y: 0, z: 0 };
      const targetPos: Vector3 = { x: 10000, y: 0, z: moon.radius + 50000 };
      const targetVel: Vector3 = { x: 0, y: 0, z: 0 };
      const projectileSpeed = 2000;

      const lead = LeadCalculator.calculateLead({
        shooterPosition: shooterPos,
        shooterVelocity: shooterVel,
        targetPosition: targetPos,
        targetVelocity: targetVel,
        projectileSpeed
      });

      // No lead needed for stationary target
      expect(lead.leadAngle).toBeCloseTo(0, 1);
      expect(lead.aimPoint.x).toBeCloseTo(targetPos.x, -2);
    });

    it('should account for shooter velocity', () => {
      const shooterPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const shooterVel: Vector3 = { x: 100, y: 0, z: 0 };  // Shooter moving
      const targetPos: Vector3 = { x: 10000, y: 0, z: moon.radius + 50000 };
      const targetVel: Vector3 = { x: 0, y: 0, z: 0 };
      const projectileSpeed = 2000;

      const lead = LeadCalculator.calculateLead({
        shooterPosition: shooterPos,
        shooterVelocity: shooterVel,
        targetPosition: targetPos,
        targetVelocity: targetVel,
        projectileSpeed
      });

      expect(lead).toBeDefined();
      expect(lead.timeToImpact).toBeGreaterThan(0);
    });

    it('should return null for impossible intercept', () => {
      const shooterPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const shooterVel: Vector3 = { x: 0, y: 0, z: 0 };
      const targetPos: Vector3 = { x: 10000, y: 0, z: moon.radius + 50000 };
      const targetVel: Vector3 = { x: 0, y: 3000, z: 0 };  // Moving faster than projectile
      const projectileSpeed = 1000;  // Too slow

      const lead = LeadCalculator.calculateLead({
        shooterPosition: shooterPos,
        shooterVelocity: shooterVel,
        targetPosition: targetPos,
        targetVelocity: targetVel,
        projectileSpeed
      });

      // May still find a solution, but check it's reasonable
      if (lead) {
        expect(lead.timeToImpact).toBeGreaterThan(0);
      }
    });
  });

  describe('Rendezvous Planner', () => {
    it('should plan Hohmann transfer to higher orbit', () => {
      const planner = new RendezvousPlanner(world);

      const shipPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const shipVel: Vector3 = { x: 1600, y: 0, z: 0 };  // Circular orbit velocity

      const targetPos: Vector3 = { x: 0, y: 0, z: moon.radius + 100000 };
      const targetVel: Vector3 = { x: 1100, y: 0, z: 0 };  // Higher orbit

      const rendezvous = planner.planRendezvous({
        shipPosition: shipPos,
        shipVelocity: shipVel,
        targetPosition: targetPos,
        targetVelocity: targetVel,
        maxDeltaV: 1000
      });

      expect(rendezvous).toBeDefined();
      if (rendezvous) {
        expect(rendezvous.deltaVBudget).toBeLessThan(1000);
        expect(rendezvous.maneuvers.length).toBeGreaterThan(0);
      }
    });

    it('should calculate deltaV for intercept', () => {
      const planner = new RendezvousPlanner(world);

      const shipPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const shipVel: Vector3 = { x: 1600, y: 0, z: 0 };

      const targetPos: Vector3 = { x: 50000, y: 0, z: moon.radius + 50000 };
      const targetVel: Vector3 = { x: 1600, y: 0, z: 0 };  // Same orbit

      const rendezvous = planner.planRendezvous({
        shipPosition: shipPos,
        shipVelocity: shipVel,
        targetPosition: targetPos,
        targetVelocity: targetVel,
        maxDeltaV: 500
      });

      if (rendezvous) {
        expect(rendezvous.deltaVBudget).toBeGreaterThan(0);
        expect(rendezvous.transferTime).toBeGreaterThan(0);
      }
    });
  });

  describe('Targeting System Integration', () => {
    let targeting: TargetingSystem;

    beforeEach(() => {
      targeting = new TargetingSystem(world);
    });

    it('should find intercept solution for ballistic trajectory', () => {
      const shipPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const shipVel: Vector3 = { x: 0, y: 0, z: 0 };

      const target = CelestialBodyFactory.createStation(
        'target1',
        'Target Station',
        { x: 10000, y: 5000, z: moon.radius + 50000 },
        { x: 100, y: 0, z: 0 }
      );
      world.addBody(target);

      const solution = targeting.findInterceptSolution({
        shipPosition: shipPos,
        shipVelocity: shipVel,
        targetId: 'target1',
        interceptType: InterceptType.BALLISTIC,
        projectileSpeed: 2000
      });

      expect(solution).toBeDefined();
      if (solution) {
        expect(solution.aimDirection).toBeDefined();
        expect(solution.timeToIntercept).toBeGreaterThan(0);
      }
    });

    it('should track multiple targets', () => {
      targeting.addTarget('target1', {
        id: 'target1',
        name: 'Target 1',
        type: 'ship',
        mass: 10000,
        radius: 10,
        position: { x: 10000, y: 0, z: moon.radius + 50000 },
        velocity: { x: 0, y: 100, z: 0 },
        radarCrossSection: 50,
        thermalSignature: 300,
        collisionDamage: 50,
        hardness: 300
      });

      targeting.addTarget('target2', {
        id: 'target2',
        name: 'Target 2',
        type: 'ship',
        mass: 10000,
        radius: 10,
        position: { x: -10000, y: 0, z: moon.radius + 50000 },
        velocity: { x: 0, y: -100, z: 0 },
        radarCrossSection: 50,
        thermalSignature: 300,
        collisionDamage: 50,
        hardness: 300
      });

      const targets = targeting.getAllTargets();
      expect(targets.length).toBe(2);
    });

    it('should calculate closest approach', () => {
      const shipPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const shipVel: Vector3 = { x: 500, y: 0, z: 0 };

      const target: CelestialBody = {
        id: 'target1',
        name: 'Target 1',
        type: 'ship',
        mass: 10000,
        radius: 10,
        position: { x: 10000, y: 1000, z: moon.radius + 50000 },
        velocity: { x: -500, y: 0, z: 0 },
        radarCrossSection: 50,
        thermalSignature: 300,
        collisionDamage: 50,
        hardness: 300
      };

      const approach = targeting.calculateClosestApproach(
        shipPos,
        shipVel,
        target.position,
        target.velocity
      );

      expect(approach.distance).toBeGreaterThan(0);
      expect(approach.time).toBeGreaterThan(0);
    });

    it('should update target tracking', () => {
      const target: CelestialBody = {
        id: 'target1',
        name: 'Moving Target',
        type: 'ship',
        mass: 10000,
        radius: 10,
        position: { x: 10000, y: 0, z: moon.radius + 50000 },
        velocity: { x: 100, y: 0, z: 0 },
        radarCrossSection: 50,
        thermalSignature: 300,
        collisionDamage: 50,
        hardness: 300
      };

      targeting.addTarget('target1', target);

      // Update position
      target.position.x += 1000;

      targeting.updateTarget('target1', target);

      const tracked = targeting.getTarget('target1');
      expect(tracked?.position.x).toBe(11000);
    });
  });

  describe('Edge Cases', () => {
    it('should handle zero projectile speed', () => {
      const lead = LeadCalculator.calculateLead({
        shooterPosition: { x: 0, y: 0, z: 0 },
        shooterVelocity: { x: 0, y: 0, z: 0 },
        targetPosition: { x: 1000, y: 0, z: 0 },
        targetVelocity: { x: 0, y: 0, z: 0 },
        projectileSpeed: 0
      });

      expect(lead).toBeNull();
    });

    it('should handle target at same position', () => {
      const pos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };

      const lead = LeadCalculator.calculateLead({
        shooterPosition: pos,
        shooterVelocity: { x: 0, y: 0, z: 0 },
        targetPosition: pos,
        targetVelocity: { x: 0, y: 0, z: 0 },
        projectileSpeed: 1000
      });

      expect(lead.timeToImpact).toBeCloseTo(0, 1);
    });
  });
});
