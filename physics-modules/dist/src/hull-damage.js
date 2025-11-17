"use strict";
/**
 * Hull Damage System
 *
 * Handles armor penetration, hull breaches, structural damage, and atmospheric pressure
 * NO RENDERING - physics only
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.HullDamageSystem = exports.HullStructure = exports.PenetrationCalculator = exports.DamageType = exports.MaterialType = void 0;
const math_utils_1 = require("./math-utils");
var MaterialType;
(function (MaterialType) {
    MaterialType["STEEL"] = "steel";
    MaterialType["TITANIUM"] = "titanium";
    MaterialType["ALUMINUM"] = "aluminum";
    MaterialType["COMPOSITE"] = "composite";
    MaterialType["CERAMIC"] = "ceramic";
})(MaterialType || (exports.MaterialType = MaterialType = {}));
var DamageType;
(function (DamageType) {
    DamageType["KINETIC"] = "kinetic";
    DamageType["THERMAL"] = "thermal";
    DamageType["EXPLOSIVE"] = "explosive";
    DamageType["COLLISION"] = "collision";
})(DamageType || (exports.DamageType = DamageType = {}));
/**
 * Armor penetration calculations
 */
class PenetrationCalculator {
    /**
     * Calculate kinetic energy penetration using simplified DeMarre formula
     * Actual formula is complex - this is a game-appropriate approximation
     */
    static calculateKineticPenetration(params) {
        const { projectileMass, velocity, diameter, impactAngle, armorThickness, armorHardness, armorDensity } = params;
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
        let spalling;
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
    static calculateThermalDamage(thermalEnergy, armorThickness, armorDensity, material) {
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
exports.PenetrationCalculator = PenetrationCalculator;
/**
 * Hull structure management
 */
class HullStructure {
    constructor(config) {
        this.compartments = new Map();
        this.armorLayers = new Map();
        for (const compartment of config.compartments) {
            this.compartments.set(compartment.id, compartment);
        }
        for (const armor of config.armorLayers) {
            this.armorLayers.set(armor.id, armor);
        }
    }
    getCompartment(id) {
        return this.compartments.get(id);
    }
    getArmorLayer(id) {
        return this.armorLayers.get(id);
    }
    getCompartmentAtPosition(position) {
        // Simplified: return first compartment
        // In full implementation, would use spatial partitioning
        return Array.from(this.compartments.values())[0];
    }
    getOverallIntegrity() {
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
    getAllCompartments() {
        return Array.from(this.compartments.values());
    }
    getAllArmorLayers() {
        return Array.from(this.armorLayers.values());
    }
}
exports.HullStructure = HullStructure;
/**
 * Main damage system
 */
class HullDamageSystem {
    constructor(hull) {
        this.breachIdCounter = 0;
        this.hull = hull;
    }
    processImpact(params) {
        const { position, velocity, mass, damageType, impactAngle, thermalEnergy, explosiveYield } = params;
        let damageApplied = 0;
        let breachCreated = false;
        let armorPenetrated = false;
        const affectedCompartments = [];
        // Get affected compartment
        const compartment = this.hull.getCompartmentAtPosition(position);
        if (!compartment) {
            return { damageApplied: 0, breachCreated: false, affectedCompartments: [], armorPenetrated: false };
        }
        affectedCompartments.push(compartment.id);
        switch (damageType) {
            case DamageType.KINETIC: {
                const speed = math_utils_1.VectorMath.magnitude(velocity);
                const kineticEnergy = 0.5 * mass * speed * speed;
                damageApplied = kineticEnergy;
                // Check armor penetration
                const armor = this.hull.getAllArmorLayers()[0]; // Simplified: use first armor
                if (armor) {
                    const penetration = PenetrationCalculator.calculateKineticPenetration({
                        projectileMass: mass,
                        velocity: speed,
                        diameter: Math.pow(mass / 7850, 1 / 3) * 2, // Approximate diameter from mass
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
                        compartment.structuralIntegrity = Math.max(0, compartment.structuralIntegrity - spallingDamage / 10000000);
                    }
                }
                break;
            }
            case DamageType.THERMAL: {
                if (thermalEnergy) {
                    damageApplied = thermalEnergy;
                    const armor = this.hull.getAllArmorLayers()[0];
                    if (armor) {
                        const ablation = PenetrationCalculator.calculateThermalDamage(thermalEnergy, armor.thickness - armor.ablationDepth, armor.density, armor.material);
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
                    compartment.structuralIntegrity = Math.max(0, compartment.structuralIntegrity - explosiveYield / 20000000);
                }
                break;
            }
            case DamageType.COLLISION: {
                const speed = math_utils_1.VectorMath.magnitude(velocity);
                const impactEnergy = 0.5 * mass * speed * speed;
                damageApplied = impactEnergy;
                // Collision damage is spread over larger area
                compartment.structuralIntegrity = Math.max(0, compartment.structuralIntegrity - impactEnergy / 50000000);
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
    createBreach(compartment, position, mass, damageType) {
        // Calculate breach size based on projectile mass
        const breachArea = Math.max(0.001, (mass / 1000) * 0.01); // Rough approximation
        const breach = {
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
    updatePressure(dt) {
        for (const compartment of this.hull.getAllCompartments()) {
            if (compartment.breaches.length === 0)
                continue;
            // Calculate total breach area
            const totalBreachArea = compartment.breaches
                .filter(b => !b.sealed)
                .reduce((sum, b) => sum + b.area, 0);
            if (totalBreachArea === 0)
                continue;
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
    getHull() {
        return this.hull;
    }
}
exports.HullDamageSystem = HullDamageSystem;
//# sourceMappingURL=hull-damage.js.map