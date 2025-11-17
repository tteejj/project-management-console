# Space Game Codebase Analysis Report

## Executive Summary

You have a sophisticated **spacecraft systems simulator** (Vector Moon Lander) currently in the "moon-lander-game" branch, with a focus on procedural complexity and emergent gameplay through interconnected ship systems. The codebase is written in **TypeScript** and uses **HTML5 Canvas** for rendering.

**Current State**: MVP-level implementation with comprehensive physics modules and a complete framework for spacecraft management. The universe-generator branch appears to be a work-in-progress merge with a project management console.

---

## 1. GAME STRUCTURE & ARCHITECTURE

### Design Philosophy
- **"Submarine Simulator in Space"** - Players *operate* systems, not direct-pilot
- **Event-driven exploration** with node-based campaign structure (inspired by FTL)
- **Permadeath roguelike** with meta-progression
- **Short sessions** (5-30 minutes per run, 2-5 hours total campaign)

### Core Architecture Pattern
**Entity-Component-System (Simplified)**
```
Spacecraft (Main Entity)
├── Core Physics Subsystems
├── Advanced Flight Systems
└── Simulation Time Management
```

### Technology Stack
- **Language**: TypeScript (type-safe, refactoring friendly)
- **Runtime**: Browser (HTML5)
- **Rendering**: HTML5 Canvas 2D
- **Build Tools**: Vite (dev server), TypeScript compiler, ESLint, Prettier
- **Game Engine**: Custom (full control, lightweight, no unnecessary overhead)

---

## 2. ENTITY/OBJECT SYSTEMS IN PLACE

### Main Entity: Spacecraft Class
```typescript
class Spacecraft {
  // Core physics subsystems
  public fuel: FuelSystem;
  public electrical: ElectricalSystem;
  public gas: CompressedGasSystem;
  public thermal: ThermalSystem;
  public coolant: CoolantSystem;
  public mainEngine: MainEngine;
  public rcs: RCSSystem;
  public physics: ShipPhysics;

  // Advanced flight systems
  public flightControl: FlightControlSystem;
  public navigation: NavigationSystem;
  public mission: MissionSystem;

  // Simulation time tracking
  public simulationTime: number;
}
```

### Core Physics Components

#### **Vector3 & Quaternion Types**
- 3D position, velocity tracking
- Quaternion-based rotation (prevents gimbal lock)
- Position in inertial frame (relative to planet center)

#### **Ship State**
```typescript
interface ShipState {
  position: Vector3;           // meters from planet center
  velocity: Vector3;           // m/s
  attitude: Quaternion;        // orientation (no gimbal lock)
  angularVelocity: Vector3;    // rad/s in body frame
  dryMass: number;             // kg (empty ship)
  propellantMass: number;      // kg (fuel + oxidizer)
}
```

### Fuel System Components
- **FuelTank** interface with:
  - Volume and capacity tracking
  - Pressurization systems (N2, He pressurant)
  - Pressure dynamics (ideal gas law)
  - Temperature tracking
  - Valve control (feed to engine, RCS, crossfeed, vent)

- **FuelLine** for flow control:
  - Fuel pump active/inactive
  - Pressure tracking
  - Connected tank ID

- **Multiple Tanks**: Main tank 1, Main tank 2, RCS tank
  - Fuel mass calculated from volume and density
  - Center of mass position for balance calculation

### Landing Zone & Mission Objects
```typescript
interface LandingZone {
  id: string;
  name: string;
  coordinates: LatLon;
  difficulty: 'easy' | 'medium' | 'hard' | 'extreme';
  maxLandingSpeed: number;     // m/s
  maxLandingAngle: number;     // degrees
  terrainType: 'flat' | 'rocky' | 'cratered' | 'slope';
  boulderDensity: number;      // 0-1
  lighting: 'day' | 'night' | 'terminator';
}

interface Mission {
  id: string;
  name: string;
  briefing: string;
  landingZone: LandingZone;
  objectives: MissionObjective[];
  startAltitude: number;
  startVelocity: Vector3;
  startFuel: number;
}
```

