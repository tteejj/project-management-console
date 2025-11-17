/**
 * Weapons Control System
 *
 * Integrates all weapon systems (kinetic, missile, energy) with:
 * - Fire control computer
 * - Target tracking and management
 * - Automated point defense
 * - Power management integration
 * - Damage assessment
 */

import { KineticWeapon, ProjectileManager, Target as KineticTarget } from './kinetic-weapons';
import { Missile, MissileLauncherSystem, MissileType } from './missile-weapons';
import { LaserWeapon, ParticleBeamWeapon, EnergyDamage } from './energy-weapons';

export type TargetType = 'spacecraft' | 'missile' | 'station' | 'debris';
export type ThreatLevel = 'none' | 'low' | 'medium' | 'high' | 'critical';
export type EngagementMode = 'manual' | 'computer_assisted' | 'auto_track' | 'point_defense' | 'barrage';

/**
 * Tracked target
 */
export interface TrackedTarget {
  id: string;
  type: TargetType;
  position: { x: number; y: number; z: number }; // km
  velocity: { x: number; y: number; z: number }; // m/s
  radius: number; // m
  threat: ThreatLevel;
  health: number; // 0-1
  hostile: boolean;
  locked: boolean;
  timeToIntercept: number | null; // seconds
  inRange: { kinetic: boolean; missile: boolean; laser: boolean };
}

/**
 * Engagement order
 */
export interface EngagementOrder {
  targetId: string;
  weaponIds: string[];
  mode: EngagementMode;
  priority: number; // 0-10, higher = more urgent
  autoFire: boolean;
}

/**
 * Weapons Control System
 */
export class WeaponsControlSystem {
  // Weapon systems
  private kineticWeapons: Map<string, KineticWeapon> = new Map();
  private missileLaunchers: Map<string, MissileLauncherSystem> = new Map();
  private laserWeapons: Map<string, LaserWeapon> = new Map();
  private particleBeams: Map<string, ParticleBeamWeapon> = new Map();

  // Projectile tracking
  private projectileManager: ProjectileManager = new ProjectileManager();

  // Targets
  private targets: Map<string, TrackedTarget> = new Map();
  private engagements: EngagementOrder[] = [];

  // Ship state
  private shipPosition: { x: number; y: number; z: number } = { x: 0, y: 0, z: 0 };
  private shipVelocity: { x: number; y: number; z: number } = { x: 0, y: 0, z: 0 };

  // Fire control
  public pointDefenseActive: boolean = true;
  public weaponsSafety: boolean = true; // Master safety
  public autoEngageHostiles: boolean = false;

  // Power management
  private totalPowerDraw: number = 0;
  private powerAvailable: number = 100000; // 100 kW default

  constructor() {
    // Default weapons will be added by spacecraft
  }

  /**
   * Add kinetic weapon
   */
  public addKineticWeapon(weapon: KineticWeapon): void {
    this.kineticWeapons.set(weapon.id, weapon);
  }

  /**
   * Add missile launcher
   */
  public addMissileLauncher(launcher: MissileLauncherSystem): void {
    this.missileLaunchers.set(launcher.launcher.id, launcher);
  }

  /**
   * Add laser weapon
   */
  public addLaserWeapon(laser: LaserWeapon): void {
    this.laserWeapons.set(laser.getState().id, laser);
  }

  /**
   * Add particle beam
   */
  public addParticleBeam(beam: ParticleBeamWeapon): void {
    this.particleBeams.set(beam.getState().id, beam);
  }

  /**
   * Update ship position/velocity
   */
  public updateShipState(
    position: { x: number; y: number; z: number },
    velocity: { x: number; y: number; z: number }
  ): void {
    this.shipPosition = { ...position };
    this.shipVelocity = { ...velocity };
  }

  /**
   * Add/update target
   */
  public trackTarget(target: TrackedTarget): void {
    this.targets.set(target.id, target);
    this.updateTargetRanges(target);
  }

  /**
   * Remove target
   */
  public removeTarget(targetId: string): void {
    this.targets.delete(targetId);
    this.engagements = this.engagements.filter(e => e.targetId !== targetId);
  }

