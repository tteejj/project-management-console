/**
 * ThermalBalance.ts
 * Comprehensive thermal modeling using Stefan-Boltzmann law, albedo, emissivity
 */

import { Vector3, Star, Planet, CelestialBody } from './CelestialBody';

export interface ThermalEnvironment {
  solarHeating: number;      // W/m² from star
  albedoHeating: number;     // W/m² from reflected light
  thermalRadiation: number;  // W/m² from thermal emission
  cosmicBackground: number;  // W/m² from CMB (2.7K)
  netHeatFlux: number;       // W/m² (positive = heating, negative = cooling)
  equilibriumTemp: number;   // K (temperature at thermal equilibrium)
}

export interface SurfaceEnergyBalance {
  solarInput: number;         // W/m²
  albedoReflection: number;   // W/m²
  absorbed: number;           // W/m²
  emitted: number;            // W/m²
  conducted: number;          // W/m² (to subsurface)
  greenhouseEffect: number;   // W/m² (atmospheric re-radiation)
  netBalance: number;         // W/m²
}

/**
 * Thermal physics calculator using real Stefan-Boltzmann law
 */
export class ThermalBalance {
  private static readonly STEFAN_BOLTZMANN = 5.670374419e-8; // W⋅m⁻²⋅K⁻⁴
  private static readonly CMB_TEMPERATURE = 2.725; // K (cosmic microwave background)
  private static readonly AU = 1.496e11; // meters

  /**
   * Calculate complete thermal environment at a position
   */
  static calculateThermalEnvironment(
    position: Vector3,
    star: Star,
    nearbyBodies: CelestialBody[],
    albedo: number = 0.3,
    emissivity: number = 0.9
  ): ThermalEnvironment {
    // 1. Solar heating
    const distanceToStar = this.distance(position, star.position);
    const solarFlux = star.getRadiationAt(distanceToStar);
    const solarHeating = solarFlux * (1 - albedo);

    // 2. Albedo heating from nearby bodies
    let albedoHeating = 0;
    for (const body of nearbyBodies) {
      const distanceToBody = this.distance(position, body.position);
      const bodyAlbedo = body.visual.albedo;

      // Radiation from star hitting the body
      const distanceStarToBody = this.distance(star.position, body.position);
      const bodyIncomingFlux = star.getRadiationAt(distanceStarToBody);

      // Reflected radiation (Lambert's cosine law)
      const bodyReflectedPower = bodyIncomingFlux * bodyAlbedo * Math.PI * body.physical.radius * body.physical.radius;
      const receivedAlbedo = bodyReflectedPower / (4 * Math.PI * distanceToBody * distanceToBody);

      albedoHeating += receivedAlbedo;
    }

    // 3. Thermal radiation from nearby bodies
    let thermalRadiation = 0;
    for (const body of nearbyBodies) {
      const distanceToBody = this.distance(position, body.position);

      // Temperature of body
      let bodyTemp: number;
      if (body instanceof Planet) {
        bodyTemp = body.surfaceTemperature;
      } else if (body instanceof Star) {
        bodyTemp = body.temperature;
      } else {
        bodyTemp = 200; // Default for asteroids, etc.
      }

      // Stefan-Boltzmann radiation: j = εσT⁴
      const bodyEmissivity = body.visual.emissivity;
      const bodyRadiantExitance = bodyEmissivity * this.STEFAN_BOLTZMANN * Math.pow(bodyTemp, 4);

      // Power radiated
      const bodyRadiatedPower = bodyRadiantExitance * 4 * Math.PI * body.physical.radius * body.physical.radius;

      // Received at position
      const receivedThermal = bodyRadiatedPower / (4 * Math.PI * distanceToBody * distanceToBody);

      thermalRadiation += receivedThermal;
    }

    // 4. Cosmic microwave background
    const cosmicBackground = this.STEFAN_BOLTZMANN * Math.pow(this.CMB_TEMPERATURE, 4);

    // 5. Net heat flux
    const absorbed = solarHeating + albedoHeating + thermalRadiation + cosmicBackground;
    const emitted = emissivity * this.STEFAN_BOLTZMANN * Math.pow(300, 4); // Assume 300K for calculation
    const netHeatFlux = absorbed - emitted;

    // 6. Calculate equilibrium temperature
    // At equilibrium: absorbed = emitted
    // εσT⁴ = absorbed
    // T = (absorbed / (εσ))^0.25
    const equilibriumTemp = Math.pow(absorbed / (emissivity * this.STEFAN_BOLTZMANN), 0.25);

    return {
      solarHeating,
      albedoHeating,
      thermalRadiation,
      cosmicBackground,
      netHeatFlux,
      equilibriumTemp
    };
  }

