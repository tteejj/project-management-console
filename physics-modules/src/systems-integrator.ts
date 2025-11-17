/**
 * Systems Integrator
 *
 * Manages all spacecraft subsystems and their interactions:
 * - Power distribution and management
 * - Damage propagation between systems
 * - Cascading failures
 * - Automated responses
 * - System health monitoring
 * - Emergency protocols
 */

import { Spacecraft } from './spacecraft';
import { PowerManagementSystem, PowerConsumer, EMCONLevel } from './power-management';

export interface SystemDependency {
  systemId: string;
  dependsOn: string[];  // System IDs this depends on
  criticalDependency: boolean; // If true, system fails if dependency fails
}

export interface DamageEvent {
  systemId: string;
  severity: number; // 0-1
  type: 'impact' | 'overheat' | 'power_surge' | 'radiation' | 'micrometeorite' | 'malfunction';
  timestamp: number;
  cascading: boolean; // Can cause damage to other systems
}

export class SystemsIntegrator {
  private spacecraft: Spacecraft;
  public powerManagement: PowerManagementSystem;

  // System dependencies
  private dependencies: Map<string, SystemDependency> = new Map();

  // System health (0-1, where 1 is perfect health)
  private systemHealth: Map<string, number> = new Map();

  // Automated systems
  public autoRepairEnabled: boolean = true;
  public autoPowerManagementEnabled: boolean = true;
  public cascadeProtectionEnabled: boolean = true;

  // Emergency protocols
  public emergencyProtocolActive: boolean = false;
  private emergencyProtocolStartTime: number = 0;

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  constructor(spacecraft: Spacecraft) {
    this.spacecraft = spacecraft;
    this.powerManagement = new PowerManagementSystem({
      totalGenerationW: 3000,
      batteryCapacityKWh: 10,
      brownoutThresholdPercent: 0.95
    });

    this.initializeSystemDependencies();
    this.registerAllPowerConsumers();
    this.initializeSystemHealth();
  }

  private initializeSystemDependencies(): void {
    // Define critical dependencies between systems
    this.dependencies.set('mainEngine', {
      systemId: 'mainEngine',
      dependsOn: ['fuel', 'electrical', 'thermal'],
      criticalDependency: true
    });

    this.dependencies.set('rcs', {
      systemId: 'rcs',
      dependsOn: ['fuel', 'electrical'],
      criticalDependency: true
    });

    this.dependencies.set('navComputer', {
      systemId: 'navComputer',
      dependsOn: ['electrical'],
      criticalDependency: true
    });

    this.dependencies.set('communications', {
      systemId: 'communications',
      dependsOn: ['electrical'],
      criticalDependency: true
    });

    this.dependencies.set('environmental', {
      systemId: 'environmental',
      dependsOn: ['electrical', 'thermal'],
      criticalDependency: true
    });

    this.dependencies.set('landing', {
      systemId: 'landing',
      dependsOn: ['electrical'],
      criticalDependency: false
    });

    this.dependencies.set('docking', {
      systemId: 'docking',
      dependsOn: ['electrical'],
      criticalDependency: false
    });

    this.dependencies.set('ew', {
      systemId: 'ew',
      dependsOn: ['electrical'],
      criticalDependency: true
    });

    this.dependencies.set('countermeasures', {
      systemId: 'countermeasures',
      dependsOn: ['electrical'],
      criticalDependency: false
    });

    // Weapons system (Critical Integration: Weapons Power Management)
    this.dependencies.set('weapons', {
      systemId: 'weapons',
      dependsOn: ['electrical', 'thermal', 'centerOfMass'],
      criticalDependency: true // Weapons offline if power or thermal management fails
    });

    // Center of Mass system (Critical Integration: CoM Tracking)
    this.dependencies.set('centerOfMass', {
      systemId: 'centerOfMass',
      dependsOn: ['fuel', 'cargo'], // CoM depends on fuel and cargo changes
      criticalDependency: false
    });
  }

