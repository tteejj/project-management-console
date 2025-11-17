/**
 * PropulsionSystem.ts
 * Comprehensive rocket propulsion using real Tsiolkovsky equation and orbital mechanics
 */

import { Vector3 } from './CelestialBody';

export interface FuelType {
  name: string;
  specificImpulse: number;   // seconds (Isp)
  density: number;           // kg/m³
  cost: number;              // credits/kg
  storageTemp: number;       // K (cryogenic fuels need cooling)
  toxicity: number;          // 0-1
  explosivity: number;       // 0-1
}

export const FUEL_TYPES: Record<string, FuelType> = {
  // Chemical propellants
  HYDROGEN_OXYGEN: {
    name: 'Liquid Hydrogen/Oxygen',
    specificImpulse: 450,    // Best chemical rocket
    density: 300,            // LOX is denser than LH2
    cost: 2,
    storageTemp: 20,         // Very cold
    toxicity: 0.1,
    explosivity: 0.9
  },
  KEROSENE_OXYGEN: {
    name: 'RP-1/LOX',
    specificImpulse: 350,
    density: 900,
    cost: 1,
    storageTemp: 90,
    toxicity: 0.3,
    explosivity: 0.7
  },
  METHANE_OXYGEN: {
    name: 'Liquid Methane/Oxygen',
    specificImpulse: 380,
    density: 500,
    cost: 1.5,
    storageTemp: 111,
    toxicity: 0.2,
    explosivity: 0.8
  },
  HYDRAZINE: {
    name: 'Hydrazine Monopropellant',
    specificImpulse: 230,
    density: 1021,
    cost: 5,
    storageTemp: 298,
    toxicity: 0.9,
    explosivity: 0.6
  },

  // Advanced propulsion
  ION_XENON: {
    name: 'Xenon Ion Drive',
    specificImpulse: 3000,   // Very high Isp
    density: 3000,
    cost: 50,
    storageTemp: 298,
    toxicity: 0.0,
    explosivity: 0.0
  },
  FUSION_DEUTERIUM: {
    name: 'Deuterium Fusion',
    specificImpulse: 100000, // Extremely high
    density: 162,
    cost: 1000,
    storageTemp: 20,
    toxicity: 0.1,
    explosivity: 0.3
  },
  ANTIMATTER: {
    name: 'Antimatter',
    specificImpulse: 10000000, // Nearly c
    density: 1,              // Magnetic containment
    cost: 1000000,
    storageTemp: 0,          // Magnetic trap
    toxicity: 0.0,
    explosivity: 1.0         // Catastrophic if containment fails
  }
};

export interface PropulsionEngine {
  id: string;
  name: string;
  type: EngineType;
  fuelType: string;         // Key from FUEL_TYPES
  maxThrust: number;        // Newtons
  massFlowRate: number;     // kg/s at max thrust
  efficiency: number;       // 0-1 (actual vs theoretical Isp)
  powerConsumption: number; // watts (for ion drives)
  mass: number;             // kg (engine dry mass)
  operational: boolean;
  health: number;           // 0-100
  temperature: number;      // K
  throttle: number;         // 0-1 (current throttle setting)
}

export type EngineType = 'CHEMICAL' | 'ION' | 'FUSION' | 'ANTIMATTER' | 'RCS';

export interface FuelTank {
  id: string;
  fuelType: string;
  capacity: number;         // kg
  current: number;          // kg
  mass: number;             // kg (tank dry mass)
  insulated: boolean;       // For cryogenic fuels
  coolingPower: number;     // watts (for active cooling)
  integrity: number;        // 0-100
}

export interface Maneuver {
  id: string;
  name: string;
  type: ManeuverType;
  startTime: number;        // timestamp
  duration: number;         // seconds
  deltaV: Vector3;          // m/s change in velocity
  fuelRequired: number;     // kg
  executed: boolean;
  progress: number;         // 0-1
}

export type ManeuverType =
  | 'PROGRADE'    // Speed up
  | 'RETROGRADE'  // Slow down
  | 'NORMAL'      // Out of orbital plane
  | 'ANTINORMAL'  // Into orbital plane
  | 'RADIAL_IN'   // Toward body
  | 'RADIAL_OUT'  // Away from body
  | 'CUSTOM';     // Arbitrary direction

export interface TransferOrbit {
  from: Vector3;
  to: Vector3;
  burn1: {
    deltaV: number;
    direction: Vector3;
    time: number;
  };
  burn2: {
    deltaV: number;
    direction: Vector3;
    time: number;
  };
  transferTime: number;     // seconds
  totalDeltaV: number;      // m/s
  fuelRequired: number;     // kg
}

