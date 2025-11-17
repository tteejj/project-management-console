/**
 * Sensor Systems
 *
 * Implements radar, thermal IR, LIDAR, and mass detector physics
 * NO RENDERING - physics only
 */

import { Vector3, VectorMath, G } from './math-utils';
import { World, CelestialBody } from './world';

export enum SensorType {
  RADAR = 'radar',
  THERMAL = 'thermal',
  LIDAR = 'lidar',
  MASS_DETECTOR = 'mass_detector'
}

export enum RadarBand {
  X_BAND = 'X',      // 8-12 GHz (most common)
  KU_BAND = 'Ku',    // 12-18 GHz
  KA_BAND = 'Ka'     // 26-40 GHz
}

export interface SensorContact {
  bodyId: string;
  sensorType: SensorType;
  range: number;              // meters
  bearing: Vector3;           // unit vector to target
  signalStrength: number;     // dBm or arbitrary units
  confidence: number;         // 0-1
  timestamp: number;          // simulation time
}

export interface RadarConfig {
  maxRange: number;           // meters
  band: RadarBand;
  power: number;              // watts
  antennaGain: number;        // dB
  noiseFloor: number;         // dBm
}

export interface ThermalConfig {
  maxRange: number;           // meters
  sensitivity: number;        // minimum detectable temperature difference (K)
  fov: number;                // field of view in degrees
}

export interface LIDARConfig {
  maxRange: number;           // meters
  angularResolution: number;  // degrees
  rangeResolution: number;    // meters
}

export interface MassDetectorConfig {
  sensitivity: number;        // minimum detectable acceleration (m/s²)
  maxRange: number;           // meters
}

/**
 * Radar sensor using radar equation
 * Range equation: Pr = (Pt * Gt * Gr * λ² * σ) / ((4π)³ * R⁴ * L)
 * Simplified for game: Detection range based on RCS and power
 */
export class RadarSensor {
  private config: RadarConfig;
  private wavelength: number;

  constructor(config: RadarConfig) {
    this.config = config;

    // Calculate wavelength from band
    const frequencies = {
      [RadarBand.X_BAND]: 10e9,    // 10 GHz
      [RadarBand.KU_BAND]: 15e9,   // 15 GHz
      [RadarBand.KA_BAND]: 35e9    // 35 GHz
    };

    const frequency = frequencies[config.band];
    this.wavelength = 3e8 / frequency;  // c / f
  }

  scan(observerPos: Vector3, world: World, excludeBody?: CelestialBody): SensorContact[] {
    const contacts: SensorContact[] = [];
    const bodies = world.getAllBodies();

    for (const body of bodies) {
      if (excludeBody && body.id === excludeBody.id) continue;

      const range = VectorMath.distance(observerPos, body.position);

      // Skip if beyond max range
      if (range > this.config.maxRange) continue;

      // Skip if zero range (observer at target position or self)
      if (range < 1) continue;

      const rcs = body.radarCrossSection || 0;

      // Skip if zero RCS (perfect stealth)
      if (rcs <= 0) continue;

      // Radar equation (simplified)
      // Received power: Pr = (Pt * Gt * Gr * λ² * RCS) / ((4π)³ * R⁴)
      // Assuming Gt = Gr (same antenna for transmit/receive)

      const Pt = this.config.power;
      const Gt = Math.pow(10, this.config.antennaGain / 10);  // Convert dB to linear
      const lambda = this.wavelength;

      // Simplified radar equation
      const numerator = Pt * Gt * Gt * lambda * lambda * rcs;
      const denominator = Math.pow(4 * Math.PI, 3) * Math.pow(range, 4);
      const Pr = numerator / denominator;

      // Convert to dBm
      const PrdBm = 10 * Math.log10(Pr * 1000);  // Convert to milliwatts

      // Check if above noise floor
      if (PrdBm < this.config.noiseFloor) continue;

      // Calculate bearing (unit vector to target)
      const bearing = VectorMath.normalize(
        VectorMath.subtract(body.position, observerPos)
      );

      // Confidence based on SNR (signal-to-noise ratio)
      const snr = PrdBm - this.config.noiseFloor;
      const confidence = Math.min(1.0, snr / 20);  // 20dB SNR = perfect confidence

      contacts.push({
        bodyId: body.id,
        sensorType: SensorType.RADAR,
        range,
        bearing,
        signalStrength: PrdBm,
        confidence,
        timestamp: 0
      });
    }

    return contacts;
  }
}

/**
 * Thermal IR sensor
 * Detects infrared radiation from warm objects
 */
export class ThermalSensor {
  private config: ThermalConfig;

  constructor(config: ThermalConfig) {
    this.config = config;
  }

