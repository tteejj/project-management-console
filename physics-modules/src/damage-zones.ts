/**
 * Damage Zone System
 *
 * Maps 3D hit coordinates to ship zones and applies zone-specific damage effects.
 * Based on SPACECRAFT_INTEGRATION.md damage zones (Lines 287-309).
 *
 * Features:
 * - 12 defined damage zones with coordinate boundaries
 * - Zone-specific critical hit effects
 * - Armor penetration calculations
 * - Critical hit probability per zone
 * - Damage propagation to affected systems
 * - Crew casualty tracking
 */

import { CrewSystem } from './crew-system';

export interface DamageZone {
  id: string;
  name: string;
  bounds: {
    xMin: number; xMax: number;
    yMin: number; yMax: number;
    zMin: number; zMax: number;
  };
  criticalSystems: string[]; // System IDs in this zone
  crewPositions: number; // Number of crew normally in this zone
  criticalHitChance: number; // 0-1 probability
  armorThickness: number; // mm
  description: string;
}

export interface DamageReport {
  hit: boolean;
  zoneName: string;
  zoneId?: string;
  damage: number; // Damage points
  isCritical?: boolean;
  penetration?: number; // mm penetrated
  affectedSystems?: string[];
  effects: string[];
  hitPosition?: { x: number; y: number; z: number };
}

export class DamageZoneSystem {
  private zones: DamageZone[] = [];
  private damageHistory: DamageReport[] = [];
  private crewSystem: CrewSystem | null = null;

  constructor() {
    this.initializeZones();
  }

  /**
   * Register crew system for casualty tracking
   */
  public registerCrewSystem(crewSystem: CrewSystem): void {
    this.crewSystem = crewSystem;
  }

