/**
 * Optical Sensors System
 *
 * Passive optical and infrared detection:
 * - Visual spectrum (cameras)
 * - Infrared detection (heat signatures)
 * - Star trackers for navigation
 * - Passive detection (no emissions)
 * - Range estimation from angular size
 * - Temperature estimation from IR spectrum
 */

export type OpticalMode = 'visual' | 'infrared' | 'combined' | 'standby' | 'off';
export type TargetType = 'point_source' | 'extended' | 'engine_plume' | 'unknown';

export interface OpticalContact {
  id: string;
  bearing: number; // degrees from ship forward
  elevation: number; // degrees from ship level
  angularSize: number; // arc-seconds
  estimatedRange: number; // km (from angular size if known target)
  visualMagnitude: number; // Brightness
  irSignature: number; // W/sr (Watts per steradian)
  estimatedTemperature: number; // K (from IR spectrum)
  trackQuality: number; // 0-1
  firstDetection: number; // timestamp
  lastUpdate: number; // timestamp
  targetType: TargetType;
  position: { x: number; y: number; z: number } | null; // km, null if range unknown
}

export interface OpticalConfiguration {
  visualApertureM?: number; // Telescope aperture
  irApertureM?: number; // IR sensor aperture
  focalLengthM?: number;
  pixelCount?: number;
  fieldOfViewDegrees?: number;
  minDetectableFlux?: number; // W/m^2
}

export class OpticalSensorsSystem {
  // Configuration
  private visualApertureM: number;
  private irApertureM: number;
  private focalLengthM: number;
  private pixelCount: number;
  private fieldOfViewDegrees: number;
  private minDetectableFlux: number;

  // State
  public mode: OpticalMode = 'combined';
  public powered: boolean = true;
  public operational: boolean = true;

  // Detection
  private contacts: Map<string, OpticalContact> = new Map();

  // Scan
  private scanAzimuth: number = 0;
  private scanElevation: number = 0;

  // Power
  private currentPowerDraw: number = 0;

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  // Constants
  private readonly STEFAN_BOLTZMANN = 5.670374419e-8; // W/m^2/K^4
  private readonly SPEED_OF_LIGHT = 299792458; // m/s

  constructor(config?: OpticalConfiguration) {
    this.visualApertureM = config?.visualApertureM || 0.2; // 20cm telescope
    this.irApertureM = config?.irApertureM || 0.15; // 15cm IR sensor
    this.focalLengthM = config?.focalLengthM || 2.0; // 2m focal length
    this.pixelCount = config?.pixelCount || 2048 * 2048; // 4MP sensor
    this.fieldOfViewDegrees = config?.fieldOfViewDegrees || 10; // 10 degree FOV
    this.minDetectableFlux = config?.minDetectableFlux || 1e-12; // W/m^2 (very sensitive)
  }

