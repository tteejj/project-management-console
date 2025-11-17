#!/usr/bin/env node

/**
 * Comprehensive Systems Status Screen
 *
 * Shows all spacecraft subsystems in a multi-panel view
 * Demonstrates power management, EMCON, damage control, and all new features
 */

import { Spacecraft } from '../src/spacecraft';

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',
  bgRed: '\x1b[41m',
  bgGreen: '\x1b[42m',
  bgYellow: '\x1b[43m'
};

class ComprehensiveSystemsScreen {
  private spacecraft: Spacecraft;
  private selectedStation: number = 0; // 0-4 for different stations

  constructor() {
    this.spacecraft = new Spacecraft();
    this.initialize();
  }

  private initialize(): void {
    // Start critical systems
    this.spacecraft.startReactor();
    this.spacecraft.startCoolantPump(0);

    // Set initial conditions
    this.spacecraft.physics.position = { x: 0, y: 0, z: 1737400 + 5000 };
    this.spacecraft.physics.velocity = { x: 0, y: 0, z: -20 };
    this.spacecraft.physics.propellantMass = 160;
  }

  public render(): void {
    console.clear();
    this.renderHeader();

    switch (this.selectedStation) {
      case 0:
        this.renderCaptainScreen();
        break;
      case 1:
        this.renderEngineeringScreen();
        break;
      case 2:
        this.renderTacticalScreen();
        break;
      case 3:
        this.renderLifeSupportScreen();
        break;
      case 4:
        this.renderCargoNavScreen();
        break;
    }

    this.renderFooter();
  }

  private renderHeader(): void {
    const state = this.spacecraft.getState();
    const integration = state.systemsIntegration;
    const overallHealth = integration.overallHealth;

    let healthColor = colors.green;
    if (overallHealth < 0.3) healthColor = colors.red;
    else if (overallHealth < 0.7) healthColor = colors.yellow;

    console.log(colors.bright + colors.cyan + '╔════════════════════════════════════════════════════════════════════════════════╗');
    console.log('║                     SPACECRAFT COMPREHENSIVE SYSTEMS STATUS                    ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════════╝' + colors.reset);

    console.log();
    console.log(`${colors.white}┌─ STATUS BAR ─────────────────────────────────────────────────────────────────┐${colors.reset}`);
    console.log(`│ Time: ${state.simulationTime.toFixed(1)}s │ Health: ${healthColor}${(overallHealth * 100).toFixed(0)}%${colors.reset} │ PWR: ${this.renderPowerBar(integration.powerManagement)} │ EMCON: ${this.getEMCONColor(integration.powerManagement.emconLevel)}${integration.powerManagement.emconLevel.toUpperCase()}${colors.reset} │`);
    console.log(`${colors.white}└──────────────────────────────────────────────────────────────────────────────┘${colors.reset}`);
    console.log();
  }

  private renderPowerBar(pm: any): string {
    const percent = (pm.generation / pm.demand) * 100;
    let color = colors.green;
    if (percent < 80) color = colors.yellow;
    if (percent < 50) color = colors.red;

    const bars = Math.floor(percent / 10);
    const barStr = '█'.repeat(Math.max(0, bars)) + '░'.repeat(Math.max(0, 10 - bars));

    return `${color}${barStr}${colors.reset} ${percent.toFixed(0)}%`;
  }

  private getEMCONColor(level: string): string {
    switch (level) {
      case 'unrestricted': return colors.green;
      case 'reduced': return colors.yellow;
      case 'minimal': return colors.magenta;
      case 'silent': return colors.red;
      default: return colors.white;
    }
  }

