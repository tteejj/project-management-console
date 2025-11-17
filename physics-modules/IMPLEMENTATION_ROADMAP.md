# Implementation Roadmap: Addressing Critical Gaps

**Date**: 2025-11-17
**Purpose**: Detailed implementation plan with code examples for addressing identified gaps
**Reference**: See GAP_ANALYSIS.md for complete gap identification

---

## Overview

This document provides **concrete implementation strategies** for the critical gaps identified in the spacecraft simulation. Each section includes:
- Technical approach
- Code structure examples
- Integration points
- Testing strategies

---

## CRITICAL PRIORITY 1: Center of Mass (CoM) Tracking

### Technical Approach

Implement a centralized CoM tracking system that:
1. Collects mass and position from all systems
2. Calculates combined CoM and moment of inertia tensor
3. Provides this to physics and control systems
4. Updates in real-time as mass changes

### Implementation Structure

**New File**: `src/center-of-mass.ts`

```typescript
/**
 * Center of Mass Tracking System
 *
 * Tracks all mass components and calculates:
 * - Total mass
 * - Center of mass position
 * - Moment of inertia tensor
 * - Mass distribution
 */

export interface MassComponent {
  id: string;
  name: string;
  mass: number; // kg
  position: { x: number; y: number; z: number }; // meters from origin
  fixed: boolean; // true for structural components
}

export class CenterOfMassSystem {
  private components: Map<string, MassComponent> = new Map();

  // Cached calculations (updated when mass changes)
  private totalMass: number = 0;
  private centerOfMass: { x: number; y: number; z: number } = { x: 0, y: 0, z: 0 };
  private momentOfInertia: {
    Ixx: number; Iyy: number; Izz: number;
    Ixy: number; Ixz: number; Iyz: number;
  } = { Ixx: 0, Iyy: 0, Izz: 0, Ixy: 0, Ixz: 0, Iyz: 0 };

  private dirty: boolean = true; // Recalculate on next access

  /**
   * Register a mass component
   */
  public registerComponent(component: MassComponent): void {
    this.components.set(component.id, component);
    this.dirty = true;
  }

  /**
   * Update mass of a component (e.g., fuel consumption)
   */
  public updateMass(id: string, newMass: number): void {
    const component = this.components.get(id);
    if (component) {
      component.mass = newMass;
      this.dirty = true;
    }
  }

  /**
   * Update position of a component (e.g., cargo movement)
   */
  public updatePosition(id: string, position: { x: number; y: number; z: number }): void {
    const component = this.components.get(id);
    if (component && !component.fixed) {
      component.position = position;
      this.dirty = true;
    }
  }

  /**
   * Remove a component (e.g., ammunition fired)
   */
  public removeComponent(id: string): void {
    this.components.delete(id);
    this.dirty = true;
  }

  /**
   * Calculate center of mass: CoM = Σ(m_i * r_i) / Σ(m_i)
   */
  private calculate(): void {
    if (!this.dirty) return;

    let totalMass = 0;
    let sumMx = 0, sumMy = 0, sumMz = 0;

    // Calculate total mass and weighted position sum
    for (const component of this.components.values()) {
      totalMass += component.mass;
      sumMx += component.mass * component.position.x;
      sumMy += component.mass * component.position.y;
      sumMz += component.mass * component.position.z;
    }

    this.totalMass = totalMass;

    if (totalMass > 0) {
      this.centerOfMass = {
        x: sumMx / totalMass,
        y: sumMy / totalMass,
        z: sumMz / totalMass
      };
    } else {
      this.centerOfMass = { x: 0, y: 0, z: 0 };
    }

    // Calculate moment of inertia tensor relative to CoM
    // I_xx = Σ m_i * (y_i² + z_i²)
    // I_xy = Σ m_i * x_i * y_i  (products of inertia)
    let Ixx = 0, Iyy = 0, Izz = 0;
    let Ixy = 0, Ixz = 0, Iyz = 0;

    for (const component of this.components.values()) {
      // Position relative to CoM
      const dx = component.position.x - this.centerOfMass.x;
      const dy = component.position.y - this.centerOfMass.y;
      const dz = component.position.z - this.centerOfMass.z;

      const m = component.mass;

      // Diagonal terms
      Ixx += m * (dy * dy + dz * dz);
      Iyy += m * (dx * dx + dz * dz);
      Izz += m * (dx * dx + dy * dy);

      // Off-diagonal terms (products of inertia)
      Ixy += m * dx * dy;
      Ixz += m * dx * dz;
      Iyz += m * dy * dz;
    }

    this.momentOfInertia = { Ixx, Iyy, Izz, Ixy, Ixz, Iyz };
    this.dirty = false;
  }

  /**
   * Get current center of mass
   */
  public getCoM(): { x: number; y: number; z: number } {
    this.calculate();
    return { ...this.centerOfMass };
  }

  /**
   * Get total mass
   */
  public getTotalMass(): number {
    this.calculate();
    return this.totalMass;
  }

  /**
   * Get moment of inertia tensor
   */
  public getMomentOfInertia() {
    this.calculate();
    return { ...this.momentOfInertia };
  }

  /**
   * Get offset from origin to CoM
   * Used by RCS to compensate thrust
   */
  public getCoMOffset(): { x: number; y: number; z: number } {
    this.calculate();
    return this.centerOfMass;
  }

  /**
   * Get full state for debugging
   */
  public getState() {
    this.calculate();
    return {
      totalMass: this.totalMass,
      centerOfMass: this.centerOfMass,
      momentOfInertia: this.momentOfInertia,
      componentCount: this.components.size,
      components: Array.from(this.components.values())
    };
  }
}
```

