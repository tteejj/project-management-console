/**
 * Electrical System Physics Module
 *
 * Simulates:
 * - Reactor power generation (RTG or small fission)
 * - Battery charge/discharge with thermal effects
 * - Capacitor bank for high-draw surges
 * - Dual power buses (A and B) for redundancy
 * - Circuit breakers with overcurrent protection
 * - Power cross-tie capability
 * - Blackout recovery
 * - Heat generation from inefficiency
 */

export interface Reactor {
  fuelRemaining: number; // %
  fuelDegradationRate: number; // % per second at 100% throttle

  throttle: number; // 0-1
  maxOutputKW: number;
  currentOutputKW: number;

  temperature: number; // K
  maxSafeTemp: number;
  scramTemp: number; // auto-shutdown temperature

  status: 'offline' | 'starting' | 'online' | 'scrammed';
  startupTime: number; // seconds
  startupTimer: number; // current startup progress

  thermalEfficiency: number; // electrical output / total energy (rest is waste heat)
  heatGenerationW: number; // current waste heat generation
}

export interface Battery {
  chargeKWh: number;
  capacityKWh: number;
  maxChargeRateKW: number;
  maxDischargeRateKW: number;
  temperature: number; // K
  health: number; // 0-100, degrades over charge cycles
  chargeCycles: number;
}

export interface CapacitorBank {
  chargeKJ: number;
  capacityKJ: number;
  chargeRateKW: number;
  dischargeRateKW: number;
}

export interface PowerBus {
  name: 'A' | 'B';
  voltage: number; // volts
  maxCapacityKW: number;
  currentLoadKW: number;
  faults: number;
  connected: boolean;
  crosstieEnabled: boolean;
}

export interface CircuitBreaker {
  name: string;
  bus: 'A' | 'B';
  on: boolean;
  loadW: number; // rated load in watts
  essential: boolean; // cannot be manually tripped
  tripThreshold: number; // amps - overcurrent protection
  tripped: boolean; // has it tripped due to overcurrent?
}

interface ElectricalSystemConfig {
  reactor?: Partial<Reactor>;
  battery?: Partial<Battery>;
  capacitorBank?: Partial<CapacitorBank>;
  buses?: PowerBus[];
  breakers?: Map<string, CircuitBreaker>;
}

export class ElectricalSystem {
  public reactor: Reactor;
  public battery: Battery;
  public capacitorBank: CapacitorBank;
  public buses: PowerBus[];
  public breakers: Map<string, CircuitBreaker>;

  // Tracking for analysis
  public totalPowerGenerated: number = 0; // kWh
  public totalPowerConsumed: number = 0; // kWh
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor(config?: ElectricalSystemConfig) {
    // Default reactor configuration
    this.reactor = {
      fuelRemaining: 100,
      fuelDegradationRate: 0.001,
      throttle: 0,
      maxOutputKW: 8.0,
      currentOutputKW: 0,
      temperature: 400,
      maxSafeTemp: 800,
      scramTemp: 900,
      status: 'offline',
      startupTime: 30,
      startupTimer: 0,
      thermalEfficiency: 0.33,
      heatGenerationW: 0,
      ...config?.reactor
    };

    // Default battery configuration
    this.battery = {
      chargeKWh: 8.0,
      capacityKWh: 12.0,
      maxChargeRateKW: 2.0,
      maxDischargeRateKW: 3.5,
      temperature: 293,
      health: 100,
      chargeCycles: 0,
      ...config?.battery
    };

    // Default capacitor bank
    this.capacitorBank = {
      chargeKJ: 50,
      capacityKJ: 100,
      chargeRateKW: 10,
      dischargeRateKW: 50,
      ...config?.capacitorBank
    };

    // Default power buses
    this.buses = config?.buses || [
      { name: 'A', voltage: 28, maxCapacityKW: 4.5, currentLoadKW: 0, faults: 0, connected: true, crosstieEnabled: false },
      { name: 'B', voltage: 28, maxCapacityKW: 4.5, currentLoadKW: 0, faults: 0, connected: true, crosstieEnabled: false }
    ];

    // Default circuit breakers
    this.breakers = config?.breakers || this.createDefaultBreakers();
  }

