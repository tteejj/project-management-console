/**
 * Missile Weapons System
 *
 * Implements guided missile systems including:
 * - Short, Medium, Long Range Missiles and Torpedoes
 * - Multiple guidance modes (inertial, radar, IR, optical)
 * - Propulsion physics with fuel consumption
 * - Proportional navigation guidance
 * - Counter-countermeasures
 * - Launch systems (VLS, hardpoint, internal bay)
 */

export type MissileType = 'SRM' | 'MRM' | 'LRM' | 'Torpedo';
export type GuidanceMode = 'inertial' | 'command' | 'active_radar' | 'passive_radar' | 'IR' | 'optical' | 'proportional_nav';
export type WarheadType = 'HE' | 'shaped_charge' | 'fragmentation' | 'EMP' | 'nuclear';
export type MissileStatus = 'ready' | 'pre_flight' | 'launched' | 'boost' | 'midcourse' | 'terminal' | 'hit' | 'miss';
export type LauncherType = 'VLS' | 'hardpoint' | 'internal_bay';

/**
 * Missile guidance computer
 */
export interface GuidanceComputer {
  mode: GuidanceMode;
  targetLocked: boolean;
  lockStrength: number; // 0-1
  seekerFOV: number; // degrees
  seekerRange: number; // km
  navigationGain: number; // proportional navigation constant (typically 3-5)
}

/**
 * Missile propulsion system
 */
export interface MissilePropulsion {
  thrust: number; // Newtons
  specificImpulse: number; // seconds
  burnTime: number; // seconds
  fuelMass: number; // kg
  fuelRemaining: number; // kg
  burning: boolean;
  exhaustVelocity: number; // m/s
}

/**
 * Missile warhead
 */
export interface Warhead {
  type: WarheadType;
  mass: number; // kg
  yield: number; // TNT equivalent in kg (or kilotons for nuclear)
  blastRadius: number; // meters
  fragmentationRadius: number; // meters for frag warheads
  armorPenetration: number; // mm RHA for shaped charge
}

/**
 * Missile launcher
 */
export interface MissileLauncher {
  id: string;
  type: LauncherType;
  capacity: number;
  loaded: number;
  reloadTimeSeconds: number;
  reloadProgress: number; // 0-1
  location: { x: number; y: number; z: number };
  powerDraw: number; // W
}

/**
 * Missile definition
 */
export class Missile {
  public id: string;
  public name: string;
  public type: MissileType;
  public status: MissileStatus = 'ready';

  // Physical properties
  public position: { x: number; y: number; z: number }; // km
  public velocity: { x: number; y: number; z: number }; // m/s
  public dryMass: number; // kg
  public length: number; // meters
  public diameter: number; // meters

  // Systems
  public guidance: GuidanceComputer;
  public propulsion: MissilePropulsion;
  public warhead: Warhead;

  // Target
  public targetId: string | null = null;
  public targetPosition: { x: number; y: number; z: number } | null = null;
  public targetVelocity: { x: number; y: number; z: number } | null = null;

  // Flight state
  public launchTime: number = 0;
  public flightTime: number = 0;
  public distanceToTarget: number = 999;
  public closingRate: number = 0;

  // Countermeasures
  public chaffEffectiveness: number = 0; // 0-1, how much chaff affects us
  public flareEffectiveness: number = 0; // 0-1, how much flares affect us
  public ecmEffectiveness: number = 0; // 0-1, how much jamming affects us

