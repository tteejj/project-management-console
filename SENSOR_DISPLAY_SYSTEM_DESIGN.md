# Sensor & Display System Design (No Camera/Rendering)

## Core Philosophy

**Submarine Simulator in Space:**
- You NEVER see the outside world directly
- All information comes through instruments and sensors
- Navigation is entirely by instruments (like flying IFR)
- The world exists in physics, but you only see processed data

**Like:**
- Submarine sonar operator (ping returns, not visuals)
- Apollo spacecraft (instruments only, no windows for navigation)
- Commercial aircraft IFR (instruments, not visual references)
- Blind navigation by instruments alone

---

## Sensor Architecture

### Sensor Types

```typescript
interface Sensor {
  id: string;
  name: string;
  type: SensorType;

  // Power & Status
  powerDraw: number;           // Watts
  operational: boolean;        // Powered and functional
  damaged: boolean;

  // Capabilities
  maxRange: number;            // m
  accuracy: number;            // 0-1 (1 = perfect)
  updateRate: number;          // Hz

  // Active vs Passive
  mode: 'passive' | 'active';

  // Sensor signature (for stealth)
  emissionStrength?: number;   // Watts (if active)
}

enum SensorType {
  RADAR,              // Active - emits radio waves
  LIDAR,              // Active - emits laser pulses
  THERMAL_IR,         // Passive - detects heat
  MASS_DETECTOR,      // Passive - detects gravity
  RADIO_RECEIVER,     // Passive - listens for emissions
  OPTICAL,            // Passive - visible light (very limited)
  DOPPLER,            // Active/Passive - velocity measurement
  MAGNETOMETER        // Passive - detects magnetic fields
}
```

---

## Sensor Systems

### 1. Radar System

**Purpose:** Primary sensor for detecting objects, measuring range/bearing

**Technology:** Active electromagnetic (radio waves)

```typescript
interface RadarSystem extends Sensor {
  type: SensorType.RADAR;
  mode: 'active';  // Emits detectable signals

  // Radar parameters
  frequency: number;           // GHz (higher = better resolution, shorter range)
  beamWidth: number;           // degrees (narrower = better accuracy)
  scanRate: number;            // rpm (how fast it scans)

  // Detection
  minDetectableRCS: number;    // m² (radar cross-section)

  // Modes
  scanMode: 'continuous' | 'sweep' | 'track';
}

interface RadarContact {
  id: string;

  // Measurements (with noise)
  range: number;               // m (± accuracy)
  bearing: number;             // degrees (± accuracy)
  elevation: number;           // degrees (± accuracy)

  // Derived
  relativeVelocity?: number;   // m/s (Doppler shift)
  rcs: number;                 // m² (radar cross-section)

  // Tracking
  firstDetected: number;       // timestamp
  lastDetected: number;
  confidence: number;          // 0-1 (how sure we are it's real)

  // Classification (if enough data)
  classification?: 'planet' | 'station' | 'asteroid' | 'ship' | 'debris' | 'unknown';
  size?: 'small' | 'medium' | 'large';
}

class RadarSystem {
  scan(world: World, shipPosition: Vector3, shipVelocity: Vector3): RadarContact[] {
    const contacts: RadarContact[] = [];

    // Query world for bodies in range
    const nearbyBodies = world.getBodiesInRange(shipPosition, this.maxRange);

    for (const body of nearbyBodies) {
      // Can we detect it?
      const rcs = body.radarCrossSection;
      if (rcs < this.minDetectableRCS) continue; // Too small

      // Calculate range
      const relativePos = subtract(body.position, shipPosition);
      const range = magnitude(relativePos);

      // Add sensor noise
      const rangeError = (1 - this.accuracy) * range * 0.05;
      const measuredRange = range + (Math.random() - 0.5) * rangeError;

      // Calculate bearing (horizontal angle)
      const bearing = Math.atan2(relativePos.y, relativePos.x) * RAD_TO_DEG;
      const bearingError = (1 - this.accuracy) * this.beamWidth * 0.5;
      const measuredBearing = bearing + (Math.random() - 0.5) * bearingError;

      // Calculate elevation (vertical angle)
      const elevation = Math.atan2(relativePos.z,
        Math.sqrt(relativePos.x ** 2 + relativePos.y ** 2)) * RAD_TO_DEG;
      const measuredElevation = elevation + (Math.random() - 0.5) * bearingError;

      // Doppler velocity (if moving)
      const relativeVel = subtract(body.velocity, shipVelocity);
      const dopplerVelocity = dot(normalize(relativePos), relativeVel);

      // Classify if we have enough data
      const classification = this.classifyContact(rcs, range, body);

      contacts.push({
        id: body.id,
        range: measuredRange,
        bearing: measuredBearing,
        elevation: measuredElevation,
        relativeVelocity: dopplerVelocity,
        rcs: rcs,
        firstDetected: Date.now(),
        lastDetected: Date.now(),
        confidence: this.calculateConfidence(range, rcs),
        classification,
        size: this.estimateSize(rcs)
      });
    }

    return contacts;
  }

  private classifyContact(rcs: number, range: number, body: CelestialBody): string {
    // Large RCS + stationary = likely station or planet
    if (rcs > 1000 && body.velocity.magnitude() < 10) {
      return body.radius > 100000 ? 'planet' : 'station';
    }

    // Small RCS + moving = likely asteroid or debris
    if (rcs < 10 && body.velocity.magnitude() > 50) {
      return body.radius < 10 ? 'debris' : 'asteroid';
    }

    // Medium RCS + moving = likely ship
    if (rcs > 10 && rcs < 100 && body.velocity.magnitude() > 10) {
      return 'ship';
    }

    return 'unknown';
  }
}
```

