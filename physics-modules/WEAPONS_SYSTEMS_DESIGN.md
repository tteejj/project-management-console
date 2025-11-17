# Weapon Systems Design

## Overview

This document defines the complete weapon systems for spacecraft combat, including kinetic weapons, missiles, and energy weapons with realistic physics, targeting, and ammunition management.

## Weapon Categories

### 1. Kinetic Weapons

Projectile-based weapons that use physical mass to damage targets.

#### 1.1 Autocannons
**Concept:** Rapid-fire ballistic weapons with moderate damage and range

**Physics:**
- Muzzle velocity: 1000-3000 m/s
- Projectile mass: 0.1-5 kg
- Rate of fire: 60-600 rounds/minute
- Recoil force: F = (mass × velocity) / time_between_shots
- Ballistic trajectory affected by:
  - Initial velocity vector
  - Gravity (if near planetary body)
  - No air resistance (space)
  - Coriolis effect (rotating reference frames)

**Ammunition:**
- Magazine capacity: 200-2000 rounds
- Reload time: 5-15 seconds
- Ammo types:
  - **AP (Armor Piercing):** High penetration, low explosive
  - **HE (High Explosive):** Area damage, lower penetration
  - **Incendiary:** Thermal damage, ignites fuel/oxygen
  - **Proximity Fuse:** Explodes near target (flak)

**Turret Mechanics:**
- Rotation speed: 15-60 °/s (yaw/pitch)
- Arc of fire:
  - Forward guns: ±60° horizontal, ±30° vertical
  - Dorsal turrets: 270° horizontal, ±45° vertical
  - Point defense: 360° horizontal, ±80° vertical
- Tracking accuracy: ±0.5° to ±5° depending on turret quality
- Lead calculation required for moving targets

**Power Requirements:**
- Autoloader: 50W continuous, 500W during reload
- Turret motors: 200-1000W when rotating
- Fire control computer: 100W continuous

#### 1.2 Railguns
**Concept:** Electromagnetic accelerators firing hypersonic projectiles

**Physics:**
- Muzzle velocity: 5000-15000 m/s
- Projectile mass: 0.5-50 kg
- Rate of fire: 1-10 rounds/minute (capacitor recharge)
- Kinetic energy: KE = 0.5 × m × v²
- Penetration depth: Based on kinetic energy and armor density
- Electromagnetic pulse: Can damage electronics on hit

**Power Requirements:**
- Capacitor charge: 500 kW for 10-30 seconds
- Per-shot energy: 5-50 MJ
- Standby power: 1 kW (cooling, fire control)
- Peak power draw: Can brownout entire ship if not managed

**Ammunition:**
- Solid slugs (tungsten, depleted uranium)
- Magazine: 20-100 rounds
- Reload time: 30-60 seconds
- No propellant needed (electromagnetic acceleration)

**Thermal:**
- Heat generation: 10-30% of shot energy as waste heat
- Requires active cooling between shots
- Overheat lockout after 5-10 rapid shots

#### 1.3 Mass Drivers
**Concept:** Large-scale kinetic weapons for capital ship combat

**Physics:**
- Muzzle velocity: 10000-50000 m/s
- Projectile mass: 50-1000 kg
- Rate of fire: 1 shot per 1-5 minutes
- Recoil: Significant momentum transfer to firing ship
- Time to target: Distance / velocity (can be minutes)

**Applications:**
- Orbital bombardment
- Station-to-station combat
- Capital ship engagement
- Asteroid deflection

### 2. Missile Systems

Self-propelled guided weapons with various warheads and guidance modes.

#### 2.1 Missile Types

**Short Range Missiles (SRM)**
- Range: 5-50 km
- Burn time: 10-30 seconds
- Guidance: Active radar + IR seeker
- Warhead: 10-50 kg HE
- Speed: 500-2000 m/s
- Countermeasures vulnerability: High

**Medium Range Missiles (MRM)**
- Range: 50-500 km
- Burn time: 30-120 seconds
- Guidance: Inertial + active radar + IR terminal
- Warhead: 50-200 kg HE, shaped charge, or fragmentation
- Speed: 1000-5000 m/s
- Mid-course correction capability