### Integration Points

**1. Spacecraft Constructor** (`spacecraft.ts`):
```typescript
export class Spacecraft {
  public comSystem: CenterOfMassSystem;

  constructor(config?: SpacecraftConfig) {
    // Initialize CoM system FIRST
    this.comSystem = new CenterOfMassSystem();

    // Register fixed structural mass
    this.comSystem.registerComponent({
      id: 'hull_structure',
      name: 'Hull Structure',
      mass: 15000, // kg (from SPACECRAFT_INTEGRATION.md)
      position: { x: 0, y: 0, z: 0 },
      fixed: true
    });

    this.comSystem.registerComponent({
      id: 'reactor',
      name: 'Reactor',
      mass: 8000,
      position: { x: 0, y: -2, z: -5 }, // From layout doc
      fixed: true
    });

    this.comSystem.registerComponent({
      id: 'main_engine',
      name: 'Main Engine',
      mass: 5000,
      position: { x: 0, y: -3, z: -22 },
      fixed: true
    });

    // ... register all fixed components

    // Initialize fuel system
    this.fuel = new FuelSystem(config?.fuelConfig);

    // Register fuel tanks with initial mass
    const tanks = this.fuel.getState().tanks;
    for (const tank of tanks) {
      this.comSystem.registerComponent({
        id: `fuel_${tank.id}`,
        name: `Fuel Tank ${tank.id}`,
        mass: tank.fuelMass,
        position: this.getFuelTankPosition(tank.id), // Define positions
        fixed: true // Tanks don't move, fuel inside does
      });
    }

    // ... rest of initialization
  }

  private getFuelTankPosition(tankId: string): { x: number; y: number; z: number } {
    // Map tank IDs to physical positions from layout
    const positions: Record<string, { x: number; y: number; z: number }> = {
      'main_1': { x: -3, y: -2, z: -10 }, // Port main tank
      'main_2': { x: 3, y: -2, z: -10 },  // Starboard main tank
      'rcs': { x: 0, y: -1, z: 0 }        // RCS tank (distributed, use avg)
    };
    return positions[tankId] || { x: 0, y: 0, z: 0 };
  }
}
```

**2. Update Fuel Mass** (`spacecraft.ts:329-334`):
```typescript
// Current code consumes fuel
this.fuel.consumeFuel('main_1', mainFuelAmount);
this.fuel.consumeFuel('main_2', mainOxidizerAmount);
this.fuel.consumeFuel('rcs', rcsFuelConsumption);

// ADD: Update CoM system
const fuelState = this.fuel.getState();
for (const tank of fuelState.tanks) {
  this.comSystem.updateMass(`fuel_${tank.id}`, tank.fuelMass);
}
```

