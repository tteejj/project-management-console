# Spacecraft Physical Layout & Integration Design

## Ship Overview

**Class**: Medium Combat Freighter
**Name**: MC-550 "Valkyrie"
**Role**: Multi-role spacecraft capable of cargo transport, combat operations, and deep space exploration

## Physical Specifications

**Dimensions:**
- Length: 45 meters
- Beam: 18 meters
- Height: 12 meters
- Mass (dry): 50,000 kg
- Mass (fueled): 95,000 kg
- Crew: 1-6 personnel

**Layout Coordinate System:**
- **X-axis**: Port (-) to Starboard (+)
- **Y-axis**: Ventral (-) to Dorsal (+)
- **Z-axis**: Aft (-) to Forward (+)
- Origin (0,0,0) at center of mass

## Deck Layout

### Deck 1: Command & Living (Y: +4m to +6m)
```
     FORWARD
        ↑
    [BRIDGE]────[OBS DOME]
        │
    [QUARTERS]──[QUARTERS]
        │
    [GALLEY]────[MED BAY]
        │
     [AIRLOCK]
```

**Components:**
- Bridge: (0, +5, +20) - Command and control
- Observation Dome: (0, +6, +22) - Sensor array, star tracker mount
- Crew Quarters: (±4, +5, +15) - 2 compartments
- Galley/Life Support: (-4, +5, +10)
- Medical Bay: (+4, +5, +10)
- Airlock: (0, +5, +5)

### Deck 2: Main Operations (Y: 0m to +4m)
```
    [WEAPONS]───[FLIGHT]
       STATION     DECK
          │         │
    [ENGINEER]──[CARGO]──[DOCKING]
       STATION     BAY     PORT
          │         │
    [TACTICAL]──[LADDER]
```

**Components:**
- Flight Deck: (0, +2, +15) - Primary flight controls
- Weapons Station: (-5, +2, +15) - Fire control
- Engineering Station: (-5, +2, +5) - Power/thermal management
- Tactical Station: (-5, +2, -5) - Sensors/countermeasures
- Cargo Bay: (0, +1, 0) - Main storage, 200m³
- Docking Port (Forward): (0, +2, +25)

### Deck 3: Engineering & Propulsion (Y: -4m to 0m)
```
    [REACTOR]───[BATTERIES]
        │            │
    [THERMAL]────[COOLANT]
     SYSTEMS      LOOPS
        │            │
    [FUEL]───────[RCS]
     TANKS       THRUSTERS
        │
    [MAIN ENGINE]
```

**Components:**
- Reactor: (0, -2, -5) - 3 MW nuclear reactor
- Battery Banks: (±4, -2, -5) - 10 kWh each
- Thermal Radiators: (±8, 0, 0) - Deployable panels
- Coolant System: (±2, -2, 0) - Primary loops
- Fuel Tanks: (±3, -2, -10) - Main propellant storage
- RCS Clusters: 4x positions around hull
- Main Engine: (0, -3, -22) - Primary thrust

## Weapons Layout

### Turret Mounts

**1. Dorsal Autocannon Turret** (PD-20)
- Location: (0, +6, +10)
- Type: Point Defense, 20mm
- Arc: 360° azimuth, -30° to +80° elevation
- Role: Anti-missile, close defense
- Magazine: Below turret at (0, +4, +10), 500 rounds
- Power: 500W firing, 100W tracking
- Cooling: Air-cooled barrel

**2. Forward Railgun** (RG-100)
- Location: (0, +1, +18)
- Type: Fixed forward mount with ±20° gimbal
- Arc: -20° to +20° azimuth, -15° to +15° elevation
- Role: Anti-ship, long range
- Magazine: (0, 0, +16), 30 tungsten slugs
- Power: 15 MW per shot (capacitor)
- Cooling: Liquid cooling loop to main radiators

**3. Port/Starboard Missile Launchers** (VLS)
- Locations: (±6, +2, +8)
- Type: Vertical Launch System
- Capacity: 4 missiles each (8 total)
- Missile Types: MRM (multi-role)
- Reload: Internal magazine, 30s cycle
- Power: 500W per launcher

