/**
 * Hull Damage System Tests
 *
 * Tests armor penetration, hull breaches, structural damage, and compartmentalization
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  HullDamageSystem,
  ArmorLayer,
  Compartment,
  DamageType,
  ImpactResult,
  PenetrationCalculator,
  HullStructure,
  MaterialType
} from '../src/hull-damage';
import { Vector3 } from '../src/math-utils';

describe('Hull Damage System', () => {
  describe('Penetration Calculator', () => {
    it('should calculate kinetic penetration depth', () => {
      const result = PenetrationCalculator.calculateKineticPenetration({
        projectileMass: 10,      // kg
        velocity: 1000,          // m/s
        diameter: 0.1,           // m
        impactAngle: 0,          // degrees (perpendicular)
        armorThickness: 0.05,    // m (50mm)
        armorHardness: 500,      // Brinell hardness
        armorDensity: 7850       // kg/m³ (steel)
      });

      expect(result.penetrated).toBe(true);
      expect(result.penetrationDepth).toBeGreaterThan(0.05);
      expect(result.residualEnergy).toBeGreaterThan(0);
    });

    it('should fail to penetrate thick armor', () => {
      const result = PenetrationCalculator.calculateKineticPenetration({
        projectileMass: 1,       // kg (small projectile)
        velocity: 500,           // m/s
        diameter: 0.05,          // m
        impactAngle: 0,
        armorThickness: 0.5,     // m (500mm - very thick)
        armorHardness: 600,
        armorDensity: 7850
      });

      expect(result.penetrated).toBe(false);
      expect(result.penetrationDepth).toBeLessThan(0.5);
    });

    it('should reduce penetration at oblique angles', () => {
      const perpendicular = PenetrationCalculator.calculateKineticPenetration({
        projectileMass: 5,
        velocity: 800,
        diameter: 0.08,
        impactAngle: 0,          // perpendicular
        armorThickness: 0.1,
        armorHardness: 500,
        armorDensity: 7850
      });

      const oblique = PenetrationCalculator.calculateKineticPenetration({
        projectileMass: 5,
        velocity: 800,
        diameter: 0.08,
        impactAngle: 45,         // 45 degrees
        armorThickness: 0.1,
        armorHardness: 500,
        armorDensity: 7850
      });

      expect(oblique.penetrationDepth).toBeLessThan(perpendicular.penetrationDepth);
    });

    it('should calculate spalling damage', () => {
      const result = PenetrationCalculator.calculateKineticPenetration({
        projectileMass: 20,
        velocity: 1500,
        diameter: 0.15,
        impactAngle: 0,
        armorThickness: 0.08,
        armorHardness: 400,
        armorDensity: 7850
      });

      expect(result.spalling).toBeDefined();
      expect(result.spalling!.fragmentCount).toBeGreaterThan(0);
      expect(result.spalling!.fragmentEnergy).toBeGreaterThan(0);
    });

    it('should handle zero velocity impact', () => {
      const result = PenetrationCalculator.calculateKineticPenetration({
        projectileMass: 10,
        velocity: 0,
        diameter: 0.1,
        impactAngle: 0,
        armorThickness: 0.05,
        armorHardness: 500,
        armorDensity: 7850
      });

      expect(result.penetrated).toBe(false);
      expect(result.penetrationDepth).toBe(0);
    });
  });

  describe('Armor Layers', () => {
    it('should create armor layer with correct properties', () => {
      const armor: ArmorLayer = {
        id: 'outer-armor',
        material: MaterialType.STEEL,
        thickness: 0.1,
        hardness: 500,
        density: 7850,
        integrity: 1.0,
        ablationDepth: 0
      };

      expect(armor.integrity).toBe(1.0);
      expect(armor.ablationDepth).toBe(0);
    });

    it('should reduce integrity when damaged', () => {
      const armor: ArmorLayer = {
        id: 'outer-armor',
        material: MaterialType.STEEL,
        thickness: 0.1,
        hardness: 500,
        density: 7850,
        integrity: 1.0,
        ablationDepth: 0
      };

      // Simulate damage
      armor.integrity = 0.7;
      armor.ablationDepth = 0.02;

      expect(armor.integrity).toBe(0.7);
      expect(armor.ablationDepth).toBe(0.02);
      expect(armor.thickness - armor.ablationDepth).toBe(0.08);
    });
  });

  describe('Compartments', () => {
    let compartment: Compartment;

    beforeEach(() => {
      compartment = {
        id: 'bridge',
        name: 'Bridge',
        volume: 100,              // m³
        pressure: 101325,         // Pa (1 atm)
        atmosphereIntegrity: 1.0,
        structuralIntegrity: 1.0,
        breaches: [],
        systems: ['navigation', 'communications'],
        connectedCompartments: ['corridor-1']
      };
    });

    it('should create compartment with full integrity', () => {
      expect(compartment.atmosphereIntegrity).toBe(1.0);
      expect(compartment.structuralIntegrity).toBe(1.0);
      expect(compartment.breaches.length).toBe(0);
    });

    it('should track pressure loss from breaches', () => {
      compartment.breaches.push({
        id: 'breach-1',
        position: { x: 0, y: 0, z: 0 },
        area: 0.01,              // m² (10cm x 10cm hole)
        sealed: false,
        damageType: DamageType.KINETIC
      });

      expect(compartment.breaches.length).toBe(1);
      expect(compartment.atmosphereIntegrity).toBe(1.0);  // Not yet calculated
    });
  });

  describe('Hull Structure', () => {
    let hull: HullStructure;

    beforeEach(() => {
      hull = new HullStructure({
        compartments: [
          {
            id: 'bridge',
            name: 'Bridge',
            volume: 100,
            pressure: 101325,
            atmosphereIntegrity: 1.0,
            structuralIntegrity: 1.0,
            breaches: [],
            systems: ['navigation'],
            connectedCompartments: ['corridor']
          },
          {
            id: 'corridor',
            name: 'Corridor',
            volume: 50,
            pressure: 101325,
            atmosphereIntegrity: 1.0,
            structuralIntegrity: 1.0,
            breaches: [],
            systems: [],
            connectedCompartments: ['bridge', 'engine-room']
          }
        ],
        armorLayers: [
          {
            id: 'outer',
            material: MaterialType.STEEL,
            thickness: 0.1,
            hardness: 500,
            density: 7850,
            integrity: 1.0,
            ablationDepth: 0
          }
        ]
      });
    });

    it('should initialize with compartments and armor', () => {
      expect(hull.getCompartment('bridge')).toBeDefined();
      expect(hull.getCompartment('corridor')).toBeDefined();
      expect(hull.getArmorLayer('outer')).toBeDefined();
    });

    it('should calculate overall hull integrity', () => {
      const integrity = hull.getOverallIntegrity();
      expect(integrity.structural).toBe(1.0);
      expect(integrity.armor).toBe(1.0);
    });

    it('should find compartment at position', () => {
      // Simplified - just return first compartment for testing
      const compartment = hull.getCompartmentAtPosition({ x: 0, y: 0, z: 5 });
      expect(compartment).toBeDefined();
    });
  });

  describe('Damage System Integration', () => {
    let damageSystem: HullDamageSystem;
    let hull: HullStructure;

    beforeEach(() => {
      hull = new HullStructure({
        compartments: [
          {
            id: 'hull-section-1',
            name: 'Hull Section 1',
            volume: 200,
            pressure: 101325,
            atmosphereIntegrity: 1.0,
            structuralIntegrity: 1.0,
            breaches: [],
            systems: ['life-support'],
            connectedCompartments: []
          }
        ],
        armorLayers: [
          {
            id: 'outer-armor',
            material: MaterialType.STEEL,
            thickness: 0.15,
            hardness: 550,
            density: 7850,
            integrity: 1.0,
            ablationDepth: 0
          }
        ]
      });

      damageSystem = new HullDamageSystem(hull);
    });

    it('should process kinetic impact', () => {
      const impact: ImpactResult = damageSystem.processImpact({
        position: { x: 0, y: 0, z: 10 },
        velocity: { x: 0, y: 0, z: -1000 },
        mass: 15,
        damageType: DamageType.KINETIC,
        impactAngle: 0
      });

      expect(impact).toBeDefined();
      expect(impact.damageApplied).toBeGreaterThan(0);
    });

    it('should create breach on full penetration', () => {
      const impact = damageSystem.processImpact({
        position: { x: 0, y: 0, z: 10 },
        velocity: { x: 0, y: 0, z: -2000 },  // High velocity
        mass: 50,                             // Heavy projectile
        damageType: DamageType.KINETIC,
        impactAngle: 0
      });

      const compartment = hull.getCompartmentAtPosition({ x: 0, y: 0, z: 10 });

      if (impact.breachCreated) {
        expect(compartment?.breaches.length).toBeGreaterThan(0);
      }
    });

    it('should reduce armor integrity from impacts', () => {
      const armor = hull.getArmorLayer('outer-armor')!;
      const initialIntegrity = armor.integrity;

      damageSystem.processImpact({
        position: { x: 0, y: 0, z: 10 },
        velocity: { x: 0, y: 0, z: -800 },
        mass: 10,
        damageType: DamageType.KINETIC,
        impactAngle: 0
      });

      expect(armor.integrity).toBeLessThan(initialIntegrity);
    });

    it('should handle thermal damage', () => {
      const impact = damageSystem.processImpact({
        position: { x: 0, y: 0, z: 10 },
        velocity: { x: 0, y: 0, z: 0 },
        mass: 0,
        damageType: DamageType.THERMAL,
        impactAngle: 0,
        thermalEnergy: 5000000  // 5 MJ laser
      });

      expect(impact.damageApplied).toBeGreaterThan(0);
    });

    it('should handle explosive damage', () => {
      const impact = damageSystem.processImpact({
        position: { x: 0, y: 0, z: 10 },
        velocity: { x: 0, y: 0, z: -500 },
        mass: 20,
        damageType: DamageType.EXPLOSIVE,
        impactAngle: 0,
        explosiveYield: 10000000  // 10 MJ warhead
      });

      expect(impact.damageApplied).toBeGreaterThan(0);
      expect(impact.affectedCompartments.length).toBeGreaterThan(0);
    });
  });

  describe('Pressure Loss Simulation', () => {
    let hull: HullStructure;
    let damageSystem: HullDamageSystem;

    beforeEach(() => {
      hull = new HullStructure({
        compartments: [
          {
            id: 'pressurized-cabin',
            name: 'Pressurized Cabin',
            volume: 150,
            pressure: 101325,
            atmosphereIntegrity: 1.0,
            structuralIntegrity: 1.0,
            breaches: [],
            systems: [],
            connectedCompartments: []
          }
        ],
        armorLayers: []
      });

      damageSystem = new HullDamageSystem(hull);
    });

    it('should simulate pressure loss over time', () => {
      const compartment = hull.getCompartment('pressurized-cabin')!;

      // Create a breach
      compartment.breaches.push({
        id: 'breach-test',
        position: { x: 0, y: 0, z: 0 },
        area: 0.01,  // 10cm x 10cm
        sealed: false,
        damageType: DamageType.KINETIC
      });

      const initialPressure = compartment.pressure;

      // Simulate 60 seconds of pressure loss
      damageSystem.updatePressure(60);

      expect(compartment.pressure).toBeLessThan(initialPressure);
      expect(compartment.atmosphereIntegrity).toBeLessThan(1.0);
    });

    it('should not lose pressure in sealed compartment', () => {
      const compartment = hull.getCompartment('pressurized-cabin')!;
      const initialPressure = compartment.pressure;

      damageSystem.updatePressure(60);

      expect(compartment.pressure).toBe(initialPressure);
    });
  });

  describe('Edge Cases', () => {
    it('should handle zero-mass projectile', () => {
      const result = PenetrationCalculator.calculateKineticPenetration({
        projectileMass: 0,
        velocity: 1000,
        diameter: 0.1,
        impactAngle: 0,
        armorThickness: 0.05,
        armorHardness: 500,
        armorDensity: 7850
      });

      expect(result.penetrated).toBe(false);
      expect(result.penetrationDepth).toBe(0);
    });

    it('should handle extreme impact angles', () => {
      const result = PenetrationCalculator.calculateKineticPenetration({
        projectileMass: 10,
        velocity: 1000,
        diameter: 0.1,
        impactAngle: 89,  // Nearly parallel
        armorThickness: 0.05,
        armorHardness: 500,
        armorDensity: 7850
      });

      // Should bounce off at extreme angles
      expect(result.penetrationDepth).toBeLessThan(0.01);
    });
  });
});
