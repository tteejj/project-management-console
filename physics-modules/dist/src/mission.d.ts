/**
 * Mission System
 *
 * Provides landing zones, scoring, objectives, and procedural checklists
 * for mission-based gameplay.
 */
export interface Vector3 {
    x: number;
    y: number;
    z: number;
}
export interface LatLon {
    lat: number;
    lon: number;
}
export type Difficulty = 'easy' | 'medium' | 'hard' | 'extreme';
export type TerrainType = 'flat' | 'rocky' | 'cratered' | 'slope';
export type Lighting = 'day' | 'night' | 'terminator';
export type ObjectiveType = 'primary' | 'secondary' | 'bonus';
export type ChecklistPhase = 'pre-landing' | 'descent' | 'final-approach' | 'post-landing';
export type Grade = 'S' | 'A' | 'B' | 'C' | 'D' | 'F';
export interface LandingZone {
    id: string;
    name: string;
    description: string;
    coordinates: LatLon;
    radius: number;
    difficulty: Difficulty;
    maxLandingSpeed: number;
    maxLandingAngle: number;
    targetPrecision: number;
    terrainType: TerrainType;
    boulderDensity: number;
    lighting: Lighting;
}
export interface MissionObjective {
    id: string;
    description: string;
    type: ObjectiveType;
    completed: boolean;
    points: number;
}
export interface ChecklistItem {
    id: string;
    description: string;
    completed: boolean;
    automated: boolean;
    verification: () => boolean;
}
export interface Checklist {
    id: string;
    name: string;
    phase: ChecklistPhase;
    items: ChecklistItem[];
    allCompleted: boolean;
}
export interface MissionScore {
    landingSpeedScore: number;
    landingAngleScore: number;
    precisionScore: number;
    fuelEfficiencyScore: number;
    timeEfficiencyScore: number;
    systemHealthScore: number;
    procedureScore: number;
    difficultyMultiplier: number;
    totalScore: number;
    grade: Grade;
}
export interface Mission {
    id: string;
    name: string;
    briefing: string;
    landingZone: LandingZone;
    objectives: MissionObjective[];
    startAltitude: number;
    startVelocity: Vector3;
    startFuel: number;
    parTime: number;
    maxTime: number;
}
export interface MissionResult {
    success: boolean;
    missionTime: number;
    score: MissionScore;
    objectivesCompleted: number;
    objectivesTotal: number;
    checklistsCompleted: number;
    checklistsTotal: number;
}
/**
 * Landing Zone Database
 */
export declare class LandingZoneDatabase {
    private zones;
    constructor();
    private initializeZones;
    getZone(id: string): LandingZone | undefined;
    getAllZones(): LandingZone[];
    getZonesByDifficulty(difficulty: Difficulty): LandingZone[];
}
/**
 * Scoring Calculator
 */
export declare class ScoringCalculator {
    calculateScore(landingSpeed: number, landingAngle: number, distanceFromTarget: number, fuelRemaining: number, initialFuel: number, missionTime: number, parTime: number, systemHealth: number, // 0-100
    checklistsCompleted: number, totalChecklists: number, landingZone: LandingZone): MissionScore;
    calculatePrecisionBonus(distanceFromTarget: number, bonusRadius: number): number;
}
/**
 * Mission Builder
 * Creates missions with objectives and checklists
 */
export declare class MissionBuilder {
    private lzDatabase;
    constructor();
    createTrainingMission(): Mission;
    createPrecisionMission(): Mission;
    createChallengeMission(): Mission;
}
/**
 * Checklist System
 */
export declare class ChecklistSystem {
    private checklists;
    addChecklist(checklist: Checklist): void;
    getChecklist(id: string): Checklist | undefined;
    getAllChecklists(): Checklist[];
    getChecklistsByPhase(phase: ChecklistPhase): Checklist[];
    updateChecklist(id: string): void;
    getCompletionRate(): number;
}
/**
 * Mission System
 * Main integration point for missions, scoring, and objectives
 */
export declare class MissionSystem {
    private lzDatabase;
    private scoringCalc;
    private missionBuilder;
    private checklistSystem;
    private currentMission;
    private missionStartTime;
    private missionComplete;
    constructor();
    getLandingZone(id: string): LandingZone | undefined;
    getAllLandingZones(): LandingZone[];
    loadMission(mission: Mission): void;
    startMission(currentTime: number): void;
    getCurrentMission(): Mission | null;
    completeObjective(objectiveId: string): void;
    checkObjective(objectiveId: string, condition: boolean): void;
    getObjectivesCompletion(): {
        completed: number;
        total: number;
    };
    calculateMissionScore(landingSpeed: number, landingAngle: number, landingPosition: Vector3, targetPosition: Vector3, fuelRemaining: number, systemHealth: number, currentTime: number): MissionResult;
    addChecklist(checklist: Checklist): void;
    updateChecklists(): void;
    getChecklists(): Checklist[];
    isInLandingZone(position: Vector3, landingZone: LandingZone): boolean;
    private calculateDistance;
    private latLonToPosition;
    createTrainingMission(): Mission;
    createPrecisionMission(): Mission;
    createChallengeMission(): Mission;
}
//# sourceMappingURL=mission.d.ts.map