  /**
   * Initialize zones based on SPACECRAFT_INTEGRATION.md (Lines 287-309)
   */
  private initializeZones(): void {
    this.zones = [
      // Zone 1: Forward Nose
      {
        id: 'forward_nose',
        name: 'Forward Nose',
        bounds: { xMin: -5, xMax: 5, yMin: -2, yMax: 6, zMin: 18, zMax: 25 },
        criticalSystems: ['radar', 'docking_port', 'forward_sensors', 'particle_beam'],
        crewPositions: 0, // No crew normally stationed here
        criticalHitChance: 0.3,
        armorThickness: 50,
        description: 'Sensors, radar, docking port, particle beam weapon'
      },

      // Zone 2: Bridge/Command
      {
        id: 'bridge',
        name: 'Bridge/Command',
        bounds: { xMin: -6, xMax: 6, yMin: 4, yMax: 6, zMin: 10, zMax: 18 },
        criticalSystems: ['flight_control', 'nav_computer', 'crew', 'observation_dome'],
        crewPositions: 3, // Bridge: 3 crew (Commander, Pilot, Sensors)
        criticalHitChance: 0.8, // Very high - crew casualties likely
        armorThickness: 100,
        description: 'Command center, crew quarters, critical control systems'
      },

      // Zone 3: Forward Weapons
      {
        id: 'forward_weapons',
        name: 'Forward Weapons',
        bounds: { xMin: -7, xMax: 7, yMin: -1, yMax: 4, zMin: 5, zMax: 15 },
        criticalSystems: ['forward_railgun', 'port_vls', 'starboard_vls', 'dorsal_autocannon'],
        crewPositions: 1, // Weapons: 1 crew (Weapons Officer)
        criticalHitChance: 0.5,
        armorThickness: 150, // Well armored weapons
        description: 'Railgun, missile launchers, autocannon turret'
      },

      // Zone 4: Port Wing
      {
        id: 'port_wing',
        name: 'Port Wing',
        bounds: { xMin: -9, xMax: -6, yMin: -4, yMax: 4, zMin: -10, zMax: 10 },
        criticalSystems: ['port_radiator', 'port_fuel_tank', 'port_rcs'],
        crewPositions: 0, // No crew normally stationed here
        criticalHitChance: 0.4,
        armorThickness: 30, // Thin armor on radiators
        description: 'Port radiator panels, fuel tank, RCS thrusters'
      },

      // Zone 5: Starboard Wing
      {
        id: 'starboard_wing',
        name: 'Starboard Wing',
        bounds: { xMin: 6, xMax: 9, yMin: -4, yMax: 4, zMin: -10, zMax: 10 },
        criticalSystems: ['starboard_radiator', 'starboard_fuel_tank', 'starboard_rcs'],
        crewPositions: 0, // No crew normally stationed here
        criticalHitChance: 0.4,
        armorThickness: 30,
        description: 'Starboard radiator panels, fuel tank, RCS thrusters'
      },

      // Zone 6: Cargo Bay
      {
        id: 'cargo_bay',
        name: 'Cargo Bay',
        bounds: { xMin: -6, xMax: 6, yMin: -2, yMax: 2, zMin: -5, zMax: 5 },
        criticalSystems: ['cargo_bay', 'cargo_crane'],
        crewPositions: 0, // No crew normally stationed here
        criticalHitChance: 0.2, // Low criticality
        armorThickness: 80,
        description: 'Main cargo storage, minimal critical systems'
      },

      // Zone 7: Engineering Core
      {
        id: 'engineering_core',
        name: 'Engineering Core',
        bounds: { xMin: -5, xMax: 5, yMin: -4, yMax: 0, zMin: -10, zMax: 0 },
        criticalSystems: ['reactor', 'batteries', 'coolant_system', 'thermal_control'],
        crewPositions: 1, // Engineering: 1 crew (Engineer)
        criticalHitChance: 0.9, // CATASTROPHIC if hit
        armorThickness: 200, // Heavily armored
        description: 'Reactor, batteries, critical power systems'
      },

      // Zone 8: Propulsion
      {
        id: 'propulsion',
        name: 'Propulsion',
        bounds: { xMin: -6, xMax: 6, yMin: -4, yMax: 0, zMin: -25, zMax: -15 },
        criticalSystems: ['main_engine', 'fuel_feeds', 'engine_gimbal'],
        crewPositions: 0, // No crew normally stationed here
        criticalHitChance: 0.7,
        armorThickness: 120,
        description: 'Main engine, fuel feeds, propulsion systems'
      },

      // Zone 9: Dorsal Hull
      {
        id: 'dorsal_hull',
        name: 'Dorsal Hull',
        bounds: { xMin: -6, xMax: 6, yMin: 4, yMax: 7, zMin: -10, zMax: 10 },
        criticalSystems: ['dorsal_pd_turret', 's_band_antenna', 'esm_array'],
        crewPositions: 0, // No crew normally stationed here
        criticalHitChance: 0.3,
        armorThickness: 60,
        description: 'PD turret, antennas, sensor arrays'
      },

      // Zone 10: Ventral Hull
      {
        id: 'ventral_hull',
        name: 'Ventral Hull',
        bounds: { xMin: -6, xMax: 6, yMin: -5, yMax: -2, zMin: -10, zMax: 10 },
        criticalSystems: ['ventral_laser', 'landing_gear', 'vhf_antenna'],
        crewPositions: 0, // No crew normally stationed here
        criticalHitChance: 0.4,
        armorThickness: 70,
        description: 'Laser turret, landing gear, lower antennas'
      },

      // Zone 11: Port Systems
      {
        id: 'port_systems',
        name: 'Port Systems',
        bounds: { xMin: -6, xMax: -4, yMin: -2, yMax: 4, zMin: -15, zMax: 15 },
        criticalSystems: ['port_subsystems', 'port_power_bus'],
        crewPositions: 0, // No crew normally stationed here
        criticalHitChance: 0.3,
        armorThickness: 70,
        description: 'Port-side subsystems and power distribution'
      },

      // Zone 12: Starboard Systems
      {
        id: 'starboard_systems',
        name: 'Starboard Systems',
        bounds: { xMin: 4, xMax: 6, yMin: -2, yMax: 4, zMin: -15, zMax: 15 },
        criticalSystems: ['starboard_subsystems', 'starboard_power_bus'],
        crewPositions: 0, // No crew normally stationed here
        criticalHitChance: 0.3,
        armorThickness: 70,
        description: 'Starboard-side subsystems and power distribution'
      }
    ];
  }

  /**
   * Determine which zone was hit by a projectile/beam
   */
  public getHitZone(hitPosition: { x: number; y: number; z: number }): DamageZone | null {
    for (const zone of this.zones) {
      if (this.isPointInZone(hitPosition, zone)) {
        return zone;
      }
    }
    return null; // Miss or hit outside defined zones
  }

