/**
 * Thermal Budget System
 *
 * Manages heat generation, transfer, cooling, and thermal limits
 * Critical for long-duration missions - heat management is survival!
 */

export enum CoolingType {
  LIQUID_LOOP = 'liquid_loop',
  RADIATOR = 'radiator',
  HEAT_PIPE = 'heat_pipe',
  THERMOELECTRIC = 'thermoelectric'
}

export interface ThermalComponent {
  id: string;
  name: string;
  temperature: number;          // K
  mass: number;                 // kg
  specificHeat: number;         // J/(kg·K)
  surfaceArea: number;          // m²
  heatGeneration: number;       // W
  compartmentId: string;

  // Optional properties
  maxSafeTemp?: number;         // K
  exposedToSpace?: boolean;     // For radiation
  powerDraw?: number;           // kW (for integration)
  efficiency?: number;          // 0-1 (for heat calculation)
  emissivity?: number;          // 0-1 (for radiation, default 0.9)
}

export interface ThermalCompartment {
  id: string;
  name: string;
  temperature: number;          // K
  volume: number;               // m³
  airMass: number;              // kg
  connectedCompartments: string[];
}

export interface CoolingSystem {
  id: string;
  type: CoolingType;
  coolingCapacity: number;      // W
  powerDraw: number;            // kW
  efficiency: number;           // 0-1
  targetComponentIds: string[];
  active: boolean;
  flowRate?: number;            // kg/s (for liquid loops)
}

export interface ThermalConfig {
  components: ThermalComponent[];
  compartments: ThermalCompartment[];
  coolingSystems: CoolingSystem[];
}

export interface ThermalWarning {
  componentId: string;
  type: 'overheating' | 'critical';
  temperature: number;
  maxSafe: number;
}

export interface ThermalStatistics {
  totalHeatGenerated: number;   // J
  totalHeatRejected: number;    // J
  averageTemperature: number;   // K
  hottestComponent: string;
  hottestTemperature: number;   // K
}

/**
 * Thermal Budget System
 */
export class ThermalBudgetSystem {
  private components: Map<string, ThermalComponent> = new Map();
  private compartments: Map<string, ThermalCompartment> = new Map();
  private coolingSystems: Map<string, CoolingSystem> = new Map();

  // Statistics
  private totalHeatGenerated: number = 0;
  private totalHeatRejected: number = 0;

  // Constants
  private readonly STEFAN_BOLTZMANN = 5.67e-8;  // W/(m²·K⁴)
  private readonly AIR_SPECIFIC_HEAT = 1005;    // J/(kg·K)
  private readonly CONVECTION_COEFF = 10;       // W/(m²·K) typical for natural convection
  private readonly CONDUCTION_COEFF = 0.5;      // Simplified inter-compartment heat transfer

  constructor(config: ThermalConfig) {
    for (const component of config.components) {
      this.components.set(component.id, component);
    }
    for (const compartment of config.compartments) {
      this.compartments.set(compartment.id, compartment);
    }
    for (const cooling of config.coolingSystems) {
      this.coolingSystems.set(cooling.id, cooling);
    }
  }

