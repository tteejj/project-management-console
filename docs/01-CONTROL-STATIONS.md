# Control Stations & Controls

## Overview

The game features **4-5 control stations** that the player switches between using number keys (1-5) or tab. Each station displays different information and controls different ship systems.

**Key Design Principle**: No single station shows everything. Players must switch between stations to get complete situational awareness.

## Station 1: HELM / PROPULSION

**Purpose**: Direct control of ship movement and propulsion systems

**Screen Layout**:
```
┌─────────────────────────────────────────────────────────┐
│ HELM CONTROL                                    [1/5]   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  MAIN ENGINE               RCS THRUSTERS               │
│  ┌──────────────┐          ┌─────────────────────┐    │
│  │ FUEL VALVE   │          │  BOW    [1][2][3][4]│    │
│  │  ○ OPEN      │          │         P  S  D  V  │    │
│  │  ● CLOSED    │          │                     │    │
│  │              │          │  MID    [5][6][7][8]│    │
│  │ IGNITION     │          │         P  S  D  V  │    │
│  │  [  ARM  ]   │          │                     │    │
│  │  [  FIRE ]   │          │  STERN  [9][0][-][=]│    │
│  │              │          │         P  S  D  V  │    │
│  │ THROTTLE     │          │                     │    │
│  │  [||||    ]  │          │ P=Port S=Starboard  │    │
│  │   0%   (Q/A) │          │ D=Dorsal V=Ventral  │    │
│  │              │          └─────────────────────┘    │
│  │ GIMBAL       │                                      │
│  │  X: [||||] (W/S) │      FUEL STATUS                │
│  │  Y: [||||] (E/D) │      ┌────────────────────┐    │
│  │              │          │ TANK 1  [████░░] 70%│    │
│  └──────────────┘          │ TANK 2  [███░░░] 55%│    │
│                            │ MAIN    [██████] 95%│    │
│  ENGINE STATUS             │                     │    │
│  ┌──────────────┐          │ BALANCE: ⚖ STABLE  │    │
│  │ TEMP:  425K  │          │                     │    │
│  │ [████░░░░]   │          │ [TRANSFER 1→2]      │    │
│  │ PRESS: 2.1bar│          │ [TRANSFER 2→1]      │    │
│  │ FLOW:  85%   │          │ [EMERGENCY DUMP]    │    │
│  └──────────────┘          └────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### Controls (MVP)

**Main Engine** (10 controls):
1. `F` - Toggle fuel valve (OPEN/CLOSED)
2. `G` - Arm ignition (must arm before firing)
3. `H` - Fire ignition (only works if armed + valve open + pressure good)
4. `Q` - Increase throttle (+5%)
5. `A` - Decrease throttle (-5%)
6. `W` - Gimbal up (+1°)
7. `S` - Gimbal down (-1°)
8. `E` - Gimbal right (+1°)
9. `D` - Gimbal left (-1°)
10. `R` - Emergency cutoff (instant shutdown)

**RCS Thrusters** (12 controls):
- Number keys `1-9, 0, -, =` - Fire individual thrusters while held
- Each thruster has position (bow/mid/stern) and direction (port/starboard/dorsal/ventral)

**Fuel Management** (4 controls):
1. `T` - Transfer Tank 1 → Tank 2
2. `Y` - Transfer Tank 2 → Tank 1
3. `U` - Emergency fuel dump (vents fuel, creates thrust)
4. Auto-balance indicator (visual only)

**Gauges/Readouts** (Visual only):
- Engine temperature (overheating disables engine)
- Fuel pressure (must be in green zone to ignite)
- Fuel flow percentage
- Tank levels (3 tanks)
- Balance indicator

### Controls (Full Version)

**Additional features:**
- Individual thruster lock toggles (disable damaged thrusters)
- Thruster temperature gauges (can overheat)
- Fuel pump controls (manual pump management)
- Engine preheater (cold starts take time)
- Throttle presets (25%, 50%, 75%, 100%)
- Gimbal lock toggle
- RCS auto-stabilization toggle

**Total Controls**: ~35-40

---

## Station 2: ENGINEERING / POWER

**Purpose**: Power generation, distribution, thermal management, and damage control

**Screen Layout**:
```
┌─────────────────────────────────────────────────────────┐
│ ENGINEERING                                     [2/5]   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  REACTOR                   POWER DISTRIBUTION          │
│  ┌──────────────┐          ┌─────────────────────┐    │
│  │ STATUS: ONLINE          │ BUS A    BUS B       │    │
│  │ OUTPUT: 2.4kW│          │ 1.8kW    1.2kW       │    │
│  │              │          │ [████]   [███░]      │    │
│  │ [  START  ]  │          │                     │    │
│  │ [  SCRAM  ]  │          │ BREAKERS (ON/OFF)   │    │
│  │              │          │ [1] Life Support  A │    │
│  │ THROTTLE     │          │ [2] Propulsion    A │    │
│  │  [||||||| ]  │          │ [3] Nav Computer  B │    │
│  │   75%  (I/K) │          │ [4] Sensors       B │    │
│  │              │          │ [5] Doors         A │    │
│  │ TEMP: 450K   │          │ [6] Lights        B │    │
│  │ [████░░░░]   │          │ [7] Comms         B │    │
│  └──────────────┘          │ [8] Coolant Pump  A │    │
│                            │ [9] Radiators     A │    │
│  BATTERY                   │ [0] Backup Sys    B │    │
│  ┌──────────────┐          └─────────────────────┘    │
│  │ CHARGE: 78%  │                                      │
│  │ [███████░░]  │          THERMAL MANAGEMENT          │
│  │              │          ┌─────────────────────┐    │
│  │ ○ CHARGE     │          │ COOLANT PUMP: ON    │    │
│  │ ● DISCHARGE  │          │ FLOW: 85%           │    │
│  │              │          │                     │    │
│  │ LOAD: -0.8kW │          │ RADIATORS: DEPLOYED │    │
│  └──────────────┘          │ [RETRACT] [DEPLOY]  │    │
│                            │                     │    │
│  DAMAGE CONTROL            │ HEAT EXCHANGERS     │    │
│  ┌──────────────┐          │ #1 ● #2 ● #3 ○ #4 ●│    │
│  │ ● Propulsion │          │                     │    │
│  │ ● Life Sup.  │          │ [EMERGENCY DUMP]    │    │
│  │ ○ Nav Comp.  │          └─────────────────────┘    │
│  │ ○ Sensors    │                                      │
│  │ ● Hull Int.  │          SPARE PARTS: 3              │
│  │ ● Thermal    │          REPAIR QUEUE: 2             │
│  └──────────────┘                                      │
└─────────────────────────────────────────────────────────┘
```

### Controls (MVP)

**Reactor** (4 controls):
1. `R` - Start reactor (takes 10 seconds)
2. `T` - SCRAM (emergency shutdown)
3. `I` - Increase throttle (+5% power output)
4. `K` - Decrease throttle (-5% power output)

**Power Distribution** (10 circuit breakers):
- Keys `1-9, 0` - Toggle circuit breakers ON/OFF
- Each breaker controls power to a specific system
- Systems without power don't function
- Drawing more power than reactor produces drains battery

**Battery** (2 controls):
1. `B` - Toggle charge/discharge mode
2. Auto-manages based on reactor output (visual only)

**Thermal Management** (4 controls):
1. `C` - Toggle coolant pump ON/OFF
2. `V` - Increase coolant flow (+10%)
3. `F` - Decrease coolant flow (-10%)
4. `G` - Deploy/retract radiators
5. `H` - Emergency heat dump (vents coolant to space, one-time use)

**Damage Control** (2 controls):
1. `M` - Cycle through damaged systems
2. `N` - Initiate repair (consumes spare part, takes time)

**Gauges/Readouts**:
- Reactor output (kW)
- Reactor temperature
- Bus A/B voltage and load
- Battery charge percentage
- System status (green/yellow/red)
- Temperature at 10+ locations
- Heat exchanger status
- Spare parts count

### Controls (Full Version)

**Additional features:**
- Individual bus routing (reroute systems between buses)
- Emergency bus (low-power mode)
- Battery bank management (multiple batteries)
- Coolant reservoir levels
- Heat exchanger individual controls
- Damage assessment tool
- Jury-rig option (temporary fix, no parts needed, unreliable)
- Load balancing auto/manual toggle

**Total Controls**: ~45-50

---

## Station 3: NAVIGATION / SENSORS

**Purpose**: Situational awareness, trajectory planning, sensor management

**Screen Layout**:
```
┌─────────────────────────────────────────────────────────┐
│ NAVIGATION                                      [3/5]   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  TACTICAL DISPLAY          SENSORS                     │
│  ┌──────────────┐          ┌─────────────────────┐    │
│  │      N        │          │ RADAR: ACTIVE       │    │
│  │      ↑        │          │ RANGE: [||||] 10km  │    │
│  │              │          │  (Z/X to adjust)    │    │
│  │   *  █  ○    │          │ GAIN:  [|||░] 75%   │    │
│  │              │          │  (C/V to adjust)    │    │
│  │      +       │          │                     │    │
│  │   (YOU)      │          │ LIDAR: PASSIVE      │    │
│  │              │          │ [ACTIVE] [PASSIVE]  │    │
│  │    *         │          │ SWEEP: 360° AUTO    │    │
│  │              │          │                     │    │
│  │  * = Contact │          │ THERMAL: ON         │    │
│  │  ○ = Target  │          │ SENS: [|||||] 90%   │    │
│  │              │          │  (B/N to adjust)    │    │
│  └──────────────┘          │                     │    │
│                            │ MASS DETECT: ON     │    │
│  VELOCITY VECTORS          │ [CALIBRATE]         │    │
│  ┌──────────────┐          └─────────────────────┘    │
│  │ YOUR VEL     │                                      │
│  │  →           │          CONTACTS                   │
│  │   15.2 m/s   │          ┌─────────────────────┐    │
│  │  045°        │          │ 1. RNG: 8.2km       │    │
│  │              │          │    BRG: 045°        │    │
│  │ TARGET VEL   │          │    VEL: 12.5m/s     │    │
│  │   ←          │          │    CLOSING          │    │
│  │   8.3 m/s    │          │                     │    │
│  │  220°        │          │ 2. RNG: 15.7km      │    │
│  │              │          │    BRG: 310°        │    │
│  │ RELATIVE     │          │    VEL: 5.2m/s      │    │
│  │  ↗           │          │    OPENING          │    │
│  │   7.1 m/s    │          │                     │    │
│  └──────────────┘          │ [SELECT: 1-9]       │    │
│                            └─────────────────────┘    │
│  NAV COMPUTER                                         │
│  ┌──────────────────────────────────────────┐         │
│  │ TARGET: Contact #1                       │         │
│  │ INTERCEPT Δv: 8.5 m/s                   │         │
│  │ TIME TO INTERCEPT: 145s                  │         │
│  │ FUEL REQUIRED: 12kg                      │         │
│  │                                          │         │
│  │ [PLOT COURSE] [AUTOPILOT ENGAGE]        │         │
│  └──────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────┘
```

### Controls (MVP)

**Sensors** (10 controls):
1. `R` - Toggle radar ON/OFF
2. `Z` - Increase radar range
3. `X` - Decrease radar range
4. `C` - Increase radar gain (sensitivity)
5. `V` - Decrease radar gain
6. `L` - Toggle LIDAR active/passive
7. `T` - Toggle thermal sensor ON/OFF
8. `B` - Increase thermal sensitivity
9. `N` - Decrease thermal sensitivity
10. `M` - Calibrate mass detector (takes 5 seconds)

**Contact Management** (5 controls):
1. `1-9` - Select contact as target
2. `TAB` - Cycle through contacts
3. `SHIFT+TAB` - Cycle backwards
4. Contact list auto-updates (visual only)
5. Selected target highlights on tactical display

**Navigation Computer** (3 controls):
1. `P` - Plot intercept course to selected target
2. `A` - Engage autopilot (requires Nav Computer powered, can fail if damaged)
3. `S` - Disengage autopilot

**Displays** (Visual only):
- Tactical radar (top-down 2D view)
- Velocity vectors (your ship, target, relative)
- Contact list (range, bearing, velocity, closing/opening)
- Intercept solution (delta-v, time, fuel)
- Projected trajectory line

### Controls (Full Version)

**Additional features:**
- Radar mode selection (search/track)
- LIDAR sweep angle adjustment
- Individual contact tracking locks
- Waypoint system (mark positions)
- Coordinate input (manual navigation)
- Trajectory prediction overlay
- Collision warning system
- IFF transponder controls
- ECM/ECCM (if combat added)

**Total Controls**: ~30-35

---

## Station 4: LIFE SUPPORT / ENVIRONMENTAL

**Purpose**: Atmosphere management, fire suppression, compartment control

**Screen Layout**:
```
┌─────────────────────────────────────────────────────────┐
│ LIFE SUPPORT                                    [4/5]   │
├─────────────────────────────────────────────────────────�┤
│                                                         │
│  SHIP LAYOUT (6 COMPARTMENTS)                          │
│  ┌──────────────────────────────────────────┐          │
│  │   [1]────[2]────[3]                     │          │
│  │    │      │      │                       │          │
│  │   [4]────[5]────[6]                     │          │
│  │                                          │          │
│  │  1=Bow   2=Bridge  3=Engineering        │          │
│  │  4=Port  5=Center  6=Stern              │          │
│  └──────────────────────────────────────────┘          │
│                                                         │
│  COMPARTMENT: #5 (CENTER) ◀ SELECT: 1-6 ▶             │
│  ┌────────────────────────────────────────────────┐    │
│  │ ATMOSPHERE                                     │    │
│  │  O2:    [████░░░░] 18.2%  (NORM: 21%)         │    │
│  │  CO2:   [░░░░░░░░]  0.8%  (NORM: <1%)         │    │
│  │  N2:    [███████░] 80.5%  (NORM: 78%)         │    │
│  │  PRESS: [████████] 101kPa (NORM: 101kPa)      │    │
│  │  TEMP:  [████░░░░] 295K   (NORM: 293K)        │    │
│  │                                                │    │
│  │ STATUS: ● NORMAL                               │    │
│  │                                                │    │
│  │ BULKHEAD DOORS                                 │    │
│  │  [BOW]   [BRIDGE]  [ENG]                      │    │
│  │   OPEN     OPEN     OPEN                      │    │
│  │  [PORT]  [STERN]                              │    │
│  │   OPEN     OPEN                               │    │
│  │                                                │    │
│  │ FIRE SUPPRESSION                               │    │
│  │  [ DISARMED ]                                  │    │
│  │  [  ARM  ]  [  FIRE  ]                        │    │
│  │                                                │    │
│  │ EMERGENCY VENT                                 │    │
│  │  ⚠ SAFETY INTERLOCK: ON                       │    │
│  │  [ OVERRIDE ]  [ VENT TO SPACE ]              │    │
│  │                                                │    │
│  │ PRESSURE EQUALIZATION                          │    │
│  │  [ AUTO ]  [ MANUAL VALVE ]                   │    │
│  └────────────────────────────────────────────────┘    │
│                                                         │
│  GLOBAL SYSTEMS                                        │
│  ┌────────────────────────────────────────────────┐    │
│  │ O2 GENERATOR: ● ON    RATE: [|||░] 0.8 L/min  │    │
│  │                        (Q/A to adjust)         │    │
│  │                                                │    │
│  │ CO2 SCRUBBER: ● ON    EFFICIENCY: 95%         │    │
│  │               FILTER: [████░░] 65% LIFE       │    │
│  │                                                │    │
│  │ O2 RESERVES: [██████░] 85kg                   │    │
│  │ SCRUB MEDIA: [███░░░░] 45% REMAINING          │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### Controls (MVP)

