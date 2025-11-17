/**
 * Electronic Warfare (EW) Subsystem
 *
 * Simulates:
 * - Electronic Support Measures (ESM) - passive detection and analysis
 * - Electronic Attack (EA) - active jamming and deception
 * - Electronic Protection (EP) - defending against hostile EW
 * - Radar warning receiver (RWR)
 * - Signal intelligence (SIGINT) gathering
 * - Emissions control (EMCON)
 * - Threat library and identification
 * - Jamming effectiveness calculations
 */

export interface ThreatEmitter {
  id: string;
  type: 'radar' | 'missile_seeker' | 'targeting_laser' | 'communications';
  frequencyGHz: number;
  strength: number; // 0-1, signal strength
  bearing: number; // degrees
  identified: boolean;
  threatLevel: 'low' | 'medium' | 'high' | 'critical';
  trackingUs: boolean;
}

export interface JammerUnit {
  id: string;
  type: 'noise' | 'deception' | 'barrage';
  frequencyRangeGHz: { min: number; max: number };
  effectivePowerW: number;
  active: boolean;
  targetEmitterId: string | null;
  effectiveness: number; // 0-1
}

export interface EWConfig {
  esmSensitivity?: number; // Detection range multiplier
  jammerPowerW?: number;
  jammerCount?: number;
  threatLibrarySize?: number;
  processingPowerGflops?: number;
  powerConsumptionW?: number;
}

export class ElectronicWarfareSystem {
  // ESM (Electronic Support Measures) - Passive Detection
  public esmSensitivity: number;
  public detectedEmitters: Map<string, ThreatEmitter>;
  public threatLibrary: Set<string>; // Known threat signatures
  public rwr: {
    active: boolean;
    detectionRangeKm: number;
    audioAlerts: boolean;
  };

  // EA (Electronic Attack) - Active Jamming
  public jammers: Map<string, JammerUnit>;
  public jammerPowerW: number;

  // EP (Electronic Protection) - Defensive measures
  public emconLevel: 'unrestricted' | 'reduced' | 'minimal' | 'silent';
  public frequencyHoppingEnabled: boolean;
  public spreadSpectrumEnabled: boolean;

  // Signal Intelligence
  public sigintBuffer: Array<{
    timestamp: number;
    emitter: ThreatEmitter;
    interceptedData: any;
  }>;
  public sigintCapacity: number = 100;

  // Processing
  public processingPowerGflops: number;
  public processingLoad: number = 0; // 0-1

  // State
  public operational: boolean = true;
  public isPowered: boolean = true;

  // Power tracking
  public currentPowerDraw: number = 0; // W
  public basePowerDraw: number = 50; // W (ESM receivers)
  public powerConsumptionW: number;

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor(config?: EWConfig) {
    this.esmSensitivity = config?.esmSensitivity || 1.0;
    this.jammerPowerW = config?.jammerPowerW || 1000.0;
    this.processingPowerGflops = config?.processingPowerGflops || 100.0;
    this.powerConsumptionW = config?.powerConsumptionW || 500.0;

    this.detectedEmitters = new Map();
    this.jammers = new Map();
    this.threatLibrary = new Set();
    this.sigintBuffer = [];

    this.rwr = {
      active: true,
      detectionRangeKm: 200,
      audioAlerts: true
    };

    this.emconLevel = 'unrestricted';
    this.frequencyHoppingEnabled = true;
    this.spreadSpectrumEnabled = true;

    // Create default jammers
    this.createDefaultJammers(config?.jammerCount || 3);

    // Build default threat library
    this.buildThreatLibrary(config?.threatLibrarySize || 50);

    this.currentPowerDraw = this.basePowerDraw;
  }

  private createDefaultJammers(count: number): void {
    const jammerTypes: Array<JammerUnit['type']> = ['noise', 'deception', 'barrage'];

    for (let i = 0; i < count; i++) {
      const type = jammerTypes[i % jammerTypes.length];
      this.jammers.set(`jammer_${i}`, {
        id: `jammer_${i}`,
        type,
        frequencyRangeGHz: this.getFrequencyRangeForType(type),
        effectivePowerW: this.jammerPowerW,
        active: false,
        targetEmitterId: null,
        effectiveness: 0
      });
    }
  }

  private getFrequencyRangeForType(type: JammerUnit['type']): { min: number; max: number } {
    switch (type) {
      case 'noise':
        return { min: 2.0, max: 18.0 }; // Wide band
      case 'deception':
        return { min: 8.0, max: 12.0 }; // X-band (common radar)
      case 'barrage':
        return { min: 1.0, max: 40.0 }; // Very wide band
      default:
        return { min: 2.0, max: 18.0 };
    }
  }

  private buildThreatLibrary(size: number): void {
    // Add known threat signatures
    for (let i = 0; i < size; i++) {
      this.threatLibrary.add(`threat_signature_${i}`);
    }
  }

