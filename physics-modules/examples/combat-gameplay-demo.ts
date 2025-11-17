/**
 * Combat Gameplay Demo
 *
 * Full interactive combat simulator demonstrating:
 * - All weapon systems (kinetic, missiles, energy)
 * - Real-time target tracking and engagement
 * - Multiple UI stations (Weapons, Tactical, Sensors)
 * - Live combat scenarios
 * - Player controls and decision-making
 */

import { Spacecraft } from '../src/spacecraft';
import { KineticWeapon, ProjectileManager } from '../src/kinetic-weapons';
import { MissileLauncherSystem } from '../src/missile-weapons';
import { LaserWeapon, ParticleBeamWeapon } from '../src/energy-weapons';
import { WeaponsControlSystem, TrackedTarget } from '../src/weapons-control';

// ANSI colors
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
const BG_RED = '\x1b[41m';

type Station = 'weapons' | 'tactical' | 'sensors' | 'damage_control';

/**
 * Combat Gameplay Simulator
 */
class CombatGameplay {
  private spacecraft: Spacecraft;
  private weapons: WeaponsControlSystem;
  private currentStation: Station = 'weapons';
  private simulationTime: number = 0;
  private gameRunning: boolean = true;
  private selectedWeaponIndex: number = 0;
  private selectedTargetIndex: number = 0;

  constructor() {
    // Initialize spacecraft
    this.spacecraft = new Spacecraft({});

    // Initialize weapons control
    this.weapons = new WeaponsControlSystem();

    // Add weapons to spacecraft
    this.setupWeapons();

    // Spawn hostile targets
    this.spawnHostiles();

    console.log(`${BRIGHT}${CYAN}═══════════════════════════════════════════════════════════`);
    console.log(`              COMBAT GAMEPLAY SIMULATOR`);
    console.log(`═══════════════════════════════════════════════════════════${RESET}\n`);

    console.log(`${YELLOW}Mission: Defend against incoming hostile forces${RESET}`);
    console.log(`${YELLOW}Objective: Destroy all hostiles before they reach you${RESET}\n`);

    console.log(`${CYAN}Controls:${RESET}`);
    console.log(`  [1-4] Switch Stations: 1=Weapons 2=Tactical 3=Sensors 4=Damage`);
    console.log(`  [W/S] Select Weapon/Target (up/down)`);
    console.log(`  [F] Fire Selected Weapon`);
    console.log(`  [E] Engage Target (auto-track)`);
    console.log(`  [P] Toggle Point Defense`);
    console.log(`  [SPACE] Weapons Safety Toggle`);
    console.log(`  [Q] Quit\n`);

    console.log(`${BRIGHT}${GREEN}Press any key to begin...${RESET}\n`);
  }

