"use strict";
/**
 * Combat Computer System
 *
 * Sensor fusion, threat assessment, fire control
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.CombatComputer = exports.TargetPriority = exports.ThreatLevel = void 0;
const math_utils_1 = require("./math-utils");
const targeting_1 = require("./targeting");
var ThreatLevel;
(function (ThreatLevel) {
    ThreatLevel["NONE"] = "none";
    ThreatLevel["LOW"] = "low";
    ThreatLevel["MEDIUM"] = "medium";
    ThreatLevel["HIGH"] = "high";
    ThreatLevel["CRITICAL"] = "critical";
})(ThreatLevel || (exports.ThreatLevel = ThreatLevel = {}));
var TargetPriority;
(function (TargetPriority) {
    TargetPriority[TargetPriority["IGNORE"] = 0] = "IGNORE";
    TargetPriority[TargetPriority["LOW"] = 1] = "LOW";
    TargetPriority[TargetPriority["MEDIUM"] = 2] = "MEDIUM";
    TargetPriority[TargetPriority["HIGH"] = 3] = "HIGH";
    TargetPriority[TargetPriority["CRITICAL"] = 4] = "CRITICAL";
})(TargetPriority || (exports.TargetPriority = TargetPriority = {}));
/**
 * Combat Computer
 */
class CombatComputer {
    constructor(config) {
        this.tracks = new Map();
        this.weapons = new Map();
        // Constants
        this.TRACK_TIMEOUT = 30; // seconds
        this.FUSION_RADIUS = 500; // m (contacts within this are same target)
        this.HIGH_THREAT_RANGE = 10000; // m
        this.CRITICAL_THREAT_RANGE = 5000; // m
        this.ownPosition = config.position;
        this.ownVelocity = config.velocity;
    }
    /**
     * Update combat computer
     */
    update(dt) {
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
    updateSensorContacts(contacts) {
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
            }
            else {
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
    fuseContacts(contacts) {
        if (contacts.length === 0)
            return [];
        const fused = [];
        const used = new Set();
        for (let i = 0; i < contacts.length; i++) {
            if (used.has(i))
                continue;
            const cluster = [contacts[i]];
            used.add(i);
            // Find nearby contacts
            for (let j = i + 1; j < contacts.length; j++) {
                if (used.has(j))
                    continue;
                const dist = math_utils_1.VectorMath.magnitude(math_utils_1.VectorMath.subtract(contacts[i].position, contacts[j].position));
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
            }
            else {
                fused.push(cluster[0]);
            }
        }
        return fused;
    }
    /**
     * Assess threat level for track
     */
    assessThreat(track) {
        const relPos = math_utils_1.VectorMath.subtract(track.position, this.ownPosition);
        const range = math_utils_1.VectorMath.magnitude(relPos);
        // Calculate closure rate
        const relVel = math_utils_1.VectorMath.subtract(track.velocity, this.ownVelocity);
        const closureRate = -math_utils_1.VectorMath.dot(relVel, math_utils_1.VectorMath.normalize(relPos));
        // Threat based on range and closure
        if (range < this.CRITICAL_THREAT_RANGE && closureRate > 100) {
            track.threatLevel = ThreatLevel.CRITICAL;
            track.priority = TargetPriority.CRITICAL;
        }
        else if (range < this.HIGH_THREAT_RANGE && closureRate > 50) {
            track.threatLevel = ThreatLevel.HIGH;
            track.priority = TargetPriority.HIGH;
        }
        else if (range < this.HIGH_THREAT_RANGE * 2) {
            track.threatLevel = ThreatLevel.MEDIUM;
            track.priority = TargetPriority.MEDIUM;
        }
        else {
            track.threatLevel = ThreatLevel.LOW;
            track.priority = TargetPriority.LOW;
        }
    }
    /**
     * Get fire solution for target
     */
    getFireSolution(targetId, projectileSpeed) {
        const track = this.tracks.get(targetId);
        if (!track)
            return null;
        const solution = targeting_1.LeadCalculator.calculateLead({
            shooterPosition: this.ownPosition,
            shooterVelocity: this.ownVelocity,
            targetPosition: track.position,
            targetVelocity: track.velocity || { x: 0, y: 0, z: 0 },
            projectileSpeed
        });
        if (!solution)
            return null;
        const aimDirection = math_utils_1.VectorMath.normalize(math_utils_1.VectorMath.subtract(solution.aimPoint, this.ownPosition));
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
    getTracks() {
        return Array.from(this.tracks.values());
    }
    /**
     * Get prioritized target list
     */
    getPrioritizedTargets() {
        const tracks = this.getTracks();
        return tracks.sort((a, b) => {
            // Sort by priority (descending), then by range (ascending)
            if (a.priority !== b.priority) {
                return b.priority - a.priority;
            }
            const rangeA = math_utils_1.VectorMath.magnitude(math_utils_1.VectorMath.subtract(a.position, this.ownPosition));
            const rangeB = math_utils_1.VectorMath.magnitude(math_utils_1.VectorMath.subtract(b.position, this.ownPosition));
            return rangeA - rangeB;
        });
    }
    /**
     * Register weapon
     */
    registerWeapon(weaponId, cooldown) {
        this.weapons.set(weaponId, {
            id: weaponId,
            cooldown,
            lastFired: cooldown // Start ready
        });
    }
    /**
     * Fire weapon (update cooldown)
     */
    fireWeapon(weaponId) {
        const weapon = this.weapons.get(weaponId);
        if (!weapon)
            return false;
        if (weapon.lastFired < weapon.cooldown)
            return false;
        weapon.lastFired = 0;
        return true;
    }
    /**
     * Check if weapon is ready
     */
    isWeaponReady(weaponId) {
        const weapon = this.weapons.get(weaponId);
        if (!weapon)
            return false;
        return weapon.lastFired >= weapon.cooldown;
    }
    /**
     * Assign weapon to target
     */
    assignWeapon(weaponId, targetId) {
        const weapon = this.weapons.get(weaponId);
        if (!weapon)
            return false;
        const track = this.tracks.get(targetId);
        if (!track)
            return false;
        // Assignment successful (actual firing is separate)
        return true;
    }
    /**
     * Update own position and velocity
     */
    updateOwnShip(position, velocity) {
        this.ownPosition = position;
        this.ownVelocity = velocity;
    }
}
exports.CombatComputer = CombatComputer;
//# sourceMappingURL=combat-computer.js.map