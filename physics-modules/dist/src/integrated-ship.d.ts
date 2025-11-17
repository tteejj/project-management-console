/**
 * Integrated Ship - Ship-World Bridge
 *
 * Connects spacecraft physics to world simulation
 * Makes ship a first-class celestial body that can be sensed, targeted, and collided with
 */
import { Vector3, Quaternion } from './math-utils';
import { World, CelestialBody } from './world';
export interface ShipConfiguration {
    mass: number;
    radius: number;
    position: Vector3;
    velocity: Vector3;
    orientation?: Quaternion;
    angularVelocity?: Vector3;
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
export declare class IntegratedShip {
    readonly id: string;
    private spacecraftPhysics;
    private worldBody;
    private world;
    private hullDamageSystem?;
    private collisionHistory;
    private eventListeners;
    private static shipCounter;
    constructor(config: ShipConfiguration, world: World);
    /**
     * Main update loop - integrates ship with world
     */
    update(dt: number): void;
    /**
     * Sync spacecraft physics state to world body
     */
    private syncToWorldBody;
    /**
     * Check for collisions with world bodies
     */
    private checkCollisions;
    /**
     * Handle collision with another body
     */
    private handleCollision;
    /**
     * Apply force to ship
     */
    applyForce(force: Vector3): void;
    /**
     * Apply impulse to ship (instantaneous velocity change)
     */
    applyImpulse(impulse: Vector3): void;
    /**
     * Get ship position
     */
    getPosition(): Vector3;
    /**
     * Get ship velocity
     */
    getVelocity(): Vector3;
    /**
     * Get hull integrity (0-1)
     */
    getHullIntegrity(): number;
    /**
     * Get collision history
     */
    getCollisionHistory(): CollisionEvent[];
    /**
     * Get world body
     */
    getWorldBody(): CelestialBody;
    /**
     * Event listener
     */
    on(event: string, callback: EventCallback): void;
    /**
     * Emit event
     */
    private emit;
    /**
     * Calculate moment of inertia (sphere approximation)
     */
    private calculateMomentOfInertia;
    /**
     * Calculate radar cross section
     */
    private calculateRCS;
    /**
     * Cleanup
     */
    destroy(): void;
}
/**
 * Simulation controller - manages world and all ships
 */
export declare class SimulationController {
    private world;
    private ships;
    private simulationTime;
    constructor(world: World);
    /**
     * Add ship to simulation
     */
    addShip(config: ShipConfiguration): IntegratedShip;
    /**
     * Remove ship from simulation
     */
    removeShip(shipId: string): void;
    /**
     * Main update loop
     */
    update(dt: number): void;
    /**
     * Check collisions between ships
     */
    private checkShipCollisions;
    /**
     * Get simulation time
     */
    getSimulationTime(): number;
    /**
     * Get all ships
     */
    getShips(): IntegratedShip[];
    /**
     * Get ship by ID
     */
    getShip(id: string): IntegratedShip | undefined;
}
export {};
//# sourceMappingURL=integrated-ship.d.ts.map