  private createDefaultBreakers(): Map<string, CircuitBreaker> {
    return new Map([
      // Life Support (essential)
      ['o2_generator', { name: 'O2 Gen', bus: 'A', on: true, loadW: 800, essential: true, tripThreshold: 30, tripped: false }],
      ['co2_scrubber', { name: 'CO2 Scrub', bus: 'A', on: true, loadW: 600, essential: true, tripThreshold: 25, tripped: false }],

      // Cooling
      ['coolant_pump_primary', { name: 'Coolant 1', bus: 'A', on: true, loadW: 400, essential: true, tripThreshold: 20, tripped: false }],
      ['coolant_pump_backup', { name: 'Coolant 2', bus: 'B', on: false, loadW: 400, essential: false, tripThreshold: 20, tripped: false }],

      // Propulsion
      ['fuel_pump_main', { name: 'Fuel Pump', bus: 'A', on: true, loadW: 300, essential: false, tripThreshold: 15, tripped: false }],
      ['gimbal_actuators', { name: 'Gimbal Act', bus: 'A', on: true, loadW: 200, essential: false, tripThreshold: 10, tripped: false }],
      ['rcs_valves', { name: 'RCS Valves', bus: 'B', on: true, loadW: 150, essential: false, tripThreshold: 8, tripped: false }],

      // Navigation & Sensors
      ['nav_computer', { name: 'Nav Comp', bus: 'B', on: true, loadW: 250, essential: false, tripThreshold: 12, tripped: false }],
      ['radar', { name: 'Radar', bus: 'B', on: true, loadW: 350, essential: false, tripThreshold: 15, tripped: false }],
      ['lidar', { name: 'LIDAR', bus: 'B', on: false, loadW: 200, essential: false, tripThreshold: 10, tripped: false }],

      // Hydraulics
      ['hydraulic_pump_1', { name: 'Hydraulic 1', bus: 'A', on: true, loadW: 500, essential: false, tripThreshold: 20, tripped: false }],
      ['hydraulic_pump_2', { name: 'Hydraulic 2', bus: 'B', on: false, loadW: 500, essential: false, tripThreshold: 20, tripped: false }],

      // Environmental
      ['heater_1', { name: 'Heat C1', bus: 'A', on: true, loadW: 300, essential: false, tripThreshold: 12, tripped: false }],
      ['heater_2', { name: 'Heat C2', bus: 'A', on: true, loadW: 300, essential: false, tripThreshold: 12, tripped: false }],
      ['heater_3', { name: 'Heat C3', bus: 'B', on: true, loadW: 300, essential: false, tripThreshold: 12, tripped: false }],
      ['lighting', { name: 'Lights', bus: 'B', on: true, loadW: 150, essential: false, tripThreshold: 8, tripped: false }],

      // Mechanisms
      ['door_actuators', { name: 'Doors', bus: 'A', on: true, loadW: 100, essential: false, tripThreshold: 5, tripped: false }],
      ['valve_actuators', { name: 'Valves', bus: 'B', on: true, loadW: 80, essential: false, tripThreshold: 4, tripped: false }],

      // Communications
      ['comms', { name: 'Comms', bus: 'B', on: true, loadW: 120, essential: false, tripThreshold: 6, tripped: false }],
    ]);
  }

  /**
   * Main update loop
   */
  update(dt: number, simulationTime: number): void {
    // 1. Update reactor
    this.updateReactor(dt, simulationTime);

    // 2. Calculate bus loads
    this.calculateBusLoads();

    // 3. Check for overcurrent and trip breakers
    this.checkOvercurrent();

    // 4. Handle power cross-tie if enabled
    this.handleCrosstie();

    // 5. Power balance and battery/capacitor management
    this.managePowerBalance(dt, simulationTime);

    // 6. Update battery temperature
    this.updateBatteryThermal(dt);

    // 7. Check for warnings
    this.checkWarnings(simulationTime);

    // 8. Track statistics
    this.updateStatistics(dt);
  }

