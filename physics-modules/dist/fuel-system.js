"use strict";
/**
 * Fuel System Physics Module
 *
 * Simulates:
 * - Multiple fuel tanks with pressurization
 * - Pressurant gas expansion (ideal gas law)
 * - Fuel flow and pressure dynamics
 * - Fuel transfer between tanks
 * - Center of mass calculation for ship balance
 * - Temperature effects on pressure
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.FuelSystem = void 0;
const GAS_CONSTANT = 8.314; // J/(mol·K)
const FUEL_DENSITY = 1.01; // kg/L (hydrazine-like)
class FuelSystem {
    constructor(config) {
        // Tracking for analysis
        this.totalFuelConsumed = 0;
        this.events = [];
        // Default configuration
        this.tanks = config?.tanks || this.createDefaultTanks();
        this.fuelLines = config?.fuelLines || {
            mainEngine: {
                connectedTank: null,
                flowRate: 0,
                pressure: 0,
                fuelPumpActive: false
            },
            rcsManifold: {
                connectedTank: null,
                flowRate: 0,
                pressure: 0,
                fuelPumpActive: false
            }
        };
    }
    createDefaultTanks() {
        return [
            {
                id: 'main_1',
                volume: 100,
                fuelMass: 80,
                capacity: 100,
                position: { x: 0, y: 0 },
                pressurized: true,
                pressureBar: 2.5,
                pressurantType: 'N2',
                pressurantMass: 0.5,
                temperature: 293,
                valves: {
                    feedToEngine: false,
                    feedToRCS: false,
                    fillPort: false,
                    vent: false
                }
            },
            {
                id: 'main_2',
                volume: 100,
                fuelMass: 75,
                capacity: 100,
                position: { x: 0, y: 10 },
                pressurized: true,
                pressureBar: 2.5,
                pressurantType: 'N2',
                pressurantMass: 0.5,
                temperature: 293,
                valves: {
                    feedToEngine: false,
                    feedToRCS: false,
                    fillPort: false,
                    vent: false
                }
            },
            {
                id: 'rcs',
                volume: 30,
                fuelMass: 25,
                capacity: 30,
                position: { x: 0, y: -5 },
                pressurized: true,
                pressureBar: 2.5,
                pressurantType: 'N2',
                pressurantMass: 0.2,
                temperature: 293,
                valves: {
                    feedToEngine: false,
                    feedToRCS: false,
                    fillPort: false,
                    vent: false
                }
            }
        ];
    }
    /**
     * Main update loop - should be called every simulation step
     */
    update(dt, simulationTime) {
        // 1. Update tank pressures based on fuel remaining
        this.updateTankPressures();
        // 2. Update fuel line pressures
        this.updateFuelLines();
        // 3. Handle fuel transfers (crossfeed)
        this.handleFuelTransfers(dt);
        // 4. Handle venting
        this.handleVenting(dt);
        // 5. Check for warnings/events
        this.checkWarnings(simulationTime);
    }
    /**
     * Update tank pressures based on pressurant gas expansion
     * Uses ideal gas law: PV = nRT
     */
    updateTankPressures() {
        for (const tank of this.tanks) {
            if (!tank.pressurized) {
                tank.pressureBar = 0;
                continue;
            }
            // Calculate ullage volume (empty space in tank)
            const fuelVolume = tank.fuelMass / FUEL_DENSITY;
            const ullageVolume = tank.volume - fuelVolume; // liters
            if (ullageVolume <= 0) {
                // Tank completely full - very high pressure
                tank.pressureBar = 50; // Overpressure
                continue;
            }
            // Ideal gas law: P = (n * R * T) / V
            // n = mass / molar_mass
            const molarMass = tank.pressurantType === 'N2' ? 28 : 4; // N2 or He
            const moles = tank.pressurantMass / molarMass;
            // Convert volume from liters to m³
            const volumeM3 = ullageVolume / 1000;
            // Calculate pressure in Pascals, then convert to bar
            const pressurePa = (moles * GAS_CONSTANT * tank.temperature) / volumeM3;
            tank.pressureBar = pressurePa / 100000; // Pa to bar
        }
    }
    /**
     * Update fuel line pressures based on connected tanks and pumps
     */
    updateFuelLines() {
        // Main engine line
        if (this.fuelLines.mainEngine.connectedTank) {
            const tank = this.getTank(this.fuelLines.mainEngine.connectedTank);
            if (tank && tank.valves.feedToEngine) {
                let linePressure = tank.pressureBar;
                // Fuel pump adds pressure
                if (this.fuelLines.mainEngine.fuelPumpActive) {
                    linePressure += 5; // pump adds 5 bar
                }
                this.fuelLines.mainEngine.pressure = linePressure;
            }
            else {
                this.fuelLines.mainEngine.pressure = 0;
            }
        }
        else {
            this.fuelLines.mainEngine.pressure = 0;
        }
        // RCS manifold
        if (this.fuelLines.rcsManifold.connectedTank) {
            const tank = this.getTank(this.fuelLines.rcsManifold.connectedTank);
            if (tank && tank.valves.feedToRCS) {
                this.fuelLines.rcsManifold.pressure = tank.pressureBar;
            }
            else {
                this.fuelLines.rcsManifold.pressure = 0;
            }
        }
        else {
            this.fuelLines.rcsManifold.pressure = 0;
        }
    }
    /**
     * Handle fuel transfers between tanks (crossfeed)
     */
    handleFuelTransfers(dt) {
        for (const sourceTank of this.tanks) {
            if (!sourceTank.valves.crossfeedTo)
                continue;
            const destTank = this.getTank(sourceTank.valves.crossfeedTo);
            if (!destTank)
                continue;
            // Transfer rate based on pressure differential
            const pressureDiff = sourceTank.pressureBar - destTank.pressureBar;
            if (pressureDiff <= 0)
                continue; // No flow if no pressure difference
            // Flow rate proportional to pressure difference (simplified)
            const transferRateKgPerSec = pressureDiff * 0.5; // kg/s
            const transferAmount = transferRateKgPerSec * dt;
            // Transfer fuel
            const actualTransfer = Math.min(transferAmount, sourceTank.fuelMass);
            const spaceInDest = destTank.capacity - destTank.fuelMass;
            const finalTransfer = Math.min(actualTransfer, spaceInDest);
            if (finalTransfer > 0) {
                sourceTank.fuelMass -= finalTransfer;
                destTank.fuelMass += finalTransfer;
            }
        }
    }
    /**
     * Handle fuel venting to space
     */
    handleVenting(dt) {
        for (const tank of this.tanks) {
            if (tank.valves.vent) {
                // Vent fuel to space (emergency dump)
                const ventRate = 5; // kg/s
                const vented = Math.min(ventRate * dt, tank.fuelMass);
                tank.fuelMass -= vented;
                this.totalFuelConsumed += vented; // Track as consumed
                // Venting also vents pressurant
                tank.pressurantMass *= 0.95; // lose some pressurant
            }
        }
    }
    /**
     * Check for warning conditions
     */
    checkWarnings(time) {
        for (const tank of this.tanks) {
            // Low pressure warning
            if (tank.pressurized && tank.pressureBar < 1.5) {
                this.logEvent(time, 'fuel_pressure_low', { tankId: tank.id, pressure: tank.pressureBar });
            }
            // Low fuel warning
            const fuelPercent = (tank.fuelMass / tank.capacity) * 100;
            if (fuelPercent < 10) {
                this.logEvent(time, 'fuel_low', { tankId: tank.id, percent: fuelPercent });
            }
            // Tank empty
            if (tank.fuelMass < 0.1) {
                this.logEvent(time, 'tank_empty', { tankId: tank.id });
            }
        }
    }
    /**
     * Consume fuel from a specific tank
     */
    consumeFuel(tankId, massKg) {
        const tank = this.getTank(tankId);
        if (!tank)
            return false;
        if (tank.fuelMass >= massKg) {
            tank.fuelMass -= massKg;
            this.totalFuelConsumed += massKg;
            return true;
        }
        return false;
    }
    /**
     * Calculate center of mass for fuel distribution
     * Returns offset from ship centerline
     */
    getFuelBalance() {
        let totalMass = 0;
        let weightedX = 0;
        let weightedY = 0;
        for (const tank of this.tanks) {
            totalMass += tank.fuelMass;
            weightedX += tank.fuelMass * tank.position.x;
            weightedY += tank.fuelMass * tank.position.y;
        }
        if (totalMass === 0) {
            return { offset: { x: 0, y: 0 }, magnitude: 0 };
        }
        const comX = weightedX / totalMass;
        const comY = weightedY / totalMass;
        const magnitude = Math.sqrt(comX * comX + comY * comY);
        return {
            offset: { x: comX, y: comY },
            magnitude
        };
    }
    /**
     * Get total fuel mass across all tanks
     */
    getTotalFuelMass() {
        return this.tanks.reduce((sum, tank) => sum + tank.fuelMass, 0);
    }
    /**
     * Get tank by ID
     */
    getTank(id) {
        return this.tanks.find(t => t.id === id);
    }
    /**
     * Connect a fuel line to a tank
     */
    connectFuelLine(line, tankId) {
        const tank = this.getTank(tankId);
        if (!tank)
            return false;
        this.fuelLines[line].connectedTank = tankId;
        return true;
    }
    /**
     * Open/close a valve
     */
    setValve(tankId, valve, open) {
        const tank = this.getTank(tankId);
        if (!tank)
            return false;
        if (valve === 'crossfeedTo') {
            // Special case for crossfeed
            return false;
        }
        tank.valves[valve] = open;
        return true;
    }
    /**
     * Set up crossfeed between tanks
     */
    setCrossfeed(sourceTankId, destTankId) {
        const sourceTank = this.getTank(sourceTankId);
        if (!sourceTank)
            return false;
        if (destTankId) {
            const destTank = this.getTank(destTankId);
            if (!destTank)
                return false;
            sourceTank.valves.crossfeedTo = destTankId;
        }
        else {
            sourceTank.valves.crossfeedTo = undefined;
        }
        return true;
    }
    /**
     * Set fuel pump state
     */
    setFuelPump(line, active) {
        this.fuelLines[line].fuelPumpActive = active;
    }
    /**
     * Get current state for debugging/testing
     */
    getState() {
        return {
            tanks: this.tanks.map(t => ({
                id: t.id,
                fuelMass: t.fuelMass,
                pressureBar: t.pressureBar,
                temperature: t.temperature,
                fuelPercent: (t.fuelMass / t.capacity) * 100
            })),
            fuelLines: this.fuelLines,
            totalFuel: this.getTotalFuelMass(),
            balance: this.getFuelBalance(),
            totalConsumed: this.totalFuelConsumed
        };
    }
    /**
     * Log an event
     */
    logEvent(time, type, data) {
        // Only log each event type once per second to avoid spam
        const recentEvent = this.events.find(e => e.type === type &&
            e.data.tankId === data.tankId &&
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
exports.FuelSystem = FuelSystem;
//# sourceMappingURL=fuel-system.js.map