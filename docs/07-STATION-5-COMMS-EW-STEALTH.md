# Station 5: Communications, Electronic Warfare & Stealth Design (Future)

**Status:** Deferred to post-MVP, placeholder design for future implementation

---

## Overview

Station 5 handles communications, electronic warfare, and stealth operations. This station is about **information control** - gathering intelligence, managing signatures, and controlling what others know about your ship.

---

## Communications System

### Passive Communications
- **Receive distress signals** from other ships
- **Monitor station broadcasts** for news, warnings, hazards
- **Traffic control** communications (docking clearances, route advisories)
- **Automated beacons** (navigation markers, hazard warnings)

### Active Communications
- **Hail other vessels** (derelicts, stations, passing ships)
- **Request assistance** (repair, refuel, escort)
- **Negotiate trades** (resources, information, services)
- **Report discoveries** (anomalies, derelicts, hazards)

### Signal Management
- **Signal strength** - range-limited, degraded by interference
- **Encryption levels** - civilian (open), commercial (basic), military (encrypted)
- **Decryption minigame** - intercept encrypted signals, attempt to decode
- **Directional antenna** - point toward signal source for better reception
- **Multi-channel monitoring** - scan multiple frequencies simultaneously

### Controls (~15)
```
COMMUNICATIONS PANEL
┌─────────────────────────────────┐
│ RECEIVER                        │
│ Frequency: [||||    ] 145.8 MHz│
│ Signal:    [███░░░░░] Weak      │
│ [SCAN] [LOCK] [DECRYPT]         │
│                                 │
│ ACTIVE CHANNELS                 │
│ 1. Distress  145.8 MHz ●        │
│ 2. Traffic   146.2 MHz ●        │
│ 3. Station   147.0 MHz ○        │
│                                 │
│ TRANSMITTER                     │
│ Power: [||||||||] 100W          │
│ [HAIL] [REQUEST] [BROADCAST]    │
│                                 │
│ MESSAGE LOG                     │
│ > "SOS - Hull breach - 15km"   │
│ > "Traffic: Clearance granted" │
│ > "Beacon: Hazard ahead"       │
└─────────────────────────────────┘
```

---

## Electronic Warfare (EW)

### Passive EW - Detection & Analysis
- **ELINT (Electronic Intelligence)** - detect/classify other ships' emissions
- **Signature analysis** - identify ship type by radar/thermal signature
- **Signal triangulation** - locate source of transmissions
- **Threat assessment** - classify detected contacts (civilian/military/hostile)

### Active EW - Countermeasures
- **ECM (Electronic Countermeasures)** - jam enemy sensors/comms
- **Spoofing** - fake transponder codes, false contacts on enemy radar
- **Chaff deployment** - confuse radar-guided threats
- **Flares** - confuse thermal-seeking threats
- **ECCM (Electronic Counter-Countermeasures)** - resist jamming

### Combat Applications (If Combat Added)
- **Missile lock warning** - detect targeting radar
- **Break lock maneuvers** - combination of ECM + evasion
- **Decoys** - deployable false targets
- **EMP hardening** - protect systems from electromagnetic pulse

### Controls (~20)
```
ELECTRONIC WARFARE
┌─────────────────────────────────┐
│ THREAT DISPLAY                  │
│ ┌─────────────┐                 │
│ │    N        │                 │
│ │    ↑        │                 │
│ │             │                 │
│ │  ⚠️  █  🎯   │ ⚠️ = Warning    │
│ │             │ 🎯 = Lock       │
│ │    +        │                 │
│ │  (YOU)      │                 │
│ └─────────────┘                 │
│                                 │
│ CONTACTS                        │
│ 1. Unknown   5km  ⚠️  SCANNING  │
│ 2. Hostile   8km  🎯  LOCKED    │
│                                 │
│ COUNTERMEASURES                 │
│ ECM:   [STANDBY] [ACTIVE]       │
│ Chaff: ████░░░ (4 remaining)    │
│ Flare: ███░░░░ (3 remaining)    │
│ Spoof: [ACTIVATE DECOY]         │
│                                 │
│ WARNINGS                        │
│ ● RADAR LOCK DETECTED           │
│ ○ Jamming Active                │
└─────────────────────────────────┘
```

---

## Stealth & Signature Management

### Thermal Signature
- **Heat emission** - engines, reactor, life support all radiate heat
- **Radiator management** - retract to reduce signature, but overheat faster
- **Cold running mode** - minimal power, no active cooling, silent but risky
- **Heat sinks** - temporary heat storage (limited capacity)

### Radar Signature
- **Cross-section** - ship orientation affects radar return
- **Edge-on minimal** - rotate ship to present smallest profile
- **Broadside maximum** - flat surfaces reflect strongly
- **Stealth coating** - (upgrade) reduces radar signature by 50%
- **Clutter** - hide near asteroids/debris to mask signature

### Electromagnetic Signature
- **Active sensors** - radar/LIDAR emit detectable signals
- **Passive mode** - sensors receive only, no emissions
- **Radio silence** - no transmissions
- **Power emissions** - reactor, electrical systems emit EM noise

### Acoustic Signature (If Applicable)
- **Thruster noise** - vibrations detectable at close range
- **Machinery noise** - reactor, pumps, fans
- **Silent running** - shutdown non-essential systems

### Stealth Modes

**Mode 1: Normal Operations**
- All systems active
- Full sensor suite
- Maximum capability
- High signature (detectable at long range)

**Mode 2: Low Observability**
- Passive sensors only
- Reduced power output
- Radiators retracted
- Medium signature (detectable at medium range)

