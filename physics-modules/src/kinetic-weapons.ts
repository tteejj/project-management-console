/**
 * Kinetic Weapons System
 *
 * Implements ballistic weapons including:
 * - Autocannons with various ammunition types
 * - Railguns with electromagnetic acceleration
 * - Mass drivers for capital ship combat
 * - Turret tracking and rotation physics
 * - Projectile ballistics
 * - Ammunition management with magazines
 * - Recoil effects on spacecraft
 */

export type AmmoType = 'AP' | 'HE' | 'Incendiary' | 'Proximity' | 'EMP' | 'Slug';
export type WeaponType = 'autocannon' | 'railgun' | 'mass_driver';
export type FireMode = 'safe' | 'single' | 'burst' | 'auto';
export type TurretStatus = 'ready' | 'tracking' | 'firing' | 'reloading' | 'overheated' | 'jammed' | 'damaged';

/**
 * Ammunition in magazine
 */
export interface Ammunition {
  type: AmmoType;
  count: number;
  mass: number; // kg per round
  muzzleVelocity: number; // m/s
  damage: number; // base damage value
  penetration: number; // armor penetration value
  blastRadius: number; // meters (0 for kinetic)
}

/**
 * Magazine system
 */
export interface Magazine {
  id: string;
  weaponType: WeaponType;
  capacity: number;
  ammunition: Ammunition[];
  autoloaderStatus: 'ready' | 'loading' | 'jammed' | 'damaged';
  reloadProgress: number; // 0-1
  reloadTimeSeconds: number;
  location: { x: number; y: number; z: number }; // For CoM calculation
}

/**
 * Turret mount with rotation mechanics
 */
export interface Turret {
  id: string;
  name: string;
  location: { x: number; y: number; z: number }; // Mount point on ship

  // Current pointing direction (relative to ship)
  azimuth: number; // degrees, 0 = forward
  elevation: number; // degrees, 0 = level

  // Rotation rates
  azimuthRate: number; // current °/s
  elevationRate: number; // current °/s
  maxAzimuthRate: number; // max °/s
  maxElevationRate: number; // max °/s

  // Arc limits
  azimuthMin: number; // degrees
  azimuthMax: number; // degrees
  elevationMin: number; // degrees
  elevationMax: number; // degrees

  // Stabilization
  gyroStabilized: boolean;
  trackingAccuracy: number; // degrees error

  // Power
  powerDraw: number; // W, varies with rotation
  basePowerW: number; // idle power
  rotationPowerW: number; // power per °/s
}

/**
 * Projectile in flight
 */
export interface Projectile {
  id: string;
  weaponId: string;
  ammoType: AmmoType;

  // Physics
  position: { x: number; y: number; z: number }; // km
  velocity: { x: number; y: number; z: number }; // m/s
  mass: number; // kg

  // Properties
  damage: number;
  penetration: number;
  blastRadius: number;

  // State
  launchTime: number; // seconds
  lifetime: number; // seconds until self-destruct
  active: boolean;
  fusedProximity: boolean; // for proximity fuse ammo
}

/**
 * Target for fire control
 */
export interface Target {
  id: string;
  position: { x: number; y: number; z: number }; // km
  velocity: { x: number; y: number; z: number }; // m/s
  radius: number; // m, for hit detection
  threat: 'low' | 'medium' | 'high' | 'critical';
}

/**
 * Firing solution calculated by fire control
 */
export interface FiringSolution {
  valid: boolean;
  targetId: string;

  // Aiming angles
  azimuth: number; // degrees
  elevation: number; // degrees

  // Ballistics
  timeToTarget: number; // seconds
  rangeToTarget: number; // km
  interceptPoint: { x: number; y: number; z: number }; // km

  // Feasibility
  inArc: boolean;
  inRange: boolean;
  canTrack: boolean; // turret fast enough
  hitProbability: number; // 0-1

  // Constraints
  reasons: string[]; // why solution is invalid
}