**Compartment Selection** (2 controls):
1. `1-6` - Select compartment to view/control
2. Visual readouts update to show selected compartment

**Per-Compartment Controls** (8 controls per compartment):

*Bulkhead Doors* (varies by compartment):
- `Q, W, E, R, T` - Toggle adjacent doors OPEN/SEALED
- Each compartment has 2-4 doors to neighbors

*Fire Suppression*:
1. `A` - Arm fire suppression system
2. `S` - Fire suppression (releases Halon, requires armed)

*Emergency Venting*:
1. `Z` - Override safety interlock
2. `X` - Vent to space (opens external hatch, vents all atmosphere)

*Pressure Equalization*:
1. `C` - Toggle auto/manual equalization
2. `V` - Manual equalization valve (when manual mode)

**Global Systems** (4 controls):
1. `O` - Toggle O2 generator ON/OFF
2. `Q` - Increase O2 generation rate
3. `A` - Decrease O2 generation rate
4. `S` - Toggle CO2 scrubber ON/OFF (auto-manages efficiency)

**Gauges/Readouts**:
- O2, CO2, N2 percentages per compartment
- Pressure (kPa) per compartment
- Temperature per compartment
- Door states (open/sealed)
- Fire status per compartment
- O2 reserves (kg)
- Scrubber media remaining
- Generator rate

