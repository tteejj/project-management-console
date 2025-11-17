"use strict";
/**
 * Main Engine Physics Module
 *
 * Simulates:
 * - Rocket engine combustion and thrust
 * - Tsiolkovsky rocket equation and specific impulse
 * - Gimbal control for thrust vectoring
 * - Fuel/oxidizer consumption from tanks
 * - Chamber pressure and temperature dynamics
 * - Ignition sequence and startup transients
 * - Engine health degradation
 * - Thermal effects and cooling requirements
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.MainEngine = void 0;
class MainEngine {
    constructor(config) {
        // Internal state
        this.ignitionProgress = 0; // 0 to 1
        this.shutdownProgress = 0; // 0 to 1
        this.currentChamberPressureBar = 0;
        this.currentChamberTempK = 293;
        // Health and wear
        this.health = 100; // 0-100%
        this.totalFiredSeconds = 0;
        this.ignitionCount = 0;
        this.restartCooldownS = 0; // Minimum time between restarts
        // Consumption tracking
        this.totalFuelConsumedKg = 0;
        this.totalOxidizerConsumedKg = 0;
        // Events
        this.events = [];
        // Constants
        this.G0 = 9.80665; // Standard gravity (m/s²)
        this.maxThrustN = config?.maxThrustN || 45000; // 45kN (about 10,000 lbf)
        this.specificImpulseSec = config?.specificImpulseSec || 311; // Typical for hypergolic
        this.maxGimbalDeg = config?.maxGimbalDeg || 6;
        this.ignitionTimeS = config?.ignitionTimeS || 2.0;
        this.shutdownTimeS = config?.shutdownTimeS || 0.5;
        this.minThrottle = config?.minThrottle || 0.4; // 40% minimum
        this.chamberPressureBar = config?.chamberPressureBar || 10;
        this.chamberTempK = config?.chamberTempK || 3200;
        this.nozzleAreaM2 = config?.nozzleAreaM2 || 0.28; // ~0.6m diameter
        this.fuelOxidizerRatio = config?.fuelOxidizerRatio || 1.6; // Typical for UDMH/N2O4
        this.status = 'off';
        this.throttle = 0;
        this.currentThrustN = 0;
        this.gimbalPitchDeg = 0;
        this.gimbalYawDeg = 0;
    }
    /**
     * Main update loop
     */
    update(dt, simulationTime) {
        // 1. Update engine state transitions
        this.updateEngineState(dt, simulationTime);
        // 2. Calculate thrust output
        this.calculateThrust(dt);
        // 3. Track firing time
        if (this.status === 'running' && this.currentThrustN > 0) {
            this.totalFiredSeconds += dt;
        }
        // 4. Degrade health based on usage
        this.degradeHealth(dt);
        // 5. Update cooldown timer
        if (this.restartCooldownS > 0) {
            this.restartCooldownS = Math.max(0, this.restartCooldownS - dt);
        }
    }
    /**
     * Update engine state machine
     */
    updateEngineState(dt, time) {
        switch (this.status) {
            case 'igniting':
                this.ignitionProgress += dt / this.ignitionTimeS;
                if (this.ignitionProgress >= 1.0) {
                    this.ignitionProgress = 1.0;
                    this.status = 'running';
                    this.logEvent(time, 'engine_ignited', {
                        totalIgnitions: this.ignitionCount
                    });
                }
                // Chamber pressure and temperature rise during ignition
                this.currentChamberPressureBar = this.chamberPressureBar * this.ignitionProgress * this.throttle;
                this.currentChamberTempK = 293 + (this.chamberTempK - 293) * this.ignitionProgress * this.throttle;
                break;
            case 'running':
                // Maintain chamber conditions based on throttle
                this.currentChamberPressureBar = this.chamberPressureBar * this.throttle;
                this.currentChamberTempK = 293 + (this.chamberTempK - 293) * this.throttle;
                break;
            case 'shutdown':
                this.shutdownProgress += dt / this.shutdownTimeS;
                if (this.shutdownProgress >= 1.0) {
                    this.shutdownProgress = 0;
                    this.status = 'off';
                    this.currentChamberPressureBar = 0;
                    this.currentChamberTempK = Math.max(293, this.currentChamberTempK - 100 * dt); // Cool down
                    this.logEvent(time, 'engine_shutdown_complete', {});
                }
                else {
                    // Spool down
                    const spoolFactor = 1.0 - this.shutdownProgress;
                    this.currentChamberPressureBar = this.chamberPressureBar * this.throttle * spoolFactor;
                    this.currentChamberTempK = 293 + (this.currentChamberTempK - 293) * spoolFactor;
                }
                break;
            case 'off':
                this.currentChamberPressureBar = 0;
                // Gradual cooldown
                if (this.currentChamberTempK > 293) {
                    this.currentChamberTempK -= 50 * dt; // 50 K/s cooldown
                    this.currentChamberTempK = Math.max(293, this.currentChamberTempK);
                }
                break;
        }
    }
    /**
     * Calculate thrust output
     * F = ṁ * v_e
     * where v_e = Isp * g0
     */
    calculateThrust(dt) {
        if (this.status === 'off') {
            this.currentThrustN = 0;
            return;
        }
        let thrustFactor = this.throttle;
        // During ignition, thrust ramps up
        if (this.status === 'igniting') {
            thrustFactor *= this.ignitionProgress;
        }
        // During shutdown, thrust ramps down
        if (this.status === 'shutdown') {
            thrustFactor *= (1.0 - this.shutdownProgress);
        }
        // Health affects maximum thrust
        const healthFactor = this.health / 100;
        this.currentThrustN = this.maxThrustN * thrustFactor * healthFactor;
    }
    /**
     * Degrade engine health based on usage
     */
    degradeHealth(dt) {
        if (this.status === 'running' && this.currentThrustN > 0) {
            // Health degrades faster at high throttle
            const degradeRate = 0.001 * this.throttle; // % per second
            this.health = Math.max(0, this.health - degradeRate * dt);
        }
    }
    /**
     * Calculate mass flow rate
     * ṁ = F / (Isp * g0)
     */
    getMassFlowRateKgPerSec() {
        if (this.currentThrustN === 0)
            return 0;
        const exhaustVelocity = this.specificImpulseSec * this.G0;
        return this.currentThrustN / exhaustVelocity;
    }
    /**
     * Get fuel and oxidizer consumption rates
     */
    getConsumptionRates() {
        const totalMassFlow = this.getMassFlowRateKgPerSec();
        // Split based on fuel/oxidizer ratio
        // If ratio is 1.6, then for every 1kg fuel, we need 1.6kg oxidizer
        const fuelKgPerSec = totalMassFlow / (1 + this.fuelOxidizerRatio);
        const oxidizerKgPerSec = totalMassFlow * this.fuelOxidizerRatio / (1 + this.fuelOxidizerRatio);
        return { fuelKgPerSec, oxidizerKgPerSec };
    }
    /**
     * Consume propellant for this timestep
     * Returns actual consumption (may be limited by available propellant)
     */
    consumePropellant(dt, availableFuelKg, availableOxidizerKg) {
        const rates = this.getConsumptionRates();
        const desiredFuel = rates.fuelKgPerSec * dt;
        const desiredOxidizer = rates.oxidizerKgPerSec * dt;
        // Check if we have enough propellant
        const actualFuel = Math.min(desiredFuel, availableFuelKg);
        const actualOxidizer = Math.min(desiredOxidizer, availableOxidizerKg);
        // If we can't maintain the mixture ratio, reduce thrust
        const fuelRatio = actualFuel / Math.max(0.001, desiredFuel);
        const oxidizerRatio = actualOxidizer / Math.max(0.001, desiredOxidizer);
        const limitRatio = Math.min(fuelRatio, oxidizerRatio);
        if (limitRatio < 0.9 && this.status === 'running') {
            // Engine flameout due to propellant starvation
            this.shutdown();
        }
        this.totalFuelConsumedKg += actualFuel;
        this.totalOxidizerConsumedKg += actualOxidizer;
        return {
            fuelConsumed: actualFuel,
            oxidizerConsumed: actualOxidizer
        };
    }
    /**
     * Ignite the engine
     */
    ignite() {
        if (this.status !== 'off')
            return false;
        if (this.restartCooldownS > 0)
            return false;
        if (this.health < 10)
            return false;
        this.status = 'igniting';
        this.ignitionProgress = 0;
        this.ignitionCount++;
        this.restartCooldownS = 5.0; // 5 second cooldown after ignition
        return true;
    }
    /**
     * Shutdown the engine
     */
    shutdown() {
        if (this.status === 'off' || this.status === 'shutdown')
            return;
        this.status = 'shutdown';
        this.shutdownProgress = 0;
    }
    /**
     * Set throttle (0.0 to 1.0)
     */
    setThrottle(throttle) {
        // Clamp to min/max
        if (throttle > 0 && throttle < this.minThrottle) {
            throttle = this.minThrottle;
        }
        this.throttle = Math.max(0, Math.min(1.0, throttle));
    }
    /**
     * Set gimbal angles
     */
    setGimbal(pitchDeg, yawDeg) {
        this.gimbalPitchDeg = Math.max(-this.maxGimbalDeg, Math.min(this.maxGimbalDeg, pitchDeg));
        this.gimbalYawDeg = Math.max(-this.maxGimbalDeg, Math.min(this.maxGimbalDeg, yawDeg));
    }
    /**
     * Get thrust vector components
     * Returns [x, y, z] in Newtons (assuming z is thrust axis)
     */
    getThrustVector() {
        if (this.currentThrustN === 0) {
            return { x: 0, y: 0, z: 0 };
        }
        // Convert angles to radians
        const pitchRad = (this.gimbalPitchDeg * Math.PI) / 180;
        const yawRad = (this.gimbalYawDeg * Math.PI) / 180;
        // Calculate thrust components
        // Assuming: z is main thrust axis, x is pitch, y is yaw
        const thrustZ = this.currentThrustN * Math.cos(pitchRad) * Math.cos(yawRad);
        const thrustX = this.currentThrustN * Math.sin(pitchRad);
        const thrustY = this.currentThrustN * Math.sin(yawRad) * Math.cos(pitchRad);
        return { x: thrustX, y: thrustY, z: thrustZ };
    }
    /**
     * Get heat generation from engine
     */
    getHeatGenerationW() {
        // Engine generates significant heat
        // Roughly 5% of thrust power becomes waste heat
        if (this.currentThrustN === 0)
            return 0;
        const thrustPowerW = this.currentThrustN * this.getMassFlowRateKgPerSec() * this.specificImpulseSec * this.G0 / 2;
        return thrustPowerW * 0.05;
    }
    /**
     * Get current state
     */
    getState() {
        return {
            status: this.status,
            throttle: this.throttle,
            currentThrustN: this.currentThrustN,
            currentThrustKN: this.currentThrustN / 1000,
            gimbalPitch: this.gimbalPitchDeg,
            gimbalYaw: this.gimbalYawDeg,
            chamberPressureBar: this.currentChamberPressureBar,
            chamberTempK: this.currentChamberTempK,
            health: this.health,
            totalFiredSeconds: this.totalFiredSeconds,
            ignitionCount: this.ignitionCount,
            massFlowRateKgPerSec: this.getMassFlowRateKgPerSec(),
            totalFuelConsumedKg: this.totalFuelConsumedKg,
            totalOxidizerConsumedKg: this.totalOxidizerConsumedKg,
            restartCooldownS: this.restartCooldownS
        };
    }
    /**
     * Log an event
     */
    logEvent(time, type, data) {
        this.events.push({ time, type, data });
    }
    /**
     * Get all events
     */
    getEvents() {
        return this.events;
    }
    /**
     * Clear events
     */
    clearEvents() {
        this.events = [];
    }
}
exports.MainEngine = MainEngine;
//# sourceMappingURL=main-engine.js.map