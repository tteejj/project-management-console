/**
 * Coolant System Physics Module
 *
 * Simulates:
 * - Dual redundant coolant loops with fluid dynamics
 * - Heat absorption from thermal system components
 * - Radiator panels with Stefan-Boltzmann radiation
 * - Coolant temperature and flow rate tracking
 * - Pump operation and power consumption
 * - Loop isolation and cross-connect for redundancy
 * - Coolant loss from leaks
 * - Freezing and boiling conditions
 */

export interface CoolantLoop {
  id: number;
  name: string;
  coolantMassKg: number;          // Current coolant mass
  maxCapacityKg: number;          // Maximum coolant capacity
  temperature: number;            // K (average loop temperature)
  flowRateLPerMin: number;        // Current flow rate
  maxFlowRateLPerMin: number;     // Maximum flow rate
  pumpActive: boolean;
  pumpPowerW: number;             // Power consumption when active

  // Components cooled by this loop
  cooledComponents: string[];     // Component names from thermal system

  // Radiator panel
  radiatorAreaM2: number;         // Surface area for heat radiation
  radiatorTemperature: number;    // K (can differ from coolant temp)

  // Health
  leakRateLPerMin: number;        // 0 = no leak
  frozen: boolean;
  boiling: boolean;
}

export interface CoolantSystemConfig {
  loops?: CoolantLoop[];
  coolantSpecificHeat?: number;   // J/(kg·K)
  freezingPoint?: number;         // K
  boilingPoint?: number;          // K
  crossConnectOpen?: boolean;
}

export class CoolantSystem {
  public loops: CoolantLoop[];
  public coolantSpecificHeat: number;  // J/(kg·K) - typically water-glycol mix
  public freezingPoint: number;         // K
  public boilingPoint: number;          // K
  public crossConnectOpen: boolean;     // Allows coolant sharing between loops

  // Tracking
  public totalHeatRejected: number = 0;  // J (total heat radiated to space)
  public events: Array<{ time: number; type: string; data: any }> = [];

  // Constants
  private readonly STEFAN_BOLTZMANN = 5.67e-8;  // W/(m²·K⁴)
  private readonly COOLANT_DENSITY = 1050;      // kg/m³ (water-glycol)

  constructor(config?: CoolantSystemConfig) {
    this.loops = config?.loops || this.createDefaultLoops();
    this.coolantSpecificHeat = config?.coolantSpecificHeat || 3800; // J/(kg·K)
    this.freezingPoint = config?.freezingPoint || 253; // K (-20°C with antifreeze)
    this.boilingPoint = config?.boilingPoint || 393;   // K (120°C pressurized)
    this.crossConnectOpen = config?.crossConnectOpen || false;
  }

  private createDefaultLoops(): CoolantLoop[] {
    return [
      {
        id: 0,
        name: 'Primary Loop',
        coolantMassKg: 30,
        maxCapacityKg: 30,
        temperature: 293,
        flowRateLPerMin: 0,
        maxFlowRateLPerMin: 50,
        pumpActive: false,
        pumpPowerW: 400,
        cooledComponents: ['reactor', 'main_engine'],
        radiatorAreaM2: 8.0,
        radiatorTemperature: 293,
        leakRateLPerMin: 0,
        frozen: false,
        boiling: false
      },
      {
        id: 1,
        name: 'Secondary Loop',
        coolantMassKg: 20,
        maxCapacityKg: 20,
        temperature: 293,
        flowRateLPerMin: 0,
        maxFlowRateLPerMin: 30,
        pumpActive: false,
        pumpPowerW: 250,
        cooledComponents: ['battery', 'hydraulic_pump_1', 'hydraulic_pump_2'],
        radiatorAreaM2: 5.0,
        radiatorTemperature: 293,
        leakRateLPerMin: 0,
        frozen: false,
        boiling: false
      }
    ];
  }

  /**
   * Main update loop
   */
  update(dt: number, simulationTime: number, componentTemperatures?: Map<string, number>): void {
    // 1. Update pump operation and flow rates
    this.updatePumps(dt);

    // 2. Absorb heat from components (if thermal system data provided)
    if (componentTemperatures) {
      this.absorbHeatFromComponents(dt, componentTemperatures);
    }

    // 3. Reject heat via radiators (Stefan-Boltzmann)
    this.radiateHeatToSpace(dt);

    // 4. Handle coolant loss from leaks
    this.handleLeaks(dt);

    // 5. Check for freezing/boiling
    this.checkPhaseChanges(simulationTime);

    // 6. Handle cross-connect if open
    if (this.crossConnectOpen) {
      this.balanceLoops(dt);
    }

    // 7. Check for warnings
    this.checkWarnings(simulationTime);
  }

