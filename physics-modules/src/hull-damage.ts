/**
 * Hull Damage System
 *
 * Handles armor penetration, hull breaches, structural damage, and atmospheric pressure
 * NO RENDERING - physics only
 */

import { Vector3, VectorMath } from './math-utils';

export enum MaterialType {
  STEEL = 'steel',
  TITANIUM = 'titanium',
  ALUMINUM = 'aluminum',
  COMPOSITE = 'composite',
  CERAMIC = 'ceramic'
}

export enum DamageType {
  KINETIC = 'kinetic',
  THERMAL = 'thermal',
  EXPLOSIVE = 'explosive',
  COLLISION = 'collision'
}

export interface ArmorLayer {
  id: string;
  material: MaterialType;
  thickness: number;           // meters
  hardness: number;            // Brinell hardness
  density: number;             // kg/m³
  integrity: number;           // 0-1 (1 = undamaged)
  ablationDepth: number;       // meters of material ablated/worn away
}

export interface Breach {
  id: string;
  position: Vector3;
  area: number;                // m² (hole size)
  sealed: boolean;
  damageType: DamageType;
}

export interface Compartment {
  id: string;
  name: string;
  volume: number;              // m³
  pressure: number;            // Pa (pascals)
  atmosphereIntegrity: number; // 0-1 (1 = sealed, 0 = vacuum)
  structuralIntegrity: number; // 0-1 (1 = intact, 0 = destroyed)
  breaches: Breach[];
  systems: string[];           // IDs of systems in this compartment
  connectedCompartments: string[];
}

export interface PenetrationParams {
  projectileMass: number;      // kg
  velocity: number;            // m/s
  diameter: number;            // m
  impactAngle: number;         // degrees (0 = perpendicular, 90 = parallel)
  armorThickness: number;      // m
  armorHardness: number;       // Brinell
  armorDensity: number;        // kg/m³
}

export interface PenetrationResult {
  penetrated: boolean;
  penetrationDepth: number;    // m
  residualEnergy: number;      // J (energy after penetration)
  spalling?: {
    fragmentCount: number;
    fragmentEnergy: number;    // J total
  };
}

export interface ImpactParams {
  position: Vector3;
  velocity: Vector3;
  mass: number;                // kg
  damageType: DamageType;
  impactAngle: number;         // degrees
  thermalEnergy?: number;      // J (for laser/thermal weapons)
  explosiveYield?: number;     // J (for explosives)
}

export interface ImpactResult {
  damageApplied: number;       // Total damage in joules
  breachCreated: boolean;
  affectedCompartments: string[];
  armorPenetrated: boolean;
}

/**
 * Armor penetration calculations
 */
export class PenetrationCalculator {
  /**
   * Calculate kinetic energy penetration using simplified DeMarre formula
   * Actual formula is complex - this is a game-appropriate approximation
   */
  static calculateKineticPenetration(params: PenetrationParams): PenetrationResult {
    const {
      projectileMass,
      velocity,
      diameter,
      impactAngle,
      armorThickness,
      armorHardness,
      armorDensity
    } = params;

    // Handle edge cases
    if (projectileMass <= 0 || velocity <= 0) {
      return {
        penetrated: false,
        penetrationDepth: 0,
        residualEnergy: 0
      };
    }

    // Calculate kinetic energy
    const kineticEnergy = 0.5 * projectileMass * velocity * velocity;

    // Angle modifier (oblique impacts are less effective)
    const angleRad = (impactAngle * Math.PI) / 180;
    const angleFactor = Math.cos(angleRad);

    // Extreme angles bounce off
    if (angleFactor < 0.1) {
      return {
        penetrated: false,
        penetrationDepth: 0.001,
        residualEnergy: kineticEnergy * 0.9
      };
    }

    // Simplified DeMarre formula approximation
    // Real formula: penetration = K * (mass^0.5 * velocity^1.43) / (diameter^1.5 * hardness)
    // This is a game-appropriate simplification

    const hardnessFactor = armorHardness / 500; // Normalized to mild steel
    const crossSectionalArea = Math.PI * (diameter / 2) * (diameter / 2);

    // Penetration power (modified kinetic energy with velocity emphasis)
    const penetrationPower = Math.sqrt(projectileMass) * Math.pow(velocity, 1.4) / Math.pow(diameter, 0.5);

    // Armor resistance (calibrated for game balance)
    const armorResistance = armorDensity * hardnessFactor * armorThickness * 1000;

    // Angle factor is squared for more dramatic effect
    const effectiveAngleFactor = angleFactor * angleFactor;

    // Penetration depth (in meters)
    const rawPenetration = (penetrationPower / armorResistance) * effectiveAngleFactor;
    const penetrationDepth = Math.min(rawPenetration, armorThickness * 2);

    // Check if fully penetrated
    const penetrated = penetrationDepth > armorThickness;

    // Calculate residual energy
    // Energy absorbed is proportional to armor thickness, not penetration depth
    const energyToFullyPenetrate = (armorThickness / (penetrationDepth + 0.001)) * kineticEnergy;
    const energyAbsorbed = Math.min(kineticEnergy, energyToFullyPenetrate);
    const residualEnergy = Math.max(0, kineticEnergy - energyAbsorbed);

    // Spalling (fragmentation on impact)
    let spalling: PenetrationResult['spalling'];
    if (kineticEnergy > armorResistance * 0.5) {
      const spallingEnergy = kineticEnergy * 0.1; // 10% of energy creates spalling
      spalling = {
        fragmentCount: Math.floor(10 + kineticEnergy / 100000),
        fragmentEnergy: spallingEnergy
      };
    }

    return {
      penetrated,
      penetrationDepth,
      residualEnergy,
      spalling
    };
  }

