/**
 * Crew Simulation System
 *
 * Comprehensive crew member simulation:
 * - Health and injuries
 * - Medical treatment
 * - Skills and performance
 * - Morale and stress
 * - Death and incapacitation
 */

import { Vector3 } from './math-utils';

export enum InjuryType {
  TRAUMA = 'trauma',
  BURNS = 'burns',
  ASPHYXIATION = 'asphyxiation',
  RADIATION = 'radiation',
  DECOMPRESSION = 'decompression'
}

export enum BodyPart {
  HEAD = 'head',
  TORSO = 'torso',
  LEFT_ARM = 'left_arm',
  RIGHT_ARM = 'right_arm',
  LEFT_LEG = 'left_leg',
  RIGHT_LEG = 'right_leg'
}

export enum CrewRole {
  CAPTAIN = 'captain',
  PILOT = 'pilot',
  ENGINEER = 'engineer',
  MEDICAL_OFFICER = 'medical_officer',
  SCIENTIST = 'scientist',
  GUNNER = 'gunner',
  CREW = 'crew'
}

export enum TaskType {
  PILOTING = 'piloting',
  REPAIR = 'repair',
  MEDICAL = 'medical',
  COMBAT = 'combat',
  SCIENCE = 'science',
  REST = 'rest'
}

export interface Injury {
  id: string;
  type: InjuryType;
  severity: number;        // 0-1 (0 = healed, 1 = fatal)
  bodyPart: BodyPart;
  timestamp: number;
  treated: boolean;
  stabilized: boolean;
  bleedRate?: number;      // For trauma injuries (severity increase per second)
}

export interface SkillSet {
  engineering: number;     // 0-100
  piloting: number;        // 0-100
  combat: number;          // 0-100
  medical: number;         // 0-100
  science: number;         // 0-100
}

export interface Task {
  type: TaskType;
  targetId?: string;       // Target crew member (for medical), system (for repair), etc.
  startTime: number;
}

export interface CrewMemberState {
  id: string;
  name: string;
  role: CrewRole;

  // Health
  health: number;          // 0-1 (1 = perfect health)
  injuries: Injury[];
  radiationDose: number;   // Cumulative radiation (Sv)

  // Skills
  skills: SkillSet;

  // State
  fatigue: number;         // 0-1 (0 = rested, 1 = exhausted)
  stress: number;          // 0-1 (0 = calm, 1 = breaking point)
  oxygenLevel: number;     // 0-1 (1 = full oxygen)

  // G-force tracking
  currentGForce: number;   // Current G-force experienced
  peakGForce: number;      // Peak G-force ever experienced
  gForceDuration: number;  // Seconds of high-G exposure

  // Radiation tracking (cumulative)
  radiationExposureRate: number;  // Sv/hour (current rate)

  // Status
  location: string;        // Compartment ID
  currentTask?: Task;
  incapacitated: boolean;
  alive: boolean;
}

export interface MedicalSupplies {
  firstAidKits: number;
  surgicalSupplies: number;
  medications: number;
  bloodPacks: number;
}

export interface MedBay {
  id: string;
  compartmentId: string;
  operational: boolean;
  occupied: boolean;
  currentPatient?: string; // Crew member ID
}

export interface Treatment {
  type: 'first_aid' | 'surgery' | 'medication' | 'rest';
  targetInjury?: string;   // Injury ID
}

export interface Diagnosis {
  crewId: string;
  overallHealth: number;
  criticalInjuries: Injury[];
  recommendedTreatment: Treatment[];
  timeUntilDeath?: number; // seconds (if dying)
}

/**
 * Crew Simulation System
 */
export class CrewSimulation {
  private crew: Map<string, CrewMemberState> = new Map();
  private medBays: MedBay[] = [];
  private supplies: MedicalSupplies;
  private simulationTime: number = 0;

