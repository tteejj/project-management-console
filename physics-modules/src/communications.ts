/**
 * Communications Subsystem
 *
 * Simulates:
 * - Multiple radio transceivers (VHF, UHF, S-band, X-band)
 * - Signal strength and link quality
 * - Data rate capabilities
 * - Range calculations with inverse square law
 * - Antenna gain and directionality
 * - Atmospheric/plasma interference
 * - Encryption and signal processing
 * - Emergency beacon
 */

export interface RadioTransceiver {
  id: string;
  band: 'VHF' | 'UHF' | 'S-band' | 'X-band' | 'Ka-band';
  frequencyMHz: number;
  transmitPowerW: number;
  operational: boolean;
  transmitting: boolean;
  receiving: boolean;
  maxDataRateMbps: number;
  currentDataRateMbps: number;
}

export interface Antenna {
  id: string;
  type: 'omnidirectional' | 'directional' | 'phased_array';
  gain: number; // dBi
  azimuthDeg: number; // Pointing direction
  elevationDeg: number;
  operational: boolean;
}

export interface CommunicationsConfig {
  transceivers?: RadioTransceiver[];
  antennas?: Antenna[];
  encryptionEnabled?: boolean;
  emergencyBeaconPowerW?: number;
  powerConsumptionW?: number;
}

export interface CommLink {
  targetId: string;
  rangeKm: number;
  signalStrength: number; // 0-1
  linkQuality: number; // 0-1
  dataRate: number; // Mbps
  latencyMs: number;
  interference: number; // 0-1
}

export class CommunicationsSystem {
  // Hardware
  public transceivers: Map<string, RadioTransceiver>;
  public antennas: Map<string, Antenna>;
  public encryptionEnabled: boolean;
  public emergencyBeaconPowerW: number;

  // State
  public operational: boolean = true;
  public isPowered: boolean = true;
  public emergencyBeaconActive: boolean = false;
  public activeLinks: Map<string, CommLink> = new Map();

  // Power tracking
  public currentPowerDraw: number = 0; // W
  public basePowerDraw: number = 30; // W (standby)
  public powerConsumptionW: number;

  // Signal processing
  public processingLoad: number = 0; // 0-1
  public encryptionOverhead: number = 0.1; // 10% overhead when encrypting

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor(config?: CommunicationsConfig) {
    this.transceivers = new Map();
    this.antennas = new Map();

    if (config?.transceivers) {
      config.transceivers.forEach(t => this.transceivers.set(t.id, t));
    } else {
      this.createDefaultTransceivers();
    }

    if (config?.antennas) {
      config.antennas.forEach(a => this.antennas.set(a.id, a));
    } else {
      this.createDefaultAntennas();
    }

    this.encryptionEnabled = config?.encryptionEnabled !== undefined ? config.encryptionEnabled : true;
    this.emergencyBeaconPowerW = config?.emergencyBeaconPowerW || 50.0;
    this.powerConsumptionW = config?.powerConsumptionW || 200.0;

    this.currentPowerDraw = this.basePowerDraw;
  }

  private createDefaultTransceivers(): void {
    const defaultTransceivers: RadioTransceiver[] = [
      {
        id: 'vhf_primary',
        band: 'VHF',
        frequencyMHz: 121.5,
        transmitPowerW: 10,
        operational: true,
        transmitting: false,
        receiving: true,
        maxDataRateMbps: 0.01, // 10 kbps (voice)
        currentDataRateMbps: 0
      },
      {
        id: 'uhf_primary',
        band: 'UHF',
        frequencyMHz: 400,
        transmitPowerW: 25,
        operational: true,
        transmitting: false,
        receiving: true,
        maxDataRateMbps: 1.0, // 1 Mbps
        currentDataRateMbps: 0
      },
      {
        id: 's_band_primary',
        band: 'S-band',
        frequencyMHz: 2200,
        transmitPowerW: 100,
        operational: true,
        transmitting: false,
        receiving: true,
        maxDataRateMbps: 50.0, // 50 Mbps
        currentDataRateMbps: 0
      },
      {
        id: 'x_band_high_gain',
        band: 'X-band',
        frequencyMHz: 8400,
        transmitPowerW: 50,
        operational: true,
        transmitting: false,
        receiving: true,
        maxDataRateMbps: 300.0, // 300 Mbps
        currentDataRateMbps: 0
      }
    ];

    defaultTransceivers.forEach(t => this.transceivers.set(t.id, t));
  }

  private createDefaultAntennas(): void {
    const defaultAntennas: Antenna[] = [
      {
        id: 'omni_primary',
        type: 'omnidirectional',
        gain: 2.0, // dBi
        azimuthDeg: 0,
        elevationDeg: 0,
        operational: true
      },
      {
        id: 'high_gain_directional',
        type: 'directional',
        gain: 35.0, // dBi (parabolic dish)
        azimuthDeg: 0,
        elevationDeg: 0,
        operational: true
      },
      {
        id: 'phased_array',
        type: 'phased_array',
        gain: 25.0, // dBi
        azimuthDeg: 0,
        elevationDeg: 0,
        operational: true
      }
    ];

    defaultAntennas.forEach(a => this.antennas.set(a.id, a));
  }

