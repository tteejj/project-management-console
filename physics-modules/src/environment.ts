/**
 * Environment System
 *
 * Simulates lunar environment:
 * - Solar position and illumination
 * - Day/night thermal cycling (100-400K)
 * - Surface temperature based on sun angle
 * - Engine plume-surface interaction
 * - Dust dynamics from rocket exhaust
 */

export interface Vector3 {
  x: number;
  y: number;
  z: number;
}

export interface EnvironmentConfig {
  lunarDay?: number;          // Lunar day length (seconds) - default: ~29.5 Earth days
  surfaceAlbedo?: number;     // Surface reflectivity (0-1)
  surfaceEmissivity?: number; // Surface thermal emissivity (0-1)
  minSurfaceTemp?: number;    // Minimum surface temperature (K)
  maxSurfaceTemp?: number;    // Maximum surface temperature (K)
}

const DEFAULT_CONFIG: Required<EnvironmentConfig> = {
  lunarDay: 29.5 * 24 * 3600,  // ~29.5 Earth days = 2,551,392 seconds
  surfaceAlbedo: 0.12,          // Moon albedo ~0.12
  surfaceEmissivity: 0.95,      // Near-blackbody
  minSurfaceTemp: 100,          // 100K in permanent shadow
  maxSurfaceTemp: 400           // 400K in direct sunlight
};

export interface SolarIllumination {
  sunDirection: Vector3;        // Unit vector pointing to sun
  sunElevation: number;         // Angle above horizon (degrees)
  isDaylight: boolean;
  solarFlux: number;            // W/m² at surface
}

export interface SurfaceConditions {
  temperature: number;          // Surface temperature (K)
  illuminated: boolean;
  solarFlux: number;            // W/m²
  thermalFlux: number;          // W/m² from surface radiation
}

export interface PlumeDynamics {
  dustDensity: number;          // kg/m³
  dustVelocity: Vector3;        // Dust velocity from plume
  visibility: number;           // Visibility degradation (0-1)
}

export class EnvironmentSystem {
  private config: Required<EnvironmentConfig>;
  private currentTime: number = 0;

  // Constants
  private readonly SOLAR_CONSTANT = 1361;  // W/m² at Earth
  private readonly AU = 1.496e11;           // Astronomical Unit (m)
  private readonly EARTH_SUN_DIST = this.AU;
  private readonly MOON_SUN_DIST = this.AU;  // Simplified (actually varies)
  private readonly STEFAN_BOLTZMANN = 5.67e-8;  // W/(m²·K⁴)

  constructor(config?: EnvironmentConfig) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /**
   * Update environment
   */
  update(dt: number): void {
    this.currentTime += dt;
  }

  /**
   * Get solar illumination at a position
   */
  getSolarIllumination(position: Vector3, surfaceNormal: Vector3): SolarIllumination {
    // Calculate sun direction (simplified: sun in XY plane, rotating)
    const lunarDay = this.config.lunarDay;
    const angle = (this.currentTime / lunarDay) * 2 * Math.PI;

    const sunDir: Vector3 = {
      x: Math.cos(angle),
      y: Math.sin(angle),
      z: 0
    };

    // Normalize
    const mag = Math.sqrt(sunDir.x ** 2 + sunDir.y ** 2 + sunDir.z ** 2);
    const sunDirNorm: Vector3 = {
      x: sunDir.x / mag,
      y: sunDir.y / mag,
      z: sunDir.z / mag
    };

    // Sun elevation angle
    const dotProduct = this.dot(sunDirNorm, surfaceNormal);
    const sunElevation = Math.asin(Math.max(-1, Math.min(1, dotProduct))) * 180 / Math.PI;

    const isDaylight = sunElevation > 0;

    // Solar flux (cosine law)
    const solarFlux = isDaylight
      ? this.SOLAR_CONSTANT * Math.max(0, dotProduct)
      : 0;

    return {
      sunDirection: sunDirNorm,
      sunElevation,
      isDaylight,
      solarFlux
    };
  }

