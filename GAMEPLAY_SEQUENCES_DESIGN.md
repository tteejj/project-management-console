# Gameplay Sequences & Flow Design

## Overview

This document defines the complete gameplay flow from mission start to completion, including all sequences, procedures, and state transitions.

---

## Game State Machine

```
┌─────────────┐
│ MAIN MENU   │
└──────┬──────┘
       │ [Start Campaign / Continue]
       ↓
┌──────────────┐
│ SHIP SELECT  │ (Post-MVP: unlock different ships)
└──────┬───────┘
       │ [Confirm]
       ↓
┌───────────────┐
│ SECTOR MAP    │ ←──────────────┐
│ (Campaign)    │                 │
└──────┬────────┘                 │
       │ [Select Node]            │
       ↓                          │
┌────────────────┐                │
│ MISSION BRIEF  │                │
│ (Event Intro)  │                │
└──────┬─────────┘                │
       │ [Begin]                  │
       ↓                          │
┌────────────────┐                │
│ COLD START     │                │
│ (Startup Seq)  │                │
└──────┬─────────┘                │
       │ [Systems Online]         │
       ↓                          │
┌────────────────┐                │
│ PRE-FLIGHT     │                │
│ (Checks)       │                │
└──────┬─────────┘                │
       │ [Ready for Departure]    │
       ↓                          │
┌────────────────┐                │
│ DEPARTURE      │                │
│ (Undock/Burn)  │                │
└──────┬─────────┘                │
       │ [En Route]               │
       ↓                          │
┌────────────────┐                │
│ NAVIGATION     │ ←──────┐       │
│ (Transit)      │        │       │
└──────┬─────────┘        │       │
       │                  │       │
       ├──→ [EVENT] ──────┤       │
       │    (Random/      │       │
       │     Scripted)    │       │
       │                  │       │
       │ [Approach Target]│       │
       ↓                  │       │
┌────────────────┐        │       │
│ ARRIVAL        │        │       │
│ (Approach)     │        │       │
└──────┬─────────┘        │       │
       │ [Match Velocity] │       │
       ↓                  │       │
┌────────────────┐        │       │
│ DOCKING        │        │       │
│ (Final Approach)│       │       │
└──────┬─────────┘        │       │
       │ [Success/Fail]   │       │
       ↓                  │       │
┌────────────────┐        │       │
│ POST-MISSION   │        │       │
│ (Results)      │        │       │
└──────┬─────────┘        │       │
       │                  │       │
       │ [Continue] ──────┼───────┘
       │                  │
       │ [Mission Failed] │
       ↓                  │
┌────────────────┐        │
│ GAME OVER      │        │
└────────────────┘        │
                          │
[Victory Condition Met]   │
       ↓                  │
┌────────────────┐        │
│ CAMPAIGN WIN   │        │
└────────────────┘        │
```

---

## Sequence 1: Cold Start (Startup Sequence)

**Context:** Ship is powered down at a station or in safe space. Player must bring all systems online.

### Startup Procedure (Checklist Style)

#### Phase 1: Emergency Battery
```
State: All systems OFFLINE, emergency battery only
Display: Emergency lighting only (red monochrome mode)
Controls: Limited to Engineering panel
```

**Step 1.1:** Switch to Engineering Panel (forced)
- UI shows: "EMERGENCY POWER - BATTERY ONLY"
- Battery indicator: Shows remaining charge (limited time)

**Step 1.2:** Initiate Reactor Startup
- Action: Press `R` (Start Reactor)
- Feedback: "REACTOR STARTUP INITIATED"
- Timer: 10 second startup sequence
- Animation: Reactor temperature rises slowly
- Sound: (Future) Low hum building

**Step 1.3:** Monitor Reactor Startup
- Display shows:
  ```
  REACTOR STATUS
  ┌─────────────────────┐
  │ STARTUP: [███░░░░░] │
  │ TIME:    8s         │
  │ TEMP:    350K       │
  │ OUTPUT:  0.0kW      │
  └─────────────────────┘
  ```
- Player waits (can abort with `T` for SCRAM)

**Step 1.4:** Reactor Online
- At 10s: "REACTOR ONLINE"
- Output: Ramps to 30% automatically
- Display: Green indicators
- Power available: 1.5kW

