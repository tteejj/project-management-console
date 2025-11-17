/**
 * GeologicalActivity.ts
 * Planetary geology with tectonics, volcanoes, earthquakes, and thermal vents
 */

import { Planet } from './CelestialBody';

export interface TectonicPlate {
  id: string;
  boundary: { latitude: number; longitude: number }[];
  velocity: { x: number; y: number }; // cm/year
  type: PlateType;
  thickness: number;         // km
  density: number;           // kg/m³
  age: number;               // million years
}

export type PlateType = 'CONTINENTAL' | 'OCEANIC' | 'MIXED';

export interface PlateBoundary {
  plate1: string;
  plate2: string;
  type: BoundaryType;
  locations: { latitude: number; longitude: number }[];
  activity: number;          // 0-1
}

export type BoundaryType =
  | 'DIVERGENT'              // Plates moving apart
  | 'CONVERGENT'             // Plates colliding
  | 'TRANSFORM';             // Plates sliding past

export interface Volcano {
  id: string;
  name: string;
  position: { latitude: number; longitude: number };
  elevation: number;         // meters
  type: VolcanoType;
  activity: VolcanoActivity;
  lastEruption: number;      // timestamp
  vei: number;               // Volcanic Explosivity Index (0-8)
  magmaComposition: MagmaType;
  craterRadius: number;      // meters
}

export type VolcanoType = 'SHIELD' | 'COMPOSITE' | 'CINDER_CONE' | 'CALDERA' | 'CRYOVOLCANO';
export type VolcanoActivity = 'DORMANT' | 'ACTIVE' | 'ERUPTING';
export type MagmaType = 'BASALTIC' | 'ANDESITIC' | 'RHYOLITIC' | 'WATER_ICE' | 'AMMONIA_METHANE';

export interface Eruption {
  volcanoId: string;
  startTime: number;
  duration: number;          // seconds
  intensity: number;         // 0-1
  ashColumn: number;         // meters height
  lavaFlow: number;          // km radius
  pyroclasticFlow: number;   // km radius
  atmosphericImpact: number; // 0-1 (global cooling/warming)
}

export interface Earthquake {
  id: string;
  epicenter: { latitude: number; longitude: number };
  depth: number;             // km
  magnitude: number;         // Richter scale
  timestamp: number;
  duration: number;          // seconds
  aftershocks: number;
  causedBy: 'TECTONIC' | 'VOLCANIC' | 'COLLAPSE' | 'IMPACT';
}

export interface HotSpot {
  id: string;
  position: { latitude: number; longitude: number };
  depth: number;             // km
  temperature: number;       // K
  heatFlow: number;          // W/m²
  plume: boolean;            // Is there a mantle plume?
  volcanoes: string[];       // Volcano IDs created by this hot spot
}

export interface GeothermalVent {
  id: string;
  position: { latitude: number; longitude: number };
  depth: number;             // meters (ocean depth or underground)
  temperature: number;       // K
  flowRate: number;          // kg/s
  minerals: string[];
  chemicalEnergy: number;    // kJ/mol (for chemosynthesis)
}

/**
 * Geological Activity Simulator
 */
export class GeologicalActivity {
  private planet: Planet;
  private tectonicPlates: Map<string, TectonicPlate> = new Map();
  private boundaries: PlateBoundary[] = [];
  private volcanoes: Map<string, Volcano> = new Map();
  private activeEruptions: Map<string, Eruption> = new Map();
  private earthquakes: Earthquake[] = [];
  private hotSpots: Map<string, HotSpot> = new Map();
  private geothermalVents: Map<string, GeothermalVent> = new Map();
  private nextEarthquakeId = 0;

  constructor(planet: Planet) {
    this.planet = planet;
    this.initializeGeology();
  }

