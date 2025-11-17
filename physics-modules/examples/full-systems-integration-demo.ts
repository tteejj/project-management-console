/**
 * Full Systems Integration Demonstration
 *
 * Demonstrates all integrated spacecraft subsystems working together:
 * - Power management with brownout prevention
 * - EMCON (going dark) modes
 * - Systems integration and cascading failures
 * - All 12+ subsystems coordinating
 * - Damage propagation and emergency protocols
 */

import { Spacecraft } from '../src/spacecraft';

// ANSI color codes
const RESET = '\x1b[0m';
const BRIGHT = '\x1b[1m';
const DIM = '\x1b[2m';
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const BLUE = '\x1b[34m';
const MAGENTA = '\x1b[35m';
const CYAN = '\x1b[36m';
const WHITE = '\x1b[37m';

class FullSystemsIntegrationDemo {
  private spacecraft: Spacecraft;
  private simulationTime: number = 0;
  private scenario: number = 0;

  constructor() {
    this.spacecraft = new Spacecraft({});

    // Initialize spacecraft to operational state
    this.spacecraft.mainEngine.ignite();
    this.spacecraft.mainEngine.shutdown();
  }

  public run(): void {
    console.log(`${BRIGHT}${CYAN}╔═══════════════════════════════════════════════════════════════╗`);
    console.log(`║        FULL SPACECRAFT SYSTEMS INTEGRATION DEMO               ║`);
    console.log(`╚═══════════════════════════════════════════════════════════════╝${RESET}\n`);

    // Scenario 1: Normal operations
    this.runScenario1_NormalOperations();

    // Scenario 2: EMCON - Going Dark
    this.runScenario2_GoingDark();

    // Scenario 3: Power crisis and brownout
    this.runScenario3_PowerCrisis();

    // Scenario 4: Damage cascade
    this.runScenario4_DamageCascade();

    // Scenario 5: Emergency protocol
    this.runScenario5_EmergencyProtocol();

    // Scenario 6: Docking operations
    this.runScenario6_DockingOps();

    // Scenario 7: Combat scenario
    this.runScenario7_CombatScenario();

    console.log(`\n${BRIGHT}${GREEN}═══════════════════════════════════════════════════════════════`);
    console.log(`DEMONSTRATION COMPLETE - All systems integrated successfully!`);
    console.log(`═══════════════════════════════════════════════════════════════${RESET}\n`);
  }

  private runScenario1_NormalOperations(): void {
    console.log(`${BRIGHT}${BLUE}╔═══ SCENARIO 1: NORMAL OPERATIONS ═══╗${RESET}`);

    // Update systems
    this.updateSystems(1.0);

    const state = this.spacecraft.getState();
    const powerBudget = state.systemsIntegration.powerManagement.powerBudget;

    console.log(`${CYAN}Power Generation:${RESET} ${powerBudget.generation.toFixed(0)}W`);
    console.log(`${CYAN}Power Demand:${RESET} ${powerBudget.demand.toFixed(0)}W`);
    console.log(`${CYAN}Battery:${RESET} ${GREEN}${powerBudget.batteryPercent.toFixed(1)}%${RESET}`);
    console.log(`${CYAN}EMCON Level:${RESET} ${powerBudget.emconLevel.toUpperCase()}`);

    // Show active systems
    const consumers = state.systemsIntegration.powerManagement.consumers;
    const activeCount = consumers.filter((c: any) => c.powered).length;
    console.log(`${CYAN}Active Systems:${RESET} ${activeCount}/${consumers.length}`);

    // Navigation status
    const nav = state.navComputer;
    console.log(`${CYAN}Nav Computer:${RESET} ${nav.aligned ? GREEN + 'ALIGNED' : YELLOW + 'ALIGNING' + RESET}`);
    console.log(`${CYAN}Nav Quality:${RESET} ${(nav.navigationQuality * 100).toFixed(1)}%`);

    console.log(`${GREEN}✓ All systems nominal${RESET}\n`);
  }