---

## 3. PHYSICS & GAME MECHANICS

### Core Physics Engine (ShipPhysics)

#### **Orbital Mechanics**
- **Position & Velocity**: 3D inertial frame tracking (relative to planet center)
- **Gravitational Acceleration**: Inverse square law
  ```
  F = G * M * m / r²
  ```
- **Planet Parameters** (defaults for Moon):
  - Moon Mass: 7.342e22 kg
  - Moon Radius: 1,737,400 m
  - Gravitational Constant: 6.67430e-11 m³/(kg·s²)

#### **Rotational Dynamics**
- **Quaternion Integration**: q̇ = 0.5 * q * ω
- **Euler's Rotation Equations**: I·ω̇ = τ - ω × (I·ω)
- **Moment of Inertia**: Principal moments (Ix, Iy, Iz) in body frame
- **Angular Velocity**: Rad/s in body frame with gyroscopic coupling

#### **Thrust & Propulsion**
- **Main Engine Thrust**: Applied in body frame, rotated to inertial
- **RCS (Reaction Control System) Thrust**: Directional control thrusters
- **Mass-Dependent Acceleration**: a = (F_total + F_gravity) / total_mass

### Sub-System Physics Modules

#### **1. Fuel System**
- **Ideal Gas Law for Pressurization**: PV = nRT
- **Fuel Flow Dynamics**: Pressure-driven flow from tanks
- **Fuel Pump Control**: Active/inactive valve states
- **Pressurant Expansion**: Gas expansion as fuel is consumed
- **Tank Cross-feed**: Transfer fuel between tanks
- **Center of Mass Calculation**: Ship balance affects stability

#### **2. Electrical System**
- **Reactor**: Power generation with throttle control
  - Status: offline → starting → online → scrammed
  - Startup time: gradual ramp-up to full power
  - Thermal efficiency tracking
  - Waste heat generation (depends on throttle)
  
- **Battery**: Charge/discharge with thermal effects
  - Limited discharge/charge rates
  - Health degradation over charge cycles
  - Temperature-dependent performance
  
- **Capacitor Bank**: High-draw surge capacity
  
- **Dual Power Buses**: A and B with cross-tie capability
  
- **Circuit Breakers**: Overcurrent protection
  - Essential vs. non-essential circuits
  - Trip capability based on load

#### **3. Main Engine**
- **Thrust Output**: Based on Tsiolkovsky rocket equation
- **Specific Impulse (Isp)**: Typically 311 seconds (hypergolic fuel)
- **Gimbal Control**: Thrust vectoring ±6 degrees (pitch/yaw)
- **Throttle Control**: 0-1 range with minimum throttle limit (40% minimum)
- **Ignition Sequence**: 2-second startup, 0.5-second shutdown
- **Chamber Dynamics**: Pressure and temperature rise during ignition
- **Fuel/Oxidizer Consumption**: Tracked separately, based on thrust and Isp
- **Health Degradation**: Engine wear from firing
- **Restart Cooldown**: Minimum time between ignitions

#### **4. RCS (Reaction Control System)**
- **Directional Thrusters**: Multiple thrusters for pitch, roll, yaw control
- **Torque Generation**: From thruster geometry
- **Simpler Than Main Engine**: No gimbal, fixed direction
- **Alternative Propellant**: Separate from main fuel system

#### **5. Thermal System**
- **Per-Component Heat Tracking**: Reactor, main engine, RCS, etc.
- **Temperature Dynamics**: Mass and specific heat capacity
- **Heat Transfer**: Between components and compartments
- **Thermal Conduction**: Through bulkheads (W/K)
- **Passive Cooling**: Radiation to space (Stefan-Boltzmann law)
- **Compartments**: Modeled with temperature, volume, gas mass