  /**
   * Check if a point is within a zone's boundaries
   */
  private isPointInZone(
    point: { x: number; y: number; z: number },
    zone: DamageZone
  ): boolean {
    return (
      point.x >= zone.bounds.xMin && point.x <= zone.bounds.xMax &&
      point.y >= zone.bounds.yMin && point.y <= zone.bounds.yMax &&
      point.z >= zone.bounds.zMin && point.z <= zone.bounds.zMax
    );
  }

  /**
   * Calculate damage for a kinetic hit
   */
  public calculateKineticDamage(
    hitPosition: { x: number; y: number; z: number },
    projectileMass: number, // kg
    velocity: number // m/s
  ): DamageReport {
    const zone = this.getHitZone(hitPosition);

    if (!zone) {
      return {
        hit: false,
        zoneName: 'MISS',
        damage: 0,
        effects: [],
        hitPosition
      };
    }

    // Calculate kinetic energy: KE = 0.5 * m * v²
    const kineticEnergyJ = 0.5 * projectileMass * velocity * velocity;
    const kineticEnergyMJ = kineticEnergyJ / 1000000;

    // Check armor penetration
    const penetration = this.calculatePenetration(kineticEnergyMJ, zone.armorThickness);

    if (penetration <= 0) {
      return {
        hit: true,
        zoneName: zone.name,
        zoneId: zone.id,
        damage: 0,
        penetration: 0,
        effects: ['ARMOR_DEFLECT'],
        hitPosition
      };
    }

    // Calculate base damage (scales with energy)
    const baseDamage = kineticEnergyMJ * 10; // Damage points

    // Roll for critical hit
    const isCritical = Math.random() < zone.criticalHitChance;
    const finalDamage = isCritical ? baseDamage * 2 : baseDamage;

    const effects: string[] = ['KINETIC_IMPACT'];

    if (isCritical) {
      effects.push('CRITICAL_HIT');
      effects.push(...this.getCriticalEffects(zone));
    }

    // Spalling effect (fragments inside hull)
    if (penetration > zone.armorThickness * 0.5) {
      effects.push('SPALLING');
    }

    const report: DamageReport = {
      hit: true,
      zoneName: zone.name,
      zoneId: zone.id,
      damage: finalDamage,
      isCritical,
      penetration,
      affectedSystems: zone.criticalSystems,
      effects,
      hitPosition
    };

    // Apply crew casualties if applicable
    this.applyCrewCasualties(zone, finalDamage, isCritical);

    this.damageHistory.push(report);
    return report;
  }

  /**
   * Calculate damage for an energy weapon hit (laser/particle beam)
   */
  public calculateEnergyDamage(
    hitPosition: { x: number; y: number; z: number },
    energyDeliveredJ: number, // Joules delivered
    dwellTime: number, // seconds
    weaponType: 'laser' | 'particle_beam'
  ): DamageReport {
    const zone = this.getHitZone(hitPosition);

    if (!zone) {
      return {
        hit: false,
        zoneName: 'MISS',
        damage: 0,
        effects: [],
        hitPosition
      };
    }

    const energyMJ = energyDeliveredJ / 1000000;

    // Energy weapons bypass some armor (thermal/radiation damage)
    const effectiveArmor = zone.armorThickness * 0.6; // 40% bypass
    const penetration = this.calculateEnergyPenetration(energyMJ, dwellTime, effectiveArmor);

    if (penetration <= 0) {
      return {
        hit: true,
        zoneName: zone.name,
        zoneId: zone.id,
        damage: energyMJ * 2, // Surface damage even without penetration
        penetration: 0,
        effects: ['SURFACE_HEATING'],
        hitPosition
      };
    }

    const baseDamage = energyMJ * 15; // Energy weapons are very damaging
    const isCritical = Math.random() < zone.criticalHitChance;
    const finalDamage = isCritical ? baseDamage * 2 : baseDamage;

    const effects: string[] = [
      weaponType === 'laser' ? 'LASER_BURN' : 'RADIATION_DAMAGE',
      'THERMAL_DAMAGE'
    ];

    if (isCritical) {
      effects.push('CRITICAL_HIT');
      effects.push(...this.getCriticalEffects(zone));
    }

    // Energy weapons can cause fires
    if (energyMJ > 5 && Math.random() < 0.3) {
      effects.push('FIRE');
    }

    // Particle beams cause electronics damage
    if (weaponType === 'particle_beam') {
      effects.push('ELECTRONICS_DAMAGE');
    }

    const report: DamageReport = {
      hit: true,
      zoneName: zone.name,
      zoneId: zone.id,
      damage: finalDamage,
      isCritical,
      penetration,
      affectedSystems: zone.criticalSystems,
      effects,
      hitPosition
    };

    // Apply crew casualties if applicable
    this.applyCrewCasualties(zone, finalDamage, isCritical);

    this.damageHistory.push(report);
    return report;
  }