  /**
   * Setup weapon systems
   */
  private setupWeapons(): void {
    // Add autocannon (point defense)
    const pdGun = new KineticWeapon({
      id: 'pd_gun_1',
      name: 'PD-20 Autocannon',
      type: 'autocannon',
      caliber: 20,
      rateOfFire: 600,
      maxRange: 5,
      muzzleVelocity: 1500,
      turretConfig: {
        location: { x: 0, y: 2, z: 5 },
        maxAzimuthRate: 60,
        maxElevationRate: 60,
        azimuthMin: -180,
        azimuthMax: 180,
        elevationMin: -30,
        elevationMax: 80
      },
      magazineConfig: {
        capacity: 500
      }
    });
    this.weapons.addKineticWeapon(pdGun);

    // Add railgun
    const railgun = new KineticWeapon({
      id: 'railgun_1',
      name: 'RG-100 Railgun',
      type: 'railgun',
      caliber: 100,
      rateOfFire: 6,
      maxRange: 1000,
      muzzleVelocity: 8000,
      turretConfig: {
        location: { x: 0, y: 0, z: 10 },
        maxAzimuthRate: 20,
        maxElevationRate: 20,
        azimuthMin: -60,
        azimuthMax: 60,
        elevationMin: -15,
        elevationMax: 45
      },
      magazineConfig: {
        capacity: 30
      }
    });
    this.weapons.addKineticWeapon(railgun);

    // Add missile launcher
    const missileLauncher = new MissileLauncherSystem({
      id: 'vls_1',
      type: 'VLS',
      capacity: 8,
      missileType: 'MRM',
      reloadTime: 30
    });
    this.weapons.addMissileLauncher(missileLauncher);

    // Add pulse laser
    const laser = new LaserWeapon({
      id: 'laser_1',
      name: 'PL-5 Pulse Laser',
      type: 'pulse_laser',
      peakPower: 5000000, // 5 MW
      wavelength: 'IR',
      apertureDiameter: 0.5
    });
    this.weapons.addLaserWeapon(laser);

    // Add particle beam
    const particleBeam = new ParticleBeamWeapon({
      id: 'pbeam_1',
      name: 'NPB-50 Neutral Particle Beam',
      type: 'neutral',
      particleEnergy: 50,
      beamCurrent: 100
    });
    this.weapons.addParticleBeam(particleBeam);
  }

  /**
   * Spawn hostile targets
   */
  private spawnHostiles(): void {
    // Hostile spacecraft
    const hostile1: TrackedTarget = {
      id: 'hostile_1',
      type: 'spacecraft',
      position: { x: 50, y: 10, z: 20 },
      velocity: { x: -500, y: 0, z: -200 }, // Approaching
      radius: 20,
      threat: 'high',
      health: 1.0,
      hostile: true,
      locked: false,
      timeToIntercept: null,
      inRange: { kinetic: false, missile: true, laser: false }
    };
    this.weapons.trackTarget(hostile1);

    // Incoming missiles
    for (let i = 0; i < 3; i++) {
      const missile: TrackedTarget = {
        id: `incoming_missile_${i}`,
        type: 'missile',
        position: { x: 10 + i * 2, y: 5, z: 8 },
        velocity: { x: -2000, y: 0, z: -1000 }, // Fast approach
        radius: 0.5,
        threat: 'critical',
        health: 0.3, // Missiles are fragile
        hostile: true,
        locked: false,
        timeToIntercept: null,
        inRange: { kinetic: true, missile: false, laser: true }
      };
      this.weapons.trackTarget(missile);
    }

    // Distant threat
    const hostile2: TrackedTarget = {
      id: 'hostile_2',
      type: 'spacecraft',
      position: { x: 200, y: -50, z: 100 },
      velocity: { x: -300, y: 50, z: -150 },
      radius: 50,
      threat: 'medium',
      health: 1.0,
      hostile: true,
      locked: false,
      timeToIntercept: null,
      inRange: { kinetic: false, missile: true, laser: false }
    };
    this.weapons.trackTarget(hostile2);
  }

  /**
   * Update game loop
   */
  public update(dt: number): void {
    this.simulationTime += dt;

    // Update spacecraft
    this.spacecraft.update(dt);

    // Update weapons with ship state
    const spacecraftState = this.spacecraft.getState();
    this.weapons.updateShipState(
      spacecraftState.physics.position,
      { x: spacecraftState.physics.velocity.x, y: spacecraftState.physics.velocity.y, z: spacecraftState.physics.velocity.z }
    );

    // Update weapons systems
    this.weapons.update(dt);
  }

  /**
   * Render current station
   */
  public render(): void {
    console.clear();

    // Header
    this.renderHeader();

    // Station content
    switch (this.currentStation) {
      case 'weapons':
        this.renderWeaponsStation();
        break;
      case 'tactical':
        this.renderTacticalStation();
        break;
      case 'sensors':
        this.renderSensorsStation();
        break;
      case 'damage_control':
        this.renderDamageControlStation();
        break;
    }

    // Footer
    this.renderFooter();
  }

