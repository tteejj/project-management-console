/**
 * RCS (Reaction Control System) Physics Module
 *
 * Simulates:
 * - 12 individual cold-gas thrusters for attitude control
 * - 4 control groups: pitch, yaw, roll, translation
 * - Thruster coupling and moment arm calculations
 * - Individual thruster on/off control
 * - Fuel consumption from compressed gas bottles
 * - Thrust and torque generation
 * - Minimum pulse width and duty cycle limits
 */

export interface Thruster {
  id: number;
  name: string;
  position: { x: number; y: number; z: number };  // m from CG
  direction: { x: number; y: number; z: number }; // unit vector
  thrustN: number;                                 // Thrust per thruster
  active: boolean;
  totalFiredSeconds: number;
  pulseCount: number;
}

export interface ThrusterGroup {
  name: string;
  thrusterIds: number[];                          // Which thrusters in this group
  active: boolean;
}

export interface RCSConfig {
  thrusterThrustN?: number;
  minPulseWidthS?: number;
  maxDutyCycle?: number;
}

export class RCSSystem {
  public thrusters: Thruster[];
  public groups: Map<string, ThrusterGroup>;

  // Configuration
  public thrusterThrustN: number;
  public minPulseWidthS: number;
  public maxDutyCycle: number;

  // Tracking
  public totalFuelConsumedKg: number = 0;
  public events: Array<{ time: number; type: string; data: any }> = [];

  // Constants
  private readonly SPECIFIC_IMPULSE_SEC = 65;  // Cold gas thrusters (N2)
  private readonly G0 = 9.80665;

  constructor(config?: RCSConfig) {
    this.thrusterThrustN = config?.thrusterThrustN || 25;       // 25N per thruster
    this.minPulseWidthS = config?.minPulseWidthS || 0.020;      // 20ms minimum pulse
    this.maxDutyCycle = config?.maxDutyCycle || 0.5;            // 50% max duty cycle

    this.thrusters = this.createDefaultThrusters();
    this.groups = this.createDefaultGroups();
  }

  /**
   * Create 12 thrusters in standard configuration
   * 4 clusters of 3 thrusters each (forward, aft, left, right)
   */
  private createDefaultThrusters(): Thruster[] {
    return [
      // Forward cluster (pitch/yaw)
      {
        id: 0,
        name: 'FWD_UP',
        position: { x: 2.5, y: 0, z: 0.8 },
        direction: { x: 0, y: 0, z: 1 },  // Pitch down
        thrustN: this.thrusterThrustN,
        active: false,
        totalFiredSeconds: 0,
        pulseCount: 0
      },
      {
        id: 1,
        name: 'FWD_DOWN',
        position: { x: 2.5, y: 0, z: -0.8 },
        direction: { x: 0, y: 0, z: -1 }, // Pitch up
        thrustN: this.thrusterThrustN,
        active: false,
        totalFiredSeconds: 0,
        pulseCount: 0
      },
      {
        id: 2,
        name: 'FWD_RIGHT',
        position: { x: 2.5, y: 0.8, z: 0 },
        direction: { x: 0, y: 1, z: 0 },  // Yaw left
        thrustN: this.thrusterThrustN,
        active: false,
        totalFiredSeconds: 0,
        pulseCount: 0
      },

      // Aft cluster (pitch/yaw)
      {
        id: 3,
        name: 'AFT_UP',
        position: { x: -2.5, y: 0, z: 0.8 },
        direction: { x: 0, y: 0, z: 1 },  // Fires up to create pitch up moment
        thrustN: this.thrusterThrustN,
        active: false,
        totalFiredSeconds: 0,
        pulseCount: 0
      },
      {
        id: 4,
        name: 'AFT_DOWN',
        position: { x: -2.5, y: 0, z: -0.8 },
        direction: { x: 0, y: 0, z: -1 }, // Fires down to create pitch down moment
        thrustN: this.thrusterThrustN,
        active: false,
        totalFiredSeconds: 0,
        pulseCount: 0
      },
      {
        id: 5,
        name: 'AFT_LEFT',
        position: { x: -2.5, y: -0.8, z: 0 },
        direction: { x: 0, y: -1, z: 0 }, // Yaw right
        thrustN: this.thrusterThrustN,
        active: false,
        totalFiredSeconds: 0,
        pulseCount: 0
      },

      // Left cluster (roll/translation)
      {
        id: 6,
        name: 'LEFT_FWD',
        position: { x: 0.5, y: -1.0, z: 0 },
        direction: { x: 0, y: 1, z: 0 },  // Translate right
        thrustN: this.thrusterThrustN,
        active: false,
        totalFiredSeconds: 0,
        pulseCount: 0
      },
      {
        id: 7,
        name: 'LEFT_AFT',
        position: { x: -0.5, y: -1.0, z: 0 },
        direction: { x: 0, y: 1, z: 0 },  // Translate right
        thrustN: this.thrusterThrustN,
        active: false,
        totalFiredSeconds: 0,
        pulseCount: 0
      },
      {
        id: 8,
        name: 'LEFT_ROLL',
        position: { x: 0, y: -1.0, z: 0.5 },
        direction: { x: 0, y: 0, z: -1 }, // Roll CW (looking from behind)
        thrustN: this.thrusterThrustN,
        active: false,
        totalFiredSeconds: 0,
        pulseCount: 0
      },

      // Right cluster (roll/translation)
      {
        id: 9,
        name: 'RIGHT_FWD',
        position: { x: 0.5, y: 1.0, z: 0 },
        direction: { x: 0, y: -1, z: 0 }, // Translate left
        thrustN: this.thrusterThrustN,
        active: false,
        totalFiredSeconds: 0,
        pulseCount: 0
      },
      {
        id: 10,
        name: 'RIGHT_AFT',
        position: { x: -0.5, y: 1.0, z: 0 },
        direction: { x: 0, y: -1, z: 0 }, // Translate left
        thrustN: this.thrusterThrustN,
        active: false,
        totalFiredSeconds: 0,
        pulseCount: 0
      },
      {
        id: 11,
        name: 'RIGHT_ROLL',
        position: { x: 0, y: 1.0, z: 0.5 },
        direction: { x: 0, y: 0, z: 1 },  // Roll CCW
        thrustN: this.thrusterThrustN,
        active: false,
        totalFiredSeconds: 0,
        pulseCount: 0
      }
    ];
  }