/**
 * Kinetic weapon (autocannon, railgun, mass driver)
 */
export class KineticWeapon {
  public id: string;
  public name: string;
  public type: WeaponType;
  public turret: Turret;
  public magazine: Magazine;

  // Weapon characteristics
  public caliber: number; // mm
  public rateOfFire: number; // rounds per minute
  public maxRange: number; // km
  public baseMuzzleVelocity: number; // m/s
  public barrelLength: number; // m

  // State
  public status: TurretStatus = 'ready';
  public fireMode: FireMode = 'safe';
  public temperature: number = 293; // Kelvin
  public maxTemperature: number = 800; // Kelvin, overheat threshold
  public coolingRate: number = 50; // K/s when not firing
  public heatPerShot: number = 100; // Kelvin increase per shot

  // Firing
  public timeSinceLastShot: number = 999;
  public roundsInBurst: number = 0;
  public burstSize: number = 5;
  public currentTarget: Target | null = null;

  // Railgun specific
  public isRailgun: boolean = false;
  public capacitorCharge: number = 0; // 0-1
  public capacitorChargeRate: number = 0.1; // per second
  public shotsUntilOverheat: number = 10;
  public shotsFired: number = 0;

  // Power requirements
  public powerConsumption: number = 0; // current W
  public idlePowerW: number = 100;
  public firingPowerW: number = 500; // autocannon
  public railgunShotMJ: number = 25; // railgun per shot

  constructor(config: {
    id: string;
    name: string;
    type: WeaponType;
    caliber: number;
    rateOfFire: number;
    maxRange: number;
    muzzleVelocity: number;
    turretConfig: Partial<Turret>;
    magazineConfig: Partial<Magazine>;
  }) {
    this.id = config.id;
    this.name = config.name;
    this.type = config.type;
    this.caliber = config.caliber;
    this.rateOfFire = config.rateOfFire;
    this.maxRange = config.maxRange;
    this.baseMuzzleVelocity = config.muzzleVelocity;
    this.barrelLength = config.caliber / 1000 * 50; // Simplified: 50 calibers long

    this.isRailgun = config.type === 'railgun';

    // Initialize turret
    this.turret = {
      id: config.id + '_turret',
      name: config.name + ' Turret',
      location: config.turretConfig.location || { x: 0, y: 0, z: 5 },
      azimuth: 0,
      elevation: 0,
      azimuthRate: 0,
      elevationRate: 0,
      maxAzimuthRate: config.turretConfig.maxAzimuthRate || 30,
      maxElevationRate: config.turretConfig.maxElevationRate || 30,
      azimuthMin: config.turretConfig.azimuthMin ?? -180,
      azimuthMax: config.turretConfig.azimuthMax ?? 180,
      elevationMin: config.turretConfig.elevationMin ?? -30,
      elevationMax: config.turretConfig.elevationMax ?? 80,
      gyroStabilized: config.turretConfig.gyroStabilized ?? true,
      trackingAccuracy: config.turretConfig.trackingAccuracy || 0.5,
      powerDraw: 0,
      basePowerW: 50,
      rotationPowerW: 10
    };

    // Initialize magazine
    this.magazine = {
      id: config.id + '_mag',
      weaponType: config.type,
      capacity: config.magazineConfig.capacity || 500,
      ammunition: config.magazineConfig.ammunition || this.getDefaultAmmo(config.type),
      autoloaderStatus: 'ready',
      reloadProgress: 0,
      reloadTimeSeconds: config.magazineConfig.reloadTimeSeconds || 10,
      location: config.turretConfig.location || { x: 0, y: 0, z: 5 }
    };

    // Set weapon-specific parameters
    if (this.isRailgun) {
      this.firingPowerW = 0; // Railgun uses capacitor
      this.shotsUntilOverheat = 5;
    }
  }

