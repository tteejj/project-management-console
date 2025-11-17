/**
 * DynamicEventSystem.ts
 * Dynamic event generation for emergencies, discoveries, encounters, and story moments
 */

import { Vector3, CelestialBody } from './CelestialBody';
import { NPCShip } from './NPCShipAI';
import { SpaceStation } from './StationGenerator';

export interface GameEvent {
  id: string;
  type: EventType;
  category: EventCategory;
  title: string;
  description: string;
  timestamp: number;
  location?: Vector3;
  affectedEntities: string[]; // IDs of ships, stations, planets
  severity: EventSeverity;
  duration: number;           // seconds (0 = instant)
  timeRemaining: number;
  choices?: EventChoice[];
  outcome?: EventOutcome;
  completed: boolean;
  rewards?: EventRewards;
}

export type EventType =
  | 'EMERGENCY'
  | 'DISCOVERY'
  | 'ENCOUNTER'
  | 'COMBAT'
  | 'TRADE'
  | 'DIPLOMATIC'
  | 'ENVIRONMENTAL'
  | 'SYSTEM_FAILURE'
  | 'ANOMALY';

export type EventCategory =
  | 'SHIP_MALFUNCTION'
  | 'LIFE_SUPPORT_FAILURE'
  | 'FUEL_LEAK'
  | 'HULL_BREACH'
  | 'FIRE'
  | 'COLLISION_RISK'
  | 'PIRATE_ATTACK'
  | 'DISTRESS_CALL'
  | 'DERELICT_SHIP'
  | 'ANCIENT_ARTIFACT'
  | 'LIFE_SIGNS'
  | 'MINERAL_DEPOSIT'
  | 'SCIENTIFIC_PHENOMENON'
  | 'STELLAR_FLARE'
  | 'ASTEROID_IMPACT'
  | 'STATION_EMERGENCY'
  | 'FACTIONAL_CONFLICT'
  | 'TRADE_OPPORTUNITY'
  | 'NAVIGATION_HAZARD';

export type EventSeverity = 'LOW' | 'MODERATE' | 'HIGH' | 'CRITICAL' | 'CATASTROPHIC';

export interface EventChoice {
  id: string;
  text: string;
  description: string;
  requirements?: {
    skill?: string;
    skillLevel?: number;
    items?: string[];
    credits?: number;
  };
  consequences: EventConsequence[];
}

export interface EventConsequence {
  type: 'REPUTATION' | 'CREDITS' | 'RESOURCE' | 'CREW_HEALTH' | 'SHIP_DAMAGE' | 'DISCOVERY' | 'UNLOCK';
  value: number;
  target?: string;
}

export interface EventOutcome {
  choiceId: string;
  success: boolean;
  description: string;
  consequences: EventConsequence[];
}

export interface EventRewards {
  credits?: number;
  reputation?: Map<string, number>; // faction -> change
  items?: Map<string, number>;      // item -> quantity
  data?: Map<string, any>;          // Scientific data, coordinates, etc.
}

export interface DerelictShip {
  id: string;
  position: Vector3;
  shipType: string;
  age: number;              // years
  condition: number;        // 0-100
  cargo: Map<string, number>;
  dangers: string[];        // radiation, structural instability, etc.
  salvageValue: number;
  story?: string;
}

export interface Anomaly {
  id: string;
  type: AnomalyType;
  position: Vector3;
  radius: number;           // meters
  intensity: number;        // 0-1
  effects: AnomalyEffect[];
  scientificValue: number;
  discovered: boolean;
}

export type AnomalyType =
  | 'WORMHOLE'
  | 'TEMPORAL_DISTORTION'
  | 'DARK_MATTER'
  | 'QUANTUM_FLUCTUATION'
  | 'GRAVITATIONAL_ANOMALY'
  | 'RADIATION_POCKET'
  | 'ENERGY_FIELD';

export interface AnomalyEffect {
  type: 'NAVIGATION' | 'SENSORS' | 'POWER' | 'TIME' | 'GRAVITY';
  magnitude: number;
  description: string;
}

/**
 * Dynamic Event System
 */
export class DynamicEventSystem {
  private events: Map<string, GameEvent> = new Map();
  private eventHistory: GameEvent[] = [];
  private derelicts: Map<string, DerelictShip> = new Map();
  private anomalies: Map<string, Anomaly> = new Map();
  private nextEventId = 0;

  // Event generation parameters
  private emergencyChance = 0.0001;    // Per second
  private discoveryChance = 0.00005;   // Per second
  private encounterChance = 0.0002;    // Per second

