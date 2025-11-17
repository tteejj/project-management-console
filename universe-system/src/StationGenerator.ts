/**
 * StationGenerator.ts
 * Generation system for space stations and artificial structures
 */

import {
  CelestialBody,
  CelestialBodyType,
  PhysicalProperties,
  VisualProperties,
  Vector3,
  OrbitalElements
} from './CelestialBody';

export enum StationType {
  ORBITAL_STATION = 'ORBITAL_STATION',      // Standard space station
  TRADING_HUB = 'TRADING_HUB',              // Commercial center
  MILITARY_BASE = 'MILITARY_BASE',          // Defense station
  RESEARCH_FACILITY = 'RESEARCH_FACILITY',  // Science station
  MINING_PLATFORM = 'MINING_PLATFORM',      // Asteroid mining
  SHIPYARD = 'SHIPYARD',                    // Ship construction
  FUEL_DEPOT = 'FUEL_DEPOT',                // Refueling station
  RELAY_STATION = 'RELAY_STATION',          // Communications
  DEEP_SPACE_OUTPOST = 'DEEP_SPACE_OUTPOST' // Remote station
}

export enum StationFaction {
  UNITED_EARTH = 'UNITED_EARTH',
  MARS_FEDERATION = 'MARS_FEDERATION',
  BELT_ALLIANCE = 'BELT_ALLIANCE',
  OUTER_COLONIES = 'OUTER_COLONIES',
  INDEPENDENT = 'INDEPENDENT',
  CORPORATE = 'CORPORATE',
  PIRATE = 'PIRATE'
}

export interface StationServices {
  refueling: boolean;
  repairs: boolean;
  trading: boolean;
  missions: boolean;
  shipUpgrades: boolean;
  docking: boolean;
  medical: boolean;
  bountyBoard: boolean;
}

export interface DockingPort {
  id: string;
  type: 'SMALL' | 'MEDIUM' | 'LARGE' | 'CAPITAL';
  occupied: boolean;
  occupiedBy?: string; // ship id
}

export interface StationEconomy {
  wealthLevel: number;        // 0-1
  tradeVolume: number;         // credits per day
  commodityPrices: Map<string, number>; // commodity -> price multiplier
  demandGoods: string[];
  supplyGoods: string[];
}

/**
 * Space Station class
 */
export class SpaceStation extends CelestialBody {
  public stationType: StationType;
  public faction: StationFaction;
  public services: StationServices;
  public dockingPorts: DockingPort[] = [];
  public population: number;
  public economy: StationEconomy;
  public defenseRating: number;  // 0-10
  public reputation: Map<string, number> = new Map(); // faction -> rep (-100 to 100)

  constructor(
    id: string,
    name: string,
    stationType: StationType,
    faction: StationFaction,
    services: StationServices,
    population: number,
    economy: StationEconomy,
    defenseRating: number,
    physical: PhysicalProperties,
    visual: VisualProperties,
    position: Vector3
  ) {
    super(id, name, CelestialBodyType.STATION, physical, visual, position);
    this.stationType = stationType;
    this.faction = faction;
    this.services = services;
    this.population = population;
    this.economy = economy;
    this.defenseRating = defenseRating;
  }

  /**
   * Add docking port
   */
  addDockingPort(type: 'SMALL' | 'MEDIUM' | 'LARGE' | 'CAPITAL'): void {
    const port: DockingPort = {
      id: `${this.id}-dock-${this.dockingPorts.length}`,
      type,
      occupied: false
    };
    this.dockingPorts.push(port);
  }

  /**
   * Find available docking port
   */
  findAvailableDock(shipSize: 'SMALL' | 'MEDIUM' | 'LARGE' | 'CAPITAL'): DockingPort | null {
    const sizeOrder = ['SMALL', 'MEDIUM', 'LARGE', 'CAPITAL'];
    const shipSizeIndex = sizeOrder.indexOf(shipSize);

    // Find port of matching size or larger
    for (const port of this.dockingPorts) {
      const portSizeIndex = sizeOrder.indexOf(port.type);
      if (!port.occupied && portSizeIndex >= shipSizeIndex) {
        return port;
      }
    }

    return null;
  }