### Controls (Full Version)

**Additional features:**
- Individual gas venting (vent just O2 or just CO2)
- Crew assignments (when crew added)
- Medical status (when crew added)
- Temperature control per compartment
- Humidity monitoring
- Airflow management
- Emergency suit deployment
- Compartment isolation presets

**Total Controls**: ~50-60 (with 6 compartments)

---

## Station 5: COMMUNICATIONS / TACTICAL (Future)

**Purpose**: Receive distress calls, trade, mission objectives, possibly light combat

*Deferred to post-MVP - design TBD*

Possible features:
- Signal detection/decryption
- Transponder control
- Mission log
- Encounter text displays
- Shield management (if combat)
- Countermeasures

---

## Control Summary

### MVP Total Controls

| Station | Controls | Gauges/Readouts |
|---------|----------|-----------------|
| Helm | ~26 | 8 |
| Engineering | ~22 | 15 |
| Navigation | ~18 | 10 |
| Life Support | ~20 | 20 |
| **TOTAL** | **~86** | **~53** |

### Full Version Total Controls

| Station | Controls | Gauges/Readouts |
|---------|----------|-----------------|
| Helm | ~40 | 12 |
| Engineering | ~50 | 25 |
| Navigation | ~35 | 15 |
| Life Support | ~60 | 30 |
| Comms/Tactical | ~25 | 10 |
| **TOTAL** | **~210** | **~92** |

---

## UI/UX Principles

### Station Switching
- Number keys `1-5` or `TAB` to cycle
- Visual indicator of current station
- Audio cue on switch (if sound added)

### Visual Feedback
- Buttons highlight on hover
- Active states clearly shown
- Warnings flash (not constantly, just on state change)
- Critical warnings stay visible

### Keyboard Focus
- All controls keyboard-accessible
- Logical key groupings (WASD for gimbal, QA for throttle, etc.)
- No mouse required (but mouse works too)

### Information Density
- Each station shows only relevant info
- No clutter
- Important info larger/highlighted
- Secondary info smaller but accessible

### Color Coding
- Green = Normal/Good
- Yellow = Warning/Caution
- Red = Critical/Danger
- White/Amber = Neutral info
- Consistent across all stations

### Monospace Aesthetic
- Fixed-width font throughout
- ASCII-art style boxes and lines
- Retro terminal feel
- Clean and readable

### Accessibility
- Player-selectable color palette
- Clear contrast
- Large enough text
- Consistent layout
