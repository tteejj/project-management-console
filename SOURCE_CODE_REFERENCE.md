# Source Code Reference Guide

## Access the Game Code

The space game code is in the **`claude/vector-moon-lander-game-01Cx4P7A34QkDZ5YiDJwLL3M`** branch.

To view code for any file listed below:
```bash
git show claude/vector-moon-lander-game-01Cx4P7A34QkDZ5YiDJwLL3M:PATH/TO/FILE
```

Or switch to that branch:
```bash
git checkout claude/vector-moon-lander-game-01Cx4P7A34QkDZ5YiDJwLL3M
```

---

## Core Module Locations

All physics modules are in:
```
/physics-modules/src/
```

### 1. Types & Interfaces
**File**: `physics-modules/src/types.ts`

Key types:
- `Vector2` - 2D position for tank location
- `Vector3` - 3D position/velocity (future expansion)
- `Quaternion` - Rotation (no gimbal lock)
- `FuelTank` - Tank object with pressurization
- `FuelLine` - Fuel flow control
- `SimulationState` - Time tracking

### 2. Main Spacecraft Integration
**File**: `physics-modules/src/spacecraft.ts`

Main class: `Spacecraft`
- Integrates all 11 systems
- Master update loop
- Initialization with optional configs
- State getters/setters

Key methods:
- `update(dt: number)` - Master update loop
- `getState()` - Return complete state
- `startReactor()` - Startup sequence
- `startCoolantPump(pumpId: number)` - Activate cooling

### 3. Ship Physics (Orbital Mechanics)
**File**: `physics-modules/src/ship-physics.ts`

Main class: `ShipPhysics`

Responsibilities:
- 3D position/velocity tracking
- Quaternion-based rotation (no gimbal lock)
- Gravitational acceleration (inverse square law)
- Thrust application in body frame
- Rotational dynamics (Euler equations)

Key physics:
```typescript
// Gravity
const gravity = this.calculateGravity();  // Vector3

// Rotation - Euler's equations
// I·ω̇ = τ - ω × (I·ω)
private updateRotation(dt: number, mainEngineTorque: Vector3, rcsTorque: Vector3)

// Quaternion integration
// q̇ = 0.5 * q * ω
private integrateQuaternion(dt: number)
```

Key properties:
- `position: Vector3` - meters from planet center
- `velocity: Vector3` - m/s
- `attitude: Quaternion` - orientation
- `angularVelocity: Vector3` - rad/s

### 4. Fuel System
**File**: `physics-modules/src/fuel-system.ts`

Main class: `FuelSystem`

Features:
- Multiple fuel tanks (main_1, main_2, rcs)
- Pressurization with pressurant gas (N2, He)
- Ideal gas law pressure calculation
- Fuel pump control
- Tank cross-feed capability
- Center of mass calculation

Tank properties:
```typescript
interface FuelTank {
  id: string;
  volume: number;              // liters
  fuelMass: number;            // kg
  capacity: number;            // kg max
  pressurized: boolean;
  pressureBar: number;
  pressurantType: 'N2' | 'He'; // Pressurant gas type
  temperature: number;         // Kelvin
  valves: {
    feedToEngine: boolean;
    feedToRCS: boolean;
    crossfeedTo?: string;
    fillPort: boolean;
    vent: boolean;
  };
}
```

### 5. Electrical System
**File**: `physics-modules/src/electrical-system.ts`

Main class: `ElectricalSystem`

Components:
- Reactor (power generation, status tracking)
- Battery (charge/discharge, health degradation)
- Capacitor bank (surge capacity)
- Dual power buses (A & B)
- Circuit breakers (overcurrent protection)

Reactor states:
```typescript
status: 'offline' | 'starting' | 'online' | 'scrammed'
throttle: number;           // 0-1
maxOutputKW: number;
temperature: number;        // K
thermalEfficiency: number;  // Waste heat generation
```

### 6. Main Engine
**File**: `physics-modules/src/main-engine.ts`

Main class: `MainEngine`

Features:
- Tsiolkovsky rocket equation
- Specific impulse (Isp) calculation
- Gimbal control (thrust vectoring)
- Throttle control with minimum throttle
- Ignition sequence (startup/shutdown)
- Chamber pressure/temperature dynamics
- Engine health degradation
- Fuel consumption tracking

Engine parameters:
```typescript
maxThrustN: number;          // 45,000 N default
specificImpulseSec: number;  // 311 seconds
maxGimbalDeg: number;        // ±6 degrees
ignitionTimeS: number;       // 2 seconds
shutdownTimeS: number;       // 0.5 seconds
minThrottle: number;         // 40% minimum
```

### 7. RCS System
**File**: `physics-modules/src/rcs-system.ts`

Main class: `RCSSystem`

Features:
- Directional thrusters for rotation
- Torque generation from thruster geometry
- Separate propellant from main fuel
- Pulse control (on/off for each axis)

