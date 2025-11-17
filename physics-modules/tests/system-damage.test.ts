/**
 * System Damage Integration Tests
 *
 * Tests how hull damage propagates to system failures
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  SystemDamageManager,
  ShipSystem,
  SystemType,
  SystemStatus,
  DamageReport
} from '../src/system-damage';
import { HullStructure, Compartment } from '../src/hull-damage';

describe('System Damage Integration', () => {
  describe('System Health', () => {
    it('should track system integrity', () => {
      const system: ShipSystem = {
        id: 'reactor-1',
        name: 'Main Reactor',
        type: SystemType.POWER,
        compartmentId: 'engine-room',
        integrity: 1.0,
        status: SystemStatus.ONLINE,
        powerDraw: 0,
        operational: true
      };

      const damageManager = new SystemDamageManager({
        systems: [system],
        hull: new HullStructure({
          compartments: [{
            id: 'engine-room',
            name: 'Engine Room',
            volume: 100,
            pressure: 101325,
            atmosphereIntegrity: 1.0,
            structuralIntegrity: 1.0,
            breaches: [],
            systems: [],
            connectedCompartments: []
          }],
          armorLayers: []
        })
      });

      expect(system.integrity).toBe(1.0);
      expect(system.status).toBe(SystemStatus.ONLINE);
    });

    it('should fail system when integrity drops below threshold', () => {
      const system: ShipSystem = {
        id: 'life-support',
        name: 'Life Support',
        type: SystemType.LIFE_SUPPORT,
        compartmentId: 'cabin',
        integrity: 0.3,        // Low integrity
        status: SystemStatus.ONLINE,
        powerDraw: 5,
        operational: true
      };

      const damageManager = new SystemDamageManager({
        systems: [system],
        hull: new HullStructure({
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
        })
      });

      damageManager.update(1);

      // System should fail at low integrity
      expect(system.status).not.toBe(SystemStatus.ONLINE);
    });
  });

  describe('Compartment Damage Propagation', () => {
    it('should damage systems when compartment is breached', () => {
      const sensor: ShipSystem = {
        id: 'radar',
        name: 'Radar Array',
        type: SystemType.SENSORS,
        compartmentId: 'bridge',
        integrity: 1.0,
        status: SystemStatus.ONLINE,
        powerDraw: 2,
        operational: true
      };

      const hull = new HullStructure({
        compartments: [{
          id: 'bridge',
          name: 'Bridge',
          volume: 50,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 0.5,  // Damaged compartment
          breaches: [{
            id: 'breach-1',
            position: { x: 0, y: 0, z: 0 },
            area: 0.1,
            sealed: false,
            damageType: 0
          }],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const damageManager = new SystemDamageManager({
        systems: [sensor],
        hull
      });

      damageManager.update(1);

      // System should take damage from compartment structural failure
      expect(sensor.integrity).toBeLessThan(1.0);
    });

    it('should cascade damage when atmosphere lost', () => {
      const electronics: ShipSystem = {
        id: 'computer',
        name: 'Flight Computer',
        type: SystemType.CONTROL,
        compartmentId: 'cabin',
        integrity: 1.0,
        status: SystemStatus.ONLINE,
        powerDraw: 1,
        operational: true,
        requiresAtmosphere: true  // Sensitive to vacuum
      };

      const hull = new HullStructure({
        compartments: [{
          id: 'cabin',
          name: 'Cabin',
          volume: 50,
          pressure: 5000,            // Very low pressure
          atmosphereIntegrity: 0.05, // 95% atmosphere loss
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const damageManager = new SystemDamageManager({
        systems: [electronics],
        hull
      });

      damageManager.update(10);  // 10 seconds in vacuum

      // Electronics should fail in vacuum
      expect(electronics.status).toBe(SystemStatus.OFFLINE);
    });
  });

  describe('System Dependencies', () => {
    it('should fail dependent systems when power lost', () => {
      const reactor: ShipSystem = {
        id: 'reactor',
        name: 'Reactor',
        type: SystemType.POWER,
        compartmentId: 'engine-room',
        integrity: 0.1,          // Critical damage
        status: SystemStatus.ONLINE,
        powerDraw: 0,
        operational: true
      };

      const lifeSupport: ShipSystem = {
        id: 'life-support',
        name: 'Life Support',
        type: SystemType.LIFE_SUPPORT,
        compartmentId: 'cabin',
        integrity: 1.0,
        status: SystemStatus.ONLINE,
        powerDraw: 5,
        operational: true,
        dependencies: ['reactor']  // Depends on reactor
      };

      const damageManager = new SystemDamageManager({
        systems: [reactor, lifeSupport],
        hull: new HullStructure({
          compartments: [
            {
              id: 'engine-room',
              name: 'Engine Room',
              volume: 100,
              pressure: 101325,
              atmosphereIntegrity: 1.0,
              structuralIntegrity: 1.0,
              breaches: [],
              systems: [],
              connectedCompartments: []
            },
            {
              id: 'cabin',
              name: 'Cabin',
              volume: 50,
              pressure: 101325,
              atmosphereIntegrity: 1.0,
              structuralIntegrity: 1.0,
              breaches: [],
              systems: [],
              connectedCompartments: []
            }
          ],
          armorLayers: []
        })
      });

      damageManager.update(1);

      // Reactor should fail
      expect(reactor.status).not.toBe(SystemStatus.ONLINE);

      // Life support should also fail due to power loss
      expect(lifeSupport.operational).toBe(false);
    });
  });

  describe('Damage Reports', () => {
    it('should generate damage report for failed systems', () => {
      const weapon: ShipSystem = {
        id: 'railgun',
        name: 'Railgun',
        type: SystemType.WEAPONS,
        compartmentId: 'weapons-bay',
        integrity: 0.4,
        status: SystemStatus.DEGRADED,
        powerDraw: 0,
        operational: true
      };

      const damageManager = new SystemDamageManager({
        systems: [weapon],
        hull: new HullStructure({
          compartments: [{
            id: 'weapons-bay',
            name: 'Weapons Bay',
            volume: 50,
            pressure: 101325,
            atmosphereIntegrity: 1.0,
            structuralIntegrity: 1.0,
            breaches: [],
            systems: [],
            connectedCompartments: []
          }],
          armorLayers: []
        })
      });

      const report = damageManager.getDamageReport();

      expect(report.damagedSystems.length).toBeGreaterThan(0);
      expect(report.damagedSystems[0].systemId).toBe('railgun');
    });

    it('should prioritize critical systems in damage report', () => {
      const criticalSystem: ShipSystem = {
        id: 'reactor',
        name: 'Reactor',
        type: SystemType.POWER,
        compartmentId: 'engine-room',
        integrity: 0.3,
        status: SystemStatus.DEGRADED,
        powerDraw: 0,
        operational: true,
        isCritical: true
      };

      const normalSystem: ShipSystem = {
        id: 'lighting',
        name: 'Lighting',
        type: SystemType.UTILITY,
        compartmentId: 'cabin',
        integrity: 0.5,
        status: SystemStatus.DEGRADED,
        powerDraw: 1,
        operational: true,
        isCritical: false
      };

      const damageManager = new SystemDamageManager({
        systems: [normalSystem, criticalSystem],
        hull: new HullStructure({
          compartments: [
            {
              id: 'engine-room',
              name: 'Engine Room',
              volume: 100,
              pressure: 101325,
              atmosphereIntegrity: 1.0,
              structuralIntegrity: 1.0,
              breaches: [],
              systems: [],
              connectedCompartments: []
            },
            {
              id: 'cabin',
              name: 'Cabin',
              volume: 50,
              pressure: 101325,
              atmosphereIntegrity: 1.0,
              structuralIntegrity: 1.0,
              breaches: [],
              systems: [],
              connectedCompartments: []
            }
          ],
          armorLayers: []
        })
      });

      const report = damageManager.getDamageReport();

      // Critical system should be first in report
      expect(report.criticalFailures.length).toBeGreaterThan(0);
      expect(report.criticalFailures[0].systemId).toBe('reactor');
    });
  });

  describe('System Degradation', () => {
    it('should reduce system effectiveness at low integrity', () => {
      const thruster: ShipSystem = {
        id: 'rcs-1',
        name: 'RCS Thruster',
        type: SystemType.PROPULSION,
        compartmentId: 'hull',
        integrity: 0.6,          // 60% integrity
        status: SystemStatus.DEGRADED,
        powerDraw: 0.5,
        operational: true
      };

      const damageManager = new SystemDamageManager({
        systems: [thruster],
        hull: new HullStructure({
          compartments: [{
            id: 'hull',
            name: 'Hull',
            volume: 100,
            pressure: 101325,
            atmosphereIntegrity: 1.0,
            structuralIntegrity: 1.0,
            breaches: [],
            systems: [],
            connectedCompartments: []
          }],
          armorLayers: []
        })
      });

      damageManager.update(1);

      // System should be degraded
      expect(thruster.status).toBe(SystemStatus.DEGRADED);

      // Effectiveness should match integrity
      const effectiveness = damageManager.getSystemEffectiveness(thruster.id);
      expect(effectiveness).toBeCloseTo(0.6, 1);
    });
  });
});
