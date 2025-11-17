/**
 * Energy Weapons System
 *
 * Implements directed energy weapons including:
 * - Pulse and Continuous Wave Lasers
 * - Particle Beams (charged and neutral)
 * - Beam divergence and diffraction physics
 * - Thermal damage mechanics
 * - Power and cooling requirements
 * - Target reflectivity and countermeasures
 */

export type EnergyWeaponType = 'pulse_laser' | 'cw_laser' | 'particle_beam' | 'plasma_cannon';
export type LaserWavelength = 'UV' | 'visible' | 'IR' | 'X-ray';
export type BeamStatus = 'idle' | 'charging' | 'firing' | 'cooling' | 'overheated' | 'damaged';

/**
 * Laser system
 */
export interface LaserSystem {
  id: string;
  name: string;
  type: 'pulse_laser' | 'cw_laser';

  // Specifications
  peakPower: number; // Watts
  pulseDuration: number; // seconds (0 for CW)
  pulseRate: number; // Hz (0 for CW)
  wavelength: number; // nanometers
  apertureDiameter: number; // meters
  beamDivergence: number; // radians

  // Operational state
  status: BeamStatus;
  temperature: number; // Kelvin
  maxTemperature: number; // Kelvin
  coolingRate: number; // K/s

  // Power
  electricalPower: number; // W input (includes inefficiency)
  efficiency: number; // 0-1, typically 0.2-0.4 for lasers
  capacitorCharge: number; // 0-1 for pulse lasers
  capacitorChargeRate: number; // per second

  // Firing state
  firing: boolean;
  dwellTime: number; // seconds on current target
  shotsFired: number;
}

/**
 * Particle beam system
 */
export interface ParticleBeamSystem {
  id: string;
  name: string;
  type: 'neutral' | 'charged';

  // Specifications
  particleEnergy: number; // MeV
  beamCurrent: number; // mA
  power: number; // MW
  range: number; // km
  beamSpread: number; // mrad

  // Operational state
  status: BeamStatus;
  temperature: number; // K
  maxTemperature: number; // K
  coolingRate: number; // K/s

  // Power
  electricalPower: number; // MW
  efficiency: number; // 0-1, typically 0.1-0.3
  capacitorCharge: number; // 0-1
  capacitorChargeRate: number; // per second

  // Firing
  firing: boolean;
  pulseLength: number; // seconds
}

/**
 * Energy weapon damage calculation
 */
export interface EnergyDamage {
  thermalDamage: number; // Kelvin temperature rise
  ablationDepth: number; // mm of material removed
  structuralDamage: number; // 0-1 structural integrity loss
  radiationDamage: number; // rads (for particle beams)
  EM_damage: number; // electronics damage (for particle beams)
}

/**
 * Laser weapon class
 */
export class LaserWeapon {
  private system: LaserSystem;
  private currentTarget: { x: number; y: number; z: number } | null = null;
  private heatGeneration: number = 0; // W

  constructor(config: {
    id: string;
    name: string;
    type: 'pulse_laser' | 'cw_laser';
    peakPower: number;
    wavelength: LaserWavelength;
    apertureDiameter: number;
  }) {
    const wavelengthNm = this.getWavelength(config.wavelength);

    this.system = {
      id: config.id,
      name: config.name,
      type: config.type,
      peakPower: config.peakPower,
      pulseDuration: config.type === 'pulse_laser' ? 0.1 : 0, // 100ms pulse
      pulseRate: config.type === 'pulse_laser' ? 1 : 0, // 1 Hz
      wavelength: wavelengthNm,
      apertureDiameter: config.apertureDiameter,
      beamDivergence: this.calculateDivergence(wavelengthNm, config.apertureDiameter),
      status: 'idle',
      temperature: 293,
      maxTemperature: 400,
      coolingRate: 100,
      electricalPower: 0,
      efficiency: 0.25, // 25% typical for good laser
      capacitorCharge: config.type === 'pulse_laser' ? 0 : 1,
      capacitorChargeRate: 0.05, // 20 second charge
      firing: false,
      dwellTime: 0,
      shotsFired: 0
    };
  }

