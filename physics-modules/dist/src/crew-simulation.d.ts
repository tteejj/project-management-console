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
export declare enum InjuryType {
    TRAUMA = "trauma",
    BURNS = "burns",
    ASPHYXIATION = "asphyxiation",
    RADIATION = "radiation",
    DECOMPRESSION = "decompression"
}
export declare enum BodyPart {
    HEAD = "head",
    TORSO = "torso",
    LEFT_ARM = "left_arm",
    RIGHT_ARM = "right_arm",
    LEFT_LEG = "left_leg",
    RIGHT_LEG = "right_leg"
}
export declare enum CrewRole {
    CAPTAIN = "captain",
    PILOT = "pilot",
    ENGINEER = "engineer",
    MEDICAL_OFFICER = "medical_officer",
    SCIENTIST = "scientist",
    GUNNER = "gunner",
    CREW = "crew"
}
export declare enum TaskType {
    PILOTING = "piloting",
    REPAIR = "repair",
    MEDICAL = "medical",
    COMBAT = "combat",
    SCIENCE = "science",
    REST = "rest"
}
export interface Injury {
    id: string;
    type: InjuryType;
    severity: number;
    bodyPart: BodyPart;
    timestamp: number;
    treated: boolean;
    stabilized: boolean;
    bleedRate?: number;
}
export interface SkillSet {
    engineering: number;
    piloting: number;
    combat: number;
    medical: number;
    science: number;
}
export interface Task {
    type: TaskType;
    targetId?: string;
    startTime: number;
}
export interface CrewMemberState {
    id: string;
    name: string;
    role: CrewRole;
    health: number;
    injuries: Injury[];
    radiationDose: number;
    skills: SkillSet;
    fatigue: number;
    stress: number;
    oxygenLevel: number;
    location: string;
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
    currentPatient?: string;
}
export interface Treatment {
    type: 'first_aid' | 'surgery' | 'medication' | 'rest';
    targetInjury?: string;
}
export interface Diagnosis {
    crewId: string;
    overallHealth: number;
    criticalInjuries: Injury[];
    recommendedTreatment: Treatment[];
    timeUntilDeath?: number;
}
/**
 * Crew Simulation System
 */
export declare class CrewSimulation {
    private crew;
    private medBays;
    private supplies;
    private simulationTime;
    private readonly MINOR_HEAL_RATE;
    private readonly MODERATE_HEAL_RATE;
    private readonly SEVERE_HEAL_RATE;
    private readonly CRITICAL_HEAL_RATE;
    private readonly STRESS_RECOVERY_RATE;
    private readonly FATIGUE_RATE;
    private readonly CRITICAL_TIME_LIMIT;
    constructor(supplies?: MedicalSupplies);
    /**
     * Add crew member
     */
    addCrewMember(crew: CrewMemberState): void;
    /**
     * Get crew member
     */
    getCrewMember(id: string): CrewMemberState | undefined;
    /**
     * Add medical bay
     */
    addMedBay(medBay: MedBay): void;
    /**
     * Apply injury to crew member
     */
    applyInjury(crewId: string, injury: Omit<Injury, 'id' | 'timestamp'>): void;
    /**
     * Apply environmental damage
     */
    applyEnvironmentalDamage(crewId: string, damageType: InjuryType, amount: number): void;
    /**
     * Diagnose crew member
     */
    diagnose(crewId: string): Diagnosis | null;
    /**
     * Treat crew member
     */
    treat(crewId: string, doctorId: string, treatment: Treatment): boolean;
    /**
     * Assign task to crew member
     */
    assignTask(crewId: string, task: Task): boolean;
    /**
     * Calculate effective skill for a task
     */
    getEffectiveSkill(crewId: string, skillType: keyof SkillSet): number;
    /**
     * Update simulation
     */
    update(dt: number): void;
    /**
     * Update injury progression and healing
     */
    private updateInjuries;
    /**
     * Check for death conditions
     */
    private checkDeath;
    /**
     * Update stress levels
     */
    private updateStress;
    /**
     * Update fatigue
     */
    private updateFatigue;
    /**
     * Update overall health based on injuries
     */
    private updateHealth;
    /**
     * Get crew statistics
     */
    getStatistics(): {
        total: number;
        alive: number;
        dead: number;
        incapacitated: number;
        injured: number;
        healthy: number;
        supplies: {
            firstAidKits: number;
            surgicalSupplies: number;
            medications: number;
            bloodPacks: number;
        };
    };
}
//# sourceMappingURL=crew-simulation.d.ts.map