  /**
   * Update reactor state
   */
  private updateReactor(dt: number, time: number): void {
    if (this.reactor.status === 'starting') {
      this.reactor.startupTimer += dt;

      if (this.reactor.startupTimer >= this.reactor.startupTime) {
        this.reactor.status = 'online';
        this.logEvent(time, 'reactor_online', {});
      }
    }

    if (this.reactor.status === 'online') {
      // Generate power
      this.reactor.currentOutputKW = this.reactor.maxOutputKW * this.reactor.throttle;

      // Consume fuel (degradation)
      this.reactor.fuelRemaining -= this.reactor.fuelDegradationRate * this.reactor.throttle * dt;

      if (this.reactor.fuelRemaining <= 0) {
        this.reactor.fuelRemaining = 0;
        this.reactor.status = 'offline';
        this.logEvent(time, 'reactor_fuel_depleted', {});
      }

      // Heat generation (waste heat from inefficiency)
      const totalEnergyKW = this.reactor.currentOutputKW / this.reactor.thermalEfficiency;
      this.reactor.heatGenerationW = (totalEnergyKW - this.reactor.currentOutputKW) * 1000;

      // Temperature increase from waste heat (simplified - assumes no cooling)
      // In real integration, this would be handled by coolant system
      // For standalone testing, just track it

      // Auto SCRAM if overtemp
      if (this.reactor.temperature >= this.reactor.scramTemp) {
        this.SCRAM(time);
        return; // Exit immediately after SCRAM
      }
    } else {
      this.reactor.currentOutputKW = 0;
      this.reactor.heatGenerationW = 0;
    }
  }

  /**
   * Calculate current load on each bus
   */
  private calculateBusLoads(): void {
    this.buses[0].currentLoadKW = 0;
    this.buses[1].currentLoadKW = 0;

    for (const [key, breaker] of this.breakers) {
      if (breaker.on && !breaker.tripped) {
        const busIndex = breaker.bus === 'A' ? 0 : 1;
        this.buses[busIndex].currentLoadKW += breaker.loadW / 1000;
      }
    }
  }

  /**
   * Check for overcurrent and trip breakers
   */
  private checkOvercurrent(): void {
    for (const [key, breaker] of this.breakers) {
      if (breaker.on && !breaker.tripped) {
        const busIndex = breaker.bus === 'A' ? 0 : 1;
        const bus = this.buses[busIndex];

        // Calculate current draw
        const current = breaker.loadW / bus.voltage;

        if (current > breaker.tripThreshold) {
          breaker.tripped = true;
          breaker.on = false;
          this.logEvent(0, 'breaker_tripped', { breaker: key, current });
        }
      }
    }
  }

  /**
   * Handle power cross-tie between buses
   */
  private handleCrosstie(): void {
    if (this.buses[0].crosstieEnabled && this.buses[1].crosstieEnabled) {
      // Balance load across both buses
      const totalLoad = this.buses[0].currentLoadKW + this.buses[1].currentLoadKW;
      const avgLoad = totalLoad / 2;

      this.buses[0].currentLoadKW = avgLoad;
      this.buses[1].currentLoadKW = avgLoad;
    }
  }

