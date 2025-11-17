/**
 * LifeSupportSystem.ts
 * Comprehensive life support simulation with oxygen, CO2, temperature, water, food, and health
 */

export interface CrewMember {
  id: string;
  name: string;
  role: CrewRole;
  health: number;           // 0-100
  morale: number;           // 0-100
  fatigue: number;          // 0-100 (higher = more tired)
  hunger: number;           // 0-100
  thirst: number;           // 0-100
  oxygenSaturation: number; // 0-100% (normal: 95-100%)
  co2Exposure: number;      // ppm (parts per million)
  radiationDose: number;    // Sieverts (accumulated)
  status: CrewStatus;
  skills: Map<string, number>; // skill -> proficiency (0-100)
}

export type CrewRole = 'PILOT' | 'ENGINEER' | 'SCIENTIST' | 'MEDIC' | 'MECHANIC' | 'NAVIGATOR';
export type CrewStatus = 'HEALTHY' | 'FATIGUED' | 'SICK' | 'INJURED' | 'CRITICAL' | 'DECEASED';

export interface AtmosphereComposition {
  oxygen: number;           // percentage (normal: 21%)
  nitrogen: number;         // percentage (normal: 78%)
  co2: number;              // ppm (normal: 400, dangerous: >5000)
  humidity: number;         // percentage (comfortable: 30-50%)
  pressure: number;         // kPa (normal: 101.325)
  temperature: number;      // K (comfortable: 293-298)
}

export interface OxygenGenerator {
  id: string;
  type: 'ELECTROLYSIS' | 'CHEMICAL' | 'SABATIER' | 'COMPRESSED';
  operational: boolean;
  efficiency: number;       // 0-1
  outputRate: number;       // kg O2 per hour at 100% efficiency
  powerConsumption: number; // watts
  waterConsumption: number; // kg H2O per hour (for electrolysis)
  health: number;           // 0-100
  maintenanceRequired: number; // hours until maintenance needed
}

export interface CO2Scrubber {
  id: string;
  type: 'LITHIUM_HYDROXIDE' | 'AMINE' | 'MOLECULAR_SIEVE' | 'SABATIER';
  operational: boolean;
  efficiency: number;       // 0-1
  scrubbingRate: number;    // kg CO2 per hour
  powerConsumption: number; // watts
  consumableRemaining: number; // kg (for LiOH cartridges)
  consumableCapacity: number;  // kg
  health: number;           // 0-100
  regenerating: boolean;    // Some scrubbers need regeneration
  regenerationTime: number; // seconds remaining
}

export interface TemperatureControl {
  id: string;
  type: 'RADIATOR' | 'HEAT_PUMP' | 'COOLANT_LOOP';
  operational: boolean;
  coolingCapacity: number;  // watts
  heatingCapacity: number;  // watts
  powerConsumption: number; // watts
  coolantLevel: number;     // 0-100%
  health: number;           // 0-100
}

export interface WaterSystem {
  id: string;
  potableWater: number;     // kg
  wasteWater: number;       // kg
  capacity: number;         // kg
  recyclingRate: number;    // percentage (ISS: ~93%)
  purificationActive: boolean;
  powerConsumption: number; // watts
  filterHealth: number;     // 0-100
}

export interface FoodSupply {
  id: string;
  rations: number;          // number of person-days
  quality: number;          // 0-100 (affects morale)
  variety: number;          // 0-100 (affects morale)
  refrigerated: boolean;
  spoilageRate: number;     // person-days lost per day without refrigeration
  powerConsumption: number; // watts (for refrigeration)
}

export interface WasteManagement {
  solidWaste: number;       // kg
  capacity: number;         // kg
  processing: boolean;
  compactionRatio: number;  // reduction factor
  powerConsumption: number; // watts
}

export interface MedicalBay {
  supplies: number;         // medical units
  pharmaceuticals: number;  // doses
  diagnosticActive: boolean;
  powerConsumption: number; // watts
  canTreat: Set<string>;    // Conditions that can be treated
}

export interface LifeSupportAlert {
  severity: 'INFO' | 'WARNING' | 'CRITICAL' | 'EMERGENCY';
  system: string;
  message: string;
  timestamp: number;
  acknowledged: boolean;
}

