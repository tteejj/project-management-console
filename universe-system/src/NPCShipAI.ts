/**
 * NPCShipAI.ts
 * Intelligent NPC ship behaviors with state machines and decision-making
 */

import { Vector3, CelestialBody } from './CelestialBody';
import { SpaceStation } from './StationGenerator';
import { Commodity } from './EconomySystem';

export type ShipType = 'TRADER' | 'MINER' | 'PIRATE' | 'PATROL' | 'COURIER' | 'EXPLORER' | 'PASSENGER';
export type ShipState = 'IDLE' | 'TRAVELING' | 'DOCKING' | 'DOCKED' | 'TRADING' | 'MINING' | 'ATTACKING' | 'FLEEING' | 'PATROLLING';

export interface ShipCargo {
  commodity: string;
  amount: number;
  value: number;
}

export interface ShipStats {
  maxSpeed: number;           // m/s
  acceleration: number;        // m/s²
  turnRate: number;           // rad/s
  cargoCapacity: number;      // m³
  fuelCapacity: number;       // kg
  hullStrength: number;       // 0-100
  shieldStrength: number;     // 0-100
  weaponPower: number;        // arbitrary units
  sensorRange: number;        // meters
}

export interface NPCShip {
  id: string;
  name: string;
  type: ShipType;
  faction: string;
  position: Vector3;
  velocity: Vector3;
  state: ShipState;
  stats: ShipStats;
  cargo: ShipCargo[];
  fuel: number;               // kg
  credits: number;
  currentTarget?: string;     // ID of target station/ship/location
  destination?: Vector3;
  threat?: string;            // ID of threatening ship
  personality: ShipPersonality;
  route?: TradeRoute;
  memory: ShipMemory;
}

export interface ShipPersonality {
  aggression: number;         // 0-1
  greed: number;              // 0-1
  caution: number;            // 0-1
  curiosity: number;          // 0-1
  loyalty: number;            // 0-1
}

export interface ShipMemory {
  visitedStations: Set<string>;
  knownThreats: Map<string, number>; // shipId -> threat level
  profitableRoutes: TradeRoute[];
  lastTradeTime: number;
  totalProfit: number;
}

export interface TradeRoute {
  fromStation: string;
  toStation: string;
  commodity: string;
  profit: number;
  lastCheck: number;
}

export interface NavigationPath {
  waypoints: Vector3[];
  totalDistance: number;
  estimatedTime: number;
  hazards: string[];
}

/**
 * NPC Ship AI Controller
 */
export class NPCShipAI {
  private ships: Map<string, NPCShip> = new Map();
  private nextShipId = 0;

  /**
   * Create a new NPC ship
   */
  createShip(
    type: ShipType,
    faction: string,
    position: Vector3,
    customStats?: Partial<ShipStats>
  ): NPCShip {
    const stats = this.getDefaultStats(type);
    if (customStats) {
      Object.assign(stats, customStats);
    }

    const ship: NPCShip = {
      id: `ship_${this.nextShipId++}`,
      name: this.generateShipName(type, faction),
      type,
      faction,
      position: { ...position },
      velocity: { x: 0, y: 0, z: 0 },
      state: 'IDLE',
      stats,
      cargo: [],
      fuel: stats.fuelCapacity,
      credits: this.getStartingCredits(type),
      personality: this.generatePersonality(type),
      memory: {
        visitedStations: new Set(),
        knownThreats: new Map(),
        profitableRoutes: [],
        lastTradeTime: 0,
        totalProfit: 0
      }
    };

    this.ships.set(ship.id, ship);
    return ship;
  }

  /**
   * Update all NPC ships
   */
  update(
    deltaTime: number,
    stations: Map<string, SpaceStation>,
    celestialBodies: CelestialBody[],
    playerShip?: { position: Vector3; faction: string; id: string }
  ): void {
    for (const ship of this.ships.values()) {
      this.updateShip(ship, deltaTime, stations, celestialBodies, playerShip);
    }
  }

