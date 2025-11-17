/**
 * Environmental Systems Subsystem
 *
 * Simulates:
 * - Atmospheric control (pressure, composition)
 * - Air circulation and filtration
 * - Humidity control
 * - Atmosphere monitoring (CO2, O2, contaminants)
 * - Emergency oxygen systems
 * - Decompression detection and response
 * - Radiation shielding effectiveness
 * - Micrometeorite damage detection
 */

export interface AtmosphericConditions {
  pressureKPa: number; // Cabin pressure
  oxygenPercentage: number; // % O2
  co2PPM: number; // Parts per million CO2
  nitrogenPercentage: number; // % N2
  humidity: number; // % relative humidity
  temperature: number; // Celsius
  contaminants: number; // 0-1, contaminant level
}

export interface Compartment {
  id: string;
  name: string;
  volumeM3: number;
  conditions: AtmosphericConditions;
  sealed: boolean;
  pressurized: boolean;
  occupants: number;
}

export interface EnvironmentalConfig {
  compartments?: Compartment[];
  scrubberCapacity?: number; // CO2 removal rate kg/hr
  oxygenGenerationRate?: number; // kg/hr
  emergencyO2Capacity?: number; // kg
  radiationShieldingFactor?: number; // 0-1, effectiveness
  powerConsumptionW?: number;
}

export class EnvironmentalSystem {
  // Compartments
  public compartments: Map<string, Compartment>;

  // Life support equipment
  public scrubbers: {
    operational: boolean;
    capacity: number; // kg CO2/hr
    currentLoad: number; // 0-1
    filterLife: number; // 0-1, filter remaining
  };

  public oxygenGenerator: {
    operational: boolean;
    generationRate: number; // kg O2/hr
    currentOutput: number; // kg O2/hr
  };

  public emergencyOxygen: {
    available: boolean;
    capacityKg: number;
    remainingKg: number;
    active: boolean;
    flowRate: number; // kg/hr when active
  };

  public airCirculation: {
    operational: boolean;
    fanSpeed: number; // 0-1
    filterEfficiency: number; // 0-1
  };

  // Monitoring
  public alarms: {
    highCO2: boolean;
    lowO2: boolean;
    lowPressure: boolean;
    highContaminants: boolean;
  };

  // Radiation protection
  public radiationShielding: {
    effectiveness: number; // 0-1
    currentRadiationLevel: number; // mSv/hr
    cumulativeExposure: number; // mSv
  };

  // Hull integrity
  public hullIntegrity: {
    breachDetected: boolean;
    leakRate: number; // kg/hr atmosphere loss
    micrometeoriteHits: number;
  };

  // State
  public operational: boolean = true;
  public isPowered: boolean = true;

  // Power tracking
  public currentPowerDraw: number = 0; // W
  public basePowerDraw: number = 100; // W (monitoring and control)
  public powerConsumptionW: number;

  // Constants
  private readonly NOMINAL_PRESSURE_KPA = 101.3;
  private readonly NOMINAL_O2_PERCENT = 21.0;
  private readonly MAX_CO2_PPM = 5000; // NASA limit
  private readonly CO2_PRODUCTION_PER_PERSON = 0.04; // kg/hr

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor(config?: EnvironmentalConfig) {
    this.compartments = new Map();

    if (config?.compartments) {
      config.compartments.forEach(c => this.compartments.set(c.id, c));
    } else {
      this.createDefaultCompartments();
    }

    this.scrubbers = {
      operational: true,
      capacity: config?.scrubberCapacity || 2.0, // kg CO2/hr
      currentLoad: 0,
      filterLife: 1.0
    };

    this.oxygenGenerator = {
      operational: true,
      generationRate: config?.oxygenGenerationRate || 1.0, // kg O2/hr
      currentOutput: 0
    };

    this.emergencyOxygen = {
      available: true,
      capacityKg: config?.emergencyO2Capacity || 50.0,
      remainingKg: config?.emergencyO2Capacity || 50.0,
      active: false,
      flowRate: 5.0 // kg/hr
    };

    this.airCirculation = {
      operational: true,
      fanSpeed: 0.8,
      filterEfficiency: 0.95
    };

    this.alarms = {
      highCO2: false,
      lowO2: false,
      lowPressure: false,
      highContaminants: false
    };

    this.radiationShielding = {
      effectiveness: config?.radiationShieldingFactor || 0.7,
      currentRadiationLevel: 0,
      cumulativeExposure: 0
    };

    this.hullIntegrity = {
      breachDetected: false,
      leakRate: 0,
      micrometeoriteHits: 0
    };

    this.powerConsumptionW = config?.powerConsumptionW || 800.0;
    this.currentPowerDraw = this.basePowerDraw + this.powerConsumptionW;
  }