  /**
   * Update target range checks
   */
  private updateTargetRanges(target: TrackedTarget): void {
    const dx = target.position.x - this.shipPosition.x;
    const dy = target.position.y - this.shipPosition.y;
    const dz = target.position.z - this.shipPosition.z;
    const range = Math.sqrt(dx**2 + dy**2 + dz**2);

    target.inRange = {
      kinetic: range <= 50, // 50 km typical kinetic range
      missile: range <= 500, // 500 km missile range
      laser: range <= 100 // 100 km laser range
    };
  }

  /**
   * Create engagement order
   */
  public engageTarget(
    targetId: string,
    weaponType: 'kinetic' | 'missile' | 'laser' | 'all',
    mode: EngagementMode = 'computer_assisted'
  ): boolean {
    const target = this.targets.get(targetId);
    if (!target) return false;

    // Select weapons
    const weaponIds: string[] = [];

    if (weaponType === 'kinetic' || weaponType === 'all') {
      this.kineticWeapons.forEach((w, id) => {
        if (w.status !== 'damaged' && w.status !== 'jammed') {
          weaponIds.push(id);
        }
      });
    }

    if (weaponType === 'missile' || weaponType === 'all') {
      this.missileLaunchers.forEach((l, id) => {
        if (l.launcher.loaded > 0) {
          weaponIds.push(id);
        }
      });
    }

    if (weaponType === 'laser' || weaponType === 'all') {
      this.laserWeapons.forEach((l) => {
        const state = l.getState();
        if (state.status !== 'damaged' && state.status !== 'overheated') {
          weaponIds.push(state.id);
        }
      });
    }

    if (weaponIds.length === 0) {
      return false; // No weapons available
    }

    // Calculate priority based on threat
    let priority = 5;
    if (target.threat === 'critical') priority = 10;
    else if (target.threat === 'high') priority = 8;
    else if (target.threat === 'medium') priority = 6;

    // Create engagement
    const engagement: EngagementOrder = {
      targetId,
      weaponIds,
      mode,
      priority,
      autoFire: mode === 'point_defense' || this.autoEngageHostiles
    };

    this.engagements.push(engagement);
    this.engagements.sort((a, b) => b.priority - a.priority); // Sort by priority

    target.locked = true;

    return true;
  }

  /**
   * Update all weapon systems
   */
  public update(dt: number): void {
    this.totalPowerDraw = 0;

    // Update all weapon systems
    this.kineticWeapons.forEach(weapon => {
      weapon.update(dt);
      this.totalPowerDraw += weapon.powerConsumption;
    });

    this.missileLaunchers.forEach(launcher => {
      launcher.update(dt);
      this.totalPowerDraw += launcher.launcher.powerDraw;
    });

    this.laserWeapons.forEach(laser => {
      laser.update(dt);
      const state = laser.getState();
      this.totalPowerDraw += state.electricalPower * 1000000; // MW to W
    });

    this.particleBeams.forEach(beam => {
      beam.update(dt);
      const state = beam.getState();
      this.totalPowerDraw += state.electricalPower * 1000000; // MW to W
    });

    // Update projectiles
    this.projectileManager.update(dt);

    // Update targets
    this.targets.forEach(target => {
      // Update position
      target.position.x += target.velocity.x * dt / 1000;
      target.position.y += target.velocity.y * dt / 1000;
      target.position.z += target.velocity.z * dt / 1000;

      // Update ranges
      this.updateTargetRanges(target);

      // Calculate time to intercept (simplified)
      const dx = target.position.x - this.shipPosition.x;
      const dy = target.position.y - this.shipPosition.y;
      const dz = target.position.z - this.shipPosition.z;
      const range = Math.sqrt(dx**2 + dy**2 + dz**2) * 1000; // km to m

      const relVel = {
        x: target.velocity.x - this.shipVelocity.x,
        y: target.velocity.y - this.shipVelocity.y,
        z: target.velocity.z - this.shipVelocity.z
      };
      const closingSpeed = Math.abs(relVel.x * dx + relVel.y * dy + relVel.z * dz) /
                           Math.sqrt(dx**2 + dy**2 + dz**2 + 0.001);

      target.timeToIntercept = closingSpeed > 0 ? range / closingSpeed : null;
    });

    // Process engagements
    this.processEngagements(dt);

    // Auto point defense
    if (this.pointDefenseActive) {
      this.autoPointDefense();
    }

    // Check hits
    this.checkProjectileHits();
    this.checkMissileHits();
  }