  /**
   * Get default ammunition for weapon type
   */
  private getDefaultAmmo(type: WeaponType): Ammunition[] {
    if (type === 'autocannon') {
      return [
        {
          type: 'AP',
          count: 200,
          mass: 0.5,
          muzzleVelocity: this.baseMuzzleVelocity,
          damage: 100,
          penetration: 150,
          blastRadius: 0
        },
        {
          type: 'HE',
          count: 200,
          mass: 0.5,
          muzzleVelocity: this.baseMuzzleVelocity * 0.9,
          damage: 150,
          penetration: 50,
          blastRadius: 10
        },
        {
          type: 'Proximity',
          count: 100,
          mass: 0.6,
          muzzleVelocity: this.baseMuzzleVelocity * 0.85,
          damage: 80,
          penetration: 30,
          blastRadius: 50
        }
      ];
    } else if (type === 'railgun') {
      return [
        {
          type: 'Slug',
          count: 30,
          mass: 5.0,
          muzzleVelocity: this.baseMuzzleVelocity,
          damage: 1000,
          penetration: 2000,
          blastRadius: 0
        }
      ];
    } else { // mass_driver
      return [
        {
          type: 'Slug',
          count: 10,
          mass: 500,
          muzzleVelocity: this.baseMuzzleVelocity,
          damage: 50000,
          penetration: 100000,
          blastRadius: 0
        }
      ];
    }
  }

  /**
   * Update weapon systems
   */
  public update(dt: number): void {
    this.timeSinceLastShot += dt;

    // Cool down
    if (this.temperature > 293) {
      this.temperature = Math.max(293, this.temperature - this.coolingRate * dt);
    }

    // Check overheating
    if (this.temperature >= this.maxTemperature) {
      this.status = 'overheated';
    } else if (this.status === 'overheated' && this.temperature < this.maxTemperature * 0.8) {
      this.status = 'ready';
      this.shotsFired = 0;
    }

    // Reload progress
    if (this.magazine.autoloaderStatus === 'loading') {
      this.magazine.reloadProgress += dt / this.magazine.reloadTimeSeconds;
      if (this.magazine.reloadProgress >= 1.0) {
        this.magazine.reloadProgress = 0;
        this.magazine.autoloaderStatus = 'ready';
        this.status = 'ready';
      }
    }

    // Railgun capacitor charge
    if (this.isRailgun && this.capacitorCharge < 1.0) {
      this.capacitorCharge = Math.min(1.0, this.capacitorCharge + this.capacitorChargeRate * dt);
    }

    // Calculate power consumption
    this.powerConsumption = this.turret.basePowerW;
    const rotationPower = (Math.abs(this.turret.azimuthRate) + Math.abs(this.turret.elevationRate))
                         * this.turret.rotationPowerW;
    this.powerConsumption += rotationPower;

    if (this.magazine.autoloaderStatus === 'loading') {
      this.powerConsumption += 300; // Autoloader power
    }

    // Update turret rotation (decay if not being commanded)
    this.turret.azimuthRate *= 0.95;
    this.turret.elevationRate *= 0.95;
    this.turret.powerDraw = this.powerConsumption;
  }