**Long Range Missiles (LRM)**
- Range: 500-5000 km
- Burn time: 60-300 seconds
- Guidance: Inertial navigation + datalink + terminal seeker
- Warhead: 100-500 kg, nuclear option
- Speed: 2000-10000 m/s
- Can coast to extend range

**Torpedoes**
- Range: 1000-10000 km
- Burn time: Variable (can coast for hours)
- Guidance: Passive sensors, low observability
- Warhead: 200-2000 kg, often nuclear
- Speed: 500-3000 m/s (lower to conserve fuel)
- Stealth-optimized

#### 2.2 Missile Physics

**Propulsion:**
```
Thrust = mass_flow_rate × exhaust_velocity
Acceleration = Thrust / current_mass
ΔV = exhaust_velocity × ln(initial_mass / final_mass)
```

**Trajectory Types:**
- **Direct:** Shortest path, fastest time to target
- **Lead Pursuit:** Intercept moving target at future position
- **Pure Pursuit:** Follow target (inefficient, used by dumb missiles)
- **Proportional Navigation:** Most efficient intercept
- **Loft:** High-altitude arc to extend range
- **Sea-skimming/Low-approach:** Evade detection and CIWS

**Guidance Modes:**
- **Inertial:** Gyroscopes and accelerometers (no emissions, drift over time)
- **Command:** Datalink from launch platform (requires LOS, can be jammed)
- **Beam Riding:** Follow targeting laser/radar beam
- **Active Radar:** Missile has own radar (detectable but autonomous)
- **Passive Radar:** Homes on enemy emissions (undetectable)
- **IR Seeker:** Infrared tracking (short range, flare vulnerable)
- **Optical:** Camera-based terminal guidance (high accuracy)

**Countermeasure Interaction:**
- Chaff: -40% to -80% radar seeker effectiveness
- Flares: -50% to -90% IR seeker effectiveness
- ECM jamming: Degrades active radar seekers
- Laser dazzler: Defeats optical seekers
- Hard-kill: Point defense guns/missiles intercept

#### 2.3 Missile Mechanics

**Launch Sequence:**
1. Target acquisition and lock
2. Missile pre-flight check (seeker test, gyro spin-up)
3. Launch (cold launch or hot launch)
4. Booster ignition (if applicable)
5. Guidance handoff to missile
6. Mid-course updates via datalink
7. Terminal seeker activation
8. Fuzing and detonation

**Magazine System:**
- Vertical launch system (VLS): Fast reload, any direction launch
- External hardpoints: No reload, drag penalty
- Internal bay: Stealth, slower reload
- Reload time: 5-60 seconds depending on system

**Missile State:**
- Ready: In launcher, pre-flight complete
- Launched: In flight, tracking
- Tracking: Seeker locked on target
- Terminal: Final approach, ARM fuse
- Hit/Miss: Impact or self-destruct

### 3. Energy Weapons

Directed energy weapons using electromagnetic radiation or particle beams.

#### 3.1 Lasers

**Concept:** Coherent light beam that delivers energy to target surface

**Physics:**
- Power: 10 kW to 10 MW
- Wavelength: Optimized for space (no atmosphere):
  - UV (10-400 nm): High energy, short range
  - Visible (400-700 nm): Moderate
  - IR (700 nm - 1 mm): Long range, lower energy
- Beam divergence: θ = 1.22 × λ / D (aperture diameter)
- Energy on target: P × time_on_target
- Damage: Thermal (ablation, melting)

**Damage Mechanics:**
```
Energy delivered = Power × dwell_time
Heat absorbed = Energy × (1 - reflectivity)
Temperature rise = Heat / (mass × specific_heat)
Damage threshold: Ablation at ~3000K, structural failure varies
```

**Types:**
- **Pulse Laser:** High peak power, short duration (missile defense)
- **Continuous Wave:** Sustained beam (armor cutting, sensor blinding)
- **X-ray Laser:** Very high energy, very short range (nuclear pumped)

