/**
 * ESM (Electronic Support Measures) / ELINT (Electronic Intelligence) System
 *
 * Passive detection of electronic emissions:
 * - Radar emissions detection
 * - Radio communications intercept
 * - Electromagnetic signature analysis
 * - Direction finding
 * - Signal classification
 * - Long-range passive detection
 * - Completely passive (no emissions)
 */

export type ESMMode = 'wide_band' | 'narrow_band' | 'scan' | 'standby' | 'off';
export type EmissionType = 'radar' | 'communications' | 'datalink' | 'jammer' | 'unknown';

export interface ESMContact {
  id: string;
  bearing: number; // degrees from ship forward
  frequency: number; // GHz
  bandwidth: number; // MHz
  power: number; // dBm (received power)
  emissionType: EmissionType;
  pulseRepFreq: number | null; // Hz (for radar)
  modulation: string; // Modulation type
  confidence: number; // 0-1, classification confidence
  firstDetection: number; // timestamp
  lastUpdate: number; // timestamp
  signalStrength: number; // dB above noise floor
}

export interface ESMConfiguration {
  frequencyRangeGHz?: [number, number]; // Min and max frequency
  antennaGainDB?: number;
  systemNoiseFigureDB?: number;
  directionFindingAccuracy?: number; // degrees
  sensitivityDBm?: number;
}

export class ESMSystem {
  // Configuration
  private frequencyRangeGHz: [number, number];
  private antennaGainDB: number;
  private systemNoiseFigureDB: number;
  private directionFindingAccuracy: number;
  private sensitivityDBm: number;

  // State
  public mode: ESMMode = 'scan';
  public powered: boolean = true;
  public operational: boolean = true;

  // Detection
  private contacts: Map<string, ESMContact> = new Map();

  // Scan
  private scanFrequencyGHz: number = 10; // Current frequency
  private scanRate: number = 5; // GHz/second

  // Power
  private currentPowerDraw: number = 0;

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  // Signal library for classification
  private signalLibrary: Map<string, {
    emissionType: EmissionType;
    freqRange: [number, number];
    prf: number | null;
    modulation: string;
  }> = new Map();

  constructor(config?: ESMConfiguration) {
    this.frequencyRangeGHz = config?.frequencyRangeGHz || [1, 40]; // 1-40 GHz
    this.antennaGainDB = config?.antennaGainDB || 10; // 10 dB
    this.systemNoiseFigureDB = config?.systemNoiseFigureDB || 8; // 8 dB noise figure
    this.directionFindingAccuracy = config?.directionFindingAccuracy || 5; // ±5 degrees
    this.sensitivityDBm = config?.sensitivityDBm || -90; // -90 dBm sensitivity

    this.initializeSignalLibrary();
  }

  /**
   * Initialize known signal types
   */
  private initializeSignalLibrary(): void {
    // Radar signatures
    this.signalLibrary.set('search_radar', {
      emissionType: 'radar',
      freqRange: [8, 12], // X-band
      prf: 1000, // 1 kHz
      modulation: 'pulse'
    });

    this.signalLibrary.set('tracking_radar', {
      emissionType: 'radar',
      freqRange: [12, 18], // Ku-band
      prf: 5000, // 5 kHz
      modulation: 'pulse_doppler'
    });

    this.signalLibrary.set('fire_control', {
      emissionType: 'radar',
      freqRange: [15, 18], // Ku-band
      prf: 10000, // 10 kHz
      modulation: 'pulse_doppler'
    });

    // Communications
    this.signalLibrary.set('comm_link', {
      emissionType: 'communications',
      freqRange: [2, 4], // S-band
      prf: null,
      modulation: 'QPSK'
    });

    this.signalLibrary.set('datalink', {
      emissionType: 'datalink',
      freqRange: [4, 8], // C-band
      prf: null,
      modulation: 'OFDM'
    });

    // Jamming
    this.signalLibrary.set('noise_jammer', {
      emissionType: 'jammer',
      freqRange: [8, 12], // X-band
      prf: null,
      modulation: 'noise'
    });
  }

  /**
   * Set ESM mode
   */
  public setMode(mode: ESMMode): void {
    if (!this.powered) {
      this.logEvent('mode_change_blocked', { reason: 'not_powered' });
      return;
    }

    this.mode = mode;
    this.logEvent('mode_change', { mode });
    this.updatePowerDraw();
  }

  /**
   * Set power state
   */
  public setPower(powered: boolean): void {
    this.powered = powered;
    if (!powered) {
      this.mode = 'off';
      this.contacts.clear();
    }
    this.updatePowerDraw();
  }

