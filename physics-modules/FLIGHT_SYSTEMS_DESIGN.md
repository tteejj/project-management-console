# Flight Systems Design Document

## Overview

This document describes the advanced flight control, navigation, and mission systems for the Vector Moon Lander. These systems build on the core physics modules to provide realistic spacecraft control with "submarine in space" complexity.

---

## 1. Flight Control System

### 1.1 PID Controllers

**Purpose**: Closed-loop control for automated flight parameters

**PID Controller Class**:
```typescript
class PIDController {
  private kp: number;  // Proportional gain
  private ki: number;  // Integral gain
  private kd: number;  // Derivative gain
  private integral: number;
  private previousError: number;

  update(currentValue: number, targetValue: number, dt: number): number {
    const error = targetValue - currentValue;
    this.integral += error * dt;
    const derivative = (error - this.previousError) / dt;
    this.previousError = error;

    return (this.kp * error) + (this.ki * this.integral) + (this.kd * derivative);
  }
}
```

**Controllers Required**:
- Altitude Hold PID
- Vertical Speed Hold PID
- Attitude Hold PID (pitch, roll, yaw)
- Angular Rate Damping PID

**Tuning Parameters**:
| Controller | Kp | Ki | Kd | Notes |
|------------|-----|-----|-----|-------|
| Altitude | 0.05 | 0.001 | 0.2 | Slow, stable response |
| Vertical Speed | 0.8 | 0.1 | 0.15 | Fast response needed |
| Attitude | 1.5 | 0.05 | 0.5 | Prevent overshoot |
| Rate Damping | 2.0 | 0.0 | 0.3 | Pure damping, no integral |

### 1.2 Stability Augmentation System (SAS)

**Purpose**: Automatic stability and damping of spacecraft motion

**SAS Modes**:

1. **OFF** - Direct manual control only
2. **STABILITY** - Dampen rotation rates, prevent tumbling
3. **ATTITUDE_HOLD** - Maintain current orientation
4. **PROGRADE** - Point in direction of motion
5. **RETROGRADE** - Point opposite to direction of motion
6. **RADIAL_IN** - Point toward planet center
7. **RADIAL_OUT** - Point away from planet center
8. **NORMAL** - Point along orbit normal (perpendicular to orbital plane)
9. **ANTI_NORMAL** - Point opposite to orbit normal

**Implementation**:
```typescript
class SASController {
  private mode: SASMode;
  private attitudePID: PIDController[];  // [pitch, roll, yaw]
  private rateDampingPID: PIDController[];

  update(
    currentAttitude: Quaternion,
    currentAngularVel: Vector3,
    targetAttitude: Quaternion,
    dt: number
  ): RCSCommands {
    // Calculate attitude error
    const errorQuat = quaternionDifference(targetAttitude, currentAttitude);
    const errorAngles = quaternionToEuler(errorQuat);

    // PID control for each axis
    const pitchCommand = this.attitudePID[0].update(errorAngles.pitch, 0, dt);
    const rollCommand = this.attitudePID[1].update(errorAngles.roll, 0, dt);
    const yawCommand = this.attitudePID[2].update(errorAngles.yaw, 0, dt);

    // Add rate damping
    pitchCommand += this.rateDampingPID[0].update(currentAngularVel.x, 0, dt);
    rollCommand += this.rateDampingPID[1].update(currentAngularVel.y, 0, dt);
    yawCommand += this.rateDampingPID[2].update(currentAngularVel.z, 0, dt);

    return { pitch: pitchCommand, roll: rollCommand, yaw: yawCommand };
  }
}
```

### 1.3 Autopilot Modes

**Altitude Hold**:
```typescript
// Maintain specific altitude above surface
targetAltitude: number
throttleCommand = altitudePID.update(currentAlt, targetAlt, dt)
// Clamp to [0, 1] and apply to main engine
```

**Vertical Speed Hold**:
```typescript
// Maintain constant descent/ascent rate
targetVerticalSpeed: number  // e.g., -5 m/s for gentle descent
throttleCommand = verticalSpeedPID.update(currentVSpeed, targetVSpeed, dt)
```