  // Constants
  private readonly MINOR_HEAL_RATE = 0.05 / 3600;      // 5% per hour
  private readonly MODERATE_HEAL_RATE = 0.02 / 3600;   // 2% per hour
  private readonly SEVERE_HEAL_RATE = 0.01 / 3600;     // 1% per hour
  private readonly CRITICAL_HEAL_RATE = 0.005 / 3600;  // 0.5% per hour

  private readonly STRESS_RECOVERY_RATE = 0.05 / 3600; // 5% per hour
  private readonly FATIGUE_RATE = 0.1 / 3600;          // 10% per hour when working

  private readonly CRITICAL_TIME_LIMIT = 1800;         // 30 minutes

  // G-force thresholds (sustained)
  private readonly G_FORCE_DISCOMFORT = 3;   // G's - discomfort begins
  private readonly G_FORCE_INJURY = 5;       // G's - injury threshold
  private readonly G_FORCE_BLACKOUT = 9;     // G's - G-LOC (G-induced Loss of Consciousness)
  private readonly G_FORCE_FATAL = 15;       // G's - potentially fatal

  // Radiation thresholds
  private readonly RADIATION_MILD = 0.5;     // Sv - mild symptoms
  private readonly RADIATION_SEVERE = 2;     // Sv - severe radiation sickness
  private readonly RADIATION_LETHAL = 8;     // Sv - lethal dose

  constructor(supplies?: MedicalSupplies) {
    this.supplies = supplies || {
      firstAidKits: 10,
      surgicalSupplies: 5,
      medications: 20,
      bloodPacks: 8
    };
  }

  /**
   * Add crew member
   */
  addCrewMember(crew: CrewMemberState): void {
    this.crew.set(crew.id, crew);
  }

  /**
   * Get crew member
   */
  getCrewMember(id: string): CrewMemberState | undefined {
    return this.crew.get(id);
  }

  /**
   * Add medical bay
   */
  addMedBay(medBay: MedBay): void {
    this.medBays.push(medBay);
  }

  /**
   * Apply injury to crew member
   */
  applyInjury(crewId: string, injury: Omit<Injury, 'id' | 'timestamp'>): void {
    const crew = this.crew.get(crewId);
    if (!crew || !crew.alive) return;

    const fullInjury: Injury = {
      ...injury,
      id: `injury-${Date.now()}-${Math.random()}`,
      timestamp: this.simulationTime
    };

    crew.injuries.push(fullInjury);

    // Update health based on injury severity
    // Severe injuries do full damage to health
    crew.health = Math.max(0, crew.health - injury.severity);

    // Check if injury is fatal
    if (crew.health <= 0) {
      crew.alive = false;
      crew.incapacitated = true;
    }

    // Severe/critical injuries cause incapacitation (threshold >0.5, not >=)
    if (injury.severity > 0.5) {
      crew.incapacitated = true;
    }
  }

  /**
   * Apply environmental damage
   */
  applyEnvironmentalDamage(crewId: string, damageType: InjuryType, amount: number): void {
    const crew = this.crew.get(crewId);
    if (!crew || !crew.alive) return;

    // Find existing injury of this type or create new one
    let injury = crew.injuries.find(inj => inj.type === damageType && !inj.treated);

    if (injury) {
      injury.severity = Math.min(1, injury.severity + amount);
    } else {
      this.applyInjury(crewId, {
        type: damageType,
        severity: amount,
        bodyPart: BodyPart.TORSO,
        treated: false,
        stabilized: false
      });
    }
  }