  /**
   * Update event system
   */
  update(
    deltaTime: number,
    playerShip: {
      position: Vector3;
      health: number;
      fuelLevel: number;
      lifeSupportStatus: any;
    },
    nearbyShips: NPCShip[],
    nearbyStations: SpaceStation[],
    nearbyBodies: CelestialBody[]
  ): void {
    // Update active events
    for (const [id, event] of this.events) {
      if (event.duration > 0) {
        event.timeRemaining -= deltaTime;

        if (event.timeRemaining <= 0) {
          this.completeEvent(event);
        }
      }
    }

    // Roll for random events
    if (Math.random() < this.emergencyChance * deltaTime) {
      this.generateEmergency(playerShip);
    }

    if (Math.random() < this.discoveryChance * deltaTime) {
      this.generateDiscovery(playerShip.position);
    }

    if (Math.random() < this.encounterChance * deltaTime && nearbyShips.length > 0) {
      this.generateEncounter(playerShip.position, nearbyShips);
    }

    // Check for proximity-triggered events
    this.checkProximityEvents(playerShip.position, nearbyShips, nearbyStations, nearbyBodies);
  }

  /**
   * Generate emergency event
   */
  private generateEmergency(playerShip: any): void {
    const emergencyTypes: EventCategory[] = [
      'SHIP_MALFUNCTION',
      'LIFE_SUPPORT_FAILURE',
      'FUEL_LEAK',
      'HULL_BREACH',
      'FIRE',
      'COLLISION_RISK'
    ];

    const category = emergencyTypes[Math.floor(Math.random() * emergencyTypes.length)];

    const event = this.createEmergencyEvent(category, playerShip);
    if (event) {
      this.events.set(event.id, event);
    }
  }

  /**
   * Create specific emergency event
   */
  private createEmergencyEvent(category: EventCategory, playerShip: any): GameEvent | null {
    const id = `event_${this.nextEventId++}`;

    switch (category) {
      case 'LIFE_SUPPORT_FAILURE':
        return {
          id,
          type: 'EMERGENCY',
          category,
          title: 'Life Support Critical Failure',
          description: 'Primary oxygen generator has malfunctioned. CO2 levels rising rapidly. Immediate action required!',
          timestamp: Date.now(),
          affectedEntities: ['player_ship'],
          severity: 'CRITICAL',
          duration: 3600, // 1 hour to fix
          timeRemaining: 3600,
          completed: false,
          choices: [
            {
              id: 'repair',
              text: 'Attempt Emergency Repair',
              description: 'Send engineer to fix the O2 generator',
              requirements: { skill: 'engineering', skillLevel: 50 },
              consequences: [
                { type: 'CREW_HEALTH', value: 50 }  // Success restores system
              ]
            },
            {
              id: 'vent',
              text: 'Emergency Atmosphere Vent',
              description: 'Purge and replace atmosphere using reserves',
              requirements: { items: ['oxygen_reserve'] },
              consequences: [
                { type: 'RESOURCE', value: -100, target: 'oxygen' }
              ]
            },
            {
              id: 'distress',
              text: 'Send Distress Signal',
              description: 'Call for help from nearby ships',
              consequences: [
                { type: 'REPUTATION', value: -10 }  // Slight reputation hit
              ]
            }
          ]
        };

      case 'FIRE':
        return {
          id,
          type: 'EMERGENCY',
          category,
          title: 'Fire in Engineering',
          description: 'A fire has broken out in the engineering bay! Immediate containment required.',
          timestamp: Date.now(),
          affectedEntities: ['player_ship'],
          severity: 'HIGH',
          duration: 600, // 10 minutes
          timeRemaining: 600,
          completed: false,
          choices: [
            {
              id: 'extinguisher',
              text: 'Use Fire Suppression System',
              description: 'Activate automated fire suppression',
              consequences: [
                { type: 'SHIP_DAMAGE', value: -10 }  // Minor damage
              ]
            },
            {
              id: 'vent_compartment',
              text: 'Vent Compartment to Space',
              description: 'Explosive decompression will extinguish fire but damage equipment',
              consequences: [
                { type: 'SHIP_DAMAGE', value: -30 }
              ]
            },
            {
              id: 'manual',
              text: 'Manual Firefighting',
              description: 'Send crew with portable extinguishers',
              requirements: { skill: 'engineering', skillLevel: 30 },
              consequences: [
                { type: 'CREW_HEALTH', value: -20 },
                { type: 'SHIP_DAMAGE', value: -5 }
              ]
            }
          ]
        };

      case 'FUEL_LEAK':
        return {
          id,
          type: 'EMERGENCY',
          category,
          title: 'Fuel Tank Micro-Fracture',
          description: 'Fuel leak detected in main tank. Currently losing fuel at increasing rate.',
          timestamp: Date.now(),
          affectedEntities: ['player_ship'],
          severity: 'HIGH',
          duration: 1800, // 30 minutes
          timeRemaining: 1800,
          completed: false,
          choices: [
            {
              id: 'seal',
              text: 'Emergency Sealant',
              description: 'Apply emergency sealant from outside',
              requirements: { items: ['sealant_kit'] },
              consequences: [
                { type: 'RESOURCE', value: -10, target: 'sealant' }
              ]
            },
            {
              id: 'transfer',
              text: 'Transfer Fuel to Auxiliary Tanks',
              description: 'Pump fuel to backup tanks',
              consequences: [
                { type: 'RESOURCE', value: -50, target: 'fuel' }  // Lose some in transfer
              ]
            }
          ]
        };

      case 'HULL_BREACH':
        return {
          id,
          type: 'EMERGENCY',
          category,
          title: 'Hull Breach Detected',
          description: 'Micrometeorite impact has created a small hull breach. Atmosphere leaking.',
          timestamp: Date.now(),
          affectedEntities: ['player_ship'],
          severity: 'CRITICAL',
          duration: 1200, // 20 minutes
          timeRemaining: 1200,
          completed: false,
          choices: [
            {
              id: 'patch',
              text: 'Emergency Patch',
              description: 'Apply emergency hull patch',
              requirements: { items: ['hull_patch'] },
              consequences: [
                { type: 'RESOURCE', value: -1, target: 'hull_patch' }
              ]
            },
            {
              id: 'seal_section',
              text: 'Seal Section',
              description: 'Close bulkheads and seal off damaged section',
              consequences: [
                { type: 'SHIP_DAMAGE', value: -15 }
              ]
            }
          ]
        };

      default:
        return null;
    }
  }