**Limitations:**
- Requires line of sight (no over-horizon)
- Diffraction limits range: spot size = range × divergence
- Target reflectivity reduces effectiveness (mirrors as armor)
- Thermal bloom: Beam distortion from heating its own path
- Power consumption: Massive electrical draw
- Waste heat: 50-80% of input power as heat

**Tactical Use:**
- Point defense: Burn through missile casings
- Sensor blinding: Overload enemy optics
- Electronic warfare: Burn through sensor arrays
- Anti-armor: Sustained dwell to penetrate
- Communication: Laser comm links (secondary use)

#### 3.2 Particle Beams

**Concept:** Accelerated charged particles (electrons, protons, ions)

**Physics:**
- Particle energy: 1-100 MeV
- Beam current: 1-1000 mA
- Power: Voltage × Current (MW to GW range)
- Damage: Ionization, heating, radiation
- Range in space: 100-10000 km (limited by beam dispersion)
- Magnetic deflection: Charged particles bend in B-fields

**Types:**
- **Neutral Particle Beam (NPB):** Ionize, accelerate, neutralize
  - Not deflected by magnetic fields
  - Longer range
  - More complex
- **Charged Particle Beam (CPB):** Electrons or ions
  - Simpler to generate
  - Deflected by fields
  - Creates EM pulse

**Damage Mechanics:**
- Deep penetration (not just surface)
- Radiation damage to electronics
- Induces secondary radiation in target
- Can penetrate armor that stops lasers

**Power Requirements:**
- 10-1000 MW during firing
- Capacitor banks for pulse mode
- Requires dedicated reactor or massive capacitors
- Cooling: Enormous heat generation

#### 3.3 Plasma Weapons

**Concept:** Magnetically contained plasma projectile or jet

**Physics:**
- Temperature: 10,000-100,000 K
- Containment: Magnetic bottle
- Velocity: 100-10000 km/s (for projectiles)
- Range: Very limited (containment breaks down)
- Damage: Extreme thermal + EM effects

**Types:**
- **Plasma Cannon:** Contained bolts (sci-fi, questionable physics)
- **Plasma Torch:** Close range cutting tool (realistic)
- **Plasma Jet:** Propulsion + weapon (VASIMR variant)

**Limitations:**
- Range severely limited by containment breakdown
- Massive power requirements
- Best suited for very close range (<1 km)

## Fire Control System

### Targeting Computer

**Functions:**
1. **Target Acquisition**
   - Radar detection and tracking
   - Optical/IR identification
   - IFF (Identification Friend or Foe)
   - Threat prioritization

2. **Ballistic Solutions**
   - Lead calculation for moving targets
   - Projectile time of flight
   - Gravity compensation
   - Coriolis effect (if in rotating frame)

   ```
   // Lead calculation
   time_to_intercept = solve_intercept_triangle(
     target_position,
     target_velocity,
     projectile_speed,
     firing_position
   )

   firing_solution = {
     azimuth: angle_to(predicted_position),
     elevation: angle_with_gravity_compensation(),
     lead_time: time_to_intercept
   }
   ```

3. **Firing Constraints**
   - Is turret in arc?
   - Is turret tracking speed sufficient?
   - Is ammunition available?
   - Is power available?
   - Will recoil destabilize ship?
   - Is target in range?
   - Friendly fire check

4. **Engagement Modes**
   - **Manual:** Operator aims and fires
   - **Computer Assisted:** Computer provides lead, operator fires
   - **Auto-Track:** Computer tracks, operator fires
   - **Point Defense Auto:** Fully autonomous (for missiles/fighters)
   - **Barrage:** Saturate area with fire
   - **Salvo:** Coordinated multi-weapon strike

### Turret Tracking

**Physics:**
```
// Angular velocity required
ω_required = d(angle_to_target) / dt

// Can turret track?
can_track = ω_required < ω_max_turret

// Tracking error
error = |actual_pointing - desired_pointing|

// Lead the lead (account for turret slew time)
total_lead = ballistic_lead + (turret_slew_time × target_angular_velocity)
```

