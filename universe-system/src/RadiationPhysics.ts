/**
 * RadiationPhysics.ts
 * Comprehensive radiation modeling and tracking
 */

import { Vector3, Star, Planet, CelestialBody } from './CelestialBody';

export interface RadiationDose {
  total: number;           // Total accumulated dose (Sv - sieverts)
  rate: number;            // Current dose rate (Sv/hour)
  sources: Map<string, number>; // source -> dose contribution
}

export interface RadiationEnvironment {
  solarRadiation: number;  // W/m² electromagnetic
  cosmicRays: number;      // particles/m²/s
  planetaryRadiation: number; // From radioactive decay
  totalIonizing: number;   // Sv/hour
  shieldingFactor: number; // 0-1 (0 = no shielding, 1 = perfect)
}

export enum RadiationType {
  ELECTROMAGNETIC = 'ELECTROMAGNETIC', // Light, UV, X-ray, gamma
  PARTICLE = 'PARTICLE',              // Protons, electrons, alpha
  COSMIC_RAY = 'COSMIC_RAY',          // High-energy particles
  NEUTRON = 'NEUTRON'                 // Neutron radiation
}

/**
 * Radiation physics calculator
 */
export class RadiationPhysics {
  private static readonly STEFAN_BOLTZMANN = 5.670374419e-8; // W⋅m⁻²⋅K⁻⁴
  private static readonly SOLAR_CONSTANT = 1361; // W/m² at 1 AU
  private static readonly AU = 1.496e11; // meters

  /**
   * Calculate complete radiation environment at a position
   */
  static calculateRadiationEnvironment(
    position: Vector3,
    star: Star,
    planets: Planet[],
    inMagnetosphere: boolean = false
  ): RadiationEnvironment {
    // 1. Solar radiation (electromagnetic)
    const distanceToStar = this.distance(position, star.position);
    const solarRadiation = star.getRadiationAt(distanceToStar);

    // 2. Cosmic rays (galactic and extragalactic)
    // Base rate: ~400 particles/m²/s
    // Reduced by stellar wind and magnetic fields
    let cosmicRays = 400;

    if (distanceToStar < this.AU * 5) {
      // Inside stellar wind bubble
      const shielding = 1 - (distanceToStar / (this.AU * 5));
      cosmicRays *= (1 - shielding * 0.8); // Up to 80% reduction
    }

    if (inMagnetosphere) {
      cosmicRays *= 0.1; // 90% reduction in magnetosphere
    }

    // 3. Planetary radiation (from radioactive decay)
    let planetaryRadiation = 0;
    for (const planet of planets) {
      const distanceToPlanet = this.distance(position, planet.position);
      if (distanceToPlanet < planet.physical.radius * 10) {
        // Simplified model: larger/denser planets = more radiation
        const radiogenicHeat = planet.physical.mass * 1e-17; // W
        planetaryRadiation += radiogenicHeat / (4 * Math.PI * distanceToPlanet * distanceToPlanet);
      }
    }

    // 4. Calculate ionizing radiation dose rate (Sv/hour)
    const uvFraction = this.calculateUVFraction(solarRadiation, star.temperature);
    const uvDose = uvFraction * 1e-6; // Simplified conversion

    const cosmicDose = cosmicRays * 1e-7; // Simplified conversion
    const planetaryDose = planetaryRadiation * 1e-9;

    const totalIonizing = uvDose + cosmicDose + planetaryDose;

    // 5. Shielding from magnetosphere
    const shieldingFactor = inMagnetosphere ? 0.9 : 0;

    return {
      solarRadiation,
      cosmicRays,
      planetaryRadiation,
      totalIonizing,
      shieldingFactor
    };
  }

  /**
   * Calculate radiation in a radiation belt
   */
  static calculateBeltRadiation(
    planet: Planet,
    position: Vector3
  ): number {
    const distance = this.distance(position, planet.position);
    const radius = planet.physical.radius;

    // Van Allen belt analogy
    // Inner belt: 1.5-2.5 planetary radii (high energy protons)
    // Outer belt: 3-6 planetary radii (electrons)

    const radialDistance = distance / radius;

    let radiationLevel = 0;

    // Inner belt
    if (radialDistance >= 1.5 && radialDistance <= 2.5) {
      const peak = 2.0;
      const intensity = 1 - Math.abs(radialDistance - peak) / 0.5;
      radiationLevel += intensity * 100; // Sv/hour at peak
    }

    // Outer belt
    if (radialDistance >= 3 && radialDistance <= 6) {
      const peak = 4.5;
      const intensity = 1 - Math.abs(radialDistance - peak) / 1.5;
      radiationLevel += intensity * 50; // Sv/hour at peak
    }

    // Scale by planetary magnetic field strength (approximated by mass)
    const earthMass = 5.972e24;
    const fieldStrength = Math.pow(planet.physical.mass / earthMass, 0.5);
    radiationLevel *= fieldStrength;

    return radiationLevel;
  }

