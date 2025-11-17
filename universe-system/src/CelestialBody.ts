/**
 * CelestialBody.ts
 * Base classes and types for all celestial objects in the universe
 */

export interface Vector3 {
  x: number;
  y: number;
  z: number;
}

export interface OrbitalElements {
  semiMajorAxis: number;      // meters
  eccentricity: number;        // 0-1 (0 = circular)
  inclination: number;         // radians
  longitudeOfAscendingNode: number; // radians
  argumentOfPeriapsis: number; // radians
  trueAnomaly: number;         // radians (position in orbit)
}

export interface PhysicalProperties {
  mass: number;                // kg
  radius: number;              // meters
  rotationPeriod: number;      // seconds
  axialTilt: number;           // radians
  surfaceGravity: number;      // m/s²
  escapeVelocity: number;      // m/s
  atmospherePressure?: number; // pascals (at surface)
  atmosphereComposition?: Map<string, number>; // element -> percentage
}

export interface VisualProperties {
  color: string;               // hex color
  albedo: number;              // 0-1 reflectivity
  emissivity: number;          // 0-1 thermal emission
  texture?: string;            // texture identifier
  rings?: RingSystem;
}

export interface RingSystem {
  innerRadius: number;         // meters from center
  outerRadius: number;         // meters from center
  thickness: number;           // meters
  color: string;
  opacity: number;             // 0-1
}

export enum CelestialBodyType {
  STAR = 'STAR',
  PLANET = 'PLANET',
  MOON = 'MOON',
  ASTEROID = 'ASTEROID',
  COMET = 'COMET',
  STATION = 'STATION',
  DEBRIS = 'DEBRIS'
}

export enum PlanetClass {
  GAS_GIANT = 'GAS_GIANT',        // Jupiter-like
  ICE_GIANT = 'ICE_GIANT',        // Neptune-like
  TERRESTRIAL = 'TERRESTRIAL',    // Earth-like
  DESERT = 'DESERT',              // Mars-like
  ICE = 'ICE',                    // Europa-like
  LAVA = 'LAVA',                  // Io-like
  OCEAN = 'OCEAN',                // Water world
  TOXIC = 'TOXIC',                // Venus-like
}

export enum StarClass {
  O = 'O', // Blue supergiant
  B = 'B', // Blue giant
  A = 'A', // Blue-white
  F = 'F', // White
  G = 'G', // Yellow (Sun-like)
  K = 'K', // Orange
  M = 'M', // Red dwarf
  NEUTRON = 'NEUTRON',
  BLACK_HOLE = 'BLACK_HOLE'
}

/**
 * Base class for all celestial bodies
 */
export abstract class CelestialBody {
  public id: string;
  public name: string;
  public type: CelestialBodyType;
  public position: Vector3;
  public velocity: Vector3;
  public physical: PhysicalProperties;
  public visual: VisualProperties;
  public parent?: CelestialBody;
  public children: CelestialBody[] = [];
  public orbital?: OrbitalElements;

  constructor(
    id: string,
    name: string,
    type: CelestialBodyType,
    physical: PhysicalProperties,
    visual: VisualProperties,
    position: Vector3 = { x: 0, y: 0, z: 0 },
    velocity: Vector3 = { x: 0, y: 0, z: 0 }
  ) {
    this.id = id;
    this.name = name;
    this.type = type;
    this.physical = physical;
    this.visual = visual;
    this.position = position;
    this.velocity = velocity;
  }

  /**
   * Add a child body (moon, satellite, etc.)
   */
  addChild(child: CelestialBody): void {
    child.parent = this;
    this.children.push(child);
  }

  /**
   * Calculate gravitational force on another body
   */
  gravitationalForce(other: CelestialBody): Vector3 {
    const G = 6.674e-11; // gravitational constant
    const dx = other.position.x - this.position.x;
    const dy = other.position.y - this.position.y;
    const dz = other.position.z - this.position.z;
    const distanceSquared = dx * dx + dy * dy + dz * dz;
    const distance = Math.sqrt(distanceSquared);

    if (distance === 0) return { x: 0, y: 0, z: 0 };

    const forceMagnitude = (G * this.physical.mass * other.physical.mass) / distanceSquared;
    const forceDirection = {
      x: dx / distance,
      y: dy / distance,
      z: dz / distance
    };

    return {
      x: forceMagnitude * forceDirection.x,
      y: forceMagnitude * forceDirection.y,
      z: forceMagnitude * forceDirection.z
    };
  }

  /**
   * Calculate sphere of influence (Hill sphere approximation)
   */
  sphereOfInfluence(): number {
    if (!this.parent || !this.orbital) return Infinity;

    const a = this.orbital.semiMajorAxis;
    const m = this.physical.mass;
    const M = this.parent.physical.mass;

    return a * Math.pow(m / (3 * M), 1/3);
  }

  /**
   * Update position based on orbital mechanics
   */
  updateOrbitalPosition(deltaTime: number): void {
    if (!this.parent || !this.orbital) return;

    const G = 6.674e-11;
    const mu = G * this.parent.physical.mass;
    const a = this.orbital.semiMajorAxis;
    const e = this.orbital.eccentricity;

    // Mean motion
    const n = Math.sqrt(mu / (a * a * a));

    // Update true anomaly
    this.orbital.trueAnomaly += n * deltaTime;
    this.orbital.trueAnomaly %= (2 * Math.PI);

    // Calculate position in orbital plane
    const r = a * (1 - e * e) / (1 + e * Math.cos(this.orbital.trueAnomaly));

    // Convert to 3D coordinates (simplified)
    const x = r * Math.cos(this.orbital.trueAnomaly);
    const y = r * Math.sin(this.orbital.trueAnomaly);

    // Apply inclination and orientation
    const cos_i = Math.cos(this.orbital.inclination);
    const sin_i = Math.sin(this.orbital.inclination);
    const cos_omega = Math.cos(this.orbital.longitudeOfAscendingNode);
    const sin_omega = Math.sin(this.orbital.longitudeOfAscendingNode);

    this.position = {
      x: this.parent.position.x + (x * cos_omega - y * cos_i * sin_omega),
      y: this.parent.position.y + (x * sin_omega + y * cos_i * cos_omega),
      z: this.parent.position.z + (y * sin_i)
    };
  }

