/**
 * Life Support System
 *
 * Comprehensive atmospheric and environmental control system managing:
 * - Atmosphere composition (O2, CO2, N2) per compartment
 * - Pressure and temperature per compartment
 * - Bulkhead doors between compartments
 * - Fire outbreak, spread, and suppression
 * - Hull breach detection and sealing
 * - O2 generation and CO2 scrubbing
 * - Emergency venting to space
 *
 * Design Reference: docs/01-CONTROL-STATIONS.md lines 305-421
 */

export interface Compartment {
  id: string;
  name: string;
  volume: number;  // m³

  // Atmosphere
  o2Mass: number;      // kg of O2
  co2Mass: number;     // kg of CO2
  n2Mass: number;      // kg of N2
  temperature: number; // K

  // Status
  onFire: boolean;
  fireIntensity: number;  // 0-100
  breached: boolean;
  breachSize: number;     // m² (hole size)

  // Connections (indices of adjacent compartments)
  connections: { compartmentId: string; doorOpen: boolean }[];
}

export interface LifeSupportConfig {
  compartments?: Compartment[];
  o2GeneratorRateLPerMin?: number;  // L/min at STP
  co2ScrubberEfficiency?: number;   // 0-1
  halonMassKg?: number;             // kg of fire suppressant
  scrubberMediaPercent?: number;    // 0-100 filter life
  o2ReservesKg?: number;            // kg of O2 in tanks
}

export class LifeSupportSystem {
  // Constants
  private readonly GAS_CONSTANT = 8.314;  // J/(mol·K)
  private readonly O2_MOLAR_MASS = 0.032; // kg/mol
  private readonly CO2_MOLAR_MASS = 0.044; // kg/mol
  private readonly N2_MOLAR_MASS = 0.028; // kg/mol
  private readonly STP_TEMP = 273.15; // K
  private readonly STP_PRESSURE = 101325; // Pa

  // Atmosphere targets (Earth-like)
  private readonly TARGET_O2_PERCENT = 21;
  private readonly TARGET_CO2_PERCENT = 0.04;
  private readonly TARGET_N2_PERCENT = 78;
  private readonly TARGET_PRESSURE_KPA = 101;
  private readonly TARGET_TEMP_K = 293; // 20°C

  // Fire physics
  private readonly FIRE_O2_CONSUMPTION_RATE = 0.0001; // kg/s per intensity point
  private readonly FIRE_CO2_PRODUCTION_RATE = 0.00015; // kg/s per intensity point
  private readonly FIRE_HEAT_GENERATION = 50; // W per intensity point
  private readonly FIRE_SPREAD_RATE = 0.1; // intensity/s if conditions good
  private readonly HALON_EFFECTIVENESS = 2.0; // intensity reduction per kg

  // Breach physics
  private readonly VENT_RATE_CONSTANT = 0.1; // kg/s per m² breach at 1 atm

  // State
  compartments: Compartment[];

  // Global systems
  o2GeneratorActive: boolean = false;
  o2GeneratorRateLPerMin: number = 1.0;  // Adjustable
  o2ReservesKg: number = 85;

  co2ScrubberActive: boolean = false;
  co2ScrubberEfficiency: number = 0.95;
  scrubberMediaPercent: number = 100;

  halonMassKg: number = 5.0;  // Limited resource

  // Telemetry
  totalO2Generated: number = 0;  // kg
  totalCO2Scrubbed: number = 0;  // kg
  fireSuppressionUses: number = 0;

  constructor(config: LifeSupportConfig = {}) {
    // Initialize compartments
    if (config.compartments) {
      this.compartments = config.compartments;
    } else {
      // Default 6-compartment ship layout
      this.compartments = this.createDefaultCompartments();
    }

    // Override defaults
    if (config.o2GeneratorRateLPerMin !== undefined) this.o2GeneratorRateLPerMin = config.o2GeneratorRateLPerMin;
    if (config.co2ScrubberEfficiency !== undefined) this.co2ScrubberEfficiency = config.co2ScrubberEfficiency;
    if (config.halonMassKg !== undefined) this.halonMassKg = config.halonMassKg;
    if (config.scrubberMediaPercent !== undefined) this.scrubberMediaPercent = config.scrubberMediaPercent;
    if (config.o2ReservesKg !== undefined) this.o2ReservesKg = config.o2ReservesKg;
  }

