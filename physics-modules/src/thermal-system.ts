/**
 * Thermal System Physics Module
 *
 * Simulates:
 * - Per-component heat tracking
 * - Temperature dynamics with mass and specific heat
 * - Heat transfer between components and compartments
 * - Thermal conduction through bulkheads
 * - Heat generation from inefficiencies
 * - Passive cooling and radiation
 */

export interface HeatSource {
  name: string;
  heatGenerationW: number; // Current heat generation in watts
  temperature: number; // K
  mass: number; // kg
  specificHeat: number; // J/(kg·K)
  compartmentId: number; // Which compartment it's in
}

export interface Compartment {
  id: number;
  name: string;
  volume: number; // m³
  gasMass: number; // kg (total atmosphere mass)
  temperature: number; // K
  neighborIds: number[]; // Adjacent compartments
}

interface ThermalSystemConfig {
  heatSources?: HeatSource[];
  compartments?: Compartment[];
  thermalConductivity?: number; // W/K for bulkheads
  ambientSpaceTemp?: number; // K
}

export class ThermalSystem {
  public heatSources: Map<string, HeatSource>;
  public compartments: Compartment[];
  public thermalConductivity: number; // W/K between compartments
  public ambientSpaceTemp: number; // K

  // Tracking
  public totalHeatGenerated: number = 0; // J
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor(config?: ThermalSystemConfig) {
    this.heatSources = new Map();

    if (config?.heatSources) {
      config.heatSources.forEach(source => {
        this.heatSources.set(source.name, source);
      });
    } else {
      this.createDefaultHeatSources();
    }

    this.compartments = config?.compartments || this.createDefaultCompartments();
    this.thermalConductivity = config?.thermalConductivity || 50; // W/K
    this.ambientSpaceTemp = config?.ambientSpaceTemp || 2.7; // K (cosmic background)
  }

  private createDefaultHeatSources(): void {
    const sources: HeatSource[] = [
      {
        name: 'reactor',
        heatGenerationW: 0,
        temperature: 400,
        mass: 200,
        specificHeat: 450,
        compartmentId: 1 // Engineering
      },
      {
        name: 'main_engine',
        heatGenerationW: 0,
        temperature: 293,
        mass: 150,
        specificHeat: 500,
        compartmentId: 2 // Engine bay
      },
      {
        name: 'battery',
        heatGenerationW: 0,
        temperature: 293,
        mass: 80,
        specificHeat: 800,
        compartmentId: 0 // Electronics
      },
      {
        name: 'hydraulic_pump_1',
        heatGenerationW: 0,
        temperature: 293,
        mass: 15,
        specificHeat: 1000,
        compartmentId: 1
      },
      {
        name: 'hydraulic_pump_2',
        heatGenerationW: 0,
        temperature: 293,
        mass: 15,
        specificHeat: 1000,
        compartmentId: 1
      },
      {
        name: 'coolant_pump_1',
        heatGenerationW: 0,
        temperature: 293,
        mass: 10,
        specificHeat: 1000,
        compartmentId: 1
      },
      {
        name: 'nav_computer',
        heatGenerationW: 0,
        temperature: 293,
        mass: 5,
        specificHeat: 700,
        compartmentId: 0
      }
    ];

    sources.forEach(source => {
      this.heatSources.set(source.name, source);
    });
  }

  private createDefaultCompartments(): Compartment[] {
    return [
      {
        id: 0,
        name: 'Electronics',
        volume: 30,
        gasMass: 36, // ~1.2 kg/m³ air density
        temperature: 293,
        neighborIds: [1]
      },
      {
        id: 1,
        name: 'Engineering',
        volume: 50,
        gasMass: 60,
        temperature: 293,
        neighborIds: [0, 2]
      },
      {
        id: 2,
        name: 'Engine Bay',
        volume: 40,
        gasMass: 48,
        temperature: 293,
        neighborIds: [1]
      }
    ];
  }

  /**
   * Main update loop
   */
  update(dt: number, simulationTime: number): void {
    // 1. Update component temperatures from heat generation
    this.updateComponentTemperatures(dt);

    // 2. Heat transfer from components to compartments
    this.transferHeatToCompartments(dt);

    // 3. Thermal conduction between compartments
    this.conductHeatBetweenCompartments(dt);

    // 4. Check for overheating warnings
    this.checkWarnings(simulationTime);

    // 5. Track total heat
    this.trackHeatGeneration(dt);
  }

  /**
   * Update component temperatures based on heat generation
   */
  private updateComponentTemperatures(dt: number): void {
    for (const [name, source] of this.heatSources) {
      if (source.heatGenerationW > 0) {
        // Q = m * c * ΔT
        // ΔT = Q / (m * c) = (P * dt) / (m * c)
        const tempRise = (source.heatGenerationW * dt) / (source.mass * source.specificHeat);
        source.temperature += tempRise;
      }
    }
  }

  /**
   * Transfer heat from hot components to compartment air
   */
  private transferHeatToCompartments(dt: number): void {
    for (const [name, source] of this.heatSources) {
      const compartment = this.compartments[source.compartmentId];

      if (!compartment) continue;

      // Heat transfer proportional to temperature difference
      const tempDiff = source.temperature - compartment.temperature;

      // Thermal conductance (simplified convection/conduction)
      const thermalConductance = this.getThermalConductance(name);
      const heatTransferW = tempDiff * thermalConductance;

      // Component cools
      const componentTempDrop = (heatTransferW * dt) / (source.mass * source.specificHeat);
      source.temperature -= componentTempDrop;

      // Compartment heats
      const airSpecificHeat = 1000; // J/(kg·K)
      const compartmentTempRise = (heatTransferW * dt) / (compartment.gasMass * airSpecificHeat);
      compartment.temperature += compartmentTempRise;
    }
  }

