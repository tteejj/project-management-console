/**
 * PlanetGenerator.ts
 * Procedural generation system for planets and moons
 */

import {
  Planet,
  Moon,
  Asteroid,
  PlanetClass,
  PhysicalProperties,
  VisualProperties,
  OrbitalElements,
  Vector3
} from './CelestialBody';

/**
 * Seeded random number generator for reproducible generation
 */
class SeededRandom {
  private seed: number;

  constructor(seed: number) {
    this.seed = seed;
  }

  next(): number {
    this.seed = (this.seed * 9301 + 49297) % 233280;
    return this.seed / 233280;
  }

  range(min: number, max: number): number {
    return min + this.next() * (max - min);
  }

  choice<T>(array: T[]): T {
    return array[Math.floor(this.next() * array.length)];
  }

  bool(probability: number = 0.5): boolean {
    return this.next() < probability;
  }
}

export interface PlanetGenerationConfig {
  seed?: number;
  minPlanets?: number;
  maxPlanets?: number;
  allowGasGiants?: boolean;
  allowHabitableWorlds?: boolean;
  allowExtremeWorlds?: boolean;
  minOrbitalRadius?: number; // AU
  maxOrbitalRadius?: number; // AU
}

export interface MoonGenerationConfig {
  seed?: number;
  minMoons?: number;
  maxMoons?: number;
  minOrbitalRadius?: number; // planet radii
  maxOrbitalRadius?: number; // planet radii
}

/**
 * Procedural planet generator
 */
export class PlanetGenerator {
  private rng: SeededRandom;

  constructor(seed: number = Date.now()) {
    this.rng = new SeededRandom(seed);
  }

  /**
   * Generate a random planet
   */
  generatePlanet(
    id: string,
    name: string,
    orbitalRadius: number, // AU
    parentMass: number, // kg (star mass)
    config: Partial<PlanetGenerationConfig> = {}
  ): Planet {
    // Determine planet class based on orbital radius
    const planetClass = this.selectPlanetClass(orbitalRadius, config);

    // Generate physical properties based on class
    const physical = this.generatePhysicalProperties(planetClass);

    // Generate visual properties
    const visual = this.generateVisualProperties(planetClass);

    // Calculate surface temperature based on distance from star
    const temperature = this.calculateSurfaceTemperature(
      orbitalRadius,
      parentMass,
      planetClass,
      physical.atmospherePressure || 0
    );

    // Generate orbital elements
    const orbital = this.generateOrbitalElements(orbitalRadius, parentMass);

    const planet = new Planet(
      id,
      name,
      planetClass,
      physical,
      visual,
      temperature,
      orbital
    );

    // Add resources
    this.generateResources(planet);

    return planet;
  }

  /**
   * Generate moons for a planet
   */
  generateMoons(
    planet: Planet,
    config: MoonGenerationConfig = {}
  ): Moon[] {
    const {
      minMoons = 0,
      maxMoons = 5,
      minOrbitalRadius = 2,
      maxOrbitalRadius = 20
    } = config;

    // Gas giants get more moons
    const moonCountMultiplier = planet.planetClass === PlanetClass.GAS_GIANT ||
                                planet.planetClass === PlanetClass.ICE_GIANT ? 2 : 1;

    const numMoons = Math.floor(this.rng.range(minMoons, maxMoons * moonCountMultiplier));
    const moons: Moon[] = [];

    for (let i = 0; i < numMoons; i++) {
      const moon = this.generateMoon(
        `${planet.id}-moon-${i}`,
        `${planet.name} ${this.romanNumeral(i + 1)}`,
        planet,
        minOrbitalRadius,
        maxOrbitalRadius
      );
      planet.addChild(moon);
      moons.push(moon);
    }

    return moons;
  }

