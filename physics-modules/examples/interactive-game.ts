/**
 * Interactive Lunar Lander Game
 *
 * PLAYABLE game with keyboard controls and real-time display.
 *
 * CONTROLS:
 * - W/S: Main engine throttle up/down
 * - A/D: Rotate left/right
 * - Q/E: Translate left/right (RCS)
 * - G: Toggle landing gear
 * - Space: Fire RCS for stability
 * - ESC: Quit
 */

import * as readline from 'readline';
import { SimpleWorld } from '../src/simple-world';
import { SimpleSpacecraft } from '../src/simple-spacecraft';
import { Vector3 } from '../src/types';

// Enable raw mode for keyboard input
readline.emitKeypressEvents(process.stdin);
if (process.stdin.isTTY) {
  process.stdin.setRawMode(true);
}

interface Controls {
  throttle: number;      // 0-1
  rotationRate: number;  // rad/s
  rcsThrust: Vector3;    // N
  landingGearDeployed: boolean;
}

class InteractiveLunarLander {
  private world: SimpleWorld;
  private spacecraft: SimpleSpacecraft;
  private controls: Controls;
  private simulationTime: number = 0;
  private running: boolean = true;

  // Game constants
  private readonly FPS = 10;
  private readonly dt = 1.0 / this.FPS;
  private readonly MAX_THRUST = 45000; // 45 kN main engine
  private readonly RCS_THRUST = 25;     // 25 N per thruster

  // Display state
  private frameCount: number = 0;

  constructor() {
    // Initialize controls
    this.controls = {
      throttle: 0,
      rotationRate: 0,
      rcsThrust: { x: 0, y: 0, z: 0 },
      landingGearDeployed: true,
    };

    // Create world
    this.world = new SimpleWorld({
      terrainSeed: 42,
      createSatellite: true,
      createWaypoints: true,
    });

    // Create spacecraft at 15km altitude with some horizontal velocity
    this.spacecraft = new SimpleSpacecraft(
      {
        initialPosition: { x: 1737400 + 15000, y: 0, z: 0 },
        initialVelocity: { x: -50, y: 0, z: 0 }, // 50 m/s descent rate
        mass: 23000,
      },
      this.world
    );

    this.setupControls();
    this.clearScreen();
    this.displayWelcome();
  }

  private setupControls(): void {
    process.stdin.on('keypress', (str, key) => {
      if (!key) return;

      // ESC or Ctrl+C to quit
      if (key.name === 'escape' || (key.ctrl && key.name === 'c')) {
        this.running = false;
        return;
      }

      // Throttle control
      if (key.name === 'w') {
        this.controls.throttle = Math.min(1.0, this.controls.throttle + 0.1);
      } else if (key.name === 's') {
        this.controls.throttle = Math.max(0.0, this.controls.throttle - 0.1);
      }

      // Rotation control
      if (key.name === 'a') {
        this.controls.rotationRate = 0.1; // Rotate left
      } else if (key.name === 'd') {
        this.controls.rotationRate = -0.1; // Rotate right
      }

      // RCS translation
      if (key.name === 'q') {
        this.controls.rcsThrust.y = -this.RCS_THRUST * 4; // Translate left
      } else if (key.name === 'e') {
        this.controls.rcsThrust.y = this.RCS_THRUST * 4; // Translate right
      }

      // Landing gear toggle
      if (key.name === 'g') {
        this.controls.landingGearDeployed = !this.controls.landingGearDeployed;
      }

      // Space for RCS stabilization
      if (key.name === 'space') {
        // Apply counter-rotation thrust
        // (simplified - in reality would calculate based on angular velocity)
      }
    });
  }

  private clearScreen(): void {
    process.stdout.write('\x1Bc'); // Clear screen
  }

  private displayWelcome(): void {
    console.log('╔════════════════════════════════════════════════════════════════════════════╗');
    console.log('║               🌙  LUNAR LANDER - INTERACTIVE FLIGHT SIMULATOR  🚀           ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝');
    console.log('');
    console.log('MISSION: Land safely on the lunar surface');
    console.log('');
    console.log('CONTROLS:');
    console.log('  W/S     - Throttle up/down (main engine)');
    console.log('  A/D     - Rotate left/right');
    console.log('  Q/E     - Translate left/right (RCS)');
    console.log('  G       - Toggle landing gear');
    console.log('  ESC     - Quit');
    console.log('');
    console.log('SPACECRAFT: 23 tons | MAX THRUST: 45 kN | FUEL: 8000 kg');
    console.log('STARTING ALTITUDE: 15 km');
    console.log('');
    console.log('Press any key to start...');

    // Wait for keypress to start
    process.stdin.once('keypress', () => {
      this.run();
    });
  }