**Gyroscopic Stabilization:**
- Compensate for ship rotation
- Maintain inertial pointing
- Account for ship maneuvers

**Power Draw:**
```
P_turret = P_base + P_rotation + P_elevation
P_rotation = τ × ω (torque × angular velocity)
P_elevation = m × g × h / t + τ × ω
```

## Ammunition Management

### Magazine System

**Structure:**
```typescript
interface Magazine {
  id: string;
  weaponType: 'autocannon' | 'railgun' | 'missile';
  capacity: number;
  current: number;
  ammoTypes: AmmoLoadout[];
  autoloaderStatus: 'ready' | 'loading' | 'jammed' | 'empty';
  reloadTimeSeconds: number;
  location: { x: number; y: number; z: number }; // For center of mass
}

interface AmmoLoadout {
  type: 'AP' | 'HE' | 'Incendiary' | 'Proximity' | 'EMP';
  count: number;
  mass: number; // kg per round
}
```

### Reload Mechanics

**Autoloader Cycle:**
1. Extract spent casing/magazine
2. Move new round from magazine
3. Load into chamber/launcher
4. Lock and ready
5. Update count

**Time Calculation:**
```
reload_time = base_time + (rounds_to_load × time_per_round)
```

**Failures:**
- Jam probability: 0.1% - 5% per shot (depends on reliability)
- Clearing jam: 10-60 seconds
- Magazine damage: Can lose entire loadout

### Center of Mass Tracking

As ammunition is expended:
```
mass_change = -rounds_fired × round_mass
CoM_new = (total_mass × CoM_old - mass_change × magazine_location) / (total_mass - mass_change)
```

This affects:
- Ship handling
- RCS effectiveness
- Fuel efficiency
- Docking alignment

## Damage Model

### Armor System

**Armor Types:**
- **Whipple Shield:** Spaced armor for micrometeorites and small projectiles
- **Composite:** Ceramic + metal layers
- **Reactive:** Explosive panels that counter shaped charges
- **Ablative:** Sacrificial material for energy weapons
- **Reflective:** Mirrors for laser defense

**Penetration Physics:**
```
// Kinetic penetration
penetration_depth = (projectile_mass × velocity²) / (armor_density × armor_strength × area)

// Energy weapon
ablation_depth = (energy_absorbed) / (ablation_energy_per_kg × density)

// Explosive
spall_radius = warhead_mass^(1/3) × overpressure_factor
```

### Hit Location System

**Ship Zones:**
- **Hull:** Structural integrity
- **Turret:** Weapon disabled
- **Engine:** Propulsion damage
- **Reactor:** Power loss, potential meltdown
- **Magazine:** Explosion risk
- **Radiator:** Thermal overload
- **Sensors:** Blinded
- **RCS:** Maneuvering degraded

**Hit Chance:**
```
hit_probability = base_accuracy × range_modifier × target_size_modifier × ECM_modifier × evasion_modifier

range_modifier = max(0, 1 - (range / max_range)²)
target_size_modifier = target_cross_section / reference_cross_section
```

## Weapon Integration

### Power Requirements

**Priority Levels:**
- **Lasers:** Priority 7 (high power, combat critical)
- **Railguns:** Priority 6 (very high power, can wait for capacitor charge)
- **Missile Systems:** Priority 5 (moderate, guidance computers)
- **Autocannons:** Priority 5 (autoloaders, turret motors)
- **Fire Control:** Priority 8 (essential for all weapons)

**Firing Coordination:**
```
// Prevent brownout
if (weapon.powerDraw + current_load > generation_capacity) {
  if (capacitor_charged) {
    fire_from_capacitor();
  } else {
    queue_shot(); // Wait for power availability
  }
}
```

### Thermal Integration

**Heat Generation:**
- Autocannon: 50 kW per shot (barrel heating)
- Railgun: 5-50 MW per shot (resistive losses)
- Laser: 500 kW - 5 MW continuous (inefficiency heat)
- Missile: Minimal (heat at launch point only)

