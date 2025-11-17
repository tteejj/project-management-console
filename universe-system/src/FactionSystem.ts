/**
 * FactionSystem.ts
 * Comprehensive faction diplomacy, reputation, and political dynamics
 */

import { Vector3 } from './CelestialBody';
import { SpaceStation } from './StationGenerator';

export interface Faction {
  id: string;
  name: string;
  description: string;
  government: GovernmentType;
  ideology: Ideology;
  territory: Territory[];
  capital?: string;          // Station ID
  population: number;
  military: number;          // Military strength (arbitrary units)
  economy: number;           // Economic power (credits/day)
  technology: number;        // Tech level (0-10)
  influence: number;         // Political influence (0-100)
  color: string;             // For visualization
}

export type GovernmentType =
  | 'DEMOCRACY'
  | 'AUTOCRACY'
  | 'CORPORATE'
  | 'MILITARY'
  | 'THEOCRACY'
  | 'ANARCHY';

export interface Ideology {
  authoritarian: number;     // -1 (libertarian) to 1 (authoritarian)
  economic: number;          // -1 (planned) to 1 (free market)
  militaristic: number;      // 0-1
  expansionist: number;      // 0-1
  xenophobic: number;        // 0-1
  technological: number;     // 0-1 (traditional vs progressive)
}

export interface Territory {
  systemId: string;
  controlLevel: number;      // 0-1 (how much of system they control)
  stations: string[];        // Station IDs
  contested: boolean;
}

export interface DiplomaticRelation {
  faction1: string;
  faction2: string;
  standing: number;          // -100 (war) to 100 (alliance)
  state: DiplomaticState;
  treaties: Treaty[];
  history: DiplomaticEvent[];
  lastInteraction: number;
}

export type DiplomaticState =
  | 'WAR'
  | 'HOSTILE'
  | 'UNFRIENDLY'
  | 'NEUTRAL'
  | 'FRIENDLY'
  | 'ALLIED';

export interface Treaty {
  type: TreatyType;
  signedDate: number;
  expiryDate?: number;
  terms: Map<string, any>;
}

export type TreatyType =
  | 'TRADE_AGREEMENT'
  | 'NON_AGGRESSION'
  | 'MILITARY_ALLIANCE'
  | 'RESEARCH_COOPERATION'
  | 'BORDER_AGREEMENT'
  | 'MUTUAL_DEFENSE';

export interface DiplomaticEvent {
  type: EventType;
  date: number;
  impact: number;            // -100 to 100 (impact on relations)
  description: string;
}

export type EventType =
  | 'TRADE'
  | 'AID'
  | 'INSULT'
  | 'ATTACK'
  | 'TREATY_SIGNED'
  | 'TREATY_BROKEN'
  | 'BORDER_INCIDENT'
  | 'TECHNOLOGY_SHARED';

export interface Reputation {
  playerId: string;
  factionId: string;
  standing: number;          // -100 to 100
  rank: ReputationRank;
  actions: ReputationAction[];
  lastUpdate: number;
}

export type ReputationRank =
  | 'NEMESIS'
  | 'HOSTILE'
  | 'UNFRIENDLY'
  | 'NEUTRAL'
  | 'ACCEPTED'
  | 'FRIENDLY'
  | 'HONORED'
  | 'REVERED';

export interface ReputationAction {
  type: ActionType;
  value: number;
  timestamp: number;
  description: string;
}

export type ActionType =
  | 'TRADE'
  | 'MISSION_COMPLETE'
  | 'MISSION_FAILED'
  | 'ATTACKED_SHIP'
  | 'DESTROYED_SHIP'
  | 'HELPED_SHIP'
  | 'CARGO_DELIVERED'
  | 'BOUNTY_COLLECTED';

export interface Conflict {
  id: string;
  factions: string[];
  type: 'BORDER_WAR' | 'TRADE_WAR' | 'IDEOLOGICAL' | 'RESOURCE';
  startDate: number;
  intensity: number;         // 0-1
  frontlines: Vector3[];     // Battle locations
  casualties: Map<string, number>; // Faction -> casualties
}

/**
 * Faction and Diplomacy System
 */
export class FactionSystem {
  private factions: Map<string, Faction> = new Map();
  private relations: Map<string, DiplomaticRelation> = new Map();
  private reputations: Map<string, Reputation> = new Map();
  private conflicts: Map<string, Conflict> = new Map();

  constructor() {
    this.initializeDefaultFactions();
  }