  /**
   * Calculate firing solution for target
   */
  public calculateFiringSolution(
    target: Target,
    shipPosition: { x: number; y: number; z: number },
    shipVelocity: { x: number; y: number; z: number }
  ): FiringSolution {
    const reasons: string[] = [];

    // Get selected ammo
    const ammo = this.getSelectedAmmo();
    if (!ammo || ammo.count === 0) {
      reasons.push('No ammunition');
      return { valid: false, targetId: target.id, azimuth: 0, elevation: 0,
               timeToTarget: 0, rangeToTarget: 0, interceptPoint: { x: 0, y: 0, z: 0 },
               inArc: false, inRange: false, canTrack: false, hitProbability: 0, reasons };
    }

    // Relative position and velocity (target - ship)
    const relPos = {
      x: target.position.x - shipPosition.x,
      y: target.position.y - shipPosition.y,
      z: target.position.z - shipPosition.z
    };

    const relVel = {
      x: target.velocity.x - shipVelocity.x,
      y: target.velocity.y - shipVelocity.y,
      z: target.velocity.z - shipVelocity.z
    };

    // Current range
    const range = Math.sqrt(relPos.x**2 + relPos.y**2 + relPos.z**2);

    // Check range
    const inRange = range <= this.maxRange;
    if (!inRange) {
      reasons.push(`Out of range: ${range.toFixed(1)}km > ${this.maxRange}km`);
    }

    // Solve intercept triangle
    // We need to find time t such that:
    // |relPos + relVel * t| = projectileSpeed * t
    const projectileSpeed = ammo.muzzleVelocity / 1000; // km/s
    const timeToIntercept = this.solveInterceptTime(relPos, relVel, projectileSpeed);

    if (timeToIntercept < 0) {
      reasons.push('No intercept solution (target too fast)');
      return { valid: false, targetId: target.id, azimuth: 0, elevation: 0,
               timeToTarget: 0, rangeToTarget: range, interceptPoint: { x: 0, y: 0, z: 0 },
               inArc: false, inRange, canTrack: false, hitProbability: 0, reasons };
    }

    // Intercept point
    const interceptPoint = {
      x: target.position.x + relVel.x * timeToIntercept,
      y: target.position.y + relVel.y * timeToIntercept,
      z: target.position.z + relVel.z * timeToIntercept
    };

    // Direction to intercept point (relative to ship)
    const aimVector = {
      x: interceptPoint.x - shipPosition.x,
      y: interceptPoint.y - shipPosition.y,
      z: interceptPoint.z - shipPosition.z
    };

    // Convert to azimuth/elevation
    // Assuming ship coordinate system: X=right, Y=up, Z=forward
    const azimuth = Math.atan2(aimVector.x, aimVector.z) * 180 / Math.PI;
    const horizontalDist = Math.sqrt(aimVector.x**2 + aimVector.z**2);
    const elevation = Math.atan2(aimVector.y, horizontalDist) * 180 / Math.PI;

    // Check if in turret arc
    const inArc = this.isInArc(azimuth, elevation);
    if (!inArc) {
      reasons.push(`Out of arc: Az=${azimuth.toFixed(1)}° El=${elevation.toFixed(1)}°`);
    }

    // Check if turret can track fast enough
    const azDelta = this.angleDifference(azimuth, this.turret.azimuth);
    const elDelta = elevation - this.turret.elevation;
    const timeToTrack = Math.max(
      Math.abs(azDelta) / this.turret.maxAzimuthRate,
      Math.abs(elDelta) / this.turret.maxElevationRate
    );
    const canTrack = timeToTrack < 2.0; // Can reach within 2 seconds
    if (!canTrack) {
      reasons.push(`Turret too slow: ${timeToTrack.toFixed(1)}s to track`);
    }

    // Hit probability calculation
    let hitProbability = 1.0;

    // Range factor
    hitProbability *= Math.max(0, 1 - (range / this.maxRange));

    // Tracking error
    const trackingError = this.turret.trackingAccuracy; // degrees
    const targetAngularSize = Math.atan(target.radius / (range * 1000)) * 180 / Math.PI;
    hitProbability *= Math.max(0.1, Math.min(1.0, targetAngularSize / trackingError));

    // Time factor (harder to hit fast-moving targets)
    const targetSpeed = Math.sqrt(relVel.x**2 + relVel.y**2 + relVel.z**2);
    hitProbability *= Math.max(0.2, 1.0 - targetSpeed / 50); // Penalty above 50 km/s

    const valid = inRange && inArc && canTrack && hitProbability > 0.1;

    return {
      valid,
      targetId: target.id,
      azimuth,
      elevation,
      timeToTarget: timeToIntercept,
      rangeToTarget: range,
      interceptPoint,
      inArc,
      inRange,
      canTrack,
      hitProbability,
      reasons
    };
  }