**3. Update Ship Physics** (`ship-physics.ts`):
```typescript
export class ShipPhysics {
  // Add CoM offset property
  private comOffset: { x: number; y: number; z: number } = { x: 0, y: 0, z: 0 };

  /**
   * Set center of mass offset from origin
   * Called by spacecraft.ts every update
   */
  public setCoMOffset(offset: { x: number; y: number; z: number }): void {
    this.comOffset = offset;
  }

  /**
   * Set moment of inertia tensor
   */
  public setMomentOfInertia(I: {
    Ixx: number; Iyy: number; Izz: number;
    Ixy: number; Ixz: number; Iyz: number;
  }): void {
    // Use full inertia tensor instead of simplified calculation
    this.momentOfInertia = {
      x: I.Ixx,
      y: I.Iyy,
      z: I.Izz
    };
    // TODO: Use full 3x3 tensor for coupled rotation
  }

  // In update method, account for CoM offset when applying forces
  update(
    dt: number,
    mainThrust: { x: number; y: number; z: number },
    mainTorque: { x: number; y: number; z: number },
    rcsThrust: { x: number; y: number; z: number },
    rcsTorque: { x: number; y: number; z: number },
    propellantConsumed: number
  ): void {
    // ... existing code ...

    // Apply thrust at CoM offset to calculate torque
    const thrustTorque = this.calculateTorqueFromThrust(
      mainThrust,
      this.comOffset
    );

    totalTorque.x += thrustTorque.x;
    totalTorque.y += thrustTorque.y;
    totalTorque.z += thrustTorque.z;

    // ... rest of update ...
  }

  private calculateTorqueFromThrust(
    force: { x: number; y: number; z: number },
    offset: { x: number; y: number; z: number }
  ): { x: number; y: number; z: number } {
    // Torque = r × F (cross product)
    return {
      x: offset.y * force.z - offset.z * force.y,
      y: offset.z * force.x - offset.x * force.z,
      z: offset.x * force.y - offset.y * force.x
    };
  }
}
```

**4. RCS Compensation** (`rcs-system.ts`):
```typescript
export class RCSSystem {
  private comOffset: { x: number; y: number; z: number } = { x: 0, y: 0, z: 0 };

  /**
   * Set CoM offset for thrust compensation
   */
  public setCoMOffset(offset: { x: number; y: number; z: number }): void {
    this.comOffset = offset;
  }

  /**
   * Calculate thrust for translation without rotation
   * Accounts for CoM offset
   */
  private calculateCompensatedThrust(
    desiredTranslation: { x: number; y: number; z: number }
  ): Array<{ thruster: string; thrust: number }> {
    // For each thruster, calculate:
    // 1. Linear thrust contribution
    // 2. Torque induced by offset from CoM
    // 3. Compensate with opposite thrusters

    // This is complex - see Kerbal Space Program RCS balancing
    // for reference implementation
  }
}
```

**5. Weapon Ammunition Tracking** (`kinetic-weapons.ts`):
```typescript
export class KineticWeapon {
  private comSystem?: CenterOfMassSystem;

  /**
   * Register with CoM system for ammo tracking
   */
  public registerCoMSystem(comSystem: CenterOfMassSystem): void {
    this.comSystem = comSystem;

    // Register magazine mass
    comSystem.registerComponent({
      id: `ammo_${this.id}`,
      name: `${this.name} Ammunition`,
      mass: this.magazine.current * this.getProjectileMass(),
      position: this.turret.location,
      fixed: true
    });
  }

  private getProjectileMass(): number {
    // Mass per round based on caliber
    // 20mm: ~0.1 kg, 100mm railgun: ~5 kg
    return this.caliber * this.caliber * 0.00025; // Empirical
  }

  public fire(/* params */): boolean {
    const success = /* existing fire logic */;

    if (success && this.comSystem) {
      // Update ammo mass
      const newMass = this.magazine.current * this.getProjectileMass();
      this.comSystem.updateMass(`ammo_${this.id}`, newMass);
    }

    return success;
  }
}
```

### Testing Strategy

```typescript
// Test CoM calculation accuracy
describe('CenterOfMassSystem', () => {
  it('should calculate CoM for symmetric mass distribution', () => {
    const com = new CenterOfMassSystem();
    com.registerComponent({ id: '1', mass: 10, position: { x: -1, y: 0, z: 0 }, fixed: true });
    com.registerComponent({ id: '2', mass: 10, position: { x: 1, y: 0, z: 0 }, fixed: true });

    const result = com.getCoM();
    expect(result.x).toBeCloseTo(0, 6);
    expect(result.y).toBeCloseTo(0, 6);
    expect(result.z).toBeCloseTo(0, 6);
  });

  it('should shift CoM when mass changes', () => {
    const com = new CenterOfMassSystem();
    com.registerComponent({ id: 'fuel', mass: 100, position: { x: -5, y: 0, z: 0 }, fixed: true });
    com.registerComponent({ id: 'hull', mass: 100, position: { x: 5, y: 0, z: 0 }, fixed: true });

    const before = com.getCoM();
    expect(before.x).toBeCloseTo(0, 6);

    com.updateMass('fuel', 50); // Burn half the fuel
    const after = com.getCoM();
    expect(after.x).toBeGreaterThan(0); // CoM shifts toward hull
  });
});
```