/**
 * Comprehensive Propulsion System
 * Implements real rocket equation and orbital mechanics
 */
export class PropulsionSystem {
  private engines: Map<string, PropulsionEngine> = new Map();
  private fuelTanks: Map<string, FuelTank> = new Map();
  private plannedManeuvers: Maneuver[] = [];
  private currentBurn: Maneuver | null = null;

  // Ship properties
  private dryMass: number;          // kg (ship without fuel)
  private cargoMass: number = 0;    // kg

  // Physical constants
  private static readonly G = 6.67430e-11; // Gravitational constant
  private static readonly g0 = 9.80665;    // Standard gravity (for Isp conversion)

  constructor(dryMass: number) {
    this.dryMass = dryMass;
  }

  /**
   * Add engine to ship
   */
  addEngine(engine: PropulsionEngine): void {
    this.engines.set(engine.id, engine);
  }

  /**
   * Add fuel tank
   */
  addFuelTank(tank: FuelTank): void {
    this.fuelTanks.set(tank.id, tank);
  }

  /**
   * Calculate total ship mass
   */
  getTotalMass(): number {
    let mass = this.dryMass + this.cargoMass;

    // Add engine masses
    for (const engine of this.engines.values()) {
      mass += engine.mass;
    }

    // Add tank masses (dry + fuel)
    for (const tank of this.fuelTanks.values()) {
      mass += tank.mass + tank.current;
    }

    return mass;
  }

  /**
   * Calculate available delta-V using Tsiolkovsky rocket equation
   * Δv = ve * ln(m0/mf)
   * where ve = Isp * g0
   */
  calculateDeltaV(fuelType?: string): number {
    // If no fuel type specified, use primary engine's fuel
    const primaryEngine = Array.from(this.engines.values())[0];
    if (!primaryEngine && !fuelType) return 0;

    const fuel = fuelType || primaryEngine.fuelType;
    const fuelData = FUEL_TYPES[fuel];
    if (!fuelData) return 0;

    // Get total fuel of this type
    let totalFuel = 0;
    for (const tank of this.fuelTanks.values()) {
      if (tank.fuelType === fuel) {
        totalFuel += tank.current;
      }
    }

    // Calculate exhaust velocity: ve = Isp * g0
    const engine = Array.from(this.engines.values()).find(e => e.fuelType === fuel);
    const efficiency = engine?.efficiency || 1.0;
    const effectiveIsp = fuelData.specificImpulse * efficiency;
    const exhaustVelocity = effectiveIsp * PropulsionSystem.g0;

    // Tsiolkovsky rocket equation
    const m0 = this.getTotalMass(); // Initial mass (with fuel)
    const mf = m0 - totalFuel;       // Final mass (fuel spent)

    if (mf <= 0) return 0;

    const deltaV = exhaustVelocity * Math.log(m0 / mf);
    return deltaV;
  }

  /**
   * Calculate fuel required for a delta-V
   * Rearranged rocket equation: mf = m0 * (1 - e^(-Δv/ve))
   */
  calculateFuelRequired(deltaV: number, fuelType?: string): number {
    const primaryEngine = Array.from(this.engines.values())[0];
    if (!primaryEngine && !fuelType) return Infinity;

    const fuel = fuelType || primaryEngine.fuelType;
    const fuelData = FUEL_TYPES[fuel];
    if (!fuelData) return Infinity;

    const engine = Array.from(this.engines.values()).find(e => e.fuelType === fuel);
    const efficiency = engine?.efficiency || 1.0;
    const effectiveIsp = fuelData.specificImpulse * efficiency;
    const exhaustVelocity = effectiveIsp * PropulsionSystem.g0;

    const m0 = this.getTotalMass();

    // mf = m0 / e^(Δv/ve)
    const massRatio = Math.exp(deltaV / exhaustVelocity);
    const finalMass = m0 / massRatio;
    const fuelRequired = m0 - finalMass;

    return fuelRequired;
  }

