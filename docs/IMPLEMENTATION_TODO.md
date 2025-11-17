# Vector Moon Lander - Implementation TODO

**Last Updated:** 2025-11-17
**Status:** Ready for Implementation
**Based on:** ARCHITECTURE_REVIEW.md

This document provides a detailed, task-by-task breakdown of what needs to be implemented to reach MVP status.

---

## Week 1-2: Multi-Station Interface & Detailed Controls

### Task 1.1: Create Station Framework

**File:** `game/station-base.ts`

```typescript
abstract class StationScreen {
  abstract stationId: number;
  abstract stationName: string;

  abstract render(state: SpacecraftState): string;
  abstract handleInput(key: string, spacecraft: Spacecraft): void;
  abstract getHelpText(): string;
}
```

**Checklist:**
- [ ] Create `StationScreen` abstract base class
- [ ] Implement `render()` method signature
- [ ] Implement `handleInput()` method signature
- [ ] Add help text generation
- [ ] Test with mock station

**Effort:** 1 day

---

### Task 1.2: Implement Station Switching System

**File:** `game/station-manager.ts`

**Checklist:**
- [ ] Create `StationManager` class
- [ ] Store array of 4 station screens
- [ ] Implement switch-to-station (keys 1-5)
- [ ] Implement TAB cycling (forward)
- [ ] Implement SHIFT+TAB cycling (backward)
- [ ] Track current active station
- [ ] Route input to active station
- [ ] Visual indicator of current station

**Effort:** 1 day

---

### Task 1.3: Implement Helm/Propulsion Station

**File:** `game/stations/helm-station.ts`

**Controls to Implement:**

**Main Engine (10 controls):**
- [ ] `F` - Toggle fuel valve (OPEN/CLOSED)
- [ ] `G` - Arm ignition
- [ ] `H` - Fire ignition (only if armed + valve open)
- [ ] `Q` - Increase throttle (+5%)
- [ ] `A` - Decrease throttle (-5%)
- [ ] `W` - Gimbal up (+1°)
- [ ] `S` - Gimbal down (-1°)
- [ ] `E` - Gimbal right (+1°)
- [ ] `D` - Gimbal left (-1°)
- [ ] `R` - Emergency cutoff

**RCS Thrusters (12 controls):**
- [ ] `1-9, 0, -, =` - Fire individual thrusters
- [ ] Display thruster positions (bow/mid/stern)
- [ ] Display thruster directions (P/S/D/V)
- [ ] Show thruster temperature per unit
- [ ] Overheat warnings

**Fuel Management (4 controls):**
- [ ] `T` - Transfer Tank 1 → Tank 2
- [ ] `Y` - Transfer Tank 2 → Tank 1
- [ ] `U` - Emergency fuel dump
- [ ] Display tank levels (3 tanks)
- [ ] Display fuel balance indicator
- [ ] Show pressure gauges

**Display Elements:**
- [ ] Engine temperature gauge with color coding
- [ ] Fuel pressure indicator
- [ ] Fuel flow percentage
- [ ] Tank levels with bars
- [ ] Gimbal position indicators (X/Y)
- [ ] Engine status (OFF/IGNITING/RUNNING)

**Effort:** 3 days

---

### Task 1.4: Implement Engineering/Power Station

**File:** `game/stations/engineering-station.ts`

**Controls to Implement:**

**Reactor (4 controls):**
- [ ] `R` - Start reactor (10s startup)
- [ ] `T` - SCRAM (emergency shutdown)
- [ ] `I` - Increase throttle (+5%)
- [ ] `K` - Decrease throttle (-5%)
- [ ] Display status (OFFLINE/STARTING/ONLINE/SCRAMMED)
- [ ] Show output in kW
- [ ] Temperature gauge with overtemp warning

**Power Distribution (10 breakers):**
- [ ] `1` - Life Support breaker
- [ ] `2` - Propulsion breaker
- [ ] `3` - Nav Computer breaker
- [ ] `4` - Sensors breaker
- [ ] `5` - Doors breaker
- [ ] `6` - Lights breaker
- [ ] `7` - Comms breaker
- [ ] `8` - Coolant Pump breaker
- [ ] `9` - Radiators breaker
- [ ] `0` - Backup Systems breaker
- [ ] Display bus A/B loads (kW)
- [ ] Show breaker states (ON/OFF/TRIPPED)
- [ ] Overcurrent warnings

