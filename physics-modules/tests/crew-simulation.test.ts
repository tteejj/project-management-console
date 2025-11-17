/**
 * Crew Simulation Tests
 *
 * Tests crew health, injuries, medical treatment, skills, stress, and death
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  CrewSimulation,
  CrewMemberState,
  InjuryType,
  BodyPart,
  CrewRole,
  TaskType,
  MedBay
} from '../src/crew-simulation';

describe('Crew Simulation System', () => {
  let simulation: CrewSimulation;

  beforeEach(() => {
    simulation = new CrewSimulation();
  });

  describe('Injury System', () => {
    it('should apply injury and reduce health', () => {
      const crew: CrewMemberState = createHealthyCrew('engineer-1');
      simulation.addCrewMember(crew);

      simulation.applyInjury('engineer-1', {
        type: InjuryType.TRAUMA,
        severity: 0.3,
        bodyPart: BodyPart.LEFT_ARM,
        treated: false,
        stabilized: false
      });

      const injured = simulation.getCrewMember('engineer-1')!;

      expect(injured.injuries.length).toBe(1);
      expect(injured.injuries[0].type).toBe(InjuryType.TRAUMA);
      expect(injured.injuries[0].severity).toBe(0.3);
      expect(injured.health).toBeLessThan(1.0);
    });

    it('should cause incapacitation from severe injury', () => {
      const crew: CrewMemberState = createHealthyCrew('pilot-1');
      simulation.addCrewMember(crew);

      simulation.applyInjury('pilot-1', {
        type: InjuryType.BURNS,
        severity: 0.6,
        bodyPart: BodyPart.TORSO,
        treated: false,
        stabilized: false
      });

      const injured = simulation.getCrewMember('pilot-1')!;

      expect(injured.incapacitated).toBe(true);
      expect(injured.alive).toBe(true);
    });

    it('should cause death from massive injury', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-1');
      simulation.addCrewMember(crew);

      simulation.applyInjury('crew-1', {
        type: InjuryType.TRAUMA,
        severity: 1.0,
        bodyPart: BodyPart.HEAD,
        treated: false,
        stabilized: false
      });

      const dead = simulation.getCrewMember('crew-1')!;

      expect(dead.alive).toBe(false);
      expect(dead.health).toBe(0);
    });

    it('should accumulate environmental damage', () => {
      const crew: CrewMemberState = createHealthyCrew('engineer-2');
      simulation.addCrewMember(crew);

      // Apply radiation damage over time
      for (let i = 0; i < 10; i++) {
        simulation.applyEnvironmentalDamage('engineer-2', InjuryType.RADIATION, 0.05);
      }

      const injured = simulation.getCrewMember('engineer-2')!;

      expect(injured.injuries.length).toBeGreaterThan(0);
      const radInjury = injured.injuries.find(inj => inj.type === InjuryType.RADIATION);
      expect(radInjury).toBeDefined();
      expect(radInjury!.severity).toBeGreaterThan(0.4);
    });
  });

  describe('Medical Treatment', () => {
    it('should treat minor injury with first aid', () => {
      const patient: CrewMemberState = createHealthyCrew('patient-1');
      const doctor: CrewMemberState = createDoctor('doctor-1');

      simulation.addCrewMember(patient);
      simulation.addCrewMember(doctor);

      simulation.applyInjury('patient-1', {
        type: InjuryType.TRAUMA,
        severity: 0.2,
        bodyPart: BodyPart.LEFT_LEG,
        treated: false,
        stabilized: false
      });

      const injury = simulation.getCrewMember('patient-1')!.injuries[0];
      const initialSeverity = injury.severity;

      const success = simulation.treat('patient-1', 'doctor-1', {
        type: 'first_aid',
        targetInjury: injury.id
      });

      expect(success).toBe(true);
      expect(injury.treated).toBe(true);
      expect(injury.severity).toBeLessThan(initialSeverity);
    });

    it('should stabilize critical injury with surgery', () => {
      const patient: CrewMemberState = createHealthyCrew('patient-2');
      const doctor: CrewMemberState = createDoctor('doctor-2');

      simulation.addCrewMember(patient);
      simulation.addCrewMember(doctor);
      simulation.addMedBay({
        id: 'medbay-1',
        compartmentId: 'medical',
        operational: true,
        occupied: false
      });

      simulation.applyInjury('patient-2', {
        type: InjuryType.BURNS,
        severity: 0.8,
        bodyPart: BodyPart.TORSO,
        treated: false,
        stabilized: false
      });

      const injury = simulation.getCrewMember('patient-2')!.injuries[0];

      const success = simulation.treat('patient-2', 'doctor-2', {
        type: 'surgery',
        targetInjury: injury.id
      });

      expect(success).toBe(true);
      expect(injury.stabilized).toBe(true);
      expect(injury.treated).toBe(true);
    });

    it('should reduce stress with medication', () => {
      const patient: CrewMemberState = createHealthyCrew('patient-3');
      patient.stress = 0.8;

      const doctor: CrewMemberState = createDoctor('doctor-3');

      simulation.addCrewMember(patient);
      simulation.addCrewMember(doctor);

      simulation.applyInjury('patient-3', {
        type: InjuryType.TRAUMA,
        severity: 0.3,
        bodyPart: BodyPart.RIGHT_ARM,
        treated: false,
        stabilized: false
      });

      const initialStress = patient.stress;

      simulation.treat('patient-3', 'doctor-3', {
        type: 'medication'
      });

      expect(patient.stress).toBeLessThan(initialStress);
    });

    it('should heal injuries over time when treated', () => {
      const patient: CrewMemberState = createHealthyCrew('patient-4');
      const doctor: CrewMemberState = createDoctor('doctor-4');

      simulation.addCrewMember(patient);
      simulation.addCrewMember(doctor);

      simulation.applyInjury('patient-4', {
        type: InjuryType.TRAUMA,
        severity: 0.2,
        bodyPart: BodyPart.LEFT_ARM,
        treated: false,
        stabilized: false
      });

      const injury = simulation.getCrewMember('patient-4')!.injuries[0];

      simulation.treat('patient-4', 'doctor-4', {
        type: 'first_aid',
        targetInjury: injury.id
      });

      const initialSeverity = injury.severity;

      // Simulate 1 hour of healing
      for (let i = 0; i < 60; i++) {
        simulation.update(60); // 60 seconds per iteration
      }

      const finalInjury = simulation.getCrewMember('patient-4')!.injuries.find(inj => inj.id === injury.id);

      if (finalInjury) {
        expect(finalInjury.severity).toBeLessThan(initialSeverity);
      }
      // else injury healed completely (removed from array)
    });

    it('should fail treatment if incapacitated doctor', () => {
      const patient: CrewMemberState = createHealthyCrew('patient-5');
      const doctor: CrewMemberState = createDoctor('doctor-5');
      doctor.incapacitated = true;

      simulation.addCrewMember(patient);
      simulation.addCrewMember(doctor);

      simulation.applyInjury('patient-5', {
        type: InjuryType.TRAUMA,
        severity: 0.2,
        bodyPart: BodyPart.RIGHT_LEG,
        treated: false,
        stabilized: false
      });

      const injury = simulation.getCrewMember('patient-5')!.injuries[0];

      const success = simulation.treat('patient-5', 'doctor-5', {
        type: 'first_aid',
        targetInjury: injury.id
      });

      expect(success).toBe(false);
      expect(injury.treated).toBe(false);
    });
  });

  describe('Diagnosis System', () => {
    it('should diagnose critical injuries and recommend treatment', () => {
      const patient: CrewMemberState = createHealthyCrew('patient-6');
      simulation.addCrewMember(patient);

      simulation.applyInjury('patient-6', {
        type: InjuryType.BURNS,
        severity: 0.8,
        bodyPart: BodyPart.TORSO,
        treated: false,
        stabilized: false
      });

      const diagnosis = simulation.diagnose('patient-6');

      expect(diagnosis).toBeDefined();
      expect(diagnosis!.criticalInjuries.length).toBe(1);
      expect(diagnosis!.recommendedTreatment.length).toBeGreaterThan(0);
      expect(diagnosis!.recommendedTreatment[0].type).toBe('surgery');
      expect(diagnosis!.timeUntilDeath).toBeDefined();
    });

    it('should calculate time until death for critical injury', () => {
      const patient: CrewMemberState = createHealthyCrew('patient-7');
      simulation.addCrewMember(patient);

      simulation.applyInjury('patient-7', {
        type: InjuryType.TRAUMA,
        severity: 0.9,
        bodyPart: BodyPart.HEAD,
        treated: false,
        stabilized: false
      });

      const diagnosis = simulation.diagnose('patient-7');

      expect(diagnosis!.timeUntilDeath).toBeDefined();
      expect(diagnosis!.timeUntilDeath).toBeGreaterThan(0);
    });
  });

  describe('Skills and Performance', () => {
    it('should calculate effective skill with modifiers', () => {
      const engineer: CrewMemberState = createHealthyCrew('engineer-3');
      engineer.skills.engineering = 80;
      engineer.fatigue = 0;
      engineer.stress = 0;
      engineer.oxygenLevel = 1.0;

      simulation.addCrewMember(engineer);

      const effectiveSkill = simulation.getEffectiveSkill('engineer-3', 'engineering');

      expect(effectiveSkill).toBe(80); // No penalties
    });

    it('should reduce skill when injured', () => {
      const engineer: CrewMemberState = createHealthyCrew('engineer-4');
      engineer.skills.engineering = 80;

      simulation.addCrewMember(engineer);

      simulation.applyInjury('engineer-4', {
        type: InjuryType.TRAUMA,
        severity: 0.5,
        bodyPart: BodyPart.RIGHT_ARM,
        treated: false,
        stabilized: false
      });

      const effectiveSkill = simulation.getEffectiveSkill('engineer-4', 'engineering');

      expect(effectiveSkill).toBeLessThan(80);
      expect(effectiveSkill).toBeGreaterThan(0);
    });

    it('should reduce skill when fatigued', () => {
      const pilot: CrewMemberState = createHealthyCrew('pilot-2');
      pilot.skills.piloting = 90;
      pilot.fatigue = 0.8; // Very tired

      simulation.addCrewMember(pilot);

      const effectiveSkill = simulation.getEffectiveSkill('pilot-2', 'piloting');

      expect(effectiveSkill).toBeLessThan(90);
      expect(effectiveSkill).toBeCloseTo(90 * (1 - 0.8 * 0.3), 1); // 30% penalty from fatigue
    });

    it('should reduce skill when low oxygen', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-2');
      crew.skills.engineering = 70;
      crew.oxygenLevel = 0.5; // Hypoxic

      simulation.addCrewMember(crew);

      const effectiveSkill = simulation.getEffectiveSkill('crew-2', 'engineering');

      expect(effectiveSkill).toBeLessThan(70);
      expect(effectiveSkill).toBeCloseTo(35, 1); // 50% oxygen = 50% skill
    });

    it('should return zero skill for incapacitated crew', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-3');
      crew.skills.combat = 85;
      crew.incapacitated = true;

      simulation.addCrewMember(crew);

      const effectiveSkill = simulation.getEffectiveSkill('crew-3', 'combat');

      expect(effectiveSkill).toBe(0);
    });
  });

  describe('Task Assignment', () => {
    it('should assign task to healthy crew', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-4');
      simulation.addCrewMember(crew);

      const success = simulation.assignTask('crew-4', {
        type: TaskType.REPAIR,
        targetId: 'system-1',
        startTime: 0
      });

      expect(success).toBe(true);
      expect(crew.currentTask).toBeDefined();
      expect(crew.currentTask!.type).toBe(TaskType.REPAIR);
    });

    it('should fail to assign task to incapacitated crew', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-5');
      crew.incapacitated = true;

      simulation.addCrewMember(crew);

      const success = simulation.assignTask('crew-5', {
        type: TaskType.PILOTING,
        startTime: 0
      });

      expect(success).toBe(false);
      expect(crew.currentTask).toBeUndefined();
    });

    it('should refuse dangerous task when high stress', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-6');
      crew.stress = 0.95; // Breaking point

      simulation.addCrewMember(crew);

      const success = simulation.assignTask('crew-6', {
        type: TaskType.COMBAT,
        startTime: 0
      });

      expect(success).toBe(false);
    });

    it('should accept safe task when high stress', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-7');
      crew.stress = 0.95;

      simulation.addCrewMember(crew);

      const success = simulation.assignTask('crew-7', {
        type: TaskType.REST,
        startTime: 0
      });

      expect(success).toBe(true);
    });
  });

  describe('Stress and Fatigue', () => {
    it('should increase stress when low oxygen', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-8');
      crew.oxygenLevel = 0.5;
      crew.stress = 0;

      simulation.addCrewMember(crew);

      // Simulate 1 minute
      simulation.update(60);

      expect(crew.stress).toBeGreaterThan(0);
    });

    it('should increase stress when injured', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-9');
      crew.stress = 0;

      simulation.addCrewMember(crew);

      simulation.applyInjury('crew-9', {
        type: InjuryType.BURNS,
        severity: 0.3,
        bodyPart: BodyPart.LEFT_ARM,
        treated: false,
        stabilized: false
      });

      const initialStress = crew.stress;

      // Simulate 1 minute
      simulation.update(60);

      expect(crew.stress).toBeGreaterThan(initialStress);
    });

    it('should reduce stress when resting', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-10');
      crew.stress = 0.6;

      simulation.addCrewMember(crew);

      simulation.assignTask('crew-10', {
        type: TaskType.REST,
        startTime: 0
      });

      const initialStress = crew.stress;

      // Simulate 1 hour of rest
      for (let i = 0; i < 60; i++) {
        simulation.update(60);
      }

      expect(crew.stress).toBeLessThan(initialStress);
    });

    it('should increase fatigue when working', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-11');
      crew.fatigue = 0;

      simulation.addCrewMember(crew);

      simulation.assignTask('crew-11', {
        type: TaskType.REPAIR,
        targetId: 'system-2',
        startTime: 0
      });

      // Simulate 1 hour of work
      for (let i = 0; i < 60; i++) {
        simulation.update(60);
      }

      expect(crew.fatigue).toBeGreaterThan(0);
    });

    it('should reduce fatigue when resting', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-12');
      crew.fatigue = 0.8;

      simulation.addCrewMember(crew);

      simulation.assignTask('crew-12', {
        type: TaskType.REST,
        startTime: 0
      });

      // Simulate 1 hour of rest
      for (let i = 0; i < 60; i++) {
        simulation.update(60);
      }

      expect(crew.fatigue).toBeLessThan(0.8);
    });
  });

  describe('Death Conditions', () => {
    it('should die from zero health', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-13');
      crew.health = 0;

      simulation.addCrewMember(crew);

      simulation.update(1);

      expect(crew.alive).toBe(false);
    });

    it('should die from zero oxygen', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-14');
      crew.oxygenLevel = 0;

      simulation.addCrewMember(crew);

      simulation.update(1);

      expect(crew.alive).toBe(false);
    });

    it('should die from lethal radiation dose', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-15');
      crew.radiationDose = 8.5; // Lethal

      simulation.addCrewMember(crew);

      simulation.update(1);

      expect(crew.alive).toBe(false);
    });

    it('should die from untreated critical injury after time limit', () => {
      const crew: CrewMemberState = createHealthyCrew('crew-16');
      simulation.addCrewMember(crew);

      simulation.applyInjury('crew-16', {
        type: InjuryType.TRAUMA,
        severity: 0.85,
        bodyPart: BodyPart.TORSO,
        treated: false,
        stabilized: false
      });

      expect(crew.alive).toBe(true);

      // Simulate 31 minutes (past 30 minute limit)
      for (let i = 0; i < 31; i++) {
        simulation.update(60);
      }

      expect(crew.alive).toBe(false);
    });

    it('should survive critical injury if stabilized', () => {
      const patient: CrewMemberState = createHealthyCrew('crew-17');
      const doctor: CrewMemberState = createDoctor('doctor-6');

      simulation.addCrewMember(patient);
      simulation.addCrewMember(doctor);
      simulation.addMedBay({
        id: 'medbay-2',
        compartmentId: 'medical',
        operational: true,
        occupied: false
      });

      simulation.applyInjury('crew-17', {
        type: InjuryType.BURNS,
        severity: 0.85,
        bodyPart: BodyPart.TORSO,
        treated: false,
        stabilized: false
      });

      const injury = simulation.getCrewMember('crew-17')!.injuries[0];

      // Stabilize with surgery
      simulation.treat('crew-17', 'doctor-6', {
        type: 'surgery',
        targetInjury: injury.id
      });

      // Simulate 31 minutes
      for (let i = 0; i < 31; i++) {
        simulation.update(60);
      }

      expect(patient.alive).toBe(true);
    });
  });

  describe('Statistics', () => {
    it('should track crew statistics', () => {
      simulation.addCrewMember(createHealthyCrew('crew-18'));
      simulation.addCrewMember(createHealthyCrew('crew-19'));
      simulation.addCrewMember(createHealthyCrew('crew-20'));

      // Injure one
      simulation.applyInjury('crew-19', {
        type: InjuryType.TRAUMA,
        severity: 0.3,
        bodyPart: BodyPart.LEFT_LEG,
        treated: false,
        stabilized: false
      });

      // Incapacitate one
      simulation.applyInjury('crew-20', {
        type: InjuryType.BURNS,
        severity: 0.7,
        bodyPart: BodyPart.TORSO,
        treated: false,
        stabilized: false
      });

      const stats = simulation.getStatistics();

      expect(stats.total).toBe(3);
      expect(stats.alive).toBe(3);
      expect(stats.healthy).toBe(1);
      expect(stats.injured).toBeGreaterThanOrEqual(1);
      expect(stats.incapacitated).toBe(1);
    });
  });
});

// Helper functions
function createHealthyCrew(id: string): CrewMemberState {
  return {
    id,
    name: `Crew ${id}`,
    role: CrewRole.CREW,
    health: 1.0,
    injuries: [],
    radiationDose: 0,
    skills: {
      engineering: 50,
      piloting: 50,
      combat: 50,
      medical: 20,
      science: 40
    },
    fatigue: 0,
    stress: 0,
    oxygenLevel: 1.0,
    location: 'crew-quarters',
    incapacitated: false,
    alive: true
  };
}

function createDoctor(id: string): CrewMemberState {
  return {
    id,
    name: `Dr. ${id}`,
    role: CrewRole.MEDICAL_OFFICER,
    health: 1.0,
    injuries: [],
    radiationDose: 0,
    skills: {
      engineering: 30,
      piloting: 40,
      combat: 30,
      medical: 90,  // High medical skill
      science: 70
    },
    fatigue: 0,
    stress: 0,
    oxygenLevel: 1.0,
    location: 'medical',
    incapacitated: false,
    alive: true
  };
}