  /**
   * Check if a point is within the body's atmosphere
   */
  isInAtmosphere(point: Vector3): boolean {
    if (!this.physical.atmospherePressure) return false;

    const dx = point.x - this.position.x;
    const dy = point.y - this.position.y;
    const dz = point.z - this.position.z;
    const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);

    // Atmosphere extends to ~5x scale height
    const atmosphereHeight = this.physical.radius * 1.2; // simplified
    return distance < (this.physical.radius + atmosphereHeight);
  }

  /**
   * Get atmospheric properties at a point
   */
  getAtmosphericDensity(point: Vector3): number {
    if (!this.physical.atmospherePressure) return 0;

    const dx = point.x - this.position.x;
    const dy = point.y - this.position.y;
    const dz = point.z - this.position.z;
    const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
    const altitude = distance - this.physical.radius;

    if (altitude < 0) return 0; // underground

    // Exponential atmosphere model
    const scaleHeight = 8500; // meters (simplified)
    const surfaceDensity = this.physical.atmospherePressure / (287 * 288); // simplified

    return surfaceDensity * Math.exp(-altitude / scaleHeight);
  }
}

/**
 * Star class
 */
export class Star extends CelestialBody {
  public starClass: StarClass;
  public luminosity: number;    // watts
  public temperature: number;   // kelvin
  public solarRadiation: number; // W/m² at 1 AU

  constructor(
    id: string,
    name: string,
    starClass: StarClass,
    physical: PhysicalProperties,
    visual: VisualProperties,
    luminosity: number,
    temperature: number
  ) {
    super(id, name, CelestialBodyType.STAR, physical, visual);
    this.starClass = starClass;
    this.luminosity = luminosity;
    this.temperature = temperature;

    // Calculate solar radiation at 1 AU
    const AU = 1.496e11; // meters
    this.solarRadiation = luminosity / (4 * Math.PI * AU * AU);
  }

  /**
   * Get radiation intensity at a distance
   */
  getRadiationAt(distance: number): number {
    return this.luminosity / (4 * Math.PI * distance * distance);
  }

  /**
   * Get habitable zone range (simplified)
   */
  getHabitableZone(): { inner: number; outer: number } {
    const L_sun = 3.828e26; // watts
    const luminosityRatio = this.luminosity / L_sun;

    return {
      inner: 1.496e11 * Math.sqrt(luminosityRatio * 0.95),  // ~0.95 AU equivalent
      outer: 1.496e11 * Math.sqrt(luminosityRatio * 1.37)   // ~1.37 AU equivalent
    };
  }
}

/**
 * Planet class
 */
export class Planet extends CelestialBody {
  public planetClass: PlanetClass;
  public hasAtmosphere: boolean;
  public isHabitable: boolean;
  public surfaceTemperature: number; // kelvin
  public resources: Map<string, number> = new Map(); // resource -> abundance

  constructor(
    id: string,
    name: string,
    planetClass: PlanetClass,
    physical: PhysicalProperties,
    visual: VisualProperties,
    surfaceTemperature: number,
    orbital?: OrbitalElements
  ) {
    super(id, name, CelestialBodyType.PLANET, physical, visual);
    this.planetClass = planetClass;
    this.hasAtmosphere = !!physical.atmospherePressure;
    this.surfaceTemperature = surfaceTemperature;
    this.orbital = orbital;
    this.isHabitable = this.calculateHabitability();
  }

  private calculateHabitability(): boolean {
    // Simple habitability check
    const tempOk = this.surfaceTemperature > 273 && this.surfaceTemperature < 373;
    const atmosphereOk = this.hasAtmosphere &&
                        this.physical.atmospherePressure! > 50000 &&
                        this.physical.atmospherePressure! < 150000;
    const sizeOk = this.physical.mass > 3e24 && this.physical.mass < 1e25;

    return tempOk && atmosphereOk && sizeOk;
  }

  /**
   * Add resource to planet
   */
  addResource(resource: string, abundance: number): void {
    this.resources.set(resource, abundance);
  }
}

/**
 * Moon class
 */
export class Moon extends CelestialBody {
  public isTidallyLocked: boolean;

  constructor(
    id: string,
    name: string,
    physical: PhysicalProperties,
    visual: VisualProperties,
    orbital?: OrbitalElements,
    tidallyLocked: boolean = true
  ) {
    super(id, name, CelestialBodyType.MOON, physical, visual);
    this.orbital = orbital;
    this.isTidallyLocked = tidallyLocked;
  }
}

/**
 * Asteroid class
 */
export class Asteroid extends CelestialBody {
  public composition: 'METAL' | 'ROCK' | 'ICE';
  public mineralWealth: number; // 0-1

  constructor(
    id: string,
    name: string,
    physical: PhysicalProperties,
    visual: VisualProperties,
    composition: 'METAL' | 'ROCK' | 'ICE',
    mineralWealth: number = 0.5
  ) {
    super(id, name, CelestialBodyType.ASTEROID, physical, visual);
    this.composition = composition;
    this.mineralWealth = mineralWealth;
  }
}
