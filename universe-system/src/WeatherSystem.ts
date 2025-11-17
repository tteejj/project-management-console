/**
 * WeatherSystem.ts
 * Planetary weather simulation with storms, wind patterns, and precipitation
 */

import { Vector3, Planet } from './CelestialBody';
import { AtmosphericPhysics, AtmosphericProfile } from './AtmosphericPhysics';

export interface WeatherPattern {
  type: WeatherType;
  intensity: number;         // 0-1
  coverage: number;          // 0-1 (fraction of planet)
  duration: number;          // seconds remaining
  center: { latitude: number; longitude: number };
  radius: number;            // meters
  windSpeed: number;         // m/s
  precipitation: number;     // mm/hour
  temperature: number;       // K
  pressure: number;          // Pa
}

export type WeatherType =
  | 'CLEAR'
  | 'CLOUDY'
  | 'RAIN'
  | 'SNOW'
  | 'STORM'
  | 'HURRICANE'
  | 'DUST_STORM'
  | 'ACID_RAIN'
  | 'METHANE_RAIN';

export interface Storm {
  id: string;
  type: StormType;
  intensity: number;         // 0-1
  position: { latitude: number; longitude: number };
  radius: number;            // meters
  windSpeed: number;         // m/s
  rotation: number;          // rad/s (for cyclonic storms)
  elevation: number;         // meters above surface
  lightningRate: number;     // strikes per minute
  lifetime: number;          // seconds
  age: number;               // seconds
}

export type StormType =
  | 'THUNDERSTORM'
  | 'TROPICAL_CYCLONE'
  | 'TORNADO'
  | 'DUST_DEVIL'
  | 'DUST_STORM'
  | 'MAGNETIC_STORM'
  | 'ION_STORM';

export interface WindPattern {
  latitude: number;          // radians
  direction: number;         // radians (0 = east)
  speed: number;             // m/s
  altitude: number;          // meters
  type: 'TRADE_WIND' | 'WESTERLIES' | 'POLAR_EASTERLIES' | 'JET_STREAM';
}

export interface PrecipitationEvent {
  type: 'RAIN' | 'SNOW' | 'HAIL' | 'SLEET' | 'ACID' | 'METHANE';
  rate: number;              // mm/hour
  temperature: number;       // K
  coverage: number;          // 0-1
  altitude: number;          // meters (cloud base)
}

export interface ClimateZone {
  name: string;
  latitudeMin: number;       // radians
  latitudeMax: number;       // radians
  averageTemp: number;       // K
  humidity: number;          // 0-1
  rainfall: number;          // mm/year
  dominantWeather: WeatherType[];
}

/**
 * Planetary Weather Simulation
 */
export class WeatherSystem {
  private planet: Planet;
  private storms: Map<string, Storm> = new Map();
  private currentWeather: Map<string, WeatherPattern> = new Map(); // zoneId -> weather
  private windPatterns: WindPattern[] = [];
  private climateZones: ClimateZone[] = [];
  private nextStormId = 0;

  constructor(planet: Planet) {
    this.planet = planet;
    this.initializeClimates();
    this.initializeWindPatterns();
    this.generateInitialWeather();
  }

  /**
   * Initialize climate zones based on planet type
   */
  private initializeClimates(): void {
    if (!this.planet.physical.atmospherePressure) {
      // No atmosphere = no weather
      return;
    }

    const avgTemp = this.planet.surfaceTemperature;

    // Earth-like climates
    if (this.planet.planetClass === 'TERRESTRIAL' && avgTemp > 250 && avgTemp < 320) {
      this.climateZones = [
        {
          name: 'Tropical',
          latitudeMin: -Math.PI / 6,
          latitudeMax: Math.PI / 6,
          averageTemp: avgTemp + 10,
          humidity: 0.8,
          rainfall: 2000,
          dominantWeather: ['CLOUDY', 'RAIN', 'STORM']
        },
        {
          name: 'Subtropical',
          latitudeMin: Math.PI / 6,
          latitudeMax: Math.PI / 3,
          averageTemp: avgTemp + 5,
          humidity: 0.6,
          rainfall: 1000,
          dominantWeather: ['CLEAR', 'CLOUDY']
        },
        {
          name: 'Temperate',
          latitudeMin: Math.PI / 3,
          latitudeMax: Math.PI / 2.2,
          averageTemp: avgTemp,
          humidity: 0.7,
          rainfall: 800,
          dominantWeather: ['CLOUDY', 'RAIN', 'SNOW']
        },
        {
          name: 'Polar',
          latitudeMin: Math.PI / 2.2,
          latitudeMax: Math.PI / 2,
          averageTemp: avgTemp - 30,
          humidity: 0.4,
          rainfall: 200,
          dominantWeather: ['SNOW', 'CLEAR']
        }
      ];
    }
    // Desert world
    else if (this.planet.planetClass === 'DESERT') {
      this.climateZones = [
        {
          name: 'Desert',
          latitudeMin: -Math.PI / 2,
          latitudeMax: Math.PI / 2,
          averageTemp: avgTemp,
          humidity: 0.1,
          rainfall: 50,
          dominantWeather: ['CLEAR', 'DUST_STORM']
        }
      ];
    }
    // Gas giant
    else if (this.planet.planetClass === 'GAS_GIANT') {
      this.climateZones = [
        {
          name: 'Global Storm Bands',
          latitudeMin: -Math.PI / 2,
          latitudeMax: Math.PI / 2,
          averageTemp: avgTemp,
          humidity: 1.0,
          rainfall: 0, // Different precipitation
          dominantWeather: ['STORM', 'HURRICANE']
        }
      ];
    }
  }

