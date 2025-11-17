/**
 * Power Management System
 *
 * Manages power distribution across all spacecraft subsystems
 * Features:
 * - Automatic load balancing
 * - Brownout prevention
 * - Priority-based power allocation
 * - EMCON (Emissions Control) modes
 * - Circuit breakers and bus management
 * - Power budget optimization
 */

export interface PowerConsumer {
  id: string;
  name: string;
  priority: number; // 0 (lowest) to 10 (highest)
  basePowerW: number; // Minimum power to function
  currentPowerW: number; // Current power draw
  maxPowerW: number; // Maximum possible draw
  essential: boolean; // Cannot be shut down
  powered: boolean;
  busAssignment: 'A' | 'B' | 'emergency';
}

export interface PowerBus {
  id: string;
  name: string;
  maxCapacityW: number;
  currentLoadW: number;
  voltage: number; // Nominal voltage
  enabled: boolean;
  consumers: string[]; // Consumer IDs on this bus
}

export interface PowerManagementConfig {
  totalGenerationW?: number;
  batteryCapacityKWh?: number;
  emergencyBusCapacityW?: number;
  brownoutThresholdPercent?: number;
  priorityShutdownEnabled?: boolean;
}

export type EMCONLevel = 'unrestricted' | 'reduced' | 'minimal' | 'silent';

export class PowerManagementSystem {
  // Power generation
  public totalGenerationW: number;
  public currentGenerationW: number = 0;

  // Power buses
  public buses: Map<string, PowerBus>;

  // Power consumers (all subsystems)
  public consumers: Map<string, PowerConsumer>;

  // Battery
  public batteryCapacityKWh: number;
  public batteryChargeKWh: number;
  public batteryChargingW: number = 0; // Positive = charging, negative = discharging

  // Emergency systems
  public emergencyBusCapacityW: number;
  public emergencyBusActive: boolean = false;

  // Brownout protection
  public brownoutThresholdPercent: number;
  public priorityShutdownEnabled: boolean;
  public browning: boolean = false;

  // EMCON (Emissions Control)
  public emconLevel: EMCONLevel = 'unrestricted';

  // State
  public operational: boolean = true;
  public totalDemandW: number = 0;
  public powerDeficitW: number = 0;
  public powerSurplusW: number = 0;

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor(config?: PowerManagementConfig) {
    this.totalGenerationW = config?.totalGenerationW || 3000; // 3kW default
    this.batteryCapacityKWh = config?.batteryCapacityKWh || 10; // 10kWh
    this.batteryChargeKWh = this.batteryCapacityKWh * 0.8; // Start at 80%
    this.emergencyBusCapacityW = config?.emergencyBusCapacityW || 500;
    this.brownoutThresholdPercent = config?.brownoutThresholdPercent || 0.95;
    this.priorityShutdownEnabled = config?.priorityShutdownEnabled !== undefined ? config.priorityShutdownEnabled : true;

    this.buses = new Map();
    this.consumers = new Map();

    this.initializeDefaultBuses();
  }

  private initializeDefaultBuses(): void {
    this.buses.set('A', {
      id: 'A',
      name: 'Main Bus A',
      maxCapacityW: this.totalGenerationW * 0.6,
      currentLoadW: 0,
      voltage: 28.0, // DC volts
      enabled: true,
      consumers: []
    });

    this.buses.set('B', {
      id: 'B',
      name: 'Main Bus B',
      maxCapacityW: this.totalGenerationW * 0.6,
      currentLoadW: 0,
      voltage: 28.0,
      enabled: true,
      consumers: []
    });

    this.buses.set('emergency', {
      id: 'emergency',
      name: 'Emergency Bus',
      maxCapacityW: this.emergencyBusCapacityW,
      currentLoadW: 0,
      voltage: 28.0,
      enabled: false,
      consumers: []
    });
  }

  /**
   * Register a power consumer (subsystem)
   */
  public registerConsumer(consumer: PowerConsumer): void {
    this.consumers.set(consumer.id, consumer);

    // Add to assigned bus
    const bus = this.buses.get(consumer.busAssignment);
    if (bus) {
      bus.consumers.push(consumer.id);
    }

    this.logEvent('consumer_registered', { id: consumer.id, name: consumer.name });
  }

  /**
   * Update power consumer's current draw
   */
  public updateConsumerDraw(consumerId: string, powerW: number): void {
    const consumer = this.consumers.get(consumerId);
    if (!consumer) return;

    consumer.currentPowerW = Math.min(powerW, consumer.maxPowerW);
  }

  /**
   * Set reactor/generator output
   */
  public setGenerationOutput(powerW: number): void {
    this.currentGenerationW = Math.min(powerW, this.totalGenerationW);
  }

