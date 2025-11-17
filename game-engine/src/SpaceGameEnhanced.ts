/**
 * SpaceGameEnhanced.ts
 * Enhanced game engine using ALL real physics systems
 */

import { createUniverse, UniverseDesigner, StarSystem } from '../../universe-system/src';
import { Spacecraft } from '../../physics-modules/src/spacecraft';
import { Vector3, CelestialBody, Planet } from '../../universe-system/src/CelestialBody';
import { AtmosphericPhysics } from '../../universe-system/src/AtmosphericPhysics';
import { RadiationPhysics, RadiationTracker } from '../../universe-system/src/RadiationPhysics';
import { ThermalBalance } from '../../universe-system/src/ThermalBalance';
import { HabitabilityAnalysis } from '../../universe-system/src/HabitabilityAnalysis';
import { EconomySystem } from '../../universe-system/src/EconomySystem';

export interface EnhancedGameConfig {
  universeConfig?: {
    seed?: number;
    numSystems?: number;
    galaxyRadius?: number;
    campaignMode?: 'SANDBOX' | 'LINEAR' | 'OPEN_WORLD';
  };
  shipConfig?: {
    mass?: number;
    fuelCapacity?: number;
    startingFuel?: number;
    batteryCapacity?: number;
    startingPower?: number;
    startingPosition?: Vector3;
    dragCoefficient?: number;
    crossSectionalArea?: number;
  };
}

export interface ShipEnvironment {
  gravity: Vector3;
  atmosphericDrag: Vector3;
  atmosphericHeating: number; // watts
  solarHeating: number;
  solarPower: number;
  albedoHeating: number;
  radiationDose: number; // Sv/hour
  nearestBody?: CelestialBody;
  altitude?: number;
  inAtmosphere: boolean;
  temperature: number; // K
}

/**
 * Enhanced space game with full physics integration
 */
export class SpaceGameEnhanced {
  public universe: UniverseDesigner;
  public ship: Spacecraft;
  public currentSystem: StarSystem;
  public economy: EconomySystem;
  public radiationTracker: RadiationTracker;

  public gameTime: number = 0;
  public paused: boolean = false;

  // Ship configuration
  private dragCoefficient: number;
  private crossSectionalArea: number;
  private solarPanelArea: number = 20; // m²
  private solarPanelEfficiency: number = 0.25;

  // Environmental state
  public environment: ShipEnvironment;

  constructor(config: EnhancedGameConfig = {}) {
    // Create universe
    this.universe = createUniverse(config.universeConfig || {
      seed: 42,
      numSystems: 10,
      campaignMode: 'OPEN_WORLD'
    });

    this.currentSystem = this.universe.getCurrentSystem()!;

    // Initialize economy
    this.economy = new EconomySystem();
    this.currentSystem.stations.forEach(station => {
      this.economy.registerStation(station);
    });

    // Initialize radiation tracker
    this.radiationTracker = new RadiationTracker();
    this.radiationTracker.addShielding('aluminum', 0.02); // 2cm aluminum hull

    // Create ship
    const shipConfig = config.shipConfig || {};
    this.ship = new Spacecraft({
      mass: shipConfig.mass || 10000,
      fuelCapacity: shipConfig.fuelCapacity || 5000,
      initialFuel: shipConfig.startingFuel || 5000,
      batteryCapacity: shipConfig.batteryCapacity || 10000,
      initialCharge: shipConfig.startingPower || 10000
    });

    this.dragCoefficient = shipConfig.dragCoefficient || 0.5;
    this.crossSectionalArea = shipConfig.crossSectionalArea || 10;

    // Set initial ship position
    this.initializeShipPosition(shipConfig.startingPosition);

    // Initialize environment
    this.environment = this.calculateEnvironment();

    console.log('🚀 Enhanced Space Game Initialized');
    console.log(`📍 System: ${this.currentSystem.name}`);
    console.log(`⭐ Star: ${this.currentSystem.star.starClass} class`);
    console.log(`🌍 Planets: ${this.currentSystem.planets.length}`);
    console.log(`🛰️ Stations: ${this.currentSystem.stations.length}`);
  }

