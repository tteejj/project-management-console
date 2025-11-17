/**
 * HabitabilityAnalysis.ts
 * Comprehensive planetary habitability analysis
 */

import { Planet, Star } from './CelestialBody';
import { AtmosphericPhysics } from './AtmosphericPhysics';
import { RadiationPhysics } from './RadiationPhysics';
import { ThermalBalance } from './ThermalBalance';

export interface HabitabilityScore {
  overall: number;           // 0-100 (100 = Earth-like)
  breakdown: {
    temperature: number;     // 0-100
    atmosphere: number;      // 0-100
    water: number;           // 0-100
    radiation: number;       // 0-100
    gravity: number;         // 0-100
    magnetosphere: number;   // 0-100
    chemistry: number;       // 0-100
    stability: number;       // 0-100
  };
  classification: string;    // e.g., "Earth-like", "Marginal", "Uninhabitable"
  details: string[];         // Human-readable factors
}

export interface BiosphereCapability {
  canSupportLife: boolean;
  lifeType: string[];        // e.g., "microbial", "complex", "intelligent"
  biomassCapacity: number;   // relative to Earth
  primaryProducers: string[];// e.g., "photosynthesis", "chemosynthesis"
  limitingFactors: string[]; // What prevents better habitability
}

/**
 * Comprehensive habitability calculator
 */
export class HabitabilityAnalysis {
  private static readonly EARTH_MASS = 5.972e24; // kg
  private static readonly EARTH_RADIUS = 6.371e6; // m
  private static readonly EARTH_GRAVITY = 9.81; // m/s²
  private static readonly EARTH_TEMP = 288; // K (15°C average)
  private static readonly EARTH_PRESSURE = 101325; // Pa

  /**
   * Calculate comprehensive habitability score
   */
  static calculateHabitability(planet: Planet, star: Star): HabitabilityScore {
    const breakdown = {
      temperature: this.scoreTemperature(planet),
      atmosphere: this.scoreAtmosphere(planet),
      water: this.scoreWater(planet, star),
      radiation: this.scoreRadiation(planet, star),
      gravity: this.scoreGravity(planet),
      magnetosphere: this.scoreMagnetosphere(planet),
      chemistry: this.scoreChemistry(planet),
      stability: this.scoreStability(planet, star)
    };

    // Calculate overall score (weighted average)
    const weights = {
      temperature: 0.20,
      atmosphere: 0.15,
      water: 0.20,
      radiation: 0.10,
      gravity: 0.10,
      magnetosphere: 0.05,
      chemistry: 0.10,
      stability: 0.10
    };

    let overall = 0;
    for (const [key, value] of Object.entries(breakdown)) {
      overall += value * weights[key as keyof typeof weights];
    }

    // Classification
    let classification: string;
    if (overall >= 80) {
      classification = "Earth-like";
    } else if (overall >= 60) {
      classification = "Highly Habitable";
    } else if (overall >= 40) {
      classification = "Marginally Habitable";
    } else if (overall >= 20) {
      classification = "Barely Habitable";
    } else {
      classification = "Uninhabitable";
    }

    // Generate details
    const details = this.generateDetails(breakdown, planet, star);

    return {
      overall,
      breakdown,
      classification,
      details
    };
  }

  /**
   * Assess biosphere capability
   */
  static assessBiosphere(planet: Planet, star: Star): BiosphereCapability {
    const habitability = this.calculateHabitability(planet, star);

    const canSupportLife = habitability.overall >= 20;

    const lifeType: string[] = [];
    if (habitability.overall >= 80) {
      lifeType.push("microbial", "complex", "potentially intelligent");
    } else if (habitability.overall >= 60) {
      lifeType.push("microbial", "complex multicellular");
    } else if (habitability.overall >= 40) {
      lifeType.push("microbial", "simple multicellular");
    } else if (habitability.overall >= 20) {
      lifeType.push("extremophile microbial");
    }

    // Biomass capacity (relative to Earth)
    const biomassCapacity = (habitability.overall / 100) * (habitability.overall / 100);

    // Primary producers
    const primaryProducers: string[] = [];
    if (habitability.breakdown.atmosphere > 50 && planet.physical.atmosphereComposition?.has('CO2')) {
      primaryProducers.push("photosynthesis");
    }
    if (planet.physical.mass > this.EARTH_MASS * 0.5) {
      primaryProducers.push("chemosynthesis (geothermal)");
    }
    if (planet.physical.atmosphereComposition?.has('H2')) {
      primaryProducers.push("methanogenesis");
    }

    // Limiting factors
    const limitingFactors: string[] = [];
    if (habitability.breakdown.temperature < 50) {
      limitingFactors.push("Temperature extremes");
    }
    if (habitability.breakdown.water < 50) {
      limitingFactors.push("Water scarcity");
    }
    if (habitability.breakdown.atmosphere < 50) {
      limitingFactors.push("Unsuitable atmosphere");
    }
    if (habitability.breakdown.radiation < 50) {
      limitingFactors.push("High radiation");
    }
    if (habitability.breakdown.gravity < 50) {
      limitingFactors.push("Unsuitable gravity");
    }

    return {
      canSupportLife,
      lifeType,
      biomassCapacity,
      primaryProducers,
      limitingFactors
    };
  }