  /**
   * Initialize wind patterns
   */
  private initializeWindPatterns(): void {
    if (!this.planet.physical.atmospherePressure) return;

    const rotationSpeed = (2 * Math.PI * this.planet.physical.radius) / this.planet.physical.rotationPeriod;

    // Trade winds (0-30°)
    this.windPatterns.push({
      latitude: Math.PI / 6,
      direction: -Math.PI / 4, // Northeast
      speed: 20 + rotationSpeed * 0.1,
      altitude: 2000,
      type: 'TRADE_WIND'
    });

    // Westerlies (30-60°)
    this.windPatterns.push({
      latitude: Math.PI / 3,
      direction: Math.PI / 4, // Southwest
      speed: 30 + rotationSpeed * 0.15,
      altitude: 5000,
      type: 'WESTERLIES'
    });

    // Polar easterlies (60-90°)
    this.windPatterns.push({
      latitude: Math.PI / 2.5,
      direction: -Math.PI / 3,
      speed: 15 + rotationSpeed * 0.05,
      altitude: 1000,
      type: 'POLAR_EASTERLIES'
    });

    // Jet stream
    this.windPatterns.push({
      latitude: Math.PI / 3,
      direction: Math.PI / 2, // West to east
      speed: 100 + rotationSpeed * 0.3,
      altitude: 10000,
      type: 'JET_STREAM'
    });
  }

  /**
   * Generate initial weather patterns
   */
  private generateInitialWeather(): void {
    if (!this.planet.physical.atmospherePressure) return;

    // Create some initial storms for active planets
    if (this.planet.planetClass === 'GAS_GIANT') {
      // Gas giants have persistent mega-storms
      for (let i = 0; i < 5; i++) {
        this.createStorm('TROPICAL_CYCLONE', Math.random() * Math.PI - Math.PI / 2, Math.random() * 2 * Math.PI, 0.8);
      }
    } else if (this.planet.physical.atmospherePressure > 10000) {
      // Active atmospheres have regular storms
      for (let i = 0; i < 3; i++) {
        const stormType = Math.random() > 0.7 ? 'TROPICAL_CYCLONE' : 'THUNDERSTORM';
        this.createStorm(stormType as StormType, Math.random() * Math.PI / 3 - Math.PI / 6, Math.random() * 2 * Math.PI, Math.random() * 0.5);
      }
    }
  }

  /**
   * Update weather simulation
   */
  update(deltaTime: number): void {
    if (!this.planet.physical.atmospherePressure) return;

    // Update existing storms
    for (const [id, storm] of this.storms) {
      this.updateStorm(storm, deltaTime);

      // Remove old storms
      if (storm.age >= storm.lifetime) {
        this.storms.delete(id);
      }
    }

    // Spawn new storms randomly
    if (Math.random() < deltaTime / 3600) { // Average one storm per hour
      this.spawnRandomStorm();
    }

    // Update weather patterns
    this.updateWeatherPatterns(deltaTime);
  }