  /**
   * Render header
   */
  private renderHeader(): void {
    const weaponsState = this.weapons.getState();
    const threat = weaponsState.threatAssessment;

    console.log(`${BRIGHT}${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${RESET}`);
    console.log(`${BRIGHT}${CYAN}║${RESET}  COMBAT OPERATIONS CENTER  ${DIM}│${RESET} T+${this.simulationTime.toFixed(0)}s  ${BRIGHT}${CYAN}║${RESET}`);
    console.log(`${BRIGHT}${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${RESET}\n`);

    // Status bar
    const safetyColor = weaponsState.weaponsSafety ? GREEN : RED;
    const pdColor = weaponsState.pointDefenseActive ? GREEN : YELLOW;
    const threatColor = threat.criticalThreats > 0 ? RED : (threat.totalHostiles > 0 ? YELLOW : GREEN);

    console.log(`${WHITE}┌─ STATUS ────────────────────────────────────────────────────────────┐${RESET}`);
    console.log(`│ Safety: ${safetyColor}${weaponsState.weaponsSafety ? 'SAFE' : 'ARMED'}${RESET} │ ` +
                `PD: ${pdColor}${weaponsState.pointDefenseActive ? 'AUTO' : 'MANUAL'}${RESET} │ ` +
                `Threats: ${threatColor}${threat.totalHostiles}${RESET} (${BG_RED}${threat.criticalThreats} CRITICAL${RESET}) │`);
    console.log(`│ PWR: ${(weaponsState.powerDraw / 1000).toFixed(1)}kW │ ` +
                `Weapons: K:${threat.weaponsReady.kinetic} M:${threat.weaponsReady.missiles} E:${threat.weaponsReady.energy} │${RESET}`);
    console.log(`${WHITE}└─────────────────────────────────────────────────────────────────────┘${RESET}\n`);
  }

  /**
   * Render weapons station
   */
  private renderWeaponsStation(): void {
    const weaponsState = this.weapons.getState();

    console.log(`${BRIGHT}${GREEN}╔═══ STATION 1: WEAPONS CONTROL ═══════════════════════════════════╗${RESET}\n`);

    // Kinetic weapons
    console.log(`${CYAN}┌─ KINETIC WEAPONS ──────────────────────────────────────┐${RESET}`);
    weaponsState.kineticWeapons.forEach((weapon, idx) => {
      const selected = idx === this.selectedWeaponIndex ? '►' : ' ';
      const statusColor = weapon.status === 'ready' ? GREEN : (weapon.status === 'overheated' ? RED : YELLOW);

      console.log(`${selected} ${weapon.name}`);
      console.log(`  Status: ${statusColor}${weapon.status.toUpperCase()}${RESET} │ ` +
                  `Ammo: ${weapon.totalRounds} │ ` +
                  `Temp: ${this.renderBar(weapon.temperaturePercent, 10, weapon.temperaturePercent > 0.8)}`);
      console.log(`  Turret: Az=${weapon.turret.azimuth.toFixed(1)}° El=${weapon.turret.elevation.toFixed(1)}° │ ` +
                  `${weapon.turret.onTarget ? GREEN + '●TRACKING' + RESET : DIM + '○ SLEWING' + RESET}`);
    });
    console.log(`${CYAN}└────────────────────────────────────────────────────────┘${RESET}\n`);

    // Missiles
    console.log(`${CYAN}┌─ MISSILE SYSTEMS ──────────────────────────────────────┐${RESET}`);
    weaponsState.missileLaunchers.forEach(launcher => {
      console.log(`  ${launcher.launcher.id}: ${launcher.launcher.loaded}/${launcher.launcher.capacity} loaded`);
      if (launcher.launcher.reloading) {
        console.log(`  ${this.renderBar(launcher.launcher.reloadProgress, 20)} Reloading...`);
      }
    });
    console.log(`  Active Missiles: ${weaponsState.missileLaunchers.reduce((sum, l) => sum + l.missiles.length, 0)}`);
    console.log(`${CYAN}└────────────────────────────────────────────────────────┘${RESET}\n`);

    // Energy weapons
    console.log(`${CYAN}┌─ ENERGY WEAPONS ───────────────────────────────────────┐${RESET}`);
    weaponsState.laserWeapons.forEach(laser => {
      const statusColor = laser.ready ? GREEN : YELLOW;
      console.log(`  ${laser.name}: ${statusColor}${laser.status.toUpperCase()}${RESET}`);
      console.log(`    Power: ${laser.peakPower.toFixed(1)}MW │ Range: ${laser.effectiveRange.toFixed(0)}km │ ` +
                  `${this.renderBar(laser.capacitorCharge, 10)} Charge`);
    });

    weaponsState.particleBeams.forEach(beam => {
      const statusColor = beam.ready ? GREEN : YELLOW;
      console.log(`  ${beam.name}: ${statusColor}${beam.status.toUpperCase()}${RESET}`);
      console.log(`    Power: ${beam.power.toFixed(1)}MW │ Energy: ${beam.particleEnergy}MeV │ ` +
                  `${this.renderBar(beam.capacitorCharge, 10)} Charge`);
    });
    console.log(`${CYAN}└────────────────────────────────────────────────────────┘${RESET}\n`);
  }

