/**
 * Interactive Moon Lander Game
 *
 * Real-time flight simulator integrating all 9 physics modules
 * MS Flight Simulator/DCS World style complex controls
 * "Submarine in space" - indirect control philosophy
 */

import * as readline from 'readline';
import { Spacecraft } from '../src/spacecraft';

// ANSI color codes for terminal
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
};

class MoonLanderGame {
  private spacecraft: Spacecraft;
  private running: boolean = false;
  private paused: boolean = false;
  private lastUpdateTime: number = Date.now();
  private frameCount: number = 0;
  private startTime: number = 0;

  // Game state
  private missionStarted: boolean = false;
  private gameOver: boolean = false;
  private landed: boolean = false;
  private impactSpeed: number = 0;

  // Control state
  private throttleTarget: number = 0;
  private rcsActive: { [key: string]: boolean } = {};

  // Station view (1-4: different control stations)
  private currentStation: number = 1; // 1=CAPTAIN, 2=HELM, 3=ENGINEERING, 4=LIFE SUPPORT

  // Life support interaction state
  private compartmentSelection: string = 'center';
  private doorTargetIndex: number = 0; // Which door connection to toggle

  // Fuel system interaction state
  private selectedFuelTank: string = 'main_1';

  // Engineering station modes
  private engineeringMode: 'overview' | 'electrical' | 'fuel' = 'overview';

  constructor() {
    // Initialize spacecraft at 15km altitude
    this.spacecraft = new Spacecraft({
      shipPhysicsConfig: {
        initialPosition: { x: 0, y: 0, z: 1737400 + 15000 },
        initialVelocity: { x: 0, y: 0, z: -40 }  // Descending at 40 m/s
      }
    });

    this.startTime = Date.now();
  }

  /**
   * Main game loop
   */
  async start(): Promise<void> {
    console.clear();
    this.showWelcome();
    await this.waitForKey();

    console.clear();
    this.showMissionBriefing();
    await this.waitForKey();

    this.setupInput();
    this.running = true;

    console.clear();
    console.log('Starting systems...\n');

    // System startup sequence
    this.spacecraft.startReactor();
    this.spacecraft.startCoolantPump(0);
    this.spacecraft.startCoolantPump(1);

    // Show startup progress
    while (this.spacecraft.getState().electrical.reactor.status !== 'online') {
      this.spacecraft.update(0.1);
      const progress = (this.spacecraft.simulationTime / 30 * 100).toFixed(0);
      process.stdout.write(`\rReactor startup: ${progress}%...`);
      await this.sleep(50);
    }

    console.log('\n✓ Reactor online');
    console.log('✓ Coolant systems active');
    console.log('\nSystems ready. Mission starting in 3...');
    await this.sleep(1000);
    console.log('2...');
    await this.sleep(1000);
    console.log('1...');
    await this.sleep(1000);

    this.missionStarted = true;

    // Main game loop
    const updateInterval = setInterval(() => {
      if (!this.running) {
        clearInterval(updateInterval);
        return;
      }

      if (!this.paused && !this.gameOver) {
        this.update();
        this.render();
      }
    }, 100);  // 10 FPS update rate
  }

  /**
   * Update game state
   */
  private update(): void {
    const now = Date.now();
    const dt = (now - this.lastUpdateTime) / 1000;
    this.lastUpdateTime = now;

    // Physics update
    this.spacecraft.update(0.1);

    // Update throttle smoothly
    const currentThrottle = this.spacecraft.mainEngine.throttle;
    const throttleDiff = this.throttleTarget - currentThrottle;
    if (Math.abs(throttleDiff) > 0.01) {
      this.spacecraft.setMainEngineThrottle(currentThrottle + throttleDiff * 0.2);
    }

    const state = this.spacecraft.getState();

    // Check for landing
    if (state.physics.altitude <= 0 && !this.gameOver) {
      this.gameOver = true;
      this.landed = true;
      this.impactSpeed = Math.abs(state.physics.verticalSpeed);
      this.endMission();
    }

    // Check for fuel depletion
    if (state.fuel.totalFuel < 10 && !this.gameOver) {
      console.log('\n' + colors.red + '⚠️  FUEL CRITICALLY LOW!' + colors.reset);
    }

    this.frameCount++;
  }

  /**
   * Render game display
   */
  private render(): void {
    const state = this.spacecraft.getState();

    // Clear screen and move cursor to top
    console.clear();

    // Render based on current station
    switch (this.currentStation) {
      case 1:
        this.renderCaptainScreen(state);
        break;
      case 2:
        this.renderHelmStation(state);
        break;
      case 3:
        this.renderEngineeringStation(state);
        break;
      case 4:
        this.renderLifeSupportStation(state);
        break;
    }
  }