**Battery (2 controls):**
- [ ] `B` - Toggle charge/discharge mode
- [ ] Display charge percentage
- [ ] Show load (+/- kW)
- [ ] Charge/discharge indicator

**Thermal Management (5 controls):**
- [ ] `C` - Toggle coolant pump ON/OFF
- [ ] `V` - Increase coolant flow (+10%)
- [ ] `F` - Decrease coolant flow (-10%)
- [ ] `G` - Deploy/retract radiators
- [ ] `H` - Emergency heat dump
- [ ] Display coolant flow rate
- [ ] Show radiator deployment status
- [ ] Heat exchanger status (4 exchangers)

**Damage Control (2 controls):**
- [ ] `M` - Cycle through damaged systems
- [ ] `N` - Initiate repair
- [ ] Display system health list
- [ ] Show spare parts count
- [ ] Display repair queue

**Effort:** 3 days

---

### Task 1.5: Implement Navigation/Sensors Station

**File:** `game/stations/navigation-station.ts`

**Controls to Implement:**

**Sensors (10 controls):**
- [ ] `R` - Toggle radar ON/OFF
- [ ] `Z` - Increase radar range
- [ ] `X` - Decrease radar range
- [ ] `C` - Increase radar gain
- [ ] `V` - Decrease radar gain
- [ ] `L` - Toggle LIDAR active/passive
- [ ] `T` - Toggle thermal sensor
- [ ] `B` - Increase thermal sensitivity
- [ ] `N` - Decrease thermal sensitivity
- [ ] `M` - Calibrate mass detector (5s)

**Contact Management (5 controls):**
- [ ] `1-9` - Select contact as target
- [ ] `TAB` - Cycle through contacts
- [ ] `SHIFT+TAB` - Cycle backwards
- [ ] Display contact list (range, bearing, velocity)
- [ ] Highlight selected target

**Navigation Computer (3 controls):**
- [ ] `P` - Plot intercept course
- [ ] `A` - Engage autopilot
- [ ] `S` - Disengage autopilot
- [ ] Display intercept solution
- [ ] Show delta-v required
- [ ] Time to intercept
- [ ] Fuel required

**Display Elements:**
- [ ] Tactical radar (top-down 2D)
- [ ] Velocity vectors (ship, target, relative)
- [ ] Contact list with data
- [ ] Trajectory prediction line
- [ ] Projected impact point

**Effort:** 2-3 days

---

### Task 1.6: Implement Life Support Station

**File:** `game/stations/lifesupport-station.ts`

**NOTE:** Requires implementing atmosphere system first (see Task 3.1)

**Controls to Implement:**

**Compartment Selection (2 controls):**
- [ ] `1-6` - Select compartment to view
- [ ] Display ship layout diagram
- [ ] Highlight selected compartment

**Per-Compartment Controls (8 controls):**
- [ ] `Q/W/E/R/T` - Toggle adjacent doors OPEN/SEALED
- [ ] `A` - Arm fire suppression
- [ ] `S` - Fire suppression (releases Halon)
- [ ] `Z` - Override safety interlock
- [ ] `X` - Vent to space
- [ ] `C` - Toggle auto/manual equalization
- [ ] `V` - Manual equalization valve

**Global Systems (4 controls):**
- [ ] `O` - Toggle O2 generator ON/OFF
- [ ] `Q` - Increase O2 generation rate
- [ ] `A` - Decrease O2 generation rate
- [ ] `S` - Toggle CO2 scrubber ON/OFF

**Display Elements:**
- [ ] Ship compartment layout (6 compartments)
- [ ] Per-compartment atmosphere:
  - [ ] O2 percentage (with color coding)
  - [ ] CO2 percentage
  - [ ] N2 percentage
  - [ ] Pressure (kPa)
  - [ ] Temperature (K)
- [ ] Door states (OPEN/SEALED)
- [ ] Fire status per compartment
- [ ] O2 reserves (kg)
- [ ] Scrubber media remaining

**Effort:** 2-3 days (after atmosphere system implemented)

---

## Week 3: Life Support System Implementation

### Task 3.1: Atmosphere Physics Module

**File:** `physics-modules/src/atmosphere-system.ts`

**Features to Implement:**