### 8. Thermal System
**File**: `physics-modules/src/thermal-system.ts`

Main class: `ThermalSystem`

Features:
- Per-component heat tracking
- Heat transfer between compartments
- Thermal conduction through bulkheads
- Passive cooling (radiation to space)
- Stefan-Boltzmann radiation law

Heat sources:
```typescript
interface HeatSource {
  name: string;
  heatGenerationW: number;  // Current heat in watts
  temperature: number;      // K
  mass: number;            // kg
  specificHeat: number;    // J/(kg·K)
  compartmentId: number;
}
```

### 9. Coolant System
**File**: `physics-modules/src/coolant-system.ts`

Main class: `CoolantSystem`

Features:
- Active cooling loops
- Pump control (on/off)
- Radiator efficiency calculation
- Pump power consumption

### 10. Compressed Gas System
**File**: `physics-modules/src/compressed-gas-system.ts`

Main class: `CompressedGasSystem`

Features:
- Pressurant gas expansion
- Ideal gas law calculations
- Venting control

### 11. Flight Control System
**File**: `physics-modules/src/flight-control.ts`

Main class: `FlightControlSystem`

Features:
- **SAS Modes**:
  - `'stability'` - Dampen rotations
  - `'attitude_hold'` - Maintain orientation
  - `'prograde'` - Point along velocity
  - `'retrograde'` - Point opposite velocity
  - `'radial_in/out'` - Point toward/away from planet
  - `'normal/anti_normal'` - Orbit plane control

- **Autopilot Modes**:
  - `'altitude_hold'` - Maintain altitude
  - `'vertical_speed_hold'` - Constant descent rate
  - `'suicide_burn'` - Auto deceleration
  - `'hover'` - Maintain altitude with translation

- **PID Control Loops**:
  - Altitude controller
  - Vertical speed controller
  - Pitch/roll/yaw attitude controllers
  - Rate damping

### 12. Navigation System
**File**: `physics-modules/src/navigation.ts`

Main class: `NavigationSystem`

Features:
- Trajectory prediction
- Impact prediction
- Suicide burn calculation
- Velocity decomposition
- Flight telemetry

Key interfaces:
```typescript
interface ImpactPrediction {
  impactTime: number;
  impactPosition: Vector3;
  impactVelocity: Vector3;
  impactSpeed: number;
  coordinates: LatLon;
  willImpact: boolean;
}

interface FlightTelemetry {
  altitude: number;
  radarAltitude: number;
  verticalSpeed: number;
  horizontalSpeed: number;
  totalSpeed: number;
  timeToImpact: number;
  impactSpeed: number;
  pitch: number;
  roll: number;
  yaw: number;
  thrust: number;
  throttle: number;
  twr: number;
  fuelRemaining: number;
  deltaVRemaining: number;
}
```

### 13. Mission System
**File**: `physics-modules/src/mission.ts`

Main classes: `Mission`, `MissionSystem`

Features:
- Landing zone definitions
- Mission objectives (primary/secondary/bonus)
- Checklists (pre-landing, descent, etc.)
- Mission scoring system

Landing zone:
```typescript
interface LandingZone {
  id: string;
  name: string;
  coordinates: LatLon;
  radius: number;              // Acceptable landing radius (m)
  difficulty: 'easy' | 'medium' | 'hard' | 'extreme';
  maxLandingSpeed: number;     // m/s
  maxLandingAngle: number;     // degrees
  targetPrecision: number;     // Bonus radius (m)
  terrainType: 'flat' | 'rocky' | 'cratered' | 'slope';
  boulderDensity: number;      // 0-1
  lighting: 'day' | 'night' | 'terminator';
}
```

Mission scoring:
```typescript
interface MissionScore {
  landingSpeedScore: number;    // 0-1000
  landingAngleScore: number;    // 0-1000
  precisionScore: number;       // 0-1000
  fuelEfficiencyScore: number;  // 0-500
  timeEfficiencyScore: number;  // 0-500
  systemHealthScore: number;    // 0-300
  procedureScore: number;       // 0-300
  difficultyMultiplier: number;
  totalScore: number;
  grade: 'S' | 'A' | 'B' | 'C' | 'D' | 'F';
}
```

---

## Example Files

### Interactive Game
**File**: `physics-modules/examples/interactive-game.ts`

A complete real-time flight simulator demonstrating all systems.

Includes:
- Spacecraft initialization
- Game loop
- Keyboard input handling
- System startup sequence
- Real-time telemetry display

### Demo Captain Screen
**File**: `physics-modules/examples/demo-captain-screen.ts`

Example of control station UI design.

### Landing Demo
**File**: `physics-modules/examples/landing-demo.ts`

Automated landing demonstration.

---

## Documentation Files

### Design Overview
**File**: `docs/00-OVERVIEW.md`

