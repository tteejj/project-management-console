"use strict";
/**
 * System Damage Integration
 *
 * Links hull damage to system failures, handles cascading failures
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.SystemDamageManager = exports.SystemStatus = exports.SystemType = void 0;
var SystemType;
(function (SystemType) {
    SystemType["POWER"] = "power";
    SystemType["LIFE_SUPPORT"] = "life_support";
    SystemType["PROPULSION"] = "propulsion";
    SystemType["WEAPONS"] = "weapons";
    SystemType["SENSORS"] = "sensors";
    SystemType["CONTROL"] = "control";
    SystemType["THERMAL"] = "thermal";
    SystemType["UTILITY"] = "utility";
})(SystemType || (exports.SystemType = SystemType = {}));
var SystemStatus;
(function (SystemStatus) {
    SystemStatus["ONLINE"] = "online";
    SystemStatus["DEGRADED"] = "degraded";
    SystemStatus["OFFLINE"] = "offline";
    SystemStatus["DESTROYED"] = "destroyed";
})(SystemStatus || (exports.SystemStatus = SystemStatus = {}));
/**
 * System Damage Manager
 */
class SystemDamageManager {
    constructor(config) {
        this.systems = new Map();
        // Thresholds
        this.DEGRADED_THRESHOLD = 0.7; // Below 70% = degraded
        this.OFFLINE_THRESHOLD = 0.3; // Below 30% = offline
        this.DESTROYED_THRESHOLD = 0.1; // Below 10% = destroyed
        for (const system of config.systems) {
            this.systems.set(system.id, system);
        }
        this.hull = config.hull;
    }
    /**
     * Update system damage
     */
    update(dt) {
        // PHASE 1: Apply damage from compartment failures
        for (const system of this.systems.values()) {
            this.applyCompartmentDamage(system, dt);
        }
        // PHASE 2: Update system status based on new integrity
        for (const system of this.systems.values()) {
            this.updateSystemStatus(system);
        }
        // PHASE 3: Handle dependencies (cascade failures)
        for (const system of this.systems.values()) {
            this.checkDependencies(system);
        }
    }
    /**
     * Update system status based on integrity
     */
    updateSystemStatus(system) {
        if (system.integrity <= this.DESTROYED_THRESHOLD) {
            system.status = SystemStatus.DESTROYED;
            system.operational = false;
        }
        else if (system.integrity <= this.OFFLINE_THRESHOLD) {
            system.status = SystemStatus.OFFLINE;
            system.operational = false;
        }
        else if (system.integrity <= this.DEGRADED_THRESHOLD) {
            system.status = SystemStatus.DEGRADED;
            system.operational = true; // Works but poorly
        }
        else {
            system.status = SystemStatus.ONLINE;
            system.operational = true;
        }
    }
    /**
     * Apply damage from compartment state
     */
    applyCompartmentDamage(system, dt) {
        const compartment = this.hull.getCompartment(system.compartmentId);
        if (!compartment)
            return;
        // Structural damage to compartment damages systems inside
        if (compartment.structuralIntegrity < 1.0) {
            const damageRate = (1.0 - compartment.structuralIntegrity) * 0.01; // 1% per second at 0 integrity
            system.integrity = Math.max(0, system.integrity - damageRate * dt);
        }
        // Atmosphere-sensitive systems fail in vacuum
        if (system.requiresAtmosphere && compartment.atmosphereIntegrity < 0.5) {
            const degradationRate = 0.08; // 8% per second in vacuum (rapid failure)
            system.integrity = Math.max(0, system.integrity - degradationRate * dt);
        }
    }
    /**
     * Check system dependencies
     */
    checkDependencies(system) {
        if (!system.dependencies || system.dependencies.length === 0)
            return;
        for (const depId of system.dependencies) {
            const dependency = this.systems.get(depId);
            if (!dependency)
                continue;
            // If dependency is offline/destroyed, this system can't operate
            if (dependency.status === SystemStatus.OFFLINE ||
                dependency.status === SystemStatus.DESTROYED) {
                system.operational = false;
            }
        }
    }
    /**
     * Get damage report
     */
    getDamageReport() {
        const damagedSystems = [];
        const criticalFailures = [];
        let operationalCount = 0;
        for (const system of this.systems.values()) {
            if (system.operational) {
                operationalCount++;
            }
            if (system.status !== SystemStatus.ONLINE) {
                const failure = {
                    systemId: system.id,
                    systemName: system.name,
                    integrity: system.integrity,
                    reason: this.getFailureReason(system),
                    isCritical: system.isCritical ?? false
                };
                damagedSystems.push(failure);
                if (system.isCritical) {
                    criticalFailures.push(failure);
                }
            }
        }
        return {
            damagedSystems,
            criticalFailures,
            totalSystems: this.systems.size,
            operationalSystems: operationalCount
        };
    }
    /**
     * Get failure reason for system
     */
    getFailureReason(system) {
        if (system.integrity <= this.DESTROYED_THRESHOLD) {
            return 'Destroyed';
        }
        const compartment = this.hull.getCompartment(system.compartmentId);
        if (compartment) {
            if (compartment.atmosphereIntegrity < 0.5 && system.requiresAtmosphere) {
                return 'Vacuum exposure';
            }
            if (compartment.structuralIntegrity < 0.5) {
                return 'Compartment structural failure';
            }
        }
        if (system.dependencies) {
            for (const depId of system.dependencies) {
                const dep = this.systems.get(depId);
                if (dep && !dep.operational) {
                    return `Dependency failure: ${dep.name}`;
                }
            }
        }
        return 'Component damage';
    }
    /**
     * Get system effectiveness (0-1 based on integrity and status)
     */
    getSystemEffectiveness(systemId) {
        const system = this.systems.get(systemId);
        if (!system || !system.operational)
            return 0;
        // Effectiveness degrades with integrity
        return system.integrity;
    }
    /**
     * Get system by ID
     */
    getSystem(id) {
        return this.systems.get(id);
    }
    /**
     * Add system
     */
    addSystem(system) {
        this.systems.set(system.id, system);
    }
    /**
     * Get all systems
     */
    getAllSystems() {
        return Array.from(this.systems.values());
    }
}
exports.SystemDamageManager = SystemDamageManager;
//# sourceMappingURL=system-damage.js.map