**Core Data Structures:**
```typescript
interface Compartment {
  id: string;
  volume: number;  // m³
  O2_mass: number;  // kg
  CO2_mass: number;  // kg
  N2_mass: number;  // kg
  temperature: number;  // K
  doorsOpen: boolean[];  // to neighbors
  onFire: boolean;
}
```

**Physics:**
- [ ] Implement ideal gas law (PV = nRT) for pressure calculation
- [ ] Gas mixing between compartments (flow through open doors)
- [ ] O2 generation (electrolyzer model)
- [ ] CO2 scrubbing (filter efficiency model)
- [ ] Temperature effects on pressure
- [ ] Crew consumption (O2 → CO2) - optional for MVP

**Methods:**
- [ ] `calculatePressure(comp: Compartment): number`
- [ ] `mixGases(comp1: Compartment, comp2: Compartment, dt: number): void`
- [ ] `generateO2(rate: number, dt: number): void`
- [ ] `scrubCO2(efficiency: number, dt: number): void`
- [ ] `ventToSpace(compId: string, dt: number): Vector3` (returns thrust)
- [ ] `update(dt: number): void`

**Tests to Write:**
- [ ] Pressure calculation (PV=nRT validation)
- [ ] Gas mixing dynamics
- [ ] O2 generation rate
- [ ] CO2 scrubbing efficiency
- [ ] Venting thrust calculation
- [ ] Integration test with thermal system

**Effort:** 3 days

---

### Task 3.2: Fire Simulation Module

**File:** `physics-modules/src/fire-system.ts`

**Features to Implement:**

**Fire Physics:**
- [ ] Fire requires: O2 (>15% partial pressure), heat source (>400K), fuel
- [ ] Fire consumes: O2 at high rate
- [ ] Fire produces: CO2, heat, smoke (visual only)
- [ ] Fire spreads: to adjacent compartments through open doors
- [ ] Fire suppression: Halon displaces O2, or vacuum venting

**Data Structures:**
```typescript
interface Fire {
  compartmentId: string;
  intensity: number;  // 0-1
  fuelRemaining: number;  // kg
}
```

**Methods:**
- [ ] `igniteFire(compId: string): boolean` (check conditions)
- [ ] `updateFire(fire: Fire, atmosphere: AtmosphereSystem, thermal: ThermalSystem, dt: number): void`
- [ ] `spreadFire(compId: string, atmosphere: AtmosphereSystem): void`
- [ ] `suppressFire(compId: string, method: 'halon' | 'vent'): void`
- [ ] `update(dt: number): void`

**Tests to Write:**
- [ ] Fire ignition conditions
- [ ] O2 consumption rate
- [ ] Heat generation
- [ ] Fire spreading logic
- [ ] Halon suppression
- [ ] Vacuum suppression (venting)

**Effort:** 2-3 days

---

### Task 3.3: Integrate Life Support with Spacecraft

**File:** `physics-modules/src/spacecraft.ts`

**Integration Points:**
- [ ] Add `atmosphere: AtmosphereSystem` to Spacecraft class
- [ ] Add `fire: FireSystem` to Spacecraft class
- [ ] Connect fires → thermal system (heat generation)
- [ ] Connect venting → ship physics (thrust from escaping gas)
- [ ] Update thermal system to ignite fires when compartment >400K
- [ ] Add hull breaches → atmosphere leaks
- [ ] Integration tests

**Effort:** 1-2 days

---

## Week 4: Campaign Structure & Events

### Task 4.1: Campaign Map System

**File:** `game/campaign-map.ts`

**Features:**
- [ ] Node-based graph structure (20-30 nodes)
- [ ] Node types: Navigation, Operational, Encounter, Safe Haven
- [ ] Branching paths (player choices)
- [ ] Sector progression (5 sectors)
- [ ] Node state tracking (visited, available, locked)

**Data Structures:**
```typescript
interface CampaignNode {
  id: string;
  type: 'navigation' | 'operational' | 'encounter' | 'safe_haven';
  position: { x: number, y: number };
  connections: string[];  // Node IDs
  visited: boolean;
  event?: Event;
}
```

**Methods:**
- [ ] `generateMap(): CampaignNode[]`
- [ ] `selectNode(nodeId: string): void`
- [ ] `completeNode(nodeId: string, outcome: any): void`
- [ ] `getAvailableNodes(): CampaignNode[]`
- [ ] `getCurrentNode(): CampaignNode | null`

**Effort:** 3 days

---

### Task 4.2: Event System

**File:** `game/event-system.ts`