  /**
   * Diagnose crew member
   */
  diagnose(crewId: string): Diagnosis | null {
    const crew = this.crew.get(crewId);
    if (!crew) return null;

    const criticalInjuries = crew.injuries.filter(inj => inj.severity >= 0.75);
    const recommended: Treatment[] = [];

    // Recommend treatments based on injury severity
    for (const injury of crew.injuries) {
      if (injury.severity >= 0.75 && !injury.stabilized) {
        recommended.push({ type: 'surgery', targetInjury: injury.id });
      } else if (injury.severity >= 0.5 && !injury.treated) {
        recommended.push({ type: 'medication', targetInjury: injury.id });
      } else if (injury.severity > 0 && !injury.treated) {
        recommended.push({ type: 'first_aid', targetInjury: injury.id });
      }
    }

    // Calculate time until death for critical injuries
    let timeUntilDeath: number | undefined;
    if (criticalInjuries.length > 0) {
      const oldestCritical = criticalInjuries.reduce((oldest, inj) =>
        inj.timestamp < oldest.timestamp ? inj : oldest
      );
      const timeSinceCritical = this.simulationTime - oldestCritical.timestamp;
      timeUntilDeath = Math.max(0, this.CRITICAL_TIME_LIMIT - timeSinceCritical);
    }

    return {
      crewId,
      overallHealth: crew.health,
      criticalInjuries,
      recommendedTreatment: recommended,
      timeUntilDeath
    };
  }

  /**
   * Treat crew member
   */
  treat(crewId: string, doctorId: string, treatment: Treatment): boolean {
    const patient = this.crew.get(crewId);
    const doctor = this.crew.get(doctorId);

    if (!patient || !doctor || !patient.alive || doctor.incapacitated) {
      return false;
    }

    const medicalSkill = doctor.skills.medical;

    switch (treatment.type) {
      case 'first_aid':
        if (this.supplies.firstAidKits <= 0) return false;
        this.supplies.firstAidKits--;

        if (treatment.targetInjury) {
          const injury = patient.injuries.find(inj => inj.id === treatment.targetInjury);
          if (injury) {
            injury.treated = true;
            injury.severity = Math.max(0, injury.severity - 0.1 * (1 + medicalSkill / 100));
          }
        }
        return true;

      case 'surgery':
        // Requires med bay
        const availableMedBay = this.medBays.find(mb => mb.operational && !mb.occupied);
        if (!availableMedBay || this.supplies.surgicalSupplies <= 0) return false;

        this.supplies.surgicalSupplies--;

        if (treatment.targetInjury) {
          const injury = patient.injuries.find(inj => inj.id === treatment.targetInjury);
          if (injury && injury.severity >= 0.5) {
            injury.stabilized = true;
            injury.treated = true;
            injury.severity = Math.max(0, injury.severity - 0.2 * (1 + medicalSkill / 100));
          }
        }

        // Surgery can restore consciousness for severe injuries
        if (patient.incapacitated) {
          const severitySum = patient.injuries.reduce((sum, inj) => sum + inj.severity, 0);
          if (severitySum < 1.0) {
            patient.incapacitated = false;
          }
        }
        return true;

      case 'medication':
        if (this.supplies.medications <= 0) return false;
        this.supplies.medications--;

        // Medication reduces all injury severities slightly
        for (const injury of patient.injuries) {
          injury.severity = Math.max(0, injury.severity - 0.05 * (1 + medicalSkill / 200));
        }

        // Reduce stress
        patient.stress = Math.max(0, patient.stress - 0.1);
        return true;

      case 'rest':
        // Rest is free but slower healing
        patient.fatigue = Math.max(0, patient.fatigue - 0.2);
        patient.stress = Math.max(0, patient.stress - 0.05);
        return true;
    }

    return false;
  }

  /**
   * Assign task to crew member
   */
  assignTask(crewId: string, task: Task): boolean {
    const crew = this.crew.get(crewId);
    if (!crew || !crew.alive || crew.incapacitated) {
      return false;
    }

    // High stress crew may refuse dangerous tasks
    if (crew.stress > 0.9 && (task.type === TaskType.COMBAT || task.type === TaskType.REPAIR)) {
      return false;
    }

    crew.currentTask = {
      ...task,
      startTime: this.simulationTime
    };

    return true;
  }