  private registerAllPowerConsumers(): void {
    // Register all spacecraft subsystems as power consumers

    // High priority - Life support
    this.powerManagement.registerConsumer({
      id: 'environmental',
      name: 'Environmental/Life Support',
      priority: 10,
      basePowerW: 800,
      currentPowerW: 800,
      maxPowerW: 1200,
      essential: true,
      powered: true,
      busAssignment: 'A'
    });

    // High priority - Navigation
    this.powerManagement.registerConsumer({
      id: 'navComputer',
      name: 'Navigation Computer',
      priority: 9,
      basePowerW: 150,
      currentPowerW: 150,
      maxPowerW: 200,
      essential: false,
      powered: true,
      busAssignment: 'B'
    });

    // Medium-High priority - Propulsion
    this.powerManagement.registerConsumer({
      id: 'mainEngine',
      name: 'Main Engine Controls',
      priority: 8,
      basePowerW: 100,
      currentPowerW: 100,
      maxPowerW: 300,
      essential: false,
      powered: true,
      busAssignment: 'A'
    });

    this.powerManagement.registerConsumer({
      id: 'rcs',
      name: 'RCS System',
      priority: 8,
      basePowerW: 50,
      currentPowerW: 50,
      maxPowerW: 150,
      essential: false,
      powered: true,
      busAssignment: 'A'
    });

    // Medium priority - Communications
    this.powerManagement.registerConsumer({
      id: 'communications',
      name: 'Communications System',
      priority: 6,
      basePowerW: 30,
      currentPowerW: 30,
      maxPowerW: 500,
      essential: false,
      powered: true,
      busAssignment: 'B'
    });

    // Medium-Low priority - Support systems
    this.powerManagement.registerConsumer({
      id: 'landing',
      name: 'Landing System',
      priority: 5,
      basePowerW: 5,
      currentPowerW: 5,
      maxPowerW: 300,
      essential: false,
      powered: true,
      busAssignment: 'B'
    });

    this.powerManagement.registerConsumer({
      id: 'docking',
      name: 'Docking System',
      priority: 5,
      basePowerW: 10,
      currentPowerW: 10,
      maxPowerW: 200,
      essential: false,
      powered: true,
      busAssignment: 'B'
    });

    this.powerManagement.registerConsumer({
      id: 'cargo',
      name: 'Cargo Management',
      priority: 4,
      basePowerW: 20,
      currentPowerW: 20,
      maxPowerW: 500,
      essential: false,
      powered: true,
      busAssignment: 'A'
    });

    // Low priority - Defensive systems
    this.powerManagement.registerConsumer({
      id: 'ew',
      name: 'Electronic Warfare',
      priority: 3,
      basePowerW: 50,
      currentPowerW: 50,
      maxPowerW: 1500,
      essential: false,
      powered: true,
      busAssignment: 'B'
    });

    this.powerManagement.registerConsumer({
      id: 'countermeasures',
      name: 'Countermeasures',
      priority: 3,
      basePowerW: 20,
      currentPowerW: 20,
      maxPowerW: 550,
      essential: false,
      powered: true,
      busAssignment: 'B'
    });

    // Thermal management (essential)
    this.powerManagement.registerConsumer({
      id: 'thermal',
      name: 'Thermal Management',
      priority: 9,
      basePowerW: 200,
      currentPowerW: 200,
      maxPowerW: 400,
      essential: true,
      powered: true,
      busAssignment: 'A'
    });

    this.powerManagement.registerConsumer({
      id: 'coolant',
      name: 'Coolant System',
      priority: 9,
      basePowerW: 150,
      currentPowerW: 150,
      maxPowerW: 300,
      essential: true,
      powered: true,
      busAssignment: 'A'
    });

    // Weapons system (Critical Integration: Weapons Power Management)
    // Priority 7 - Below life support and navigation, above comms
    this.powerManagement.registerConsumer({
      id: 'weapons',
      name: 'Weapons Control System',
      priority: 7,
      basePowerW: 100, // Tracking and control systems
      currentPowerW: 100,
      maxPowerW: 75000000, // 75 MW max (particle beam 50 MW + railgun 15 MW + laser 10 MW)
      essential: false, // Can be shed in brownout
      powered: true,
      busAssignment: 'B'
    });
  }