  /**
   * Initialize geological features
   */
  private initializeGeology(): void {
    // Calculate geological activity level
    const activity = this.calculateGeologicalActivity();

    if (activity > 0.1) {
      this.generateTectonicPlates();
      this.generatePlateBoundaries();
      this.generateVolcanoes();
      this.generateHotSpots();
    }

    if (this.planet.physical.waterCoverage && this.planet.physical.waterCoverage > 0.1) {
      this.generateGeothermalVents();
    }
  }

  /**
   * Calculate geological activity level
   */
  private calculateGeologicalActivity(): number {
    const earthMass = 5.972e24;
    const massRatio = this.planet.physical.mass / earthMass;

    // Larger planets have more internal heat
    let activity = Math.pow(massRatio, 0.7);

    // Young planets are more active
    const age = 4.5e9; // Assume similar age to Solar System
    const ageFactor = Math.exp(-age / 1e10); // Decay over time
    activity *= (1 + ageFactor);

    // Tidal heating from moons/parent
    if (this.planet.moons && this.planet.moons.length > 0) {
      activity *= 1.5; // Moons cause tidal heating
    }

    return Math.min(1, activity);
  }

  /**
   * Generate tectonic plates
   */
  private generateTectonicPlates(): void {
    // Number of plates based on planet size
    const earthRadius = 6371000;
    const sizeRatio = this.planet.physical.radius / earthRadius;
    const numPlates = Math.floor(4 + sizeRatio * 8); // 4-12 plates

    for (let i = 0; i < numPlates; i++) {
      const plate: TectonicPlate = {
        id: `plate_${i}`,
        boundary: this.generatePlateBoundary(),
        velocity: {
          x: (Math.random() - 0.5) * 10, // cm/year
          y: (Math.random() - 0.5) * 10
        },
        type: Math.random() > 0.5 ? 'OCEANIC' : 'CONTINENTAL',
        thickness: Math.random() > 0.5 ? 35 : 7, // Continental vs oceanic
        density: Math.random() > 0.5 ? 2700 : 2900,
        age: Math.random() * 200 // 0-200 million years
      };

      this.tectonicPlates.set(plate.id, plate);
    }
  }

  /**
   * Generate plate boundary points
   */
  private generatePlateBoundary(): { latitude: number; longitude: number }[] {
    const points: { latitude: number; longitude: number }[] = [];
    const numPoints = 20;

    for (let i = 0; i < numPoints; i++) {
      points.push({
        latitude: (Math.random() - 0.5) * Math.PI,
        longitude: (Math.random() - 0.5) * 2 * Math.PI
      });
    }

    return points;
  }

  /**
   * Generate plate boundaries
   */
  private generatePlateBoundaries(): void {
    const plates = Array.from(this.tectonicPlates.values());

    for (let i = 0; i < plates.length; i++) {
      for (let j = i + 1; j < plates.length; j++) {
        // Check if plates are adjacent (simplified)
        if (Math.random() < 0.3) { // 30% chance of adjacency
          const type = this.determineBoundaryType(plates[i], plates[j]);

          this.boundaries.push({
            plate1: plates[i].id,
            plate2: plates[j].id,
            type,
            locations: [], // Would calculate intersection
            activity: Math.random() * 0.8 + 0.2
          });
        }
      }
    }
  }

  /**
   * Determine boundary type from plate velocities
   */
  private determineBoundaryType(plate1: TectonicPlate, plate2: TectonicPlate): BoundaryType {
    const relVelX = plate1.velocity.x - plate2.velocity.x;
    const relVelY = plate1.velocity.y - plate2.velocity.y;
    const relSpeed = Math.sqrt(relVelX * relVelX + relVelY * relVelY);

    // Simplified classification
    const dotProduct = plate1.velocity.x * plate2.velocity.x + plate1.velocity.y * plate2.velocity.y;

    if (dotProduct < -5) {
      return 'CONVERGENT'; // Moving toward each other
    } else if (dotProduct > 5) {
      return 'DIVERGENT'; // Moving apart
    } else {
      return 'TRANSFORM'; // Sliding past
    }
  }