  /**
   * Establish communication link
   */
  public establishLink(
    targetId: string,
    rangeKm: number,
    transceiverId: string,
    antennaId: string
  ): boolean {
    if (!this.operational || !this.isPowered) {
      this.logEvent('link_failed', { reason: 'system_offline', targetId });
      return false;
    }

    const transceiver = this.transceivers.get(transceiverId);
    const antenna = this.antennas.get(antennaId);

    if (!transceiver || !transceiver.operational) {
      this.logEvent('link_failed', { reason: 'transceiver_unavailable', targetId });
      return false;
    }

    if (!antenna || !antenna.operational) {
      this.logEvent('link_failed', { reason: 'antenna_unavailable', targetId });
      return false;
    }

    // Calculate link parameters
    const link = this.calculateLinkQuality(transceiver, antenna, rangeKm);
    link.targetId = targetId;
    link.rangeKm = rangeKm;

    if (link.linkQuality < 0.2) {
      this.logEvent('link_failed', { reason: 'signal_too_weak', targetId, quality: link.linkQuality });
      return false;
    }

    this.activeLinks.set(targetId, link);
    transceiver.transmitting = true;
    transceiver.receiving = true;
    transceiver.currentDataRateMbps = link.dataRate;

    this.updatePowerDraw();
    this.logEvent('link_established', { targetId, link });
    return true;
  }

  /**
   * Calculate link quality based on physics
   */
  private calculateLinkQuality(
    transceiver: RadioTransceiver,
    antenna: Antenna,
    rangeKm: number
  ): CommLink {
    // Friis transmission equation (simplified)
    // Path loss = 20*log10(distance) + 20*log10(frequency) + 32.45 - gain
    const freqGHz = transceiver.frequencyMHz / 1000.0;
    const pathLossDb = 20 * Math.log10(rangeKm) + 20 * Math.log10(freqGHz) + 92.45 - antenna.gain;

    // Signal strength (inverse square law approximation)
    const signalStrength = Math.max(0, 1.0 - pathLossDb / 200.0);

    // Interference (simplified - could be more complex)
    const interference = 0.05 + Math.random() * 0.05; // 5-10% base interference

    // Link quality
    const linkQuality = Math.max(0, Math.min(1.0, signalStrength * (1.0 - interference)));

    // Data rate scales with link quality
    let dataRate = transceiver.maxDataRateMbps * linkQuality;

    // Apply encryption overhead
    if (this.encryptionEnabled) {
      dataRate *= (1.0 - this.encryptionOverhead);
    }

    // Latency (speed of light + processing)
    const lightSpeedKmMs = 300; // km/ms
    const propagationDelay = rangeKm / lightSpeedKmMs;
    const processingDelay = this.encryptionEnabled ? 5 : 1; // ms
    const latencyMs = propagationDelay + processingDelay;

    return {
      targetId: '',
      rangeKm,
      signalStrength,
      linkQuality,
      dataRate,
      latencyMs,
      interference
    };
  }

  /**
   * Close communication link
   */
  public closeLink(targetId: string): void {
    const link = this.activeLinks.get(targetId);
    if (!link) return;

    this.activeLinks.delete(targetId);

    // Stop transmitting on transceiver if no other links using it
    this.transceivers.forEach(t => {
      if (t.transmitting && this.activeLinks.size === 0) {
        t.transmitting = false;
        t.currentDataRateMbps = 0;
      }
    });

    this.updatePowerDraw();
    this.logEvent('link_closed', { targetId });
  }

  /**
   * Point directional antenna
   */
  public pointAntenna(antennaId: string, azimuthDeg: number, elevationDeg: number): boolean {
    const antenna = this.antennas.get(antennaId);
    if (!antenna || !antenna.operational) return false;

    if (antenna.type === 'omnidirectional') {
      this.logEvent('antenna_point_failed', { reason: 'omnidirectional', antennaId });
      return false;
    }

    antenna.azimuthDeg = azimuthDeg;
    antenna.elevationDeg = elevationDeg;
    this.logEvent('antenna_pointed', { antennaId, azimuthDeg, elevationDeg });
    return true;
  }

  /**
   * Activate emergency beacon
   */
  public activateEmergencyBeacon(): void {
    this.emergencyBeaconActive = true;
    this.updatePowerDraw();
    this.logEvent('emergency_beacon_activated', {});
  }

  /**
   * Deactivate emergency beacon
   */
  public deactivateEmergencyBeacon(): void {
    this.emergencyBeaconActive = false;
    this.updatePowerDraw();
    this.logEvent('emergency_beacon_deactivated', {});
  }