  /**
   * Generate a single moon
   */
  private generateMoon(
    id: string,
    name: string,
    planet: Planet,
    minOrbitalRadius: number,
    maxOrbitalRadius: number
  ): Moon {
    // Moon size relative to planet (0.01 to 0.4 of planet radius)
    const sizeRatio = this.rng.range(0.01, 0.4);
    const radius = planet.physical.radius * sizeRatio;

    // Moon mass (density varies)
    const density = this.rng.range(2000, 5000); // kg/m³
    const volume = (4/3) * Math.PI * Math.pow(radius, 3);
    const mass = density * volume;

    // Rotation (most moons are tidally locked)
    const orbitalRadius = planet.physical.radius * this.rng.range(minOrbitalRadius, maxOrbitalRadius);
    const orbitalPeriod = this.calculateOrbitalPeriod(orbitalRadius, planet.physical.mass);
    const rotationPeriod = this.rng.bool(0.8) ? orbitalPeriod : this.rng.range(3600, 86400);

    const surfaceGravity = (6.674e-11 * mass) / (radius * radius);
    const escapeVelocity = Math.sqrt(2 * 6.674e-11 * mass / radius);

    const physical: PhysicalProperties = {
      mass,
      radius,
      rotationPeriod,
      axialTilt: this.rng.range(0, Math.PI / 6),
      surfaceGravity,
      escapeVelocity
    };

    // Some moons have thin atmospheres
    if (mass > 1e22 && this.rng.bool(0.2)) {
      physical.atmospherePressure = this.rng.range(100, 10000);
      physical.atmosphereComposition = new Map([
        ['N2', this.rng.range(0.6, 0.9)],
        ['O2', this.rng.range(0.05, 0.3)],
        ['CO2', this.rng.range(0.01, 0.1)]
      ]);
    }

    // Visual properties
    const colors = ['#888888', '#a0a0a0', '#c0c0c0', '#806040', '#604020', '#e0d0c0'];
    const visual: VisualProperties = {
      color: this.rng.choice(colors),
      albedo: this.rng.range(0.1, 0.6),
      emissivity: this.rng.range(0.8, 0.95)
    };

    // Orbital elements
    const orbital = this.generateOrbitalElements(
      orbitalRadius / 1.496e11, // convert to AU for function
      planet.physical.mass,
      true // is moon
    );

    return new Moon(id, name, physical, visual, orbital, rotationPeriod === orbitalPeriod);
  }

  /**
   * Generate asteroid
   */
  generateAsteroid(
    id: string,
    name: string,
    orbitalRadius: number, // AU
    parentMass: number
  ): Asteroid {
    const composition = this.rng.choice<'METAL' | 'ROCK' | 'ICE'>(['METAL', 'ROCK', 'ICE']);

    // Asteroids are small
    const radius = this.rng.range(100, 50000); // 100m to 50km

    let density: number;
    switch (composition) {
      case 'METAL': density = this.rng.range(7000, 8000); break;
      case 'ROCK': density = this.rng.range(2500, 3500); break;
      case 'ICE': density = this.rng.range(900, 1200); break;
    }

    const volume = (4/3) * Math.PI * Math.pow(radius, 3);
    const mass = density * volume;

    const surfaceGravity = (6.674e-11 * mass) / (radius * radius);
    const escapeVelocity = Math.sqrt(2 * 6.674e-11 * mass / radius);

    const physical: PhysicalProperties = {
      mass,
      radius,
      rotationPeriod: this.rng.range(3600, 86400), // 1-24 hours
      axialTilt: this.rng.range(0, Math.PI),
      surfaceGravity,
      escapeVelocity
    };

    let color: string;
    switch (composition) {
      case 'METAL': color = '#b0b0c0'; break;
      case 'ROCK': color = '#808080'; break;
      case 'ICE': color = '#e0f0ff'; break;
    }

    const visual: VisualProperties = {
      color,
      albedo: this.rng.range(0.05, 0.3),
      emissivity: 0.9
    };

    const mineralWealth = composition === 'METAL' ? this.rng.range(0.6, 1.0) : this.rng.range(0.1, 0.5);

    return new Asteroid(id, name, physical, visual, composition, mineralWealth);
  }

