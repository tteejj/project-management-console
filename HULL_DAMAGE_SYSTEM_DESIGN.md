# Hull Damage & Armor Penetration System Design

## Philosophy

Realistic damage modeling based on:
- **Impact energy** (kinetic energy = ½mv²)
- **Angle of impact** (glancing vs perpendicular)
- **Armor thickness** and material properties
- **Structural deformation** (elastic vs plastic vs catastrophic)
- **Penetration mechanics** (does it breach hull?)

Like DCS World damage modeling - physically realistic but gameplay-tuned.

---

## Hull Structure Model

### Compartmentalized Hull

```typescript
interface HullCompartment {
  id: string;
  name: string;

  // Position on ship (for determining impact location)
  position: Vector3;    // Relative to ship center
  bounds: AABB;         // Bounding box

  // Armor
  armorThickness: number;    // mm
  armorMaterial: ArmorMaterial;

  // Structural integrity
  structuralHealth: number;  // 0-100 (%)
  maxDamageCapacity: number; // Joules (before catastrophic failure)
  accumulatedDamage: number; // Joules (cumulative)

  // Deformation
  deformationLevel: number;  // 0-1 (0 = pristine, 1 = crumpled)

  // Breaches
  breaches: Breach[];

  // Systems in this compartment
  containedSystems: string[]; // IDs of systems that can be damaged
}

interface Breach {
  position: Vector3;    // Local to compartment
  diameter: number;     // m (size of hole)
  created: number;      // Simulation time
  severity: 'minor' | 'major' | 'catastrophic';
}

enum ArmorMaterial {
  ALUMINUM,       // Light, cheap, weak
  TITANIUM,       // Medium weight, strong
  COMPOSITE,      // Light, expensive, very strong
  REINFORCED_STEEL // Heavy, very strong
}

const ARMOR_PROPERTIES: Record<ArmorMaterial, {
  density: number;        // kg/m³
  yieldStrength: number;  // MPa
  hardness: number;       // Brinell
  ductility: number;      // 0-1 (how much it deforms before breaking)
}> = {
  [ArmorMaterial.ALUMINUM]: {
    density: 2700,
    yieldStrength: 200,
    hardness: 75,
    ductility: 0.6
  },
  [ArmorMaterial.TITANIUM]: {
    density: 4500,
    yieldStrength: 900,
    hardness: 350,
    ductility: 0.4
  },
  [ArmorMaterial.COMPOSITE]: {
    density: 1600,
    yieldStrength: 1500,
    hardness: 400,
    ductility: 0.2
  },
  [ArmorMaterial.REINFORCED_STEEL]: {
    density: 7850,
    yieldStrength: 800,
    hardness: 300,
    ductility: 0.5
  }
};
```

---

## Collision Impact Calculation

### Energy & Angle

```typescript
interface ImpactEvent {
  // What hit what
  projectile: CollisionObject;  // Asteroid, debris, or ship part
  target: HullCompartment;

  // Impact parameters
  impactPosition: Vector3;      // World coordinates
  impactVelocity: Vector3;      // Relative velocity (m/s)
  impactAngle: number;          // Radians from surface normal (0 = perpendicular)

  // Physics
  kineticEnergy: number;        // Joules
  momentum: Vector3;            // kg⋅m/s

  // Results (calculated)
  damageDealt: number;          // Structural damage (0-100)
  penetrated: boolean;          // Did it breach hull?
  deformation: number;          // How much hull deformed (0-1)
  breachDiameter?: number;      // m (if penetrated)
}

interface CollisionObject {
  mass: number;                 // kg
  velocity: Vector3;            // m/s
  radius: number;               // m (for spherical assumption)
  hardness: number;             // Brinell (harder = more penetration)
  material: 'rock' | 'ice' | 'metal' | 'composite';
}
```

### Impact Physics