  /**
   * Dock ship
   */
  dockShip(shipId: string, shipSize: 'SMALL' | 'MEDIUM' | 'LARGE' | 'CAPITAL'): boolean {
    const port = this.findAvailableDock(shipSize);
    if (port) {
      port.occupied = true;
      port.occupiedBy = shipId;
      return true;
    }
    return false;
  }

  /**
   * Undock ship
   */
  undockShip(shipId: string): boolean {
    const port = this.dockingPorts.find(p => p.occupiedBy === shipId);
    if (port) {
      port.occupied = false;
      port.occupiedBy = undefined;
      return true;
    }
    return false;
  }

  /**
   * Get commodity price
   */
  getCommodityPrice(commodity: string, basePrice: number): number {
    const multiplier = this.economy.commodityPrices.get(commodity) || 1.0;
    return basePrice * multiplier;
  }

  /**
   * Update station reputation
   */
  updateReputation(faction: string, change: number): void {
    const current = this.reputation.get(faction) || 0;
    this.reputation.set(faction, Math.max(-100, Math.min(100, current + change)));
  }
}

/**
 * Station Generator
 */
export class StationGenerator {
  private rng: { next: () => number; range: (min: number, max: number) => number; choice: <T>(arr: T[]) => T; bool: (p?: number) => boolean };

  constructor(seed: number = Date.now()) {
    // Simple seeded RNG
    let s = seed;
    this.rng = {
      next: () => {
        s = (s * 9301 + 49297) % 233280;
        return s / 233280;
      },
      range: (min: number, max: number) => min + this.rng.next() * (max - min),
      choice: <T>(arr: T[]): T => arr[Math.floor(this.rng.next() * arr.length)],
      bool: (p: number = 0.5) => this.rng.next() < p
    };
  }

  /**
   * Generate a space station
   */
  generateStation(
    id: string,
    name: string,
    stationType: StationType,
    parentBody: CelestialBody,
    orbitalRadius?: number // in parent body radii (default 2-5)
  ): SpaceStation {
    const faction = this.selectFaction(stationType);
    const services = this.generateServices(stationType);
    const population = this.generatePopulation(stationType);
    const economy = this.generateEconomy(stationType, faction);
    const defenseRating = this.generateDefenseRating(stationType, faction);
    const physical = this.generateStationPhysics(stationType, population);
    const visual = this.generateStationVisuals(stationType, faction);

    // Position in orbit around parent body
    const orbitDistance = (orbitalRadius || this.rng.range(2, 5)) * parentBody.physical.radius;
    const angle = this.rng.range(0, 2 * Math.PI);
    const position: Vector3 = {
      x: parentBody.position.x + orbitDistance * Math.cos(angle),
      y: parentBody.position.y + orbitDistance * Math.sin(angle),
      z: parentBody.position.z + this.rng.range(-0.1, 0.1) * orbitDistance
    };

    const station = new SpaceStation(
      id,
      name,
      stationType,
      faction,
      services,
      population,
      economy,
      defenseRating,
      physical,
      visual,
      position
    );

    // Generate docking ports
    this.generateDockingPorts(station, stationType);

    // Set orbital elements
    station.orbital = this.generateStationOrbit(orbitDistance, parentBody.physical.mass);

    // Initialize reputation (neutral to most factions)
    for (const f of Object.values(StationFaction)) {
      if (f === faction) {
        station.reputation.set(f, 75);
      } else if (f === StationFaction.PIRATE && faction !== StationFaction.PIRATE) {
        station.reputation.set(f, -50);
      } else {
        station.reputation.set(f, this.rng.range(-10, 10));
      }
    }

    // Add to parent
    parentBody.addChild(station);

    return station;
  }

