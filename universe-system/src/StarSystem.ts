/**
 * StarSystem.ts
 * Complete star system generation with all bodies, stations, and hazards
 */

import {
  Star,
  Planet,
  Moon,
  Asteroid,
  CelestialBody,
  StarClass,
  PhysicalProperties,
  VisualProperties,
  Vector3
} from './CelestialBody';
import { PlanetGenerator, PlanetGenerationConfig } from './PlanetGenerator';
import { StationGenerator, SpaceStation } from './StationGenerator';
import { HazardSystem, Hazard } from './HazardSystem';

export interface StarSystemConfig {
  seed?: number;
  starClass?: StarClass;
  numPlanets?: { min: number; max: number };
  allowAsteroidBelt?: boolean;
  allowStations?: boolean;
  allowHazards?: boolean;
  civilizationLevel?: number; // 0-10 (0 = uninhabited, 10 = high tech)
  position?: Vector3; // Position in galaxy
}

export interface StarSystemData {
  id: string;
  name: string;
  star: Star;
  planets: Planet[];
  moons: Moon[];
  asteroids: Asteroid[];
  stations: SpaceStation[];
  hazards: Hazard[];
  position: Vector3;
}

/**
 * Star System Generator
 */
export class StarSystem {
  public id: string;
  public name: string;
  public star: Star;
  public planets: Planet[] = [];
  public moons: Moon[] = [];
  public asteroids: Asteroid[] = [];
  public stations: SpaceStation[] = [];
  public hazardSystem: HazardSystem;
  public position: Vector3;

  private planetGenerator: PlanetGenerator;
  private stationGenerator: StationGenerator;
  private rng: {
    next: () => number;
    range: (min: number, max: number) => number;
    choice: <T>(arr: T[]) => T;
    bool: (p?: number) => boolean;
  };

  constructor(
    id: string,
    name: string,
    config: StarSystemConfig = {}
  ) {
    const seed = config.seed || Date.now();

    // Initialize RNG
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

    this.id = id;
    this.name = name;
    this.position = config.position || { x: 0, y: 0, z: 0 };

    // Initialize generators
    this.planetGenerator = new PlanetGenerator(seed);
    this.stationGenerator = new StationGenerator(seed + 1);
    this.hazardSystem = new HazardSystem(seed + 2);

    // Generate the star
    this.star = this.generateStar(config.starClass);

    // Generate planets
    this.generatePlanets(config);

    // Generate moons
    this.generateMoons();

    // Generate asteroid belt
    if (config.allowAsteroidBelt !== false && this.rng.bool(0.6)) {
      this.generateAsteroidBelt();
    }

    // Generate stations
    if (config.allowStations !== false) {
      this.generateStations(config.civilizationLevel || 5);
    }

    // Generate hazards
    if (config.allowHazards !== false) {
      this.hazardSystem.generateSystemHazards(
        this.id,
        [...this.planets, ...this.asteroids]
      );
    }
  }

  /**
   * Generate the star
   */
  private generateStar(starClass?: StarClass): Star {
    // Select star class if not specified
    if (!starClass) {
      const distribution = [
        { class: StarClass.M, weight: 0.76 },
        { class: StarClass.K, weight: 0.12 },
        { class: StarClass.G, weight: 0.08 },
        { class: StarClass.F, weight: 0.03 },
        { class: StarClass.A, weight: 0.006 },
        { class: StarClass.B, weight: 0.001 },
        { class: StarClass.O, weight: 0.00003 }
      ];

      const roll = this.rng.next();
      let cumulative = 0;
      for (const { class: sc, weight } of distribution) {
        cumulative += weight;
        if (roll < cumulative) {
          starClass = sc;
          break;
        }
      }
      starClass = starClass || StarClass.M;
    }

    // Generate star properties based on class
    const { mass, radius, luminosity, temperature, color } = this.getStarProperties(starClass);

    const physical: PhysicalProperties = {
      mass,
      radius,
      rotationPeriod: this.rng.range(86400 * 10, 86400 * 30), // 10-30 days
      axialTilt: this.rng.range(0, Math.PI / 12),
      surfaceGravity: (6.674e-11 * mass) / (radius * radius),
      escapeVelocity: Math.sqrt(2 * 6.674e-11 * mass / radius)
    };

    const visual: VisualProperties = {
      color,
      albedo: 0.0, // Stars don't reflect light
      emissivity: 1.0
    };

    return new Star(
      `${this.id}-star`,
      this.name,
      starClass,
      physical,
      visual,
      luminosity,
      temperature
    );
  }

