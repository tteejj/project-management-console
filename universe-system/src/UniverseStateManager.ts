/**
 * UniverseStateManager.ts
 * Central coordinator that integrates ALL systems into a cohesive, living universe
 */

import { StarSystem } from './StarSystem';
import { CelestialBody, Planet, Star } from './CelestialBody';
import { SpaceStation } from './StationGenerator';
import { NPCShipAI, NPCShip } from './NPCShipAI';
import { TrafficControl } from './TrafficControl';
import { FactionSystem } from './FactionSystem';
import { WeatherSystem } from './WeatherSystem';
import { GeologicalActivity } from './GeologicalActivity';
import { SensorSystem } from './SensorSystem';
import { CommunicationSystem } from './CommunicationSystem';
import { EconomySystem } from './EconomySystem';
import { PropulsionSystem } from './PropulsionSystem';
import { LifeSupportSystem, CrewMember } from './LifeSupportSystem';
import { DynamicEventSystem } from './DynamicEventSystem';
import { AtmosphericPhysics } from './AtmosphericPhysics';
import { RadiationPhysics, RadiationTracker } from './RadiationPhysics';
import { ThermalBalance } from './ThermalBalance';
import { HabitabilityAnalysis } from './HabitabilityAnalysis';

export interface PlayerShip {
  id: string;
  name: string;
  position: Vector3;
  velocity: Vector3;
  faction: string;
  health: number;
  shields: number;
  power: number;           // watts available
  propulsion: PropulsionSystem;
  lifeSupport: LifeSupportSystem;
  sensors: SensorSystem;
  radiationTracker: RadiationTracker;
  cargo: Map<string, number>;
  credits: number;
}

export interface Vector3 {
  x: number;
  y: number;
  z: number;
}

export interface UniverseConfig {
  seed: number;
  numSystems: number;
  difficulty: 'EASY' | 'NORMAL' | 'HARD' | 'EXTREME';
  realism: 'ARCADE' | 'BALANCED' | 'SIMULATION';
  enableRandomEvents: boolean;
  timeScale: number;        // 1.0 = real time
}

export interface UniverseState {
  currentTime: number;      // seconds since epoch
  gameTime: number;         // elapsed game time (seconds)
  paused: boolean;
  timeScale: number;
  currentSystem: string;    // Current star system ID
  playerShip: PlayerShip;
  visitedSystems: Set<string>;
  discoveredBodies: Set<string>;
  completedEvents: Set<string>;
}

/**
 * Universe State Manager
 * Coordinates all subsystems into a living, breathing universe
 */
export class UniverseStateManager {
  // Core universe data
  private config: UniverseConfig;
  private state: UniverseState;
  private starSystems: Map<string, StarSystem> = new Map();
  private currentSystem: StarSystem | null = null;

  // Subsystem managers
  private shipAI: NPCShipAI;
  private trafficControl: TrafficControl;
  private factionSystem: FactionSystem;
  private economySystem: EconomySystem;
  private communicationSystem: CommunicationSystem;
  private eventSystem: DynamicEventSystem;

  // Per-planet systems
  private weatherSystems: Map<string, WeatherSystem> = new Map();
  private geologySystems: Map<string, GeologicalActivity> = new Map();

  // Update tracking
  private lastUpdateTime: number = 0;
  private accumulatedTime: number = 0;

  constructor(config: UniverseConfig) {
    this.config = config;

    // Initialize core systems
    this.shipAI = new NPCShipAI();
    this.trafficControl = new TrafficControl();
    this.factionSystem = new FactionSystem();
    this.economySystem = new EconomySystem();
    this.communicationSystem = new CommunicationSystem();
    this.eventSystem = new DynamicEventSystem();

    // Initialize player ship
    const playerShip = this.createPlayerShip();

    // Initialize state
    this.state = {
      currentTime: Date.now(),
      gameTime: 0,
      paused: false,
      timeScale: config.timeScale,
      currentSystem: 'system_0',
      playerShip,
      visitedSystems: new Set(['system_0']),
      discoveredBodies: new Set(),
      completedEvents: new Set()
    };

    this.lastUpdateTime = Date.now();
  }