---

## CRITICAL PRIORITY 2: Damage Zone System

### Technical Approach

Implement hit location detection and zone-specific damage handlers.

### Implementation Structure

**New File**: `src/damage-zones.ts`

```typescript
/**
 * Damage Zone System
 *
 * Maps 3D hit coordinates to ship zones and applies
 * zone-specific damage effects.
 */

export interface DamageZone {
  id: string;
  name: string;
  bounds: {
    xMin: number; xMax: number;
    yMin: number; yMax: number;
    zMin: number; zMax: number;
  };
  criticalSystems: string[]; // System IDs in this zone
  criticalHitChance: number; // 0-1 probability
  armorThickness: number; // mm
}

export class DamageZoneSystem {
  private zones: DamageZone[] = [];

  constructor() {
    this.initializeZones();
  }

  /**
   * Initialize zones based on SPACECRAFT_INTEGRATION.md (Lines 287-309)
   */
  private initializeZones(): void {
    this.zones = [
      {
        id: 'forward_nose',
        name: 'Forward Nose',
        bounds: { xMin: -5, xMax: 5, yMin: -2, yMax: 6, zMin: 18, zMax: 25 },
        criticalSystems: ['radar', 'docking_port', 'nav_computer'],
        criticalHitChance: 0.2,
        armorThickness: 50
      },
      {
        id: 'bridge',
        name: 'Bridge/Command',
        bounds: { xMin: -6, xMax: 6, yMin: 4, yMax: 6, zMin: 10, zMax: 18 },
        criticalSystems: ['flight_control', 'crew'],
        criticalHitChance: 0.8, // High - crew casualties
        armorThickness: 100
      },
      {
        id: 'forward_weapons',
        name: 'Forward Weapons',
        bounds: { xMin: -7, xMax: 7, yMin: -1, yMax: 4, zMin: 5, zMax: 15 },
        criticalSystems: ['forward_railgun', 'port_vls', 'starboard_vls'],
        criticalHitChance: 0.5,
        armorThickness: 150
      },
      {
        id: 'engineering_core',
        name: 'Engineering Core',
        bounds: { xMin: -5, xMax: 5, yMin: -4, yMax: 0, zMin: -10, zMax: 0 },
        criticalSystems: ['reactor', 'batteries'],
        criticalHitChance: 0.9, // Catastrophic if hit
        armorThickness: 200 // Heavily armored
      },
      // ... all 12 zones from documentation
    ];
  }

  /**
   * Determine which zone was hit
   */
  public getHitZone(hitPosition: { x: number; y: number; z: number }): DamageZone | null {
    for (const zone of this.zones) {
      if (this.isPointInZone(hitPosition, zone)) {
        return zone;
      }
    }
    return null; // Miss or hit outside defined zones
  }

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
   * Calculate damage for a hit
   */
  public calculateDamage(
    hitPosition: { x: number; y: number; z: number },
    kineticEnergy: number, // Joules for kinetic hits
    thermalEnergy: number,  // Joules for energy weapons
    explosiveYield: number  // kg TNT equivalent for missiles
  ): DamageReport {
    const zone = this.getHitZone(hitPosition);

    if (!zone) {
      return { hit: false, zoneName: 'MISS', damage: 0, effects: [] };
    }

    // Check if penetrates armor
    const penetration = this.calculatePenetration(kineticEnergy, zone.armorThickness);

    if (penetration <= 0) {
      return {
        hit: true,
        zoneName: zone.name,
        damage: 0,
        effects: ['ARMOR_DEFLECT']
      };
    }

    // Roll for critical hit
    const isCritical = Math.random() < zone.criticalHitChance;

    const baseDamage = kineticEnergy / 1000000; // MJ → damage points
    const finalDamage = isCritical ? baseDamage * 2 : baseDamage;

    const effects: string[] = [];

    if (isCritical) {
      effects.push('CRITICAL_HIT');
      effects.push(...this.getCriticalEffects(zone));
    }

    // Thermal/explosive damage
    if (thermalEnergy > 0) {
      effects.push('THERMAL_DAMAGE');
    }
    if (explosiveYield > 0) {
      effects.push('EXPLOSIVE_DAMAGE');
      // Explosive hits multiple systems
      const blastRadius = Math.pow(explosiveYield, 1/3) * 2; // meters
      // Find nearby zones...
    }

    return {
      hit: true,
      zoneName: zone.name,
      zoneId: zone.id,
      damage: finalDamage,
      isCritical,
      penetration,
      affectedSystems: zone.criticalSystems,
      effects
    };
  }

  private calculatePenetration(kineticEnergy: number, armorThickness: number): number {
    // Simplified penetration formula
    // Real formula: De Marre formula or Lambert-Zukas
    const kineticEnergyMJ = kineticEnergy / 1000000;
    const penetrationMM = kineticEnergyMJ * 20; // Empirical
    return penetrationMM - armorThickness;
  }

  private getCriticalEffects(zone: DamageZone): string[] {
    // Zone-specific critical effects from doc (Lines 302-309)
    const criticalEffects: Record<string, string[]> = {
      'bridge': ['CREW_CASUALTIES', 'CONTROL_LOSS'],
      'engineering_core': ['POWER_LOSS', 'RADIATION_LEAK', 'MELTDOWN_RISK'],
      'fuel_tanks': ['PROPELLANT_LEAK', 'EXPLOSION_RISK'],
      'forward_weapons': ['WEAPON_DISABLED', 'MAGAZINE_EXPLOSION_RISK'],
      'radiators': ['THERMAL_OVERLOAD', 'CASCADING_FAILURE'],
      'propulsion': ['THRUST_LOSS', 'FUEL_LEAK']
    };

    return criticalEffects[zone.id] || [];
  }
}

export interface DamageReport {
  hit: boolean;
  zoneName: string;
  zoneId?: string;
  damage: number;
  isCritical?: boolean;
  penetration?: number;
  affectedSystems?: string[];
  effects: string[];
}
```

