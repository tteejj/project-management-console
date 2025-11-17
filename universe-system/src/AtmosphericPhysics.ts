/**
 * AtmosphericPhysics.ts
 * Detailed atmospheric modeling with real physics
 */

import { Vector3, Planet } from './CelestialBody';

export interface AtmosphericLayer {
  altitude: number;        // meters
  temperature: number;     // kelvin
  pressure: number;        // pascals
  density: number;         // kg/m³
  composition: Map<string, number>; // gas -> mole fraction
}

export interface AtmosphericProfile {
  surfacePressure: number;
  surfaceTemperature: number;
  scaleHeight: number;
  layers: AtmosphericLayer[];
  hasOzone: boolean;
  hasWeather: boolean;
  greenhouseEffect: number; // kelvin
}

/**
 * Detailed atmospheric physics calculator
 */
export class AtmosphericPhysics {
  private static readonly R_SPECIFIC = 287; // J/(kg·K) - air
  private static readonly GAMMA = 1.4; // ratio of specific heats
  private static readonly G = 6.674e-11;
  private static readonly BOLTZMANN = 1.381e-23;
  private static readonly AVOGADRO = 6.022e23;

  /**
   * Generate complete atmospheric profile for a planet
   */
  static generateAtmosphericProfile(planet: Planet): AtmosphericProfile | null {
    if (!planet.physical.atmospherePressure) return null;

    const surfacePressure = planet.physical.atmospherePressure;
    const surfaceTemp = planet.surfaceTemperature;
    const gravity = planet.physical.surfaceGravity;
    const composition = planet.physical.atmosphereComposition || new Map();

    // Calculate molecular weight
    const molecularWeight = this.calculateMolecularWeight(composition);

    // Calculate scale height: H = RT/Mg
    const scaleHeight = (this.R_SPECIFIC * surfaceTemp) / gravity;

    // Generate atmospheric layers
    const layers: AtmosphericLayer[] = [];
    const altitudes = [0, 5000, 10000, 20000, 50000, 100000, 200000]; // meters

    for (const altitude of altitudes) {
      const layer = this.calculateLayer(
        altitude,
        surfaceTemp,
        surfacePressure,
        scaleHeight,
        gravity,
        composition,
        molecularWeight
      );
      layers.push(layer);
    }

    // Calculate greenhouse effect
    const greenhouseEffect = this.calculateGreenhouseEffect(
      surfacePressure,
      composition,
      surfaceTemp
    );

    // Check for ozone
    const hasOzone = composition.has('O2') && (composition.get('O2')! > 0.15);

    // Weather requires sufficient pressure and volatiles
    const hasWeather = surfacePressure > 1000 &&
                      (composition.has('H2O') || composition.has('CO2'));

    return {
      surfacePressure,
      surfaceTemperature: surfaceTemp,
      scaleHeight,
      layers,
      hasOzone,
      hasWeather,
      greenhouseEffect
    };
  }

  /**
   * Calculate atmospheric properties at specific altitude
   */
  static getAtmosphereAtAltitude(
    planet: Planet,
    altitude: number
  ): AtmosphericLayer | null {
    if (!planet.physical.atmospherePressure) return null;

    const surfacePressure = planet.physical.atmospherePressure;
    const surfaceTemp = planet.surfaceTemperature;
    const gravity = planet.physical.surfaceGravity;
    const composition = planet.physical.atmosphereComposition || new Map();
    const molecularWeight = this.calculateMolecularWeight(composition);

    // Calculate scale height
    const scaleHeight = (this.R_SPECIFIC * surfaceTemp) / gravity;

    return this.calculateLayer(
      altitude,
      surfaceTemp,
      surfacePressure,
      scaleHeight,
      gravity,
      composition,
      molecularWeight
    );
  }