  /**
   * Generate asteroid belt
   */
  generateAsteroidBelt(
    systemId: string,
    count: number,
    innerRadius: number, // AU
    outerRadius: number, // AU
    parentMass: number
  ): Asteroid[] {
    const asteroids: Asteroid[] = [];

    for (let i = 0; i < count; i++) {
      const orbitalRadius = this.rng.range(innerRadius, outerRadius);
      const asteroid = this.generateAsteroid(
        `${systemId}-ast-${i}`,
        `Asteroid ${i + 1}`,
        orbitalRadius,
        parentMass
      );
      asteroids.push(asteroid);
    }

    return asteroids;
  }

  /**
   * Select planet class based on orbital radius and config
   */
  private selectPlanetClass(
    orbitalRadius: number,
    config: Partial<PlanetGenerationConfig>
  ): PlanetClass {
    const {
      allowGasGiants = true,
      allowHabitableWorlds = true,
      allowExtremeWorlds = true
    } = config;

    // Inner system (< 0.5 AU): Hot, extreme
    if (orbitalRadius < 0.5) {
      const options: PlanetClass[] = [PlanetClass.LAVA, PlanetClass.TOXIC, PlanetClass.DESERT];
      return this.rng.choice(allowExtremeWorlds ? options : [PlanetClass.DESERT]);
    }

    // Habitable zone (0.5 - 2 AU)
    if (orbitalRadius < 2.0) {
      const options: PlanetClass[] = [
        PlanetClass.TERRESTRIAL,
        PlanetClass.DESERT,
        PlanetClass.OCEAN
      ];
      if (allowExtremeWorlds) options.push(PlanetClass.TOXIC);
      return this.rng.choice(allowHabitableWorlds ? options : [PlanetClass.DESERT]);
    }

    // Outer system (> 2 AU): Cold, gas giants
    if (orbitalRadius < 10) {
      const options: PlanetClass[] = [PlanetClass.ICE, PlanetClass.DESERT];
      if (allowGasGiants) {
        options.push(PlanetClass.GAS_GIANT, PlanetClass.ICE_GIANT);
      }
      return this.rng.choice(options);
    }

    // Far outer system: Mostly gas giants and ice
    return this.rng.choice(
      allowGasGiants
        ? [PlanetClass.GAS_GIANT, PlanetClass.ICE_GIANT, PlanetClass.ICE]
        : [PlanetClass.ICE]
    );
  }

  /**
   * Generate physical properties based on planet class
   */
  private generatePhysicalProperties(planetClass: PlanetClass): PhysicalProperties {
    let mass: number, radius: number, atmospherePressure: number | undefined;
    let composition: Map<string, number> | undefined;

    switch (planetClass) {
      case PlanetClass.GAS_GIANT:
        mass = this.rng.range(1e27, 2e27); // ~Jupiter
        radius = this.rng.range(6e7, 7e7);
        atmospherePressure = this.rng.range(1e5, 1e6);
        composition = new Map([['H2', 0.9], ['He', 0.1]]);
        break;

      case PlanetClass.ICE_GIANT:
        mass = this.rng.range(8e25, 1.5e26); // ~Neptune
        radius = this.rng.range(2.4e7, 2.6e7);
        atmospherePressure = this.rng.range(1e5, 5e5);
        composition = new Map([['H2', 0.8], ['He', 0.15], ['CH4', 0.05]]);
        break;

      case PlanetClass.TERRESTRIAL:
        mass = this.rng.range(3e24, 8e24); // ~Earth
        radius = this.rng.range(5e6, 7e6);
        atmospherePressure = this.rng.range(5e4, 1.5e5);
        composition = new Map([['N2', 0.78], ['O2', 0.21], ['Ar', 0.01]]);
        break;

      case PlanetClass.DESERT:
        mass = this.rng.range(2e24, 6e24); // ~Mars
        radius = this.rng.range(3e6, 6e6);
        if (this.rng.bool(0.4)) {
          atmospherePressure = this.rng.range(600, 5000);
          composition = new Map([['CO2', 0.95], ['N2', 0.03], ['Ar', 0.02]]);
        }
        break;

      case PlanetClass.ICE:
        mass = this.rng.range(1e23, 5e24);
        radius = this.rng.range(2e6, 5e6);
        if (this.rng.bool(0.3)) {
          atmospherePressure = this.rng.range(100, 1000);
          composition = new Map([['N2', 0.9], ['CH4', 0.1]]);
        }
        break;

      case PlanetClass.LAVA:
        mass = this.rng.range(2e24, 8e24);
        radius = this.rng.range(4e6, 7e6);
        atmospherePressure = this.rng.range(1e3, 1e5);
        composition = new Map([['CO2', 0.7], ['SO2', 0.2], ['N2', 0.1]]);
        break;

      case PlanetClass.OCEAN:
        mass = this.rng.range(4e24, 1e25);
        radius = this.rng.range(6e6, 8e6);
        atmospherePressure = this.rng.range(8e4, 2e5);
        composition = new Map([['N2', 0.7], ['O2', 0.25], ['H2O', 0.05]]);
        break;

      case PlanetClass.TOXIC:
        mass = this.rng.range(3e24, 1e25); // ~Venus
        radius = this.rng.range(5e6, 7e6);
        atmospherePressure = this.rng.range(5e6, 1e7); // Very thick
        composition = new Map([['CO2', 0.96], ['N2', 0.035], ['SO2', 0.005]]);
        break;

      default:
        mass = 5.972e24;
        radius = 6.371e6;
    }

    const rotationPeriod = this.rng.range(3600 * 10, 86400 * 2); // 10 hours to 2 days
    const axialTilt = this.rng.range(0, Math.PI / 4);
    const surfaceGravity = (6.674e-11 * mass) / (radius * radius);
    const escapeVelocity = Math.sqrt(2 * 6.674e-11 * mass / radius);

    return {
      mass,
      radius,
      rotationPeriod,
      axialTilt,
      surfaceGravity,
      escapeVelocity,
      atmospherePressure,
      atmosphereComposition: composition
    };
  }

