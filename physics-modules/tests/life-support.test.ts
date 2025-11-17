/**
 * Life Support System Tests
 *
 * Tests oxygen consumption, CO2 scrubbing, pressure loss, crew health
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  LifeSupportSystem,
  CrewMember,
  CrewStatus,
  LifeSupportConfig
} from '../src/life-support';
import { HullStructure, Compartment, MaterialType } from '../src/hull-damage';

describe('Life Support System', () => {
  describe('Oxygen Consumption', () => {
    it('should consume oxygen based on crew count', () => {
      const hull = new HullStructure({
        compartments: [{
          id: 'bridge',
          name: 'Bridge',
          volume: 100,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const crew: CrewMember[] = [{
        id: 'crew-1',
        name: 'Pilot',
        location: 'bridge',
        health: 1.0,
        oxygenLevel: 1.0,
        status: CrewStatus.HEALTHY
      }, {
        id: 'crew-2',
        name: 'Engineer',
        location: 'bridge',
        health: 1.0,
        oxygenLevel: 1.0,
        status: CrewStatus.HEALTHY
      }];

      const lifeSupport = new LifeSupportSystem(hull, crew, {
        oxygenGenerationRate: 0,  // No generation for this test
        co2ScrubberRate: 0
      });

      const compartment = hull.getCompartment('bridge')!;
      const initialPressure = compartment.pressure;

      // Simulate 1 hour
      lifeSupport.update(3600);

      // Pressure should decrease due to O2 consumption
      expect(compartment.pressure).toBeLessThan(initialPressure);
    });

    it('should track oxygen depletion rate correctly', () => {
      const hull = new HullStructure({
        compartments: [{
          id: 'cabin',
          name: 'Cabin',
          volume: 50,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const crew: CrewMember[] = [{
        id: 'crew-1',
        name: 'Astronaut',
        location: 'cabin',
        health: 1.0,
        oxygenLevel: 1.0,
        status: CrewStatus.HEALTHY
      }];

      const lifeSupport = new LifeSupportSystem(hull, crew, {
        oxygenGenerationRate: 0,
        co2ScrubberRate: 0
      });

      // Human consumes ~0.023 kg O2/hour = 0.0000064 kg/s
      lifeSupport.update(3600);  // 1 hour

      const stats = lifeSupport.getStatistics();
      expect(stats.oxygenConsumed).toBeCloseTo(0.023, 2);  // ~23g per hour
    });
  });

  describe('Life Support Generation', () => {
    it('should generate oxygen when powered', () => {
      const hull = new HullStructure({
        compartments: [{
          id: 'bridge',
          name: 'Bridge',
          volume: 100,
          pressure: 90000,  // Below normal
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const lifeSupport = new LifeSupportSystem(hull, [], {
        oxygenGenerationRate: 0.00001,  // 10g/s
        co2ScrubberRate: 0.00001,
        powered: true
      });

      const compartment = hull.getCompartment('bridge')!;
      const initialPressure = compartment.pressure;

      lifeSupport.update(100);  // 100 seconds

      // Pressure should increase
      expect(compartment.pressure).toBeGreaterThan(initialPressure);
    });

    it('should not generate oxygen when unpowered', () => {
      const hull = new HullStructure({
        compartments: [{
          id: 'bridge',
          name: 'Bridge',
          volume: 100,
          pressure: 90000,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const lifeSupport = new LifeSupportSystem(hull, [], {
        oxygenGenerationRate: 0.00001,
        co2ScrubberRate: 0.00001,
        powered: false  // Unpowered!
      });

      const compartment = hull.getCompartment('bridge')!;
      const initialPressure = compartment.pressure;

      lifeSupport.update(100);

      // Pressure should not change significantly (no crew consuming, no generation)
      expect(Math.abs(compartment.pressure - initialPressure)).toBeLessThan(100);
    });
  });

  describe('Pressure Loss from Breaches', () => {
    it('should lose pressure through breach', () => {
      const hull = new HullStructure({
        compartments: [{
          id: 'hull',
          name: 'Hull',
          volume: 100,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [{
            id: 'breach-1',
            position: { x: 0, y: 0, z: 0 },
            area: 0.01,  // 10cm x 10cm
            sealed: false,
            damageType: 0
          }],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const lifeSupport = new LifeSupportSystem(hull, [], {
        oxygenGenerationRate: 0,
        co2ScrubberRate: 0
      });

      const compartment = hull.getCompartment('hull')!;
      const initialPressure = compartment.pressure;

      lifeSupport.update(60);  // 1 minute

      // Should lose significant pressure
      expect(compartment.pressure).toBeLessThan(initialPressure * 0.9);
    });

    it('should not lose pressure through sealed breach', () => {
      const hull = new HullStructure({
        compartments: [{
          id: 'hull',
          name: 'Hull',
          volume: 100,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [{
            id: 'breach-1',
            position: { x: 0, y: 0, z: 0 },
            area: 0.01,
            sealed: true,  // Sealed!
            damageType: 0
          }],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const lifeSupport = new LifeSupportSystem(hull, [], {
        oxygenGenerationRate: 0,
        co2ScrubberRate: 0
      });

      const compartment = hull.getCompartment('hull')!;
      const initialPressure = compartment.pressure;

      lifeSupport.update(60);

      // Pressure should remain constant
      expect(compartment.pressure).toBe(initialPressure);
    });
  });

  describe('Crew Health', () => {
    it('should detect hypoxia in low pressure', () => {
      const hull = new HullStructure({
        compartments: [{
          id: 'cabin',
          name: 'Cabin',
          volume: 50,
          pressure: 50000,  // 0.5 atm - hypoxic
          atmosphereIntegrity: 0.5,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const crew: CrewMember[] = [{
        id: 'crew-1',
        name: 'Astronaut',
        location: 'cabin',
        health: 1.0,
        oxygenLevel: 1.0,
        status: CrewStatus.HEALTHY
      }];

      const lifeSupport = new LifeSupportSystem(hull, crew, {
        oxygenGenerationRate: 0,
        co2ScrubberRate: 0
      });

      lifeSupport.update(60);  // 1 minute in low pressure

      const crewMember = crew[0];
      expect(crewMember.oxygenLevel).toBeLessThan(1.0);
      expect(crewMember.status).toBe(CrewStatus.HYPOXIA);
    });

    it('should cause unconsciousness in severe hypoxia', () => {
      const hull = new HullStructure({
        compartments: [{
          id: 'cabin',
          name: 'Cabin',
          volume: 50,
          pressure: 20000,  // Very low pressure
          atmosphereIntegrity: 0.2,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const crew: CrewMember[] = [{
        id: 'crew-1',
        name: 'Astronaut',
        location: 'cabin',
        health: 1.0,
        oxygenLevel: 1.0,
        status: CrewStatus.HEALTHY
      }];

      const lifeSupport = new LifeSupportSystem(hull, crew, {
        oxygenGenerationRate: 0,
        co2ScrubberRate: 0
      });

      // Simulate extended exposure
      for (let i = 0; i < 10; i++) {
        lifeSupport.update(10);
      }

      const crewMember = crew[0];
      expect(crewMember.oxygenLevel).toBe(0);
      expect(crewMember.status).toBe(CrewStatus.UNCONSCIOUS);
    });

    it('should recover in normal pressure', () => {
      const hull = new HullStructure({
        compartments: [{
          id: 'cabin',
          name: 'Cabin',
          volume: 50,
          pressure: 101325,  // Normal pressure
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const crew: CrewMember[] = [{
        id: 'crew-1',
        name: 'Astronaut',
        location: 'cabin',
        health: 1.0,
        oxygenLevel: 0.5,  // Low oxygen
        status: CrewStatus.HYPOXIA
      }];

      const lifeSupport = new LifeSupportSystem(hull, crew, {
        oxygenGenerationRate: 0,
        co2ScrubberRate: 0
      });

      lifeSupport.update(120);  // 2 minutes

      const crewMember = crew[0];
      expect(crewMember.oxygenLevel).toBeGreaterThan(0.5);
    });
  });

  describe('Multiple Compartments', () => {
    it('should track different pressures in separate compartments', () => {
      const hull = new HullStructure({
        compartments: [{
          id: 'bridge',
          name: 'Bridge',
          volume: 100,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: []
        }, {
          id: 'engine-room',
          name: 'Engine Room',
          volume: 200,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [{
            id: 'breach-1',
            position: { x: 0, y: 0, z: 0 },
            area: 0.01,
            sealed: false,
            damageType: 0
          }],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const lifeSupport = new LifeSupportSystem(hull, [], {
        oxygenGenerationRate: 0,
        co2ScrubberRate: 0
      });

      lifeSupport.update(60);

      const bridge = hull.getCompartment('bridge')!;
      const engineRoom = hull.getCompartment('engine-room')!;

      // Bridge should maintain pressure
      expect(bridge.pressure).toBe(101325);

      // Engine room should lose pressure
      expect(engineRoom.pressure).toBeLessThan(101325);
    });
  });

  describe('Statistics', () => {
    it('should track total oxygen consumed', () => {
      const hull = new HullStructure({
        compartments: [{
          id: 'cabin',
          name: 'Cabin',
          volume: 100,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const crew: CrewMember[] = [{
        id: 'crew-1',
        name: 'Astronaut',
        location: 'cabin',
        health: 1.0,
        oxygenLevel: 1.0,
        status: CrewStatus.HEALTHY
      }];

      const lifeSupport = new LifeSupportSystem(hull, crew, {
        oxygenGenerationRate: 0,
        co2ScrubberRate: 0
      });

      lifeSupport.update(3600);  // 1 hour

      const stats = lifeSupport.getStatistics();
      expect(stats.oxygenConsumed).toBeGreaterThan(0);
      expect(stats.healthyCrew).toBe(1);
    });
  });
});