**Suicide Burn Autopilot**:
```typescript
// Calculate optimal burn start altitude
const effectiveThrust = maxThrust * cos(angleFromVertical);
const acceleration = effectiveThrust / currentMass;
const burnDistance = (verticalSpeed²) / (2 * acceleration);
const safetyFactor = 1.1;
const burnAltitude = burnDistance * safetyFactor;

if (altitude <= burnAltitude && !burning) {
  igniteEngine();
  setThrottle(1.0);
}
```

**Hover Mode**:
```typescript
// Automatically maintain altitude while allowing translation
const gravity = calculateGravity(altitude);
const hoverThrust = currentMass * gravity;
const hoverThrottle = hoverThrust / maxThrust;
// Apply small corrections via PID
```

### 1.4 Gimbal Autopilot

**Purpose**: Automatically vector thrust to null horizontal velocity

```typescript
// Calculate horizontal velocity vector
const horizontalVel = { x: velocity.x, y: velocity.y };
const horizontalSpeed = magnitude(horizontalVel);

// Calculate required gimbal angle to counter horizontal drift
const thrustAccel = currentThrust / mass;
const gimbalAngle = atan2(horizontalSpeed, thrustAccel);

// Apply gimbal to oppose horizontal velocity direction
const gimbalDirection = -normalize(horizontalVel);
engine.setGimbal(
  gimbalDirection.y * gimbalAngle,  // pitch
  gimbalDirection.x * gimbalAngle   // yaw
);
```

---

## 2. Navigation & Display System

### 2.1 Trajectory Prediction

**Impact Point Calculation**:
```typescript
class TrajectoryPredictor {
  predictImpact(
    position: Vector3,
    velocity: Vector3,
    mass: number,
    engineThrust: number
  ): ImpactPrediction {
    // Numerical integration of trajectory
    let pos = { ...position };
    let vel = { ...velocity };
    let time = 0;
    const dt = 0.1;

    while (getAltitude(pos) > 0 && time < 1000) {
      const gravity = calculateGravityVector(pos);
      const thrust = engineThrust > 0 ?
        calculateThrustVector(engineThrust, attitude) :
        { x: 0, y: 0, z: 0 };

      const accel = {
        x: (thrust.x / mass) + gravity.x,
        y: (thrust.y / mass) + gravity.y,
        z: (thrust.z / mass) + gravity.z
      };

      vel.x += accel.x * dt;
      vel.y += accel.y * dt;
      vel.z += accel.z * dt;

      pos.x += vel.x * dt;
      pos.y += vel.y * dt;
      pos.z += vel.z * dt;

      time += dt;
    }

    return {
      impactTime: time,
      impactPosition: pos,
      impactVelocity: vel,
      coordinates: positionToLatLon(pos)
    };
  }
}
```

**Suicide Burn Calculator**:
```typescript
calculateSuicideBurn(
  altitude: number,
  verticalSpeed: number,
  mass: number,
  maxThrust: number
): SuicideBurnData {
  const acceleration = maxThrust / mass;
  const stopDistance = (verticalSpeed * verticalSpeed) / (2 * acceleration);
  const safetyMargin = 1.15; // 15% safety factor
  const burnAltitude = stopDistance * safetyMargin;
  const timeUntilBurn = (altitude - burnAltitude) / Math.abs(verticalSpeed);

  return {
    burnAltitude,
    currentAltitude: altitude,
    timeUntilBurn,
    shouldBurn: altitude <= burnAltitude,
    burnDuration: Math.abs(verticalSpeed) / acceleration
  };
}
```

### 2.2 Navball Display

**Purpose**: Visual attitude reference similar to KSP

```
ASCII Navball:
        N (0°)
    NW  ↑  NE
  W ← [◉] → E
    SW  ↓  SE
        S (180°)

Markers:
  ⊕ Prograde (direction of motion)
  ⊗ Retrograde (opposite motion)
  ◎ Target (landing zone)
  ⊙ Radial In
  ⊚ Radial Out
  ⊡ Normal
  ⊟ Anti-Normal
```

**Implementation**:
```typescript
class NavballDisplay {
  render(
    attitude: Quaternion,
    velocity: Vector3,
    targetDirection?: Vector3
  ): string {
    // Convert quaternion to pitch/roll/yaw
    const euler = quaternionToEuler(attitude);

    // Calculate prograde marker position on navball
    const progradeBody = worldToBody(normalize(velocity), attitude);
    const progradePos = vectorToNavballCoords(progradeBody);

    // Render ASCII navball with markers
    // ...
  }
}
```

