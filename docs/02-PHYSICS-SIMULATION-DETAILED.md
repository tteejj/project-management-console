# Physics & Simulation Systems (DETAILED)

## Philosophy

**"Deep Simulation, Emergent Complexity"**

We ARE simulating Dwarf Fortress-level system interconnections. Every system consumes resources, generates waste products, and can be rerouted/jury-rigged. Physics creates emergent gameplay through realistic system interactions.

**Simulation Depth:**
- Fluid dynamics (coolant, fuel, hydraulic fluid, water, gases)
- Energy accounting (every watt tracked)
- Resource consumption (volume-based, rate-based)
- Routing flexibility (reroute around damage)
- Cascading failures (realistic cause-effect chains)

**Performance Target:** 60 FPS (aggressive optimization required)

---

## Resource Accounting Framework

### Tracked Resources

**Fluids:**
- Fuel (hydrazine or similar) - mass in kg, volume in L
- Coolant (water/glycol mix) - volume in L, temperature
- Hydraulic fluid - volume in L, pressure in bar
- Water (potable) - volume in L
- Compressed gases (N2, O2) - mass in kg, pressure in bar, volume in L

**Gases (per compartment):**
- O2 - mass in kg
- CO2 - mass in kg
- N2 - mass in kg
- H2O vapor - mass in kg
- Trace gases/contaminants - ppm

**Electrical:**
- Battery charge - kWh
- Capacitor charge - kJ (for high-draw systems)
- Reactor fuel - % remaining (degradation)

**Consumables:**
- CO2 scrubber media - kg remaining
- Fire suppression agent (Halon) - kg
- O2 generator cartridges - units
- Spare parts - units
- Repair patches - units

**Energy Tracking:**
- Every component tracks: power draw (W), heat generation (W), efficiency (%)

---

## 1. Detailed Electrical System

### Power Generation

**Reactor (Radioisotope Thermoelectric Generator or Small Fission)**
```typescript
class Reactor {
  fuelRemaining: number = 100; // %
  fuelDegradationRate: number = 0.001; // % per second at 100% throttle

  throttle: number = 0; // 0-1
  maxOutputKW: number = 8.0;
  currentOutputKW: number = 0;

  temperature: number = 400; // K
  maxSafeTemp: number = 800; // K
  scramTemp: number = 900; // K

  coolantFlowRequired: number = 15; // L/min at 100% throttle
  coolantInletTemp: number = 293; // K
  coolantOutletTemp: number = 400; // K (when operating)

  status: 'offline' | 'starting' | 'online' | 'scrammed' = 'offline';
  startupTime: number = 30; // seconds
  startupTimer: number = 0;

  // Efficiency degrades with temperature
  thermalEfficiency: number = 0.33; // 33% electrical, 67% waste heat

  update(dt: number, coolantFlow: number) {
    if (this.status === 'starting') {
      this.startupTimer += dt;
      if (this.startupTimer >= this.startupTime) {
        this.status = 'online';
      }
      return;
    }

    if (this.status === 'online') {
      // Generate power
      this.currentOutputKW = this.maxOutputKW * this.throttle;

      // Consume fuel (degradation)
      this.fuelRemaining -= this.fuelDegradationRate * this.throttle * dt;

      // Heat generation (waste heat from inefficiency)
      const thermalPowerKW = this.currentOutputKW / this.thermalEfficiency - this.currentOutputKW;
      const heatGeneratedW = thermalPowerKW * 1000;

      // Temperature management
      if (coolantFlow < this.coolantFlowRequired * this.throttle) {
        // Insufficient cooling
        this.temperature += (heatGeneratedW * 0.001) * dt; // simplified
      } else {
        // Adequate cooling
        const heatRemovedW = coolantFlow * 4186 * (this.coolantOutletTemp - this.coolantInletTemp) / 60;
        const netHeat = heatGeneratedW - heatRemovedW;
        this.temperature += (netHeat * 0.0005) * dt;
      }

      // SCRAM if overtemp
      if (this.temperature >= this.scramTemp) {
        this.SCRAM();
      }
    }
  }

  start() {
    if (this.status === 'offline') {
      this.status = 'starting';
      this.startupTimer = 0;
    }
  }

  SCRAM() {
    this.status = 'scrammed';
    this.throttle = 0;
    this.currentOutputKW = 0;
    // Requires manual reset
  }
}
```

### Power Distribution (Detailed)

**Bus Architecture:**
```typescript
interface PowerBus {
  name: string; // 'A' or 'B'
  voltage: number; // 28V DC
  maxCapacity: number; // kW
  currentLoad: number; // kW
  faults: number; // fault counter

  connected: boolean;
  crosstieToOtherBus: boolean;
}

interface CircuitBreaker {
  name: string;
  bus: 'A' | 'B';
  on: boolean;
  loadW: number; // Watts
  essential: boolean; // Can't be manually tripped
  tripThreshold: number; // Amps (overcurrent protection)
}

class ElectricalSystem {
  buses: PowerBus[] = [
    { name: 'A', voltage: 28, maxCapacity: 4.5, currentLoad: 0, faults: 0, connected: true, crosstieToOtherBus: false },
    { name: 'B', voltage: 28, maxCapacity: 4.5, currentLoad: 0, faults: 0, connected: true, crosstieToOtherBus: false }
  ];

  breakers: Map<string, CircuitBreaker> = new Map([
    // Life Support
    ['o2_generator', { name: 'O2 Gen', bus: 'A', on: true, loadW: 800, essential: true, tripThreshold: 30 }],
    ['co2_scrubber', { name: 'CO2 Scrub', bus: 'A', on: true, loadW: 600, essential: true, tripThreshold: 25 }],
    ['coolant_pump_primary', { name: 'Coolant 1', bus: 'A', on: true, loadW: 400, essential: true, tripThreshold: 20 }],
    ['coolant_pump_backup', { name: 'Coolant 2', bus: 'B', on: false, loadW: 400, essential: false, tripThreshold: 20 }],

    // Propulsion
    ['fuel_pump_main', { name: 'Fuel Pump', bus: 'A', on: true, loadW: 300, essential: false, tripThreshold: 15 }],
    ['gimbal_actuators', { name: 'Gimbal Act', bus: 'A', on: true, loadW: 200, essential: false, tripThreshold: 10 }],
    ['rcs_valves', { name: 'RCS Valves', bus: 'B', on: true, loadW: 150, essential: false, tripThreshold: 8 }],

    // Navigation & Sensors
    ['nav_computer', { name: 'Nav Comp', bus: 'B', on: true, loadW: 250, essential: false, tripThreshold: 12 }],
    ['radar', { name: 'Radar', bus: 'B', on: true, loadW: 350, essential: false, tripThreshold: 15 }],
    ['lidar', { name: 'LIDAR', bus: 'B', on: true, loadW: 200, essential: false, tripThreshold: 10 }],

    // Hydraulics
    ['hydraulic_pump_1', { name: 'Hydraulic 1', bus: 'A', on: true, loadW: 500, essential: false, tripThreshold: 20 }],
    ['hydraulic_pump_2', { name: 'Hydraulic 2', bus: 'B', on: false, loadW: 500, essential: false, tripThreshold: 20 }],

    // Environmental
    ['heater_compartment_1', { name: 'Heat C1', bus: 'A', on: true, loadW: 300, essential: false, tripThreshold: 12 }],
    ['heater_compartment_2', { name: 'Heat C2', bus: 'A', on: true, loadW: 300, essential: false, tripThreshold: 12 }],
    ['heater_compartment_3', { name: 'Heat C3', bus: 'B', on: true, loadW: 300, essential: false, tripThreshold: 12 }],
    ['lighting', { name: 'Lights', bus: 'B', on: true, loadW: 150, essential: false, tripThreshold: 8 }],

    // Doors & Mechanisms
    ['door_actuators', { name: 'Doors', bus: 'A', on: true, loadW: 100, essential: false, tripThreshold: 5 }],
    ['valve_actuators', { name: 'Valves', bus: 'B', on: true, loadW: 80, essential: false, tripThreshold: 4 }],

    // Communications
    ['comms', { name: 'Comms', bus: 'B', on: true, loadW: 120, essential: false, tripThreshold: 6 }],
  ]);

  battery: {
    chargeKWh: number;
    capacityKWh: number;
    maxChargeRateKW: number;
    maxDischargeRateKW: number;
    temperature: number;
    health: number; // degrades over charge cycles
  } = {
    chargeKWh: 8.0,
    capacityKWh: 12.0,
    maxChargeRateKW: 2.0,
    maxDischargeRateKW: 3.5,
    temperature: 293,
    health: 100
  };

  capacitorBank: {
    chargeKJ: number;
    capacityKJ: number;
    chargeRateKW: number;
    dischargeRateKW: number;
  } = {
    chargeKJ: 50,
    capacityKJ: 100,
    chargeRateKW: 10,
    dischargeRateKW: 50 // for high-draw startup surges
  };

  update(dt: number, reactor: Reactor) {
    // Calculate bus loads
    this.buses[0].currentLoad = 0;
    this.buses[1].currentLoad = 0;

    for (const [key, breaker] of this.breakers) {
      if (breaker.on) {
        const busIndex = breaker.bus === 'A' ? 0 : 1;
        this.buses[busIndex].currentLoad += breaker.loadW / 1000; // to kW

        // Check for overcurrent
        const current = breaker.loadW / this.buses[busIndex].voltage;
        if (current > breaker.tripThreshold) {
          // Trip breaker
          breaker.on = false;
          eventBus.emit('breaker_tripped', key);
        }
      }
    }

    // Apply crosstie if enabled
    let totalLoad = this.buses[0].currentLoad + this.buses[1].currentLoad;
    if (this.buses[0].crosstieToOtherBus && this.buses[1].crosstieToOtherBus) {
      // Balanced across both buses
      const avgLoad = totalLoad / 2;
      this.buses[0].currentLoad = avgLoad;
      this.buses[1].currentLoad = avgLoad;
    }

    // Power balance
    const totalLoadKW = this.buses[0].currentLoad + this.buses[1].currentLoad;
    const reactorOutputKW = reactor.currentOutputKW;
    const netPowerKW = reactorOutputKW - totalLoadKW;

    if (netPowerKW < 0) {
      // Deficit - drain battery and/or capacitors
      const deficitKW = -netPowerKW;

      // Try capacitors first (fast discharge)
      const capacitorDischargeKW = Math.min(deficitKW, this.capacitorBank.dischargeRateKW);
      const capacitorDischargeKJ = capacitorDischargeKW * dt;

      if (this.capacitorBank.chargeKJ >= capacitorDischargeKJ) {
        this.capacitorBank.chargeKJ -= capacitorDischargeKJ;
      }

      // Remaining deficit from battery
      const remainingDeficitKW = deficitKW - capacitorDischargeKW;
      const batteryDischargeKW = Math.min(remainingDeficitKW, this.battery.maxDischargeRateKW);
      const batteryDischargeKWh = batteryDischargeKW * (dt / 3600);

      this.battery.chargeKWh -= batteryDischargeKWh;

      // Battery heat from discharge
      this.battery.temperature += (batteryDischargeKW * 0.1) * dt; // inefficiency heat

      if (this.battery.chargeKWh <= 0) {
        this.battery.chargeKWh = 0;
        this.blackout();
      }
    } else {
      // Surplus - charge capacitors then battery
      const surplusKW = netPowerKW;

      // Charge capacitors first (fast)
      const capacitorChargeNeeded = (this.capacitorBank.capacityKJ - this.capacitorBank.chargeKJ);
      const capacitorChargeKW = Math.min(surplusKW, this.capacitorBank.chargeRateKW);
      const capacitorChargeKJ = capacitorChargeKW * dt;

      this.capacitorBank.chargeKJ = Math.min(
        this.capacitorBank.capacityKJ,
        this.capacitorBank.chargeKJ + capacitorChargeKJ
      );

      // Remaining surplus to battery
      const remainingSurplusKW = surplusKW - capacitorChargeKW;
      const batteryChargeKW = Math.min(remainingSurplusKW, this.battery.maxChargeRateKW);
      const batteryChargeKWh = batteryChargeKW * (dt / 3600);

      this.battery.chargeKWh = Math.min(
        this.battery.capacityKWh,
        this.battery.chargeKWh + batteryChargeKWh
      );

      // Battery heat from charging
      this.battery.temperature += (batteryChargeKW * 0.05) * dt;
    }

    // Battery cooling (passive)
    this.battery.temperature -= (this.battery.temperature - 293) * 0.01 * dt;
  }

  blackout() {
    // Trip all non-essential breakers
    for (const [key, breaker] of this.breakers) {
      if (!breaker.essential) {
        breaker.on = false;
      }
    }
    eventBus.emit('blackout');
  }

  toggleBreaker(key: string) {
    const breaker = this.breakers.get(key);
    if (breaker && !breaker.essential) {
      breaker.on = !breaker.on;
    }
  }

  setCrosstie(enable: boolean) {
    this.buses[0].crosstieToOtherBus = enable;
    this.buses[1].crosstieToOtherBus = enable;
  }
}
```