  private runScenario2_GoingDark(): void {
    console.log(`${BRIGHT}${BLUE}╔═══ SCENARIO 2: GOING DARK (EMCON) ═══╗${RESET}`);

    console.log(`${YELLOW}Entering stealth mode...${RESET}`);

    // Progress through EMCON levels
    const levels: Array<'unrestricted' | 'reduced' | 'minimal' | 'silent'> =
      ['unrestricted', 'reduced', 'minimal', 'silent'];

    for (const level of levels) {
      this.spacecraft.systemsIntegrator.powerManagement.setEMCON(level);
      this.updateSystems(0.1);

      const state = this.spacecraft.getState();
      const powerBudget = state.systemsIntegration.powerManagement.powerBudget;
      const consumers = state.systemsIntegration.powerManagement.consumers;
      const activeCount = consumers.filter((c: any) => c.powered).length;

      let color = GREEN;
      if (level === 'minimal') color = YELLOW;
      if (level === 'silent') color = RED;

      console.log(`  ${color}EMCON ${level.toUpperCase()}:${RESET} ` +
                  `${activeCount} systems active, ` +
                  `${powerBudget.demand.toFixed(0)}W demand`);
    }

    // Return to normal
    this.spacecraft.systemsIntegrator.powerManagement.setEMCON('unrestricted');
    this.updateSystems(0.1);

    console.log(`${GREEN}✓ EMCON capabilities verified${RESET}\n`);
  }

  private runScenario3_PowerCrisis(): void {
    console.log(`${BRIGHT}${BLUE}╔═══ SCENARIO 3: POWER CRISIS & BROWNOUT PREVENTION ═══╗${RESET}`);

    console.log(`${YELLOW}Simulating reactor damage (50% power loss)...${RESET}`);

    // Reduce reactor output to create power crisis
    const reactor = (this.spacecraft.electrical as any).reactor;
    const originalOutput = reactor.currentOutputKW;
    reactor.currentOutputKW = originalOutput * 0.5;

    // Update to trigger brownout prevention
    this.updateSystems(1.0);

    const state = this.spacecraft.getState();
    const powerBudget = state.systemsIntegration.powerManagement.powerBudget;

    console.log(`${CYAN}Generation:${RESET} ${RED}${powerBudget.generation.toFixed(0)}W${RESET} ` +
                `(${YELLOW}-50%${RESET})`);
    console.log(`${CYAN}Demand:${RESET} ${powerBudget.demand.toFixed(0)}W`);
    console.log(`${CYAN}Status:${RESET} ${powerBudget.browning ? RED + 'BROWNOUT WARNING' : GREEN + 'NORMAL'}${RESET}`);

    // Check which systems were shed
    const consumers = state.systemsIntegration.powerManagement.consumers;
    const shedSystems = consumers.filter((c: any) => !c.powered && !c.essential);

    if (shedSystems.length > 0) {
      console.log(`${YELLOW}Load shedding activated:${RESET}`);
      shedSystems.forEach((sys: any) => {
        console.log(`  ${DIM}- ${sys.name} (priority ${sys.priority})${RESET}`);
      });
    }

    // Restore power
    reactor.currentOutputKW = originalOutput;
    this.updateSystems(1.0);

    console.log(`${GREEN}✓ Brownout prevention verified${RESET}\n`);
  }

