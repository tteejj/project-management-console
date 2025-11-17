/**
 * HazardSystem.ts
 * Environmental hazards: storms, radiation, debris, anomalies
 */

import { Vector3, CelestialBody } from './CelestialBody';

export enum HazardType {
  SOLAR_STORM = 'SOLAR_STORM',           // Radiation burst from star
  RADIATION_BELT = 'RADIATION_BELT',     // Van Allen-like radiation zones
  DEBRIS_FIELD = 'DEBRIS_FIELD',         // Space junk, asteroid fragments
  ION_STORM = 'ION_STORM',               // Electromagnetic interference
  GRAVITY_WELL = 'GRAVITY_WELL',         // Dangerous gravity gradient
  MAGNETIC_ANOMALY = 'MAGNETIC_ANOMALY', // Compass/navigation disruption
  PLASMA_CLOUD = 'PLASMA_CLOUD',         // Superheated plasma
  DARK_MATTER_CLOUD = 'DARK_MATTER_CLOUD', // Unknown physics
  MICRO_METEOR_SHOWER = 'MICRO_METEOR_SHOWER' // High-velocity particles
}

export enum HazardSeverity {
  LOW = 1,
  MODERATE = 2,
  HIGH = 3,
  EXTREME = 4,
  LETHAL = 5
}

export interface HazardEffect {
  hullDamagePerSecond?: number;      // Direct damage
  radiationPerSecond?: number;        // Radiation exposure
  heatPerSecond?: number;             // Thermal load
  electricalInterference?: number;    // System disruption (0-1)
  navigationDisruption?: number;      // Nav error (0-1)
  thrustPenalty?: number;             // Movement penalty (0-1)
  shieldDrain?: number;               // Energy shield drain per second
  visibilityReduction?: number;       // Sensor range penalty (0-1)
}

export interface HazardZone {
  id: string;
  type: HazardType;
  name: string;
  severity: HazardSeverity;
  position: Vector3;
  radius: number;                     // meters
  effects: HazardEffect;
  active: boolean;
  duration?: number;                  // seconds (undefined = permanent)
  timeRemaining?: number;             // seconds
  movementVector?: Vector3;           // moving hazards
}

/**
 * Base Hazard class
 */
export abstract class Hazard {
  public id: string;
  public type: HazardType;
  public name: string;
  public severity: HazardSeverity;
  public position: Vector3;
  public radius: number;
  public effects: HazardEffect;
  public active: boolean = true;
  public duration?: number;
  public timeElapsed: number = 0;

  constructor(
    id: string,
    type: HazardType,
    name: string,
    severity: HazardSeverity,
    position: Vector3,
    radius: number,
    effects: HazardEffect,
    duration?: number
  ) {
    this.id = id;
    this.type = type;
    this.name = name;
    this.severity = severity;
    this.position = position;
    this.radius = radius;
    this.effects = effects;
    this.duration = duration;
  }

  /**
   * Check if a point is within the hazard
   */
  isPointInHazard(point: Vector3): boolean {
    const dx = point.x - this.position.x;
    const dy = point.y - this.position.y;
    const dz = point.z - this.position.z;
    const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
    return distance < this.radius;
  }

  /**
   * Get effect intensity at a point (0-1 based on distance)
   */
  getIntensityAt(point: Vector3): number {
    const dx = point.x - this.position.x;
    const dy = point.y - this.position.y;
    const dz = point.z - this.position.z;
    const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);

    if (distance >= this.radius) return 0;