  /**
   * Toggle encryption
   */
  public setEncryption(enabled: boolean): void {
    this.encryptionEnabled = enabled;
    this.logEvent('encryption_toggled', { enabled });

    // Recalculate all active links
    this.activeLinks.forEach((link, targetId) => {
      // Find transceiver/antenna for this link (simplified - just update data rates)
      if (enabled) {
        link.dataRate *= (1.0 - this.encryptionOverhead);
      } else {
        link.dataRate /= (1.0 - this.encryptionOverhead);
      }
    });
  }

  /**
   * Update power consumption
   */
  private updatePowerDraw(): void {
    let totalPower = this.basePowerDraw;

    // Add power for transmitting transceivers
    this.transceivers.forEach(t => {
      if (t.transmitting) {
        totalPower += t.transmitPowerW;
      }
      if (t.receiving) {
        totalPower += 5; // Receiver power (small)
      }
    });

    // Emergency beacon
    if (this.emergencyBeaconActive) {
      totalPower += this.emergencyBeaconPowerW;
    }

    this.currentPowerDraw = totalPower;
  }

  /**
   * Update communication system
   */
  public update(dt: number): void {
    if (!this.isPowered) {
      this.operational = false;
      this.currentPowerDraw = 0;
      this.activeLinks.clear();
      this.emergencyBeaconActive = false;
      this.transceivers.forEach(t => {
        t.transmitting = false;
        t.receiving = false;
      });
      return;
    }

    if (!this.operational) return;

    // Update processing load based on active links and data rates
    let totalDataRate = 0;
    this.activeLinks.forEach(link => {
      totalDataRate += link.dataRate;
    });

    // Max processing capacity (arbitrary units based on transceivers)
    const maxCapacity = Array.from(this.transceivers.values()).reduce(
      (sum, t) => sum + t.maxDataRateMbps,
      0
    );

    this.processingLoad = Math.min(1.0, totalDataRate / maxCapacity);
  }

  /**
   * Apply damage
   */
  public applyDamage(severity: number, componentId?: string): void {
    if (componentId) {
      // Damage specific component
      const transceiver = this.transceivers.get(componentId);
      if (transceiver) {
        transceiver.operational = false;
        transceiver.transmitting = false;
        transceiver.receiving = false;
        this.logEvent('transceiver_damaged', { componentId, severity });
        return;
      }

      const antenna = this.antennas.get(componentId);
      if (antenna) {
        antenna.operational = false;
        this.logEvent('antenna_damaged', { componentId, severity });
        return;
      }
    } else {
      // General system damage
      if (severity > 0.7) {
        this.operational = false;
        this.activeLinks.clear();
        this.logEvent('communications_destroyed', { severity });
      } else if (severity > 0.3) {
        // Damage random transceiver
        const transceiverIds = Array.from(this.transceivers.keys());
        if (transceiverIds.length > 0) {
          const randomId = transceiverIds[Math.floor(Math.random() * transceiverIds.length)];
          this.applyDamage(severity, randomId);
        }
      }
    }
  }

  /**
   * Repair system
   */
  public repair(componentId?: string): void {
    if (componentId) {
      const transceiver = this.transceivers.get(componentId);
      if (transceiver) {
        transceiver.operational = true;
        this.logEvent('transceiver_repaired', { componentId });
        return;
      }

      const antenna = this.antennas.get(componentId);
      if (antenna) {
        antenna.operational = true;
        this.logEvent('antenna_repaired', { componentId });
        return;
      }
    } else {
      this.operational = true;
      this.transceivers.forEach(t => (t.operational = true));
      this.antennas.forEach(a => (a.operational = true));
      this.logEvent('communications_repaired', {});
    }
  }

  /**
   * Set power state
   */
  public setPower(powered: boolean): void {
    this.isPowered = powered;
    if (!powered) {
      this.currentPowerDraw = 0;
    } else {
      this.updatePowerDraw();
    }
  }

  public getState() {
    const transceiversArray: any[] = [];
    this.transceivers.forEach((t, id) => {
      transceiversArray.push({ ...t });
    });

    const antennasArray: any[] = [];
    this.antennas.forEach((a, id) => {
      antennasArray.push({ ...a });
    });

    const linksArray: any[] = [];
    this.activeLinks.forEach((link, id) => {
      linksArray.push({ id, ...link });
    });

    return {
      operational: this.operational,
      isPowered: this.isPowered,
      transceivers: transceiversArray,
      antennas: antennasArray,
      activeLinks: linksArray,
      emergencyBeaconActive: this.emergencyBeaconActive,
      encryptionEnabled: this.encryptionEnabled,
      processingLoad: this.processingLoad,
      powerDraw: this.currentPowerDraw
    };
  }

  private logEvent(type: string, data: any): void {
    this.events.push({ time: Date.now(), type, data });
  }
}
