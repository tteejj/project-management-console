/**
 * Ship Configuration - Unified ship definition
 *
 * Ties together all subsystems into a complete, simulated spacecraft
 */

import { Vector3 } from './math-utils';
import { HullStructure, Compartment, ArmorLayer } from './hull-damage';
import { LifeSupportSystem, CrewMember, LifeSupportConfig, CrewStatus } from './life-support';
import { PowerBudgetSystem, PowerSource, PowerConsumer, BatteryBank, PowerSourceType, PowerPriority } from './power-budget';
import { ThermalBudgetSystem, ThermalComponent, ThermalCompartment, CoolingSystem } from './thermal-budget';
import { SystemDamageManager, ShipSystem, SystemType, SystemStatus } from './system-damage';
import { DamageControlSystem, RepairCrew } from './damage-control';
import { CombatComputer } from './combat-computer';

/**
 * Complete ship configuration
 */
export interface ShipConfig {
  // Identity
  id: string;
  name: string;
  class: string;

  // Physics
  mass: number;              // kg
  position: Vector3;
  velocity: Vector3;

  // Hull Structure
  compartments: Compartment[];
  armorLayers: ArmorLayer[];

  // Power Systems
  powerSources: PowerSource[];
  powerConsumers: PowerConsumer[];
  batteries: BatteryBank[];

  // Thermal Systems
  thermalComponents: ThermalComponent[];
  thermalCompartments: ThermalCompartment[];
  coolingSystems: CoolingSystem[];

  // Ship Systems
  systems: ShipSystem[];

  // Life Support & Crew
  crew: CrewMember[];
  lifeSupport: LifeSupportConfig;

  // Combat
  weapons?: any[];  // From existing weapons system
}

/**
 * Complete Ship - integrates all subsystems
 */
export class CompleteShip {
  // Identity
  public id: string;
  public name: string;
  public class: string;

  // Subsystems
  public hull: HullStructure;
  public lifeSupport: LifeSupportSystem;
  public power: PowerBudgetSystem;
  public thermal: ThermalBudgetSystem;
  public systemDamage: SystemDamageManager;
  public damageControl: DamageControlSystem;
  public combatComputer: CombatComputer;

  // Physics state
  public position: Vector3;
  public velocity: Vector3;
  public mass: number;

  constructor(config: ShipConfig) {
    this.id = config.id;
    this.name = config.name;
    this.class = config.class;
    this.position = config.position;
    this.velocity = config.velocity;
    this.mass = config.mass;

    // Initialize hull
    this.hull = new HullStructure({
      compartments: config.compartments,
      armorLayers: config.armorLayers
    });

    // Initialize power
    this.power = new PowerBudgetSystem({
      sources: config.powerSources,
      consumers: config.powerConsumers,
      batteries: config.batteries
    });

    // Initialize thermal
    this.thermal = new ThermalBudgetSystem({
      components: config.thermalComponents,
      compartments: config.thermalCompartments,
      coolingSystems: config.coolingSystems
    });

    // Initialize systems
    this.systemDamage = new SystemDamageManager({
      systems: config.systems,
      hull: this.hull
    });

    // Initialize life support
    this.lifeSupport = new LifeSupportSystem(
      this.hull,
      config.crew,
      config.lifeSupport
    );

    // Initialize damage control
    const repairCrews: RepairCrew[] = config.crew.map(crewMember => ({
      crewMember,
      repairSkill: 0.8,  // Default skill
      efficiency: 1.0,
      currentTask: null,
      fatigueLevel: 0
    }));

    this.damageControl = new DamageControlSystem({
      repairCrews,
      hull: this.hull,
      systems: config.systems
    });

    // Initialize combat computer
    this.combatComputer = new CombatComputer({
      position: this.position,
      velocity: this.velocity
    });
  }

  /**
   * Update all ship systems
   */
  update(dt: number): void {
    // PHASE 1: Power generation and distribution
    this.power.update(dt);

    // PHASE 2: Thermal management
    this.thermal.update(dt);

    // PHASE 3: Life support
    this.lifeSupport.update(dt);

    // PHASE 4: System damage propagation
    this.systemDamage.update(dt);

    // PHASE 5: Damage control / repairs
    this.damageControl.update(dt);

    // PHASE 6: Combat computer
    this.combatComputer.update(dt);
    this.combatComputer.updateOwnShip(this.position, this.velocity);
  }

