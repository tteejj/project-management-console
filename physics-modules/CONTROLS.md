# Vector Moon Lander - Interactive Controls Reference

**"Submarine in Space" - Procedural Control Interface**

All controls are keyboard-driven. No mouse required.

---

## Station Switching

| Key | Station | Description |
|-----|---------|-------------|
| **5** | Captain Screen | Overview of all 13 systems |
| **6** | Helm | Propulsion, flight controls, fuel |
| **7** | Engineering | Power, thermal, coolant |
| **8** | Life Support | Atmosphere, O2/CO2, fire suppression |

---

## Flight Controls (All Stations)

### Main Engine
| Key | Action |
|-----|--------|
| **I** | Ignite main engine (requires 2-second sequence) |
| **K** | Kill engine (shutdown) |
| **+** / **=** | Increase throttle (+10%) |
| **-** | Decrease throttle (-10%) |

### RCS (Reaction Control System)
| Key | Action |
|-----|--------|
| **W** | Pitch up (200ms pulse) |
| **S** | Pitch down (200ms pulse) |
| **A** | Yaw left (200ms pulse) |
| **D** | Yaw right (200ms pulse) |
| **Q** | Roll counter-clockwise (200ms pulse) |
| **E** | Roll clockwise (200ms pulse) |

### SAS (Stability Augmentation System)
**Context:** Active on all stations EXCEPT Engineering (keys 1-2 used for pumps)

| Key | SAS Mode |
|-----|----------|
| **1** | Off |
| **2** | Stability hold |
| **3** | Prograde hold |
| **4** | Retrograde hold |

### Autopilot
| Key | Autopilot Mode |
|-----|----------------|
| **F1** | Off |
| **F2** | Altitude hold (holds current altitude) |
| **F3** | Vertical speed hold (holds current V/S) |
| **F4** | Suicide burn (automatic landing burn) |
| **F5** | Hover (maintain altitude with throttle) |

### Gimbal Control
| Key | Action |
|-----|--------|
| **G** | Toggle gimbal autopilot (automatic thrust vectoring) |

---

## Engineering Controls

### Reactor (All Stations)
| Key | Action |
|-----|--------|
| **R** | Start reactor (30-second startup sequence) |
| **T** | SCRAM - Emergency reactor shutdown |

### Reactor Control (Engineering Station Only)
| Key | Action |
|-----|--------|
| **↑** | Increase reactor throttle (+10%, max 100%) |
| **↓** | Decrease reactor throttle (-10%, min 0%) |
| **Y** | Reset reactor from SCRAM state |

### Coolant System (Engineering Station Only)
**Context:** Keys 1-2 control coolant pumps ONLY when on Engineering station

| Key | Action |
|-----|--------|
| **1** | Toggle coolant loop 1 pump on/off |
| **2** | Toggle coolant loop 2 pump on/off |
| **X** | Toggle coolant cross-connect (shares coolant between loops) |

### Electrical System (Engineering Station Only)
**Circuit Breakers** - Toggle critical systems on/off:

| Key | Breaker | System |
|-----|---------|--------|
| **A** | O2 Generator | Life support oxygen generation |
| **B** | CO2 Scrubber | Life support CO2 removal |
| **H** | Nav Computer | Navigation systems |
| **J** | Hydraulic Pump 1 | Primary hydraulics |
| **L** | Comms | Communications system |
| **N** | Fuel Pump Main | Main engine fuel pump |
| **M** | Bus Crosstie | Connect power bus A & B for load balancing |

---

## Fuel System Controls (Helm Station Only)

### Tank Selection
| Key | Action |
|-----|--------|
| **Tab** | Cycle fuel tank selection (Main 1 → Main 2 → RCS) |

### Fuel Valves
**Context:** Controls apply to currently selected tank

| Key | Valve | Action |
|-----|-------|--------|
| **N** | Engine Feed | Toggle valve connecting tank to main engine |
| **M** | RCS Feed | Toggle valve connecting tank to RCS manifold |
| **U** | Vent | Toggle emergency vent valve (dumps fuel to space) |

**Note:** Tank must have valve open AND pressure >1.5 bar to feed systems. Venting is permanent - fuel cannot be recovered!

---

## Life Support Controls

### O2 Generation (All Stations)
| Key | Action |
|-----|--------|
| **O** | Toggle O2 generator on/off |
| **[** | Decrease O2 generation rate (-0.5 L/min, min: 0) |
| **]** | Increase O2 generation rate (+0.5 L/min, max: 3.0) |

### CO2 Scrubbing (All Stations)
| Key | Action |
|-----|--------|
| **C** | Toggle CO2 scrubber on/off |