  /**
   * Initialize default factions
   */
  private initializeDefaultFactions(): void {
    // United Earth Government
    this.addFaction({
      id: 'UNITED_EARTH',
      name: 'United Earth Government',
      description: 'Democratic federation of Earth nations',
      government: 'DEMOCRACY',
      ideology: {
        authoritarian: -0.3,
        economic: 0.2,
        militaristic: 0.4,
        expansionist: 0.5,
        xenophobic: -0.2,
        technological: 0.7
      },
      territory: [],
      population: 15000000000,
      military: 1000,
      economy: 1000000000,
      technology: 8,
      influence: 85,
      color: '#0066CC'
    });

    // Mars Federation
    this.addFaction({
      id: 'MARS_FEDERATION',
      name: 'Mars Federation',
      description: 'Independent colonies of Mars and outer planets',
      government: 'DEMOCRACY',
      ideology: {
        authoritarian: -0.5,
        economic: 0.6,
        militaristic: 0.3,
        expansionist: 0.7,
        xenophobic: 0.1,
        technological: 0.9
      },
      territory: [],
      population: 5000000000,
      military: 600,
      economy: 500000000,
      technology: 9,
      influence: 70,
      color: '#CC3300'
    });

    // Titan Consortium
    this.addFaction({
      id: 'TITAN_CONSORTIUM',
      name: 'Titan Consortium',
      description: 'Corporate alliance controlling outer system resources',
      government: 'CORPORATE',
      ideology: {
        authoritarian: 0.4,
        economic: 0.9,
        militaristic: 0.2,
        expansionist: 0.8,
        xenophobic: 0.3,
        technological: 0.8
      },
      territory: [],
      population: 2000000000,
      military: 400,
      economy: 800000000,
      technology: 7,
      influence: 65,
      color: '#FFD700'
    });

    // Independent Colonies
    this.addFaction({
      id: 'INDEPENDENT',
      name: 'Independent Colonies',
      description: 'Loose alliance of independent stations and settlements',
      government: 'DEMOCRACY',
      ideology: {
        authoritarian: -0.7,
        economic: 0.5,
        militaristic: 0.1,
        expansionist: 0.4,
        xenophobic: -0.5,
        technological: 0.6
      },
      territory: [],
      population: 1000000000,
      military: 200,
      economy: 200000000,
      technology: 6,
      influence: 40,
      color: '#00CC66'
    });

    // Pirates (hostile faction)
    this.addFaction({
      id: 'PIRATE',
      name: 'Pirate Clans',
      description: 'Decentralized criminal organizations',
      government: 'ANARCHY',
      ideology: {
        authoritarian: -0.8,
        economic: 0.8,
        militaristic: 0.9,
        expansionist: 0.3,
        xenophobic: 0.6,
        technological: 0.4
      },
      territory: [],
      population: 50000000,
      military: 300,
      economy: 50000000,
      technology: 5,
      influence: 20,
      color: '#990000'
    });

    // Initialize relations
    this.initializeRelations();
  }

  /**
   * Initialize diplomatic relations
   */
  private initializeRelations(): void {
    const factionIds = Array.from(this.factions.keys());

    for (let i = 0; i < factionIds.length; i++) {
      for (let j = i + 1; j < factionIds.length; j++) {
        const faction1 = this.factions.get(factionIds[i])!;
        const faction2 = this.factions.get(factionIds[j])!;

        const standing = this.calculateInitialStanding(faction1, faction2);
        const state = this.getStateFromStanding(standing);

        this.relations.set(this.getRelationKey(factionIds[i], factionIds[j]), {
          faction1: factionIds[i],
          faction2: factionIds[j],
          standing,
          state,
          treaties: [],
          history: [],
          lastInteraction: Date.now()
        });
      }
    }
  }

  /**
   * Calculate initial standing based on ideologies
   */
  private calculateInitialStanding(faction1: Faction, faction2: Faction): number {
    // Pirates are hostile to everyone
    if (faction1.id === 'PIRATE' || faction2.id === 'PIRATE') {
      return -60;
    }

    let standing = 0;

    // Ideological compatibility
    const ideoDiff =
      Math.abs(faction1.ideology.authoritarian - faction2.ideology.authoritarian) +
      Math.abs(faction1.ideology.economic - faction2.ideology.economic) +
      Math.abs(faction1.ideology.xenophobic - faction2.ideology.xenophobic);

    standing -= ideoDiff * 20; // More different = worse relations

    // Government compatibility
    if (faction1.government === faction2.government) {
      standing += 20;
    }

    // Specific relationships
    if ((faction1.id === 'UNITED_EARTH' && faction2.id === 'MARS_FEDERATION') ||
        (faction1.id === 'MARS_FEDERATION' && faction2.id === 'UNITED_EARTH')) {
      standing += 40; // Historical allies
    }

    if ((faction1.id === 'TITAN_CONSORTIUM' && faction2.id === 'INDEPENDENT') ||
        (faction1.id === 'INDEPENDENT' && faction2.id === 'TITAN_CONSORTIUM')) {
      standing -= 30; // Corporate vs independent tension
    }

    return Math.max(-100, Math.min(100, standing));
  }