**Cooling:**
- Barrel cooling: Radiative + active coolant
- Capacitor cooling: Liquid cooling loops
- Laser cavity: Cryogenic cooling for high power

### Recoil Effects

**Momentum Conservation:**
```
ship_velocity_change = -(projectile_mass × muzzle_velocity) / ship_mass
ship_rotation_change = (force × distance_from_CoM) / moment_of_inertia
```

**RCS Compensation:**
- Fire opposite RCS thrusters to counter recoil
- Stabilize ship after firing
- Power requirement: Based on projectile momentum

## Gameplay Integration

### Weapons Station UI

**Display Elements:**
1. **Tactical Overview**
   - Radar scope with contacts
   - Range rings
   - Weapon range overlays
   - Threat indicators

2. **Weapon Status Panel**
   - Each weapon: Status, ammo, temp, power
   - Ready indicators
   - Reload progress bars
   - Turret rotation indicators

3. **Targeting Reticle**
   - Lead indicator (predicted intercept)
   - Range to target
   - Closure rate
   - Hit probability
   - Time to weapons range

4. **Fire Control**
   - Weapon select
   - Fire mode (single/burst/auto)
   - Safety (safe/armed)
   - Missile seeker mode
   - Engagement mode

### Combat Loop

**Player Actions:**
1. **Detect** - Use sensors to find targets
2. **Identify** - IFF check, threat assessment
3. **Track** - Maintain lock on target
4. **Engage** - Select weapon and fire mode
5. **Fire** - Execute attack
6. **Assess** - Battle damage assessment
7. **Re-engage** or **Evade**

**AI/Automated Systems:**
- Point defense auto-engages incoming missiles
- Threat warning alerts operator
- Auto-turret slewing to targets
- Ammunition allocation recommendations
- Power management during combat

### Mission Scenarios

**1. Patrol/Interception**
- Long range detection
- Intercept course
- Missile engagement at range
- Energy weapons for finishing

**2. Point Defense**
- Protect friendly assets
- Engage incoming threats
- Prioritize by proximity
- Coordinate multiple weapons

**3. Strike Mission**
- Approach target
- Launch standoff weapons
- Evade defenses
- Battle damage assessment

**4. Dogfight**
- Close range maneuvering
- Autocannon/short-range missiles
- RCS and main engine coordination
- Out-maneuver opponent

## Performance Specifications

### Example Weapon Stats

**Light Autocannon (PD-20)**
- Caliber: 20mm
- Rate of Fire: 600 RPM
- Muzzle Velocity: 1500 m/s
- Magazine: 500 rounds
- Reload: 10 seconds
- Power: 500W
- Effective Range: 5 km
- Role: Point defense

**Medium Railgun (RG-100)**
- Caliber: 100mm
- Rate of Fire: 6 RPM
- Muzzle Velocity: 8000 m/s
- Magazine: 30 rounds
- Reload: 45 seconds
- Power: 15 MW per shot
- Capacitor Charge: 25 seconds
- Effective Range: 1000 km
- Role: Anti-ship

**Pulse Laser (PL-5)**
- Power: 5 MW peak
- Pulse Duration: 100 ms
- Pulse Rate: 1 Hz
- Wavelength: 1064 nm (IR)
- Beam Divergence: 0.5 µrad
- Power Draw: 10 MW (20% efficient)
- Effective Range: 100 km
- Role: Missile defense, sensor blinding

**Multi-Role Missile (MRM-50)**
- Length: 3m
- Mass: 150 kg (50 kg warhead)
- Motor: Solid rocket, 90s burn
- Speed: 3000 m/s
- Range: 250 km
- Guidance: INS + Active Radar + IR
- Warhead: Shaped charge or HE-FRAG
- Role: Anti-ship, anti-missile

## Next Steps

1. Implement weapon system classes (kinetic, missiles, energy)
2. Create fire control computer
3. Build ammunition management
4. Integrate with power and thermal systems
5. Create weapons UI station
6. Build targeting and ballistics solver
7. Implement damage model
8. Create combat scenarios and missions