  /**
   * Get ship status summary
   */
  getStatus() {
    const powerStats = this.power.getStatistics();
    const thermalStats = this.thermal.getStatistics();
    const damageReport = this.systemDamage.getDamageReport();
    const lifeStats = this.lifeSupport.getStatistics();

    return {
      ship: {
        id: this.id,
        name: this.name,
        class: this.class,
        position: this.position,
        velocity: this.velocity,
        mass: this.mass
      },
      power: {
        generation: powerStats.totalGeneration,
        consumption: powerStats.totalConsumption,
        batteryCharge: powerStats.batteryCharge,
        batteryCapacity: powerStats.batteryCapacity,
        brownout: powerStats.brownoutActive
      },
      thermal: {
        averageTemp: thermalStats.averageTemperature,
        hottestComponent: thermalStats.hottestComponent,
        hottestTemp: thermalStats.hottestTemperature
      },
      damage: {
        totalSystems: damageReport.totalSystems,
        operational: damageReport.operationalSystems,
        criticalFailures: damageReport.criticalFailures.length
      },
      lifeSupport: {
        crewHealthy: lifeStats.healthyCrew,
        crewTotal: this.lifeSupport.getCrew().length,
        oxygenConsumed: lifeStats.oxygenConsumed
      },
      combat: {
        tracks: this.combatComputer.getTracks().length
      }
    };
  }
}

/**
 * Example ship configurations
 */
export class ShipTemplates {
  /**
   * Small frigate - basic combat ship
   */
  static createFrigate(id: string, position: Vector3, velocity: Vector3): CompleteShip {
    const config: ShipConfig = {
      id,
      name: 'Frigate',
      class: 'Frigate-class',
      mass: 50000,  // 50 tons
      position,
      velocity,

      // Hull: 3 compartments
      compartments: [
        {
          id: 'bridge',
          name: 'Bridge',
          volume: 30,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: ['engineering']
        },
        {
          id: 'engineering',
          name: 'Engineering',
          volume: 50,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: ['bridge', 'cargo']
        },
        {
          id: 'cargo',
          name: 'Cargo Bay',
          volume: 100,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: ['engineering']
        }
      ],

      armorLayers: [
        {
          material: 'titanium-alloy',
          thickness: 0.05,  // 5cm
          density: 4500,
          hardness: 6.0
        }
      ],

      // Power: Reactor + batteries
      powerSources: [{
        id: 'reactor-1',
        type: PowerSourceType.REACTOR,
        maxOutput: 50,  // 50 kW
        currentOutput: 0,
        efficiency: 0.90,
        powered: true
      }],

      powerConsumers: [
        {
          id: 'life-support',
          name: 'Life Support',
          powerDraw: 5,
          priority: PowerPriority.CRITICAL,
          powered: true,
          actualPower: 0
        },
        {
          id: 'sensors',
          name: 'Sensors',
          powerDraw: 3,
          priority: PowerPriority.HIGH,
          powered: true,
          actualPower: 0
        },
        {
          id: 'weapons',
          name: 'Weapons',
          powerDraw: 10,
          priority: PowerPriority.MEDIUM,
          powered: true,
          actualPower: 0
        }
      ],

      batteries: [{
        id: 'battery-1',
        capacity: 100,  // 100 kWh
        currentCharge: 80,
        maxChargeRate: 20,
        maxDischargeRate: 30,
        efficiency: 0.95
      }],

      // Thermal
      thermalComponents: [
        {
          id: 'reactor-thermal',
          name: 'Reactor',
          temperature: 400,
          mass: 1000,
          specificHeat: 500,
          surfaceArea: 5,
          heatGeneration: 5000,  // 5 kW waste heat
          compartmentId: 'engineering'
        }
      ],

      thermalCompartments: [
        {
          id: 'bridge',
          name: 'Bridge',
          temperature: 293,
          volume: 30,
          airMass: 36,
          connectedCompartments: ['engineering']
        },
        {
          id: 'engineering',
          name: 'Engineering',
          temperature: 293,
          volume: 50,
          airMass: 60,
          connectedCompartments: ['bridge', 'cargo']
        },
        {
          id: 'cargo',
          name: 'Cargo',
          temperature: 293,
          volume: 100,
          airMass: 120,
          connectedCompartments: ['engineering']
        }
      ],

      coolingSystems: [],

      // Systems
      systems: [
        {
          id: 'reactor-sys',
          name: 'Main Reactor',
          type: SystemType.POWER,
          compartmentId: 'engineering',
          integrity: 1.0,
          status: SystemStatus.ONLINE,
          powerDraw: 0,
          operational: true,
          isCritical: true
        },
        {
          id: 'life-support-sys',
          name: 'Life Support',
          type: SystemType.LIFE_SUPPORT,
          compartmentId: 'engineering',
          integrity: 1.0,
          status: SystemStatus.ONLINE,
          powerDraw: 5,
          operational: true,
          isCritical: true,
          dependencies: ['reactor-sys']
        }
      ],

      // Crew
      crew: [
        {
          id: 'captain',
          name: 'Captain',
          location: 'bridge',
          health: 1.0,
          oxygenLevel: 1.0,
          status: CrewStatus.HEALTHY
        },
        {
          id: 'engineer',
          name: 'Engineer',
          location: 'engineering',
          health: 1.0,
          oxygenLevel: 1.0,
          status: CrewStatus.HEALTHY
        }
      ],

      lifeSupport: {
        oxygenGenerationRate: 0.5,  // kg/hr
        co2ScrubberRate: 0.5,
        powered: true
      }
    };

    return new CompleteShip(config);
  }
}