  /**
   * Process engagement orders
   */
  private processEngagements(dt: number): void {
    for (const engagement of this.engagements) {
      const target = this.targets.get(engagement.targetId);
      if (!target) continue;

      // Process each assigned weapon
      for (const weaponId of engagement.weaponIds) {
        // Check if kinetic weapon
        const kinetic = this.kineticWeapons.get(weaponId);
        if (kinetic) {
          this.processKineticEngagement(kinetic, target, engagement, dt);
          continue;
        }

        // Check if missile launcher
        const missile = this.missileLaunchers.get(weaponId);
        if (missile) {
          this.processMissileEngagement(missile, target, engagement);
          continue;
        }

        // Check if laser
        this.laserWeapons.forEach((laser) => {
          if (laser.getState().id === weaponId) {
            this.processLaserEngagement(laser, target, engagement);
          }
        });
      }
    }
  }

  /**
   * Process kinetic weapon engagement
   */
  private processKineticEngagement(
    weapon: KineticWeapon,
    target: TrackedTarget,
    engagement: EngagementOrder,
    dt: number
  ): void {
    if (target.threat === 'none') return; // Skip non-threats

    // Calculate firing solution
    const solution = weapon.calculateFiringSolution(
      {
        id: target.id,
        position: target.position,
        velocity: target.velocity,
        radius: target.radius,
        threat: target.threat as 'low' | 'medium' | 'high' | 'critical'
      },
      this.shipPosition,
      this.shipVelocity
    );

    // Track target
    weapon.trackSolution(solution, dt);

    // Fire if conditions met
    if (engagement.autoFire && !this.weaponsSafety && solution.valid) {
      if (solution.hitProbability > 0.3) { // Minimum hit probability
        const projectile = weapon.fire(solution, this.shipPosition, this.shipVelocity);
        if (projectile) {
          this.projectileManager.addProjectile(projectile);
        }
      }
    }
  }

  /**
   * Process missile engagement
   */
  private processMissileEngagement(
    launcher: MissileLauncherSystem,
    target: TrackedTarget,
    engagement: EngagementOrder
  ): void {
    // Lock target
    const locked = launcher.lockTarget(target.id, target.position, target.velocity);

    if (locked && engagement.autoFire && !this.weaponsSafety) {
      // Launch
      const missile = launcher.launch(this.shipPosition, this.shipVelocity);
      // Missile is now tracking in launcher's list
    }
  }

  /**
   * Process laser engagement
   */
  private processLaserEngagement(
    laser: LaserWeapon,
    target: TrackedTarget,
    engagement: EngagementOrder
  ): void {
    if (engagement.autoFire && !this.weaponsSafety) {
      laser.startFiring(target.position);
    }
  }

  /**
   * Automated point defense
   */
  private autoPointDefense(): void {
    // Find incoming missiles
    const incomingMissiles = Array.from(this.targets.values()).filter(t =>
      t.type === 'missile' &&
      t.threat === 'critical' &&
      t.timeToIntercept !== null &&
      t.timeToIntercept < 30 // Within 30 seconds
    );

    // Engage with available point defense weapons
    for (const missile of incomingMissiles) {
      if (!missile.locked) {
        this.engageTarget(missile.id, 'kinetic', 'point_defense');
      }
    }
  }

