/**
 * Sensor Fusion System
 *
 * Combines data from multiple sensor systems into unified tracks:
 * - Radar contacts (range, bearing, velocity)
 * - Optical contacts (bearing, IR signature, visual magnitude)
 * - ESM contacts (bearing, emission type, frequency)
 * - Track correlation and association
 * - Track quality assessment
 * - Automated threat classification
 * - Integrated tactical picture
 */

import type { RadarContact, RadarTrack } from './radar-system';
import type { OpticalContact } from './optical-sensors';
import type { ESMContact } from './esm-system';

export type ThreatLevel = 'none' | 'low' | 'medium' | 'high' | 'critical';
export type TrackClassification =
  | 'unknown'
  | 'friendly'
  | 'neutral'
  | 'hostile'
  | 'missile'
  | 'spacecraft'
  | 'debris'
  | 'station';

export interface FusedTrack {
  id: string;
  classification: TrackClassification;
  threatLevel: ThreatLevel;

  // Position (best estimate from all sensors)
  position: { x: number; y: number; z: number } | null; // km
  velocity: { x: number; y: number; z: number } | null; // m/s

  // Measurements
  range: number | null; // km (from radar)
  rangeRate: number | null; // km/s (from radar)
  bearing: number; // degrees (from any sensor)
  elevation: number; // degrees (from any sensor)

  // Sensor contributions
  radarContact: RadarContact | null;
  opticalContact: OpticalContact | null;
  esmContact: ESMContact | null;

  // Track quality
  trackQuality: number; // 0-1
  positionUncertainty: number; // km
  velocityUncertainty: number; // m/s

  // Metadata
  firstDetection: number; // timestamp
  lastUpdate: number; // timestamp
  sensorCount: number; // How many sensors see this track

  // Tactical data
  timeToClosestApproach: number | null; // seconds
  closestApproachDistance: number | null; // km
  inWeaponsRange: boolean;
  lockQuality: number; // 0-1, for weapons targeting
}

export interface FusionConfiguration {
  correlationThresholdDegrees?: number; // Max bearing difference for correlation
  trackConfirmationTime?: number; // Seconds before track confirmed
  threatAssessmentEnabled?: boolean;
}

export class SensorFusionSystem {
  // Configuration
  private correlationThresholdDegrees: number;
  private trackConfirmationTime: number;
  private threatAssessmentEnabled: boolean;

  // Fused tracks
  private tracks: Map<string, FusedTrack> = new Map();

  // Track ID generation
  private nextTrackId: number = 1000;

  // Ship state (for threat assessment)
  private shipPosition: { x: number; y: number; z: number } = { x: 0, y: 0, z: 0 };
  private shipVelocity: { x: number; y: number; z: number } = { x: 0, y: 0, z: 0 };

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor(config?: FusionConfiguration) {
    this.correlationThresholdDegrees = config?.correlationThresholdDegrees || 10; // 10 degrees
    this.trackConfirmationTime = config?.trackConfirmationTime || 2; // 2 seconds
    this.threatAssessmentEnabled = config?.threatAssessmentEnabled !== undefined
      ? config.threatAssessmentEnabled
      : true;
  }

  /**
   * Update sensor fusion
   */
  public update(
    dt: number,
    radarContacts: RadarContact[],
    radarTracks: RadarTrack[],
    opticalContacts: OpticalContact[],
    esmContacts: ESMContact[],
    shipPosition: { x: number; y: number; z: number },
    shipVelocity: { x: number; y: number; z: number }
  ): void {
    this.shipPosition = shipPosition;
    this.shipVelocity = shipVelocity;

    // Step 1: Update existing tracks with new sensor data
    this.updateExistingTracks(radarContacts, radarTracks, opticalContacts, esmContacts);

    // Step 2: Create new tracks from uncorrelated contacts
    this.createNewTracks(radarContacts, opticalContacts, esmContacts);

    // Step 3: Assess threats
    if (this.threatAssessmentEnabled) {
      this.assessThreats();
    }

    // Step 4: Clean up old tracks
    this.cleanupTracks();
  }

