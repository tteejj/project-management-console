/**
 * Weapon Systems Tests
 *
 * Tests railgun, coilgun, missiles, lasers, and projectile physics
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  WeaponSystem,
  Weapon,
  WeaponType,
  Projectile,
  ProjectileManager,
  FiringResult
} from '../src/weapons';
import { IntegratedShip, ShipConfiguration } from '../src/integrated-ship';
import { World, CelestialBodyFactory } from '../src/world';
import { Vector3, VectorMath } from '../src/math-utils';

describe('Weapon Systems', () => {
  let world: World;
  let moon: any;

  beforeEach(() => {
    world = new World();
    moon = CelestialBodyFactory.createMoon();
    world.addBody(moon);
  });

  describe('Weapon Configuration', () => {
    it('should create railgun with correct properties', () => {
      const railgun: Weapon = {
        id: 'railgun-1',
        type: WeaponType.RAILGUN,
        mountPoint: { x: 0, y: 0, z: 10 },
        aimDirection: { x: 1, y: 0, z: 0 },
        damage: 50000,
        projectileSpeed: 3000,
        projectileMass: 5,
        range: 50000,
        rateOfFire: 10,
        powerDraw: 500,
        heatGeneration: 1000000,
        ammoCapacity: 100,
        ammoRemaining: 100,
        cooldown: 0,
        compartmentId: 'weapons-bay'
      };

      expect(railgun.type).toBe(WeaponType.RAILGUN);
      expect(railgun.projectileSpeed).toBe(3000);
    });

    it('should create laser with no ammo', () => {
      const laser: Weapon = {
        id: 'laser-1',
        type: WeaponType.LASER,
        mountPoint: { x: 0, y: 0, z: 10 },
        aimDirection: { x: 1, y: 0, z: 0 },
        damage: 100000,
        range: 100000,
        rateOfFire: 1,
        powerDraw: 2000,
        heatGeneration: 5000000,
        cooldown: 0,
        compartmentId: 'weapons-bay'
      };

      expect(laser.ammoCapacity).toBeUndefined();
      expect(laser.projectileSpeed).toBeUndefined();
    });
  });

  describe('Firing Weapons', () => {
    it('should fire railgun and create projectile', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 0, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);
      const weaponSystem = new WeaponSystem(ship);

      const railgun: Weapon = {
        id: 'railgun-1',
        type: WeaponType.RAILGUN,
        mountPoint: { x: 0, y: 0, z: 10 },
        aimDirection: { x: 1, y: 0, z: 0 },
        damage: 50000,
        projectileSpeed: 3000,
        projectileMass: 5,
        range: 50000,
        rateOfFire: 10,
        powerDraw: 100,  // Low power for test
        heatGeneration: 100000,
        ammoCapacity: 100,
        ammoRemaining: 100,
        cooldown: 0,
        compartmentId: 'weapons-bay'
      };

      weaponSystem.addWeapon(railgun);

      const result = weaponSystem.fire('railgun-1', { x: 1, y: 0, z: 0 });

      expect(result.success).toBe(true);
      expect(result.projectile).toBeDefined();
      expect(result.projectile?.mass).toBe(5);
    });

    it('should fail when out of ammo', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 0, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);
      const weaponSystem = new WeaponSystem(ship);

      const railgun: Weapon = {
        id: 'railgun-1',
        type: WeaponType.RAILGUN,
        mountPoint: { x: 0, y: 0, z: 10 },
        aimDirection: { x: 1, y: 0, z: 0 },
        damage: 50000,
        projectileSpeed: 3000,
        projectileMass: 5,
        range: 50000,
        rateOfFire: 10,
        powerDraw: 100,
        heatGeneration: 100000,
        ammoCapacity: 100,
        ammoRemaining: 0,  // No ammo!
        cooldown: 0,
        compartmentId: 'weapons-bay'
      };

      weaponSystem.addWeapon(railgun);

      const result = weaponSystem.fire('railgun-1', { x: 1, y: 0, z: 0 });

      expect(result.success).toBe(false);
      expect(result.reason).toBe('out_of_ammo');
    });

    it('should fail when on cooldown', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 0, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);
      const weaponSystem = new WeaponSystem(ship);

      const railgun: Weapon = {
        id: 'railgun-1',
        type: WeaponType.RAILGUN,
        mountPoint: { x: 0, y: 0, z: 10 },
        aimDirection: { x: 1, y: 0, z: 0 },
        damage: 50000,
        projectileSpeed: 3000,
        projectileMass: 5,
        range: 50000,
        rateOfFire: 10,
        powerDraw: 100,
        heatGeneration: 100000,
        ammoCapacity: 100,
        ammoRemaining: 100,
        cooldown: 5,  // On cooldown
        compartmentId: 'weapons-bay'
      };

      weaponSystem.addWeapon(railgun);

      const result = weaponSystem.fire('railgun-1', { x: 1, y: 0, z: 0 });

      expect(result.success).toBe(false);
      expect(result.reason).toBe('on_cooldown');
    });

    it('should consume ammo when firing', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 0, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);
      const weaponSystem = new WeaponSystem(ship);

      const railgun: Weapon = {
        id: 'railgun-1',
        type: WeaponType.RAILGUN,
        mountPoint: { x: 0, y: 0, z: 10 },
        aimDirection: { x: 1, y: 0, z: 0 },
        damage: 50000,
        projectileSpeed: 3000,
        projectileMass: 5,
        range: 50000,
        rateOfFire: 10,
        powerDraw: 100,
        heatGeneration: 100000,
        ammoCapacity: 100,
        ammoRemaining: 50,
        cooldown: 0,
        compartmentId: 'weapons-bay'
      };

      weaponSystem.addWeapon(railgun);

      weaponSystem.fire('railgun-1', { x: 1, y: 0, z: 0 });

      const weapon = weaponSystem.getWeapon('railgun-1');
      expect(weapon?.ammoRemaining).toBe(49);
    });

    it('should set cooldown after firing', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 0, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);
      const weaponSystem = new WeaponSystem(ship);

      const railgun: Weapon = {
        id: 'railgun-1',
        type: WeaponType.RAILGUN,
        mountPoint: { x: 0, y: 0, z: 10 },
        aimDirection: { x: 1, y: 0, z: 0 },
        damage: 50000,
        projectileSpeed: 3000,
        projectileMass: 5,
        range: 50000,
        rateOfFire: 10,  // 10 RPM = 6 second cooldown
        powerDraw: 100,
        heatGeneration: 100000,
        ammoCapacity: 100,
        ammoRemaining: 100,
        cooldown: 0,
        compartmentId: 'weapons-bay'
      };

      weaponSystem.addWeapon(railgun);

      weaponSystem.fire('railgun-1', { x: 1, y: 0, z: 0 });

      const weapon = weaponSystem.getWeapon('railgun-1');
      expect(weapon?.cooldown).toBeGreaterThan(0);
    });
  });

  describe('Projectile Physics', () => {
    it('should create projectile with ship velocity', () => {
      const projectile = new Projectile({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 1000, y: 0, z: 0 },
        mass: 5,
        damage: 50000,
        lifetime: 60
      });

      expect(projectile.getPosition()).toEqual({ x: 0, y: 0, z: 0 });
      expect(projectile.getVelocity()).toEqual({ x: 1000, y: 0, z: 0 });
    });

    it('should update projectile position', () => {
      const projectile = new Projectile({
        position: { x: 0, y: 0, z: moon.radius + 100000 },  // Above moon
        velocity: { x: 1000, y: 0, z: 0 },
        mass: 5,
        damage: 50000,
        lifetime: 60
      });

      projectile.update(1, world);

      expect(projectile.getPosition().x).toBeGreaterThan(0);
    });

    it('should apply gravity to projectile', () => {
      const projectile = new Projectile({
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 1000, y: 0, z: 0 },
        mass: 5,
        damage: 50000,
        lifetime: 60
      });

      const initialZ = projectile.getPosition().z;

      // Update multiple times to see gravity effect
      for (let i = 0; i < 10; i++) {
        projectile.update(1, world);
      }

      // Should fall toward moon
      expect(projectile.getPosition().z).toBeLessThan(initialZ);
    });

    it('should detect hit on target', () => {
      const target = CelestialBodyFactory.createAsteroid(
        'target',
        { x: 10000, y: 0, z: moon.radius + 100000 },
        { x: 0, y: 0, z: 0 },
        1000,
        50
      );
      world.addBody(target);

      const projectile = new Projectile({
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 5000, y: 0, z: 0 },  // Toward target
        mass: 5,
        damage: 50000,
        lifetime: 60
      });

      let hitDetected = false;
      projectile.on('hit', () => {
        hitDetected = true;
      });

      // Simulate until hit
      for (let i = 0; i < 10; i++) {
        projectile.update(0.5, world);
        if (!projectile.isAlive()) break;
      }

      expect(hitDetected).toBe(true);
    });

    it('should die after lifetime expires', () => {
      const projectile = new Projectile({
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 1000, y: 0, z: 0 },
        mass: 5,
        damage: 50000,
        lifetime: 5  // 5 second lifetime
      });

      expect(projectile.isAlive()).toBe(true);

      // Simulate 6 seconds
      for (let i = 0; i < 6; i++) {
        projectile.update(1, world);
      }

      expect(projectile.isAlive()).toBe(false);
    });
  });

  describe('Projectile Manager', () => {
    it('should track multiple projectiles', () => {
      const manager = new ProjectileManager();

      const p1 = new Projectile({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 1000, y: 0, z: 0 },
        mass: 5,
        damage: 50000,
        lifetime: 60
      });

      const p2 = new Projectile({
        position: { x: 1000, y: 0, z: 0 },
        velocity: { x: -1000, y: 0, z: 0 },
        mass: 5,
        damage: 50000,
        lifetime: 60
      });

      manager.addProjectile(p1);
      manager.addProjectile(p2);

      expect(manager.getProjectileCount()).toBe(2);
    });

    it('should update all projectiles', () => {
      const manager = new ProjectileManager();

      const projectile = new Projectile({
        position: { x: 0, y: 0, z: moon.radius + 100000 },  // Above moon
        velocity: { x: 1000, y: 0, z: 0 },
        mass: 5,
        damage: 50000,
        lifetime: 60
      });

      manager.addProjectile(projectile);

      manager.update(1, world);

      expect(projectile.getPosition().x).toBeGreaterThan(0);
    });

    it('should remove dead projectiles', () => {
      const manager = new ProjectileManager();

      const projectile = new Projectile({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 1000, y: 0, z: 0 },
        mass: 5,
        damage: 50000,
        lifetime: 1  // 1 second
      });

      manager.addProjectile(projectile);

      expect(manager.getProjectileCount()).toBe(1);

      // Update past lifetime
      manager.update(2, world);

      expect(manager.getProjectileCount()).toBe(0);
    });
  });

  describe('Weapon Cooldown', () => {
    it('should decrease cooldown over time', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 0, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);
      const weaponSystem = new WeaponSystem(ship);

      const railgun: Weapon = {
        id: 'railgun-1',
        type: WeaponType.RAILGUN,
        mountPoint: { x: 0, y: 0, z: 10 },
        aimDirection: { x: 1, y: 0, z: 0 },
        damage: 50000,
        projectileSpeed: 3000,
        projectileMass: 5,
        range: 50000,
        rateOfFire: 10,
        powerDraw: 100,
        heatGeneration: 100000,
        ammoCapacity: 100,
        ammoRemaining: 100,
        cooldown: 5,
        compartmentId: 'weapons-bay'
      };

      weaponSystem.addWeapon(railgun);

      weaponSystem.update(3);

      const weapon = weaponSystem.getWeapon('railgun-1');
      expect(weapon?.cooldown).toBe(2);
    });

    it('should allow firing after cooldown expires', () => {
      const config: ShipConfiguration = {
        mass: 50000,
        radius: 10,
        position: { x: 0, y: 0, z: moon.radius + 100000 },
        velocity: { x: 0, y: 0, z: 0 }
      };

      const ship = new IntegratedShip(config, world);
      const weaponSystem = new WeaponSystem(ship);

      const railgun: Weapon = {
        id: 'railgun-1',
        type: WeaponType.RAILGUN,
        mountPoint: { x: 0, y: 0, z: 10 },
        aimDirection: { x: 1, y: 0, z: 0 },
        damage: 50000,
        projectileSpeed: 3000,
        projectileMass: 5,
        range: 50000,
        rateOfFire: 10,
        powerDraw: 100,
        heatGeneration: 100000,
        ammoCapacity: 100,
        ammoRemaining: 100,
        cooldown: 2,
        compartmentId: 'weapons-bay'
      };

      weaponSystem.addWeapon(railgun);

      // Wait for cooldown
      weaponSystem.update(3);

      const result = weaponSystem.fire('railgun-1', { x: 1, y: 0, z: 0 });
      expect(result.success).toBe(true);
    });
  });
});