  /**
   * Add faction
   */
  addFaction(faction: Faction): void {
    this.factions.set(faction.id, faction);
  }

  /**
   * Update relations based on events
   */
  update(deltaTime: number): void {
    // Natural drift toward neutral over time
    for (const relation of this.relations.values()) {
      if (relation.state !== 'WAR' && relation.state !== 'ALLIED') {
        const drift = (0 - relation.standing) * 0.001 * deltaTime;
        relation.standing += drift;
        relation.state = this.getStateFromStanding(relation.standing);
      }
    }

    // Update conflicts
    for (const conflict of this.conflicts.values()) {
      this.updateConflict(conflict, deltaTime);
    }

    // Check for treaty expirations
    for (const relation of this.relations.values()) {
      relation.treaties = relation.treaties.filter(treaty => {
        if (treaty.expiryDate && Date.now() > treaty.expiryDate) {
          this.addDiplomaticEvent(
            relation,
            'TREATY_BROKEN',
            -20,
            `${treaty.type} expired`
          );
          return false;
        }
        return true;
      });
    }
  }

  /**
   * Update ongoing conflict
   */
  private updateConflict(conflict: Conflict, deltaTime: number): void {
    // Conflicts cause casualties
    for (const factionId of conflict.factions) {
      const casualties = (conflict.intensity * 100 * deltaTime) / 86400; // Per day
      const current = conflict.casualties.get(factionId) || 0;
      conflict.casualties.set(factionId, current + casualties);

      // Reduce military strength
      const faction = this.factions.get(factionId);
      if (faction) {
        faction.military = Math.max(0, faction.military - casualties * 0.01);
      }
    }

    // Intensity may decrease over time
    conflict.intensity *= (1 - 0.01 * deltaTime / 86400); // Decay

    // End conflict if intensity too low
    if (conflict.intensity < 0.1) {
      this.endConflict(conflict.id);
    }
  }

  /**
   * End a conflict
   */
  private endConflict(conflictId: string): void {
    const conflict = this.conflicts.get(conflictId);
    if (!conflict) return;

    // Update relations between warring factions
    for (let i = 0; i < conflict.factions.length; i++) {
      for (let j = i + 1; j < conflict.factions.length; j++) {
        const relation = this.getRelation(conflict.factions[i], conflict.factions[j]);
        if (relation) {
          relation.standing = Math.min(-20, relation.standing); // Still hostile after war
          relation.state = this.getStateFromStanding(relation.standing);
        }
      }
    }

    this.conflicts.delete(conflictId);
  }

  /**
   * Get or create player reputation with faction
   */
  getReputation(playerId: string, factionId: string): Reputation {
    const key = `${playerId}_${factionId}`;
    let rep = this.reputations.get(key);

    if (!rep) {
      rep = {
        playerId,
        factionId,
        standing: 0,
        rank: 'NEUTRAL',
        actions: [],
        lastUpdate: Date.now()
      };
      this.reputations.set(key, rep);
    }

    return rep;
  }

  /**
   * Modify player reputation
   */
  modifyReputation(
    playerId: string,
    factionId: string,
    change: number,
    actionType: ActionType,
    description: string
  ): void {
    const rep = this.getReputation(playerId, factionId);

    rep.standing = Math.max(-100, Math.min(100, rep.standing + change));
    rep.rank = this.getRankFromStanding(rep.standing);
    rep.actions.push({
      type: actionType,
      value: change,
      timestamp: Date.now(),
      description
    });
    rep.lastUpdate = Date.now();

    // Keep only recent actions
    if (rep.actions.length > 100) {
      rep.actions = rep.actions.slice(-50);
    }

    // Ripple effect to allied/enemy factions
    this.propagateReputationChange(playerId, factionId, change);
  }

  /**
   * Propagate reputation change to related factions
   */
  private propagateReputationChange(playerId: string, factionId: string, change: number): void {
    for (const otherFaction of this.factions.keys()) {
      if (otherFaction === factionId) continue;

      const relation = this.getRelation(factionId, otherFaction);
      if (!relation) continue;

      // Allies like friends of friends, enemies hate friends of enemies
      const rippleChange = change * (relation.standing / 100) * 0.2; // 20% ripple

      if (Math.abs(rippleChange) > 1) {
        const otherRep = this.getReputation(playerId, otherFaction);
        otherRep.standing = Math.max(-100, Math.min(100, otherRep.standing + rippleChange));
        otherRep.rank = this.getRankFromStanding(otherRep.standing);
      }
    }
  }

  /**
   * Get diplomatic relation between two factions
   */
  getRelation(faction1: string, faction2: string): DiplomaticRelation | undefined {
    const key = this.getRelationKey(faction1, faction2);
    return this.relations.get(key);
  }