  /**
   * Set optical sensor mode
   */
  public setMode(mode: OpticalMode): void {
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
   * Update optical sensors
   */
  public update(
    dt: number,
    shipPosition: { x: number; y: number; z: number },
    shipOrientation: { pitch: number; roll: number; yaw: number },
    targets: Array<{
      id: string;
      position: { x: number; y: number; z: number };
      velocity: { x: number; y: number; z: number };
      radius: number; // meters
      temperature: number; // K
      engineFiring: boolean;
    }>
  ): void {
    if (!this.powered || this.mode === 'off') {
      this.currentPowerDraw = 0;
      return;
    }

    // Process detections
    this.processDetections(shipPosition, shipOrientation, targets);

    // Clean up old contacts
    this.cleanupContacts();
  }

  /**
   * Process optical detections
   */
  private processDetections(
    shipPosition: { x: number; y: number; z: number },
    shipOrientation: { pitch: number; roll: number; yaw: number },
    targets: Array<{
      id: string;
      position: { x: number; y: number; z: number };
      velocity: { x: number; y: number; z: number };
      radius: number;
      temperature: number;
      engineFiring: boolean;
    }>
  ): void {
    for (const target of targets) {
      // Calculate range and bearing
      const dx = target.position.x - shipPosition.x;
      const dy = target.position.y - shipPosition.y;
      const dz = target.position.z - shipPosition.z;
      const rangeKm = Math.sqrt(dx**2 + dy**2 + dz**2);
      const rangeM = rangeKm * 1000;

      // Calculate bearing relative to ship
      const bearing = Math.atan2(dy, dx) * (180 / Math.PI) - shipOrientation.yaw;
      const elevation = Math.atan2(dz, Math.sqrt(dx**2 + dy**2)) * (180 / Math.PI) - shipOrientation.pitch;

      // Check if in field of view
      if (Math.abs(bearing) > this.fieldOfViewDegrees / 2) continue;
      if (Math.abs(elevation) > this.fieldOfViewDegrees / 2) continue;

      // Calculate angular size (arc-seconds)
      const angularSizeRad = (target.radius * 2) / rangeM; // radians
      const angularSizeArcsec = angularSizeRad * (180 / Math.PI) * 3600; // arc-seconds

      // Calculate visual detection
      let visualDetected = false;
      let visualMagnitude = 99; // Very faint

      if (this.mode === 'visual' || this.mode === 'combined') {
        // Reflected sunlight (simplified - assumes sun is nearby)
        const albedo = 0.3; // Assume 30% reflectivity
        const solarFlux = 1361; // W/m^2 at 1 AU
        const targetArea = Math.PI * target.radius * target.radius;
        const reflectedPower = solarFlux * targetArea * albedo;

        // Power received at sensor
        const solidAngle = targetArea / (rangeM * rangeM);
        const receivedFlux = reflectedPower * solidAngle / (Math.PI * this.visualApertureM * this.visualApertureM / 4);

        if (receivedFlux > this.minDetectableFlux) {
          visualDetected = true;
          // Convert to visual magnitude (simplified)
          visualMagnitude = -2.5 * Math.log10(receivedFlux / 2.5e-8); // Vega as reference
        }
      }

      // Calculate IR detection
      let irDetected = false;
      let irSignature = 0;
      let estimatedTemp = 0;

      if (this.mode === 'infrared' || this.mode === 'combined') {
        // Blackbody radiation
        const surfaceArea = 4 * Math.PI * target.radius * target.radius;
        const radiantPower = this.STEFAN_BOLTZMANN * target.temperature**4 * surfaceArea;

        // Add engine plume contribution
        if (target.engineFiring) {
          const plumeTemp = 3000; // K (hot exhaust)
          const plumeArea = Math.PI * (target.radius * 0.5)**2; // Half ship radius
          const plumePower = this.STEFAN_BOLTZMANN * plumeTemp**4 * plumeArea;
          irSignature = (radiantPower + plumePower) / (4 * Math.PI); // W/sr
        } else {
          irSignature = radiantPower / (4 * Math.PI); // W/sr
        }

        // Power received at sensor
        const sensorArea = Math.PI * this.irApertureM * this.irApertureM / 4;
        const receivedPowerIR = irSignature * (sensorArea / (rangeM * rangeM));

        if (receivedPowerIR > this.minDetectableFlux) {
          irDetected = true;
          estimatedTemp = target.temperature;
        }
      }

      // Detect if either visual or IR detected
      if (visualDetected || irDetected) {
        this.detectTarget(
          target.id,
          bearing,
          elevation,
          angularSizeArcsec,
          rangeKm,
          visualMagnitude,
          irSignature,
          estimatedTemp,
          target.engineFiring,
          target.position
        );
      }
    }
  }

  /**
   * Detect target
   */
  private detectTarget(
    id: string,
    bearing: number,
    elevation: number,
    angularSize: number,
    estimatedRange: number,
    visualMagnitude: number,
    irSignature: number,
    estimatedTemperature: number,
    engineFiring: boolean,
    position: { x: number; y: number; z: number }
  ): void {
    const existingContact = this.contacts.get(id);

    // Classify target type
    let targetType: TargetType = 'unknown';
    if (angularSize < 0.1) {
      targetType = 'point_source';
    } else if (angularSize > 1.0) {
      targetType = 'extended';
    }
    if (engineFiring) {
      targetType = 'engine_plume';
    }

    if (existingContact) {
      // Update existing contact
      existingContact.bearing = bearing;
      existingContact.elevation = elevation;
      existingContact.angularSize = angularSize;
      existingContact.estimatedRange = estimatedRange;
      existingContact.visualMagnitude = visualMagnitude;
      existingContact.irSignature = irSignature;
      existingContact.estimatedTemperature = estimatedTemperature;
      existingContact.lastUpdate = Date.now();
      existingContact.trackQuality = Math.min(1, existingContact.trackQuality + 0.05);
      existingContact.position = position;
    } else {
      // New contact
      const contact: OpticalContact = {
        id,
        bearing,
        elevation,
        angularSize,
        estimatedRange,
        visualMagnitude,
        irSignature,
        estimatedTemperature,
        trackQuality: 0.5,
        firstDetection: Date.now(),
        lastUpdate: Date.now(),
        targetType,
        position
      };

      this.contacts.set(id, contact);
      this.logEvent('new_contact', { id, bearing, elevation, type: targetType });
    }
  }

  /**
   * Clean up old contacts
   */
  private cleanupContacts(): void {
    const now = Date.now();
    const maxAge = 3000; // 3 seconds (optical sensors lose contact quickly)

    for (const [id, contact] of this.contacts) {
      if (now - contact.lastUpdate > maxAge) {
        this.contacts.delete(id);
        this.logEvent('contact_lost', { id });
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
        this.currentPowerDraw = 10; // 10W standby
        break;
      case 'visual':
        this.currentPowerDraw = 50; // 50W visual only
        break;
      case 'infrared':
        this.currentPowerDraw = 150; // 150W IR (needs cooling)
        break;
      case 'combined':
        this.currentPowerDraw = 200; // 200W both
        break;
    }
  }

  /**
   * Get all contacts
   */
  public getContacts(): OpticalContact[] {
    return Array.from(this.contacts.values());
  }

  /**
   * Get contact by ID
   */
  public getContact(id: string): OpticalContact | undefined {
    return this.contacts.get(id);
  }

  /**
   * Get current power draw
   */
  public getPowerDraw(): number {
    return this.currentPowerDraw;
  }

  /**
   * Estimate range to target from angular size (if target type known)
   */
  public estimateRange(angularSizeArcsec: number, knownDiameterM: number): number {
    const angularSizeRad = angularSizeArcsec / 3600 * (Math.PI / 180);
    const rangeM = knownDiameterM / angularSizeRad;
    return rangeM / 1000; // km
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
      contactCount: this.contacts.size,
      contacts: this.getContacts(),
      configuration: {
        visualApertureM: this.visualApertureM,
        irApertureM: this.irApertureM,
        fieldOfViewDegrees: this.fieldOfViewDegrees,
        minDetectableFlux: this.minDetectableFlux
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