#### Phase 2: Primary Systems

**Step 2.1:** Enable Essential Breakers
- UI highlights breakers to enable:
  ```
  CIRCUIT BREAKERS
  [1] Life Support   ○ OFF  → Press 1
  [2] Propulsion     ○ OFF  → Press 2
  [3] Nav Computer   ○ OFF  → Press 3
  [4] Sensors        ○ OFF  → Press 4
  ```

**Step 2.2:** Increase Reactor Output
- Action: Press `I` to increase throttle
- Target: 75% (3.75kW)
- Monitor: Battery starts charging

**Step 2.3:** Enable Secondary Systems
- Enable remaining breakers:
  ```
  [5] Doors          ○ OFF  → Press 5
  [6] Lights         ○ OFF  → Press 6
  [7] Comms          ○ OFF  → (Optional)
  [8] Coolant Pump   ○ OFF  → Press 8 (Important!)
  [9] Radiators      ○ OFF  → Press 9
  ```

**Step 2.4:** Deploy Radiators
- Action: Press `G` (Deploy Radiators)
- Feedback: "RADIATORS DEPLOYING"
- Animation: Radiator deploy progress
- Result: Thermal management active

#### Phase 3: Propulsion Systems

**Step 3.1:** Switch to Helm Panel
- Press `1` to switch stations
- Display: Helm controls now active

**Step 3.2:** Open Fuel Valve
- Action: Press `F` (Open Fuel Valve)
- Display:
  ```
  FUEL VALVE
  ● OPEN
  ○ CLOSED

  FUEL PRESSURE: [████████] 2.1 bar
  STATUS: READY
  ```

**Step 3.3:** Engine Pre-Heat (Optional but Recommended)
- Action: Arm ignition (`G`) but don't fire yet
- System pre-heats for 5 seconds
- Prevents cold-start damage

**Step 3.4:** Verify All Systems
- Checklist Display:
  ```
  PRE-FLIGHT CHECKLIST
  ☑ Reactor Online
  ☑ Power Stable
  ☑ Coolant Active
  ☑ Fuel Pressure Good
  ☑ RCS Armed
  ☑ Main Engine Ready

  STATUS: READY FOR DEPARTURE
  [PROCEED]
  ```

### Startup Failure Scenarios

**Failure A: Battery Depletion**
- If reactor startup takes too long OR player doesn't start it
- Battery hits 0% → BLACKOUT
- Recovery: Must restart from emergency battery (limited tries)

**Failure B: Reactor SCRAM During Startup**
- Random 5% chance if player rushing
- Must restart sequence

**Failure C: Overheating During Startup**
- If radiators not deployed soon enough
- Reactor auto-SCRAMs to prevent damage
- Must cool down and restart

### Time Estimates
- **Speedrun (Optimal):** 45-60 seconds
- **First Time:** 2-3 minutes (learning checklist)
- **Rushed/Mistakes:** 3-5 minutes (recovering from failures)

---

## Sequence 2: Pre-Flight Checks

**Context:** Systems are online, preparing for departure.

### Pre-Flight Workflow

**Step 1:** Verify Fuel Status
- Switch to Helm panel
- Check all 3 fuel tanks:
  ```
  FUEL STATUS
  TANK 1:  [████████] 95%  (380kg)
  TANK 2:  [███████░] 90%  (360kg)
  MAIN:    [████████] 98%  (392kg)

  TOTAL: 1132kg
  BALANCE: ⚖ STABLE
  ```

**Step 2:** Check Power Budget
- Switch to Engineering
- Verify power draw < reactor output:
  ```
  POWER STATUS
  REACTOR OUTPUT: 3.75kW
  BUS A LOAD:     1.8kW
  BUS B LOAD:     1.2kW
  TOTAL LOAD:     3.0kW

  MARGIN: +0.75kW ✓
  BATTERY: [███████░] 85% CHARGING
  ```

**Step 3:** Verify Thermal Status
- Check all compartments < 320K (safe operating temp)
  ```
  THERMAL STATUS
  BOW:      295K ✓
  BRIDGE:   293K ✓
  ENGINE:   298K ✓
  PORT:     294K ✓
  CENTER:   293K ✓
  STERN:    296K ✓

  COOLANT FLOW: 85%
  RADIATORS: DEPLOYED
  ```

