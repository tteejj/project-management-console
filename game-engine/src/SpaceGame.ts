/**
 * SpaceGame.ts
 * Main game engine integrating universe generation with ship physics
 */

import { createUniverse, UniverseDesigner, StarSystem } from '../../universe-system/src';
import { Spacecraft } from '../../physics-modules/src/spacecraft';
import { Vector3 } from '../../universe-system/src/CelestialBody';

export interface GameConfig {
  universeConfig?: {
    seed?: number;
    numSystems?: number;
    galaxyRadius?: number;
    campaignMode?: 'SANDBOX' | 'LINEAR' | 'OPEN_WORLD';
  };
  shipConfig?: {
    startingFuel?: number;
    startingPower?: number;
    startingPosition?: Vector3;
  };
}

/**
 * Main game engine that integrates everything
 */
export class SpaceGame {
  public universe: UniverseDesigner;
  public ship: Spacecraft;
  public currentSystem: StarSystem;
  public gameTime: number = 0;
  public paused: boolean = false;

  constructor(config: GameConfig = {}) {
    // Create universe
    this.universe = createUniverse(config.universeConfig || {
      seed: 42,
      numSystems: 10,
      campaignMode: 'OPEN_WORLD'
    });

    // Get starting system
    this.currentSystem = this.universe.getCurrentSystem()!;

    // Create ship
    this.ship = new Spacecraft({
      mass: 10000, // 10 tons
      fuelCapacity: 5000, // kg
      initialFuel: config.shipConfig?.startingFuel || 5000,
      batteryCapacity: 10000, // Wh
      initialCharge: config.shipConfig?.startingPower || 10000
    });

    // Set ship position
    if (config.shipConfig?.startingPosition) {
      this.ship.physics.position = config.shipConfig.startingPosition;
    } else {
      // Start in orbit around first planet or near star
      if (this.currentSystem.planets.length > 0) {
        const planet = this.currentSystem.planets[0];
        const orbitHeight = planet.physical.radius * 2;
        this.ship.physics.position = {
          x: planet.position.x + orbitHeight,
          y: planet.position.y,
          z: planet.position.z
        };
      } else {
        this.ship.physics.position = {
          x: this.currentSystem.star.position.x + 1e9,
          y: this.currentSystem.star.position.y,
          z: this.currentSystem.star.position.z
        };
      }
    }

    console.log('🚀 Space Game Initialized');
    console.log(`📍 System: ${this.currentSystem.name}`);
    console.log(`🌍 Planets: ${this.currentSystem.planets.length}`);
    console.log(`🛰️ Stations: ${this.currentSystem.stations.length}`);
  }

  /**
   * Main game update loop
   */
  update(deltaTime: number): void {
    if (this.paused) return;

    this.gameTime += deltaTime;

    // Update universe (orbits, hazards, missions)
    this.universe.update(deltaTime);

    // Update ship physics
    this.ship.update(deltaTime);

    // Apply environmental effects
    this.applyUniversePhysics(deltaTime);

    // Check for events
    this.checkGameEvents();
  }