  /**
   * Calculate thermal damage (laser ablation)
   */
  static calculateThermalDamage(
    thermalEnergy: number,
    armorThickness: number,
    armorDensity: number,
    material: MaterialType
  ): number {
    // Specific heat and melting point vary by material
    const materialProperties = {
      [MaterialType.STEEL]: { meltingPoint: 1800, specificHeat: 500 },
      [MaterialType.TITANIUM]: { meltingPoint: 1940, specificHeat: 520 },
      [MaterialType.ALUMINUM]: { meltingPoint: 933, specificHeat: 900 },
      [MaterialType.COMPOSITE]: { meltingPoint: 1200, specificHeat: 1000 },
      [MaterialType.CERAMIC]: { meltingPoint: 2300, specificHeat: 800 }
    };

    const props = materialProperties[material];

    // Energy required to melt armor
    const volume = armorThickness * 0.01; // Assume 1cm² beam area
    const mass = volume * armorDensity;
    const energyToMelt = mass * props.specificHeat * props.meltingPoint;

    // Ablation depth
    const ablationDepth = (thermalEnergy / energyToMelt) * armorThickness;

    return Math.min(ablationDepth, armorThickness);
  }
}

/**
 * Hull structure management
 */
export class HullStructure {
  private compartments: Map<string, Compartment> = new Map();
  private armorLayers: Map<string, ArmorLayer> = new Map();

  constructor(config: {
    compartments: Compartment[];
    armorLayers: ArmorLayer[];
  }) {
    for (const compartment of config.compartments) {
      this.compartments.set(compartment.id, compartment);
    }

    for (const armor of config.armorLayers) {
      this.armorLayers.set(armor.id, armor);
    }
  }

  getCompartment(id: string): Compartment | undefined {
    return this.compartments.get(id);
  }

  getArmorLayer(id: string): ArmorLayer | undefined {
    return this.armorLayers.get(id);
  }

  getCompartmentAtPosition(position: Vector3): Compartment | undefined {
    // Simplified: return first compartment
    // In full implementation, would use spatial partitioning
    return Array.from(this.compartments.values())[0];
  }

  getOverallIntegrity(): { structural: number; armor: number } {
    let totalStructural = 0;
    let totalArmor = 0;
    let compartmentCount = 0;
    let armorCount = 0;

    for (const compartment of this.compartments.values()) {
      totalStructural += compartment.structuralIntegrity;
      compartmentCount++;
    }

    for (const armor of this.armorLayers.values()) {
      totalArmor += armor.integrity;
      armorCount++;
    }

    return {
      structural: compartmentCount > 0 ? totalStructural / compartmentCount : 1.0,
      armor: armorCount > 0 ? totalArmor / armorCount : 1.0
    };
  }

  getAllCompartments(): Compartment[] {
    return Array.from(this.compartments.values());
  }

  getAllArmorLayers(): ArmorLayer[] {
    return Array.from(this.armorLayers.values());
  }
}

/**
 * Main damage system
 */
export class HullDamageSystem {
  private hull: HullStructure;
  private breachIdCounter = 0;

  constructor(hull: HullStructure) {
    this.hull = hull;
  }