  /**
   * Update individual ship AI
   */
  private updateShip(
    ship: NPCShip,
    deltaTime: number,
    stations: Map<string, SpaceStation>,
    celestialBodies: CelestialBody[],
    playerShip?: { position: Vector3; faction: string; id: string }
  ): void {
    // Fuel consumption
    const speed = this.magnitude(ship.velocity);
    const fuelConsumption = 0.001 * speed * deltaTime; // Simplified
    ship.fuel = Math.max(0, ship.fuel - fuelConsumption);

    // Check for threats
    if (playerShip) {
      this.evaluateThreat(ship, playerShip);
    }

    // State machine
    switch (ship.state) {
      case 'IDLE':
        this.handleIdleState(ship, stations);
        break;

      case 'TRAVELING':
        this.handleTravelingState(ship, deltaTime, stations, celestialBodies);
        break;

      case 'DOCKING':
        this.handleDockingState(ship, deltaTime, stations);
        break;

      case 'DOCKED':
        this.handleDockedState(ship, deltaTime, stations);
        break;

      case 'TRADING':
        this.handleTradingState(ship, deltaTime);
        break;

      case 'ATTACKING':
        this.handleAttackingState(ship, deltaTime, playerShip);
        break;

      case 'FLEEING':
        this.handleFleeingState(ship, deltaTime, playerShip);
        break;

      case 'PATROLLING':
        this.handlePatrollingState(ship, deltaTime, stations, celestialBodies);
        break;

      case 'MINING':
        this.handleMiningState(ship, deltaTime, celestialBodies);
        break;
    }

    // Update position
    ship.position.x += ship.velocity.x * deltaTime;
    ship.position.y += ship.velocity.y * deltaTime;
    ship.position.z += ship.velocity.z * deltaTime;
  }

  /**
   * Handle IDLE state - decide what to do
   */
  private handleIdleState(ship: NPCShip, stations: Map<string, SpaceStation>): void {
    switch (ship.type) {
      case 'TRADER':
        // Find profitable trade route
        const bestRoute = this.findBestTradeRoute(ship, stations);
        if (bestRoute) {
          ship.route = bestRoute;
          ship.currentTarget = bestRoute.fromStation;
          ship.state = 'TRAVELING';
          const station = stations.get(bestRoute.fromStation);
          if (station) {
            ship.destination = { ...station.position };
          }
        }
        break;

      case 'PATROL':
        // Start patrol route
        ship.state = 'PATROLLING';
        break;

      case 'MINER':
        // Find nearest asteroid field
        ship.state = 'MINING';
        break;

      case 'PIRATE':
        // Look for targets
        if (Math.random() < ship.personality.aggression) {
          ship.state = 'PATROLLING';
        }
        break;

      case 'EXPLORER':
        // Random exploration
        ship.destination = this.generateRandomDestination(ship.position, 1e9);
        ship.state = 'TRAVELING';
        break;

      default:
        // Stay idle
        break;
    }
  }

  /**
   * Handle TRAVELING state - navigate to destination
   */
  private handleTravelingState(
    ship: NPCShip,
    deltaTime: number,
    stations: Map<string, SpaceStation>,
    celestialBodies: CelestialBody[]
  ): void {
    if (!ship.destination) {
      ship.state = 'IDLE';
      return;
    }

    // Calculate direction to destination
    const toDestination = {
      x: ship.destination.x - ship.position.x,
      y: ship.destination.y - ship.position.y,
      z: ship.destination.z - ship.position.z
    };
    const distance = this.magnitude(toDestination);

    // Arrived?
    if (distance < 1000) { // Within 1km
      if (ship.currentTarget && stations.has(ship.currentTarget)) {
        ship.state = 'DOCKING';
      } else {
        ship.state = 'IDLE';
        ship.destination = undefined;
      }
      return;
    }

    // Normalize direction
    const direction = {
      x: toDestination.x / distance,
      y: toDestination.y / distance,
      z: toDestination.z / distance
    };

    // Simple navigation - accelerate toward target
    const desiredVelocity = {
      x: direction.x * ship.stats.maxSpeed,
      y: direction.y * ship.stats.maxSpeed,
      z: direction.z * ship.stats.maxSpeed
    };

    // Smooth acceleration
    ship.velocity.x += (desiredVelocity.x - ship.velocity.x) * Math.min(1, ship.stats.acceleration * deltaTime / ship.stats.maxSpeed);
    ship.velocity.y += (desiredVelocity.y - ship.velocity.y) * Math.min(1, ship.stats.acceleration * deltaTime / ship.stats.maxSpeed);
    ship.velocity.z += (desiredVelocity.z - ship.velocity.z) * Math.min(1, ship.stats.acceleration * deltaTime / ship.stats.maxSpeed);

    // Deceleration zone
    const stoppingDistance = (ship.stats.maxSpeed * ship.stats.maxSpeed) / (2 * ship.stats.acceleration);
    if (distance < stoppingDistance) {
      const speedReduction = 1 - (stoppingDistance - distance) / stoppingDistance;
      ship.velocity.x *= speedReduction;
      ship.velocity.y *= speedReduction;
      ship.velocity.z *= speedReduction;
    }
  }