  /**
   * Conduct heat between adjacent compartments
   */
  private conductHeatBetweenCompartments(dt: number): void {
    const processed = new Set<string>();

    for (const comp of this.compartments) {
      for (const neighborId of comp.neighborIds) {
        const pairKey = `${Math.min(comp.id, neighborId)}-${Math.max(comp.id, neighborId)}`;

        if (processed.has(pairKey)) continue;
        processed.add(pairKey);

        const neighbor = this.compartments[neighborId];
        if (!neighbor) continue;

        const tempDiff = comp.temperature - neighbor.temperature;
        const heatFlowW = tempDiff * this.thermalConductivity;

        const airSpecificHeat = 1000;

        const comp1TempChange = -(heatFlowW * dt) / (comp.gasMass * airSpecificHeat);
        const comp2TempChange = (heatFlowW * dt) / (neighbor.gasMass * airSpecificHeat);

        comp.temperature += comp1TempChange;
        neighbor.temperature += comp2TempChange;
      }
    }
  }

  /**
   * Check for overheating warnings
   */
  private checkWarnings(time: number): void {
    for (const [name, source] of this.heatSources) {
      // Component-specific temperature limits
      const limit = this.getTemperatureLimit(name);

      if (source.temperature > limit) {
        this.logEvent(time, 'component_overheating', {
          component: name,
          temperature: source.temperature,
          limit: limit
        });
      }
    }

    for (const comp of this.compartments) {
      if (comp.temperature > 330) { // 57°C
        this.logEvent(time, 'compartment_hot', {
          compartmentId: comp.id,
          name: comp.name,
          temperature: comp.temperature
        });
      }

      if (comp.temperature < 260) { // -13°C
        this.logEvent(time, 'compartment_cold', {
          compartmentId: comp.id,
          name: comp.name,
          temperature: comp.temperature
        });
      }
    }
  }

  /**
   * Track total heat generation
   */
  private trackHeatGeneration(dt: number): void {
    for (const [name, source] of this.heatSources) {
      this.totalHeatGenerated += source.heatGenerationW * dt;
    }
  }

  /**
   * Get thermal conductance for a component (W/K)
   */
  private getThermalConductance(componentName: string): number {
    // Different components have different surface areas and contact
    // Higher values = better heat transfer to compartment air
    const conductances: Record<string, number> = {
      'reactor': 20,      // Large, good air circulation
      'main_engine': 30,  // Very hot, large surface area
      'battery': 10,      // Moderate surface area
      'hydraulic_pump_1': 5,
      'hydraulic_pump_2': 5,
      'coolant_pump_1': 5,
      'nav_computer': 3
    };

    return conductances[componentName] || 5;
  }

  /**
   * Get temperature limit for component (K)
   */
  private getTemperatureLimit(componentName: string): number {
    const limits: Record<string, number> = {
      'reactor': 900, // Auto SCRAM
      'main_engine': 800,
      'battery': 330, // 57°C
      'hydraulic_pump_1': 400,
      'hydraulic_pump_2': 400,
      'coolant_pump_1': 400,
      'nav_computer': 350
    };

    return limits[componentName] || 350;
  }

  /**
   * Add heat to a specific component
   */
  addHeat(componentName: string, joules: number): void {
    const source = this.heatSources.get(componentName);
    if (source) {
      const tempRise = joules / (source.mass * source.specificHeat);
      source.temperature += tempRise;
    }
  }

  /**
   * Set heat generation rate for a component
   */
  setHeatGeneration(componentName: string, watts: number): void {
    const source = this.heatSources.get(componentName);
    if (source) {
      source.heatGenerationW = Math.max(0, watts);
    }
  }

  /**
   * Get component temperature
   */
  getComponentTemperature(componentName: string): number {
    const source = this.heatSources.get(componentName);
    return source ? source.temperature : 0;
  }

  /**
   * Get compartment temperature
   */
  getCompartmentTemperature(compartmentId: number): number {
    const comp = this.compartments[compartmentId];
    return comp ? comp.temperature : 0;
  }

  /**
   * Set compartment temperature (for external cooling/heating)
   */
  setCompartmentTemperature(compartmentId: number, tempK: number): void {
    const comp = this.compartments[compartmentId];
    if (comp) {
      comp.temperature = tempK;
    }
  }

  /**
   * Get component by name
   */
  getComponent(name: string): HeatSource | undefined {
    return this.heatSources.get(name);
  }

  /**
   * Get compartment by ID
   */
  getCompartment(id: number): Compartment | undefined {
    return this.compartments[id];
  }

  /**
   * Get current state for debugging/testing
   */
  getState() {
    return {
      components: Array.from(this.heatSources.entries()).map(([name, source]) => ({
        name,
        temperature: source.temperature,
        heatGeneration: source.heatGenerationW,
        compartmentId: source.compartmentId
      })),
      compartments: this.compartments.map(comp => ({
        id: comp.id,
        name: comp.name,
        temperature: comp.temperature,
        gasMass: comp.gasMass
      })),
      totalHeatGenerated: this.totalHeatGenerated
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
