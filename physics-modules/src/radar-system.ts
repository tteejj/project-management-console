/**
 * Radar System
 *
 * Active radar detection with realistic physics:
 * - Range-based detection probability
 * - Radar cross-section (RCS) calculations
 * - Signal-to-noise ratio
 * - Power requirements
 * - Jamming resistance
 * - Multiple search and track modes
 */

export type RadarMode = 'search' | 'track' | 'track_while_scan' | 'standby' | 'off';
export type RadarBand = 'S' | 'C' | 'X' | 'Ku' | 'Ka'; // Frequency bands

export interface RadarConfiguration {
  peakPowerKW?: number;
  antennaGainDB?: number;
  antennaDiameterM?: number;
  frequencyGHz?: number;
  pulseRepetitionFreqHz?: number;
  beamwidthDegrees?: number;
  maxRangeKm?: number;
}

export interface RadarContact {
  id: string;
  range: number; // km
  bearing: number; // degrees, 0 = forward
  elevation: number; // degrees, 0 = level
  rangeRate: number; // km/s, positive = approaching
  rcs: number; // m^2
  snr: number; // Signal-to-noise ratio (dB)
  quality: number; // 0-1, track quality
  firstDetection: number; // timestamp
  lastUpdate: number; // timestamp
  position: { x: number; y: number; z: number }; // km
  velocity: { x: number; y: number; z: number }; // m/s
  classification: 'unknown' | 'missile' | 'spacecraft' | 'debris' | 'noise';
}

export interface RadarTrack {
  contactId: string;
  locked: boolean;
  trackQuality: number; // 0-1
  trackAge: number; // seconds
  predictedPosition: { x: number; y: number; z: number };
  predictedVelocity: { x: number; y: number; z: number };
  covariance: number; // Position uncertainty (km)
}

export class RadarSystem {
  // Configuration
  private peakPowerKW: number;
  private antennaGainDB: number;
  private antennaDiameterM: number;
  private frequencyGHz: number;
  private pulseRepetitionFreqHz: number;
  private beamwidthDegrees: number;
  private maxRangeKm: number;

  // State
  public mode: RadarMode = 'standby';
  public powered: boolean = true;
  public operational: boolean = true;

  // Detection
  private contacts: Map<string, RadarContact> = new Map();
  private tracks: Map<string, RadarTrack> = new Map();

  // Scan pattern
  private scanAzimuth: number = 0; // degrees
  private scanElevation: number = 0; // degrees
  private scanRate: number = 60; // degrees/second

  // Performance
  private currentPowerDraw: number = 0; // W
  private temperature: number = 293; // K
  private maxTemperature: number = 350; // K

  // Jamming
  private jammingStrength: number = 0; // dB

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  // Constants
  private readonly BOLTZMANN_CONSTANT = 1.380649e-23; // J/K
  private readonly SPEED_OF_LIGHT = 299792458; // m/s

  constructor(config?: RadarConfiguration) {
    this.peakPowerKW = config?.peakPowerKW || 100; // 100 kW peak
    this.antennaGainDB = config?.antennaGainDB || 35; // 35 dB gain
    this.antennaDiameterM = config?.antennaDiameterM || 2.0; // 2m dish
    this.frequencyGHz = config?.frequencyGHz || 10; // 10 GHz (X-band)
    this.pulseRepetitionFreqHz = config?.pulseRepetitionFreqHz || 1000; // 1 kHz
    this.beamwidthDegrees = config?.beamwidthDegrees || 2.0; // 2 degree beam
    this.maxRangeKm = config?.maxRangeKm || 1000; // 1000 km max range
  }

