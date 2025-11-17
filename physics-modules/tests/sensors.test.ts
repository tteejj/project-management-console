/**
 * Sensor Systems Tests
 *
 * Tests radar, thermal IR, LIDAR, and mass detector physics
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  SensorSystem,
  RadarSensor,
  ThermalSensor,
  LIDARSensor,
  MassDetector,
  SensorContact,
  SensorType,
  RadarBand
} from '../src/sensors';
import { CelestialBodyFactory, World, CelestialBody } from '../src/world';
import { Vector3, VectorMath } from '../src/math-utils';

describe('Sensor Systems', () => {
  let world: World;
  let moon: CelestialBody;

  beforeEach(() => {
    world = new World();
    moon = CelestialBodyFactory.createMoon();
    world.addBody(moon);
  });

  describe('Radar Sensor', () => {
    it('should detect target within range', () => {
      const radar = new RadarSensor({
        maxRange: 100000,        // 100km
        band: RadarBand.X_BAND,
        power: 100000,           // 100 kW
        antennaGain: 40,         // dB
        noiseFloor: -110         // dBm
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const targetPos: Vector3 = { x: 0, y: 0, z: moon.radius + 80000 };

      const target = CelestialBodyFactory.createStation(
        'station1',
        'Station Alpha',
        targetPos,
        { x: 0, y: 0, z: 0 }
      );
      world.addBody(target);

      const contacts = radar.scan(observerPos, world, moon);
      expect(contacts.length).toBeGreaterThan(0);
      expect(contacts[0].bodyId).toBe('station1');
    });

    it('should not detect target beyond max range', () => {
      const radar = new RadarSensor({
        maxRange: 10000,         // 10km only
        band: RadarBand.X_BAND,
        power: 10000,
        antennaGain: 30,
        noiseFloor: -110
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const targetPos: Vector3 = { x: 0, y: 0, z: moon.radius + 100000 };

      const target = CelestialBodyFactory.createStation(
        'station1',
        'Station Alpha',
        targetPos,
        { x: 0, y: 0, z: 0 }
      );
      world.addBody(target);

      const contacts = radar.scan(observerPos, world, moon);
      const stationContacts = contacts.filter(c => c.bodyId === 'station1');
      expect(stationContacts.length).toBe(0);
    });

    it('should calculate radar range using radar equation', () => {
      const radar = new RadarSensor({
        maxRange: 200000,
        band: RadarBand.X_BAND,
        power: 100000,
        antennaGain: 40,
        noiseFloor: -110
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const targetPos: Vector3 = { x: 0, y: 0, z: moon.radius + 60000 };

      const target = CelestialBodyFactory.createStation(
        'station1',
        'Station Alpha',
        targetPos,
        { x: 0, y: 0, z: 0 }
      );
      world.addBody(target);

      const contacts = radar.scan(observerPos, world, moon);
      expect(contacts[0].signalStrength).toBeGreaterThan(-110);  // Above noise floor
    });

    it('should reduce detection with lower RCS', () => {
      const radar = new RadarSensor({
        maxRange: 100000,
        band: RadarBand.X_BAND,
        power: 50000,
        antennaGain: 35,
        noiseFloor: -110
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };

      // High RCS target
      const targetPos1: Vector3 = { x: 10000, y: 0, z: moon.radius + 80000 };
      const target1: CelestialBody = {
        id: 'large-station',
        name: 'Large Station',
        type: 'station',
        mass: 100000,
        radius: 50,
        position: targetPos1,
        velocity: { x: 0, y: 0, z: 0 },
        radarCrossSection: 1000,     // Large RCS
        thermalSignature: 300,
        collisionDamage: 100,
        hardness: 500
      };

      // Low RCS target (stealth)
      const targetPos2: Vector3 = { x: -10000, y: 0, z: moon.radius + 80000 };
      const target2: CelestialBody = {
        id: 'stealth-ship',
        name: 'Stealth Ship',
        type: 'ship',
        mass: 10000,
        radius: 20,
        position: targetPos2,
        velocity: { x: 0, y: 0, z: 0 },
        radarCrossSection: 0.1,      // Very low RCS (stealth)
        thermalSignature: 200,
        collisionDamage: 50,
        hardness: 300
      };

      world.addBody(target1);
      world.addBody(target2);

      const contacts = radar.scan(observerPos, world, moon);

      const largeContact = contacts.find(c => c.bodyId === 'large-station');
      const stealthContact = contacts.find(c => c.bodyId === 'stealth-ship');

      expect(largeContact).toBeDefined();

      if (largeContact && stealthContact) {
        expect(largeContact.signalStrength).toBeGreaterThan(stealthContact.signalStrength);
      }
    });
  });

  describe('Thermal Sensor', () => {
    it('should detect hot objects', () => {
      const thermal = new ThermalSensor({
        maxRange: 50000,
        sensitivity: 0.1,        // Can detect 0.1K difference
        fov: 90                  // 90 degree field of view
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const targetPos: Vector3 = { x: 0, y: 0, z: moon.radius + 70000 };

      const target: CelestialBody = {
        id: 'hot-station',
        name: 'Hot Station',
        type: 'station',
        mass: 50000,
        radius: 30,
        position: targetPos,
        velocity: { x: 0, y: 0, z: 0 },
        radarCrossSection: 500,
        thermalSignature: 400,   // Hot (400K)
        collisionDamage: 50,
        hardness: 400
      };
      world.addBody(target);

      const contacts = thermal.scan(observerPos, world, moon);
      expect(contacts.length).toBeGreaterThan(0);
      expect(contacts[0].bodyId).toBe('hot-station');
    });

    it('should not detect cold objects at long range', () => {
      const thermal = new ThermalSensor({
        maxRange: 50000,
        sensitivity: 1.0,        // Lower sensitivity
        fov: 90
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const targetPos: Vector3 = { x: 0, y: 0, z: moon.radius + 100000 };

      const target: CelestialBody = {
        id: 'cold-ship',
        name: 'Cold Ship',
        type: 'ship',
        mass: 10000,
        radius: 10,
        position: targetPos,
        velocity: { x: 0, y: 0, z: 0 },
        radarCrossSection: 50,
        thermalSignature: 280,   // Close to background (2.7K cosmic + moon ~250K)
        collisionDamage: 30,
        hardness: 300
      };
      world.addBody(target);

      const contacts = thermal.scan(observerPos, world, moon);
      const coldContacts = contacts.filter(c => c.bodyId === 'cold-ship');
      expect(coldContacts.length).toBe(0);
    });

    it('should calculate apparent temperature with inverse square law', () => {
      const thermal = new ThermalSensor({
        maxRange: 100000,
        sensitivity: 0.1,
        fov: 120
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };

      // Same target at different distances
      const nearPos: Vector3 = { x: 5000, y: 0, z: moon.radius + 55000 };
      const farPos: Vector3 = { x: -5000, y: 0, z: moon.radius + 90000 };

      const nearTarget: CelestialBody = {
        id: 'near',
        name: 'Near',
        type: 'ship',
        mass: 10000,
        radius: 10,
        position: nearPos,
        velocity: { x: 0, y: 0, z: 0 },
        radarCrossSection: 50,
        thermalSignature: 350,
        collisionDamage: 30,
        hardness: 300
      };

      const farTarget: CelestialBody = {
        id: 'far',
        name: 'Far',
        type: 'ship',
        mass: 10000,
        radius: 10,
        position: farPos,
        velocity: { x: 0, y: 0, z: 0 },
        radarCrossSection: 50,
        thermalSignature: 350,   // Same temp
        collisionDamage: 30,
        hardness: 300
      };

      world.addBody(nearTarget);
      world.addBody(farTarget);

      const contacts = thermal.scan(observerPos, world, moon);

      const nearContact = contacts.find(c => c.bodyId === 'near');
      const farContact = contacts.find(c => c.bodyId === 'far');

      if (nearContact && farContact) {
        expect(nearContact.signalStrength).toBeGreaterThan(farContact.signalStrength);
      }
    });
  });

  describe('LIDAR Sensor', () => {
    it('should detect objects and measure range accurately', () => {
      const lidar = new LIDARSensor({
        maxRange: 10000,
        angularResolution: 0.1,  // degrees
        rangeResolution: 0.1     // meters
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 5000 };
      const targetPos: Vector3 = { x: 0, y: 0, z: moon.radius + 7000 };

      const target = CelestialBodyFactory.createAsteroid(
        'asteroid1',
        targetPos,
        { x: 0, y: 0, z: 0 },
        1000,
        5
      );
      world.addBody(target);

      const contacts = lidar.scan(observerPos, world, moon);
      expect(contacts.length).toBeGreaterThan(0);

      const distance = VectorMath.distance(observerPos, targetPos);
      expect(contacts[0].range).toBeCloseTo(distance, 0);
    });

    it('should not detect beyond max range', () => {
      const lidar = new LIDARSensor({
        maxRange: 1000,
        angularResolution: 0.1,
        rangeResolution: 0.1
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 5000 };
      const targetPos: Vector3 = { x: 0, y: 0, z: moon.radius + 10000 };

      const target = CelestialBodyFactory.createAsteroid(
        'asteroid1',
        targetPos,
        { x: 0, y: 0, z: 0 },
        1000,
        5
      );
      world.addBody(target);

      const contacts = lidar.scan(observerPos, world, moon);
      const asteroidContacts = contacts.filter(c => c.bodyId === 'asteroid1');
      expect(asteroidContacts.length).toBe(0);
    });

    it('should provide high-precision ranging', () => {
      const lidar = new LIDARSensor({
        maxRange: 10000,
        angularResolution: 0.01,
        rangeResolution: 0.01
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 5000 };
      const targetPos: Vector3 = { x: 100, y: 50, z: moon.radius + 5500 };

      const target = CelestialBodyFactory.createDebris(
        'debris1',
        targetPos,
        { x: 0, y: 0, z: 0 },
        10,
        0.5
      );
      world.addBody(target);

      const contacts = lidar.scan(observerPos, world, moon);
      const actualRange = VectorMath.distance(observerPos, targetPos);

      expect(contacts[0].range).toBeCloseTo(actualRange, 1);
    });
  });

  describe('Mass Detector', () => {
    it('should detect massive objects via gravitational anomalies', () => {
      const massDetector = new MassDetector({
        sensitivity: 1e-8,       // Can detect tiny g-force changes
        maxRange: 100000
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };

      // Add a massive hidden object (dense asteroid, black hole, etc.)
      const anomalyPos: Vector3 = { x: 30000, y: 0, z: moon.radius + 50000 };
      const anomaly: CelestialBody = {
        id: 'hidden-mass',
        name: 'Dense Asteroid',
        type: 'asteroid',
        mass: 1e15,              // Very massive
        radius: 100,             // But small
        position: anomalyPos,
        velocity: { x: 0, y: 0, z: 0 },
        radarCrossSection: 1,    // Low radar signature
        thermalSignature: 250,   // Cold (hard to detect thermally)
        collisionDamage: 1000,
        hardness: 1000
      };
      world.addBody(anomaly);

      const contacts = massDetector.scan(observerPos, world, moon);
      expect(contacts.length).toBeGreaterThan(0);
      expect(contacts.some(c => c.bodyId === 'hidden-mass')).toBe(true);
    });

    it('should not detect low-mass objects', () => {
      const massDetector = new MassDetector({
        sensitivity: 1e-6,       // Lower sensitivity
        maxRange: 50000
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const targetPos: Vector3 = { x: 10000, y: 0, z: moon.radius + 55000 };

      const target = CelestialBodyFactory.createDebris(
        'debris1',
        targetPos,
        { x: 0, y: 0, z: 0 },
        100,              // 100kg (very low mass)
        1
      );
      world.addBody(target);

      const contacts = massDetector.scan(observerPos, world, moon);
      const debrisContacts = contacts.filter(c => c.bodyId === 'debris1');
      expect(debrisContacts.length).toBe(0);
    });
  });

  describe('Sensor System Integration', () => {
    let sensorSystem: SensorSystem;
    let observerPos: Vector3;

    beforeEach(() => {
      sensorSystem = new SensorSystem();
      observerPos = { x: 0, y: 0, z: moon.radius + 50000 };

      // Add sensors
      sensorSystem.addSensor('radar-1', new RadarSensor({
        maxRange: 100000,
        band: RadarBand.X_BAND,
        power: 100000,
        antennaGain: 40,
        noiseFloor: -110
      }));

      sensorSystem.addSensor('thermal-1', new ThermalSensor({
        maxRange: 50000,
        sensitivity: 0.5,
        fov: 90
      }));

      sensorSystem.addSensor('lidar-1', new LIDARSensor({
        maxRange: 10000,
        angularResolution: 0.1,
        rangeResolution: 0.1
      }));
    });

    it('should combine contacts from multiple sensors', () => {
      const targetPos: Vector3 = { x: 0, y: 0, z: moon.radius + 55000 };
      const target = CelestialBodyFactory.createStation(
        'station1',
        'Station Alpha',
        targetPos,
        { x: 0, y: 0, z: 0 }
      );
      world.addBody(target);

      const allContacts = sensorSystem.scanAll(observerPos, world, moon);

      // Should be detected by radar, thermal, and LIDAR
      const stationContacts = allContacts.filter(c => c.bodyId === 'station1');
      expect(stationContacts.length).toBeGreaterThan(0);
    });

    it('should track sensor power states', () => {
      sensorSystem.setSensorPower('radar-1', false);
      expect(sensorSystem.isSensorActive('radar-1')).toBe(false);

      sensorSystem.setSensorPower('radar-1', true);
      expect(sensorSystem.isSensorActive('radar-1')).toBe(true);
    });
  });

  describe('Edge Cases', () => {
    it('should handle observer at same position as target', () => {
      const radar = new RadarSensor({
        maxRange: 100000,
        band: RadarBand.X_BAND,
        power: 100000,
        antennaGain: 40,
        noiseFloor: -110
      });

      const pos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const target = CelestialBodyFactory.createStation(
        'station1',
        'Station Alpha',
        pos,
        { x: 0, y: 0, z: 0 }
      );
      world.addBody(target);

      const contacts = radar.scan(pos, world, moon);
      // Should either detect with infinite signal or filter out self
      expect(contacts).toBeDefined();
    });

    it('should handle zero RCS target', () => {
      const radar = new RadarSensor({
        maxRange: 100000,
        band: RadarBand.X_BAND,
        power: 100000,
        antennaGain: 40,
        noiseFloor: -110
      });

      const observerPos: Vector3 = { x: 0, y: 0, z: moon.radius + 50000 };
      const targetPos: Vector3 = { x: 0, y: 0, z: moon.radius + 60000 };

      const target: CelestialBody = {
        id: 'invisible',
        name: 'Perfect Stealth',
        type: 'ship',
        mass: 10000,
        radius: 10,
        position: targetPos,
        velocity: { x: 0, y: 0, z: 0 },
        radarCrossSection: 0,    // Perfect stealth
        thermalSignature: 250,
        collisionDamage: 30,
        hardness: 300
      };
      world.addBody(target);

      const contacts = radar.scan(observerPos, world, moon);
      const invisibleContacts = contacts.filter(c => c.bodyId === 'invisible');
      expect(invisibleContacts.length).toBe(0);
    });
  });
});