  /**
   * Create control groups
   */
  private createDefaultGroups(): Map<string, ThrusterGroup> {
    const groups = new Map<string, ThrusterGroup>();

    groups.set('pitch_up', {
      name: 'pitch_up',
      thrusterIds: [1, 3],  // FWD_DOWN, AFT_UP
      active: false
    });

    groups.set('pitch_down', {
      name: 'pitch_down',
      thrusterIds: [0, 4],  // FWD_UP, AFT_DOWN
      active: false
    });

    groups.set('yaw_left', {
      name: 'yaw_left',
      thrusterIds: [2],     // FWD_RIGHT
      active: false
    });

    groups.set('yaw_right', {
      name: 'yaw_right',
      thrusterIds: [5],     // AFT_LEFT
      active: false
    });

    groups.set('roll_cw', {
      name: 'roll_cw',
      thrusterIds: [8],     // LEFT_ROLL
      active: false
    });

    groups.set('roll_ccw', {
      name: 'roll_ccw',
      thrusterIds: [11],    // RIGHT_ROLL
      active: false
    });

    groups.set('translate_left', {
      name: 'translate_left',
      thrusterIds: [9, 10], // RIGHT_FWD, RIGHT_AFT
      active: false
    });

    groups.set('translate_right', {
      name: 'translate_right',
      thrusterIds: [6, 7],  // LEFT_FWD, LEFT_AFT
      active: false
    });

    return groups;
  }

  /**
   * Main update loop
   */
  update(dt: number, simulationTime: number): void {
    // Update active thruster firing time
    for (const thruster of this.thrusters) {
      if (thruster.active) {
        thruster.totalFiredSeconds += dt;
      }
    }
  }

  /**
   * Activate a control group
   */
  activateGroup(groupName: string): boolean {
    const group = this.groups.get(groupName);
    if (!group) return false;

    group.active = true;

    for (const thrusterId of group.thrusterIds) {
      this.activateThruster(thrusterId);
    }

    return true;
  }

  /**
   * Deactivate a control group
   */
  deactivateGroup(groupName: string): void {
    const group = this.groups.get(groupName);
    if (!group) return;

    group.active = false;

    for (const thrusterId of group.thrusterIds) {
      this.deactivateThruster(thrusterId);
    }
  }

  /**
   * Activate individual thruster
   */
  activateThruster(thrusterId: number): boolean {
    if (thrusterId < 0 || thrusterId >= this.thrusters.length) return false;

    const thruster = this.thrusters[thrusterId];
    if (!thruster.active) {
      thruster.pulseCount++;
    }
    thruster.active = true;

    return true;
  }

