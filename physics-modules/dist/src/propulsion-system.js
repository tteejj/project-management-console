"use strict";
/**
 * Propulsion System
 *
 * Integrates thrusters with fuel, power, thermal, and physics systems
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.PropulsionSystem = exports.ThrusterType = exports.PropellantType = void 0;
const math_utils_1 = require("./math-utils");
var PropellantType;
(function (PropellantType) {
    PropellantType["HYDRAZINE"] = "hydrazine";
    PropellantType["LOX_LH2"] = "lox_lh2";
    PropellantType["MMH_NTO"] = "mmh_nto";
    PropellantType["XENON"] = "xenon";
})(PropellantType || (exports.PropellantType = PropellantType = {}));
var ThrusterType;
(function (ThrusterType) {
    ThrusterType["MAIN_ENGINE"] = "main_engine";
    ThrusterType["RCS"] = "rcs";
    ThrusterType["ION_DRIVE"] = "ion_drive";
})(ThrusterType || (exports.ThrusterType = ThrusterType = {}));
/**
 * Propulsion System - Manages all thrusters
 */
class PropulsionSystem {
    constructor() {
        this.thrusters = new Map();
        this.fuelTanks = new Map();
        this.G0 = 9.80665; // Standard gravity (m/s²)
        this.GIMBAL_RATE = 10; // degrees per second
    }
    /**
     * Add thruster to system
     */
    addThruster(config) {
        const state = {
            enabled: false,
            throttle: 0,
            gimbalAngle: { x: 0, y: 0, z: 0 },
            temperature: 293, // Room temperature
            fuelFlow: 0,
            powerDraw: 0,
            heatGeneration: 0,
            damaged: false,
            integrity: 1.0,
            actualThrust: 0
        };
        this.thrusters.set(config.id, { config, state });
    }
    /**
     * Register fuel tank
     */
    registerFuelTank(tankId, tank) {
        this.fuelTanks.set(tankId, tank);
    }
    /**
     * Register power budget
     */
    registerPowerBudget(powerBudget) {
        this.powerBudget = powerBudget;
    }
    /**
     * Get thruster config
     */
    getThrusterConfig(id) {
        return this.thrusters.get(id)?.config;
    }
    /**
     * Get thruster state
     */
    getThrusterState(id) {
        return this.thrusters.get(id)?.state;
    }
    /**
     * Fire thruster at given throttle
     */
    fireThruster(id, throttle) {
        const thruster = this.thrusters.get(id);
        if (!thruster)
            return false;
        const { config, state } = thruster;
        // Check damage
        if (state.damaged || state.integrity <= 0)
            return false;
        // Clamp throttle to valid range
        const minThrottle = config.minThrottle || (config.type === ThrusterType.RCS ? 1.0 : 0.4);
        const clampedThrottle = Math.max(0, Math.min(1, throttle));
        // RCS is ON/OFF only
        if (config.type === ThrusterType.RCS) {
            state.throttle = clampedThrottle > 0.5 ? 1.0 : 0;
        }
        else {
            state.throttle = clampedThrottle < minThrottle ? 0 : clampedThrottle;
        }
        state.enabled = state.throttle > 0;
        return true;
    }
    /**
     * Set gimbal angle (for thrust vectoring)
     */
    setGimbal(id, targetAngle) {
        const thruster = this.thrusters.get(id);
        if (!thruster || !thruster.config.canGimbal)
            return false;
        const { config, state } = thruster;
        const maxAngle = config.gimbalRange || 15;
        // Clamp to gimbal range
        state.gimbalAngle = {
            x: Math.max(-maxAngle, Math.min(maxAngle, targetAngle.x)),
            y: Math.max(-maxAngle, Math.min(maxAngle, targetAngle.y)),
            z: Math.max(-maxAngle, Math.min(maxAngle, targetAngle.z))
        };
        return true;
    }
    /**
     * Get current thrust vector (force and torque)
     */
    getThrustVector(id) {
        const thruster = this.thrusters.get(id);
        if (!thruster) {
            return { force: math_utils_1.VectorMath.zero(), torque: math_utils_1.VectorMath.zero() };
        }
        const { config, state } = thruster;
        // Calculate thrust direction with gimbal
        const thrustDir = this.calculateThrustDirection(config.direction, state.gimbalAngle);
        // Calculate force vector
        const force = math_utils_1.VectorMath.scale(thrustDir, state.actualThrust);
        // Calculate torque: τ = r × F
        const torque = math_utils_1.VectorMath.cross(config.position, force);
        return { force, torque };
    }
    /**
     * Update all thrusters
     */
    update(dt) {
        let totalForce = math_utils_1.VectorMath.zero();
        let totalTorque = math_utils_1.VectorMath.zero();
        let totalFuelConsumed = 0;
        let totalPowerConsumed = 0;
        let totalHeatGenerated = 0;
        for (const [id, thruster] of this.thrusters.entries()) {
            if (!thruster.state.enabled) {
                thruster.state.actualThrust = 0;
                thruster.state.fuelFlow = 0;
                thruster.state.powerDraw = 0;
                thruster.state.heatGeneration = 0;
                continue;
            }
            // 1. Calculate thrust and fuel consumption
            const thrustResult = this.calculateThrust(thruster, dt);
            if (thrustResult.success) {
                thruster.state.actualThrust = thrustResult.thrust;
                thruster.state.fuelFlow = thrustResult.fuelFlow;
                thruster.state.powerDraw = thrustResult.powerDraw;
                thruster.state.heatGeneration = thrustResult.heatGeneration;
                // 2. Get thrust vector
                const { force, torque } = this.getThrustVector(id);
                totalForce = math_utils_1.VectorMath.add(totalForce, force);
                totalTorque = math_utils_1.VectorMath.add(totalTorque, torque);
                // 3. Accumulate totals
                totalFuelConsumed += thrustResult.fuelConsumed;
                totalPowerConsumed += thrustResult.powerDraw;
                totalHeatGenerated += thrustResult.heatGeneration;
                // 4. Update temperature
                this.updateThrusterTemperature(thruster, dt);
            }
            else {
                // Fuel or power depleted - shut down
                thruster.state.enabled = false;
                thruster.state.throttle = 0;
                thruster.state.actualThrust = 0;
                thruster.state.fuelFlow = 0;
                thruster.state.powerDraw = 0;
                thruster.state.heatGeneration = 0;
            }
        }
        return {
            force: totalForce,
            torque: totalTorque,
            fuelConsumed: totalFuelConsumed,
            powerConsumed: totalPowerConsumed,
            heatGenerated: totalHeatGenerated
        };
    }
    /**
     * Calculate thrust, fuel consumption, power, and heat
     */
    calculateThrust(thruster, dt) {
        const { config, state } = thruster;
        // Calculate nominal thrust
        const nominalThrust = config.maxThrust * state.throttle;
        // Calculate fuel mass flow rate: ṁ = F / (Isp × g₀)
        const fuelFlow = nominalThrust / (config.isp * this.G0);
        const fuelConsumed = fuelFlow * dt;
        // Check fuel availability
        const fuelTank = this.fuelTanks.get(config.fuelTankId);
        if (!fuelTank) {
            return { success: false, thrust: 0, fuelFlow: 0, fuelConsumed: 0, powerDraw: 0, heatGeneration: 0 };
        }
        const canConsumeFuel = fuelTank.consume(fuelConsumed);
        if (!canConsumeFuel) {
            return { success: false, thrust: 0, fuelFlow: 0, fuelConsumed: 0, powerDraw: 0, heatGeneration: 0 };
        }
        // Calculate power consumption
        let powerDraw = 0;
        if (config.pumpPower) {
            powerDraw += config.pumpPower * state.throttle;
        }
        if (config.canGimbal && config.gimbalPower) {
            powerDraw += config.gimbalPower;
        }
        // Check power availability (only for pump-fed engines)
        if (config.pumpPower && this.powerBudget) {
            const hasPower = this.powerBudget.requestPower(config.id, powerDraw);
            if (!hasPower) {
                // Refund fuel (couldn't use it)
                // Note: This is simplified - in reality the fuel tank should handle transactions
                return { success: false, thrust: 0, fuelFlow: 0, fuelConsumed: 0, powerDraw: 0, heatGeneration: 0 };
            }
        }
        // Apply modifiers
        let actualThrust = nominalThrust;
        // Damage reduces thrust
        actualThrust *= state.integrity;
        // Tank pressure affects thrust (simplified: pressure < 50% reduces thrust)
        const tankPressure = fuelTank.getPressure();
        if (tankPressure < 50000) { // 0.5 bar
            const pressureFactor = tankPressure / 50000;
            actualThrust *= Math.max(0.2, pressureFactor); // Minimum 20% thrust
        }
        // Overheating reduces thrust
        if (state.temperature > 800) { // 800K threshold
            const overheatFactor = Math.max(0, 1 - (state.temperature - 800) / 500);
            actualThrust *= overheatFactor;
        }
        // Calculate heat generation
        // Heat = (1 - efficiency) × thrust power
        const thrustPower = actualThrust * config.isp * this.G0 / 1000; // kW
        const heatGeneration = thrustPower * (1 - config.efficiency);
        return {
            success: true,
            thrust: actualThrust,
            fuelFlow,
            fuelConsumed,
            powerDraw,
            heatGeneration
        };
    }
    /**
     * Calculate thrust direction with gimbal
     */
    calculateThrustDirection(baseDirection, gimbalAngle) {
        // For simplicity, apply gimbal as small angle rotation
        // In reality, this would use rotation matrices
        const gimbalRad = {
            x: (gimbalAngle.x * Math.PI) / 180,
            y: (gimbalAngle.y * Math.PI) / 180,
            z: (gimbalAngle.z * Math.PI) / 180
        };
        // Apply pitch (x) and yaw (y) gimbal
        // For small angles: sin(θ) ≈ θ, cos(θ) ≈ 1
        const thrustDir = {
            x: baseDirection.x + gimbalRad.y,
            y: baseDirection.y + gimbalRad.x,
            z: baseDirection.z
        };
        return math_utils_1.VectorMath.normalize(thrustDir);
    }
    /**
     * Update thruster temperature
     */
    updateThrusterTemperature(thruster, dt) {
        const { state } = thruster;
        // Heat up from operation
        const heatIncrease = state.heatGeneration * 1000 * dt / 100; // Simplified: 100kg thermal mass
        // Cooling (radiation to space, simplified)
        const COOLING_RATE = 0.1; // K/s
        const cooling = COOLING_RATE * dt;
        state.temperature += heatIncrease - cooling;
        state.temperature = Math.max(293, state.temperature); // Minimum ambient temp
        // Damage from overheating
        if (state.temperature > 1200) { // 1200K critical temp
            state.integrity -= 0.01 * dt; // 1% per second at critical temp
            state.integrity = Math.max(0, state.integrity);
            if (state.integrity <= 0) {
                state.damaged = true;
            }
        }
    }
    /**
     * Get total thrust vector for all active thrusters
     */
    getTotalThrust() {
        let totalForce = math_utils_1.VectorMath.zero();
        let totalTorque = math_utils_1.VectorMath.zero();
        for (const [id, _] of this.thrusters.entries()) {
            const { force, torque } = this.getThrustVector(id);
            totalForce = math_utils_1.VectorMath.add(totalForce, force);
            totalTorque = math_utils_1.VectorMath.add(totalTorque, torque);
        }
        return { force: totalForce, torque: totalTorque };
    }
    /**
     * Get statistics
     */
    getStatistics() {
        let totalThrust = 0;
        let activeThruster = 0;
        let damagedThruster = 0;
        for (const thruster of this.thrusters.values()) {
            if (thruster.state.enabled) {
                activeThruster++;
                totalThrust += thruster.state.actualThrust;
            }
            if (thruster.state.damaged) {
                damagedThruster++;
            }
        }
        return {
            totalThrusters: this.thrusters.size,
            activeThrusters: activeThruster,
            damagedThrusters: damagedThruster,
            totalThrust
        };
    }
}
exports.PropulsionSystem = PropulsionSystem;
//# sourceMappingURL=propulsion-system.js.map