  /**
   * Update individual storm
   */
  private updateStorm(storm: Storm, deltaTime: number): void {
    storm.age += deltaTime;

    // Storm evolution
    const lifeProgress = storm.age / storm.lifetime;

    if (lifeProgress < 0.3) {
      // Growing phase
      storm.intensity = Math.min(1, storm.intensity + deltaTime / (storm.lifetime * 0.3));
    } else if (lifeProgress > 0.7) {
      // Dissipating phase
      storm.intensity = Math.max(0, storm.intensity - deltaTime / (storm.lifetime * 0.3));
    }

    // Storm movement (simplified)
    const windPattern = this.getWindAtLocation(storm.position.latitude, storm.elevation);
    if (windPattern) {
      // Move storm with prevailing winds
      const angularSpeed = windPattern.speed / this.planet.physical.radius;
      storm.position.longitude += angularSpeed * deltaTime;

      // Wrap longitude
      if (storm.position.longitude > Math.PI) storm.position.longitude -= 2 * Math.PI;
      if (storm.position.longitude < -Math.PI) storm.position.longitude += 2 * Math.PI;
    }

    // Update storm characteristics based on intensity
    storm.windSpeed = storm.intensity * this.getMaxWindSpeed(storm.type);
    storm.lightningRate = storm.type === 'THUNDERSTORM' ? storm.intensity * 60 : 0;
  }

  /**
   * Get maximum wind speed for storm type
   */
  private getMaxWindSpeed(type: StormType): number {
    switch (type) {
      case 'THUNDERSTORM': return 50;
      case 'TROPICAL_CYCLONE': return 200;
      case 'TORNADO': return 400;
      case 'DUST_DEVIL': return 100;
      case 'DUST_STORM': return 150;
      case 'MAGNETIC_STORM': return 0; // Different effects
      case 'ION_STORM': return 0;
      default: return 30;
    }
  }

  /**
   * Create a new storm
   */
  private createStorm(
    type: StormType,
    latitude: number,
    longitude: number,
    initialIntensity: number = 0.3
  ): Storm {
    const storm: Storm = {
      id: `storm_${this.nextStormId++}`,
      type,
      intensity: initialIntensity,
      position: { latitude, longitude },
      radius: this.getStormRadius(type),
      windSpeed: initialIntensity * this.getMaxWindSpeed(type),
      rotation: type === 'TROPICAL_CYCLONE' || type === 'TORNADO' ? 0.1 : 0,
      elevation: type === 'DUST_STORM' ? 100 : 5000,
      lightningRate: type === 'THUNDERSTORM' ? initialIntensity * 60 : 0,
      lifetime: this.getStormLifetime(type),
      age: 0
    };

    this.storms.set(storm.id, storm);
    return storm;
  }

  /**
   * Get typical storm radius
   */
  private getStormRadius(type: StormType): number {
    switch (type) {
      case 'THUNDERSTORM': return 50000; // 50 km
      case 'TROPICAL_CYCLONE': return 500000; // 500 km
      case 'TORNADO': return 1000; // 1 km
      case 'DUST_DEVIL': return 100;
      case 'DUST_STORM': return 1000000; // 1000 km
      case 'ION_STORM': return 200000;
      default: return 10000;
    }
  }

  /**
   * Get storm lifetime
   */
  private getStormLifetime(type: StormType): number {
    switch (type) {
      case 'THUNDERSTORM': return 3600 * 2; // 2 hours
      case 'TROPICAL_CYCLONE': return 86400 * 7; // 7 days
      case 'TORNADO': return 600; // 10 minutes
      case 'DUST_DEVIL': return 300; // 5 minutes
      case 'DUST_STORM': return 86400 * 3; // 3 days
      case 'ION_STORM': return 3600 * 6; // 6 hours
      default: return 3600;
    }
  }

  /**
   * Spawn random storm based on planet conditions
   */
  private spawnRandomStorm(): void {
    const stormType = this.selectRandomStormType();
    const latitude = (Math.random() - 0.5) * Math.PI / 2; // -45° to +45°
    const longitude = (Math.random() - 0.5) * 2 * Math.PI;

    this.createStorm(stormType, latitude, longitude);
  }

  /**
   * Select random storm type based on planet
   */
  private selectRandomStormType(): StormType {
    if (this.planet.planetClass === 'GAS_GIANT') {
      return Math.random() > 0.5 ? 'TROPICAL_CYCLONE' : 'ION_STORM';
    } else if (this.planet.planetClass === 'DESERT') {
      return Math.random() > 0.3 ? 'DUST_STORM' : 'DUST_DEVIL';
    } else {
      const rand = Math.random();
      if (rand < 0.7) return 'THUNDERSTORM';
      if (rand < 0.95) return 'TROPICAL_CYCLONE';
      return 'TORNADO';
    }
  }

  /**
   * Update weather patterns
   */
  private updateWeatherPatterns(deltaTime: number): void {
    // Update each climate zone's weather
    for (let i = 0; i < this.climateZones.length; i++) {
      const zone = this.climateZones[i];
      const zoneId = `zone_${i}`;

      let currentWeather = this.currentWeather.get(zoneId);

      if (!currentWeather) {
        // Initialize weather
        currentWeather = this.generateWeatherPattern(zone);
        this.currentWeather.set(zoneId, currentWeather);
      }

      // Update duration
      currentWeather.duration -= deltaTime;

      // Change weather when duration expires
      if (currentWeather.duration <= 0) {
        this.currentWeather.set(zoneId, this.generateWeatherPattern(zone));
      }
    }
  }