  private createDefaultCompartments(): Compartment[] {
    // 6 compartments as designed: Bow, Bridge, Engineering, Port, Center, Stern
    return [
      {
        id: 'bow',
        name: 'Bow',
        volume: 20,
        o2Mass: 5.6,   // Calculated for 101 kPa at 293K
        co2Mass: 0.005,
        n2Mass: 18.1,
        temperature: 293,
        onFire: false,
        fireIntensity: 0,
        breached: false,
        breachSize: 0,
        connections: [
          { compartmentId: 'port', doorOpen: true },
          { compartmentId: 'center', doorOpen: true }
        ]
      },
      {
        id: 'bridge',
        name: 'Bridge',
        volume: 25,
        o2Mass: 7.0,
        co2Mass: 0.006,
        n2Mass: 22.6,
        temperature: 293,
        onFire: false,
        fireIntensity: 0,
        breached: false,
        breachSize: 0,
        connections: [
          { compartmentId: 'center', doorOpen: true }
        ]
      },
      {
        id: 'engineering',
        name: 'Engineering',
        volume: 30,
        o2Mass: 8.4,
        co2Mass: 0.008,
        n2Mass: 27.2,
        temperature: 293,
        onFire: false,
        fireIntensity: 0,
        breached: false,
        breachSize: 0,
        connections: [
          { compartmentId: 'center', doorOpen: true },
          { compartmentId: 'stern', doorOpen: true }
        ]
      },
      {
        id: 'port',
        name: 'Port',
        volume: 15,
        o2Mass: 4.2,
        co2Mass: 0.004,
        n2Mass: 13.6,
        temperature: 293,
        onFire: false,
        fireIntensity: 0,
        breached: false,
        breachSize: 0,
        connections: [
          { compartmentId: 'bow', doorOpen: true },
          { compartmentId: 'center', doorOpen: true }
        ]
      },
      {
        id: 'center',
        name: 'Center',
        volume: 40,
        o2Mass: 11.2,
        co2Mass: 0.010,
        n2Mass: 36.3,
        temperature: 293,
        onFire: false,
        fireIntensity: 0,
        breached: false,
        breachSize: 0,
        connections: [
          { compartmentId: 'bow', doorOpen: true },
          { compartmentId: 'bridge', doorOpen: true },
          { compartmentId: 'engineering', doorOpen: true },
          { compartmentId: 'port', doorOpen: true },
          { compartmentId: 'stern', doorOpen: true }
        ]
      },
      {
        id: 'stern',
        name: 'Stern',
        volume: 20,
        o2Mass: 5.6,
        co2Mass: 0.005,
        n2Mass: 18.1,
        temperature: 293,
        onFire: false,
        fireIntensity: 0,
        breached: false,
        breachSize: 0,
        connections: [
          { compartmentId: 'center', doorOpen: true },
          { compartmentId: 'engineering', doorOpen: true }
        ]
      }
    ];
  }

  /**
   * Main update loop
   */
  update(dt: number): void {
    // O2 generation
    if (this.o2GeneratorActive && this.o2ReservesKg > 0) {
      this.generateO2(dt);
    }

    // CO2 scrubbing
    if (this.co2ScrubberActive && this.scrubberMediaPercent > 0) {
      this.scrubCO2(dt);
    }

    // Per-compartment updates
    for (const comp of this.compartments) {
      // Fire simulation
      if (comp.onFire) {
        this.updateFire(comp, dt);
      }

      // Hull breach venting
      if (comp.breached) {
        this.ventAtmosphere(comp, dt);
      }
    }

    // Gas equalization between connected compartments
    this.equalizeAtmosphere(dt);
  }

  /**
   * Generate O2 from reserves and distribute to compartments
   */
  private generateO2(dt: number): void {
    // Convert L/min at STP to kg/s
    const volumeRate = this.o2GeneratorRateLPerMin / 60; // L/s
    const moles = (this.STP_PRESSURE * (volumeRate / 1000)) / (this.GAS_CONSTANT * this.STP_TEMP);
    const massRate = moles * this.O2_MOLAR_MASS; // kg/s

    const o2ToAdd = massRate * dt;

    if (o2ToAdd > this.o2ReservesKg) {
      // Depleted reserves
      this.o2GeneratorActive = false;
      return;
    }

    this.o2ReservesKg -= o2ToAdd;
    this.totalO2Generated += o2ToAdd;

    // Add to all compartments proportionally by volume
    const totalVolume = this.compartments.reduce((sum, c) => sum + c.volume, 0);
    for (const comp of this.compartments) {
      const fraction = comp.volume / totalVolume;
      comp.o2Mass += o2ToAdd * fraction;
    }
  }

  /**
   * Scrub CO2 from all compartments
   */
  private scrubCO2(dt: number): void {
    const scrubRate = this.co2ScrubberEfficiency * 0.001; // kg/s max

    for (const comp of this.compartments) {
      const co2ToRemove = Math.min(comp.co2Mass, scrubRate * dt);
      comp.co2Mass -= co2ToRemove;
      this.totalCO2Scrubbed += co2ToRemove;

      // Degrade scrubber media
      this.scrubberMediaPercent -= (co2ToRemove / 10) * 100;
      this.scrubberMediaPercent = Math.max(0, this.scrubberMediaPercent);

      if (this.scrubberMediaPercent === 0) {
        this.co2ScrubberActive = false;
        break;
      }
    }
  }