  /**
   * Handle DOCKING state
   */
  private handleDockingState(
    ship: NPCShip,
    deltaTime: number,
    stations: Map<string, SpaceStation>
  ): void {
    // Simulate docking time
    const dockingTime = 30; // 30 seconds

    // Decelerate
    ship.velocity.x *= 0.9;
    ship.velocity.y *= 0.9;
    ship.velocity.z *= 0.9;

    // After brief delay, transition to docked
    if (this.magnitude(ship.velocity) < 1) {
      ship.state = 'DOCKED';
      ship.memory.visitedStations.add(ship.currentTarget!);
    }
  }

  /**
   * Handle DOCKED state - perform station activities
   */
  private handleDockedState(
    ship: NPCShip,
    deltaTime: number,
    stations: Map<string, SpaceStation>
  ): void {
    if (!ship.currentTarget || !stations.has(ship.currentTarget)) {
      ship.state = 'IDLE';
      return;
    }

    const station = stations.get(ship.currentTarget)!;

    // Refuel
    if (ship.fuel < ship.stats.fuelCapacity * 0.9) {
      const refuelAmount = Math.min(
        ship.stats.fuelCapacity - ship.fuel,
        100 * deltaTime
      );
      ship.fuel += refuelAmount;
      ship.credits -= refuelAmount * 0.5; // Cost of fuel
    }

    // Trading behavior
    if (ship.type === 'TRADER' && ship.route) {
      ship.state = 'TRADING';
    } else {
      // Stay docked for a bit, then leave
      if (Math.random() < 0.01) { // 1% chance per update to leave
        ship.currentTarget = undefined;
        ship.state = 'IDLE';
      }
    }
  }

  /**
   * Handle TRADING state
   */
  private handleTradingState(ship: NPCShip, deltaTime: number): void {
    if (!ship.route) {
      ship.state = 'DOCKED';
      return;
    }

    // Simplified trading logic
    // In reality, this would interact with EconomySystem

    // Buy cargo at from station
    if (ship.currentTarget === ship.route.fromStation && ship.cargo.length === 0) {
      const affordableAmount = Math.min(
        ship.stats.cargoCapacity,
        ship.credits / 100 // Simplified pricing
      );

      ship.cargo.push({
        commodity: ship.route.commodity,
        amount: affordableAmount,
        value: affordableAmount * 100
      });
      ship.credits -= affordableAmount * 100;

      // Now travel to destination
      ship.currentTarget = ship.route.toStation;
      ship.state = 'TRAVELING';
    }
    // Sell cargo at destination
    else if (ship.currentTarget === ship.route.toStation && ship.cargo.length > 0) {
      const totalValue = ship.cargo.reduce((sum, c) => sum + c.value * 1.2, 0); // 20% profit
      ship.credits += totalValue;
      ship.memory.totalProfit += totalValue - ship.cargo.reduce((sum, c) => sum + c.value, 0);
      ship.cargo = [];

      ship.state = 'DOCKED';
      ship.route = undefined;
    }
  }