  /**
   * Generate visual properties based on planet class
   */
  private generateVisualProperties(planetClass: PlanetClass): VisualProperties {
    let color: string, albedo: number;

    switch (planetClass) {
      case PlanetClass.GAS_GIANT:
        color = this.rng.choice(['#d4a574', '#c9b896', '#e8d4b0']);
        albedo = this.rng.range(0.4, 0.6);
        break;
      case PlanetClass.ICE_GIANT:
        color = this.rng.choice(['#4a90e2', '#5ca8ff', '#6eb5ff']);
        albedo = this.rng.range(0.5, 0.7);
        break;
      case PlanetClass.TERRESTRIAL:
        color = this.rng.choice(['#4a7c59', '#6b8e73', '#5a9b6d']);
        albedo = this.rng.range(0.3, 0.4);
        break;
      case PlanetClass.DESERT:
        color = this.rng.choice(['#c97435', '#d4834a', '#e09560']);
        albedo = this.rng.range(0.2, 0.35);
        break;
      case PlanetClass.ICE:
        color = this.rng.choice(['#d4e8f0', '#e8f4f8', '#ffffff']);
        albedo = this.rng.range(0.6, 0.9);
        break;
      case PlanetClass.LAVA:
        color = this.rng.choice(['#ff4500', '#ff6347', '#ff7f50']);
        albedo = this.rng.range(0.1, 0.2);
        break;
      case PlanetClass.OCEAN:
        color = this.rng.choice(['#0066cc', '#0077dd', '#0088ee']);
        albedo = this.rng.range(0.35, 0.5);
        break;
      case PlanetClass.TOXIC:
        color = this.rng.choice(['#9acd32', '#a0d648', '#b0e060']);
        albedo = this.rng.range(0.7, 0.85);
        break;
      default:
        color = '#808080';
        albedo = 0.3;
    }

    // Some gas giants have rings
    let rings: VisualProperties['rings'];
    if ((planetClass === PlanetClass.GAS_GIANT || planetClass === PlanetClass.ICE_GIANT) &&
        this.rng.bool(0.4)) {
      const radius = this.generatePhysicalProperties(planetClass).radius;
      rings = {
        innerRadius: radius * this.rng.range(1.5, 2.0),
        outerRadius: radius * this.rng.range(2.5, 3.5),
        thickness: this.rng.range(10, 100),
        color: this.rng.choice(['#c0c0c0', '#d0d0d0', '#e0e0e0']),
        opacity: this.rng.range(0.3, 0.7)
      };
    }

    return {
      color,
      albedo,
      emissivity: this.rng.range(0.85, 0.95),
      rings
    };
  }