  /**
   * Create player ship with all subsystems
   */
  private createPlayerShip(): PlayerShip {
    // Create propulsion system
    const propulsion = new PropulsionSystem(50000); // 50 ton dry mass

    // Add main engine
    propulsion.addEngine({
      id: 'main_engine',
      name: 'Fusion Drive',
      type: 'FUSION',
      fuelType: 'FUSION_DEUTERIUM',
      maxThrust: 500000, // 500 kN
      massFlowRate: 0.005, // kg/s
      efficiency: 0.85,
      powerConsumption: 10000,
      mass: 5000,
      operational: true,
      health: 100,
      temperature: 300,
      throttle: 0
    });

    // Add RCS thrusters
    propulsion.addEngine({
      id: 'rcs',
      name: 'RCS Thrusters',
      type: 'RCS',
      fuelType: 'HYDRAZINE',
      maxThrust: 5000, // 5 kN
      massFlowRate: 0.02,
      efficiency: 0.9,
      powerConsumption: 100,
      mass: 200,
      operational: true,
      health: 100,
      temperature: 300,
      throttle: 0
    });

    // Add fuel tanks
    propulsion.addFuelTank({
      id: 'main_tank',
      fuelType: 'FUSION_DEUTERIUM',
      capacity: 10000,
      current: 10000,
      mass: 1000,
      insulated: true,
      coolingPower: 1000,
      integrity: 100
    });

    propulsion.addFuelTank({
      id: 'rcs_tank',
      fuelType: 'HYDRAZINE',
      capacity: 500,
      current: 500,
      mass: 50,
      insulated: false,
      coolingPower: 0,
      integrity: 100
    });

    // Create life support
    const lifeSupport = new LifeSupportSystem(200); // 200 m³ habitable volume

    // Add O2 generator
    lifeSupport.addOxygenGenerator({
      id: 'o2_gen_1',
      type: 'ELECTROLYSIS',
      operational: true,
      efficiency: 0.95,
      outputRate: 2.5, // kg/hour (enough for ~2.5 people)
      powerConsumption: 3000,
      waterConsumption: 2.8,
      health: 100,
      maintenanceRequired: 720 // 30 days
    });

    // Add CO2 scrubber
    lifeSupport.addCO2Scrubber({
      id: 'co2_scrubber_1',
      type: 'AMINE',
      operational: true,
      efficiency: 0.98,
      scrubbingRate: 3.0, // kg/hour
      powerConsumption: 2000,
      consumableRemaining: 0, // Regenerating type
      consumableCapacity: 0,
      health: 100,
      regenerating: false,
      regenerationTime: 0
    });

    // Add temperature control
    lifeSupport.addTemperatureControl({
      id: 'hvac_1',
      type: 'HEAT_PUMP',
      operational: true,
      coolingCapacity: 5000,
      heatingCapacity: 3000,
      powerConsumption: 1500,
      coolantLevel: 100,
      health: 100
    });

    // Add water system
    lifeSupport.setWaterSystem({
      id: 'water_sys',
      potableWater: 500, // kg
      wasteWater: 0,
      capacity: 1000,
      recyclingRate: 90,
      purificationActive: true,
      powerConsumption: 800,
      filterHealth: 100
    });

    // Add food supply
    lifeSupport.setFoodSupply({
      id: 'food',
      rations: 180, // 60 days for 3 people
      quality: 80,
      variety: 70,
      refrigerated: true,
      spoilageRate: 2,
      powerConsumption: 500
    });

    // Add crew
    lifeSupport.addCrewMember({
      id: 'crew_1',
      name: 'Captain Sarah Chen',
      role: 'PILOT',
      health: 100,
      morale: 85,
      fatigue: 20,
      hunger: 10,
      thirst: 5,
      oxygenSaturation: 98,
      co2Exposure: 400,
      radiationDose: 0,
      status: 'HEALTHY',
      skills: new Map([
        ['piloting', 90],
        ['navigation', 85],
        ['leadership', 80]
      ])
    });

    lifeSupport.addCrewMember({
      id: 'crew_2',
      name: 'Engineer Marcus Rodriguez',
      role: 'ENGINEER',
      health: 100,
      morale: 80,
      fatigue: 15,
      hunger: 10,
      thirst: 5,
      oxygenSaturation: 98,
      co2Exposure: 400,
      radiationDose: 0,
      status: 'HEALTHY',
      skills: new Map([
        ['engineering', 95],
        ['mechanics', 90],
        ['electronics', 85]
      ])
    });

    lifeSupport.addCrewMember({
      id: 'crew_3',
      name: 'Dr. Yuki Tanaka',
      role: 'SCIENTIST',
      health: 100,
      morale: 90,
      fatigue: 10,
      hunger: 10,
      thirst: 5,
      oxygenSaturation: 98,
      co2Exposure: 400,
      radiationDose: 0,
      status: 'HEALTHY',
      skills: new Map([
        ['science', 95],
        ['medicine', 80],
        ['analysis', 90]
      ])
    });

    // Create sensors
    const sensors = new SensorSystem();

    // Create radiation tracker
    const radiationTracker = new RadiationTracker(10, 5, 3); // 10mm Al hull, 5mm water, 3mm lead

    return {
      id: 'player_ship',
      name: 'SS Endeavor',
      position: { x: 0, y: 0, z: 0 },
      velocity: { x: 0, y: 0, z: 0 },
      faction: 'INDEPENDENT',
      health: 100,
      shields: 100,
      power: 100000, // 100 kW reactor
      propulsion,
      lifeSupport,
      sensors,
      radiationTracker,
      cargo: new Map([
        ['supplies', 1000],
        ['spare_parts', 50]
      ]),
      credits: 50000
    };
  }

