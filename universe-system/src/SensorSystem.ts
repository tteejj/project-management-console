/**
 * SensorSystem.ts
 * Realistic sensor and detection with electromagnetic signatures, stealth, and scanning
 */

import { Vector3, CelestialBody, Star, Planet } from './CelestialBody';
import { SpaceStation } from './StationGenerator';
import { NPCShip } from './NPCShipAI';

export interface SensorSuite {
  radar: RadarSensor;
  infrared: InfraredSensor;
  optical: OpticalSensor;
  gravitic: GraviticSensor;
  neutrino: NeutrinoSensor;
  powerConsumption: number;  // watts
  effectiveRange: number;    // meters (best sensor)
}

export interface RadarSensor {
  enabled: boolean;
  power: number;             // watts
  frequency: number;         // Hz
  range: number;             // meters
  resolution: number;        // meters (minimum detectable size)
  beamWidth: number;         // radians
}

export interface InfraredSensor {
  enabled: boolean;
  sensitivity: number;       // K (minimum temperature difference)
  range: number;             // meters
  wavelength: number;        // micrometers
  cooled: boolean;           // Cooled sensors more sensitive
}

export interface OpticalSensor {
  enabled: boolean;
  aperture: number;          // meters
  magnification: number;
  range: number;             // meters (for visual detection)
  spectralRange: [number, number]; // nm (wavelength range)
}

export interface GraviticSensor {
  enabled: boolean;
  sensitivity: number;       // kg (minimum mass detectable)
  range: number;             // meters
  resolution: number;        // seconds (update rate)
}

export interface NeutrinoSensor {
  enabled: boolean;
  sensitivity: number;
  range: number;
  detectorMass: number;      // kg (larger = more sensitive)
}

export interface DetectedObject {
  id: string;
  type: 'SHIP' | 'STATION' | 'PLANET' | 'STAR' | 'ASTEROID' | 'DEBRIS' | 'UNKNOWN';
  position: Vector3;
  velocity?: Vector3;
  distance: number;
  bearing: { azimuth: number; elevation: number };
  signalStrength: number;    // 0-1
  confidence: number;        // 0-1 (how sure we are of the classification)
  detectedBy: ('RADAR' | 'INFRARED' | 'OPTICAL' | 'GRAVITIC' | 'NEUTRINO')[];
  signature: Signature;
  lastUpdate: number;
}

export interface Signature {
  thermal: number;           // K (infrared signature)
  radar: number;             // m² (radar cross-section)
  optical: number;           // m² (visible cross-section)
  mass: number;              // kg (gravitic signature)
  radiation: number;         // W (total electromagnetic emission)
  neutrino: number;          // particles/s (from reactors)
}

export interface ScanResult {
  target: DetectedObject;
  detailedInfo?: {
    classification: string;
    mass?: number;
    composition?: Map<string, number>;
    temperature?: number;
    atmosphere?: boolean;
    lifeSigns?: boolean;
    technology?: number;      // Tech level 0-10
    threat?: number;          // 0-1
  };
  scanProgress: number;      // 0-1
  scanTime: number;          // seconds remaining
}

/**
 * Sensor and Detection System
 */
export class SensorSystem {
  private sensors: SensorSuite;
  private detectedObjects: Map<string, DetectedObject> = new Map();
  private activeScan: ScanResult | null = null;

  constructor(sensors?: Partial<SensorSuite>) {
    this.sensors = {
      radar: {
        enabled: true,
        power: 10000, // 10 kW
        frequency: 10e9, // 10 GHz (X-band)
        range: 1000000, // 1000 km
        resolution: 1, // 1 meter
        beamWidth: 0.01 // ~0.5 degrees
      },
      infrared: {
        enabled: true,
        sensitivity: 0.1, // 0.1 K
        range: 500000, // 500 km
        wavelength: 10, // 10 μm (thermal IR)
        cooled: true
      },
      optical: {
        enabled: true,
        aperture: 0.5, // 0.5 meter telescope
        magnification: 100,
        range: 10000000, // 10,000 km (visual)
        spectralRange: [400, 700] // Visible light
      },
      gravitic: {
        enabled: false, // Advanced tech
        sensitivity: 1000, // 1 ton
        range: 100000, // 100 km
        resolution: 1 // 1 Hz update
      },
      neutrino: {
        enabled: false, // Very advanced
        sensitivity: 1e12, // Minimum flux
        range: 1e9, // 1 million km
        detectorMass: 1000 // 1 ton detector
      },
      powerConsumption: 15000, // 15 kW total
      effectiveRange: 1000000,
      ...sensors
    };
  }

