/**
 * Crew System
 *
 * Manages spacecraft crew members:
 * - Individual crew members with skills and attributes
 * - Station assignments and efficiency
 * - Fatigue and morale tracking
 * - Injuries and casualties from damage
 * - Skill-based performance bonuses
 * - Crew actions and automation
 */

export type CrewSkill =
  | 'pilot'
  | 'engineer'
  | 'weapons'
  | 'sensors'
  | 'communications'
  | 'medical'
  | 'damage_control'
  | 'leadership';

export type CrewStatus = 'healthy' | 'injured' | 'incapacitated' | 'deceased';

export type StationType =
  | 'command'
  | 'helm'
  | 'engineering'
  | 'weapons'
  | 'sensors'
  | 'communications'
  | 'medical'
  | 'damage_control'
  | 'unassigned';

export interface CrewSkillLevel {
  skill: CrewSkill;
  level: number; // 1-5 (1 = novice, 5 = expert)
  experience: number; // 0-1000 XP
}

export interface CrewMember {
  id: string;
  name: string;
  rank: string;

  // Skills
  skills: CrewSkillLevel[];

  // Physical state
  health: number; // 0-100
  status: CrewStatus;
  injuries: string[]; // Description of injuries

  // Mental state
  fatigue: number; // 0-100 (0 = well-rested, 100 = exhausted)
  morale: number; // 0-100 (0 = broken, 100 = excellent)
  stress: number; // 0-100 (0 = calm, 100 = panicked)

  // Assignment
  station: StationType;
  assignedZone: string | null; // For damage control

  // Experience
  totalExperience: number;
  missionsCompleted: number;

  // Metadata
  biography?: string;
}

export interface StationAssignment {
  station: StationType;
  assignedCrew: string[]; // Crew member IDs
  efficiency: number; // 0-1 (based on crew skills)
  maxCrew: number;
}

export interface CrewAction {
  id: string;
  crewId: string;
  actionType: 'repair' | 'heal' | 'operate_system' | 'move' | 'rest';
  targetId: string | null; // System ID or zone ID
  startTime: number;
  duration: number;
  progress: number; // 0-1
  completed: boolean;
}

/**
 * Crew Management System
 */
export class CrewSystem {
  private crew: Map<string, CrewMember> = new Map();
  private stations: Map<StationType, StationAssignment> = new Map();
  private actions: Map<string, CrewAction> = new Map();

  // Fatigue parameters
  private fatigueRate: number = 1.0; // Fatigue gain per hour
  private restRate: number = 10.0; // Fatigue recovery per hour
  private stressDecayRate: number = 2.0; // Stress reduction per hour

  // Performance parameters
  private fatiguePerformancePenalty: number = 0.5; // Max 50% penalty
  private injuryPerformancePenalty: number = 0.7; // Max 70% penalty

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor() {
    this.initializeStations();
  }

  /**
   * Initialize station assignments
   */
  private initializeStations(): void {
    const stationTypes: StationType[] = [
      'command', 'helm', 'engineering', 'weapons',
      'sensors', 'communications', 'medical', 'damage_control'
    ];

    stationTypes.forEach(type => {
      this.stations.set(type, {
        station: type,
        assignedCrew: [],
        efficiency: 0,
        maxCrew: type === 'damage_control' ? 4 : (type === 'command' ? 1 : 2)
      });
    });
  }

  /**
   * Add crew member
   */
  public addCrewMember(member: CrewMember): void {
    this.crew.set(member.id, member);
    this.logEvent('crew_added', { id: member.id, name: member.name, rank: member.rank });
  }

  /**
   * Remove crew member (death or evacuation)
   */
  public removeCrewMember(crewId: string): void {
    const member = this.crew.get(crewId);
    if (!member) return;

    // Unassign from station
    if (member.station !== 'unassigned') {
      this.unassignFromStation(crewId);
    }

    this.crew.delete(crewId);
    this.logEvent('crew_removed', { id: crewId, name: member.name });
  }

