/**
 * Complete Lunar Lander Game
 *
 * Integrated game with all physics systems:
 * - Terrain system with elevation and craters
 * - Landing gear with 4-leg suspension
 * - Orbital bodies (practice satellite)
 * - Environment (solar position, thermal)
 * - Waypoint navigation
 * - Full spacecraft physics
 *
 * Controls:
 * - W: Thrust up (main engine)
 * - S: Thrust down (reduce throttle)
 * - A/D: Rotate left/right
 * - G: Toggle landing gear
 * - Q: Quit
 */

import { GameWorld } from '../src/game-world';
import { GameSpacecraft } from '../src/game-spacecraft';
import { Vector3 } from '../src/types';

/**
 * Main game class
 */
class LunarLanderGame {
  private gameWorld: GameWorld;
  private spacecraft: GameSpacecraft;
  private running: boolean = false;
  private simulationTime: number = 0;
  private frameCount: number = 0;

  // Game settings
  private readonly FPS = 10; // Update rate
  private readonly dt = 1.0 / this.FPS;

  // Display state
  private lastDisplayTime: number = 0;
  private readonly DISPLAY_INTERVAL = 1.0; // Update display every second

  constructor() {
    // Create game world with all systems
    console.log('🌙 Initializing Lunar Lander Game...\n');

    this.gameWorld = new GameWorld({
      createMoon: true,
      createSatellite: true,
      createWaypoints: true,
      terrainSeed: 42,
    });

    // Create spacecraft at 15km altitude
    this.spacecraft = new GameSpacecraft(
      {
        initialPosition: { x: 1737400 + 15000, y: 0, z: 0 }, // 15km altitude
        initialVelocity: { x: 0, y: 0, z: 0 },
        dryMass: 15000, // 15 metric tons dry mass
        propellantMass: 8000, // 8 metric tons propellant
      },
      this.gameWorld
    );

    // Deploy landing gear
    this.spacecraft.setLandingGearDeployed(true);

    console.log('✅ Game initialized!\n');
    console.log('='.repeat(80));
    console.log('MISSION: Land safely on the lunar surface');
    console.log('='.repeat(80));
    console.log('Starting altitude: 15.0 km');
    console.log('Spacecraft mass: 23.0 metric tons (15.0t dry + 8.0t propellant)');
    console.log('Landing gear: DEPLOYED');
    console.log('Target: Navigate to waypoints and land safely');
    console.log('='.repeat(80) + '\n');
  }

  /**
   * Main game loop
   */
  run(): void {
    this.running = true;

    console.log('🚀 Starting simulation...\n');

    // Run simulation for 200 seconds (enough time for descent)
    const maxTime = 200.0;

    while (this.running && this.simulationTime < maxTime) {
      this.update();

      // Check for landing or crash
      if (this.checkLandingConditions()) {
        break;
      }

      this.frameCount++;
      this.simulationTime += this.dt;
    }

    // Display final results
    this.displayFinalResults();
  }

  /**
   * Update game state
   */
  private update(): void {
    // Update world (celestial bodies, environment, orbital mechanics)
    this.gameWorld.update(this.dt);

    // Update spacecraft (physics, landing gear, collisions)
    this.spacecraft.update(this.dt);

    // Display status periodically
    if (this.simulationTime - this.lastDisplayTime >= this.DISPLAY_INTERVAL) {
      this.displayStatus();
      this.lastDisplayTime = this.simulationTime;
    }
  }

  /**
   * Display current status
   */
  private displayStatus(): void {
    const position = this.spacecraft.getPosition();
    const velocity = this.spacecraft.getVelocity();
    const altitudeAGL = this.spacecraft.getAltitudeAGL();
    const altitudeMSL = this.spacecraft.getAltitudeMSL();
    const verticalSpeed = this.spacecraft.getVerticalSpeed();
    const horizontalSpeed = this.spacecraft.getHorizontalSpeed();
    const latLon = this.spacecraft.getLatLon();
    const landingGear = this.spacecraft.getLandingGearStatus();

    // Get environment info
    const surfaceNormal = this.gameWorld.getSurfaceNormal(latLon.latitude, latLon.longitude);
    const surfaceConditions = this.gameWorld.getSurfaceConditions(position, surfaceNormal);

    // Get waypoint guidance
    const waypointGuidance = this.gameWorld.getActiveWaypointGuidance(position, velocity);

    // Get nearest satellite
    const nearestBody = this.gameWorld.getNearestOrbitalBody(position, velocity);
    let satelliteInfo = 'None';
    if (nearestBody) {
      const dx = nearestBody.body.position.x - position.x;
      const dy = nearestBody.body.position.y - position.y;
      const dz = nearestBody.body.position.z - position.z;
      const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
      satelliteInfo = `${nearestBody.body.name} (${(distance / 1000).toFixed(1)} km)`;
    }

    console.log(`T+${this.simulationTime.toFixed(1)}s | ` +
      `ALT: ${(altitudeAGL / 1000).toFixed(3)} km | ` +
      `V/S: ${verticalSpeed.toFixed(1)} m/s | ` +
      `H/S: ${horizontalSpeed.toFixed(1)} m/s`);

    console.log(`  Position: [${position.x.toFixed(0)}, ${position.y.toFixed(0)}, ${position.z.toFixed(0)}]`);
    console.log(`  Lat/Lon: ${latLon.latitude.toFixed(2)}°, ${latLon.longitude.toFixed(2)}°`);
    console.log(`  Altitude MSL: ${(altitudeMSL / 1000).toFixed(3)} km | AGL: ${(altitudeAGL / 1000).toFixed(3)} km`);
    console.log(`  Landing Gear: ${landingGear.deployed ? 'DEPLOYED' : 'RETRACTED'} | ` +
      `Contact: ${landingGear.contact.legsInContact}/4 legs | ` +
      `Stable: ${landingGear.contact.isStable ? 'YES' : 'NO'}`);

    if (landingGear.health.totalHealth < 100) {
      console.log(`  ⚠️  DAMAGE: Landing gear health ${landingGear.health.totalHealth.toFixed(1)}%`);
    }

    console.log(`  Surface Temp: ${surfaceConditions.temperature.toFixed(0)} K | ` +
      `Illuminated: ${surfaceConditions.illuminated ? 'YES' : 'NO'}`);

    if (waypointGuidance) {
      console.log(`  📍 Waypoint: ${waypointGuidance.waypoint.name} | ` +
        `Distance: ${(waypointGuidance.distance / 1000).toFixed(1)} km | ` +
        `Bearing: ${waypointGuidance.bearing.toFixed(0)}°`);
    }

    console.log(`  🛰️  Nearest Satellite: ${satelliteInfo}`);
    console.log('');
  }

