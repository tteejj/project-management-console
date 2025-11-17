"use strict";
/**
 * Life Support System
 *
 * Manages oxygen, CO2, pressure, and crew health
 * Critical for submarine simulator feel - crew needs air!
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.LifeSupportSystem = exports.CrewStatus = void 0;
var CrewStatus;
(function (CrewStatus) {
    CrewStatus["HEALTHY"] = "healthy";
    CrewStatus["HYPOXIA"] = "hypoxia";
    CrewStatus["UNCONSCIOUS"] = "unconscious";
    CrewStatus["DEAD"] = "dead";
})(CrewStatus || (exports.CrewStatus = CrewStatus = {}));
/**
 * Life Support System
 */
class LifeSupportSystem {
    constructor(hull, crew, config) {
        // Statistics
        this.totalOxygenConsumed = 0;
        this.totalCO2Produced = 0;
        // Constants
        this.OXYGEN_CONSUMPTION_RATE = 0.0000064; // kg/s per person (0.023 kg/hr)
        this.CO2_PRODUCTION_RATE = 0.0000088; // kg/s per person (molecular weight ratio)
        this.HYPOXIA_PRESSURE = 60000; // Pa (0.6 atm)
        this.CRITICAL_PRESSURE = 40000; // Pa (0.4 atm)
        this.OXYGEN_RECOVERY_RATE = 0.2; // per second in good air
        this.OXYGEN_DEPLETION_RATE = 0.1; // per second in bad air
        this.hull = hull;
        this.crew = crew;
        this.config = config;
    }
    /**
     * Update life support system
     */
    update(dt) {
        const compartments = this.hull.getAllCompartments();
        // Process each compartment
        for (const compartment of compartments) {
            // 1. Oxygen consumption by crew
            const crewInCompartment = this.crew.filter(c => c.location === compartment.id);
            const oxygenConsumed = crewInCompartment.length * this.OXYGEN_CONSUMPTION_RATE * dt;
            const co2Produced = crewInCompartment.length * this.CO2_PRODUCTION_RATE * dt;
            // Track statistics
            this.totalOxygenConsumed += oxygenConsumed;
            this.totalCO2Produced += co2Produced;
            // Reduce pressure from O2 consumption (simplified)
            // In reality, O2 is replaced with CO2, but we simplify to pressure loss
            const pressureLoss = (oxygenConsumed / compartment.volume) * 8314 * 293; // Ideal gas law approximation
            compartment.pressure = Math.max(0, compartment.pressure - pressureLoss);
            // 2. Pressure loss through breaches
            if (compartment.breaches.length > 0) {
                const totalBreachArea = compartment.breaches
                    .filter(b => !b.sealed)
                    .reduce((sum, b) => sum + b.area, 0);
                if (totalBreachArea > 0) {
                    // Gas discharge through orifice (choked flow approximation)
                    // dP/dt = -(v * A / V) * P, where v ≈ speed of sound for vacuum exposure
                    const dischargeVelocity = 340; // m/s (speed of sound in air)
                    const decayRate = (dischargeVelocity * totalBreachArea) / compartment.volume;
                    // Exponential decay: P(t) = P0 * exp(-k*t)
                    // For small dt, we can use: P(t+dt) ≈ P(t) * (1 - k*dt)
                    compartment.pressure = compartment.pressure * Math.exp(-decayRate * dt);
                    compartment.pressure = Math.max(0, compartment.pressure);
                }
            }
            // 3. Life support generation (if powered)
            if (this.config.powered && compartment.atmosphereIntegrity > 0.1) {
                const oxygenGenerated = this.config.oxygenGenerationRate * dt;
                const pressureGain = (oxygenGenerated / compartment.volume) * 8314 * 293;
                compartment.pressure = Math.min(101325, compartment.pressure + pressureGain);
            }
            // 4. Update crew health
            for (const crewMember of crewInCompartment) {
                this.updateCrewHealth(crewMember, compartment, dt);
            }
        }
        // 5. Update atmosphere integrity based on pressure
        for (const compartment of compartments) {
            compartment.atmosphereIntegrity = compartment.pressure / 101325;
        }
    }
    /**
     * Update crew member health
     */
    updateCrewHealth(crew, compartment, dt) {
        // Check for hypoxia
        if (compartment.pressure < this.HYPOXIA_PRESSURE) {
            // Low oxygen - crew deteriorates
            crew.oxygenLevel = Math.max(0, crew.oxygenLevel - this.OXYGEN_DEPLETION_RATE * dt);
            if (crew.oxygenLevel <= 0) {
                crew.status = CrewStatus.UNCONSCIOUS;
                crew.health = Math.max(0, crew.health - 0.01 * dt); // Dying slowly
            }
            else {
                crew.status = CrewStatus.HYPOXIA;
            }
            // Severe hypoxia
            if (compartment.pressure < this.CRITICAL_PRESSURE) {
                crew.oxygenLevel = 0;
                crew.status = CrewStatus.UNCONSCIOUS;
            }
        }
        else {
            // Good air - crew recovers
            crew.oxygenLevel = Math.min(1, crew.oxygenLevel + this.OXYGEN_RECOVERY_RATE * dt);
            if (crew.oxygenLevel > 0.8 && crew.status !== CrewStatus.DEAD) {
                crew.status = CrewStatus.HEALTHY;
            }
        }
        // Death
        if (crew.health <= 0) {
            crew.status = CrewStatus.DEAD;
            crew.oxygenLevel = 0;
        }
    }
    /**
     * Get statistics
     */
    getStatistics() {
        let healthy = 0;
        let hypoxic = 0;
        let unconscious = 0;
        let dead = 0;
        for (const crew of this.crew) {
            switch (crew.status) {
                case CrewStatus.HEALTHY:
                    healthy++;
                    break;
                case CrewStatus.HYPOXIA:
                    hypoxic++;
                    break;
                case CrewStatus.UNCONSCIOUS:
                    unconscious++;
                    break;
                case CrewStatus.DEAD:
                    dead++;
                    break;
            }
        }
        return {
            oxygenConsumed: this.totalOxygenConsumed,
            co2Produced: this.totalCO2Produced,
            healthyCrew: healthy,
            hypoxicCrew: hypoxic,
            unconsciousCrew: unconscious,
            deadCrew: dead
        };
    }
    /**
     * Set power state
     */
    setPowered(powered) {
        this.config.powered = powered;
    }
    /**
     * Get all crew
     */
    getCrew() {
        return this.crew;
    }
}
exports.LifeSupportSystem = LifeSupportSystem;
//# sourceMappingURL=life-support.js.map