  /**
   * Update pump states and flow rates
   */
  private updatePumps(dt: number): void {
    for (const loop of this.loops) {
      if (loop.pumpActive && !loop.frozen && loop.coolantMassKg > 0) {
        // Flow rate proportional to coolant mass (less mass = less flow)
        const fillFraction = loop.coolantMassKg / loop.maxCapacityKg;
        loop.flowRateLPerMin = loop.maxFlowRateLPerMin * fillFraction;
      } else {
        loop.flowRateLPerMin = 0;
      }
    }
  }

  /**
   * Absorb heat from components being cooled
   */
  private absorbHeatFromComponents(dt: number, componentTemperatures: Map<string, number>): void {
    for (const loop of this.loops) {
      if (loop.flowRateLPerMin === 0 || loop.coolantMassKg === 0) continue;

      let totalHeatAbsorbedW = 0;

      for (const componentName of loop.cooledComponents) {
        const componentTemp = componentTemperatures.get(componentName);
        if (componentTemp === undefined) continue;

        // Heat transfer proportional to temperature difference and flow rate
        const tempDiff = componentTemp - loop.temperature;

        // Heat transfer coefficient (higher flow = better heat transfer)
        const flowFactor = loop.flowRateLPerMin / loop.maxFlowRateLPerMin;
        const heatTransferCoeff = 1000 * flowFactor; // W/K at full flow

        const heatAbsorbedW = tempDiff * heatTransferCoeff;
        totalHeatAbsorbedW += Math.max(0, heatAbsorbedW); // Only absorb heat, don't reject
      }

      // Coolant temperature rises from absorbed heat
      // Q = m * c * ΔT
      const tempRise = (totalHeatAbsorbedW * dt) / (loop.coolantMassKg * this.coolantSpecificHeat);
      loop.temperature += tempRise;
    }
  }

  /**
   * Radiate heat to space via radiator panels
   * Uses Stefan-Boltzmann law: P = ε * σ * A * T⁴
   */
  private radiateHeatToSpace(dt: number): void {
    const spaceTemp = 2.7; // K (cosmic background)
    const emissivity = 0.9; // High for black radiator panels

    for (const loop of this.loops) {
      if (loop.coolantMassKg === 0) continue;

      // Radiator temperature tracks coolant temperature (with slight lag)
      const tempDiff = loop.temperature - loop.radiatorTemperature;
      loop.radiatorTemperature += tempDiff * 0.5 * dt; // Thermal lag

      // Stefan-Boltzmann radiation
      const T_rad = loop.radiatorTemperature;
      const T_space = spaceTemp;

      // Net radiation power (radiator emits, space background negligible)
      const powerRadiatedW = emissivity * this.STEFAN_BOLTZMANN * loop.radiatorAreaM2 *
                            (Math.pow(T_rad, 4) - Math.pow(T_space, 4));

      // Coolant cools from heat radiation
      const tempDrop = (powerRadiatedW * dt) / (loop.coolantMassKg * this.coolantSpecificHeat);
      loop.temperature -= tempDrop;

      // Track total heat rejected
      this.totalHeatRejected += powerRadiatedW * dt;
    }
  }

  /**
   * Handle coolant loss from leaks
   */
  private handleLeaks(dt: number): void {
    for (const loop of this.loops) {
      if (loop.leakRateLPerMin > 0) {
        const leakRateKgPerSec = (loop.leakRateLPerMin / 60) * this.COOLANT_DENSITY / 1000;
        const lossKg = leakRateKgPerSec * dt;

        loop.coolantMassKg = Math.max(0, loop.coolantMassKg - lossKg);
      }
    }
  }

  /**
   * Check for freezing or boiling
   */
  private checkPhaseChanges(time: number): void {
    for (const loop of this.loops) {
      // Freezing
      if (loop.temperature < this.freezingPoint && !loop.frozen) {
        loop.frozen = true;
        loop.pumpActive = false; // Pump stops when frozen
        this.logEvent(time, 'coolant_frozen', {
          loopId: loop.id,
          name: loop.name,
          temperature: loop.temperature
        });
      } else if (loop.temperature > this.freezingPoint + 10 && loop.frozen) {
        loop.frozen = false;
      }

      // Boiling
      if (loop.temperature > this.boilingPoint && !loop.boiling) {
        loop.boiling = true;
        this.logEvent(time, 'coolant_boiling', {
          loopId: loop.id,
          name: loop.name,
          temperature: loop.temperature
        });
      } else if (loop.temperature < this.boilingPoint - 10 && loop.boiling) {
        loop.boiling = false;
      }
    }
  }

