/**
 * Weapon Systems
 *
 * Implements railguns, coilguns, missiles, lasers, and projectile physics
 * NO RENDERING - physics only
 */

import { Vector3, VectorMath } from './math-utils';
import { World, CelestialBody } from './world';
import { CollisionDetector } from './collision';
import { IntegratedShip } from './integrated-ship';

export enum WeaponType {
  RAILGUN = 'railgun',
  COILGUN = 'coilgun',
  MISSILE = 'missile',
  LASER = 'laser'
}

export interface Weapon {
  id: string;
  type: WeaponType;

  // Physical properties
  mountPoint: Vector3;           // Position on ship
  aimDirection: Vector3;         // Current aim (unit vector)

  // Performance
  damage: number;                // Base damage (Joules)
  projectileSpeed?: number;      // m/s (for projectiles)
  projectileMass?: number;       // kg (for projectiles)
  range: number;                 // Maximum effective range (m)
  rateOfFire: number;            // rounds per minute

  // Resources
  powerDraw: number;             // kW when firing
  heatGeneration: number;        // J per shot
  ammoCapacity?: number;         // For projectiles
  ammoRemaining?: number;

  // State
  cooldown: number;              // Time until can fire again (seconds)
  compartmentId: string;         // Which compartment it's in
}

export interface FiringResult {
  success: boolean;
  reason?: string;
  projectile?: Projectile;
}

export interface ProjectileConfig {
  position: Vector3;
  velocity: Vector3;
  mass: number;
  damage: number;
  lifetime: number;              // seconds
}

type EventCallback = (...args: any[]) => void;

/**
 * Projectile - physical projectile in space
 */
export class Projectile {
  private position: Vector3;
  private velocity: Vector3;
  private mass: number;
  private damage: number;
  private lifetime: number;
  private alive: boolean = true;
  private eventListeners: Map<string, EventCallback[]> = new Map();

  constructor(config: ProjectileConfig) {
    this.position = { ...config.position };
    this.velocity = { ...config.velocity };
    this.mass = config.mass;
    this.damage = config.damage;
    this.lifetime = config.lifetime;
  }

  /**
   * Update projectile physics
   */
  update(dt: number, world: World): void {
    if (!this.alive) return;

    // PHASE 1: Apply gravity
    const gravity = world.getGravityAt(this.position);
    this.velocity = VectorMath.add(
      this.velocity,
      VectorMath.scale(gravity, dt)
    );

    // PHASE 2: Calculate new position
    const displacement = VectorMath.scale(this.velocity, dt);
    const newPosition = VectorMath.add(this.position, displacement);

    // PHASE 3: Check for hits using sweep test
    const hit = this.checkHit(this.position, newPosition, world);

    if (hit) {
      this.handleImpact(hit.body, hit.point, world);
      this.alive = false;
      return;
    }

    // PHASE 4: Update position
    this.position = newPosition;

    // PHASE 5: Lifetime decay
    this.lifetime -= dt;
    if (this.lifetime <= 0) {
      this.alive = false;
    }
  }

  /**
   * Check for hits along trajectory
   */
  private checkHit(startPos: Vector3, endPos: Vector3, world: World): { body: CelestialBody; point: Vector3 } | null {
    const bodies = world.getAllBodies();
    const direction = VectorMath.normalize(VectorMath.subtract(endPos, startPos));
    const distance = VectorMath.distance(startPos, endPos);

    let closestHit: { body: CelestialBody; point: Vector3; distance: number } | null = null;

    for (const body of bodies) {
      // Simple sphere intersection
      const toBody = VectorMath.subtract(body.position, startPos);
      const projection = VectorMath.dot(toBody, direction);

      // Check if body is ahead of us
      if (projection < 0 || projection > distance) continue;

      const closestPoint = VectorMath.add(startPos, VectorMath.scale(direction, projection));
      const distToBody = VectorMath.distance(closestPoint, body.position);

      if (distToBody <= body.radius) {
        const hitDistance = projection - Math.sqrt(body.radius * body.radius - distToBody * distToBody);
        if (!closestHit || hitDistance < closestHit.distance) {
          const hitPoint = VectorMath.add(startPos, VectorMath.scale(direction, hitDistance));
          closestHit = { body, point: hitPoint, distance: hitDistance };
        }
      }
    }

    if (closestHit) {
      return { body: closestHit.body, point: closestHit.point };
    }

    return null;
  }

  /**
   * Handle impact with target
   */
  private handleImpact(target: CelestialBody, point: Vector3, world: World): void {
    // Emit hit event
    this.emit('hit', { target, point, damage: this.damage });

    // TODO: Apply damage to IntegratedShip if target is a ship
    // This requires checking if the body belongs to a ship and accessing its damage system
  }

