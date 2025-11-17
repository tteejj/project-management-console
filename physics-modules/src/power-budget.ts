/**
 * Power Budget System
 *
 * Manages power generation, distribution, brownouts, and battery management
 * Critical for submarine simulator feel - power management affects everything!
 */

export enum PowerSourceType {
  REACTOR = 'reactor',
  SOLAR = 'solar',
  RTG = 'rtg',       // Radioisotope Thermoelectric Generator
  FUEL_CELL = 'fuel_cell'
}

export enum PowerPriority {
  CRITICAL = 0,      // Life support, flight control
  HIGH = 1,          // Sensors, RCS
  MEDIUM = 2,        // Weapons, non-essential systems
  LOW = 3            // Lighting, comfort
}

export interface PowerSource {
  id: string;
  type: PowerSourceType;
  maxOutput: number;          // kW
  currentOutput: number;      // kW (actual output)
  efficiency: number;         // 0-1
  powered: boolean;

  // Solar-specific
  sunExposure?: number;       // 0-1 (1 = full sun, 0 = shadow)
}

export interface PowerConsumer {
  id: string;
  name: string;
  powerDraw: number;          // kW requested
  priority: PowerPriority;
  powered: boolean;
  actualPower: number;        // kW actually received
}

export interface BatteryBank {
  id: string;
  capacity: number;           // kWh
  currentCharge: number;      // kWh
  maxChargeRate: number;      // kW
  maxDischargeRate: number;   // kW
  efficiency: number;         // 0-1
}

export interface PowerBudgetConfig {
  sources: PowerSource[];
  consumers: PowerConsumer[];
  batteries: BatteryBank[];
}

export interface PowerStatistics {
  totalGeneration: number;    // kW
  totalConsumption: number;   // kW
  totalEnergyConsumed: number; // kWh
  totalEnergyGenerated: number; // kWh
  batteryCharge: number;      // kWh total
  batteryCapacity: number;    // kWh total
  brownoutActive: boolean;
  powerDeficit: number;       // kW
}

/**
 * Power Budget System
 */
export class PowerBudgetSystem {
  private sources: Map<string, PowerSource> = new Map();
  private consumers: Map<string, PowerConsumer> = new Map();
  private batteries: Map<string, BatteryBank> = new Map();

  // Statistics
  private totalEnergyConsumed: number = 0;
  private totalEnergyGenerated: number = 0;
  private brownoutActive: boolean = false;
  private powerDeficit: number = 0;

  constructor(config: PowerBudgetConfig) {
    for (const source of config.sources) {
      this.sources.set(source.id, source);
    }
    for (const consumer of config.consumers) {
      this.consumers.set(consumer.id, consumer);
    }
    for (const battery of config.batteries) {
      this.batteries.set(battery.id, battery);
    }
  }

  /**
   * Update power budget system
   */
  update(dt: number): void {
    // PHASE 1: Calculate total available power
    let totalAvailablePower = 0;

    for (const source of this.sources.values()) {
      if (!source.powered) {
        source.currentOutput = 0;
        continue;
      }

      switch (source.type) {
        case PowerSourceType.REACTOR:
          source.currentOutput = source.maxOutput * source.efficiency;
          break;

        case PowerSourceType.SOLAR:
          const sunExposure = source.sunExposure ?? 1.0;
          source.currentOutput = source.maxOutput * source.efficiency * sunExposure;
          break;

        case PowerSourceType.RTG:
          source.currentOutput = source.maxOutput;  // Constant output
          break;

        case PowerSourceType.FUEL_CELL:
          source.currentOutput = source.maxOutput * source.efficiency;
          break;
      }

      totalAvailablePower += source.currentOutput;
    }

    // PHASE 2: Calculate total power demand
    let totalDemand = 0;
    for (const consumer of this.consumers.values()) {
      if (consumer.powered) {
        totalDemand += consumer.powerDraw;
      }
    }

    // PHASE 3: Distribute power by priority
    let remainingPower = totalAvailablePower;
    let totalActualConsumption = 0;

    // Sort consumers by priority
    const sortedConsumers = Array.from(this.consumers.values()).sort((a, b) => {
      return a.priority - b.priority;  // Lower number = higher priority
    });

    for (const consumer of sortedConsumers) {
      if (!consumer.powered) {
        consumer.actualPower = 0;
        continue;
      }

      if (remainingPower >= consumer.powerDraw) {
        // Full power available
        consumer.actualPower = consumer.powerDraw;
        remainingPower -= consumer.powerDraw;
        totalActualConsumption += consumer.powerDraw;
      } else {
        // Partial or no power
        consumer.actualPower = Math.max(0, remainingPower);
        totalActualConsumption += consumer.actualPower;
        remainingPower = 0;
      }
    }

    // PHASE 4: Battery management
    // Check if we have excess power (generation > demand) or deficit (demand > generation)
    const powerBalance = totalAvailablePower - totalDemand;

    if (powerBalance > 0) {
      // Excess power - charge batteries
      this.chargeBatteries(powerBalance, dt);
    } else if (powerBalance < 0) {
      // Power deficit - discharge batteries to meet unmet demand
      const powerNeeded = -powerBalance;
      const powerFromBatteries = this.dischargeBatteries(powerNeeded, dt);

      // Distribute additional power from batteries to consumers who didn't get full power
      if (powerFromBatteries > 0) {
        this.redistributePower(powerFromBatteries, sortedConsumers);
        totalActualConsumption += Math.min(powerFromBatteries, powerNeeded);
      }
    }

    // PHASE 5: Update statistics
    this.totalEnergyGenerated += (totalAvailablePower * dt) / 3600;  // kWh
    this.totalEnergyConsumed += (totalActualConsumption * dt) / 3600;  // kWh

    // Check for brownout
    this.brownoutActive = totalDemand > totalAvailablePower + this.getTotalBatteryDischargeCapacity();
    this.powerDeficit = this.brownoutActive ? totalDemand - totalAvailablePower : 0;
  }

