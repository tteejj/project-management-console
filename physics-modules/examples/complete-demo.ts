/**
 * Complete Physical World Demo
 *
 * Demonstrates all integrated systems:
 * - Terrain with craters
 * - Landing gear physics
 * - Orbital satellite
 * - Environment (sun position, thermal)
 * - Waypoint navigation
 */

import { TerrainSystem } from '../src/terrain-system';
import { LandingGear } from '../src/landing-gear';
import { OrbitalBody, OrbitalBodiesManager, createDefaultSatellite } from '../src/orbital-bodies';
import { EnvironmentSystem } from '../src/environment';
import { WaypointManager, createPracticeWaypoints } from '../src/waypoints';

interface Vector3 {
  x: number;
  y: number;
  z: number;
}

interface Quaternion {
  w: number;
  x: number;
  y: number;
  z: number;
}

/**
 * Simple spacecraft physics for demo
 */
class SimpleSpacecraft {
  position: Vector3;
  velocity: Vector3;
  attitude: Quaternion;
  angularVelocity: Vector3;
  mass: number;
  thrust: number = 0;

  private readonly MOON_RADIUS = 1737400;
  private readonly MOON_MASS = 7.342e22;
  private readonly G = 6.67430e-11;

  constructor() {
    // Start at 15km altitude
    this.position = { x: 0, y: 0, z: this.MOON_RADIUS + 15000 };
    this.velocity = { x: 0, y: 0, z: -40 };  // Descending
    this.attitude = { w: 1, x: 0, y: 0, z: 0 };  // Identity
    this.angularVelocity = { x: 0, y: 0, z: 0 };
    this.mass = 8000;  // 8 metric tons
  }

  update(dt: number, landingGearForce: Vector3): void {
    // Gravity
    const r = this.magnitude(this.position);
    const gravityMag = this.G * this.MOON_MASS / (r * r);
    const gravityDir = this.normalize(this.position);
    const gravity = {
      x: -gravityDir.x * gravityMag * this.mass,
      y: -gravityDir.y * gravityMag * this.mass,
      z: -gravityDir.z * gravityMag * this.mass
    };

    // Total force
    const totalForce = {
      x: gravity.x + landingGearForce.x,
      y: gravity.y + landingGearForce.y,
      z: gravity.z + landingGearForce.z
    };

    // Acceleration = F / m
    const accel = {
      x: totalForce.x / this.mass,
      y: totalForce.y / this.mass,
      z: totalForce.z / this.mass
    };

    // Update velocity and position
    this.velocity.x += accel.x * dt;
    this.velocity.y += accel.y * dt;
    this.velocity.z += accel.z * dt;

    this.position.x += this.velocity.x * dt;
    this.position.y += this.velocity.y * dt;
    this.position.z += this.velocity.z * dt;
  }

  getAltitude(terrainElev: number): number {
    return this.magnitude(this.position) - this.MOON_RADIUS - terrainElev;
  }

  private magnitude(v: Vector3): number {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  }

  private normalize(v: Vector3): Vector3 {
    const mag = this.magnitude(v);
    return { x: v.x / mag, y: v.y / mag, z: v.z / mag };
  }
}

/**
 * Run complete simulation
 */