  /**
   * Calculate radiation from solar storm
   */
  static calculateSolarStormRadiation(
    distanceFromStar: number,
    stormIntensity: number // 1-10
  ): number {
    // Solar storm increases particle radiation dramatically
    const baseFlux = this.SOLAR_CONSTANT / (this.AU * this.AU);
    const stormFlux = baseFlux * (distanceFromStar * distanceFromStar);

    // Proton flux increases by 10-10000x during storm
    const protonFlux = stormFlux * Math.pow(10, stormIntensity);

    // Convert to dose rate (simplified)
    const doseRate = protonFlux * 1e-5; // Sv/hour

    return doseRate;
  }

  /**
   * Calculate shielding effectiveness
   */
  static calculateShielding(
    material: string,
    thickness: number // meters
  ): number {
    // Half-value layer (HVL) for different materials
    const hvlData: Map<string, number> = new Map([
      ['aluminum', 0.05],     // 5cm for gamma rays
      ['lead', 0.01],         // 1cm for gamma rays
      ['water', 0.15],        // 15cm for gamma rays
      ['polyethylene', 0.10], // 10cm for neutrons
      ['concrete', 0.08],     // 8cm for gamma rays
      ['regolith', 0.12]      // 12cm (lunar soil)
    ]);

    const hvl = hvlData.get(material) || 0.1;

    // Attenuation: I = I0 * exp(-μx) ≈ I0 * 0.5^(x/HVL)
    const attenuation = Math.pow(0.5, thickness / hvl);

    // Shielding factor (fraction blocked)
    return 1 - attenuation;
  }

  /**
   * Calculate UV index at position
   */
  static calculateUVIndex(
    star: Star,
    distanceFromStar: number,
    atmosphericDensity: number = 0
  ): number {
    // UV radiation from star
    const totalRadiation = star.getRadiationAt(distanceFromStar);
    const uvFraction = this.calculateUVFraction(totalRadiation, star.temperature);

    // Atmospheric absorption (ozone layer)
    const atmosphericReduction = atmosphericDensity > 0.1 ? 0.9 : 0;
    const surfaceUV = uvFraction * (1 - atmosphericReduction);

    // Convert to UV index (0-11+)
    // UV index = (UV W/m²) * 40
    const uvIndex = surfaceUV * 40;

    return uvIndex;
  }

  /**
   * Calculate thermal radiation from body
   */
  static calculateThermalRadiation(
    body: CelestialBody,
    emissivity: number = 1.0
  ): number {
    // Stefan-Boltzmann law: j = εσT⁴
    const temperature = body instanceof Planet
      ? body.surfaceTemperature
      : body instanceof Star
        ? body.temperature
        : 300; // Default

    const radiantExitance = emissivity * this.STEFAN_BOLTZMANN * Math.pow(temperature, 4);

    return radiantExitance; // W/m²
  }

  /**
   * Calculate albedo effect (reflected radiation)
   */
  static calculateAlbedoRadiation(
    body: CelestialBody,
    star: Star,
    observerPosition: Vector3
  ): number {
    // Radiation from star hitting the body
    const distanceStarToBody = this.distance(star.position, body.position);
    const incomingRadiation = star.getRadiationAt(distanceStarToBody);

    // Reflected radiation (depends on albedo)
    const albedo = body.visual.albedo;
    const reflectedPower = incomingRadiation * albedo * Math.PI * body.physical.radius * body.physical.radius;

    // Radiation at observer position
    const distanceBodyToObserver = this.distance(body.position, observerPosition);
    const receivedRadiation = reflectedPower / (4 * Math.PI * distanceBodyToObserver * distanceBodyToObserver);

    return receivedRadiation; // W/m²
  }