  /**
   * Apply universe physics to the ship
   */
  private applyUniversePhysics(deltaTime: number): void {
    const shipPos = this.ship.physics.position;

    // 1. Gravity from all nearby bodies
    const nearbyBodies = this.currentSystem.findBodiesInRadius(shipPos, 1e10); // 10,000 km

    let totalGravityForce = { x: 0, y: 0, z: 0 };
    let strongestBody: any = null;
    let strongestForce = 0;

    for (const body of nearbyBodies) {
      if (body.type === 'STATION') continue; // Stations too small for gravity

      const dx = body.position.x - shipPos.x;
      const dy = body.position.y - shipPos.y;
      const dz = body.position.z - shipPos.z;
      const distanceSquared = dx * dx + dy * dy + dz * dz;
      const distance = Math.sqrt(distanceSquared);

      if (distance < body.physical.radius) {
        // Collision!
        this.handleCollision(body);
        return;
      }

      // Calculate gravitational force
      const G = 6.674e-11;
      const forceMagnitude = (G * body.physical.mass * this.ship.physics.mass) / distanceSquared;

      const forceDirection = {
        x: dx / distance,
        y: dy / distance,
        z: dz / distance
      };

      totalGravityForce.x += forceMagnitude * forceDirection.x;
      totalGravityForce.y += forceMagnitude * forceDirection.y;
      totalGravityForce.z += forceMagnitude * forceDirection.z;

      // Track strongest gravitational influence
      if (forceMagnitude > strongestForce) {
        strongestForce = forceMagnitude;
        strongestBody = body;
      }
    }

    // Apply gravity to ship
    const acceleration = {
      x: totalGravityForce.x / this.ship.physics.mass,
      y: totalGravityForce.y / this.ship.physics.mass,
      z: totalGravityForce.z / this.ship.physics.mass
    };

    this.ship.physics.velocity.x += acceleration.x * deltaTime;
    this.ship.physics.velocity.y += acceleration.y * deltaTime;
    this.ship.physics.velocity.z += acceleration.z * deltaTime;

    // 2. Atmospheric effects
    if (strongestBody && strongestBody.isInAtmosphere) {
      const inAtmosphere = strongestBody.isInAtmosphere(shipPos);
      if (inAtmosphere) {
        const density = strongestBody.getAtmosphericDensity(shipPos);

        // Atmospheric drag
        const velocity = Math.sqrt(
          this.ship.physics.velocity.x ** 2 +
          this.ship.physics.velocity.y ** 2 +
          this.ship.physics.velocity.z ** 2
        );

        const dragCoefficient = 0.5;
        const crossSectionalArea = 10; // m²
        const dragForce = 0.5 * density * velocity * velocity * dragCoefficient * crossSectionalArea;

        // Apply drag opposite to velocity
        if (velocity > 0) {
          const dragAccel = dragForce / this.ship.physics.mass;
          this.ship.physics.velocity.x -= (this.ship.physics.velocity.x / velocity) * dragAccel * deltaTime;
          this.ship.physics.velocity.y -= (this.ship.physics.velocity.y / velocity) * dragAccel * deltaTime;
          this.ship.physics.velocity.z -= (this.ship.physics.velocity.z / velocity) * dragAccel * deltaTime;
        }

        // Atmospheric heating
        const heatingRate = 0.5 * density * Math.pow(velocity, 3) * crossSectionalArea / 1000;
        this.ship.thermal.addExternalHeat(heatingRate * deltaTime);
      }
    }

    // 3. Solar radiation
    const distanceFromStar = Math.sqrt(
      Math.pow(shipPos.x - this.currentSystem.star.position.x, 2) +
      Math.pow(shipPos.y - this.currentSystem.star.position.y, 2) +
      Math.pow(shipPos.z - this.currentSystem.star.position.z, 2)
    );

    const radiation = this.currentSystem.star.getRadiationAt(distanceFromStar);
    const solarPanelArea = 20; // m²
    const solarPanelEfficiency = 0.25;
    const solarPower = radiation * solarPanelArea * solarPanelEfficiency;

    // Add solar power to electrical system
    this.ship.electrical.addExternalPower(solarPower * deltaTime / 3600); // Convert to Wh

    // Add solar heating
    const solarHeating = radiation * 50; // 50 m² total surface area
    this.ship.thermal.addExternalHeat(solarHeating * deltaTime / 1000); // Convert to kJ

    // 4. Environmental hazards
    const hazards = this.currentSystem.hazardSystem.getHazardsAt(shipPos);
    if (hazards.length > 0) {
      const effects = this.currentSystem.hazardSystem.getCombinedEffectsAt(shipPos, deltaTime);

      // Hull damage
      if (effects.hullDamagePerSecond) {
        // TODO: Implement hull integrity system
        console.log(`⚠️  Taking ${effects.hullDamagePerSecond.toFixed(1)} damage/sec from hazards`);
      }

      // Radiation
      if (effects.radiationPerSecond) {
        // TODO: Implement radiation tracking
        console.log(`☢️  Radiation exposure: ${effects.radiationPerSecond.toFixed(1)} rads/sec`);
      }

      // Heat
      if (effects.heatPerSecond) {
        this.ship.thermal.addExternalHeat(effects.heatPerSecond * deltaTime);
      }

      // Electrical interference
      if (effects.electricalInterference && effects.electricalInterference > 0.5) {
        // Disrupt electrical systems
        const powerLoss = this.ship.electrical.getBatteryCharge() * effects.electricalInterference * 0.01;
        this.ship.electrical.consumePower(powerLoss);
      }
    }
  }

