/**
 * Docking System Subsystem
 *
 * Simulates:
 * - Docking port mechanisms (probe/drogue, androgynous)
 * - Capture and latching sequences
 * - Seal integrity and atmosphere equalization
 * - Alignment sensors and guidance
 * - Hard dock vs soft dock states
 * - Resource transfer connections (power, data, fluids)
 */

export interface DockingPort {
  id: string;
  type: 'probe' | 'drogue' | 'androgynous';
  status: 'available' | 'approaching' | 'captured' | 'hard_docked' | 'damaged';
  connectedTo: string | null; // ID of connected port
  sealIntegrity: number; // 0-1, seal quality
  alignmentError: number; // degrees, misalignment
  hasResourceConnections: boolean; // Can transfer power/fluids
}

export interface DockingConfig {
  ports?: DockingPort[];
  captureRangeMM?: number; // Capture mechanism range
  alignmentToleranceDeg?: number; // Max misalignment for capture
  latchTimeS?: number; // Time to complete hard dock
  powerConsumptionW?: number; // Power draw during operation
}

export interface DockingTarget {
  relativePosition: { x: number; y: number; z: number }; // meters
  relativeVelocity: { x: number; y: number; z: number }; // m/s
  relativeAttitude: { roll: number; pitch: number; yaw: number }; // degrees
  portType: 'probe' | 'drogue' | 'androgynous';
}

export class DockingSystem {
  // Ports
  public ports: Map<string, DockingPort>;

  // Hardware specs
  public captureRangeMM: number;
  public alignmentToleranceDeg: number;
  public latchTimeS: number;
  public powerConsumptionW: number;

  // State
  public operational: boolean = true;
  public isPowered: boolean = true;
  public activePort: string | null = null;
  public dockingInProgress: boolean = false;
  public latchProgress: number = 0; // 0-1

  // Power tracking
  public currentPowerDraw: number = 0; // W
  public basePowerDraw: number = 10; // W (standby)

  // Guidance
  public targetData: DockingTarget | null = null;
  public approachRate: number = 0; // m/s (relative velocity magnitude)

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor(config?: DockingConfig) {
    this.ports = new Map();

    if (config?.ports) {
      config.ports.forEach(port => {
        this.ports.set(port.id, port);
      });
    } else {
      this.createDefaultPorts();
    }

    this.captureRangeMM = config?.captureRangeMM || 100.0; // 10 cm
    this.alignmentToleranceDeg = config?.alignmentToleranceDeg || 3.0;
    this.latchTimeS = config?.latchTimeS || 30.0;
    this.powerConsumptionW = config?.powerConsumptionW || 200.0;

    this.currentPowerDraw = this.basePowerDraw;
  }

  private createDefaultPorts(): void {
    const defaultPorts: DockingPort[] = [
      {
        id: 'port_fwd',
        type: 'androgynous',
        status: 'available',
        connectedTo: null,
        sealIntegrity: 1.0,
        alignmentError: 0,
        hasResourceConnections: true
      },
      {
        id: 'port_aft',
        type: 'androgynous',
        status: 'available',
        connectedTo: null,
        sealIntegrity: 1.0,
        alignmentError: 0,
        hasResourceConnections: true
      },
      {
        id: 'port_zenith',
        type: 'probe',
        status: 'available',
        connectedTo: null,
        sealIntegrity: 1.0,
        alignmentError: 0,
        hasResourceConnections: false
      }
    ];

    defaultPorts.forEach(port => {
      this.ports.set(port.id, port);
    });
  }

  /**
   * Initiate docking sequence
   */
  public initiateDocking(portId: string, target: DockingTarget): boolean {
    if (!this.operational || !this.isPowered) {
      this.logEvent('docking_failed', { reason: 'system_offline' });
      return false;
    }

    const port = this.ports.get(portId);
    if (!port) {
      this.logEvent('docking_failed', { reason: 'invalid_port', portId });
      return false;
    }

    if (port.status !== 'available') {
      this.logEvent('docking_failed', { reason: 'port_unavailable', portId, status: port.status });
      return false;
    }

    // Check port compatibility
    if (!this.isPortCompatible(port.type, target.portType)) {
      this.logEvent('docking_failed', { reason: 'incompatible_ports', ourType: port.type, theirType: target.portType });
      return false;
    }

    this.activePort = portId;
    this.targetData = target;
    this.dockingInProgress = true;
    port.status = 'approaching';
    this.currentPowerDraw = this.basePowerDraw + this.powerConsumptionW;

    this.logEvent('docking_initiated', { portId, target });
    return true;
  }

  /**
   * Check if two port types are compatible
   */
  private isPortCompatible(typeA: string, typeB: string): boolean {
    if (typeA === 'androgynous' || typeB === 'androgynous') return true;
    if (typeA === 'probe' && typeB === 'drogue') return true;
    if (typeA === 'drogue' && typeB === 'probe') return true;
    return false;
  }