  /**
   * Assign crew member to station
   */
  public assignToStation(crewId: string, station: StationType): boolean {
    const member = this.crew.get(crewId);
    if (!member) return false;

    const stationData = this.stations.get(station);
    if (!stationData) return false;

    // Check if station is full
    if (stationData.assignedCrew.length >= stationData.maxCrew) {
      this.logEvent('assignment_failed', { crewId, station, reason: 'station_full' });
      return false;
    }

    // Check if crew member is capable
    if (member.status === 'deceased' || member.status === 'incapacitated') {
      this.logEvent('assignment_failed', { crewId, station, reason: 'crew_incapacitated' });
      return false;
    }

    // Unassign from current station
    if (member.station !== 'unassigned') {
      this.unassignFromStation(crewId);
    }

    // Assign to new station
    member.station = station;
    stationData.assignedCrew.push(crewId);

    // Recalculate station efficiency
    this.updateStationEfficiency(station);

    this.logEvent('crew_assigned', { crewId, station });
    return true;
  }

  /**
   * Unassign crew member from station
   */
  public unassignFromStation(crewId: string): void {
    const member = this.crew.get(crewId);
    if (!member || member.station === 'unassigned') return;

    const station = this.stations.get(member.station);
    if (station) {
      station.assignedCrew = station.assignedCrew.filter(id => id !== crewId);
      this.updateStationEfficiency(member.station);
    }

    member.station = 'unassigned';
    this.logEvent('crew_unassigned', { crewId });
  }

  /**
   * Update station efficiency based on assigned crew skills
   */
  private updateStationEfficiency(stationType: StationType): void {
    const station = this.stations.get(stationType);
    if (!station) return;

    if (station.assignedCrew.length === 0) {
      station.efficiency = 0;
      return;
    }

    // Map station type to relevant skill
    const skillMap: Record<StationType, CrewSkill | null> = {
      'command': 'leadership',
      'helm': 'pilot',
      'engineering': 'engineer',
      'weapons': 'weapons',
      'sensors': 'sensors',
      'communications': 'communications',
      'medical': 'medical',
      'damage_control': 'damage_control',
      'unassigned': null
    };

    const relevantSkill = skillMap[stationType];
    if (!relevantSkill) {
      station.efficiency = 1.0;
      return;
    }

    // Calculate average skill level and performance
    let totalEfficiency = 0;
    let crewCount = 0;

    for (const crewId of station.assignedCrew) {
      const member = this.crew.get(crewId);
      if (!member || member.status === 'deceased') continue;

      // Get skill level
      const skillLevel = member.skills.find(s => s.skill === relevantSkill);
      const baseSkill = skillLevel ? skillLevel.level / 5 : 0.2; // 20% if unskilled

      // Apply fatigue penalty
      const fatiguePenalty = (member.fatigue / 100) * this.fatiguePerformancePenalty;

      // Apply injury penalty
      const injuryPenalty = member.status === 'injured' ? this.injuryPerformancePenalty : 0;

      // Calculate crew member efficiency
      const efficiency = baseSkill * (1 - fatiguePenalty - injuryPenalty);

      totalEfficiency += Math.max(0.1, efficiency); // Minimum 10%
      crewCount++;
    }

    station.efficiency = crewCount > 0 ? totalEfficiency / crewCount : 0;
  }

  /**
   * Get station efficiency
   */
  public getStationEfficiency(station: StationType): number {
    const stationData = this.stations.get(station);
    return stationData ? stationData.efficiency : 0;
  }

  /**
   * Apply damage to crew (from ship damage)
   */
  public applyCrewDamage(zoneId: string, severity: number): void {
    // Find crew in or near the damaged zone
    const affectedCrew: CrewMember[] = [];

    this.crew.forEach(member => {
      // Crew at damage control station or in specific zones can be affected
      if (member.assignedZone === zoneId || Math.random() < severity * 0.3) {
        affectedCrew.push(member);
      }
    });

    affectedCrew.forEach(member => {
      // Calculate injury severity
      const injurySeverity = severity * (0.5 + Math.random() * 0.5);

      if (injurySeverity > 0.8) {
        // Fatal injury
        member.status = 'deceased';
        member.health = 0;
        member.injuries.push(`Fatal injuries from ${zoneId} damage`);
        this.logEvent('crew_casualty', {
          crewId: member.id,
          name: member.name,
          zone: zoneId,
          fatal: true
        });
        this.unassignFromStation(member.id);
      } else if (injurySeverity > 0.5) {
        // Severe injury - incapacitated
        member.status = 'incapacitated';
        member.health = Math.max(0, member.health - injurySeverity * 50);
        member.injuries.push(`Severe injuries from ${zoneId} damage`);
        this.logEvent('crew_casualty', {
          crewId: member.id,
          name: member.name,
          zone: zoneId,
          severity: 'severe'
        });
        this.unassignFromStation(member.id);
      } else if (injurySeverity > 0.2) {
        // Moderate injury
        member.status = 'injured';
        member.health = Math.max(0, member.health - injurySeverity * 30);
        member.injuries.push(`Injuries from ${zoneId} damage`);
        this.logEvent('crew_injury', {
          crewId: member.id,
          name: member.name,
          zone: zoneId,
          severity: 'moderate'
        });

        // Update station efficiency
        if (member.station !== 'unassigned') {
          this.updateStationEfficiency(member.station);
        }
      }

      // Add stress from damage
      member.stress = Math.min(100, member.stress + injurySeverity * 40);
    });
  }

