/**
 * UniverseDesigner.ts
 * Main universe manager and game designer
 * Coordinates star systems, campaigns, progression, and game state
 */

import { StarSystem, StarSystemConfig, generateStarSystem } from './StarSystem';
import { CelestialBody, Vector3, StarClass } from './CelestialBody';
import { SpaceStation } from './StationGenerator';

export interface UniverseConfig {
  seed?: number;
  numSystems?: number;
  galaxyRadius?: number; // light years
  campaignMode?: 'SANDBOX' | 'LINEAR' | 'OPEN_WORLD';
  startingSystem?: string;
  difficultyProgression?: boolean;
}

export interface JumpRoute {
  from: string; // system id
  to: string;   // system id
  distance: number; // light years
  fuelCost: number;
  discovered: boolean;
}

export interface GameState {
  currentSystem: string;
  discoveredSystems: Set<string>;
  visitedSystems: Set<string>;
  playerPosition: Vector3;
  credits: number;
  reputation: Map<string, number>; // faction -> rep
  completedMissions: string[];
  discoveredJumpRoutes: Set<string>; // route ids
}

export interface Mission {
  id: string;
  type: 'DELIVERY' | 'COMBAT' | 'EXPLORATION' | 'RESCUE' | 'MINING' | 'ESCORT';
  title: string;
  description: string;
  giver: string; // station id
  targetSystem?: string;
  targetBody?: string;
  reward: number;
  reputationGain: Map<string, number>;
  difficulty: number; // 1-10
  timeLimit?: number; // seconds
  status: 'AVAILABLE' | 'ACTIVE' | 'COMPLETED' | 'FAILED';
}

/**
 * Main Universe Designer and Manager
 */
export class UniverseDesigner {
  public systems: Map<string, StarSystem> = new Map();
  public jumpRoutes: Map<string, JumpRoute> = new Map();
  public gameState: GameState;
  public missions: Map<string, Mission> = new Map();
  public config: UniverseConfig;
  public currentTime: number = 0; // Game time in seconds

  private rng: {
    next: () => number;
    range: (min: number, max: number) => number;
    choice: <T>(arr: T[]) => T;
    bool: (p?: number) => boolean;
  };

  constructor(config: UniverseConfig = {}) {
    this.config = {
      seed: config.seed || Date.now(),
      numSystems: config.numSystems || 10,
      galaxyRadius: config.galaxyRadius || 100,
      campaignMode: config.campaignMode || 'OPEN_WORLD',
      startingSystem: config.startingSystem,
      difficultyProgression: config.difficultyProgression !== false
    };

    // Initialize RNG
    let s = this.config.seed!;
    this.rng = {
      next: () => {
        s = (s * 9301 + 49297) % 233280;
        return s / 233280;
      },
      range: (min: number, max: number) => min + this.rng.next() * (max - min),
      choice: <T>(arr: T[]): T => arr[Math.floor(this.rng.next() * arr.length)],
      bool: (p: number = 0.5) => this.rng.next() < p
    };

    // Generate the universe
    this.generateUniverse();

    // Initialize game state
    const startingSystemId = this.config.startingSystem ||
                            Array.from(this.systems.keys())[0];

    this.gameState = {
      currentSystem: startingSystemId,
      discoveredSystems: new Set([startingSystemId]),
      visitedSystems: new Set([startingSystemId]),
      playerPosition: { x: 0, y: 0, z: 0 },
      credits: 10000,
      reputation: new Map(),
      completedMissions: [],
      discoveredJumpRoutes: new Set()
    };

    // Generate initial missions
    this.generateMissions();
  }

  /**
   * Generate the entire universe
   */
  private generateUniverse(): void {
    console.log(`Generating universe with ${this.config.numSystems} systems...`);

    // Generate star systems
    for (let i = 0; i < this.config.numSystems!; i++) {
      const system = this.generateSystemForUniverse(i);
      this.systems.set(system.id, system);
    }

    // Generate jump routes
    this.generateJumpRoutes();

    console.log(`Universe generated: ${this.systems.size} systems, ${this.jumpRoutes.size} jump routes`);
  }