**Step 4:** Navigation Computer Check
- Switch to Navigation panel
- Verify sensors active:
  ```
  SENSOR STATUS
  RADAR:    ● ACTIVE  Range: 10km
  LIDAR:    ● PASSIVE
  THERMAL:  ● ACTIVE  Sensitivity: 90%
  MASS DET: ● ACTIVE

  CONTACTS: 2
  1. Station Alpha (0.5km, 000°)
  2. Traffic Beacon (2.3km, 045°)
  ```

**Step 5:** Set Departure Target
- Select destination from navigation:
  ```
  NAVIGATION COMPUTER

  TARGET: Waypoint Bravo
  DISTANCE: 15,000m
  BEARING: 090° (East)

  ΔVEL REQUIRED: 45 m/s
  FUEL ESTIMATE: 15kg
  TIME ESTIMATE: 120s

  [PLOT COURSE]
  ```

- Press `P` to plot intercept course
- Display shows:
  ```
  COURSE PLOTTED
  ┌──────────────────────┐
  │  YOU                 │
  │   +                  │
  │    \                 │
  │     \                │
  │      \               │
  │       ○ TARGET       │
  │                      │
  │ BURN VECTOR: 090°    │
  │ DURATION: 12s @ 75%  │
  └──────────────────────┘

  [READY FOR DEPARTURE]
  ```

### Pre-Flight Complete
- All checks green
- Course plotted
- Ready to undock/burn

---

## Sequence 3: Departure (Undocking & Initial Burn)

**Context:** Leaving station or safe position, beginning transit.

### Departure Procedure

#### Phase 1: Undocking (If Docked)

**Step 1:** Request Undocking Clearance (Automatic)
- Display: "UNDOCKING CLEARANCE: GRANTED"
- Docking clamps release (automatic)

**Step 2:** RCS Cold Gas Separation
- Action: Use RCS thrusters to push away from station
- Controls: Number keys for bow thrusters
- Recommended: `1` + `2` (bow port + starboard)
- Target: 0.5 m/s separation velocity
- Monitor: Tactical display shows increasing range

**Step 3:** Clear Minimum Safe Distance
- Display: "RANGE: 500m - CLEAR FOR MAIN ENGINE"
- Safe to use main engine without damaging station

#### Phase 2: Departure Burn

**Step 4:** Arm Main Engine
- Action: Press `G` (Arm Ignition)
- Display: "IGNITION ARMED"

**Step 5:** Align to Burn Vector
- Use RCS to rotate ship to match plotted course (090°)
- Display shows alignment indicator:
  ```
  ALIGNMENT
  Target: 090°
  Current: 087°
  Error: -3°

  [|||░░░░░░░] NEARLY ALIGNED
  ```

**Step 6:** Fire Main Engine
- Action: Press `H` (Ignite)
- Display: "MAIN ENGINE: FIRING"

**Step 7:** Set Throttle for Burn
- Navigation computer shows recommended throttle (e.g., 75%)
- Action: Press `Q` repeatedly to reach 75%
- Display:
  ```
  BURN IN PROGRESS

  THROTTLE: [||||||| ] 75%
  DURATION: 12s / 12s
  ΔVEL: 0.0 / 45.0 m/s

  [EXECUTING BURN]
  ```

**Step 8:** Monitor Burn Progress
- Velocity vector grows on tactical display
- Fuel consumption shown
- Temperature rises (monitor thermal)

**Step 9:** Burn Completion
- At target Δv, nav computer alerts: "BURN COMPLETE"
- Action: Press `A` to reduce throttle to 0%
- Action: Press `R` (Emergency Cutoff) or reduce throttle to 0
- Ship now coasting toward target

#### Phase 3: Coast Phase

**Step 10:** Verify Trajectory
- Navigation shows:
  ```
  TRAJECTORY STATUS

  TARGET: Waypoint Bravo
  RANGE: 14,500m (decreasing)
  CLOSING SPEED: 45 m/s
  TIME TO INTERCEPT: 322s

  PROJECTED MISS: 12m ✓

  STATUS: ON COURSE
  ```