  /**
   * Generate weather pattern for climate zone
   */
  private generateWeatherPattern(zone: ClimateZone): WeatherPattern {
    const type = zone.dominantWeather[Math.floor(Math.random() * zone.dominantWeather.length)];
    const intensity = Math.random() * 0.7 + 0.3;

    return {
      type,
      intensity,
      coverage: zone.rainfall / 2000, // Approximate
      duration: 3600 * (2 + Math.random() * 4), // 2-6 hours
      center: {
        latitude: (zone.latitudeMin + zone.latitudeMax) / 2,
        longitude: 0
      },
      radius: this.planet.physical.radius * 0.2,
      windSpeed: this.getWeatherWindSpeed(type, intensity),
      precipitation: this.getPrecipitationRate(type, intensity),
      temperature: zone.averageTemp,
      pressure: this.planet.physical.atmospherePressure || 0
    };
  }

  /**
   * Get wind speed for weather type
   */
  private getWeatherWindSpeed(type: WeatherType, intensity: number): number {
    const base: Record<WeatherType, number> = {
      CLEAR: 5,
      CLOUDY: 10,
      RAIN: 20,
      SNOW: 15,
      STORM: 50,
      HURRICANE: 150,
      DUST_STORM: 80,
      ACID_RAIN: 25,
      METHANE_RAIN: 30
    };
    return base[type] * intensity;
  }

  /**
   * Get precipitation rate
   */
  private getPrecipitationRate(type: WeatherType, intensity: number): number {
    const base: Record<WeatherType, number> = {
      CLEAR: 0,
      CLOUDY: 0,
      RAIN: 10,
      SNOW: 5,
      STORM: 50,
      HURRICANE: 100,
      DUST_STORM: 0,
      ACID_RAIN: 15,
      METHANE_RAIN: 8
    };
    return base[type] * intensity;
  }

  /**
   * Get weather at specific location
   */
  getWeatherAt(latitude: number, longitude: number, altitude: number): {
    weather: WeatherPattern | null;
    storm: Storm | null;
    wind: WindPattern | null;
    hazardLevel: number;
  } {
    // Check for active storms
    let activeStorm: Storm | null = null;
    for (const storm of this.storms.values()) {
      const distance = this.angularDistance(
        latitude, longitude,
        storm.position.latitude, storm.position.longitude
      );
      const angularRadius = storm.radius / this.planet.physical.radius;

      if (distance < angularRadius && Math.abs(altitude - storm.elevation) < 5000) {
        activeStorm = storm;
        break;
      }
    }

    // Get zone weather
    const zone = this.climateZones.find(z =>
      latitude >= z.latitudeMin && latitude <= z.latitudeMax
    );

    const weather = zone ? this.currentWeather.get(`zone_${this.climateZones.indexOf(zone)}`) || null : null;

    // Get wind
    const wind = this.getWindAtLocation(latitude, altitude);

    // Calculate hazard level
    let hazardLevel = 0;
    if (activeStorm) {
      hazardLevel = activeStorm.intensity * 0.8;
    } else if (weather) {
      hazardLevel = weather.intensity * 0.3;
    }

    return { weather, storm: activeStorm, wind, hazardLevel };
  }

  /**
   * Get wind at location
   */
  private getWindAtLocation(latitude: number, altitude: number): WindPattern | null {
    // Find closest wind pattern
    let closest: WindPattern | null = null;
    let minDiff = Infinity;

    for (const pattern of this.windPatterns) {
      const latDiff = Math.abs(pattern.latitude - Math.abs(latitude));
      const altDiff = Math.abs(pattern.altitude - altitude);
      const diff = latDiff + altDiff / 10000;

      if (diff < minDiff) {
        minDiff = diff;
        closest = pattern;
      }
    }

    return closest;
  }

  /**
   * Calculate angular distance between two lat/lon points
   */
  private angularDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    // Haversine formula
    const dLat = lat2 - lat1;
    const dLon = lon2 - lon1;

    const a = Math.sin(dLat / 2) ** 2 +
              Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;

    return 2 * Math.asin(Math.sqrt(a));
  }

  /**
   * Get all active storms
   */
  getStorms(): Storm[] {
    return Array.from(this.storms.values());
  }

  /**
   * Get climate zones
   */
  getClimateZones(): ClimateZone[] {
    return this.climateZones;
  }
}