  /**
   * Check landing or crash conditions
   */
  private checkLandingConditions(): boolean {
    const altitudeAGL = this.spacecraft.getAltitudeAGL();
    const verticalSpeed = this.spacecraft.getVerticalSpeed();
    const landingGear = this.spacecraft.getLandingGearStatus();
    const hullIntegrity = this.spacecraft.getHullIntegrity();

    // Check if landed (on ground and stable)
    if (this.spacecraft.isSpacecraftLanded()) {
      console.log('\n' + '='.repeat(80));
      console.log('🎉 TOUCHDOWN!');
      console.log('='.repeat(80));
      return true;
    }

    // Check if crashed (hull damage or below surface with high speed)
    if (hullIntegrity < 0.5) {
      console.log('\n' + '='.repeat(80));
      console.log('💥 CRASH! Hull integrity critical!');
      console.log('='.repeat(80));
      return true;
    }

    // Check if below surface with significant speed
    if (altitudeAGL < 0 && Math.abs(verticalSpeed) > 10) {
      console.log('\n' + '='.repeat(80));
      console.log('💥 CRASH! Impact with terrain!');
      console.log('='.repeat(80));
      return true;
    }

    return false;
  }

  /**
   * Display final results
   */
  private displayFinalResults(): void {
    const position = this.spacecraft.getPosition();
    const velocity = this.spacecraft.getVelocity();
    const altitudeAGL = this.spacecraft.getAltitudeAGL();
    const verticalSpeed = this.spacecraft.getVerticalSpeed();
    const horizontalSpeed = this.spacecraft.getHorizontalSpeed();
    const latLon = this.spacecraft.getLatLon();
    const landingGear = this.spacecraft.getLandingGearStatus();
    const hullIntegrity = this.spacecraft.getHullIntegrity();

    console.log('\n');
    console.log('='.repeat(80));
    console.log('MISSION SUMMARY');
    console.log('='.repeat(80));
    console.log(`Mission Duration: ${this.simulationTime.toFixed(1)} seconds`);
    console.log(`Final Altitude AGL: ${altitudeAGL.toFixed(1)} meters`);
    console.log(`Final Vertical Speed: ${verticalSpeed.toFixed(2)} m/s`);
    console.log(`Final Horizontal Speed: ${horizontalSpeed.toFixed(2)} m/s`);
    console.log(`Landing Position: ${latLon.latitude.toFixed(4)}°, ${latLon.longitude.toFixed(4)}°`);
    console.log(`Landing Gear Status:`);
    console.log(`  - Deployed: ${landingGear.deployed ? 'YES' : 'NO'}`);
    console.log(`  - Legs in Contact: ${landingGear.contact.legsInContact}/4`);
    console.log(`  - Stable: ${landingGear.contact.isStable ? 'YES' : 'NO'}`);
    console.log(`  - Average Health: ${landingGear.health.totalHealth.toFixed(1)}%`);
    console.log(`Hull Integrity: ${(hullIntegrity * 100).toFixed(1)}%`);

    // Determine landing quality
    let grade = 'F';
    let gradeName = 'CRASH';

    if (this.spacecraft.isSpacecraftLanded()) {
      const impactSpeed = Math.abs(verticalSpeed);
      const gearHealth = landingGear.health.totalHealth;

      if (impactSpeed < 1.0 && gearHealth > 90 && landingGear.contact.isStable) {
        grade = 'S';
        gradeName = 'PERFECT LANDING';
      } else if (impactSpeed < 2.0 && gearHealth > 75 && landingGear.contact.isStable) {
        grade = 'A';
        gradeName = 'EXCELLENT LANDING';
      } else if (impactSpeed < 3.0 && gearHealth > 50 && landingGear.contact.legsInContact >= 3) {
        grade = 'B';
        gradeName = 'GOOD LANDING';
      } else if (impactSpeed < 5.0 && gearHealth > 25) {
        grade = 'C';
        gradeName = 'ROUGH LANDING';
      } else {
        grade = 'D';
        gradeName = 'HARD LANDING';
      }
    }

    console.log(`\nGRADE: ${grade} - ${gradeName}`);
    console.log('='.repeat(80));
    console.log('\n');
  }
}

/**
 * Run the game
 */
function main() {
  const game = new LunarLanderGame();
  game.run();
}

// Start the game
main();