/**
 * Comprehensive Life Support System
 */
export class LifeSupportSystem {
  private crew: Map<string, CrewMember> = new Map();
  private atmosphere: AtmosphereComposition;
  private oxygenGenerators: Map<string, OxygenGenerator> = new Map();
  private co2Scrubbers: Map<string, CO2Scrubber> = new Map();
  private temperatureControl: Map<string, TemperatureControl> = new Map();
  private waterSystem: WaterSystem | null = null;
  private foodSupply: FoodSupply | null = null;
  private wasteManagement: WasteManagement | null = null;
  private medicalBay: MedicalBay | null = null;
  private alerts: LifeSupportAlert[] = [];

  private habitableVolume: number; // m³

  // Constants
  private static readonly O2_CONSUMPTION_PER_PERSON = 0.84; // kg/day
  private static readonly CO2_PRODUCTION_PER_PERSON = 1.0;  // kg/day
  private static readonly WATER_CONSUMPTION_PER_PERSON = 3.5; // kg/day
  private static readonly FOOD_CONSUMPTION_PER_PERSON = 1.8;  // kg/day
  private static readonly HEAT_GENERATION_PER_PERSON = 100;   // watts

  constructor(habitableVolume: number) {
    this.habitableVolume = habitableVolume;

    // Initialize Earth-normal atmosphere
    this.atmosphere = {
      oxygen: 21.0,
      nitrogen: 78.0,
      co2: 400,              // ppm
      humidity: 40,
      pressure: 101.325,     // kPa
      temperature: 295       // K (22°C)
    };
  }

  /**
   * Add crew member
   */
  addCrewMember(member: CrewMember): void {
    this.crew.set(member.id, member);
  }

  /**
   * Add oxygen generator
   */
  addOxygenGenerator(generator: OxygenGenerator): void {
    this.oxygenGenerators.set(generator.id, generator);
  }

  /**
   * Add CO2 scrubber
   */
  addCO2Scrubber(scrubber: CO2Scrubber): void {
    this.co2Scrubbers.set(scrubber.id, scrubber);
  }

  /**
   * Add temperature control
   */
  addTemperatureControl(control: TemperatureControl): void {
    this.temperatureControl.set(control.id, control);
  }

  /**
   * Set water system
   */
  setWaterSystem(system: WaterSystem): void {
    this.waterSystem = system;
  }

  /**
   * Set food supply
   */
  setFoodSupply(supply: FoodSupply): void {
    this.foodSupply = supply;
  }

  /**
   * Set waste management
   */
  setWasteManagement(waste: WasteManagement): void {
    this.wasteManagement = waste;
  }

  /**
   * Set medical bay
   */
  setMedicalBay(medical: MedicalBay): void {
    this.medicalBay = medical;
  }