  private createDefaultCompartments(): void {
    const defaultCompartments: Compartment[] = [
      {
        id: 'bridge',
        name: 'Bridge',
        volumeM3: 40,
        conditions: this.getNominalConditions(),
        sealed: true,
        pressurized: true,
        occupants: 3
      },
      {
        id: 'crew_quarters',
        name: 'Crew Quarters',
        volumeM3: 60,
        conditions: this.getNominalConditions(),
        sealed: true,
        pressurized: true,
        occupants: 4
      },
      {
        id: 'engineering',
        name: 'Engineering',
        volumeM3: 50,
        conditions: this.getNominalConditions(),
        sealed: true,
        pressurized: true,
        occupants: 2
      },
      {
        id: 'cargo_bay',
        name: 'Cargo Bay',
        volumeM3: 100,
        conditions: {
          ...this.getNominalConditions(),
          pressureKPa: 0,
          oxygenPercentage: 0
        },
        sealed: true,
        pressurized: false,
        occupants: 0
      }
    ];

    defaultCompartments.forEach(c => this.compartments.set(c.id, c));
  }

  private getNominalConditions(): AtmosphericConditions {
    return {
      pressureKPa: this.NOMINAL_PRESSURE_KPA,
      oxygenPercentage: this.NOMINAL_O2_PERCENT,
      co2PPM: 400,
      nitrogenPercentage: 78.0,
      humidity: 45,
      temperature: 22,
      contaminants: 0
    };
  }

  /**
   * Update atmospheric conditions for all compartments
   */
  public updateAtmosphere(dt: number): void {
    if (!this.operational || !this.isPowered) return;

    this.compartments.forEach(comp => {
      if (!comp.pressurized) return;

      // CO2 production from occupants
      const co2Production = comp.occupants * this.CO2_PRODUCTION_PER_PERSON * (dt / 3600);

      // Update CO2 levels
      const co2MassKg = (comp.conditions.co2PPM / 1_000_000) * comp.volumeM3 * 1.98; // ~density of CO2
      const newCO2Mass = co2MassKg + co2Production;

      // Scrubber removes CO2
      if (this.scrubbers.operational) {
        const scrubberRemoval = (this.scrubbers.capacity * (dt / 3600)) / this.compartments.size;
        const finalCO2 = Math.max(0, newCO2Mass - scrubberRemoval);
        comp.conditions.co2PPM = (finalCO2 / comp.volumeM3 / 1.98) * 1_000_000;

        this.scrubbers.currentLoad = comp.conditions.co2PPM / this.MAX_CO2_PPM;

        // Filter degradation
        this.scrubbers.filterLife -= (dt / 3600) * 0.001; // 1000 hours life
      } else {
        comp.conditions.co2PPM = (newCO2Mass / comp.volumeM3 / 1.98) * 1_000_000;
      }

      // O2 consumption (simplified)
      const o2Consumption = comp.occupants * 0.023 * (dt / 3600); // kg/hr per person
      const o2Mass = (comp.conditions.oxygenPercentage / 100) * comp.volumeM3 * 1.429; // density of O2

      // O2 generator replenishment
      if (this.oxygenGenerator.operational) {
        const o2Generation = (this.oxygenGenerator.generationRate * (dt / 3600)) / this.compartments.size;
        const finalO2 = o2Mass - o2Consumption + o2Generation;
        comp.conditions.oxygenPercentage = (finalO2 / comp.volumeM3 / 1.429) * 100;
        this.oxygenGenerator.currentOutput = o2Generation * 3600 / dt;
      } else {
        const finalO2 = o2Mass - o2Consumption;
        comp.conditions.oxygenPercentage = (finalO2 / comp.volumeM3 / 1.429) * 100;
      }

      // Emergency oxygen override
      if (this.emergencyOxygen.active && this.emergencyOxygen.remainingKg > 0) {
        const emergencyFlow = (this.emergencyOxygen.flowRate * (dt / 3600)) / this.compartments.size;
        comp.conditions.oxygenPercentage += (emergencyFlow / comp.volumeM3 / 1.429) * 100;
        this.emergencyOxygen.remainingKg -= emergencyFlow;

        if (this.emergencyOxygen.remainingKg <= 0) {
          this.emergencyOxygen.active = false;
          this.emergencyOxygen.available = false;
          this.logEvent('emergency_oxygen_depleted', {});
        }
      }

      // Hull breach - pressure loss
      if (this.hullIntegrity.breachDetected && this.hullIntegrity.leakRate > 0) {
        const leakMass = this.hullIntegrity.leakRate * (dt / 3600);
        const currentAtmosphereMass = comp.volumeM3 * (comp.conditions.pressureKPa / this.NOMINAL_PRESSURE_KPA) * 1.225;
        const newAtmosphereMass = Math.max(0, currentAtmosphereMass - leakMass);
        comp.conditions.pressureKPa = (newAtmosphereMass / comp.volumeM3 / 1.225) * this.NOMINAL_PRESSURE_KPA;
      }

      // Update alarms
      this.updateAlarms(comp);
    });

    // Radiation exposure
    this.updateRadiationExposure(dt);
  }