  /**
   * Update fire in compartment
   */
  private updateFire(comp: Compartment, dt: number): void {
    // Fire consumes O2 and produces CO2
    const o2Consumed = this.FIRE_O2_CONSUMPTION_RATE * comp.fireIntensity * dt;
    const co2Produced = this.FIRE_CO2_PRODUCTION_RATE * comp.fireIntensity * dt;

    comp.o2Mass = Math.max(0, comp.o2Mass - o2Consumed);
    comp.co2Mass += co2Produced;

    // Fire generates heat
    comp.temperature += (this.FIRE_HEAT_GENERATION * comp.fireIntensity * dt) / (this.getTotalMass(comp) * 1000); // Rough heat capacity

    // Fire spreads if O2 available
    const o2Percent = this.getO2Percent(comp);
    if (o2Percent > 15 && comp.fireIntensity < 100) {
      comp.fireIntensity += this.FIRE_SPREAD_RATE * dt;
      comp.fireIntensity = Math.min(100, comp.fireIntensity);
    }

    // Fire dies if O2 too low
    if (o2Percent < 10) {
      comp.fireIntensity -= this.FIRE_SPREAD_RATE * 2 * dt;
      comp.fireIntensity = Math.max(0, comp.fireIntensity);
      if (comp.fireIntensity === 0) {
        comp.onFire = false;
      }
    }
  }

  /**
   * Vent atmosphere through breach
   */
  private ventAtmosphere(comp: Compartment, dt: number): void {
    const pressure = this.getPressureKPa(comp) * 1000; // Convert to Pa
    const massFlow = this.VENT_RATE_CONSTANT * comp.breachSize * (pressure / this.STP_PRESSURE) * dt;

    const totalMass = this.getTotalMass(comp);
    if (totalMass === 0) return;

    // Vent gases proportionally
    const o2Fraction = comp.o2Mass / totalMass;
    const co2Fraction = comp.co2Mass / totalMass;
    const n2Fraction = comp.n2Mass / totalMass;

    comp.o2Mass = Math.max(0, comp.o2Mass - massFlow * o2Fraction);
    comp.co2Mass = Math.max(0, comp.co2Mass - massFlow * co2Fraction);
    comp.n2Mass = Math.max(0, comp.n2Mass - massFlow * n2Fraction);

    // Venting cools the compartment
    comp.temperature -= 0.1 * dt; // Simple cooling model
    comp.temperature = Math.max(253, comp.temperature); // Can't go below freezing
  }

  /**
   * Equalize atmosphere between connected compartments with open doors
   */
  private equalizeAtmosphere(dt: number): void {
    const equalizationRate = 0.1; // Fraction per second

    for (const comp of this.compartments) {
      for (const conn of comp.connections) {
        if (!conn.doorOpen) continue;

        const other = this.compartments.find(c => c.id === conn.compartmentId);
        if (!other) continue;

        // Pressure equalization drives flow
        const p1 = this.getPressureKPa(comp);
        const p2 = this.getPressureKPa(other);

        if (Math.abs(p1 - p2) < 0.1) continue; // Already balanced

        // High pressure flows to low pressure
        const from = p1 > p2 ? comp : other;
        const to = p1 > p2 ? other : comp;

        const flowFraction = equalizationRate * dt;

        // Transfer gases
        const o2Transfer = from.o2Mass * flowFraction;
        const co2Transfer = from.co2Mass * flowFraction;
        const n2Transfer = from.n2Mass * flowFraction;

        from.o2Mass -= o2Transfer;
        from.co2Mass -= co2Transfer;
        from.n2Mass -= n2Transfer;

        to.o2Mass += o2Transfer;
        to.co2Mass += co2Transfer;
        to.n2Mass += n2Transfer;
      }
    }
  }

  /**
   * Calculate total gas mass in compartment
   */
  private getTotalMass(comp: Compartment): number {
    return comp.o2Mass + comp.co2Mass + comp.n2Mass;
  }

  /**
   * Calculate pressure in compartment using ideal gas law
   */
  getPressureKPa(comp: Compartment): number {
    const totalMoles = (comp.o2Mass / this.O2_MOLAR_MASS) +
                      (comp.co2Mass / this.CO2_MOLAR_MASS) +
                      (comp.n2Mass / this.N2_MOLAR_MASS);

    const pressurePa = (totalMoles * this.GAS_CONSTANT * comp.temperature) / comp.volume;
    return pressurePa / 1000; // Convert to kPa
  }

  /**
   * Get O2 percentage
   */
  getO2Percent(comp: Compartment): number {
    const total = this.getTotalMass(comp);
    if (total === 0) return 0;
    return (comp.o2Mass / total) * 100;
  }

