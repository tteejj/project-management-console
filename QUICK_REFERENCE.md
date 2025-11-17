# Space Game - Quick Reference Guide

## Project Overview at a Glance

**Type**: Spacecraft Systems Simulator (Moon Lander)  
**Genre**: Complex Procedural Simulation / Roguelike Exploration  
**Platform**: Browser (HTML5 + TypeScript)  
**Dev Status**: MVP phase - core systems complete, integration in progress  
**Design Inspiration**: FTL + Out There + Highfleet + DCS World + Dwarf Fortress  

---

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    SPACECRAFT (Main Entity)             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │        CORE PHYSICS SUBSYSTEMS (8 modules)       │  │
│  ├──────────────────────────────────────────────────┤  │
│  │ • Fuel System         → Pressurized tank mgmt    │  │
│  │ • Electrical System   → Reactor, power dist.     │  │
│  │ • Main Engine         → Thrust vectoring         │  │
│  │ • RCS System          → Attitude control         │  │
│  │ • Thermal System      → Heat generation/transfer │  │
│  │ • Coolant System      → Active cooling           │  │
│  │ • Compressed Gas      → Tank pressurization      │  │
│  │ • Ship Physics        → Orbital + rotation       │  │
│  └──────────────────────────────────────────────────┘  │
│                           ↓                             │
│  ┌──────────────────────────────────────────────────┐  │
│  │    ADVANCED FLIGHT SYSTEMS (3 systems)           │  │
│  ├──────────────────────────────────────────────────┤  │
│  │ • Flight Control      → SAS modes + Autopilot    │  │
│  │ • Navigation System   → Trajectory prediction    │  │
│  │ • Mission System      → Landing objectives       │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Data Structures (Key Objects)

### Spacecraft State
```
position: Vector3         (m from planet center)
velocity: Vector3         (m/s)
attitude: Quaternion      (no gimbal lock)
angularVelocity: Vector3  (rad/s)
dryMass: number          (kg)
propellantMass: number   (kg)
```

### Fuel Tank
```
id: string
fuelMass: number         (kg)
capacity: number         (kg max)
pressureBar: number      (atm)
temperature: number      (Kelvin)
position: Vector2        (for balance calc)
```

### Landing Zone
```
id: string
name: string
difficulty: easy|medium|hard|extreme
maxLandingSpeed: number  (m/s)
maxLandingAngle: number  (degrees)
terrainType: flat|rocky|cratered|slope
lighting: day|night|terminator
```

---

## Physics Engine Constants

**Gravity Calculations**
- G = 6.67430e-11 m³/(kg·s²)
- Moon Mass = 7.342e22 kg
- Moon Radius = 1,737,400 m

**Engine Specs**
- Max Thrust = 45,000 N (45 kN)
- Specific Impulse = 311 seconds
- Max Gimbal = ±6 degrees
- Ignition Time = 2 seconds
- Minimum Throttle = 40%

**Ship Defaults**
- Dry Mass = 5,000 kg
- Fuel Capacity = 3,000 kg
- Moment of Inertia = {x:2000, y:2000, z:500} kg·m²
- Starting Altitude = 15 km

---

## Update Loop Sequence (Per Frame)

```
1. Electrical System    → Generate power
2. Main Engine         → Calculate thrust
3. RCS System          → Calculate torques
4. Flight Control      → Update autopilot/SAS
5. Thermal System      → Heat transfer & generation
6. Coolant System      → Active cooling
7. Ship Physics        → Update position/rotation
8. Navigation          → Telemetry update
9. Mission System      → Check objectives
10. Events             → Log any events
```

---

## Physics Equations (Key)

**Orbital Mechanics**
```
F_gravity = G * M * m / r²
a_total = (F_thrust + F_gravity) / m_total
```

**Rotational Dynamics**
```
I·ω̇ = τ - ω × (I·ω)    [Euler equations]
q̇ = 0.5 * q * ω       [Quaternion integration]
```

**Tank Pressure (Ideal Gas Law)**
```
P·V = n·R·T
P = (n·R·T) / V
```

**Main Engine Thrust (Tsiolkovsky)**
```
Thrust = Isp * g0 * (dm/dt)
```

---

## File Map