  /**
   * Get star properties based on class
   */
  private getStarProperties(starClass: StarClass): {
    mass: number;
    radius: number;
    luminosity: number;
    temperature: number;
    color: string;
  } {
    const solarMass = 1.989e30;
    const solarRadius = 6.96e8;
    const solarLuminosity = 3.828e26;

    switch (starClass) {
      case StarClass.O:
        return {
          mass: solarMass * this.rng.range(16, 50),
          radius: solarRadius * this.rng.range(6.6, 10),
          luminosity: solarLuminosity * this.rng.range(30000, 100000),
          temperature: this.rng.range(30000, 50000),
          color: '#9bb0ff'
        };
      case StarClass.B:
        return {
          mass: solarMass * this.rng.range(2.1, 16),
          radius: solarRadius * this.rng.range(1.8, 6.6),
          luminosity: solarLuminosity * this.rng.range(25, 30000),
          temperature: this.rng.range(10000, 30000),
          color: '#aabfff'
        };
      case StarClass.A:
        return {
          mass: solarMass * this.rng.range(1.4, 2.1),
          radius: solarRadius * this.rng.range(1.4, 1.8),
          luminosity: solarLuminosity * this.rng.range(5, 25),
          temperature: this.rng.range(7500, 10000),
          color: '#cad7ff'
        };
      case StarClass.F:
        return {
          mass: solarMass * this.rng.range(1.04, 1.4),
          radius: solarRadius * this.rng.range(1.15, 1.4),
          luminosity: solarLuminosity * this.rng.range(1.5, 5),
          temperature: this.rng.range(6000, 7500),
          color: '#f8f7ff'
        };
      case StarClass.G:
        return {
          mass: solarMass * this.rng.range(0.8, 1.04),
          radius: solarRadius * this.rng.range(0.96, 1.15),
          luminosity: solarLuminosity * this.rng.range(0.6, 1.5),
          temperature: this.rng.range(5200, 6000),
          color: '#fff4ea'
        };
      case StarClass.K:
        return {
          mass: solarMass * this.rng.range(0.45, 0.8),
          radius: solarRadius * this.rng.range(0.7, 0.96),
          luminosity: solarLuminosity * this.rng.range(0.08, 0.6),
          temperature: this.rng.range(3700, 5200),
          color: '#ffd2a1'
        };
      case StarClass.M:
        return {
          mass: solarMass * this.rng.range(0.08, 0.45),
          radius: solarRadius * this.rng.range(0.1, 0.7),
          luminosity: solarLuminosity * this.rng.range(0.001, 0.08),
          temperature: this.rng.range(2400, 3700),
          color: '#ffcc6f'
        };
      default:
        // Default to G-type (Sun-like)
        return {
          mass: solarMass,
          radius: solarRadius,
          luminosity: solarLuminosity,
          temperature: 5778,
          color: '#fff4ea'
        };
    }
  }

  /**
   * Generate planets
   */
  private generatePlanets(config: StarSystemConfig): void {
    const min = config.numPlanets?.min || 3;
    const max = config.numPlanets?.max || 12;
    const numPlanets = Math.floor(this.rng.range(min, max + 1));

    // Generate orbital radii using Titius-Bode-like law
    const orbitalRadii: number[] = [];
    for (let i = 0; i < numPlanets; i++) {
      // Modified formula: a = 0.4 + 0.3 * 2^n
      const a = 0.4 + 0.3 * Math.pow(2, i);
      // Add some randomness
      const radius = a * this.rng.range(0.8, 1.2);
      orbitalRadii.push(radius);
    }

    // Generate planets
    for (let i = 0; i < numPlanets; i++) {
      const planet = this.planetGenerator.generatePlanet(
        `${this.id}-planet-${i}`,
        this.generatePlanetName(i),
        orbitalRadii[i],
        this.star.physical.mass,
        {
          seed: config.seed,
          allowGasGiants: true,
          allowHabitableWorlds: true,
          allowExtremeWorlds: true
        }
      );

      this.star.addChild(planet);
      this.planets.push(planet);
    }
  }

  /**
   * Generate moons for all planets
   */
  private generateMoons(): void {
    for (const planet of this.planets) {
      const moons = this.planetGenerator.generateMoons(planet, {
        minMoons: 0,
        maxMoons: 8,
        minOrbitalRadius: 2,
        maxOrbitalRadius: 20
      });

      this.moons.push(...moons);
    }
  }

