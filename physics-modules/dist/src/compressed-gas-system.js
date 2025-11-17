"use strict";
/**
 * Compressed Gas System Physics Module
 *
 * Simulates:
 * - High-pressure gas bottles (N2, O2, He)
 * - Ideal gas law for pressure-temperature relationship
 * - Gas consumption and pressure drop
 * - Temperature effects from environment
 * - Overpressure warnings and rupture
 * - Regulated output pressure
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.CompressedGasSystem = void 0;
class CompressedGasSystem {
    constructor(config) {
        // Tracking
        this.totalGasConsumed = new Map(); // kg per gas type
        this.events = [];
        this.bottles = config?.bottles || this.createDefaultBottles();
        this.regulators = config?.regulators || this.createDefaultRegulators();
        this.ambientTemperature = config?.ambientTemperature || 293;
        // Initialize tracking
        this.totalGasConsumed.set('N2', 0);
        this.totalGasConsumed.set('O2', 0);
        this.totalGasConsumed.set('He', 0);
    }
    createDefaultBottles() {
        return [
            {
                gas: 'N2',
                pressureBar: 200, // 200 bar compressed nitrogen
                volumeL: 50,
                massKg: 12.5,
                maxPressureBar: 250,
                temperature: 293,
                uses: ['fuel_pressurization', 'pneumatic_actuators', 'emergency_atmosphere'],
                ruptured: false
            },
            {
                gas: 'O2',
                pressureBar: 150,
                volumeL: 40,
                massKg: 8.5,
                maxPressureBar: 200,
                temperature: 293,
                uses: ['emergency_breathing', 'fuel_oxidizer'],
                ruptured: false
            },
            {
                gas: 'He',
                pressureBar: 180,
                volumeL: 30,
                massKg: 1.2,
                maxPressureBar: 220,
                temperature: 293,
                uses: ['leak_detection', 'purging'],
                ruptured: false
            }
        ];
    }
    createDefaultRegulators() {
        return [
            {
                name: 'Fuel Tank Pressurization',
                inputBottleIndex: 0, // N2 bottle
                outputPressureBar: 2.5,
                flowRateLPerMin: 5,
                active: false
            },
            {
                name: 'Emergency O2',
                inputBottleIndex: 1, // O2 bottle
                outputPressureBar: 1.0,
                flowRateLPerMin: 50,
                active: false
            },
            {
                name: 'Pneumatic Systems',
                inputBottleIndex: 0, // N2 bottle
                outputPressureBar: 8.0,
                flowRateLPerMin: 10,
                active: false
            }
        ];
    }
    /**
     * Main update loop
     */
    update(dt, simulationTime) {
        // 1. Update bottle temperatures based on ambient
        this.updateBottleTemperatures(dt);
        // 2. Update pressures based on temperature (ideal gas law)
        this.updateBottlePressures();
        // 3. Check for overpressure and rupture
        this.checkOverpressure(simulationTime);
        // 4. Check for warnings
        this.checkWarnings(simulationTime);
    }
    /**
     * Update bottle temperatures - they equilibrate with ambient
     */
    updateBottleTemperatures(dt) {
        for (const bottle of this.bottles) {
            if (bottle.ruptured)
                continue;
            // Slow thermal equilibrium with compartment
            const tempDiff = this.ambientTemperature - bottle.temperature;
            const thermalTimeConstant = 0.01; // slow equilibration
            bottle.temperature += tempDiff * thermalTimeConstant * dt;
        }
    }
    /**
     * Update bottle pressures using ideal gas law
     * P = (n * R * T) / V
     * where n = mass / molar_mass
     */
    updateBottlePressures() {
        const R = 8.314; // J/(mol·K)
        for (const bottle of this.bottles) {
            if (bottle.ruptured) {
                bottle.pressureBar = 0;
                continue;
            }
            if (bottle.massKg <= 0) {
                bottle.pressureBar = 0;
                continue;
            }
            const molarMass = this.getMolarMass(bottle.gas);
            const moles = bottle.massKg / molarMass;
            const volumeM3 = bottle.volumeL / 1000;
            // P = (n * R * T) / V, convert Pa to bar
            const pressurePa = (moles * R * bottle.temperature) / volumeM3;
            bottle.pressureBar = pressurePa / 100000;
        }
    }
    /**
     * Check for overpressure and handle rupture
     */
    checkOverpressure(time) {
        for (let i = 0; i < this.bottles.length; i++) {
            const bottle = this.bottles[i];
            if (bottle.ruptured)
                continue;
            // Overpressure warning at 95% of max
            if (bottle.pressureBar > bottle.maxPressureBar * 0.95) {
                this.logEvent(time, 'gas_bottle_overpressure', {
                    bottleIndex: i,
                    gas: bottle.gas,
                    pressure: bottle.pressureBar,
                    maxPressure: bottle.maxPressureBar
                });
            }
            // Rupture if exceeds max pressure
            if (bottle.pressureBar > bottle.maxPressureBar) {
                this.ruptureBottle(i, time);
            }
        }
    }
    /**
     * Rupture a bottle (catastrophic failure)
     */
    ruptureBottle(bottleIndex, time) {
        const bottle = this.bottles[bottleIndex];
        if (bottle.ruptured)
            return;
        bottle.ruptured = true;
        // Calculate explosive energy
        const volumeM3 = bottle.volumeL / 1000;
        const pressurePa = bottle.pressureBar * 100000;
        const storedEnergyJ = pressurePa * volumeM3;
        this.logEvent(time, 'gas_bottle_ruptured', {
            bottleIndex,
            gas: bottle.gas,
            massKg: bottle.massKg,
            pressureBar: bottle.pressureBar,
            energyJ: storedEnergyJ
        });
        // Gas is lost to space/compartment
        bottle.pressureBar = 0;
        bottle.massKg = 0;
    }
    /**
     * Check for warning conditions
     */
    checkWarnings(time) {
        for (let i = 0; i < this.bottles.length; i++) {
            const bottle = this.bottles[i];
            if (bottle.ruptured)
                continue;
            // Low pressure warning (< 30 bar)
            if (bottle.pressureBar < 30 && bottle.pressureBar > 0) {
                this.logEvent(time, 'gas_bottle_low', {
                    bottleIndex: i,
                    gas: bottle.gas,
                    pressureBar: bottle.pressureBar
                });
            }
            // Empty warning
            if (bottle.massKg < 0.1 && bottle.massKg > 0) {
                this.logEvent(time, 'gas_bottle_depleted', {
                    bottleIndex: i,
                    gas: bottle.gas
                });
            }
        }
    }
    /**
     * Consume gas from a specific bottle
     * Returns actual mass consumed (may be less than requested)
     */
    consumeGas(bottleIndex, massKg) {
        const bottle = this.bottles[bottleIndex];
        if (!bottle || bottle.ruptured)
            return 0;
        const actualConsumed = Math.min(massKg, bottle.massKg);
        if (actualConsumed > 0) {
            bottle.massKg -= actualConsumed;
            // Track consumption
            const currentTotal = this.totalGasConsumed.get(bottle.gas) || 0;
            this.totalGasConsumed.set(bottle.gas, currentTotal + actualConsumed);
            // Pressure will update on next updateBottlePressures() call
        }
        return actualConsumed;
    }
    /**
     * Activate a regulator to provide gas flow
     * Returns actual flow rate achieved (L/min)
     */
    activateRegulator(regulatorName) {
        const regulator = this.regulators.find(r => r.name === regulatorName);
        if (!regulator)
            return 0;
        const bottle = this.bottles[regulator.inputBottleIndex];
        if (!bottle || bottle.ruptured)
            return 0;
        // Check if bottle pressure is sufficient
        if (bottle.pressureBar < regulator.outputPressureBar + 5) {
            // Need at least 5 bar above output pressure for regulation
            return 0;
        }
        regulator.active = true;
        return regulator.flowRateLPerMin;
    }
    /**
     * Deactivate a regulator
     */
    deactivateRegulator(regulatorName) {
        const regulator = this.regulators.find(r => r.name === regulatorName);
        if (regulator) {
            regulator.active = false;
        }
    }
    /**
     * Get regulated output pressure from a regulator
     */
    getRegulatorPressure(regulatorName) {
        const regulator = this.regulators.find(r => r.name === regulatorName);
        if (!regulator || !regulator.active)
            return 0;
        const bottle = this.bottles[regulator.inputBottleIndex];
        if (!bottle || bottle.ruptured)
            return 0;
        // Check if bottle can maintain regulated pressure
        if (bottle.pressureBar >= regulator.outputPressureBar + 5) {
            return regulator.outputPressureBar;
        }
        // Insufficient pressure - output drops
        return Math.max(0, bottle.pressureBar - 5);
    }
    /**
     * Transfer gas between bottles (if needed for balancing)
     */
    transferGas(fromBottleIndex, toBottleIndex, massKg) {
        const fromBottle = this.bottles[fromBottleIndex];
        const toBottle = this.bottles[toBottleIndex];
        if (!fromBottle || !toBottle)
            return false;
        if (fromBottle.ruptured || toBottle.ruptured)
            return false;
        if (fromBottle.gas !== toBottle.gas)
            return false; // Can't mix gas types
        if (fromBottle.massKg >= massKg) {
            // Check if destination has capacity
            const R = 8.314;
            const molarMass = this.getMolarMass(toBottle.gas);
            const newMass = toBottle.massKg + massKg;
            const newMoles = newMass / molarMass;
            const volumeM3 = toBottle.volumeL / 1000;
            const newPressurePa = (newMoles * R * toBottle.temperature) / volumeM3;
            const newPressureBar = newPressurePa / 100000;
            if (newPressureBar <= toBottle.maxPressureBar) {
                fromBottle.massKg -= massKg;
                toBottle.massKg += massKg;
                return true;
            }
        }
        return false;
    }
    /**
     * Get molar mass for gas type (in kg/mol for consistency with massKg)
     */
    getMolarMass(gas) {
        const molarMasses = {
            'N2': 0.028, // kg/mol
            'O2': 0.032,
            'He': 0.004
        };
        return molarMasses[gas];
    }
    /**
     * Get bottle by index
     */
    getBottle(index) {
        return this.bottles[index];
    }
    /**
     * Get bottle by gas type
     */
    getBottleByGas(gasType) {
        return this.bottles.find(b => b.gas === gasType && !b.ruptured);
    }
    /**
     * Set ambient temperature (from compartment/thermal system)
     */
    setAmbientTemperature(tempK) {
        this.ambientTemperature = tempK;
    }
    /**
     * Get current state for debugging/testing
     */
    getState() {
        return {
            bottles: this.bottles.map((b, i) => ({
                index: i,
                gas: b.gas,
                pressureBar: b.pressureBar,
                massKg: b.massKg,
                temperature: b.temperature,
                percentFull: (b.pressureBar / b.maxPressureBar) * 100,
                ruptured: b.ruptured
            })),
            regulators: this.regulators.map(r => ({
                name: r.name,
                active: r.active,
                outputPressure: this.getRegulatorPressure(r.name),
                inputBottle: r.inputBottleIndex
            })),
            totalConsumed: Object.fromEntries(this.totalGasConsumed),
            ambientTemperature: this.ambientTemperature
        };
    }
    /**
     * Log an event
     */
    logEvent(time, type, data) {
        // Only log each event type once per second to avoid spam
        const recentEvent = this.events.find(e => e.type === type &&
            JSON.stringify(e.data) === JSON.stringify(data) &&
            time - e.time < 1.0);
        if (!recentEvent) {
            this.events.push({ time, type, data });
        }
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
exports.CompressedGasSystem = CompressedGasSystem;
//# sourceMappingURL=compressed-gas-system.js.map