  /**
   * Set EMCON level (affects what systems can transmit/radiate)
   */
  public setEMCON(level: EMCONLevel): void {
    const prevLevel = this.emconLevel;
    this.emconLevel = level;

    // Automatically adjust system power based on EMCON level
    switch (level) {
      case 'unrestricted':
        // All systems allowed
        break;

      case 'reduced':
        // Reduce non-essential transmissions
        this.powerDownNonEssentialEmitters();
        break;

      case 'minimal':
        // Only passive sensors and internal systems
        this.powerDownAllEmitters();
        break;

      case 'silent':
        // Complete emissions silence - power down all emitting systems
        this.goSilent();
        break;
    }

    this.logEvent('emcon_set', { prev: prevLevel, new: level });
  }

  private powerDownNonEssentialEmitters(): void {
    // Logic to reduce power to comms, active sensors, etc.
    this.consumers.forEach(consumer => {
      if ((consumer.id.includes('comm') || consumer.id.includes('radar')) && !consumer.essential) {
        consumer.powered = false;
      }
    });
  }

  private powerDownAllEmitters(): void {
    this.consumers.forEach(consumer => {
      if ((consumer.id.includes('comm') || consumer.id.includes('radar') ||
           consumer.id.includes('ew') || consumer.id.includes('beacon')) &&
          !consumer.essential) {
        consumer.powered = false;
      }
    });
  }

  private goSilent(): void {
    // Complete silence - only life support and minimal systems
    this.consumers.forEach(consumer => {
      if (!consumer.id.includes('life_support') &&
          !consumer.id.includes('environmental') &&
          !consumer.essential) {
        consumer.powered = false;
      }
    });
  }

  /**
   * Enable/disable circuit breaker for a consumer
   */
  public setCircuitBreaker(consumerId: string, enabled: boolean): boolean {
    const consumer = this.consumers.get(consumerId);
    if (!consumer) return false;

    if (!enabled && consumer.essential) {
      this.logEvent('breaker_blocked', { id: consumerId, reason: 'essential_system' });
      return false;
    }

    consumer.powered = enabled;
    this.logEvent('breaker_toggled', { id: consumerId, enabled });
    return true;
  }

  /**
   * Transfer consumer to different bus
   */
  public transferConsumerBus(consumerId: string, targetBus: 'A' | 'B' | 'emergency'): boolean {
    const consumer = this.consumers.get(consumerId);
    if (!consumer) return false;

    const oldBus = this.buses.get(consumer.busAssignment);
    const newBus = this.buses.get(targetBus);

    if (!oldBus || !newBus) return false;

    // Remove from old bus
    oldBus.consumers = oldBus.consumers.filter(id => id !== consumerId);

    // Add to new bus
    newBus.consumers.push(consumerId);
    consumer.busAssignment = targetBus;

    this.logEvent('bus_transfer', { consumer: consumerId, from: oldBus.id, to: newBus.id });
    return true;
  }

  /**
   * Enable emergency bus (battery-only, limited systems)
   */
  public activateEmergencyBus(): void {
    this.emergencyBusActive = true;
    const emergencyBus = this.buses.get('emergency');
    if (emergencyBus) {
      emergencyBus.enabled = true;
    }

    // Automatically shed non-essential loads
    this.shedNonEssentialLoads();

    this.logEvent('emergency_bus_activated', {});
  }

  /**
   * Deactivate emergency bus
   */
  public deactivateEmergencyBus(): void {
    this.emergencyBusActive = false;
    const emergencyBus = this.buses.get('emergency');
    if (emergencyBus) {
      emergencyBus.enabled = false;
    }

    this.logEvent('emergency_bus_deactivated', {});
  }

  /**
   * Shed non-essential loads (brownout prevention)
   */
  private shedNonEssentialLoads(): void {
    // Get sorted list of consumers by priority (lowest first)
    const sortedConsumers = Array.from(this.consumers.values())
      .filter(c => !c.essential)
      .sort((a, b) => a.priority - b.priority);

    let shedPower = 0;
    const shedList: string[] = [];

    for (const consumer of sortedConsumers) {
      if (this.totalDemandW - shedPower <= this.currentGenerationW) {
        break; // Enough load shed
      }

      consumer.powered = false;
      shedPower += consumer.currentPowerW;
      shedList.push(consumer.id);
    }

    this.logEvent('load_shed', { shedCount: shedList.length, shedPowerW: shedPower, systems: shedList });
  }