  private initializeSystemHealth(): void {
    // Initialize all systems at full health
    const systems = [
      'mainEngine', 'rcs', 'fuel', 'electrical', 'thermal', 'coolant',
      'navComputer', 'communications', 'environmental', 'landing', 'docking',
      'cargo', 'ew', 'countermeasures', 'weapons', 'centerOfMass'
    ];

    systems.forEach(sys => {
      this.systemHealth.set(sys, 1.0);
    });
  }

  /**
   * Update all systems integration
   */
  public update(dt: number): void {
    // 1. Update power management
    const reactorOutput = this.spacecraft.electrical.reactor.currentOutputKW * 1000; // Convert kW to W
    const batteryCharge = this.spacecraft.electrical.battery.chargeKWh;

    this.powerManagement.update(dt, reactorOutput, batteryCharge);

    // 2. Update power draws from subsystems
    this.updateSubsystemPowerDraws();

    // 3. Apply power state to subsystems
    this.applyPowerStateToSubsystems();

    // 4. Check for cascading failures
    if (this.cascadeProtectionEnabled) {
      this.checkCascadingFailures();
    }

    // 5. Auto-repair if enabled
    if (this.autoRepairEnabled) {
      this.performAutoRepair(dt);
    }

    // 6. Check emergency protocols
    this.checkEmergencyProtocols();
  }

  private updateSubsystemPowerDraws(): void {
    // Update actual power consumption from each subsystem
    this.powerManagement.updateConsumerDraw('environmental', this.spacecraft.environmental.currentPowerDraw);
    this.powerManagement.updateConsumerDraw('navComputer', this.spacecraft.navComputer.currentPowerDraw);
    this.powerManagement.updateConsumerDraw('communications', this.spacecraft.communications.currentPowerDraw);
    this.powerManagement.updateConsumerDraw('landing', this.spacecraft.landing.currentPowerDraw);
    this.powerManagement.updateConsumerDraw('docking', this.spacecraft.docking.currentPowerDraw);
    this.powerManagement.updateConsumerDraw('cargo', this.spacecraft.cargo.currentPowerDraw);
    this.powerManagement.updateConsumerDraw('ew', this.spacecraft.ew.currentPowerDraw);
    this.powerManagement.updateConsumerDraw('countermeasures', this.spacecraft.countermeasures.currentPowerDraw);
    this.powerManagement.updateConsumerDraw('thermal', this.spacecraft.thermal.heatSources.size * 50); // Approximate

    // Calculate coolant power draw from all loops
    let coolantPower = 0;
    this.spacecraft.coolant.loops.forEach(loop => {
      coolantPower += loop.pumpPowerW;
    });
    this.powerManagement.updateConsumerDraw('coolant', coolantPower);

    // Critical Integration: Weapons power draw (includes tracking + firing power)
    const weaponsPower = this.spacecraft.weapons.getPowerDraw();
    this.powerManagement.updateConsumerDraw('weapons', weaponsPower);
  }

  private applyPowerStateToSubsystems(): void {
    // Apply power management decisions to actual subsystems
    const consumers = this.powerManagement.consumers;

    consumers.forEach((consumer, id) => {
      switch (id) {
        case 'environmental':
          this.spacecraft.environmental.setPower(consumer.powered);
          break;
        case 'navComputer':
          this.spacecraft.navComputer.setPower(consumer.powered);
          break;
        case 'communications':
          this.spacecraft.communications.setPower(consumer.powered);
          break;
        case 'landing':
          this.spacecraft.landing.setPower(consumer.powered);
          break;
        case 'docking':
          this.spacecraft.docking.setPower(consumer.powered);
          break;
        case 'cargo':
          this.spacecraft.cargo.setPower(consumer.powered);
          break;
        case 'ew':
          this.spacecraft.ew.setPower(consumer.powered);
          break;
        case 'countermeasures':
          this.spacecraft.countermeasures.setPower(consumer.powered);
          break;
        case 'weapons':
          // Critical Integration: Weapons power management
          // If powered is false, weapons master safety is enabled
          this.spacecraft.weapons.weaponsSafety = !consumer.powered;
          break;
      }
    });
  }

