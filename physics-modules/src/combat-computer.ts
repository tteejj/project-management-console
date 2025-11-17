/**
 * Combat Computer System
 *
 * Sensor fusion, threat assessment, fire control
 */

import { Vector3, VectorMath } from './math-utils';
import { SensorType } from './sensors';
import { LeadCalculator, LeadSolution } from './targeting';

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

export enum ThreatLevel {
  NONE = 'none',
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  CRITICAL = 'critical'
}

export enum TargetPriority {
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
  lastUpdate: number;          // Time since last sensor contact
  confidence: number;           // 0-1
  threatLevel: ThreatLevel;
  priority: TargetPriority;
  sensorTypes: string[];        // Which sensors see this target
}

export interface FireSolution {
  targetId: string;
  aimPoint: Vector3;
  aimDirection: Vector3;
  timeToImpact: number;
  leadAngle: number;            // degrees
  valid: boolean;
}

export interface CombatComputerConfig {
  position: Vector3;
  velocity: Vector3;
}

interface WeaponState {
  id: string;
  cooldown: number;             // seconds
  lastFired: number;            // seconds since last fire
}

/**
 * Combat Computer
 */
export class CombatComputer {
  private ownPosition: Vector3;
  private ownVelocity: Vector3;
  private tracks: Map<string, Track> = new Map();
  private weapons: Map<string, WeaponState> = new Map();

  // Constants
  private readonly TRACK_TIMEOUT = 30;           // seconds
  private readonly FUSION_RADIUS = 500;          // m (contacts within this are same target)
  private readonly HIGH_THREAT_RANGE = 10000;    // m
  private readonly CRITICAL_THREAT_RANGE = 5000; // m

  constructor(config: CombatComputerConfig) {
    this.ownPosition = config.position;
    this.ownVelocity = config.velocity;
  }

  /**
   * Update combat computer
   */
  update(dt: number): void {
    // Age tracks
    for (const track of this.tracks.values()) {
      track.lastUpdate += dt;
    }

    // Remove stale tracks
    for (const [id, track] of this.tracks.entries()) {
      if (track.lastUpdate > this.TRACK_TIMEOUT) {
        this.tracks.delete(id);
      }
    }

    // Update weapon cooldowns
    for (const weapon of this.weapons.values()) {
      weapon.lastFired += dt;
    }
  }

  /**
   * Update sensor contacts (sensor fusion)
   */
  updateSensorContacts(contacts: CombatSensorContact[]): void {
    // Group contacts by proximity (fusion)
    const fusedContacts = this.fuseContacts(contacts);

    for (const contact of fusedContacts) {
      let track = this.tracks.get(contact.targetId);

      if (!track) {
        // New track
        track = {
          targetId: contact.targetId,
          position: contact.position,
          velocity: contact.velocity || { x: 0, y: 0, z: 0 },
          lastUpdate: 0,
          confidence: contact.signalStrength,
          threatLevel: ThreatLevel.NONE,
          priority: TargetPriority.LOW,
          sensorTypes: [contact.sensorType]
        };
        this.tracks.set(contact.targetId, track);
      } else {
        // Update existing track
        track.position = contact.position;
        track.velocity = contact.velocity || track.velocity;
        track.lastUpdate = 0;
        track.confidence = Math.min(1, track.confidence * 0.9 + contact.signalStrength * 0.1);

        if (!track.sensorTypes.includes(contact.sensorType)) {
          track.sensorTypes.push(contact.sensorType);
          // Multi-sensor confirmation increases confidence
          track.confidence = Math.min(1, track.confidence * 1.2);
        }
      }

      // Update threat assessment
      this.assessThreat(track);
    }
  }

  /**
   * Fuse nearby contacts into single tracks
   */
  private fuseContacts(contacts: CombatSensorContact[]): CombatSensorContact[] {
    if (contacts.length === 0) return [];

    const fused: CombatSensorContact[] = [];
    const used = new Set<number>();

    for (let i = 0; i < contacts.length; i++) {
      if (used.has(i)) continue;

      const cluster: CombatSensorContact[] = [contacts[i]];
      used.add(i);

      // Find nearby contacts
      for (let j = i + 1; j < contacts.length; j++) {
        if (used.has(j)) continue;

        const dist = VectorMath.magnitude(
          VectorMath.subtract(contacts[i].position, contacts[j].position)
        );

        if (dist < this.FUSION_RADIUS) {
          cluster.push(contacts[j]);
          used.add(j);
        }
      }

      // Average cluster to create fused contact
      if (cluster.length > 1) {
        const avgPos = { x: 0, y: 0, z: 0 };
        const avgVel = { x: 0, y: 0, z: 0 };
        let avgSignal = 0;

        for (const c of cluster) {
          avgPos.x += c.position.x;
          avgPos.y += c.position.y;
          avgPos.z += c.position.z;
          if (c.velocity) {
            avgVel.x += c.velocity.x;
            avgVel.y += c.velocity.y;
            avgVel.z += c.velocity.z;
          }
          avgSignal += c.signalStrength;
        }

        fused.push({
          targetId: cluster[0].targetId,
          position: {
            x: avgPos.x / cluster.length,
            y: avgPos.y / cluster.length,
            z: avgPos.z / cluster.length
          },
          velocity: {
            x: avgVel.x / cluster.length,
            y: avgVel.y / cluster.length,
            z: avgVel.z / cluster.length
          },
          signalStrength: avgSignal / cluster.length,
          sensorType: 'fused'
        });
      } else {
        fused.push(cluster[0]);
      }
    }

    return fused;
  }