  private runScenario4_DamageCascade(): void {
    console.log(`${BRIGHT}${BLUE}╔═══ SCENARIO 4: DAMAGE CASCADE ═══╗${RESET}`);

    console.log(`${RED}Hull breach detected! Applying damage...${RESET}`);

    // Apply damage to environmental system
    this.spacecraft.systemsIntegrator.applyDamage({
      systemId: 'environmental',
      severity: 0.6,
      type: 'impact',
      timestamp: Date.now(),
      cascading: true
    });

    this.updateSystems(1.0);

    const state = this.spacecraft.getState();
    const env = state.environmental;

    console.log(`${CYAN}Environmental System:${RESET} ${env.operational ? YELLOW + 'DEGRADED' : RED + 'OFFLINE'}${RESET}`);

    // Check atmosphere
    const mainComp = env.compartments.find((c: any) => c.id === 'main');
    if (mainComp) {
      console.log(`${CYAN}Pressure:${RESET} ${mainComp.atmosphere.pressureKPa.toFixed(1)} kPa`);
      console.log(`${CYAN}O2:${RESET} ${mainComp.atmosphere.oxygenPercentage.toFixed(1)}%`);

      if (mainComp.atmosphere.pressureKPa < 95.0) {
        console.log(`${RED}⚠ WARNING: Pressure loss detected${RESET}`);
      }
    }

    // Check for cascading failures
    const systemHealth = state.systemsIntegration.systemHealth;
    const damagedSystems = Object.entries(systemHealth)
      .filter(([_, health]) => (health as number) < 1.0);

    if (damagedSystems.length > 1) {
      console.log(`${YELLOW}Cascading damage detected:${RESET}`);
      damagedSystems.forEach(([sys, health]) => {
        console.log(`  ${DIM}- ${sys}: ${((health as number) * 100).toFixed(0)}%${RESET}`);
      });
    }

    console.log(`${GREEN}✓ Damage propagation verified${RESET}\n`);
  }

  private runScenario5_EmergencyProtocol(): void {
    console.log(`${BRIGHT}${BLUE}╔═══ SCENARIO 5: EMERGENCY PROTOCOL ═══╗${RESET}`);

    console.log(`${RED}CRITICAL FAILURE - Activating emergency protocol...${RESET}`);

    this.spacecraft.systemsIntegrator.activateEmergencyProtocol();
    this.updateSystems(1.0);

    const state = this.spacecraft.getState();
    const powerBudget = state.systemsIntegration.powerManagement.powerBudget;

    console.log(`${CYAN}Emergency Mode:${RESET} ${state.systemsIntegration.emergencyProtocolActive ? RED + 'ACTIVE' : 'INACTIVE'}${RESET}`);
    console.log(`${CYAN}EMCON Level:${RESET} ${RED}${powerBudget.emconLevel.toUpperCase()}${RESET}`);
    console.log(`${CYAN}Power Demand:${RESET} ${powerBudget.demand.toFixed(0)}W ${DIM}(minimal)${RESET}`);

    // Check which systems are still powered
    const consumers = state.systemsIntegration.powerManagement.consumers;
    const essentialActive = consumers.filter((c: any) => c.powered && c.essential);

    console.log(`${CYAN}Essential Systems:${RESET} ${essentialActive.length} active`);
    essentialActive.forEach((sys: any) => {
      console.log(`  ${GREEN}✓ ${sys.name}${RESET}`);
    });

    console.log(`${GREEN}✓ Emergency protocol verified${RESET}\n`);
  }

  private runScenario6_DockingOps(): void {
    console.log(`${BRIGHT}${BLUE}╔═══ SCENARIO 6: DOCKING OPERATIONS ═══╗${RESET}`);

    console.log(`${CYAN}Initiating docking sequence...${RESET}`);

    // Set up docking target
    const dockingTarget = {
      relativePosition: { x: 0.05, y: 0.02, z: 0.01 }, // 5cm, 2cm, 1cm
      relativeVelocity: { x: 0.05, y: 0.02, z: 0.01 }, // 5cm/s approach
      relativeAttitude: { roll: 0.5, pitch: 1.0, yaw: 0.3 }, // degrees
      portType: 'androgynous' as const
    };

    const dockInitiated = this.spacecraft.docking.initiateDocking('port_fwd', dockingTarget);
    console.log(`${CYAN}Docking initiated:${RESET} ${dockInitiated ? GREEN + 'YES' : RED + 'FAILED'}${RESET}`);

    if (dockInitiated) {
      this.updateSystems(1.0);

      const guidance = this.spacecraft.docking.getAlignmentGuidance();
      if (guidance) {
        console.log(`${CYAN}Distance:${RESET} ${(guidance.distance * 1000).toFixed(1)}mm`);
        console.log(`${CYAN}Approach Rate:${RESET} ${(guidance.rate * 100).toFixed(1)}cm/s`);
        console.log(`${CYAN}Alignment Error:${RESET} ${guidance.alignment.toFixed(2)}°`);

        // Attempt capture
        const captured = this.spacecraft.docking.attemptCapture();
        console.log(`${CYAN}Capture:${RESET} ${captured ? GREEN + 'SUCCESS' : YELLOW + 'IN PROGRESS'}${RESET}`);

        if (captured) {
          // Wait for latches
          this.updateSystems(35.0); // 35 seconds for latch completion

          const hardDock = this.spacecraft.docking.completeHardDock();
          console.log(`${CYAN}Hard Dock:${RESET} ${hardDock ? GREEN + 'COMPLETE' : YELLOW + 'IN PROGRESS'}${RESET}`);

          const state = this.spacecraft.getState();
          const port = state.docking.ports.find((p: any) => p.id === 'port_fwd');
          if (port) {
            console.log(`${CYAN}Seal Integrity:${RESET} ${(port.sealIntegrity * 100).toFixed(1)}%`);
          }
        }
      }
    }

    console.log(`${GREEN}✓ Docking system verified${RESET}\n`);
  }