**Step 11:** Secure from Departure Stations
- Reduce reactor throttle (save power)
- Option to time-compress (future feature)
- Monitor for random events during transit

---

## Sequence 4: Navigation (Transit Phase)

**Context:** Ship is coasting toward target. Player monitors systems and responds to events.

### Navigation Workflow

#### Normal Transit

**Monitor 1: Trajectory**
- Check navigation panel regularly
- Verify still on course
- Watch for:
  ```
  WARNING: COURSE DEVIATION
  Projected Miss: 150m

  [CORRECTION BURN NEEDED]
  ```

**Monitor 2: Systems Health**
- Rotate through panels checking:
  - Power: Battery charging? Reactor stable?
  - Thermal: All temps nominal?
  - Fuel: Sufficient for approach burn?
  - Life Support: (Future) Atmosphere OK?

**Monitor 3: Contacts**
- Watch radar for:
  - Asteroids (obstacles)
  - Derelicts (opportunities)
  - Anomalies (events)

#### Mid-Course Correction

**When Needed:** Course deviation > 50m

**Step 1:** Calculate Correction
- Nav computer shows:
  ```
  CORRECTION REQUIRED

  Current Miss: 120m
  Correction Δv: 2.5 m/s
  Burn Vector: 085°
  Fuel Cost: 1kg

  [PLOT CORRECTION]
  ```

**Step 2:** Execute Small Burn
- Align ship
- Brief throttle burst (5-10%)
- 1-2 second burn
- Verify correction applied

#### Event Triggers During Transit

Events can trigger at:
- **Specific time marks** (e.g., 50% of journey)
- **Random chance** (per update, low probability)
- **Proximity to objects** (entering asteroid field)

**Event Trigger Example:**
```
=================================
   REACTOR MALFUNCTION
=================================

Your reactor has unexpectedly
SCRAMmed. Battery power only.

BATTERY REMAINING: 85% (12 min)

You must restart the reactor
before power is depleted.

[ACKNOWLEDGE]
=================================
```

Player must:
1. Switch to Engineering
2. Diagnose issue
3. Restart reactor (startup sequence)
4. Resume navigation

---

## Sequence 5: Approach & Arrival

**Context:** Nearing target destination, preparing for final approach.

### Approach Procedure

**Range: 5000m - Begin Approach**

**Step 1:** Begin Deceleration Burn Planning
- Nav computer shows:
  ```
  APPROACH PLANNING

  CURRENT VELOCITY: 45 m/s
  TARGET VELOCITY: 0 m/s (match target)

  DECEL BURN:
  - Start at: 2500m
  - Duration: 12s @ 75%
  - Fuel: 15kg

  [AUTO ALERT AT 2500m]
  ```

**Range: 2500m - Deceleration Burn**

**Step 2:** Rotate 180° for Retrograde Burn
- Use RCS to flip ship
- Align to retrograde (opposite velocity vector)
- Display:
  ```
  FLIP MANEUVER

  Current: 090°
  Target: 270° (retrograde)

  Use RCS to rotate 180°
  ```

**Step 3:** Execute Deceleration Burn
- Same as departure burn, but stopping velocity
- Arm engine
- Fire
- Throttle to 75%
- Monitor velocity decreasing:
  ```
  DECELERATION BURN

  VELOCITY: 45 → 22 → 10 → 0 m/s

  [BURN COMPLETE]
  ```

**Range: 500m - Fine Approach**

**Step 4:** Match Velocity to Target
- If target moving (station orbit, etc.):
  ```
  VELOCITY MATCHING

  YOUR VEL:    0.2 m/s @ 085°
  TARGET VEL:  0.1 m/s @ 090°
  RELATIVE:    0.15 m/s

  ΔVEL NEEDED: 0.15 m/s

  [MATCH VELOCITY]
  ```

- Use RCS for fine adjustments
- Get relative velocity < 0.5 m/s

**Range: 100m - Final Approach**

**Step 5:** Station-Keeping
- Use RCS to maintain position and attitude
- Drift slowly toward target (0.1-0.2 m/s)
- Keep aligned

---