  /**
   * Generate discovery event
   */
  private generateDiscovery(position: Vector3): void {
    const discoveryTypes: EventCategory[] = [
      'DERELICT_SHIP',
      'ANCIENT_ARTIFACT',
      'LIFE_SIGNS',
      'MINERAL_DEPOSIT',
      'SCIENTIFIC_PHENOMENON'
    ];

    const category = discoveryTypes[Math.floor(Math.random() * discoveryTypes.length)];

    const event = this.createDiscoveryEvent(category, position);
    if (event) {
      this.events.set(event.id, event);
    }
  }

  /**
   * Create discovery event
   */
  private createDiscoveryEvent(category: EventCategory, position: Vector3): GameEvent | null {
    const id = `event_${this.nextEventId++}`;

    switch (category) {
      case 'DERELICT_SHIP':
        const derelict = this.generateDerelictShip(position);
        return {
          id,
          type: 'DISCOVERY',
          category,
          title: 'Derelict Vessel Detected',
          description: `Sensors have detected a derelict ${derelict.shipType}. Appears to be ${derelict.age} years old. Salvage possible.`,
          timestamp: Date.now(),
          location: position,
          affectedEntities: [derelict.id],
          severity: 'LOW',
          duration: 0,
          timeRemaining: 0,
          completed: false,
          choices: [
            {
              id: 'investigate',
              text: 'Board and Investigate',
              description: 'Send a boarding party to investigate',
              consequences: [
                { type: 'CREDITS', value: derelict.salvageValue },
                { type: 'DISCOVERY', value: 1 }
              ]
            },
            {
              id: 'scan',
              text: 'Scan and Log',
              description: 'Perform detailed scan and record location',
              consequences: [
                { type: 'DISCOVERY', value: 0.5 }
              ]
            },
            {
              id: 'ignore',
              text: 'Ignore',
              description: 'Continue on current course',
              consequences: []
            }
          ],
          rewards: {
            credits: derelict.salvageValue,
            items: derelict.cargo
          }
        };

      case 'ANCIENT_ARTIFACT':
        return {
          id,
          type: 'DISCOVERY',
          category,
          title: 'Anomalous Object Detected',
          description: 'Sensors have detected an object of unknown origin. Energy signatures unlike anything in the database.',
          timestamp: Date.now(),
          location: position,
          affectedEntities: [],
          severity: 'MODERATE',
          duration: 0,
          timeRemaining: 0,
          completed: false,
          choices: [
            {
              id: 'retrieve',
              text: 'Retrieve Artifact',
              description: 'Recover the object for study',
              consequences: [
                { type: 'DISCOVERY', value: 10 },
                { type: 'CREDITS', value: 50000 }
              ]
            },
            {
              id: 'study',
              text: 'Study in Place',
              description: 'Perform detailed analysis without recovery',
              requirements: { skill: 'science', skillLevel: 70 },
              consequences: [
                { type: 'DISCOVERY', value: 5 }
              ]
            }
          ],
          rewards: {
            credits: 50000
          }
        };

      case 'MINERAL_DEPOSIT':
        return {
          id,
          type: 'DISCOVERY',
          category,
          title: 'Rich Mineral Deposit',
          description: 'Asteroid contains valuable rare earth elements and platinum group metals.',
          timestamp: Date.now(),
          location: position,
          affectedEntities: [],
          severity: 'LOW',
          duration: 0,
          timeRemaining: 0,
          completed: false,
          choices: [
            {
              id: 'mine',
              text: 'Begin Mining Operation',
              description: 'Extract valuable minerals',
              requirements: { items: ['mining_equipment'] },
              consequences: [
                { type: 'RESOURCE', value: 500, target: 'minerals' },
                { type: 'CREDITS', value: 10000 }
              ]
            },
            {
              id: 'claim',
              text: 'File Mining Claim',
              description: 'Register claim for future mining',
              consequences: [
                { type: 'CREDITS', value: 5000 }
              ]
            }
          ],
          rewards: {
            credits: 10000,
            items: new Map([['minerals', 500]])
          }
        };

      default:
        return null;
    }
  }

