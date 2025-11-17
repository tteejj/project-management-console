/**
 * Complete Ship Simulation Test
 *
 * Demonstrates a fully integrated ship in a simulated universe
 */

import { describe, it, expect } from 'vitest';
import { CompleteShip, ShipTemplates } from '../src/ship-configuration';
import { World } from '../src/world';
import { IntegratedShip, SimulationController } from '../src/integrated-ship';

describe('Complete Ship Simulation', () => {
  it('should simulate a ship as a celestial body in the universe', () => {
    // STEP 1: Create the universe (world with moon)
    const world = new World();
    world.addBody({
      id: 'moon',
      name: 'Moon',
      mass: 7.342e22,  // Moon mass
      radius: 1737400,  // Moon radius in meters
      position: { x: 0, y: 0, z: 0 },
      velocity: { x: 0, y: 0, z: 0 },
      type: 'planet'
    });

    // STEP 2: Create a complete ship with all subsystems
    const ship = ShipTemplates.createFrigate(
      'frigate-1',
      { x: 0, y: 0, z: 1737400 + 100000 },  // 100km above moon surface
      { x: 1700, y: 0, z: 0 }  // Orbital velocity
    );

    // STEP 3: Add ship to world as celestial body
    const integratedShip = new IntegratedShip({
      mass: ship.mass,
      radius: 10,  // 10m radius frigate
      position: ship.position,
      velocity: ship.velocity
    }, world);

    // STEP 4: Create simulation controller
    const sim = new SimulationController(world);
    sim.addShip(integratedShip);

    // STEP 5: Run simulation
    // Update once to initialize power generation
    ship.update(1);
    const statusBefore = ship.getStatus();

    for (let i = 0; i < 60; i++) {
      // Update universe (gravity, orbits)
      sim.update(1);

      // Update ship systems
      ship.update(1);

      // Sync ship physics
      ship.position = integratedShip.getPosition();
      ship.velocity = integratedShip.getVelocity();
    }

    const statusAfter = ship.getStatus();

    // VERIFY: Ship is functioning
    expect(statusAfter.power.generation).toBeGreaterThan(0);  // Reactor working
    expect(statusAfter.power.brownout).toBe(false);  // No power issues
    expect(statusAfter.lifeSupport.crewHealthy).toBe(2);  // Both crew healthy
    expect(statusAfter.damage.operational).toBe(2);  // All systems operational

    // VERIFY: IntegratedShip exists in world as celestial body
    const integratedPos = integratedShip.getPosition();
    expect(integratedPos).toBeDefined();
    expect(integratedShip.getVelocity()).toBeDefined();
    // Ship is orbiting moon under gravity (integration successful)
  });

  it('should handle damage cascades across all systems', () => {
    // Create ship
    const ship = ShipTemplates.createFrigate(
      'frigate-2',
      { x: 0, y: 0, z: 2000000 },
      { x: 0, y: 0, z: 0 }
    );

    // DAMAGE: Breach the engineering compartment
    const engineering = ship.hull.getCompartment('engineering')!;
    engineering.breaches.push({
      id: 'breach-1',
      position: { x: 0, y: 0, z: 0 },
      area: 0.5,  // Large breach - 0.5 m²
      sealed: false,
      damageType: 0
    });
    // Damage compartment structure
    engineering.structuralIntegrity = 0.5;  // 50% structural damage

    // Simulate damage propagation
    for (let i = 0; i < 10; i++) {
      ship.update(1);
    }

    const status = ship.getStatus();

    // VERIFY: Damage cascade occurred
    expect(engineering.pressure).toBeLessThan(101325);  // Pressure lost
    expect(engineering.atmosphereIntegrity).toBeLessThan(1.0);  // Atmosphere compromised

    // Systems in engineering should be affected by structural damage
    const reactorSystem = ship.systemDamage.getSystem('reactor-sys')!;
    expect(reactorSystem.integrity).toBeLessThan(1.0);  // Reactor damaged from compartment failure
  });

  it('should simulate crew repairs restoring ship function', () => {
    // Create damaged ship
    const ship = ShipTemplates.createFrigate(
      'frigate-3',
      { x: 0, y: 0, z: 2000000 },
      { x: 0, y: 0, z: 0 }
    );

    // Create breach
    const engineering = ship.hull.getCompartment('engineering')!;
    const breach = {
      id: 'breach-1',
      position: { x: 0, y: 0, z: 0 },
      area: 0.01,  // Small breach
      sealed: false,
      damageType: 0
    };
    engineering.breaches.push(breach);

    // Auto-assign repair crews
    ship.damageControl.autoAssignTasks();

    // Simulate repairs
    for (let i = 0; i < 200; i++) {
      ship.update(1);
    }

    // VERIFY: Breach sealed
    expect(breach.sealed).toBe(true);

    // VERIFY: Pressure recovering
    expect(engineering.pressure).toBeGreaterThan(50000);  // Partial recovery
  });

  it('should track power consumption affecting thermal and life support', () => {
    const ship = ShipTemplates.createFrigate(
      'frigate-4',
      { x: 0, y: 0, z: 2000000 },
      { x: 0, y: 0, z: 0 }
    );

    const initialThermal = ship.thermal.getStatistics();
    const initialPower = ship.power.getStatistics();

    // Run for 1 minute
    for (let i = 0; i < 60; i++) {
      ship.update(1);
    }

    const finalThermal = ship.thermal.getStatistics();
    const finalPower = ship.power.getStatistics();

    // VERIFY: Power consumed
    expect(finalPower.totalEnergyConsumed).toBeGreaterThan(0);

    // VERIFY: Heat generated
    expect(finalThermal.totalHeatGenerated).toBeGreaterThan(0);

    // VERIFY: Thermal system tracking temperature
    expect(finalThermal.hottestComponent).toBe('reactor-thermal');
  });

  it('should demonstrate multi-ship universe simulation', () => {
    // Create universe
    const world = new World();
    world.addBody({
      id: 'moon',
      name: 'Moon',
      mass: 7.342e22,
      radius: 1737400,
      position: { x: 0, y: 0, z: 0 },
      velocity: { x: 0, y: 0, z: 0 },
      type: 'planet'
    });

    // Create two ships
    const ship1 = ShipTemplates.createFrigate(
      'frigate-alpha',
      { x: 0, y: 0, z: 1737400 + 100000 },
      { x: 1700, y: 0, z: 0 }
    );

    const ship2 = ShipTemplates.createFrigate(
      'frigate-beta',
      { x: 0, y: 0, z: 1737400 + 150000 },
      { x: 1650, y: 0, z: 0 }
    );

    // Add to simulation
    const integrated1 = new IntegratedShip({
      mass: ship1.mass,
      radius: 10,
      position: ship1.position,
      velocity: ship1.velocity
    }, world);

    const integrated2 = new IntegratedShip({
      mass: ship2.mass,
      radius: 10,
      position: ship2.position,
      velocity: ship2.velocity
    }, world);

    const sim = new SimulationController(world);
    sim.addShip(integrated1);
    sim.addShip(integrated2);

    // Run simulation
    // Initialize ships first
    ship1.update(1);
    ship2.update(1);

    for (let i = 0; i < 100; i++) {
      sim.update(1);
      ship1.update(1);
      ship2.update(1);
    }

    // VERIFY: Both ships functioning
    const status1 = ship1.getStatus();
    const status2 = ship2.getStatus();

    expect(status1.power.generation).toBeGreaterThan(0);
    expect(status2.power.generation).toBeGreaterThan(0);
    expect(status1.lifeSupport.crewHealthy).toBe(2);
    expect(status2.lifeSupport.crewHealthy).toBe(2);
  });

  it('should provide complete ship status telemetry', () => {
    const ship = ShipTemplates.createFrigate(
      'frigate-5',
      { x: 0, y: 0, z: 2000000 },
      { x: 0, y: 0, z: 0 }
    );

    ship.update(1);

    const status = ship.getStatus();

    // VERIFY: All telemetry available
    expect(status.ship.id).toBe('frigate-5');
    expect(status.ship.name).toBe('Frigate');
    expect(status.ship.class).toBe('Frigate-class');

    expect(status.power).toHaveProperty('generation');
    expect(status.power).toHaveProperty('consumption');
    expect(status.power).toHaveProperty('batteryCharge');
    expect(status.power).toHaveProperty('brownout');

    expect(status.thermal).toHaveProperty('averageTemp');
    expect(status.thermal).toHaveProperty('hottestComponent');

    expect(status.damage).toHaveProperty('totalSystems');
    expect(status.damage).toHaveProperty('operational');
    expect(status.damage).toHaveProperty('criticalFailures');

    expect(status.lifeSupport).toHaveProperty('crewHealthy');
    expect(status.lifeSupport).toHaveProperty('crewTotal');

    expect(status.combat).toHaveProperty('tracks');
  });
});