  private renderCaptainScreen(): void {
    console.log(colors.bright + colors.green + '╔═══ STATION 1: CAPTAIN / FLIGHT CONTROL ═══════════════════════════════════╗' + colors.reset);
    console.log();

    const state = this.spacecraft.getState();
    const physics = state.physics;
    const nav = state.navigation;
    const fc = state.flightControl;

    // Left column - Navigation
    console.log(colors.cyan + '┌─ NAVIGATION ──────────────┐' + colors.reset + '  ' + colors.yellow + '┌─ FLIGHT CONTROL ─────────┐' + colors.reset);
    console.log(`│ ALT:  ${this.pad(physics.altitude.toFixed(0), 8)} m  │  │ SAS:  ${this.getSASDisplay(fc.sasMode)}  │`);
    console.log(`│ VSPD: ${this.pad(physics.verticalSpeed.toFixed(2), 8)} m/s│  │ AUTO: ${this.getAutopilotDisplay(fc.autopilotMode)}  │`);
    console.log(`│ HSPD: ${this.pad(nav.horizontalSpeed.toFixed(2), 8)} m/s│  │ GMBL: ${fc.gimbalCommand.pitch.toFixed(1)}° ${fc.gimbalCommand.yaw.toFixed(1)}°${colors.reset}  │`);
    console.log(`│ TWR:  ${this.pad(nav.twr.toFixed(2), 8)}     │  │ THR:  ${this.renderThrottleBar(state.mainEngine.throttle)}  │`);
    console.log(`│ ΔV:   ${this.pad(nav.deltaVRemaining.toFixed(0), 8)} m/s│  └───────────────────────────┘`);
    console.log(`└────────────────────────────┘`);
    console.log();

    // Engine status
    const engine = state.mainEngine;
    let engineColor = colors.dim;
    if (engine.status === 'running') engineColor = colors.green;
    else if (engine.status === 'igniting') engineColor = colors.yellow;

    console.log(colors.cyan + '┌─ PROPULSION ──────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ MAIN ENGINE: ${engineColor}${engine.status.toUpperCase().padEnd(10)}${colors.reset} │ THRUST: ${this.renderThrustBar(engine.currentThrustN, 100000)}`);
    console.log(`│ TEMP: ${this.renderTempBar(engine.chamberTempK, 3000)} │ FUEL: ${this.renderFuelBar(state.fuel.totalFuel, 200)}`);
    console.log(`└────────────────────────────────────────────────────────────┘`);
    console.log();

    // Navball (simple ASCII representation)
    console.log(colors.cyan + '┌─ NAVBALL ─────┐' + colors.reset);
    console.log(`│      ${colors.green}↑${colors.reset}       │`);
    console.log(`│   ${colors.yellow}◄${colors.reset}  ${colors.white}⊕${colors.reset}  ${colors.yellow}►${colors.reset}  │`);
    console.log(`│      ${colors.green}↓${colors.reset}       │`);
    console.log(`└────────────────┘`);
  }

  private renderEngineeringScreen(): void {
    console.log(colors.bright + colors.yellow + '╔═══ STATION 2: ENGINEERING / POWER MANAGEMENT ═════════════════════════════╗' + colors.reset);
    console.log();

    const state = this.spacecraft.getState();
    const integration = state.systemsIntegration;
    const pm = integration.powerManagement;
    const electrical = state.electrical;

    // Power generation
    console.log(colors.cyan + '┌─ POWER GENERATION ────────────────────┐' + colors.reset);
    console.log(`│ REACTOR:   ${electrical.reactor.status === 'online' ? colors.green + 'ONLINE ' : colors.red + 'OFFLINE'}${colors.reset}  ${(electrical.reactor.outputKW * 1000).toFixed(0)}W  │`);
    console.log(`│ BATTERY:   ${this.renderBatteryBar(pm.batteryPercent)} ${pm.batteryPercent.toFixed(0)}%       │`);
    console.log(`│ CHARGING:  ${pm.batteryChargingW > 0 ? colors.green + '+' : pm.batteryChargingW < 0 ? colors.red + '' : ''}${pm.batteryChargingW.toFixed(0)}W${colors.reset}              │`);
    console.log(`└────────────────────────────────────────┘`);
    console.log();

    // Power distribution
    console.log(colors.cyan + '┌─ POWER DISTRIBUTION ──────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Generation: ${colors.green}${pm.generation.toFixed(0)}W${colors.reset}  │  Demand: ${this.getDemandColor(pm)}${pm.totalDemand.toFixed(0)}W${colors.reset}  │  ${pm.deficit > 0 ? colors.red + 'DEFICIT: ' + pm.deficit.toFixed(0) + 'W' : colors.green + 'Surplus: ' + pm.surplus.toFixed(0) + 'W'}${colors.reset}`);
    console.log(`└────────────────────────────────────────────────────────────────────────┘`);
    console.log();

    // Circuit breakers
    console.log(colors.cyan + '┌─ CIRCUIT BREAKERS ─────────────────────────────────────────────────────┐' + colors.reset);

    const consumers = pm.consumers.slice(0, 10); // Show first 10
    consumers.forEach((consumer: any) => {
      const statusColor = consumer.powered ? colors.green : colors.red;
      const statusText = consumer.powered ? 'ON ' : 'OFF';
      const priorityText = `P${consumer.priority}`.padEnd(3);
      const essentialMark = consumer.essential ? '⚠' : ' ';

      console.log(`│ [${statusColor}${statusText}${colors.reset}] ${consumer.name.padEnd(30)} ${priorityText} ${consumer.currentPowerW.toFixed(0).padStart(5)}W ${essentialMark} │`);
    });

    console.log(`└────────────────────────────────────────────────────────────────────────┘`);
    console.log();

    // Thermal
    const thermal = state.thermal;
    const reactorComponent = thermal.components.find((c: any) => c.name === 'reactor');
    const engineComponent = thermal.components.find((c: any) => c.name === 'main_engine');

    console.log(colors.cyan + '┌─ THERMAL MANAGEMENT ──────────────────┐' + colors.reset);
    console.log(`│ Reactor:     ${this.renderTempBar(reactorComponent ? reactorComponent.temperature : 300, 600)} │`);
    console.log(`│ Main Engine: ${this.renderTempBar(engineComponent ? engineComponent.temperature : 300, 3000)} │`);
    console.log(`│ Coolant:     ${state.coolant.loops[0].pumpActive ? colors.green + 'FLOWING' : colors.red + 'STOPPED'}${colors.reset}            │`);
    console.log(`└────────────────────────────────────────┘`);
  }

  private renderTacticalScreen(): void {
    console.log(colors.bright + colors.red + '╔═══ STATION 3: TACTICAL / DEFENSIVE SYSTEMS ═══════════════════════════════╗' + colors.reset);
    console.log();

    const state = this.spacecraft.getState();
    const ew = state.ew;
    const cm = state.countermeasures;
    const comms = state.communications;

    // Electronic Warfare
    console.log(colors.cyan + '┌─ ELECTRONIC WARFARE ──────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ RWR:          ${ew.rwr.active ? colors.green + 'ACTIVE  ' : colors.red + 'INACTIVE'}${colors.reset}  Range: ${ew.rwr.detectionRangeKm}km                    │`);
    console.log(`│ EMCON:        ${this.getEMCONColor(ew.emconLevel)}${ew.emconLevel.toUpperCase().padEnd(12)}${colors.reset}                                        │`);
    console.log(`│ Threats:      ${ew.threatAssessment.totalThreats} detected (${colors.red}${ew.threatAssessment.criticalThreats} critical${colors.reset})                │`);
    console.log(`│ Jammers:      ${ew.threatAssessment.activeJammers}/${ew.jammers.length} active                                      │`);
    console.log(`└────────────────────────────────────────────────────────────────────────┘`);
    console.log();

    // Countermeasures
    console.log(colors.cyan + '┌─ COUNTERMEASURES ─────────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ CHAFF:   [${this.renderLoadoutBar(cm.loadout.chaff, cm.maxCapacity.chaff)}] ${cm.loadout.chaff}/${cm.maxCapacity.chaff}                     │`);
    console.log(`│ FLARES:  [${this.renderLoadoutBar(cm.loadout.flares, cm.maxCapacity.flares)}] ${cm.loadout.flares}/${cm.maxCapacity.flares}                     │`);
    console.log(`│ DECOYS:  [${this.renderLoadoutBar(cm.loadout.decoys, cm.maxCapacity.decoys)}] ${cm.loadout.decoys}/${cm.maxCapacity.decoys}                       │`);
    console.log(`│ ECM:      ${cm.ecmActive ? colors.green + 'ACTIVE' : colors.dim + 'STANDBY'}${colors.reset}                                                 │`);
    console.log(`└────────────────────────────────────────────────────────────────────────┘`);
    console.log();

    // Communications
    console.log(colors.cyan + '┌─ COMMUNICATIONS ──────────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Active Links:  ${comms.activeLinks.length}                                                       │`);
    console.log(`│ Encryption:    ${comms.encryptionEnabled ? colors.green + 'ENABLED ' : colors.yellow + 'DISABLED'}${colors.reset}                                          │`);
    console.log(`│ Beacon:        ${comms.emergencyBeaconActive ? colors.red + 'TRANSMITTING' : colors.dim + 'INACTIVE    '}${colors.reset}                                  │`);
    console.log(`│ Processing:    ${this.renderProcessBar(comms.processingLoad)}                                │`);
    console.log(`└────────────────────────────────────────────────────────────────────────┘`);
  }

  private renderLifeSupportScreen(): void {
    console.log(colors.bright + colors.green + '╔═══ STATION 4: LIFE SUPPORT / ENVIRONMENTAL ═══════════════════════════════╗' + colors.reset);
    console.log();

    const state = this.spacecraft.getState();
    const env = state.environmental;

    // Compartments (show first 3)
    const compartments = env.compartments.slice(0, 3);

    compartments.forEach((comp: any) => {
      console.log(colors.cyan + `┌─ COMPARTMENT: ${comp.name.toUpperCase()} ${'─'.repeat(50 - comp.name.length)}┐` + colors.reset);
      console.log(`│ O₂:       ${this.renderAtmosphereBar(comp.conditions.oxygenPercentage, 21)} ${comp.conditions.oxygenPercentage.toFixed(1)}%                │`);
      console.log(`│ CO₂:      ${this.renderCO2Bar(comp.conditions.co2PPM)} ${comp.conditions.co2PPM.toFixed(0)} ppm           │`);
      console.log(`│ Pressure: ${this.renderPressureBar(comp.conditions.pressureKPa)} ${comp.conditions.pressureKPa.toFixed(1)} kPa        │`);
      console.log(`│ Temp:     ${this.renderTempBar(comp.conditions.temperature, 350)} ${comp.conditions.temperature.toFixed(0)}K                  │`);
      console.log(`│ Status:   ${this.getCompartmentStatus(comp.conditions)}                                     │`);
      console.log(`└────────────────────────────────────────────────────────────────────────┘`);
      console.log();
    });

    // Global systems
    console.log(colors.cyan + '┌─ LIFE SUPPORT SYSTEMS ────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ O₂ Generator:  ${env.oxygenGenerator.operational ? colors.green + 'ON ' : colors.red + 'OFF'}${colors.reset}  Output: ${env.oxygenGenerator.currentOutput.toFixed(2)} kg/hr       │`);
    console.log(`│ CO₂ Scrubber:  ${env.scrubbers.operational ? colors.green + 'ON ' : colors.red + 'OFF'}${colors.reset}  Filter: [${this.renderFilterBar(env.scrubbers.filterLife)}] ${(env.scrubbers.filterLife * 100).toFixed(0)}%  │`);
    console.log(`│ Emergency O₂:  ${env.emergencyOxygen.available ? colors.green + 'READY' : colors.red + 'DEPLETED'}${colors.reset}  ${env.emergencyOxygen.remainingKg.toFixed(1)}kg remaining      │`);
    console.log(`│ Hull Breach:   ${env.hullIntegrity.breachDetected ? colors.red + 'DETECTED! ' + env.hullIntegrity.leakRate.toFixed(1) + ' kg/hr' : colors.green + 'SEALED'}${colors.reset}              │`);
    console.log(`└────────────────────────────────────────────────────────────────────────┘`);
    console.log();

    // Radiation
    console.log(colors.cyan + '┌─ RADIATION PROTECTION ────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Shielding:     ${(env.radiationShielding.effectiveness * 100).toFixed(0)}% effective                                   │`);
    console.log(`│ Current Level: ${env.radiationShielding.currentRadiationLevel.toFixed(3)} mSv/hr                               │`);
    console.log(`│ Cumulative:    ${env.radiationShielding.cumulativeExposure.toFixed(1)} mSv                                     │`);
    console.log(`└────────────────────────────────────────────────────────────────────────┘`);
  }

  private renderCargoNavScreen(): void {
    console.log(colors.bright + colors.magenta + '╔═══ STATION 5: CARGO & DOCKING ════════════════════════════════════════════╗' + colors.reset);
    console.log();

    const state = this.spacecraft.getState();
    const cargo = state.cargo;
    const docking = state.docking;
    const landing = state.landing;

    // Cargo
    console.log(colors.cyan + '┌─ CARGO MANAGEMENT ────────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Total Mass:    ${cargo.totalMass.toFixed(1)} kg                                               │`);
    console.log(`│ Center of Mass: (${cargo.centerOfMass.x.toFixed(2)}, ${cargo.centerOfMass.y.toFixed(2)}, ${cargo.centerOfMass.z.toFixed(2)})                    │`);
    console.log(`│ Items:         ${cargo.manifest.length} items loaded                                       │`);
    console.log(`└────────────────────────────────────────────────────────────────────────┘`);
    console.log();

    // Inventory
    console.log(colors.cyan + '┌─ RESOURCE INVENTORY ──────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Food:          ${cargo.inventory.food.toFixed(0)} kg                                                  │`);
    console.log(`│ Water:         ${cargo.inventory.water.toFixed(0)} kg                                                 │`);
    console.log(`│ Oxygen:        ${cargo.inventory.oxygen.toFixed(0)} kg                                                 │`);
    console.log(`│ Spare Parts:   ${cargo.inventory.spareParts}                                                      │`);
    console.log(`│ Medical:       ${cargo.inventory.medicalSupplies}                                                      │`);
    console.log(`└────────────────────────────────────────────────────────────────────────┘`);
    console.log();

    // Docking
    console.log(colors.cyan + '┌─ DOCKING SYSTEM ──────────────────────────────────────────────────────┐' + colors.reset);
    docking.ports.forEach((port: any) => {
      const statusColor = port.status === 'available' ? colors.green :
                          port.status === 'hard_docked' ? colors.blue :
                          colors.yellow;
      console.log(`│ ${port.id.padEnd(15)} [${statusColor}${port.status.toUpperCase().padEnd(15)}${colors.reset}] ${port.type.padEnd(15)} │`);
    });
    console.log(`└────────────────────────────────────────────────────────────────────────┘`);
    console.log();

    // Landing
    console.log(colors.cyan + '┌─ LANDING SYSTEM ──────────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Gear Status:   ${landing.allGearDeployed ? colors.green + 'DEPLOYED' : colors.dim + 'RETRACTED'}${colors.reset}  ${landing.allGearLocked ? colors.green + '[LOCKED]' : colors.yellow + '[UNLOCKED]'}${colors.reset}        │`);
    console.log(`│ Surface:       ${landing.surfaceContact ? colors.green + 'CONTACT' : colors.dim + 'NO CONTACT'}${colors.reset}                                      │`);
    console.log(`│ Radar:         ${landing.terrainRadarActive ? colors.green + 'ACTIVE' : colors.dim + 'STANDBY'}${colors.reset}                                       │`);
    console.log(`│ Lights:        ${landing.lightsOn ? colors.green + 'ON' : colors.dim + 'OFF'}${colors.reset}                                              │`);
    console.log(`└────────────────────────────────────────────────────────────────────────┘`);
  }

  private renderFooter(): void {
    console.log();
    console.log(colors.dim + '─'.repeat(80) + colors.reset);
    console.log(colors.white + 'Station: [1] Captain  [2] Engineering  [3] Tactical  [4] Life Support  [5] Cargo/Docking' + colors.reset);
    console.log(colors.dim + 'Press CTRL+C to exit' + colors.reset);
  }

  // Helper rendering functions
  private pad(str: string, len: number): string {
    return str.padStart(len);
  }

  private getSASDisplay(mode: string): string {
    const modeMap: any = {
      'off': colors.dim + 'OFF      ',
      'stability': colors.green + 'STAB     ',
      'prograde': colors.cyan + 'PROGRADE ',
      'retrograde': colors.yellow + 'RETRO    '
    };
    return (modeMap[mode] || colors.white + mode.padEnd(9)) + colors.reset;
  }

  private getAutopilotDisplay(mode: string): string {
    if (mode === 'off') return colors.dim + 'OFF      ' + colors.reset;
    return colors.green + mode.substring(0, 9).toUpperCase().padEnd(9) + colors.reset;
  }

  private renderThrottleBar(throttle: number): string {
    const bars = Math.floor(throttle * 10);
    return colors.green + '█'.repeat(bars) + colors.dim + '░'.repeat(10 - bars) + colors.reset + ` ${(throttle * 100).toFixed(0)}%`;
  }

  private renderThrustBar(current: number, max: number): string {
    const percent = (current / max) * 100;
    const bars = Math.floor(percent / 10);
    return colors.yellow + '█'.repeat(bars) + colors.dim + '░'.repeat(10 - bars) + colors.reset + ` ${percent.toFixed(0)}%`;
  }

  private renderTempBar(temp: number, maxTemp: number): string {
    const percent = (temp / maxTemp) * 100;
    let color = colors.green;
    if (percent > 80) color = colors.red;
    else if (percent > 60) color = colors.yellow;

    const bars = Math.floor(percent / 10);
    return color + '█'.repeat(Math.min(10, bars)) + colors.dim + '░'.repeat(Math.max(0, 10 - bars)) + colors.reset + ` ${temp.toFixed(0)}K`;
  }

  private renderFuelBar(current: number, max: number): string {
    const percent = (current / max) * 100;
    const bars = Math.floor(percent / 10);
    let color = colors.green;
    if (percent < 20) color = colors.red;
    else if (percent < 40) color = colors.yellow;

    return color + '█'.repeat(bars) + colors.dim + '░'.repeat(10 - bars) + colors.reset + ` ${percent.toFixed(0)}%`;
  }

  private renderBatteryBar(percent: number): string {
    const bars = Math.floor(percent / 10);
    let color = colors.green;
    if (percent < 20) color = colors.red;
    else if (percent < 40) color = colors.yellow;

    return color + '█'.repeat(bars) + colors.dim + '░'.repeat(10 - bars) + colors.reset;
  }

  private getDemandColor(pm: any): string {
    const percent = (pm.totalDemand / pm.generation) * 100;
    if (percent > 100) return colors.red;
    if (percent > 90) return colors.yellow;
    return colors.green;
  }

  private renderLoadoutBar(current: number, max: number): string {
    const percent = (current / max) * 100;
    const bars = Math.floor(percent / 10);
    return colors.cyan + '█'.repeat(bars) + colors.dim + '░'.repeat(10 - bars) + colors.reset;
  }

  private renderProcessBar(load: number): string {
    const bars = Math.floor(load * 10);
    return colors.blue + '█'.repeat(bars) + colors.dim + '░'.repeat(10 - bars) + colors.reset + ` ${(load * 100).toFixed(0)}%`;
  }

  private renderAtmosphereBar(percent: number, nominal: number): string {
    const diff = Math.abs(percent - nominal);
    let color = colors.green;
    if (diff > 3) color = colors.red;
    else if (diff > 1) color = colors.yellow;

    const bars = Math.floor((percent / nominal) * 10);
    return color + '█'.repeat(Math.min(10, bars)) + colors.dim + '░'.repeat(Math.max(0, 10 - bars)) + colors.reset;
  }

  private renderCO2Bar(ppm: number): string {
    let color = colors.green;
    if (ppm > 5000) color = colors.red;
    else if (ppm > 2000) color = colors.yellow;

    const bars = Math.floor((ppm / 5000) * 10);
    return color + '█'.repeat(Math.min(10, bars)) + colors.dim + '░'.repeat(Math.max(0, 10 - bars)) + colors.reset;
  }

  private renderPressureBar(kpa: number): string {
    const percent = (kpa / 101.3) * 100;
    let color = colors.green;
    if (percent < 80) color = colors.red;
    else if (percent < 95) color = colors.yellow;

    const bars = Math.floor(percent / 10);
    return color + '█'.repeat(Math.min(10, bars)) + colors.dim + '░'.repeat(Math.max(0, 10 - bars)) + colors.reset;
  }

  private renderFilterBar(life: number): string {
    const bars = Math.floor(life * 10);
    let color = colors.green;
    if (life < 0.2) color = colors.red;
    else if (life < 0.4) color = colors.yellow;

    return color + '█'.repeat(bars) + colors.dim + '░'.repeat(10 - bars) + colors.reset;
  }

  private getCompartmentStatus(conditions: any): string {
    const o2Ok = Math.abs(conditions.oxygenPercentage - 21) < 2;
    const co2Ok = conditions.co2PPM < 2000;
    const pressureOk = conditions.pressureKPa > 95;

    if (o2Ok && co2Ok && pressureOk) return colors.green + '● NOMINAL' + colors.reset;
    if (!o2Ok || !pressureOk) return colors.red + '● CRITICAL' + colors.reset;
    return colors.yellow + '● WARNING' + colors.reset;
  }
}

// Run the screen
const screen = new ComprehensiveSystemsScreen();
screen.render();