  scan(observerPos: Vector3, world: World, excludeBody?: CelestialBody): SensorContact[] {
    const contacts: SensorContact[] = [];
    const bodies = world.getAllBodies();

    // Background temperature (cosmic microwave background + local environment)
    const backgroundTemp = 2.7 + 250;  // ~253K (cold space + moon surface radiation)

    for (const body of bodies) {
      if (excludeBody && body.id === excludeBody.id) continue;

      const range = VectorMath.distance(observerPos, body.position);

      if (range > this.config.maxRange) continue;
      if (range < 1) continue;

      const thermalSig = body.thermalSignature || backgroundTemp;

      // Temperature difference from background
      const deltaT = Math.abs(thermalSig - backgroundTemp);

      // Can we detect this temperature difference?
      if (deltaT < this.config.sensitivity) continue;

      // Apparent temperature based on solid angle
      // Solid angle = π * r² / d² (for a sphere)
      // Apparent signal strength proportional to solid angle and temperature
      const solidAngle = Math.PI * (body.radius * body.radius) / (range * range);
      const apparentDeltaT = deltaT * solidAngle * 1000;  // Scale factor for detectability

      // Need minimum intensity to detect
      const minDetectable = this.config.sensitivity;
      if (apparentDeltaT < minDetectable) continue;

      // Signal strength proportional to apparent delta-T
      const signalStrength = apparentDeltaT / minDetectable;

      const bearing = VectorMath.normalize(
        VectorMath.subtract(body.position, observerPos)
      );

      const confidence = Math.min(1.0, signalStrength);

      contacts.push({
        bodyId: body.id,
        sensorType: SensorType.THERMAL,
        range,
        bearing,
        signalStrength,
        confidence,
        timestamp: 0
      });
    }

    return contacts;
  }
}

/**
 * LIDAR (Light Detection and Ranging)
 * High-precision ranging using laser pulses
 */
export class LIDARSensor {
  private config: LIDARConfig;

  constructor(config: LIDARConfig) {
    this.config = config;
  }

  scan(observerPos: Vector3, world: World, excludeBody?: CelestialBody): SensorContact[] {
    const contacts: SensorContact[] = [];
    const bodies = world.getAllBodies();

    for (const body of bodies) {
      if (excludeBody && body.id === excludeBody.id) continue;

      const range = VectorMath.distance(observerPos, body.position);

      if (range > this.config.maxRange) continue;
      if (range < 1) continue;

      const bearing = VectorMath.normalize(
        VectorMath.subtract(body.position, observerPos)
      );

      // LIDAR has very high SNR for any detectable target
      const signalStrength = 1.0;
      const confidence = 1.0;

      contacts.push({
        bodyId: body.id,
        sensorType: SensorType.LIDAR,
        range,
        bearing,
        signalStrength,
        confidence,
        timestamp: 0
      });
    }

    return contacts;
  }
}

/**
 * Mass Detector
 * Detects gravitational anomalies from massive objects
 */
export class MassDetector {
  private config: MassDetectorConfig;

  constructor(config: MassDetectorConfig) {
    this.config = config;
  }

  scan(observerPos: Vector3, world: World, excludeBody?: CelestialBody): SensorContact[] {
    const contacts: SensorContact[] = [];
    const bodies = world.getAllBodies();

    for (const body of bodies) {
      if (excludeBody && body.id === excludeBody.id) continue;

      const range = VectorMath.distance(observerPos, body.position);

      if (range > this.config.maxRange) continue;
      if (range < 1) continue;

      // Calculate gravitational acceleration: g = GM/r²
      const gravAccel = (G * body.mass) / (range * range);

      // Check if detectable
      if (gravAccel < this.config.sensitivity) continue;

      const bearing = VectorMath.normalize(
        VectorMath.subtract(body.position, observerPos)
      );

      // Signal strength is ratio of g-force to sensitivity
      const signalStrength = gravAccel / this.config.sensitivity;
      const confidence = Math.min(1.0, signalStrength);

      contacts.push({
        bodyId: body.id,
        sensorType: SensorType.MASS_DETECTOR,
        range,
        bearing,
        signalStrength,
        confidence,
        timestamp: 0
      });
    }

    return contacts;
  }
}

/**
 * Sensor system integration
 */
export interface Sensor {
  scan(observerPos: Vector3, world: World, excludeBody?: CelestialBody): SensorContact[];
}

export class SensorSystem {
  private sensors: Map<string, { sensor: Sensor; active: boolean }> = new Map();

  addSensor(id: string, sensor: Sensor): void {
    this.sensors.set(id, { sensor, active: true });
  }

  removeSensor(id: string): void {
    this.sensors.delete(id);
  }

  setSensorPower(id: string, active: boolean): void {
    const entry = this.sensors.get(id);
    if (entry) {
      entry.active = active;
    }
  }

  isSensorActive(id: string): boolean {
    const entry = this.sensors.get(id);
    return entry ? entry.active : false;
  }

  scanAll(observerPos: Vector3, world: World, excludeBody?: CelestialBody): SensorContact[] {
    const allContacts: SensorContact[] = [];

    for (const [id, entry] of this.sensors.entries()) {
      if (!entry.active) continue;

      const contacts = entry.sensor.scan(observerPos, world, excludeBody);
      allContacts.push(...contacts);
    }

    return allContacts;
  }

  getSensor(id: string): Sensor | undefined {
    const entry = this.sensors.get(id);
    return entry ? entry.sensor : undefined;
  }
}