  /**
   * Calculate drag force on object in atmosphere
   */
  static calculateDrag(
    planet: Planet,
    position: Vector3,
    velocity: Vector3,
    dragCoefficient: number,
    crossSectionalArea: number
  ): Vector3 {
    // Get altitude
    const dx = position.x - planet.position.x;
    const dy = position.y - planet.position.y;
    const dz = position.z - planet.position.z;
    const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
    const altitude = distance - planet.physical.radius;

    if (altitude < 0 || altitude > 200000) {
      return { x: 0, y: 0, z: 0 }; // No drag underground or in space
    }

    // Get atmospheric density at altitude
    const layer = this.getAtmosphereAtAltitude(planet, altitude);
    if (!layer) return { x: 0, y: 0, z: 0 };

    const density = layer.density;

    // Calculate velocity magnitude
    const vMag = Math.sqrt(velocity.x ** 2 + velocity.y ** 2 + velocity.z ** 2);
    if (vMag === 0) return { x: 0, y: 0, z: 0 };

    // Drag force: F = 0.5 * ρ * v² * Cd * A
    const dragMagnitude = 0.5 * density * vMag * vMag * dragCoefficient * crossSectionalArea;

    // Direction is opposite to velocity
    const dragForce = {
      x: -(velocity.x / vMag) * dragMagnitude,
      y: -(velocity.y / vMag) * dragMagnitude,
      z: -(velocity.z / vMag) * dragMagnitude
    };

    return dragForce;
  }

  /**
   * Calculate atmospheric heating from friction
   */
  static calculateAtmosphericHeating(
    planet: Planet,
    position: Vector3,
    velocity: Vector3,
    crossSectionalArea: number
  ): number {
    // Get altitude
    const dx = position.x - planet.position.x;
    const dy = position.y - planet.position.y;
    const dz = position.z - planet.position.z;
    const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
    const altitude = distance - planet.physical.radius;

    if (altitude < 0 || altitude > 200000) return 0;

    // Get atmospheric density
    const layer = this.getAtmosphereAtAltitude(planet, altitude);
    if (!layer) return 0;

    const density = layer.density;
    const vMag = Math.sqrt(velocity.x ** 2 + velocity.y ** 2 + velocity.z ** 2);

    // Heating rate: Q = 0.5 * ρ * v³ * A
    // This is the power dissipated as heat (watts)
    const heatingRate = 0.5 * density * Math.pow(vMag, 3) * crossSectionalArea;

    return heatingRate; // watts
  }

  /**
   * Calculate molecular weight of gas mixture
   */
  private static calculateMolecularWeight(composition: Map<string, number>): number {
    const weights: Map<string, number> = new Map([
      ['H2', 2.016],
      ['He', 4.003],
      ['N2', 28.014],
      ['O2', 31.998],
      ['CO2', 44.01],
      ['Ar', 39.948],
      ['H2O', 18.015],
      ['CH4', 16.043],
      ['SO2', 64.066]
    ]);

    let totalWeight = 0;
    let totalFraction = 0;

    for (const [gas, fraction] of composition.entries()) {
      const weight = weights.get(gas) || 29; // Default to ~air
      totalWeight += fraction * weight;
      totalFraction += fraction;
    }

    return totalFraction > 0 ? totalWeight / totalFraction : 29;
  }

  /**
   * Calculate atmospheric layer properties
   */
  private static calculateLayer(
    altitude: number,
    surfaceTemp: number,
    surfacePressure: number,
    scaleHeight: number,
    gravity: number,
    composition: Map<string, number>,
    molecularWeight: number
  ): AtmosphericLayer {
    // Barometric formula: P = P0 * exp(-h/H)
    const pressure = surfacePressure * Math.exp(-altitude / scaleHeight);

    // Temperature lapse rate (simplified)
    // Troposphere: -6.5 K/km
    // Stratosphere: isothermal or warming
    let temperature: number;
    if (altitude < 10000) {
      // Troposphere
      temperature = surfaceTemp - (6.5 * altitude / 1000);
    } else if (altitude < 50000) {
      // Stratosphere (simplified as isothermal)
      temperature = surfaceTemp - 65; // ~-65K from surface
    } else {
      // Upper atmosphere (warming from solar UV)
      temperature = surfaceTemp - 65 + ((altitude - 50000) / 10000) * 20;
    }

    temperature = Math.max(temperature, 50); // Minimum 50K

    // Ideal gas law: ρ = P*M/(R*T)
    const R_universal = 8.314; // J/(mol·K)
    const density = (pressure * molecularWeight) / (R_universal * temperature * 1000);

    return {
      altitude,
      temperature,
      pressure,
      density,
      composition: new Map(composition) // Copy composition
    };
  }