  /**
   * Calculate Hohmann transfer orbit between two circular orbits
   */
  calculateHohmannTransfer(
    r1: number, // Current orbit radius (m)
    r2: number, // Target orbit radius (m)
    centralBodyMu: number // Standard gravitational parameter (m³/s²)
  ): TransferOrbit {
    // Velocities in circular orbits
    const v1 = Math.sqrt(centralBodyMu / r1);
    const v2 = Math.sqrt(centralBodyMu / r2);

    // Semi-major axis of transfer orbit
    const a_transfer = (r1 + r2) / 2;

    // Velocities at periapsis and apoapsis of transfer orbit
    const v_periapsis = Math.sqrt(centralBodyMu * (2/r1 - 1/a_transfer));
    const v_apoapsis = Math.sqrt(centralBodyMu * (2/r2 - 1/a_transfer));

    // Delta-V for each burn
    const deltaV1 = Math.abs(v_periapsis - v1); // Burn at r1
    const deltaV2 = Math.abs(v2 - v_apoapsis);   // Burn at r2

    const totalDeltaV = deltaV1 + deltaV2;

    // Transfer time (half orbital period of transfer orbit)
    const transferTime = Math.PI * Math.sqrt(Math.pow(a_transfer, 3) / centralBodyMu);

    const fuelRequired = this.calculateFuelRequired(totalDeltaV);

    return {
      from: { x: r1, y: 0, z: 0 }, // Simplified
      to: { x: r2, y: 0, z: 0 },
      burn1: {
        deltaV: deltaV1,
        direction: { x: 1, y: 0, z: 0 }, // Prograde
        time: 0
      },
      burn2: {
        deltaV: deltaV2,
        direction: { x: 1, y: 0, z: 0 }, // Prograde
        time: transferTime
      },
      transferTime,
      totalDeltaV,
      fuelRequired
    };
  }

  /**
   * Plan a maneuver
   */
  planManeuver(
    name: string,
    type: ManeuverType,
    deltaV: Vector3,
    startTime: number
  ): Maneuver | null {
    const deltaVMagnitude = this.magnitude(deltaV);
    const fuelRequired = this.calculateFuelRequired(deltaVMagnitude);

    // Check if we have enough fuel
    const availableFuel = this.getAvailableFuel();
    if (fuelRequired > availableFuel) {
      console.error(`Insufficient fuel: need ${fuelRequired.toFixed(0)} kg, have ${availableFuel.toFixed(0)} kg`);
      return null;
    }

    // Calculate burn duration
    const primaryEngine = Array.from(this.engines.values())[0];
    if (!primaryEngine) return null;

    const thrust = primaryEngine.maxThrust * primaryEngine.throttle;
    const mass = this.getTotalMass();
    const acceleration = thrust / mass;
    const duration = deltaVMagnitude / acceleration;

    const maneuver: Maneuver = {
      id: `maneuver_${Date.now()}`,
      name,
      type,
      startTime,
      duration,
      deltaV,
      fuelRequired,
      executed: false,
      progress: 0
    };

    this.plannedManeuvers.push(maneuver);
    return maneuver;
  }

  /**
   * Execute burn
   */
  update(deltaTime: number, currentTime: number): {
    thrust: Vector3;
    fuelConsumed: number;
    acceleration: Vector3;
  } {
    let thrust: Vector3 = { x: 0, y: 0, z: 0 };
    let fuelConsumed = 0;
    let acceleration: Vector3 = { x: 0, y: 0, z: 0 };

    // Check for maneuvers to execute
    if (!this.currentBurn) {
      const nextManeuver = this.plannedManeuvers.find(
        m => !m.executed && currentTime >= m.startTime
      );

      if (nextManeuver) {
        this.currentBurn = nextManeuver;
      }
    }

    // Execute current burn
    if (this.currentBurn) {
      const maneuver = this.currentBurn;
      const elapsed = currentTime - maneuver.startTime;

      if (elapsed < maneuver.duration) {
        // Still burning
        const progress = elapsed / maneuver.duration;
        maneuver.progress = progress;

        // Calculate thrust direction
        const direction = this.normalize(maneuver.deltaV);

        // Get primary engine
        const primaryEngine = Array.from(this.engines.values())[0];
        if (primaryEngine && primaryEngine.operational) {
          const thrustMagnitude = primaryEngine.maxThrust * primaryEngine.throttle;
          thrust = {
            x: direction.x * thrustMagnitude,
            y: direction.y * thrustMagnitude,
            z: direction.z * thrustMagnitude
          };

          // Consume fuel based on mass flow rate
          const fuelRate = primaryEngine.massFlowRate * primaryEngine.throttle;
          fuelConsumed = fuelRate * deltaTime;

          // Actually consume from tanks
          this.consumeFuel(primaryEngine.fuelType, fuelConsumed);

          // Calculate acceleration: F = ma
          const mass = this.getTotalMass();
          const accelMagnitude = thrustMagnitude / mass;
          acceleration = {
            x: direction.x * accelMagnitude,
            y: direction.y * accelMagnitude,
            z: direction.z * accelMagnitude
          };

          // Update engine temperature
          primaryEngine.temperature += deltaTime * 10; // Simplified heating
        }
      } else {
        // Burn complete
        maneuver.executed = true;
        maneuver.progress = 1.0;
        this.currentBurn = null;
      }
    }

    // Cool down engines
    for (const engine of this.engines.values()) {
      if (engine.temperature > 300) {
        engine.temperature -= deltaTime * 2; // Simplified cooling
      }
    }

    return { thrust, fuelConsumed, acceleration };
  }