  /**
   * Set radar mode
   */
  public setMode(mode: RadarMode): void {
    if (!this.powered) {
      this.logEvent('mode_change_blocked', { reason: 'not_powered' });
      return;
    }

    this.mode = mode;
    this.logEvent('mode_change', { mode });

    // Update power draw based on mode
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
      this.tracks.clear();
    }
    this.updatePowerDraw();
  }

  /**
   * Set jamming strength affecting this radar
   */
  public setJamming(strengthDB: number): void {
    this.jammingStrength = strengthDB;
  }

  /**
   * Update radar system
   */
  public update(
    dt: number,
    shipPosition: { x: number; y: number; z: number },
    shipOrientation: { pitch: number; roll: number; yaw: number },
    targets: Array<{
      id: string;
      position: { x: number; y: number; z: number };
      velocity: { x: number; y: number; z: number };
      rcs: number;
    }>
  ): void {
    if (!this.powered || this.mode === 'off') {
      this.currentPowerDraw = 0;
      return;
    }

    // Update scan position
    if (this.mode === 'search' || this.mode === 'track_while_scan') {
      this.scanAzimuth += this.scanRate * dt;
      if (this.scanAzimuth >= 360) {
        this.scanAzimuth -= 360;
      }
    }

    // Process detections
    this.processDetections(dt, shipPosition, shipOrientation, targets);

    // Update tracks
    this.updateTracks(dt);

    // Clean up old contacts
    this.cleanupContacts();

    // Update temperature from power dissipation
    const heatGeneration = this.currentPowerDraw * 0.3; // 30% becomes heat
    this.temperature += (heatGeneration / 1000) * dt; // Simplified cooling
    this.temperature = Math.max(293, this.temperature - 10 * dt); // Passive cooling

    // Check for overheat
    if (this.temperature > this.maxTemperature) {
      this.operational = false;
      this.logEvent('overheat', { temperature: this.temperature });
    }
  }

  /**
   * Process detections for all targets
   */
  private processDetections(
    dt: number,
    shipPosition: { x: number; y: number; z: number },
    shipOrientation: { pitch: number; roll: number; yaw: number },
    targets: Array<{
      id: string;
      position: { x: number; y: number; z: number };
      velocity: { x: number; y: number; z: number };
      rcs: number;
    }>
  ): void {
    for (const target of targets) {
      // Calculate range and bearing
      const dx = target.position.x - shipPosition.x;
      const dy = target.position.y - shipPosition.y;
      const dz = target.position.z - shipPosition.z;
      const range = Math.sqrt(dx**2 + dy**2 + dz**2); // km

      if (range > this.maxRangeKm) continue;

      // Calculate bearing relative to ship orientation
      const bearing = Math.atan2(dy, dx) * (180 / Math.PI) - shipOrientation.yaw;
      const elevation = Math.atan2(dz, Math.sqrt(dx**2 + dy**2)) * (180 / Math.PI) - shipOrientation.pitch;

      // Check if target is in beam (for track mode)
      if (this.mode === 'track') {
        const beamPointing = this.tracks.size > 0;
        if (!beamPointing) continue; // No track to follow
      }

      // Calculate detection probability using radar range equation
      const detectionProb = this.calculateDetectionProbability(range, target.rcs);

      // Random detection based on probability
      if (Math.random() < detectionProb * dt) {
        this.detectTarget(target, range, bearing, elevation, shipPosition);
      }
    }
  }

  /**
   * Calculate detection probability using radar range equation
   *
   * Radar Range Equation:
   * Pr = (Pt * G^2 * λ^2 * σ) / ((4π)^3 * R^4 * L)
   *
   * Where:
   * Pr = received power
   * Pt = transmitted power
   * G = antenna gain
   * λ = wavelength
   * σ = radar cross section
   * R = range
   * L = losses
   */
  private calculateDetectionProbability(rangeKm: number, rcs: number): number {
    // Convert to SI units
    const rangeM = rangeKm * 1000;
    const Pt = this.peakPowerKW * 1000; // Watts
    const G = Math.pow(10, this.antennaGainDB / 10); // Linear gain
    const wavelength = (this.SPEED_OF_LIGHT / (this.frequencyGHz * 1e9)); // meters
    const sigma = rcs; // m^2

    // Radar range equation (simplified, assumes L = 1)
    const numerator = Pt * G * G * wavelength * wavelength * sigma;
    const denominator = Math.pow(4 * Math.PI, 3) * Math.pow(rangeM, 4);
    const Pr = numerator / denominator;

    // Noise power
    const bandwidth = 1e6; // 1 MHz bandwidth
    const noiseTemperature = 290; // K
    const Pn = this.BOLTZMANN_CONSTANT * noiseTemperature * bandwidth;

    // Signal-to-noise ratio
    let snr = Pr / Pn;

    // Apply jamming
    if (this.jammingStrength > 0) {
      const jammingPower = Math.pow(10, this.jammingStrength / 10);
      snr = snr / (1 + jammingPower);
    }

    // Convert to dB
    const snrDB = 10 * Math.log10(snr);

    // Detection probability based on SNR
    // Threshold: 13 dB for 90% detection probability
    const threshold = 13; // dB
    const detectionProb = 1 / (1 + Math.exp(-(snrDB - threshold)));

    return Math.max(0, Math.min(1, detectionProb));
  }

  /**
   * Detect and track a target
   */
  private detectTarget(
    target: {
      id: string;
      position: { x: number; y: number; z: number };
      velocity: { x: number; y: number; z: number };
      rcs: number;
    },
    range: number,
    bearing: number,
    elevation: number,
    shipPosition: { x: number; y: number; z: number }
  ): void {
    const dx = target.position.x - shipPosition.x;
    const dy = target.position.y - shipPosition.y;
    const dz = target.position.z - shipPosition.z;

    // Calculate range rate (closing velocity)
    const rangeRate = (
      target.velocity.x * dx +
      target.velocity.y * dy +
      target.velocity.z * dz
    ) / (range * 1000); // km/s

    // Calculate SNR for display
    const rangeM = range * 1000;
    const Pt = this.peakPowerKW * 1000;
    const G = Math.pow(10, this.antennaGainDB / 10);
    const wavelength = (this.SPEED_OF_LIGHT / (this.frequencyGHz * 1e9));
    const sigma = target.rcs;
    const Pr = (Pt * G * G * wavelength * wavelength * sigma) / (Math.pow(4 * Math.PI, 3) * Math.pow(rangeM, 4));
    const Pn = this.BOLTZMANN_CONSTANT * 290 * 1e6;
    const snrDB = 10 * Math.log10(Pr / Pn);

    const existingContact = this.contacts.get(target.id);

    if (existingContact) {
      // Update existing contact
      existingContact.range = range;
      existingContact.bearing = bearing;
      existingContact.elevation = elevation;
      existingContact.rangeRate = rangeRate;
      existingContact.snr = snrDB;
      existingContact.lastUpdate = Date.now();
      existingContact.quality = Math.min(1, existingContact.quality + 0.1);
      existingContact.position = { ...target.position };
      existingContact.velocity = { ...target.velocity };
    } else {
      // New contact
      const contact: RadarContact = {
        id: target.id,
        range,
        bearing,
        elevation,
        rangeRate,
        rcs: target.rcs,
        snr: snrDB,
        quality: 0.3,
        firstDetection: Date.now(),
        lastUpdate: Date.now(),
        position: { ...target.position },
        velocity: { ...target.velocity },
        classification: this.classifyTarget(target.rcs, range, rangeRate)
      };

      this.contacts.set(target.id, contact);
      this.logEvent('new_contact', { id: target.id, range, bearing });

      // Auto-create track if in track mode
      if (this.mode === 'track' || this.mode === 'track_while_scan') {
        this.initiateTrack(target.id);
      }
    }
  }

  /**
   * Classify target based on characteristics
   */
  private classifyTarget(rcs: number, range: number, rangeRate: number): RadarContact['classification'] {
    // Small RCS + high closing rate = likely missile
    if (rcs < 0.1 && Math.abs(rangeRate) > 2.0) {
      return 'missile';
    }

    // Medium RCS = spacecraft
    if (rcs >= 0.1 && rcs < 100) {
      return 'spacecraft';
    }

    // Large RCS but slow = debris
    if (rcs >= 100 && Math.abs(rangeRate) < 0.5) {
      return 'debris';
    }

    return 'unknown';
  }

  /**
   * Initiate track on a contact
   */
  public initiateTrack(contactId: string): boolean {
    const contact = this.contacts.get(contactId);
    if (!contact) return false;

    const track: RadarTrack = {
      contactId,
      locked: true,
      trackQuality: contact.quality,
      trackAge: 0,
      predictedPosition: { ...contact.position },
      predictedVelocity: { ...contact.velocity },
      covariance: contact.range * 0.01 // 1% range uncertainty
    };

    this.tracks.set(contactId, track);
    this.logEvent('track_initiated', { contactId });
    return true;
  }

  /**
   * Drop track
   */
  public dropTrack(contactId: string): void {
    this.tracks.delete(contactId);
    this.logEvent('track_dropped', { contactId });
  }

  /**
   * Update all tracks
   */
  private updateTracks(dt: number): void {
    for (const [id, track] of this.tracks) {
      const contact = this.contacts.get(id);

      if (!contact) {
        // Lost contact - coast track
        track.trackQuality -= 0.1 * dt;
        track.covariance += 0.1 * dt; // Uncertainty grows

        if (track.trackQuality <= 0) {
          this.dropTrack(id);
        }
        continue;
      }

      // Update track age
      track.trackAge += dt;

      // Kalman filter update (simplified)
      const alpha = 0.3; // Smoothing factor
      track.predictedPosition.x = alpha * contact.position.x + (1 - alpha) * track.predictedPosition.x;
      track.predictedPosition.y = alpha * contact.position.y + (1 - alpha) * track.predictedPosition.y;
      track.predictedPosition.z = alpha * contact.position.z + (1 - alpha) * track.predictedPosition.z;

      track.predictedVelocity.x = alpha * contact.velocity.x + (1 - alpha) * track.predictedVelocity.x;
      track.predictedVelocity.y = alpha * contact.velocity.y + (1 - alpha) * track.predictedVelocity.y;
      track.predictedVelocity.z = alpha * contact.velocity.z + (1 - alpha) * track.predictedVelocity.z;

      track.trackQuality = Math.min(1, track.trackQuality + 0.05 * dt);
      track.covariance = Math.max(0.01, track.covariance - 0.05 * dt);
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
        this.logEvent('contact_lost', { id });
      }
    }
  }

  /**
   * Update power draw based on mode
   */
  private updatePowerDraw(): void {
    switch (this.mode) {
      case 'off':
        this.currentPowerDraw = 0;
        break;
      case 'standby':
        this.currentPowerDraw = 100; // 100W standby
        break;
      case 'search':
        this.currentPowerDraw = this.peakPowerKW * 1000 * 0.1; // 10% duty cycle
        break;
      case 'track':
        this.currentPowerDraw = this.peakPowerKW * 1000 * 0.2; // 20% duty cycle
        break;
      case 'track_while_scan':
        this.currentPowerDraw = this.peakPowerKW * 1000 * 0.15; // 15% duty cycle
        break;
    }
  }

  /**
   * Get all contacts
   */
  public getContacts(): RadarContact[] {
    return Array.from(this.contacts.values());
  }

  /**
   * Get all tracks
   */
  public getTracks(): RadarTrack[] {
    return Array.from(this.tracks.values());
  }

  /**
   * Get contact by ID
   */
  public getContact(id: string): RadarContact | undefined {
    return this.contacts.get(id);
  }

  /**
   * Get track by ID
   */
  public getTrack(id: string): RadarTrack | undefined {
    return this.tracks.get(id);
  }

  /**
   * Get current power draw
   */
  public getPowerDraw(): number {
    return this.currentPowerDraw;
  }

  /**
   * Get system state
   */
  public getState() {
    return {
      mode: this.mode,
      powered: this.powered,
      operational: this.operational,
      temperature: this.temperature,
      maxTemperature: this.maxTemperature,
      powerDraw: this.currentPowerDraw,
      scanAzimuth: this.scanAzimuth,
      scanElevation: this.scanElevation,
      contactCount: this.contacts.size,
      trackCount: this.tracks.size,
      contacts: this.getContacts(),
      tracks: this.getTracks(),
      jammingStrength: this.jammingStrength,
      maxRange: this.maxRangeKm,
      configuration: {
        peakPowerKW: this.peakPowerKW,
        antennaGainDB: this.antennaGainDB,
        frequencyGHz: this.frequencyGHz,
        beamwidthDegrees: this.beamwidthDegrees
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