  processImpact(params: ImpactParams): ImpactResult {
    const {
      position,
      velocity,
      mass,
      damageType,
      impactAngle,
      thermalEnergy,
      explosiveYield
    } = params;

    let damageApplied = 0;
    let breachCreated = false;
    let armorPenetrated = false;
    const affectedCompartments: string[] = [];

    // Get affected compartment
    const compartment = this.hull.getCompartmentAtPosition(position);
    if (!compartment) {
      return { damageApplied: 0, breachCreated: false, affectedCompartments: [], armorPenetrated: false };
    }

    affectedCompartments.push(compartment.id);

    switch (damageType) {
      case DamageType.KINETIC: {
        const speed = VectorMath.magnitude(velocity);
        const kineticEnergy = 0.5 * mass * speed * speed;
        damageApplied = kineticEnergy;

        // Check armor penetration
        const armor = this.hull.getAllArmorLayers()[0]; // Simplified: use first armor
        if (armor) {
          const penetration = PenetrationCalculator.calculateKineticPenetration({
            projectileMass: mass,
            velocity: speed,
            diameter: Math.pow(mass / 7850, 1/3) * 2, // Approximate diameter from mass
            impactAngle,
            armorThickness: armor.thickness - armor.ablationDepth,
            armorHardness: armor.hardness,
            armorDensity: armor.density
          });

          armorPenetrated = penetration.penetrated;

          // Damage armor
          const damageRatio = Math.min(1.0, kineticEnergy / 1000000); // 1 MJ normalizer
          armor.integrity = Math.max(0, armor.integrity - damageRatio * 0.1);

          // Create breach if penetrated
          if (penetration.penetrated) {
            breachCreated = this.createBreach(compartment, position, mass, damageType);
          }

          // Spalling damage to interior even if not fully penetrated
          if (penetration.spalling) {
            const spallingDamage = penetration.spalling.fragmentEnergy;
            compartment.structuralIntegrity = Math.max(
              0,
              compartment.structuralIntegrity - spallingDamage / 10000000
            );
          }
        }
        break;
      }

      case DamageType.THERMAL: {
        if (thermalEnergy) {
          damageApplied = thermalEnergy;

          const armor = this.hull.getAllArmorLayers()[0];
          if (armor) {
            const ablation = PenetrationCalculator.calculateThermalDamage(
              thermalEnergy,
              armor.thickness - armor.ablationDepth,
              armor.density,
              armor.material
            );

            armor.ablationDepth += ablation;
            armor.integrity = Math.max(0, 1.0 - armor.ablationDepth / armor.thickness);

            // Create breach if burned through
            if (armor.ablationDepth >= armor.thickness) {
              armorPenetrated = true;
              breachCreated = this.createBreach(compartment, position, mass * 0.5, damageType);
            }
          }
        }
        break;
      }

      case DamageType.EXPLOSIVE: {
        if (explosiveYield) {
          damageApplied = explosiveYield;

          // Explosive damage affects multiple compartments
          const armor = this.hull.getAllArmorLayers()[0];
          if (armor) {
            const damageRatio = Math.min(1.0, explosiveYield / 10000000); // 10 MJ normalizer
            armor.integrity = Math.max(0, armor.integrity - damageRatio * 0.2);

            if (armor.integrity < 0.5) {
              armorPenetrated = true;
              breachCreated = this.createBreach(compartment, position, mass, damageType);
            }
          }

          // Structural damage
          compartment.structuralIntegrity = Math.max(
            0,
            compartment.structuralIntegrity - explosiveYield / 20000000
          );
        }
        break;
      }

      case DamageType.COLLISION: {
        const speed = VectorMath.magnitude(velocity);
        const impactEnergy = 0.5 * mass * speed * speed;
        damageApplied = impactEnergy;

        // Collision damage is spread over larger area
        compartment.structuralIntegrity = Math.max(
          0,
          compartment.structuralIntegrity - impactEnergy / 50000000
        );

        const armor = this.hull.getAllArmorLayers()[0];
        if (armor) {
          armor.integrity = Math.max(0, armor.integrity - impactEnergy / 100000000);
        }
        break;
      }
    }

    return {
      damageApplied,
      breachCreated,
      affectedCompartments,
      armorPenetrated
    };
  }

  private createBreach(
    compartment: Compartment,
    position: Vector3,
    mass: number,
    damageType: DamageType
  ): boolean {
    // Calculate breach size based on projectile mass
    const breachArea = Math.max(0.001, (mass / 1000) * 0.01); // Rough approximation

    const breach: Breach = {
      id: `breach-${this.breachIdCounter++}`,
      position,
      area: breachArea,
      sealed: false,
      damageType
    };

    compartment.breaches.push(breach);
    return true;
  }

  /**
   * Update atmospheric pressure in compartments over time
   */
  updatePressure(dt: number): void {
    for (const compartment of this.hull.getAllCompartments()) {
      if (compartment.breaches.length === 0) continue;

      // Calculate total breach area
      const totalBreachArea = compartment.breaches
        .filter(b => !b.sealed)
        .reduce((sum, b) => sum + b.area, 0);

      if (totalBreachArea === 0) continue;

      // Simplified pressure loss model
      // dP/dt = -k * A * P / V (where k is flow coefficient)
      const flowCoefficient = 0.6; // Typical orifice coefficient
      const pressureLossRate = flowCoefficient * totalBreachArea * compartment.pressure / compartment.volume;

      // Update pressure
      const pressureLoss = pressureLossRate * dt;
      compartment.pressure = Math.max(0, compartment.pressure - pressureLoss);

      // Update atmosphere integrity
      compartment.atmosphereIntegrity = compartment.pressure / 101325; // Normalize to 1 atm
    }
  }

  getHull(): HullStructure {
    return this.hull;
  }
}