  /**
   * Generate a single star system for the universe
   */
  private generateSystemForUniverse(index: number): StarSystem {
    const names = this.generateSystemNames();
    const name = names[index] || `System-${index + 1}`;

    // Position in galaxy (2D plane for simplicity)
    const angle = this.rng.range(0, 2 * Math.PI);
    const radius = this.rng.range(0, this.config.galaxyRadius!);
    const position: Vector3 = {
      x: radius * Math.cos(angle) * 9.461e15, // Convert ly to meters
      y: radius * Math.sin(angle) * 9.461e15,
      z: this.rng.range(-5, 5) * 9.461e15 // Small Z variation
    };

    // Determine civilization level based on distance from center
    // Inner systems more developed
    const normalizedDistance = radius / this.config.galaxyRadius!;
    let civilizationLevel = Math.floor(
      this.rng.range(3, 10) * (1 - normalizedDistance * 0.5)
    );
    civilizationLevel = Math.max(0, Math.min(10, civilizationLevel));

    // System difficulty increases with distance (if enabled)
    let numPlanets = { min: 3, max: 12 };
    if (this.config.difficultyProgression) {
      const difficulty = normalizedDistance;
      numPlanets = {
        min: Math.floor(3 + difficulty * 5),
        max: Math.floor(8 + difficulty * 8)
      };
    }

    const systemConfig: StarSystemConfig = {
      seed: this.config.seed! + index,
      numPlanets,
      allowAsteroidBelt: true,
      allowStations: true,
      allowHazards: true,
      civilizationLevel,
      position
    };

    return new StarSystem(`system-${index}`, name, systemConfig);
  }

  /**
   * Generate jump routes between systems
   */
  private generateJumpRoutes(): void {
    const systemArray = Array.from(this.systems.values());

    // Connect nearby systems
    for (let i = 0; i < systemArray.length; i++) {
      const system1 = systemArray[i];

      // Find nearest systems
      const distances: { system: StarSystem; distance: number }[] = [];

      for (let j = 0; j < systemArray.length; j++) {
        if (i === j) continue;

        const system2 = systemArray[j];
        const distance = this.calculateDistance(system1.position, system2.position);
        distances.push({ system: system2, distance });
      }

      // Sort by distance
      distances.sort((a, b) => a.distance - b.distance);

      // Connect to 2-4 nearest systems
      const numConnections = Math.floor(this.rng.range(2, 5));
      for (let k = 0; k < Math.min(numConnections, distances.length); k++) {
        const target = distances[k];

        const routeId = this.createRouteId(system1.id, target.system.id);
        if (!this.jumpRoutes.has(routeId)) {
          const distanceLY = target.distance / 9.461e15;

          const route: JumpRoute = {
            from: system1.id,
            to: target.system.id,
            distance: distanceLY,
            fuelCost: distanceLY * 10, // 10 units per light year
            discovered: false
          };

          this.jumpRoutes.set(routeId, route);

          // Also create reverse route
          const reverseRouteId = this.createRouteId(target.system.id, system1.id);
          const reverseRoute: JumpRoute = {
            from: target.system.id,
            to: system1.id,
            distance: distanceLY,
            fuelCost: distanceLY * 10,
            discovered: false
          };

          this.jumpRoutes.set(reverseRouteId, reverseRoute);
        }
      }
    }
  }

  /**
   * Generate missions
   */
  private generateMissions(): void {
    // Generate missions for each system with stations
    for (const system of this.systems.values()) {
      if (system.stations.length === 0) continue;

      // Each station might have 0-3 missions
      for (const station of system.stations) {
        const numMissions = Math.floor(this.rng.range(0, 4));

        for (let i = 0; i < numMissions; i++) {
          const mission = this.generateMission(system, station);
          this.missions.set(mission.id, mission);
        }
      }
    }
  }