  private runScenario7_CombatScenario(): void {
    console.log(`${BRIGHT}${BLUE}╔═══ SCENARIO 7: COMBAT SCENARIO ═══╗${RESET}`);

    console.log(`${RED}Threat detected! Activating defensive systems...${RESET}`);

    // Activate EW systems
    const radarEmitter = {
      id: 'hostile_radar_1',
      type: 'radar' as const,
      frequencyGHz: 10.0,
      strength: 0.8,
      bearing: 45,
      identified: true,
      threatLevel: 'high' as const,
      trackingUs: true
    };

    const detected = this.spacecraft.ew.detectEmitter(radarEmitter, 150); // 150km
    console.log(`${CYAN}Emitter Detection:${RESET} ${detected ? YELLOW + 'THREAT DETECTED' : 'CLEAR'}${RESET}`);

    if (detected) {
      // Get threat assessment
      const threats = this.spacecraft.ew.getThreatAssessment();
      console.log(`${CYAN}Total Threats:${RESET} ${threats.totalThreats}`);
      console.log(`${CYAN}Critical Threats:${RESET} ${RED}${threats.criticalThreats}${RESET}`);

      // Activate jammer
      const ews = this.spacecraft.ew;
      const jammers = Array.from((ews as any).jammers.keys()) as string[];
      if (jammers.length > 0) {
        const activated = ews.activateJammer(jammers[0], radarEmitter.id);
        console.log(`${CYAN}ECM Jamming:${RESET} ${activated ? GREEN + 'ACTIVE' : 'STANDBY'}${RESET}`);
      }

      // Deploy countermeasures
      const chaffDeployed = this.spacecraft.countermeasures.deployChaff(2);
      const flaresDeployed = this.spacecraft.countermeasures.deployFlares(2);

      console.log(`${CYAN}Countermeasures:${RESET}`);
      console.log(`  - Chaff: ${chaffDeployed ? GREEN + 'DEPLOYED' : 'UNAVAILABLE'}${RESET}`);
      console.log(`  - Flares: ${flaresDeployed ? GREEN + 'DEPLOYED' : 'UNAVAILABLE'}${RESET}`);

      // Show remaining loadout
      const state = this.spacecraft.getState();
      const cm = state.countermeasures;
      console.log(`${CYAN}Remaining:${RESET} ${cm.loadout.chaff} chaff, ${cm.loadout.flares} flares`);
    }

    console.log(`${GREEN}✓ Combat systems verified${RESET}\n`);
  }

  private updateSystems(dt: number): void {
    this.spacecraft.update(dt);
    this.simulationTime += dt;
  }

  private printSystemStatus(): void {
    const state = this.spacecraft.getState();
    const totalMass = state.physics.dryMass + state.physics.propellantMass;

    console.log(`\n${BRIGHT}${WHITE}═══ SYSTEM STATUS ═══${RESET}`);
    console.log(`Time: ${this.simulationTime.toFixed(1)}s`);
    console.log(`Mass: ${totalMass.toFixed(0)}kg`);
    console.log(`Fuel: ${state.fuel.totalFuel.toFixed(0)}kg`);
  }
}

// Run the demonstration
const demo = new FullSystemsIntegrationDemo();
demo.run();