  /**
   * Solve intercept time using quadratic formula
   */
  private solveInterceptTime(
    relPos: { x: number; y: number; z: number },
    relVel: { x: number; y: number; z: number },
    projectileSpeed: number
  ): number {
    // Quadratic equation: a*t² + b*t + c = 0
    const a = relVel.x**2 + relVel.y**2 + relVel.z**2 - projectileSpeed**2;
    const b = 2 * (relPos.x * relVel.x + relPos.y * relVel.y + relPos.z * relVel.z);
    const c = relPos.x**2 + relPos.y**2 + relPos.z**2;

    const discriminant = b**2 - 4*a*c;
    if (discriminant < 0) {
      return -1; // No solution
    }

    const t1 = (-b + Math.sqrt(discriminant)) / (2*a);
    const t2 = (-b - Math.sqrt(discriminant)) / (2*a);

    // Return smallest positive time
    if (t1 > 0 && t2 > 0) {
      return Math.min(t1, t2);
    } else if (t1 > 0) {
      return t1;
    } else if (t2 > 0) {
      return t2;
    } else {
      return -1;
    }
  }

  /**
   * Check if angles are within turret arc
   */
  private isInArc(azimuth: number, elevation: number): boolean {
    const azInArc = azimuth >= this.turret.azimuthMin && azimuth <= this.turret.azimuthMax;
    const elInArc = elevation >= this.turret.elevationMin && elevation <= this.turret.elevationMax;
    return azInArc && elInArc;
  }

  /**
   * Calculate shortest angular difference
   */
  private angleDifference(a: number, b: number): number {
    let diff = a - b;
    while (diff > 180) diff -= 360;
    while (diff < -180) diff += 360;
    return diff;
  }

  /**
   * Command turret to track solution
   */
  public trackSolution(solution: FiringSolution, dt: number): void {
    if (!solution.valid) return;

    const azDelta = this.angleDifference(solution.azimuth, this.turret.azimuth);
    const elDelta = solution.elevation - this.turret.elevation;

    // Simple proportional control
    const kP = 2.0;
    this.turret.azimuthRate = Math.max(-this.turret.maxAzimuthRate,
      Math.min(this.turret.maxAzimuthRate, azDelta * kP));
    this.turret.elevationRate = Math.max(-this.turret.maxElevationRate,
      Math.min(this.turret.maxElevationRate, elDelta * kP));

    // Update angles
    this.turret.azimuth += this.turret.azimuthRate * dt;
    this.turret.elevation += this.turret.elevationRate * dt;

    // Clamp to limits
    this.turret.azimuth = Math.max(this.turret.azimuthMin,
      Math.min(this.turret.azimuthMax, this.turret.azimuth));
    this.turret.elevation = Math.max(this.turret.elevationMin,
      Math.min(this.turret.elevationMax, this.turret.elevation));

    // Check if on target
    if (Math.abs(azDelta) < this.turret.trackingAccuracy &&
        Math.abs(elDelta) < this.turret.trackingAccuracy) {
      this.status = 'tracking';
    }
  }

