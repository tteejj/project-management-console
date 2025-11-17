/**
 * Countermeasures Subsystem
 *
 * Simulates:
 * - Chaff dispensers (radar countermeasures)
 * - Flare dispensers (IR countermeasures)
 * - Electronic countermeasures (ECM) - jamming
 * - Decoy deployment
 * - Countermeasure effectiveness tracking
 * - Magazine capacity and reload mechanics
 */

export interface CountermeasureLoadout {
  chaff: number; // Number of chaff cartridges
  flares: number; // Number of flare cartridges
  decoys: number; // Number of deployable decoys
}

export interface CountermeasureConfig {
  chaffCapacity?: number;
  flareCapacity?: number;
  decoyCapacity?: number;
  ecmPowerW?: number; // ECM transmitter power
  dispenserCount?: number; // Number of dispenser units
  reloadTimeS?: number; // Time to reload a dispenser
}

export interface ThreatSignature {
  type: 'radar' | 'infrared' | 'visual' | 'combined';
  strength: number; // 0-1, threat intensity
  range: number; // meters
}

export class CountermeasureSystem {
  // Loadout
  public loadout: CountermeasureLoadout;
  public maxCapacity: {
    chaff: number;
    flares: number;
    decoys: number;
  };

  // Hardware
  public dispenserCount: number;
  public ecmPowerW: number;
  public reloadTimeS: number;

  // State
  public operational: boolean = true;
  public ecmActive: boolean = false;
  public isPowered: boolean = true;
  public reloading: boolean = false;
  public reloadProgress: number = 0; // 0-1

  // Power tracking
  public currentPowerDraw: number = 0; // W
  public basePowerDraw: number = 20; // W (standby)

  // Effectiveness tracking
  public deploymentsThisMission: {
    chaff: number;
    flares: number;
    decoys: number;
  } = { chaff: 0, flares: 0, decoys: 0 };

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor(config?: CountermeasureConfig) {
    this.maxCapacity = {
      chaff: config?.chaffCapacity || 100,
      flares: config?.flareCapacity || 80,
      decoys: config?.decoyCapacity || 10
    };

    this.loadout = {
      chaff: this.maxCapacity.chaff,
      flares: this.maxCapacity.flares,
      decoys: this.maxCapacity.decoys
    };

    this.dispenserCount = config?.dispenserCount || 4;
    this.ecmPowerW = config?.ecmPowerW || 500.0;
    this.reloadTimeS = config?.reloadTimeS || 2.0;

    this.currentPowerDraw = this.basePowerDraw;
  }

  /**
   * Deploy chaff to counter radar threats
   */
  public deployChaff(count: number = 1): boolean {
    if (!this.operational || !this.isPowered) {
      this.logEvent('deployment_failed', { type: 'chaff', reason: 'system_offline' });
      return false;
    }

    if (this.reloading) {
      this.logEvent('deployment_failed', { type: 'chaff', reason: 'reloading' });
      return false;
    }

    const deployCount = Math.min(count, this.loadout.chaff, this.dispenserCount);

    if (deployCount === 0) {
      this.logEvent('deployment_failed', { type: 'chaff', reason: 'empty' });
      return false;
    }

    this.loadout.chaff -= deployCount;
    this.deploymentsThisMission.chaff += deployCount;
    this.logEvent('chaff_deployed', { count: deployCount, remaining: this.loadout.chaff });

    // Start reload cycle
    this.reloading = true;
    this.reloadProgress = 0;

    return true;
  }

  /**
   * Deploy flares to counter IR/heat-seeking threats
   */
  public deployFlares(count: number = 1): boolean {
    if (!this.operational || !this.isPowered) {
      this.logEvent('deployment_failed', { type: 'flares', reason: 'system_offline' });
      return false;
    }

    if (this.reloading) {
      this.logEvent('deployment_failed', { type: 'flares', reason: 'reloading' });
      return false;
    }

    const deployCount = Math.min(count, this.loadout.flares, this.dispenserCount);

    if (deployCount === 0) {
      this.logEvent('deployment_failed', { type: 'flares', reason: 'empty' });
      return false;
    }

    this.loadout.flares -= deployCount;
    this.deploymentsThisMission.flares += deployCount;
    this.logEvent('flares_deployed', { count: deployCount, remaining: this.loadout.flares });

    // Start reload cycle
    this.reloading = true;
    this.reloadProgress = 0;

    return true;
  }

  /**
   * Deploy decoy drone
   */
  public deployDecoy(): boolean {
    if (!this.operational || !this.isPowered) {
      this.logEvent('deployment_failed', { type: 'decoy', reason: 'system_offline' });
      return false;
    }

    if (this.loadout.decoys === 0) {
      this.logEvent('deployment_failed', { type: 'decoy', reason: 'empty' });
      return false;
    }

    this.loadout.decoys -= 1;
    this.deploymentsThisMission.decoys += 1;
    this.logEvent('decoy_deployed', { remaining: this.loadout.decoys });

    return true;
  }