  /**
   * Render tactical station
   */
  private renderTacticalStation(): void {
    const weaponsState = this.weapons.getState();
    const targets = weaponsState.targets;

    console.log(`${BRIGHT}${BLUE}╔═══ STATION 2: TACTICAL OVERVIEW ═════════════════════════════════╗${RESET}\n`);

    // Radar scope
    console.log(`${CYAN}┌─ TACTICAL DISPLAY ─────────────────────────────────────┐${RESET}`);
    console.log(`│                                                        │`);
    console.log(`│              ${GREEN}●${RESET} = SHIP         ${RED}●${RESET} = HOSTILE         │`);
    console.log(`│              ${YELLOW}○${RESET} = MISSILE      ${BLUE}●${RESET} = FRIENDLY       │`);
    console.log(`│                                                        │`);

    // Simplified radar scope
    console.log(`│                        ${GREEN}●${RESET}                           │`);
    targets.forEach(target => {
      const color = target.threat === 'critical' ? RED : (target.hostile ? YELLOW : BLUE);
      const symbol = target.type === 'missile' ? '○' : '●';
      // Simplified positioning
      const x = 30 + Math.floor(target.position.x / 10);
      const y = 5 + Math.floor(target.position.y / 10);
      if (x >= 0 && x < 60 && y >= 0 && y < 10) {
        console.log(`│  ${' '.repeat(Math.max(0, x))}${color}${symbol}${RESET}${' '.repeat(Math.max(0, 55 - x))}│`);
      }
    });

    console.log(`│                                                        │`);
    console.log(`${CYAN}└────────────────────────────────────────────────────────┘${RESET}\n`);

    // Engagement status
    console.log(`${CYAN}┌─ ACTIVE ENGAGEMENTS ───────────────────────────────────┐${RESET}`);
    if (weaponsState.engagements.length === 0) {
      console.log(`  ${DIM}No active engagements${RESET}`);
    } else {
      weaponsState.engagements.forEach(eng => {
        const target = targets.find(t => t.id === eng.targetId);
        if (target) {
          console.log(`  Target: ${target.id} │ Priority: ${eng.priority} │ Mode: ${eng.mode}`);
          console.log(`    Weapons: ${eng.weaponIds.length} │ Auto-fire: ${eng.autoFire ? 'YES' : 'NO'}`);
        }
      });
    }
    console.log(`${CYAN}└────────────────────────────────────────────────────────┘${RESET}\n`);
  }