  /**
   * Apply damage to a system
   */
  public applyDamage(damageEvent: DamageEvent): void {
    const { systemId, severity, type, cascading } = damageEvent;

    // Apply damage to the system
    switch (systemId) {
      case 'mainEngine':
        // Main engine doesn't have applyDamage yet - would need to implement
        // For now, just reduce health
        break;
      case 'navComputer':
        this.spacecraft.navComputer.applyDamage(severity);
        break;
      case 'communications':
        this.spacecraft.communications.applyDamage(severity);
        break;
      case 'environmental':
        this.spacecraft.environmental.applyDamage(severity);
        break;
      case 'landing':
        this.spacecraft.landing.applyDamage(severity);
        break;
      case 'docking':
        this.spacecraft.docking.applyDamage(severity);
        break;
      case 'cargo':
        this.spacecraft.cargo.applyDamage(severity);
        break;
      case 'ew':
        this.spacecraft.ew.applyDamage(severity);
        break;
      case 'countermeasures':
        this.spacecraft.countermeasures.applyDamage(severity);
        break;
      case 'thermal':
        this.spacecraft.thermal.setHeatGeneration('damage_heat', severity * 1000);
        break;
      case 'weapons':
        // Critical Integration: Weapons damage handling
        // Severe damage activates weapons safety
        if (severity > 0.5) {
          this.spacecraft.weapons.weaponsSafety = true;
        }
        break;
      case 'centerOfMass':
        // CoM system is computational - damage doesn't apply directly
        // But we track health for cascading failures
        break;
    }

    // Update system health
    const currentHealth = this.systemHealth.get(systemId) || 1.0;
    this.systemHealth.set(systemId, Math.max(0, currentHealth - severity));

    this.logEvent('damage_applied', { system: systemId, severity, type });

    // Cascading damage
    if (cascading && this.cascadeProtectionEnabled) {
      this.propagateDamage(systemId, severity * 0.3); // 30% damage propagates
    }
  }

  private propagateDamage(sourceSystemId: string, severity: number): void {
    // Find systems that depend on this one
    this.dependencies.forEach((dep, systemId) => {
      if (dep.dependsOn.includes(sourceSystemId)) {
        if (dep.criticalDependency && severity > 0.5) {
          // Critical dependency - cascade full damage
          this.applyDamage({
            systemId,
            severity: severity * 0.8,
            type: 'malfunction',
            timestamp: Date.now(),
            cascading: false // Prevent infinite cascade
          });
        }
      }
    });
  }

  private checkCascadingFailures(): void {
    // Check if critical systems have failed and shut down dependents
    this.dependencies.forEach((dep, systemId) => {
      const systemWorking = this.isSystemOperational(systemId);

      dep.dependsOn.forEach(dependencyId => {
        const dependencyWorking = this.isSystemOperational(dependencyId);

        if (!dependencyWorking && dep.criticalDependency && systemWorking) {
          // Dependency failed, shut down this system
          this.logEvent('cascade_failure', {
            system: systemId,
            failed_dependency: dependencyId
          });

          // Reduce system health
          const currentHealth = this.systemHealth.get(systemId) || 1.0;
          this.systemHealth.set(systemId, currentHealth * 0.5);
        }
      });
    });
  }

  private isSystemOperational(systemId: string): boolean {
    const health = this.systemHealth.get(systemId) || 0;
    return health > 0.2; // System is operational if health > 20%
  }