  /**
   * Initialize ship position
   */
  private initializeShipPosition(startingPosition?: Vector3): void {
    if (startingPosition) {
      this.ship.physics.position = startingPosition;
    } else if (this.currentSystem.planets.length > 0) {
      // Start in low orbit around first habitable planet, or first planet
      const habitablePlanets = this.currentSystem.getHabitablePlanets();
      const planet = habitablePlanets.length > 0 ? habitablePlanets[0] : this.currentSystem.planets[0];

      const orbitHeight = planet.physical.radius * 1.2; // 20% above surface
      this.ship.physics.position = {
        x: planet.position.x + orbitHeight,
        y: planet.position.y,
        z: planet.position.z
      };

      // Set orbital velocity
      const orbitalSpeed = Math.sqrt(6.674e-11 * planet.physical.mass / orbitHeight);
      this.ship.physics.velocity = {
        x: 0,
        y: orbitalSpeed,
        z: 0
      };

      console.log(`🛸 Starting in orbit around ${planet.name}`);
      console.log(`   Altitude: ${(orbitHeight - planet.physical.radius) / 1000} km`);
      console.log(`   Orbital speed: ${orbitalSpeed} m/s`);
    } else {
      // Start near star
      this.ship.physics.position = {
        x: this.currentSystem.star.position.x + 1e9,
        y: this.currentSystem.star.position.y,
        z: this.currentSystem.star.position.z
      };
    }
  }

  /**
   * Main update loop with real physics
   */
  update(deltaTime: number): void {
    if (this.paused) return;

    this.gameTime += deltaTime;

    // Update universe
    this.universe.update(deltaTime);
    this.economy.update(deltaTime);

    // Calculate environmental effects BEFORE ship update
    this.environment = this.calculateEnvironment();

    // Apply environmental forces to ship
    this.applyEnvironmentalPhysics(deltaTime);

    // Update ship physics
    this.ship.update(deltaTime);

    // Update radiation tracking
    const radEnv = this.calculateRadiationEnvironment();
    this.radiationTracker.update(radEnv, deltaTime);

    // Check for critical events
    this.checkCriticalEvents();
  }

  /**
   * Calculate complete environmental state
   */
  private calculateEnvironment(): ShipEnvironment {
    const shipPos = this.ship.physics.position;
    const shipVel = this.ship.physics.velocity;

    // Find nearest body
    const nearestBody = this.currentSystem.findNearestBody(shipPos, ['STATION']);

    let altitude: number | undefined;
    let inAtmosphere = false;

    if (nearestBody) {
      const distance = this.distance(shipPos, nearestBody.position);
      altitude = distance - nearestBody.physical.radius;

      if (nearestBody instanceof Planet) {
        inAtmosphere = nearestBody.isInAtmosphere(shipPos);
      }
    }

    // Calculate gravity
    const gravity = this.calculateGravity();

    // Calculate atmospheric effects
    let atmosphericDrag = { x: 0, y: 0, z: 0 };
    let atmosphericHeating = 0;

    if (inAtmosphere && nearestBody instanceof Planet) {
      atmosphericDrag = AtmosphericPhysics.calculateDrag(
        nearestBody,
        shipPos,
        shipVel,
        this.dragCoefficient,
        this.crossSectionalArea
      );

      atmosphericHeating = AtmosphericPhysics.calculateAtmosphericHeating(
        nearestBody,
        shipPos,
        shipVel,
        this.crossSectionalArea
      );
    }

    // Calculate thermal environment
    const nearbyBodies = this.currentSystem.findBodiesInRadius(shipPos, 1e10);
    const thermal = ThermalBalance.calculateThermalEnvironment(
      shipPos,
      this.currentSystem.star,
      nearbyBodies.filter(b => b !== nearestBody),
      0.3, // Ship albedo
      0.9  // Ship emissivity
    );

    // Solar power generation
    const solarPower = thermal.solarHeating * this.solarPanelArea * this.solarPanelEfficiency;

    // Radiation dose
    const radEnv = this.calculateRadiationEnvironment();
    const radiationDose = radEnv.totalIonizing;

    return {
      gravity,
      atmosphericDrag,
      atmosphericHeating,
      solarHeating: thermal.solarHeating,
      solarPower,
      albedoHeating: thermal.albedoHeating,
      radiationDose,
      nearestBody,
      altitude,
      inAtmosphere,
      temperature: thermal.equilibriumTemp
    };
  }

  /**
   * Calculate gravitational force from all nearby bodies
   */
  private calculateGravity(): Vector3 {
    const shipPos = this.ship.physics.position;
    const shipMass = this.ship.physics.mass;
    const G = 6.674e-11;

    // Get all bodies within 10 million km
    const nearbyBodies = this.currentSystem.findBodiesInRadius(shipPos, 1e10);

    let totalForce = { x: 0, y: 0, z: 0 };

    for (const body of nearbyBodies) {
      if (body.type === 'STATION') continue; // Stations too small

      const dx = body.position.x - shipPos.x;
      const dy = body.position.y - shipPos.y;
      const dz = body.position.z - shipPos.z;
      const distanceSquared = dx * dx + dy * dy + dz * dz;
      const distance = Math.sqrt(distanceSquared);

      if (distance < body.physical.radius) {
        // Collision imminent!
        continue;
      }

      // F = G * M * m / r²
      const forceMagnitude = (G * body.physical.mass * shipMass) / distanceSquared;

      totalForce.x += forceMagnitude * (dx / distance);
      totalForce.y += forceMagnitude * (dy / distance);
      totalForce.z += forceMagnitude * (dz / distance);
    }

    return totalForce;
  }