#### **6. Coolant System**
- **Active Cooling Loops**: Pumps to remove heat from components
- **Coolant Flow**: Pump-driven circulation
- **Heat Exchanger Efficiency**: Transfers heat from components to radiators
- **Radiator Area**: Determines cooling capacity

#### **7. Compressed Gas System**
- **Pressurant Tracking**: N2, He, or none
- **Pressure Calculations**: Ideal gas law for expansion
- **Tank Pressurization**: Separate from fuel pressurization
- **Venting**: Controlled gas release

#### **8. Coolant System** (Liquid Cooling)
- **Active Cooling Loops**: Pump-based heat removal
- **Radiator Efficiency**: Temperature-dependent dissipation
- **Pump Power**: Electrical draw for circulation

### Advanced Flight Systems

#### **Flight Control System**
- **Stability Augmentation (SAS) Modes**:
  - Stability: Dampen rotation rates
  - Attitude Hold: Maintain orientation
  - Prograde: Point along velocity vector
  - Retrograde: Point opposite velocity
  - Radial In/Out: Point toward/away from planet
  - Normal/Anti-Normal: Orbit plane control

- **Autopilot Modes**:
  - Altitude Hold: Maintain specific altitude
  - Vertical Speed Hold: Constant descent/ascent rate
  - Suicide Burn: Automatic deceleration (touchdown preparation)
  - Hover: Maintain altitude with translation

- **PID Control Loops**:
  - Altitude controller
  - Vertical speed controller
  - Pitch, roll, yaw attitude controllers
  - Rate damping (angular velocity dampening)

#### **Navigation System**
- **Trajectory Prediction**: Numerical integration of future path
- **Impact Prediction**: Where will ship hit terrain
- **Suicide Burn Calculation**: Altitude to start deceleration
- **Velocity Decomposition**:
  - Total speed
  - Vertical/horizontal components
  - North/east components
  - Prograde/normal vectors

- **Flight Telemetry**:
  - Altitude (orbital & radar)
  - Vertical/horizontal speed
  - Time to impact
  - Thrust-to-weight ratio
  - Fuel burn time estimate
  - Delta-V remaining

#### **Mission System**
- **Landing Zone Management**: Multiple terrain types and difficulties
- **Mission Scoring**:
  - Landing quality (speed, angle, precision)
  - Resource efficiency (fuel, time)
  - System health during descent
  - Difficulty multiplier
  - Letter grade (S/A/B/C/D/F)

- **Objective Tracking**: Primary, secondary, bonus objectives
- **Checklists**: Pre-landing, descent, final approach, post-landing phases

### Master Update Loop (Integration)
```
1. Update electrical system (power generation)
2. Update main engine (thrust calculation)
3. Update RCS system
4. Update flight control (autopilot/SAS)
5. Get propellant consumption
6. Update thermal system (heat generation & transfer)
7. Update coolant system (active cooling)
8. Update ship physics (forces & torques)
9. Update navigation telemetry
10. Check for mission objectives
```

---

## 4. OVERALL ARCHITECTURE & FILE STRUCTURE

### Project Structure (Moon-Lander Branch)

```
/physics-modules/
├── src/
│   ├── types.ts                    # Shared type definitions (Vector2, FuelTank, etc.)
│   ├── spacecraft.ts               # Main spacecraft integration class
│   ├── ship-physics.ts             # Orbital mechanics & rotation dynamics
│   ├── fuel-system.ts              # Fuel tanks, pressurization, flow
│   ├── electrical-system.ts        # Reactor, batteries, power buses, breakers
│   ├── main-engine.ts              # Rocket engine thrust & gimbal control
│   ├── rcs-system.ts               # Reaction control thrusters
│   ├── thermal-system.ts           # Heat generation, transfer, radiation
│   ├── coolant-system.ts           # Active cooling loops
│   ├── compressed-gas-system.ts    # Pressurant gas expansion
│   ├── flight-control.ts           # SAS modes & autopilot PID controllers
│   ├── navigation.ts               # Trajectory prediction & telemetry
│   └── mission.ts                  # Landing zones, objectives, scoring
│
├── examples/
│   ├── interactive-game.ts         # Real-time flight simulator
│   ├── demo-captain-screen.ts      # Control station UI demo
│   └── landing-demo.ts             # Automated landing demo
│
├── tests/
│   ├── fuel-system.test.ts         # Unit tests for systems
│   └── [other system tests]
│
├── dist/                           # Compiled JavaScript output
├── node_modules/                   # Dependencies
├── package.json                    # Project dependencies
├── tsconfig.json                   # TypeScript configuration
└── README.md
```