  /**
   * Manage power balance between generation and consumption
   */
  private managePowerBalance(dt: number, time: number): void {
    const totalLoadKW = this.buses[0].currentLoadKW + this.buses[1].currentLoadKW;
    const reactorOutputKW = this.reactor.currentOutputKW;
    const netPowerKW = reactorOutputKW - totalLoadKW;

    if (netPowerKW < 0) {
      // Power deficit - drain capacitors then battery
      const deficitKW = -netPowerKW;

      // Try capacitors first (fast discharge for transients)
      const desiredCapacitorDischargeKW = Math.min(deficitKW, this.capacitorBank.dischargeRateKW);
      const desiredCapacitorDischargeKJ = desiredCapacitorDischargeKW * dt;

      // Cap by available charge
      const actualCapacitorDischargeKJ = Math.min(desiredCapacitorDischargeKJ, this.capacitorBank.chargeKJ);
      this.capacitorBank.chargeKJ -= actualCapacitorDischargeKJ;
      const actualCapacitorDischargeKW = actualCapacitorDischargeKJ / dt;

      // Remaining deficit from battery
      const remainingDeficitKW = deficitKW - actualCapacitorDischargeKW;
      const batteryDischargeKW = Math.min(remainingDeficitKW, this.battery.maxDischargeRateKW);
      const batteryDischargeKWh = batteryDischargeKW * (dt / 3600);

      this.battery.chargeKWh -= batteryDischargeKWh;

      // Battery heat from discharge (inefficiency)
      const dischargeHeatW = batteryDischargeKW * 100; // ~10% inefficiency
      this.battery.temperature += (dischargeHeatW * dt) / (10 * 800); // 10kg battery, 800 J/(kg·K)

      // Track discharge cycles
      if (batteryDischargeKW > 0) {
        this.battery.chargeCycles += (batteryDischargeKWh / this.battery.capacityKWh) * 0.5; // half cycle
      }

      if (this.battery.chargeKWh <= 0) {
        this.battery.chargeKWh = 0;
        this.blackout(time);
      }
    } else {
      // Power surplus - charge capacitors then battery
      const surplusKW = netPowerKW;

      // Charge capacitors first (fast charge)
      const desiredCapacitorChargeKW = Math.min(surplusKW, this.capacitorBank.chargeRateKW);
      const desiredCapacitorChargeKJ = desiredCapacitorChargeKW * dt;

      // Cap by available capacity
      const availableCapacityKJ = this.capacitorBank.capacityKJ - this.capacitorBank.chargeKJ;
      const actualCapacitorChargeKJ = Math.min(desiredCapacitorChargeKJ, availableCapacityKJ);
      this.capacitorBank.chargeKJ += actualCapacitorChargeKJ;
      const actualCapacitorChargeKW = actualCapacitorChargeKJ / dt;

      // Remaining surplus to battery
      const remainingSurplusKW = surplusKW - actualCapacitorChargeKW;
      const batteryChargeKW = Math.min(remainingSurplusKW, this.battery.maxChargeRateKW);
      const batteryChargeKWh = batteryChargeKW * (dt / 3600);

      this.battery.chargeKWh = Math.min(
        this.battery.capacityKWh,
        this.battery.chargeKWh + batteryChargeKWh
      );

      // Battery heat from charging
      const chargeHeatW = batteryChargeKW * 50; // ~5% inefficiency
      this.battery.temperature += (chargeHeatW * dt) / (10 * 800);

      // Track charge cycles
      if (batteryChargeKW > 0) {
        this.battery.chargeCycles += (batteryChargeKWh / this.battery.capacityKWh) * 0.5;
      }
    }

    // Battery health degrades with charge cycles
    if (this.battery.chargeCycles > 500) {
      this.battery.health = Math.max(0, 100 - ((this.battery.chargeCycles - 500) / 10));
    }
  }

  /**
   * Update battery thermal state
   */
  private updateBatteryThermal(dt: number): void {
    // Passive cooling to ambient (simplified)
    const ambientTemp = 293;
    const tempDiff = this.battery.temperature - ambientTemp;
    const coolingRate = 0.01; // thermal time constant

    this.battery.temperature -= tempDiff * coolingRate * dt;
  }

  /**
   * Check for warning conditions
   */
  private checkWarnings(time: number): void {
    // Low battery
    if (this.battery.chargeKWh < this.battery.capacityKWh * 0.2) {
      this.logEvent(time, 'battery_low', { chargePercent: (this.battery.chargeKWh / this.battery.capacityKWh) * 100 });
    }

    // Reactor overheating
    if (this.reactor.status === 'online' && this.reactor.temperature > this.reactor.maxSafeTemp) {
      this.logEvent(time, 'reactor_overtemp', { temperature: this.reactor.temperature });
    }

    // Battery overheating
    if (this.battery.temperature > 320) {
      this.logEvent(time, 'battery_overtemp', { temperature: this.battery.temperature });
    }

    // Bus overload
    for (const bus of this.buses) {
      if (bus.currentLoadKW > bus.maxCapacityKW) {
        this.logEvent(time, 'bus_overload', { bus: bus.name, load: bus.currentLoadKW, capacity: bus.maxCapacityKW });
      }
    }
  }

  /**
   * Update statistics tracking
   */
  private updateStatistics(dt: number): void {
    this.totalPowerGenerated += this.reactor.currentOutputKW * (dt / 3600);
    const totalLoad = this.buses[0].currentLoadKW + this.buses[1].currentLoadKW;
    this.totalPowerConsumed += totalLoad * (dt / 3600);
  }

