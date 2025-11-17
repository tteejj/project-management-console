/**
 * Unified Ship - Complete integration of physics and subsystems
 *
 * Single entity that exists in BOTH the physics world AND has all subsystems
 */

import { Vector3 } from './math-utils';
import { World } from './world';
import { IntegratedShip, ShipConfiguration as PhysicsShipConfig } from './integrated-ship';
import { CompleteShip, ShipConfig } from './ship-configuration';

/**
 * Unified Ship that seamlessly integrates physics and subsystems
 */
export class UnifiedShip {
  // Physics representation (exists in world, affected by gravity, collisions)
  private integratedShip: IntegratedShip;

  // Subsystems representation (power, thermal, life support, etc.)
  private completeShip: CompleteShip;

  constructor(config: ShipConfig, world: World) {
    // Create subsystems ship
    this.completeShip = new CompleteShip(config);

    // Create physics ship with matching parameters
    const physicsConfig: PhysicsShipConfig = {
      mass: config.mass,
      radius: this.calculateRadius(config.mass),  // Estimate from mass
      position: config.position,
      velocity: config.velocity,
      hullConfig: {
        compartments: config.compartments,
        armorLayers: config.armorLayers
      }
    };

    this.integratedShip = new IntegratedShip(physicsConfig, world);
  }

  /**
   * Update - automatically syncs physics and subsystems
   */
  update(dt: number): void {
    // PHASE 1: Update physics (gravity, collisions, orbital mechanics)
    this.integratedShip.update(dt);

    // PHASE 2: Sync position/velocity from physics to subsystems
    this.syncFromPhysics();

    // PHASE 3: Update all subsystems
    this.completeShip.update(dt);

    // No need to sync back - subsystems don't affect position
    // (except for future RCS/thrusters which would apply forces to IntegratedShip)
  }

  /**
   * Sync state from physics representation to subsystems
   */
  private syncFromPhysics(): void {
    this.completeShip.position = this.integratedShip.getPosition();
    this.completeShip.velocity = this.integratedShip.getVelocity();
    this.completeShip.combatComputer.updateOwnShip(
      this.completeShip.position,
      this.completeShip.velocity
    );
  }

  /**
   * Calculate ship radius from mass (rough estimate)
   */
  private calculateRadius(mass: number): number {
    // Assume roughly spherical ship with density ~500 kg/m³ (mostly hollow)
    // V = m / ρ = (4/3)πr³  →  r = ∛(3m / 4πρ)
    const density = 500;
    const volume = mass / density;
    return Math.pow((3 * volume) / (4 * Math.PI), 1/3);
  }

  /**
   * Apply thrust (future feature - connects subsystems to physics)
   */
  applyThrust(direction: Vector3, magnitude: number): void {
    // Check if engines operational
    // Apply force to IntegratedShip
    // Consume fuel
    // Generate heat
    // Future implementation
  }

  /**
   * Get complete ship status
   */
  getStatus() {
    return this.completeShip.getStatus();
  }

  /**
   * Get ship ID
   */
  get id(): string {
    return this.completeShip.id;
  }

  /**
   * Get ship name
   */
  get name(): string {
    return this.completeShip.name;
  }

  /**
   * Get current position (from physics)
   */
  getPosition(): Vector3 {
    return this.integratedShip.getPosition();
  }

  /**
   * Get current velocity (from physics)
   */
  getVelocity(): Vector3 {
    return this.integratedShip.getVelocity();
  }

  /**
   * Access subsystems directly
   */
  get power() {
    return this.completeShip.power;
  }

  get thermal() {
    return this.completeShip.thermal;
  }

  get lifeSupport() {
    return this.completeShip.lifeSupport;
  }

  get systemDamage() {
    return this.completeShip.systemDamage;
  }

  get damageControl() {
    return this.completeShip.damageControl;
  }

  get combatComputer() {
    return this.completeShip.combatComputer;
  }

  get hull() {
    return this.completeShip.hull;
  }

  /**
   * Access physics ship (for adding to simulation)
   */
  get physicsBody(): IntegratedShip {
    return this.integratedShip;
  }
}
