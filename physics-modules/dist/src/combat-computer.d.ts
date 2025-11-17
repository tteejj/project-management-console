/**
 * Combat Computer System
 *
 * Sensor fusion, threat assessment, fire control
 */
import { Vector3 } from './math-utils';
import { SensorType } from './sensors';
/**
 * Combat sensor contact - processed sensor data for fire control
 * (Different from raw SensorContact which has range/bearing)
 */
export interface CombatSensorContact {
    targetId: string;
    position: Vector3;
    velocity?: Vector3;
    signalStrength: number;
    sensorType: SensorType | 'fused';
}
export declare enum ThreatLevel {
    NONE = "none",
    LOW = "low",
    MEDIUM = "medium",
    HIGH = "high",
    CRITICAL = "critical"
}
export declare enum TargetPriority {
    IGNORE = 0,
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3,
    CRITICAL = 4
}
export interface Track {
    targetId: string;
    position: Vector3;
    velocity: Vector3;
    lastUpdate: number;
    confidence: number;
    threatLevel: ThreatLevel;
    priority: TargetPriority;
    sensorTypes: string[];
}
export interface FireSolution {
    targetId: string;
    aimPoint: Vector3;
    aimDirection: Vector3;
    timeToImpact: number;
    leadAngle: number;
    valid: boolean;
}
export interface CombatComputerConfig {
    position: Vector3;
    velocity: Vector3;
}
/**
 * Combat Computer
 */
export declare class CombatComputer {
    private ownPosition;
    private ownVelocity;
    private tracks;
    private weapons;
    private readonly TRACK_TIMEOUT;
    private readonly FUSION_RADIUS;
    private readonly HIGH_THREAT_RANGE;
    private readonly CRITICAL_THREAT_RANGE;
    constructor(config: CombatComputerConfig);
    /**
     * Update combat computer
     */
    update(dt: number): void;
    /**
     * Update sensor contacts (sensor fusion)
     */
    updateSensorContacts(contacts: CombatSensorContact[]): void;
    /**
     * Fuse nearby contacts into single tracks
     */
    private fuseContacts;
    /**
     * Assess threat level for track
     */
    private assessThreat;
    /**
     * Get fire solution for target
     */
    getFireSolution(targetId: string, projectileSpeed: number): FireSolution | null;
    /**
     * Get all tracks
     */
    getTracks(): Track[];
    /**
     * Get prioritized target list
     */
    getPrioritizedTargets(): Track[];
    /**
     * Register weapon
     */
    registerWeapon(weaponId: string, cooldown: number): void;
    /**
     * Fire weapon (update cooldown)
     */
    fireWeapon(weaponId: string): boolean;
    /**
     * Check if weapon is ready
     */
    isWeaponReady(weaponId: string): boolean;
    /**
     * Assign weapon to target
     */
    assignWeapon(weaponId: string, targetId: string): boolean;
    /**
     * Update own position and velocity
     */
    updateOwnShip(position: Vector3, velocity: Vector3): void;
}
//# sourceMappingURL=combat-computer.d.ts.map