---

### 2. Thermal/IR Sensor

**Purpose:** Passive detection of heat signatures

**Technology:** Infrared camera detecting thermal radiation

```typescript
interface ThermalSensor extends Sensor {
  type: SensorType.THERMAL_IR;
  mode: 'passive';  // No emissions

  // Thermal parameters
  sensitivity: number;         // Minimum detectable temperature delta (K)
  wavelengthRange: [number, number]; // μm (infrared bands)

  // Field of view
  fov: number;                 // degrees
}

interface ThermalContact {
  id: string;

  // Thermal signature
  temperature: number;         // K (estimated)
  brightness: number;          // Relative brightness (0-100)

  // Position (less precise than radar)
  bearing: number;             // degrees
  elevation: number;           // degrees
  angularSize?: number;        // degrees (if resolved)

  // Type hints
  signature: 'hot_engine' | 'warm_hull' | 'cold_object' | 'star';
}

class ThermalSensor {
  scan(world: World, shipPosition: Vector3): ThermalContact[] {
    const contacts: ThermalContact[] = [];

    for (const body of world.bodies.values()) {
      // Can we see it thermally?
      if (body.thermalSignature < this.sensitivity) continue;

      const relativePos = subtract(body.position, shipPosition);
      const range = magnitude(relativePos);

      // Thermal radiation falls off with inverse square
      const apparentBrightness = body.thermalSignature / (range * range);

      if (apparentBrightness < this.sensitivity) continue;

      // Calculate bearing (thermal sensors don't give range!)
      const bearing = Math.atan2(relativePos.y, relativePos.x) * RAD_TO_DEG;
      const elevation = Math.atan2(relativePos.z,
        Math.sqrt(relativePos.x ** 2 + relativePos.y ** 2)) * RAD_TO_DEG;

      // Angular size (if close enough to resolve)
      const angularSize = (body.radius / range) * RAD_TO_DEG;

      contacts.push({
        id: body.id,
        temperature: this.estimateTemperature(body.thermalSignature),
        brightness: apparentBrightness * 100,
        bearing,
        elevation,
        angularSize: angularSize > 0.01 ? angularSize : undefined,
        signature: this.classifyThermalSignature(body.thermalSignature)
      });
    }

    return contacts;
  }

  private classifyThermalSignature(signature: number): string {
    if (signature > 2000) return 'hot_engine';    // Active engines
    if (signature > 500) return 'warm_hull';      // Warm spacecraft
    if (signature > 100) return 'cold_object';    // Asteroid, station
    return 'star';                                 // Background stars
  }
}
```