---

## 2. Hydraulic System

**Purpose:** Actuate valves, doors, gimbal mechanisms, landing gear

```typescript
class HydraulicSystem {
  // Two independent hydraulic loops for redundancy
  loops: HydraulicLoop[] = [
    {
      name: 'Primary',
      fluidVolume: 15, // liters
      maxVolume: 20,
      pressure: 210, // bar (3000 psi)
      targetPressure: 210,
      minPressure: 140, // below this, actuators weak

      pump: {
        powered: true,
        powerDraw: 500, // W
        flowRate: 5, // L/min at full speed
        efficiency: 0.75
      },

      accumulator: {
        chargedVolume: 2, // liters
        maxVolume: 3,
        prechargeBar: 100
      },

      leakRate: 0, // L/min (increases with damage)
      temperature: 320, // K (hydraulic fluid runs warm)

      consumers: [
        { name: 'main_gimbal', flowRate: 2, active: false },
        { name: 'door_actuators_1_3', flowRate: 1, active: false },
        { name: 'fuel_valves', flowRate: 0.5, active: false }
      ]
    },
    {
      name: 'Backup',
      fluidVolume: 15,
      maxVolume: 20,
      pressure: 210,
      targetPressure: 210,
      minPressure: 140,

      pump: {
        powered: false, // normally off
        powerDraw: 500,
        flowRate: 5,
        efficiency: 0.75
      },

      accumulator: {
        chargedVolume: 2,
        maxVolume: 3,
        prechargeBar: 100
      },

      leakRate: 0,
      temperature: 293,

      consumers: [
        { name: 'backup_gimbal', flowRate: 2, active: false },
        { name: 'door_actuators_4_6', flowRate: 1, active: false },
        { name: 'emergency_valves', flowRate: 0.5, active: false }
      ]
    }
  ];

  crossconnectOpen: boolean = false; // Can connect loops in emergency

  update(dt: number, electrical: ElectricalSystem) {
    for (const loop of this.loops) {
      // Pump operation
      if (loop.pump.powered && electrical.breakers.get(`hydraulic_pump_${loop.name.toLowerCase()}`).on) {
        // Pump increases pressure
        const flowGenerated = loop.pump.flowRate * (dt / 60); // liters
        const pressureIncrease = (flowGenerated / loop.maxVolume) * loop.targetPressure;
        loop.pressure = Math.min(loop.targetPressure, loop.pressure + pressureIncrease);

        // Pump generates heat
        const heatGenerated = loop.pump.powerDraw * (1 - loop.pump.efficiency);
        loop.temperature += (heatGenerated * 0.001) * dt;
      }

      // Consumer draw
      let totalFlowDemand = 0;
      for (const consumer of loop.consumers) {
        if (consumer.active) {
          totalFlowDemand += consumer.flowRate;
        }
      }

      if (totalFlowDemand > 0) {
        const flowDrawn = totalFlowDemand * (dt / 60);
        const pressureDecrease = (flowDrawn / loop.maxVolume) * loop.targetPressure;
        loop.pressure = Math.max(0, loop.pressure - pressureDecrease);

        // If pressure too low, consumers don't work properly
        if (loop.pressure < loop.minPressure) {
          eventBus.emit('hydraulic_pressure_low', loop.name);
        }
      }

      // Leaks
      if (loop.leakRate > 0) {
        const leaked = loop.leakRate * (dt / 60);
        loop.fluidVolume -= leaked;
        loop.pressure -= (leaked / loop.maxVolume) * loop.targetPressure;

        if (loop.fluidVolume <= 0) {
          loop.fluidVolume = 0;
          loop.pressure = 0;
          eventBus.emit('hydraulic_system_dry', loop.name);
        }
      }

      // Accumulator helps buffer pressure spikes
      // (simplified - just provides reserve)

      // Temperature cooling (passive)
      loop.temperature -= (loop.temperature - 293) * 0.02 * dt;
    }

    // Crossconnect allows sharing fluid between loops
    if (this.crossconnectOpen) {
      const avgVolume = (this.loops[0].fluidVolume + this.loops[1].fluidVolume) / 2;
      const avgPressure = (this.loops[0].pressure + this.loops[1].pressure) / 2;

      this.loops[0].fluidVolume = avgVolume;
      this.loops[1].fluidVolume = avgVolume;
      this.loops[0].pressure = avgPressure;
      this.loops[1].pressure = avgPressure;
    }
  }

  activateConsumer(loopIndex: number, consumerName: string, active: boolean) {
    const consumer = this.loops[loopIndex].consumers.find(c => c.name === consumerName);
    if (consumer) {
      consumer.active = active;
    }
  }

  canActuate(loopIndex: number): boolean {
    return this.loops[loopIndex].pressure >= this.loops[loopIndex].minPressure;
  }
}
```

---

## 3. Propulsion System (Detailed)

### Fuel System