  /**
   * Activate electronic countermeasures (jamming)
   */
  public activateECM(): boolean {
    if (!this.operational || !this.isPowered) {
      this.logEvent('ecm_failed', { reason: 'system_offline' });
      return false;
    }

    this.ecmActive = true;
    this.currentPowerDraw = this.basePowerDraw + this.ecmPowerW;
    this.logEvent('ecm_activated', { powerDraw: this.currentPowerDraw });
    return true;
  }

  /**
   * Deactivate ECM
   */
  public deactivateECM(): void {
    this.ecmActive = false;
    this.currentPowerDraw = this.basePowerDraw;
    this.logEvent('ecm_deactivated', {});
  }

  /**
   * Calculate effectiveness against a threat
   */
  public calculateEffectiveness(threat: ThreatSignature, recentDeployments: {
    chaff: number;
    flares: number;
    decoys: number;
  }): number {
    if (!this.operational || !this.isPowered) return 0;

    let effectiveness = 0;

    switch (threat.type) {
      case 'radar':
        // Chaff and ECM counter radar
        const chaffEffect = Math.min(1.0, recentDeployments.chaff * 0.3);
        const ecmEffect = this.ecmActive ? 0.4 : 0;
        effectiveness = Math.min(1.0, chaffEffect + ecmEffect);
        break;

      case 'infrared':
        // Flares counter IR
        effectiveness = Math.min(1.0, recentDeployments.flares * 0.35);
        break;

      case 'visual':
        // Decoys help against visual tracking
        effectiveness = Math.min(0.6, recentDeployments.decoys * 0.4);
        break;

      case 'combined':
        // Multi-mode threats require multiple countermeasures
        const avgEffect = (
          Math.min(1.0, recentDeployments.chaff * 0.2) +
          Math.min(1.0, recentDeployments.flares * 0.2) +
          Math.min(0.6, recentDeployments.decoys * 0.3)
        ) / 3.0;
        effectiveness = avgEffect + (this.ecmActive ? 0.2 : 0);
        break;
    }

    // Distance factor - less effective at close range
    const rangeFactor = Math.min(1.0, threat.range / 1000.0);
    effectiveness *= rangeFactor;

    return Math.min(1.0, effectiveness);
  }

  /**
   * Update system state
   */
  public update(dt: number): void {
    if (!this.isPowered) {
      this.operational = false;
      this.currentPowerDraw = 0;
      this.ecmActive = false;
      return;
    }

    if (!this.operational) return;

    // Handle reload cycle
    if (this.reloading) {
      this.reloadProgress += dt / this.reloadTimeS;
      if (this.reloadProgress >= 1.0) {
        this.reloading = false;
        this.reloadProgress = 0;
        this.logEvent('reload_complete', {});
      }
    }
  }

  /**
   * Apply damage
   */
  public applyDamage(severity: number): void {
    if (severity > 0.5) {
      this.operational = false;
      this.ecmActive = false;
      this.logEvent('countermeasures_destroyed', { severity });
    } else if (severity > 0.2) {
      // Lose some countermeasures
      const loss = Math.floor(severity * 20);
      this.loadout.chaff = Math.max(0, this.loadout.chaff - loss);
      this.loadout.flares = Math.max(0, this.loadout.flares - loss);
      this.logEvent('countermeasures_damaged', { severity, loss });
    }
  }

  /**
   * Repair system
   */
  public repair(): void {
    this.operational = true;
    this.logEvent('countermeasures_repaired', {});
  }

  /**
   * Reload/rearm countermeasures (requires docking or resupply)
   */
  public rearm(chaff?: number, flares?: number, decoys?: number): void {
    if (chaff !== undefined) {
      this.loadout.chaff = Math.min(this.maxCapacity.chaff, this.loadout.chaff + chaff);
    }
    if (flares !== undefined) {
      this.loadout.flares = Math.min(this.maxCapacity.flares, this.loadout.flares + flares);
    }
    if (decoys !== undefined) {
      this.loadout.decoys = Math.min(this.maxCapacity.decoys, this.loadout.decoys + decoys);
    }
    this.logEvent('rearmed', { loadout: this.loadout });
  }

  /**
   * Set power state
   */
  public setPower(powered: boolean): void {
    this.isPowered = powered;
    if (!powered) {
      this.currentPowerDraw = 0;
      this.ecmActive = false;
    } else {
      this.currentPowerDraw = this.basePowerDraw;
    }
  }

  public getState() {
    return {
      operational: this.operational,
      isPowered: this.isPowered,
      loadout: { ...this.loadout },
      maxCapacity: { ...this.maxCapacity },
      ecmActive: this.ecmActive,
      reloading: this.reloading,
      reloadProgress: this.reloadProgress,
      powerDraw: this.currentPowerDraw,
      deploymentsThisMission: { ...this.deploymentsThisMission }
    };
  }

  private logEvent(type: string, data: any): void {
    this.events.push({ time: Date.now(), type, data });
  }
}