  /**
   * Get surface conditions at a location
   */
  getSurfaceConditions(
    position: Vector3,
    surfaceNormal: Vector3
  ): SurfaceConditions {
    const illumination = this.getSolarIllumination(position, surfaceNormal);

    // Calculate equilibrium temperature from solar heating
    // Energy balance: Absorbed solar = Emitted thermal
    // (1-α)·F_solar = ε·σ·T⁴
    const absorbed = (1 - this.config.surfaceAlbedo) * illumination.solarFlux;
    const emissivity = this.config.surfaceEmissivity;

    let temperature: number;
    if (illumination.isDaylight && absorbed > 0) {
      // Solve for T: T = (absorbed / (ε·σ))^0.25
      temperature = Math.pow(
        absorbed / (emissivity * this.STEFAN_BOLTZMANN),
        0.25
      );
    } else {
      // Night side or shadow - minimum temperature
      temperature = this.config.minSurfaceTemp;
    }

    // Clamp to realistic range
    temperature = Math.max(
      this.config.minSurfaceTemp,
      Math.min(this.config.maxSurfaceTemp, temperature)
    );

    // Thermal radiation from surface
    const thermalFlux = emissivity * this.STEFAN_BOLTZMANN * Math.pow(temperature, 4);

    return {
      temperature,
      illuminated: illumination.isDaylight,
      solarFlux: illumination.solarFlux,
      thermalFlux
    };
  }

  /**
   * Calculate plume-surface interaction
   * Models dust kicked up by rocket exhaust impinging on surface
   */
  calculatePlumeInteraction(
    thrustN: number,
    exhaustVelocity: number,
    altitude: number,
    surfacePosition: Vector3
  ): PlumeDynamics {
    // No interaction if too high
    if (altitude > 100 || thrustN < 100) {
      return {
        dustDensity: 0,
        dustVelocity: { x: 0, y: 0, z: 0 },
        visibility: 1.0
      };
    }

    // Plume impingement on surface
    // Simplified model: dust ejection proportional to thrust and inverse to altitude
    const massFlowRate = thrustN / exhaustVelocity;  // kg/s

    // Dust entrainment efficiency (fraction of regolith mobilized)
    const entrainmentFactor = 0.01;  // 1% of impinging gas mass

    // Dust mass flow rate
    const dustMassFlow = massFlowRate * entrainmentFactor;

    // Dust density in plume (decreases with altitude)
    const plumeRadius = Math.max(1, altitude * 0.1);  // Plume expands ~10° cone
    const plumeVolume = Math.PI * plumeRadius * plumeRadius * altitude;
    const dustDensity = dustMassFlow / (plumeVolume + 1);  // kg/m³

    // Dust velocity (radially outward from impact point)
    const dustSpeed = Math.sqrt(thrustN / (dustMassFlow + 1)) * 0.5;  // Simplified

    // Visibility degradation (exponential with dust density)
    const visibility = Math.exp(-dustDensity * 100);

    return {
      dustDensity,
      dustVelocity: { x: 0, y: 0, z: dustSpeed },
      visibility: Math.max(0, Math.min(1, visibility))
    };
  }

  /**
   * Get current lunar time (0-1, where 0=midnight, 0.5=noon)
   */
  getLunarTimeOfDay(): number {
    return (this.currentTime % this.config.lunarDay) / this.config.lunarDay;
  }

  /**
   * Get environment state
   */
  getState() {
    return {
      currentTime: this.currentTime,
      lunarTimeOfDay: this.getLunarTimeOfDay(),
      lunarDay: this.config.lunarDay,
      isDay: this.getLunarTimeOfDay() > 0.25 && this.getLunarTimeOfDay() < 0.75
    };
  }

  // ========== Vector Math ==========

  private dot(a: Vector3, b: Vector3): number {
    return a.x * b.x + a.y * b.y + a.z * b.z;
  }

  private magnitude(v: Vector3): number {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  }
}