  /**
   * Attempt capture (soft dock)
   */
  public attemptCapture(): boolean {
    if (!this.dockingInProgress || !this.activePort || !this.targetData) {
      return false;
    }

    const port = this.ports.get(this.activePort)!;
    const target = this.targetData;

    // Calculate distance
    const distance = Math.sqrt(
      target.relativePosition.x ** 2 +
      target.relativePosition.y ** 2 +
      target.relativePosition.z ** 2
    ) * 1000; // convert to mm

    // Calculate approach velocity
    this.approachRate = Math.sqrt(
      target.relativeVelocity.x ** 2 +
      target.relativeVelocity.y ** 2 +
      target.relativeVelocity.z ** 2
    );

    // Calculate total alignment error
    const alignmentError = Math.sqrt(
      target.relativeAttitude.roll ** 2 +
      target.relativeAttitude.pitch ** 2 +
      target.relativeAttitude.yaw ** 2
    );

    port.alignmentError = alignmentError;

    // Check capture criteria
    if (distance > this.captureRangeMM) {
      this.logEvent('capture_failed', { reason: 'out_of_range', distance });
      return false;
    }

    if (alignmentError > this.alignmentToleranceDeg) {
      this.logEvent('capture_failed', { reason: 'misaligned', alignmentError });
      return false;
    }

    if (this.approachRate > 0.2) { // Max 20 cm/s approach
      this.logEvent('capture_failed', { reason: 'approach_too_fast', rate: this.approachRate });
      return false;
    }

    // Successful capture!
    port.status = 'captured';
    this.latchProgress = 0;
    this.logEvent('capture_success', { portId: this.activePort, alignmentError });
    return true;
  }

  /**
   * Complete hard dock
   */
  public completeHardDock(): boolean {
    if (!this.activePort) return false;

    const port = this.ports.get(this.activePort)!;

    if (port.status !== 'captured') {
      this.logEvent('hard_dock_failed', { reason: 'not_captured', status: port.status });
      return false;
    }

    if (this.latchProgress < 1.0) {
      this.logEvent('hard_dock_failed', { reason: 'latches_not_engaged', progress: this.latchProgress });
      return false;
    }

    port.status = 'hard_docked';
    port.connectedTo = 'external_vessel'; // In real scenario, would be vessel ID

    // Check seal integrity
    port.sealIntegrity = 1.0 - port.alignmentError / 10.0;

    this.dockingInProgress = false;
    this.currentPowerDraw = this.basePowerDraw;

    this.logEvent('hard_dock_complete', {
      portId: this.activePort,
      sealIntegrity: port.sealIntegrity,
      alignmentError: port.alignmentError
    });

    return true;
  }

  /**
   * Undock from a port
   */
  public undock(portId: string): boolean {
    const port = this.ports.get(portId);
    if (!port) return false;

    if (port.status !== 'hard_docked' && port.status !== 'captured') {
      this.logEvent('undock_failed', { reason: 'not_docked', status: port.status });
      return false;
    }

    port.status = 'available';
    port.connectedTo = null;
    port.alignmentError = 0;
    port.sealIntegrity = 1.0;

    this.logEvent('undocked', { portId });
    return true;
  }

  /**
   * Update docking system
   */
  public update(dt: number): void {
    if (!this.isPowered) {
      this.operational = false;
      this.currentPowerDraw = 0;
      return;
    }

    if (!this.operational) return;

    // Update latching progress
    if (this.activePort) {
      const port = this.ports.get(this.activePort);
      if (port && port.status === 'captured') {
        this.latchProgress += dt / this.latchTimeS;
        if (this.latchProgress >= 1.0) {
          this.latchProgress = 1.0;
          this.logEvent('latches_engaged', { portId: this.activePort });
        }
      }
    }
  }

  /**
   * Check if atmosphere can be equalized (safe to open hatch)
   */
  public canEqualizeAtmosphere(portId: string): boolean {
    const port = this.ports.get(portId);
    if (!port) return false;

    return port.status === 'hard_docked' && port.sealIntegrity > 0.9;
  }

  /**
   * Get docking alignment guidance for display
   */
  public getAlignmentGuidance(): {
    distance: number;
    rate: number;
    alignment: number;
    status: string;
  } | null {
    if (!this.targetData || !this.activePort) return null;

    const port = this.ports.get(this.activePort)!;
    const target = this.targetData;

    const distance = Math.sqrt(
      target.relativePosition.x ** 2 +
      target.relativePosition.y ** 2 +
      target.relativePosition.z ** 2
    );

    return {
      distance: distance,
      rate: this.approachRate,
      alignment: port.alignmentError,
      status: port.status
    };
  }

  /**
   * Apply damage
   */
  public applyDamage(severity: number, portId?: string): void {
    if (portId) {
      const port = this.ports.get(portId);
      if (port) {
        if (severity > 0.5) {
          port.status = 'damaged';
          port.sealIntegrity = 0;
          this.logEvent('port_damaged', { portId, severity });
        } else {
          port.sealIntegrity *= (1 - severity);
          this.logEvent('port_degraded', { portId, severity, newIntegrity: port.sealIntegrity });
        }
      }
    } else {
      if (severity > 0.7) {
        this.operational = false;
        this.logEvent('docking_system_destroyed', { severity });
      }
    }
  }

  /**
   * Repair system
   */
  public repair(portId?: string): void {
    if (portId) {
      const port = this.ports.get(portId);
      if (port) {
        port.status = 'available';
        port.sealIntegrity = 1.0;
        port.alignmentError = 0;
        this.logEvent('port_repaired', { portId });
      }
    } else {
      this.operational = true;
      this.logEvent('docking_system_repaired', {});
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
      this.currentPowerDraw = this.basePowerDraw;
    }
  }

  public getState() {
    const portsArray: any[] = [];
    this.ports.forEach((port) => {
      portsArray.push({ ...port });
    });

    return {
      operational: this.operational,
      isPowered: this.isPowered,
      ports: portsArray,
      activePort: this.activePort,
      dockingInProgress: this.dockingInProgress,
      latchProgress: this.latchProgress,
      powerDraw: this.currentPowerDraw,
      alignmentGuidance: this.getAlignmentGuidance()
    };
  }

  private logEvent(type: string, data: any): void {
    this.events.push({ time: Date.now(), type, data });
  }
}
