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
  lat: number;  // degrees
  lon: number;  // degrees
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
  radius: number;              // Acceptable landing radius (m)
  difficulty: Difficulty;

  // Constraints
  maxLandingSpeed: number;     // m/s
  maxLandingAngle: number;     // degrees from vertical
  targetPrecision: number;     // Bonus radius (m)

  // Environment
  terrainType: TerrainType;
  boulderDensity: number;      // 0-1
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
  automated: boolean;          // Can autopilot do it?
  verification: () => boolean; // Check if completed
}

export interface Checklist {
  id: string;
  name: string;
  phase: ChecklistPhase;
  items: ChecklistItem[];
  allCompleted: boolean;
}

export interface MissionScore {
  // Landing Quality (0-1000 points)
  landingSpeedScore: number;
  landingAngleScore: number;
  precisionScore: number;

  // Resource Efficiency (0-500 points)
  fuelEfficiencyScore: number;
  timeEfficiencyScore: number;

  // System Health (0-300 points)
  systemHealthScore: number;
  procedureScore: number;

  // Final Score
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

  // Initial Conditions
  startAltitude: number;
  startVelocity: Vector3;
  startFuel: number;

  // Constraints
  parTime: number;             // Target completion time (s)
  maxTime: number;             // Mission failure time (s)
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
export class LandingZoneDatabase {
  private zones: Map<string, LandingZone> = new Map();

  constructor() {
    this.initializeZones();
  }

  private initializeZones(): void {
    // Easy: Mare Tranquillitatis Base Alpha
    this.zones.set('lz_tranquility', {
      id: 'lz_tranquility',
      name: 'Mare Tranquillitatis Base Alpha',
      description: 'Primary landing site. Flat terrain, good visibility.',
      coordinates: { lat: 0.674, lon: 23.473 },
      radius: 500,
      difficulty: 'easy',
      maxLandingSpeed: 3.0,
      maxLandingAngle: 10,
      targetPrecision: 50,
      terrainType: 'flat',
      boulderDensity: 0.1,
      lighting: 'day'
    });

    // Medium: Mare Serenitatis Outpost
    this.zones.set('lz_serenitatis', {
      id: 'lz_serenitatis',
      name: 'Mare Serenitatis Outpost',
      description: 'Secondary site with scattered boulders.',
      coordinates: { lat: 28.0, lon: 17.5 },
      radius: 300,
      difficulty: 'medium',
      maxLandingSpeed: 2.5,
      maxLandingAngle: 7,
      targetPrecision: 30,
      terrainType: 'rocky',
      boulderDensity: 0.3,
      lighting: 'day'
    });

    // Hard: Copernicus Crater Rim Station
    this.zones.set('lz_copernicus', {
      id: 'lz_copernicus',
      name: 'Copernicus Crater Rim Station',
      description: 'Challenging crater rim landing. Precision required.',
      coordinates: { lat: 9.62, lon: -20.08 },
      radius: 200,
      difficulty: 'hard',
      maxLandingSpeed: 2.0,
      maxLandingAngle: 5,
      targetPrecision: 20,
      terrainType: 'slope',
      boulderDensity: 0.4,
      lighting: 'terminator'
    });

    // Extreme: Shackleton Crater Ice Mine
    this.zones.set('lz_shackleton', {
      id: 'lz_shackleton',
      name: 'Shackleton Crater Ice Mine',
      description: 'Extreme difficulty. Permanently shadowed, rough terrain.',
      coordinates: { lat: -89.54, lon: 0 },
      radius: 100,
      difficulty: 'extreme',
      maxLandingSpeed: 1.5,
      maxLandingAngle: 3,
      targetPrecision: 10,
      terrainType: 'rocky',
      boulderDensity: 0.7,
      lighting: 'night'
    });
  }

  getZone(id: string): LandingZone | undefined {
    return this.zones.get(id);
  }

  getAllZones(): LandingZone[] {
    return Array.from(this.zones.values());
  }