  /**
   * Update existing tracks with new sensor data
   */
  private updateExistingTracks(
    radarContacts: RadarContact[],
    radarTracks: RadarTrack[],
    opticalContacts: OpticalContact[],
    esmContacts: ESMContact[]
  ): void {
    for (const track of this.tracks.values()) {
      let updated = false;

      // Try to correlate with radar
      const radarContact = this.correlateSensor(
        track,
        radarContacts.map(c => ({ bearing: c.bearing, elevation: c.elevation, contact: c }))
      );
      if (radarContact) {
        track.radarContact = radarContact.contact as RadarContact;
        track.range = radarContact.contact.range;
        track.rangeRate = radarContact.contact.rangeRate;
        track.position = radarContact.contact.position;
        track.velocity = radarContact.contact.velocity;
        track.bearing = radarContact.contact.bearing;
        track.elevation = radarContact.contact.elevation;
        updated = true;
      } else {
        track.radarContact = null;
      }

      // Try to correlate with optical
      const opticalContact = this.correlateSensor(
        track,
        opticalContacts.map(c => ({ bearing: c.bearing, elevation: c.elevation, contact: c }))
      );
      if (opticalContact) {
        track.opticalContact = opticalContact.contact as OpticalContact;
        track.bearing = opticalContact.contact.bearing;
        track.elevation = opticalContact.contact.elevation;
        // If no radar, use optical position estimate
        if (!track.radarContact && opticalContact.contact.position) {
          track.position = opticalContact.contact.position;
        }
        updated = true;
      } else {
        track.opticalContact = null;
      }

      // Try to correlate with ESM (bearing-only correlation)
      const esmContact = this.correlateESM(track, esmContacts);
      if (esmContact) {
        track.esmContact = esmContact;
        updated = true;
      } else {
        track.esmContact = null;
      }

      // Update track metadata
      if (updated) {
        track.lastUpdate = Date.now();
        track.sensorCount = [track.radarContact, track.opticalContact, track.esmContact]
          .filter(c => c !== null).length;

        // Update track quality based on sensor count and age
        const ageSeconds = (Date.now() - track.firstDetection) / 1000;
        const ageFactor = Math.min(1, ageSeconds / this.trackConfirmationTime);
        const sensorFactor = track.sensorCount / 3;
        track.trackQuality = (ageFactor + sensorFactor) / 2;

        // Update position uncertainty
        if (track.radarContact) {
          track.positionUncertainty = track.radarContact.range * 0.01; // 1% of range
        } else {
          track.positionUncertainty = 100; // High uncertainty without radar
        }
      }
    }
  }

  /**
   * Correlate track with sensor contacts
   */
  private correlateSensor<T extends { bearing: number; elevation: number }>(
    track: FusedTrack,
    contacts: Array<{ bearing: number; elevation: number; contact: T }>
  ): { bearing: number; elevation: number; contact: T } | null {
    let bestMatch: { bearing: number; elevation: number; contact: T } | null = null;
    let bestScore = Infinity;

    for (const contact of contacts) {
      const bearingDiff = Math.abs(this.angleDifference(track.bearing, contact.bearing));
      const elevationDiff = Math.abs(this.angleDifference(track.elevation, contact.elevation));

      const score = Math.sqrt(bearingDiff**2 + elevationDiff**2);

      if (score < this.correlationThresholdDegrees && score < bestScore) {
        bestScore = score;
        bestMatch = contact;
      }
    }

    return bestMatch;
  }

  /**
   * Correlate ESM contact (bearing-only)
   */
  private correlateESM(
    track: FusedTrack,
    esmContacts: ESMContact[]
  ): ESMContact | null {
    let bestMatch: ESMContact | null = null;
    let bestScore = Infinity;

    for (const contact of esmContacts) {
      const bearingDiff = Math.abs(this.angleDifference(track.bearing, contact.bearing));

      if (bearingDiff < this.correlationThresholdDegrees && bearingDiff < bestScore) {
        bestScore = bearingDiff;
        bestMatch = contact;
      }
    }

    return bestMatch;
  }

  /**
   * Calculate smallest difference between two angles
   */
  private angleDifference(a: number, b: number): number {
    let diff = a - b;
    while (diff > 180) diff -= 360;
    while (diff < -180) diff += 360;
    return diff;
  }

  /**
   * Create new tracks from uncorrelated contacts
   */
  private createNewTracks(
    radarContacts: RadarContact[],
    opticalContacts: OpticalContact[],
    esmContacts: ESMContact[]
  ): void {
    // Create tracks from radar contacts (most reliable)
    for (const contact of radarContacts) {
      if (!this.isContactCorrelated(contact.bearing, contact.elevation)) {
        this.createTrack(contact, null, null);
      }
    }

    // Create tracks from optical contacts (if not correlated with existing tracks)
    for (const contact of opticalContacts) {
      if (!this.isContactCorrelated(contact.bearing, contact.elevation)) {
        this.createTrack(null, contact, null);
      }
    }

    // ESM contacts alone don't create tracks (bearing-only, unreliable)
    // They only enhance existing tracks
  }