  /**
   * Generate volcanoes
   */
  private generateVolcanoes(): void {
    // Volcanoes at convergent boundaries
    for (const boundary of this.boundaries) {
      if (boundary.type === 'CONVERGENT') {
        const numVolcanoes = Math.floor(boundary.activity * 10);

        for (let i = 0; i < numVolcanoes; i++) {
          this.createVolcano(
            Math.random() * Math.PI - Math.PI / 2,
            Math.random() * 2 * Math.PI - Math.PI,
            'COMPOSITE'
          );
        }
      }
    }

    // Shield volcanoes at hot spots (generated later)
    // Cryovolcanoes on icy worlds
    if (this.planet.surfaceTemperature < 150) {
      for (let i = 0; i < 3; i++) {
        this.createVolcano(
          Math.random() * Math.PI - Math.PI / 2,
          Math.random() * 2 * Math.PI - Math.PI,
          'CRYOVOLCANO'
        );
      }
    }
  }

  /**
   * Create a volcano
   */
  private createVolcano(latitude: number, longitude: number, type: VolcanoType): Volcano {
    const id = `volcano_${this.volcanoes.size}`;

    const volcano: Volcano = {
      id,
      name: `Volcano ${this.volcanoes.size + 1}`,
      position: { latitude, longitude },
      elevation: type === 'SHIELD' ? 5000 : 3000,
      type,
      activity: Math.random() > 0.7 ? 'ACTIVE' : 'DORMANT',
      lastEruption: Date.now() - Math.random() * 86400000 * 365 * 100, // Last 100 years
      vei: Math.floor(Math.random() * 5) + 2, // VEI 2-6
      magmaComposition: type === 'CRYOVOLCANO' ? 'WATER_ICE' : 'BASALTIC',
      craterRadius: 500 + Math.random() * 2000
    };

    this.volcanoes.set(id, volcano);
    return volcano;
  }

  /**
   * Generate hot spots
   */
  private generateHotSpots(): void {
    const numHotSpots = Math.floor(Math.random() * 5) + 2; // 2-6 hot spots

    for (let i = 0; i < numHotSpots; i++) {
      const latitude = Math.random() * Math.PI - Math.PI / 2;
      const longitude = Math.random() * 2 * Math.PI - Math.PI;

      const hotSpot: HotSpot = {
        id: `hotspot_${i}`,
        position: { latitude, longitude },
        depth: 100 + Math.random() * 200, // 100-300 km deep
        temperature: 1500 + Math.random() * 500, // K
        heatFlow: 0.1 + Math.random() * 0.3, // W/m²
        plume: Math.random() > 0.5,
        volcanoes: []
      };

      // Create shield volcanoes at hot spot
      const volcano = this.createVolcano(latitude, longitude, 'SHIELD');
      hotSpot.volcanoes.push(volcano.id);

      this.hotSpots.set(hotSpot.id, hotSpot);
    }
  }

  /**
   * Generate geothermal vents
   */
  private generateGeothermalVents(): void {
    // Vents at divergent boundaries (mid-ocean ridges)
    for (const boundary of this.boundaries) {
      if (boundary.type === 'DIVERGENT') {
        const numVents = Math.floor(boundary.activity * 20);

        for (let i = 0; i < numVents; i++) {
          const vent: GeothermalVent = {
            id: `vent_${this.geothermalVents.size}`,
            position: {
              latitude: Math.random() * Math.PI - Math.PI / 2,
              longitude: Math.random() * 2 * Math.PI - Math.PI
            },
            depth: 2000 + Math.random() * 2000, // 2-4 km deep
            temperature: 400 + Math.random() * 200, // K
            flowRate: 1 + Math.random() * 10, // kg/s
            minerals: ['iron', 'sulfur', 'manganese', 'zinc'],
            chemicalEnergy: 100 + Math.random() * 400 // kJ/mol
          };

          this.geothermalVents.set(vent.id, vent);
        }
      }
    }
  }