  /**
   * Update life support systems
   */
  update(deltaTime: number, externalTemp: number = 3): void {
    const hours = deltaTime / 3600;
    const days = deltaTime / 86400;
    const crewCount = this.crew.size;

    if (crewCount === 0) return;

    // === OXYGEN MANAGEMENT ===
    const o2Needed = (LifeSupportSystem.O2_CONSUMPTION_PER_PERSON * crewCount * days);
    let o2Generated = 0;

    for (const generator of this.oxygenGenerators.values()) {
      if (generator.operational && generator.health > 0) {
        const generated = generator.outputRate * generator.efficiency * hours;
        o2Generated += generated;

        // Consume water for electrolysis
        if (generator.type === 'ELECTROLYSIS' && this.waterSystem) {
          const waterUsed = generator.waterConsumption * hours;
          this.waterSystem.potableWater -= waterUsed;

          if (this.waterSystem.potableWater < 0) {
            this.waterSystem.potableWater = 0;
            generator.operational = false;
            this.addAlert('CRITICAL', 'O2 Generator', 'Oxygen generator offline: insufficient water');
          }
        }

        // Maintenance countdown
        generator.maintenanceRequired -= hours;
        if (generator.maintenanceRequired <= 0) {
          generator.efficiency *= 0.9; // Degraded performance
          if (generator.efficiency < 0.5) {
            generator.operational = false;
            this.addAlert('EMERGENCY', 'O2 Generator', `${generator.id} requires immediate maintenance!`);
          }
        }
      }
    }

    // Update atmospheric oxygen
    const o2Change = o2Generated - o2Needed;
    this.atmosphere.oxygen += (o2Change / this.habitableVolume) * 100; // Simplified

    // === CO2 MANAGEMENT ===
    const co2Produced = (LifeSupportSystem.CO2_PRODUCTION_PER_PERSON * crewCount * days);
    let co2Scrubbed = 0;

    for (const scrubber of this.co2Scrubbers.values()) {
      if (scrubber.operational && !scrubber.regenerating) {
        const scrubbed = scrubber.scrubbingRate * scrubber.efficiency * hours;
        co2Scrubbed += scrubbed;

        // Consume consumables (for LiOH)
        if (scrubber.type === 'LITHIUM_HYDROXIDE') {
          scrubber.consumableRemaining -= scrubbed * 2.2; // LiOH + CO2 -> Li2CO3 + H2O

          if (scrubber.consumableRemaining <= 0) {
            scrubber.operational = false;
            this.addAlert('CRITICAL', 'CO2 Scrubber', `${scrubber.id} cartridge depleted!`);
          }
        }

        // Regenerating scrubbers (amine, molecular sieve)
        if ((scrubber.type === 'AMINE' || scrubber.type === 'MOLECULAR_SIEVE') &&
            Math.random() < 0.001 * hours) {
          // Needs periodic regeneration
          scrubber.regenerating = true;
          scrubber.regenerationTime = 3600; // 1 hour
        }
      }

      // Update regeneration
      if (scrubber.regenerating) {
        scrubber.regenerationTime -= deltaTime;
        if (scrubber.regenerationTime <= 0) {
          scrubber.regenerating = false;
          scrubber.efficiency = 1.0; // Restored
        }
      }
    }

    // Update atmospheric CO2
    const co2Net = (co2Produced - co2Scrubbed) * 1e6 / this.habitableVolume; // Convert to ppm
    this.atmosphere.co2 += co2Net;

    // === TEMPERATURE CONTROL ===
    const heatGenerated = crewCount * LifeSupportSystem.HEAT_GENERATION_PER_PERSON;
    const heatLoss = (this.atmosphere.temperature - externalTemp) * 10; // Simplified heat loss
    let coolingProvided = 0;
    let heatingProvided = 0;

    for (const control of this.temperatureControl.values()) {
      if (control.operational) {
        if (this.atmosphere.temperature > 298) {
          // Need cooling
          coolingProvided += control.coolingCapacity;
        } else if (this.atmosphere.temperature < 293) {
          // Need heating
          heatingProvided += control.heatingCapacity;
        }

        // Coolant degradation
        if (control.coolantLevel > 0) {
          control.coolantLevel -= 0.01 * hours; // Slow leak
          if (control.coolantLevel < 20) {
            this.addAlert('WARNING', 'Temperature Control', `${control.id} coolant low`);
          }
        }
      }
    }

    const netHeat = heatGenerated - heatLoss - coolingProvided + heatingProvided;
    this.atmosphere.temperature += (netHeat * deltaTime) / (this.habitableVolume * 1000); // Simplified

    // === WATER MANAGEMENT ===
    if (this.waterSystem) {
      const waterConsumed = LifeSupportSystem.WATER_CONSUMPTION_PER_PERSON * crewCount * days;
      this.waterSystem.potableWater -= waterConsumed;

      // Produce waste water
      this.waterSystem.wasteWater += waterConsumed * 0.95; // Most water becomes waste

      // Recycle water
      if (this.waterSystem.purificationActive && this.waterSystem.filterHealth > 0) {
        const recycled = this.waterSystem.wasteWater * (this.waterSystem.recyclingRate / 100) * days;
        this.waterSystem.potableWater += recycled;
        this.waterSystem.wasteWater -= recycled / (this.waterSystem.recyclingRate / 100);

        // Filter degradation
        this.waterSystem.filterHealth -= 0.1 * hours;
        if (this.waterSystem.filterHealth < 20) {
          this.addAlert('WARNING', 'Water System', 'Water filters need replacement');
        }
      }

      // Check water levels
      if (this.waterSystem.potableWater < crewCount * 10) {
        this.addAlert('CRITICAL', 'Water System', 'Potable water critically low');
      }
    }

    // === FOOD MANAGEMENT ===
    if (this.foodSupply) {
      this.foodSupply.rations -= crewCount * days;

      // Spoilage
      if (!this.foodSupply.refrigerated) {
        this.foodSupply.rations -= this.foodSupply.spoilageRate * days;
        this.foodSupply.quality -= 1 * days; // Quality degrades without refrigeration
      }

      if (this.foodSupply.rations < crewCount * 7) {
        this.addAlert('WARNING', 'Food Supply', 'Food supply running low (less than 7 days)');
      }

      if (this.foodSupply.rations <= 0) {
        this.addAlert('EMERGENCY', 'Food Supply', 'Food supply exhausted!');
      }
    }

    // === WASTE MANAGEMENT ===
    if (this.wasteManagement) {
      const wasteGenerated = crewCount * 0.5 * days; // kg per person per day
      this.wasteManagement.solidWaste += wasteGenerated;

      // Compact waste
      if (this.wasteManagement.processing) {
        const compacted = this.wasteManagement.solidWaste * (1 - 1/this.wasteManagement.compactionRatio);
        this.wasteManagement.solidWaste -= compacted;
      }

      if (this.wasteManagement.solidWaste > this.wasteManagement.capacity * 0.9) {
        this.addAlert('WARNING', 'Waste Management', 'Waste storage nearing capacity');
      }
    }

    // === UPDATE CREW HEALTH ===
    for (const member of this.crew.values()) {
      this.updateCrewMember(member, days);
    }

    // === CHECK CRITICAL CONDITIONS ===
    this.checkCriticalConditions();
  }

