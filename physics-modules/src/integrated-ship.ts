/**
 * Integrated Ship - Ship-World Bridge
 *
 * Connects spacecraft physics to world simulation
 * Makes ship a first-class celestial body that can be sensed, targeted, and collided with
 */

import { Vector3, VectorMath, Quaternion, QuaternionMath } from './math-utils';
import { World, CelestialBody } from './world';
import { HullStructure, HullDamageSystem, DamageType } from './hull-damage';
import { CollisionDetector, CollisionResult, CollisionResponse, PhysicsBody } from './collision';
import { SpacecraftPhysics } from './spacecraft-physics';

export interface ShipConfiguration {
  mass: number;
  radius: number;
  position: Vector3;
  velocity: Vector3;
  orientation?: Quaternion;
  angularVelocity?: Vector3;

  // Optional hull configuration
  hullConfig?: {
    compartments: any[];
    armorLayers: any[];
  };
}

export interface CollisionEvent {
  timestamp: number;
  otherBody: CelestialBody;
  point: Vector3;
  normal: Vector3;
  relativeVelocity: number;
  damageApplied: number;
}

type EventCallback = (...args: any[]) => void;

/**
 * Integrated ship that exists in both spacecraft physics and world physics
 */
export class IntegratedShip {
  public readonly id: string;

  private spacecraftPhysics: SpacecraftPhysics;
  private worldBody: CelestialBody;
  private world: World;

  private hullDamageSystem?: HullDamageSystem;
  private collisionHistory: CollisionEvent[] = [];
  private eventListeners: Map<string, EventCallback[]> = new Map();

  private static shipCounter = 0;

  constructor(config: ShipConfiguration, world: World) {
    if (config.mass <= 0) {
      throw new Error('Ship mass must be positive');
    }

    this.id = `ship-${IntegratedShip.shipCounter++}`;
    this.world = world;

    // Create spacecraft physics
    this.spacecraftPhysics = new SpacecraftPhysics({
      mass: config.mass,
      momentOfInertia: this.calculateMomentOfInertia(config.mass, config.radius),
      position: config.position,
      velocity: config.velocity,
      orientation: config.orientation || { w: 1, x: 0, y: 0, z: 0 },
      angularVelocity: config.angularVelocity || { x: 0, y: 0, z: 0 }
    });

    // Create world body (ship as celestial body)
    this.worldBody = {
      id: this.id,
      name: `Ship ${this.id}`,
      type: 'satellite',  // Ships are satellites in the celestial body system
      mass: config.mass,
      radius: config.radius,
      position: { ...config.position },
      velocity: { ...config.velocity },
      radarCrossSection: this.calculateRCS(config.radius),
      thermalSignature: 300,  // Ships are warm (life support, electronics)
      collisionDamage: config.mass / 1000,
      hardness: 400
    };

    // Add to world
    this.world.addBody(this.worldBody);

    // Initialize hull damage system if config provided
    if (config.hullConfig) {
      const hull = new HullStructure(config.hullConfig);
      this.hullDamageSystem = new HullDamageSystem(hull);
    }
  }

  /**
   * Main update loop - integrates ship with world
   */
  update(dt: number): void {
    // PHASE 1: Get gravity from world
    const gravity = this.world.getGravityAt(
      this.spacecraftPhysics.getPosition(),
      this.id  // Exclude self from gravity calculation
    );

    // PHASE 2: Apply gravity to spacecraft
    const gravityForce = VectorMath.scale(gravity, this.spacecraftPhysics.getMass());
    this.spacecraftPhysics.applyForce(gravityForce);

    // PHASE 3: Update spacecraft physics
    this.spacecraftPhysics.update(dt);

    // PHASE 4: Sync to world body
    this.syncToWorldBody();

    // PHASE 5: Check for collisions
    this.checkCollisions();

    // PHASE 6: Update damage systems
    if (this.hullDamageSystem) {
      this.hullDamageSystem.updatePressure(dt);
    }
  }

  /**
   * Sync spacecraft physics state to world body
   */
  private syncToWorldBody(): void {
    const position = this.spacecraftPhysics.getPosition();
    const velocity = this.spacecraftPhysics.getVelocity();

    this.worldBody.position = { ...position };
    this.worldBody.velocity = { ...velocity };
  }

  /**
   * Check for collisions with world bodies
   */
  private checkCollisions(): void {
    const bodies = this.world.getAllBodies();
    const shipPos = this.spacecraftPhysics.getPosition();
    const shipVel = this.spacecraftPhysics.getVelocity();

    for (const body of bodies) {
      // Skip self
      if (body.id === this.id) continue;

      // Detect collision
      const collision = CollisionDetector.detectSphereSphere(
        shipPos,
        this.worldBody.radius,
        body.position,
        body.radius
      );

      if (collision && collision.collided) {
        this.handleCollision(body, collision);
      }
    }
  }