```typescript
class DamageCalculator {
  calculateImpact(event: ImpactEvent): ImpactResult {
    // 1. Calculate kinetic energy
    const relativeSpeed = magnitude(event.impactVelocity);
    const kineticEnergy = 0.5 * event.projectile.mass * relativeSpeed * relativeSpeed;

    // 2. Angle factor (glancing blows do less damage)
    const angleFactor = this.calculateAngleFactor(event.impactAngle);

    // 3. Effective energy (after angle reduction)
    const effectiveEnergy = kineticEnergy * angleFactor;

    // 4. Armor resistance
    const armorResistance = this.calculateArmorResistance(
      event.target.armorThickness,
      event.target.armorMaterial,
      event.projectile
    );

    // 5. Penetration check
    const penetrated = effectiveEnergy > armorResistance;

    // 6. Damage
    let structuralDamage = 0;
    let deformation = 0;
    let breachSize = 0;

    if (penetrated) {
      // Catastrophic - hull breached
      const excessEnergy = effectiveEnergy - armorResistance;
      structuralDamage = this.energyToDamage(excessEnergy);
      breachSize = this.calculateBreachSize(excessEnergy, event.projectile);
      deformation = 1.0; // Fully deformed at breach point
    } else {
      // Non-penetrating - deformation only
      const energyRatio = effectiveEnergy / armorResistance;
      deformation = this.calculateDeformation(energyRatio, event.target.armorMaterial);
      structuralDamage = deformation * 30; // Deformation causes some structural damage
    }

    return {
      penetrated,
      structuralDamage,
      deformation,
      breachDiameter: penetrated ? breachSize : 0,
      energyDeposited: effectiveEnergy
    };
  }

  // Angle factor: cos²(θ) for energy transfer
  // Perpendicular (0°) = 1.0, Glancing (80°) = 0.03
  private calculateAngleFactor(angle: number): number {
    const cos = Math.cos(angle);
    return cos * cos; // Squared for realistic energy transfer
  }

  // Armor resistance based on thickness and material
  private calculateArmorResistance(
    thickness: number,      // mm
    material: ArmorMaterial,
    projectile: CollisionObject
  ): number {
    const props = ARMOR_PROPERTIES[material];

    // Base resistance: yield strength × thickness × area
    // Simplified: R = σ_y × t² × (hardness ratio)
    const baseResistance = props.yieldStrength * 1e6 * // Convert MPa to Pa
                          (thickness / 1000) * (thickness / 1000); // m²

    // Hardness factor (harder armor resists harder projectiles better)
    const hardnessRatio = props.hardness / Math.max(projectile.hardness, 50);
    const hardnessFactor = Math.pow(hardnessRatio, 0.5);

    return baseResistance * hardnessFactor;
  }

  // Convert excess energy to structural damage
  private energyToDamage(energy: number): number {
    // Damage scales logarithmically with energy
    // 1 kJ = 10 damage
    // 10 kJ = 20 damage
    // 100 kJ = 30 damage
    const baseDamage = 10 * Math.log10(energy / 1000 + 1);
    return Math.min(100, baseDamage);
  }

  // Calculate breach size from penetrating energy
  private calculateBreachSize(energy: number, projectile: CollisionObject): number {
    // Breach at least as large as projectile
    const minSize = projectile.radius * 2;

    // Scales with energy (more energy = bigger hole)
    const energyFactor = Math.pow(energy / 10000, 0.33); // Cube root scaling

    return minSize * (1 + energyFactor);
  }

  // Calculate plastic deformation from non-penetrating impact
  private calculateDeformation(
    energyRatio: number,     // Fraction of energy needed to penetrate
    material: ArmorMaterial
  ): number {
    const props = ARMOR_PROPERTIES[material];

    // Ductile materials deform more before breaking
    const ductilityFactor = props.ductility;

    // Deformation increases as energy approaches penetration threshold
    const deformation = energyRatio * ductilityFactor;

    return Math.min(1.0, deformation);
  }
}
```

---

## Structural Integrity System

### Cumulative Damage