  /**
   * Update radiation exposure
   */
  private updateRadiationExposure(dt: number): void {
    // Simplified - would normally depend on location (solar events, Van Allen belts, etc.)
    const baseRadiation = 0.05; // mSv/hr in space
    const shieldedRadiation = baseRadiation * (1 - this.radiationShielding.effectiveness);

    this.radiationShielding.currentRadiationLevel = shieldedRadiation;
    this.radiationShielding.cumulativeExposure += shieldedRadiation * (dt / 3600);

    // Alert on high exposure
    if (this.radiationShielding.cumulativeExposure > 100) {
      this.logEvent('radiation_warning', {
        cumulative: this.radiationShielding.cumulativeExposure
      });
    }
  }

  /**
   * Update environmental alarms
   */
  private updateAlarms(comp: Compartment): void {
    const prevHighCO2 = this.alarms.highCO2;
    const prevLowO2 = this.alarms.lowO2;
    const prevLowPressure = this.alarms.lowPressure;

    this.alarms.highCO2 = comp.conditions.co2PPM > this.MAX_CO2_PPM;
    this.alarms.lowO2 = comp.conditions.oxygenPercentage < 19.5;
    this.alarms.lowPressure = comp.conditions.pressureKPa < 80.0;
    this.alarms.highContaminants = comp.conditions.contaminants > 0.5;

    // Log new alarms
    if (this.alarms.highCO2 && !prevHighCO2) {
      this.logEvent('alarm_high_co2', { compartment: comp.id, co2: comp.conditions.co2PPM });
    }
    if (this.alarms.lowO2 && !prevLowO2) {
      this.logEvent('alarm_low_o2', { compartment: comp.id, o2: comp.conditions.oxygenPercentage });
    }
    if (this.alarms.lowPressure && !prevLowPressure) {
      this.logEvent('alarm_low_pressure', { compartment: comp.id, pressure: comp.conditions.pressureKPa });
    }
  }

  /**
   * Activate emergency oxygen
   */
  public activateEmergencyOxygen(): boolean {
    if (!this.emergencyOxygen.available) {
      this.logEvent('emergency_o2_failed', { reason: 'not_available' });
      return false;
    }

    this.emergencyOxygen.active = true;
    this.logEvent('emergency_o2_activated', { remaining: this.emergencyOxygen.remainingKg });
    return true;
  }

  /**
   * Deactivate emergency oxygen
   */
  public deactivateEmergencyOxygen(): void {
    this.emergencyOxygen.active = false;
    this.logEvent('emergency_o2_deactivated', {});
  }

  /**
   * Seal compartment
   */
  public sealCompartment(compartmentId: string): boolean {
    const comp = this.compartments.get(compartmentId);
    if (!comp) return false;

    comp.sealed = true;
    this.logEvent('compartment_sealed', { compartmentId });
    return true;
  }

  /**
   * Detect hull breach (called by damage system)
   */
  public detectBreach(leakRate: number): void {
    this.hullIntegrity.breachDetected = true;
    this.hullIntegrity.leakRate = leakRate;
    this.logEvent('hull_breach_detected', { leakRate });
  }

  /**
   * Repair hull breach
   */
  public repairBreach(): void {
    this.hullIntegrity.breachDetected = false;
    this.hullIntegrity.leakRate = 0;
    this.logEvent('hull_breach_repaired', {});
  }