### 2.3 Velocity Modes

**Surface Relative Velocity**:
- Velocity relative to rotating surface
- Account for moon's rotation
- Used for landing

**Orbit Relative Velocity**:
- Velocity relative to inertial frame
- Used for orbital mechanics

**Decomposition**:
```typescript
interface VelocityBreakdown {
  total: number;           // Total speed magnitude
  vertical: number;        // Radial component (toward/away from surface)
  horizontal: number;      // Tangential component (parallel to surface)
  north: number;          // North component
  east: number;           // East component
  prograde: number;       // Along velocity vector
  normal: number;         // Perpendicular to orbital plane
}
```

### 2.4 Enhanced Telemetry

```typescript
interface FlightTelemetry {
  // Position & Velocity
  altitude: number;
  radarAltitude: number;  // Terrain-relative
  verticalSpeed: number;
  horizontalSpeed: number;
  totalSpeed: number;

  // Trajectory
  timeToImpact: number;
  impactSpeed: number;
  impactCoordinates: LatLon;
  suicideBurnAltitude: number;
  timeToSuicideBurn: number;

  // Attitude
  pitch: number;
  roll: number;
  yaw: number;
  heading: number;
  angleFromVertical: number;

  // Propulsion
  thrust: number;
  throttle: number;
  twr: number;  // Thrust-to-weight ratio

  // Resources
  fuelRemaining: number;
  fuelRemainingPercent: number;
  estimatedBurnTime: number;
  deltaVRemaining: number;

  // Navigation
  distanceToTarget: number;
  bearingToTarget: number;
}
```

---

## 3. Mission System

### 3.1 Landing Zones

**Landing Zone Definition**:
```typescript
interface LandingZone {
  id: string;
  name: string;
  description: string;
  coordinates: LatLon;
  radius: number;  // Acceptable landing radius in meters
  difficulty: 'easy' | 'medium' | 'hard' | 'extreme';

  // Constraints
  maxLandingSpeed: number;  // m/s
  maxLandingAngle: number;  // degrees from vertical
  targetPrecision: number;  // bonus radius in meters

  // Environment
  terrainType: 'flat' | 'rocky' | 'cratered' | 'slope';
  boulderDensity: number;  // 0-1
  lighting: 'day' | 'night' | 'terminator';
}
```

**Example Landing Zones**:
```typescript
const landingZones: LandingZone[] = [
  {
    id: 'lz_tranquility',
    name: 'Mare Tranquillitatis Base Alpha',
    description: 'Primary landing site. Flat terrain, good visibility.',
    coordinates: { lat: 0.674, lon: 23.473 },
    radius: 500,
    difficulty: 'easy',
    maxLandingSpeed: 3.0,
    maxLandingAngle: 10,
    targetPrecision: 50,
    terrainType: 'flat',
    boulderDensity: 0.1,
    lighting: 'day'
  },
  {
    id: 'lz_crater_rim',
    name: 'Copernicus Crater Rim Station',
    description: 'Challenging crater rim landing. Precision required.',
    coordinates: { lat: 9.62, lon: -20.08 },
    radius: 200,
    difficulty: 'hard',
    maxLandingSpeed: 2.0,
    maxLandingAngle: 5,
    targetPrecision: 20,
    terrainType: 'slope',
    boulderDensity: 0.4,
    lighting: 'terminator'
  },
  {
    id: 'lz_south_pole',
    name: 'Shackleton Crater Ice Mine',
    description: 'Extreme difficulty. Permanently shadowed, rough terrain.',
    coordinates: { lat: -89.54, lon: 0 },
    radius: 100,
    difficulty: 'extreme',
    maxLandingSpeed: 1.5,
    maxLandingAngle: 3,
    targetPrecision: 10,
    terrainType: 'rocky',
    boulderDensity: 0.7,
    lighting: 'night'
  }
];
```

### 3.2 Scoring System