```typescript
class HullIntegritySystem {
  compartments: HullCompartment[] = [];

  // Overall ship integrity
  getOverallIntegrity(): number {
    let totalHealth = 0;
    for (const comp of this.compartments) {
      totalHealth += comp.structuralHealth;
    }
    return totalHealth / this.compartments.length;
  }

  // Apply impact to specific compartment
  applyImpact(impact: ImpactEvent): void {
    const comp = this.findCompartmentAtPosition(impact.impactPosition);
    if (!comp) return;

    const result = new DamageCalculator().calculateImpact(impact);

    // 1. Reduce structural health
    comp.structuralHealth = Math.max(0, comp.structuralHealth - result.structuralDamage);

    // 2. Accumulate damage
    comp.accumulatedDamage += result.energyDeposited;

    // 3. Update deformation
    comp.deformationLevel = Math.max(comp.deformationLevel, result.deformation);

    // 4. Create breach if penetrated
    if (result.penetrated) {
      this.createBreach(comp, impact.impactPosition, result.breachDiameter);
    }

    // 5. Check for cascading failures
    this.checkCatastrophicFailure(comp);

    // 6. Damage internal systems
    if (result.penetrated || comp.structuralHealth < 30) {
      this.damageContainedSystems(comp, result.structuralDamage);
    }
  }

  private createBreach(
    comp: HullCompartment,
    position: Vector3,
    diameter: number
  ): void {
    const breach: Breach = {
      position,
      diameter,
      created: Date.now(),
      severity: diameter < 0.1 ? 'minor' :
                diameter < 0.5 ? 'major' : 'catastrophic'
    };

    comp.breaches.push(breach);

    // Trigger consequences
    this.triggerBreachEffects(comp, breach);
  }

  private checkCatastrophicFailure(comp: HullCompartment): void {
    // Catastrophic failure if:
    // 1. Accumulated damage > capacity
    // 2. Multiple large breaches
    // 3. Structural health near zero

    if (comp.accumulatedDamage > comp.maxDamageCapacity ||
        comp.structuralHealth < 5) {
      this.compartmentCatastrophicFailure(comp);
    }
  }

  private compartmentCatastrophicFailure(comp: HullCompartment): void {
    // Total loss of compartment
    comp.structuralHealth = 0;
    comp.deformationLevel = 1.0;

    // All systems in compartment destroyed
    for (const sysId of comp.containedSystems) {
      // Disable system completely
      this.destroySystem(sysId);
    }

    // Massive breach (entire section vented)
    this.createBreach(comp, comp.position, 2.0);

    // Game over if critical compartment (e.g., cockpit)
    if (comp.id === 'cockpit' || comp.id === 'reactor_bay') {
      this.triggerGameOver('catastrophic_hull_failure');
    }
  }

  private damageContainedSystems(comp: HullCompartment, damage: number): void {
    for (const sysId of comp.containedSystems) {
      // Random chance to hit each system
      const hitChance = damage / 100;

      if (Math.random() < hitChance) {
        const systemDamage = damage * (0.5 + Math.random() * 0.5);
        this.applySystemDamage(sysId, systemDamage);
      }
    }
  }
}
```

---

## Breach Effects

### Atmospheric Venting

```typescript
interface BreachEffects {
  // Atmosphere loss (if breach connects to space)
  ventingRate: number;      // kg/s

  // Thrust from venting (Newton's third law)
  ventThrust: Vector3;      // N

  // Pressure differential
  internalPressure: number; // Pa
  externalPressure: number; // Pa (usually 0 in space)

  // Temperature effects
  rapidCooling: boolean;    // Flash-freezing from decompression
}

class BreachPhysics {
  calculateVentingRate(
    breach: Breach,
    internalPressure: number,
    compartmentVolume: number
  ): number {
    // Choked flow through orifice
    // ṁ = C_d × A × sqrt(ρ × P)

    const dischargeCoeff = 0.6;  // Typical for sharp-edged orifice
    const area = Math.PI * (breach.diameter / 2) ** 2; // m²

    // Assume air density at internal pressure
    const gasDensity = internalPressure / (287 * 293); // Ideal gas law, kg/m³

    const massFlow = dischargeCoeff * area * Math.sqrt(gasDensity * internalPressure);

    return massFlow; // kg/s
  }

  calculateVentThrust(
    breach: Breach,
    massFlow: number,
    ventDirection: Vector3  // Outward normal from hull
  ): Vector3 {
    // F = ṁ × v_exit
    // For choked flow: v_exit ≈ 300 m/s (speed of sound in air)

    const exitVelocity = 300; // m/s
    const thrustMagnitude = massFlow * exitVelocity;

    return {
      x: ventDirection.x * thrustMagnitude,
      y: ventDirection.y * thrustMagnitude,
      z: ventDirection.z * thrustMagnitude
    };
  }

  update(dt: number, breaches: Breach[], compartment: HullCompartment): void {
    for (const breach of breaches) {
      const ventRate = this.calculateVentingRate(
        breach,
        compartment.atmospherePressure,
        compartment.volume
      );

      // Remove atmosphere
      const massVented = ventRate * dt;
      compartment.atmosphereMass -= massVented;
      compartment.atmospherePressure = this.calculatePressure(
        compartment.atmosphereMass,
        compartment.volume,
        compartment.temperature
      );

      // Apply thrust to ship
      const thrust = this.calculateVentThrust(
        breach,
        ventRate,
        breach.outwardNormal
      );

      this.applyForceToShip(thrust, breach.position);

      // Stop venting if pressure equalized
      if (compartment.atmospherePressure < 100) { // Near vacuum
        // Breach effects minimal now
      }
    }
  }
}
```

---

## Repair & Patching