  /**
   * Calculate effective skill for a task
   */
  getEffectiveSkill(crewId: string, skillType: keyof SkillSet): number {
    const crew = this.crew.get(crewId);
    if (!crew || !crew.alive || crew.incapacitated) return 0;

    const baseSkill = crew.skills[skillType];

    // Calculate injury penalty
    const totalInjurySeverity = crew.injuries.reduce((sum, inj) => sum + inj.severity, 0);
    const injuryPenalty = Math.min(totalInjurySeverity, 1.0);

    const effectiveSkill = baseSkill
      * (1 - injuryPenalty * 0.5)       // Injuries reduce skill up to 50%
      * (1 - crew.fatigue * 0.3)        // Fatigue reduces skill up to 30%
      * (1 - crew.stress * 0.2)         // Stress reduces skill up to 20%
      * crew.oxygenLevel;               // Hypoxia reduces skill proportionally

    return Math.max(0, effectiveSkill);
  }

  /**
   * Update simulation
   */
  update(dt: number): void {
    this.simulationTime += dt;

    for (const [id, crew] of this.crew.entries()) {
      if (!crew.alive) continue;

      // 1. Update injuries
      this.updateInjuries(crew, dt);

      // 2. Apply G-force effects
      this.updateGForceEffects(crew, dt);

      // 3. Apply radiation effects
      this.updateRadiationEffects(crew, dt);

      // 4. Check death conditions
      this.checkDeath(crew);

      // 5. Update stress and fatigue
      this.updateStress(crew, dt);
      this.updateFatigue(crew, dt);

      // 6. Update health based on overall injury state
      this.updateHealth(crew);
    }
  }

  /**
   * Set crew member's current G-force exposure
   * Should be called from physics simulation
   */
  setCrewGForce(crewId: string, gForce: number): void {
    const crew = this.crew.get(crewId);
    if (!crew || !crew.alive) return;

    crew.currentGForce = gForce;

    if (gForce > crew.peakGForce) {
      crew.peakGForce = gForce;
    }
  }

  /**
   * Set crew member's radiation exposure rate
   * Should be called from environment/radiation simulation
   */
  setCrewRadiationRate(crewId: string, svPerHour: number): void {
    const crew = this.crew.get(crewId);
    if (!crew || !crew.alive) return;

    crew.radiationExposureRate = svPerHour;
  }

  /**
   * Update injury progression and healing
   */
  private updateInjuries(crew: CrewMemberState, dt: number): void {
    for (let i = crew.injuries.length - 1; i >= 0; i--) {
      const injury = crew.injuries[i];

      // Untreated injuries may worsen
      if (!injury.treated && !injury.stabilized) {
        // Bleeding from trauma
        if (injury.type === InjuryType.TRAUMA && injury.bleedRate) {
          injury.severity = Math.min(1, injury.severity + injury.bleedRate * dt);
        }
      }

      // Healing
      if (injury.treated || injury.stabilized) {
        let healRate = 0;

        if (injury.severity < 0.25) {
          healRate = this.MINOR_HEAL_RATE;
        } else if (injury.severity < 0.5) {
          healRate = this.MODERATE_HEAL_RATE;
        } else if (injury.severity < 0.75) {
          healRate = this.SEVERE_HEAL_RATE;
        } else {
          healRate = this.CRITICAL_HEAL_RATE;
        }

        injury.severity = Math.max(0, injury.severity - healRate * dt);

        // Remove fully healed injuries
        if (injury.severity <= 0) {
          crew.injuries.splice(i, 1);
        }
      }
    }
  }