```typescript
class FuelSystem {
  // Multiple fuel tanks with crossfeed capability
  tanks: FuelTank[] = [
    {
      id: 'main_1',
      volume: 100, // liters
      fuelMass: 80, // kg (hydrazine density ~1.01 kg/L, so ~80% full)
      capacity: 100,
      position: { x: 0, y: 0 }, // on ship (for balance calculation)

      pressurized: true,
      pressureBar: 2.5, // fuel pressurization
      pressurantType: 'N2',
      pressurantMass: 0.5, // kg of compressed N2

      temperature: 293,

      valves: {
        feedToEngine: false,
        feedToTank2: false,
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
        feedToTank1: false,
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
        feedToRCS: false,
        fillPort: false,
        vent: false
      }
    }
  ];

  fuelLines: {
    mainEngine: {
      connectedTank: string | null;
      flowRate: number; // L/s
      pressure: number; // bar
      fuelPumpActive: boolean;
    };
    rcsManifold: {
      connectedTank: string | null;
      flowRate: number;
      pressure: number;
    };
  } = {
    mainEngine: {
      connectedTank: null,
      flowRate: 0,
      pressure: 0,
      fuelPumpActive: false
    },
    rcsManifold: {
      connectedTank: null,
      flowRate: 0,
      pressure: 0
    }
  };

  update(dt: number, electrical: ElectricalSystem, hydraulic: HydraulicSystem) {
    // Update tank pressures based on fuel remaining
    for (const tank of this.tanks) {
      const fuelVolume = tank.fuelMass / 1.01; // kg to liters
      const ullageVolume = tank.volume - fuelVolume;

      // Pressurant expands into ullage (ideal gas approximation)
      if (tank.pressurized) {
        // Simplified: pressure = (pressurant mass * R * T) / ullage volume
        tank.pressureBar = (tank.pressurantMass * 8.314 * tank.temperature) / (ullageVolume * 28); // N2 molar mass 28

        if (tank.pressureBar < 1.5) {
          eventBus.emit('fuel_pressure_low', tank.id);
        }
      }
    }

    // Fuel flow to main engine
    if (this.fuelLines.mainEngine.connectedTank) {
      const tank = this.tanks.find(t => t.id === this.fuelLines.mainEngine.connectedTank);

      if (tank && tank.valves.feedToEngine) {
        // Fuel pressure depends on tank pressure + pump
        let linePressure = tank.pressureBar;
        if (this.fuelLines.mainEngine.fuelPumpActive) {
          linePressure += 5; // pump adds 5 bar
        }

        this.fuelLines.mainEngine.pressure = linePressure;

        // Flow rate depends on demand from engine
        // (calculated by engine system)
      }
    }

    // Fuel flow to RCS
    if (this.fuelLines.rcsManifold.connectedTank) {
      const tank = this.tanks.find(t => t.id === this.fuelLines.rcsManifold.connectedTank);

      if (tank && tank.valves.feedToRCS) {
        this.fuelLines.rcsManifold.pressure = tank.pressureBar;
      }
    }

    // Fuel transfer between tanks (if valves open)
    // (simplified - instant transfer based on pressure differential)

    // Valve actuation requires hydraulic pressure
    // (player can't open valves if hydraulic system failed)
  }

  consumeFuel(tankId: string, massKg: number): boolean {
    const tank = this.tanks.find(t => t.id === tankId);
    if (tank && tank.fuelMass >= massKg) {
      tank.fuelMass -= massKg;
      return true;
    }
    return false;
  }

  getTotalFuelMass(): number {
    return this.tanks.reduce((sum, tank) => sum + tank.fuelMass, 0);
  }

  getFuelBalance(): number {
    // Calculate center of mass offset
    let totalMass = 0;
    let weightedX = 0;
    let weightedY = 0;

    for (const tank of this.tanks) {
      totalMass += tank.fuelMass;
      weightedX += tank.fuelMass * tank.position.x;
      weightedY += tank.fuelMass * tank.position.y;
    }

    if (totalMass === 0) return 0;

    const comX = weightedX / totalMass;
    const comY = weightedY / totalMass;

    // Return distance from ship centerline
    return Math.sqrt(comX*comX + comY*comY);
  }
}
```

### Main Engine (Detailed)

```typescript
class MainEngine {
  thrust: number = 50000; // Newtons max
  specificImpulse: number = 300; // seconds (exhaust velocity = Isp * g)
  exhaustVelocity: number = 300 * 9.81; // m/s

  ignited: boolean = false;
  throttle: number = 0; // 0-1

  gimbal: {
    x: number; // -10 to +10 degrees
    y: number;
    actuationRate: number; // degrees per second
    hydraulicLoop: number; // which hydraulic loop controls this
  } = {
    x: 0,
    y: 0,
    actuationRate: 5,
    hydraulicLoop: 0
  };

  combustionChamber: {
    pressure: number; // bar
    temperature: number; // K
    maxTemp: number;
    maxPressure: number;
  } = {
    pressure: 0,
    temperature: 293,
    maxTemp: 3500,
    maxPressure: 100
  };

  nozzle: {
    throatDiameter: number; // meters
    expansionRatio: number;
    efficiency: number; // 0-1
  } = {
    throatDiameter: 0.15,
    expansionRatio: 40,
    efficiency: 0.92
  };

  fuelRequirements: {
    minPressureBar: number;
    minFlowRate: number; // kg/s at 100% throttle
  } = {
    minPressureBar: 2.0,
    minFlowRate: 15
  };

  update(dt: number, fuelSystem: FuelSystem, hydraulicSystem: HydraulicSystem) {
    if (this.ignited && this.throttle > 0) {
      // Check fuel availability
      const fuelPressure = fuelSystem.fuelLines.mainEngine.pressure;

      if (fuelPressure < this.fuelRequirements.minPressureBar) {
        // Flameout
        this.ignited = false;
        eventBus.emit('engine_flameout', 'fuel_pressure_low');
        return;
      }

      // Calculate fuel consumption
      const massFlowRate = this.fuelRequirements.minFlowRate * this.throttle; // kg/s
      const fuelConsumed = massFlowRate * dt;

      if (!fuelSystem.consumeFuel(fuelSystem.fuelLines.mainEngine.connectedTank, fuelConsumed)) {
        // Out of fuel
        this.ignited = false;
        eventBus.emit('engine_flameout', 'fuel_depleted');
        return;
      }

      // Calculate thrust (Tsiolkovsky equation simplified)
      const actualThrust = this.thrust * this.throttle * this.nozzle.efficiency;

      // Combustion chamber conditions
      this.combustionChamber.temperature = 2800 + (this.throttle * 700); // K
      this.combustionChamber.pressure = this.throttle * 80; // bar

      // Overheating check
      if (this.combustionChamber.temperature > this.combustionChamber.maxTemp) {
        // Engine damage
        eventBus.emit('engine_overheat');
        this.nozzle.efficiency *= 0.99; // permanent degradation
      }

      // Heat generated (waste heat)
      const heatGeneratedW = actualThrust * this.exhaustVelocity * (1 - this.nozzle.efficiency);

      // Apply thrust to ship
      const thrustAngle = ship.rotation + degToRad(this.gimbal.x) + degToRad(this.gimbal.y);
      const force = {
        x: Math.cos(thrustAngle) * actualThrust,
        y: Math.sin(thrustAngle) * actualThrust
      };

      ship.applyForce(force);

      // Heat generation to thermal system
      thermal.addHeat('engine_bay', heatGeneratedW * dt);
    }

    // Gimbal actuation (requires hydraulics)
    if (hydraulicSystem.canActuate(this.gimbal.hydraulicLoop)) {
      // Player can adjust gimbal
      // (handled by input system)
    } else {
      // Gimbal stuck in current position
      eventBus.emit('gimbal_hydraulic_failure');
    }
  }

  ignite(): boolean {
    // Requires fuel pressure and electric igniter
    if (fuelSystem.fuelLines.mainEngine.pressure >= this.fuelRequirements.minPressureBar) {
      this.ignited = true;
      return true;
    }
    return false;
  }
}
```

I'll continue this in the next file write - this is getting too long. Let me break this into multiple continued sections.


---

## 4. Coolant System (Detailed with Routing)

**Purpose:** Remove waste heat from reactor, engines, electronics