### Emergency Repairs

```typescript
interface RepairAction {
  type: 'patch_breach' | 'reinforce_structure' | 'seal_compartment';
  target: HullCompartment;
  targetBreach?: Breach;
  duration: number;         // seconds
  spareParts: number;       // Cost in parts
  effectiveness: number;    // 0-1 (how much it helps)
}

class RepairSystem {
  availableSpareParts: number = 10; // Starting parts

  canRepair(action: RepairAction): boolean {
    return this.availableSpareParts >= action.spareParts;
  }

  executeRepair(action: RepairAction): void {
    if (!this.canRepair(action)) return;

    this.availableSpareParts -= action.spareParts;

    switch (action.type) {
      case 'patch_breach':
        this.patchBreach(action.target, action.targetBreach!);
        break;

      case 'reinforce_structure':
        this.reinforceStructure(action.target, action.effectiveness);
        break;

      case 'seal_compartment':
        this.sealCompartment(action.target);
        break;
    }
  }

  private patchBreach(comp: HullCompartment, breach: Breach): void {
    // Remove breach from list (patched)
    const index = comp.breaches.indexOf(breach);
    if (index > -1) {
      comp.breaches.splice(index, 1);
    }

    // Restore some structural integrity
    comp.structuralHealth = Math.min(100, comp.structuralHealth + 10);

    // Stop venting from this breach
    // (breach removal handles this automatically)
  }

  private reinforceStructure(comp: HullCompartment, effectiveness: number): void {
    // Partially restore health
    const restoration = 20 * effectiveness;
    comp.structuralHealth = Math.min(100, comp.structuralHealth + restoration);

    // Reduce deformation slightly
    comp.deformationLevel *= (1 - effectiveness * 0.3);
  }

  private sealCompartment(comp: HullCompartment): void {
    // Close all doors to this compartment
    // Prevents atmosphere loss spreading to other compartments
    // (Handled by door system)
  }
}
```

---

## Compartment Layout (MVP Ship)

### Default Scout Ship

```typescript
const createScoutShipHull = (): HullCompartment[] => {
  return [
    {
      id: 'bow',
      name: 'Bow Section',
      position: { x: 5, y: 0, z: 0 },
      bounds: { min: { x: 3, y: -2, z: -2 }, max: { x: 7, y: 2, z: 2 } },
      armorThickness: 20, // mm
      armorMaterial: ArmorMaterial.ALUMINUM,
      structuralHealth: 100,
      maxDamageCapacity: 50000, // 50 kJ
      accumulatedDamage: 0,
      deformationLevel: 0,
      breaches: [],
      containedSystems: ['radar', 'rcs_bow']
    },

    {
      id: 'cockpit',
      name: 'Command Module',
      position: { x: 2, y: 0, z: 1 },
      bounds: { min: { x: 0, y: -1.5, z: -0.5 }, max: { x: 4, y: 1.5, z: 2.5 } },
      armorThickness: 30,
      armorMaterial: ArmorMaterial.COMPOSITE,
      structuralHealth: 100,
      maxDamageCapacity: 80000,
      accumulatedDamage: 0,
      deformationLevel: 0,
      breaches: [],
      containedSystems: ['navigation', 'life_support', 'flight_controls']
    },

    {
      id: 'engineering',
      name: 'Engineering Bay',
      position: { x: 0, y: 0, z: -1 },
      bounds: { min: { x: -2, y: -2, z: -3 }, max: { x: 2, y: 2, z: 1 } },
      armorThickness: 40,
      armorMaterial: ArmorMaterial.TITANIUM,
      structuralHealth: 100,
      maxDamageCapacity: 120000,
      accumulatedDamage: 0,
      deformationLevel: 0,
      breaches: [],
      containedSystems: ['reactor', 'electrical', 'thermal', 'coolant']
    },

    {
      id: 'fuel_tanks',
      name: 'Fuel Storage',
      position: { x: -2, y: 0, z: 0 },
      bounds: { min: { x: -4, y: -1.5, z: -1.5 }, max: { x: 0, y: 1.5, z: 1.5 } },
      armorThickness: 15,
      armorMaterial: ArmorMaterial.ALUMINUM,
      structuralHealth: 100,
      maxDamageCapacity: 40000,
      accumulatedDamage: 0,
      deformationLevel: 0,
      breaches: [],
      containedSystems: ['fuel_system']
    },

    {
      id: 'engine_bay',
      name: 'Engine Section',
      position: { x: -5, y: 0, z: 0 },
      bounds: { min: { x: -7, y: -2, z: -2 }, max: { x: -3, y: 2, z: 2 } },
      armorThickness: 25,
      armorMaterial: ArmorMaterial.REINFORCED_STEEL,
      structuralHealth: 100,
      maxDamageCapacity: 100000,
      accumulatedDamage: 0,
      deformationLevel: 0,
      breaches: [],
      containedSystems: ['main_engine', 'rcs_stern', 'gimbal']
    },

    {
      id: 'port_side',
      name: 'Port Equipment Bay',
      position: { x: 0, y: -2, z: 0 },
      bounds: { min: { x: -1, y: -3, z: -1 }, max: { x: 1, y: -1, z: 1 } },
      armorThickness: 18,
      armorMaterial: ArmorMaterial.ALUMINUM,
      structuralHealth: 100,
      maxDamageCapacity: 45000,
      accumulatedDamage: 0,
      deformationLevel: 0,
      breaches: [],
      containedSystems: ['rcs_port']
    },

    {
      id: 'starboard_side',
      name: 'Starboard Equipment Bay',
      position: { x: 0, y: 2, z: 0 },
      bounds: { min: { x: -1, y: 1, z: -1 }, max: { x: 1, y: 3, z: 1 } },
      armorThickness: 18,
      armorMaterial: ArmorMaterial.ALUMINUM,
      structuralHealth: 100,
      maxDamageCapacity: 45000,
      accumulatedDamage: 0,
      deformationLevel: 0,
      breaches: [],
      containedSystems: ['rcs_starboard']
    }
  ];
};
```

