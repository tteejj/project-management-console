"use strict";
/**
 * Ship Configuration - Unified ship definition
 *
 * Ties together all subsystems into a complete, simulated spacecraft
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.ShipTemplates = exports.CompleteShip = void 0;
const hull_damage_1 = require("./hull-damage");
const life_support_1 = require("./life-support");
const power_budget_1 = require("./power-budget");
const thermal_budget_1 = require("./thermal-budget");
const system_damage_1 = require("./system-damage");
const damage_control_1 = require("./damage-control");
const combat_computer_1 = require("./combat-computer");
/**
 * Complete Ship - integrates all subsystems
 */
class CompleteShip {
    constructor(config) {
        this.id = config.id;
        this.name = config.name;
        this.class = config.class;
        this.position = config.position;
        this.velocity = config.velocity;
        this.mass = config.mass;
        // Initialize hull
        this.hull = new hull_damage_1.HullStructure({
            compartments: config.compartments,
            armorLayers: config.armorLayers
        });
        // Initialize power
        this.power = new power_budget_1.PowerBudgetSystem({
            sources: config.powerSources,
            consumers: config.powerConsumers,
            batteries: config.batteries
        });
        // Initialize thermal
        this.thermal = new thermal_budget_1.ThermalBudgetSystem({
            components: config.thermalComponents,
            compartments: config.thermalCompartments,
            coolingSystems: config.coolingSystems
        });
        // Initialize systems
        this.systemDamage = new system_damage_1.SystemDamageManager({
            systems: config.systems,
            hull: this.hull
        });
        // Initialize life support
        this.lifeSupport = new life_support_1.LifeSupportSystem(this.hull, config.crew, config.lifeSupport);
        // Initialize damage control
        const repairCrews = config.crew.map(crewMember => ({
            crewMember,
            repairSkill: 0.8, // Default skill
            efficiency: 1.0,
            currentTask: null,
            fatigueLevel: 0
        }));
        this.damageControl = new damage_control_1.DamageControlSystem({
            repairCrews,
            hull: this.hull,
            systems: config.systems
        });
        // Initialize combat computer
        this.combatComputer = new combat_computer_1.CombatComputer({
            position: this.position,
            velocity: this.velocity
        });
    }
    /**
     * Update all ship systems
     */
    update(dt) {
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
exports.CompleteShip = CompleteShip;
/**
 * Example ship configurations
 */
class ShipTemplates {
    /**
     * Small frigate - basic combat ship
     */
    static createFrigate(id, position, velocity) {
        const config = {
            id,
            name: 'Frigate',
            class: 'Frigate-class',
            mass: 50000, // 50 tons
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
                    id: 'hull-armor-1',
                    material: hull_damage_1.MaterialType.TITANIUM,
                    thickness: 0.05, // 5cm
                    density: 4500,
                    hardness: 6.0,
                    integrity: 1.0,
                    ablationDepth: 0
                }
            ],
            // Power: Reactor + batteries
            powerSources: [{
                    id: 'reactor-1',
                    type: power_budget_1.PowerSourceType.REACTOR,
                    maxOutput: 50, // 50 kW
                    currentOutput: 0,
                    efficiency: 0.90,
                    powered: true
                }],
            powerConsumers: [
                {
                    id: 'life-support',
                    name: 'Life Support',
                    powerDraw: 5,
                    priority: power_budget_1.PowerPriority.CRITICAL,
                    powered: true,
                    actualPower: 0
                },
                {
                    id: 'sensors',
                    name: 'Sensors',
                    powerDraw: 3,
                    priority: power_budget_1.PowerPriority.HIGH,
                    powered: true,
                    actualPower: 0
                },
                {
                    id: 'weapons',
                    name: 'Weapons',
                    powerDraw: 10,
                    priority: power_budget_1.PowerPriority.MEDIUM,
                    powered: true,
                    actualPower: 0
                }
            ],
            batteries: [{
                    id: 'battery-1',
                    capacity: 100, // 100 kWh
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
                    heatGeneration: 5000, // 5 kW waste heat
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
                    type: system_damage_1.SystemType.POWER,
                    compartmentId: 'engineering',
                    integrity: 1.0,
                    status: system_damage_1.SystemStatus.ONLINE,
                    powerDraw: 0,
                    operational: true,
                    isCritical: true
                },
                {
                    id: 'life-support-sys',
                    name: 'Life Support',
                    type: system_damage_1.SystemType.LIFE_SUPPORT,
                    compartmentId: 'engineering',
                    integrity: 1.0,
                    status: system_damage_1.SystemStatus.ONLINE,
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
                    status: life_support_1.CrewStatus.HEALTHY
                },
                {
                    id: 'engineer',
                    name: 'Engineer',
                    location: 'engineering',
                    health: 1.0,
                    oxygenLevel: 1.0,
                    status: life_support_1.CrewStatus.HEALTHY
                }
            ],
            lifeSupport: {
                oxygenGenerationRate: 0.5, // kg/hr
                co2ScrubberRate: 0.5,
                powered: true
            }
        };
        return new CompleteShip(config);
    }
}
exports.ShipTemplates = ShipTemplates;
//# sourceMappingURL=ship-configuration.js.map