**Score Components**:
```typescript
interface MissionScore {
  // Landing Quality (0-1000 points)
  landingSpeedScore: number;     // Gentler = better
  landingAngleScore: number;     // More vertical = better
  precisionScore: number;        // Closer to target = better

  // Resource Efficiency (0-500 points)
  fuelEfficiencyScore: number;   // More fuel remaining = better
  timeEfficiencyScore: number;   // Faster landing = better

  // System Health (0-300 points)
  systemHealthScore: number;     // No damage = better
  procedureScore: number;        // Followed checklists = better

  // Difficulty Multiplier
  difficultyMultiplier: number;  // 1.0 / 1.5 / 2.0 / 3.0

  // Final Score
  totalScore: number;
  grade: 'S' | 'A' | 'B' | 'C' | 'D' | 'F';
}
```

**Scoring Formulas**:
```typescript
// Landing Speed Score (max 400 points)
const speedScore = Math.max(0, 400 * (1 - landingSpeed / maxAllowedSpeed));

// Precision Score (max 300 points)
const distanceFromTarget = calculateDistance(landingPos, targetPos);
const precisionScore = Math.max(0, 300 * (1 - distanceFromTarget / landingZoneRadius));

// Landing Angle Score (max 300 points)
const angleScore = Math.max(0, 300 * (1 - landingAngle / maxAllowedAngle));

// Fuel Efficiency Score (max 300 points)
const fuelPercent = remainingFuel / initialFuel;
const fuelScore = 300 * fuelPercent;

// Time Efficiency Score (max 200 points)
const timeScore = Math.max(0, 200 * (1 - missionTime / parTime));

// System Health Score (max 200 points)
const avgHealth = (reactorHealth + engineHealth + batteryHealth) / 3;
const healthScore = 200 * (avgHealth / 100);

// Procedure Score (max 100 points)
const procedureScore = completedChecklists.length * 20;

// Total with difficulty multiplier
const baseScore = speedScore + precisionScore + angleScore +
                  fuelScore + timeScore + healthScore + procedureScore;
const totalScore = baseScore * difficultyMultiplier;

// Grade assignment
if (totalScore >= 2500) grade = 'S';
else if (totalScore >= 2000) grade = 'A';
else if (totalScore >= 1500) grade = 'B';
else if (totalScore >= 1000) grade = 'C';
else if (totalScore >= 500) grade = 'D';
else grade = 'F';
```

### 3.3 Mission Objectives

```typescript
interface MissionObjective {
  id: string;
  description: string;
  type: 'primary' | 'secondary' | 'bonus';
  completed: boolean;
  points: number;
}

interface Mission {
  id: string;
  name: string;
  briefing: string;
  landingZone: LandingZone;

  objectives: MissionObjective[];

  // Initial Conditions
  startAltitude: number;
  startVelocity: Vector3;
  startFuel: number;

  // Constraints
  parTime: number;  // Target completion time
  maxTime: number;  // Mission failure time
}
```

**Example Mission**:
```typescript
const mission: Mission = {
  id: 'mission_01',
  name: 'First Landing',
  briefing: 'Land at Mare Tranquillitatis Base Alpha. This is a training mission with forgiving parameters.',
  landingZone: landingZones[0],

  objectives: [
    {
      id: 'obj_land_safely',
      description: 'Land with impact speed < 3.0 m/s',
      type: 'primary',
      completed: false,
      points: 500
    },
    {
      id: 'obj_precision',
      description: 'Land within 100m of target',
      type: 'secondary',
      completed: false,
      points: 200
    },
    {
      id: 'obj_fuel_efficiency',
      description: 'Land with >30% fuel remaining',
      type: 'secondary',
      completed: false,
      points: 200
    },
    {
      id: 'obj_perfect_landing',
      description: 'Land with impact speed < 1.5 m/s',
      type: 'bonus',
      completed: false,
      points: 300
    }
  ],

  startAltitude: 5000,
  startVelocity: { x: 0, y: 0, z: -50 },
  startFuel: 200,
  parTime: 120,
  maxTime: 300
};
```

### 3.4 Procedural Checklists

```typescript
interface ChecklistItem {
  id: string;
  description: string;
  completed: boolean;
  automated?: boolean;  // Can autopilot do it?
  verification: () => boolean;  // Check if completed
}

interface Checklist {
  id: string;
  name: string;
  phase: 'pre-landing' | 'descent' | 'final-approach' | 'post-landing';
  items: ChecklistItem[];
  allCompleted: boolean;
}
```