  /**
   * Get wavelength in nm
   */
  private getWavelength(type: LaserWavelength): number {
    const wavelengths = {
      'UV': 300,
      'visible': 550,
      'IR': 1064,
      'X-ray': 0.1
    };
    return wavelengths[type];
  }

  /**
   * Calculate beam divergence using diffraction limit
   * θ = 1.22 × λ / D
   */
  private calculateDivergence(wavelengthNm: number, apertureDiameter: number): number {
    const wavelengthM = wavelengthNm * 1e-9;
    return 1.22 * wavelengthM / apertureDiameter; // radians
  }

  /**
   * Calculate spot size at range
   * spot_radius = range × tan(divergence/2) ≈ range × divergence/2
   */
  private calculateSpotSize(rangeKm: number): number {
    const rangeM = rangeKm * 1000;
    return rangeM * this.system.beamDivergence; // meters radius
  }

  /**
   * Calculate power density on target
   * Power density = Power / spot_area
   */
  private calculatePowerDensity(rangeKm: number): number {
    const spotRadius = this.calculateSpotSize(rangeKm);
    const spotArea = Math.PI * spotRadius * spotRadius; // m²
    return this.system.peakPower / spotArea; // W/m²
  }

  /**
   * Calculate damage to target
   */
  public calculateDamage(
    rangeKm: number,
    dwellTime: number,
    targetReflectivity: number = 0.1, // 0-1, higher = more reflective
    targetMaterial: {
      density: number; // kg/m³
      specificHeat: number; // J/(kg·K)
      ablationEnergy: number; // J/kg
    } = {
      density: 2700, // Aluminum
      specificHeat: 900,
      ablationEnergy: 10000000 // 10 MJ/kg
    }
  ): EnergyDamage {
    const powerDensity = this.calculatePowerDensity(rangeKm);
    const spotSize = this.calculateSpotSize(rangeKm);
    const spotArea = Math.PI * spotSize * spotSize;

    // Energy delivered
    const totalEnergy = this.system.peakPower * dwellTime; // Joules
    const energyAbsorbed = totalEnergy * (1 - targetReflectivity);

    // Thermal damage
    // Simplified: assume 1cm³ volume heated
    const heatedVolume = spotArea * 0.01; // m³
    const heatedMass = heatedVolume * targetMaterial.density; // kg
    const temperatureRise = energyAbsorbed / (heatedMass * targetMaterial.specificHeat); // Kelvin

    // Ablation (material removal)
    const ablationEnergy = Math.max(0, energyAbsorbed - heatedMass * targetMaterial.specificHeat * 1000);
    const ablatedMass = ablationEnergy / targetMaterial.ablationEnergy; // kg
    const ablationDepth = (ablatedMass / targetMaterial.density) / spotArea * 1000; // mm

    // Structural damage (simplified)
    const structuralDamage = Math.min(1.0, ablationDepth / 100); // 10cm = total failure

    return {
      thermalDamage: temperatureRise,
      ablationDepth: ablationDepth,
      structuralDamage: structuralDamage,
      radiationDamage: 0, // Lasers don't cause radiation damage
      EM_damage: 0
    };
  }

  /**
   * Begin firing at target
   */
  public startFiring(targetPos: { x: number; y: number; z: number }): boolean {
    if (this.system.status === 'overheated' || this.system.status === 'damaged') {
      return false;
    }

    if (this.system.type === 'pulse_laser' && this.system.capacitorCharge < 1.0) {
      return false; // Not charged
    }

    this.system.firing = true;
    this.system.status = 'firing';
    this.currentTarget = { ...targetPos };
    this.system.dwellTime = 0;

    return true;
  }

  /**
   * Stop firing
   */
  public stopFiring(): void {
    this.system.firing = false;
    this.system.status = 'cooling';
    this.currentTarget = null;
    this.system.dwellTime = 0;
  }