  /**
   * Micrometeorite impact
   */
  public micrometeoriteImpact(severity: number): void {
    this.hullIntegrity.micrometeoriteHits++;

    if (severity > 0.5) {
      // Causes breach
      const leakRate = severity * 10; // kg/hr
      this.detectBreach(leakRate);
    } else {
      // Minor damage to shielding
      this.radiationShielding.effectiveness *= (1 - severity * 0.1);
    }

    this.logEvent('micrometeorite_impact', {
      severity,
      totalHits: this.hullIntegrity.micrometeoriteHits
    });
  }

  /**
   * Set fan speed for air circulation
   */
  public setFanSpeed(speed: number): void {
    this.airCirculation.fanSpeed = Math.max(0, Math.min(1, speed));
    this.logEvent('fan_speed_set', { speed: this.airCirculation.fanSpeed });
  }

  /**
   * Update environmental systems
   */
  public update(dt: number): void {
    if (!this.isPowered) {
      this.operational = false;
      this.currentPowerDraw = 0;
      this.scrubbers.operational = false;
      this.oxygenGenerator.operational = false;
      this.airCirculation.operational = false;
      return;
    }

    if (!this.operational) return;

    // Update atmosphere in all compartments
    this.updateAtmosphere(dt);

    // Power consumption varies with fan speed
    const fanPower = 200 * this.airCirculation.fanSpeed;
    this.currentPowerDraw = this.basePowerDraw + fanPower +
      (this.scrubbers.operational ? 300 : 0) +
      (this.oxygenGenerator.operational ? 300 : 0);
  }

  /**
   * Apply damage
   */
  public applyDamage(severity: number, component?: 'scrubber' | 'o2_gen' | 'circulation'): void {
    if (component === 'scrubber') {
      if (severity > 0.5) {
        this.scrubbers.operational = false;
        this.logEvent('scrubber_damaged', { severity });
      } else {
        this.scrubbers.capacity *= (1 - severity);
      }
    } else if (component === 'o2_gen') {
      if (severity > 0.5) {
        this.oxygenGenerator.operational = false;
        this.logEvent('o2_generator_damaged', { severity });
      } else {
        this.oxygenGenerator.generationRate *= (1 - severity);
      }
    } else if (component === 'circulation') {
      if (severity > 0.5) {
        this.airCirculation.operational = false;
        this.logEvent('circulation_damaged', { severity });
      } else {
        this.airCirculation.filterEfficiency *= (1 - severity);
      }
    } else {
      if (severity > 0.8) {
        this.operational = false;
        this.logEvent('environmental_system_destroyed', { severity });
      }
    }
  }

  /**
   * Repair system
   */
  public repair(component?: 'scrubber' | 'o2_gen' | 'circulation'): void {
    if (component === 'scrubber') {
      this.scrubbers.operational = true;
      this.scrubbers.filterLife = 1.0;
      this.logEvent('scrubber_repaired', {});
    } else if (component === 'o2_gen') {
      this.oxygenGenerator.operational = true;
      this.logEvent('o2_generator_repaired', {});
    } else if (component === 'circulation') {
      this.airCirculation.operational = true;
      this.airCirculation.filterEfficiency = 0.95;
      this.logEvent('circulation_repaired', {});
    } else {
      this.operational = true;
      this.scrubbers.operational = true;
      this.oxygenGenerator.operational = true;
      this.airCirculation.operational = true;
      this.logEvent('environmental_system_repaired', {});
    }
  }

  /**
   * Set power state
   */
  public setPower(powered: boolean): void {
    this.isPowered = powered;
    if (!powered) {
      this.currentPowerDraw = 0;
    }
  }

  public getState() {
    const compartmentsArray: any[] = [];
    this.compartments.forEach((comp, id) => {
      compartmentsArray.push({ ...comp });
    });

    return {
      operational: this.operational,
      isPowered: this.isPowered,
      compartments: compartmentsArray,
      scrubbers: { ...this.scrubbers },
      oxygenGenerator: { ...this.oxygenGenerator },
      emergencyOxygen: { ...this.emergencyOxygen },
      airCirculation: { ...this.airCirculation },
      alarms: { ...this.alarms },
      radiationShielding: { ...this.radiationShielding },
      hullIntegrity: { ...this.hullIntegrity },
      powerDraw: this.currentPowerDraw
    };
  }

  private logEvent(type: string, data: any): void {
    this.events.push({ time: Date.now(), type, data });
  }
}