  /**
   * Handle collision with another body using advanced collision response
   */
  private handleCollision(otherBody: CelestialBody, collision: CollisionResult): void {
    const shipPos = this.spacecraftPhysics.getPosition();
    const shipVel = this.spacecraftPhysics.getVelocity();
    const shipMass = this.spacecraftPhysics.getMass();

    // Create physics bodies for collision response
    const shipBody: PhysicsBody = {
      position: shipPos,
      velocity: shipVel,
      angularVelocity: this.spacecraftPhysics.getAngularVelocity(),
      mass: shipMass,
      momentOfInertia: this.spacecraftPhysics.getMomentOfInertia(),
      restitution: 0.3,  // Semi-elastic (metal hull)
      friction: 0.5,     // Moderate friction
      isStatic: false
    };

    const otherBodyPhysics: PhysicsBody = {
      position: otherBody.position,
      velocity: otherBody.velocity,
      angularVelocity: { x: 0, y: 0, z: 0 },
      mass: otherBody.mass,
      momentOfInertia: { x: otherBody.mass, y: otherBody.mass, z: otherBody.mass },
      restitution: 0.2,  // Rock/asteroid is less elastic
      friction: 0.7,     // Rough surface
      isStatic: otherBody.type === 'planet' || otherBody.type === 'moon'  // Planets are immovable
    };

    // Calculate collision response using impulse-based physics
    const response = CollisionResponse.resolve(shipBody, otherBodyPhysics, collision);

    // Apply linear impulse to ship velocity
    CollisionResponse.applyImpulse(shipBody, response.linearImpulse, response.angularImpulseA);
    this.spacecraftPhysics.setVelocity(shipBody.velocity);

    // Apply angular impulse if available
    if (response.angularImpulseA) {
      const newAngularVel = VectorMath.add(
        this.spacecraftPhysics.getAngularVelocity(),
        response.angularImpulseA
      );
      this.spacecraftPhysics.setAngularVelocity(newAngularVel);
    }

    // Separate penetrating bodies
    CollisionResponse.separateBodies(shipBody, otherBodyPhysics, collision);
    this.spacecraftPhysics.setPosition(shipBody.position);

    // Calculate relative velocity for damage
    const relVel = VectorMath.subtract(shipVel, otherBody.velocity);
    const relSpeed = VectorMath.magnitude(relVel);

    // Apply damage based on impact energy
    let damageApplied = 0;
    if (this.hullDamageSystem) {
      // Use impact energy from collision response
      const impactEnergy = response.impactEnergy;
      const damageScale = Math.min(1.0, impactEnergy / 1000000);  // Scale to 0-1 (1 MJ = full damage)

      const impactResult = this.hullDamageSystem.processImpact({
        position: collision.point,
        velocity: relVel,
        mass: otherBody.mass * 0.1,  // Effective mass
        damageType: DamageType.COLLISION,
        impactAngle: 0
      });
      damageApplied = impactResult.damageApplied * damageScale;
    }

    // Record collision event
    const event: CollisionEvent = {
      timestamp: Date.now(),
      otherBody,
      point: collision.point,
      normal: collision.normal,
      relativeVelocity: relSpeed,
      damageApplied
    };

    this.collisionHistory.push(event);

    // Emit event with collision response data
    this.emit('collision', {
      ...event,
      impactEnergy: response.impactEnergy,
      separationVelocity: response.separationVelocity
    });
  }

  /**
   * Apply force to ship
   */
  applyForce(force: Vector3): void {
    this.spacecraftPhysics.applyForce(force);
  }

  /**
   * Apply impulse to ship (instantaneous velocity change)
   */
  applyImpulse(impulse: Vector3): void {
    const velocityChange = VectorMath.scale(impulse, 1 / this.spacecraftPhysics.getMass());
    const newVelocity = VectorMath.add(
      this.spacecraftPhysics.getVelocity(),
      velocityChange
    );
    this.spacecraftPhysics.setVelocity(newVelocity);
  }

  /**
   * Get ship position
   */
  getPosition(): Vector3 {
    return this.spacecraftPhysics.getPosition();
  }

  /**
   * Get ship velocity
   */
  getVelocity(): Vector3 {
    return this.spacecraftPhysics.getVelocity();
  }

  /**
   * Get hull integrity (0-1)
   */
  getHullIntegrity(): number {
    if (!this.hullDamageSystem) return 1.0;

    const integrity = this.hullDamageSystem.getHull().getOverallIntegrity();
    return integrity.structural;
  }