  /**
   * Render sensors station
   */
  private renderSensorsStation(): void {
    const weaponsState = this.weapons.getState();
    const targets = weaponsState.targets;

    console.log(`${BRIGHT}${MAGENTA}╔═══ STATION 3: SENSORS & TRACKING ════════════════════════════════╗${RESET}\n`);

    console.log(`${CYAN}┌─ TRACKED CONTACTS ─────────────────────────────────────┐${RESET}`);
    targets.forEach((target, idx) => {
      const selected = idx === this.selectedTargetIndex ? '►' : ' ';
      const threatColor = target.threat === 'critical' ? BG_RED + WHITE :
                          target.threat === 'high' ? RED :
                          target.threat === 'medium' ? YELLOW : GREEN;
      const lockStatus = target.locked ? GREEN + '●LOCKED' : DIM + '○';

      const dx = target.position.x;
      const dy = target.position.y;
      const dz = target.position.z;
      const range = Math.sqrt(dx**2 + dy**2 + dz**2);

      console.log(`${selected} ${target.id}`);
      console.log(`  Type: ${target.type} │ ${threatColor}${target.threat.toUpperCase()}${RESET} │ ${lockStatus}${RESET}`);
      console.log(`  Range: ${range.toFixed(1)}km │ Health: ${this.renderBar(target.health, 10, target.health < 0.3)}`);
      console.log(`  Velocity: ${Math.sqrt(target.velocity.x**2 + target.velocity.y**2 + target.velocity.z**2).toFixed(0)}m/s`);
      if (target.timeToIntercept !== null) {
        console.log(`  ${RED}TIME TO INTERCEPT: ${target.timeToIntercept.toFixed(1)}s${RESET}`);
      }
      console.log(`  In Range: K:${target.inRange.kinetic ? GREEN + 'Y' : RED + 'N'}${RESET} │ ` +
                  `M:${target.inRange.missile ? GREEN + 'Y' : RED + 'N'}${RESET} │ ` +
                  `L:${target.inRange.laser ? GREEN + 'Y' : RED + 'N'}${RESET}`);
      console.log('');
    });
    console.log(`${CYAN}└────────────────────────────────────────────────────────┘${RESET}\n`);
  }

  /**
   * Render damage control station
   */
  private renderDamageControlStation(): void {
    const weaponsState = this.weapons.getState();

    console.log(`${BRIGHT}${YELLOW}╔═══ STATION 4: DAMAGE CONTROL ════════════════════════════════════╗${RESET}\n`);

    console.log(`${CYAN}┌─ WEAPON SYSTEMS STATUS ────────────────────────────────┐${RESET}`);

    // Check weapon damage
    let damageDetected = false;

    weaponsState.kineticWeapons.forEach(weapon => {
      if (weapon.status === 'damaged' || weapon.status === 'jammed') {
        damageDetected = true;
        console.log(`  ${RED}⚠ ${weapon.name}: ${weapon.status.toUpperCase()}${RESET}`);
      }
    });

    weaponsState.laserWeapons.forEach(laser => {
      if (laser.status === 'damaged' || laser.status === 'overheated') {
        damageDetected = true;
        console.log(`  ${RED}⚠ ${laser.name}: ${laser.status.toUpperCase()}${RESET}`);
      }
    });

    if (!damageDetected) {
      console.log(`  ${GREEN}✓ All weapon systems operational${RESET}`);
    }

    console.log(`${CYAN}└────────────────────────────────────────────────────────┘${RESET}\n`);

    // Power status
    console.log(`${CYAN}┌─ POWER DISTRIBUTION ───────────────────────────────────┐${RESET}`);
    console.log(`  Total Draw: ${(weaponsState.powerDraw / 1000).toFixed(1)} kW`);
    console.log(`  ${this.renderBar(weaponsState.powerDraw / 100000, 30, weaponsState.powerDraw > 80000)}`);
    console.log(`${CYAN}└────────────────────────────────────────────────────────┘${RESET}\n`);
  }

