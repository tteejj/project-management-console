/**
 * Landing System Subsystem
 *
 * Simulates:
 * - Landing gear deployment and retraction
 * - Touchdown sensors and contact detection
 * - Shock absorber physics (oleopneumatic struts)
 * - Gear strength and load limits
 * - Surface contact analysis
 * - Terrain scanning radar/lidar
 * - Landing lights
 */

export interface LandingGear {
  id: string;
  deployed: boolean;
  locked: boolean; // Locked in deployed position
  strut: {
    compression: number; // 0-1, current compression
    maxCompressionM: number; // Maximum travel
    springConstant: number; // N/m
    dampingCoefficient: number; // N·s/m
    maxLoad: number; // Newtons
  };
  contact: boolean; // Touching ground
  health: number; // 0-1, structural integrity
  sensors: {
    touchdown: boolean;
    weightOnWheels: number; // Newtons
  };
}

export interface LandingConfig {
  gearCount?: number;
  deployTimeS?: number;
  retractTimeS?: number;
  maxCompressionM?: number;
  springConstant?: number;
  dampingCoefficient?: number;
  maxLoadPerGear?: number;
  terrainRadarRangeM?: number;
  powerConsumptionW?: number;
}

export interface TerrainData {
  altitude: number; // meters above surface
  slope: number; // degrees
  surfaceType: 'soft' | 'hard' | 'ice' | 'unknown';
  roughness: number; // 0-1
}

export class LandingSystem {
  // Landing gear
  public gear: Map<string, LandingGear>;
  public gearCount: number;

  // Deployment mechanics
  public deployTimeS: number;
  public retractTimeS: number;
  public deploymentProgress: number = 0; // 0-1
  public deploying: boolean = false;
  public retracting: boolean = false;

  // Terrain scanning
  public terrainRadarRangeM: number;
  public terrainRadarActive: boolean = false;
  public terrainData: TerrainData | null = null;

  // State
  public operational: boolean = true;
  public isPowered: boolean = true;
  public lightsOn: boolean = false;
  public allGearDeployed: boolean = false;
  public allGearLocked: boolean = false;
  public surfaceContact: boolean = false;

  // Power tracking
  public currentPowerDraw: number = 0; // W
  public basePowerDraw: number = 5; // W (standby)
  public powerConsumptionW: number;

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor(config?: LandingConfig) {
    this.gearCount = config?.gearCount || 3;
    this.deployTimeS = config?.deployTimeS || 15.0;
    this.retractTimeS = config?.retractTimeS || 20.0;
    this.terrainRadarRangeM = config?.terrainRadarRangeM || 5000.0;
    this.powerConsumptionW = config?.powerConsumptionW || 300.0;

    this.gear = new Map();
    this.createDefaultGear(config);

    this.currentPowerDraw = this.basePowerDraw;
  }

  private createDefaultGear(config?: LandingConfig): void {
    const gearPositions = ['nose', 'left_main', 'right_main', 'aft'];

    for (let i = 0; i < this.gearCount; i++) {
      const id = gearPositions[i] || `gear_${i}`;
      this.gear.set(id, {
        id,
        deployed: false,
        locked: false,
        strut: {
          compression: 0,
          maxCompressionM: config?.maxCompressionM || 0.5,
          springConstant: config?.springConstant || 100000, // N/m
          dampingCoefficient: config?.dampingCoefficient || 5000, // N·s/m
          maxLoad: config?.maxLoadPerGear || 50000 // N (~5 tons per gear)
        },
        contact: false,
        health: 1.0,
        sensors: {
          touchdown: false,
          weightOnWheels: 0
        }
      });
    }
  }

  /**
   * Deploy landing gear
   */
  public deployGear(): boolean {
    if (!this.operational || !this.isPowered) {
      this.logEvent('deploy_failed', { reason: 'system_offline' });
      return false;
    }

    if (this.allGearDeployed) {
      this.logEvent('deploy_failed', { reason: 'already_deployed' });
      return false;
    }

    if (this.retracting) {
      this.logEvent('deploy_failed', { reason: 'currently_retracting' });
      return false;
    }

    this.deploying = true;
    this.deploymentProgress = 0;
    this.currentPowerDraw = this.basePowerDraw + this.powerConsumptionW;
    this.logEvent('gear_deploying', {});
    return true;
  }