  /**
   * Calculate damage for an explosive hit (missile warhead)
   */
  public calculateExplosiveDamage(
    hitPosition: { x: number; y: number; z: number },
    explosiveYieldKg: number // kg TNT equivalent
  ): DamageReport {
    const zone = this.getHitZone(hitPosition);

    if (!zone) {
      return {
        hit: false,
        zoneName: 'MISS',
        damage: 0,
        effects: [],
        hitPosition
      };
    }

    // Blast radius: R = Y^(1/3) * k, where k ≈ 2 for space
    const blastRadius = Math.pow(explosiveYieldKg, 1/3) * 2; // meters

    // Overpressure penetration
    const penetration = explosiveYieldKg * 10; // Simplified

    const baseDamage = explosiveYieldKg * 20; // Explosives are devastating
    const isCritical = Math.random() < Math.min(0.9, zone.criticalHitChance * 1.5);
    const finalDamage = isCritical ? baseDamage * 2 : baseDamage;

    const effects: string[] = ['EXPLOSIVE_BLAST', 'FRAGMENTATION'];

    if (isCritical) {
      effects.push('CRITICAL_HIT');
      effects.push(...this.getCriticalEffects(zone));
    }

    // Explosive damage affects multiple zones
    const affectedSystems = [...zone.criticalSystems];
    const nearbyZones = this.getZonesInRadius(hitPosition, blastRadius);
    for (const nearbyZone of nearbyZones) {
      if (nearbyZone.id !== zone.id) {
        affectedSystems.push(...nearbyZone.criticalSystems);
        effects.push(`BLAST_DAMAGE_${nearbyZone.id.toUpperCase()}`);
      }
    }

    // Hull breach likely
    if (explosiveYieldKg > 10) {
      effects.push('HULL_BREACH');
    }

    const report: DamageReport = {
      hit: true,
      zoneName: zone.name,
      zoneId: zone.id,
      damage: finalDamage,
      isCritical,
      penetration,
      affectedSystems,
      effects,
      hitPosition
    };

    // Apply crew casualties if applicable
    this.applyCrewCasualties(zone, finalDamage, isCritical);

    this.damageHistory.push(report);
    return report;
  }

  /**
   * Calculate kinetic penetration depth
   * Simplified De Marre formula
   */
  private calculatePenetration(kineticEnergyMJ: number, armorThickness: number): number {
    // Penetration (mm) ≈ Energy (MJ) * 20 (empirical constant)
    const penetrationMM = kineticEnergyMJ * 20;
    return penetrationMM - armorThickness;
  }

  /**
   * Calculate energy weapon penetration
   */
  private calculateEnergyPenetration(
    energyMJ: number,
    dwellTime: number,
    armorThickness: number
  ): number {
    // Energy weapons depend on dwell time
    // Penetration ≈ (Energy * dwellTime) / armor_resistance
    const penetrationMM = (energyMJ * dwellTime * 5);
    return penetrationMM - armorThickness;
  }

  /**
   * Get zones within blast radius
   */
  private getZonesInRadius(
    center: { x: number; y: number; z: number },
    radius: number
  ): DamageZone[] {
    return this.zones.filter(zone => {
      // Check if zone bounds intersect with sphere
      const zoneCenterX = (zone.bounds.xMin + zone.bounds.xMax) / 2;
      const zoneCenterY = (zone.bounds.yMin + zone.bounds.yMax) / 2;
      const zoneCenterZ = (zone.bounds.zMin + zone.bounds.zMax) / 2;

      const dx = zoneCenterX - center.x;
      const dy = zoneCenterY - center.y;
      const dz = zoneCenterZ - center.z;
      const distance = Math.sqrt(dx*dx + dy*dy + dz*dz);

      return distance <= radius;
    });
  }