  /**
   * Render footer with controls
   */
  private renderFooter(): void {
    console.log(`${WHITE}─────────────────────────────────────────────────────────────────────${RESET}`);

    const stationNames = {
      'weapons': '1:WEAPONS',
      'tactical': '2:TACTICAL',
      'sensors': '3:SENSORS',
      'damage_control': '4:DAMAGE'
    };

    let stationBar = '';
    for (const [key, name] of Object.entries(stationNames)) {
      if (key === this.currentStation) {
        stationBar += `${BRIGHT}${GREEN}[${name}]${RESET} `;
      } else {
        stationBar += `${DIM}${name}${RESET} `;
      }
    }

    console.log(`Stations: ${stationBar}`);
    console.log(`${DIM}W/S:Select │ F:Fire │ E:Engage │ P:PD Toggle │ SPACE:Safety │ Q:Quit${RESET}`);
  }

  /**
   * Render progress bar
   */
  private renderBar(percent: number, length: number = 10, danger: boolean = false): string {
    const filled = Math.floor(percent * length);
    const empty = length - filled;
    const color = danger ? RED : (percent > 0.7 ? YELLOW : GREEN);
    return `${color}${'█'.repeat(filled)}${DIM}${'░'.repeat(empty)}${RESET}`;
  }

  /**
   * Run game loop
   */
  public run(): void {
    // Simulate game loop
    const frameTime = 1.0; // 1 second per frame for demo

    for (let i = 0; i < 60; i++) { // 60 seconds of combat
      this.update(frameTime);
      this.render();

      // Simulate some actions
      if (i === 5) {
        // Enable point defense
        this.weapons.pointDefenseActive = true;
      }

      if (i === 10) {
        // Engage first hostile with missiles
        const targets = this.weapons.getState().targets;
        if (targets.length > 0) {
          this.weapons.weaponsSafety = false;
          this.weapons.engageTarget(targets[0].id, 'missile', 'computer_assisted');
        }
      }

      if (i === 15) {
        // Engage with kinetic
        const targets = this.weapons.getState().targets;
        if (targets.length > 1) {
          this.weapons.engageTarget(targets[1].id, 'kinetic', 'auto_track');
        }
      }

      // Cycle through stations
      if (i % 15 === 0) {
        const stations: Station[] = ['weapons', 'tactical', 'sensors', 'damage_control'];
        this.currentStation = stations[Math.floor(i / 15) % 4];
      }

      // Check victory condition
      const remaining = this.weapons.getState().targets.filter(t => t.hostile).length;
      if (remaining === 0) {
        console.log(`\n${BRIGHT}${GREEN}╔═══════════════════════════════════════════════════════════╗${RESET}`);
        console.log(`${BRIGHT}${GREEN}║              MISSION ACCOMPLISHED!                        ║${RESET}`);
        console.log(`${BRIGHT}${GREEN}║     All hostile contacts destroyed!                       ║${RESET}`);
        console.log(`${BRIGHT}${GREEN}╚═══════════════════════════════════════════════════════════╝${RESET}\n`);
        break;
      }

      // Simulate delay (in real game, would wait for user input)
      // For demo, just continue
    }
  }
}

// Run the demo
const game = new CombatGameplay();
game.run();

console.log(`\n${BRIGHT}${CYAN}Combat gameplay demonstration complete!${RESET}\n`);
console.log(`This demo showcased:`);
console.log(`  ✓ All weapon types (kinetic, missiles, energy)`);
console.log(`  ✓ Real-time target tracking and threat assessment`);
console.log(`  ✓ Automated point defense system`);
console.log(`  ✓ Multiple UI stations with different views`);
console.log(`  ✓ Live combat engagement`);
console.log(`  ✓ Power management integration`);
console.log(`\nFor full interactive gameplay, this would accept keyboard input.${RESET}\n`);