  /**
   * Update power distribution (called each frame)
   */
  public update(dt: number, reactorOutputW: number, batteryChargeKWh: number): void {
    if (!this.operational) return;

    // Update generation
    this.currentGenerationW = reactorOutputW;
    this.batteryChargeKWh = batteryChargeKWh;

    // Calculate total demand
    this.totalDemandW = 0;
    this.buses.forEach(bus => {
      bus.currentLoadW = 0;
    });

    // Sum up all powered consumers
    this.consumers.forEach(consumer => {
      if (consumer.powered) {
        this.totalDemandW += consumer.currentPowerW;

        const bus = this.buses.get(consumer.busAssignment);
        if (bus && bus.enabled) {
          bus.currentLoadW += consumer.currentPowerW;
        }
      }
    });

    // Calculate surplus/deficit
    const totalAvailable = this.currentGenerationW;
    this.powerDeficitW = Math.max(0, this.totalDemandW - totalAvailable);
    this.powerSurplusW = Math.max(0, totalAvailable - this.totalDemandW);

    // Battery management
    if (this.powerDeficitW > 0) {
      // Discharging battery
      this.batteryChargingW = -this.powerDeficitW;
      const dischargeKWh = (this.powerDeficitW / 1000) * (dt / 3600);
      this.batteryChargeKWh = Math.max(0, this.batteryChargeKWh - dischargeKWh);

      // Check for battery depletion
      if (this.batteryChargeKWh < 0.1) {
        this.handleBatteryDepletion();
      }
    } else if (this.powerSurplusW > 0) {
      // Charging battery
      const maxChargeRate = 1000; // 1kW max charge rate
      this.batteryChargingW = Math.min(this.powerSurplusW, maxChargeRate);
      const chargeKWh = (this.batteryChargingW / 1000) * (dt / 3600);
      this.batteryChargeKWh = Math.min(this.batteryCapacityKWh, this.batteryChargeKWh + chargeKWh);
    } else {
      this.batteryChargingW = 0;
    }

    // Check for brownout condition
    const loadPercent = this.totalDemandW / totalAvailable;
    if (loadPercent > this.brownoutThresholdPercent && !this.browning) {
      this.handleBrownout();
    } else if (loadPercent < this.brownoutThresholdPercent * 0.9 && this.browning) {
      this.browning = false;
      this.logEvent('brownout_cleared', {});
    }

    // Check bus overloads
    this.buses.forEach(bus => {
      if (bus.enabled && bus.currentLoadW > bus.maxCapacityW) {
        this.logEvent('bus_overload', {
          bus: bus.id,
          load: bus.currentLoadW,
          capacity: bus.maxCapacityW
        });
      }
    });
  }

  private handleBrownout(): void {
    this.browning = true;
    this.logEvent('brownout_warning', {
      demand: this.totalDemandW,
      available: this.currentGenerationW
    });

    if (this.priorityShutdownEnabled) {
      this.shedNonEssentialLoads();
    }
  }

  private handleBatteryDepletion(): void {
    this.logEvent('battery_depleted', {});

    // Emergency bus activation
    if (!this.emergencyBusActive) {
      this.activateEmergencyBus();
    }

    // Force load shedding
    this.shedNonEssentialLoads();
  }

  /**
   * Get power budget report
   */
  public getPowerBudget(): {
    generation: number;
    demand: number;
    surplus: number;
    deficit: number;
    batteryCharge: number;
    batteryPercent: number;
    loadPercent: number;
    browning: boolean;
    emconLevel: EMCONLevel;
  } {
    return {
      generation: this.currentGenerationW,
      demand: this.totalDemandW,
      surplus: this.powerSurplusW,
      deficit: this.powerDeficitW,
      batteryCharge: this.batteryChargeKWh,
      batteryPercent: (this.batteryChargeKWh / this.batteryCapacityKWh) * 100,
      loadPercent: (this.totalDemandW / this.currentGenerationW) * 100,
      browning: this.browning,
      emconLevel: this.emconLevel
    };
  }

  /**
   * Get detailed bus status
   */
  public getBusStatus(busId: string): {
    id: string;
    load: number;
    capacity: number;
    percent: number;
    enabled: boolean;
    consumerCount: number;
  } | null {
    const bus = this.buses.get(busId);
    if (!bus) return null;

    return {
      id: bus.id,
      load: bus.currentLoadW,
      capacity: bus.maxCapacityW,
      percent: (bus.currentLoadW / bus.maxCapacityW) * 100,
      enabled: bus.enabled,
      consumerCount: bus.consumers.length
    };
  }

  public getState() {
    const busesArray: any[] = [];
    this.buses.forEach((bus) => {
      busesArray.push({ ...bus });
    });

    const consumersArray: any[] = [];
    this.consumers.forEach((consumer, id) => {
      consumersArray.push({ ...consumer });
    });

    return {
      operational: this.operational,
      generation: this.currentGenerationW,
      totalDemand: this.totalDemandW,
      surplus: this.powerSurplusW,
      deficit: this.powerDeficitW,
      batteryCharge: this.batteryChargeKWh,
      batteryCapacity: this.batteryCapacityKWh,
      batteryPercent: (this.batteryChargeKWh / this.batteryCapacityKWh) * 100,
      batteryChargingW: this.batteryChargingW,
      browning: this.browning,
      emergencyBusActive: this.emergencyBusActive,
      emconLevel: this.emconLevel,
      buses: busesArray,
      consumers: consumersArray,
      powerBudget: this.getPowerBudget()
    };
  }

  private logEvent(type: string, data: any): void {
    this.events.push({ time: Date.now(), type, data });
  }
}