  getZonesByDifficulty(difficulty: Difficulty): LandingZone[] {
    return Array.from(this.zones.values()).filter(z => z.difficulty === difficulty);
  }
}

/**
 * Scoring Calculator
 */
export class ScoringCalculator {
  calculateScore(
    landingSpeed: number,
    landingAngle: number,
    distanceFromTarget: number,
    fuelRemaining: number,
    initialFuel: number,
    missionTime: number,
    parTime: number,
    systemHealth: number,       // 0-100
    checklistsCompleted: number,
    totalChecklists: number,
    landingZone: LandingZone
  ): MissionScore {
    // Landing Speed Score (max 400 points)
    const speedScore = Math.max(0, 400 * (1 - landingSpeed / landingZone.maxLandingSpeed));

    // Precision Score (max 300 points)
    const precisionScore = Math.max(0, 300 * (1 - distanceFromTarget / landingZone.radius));

    // Landing Angle Score (max 300 points)
    const angleScore = Math.max(0, 300 * (1 - landingAngle / landingZone.maxLandingAngle));

    // Fuel Efficiency Score (max 300 points)
    const fuelPercent = initialFuel > 0 ? fuelRemaining / initialFuel : 0;
    const fuelScore = 300 * fuelPercent;

    // Time Efficiency Score (max 200 points)
    const timeScore = missionTime <= parTime ?
      200 : Math.max(0, 200 * (1 - (missionTime - parTime) / parTime));

    // System Health Score (max 200 points)
    const healthScore = 200 * (systemHealth / 100);

    // Procedure Score (max 100 points)
    const procedureScore = totalChecklists > 0 ?
      100 * (checklistsCompleted / totalChecklists) : 0;

    // Difficulty Multiplier
    const difficultyMultipliers: Record<Difficulty, number> = {
      'easy': 1.0,
      'medium': 1.5,
      'hard': 2.0,
      'extreme': 3.0
    };
    const difficultyMultiplier = difficultyMultipliers[landingZone.difficulty];

    // Total Score
    const baseScore = speedScore + precisionScore + angleScore +
                      fuelScore + timeScore + healthScore + procedureScore;
    const totalScore = baseScore * difficultyMultiplier;

    // Grade Assignment
    let grade: Grade;
    if (totalScore >= 2500) grade = 'S';
    else if (totalScore >= 2000) grade = 'A';
    else if (totalScore >= 1500) grade = 'B';
    else if (totalScore >= 1000) grade = 'C';
    else if (totalScore >= 500) grade = 'D';
    else grade = 'F';

    return {
      landingSpeedScore: speedScore,
      landingAngleScore: angleScore,
      precisionScore,
      fuelEfficiencyScore: fuelScore,
      timeEfficiencyScore: timeScore,
      systemHealthScore: healthScore,
      procedureScore,
      difficultyMultiplier,
      totalScore,
      grade
    };
  }

  calculatePrecisionBonus(distanceFromTarget: number, bonusRadius: number): number {
    if (distanceFromTarget <= bonusRadius) {
      return 500 * (1 - distanceFromTarget / bonusRadius);
    }
    return 0;
  }
}

/**
 * Mission Builder
 * Creates missions with objectives and checklists
 */
export class MissionBuilder {
  private lzDatabase: LandingZoneDatabase;

  constructor() {
    this.lzDatabase = new LandingZoneDatabase();
  }

  createTrainingMission(): Mission {
    const lz = this.lzDatabase.getZone('lz_tranquility')!;

    return {
      id: 'mission_training',
      name: 'Training Flight',
      briefing: 'Land at Mare Tranquillitatis Base Alpha. This is a training mission with forgiving parameters.',
      landingZone: lz,
      objectives: [
        {
          id: 'obj_land_safely',
          description: 'Land with impact speed < 3.0 m/s',
          type: 'primary',
          completed: false,
          points: 500
        },
        {
          id: 'obj_precision',
          description: 'Land within 100m of target',
          type: 'secondary',
          completed: false,
          points: 200
        },
        {
          id: 'obj_fuel_efficiency',
          description: 'Land with >30% fuel remaining',
          type: 'secondary',
          completed: false,
          points: 200
        },
        {
          id: 'obj_perfect_landing',
          description: 'Land with impact speed < 1.5 m/s',
          type: 'bonus',
          completed: false,
          points: 300
        }
      ],
      startAltitude: 5000,
      startVelocity: { x: 0, y: 0, z: -50 },
      startFuel: 200,
      parTime: 120,
      maxTime: 300
    };
  }