  /**
   * Get collision history
   */
  getCollisionHistory(): CollisionEvent[] {
    return [...this.collisionHistory];
  }

  /**
   * Get world body
   */
  getWorldBody(): CelestialBody {
    return this.worldBody;
  }

  /**
   * Event listener
   */
  on(event: string, callback: EventCallback): void {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    this.eventListeners.get(event)!.push(callback);
  }

  /**
   * Emit event
   */
  private emit(event: string, ...args: any[]): void {
    const listeners = this.eventListeners.get(event);
    if (listeners) {
      for (const callback of listeners) {
        callback(...args);
      }
    }
  }

  /**
   * Calculate moment of inertia (sphere approximation)
   */
  private calculateMomentOfInertia(mass: number, radius: number): Vector3 {
    const I = (2/5) * mass * radius * radius;
    return { x: I, y: I, z: I };
  }

  /**
   * Calculate radar cross section
   */
  private calculateRCS(radius: number): number {
    // RCS for sphere: π * r²
    return Math.PI * radius * radius;
  }

  /**
   * Cleanup
   */
  destroy(): void {
    this.world.removeBody(this.id);
  }
}

/**
 * Simulation controller - manages world and all ships
 */
export class SimulationController {
  private world: World;
  private ships: Map<string, IntegratedShip> = new Map();
  private simulationTime: number = 0;

  constructor(world: World) {
    this.world = world;
  }

  /**
   * Add ship to simulation
   */
  addShip(config: ShipConfiguration): IntegratedShip {
    const ship = new IntegratedShip(config, this.world);
    this.ships.set(ship.id, ship);
    return ship;
  }

  /**
   * Remove ship from simulation
   */
  removeShip(shipId: string): void {
    const ship = this.ships.get(shipId);
    if (ship) {
      ship.destroy();
      this.ships.delete(shipId);
    }
  }

  /**
   * Main update loop
   */
  update(dt: number): void {
    // PHASE 1: Update world (orbits, n-body)
    this.world.update(dt);

    // PHASE 2: Update all ships
    for (const ship of this.ships.values()) {
      ship.update(dt);
    }

    // PHASE 3: Check ship-ship collisions
    this.checkShipCollisions();

    // PHASE 4: Update simulation time
    this.simulationTime += dt;
  }

  /**
   * Check collisions between ships
   */
  private checkShipCollisions(): void {
    const shipArray = Array.from(this.ships.values());

    for (let i = 0; i < shipArray.length; i++) {
      for (let j = i + 1; j < shipArray.length; j++) {
        const ship1 = shipArray[i];
        const ship2 = shipArray[j];

        const collision = CollisionDetector.detectSphereSphere(
          ship1.getPosition(),
          ship1.getWorldBody().radius,
          ship2.getPosition(),
          ship2.getWorldBody().radius
        );

        if (collision && collision.collided) {
          // Create physics bodies for both ships
          const body1: PhysicsBody = {
            position: ship1.getPosition(),
            velocity: ship1.getVelocity(),
            mass: ship1.getWorldBody().mass,
            restitution: 0.3,
            friction: 0.5,
            isStatic: false
          };

          const body2: PhysicsBody = {
            position: ship2.getPosition(),
            velocity: ship2.getVelocity(),
            mass: ship2.getWorldBody().mass,
            restitution: 0.3,
            friction: 0.5,
            isStatic: false
          };

          // Calculate collision response
          const response = CollisionResponse.resolve(body1, body2, collision);

          // Apply impulses to both ships
          CollisionResponse.applyImpulse(body1, response.linearImpulse, response.angularImpulseA);
          CollisionResponse.applyImpulse(body2, VectorMath.scale(response.linearImpulse, -1), response.angularImpulseB);

          ship1['spacecraftPhysics'].setVelocity(body1.velocity);
          ship2['spacecraftPhysics'].setVelocity(body2.velocity);

          // Separate bodies
          CollisionResponse.separateBodies(body1, body2, collision);
          ship1['spacecraftPhysics'].setPosition(body1.position);
          ship2['spacecraftPhysics'].setPosition(body2.position);
        }
      }
    }
  }

  /**
   * Get simulation time
   */
  getSimulationTime(): number {
    return this.simulationTime;
  }

  /**
   * Get all ships
   */
  getShips(): IntegratedShip[] {
    return Array.from(this.ships.values());
  }

  /**
   * Get ship by ID
   */
  getShip(id: string): IntegratedShip | undefined {
    return this.ships.get(id);
  }
}