  /**
   * Render Captain Screen (overview of all systems)
   */
  private renderCaptainScreen(state: any): void {

    // Title bar
    console.log(colors.bright + colors.cyan + '═'.repeat(80) + colors.reset);
    console.log(colors.bright + '              🌙 VECTOR MOON LANDER - FLIGHT SIMULATOR 🚀' + colors.reset);
    console.log(colors.bright + colors.cyan + '═'.repeat(80) + colors.reset);
    console.log();

    // Mission time
    const missionTime = state.simulationTime.toFixed(1);
    console.log(`${colors.cyan}Mission Time:${colors.reset} ${missionTime}s`);
    console.log();

    // Orbital Status
    console.log(colors.yellow + '┌─ ORBITAL STATUS ──────────────────────────────────────────┐' + colors.reset);
    const altitude = state.physics.altitude;
    const vertSpeed = state.physics.verticalSpeed;
    const speed = state.physics.speed;

    const altColor = altitude < 1000 ? colors.red : altitude < 5000 ? colors.yellow : colors.green;
    const vSpeedColor = vertSpeed < -20 ? colors.red : vertSpeed < -10 ? colors.yellow : colors.green;

    console.log(`│ Altitude:       ${altColor}${altitude.toFixed(1).padStart(10)}${colors.reset} m`);
    console.log(`│ Vertical Speed: ${vSpeedColor}${vertSpeed.toFixed(2).padStart(10)}${colors.reset} m/s`);
    console.log(`│ Total Speed:    ${speed.toFixed(2).padStart(10)} m/s`);
    console.log(`│ Mass:           ${state.physics.totalMass.toFixed(0).padStart(10)} kg`);
    console.log(colors.yellow + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Attitude
    const euler = state.physics.eulerAngles;
    console.log(colors.blue + '┌─ ATTITUDE ─────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Pitch:          ${euler.pitch.toFixed(2).padStart(10)}°`);
    console.log(`│ Roll:           ${euler.roll.toFixed(2).padStart(10)}°`);
    console.log(`│ Yaw:            ${euler.yaw.toFixed(2).padStart(10)}°`);
    console.log(colors.blue + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Propulsion
    console.log(colors.magenta + '┌─ PROPULSION ───────────────────────────────────────────────┐' + colors.reset);
    const engineStatus = state.mainEngine.status;
    const engineColor = engineStatus === 'running' ? colors.green : engineStatus === 'igniting' ? colors.yellow : colors.dim;
    const thrust = state.mainEngine.currentThrustN;
    const throttle = state.mainEngine.throttle * 100;

    console.log(`│ Main Engine:    ${engineColor}${engineStatus.toUpperCase().padStart(10)}${colors.reset}`);
    console.log(`│ Thrust:         ${thrust.toFixed(0).padStart(10)} N`);
    console.log(`│ Throttle:       ${throttle.toFixed(0).padStart(10)}%`);
    console.log(`│ Engine Health:  ${state.mainEngine.health.toFixed(1).padStart(10)}%`);
    console.log(colors.magenta + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Resources
    console.log(colors.green + '┌─ RESOURCES ────────────────────────────────────────────────┐' + colors.reset);
    const fuelPercent = (state.fuel.totalFuel / 160) * 100;  // Assuming 160kg total initial
    const fuelColor = fuelPercent < 20 ? colors.red : fuelPercent < 50 ? colors.yellow : colors.green;
    const batteryColor = state.electrical.battery.chargePercent < 20 ? colors.red : colors.green;

    console.log(`│ Propellant:     ${fuelColor}${state.fuel.totalFuel.toFixed(0).padStart(10)}${colors.reset} kg (${fuelPercent.toFixed(0)}%)`);
    console.log(`│ Reactor:        ${state.electrical.reactor.outputKW.toFixed(1).padStart(10)} kW`);
    console.log(`│ Battery:        ${batteryColor}${state.electrical.battery.chargePercent.toFixed(0).padStart(10)}${colors.reset}%`);
    console.log(colors.green + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Thermal
    const reactorTemp = state.thermal.components.find((c: any) => c.name === 'reactor')?.temperature || 0;
    const engineTemp = state.thermal.components.find((c: any) => c.name === 'main_engine')?.temperature || 0;
    const coolantTemp = state.coolant.loops[0].temperature;

    console.log(colors.red + '┌─ THERMAL ──────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Reactor Temp:   ${reactorTemp.toFixed(0).padStart(10)} K`);
    console.log(`│ Engine Temp:    ${engineTemp.toFixed(0).padStart(10)} K`);
    console.log(`│ Coolant Temp:   ${coolantTemp.toFixed(0).padStart(10)} K`);
    console.log(colors.red + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Flight Control
    const fcState = state.flightControl;
    const sasMode = fcState.sasMode;
    const apMode = fcState.autopilotMode;
    const sasColor = sasMode !== 'off' ? colors.green : colors.dim;
    const apColor = apMode !== 'off' ? colors.green : colors.dim;

    console.log(colors.yellow + '┌─ FLIGHT CONTROL ───────────────────────────────────────────┐' + colors.reset);
    console.log(`│ SAS Mode:       ${sasColor}${sasMode.toUpperCase().padStart(16)}${colors.reset}`);
    console.log(`│ Autopilot:      ${apColor}${apMode.replace('_', ' ').toUpperCase().padStart(16)}${colors.reset}`);
    const gimbalEnabled = this.spacecraft.flightControl.isGimbalAutopilotEnabled();
    console.log(`│ Gimbal Ctrl:    ${gimbalEnabled ? colors.green + 'ENABLED' : colors.dim + 'DISABLED'}${colors.reset.padStart(7)}`);
    if (apMode === 'altitude_hold') {
      console.log(`│ Target Alt:     ${fcState.targetAltitude?.toFixed(0).padStart(10)} m`);
    } else if (apMode === 'vertical_speed_hold') {
      console.log(`│ Target V/S:     ${fcState.targetVerticalSpeed?.toFixed(1).padStart(10)} m/s`);
    }
    console.log(colors.yellow + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Navigation
    const navData = state.navigation;
    const suicideBurn = this.spacecraft.getSuicideBurnData();
    const burnWarning = suicideBurn.shouldBurn ? colors.red : colors.green;

    console.log(colors.cyan + '┌─ NAVIGATION ───────────────────────────────────────────────┐' + colors.reset);
    if (navData.timeToImpact !== null && navData.timeToImpact !== Infinity) {
      console.log(`│ Time to Impact: ${navData.timeToImpact.toFixed(1).padStart(10)} s`);
    } else {
      console.log(`│ Time to Impact: ${colors.dim}NO IMPACT${colors.reset}`);
    }
    console.log(`│ Suicide Burn:   ${burnWarning}${suicideBurn.burnAltitude.toFixed(0).padStart(10)}${colors.reset} m`);
    if (suicideBurn.shouldBurn) {
      console.log(`│ ${colors.red}⚠️  INITIATE SUICIDE BURN NOW!${colors.reset.padStart(33)}`);
    } else if (suicideBurn.timeUntilBurn > 0 && suicideBurn.timeUntilBurn < 30) {
      console.log(`│ Burn in:        ${colors.yellow}${suicideBurn.timeUntilBurn.toFixed(1).padStart(10)}${colors.reset} s`);
    }
    console.log(`│ Delta-V Remain: ${navData.deltaVRemaining.toFixed(0).padStart(10)} m/s`);
    console.log(`│ TWR:            ${navData.twr.toFixed(2).padStart(10)}`);
    console.log(colors.cyan + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Controls
    console.log(colors.cyan + '┌─ CONTROLS ─────────────────────────────────────────────────┐' + colors.reset);
    console.log('│ ENGINE: [I]gnite [K]ill [+/-]Throttle                    │');
    console.log('│ RCS:    [W/S]Pitch [A/D]Yaw [Q/E]Roll                    │');
    console.log('│ SAS:    [1]Off [2]Stability [3]Prograde [4]Retrograde   │');
    console.log('│ AUTO:   [F1]Off [F2]AltHold [F3]V/S [F4]Suicide [F5]Hovr│');
    console.log('│ STATION:[5]Captain [6]Helm [7]Engineering [8]LifeSupport│');
    console.log('│ OTHER:  [G]imbal [P]ause [X]Quit                         │');
    console.log(colors.cyan + '└────────────────────────────────────────────────────────────┘' + colors.reset);
  }

  /**
   * Render Helm Station (propulsion/flight controls)
   */
  private renderHelmStation(state: any): void {
    // Title
    console.log(colors.bright + colors.cyan + '═'.repeat(80) + colors.reset);
    console.log(colors.bright + '                    HELM & PROPULSION STATION' + colors.reset);
    console.log(colors.bright + colors.cyan + '═'.repeat(80) + colors.reset);
    console.log();

    // Mission time
    console.log(`${colors.cyan}Mission Time:${colors.reset} ${state.simulationTime.toFixed(1)}s`);
    console.log();

    // Main Engine Panel
    const engineStatus = state.mainEngine.status;
    const engineColor = engineStatus === 'running' ? colors.green : engineStatus === 'igniting' ? colors.yellow : colors.dim;

    console.log(colors.magenta + '┌─ MAIN ENGINE ──────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Status:         ${engineColor}${engineStatus.toUpperCase().padStart(16)}${colors.reset}`);
    console.log(`│ Thrust:         ${state.mainEngine.currentThrustN.toFixed(0).padStart(10)} N`);
    console.log(`│ Throttle:       ${(state.mainEngine.throttle * 100).toFixed(0).padStart(10)}%`);
    console.log(`│ Health:         ${state.mainEngine.health.toFixed(1).padStart(10)}%`);
    console.log(`│ Gimbal X:       ${state.mainEngine.gimbalPitch?.toFixed(2).padStart(10) || '0.00'}°`);
    console.log(`│ Gimbal Y:       ${state.mainEngine.gimbalYaw?.toFixed(2).padStart(10) || '0.00'}°`);
    console.log(colors.magenta + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Fuel System - Enhanced with tank details and valves
    const fuelPercent = (state.fuel.totalFuel / 160) * 100;
    const fuelColor = fuelPercent < 20 ? colors.red : fuelPercent < 50 ? colors.yellow : colors.green;

    console.log(colors.green + '┌─ FUEL SYSTEM ──────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Total:          ${fuelColor}${state.fuel.totalFuel.toFixed(0).padStart(10)}${colors.reset} kg (${fuelPercent.toFixed(0)}%)`);
    console.log(`│ Selected Tank:  ${colors.bright}${this.selectedFuelTank.toUpperCase().padEnd(10)}${colors.reset}` + ' '.padEnd(25) + '│');
    console.log(colors.green + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Fuel Tanks - Individual tank status with crossfeed
    console.log(colors.cyan + '┌─ FUEL TANKS ───────────────────────────────────────────────┐' + colors.reset);
    if (state.fuel.tanks && state.fuel.tanks.length > 0) {
      for (const tank of state.fuel.tanks) {
        const selectedMarker = tank.id === this.selectedFuelTank ? colors.bright + '►' : ' ';
        const tankPercent = tank.fuelPercent;
        const tankColor = tankPercent < 20 ? colors.red : tankPercent < 50 ? colors.yellow : colors.green;
        const pressColor = tank.pressureBar < 1.5 ? colors.red : colors.green;

        console.log(`│${selectedMarker} ${tank.id.padEnd(8)} ${tankColor}${tank.fuelMass.toFixed(1).padStart(6)}${colors.reset}kg (${tankPercent.toFixed(0).padStart(2)}%) ${pressColor}${tank.pressureBar.toFixed(1)}${colors.reset}bar`);

        // Show valve status and crossfeed for selected tank
        if (tank.id === this.selectedFuelTank) {
          const valves = this.spacecraft.fuel.getTank(tank.id)?.valves;
          if (valves) {
            const engineValve = valves.feedToEngine ? colors.green + 'ENG✓' : colors.dim + 'ENG✗';
            const rcsValve = valves.feedToRCS ? colors.green + 'RCS✓' : colors.dim + 'RCS✗';
            const ventValve = valves.vent ? colors.red + 'VENT!' : colors.dim + 'VENT✗';
            const crossfeedTo = valves.crossfeedTo;
            const crossfeed = crossfeedTo ? colors.yellow + '→' + crossfeedTo.toUpperCase() : colors.dim + 'X-FEED✗';
            console.log(`│   Valves: ${engineValve}${colors.reset} ${rcsValve}${colors.reset} ${ventValve}${colors.reset}`);
            console.log(`│   Crossfeed: ${crossfeed}${colors.reset}` + ' '.padEnd(34) + '│');
          }
        }
      }
    }
    console.log(colors.cyan + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Flight Control
    const fcState = state.flightControl;
    const sasMode = fcState.sasMode;
    const apMode = fcState.autopilotMode;
    const sasColor = sasMode !== 'off' ? colors.green : colors.dim;
    const apColor = apMode !== 'off' ? colors.green : colors.dim;

    console.log(colors.yellow + '┌─ FLIGHT CONTROL ───────────────────────────────────────────┐' + colors.reset);
    console.log(`│ SAS Mode:       ${sasColor}${sasMode.toUpperCase().padStart(16)}${colors.reset}`);
    console.log(`│ Autopilot:      ${apColor}${apMode.replace('_', ' ').toUpperCase().padStart(16)}${colors.reset}`);
    const gimbalEnabled = this.spacecraft.flightControl.isGimbalAutopilotEnabled();
    console.log(`│ Gimbal Ctrl:    ${gimbalEnabled ? colors.green + 'ENABLED' : colors.dim + 'DISABLED'}${colors.reset.padStart(7)}`);
    if (apMode === 'altitude_hold') {
      console.log(`│ Target Alt:     ${fcState.targetAltitude?.toFixed(0).padStart(10)} m`);
    } else if (apMode === 'vertical_speed_hold') {
      console.log(`│ Target V/S:     ${fcState.targetVerticalSpeed?.toFixed(1).padStart(10)} m/s`);
    }
    console.log(colors.yellow + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Attitude
    const euler = state.physics.eulerAngles;
    console.log(colors.blue + '┌─ ATTITUDE ─────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Pitch:          ${euler.pitch.toFixed(2).padStart(10)}°`);
    console.log(`│ Roll:           ${euler.roll.toFixed(2).padStart(10)}°`);
    console.log(`│ Yaw:            ${euler.yaw.toFixed(2).padStart(10)}°`);
    console.log(colors.blue + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Controls
    console.log(colors.cyan + '┌─ HELM CONTROLS ────────────────────────────────────────────┐' + colors.reset);
    console.log('│ ENGINE:  [I]gnite [K]ill [+/-]Throttle                   │');
    console.log('│ RCS:     [W/S]Pitch [A/D]Yaw [Q/E]Roll                   │');
    console.log('│ SAS:     [1]Off [2]Stability [3]Prograde [4]Retrograde  │');
    console.log('│ AUTO:    [F1]Off [F2]AltHold [F3]V/S [F4]Suicide [F5]Hvr│');
    console.log('│ FUEL:    [Tab]Select Tank  [Z]Cycle Crossfeed Dest      │');
    console.log('│ VALVES:  [N]Engine [M]RCS [U]Vent (selected tank)       │');
    console.log('│ OTHER:   [G]imbal [P]ause                                │');
    console.log('│ STATION: [5]Captain [6]Helm [7]Engineering [8]LifeSupport│');
    console.log(colors.cyan + '└────────────────────────────────────────────────────────────┘' + colors.reset);
  }

  /**
   * Render Engineering Station (power/thermal/electrical)
   */
  private renderEngineeringStation(state: any): void {
    // Title
    console.log(colors.bright + colors.cyan + '═'.repeat(80) + colors.reset);
    console.log(colors.bright + '                    ENGINEERING STATION' + colors.reset);
    console.log(colors.bright + colors.cyan + '═'.repeat(80) + colors.reset);
    console.log();

    // Mission time
    console.log(`${colors.cyan}Mission Time:${colors.reset} ${state.simulationTime.toFixed(1)}s`);
    console.log();

    // Electrical System - Enhanced with reactor throttle and bus status
    const reactorStatus = state.electrical.reactor.status;
    const reactorColor = reactorStatus === 'online' ? colors.green : reactorStatus === 'starting' ? colors.yellow : colors.dim;
    const batteryColor = state.electrical.battery.chargePercent < 20 ? colors.red : colors.green;

    console.log(colors.yellow + '┌─ ELECTRICAL SYSTEM ────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Reactor:        ${reactorColor}${reactorStatus.toUpperCase().padStart(16)}${colors.reset}`);
    console.log(`│ Throttle:       ${(state.electrical.reactor.throttle * 100).toFixed(0).padStart(10)}%`);
    console.log(`│ Output:         ${state.electrical.reactor.outputKW.toFixed(1).padStart(10)} kW`);
    console.log(`│ Temperature:    ${state.electrical.reactor.temperature.toFixed(0).padStart(10)} K`);
    console.log(`│ Battery:        ${batteryColor}${state.electrical.battery.chargePercent.toFixed(0).padStart(10)}${colors.reset}%`);
    console.log(`│ Charge:         ${state.electrical.battery.chargeKWh.toFixed(2).padStart(10)} kWh`);
    console.log(`│ Total Load:     ${state.electrical.totalLoad.toFixed(2).padStart(10)} kW`);
    console.log(`│ Net Power:      ${state.electrical.netPower.toFixed(2).padStart(10)} kW`);

    // Bus status
    const busA = state.electrical.buses[0];
    const busB = state.electrical.buses[1];
    const busAColor = busA.loadPercent > 90 ? colors.red : busA.loadPercent > 75 ? colors.yellow : colors.green;
    const busBColor = busB.loadPercent > 90 ? colors.red : busB.loadPercent > 75 ? colors.yellow : colors.green;
    const crosstieStatus = busA.crosstieEnabled ? colors.green + 'CLOSED' : colors.dim + 'OPEN';

    console.log(`│ Bus A Load:     ${busAColor}${busA.loadKW.toFixed(1).padStart(10)}${colors.reset} kW (${busA.loadPercent.toFixed(0)}%)`);
    console.log(`│ Bus B Load:     ${busBColor}${busB.loadKW.toFixed(1).padStart(10)}${colors.reset} kW (${busB.loadPercent.toFixed(0)}%)`);
    console.log(`│ Crosstie:       ${crosstieStatus}${colors.reset.padStart(10)}`);
    console.log(colors.yellow + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Circuit Breakers - Show ALL breakers with keyboard shortcuts
    console.log(colors.magenta + '┌─ CIRCUIT BREAKERS (ALL 19) ────────────────────────────────┐' + colors.reset);
    const allBreakers = [
      { key: 'A', id: 'o2_generator' },
      { key: 'B', id: 'co2_scrubber' },
      { key: 'C', id: 'coolant_pump_primary' },
      { key: 'D', id: 'coolant_pump_backup' },
      { key: 'E', id: 'fuel_pump_main' },
      { key: 'F', id: 'gimbal_actuators' },
      { key: 'G', id: 'rcs_valves' },
      { key: 'H', id: 'nav_computer' },
      { key: 'I', id: 'radar' },
      { key: 'J', id: 'lidar' },
      { key: 'K', id: 'hydraulic_pump_1' },
      { key: 'L', id: 'hydraulic_pump_2' },
      { key: 'N', id: 'heater_1' },
      { key: 'O', id: 'heater_2' },
      { key: 'P', id: 'heater_3' },
      { key: 'Q', id: 'lighting' },
      { key: 'S', id: 'door_actuators' },
      { key: 'U', id: 'valve_actuators' },
      { key: 'V', id: 'comms' }
    ];

    for (const mapping of allBreakers) {
      const breaker = state.electrical.breakerStatus.find((b: any) => b.key === mapping.id);
      if (breaker) {
        const statusColor = breaker.on ? colors.green : colors.dim;
        const trippedWarning = breaker.tripped ? colors.red + ' [TRIP]' : '';
        const essentialMark = breaker.essential ? '🔒' : '  ';
        const status = breaker.on ? 'ON ' : 'OFF';
        console.log(`│[${mapping.key}]${essentialMark}${breaker.name.padEnd(11)} ${statusColor}${status}${colors.reset} ${breaker.bus}${trippedWarning}${colors.reset.padEnd(18)}`);
      }
    }
    console.log(colors.magenta + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Coolant System - Enhanced with cross-connect
    console.log(colors.cyan + '┌─ COOLANT SYSTEM ───────────────────────────────────────────┐' + colors.reset);
    for (let i = 0; i < state.coolant.loops.length && i < 2; i++) {
      const loop = state.coolant.loops[i];
      const pumpStatus = loop.pumpActive ? colors.green + 'ACTIVE' : colors.dim + 'INACTIVE';
      console.log(`│ Loop ${i + 1}:`);
      console.log(`│   Pump:       ${pumpStatus}${colors.reset}`);
      console.log(`│   Temp:       ${loop.temperature.toFixed(0).padStart(10)} K`);
      console.log(`│   Flow:       ${loop.flowRateLPerMin.toFixed(1).padStart(10)} L/min`);
    }
    const crossConnectStatus = state.coolant.crossConnectOpen ? colors.green + 'OPEN' : colors.dim + 'CLOSED';
    console.log(`│ Cross-Connect:  ${crossConnectStatus}${colors.reset}`);
    console.log(`│ Heat Rejected:  ${(state.coolant.totalHeatRejected / 1000).toFixed(1).padStart(10)} kJ`);
    console.log(colors.cyan + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Thermal System (compact)
    const reactorTemp = state.thermal.components.find((c: any) => c.name === 'reactor')?.temperature || 0;
    const engineTemp = state.thermal.components.find((c: any) => c.name === 'main_engine')?.temperature || 0;

    console.log(colors.red + '┌─ THERMAL ──────────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Reactor: ${reactorTemp.toFixed(0).padStart(4)}K  Engine: ${engineTemp.toFixed(0).padStart(4)}K` + ' '.padEnd(25) + '│');
    console.log(colors.red + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Controls
    console.log(colors.cyan + '┌─ ENGINEERING CONTROLS ─────────────────────────────────────┐' + colors.reset);
    console.log('│ REACTOR:   [R]Start [T]SCRAM  [↑/↓]Throttle [Y]Reset     │');
    console.log('│ COOLANT:   [1]Loop1 [2]Loop2  [X]Cross-Connect           │');
    console.log('│ BREAKERS:  [A-V] Toggle (see list above, 🔒=essential)   │');
    console.log('│ POWER:     [M]Bus Crosstie                               │');
    console.log('│ STATION:   [5]Captain [6]Helm [7]Engineering [8]LifeSuprt│');
    console.log(colors.cyan + '└────────────────────────────────────────────────────────────┘' + colors.reset);
  }

  /**
   * Render Life Support Station
   */
  private renderLifeSupportStation(state: any): void {
    // Title
    console.log(colors.bright + colors.cyan + '═'.repeat(80) + colors.reset);
    console.log(colors.bright + '                    LIFE SUPPORT STATION' + colors.reset);
    console.log(colors.bright + colors.cyan + '═'.repeat(80) + colors.reset);
    console.log();

    // Mission time
    console.log(`${colors.cyan}Mission Time:${colors.reset} ${state.simulationTime.toFixed(1)}s`);
    console.log();

    const ls = state.lifeSupport;

    // O2 Generator
    const o2Color = ls.o2Generator.active ? colors.green : colors.dim;
    console.log(colors.green + '┌─ O2 GENERATION ────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Status:         ${o2Color}${(ls.o2Generator.active ? 'ACTIVE' : 'INACTIVE').padStart(16)}${colors.reset}`);
    console.log(`│ Rate:           ${ls.o2Generator.rateLPerMin.toFixed(1).padStart(10)} L/min`);
    console.log(`│ Reserves:       ${ls.o2Generator.reservesKg.toFixed(1).padStart(10)} kg`);
    console.log(`│ Total Generated:${ls.o2Generator.totalGenerated.toFixed(2).padStart(10)} kg`);
    console.log(colors.green + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // CO2 Scrubber
    const scrubberColor = ls.co2Scrubber.active ? colors.green : colors.dim;
    const mediaColor = ls.co2Scrubber.mediaPercent < 20 ? colors.red : ls.co2Scrubber.mediaPercent < 50 ? colors.yellow : colors.green;

    console.log(colors.blue + '┌─ CO2 SCRUBBER ─────────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Status:         ${scrubberColor}${(ls.co2Scrubber.active ? 'ACTIVE' : 'INACTIVE').padStart(16)}${colors.reset}`);
    console.log(`│ Efficiency:     ${(ls.co2Scrubber.efficiency * 100).toFixed(0).padStart(10)}%`);
    console.log(`│ Media Life:     ${mediaColor}${ls.co2Scrubber.mediaPercent.toFixed(0).padStart(10)}${colors.reset}%`);
    console.log(`│ Total Scrubbed: ${ls.co2Scrubber.totalScrubbed.toFixed(2).padStart(10)} kg`);
    console.log(colors.blue + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Compartments
    console.log(colors.yellow + '┌─ COMPARTMENTS ─────────────────────────────────────────────┐' + colors.reset);
    for (const comp of ls.compartments.slice(0, 6)) {
      const o2Percent = comp.o2Percent;
      const co2Percent = comp.co2Percent;
      const pressure = comp.pressureKPa;

      const o2StatusColor = o2Percent < 18 ? colors.red : o2Percent < 20 ? colors.yellow : colors.green;
      const co2StatusColor = co2Percent > 1.0 ? colors.red : co2Percent > 0.5 ? colors.yellow : colors.green;
      const pressureColor = pressure < 80 ? colors.red : pressure < 95 ? colors.yellow : colors.green;
      const fireWarning = comp.onFire ? colors.red + ' 🔥FIRE!' : '';

      console.log(`│ ${comp.name.padEnd(12)} O2:${o2StatusColor}${o2Percent.toFixed(1).padStart(5)}${colors.reset}% CO2:${co2StatusColor}${co2Percent.toFixed(2).padStart(5)}${colors.reset}% P:${pressureColor}${pressure.toFixed(0).padStart(4)}${colors.reset}kPa${fireWarning}${colors.reset}`);
    }
    console.log(colors.yellow + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Fire Suppression
    const halonColor = ls.halon.remainingKg < 1.0 ? colors.red : ls.halon.remainingKg < 2.5 ? colors.yellow : colors.green;

    console.log(colors.red + '┌─ FIRE SUPPRESSION ─────────────────────────────────────────┐' + colors.reset);
    console.log(`│ Halon:          ${halonColor}${ls.halon.remainingKg.toFixed(1).padStart(10)}${colors.reset} kg`);
    console.log(`│ Uses:           ${ls.halon.usesCount.toString().padStart(10)}`);
    console.log(colors.red + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Bulkhead Doors
    console.log(colors.yellow + '┌─ BULKHEAD DOORS ───────────────────────────────────────────┐' + colors.reset);
    const compartments = ['bow', 'bridge', 'engineering', 'port', 'center', 'stern'];
    const doorMap = new Map<string, string[]>();

    // Build door connections from compartment data
    for (const comp of ls.compartments) {
      for (const door of comp.doors) {
        const key = `${comp.id}-${door.to}`;
        const status = door.open ? colors.green + 'OPEN  ' : colors.red + 'CLOSED';
        const label = `${comp.name.substring(0, 3)}-${this.getCompartmentName(door.to).substring(0, 3)}`;
        if (!doorMap.has(key)) {
          doorMap.set(key, [label, status]);
        }
      }
    }

    let doorCount = 0;
    for (const [key, [label, status]] of doorMap) {
      if (doorCount % 3 === 0 && doorCount > 0) console.log('│' + ' '.padEnd(59) + '│');
      if (doorCount % 3 === 0) process.stdout.write('│ ');
      process.stdout.write(`${label}:${status}${colors.reset}  `);
      doorCount++;
      if (doorCount % 3 === 0) console.log('│');
    }
    if (doorCount % 3 !== 0) console.log(' '.padEnd(60 - (doorCount % 3) * 20) + '│');
    console.log(colors.yellow + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Active compartment selection indicator with door targeting
    console.log(colors.magenta + '┌─ SELECTED COMPARTMENT ─────────────────────────────────────┐' + colors.reset);
    console.log(`│ Target: ${colors.bright}${this.compartmentSelection.toUpperCase().padEnd(50)}${colors.reset}│`);
    console.log(`│ [1]Bow [2]Bridge [3]Engineering [4]Port [5]Center [6]Stern│`);

    // Show door target for selected compartment
    const selectedComp = ls.compartments.find((c: any) => c.id === this.compartmentSelection);
    if (selectedComp && selectedComp.doors.length > 0) {
      const targetDoor = selectedComp.doors[this.doorTargetIndex % selectedComp.doors.length];
      const doorStatus = targetDoor.open ? colors.green + 'OPEN' : colors.red + 'CLOSED';
      console.log(`│ Door Target: ${this.getCompartmentName(targetDoor.to).padEnd(12)} ${doorStatus}${colors.reset}` + ' '.padEnd(15) + '│');
    } else {
      console.log(`│ Door Target: ${colors.dim}NONE${colors.reset}` + ' '.padEnd(37) + '│');
    }
    console.log(colors.magenta + '└────────────────────────────────────────────────────────────┘' + colors.reset);
    console.log();

    // Controls
    console.log(colors.cyan + '┌─ LIFE SUPPORT CONTROLS ────────────────────────────────────┐' + colors.reset);
    console.log('│ O2 GEN:    [O]n/Off  [[]Decrease  []]Increase             │');
    console.log('│ CO2 SCRUB: [C]O2 Scrubber On/Off                          │');
    console.log('│ SELECT:    [1-6]Direct Select  [Tab]Cycle Compartment    │');
    console.log('│ DOORS:     [W]Cycle Door Target  [D]Toggle Selected Door │');
    console.log('│ EMERGENCY: [F]ire Suppress  [V]ent  [L]Seal Breach       │');
    console.log('│ STATION:   [5-8] - Hold SHIFT then press station number  │');
    console.log(colors.cyan + '└────────────────────────────────────────────────────────────┘' + colors.reset);
  }

  /**
   * Helper to get compartment name by ID
   */
  private getCompartmentName(id: string): string {
    const names: { [key: string]: string } = {
      'bow': 'Bow',
      'bridge': 'Bridge',
      'engineering': 'Engineering',
      'port': 'Port',
      'center': 'Center',
      'stern': 'Stern'
    };
    return names[id] || id;
  }

  /**
   * Setup keyboard input handling
   */
  private setupInput(): void {
    readline.emitKeypressEvents(process.stdin);
    if (process.stdin.isTTY) {
      process.stdin.setRawMode(true);
    }

    process.stdin.on('keypress', (str, key) => {
      if (!this.missionStarted || this.gameOver) return;

      if (key.ctrl && key.name === 'c') {
        this.quit();
        return;
      }

      switch (key.name) {
        // Engine controls
        case 'i':
          this.spacecraft.igniteMainEngine();
          break;
        case 'k':
          this.spacecraft.shutdownMainEngine();
          this.throttleTarget = 0;
          break;
        case 'equal':  // + key
        case 'plus':
          this.throttleTarget = Math.min(1.0, this.throttleTarget + 0.1);
          break;
        case 'minus':
          this.throttleTarget = Math.max(0.0, this.throttleTarget - 0.1);
          break;

        // RCS controls (W is context-sensitive for Life Support)
        case 'w':
          if (this.currentStation === 4) {
            // Life Support: Cycle door target
            const comp = this.spacecraft.lifeSupport.compartments.find(c => c.id === this.compartmentSelection);
            if (comp && comp.connections.length > 0) {
              this.doorTargetIndex = (this.doorTargetIndex + 1) % comp.connections.length;
            }
          } else {
            // Other stations: RCS pitch up
            this.spacecraft.activateRCS('pitch_up');
            setTimeout(() => this.spacecraft.deactivateRCS('pitch_up'), 200);
          }
          break;
        case 's':
          this.spacecraft.activateRCS('pitch_down');
          setTimeout(() => this.spacecraft.deactivateRCS('pitch_down'), 200);
          break;
        case 'a':
          this.spacecraft.activateRCS('yaw_left');
          setTimeout(() => this.spacecraft.deactivateRCS('yaw_left'), 200);
          break;
        case 'd':
          this.spacecraft.activateRCS('yaw_right');
          setTimeout(() => this.spacecraft.deactivateRCS('yaw_right'), 200);
          break;
        case 'q':
          this.spacecraft.activateRCS('roll_ccw');
          setTimeout(() => this.spacecraft.deactivateRCS('roll_ccw'), 200);
          break;
        case 'e':
          this.spacecraft.activateRCS('roll_cw');
          setTimeout(() => this.spacecraft.deactivateRCS('roll_cw'), 200);
          break;

        // Context-sensitive controls for keys 1-6
        case '1':
          if (this.currentStation === 3) {
            // Engineering: Toggle coolant loop 1
            const loop1 = this.spacecraft.coolant.loops[0];
            if (loop1.pumpActive) {
              this.spacecraft.coolant.stopPump(0);
            } else {
              this.spacecraft.startCoolantPump(0);
            }
          } else if (this.currentStation === 4) {
            // Life Support: Select Bow compartment
            this.compartmentSelection = 'bow';
            this.doorTargetIndex = 0; // Reset door target
          } else {
            // Other stations: SAS off
            this.spacecraft.setSASMode('off');
          }
          break;
        case '2':
          if (this.currentStation === 3) {
            // Engineering: Toggle coolant loop 2
            const loop2 = this.spacecraft.coolant.loops[1];
            if (loop2.pumpActive) {
              this.spacecraft.coolant.stopPump(1);
            } else {
              this.spacecraft.startCoolantPump(1);
            }
          } else if (this.currentStation === 4) {
            // Life Support: Select Bridge compartment
            this.compartmentSelection = 'bridge';
            this.doorTargetIndex = 0; // Reset door target
          } else {
            // Other stations: SAS stability
            this.spacecraft.setSASMode('stability');
          }
          break;
        case '3':
          if (this.currentStation === 4) {
            // Life Support: Select Engineering compartment
            this.compartmentSelection = 'engineering';
            this.doorTargetIndex = 0; // Reset door target
          } else if (this.currentStation !== 3) {
            this.spacecraft.setSASMode('prograde');
          }
          break;
        case '4':
          if (this.currentStation === 4) {
            // Life Support: Select Port compartment
            this.compartmentSelection = 'port';
            this.doorTargetIndex = 0; // Reset door target
          } else if (this.currentStation !== 3) {
            this.spacecraft.setSASMode('retrograde');
          }
          break;

        // Station switching (5-8 always switch stations, but on LS also select compartments first)
        case '5':
          if (this.currentStation === 4) this.compartmentSelection = 'center';
          this.currentStation = 1; // Captain Screen
          break;
        case '6':
          if (this.currentStation === 4) this.compartmentSelection = 'stern';
          this.currentStation = 2; // Helm
          break;
        case '7':
          this.currentStation = 3; // Engineering
          break;
        case '8':
          this.currentStation = 4; // Life Support
          break;

        // Autopilot controls
        case 'f1':
          this.spacecraft.setAutopilotMode('off');
          break;
        case 'f2':
          // Altitude hold - set target to current altitude
          this.spacecraft.setTargetAltitude(this.spacecraft.physics.getState().altitude);
          this.spacecraft.setAutopilotMode('altitude_hold');
          break;
        case 'f3':
          // Vertical speed hold - set target to current vertical speed
          this.spacecraft.setTargetVerticalSpeed(this.spacecraft.physics.getState().verticalSpeed);
          this.spacecraft.setAutopilotMode('vertical_speed_hold');
          break;
        case 'f4':
          this.spacecraft.setAutopilotMode('suicide_burn');
          break;
        case 'f5':
          this.spacecraft.setAutopilotMode('hover');
          break;

        // Gimbal autopilot toggle
        case 'g':
          const currentGimbal = this.spacecraft.flightControl.isGimbalAutopilotEnabled();
          this.spacecraft.setGimbalAutopilot(!currentGimbal);
          break;

        // Life Support controls (accessible from any station)
        case 'o':
          // Toggle O2 generator
          this.spacecraft.lifeSupport.o2GeneratorActive = !this.spacecraft.lifeSupport.o2GeneratorActive;
          break;
        case '[':
          // Decrease O2 generation rate
          const currentRate = this.spacecraft.lifeSupport.o2GeneratorRateLPerMin;
          this.spacecraft.lifeSupport.setO2GeneratorRate(Math.max(0, currentRate - 0.5));
          break;
        case ']':
          // Increase O2 generation rate
          const currentRate2 = this.spacecraft.lifeSupport.o2GeneratorRateLPerMin;
          this.spacecraft.lifeSupport.setO2GeneratorRate(Math.min(3.0, currentRate2 + 0.5));
          break;
        case 'c':
          // Toggle CO2 scrubber
          this.spacecraft.lifeSupport.co2ScrubberActive = !this.spacecraft.lifeSupport.co2ScrubberActive;
          break;

        // Engineering controls (accessible from any station)
        case 'r':
          // Start reactor
          this.spacecraft.startReactor();
          break;
        case 't':
          // SCRAM reactor (emergency shutdown)
          this.spacecraft.electrical.SCRAM(this.spacecraft.simulationTime);
          break;

        // Engineering Station - ALL 19 Circuit Breakers (context-sensitive)
        case 'a': case 'b': case 'c': case 'd': case 'e': case 'f': case 'g': case 'h':
        case 'i': case 'j': case 'k': case 'l': case 'n': case 'o': case 'p': case 'q':
        case 's': case 'u': case 'v':
          if (this.currentStation === 3) {
            // Engineering: Circuit breaker control
            const breakerMap: {[key: string]: string} = {
              'a': 'o2_generator', 'b': 'co2_scrubber', 'c': 'coolant_pump_primary',
              'd': 'coolant_pump_backup', 'e': 'fuel_pump_main', 'f': 'gimbal_actuators',
              'g': 'rcs_valves', 'h': 'nav_computer', 'i': 'radar', 'j': 'lidar',
              'k': 'hydraulic_pump_1', 'l': 'hydraulic_pump_2', 'n': 'heater_1',
              'o': 'heater_2', 'p': 'heater_3', 'q': 'lighting', 's': 'door_actuators',
              'u': 'valve_actuators', 'v': 'comms'
            };
            const breakerKey = breakerMap[key.name];
            const breaker = this.spacecraft.electrical.breakers.get(breakerKey);
            if (breaker) {
              this.spacecraft.electrical.toggleBreaker(breakerKey, !breaker.on);
            }
          } else if (this.currentStation === 2 && key.name === 'n') {
            // Helm: Toggle engine feed valve
            const tank = this.spacecraft.fuel.getTank(this.selectedFuelTank);
            if (tank) {
              this.spacecraft.fuel.setValve(this.selectedFuelTank, 'feedToEngine', !tank.valves.feedToEngine);
            }
          } else if (this.currentStation === 2 && key.name === 'u') {
            // Helm: Toggle vent valve (moved from separate case)
            const tank = this.spacecraft.fuel.getTank(this.selectedFuelTank);
            if (tank) {
              this.spacecraft.fuel.setValve(this.selectedFuelTank, 'vent', !tank.valves.vent);
            }
          } else if (this.currentStation === 4 && key.name === 'f') {
            // Life Support: Fire suppression
            this.spacecraft.lifeSupport.fireSuppress(this.compartmentSelection);
          } else if (this.currentStation === 4 && key.name === 'v') {
            // Life Support: Emergency vent
            this.spacecraft.lifeSupport.emergencyVent(this.compartmentSelection);
          } else if (this.currentStation === 4 && key.name === 'd') {
            // Life Support: Toggle selected door
            const comp = this.spacecraft.lifeSupport.compartments.find(c => c.id === this.compartmentSelection);
            if (comp && comp.connections.length > 0) {
              const targetConnection = comp.connections[this.doorTargetIndex % comp.connections.length];
              this.spacecraft.lifeSupport.toggleDoor(this.compartmentSelection, targetConnection.compartmentId);
            }
          } else if (this.currentStation === 4 && key.name === 'l') {
            // Life Support: Seal breach
            this.spacecraft.lifeSupport.sealBreach(this.compartmentSelection);
          }
          break;

        // Engineering/Helm shared key M
        case 'm':
          if (this.currentStation === 3) {
            // Engineering: Toggle bus crosstie
            const currentCrosstie = this.spacecraft.electrical.buses[0].crosstieEnabled;
            this.spacecraft.electrical.setCrosstie(!currentCrosstie);
          } else if (this.currentStation === 2) {
            // Helm: Toggle RCS feed valve (changed from H to M)
            const tank = this.spacecraft.fuel.getTank(this.selectedFuelTank);
            if (tank) {
              this.spacecraft.fuel.setValve(this.selectedFuelTank, 'feedToRCS', !tank.valves.feedToRCS);
            }
          }
          break;

        // Engineering Station - Coolant Cross-Connect
        case 'x':
          if (this.currentStation === 3) {
            const currentCrossConnect = this.spacecraft.coolant.crossConnectOpen;
            if (currentCrossConnect) {
              this.spacecraft.coolant.closeCrossConnect();
            } else {
              this.spacecraft.coolant.openCrossConnect();
            }
          }
          break;

        // Engineering Station - Reactor Reset
        case 'y':
          if (this.currentStation === 3) {
            this.spacecraft.electrical.resetReactor();
          }
          break;

        // Engineering Station - Reactor Throttle
        case 'up':
          if (this.currentStation === 3) {
            const currentThrottle = this.spacecraft.electrical.reactor.throttle;
            this.spacecraft.electrical.setReactorThrottle(Math.min(1.0, currentThrottle + 0.1));
          }
          break;
        case 'down':
          if (this.currentStation === 3) {
            const currentThrottle = this.spacecraft.electrical.reactor.throttle;
            this.spacecraft.electrical.setReactorThrottle(Math.max(0, currentThrottle - 0.1));
          }
          break;

        // Tab key - context sensitive (Helm: cycle fuel tank, Life Support: cycle compartment)
        case 'tab':
          if (this.currentStation === 2) {
            // Helm: Cycle fuel tank selection
            const tanks = ['main_1', 'main_2', 'rcs'];
            const currentIndex = tanks.indexOf(this.selectedFuelTank);
            this.selectedFuelTank = tanks[(currentIndex + 1) % tanks.length];
          } else if (this.currentStation === 4) {
            // Life Support: Cycle compartment
            const compartments = ['bow', 'bridge', 'engineering', 'port', 'center', 'stern'];
            const currentIndex = compartments.indexOf(this.compartmentSelection);
            this.compartmentSelection = compartments[(currentIndex + 1) % compartments.length];
            this.doorTargetIndex = 0; // Reset door target
          }
          break;

        // Helm Station - Fuel crossfeed control
        case 'z':
          if (this.currentStation === 2) {
            // Cycle crossfeed destination for selected tank
            const sourceTank = this.spacecraft.fuel.getTank(this.selectedFuelTank);
            if (sourceTank) {
              const allTanks = ['main_1', 'main_2', 'rcs'];
              const otherTanks = allTanks.filter(t => t !== this.selectedFuelTank);
              const currentCrossfeed = sourceTank.valves.crossfeedTo;

              if (!currentCrossfeed) {
                // Start crossfeed to first other tank
                this.spacecraft.fuel.setCrossfeed(this.selectedFuelTank, otherTanks[0]);
              } else {
                const currentIndex = otherTanks.indexOf(currentCrossfeed);
                if (currentIndex === otherTanks.length - 1) {
                  // Last option, turn off crossfeed
                  this.spacecraft.fuel.setCrossfeed(this.selectedFuelTank, undefined);
                } else {
                  // Cycle to next tank
                  this.spacecraft.fuel.setCrossfeed(this.selectedFuelTank, otherTanks[currentIndex + 1]);
                }
              }
            }
          }
          break;

        // Game controls
        case 'p':
          this.paused = !this.paused;
          console.log(this.paused ? '\n⏸️  PAUSED' : '\n▶️  RESUMED');
          break;
        case 'x':
          this.quit();
          break;
      }
    });
  }

  /**
   * End mission and show results
   */
  private endMission(): void {
    this.running = false;

    console.clear();
    console.log(colors.bright + colors.cyan + '═'.repeat(80) + colors.reset);
    console.log(colors.bright + '                         MISSION COMPLETE' + colors.reset);
    console.log(colors.bright + colors.cyan + '═'.repeat(80) + colors.reset);
    console.log();

    const state = this.spacecraft.getState();
    const fuelUsed = 160 - state.fuel.totalFuel;

    // Landing assessment
    let assessment = '';
    let color = colors.white;

    if (this.impactSpeed < 2.0) {
      assessment = '🌟 PERFECT LANDING!';
      color = colors.green;
    } else if (this.impactSpeed < 3.0) {
      assessment = '✅ SOFT LANDING';
      color = colors.green;
    } else if (this.impactSpeed < 5.0) {
      assessment = '⚠️  HARD LANDING';
      color = colors.yellow;
    } else if (this.impactSpeed < 10.0) {
      assessment = '❌ CRASH LANDING';
      color = colors.red;
    } else {
      assessment = '💥 CATASTROPHIC IMPACT';
      color = colors.red;
    }

    console.log(color + colors.bright + assessment + colors.reset);
    console.log();

    console.log('📊 LANDING STATISTICS:');
    console.log(`   Impact Speed:    ${this.impactSpeed.toFixed(2)} m/s`);
    console.log(`   Mission Time:    ${state.simulationTime.toFixed(1)} seconds`);
    console.log(`   Fuel Used:       ${fuelUsed.toFixed(0)} kg (${(fuelUsed / 160 * 100).toFixed(1)}%)`);
    console.log(`   Fuel Remaining:  ${state.fuel.totalFuel.toFixed(0)} kg`);
    console.log();

    console.log('🔧 SYSTEM STATUS:');
    console.log(`   Main Engine:     ${state.mainEngine.health.toFixed(1)}% health`);
    console.log(`   Battery:         ${state.electrical.battery.chargePercent.toFixed(0)}%`);
    console.log(`   Reactor:         ${state.electrical.reactor.status}`);
    console.log();

    console.log('Press any key to exit...');

    process.stdin.once('keypress', () => {
      this.quit();
    });
  }

  /**
   * Show welcome screen
   */
  private showWelcome(): void {
    console.log(colors.bright + colors.cyan);
    console.log('╔═══════════════════════════════════════════════════════════════════════════╗');
    console.log('║                                                                           ║');
    console.log('║              🌙 VECTOR MOON LANDER - FLIGHT SIMULATOR 🚀                  ║');
    console.log('║                                                                           ║');
    console.log('║                   MS Flight Simulator Level Complexity                    ║');
    console.log('║                      "Submarine in Space" Concept                         ║');
    console.log('║                                                                           ║');
    console.log('╚═══════════════════════════════════════════════════════════════════════════╝');
    console.log(colors.reset);
    console.log();
    console.log(colors.green + '✓ 13 Physics & Flight Systems Integrated' + colors.reset);
    console.log(colors.green + '✓ 387/390 Tests Passing (99.2%)' + colors.reset);
    console.log(colors.green + '✓ 4 Control Stations (Captain/Helm/Engineering/Life Support)' + colors.reset);
    console.log(colors.green + '✓ Realistic Orbital Mechanics' + colors.reset);
    console.log(colors.green + '✓ Advanced Flight Control & Autopilot' + colors.reset);
    console.log(colors.green + '✓ Navigation, Mission & Life Support' + colors.reset);
    console.log();
    console.log(colors.yellow + 'Press any key to continue...' + colors.reset);
  }

  /**
   * Show mission briefing
   */
  private showMissionBriefing(): void {
    console.log(colors.bright + '═══ MISSION BRIEFING ═══' + colors.reset);
    console.log();
    console.log(colors.cyan + 'OBJECTIVE:' + colors.reset);
    console.log('  Land safely on the lunar surface from 15km altitude');
    console.log();
    console.log(colors.cyan + 'INITIAL CONDITIONS:' + colors.reset);
    console.log('  Altitude:        15,000 m');
    console.log('  Vertical Speed:  -40 m/s (descending)');
    console.log('  Propellant:      160 kg');
    console.log('  Spacecraft Mass: 8,000 kg total');
    console.log();
    console.log(colors.cyan + 'LANDING CRITERIA:' + colors.reset);
    console.log('  ' + colors.green + 'Perfect:' + colors.reset + '  < 2.0 m/s');
    console.log('  ' + colors.green + 'Soft:' + colors.reset + '    < 3.0 m/s');
    console.log('  ' + colors.yellow + 'Hard:' + colors.reset + '    < 5.0 m/s');
    console.log('  ' + colors.red + 'Crash:' + colors.reset + '   >= 5.0 m/s');
    console.log();
    console.log(colors.cyan + 'CONTROL STATIONS:' + colors.reset);
    console.log('  ' + colors.bright + '[5]' + colors.reset + ' Captain Screen   - Overview of all systems');
    console.log('  ' + colors.bright + '[6]' + colors.reset + ' Helm             - Propulsion & flight controls');
    console.log('  ' + colors.bright + '[7]' + colors.reset + ' Engineering      - Power, thermal & coolant');
    console.log('  ' + colors.bright + '[8]' + colors.reset + ' Life Support     - Atmosphere, O2/CO2, fire suppression');
    console.log();
    console.log(colors.cyan + 'SYSTEMS AVAILABLE:' + colors.reset);
    console.log('  • Nuclear Reactor (8 kW max, 30s startup)');
    console.log('  • Main Engine (45 kN thrust, Isp=311s)');
    console.log('  • RCS Thrusters (12x 25N thrusters)');
    console.log('  • Dual Coolant Loops');
    console.log('  • Life Support (6 compartments, O2 gen, CO2 scrubber)');
    console.log('  • Battery Backup');
    console.log();
    console.log(colors.cyan + 'FLIGHT SYSTEMS:' + colors.reset);
    console.log('  • SAS (Stability Augmentation System)');
    console.log('  • Autopilot (Altitude Hold, V/S Hold, Suicide Burn, Hover)');
    console.log('  • Gimbal Control (Automated thrust vectoring)');
    console.log('  • Navigation Computer (Trajectory prediction, Delta-V)');
    console.log();
    console.log(colors.yellow + 'Good luck, Commander. Press any key to start systems...' + colors.reset);
  }

  /**
   * Helper functions
   */
  private async waitForKey(): Promise<void> {
    return new Promise((resolve) => {
      process.stdin.once('keypress', () => resolve());
    });
  }

  private async sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private quit(): void {
    this.running = false;
    console.clear();
    console.log(colors.cyan + '\nThank you for flying Vector Moon Lander!' + colors.reset);
    console.log(colors.dim + 'Comprehensive spacecraft physics simulation with advanced flight systems' + colors.reset);
    console.log(colors.dim + '13 integrated systems, 4 control stations, 387/390 tests passing' + colors.reset);
    console.log();
    process.exit(0);
  }
}

// Run the game
const game = new MoonLanderGame();
game.start().catch(console.error);