```typescript
class CoolantSystem {
  // Coolant is water/glycol mixture
  totalCoolant: number = 80; // liters
  maxCoolant: number = 100;
  coolantTemp: number = 310; // K (warm when circulating)

  coolantType: 'water_glycol' = 'water_glycol';
  specificHeat: number = 3800; // J/(kg·K)
  density: number = 1.05; // kg/L

  // Multiple coolant loops that can be rerouted
  loops: CoolantLoop[] = [
    {
      name: 'Primary',
      active: true,
      flowRate: 20, // L/min
      pump: {
        powered: true,
        powerDraw: 400, // W
        rpm: 3000,
        maxRPM: 4000,
        efficiency: 0.80
      },

      routing: {
        reactor: true,
        mainEngine: true,
        electronics: true,
        radiator1: true
      },

      inletTemp: 293,
      outletTemp: 320,
      pressureBar: 1.5,

      leakRate: 0 // L/min
    },
    {
      name: 'Backup',
      active: false,
      flowRate: 15,
      pump: {
        powered: false,
        powerDraw: 400,
        rpm: 0,
        maxRPM: 4000,
        efficiency: 0.80
      },

      routing: {
        reactor: false,
        mainEngine: false,
        electronics: true,
        radiator2: true
      },

      inletTemp: 293,
      outletTemp: 293,
      pressureBar: 0,

      leakRate: 0
    }
  ];

  radiators: Radiator[] = [
    {
      id: 'rad_1',
      deployed: true,
      area: 15, // m²
      emissivity: 0.85,
      temperature: 310,
      heatRejection: 0, // W (calculated)
      connectedLoop: 0
    },
    {
      id: 'rad_2',
      deployed: false, // retracted
      area: 12,
      emissivity: 0.85,
      temperature: 293,
      heatRejection: 0,
      connectedLoop: 1
    }
  ];

  heatExchangers: HeatExchanger[] = [
    { name: 'reactor_hx', efficiency: 0.90, heatTransferW: 0, coolantLoop: 0 },
    { name: 'engine_hx', efficiency: 0.85, heatTransferW: 0, coolantLoop: 0 },
    { name: 'electronics_hx', efficiency: 0.88, heatTransferW: 0, coolantLoop: 0 }
  ];

  // Reserve/emergency dump
  emergencyDumpAvailable: boolean = true;
  dumpCoolantMass: number = 0; // kg dumped this mission

  update(dt: number, thermal: ThermalSystem, electrical: ElectricalSystem) {
    for (let i = 0; i < this.loops.length; i++) {
      const loop = this.loops[i];

      // Pump operation
      if (loop.active && loop.pump.powered) {
        const pumpBreaker = electrical.breakers.get(`coolant_pump_${i === 0 ? 'primary' : 'backup'}`);

        if (pumpBreaker && pumpBreaker.on) {
          // Pump running
          loop.flowRate = (loop.pump.rpm / loop.pump.maxRPM) * 20; // max 20 L/min

          // Pump pressure
          loop.pressureBar = (loop.pump.rpm / loop.pump.maxRPM) * 2.0;

          // Pump heat (inefficiency)
          const pumpHeatW = loop.pump.powerDraw * (1 - loop.pump.efficiency);
          thermal.addHeat('engineering', pumpHeatW * dt);
        } else {
          loop.flowRate = 0;
          loop.pressureBar = 0;
        }
      }

      // Heat pickup from routed components
      let heatPickupW = 0;

      if (loop.routing.reactor && reactor.status === 'online') {
        const reactorHeatW = reactor.currentOutputKW * 1000 / reactor.thermalEfficiency - reactor.currentOutputKW * 1000;
        const hxEfficiency = this.heatExchangers.find(hx => hx.name === 'reactor_hx').efficiency;
        heatPickupW += reactorHeatW * hxEfficiency;
      }

      if (loop.routing.mainEngine && mainEngine.ignited) {
        const engineHeatW = thermal.compartments.find(c => c.name === 'engine_bay').heatGenerationRate;
        const hxEfficiency = this.heatExchangers.find(hx => hx.name === 'engine_hx').efficiency;
        heatPickupW += engineHeatW * hxEfficiency;
      }

      if (loop.routing.electronics) {
        const electronicsHeatW = electrical.battery.temperature > 293 ?
          (electrical.battery.temperature - 293) * 50 : 0;
        const hxEfficiency = this.heatExchangers.find(hx => hx.name === 'electronics_hx').efficiency;
        heatPickupW += electronicsHeatW * hxEfficiency;
      }

      // Temperature rise from heat pickup
      if (loop.flowRate > 0) {
        const coolantMassFlowKgPerSec = (loop.flowRate / 60) * this.density;
        const tempRise = heatPickupW / (coolantMassFlowKgPerSec * this.specificHeat);
        loop.outletTemp = loop.inletTemp + tempRise;
      }

      // Heat rejection via radiators
      let heatRejectedW = 0;

      for (const radiator of this.radiators) {
        if (radiator.connectedLoop === i && radiator.deployed) {
          // Stefan-Boltzmann radiation
          const STEFAN_BOLTZMANN = 5.67e-8;
          const SPACE_TEMP = 2.7; // K

          radiator.temperature = loop.outletTemp;

          const radiatedPower = radiator.emissivity *
                               STEFAN_BOLTZMANN *
                               radiator.area *
                               (Math.pow(radiator.temperature, 4) - Math.pow(SPACE_TEMP, 4));

          heatRejectedW += radiatedPower;
          radiator.heatRejection = radiatedPower;
        }
      }

      // Net heat balance
      const netHeatW = heatPickupW - heatRejectedW;

      // Coolant temperature update
      if (this.totalCoolant > 0) {
        const coolantMassKg = this.totalCoolant * this.density;
        const tempChange = (netHeatW * dt) / (coolantMassKg * this.specificHeat);
        this.coolantTemp += tempChange;
      }

      // Update inlet temp for next cycle
      loop.inletTemp = this.coolantTemp - (heatRejectedW > 0 ? heatRejectedW / (loop.flowRate * this.density * this.specificHeat) : 0);

      // Leaks
      if (loop.leakRate > 0) {
        const leaked = loop.leakRate * (dt / 60);
        this.totalCoolant -= leaked;

        if (this.totalCoolant <= 0) {
          this.totalCoolant = 0;
          eventBus.emit('coolant_depleted');
        }
      }

      // Overheat warning
      if (this.coolantTemp > 370) {
        eventBus.emit('coolant_overheat');
      }

      // Boiling
      if (this.coolantTemp > 390 && loop.pressureBar < 2.0) {
        eventBus.emit('coolant_boiling');
        // Coolant loss from vaporization
        this.totalCoolant -= 0.1 * dt;
      }
    }
  }

  reroute(loopIndex: number, component: string, enabled: boolean) {
    this.loops[loopIndex].routing[component] = enabled;
  }

  deployRadiator(radiatorId: string): boolean {
    const radiator = this.radiators.find(r => r.id === radiatorId);
    if (radiator && ship.velocity < 5) { // can't deploy if moving fast
      radiator.deployed = true;
      return true;
    }
    return false;
  }

  retractRadiator(radiatorId: string) {
    const radiator = this.radiators.find(r => r.id === radiatorId);
    if (radiator) {
      radiator.deployed = false;
    }
  }

  emergencyCoolantDump(): boolean {
    if (this.emergencyDumpAvailable && this.totalCoolant > 10) {
      // Dump 50% of coolant to space (creates thrust)
      const dumpedLiters = this.totalCoolant * 0.5;
      const dumpedMassKg = dumpedLiters * this.density;

      this.totalCoolant *= 0.5;
      this.dumpCoolantMass += dumpedMassKg;

      // Instant temperature drop
      this.coolantTemp = 293;

      // Thrust from venting (hot coolant)
      const ventVelocity = 50; // m/s
      const thrust = dumpedMassKg * ventVelocity;

      ship.applyForce({ x: 0, y: -thrust }); // vented downward

      this.emergencyDumpAvailable = false; // one-time use
      eventBus.emit('emergency_coolant_dump');

      return true;
    }
    return false;
  }
}
```

---

## 5. Life Support System (Detailed)

### Water System

```typescript
class WaterSystem {
  // Water is consumed by O2 generator, crew, and used for cooling
  potableWater: number = 50; // liters
  wasteWater: number = 0;
  maxWaterStorage: number = 80;

  waterRecycler: {
    active: boolean;
    powerDraw: number; // W
    recycleRate: number; // L/hr
    efficiency: number; // 0-1 (waste → potable recovery rate)
    filterLife: number; // hours remaining
  } = {
    active: false,
    powerDraw: 250,
    recycleRate: 2.0, // L/hr
    efficiency: 0.85,
    filterLife: 100
  };

  update(dt: number, electrical: ElectricalSystem) {
    // Water recycling
    if (this.waterRecycler.active && electrical.breakers.get('water_recycler')?.on) {
      const recycledL = (this.waterRecycler.recycleRate / 3600) * dt;
      const recoveredL = recycledL * this.waterRecycler.efficiency;

      if (this.wasteWater >= recycledL) {
        this.wasteWater -= recycledL;
        this.potableWater += recoveredL;

        // Lost water (inefficiency)
        const lostL = recycledL * (1 - this.waterRecycler.efficiency);

        // Filter degradation
        this.waterRecycler.filterLife -= dt / 3600;

        if (this.waterRecycler.filterLife <= 0) {
          this.waterRecycler.active = false;
          eventBus.emit('water_filter_exhausted');
        }
      }
    }

    // Enforce storage limits
    this.potableWater = Math.min(this.potableWater, this.maxWaterStorage);
  }

  consumeWater(liters: number): boolean {
    if (this.potableWater >= liters) {
      this.potableWater -= liters;
      return true;
    }
    return false;
  }

  produceWaste(liters: number) {
    this.wasteWater += liters;
  }
}
```

### O2 Generation (Electrolysis)

```typescript
class O2Generator {
  active: boolean = false;
  powerDraw: number = 800; // W

  // Electrolysis: 2H2O → 2H2 + O2
  // 1L water → ~0.89 kg O2 + ~0.11 kg H2
  waterConsumptionRate: number = 0.5; // L/hr
  o2ProductionRate: number = 0.445; // kg/hr
  h2ProductionRate: number = 0.055; // kg/hr (vented or stored)

  efficiency: number = 0.75;
  temperature: number = 293;
  electrodeHealth: number = 100; // degrades over time

  cartridgeMode: {
    available: boolean;
    cartridgesRemaining: number;
    o2PerCartridge: number; // kg
  } = {
    available: true,
    cartridgesRemaining: 3,
    o2PerCartridge: 5.0
  };

  update(dt: number, waterSystem: WaterSystem, atmosphereSystem: AtmosphereSystem, electrical: ElectricalSystem) {
    if (this.active && electrical.breakers.get('o2_generator')?.on) {
      const waterNeeded = (this.waterConsumptionRate / 3600) * dt;

      if (waterSystem.consumeWater(waterNeeded)) {
        // Produce O2
        const o2Produced = (this.o2ProductionRate / 3600) * this.efficiency * dt;

        // Add to atmosphere (distribute across compartments)
        atmosphereSystem.addO2Global(o2Produced);

        // H2 byproduct (vented to space)
        const h2Produced = (this.h2ProductionRate / 3600) * dt;
        // (could store H2 for fuel cells in future)

        // Heat generation
        const heatW = this.powerDraw * (1 - this.efficiency);
        thermal.addHeat('life_support_bay', heatW * dt);

        // Electrode degradation
        this.electrodeHealth -= 0.001 * dt;

        if (this.electrodeHealth <= 0) {
          this.active = false;
          eventBus.emit('o2_generator_failed');
        }
      } else {
        // No water - generator shuts down
        this.active = false;
        eventBus.emit('o2_generator_no_water');
      }
    }
  }

  useCartridge(atmosphereSystem: AtmosphereSystem): boolean {
    if (this.cartridgeMode.cartridgesRemaining > 0) {
      this.cartridgeMode.cartridgesRemaining--;
      atmosphereSystem.addO2Global(this.cartridgeMode.o2PerCartridge);
      eventBus.emit('o2_cartridge_used', this.cartridgeMode.cartridgesRemaining);
      return true;
    }
    return false;
  }
}
```