  /**
   * Fire weapon at current solution
   */
  public fire(
    solution: FiringSolution,
    shipPosition: { x: number; y: number; z: number },
    shipVelocity: { x: number; y: number; z: number }
  ): Projectile | null {
    // Check if can fire
    if (this.fireMode === 'safe') return null;
    if (this.status === 'overheated' || this.status === 'jammed' || this.status === 'damaged') return null;
    if (this.magazine.autoloaderStatus !== 'ready') return null;

    const ammo = this.getSelectedAmmo();
    if (!ammo || ammo.count === 0) return null;

    // Check rate of fire
    const fireInterval = 60.0 / this.rateOfFire; // seconds between shots
    if (this.timeSinceLastShot < fireInterval) return null;

    // Railgun needs charged capacitor
    if (this.isRailgun && this.capacitorCharge < 1.0) return null;

    // Fire!
    ammo.count--;
    this.timeSinceLastShot = 0;
    this.temperature += this.heatPerShot;
    this.shotsFired++;
    this.status = 'firing';

    if (this.isRailgun) {
      this.capacitorCharge = 0;
    }

    // Start reload if magazine empty
    if (this.getTotalRounds() === 0) {
      this.magazine.autoloaderStatus = 'loading';
      this.status = 'reloading';
    }

    // Calculate projectile initial velocity (ship + muzzle velocity in aim direction)
    const aimRad = {
      azimuth: solution.azimuth * Math.PI / 180,
      elevation: solution.elevation * Math.PI / 180
    };

    const muzzleVelVector = {
      x: Math.sin(aimRad.azimuth) * Math.cos(aimRad.elevation) * ammo.muzzleVelocity,
      y: Math.sin(aimRad.elevation) * ammo.muzzleVelocity,
      z: Math.cos(aimRad.azimuth) * Math.cos(aimRad.elevation) * ammo.muzzleVelocity
    };

    const projectile: Projectile = {
      id: `proj_${this.id}_${Date.now()}`,
      weaponId: this.id,
      ammoType: ammo.type,
      position: { ...shipPosition },
      velocity: {
        x: shipVelocity.x + muzzleVelVector.x,
        y: shipVelocity.y + muzzleVelVector.y,
        z: shipVelocity.z + muzzleVelVector.z
      },
      mass: ammo.mass,
      damage: ammo.damage,
      penetration: ammo.penetration,
      blastRadius: ammo.blastRadius,
      launchTime: 0,
      lifetime: solution.rangeToTarget / (ammo.muzzleVelocity / 1000) * 3, // 3x time to target
      active: true,
      fusedProximity: ammo.type === 'Proximity'
    };

    return projectile;
  }

  /**
   * Get currently selected ammunition type
   */
  private getSelectedAmmo(): Ammunition | null {
    // For now, just return first available ammo
    for (const ammo of this.magazine.ammunition) {
      if (ammo.count > 0) {
        return ammo;
      }
    }
    return null;
  }

  /**
   * Get total rounds remaining
   */
  public getTotalRounds(): number {
    return this.magazine.ammunition.reduce((sum, ammo) => sum + ammo.count, 0);
  }

  /**
   * Calculate recoil force on spacecraft
   */
  public getRecoilForce(): { x: number; y: number; z: number } {
    if (this.timeSinceLastShot > 0.1) {
      return { x: 0, y: 0, z: 0 };
    }

    const ammo = this.getSelectedAmmo();
    if (!ammo) return { x: 0, y: 0, z: 0 };

    // F = m * v / Δt (momentum change over time)
    const impulse = ammo.mass * ammo.muzzleVelocity;
    const deltaT = 0.01; // 10ms impulse duration
    const force = impulse / deltaT;

    // Direction is opposite of barrel pointing
    const aimRad = {
      azimuth: this.turret.azimuth * Math.PI / 180,
      elevation: this.turret.elevation * Math.PI / 180
    };

    return {
      x: -Math.sin(aimRad.azimuth) * Math.cos(aimRad.elevation) * force,
      y: -Math.sin(aimRad.elevation) * force,
      z: -Math.cos(aimRad.azimuth) * Math.cos(aimRad.elevation) * force
    };
  }