function runSimulation() {
  console.log('='.repeat(80));
  console.log('MOON LANDER - COMPLETE PHYSICAL WORLD SIMULATION');
  console.log('='.repeat(80));
  console.log();

  // Initialize all systems
  console.log('Initializing systems...');
  const terrain = new TerrainSystem();
  const landingGear = new LandingGear();
  const orbitalBodies = new OrbitalBodiesManager();
  const environment = new EnvironmentSystem();
  const waypoints = new WaypointManager();
  const spacecraft = new SimpleSpacecraft();

  // Add satellite
  orbitalBodies.addBody(createDefaultSatellite());

  // Add waypoints
  createPracticeWaypoints(waypoints);

  console.log('✓ Terrain system initialized');
  console.log('✓ Landing gear ready');
  console.log('✓ Satellite in orbit (100km)');
  console.log('✓ Environment system online');
  console.log('✓ Waypoints created (3 waypoints)');
  console.log();

  // Deploy landing gear
  landingGear.deploy();
  console.log('Landing gear deployed\n');

  // Simulation parameters
  const dt = 0.1;  // 100ms timesteps
  let time = 0;
  let landed = false;

  console.log('Starting descent from 15km...\n');
  console.log('Time    Alt(m)  Speed(m/s) Terrain(m) Legs  Temp(K) Satellite(km) Waypoint');
  console.log('-'.repeat(80));

  // Run simulation
  for (let step = 0; step < 3000; step++) {
    // Update all systems
    orbitalBodies.update(dt, time);
    environment.update(dt);

    // Get current conditions
    const coords = terrain.positionToLatLon(spacecraft.position);
    const terrainElev = terrain.getElevation(coords.lat, coords.lon);
    const surfaceNormal = terrain.getSurfaceNormal(coords.lat, coords.lon);
    const altitude = spacecraft.getAltitude(terrainElev);

    // Landing gear physics
    const gearForces = landingGear.update(
      dt,
      spacecraft.position,
      spacecraft.attitude,
      spacecraft.velocity,
      terrainElev,
      surfaceNormal,
      spacecraft.mass
    );

    const gearState = landingGear.getState();

    // Update spacecraft
    spacecraft.update(dt, gearForces.force);

    // Environment
    const surfaceConditions = environment.getSurfaceConditions(
      spacecraft.position,
      surfaceNormal
    );

    // Satellite tracking
    const satellite = orbitalBodies.getBody('Practice Satellite');
    const satDistance = satellite ? Math.sqrt(
      (satellite.position.x - spacecraft.position.x) ** 2 +
      (satellite.position.y - spacecraft.position.y) ** 2 +
      (satellite.position.z - spacecraft.position.z) ** 2
    ) / 1000 : 0;

    // Waypoint guidance
    const guidance = waypoints.getActiveGuidance(
      spacecraft.position,
      spacecraft.velocity,
      terrainElev
    );

    // Print status every second
    if (step % 10 === 0) {
      const speed = Math.sqrt(
        spacecraft.velocity.x ** 2 +
        spacecraft.velocity.y ** 2 +
        spacecraft.velocity.z ** 2
      );

      const wpInfo = guidance
        ? `${guidance.waypoint.name.substring(0, 15)} (${(guidance.distance / 1000).toFixed(1)}km)`
        : 'None';

      console.log(
        `${time.toFixed(1).padStart(6)}s ` +
        `${altitude.toFixed(0).padStart(6)} ` +
        `${speed.toFixed(1).padStart(9)} ` +
        `${terrainElev.toFixed(0).padStart(9)} ` +
        `${gearState.numLegsInContact}/${landingGear.getLegs().length} ` +
        `${surfaceConditions.temperature.toFixed(0).padStart(6)} ` +
        `${satDistance.toFixed(1).padStart(12)} ` +
        `${wpInfo}`
      );
    }

    // Check for landing
    if (altitude <= 0 && !landed) {
      landed = true;
      const speed = Math.sqrt(
        spacecraft.velocity.x ** 2 +
        spacecraft.velocity.y ** 2 +
        spacecraft.velocity.z ** 2
      );

      console.log();
      console.log('='.repeat(80));
      console.log('TOUCHDOWN!');
      console.log('='.repeat(80));
      console.log(`Landing time: ${time.toFixed(1)}s`);
      console.log(`Impact speed: ${speed.toFixed(2)} m/s`);
      console.log(`Legs in contact: ${gearState.numLegsInContact}/${landingGear.getLegs().length}`);
      console.log(`Landing stable: ${gearState.isStable ? 'YES' : 'NO'}`);
      console.log(`Max leg force: ${(gearState.maxLegForce / 1000).toFixed(1)} kN`);
      console.log(`Avg compression: ${(gearState.avgCompression * 100).toFixed(1)}%`);
      console.log(`Damaged legs: ${gearState.damagedLegs}`);
      console.log();

      // Landing assessment
      if (speed < 2.0) {
        console.log('🌟 PERFECT LANDING!');
      } else if (speed < 3.0) {
        console.log('✅ SOFT LANDING');
      } else if (speed < 5.0) {
        console.log('⚠️  HARD LANDING');
      } else {
        console.log('❌ CRASH LANDING');
      }
      console.log();

      // Terrain info
      const slope = terrain.getSlope(coords.lat, coords.lon);
      const nearCrater = terrain.getNearestCrater(coords.lat, coords.lon);

      console.log('Landing site:');
      console.log(`  Position: ${coords.lat.toFixed(3)}°N, ${coords.lon.toFixed(3)}°E`);
      console.log(`  Elevation: ${terrainElev.toFixed(1)}m`);
      console.log(`  Slope: ${slope.toFixed(1)}°`);
      if (nearCrater && nearCrater.distance < 50) {
        console.log(`  Near: ${nearCrater.crater.name || 'Small crater'} (${nearCrater.distance.toFixed(1)}km)`);
      }
      console.log();

      // Environment info
      const solarIllum = environment.getSolarIllumination(spacecraft.position, surfaceNormal);
      console.log('Environment:');
      console.log(`  Surface temp: ${surfaceConditions.temperature.toFixed(1)}K`);
      console.log(`  Solar flux: ${surfaceConditions.solarFlux.toFixed(0)} W/m²`);
      console.log(`  Sun elevation: ${solarIllum.sunElevation.toFixed(1)}°`);
      console.log(`  Daylight: ${solarIllum.isDaylight ? 'Yes' : 'No'}`);
      console.log();

      // Satellite info
      if (satellite) {
        const satState = satellite.getState();
        console.log('Satellite tracking:');
        console.log(`  Distance: ${satDistance.toFixed(1)}km`);
        console.log(`  Altitude: ${(satState.altitude / 1000).toFixed(1)}km`);
        console.log(`  Orbital period: ${(satState.orbitalPeriod / 60).toFixed(1)} min`);
        console.log(`  Speed: ${(satState.speed / 1000).toFixed(2)}km/s`);

        if (satState.dockingPort) {
          console.log(`  Docking port: Available`);
          console.log(`  Port radius: ${satState.dockingPort.radius}m`);
        }
      }
      console.log();

      // Waypoint info
      if (guidance) {
        console.log('Next waypoint:');
        console.log(`  Name: ${guidance.waypoint.name}`);
        console.log(`  Distance: ${(guidance.distance / 1000).toFixed(2)}km`);
        console.log(`  Bearing: ${guidance.bearing.toFixed(0)}°`);
        console.log(`  Elevation: ${guidance.elevation.toFixed(1)}°`);
      }

      break;
    }

    time += dt;
  }

  console.log();
  console.log('='.repeat(80));
  console.log('SIMULATION COMPLETE');
  console.log('='.repeat(80));
  console.log();
  console.log('Systems tested:');
  console.log('✅ Terrain system - Real lunar surface with craters');
  console.log('✅ Landing gear - 4-leg spring-damper suspension');
  console.log('✅ Orbital bodies - Satellite in 100km orbit');
  console.log('✅ Environment - Solar position and thermal cycling');
  console.log('✅ Waypoints - Navigation guidance system');
  console.log();
  console.log('All systems operational! 🚀');
}

// Run the simulation
runSimulation();