  /**
   * Check if contact is already correlated with existing track
   */
  private isContactCorrelated(bearing: number, elevation: number): boolean {
    for (const track of this.tracks.values()) {
      const bearingDiff = Math.abs(this.angleDifference(track.bearing, bearing));
      const elevationDiff = Math.abs(this.angleDifference(track.elevation, elevation));
      const score = Math.sqrt(bearingDiff**2 + elevationDiff**2);

      if (score < this.correlationThresholdDegrees) {
        return true;
      }
    }
    return false;
  }

  /**
   * Create new fused track
   */
  private createTrack(
    radarContact: RadarContact | null,
    opticalContact: OpticalContact | null,
    esmContact: ESMContact | null
  ): void {
    const trackId = `T${this.nextTrackId++}`;

    // Determine bearing and elevation from available sensors
    let bearing = 0;
    let elevation = 0;
    let position: { x: number; y: number; z: number } | null = null;
    let velocity: { x: number; y: number; z: number } | null = null;

    if (radarContact) {
      bearing = radarContact.bearing;
      elevation = radarContact.elevation;
      position = radarContact.position;
      velocity = radarContact.velocity;
    } else if (opticalContact) {
      bearing = opticalContact.bearing;
      elevation = opticalContact.elevation;
      position = opticalContact.position;
    } else if (esmContact) {
      bearing = esmContact.bearing;
      elevation = 0;
    }

    // Initial classification
    const classification = this.classifyTrack(radarContact, opticalContact, esmContact);

    const track: FusedTrack = {
      id: trackId,
      classification,
      threatLevel: 'none',
      position,
      velocity,
      range: radarContact?.range || null,
      rangeRate: radarContact?.rangeRate || null,
      bearing,
      elevation,
      radarContact,
      opticalContact,
      esmContact,
      trackQuality: 0.3, // Initial quality
      positionUncertainty: radarContact ? radarContact.range * 0.01 : 100,
      velocityUncertainty: 10, // m/s
      firstDetection: Date.now(),
      lastUpdate: Date.now(),
      sensorCount: [radarContact, opticalContact, esmContact].filter(c => c !== null).length,
      timeToClosestApproach: null,
      closestApproachDistance: null,
      inWeaponsRange: false,
      lockQuality: 0
    };

    this.tracks.set(trackId, track);
    this.logEvent('track_created', { id: trackId, classification });
  }

  /**
   * Classify track based on sensor data
   */
  private classifyTrack(
    radarContact: RadarContact | null,
    opticalContact: OpticalContact | null,
    esmContact: ESMContact | null
  ): TrackClassification {
    // Use radar classification if available
    if (radarContact) {
      if (radarContact.classification === 'missile') return 'missile';
      if (radarContact.classification === 'spacecraft') return 'spacecraft';
      if (radarContact.classification === 'debris') return 'debris';
    }

    // Use optical data
    if (opticalContact) {
      if (opticalContact.targetType === 'engine_plume') {
        // Hot engine = active spacecraft or missile
        if (radarContact && Math.abs(radarContact.rangeRate) > 2.0) {
          return 'missile'; // High closing rate
        }
        return 'spacecraft';
      }
    }

    // Use ESM data
    if (esmContact) {
      if (esmContact.emissionType === 'radar') {
        return 'spacecraft'; // Has radar = spacecraft
      }
    }

    return 'unknown';
  }

  /**
   * Assess threats for all tracks
   */
  private assessThreats(): void {
    for (const track of this.tracks.values()) {
      // Calculate closest approach if we have position and velocity
      if (track.position && track.velocity) {
        const result = this.calculateClosestApproach(
          track.position,
          track.velocity,
          this.shipPosition,
          this.shipVelocity
        );

        track.timeToClosestApproach = result.time;
        track.closestApproachDistance = result.distance;
      }

      // Assess threat level
      track.threatLevel = this.assessThreatLevel(track);

      // Check if in weapons range (simplified - 100 km)
      track.inWeaponsRange = track.range !== null && track.range < 100;

      // Calculate lock quality for weapons
      track.lockQuality = this.calculateLockQuality(track);
    }
  }