  /**
   * Handle ATTACKING state
   */
  private handleAttackingState(
    ship: NPCShip,
    deltaTime: number,
    playerShip?: { position: Vector3; faction: string; id: string }
  ): void {
    if (!ship.threat || !playerShip || ship.threat !== playerShip.id) {
      ship.state = 'IDLE';
      return;
    }

    // Navigate toward target
    ship.destination = { ...playerShip.position };

    const distance = this.distance(ship.position, playerShip.position);

    // In weapon range?
    if (distance < 5000) {
      // Attack! (this would trigger weapon systems in a full implementation)
      // For now, just track it
    }

    // Lost target or too damaged?
    if (distance > ship.stats.sensorRange || ship.stats.hullStrength < 30) {
      ship.state = 'FLEEING';
      ship.threat = undefined;
    }
  }

  /**
   * Handle FLEEING state
   */
  private handleFleeingState(
    ship: NPCShip,
    deltaTime: number,
    playerShip?: { position: Vector3; faction: string; id: string }
  ): void {
    if (!playerShip) {
      ship.state = 'IDLE';
      return;
    }

    // Flee in opposite direction
    const awayFromThreat = {
      x: ship.position.x - playerShip.position.x,
      y: ship.position.y - playerShip.position.y,
      z: ship.position.z - playerShip.position.z
    };

    const distance = this.magnitude(awayFromThreat);
    if (distance > ship.stats.sensorRange * 2) {
      ship.state = 'IDLE';
      return;
    }

    ship.destination = {
      x: ship.position.x + awayFromThreat.x * 10,
      y: ship.position.y + awayFromThreat.y * 10,
      z: ship.position.z + awayFromThreat.z * 10
    };
  }

  /**
   * Handle PATROLLING state
   */
  private handlePatrollingState(
    ship: NPCShip,
    deltaTime: number,
    stations: Map<string, SpaceStation>,
    celestialBodies: CelestialBody[]
  ): void {
    // Generate patrol waypoints if needed
    if (!ship.destination) {
      ship.destination = this.generateRandomDestination(ship.position, 1e8);
    }

    // Continue to destination
    const distance = this.distance(ship.position, ship.destination);
    if (distance < 10000) {
      ship.destination = this.generateRandomDestination(ship.position, 1e8);
    }
  }

  /**
   * Handle MINING state
   */
  private handleMiningState(
    ship: NPCShip,
    deltaTime: number,
    celestialBodies: CelestialBody[]
  ): void {
    // Find nearest asteroid
    // Simplified: just generate cargo over time
    const miningRate = 0.1 * deltaTime; // units per second

    const usedCapacity = ship.cargo.reduce((sum, c) => sum + c.amount * 0.5, 0);
    if (usedCapacity < ship.stats.cargoCapacity) {
      const existing = ship.cargo.find(c => c.commodity === 'iron');
      if (existing) {
        existing.amount += miningRate;
        existing.value += miningRate * 80;
      } else {
        ship.cargo.push({
          commodity: 'iron',
          amount: miningRate,
          value: miningRate * 80
        });
      }
    } else {
      // Cargo full, go sell
      ship.state = 'IDLE';
    }
  }

  /**
   * Evaluate threat from another ship
   */
  private evaluateThreat(
    ship: NPCShip,
    otherShip: { position: Vector3; faction: string; id: string }
  ): void {
    const distance = this.distance(ship.position, otherShip.position);

    // Out of sensor range
    if (distance > ship.stats.sensorRange) {
      return;
    }

    // Same faction = friendly
    if (ship.faction === otherShip.faction) {
      return;
    }

    // Threat level calculation
    let threatLevel = 0;

    if (ship.type === 'PIRATE') {
      // Pirates see everyone as potential targets
      threatLevel = ship.personality.aggression;

      if (ship.cargo.length > 0 || ship.credits > 10000) {
        // Valuable target
        threatLevel += 0.3;
      }

      if (threatLevel > 0.6) {
        ship.threat = otherShip.id;
        ship.state = 'ATTACKING';
      }
    } else {
      // Non-pirates fear pirates
      if (otherShip.faction === 'PIRATE') {
        threatLevel = 0.8;
      }

      if (ship.personality.caution * threatLevel > 0.5) {
        ship.threat = otherShip.id;
        ship.state = 'FLEEING';
      }
    }

    ship.memory.knownThreats.set(otherShip.id, threatLevel);
  }