  /**
   * Add star system to universe
   */
  addStarSystem(system: StarSystem): void {
    this.starSystems.set(system.star.id, system);

    // Initialize per-planet systems
    for (const planet of system.planets) {
      if (planet.physical.atmospherePressure && planet.physical.atmospherePressure > 100) {
        this.weatherSystems.set(planet.id, new WeatherSystem(planet));
      }

      // Geological activity for rocky planets
      if (planet.planetClass === 'TERRESTRIAL' || planet.planetClass === 'DESERT') {
        this.geologySystems.set(planet.id, new GeologicalActivity(planet));
      }
    }

    // Initialize traffic control with stations
    if (system.stations.length > 0) {
      this.trafficControl.initializeSystem(system.stations);
    }

    // Spawn NPC ships
    this.spawnNPCShips(system);
  }

  /**
   * Spawn NPC ships in system
   */
  private spawnNPCShips(system: StarSystem): void {
    const factions = this.factionSystem.getAllFactions();

    // Spawn traders
    for (let i = 0; i < 5; i++) {
      const station = system.stations[Math.floor(Math.random() * system.stations.length)];
      if (station) {
        const faction = factions[Math.floor(Math.random() * factions.length)];
        this.shipAI.createShip('TRADER', faction.id, station.position);
      }
    }

    // Spawn patrol ships
    for (let i = 0; i < 3; i++) {
      const station = system.stations[Math.floor(Math.random() * system.stations.length)];
      if (station) {
        this.shipAI.createShip('PATROL', 'UNITED_EARTH', station.position);
      }
    }

    // Spawn miners
    for (let i = 0; i < 2; i++) {
      const asteroid = system.asteroids[Math.floor(Math.random() * system.asteroids.length)];
      if (asteroid) {
        this.shipAI.createShip('MINER', 'TITAN_CONSORTIUM', asteroid.position);
      }
    }

    // Spawn occasional pirate
    if (Math.random() > 0.7) {
      const randomPos = {
        x: (Math.random() - 0.5) * 1e11,
        y: (Math.random() - 0.5) * 1e11,
        z: (Math.random() - 0.5) * 1e10
      };
      this.shipAI.createShip('PIRATE', 'PIRATE', randomPos);
    }
  }