  /**
   * Update sensor system and scan for objects
   */
  update(
    observerPosition: Vector3,
    observerVelocity: Vector3,
    celestialBodies: CelestialBody[],
    stations: SpaceStation[],
    ships: NPCShip[],
    deltaTime: number
  ): void {
    // Clear old detections
    this.detectedObjects.clear();

    // Scan celestial bodies
    for (const body of celestialBodies) {
      const detection = this.detectCelestialBody(observerPosition, body);
      if (detection) {
        this.detectedObjects.set(detection.id, detection);
      }
    }

    // Scan stations
    for (const station of stations) {
      const detection = this.detectStation(observerPosition, station);
      if (detection) {
        this.detectedObjects.set(detection.id, detection);
      }
    }

    // Scan ships
    for (const ship of ships) {
      const detection = this.detectShip(observerPosition, ship);
      if (detection) {
        this.detectedObjects.set(detection.id, detection);
      }
    }

    // Update active scan
    if (this.activeScan) {
      this.activeScan.scanTime -= deltaTime;
      this.activeScan.scanProgress = Math.min(1, 1 - this.activeScan.scanTime / 60);

      if (this.activeScan.scanTime <= 0) {
        // Scan complete
        this.completeScan();
      }
    }
  }

  /**
   * Detect celestial body
   */
  private detectCelestialBody(observerPos: Vector3, body: CelestialBody): DetectedObject | null {
    const distance = this.distance(observerPos, body.position);

    // Celestial bodies are easy to detect
    let type: DetectedObject['type'] = 'UNKNOWN';
    if (body instanceof Star) type = 'STAR';
    else if (body instanceof Planet) type = 'PLANET';
    else type = 'ASTEROID';

    const signature = this.calculateCelestialSignature(body);
    const detectedBy: DetectedObject['detectedBy'] = [];

    // Check each sensor
    if (this.sensors.optical.enabled && distance < this.sensors.optical.range * 100) {
      detectedBy.push('OPTICAL'); // Stars and planets visible from far away
    }

    if (this.sensors.infrared.enabled && signature.thermal > 0) {
      const thermalRange = this.calculateThermalRange(signature.thermal);
      if (distance < thermalRange) {
        detectedBy.push('INFRARED');
      }
    }

    if (this.sensors.gravitic.enabled && distance < this.sensors.gravitic.range) {
      if (body.physical.mass > this.sensors.gravitic.sensitivity) {
        detectedBy.push('GRAVITIC');
      }
    }

    if (detectedBy.length === 0) return null;

    const bearing = this.calculateBearing(observerPos, body.position);

    return {
      id: body.id,
      type,
      position: body.position,
      velocity: body.velocity,
      distance,
      bearing,
      signalStrength: Math.min(1, this.sensors.effectiveRange / distance),
      confidence: 1.0, // Celestial bodies are obvious
      detectedBy,
      signature,
      lastUpdate: Date.now()
    };
  }

  /**
   * Detect space station
   */
  private detectStation(observerPos: Vector3, station: SpaceStation): DetectedObject | null {
    const distance = this.distance(observerPos, station.position);

    const signature: Signature = {
      thermal: 300, // K (station heating)
      radar: 10000, // Large radar cross-section
      optical: 1000, // Reflective surfaces
      mass: station.population * 100, // Rough estimate
      radiation: station.population * 1000, // Communications, power
      neutrino: 0
    };

    const detectedBy: DetectedObject['detectedBy'] = [];

    // Radar detection
    if (this.sensors.radar.enabled) {
      const radarRange = this.calculateRadarRange(signature.radar);
      if (distance < radarRange) {
        detectedBy.push('RADAR');
      }
    }

    // Infrared detection
    if (this.sensors.infrared.enabled) {
      const thermalRange = this.calculateThermalRange(signature.thermal);
      if (distance < thermalRange) {
        detectedBy.push('INFRARED');
      }
    }

    // Optical detection
    if (this.sensors.optical.enabled && distance < this.sensors.optical.range) {
      detectedBy.push('OPTICAL');
    }

    if (detectedBy.length === 0) return null;

    const bearing = this.calculateBearing(observerPos, station.position);

    return {
      id: station.id,
      type: 'STATION',
      position: station.position,
      distance,
      bearing,
      signalStrength: Math.min(1, this.sensors.effectiveRange / distance),
      confidence: 0.9,
      detectedBy,
      signature,
      lastUpdate: Date.now()
    };
  }