Covers:
- Project vision
- Design inspirations
- Design pillars
- What the game is/isn't
- Design decisions taken/rejected

### Control Stations
**File**: `docs/01-CONTROL-STATIONS.md`

Detailed specifications:
- Helm/Propulsion station
- Engineering station
- Navigation station
- Life support station
- Control counts (MVP vs Full)

### Physics Simulation
**File**: `docs/02-PHYSICS-SIMULATION.md`

Detailed physics documentation:
- Orbital mechanics
- Propulsion physics
- Thermal physics
- Atmosphere & life support
- Fire & damage simulation
- System interconnections

### Events & Progression
**File**: `docs/03-EVENTS-PROGRESSION.md`

Campaign structure:
- Sector map (node-based, FTL-style)
- Event types
- Resource economy
- Meta-progression
- Difficulty curve

### Technical Architecture
**File**: `docs/04-TECHNICAL-ARCHITECTURE.md`

Technical implementation:
- Technology stack
- Project structure
- Core architecture patterns
- Data flow
- Performance optimization

### MVP Roadmap
**File**: `docs/05-MVP-ROADMAP.md`

Development timeline:
- MVP scope
- 18-day development plan
- Phase-by-phase implementation
- Post-MVP roadmap

### Visual Design
**File**: `docs/06-VISUAL-DESIGN-REFERENCE.md`

Aesthetic guidelines:
- Color palettes
- Visual style
- Font choices
- UI design principles

---

## How to Extend the System

### Adding a New Physics System

1. Create new file: `physics-modules/src/my-system.ts`

2. Define your system class:
```typescript
export interface MySystemConfig {
  param1?: number;
  param2?: string;
}

export class MySystem {
  // Properties
  public state: SomeState;

  constructor(config?: MySystemConfig) {
    // Initialize with defaults or config
  }

  // Main update method (called every frame)
  update(dt: number, simulationTime: number): void {
    // Perform calculations
  }

  // State getter
  getState(): SomeState {
    return this.state;
  }
}
```

3. Register in Spacecraft:
```typescript
// In spacecraft.ts constructor:
this.mySystem = new MySystem(config?.mySystemConfig);

// In update loop:
this.mySystem.update(dt, this.simulationTime);
```

### Adding a New Celestial Body

1. Extend ShipPhysics configuration:
```typescript
new Spacecraft({
  shipPhysicsConfig: {
    planetMass: 5.972e24,        // Earth mass (kg)
    planetRadius: 6371000,        // Earth radius (m)
    initialPosition: { x: 0, y: 0, z: 6371000 + 400000 },
    initialVelocity: { x: 7660, y: 0, z: 0 }  // Orbital velocity
  }
})
```

2. Create landing zones:
```typescript
const earthSurfaceLz: LandingZone = {
  id: 'earth_1',
  name: 'Kennedy Space Center',
  coordinates: { lat: 28.5, lon: -80.7 },
  difficulty: 'hard',
  maxLandingSpeed: 10,  // Very low for runway landing
  terrainType: 'flat',
  lighting: 'day'
};
```

### Adding a New Event Type

Use the existing event logging framework:
```typescript
// In any system's update method:
this.events.push({
  time: simulationTime,
  type: 'my_event_type',
  data: { /* event details */ }
});
```

Events are automatically logged in the Spacecraft's event array for later analysis.

---

## Build & Development

### Build the Project
```bash
cd physics-modules
npm install
npm run build
```

### Run Tests
```bash
npm test
```

### Run Interactive Game
```bash
npm run start:game
```

### Development Server
```bash
npm run dev
```

---

## Key Formulas Reference

### Gravity Calculation
```typescript
const G = 6.67430e-11;  // m³/(kg·s²)
const rSquared = distance * distance;
const gravityAccel = (G * planetMass) / rSquared;  // m/s²
```

### Thrust from Tsiolkovsky
```typescript
const g0 = 9.80665;  // Standard gravity
const thrustN = specificImpulseSec * g0 * massFlowRate;
```

### Tank Pressure from Ideal Gas Law
```typescript
const R = 8.314;  // Gas constant
const ullageVolume = tankVolume - (fuelMass / fuelDensity);
const pressure = (pressurantMoles * R * temperature) / (ullageVolume * 1000);
```

### Heat Generation
```typescript
const heatW = efficiency * powerW;  // Watts
const temperatureRise = heatW / (mass * specificHeat);
```

### PID Control Output
```typescript
const error = setpoint - measured;
const output = kp * error + ki * integral + kd * derivative;
```

---

## Testing

Each major system has corresponding tests:
- `physics-modules/tests/fuel-system.test.ts`
- (Other system tests follow same pattern)

Test structure:
```typescript
describe('FuelSystem', () => {
  it('should calculate pressure correctly', () => {
    // Test implementation
  });
});
```

Run with: `npm test`