  /**
   * Update geological activity
   */
  update(deltaTime: number): void {
    // Update plate tectonics (very slow)
    this.updatePlates(deltaTime);

    // Update volcanic activity
    this.updateVolcanoes(deltaTime);

    // Update active eruptions
    for (const [id, eruption] of this.activeEruptions) {
      eruption.duration -= deltaTime;
      if (eruption.duration <= 0) {
        this.activeEruptions.delete(id);

        // Update volcano state
        const volcano = this.volcanoes.get(id);
        if (volcano) {
          volcano.activity = 'ACTIVE';
          volcano.lastEruption = Date.now();
        }
      }
    }

    // Random earthquakes
    if (Math.random() < deltaTime / 86400) { // Average one per day
      this.generateEarthquake();
    }

    // Clean old earthquakes
    const cutoff = Date.now() - 86400000; // Keep 1 day
    this.earthquakes = this.earthquakes.filter(eq => eq.timestamp > cutoff);
  }

  /**
   * Update tectonic plates
   */
  private updatePlates(deltaTime: number): void {
    // Plates move very slowly
    const yearFraction = deltaTime / (365.25 * 86400);

    for (const plate of this.tectonicPlates.values()) {
      // Update positions (would need to actually move plate boundaries)
      plate.age += yearFraction * 1e6; // Convert to million years
    }
  }

  /**
   * Update volcanic activity
   */
  private updateVolcanoes(deltaTime: number): void {
    for (const volcano of this.volcanoes.values()) {
      if (volcano.activity === 'ACTIVE' && !this.activeEruptions.has(volcano.id)) {
        // Chance to erupt
        const timeSinceEruption = Date.now() - volcano.lastEruption;
        const eruptionProbability = (deltaTime / 86400) * (volcano.vei / 100); // Higher VEI = more frequent

        if (Math.random() < eruptionProbability && timeSinceEruption > 86400000) { // At least 1 day
          this.triggerEruption(volcano);
        }
      }
    }
  }

  /**
   * Trigger volcanic eruption
   */
  private triggerEruption(volcano: Volcano): void {
    const duration = 3600 * (1 + Math.random() * volcano.vei); // Hours based on VEI
    const intensity = 0.5 + Math.random() * 0.5;

    const eruption: Eruption = {
      volcanoId: volcano.id,
      startTime: Date.now(),
      duration,
      intensity,
      ashColumn: Math.pow(10, volcano.vei) * 100, // Meters
      lavaFlow: volcano.vei * 2, // km
      pyroclasticFlow: volcano.vei * 5, // km
      atmosphericImpact: volcano.vei > 5 ? 0.1 * (volcano.vei - 5) : 0
    };

    this.activeEruptions.set(volcano.id, eruption);
    volcano.activity = 'ERUPTING';

    // Trigger earthquakes
    for (let i = 0; i < volcano.vei; i++) {
      this.generateEarthquake(volcano.position.latitude, volcano.position.longitude, 'VOLCANIC');
    }
  }

  /**
   * Generate earthquake
   */
  private generateEarthquake(
    latitude?: number,
    longitude?: number,
    cause: Earthquake['causedBy'] = 'TECTONIC'
  ): Earthquake {
    // Random location if not specified
    if (latitude === undefined) {
      latitude = Math.random() * Math.PI - Math.PI / 2;
      longitude = Math.random() * 2 * Math.PI - Math.PI;
    }

    // Magnitude based on cause
    let magnitude: number;
    if (cause === 'VOLCANIC') {
      magnitude = 2 + Math.random() * 4; // 2-6
    } else {
      magnitude = Math.random() * 9; // 0-9
    }

    const earthquake: Earthquake = {
      id: `eq_${this.nextEarthquakeId++}`,
      epicenter: { latitude, longitude },
      depth: 5 + Math.random() * 50, // 5-55 km
      magnitude,
      timestamp: Date.now(),
      duration: 10 + magnitude * 10, // seconds
      aftershocks: Math.floor(magnitude),
      causedBy: cause
    };

    this.earthquakes.push(earthquake);

    // Generate aftershocks
    for (let i = 0; i < earthquake.aftershocks; i++) {
      setTimeout(() => {
        const aftershock: Earthquake = {
          ...earthquake,
          id: `eq_${this.nextEarthquakeId++}`,
          magnitude: earthquake.magnitude - 1 - Math.random() * 2,
          timestamp: Date.now(),
          aftershocks: 0
        };
        this.earthquakes.push(aftershock);
      }, Math.random() * 3600000); // Within 1 hour
    }

    return earthquake;
  }