  /**
   * Deactivate individual thruster
   */
  deactivateThruster(thrusterId: number): void {
    if (thrusterId < 0 || thrusterId >= this.thrusters.length) return;

    this.thrusters[thrusterId].active = false;
  }

  /**
   * Fire a pulse (minimum pulse width)
   */
  firePulse(groupName: string): void {
    const group = this.groups.get(groupName);
    if (!group) return;

    // Activate for minimum pulse width
    this.activateGroup(groupName);

    // Would need timer to deactivate after minPulseWidthS
    // For now, caller should deactivate after appropriate time
  }

  /**
   * Calculate total thrust force vector
   * Returns net force in (x, y, z)
   */
  getTotalThrustVector(): { x: number; y: number; z: number } {
    let fx = 0;
    let fy = 0;
    let fz = 0;

    for (const thruster of this.thrusters) {
      if (thruster.active) {
        fx += thruster.thrustN * thruster.direction.x;
        fy += thruster.thrustN * thruster.direction.y;
        fz += thruster.thrustN * thruster.direction.z;
      }
    }

    return { x: fx, y: fy, z: fz };
  }

  /**
   * Calculate total torque vector
   * τ = r × F
   * Returns net torque in (x, y, z) in N·m
   */
  getTotalTorque(): { x: number; y: number; z: number } {
    let tx = 0;
    let ty = 0;
    let tz = 0;

    for (const thruster of this.thrusters) {
      if (!thruster.active) continue;

      const r = thruster.position;
      const F = {
        x: thruster.thrustN * thruster.direction.x,
        y: thruster.thrustN * thruster.direction.y,
        z: thruster.thrustN * thruster.direction.z
      };

      // Cross product: r × F
      tx += r.y * F.z - r.z * F.y;
      ty += r.z * F.x - r.x * F.z;
      tz += r.x * F.y - r.y * F.x;
    }

    return { x: tx, y: ty, z: tz };
  }

  /**
   * Calculate fuel consumption
   * ṁ = F / (Isp * g0)
   */
  consumeFuel(dt: number, availableFuelKg: number): number {
    const totalThrust = this.getTotalActiveThrust();

    if (totalThrust === 0) return 0;

    const massFlowKgPerSec = totalThrust / (this.SPECIFIC_IMPULSE_SEC * this.G0);
    const desiredFuel = massFlowKgPerSec * dt;
    const actualFuel = Math.min(desiredFuel, availableFuelKg);

    this.totalFuelConsumedKg += actualFuel;

    return actualFuel;
  }

  /**
   * Get total thrust from active thrusters
   */
  getTotalActiveThrust(): number {
    let total = 0;
    for (const thruster of this.thrusters) {
      if (thruster.active) {
        total += thruster.thrustN;
      }
    }
    return total;
  }

  /**
   * Get number of active thrusters
   */
  getActiveThrusterCount(): number {
    return this.thrusters.filter(t => t.active).length;
  }

  /**
   * Get thruster by ID
   */
  getThruster(id: number): Thruster | undefined {
    return this.thrusters[id];
  }

  /**
   * Get group by name
   */
  getGroup(name: string): ThrusterGroup | undefined {
    return this.groups.get(name);
  }

  /**
   * Get current state
   */
  getState() {
    return {
      thrusters: this.thrusters.map(t => ({
        id: t.id,
        name: t.name,
        active: t.active,
        thrustN: t.thrustN,
        totalFiredSeconds: t.totalFiredSeconds,
        pulseCount: t.pulseCount
      })),
      groups: Array.from(this.groups.entries()).map(([name, group]) => ({
        name,
        active: group.active,
        thrusterCount: group.thrusterIds.length
      })),
      totalActiveThrust: this.getTotalActiveThrust(),
      activeThrusterCount: this.getActiveThrusterCount(),
      totalFuelConsumed: this.totalFuelConsumedKg,
      thrustVector: this.getTotalThrustVector(),
      torqueVector: this.getTotalTorque()
    };
  }

  /**
   * Log an event
   */
  private logEvent(time: number, type: string, data: any): void {
    this.events.push({ time, type, data });
  }

  /**
   * Get all events
   */
  getEvents() {
    return this.events;
  }

  /**
   * Clear events
   */
  clearEvents(): void {
    this.events = [];
  }
}