**Pre-Landing Checklist**:
```typescript
const preLandingChecklist: Checklist = {
  id: 'pre_landing',
  name: 'Pre-Landing Systems Check',
  phase: 'pre-landing',
  items: [
    {
      id: 'reactor_online',
      description: 'Reactor online and stable (>80% output)',
      completed: false,
      verification: () => reactor.status === 'online' && reactor.outputKW > 6.4
    },
    {
      id: 'coolant_active',
      description: 'Both coolant loops active',
      completed: false,
      verification: () => coolant.loops.every(l => l.pumpActive)
    },
    {
      id: 'thermal_nominal',
      description: 'All component temperatures <400K',
      completed: false,
      verification: () => Object.values(thermal.components).every(t => t < 400)
    },
    {
      id: 'main_engine_health',
      description: 'Main engine health >90%',
      completed: false,
      verification: () => mainEngine.health > 90
    },
    {
      id: 'rcs_fuel',
      description: 'RCS fuel >20kg',
      completed: false,
      verification: () => fuel.tanks.rcs.fuelMass > 20
    },
    {
      id: 'battery_charge',
      description: 'Battery charge >50%',
      completed: false,
      verification: () => battery.chargePercent > 50
    },
    {
      id: 'attitude_stable',
      description: 'Attitude within 5° of vertical',
      completed: false,
      verification: () => Math.abs(attitude.pitch) < 5 && Math.abs(attitude.roll) < 5
    }
  ],
  allCompleted: false
};
```

---

## 4. Environmental Physics

### 4.1 Terrain System

```typescript
interface Terrain {
  getElevation(lat: number, lon: number): number;
  getSlope(lat: number, lon: number): number;
  getSurfaceNormal(lat: number, lon: number): Vector3;
  isSafeToLand(lat: number, lon: number): boolean;
  getBoulderDensity(lat: number, lon: number): number;
}

// Simple implementation using noise
class LunarTerrain implements Terrain {
  private noiseGenerator: PerlinNoise;

  getElevation(lat: number, lon: number): number {
    // Crater function
    const crater1 = this.craterElevation(lat, lon, 10, -20, 50, 100);
    const crater2 = this.craterElevation(lat, lon, -15, 30, 30, 50);

    // Noise for roughness
    const roughness = this.noiseGenerator.noise(lat * 10, lon * 10) * 5;

    return crater1 + crater2 + roughness;
  }

  private craterElevation(
    lat: number, lon: number,
    centerLat: number, centerLon: number,
    radius: number, depth: number
  ): number {
    const dist = haversineDistance(lat, lon, centerLat, centerLon);
    if (dist > radius) return 0;

    // Crater profile: raised rim, depressed center
    const normalizedDist = dist / radius;
    if (normalizedDist < 0.8) {
      // Interior depression
      return -depth * (1 - normalizedDist / 0.8);
    } else {
      // Rim elevation
      return depth * 0.5 * (normalizedDist - 0.8) / 0.2;
    }
  }
}
```

### 4.2 Radar Altitude

```typescript
// Difference between orbital altitude and radar altitude
interface AltitudeData {
  orbitalAltitude: number;    // Distance from planet center - radius
  radarAltitude: number;      // Distance to terrain below
  terrainElevation: number;   // Terrain height above reference
}

function calculateAltitudes(
  position: Vector3,
  terrain: Terrain
): AltitudeData {
  const coords = positionToLatLon(position);
  const terrainElevation = terrain.getElevation(coords.lat, coords.lon);
  const orbitalAltitude = magnitude(position) - MOON_RADIUS;
  const radarAltitude = orbitalAltitude - terrainElevation;

  return { orbitalAltitude, radarAltitude, terrainElevation };
}
```

### 4.3 Plume Effects (Future)

```typescript
// Engine exhaust interaction with surface
interface PlumeEffect {
  dustKickup: number;      // Visibility reduction 0-1
  plumeForce: Vector3;     // Force from plume-surface interaction
  thermalEffect: number;   // Heat on surface
}

// Simplified model
function calculatePlumeEffect(
  altitude: number,
  thrust: number,
  surfaceType: string
): PlumeEffect {
  // Only significant below ~100m
  if (altitude > 100) {
    return { dustKickup: 0, plumeForce: {x:0,y:0,z:0}, thermalEffect: 0 };
  }

  const intensity = (100 - altitude) / 100;
  const dustKickup = intensity * 0.8;  // Reduce visibility

  return { dustKickup, plumeForce: {x:0,y:0,z:0}, thermalEffect: 0 };
}
```