  /**
   * Get CO2 percentage
   */
  getCO2Percent(comp: Compartment): number {
    const total = this.getTotalMass(comp);
    if (total === 0) return 0;
    return (comp.co2Mass / total) * 100;
  }

  /**
   * Get N2 percentage
   */
  getN2Percent(comp: Compartment): number {
    const total = this.getTotalMass(comp);
    if (total === 0) return 0;
    return (comp.n2Mass / total) * 100;
  }

  // --- Control Methods ---

  /**
   * Toggle bulkhead door between compartments
   */
  toggleDoor(comp1Id: string, comp2Id: string): boolean {
    const comp = this.compartments.find(c => c.id === comp1Id);
    if (!comp) return false;

    const conn = comp.connections.find(c => c.compartmentId === comp2Id);
    if (!conn) return false;

    conn.doorOpen = !conn.doorOpen;

    // Also update the reverse connection
    const otherComp = this.compartments.find(c => c.id === comp2Id);
    if (otherComp) {
      const reverseConn = otherComp.connections.find(c => c.compartmentId === comp1Id);
      if (reverseConn) {
        reverseConn.doorOpen = conn.doorOpen;
      }
    }

    return conn.doorOpen;
  }

  /**
   * Fire suppression (uses Halon)
   */
  fireSuppress(compId: string): boolean {
    const comp = this.compartments.find(c => c.id === compId);
    if (!comp || !comp.onFire) return false;

    if (this.halonMassKg < 0.5) return false; // Not enough

    const halionUsed = 0.5; // kg per use
    this.halonMassKg -= halionUsed;
    this.fireSuppressionUses++;

    comp.fireIntensity -= this.HALON_EFFECTIVENESS * halionUsed;
    comp.fireIntensity = Math.max(0, comp.fireIntensity);

    if (comp.fireIntensity === 0) {
      comp.onFire = false;
    }

    return true;
  }

  /**
   * Emergency vent compartment to space
   */
  emergencyVent(compId: string): boolean {
    const comp = this.compartments.find(c => c.id === compId);
    if (!comp) return false;

    // Vent all atmosphere
    comp.o2Mass = 0;
    comp.co2Mass = 0;
    comp.n2Mass = 0;
    comp.temperature = 253; // Near freezing

    // Kills fire instantly
    comp.onFire = false;
    comp.fireIntensity = 0;

    return true;
  }

  /**
   * Seal hull breach (uses repair kit)
   */
  sealBreach(compId: string): boolean {
    const comp = this.compartments.find(c => c.id === compId);
    if (!comp || !comp.breached) return false;

    comp.breached = false;
    comp.breachSize = 0;

    return true;
  }

  /**
   * Cause hull breach (for events/testing)
   */
  causeBreach(compId: string, sizeM2: number): boolean {
    const comp = this.compartments.find(c => c.id === compId);
    if (!comp) return false;

    comp.breached = true;
    comp.breachSize = sizeM2;

    return true;
  }

  /**
   * Start fire in compartment (for events/testing)
   */
  startFire(compId: string, intensity: number = 20): boolean {
    const comp = this.compartments.find(c => c.id === compId);
    if (!comp) return false;

    comp.onFire = true;
    comp.fireIntensity = intensity;

    return true;
  }

  /**
   * Set O2 generator rate
   */
  setO2GeneratorRate(ratePerMin: number): void {
    this.o2GeneratorRateLPerMin = Math.max(0, Math.min(3.0, ratePerMin)); // 0-3 L/min
  }

  /**
   * Get system state for telemetry
   */
  getState() {
    return {
      compartments: this.compartments.map(c => ({
        id: c.id,
        name: c.name,
        volume: c.volume,
        o2Percent: this.getO2Percent(c),
        co2Percent: this.getCO2Percent(c),
        n2Percent: this.getN2Percent(c),
        pressureKPa: this.getPressureKPa(c),
        temperature: c.temperature,
        onFire: c.onFire,
        fireIntensity: c.fireIntensity,
        breached: c.breached,
        breachSize: c.breachSize,
        doors: c.connections.map(conn => ({
          to: conn.compartmentId,
          open: conn.doorOpen
        }))
      })),
      o2Generator: {
        active: this.o2GeneratorActive,
        rateLPerMin: this.o2GeneratorRateLPerMin,
        reservesKg: this.o2ReservesKg,
        totalGenerated: this.totalO2Generated
      },
      co2Scrubber: {
        active: this.co2ScrubberActive,
        efficiency: this.co2ScrubberEfficiency,
        mediaPercent: this.scrubberMediaPercent,
        totalScrubbed: this.totalCO2Scrubbed
      },
      halon: {
        remainingKg: this.halonMassKg,
        usesCount: this.fireSuppressionUses
      }
    };
  }
}