  createPrecisionMission(): Mission {
    const lz = this.lzDatabase.getZone('lz_serenitatis')!;

    return {
      id: 'mission_precision',
      name: 'Precision Landing',
      briefing: 'Land at Mare Serenitatis Outpost. Rocky terrain requires careful approach.',
      landingZone: lz,
      objectives: [
        {
          id: 'obj_land_safely',
          description: 'Land with impact speed < 2.5 m/s',
          type: 'primary',
          completed: false,
          points: 600
        },
        {
          id: 'obj_precision',
          description: 'Land within 50m of target',
          type: 'primary',
          completed: false,
          points: 400
        },
        {
          id: 'obj_fuel_efficiency',
          description: 'Land with >25% fuel remaining',
          type: 'secondary',
          completed: false,
          points: 250
        }
      ],
      startAltitude: 8000,
      startVelocity: { x: 10, y: 0, z: -60 },
      startFuel: 180,
      parTime: 150,
      maxTime: 400
    };
  }

  createChallengeMission(): Mission {
    const lz = this.lzDatabase.getZone('lz_copernicus')!;

    return {
      id: 'mission_challenge',
      name: 'Crater Rim Challenge',
      briefing: 'Land on the rim of Copernicus Crater. Extreme precision and control required.',
      landingZone: lz,
      objectives: [
        {
          id: 'obj_land_safely',
          description: 'Land with impact speed < 2.0 m/s',
          type: 'primary',
          completed: false,
          points: 700
        },
        {
          id: 'obj_precision',
          description: 'Land within 30m of target',
          type: 'primary',
          completed: false,
          points: 500
        },
        {
          id: 'obj_angle',
          description: 'Land within 3° of vertical',
          type: 'secondary',
          completed: false,
          points: 300
        }
      ],
      startAltitude: 10000,
      startVelocity: { x: -20, y: 15, z: -70 },
      startFuel: 150,
      parTime: 180,
      maxTime: 450
    };
  }
}

/**
 * Checklist System
 */
export class ChecklistSystem {
  private checklists: Checklist[] = [];

  addChecklist(checklist: Checklist): void {
    this.checklists.push(checklist);
  }

  getChecklist(id: string): Checklist | undefined {
    return this.checklists.find(c => c.id === id);
  }

  getAllChecklists(): Checklist[] {
    return this.checklists;
  }

  getChecklistsByPhase(phase: ChecklistPhase): Checklist[] {
    return this.checklists.filter(c => c.phase === phase);
  }

  updateChecklist(id: string): void {
    const checklist = this.getChecklist(id);
    if (!checklist) return;

    // Update each item
    for (const item of checklist.items) {
      if (!item.completed && item.verification) {
        item.completed = item.verification();
      }
    }

    // Check if all completed
    checklist.allCompleted = checklist.items.every(item => item.completed);
  }

  getCompletionRate(): number {
    if (this.checklists.length === 0) return 0;
    const completed = this.checklists.filter(c => c.allCompleted).length;
    return completed / this.checklists.length;
  }
}

/**
 * Mission System
 * Main integration point for missions, scoring, and objectives
 */
export class MissionSystem {
  private lzDatabase: LandingZoneDatabase;
  private scoringCalc: ScoringCalculator;
  private missionBuilder: MissionBuilder;
  private checklistSystem: ChecklistSystem;

  private currentMission: Mission | null = null;
  private missionStartTime: number = 0;
  private missionComplete: boolean = false;

  constructor() {
    this.lzDatabase = new LandingZoneDatabase();
    this.scoringCalc = new ScoringCalculator();
    this.missionBuilder = new MissionBuilder();
    this.checklistSystem = new ChecklistSystem();
  }

  // Landing Zones
  getLandingZone(id: string): LandingZone | undefined {
    return this.lzDatabase.getZone(id);
  }

  getAllLandingZones(): LandingZone[] {
    return this.lzDatabase.getAllZones();
  }

  // Missions
  loadMission(mission: Mission): void {
    this.currentMission = mission;
    this.missionStartTime = 0;
    this.missionComplete = false;
  }

  startMission(currentTime: number): void {
    this.missionStartTime = currentTime;
  }

  getCurrentMission(): Mission | null {
    return this.currentMission;
  }

