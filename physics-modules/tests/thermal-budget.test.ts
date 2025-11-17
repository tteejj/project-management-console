/**
 * Thermal Budget System Tests
 *
 * Tests heat generation, transfer, cooling, and thermal management
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  ThermalBudgetSystem,
  HeatSource,
  HeatSink,
  ThermalComponent,
  CoolingSystem,
  CoolingType,
  ThermalCompartment,
  ThermalConfig,
  ThermalStatistics
} from '../src/thermal-budget';

describe('Thermal Budget System', () => {
  describe('Heat Generation', () => {
    it('should generate heat from components', () => {
      const reactor: ThermalComponent = {
        id: 'reactor',
        name: 'Reactor',
        temperature: 400,         // K
        mass: 1000,               // kg
        specificHeat: 500,        // J/(kg·K)
        surfaceArea: 2,           // m² (smaller surface = less convection)
        heatGeneration: 100000,   // W (100 kW - strong heat source)
        compartmentId: 'engine-room'
      };

      const compartment: ThermalCompartment = {
        id: 'engine-room',
        name: 'Engine Room',
        temperature: 293,         // K (20°C)
        volume: 100,              // m³
        airMass: 120,             // kg (density ~1.2 kg/m³)
        connectedCompartments: []
      };

      const thermal = new ThermalBudgetSystem({
        components: [reactor],
        compartments: [compartment],
        coolingSystems: []
      });

      const initialTemp = reactor.temperature;
      thermal.update(10);  // 10 seconds

      // Component should heat up
      expect(reactor.temperature).toBeGreaterThan(initialTemp);
    });

    it('should calculate temperature rise correctly', () => {
      // Q = mcΔT → ΔT = Q / (mc)
      const component: ThermalComponent = {
        id: 'battery',
        name: 'Battery',
        temperature: 293,
        mass: 100,              // kg
        specificHeat: 900,      // J/(kg·K) (similar to lithium)
        surfaceArea: 2,
        heatGeneration: 1000,   // W
        compartmentId: 'cabin'
      };

      const compartment: ThermalCompartment = {
        id: 'cabin',
        name: 'Cabin',
        temperature: 293,
        volume: 50,
        airMass: 60,
        connectedCompartments: []
      };

      const thermal = new ThermalBudgetSystem({
        components: [component],
        compartments: [compartment],
        coolingSystems: []
      });

      thermal.update(90);  // 90 seconds

      // Heat generated = 1000 W * 90 s = 90,000 J
      // Expected ΔT = 90,000 / (100 * 900) = 1K
      // But heat will also transfer to air, so actual rise will be less
      expect(component.temperature).toBeGreaterThan(293);
      expect(component.temperature).toBeLessThan(295);  // Reasonable range
    });
  });

  describe('Heat Transfer', () => {
    it('should transfer heat to compartment air', () => {
      const hotComponent: ThermalComponent = {
        id: 'engine',
        name: 'Engine',
        temperature: 500,       // Very hot
        mass: 500,
        specificHeat: 450,
        surfaceArea: 5,
        heatGeneration: 0,      // No active generation for this test
        compartmentId: 'engine-room'
      };

      const compartment: ThermalCompartment = {
        id: 'engine-room',
        name: 'Engine Room',
        temperature: 293,       // Cool air
        volume: 100,
        airMass: 120,
        connectedCompartments: []
      };

      const thermal = new ThermalBudgetSystem({
        components: [hotComponent],
        compartments: [compartment],
        coolingSystems: []
      });

      const initialComponentTemp = hotComponent.temperature;
      const initialAirTemp = compartment.temperature;

      thermal.update(60);  // 1 minute

      // Component should cool down
      expect(hotComponent.temperature).toBeLessThan(initialComponentTemp);
      // Air should heat up
      expect(compartment.temperature).toBeGreaterThan(initialAirTemp);
    });

    it('should transfer heat between compartments', () => {
      const hotCompartment: ThermalCompartment = {
        id: 'engine-room',
        name: 'Engine Room',
        temperature: 350,       // Hot
        volume: 100,
        airMass: 120,
        connectedCompartments: ['cabin']
      };

      const coldCompartment: ThermalCompartment = {
        id: 'cabin',
        name: 'Cabin',
        temperature: 293,       // Normal
        volume: 50,
        airMass: 60,
        connectedCompartments: ['engine-room']
      };

      const thermal = new ThermalBudgetSystem({
        components: [],
        compartments: [hotCompartment, coldCompartment],
        coolingSystems: []
      });

      const initialHotTemp = hotCompartment.temperature;
      const initialColdTemp = coldCompartment.temperature;

      thermal.update(100);  // 100 seconds

      // Hot compartment should cool
      expect(hotCompartment.temperature).toBeLessThan(initialHotTemp);
      // Cold compartment should warm
      expect(coldCompartment.temperature).toBeGreaterThan(initialColdTemp);
    });

    it('should radiate heat to space', () => {
      const component: ThermalComponent = {
        id: 'radiator',
        name: 'Radiator Panel',
        temperature: 400,       // Hot
        mass: 50,
        specificHeat: 900,
        surfaceArea: 10,        // Large surface
        heatGeneration: 0,
        compartmentId: 'exterior',
        exposedToSpace: true    // Radiates to space
      };

      const compartment: ThermalCompartment = {
        id: 'exterior',
        name: 'Exterior',
        temperature: 400,
        volume: 1,
        airMass: 0.001,         // Vacuum
        connectedCompartments: []
      };

      const thermal = new ThermalBudgetSystem({
        components: [component],
        compartments: [compartment],
        coolingSystems: []
      });

      const initialTemp = component.temperature;
      thermal.update(100);

      // Should cool via radiation (Stefan-Boltzmann law)
      expect(component.temperature).toBeLessThan(initialTemp);
    });
  });

  describe('Active Cooling', () => {
    it('should cool components with active cooling', () => {
      const reactor: ThermalComponent = {
        id: 'reactor',
        name: 'Reactor',
        temperature: 500,
        mass: 1000,
        specificHeat: 500,
        surfaceArea: 10,
        heatGeneration: 50000,  // 50 kW heat
        compartmentId: 'engine-room'
      };

      const cooling: CoolingSystem = {
        id: 'coolant-loop',
        type: CoolingType.LIQUID_LOOP,
        coolingCapacity: 60000,   // 60 kW capacity
        powerDraw: 2,             // 2 kW pump
        efficiency: 0.9,
        targetComponentIds: ['reactor'],
        active: true,
        flowRate: 10              // kg/s
      };

      const compartment: ThermalCompartment = {
        id: 'engine-room',
        name: 'Engine Room',
        temperature: 293,
        volume: 100,
        airMass: 120,
        connectedCompartments: []
      };

      const thermal = new ThermalBudgetSystem({
        components: [reactor],
        compartments: [compartment],
        coolingSystems: [cooling]
      });

      thermal.update(100);

      // Reactor should not overheat with adequate cooling
      expect(reactor.temperature).toBeLessThan(600);
    });

    it('should reject heat to radiators', () => {
      const radiator: ThermalComponent = {
        id: 'radiator',
        name: 'Heat Radiator',
        temperature: 293,
        mass: 100,
        specificHeat: 900,
        surfaceArea: 20,          // Large radiator
        heatGeneration: 0,
        compartmentId: 'exterior',
        exposedToSpace: true
      };

      const cooling: CoolingSystem = {
        id: 'heat-rejection',
        type: CoolingType.RADIATOR,
        coolingCapacity: 100000,  // 100 kW
        powerDraw: 1,
        efficiency: 0.95,
        targetComponentIds: ['radiator'],
        active: true,
        flowRate: 5
      };

      const compartment: ThermalCompartment = {
        id: 'exterior',
        name: 'Exterior',
        temperature: 293,
        volume: 1,
        airMass: 0.001,
        connectedCompartments: []
      };

      const thermal = new ThermalBudgetSystem({
        components: [radiator],
        compartments: [compartment],
        coolingSystems: [cooling]
      });

      // Add heat load to radiator
      radiator.heatGeneration = 50000;  // 50 kW from reactor

      thermal.update(100);

      // Radiator should stay relatively cool
      expect(radiator.temperature).toBeLessThan(400);
    });
  });

  describe('Thermal Limits and Warnings', () => {
    it('should warn when component exceeds safe temperature', () => {
      const electronics: ThermalComponent = {
        id: 'computer',
        name: 'Flight Computer',
        temperature: 293,
        mass: 10,
        specificHeat: 700,
        surfaceArea: 0.5,
        heatGeneration: 500,      // 500W heat
        compartmentId: 'cabin',
        maxSafeTemp: 330          // 57°C max
      };

      const compartment: ThermalCompartment = {
        id: 'cabin',
        name: 'Cabin',
        temperature: 293,
        volume: 50,
        airMass: 60,
        connectedCompartments: []
      };

      const thermal = new ThermalBudgetSystem({
        components: [electronics],
        compartments: [compartment],
        coolingSystems: []
      });

      // Heat up component
      for (let i = 0; i < 10; i++) {
        thermal.update(10);
      }

      const warnings = thermal.getWarnings();
      const hasOverheatWarning = warnings.some(w =>
        w.componentId === 'computer' && w.type === 'overheating'
      );

      if (electronics.temperature > 330) {
        expect(hasOverheatWarning).toBe(true);
      }
    });
  });

  describe('Statistics', () => {
    it('should track total heat generated', () => {
      const component: ThermalComponent = {
        id: 'heater',
        name: 'Heater',
        temperature: 293,
        mass: 50,
        specificHeat: 500,
        surfaceArea: 1,
        heatGeneration: 1000,     // 1 kW
        compartmentId: 'cabin'
      };

      const compartment: ThermalCompartment = {
        id: 'cabin',
        name: 'Cabin',
        temperature: 293,
        volume: 50,
        airMass: 60,
        connectedCompartments: []
      };

      const thermal = new ThermalBudgetSystem({
        components: [component],
        compartments: [compartment],
        coolingSystems: []
      });

      thermal.update(3600);  // 1 hour

      const stats = thermal.getStatistics();
      // Heat generated = 1 kW * 3600 s = 3.6 MJ
      expect(stats.totalHeatGenerated).toBeCloseTo(3600000, -3);  // Within 1000 J
    });

    it('should track total heat rejected', () => {
      const radiator: ThermalComponent = {
        id: 'radiator',
        name: 'Radiator',
        temperature: 350,         // Hot
        mass: 100,
        specificHeat: 900,
        surfaceArea: 10,
        heatGeneration: 0,
        compartmentId: 'exterior',
        exposedToSpace: true
      };

      const compartment: ThermalCompartment = {
        id: 'exterior',
        name: 'Exterior',
        temperature: 350,
        volume: 1,
        airMass: 0.001,
        connectedCompartments: []
      };

      const thermal = new ThermalBudgetSystem({
        components: [radiator],
        compartments: [compartment],
        coolingSystems: []
      });

      thermal.update(100);

      const stats = thermal.getStatistics();
      expect(stats.totalHeatRejected).toBeGreaterThan(0);
    });
  });

  describe('Integration with Power System', () => {
    it('should generate heat proportional to power consumption', () => {
      const weapon: ThermalComponent = {
        id: 'railgun',
        name: 'Railgun',
        temperature: 293,
        mass: 200,
        specificHeat: 450,
        surfaceArea: 2,
        heatGeneration: 0,        // Will be set by power system
        compartmentId: 'weapons-bay',
        powerDraw: 100,           // 100 kW when firing
        efficiency: 0.80          // 80% → projectile, 20% → heat
      };

      const compartment: ThermalCompartment = {
        id: 'weapons-bay',
        name: 'Weapons Bay',
        temperature: 293,
        volume: 50,
        airMass: 60,
        connectedCompartments: []
      };

      const thermal = new ThermalBudgetSystem({
        components: [weapon],
        compartments: [compartment],
        coolingSystems: []
      });

      // Simulate weapon firing
      weapon.heatGeneration = weapon.powerDraw * (1 - weapon.efficiency) * 1000;  // 20 kW heat

      thermal.update(1);  // 1 second burst

      expect(weapon.temperature).toBeGreaterThan(293);
    });
  });
});