    // Linear falloff from center
    return 1 - (distance / this.radius);
  }

  /**
   * Apply effects to a ship at a position
   */
  applyEffects(point: Vector3, deltaTime: number): HazardEffect {
    if (!this.active) return {};

    const intensity = this.getIntensityAt(point);
    if (intensity === 0) return {};

    // Scale effects by intensity
    const scaledEffects: HazardEffect = {};
    if (this.effects.hullDamagePerSecond)
      scaledEffects.hullDamagePerSecond = this.effects.hullDamagePerSecond * intensity * deltaTime;
    if (this.effects.radiationPerSecond)
      scaledEffects.radiationPerSecond = this.effects.radiationPerSecond * intensity * deltaTime;
    if (this.effects.heatPerSecond)
      scaledEffects.heatPerSecond = this.effects.heatPerSecond * intensity * deltaTime;
    if (this.effects.electricalInterference)
      scaledEffects.electricalInterference = this.effects.electricalInterference * intensity;
    if (this.effects.navigationDisruption)
      scaledEffects.navigationDisruption = this.effects.navigationDisruption * intensity;
    if (this.effects.thrustPenalty)
      scaledEffects.thrustPenalty = this.effects.thrustPenalty * intensity;
    if (this.effects.shieldDrain)
      scaledEffects.shieldDrain = this.effects.shieldDrain * intensity * deltaTime;
    if (this.effects.visibilityReduction)
      scaledEffects.visibilityReduction = this.effects.visibilityReduction * intensity;

    return scaledEffects;
  }

  /**
   * Update hazard state
   */
  update(deltaTime: number): void {
    if (!this.active) return;

    this.timeElapsed += deltaTime;

    if (this.duration && this.timeElapsed >= this.duration) {
      this.active = false;
    }
  }
}

/**
 * Solar Storm - radiation burst from star
 */
export class SolarStorm extends Hazard {
  public source: CelestialBody; // The star

  constructor(id: string, star: CelestialBody, severity: HazardSeverity, duration: number) {
    const radius = 1e11 * severity; // Affects whole inner system

    const effects: HazardEffect = {
      radiationPerSecond: 10 * severity,
      electricalInterference: 0.2 * severity,
      heatPerSecond: 5 * severity
    };

    super(
      id,
      HazardType.SOLAR_STORM,
      `Solar Storm ${severity}`,
      severity,
      star.position,
      radius,
      effects,
      duration
    );

    this.source = star;
  }

  update(deltaTime: number): void {
    super.update(deltaTime);
    // Solar storms move with the star
    this.position = this.source.position;
  }
}

/**
 * Radiation Belt - permanent radiation zone around planets
 */
export class RadiationBelt extends Hazard {
  public parent: CelestialBody;
  public innerRadius: number;
  public outerRadius: number;

  constructor(
    id: string,
    parent: CelestialBody,
    innerRadius: number, // meters from center
    outerRadius: number,
    severity: HazardSeverity
  ) {
    const effects: HazardEffect = {
      radiationPerSecond: 5 * severity,
      electricalInterference: 0.1 * severity
    };

    super(
      id,
      HazardType.RADIATION_BELT,
      `${parent.name} Radiation Belt`,
      severity,
      parent.position,
      outerRadius,
      effects
    );

    this.parent = parent;
    this.innerRadius = innerRadius;
    this.outerRadius = outerRadius;
  }

  isPointInHazard(point: Vector3): boolean {
    const dx = point.x - this.position.x;
    const dy = point.y - this.position.y;
    const dz = point.z - this.position.z;
    const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
    return distance >= this.innerRadius && distance <= this.outerRadius;
  }

  getIntensityAt(point: Vector3): number {
    const dx = point.x - this.position.x;
    const dy = point.y - this.position.y;
    const dz = point.z - this.position.z;
    const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);

    if (distance < this.innerRadius || distance > this.outerRadius) return 0;

    // Peak intensity in middle of belt
    const beltWidth = this.outerRadius - this.innerRadius;
    const positionInBelt = distance - this.innerRadius;
    const normalizedPosition = positionInBelt / beltWidth;

    // Gaussian-like distribution
    return Math.exp(-Math.pow((normalizedPosition - 0.5) * 4, 2));
  }

  update(deltaTime: number): void {
    super.update(deltaTime);
    // Radiation belt moves with parent body
    this.position = this.parent.position;
  }
}

/**
 * Debris Field - dangerous space junk
 */
export class DebrisField extends Hazard {
  public debrisCount: number;
  public velocity: Vector3;

  constructor(
    id: string,
    name: string,
    position: Vector3,
    radius: number,
    debrisCount: number,
    velocity: Vector3 = { x: 0, y: 0, z: 0 },
    severity: HazardSeverity = HazardSeverity.MODERATE
  ) {
    const effects: HazardEffect = {
      hullDamagePerSecond: 20 * severity,
      visibilityReduction: 0.3
    };

    super(
      id,
      HazardType.DEBRIS_FIELD,
      name,
      severity,
      position,
      radius,
      effects
    );

    this.debrisCount = debrisCount;
    this.velocity = velocity;
  }