  /**
   * Generate encounter event
   */
  private generateEncounter(position: Vector3, nearbyShips: NPCShip[]): void {
    if (nearbyShips.length === 0) return;

    const ship = nearbyShips[Math.floor(Math.random() * nearbyShips.length)];

    const event: GameEvent = {
      id: `event_${this.nextEventId++}`,
      type: 'ENCOUNTER',
      category: ship.type === 'PIRATE' ? 'PIRATE_ATTACK' : 'DISTRESS_CALL',
      title: ship.type === 'PIRATE' ? 'Hostile Ship Detected' : 'Distress Call Received',
      description: ship.type === 'PIRATE' ?
        `Pirate vessel ${ship.name} has locked weapons on your ship!` :
        `${ship.name} is broadcasting a distress signal. They need assistance.`,
      timestamp: Date.now(),
      location: position,
      affectedEntities: [ship.id],
      severity: ship.type === 'PIRATE' ? 'HIGH' : 'MODERATE',
      duration: 0,
      timeRemaining: 0,
      completed: false,
      choices: ship.type === 'PIRATE' ? [
        {
          id: 'fight',
          text: 'Engage in Combat',
          description: 'Fight the pirate',
          consequences: [
            { type: 'SHIP_DAMAGE', value: -40 },
            { type: 'CREDITS', value: 5000 },
            { type: 'REPUTATION', value: 10 }
          ]
        },
        {
          id: 'flee',
          text: 'Attempt to Flee',
          description: 'Try to escape',
          consequences: [
            { type: 'RESOURCE', value: -20, target: 'fuel' }
          ]
        },
        {
          id: 'negotiate',
          text: 'Attempt Negotiation',
          description: 'Try to bribe the pirate',
          requirements: { credits: 2000 },
          consequences: [
            { type: 'CREDITS', value: -2000 }
          ]
        }
      ] : [
        {
          id: 'help',
          text: 'Render Assistance',
          description: 'Help the ship in distress',
          consequences: [
            { type: 'REPUTATION', value: 20 },
            { type: 'CREDITS', value: 1000 }
          ]
        },
        {
          id: 'ignore',
          text: 'Ignore and Continue',
          description: 'Leave them to their fate',
          consequences: [
            { type: 'REPUTATION', value: -10 }
          ]
        }
      ]
    };

    this.events.set(event.id, event);
  }

  /**
   * Check for proximity-triggered events
   */
  private checkProximityEvents(
    playerPos: Vector3,
    nearbyShips: NPCShip[],
    nearbyStations: SpaceStation[],
    nearbyBodies: CelestialBody[]
  ): void {
    // Check anomalies
    for (const anomaly of this.anomalies.values()) {
      if (!anomaly.discovered) {
        const distance = this.distance(playerPos, anomaly.position);
        if (distance < anomaly.radius * 2) {
          anomaly.discovered = true;
          this.generateAnomalyEvent(anomaly);
        }
      }
    }
  }