  /**
   * Generate a single mission
   */
  private generateMission(system: StarSystem, station: SpaceStation): Mission {
    const types: Mission['type'][] = ['DELIVERY', 'COMBAT', 'EXPLORATION', 'RESCUE', 'MINING', 'ESCORT'];
    const type = this.rng.choice(types);

    const missionId = `mission-${system.id}-${station.id}-${this.missions.size}`;

    let title: string, description: string, reward: number, difficulty: number;
    let targetSystem: string | undefined, targetBody: string | undefined;

    switch (type) {
      case 'DELIVERY':
        const deliveryTargets = this.getAccessibleSystems(system.id);
        const targetSys = this.rng.choice(deliveryTargets);
        targetSystem = targetSys?.id;

        title = 'Cargo Delivery';
        description = targetSystem
          ? `Deliver cargo to ${this.systems.get(targetSystem)?.name}`
          : 'Deliver cargo to local station';
        reward = this.rng.range(500, 5000);
        difficulty = targetSystem ? this.rng.range(2, 6) : this.rng.range(1, 3);
        break;

      case 'COMBAT':
        title = 'Eliminate Hostiles';
        description = 'Clear pirate forces from the sector';
        reward = this.rng.range(2000, 10000);
        difficulty = this.rng.range(4, 8);
        break;

      case 'EXPLORATION':
        const unexploredBodies = system.planets.filter(p => this.rng.bool(0.5));
        targetBody = unexploredBodies.length > 0
          ? this.rng.choice(unexploredBodies).id
          : undefined;

        title = 'Survey Mission';
        description = targetBody
          ? `Survey and scan ${targetBody}`
          : 'Explore uncharted regions';
        reward = this.rng.range(1000, 4000);
        difficulty = this.rng.range(2, 5);
        break;

      case 'RESCUE':
        title = 'Search and Rescue';
        description = 'Locate and rescue stranded ship';
        reward = this.rng.range(3000, 8000);
        difficulty = this.rng.range(3, 7);
        break;

      case 'MINING':
        const asteroidTargets = system.asteroids.filter(() => this.rng.bool(0.3));
        targetBody = asteroidTargets.length > 0
          ? this.rng.choice(asteroidTargets).id
          : undefined;

        title = 'Mining Contract';
        description = 'Extract valuable minerals from asteroid field';
        reward = this.rng.range(1500, 6000);
        difficulty = this.rng.range(2, 5);
        break;

      case 'ESCORT':
        title = 'Escort Mission';
        description = 'Protect convoy through dangerous space';
        reward = this.rng.range(2500, 7000);
        difficulty = this.rng.range(3, 7);
        break;

      default:
        title = 'Unknown Mission';
        description = 'Mission details unavailable';
        reward = 1000;
        difficulty = 5;
    }

    const reputationGain = new Map<string, number>();
    reputationGain.set(station.faction, difficulty * 5);

    return {
      id: missionId,
      type,
      title,
      description,
      giver: station.id,
      targetSystem,
      targetBody,
      reward,
      reputationGain,
      difficulty,
      status: 'AVAILABLE'
    };
  }

  /**
   * Get accessible systems from a given system
   */
  private getAccessibleSystems(systemId: string): StarSystem[] {
    const accessible: StarSystem[] = [];

    for (const [routeId, route] of this.jumpRoutes) {
      if (route.from === systemId) {
        const targetSystem = this.systems.get(route.to);
        if (targetSystem) accessible.push(targetSystem);
      }
    }

    return accessible;
  }

  /**
   * Update entire universe
   */
  update(deltaTime: number): void {
    this.currentTime += deltaTime;

    // Update current system (for performance, only update current system)
    const currentSystem = this.systems.get(this.gameState.currentSystem);
    if (currentSystem) {
      currentSystem.update(deltaTime);
    }

    // Update missions
    for (const mission of this.missions.values()) {
      if (mission.status === 'ACTIVE' && mission.timeLimit) {
        mission.timeLimit -= deltaTime;
        if (mission.timeLimit <= 0) {
          mission.status = 'FAILED';
        }
      }
    }
  }

  /**
   * Jump to another system
   */
  jumpToSystem(targetSystemId: string): { success: boolean; message: string } {
    const routeId = this.createRouteId(this.gameState.currentSystem, targetSystemId);
    const route = this.jumpRoutes.get(routeId);

    if (!route) {
      return { success: false, message: 'No jump route available' };
    }

    // Mark route as discovered
    route.discovered = true;
    this.gameState.discoveredJumpRoutes.add(routeId);

    // Mark system as discovered and visited
    this.gameState.discoveredSystems.add(targetSystemId);
    this.gameState.visitedSystems.add(targetSystemId);

    // Change current system
    this.gameState.currentSystem = targetSystemId;

    // Reset player position (at jump point)
    this.gameState.playerPosition = { x: 0, y: 0, z: 0 };

    return {
      success: true,
      message: `Jumped to ${this.systems.get(targetSystemId)?.name}. Fuel cost: ${route.fuelCost}`
    };
  }

  /**
   * Get current star system
   */
  getCurrentSystem(): StarSystem | undefined {
    return this.systems.get(this.gameState.currentSystem);
  }

  /**
   * Get available jump routes from current system
   */
  getAvailableJumps(): JumpRoute[] {
    const routes: JumpRoute[] = [];

    for (const route of this.jumpRoutes.values()) {
      if (route.from === this.gameState.currentSystem) {
        routes.push(route);
      }
    }

    return routes;
  }

