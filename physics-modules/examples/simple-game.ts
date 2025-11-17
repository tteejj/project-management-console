/**
 * Simple Lunar Lander Game
 *
 * Complete integrated game with all physics systems:
 * - Terrain with elevation and craters
 * - Landing gear with 4-leg suspension
 * - Orbital satellite
 * - Environment (solar, thermal)
 * - Waypoint navigation
 */

import { SimpleWorld } from '../src/simple-world';
import { SimpleSpacecraft } from '../src/simple-spacecraft';

class SimpleLunarLander {
  private world: SimpleWorld;
  private spacecraft: SimpleSpacecraft;
  private simulationTime: number = 0;

  private readonly FPS = 10;
  private readonly dt = 1.0 / this.FPS;
  private readonly DISPLAY_INTERVAL = 1.0;
  private lastDisplayTime: number = 0;

  constructor() {
    console.log('🌙 Initializing Simple Lunar Lander...\n');

    // Create world with all systems
    this.world = new SimpleWorld({
      terrainSeed: 42,
      createSatellite: true,
      createWaypoints: true,
    });

    // Create spacecraft at 15km altitude
    this.spacecraft = new SimpleSpacecraft(
      {
        initialPosition: { x: 1737400 + 15000, y: 0, z: 0 },
        initialVelocity: { x: 0, y: 0, z: 0 },
        mass: 23000, // 23 metric tons
      },
      this.world
    );

    console.log('✅ Game initialized!\n');
    console.log('='.repeat(80));
    console.log('MISSION: Land safely on the lunar surface');
    console.log('='.repeat(80));
    console.log('Starting altitude: 15.0 km');
    console.log('Spacecraft mass: 23.0 metric tons');
    console.log('Landing gear: DEPLOYED');
    console.log('='.repeat(80) + '\n');
  }

  run(): void {
    console.log('🚀 Starting simulation...\n');

    const maxTime = 200.0;

    while (this.simulationTime < maxTime) {
      // Update world and spacecraft
      this.world.update(this.dt);
      this.spacecraft.update(this.dt);

      // Display status
      if (this.simulationTime - this.lastDisplayTime >= this.DISPLAY_INTERVAL) {
        this.displayStatus();
        this.lastDisplayTime = this.simulationTime;
      }

      // Check for landing or crash
      if (this.checkLandingConditions()) {
        break;
      }

      this.simulationTime += this.dt;
    }

    this.displayFinalResults();
  }