### CO2 Scrubber

```typescript
class CO2Scrubber {
  active: boolean = true;
  powerDraw: number = 600; // W

  scrubberMedia: {
    type: 'LiOH' | 'amine'; // lithium hydroxide or amine bed
    remaining: number; // kg
    capacity: number;
    co2AbsorptionRate: number; // kg CO2 per kg media
  } = {
    type: 'LiOH',
    remaining: 20,
    capacity: 25,
    co2AbsorptionRate: 0.78 // 1kg LiOH absorbs 0.78kg CO2
  };

  scrubRate: number = 1.5; // kg CO2/hr at 100% efficiency
  efficiency: number = 0.95;
  temperature: number = 293;

  update(dt: number, atmosphereSystem: AtmosphereSystem, electrical: ElectricalSystem) {
    if (this.active && electrical.breakers.get('co2_scrubber')?.on) {
      // Calculate CO2 to remove
      const co2ToRemove = (this.scrubRate / 3600) * this.efficiency * dt;

      // Check media available
      const mediaNeeded = co2ToRemove / this.scrubberMedia.co2AbsorptionRate;

      if (this.scrubberMedia.remaining >= mediaNeeded) {
        // Remove CO2 from atmosphere
        atmosphereSystem.removeCO2Global(co2ToRemove);

        // Consume media
        this.scrubberMedia.remaining -= mediaNeeded;

        // Heat generation (exothermic reaction)
        const heatW = 500; // scrubbing generates heat
        thermal.addHeat('life_support_bay', heatW * dt);

        if (this.scrubberMedia.remaining < 1.0) {
          eventBus.emit('co2_scrubber_media_low');
        }

        if (this.scrubberMedia.remaining <= 0) {
          this.scrubberMedia.remaining = 0;
          this.active = false;
          eventBus.emit('co2_scrubber_exhausted');
        }
      }
    }
  }

  replaceScrubberMedia(newMediaKg: number): boolean {
    // Requires being docked or having spare canisters
    if (spareParts.scrubberMedia > 0) {
      this.scrubberMedia.remaining = newMediaKg;
      spareParts.scrubberMedia--;
      return true;
    }
    return false;
  }
}
```

---

## 6. Atmosphere System (Per-Compartment Detail)

```typescript
interface Compartment {
  id: number;
  name: string;
  volume: number; // m³
  
  // Gas masses
  O2: number; // kg
  CO2: number; // kg
  N2: number; // kg
  H2O_vapor: number; // kg
  contaminants: number; // ppm (smoke, etc.)

  temperature: number; // K
  
  // Connections
  neighbors: number[]; // adjacent compartment IDs
  doors: { toCompartment: number; open: boolean; crossSection: number }[]; // m² opening

  // Ventilation
  externalVent: {
    open: boolean;
    crossSection: number; // m² (vent size)
  };

  // Crew (future)
  crewPresent: number;
  o2ConsumptionRate: number; // kg/hr per crew
  co2ProductionRate: number; // kg/hr per crew

  // Fire
  onFire: boolean;
  fireIntensity: number; // 0-1

  // Heating
  heaterActive: boolean;
  heaterPowerW: number;
}

class AtmosphereSystem {
  compartments: Compartment[] = [
    {
      id: 0,
      name: 'Bow',
      volume: 40,
      O2: 8.4, // ~21% by partial pressure
      CO2: 0.016,
      N2: 31.2,
      H2O_vapor: 0.4,
      contaminants: 0,
      temperature: 293,
      neighbors: [1, 3],
      doors: [
        { toCompartment: 1, open: true, crossSection: 2.0 },
        { toCompartment: 3, open: true, crossSection: 1.5 }
      ],
      externalVent: { open: false, crossSection: 0.1 },
      crewPresent: 0,
      o2ConsumptionRate: 0.84, // per crew
      co2ProductionRate: 1.0,
      onFire: false,
      fireIntensity: 0,
      heaterActive: true,
      heaterPowerW: 300
    },
    // ... more compartments (6 total)
  ];

  update(dt: number, electrical: ElectricalSystem) {
    // 1. Gas mixing between connected compartments
    this.mixGases(dt);

    // 2. External venting (if vents open)
    this.ventToSpace(dt);

    // 3. Crew consumption (if crew present)
    this.crewMetabolism(dt);

    // 4. Fire effects
    this.updateFires(dt);

    // 5. Temperature exchange
    this.thermalExchange(dt);

    // 6. Heating elements
    this.updateHeaters(dt, electrical);

    // 7. Check for dangerous conditions
    this.checkHazards();
  }

  mixGases(dt: number) {
    // Gas flows between compartments with open doors
    for (const comp of this.compartments) {
      for (const door of comp.doors) {
        if (!door.open) continue;

        const neighbor = this.compartments[door.toCompartment];

        // Calculate pressure differential
        const p1 = this.calculatePressure(comp);
        const p2 = this.calculatePressure(neighbor);

        const pressureDiff = p1 - p2; // Pa

        if (Math.abs(pressureDiff) < 10) continue; // negligible

        // Flow rate through opening (Bernoulli/Torricelli)
        const density = 1.2; // kg/m³ (approximate air density)
        const flowVelocity = Math.sqrt(2 * Math.abs(pressureDiff) / density);
        const massFlowRate = density * door.crossSection * flowVelocity; // kg/s

        const massTransfer = massFlowRate * dt;

        // Direction of flow
        const fromComp = pressureDiff > 0 ? comp : neighbor;
        const toComp = pressureDiff > 0 ? neighbor : comp;

        // Transfer gases proportionally
        const totalMass = fromComp.O2 + fromComp.CO2 + fromComp.N2 + fromComp.H2O_vapor;
        if (totalMass > 0) {
          const o2Fraction = fromComp.O2 / totalMass;
          const co2Fraction = fromComp.CO2 / totalMass;
          const n2Fraction = fromComp.N2 / totalMass;
          const h2oFraction = fromComp.H2O_vapor / totalMass;

          const transferAmount = Math.min(massTransfer, totalMass * 0.1); // limit to 10% per step

          fromComp.O2 -= transferAmount * o2Fraction;
          fromComp.CO2 -= transferAmount * co2Fraction;
          fromComp.N2 -= transferAmount * n2Fraction;
          fromComp.H2O_vapor -= transferAmount * h2oFraction;

          toComp.O2 += transferAmount * o2Fraction;
          toComp.CO2 += transferAmount * co2Fraction;
          toComp.N2 += transferAmount * n2Fraction;
          toComp.H2O_vapor += transferAmount * h2oFraction;
        }
      }
    }
  }

  ventToSpace(dt: number) {
    for (const comp of this.compartments) {
      if (comp.externalVent.open) {
        // Venting to vacuum
        const pressure = this.calculatePressure(comp);

        // Choked flow (sonic velocity at vent)
        const ventVelocity = 300; // m/s (approximate)
        const density = 1.2;
        const massFlowRate = density * comp.externalVent.crossSection * ventVelocity;

        const massVented = massFlowRate * dt;
        const totalMass = comp.O2 + comp.CO2 + comp.N2 + comp.H2O_vapor;

        if (totalMass > 0) {
          const fraction = Math.min(massVented / totalMass, 0.5); // limit

          comp.O2 *= (1 - fraction);
          comp.CO2 *= (1 - fraction);
          comp.N2 *= (1 - fraction);
          comp.H2O_vapor *= (1 - fraction);

          // Apply thrust to ship
          const thrust = massVented * ventVelocity / dt;
          const ventPosition = this.getCompartmentPosition(comp.id);

          ship.applyForce({ x: thrust, y: 0 }, ventPosition);
        }

        if (totalMass < 0.1) {
          // Compartment effectively vacuum
          eventBus.emit('compartment_depressurized', comp.id);
        }
      }
    }
  }

  calculatePressure(comp: Compartment): number {
    // Ideal gas law: P = (n * R * T) / V
    const R = 8.314; // J/(mol·K)

    const o2Moles = comp.O2 / 32;
    const co2Moles = comp.CO2 / 44;
    const n2Moles = comp.N2 / 28;
    const h2oMoles = comp.H2O_vapor / 18;

    const totalMoles = o2Moles + co2Moles + n2Moles + h2oMoles;

    const pressurePa = (totalMoles * R * comp.temperature) / comp.volume;

    return pressurePa;
  }

  getO2Percentage(comp: Compartment): number {
    const pressure = this.calculatePressure(comp);
    const o2PartialPressure = (comp.O2 / 32) * 8.314 * comp.temperature / comp.volume;

    return (o2PartialPressure / pressure) * 100;
  }

  getCO2Percentage(comp: Compartment): number {
    const pressure = this.calculatePressure(comp);
    const co2PartialPressure = (comp.CO2 / 44) * 8.314 * comp.temperature / comp.volume;

    return (co2PartialPressure / pressure) * 100;
  }

  addO2Global(kg: number) {
    // Distribute O2 across all compartments by volume
    const totalVolume = this.compartments.reduce((sum, c) => sum + c.volume, 0);

    for (const comp of this.compartments) {
      const fraction = comp.volume / totalVolume;
      comp.O2 += kg * fraction;
    }
  }

  removeCO2Global(kg: number) {
    // Remove CO2 proportionally from all compartments
    const totalCO2 = this.compartments.reduce((sum, c) => sum + c.CO2, 0);

    for (const comp of this.compartments) {
      const fraction = comp.CO2 / totalCO2;
      comp.CO2 -= kg * fraction;
      comp.CO2 = Math.max(0, comp.CO2);
    }
  }

  checkHazards() {
    for (const comp of this.compartments) {
      const o2Percent = this.getO2Percentage(comp);
      const co2Percent = this.getCO2Percentage(comp);
      const pressure = this.calculatePressure(comp);

      // Low O2
      if (o2Percent < 19) {
        eventBus.emit('low_o2_warning', comp.id);
      }

      // High CO2
      if (co2Percent > 3) {
        eventBus.emit('high_co2_warning', comp.id);
      }

      // Low pressure
      if (pressure < 50000) { // 0.5 atm
        eventBus.emit('low_pressure_warning', comp.id);
      }

      // High pressure
      if (pressure > 150000) { // 1.5 atm
        eventBus.emit('high_pressure_warning', comp.id);
      }
    }
  }
}
```