  /**
   * Balance coolant between loops when cross-connect is open
   */
  private balanceLoops(dt: number): void {
    if (this.loops.length < 2) return;

    const loop1 = this.loops[0];
    const loop2 = this.loops[1];

    // Equalize temperatures (heat transfer between loops)
    const tempDiff = loop1.temperature - loop2.temperature;
    const heatTransferW = tempDiff * 500; // W (cross-connect heat transfer coefficient)

    const heatEnergyJ = heatTransferW * dt;

    // Loop 1 loses heat, Loop 2 gains heat
    const tempChange1 = -heatEnergyJ / (loop1.coolantMassKg * this.coolantSpecificHeat);
    const tempChange2 = heatEnergyJ / (loop2.coolantMassKg * this.coolantSpecificHeat);

    if (!isNaN(tempChange1) && !isNaN(tempChange2)) {
      loop1.temperature += tempChange1;
      loop2.temperature += tempChange2;
    }
  }

  /**
   * Check for warning conditions
   */
  private checkWarnings(time: number): void {
    for (const loop of this.loops) {
      // High temperature warning
      if (loop.temperature > 350 && !loop.boiling) {
        this.logEvent(time, 'coolant_high_temp', {
          loopId: loop.id,
          name: loop.name,
          temperature: loop.temperature
        });
      }

      // Low coolant warning
      const fillPercent = (loop.coolantMassKg / loop.maxCapacityKg) * 100;
      if (fillPercent < 30 && fillPercent > 0) {
        this.logEvent(time, 'coolant_low', {
          loopId: loop.id,
          name: loop.name,
          percentFull: fillPercent
        });
      }

      // Pump failure (frozen or no coolant)
      if (loop.pumpActive && (loop.frozen || loop.coolantMassKg === 0)) {
        this.logEvent(time, 'pump_failure', {
          loopId: loop.id,
          name: loop.name,
          frozen: loop.frozen,
          empty: loop.coolantMassKg === 0
        });
      }
    }
  }

  /**
   * Start a coolant pump
   */
  startPump(loopId: number): boolean {
    const loop = this.loops[loopId];
    if (!loop) return false;

    if (loop.frozen || loop.coolantMassKg === 0) return false;

    loop.pumpActive = true;
    return true;
  }

  /**
   * Stop a coolant pump
   */
  stopPump(loopId: number): void {
    const loop = this.loops[loopId];
    if (loop) {
      loop.pumpActive = false;
    }
  }

  /**
   * Open cross-connect valve
   */
  openCrossConnect(): void {
    this.crossConnectOpen = true;
  }

  /**
   * Close cross-connect valve
   */
  closeCrossConnect(): void {
    this.crossConnectOpen = false;
  }

  /**
   * Add coolant to a loop (refill)
   */
  addCoolant(loopId: number, massKg: number): boolean {
    const loop = this.loops[loopId];
    if (!loop) return false;

    const spaceAvailable = loop.maxCapacityKg - loop.coolantMassKg;
    const actualAdded = Math.min(massKg, spaceAvailable);

    if (actualAdded > 0) {
      loop.coolantMassKg += actualAdded;
      return true;
    }

    return false;
  }

  /**
   * Create a leak in a loop
   */
  createLeak(loopId: number, leakRateLPerMin: number): void {
    const loop = this.loops[loopId];
    if (loop) {
      loop.leakRateLPerMin = Math.max(0, leakRateLPerMin);
    }
  }

  /**
   * Repair a leak
   */
  repairLeak(loopId: number): void {
    const loop = this.loops[loopId];
    if (loop) {
      loop.leakRateLPerMin = 0;
    }
  }

  /**
   * Get total pump power consumption
   */
  getPumpPowerDraw(): number {
    let totalPower = 0;
    for (const loop of this.loops) {
      if (loop.pumpActive) {
        totalPower += loop.pumpPowerW;
      }
    }
    return totalPower;
  }

  /**
   * Get loop by ID
   */
  getLoop(loopId: number): CoolantLoop | undefined {
    return this.loops[loopId];
  }

  /**
   * Get current state for debugging/testing
   */
  getState() {
    return {
      loops: this.loops.map(loop => ({
        id: loop.id,
        name: loop.name,
        coolantMassKg: loop.coolantMassKg,
        percentFull: (loop.coolantMassKg / loop.maxCapacityKg) * 100,
        temperature: loop.temperature,
        radiatorTemperature: loop.radiatorTemperature,
        flowRateLPerMin: loop.flowRateLPerMin,
        pumpActive: loop.pumpActive,
        pumpPowerW: loop.pumpActive ? loop.pumpPowerW : 0,
        frozen: loop.frozen,
        boiling: loop.boiling,
        leaking: loop.leakRateLPerMin > 0
      })),
      crossConnectOpen: this.crossConnectOpen,
      totalHeatRejected: this.totalHeatRejected
    };
  }

  /**
   * Log an event
   */
  private logEvent(time: number, type: string, data: any): void {
    // Only log each event type once per second to avoid spam
    const recentEvent = this.events.find(
      e => e.type === type &&
      JSON.stringify(e.data) === JSON.stringify(data) &&
      time - e.time < 1.0
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