  /**
   * Main update loop - this is where everything comes together
   */
  update(): void {
    if (this.state.paused) return;

    const now = Date.now();
    const realDeltaTime = (now - this.lastUpdateTime) / 1000; // seconds
    this.lastUpdateTime = now;

    // Apply time scale
    const deltaTime = realDeltaTime * this.state.timeScale;
    this.state.gameTime += deltaTime;
    this.state.currentTime = now;

    // Get current system
    this.currentSystem = this.starSystems.get(this.state.currentSystem) || null;
    if (!this.currentSystem) return;

    // === UPDATE ALL SUBSYSTEMS ===

    // 1. Update faction relations and diplomacy
    this.factionSystem.update(deltaTime);

    // 2. Update economy (prices, production, consumption)
    const stationMap = new Map(this.currentSystem.stations.map(s => [s.id, s]));
    this.economySystem.update(deltaTime, stationMap);

    // 3. Update NPC ship AI
    this.shipAI.update(
      deltaTime,
      stationMap,
      this.currentSystem.getAllBodies(),
      {
        position: this.state.playerShip.position,
        faction: this.state.playerShip.faction,
        id: this.state.playerShip.id
      }
    );

    // 4. Update traffic control
    this.trafficControl.update(this.shipAI.getAllShips(), deltaTime);

    // 5. Update communication system
    this.communicationSystem.update(deltaTime);

    // 6. Update planetary weather
    for (const [planetId, weather] of this.weatherSystems) {
      weather.update(deltaTime);
    }

    // 7. Update planetary geology
    for (const [planetId, geology] of this.geologySystems) {
      geology.update(deltaTime);
    }

    // 8. Update player ship systems
    this.updatePlayerShip(deltaTime);

    // 9. Update sensors
    this.state.playerShip.sensors.update(
      this.state.playerShip.position,
      this.state.playerShip.velocity,
      this.currentSystem.getAllBodies(),
      this.currentSystem.stations,
      this.shipAI.getAllShips(),
      deltaTime
    );

    // 10. Update dynamic events
    if (this.config.enableRandomEvents) {
      const playerStatus = {
        position: this.state.playerShip.position,
        health: this.state.playerShip.health,
        fuelLevel: this.state.playerShip.propulsion.getAvailableFuel(),
        lifeSupportStatus: this.state.playerShip.lifeSupport.getStatus()
      };

      this.eventSystem.update(
        deltaTime,
        playerStatus,
        this.shipAI.getAllShips(),
        this.currentSystem.stations,
        this.currentSystem.getAllBodies()
      );
    }

    // 11. Check for discoveries
    this.checkDiscoveries();
  }

  /**
   * Update player ship with all physics
   */
  private updatePlayerShip(deltaTime: number): void {
    const ship = this.state.playerShip;

    // Update propulsion (burns, fuel consumption)
    const propulsionUpdate = ship.propulsion.update(deltaTime, this.state.currentTime);

    // Apply thrust to velocity
    ship.velocity.x += propulsionUpdate.acceleration.x * deltaTime;
    ship.velocity.y += propulsionUpdate.acceleration.y * deltaTime;
    ship.velocity.z += propulsionUpdate.acceleration.z * deltaTime;

    // Calculate environmental effects
    const environment = this.calculateEnvironment(ship.position, ship.velocity);

    // Apply atmospheric drag (if in atmosphere)
    if (environment.atmosphericDrag) {
      ship.velocity.x += environment.atmosphericDrag.x * deltaTime;
      ship.velocity.y += environment.atmosphericDrag.y * deltaTime;
      ship.velocity.z += environment.atmosphericDrag.z * deltaTime;
    }

    // Apply gravity
    ship.velocity.x += environment.gravity.x * deltaTime;
    ship.velocity.y += environment.gravity.y * deltaTime;
    ship.velocity.z += environment.gravity.z * deltaTime;

    // Update position
    ship.position.x += ship.velocity.x * deltaTime;
    ship.position.y += ship.velocity.y * deltaTime;
    ship.position.z += ship.velocity.z * deltaTime;

    // Update radiation exposure
    if (environment.radiation) {
      ship.radiationTracker.update(environment.radiation, deltaTime);
    }

    // Update life support
    ship.lifeSupport.update(deltaTime, environment.temperature);

    // Update communication device position
    this.communicationSystem.updateDevicePosition(ship.id, ship.position);

    // Power management
    const powerDraw = ship.lifeSupport.getTotalPowerConsumption() +
                     ship.sensors.getPowerConsumption() +
                     propulsionUpdate.thrust.x; // Simplified

    // Hull heating from atmospheric friction
    if (environment.atmosphericHeating > 0) {
      ship.health -= environment.atmosphericHeating * 0.01 * deltaTime;
    }
  }