  /**
   * Update individual crew member
   */
  private updateCrewMember(member: CrewMember, days: number): void {
    // Oxygen saturation based on atmospheric O2
    if (this.atmosphere.oxygen < 19) {
      // Hypoxia
      member.oxygenSaturation -= (19 - this.atmosphere.oxygen) * 5 * days;
      member.health -= (19 - this.atmosphere.oxygen) * 2 * days;
      if (member.status === 'HEALTHY') {
        member.status = 'SICK';
        this.addAlert('CRITICAL', 'Crew Health', `${member.name} experiencing hypoxia`);
      }
    } else if (this.atmosphere.oxygen > 23) {
      // Oxygen toxicity (long term)
      member.health -= (this.atmosphere.oxygen - 23) * 0.5 * days;
    } else {
      // Normal O2, recover slowly
      member.oxygenSaturation = Math.min(100, member.oxygenSaturation + 10 * days);
    }

    // CO2 exposure
    member.co2Exposure = this.atmosphere.co2;
    if (this.atmosphere.co2 > 5000) {
      // Dangerous CO2 levels
      const severity = (this.atmosphere.co2 - 5000) / 1000;
      member.health -= severity * 5 * days;
      member.fatigue += severity * 10 * days;
      if (member.status === 'HEALTHY') {
        member.status = 'SICK';
        this.addAlert('CRITICAL', 'Crew Health', `${member.name} experiencing CO2 poisoning`);
      }
    }

    // Temperature effects
    if (this.atmosphere.temperature < 283 || this.atmosphere.temperature > 303) {
      const discomfort = Math.abs(this.atmosphere.temperature - 293);
      member.health -= discomfort * 0.5 * days;
      member.morale -= discomfort * 2 * days;
      member.fatigue += discomfort * 1 * days;
    }

    // Hunger and thirst
    if (this.foodSupply && this.foodSupply.rations > 0) {
      member.hunger = Math.max(0, member.hunger - 20 * days);
      member.morale += (this.foodSupply.quality / 100) * 2 * days;
    } else {
      member.hunger += 30 * days;
      member.health -= member.hunger * 0.1 * days;
      member.morale -= 10 * days;
    }

    if (this.waterSystem && this.waterSystem.potableWater > 0) {
      member.thirst = Math.max(0, member.thirst - 25 * days);
    } else {
      member.thirst += 40 * days;
      member.health -= member.thirst * 0.2 * days;
    }

    // Fatigue accumulation
    member.fatigue += 10 * days;
    if (member.fatigue > 70 && member.status === 'HEALTHY') {
      member.status = 'FATIGUED';
    }

    // Health effects on status
    if (member.health < 20) {
      member.status = 'CRITICAL';
      this.addAlert('EMERGENCY', 'Crew Health', `${member.name} in critical condition!`);
    } else if (member.health < 50) {
      member.status = 'INJURED';
    } else if (member.health < 80 && member.status !== 'FATIGUED') {
      member.status = 'SICK';
    } else if (member.health >= 80 && member.fatigue < 70) {
      member.status = 'HEALTHY';
    }

    // Death
    if (member.health <= 0) {
      member.status = 'DECEASED';
      this.addAlert('EMERGENCY', 'Crew', `${member.name} has died`);
    }

    // Clamp values
    member.health = Math.max(0, Math.min(100, member.health));
    member.morale = Math.max(0, Math.min(100, member.morale));
    member.fatigue = Math.max(0, Math.min(100, member.fatigue));
    member.hunger = Math.max(0, Math.min(100, member.hunger));
    member.thirst = Math.max(0, Math.min(100, member.thirst));
    member.oxygenSaturation = Math.max(0, Math.min(100, member.oxygenSaturation));
  }

