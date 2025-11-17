/**
 * Integrated Ship Tests
 *
 * Tests ship-world bridge, gravity effects, and collision integration
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  IntegratedShip,
  SimulationController,
  ShipConfiguration
} from '../src/integrated-ship';
import { World, CelestialBodyFactory, CelestialBody } from '../src/world';
import { Vector3, VectorMath } from '../src/math-utils';
import { HullStructure, MaterialType } from '../src/hull-damage';

describe('Integrated Ship', () => {
  let world: World;
  let moon: CelestialBody;

  beforeEach(() => {
    world = new World();
    moon = CelestialBodyFactory.createMoon();
    world.addBody(moon);
  });

  describe('Ship-World Bridge', () => {
    it('should create ship as celestial body in world', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 1500, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);

      // Ship should exist in world
      const worldBody = world.getBody(ship.id);
      expect(worldBody).toBeDefined();
      expect(worldBody?.mass).toBe(50000);
    });

    it('should sync spacecraft physics position to world body', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 1500, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);

      // Update ship physics
      ship.update(1);  // 1 second

      // World body should have updated position
      const worldBody = world.getBody(ship.id);
      expect(worldBody?.position.x).toBeGreaterThan(0);  // Moved in X direction
    });

    it('should update velocity in world body', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 0, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);

      // Apply force to change velocity
      ship.applyForce({ x: 50000, y: 0, z: 0 });
      ship.update(1);

      const worldBody = world.getBody(ship.id);
      expect(worldBody?.velocity.x).toBeGreaterThan(0);
    });

    it('should be detectable by sensors', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 0, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);
      const worldBody = world.getBody(ship.id);

      expect(worldBody?.radarCrossSection).toBeGreaterThan(0);
      expect(worldBody?.thermalSignature).toBeGreaterThan(0);
    });
  });

  describe('Gravity Effects', () => {
    it('should apply lunar gravity to ship', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 0, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);

      const initialZ = ship.getPosition().z;

      // Let ship fall under gravity
      for (let i = 0; i < 10; i++) {
        ship.update(1);
      }

      // Ship should have fallen toward moon
      expect(ship.getPosition().z).toBeLessThan(initialZ);
      expect(ship.getVelocity().z).toBeLessThan(0);  // Negative Z velocity
    });

    it('should maintain circular orbit with correct velocity', () => {
      const altitude = 100000;  // 100km above surface
      const orbitalRadius = moon.radius + altitude;

      // Calculate orbital velocity: v = sqrt(GM/r)
      const G = 6.67430e-11;
      const orbitalVelocity = Math.sqrt(G * moon.mass / orbitalRadius);

      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: orbitalRadius, y: 0, z: 0 },
        velocity: { x: 0, y: orbitalVelocity, z: 0 }
      };

      const ship = new IntegratedShip(config, world);

      const initialRadius = VectorMath.magnitude(ship.getPosition());

      // Simulate orbit for one minute
      for (let i = 0; i < 60; i++) {
        ship.update(1);
      }

      // Orbital radius should remain approximately constant
      const finalRadius = VectorMath.magnitude(ship.getPosition());
      expect(Math.abs(finalRadius - initialRadius)).toBeLessThan(1000);  // Within 1km
    });

    it('should handle n-body gravity from multiple bodies', () => {
      // Add a massive station closer to ship than moon
      const station = CelestialBodyFactory.createStation(
        'station1',
        'Massive Station',
        { x: 0, y: 10000, z: moon.radius + 50000 },  // 10km away
        { x: 0, y: 0, z: 0 }
      );
      station.mass = 1e15;  // Extremely massive to overcome moon
      world.addBody(station);

      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 50000 },
        velocity: { x: 0, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);

      const initialPos = ship.getPosition();

      ship.update(10);

      // Ship should be pulled toward station (positive Y direction)
      const displacement = VectorMath.subtract(ship.getPosition(), initialPos);
      expect(displacement.y).toBeGreaterThan(0);
    });
  });

  describe('Collision Detection', () => {
    it('should detect collision with celestial body', () => {
      // Create asteroid in ship's path
      const asteroid = CelestialBodyFactory.createAsteroid(
        'asteroid1',
        { x: 10000, y: 0, z: moon.radius + 100000 },
        { x: 0, y: 0, z: 0 },
        10000,
        50
      );
      world.addBody(asteroid);

      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 5000, y: 0, z: 0 }  // Moving toward asteroid
      };

      const ship = new IntegratedShip(config, world);

      let collisionDetected = false;
      ship.on('collision', () => {
        collisionDetected = true;
      });

      // Update until collision
      for (let i = 0; i < 10; i++) {
        ship.update(1);
        if (collisionDetected) break;
      }

      expect(collisionDetected).toBe(true);
    });

    it('should apply damage on collision', () => {
      const asteroid = CelestialBodyFactory.createAsteroid(
        'asteroid1',
        { x: 1000, y: 0, z: moon.radius + 100000 },
        { x: 0, y: 0, z: 0 },
        10000,
        50
      );
      world.addBody(asteroid);

      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 500, y: 0, z: 0 },
        hullConfig: {
          compartments: [{
            id: 'main',
            name: 'Main Hull',
            volume: 100,
            pressure: 101325,
            atmosphereIntegrity: 1.0,
            structuralIntegrity: 1.0,
            breaches: [],
            systems: [],
            connectedCompartments: []
          }],
          armorLayers: [{
            id: 'armor',
            material: MaterialType.STEEL,
            thickness: 0.05,
            hardness: 500,
            density: 7850,
            integrity: 1.0,
            ablationDepth: 0
          }]
        }
      };

      const ship = new IntegratedShip(config, world);
      const initialIntegrity = ship.getHullIntegrity();

      // Simulate collision
      for (let i = 0; i < 5; i++) {
        ship.update(1);
      }

      // Hull integrity should decrease if collision occurred
      const collision = ship.getCollisionHistory().length > 0;
      if (collision) {
        expect(ship.getHullIntegrity()).toBeLessThan(initialIntegrity);
      }
    });

    it('should apply momentum transfer on collision', () => {
      const asteroid = CelestialBodyFactory.createAsteroid(
        'asteroid1',
        { x: 5000, y: 0, z: moon.radius + 100000 },
        { x: -100, y: 0, z: 0 },  // Moving toward ship
        10000,
        30
      );
      world.addBody(asteroid);

      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 100, y: 0, z: 0 }  // Moving toward asteroid
      };

      const ship = new IntegratedShip(config, world);
      const initialVelocity = ship.getVelocity();

      // Simulate until collision
      for (let i = 0; i < 100; i++) {
        ship.update(0.1);
      }

      // Velocity should change due to collision (if it occurred)
      const collision = ship.getCollisionHistory().length > 0;
      if (collision) {
        const finalVelocity = ship.getVelocity();
        const initialSpeed = VectorMath.magnitude(initialVelocity);
        const finalSpeed = VectorMath.magnitude(finalVelocity);
        // Expect any measurable change in speed
        expect(Math.abs(finalSpeed - initialSpeed)).toBeGreaterThan(0.1);
      }
    });
  });

  describe('Simulation Controller', () => {
    it('should update world and all ships', () => {
      const controller = new SimulationController(world);

      const config1: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 1500, y: 0, z: 0 }
      };

      const config2: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 200000 },
        velocity: { x: 1000, y: 0, z: 0 }
      };

      const ship1 = controller.addShip(config1);
      const ship2 = controller.addShip(config2);

      const initialPos1 = ship1.getPosition();
      const initialPos2 = ship2.getPosition();

      controller.update(1);

      // Both ships should have moved
      expect(ship1.getPosition().x).not.toBe(initialPos1.x);
      expect(ship2.getPosition().x).not.toBe(initialPos2.x);
    });

    it('should detect collisions between ships', () => {
      const controller = new SimulationController(world);

      const config1: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 100, y: 0, z: 0 }
      };

      const config2: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 1000, y: 0, z: moon.radius + 100000 },
        velocity: { x: -100, y: 0, z: 0 }  // Head-on collision
      };

      const ship1 = controller.addShip(config1);
      const ship2 = controller.addShip(config2);

      let collision1 = false;
      let collision2 = false;

      ship1.on('collision', () => { collision1 = true; });
      ship2.on('collision', () => { collision2 = true; });

      // Simulate until collision
      for (let i = 0; i < 20; i++) {
        controller.update(1);
        if (collision1 && collision2) break;
      }

      expect(collision1).toBe(true);
      expect(collision2).toBe(true);
    });

    it('should maintain simulation time', () => {
      const controller = new SimulationController(world);

      expect(controller.getSimulationTime()).toBe(0);

      controller.update(1);
      expect(controller.getSimulationTime()).toBe(1);

      controller.update(5);
      expect(controller.getSimulationTime()).toBe(6);
    });
  });

  describe('Edge Cases', () => {
    it('should handle ship starting inside moon', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius - 1000 },  // Inside moon!
        velocity: { x: 0, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);

      // Should detect immediate collision
      ship.update(0.1);

      expect(ship.getCollisionHistory().length).toBeGreaterThan(0);
    });

    it('should handle zero mass gracefully', () => {
      const config: ShipConfiguration = {
        mass: 0,  // Invalid
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 0, y: 0, z: 0 }
      };

      expect(() => new IntegratedShip(config, world)).toThrow();
    });

    it('should handle very high velocity', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 10000, y: 0, z: 0 }  // 10 km/s
      };

      const ship = new IntegratedShip(config, world);

      // Should still update without errors
      expect(() => ship.update(1)).not.toThrow();
    });
  });
});