  /**
   * Detect and analyze emitter (passive ESM)
   */
  public detectEmitter(emitter: ThreatEmitter, rangeKm: number): boolean {
    if (!this.operational || !this.isPowered || !this.rwr.active) {
      return false;
    }

    // Check if in detection range
    const effectiveRange = this.rwr.detectionRangeKm * this.esmSensitivity;
    if (rangeKm > effectiveRange) {
      return false;
    }

    // Detect and analyze
    const existingEmitter = this.detectedEmitters.get(emitter.id);

    if (!existingEmitter) {
      // New detection
      emitter.identified = this.identifyThreat(emitter);
      this.detectedEmitters.set(emitter.id, emitter);

      this.logEvent('emitter_detected', {
        id: emitter.id,
        type: emitter.type,
        bearing: emitter.bearing,
        identified: emitter.identified
      });

      // Audio alert for high threats
      if (this.rwr.audioAlerts && emitter.threatLevel === 'critical') {
        this.logEvent('rwr_alert', { emitter: emitter.id, threatLevel: emitter.threatLevel });
      }
    } else {
      // Update existing emitter
      existingEmitter.strength = emitter.strength;
      existingEmitter.bearing = emitter.bearing;
      existingEmitter.trackingUs = emitter.trackingUs;
    }

    return true;
  }

  /**
   * Identify threat using threat library
   */
  private identifyThreat(emitter: ThreatEmitter): boolean {
    // Simplified - would use frequency, pulse characteristics, etc.
    const signature = `${emitter.type}_${Math.floor(emitter.frequencyGHz)}`;
    return this.threatLibrary.has(signature) || Math.random() > 0.3;
  }

  /**
   * Activate jammer against specific emitter
   */
  public activateJammer(jammerId: string, targetEmitterId: string): boolean {
    if (!this.operational || !this.isPowered) {
      this.logEvent('jammer_failed', { reason: 'system_offline', jammerId });
      return false;
    }

    const jammer = this.jammers.get(jammerId);
    if (!jammer) {
      this.logEvent('jammer_failed', { reason: 'invalid_jammer', jammerId });
      return false;
    }

    const target = this.detectedEmitters.get(targetEmitterId);
    if (!target) {
      this.logEvent('jammer_failed', { reason: 'target_not_detected', targetEmitterId });
      return false;
    }

    // Check if jammer can cover target frequency
    if (target.frequencyGHz < jammer.frequencyRangeGHz.min ||
        target.frequencyGHz > jammer.frequencyRangeGHz.max) {
      this.logEvent('jammer_failed', {
        reason: 'frequency_mismatch',
        targetFreq: target.frequencyGHz,
        jammerRange: jammer.frequencyRangeGHz
      });
      return false;
    }

    jammer.active = true;
    jammer.targetEmitterId = targetEmitterId;
    jammer.effectiveness = this.calculateJammingEffectiveness(jammer, target);

    this.updatePowerDraw();
    this.logEvent('jammer_activated', {
      jammerId,
      targetId: targetEmitterId,
      effectiveness: jammer.effectiveness
    });

    return true;
  }

  /**
   * Calculate jamming effectiveness
   */
  private calculateJammingEffectiveness(jammer: JammerUnit, target: ThreatEmitter): number {
    // Simplified jamming equation
    // Effectiveness depends on jammer power vs signal strength and type
    const powerRatio = jammer.effectivePowerW / (target.strength * 1000);

    let baseEffectiveness = Math.min(1.0, powerRatio / 10.0);

    // Type-specific modifiers
    switch (jammer.type) {
      case 'noise':
        baseEffectiveness *= 0.8; // Less effective but works on everything
        break;
      case 'deception':
        baseEffectiveness *= 1.2; // More effective if frequency matches
        break;
      case 'barrage':
        baseEffectiveness *= 0.6; // Spreads power thin
        break;
    }

    return Math.max(0, Math.min(1.0, baseEffectiveness));
  }

  /**
   * Deactivate jammer
   */
  public deactivateJammer(jammerId: string): void {
    const jammer = this.jammers.get(jammerId);
    if (!jammer) return;

    jammer.active = false;
    jammer.targetEmitterId = null;
    jammer.effectiveness = 0;

    this.updatePowerDraw();
    this.logEvent('jammer_deactivated', { jammerId });
  }

  /**
   * Set EMCON (Emissions Control) level
   */
  public setEmconLevel(level: ElectronicWarfareSystem['emconLevel']): void {
    this.emconLevel = level;
    this.logEvent('emcon_set', { level });

    // Different levels affect our detectability
    // 'silent' = completely passive, no transmissions
    // 'minimal' = only essential comms
    // 'reduced' = limited radar/active sensors
    // 'unrestricted' = all systems active
  }