### Integration with Weapons

**In `weapons-control.ts`**:
```typescript
export class WeaponsControlSystem {
  private damageZones: DamageZoneSystem;

  constructor() {
    // ... existing ...
    this.damageZones = new DamageZoneSystem();
  }

  /**
   * Modified hit checking with zone-based damage
   */
  private checkProjectileHits(): void {
    const hits = this.projectileManager.checkHits(targetArray);

    for (const hit of hits) {
      // Get projectile details
      const projectile = this.projectileManager.getProjectile(hit.projectileId);
      const kineticEnergy = 0.5 * projectile.mass * projectile.velocity * projectile.velocity;

      // Calculate zone-based damage
      const damageReport = this.damageZones.calculateDamage(
        hit.hitPosition,
        kineticEnergy,
        0, // thermal
        0  // explosive
      );

      if (damageReport.hit && damageReport.affectedSystems) {
        // Apply damage to specific systems
        for (const systemId of damageReport.affectedSystems) {
          this.damageSystem(systemId, damageReport.damage);
        }

        // Process critical effects
        for (const effect of damageReport.effects) {
          this.processDamageEffect(effect, damageReport);
        }
      }

      // Log event
      this.events.push({
        type: 'ZONE_HIT',
        timestamp: Date.now(),
        zone: damageReport.zoneName,
        damage: damageReport.damage,
        critical: damageReport.isCritical,
        effects: damageReport.effects
      });
    }
  }

  private damageSystem(systemId: string, damage: number): void {
    // Map system IDs to actual subsystems
    // This requires systems to expose damage methods
  }

  private processDamageEffect(effect: string, report: DamageReport): void {
    switch (effect) {
      case 'RADIATION_LEAK':
        // Increase environmental radiation
        break;
      case 'PROPELLANT_LEAK':
        // Start fuel leak over time
        break;
      case 'MAGAZINE_EXPLOSION_RISK':
        // Roll for catastrophic explosion
        if (Math.random() < 0.3) {
          // Kaboom
        }
        break;
      // ... handle all effects
    }
  }
}
```

---

## CRITICAL PRIORITY 3: Sensor Systems

### Implementation Structure

**New File**: `src/sensor-system.ts`