I'll continue this in another append with fire physics, thermal details, and all the emergent cascades...


---

## 7. Detailed Thermal System (Per-Component Heat Tracking)

```typescript
class DetailedThermalSystem {
  // Track heat generation/dissipation per component
  heatSources: Map<string, HeatSource> = new Map([
    ['reactor', { heatGenerationW: 0, temperature: 400, mass: 200, specificHeat: 450 }],
    ['main_engine', { heatGenerationW: 0, temperature: 293, mass: 150, specificHeat: 500 }],
    ['battery', { heatGenerationW: 0, temperature: 293, mass: 80, specificHeat: 800 }],
    ['hydraulic_pump_1', { heatGenerationW: 0, temperature: 293, mass: 15, specificHeat: 1000 }],
    ['hydraulic_pump_2', { heatGenerationW: 0, temperature: 293, mass: 15, specificHeat: 1000 }],
    ['coolant_pump_1', { heatGenerationW: 0, temperature: 293, mass: 10, specificHeat: 1000 }],
    ['coolant_pump_2', { heatGenerationW: 0, temperature: 293, mass: 10, specificHeat: 1000 }],
    ['nav_computer', { heatGenerationW: 0, temperature: 293, mass: 5, specificHeat: 700 }],
    ['radar', { heatGenerationW: 0, temperature: 293, mass: 8, specificHeat: 700 }],
  ]);

  // Heat transfer between components and compartments
  thermalConductivity: Map<string, number> = new Map([
    ['reactor_to_engineering', 0.5], // W/K
    ['engine_to_engine_bay', 0.8],
    ['battery_to_electronics_bay', 0.3],
  ]);

  update(dt: number) {
    // Update component temperatures based on heat generation
    for (const [name, source] of this.heatSources) {
      if (source.heatGenerationW > 0) {
        const tempRise = (source.heatGenerationW * dt) / (source.mass * source.specificHeat);
        source.temperature += tempRise;
      }

      // Passive cooling (radiation/convection to compartment air)
      const compartment = this.getCompartmentForComponent(name);
      if (compartment) {
        const tempDiff = source.temperature - compartment.temperature;
        const heatTransferW = tempDiff * this.getThermalLink(name);

        source.temperature -= (heatTransferW * dt) / (source.mass * source.specificHeat);
        compartment.temperature += (heatTransferW * dt) / this.getCompartmentHeatCapacity(compartment);
      }
    }

    // Conduct heat between compartments
    for (const comp of atmosphereSystem.compartments) {
      for (const neighborId of comp.neighbors) {
        const neighbor = atmosphereSystem.compartments[neighborId];

        const tempDiff = comp.temperature - neighbor.temperature;
        const heatFlow = tempDiff * 50 * dt; // W (simplified conduction through bulkheads)

        const comp1Mass = this.getCompartmentMass(comp);
        const comp2Mass = this.getCompartmentMass(neighbor);

        comp.temperature -= heatFlow / (comp1Mass * 1000); // specific heat of air ~1000 J/(kg·K)
        neighbor.temperature += heatFlow / (comp2Mass * 1000);
      }
    }
  }

  addHeat(componentName: string, joules: number) {
    const source = this.heatSources.get(componentName);
    if (source) {
      const tempRise = joules / (source.mass * source.specificHeat);
      source.temperature += tempRise;
    }
  }

  getCompartmentForComponent(componentName: string): Compartment | null {
    const mapping = {
      'reactor': 'Engineering',
      'main_engine': 'Engine Bay',
      'battery': 'Electronics Bay',
      // ... more mappings
    };

    const compName = mapping[componentName];
    return atmosphereSystem.compartments.find(c => c.name === compName) || null;
  }

  getThermalLink(componentName: string): number {
    // Thermal conductance from component to air (W/K)
    return this.thermalConductivity.get(`${componentName}_to_${this.getCompartmentForComponent(componentName)?.name}`) || 0.2;
  }

  getCompartmentMass(comp: Compartment): number {
    // Total gas mass in compartment
    return comp.O2 + comp.CO2 + comp.N2 + comp.H2O_vapor;
  }

  getCompartmentHeatCapacity(comp: Compartment): number {
    const mass = this.getCompartmentMass(comp);
    const specificHeat = 1000; // J/(kg·K) for air
    return mass * specificHeat;
  }
}
```

---

## 8. Compressed Gas Storage

```typescript
class CompressedGasSystem {
  // High-pressure gas bottles for various uses
  bottles: GasBottle[] = [
    {
      gas: 'N2',
      pressureBar: 200, // 200 bar compressed nitrogen
      volumeL: 50,
      massKg: 12.5,
      maxPressureBar: 250,
      temperature: 293,

      uses: ['fuel_pressurization', 'pneumatic_actuators', 'emergency_atmosphere']
    },
    {
      gas: 'O2',
      pressureBar: 150,
      volumeL: 40,
      massKg: 8.5,
      maxPressureBar: 200,
      temperature: 293,

      uses: ['emergency_breathing', 'fuel_oxidizer']
    },
    {
      gas: 'He',
      pressureBar: 180,
      volumeL: 30,
      massKg: 1.2,
      maxPressureBar: 220,
      temperature: 293,

      uses: ['leak_detection', 'purging']
    }
  ];

  regulators: Map<string, Regulator> = new Map([
    ['fuel_press', { inputBottle: 0, outputPressureBar: 2.5, flowRateL_min: 5 }],
    ['emergency_o2', { inputBottle: 1, outputPressureBar: 1.0, flowRateL_min: 50 }],
  ]);

  update(dt: number) {
    // Gas temperature affects pressure (Gay-Lussac's law)
    for (const bottle of this.bottles) {
      // P1/T1 = P2/T2
      // (simplified - assume constant volume, mass)

      // Bottles heat up/cool down based on compartment temperature
      const compartment = atmosphereSystem.compartments.find(c => c.name === 'Storage');
      if (compartment) {
        const tempDiff = compartment.temperature - bottle.temperature;
        bottle.temperature += tempDiff * 0.01 * dt; // slow thermal equilibrium
      }

      // Update pressure based on temperature
      bottle.pressureBar = (bottle.massKg / this.getMolarMass(bottle.gas)) * 8.314 * bottle.temperature / (bottle.volumeL / 1000);

      // Overpressure warning
      if (bottle.pressureBar > bottle.maxPressureBar * 0.95) {
        eventBus.emit('gas_bottle_overpressure', bottle.gas);
      }

      // Rupture
      if (bottle.pressureBar > bottle.maxPressureBar) {
        this.ruptureBottle(bottle);
      }
    }
  }

  ruptureBottle(bottle: GasBottle) {
    eventBus.emit('gas_bottle_ruptured', bottle.gas);

    // Explosive decompression
    const energyJ = bottle.pressureBar * 100000 * (bottle.volumeL / 1000); // stored energy
    const explosionForce = energyJ / 10; // Newtons (simplified)

    ship.applyForce({ x: Math.random() * explosionForce, y: Math.random() * explosionForce });

    // Add gas to compartment
    const compartment = atmosphereSystem.compartments.find(c => c.name === 'Storage');
    if (compartment) {
      if (bottle.gas === 'N2') compartment.N2 += bottle.massKg;
      if (bottle.gas === 'O2') compartment.O2 += bottle.massKg;
    }

    // Bottle now empty and useless
    bottle.pressureBar = 0;
    bottle.massKg = 0;
  }

  consumeGas(bottleIndex: number, massKg: number): boolean {
    const bottle = this.bottles[bottleIndex];
    if (bottle.massKg >= massKg) {
      bottle.massKg -= massKg;

      // Pressure drops as mass decreases
      bottle.pressureBar = (bottle.massKg / this.getMolarMass(bottle.gas)) * 8.314 * bottle.temperature / (bottle.volumeL / 1000);

      return true;
    }
    return false;
  }

  getMolarMass(gas: string): number {
    const molarMasses = {
      'N2': 28,
      'O2': 32,
      'He': 4
    };
    return molarMasses[gas] || 28;
  }
}
```

