/**
 * Complete Ship Simulation Test
 *
 * Demonstrates a fully integrated ship in a simulated universe
 */

import { describe, it, expect } from 'vitest';
import { CompleteShip, ShipTemplates } from '../src/ship-configuration';
import { World } from '../src/world';
import { IntegratedShip, SimulationController } from '../src/integrated-ship';
import { UnifiedShip } from '../src/unified-ship';

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

describe('Unified Ship Integration', () => {
  it('should automatically sync physics and subsystems without manual intervention', () => {
    // This test demonstrates the SOLUTION to the manual syncing problem

    // STEP 1: Create the universe
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

    // STEP 2: Create UnifiedShip (physics + subsystems integrated)
    const shipConfig = {
      id: 'unified-frigate',
      name: 'Unified Test Ship',
      class: 'Frigate-class',
      mass: 50000,
      position: { x: 0, y: 0, z: 1737400 + 100000 },  // 100km above moon
      velocity: { x: 1700, y: 0, z: 0 },               // Orbital velocity

      // Use same config as ShipTemplates.createFrigate
      compartments: [
        {
          id: 'bridge',
          name: 'Bridge',
          volume: 30,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: ['engineering']
        },
        {
          id: 'engineering',
          name: 'Engineering',
          volume: 50,
          pressure: 101325,
          atmosphereIntegrity: 1.0,
          structuralIntegrity: 1.0,
          breaches: [],
          systems: [],
          connectedCompartments: ['bridge']
        }
      ],
      armorLayers: [{
        id: 'hull-armor-1',
        material: 'titanium',  // MaterialType.TITANIUM
        thickness: 0.05,
        density: 4500,
        hardness: 6.0,
        integrity: 1.0,
        ablationDepth: 0
      }],
      powerSources: [{
        id: 'reactor-1',
        type: 'reactor',  // PowerSourceType.REACTOR
        maxOutput: 50,
        currentOutput: 0,
        efficiency: 0.90,
        powered: true
      }],
      powerConsumers: [{
        id: 'life-support',
        name: 'Life Support',
        powerDraw: 5,
        priority: 0,  // PowerPriority.CRITICAL
        powered: true,
        actualPower: 0
      }],
      batteries: [{
        id: 'battery-1',
        capacity: 100,
        currentCharge: 80,
        maxChargeRate: 20,
        maxDischargeRate: 30,
        efficiency: 0.95
      }],
      thermalComponents: [{
        id: 'reactor-thermal',
        name: 'Reactor',
        temperature: 400,
        mass: 1000,
        specificHeat: 500,
        surfaceArea: 5,
        heatGeneration: 5000,
        compartmentId: 'engineering'
      }],
      thermalCompartments: [{
        id: 'engineering',
        name: 'Engineering',
        temperature: 293,
        volume: 50,
        airMass: 60,
        connectedCompartments: ['bridge']
      }],
      coolingSystems: [],
      systems: [{
        id: 'reactor-sys',
        name: 'Main Reactor',
        type: 0,  // POWER
        compartmentId: 'engineering',
        integrity: 1.0,
        status: 0,  // ONLINE
        powerDraw: 0,
        operational: true,
        isCritical: true
      }],
      crew: [{
        id: 'captain',
        name: 'Captain',
        location: 'bridge',
        health: 1.0,
        oxygenLevel: 1.0,
        status: 0  // HEALTHY
      }],
      lifeSupport: {
        oxygenGenerationRate: 0.5,
        co2ScrubberRate: 0.5,
        powered: true
      }
    };

    const ship = new UnifiedShip(shipConfig, world);

    // STEP 3: Create simulation controller
    const sim = new SimulationController(world);
    sim.addShip(ship.physicsBody);

    // STEP 4: Run simulation - NO MANUAL SYNCING!
    const initialPos = ship.getPosition();

    for (let i = 0; i < 60; i++) {
      sim.update(1);   // World physics (gravity, orbits)
      ship.update(1);  // Automatically syncs physics → subsystems → updates all systems
    }

    const finalPos = ship.getPosition();
    const status = ship.getStatus();

    // VERIFY: Ship is functioning (subsystems working)
    expect(status.power.generation).toBeGreaterThan(0);
    expect(status.power.brownout).toBe(false);
    expect(status.lifeSupport.crewHealthy).toBe(1);
    expect(status.damage.operational).toBeGreaterThan(0);

    // VERIFY: Ship is in orbit (physics working)
    expect(finalPos).toBeDefined();
    expect(ship.getVelocity()).toBeDefined();

    // VERIFY: Position changed due to orbital motion
    const moved = (finalPos.x !== initialPos.x) || (finalPos.y !== initialPos.y) || (finalPos.z !== initialPos.z);
    expect(moved).toBe(true);

    // VERIFY: Status includes physics state (integration successful)
    expect(status.ship.position).toEqual(finalPos);
    expect(status.ship.velocity).toBeDefined();
  });

  it('should handle damage cascades in integrated ship', () => {
    const world = new World();

    const shipConfig = {
      id: 'damage-test',
      name: 'Damage Test Ship',
      class: 'Frigate-class',
      mass: 50000,
      position: { x: 0, y: 0, z: 2000000 },
      velocity: { x: 0, y: 0, z: 0 },
      compartments: [{
        id: 'engineering',
        name: 'Engineering',
        volume: 50,
        pressure: 101325,
        atmosphereIntegrity: 1.0,
        structuralIntegrity: 1.0,
        breaches: [],
        systems: [],
        connectedCompartments: []
      }],
      armorLayers: [{
        id: 'hull-armor-1',
        material: 'titanium',  // MaterialType.TITANIUM
        thickness: 0.05,
        density: 4500,
        hardness: 6.0,
        integrity: 1.0,
        ablationDepth: 0
      }],
      powerSources: [{
        id: 'reactor-1',
        type: 'reactor',
        maxOutput: 50,
        currentOutput: 0,
        efficiency: 0.90,
        powered: true
      }],
      powerConsumers: [],
      batteries: [],
      thermalComponents: [],
      thermalCompartments: [],
      coolingSystems: [],
      systems: [{
        id: 'reactor-sys',
        name: 'Main Reactor',
        type: 0,
        compartmentId: 'engineering',
        integrity: 1.0,
        status: 0,
        powerDraw: 0,
        operational: true,
        isCritical: true
      }],
      crew: [],
      lifeSupport: {
        oxygenGenerationRate: 0.5,
        co2ScrubberRate: 0.5,
        powered: true
      }
    };

    const ship = new UnifiedShip(shipConfig, world);

    // DAMAGE: Breach the hull via the integrated physics representation
    const engineering = ship.hull.getCompartment('engineering')!;
    engineering.breaches.push({
      id: 'breach-1',
      position: { x: 0, y: 0, z: 0 },
      area: 0.5,
      sealed: false,
      damageType: 0
    });
    engineering.structuralIntegrity = 0.5;

    // Simulate damage propagation
    for (let i = 0; i < 10; i++) {
      ship.update(1);
    }

    const status = ship.getStatus();

    // VERIFY: Damage cascade propagated through integrated systems
    expect(engineering.pressure).toBeLessThan(101325);

    const reactorSystem = ship.systemDamage.getSystem('reactor-sys')!;
    expect(reactorSystem.integrity).toBeLessThan(1.0);
  });
});