  update(deltaTime: number): void {
    super.update(deltaTime);

    // Debris fields drift
    this.position.x += this.velocity.x * deltaTime;
    this.position.y += this.velocity.y * deltaTime;
    this.position.z += this.velocity.z * deltaTime;
  }
}

/**
 * Ion Storm - electromagnetic chaos
 */
export class IonStorm extends Hazard {
  public velocity: Vector3;

  constructor(
    id: string,
    position: Vector3,
    radius: number,
    velocity: Vector3,
    severity: HazardSeverity,
    duration: number
  ) {
    const effects: HazardEffect = {
      electricalInterference: 0.5 * severity,
      navigationDisruption: 0.4 * severity,
      visibilityReduction: 0.6 * severity,
      shieldDrain: 10 * severity
    };

    super(
      id,
      HazardType.ION_STORM,
      'Ion Storm',
      severity,
      position,
      radius,
      effects,
      duration
    );

    this.velocity = velocity;
  }

  update(deltaTime: number): void {
    super.update(deltaTime);

    // Ion storms move
    this.position.x += this.velocity.x * deltaTime;
    this.position.y += this.velocity.y * deltaTime;
    this.position.z += this.velocity.z * deltaTime;

    // They also grow and shrink
    const growthRate = Math.sin(this.timeElapsed * 0.1) * 100;
    this.radius += growthRate * deltaTime;
    this.radius = Math.max(1000, this.radius); // Minimum size
  }
}

/**
 * Hazard System Manager
 */
export class HazardSystem {
  private hazards: Map<string, Hazard> = new Map();
  private rng: { next: () => number; range: (min: number, max: number) => number; choice: <T>(arr: T[]) => T; bool: (p?: number) => boolean };

  constructor(seed: number = Date.now()) {
    let s = seed;
    this.rng = {
      next: () => {
        s = (s * 9301 + 49297) % 233280;
        return s / 233280;
      },
      range: (min: number, max: number) => min + this.rng.next() * (max - min),
      choice: <T>(arr: T[]): T => arr[Math.floor(this.rng.next() * arr.length)],
      bool: (p: number = 0.5) => this.rng.next() < p
    };
  }

  /**
   * Add a hazard
   */
  addHazard(hazard: Hazard): void {
    this.hazards.set(hazard.id, hazard);
  }

  /**
   * Remove a hazard
   */
  removeHazard(id: string): void {
    this.hazards.delete(id);
  }

  /**
   * Get all active hazards
   */
  getActiveHazards(): Hazard[] {
    return Array.from(this.hazards.values()).filter(h => h.active);
  }

  /**
   * Get hazards affecting a point
   */
  getHazardsAt(point: Vector3): Hazard[] {
    return this.getActiveHazards().filter(h => h.isPointInHazard(point));
  }

  /**
   * Calculate combined effects at a point
   */
  getCombinedEffectsAt(point: Vector3, deltaTime: number): HazardEffect {
    const combined: HazardEffect = {};
    const hazards = this.getHazardsAt(point);

    for (const hazard of hazards) {
      const effects = hazard.applyEffects(point, deltaTime);

      // Sum damage effects
      combined.hullDamagePerSecond = (combined.hullDamagePerSecond || 0) + (effects.hullDamagePerSecond || 0);
      combined.radiationPerSecond = (combined.radiationPerSecond || 0) + (effects.radiationPerSecond || 0);
      combined.heatPerSecond = (combined.heatPerSecond || 0) + (effects.heatPerSecond || 0);
      combined.shieldDrain = (combined.shieldDrain || 0) + (effects.shieldDrain || 0);

      // Take maximum for interference/disruption effects
      combined.electricalInterference = Math.max(
        combined.electricalInterference || 0,
        effects.electricalInterference || 0
      );
      combined.navigationDisruption = Math.max(
        combined.navigationDisruption || 0,
        effects.navigationDisruption || 0
      );
      combined.thrustPenalty = Math.max(
        combined.thrustPenalty || 0,
        effects.thrustPenalty || 0
      );
      combined.visibilityReduction = Math.max(
        combined.visibilityReduction || 0,
        effects.visibilityReduction || 0
      );
    }

    return combined;
  }

  /**
   * Update all hazards
   */
  update(deltaTime: number): void {
    for (const hazard of this.hazards.values()) {
      hazard.update(deltaTime);

      // Remove inactive temporary hazards
      if (!hazard.active && hazard.duration) {
        this.hazards.delete(hazard.id);
      }
    }
  }

