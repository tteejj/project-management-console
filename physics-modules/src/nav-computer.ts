/**
 * Navigation Computer Subsystem
 *
 * Simulates:
 * - Stellar navigation and inertial navigation systems
 * - Star tracker and gyroscope data fusion
 * - Position/velocity determination accuracy
 * - Computational load and power consumption
 * - Navigation solution quality degradation
 * - IMU drift and recalibration
 */

export interface NavSensorData {
  starTrackerQuality: number; // 0-1, quality of star fix
  gyroQuality: number; // 0-1, gyro accuracy
  accelerometerQuality: number; // 0-1, accelerometer accuracy
  positionUncertainty: number; // meters, 3-sigma error
  velocityUncertainty: number; // m/s, 3-sigma error
  attitudeUncertainty: number; // degrees, 3-sigma error
}

export interface NavComputerConfig {
  processingPowerGflops?: number; // Computational power
  powerConsumptionW?: number; // Power draw
  starTrackerAccuracy?: number; // Base accuracy in arcseconds
  gyroAccuracy?: number; // Base accuracy in deg/hr drift
  updateRateHz?: number; // Navigation solution update rate
  initialAlignment?: boolean; // Whether system is aligned
}

export class NavigationComputer {
  // Hardware specs
  public processingPowerGflops: number;
  public powerConsumptionW: number;
  public starTrackerAccuracy: number; // arcseconds
  public gyroAccuracy: number; // deg/hr drift
  public updateRateHz: number;

  // State
  public operational: boolean = true;
  public aligned: boolean;
  public sensorData: NavSensorData;
  public gyroDriftRate: number = 0; // Current drift rate deg/hr
  public timeSinceAlignment: number = 0; // seconds
  public processingLoad: number = 0; // 0-1, fraction of capacity used

  // Power tracking
  public currentPowerDraw: number = 0; // W
  public isPowered: boolean = true;

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor(config?: NavComputerConfig) {
    this.processingPowerGflops = config?.processingPowerGflops || 50.0;
    this.powerConsumptionW = config?.powerConsumptionW || 150.0;
    this.starTrackerAccuracy = config?.starTrackerAccuracy || 1.0; // 1 arcsecond
    this.gyroAccuracy = config?.gyroAccuracy || 0.01; // 0.01 deg/hr (high quality)
    this.updateRateHz = config?.updateRateHz || 50.0;
    this.aligned = config?.initialAlignment !== undefined ? config.initialAlignment : true;

    this.sensorData = {
      starTrackerQuality: 1.0,
      gyroQuality: 1.0,
      accelerometerQuality: 1.0,
      positionUncertainty: 10.0, // 10 meters
      velocityUncertainty: 0.01, // 1 cm/s
      attitudeUncertainty: 0.001 // 0.001 degrees
    };

    this.currentPowerDraw = this.powerConsumptionW;
  }

  /**
   * Perform initial alignment (requires stable attitude and star fix)
   */
  public performAlignment(starVisibility: number = 1.0): boolean {
    if (!this.isPowered || !this.operational) {
      this.logEvent('alignment_failed', { reason: 'system_offline' });
      return false;
    }

    if (starVisibility < 0.5) {
      this.logEvent('alignment_failed', { reason: 'insufficient_star_visibility', visibility: starVisibility });
      return false;
    }

    this.aligned = true;
    this.timeSinceAlignment = 0;
    this.gyroDriftRate = this.gyroAccuracy * (0.5 + Math.random() * 0.5); // Random drift within spec
    this.logEvent('alignment_complete', { gyroDrift: this.gyroDriftRate });
    return true;
  }

  /**
   * Update navigation solution
   */
  public updateNavSolution(starVisibility: number, dt: number): void {
    if (!this.isPowered) {
      this.operational = false;
      this.currentPowerDraw = 0;
      return;
    }

    this.currentPowerDraw = this.powerConsumptionW;
    this.timeSinceAlignment += dt;

    if (!this.operational) return;

    // Update sensor quality based on star visibility
    this.sensorData.starTrackerQuality = Math.max(0, Math.min(1, starVisibility));

    // Gyro drift accumulates over time
    const driftAccumulation = this.gyroDriftRate * (this.timeSinceAlignment / 3600.0);
    this.sensorData.gyroQuality = Math.max(0, 1.0 - driftAccumulation / 10.0);

    // Calculate position/velocity uncertainty
    if (this.aligned && starVisibility > 0.3) {
      // With star fix, position uncertainty is low
      const baseUncertainty = 10.0; // meters
      this.sensorData.positionUncertainty = baseUncertainty / starVisibility;
      this.sensorData.velocityUncertainty = 0.01 / starVisibility; // cm/s
      this.sensorData.attitudeUncertainty = (this.starTrackerAccuracy / 3600.0) / starVisibility; // deg
    } else {
      // Pure inertial - uncertainty grows over time
      const timeFactor = Math.sqrt(this.timeSinceAlignment);
      this.sensorData.positionUncertainty = 10.0 + timeFactor * 0.5;
      this.sensorData.velocityUncertainty = 0.01 + timeFactor * 0.001;
      this.sensorData.attitudeUncertainty = 0.001 + driftAccumulation;
    }

    // Processing load varies with solution complexity
    this.processingLoad = 0.3 + 0.2 * Math.random();

    // Check for alignment loss
    if (this.timeSinceAlignment > 7200 && starVisibility < 0.1) { // 2 hours without star fix
      if (this.aligned) {
        this.aligned = false;
        this.logEvent('alignment_lost', { timeElapsed: this.timeSinceAlignment });
      }
    }
  }

  /**
   * Apply damage to the navigation computer
   */
  public applyDamage(severity: number): void {
    if (severity > 0.3) {
      this.operational = false;
      this.logEvent('nav_computer_damaged', { severity });
    } else {
      // Degrade accuracy
      this.starTrackerAccuracy *= (1 + severity);
      this.gyroAccuracy *= (1 + severity * 2);
      this.logEvent('nav_computer_degraded', { severity, newAccuracy: this.starTrackerAccuracy });
    }
  }

  /**
   * Repair navigation computer
   */
  public repair(): void {
    this.operational = true;
    this.logEvent('nav_computer_repaired', {});
  }

  /**
   * Set power state
   */
  public setPower(powered: boolean): void {
    this.isPowered = powered;
    if (!powered) {
      this.currentPowerDraw = 0;
    }
  }

  /**
   * Get current navigation quality (0-1, overall health metric)
   */
  public getNavigationQuality(): number {
    if (!this.operational || !this.isPowered) return 0;
    if (!this.aligned) return 0.2;

    const avgSensorQuality = (
      this.sensorData.starTrackerQuality +
      this.sensorData.gyroQuality +
      this.sensorData.accelerometerQuality
    ) / 3.0;

    return avgSensorQuality;
  }

  public getState() {
    return {
      operational: this.operational,
      aligned: this.aligned,
      isPowered: this.isPowered,
      powerDraw: this.currentPowerDraw,
      processingLoad: this.processingLoad,
      timeSinceAlignment: this.timeSinceAlignment,
      sensorData: { ...this.sensorData },
      navigationQuality: this.getNavigationQuality(),
      gyroDriftRate: this.gyroDriftRate
    };
  }

  private logEvent(type: string, data: any): void {
    this.events.push({ time: Date.now(), type, data });
  }
}