**Core Modules** (physics-modules/src/)
```
types.ts              ← Shared types & interfaces
spacecraft.ts         ← Main integration class
ship-physics.ts       ← Orbital & rotation mechanics
fuel-system.ts        ← Tank management
electrical-system.ts  ← Power generation
main-engine.ts        ← Rocket engine physics
rcs-system.ts         ← Attitude thrusters
thermal-system.ts     ← Heat simulation
coolant-system.ts     ← Active cooling
compressed-gas-system.ts ← Tank pressurization
flight-control.ts     ← SAS & autopilot (PID)
navigation.ts         ← Trajectory prediction
mission.ts            ← Landing zones & scoring
```

**Documentation** (docs/)
```
00-OVERVIEW.md        ← Design philosophy
01-CONTROL-STATIONS.md ← UI specifications
02-PHYSICS-SIMULATION.md ← Detailed physics
03-EVENTS-PROGRESSION.md ← Campaign structure
04-TECHNICAL-ARCHITECTURE.md ← Tech stack
05-MVP-ROADMAP.md     ← Development timeline
```

---

## What's Built vs What's Needed

### Built (Existing)
- [x] 8 core physics modules
- [x] 3 advanced flight systems
- [x] Full orbital mechanics (2D simplified)
- [x] Quaternion-based rotation
- [x] PID-based autopilot
- [x] Trajectory prediction
- [x] Landing zone system
- [x] Mission scoring
- [x] Interactive game loop

### Needed for Universe
- [ ] Procedural planet generation
- [ ] Multiple celestial bodies
- [ ] Space station system
- [ ] Storm/environmental hazards
- [ ] Campaign/progression system
- [ ] Event encounter system
- [ ] Docking mechanics
- [ ] Station services (refuel, repair)
- [ ] HTML5 Canvas renderer
- [ ] Multi-body gravity solver

---

## Key Patterns & Design Decisions

**Design Patterns Used**
1. Entity-Component-System (simplified)
2. State Machine (engine status)
3. Observer (event logging)
4. Strategy (SAS modes)
5. Composite (systems composition)
6. Update Loop (master coordination)

**Configuration Pattern**
```typescript
new Spacecraft({
  fuelConfig?: {...},
  electricalConfig?: {...},
  thermalConfig?: {...}
  // etc - optional, defaults provided
})
```

**Event System**
```typescript
events: Array<{
  time: number;
  type: string;
  data: any;
}>
```

---

## Recommended Reading Order

1. **SPACE_GAME_ANALYSIS.md** (this report - full details)
2. **/docs/00-OVERVIEW.md** (design vision)
3. **/docs/04-TECHNICAL-ARCHITECTURE.md** (system structure)
4. **/physics-modules/src/types.ts** (data structures)
5. **/physics-modules/src/spacecraft.ts** (integration pattern)
6. **/docs/03-EVENTS-PROGRESSION.md** (universe design)

---

## Development Roadmap (Suggested)

**Phase 1**: Celestial Body Framework
- Abstract CelestialBody class
- Planet/Moon/Asteroid implementations
- Procedural terrain generation (Perlin noise)
- Multi-body gravity solver

**Phase 2**: Universe Management
- Universe class with spatial indexing
- Body discovery/mapping system
- Orbital parameter calculations

**Phase 3**: Space Stations
- SpaceStation class
- Docking mechanics
- Service system (refuel, repair, trade)

**Phase 4**: Encounters & Events
- Event generator system
- Derelict encounters
- Navigation challenges
- Storm systems

**Phase 5**: Campaign Map
- Node-based map (FTL style)
- Procedural event generation
- Meta-progression system

---

## Key Metrics

**Physics Fidelity**
- Position: Meter precision
- Time: Sub-second precision (0.1s steps typical)
- Gravity: Inverse square law, no approximation

**Control Complexity**
- 30-40 ship systems (target)
- 4-5 control stations
- 80-120 individual controls

**Gameplay Scope**
- 20-30 node campaign (per run)
- 5-30 minutes per run
- 2-5 hours total completion

**Performance Target**
- 60 FPS target (when rendered)
- 100+ simulation steps per render frame typical
- Minimal CPU overhead

---

## Contact Points for Integration

**Adding New Celestial Body**
- Extend ShipPhysics with new planet params
- Create LandingZone instances
- Add to Universe class (future)

**Adding New System**
- Create new XxxSystem class in src/
- Add update() method
- Register in Spacecraft constructor
- Wire into master update loop

**Adding Events**
- Use existing event logging framework
- Create event type definitions
- Wire into encounter system (future)

**Adding Stations**
- Implement SpaceStation class
- Create docking mechanics
- Add service definitions
- Wire into mission system