---

## Integration with Game Systems

### Collision → Damage → Effects

```typescript
// In collision detection system:
const collision = detectCollision(ship, asteroid);

if (collision) {
  // 1. Calculate impact
  const impact: ImpactEvent = {
    projectile: {
      mass: asteroid.mass,
      velocity: asteroid.velocity,
      radius: asteroid.radius,
      hardness: 500, // Rock
      material: 'rock'
    },
    target: ship.hull.findCompartmentAtPosition(collision.point),
    impactPosition: collision.point,
    impactVelocity: subtract(asteroid.velocity, ship.velocity),
    impactAngle: calculateAngle(collision.normal, collision.velocity),
    kineticEnergy: 0, // Calculated in applyImpact
    momentum: { x: 0, y: 0, z: 0 }
  };

  // 2. Apply damage
  ship.hullIntegrity.applyImpact(impact);

  // 3. Apply momentum transfer (bounce ship)
  const impulse = calculateImpulse(impact);
  ship.physics.applyImpulse(impulse);

  // 4. Trigger effects
  if (impact.penetrated) {
    // Breach created - venting begins
    // System damage possible
    // Warning klaxons
  }
}
```

---

## Display to Player

### Damage Report (Instrument Display Only)

```
HULL INTEGRITY MONITOR
┌─────────────────────────────────┐
│ OVERALL: [██████░░░░] 65%       │
│                                 │
│ COMPARTMENT STATUS              │
│ BOW:        [█████░░░░] 52% ⚠   │
│   - 1 Minor Breach (0.08m)      │
│   - Deformation: 32%            │
│   - Radar: DAMAGED              │
│                                 │
│ COCKPIT:    [██████████] 100% ✓ │
│                                 │
│ ENGINEERING:[████████░░] 78%    │
│   - Deformation: 15%            │
│                                 │
│ FUEL TANKS: [███████░░░] 70% ⚠  │
│   - 1 Major Breach (0.4m) 🔴    │
│   - VENTING: 2.5 kg/s           │
│   - Fuel leak detected          │
│                                 │
│ ENGINE BAY: [██████████] 100% ✓ │
│                                 │
│ [SWITCH TO DAMAGE CONTROL]      │
└─────────────────────────────────┘
```

No visual damage model - just data readouts. Like submarine damage control board.

---

## Summary

**Hull Damage System:**
- Physics-based impact calculation (energy, angle, armor)
- Realistic penetration mechanics (armor thickness, hardness, material)
- Structural deformation (elastic → plastic → catastrophic)
- Cumulative damage tracking
- Breaches with atmospheric venting
- System damage from impacts
- Emergency repair capabilities

**No Visual Damage:**
- Hull exists as data structure
- Damage shown through instruments/readouts
- Player infers situation from sensors, not by looking at ship

**Integration:**
- Collision detection provides impact data
- Damage calculator determines breach/deformation
- Systems respond to damage (power loss, venting, etc.)
- Player sees warnings and status displays

**Next:** Sensor-based display system design.