  /**
   * Check for critical conditions
   */
  private checkCriticalConditions(): void {
    // Oxygen
    if (this.atmosphere.oxygen < 17) {
      this.addAlert('EMERGENCY', 'Atmosphere', `Oxygen critically low: ${this.atmosphere.oxygen.toFixed(1)}%`);
    } else if (this.atmosphere.oxygen < 19) {
      this.addAlert('CRITICAL', 'Atmosphere', `Oxygen low: ${this.atmosphere.oxygen.toFixed(1)}%`);
    }

    // CO2
    if (this.atmosphere.co2 > 10000) {
      this.addAlert('EMERGENCY', 'Atmosphere', `CO2 at lethal levels: ${this.atmosphere.co2.toFixed(0)} ppm`);
    } else if (this.atmosphere.co2 > 5000) {
      this.addAlert('CRITICAL', 'Atmosphere', `CO2 dangerous: ${this.atmosphere.co2.toFixed(0)} ppm`);
    }

    // Temperature
    if (this.atmosphere.temperature < 273 || this.atmosphere.temperature > 313) {
      this.addAlert('EMERGENCY', 'Temperature', `Extreme temperature: ${(this.atmosphere.temperature - 273).toFixed(1)}°C`);
    } else if (this.atmosphere.temperature < 283 || this.atmosphere.temperature > 303) {
      this.addAlert('WARNING', 'Temperature', `Temperature uncomfortable: ${(this.atmosphere.temperature - 273).toFixed(1)}°C`);
    }

    // Pressure
    if (this.atmosphere.pressure < 50 || this.atmosphere.pressure > 150) {
      this.addAlert('EMERGENCY', 'Atmosphere', `Pressure critical: ${this.atmosphere.pressure.toFixed(1)} kPa`);
    }
  }

  /**
   * Add alert
   */
  private addAlert(severity: LifeSupportAlert['severity'], system: string, message: string): void {
    // Don't duplicate recent alerts
    const recent = this.alerts.find(a =>
      a.system === system &&
      a.message === message &&
      Date.now() - a.timestamp < 60000 // Within last minute
    );

    if (!recent) {
      this.alerts.push({
        severity,
        system,
        message,
        timestamp: Date.now(),
        acknowledged: false
      });

      // Keep only last 100 alerts
      if (this.alerts.length > 100) {
        this.alerts = this.alerts.slice(-50);
      }
    }
  }

  /**
   * Acknowledge alert
   */
  acknowledgeAlert(index: number): void {
    if (this.alerts[index]) {
      this.alerts[index].acknowledged = true;
    }
  }