  /**
   * Event listener
   */
  on(event: string, callback: EventCallback): void {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    this.eventListeners.get(event)!.push(callback);
  }

  /**
   * Emit event
   */
  private emit(event: string, ...args: any[]): void {
    const listeners = this.eventListeners.get(event);
    if (listeners) {
      for (const callback of listeners) {
        callback(...args);
      }
    }
  }

  // Getters
  getPosition(): Vector3 {
    return { ...this.position };
  }

  getVelocity(): Vector3 {
    return { ...this.velocity };
  }

  isAlive(): boolean {
    return this.alive;
  }
}

/**
 * Weapon System - manages all weapons on a ship
 */
export class WeaponSystem {
  private ship: IntegratedShip;
  private weapons: Map<string, Weapon> = new Map();

  constructor(ship: IntegratedShip) {
    this.ship = ship;
  }

  /**
   * Add weapon to ship
   */
  addWeapon(weapon: Weapon): void {
    this.weapons.set(weapon.id, weapon);
  }

  /**
   * Fire a weapon
   */
  fire(weaponId: string, aimDirection: Vector3): FiringResult {
    const weapon = this.weapons.get(weaponId);
    if (!weapon) {
      return { success: false, reason: 'weapon_not_found' };
    }

    // Check cooldown
    if (weapon.cooldown > 0) {
      return { success: false, reason: 'on_cooldown' };
    }

    // Check ammo
    if (weapon.ammoRemaining !== undefined && weapon.ammoRemaining <= 0) {
      return { success: false, reason: 'out_of_ammo' };
    }

    // Fire based on weapon type
    let projectile: Projectile | undefined;

    switch (weapon.type) {
      case WeaponType.RAILGUN:
      case WeaponType.COILGUN:
        projectile = this.fireProjectileWeapon(weapon, aimDirection);
        break;

      case WeaponType.LASER:
        // Instant hit - no projectile
        // TODO: Implement hitscan laser
        break;

      case WeaponType.MISSILE:
        // TODO: Implement guided missile
        break;
    }

    // Consume ammo
    if (weapon.ammoRemaining !== undefined) {
      weapon.ammoRemaining--;
    }

    // Set cooldown
    weapon.cooldown = 60 / weapon.rateOfFire;

    return {
      success: true,
      projectile
    };
  }

  /**
   * Fire projectile weapon (railgun/coilgun)
   */
  private fireProjectileWeapon(weapon: Weapon, aimDirection: Vector3): Projectile {
    // Calculate projectile position (mount point + ship position)
    const shipPos = this.ship.getPosition();
    const projectilePos = VectorMath.add(shipPos, weapon.mountPoint);

    // Calculate projectile velocity (ship velocity + weapon velocity)
    const shipVel = this.ship.getVelocity();
    const weaponVelocity = VectorMath.scale(
      VectorMath.normalize(aimDirection),
      weapon.projectileSpeed || 0
    );
    const projectileVel = VectorMath.add(shipVel, weaponVelocity);

    // Create projectile
    const projectile = new Projectile({
      position: projectilePos,
      velocity: projectileVel,
      mass: weapon.projectileMass || 1,
      damage: weapon.damage,
      lifetime: 60  // 1 minute default
    });

    // Apply recoil to ship
    const recoilMomentum = VectorMath.scale(
      weaponVelocity,
      -(weapon.projectileMass || 1)
    );
    this.ship.applyImpulse(recoilMomentum);

    return projectile;
  }

  /**
   * Update all weapons
   */
  update(dt: number): void {
    for (const weapon of this.weapons.values()) {
      if (weapon.cooldown > 0) {
        weapon.cooldown = Math.max(0, weapon.cooldown - dt);
      }
    }
  }

  /**
   * Get weapon by ID
   */
  getWeapon(id: string): Weapon | undefined {
    return this.weapons.get(id);
  }

  /**
   * Get all weapons
   */
  getAllWeapons(): Weapon[] {
    return Array.from(this.weapons.values());
  }
}

/**
 * Projectile Manager - tracks all projectiles in the world
 */
export class ProjectileManager {
  private projectiles: Projectile[] = [];

  /**
   * Add projectile to tracking
   */
  addProjectile(projectile: Projectile): void {
    this.projectiles.push(projectile);
  }

  /**
   * Update all projectiles
   */
  update(dt: number, world: World): void {
    // Update all projectiles
    for (const projectile of this.projectiles) {
      if (projectile.isAlive()) {
        projectile.update(dt, world);
      }
    }

    // Remove dead projectiles
    this.projectiles = this.projectiles.filter(p => p.isAlive());
  }

  /**
   * Get projectile count
   */
  getProjectileCount(): number {
    return this.projectiles.length;
  }

  /**
   * Get all projectiles
   */
  getAllProjectiles(): Projectile[] {
    return [...this.projectiles];
  }
}