  /**
   * Detect ship
   */
  private detectShip(observerPos: Vector3, ship: NPCShip): DetectedObject | null {
    const distance = this.distance(observerPos, ship.position);

    // Calculate ship signature (smaller than stations)
    const signature: Signature = {
      thermal: 400, // K (engine heat)
      radar: 100, // m² (small cross-section)
      optical: 50, // m²
      mass: 100000, // kg (rough estimate)
      radiation: 1000, // W (comms, sensors)
      neutrino: ship.fuel > 0 ? 1e10 : 0 // Active reactor
    };

    const detectedBy: DetectedObject['detectedBy'] = [];

    // Radar
    if (this.sensors.radar.enabled) {
      const radarRange = this.calculateRadarRange(signature.radar);
      if (distance < radarRange) {
        detectedBy.push('RADAR');
      }
    }

    // Infrared (ships are hot)
    if (this.sensors.infrared.enabled) {
      const thermalRange = this.calculateThermalRange(signature.thermal);
      if (distance < thermalRange) {
        detectedBy.push('INFRARED');
      }
    }

    // Optical (harder at distance)
    if (this.sensors.optical.enabled && distance < this.sensors.optical.range / 10) {
      detectedBy.push('OPTICAL');
    }

    if (detectedBy.length === 0) return null;

    const bearing = this.calculateBearing(observerPos, ship.position);

    return {
      id: ship.id,
      type: 'SHIP',
      position: ship.position,
      velocity: ship.velocity,
      distance,
      bearing,
      signalStrength: Math.min(1, this.sensors.effectiveRange / distance),
      confidence: 0.7, // Less certain about ships
      detectedBy,
      signature,
      lastUpdate: Date.now()
    };
  }

  /**
   * Calculate signature for celestial body
   */
  private calculateCelestialSignature(body: CelestialBody): Signature {
    let temp = 300; // Default

    if (body instanceof Star) {
      temp = body.temperature;
    } else if (body instanceof Planet) {
      temp = body.surfaceTemperature;
    }

    return {
      thermal: temp,
      radar: Math.PI * body.physical.radius * body.physical.radius, // Cross-section
      optical: Math.PI * body.physical.radius * body.physical.radius,
      mass: body.physical.mass,
      radiation: body instanceof Star ? 1e26 : 0,
      neutrino: 0
    };
  }

  /**
   * Calculate radar detection range
   */
  private calculateRadarRange(radarCrossSection: number): number {
    // Radar equation: R = ((P*G²*λ²*σ) / ((4π)³*P_min))^0.25
    // Simplified: range proportional to RCS^0.25
    const baseRange = this.sensors.radar.range;
    return baseRange * Math.pow(radarCrossSection / 100, 0.25);
  }

  /**
   * Calculate thermal detection range
   */
  private calculateThermalRange(temperature: number): number {
    // Stefan-Boltzmann: flux = σT⁴
    // Range inversely proportional to sqrt(flux)
    const STEFAN_BOLTZMANN = 5.670374419e-8;
    const flux = STEFAN_BOLTZMANN * Math.pow(temperature, 4);
    const baseRange = this.sensors.infrared.range;

    // Objects hotter than 300K detectable farther
    const tempFactor = Math.pow(temperature / 300, 2);
    return baseRange * tempFactor;
  }