  /**
   * Score: Temperature suitability
   */
  private static scoreTemperature(planet: Planet): number {
    const temp = planet.surfaceTemperature;

    // Ideal range: 273K - 310K (0°C - 37°C)
    // Acceptable range: 230K - 350K (-43°C - 77°C)
    // Extremophile range: 200K - 400K (-73°C - 127°C)

    if (temp >= 273 && temp <= 310) {
      // Ideal - perfect score
      return 100;
    } else if (temp >= 250 && temp < 273) {
      // Cold but acceptable
      return 60 + (temp - 250) * (40 / 23);
    } else if (temp > 310 && temp <= 330) {
      // Warm but acceptable
      return 100 - (temp - 310) * (40 / 20);
    } else if (temp >= 230 && temp < 250) {
      // Very cold - marginal
      return (temp - 230) * (60 / 20);
    } else if (temp > 330 && temp <= 350) {
      // Very hot - marginal
      return 60 - (temp - 330) * (40 / 20);
    } else if (temp >= 200 && temp < 230) {
      // Extremophile only
      return (temp - 200) * (20 / 30);
    } else if (temp > 350 && temp <= 400) {
      // Extremophile only
      return 20 - (temp - 350) * (20 / 50);
    } else {
      // Too extreme
      return 0;
    }
  }