  /**
   * Update thermal budget system
   */
  update(dt: number): void {
    // PHASE 1: Heat generation
    for (const component of this.components.values()) {
      if (component.heatGeneration > 0) {
        // Q = P * t, ΔT = Q / (m * c)
        const heatEnergy = component.heatGeneration * dt;  // J
        const tempRise = heatEnergy / (component.mass * component.specificHeat);
        component.temperature += tempRise;

        this.totalHeatGenerated += heatEnergy;
      }
    }

    // PHASE 2: Component to compartment heat transfer (convection)
    for (const component of this.components.values()) {
      const compartment = this.compartments.get(component.compartmentId);
      if (!compartment) continue;

      // Newton's law of cooling: Q = h * A * ΔT
      const tempDiff = component.temperature - compartment.temperature;
      const heatTransfer = this.CONVECTION_COEFF * component.surfaceArea * tempDiff * dt;

      // Update component temperature
      const componentTempChange = -heatTransfer / (component.mass * component.specificHeat);
      component.temperature += componentTempChange;

      // Update compartment air temperature
      const airTempChange = heatTransfer / (compartment.airMass * this.AIR_SPECIFIC_HEAT);
      compartment.temperature += airTempChange;
    }

    // PHASE 3: Inter-compartment heat transfer
    for (const compartment of this.compartments.values()) {
      for (const connectedId of compartment.connectedCompartments) {
        const connected = this.compartments.get(connectedId);
        if (!connected) continue;

        // Simplified conduction model
        const tempDiff = compartment.temperature - connected.temperature;
        const heatTransfer = this.CONDUCTION_COEFF * tempDiff * dt;

        // Update both compartments
        const change1 = -heatTransfer / (compartment.airMass * this.AIR_SPECIFIC_HEAT);
        const change2 = heatTransfer / (connected.airMass * this.AIR_SPECIFIC_HEAT);

        compartment.temperature += change1;
        connected.temperature += change2;
      }
    }

    // PHASE 4: Radiation to space (Stefan-Boltzmann)
    for (const component of this.components.values()) {
      if (component.exposedToSpace) {
        const emissivity = component.emissivity ?? 0.9;
        const spaceTemp = 3;  // K (cosmic background)

        // P = ε * σ * A * (T⁴ - T_space⁴)
        const radPower = emissivity * this.STEFAN_BOLTZMANN * component.surfaceArea *
          (Math.pow(component.temperature, 4) - Math.pow(spaceTemp, 4));

        const heatRejected = radPower * dt;
        const tempDrop = heatRejected / (component.mass * component.specificHeat);
        component.temperature -= tempDrop;

        this.totalHeatRejected += heatRejected;
      }
    }

    // PHASE 5: Active cooling systems
    for (const cooling of this.coolingSystems.values()) {
      if (!cooling.active) continue;

      for (const targetId of cooling.targetComponentIds) {
        const component = this.components.get(targetId);
        if (!component) continue;

        // Remove heat based on cooling capacity
        const heatRemoved = cooling.coolingCapacity * cooling.efficiency * dt;
        const tempDrop = heatRemoved / (component.mass * component.specificHeat);
        component.temperature -= tempDrop;

        this.totalHeatRejected += heatRemoved;
      }
    }
  }

  /**
   * Get thermal warnings
   */
  getWarnings(): ThermalWarning[] {
    const warnings: ThermalWarning[] = [];

    for (const component of this.components.values()) {
      if (component.maxSafeTemp && component.temperature > component.maxSafeTemp) {
        warnings.push({
          componentId: component.id,
          type: component.temperature > component.maxSafeTemp * 1.2 ? 'critical' : 'overheating',
          temperature: component.temperature,
          maxSafe: component.maxSafeTemp
        });
      }
    }

    return warnings;
  }

  /**
   * Get statistics
   */
  getStatistics(): ThermalStatistics {
    let totalTemp = 0;
    let count = 0;
    let hottestComponent = '';
    let hottestTemperature = 0;

    for (const component of this.components.values()) {
      totalTemp += component.temperature;
      count++;

      if (component.temperature > hottestTemperature) {
        hottestTemperature = component.temperature;
        hottestComponent = component.id;
      }
    }

    return {
      totalHeatGenerated: this.totalHeatGenerated,
      totalHeatRejected: this.totalHeatRejected,
      averageTemperature: count > 0 ? totalTemp / count : 0,
      hottestComponent,
      hottestTemperature
    };
  }

  /**
   * Get component by ID
   */
  getComponent(id: string): ThermalComponent | undefined {
    return this.components.get(id);
  }

  /**
   * Get compartment by ID
   */
  getCompartment(id: string): ThermalCompartment | undefined {
    return this.compartments.get(id);
  }

  /**
   * Get cooling system by ID
   */
  getCoolingSystem(id: string): CoolingSystem | undefined {
    return this.coolingSystems.get(id);
  }

  /**
   * Add component
   */
  addComponent(component: ThermalComponent): void {
    this.components.set(component.id, component);
  }

  /**
   * Add compartment
   */
  addCompartment(compartment: ThermalCompartment): void {
    this.compartments.set(compartment.id, compartment);
  }

  /**
   * Add cooling system
   */
  addCoolingSystem(cooling: CoolingSystem): void {
    this.coolingSystems.set(cooling.id, cooling);
  }
}