  /**
   * Update G-force effects on crew member
   *
   * G-force effects:
   * - 3-5 G: Discomfort, increased stress
   * - 5-9 G: Injury (bruising, blood vessel damage), high stress
   * - 9+ G: G-LOC (G-induced Loss of Consciousness), incapacitation
   * - 15+ G: Potentially fatal
   */
  private updateGForceEffects(crew: CrewMemberState, dt: number): void {
    const gForce = crew.currentGForce || 0;

    // Track high-G duration
    if (gForce > this.G_FORCE_DISCOMFORT) {
      crew.gForceDuration = (crew.gForceDuration || 0) + dt;
    } else {
      crew.gForceDuration = Math.max(0, (crew.gForceDuration || 0) - dt * 0.5);  // Recovery
    }

    // Fatal G-forces
    if (gForce >= this.G_FORCE_FATAL) {
      this.applyEnvironmentalDamage(crew.id, InjuryType.TRAUMA, 0.5 * dt);  // Rapid death
      return;
    }

    // G-LOC (Loss of Consciousness)
    if (gForce >= this.G_FORCE_BLACKOUT) {
      crew.incapacitated = true;
      crew.stress = Math.min(1, crew.stress + 0.2 * dt);

      // Chance of injury during blackout
      if (Math.random() < 0.1 * dt) {  // 10% per second
        this.applyInjury(crew.id, {
          type: InjuryType.TRAUMA,
          severity: 0.1 + Math.random() * 0.2,
          bodyPart: BodyPart.HEAD,
          treated: false,
          stabilized: false
        });
      }
    }

    // Injury-causing G-forces
    else if (gForce >= this.G_FORCE_INJURY) {
      // Accumulating injuries over time
      const injuryRate = (gForce - this.G_FORCE_INJURY) / 10;  // Severity per second
      this.applyEnvironmentalDamage(crew.id, InjuryType.TRAUMA, injuryRate * dt);

      // Increased stress
      crew.stress = Math.min(1, crew.stress + 0.1 * dt);
    }

    // Discomfort range
    else if (gForce >= this.G_FORCE_DISCOMFORT) {
      // Increased stress and fatigue
      crew.stress = Math.min(1, crew.stress + 0.05 * dt);
      crew.fatigue = Math.min(1, crew.fatigue + 0.02 * dt);
    }
  }

  /**
   * Update radiation effects on crew member
   *
   * Radiation effects (cumulative dose):
   * - 0-0.5 Sv: Minimal effects
   * - 0.5-2 Sv: Mild radiation sickness (nausea, fatigue)
   * - 2-8 Sv: Severe radiation sickness (vomiting, infections, bleeding)
   * - 8+ Sv: Lethal dose (multi-organ failure)
   *
   * Exposure rate is in Sv/hour
   */
  private updateRadiationEffects(crew: CrewMemberState, dt: number): void {
    const exposureRate = crew.radiationExposureRate || 0;

    // Accumulate radiation dose: Sv = (Sv/hour) * (seconds/3600)
    const doseDelta = exposureRate * (dt / 3600);
    crew.radiationDose += doseDelta;

    // Effects based on cumulative dose
    if (crew.radiationDose >= this.RADIATION_SEVERE) {
      // Severe radiation sickness
      // Progressive damage
      this.applyEnvironmentalDamage(crew.id, InjuryType.RADIATION, 0.01 * dt);

      // High stress and fatigue
      crew.stress = Math.min(1, crew.stress + 0.1 * dt);
      crew.fatigue = Math.min(1, crew.fatigue + 0.15 * dt);

      // Chance of bleeding (radiation damages blood vessels)
      if (Math.random() < 0.05 * dt) {
        this.applyInjury(crew.id, {
          type: InjuryType.RADIATION,
          severity: 0.2 + Math.random() * 0.3,
          bodyPart: BodyPart.TORSO,
          treated: false,
          stabilized: false,
          bleedRate: 0.01  // Slow bleeding
        });
      }
    } else if (crew.radiationDose >= this.RADIATION_MILD) {
      // Mild radiation sickness
      // Moderate damage
      this.applyEnvironmentalDamage(crew.id, InjuryType.RADIATION, 0.005 * dt);

      // Increased stress and fatigue
      crew.stress = Math.min(1, crew.stress + 0.05 * dt);
      crew.fatigue = Math.min(1, crew.fatigue + 0.08 * dt);
    }

    // Acute radiation exposure (high rate)
    if (exposureRate > 1.0) {  // >1 Sv/hour is very high
      // Immediate nausea and weakness
      crew.stress = Math.min(1, crew.stress + 0.15 * dt);
      crew.fatigue = Math.min(1, crew.fatigue + 0.2 * dt);

      if (exposureRate > 10) {  // Extreme radiation
        crew.incapacitated = true;
      }
    }
  }

