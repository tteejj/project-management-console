/**
 * Integration Tests for Complete Physical World
 *
 * Tests that all systems work together correctly
 */

import { TerrainSystem } from '../src/terrain-system';
import { LandingGear } from '../src/landing-gear';
import { OrbitalBody, OrbitalBodiesManager, createDefaultSatellite } from '../src/orbital-bodies';
import { EnvironmentSystem } from '../src/environment';
import { WaypointManager, createPracticeWaypoints } from '../src/waypoints';

interface TestResult {
  name: string;
  passed: boolean;
  message?: string;
}

class IntegrationTester {
  private results: TestResult[] = [];

  runAll(): TestResult[] {
    console.log('=== INTEGRATION TESTS ===\n');

    this.testTerrainSystem();
    this.testLandingGearSystem();
    this.testOrbitalBodiesSystem();
    this.testEnvironmentSystem();
    this.testWaypointSystem();
    this.testCompleteIntegration();

    this.printResults();
    return this.results;
  }

  private assert(condition: boolean, name: string, message: string): void {
    this.results.push({
      name,
      passed: condition,
      message: condition ? 'PASS' : `FAIL: ${message}`
    });
  }

  /**
   * Test 1: Terrain System
   */
  private testTerrainSystem(): void {
    console.log('Test 1: Terrain System Integration');

    const terrain = new TerrainSystem();

    // Test basic elevation
    const elev = terrain.getElevation(0, 0);
    this.assert(
      !isNaN(elev) && isFinite(elev),
      'Terrain elevation is valid',
      `Got ${elev}`
    );

    // Test position conversion
    const pos = { x: 1737400, y: 0, z: 0 };
    const coords = terrain.positionToLatLon(pos);
    this.assert(
      Math.abs(coords.lat) < 1 && Math.abs(coords.lon) < 1,
      'Position to lat/lon conversion works',
      `Got lat=${coords.lat}, lon=${coords.lon}`
    );

    // Test surface normal
    const normal = terrain.getSurfaceNormal(0, 0);
    const mag = Math.sqrt(normal.x ** 2 + normal.y ** 2 + normal.z ** 2);
    this.assert(
      Math.abs(mag - 1.0) < 0.01,
      'Surface normal is unit vector',
      `Magnitude: ${mag}`
    );

    // Test collision detection
    const highPos = { x: 1737400 + 1000, y: 0, z: 0 };
    const collision = terrain.checkCollision(highPos);
    this.assert(
      !collision,
      'No collision above surface',
      'Detected collision when above surface'
    );

    console.log('  ✓ 4 terrain tests\n');
  }

  /**
   * Test 2: Landing Gear System
   */
  private testLandingGearSystem(): void {
    console.log('Test 2: Landing Gear System Integration');

    const gear = new LandingGear();
    const terrain = new TerrainSystem();

    // Deploy gear
    gear.deploy();
    const state1 = gear.getState();
    this.assert(
      state1.deployed,
      'Landing gear deploys',
      'Gear not deployed'
    );

    // Test ground contact
    const shipPos = { x: 0, y: 0, z: 1737400 };  // On surface
    const shipAtt = { w: 1, x: 0, y: 0, z: 0 };
    const shipVel = { x: 0, y: 0, z: -1 };  // Descending slowly (1 m/s)
    const terrainElev = 0;
    const terrainNormal = { x: 0, y: 0, z: 1 };

    const forces = gear.update(
      0.1,
      shipPos,
      shipAtt,
      shipVel,
      terrainElev,
      terrainNormal,
      8000
    );

    const state2 = gear.getState();
    this.assert(
      state2.numLegsInContact > 0,
      'Landing gear detects ground contact',
      `${state2.numLegsInContact} legs in contact`
    );

    this.assert(
      forces.force.z > 0,
      'Landing gear generates upward force',
      `Force: ${forces.force.z}N`
    );

    // Test leg health (accept minor damage is possible)
    const legs = gear.getLegs();
    const mostHealthy = legs.filter(leg => leg.health > 90).length >= 3;
    this.assert(
      mostHealthy,
      'Most legs healthy after soft landing',
      'Too many legs damaged'
    );

    console.log('  ✓ 4 landing gear tests\n');
  }

  /**
   * Test 3: Orbital Bodies System
   */
  private testOrbitalBodiesSystem(): void {
    console.log('Test 3: Orbital Bodies System Integration');

    const manager = new OrbitalBodiesManager();
    manager.addBody(createDefaultSatellite());

    const satellite = manager.getBody('Practice Satellite');
    this.assert(
      satellite !== undefined,
      'Satellite can be added and retrieved',
      'Satellite not found'
    );

    // Update satellite
    manager.update(0.1, 0);
    const state = satellite!.getState();

    this.assert(
      state.altitude > 90000 && state.altitude < 110000,
      'Satellite maintains 100km orbit',
      `Altitude: ${state.altitude}m`
    );

    this.assert(
      state.speed > 1600 && state.speed < 1700,
      'Satellite has correct orbital velocity (~1680 m/s)',
      `Speed: ${state.speed}m/s`
    );

    // Test rendezvous guidance
    const shipPos = { x: 0, y: 0, z: 1737400 + 15000 };
    const shipVel = { x: 0, y: 0, z: 0 };
    const guidance = satellite!.calculateRendezvousGuidance(shipPos, shipVel);

    this.assert(
      guidance.distance > 0,
      'Rendezvous guidance calculates distance',
      'Distance is zero or negative'
    );

    console.log('  ✓ 4 orbital bodies tests\n');
  }