**4. Ventral Laser Turret** (PL-5)
- Location: (0, -3, +5)
- Type: Pulse Laser, 5 MW
- Arc: 180° azimuth, -80° to +30° elevation
- Role: Point defense, anti-missile
- Aperture: 0.5m diameter
- Power: 10 MW (20% efficient)
- Cooling: Dedicated cryogenic system

**5. Forward Particle Beam** (NPB-50)
- Location: (0, 0, +22)
- Type: Fixed forward, neutral particle beam
- Arc: ±5° gimbal (near-fixed)
- Role: Heavy anti-ship
- Power: 50 MW pulse
- Cooling: Superconducting magnets, cryo

## Subsystem Locations

### Navigation & Sensors (Deck 1)
- **Nav Computer**: Bridge, (0, +5, +20)
- **Star Tracker**: Obs dome, (0, +6, +22)
- **Radar Array**: Forward nose, (0, +4, +24)
- **Optical Sensors**: Obs dome, 360° coverage
- **ESM/ELINT**: Dorsal spine, (0, +6, 0)

### Communications (Distributed)
- **VHF/UHF**: Ventral, (0, -3, +10)
- **S-band**: Dorsal, (0, +6, +5)
- **X-band**: Forward, (0, +3, +23)
- **Laser Comm**: Obs dome, (0, +6, +22)

### Countermeasures (External)
- **Chaff Launchers**: Port/starboard, (±7, +2, +12), 4 tubes each
- **Flare Launchers**: Aft ventral, (0, -2, -18), 6 tubes
- **ECM Array**: Dorsal, (0, +5, -5)

### Docking System
- **Forward Port**: (0, +2, +25), androgynous type
- **Dorsal Port**: (0, +6, 0), probe type
- **Ventral Port**: (0, -3, -5), drogue type

### Landing System (Retractable)
- **Nose Gear**: (0, -4, +15), oleopneumatic
- **Port Main Gear**: (-5, -4, -5)
- **Starboard Main Gear**: (+5, -4, -5)
- **Gear Bay**: (±5, -3, -5), hydraulically actuated

### Environmental & Life Support
- **Atmosphere Processors**: (0, +4, +10), main compartment
- **O2 Generators**: (±2, +4, +10)
- **CO2 Scrubbers**: (±2, +4, +8)
- **Emergency O2**: (0, +5, +12), 50 kg reserve
- **Radiation Shielding**: Reactor room walls, 30cm borated polyethylene

### Cargo System
- **Main Bay**: (0, +1, 0), 200 m³, 20 tons capacity
- **Bay Doors**: Ventral, (0, -1, ±8), 4m x 8m
- **Cargo Crane**: (0, +3, 0), 5-ton capacity
- **Transfer Locks**: Port/starboard, (±8, +1, 0)

## Power Distribution

### Generation
- **Reactor**: (0, -2, -5), 3 MW continuous
- **Solar Arrays** (Optional): Deployable wings, (±12, +2, 0), 50 kW total

### Distribution Buses
- **Bus A** (Main): Reactor → Forward systems
- **Bus B** (Backup): Reactor → Aft systems
- **Emergency Bus**: Batteries → Critical systems only

### Circuit Breakers (Engineering Station)
1. Environmental/Life Support - Priority 10 - Bus A
2. Navigation Computer - Priority 9 - Bus A
3. Flight Control - Priority 8 - Bus A
4. Thermal Management - Priority 10 - Bus A
5. Main Engine - Priority 8 - Bus B
6. RCS - Priority 8 - Bus B
7. Railgun Capacitors - Priority 6 - Bus B
8. Laser Systems - Priority 7 - Bus A
9. Missile Systems - Priority 5 - Bus B
10. Communications - Priority 6 - Bus A
11. Sensors/Radar - Priority 7 - Bus A
12. Countermeasures - Priority 3 - Bus B

## Thermal Management

### Heat Sources
- Reactor: 300 kW waste heat
- Railgun: 10 MW per shot (brief)
- Laser: 8 MW continuous when firing
- Particle Beam: 40 MW during shot
- Main Engine: 2 MW during burn
- Electronics: 50 kW continuous