```typescript
/**
 * Unified Sensor System
 *
 * Combines radar, optical, IR, and passive sensors
 * with realistic detection ranges and signal degradation.
 */

export interface SensorContact {
  id: string;
  position: { x: number; y: number; z: number };
  velocity?: { x: number; y: number; z: number };
  detectionMethod: 'radar' | 'optical' | 'ir' | 'esm';
  signalStrength: number; // 0-1
  confidence: number; // 0-1 (affected by jamming, range)
  trackQuality: 'firm' | 'tentative' | 'lost';
  lastUpdate: number; // timestamp
  classification?: 'ship' | 'missile' | 'debris' | 'unknown';
}

export class SensorSystem {
  // Radar
  private radarPower: number = 100000; // Watts
  private radarFrequency: number = 10e9; // 10 GHz (X-band)
  private radarGain: number = 40; // dB
  private radarEnabled: boolean = true;

  // Optical
  private opticalAperture: number = 0.5; // meters
  private opticalFOV: number = 60; // degrees

  // IR
  private irSensitivity: number = 0.1; // W/m² minimum detectable

  // Passive ESM
  private esmBands: number[] = [1e9, 10e9, 100e9]; // Frequency coverage

  private contacts: Map<string, SensorContact> = new Map();

  /**
   * Update sensor scans
   */
  public update(
    dt: number,
    ownPosition: { x: number; y: number; z: number },
    targets: Array<{
      id: string;
      position: { x: number; y: number; z: number };
      velocity: { x: number; y: number; z: number };
      radarCrossSection: number; // m²
      thermalSignature: number; // Watts radiated
      emitting: boolean; // Radar/comms active
    }>
  ): void {
    // Age existing contacts
    for (const contact of this.contacts.values()) {
      const age = Date.now() - contact.lastUpdate;
      if (age > 5000) { // 5 seconds old
        contact.trackQuality = 'lost';
      } else if (age > 2000) {
        contact.trackQuality = 'tentative';
      }
    }

    // Scan for new/updated contacts
    for (const target of targets) {
      const range = this.calculateRange(ownPosition, target.position);

      // Try each sensor type
      const radarDetection = this.tryRadarDetection(target, range);
      const irDetection = this.tryIRDetection(target, range);
      const opticalDetection = this.tryOpticalDetection(target, range);
      const esmDetection = target.emitting ? this.tryESMDetection(target, range) : null;

      // Sensor fusion: combine detections
      const bestDetection = this.fuseDetections([
        radarDetection,
        irDetection,
        opticalDetection,
        esmDetection
      ].filter(d => d !== null));

      if (bestDetection) {
        this.contacts.set(target.id, {
          id: target.id,
          position: target.position,
          velocity: target.velocity,
          detectionMethod: bestDetection.method,
          signalStrength: bestDetection.strength,
          confidence: bestDetection.confidence,
          trackQuality: 'firm',
          lastUpdate: Date.now(),
          classification: this.classifyTarget(target, bestDetection)
        });
      }
    }
  }

  private calculateRange(
    pos1: { x: number; y: number; z: number },
    pos2: { x: number; y: number; z: number }
  ): number {
    const dx = pos2.x - pos1.x;
    const dy = pos2.y - pos1.y;
    const dz = pos2.z - pos1.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /**
   * Radar detection using radar range equation
   * R_max = [(P_t × G² × λ² × σ) / ((4π)³ × P_min)]^(1/4)
   */
  private tryRadarDetection(
    target: { radarCrossSection: number },
    range: number
  ): { method: 'radar'; strength: number; confidence: number } | null {
    if (!this.radarEnabled) return null;

    const c = 299792458; // Speed of light
    const wavelength = c / this.radarFrequency;
    const gain = Math.pow(10, this.radarGain / 10); // dB to linear

    // Radar range equation
    const numerator = this.radarPower * gain * gain * wavelength * wavelength * target.radarCrossSection;
    const denominator = Math.pow(4 * Math.PI, 3) * 1e-12; // Min detectable power 1 pW
    const maxRange = Math.pow(numerator / denominator, 0.25);

    if (range > maxRange) return null;

    // Signal strength degrades as R^4
    const strength = Math.pow(maxRange / range, 4);
    const confidence = Math.min(strength, 1.0);

    return { method: 'radar', strength, confidence };
  }

  /**
   * IR detection based on thermal signature
   */
  private tryIRDetection(
    target: { thermalSignature: number },
    range: number
  ): { method: 'ir'; strength: number; confidence: number } | null {
    // Power per unit area at distance
    const irradiance = target.thermalSignature / (4 * Math.PI * range * range);

    if (irradiance < this.irSensitivity) return null;

    const strength = irradiance / this.irSensitivity;
    const confidence = Math.min(strength / 10, 1.0);

    return { method: 'ir', strength, confidence };
  }

  /**
   * Optical detection (requires target to be illuminated or self-luminous)
   */
  private tryOpticalDetection(
    target: any,
    range: number
  ): { method: 'optical'; strength: number; confidence: number } | null {
    // Simplified: assume target reflects sunlight
    // Real implementation needs solar position, target albedo, etc.
    const maxOpticalRange = 100000; // 100 km

    if (range > maxOpticalRange) return null;

    const strength = 1.0 - (range / maxOpticalRange);
    return { method: 'optical', strength, confidence: strength };
  }

  /**
   * ESM detection (passive detection of emissions)
   */
  private tryESMDetection(
    target: any,
    range: number
  ): { method: 'esm'; strength: number; confidence: number } | null {
    // Friis transmission equation (from communications.ts)
    // P_r = P_t × G_t × G_r × (λ / (4πR))²

    // Assume target emitting 1 kW radar
    const targetPower = 1000;
    const wavelength = 0.03; // 10 GHz
    const receivedPower = targetPower * Math.pow(wavelength / (4 * Math.PI * range), 2);

    const minDetectable = 1e-15; // Very sensitive

    if (receivedPower < minDetectable) return null;

    const strength = receivedPower / minDetectable;
    return { method: 'esm', strength: Math.log10(strength) / 10, confidence: 0.8 };
  }

  /**
   * Sensor fusion: combine multiple detections
   */
  private fuseDetections(
    detections: Array<{ method: string; strength: number; confidence: number }>
  ): { method: any; strength: number; confidence: number } | null {
    if (detections.length === 0) return null;

    // Use detection with highest confidence
    detections.sort((a, b) => b.confidence - a.confidence);
    return detections[0] as any;
  }

  private classifyTarget(target: any, detection: any): 'ship' | 'missile' | 'debris' | 'unknown' {
    // Classification logic based on signature
    // This is placeholder - real classification is complex
    return 'unknown';
  }

  /**
   * Get all current contacts
   */
  public getContacts(): SensorContact[] {
    return Array.from(this.contacts.values())
      .filter(c => c.trackQuality !== 'lost');
  }

  /**
   * Enable/disable radar (for EMCON)
   */
  public setRadarEnabled(enabled: boolean): void {
    this.radarEnabled = enabled;
  }
}
```