  /**
   * Track accumulated radiation dose
   */
  static accumulateDose(
    currentDose: RadiationDose,
    environment: RadiationEnvironment,
    deltaTime: number // seconds
  ): RadiationDose {
    // Calculate dose received in this time period
    const effectiveDoseRate = environment.totalIonizing * (1 - environment.shieldingFactor);
    const doseIncrement = effectiveDoseRate * (deltaTime / 3600); // Convert seconds to hours

    const newTotal = currentDose.total + doseIncrement;
    const newRate = effectiveDoseRate;

    // Update sources
    const sources = new Map(currentDose.sources);
    sources.set('cosmic', (sources.get('cosmic') || 0) + environment.cosmicRays * (deltaTime / 3600) * 1e-7);
    sources.set('solar', (sources.get('solar') || 0) + environment.solarRadiation * (deltaTime / 3600) * 1e-9);

    return {
      total: newTotal,
      rate: newRate,
      sources
    };
  }

  /**
   * Calculate radiation health effects
   */
  static getHealthEffects(totalDose: number): {
    severity: string;
    effects: string[];
    fatal: boolean;
  } {
    // Dose in Sieverts (Sv)
    if (totalDose < 0.1) {
      return {
        severity: 'None',
        effects: ['No measurable effects'],
        fatal: false
      };
    } else if (totalDose < 0.5) {
      return {
        severity: 'Mild',
        effects: ['Temporary reduction in white blood cell count'],
        fatal: false
      };
    } else if (totalDose < 1.0) {
      return {
        severity: 'Moderate',
        effects: ['Nausea', 'Fatigue', 'Reduced blood cell counts'],
        fatal: false
      };
    } else if (totalDose < 4.0) {
      return {
        severity: 'Severe',
        effects: ['Severe radiation sickness', 'Hair loss', 'Bleeding', '50% mortality without treatment'],
        fatal: false
      };
    } else if (totalDose < 6.0) {
      return {
        severity: 'Acute',
        effects: ['Severe damage to bone marrow', 'GI tract damage', '90% mortality'],
        fatal: true
      };
    } else {
      return {
        severity: 'Fatal',
        effects: ['Central nervous system damage', 'Death within days'],
        fatal: true
      };
    }
  }

  /**
   * Helper: Calculate UV fraction of radiation
   */
  private static calculateUVFraction(totalRadiation: number, starTemp: number): number {
    // Wien's displacement law to find peak wavelength
    const peakWavelength = 2.898e-3 / starTemp; // meters

    // UV is 10nm - 400nm (1e-8 to 4e-7 meters)
    // Hotter stars emit more UV
    let uvFraction: number;

    if (starTemp > 10000) {
      uvFraction = 0.3; // O, B stars
    } else if (starTemp > 7500) {
      uvFraction = 0.2; // A stars
    } else if (starTemp > 6000) {
      uvFraction = 0.1; // F, G stars (Sun)
    } else if (starTemp > 5000) {
      uvFraction = 0.05; // K stars
    } else {
      uvFraction = 0.02; // M stars
    }

    return totalRadiation * uvFraction;
  }

  /**
   * Helper: Distance between two points
   */
  private static distance(p1: Vector3, p2: Vector3): number {
    const dx = p1.x - p2.x;
    const dy = p1.y - p2.y;
    const dz = p1.z - p2.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }
}

/**
 * Radiation dose tracker for game entities
 */
export class RadiationTracker {
  private dose: RadiationDose = {
    total: 0,
    rate: 0,
    sources: new Map()
  };

  public shielding: Map<string, number> = new Map(); // material -> thickness

  getDose(): RadiationDose {
    return { ...this.dose };
  }

  update(
    environment: RadiationEnvironment,
    deltaTime: number
  ): void {
    // Calculate total shielding
    let totalShielding = environment.shieldingFactor;
    for (const [material, thickness] of this.shielding) {
      const materialShielding = RadiationPhysics.calculateShielding(material, thickness);
      totalShielding = Math.max(totalShielding, materialShielding);
    }

    const shieldedEnvironment = {
      ...environment,
      shieldingFactor: totalShielding
    };

    this.dose = RadiationPhysics.accumulateDose(this.dose, shieldedEnvironment, deltaTime);
  }

  addShielding(material: string, thickness: number): void {
    const current = this.shielding.get(material) || 0;
    this.shielding.set(material, current + thickness);
  }

  getHealthStatus(): { severity: string; effects: string[]; fatal: boolean } {
    return RadiationPhysics.getHealthEffects(this.dose.total);
  }

  reset(): void {
    this.dose = {
      total: 0,
      rate: 0,
      sources: new Map()
    };
  }
}