  /**
   * Get critical effects for a zone (from SPACECRAFT_INTEGRATION.md Lines 302-309)
   */
  private getCriticalEffects(zone: DamageZone): string[] {
    const criticalEffects: Record<string, string[]> = {
      'bridge': ['CREW_CASUALTIES', 'CONTROL_LOSS', 'NAVIGATION_OFFLINE'],
      'engineering_core': ['POWER_LOSS', 'RADIATION_LEAK', 'MELTDOWN_RISK', 'CASCADING_FAILURE'],
      'port_wing': ['PROPELLANT_LEAK', 'EXPLOSION_RISK', 'THERMAL_OVERLOAD'],
      'starboard_wing': ['PROPELLANT_LEAK', 'EXPLOSION_RISK', 'THERMAL_OVERLOAD'],
      'forward_weapons': ['WEAPON_DISABLED', 'MAGAZINE_EXPLOSION_RISK'],
      'dorsal_hull': ['WEAPON_DISABLED'],
      'ventral_hull': ['WEAPON_DISABLED', 'LANDING_GEAR_DAMAGED'],
      'propulsion': ['THRUST_LOSS', 'FUEL_LEAK', 'ENGINE_FAILURE'],
      'forward_nose': ['SENSOR_BLIND', 'DOCKING_DISABLED'],
      'cargo_bay': ['CARGO_LOST', 'HULL_BREACH'],
      'port_systems': ['SUBSYSTEM_FAILURE', 'POWER_BUS_DAMAGED'],
      'starboard_systems': ['SUBSYSTEM_FAILURE', 'POWER_BUS_DAMAGED']
    };

    return criticalEffects[zone.id] || [];
  }

  /**
   * Apply crew casualties from zone damage
   */
  private applyCrewCasualties(zone: DamageZone, damage: number, isCritical: boolean): void {
    if (!this.crewSystem || zone.crewPositions === 0) {
      return; // No crew system registered or no crew in this zone
    }

    // Calculate casualty probability based on damage and critical hit
    // Higher damage and critical hits increase casualty risk
    const baseCasualtyChance = Math.min(0.8, damage / 100); // Max 80% base chance
    const criticalMultiplier = isCritical ? 2.0 : 1.0;
    const casualtyChance = Math.min(0.95, baseCasualtyChance * criticalMultiplier);

    // Only apply casualties if random roll succeeds
    if (Math.random() < casualtyChance) {
      // Calculate severity based on damage amount
      const severity = Math.min(1.0, damage / 200); // Normalize to 0-1

      // Apply damage to crew in this zone
      this.crewSystem.applyCrewDamage(zone.id, severity);
    }
  }

  /**
   * Get all zones
   */
  public getAllZones(): DamageZone[] {
    return [...this.zones];
  }

  /**
   * Get zone by ID
   */
  public getZone(id: string): DamageZone | undefined {
    return this.zones.find(z => z.id === id);
  }

  /**
   * Get damage history
   */
  public getDamageHistory(): DamageReport[] {
    return [...this.damageHistory];
  }

  /**
   * Clear damage history
   */
  public clearHistory(): void {
    this.damageHistory = [];
  }

  /**
   * Get zones sorted by damage received
   */
  public getMostDamagedZones(): Array<{ zoneId: string; zoneName: string; totalDamage: number; hits: number }> {
    const zoneStats = new Map<string, { zoneName: string; totalDamage: number; hits: number }>();

    for (const report of this.damageHistory) {
      if (report.zoneId) {
        const existing = zoneStats.get(report.zoneId);
        if (existing) {
          existing.totalDamage += report.damage;
          existing.hits += 1;
        } else {
          zoneStats.set(report.zoneId, {
            zoneName: report.zoneName,
            totalDamage: report.damage,
            hits: 1
          });
        }
      }
    }

    return Array.from(zoneStats.entries())
      .map(([zoneId, stats]) => ({ zoneId, ...stats }))
      .sort((a, b) => b.totalDamage - a.totalDamage);
  }

  /**
   * Get state for debugging/telemetry
   */
  public getState() {
    return {
      zones: this.zones.map(z => ({
        id: z.id,
        name: z.name,
        criticalHitChance: z.criticalHitChance,
        armorThickness: z.armorThickness,
        systemCount: z.criticalSystems.length
      })),
      damageHistoryCount: this.damageHistory.length,
      mostDamagedZones: this.getMostDamagedZones()
    };
  }
}