  /**
   * Retract landing gear
   */
  public retractGear(): boolean {
    if (!this.operational || !this.isPowered) {
      this.logEvent('retract_failed', { reason: 'system_offline' });
      return false;
    }

    if (!this.allGearDeployed) {
      this.logEvent('retract_failed', { reason: 'not_deployed' });
      return false;
    }

    if (this.surfaceContact) {
      this.logEvent('retract_failed', { reason: 'weight_on_wheels' });
      return false;
    }

    if (this.deploying) {
      this.logEvent('retract_failed', { reason: 'currently_deploying' });
      return false;
    }

    this.retracting = true;
    this.deploymentProgress = 1.0;
    this.currentPowerDraw = this.basePowerDraw + this.powerConsumptionW;
    this.logEvent('gear_retracting', {});
    return true;
  }

  /**
   * Activate terrain scanning radar
   */
  public activateTerrainRadar(): boolean {
    if (!this.operational || !this.isPowered) return false;

    this.terrainRadarActive = true;
    this.currentPowerDraw += 50; // Additional 50W for radar
    this.logEvent('terrain_radar_active', {});
    return true;
  }

  /**
   * Deactivate terrain radar
   */
  public deactivateTerrainRadar(): void {
    this.terrainRadarActive = false;
    this.currentPowerDraw -= 50;
    this.logEvent('terrain_radar_inactive', {});
  }

  /**
   * Update terrain data (would be called by external systems with real terrain info)
   */
  public updateTerrainData(data: TerrainData): void {
    if (!this.terrainRadarActive) return;

    this.terrainData = data;

    // Alert if terrain is too close or unsuitable
    if (data.altitude < 100) {
      this.logEvent('terrain_proximity', { altitude: data.altitude });
    }

    if (data.slope > 15 && data.altitude < 500) {
      this.logEvent('terrain_warning', { slope: data.slope, altitude: data.altitude });
    }
  }

  /**
   * Toggle landing lights
   */
  public toggleLights(on: boolean): void {
    this.lightsOn = on;
    if (on) {
      this.currentPowerDraw += 100; // 100W for lights
      this.logEvent('lights_on', {});
    } else {
      this.currentPowerDraw -= 100;
      this.logEvent('lights_off', {});
    }
  }

  /**
   * Simulate gear compression during touchdown/landing
   */
  public applyGroundForce(gearId: string, verticalVelocity: number, mass: number, dt: number): void {
    const g = this.gear.get(gearId);
    if (!g || !g.deployed || !g.locked) return;

    // Simple spring-damper model
    const compressionVelocity = -verticalVelocity; // Positive = compressing

    // Force from spring and damper
    const springForce = g.strut.springConstant * g.strut.compression;
    const damperForce = g.strut.dampingCoefficient * compressionVelocity;
    const totalForce = springForce + damperForce;

    // Update compression
    const acceleration = totalForce / (mass / this.gearCount);
    const deltaCompression = compressionVelocity * dt;
    g.strut.compression = Math.max(0, Math.min(1.0, g.strut.compression + deltaCompression / g.strut.maxCompressionM));

    // Check for contact
    g.contact = g.strut.compression > 0.01;
    g.sensors.touchdown = g.contact;
    g.sensors.weightOnWheels = totalForce;

    // Check for overload
    if (totalForce > g.strut.maxLoad) {
      const overload = totalForce / g.strut.maxLoad;
      this.applyDamage(overload - 1.0, gearId);
      this.logEvent('gear_overload', { gearId, force: totalForce, maxLoad: g.strut.maxLoad });
    }
  }