### Compartment Selection (Life Support Station Only)
| Key | Compartment |
|-----|-------------|
| **1** | Bow |
| **2** | Bridge |
| **3** | Engineering |
| **4** | Port |
| **5** | Center (also switches to Captain screen) |
| **6** | Stern (also switches to Helm station) |
| **Tab** | Cycle compartment selection (Bow → Bridge → ...) |

### Emergency Operations (Life Support Station Only)
| Key | Action |
|-----|--------|
| **F** | Fire suppression - Deploy Halon in selected compartment |
| **V** | Emergency vent - Vent selected compartment to space (kills fire instantly) |
| **D** | Toggle bulkhead door - Opens/closes first door of selected compartment |
| **L** | Seal hull breach in selected compartment |

**Note:** Fire suppression and venting target the currently selected compartment. Use **1-6** for direct selection or **Tab** to cycle.

---

## Game Controls (All Stations)

| Key | Action |
|-----|--------|
| **P** | Pause/Resume simulation |
| **X** | Quit game |

---

## Context-Sensitive Controls

Many keys have different functions depending on which station you're viewing:

### Keys 1-6
- **Engineering Station:** 1-2 control coolant pumps, 3-4 inactive
- **Life Support Station:** 1-6 select compartments (5-6 also switch stations)
- **All Other Stations:** 1-4 control SAS modes, 5-8 switch stations

### Tab Key
- **Helm Station:** Cycle fuel tank selection
- **Life Support Station:** Cycle compartment selection
- **Other Stations:** Inactive

### Letters A, B, H, J, L, N, M, X, Y
- **Engineering Station:** Circuit breakers, bus crosstie, coolant cross-connect, reactor controls
- **Other Stations:** Most inactive (see station-specific sections)

### Letters D, F, L, V
- **Life Support Station:** Bulkhead doors, fire suppression, breach sealing, emergency vent
- **Other Stations:** Inactive

### Letters N, M, U
- **Helm Station:** Fuel valve controls (Engine, RCS, Vent)
- **Engineering Station:** N = Fuel Pump breaker, M = Bus crosstie
- **Other Stations:** Inactive

### Arrow Keys ↑/↓
- **Engineering Station:** Reactor throttle control
- **Other Stations:** Inactive

---

## Display Color Coding

### Status Indicators
- **🟢 Green:** Normal, healthy, active
- **🟡 Yellow:** Warning, caution, degraded
- **🔴 Red:** Critical, danger, emergency
- **⚪ Dim/Gray:** Inactive, offline, disabled

### Life Support
- **O2:** Green >20%, Yellow 18-20%, Red <18%
- **CO2:** Green <0.5%, Yellow 0.5-1.0%, Red >1.0%
- **Pressure:** Green >95 kPa, Yellow 80-95 kPa, Red <80 kPa
- **Fire:** 🔥 Red indicator if compartment on fire

### Thermal
- **Temperature:** Green <400K, Yellow 400-500K, Red >500K

### Resources
- **Fuel:** Green >50%, Yellow 20-50%, Red <20%
- **Battery:** Green >20%, Red <20%

---

## Telemetry Overview

### Captain Screen (Station 5)
- Orbital status (altitude, vertical speed, total speed, mass)
- Attitude (pitch, roll, yaw)
- Propulsion (engine status, thrust, throttle, health)
- Resources (propellant, reactor output, battery)
- Thermal (reactor temp, engine temp, coolant temp)
- Flight control (SAS mode, autopilot mode, gimbal status)
- Navigation (time to impact, suicide burn altitude, delta-V, TWR)

### Helm Station (Station 6)
- Main engine detailed status (gimbal positions)
- **FUEL SYSTEM:** Tank selection, individual tank status (mass, pressure, percent full)
- **FUEL VALVES:** Engine feed, RCS feed, vent status for selected tank
- Flight control systems detail
- Attitude display

### Engineering Station (Station 7)
- **ELECTRICAL:** Reactor status/throttle/output, battery, bus loads (A/B), bus crosstie status, net power
- **CIRCUIT BREAKERS:** 12 critical breakers with on/off/tripped status
- **COOLANT:** 2 loops with pump status, temp, flow, cross-connect status
- **THERMAL:** Reactor and engine temperatures (compact)
- Heat rejection tracking

### Life Support Station (Station 8)
- O2 generator (status, rate, reserves, total generated)
- CO2 scrubber (status, efficiency, media life, total scrubbed)
- 6 compartments (O2%, CO2%, pressure, fire warnings)
- **BULKHEAD DOORS:** All door connections with open/closed status
- Fire suppression (Halon reserves, usage count)
- **Selected compartment indicator** with direct selection keys (1-6)

---

## Procedural Complexity Examples