  /**
   * Intercept and analyze signals (SIGINT)
   */
  public interceptSignal(emitter: ThreatEmitter, data: any): void {
    if (!this.operational || !this.isPowered) return;

    // Add to SIGINT buffer
    this.sigintBuffer.push({
      timestamp: Date.now(),
      emitter: { ...emitter },
      interceptedData: data
    });

    // Maintain buffer size
    if (this.sigintBuffer.length > this.sigintCapacity) {
      this.sigintBuffer.shift();
    }

    this.logEvent('signal_intercepted', {
      emitterId: emitter.id,
      type: emitter.type
    });
  }

  /**
   * Get threat assessment
   */
  public getThreatAssessment(): {
    totalThreats: number;
    criticalThreats: number;
    highThreats: number;
    trackingThreats: number;
    activeJammers: number;
  } {
    let critical = 0;
    let high = 0;
    let tracking = 0;

    this.detectedEmitters.forEach(emitter => {
      if (emitter.threatLevel === 'critical') critical++;
      if (emitter.threatLevel === 'high') high++;
      if (emitter.trackingUs) tracking++;
    });

    let activeJammers = 0;
    this.jammers.forEach(jammer => {
      if (jammer.active) activeJammers++;
    });

    return {
      totalThreats: this.detectedEmitters.size,
      criticalThreats: critical,
      highThreats: high,
      trackingThreats: tracking,
      activeJammers
    };
  }

  /**
   * Update power consumption
   */
  private updatePowerDraw(): void {
    let totalPower = this.basePowerDraw;

    // Add power for active jammers
    this.jammers.forEach(jammer => {
      if (jammer.active) {
        totalPower += jammer.effectivePowerW;
      }
    });

    this.currentPowerDraw = totalPower;
  }

  /**
   * Update EW system
   */
  public update(dt: number): void {
    if (!this.isPowered) {
      this.operational = false;
      this.currentPowerDraw = 0;
      this.rwr.active = false;
      this.jammers.forEach(j => {
        j.active = false;
      });
      return;
    }

    if (!this.operational) return;

    // Update processing load
    const detectionLoad = this.detectedEmitters.size * 0.01;
    const jammingLoad = Array.from(this.jammers.values()).filter(j => j.active).length * 0.1;
    this.processingLoad = Math.min(1.0, detectionLoad + jammingLoad);

    // Age out old detections (simple timeout)
    const now = Date.now();
    this.detectedEmitters.forEach((emitter, id) => {
      // Would normally track last update time
      // For now, this is a placeholder
    });
  }

  /**
   * Apply damage
   */
  public applyDamage(severity: number, componentId?: string): void {
    if (componentId) {
      const jammer = this.jammers.get(componentId);
      if (jammer) {
        jammer.active = false;
        jammer.effectivePowerW *= (1 - severity);
        this.logEvent('jammer_damaged', { componentId, severity });
        this.updatePowerDraw();
        return;
      }
    }

    if (severity > 0.7) {
      this.operational = false;
      this.rwr.active = false;
      this.logEvent('ew_system_destroyed', { severity });
    } else if (severity > 0.4) {
      this.esmSensitivity *= (1 - severity);
      this.rwr.detectionRangeKm *= (1 - severity);
      this.logEvent('ew_system_degraded', { severity, newSensitivity: this.esmSensitivity });
    }
  }

  /**
   * Repair system
   */
  public repair(componentId?: string): void {
    if (componentId) {
      const jammer = this.jammers.get(componentId);
      if (jammer) {
        jammer.effectivePowerW = this.jammerPowerW;
        this.logEvent('jammer_repaired', { componentId });
        return;
      }
    }

    this.operational = true;
    this.rwr.active = true;
    this.esmSensitivity = 1.0;
    this.rwr.detectionRangeKm = 200;
    this.logEvent('ew_system_repaired', {});
  }

  /**
   * Set power state
   */
  public setPower(powered: boolean): void {
    this.isPowered = powered;
    if (!powered) {
      this.currentPowerDraw = 0;
      this.rwr.active = false;
    } else {
      this.rwr.active = true;
      this.updatePowerDraw();
    }
  }

  public getState() {
    const emittersArray: any[] = [];
    this.detectedEmitters.forEach((emitter, id) => {
      emittersArray.push({ ...emitter });
    });

    const jammersArray: any[] = [];
    this.jammers.forEach((jammer, id) => {
      jammersArray.push({ ...jammer });
    });

    return {
      operational: this.operational,
      isPowered: this.isPowered,
      detectedEmitters: emittersArray,
      jammers: jammersArray,
      rwr: { ...this.rwr },
      emconLevel: this.emconLevel,
      threatAssessment: this.getThreatAssessment(),
      processingLoad: this.processingLoad,
      sigintBufferSize: this.sigintBuffer.length,
      powerDraw: this.currentPowerDraw
    };
  }

  private logEvent(type: string, data: any): void {
    this.events.push({ time: Date.now(), type, data });
  }
}
