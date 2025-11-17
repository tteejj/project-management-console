"use strict";
/**
 * Thermal System Physics Module
 *
 * Simulates:
 * - Per-component heat tracking
 * - Temperature dynamics with mass and specific heat
 * - Heat transfer between components and compartments
 * - Thermal conduction through bulkheads
 * - Heat generation from inefficiencies
 * - Passive cooling and radiation
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.ThermalSystem = void 0;
class ThermalSystem {
    constructor(config) {
        // Tracking
        this.totalHeatGenerated = 0; // J
        this.events = [];
        this.heatSources = new Map();
        if (config?.heatSources) {
            config.heatSources.forEach(source => {
                this.heatSources.set(source.name, source);
            });
        }
        else {
            this.createDefaultHeatSources();
        }
        this.compartments = config?.compartments || this.createDefaultCompartments();
        this.thermalConductivity = config?.thermalConductivity || 50; // W/K
        this.ambientSpaceTemp = config?.ambientSpaceTemp || 2.7; // K (cosmic background)
    }
    createDefaultHeatSources() {
        const sources = [
            {
                name: 'reactor',
                heatGenerationW: 0,
                temperature: 400,
                mass: 200,
                specificHeat: 450,
                compartmentId: 1 // Engineering
            },
            {
                name: 'main_engine',
                heatGenerationW: 0,
                temperature: 293,
                mass: 150,
                specificHeat: 500,
                compartmentId: 2 // Engine bay
            },
            {
                name: 'battery',
                heatGenerationW: 0,
                temperature: 293,
                mass: 80,
                specificHeat: 800,
                compartmentId: 0 // Electronics
            },
            {
                name: 'hydraulic_pump_1',
                heatGenerationW: 0,
                temperature: 293,
                mass: 15,
                specificHeat: 1000,
                compartmentId: 1
            },
            {
                name: 'hydraulic_pump_2',
                heatGenerationW: 0,
                temperature: 293,
                mass: 15,
                specificHeat: 1000,
                compartmentId: 1
            },
            {
                name: 'coolant_pump_1',
                heatGenerationW: 0,
                temperature: 293,
                mass: 10,
                specificHeat: 1000,
                compartmentId: 1
            },
            {
                name: 'nav_computer',
                heatGenerationW: 0,
                temperature: 293,
                mass: 5,
                specificHeat: 700,
                compartmentId: 0
            }
        ];
        sources.forEach(source => {
            this.heatSources.set(source.name, source);
        });
    }
    createDefaultCompartments() {
        return [
            {
                id: 0,
                name: 'Electronics',
                volume: 30,
                gasMass: 36, // ~1.2 kg/m³ air density
                temperature: 293,
                neighborIds: [1]
            },
            {
                id: 1,
                name: 'Engineering',
                volume: 50,
                gasMass: 60,
                temperature: 293,
                neighborIds: [0, 2]
            },
            {
                id: 2,
                name: 'Engine Bay',
                volume: 40,
                gasMass: 48,
                temperature: 293,
                neighborIds: [1]
            }
        ];
    }
    /**
     * Main update loop
     */
    update(dt, simulationTime) {
        // 1. Update component temperatures from heat generation
        this.updateComponentTemperatures(dt);
        // 2. Heat transfer from components to compartments
        this.transferHeatToCompartments(dt);
        // 3. Thermal conduction between compartments
        this.conductHeatBetweenCompartments(dt);
        // 4. Check for overheating warnings
        this.checkWarnings(simulationTime);
        // 5. Track total heat
        this.trackHeatGeneration(dt);
    }
    /**
     * Update component temperatures based on heat generation
     */
    updateComponentTemperatures(dt) {
        for (const [name, source] of this.heatSources) {
            if (source.heatGenerationW > 0) {
                // Q = m * c * ΔT
                // ΔT = Q / (m * c) = (P * dt) / (m * c)
                const tempRise = (source.heatGenerationW * dt) / (source.mass * source.specificHeat);
                source.temperature += tempRise;
            }
        }
    }
    /**
     * Transfer heat from hot components to compartment air
     */
    transferHeatToCompartments(dt) {
        for (const [name, source] of this.heatSources) {
            const compartment = this.compartments[source.compartmentId];
            if (!compartment)
                continue;
            // Heat transfer proportional to temperature difference
            const tempDiff = source.temperature - compartment.temperature;
            // Thermal conductance (simplified convection/conduction)
            const thermalConductance = this.getThermalConductance(name);
            const heatTransferW = tempDiff * thermalConductance;
            // Component cools
            const componentTempDrop = (heatTransferW * dt) / (source.mass * source.specificHeat);
            source.temperature -= componentTempDrop;
            // Compartment heats
            const airSpecificHeat = 1000; // J/(kg·K)
            const compartmentTempRise = (heatTransferW * dt) / (compartment.gasMass * airSpecificHeat);
            compartment.temperature += compartmentTempRise;
        }
    }
    /**
     * Conduct heat between adjacent compartments
     */
    conductHeatBetweenCompartments(dt) {
        const processed = new Set();
        for (const comp of this.compartments) {
            for (const neighborId of comp.neighborIds) {
                const pairKey = `${Math.min(comp.id, neighborId)}-${Math.max(comp.id, neighborId)}`;
                if (processed.has(pairKey))
                    continue;
                processed.add(pairKey);
                const neighbor = this.compartments[neighborId];
                if (!neighbor)
                    continue;
                const tempDiff = comp.temperature - neighbor.temperature;
                const heatFlowW = tempDiff * this.thermalConductivity;
                const airSpecificHeat = 1000;
                const comp1TempChange = -(heatFlowW * dt) / (comp.gasMass * airSpecificHeat);
                const comp2TempChange = (heatFlowW * dt) / (neighbor.gasMass * airSpecificHeat);
                comp.temperature += comp1TempChange;
                neighbor.temperature += comp2TempChange;
            }
        }
    }
    /**
     * Check for overheating warnings
     */
    checkWarnings(time) {
        for (const [name, source] of this.heatSources) {
            // Component-specific temperature limits
            const limit = this.getTemperatureLimit(name);
            if (source.temperature > limit) {
                this.logEvent(time, 'component_overheating', {
                    component: name,
                    temperature: source.temperature,
                    limit: limit
                });
            }
        }
        for (const comp of this.compartments) {
            if (comp.temperature > 330) { // 57°C
                this.logEvent(time, 'compartment_hot', {
                    compartmentId: comp.id,
                    name: comp.name,
                    temperature: comp.temperature
                });
            }
            if (comp.temperature < 260) { // -13°C
                this.logEvent(time, 'compartment_cold', {
                    compartmentId: comp.id,
                    name: comp.name,
                    temperature: comp.temperature
                });
            }
        }
    }
    /**
     * Track total heat generation
     */
    trackHeatGeneration(dt) {
        for (const [name, source] of this.heatSources) {
            this.totalHeatGenerated += source.heatGenerationW * dt;
        }
    }
    /**
     * Get thermal conductance for a component (W/K)
     */
    getThermalConductance(componentName) {
        // Different components have different surface areas and contact
        // Higher values = better heat transfer to compartment air
        const conductances = {
            'reactor': 20, // Large, good air circulation
            'main_engine': 30, // Very hot, large surface area
            'battery': 10, // Moderate surface area
            'hydraulic_pump_1': 5,
            'hydraulic_pump_2': 5,
            'coolant_pump_1': 5,
            'nav_computer': 3
        };
        return conductances[componentName] || 5;
    }
    /**
     * Get temperature limit for component (K)
     */
    getTemperatureLimit(componentName) {
        const limits = {
            'reactor': 900, // Auto SCRAM
            'main_engine': 800,
            'battery': 330, // 57°C
            'hydraulic_pump_1': 400,
            'hydraulic_pump_2': 400,
            'coolant_pump_1': 400,
            'nav_computer': 350
        };
        return limits[componentName] || 350;
    }
    /**
     * Add heat to a specific component
     */
    addHeat(componentName, joules) {
        const source = this.heatSources.get(componentName);
        if (source) {
            const tempRise = joules / (source.mass * source.specificHeat);
            source.temperature += tempRise;
        }
    }
    /**
     * Set heat generation rate for a component
     */
    setHeatGeneration(componentName, watts) {
        const source = this.heatSources.get(componentName);
        if (source) {
            source.heatGenerationW = Math.max(0, watts);
        }
    }
    /**
     * Get component temperature
     */
    getComponentTemperature(componentName) {
        const source = this.heatSources.get(componentName);
        return source ? source.temperature : 0;
    }
    /**
     * Get compartment temperature
     */
    getCompartmentTemperature(compartmentId) {
        const comp = this.compartments[compartmentId];
        return comp ? comp.temperature : 0;
    }
    /**
     * Set compartment temperature (for external cooling/heating)
     */
    setCompartmentTemperature(compartmentId, tempK) {
        const comp = this.compartments[compartmentId];
        if (comp) {
            comp.temperature = tempK;
        }
    }
    /**
     * Get component by name
     */
    getComponent(name) {
        return this.heatSources.get(name);
    }
    /**
     * Get compartment by ID
     */
    getCompartment(id) {
        return this.compartments[id];
    }
    /**
     * Get current state for debugging/testing
     */
    getState() {
        return {
            components: Array.from(this.heatSources.entries()).map(([name, source]) => ({
                name,
                temperature: source.temperature,
                heatGeneration: source.heatGenerationW,
                compartmentId: source.compartmentId
            })),
            compartments: this.compartments.map(comp => ({
                id: comp.id,
                name: comp.name,
                temperature: comp.temperature,
                gasMass: comp.gasMass
            })),
            totalHeatGenerated: this.totalHeatGenerated
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
exports.ThermalSystem = ThermalSystem;
//# sourceMappingURL=thermal-system.js.map