### Startup Sequence
1. Switch to Engineering (**7**)
2. Start reactor (**R**) - Wait 30 seconds
3. Start coolant pumps (**1**, **2**)
4. Switch to Life Support (**8**)
5. Activate O2 generator (**O**)
6. Activate CO2 scrubber (**C**)
7. Switch to Helm (**6**)
8. Ignite engine (**I**) - Wait 2 seconds
9. Set throttle (**+** to increase)
10. Enable SAS stability (**2**)

### Emergency Fire Response
1. Switch to Life Support (**8**)
2. Select burning compartment (**1-6** for direct selection, or **Tab** to cycle)
3. Close bulkhead doors to isolate fire (**D** - toggles door to adjacent compartment)
4. Deploy Halon (**F**)
5. If fire persists: Emergency vent (**V**) - WARNING: Vents all atmosphere!
6. Monitor O2 levels in other compartments
7. If compartment has hull breach: Seal breach (**L**) after venting

### Fuel Management (Tank Switching & Valves)
1. Switch to Helm (**6**)
2. Check which tanks are feeding systems (valve indicators on selected tank)
3. Select tank to reconfigure (**Tab** to cycle through main_1, main_2, rcs)
4. Open/close valves as needed:
   - **N** - Engine feed valve (must be open for main engine)
   - **M** - RCS feed valve (must be open for RCS)
   - **U** - Emergency vent (dumps fuel to space - use carefully!)
5. Monitor tank pressure (must be >1.5 bar to feed systems)
6. **Tip:** Close valves on depleted tanks to prevent cavitation

### Electrical Load Management
1. Switch to Engineering (**7**)
2. Check bus loads (Bus A and Bus B) - yellow warning >75%, red critical >90%
3. If overloaded:
   - Toggle bus crosstie (**M**) to balance loads across both buses
   - OR shed non-essential loads using circuit breakers (**A-L**)
4. Monitor net power (should be positive)
5. Adjust reactor throttle (**↑/↓**) to match electrical demand
6. If reactor is SCRAM'd: Reset (**Y**) once temperature <800K

### Suicide Burn Landing
1. Switch to Captain (**5**) or Helm (**6**)
2. Monitor navigation display for "Time to Impact"
3. When "INITIATE SUICIDE BURN NOW!" appears:
   - Enable autopilot suicide burn mode (**F4**)
   - Engine auto-throttles to achieve soft landing
4. Or manually:
   - Ignite engine (**I**)
   - Full throttle (**+** to 100%)
   - Monitor vertical speed
   - Reduce throttle as speed approaches 0
   - Target: <2 m/s for perfect landing

---

## Tips

**Energy Management:**
- Reactor takes 30 seconds to start - plan ahead
- Battery can sustain minimal systems for ~15 minutes
- Coolant loops prevent reactor overheat - keep them running

**Life Support:**
- O2 generation consumes reserves (85kg total)
- CO2 scrubber media degrades with use (100% → 0%)
- Halon is limited (5kg total, ~10 uses)
- Emergency venting is permanent - can't recover atmosphere

**Landing:**
- Suicide burn is most fuel-efficient
- "Time to Impact" warns you when to start
- Perfect landing: <2 m/s impact speed
- Soft landing: <3 m/s
- Hard landing: <5 m/s (survivable)
- Crash: ≥5 m/s

**Station Management:**
- All flight controls work from any station
- Engineering controls (pumps, breakers, reactor throttle) only work on Engineering station
- Fuel valve controls only work on Helm station
- Life Support emergencies only work on Life Support station
- Switch stations frequently to monitor all systems
- Use context-sensitive controls (same key, different function per station)

**Electrical Systems:**
- Circuit breakers protect systems from overcurrent - will auto-trip if overloaded
- Bus crosstie balances electrical load across both power buses
- Reactor throttle controls power output (0-100%) - match to electrical demand
- Essential breakers (O2 gen, CO2 scrubber, primary coolant) cannot be manually disabled
- If blackout occurs, non-essential breakers automatically trip to preserve power

**Fuel Systems:**
- Tanks must have open valves AND sufficient pressure (>1.5 bar) to feed systems
- Emergency vent is permanent - vented fuel cannot be recovered
- Multiple tanks can feed same system simultaneously (if valves open)
- RCS and main engine can draw from different tanks
- Monitor tank pressure - depressurization indicates leak or pressurant depletion

**Coolant Systems:**
- Cross-connect allows coolant sharing between loops for redundancy
- If one loop fails, cross-connect and run single loop at higher flow
- Frozen coolant stops pump - must warm system before restart
- Boiling coolant indicates severe overheating - emergency reactor shutdown needed

**Bulkhead Doors:**
- Closed doors isolate compartments (fire, pressure, contamination)
- Open doors allow atmosphere equalization between compartments
- During fire: close doors to starve fire of oxygen
- During depressurization: close doors to save atmosphere in other compartments

---

**"In space, you don't fly - you operate systems and hope they work."**