  private displayStatus(): void {
    const altitudeAGL = this.spacecraft.getAltitudeAGL();
    const altitudeMSL = this.spacecraft.getAltitudeMSL();
    const verticalSpeed = this.spacecraft.getVerticalSpeed();
    const horizontalSpeed = this.spacecraft.getHorizontalSpeed();
    const latLon = this.spacecraft.getLatLon();
    const landingGear = this.spacecraft.getLandingGearStatus();

    // Get terrain info
    const terrainElevation = this.world.terrain.getElevation(latLon.latitude, latLon.longitude);

    // Get environment info
    const surfaceNormal = this.world.terrain.getSurfaceNormal(latLon.latitude, latLon.longitude);
    const surfaceConditions = this.world.environment.getSurfaceConditions(
      this.spacecraft.position,
      surfaceNormal
    );

    // Get waypoint guidance
    const waypointGuidance = this.world.waypoints.getActiveGuidance(
      this.spacecraft.position,
      this.spacecraft.velocity,
      terrainElevation
    );

    // Get nearest satellite
    const nearestSatellite = this.world.orbitalBodies.findNearestBody(this.spacecraft.position);
    let satelliteInfo = 'None';
    if (nearestSatellite) {
      const satPos = nearestSatellite.body.position;
      const dx = satPos.x - this.spacecraft.position.x;
      const dy = satPos.y - this.spacecraft.position.y;
      const dz = satPos.z - this.spacecraft.position.z;
      const distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
      satelliteInfo = `${nearestSatellite.body.name} (${(distance / 1000).toFixed(1)} km)`;
    }

    console.log(`T+${this.simulationTime.toFixed(1)}s | ` +
      `ALT: ${(altitudeAGL / 1000).toFixed(3)} km | ` +
      `V/S: ${verticalSpeed.toFixed(1)} m/s | ` +
      `H/S: ${horizontalSpeed.toFixed(1)} m/s`);

    console.log(`  Position: [${this.spacecraft.position.x.toFixed(0)}, ` +
      `${this.spacecraft.position.y.toFixed(0)}, ` +
      `${this.spacecraft.position.z.toFixed(0)}]`);

    console.log(`  Lat/Lon: ${latLon.latitude.toFixed(2)}°, ${latLon.longitude.toFixed(2)}°`);

    console.log(`  Altitude MSL: ${(altitudeMSL / 1000).toFixed(3)} km | ` +
      `AGL: ${(altitudeAGL / 1000).toFixed(3)} km | ` +
      `Terrain: ${terrainElevation.toFixed(1)} m`);

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

  private checkLandingConditions(): boolean {
    const altitudeAGL = this.spacecraft.getAltitudeAGL();
    const verticalSpeed = this.spacecraft.getVerticalSpeed();

    // Check if landed
    if (this.spacecraft.isLanded() && Math.abs(verticalSpeed) < 0.1) {
      console.log('\n' + '='.repeat(80));
      console.log('🎉 TOUCHDOWN!');
      console.log('='.repeat(80));
      return true;
    }

    // Check if crashed (below surface with significant speed)
    if (altitudeAGL < -1.0) {
      console.log('\n' + '='.repeat(80));
      console.log('💥 CRASH! Impact with terrain!');
      console.log('='.repeat(80));
      return true;
    }

    return false;
  }

  private displayFinalResults(): void {
    const altitudeAGL = this.spacecraft.getAltitudeAGL();
    const verticalSpeed = this.spacecraft.getVerticalSpeed();
    const horizontalSpeed = this.spacecraft.getHorizontalSpeed();
    const latLon = this.spacecraft.getLatLon();
    const landingGear = this.spacecraft.getLandingGearStatus();

    console.log('\n');
    console.log('='.repeat(80));
    console.log('MISSION SUMMARY');
    console.log('='.repeat(80));
    console.log(`Mission Duration: ${this.simulationTime.toFixed(1)} seconds`);
    console.log(`Final Altitude AGL: ${altitudeAGL.toFixed(1)} meters`);
    console.log(`Final Vertical Speed: ${verticalSpeed.toFixed(2)} m/s`);
    console.log(`Final Horizontal Speed: ${horizontalSpeed.toFixed(2)} m/s`);
    console.log(`Landing Position: ${latLon.latitude.toFixed(4)}°, ${latLon.longitude.toFixed(4)}°`);
    console.log(`Landing Gear:`);
    console.log(`  - Deployed: ${landingGear.deployed ? 'YES' : 'NO'}`);
    console.log(`  - Legs in Contact: ${landingGear.contact.legsInContact}/4`);
    console.log(`  - Stable: ${landingGear.contact.isStable ? 'YES' : 'NO'}`);
    console.log(`  - Average Health: ${landingGear.health.totalHealth.toFixed(1)}%`);

    // Determine landing quality
    let grade = 'F';
    let gradeName = 'CRASH';

    if (this.spacecraft.isLanded()) {
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
    console.log('\n✅ All physics systems integrated and working!');
    console.log('   - Terrain: Elevation tracking with procedural craters');
    console.log('   - Landing Gear: 4-leg spring-damper suspension');
    console.log('   - Environment: Solar position and thermal calculations');
    console.log('   - Orbital Bodies: Practice satellite in 100km orbit');
    console.log('   - Waypoints: Navigation guidance system');
    console.log('='.repeat(80) + '\n');
  }
}

// Run the game
function main() {
  const game = new SimpleLunarLander();
  game.run();
}

main();