  /**
   * Get missions available at a station
   */
  getMissionsAtStation(stationId: string): Mission[] {
    return Array.from(this.missions.values()).filter(
      m => m.giver === stationId && m.status === 'AVAILABLE'
    );
  }

  /**
   * Accept a mission
   */
  acceptMission(missionId: string): boolean {
    const mission = this.missions.get(missionId);
    if (mission && mission.status === 'AVAILABLE') {
      mission.status = 'ACTIVE';
      return true;
    }
    return false;
  }

  /**
   * Complete a mission
   */
  completeMission(missionId: string): { success: boolean; reward: number; reputation: Map<string, number> } {
    const mission = this.missions.get(missionId);

    if (!mission || mission.status !== 'ACTIVE') {
      return { success: false, reward: 0, reputation: new Map() };
    }

    mission.status = 'COMPLETED';
    this.gameState.completedMissions.push(missionId);
    this.gameState.credits += mission.reward;

    // Update reputation
    for (const [faction, rep] of mission.reputationGain) {
      const currentRep = this.gameState.reputation.get(faction) || 0;
      this.gameState.reputation.set(faction, currentRep + rep);
    }

    return {
      success: true,
      reward: mission.reward,
      reputation: mission.reputationGain
    };
  }

  /**
   * Get universe statistics
   */
  getStatistics(): {
    totalSystems: number;
    totalPlanets: number;
    totalMoons: number;
    totalStations: number;
    totalAsteroids: number;
    habitablePlanets: number;
    discoveredSystems: number;
    availableMissions: number;
  } {
    let totalPlanets = 0;
    let totalMoons = 0;
    let totalStations = 0;
    let totalAsteroids = 0;
    let habitablePlanets = 0;

    for (const system of this.systems.values()) {
      totalPlanets += system.planets.length;
      totalMoons += system.moons.length;
      totalStations += system.stations.length;
      totalAsteroids += system.asteroids.length;
      habitablePlanets += system.getHabitablePlanets().length;
    }

    const availableMissions = Array.from(this.missions.values()).filter(
      m => m.status === 'AVAILABLE'
    ).length;

    return {
      totalSystems: this.systems.size,
      totalPlanets,
      totalMoons,
      totalStations,
      totalAsteroids,
      habitablePlanets,
      discoveredSystems: this.gameState.discoveredSystems.size,
      availableMissions
    };
  }

  /**
   * Export universe data
   */
  export(): {
    config: UniverseConfig;
    systems: any[];
    jumpRoutes: JumpRoute[];
    gameState: any;
    statistics: any;
  } {
    return {
      config: this.config,
      systems: Array.from(this.systems.values()).map(s => s.export()),
      jumpRoutes: Array.from(this.jumpRoutes.values()),
      gameState: {
        ...this.gameState,
        discoveredSystems: Array.from(this.gameState.discoveredSystems),
        visitedSystems: Array.from(this.gameState.visitedSystems),
        reputation: Array.from(this.gameState.reputation.entries()),
        discoveredJumpRoutes: Array.from(this.gameState.discoveredJumpRoutes)
      },
      statistics: this.getStatistics()
    };
  }

  /**
   * Helper: Calculate distance between two points
   */
  private calculateDistance(p1: Vector3, p2: Vector3): number {
    const dx = p1.x - p2.x;
    const dy = p1.y - p2.y;
    const dz = p1.z - p2.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /**
   * Helper: Create route ID
   */
  private createRouteId(from: string, to: string): string {
    return `${from}-to-${to}`;
  }

  /**
   * Helper: Generate system names
   */
  private generateSystemNames(): string[] {
    return [
      'Sol', 'Alpha Centauri', 'Proxima', 'Barnard', 'Wolf 359',
      'Lalande', 'Sirius', 'Luyten', 'Ross 154', 'Epsilon Eridani',
      'Lacaille', 'Ross 128', 'Procyon', 'Struve', 'Groombridge',
      'Epsilon Indi', 'Tau Ceti', '40 Eridani', 'Altair', 'Vega',
      'Arcturus', 'Capella', 'Rigel', 'Betelgeuse', 'Aldebaran',
      'Antares', 'Spica', 'Pollux', 'Fomalhaut', 'Deneb',
      'Regulus', 'Adhara', 'Castor', 'Bellatrix', 'Mira'
    ];
  }
}

/**
 * Quick universe creation function
 */
export function createUniverse(config: UniverseConfig = {}): UniverseDesigner {
  return new UniverseDesigner(config);
}
