"use strict";
/**
 * Power Budget System
 *
 * Manages power generation, distribution, brownouts, and battery management
 * Critical for submarine simulator feel - power management affects everything!
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.PowerBudgetSystem = exports.PowerPriority = exports.PowerSourceType = void 0;
var PowerSourceType;
(function (PowerSourceType) {
    PowerSourceType["REACTOR"] = "reactor";
    PowerSourceType["SOLAR"] = "solar";
    PowerSourceType["RTG"] = "rtg";
    PowerSourceType["FUEL_CELL"] = "fuel_cell";
})(PowerSourceType || (exports.PowerSourceType = PowerSourceType = {}));
var PowerPriority;
(function (PowerPriority) {
    PowerPriority[PowerPriority["CRITICAL"] = 0] = "CRITICAL";
    PowerPriority[PowerPriority["HIGH"] = 1] = "HIGH";
    PowerPriority[PowerPriority["MEDIUM"] = 2] = "MEDIUM";
    PowerPriority[PowerPriority["LOW"] = 3] = "LOW"; // Lighting, comfort
})(PowerPriority || (exports.PowerPriority = PowerPriority = {}));
/**
 * Power Budget System
 */
class PowerBudgetSystem {
    constructor(config) {
        this.sources = new Map();
        this.consumers = new Map();
        this.batteries = new Map();
        // Statistics
        this.totalEnergyConsumed = 0;
        this.totalEnergyGenerated = 0;
        this.brownoutActive = false;
        this.powerDeficit = 0;
        for (const source of config.sources) {
            this.sources.set(source.id, source);
        }
        for (const consumer of config.consumers) {
            this.consumers.set(consumer.id, consumer);
        }
        for (const battery of config.batteries) {
            this.batteries.set(battery.id, battery);
        }
    }
    /**
     * Update power budget system
     */
    update(dt) {
        // PHASE 1: Calculate total available power
        let totalAvailablePower = 0;
        for (const source of this.sources.values()) {
            if (!source.powered) {
                source.currentOutput = 0;
                continue;
            }
            switch (source.type) {
                case PowerSourceType.REACTOR:
                    source.currentOutput = source.maxOutput * source.efficiency;
                    break;
                case PowerSourceType.SOLAR:
                    const sunExposure = source.sunExposure ?? 1.0;
                    source.currentOutput = source.maxOutput * source.efficiency * sunExposure;
                    break;
                case PowerSourceType.RTG:
                    source.currentOutput = source.maxOutput; // Constant output
                    break;
                case PowerSourceType.FUEL_CELL:
                    source.currentOutput = source.maxOutput * source.efficiency;
                    break;
            }
            totalAvailablePower += source.currentOutput;
        }
        // PHASE 2: Calculate total power demand
        let totalDemand = 0;
        for (const consumer of this.consumers.values()) {
            if (consumer.powered) {
                totalDemand += consumer.powerDraw;
            }
        }
        // PHASE 3: Distribute power by priority
        let remainingPower = totalAvailablePower;
        let totalActualConsumption = 0;
        // Sort consumers by priority
        const sortedConsumers = Array.from(this.consumers.values()).sort((a, b) => {
            return a.priority - b.priority; // Lower number = higher priority
        });
        for (const consumer of sortedConsumers) {
            if (!consumer.powered) {
                consumer.actualPower = 0;
                continue;
            }
            if (remainingPower >= consumer.powerDraw) {
                // Full power available
                consumer.actualPower = consumer.powerDraw;
                remainingPower -= consumer.powerDraw;
                totalActualConsumption += consumer.powerDraw;
            }
            else {
                // Partial or no power
                consumer.actualPower = Math.max(0, remainingPower);
                totalActualConsumption += consumer.actualPower;
                remainingPower = 0;
            }
        }
        // PHASE 4: Battery management
        // Check if we have excess power (generation > demand) or deficit (demand > generation)
        const powerBalance = totalAvailablePower - totalDemand;
        if (powerBalance > 0) {
            // Excess power - charge batteries
            this.chargeBatteries(powerBalance, dt);
        }
        else if (powerBalance < 0) {
            // Power deficit - discharge batteries to meet unmet demand
            const powerNeeded = -powerBalance;
            const powerFromBatteries = this.dischargeBatteries(powerNeeded, dt);
            // Distribute additional power from batteries to consumers who didn't get full power
            if (powerFromBatteries > 0) {
                this.redistributePower(powerFromBatteries, sortedConsumers);
                totalActualConsumption += Math.min(powerFromBatteries, powerNeeded);
            }
        }
        // PHASE 5: Update statistics
        this.totalEnergyGenerated += (totalAvailablePower * dt) / 3600; // kWh
        this.totalEnergyConsumed += (totalActualConsumption * dt) / 3600; // kWh
        // Check for brownout
        this.brownoutActive = totalDemand > totalAvailablePower + this.getTotalBatteryDischargeCapacity();
        this.powerDeficit = this.brownoutActive ? totalDemand - totalAvailablePower : 0;
    }
    /**
     * Charge batteries from excess power
     */
    chargeBatteries(excessPower, dt) {
        let remainingExcess = excessPower;
        for (const battery of this.batteries.values()) {
            if (remainingExcess <= 0)
                break;
            if (battery.currentCharge >= battery.capacity)
                continue;
            // Limit by charge rate
            const maxChargeNow = Math.min(battery.maxChargeRate, (battery.capacity - battery.currentCharge) / (dt / 3600) // Don't overcharge
            );
            const chargeRate = Math.min(remainingExcess, maxChargeNow);
            // Account for efficiency
            const energyAdded = (chargeRate * dt / 3600) * battery.efficiency;
            battery.currentCharge = Math.min(battery.capacity, battery.currentCharge + energyAdded);
            remainingExcess -= chargeRate;
        }
    }
    /**
     * Discharge batteries to meet power deficit
     */
    dischargeBatteries(powerNeeded, dt) {
        let totalDischarged = 0;
        for (const battery of this.batteries.values()) {
            if (powerNeeded <= 0)
                break;
            if (battery.currentCharge <= 0)
                continue;
            // Limit by discharge rate
            const maxDischargeNow = Math.min(battery.maxDischargeRate, battery.currentCharge / (dt / 3600) // Don't over-discharge
            );
            const dischargeRate = Math.min(powerNeeded, maxDischargeNow);
            // Account for efficiency
            const energyRemoved = dischargeRate * dt / 3600;
            battery.currentCharge = Math.max(0, battery.currentCharge - energyRemoved);
            totalDischarged += dischargeRate;
            powerNeeded -= dischargeRate;
        }
        return totalDischarged;
    }
    /**
     * Redistribute additional power from batteries
     */
    redistributePower(additionalPower, sortedConsumers) {
        let remainingPower = additionalPower;
        for (const consumer of sortedConsumers) {
            if (remainingPower <= 0)
                break;
            if (!consumer.powered)
                continue;
            const deficit = consumer.powerDraw - consumer.actualPower;
            if (deficit > 0) {
                const additionalForConsumer = Math.min(deficit, remainingPower);
                consumer.actualPower += additionalForConsumer;
                remainingPower -= additionalForConsumer;
            }
        }
    }
    /**
     * Get total battery discharge capacity
     */
    getTotalBatteryDischargeCapacity() {
        let total = 0;
        for (const battery of this.batteries.values()) {
            if (battery.currentCharge > 0) {
                total += battery.maxDischargeRate;
            }
        }
        return total;
    }
    /**
     * Get consumer by ID
     */
    getConsumer(id) {
        return this.consumers.get(id);
    }
    /**
     * Get source by ID
     */
    getSource(id) {
        return this.sources.get(id);
    }
    /**
     * Get battery by ID
     */
    getBattery(id) {
        return this.batteries.get(id);
    }
    /**
     * Get statistics
     */
    getStatistics() {
        let totalGeneration = 0;
        for (const source of this.sources.values()) {
            totalGeneration += source.currentOutput;
        }
        let totalConsumption = 0;
        for (const consumer of this.consumers.values()) {
            totalConsumption += consumer.actualPower;
        }
        let batteryCharge = 0;
        let batteryCapacity = 0;
        for (const battery of this.batteries.values()) {
            batteryCharge += battery.currentCharge;
            batteryCapacity += battery.capacity;
        }
        return {
            totalGeneration,
            totalConsumption,
            totalEnergyConsumed: this.totalEnergyConsumed,
            totalEnergyGenerated: this.totalEnergyGenerated,
            batteryCharge,
            batteryCapacity,
            brownoutActive: this.brownoutActive,
            powerDeficit: this.powerDeficit
        };
    }
    /**
     * Add power source
     */
    addSource(source) {
        this.sources.set(source.id, source);
    }
    /**
     * Add power consumer
     */
    addConsumer(consumer) {
        this.consumers.set(consumer.id, consumer);
    }
    /**
     * Add battery
     */
    addBattery(battery) {
        this.batteries.set(battery.id, battery);
    }
}
exports.PowerBudgetSystem = PowerBudgetSystem;
//# sourceMappingURL=power-budget.js.map