  /**
   * Update landing system state
   */
  public update(dt: number): void {
    if (!this.isPowered) {
      this.operational = false;
      this.currentPowerDraw = 0;
      this.terrainRadarActive = false;
      this.lightsOn = false;
      return;
    }

    if (!this.operational) return;

    // Handle deployment
    if (this.deploying) {
      this.deploymentProgress += dt / this.deployTimeS;
      if (this.deploymentProgress >= 1.0) {
        this.deploymentProgress = 1.0;
        this.deploying = false;
        this.currentPowerDraw = this.basePowerDraw;

        // Lock all gear
        this.gear.forEach(g => {
          g.deployed = true;
          g.locked = true;
        });

        this.allGearDeployed = true;
        this.allGearLocked = true;
        this.logEvent('gear_deployed_locked', {});
      }
    }

    // Handle retraction
    if (this.retracting) {
      this.deploymentProgress -= dt / this.retractTimeS;
      if (this.deploymentProgress <= 0) {
        this.deploymentProgress = 0;
        this.retracting = false;
        this.currentPowerDraw = this.basePowerDraw;

        // Retract and unlock all gear
        this.gear.forEach(g => {
          g.deployed = false;
          g.locked = false;
          g.contact = false;
          g.strut.compression = 0;
        });

        this.allGearDeployed = false;
        this.allGearLocked = false;
        this.logEvent('gear_retracted', {});
      }
    }

    // Update surface contact status
    let anyContact = false;
    this.gear.forEach(g => {
      if (g.contact) anyContact = true;
    });
    this.surfaceContact = anyContact;
  }

  /**
   * Check if safe to land
   */
  public isSafeToLand(): { safe: boolean; reasons: string[] } {
    const reasons: string[] = [];

    if (!this.allGearDeployed) {
      reasons.push('Gear not deployed');
    }

    if (!this.allGearLocked) {
      reasons.push('Gear not locked');
    }

    let anyDamaged = false;
    this.gear.forEach(g => {
      if (g.health < 0.7) anyDamaged = true;
    });
    if (anyDamaged) {
      reasons.push('Gear damaged');
    }

    if (this.terrainData) {
      if (this.terrainData.slope > 20) {
        reasons.push('Terrain too steep');
      }
      if (this.terrainData.surfaceType === 'unknown') {
        reasons.push('Unknown surface type');
      }
    } else {
      reasons.push('No terrain data');
    }

    return {
      safe: reasons.length === 0,
      reasons
    };
  }

  /**
   * Apply damage to landing system
   */
  public applyDamage(severity: number, gearId?: string): void {
    if (gearId) {
      const g = this.gear.get(gearId);
      if (g) {
        g.health = Math.max(0, g.health - severity);
        if (g.health < 0.3) {
          g.locked = false;
          this.logEvent('gear_failure', { gearId, health: g.health });
        } else {
          this.logEvent('gear_damaged', { gearId, health: g.health });
        }
      }
    } else {
      if (severity > 0.7) {
        this.operational = false;
        this.logEvent('landing_system_destroyed', { severity });
      }
    }
  }

  /**
   * Repair landing system
   */
  public repair(gearId?: string): void {
    if (gearId) {
      const g = this.gear.get(gearId);
      if (g) {
        g.health = 1.0;
        this.logEvent('gear_repaired', { gearId });
      }
    } else {
      this.operational = true;
      this.gear.forEach(g => {
        g.health = 1.0;
      });
      this.logEvent('landing_system_repaired', {});
    }
  }

  /**
   * Set power state
   */
  public setPower(powered: boolean): void {
    this.isPowered = powered;
    if (!powered) {
      this.currentPowerDraw = 0;
      this.terrainRadarActive = false;
      this.lightsOn = false;
    } else {
      this.currentPowerDraw = this.basePowerDraw;
    }
  }

  public getState() {
    const gearArray: any[] = [];
    this.gear.forEach((g, id) => {
      gearArray.push({
        id,
        deployed: g.deployed,
        locked: g.locked,
        contact: g.contact,
        health: g.health,
        compression: g.strut.compression,
        weightOnWheels: g.sensors.weightOnWheels
      });
    });

    return {
      operational: this.operational,
      isPowered: this.isPowered,
      gear: gearArray,
      allGearDeployed: this.allGearDeployed,
      allGearLocked: this.allGearLocked,
      surfaceContact: this.surfaceContact,
      deploying: this.deploying,
      retracting: this.retracting,
      deploymentProgress: this.deploymentProgress,
      terrainRadarActive: this.terrainRadarActive,
      terrainData: this.terrainData,
      lightsOn: this.lightsOn,
      powerDraw: this.currentPowerDraw,
      safeToLand: this.isSafeToLand()
    };
  }

  private logEvent(type: string, data: any): void {
    this.events.push({ time: Date.now(), type, data });
  }
}