  /**
   * Check for projectile hits
   */
  private checkProjectileHits(): void {
    const targetArray = Array.from(this.targets.values())
      .filter(t => t.threat !== 'none')
      .map(t => ({
        id: t.id,
        position: { x: t.position.x, y: t.position.y, z: t.position.z },
        velocity: { x: t.velocity.x, y: t.velocity.y, z: t.velocity.z },
        radius: t.radius,
        threat: t.threat as 'low' | 'medium' | 'high' | 'critical'
      }));

    const hits = this.projectileManager.checkHits(targetArray);

    for (const hit of hits) {
      const target = this.targets.get(hit.targetId);
      if (target) {
        // Apply damage
        const damagePercent = hit.damage / 1000; // Normalize
        target.health = Math.max(0, target.health - damagePercent);

        // Destroy if health depleted
        if (target.health <= 0) {
          this.removeTarget(target.id);
        }
      }
    }
  }

  /**
   * Check for missile hits
   */
  private checkMissileHits(): void {
    this.missileLaunchers.forEach(launcher => {
      const missiles = launcher.launchedMissiles;

      for (const missile of missiles) {
        if (missile.status !== 'terminal' && missile.status !== 'launched') continue;

        // Find target
        const target = this.targets.get(missile.targetId || '');
        if (!target) continue;

        // Check hit
        const hit = missile.checkHit(target.position, target.radius);
        if (hit) {
          // Apply damage
          const state = missile.getState();
          target.health = Math.max(0, target.health - 0.5); // Missiles do massive damage

          if (target.health <= 0) {
            this.removeTarget(target.id);
          }
        }
      }
    });
  }

  /**
   * Get threat assessment
   */
  public getThreatAssessment() {
    const hostileTargets = Array.from(this.targets.values()).filter(t => t.hostile);
    const criticalThreats = hostileTargets.filter(t => t.threat === 'critical');
    const incomingMissiles = hostileTargets.filter(t => t.type === 'missile');

    return {
      totalHostiles: hostileTargets.length,
      criticalThreats: criticalThreats.length,
      incomingMissiles: incomingMissiles.length,
      closestThreat: this.getClosestThreat(),
      weaponsReady: this.getWeaponsReady()
    };
  }

  /**
   * Get closest threat
   */
  private getClosestThreat(): TrackedTarget | null {
    let closest: TrackedTarget | null = null;
    let minDist = Infinity;

    this.targets.forEach(target => {
      if (!target.hostile) return;

      const dx = target.position.x - this.shipPosition.x;
      const dy = target.position.y - this.shipPosition.y;
      const dz = target.position.z - this.shipPosition.z;
      const dist = Math.sqrt(dx**2 + dy**2 + dz**2);

      if (dist < minDist) {
        minDist = dist;
        closest = target;
      }
    });

    return closest;
  }

  /**
   * Get weapons ready count
   */
  private getWeaponsReady() {
    let kinetic = 0;
    let missiles = 0;
    let energy = 0;

    this.kineticWeapons.forEach(w => {
      if (w.status === 'ready' || w.status === 'tracking') kinetic++;
    });

    this.missileLaunchers.forEach(l => {
      missiles += l.launcher.loaded;
    });

    this.laserWeapons.forEach(l => {
      if (l.getState().ready) energy++;
    });

    this.particleBeams.forEach(b => {
      if (b.getState().ready) energy++;
    });

    return { kinetic, missiles, energy };
  }

  /**
   * Get complete weapons status
   */
  public getState() {
    return {
      powerDraw: this.totalPowerDraw,
      weaponsSafety: this.weaponsSafety,
      pointDefenseActive: this.pointDefenseActive,
      autoEngageHostiles: this.autoEngageHostiles,

      kineticWeapons: Array.from(this.kineticWeapons.values()).map(w => w.getState()),
      missileLaunchers: Array.from(this.missileLaunchers.values()).map(l => l.getState()),
      laserWeapons: Array.from(this.laserWeapons.values()).map(l => l.getState()),
      particleBeams: Array.from(this.particleBeams.values()).map(b => b.getState()),

      projectiles: this.projectileManager.getProjectiles(),
      targets: Array.from(this.targets.values()),
      engagements: this.engagements,
      threatAssessment: this.getThreatAssessment()
    };
  }
}