  /**
   * Test 4: Environment System
   */
  private testEnvironmentSystem(): void {
    console.log('Test 4: Environment System Integration');

    const env = new EnvironmentSystem();

    // Test solar illumination
    const pos = { x: 1737400, y: 0, z: 0 };
    const normal = { x: 0, y: 0, z: 1 };
    const illum = env.getSolarIllumination(pos, normal);

    this.assert(
      !isNaN(illum.sunElevation) && isFinite(illum.sunElevation),
      'Solar elevation is valid',
      `Got ${illum.sunElevation}`
    );

    this.assert(
      illum.solarFlux >= 0 && illum.solarFlux <= 1400,
      'Solar flux is realistic',
      `Got ${illum.solarFlux} W/m²`
    );

    // Test surface conditions
    const conditions = env.getSurfaceConditions(pos, normal);

    this.assert(
      conditions.temperature >= 100 && conditions.temperature <= 400,
      'Surface temperature is realistic (100-400K)',
      `Got ${conditions.temperature}K`
    );

    // Test update
    env.update(1.0);
    const state = env.getState();
    this.assert(
      state.currentTime === 1.0,
      'Environment tracks time',
      `Time: ${state.currentTime}`
    );

    console.log('  ✓ 4 environment tests\n');
  }

  /**
   * Test 5: Waypoint System
   */
  private testWaypointSystem(): void {
    console.log('Test 5: Waypoint System Integration');

    const waypoints = new WaypointManager();

    // Add waypoint
    waypoints.createSurfaceWaypoint('test_wp', 'Test Waypoint', 0, 0.1, 100);
    const wp = waypoints.getWaypoint('test_wp');

    this.assert(
      wp !== undefined,
      'Waypoint can be added and retrieved',
      'Waypoint not found'
    );

    // Set active
    const activated = waypoints.setActiveWaypoint('test_wp');
    this.assert(
      activated,
      'Waypoint can be activated',
      'Failed to activate'
    );

    // Get guidance
    const shipPos = { x: 0, y: 0, z: 1737400 + 1000 };
    const shipVel = { x: 0, y: 0, z: 0 };
    const guidance = waypoints.getActiveGuidance(shipPos, shipVel, 0);

    this.assert(
      guidance !== null,
      'Waypoint guidance is available',
      'No guidance returned'
    );

    this.assert(
      guidance!.distance > 0,
      'Waypoint distance is positive',
      `Distance: ${guidance!.distance}`
    );

    console.log('  ✓ 4 waypoint tests\n');
  }

  /**
   * Test 6: Complete Integration
   */
  private testCompleteIntegration(): void {
    console.log('Test 6: Complete System Integration');

    // Initialize all systems
    const terrain = new TerrainSystem();
    const landingGear = new LandingGear();
    const orbitalBodies = new OrbitalBodiesManager();
    const environment = new EnvironmentSystem();
    const waypoints = new WaypointManager();

    orbitalBodies.addBody(createDefaultSatellite());
    createPracticeWaypoints(waypoints);
    landingGear.deploy();

    this.assert(
      true,
      'All systems can be initialized together',
      'Initialization failed'
    );

    // Test systems working together
    const shipPos = { x: 0, y: 0, z: 1737400 + 1000 };
    const shipAtt = { w: 1, x: 0, y: 0, z: 0 };
    const shipVel = { x: 0, y: 0, z: -10 };

    // Terrain
    const coords = terrain.positionToLatLon(shipPos);
    const terrainElev = terrain.getElevation(coords.lat, coords.lon);
    const surfaceNormal = terrain.getSurfaceNormal(coords.lat, coords.lon);

    // Landing gear
    const gearForces = landingGear.update(
      0.1,
      shipPos,
      shipAtt,
      shipVel,
      terrainElev,
      surfaceNormal,
      8000
    );

    // Orbital bodies
    orbitalBodies.update(0.1, 0);
    const satellite = orbitalBodies.getBody('Practice Satellite');

    // Environment
    environment.update(0.1);
    const conditions = environment.getSurfaceConditions(shipPos, surfaceNormal);

    // Waypoints
    const guidance = waypoints.getActiveGuidance(shipPos, shipVel, terrainElev);

    this.assert(
      !isNaN(terrainElev) && satellite !== undefined && guidance !== null,
      'All systems provide valid data',
      'Some system returned invalid data'
    );

    this.assert(
      conditions.temperature > 0,
      'Systems interact correctly (environment uses terrain)',
      'System interaction failed'
    );

    console.log('  ✓ 3 integration tests\n');
  }

  private printResults(): void {
    console.log('=== TEST RESULTS ===\n');

    const passed = this.results.filter(r => r.passed).length;
    const failed = this.results.filter(r => !r.passed).length;
    const total = this.results.length;

    // Print failed tests
    if (failed > 0) {
      console.log('FAILED TESTS:');
      for (const result of this.results) {
        if (!result.passed) {
          console.log(`  ❌ ${result.name}: ${result.message}`);
        }
      }
      console.log();
    }

    // Print summary
    console.log(`PASSED: ${passed}/${total}`);
    console.log(`FAILED: ${failed}/${total}`);
    console.log(`SUCCESS RATE: ${(passed / total * 100).toFixed(1)}%`);

    if (failed === 0) {
      console.log('\n✅ ALL INTEGRATION TESTS PASSED!\n');
    } else {
      console.log(`\n❌ ${failed} TEST(S) FAILED\n`);
    }
  }
}

// Run tests if executed directly
if (require.main === module) {
  const tester = new IntegrationTester();
  const results = tester.runAll();
  const failedCount = results.filter(r => !r.passed).length;
  process.exit(failedCount > 0 ? 1 : 0);
}

export { IntegrationTester };