### Documentation Files
```
/docs/
├── 00-OVERVIEW.md                 # Vision, design philosophy, inspirations
├── 01-CONTROL-STATIONS.md         # UI/panel specifications
├── 02-PHYSICS-SIMULATION.md       # Detailed physics documentation
├── 02-PHYSICS-SIMULATION-DETAILED.md
├── 03-EVENTS-PROGRESSION.md       # Campaign structure & events
├── 04-TECHNICAL-ARCHITECTURE.md   # Tech stack & implementation
├── 05-MVP-ROADMAP.md              # Development timeline
└── 06-VISUAL-DESIGN-REFERENCE.md  # Aesthetic guidelines
```

---

## 5. EXISTING CELESTIAL BODIES, SHIPS & OBJECTS

### Celestial Bodies
**Currently implemented for: Moon (default)**
- Mass: 7.342e22 kg
- Radius: 1,737,400 m
- Gravity: Inverse square law calculation
- Landing zones: Multiple terrain types (flat, rocky, cratered, slope)
- Lighting conditions: Day, night, terminator

**Not yet implemented but designed for**:
- Earth
- Mars
- Other planets/moons
- Space stations
- Asteroids
- Derelicts (encounter objects)

### Spacecraft
**Single Ship Type (MVP)**
- Name: Spacecraft (generic implementation)
- Class: Integrated systems simulator
- Default Configuration:
  - Dry Mass: 5,000 kg
  - Propellant: 3,000 kg
  - Moment of Inertia: {x: 2000, y: 2000, z: 500} kg·m²
  - Max Altitude: Starts at 15 km
  - Initial Velocity: 0 m/s (hover) or custom

### Game Objects Not Yet Implemented
- **Stations**: Orbital, planetary surface, asteroid
- **Planets**: Multiple celestial bodies beyond Moon
- **Asteroids**: For mining or navigation challenges
- **Derelicts**: For encounters, rescue missions
- **Environmental Hazards**:
  - Meteor showers
  - Solar storms
  - Radiation belts
  - Dust clouds
  
- **Crew Members**: Deferred to expansion
- **Parts/Modules**: For ship upgrades
- **Weapons**: Deliberately excluded from initial design

---

## 6. WHAT'S READY FOR UNIVERSE GENERATION

### Already Complete
- [x] Spacecraft systems architecture (8 core modules)
- [x] Physics simulation engine
- [x] Flight control & navigation systems
- [x] Landing mission system with scoring
- [x] Mission briefing & objective system
- [x] Save/load system (framework)
- [x] Event system (framework)

### Needs Implementation for Universe Generation
- [ ] **Procedural Universe Generator**
  - Planet generation (size, mass, gravity, terrain)
  - Station generation (orbital parameters, services)
  - Encounter generation (derelicts, events)
  - Campaign map generation (node-based)

- [ ] **Multiple Planets/Celestial Bodies**
  - Earth, Mars, Venus, moons, asteroids
  - Terrain variation algorithms
  - Gravity field calculations for each body

- [ ] **Space Stations**
  - Orbital mechanics for station positions
  - Docking mechanics
  - Services (refueling, repairs, trading)

- [ ] **Storm/Environmental Systems**
  - Solar storms affecting electronics
  - Radiation belts
  - Meteorite fields
  - Atmospheric interference