  /**
   * Calculate greenhouse effect
   */
  private static calculateGreenhouseEffect(
    pressure: number,
    composition: Map<string, number>,
    baseTemp: number
  ): number {
    let greenhouseK = 0;

    // CO2 greenhouse effect
    const co2Fraction = composition.get('CO2') || 0;
    const co2Partial = pressure * co2Fraction;
    greenhouseK += 50 * Math.log10(1 + co2Partial / 1000);

    // H2O greenhouse effect
    const h2oFraction = composition.get('H2O') || 0;
    const h2oPartial = pressure * h2oFraction;
    greenhouseK += 30 * Math.log10(1 + h2oPartial / 1000);

    // CH4 greenhouse effect (very potent)
    const ch4Fraction = composition.get('CH4') || 0;
    const ch4Partial = pressure * ch4Fraction;
    greenhouseK += 100 * Math.log10(1 + ch4Partial / 100);

    return greenhouseK;
  }

  /**
   * Calculate wind patterns (simplified)
   */
  static getWindAtAltitude(
    planet: Planet,
    position: Vector3,
    altitude: number
  ): Vector3 {
    // Simplified wind model based on rotation and temperature gradients

    // Get latitude (simplified)
    const dy = position.y - planet.position.y;
    const dx = position.x - planet.position.x;
    const latitude = Math.atan2(dy, dx);

    // Rotation speed at surface
    const rotationSpeed = (2 * Math.PI * planet.physical.radius) / planet.physical.rotationPeriod;

    // Coriolis effect creates wind patterns
    // Trade winds near equator, westerlies at mid-latitudes
    const latitudeFactor = Math.cos(latitude * 2);
    const windSpeed = rotationSpeed * latitudeFactor * 0.1; // 10% of rotation speed

    // Wind direction (perpendicular to radius, varies with latitude)
    const windDirection = {
      x: -Math.sin(latitude),
      y: Math.cos(latitude),
      z: 0
    };

    return {
      x: windDirection.x * windSpeed,
      y: windDirection.y * windSpeed,
      z: windDirection.z * windSpeed
    };
  }

  /**
   * Check if conditions support liquid water
   */
  static hasLiquidWater(planet: Planet): boolean {
    if (!planet.physical.atmospherePressure) return false;

    const temp = planet.surfaceTemperature;
    const pressure = planet.physical.atmospherePressure;

    // Water phase diagram (simplified)
    // Liquid water requires: 273K < T < 373K and P > 611 Pa
    const tempOk = temp > 273 && temp < 373;
    const pressureOk = pressure > 611;

    return tempOk && pressureOk;
  }

  /**
   * Calculate atmospheric optical depth (for visibility)
   */
  static getOpticalDepth(
    planet: Planet,
    altitude: number,
    viewDistance: number
  ): number {
    const layer = this.getAtmosphereAtAltitude(planet, altitude);
    if (!layer) return 0;

    // Optical depth: τ = ρ * σ * L
    // where σ is scattering cross-section, L is path length
    const scatteringCoefficient = 1e-5; // m²/kg (simplified)
    const opticalDepth = layer.density * scatteringCoefficient * viewDistance;

    return opticalDepth;
  }
}