**Event Types to Implement:**

**Navigation Events (8-10 events):**
- [ ] Standard landing (easy)
- [ ] Crater rim landing (medium)
- [ ] Boulder field landing (hard)
- [ ] Night landing (reduced visibility)
- [ ] Emergency landing (damaged systems)
- [ ] Moving target (docking with station)
- [ ] Asteroid field navigation
- [ ] Intercept mission

**Operational Events (8-10 events):**
- [ ] Reactor malfunction
- [ ] Fuel leak
- [ ] Fire outbreak
- [ ] Power loss
- [ ] Sensor failure
- [ ] Engine damage
- [ ] Hull breach
- [ ] Thermal overload

**Encounter Events (5-7 events):**
- [ ] Derelict ship (salvage opportunity)
- [ ] Distress call (rescue mission)
- [ ] Trading post (buy/sell resources)
- [ ] Hostile encounter (light combat)
- [ ] Scientific anomaly (investigation)

**Safe Haven Events (2-3 events):**
- [ ] Repair station (restore systems, buy parts)
- [ ] Refuel depot (buy fuel, O2)
- [ ] Rest stop (safe, no threats)

**Event Template:**
```typescript
interface Event {
  id: string;
  type: string;
  title: string;
  description: string;
  choices: EventChoice[];
  outcome: (choice: number, state: SpacecraftState) => EventOutcome;
}
```

**Effort:** 4-5 days

---

### Task 4.3: Resource Economy

**File:** `game/resource-economy.ts`

**Resources to Track:**
- [ ] Fuel (kg) - already tracked in fuel system
- [ ] O2 (kg) - tracked in atmosphere system
- [ ] Spare Parts (count) - for repairs
- [ ] Credits (currency) - for trading

**Features:**
- [ ] Track resources across campaign
- [ ] Resource costs for actions (repairs, trading)
- [ ] Random resource events (find supplies, lose resources)
- [ ] Scarcity creates tension

**Effort:** 1-2 days

---

## Week 5: Damage System & Visual Polish

### Task 5.1: Comprehensive Damage System

**File:** `physics-modules/src/damage-system.ts`

**Features:**

**Component Health:**
- [ ] Per-component health (0-100%)
- [ ] Health affects efficiency:
  - 100-50%: Linear efficiency reduction
  - 50-25%: Degraded performance (50% efficiency)
  - 25-0%: Unreliable (random failures, 25% efficiency)
  - 0%: Complete failure

**Damage Sources:**
- [ ] Overheating (thermal damage over time)
- [ ] Overpressure (explosive damage)
- [ ] Fires (burn damage)
- [ ] Impacts (collision damage)
- [ ] Random failures (based on health)

**Repair System:**
- [ ] Repair queue (FIFO)
- [ ] Repair time per component
- [ ] Spare parts consumption
- [ ] Jury-rig option (no parts, temporary, unreliable)

**Methods:**
- [ ] `applyDamage(component: string, amount: number): void`
- [ ] `startRepair(component: string, useSpare: boolean): void`
- [ ] `updateRepairs(dt: number): void`
- [ ] `getComponentEfficiency(component: string): number`

**Effort:** 3-4 days

---

### Task 5.2: Visual Design Improvements

**Files:**
- `game/ui/box-drawing.ts` - Box-drawing characters
- `game/ui/gauges.ts` - ASCII art gauges/sliders
- `game/ui/colors.ts` - Color palette system
- `game/ui/vector-graphics.ts` - Simple vector rendering

**Features:**

**Box Drawing:**
- [ ] Use Unicode box-drawing characters
- [ ] Nested boxes for panels
- [ ] Connectors and dividers

**Gauges & Indicators:**
- [ ] Horizontal bar gauges: `[████░░░░] 50%`
- [ ] Vertical bar gauges (for columns)
- [ ] Numeric readouts with units
- [ ] Color coding (green/yellow/red)
- [ ] Flashing warnings

**Color Palettes:**
- [ ] Green CRT mode (default)
- [ ] Amber mode
- [ ] Cyan mode
- [ ] White mode
- [ ] Player selectable

**Vector Graphics (Simple):**
- [ ] Ship icon (ASCII art)
- [ ] Trajectory line
- [ ] Target indicators
- [ ] Velocity vectors (arrows)

**Effort:** 3-4 days

---

### Task 5.3: Playtesting & Balance