---

### 3. LIDAR (Laser Ranging)

**Purpose:** High-precision range and velocity measurement

**Technology:** Active laser pulses, time-of-flight measurement

```typescript
interface LIDARSystem extends Sensor {
  type: SensorType.LIDAR;
  mode: 'active';  // Emits detectable laser

  // LIDAR parameters
  wavelength: number;          // nm (laser wavelength)
  pulseRate: number;           // Hz
  rangePrecision: number;      // m (accuracy)

  // Targeting
  pointingAccuracy: number;    // degrees
}

interface LIDARMeasurement {
  targetId: string;

  // High-precision measurements
  range: number;               // m (very accurate)
  rangeRate: number;           // m/s (closing velocity)

  // Surface properties (if close enough)
  surfaceReflectivity?: number; // 0-1
  rotation?: number;            // rad/s (detected from surface motion)
}

class LIDARSystem {
  // LIDAR requires a target (can't scan like radar)
  measureTarget(
    world: World,
    shipPosition: Vector3,
    shipVelocity: Vector3,
    targetId: string
  ): LIDARMeasurement | null {
    const target = world.bodies.get(targetId);
    if (!target) return null;

    const relativePos = subtract(target.position, shipPosition);
    const range = magnitude(relativePos);

    if (range > this.maxRange) return null;

    // LIDAR is very precise
    const rangeError = this.rangePrecision;
    const measuredRange = range + (Math.random() - 0.5) * rangeError;

    // Doppler shift from laser gives velocity
    const relativeVel = subtract(target.velocity, shipVelocity);
    const rangeRate = dot(normalize(relativePos), relativeVel);

    return {
      targetId: target.id,
      range: measuredRange,
      rangeRate,
      surfaceReflectivity: this.measureReflectivity(target),
      rotation: target.angularVelocity?.magnitude()
    };
  }
}
```

---

### 4. Mass Detector (Gravimetric Sensor)

**Purpose:** Passive detection via gravitational field

**Technology:** Sensitive accelerometer detecting gravity gradients

```typescript
interface MassDetector extends Sensor {
  type: SensorType.MASS_DETECTOR;
  mode: 'passive';

  // Sensitivity
  minDetectableMass: number;   // kg
  minDetectableAccel: number;  // m/s² (gravitational)
}

interface GravimetricContact {
  direction: Vector3;          // Direction to mass
  estimatedMass: number;       // kg (rough estimate)
  estimatedRange: number;      // m (very rough)

  // Mass detectors give direction and strength, not precise location
  confidence: number;          // 0-1
}

class MassDetector {
  scan(world: World, shipPosition: Vector3): GravimetricContact[] {
    const contacts: GravimetricContact[] = [];

    for (const body of world.bodies.values()) {
      if (body.mass < this.minDetectableMass) continue;

      const relativePos = subtract(body.position, shipPosition);
      const range = magnitude(relativePos);

      // Calculate gravitational acceleration
      const g = G * body.mass / (range * range);

      if (g < this.minDetectableAccel) continue;

      // Mass detector gives direction and strength, range is estimated
      const direction = normalize(relativePos);
      const estimatedRange = Math.sqrt(G * body.mass / g);

      contacts.push({
        direction,
        estimatedMass: body.mass,
        estimatedRange,
        confidence: Math.min(1, g / this.minDetectableAccel)
      });
    }

    return contacts;
  }
}
```

---

## Display Formats

### Tactical Display (Radar Plot)

**No visual world - only processed sensor data**

```
TACTICAL RADAR DISPLAY
┌─────────────────────────────────┐
│         N (000°)                │
│          ↑                      │
│          │                      │
│     ·    │    ●                 │  · = Debris (1.2km)
│          │         ○            │  ● = Station (8.5km)
│          │                      │  ○ = Unknown (15km)
│  ────────+────────              │  ⊕ = YOU
│  W       ⊕       E              │  △ = Asteroid (3km)
│          │                      │
│      △   │                      │
│          │                      │
│          ↓                      │
│         S (180°)                │
│                                 │
│ RANGE: 20km  GAIN: 75%          │
│ CONTACTS: 4  MODE: SWEEP        │
│                                 │
│ SELECTED: Station Alpha         │
│   Range:   8,542 m              │
│   Bearing: 045° (NE)            │
│   Elev:    +2°                  │
│   Closing: 12 m/s               │
│   RCS:     285 m²               │
│   Class:   STATION (95%)        │
│                                 │
│ [1-4 Select] [R Range] [M Mode] │
└─────────────────────────────────┘
```