  /**
   * Generate asteroid belt
   */
  private generateAsteroidBelt(): void {
    // Find gap between planets (usually between inner rocky and outer gas giants)
    let beltPosition = 2.8; // Default ~Mars-Jupiter gap

    if (this.planets.length >= 4) {
      // Find largest gap
      let maxGap = 0;
      let gapPosition = 0;

      for (let i = 0; i < this.planets.length - 1; i++) {
        const innerRadius = this.planets[i].orbital!.semiMajorAxis / 1.496e11;
        const outerRadius = this.planets[i + 1].orbital!.semiMajorAxis / 1.496e11;
        const gap = outerRadius - innerRadius;

        if (gap > maxGap && innerRadius > 1.0 && outerRadius < 6.0) {
          maxGap = gap;
          gapPosition = (innerRadius + outerRadius) / 2;
        }
      }

      if (gapPosition > 0) beltPosition = gapPosition;
    }

    // Generate asteroids
    const numAsteroids = Math.floor(this.rng.range(50, 200));
    const innerRadius = beltPosition * 0.9;
    const outerRadius = beltPosition * 1.1;

    const asteroids = this.planetGenerator.generateAsteroidBelt(
      this.id,
      numAsteroids,
      innerRadius,
      outerRadius,
      this.star.physical.mass
    );

    // Set orbital elements for each asteroid
    for (const asteroid of asteroids) {
      const orbitalRadius = this.rng.range(innerRadius, outerRadius);
      asteroid.orbital = {
        semiMajorAxis: orbitalRadius * 1.496e11,
        eccentricity: this.rng.range(0, 0.3),
        inclination: this.rng.range(0, Math.PI / 6),
        longitudeOfAscendingNode: this.rng.range(0, 2 * Math.PI),
        argumentOfPeriapsis: this.rng.range(0, 2 * Math.PI),
        trueAnomaly: this.rng.range(0, 2 * Math.PI)
      };

      this.star.addChild(asteroid);
    }

    this.asteroids.push(...asteroids);
  }

  /**
   * Generate stations
   */
  private generateStations(civilizationLevel: number): void {
    // More advanced civilizations have more stations
    const stationMultiplier = civilizationLevel / 10;

    if (stationMultiplier < 0.2) return; // No stations in primitive systems

    const allBodies = [...this.planets, ...this.moons, ...this.asteroids];
    const stations = this.stationGenerator.generateStationsForSystem(this.id, allBodies);

    // Scale number of stations by civilization level
    const numStations = Math.floor(stations.length * stationMultiplier);
    this.stations = stations.slice(0, numStations);
  }

  /**
   * Update entire system
   */
  update(deltaTime: number): void {
    // Update star
    // Stars don't move much, but might rotate

    // Update planets
    for (const planet of this.planets) {
      planet.updateOrbitalPosition(deltaTime);
    }

    // Update moons
    for (const moon of this.moons) {
      moon.updateOrbitalPosition(deltaTime);
    }

    // Update asteroids (expensive, might want to optimize)
    for (const asteroid of this.asteroids) {
      asteroid.updateOrbitalPosition(deltaTime);
    }

    // Update stations
    for (const station of this.stations) {
      station.updateOrbitalPosition(deltaTime);
    }

    // Update hazards
    this.hazardSystem.update(deltaTime);
  }

  /**
   * Get all bodies in system
   */
  getAllBodies(): CelestialBody[] {
    return [
      this.star,
      ...this.planets,
      ...this.moons,
      ...this.asteroids,
      ...this.stations
    ];
  }

  /**
   * Find nearest body to a position
   */
  findNearestBody(position: Vector3, excludeTypes: string[] = []): CelestialBody | null {
    const bodies = this.getAllBodies().filter(b => !excludeTypes.includes(b.type));

    let nearest: CelestialBody | null = null;
    let minDistance = Infinity;

    for (const body of bodies) {
      const dx = position.x - body.position.x;
      const dy = position.y - body.position.y;
      const dz = position.z - body.position.z;
      const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);

      if (distance < minDistance) {
        minDistance = distance;
        nearest = body;
      }
    }

    return nearest;
  }

  /**
   * Find bodies within radius
   */
  findBodiesInRadius(position: Vector3, radius: number): CelestialBody[] {
    return this.getAllBodies().filter(body => {
      const dx = position.x - body.position.x;
      const dy = position.y - body.position.y;
      const dz = position.z - body.position.z;
      const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
      return distance <= radius;
    });
  }

  /**
   * Get habitable planets
   */
  getHabitablePlanets(): Planet[] {
    return this.planets.filter(p => p.isHabitable);
  }

  /**
   * Export system data
   */
  export(): StarSystemData {
    return {
      id: this.id,
      name: this.name,
      star: this.star,
      planets: this.planets,
      moons: this.moons,
      asteroids: this.asteroids,
      stations: this.stations,
      hazards: this.hazardSystem.getActiveHazards(),
      position: this.position
    };
  }

  /**
   * Generate planet name
   */
  private generatePlanetName(index: number): string {
    const romanNumerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'];
    return `${this.name} ${romanNumerals[index] || (index + 1)}`;
  }
}

/**
 * Quick system generator function
 */
export function generateStarSystem(
  name: string,
  config: StarSystemConfig = {}
): StarSystem {
  const id = `system-${name.toLowerCase().replace(/\s+/g, '-')}`;
  return new StarSystem(id, name, config);
}