  /**
   * Fire a pulse (for pulse lasers)
   */
  public firePulse(): boolean {
    if (this.system.type !== 'pulse_laser') {
      return false;
    }

    if (this.system.capacitorCharge < 1.0) {
      return false;
    }

    this.system.capacitorCharge = 0;
    this.system.shotsFired++;
    this.system.temperature += 50; // Heat per shot

    return true;
  }

  /**
   * Update laser system
   */
  public update(dt: number): void {
    // Charging
    if (this.system.type === 'pulse_laser' && this.system.capacitorCharge < 1.0) {
      this.system.capacitorCharge = Math.min(1.0,
        this.system.capacitorCharge + this.system.capacitorChargeRate * dt);
      this.system.status = 'charging';
    }

    // Firing
    if (this.system.firing) {
      this.system.dwellTime += dt;

      // Heat generation
      const wastePower = this.system.peakPower * (1 / this.system.efficiency - 1);
      this.system.temperature += (wastePower / 10000) * dt; // Simplified heating

      // Power consumption
      this.system.electricalPower = this.system.peakPower / this.system.efficiency;
    } else {
      this.system.electricalPower = this.system.capacitorChargeRate *
                                      this.system.peakPower / this.system.efficiency;
    }

    // Cooling
    if (this.system.temperature > 293) {
      this.system.temperature = Math.max(293,
        this.system.temperature - this.system.coolingRate * dt);
    }

    // Overheating
    if (this.system.temperature >= this.system.maxTemperature) {
      this.system.status = 'overheated';
      this.system.firing = false;
    } else if (this.system.status === 'overheated' &&
               this.system.temperature < this.system.maxTemperature * 0.7) {
      this.system.status = 'idle';
    }
  }

  /**
   * Get effective range
   */
  public getEffectiveRange(): number {
    // Range where power density is still useful (> 1 MW/m²)
    const minPowerDensity = 1000000; // W/m²
    let range = 1; // km

    while (range < 1000) {
      const powerDensity = this.calculatePowerDensity(range);
      if (powerDensity < minPowerDensity) {
        return range;
      }
      range += 10;
    }

    return 1000; // Max 1000 km
  }

  /**
   * Get laser state
   */
  public getState() {
    return {
      id: this.system.id,
      name: this.system.name,
      type: this.system.type,
      status: this.system.status,
      firing: this.system.firing,

      // Power
      peakPower: this.system.peakPower / 1000000, // MW
      electricalPower: this.system.electricalPower / 1000000, // MW
      efficiency: this.system.efficiency,

      // Thermal
      temperature: this.system.temperature,
      maxTemperature: this.system.maxTemperature,
      temperaturePercent: (this.system.temperature - 293) / (this.system.maxTemperature - 293),

      // Charging (pulse laser)
      capacitorCharge: this.system.capacitorCharge,
      ready: this.system.capacitorCharge >= 1.0 || this.system.type === 'cw_laser',

      // Performance
      wavelength: this.system.wavelength,
      divergence: this.system.beamDivergence * 1000000, // µrad
      effectiveRange: this.getEffectiveRange(),

      // Firing
      dwellTime: this.system.dwellTime,
      shotsFired: this.system.shotsFired
    };
  }
}

/**
 * Particle beam weapon
 */
export class ParticleBeamWeapon {
  private system: ParticleBeamSystem;
  private currentTarget: { x: number; y: number; z: number } | null = null;

  constructor(config: {
    id: string;
    name: string;
    type: 'neutral' | 'charged';
    particleEnergy: number; // MeV
    beamCurrent: number; // mA
  }) {
    const power = config.particleEnergy * config.beamCurrent / 1000; // MW

    this.system = {
      id: config.id,
      name: config.name,
      type: config.type,
      particleEnergy: config.particleEnergy,
      beamCurrent: config.beamCurrent,
      power: power,
      range: config.type === 'neutral' ? 1000 : 100, // Neutral beams longer range
      beamSpread: config.type === 'neutral' ? 0.1 : 1.0, // mrad
      status: 'idle',
      temperature: 293,
      maxTemperature: 500,
      coolingRate: 200,
      electricalPower: power / 0.2, // 20% efficiency
      efficiency: 0.2,
      capacitorCharge: 0,
      capacitorChargeRate: 0.02, // 50 second charge
      firing: false,
      pulseLength: 0.5 // 500ms pulse
    };
  }