**NOT a camera view - this is processed radar returns displayed as symbols**

---

### Thermal Display

```
THERMAL SENSOR
┌─────────────────────────────────┐
│ MODE: Passive IR  GAIN: [||||  ]│
│                                 │
│ HEAT SIGNATURES                 │
│                                 │
│ 1. BRIGHT (295°)  045° +2°      │
│    ████████████ 🔥🔥🔥           │
│    "Station Alpha - warm hull"  │
│                                 │
│ 2. HOT (850°)     270° -15°     │
│    ████████████████████ 🔥🔥🔥🔥 │
│    "Unknown - active engines!"  │
│                                 │
│ 3. FAINT (120°)   180° 0°       │
│    ███░░░░░░░░░                 │
│    "Asteroid - cold"            │
│                                 │
│ 4. BACKGROUND     Various       │
│    ░░░ (Stars)                  │
│                                 │
│ SENSITIVITY: [|||||||||] MAX    │
│ WAVELENGTH: 8-12 μm (thermal)   │
│                                 │
│ NOTE: No range data from IR!    │
│ Cross-reference with radar.     │
└─────────────────────────────────┘
```

---

### LIDAR Rangefinder

```
LIDAR TARGETING
┌─────────────────────────────────┐
│ TARGET: Station Alpha (locked)  │
│                                 │
│ RANGE MEASUREMENT               │
│ ┌─────────────────────┐         │
│ │  8,542.3 m          │ [████]  │
│ │  ± 0.2 m            │ SIGNAL  │
│ └─────────────────────┘         │
│                                 │
│ VELOCITY                        │
│ ┌─────────────────────┐         │
│ │  -12.4 m/s          │ CLOSING │
│ │  (approaching)      │         │
│ └─────────────────────┘         │
│                                 │
│ TIME TO CONTACT                 │
│ ┌─────────────────────┐         │
│ │  11 min 29 sec      │         │
│ └─────────────────────┘         │
│                                 │
│ SURFACE REFLECTIVITY: 0.45      │
│ ROTATION RATE: 0.02 rad/s       │
│                                 │
│ [SELECT NEW TARGET]             │
│ [ENABLE TRACKING]               │
└─────────────────────────────────┘
```

---

### Navigation Computer

**Combines all sensor data into navigation solution**

```
NAVIGATION COMPUTER
┌─────────────────────────────────┐
│ POSITION (Moon-Centric)         │
│   X:  +125,432 m                │
│   Y:   -45,123 m                │
│   Z:  +234,567 m                │
│   Alt: 15,234 m ASL             │
│                                 │
│ VELOCITY                        │
│   Vx:  +12.5 m/s                │
│   Vy:   -3.2 m/s                │
│   Vz:  +45.8 m/s                │
│   |V|:  48.3 m/s                │
│                                 │
│ VELOCITY VECTORS                │
│   Vertical:   -8.2 m/s ↓        │
│   Horizontal: +47.6 m/s →       │
│   Prograde:   +48.3 m/s         │
│   Normal:     +2.1 m/s          │
│                                 │
│ TRAJECTORY PREDICTION           │
│   Impact Time: 5 min 23 sec     │
│   Impact Pos:  15.2°N 45.8°E    │
│   Impact Speed: 142 m/s 🔴      │
│   Suicide Burn: 45 sec          │
│                                 │
│ FLIGHT DATA                     │
│   Heading: 045° (NE)            │
│   Pitch: -12° (nose down)       │
│   Roll: +5° (right bank)        │
│   TWR: 1.85                     │
│                                 │
│ [PLOT INTERCEPT] [SUICIDE BURN] │
└─────────────────────────────────┘
```

---