  /**
   * Get geological activity at location
   */
  getActivityAt(latitude: number, longitude: number): {
    seismicRisk: number;
    volcanicRisk: number;
    nearestVolcano: Volcano | null;
    nearestVent: GeothermalVent | null;
    recentQuakes: Earthquake[];
  } {
    let seismicRisk = 0;
    let volcanicRisk = 0;
    let nearestVolcano: Volcano | null = null;
    let nearestVent: GeothermalVent | null = null;
    let minVolcanoDist = Infinity;
    let minVentDist = Infinity;

    // Check volcanoes
    for (const volcano of this.volcanoes.values()) {
      const dist = this.angularDistance(
        latitude, longitude,
        volcano.position.latitude, volcano.position.longitude
      );

      if (dist < minVolcanoDist) {
        minVolcanoDist = dist;
        nearestVolcano = volcano;
      }

      // Volcanic risk within 100 km
      if (dist < 100000 / this.planet.physical.radius) {
        volcanicRisk = Math.max(volcanicRisk, (1 - dist * this.planet.physical.radius / 100000) * 0.8);
      }
    }

    // Check vents
    for (const vent of this.geothermalVents.values()) {
      const dist = this.angularDistance(
        latitude, longitude,
        vent.position.latitude, vent.position.longitude
      );

      if (dist < minVentDist) {
        minVentDist = dist;
        nearestVent = vent;
      }
    }

    // Seismic risk from boundaries
    for (const boundary of this.boundaries) {
      // Simplified: just use boundary activity
      seismicRisk = Math.max(seismicRisk, boundary.activity * 0.5);
    }

    // Recent earthquakes
    const recentQuakes = this.earthquakes.filter(eq => {
      const dist = this.angularDistance(
        latitude, longitude,
        eq.epicenter.latitude, eq.epicenter.longitude
      );
      return dist < 500000 / this.planet.physical.radius; // Within 500 km
    });

    return {
      seismicRisk,
      volcanicRisk,
      nearestVolcano,
      nearestVent,
      recentQuakes
    };
  }

  /**
   * Calculate angular distance
   */
  private angularDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const dLat = lat2 - lat1;
    const dLon = lon2 - lon1;

    const a = Math.sin(dLat / 2) ** 2 +
              Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;

    return 2 * Math.asin(Math.sqrt(a));
  }

  /**
   * Get all active volcanoes
   */
  getActiveVolcanoes(): Volcano[] {
    return Array.from(this.volcanoes.values()).filter(v => v.activity !== 'DORMANT');
  }

  /**
   * Get active eruptions
   */
  getActiveEruptions(): Eruption[] {
    return Array.from(this.activeEruptions.values());
  }

  /**
   * Get recent earthquakes
   */
  getRecentEarthquakes(hours: number = 24): Earthquake[] {
    const cutoff = Date.now() - hours * 3600000;
    return this.earthquakes.filter(eq => eq.timestamp > cutoff);
  }

  /**
   * Get hot spots
   */
  getHotSpots(): HotSpot[] {
    return Array.from(this.hotSpots.values());
  }

  /**
   * Get geothermal vents
   */
  getGeothermalVents(): GeothermalVent[] {
    return Array.from(this.geothermalVents.values());
  }
}