  /**
   * Update ESM system
   */
  public update(
    dt: number,
    shipPosition: { x: number; y: number; z: number },
    shipOrientation: { pitch: number; roll: number; yaw: number },
    emitters: Array<{
      id: string;
      position: { x: number; y: number; z: number };
      emitting: boolean;
      emissionType: 'radar' | 'communications' | 'jammer';
      frequencyGHz: number;
      powerKW: number; // Transmit power
    }>
  ): void {
    if (!this.powered || this.mode === 'off') {
      this.currentPowerDraw = 0;
      return;
    }

    // Update scan frequency
    if (this.mode === 'scan') {
      this.scanFrequencyGHz += this.scanRate * dt;
      if (this.scanFrequencyGHz > this.frequencyRangeGHz[1]) {
        this.scanFrequencyGHz = this.frequencyRangeGHz[0];
      }
    }

    // Process detections
    this.processEmissions(shipPosition, shipOrientation, emitters);

    // Clean up old contacts
    this.cleanupContacts();
  }

  /**
   * Process emission detections
   */
  private processEmissions(
    shipPosition: { x: number; y: number; z: number },
    shipOrientation: { pitch: number; roll: number; yaw: number },
    emitters: Array<{
      id: string;
      position: { x: number; y: number; z: number };
      emitting: boolean;
      emissionType: 'radar' | 'communications' | 'jammer';
      frequencyGHz: number;
      powerKW: number;
    }>
  ): void {
    for (const emitter of emitters) {
      if (!emitter.emitting) continue;

      // Calculate range and bearing
      const dx = emitter.position.x - shipPosition.x;
      const dy = emitter.position.y - shipPosition.y;
      const dz = emitter.position.z - shipPosition.z;
      const rangeKm = Math.sqrt(dx**2 + dy**2 + dz**2);
      const rangeM = rangeKm * 1000;

      // Calculate bearing
      const bearing = Math.atan2(dy, dx) * (180 / Math.PI) - shipOrientation.yaw;

      // Add direction-finding error
      const bearingError = (Math.random() - 0.5) * 2 * this.directionFindingAccuracy;
      const detectedBearing = bearing + bearingError;

      // Calculate received power using Friis transmission equation
      // Pr = Pt + Gt + Gr - 20*log10(d) - 20*log10(f) - 20*log10(4π/c)
      const Pt_dBm = 10 * Math.log10(emitter.powerKW * 1000000); // Convert kW to mW
      const Gt_dB = 0; // Assume 0 dBi transmit antenna
      const Gr_dB = this.antennaGainDB;
      const freq_MHz = emitter.frequencyGHz * 1000;

      // Free space path loss
      const FSPL = 20 * Math.log10(rangeM) + 20 * Math.log10(freq_MHz) + 32.44;

      const Pr_dBm = Pt_dBm + Gt_dB + Gr_dB - FSPL;

      // Check if detectable
      if (Pr_dBm < this.sensitivityDBm) continue;

      // Signal strength above noise floor
      const noiseFloor = -174 + 10 * Math.log10(1e9) + this.systemNoiseFigureDB; // dBm/Hz, 1 GHz bandwidth
      const signalStrength = Pr_dBm - noiseFloor;

      // Check if in scan range
      if (this.mode === 'scan') {
        const freqDiff = Math.abs(emitter.frequencyGHz - this.scanFrequencyGHz);
        if (freqDiff > 1.0) continue; // Out of scan window
      }

      // Classify signal
      const classification = this.classifySignal(emitter.frequencyGHz, emitter.emissionType, signalStrength);

      // Detect emission
      this.detectEmission(
        emitter.id,
        detectedBearing,
        emitter.frequencyGHz,
        Pr_dBm,
        classification.emissionType,
        classification.prf,
        classification.modulation,
        classification.confidence,
        signalStrength
      );
    }
  }

  /**
   * Classify detected signal
   */
  private classifySignal(
    frequencyGHz: number,
    actualType: 'radar' | 'communications' | 'jammer',
    signalStrength: number
  ): {
    emissionType: EmissionType;
    prf: number | null;
    modulation: string;
    confidence: number;
  } {
    // Low signal strength reduces classification confidence
    const baseConfidence = Math.min(1, signalStrength / 40); // 40 dB for max confidence

    // Match against signal library
    for (const [key, signature] of this.signalLibrary) {
      if (frequencyGHz >= signature.freqRange[0] && frequencyGHz <= signature.freqRange[1]) {
        // Frequency matches
        if (signature.emissionType === actualType) {
          return {
            emissionType: signature.emissionType,
            prf: signature.prf,
            modulation: signature.modulation,
            confidence: baseConfidence * 0.9 // High confidence
          };
        }
      }
    }

    // Unknown signal
    return {
      emissionType: 'unknown',
      prf: null,
      modulation: 'unknown',
      confidence: baseConfidence * 0.3 // Low confidence
    };
  }