  run(): void {
    const gameLoop = setInterval(() => {
      if (!this.running) {
        clearInterval(gameLoop);
        this.shutdown();
        return;
      }

      this.update();
      this.render();

      // Check for landing or crash
      if (this.checkEndConditions()) {
        clearInterval(gameLoop);
        this.displayFinalResults();
        this.shutdown();
      }

      this.frameCount++;
      this.simulationTime += this.dt;
    }, 1000 / this.FPS);
  }

  private update(): void {
    // Apply thrust from controls
    const thrust = this.controls.throttle * this.MAX_THRUST;
    const thrustVector: Vector3 = {
      x: thrust, // Thrust in radial direction (upward)
      y: this.controls.rcsThrust.y,
      z: this.controls.rcsThrust.z,
    };

    // Apply thrust as force to spacecraft
    // Convert thrust to acceleration and apply
    const accel = {
      x: thrustVector.x / this.spacecraft.mass,
      y: thrustVector.y / this.spacecraft.mass,
      z: thrustVector.z / this.spacecraft.mass,
    };

    // Update spacecraft velocity before physics update
    this.spacecraft.velocity.x += accel.x * this.dt;
    this.spacecraft.velocity.y += accel.y * this.dt;
    this.spacecraft.velocity.z += accel.z * this.dt;

    // Update world
    this.world.update(this.dt);

    // Update spacecraft (physics, landing gear)
    this.spacecraft.update(this.dt);

    // Reset RCS thrust (needs to be held)
    this.controls.rcsThrust = { x: 0, y: 0, z: 0 };
    this.controls.rotationRate = 0;
  }