  /**
   * Get weapon state for UI
   */
  public getState() {
    return {
      id: this.id,
      name: this.name,
      type: this.type,
      status: this.status,
      fireMode: this.fireMode,

      // Turret
      turret: {
        azimuth: this.turret.azimuth,
        elevation: this.turret.elevation,
        azimuthRate: this.turret.azimuthRate,
        elevationRate: this.turret.elevationRate,
        onTarget: this.status === 'tracking'
      },

      // Ammunition
      ammunition: this.magazine.ammunition.map(a => ({
        type: a.type,
        count: a.count,
        capacity: this.magazine.capacity
      })),
      totalRounds: this.getTotalRounds(),

      // Status
      temperature: this.temperature,
      maxTemperature: this.maxTemperature,
      temperaturePercent: (this.temperature - 293) / (this.maxTemperature - 293),

      // Railgun
      capacitorCharge: this.capacitorCharge,

      // Reload
      reloading: this.magazine.autoloaderStatus === 'loading',
      reloadProgress: this.magazine.reloadProgress,

      // Power
      powerDraw: this.powerConsumption
    };
  }
}

/**
 * Projectile simulation
 */
export class ProjectileManager {
  private projectiles: Map<string, Projectile> = new Map();
  private simulationTime: number = 0;

  // Gravitational acceleration vector (Critical Fix: Projectile Gravity Physics)
  // Default to zero gravity (deep space), set by spacecraft for planetary operations
  private gravity: { x: number; y: number; z: number } = { x: 0, y: 0, z: 0 };

  /**
   * Set gravitational acceleration
   * Called by spacecraft to set local gravity field
   * Critical Fix: Projectile Gravity Physics
   */
  public setGravity(gravity: { x: number; y: number; z: number }): void {
    this.gravity = { ...gravity };
  }

  /**
   * Add projectile to simulation
   */
  public addProjectile(projectile: Projectile): void {
    projectile.launchTime = this.simulationTime;
    this.projectiles.set(projectile.id, projectile);
  }

  /**
   * Update all projectiles
   */
  public update(dt: number): void {
    this.simulationTime += dt;

    for (const [id, proj] of this.projectiles) {
      if (!proj.active) {
        this.projectiles.delete(id);
        continue;
      }

      // Update velocity with gravity (Critical Fix: Projectile Gravity Physics)
      // v = v0 + a*t
      proj.velocity.x += this.gravity.x * dt;
      proj.velocity.y += this.gravity.y * dt;
      proj.velocity.z += this.gravity.z * dt;

      // Update position using current velocity
      // s = v*t (using updated velocity for semi-implicit Euler integration)
      proj.position.x += proj.velocity.x * dt / 1000; // m/s to km
      proj.position.y += proj.velocity.y * dt / 1000;
      proj.position.z += proj.velocity.z * dt / 1000;

      // Check lifetime
      if (this.simulationTime - proj.launchTime > proj.lifetime) {
        proj.active = false;
      }
    }
  }

  /**
   * Check for hits against targets
   */
  public checkHits(targets: Target[]): Array<{ projectileId: string; targetId: string; damage: number }> {
    const hits: Array<{ projectileId: string; targetId: string; damage: number }> = [];

    for (const proj of this.projectiles.values()) {
      if (!proj.active) continue;

      for (const target of targets) {
        const dx = (proj.position.x - target.position.x) * 1000; // km to m
        const dy = (proj.position.y - target.position.y) * 1000;
        const dz = (proj.position.z - target.position.z) * 1000;
        const distance = Math.sqrt(dx**2 + dy**2 + dz**2);

        // Direct hit
        if (distance <= target.radius) {
          hits.push({
            projectileId: proj.id,
            targetId: target.id,
            damage: proj.damage
          });
          proj.active = false;
        }
        // Proximity fuse
        else if (proj.fusedProximity && distance <= proj.blastRadius) {
          const falloff = 1.0 - (distance / proj.blastRadius);
          hits.push({
            projectileId: proj.id,
            targetId: target.id,
            damage: proj.damage * falloff
          });
          proj.active = false;
        }
      }
    }

    return hits;
  }

  /**
   * Get all active projectiles
   */
  public getProjectiles(): Projectile[] {
    return Array.from(this.projectiles.values());
  }

  /**
   * Clear all projectiles
   */
  public clear(): void {
    this.projectiles.clear();
  }
}