  /**
   * Calculate surface temperature
   */
  private calculateSurfaceTemperature(
    orbitalRadius: number, // AU
    starMass: number,
    planetClass: PlanetClass,
    atmospherePressure: number
  ): number {
    const AU = 1.496e11;
    const distance = orbitalRadius * AU;

    // Simplified stellar luminosity from mass (main sequence approximation)
    const solarMass = 1.989e30;
    const massRatio = starMass / solarMass;
    const luminosity = 3.828e26 * Math.pow(massRatio, 3.5);

    // Solar flux at distance
    const flux = luminosity / (4 * Math.PI * distance * distance);

    // Base temperature (no atmosphere)
    const albedo = this.generateVisualProperties(planetClass).albedo;
    const baseTemp = Math.pow(
      (flux * (1 - albedo)) / (4 * 5.67e-8),
      0.25
    );

    // Greenhouse effect
    let greenhouse = 0;
    if (atmospherePressure > 1000) {
      greenhouse = Math.log10(atmospherePressure / 1000) * 50;
    }

    // Internal heating for gas giants
    let internalHeating = 0;
    if (planetClass === PlanetClass.GAS_GIANT || planetClass === PlanetClass.ICE_GIANT) {
      internalHeating = this.rng.range(5, 20);
    }

    // Volcanic heating for lava worlds
    if (planetClass === PlanetClass.LAVA) {
      internalHeating = this.rng.range(200, 500);
    }

    return baseTemp + greenhouse + internalHeating;
  }

  /**
   * Generate orbital elements
   */
  private generateOrbitalElements(
    orbitalRadius: number, // AU
    parentMass: number,
    isMoon: boolean = false
  ): OrbitalElements {
    const AU = 1.496e11;
    const semiMajorAxis = isMoon ? orbitalRadius : orbitalRadius * AU;

    return {
      semiMajorAxis,
      eccentricity: isMoon ? this.rng.range(0, 0.1) : this.rng.range(0, 0.3),
      inclination: this.rng.range(0, Math.PI / 12),
      longitudeOfAscendingNode: this.rng.range(0, 2 * Math.PI),
      argumentOfPeriapsis: this.rng.range(0, 2 * Math.PI),
      trueAnomaly: this.rng.range(0, 2 * Math.PI)
    };
  }

  /**
   * Generate resources for a planet
   */
  private generateResources(planet: Planet): void {
    const resources = ['Iron', 'Water', 'Uranium', 'Helium-3', 'Rare Earths'];

    resources.forEach(resource => {
      let abundance = this.rng.range(0, 1);

      // Adjust based on planet class
      if (resource === 'Water' && planet.planetClass === PlanetClass.OCEAN) {
        abundance = this.rng.range(0.8, 1.0);
      } else if (resource === 'Iron' && planet.planetClass === PlanetClass.TERRESTRIAL) {
        abundance = this.rng.range(0.5, 0.9);
      } else if (resource === 'Helium-3' &&
                 (planet.planetClass === PlanetClass.GAS_GIANT ||
                  planet.planetClass === PlanetClass.ICE_GIANT)) {
        abundance = this.rng.range(0.6, 1.0);
      }

      if (abundance > 0.1) {
        planet.addResource(resource, abundance);
      }
    });
  }

  /**
   * Calculate orbital period using Kepler's third law
   */
  private calculateOrbitalPeriod(semiMajorAxis: number, parentMass: number): number {
    const G = 6.674e-11;
    return 2 * Math.PI * Math.sqrt(Math.pow(semiMajorAxis, 3) / (G * parentMass));
  }

  /**
   * Convert number to Roman numeral
   */
  private romanNumeral(num: number): string {
    const romans = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
    return romans[num - 1] || num.toString();
  }
}