  /**
   * Calculate surface energy balance for a planet
   */
  static calculatePlanetaryEnergyBalance(
    planet: Planet,
    star: Star
  ): SurfaceEnergyBalance {
    const distanceToStar = this.distance(planet.position, star.position);

    // 1. Solar input
    const solarInput = star.getRadiationAt(distanceToStar);

    // 2. Albedo reflection
    const albedo = planet.visual.albedo;
    const albedoReflection = solarInput * albedo;

    // 3. Absorbed solar radiation
    const absorbed = solarInput * (1 - albedo);

    // 4. Emitted thermal radiation (Stefan-Boltzmann)
    const emissivity = planet.visual.emissivity;
    const surfaceTemp = planet.surfaceTemperature;
    const emitted = emissivity * this.STEFAN_BOLTZMANN * Math.pow(surfaceTemp, 4);

    // 5. Subsurface conduction (geothermal + tidal heating)
    let conducted = 0;

    // Geothermal heat flow (depends on planet size/age)
    const earthMass = 5.972e24;
    const massRatio = planet.physical.mass / earthMass;
    const geothermalHeatFlow = 0.09 * Math.pow(massRatio, 0.5); // W/m² (Earth = 0.09)
    conducted += geothermalHeatFlow;

    // Tidal heating (if has massive parent or moons)
    if (planet.parent) {
      const tidalHeating = this.calculateTidalHeating(planet, planet.parent);
      conducted += tidalHeating;
    }

    // 6. Greenhouse effect (atmospheric re-radiation)
    let greenhouseEffect = 0;
    if (planet.physical.atmospherePressure && planet.physical.atmosphereComposition) {
      greenhouseEffect = this.calculateGreenhouseReradiation(
        planet.physical.atmospherePressure,
        planet.physical.atmosphereComposition,
        emitted
      );
    }

    // 7. Net balance
    const netBalance = absorbed + conducted + greenhouseEffect - emitted;

    return {
      solarInput,
      albedoReflection,
      absorbed,
      emitted,
      conducted,
      greenhouseEffect,
      netBalance
    };
  }

  /**
   * Calculate equilibrium temperature for a planet
   */
  static calculateEquilibriumTemperature(
    star: Star,
    orbitalDistance: number,
    albedo: number,
    emissivity: number = 1.0,
    greenhouseFactor: number = 0
  ): number {
    // Flux at orbital distance
    const flux = star.getRadiationAt(orbitalDistance);

    // Absorbed flux
    const absorbed = flux * (1 - albedo);

    // Equilibrium temperature (Stefan-Boltzmann)
    // For a sphere: absorbed * πR² = emitted * 4πR²
    // So: absorbed / 4 = εσT⁴
    const baseTemp = Math.pow(absorbed / (4 * emissivity * this.STEFAN_BOLTZMANN), 0.25);

    // Add greenhouse effect
    const finalTemp = baseTemp + greenhouseFactor;

    return finalTemp;
  }