  private render(): void {
    // Move cursor to top
    process.stdout.write('\x1B[H');

    const alt = this.spacecraft.getAltitudeAGL();
    const altMSL = this.spacecraft.getAltitudeMSL();
    const vSpeed = this.spacecraft.getVerticalSpeed();
    const hSpeed = this.spacecraft.getHorizontalSpeed();
    const latLon = this.spacecraft.getLatLon();
    const landingGear = this.spacecraft.getLandingGearStatus();

    // Get terrain info
    const terrainElev = this.world.terrain.getElevation(latLon.latitude, latLon.longitude);
    const surfaceNormal = this.world.terrain.getSurfaceNormal(latLon.latitude, latLon.longitude);
    const surfaceConditions = this.world.environment.getSurfaceConditions(
      this.spacecraft.position,
      surfaceNormal
    );

    // Get waypoint
    const wpGuidance = this.world.waypoints.getActiveGuidance(
      this.spacecraft.position,
      this.spacecraft.velocity,
      terrainElev
    );

    // Get satellite
    const satellite = this.world.orbitalBodies.findNearestBody(this.spacecraft.position);
    let satDist = 0;
    if (satellite) {
      const dx = satellite.body.position.x - this.spacecraft.position.x;
      const dy = satellite.body.position.y - this.spacecraft.position.y;
      const dz = satellite.body.position.z - this.spacecraft.position.z;
      satDist = Math.sqrt(dx * dx + dy * dy + dz * dz) / 1000;
    }

    // Header
    console.log('╔════════════════════════════════════════════════════════════════════════════╗');
    console.log(`║  T+${this.simulationTime.toFixed(1).padEnd(8)} | LUNAR LANDER FLIGHT COMPUTER                          ║`);
    console.log('╠════════════════════════════════════════════════════════════════════════════╣');

    // Altitude & Velocity
    console.log('║                                                                            ║');
    console.log(`║  ALTITUDE                                                                  ║`);
    console.log(`║    Above Ground:   ${(alt / 1000).toFixed(3).padStart(8)} km                                   ║`);
    console.log(`║    Mean Sea Level: ${(altMSL / 1000).toFixed(3).padStart(8)} km                                   ║`);
    console.log(`║    Terrain Elev:   ${terrainElev.toFixed(1).padStart(8)} m                                    ║`);
    console.log('║                                                                            ║');
    console.log(`║  VELOCITY                                                                  ║`);
    console.log(`║    Vertical:   ${vSpeed.toFixed(1).padStart(8)} m/s  ${this.getVerticalSpeedBar(vSpeed)}                ║`);
    console.log(`║    Horizontal: ${hSpeed.toFixed(1).padStart(8)} m/s  ${this.getHorizontalSpeedBar(hSpeed)}                ║`);
    console.log('║                                                                            ║');

    // Position
    console.log(`║  POSITION                                                                  ║`);
    console.log(`║    Latitude:  ${latLon.latitude.toFixed(4).padStart(10)}°                                        ║`);
    console.log(`║    Longitude: ${latLon.longitude.toFixed(4).padStart(10)}°                                        ║`);
    console.log('║                                                                            ║');

    // Landing Gear
    const gearStatus = landingGear.deployed ? '✓ DEPLOYED' : '✗ RETRACTED';
    const gearHealth = landingGear.health.totalHealth;
    const gearColor = gearHealth > 75 ? '✓' : gearHealth > 25 ? '!' : '✗';
    console.log(`║  LANDING GEAR: ${gearStatus.padEnd(12)}                                            ║`);
    console.log(`║    Contact: ${landingGear.contact.legsInContact}/4 legs | Stable: ${landingGear.contact.isStable ? 'YES' : 'NO '}                            ║`);
    console.log(`║    Health:  ${gearColor} ${gearHealth.toFixed(0).padStart(3)}%                                                   ║`);
    console.log('║                                                                            ║');

    // Environment
    console.log(`║  ENVIRONMENT                                                               ║`);
    console.log(`║    Surface Temp: ${surfaceConditions.temperature.toFixed(0).padStart(3)} K                                          ║`);
    console.log(`║    Illuminated:  ${surfaceConditions.illuminated ? 'YES' : 'NO '}                                                 ║`);
    console.log('║                                                                            ║');

    // Navigation
    if (wpGuidance) {
      console.log(`║  NAVIGATION                                                                ║`);
      console.log(`║    Waypoint: ${wpGuidance.waypoint.name.padEnd(25)}                          ║`);
      console.log(`║    Distance: ${(wpGuidance.distance / 1000).toFixed(1).padStart(6)} km | Bearing: ${wpGuidance.bearing.toFixed(0).padStart(3)}°                       ║`);
      console.log('║                                                                            ║');
    }

    // Satellite
    console.log(`║  🛰️  SATELLITE: ${satDist.toFixed(1).padStart(6)} km away                                   ║`);
    console.log('║                                                                            ║');

    // Controls
    console.log('╠════════════════════════════════════════════════════════════════════════════╣');
    console.log(`║  THROTTLE: ${(this.controls.throttle * 100).toFixed(0).padStart(3)}% ${this.getThrottleBar(this.controls.throttle)}                                   ║`);
    console.log(`║  THRUST:   ${(this.controls.throttle * this.MAX_THRUST / 1000).toFixed(1).padStart(5)} kN                                                  ║`);
    console.log('╠════════════════════════════════════════════════════════════════════════════╣');
    console.log('║  W/S: Throttle | A/D: Rotate | Q/E: Translate | G: Gear | ESC: Quit       ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝');

    // Add some blank lines to prevent flicker
    console.log('\n\n\n');
  }

  private getThrottleBar(throttle: number): string {
    const barLength = 20;
    const filled = Math.round(throttle * barLength);
    return '[' + '█'.repeat(filled) + '░'.repeat(barLength - filled) + ']';
  }

  private getVerticalSpeedBar(vSpeed: number): string {
    // -50 to +50 m/s range
    const normalized = Math.max(-50, Math.min(50, vSpeed)) / 50; // -1 to 1
    const barLength = 10;
    const center = Math.floor(barLength / 2);

    if (normalized < 0) {
      // Descending
      const filled = Math.round(Math.abs(normalized) * center);
      return '↓' + '▼'.repeat(filled) + '·'.repeat(center - filled);
    } else {
      // Ascending
      const filled = Math.round(normalized * center);
      return '·'.repeat(center - filled) + '▲'.repeat(filled) + '↑';
    }
  }