- [ ] **Campaign/Progression System**
  - Node-based map with FTL-style events
  - Event dispatch system
  - Resource economy (fuel, O2, parts)
  - Meta-progression (unlocks, achievements)

- [ ] **Encounter/Event System**
  - Navigation challenges (asteroid fields, intercepts)
  - Operational events (system failures, fires)
  - Encounter events (derelicts, distress calls, trading)
  - Event outcome resolution

---

## 7. CODE ORGANIZATION INSIGHTS

### Module Dependencies Flow
```
Spacecraft (orchestrator)
├── ShipPhysics (core orbital/rotation)
├── FuelSystem → ShipPhysics (consumes propellant)
├── MainEngine → FuelSystem (consumes fuel)
├── RCSSystem → FuelSystem (consumes fuel)
├── ElectricalSystem (generates power)
├── ThermalSystem (tracks heat generation)
├── CoolantSystem → ThermalSystem (removes heat)
├── CompressedGasSystem (tank pressurization)
├── FlightControl → ShipPhysics (SAS/autopilot)
├── Navigation → ShipPhysics (trajectory prediction)
└── Mission (objective tracking)
```

### Key Design Patterns
1. **State Pattern**: Engine status transitions (off → igniting → running → shutdown)
2. **Observer Pattern**: Event logging in all systems
3. **Strategy Pattern**: SAS mode selection in flight control
4. **Composite Pattern**: Spacecraft composes multiple systems
5. **Update Loop Pattern**: Master update() in Spacecraft coordinates all subsystems

### Configuration System
Most systems accept optional config objects:
```typescript
new Spacecraft({
  fuelConfig?: any;
  electricalConfig?: any;
  thermalConfig?: any;
  // ... etc
})
```

Default configurations are provided if none specified.

---

## 8. RECOMMENDED APPROACH FOR UNIVERSE GENERATION

Based on the existing architecture, here's how to add universe generation:

### Phase 1: Celestial Bodies
- Create abstract `CelestialBody` class
- Extend for `Planet`, `Moon`, `Asteroid`
- Implement terrain generation (perlin noise, fractal)
- Create factory for procedural generation

### Phase 2: Universe/World
- Create `Universe` class managing multiple bodies
- Implement spatial indexing (quadtree/octree)
- Add body discovery/mapping

### Phase 3: Stations
- Create `SpaceStation` class with orbital parameters
- Implement docking mechanics
- Add services system (refuel, repair, trade)

### Phase 4: Events & Encounters
- Extend existing event system in mission
- Create event generator based on location/difficulty
- Implement encounter resolution

### Phase 5: Campaign Map
- Implement node-based map (FTL-style)
- Add procedural event generation per node
- Create progression/meta-system

---

## 9. CURRENT DEVELOPMENT STATE

### Completed
- Core spacecraft systems simulation (9 modules)
- Physics engine with orbital mechanics
- Flight control with PID-based autopilot
- Navigation with trajectory prediction
- Mission system with landing objectives
- Interactive game loop (text-based)
- Comprehensive documentation

### In Progress
- Integration of all systems (mostly done)
- Testing and balancing
- UI/control panel design

### Not Started
- Procedural universe generation
- Multiple planets/bodies
- Space stations
- Advanced events/storms
- Campaign map system
- Visual renderer (Canvas integration planned)

---

## 10. KEY FILES TO REFERENCE

**For Universe Generation:**
- `/docs/04-TECHNICAL-ARCHITECTURE.md` - System structure
- `/physics-modules/src/types.ts` - Common type definitions
- `/physics-modules/src/spacecraft.ts` - Integration pattern
- `/physics-modules/src/mission.ts` - Landing zone structure (can be adapted)

**For Physics Systems:**
- `/physics-modules/src/ship-physics.ts` - Orbital mechanics baseline
- `/physics-modules/src/flight-control.ts` - Control system patterns

**For Game Design:**
- `/docs/00-OVERVIEW.md` - Design philosophy
- `/docs/03-EVENTS-PROGRESSION.md` - Campaign structure blueprint