  /**
   * Assess threat level for track
   */
  private assessThreat(track: Track): void {
    const relPos = VectorMath.subtract(track.position, this.ownPosition);
    const range = VectorMath.magnitude(relPos);

    // Calculate closure rate
    const relVel = VectorMath.subtract(track.velocity, this.ownVelocity);
    const closureRate = -VectorMath.dot(relVel, VectorMath.normalize(relPos));

    // Threat based on range and closure
    if (range < this.CRITICAL_THREAT_RANGE && closureRate > 100) {
      track.threatLevel = ThreatLevel.CRITICAL;
      track.priority = TargetPriority.CRITICAL;
    } else if (range < this.HIGH_THREAT_RANGE && closureRate > 50) {
      track.threatLevel = ThreatLevel.HIGH;
      track.priority = TargetPriority.HIGH;
    } else if (range < this.HIGH_THREAT_RANGE * 2) {
      track.threatLevel = ThreatLevel.MEDIUM;
      track.priority = TargetPriority.MEDIUM;
    } else {
      track.threatLevel = ThreatLevel.LOW;
      track.priority = TargetPriority.LOW;
    }
  }

  /**
   * Get fire solution for target
   */
  getFireSolution(targetId: string, projectileSpeed: number): FireSolution | null {
    const track = this.tracks.get(targetId);
    if (!track) return null;

    const solution = LeadCalculator.calculateLead({
      shooterPosition: this.ownPosition,
      shooterVelocity: this.ownVelocity,
      targetPosition: track.position,
      targetVelocity: track.velocity || { x: 0, y: 0, z: 0 },
      projectileSpeed
    });

    if (!solution) return null;

    const aimDirection = VectorMath.normalize(VectorMath.subtract(solution.aimPoint, this.ownPosition));

    return {
      targetId,
      aimPoint: solution.aimPoint,
      aimDirection,
      timeToImpact: solution.timeToImpact,
      leadAngle: solution.leadAngle,
      valid: true
    };
  }

  /**
   * Get all tracks
   */
  getTracks(): Track[] {
    return Array.from(this.tracks.values());
  }

  /**
   * Get prioritized target list
   */
  getPrioritizedTargets(): Track[] {
    const tracks = this.getTracks();
    return tracks.sort((a, b) => {
      // Sort by priority (descending), then by range (ascending)
      if (a.priority !== b.priority) {
        return b.priority - a.priority;
      }
      const rangeA = VectorMath.magnitude(VectorMath.subtract(a.position, this.ownPosition));
      const rangeB = VectorMath.magnitude(VectorMath.subtract(b.position, this.ownPosition));
      return rangeA - rangeB;
    });
  }

  /**
   * Register weapon
   */
  registerWeapon(weaponId: string, cooldown: number): void {
    this.weapons.set(weaponId, {
      id: weaponId,
      cooldown,
      lastFired: cooldown  // Start ready
    });
  }

  /**
   * Fire weapon (update cooldown)
   */
  fireWeapon(weaponId: string): boolean {
    const weapon = this.weapons.get(weaponId);
    if (!weapon) return false;

    if (weapon.lastFired < weapon.cooldown) return false;

    weapon.lastFired = 0;
    return true;
  }

  /**
   * Check if weapon is ready
   */
  isWeaponReady(weaponId: string): boolean {
    const weapon = this.weapons.get(weaponId);
    if (!weapon) return false;
    return weapon.lastFired >= weapon.cooldown;
  }

  /**
   * Assign weapon to target
   */
  assignWeapon(weaponId: string, targetId: string): boolean {
    const weapon = this.weapons.get(weaponId);
    if (!weapon) return false;

    const track = this.tracks.get(targetId);
    if (!track) return false;

    // Assignment successful (actual firing is separate)
    return true;
  }

  /**
   * Update own position and velocity
   */
  updateOwnShip(position: Vector3, velocity: Vector3): void {
    this.ownPosition = position;
    this.ownVelocity = velocity;
  }
}