  /**
   * Calculate environmental effects on ship
   */
  private calculateEnvironment(position: Vector3, velocity: Vector3): {
    gravity: Vector3;
    atmosphericDrag: Vector3 | null;
    atmosphericHeating: number;
    temperature: number;
    radiation: any;
  } {
    if (!this.currentSystem) {
      return {
        gravity: { x: 0, y: 0, z: 0 },
        atmosphericDrag: null,
        atmosphericHeating: 0,
        temperature: 3,
        radiation: null
      };
    }

    let gravity = { x: 0, y: 0, z: 0 };
    let atmosphericDrag: Vector3 | null = null;
    let atmosphericHeating = 0;
    let temperature = 3; // Deep space
    let radiation = null;

    // Calculate gravity from all bodies
    for (const body of this.currentSystem.getAllBodies()) {
      const r = {
        x: body.position.x - position.x,
        y: body.position.y - position.y,
        z: body.position.z - position.z
      };

      const distance = Math.sqrt(r.x * r.x + r.y * r.y + r.z * r.z);
      if (distance < 100) continue; // Avoid division by zero

      // F = GMm/r² => a = GM/r²
      const G = 6.67430e-11;
      const acceleration = (G * body.physical.mass) / (distance * distance);

      const direction = {
        x: r.x / distance,
        y: r.y / distance,
        z: r.z / distance
      };

      gravity.x += direction.x * acceleration;
      gravity.y += direction.y * acceleration;
      gravity.z += direction.z * acceleration;

      // Check for atmospheric effects
      if (body instanceof Planet && body.physical.atmospherePressure) {
        const altitude = distance - body.physical.radius;

        if (altitude < body.physical.atmosphericHeight!) {
          // In atmosphere!
          const drag = AtmosphericPhysics.calculateDrag(
            body,
            position,
            velocity,
            0.5, // drag coefficient
            100  // cross-sectional area (m²)
          );

          const heating = AtmosphericPhysics.calculateAtmosphericHeating(
            body,
            position,
            velocity,
            100
          );

          atmosphericDrag = drag;
          atmosphericHeating = heating;
          temperature = body.surfaceTemperature;
        }
      }

      // Radiation from star
      if (body instanceof Star) {
        const radEnv = RadiationPhysics.calculateRadiationEnvironment(
          position,
          body,
          []
        );
        radiation = radEnv;
      }
    }

    return {
      gravity,
      atmosphericDrag,
      atmosphericHeating,
      temperature,
      radiation
    };
  }

  /**
   * Check for discoveries (planets, anomalies, etc.)
   */
  private checkDiscoveries(): void {
    if (!this.currentSystem) return;

    for (const body of this.currentSystem.getAllBodies()) {
      if (!this.state.discoveredBodies.has(body.id)) {
        const distance = this.distance(this.state.playerShip.position, body.position);

        // Discovery range based on sensor capability
        const detectionRange = this.state.playerShip.sensors.getDetectedObjects()
          .find(obj => obj.id === body.id);

        if (detectionRange) {
          this.state.discoveredBodies.add(body.id);
          console.log(`Discovered: ${body.id}`);
        }
      }
    }
  }

  /**
   * Get comprehensive universe status
   */
  getStatus(): {
    state: UniverseState;
    currentSystem: any;
    ships: NPCShip[];
    factions: any[];
    economy: any;
    events: any[];
    traffic: any;
  } {
    return {
      state: this.state,
      currentSystem: this.currentSystem ? {
        star: this.currentSystem.star,
        planets: this.currentSystem.planets,
        stations: this.currentSystem.stations,
        asteroids: this.currentSystem.asteroids
      } : null,
      ships: this.shipAI.getAllShips(),
      factions: this.factionSystem.getAllFactions(),
      economy: this.economySystem.getGlobalEconomy(),
      events: this.eventSystem.getActiveEvents(),
      traffic: {
        lanes: this.trafficControl.getLanes(),
        warnings: this.trafficControl.getWarnings(),
        collisions: this.trafficControl.getCollisionPredictions()
      }
    };
  }

  /**
   * Pause/unpause simulation
   */
  setPaused(paused: boolean): void {
    this.state.paused = paused;
  }

  /**
   * Set time scale
   */
  setTimeScale(scale: number): void {
    this.state.timeScale = Math.max(0.1, Math.min(1000, scale));
  }

  /**
   * Get player ship
   */
  getPlayerShip(): PlayerShip {
    return this.state.playerShip;
  }

  /**
   * Get subsystems
   */
  getSubsystems() {
    return {
      shipAI: this.shipAI,
      trafficControl: this.trafficControl,
      factionSystem: this.factionSystem,
      economySystem: this.economySystem,
      communicationSystem: this.communicationSystem,
      eventSystem: this.eventSystem
    };
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