## Sequence 6: Docking

**Context:** Final meters to target, precision required.

### Docking Procedure

**Range: 50m - Docking Alignment**

**Step 1:** Align Docking Port
- Rotate ship to match target's docking orientation
  ```
  DOCKING ALIGNMENT

  Target Orientation: 000° (North)
  Your Orientation:   358°

  Error: -2° ✓

  ALIGNED
  ```

**Step 2:** Final Approach
- Very slow closure (0.1 m/s max)
- RCS only (no main engine)
- Use forward/aft thrusters:
  - Forward: `9` + `0` (stern thrusters)
  - Brake: `1` + `2` (bow thrusters)

**Step 3:** Contact & Capture
- At 5m: "PREPARE FOR DOCKING"
- At 1m: "DOCKING IN PROGRESS"
- At 0m: "CONTACT"
- Automatic: Docking clamps engage

**Success Conditions:**
- Range: < 1m
- Relative velocity: < 0.5 m/s
- Alignment: < 5° error
- No collision damage (> 1.0 m/s impact)

**Success Display:**
```
=================================
    DOCKING SUCCESSFUL
=================================

Time: 1235s (20:35)
Fuel Used: 32kg
Damage: None

MISSION OBJECTIVE: COMPLETE

[CONTINUE]
=================================
```

### Docking Failure Scenarios

**Failure A: Collision (Too Fast)**
- Impact > 1.0 m/s
- Result: Hull damage, bounce off
- Must retry approach

**Failure B: Misalignment**
- Angle error > 10°
- Result: Docking port miss, can't connect
- Must re-align and retry

**Failure C: Fuel Depletion**
- Ran out of fuel during approach
- Result: Drifting, can't maneuver
- Mission failure (stranded)

---

## Event Integration During Sequences

### Event Types & When They Trigger

#### 1. Navigation Events
**Trigger:** During transit (NAVIGATION state)

**Examples:**
- **Asteroid Field** (Range: 3000m to target)
  - Display: "ASTEROID FIELD DETECTED"
  - Requires: Manual dodging with RCS
  - Duration: 60-120 seconds
  - Risk: Hull damage if collision

- **Debris Cloud** (Random, 10% chance)
  - Display: "HIGH-VELOCITY DEBRIS"
  - Requires: Orient ship to minimize cross-section
  - Duration: 30 seconds
  - Risk: Random impacts

#### 2. Operational Events
**Trigger:** Any time after startup

**Examples:**
- **Reactor Failure** (Random, 5% chance per mission)
  - Display: "REACTOR SCRAM"
  - Requires: Engineering panel, restart sequence
  - Time Limit: Battery duration
  - Risk: Blackout if not fixed

- **Fire Outbreak** (Random, 3% chance OR after overheat)
  - Display: "FIRE DETECTED IN COMPARTMENT 3"
  - Requires: Life Support panel, fire suppression
  - Time Limit: O2 depletion
  - Risk: Ship-wide fire, critical damage

- **Hull Breach** (Random, 10% in debris fields)
  - Display: "HULL BREACH - COMPARTMENT 5"
  - Requires: Life Support panel, seal/patch
  - Time Limit: Atmosphere loss
  - Risk: Thrust vector from venting

#### 3. Encounter Events
**Trigger:** Scripted node encounters

**Examples:**
- **Derelict Vessel** (Choice-based)
  - Display: "DERELICT DETECTED - INVESTIGATE?"
  - Options: Dock / Scan / Ignore
  - If Dock: Precision docking mini-mission
  - Reward: Fuel, parts, O2

- **Distress Signal** (Choice-based)
  - Display: "SOS RECEIVED - RESPOND?"
  - Options: Intercept / Ignore
  - If Intercept: Rendezvous navigation challenge
  - Reward: Resources, info

### Event Resolution Flow

```
[NORMAL NAVIGATION]
       │
       ↓
[EVENT TRIGGERED]
       │
       ↓
[EVENT BRIEFING SCREEN]
   "What's happening?"
   "What do you need to do?"
       │
       ↓
[PLAYER RESPONDS]
   - Switch panels
   - Use controls
   - Make decisions
       │
       ├─→ [SUCCESS] → [REWARD/CONTINUE]
       │
       └─→ [FAILURE] → [PENALTY/CONTINUE or GAME OVER]
       │
       ↓
[RESUME NAVIGATION]
```