### Contact List (Sensor Fusion)

**Combines radar, thermal, LIDAR, mass detector data**

```
CONTACT MANAGER
┌─────────────────────────────────┐
│ TRACKED OBJECTS (12)            │
│                                 │
│ 1. STATION ALPHA         [SEL]  │
│    Range: 8,542m  Brg: 045°     │
│    Radar: ●  Thermal: 🔥🔥       │
│    LIDAR: LOCKED                │
│    Class: Station (95% conf)    │
│    Status: Friendly             │
│                                 │
│ 2. UNKNOWN CONTACT       [ ? ]  │
│    Range: 15,234m  Brg: 090°    │
│    Radar: ○  Thermal: 🔥🔥🔥🔥    │
│    LIDAR: ---                   │
│    Class: Unknown (hot engines) │
│    Status: CAUTION ⚠            │
│                                 │
│ 3. ASTEROID FIELD        [...]  │
│    Range: 3,200m  Brg: 180°     │
│    Radar: △△△  Thermal: ░       │
│    Mass: Detected               │
│    Class: Asteroids (80%)       │
│    Status: HAZARD ⚠             │
│                                 │
│ 4. DEBRIS                [...]  │
│    Range: 1,200m  Brg: 270°     │
│    Radar: ·  Thermal: ---       │
│    Class: Debris/small          │
│    Status: COLLISION RISK 🔴    │
│                                 │
│ [SELECT] [TRACK] [TARGET]       │
│ [FILTER BY TYPE/RANGE]          │
└─────────────────────────────────┘
```

---

### Damage Control Board

**Hull integrity data from internal sensors**

```
DAMAGE CONTROL
┌─────────────────────────────────┐
│ HULL INTEGRITY: [██████░░░░] 65%│
│                                 │
│ COMPARTMENT STATUS              │
│                                 │
│ [BOW]                           │
│ ├─ Integrity: 52% ⚠             │
│ ├─ Breach: 1 minor (0.08m)      │
│ ├─ Venting: SEALED              │
│ └─ Systems: Radar DAMAGED       │
│                                 │
│ [COCKPIT] ✓                     │
│ └─ Integrity: 100%              │
│                                 │
│ [ENGINEERING]                   │
│ ├─ Integrity: 78%               │
│ └─ Deformation: 15%             │
│                                 │
│ [FUEL TANKS] 🔴                 │
│ ├─ Integrity: 70% ⚠             │
│ ├─ Breach: 1 major (0.4m)       │
│ ├─ VENTING: 2.5 kg/s            │
│ └─ Fuel leak: ACTIVE            │
│                                 │
│ [ENGINE BAY] ✓                  │
│ └─ Integrity: 100%              │
│                                 │
│ ACTIONS:                        │
│ [SEAL BREACH] [EMERGENCY PATCH] │
│ [VENT COMPARTMENT] [REINFORCE]  │
└─────────────────────────────────┘
```

---

## Sensor Integration Architecture

### Data Flow

```
World (Physics)
    ↓
Sensor Query (active scan or passive listen)
    ↓
Sensor Processing (apply accuracy, noise, range limits)
    ↓
Contact List (tracked objects with fused data)
    ↓
Display Renderer (ASCII/vector graphics)
    ↓
Screen (player sees only this)
```

### TypeScript Implementation