  /**
   * Find best trade route for ship
   */
  private findBestTradeRoute(
    ship: NPCShip,
    stations: Map<string, SpaceStation>
  ): TradeRoute | null {
    // Check memory first
    if (ship.memory.profitableRoutes.length > 0) {
      const route = ship.memory.profitableRoutes[0];
      // Verify stations still exist
      if (stations.has(route.fromStation) && stations.has(route.toStation)) {
        return route;
      }
    }

    // Find new route
    const stationList = Array.from(stations.values());
    let bestRoute: TradeRoute | null = null;
    let bestProfit = 0;

    for (let i = 0; i < stationList.length; i++) {
      for (let j = 0; j < stationList.length; j++) {
        if (i === j) continue;

        const from = stationList[i];
        const to = stationList[j];

        // Simplified profit calculation
        // In real implementation, would check actual market prices
        const distance = this.distance(from.position, to.position);
        const profit = 1000 - distance / 1e6; // Arbitrary profit model

        if (profit > bestProfit) {
          bestProfit = profit;
          bestRoute = {
            fromStation: from.id,
            toStation: to.id,
            commodity: 'fuel', // Simplified
            profit,
            lastCheck: Date.now()
          };
        }
      }
    }

    if (bestRoute) {
      ship.memory.profitableRoutes.push(bestRoute);
    }

    return bestRoute;
  }

  /**
   * Get default stats for ship type
   */
  private getDefaultStats(type: ShipType): ShipStats {
    const baseStats: Record<ShipType, ShipStats> = {
      TRADER: {
        maxSpeed: 200,
        acceleration: 20,
        turnRate: 0.5,
        cargoCapacity: 1000,
        fuelCapacity: 5000,
        hullStrength: 100,
        shieldStrength: 50,
        weaponPower: 10,
        sensorRange: 100000
      },
      MINER: {
        maxSpeed: 100,
        acceleration: 10,
        turnRate: 0.3,
        cargoCapacity: 2000,
        fuelCapacity: 8000,
        hullStrength: 150,
        shieldStrength: 30,
        weaponPower: 5,
        sensorRange: 50000
      },
      PIRATE: {
        maxSpeed: 300,
        acceleration: 40,
        turnRate: 1.0,
        cargoCapacity: 500,
        fuelCapacity: 3000,
        hullStrength: 80,
        shieldStrength: 70,
        weaponPower: 50,
        sensorRange: 150000
      },
      PATROL: {
        maxSpeed: 250,
        acceleration: 30,
        turnRate: 0.8,
        cargoCapacity: 200,
        fuelCapacity: 4000,
        hullStrength: 120,
        shieldStrength: 100,
        weaponPower: 40,
        sensorRange: 200000
      },
      COURIER: {
        maxSpeed: 400,
        acceleration: 50,
        turnRate: 1.2,
        cargoCapacity: 100,
        fuelCapacity: 2000,
        hullStrength: 60,
        shieldStrength: 40,
        weaponPower: 5,
        sensorRange: 80000
      },
      EXPLORER: {
        maxSpeed: 150,
        acceleration: 15,
        turnRate: 0.6,
        cargoCapacity: 300,
        fuelCapacity: 10000,
        hullStrength: 100,
        shieldStrength: 60,
        weaponPower: 15,
        sensorRange: 300000
      },
      PASSENGER: {
        maxSpeed: 180,
        acceleration: 25,
        turnRate: 0.7,
        cargoCapacity: 50,
        fuelCapacity: 3000,
        hullStrength: 90,
        shieldStrength: 80,
        weaponPower: 10,
        sensorRange: 100000
      }
    };

    return { ...baseStats[type] };
  }