  /**
   * Calculate closest point of approach
   */
  private calculateClosestApproach(
    pos1: { x: number; y: number; z: number },
    vel1: { x: number; y: number; z: number },
    pos2: { x: number; y: number; z: number },
    vel2: { x: number; y: number; z: number }
  ): { time: number; distance: number } {
    // Relative position and velocity
    const dx = pos1.x - pos2.x;
    const dy = pos1.y - pos2.y;
    const dz = pos1.z - pos2.z;

    const dvx = (vel1.x - vel2.x) / 1000; // m/s to km/s
    const dvy = (vel1.y - vel2.y) / 1000;
    const dvz = (vel1.z - vel2.z) / 1000;

    // Time to closest approach: t = -(r · v) / |v|^2
    const dotProduct = dx * dvx + dy * dvy + dz * dvz;
    const velocitySquared = dvx**2 + dvy**2 + dvz**2;

    if (velocitySquared === 0) {
      // Not moving relative to each other
      return {
        time: 0,
        distance: Math.sqrt(dx**2 + dy**2 + dz**2)
      };
    }

    const timeToCA = -dotProduct / velocitySquared;

    // Calculate position at closest approach
    const caX = dx + dvx * timeToCA;
    const caY = dy + dvy * timeToCA;
    const caZ = dz + dvz * timeToCA;

    const distance = Math.sqrt(caX**2 + caY**2 + caZ**2);

    return {
      time: timeToCA,
      distance
    };
  }

  /**
   * Assess threat level
   */
  private assessThreatLevel(track: FusedTrack): ThreatLevel {
    // Missiles are critical threats
    if (track.classification === 'missile') {
      if (track.range && track.range < 50) {
        return 'critical';
      }
      return 'high';
    }

    // Hostile spacecraft with fire control radar
    if (track.esmContact?.emissionType === 'radar' &&
        track.esmContact.pulseRepFreq &&
        track.esmContact.pulseRepFreq > 5000) {
      return 'high'; // Fire control radar detected
    }

    // Closing targets
    if (track.rangeRate && track.rangeRate < -0.5) { // Closing > 500 m/s
      if (track.range && track.range < 100) {
        return 'medium';
      }
      return 'low';
    }

    // Unknown or non-threatening
    if (track.classification === 'debris') {
      return 'none';
    }

    return 'low';
  }

  /**
   * Calculate weapons lock quality
   */
  private calculateLockQuality(track: FusedTrack): number {
    let quality = 0;

    // Radar provides best lock
    if (track.radarContact) {
      quality += 0.6 * track.radarContact.quality;
    }

    // Optical enhances lock
    if (track.opticalContact) {
      quality += 0.3 * track.opticalContact.trackQuality;
    }

    // ESM provides bearing
    if (track.esmContact) {
      quality += 0.1 * track.esmContact.confidence;
    }

    // Track age improves quality
    const ageSeconds = (Date.now() - track.firstDetection) / 1000;
    const ageFactor = Math.min(1, ageSeconds / 5); // 5 seconds to full quality
    quality *= ageFactor;

    return Math.min(1, quality);
  }

  /**
   * Clean up old tracks
   */
  private cleanupTracks(): void {
    const now = Date.now();
    const maxAge = 10000; // 10 seconds

    for (const [id, track] of this.tracks) {
      if (now - track.lastUpdate > maxAge) {
        this.tracks.delete(id);
        this.logEvent('track_lost', { id, classification: track.classification });
      }
    }
  }

  /**
   * Get all fused tracks
   */
  public getTracks(): FusedTrack[] {
    return Array.from(this.tracks.values());
  }

  /**
   * Get track by ID
   */
  public getTrack(id: string): FusedTrack | undefined {
    return this.tracks.get(id);
  }

  /**
   * Get tracks by classification
   */
  public getTracksByClassification(classification: TrackClassification): FusedTrack[] {
    return Array.from(this.tracks.values()).filter(t => t.classification === classification);
  }

  /**
   * Get tracks by threat level
   */
  public getTracksByThreat(minThreat: ThreatLevel): FusedTrack[] {
    const threatOrder: ThreatLevel[] = ['none', 'low', 'medium', 'high', 'critical'];
    const minIndex = threatOrder.indexOf(minThreat);

    return Array.from(this.tracks.values()).filter(t => {
      const trackIndex = threatOrder.indexOf(t.threatLevel);
      return trackIndex >= minIndex;
    });
  }

  /**
   * Get system state
   */
  public getState() {
    return {
      trackCount: this.tracks.size,
      tracks: this.getTracks(),
      threatAssessmentEnabled: this.threatAssessmentEnabled,
      configuration: {
        correlationThresholdDegrees: this.correlationThresholdDegrees,
        trackConfirmationTime: this.trackConfirmationTime
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