  /**
   * Generate multiple stations for a system
   */
  generateStationsForSystem(
    systemId: string,
    bodies: CelestialBody[]
  ): SpaceStation[] {
    const stations: SpaceStation[] = [];

    // Major planets get orbital stations
    const majorBodies = bodies.filter(b =>
      b.type === CelestialBodyType.PLANET &&
      b.physical.mass > 1e24 // Earth mass or larger
    );

    majorBodies.forEach((body, index) => {
      // Each major planet gets 1-3 stations
      const numStations = Math.floor(this.rng.range(1, 4));

      for (let i = 0; i < numStations; i++) {
        const stationType = this.selectStationType(body, index);
        const station = this.generateStation(
          `${systemId}-station-${body.id}-${i}`,
          this.generateStationName(body.name, stationType, i),
          stationType,
          body
        );
        stations.push(station);
      }
    });

    // Asteroid belts might have mining platforms
    const asteroidBodies = bodies.filter(b => b.type === CelestialBodyType.ASTEROID);
    if (asteroidBodies.length > 10 && this.rng.bool(0.7)) {
      const asteroid = this.rng.choice(asteroidBodies);
      const station = this.generateStation(
        `${systemId}-mining-platform`,
        'Deep Space Mining Platform',
        StationType.MINING_PLATFORM,
        asteroid,
        1.5
      );
      stations.push(station);
    }

    // Deep space stations (Lagrange points, etc.)
    if (this.rng.bool(0.4)) {
      const parentBody = this.rng.choice(majorBodies);
      const station = this.generateStation(
        `${systemId}-deep-space`,
        'Deep Space Relay',
        StationType.DEEP_SPACE_OUTPOST,
        parentBody,
        this.rng.range(10, 20)
      );
      stations.push(station);
    }

    return stations;
  }

  /**
   * Select appropriate station type for a body
   */
  private selectStationType(body: CelestialBody, bodyIndex: number): StationType {
    // Inner system: more military and research
    if (bodyIndex < 2) {
      return this.rng.choice([
        StationType.MILITARY_BASE,
        StationType.RESEARCH_FACILITY,
        StationType.ORBITAL_STATION
      ]);
    }

    // Mid system: trading and general
    if (bodyIndex < 4) {
      return this.rng.choice([
        StationType.TRADING_HUB,
        StationType.ORBITAL_STATION,
        StationType.SHIPYARD,
        StationType.FUEL_DEPOT
      ]);
    }

    // Outer system: fuel depots and outposts
    return this.rng.choice([
      StationType.FUEL_DEPOT,
      StationType.DEEP_SPACE_OUTPOST,
      StationType.MINING_PLATFORM
    ]);
  }

  /**
   * Select faction based on station type
   */
  private selectFaction(stationType: StationType): StationFaction {
    switch (stationType) {
      case StationType.MILITARY_BASE:
        return this.rng.choice([
          StationFaction.UNITED_EARTH,
          StationFaction.MARS_FEDERATION,
          StationFaction.OUTER_COLONIES
        ]);
      case StationType.TRADING_HUB:
        return this.rng.choice([
          StationFaction.CORPORATE,
          StationFaction.INDEPENDENT
        ]);
      case StationType.MINING_PLATFORM:
        return this.rng.choice([
          StationFaction.BELT_ALLIANCE,
          StationFaction.CORPORATE
        ]);
      case StationType.RESEARCH_FACILITY:
        return this.rng.choice([
          StationFaction.UNITED_EARTH,
          StationFaction.INDEPENDENT
        ]);
      default:
        return this.rng.choice(Object.values(StationFaction).filter(f => f !== StationFaction.PIRATE));
    }
  }

  /**
   * Generate services based on station type
   */
  private generateServices(stationType: StationType): StationServices {
    const base: StationServices = {
      refueling: false,
      repairs: false,
      trading: false,
      missions: false,
      shipUpgrades: false,
      docking: true,
      medical: false,
      bountyBoard: false
    };

    switch (stationType) {
      case StationType.TRADING_HUB:
        return { ...base, refueling: true, repairs: true, trading: true, missions: true, medical: true };
      case StationType.SHIPYARD:
        return { ...base, refueling: true, repairs: true, trading: true, shipUpgrades: true };
      case StationType.FUEL_DEPOT:
        return { ...base, refueling: true, repairs: true, trading: this.rng.bool(0.5) };
      case StationType.MILITARY_BASE:
        return { ...base, refueling: true, repairs: true, missions: true, bountyBoard: true, medical: true };
      case StationType.RESEARCH_FACILITY:
        return { ...base, refueling: this.rng.bool(0.7), missions: true, medical: true };
      case StationType.MINING_PLATFORM:
        return { ...base, refueling: true, trading: true, repairs: this.rng.bool(0.6) };
      case StationType.ORBITAL_STATION:
        return { ...base, refueling: true, repairs: true, trading: true, missions: this.rng.bool(0.7), medical: true };
      default:
        return { ...base, refueling: true };
    }
  }