  /**
   * Start reactor
   */
  startReactor(): boolean {
    if (this.reactor.status === 'offline' && this.reactor.fuelRemaining > 0) {
      this.reactor.status = 'starting';
      this.reactor.startupTimer = 0;
      return true;
    }
    return false;
  }

  /**
   * Emergency reactor shutdown (SCRAM)
   */
  SCRAM(time: number): void {
    this.reactor.status = 'scrammed';
    this.reactor.throttle = 0;
    this.reactor.currentOutputKW = 0;
    this.logEvent(time, 'reactor_scram', { temperature: this.reactor.temperature });
  }

  /**
   * Reset reactor from SCRAM (requires manual intervention)
   */
  resetReactor(): boolean {
    if (this.reactor.status === 'scrammed' && this.reactor.temperature < this.reactor.maxSafeTemp) {
      this.reactor.status = 'offline';
      return true;
    }
    return false;
  }

  /**
   * Set reactor throttle
   */
  setReactorThrottle(throttle: number): void {
    this.reactor.throttle = Math.max(0, Math.min(1, throttle));
  }

  /**
   * Toggle circuit breaker
   */
  toggleBreaker(key: string, on: boolean): boolean {
    const breaker = this.breakers.get(key);
    if (!breaker) return false;

    // Cannot manually turn off essential breakers
    if (!on && breaker.essential) return false;

    // Reset tripped state when turning on
    if (on && breaker.tripped) {
      breaker.tripped = false;
    }

    breaker.on = on;
    return true;
  }

  /**
   * Enable/disable bus crosstie
   */
  setCrosstie(enable: boolean): void {
    this.buses[0].crosstieEnabled = enable;
    this.buses[1].crosstieEnabled = enable;
  }

  /**
   * Blackout - trip all non-essential breakers
   */
  private blackout(time: number): void {
    for (const [key, breaker] of this.breakers) {
      if (!breaker.essential) {
        breaker.on = false;
      }
    }
    this.logEvent(time, 'blackout', {});
  }

  /**
   * Get current state for debugging/testing
   */
  getState() {
    return {
      reactor: {
        status: this.reactor.status,
        outputKW: this.reactor.currentOutputKW,
        throttle: this.reactor.throttle,
        fuelRemaining: this.reactor.fuelRemaining,
        temperature: this.reactor.temperature,
        heatGenerationW: this.reactor.heatGenerationW
      },
      battery: {
        chargeKWh: this.battery.chargeKWh,
        chargePercent: (this.battery.chargeKWh / this.battery.capacityKWh) * 100,
        temperature: this.battery.temperature,
        health: this.battery.health,
        chargeCycles: this.battery.chargeCycles
      },
      capacitor: {
        chargeKJ: this.capacitorBank.chargeKJ,
        chargePercent: (this.capacitorBank.chargeKJ / this.capacitorBank.capacityKJ) * 100
      },
      buses: this.buses.map(bus => ({
        name: bus.name,
        loadKW: bus.currentLoadKW,
        capacityKW: bus.maxCapacityKW,
        loadPercent: (bus.currentLoadKW / bus.maxCapacityKW) * 100,
        crosstieEnabled: bus.crosstieEnabled
      })),
      totalLoad: this.buses[0].currentLoadKW + this.buses[1].currentLoadKW,
      netPower: this.reactor.currentOutputKW - (this.buses[0].currentLoadKW + this.buses[1].currentLoadKW),
      breakerStatus: Array.from(this.breakers.entries()).map(([key, breaker]) => ({
        key,
        name: breaker.name,
        on: breaker.on,
        tripped: breaker.tripped,
        bus: breaker.bus
      }))
    };
  }

  /**
   * Log an event
   */
  private logEvent(time: number, type: string, data: any): void {
    // Only log each event type once per second to avoid spam
    const recentEvent = this.events.find(
      e => e.type === type && time - e.time < 1.0
    );

    if (!recentEvent) {
      this.events.push({ time, type, data });
    }
  }

  /**
   * Get all events
   */
  getEvents() {
    return this.events;
  }

  /**
   * Clear events
   */
  clearEvents(): void {
    this.events = [];
  }
}