  /**
   * Consume fuel from tanks
   */
  private consumeFuel(fuelType: string, amount: number): boolean {
    let remaining = amount;

    for (const tank of this.fuelTanks.values()) {
      if (tank.fuelType === fuelType && tank.current > 0) {
        const consumed = Math.min(tank.current, remaining);
        tank.current -= consumed;
        remaining -= consumed;

        if (remaining <= 0) break;
      }
    }

    return remaining === 0;
  }

  /**
   * Get available fuel of specific type
   */
  getAvailableFuel(fuelType?: string): number {
    let total = 0;

    for (const tank of this.fuelTanks.values()) {
      if (!fuelType || tank.fuelType === fuelType) {
        total += tank.current;
      }
    }

    return total;
  }

  /**
   * Refuel
   */
  refuel(fuelType: string, amount: number): number {
    let remaining = amount;

    for (const tank of this.fuelTanks.values()) {
      if (tank.fuelType === fuelType) {
        const capacity = tank.capacity - tank.current;
        const added = Math.min(capacity, remaining);
        tank.current += added;
        remaining -= added;

        if (remaining <= 0) break;
      }
    }

    return amount - remaining; // Amount actually added
  }

  /**
   * Get thrust-to-weight ratio
   */
  getThrustToWeight(gravity: number): number {
    let totalThrust = 0;

    for (const engine of this.engines.values()) {
      if (engine.operational) {
        totalThrust += engine.maxThrust * engine.throttle;
      }
    }

    const weight = this.getTotalMass() * gravity;
    return totalThrust / weight;
  }

  /**
   * Can we complete a maneuver?
   */
  canPerformManeuver(deltaV: number): {
    possible: boolean;
    fuelNeeded: number;
    fuelAvailable: number;
    shortfall: number;
  } {
    const fuelNeeded = this.calculateFuelRequired(deltaV);
    const fuelAvailable = this.getAvailableFuel();

    return {
      possible: fuelAvailable >= fuelNeeded,
      fuelNeeded,
      fuelAvailable,
      shortfall: Math.max(0, fuelNeeded - fuelAvailable)
    };
  }

  /**
   * Get all planned maneuvers
   */
  getPlannedManeuvers(): Maneuver[] {
    return this.plannedManeuvers;
  }

  /**
   * Cancel maneuver
   */
  cancelManeuver(maneuverId: string): boolean {
    const index = this.plannedManeuvers.findIndex(m => m.id === maneuverId);
    if (index >= 0) {
      this.plannedManeuvers.splice(index, 1);
      return true;
    }
    return false;
  }

  /**
   * Get engine status
   */
  getEngineStatus(): PropulsionEngine[] {
    return Array.from(this.engines.values());
  }

  /**
   * Get fuel tank status
   */
  getFuelTankStatus(): FuelTank[] {
    return Array.from(this.fuelTanks.values());
  }

  /**
   * Set engine throttle
   */
  setThrottle(engineId: string, throttle: number): void {
    const engine = this.engines.get(engineId);
    if (engine) {
      engine.throttle = Math.max(0, Math.min(1, throttle));
    }
  }

  /**
   * Set cargo mass
   */
  setCargoMass(mass: number): void {
    this.cargoMass = Math.max(0, mass);
  }

  /**
   * Vector operations
   */
  private magnitude(v: Vector3): number {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  }

  private normalize(v: Vector3): Vector3 {
    const mag = this.magnitude(v);
    if (mag === 0) return { x: 0, y: 0, z: 0 };
    return {
      x: v.x / mag,
      y: v.y / mag,
      z: v.z / mag
    };
  }

  /**
   * Get comprehensive status report
   */
  getStatus(): {
    totalMass: number;
    dryMass: number;
    fuelMass: number;
    cargoMass: number;
    availableDeltaV: number;
    engines: PropulsionEngine[];
    tanks: FuelTank[];
    activeBurn: Maneuver | null;
    plannedManeuvers: Maneuver[];
  } {
    const fuelMass = this.getAvailableFuel();

    return {
      totalMass: this.getTotalMass(),
      dryMass: this.dryMass,
      fuelMass,
      cargoMass: this.cargoMass,
      availableDeltaV: this.calculateDeltaV(),
      engines: Array.from(this.engines.values()),
      tanks: Array.from(this.fuelTanks.values()),
      activeBurn: this.currentBurn,
      plannedManeuvers: this.plannedManeuvers
    };
  }
}