  /**
   * Generate population
   */
  private generatePopulation(stationType: StationType): number {
    switch (stationType) {
      case StationType.TRADING_HUB: return Math.floor(this.rng.range(10000, 50000));
      case StationType.ORBITAL_STATION: return Math.floor(this.rng.range(5000, 20000));
      case StationType.SHIPYARD: return Math.floor(this.rng.range(8000, 30000));
      case StationType.MILITARY_BASE: return Math.floor(this.rng.range(3000, 15000));
      case StationType.RESEARCH_FACILITY: return Math.floor(this.rng.range(500, 5000));
      case StationType.MINING_PLATFORM: return Math.floor(this.rng.range(100, 2000));
      case StationType.FUEL_DEPOT: return Math.floor(this.rng.range(200, 3000));
      case StationType.RELAY_STATION: return Math.floor(this.rng.range(50, 500));
      case StationType.DEEP_SPACE_OUTPOST: return Math.floor(this.rng.range(100, 1000));
      default: return 1000;
    }
  }

  /**
   * Generate economy
   */
  private generateEconomy(stationType: StationType, faction: StationFaction): StationEconomy {
    const wealthLevel = stationType === StationType.TRADING_HUB ? this.rng.range(0.7, 1.0) :
                       stationType === StationType.MILITARY_BASE ? this.rng.range(0.5, 0.8) :
                       this.rng.range(0.3, 0.7);

    const tradeVolume = wealthLevel * this.rng.range(100000, 1000000);

    const commodityPrices = new Map<string, number>();
    const commodities = ['Fuel', 'Food', 'Water', 'Metals', 'Electronics', 'Medicine', 'Weapons'];

    commodities.forEach(commodity => {
      let multiplier = this.rng.range(0.8, 1.2);

      // Adjust based on station type
      if (commodity === 'Fuel' && stationType === StationType.FUEL_DEPOT) {
        multiplier *= 0.7; // Fuel depots have cheap fuel
      } else if (commodity === 'Weapons' && stationType === StationType.MILITARY_BASE) {
        multiplier *= 0.8;
      } else if (stationType === StationType.DEEP_SPACE_OUTPOST) {
        multiplier *= 1.5; // Everything expensive at outposts
      }

      commodityPrices.set(commodity, multiplier);
    });

    const demandGoods: string[] = [];
    const supplyGoods: string[] = [];

    // Set supply/demand based on station type
    switch (stationType) {
      case StationType.MINING_PLATFORM:
        supplyGoods.push('Metals');
        demandGoods.push('Food', 'Water', 'Electronics');
        break;
      case StationType.FUEL_DEPOT:
        supplyGoods.push('Fuel');
        demandGoods.push('Food', 'Water');
        break;
      case StationType.TRADING_HUB:
        supplyGoods.push(...commodities);
        break;
      case StationType.MILITARY_BASE:
        supplyGoods.push('Weapons');
        demandGoods.push('Food', 'Medicine', 'Electronics');
        break;
    }

    return {
      wealthLevel,
      tradeVolume,
      commodityPrices,
      demandGoods,
      supplyGoods
    };
  }

  /**
   * Generate defense rating
   */
  private generateDefenseRating(stationType: StationType, faction: StationFaction): number {
    let base = 5;

    if (stationType === StationType.MILITARY_BASE) base = 9;
    else if (stationType === StationType.TRADING_HUB) base = 7;
    else if (stationType === StationType.DEEP_SPACE_OUTPOST) base = 3;

    if (faction === StationFaction.UNITED_EARTH || faction === StationFaction.MARS_FEDERATION) {
      base += 1;
    } else if (faction === StationFaction.PIRATE) {
      base = Math.max(2, base - 3);
    }

    return Math.min(10, Math.max(1, base + this.rng.range(-1, 1)));
  }