```typescript
class SensorManager {
  sensors: Map<string, Sensor> = new Map();
  contacts: Map<string, Contact> = new Map();

  // Main update loop
  update(dt: number, world: World, shipState: ShipState): void {
    // 1. Update each sensor
    for (const sensor of this.sensors.values()) {
      if (!sensor.operational) continue;

      // Scan based on sensor type
      switch (sensor.type) {
        case SensorType.RADAR:
          const radarContacts = (sensor as RadarSystem).scan(
            world,
            shipState.position,
            shipState.velocity
          );
          this.fuseSensorData('radar', radarContacts);
          break;

        case SensorType.THERMAL_IR:
          const thermalContacts = (sensor as ThermalSensor).scan(
            world,
            shipState.position
          );
          this.fuseSensorData('thermal', thermalContacts);
          break;

        case SensorType.LIDAR:
          // LIDAR requires target selection
          if (this.selectedTarget) {
            const lidarData = (sensor as LIDARSystem).measureTarget(
              world,
              shipState.position,
              shipState.velocity,
              this.selectedTarget
            );
            this.fuseSensorData('lidar', [lidarData]);
          }
          break;

        case SensorType.MASS_DETECTOR:
          const gravContacts = (sensor as MassDetector).scan(
            world,
            shipState.position
          );
          this.fuseSensorData('mass', gravContacts);
          break;
      }
    }

    // 2. Update contact tracking
    this.updateContactTracking(dt);

    // 3. Classify contacts
    this.classifyContacts();

    // 4. Generate warnings
    this.checkForThreats(shipState);
  }

  // Combine data from multiple sensors
  private fuseSensorData(sensorType: string, data: any[]): void {
    for (const measurement of data) {
      const contactId = measurement.id || measurement.targetId;

      if (!this.contacts.has(contactId)) {
        // New contact
        this.contacts.set(contactId, {
          id: contactId,
          firstDetected: Date.now(),
          sensorData: {}
        });
      }

      const contact = this.contacts.get(contactId)!;

      // Update sensor-specific data
      contact.sensorData[sensorType] = measurement;
      contact.lastUpdate = Date.now();
    }
  }

  // Calculate best estimate of contact position/velocity
  private fuseContactPosition(contact: Contact): {
    position: Vector3;
    velocity: Vector3;
    confidence: number;
  } {
    // Radar gives best bearing/range
    const radarData = contact.sensorData.radar;

    // LIDAR gives best range
    const lidarData = contact.sensorData.lidar;

    // Thermal gives bearing only
    const thermalData = contact.sensorData.thermal;

    // Combine based on availability and accuracy
    const range = lidarData?.range || radarData?.range || 0;
    const bearing = radarData?.bearing || thermalData?.bearing || 0;
    const elevation = radarData?.elevation || thermalData?.elevation || 0;

    // Convert spherical to Cartesian
    const position = sphericalToCartesian(range, bearing, elevation);

    // Velocity from LIDAR or radar Doppler
    const velocity = lidarData?.rangeRate || radarData?.relativeVelocity || 0;

    return {
      position,
      velocity: { x: 0, y: 0, z: velocity }, // Simplified
      confidence: this.calculateConfidence(contact)
    };
  }
}
```

---

## Sensor Limitations & Gameplay

### Sensor Trade-offs

| Sensor | Pros | Cons |
|--------|------|------|
| **Radar** | Wide area scan, range+bearing | Active (detectable), lower accuracy |
| **Thermal** | Passive (stealthy), detects heat | No range data, limited by signature |
| **LIDAR** | Very precise range | Requires target lock, active, narrow beam |
| **Mass Detector** | Always on, can't be jammed | Very rough estimates, close range only |

### Gameplay Integration

**Scenario 1: Approaching Station**
- Radar detects station at 20km (bearing, rough range)
- Thermal sees warm hull signature (confirms contact)
- Select station as target
- LIDAR locks on, gives precise range for docking
- Navigation computer calculates intercept burn

**Scenario 2: Asteroid Field**
- Radar shows many small contacts ahead
- Thermal shows cold signatures (asteroids)
- Mass detector confirms gravitational field
- Cannot LIDAR all of them (too many)
- Must navigate by radar alone

**Scenario 3: Stealth Approach**
- Turn off radar (no emissions)
- Rely on passive thermal sensor
- Can see others, they can't see you (easily)
- Limited information (no range from thermal)
- Must cross-reference with mass detector

**Scenario 4: Unknown Contact**
- Radar detects object at 15km
- Thermal shows HOT signature (active engines)
- Not in database - unknown ship
- LIDAR lock to get precise range/velocity
- Classify as potential threat

---

## Display Panel Layouts

### Station 3: Navigation & Sensors