---

## State Persistence Between Sequences

### What Carries Forward

**Ship State:**
- Fuel remaining
- System health (damage %)
- Battery charge
- Thermal state (temperatures)
- Hull integrity
- Resource inventory (parts, O2, etc.)

**Position/Velocity:**
- Current position in space
- Current velocity vector
- Current rotation

**Mission Progress:**
- Nodes completed
- Events encountered
- Time elapsed
- Objectives status

### Save Points

**Auto-Save Triggers:**
- End of each sequence (docking complete)
- Before each event
- Manual save (pause menu)

**Save Data:**
```json
{
  "version": "1.0",
  "timestamp": "2025-11-16T22:00:00Z",
  "campaign": {
    "currentNode": 5,
    "sector": 2,
    "seed": 12345
  },
  "ship": {
    "fuel": 1050,
    "fuelCapacity": 1200,
    "systems": {
      "propulsion": { "health": 100 },
      "reactor": { "health": 95 },
      "lifesupport": { "health": 100 },
      "navigation": { "health": 100 }
    },
    "position": { "x": 15000, "y": 3000 },
    "velocity": { "x": 0, "y": 0 }
  }
}
```

---

## UI State Transitions During Sequences

### HUD Elements by Sequence

**Startup:**
- Active Panel: Engineering (forced)
- Display: Startup checklist
- Controls: Limited to Engineering
- Overlay: "EMERGENCY POWER" warning

**Pre-Flight:**
- Active Panel: Player choice
- Display: Checklist overlay
- Controls: All available
- Overlay: "PRE-FLIGHT CHECKS"

**Departure:**
- Active Panel: Helm (recommended)
- Display: Burn timer, Δv indicator
- Controls: All available
- Overlay: "DEPARTURE BURN"

**Navigation:**
- Active Panel: Navigation (recommended)
- Display: Trajectory projection
- Controls: All available
- Overlay: None (or event-specific)

**Approach:**
- Active Panel: Helm (recommended)
- Display: Range, velocity, alignment
- Controls: All available
- Overlay: "APPROACH MODE"

**Docking:**
- Active Panel: Helm (forced)
- Display: Docking alignment, contact range
- Controls: RCS only (main engine disabled)
- Overlay: "DOCKING MODE"

---

## Tutorial Sequence (First Mission)

### Special Handling for First Playthrough

**Overlay Hints:**
- Startup: "Press R to start reactor" (arrow pointing to button)
- Pre-Flight: "Check all systems are green"
- Departure: "Use Q/A to adjust throttle"
- Navigation: "Switch panels with number keys"
- Approach: "Match velocity to < 0.5 m/s"

**Pause & Explain:**
- Can pause at any time
- Info panel explains current objective
- No time pressure (timers disabled)

**Simplified First Mission:**
- No random events
- Generous fuel margins
- Wider tolerances (docking < 1.0 m/s instead of 0.5)
- Success guaranteed if following instructions

---

## Sequence Timing Estimates

### MVP Single Mission (Node-to-Node)

| Sequence | Optimal | First Time | With Events |
|----------|---------|------------|-------------|
| Startup | 45s | 2-3min | Same |
| Pre-Flight | 30s | 1-2min | Same |
| Departure | 60s | 2min | Same |
| Navigation | 5min | 5-8min | 8-15min |
| Approach | 2min | 3-5min | Same |
| Docking | 60s | 2-3min | Same |
| **TOTAL** | **~10min** | **15-25min** | **20-35min** |

### Full Campaign (20-30 Nodes)

- **Speedrun:** 3-4 hours
- **Normal:** 4-6 hours
- **Cautious:** 6-8 hours

---

## Next Steps: Implementation Priority

1. **Build State Machine** (game.ts)
2. **Implement Startup Sequence** (first testable loop)
3. **Build Navigation State** (core gameplay)
4. **Add First Event** (reactor failure - simplest)
5. **Build Campaign Map** (node progression)
6. **Add More Events** (incremental content)

This design should now be ready for implementation.