---

## 9. Fire Physics (Detailed Combustion)

```typescript
class FireSystem {
  fires: Fire[] = [];

  startFire(compartmentId: number, ignitionSource: string, intensity: number = 0.3) {
    const compartment = atmosphereSystem.compartments[compartmentId];

    // Check if fire can start
    const o2Percent = atmosphereSystem.getO2Percentage(compartment);

    if (o2Percent < 16) {
      // Not enough O2 to sustain combustion
      return;
    }

    this.fires.push({
      compartmentId,
      intensity, // 0-1
      fuel: 'electronics', // what's burning
      o2ConsumptionRate: 2.0, // kg/hr at intensity 1.0
      co2ProductionRate: 2.75, // kg/hr
      heatGenerationRate: 50000, // W at intensity 1.0
      smokeProduction: 0,
      ignitionSource
    });

    compartment.onFire = true;
    compartment.fireIntensity = intensity;

    eventBus.emit('fire_started', compartmentId);
  }

  update(dt: number) {
    for (let i = this.fires.length - 1; i >= 0; i--) {
      const fire = this.fires[i];
      const compartment = atmosphereSystem.compartments[fire.compartmentId];

      const o2Percent = atmosphereSystem.getO2Percentage(compartment);
      const pressure = atmosphereSystem.calculatePressure(compartment);

      // Fire needs O2 to burn
      if (o2Percent < 14 || pressure < 20000) {
        // Fire dies out (lack of O2 or pressure too low)
        fire.intensity *= 0.9;

        if (fire.intensity < 0.05) {
          this.extinguishFire(i);
          continue;
        }
      } else {
        // Fire can grow if conditions favorable
        if (o2Percent > 20 && compartment.temperature > 350) {
          fire.intensity = Math.min(1.0, fire.intensity + 0.1 * dt);
        }
      }

      // O2 consumption
      const o2Consumed = (fire.o2ConsumptionRate / 3600) * fire.intensity * dt;
      compartment.O2 -= o2Consumed;
      compartment.O2 = Math.max(0, compartment.O2);

      // CO2 production
      const co2Produced = (fire.co2ProductionRate / 3600) * fire.intensity * dt;
      compartment.CO2 += co2Produced;

      // Heat generation
      const heatW = fire.heatGenerationRate * fire.intensity;
      compartment.temperature += (heatW * dt) / detailedThermal.getCompartmentHeatCapacity(compartment);

      // Smoke/contaminants
      fire.smokeProduction += fire.intensity * dt;
      compartment.contaminants += fire.intensity * 10 * dt; // ppm

      // Fire can spread to adjacent compartments with open doors
      if (fire.intensity > 0.7) {
        this.trySpread(fire);
      }

      compartment.fireIntensity = fire.intensity;
    }
  }

  trySpread(fire: Fire) {
    const compartment = atmosphereSystem.compartments[fire.compartmentId];

    for (const door of compartment.doors) {
      if (!door.open) continue;

      const neighbor = atmosphereSystem.compartments[door.toCompartment];

      // Fire spreads if neighbor is hot and has O2
      if (neighbor.temperature > 340 && atmosphereSystem.getO2Percentage(neighbor) > 18) {
        const spreadChance = fire.intensity * 0.05; // 5% per second at max intensity

        if (Math.random() < spreadChance) {
          if (!neighbor.onFire) {
            this.startFire(door.toCompartment, 'spread_from_fire', fire.intensity * 0.5);
          }
        }
      }
    }
  }

  suppressFire(compartmentId: number, suppressant: 'halon' | 'water' | 'co2') {
    const fireIndex = this.fires.findIndex(f => f.compartmentId === compartmentId);

    if (fireIndex !== -1) {
      const fire = this.fires[fireIndex];

      switch (suppressant) {
        case 'halon':
          // Halon displaces O2
          const compartment = atmosphereSystem.compartments[compartmentId];
          compartment.O2 *= 0.5; // rapid O2 reduction
          fire.intensity *= 0.2; // rapid suppression
          break;

        case 'water':
          // Water cools
          compartment.temperature -= 50; // rapid cooling
          fire.intensity *= 0.5;
          break;

        case 'co2':
          // CO2 displaces O2
          compartment.CO2 += 5; // flood with CO2
          compartment.O2 *= 0.7;
          fire.intensity *= 0.4;
          break;
      }

      if (fire.intensity < 0.1) {
        this.extinguishFire(fireIndex);
      }
    }
  }

  extinguishFire(fireIndex: number) {
    const fire = this.fires[fireIndex];
    const compartment = atmosphereSystem.compartments[fire.compartmentId];

    compartment.onFire = false;
    compartment.fireIntensity = 0;

    this.fires.splice(fireIndex, 1);

    eventBus.emit('fire_extinguished', fire.compartmentId);
  }
}
```

---

## 10. Detailed RCS System

```typescript
class RCSSystem {
  thrusters: RCSThruster[] = [
    // Bow thrusters (4)
    { id: 0, name: 'Bow Port', position: { x: -2, y: 10 }, direction: { x: -1, y: 0 }, thrust: 500, fuelRate: 0.08, temperature: 293, active: false, health: 100 },
    { id: 1, name: 'Bow Starboard', position: { x: 2, y: 10 }, direction: { x: 1, y: 0 }, thrust: 500, fuelRate: 0.08, temperature: 293, active: false, health: 100 },
    { id: 2, name: 'Bow Dorsal', position: { x: 0, y: 12 }, direction: { x: 0, y: 1 }, thrust: 500, fuelRate: 0.08, temperature: 293, active: false, health: 100 },
    { id: 3, name: 'Bow Ventral', position: { x: 0, y: 8 }, direction: { x: 0, y: -1 }, thrust: 500, fuelRate: 0.08, temperature: 293, active: false, health: 100 },

    // Midship thrusters (4)
    { id: 4, name: 'Mid Port', position: { x: -2, y: 0 }, direction: { x: -1, y: 0 }, thrust: 500, fuelRate: 0.08, temperature: 293, active: false, health: 100 },
    { id: 5, name: 'Mid Starboard', position: { x: 2, y: 0 }, direction: { x: 1, y: 0 }, thrust: 500, fuelRate: 0.08, temperature: 293, active: false, health: 100 },
    { id: 6, name: 'Mid Dorsal', position: { x: 0, y: 2 }, direction: { x: 0, y: 1 }, thrust: 500, fuelRate: 0.08, temperature: 293, active: false, health: 100 },
    { id: 7, name: 'Mid Ventral', position: { x: 0, y: -2 }, direction: { x: 0, y: -1 }, thrust: 500, fuelRate: 0.08, temperature: 293, active: false, health: 100 },

    // Stern thrusters (4)
    { id: 8, name: 'Stern Port', position: { x: -2, y: -10 }, direction: { x: -1, y: 0 }, thrust: 500, fuelRate: 0.08, temperature: 293, active: false, health: 100 },
    { id: 9, name: 'Stern Starboard', position: { x: 2, y: -10 }, direction: { x: 1, y: 0 }, thrust: 500, fuelRate: 0.08, temperature: 293, active: false, health: 100 },
    { id: 10, name: 'Stern Dorsal', position: { x: 0, y: -8 }, direction: { x: 0, y: 1 }, thrust: 500, fuelRate: 0.08, temperature: 293, active: false, health: 100 },
    { id: 11, name: 'Stern Ventral', position: { x: 0, y: -12 }, direction: { x: 0, y: -1 }, thrust: 500, fuelRate: 0.08, temperature: 293, active: false, health: 100 },
  ];

  update(dt: number, fuelSystem: FuelSystem) {
    for (const thruster of this.thrusters) {
      if (thruster.active && thruster.health > 0) {
        // Check fuel availability
        const fuelPressure = fuelSystem.fuelLines.rcsManifold.pressure;

        if (fuelPressure < 1.5) {
          // Insufficient pressure
          eventBus.emit('rcs_low_pressure');
          continue;
        }

        // Consume fuel
        const fuelConsumed = thruster.fuelRate * dt;
        if (!fuelSystem.consumeFuel('rcs', fuelConsumed)) {
          eventBus.emit('rcs_out_of_fuel');
          continue;
        }

        // Apply thrust
        const actualThrust = thruster.thrust * (thruster.health / 100);

        const force = {
          x: thruster.direction.x * actualThrust,
          y: thruster.direction.y * actualThrust
        };

        ship.applyForce(force, thruster.position); // Creates both force and torque

        // Heat generation
        thruster.temperature += 15 * dt; // heats up when firing

        // Overheat damage
        if (thruster.temperature > 600) {
          thruster.health -= 5 * dt;
          eventBus.emit('rcs_overheat', thruster.id);
        }
      } else {
        // Cooling when not firing
        thruster.temperature -= (thruster.temperature - 293) * 0.1 * dt;
      }
    }
  }

  fireThruster(thrusterId: number, active: boolean) {
    const thruster = this.thrusters[thrusterId];
    if (thruster) {
      thruster.active = active;
    }
  }

  lockThruster(thrusterId: number, locked: boolean) {
    // Player can disable malfunctioning thrusters
    const thruster = this.thrusters[thrusterId];
    if (thruster) {
      thruster.health = locked ? 0 : 100; // simple lock mechanism
    }
  }
}
```