**Testing Scenarios:**
- [ ] Easy landing (Mare Tranquillitatis)
- [ ] Medium landing with one system failure
- [ ] Hard landing with fire
- [ ] Complete campaign run (20+ nodes)
- [ ] Resource scarcity test (low fuel)
- [ ] Damage accumulation test

**Balance Adjustments:**
- [ ] Fuel consumption rates
- [ ] Damage rates
- [ ] Repair times
- [ ] Fire spreading rates
- [ ] Resource availability
- [ ] Event difficulty curve

**Effort:** 3-5 days (ongoing)

---

## Post-MVP: Optional Enhancements

### Task 6.1: Tutorial System
- [ ] Interactive tutorial for each station
- [ ] Guided first landing
- [ ] System explanations
- [ ] Control reference

**Effort:** 3-4 days

---

### Task 6.2: Sound Design
- [ ] Engine sounds (ignition, running, shutdown)
- [ ] RCS firing bleeps
- [ ] Warning klaxons
- [ ] Button press sounds
- [ ] Ambient hum

**Effort:** 2-3 days

---

### Task 6.3: Additional Content
- [ ] 10-15 more campaign events
- [ ] 5+ more landing zones
- [ ] Difficulty modes (easy/normal/hard)
- [ ] Achievements system
- [ ] Leaderboards (time, fuel efficiency)

**Effort:** 5-7 days

---

## Summary Timeline

| Week | Focus | Deliverable |
|------|-------|-------------|
| 1-2 | Multi-Station Interface | 4 stations with detailed controls |
| 3 | Life Support System | Atmosphere & fire simulation |
| 4 | Campaign Structure | Events, map, resource economy |
| 5 | Damage & Polish | Comprehensive damage, visual improvements |
| 6+ | Post-MVP | Tutorial, sound, additional content |

**Total Estimated Time to MVP:** 5-6 weeks
**Total Estimated Time to Polished Release:** 8-10 weeks

---

## Daily Progress Tracking

Use this checklist to track daily progress:

### Week 1
- [ ] Day 1: Station framework + switching system
- [ ] Day 2: Helm station (main engine controls)
- [ ] Day 3: Helm station (RCS + fuel management)
- [ ] Day 4: Engineering station (reactor + power)
- [ ] Day 5: Engineering station (thermal + damage)

### Week 2
- [ ] Day 6: Navigation station (sensors)
- [ ] Day 7: Navigation station (contacts + nav computer)
- [ ] Day 8: Integration testing all stations
- [ ] Day 9: UI polish and bug fixes
- [ ] Day 10: Playtest multi-station interface

### Week 3
- [ ] Day 11: Atmosphere physics module
- [ ] Day 12: Atmosphere testing and integration
- [ ] Day 13: Fire simulation module
- [ ] Day 14: Fire testing and integration
- [ ] Day 15: Life Support station UI

### Week 4
- [ ] Day 16: Campaign map structure
- [ ] Day 17: Event system framework
- [ ] Day 18: Create 10-15 events
- [ ] Day 19: Resource economy
- [ ] Day 20: Campaign integration and testing

### Week 5
- [ ] Day 21: Comprehensive damage system
- [ ] Day 22: Repair mechanics
- [ ] Day 23: Visual design improvements
- [ ] Day 24: Color palettes and gauges
- [ ] Day 25-30: Playtesting and balance

---

## Success Criteria Checklist

**MVP Complete When:**
- [ ] All 4 stations implemented and functional
- [ ] Station switching works smoothly
- [ ] All documented controls implemented (86 controls)
- [ ] Life support system working (atmosphere, fire)
- [ ] Campaign map with 20+ nodes
- [ ] 20+ events across all types
- [ ] Resource economy functional
- [ ] Damage/repair system working
- [ ] Visual design matches aesthetic (retro-futuristic)
- [ ] Complete playthrough takes 2-5 hours
- [ ] Game is stable (no crashes)
- [ ] Core gameplay loop is fun

**Ready for Release When:**
- [ ] MVP criteria met
- [ ] Tutorial system implemented
- [ ] Sound design added
- [ ] Additional content (30+ events)
- [ ] Extensive playtesting done
- [ ] Balance is good
- [ ] Performance is smooth (60 FPS)
- [ ] All known bugs fixed

---

**Last Updated:** 2025-11-17
**Next Review:** After Week 2 (multi-station implementation)
