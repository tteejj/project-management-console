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

### Coolant Pumps (Engineering Station Only)
**Context:** Keys 1-2 control coolant pumps ONLY when on Engineering station

| Key | Action |
|-----|--------|
| **1** | Toggle coolant loop 1 pump on/off |
| **2** | Toggle coolant loop 2 pump on/off |

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

### Emergency Operations (Life Support Station Only)
| Key | Action |
|-----|--------|
| **B** | Cycle compartment selection (Bow → Bridge → Engineering → Port → Center → Stern) |
| **F** | Fire suppression - Deploy Halon in selected compartment |
| **V** | Emergency vent - Vent selected compartment to space (kills fire instantly) |

**Note:** Fire suppression and venting target the currently selected compartment. Use **B** to cycle through compartments.

---

## Game Controls (All Stations)

| Key | Action |
|-----|--------|
| **P** | Pause/Resume simulation |
| **X** | Quit game |

---

## Context-Sensitive Controls

Some keys have different functions depending on which station you're viewing:

### Keys 1-4
- **Engineering Station:** Keys 1-2 control coolant pumps, 3-4 inactive
- **All Other Stations:** Keys 1-4 control SAS modes

### Keys F, V, B
- **Life Support Station:** Fire suppression, emergency vent, compartment cycling
- **All Other Stations:** Inactive

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
- Propellant tank breakdown (3 tanks)
- Flight control systems detail
- Attitude display

### Engineering Station (Station 7)
- Electrical system (reactor status, battery charge, total load)
- Thermal system (all component temperatures)
- Coolant system (2 loops: pump status, temperature, flow rate)
- Heat rejection tracking

### Life Support Station (Station 8)
- O2 generator (status, rate, reserves, total generated)
- CO2 scrubber (status, efficiency, media life, total scrubbed)
- 6 compartments (O2%, CO2%, pressure, fire warnings)
- Fire suppression (Halon reserves, usage count)
- Selected compartment indicator

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
2. Cycle to burning compartment (**B** repeatedly)
3. Deploy Halon (**F**)
4. If fire persists: Emergency vent (**V**) - WARNING: Vents all atmosphere!
5. Monitor O2 levels in other compartments
6. Close bulkhead doors (not yet implemented) to prevent spread

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
- Engineering controls (pumps) only work on Engineering station
- Life Support emergencies only work on Life Support station
- Switch stations frequently to monitor all systems

---

**"In space, you don't fly - you operate systems and hope they work."**