  /**
   * Score: Atmosphere suitability
   */
  private static scoreAtmosphere(planet: Planet): number {
    if (!planet.physical.atmospherePressure) return 0;

    const pressure = planet.physical.atmospherePressure;
    const composition = planet.physical.atmosphereComposition;

    let score = 0;

    // Pressure score
    if (pressure >= 50000 && pressure <= 200000) {
      // Ideal range (0.5 - 2 atm)
      score += 50;
    } else if (pressure >= 10000 && pressure < 50000) {
      // Low but breathable with equipment
      score += 30;
    } else if (pressure > 200000 && pressure <= 500000) {
      // High but manageable
      score += 30;
    } else if (pressure >= 1000 && pressure < 10000) {
      // Very thin - extreme difficulty
      score += 10;
    }

    // Composition score
    if (composition) {
      const o2 = composition.get('O2') || 0;
      const n2 = composition.get('N2') || 0;
      const co2 = composition.get('CO2') || 0;
      const h2o = composition.get('H2O') || 0;

      // Oxygen for aerobic life
      if (o2 >= 0.15 && o2 <= 0.35) {
        score += 30; // Ideal O2 (Earth = 0.21)
      } else if (o2 >= 0.05 && o2 < 0.15) {
        score += 15; // Low but usable
      } else if (o2 > 0) {
        score += 5; // Trace oxygen
      }

      // Nitrogen for buffer gas
      if (n2 >= 0.5) {
        score += 10;
      } else if (n2 >= 0.1) {
        score += 5;
      }

      // CO2 for photosynthesis (but not too much)
      if (co2 >= 0.0003 && co2 <= 0.01) {
        score += 10; // Good for plants
      } else if (co2 > 0.01 && co2 <= 0.05) {
        score += 5; // High but acceptable
      } else if (co2 > 0.05) {
        score -= 10; // Too much CO2 is toxic
      }
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * Score: Water availability
   */
  private static scoreWater(planet: Planet, star: Star): number {
    let score = 0;

    // Check if liquid water can exist
    const hasLiquidWater = AtmosphericPhysics.hasLiquidWater(planet);

    if (hasLiquidWater) {
      score = 80; // Can have liquid water

      // Check for actual water in atmosphere or resources
      if (planet.physical.atmosphereComposition?.has('H2O')) {
        const h2oFraction = planet.physical.atmosphereComposition.get('H2O')!;
        score += Math.min(20, h2oFraction * 200); // Up to 20 points
      }

      if (planet.resources.has('Water')) {
        const waterAbundance = planet.resources.get('Water')!;
        score = Math.min(100, score + waterAbundance * 20);
      }

      // Ocean world bonus
      if (planet.planetClass === 'OCEAN') {
        score = 100;
      }
    } else {
      // No liquid water
      // Check for ice
      const temp = planet.surfaceTemperature;
      if (temp < 273 && planet.resources.has('Water')) {
        score = 30; // Has water ice
      } else if (temp > 373) {
        // Steam atmosphere
        if (planet.physical.atmosphereComposition?.has('H2O')) {
          score = 40; // Steam atmosphere
        }
      }
    }

    return Math.min(100, score);
  }

  /**
   * Score: Radiation environment
   */
  private static scoreRadiation(planet: Planet, star: Star): number {
    const distanceToStar = Math.sqrt(
      Math.pow(planet.position.x - star.position.x, 2) +
      Math.pow(planet.position.y - star.position.y, 2) +
      Math.pow(planet.position.z - star.position.z, 2)
    );

    const environment = RadiationPhysics.calculateRadiationEnvironment(
      planet.position,
      star,
      [],
      planet.physical.mass > this.EARTH_MASS * 0.3 // Has magnetosphere if big enough
    );

    const doseRate = environment.totalIonizing; // Sv/hour

    // Score based on dose rate
    // < 0.001 Sv/hr: Perfect (Earth-like)
    // 0.001 - 0.01 Sv/hr: Acceptable
    // 0.01 - 0.1 Sv/hr: High
    // > 0.1 Sv/hr: Lethal

    if (doseRate < 0.001) {
      return 100;
    } else if (doseRate < 0.01) {
      return 100 - (doseRate - 0.001) * (40 / 0.009);
    } else if (doseRate < 0.1) {
      return 60 - (doseRate - 0.01) * (40 / 0.09);
    } else if (doseRate < 1.0) {
      return 20 - (doseRate - 0.1) * (20 / 0.9);
    } else {
      return 0;
    }
  }

  /**
   * Score: Gravity suitability
   */
  private static scoreGravity(planet: Planet): number {
    const gravity = planet.physical.surfaceGravity;

    // Ideal: 0.8g - 1.2g (Earth = 9.81)
    // Acceptable: 0.4g - 2.0g
    // Marginal: 0.2g - 3.0g

    const gEarth = gravity / this.EARTH_GRAVITY;

    if (gEarth >= 0.8 && gEarth <= 1.2) {
      return 100;
    } else if (gEarth >= 0.4 && gEarth < 0.8) {
      return 60 + (gEarth - 0.4) * (40 / 0.4);
    } else if (gEarth > 1.2 && gEarth <= 2.0) {
      return 100 - (gEarth - 1.2) * (40 / 0.8);
    } else if (gEarth >= 0.2 && gEarth < 0.4) {
      return (gEarth - 0.2) * (60 / 0.2);
    } else if (gEarth > 2.0 && gEarth <= 3.0) {
      return 60 - (gEarth - 2.0) * (40 / 1.0);
    } else {
      return Math.max(0, 20 - Math.abs(gEarth - 1.5) * 10);
    }
  }

  /**
   * Score: Magnetosphere protection
   */
  private static scoreMagnetosphere(planet: Planet): number {
    // Magnetosphere strength approximated by mass and rotation
    const massRatio = planet.physical.mass / this.EARTH_MASS;
    const rotationFactor = (86400 / planet.physical.rotationPeriod); // Earth day / planet day

    // Larger, faster-rotating planets have stronger fields
    const fieldStrength = Math.pow(massRatio, 0.5) * rotationFactor;

    if (fieldStrength >= 0.8) {
      return 100;
    } else if (fieldStrength >= 0.3) {
      return 50 + fieldStrength * (50 / 0.8);
    } else if (fieldStrength >= 0.1) {
      return 20 + fieldStrength * (30 / 0.3);
    } else {
      return fieldStrength * (20 / 0.1);
    }
  }

  /**
   * Score: Chemical environment
   */
  private static scoreChemistry(planet: Planet): number {
    let score = 50; // Base score

    const composition = planet.physical.atmosphereComposition;
    if (!composition) return 0;

    // Presence of key elements for life
    const hasCarbon = composition.has('CO2') || composition.has('CH4');
    const hasHydrogen = composition.has('H2') || composition.has('H2O');
    const hasNitrogen = composition.has('N2');
    const hasOxygen = composition.has('O2');

    if (hasCarbon) score += 15;
    if (hasHydrogen) score += 15;
    if (hasNitrogen) score += 10;
    if (hasOxygen) score += 10;

    // Check resources
    if (planet.resources.has('Water')) score += 10;
    if (planet.resources.has('Iron')) score += 5;

    // Penalize toxic atmospheres
    if (composition.has('SO2') && composition.get('SO2')! > 0.01) {
      score -= 20;
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * Score: Orbital stability
   */
  private static scoreStability(planet: Planet, star: Star): number {
    if (!planet.orbital) return 50;

    let score = 100;

    // Eccentric orbits cause temperature swings
    const eccentricity = planet.orbital.eccentricity;
    if (eccentricity > 0.2) {
      score -= (eccentricity - 0.2) * 100;
    }

    // Check if in habitable zone
    const habitableZone = star.getHabitableZone();
    const orbitalRadius = planet.orbital.semiMajorAxis;

    if (orbitalRadius >= habitableZone.inner && orbitalRadius <= habitableZone.outer) {
      score = Math.min(100, score + 20);
    } else if (orbitalRadius < habitableZone.inner * 0.5) {
      score -= 30; // Too close
    } else if (orbitalRadius > habitableZone.outer * 2) {
      score -= 30; // Too far
    }

    // High inclination can cause seasonal extremes
    const inclination = planet.orbital.inclination;
    if (inclination > Math.PI / 6) {
      score -= 10;
    }

    // Axial tilt affects seasons
    const axialTilt = planet.physical.axialTilt;
    if (axialTilt > Math.PI / 3) {
      score -= 15; // Extreme seasons
    }

    return Math.max(0, score);
  }

  /**
   * Generate human-readable details
   */
  private static generateDetails(
    breakdown: any,
    planet: Planet,
    star: Star
  ): string[] {
    const details: string[] = [];

    // Temperature
    const tempC = planet.surfaceTemperature - 273;
    if (breakdown.temperature >= 80) {
      details.push(`Temperature is ideal (${tempC.toFixed(1)}°C)`);
    } else if (breakdown.temperature >= 50) {
      details.push(`Temperature is acceptable (${tempC.toFixed(1)}°C)`);
    } else {
      details.push(`Temperature is problematic (${tempC.toFixed(1)}°C)`);
    }

    // Atmosphere
    if (breakdown.atmosphere >= 80) {
      details.push("Atmosphere is breathable");
    } else if (breakdown.atmosphere >= 50) {
      details.push("Atmosphere requires equipment");
    } else if (breakdown.atmosphere > 0) {
      details.push("Atmosphere is minimal or toxic");
    } else {
      details.push("No atmosphere");
    }

    // Water
    if (breakdown.water >= 80) {
      details.push("Abundant liquid water");
    } else if (breakdown.water >= 50) {
      details.push("Water present");
    } else {
      details.push("Water scarce or frozen");
    }

    // Radiation
    if (breakdown.radiation >= 80) {
      details.push("Radiation levels are safe");
    } else if (breakdown.radiation >= 50) {
      details.push("Moderate radiation - shielding recommended");
    } else {
      details.push("High radiation - dangerous");
    }

    // Gravity
    const gEarth = planet.physical.surfaceGravity / this.EARTH_GRAVITY;
    if (breakdown.gravity >= 80) {
      details.push(`Gravity is comfortable (${gEarth.toFixed(2)}g)`);
    } else {
      details.push(`Gravity is challenging (${gEarth.toFixed(2)}g)`);
    }

    return details;
  }
}