  /**
   * Modify diplomatic relation
   */
  modifyRelation(
    faction1: string,
    faction2: string,
    change: number,
    eventType: EventType,
    description: string
  ): void {
    const relation = this.getRelation(faction1, faction2);
    if (!relation) return;

    relation.standing = Math.max(-100, Math.min(100, relation.standing + change));
    relation.state = this.getStateFromStanding(relation.standing);

    this.addDiplomaticEvent(relation, eventType, change, description);

    // Check for war/peace
    if (relation.standing <= -80 && relation.state !== 'WAR') {
      this.declareWar(faction1, faction2);
    } else if (relation.standing >= 80 && relation.state !== 'ALLIED') {
      this.formAlliance(faction1, faction2);
    }
  }

  /**
   * Declare war between factions
   */
  private declareWar(faction1: string, faction2: string): void {
    const relation = this.getRelation(faction1, faction2);
    if (!relation) return;

    relation.state = 'WAR';

    // Create conflict
    const conflict: Conflict = {
      id: `war_${faction1}_${faction2}_${Date.now()}`,
      factions: [faction1, faction2],
      type: 'IDEOLOGICAL',
      startDate: Date.now(),
      intensity: 0.8,
      frontlines: [],
      casualties: new Map()
    };

    this.conflicts.set(conflict.id, conflict);

    this.addDiplomaticEvent(relation, 'ATTACK', -50, 'War declared');
  }

  /**
   * Form alliance
   */
  private formAlliance(faction1: string, faction2: string): void {
    const relation = this.getRelation(faction1, faction2);
    if (!relation) return;

    relation.state = 'ALLIED';

    // Add alliance treaty
    relation.treaties.push({
      type: 'MILITARY_ALLIANCE',
      signedDate: Date.now(),
      terms: new Map([
        ['mutual_defense', true],
        ['shared_intel', true]
      ])
    });

    this.addDiplomaticEvent(relation, 'TREATY_SIGNED', 30, 'Alliance formed');
  }

  /**
   * Add diplomatic event
   */
  private addDiplomaticEvent(
    relation: DiplomaticRelation,
    type: EventType,
    impact: number,
    description: string
  ): void {
    relation.history.push({
      type,
      date: Date.now(),
      impact,
      description
    });

    // Keep only recent history
    if (relation.history.length > 50) {
      relation.history = relation.history.slice(-25);
    }

    relation.lastInteraction = Date.now();
  }

  /**
   * Get diplomatic state from standing
   */
  private getStateFromStanding(standing: number): DiplomaticState {
    if (standing <= -80) return 'WAR';
    if (standing <= -40) return 'HOSTILE';
    if (standing <= -10) return 'UNFRIENDLY';
    if (standing <= 10) return 'NEUTRAL';
    if (standing <= 40) return 'FRIENDLY';
    return 'ALLIED';
  }

  /**
   * Get reputation rank from standing
   */
  private getRankFromStanding(standing: number): ReputationRank {
    if (standing <= -80) return 'NEMESIS';
    if (standing <= -40) return 'HOSTILE';
    if (standing <= -10) return 'UNFRIENDLY';
    if (standing <= 10) return 'NEUTRAL';
    if (standing <= 30) return 'ACCEPTED';
    if (standing <= 60) return 'FRIENDLY';
    if (standing <= 85) return 'HONORED';
    return 'REVERED';
  }

  /**
   * Get relation key (order independent)
   */
  private getRelationKey(faction1: string, faction2: string): string {
    return faction1 < faction2 ? `${faction1}_${faction2}` : `${faction2}_${faction1}`;
  }

  /**
   * Get all factions
   */
  getAllFactions(): Faction[] {
    return Array.from(this.factions.values());
  }

  /**
   * Get faction by ID
   */
  getFaction(id: string): Faction | undefined {
    return this.factions.get(id);
  }

  /**
   * Get all active conflicts
   */
  getActiveConflicts(): Conflict[] {
    return Array.from(this.conflicts.values());
  }

  /**
   * Get player's reputation with all factions
   */
  getPlayerReputations(playerId: string): Map<string, Reputation> {
    const reps = new Map<string, Reputation>();
    for (const faction of this.factions.keys()) {
      reps.set(faction, this.getReputation(playerId, faction));
    }
    return reps;
  }

  /**
   * Check if player can dock at station
   */
  canPlayerDock(playerId: string, stationFaction: string): boolean {
    const rep = this.getReputation(playerId, stationFaction);
    return rep.standing > -40; // Hostile or better can dock
  }

  /**
   * Check if faction will attack player
   */
  willAttackPlayer(playerId: string, factionId: string): boolean {
    const rep = this.getReputation(playerId, factionId);
    return rep.standing < -60; // Hostile factions attack
  }
}
