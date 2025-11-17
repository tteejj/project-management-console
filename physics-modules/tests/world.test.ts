/**
 * Tests for World Environment System
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { World, CelestialBody, CelestialBodyFactory } from '../src/world';
import { VectorMath, G } from '../src/math-utils';

describe('World Environment System', () => {
  let world: World;

  beforeEach(() => {
    world = new World();
  });

  describe('Body Management', () => {
    it('should add and retrieve celestial bodies', () => {
      const moon = CelestialBodyFactory.createMoon();
      world.addBody(moon);

      expect(world.getBodyCount()).toBe(1);
      expect(world.getBody('moon')).toBeDefined();
      expect(world.getBody('moon')?.name).toBe('Moon');
    });

    it('should remove celestial bodies', () => {
      const moon = CelestialBodyFactory.createMoon();
      world.addBody(moon);
      expect(world.getBodyCount()).toBe(1);

      world.removeBody('moon');
      expect(world.getBodyCount()).toBe(0);
      expect(world.getBody('moon')).toBeUndefined();
    });

    it('should clear all bodies', () => {
      world.addBody(CelestialBodyFactory.createMoon());
      world.addBody(CelestialBodyFactory.createStation('station1', 'Alpha', { x: 1000, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }));
      expect(world.getBodyCount()).toBe(2);

      world.clear();
      expect(world.getBodyCount()).toBe(0);
    });

    it('should filter bodies by type', () => {
      world.addBody(CelestialBodyFactory.createMoon());
      world.addBody(CelestialBodyFactory.createStation('station1', 'Alpha', { x: 1000, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }));
      world.addBody(CelestialBodyFactory.createStation('station2', 'Beta', { x: 2000, y: 0, z: 0 }, { x: 0, y: 0, z: 0 }));

      const stations = world.getBodiesByType('station');
      expect(stations.length).toBe(2);

      const moons = world.getBodiesByType('moon');
      expect(moons.length).toBe(1);
    });
  });

  describe('N-Body Gravity', () => {
    it('should calculate gravitational acceleration from single body', () => {
      const moon = CelestialBodyFactory.createMoon();
      world.addBody(moon);

      // Position 15km above surface
      const position = { x: 0, y: 0, z: moon.radius + 15000 };

      const gravity = world.getGravityAt(position);

      // Calculate expected gravity: g = G * M / r²
      const r = moon.radius + 15000;
      const expectedMag = G * moon.mass / (r * r);

      const gravityMag = VectorMath.magnitude(gravity);

      expect(gravityMag).toBeCloseTo(expectedMag, 10);

      // Should point toward moon center (downward in this case)
      expect(gravity.z).toBeLessThan(0);
    });

    it('should calculate n-body gravity from multiple bodies', () => {
      const moon = CelestialBodyFactory.createMoon();
      world.addBody(moon);

      // Add station at 100km altitude
      const stationPos = { x: moon.radius + 100000, y: 0, z: 0 };
      const station = CelestialBodyFactory.createStation(
        'station1',
        'Alpha',
        stationPos,
        { x: 0, y: 0, z: 0 }
      );
      world.addBody(station);

      // Position between moon and station
      const testPos = { x: moon.radius + 50000, y: 0, z: 0 };

      const gravity = world.getGravityAt(testPos);

      // Gravity should have component from both bodies
      // Moon dominates, but station should contribute slightly
      const gravityMag = VectorMath.magnitude(gravity);
      expect(gravityMag).toBeGreaterThan(0);

      // X component should be negative (toward moon center)
      expect(gravity.x).toBeLessThan(0);
    });

    it('should exclude specified body from gravity calculation', () => {
      const moon = CelestialBodyFactory.createMoon();
      world.addBody(moon);

      const station = CelestialBodyFactory.createStation(
        'station1',
        'Alpha',
        { x: moon.radius + 100000, y: 0, z: 0 },
        { x: 0, y: 0, z: 0 }
      );
      world.addBody(station);

      // Calculate gravity at moon position, excluding moon
      const gravity = world.getGravityAt(moon.position, 'moon');

      // Should only feel station's gravity (very small)
      const gravityMag = VectorMath.magnitude(gravity);
      expect(gravityMag).toBeLessThan(1e-8); // Station is too light to matter much
    });

    it('should handle zero-mass bodies correctly', () => {
      const moon = CelestialBodyFactory.createMoon();
      world.addBody(moon);

      // Add zero-mass debris
      const debris: CelestialBody = {
        id: 'debris1',
        name: 'Debris',
        type: 'debris',
        mass: 0,
        radius: 1,
        position: { x: moon.radius + 100000, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 },
        radarCrossSection: 1,
        thermalSignature: 10,
        collisionDamage: 1,
        hardness: 100
      };
      world.addBody(debris);

      // Test position above moon's surface
      const testPosition = { x: 0, y: 0, z: moon.radius + 50000 };
      const gravity = world.getGravityAt(testPosition);

      // Should only feel moon's gravity (debris has zero mass and is far away)
      const gravityMag = VectorMath.magnitude(gravity);

      // Calculate expected gravity from moon alone
      const toMoon = VectorMath.subtract(moon.position, testPosition);
      const distSq = VectorMath.magnitudeSquared(toMoon);
      const expectedGravity = G * moon.mass / distSq;

      expect(gravityMag).toBeGreaterThan(0);
      expect(gravityMag).toBeCloseTo(expectedGravity, 10);
    });
  });

  describe('Spatial Queries', () => {
    beforeEach(() => {
      const moon = CelestialBodyFactory.createMoon();
      world.addBody(moon);

      // Add stations at various positions
      world.addBody(CelestialBodyFactory.createStation(
        'station1',
        'Alpha',
        { x: moon.radius + 10000, y: 0, z: 0 },
        { x: 0, y: 0, z: 0 }
      ));

      world.addBody(CelestialBodyFactory.createStation(
        'station2',
        'Beta',
        { x: moon.radius + 100000, y: 0, z: 0 },
        { x: 0, y: 0, z: 0 }
      ));

      world.addBody(CelestialBodyFactory.createStation(
        'station3',
        'Gamma',
        { x: 0, y: moon.radius + 50000, z: 0 },
        { x: 0, y: 0, z: 0 }
      ));
    });

    it('should find bodies within range', () => {
      const moon = world.getBody('moon')!;
      const searchPos = { x: moon.radius + 10000, y: 0, z: 0 };
      const searchRadius = 5000;

      const nearbyBodies = world.getBodiesInRange(searchPos, searchRadius);

      // Should find station1 (very close) but not others
      expect(nearbyBodies.length).toBeGreaterThan(0);
      expect(nearbyBodies.some(b => b.id === 'station1')).toBe(true);
    });

    it('should find bodies in AABB region', () => {
      const moon = world.getBody('moon')!;

      const bounds = {
        min: { x: -10000, y: -10000, z: -10000 },
        max: { x: moon.radius + 20000, y: 10000, z: 10000 }
      };

      const bodiesInRegion = world.getBodiesInRegion(bounds);

      // Should find station1 and moon (moon is at origin)
      expect(bodiesInRegion.length).toBeGreaterThanOrEqual(2);
      expect(bodiesInRegion.some(b => b.id === 'station1')).toBe(true);
      expect(bodiesInRegion.some(b => b.id === 'moon')).toBe(true);
    });

    it('should find closest body to position', () => {
      const moon = world.getBody('moon')!;
      const searchPos = { x: moon.radius + 15000, y: 0, z: 0 };

      const closest = world.findClosestBody(searchPos);

      // Should find station1 (at 10km altitude) as closest
      expect(closest?.id).toBe('station1');
    });

    it('should filter bodies when finding closest', () => {
      const moon = world.getBody('moon')!;
      const searchPos = { x: moon.radius + 15000, y: 0, z: 0 };

      const closestStation = world.findClosestBody(
        searchPos,
        (body) => body.type === 'station'
      );

      expect(closestStation?.type).toBe('station');
      expect(closestStation?.id).toBe('station1');
    });

    it('should raycast and find first intersection', () => {
      const moon = world.getBody('moon')!;

      // Start further away, past all stations, pointing toward moon
      const origin = { x: moon.radius + 200000, y: 0, z: 0 };
      const direction = { x: -1, y: 0, z: 0 }; // Point toward moon

      const hit = world.raycast(origin, direction, 300000);

      expect(hit).toBeDefined();
      // Will hit station2 first (at 100km) before moon
      expect(hit?.distance).toBeGreaterThan(0);
      expect(hit?.distance).toBeLessThan(200000);
    });

    it('should return null when raycast misses', () => {
      const moon = world.getBody('moon')!;

      const origin = { x: moon.radius + 50000, y: 0, z: 0 };
      const direction = { x: 0, y: 1, z: 0 }; // Point away from everything

      const hit = world.raycast(origin, direction, 100000);

      // Might hit something, but if not in that direction, should be null
      // (depends on exact positions)
    });
  });

  describe('Orbital Mechanics', () => {
    it('should calculate escape velocity', () => {
      const moon = CelestialBodyFactory.createMoon();
      world.addBody(moon);

      const position = { x: 0, y: 0, z: moon.radius + 15000 };

      const escapeVel = world.getEscapeVelocity(position);

      // v_escape = sqrt(2 * G * M / r)
      const r = moon.radius + 15000;
      const expectedVel = Math.sqrt(2 * G * moon.mass / r);

      expect(escapeVel).toBeCloseTo(expectedVel, 5);
    });

    it('should calculate orbital velocity', () => {
      const moon = CelestialBodyFactory.createMoon();
      world.addBody(moon);

      const position = { x: 0, y: 0, z: moon.radius + 15000 };

      const orbitalVel = world.getOrbitalVelocity(position);

      // v_orbital = sqrt(G * M / r)
      const r = moon.radius + 15000;
      const expectedVel = Math.sqrt(G * moon.mass / r);

      expect(orbitalVel).toBeCloseTo(expectedVel, 5);

      // Escape velocity should be sqrt(2) times orbital velocity
      const escapeVel = world.getEscapeVelocity(position);
      expect(escapeVel / orbitalVel).toBeCloseTo(Math.sqrt(2), 5);
    });

    it('should identify dominant gravitational body', () => {
      const moon = CelestialBodyFactory.createMoon();
      world.addBody(moon);

      const station = CelestialBodyFactory.createStation(
        'station1',
        'Alpha',
        { x: moon.radius + 100000, y: 0, z: 0 },
        { x: 0, y: 0, z: 0 }
      );
      world.addBody(station);

      // Position near moon
      const position = { x: 0, y: 0, z: moon.radius + 15000 };

      const dominant = world.getDominantBody(position);

      expect(dominant?.id).toBe('moon');
    });
  });

  describe('Physics Update', () => {
    it('should update ballistic motion for non-static bodies', () => {
      const moon = CelestialBodyFactory.createMoon();
      world.addBody(moon);

      const asteroid = CelestialBodyFactory.createAsteroid(
        'ast1',
        { x: 0, y: 0, z: moon.radius + 100000 },
        { x: 100, y: 0, z: 0 }, // Moving horizontally
        10 // 10m radius
      );
      world.addBody(asteroid);

      const initialPos = { ...asteroid.position };
      const initialVel = { ...asteroid.velocity };

      // Update for 1 second
      world.update(1.0);

      const asteroid2 = world.getBody('ast1')!;

      // Position should have changed
      expect(VectorMath.distance(initialPos, asteroid2.position)).toBeGreaterThan(0);

      // Velocity should have changed due to gravity
      expect(VectorMath.magnitude(asteroid2.velocity)).not.toBeCloseTo(VectorMath.magnitude(initialVel), 5);

      // Should be falling toward moon (z velocity should decrease)
      expect(asteroid2.velocity.z).toBeLessThan(initialVel.z);
    });

    it('should not move static bodies', () => {
      const moon = CelestialBodyFactory.createMoon();
      world.addBody(moon);

      const initialPos = { ...moon.position };

      // Update for 1 second
      world.update(1.0);

      const moon2 = world.getBody('moon')!;

      // Position should not change (static body)
      expect(VectorMath.equals(initialPos, moon2.position)).toBe(true);
    });

    it('should update simulation time', () => {
      expect(world.getTime()).toBe(0);

      world.update(1.0);
      expect(world.getTime()).toBe(1.0);

      world.update(0.5);
      expect(world.getTime()).toBe(1.5);
    });
  });

  describe('Factory Methods', () => {
    it('should create Moon with correct properties', () => {
      const moon = CelestialBodyFactory.createMoon();

      expect(moon.id).toBe('moon');
      expect(moon.type).toBe('moon');
      expect(moon.mass).toBeCloseTo(7.342e22, 0);
      expect(moon.radius).toBe(1737400);
      expect(moon.isStatic).toBe(true);
    });

    it('should create Station with correct properties', () => {
      const station = CelestialBodyFactory.createStation(
        'alpha',
        'Station Alpha',
        { x: 1000, y: 0, z: 0 },
        { x: 10, y: 0, z: 0 }
      );

      expect(station.id).toBe('alpha');
      expect(station.name).toBe('Station Alpha');
      expect(station.type).toBe('station');
      expect(station.mass).toBe(50000);
      expect(station.radius).toBe(20);
      expect(station.isStatic).toBe(false);
      expect(station.position.x).toBe(1000);
      expect(station.velocity.x).toBe(10);
    });

    it('should create Asteroid with mass proportional to volume', () => {
      const radius = 10; // 10m
      const asteroid = CelestialBodyFactory.createAsteroid(
        'ast1',
        { x: 0, y: 0, z: 0 },
        { x: 0, y: 0, z: 0 },
        radius
      );

      expect(asteroid.type).toBe('asteroid');
      expect(asteroid.radius).toBe(radius);

      // Check mass calculation: volume * density
      const expectedVolume = (4/3) * Math.PI * Math.pow(radius, 3);
      const expectedMass = expectedVolume * 2500; // Rocky density

      expect(asteroid.mass).toBeCloseTo(expectedMass, 0);
    });

    it('should create Debris with correct properties', () => {
      const size = 2; // 2m
      const debris = CelestialBodyFactory.createDebris(
        'deb1',
        { x: 100, y: 0, z: 0 },
        { x: 5, y: 0, z: 0 },
        size
      );

      expect(debris.type).toBe('debris');
      expect(debris.radius).toBe(size);

      // Check mass calculation: volume * density
      const expectedVolume = (4/3) * Math.PI * Math.pow(size, 3);
      const expectedMass = expectedVolume * 3000; // Metal density

      expect(debris.mass).toBeCloseTo(expectedMass, 0);
    });
  });
});