  /**
   * Check for death conditions
   */
  private checkDeath(crew: CrewMemberState): void {
    // Health at zero
    if (crew.health <= 0) {
      crew.alive = false;
      crew.incapacitated = true;
      return;
    }

    // Oxygen depletion
    if (crew.oxygenLevel <= 0) {
      crew.alive = false;
      crew.incapacitated = true;
      return;
    }

    // Critical injury untreated too long
    const criticalInjuries = crew.injuries.filter(inj => inj.severity >= 0.75 && !inj.stabilized);
    for (const injury of criticalInjuries) {
      const timeSinceCritical = this.simulationTime - injury.timestamp;
      if (timeSinceCritical > this.CRITICAL_TIME_LIMIT) {
        crew.alive = false;
        crew.incapacitated = true;
        return;
      }
    }

    // Lethal radiation dose (8 Sv)
    if (crew.radiationDose >= 8) {
      crew.alive = false;
      crew.incapacitated = true;
      return;
    }
  }

  /**
   * Update stress levels
   */
  private updateStress(crew: CrewMemberState, dt: number): void {
    let stressChange = 0;

    // Low oxygen increases stress
    if (crew.oxygenLevel < 0.7) {
      stressChange += 0.08 / 60 * dt;  // 8% per minute
    }

    // Injuries increase stress
    if (crew.injuries.length > 0) {
      stressChange += 0.1 / 60 * dt;   // 10% per minute
    }

    // Resting reduces stress
    if (crew.currentTask?.type === TaskType.REST) {
      stressChange -= this.STRESS_RECOVERY_RATE * dt;
    }

    crew.stress = Math.max(0, Math.min(1, crew.stress + stressChange));
  }

  /**
   * Update fatigue
   */
  private updateFatigue(crew: CrewMemberState, dt: number): void {
    if (crew.currentTask?.type === TaskType.REST) {
      // Resting reduces fatigue
      crew.fatigue = Math.max(0, crew.fatigue - this.FATIGUE_RATE * dt);
    } else if (crew.currentTask) {
      // Working increases fatigue
      crew.fatigue = Math.min(1, crew.fatigue + this.FATIGUE_RATE * dt);
    }
  }

  /**
   * Update overall health based on injuries
   */
  private updateHealth(crew: CrewMemberState): void {
    const totalInjurySeverity = crew.injuries.reduce((sum, inj) => sum + inj.severity, 0);

    // Health is reduced by total injury severity
    crew.health = Math.max(0, 1 - totalInjurySeverity);

    // Check incapacitation (threshold >0.5 for consistency)
    const hasSevereInjury = crew.injuries.some(inj => inj.severity > 0.5);
    crew.incapacitated = crew.health < 0.3 || hasSevereInjury || crew.oxygenLevel < 0.4;
  }

  /**
   * Get crew statistics
   */
  getStatistics() {
    const total = this.crew.size;
    let alive = 0;
    let incapacitated = 0;
    let injured = 0;
    let healthy = 0;

    for (const crew of this.crew.values()) {
      if (crew.alive) {
        alive++;
        if (crew.incapacitated) {
          incapacitated++;
        } else if (crew.injuries.length > 0) {
          injured++;
        } else {
          healthy++;
        }
      }
    }

    return {
      total,
      alive,
      dead: total - alive,
      incapacitated,
      injured,
      healthy,
      supplies: { ...this.supplies }
    };
  }
}