  /**
   * Heal crew member
   */
  public healCrewMember(crewId: string, healingAmount: number): void {
    const member = this.crew.get(crewId);
    if (!member) return;

    if (member.status === 'deceased') {
      return; // Can't heal the dead
    }

    member.health = Math.min(100, member.health + healingAmount);

    // Recover from incapacitation
    if (member.status === 'incapacitated' && member.health > 50) {
      member.status = 'injured';
      this.logEvent('crew_recovered', { crewId, from: 'incapacitated', to: 'injured' });
    }

    // Recover from injury
    if (member.status === 'injured' && member.health > 80) {
      member.status = 'healthy';
      member.injuries = [];
      this.logEvent('crew_recovered', { crewId, from: 'injured', to: 'healthy' });
    }

    // Update station efficiency
    if (member.station !== 'unassigned') {
      this.updateStationEfficiency(member.station);
    }
  }

  /**
   * Update crew system (fatigue, stress, actions)
   */
  public update(dt: number): void {
    const dtHours = dt / 3600; // Convert to hours

    this.crew.forEach(member => {
      if (member.status === 'deceased') return;

      // Update fatigue
      if (member.station !== 'unassigned' && member.station !== 'medical') {
        // Working - gain fatigue
        member.fatigue = Math.min(100, member.fatigue + this.fatigueRate * dtHours);
      } else {
        // Resting - lose fatigue
        member.fatigue = Math.max(0, member.fatigue - this.restRate * dtHours);
      }

      // Update stress (naturally decreases over time)
      member.stress = Math.max(0, member.stress - this.stressDecayRate * dtHours);

      // Update morale based on ship condition, stress, fatigue
      const moraleTarget = 75 - (member.stress * 0.5) - (member.fatigue * 0.3);
      if (member.morale < moraleTarget) {
        member.morale = Math.min(moraleTarget, member.morale + 5 * dtHours);
      } else {
        member.morale = Math.max(moraleTarget, member.morale - 2 * dtHours);
      }
      member.morale = Math.max(0, Math.min(100, member.morale));

      // Check for fatigue-related incapacitation
      if (member.fatigue > 95 && member.status === 'healthy') {
        member.status = 'incapacitated';
        member.injuries.push('Exhaustion');
        this.logEvent('crew_exhaustion', { crewId: member.id, name: member.name });
        this.unassignFromStation(member.id);
      }
    });

    // Update all stations
    this.stations.forEach((_, type) => {
      this.updateStationEfficiency(type);
    });

    // Update actions
    this.updateActions(dt);
  }

  /**
   * Update crew actions
   */
  private updateActions(dt: number): void {
    this.actions.forEach((action, id) => {
      if (action.completed) return;

      action.progress += dt / action.duration;

      if (action.progress >= 1.0) {
        action.progress = 1.0;
        action.completed = true;

        this.logEvent('action_completed', {
          actionId: id,
          crewId: action.crewId,
          type: action.actionType
        });

        // Grant experience
        const member = this.crew.get(action.crewId);
        if (member) {
          this.grantExperience(member, action.actionType);
        }
      }
    });
  }

