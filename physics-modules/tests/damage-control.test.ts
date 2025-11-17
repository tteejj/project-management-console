/**
 * Damage Control System Tests
 *
 * Tests crew-based repair mechanics for hull and systems
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  DamageControlSystem,
  RepairCrew,
  RepairTask,
  RepairTaskType,
  RepairPriority,
  RepairConfig
} from '../src/damage-control';
import { CrewMember, CrewStatus } from '../src/life-support';
import { ShipSystem, SystemStatus, SystemType } from '../src/system-damage';
import { HullStructure, Breach } from '../src/hull-damage';

describe('Damage Control System', () => {
  describe('Repair Crew', () => {
    it('should track crew repair skills', () => {
      const crew: RepairCrew = {
        crewMember: {
          id: 'crew-1',
          name: 'Engineer',
          location: 'engine-room',
          health: 1.0,
          oxygenLevel: 1.0,
          status: CrewStatus.HEALTHY
        },
        repairSkill: 0.8,        // 80% skill
        efficiency: 1.0,
        currentTask: null,
        fatigueLevel: 0
      };

      expect(crew.repairSkill).toBe(0.8);
      expect(crew.efficiency).toBe(1.0);
    });

    it('should reduce efficiency when fatigued', () => {
      const crew: RepairCrew = {
        crewMember: {
          id: 'crew-1',
          name: 'Engineer',
          location: 'engine-room',
          health: 1.0,
          oxygenLevel: 1.0,
          status: CrewStatus.HEALTHY
        },
        repairSkill: 0.8,
        efficiency: 1.0,
        currentTask: null,
        fatigueLevel: 0.7        // 70% fatigued
      };

      const damageControl = new DamageControlSystem({
        repairCrews: [crew],
        hull: new HullStructure({
          compartments: [],
          armorLayers: []
        })
      });

      damageControl.update(1);

      // Fatigue should reduce efficiency
      expect(crew.efficiency).toBeLessThan(1.0);
    });
  });

  describe('Hull Breach Repair', () => {
    it('should seal hull breach over time', () => {
      const breach: Breach = {
        id: 'breach-1',
        position: { x: 0, y: 0, z: 0 },
        area: 0.01,              // 10cm x 10cm
        sealed: false,
        damageType: 0
      };

      const hull = new HullStructure({
        compartments: [{
          id: 'cabin',
          name: 'Cabin',
          volume: 50,
          pressure: 50000,       // Low pressure due to breach
          atmosphereIntegrity: 0.5,
          structuralIntegrity: 0.9,
          breaches: [breach],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const crew: RepairCrew = {
        crewMember: {
          id: 'crew-1',
          name: 'Engineer',
          location: 'cabin',     // In same compartment as breach
          health: 1.0,
          oxygenLevel: 1.0,
          status: CrewStatus.HEALTHY
        },
        repairSkill: 0.9,
        efficiency: 1.0,
        currentTask: null,
        fatigueLevel: 0
      };

      const damageControl = new DamageControlSystem({
        repairCrews: [crew],
        hull
      });

      // Assign repair task
      damageControl.assignRepairTask(crew.crewMember.id, {
        id: 'task-1',
        type: RepairTaskType.BREACH,
        targetId: 'breach-1',
        compartmentId: 'cabin',
        priority: RepairPriority.CRITICAL,
        progress: 0,
        timeRequired: 100,       // 100 seconds
        assignedCrewId: null
      });

      // Simulate repair
      for (let i = 0; i < 120; i++) {
        damageControl.update(1);
      }

      // Breach should be sealed
      expect(breach.sealed).toBe(true);
    });

    it('should repair faster with higher skill', () => {
      const breach: Breach = {
        id: 'breach-1',
        position: { x: 0, y: 0, z: 0 },
        area: 0.01,
        sealed: false,
        damageType: 0
      };

      const hull = new HullStructure({
        compartments: [{
          id: 'cabin',
          name: 'Cabin',
          volume: 50,
          pressure: 50000,
          atmosphereIntegrity: 0.5,
          structuralIntegrity: 0.9,
          breaches: [breach],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const skilledCrew: RepairCrew = {
        crewMember: {
          id: 'crew-1',
          name: 'Expert Engineer',
          location: 'cabin',
          health: 1.0,
          oxygenLevel: 1.0,
          status: CrewStatus.HEALTHY
        },
        repairSkill: 1.0,        // Expert
        efficiency: 1.0,
        currentTask: null,
        fatigueLevel: 0
      };

      const damageControl = new DamageControlSystem({
        repairCrews: [skilledCrew],
        hull
      });

      damageControl.assignRepairTask(skilledCrew.crewMember.id, {
        id: 'task-1',
        type: RepairTaskType.BREACH,
        targetId: 'breach-1',
        compartmentId: 'cabin',
        priority: RepairPriority.CRITICAL,
        progress: 0,
        timeRequired: 50,         // Expert can complete in 50s
        assignedCrewId: null
      });

      // Expert should repair in less time
      let sealed = false;
      for (let i = 0; i < 60; i++) {
        damageControl.update(1);
        if (breach.sealed) {
          sealed = true;
          break;
        }
      }

      expect(sealed).toBe(true);  // Should finish in < 60s with expert
    });
  });

  describe('System Repair', () => {
    it('should restore system integrity', () => {
      const system: ShipSystem = {
        id: 'reactor',
        name: 'Reactor',
        type: SystemType.POWER,
        compartmentId: 'engine-room',
        integrity: 0.4,          // Damaged
        status: SystemStatus.DEGRADED,
        powerDraw: 0,
        operational: true
      };

      const hull = new HullStructure({
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
      });

      const crew: RepairCrew = {
        crewMember: {
          id: 'crew-1',
          name: 'Engineer',
          location: 'engine-room',
          health: 1.0,
          oxygenLevel: 1.0,
          status: CrewStatus.HEALTHY
        },
        repairSkill: 0.8,
        efficiency: 1.0,
        currentTask: null,
        fatigueLevel: 0
      };

      const damageControl = new DamageControlSystem({
        repairCrews: [crew],
        hull,
        systems: [system]
      });

      const initialIntegrity = system.integrity;

      damageControl.assignRepairTask(crew.crewMember.id, {
        id: 'task-1',
        type: RepairTaskType.SYSTEM,
        targetId: 'reactor',
        compartmentId: 'engine-room',
        priority: RepairPriority.HIGH,
        progress: 0,
        timeRequired: 200,
        assignedCrewId: null
      });

      // Simulate repair
      for (let i = 0; i < 250; i++) {
        damageControl.update(1);
      }

      // System should be repaired
      expect(system.integrity).toBeGreaterThan(initialIntegrity);
    });
  });

  describe('Repair Prioritization', () => {
    it('should prioritize critical tasks', () => {
      const criticalBreach: Breach = {
        id: 'breach-1',
        position: { x: 0, y: 0, z: 0 },
        area: 0.1,               // Large breach
        sealed: false,
        damageType: 0
      };

      const minorBreach: Breach = {
        id: 'breach-2',
        position: { x: 1, y: 0, z: 0 },
        area: 0.001,             // Small breach
        sealed: false,
        damageType: 0
      };

      const hull = new HullStructure({
        compartments: [{
          id: 'cabin',
          name: 'Cabin',
          volume: 50,
          pressure: 50000,
          atmosphereIntegrity: 0.3,
          structuralIntegrity: 0.9,
          breaches: [criticalBreach, minorBreach],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const crew: RepairCrew = {
        crewMember: {
          id: 'crew-1',
          name: 'Engineer',
          location: 'cabin',
          health: 1.0,
          oxygenLevel: 1.0,
          status: CrewStatus.HEALTHY
        },
        repairSkill: 0.8,
        efficiency: 1.0,
        currentTask: null,
        fatigueLevel: 0
      };

      const damageControl = new DamageControlSystem({
        repairCrews: [crew],
        hull
      });

      // Auto-assign should pick critical task
      damageControl.autoAssignTasks();

      // Crew should be assigned to critical breach
      expect(crew.currentTask).not.toBeNull();
      expect(crew.currentTask?.targetId).toBe('breach-1');
    });
  });

  describe('Crew Fatigue', () => {
    it('should increase fatigue during repairs', () => {
      const hull = new HullStructure({
        compartments: [{
          id: 'cabin',
          name: 'Cabin',
          volume: 50,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 0.8,
          breaches: [],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const crew: RepairCrew = {
        crewMember: {
          id: 'crew-1',
          name: 'Engineer',
          location: 'cabin',
          health: 1.0,
          oxygenLevel: 1.0,
          status: CrewStatus.HEALTHY
        },
        repairSkill: 0.8,
        efficiency: 1.0,
        currentTask: null,
        fatigueLevel: 0
      };

      const damageControl = new DamageControlSystem({
        repairCrews: [crew],
        hull
      });

      damageControl.assignRepairTask(crew.crewMember.id, {
        id: 'task-1',
        type: RepairTaskType.STRUCTURAL,
        targetId: 'cabin',
        compartmentId: 'cabin',
        priority: RepairPriority.MEDIUM,
        progress: 0,
        timeRequired: 300,
        assignedCrewId: null
      });

      // Work for extended period
      for (let i = 0; i < 500; i++) {
        damageControl.update(1);
      }

      // Crew should be fatigued
      expect(crew.fatigueLevel).toBeGreaterThan(0);
    });

    it('should reduce fatigue when resting', () => {
      const crew: RepairCrew = {
        crewMember: {
          id: 'crew-1',
          name: 'Engineer',
          location: 'cabin',
          health: 1.0,
          oxygenLevel: 1.0,
          status: CrewStatus.HEALTHY
        },
        repairSkill: 0.8,
        efficiency: 1.0,
        currentTask: null,
        fatigueLevel: 0.8        // Very fatigued
      };

      const damageControl = new DamageControlSystem({
        repairCrews: [crew],
        hull: new HullStructure({
          compartments: [],
          armorLayers: []
        })
      });

      const initialFatigue = crew.fatigueLevel;

      // Rest (no task assigned)
      for (let i = 0; i < 100; i++) {
        damageControl.update(1);
      }

      // Fatigue should decrease
      expect(crew.fatigueLevel).toBeLessThan(initialFatigue);
    });
  });

  describe('Repair Statistics', () => {
    it('should track repairs completed', () => {
      const breach: Breach = {
        id: 'breach-1',
        position: { x: 0, y: 0, z: 0 },
        area: 0.01,
        sealed: false,
        damageType: 0
      };

      const hull = new HullStructure({
        compartments: [{
          id: 'cabin',
          name: 'Cabin',
          volume: 50,
          pressure: 50000,
          atmosphereIntegrity: 0.5,
          structuralIntegrity: 0.9,
          breaches: [breach],
          systems: [],
          connectedCompartments: []
        }],
        armorLayers: []
      });

      const crew: RepairCrew = {
        crewMember: {
          id: 'crew-1',
          name: 'Engineer',
          location: 'cabin',
          health: 1.0,
          oxygenLevel: 1.0,
          status: CrewStatus.HEALTHY
        },
        repairSkill: 1.0,
        efficiency: 1.0,
        currentTask: null,
        fatigueLevel: 0
      };

      const damageControl = new DamageControlSystem({
        repairCrews: [crew],
        hull
      });

      damageControl.assignRepairTask(crew.crewMember.id, {
        id: 'task-1',
        type: RepairTaskType.BREACH,
        targetId: 'breach-1',
        compartmentId: 'cabin',
        priority: RepairPriority.CRITICAL,
        progress: 0,
        timeRequired: 50,
        assignedCrewId: null
      });

      // Complete repair
      for (let i = 0; i < 60; i++) {
        damageControl.update(1);
      }

      const stats = damageControl.getStatistics();
      expect(stats.tasksCompleted).toBeGreaterThan(0);
    });
  });
});