  /**
   * Generate station physics
   */
  private generateStationPhysics(stationType: StationType, population: number): PhysicalProperties {
    // Station size based on population
    let radius: number;

    if (population < 1000) radius = 50;
    else if (population < 5000) radius = 150;
    else if (population < 20000) radius = 300;
    else radius = 500;

    // Massive stations are heavier
    const mass = population * 100 + radius * radius * 10; // simplified

    return {
      mass,
      radius,
      rotationPeriod: this.rng.range(60, 300), // 1-5 minutes for artificial gravity
      axialTilt: 0,
      surfaceGravity: 0, // Stations use rotation for gravity
      escapeVelocity: Math.sqrt(2 * 6.674e-11 * mass / radius)
    };
  }

  /**
   * Generate station visuals
   */
  private generateStationVisuals(stationType: StationType, faction: StationFaction): VisualProperties {
    let color: string;

    switch (faction) {
      case StationFaction.UNITED_EARTH: color = '#2e5c8a'; break;
      case StationFaction.MARS_FEDERATION: color = '#c14c3e'; break;
      case StationFaction.BELT_ALLIANCE: color = '#7a6f5d'; break;
      case StationFaction.OUTER_COLONIES: color = '#4a7c6b'; break;
      case StationFaction.CORPORATE: color = '#6b5b8e'; break;
      case StationFaction.PIRATE: color = '#8e5b5b'; break;
      default: color = '#808080';
    }

    return {
      color,
      albedo: 0.3,
      emissivity: 0.9
    };
  }

  /**
   * Generate docking ports
   */
  private generateDockingPorts(station: SpaceStation, stationType: StationType): void {
    let small = 2, medium = 1, large = 0, capital = 0;

    switch (stationType) {
      case StationType.TRADING_HUB:
        small = 10; medium = 5; large = 3; capital = 2;
        break;
      case StationType.SHIPYARD:
        small = 4; medium = 4; large = 4; capital = 2;
        break;
      case StationType.MILITARY_BASE:
        small = 6; medium = 4; large = 3; capital = 1;
        break;
      case StationType.ORBITAL_STATION:
        small = 6; medium = 3; large = 1;
        break;
      case StationType.FUEL_DEPOT:
        small = 4; medium = 3; large = 2;
        break;
      case StationType.MINING_PLATFORM:
        small = 3; medium = 2; large = 1;
        break;
      case StationType.DEEP_SPACE_OUTPOST:
        small = 2; medium = 1;
        break;
    }

    for (let i = 0; i < small; i++) station.addDockingPort('SMALL');
    for (let i = 0; i < medium; i++) station.addDockingPort('MEDIUM');
    for (let i = 0; i < large; i++) station.addDockingPort('LARGE');
    for (let i = 0; i < capital; i++) station.addDockingPort('CAPITAL');
  }

  /**
   * Generate orbital elements for station
   */
  private generateStationOrbit(orbitalRadius: number, parentMass: number): OrbitalElements {
    return {
      semiMajorAxis: orbitalRadius,
      eccentricity: this.rng.range(0, 0.05), // Nearly circular
      inclination: this.rng.range(0, Math.PI / 36), // Low inclination
      longitudeOfAscendingNode: this.rng.range(0, 2 * Math.PI),
      argumentOfPeriapsis: this.rng.range(0, 2 * Math.PI),
      trueAnomaly: this.rng.range(0, 2 * Math.PI)
    };
  }

  /**
   * Generate station name
   */
  private generateStationName(bodyName: string, stationType: StationType, index: number): string {
    const prefixes = ['Station', 'Outpost', 'Base', 'Platform', 'Hub', 'Facility'];
    const suffixes = ['Alpha', 'Beta', 'Gamma', 'Prime', 'One', 'Central'];

    switch (stationType) {
      case StationType.TRADING_HUB: return `${bodyName} Trade Hub`;
      case StationType.MILITARY_BASE: return `${bodyName} Defense Station`;
      case StationType.RESEARCH_FACILITY: return `${bodyName} Research Facility`;
      case StationType.SHIPYARD: return `${bodyName} Shipyards`;
      case StationType.MINING_PLATFORM: return `${bodyName} Mining Platform ${index + 1}`;
      case StationType.FUEL_DEPOT: return `${bodyName} Fuel Depot`;
      case StationType.RELAY_STATION: return `${bodyName} Relay`;
      case StationType.DEEP_SPACE_OUTPOST: return `Deep Space Outpost ${this.rng.choice(suffixes)}`;
      default: return `${bodyName} Station ${this.rng.choice(suffixes)}`;
    }
  }
}