  /**
   * Calculate particle beam damage
   */
  public calculateDamage(
    rangeKm: number,
    pulseLength: number
  ): EnergyDamage {
    // Particle energy deposition
    const energyDeposited = this.system.power * 1000000 * pulseLength; // Joules

    // Radiation damage (particle beams cause ionization)
    const radiationDamage = this.system.particleEnergy * this.system.beamCurrent * pulseLength;

    // EM damage (charged particles induce currents)
    const emDamage = this.system.type === 'charged' ?
      this.system.beamCurrent * pulseLength * 0.1 : 0;

    // Thermal (particles deposit energy as heat)
    const thermalDamage = energyDeposited / 1000; // Simplified

    // Structural (deep penetration damage)
    const structuralDamage = Math.min(1.0, radiationDamage / 10000);

    return {
      thermalDamage: thermalDamage,
      ablationDepth: 0, // Particles don't ablate like lasers
      structuralDamage: structuralDamage,
      radiationDamage: radiationDamage,
      EM_damage: emDamage
    };
  }

  /**
   * Fire particle beam
   */
  public fire(): boolean {
    if (this.system.status === 'overheated' || this.system.status === 'damaged') {
      return false;
    }

    if (this.system.capacitorCharge < 1.0) {
      return false;
    }

    this.system.firing = true;
    this.system.status = 'firing';
    this.system.capacitorCharge = 0;
    this.system.temperature += 100;

    // Auto-stop after pulse length
    setTimeout(() => {
      this.system.firing = false;
      this.system.status = 'cooling';
    }, this.system.pulseLength * 1000);

    return true;
  }

  /**
   * Update particle beam
   */
  public update(dt: number): void {
    // Charging
    if (this.system.capacitorCharge < 1.0) {
      this.system.capacitorCharge = Math.min(1.0,
        this.system.capacitorCharge + this.system.capacitorChargeRate * dt);
      this.system.status = 'charging';
    }

    // Power consumption
    if (this.system.firing) {
      this.system.electricalPower = this.system.power / this.system.efficiency;
    } else {
      this.system.electricalPower = this.system.capacitorChargeRate *
                                      this.system.power / this.system.efficiency * 0.1;
    }

    // Cooling
    if (this.system.temperature > 293) {
      this.system.temperature = Math.max(293,
        this.system.temperature - this.system.coolingRate * dt);
    }

    // Overheating
    if (this.system.temperature >= this.system.maxTemperature) {
      this.system.status = 'overheated';
      this.system.firing = false;
    } else if (this.system.status === 'overheated' &&
               this.system.temperature < this.system.maxTemperature * 0.6) {
      this.system.status = 'idle';
    }
  }

  /**
   * Get particle beam state
   */
  public getState() {
    return {
      id: this.system.id,
      name: this.system.name,
      type: this.system.type,
      status: this.system.status,
      firing: this.system.firing,

      // Power
      power: this.system.power, // MW
      electricalPower: this.system.electricalPower, // MW
      particleEnergy: this.system.particleEnergy, // MeV
      beamCurrent: this.system.beamCurrent, // mA

      // Thermal
      temperature: this.system.temperature,
      maxTemperature: this.system.maxTemperature,
      temperaturePercent: (this.system.temperature - 293) / (this.system.maxTemperature - 293),

      // Charging
      capacitorCharge: this.system.capacitorCharge,
      ready: this.system.capacitorCharge >= 1.0,

      // Performance
      range: this.system.range,
      pulseLength: this.system.pulseLength
    };
  }
}