---

## CRITICAL PRIORITY 4: Weapons Integration

### Power Integration

**In `systems-integrator.ts:122-275`**, add weapons to power consumers:

```typescript
private initializePowerConsumers(): void {
  // ... existing consumers ...

  // Register weapons
  this.powerConsumers.push({
    id: 'pd_autocannon',
    name: 'PD-20 Autocannon',
    basePowerW: 100, // Tracking power
    maxPowerW: 1000, // Firing power
    priority: 5,
    enabled: true,
    essential: false
  });

  this.powerConsumers.push({
    id: 'forward_railgun',
    name: 'RG-100 Railgun',
    basePowerW: 1000, // Standby
    maxPowerW: 15000000, // 15 MW per shot (capacitor)
    priority: 6,
    enabled: true,
    essential: false
  });

  // ... all weapons
}
```

**In `weapons-control.ts`**, query power availability before firing:

```typescript
export class WeaponsControlSystem {
  private powerSystem?: SystemsIntegrator;

  public setPowerSystem(powerSystem: SystemsIntegrator): void {
    this.powerSystem = powerSystem;
  }

  private canFireRailgun(): boolean {
    if (!this.powerSystem) return true; // Legacy mode

    // Check if 15 MW available or capacitor charged
    const powerState = this.powerSystem.getState().powerManagement;
    const available = powerState.generation - powerState.demand;

    if (available >= 15000000) {
      return true;
    }

    // Check capacitor (would need to add capacitor system)
    return this.railgunCapacitorCharged;
  }
}
```

### Thermal Integration

**In `weapons-control.ts`**, report heat generation:

```typescript
export class WeaponsControlSystem {
  private thermalSystem?: ThermalSystem;

  public setThermalSystem(thermal: ThermalSystem): void {
    this.thermalSystem = thermal;
  }

  public update(dt: number): void {
    // ... existing update ...

    // Report weapon heat generation
    if (this.thermalSystem) {
      let totalWeaponHeat = 0;

      for (const weapon of this.kineticWeapons.values()) {
        if (weapon.isFiring()) {
          // Autocannon: ~50 kW, Railgun: 10 MW per shot
          const heatGeneration = weapon.getHeatGeneration();
          totalWeaponHeat += heatGeneration;
        }
      }

      for (const laser of this.laserWeapons.values()) {
        if (laser.isFiring()) {
          // Laser: 8 MW continuous (80% waste heat)
          totalWeaponHeat += 8000000 * 0.8;
        }
      }

      this.thermalSystem.setHeatGeneration('weapons', totalWeaponHeat);
    }
  }
}
```

### Recoil Integration

**In `spacecraft.ts:350-357`**, apply weapon recoil:

```typescript
// After RCS thrust calculation
const rcsThrust = this.rcs.getTotalThrustVector();
const rcsTorque = this.rcs.getTotalTorque();

// ADD: Get weapon recoil
const weaponRecoil = this.weapons.getRecoilForce();
const weaponTorque = this.weapons.getRecoilTorque(this.comSystem.getCoM());

// Update ship physics with weapon recoil
this.physics.update(
  dt,
  mainEngineThrust,
  mainEngineTorque,
  {
    x: rcsThrust.x + weaponRecoil.x,
    y: rcsThrust.y + weaponRecoil.y,
    z: rcsThrust.z + weaponRecoil.z
  },
  {
    x: rcsTorque.x + weaponTorque.x,
    y: rcsTorque.y + weaponTorque.y,
    z: rcsTorque.z + weaponTorque.z
  },
  totalPropellantConsumed
);
```

**In `weapons-control.ts`**, accumulate recoil:

```typescript
export class WeaponsControlSystem {
  private accumulatedRecoil: { x: number; y: number; z: number } = { x: 0, y: 0, z: 0 };

  public update(dt: number): void {
    // Reset recoil accumulator
    this.accumulatedRecoil = { x: 0, y: 0, z: 0 };

    // ... existing update ...

    // When weapons fire, add recoil
    for (const weapon of this.kineticWeapons.values()) {
      if (weapon.justFired()) {
        const recoil = weapon.getRecoilForce();
        this.accumulatedRecoil.x += recoil.x;
        this.accumulatedRecoil.y += recoil.y;
        this.accumulatedRecoil.z += recoil.z;
      }
    }
  }

  public getRecoilForce(): { x: number; y: number; z: number } {
    return this.accumulatedRecoil;
  }

  public getRecoilTorque(comOffset: { x: number; y: number; z: number }): { x: number; y: number; z: number } {
    // Calculate torque from recoil force applied at weapon location
    // Need to track weapon locations and apply r × F
    // For now, simplified:
    return { x: 0, y: 0, z: 0 };
  }
}
```

---

## Additional Recommendations

### 1. Orbital Mechanics Implementation
- Add `orbital-mechanics.ts` module
- Implement Keplerian orbital elements
- Add Lambert solver for rendezvous
- Create maneuver node planner

### 2. Projectile Gravity
- Modify `ProjectileManager` to apply gravity to projectiles
- Integrate projectile state like ship state
- Update ballistic solver for gravity arc

### 3. Configuration System
- Create `config/` directory
- Move all hardcoded constants to JSON/YAML files
- Ship parameters, PID gains, thermal constants, etc.

### 4. Testing Infrastructure
- Add Jest or Mocha test framework
- Unit tests for physics calculations
- Integration tests for subsystem interactions
- Regression tests for known bugs

---

## Timeline Estimate

**Week 1-2**: Center of Mass System
- Implement CoMTracker (3 days)
- Integrate with all mass-changing systems (4 days)
- Update physics and RCS (3 days)
- Testing and debugging (4 days)

**Week 3**: Damage Zones
- Implement DamageZoneSystem (2 days)
- Integrate with weapons (2 days)
- Add critical effect handlers (2 days)
- Testing (1 day)

**Week 4**: Weapons Integration
- Power integration (2 days)
- Thermal integration (2 days)
- Recoil integration (2 days)
- Testing (1 day)

**Week 5**: Sensor Systems
- Implement SensorSystem (3 days)
- Sensor fusion (2 days)
- Integration with UI (2 days)

**Total**: 5 weeks for critical priorities

---

*End of Implementation Roadmap*