---

## 11. Emergent Gameplay - Detailed Cascade Examples

### Example 1: Total System Collapse

```
Initial State: Ship cruising, all systems nominal

Step 1: MICROMETEORITE HIT
→ Punctures coolant loop in Engineering compartment
→ Coolant begins leaking (2 L/min)

Step 2: COOLANT LEAK DETECTED (30 seconds later)
→ Coolant level dropping: 80L → 70L → 60L...
→ Player notices coolant temp rising
→ Player must decide: seal Engineering or reroute coolant

Step 3: PLAYER REROUTES to Backup Loop
→ Backup coolant pump activated
→ Requires 400W power (load increases)
→ Battery begins slow drain (reactor at 95% capacity)

Step 4: REACTOR OVERHEATS (coolant insufficient)
→ Primary loop pressure drops below threshold
→ Reactor temp: 800K → 850K → 900K
→ Automatic SCRAM at 900K

Step 5: REACTOR OFFLINE
→ Power output drops to 0
→ Battery now sole power source
→ Battery: 8.0 kWh, discharging at 3.2 kW
→ Time remaining: ~2.5 hours

Step 6: PLAYER SHEDS LOAD
→ Trips breakers: Lights, Radar, Comms, Heating
→ Keeps: Life Support, Minimal Propulsion, Nav Computer
→ New load: 1.8 kW
→ Time remaining: ~4.4 hours

Step 7: RACE AGAINST TIME
→ Player must navigate to station before battery dies
→ Main engine offline (no cooling for reactor restart)
→ RCS only (limited fuel)
→ Must calculate intercept precisely (one shot)

Step 8: SUCCESSFUL DOCKING or DEATH
→ Success: Dock with 15% battery remaining
→ Failure: Battery dies → blackout → life support offline → hypoxia → death
```

### Example 2: Fire Cascade with Creative Solution

```
Initial State: Normal operations

Step 1: ELECTRICAL SHORT in Electronics Bay
→ Sparks ignite plastic insulation
→ Fire starts (intensity 0.3)

Step 2: FIRE DETECTED
→ Smoke detectors trigger
→ Fire consuming O2: 21% → 19% → 17%
→ Producing CO2: 0.04% → 0.8% → 1.5%
→ Temperature rising: 293K → 310K → 330K

Step 3: PLAYER RESPONSE - Seal Compartment
→ Closes bulkhead doors to Electronics Bay
→ Fire isolated but still burning
→ O2 continues dropping in sealed compartment

Step 4: PROBLEM - Navigation Computer in that bay!
→ Losing nav computer means no autopilot
→ Precision docking becomes nearly impossible
→ Player must choose: Fight fire or sacrifice computer

Step 5: PLAYER USES FIRE SUPPRESSION
→ Activates Halon system
→ O2 rapidly displaced: 17% → 8% → 5%
→ Fire intensity: 0.7 → 0.3 → 0.05 → extinguished

Step 6: AFTERMATH
→ Fire out but compartment toxic (CO2 + smoke)
→ Nav computer damaged by heat (efficiency 60%)
→ Must vent compartment to clear atmosphere
→ Opens external vent

Step 7: VENTING CREATES THRUST
→ Atmosphere venting to space
→ Creates 200N thrust vector (unplanned)
→ Ship begins rotating
→ Player must use RCS to counter

Step 8: RESOLUTION
→ Compartment vented (now vacuum)
→ Fire fully extinguished
→ Nav computer partially functional
→ Must dock manually with degraded instruments
→ Succeeded through skill and improvisation
```

### Example 3: Fuel Imbalance Spiral

```
Initial State: High-speed intercept maneuver

Step 1: PROLONGED MAIN ENGINE BURN
→ Consuming fuel from Main Tank 1
→ Fuel: 80kg → 60kg → 40kg → 20kg

Step 2: TANK 1 NEARLY EMPTY
→ Center of mass shifts toward Tank 2
→ Ship has rotation bias (slow tumble begins)

Step 3: PLAYER SWITCHES FUEL FEED
→ Opens valve from Tank 2
→ Closes valve from Tank 1
→ Fuel flow interrupted briefly
→ Engine pressure drops below threshold

Step 4: ENGINE FLAMEOUT
→ Combustion chamber pressure lost
→ Must reignite
→ Requires pressurization cycle (15 seconds)

Step 5: DURING REIGNITION - Ship Tumbling
→ Rotation rate increasing (imbalanced tanks)
→ Must use RCS to stabilize
→ RCS fuel depleting rapidly

Step 6: ENGINE REIGNITED but Imbalanced
→ Thrust vector not through center of mass
→ Acceleration creates torque
→ Tumble worsens despite engine firing

Step 7: PLAYER SOLUTION - Fuel Transfer
→ Pauses engine burn
→ Activates fuel transfer pump (Tank 2 → Tank 1)
→ Transfer rate: 2 kg/min
→ Takes 3 minutes to rebalance
→ Uses precious time approaching target

Step 8: REBALANCED
→ Center of mass restored
→ Rotation controlled
→ Resume burn but now behind schedule
→ Must increase throttle (higher fuel consumption + heat)
→ Thermal management now critical

Step 9: INTERCEPT SUCCESSFUL but Hot
→ Arrived at target
→ Engines at 95% max temp
→ Coolant at 360K (near boiling)
→ Must shut down and coast final approach
→ Precision docking on RCS only
```

---

## 12. Performance Optimization

With this level of simulation detail, hitting 60 FPS requires optimization:

**Update Frequencies:**
```
Physics (ship motion): 60 Hz (every frame)
Electrical system: 30 Hz (every 2 frames)
Hydraulics: 20 Hz (every 3 frames)
Fuel system: 20 Hz
Coolant system: 10 Hz (every 6 frames)
Atmosphere mixing: 10 Hz
Thermal conduction: 10 Hz
Fire simulation: 10 Hz
Water/Life support: 5 Hz (every 12 frames)
Compressed gas: 5 Hz
```

**Profiling Budget (60 FPS = 16.67ms per frame):**
```
Ship physics:           1.0ms
Electrical:             0.5ms (30 Hz)
Hydraulics:             0.3ms (20 Hz)
Fuel system:            0.4ms (20 Hz)
Propulsion:             0.8ms
Coolant (when active):  0.6ms (10 Hz)
Atmosphere:             1.5ms (10 Hz)
Thermal:                0.8ms (10 Hz)
Fire:                   0.3ms (10 Hz)
Life support:           0.2ms (5 Hz)
Event system:           0.3ms
Rendering:              4.0ms
Input:                  0.2ms
UI updates:             1.5ms
---------------------------------
Total:                  ~12.4ms (3.3ms headroom)
```

**Optimization Techniques:**
- Object pooling for temporary objects
- Cached calculations (pressure, temperature deltas)
- Dirty flags (only recalculate when changed)
- Spatial hashing for collision detection
- Throttle non-critical updates
- SIMD operations where possible (JS typed arrays)

---

## 13. System Rerouting Examples

**Coolant Rerouting:**
```
Normal: Reactor → Primary Loop → Radiator 1
Damage: Primary Loop breached
Player: Reactor → Backup Loop → Radiator 2
Cost: Higher power draw (backup pump less efficient)
```

**Power Cross-Tie:**
```
Normal: Bus A (Reactor) → Life Support, Propulsion
        Bus B (Reactor) → Navigation, Sensors
Damage: Bus A fault
Player: Enable cross-tie → Bus B feeds all systems
Limit: Bus B capacity only 4.5kW (must shed load)
```

**Fuel Cross-Feed:**
```
Normal: Tank 1 → Main Engine
        Tank 2 → Reserve
        RCS Tank → RCS
Damage: Tank 1 leak
Player: Close Tank 1, Open Tank 2 → Main Engine
        Transfer remaining Tank 1 → Tank 2 (salvage fuel)
        Use compressed N2 to re-pressurize Tank 2
```

**Hydraulic Cross-Connect:**
```
Normal: Primary Loop → Main Gimbal, Doors 1-3
        Backup Loop → Backup Gimbal, Doors 4-6
Damage: Primary pump failed
Player: Open cross-connect
        Backup pump → All actuators
Limit: Lower pressure (slower actuation)
```

**Life Support Compartment Isolation:**
```
Normal: All 6 compartments connected, O2 distributed
Emergency: Fire in Compartment 3
Player: Seal doors to Comp 3
        Vent Comp 3 to space
        O2 generator → remaining 5 compartments only
Result: Reduced habitable volume, higher O2 consumption rate per cubic meter
```

---

## Conclusion

This detailed simulation creates a living, breathing spacecraft where:

- **Every watt is accounted for**
- **Every liter of fluid matters**
- **Every valve can be rerouted**
- **Every system depends on others**
- **Failures cascade realistically**
- **Creative solutions emerge from physics**

The player doesn't just click buttons - they **operate a spacecraft** with all the complexity, danger, and satisfaction that entails.