  /**
   * Get power consumption
   */
  getTotalPowerConsumption(): number {
    let total = 0;

    for (const gen of this.oxygenGenerators.values()) {
      if (gen.operational) total += gen.powerConsumption;
    }

    for (const scrubber of this.co2Scrubbers.values()) {
      if (scrubber.operational) total += scrubber.powerConsumption;
    }

    for (const control of this.temperatureControl.values()) {
      if (control.operational) total += control.powerConsumption;
    }

    if (this.waterSystem?.purificationActive) {
      total += this.waterSystem.powerConsumption;
    }

    if (this.foodSupply?.refrigerated) {
      total += this.foodSupply.powerConsumption;
    }

    if (this.wasteManagement?.processing) {
      total += this.wasteManagement.powerConsumption;
    }

    if (this.medicalBay?.diagnosticActive) {
      total += this.medicalBay.powerConsumption;
    }

    return total;
  }

  /**
   * Get comprehensive status
   */
  getStatus(): {
    atmosphere: AtmosphereComposition;
    crew: CrewMember[];
    systems: {
      oxygen: OxygenGenerator[];
      co2: CO2Scrubber[];
      temperature: TemperatureControl[];
      water: WaterSystem | null;
      food: FoodSupply | null;
      waste: WasteManagement | null;
      medical: MedicalBay | null;
    };
    alerts: LifeSupportAlert[];
    powerConsumption: number;
    consumables: {
      daysOfOxygen: number;
      daysOfFood: number;
      daysOfWater: number;
    };
  } {
    const crewCount = this.crew.size;

    // Calculate days of consumables
    const totalO2Capacity = Array.from(this.oxygenGenerators.values())
      .reduce((sum, gen) => sum + (gen.operational ? gen.outputRate * 24 : 0), 0);
    const o2Consumption = LifeSupportSystem.O2_CONSUMPTION_PER_PERSON * crewCount;
    const daysOfOxygen = o2Consumption > 0 ? totalO2Capacity / o2Consumption : Infinity;

    const daysOfFood = this.foodSupply && crewCount > 0 ? this.foodSupply.rations / crewCount : 0;

    const waterConsumption = LifeSupportSystem.WATER_CONSUMPTION_PER_PERSON * crewCount;
    const daysOfWater = this.waterSystem && waterConsumption > 0 ?
      this.waterSystem.potableWater / waterConsumption : 0;

    return {
      atmosphere: { ...this.atmosphere },
      crew: Array.from(this.crew.values()),
      systems: {
        oxygen: Array.from(this.oxygenGenerators.values()),
        co2: Array.from(this.co2Scrubbers.values()),
        temperature: Array.from(this.temperatureControl.values()),
        water: this.waterSystem ? { ...this.waterSystem } : null,
        food: this.foodSupply ? { ...this.foodSupply } : null,
        waste: this.wasteManagement ? { ...this.wasteManagement } : null,
        medical: this.medicalBay ? { ...this.medicalBay } : null
      },
      alerts: this.alerts.filter(a => !a.acknowledged),
      powerConsumption: this.getTotalPowerConsumption(),
      consumables: {
        daysOfOxygen,
        daysOfFood,
        daysOfWater
      }
    };
  }

  /**
   * Emergency actions
   */
  emergencyPurge(): void {
    this.atmosphere.co2 = 400;
    this.addAlert('WARNING', 'System', 'Emergency atmosphere purge completed');
  }

  /**
   * Crew rest (reduces fatigue)
   */
  crewRest(memberId: string, hours: number): void {
    const member = this.crew.get(memberId);
    if (member) {
      member.fatigue = Math.max(0, member.fatigue - hours * 10);
      if (member.fatigue < 30) {
        member.status = 'HEALTHY';
      }
    }
  }

  /**
   * Medical treatment
   */
  treatCrewMember(memberId: string): boolean {
    const member = this.crew.get(memberId);
    if (!member || !this.medicalBay) return false;

    if (this.medicalBay.supplies > 0 && this.medicalBay.pharmaceuticals > 0) {
      member.health = Math.min(100, member.health + 30);
      this.medicalBay.supplies -= 1;
      this.medicalBay.pharmaceuticals -= 1;

      if (member.health > 80) {
        member.status = 'HEALTHY';
      } else if (member.health > 50) {
        member.status = 'SICK';
      }

      return true;
    }

    return false;
  }
}