  /**
   * Calculate bearing to target
   */
  private calculateBearing(from: Vector3, to: Vector3): { azimuth: number; elevation: number } {
    const dx = to.x - from.x;
    const dy = to.y - from.y;
    const dz = to.z - from.z;

    const azimuth = Math.atan2(dy, dx);
    const horizontalDist = Math.sqrt(dx * dx + dy * dy);
    const elevation = Math.atan2(dz, horizontalDist);

    return { azimuth, elevation };
  }

  /**
   * Start detailed scan of target
   */
  startScan(targetId: string): boolean {
    const target = this.detectedObjects.get(targetId);
    if (!target) return false;

    // Can only scan one target at a time
    if (this.activeScan) return false;

    this.activeScan = {
      target,
      scanProgress: 0,
      scanTime: 60 // 60 seconds for detailed scan
    };

    return true;
  }

  /**
   * Complete active scan
   */
  private completeScan(): void {
    if (!this.activeScan) return;

    // Generate detailed info based on target type
    const target = this.activeScan.target;

    if (target.type === 'PLANET') {
      this.activeScan.detailedInfo = {
        classification: 'Terrestrial Planet',
        mass: target.signature.mass,
        composition: new Map([
          ['rock', 0.7],
          ['iron', 0.3]
        ]),
        temperature: target.signature.thermal,
        atmosphere: target.signature.thermal > 100 && target.signature.thermal < 400,
        lifeSigns: Math.random() > 0.95, // 5% chance
        technology: 0
      };
    } else if (target.type === 'SHIP') {
      this.activeScan.detailedInfo = {
        classification: 'Spacecraft',
        mass: target.signature.mass,
        technology: 5 + Math.floor(Math.random() * 5),
        threat: Math.random()
      };
    } else if (target.type === 'STATION') {
      this.activeScan.detailedInfo = {
        classification: 'Space Station',
        mass: target.signature.mass,
        technology: 6,
        threat: 0.1
      };
    }
  }

  /**
   * Get all detected objects
   */
  getDetectedObjects(): DetectedObject[] {
    return Array.from(this.detectedObjects.values());
  }

  /**
   * Get objects by type
   */
  getObjectsByType(type: DetectedObject['type']): DetectedObject[] {
    return Array.from(this.detectedObjects.values()).filter(obj => obj.type === type);
  }

  /**
   * Get nearest object
   */
  getNearestObject(): DetectedObject | null {
    let nearest: DetectedObject | null = null;
    let minDistance = Infinity;

    for (const obj of this.detectedObjects.values()) {
      if (obj.distance < minDistance) {
        minDistance = obj.distance;
        nearest = obj;
      }
    }

    return nearest;
  }

  /**
   * Get active scan
   */
  getActiveScan(): ScanResult | null {
    return this.activeScan;
  }

  /**
   * Cancel active scan
   */
  cancelScan(): void {
    this.activeScan = null;
  }

  /**
   * Distance between points
   */
  private distance(p1: Vector3, p2: Vector3): number {
    const dx = p1.x - p2.x;
    const dy = p1.y - p2.y;
    const dz = p1.z - p2.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /**
   * Get sensor power consumption
   */
  getPowerConsumption(): number {
    let power = 0;
    if (this.sensors.radar.enabled) power += this.sensors.radar.power;
    if (this.sensors.infrared.enabled) power += 1000; // 1 kW
    if (this.sensors.optical.enabled) power += 500; // 0.5 kW
    if (this.sensors.gravitic.enabled) power += 5000; // 5 kW
    if (this.sensors.neutrino.enabled) power += 10000; // 10 kW

    return power;
  }

  /**
   * Toggle sensor
   */
  toggleSensor(sensorType: 'RADAR' | 'INFRARED' | 'OPTICAL' | 'GRAVITIC' | 'NEUTRINO', enabled: boolean): void {
    switch (sensorType) {
      case 'RADAR': this.sensors.radar.enabled = enabled; break;
      case 'INFRARED': this.sensors.infrared.enabled = enabled; break;
      case 'OPTICAL': this.sensors.optical.enabled = enabled; break;
      case 'GRAVITIC': this.sensors.gravitic.enabled = enabled; break;
      case 'NEUTRINO': this.sensors.neutrino.enabled = enabled; break;
    }
  }
}