```
NAVIGATION PANEL
┌─────────────────────────────────────────────┐
│ TACTICAL RADAR          │ CONTACT LIST      │
│ ┌─────────────────────┐ │ 1. Station Alpha  │
│ │       N             │ │    8.5km  045°    │
│ │       ↑             │ │ 2. Unknown        │
│ │   ·   │   ●         │ │    15km   090° ⚠  │
│ │       │        ○    │ │ 3. Asteroid       │
│ │ ──────+──────       │ │    3km    180°    │
│ │ W     ⊕     E       │ │ 4. Debris         │
│ │       │             │ │    1.2km  270° 🔴 │
│ │   △   │             │ └───────────────────┘
│ │       S             │                     │
│ └─────────────────────┘ │ THERMAL SENSOR    │
│ Range: 20km  Gain: 75%  │ 1. 🔥🔥 045° Warm  │
│ Contacts: 4  SWEEP      │ 2. 🔥🔥🔥🔥 270° Hot│
│                         │ 3. ░ 180° Cold    │
├─────────────────────────┴───────────────────┤
│ NAVIGATION COMPUTER                         │
│ Position: X+125,432 Y-45,123 Z+234,567      │
│ Velocity: |V|=48.3m/s  Heading 045°         │
│ Altitude: 15,234m  Vertical: -8.2m/s ↓      │
│                                             │
│ TRAJECTORY: Impact 5:23  Speed 142m/s 🔴    │
│ Suicide Burn Start: 45 seconds              │
│                                             │
│ [PLOT INTERCEPT] [SUICIDE BURN] [HOLD ALT]  │
└─────────────────────────────────────────────┘
```

---

## Technical Requirements

### Sensor Query Interface

```typescript
interface WorldQueryResult {
  bodies: CelestialBody[];
  range: number;
  queryTime: number; // For performance tracking
}

class World {
  // Efficient spatial queries for sensors
  getBodiesInRange(
    position: Vector3,
    range: number,
    filter?: (body: CelestialBody) => boolean
  ): CelestialBody[] {
    // Use spatial partitioning (octree/quadtree)
    // Return only bodies within sensor range
    // Apply optional filter
  }

  // Raycast for LIDAR
  raycast(
    origin: Vector3,
    direction: Vector3,
    maxRange: number
  ): { body: CelestialBody; distance: number } | null {
    // Find first body intersected by ray
  }
}
```

### Power Management

```typescript
// All sensors consume power
class ElectricalSystem {
  registerSensor(sensor: Sensor): void {
    this.powerConsumers.set(sensor.id, sensor.powerDraw);
  }

  update(dt: number): void {
    // If power insufficient, disable sensors
    if (this.availablePower < this.totalDraw) {
      this.brownout(); // Disable non-critical sensors
    }
  }
}
```

### Update Rate Optimization

```typescript
// Not all sensors need to update every frame
class SensorManager {
  private updateCounters: Map<string, number> = new Map();

  update(dt: number, world: World, ship: ShipState): void {
    for (const [id, sensor] of this.sensors) {
      // Update at sensor-specific rate
      const updateInterval = 1 / sensor.updateRate; // seconds

      this.updateCounters.set(id,
        (this.updateCounters.get(id) || 0) + dt);

      if (this.updateCounters.get(id)! >= updateInterval) {
        this.updateSensor(sensor, world, ship);
        this.updateCounters.set(id, 0);
      }
    }
  }
}
```

---

## Summary

**Sensor-Based Navigation (No Camera):**
- All information from sensors (radar, thermal, LIDAR, mass detector)
- Each sensor has strengths and weaknesses
- Player must combine sensor data for complete picture
- Displays show processed data (not visual world)

**Display Types:**
- Tactical radar plot (top-down symbol map)
- Thermal signature list (heat sources)
- LIDAR rangefinder (precise measurements)
- Navigation computer (position, velocity, trajectory)
- Contact manager (sensor fusion)
- Damage control board (internal sensors)

**Like Submarine Navigation:**
- Sonar operator sees pings, not visuals
- Navigation by instruments only
- Must interpret sensor data
- Multiple sensors provide different information
- Skill = understanding what sensors tell you

**Integration:**
- World exists in physics
- Sensors query world for detectable objects
- Sensor processing adds noise, limits, accuracy
- Display renders processed data only
- Player never sees "ground truth"

**Next:** Collision detection system design.