  /**
   * Calculate tidal heating
   */
  private static calculateTidalHeating(
    body: CelestialBody,
    parent: CelestialBody
  ): number {
    if (!body.orbital) return 0;

    const G = 6.674e-11;
    const M = parent.physical.mass;
    const R = body.physical.radius;
    const a = body.orbital.semiMajorAxis;
    const e = body.orbital.eccentricity;

    // Tidal heating rate (simplified formula)
    // Q̇ ∝ (e²/Q) * (GM²R⁵/a⁶)
    // where Q is the dissipation factor
    const Q_factor = 100; // Assumed quality factor

    const tidalHeating = (e * e / Q_factor) * (G * M * M * Math.pow(R, 5)) / Math.pow(a, 6);

    // Convert to W/m² (distributed over surface)
    const surfaceArea = 4 * Math.PI * R * R;
    const heatFlux = tidalHeating / surfaceArea;

    return heatFlux; // W/m²
  }

  /**
   * Calculate greenhouse re-radiation
   */
  private static calculateGreenhouseReradiation(
    pressure: number,
    composition: Map<string, number>,
    emittedRadiation: number
  ): number {
    // Calculate opacity of atmosphere to infrared
    let opacity = 0;

    // CO2 contribution
    const co2Fraction = composition.get('CO2') || 0;
    opacity += co2Fraction * 0.5;

    // H2O contribution
    const h2oFraction = composition.get('H2O') || 0;
    opacity += h2oFraction * 0.7;

    // CH4 contribution (very effective)
    const ch4Fraction = composition.get('CH4') || 0;
    opacity += ch4Fraction * 2.0;

    // Scale by pressure (thicker atmosphere = more opacity)
    const earthPressure = 101325;
    const pressureScale = Math.log10(pressure / earthPressure + 1);
    opacity *= pressureScale;

    // Clamp opacity
    opacity = Math.min(opacity, 0.95);

    // Re-radiated back to surface
    const reradiated = emittedRadiation * opacity;

    return reradiated;
  }

  /**
   * Calculate day-night temperature variation
   */
  static calculateDiurnalVariation(
    planet: Planet,
    star: Star,
    latitude: number, // radians
    localHour: number // 0-24
  ): number {
    const baseTemp = planet.surfaceTemperature;

    // Solar zenith angle
    const hourAngle = (localHour - 12) * (Math.PI / 12); // radians
    const zenithAngle = Math.acos(
      Math.sin(latitude) * Math.sin(0) + // Assume equinox
      Math.cos(latitude) * Math.cos(0) * Math.cos(hourAngle)
    );

    // Insolation follows cosine law
    const distanceToStar = this.distance(planet.position, star.position);
    const maxInsolation = star.getRadiationAt(distanceToStar);
    const currentInsolation = Math.max(0, maxInsolation * Math.cos(zenithAngle));

    // Temperature variation (simplified)
    // Daytime: higher temp
    // Nighttime: lower temp
    const insolationRatio = currentInsolation / maxInsolation;

    // Atmospheric thermal inertia
    let thermalInertia = 1.0;
    if (planet.physical.atmospherePressure) {
      // Thicker atmosphere = less temperature variation
      thermalInertia = Math.min(3.0, Math.log10(planet.physical.atmospherePressure / 1000 + 1));
    }

    // Temperature variation
    const variation = (insolationRatio - 0.5) * 50 / thermalInertia; // ±25K / thermal inertia

    return baseTemp + variation;
  }

  /**
   * Calculate infrared radiation visible from space
   */
  static calculateInfraredSignature(
    body: CelestialBody,
    observerDistance: number
  ): number {
    let temperature: number;

    if (body instanceof Planet) {
      temperature = body.surfaceTemperature;
    } else if (body instanceof Star) {
      temperature = body.temperature;
    } else {
      temperature = 200; // Default
    }

    // Stefan-Boltzmann radiation
    const emissivity = body.visual.emissivity;
    const radiantExitance = emissivity * this.STEFAN_BOLTZMANN * Math.pow(temperature, 4);

    // Total radiated power
    const totalPower = radiantExitance * 4 * Math.PI * body.physical.radius * body.physical.radius;

    // Flux at observer
    const flux = totalPower / (4 * Math.PI * observerDistance * observerDistance);

    return flux; // W/m²
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