### Cooling Systems
- **Primary Radiators**: Deployable panels, (±8, 0, ±10), 4x panels, 1 MW each
- **Secondary Radiators**: Fixed dorsal, (0, +6, -10 to +10)
- **Coolant Loops**:
  - Loop 1: Reactor → Primary radiators
  - Loop 2: Weapons → Secondary radiators
  - Loop 3: Electronics → Fixed radiators
- **Emergency Heat Dump**: Vent coolant to space (last resort)

## Center of Mass Management

### Nominal Configuration
- **CoM**: (0, 0, 0) when fully fueled
- **Fuel Consumption**: CoM shifts aft as fuel depleted
- **Cargo Loading**: CoM varies with cargo distribution
- **Weapon Firing**: Minimal CoM shift (low mass projectiles)

### CoM Tracking Systems
- **Fuel Level Sensors**: Monitor tank levels
- **Cargo Load Cells**: Track cargo mass and position
- **Ammo Counters**: Track magazine mass
- **Flight Computer**: Auto-compensates RCS for CoM shift

## Station Locations & Access

### Bridge/Flight Deck (Primary)
Location: (0, +5, +20)
Seats: 2 (Pilot, Co-pilot)
Stations Accessible:
- Flight Control (primary)
- Navigation
- Captain's station (all systems overview)
- Forward observation

### Weapons Station
Location: (-5, +2, +15)
Seats: 1
Controls:
- All weapon systems
- Fire control computer
- Targeting sensors
- Countermeasures

### Engineering Station
Location: (-5, +2, +5)
Seats: 1
Controls:
- Power distribution
- Thermal management
- Damage control
- Propulsion systems

### Tactical Station
Location: (-5, +2, -5)
Seats: 1
Controls:
- Sensors (radar, optical, ESM)
- Electronic warfare
- Threat assessment
- Communications

### Life Support/Science
Location: (+4, +5, +10)
Seats: 1
Controls:
- Environmental systems
- Medical systems
- Cargo management
- Docking control

## Damage Zones

Ship divided into 12 damage zones for hit location:

1. **Forward Nose** (+18 to +25 Z): Sensors, radar, docking port
2. **Bridge/Command** (+10 to +18 Z, Y > +4): Critical crew area
3. **Forward Weapons** (+5 to +15 Z): Railgun, missiles
4. **Port Wing** (X < -6): Radiators, fuel
5. **Starboard Wing** (X > +6): Radiators, fuel
6. **Cargo Bay** (-5 to +5 Z, -2 < Y < +2): Cargo, structural
7. **Engineering Core** (-10 to 0 Z, Y < 0): Reactor, batteries
8. **Propulsion** (-15 to -25 Z): Main engine, fuel feeds
9. **Dorsal Hull** (Y > +4): PD turret, sensors
10. **Ventral Hull** (Y < -2): Laser turret, landing gear
11. **Port Systems** (X < -4, other): Subsystems
12. **Starboard Systems** (X > +4, other): Subsystems

### Critical Hit Effects
- **Bridge Hit**: Crew casualties, control loss
- **Reactor Hit**: Power loss, radiation leak, possible meltdown
- **Fuel Tank Hit**: Propellant leak, possible explosion
- **Weapons Hit**: System disabled, magazine explosion risk
- **Radiator Hit**: Thermal overload, cascading failures
- **Engine Hit**: Thrust loss, fuel leak

## Mass Budget

| Component | Mass (kg) | Location |
|-----------|-----------|----------|
| Hull Structure | 15,000 | Distributed |
| Reactor + Shielding | 8,000 | (0,-2,-5) |
| Main Engine | 5,000 | (0,-3,-22) |
| Fuel (full) | 45,000 | (±3,-2,-10) |
| RCS + Propellant | 3,000 | Distributed |
| Weapons Systems | 4,000 | Various |
| Sensors/Comms | 1,000 | Forward/dorsal |
| Life Support | 2,000 | Deck 1 |
| Cargo (max) | 20,000 | (0,+1,0) |
| Crew + Supplies | 1,000 | Deck 1 |
| **Total (empty)** | **50,000** | |
| **Total (fueled)** | **95,000** | |
| **Total (max)** | **115,000** | |