  /**
   * Generate ship personality
   */
  private generatePersonality(type: ShipType): ShipPersonality {
    const base: Record<ShipType, ShipPersonality> = {
      TRADER: { aggression: 0.1, greed: 0.8, caution: 0.7, curiosity: 0.3, loyalty: 0.6 },
      MINER: { aggression: 0.1, greed: 0.6, caution: 0.8, curiosity: 0.2, loyalty: 0.7 },
      PIRATE: { aggression: 0.9, greed: 0.9, caution: 0.3, curiosity: 0.5, loyalty: 0.4 },
      PATROL: { aggression: 0.5, greed: 0.2, caution: 0.5, curiosity: 0.4, loyalty: 0.9 },
      COURIER: { aggression: 0.2, greed: 0.5, caution: 0.6, curiosity: 0.3, loyalty: 0.7 },
      EXPLORER: { aggression: 0.2, greed: 0.3, caution: 0.5, curiosity: 0.9, loyalty: 0.5 },
      PASSENGER: { aggression: 0.1, greed: 0.7, caution: 0.9, curiosity: 0.2, loyalty: 0.8 }
    };

    const personality = { ...base[type] };

    // Add some variation
    for (const key in personality) {
      personality[key as keyof ShipPersonality] += (Math.random() - 0.5) * 0.2;
      personality[key as keyof ShipPersonality] = Math.max(0, Math.min(1, personality[key as keyof ShipPersonality]));
    }

    return personality;
  }

  /**
   * Generate ship name
   */
  private generateShipName(type: ShipType, faction: string): string {
    const prefixes = ['SS', 'ISV', 'MSV', 'CSV', 'USV'];
    const names = [
      'Venture', 'Pioneer', 'Explorer', 'Pathfinder', 'Odyssey',
      'Horizon', 'Aurora', 'Nebula', 'Frontier', 'Discovery',
      'Liberty', 'Enterprise', 'Voyager', 'Serenity', 'Endeavor'
    ];

    const prefix = prefixes[Math.floor(Math.random() * prefixes.length)];
    const name = names[Math.floor(Math.random() * names.length)];
    const number = Math.floor(Math.random() * 999);

    return `${prefix} ${name}-${number}`;
  }

  /**
   * Get starting credits for ship type
   */
  private getStartingCredits(type: ShipType): number {
    const credits: Record<ShipType, number> = {
      TRADER: 50000,
      MINER: 30000,
      PIRATE: 10000,
      PATROL: 20000,
      COURIER: 25000,
      EXPLORER: 40000,
      PASSENGER: 35000
    };
    return credits[type];
  }

  /**
   * Generate random destination
   */
  private generateRandomDestination(from: Vector3, maxDistance: number): Vector3 {
    const angle1 = Math.random() * Math.PI * 2;
    const angle2 = Math.random() * Math.PI * 2;
    const distance = Math.random() * maxDistance;

    return {
      x: from.x + Math.cos(angle1) * Math.cos(angle2) * distance,
      y: from.y + Math.sin(angle1) * Math.cos(angle2) * distance,
      z: from.z + Math.sin(angle2) * distance
    };
  }

  /**
   * Vector magnitude
   */
  private magnitude(v: Vector3): number {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  }

  /**
   * Distance between two points
   */
  private distance(p1: Vector3, p2: Vector3): number {
    const dx = p1.x - p2.x;
    const dy = p1.y - p2.y;
    const dz = p1.z - p2.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /**
   * Get all ships
   */
  getAllShips(): NPCShip[] {
    return Array.from(this.ships.values());
  }

  /**
   * Get ships by type
   */
  getShipsByType(type: ShipType): NPCShip[] {
    return Array.from(this.ships.values()).filter(s => s.type === type);
  }

  /**
   * Get ships by faction
   */
  getShipsByFaction(faction: string): NPCShip[] {
    return Array.from(this.ships.values()).filter(s => s.faction === faction);
  }

  /**
   * Get ships in range
   */
  getShipsInRange(position: Vector3, range: number): NPCShip[] {
    return Array.from(this.ships.values()).filter(s =>
      this.distance(s.position, position) <= range
    );
  }

  /**
   * Remove ship
   */
  removeShip(shipId: string): void {
    this.ships.delete(shipId);
  }
}