  /**
   * Calculate radiation environment
   */
  private calculateRadiationEnvironment() {
    const shipPos = this.ship.physics.position;
    const nearbyPlanets = this.currentSystem.planets.filter(p => {
      const dist = this.distance(shipPos, p.position);
      return dist < p.physical.radius * 10;
    });

    // Check if in magnetosphere (approximated by being close to large planet)
    let inMagnetosphere = false;
    if (this.environment.nearestBody instanceof Planet) {
      const planet = this.environment.nearestBody;
      if (planet.physical.mass > 3e24) { // Earth-mass or larger
        const distance = this.distance(shipPos, planet.position);
        const magnetosphereRadius = planet.physical.radius * 10;
        inMagnetosphere = distance < magnetosphereRadius;
      }
    }

    return RadiationPhysics.calculateRadiationEnvironment(
      shipPos,
      this.currentSystem.star,
      nearbyPlanets,
      inMagnetosphere
    );
  }

  /**
   * Apply environmental physics to ship
   */
  private applyEnvironmentalPhysics(deltaTime: number): void {
    // 1. Gravity
    const gravityAccel = {
      x: this.environment.gravity.x / this.ship.physics.mass,
      y: this.environment.gravity.y / this.ship.physics.mass,
      z: this.environment.gravity.z / this.ship.physics.mass
    };

    this.ship.physics.velocity.x += gravityAccel.x * deltaTime;
    this.ship.physics.velocity.y += gravityAccel.y * deltaTime;
    this.ship.physics.velocity.z += gravityAccel.z * deltaTime;

    // 2. Atmospheric drag
    const dragAccel = {
      x: this.environment.atmosphericDrag.x / this.ship.physics.mass,
      y: this.environment.atmosphericDrag.y / this.ship.physics.mass,
      z: this.environment.atmosphericDrag.z / this.ship.physics.mass
    };

    this.ship.physics.velocity.x += dragAccel.x * deltaTime;
    this.ship.physics.velocity.y += dragAccel.y * deltaTime;
    this.ship.physics.velocity.z += dragAccel.z * deltaTime;

    // 3. Atmospheric heating
    if (this.environment.atmosphericHeating > 0) {
      // Convert watts to kJ for thermal system
      const heatingKJ = (this.environment.atmosphericHeating * deltaTime) / 1000;
      this.ship.thermal.addExternalHeat(heatingKJ);
    }

    // 4. Solar heating
    const solarHeatingKJ = (this.environment.solarHeating * 50 * deltaTime) / 1000; // 50 m² surface
    this.ship.thermal.addExternalHeat(solarHeatingKJ);

    // 5. Albedo heating
    const albedoHeatingKJ = (this.environment.albedoHeating * 50 * deltaTime) / 1000;
    this.ship.thermal.addExternalHeat(albedoHeatingKJ);

    // 6. Solar power generation
    const powerGenerated = (this.environment.solarPower * deltaTime) / 3600; // Convert to Wh
    this.ship.electrical.addExternalPower(powerGenerated);

    // 7. Hazard effects
    const hazards = this.currentSystem.hazardSystem.getHazardsAt(this.ship.physics.position);
    if (hazards.length > 0) {
      const effects = this.currentSystem.hazardSystem.getCombinedEffectsAt(
        this.ship.physics.position,
        deltaTime
      );

      if (effects.heatPerSecond) {
        this.ship.thermal.addExternalHeat(effects.heatPerSecond * deltaTime);
      }

      if (effects.electricalInterference && effects.electricalInterference > 0.5) {
        const powerLoss = this.ship.electrical.getBatteryCharge() * effects.electricalInterference * 0.01;
        this.ship.electrical.consumePower(powerLoss);
      }
    }
  }