  // Objectives
  completeObjective(objectiveId: string): void {
    if (!this.currentMission) return;

    const objective = this.currentMission.objectives.find(o => o.id === objectiveId);
    if (objective) {
      objective.completed = true;
    }
  }

  checkObjective(objectiveId: string, condition: boolean): void {
    if (condition) {
      this.completeObjective(objectiveId);
    }
  }

  getObjectivesCompletion(): { completed: number; total: number } {
    if (!this.currentMission) return { completed: 0, total: 0 };

    const completed = this.currentMission.objectives.filter(o => o.completed).length;
    const total = this.currentMission.objectives.length;

    return { completed, total };
  }

  // Scoring
  calculateMissionScore(
    landingSpeed: number,
    landingAngle: number,
    landingPosition: Vector3,
    targetPosition: Vector3,
    fuelRemaining: number,
    systemHealth: number,
    currentTime: number
  ): MissionResult {
    if (!this.currentMission) {
      throw new Error('No active mission');
    }

    const missionTime = currentTime - this.missionStartTime;
    const distance = this.calculateDistance(landingPosition, targetPosition);

    const score = this.scoringCalc.calculateScore(
      landingSpeed,
      landingAngle,
      distance,
      fuelRemaining,
      this.currentMission.startFuel,
      missionTime,
      this.currentMission.parTime,
      systemHealth,
      this.checklistSystem.getChecklistsByPhase('pre-landing').filter(c => c.allCompleted).length,
      this.checklistSystem.getChecklistsByPhase('pre-landing').length,
      this.currentMission.landingZone
    );

    // Auto-complete objectives based on performance
    this.checkObjective('obj_land_safely',
      landingSpeed <= this.currentMission.landingZone.maxLandingSpeed);
    this.checkObjective('obj_precision',
      distance <= this.currentMission.landingZone.targetPrecision * 2);
    this.checkObjective('obj_fuel_efficiency',
      (fuelRemaining / this.currentMission.startFuel) >= 0.3);
    this.checkObjective('obj_perfect_landing',
      landingSpeed <= 1.5);
    this.checkObjective('obj_angle',
      landingAngle <= 3);

    const objectives = this.getObjectivesCompletion();

    this.missionComplete = true;

    return {
      success: landingSpeed <= this.currentMission.landingZone.maxLandingSpeed,
      missionTime,
      score,
      objectivesCompleted: objectives.completed,
      objectivesTotal: objectives.total,
      checklistsCompleted: this.checklistSystem.getAllChecklists().filter(c => c.allCompleted).length,
      checklistsTotal: this.checklistSystem.getAllChecklists().length
    };
  }

  // Checklists
  addChecklist(checklist: Checklist): void {
    this.checklistSystem.addChecklist(checklist);
  }

  updateChecklists(): void {
    for (const checklist of this.checklistSystem.getAllChecklists()) {
      this.checklistSystem.updateChecklist(checklist.id);
    }
  }

  getChecklists(): Checklist[] {
    return this.checklistSystem.getAllChecklists();
  }

  // Utilities
  isInLandingZone(position: Vector3, landingZone: LandingZone): boolean {
    // Simplified - just check radial distance for now
    const targetPos = this.latLonToPosition(landingZone.coordinates);
    const distance = this.calculateDistance(position, targetPos);
    return distance <= landingZone.radius;
  }

  private calculateDistance(a: Vector3, b: Vector3): number {
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const dz = b.z - a.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  private latLonToPosition(coords: LatLon): Vector3 {
    // Simplified conversion (assumes Moon radius)
    const MOON_RADIUS = 1737400;
    const latRad = coords.lat * Math.PI / 180;
    const lonRad = coords.lon * Math.PI / 180;

    return {
      x: MOON_RADIUS * Math.cos(latRad) * Math.cos(lonRad),
      y: MOON_RADIUS * Math.cos(latRad) * Math.sin(lonRad),
      z: MOON_RADIUS * Math.sin(latRad)
    };
  }

  // Mission Builder Access
  createTrainingMission(): Mission {
    return this.missionBuilder.createTrainingMission();
  }

  createPrecisionMission(): Mission {
    return this.missionBuilder.createPrecisionMission();
  }

  createChallengeMission(): Mission {
    return this.missionBuilder.createChallengeMission();
  }
}