  /**
   * Detect emission
   */
  private detectEmission(
    id: string,
    bearing: number,
    frequency: number,
    power: number,
    emissionType: EmissionType,
    pulseRepFreq: number | null,
    modulation: string,
    confidence: number,
    signalStrength: number
  ): void {
    const existingContact = this.contacts.get(id);

    // Estimate bandwidth based on emission type
    let bandwidth = 1; // MHz default
    if (emissionType === 'radar') {
      bandwidth = pulseRepFreq ? pulseRepFreq / 1000 : 1;
    } else if (emissionType === 'communications') {
      bandwidth = 10;
    } else if (emissionType === 'jammer') {
      bandwidth = 100; // Wide-band noise
    }

    if (existingContact) {
      // Update existing contact
      existingContact.bearing = bearing;
      existingContact.frequency = frequency;
      existingContact.power = power;
      existingContact.emissionType = emissionType;
      existingContact.confidence = Math.min(1, existingContact.confidence + 0.05);
      existingContact.lastUpdate = Date.now();
      existingContact.signalStrength = signalStrength;
    } else {
      // New contact
      const contact: ESMContact = {
        id,
        bearing,
        frequency,
        bandwidth,
        power,
        emissionType,
        pulseRepFreq,
        modulation,
        confidence,
        firstDetection: Date.now(),
        lastUpdate: Date.now(),
        signalStrength
      };

      this.contacts.set(id, contact);
      this.logEvent('new_emission', { id, bearing, frequency, type: emissionType });

      // Alert if fire control radar detected
      if (emissionType === 'radar' && pulseRepFreq && pulseRepFreq > 5000) {
        this.logEvent('fire_control_warning', { id, bearing });
      }
    }
  }

  /**
   * Clean up old contacts
   */
  private cleanupContacts(): void {
    const now = Date.now();
    const maxAge = 5000; // 5 seconds

    for (const [id, contact] of this.contacts) {
      if (now - contact.lastUpdate > maxAge) {
        this.contacts.delete(id);
        this.logEvent('emission_lost', { id });
      }
    }
  }

  /**
   * Update power draw
   */
  private updatePowerDraw(): void {
    switch (this.mode) {
      case 'off':
        this.currentPowerDraw = 0;
        break;
      case 'standby':
        this.currentPowerDraw = 20; // 20W standby
        break;
      case 'wide_band':
        this.currentPowerDraw = 100; // 100W wide-band
        break;
      case 'narrow_band':
        this.currentPowerDraw = 50; // 50W narrow-band
        break;
      case 'scan':
        this.currentPowerDraw = 80; // 80W scanning
        break;
    }
  }

  /**
   * Get all contacts
   */
  public getContacts(): ESMContact[] {
    return Array.from(this.contacts.values());
  }

  /**
   * Get contact by ID
   */
  public getContact(id: string): ESMContact | undefined {
    return this.contacts.get(id);
  }

  /**
   * Get current power draw
   */
  public getPowerDraw(): number {
    return this.currentPowerDraw;
  }

  /**
   * Detect specific frequency
   */
  public tuneToFrequency(frequencyGHz: number): void {
    this.mode = 'narrow_band';
    this.scanFrequencyGHz = frequencyGHz;
    this.logEvent('frequency_tuned', { frequency: frequencyGHz });
  }

  /**
   * Get system state
   */
  public getState() {
    return {
      mode: this.mode,
      powered: this.powered,
      operational: this.operational,
      powerDraw: this.currentPowerDraw,
      scanFrequency: this.scanFrequencyGHz,
      contactCount: this.contacts.size,
      contacts: this.getContacts(),
      configuration: {
        frequencyRangeGHz: this.frequencyRangeGHz,
        antennaGainDB: this.antennaGainDB,
        sensitivityDBm: this.sensitivityDBm,
        directionFindingAccuracy: this.directionFindingAccuracy
      }
    };
  }

  private logEvent(type: string, data: any): void {
    this.events.push({ time: Date.now(), type, data });
  }

  public getEvents(): Array<{ time: number; type: string; data: any }> {
    const events = [...this.events];
    this.events = [];
    return events;
  }
}