  /**
   * Generate anomaly event
   */
  private generateAnomalyEvent(anomaly: Anomaly): void {
    const event: GameEvent = {
      id: `event_${this.nextEventId++}`,
      type: 'ANOMALY',
      category: 'SCIENTIFIC_PHENOMENON',
      title: `${anomaly.type} Detected`,
      description: `Sensors have detected a ${anomaly.type}. Scientific value: ${anomaly.scientificValue}`,
      timestamp: Date.now(),
      location: anomaly.position,
      affectedEntities: [anomaly.id],
      severity: 'MODERATE',
      duration: 0,
      timeRemaining: 0,
      completed: false,
      choices: [
        {
          id: 'study',
          text: 'Conduct Scientific Study',
          description: 'Perform detailed analysis',
          requirements: { skill: 'science', skillLevel: 60 },
          consequences: [
            { type: 'DISCOVERY', value: anomaly.scientificValue },
            { type: 'CREDITS', value: anomaly.scientificValue * 100 }
          ]
        },
        {
          id: 'navigate',
          text: 'Navigate Around',
          description: 'Avoid the anomaly',
          consequences: []
        }
      ]
    };

    this.events.set(event.id, event);
  }

  /**
   * Make choice on event
   */
  makeChoice(eventId: string, choiceId: string): EventOutcome | null {
    const event = this.events.get(eventId);
    if (!event || !event.choices) return null;

    const choice = event.choices.find(c => c.id === choiceId);
    if (!choice) return null;

    // Determine success (simplified)
    const success = Math.random() > 0.3; // 70% success rate

    const outcome: EventOutcome = {
      choiceId,
      success,
      description: success ? 'Action successful!' : 'Action failed!',
      consequences: success ? choice.consequences : []
    };

    event.outcome = outcome;
    event.completed = true;

    // Move to history
    this.eventHistory.push(event);
    this.events.delete(eventId);

    return outcome;
  }

  /**
   * Complete event (timeout)
   */
  private completeEvent(event: GameEvent): void {
    // Event timed out without player action
    event.completed = true;
    event.outcome = {
      choiceId: 'timeout',
      success: false,
      description: 'Event timed out',
      consequences: [
        { type: 'SHIP_DAMAGE', value: -20 }  // Penalty for ignoring
      ]
    };

    this.eventHistory.push(event);
    this.events.delete(event.id);
  }

  /**
   * Generate derelict ship
   */
  private generateDerelictShip(position: Vector3): DerelictShip {
    const types = ['Freighter', 'Mining Vessel', 'Explorer', 'Warship'];
    const age = Math.floor(Math.random() * 100) + 10;

    const derelict: DerelictShip = {
      id: `derelict_${Date.now()}`,
      position,
      shipType: types[Math.floor(Math.random() * types.length)],
      age,
      condition: Math.random() * 70 + 10,
      cargo: new Map([
        ['scrap_metal', Math.floor(Math.random() * 500)],
        ['fuel', Math.floor(Math.random() * 200)],
        ['components', Math.floor(Math.random() * 50)]
      ]),
      dangers: ['radiation', 'structural_instability'],
      salvageValue: Math.floor(Math.random() * 10000) + 5000,
      story: 'Unknown fate'
    };

    this.derelicts.set(derelict.id, derelict);
    return derelict;
  }

  /**
   * Generate anomaly
   */
  generateAnomaly(position: Vector3, type: AnomalyType): Anomaly {
    const anomaly: Anomaly = {
      id: `anomaly_${Date.now()}`,
      type,
      position,
      radius: 100000 + Math.random() * 900000,
      intensity: Math.random(),
      effects: [
        {
          type: 'SENSORS',
          magnitude: 0.5,
          description: 'Sensor readings distorted'
        }
      ],
      scientificValue: Math.floor(Math.random() * 100),
      discovered: false
    };

    this.anomalies.set(anomaly.id, anomaly);
    return anomaly;
  }

  /**
   * Get active events
   */
  getActiveEvents(): GameEvent[] {
    return Array.from(this.events.values());
  }

  /**
   * Get event history
   */
  getEventHistory(): GameEvent[] {
    return this.eventHistory;
  }

  /**
   * Get events by type
   */
  getEventsByType(type: EventType): GameEvent[] {
    return Array.from(this.events.values()).filter(e => e.type === type);
  }

  /**
   * Get critical events
   */
  getCriticalEvents(): GameEvent[] {
    return Array.from(this.events.values()).filter(e =>
      e.severity === 'CRITICAL' || e.severity === 'CATASTROPHIC'
    );
  }

  /**
   * Distance calculation
   */
  private distance(p1: Vector3, p2: Vector3): number {
    const dx = p1.x - p2.x;
    const dy = p1.y - p2.y;
    const dz = p1.z - p2.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }
}