**Mode 3: Silent Running**
- All active systems off (radar, LIDAR, comms)
- Minimum power (life support only)
- No radiators (heat building up)
- Low signature (detectable only at close range)
- **Time limited** - thermal buildup forces return to normal mode

**Mode 4: Cold & Dark**
- Everything off except emergency battery
- Maximum stealth
- Extremely low signature (nearly undetectable)
- **Very time limited** - crew at risk (no life support), thermal critical
- **Emergency only**

### Controls (~15)
```
STEALTH MANAGEMENT
┌─────────────────────────────────┐
│ SIGNATURE STATUS                │
│                                 │
│ THERMAL:  [████████] HIGH       │
│   Temp: 450K (bright IR)        │
│   Radiators: DEPLOYED           │
│   [RETRACT] for lower sig       │
│                                 │
│ RADAR:    [█████░░░] MEDIUM     │
│   Aspect: Broadside             │
│   [ROTATE EDGE-ON]              │
│                                 │
│ EM:       [███████░] HIGH       │
│   Radar: ACTIVE                 │
│   Comms: TRANSMITTING           │
│   [PASSIVE MODE]                │
│                                 │
│ STEALTH MODES                   │
│ ○ Normal (Current)              │
│ ○ Low Observable                │
│ ○ Silent Running                │
│ ○ Cold & Dark (Emergency)       │
│                                 │
│ DETECTION ESTIMATE              │
│ Enemy can detect you at:        │
│ 12 km (current signature)       │
└─────────────────────────────────┘
```

---

## Gameplay Integration

### Mission Types Using Station 5

**Stealth Missions:**
- Sneak past patrol ships
- Approach undetected for reconnaissance
- Avoid hostile forces while damaged

**ELINT Missions:**
- Intercept enemy communications
- Identify unknown contacts
- Map enemy sensor coverage

**Rescue Missions:**
- Locate distress signals
- Communicate with survivors
- Coordinate multi-ship operations

**Combat Missions** (If Combat Added):
- Electronic warfare support
- Missile defense
- Stealth attack runs

### Skill Progression

**Novice:**
- Uses normal operations mode
- Reacts to threats after detected
- Basic communications

**Intermediate:**
- Switches to low-observable proactively
- Monitors threat signatures
- Decrypts some signals

**Expert:**
- Silent running timing mastery
- Predictive threat avoidance
- Full EW suite utilization
- Edge-on maneuvering while navigating

---

## System Interconnections

### With Engineering:
- **Power budget** - active sensors draw power
- **Thermal** - stealth requires heat management
- **Reactor throttle** - lower output = lower EM signature

### With Navigation:
- **Passive sensors** - limited range/accuracy
- **Threat avoidance** - plot courses avoiding detection
- **Sensor fusion** - combine comms intel with sensor data

### With Helm:
- **Orientation control** - edge-on for stealth
- **Thruster management** - minimize signature during burns
- **Evasive maneuvers** - break sensor locks

---

## Technical Implementation Notes

### Detection Model
```typescript
interface SignatureModel {
  thermal: number;      // 0-100 (Kelvin-based)
  radar: number;        // 0-100 (cross-section m²)
  electromagnetic: number; // 0-100 (emissions W)
}

function calculateDetectionRange(
  shipSignature: SignatureModel,
  sensorSensitivity: number,
  range: number
): boolean {
  // Simplified inverse-square law
  const signalStrength = shipSignature.total / (range * range);
  return signalStrength > sensorSensitivity;
}
```

### Stealth Mechanics
- **Heat buildup** during silent running (thermal.ts)
- **Detection probability** vs range (sensors.ts)
- **Signature calculation** based on active systems (new: signature.ts)

---

## Balance Considerations

### Stealth Shouldn't Be:
- **Always optimal** - should have trade-offs
- **Perfect invisibility** - always some risk of detection
- **Boring** - tension from heat buildup, time limits

### Stealth Should Be:
- **Skill-based** - timing, planning, execution
- **Risky** - thermal danger, limited sensors, vulnerability
- **Rewarding** - avoid fights, save fuel, complete objectives

### Detection Ranges (Example)
```
Signature Level → Detection Range
High (normal):    20 km
Medium (low-obs): 8 km
Low (silent):     3 km
Minimal (cold):   0.5 km (visual range only)
```

---

## Future Expansion Ideas

### Advanced Features (Post-Post-MVP)
- **Quantum encryption** - unbreakable comms (expensive)
- **AI decryption** - automated signal analysis
- **Drone deployment** - remote sensors, decoys
- **Network warfare** - hack enemy systems
- **Multi-ship coordination** - fleet-level EW

### Story Integration
- **Factions** - different communication protocols
- **Reputation** - monitoring your transmissions
- **Black market** - illegal encryption keys
- **Spy missions** - intelligence gathering contracts

---

## MVP vs Full Version

### Not in MVP:
- No Station 5 at all
- No stealth mechanics
- No electronic warfare
- Basic comms only (receiving distress/station broadcasts)

### Phase 1 Addition (Week 13-14):
- Basic comms panel (receive/transmit)
- Passive detection (see what sensors detect you)
- Manual signature management (radiators, power, orientation)

### Phase 2 Addition (Week 15-16):
- Stealth modes (silent running, cold & dark)
- Basic ECM/ECCM
- Decryption minigames

### Full Version (Week 17+):
- Complete EW suite
- Combat integration
- Mission-specific uses
- Advanced features

---

**Implementation Priority:** LOW (post-MVP)

**Design Status:** PRELIMINARY - needs playtesting and iteration

**Dependencies:**
- Core systems working
- Sensors functional
- Thermal system complete
- Combat system (if applicable)