  /**
   * Charge batteries from excess power
   */
  private chargeBatteries(excessPower: number, dt: number): void {
    let remainingExcess = excessPower;

    for (const battery of this.batteries.values()) {
      if (remainingExcess <= 0) break;
      if (battery.currentCharge >= battery.capacity) continue;

      // Limit by charge rate
      const maxChargeNow = Math.min(
        battery.maxChargeRate,
        (battery.capacity - battery.currentCharge) / (dt / 3600)  // Don't overcharge
      );
      const chargeRate = Math.min(remainingExcess, maxChargeNow);

      // Account for efficiency
      const energyAdded = (chargeRate * dt / 3600) * battery.efficiency;
      battery.currentCharge = Math.min(battery.capacity, battery.currentCharge + energyAdded);

      remainingExcess -= chargeRate;
    }
  }

  /**
   * Discharge batteries to meet power deficit
   */
  private dischargeBatteries(powerNeeded: number, dt: number): number {
    let totalDischarged = 0;

    for (const battery of this.batteries.values()) {
      if (powerNeeded <= 0) break;
      if (battery.currentCharge <= 0) continue;

      // Limit by discharge rate
      const maxDischargeNow = Math.min(
        battery.maxDischargeRate,
        battery.currentCharge / (dt / 3600)  // Don't over-discharge
      );
      const dischargeRate = Math.min(powerNeeded, maxDischargeNow);

      // Account for efficiency
      const energyRemoved = dischargeRate * dt / 3600;
      battery.currentCharge = Math.max(0, battery.currentCharge - energyRemoved);

      totalDischarged += dischargeRate;
      powerNeeded -= dischargeRate;
    }

    return totalDischarged;
  }

  /**
   * Redistribute additional power from batteries
   */
  private redistributePower(additionalPower: number, sortedConsumers: PowerConsumer[]): void {
    let remainingPower = additionalPower;

    for (const consumer of sortedConsumers) {
      if (remainingPower <= 0) break;
      if (!consumer.powered) continue;

      const deficit = consumer.powerDraw - consumer.actualPower;
      if (deficit > 0) {
        const additionalForConsumer = Math.min(deficit, remainingPower);
        consumer.actualPower += additionalForConsumer;
        remainingPower -= additionalForConsumer;
      }
    }
  }

  /**
   * Get total battery discharge capacity
   */
  private getTotalBatteryDischargeCapacity(): number {
    let total = 0;
    for (const battery of this.batteries.values()) {
      if (battery.currentCharge > 0) {
        total += battery.maxDischargeRate;
      }
    }
    return total;
  }

  /**
   * Get consumer by ID
   */
  getConsumer(id: string): PowerConsumer | undefined {
    return this.consumers.get(id);
  }

  /**
   * Get source by ID
   */
  getSource(id: string): PowerSource | undefined {
    return this.sources.get(id);
  }

  /**
   * Get battery by ID
   */
  getBattery(id: string): BatteryBank | undefined {
    return this.batteries.get(id);
  }

  /**
   * Get statistics
   */
  getStatistics(): PowerStatistics {
    let totalGeneration = 0;
    for (const source of this.sources.values()) {
      totalGeneration += source.currentOutput;
    }

    let totalConsumption = 0;
    for (const consumer of this.consumers.values()) {
      totalConsumption += consumer.actualPower;
    }

    let batteryCharge = 0;
    let batteryCapacity = 0;
    for (const battery of this.batteries.values()) {
      batteryCharge += battery.currentCharge;
      batteryCapacity += battery.capacity;
    }

    return {
      totalGeneration,
      totalConsumption,
      totalEnergyConsumed: this.totalEnergyConsumed,
      totalEnergyGenerated: this.totalEnergyGenerated,
      batteryCharge,
      batteryCapacity,
      brownoutActive: this.brownoutActive,
      powerDeficit: this.powerDeficit
    };
  }

  /**
   * Add power source
   */
  addSource(source: PowerSource): void {
    this.sources.set(source.id, source);
  }

  /**
   * Add power consumer
   */
  addConsumer(consumer: PowerConsumer): void {
    this.consumers.set(consumer.id, consumer);
  }

  /**
   * Add battery
   */
  addBattery(battery: BatteryBank): void {
    this.batteries.set(battery.id, battery);
  }
}