  /**
   * Check for critical events
   */
  private checkCriticalEvents(): void {
    // Check radiation exposure
    const health = this.radiationTracker.getHealthStatus();
    if (health.fatal) {
      console.log('☢️  CRITICAL: Fatal radiation exposure!');
      console.log(`   Total dose: ${this.radiationTracker.getDose().total} Sv`);
      this.paused = true;
    }

    // Check altitude
    if (this.environment.altitude !== undefined && this.environment.altitude < 100) {
      if (this.environment.nearestBody) {
        const velocity = Math.sqrt(
          this.ship.physics.velocity.x ** 2 +
          this.ship.physics.velocity.y ** 2 +
          this.ship.physics.velocity.z ** 2
        );

        if (velocity > 10 && this.environment.altitude < 0) {
          console.log(`💥 CRASH! Impacted ${this.environment.nearestBody.name} at ${velocity.toFixed(0)} m/s`);
          this.paused = true;
        }
      }
    }

    // Check overheating
    const temp = this.ship.thermal.getAverageTemperature();
    if (temp > 500) {
      console.log('🔥 WARNING: Critical temperature! Systems failing!');
    }
  }

  /**
   * Get detailed ship status
   */
  getDetailedStatus() {
    const velocity = Math.sqrt(
      this.ship.physics.velocity.x ** 2 +
      this.ship.physics.velocity.y ** 2 +
      this.ship.physics.velocity.z ** 2
    );

    const radDose = this.radiationTracker.getDose();
    const health = this.radiationTracker.getHealthStatus();

    return {
      position: this.ship.physics.position,
      velocity: {
        magnitude: velocity,
        vector: this.ship.physics.velocity
      },
      fuel: {
        mass: this.ship.fuel.getCurrentMass(),
        percent: (this.ship.fuel.getCurrentMass() / this.ship.fuel.getCapacity()) * 100
      },
      power: {
        charge: this.ship.electrical.getBatteryCharge(),
        percent: (this.ship.electrical.getBatteryCharge() / this.ship.electrical.getBatteryCapacity()) * 100,
        solarGeneration: this.environment.solarPower
      },
      thermal: {
        temperature: this.ship.thermal.getAverageTemperature(),
        externalHeating: this.environment.atmosphericHeating + this.environment.solarHeating + this.environment.albedoHeating
      },
      environment: {
        nearestBody: this.environment.nearestBody?.name,
        altitude: this.environment.altitude,
        inAtmosphere: this.environment.inAtmosphere,
        gravity: Math.sqrt(
          this.environment.gravity.x ** 2 +
          this.environment.gravity.y ** 2 +
          this.environment.gravity.z ** 2
        ),
        radiation: {
          dose: radDose.total,
          rate: radDose.rate,
          health: health.severity,
          effects: health.effects
        }
      },
      gameTime: this.gameTime
    };
  }

  /**
   * Scan nearest planet for detailed info
   */
  scanNearestPlanet(): any {
    if (!this.environment.nearestBody || !(this.environment.nearestBody instanceof Planet)) {
      return null;
    }

    const planet = this.environment.nearestBody;
    const habitability = HabitabilityAnalysis.calculateHabitability(planet, this.currentSystem.star);
    const biosphere = HabitabilityAnalysis.assessBiosphere(planet, this.currentSystem.star);

    let atmosphericProfile = null;
    if (planet.physical.atmospherePressure) {
      atmosphericProfile = AtmosphericPhysics.generateAtmosphericProfile(planet);
    }

    const energyBalance = ThermalBalance.calculatePlanetaryEnergyBalance(
      planet,
      this.currentSystem.star
    );

    return {
      name: planet.name,
      class: planet.planetClass,
      physical: {
        mass: planet.physical.mass,
        radius: planet.physical.radius,
        gravity: planet.physical.surfaceGravity,
        temperature: planet.surfaceTemperature
      },
      habitability: {
        score: habitability.overall,
        classification: habitability.classification,
        breakdown: habitability.breakdown,
        details: habitability.details
      },
      biosphere: {
        canSupportLife: biosphere.canSupportLife,
        lifeTypes: biosphere.lifeType,
        biomassCapacity: biosphere.biomassCapacity,
        primaryProducers: biosphere.primaryProducers,
        limitingFactors: biosphere.limitingFactors
      },
      atmosphere: atmosphericProfile,
      energy: energyBalance,
      resources: Array.from(planet.resources.entries())
    };
  }

  /**
   * Trade at current station
   */
  tradeAtStation(stationId: string, commodityId: string, amount: number, buying: boolean) {
    return this.economy.executeTrade(stationId, commodityId, amount, buying);
  }

  /**
   * Get profitable trade routes
   */
  getTradeRoutes(limit: number = 10) {
    return this.economy.getTopTradeRoutes(limit);
  }

  /**
   * Helper: distance calculation
   */
  private distance(p1: Vector3, p2: Vector3): number {
    const dx = p1.x - p2.x;
    const dy = p1.y - p2.y;
    const dz = p1.z - p2.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }
}