  private getHorizontalSpeedBar(hSpeed: number): string {
    const barLength = 10;
    const filled = Math.min(barLength, Math.round(hSpeed / 10));
    return '→' + '━'.repeat(filled) + '·'.repeat(barLength - filled);
  }

  private checkEndConditions(): boolean {
    const alt = this.spacecraft.getAltitudeAGL();
    const vSpeed = this.spacecraft.getVerticalSpeed();

    // Landed
    if (this.spacecraft.isLanded() && Math.abs(vSpeed) < 0.5) {
      return true;
    }

    // Crashed
    if (alt < -1.0) {
      return true;
    }

    // Too high (ran out of time)
    if (this.simulationTime > 300) {
      return true;
    }

    return false;
  }

  private displayFinalResults(): void {
    this.clearScreen();

    const alt = this.spacecraft.getAltitudeAGL();
    const vSpeed = this.spacecraft.getVerticalSpeed();
    const hSpeed = this.spacecraft.getHorizontalSpeed();
    const latLon = this.spacecraft.getLatLon();
    const landingGear = this.spacecraft.getLandingGearStatus();

    console.log('╔════════════════════════════════════════════════════════════════════════════╗');
    console.log('║                          MISSION SUMMARY                                   ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝');
    console.log('');
    console.log(`Mission Duration: ${this.simulationTime.toFixed(1)} seconds`);
    console.log(`Final Altitude AGL: ${alt.toFixed(1)} meters`);
    console.log(`Final Vertical Speed: ${vSpeed.toFixed(2)} m/s`);
    console.log(`Final Horizontal Speed: ${hSpeed.toFixed(2)} m/s`);
    console.log(`Landing Position: ${latLon.latitude.toFixed(4)}°, ${latLon.longitude.toFixed(4)}°`);
    console.log('');
    console.log('Landing Gear:');
    console.log(`  - Deployed: ${landingGear.deployed ? 'YES' : 'NO'}`);
    console.log(`  - Legs in Contact: ${landingGear.contact.legsInContact}/4`);
    console.log(`  - Stable: ${landingGear.contact.isStable ? 'YES' : 'NO'}`);
    console.log(`  - Health: ${landingGear.health.totalHealth.toFixed(1)}%`);
    console.log('');

    // Determine grade
    let grade = 'F';
    let gradeName = 'CRASH';
    let message = 'Better luck next time!';

    if (this.spacecraft.isLanded()) {
      const impactSpeed = Math.abs(vSpeed);
      const gearHealth = landingGear.health.totalHealth;

      if (impactSpeed < 1.0 && gearHealth > 90 && landingGear.contact.isStable) {
        grade = 'S';
        gradeName = 'PERFECT LANDING';
        message = '🎉 Outstanding! A textbook landing!';
      } else if (impactSpeed < 2.0 && gearHealth > 75 && landingGear.contact.isStable) {
        grade = 'A';
        gradeName = 'EXCELLENT LANDING';
        message = '✨ Great job! Very smooth touchdown!';
      } else if (impactSpeed < 3.0 && gearHealth > 50 && landingGear.contact.legsInContact >= 3) {
        grade = 'B';
        gradeName = 'GOOD LANDING';
        message = '👍 Well done! A solid landing!';
      } else if (impactSpeed < 5.0 && gearHealth > 25) {
        grade = 'C';
        gradeName = 'ROUGH LANDING';
        message = '😅 You made it down, but that was bumpy!';
      } else {
        grade = 'D';
        gradeName = 'HARD LANDING';
        message = '😬 Survived, but the spacecraft took damage!';
      }
    } else {
      message = '💥 The spacecraft was destroyed on impact!';
    }

    console.log('╔════════════════════════════════════════════════════════════════════════════╗');
    console.log(`║  GRADE: ${grade} - ${gradeName.padEnd(30)}                           ║`);
    console.log('╚════════════════════════════════════════════════════════════════════════════╝');
    console.log(`  ${message}`);
    console.log('');
  }

  private shutdown(): void {
    if (process.stdin.isTTY) {
      process.stdin.setRawMode(false);
    }
    process.stdin.pause();
    process.exit(0);
  }
}

// Start the game
const game = new InteractiveLunarLander();