  /**
   * Grant experience to crew member
   */
  private grantExperience(member: CrewMember, actionType: string): void {
    const xpGain = 10; // Base XP per action

    // Determine which skill to improve
    const skillMap: Record<string, CrewSkill> = {
      'repair': 'engineer',
      'heal': 'medical',
      'operate_system': 'engineer'
    };

    const skill = skillMap[actionType];
    if (skill) {
      const skillLevel = member.skills.find(s => s.skill === skill);
      if (skillLevel) {
        skillLevel.experience += xpGain;

        // Level up if enough XP
        const xpRequired = skillLevel.level * 200;
        if (skillLevel.experience >= xpRequired && skillLevel.level < 5) {
          skillLevel.level++;
          skillLevel.experience = 0;

          this.logEvent('skill_levelup', {
            crewId: member.id,
            skill,
            newLevel: skillLevel.level
          });
        }
      }
    }

    member.totalExperience += xpGain;
  }

  /**
   * Get crew member
   */
  public getCrewMember(crewId: string): CrewMember | undefined {
    return this.crew.get(crewId);
  }

  /**
   * Get all crew members
   */
  public getAllCrew(): CrewMember[] {
    return Array.from(this.crew.values());
  }

  /**
   * Get crew count by status
   */
  public getCrewCountByStatus(status: CrewStatus): number {
    return Array.from(this.crew.values()).filter(m => m.status === status).length;
  }

  /**
   * Get station assignment
   */
  public getStation(station: StationType): StationAssignment | undefined {
    return this.stations.get(station);
  }

  /**
   * Get all stations
   */
  public getAllStations(): StationAssignment[] {
    return Array.from(this.stations.values());
  }

  /**
   * Get crew system state
   */
  public getState() {
    return {
      crewCount: this.crew.size,
      crewMembers: this.getAllCrew(),
      stations: this.getAllStations(),
      casualties: this.getCrewCountByStatus('deceased'),
      injured: this.getCrewCountByStatus('injured'),
      incapacitated: this.getCrewCountByStatus('incapacitated'),
      averageMorale: this.getAverageMorale(),
      averageFatigue: this.getAverageFatigue()
    };
  }

  /**
   * Get average crew morale
   */
  private getAverageMorale(): number {
    const activeCrew = Array.from(this.crew.values()).filter(m => m.status !== 'deceased');
    if (activeCrew.length === 0) return 0;

    const totalMorale = activeCrew.reduce((sum, m) => sum + m.morale, 0);
    return totalMorale / activeCrew.length;
  }

  /**
   * Get average crew fatigue
   */
  private getAverageFatigue(): number {
    const activeCrew = Array.from(this.crew.values()).filter(m => m.status !== 'deceased');
    if (activeCrew.length === 0) return 0;

    const totalFatigue = activeCrew.reduce((sum, m) => sum + m.fatigue, 0);
    return totalFatigue / activeCrew.length;
  }

  private logEvent(type: string, data: any): void {
    this.events.push({ time: Date.now(), type, data });
  }

  public getEvents(): Array<{ time: number; type: string; data: any }> {
    const events = [...this.events];
    this.events = [];
    return events;
  }
}

/**
 * Create default crew member
 */
export function createCrewMember(
  id: string,
  name: string,
  rank: string,
  primarySkill: CrewSkill,
  skillLevel: number = 3
): CrewMember {
  return {
    id,
    name,
    rank,
    skills: [
      {
        skill: primarySkill,
        level: skillLevel,
        experience: 0
      }
    ],
    health: 100,
    status: 'healthy',
    injuries: [],
    fatigue: 0,
    morale: 75,
    stress: 0,
    station: 'unassigned',
    assignedZone: null,
    totalExperience: 0,
    missionsCompleted: 0
  };
}

/**
 * Create a full crew complement
 */
export function createStandardCrew(): CrewMember[] {
  return [
    createCrewMember('crew_001', 'Commander Sarah Chen', 'Commander', 'leadership', 5),
    createCrewMember('crew_002', 'Lt. Marcus Rivera', 'Pilot', 'pilot', 4),
    createCrewMember('crew_003', 'Lt. Kenji Tanaka', 'Engineer', 'engineer', 4),
    createCrewMember('crew_004', 'Ensign Alex Kowalski', 'Weapons Officer', 'weapons', 3),
    createCrewMember('crew_005', 'Lt. Priya Sharma', 'Sensors Officer', 'sensors', 4),
    createCrewMember('crew_006', 'Dr. James Wilson', 'Medical Officer', 'medical', 4),
    createCrewMember('crew_007', 'CPO Maria Santos', 'Damage Control', 'damage_control', 3),
    createCrewMember('crew_008', 'Ensign Thomas Lee', 'Communications', 'communications', 2)
  ];
}