## UI Screen Mapping

### Screen 1: Flight Control
**Location**: Bridge, main console
**Access**: Pilot seat, always visible
**Displays**:
- Navball (attitude indicator)
- Velocity vector
- Altitude/orbit display
- TWR, ΔV remaining
- SAS/Autopilot status
- Engine throttle
- RCS control
- Gimbal angles

**Controls**:
- Throttle slider
- SAS toggle
- Autopilot engage
- RCS enable/disable
- Gimbal control
- Maneuver node execution

### Screen 2: Navigation & Mission
**Location**: Bridge, secondary console
**Access**: Co-pilot seat
**Displays**:
- Orbital map
- Maneuver planning
- Mission objectives
- Waypoints
- Rendezvous data
- Navigation computer status

**Controls**:
- Maneuver creation
- Warp time
- Set waypoint
- Mission select

### Screen 3: Weapons Control
**Location**: Weapons station
**Access**: Weapons officer seat
**Displays**:
- All weapons status
- Ammunition counts
- Target list
- Firing solutions
- Weapon temperature
- Capacitor charge
- Turret positions

**Controls**:
- Select weapon
- Select target
- Fire
- Engage/Disengage
- Fire mode select
- Safety toggle
- Countermeasures deploy

### Screen 4: Tactical/Sensors
**Location**: Tactical station
**Access**: Tactical officer seat
**Displays**:
- Radar scope
- Target tracking
- Threat assessment
- ESM contacts
- Electronic warfare status
- Communications links

**Controls**:
- Scan mode
- Track target
- Activate ECM
- Communications
- IFF query

### Screen 5: Engineering
**Location**: Engineering station
**Access**: Engineer seat
**Displays**:
- Power generation/demand
- Circuit breakers
- Thermal status
- Coolant flow
- Battery charge
- System health
- Damage report

**Controls**:
- Circuit breaker toggles
- EMCON level
- Radiator deploy/retract
- Emergency protocols
- Damage control priorities

### Screen 6: Life Support
**Location**: Science/Medical station
**Access**: Science officer seat
**Displays**:
- Atmosphere (pressure, O2, CO2, temp)
- Radiation levels
- Hull integrity
- Cargo inventory
- Docking status
- Landing gear

**Controls**:
- Emergency O2 activate
- Seal compartment
- Cargo crane
- Docking initiate
- Landing gear deploy/retract

## Control Scheme

### Keyboard Mapping
```
[1-6]     Switch Stations (1=Flight, 2=Nav, 3=Weapons, 4=Tactical, 5=Eng, 6=Life)
[WASD]    Flight: Pitch/Yaw | Weapons: Target select | UI: Navigate
[QE]      Flight: Roll | UI: Scroll
[Shift]   Flight: Throttle up | UI: Page up
[Ctrl]    Flight: Throttle down | UI: Page down
[Space]   Flight: RCS translate | Weapons: Safety toggle
[Tab]     Cycle targets
[F]       Weapons: Fire | UI: Activate selected
[R]       Reload / Retract
[T]       SAS toggle / Track target
[G]       Landing gear toggle
[V]       Camera view toggle
[M]       Map view
[X]       Kill throttle / Cancel
[Z]       Max throttle
[,]       Time warp decrease
[.]       Time warp increase
[ESC]     Pause menu
```

### Mouse
- **Left Click**: Activate button, fire weapon
- **Right Click**: Context menu, cancel
- **Scroll**: Zoom, throttle adjust
- **Drag**: Rotate camera, adjust sliders

## Integration Checklist

- [x] Physical layout defined
- [ ] Spacecraft class updated with weapons
- [ ] All subsystems positioned with coordinates
- [ ] Mass/CoM calculations integrated
- [ ] Power distribution configured
- [ ] Thermal system mapped
- [ ] UI screens designed
- [ ] Control scheme mapped
- [ ] Damage zones implemented
- [ ] Complete gameplay loop