  constructor(config: {
    type: MissileType;
    name: string;
    position: { x: number; y: number; z: number };
    velocity: { x: number; y: number; z: number };
  }) {
    this.id = `missile_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    this.name = config.name;
    this.type = config.type;
    this.position = { ...config.position };
    this.velocity = { ...config.velocity };

    // Set type-specific parameters
    const specs = this.getMissileSpecs(config.type);
    this.dryMass = specs.dryMass;
    this.length = specs.length;
    this.diameter = specs.diameter;

    this.guidance = {
      mode: specs.guidanceMode,
      targetLocked: false,
      lockStrength: 0,
      seekerFOV: specs.seekerFOV,
      seekerRange: specs.seekerRange,
      navigationGain: 4.0 // N' = 4 is typical
    };

    this.propulsion = {
      thrust: specs.thrust,
      specificImpulse: specs.isp,
      burnTime: specs.burnTime,
      fuelMass: specs.fuelMass,
      fuelRemaining: specs.fuelMass,
      burning: false,
      exhaustVelocity: specs.isp * 9.81 // m/s
    };

    this.warhead = {
      type: specs.warheadType,
      mass: specs.warheadMass,
      yield: specs.warheadYield,
      blastRadius: specs.blastRadius,
      fragmentationRadius: specs.fragRadius,
      armorPenetration: specs.penetration
    };

    // Set CM vulnerabilities based on guidance mode
    if (this.guidance.mode === 'active_radar' || this.guidance.mode === 'passive_radar') {
      this.chaffEffectiveness = 0.7;
      this.ecmEffectiveness = 0.6;
    } else if (this.guidance.mode === 'IR') {
      this.flareEffectiveness = 0.8;
    } else if (this.guidance.mode === 'optical') {
      // Optical is hard to spoof
      this.chaffEffectiveness = 0.1;
      this.flareEffectiveness = 0.2;
    }
  }

  /**
   * Get missile specifications by type
   */
  private getMissileSpecs(type: MissileType) {
    const specs = {
      'SRM': {
        dryMass: 50, fuelMass: 30, length: 2.0, diameter: 0.15,
        thrust: 15000, isp: 220, burnTime: 15,
        guidanceMode: 'IR' as GuidanceMode, seekerFOV: 30, seekerRange: 10,
        warheadType: 'HE' as WarheadType, warheadMass: 10, warheadYield: 10,
        blastRadius: 20, fragRadius: 50, penetration: 100
      },
      'MRM': {
        dryMass: 120, fuelMass: 80, length: 3.5, diameter: 0.25,
        thrust: 30000, isp: 250, burnTime: 60,
        guidanceMode: 'active_radar' as GuidanceMode, seekerFOV: 60, seekerRange: 50,
        warheadType: 'shaped_charge' as WarheadType, warheadMass: 50, warheadYield: 50,
        blastRadius: 30, fragRadius: 80, penetration: 500
      },
      'LRM': {
        dryMass: 300, fuelMass: 200, length: 5.0, diameter: 0.35,
        thrust: 50000, isp: 280, burnTime: 180,
        guidanceMode: 'proportional_nav' as GuidanceMode, seekerFOV: 90, seekerRange: 500,
        warheadType: 'HE' as WarheadType, warheadMass: 200, warheadYield: 200,
        blastRadius: 50, fragRadius: 150, penetration: 200
      },
      'Torpedo': {
        dryMass: 800, fuelMass: 600, length: 8.0, diameter: 0.5,
        thrust: 25000, isp: 300, burnTime: 600,
        guidanceMode: 'passive_radar' as GuidanceMode, seekerFOV: 120, seekerRange: 1000,
        warheadType: 'nuclear' as WarheadType, warheadMass: 500, warheadYield: 5, // 5 kilotons
        blastRadius: 500, fragRadius: 0, penetration: 0
      }
    };

    return specs[type];
  }

  /**
   * Lock onto target
   */
  public lockTarget(
    targetId: string,
    targetPos: { x: number; y: number; z: number },
    targetVel: { x: number; y: number; z: number }
  ): boolean {
    // Calculate if target is in seeker FOV and range
    const dx = (targetPos.x - this.position.x);
    const dy = (targetPos.y - this.position.y);
    const dz = (targetPos.z - this.position.z);
    const distance = Math.sqrt(dx**2 + dy**2 + dz**2);

    if (distance > this.guidance.seekerRange) {
      return false; // Out of range
    }

    // Check FOV (simplified: just check if generally ahead)
    const velMag = Math.sqrt(this.velocity.x**2 + this.velocity.y**2 + this.velocity.z**2);
    if (velMag < 1) {
      // Not launched yet, can lock any direction
      this.targetId = targetId;
      this.targetPosition = { ...targetPos };
      this.targetVelocity = { ...targetVel };
      this.guidance.targetLocked = true;
      this.guidance.lockStrength = 1.0;
      return true;
    }

    // Normalize velocity
    const velNorm = {
      x: this.velocity.x / velMag,
      y: this.velocity.y / velMag,
      z: this.velocity.z / velMag
    };

    // Dot product with direction to target
    const toTarget = { x: dx, y: dy, z: dz };
    const distNorm = Math.sqrt(dx**2 + dy**2 + dz**2);
    const dotProduct = (velNorm.x * toTarget.x + velNorm.y * toTarget.y + velNorm.z * toTarget.z) / distNorm;
    const angleToTarget = Math.acos(Math.max(-1, Math.min(1, dotProduct))) * 180 / Math.PI;

    if (angleToTarget > this.guidance.seekerFOV / 2) {
      return false; // Outside FOV
    }

    this.targetId = targetId;
    this.targetPosition = { ...targetPos };
    this.targetVelocity = { ...targetVel };
    this.guidance.targetLocked = true;
    this.guidance.lockStrength = 1.0 - (angleToTarget / (this.guidance.seekerFOV / 2)) * 0.5;

    return true;
  }

  /**
   * Update missile flight
   */
  public update(dt: number): void {
    if (this.status === 'ready' || this.status === 'pre_flight') {
      return; // Not launched yet
    }

    this.flightTime += dt;

    // Update target tracking
    if (this.targetPosition && this.targetVelocity) {
      // Update predicted target position
      this.targetPosition.x += this.targetVelocity.x * dt / 1000;
      this.targetPosition.y += this.targetVelocity.y * dt / 1000;
      this.targetPosition.z += this.targetVelocity.z * dt / 1000;

      // Calculate distance and closing rate
      const dx = (this.targetPosition.x - this.position.x) * 1000; // km to m
      const dy = (this.targetPosition.y - this.position.y) * 1000;
      const dz = (this.targetPosition.z - this.position.z) * 1000;
      this.distanceToTarget = Math.sqrt(dx**2 + dy**2 + dz**2) / 1000; // back to km

      const relVel = {
        x: this.velocity.x - this.targetVelocity.x,
        y: this.velocity.y - this.targetVelocity.y,
        z: this.velocity.z - this.targetVelocity.z
      };
      this.closingRate = -(relVel.x * dx + relVel.y * dy + relVel.z * dz) /
                         Math.sqrt(dx**2 + dy**2 + dz**2); // m/s
    }

    // Propulsion
    if (this.propulsion.burning && this.propulsion.fuelRemaining > 0) {
      const fuelBurnRate = this.propulsion.thrust / this.propulsion.exhaustVelocity; // kg/s
      const fuelBurned = Math.min(fuelBurnRate * dt, this.propulsion.fuelRemaining);
      this.propulsion.fuelRemaining -= fuelBurned;

      if (this.propulsion.fuelRemaining <= 0) {
        this.propulsion.burning = false;
        this.status = 'midcourse';
      }

      // Apply thrust via Tsiolkovsky
      const currentMass = this.dryMass + this.warhead.mass + this.propulsion.fuelRemaining;
      const acceleration = this.propulsion.thrust / currentMass; // m/s²

      // Guidance steering
      if (this.guidance.targetLocked && this.targetPosition) {
        const steering = this.calculateProportionalNav();
        const accelVec = {
          x: steering.x * acceleration,
          y: steering.y * acceleration,
          z: steering.z * acceleration
        };

        this.velocity.x += accelVec.x * dt;
        this.velocity.y += accelVec.y * dt;
        this.velocity.z += accelVec.z * dt;
      }
    }

    // Update position
    this.position.x += this.velocity.x * dt / 1000; // m/s to km
    this.position.y += this.velocity.y * dt / 1000;
    this.position.z += this.velocity.z * dt / 1000;

    // Update flight phase
    if (this.status === 'boost' && !this.propulsion.burning) {
      this.status = 'midcourse';
    }

    // Terminal phase
    if (this.guidance.targetLocked && this.distanceToTarget < 5) { // 5km
      this.status = 'terminal';
    }

    // Miss if fuel depleted and not hitting
    if (this.flightTime > this.propulsion.burnTime * 3 && this.distanceToTarget > 10) {
      this.status = 'miss';
    }
  }

  /**
   * Calculate proportional navigation guidance
   * Standard PN: a_c = N' * V_c * λ_dot
   * where N' is navigation gain, V_c is closing velocity, λ_dot is LOS rate
   */
  private calculateProportionalNav(): { x: number; y: number; z: number } {
    if (!this.targetPosition) {
      // No target, fly straight
      const velMag = Math.sqrt(this.velocity.x**2 + this.velocity.y**2 + this.velocity.z**2);
      return {
        x: this.velocity.x / velMag,
        y: this.velocity.y / velMag,
        z: this.velocity.z / velMag
      };
    }

    // Line of sight vector
    const los = {
      x: this.targetPosition.x - this.position.x,
      y: this.targetPosition.y - this.position.y,
      z: this.targetPosition.z - this.position.z
    };

    const losMag = Math.sqrt(los.x**2 + los.y**2 + los.z**2);
    if (losMag < 0.001) {
      // Basically on target, continue current direction
      const velMag = Math.sqrt(this.velocity.x**2 + this.velocity.y**2 + this.velocity.z**2);
      return {
        x: this.velocity.x / velMag,
        y: this.velocity.y / velMag,
        z: this.velocity.z / velMag
      };
    }

    // Unit LOS vector
    const losUnit = {
      x: los.x / losMag,
      y: los.y / losMag,
      z: los.z / losMag
    };

    // Current velocity direction
    const velMag = Math.sqrt(this.velocity.x**2 + this.velocity.y**2 + this.velocity.z**2);
    const velUnit = {
      x: this.velocity.x / velMag,
      y: this.velocity.y / velMag,
      z: this.velocity.z / velMag
    };

    // Steer toward LOS with proportional nav gain
    // Simplified: blend current velocity with LOS direction
    const blend = this.guidance.navigationGain * 0.2; // Scale factor
    const steeringVec = {
      x: velUnit.x * (1 - blend) + losUnit.x * blend,
      y: velUnit.y * (1 - blend) + losUnit.y * blend,
      z: velUnit.z * (1 - blend) + losUnit.z * blend
    };

    // Normalize
    const steerMag = Math.sqrt(steeringVec.x**2 + steeringVec.y**2 + steeringVec.z**2);
    return {
      x: steeringVec.x / steerMag,
      y: steeringVec.y / steerMag,
      z: steeringVec.z / steerMag
    };
  }

  /**
   * Launch the missile
   */
  public launch(): void {
    if (this.status !== 'ready' && this.status !== 'pre_flight') {
      return;
    }

    this.status = 'boost';
    this.propulsion.burning = true;
    this.launchTime = 0;
    this.flightTime = 0;
  }

  /**
   * Apply countermeasure effects
   */
  public applyCountermeasures(chaff: number, flares: number, ecm: number): void {
    // Degrade lock strength
    const chaffDegradation = chaff * this.chaffEffectiveness;
    const flareDegradation = flares * this.flareEffectiveness;
    const ecmDegradation = ecm * this.ecmEffectiveness;

    const totalDegradation = Math.max(chaffDegradation, flareDegradation) + ecmDegradation * 0.5;

    this.guidance.lockStrength = Math.max(0, this.guidance.lockStrength - totalDegradation);

    if (this.guidance.lockStrength < 0.3) {
      this.guidance.targetLocked = false;
      this.status = 'miss';
    }
  }

  /**
   * Check if missile hits target
   */
  public checkHit(
    targetPos: { x: number; y: number; z: number },
    targetRadius: number
  ): boolean {
    const dx = (this.position.x - targetPos.x) * 1000; // km to m
    const dy = (this.position.y - targetPos.y) * 1000;
    const dz = (this.position.z - targetPos.z) * 1000;
    const distance = Math.sqrt(dx**2 + dy**2 + dz**2);

    // Direct hit
    if (distance <= targetRadius) {
      this.status = 'hit';
      return true;
    }

    // Proximity detonation
    if (distance <= this.warhead.blastRadius) {
      this.status = 'hit';
      return true;
    }

    return false;
  }

  /**
   * Get missile state
   */
  public getState() {
    return {
      id: this.id,
      name: this.name,
      type: this.type,
      status: this.status,

      // Position/velocity
      position: { ...this.position },
      velocity: { ...this.velocity },
      speed: Math.sqrt(this.velocity.x**2 + this.velocity.y**2 + this.velocity.z**2),

      // Guidance
      targetLocked: this.guidance.targetLocked,
      lockStrength: this.guidance.lockStrength,
      distanceToTarget: this.distanceToTarget,
      closingRate: this.closingRate,

      // Propulsion
      burning: this.propulsion.burning,
      fuelPercent: this.propulsion.fuelRemaining / this.propulsion.fuelMass,
      flightTime: this.flightTime,

      // Warhead
      warheadType: this.warhead.type,
      warheadYield: this.warhead.yield
    };
  }
}

/**
 * Missile launcher system
 */
export class MissileLauncherSystem {
  public launcher: MissileLauncher;
  public missiles: Missile[] = [];
  public launchedMissiles: Missile[] = [];
  private nextMissileIndex: number = 0;

  constructor(config: {
    id: string;
    type: LauncherType;
    capacity: number;
    missileType: MissileType;
    reloadTime: number;
  }) {
    this.launcher = {
      id: config.id,
      type: config.type,
      capacity: config.capacity,
      loaded: config.capacity,
      reloadTimeSeconds: config.reloadTime,
      reloadProgress: 0,
      location: { x: 0, y: 0, z: 0 },
      powerDraw: 50 // Base power for guidance computer
    };

    // Load missiles
    for (let i = 0; i < config.capacity; i++) {
      this.missiles.push(new Missile({
        type: config.missileType,
        name: `${config.missileType}-${i + 1}`,
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      }));
    }
  }

  /**
   * Lock next missile on target
   */
  public lockTarget(
    targetId: string,
    targetPos: { x: number; y: number; z: number },
    targetVel: { x: number; y: number; z: number }
  ): boolean {
    if (this.nextMissileIndex >= this.missiles.length) {
      return false; // No missiles left
    }

    const missile = this.missiles[this.nextMissileIndex];
    const locked = missile.lockTarget(targetId, targetPos, targetVel);

    if (locked) {
      missile.status = 'pre_flight';
    }

    return locked;
  }

  /**
   * Launch locked missile
   */
  public launch(
    shipPos: { x: number; y: number; z: number },
    shipVel: { x: number; y: number; z: number }
  ): Missile | null {
    if (this.nextMissileIndex >= this.missiles.length) {
      return null;
    }

    const missile = this.missiles[this.nextMissileIndex];
    if (missile.status !== 'pre_flight') {
      return null; // Not ready
    }

    // Set missile initial position and velocity
    missile.position = { ...shipPos };
    missile.velocity = { ...shipVel }; // Inherit ship velocity

    // Launch
    missile.launch();

    // Move to launched list
    this.launchedMissiles.push(missile);
    this.nextMissileIndex++;
    this.launcher.loaded = this.missiles.length - this.nextMissileIndex;

    return missile;
  }

  /**
   * Update launcher and missiles
   */
  public update(dt: number): void {
    // Update all launched missiles
    for (const missile of this.launchedMissiles) {
      if (missile.status !== 'hit' && missile.status !== 'miss') {
        missile.update(dt);
      }
    }

    // Reload
    if (this.launcher.loaded === 0 && this.launcher.reloadProgress < 1.0) {
      this.launcher.reloadProgress += dt / this.launcher.reloadTimeSeconds;
      this.launcher.powerDraw = 500; // Active reload

      if (this.launcher.reloadProgress >= 1.0) {
        this.launcher.reloadProgress = 0;
        // In real implementation, would reload from magazine
        // For now, just reset
      }
    } else {
      this.launcher.powerDraw = 50; // Idle
    }
  }

  /**
   * Get launcher state
   */
  public getState() {
    return {
      launcher: {
        id: this.launcher.id,
        type: this.launcher.type,
        loaded: this.launcher.loaded,
        capacity: this.launcher.capacity,
        reloading: this.launcher.reloadProgress > 0,
        reloadProgress: this.launcher.reloadProgress,
        powerDraw: this.launcher.powerDraw
      },
      missiles: this.launchedMissiles
        .filter(m => m.status !== 'hit' && m.status !== 'miss')
        .map(m => m.getState())
    };
  }
}