---

## 5. System Integration Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Game / UI Layer                      │
│  - Interactive controls                                 │
│  - Display rendering                                    │
│  - Mission management                                   │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────┴───────────────────────────────────────┐
│              Flight Management System                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Autopilot  │  │  Navigation  │  │   Mission    │  │
│  │   - SAS      │  │  - Navball   │  │  - Scoring   │  │
│  │   - PID      │  │  - Predict   │  │  - Zones     │  │
│  │   - Modes    │  │  - Telemetry │  │  - Checks    │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
└─────────┴──────────────────┴──────────────────┴─────────┘
          │                  │                  │
┌─────────┴──────────────────┴──────────────────┴─────────┐
│                 Spacecraft Integration                   │
│  - Coordinates all subsystems                            │
│  - Manages resource flow                                 │
└─────────────────┬────────────────────────────────────────┘
                  │
┌─────────────────┴────────────────────────────────────────┐
│              Core Physics Modules (Existing)             │
│  Fuel | Electrical | Gas | Thermal | Coolant             │
│  Main Engine | RCS | Ship Physics                        │
└──────────────────────────────────────────────────────────┘
```

---

## 6. Testing Strategy

### 6.1 Flight Control Tests

- PID controller step response
- PID controller overshoot < 10%
- SAS stability damping effectiveness
- Attitude hold accuracy (< 1° error)
- Altitude hold stability (< 5m oscillation)
- Suicide burn calculation accuracy
- Hover mode stability

### 6.2 Navigation Tests

- Trajectory prediction accuracy
- Impact point calculation (< 1% error)
- Navball marker positioning
- Velocity decomposition correctness
- Coordinate transformations

### 6.3 Mission Tests

- Landing zone detection
- Score calculation consistency
- Objective completion detection
- Checklist verification logic
- Grade assignment thresholds

---

## 7. Implementation Phases

### Phase 1: Flight Control System ✓ NEXT
- PID controller base class
- SAS controller with damping modes
- Basic autopilot modes (altitude, vertical speed)
- Comprehensive testing (30+ tests)

### Phase 2: Navigation System
- Trajectory predictor
- Suicide burn calculator
- Navball display renderer
- Velocity decomposition
- Enhanced telemetry
- Comprehensive testing (25+ tests)

### Phase 3: Mission System
- Landing zone definitions
- Scoring calculator
- Mission objectives framework
- Checklist system
- Comprehensive testing (20+ tests)

### Phase 4: Integration
- Integrate flight control into spacecraft
- Add navigation displays to game UI
- Implement mission selection and scoring
- Update interactive game with all features
- Integration testing

### Phase 5: Polish (Future)
- Terrain system
- Plume effects
- Advanced lighting
- More landing zones
- Campaign mode

---

## 8. Configuration Files

**Flight Control Config**:
```typescript
export const FLIGHT_CONTROL_CONFIG = {
  pid: {
    altitude: { kp: 0.05, ki: 0.001, kd: 0.2 },
    verticalSpeed: { kp: 0.8, ki: 0.1, kd: 0.15 },
    pitch: { kp: 1.5, ki: 0.05, kd: 0.5 },
    roll: { kp: 1.5, ki: 0.05, kd: 0.5 },
    yaw: { kp: 1.5, ki: 0.05, kd: 0.5 },
    rateDamping: { kp: 2.0, ki: 0.0, kd: 0.3 }
  },
  sas: {
    deadband: 0.5,  // degrees
    rateDeadband: 0.01,  // rad/s
    maxControlAuthority: 1.0  // 0-1
  },
  autopilot: {
    suicideBurnSafetyFactor: 1.15,
    hoverThrottleMargin: 0.05,
    altitudeHoldDeadband: 5.0,  // meters
    speedHoldDeadband: 0.5  // m/s
  }
};
```

---

**End of Design Document**

*This design provides the blueprint for Phase 1-3 implementations. Each system will be built independently with comprehensive tests, following the same pattern as the core physics modules.*