  private performAutoRepair(dt: number): void {
    // Slowly repair systems over time (if spare parts available)
    const sparePartsAvailable = this.spacecraft.cargo.inventory.spareParts;

    if (sparePartsAvailable > 0) {
      this.systemHealth.forEach((health, systemId) => {
        if (health < 1.0 && health > 0) {
          // Repair at 1% per 10 seconds
          const repairRate = 0.01 * (dt / 10.0);
          const newHealth = Math.min(1.0, health + repairRate);
          this.systemHealth.set(systemId, newHealth);

          if (newHealth >= 1.0) {
            // Consume a spare part
            this.spacecraft.cargo.consumeResource('spareParts', 1);
            this.logEvent('system_repaired', { system: systemId });
          }
        }
      });
    }
  }

  private checkEmergencyProtocols(): void {
    // Check for critical situations requiring emergency protocols
    const criticalSystems = ['environmental', 'electrical'];
    let criticalFailure = false;

    criticalSystems.forEach(systemId => {
      const health = this.systemHealth.get(systemId) || 0;
      if (health < 0.3) {
        criticalFailure = true;
      }
    });

    // Activate emergency protocol
    if (criticalFailure && !this.emergencyProtocolActive) {
      this.activateEmergencyProtocol();
    } else if (!criticalFailure && this.emergencyProtocolActive) {
      const elapsedTime = Date.now() - this.emergencyProtocolStartTime;
      if (elapsedTime > 60000) { // 1 minute stable
        this.deactivateEmergencyProtocol();
      }
    }
  }

  /**
   * Activate emergency protocol (maximum survival mode)
   */
  public activateEmergencyProtocol(): void {
    this.emergencyProtocolActive = true;
    this.emergencyProtocolStartTime = Date.now();

    // Go to EMCON silent
    this.powerManagement.setEMCON('minimal');

    // Activate emergency bus
    this.powerManagement.activateEmergencyBus();

    // Emergency oxygen if life support critical
    if ((this.systemHealth.get('environmental') || 0) < 0.3) {
      this.spacecraft.environmental.activateEmergencyOxygen();
    }

    this.logEvent('emergency_protocol_activated', {});
  }

  /**
   * Deactivate emergency protocol
   */
  public deactivateEmergencyProtocol(): void {
    this.emergencyProtocolActive = false;

    this.powerManagement.setEMCON('unrestricted');
    this.powerManagement.deactivateEmergencyBus();

    this.logEvent('emergency_protocol_deactivated', {});
  }

  /**
   * Set EMCON level
   */
  public setEMCON(level: EMCONLevel): void {
    this.powerManagement.setEMCON(level);
  }

  /**
   * Get overall ship health
   */
  public getOverallHealth(): number {
    let totalHealth = 0;
    let count = 0;

    this.systemHealth.forEach(health => {
      totalHealth += health;
      count++;
    });

    return count > 0 ? totalHealth / count : 0;
  }

  /**
   * Get system health report
   */
  public getSystemHealthReport(): Map<string, { health: number; operational: boolean; status: string }> {
    const report = new Map();

    this.systemHealth.forEach((health, systemId) => {
      let status = 'nominal';
      if (health < 0.3) status = 'critical';
      else if (health < 0.6) status = 'damaged';
      else if (health < 0.9) status = 'degraded';

      report.set(systemId, {
        health,
        operational: health > 0.2,
        status
      });
    });

    return report;
  }

  public getState() {
    const healthReport: any = {};
    this.getSystemHealthReport().forEach((report, systemId) => {
      healthReport[systemId] = report;
    });

    return {
      overallHealth: this.getOverallHealth(),
      systemHealth: healthReport,
      powerManagement: this.powerManagement.getState(),
      emergencyProtocolActive: this.emergencyProtocolActive,
      autoRepairEnabled: this.autoRepairEnabled,
      autoPowerManagementEnabled: this.autoPowerManagementEnabled,
      cascadeProtectionEnabled: this.cascadeProtectionEnabled
    };
  }

  private logEvent(type: string, data: any): void {
    this.events.push({ time: Date.now(), type, data });
  }
}