  /**
   * Generate radiation belts for a planet
   */
  generateRadiationBelts(planet: CelestialBody): RadiationBelt[] {
    const belts: RadiationBelt[] = [];

    // Large planets with magnetic fields get radiation belts
    if (planet.physical.mass < 5e24) return belts; // Too small

    const numBelts = this.rng.bool(0.7) ? (this.rng.bool(0.5) ? 2 : 1) : 0;

    for (let i = 0; i < numBelts; i++) {
      const innerRadius = planet.physical.radius * this.rng.range(1.5, 3);
      const outerRadius = planet.physical.radius * this.rng.range(3.5, 6);
      const severity = this.rng.choice([
        HazardSeverity.LOW,
        HazardSeverity.MODERATE,
        HazardSeverity.HIGH
      ]);

      const belt = new RadiationBelt(
        `${planet.id}-rad-belt-${i}`,
        planet,
        innerRadius,
        outerRadius,
        severity
      );

      belts.push(belt);
      this.addHazard(belt);
    }

    return belts;
  }

  /**
   * Generate debris field
   */
  generateDebrisField(
    id: string,
    position: Vector3,
    radius: number,
    density: number = 0.5 // 0-1
  ): DebrisField {
    const debrisCount = Math.floor(density * 1000);
    const velocity: Vector3 = {
      x: this.rng.range(-100, 100),
      y: this.rng.range(-100, 100),
      z: this.rng.range(-100, 100)
    };

    const severity = density < 0.3 ? HazardSeverity.LOW :
                    density < 0.6 ? HazardSeverity.MODERATE :
                    HazardSeverity.HIGH;

    const field = new DebrisField(
      id,
      'Debris Field',
      position,
      radius,
      debrisCount,
      velocity,
      severity
    );

    this.addHazard(field);
    return field;
  }

  /**
   * Trigger a solar storm
   */
  triggerSolarStorm(star: CelestialBody, severity: HazardSeverity, duration: number): SolarStorm {
    const storm = new SolarStorm(
      `solar-storm-${Date.now()}`,
      star,
      severity,
      duration
    );

    this.addHazard(storm);
    return storm;
  }

  /**
   * Spawn random ion storm
   */
  spawnIonStorm(position: Vector3, radius: number, duration: number): IonStorm {
    const velocity: Vector3 = {
      x: this.rng.range(-1000, 1000),
      y: this.rng.range(-1000, 1000),
      z: this.rng.range(-1000, 1000)
    };

    const severity = this.rng.choice([
      HazardSeverity.MODERATE,
      HazardSeverity.HIGH,
      HazardSeverity.EXTREME
    ]);

    const storm = new IonStorm(
      `ion-storm-${Date.now()}`,
      position,
      radius,
      velocity,
      severity,
      duration
    );

    this.addHazard(storm);
    return storm;
  }

  /**
   * Generate hazards for a star system
   */
  generateSystemHazards(
    systemId: string,
    bodies: CelestialBody[]
  ): void {
    // Radiation belts for planets
    bodies.forEach(body => {
      if (body.type === 'PLANET') {
        this.generateRadiationBelts(body);
      }
    });

    // Random debris fields in asteroid belts
    const asteroidBodies = bodies.filter(b => b.type === 'ASTEROID');
    if (asteroidBodies.length > 5) {
      // Create a few debris concentrations
      const numFields = Math.floor(this.rng.range(1, 4));
      for (let i = 0; i < numFields; i++) {
        const asteroid = this.rng.choice(asteroidBodies);
        this.generateDebrisField(
          `${systemId}-debris-${i}`,
          asteroid.position,
          this.rng.range(5e6, 5e7),
          this.rng.range(0.3, 0.8)
        );
      }
    }

    // Occasional ion storms
    if (this.rng.bool(0.3)) {
      const randomBody = this.rng.choice(bodies);
      const offset = {
        x: this.rng.range(-1e9, 1e9),
        y: this.rng.range(-1e9, 1e9),
        z: this.rng.range(-1e9, 1e9)
      };
      const stormPos = {
        x: randomBody.position.x + offset.x,
        y: randomBody.position.y + offset.y,
        z: randomBody.position.z + offset.z
      };
      this.spawnIonStorm(stormPos, this.rng.range(1e7, 1e8), this.rng.range(3600, 86400));
    }
  }
}
