/**
 * Procedural Generation Tests
 *
 * Tests seeded RNG, asteroid fields, debris clouds, and random body placement
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  SeededRandom,
  ProceduralGenerator,
  AsteroidFieldConfig,
  DebrisCloudConfig,
  StationPlacementConfig
} from '../src/procedural';
import { World } from '../src/world';
import { Vector3 } from '../src/math-utils';

describe('Procedural Generation', () => {
  describe('Seeded Random', () => {
    it('should generate consistent values with same seed', () => {
      const rng1 = new SeededRandom(12345);
      const rng2 = new SeededRandom(12345);

      const values1 = [rng1.next(), rng1.next(), rng1.next()];
      const values2 = [rng2.next(), rng2.next(), rng2.next()];

      expect(values1).toEqual(values2);
    });

    it('should generate different values with different seeds', () => {
      const rng1 = new SeededRandom(12345);
      const rng2 = new SeededRandom(54321);

      const val1 = rng1.next();
      const val2 = rng2.next();

      expect(val1).not.toEqual(val2);
    });

    it('should generate values between 0 and 1', () => {
      const rng = new SeededRandom(12345);

      for (let i = 0; i < 100; i++) {
        const val = rng.next();
        expect(val).toBeGreaterThanOrEqual(0);
        expect(val).toBeLessThan(1);
      }
    });

    it('should generate random integer in range', () => {
      const rng = new SeededRandom(12345);

      for (let i = 0; i < 100; i++) {
        const val = rng.nextInt(10, 20);
        expect(val).toBeGreaterThanOrEqual(10);
        expect(val).toBeLessThanOrEqual(20);
        expect(Number.isInteger(val)).toBe(true);
      }
    });

    it('should generate random float in range', () => {
      const rng = new SeededRandom(12345);

      for (let i = 0; i < 100; i++) {
        const val = rng.nextFloat(5.5, 10.5);
        expect(val).toBeGreaterThanOrEqual(5.5);
        expect(val).toBeLessThan(10.5);
      }
    });

    it('should generate random boolean', () => {
      const rng = new SeededRandom(12345);
      const values = [];

      for (let i = 0; i < 100; i++) {
        values.push(rng.nextBool());
      }

      // Should have both true and false values
      expect(values.some(v => v === true)).toBe(true);
      expect(values.some(v => v === false)).toBe(true);
    });
  });

  describe('Asteroid Field Generation', () => {
    let world: World;
    let generator: ProceduralGenerator;

    beforeEach(() => {
      world = new World();
      generator = new ProceduralGenerator(12345);
    });

    it('should generate asteroid field with correct count', () => {
      const config: AsteroidFieldConfig = {
        count: 50,
        center: { x: 0, y: 0, z: 0 },
        radius: 100000,
        minSize: 1,
        maxSize: 50,
        minMass: 100,
        maxMass: 100000
      };

      const asteroids = generator.generateAsteroidField(config);

      expect(asteroids.length).toBe(50);
    });

    it('should place asteroids within specified radius', () => {
      const center: Vector3 = { x: 10000, y: 5000, z: 15000 };
      const radius = 50000;

      const config: AsteroidFieldConfig = {
        count: 20,
        center,
        radius,
        minSize: 1,
        maxSize: 10,
        minMass: 100,
        maxMass: 10000
      };

      const asteroids = generator.generateAsteroidField(config);

      for (const asteroid of asteroids) {
        const dx = asteroid.position.x - center.x;
        const dy = asteroid.position.y - center.y;
        const dz = asteroid.position.z - center.z;
        const distance = Math.sqrt(dx*dx + dy*dy + dz*dz);

        expect(distance).toBeLessThanOrEqual(radius);
      }
    });

    it('should generate asteroids with sizes in range', () => {
      const config: AsteroidFieldConfig = {
        count: 30,
        center: { x: 0, y: 0, z: 0 },
        radius: 100000,
        minSize: 5,
        maxSize: 25,
        minMass: 1000,
        maxMass: 50000
      };

      const asteroids = generator.generateAsteroidField(config);

      for (const asteroid of asteroids) {
        expect(asteroid.radius).toBeGreaterThanOrEqual(5);
        expect(asteroid.radius).toBeLessThanOrEqual(25);
      }
    });

    it('should generate asteroids with unique IDs', () => {
      const config: AsteroidFieldConfig = {
        count: 20,
        center: { x: 0, y: 0, z: 0 },
        radius: 50000,
        minSize: 1,
        maxSize: 10,
        minMass: 100,
        maxMass: 10000
      };

      const asteroids = generator.generateAsteroidField(config);
      const ids = asteroids.map(a => a.id);
      const uniqueIds = new Set(ids);

      expect(uniqueIds.size).toBe(asteroids.length);
    });

    it('should support velocity variation', () => {
      const config: AsteroidFieldConfig = {
        count: 20,
        center: { x: 0, y: 0, z: 0 },
        radius: 50000,
        minSize: 1,
        maxSize: 10,
        minMass: 100,
        maxMass: 10000,
        velocityVariation: 100  // m/s
      };

      const asteroids = generator.generateAsteroidField(config);

      // At least some asteroids should have non-zero velocity
      const movingAsteroids = asteroids.filter(a =>
        Math.abs(a.velocity.x) > 0 ||
        Math.abs(a.velocity.y) > 0 ||
        Math.abs(a.velocity.z) > 0
      );

      expect(movingAsteroids.length).toBeGreaterThan(0);
    });
  });

  describe('Debris Cloud Generation', () => {
    let generator: ProceduralGenerator;

    beforeEach(() => {
      generator = new ProceduralGenerator(54321);
    });

    it('should generate debris cloud with correct count', () => {
      const config: DebrisCloudConfig = {
        count: 100,
        center: { x: 0, y: 0, z: 0 },
        radius: 10000,
        minSize: 0.1,
        maxSize: 2,
        minMass: 1,
        maxMass: 100
      };

      const debris = generator.generateDebrisCloud(config);

      expect(debris.length).toBe(100);
    });

    it('should generate debris smaller than asteroids', () => {
      const config: DebrisCloudConfig = {
        count: 50,
        center: { x: 0, y: 0, z: 0 },
        radius: 5000,
        minSize: 0.1,
        maxSize: 1.0,
        minMass: 1,
        maxMass: 50
      };

      const debris = generator.generateDebrisCloud(config);

      for (const piece of debris) {
        expect(piece.radius).toBeGreaterThanOrEqual(0.1);
        expect(piece.radius).toBeLessThanOrEqual(1.0);
        expect(piece.mass).toBeGreaterThanOrEqual(1);
        expect(piece.mass).toBeLessThanOrEqual(50);
      }
    });

    it('should place debris within radius', () => {
      const center: Vector3 = { x: 5000, y: -3000, z: 8000 };
      const radius = 2000;

      const config: DebrisCloudConfig = {
        count: 30,
        center,
        radius,
        minSize: 0.1,
        maxSize: 0.5,
        minMass: 1,
        maxMass: 10
      };

      const debris = generator.generateDebrisCloud(config);

      for (const piece of debris) {
        const dx = piece.position.x - center.x;
        const dy = piece.position.y - center.y;
        const dz = piece.position.z - center.z;
        const distance = Math.sqrt(dx*dx + dy*dy + dz*dz);

        expect(distance).toBeLessThanOrEqual(radius);
      }
    });
  });

  describe('Station Placement', () => {
    let generator: ProceduralGenerator;

    beforeEach(() => {
      generator = new ProceduralGenerator(99999);
    });

    it('should place stations at specified positions', () => {
      const config: StationPlacementConfig = {
        count: 5,
        minDistanceFromCenter: 50000,
        maxDistanceFromCenter: 200000,
        center: { x: 0, y: 0, z: 0 },
        orbitalVelocity: 1500
      };

      const stations = generator.generateStations(config);

      expect(stations.length).toBe(5);

      for (const station of stations) {
        const dx = station.position.x;
        const dy = station.position.y;
        const dz = station.position.z;
        const distance = Math.sqrt(dx*dx + dy*dy + dz*dz);

        expect(distance).toBeGreaterThanOrEqual(50000);
        expect(distance).toBeLessThanOrEqual(200000);
      }
    });

    it('should assign orbital velocities to stations', () => {
      const config: StationPlacementConfig = {
        count: 3,
        minDistanceFromCenter: 100000,
        maxDistanceFromCenter: 150000,
        center: { x: 0, y: 0, z: 0 },
        orbitalVelocity: 1200
      };

      const stations = generator.generateStations(config);

      for (const station of stations) {
        const speed = Math.sqrt(
          station.velocity.x ** 2 +
          station.velocity.y ** 2 +
          station.velocity.z ** 2
        );

        // Should have approximately orbital velocity
        expect(speed).toBeGreaterThan(0);
        expect(speed).toBeLessThan(2000);  // Reasonable upper bound
      }
    });
  });

  describe('Procedural Generation Integration', () => {
    it('should populate world with procedural content', () => {
      const world = new World();
      const generator = new ProceduralGenerator(42);

      const asteroids = generator.generateAsteroidField({
        count: 10,
        center: { x: 0, y: 0, z: 0 },
        radius: 50000,
        minSize: 5,
        maxSize: 20,
        minMass: 1000,
        maxMass: 50000
      });

      for (const asteroid of asteroids) {
        world.addBody(asteroid);
      }

      const bodies = world.getAllBodies();
      expect(bodies.length).toBe(10);
    });

    it('should generate consistent content with same seed', () => {
      const gen1 = new ProceduralGenerator(12345);
      const gen2 = new ProceduralGenerator(12345);

      const asteroids1 = gen1.generateAsteroidField({
        count: 5,
        center: { x: 0, y: 0, z: 0 },
        radius: 10000,
        minSize: 1,
        maxSize: 10,
        minMass: 100,
        maxMass: 10000
      });

      const asteroids2 = gen2.generateAsteroidField({
        count: 5,
        center: { x: 0, y: 0, z: 0 },
        radius: 10000,
        minSize: 1,
        maxSize: 10,
        minMass: 100,
        maxMass: 10000
      });

      // Positions should match
      for (let i = 0; i < asteroids1.length; i++) {
        expect(asteroids1[i].position.x).toBeCloseTo(asteroids2[i].position.x, 0);
        expect(asteroids1[i].position.y).toBeCloseTo(asteroids2[i].position.y, 0);
        expect(asteroids1[i].position.z).toBeCloseTo(asteroids2[i].position.z, 0);
      }
    });
  });

  describe('Edge Cases', () => {
    it('should handle zero count gracefully', () => {
      const generator = new ProceduralGenerator(12345);

      const asteroids = generator.generateAsteroidField({
        count: 0,
        center: { x: 0, y: 0, z: 0 },
        radius: 10000,
        minSize: 1,
        maxSize: 10,
        minMass: 100,
        maxMass: 10000
      });

      expect(asteroids.length).toBe(0);
    });

    it('should handle very small radius', () => {
      const generator = new ProceduralGenerator(12345);

      const asteroids = generator.generateAsteroidField({
        count: 5,
        center: { x: 0, y: 0, z: 0 },
        radius: 10,  // Very small
        minSize: 0.1,
        maxSize: 0.5,
        minMass: 1,
        maxMass: 10
      });

      expect(asteroids.length).toBe(5);
    });
  });
});