  /**
   * Check for game events (missions, discoveries, etc.)
   */
  private checkGameEvents(): void {
    const shipPos = this.ship.physics.position;

    // Check for nearby stations
    for (const station of this.currentSystem.stations) {
      const dx = station.position.x - shipPos.x;
      const dy = station.position.y - shipPos.y;
      const dz = station.position.z - shipPos.z;
      const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);

      if (distance < 1000) {
        // Within docking range
        this.onStationNearby(station, distance);
      }
    }

    // Check for planet discoveries
    for (const planet of this.currentSystem.planets) {
      const dx = planet.position.x - shipPos.x;
      const dy = planet.position.y - shipPos.y;
      const dz = planet.position.z - shipPos.z;
      const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);

      if (distance < planet.physical.radius * 5) {
        // Close enough to scan
        this.onPlanetNearby(planet, distance);
      }
    }
  }

  /**
   * Handle collision with celestial body
   */
  private handleCollision(body: any): void {
    console.log(`💥 COLLISION with ${body.name}!`);
    // TODO: Implement crash handling
    this.paused = true;
  }

  /**
   * Event: Near a station
   */
  private onStationNearby(station: any, distance: number): void {
    // This would trigger UI events in a full game
  }

  /**
   * Event: Near a planet
   */
  private onPlanetNearby(planet: any, distance: number): void {
    // This would trigger scanning/survey events
  }

  /**
   * Jump to another star system
   */
  jumpToSystem(targetSystemId: string): boolean {
    const result = this.universe.jumpToSystem(targetSystemId);

    if (result.success) {
      this.currentSystem = this.universe.getCurrentSystem()!;
      // Reset ship position at jump point
      this.ship.physics.position = { x: 0, y: 0, z: 0 };
      this.ship.physics.velocity = { x: 0, y: 0, z: 0 };

      console.log(`✨ ${result.message}`);
      return true;
    } else {
      console.log(`❌ ${result.message}`);
      return false;
    }
  }

  /**
   * Get ship status
   */
  getShipStatus(): {
    position: Vector3;
    velocity: Vector3;
    fuel: number;
    power: number;
    temperature: number;
    altitude?: number;
    nearestBody?: string;
  } {
    const shipPos = this.ship.physics.position;
    const nearestBody = this.currentSystem.findNearestBody(shipPos, ['STATION']);

    let altitude: number | undefined;
    if (nearestBody) {
      const dx = nearestBody.position.x - shipPos.x;
      const dy = nearestBody.position.y - shipPos.y;
      const dz = nearestBody.position.z - shipPos.z;
      const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
      altitude = distance - nearestBody.physical.radius;
    }

    return {
      position: this.ship.physics.position,
      velocity: this.ship.physics.velocity,
      fuel: this.ship.fuel.getCurrentMass(),
      power: this.ship.electrical.getBatteryCharge(),
      temperature: this.ship.thermal.getAverageTemperature(),
      altitude,
      nearestBody: nearestBody?.name
    };
  }

  /**
   * Get current system info
   */
  getSystemInfo(): {
    name: string;
    starClass: string;
    planets: number;
    stations: number;
    hazards: number;
  } {
    return {
      name: this.currentSystem.name,
      starClass: this.currentSystem.star.starClass,
      planets: this.currentSystem.planets.length,
      stations: this.currentSystem.stations.length,
      hazards: this.currentSystem.hazardSystem.getActiveHazards().length
    };
  }

  /**
   * Get game statistics
   */
  getStats(): {
    universeStats: any;
    shipStats: any;
    gameTime: number;
  } {
    return {
      universeStats: this.universe.getStatistics(),
      shipStats: {
        fuel: this.ship.fuel.getCurrentMass(),
        fuelPercent: (this.ship.fuel.getCurrentMass() / this.ship.fuel.getCapacity()) * 100,
        power: this.ship.electrical.getBatteryCharge(),
        powerPercent: (this.ship.electrical.getBatteryCharge() / this.ship.electrical.getBatteryCapacity()) * 100,
        temperature: this.ship.thermal.getAverageTemperature()
      },
      gameTime: this.gameTime
    };
  }
}
