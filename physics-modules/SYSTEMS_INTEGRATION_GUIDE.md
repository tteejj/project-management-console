# Spacecraft Systems Integration Guide

## Overview
This guide explains how all spacecraft subsystems are integrated and how they interact during gameplay. All critical gaps from the gap analysis have been addressed and integrated into the game systems.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SPACECRAFT MASTER                        │
│                   (spacecraft.ts)                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │               │
┌───────▼────────┐ ┌──▼──────────┐ ┌─▼──────────────┐
│ Physics Engine │ │ Systems     │ │ Center of Mass │
│ (ship-physics) │ │ Integrator  │ │ (center-of-mass│
└───────┬────────┘ └──┬──────────┘ └─┬──────────────┘
        │              │               │
        │         ┌────▼────┐          │
        │         │ Power   │          │
        │         │ Mgmt    │          │
        │         └────┬────┘          │
        │              │               │
┌───────┴──────────────┴───────────────┴──────────────┐
│               SUBSYSTEMS LAYER                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ Weapons  │ │   RCS    │ │   Fuel   │            │
│  │ Control  │ │ System   │ │ System   │            │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘            │
│       │            │             │                   │
│  ┌────▼─────┐ ┌───▼──────┐ ┌───▼──────┐            │
│  │ Kinetic  │ │ Thermal  │ │  Cargo   │            │
│  │ Weapons  │ │ System   │ │ System   │            │
│  └──────────┘ └──────────┘ └──────────┘            │
└──────────────────────────────────────────────────────┘
```

## Critical Systems Integration

### 1. Center of Mass (CoM) Tracking System

**Location**: `src/center-of-mass.ts`
**Integration Points**: `spacecraft.ts:152-163, 336-352, 363-375`

The CoM system is the foundation for realistic spacecraft dynamics. It tracks all mass components and calculates:

#### Mass Components Tracked:
- **Hull Structure**: 15,000 kg (fixed)
- **Reactor + Shielding**: 8,000 kg (fixed)
- **Main Engine**: 5,000 kg (fixed)
- **Weapons Systems**: 4,000 kg (fixed)
- **Sensors/Comms**: 1,000 kg (fixed)
- **Life Support**: 2,000 kg (fixed)
- **Crew + Supplies**: 1,000 kg (can move slightly)
- **Fuel Tanks**: Variable mass (updated each frame)
  - Main tank 1 (port): Updated as fuel consumed
  - Main tank 2 (starboard oxidizer): Updated as oxidizer consumed
  - RCS tank: Updated with RCS propellant consumption
- **RCS Propellant**: Variable mass (updated each frame)
- **Cargo**: Variable mass and position (updated when loaded/unloaded)
- **Ammunition**: Variable mass (updated as rounds fired)
  - Autocannon magazines
  - Railgun magazines
  - Missile bays

#### Update Sequence (Each Frame):
```typescript
// spacecraft.ts update() method:

// 1. Fuel consumption
fuel.consumeFuel('main_1', fuelAmount);
fuel.consumeFuel('main_2', oxidizerAmount);
fuel.consumeFuel('rcs', rcsAmount);

// 2. Update CoM with new fuel masses
for (const tank of fuelState.tanks) {
  comSystem.updateMass(`fuel_${tank.id}`, tank.fuelMass);
}

// 3. Update RCS propellant mass
comSystem.updateMass('rcs_propellant', rcsTankState.fuelMass);

// 4. Update ammunition mass (as rounds fired)
const magazines = weapons.getMagazines();
for (const mag of magazines) {
  comSystem.updateMass(`ammo_${mag.id}`, mag.mass);
}

// 5. CoM offset is now current and ready for physics
const comOffset = comSystem.getCoM();
const momentOfInertia = comSystem.getMomentOfInertia();
```

#### Game Impact:
- **Dynamic Flight Characteristics**: Ship handles differently as fuel depletes
- **Cargo Loading Effects**: Loading 10,000 kg of cargo forward shifts CoM forward, affecting pitch authority
- **Combat Tactics**: Firing heavy railgun rounds reduces forward mass, slightly shifting CoM aft
- **Emergency Procedures**: Jettisoning cargo in an emergency instantly affects handling

---

### 2. Weapons Power Management & Brownout Enforcement

**Location**: `src/weapons-control.ts:416-474`
**Integration Points**: `spacecraft.ts:410-414, 595-599`

The power brownout system prevents weapons from firing when insufficient power is available.

#### Power Requirements (Watts):
- **Autocannon**: 500 W (tracking + firing)
- **Railgun**: 15,000,000 W (15 MW from capacitor discharge)
- **Missile Launcher**: 500 W (minimal power)
- **Pulse Laser**: 10,000,000 W (10 MW continuous)
- **Particle Beam**: 50,000,000 W (50 MW pulse)

#### Power Budget Check (Each Frame):
```typescript
// spacecraft.ts:
const reactorPowerW = electrical.reactor.currentOutputKW * 1000;
const batteryPowerW = electrical.battery.maxDischargeRateKW * 1000;
const totalAvailablePowerW = reactorPowerW + batteryPowerW;
weapons.setPowerAvailable(totalAvailablePowerW);

// weapons-control.ts:
private checkPowerForWeapon(weaponType): boolean {
  const powerSurplus = this.powerAvailable - this.totalPowerDraw;

  if (powerSurplus < requiredPower) {
    this.events.push({
      type: 'POWER_INSUFFICIENT',
      data: { weaponType, required, available, deficit }
    });
    return false; // Weapon cannot fire
  }
  return true;
}
```

#### Game Impact:
- **Tactical Decisions**: Fire railgun OR particle beam, not both simultaneously (65 MW total)
- **Power Management**: Divert power from life support to weapons in combat
- **Emergency Situations**: Reactor damage limits weapon options
- **Brownout Events**: Weapons automatically shed during system brownout

#### Integration with Power Management System:
```typescript
// systems-integrator.ts:
// Weapons registered as priority 7 power consumer
// Below life support (10), navigation (9), but above comms (6)

powerManagement.registerConsumer({
  id: 'weapons',
  priority: 7,
  maxPowerW: 75000000, // 75 MW max
  essential: false // Can be shed during brownout
});

// During brownout, weapons are automatically disabled
if (powerDeficit > threshold) {
  weapons.weaponsSafety = true; // Master safety engaged
}
```

---

### 3. RCS Center of Mass Compensation

**Location**: `src/rcs-system.ts:50-51, 359-405`
**Integration Points**: `spacecraft.ts:362-368, 501-504`

RCS thrusters compensate for shifting CoM when generating torque for attitude control.

#### Physical Principle:
Torque = r × F, where r is the position vector from CoM to thruster

Without CoM compensation:
- As fuel depletes forward, CoM shifts aft
- Forward RCS thrusters have reduced moment arm
- Aft RCS thrusters have increased moment arm
- Ship becomes harder to pitch up, easier to pitch down

With CoM compensation:
- Moment arm calculated dynamically: `r_effective = r_thruster - r_CoM`
- Thruster firing times adjusted to maintain consistent torque authority
- Ship handles predictably throughout fuel depletion

#### Update Sequence:
```typescript
// spacecraft.ts update() method:

// 1. Get current CoM (updated with fuel/cargo/ammo changes)
const comOffset = comSystem.getCoM();

// 2. Update RCS with current CoM
rcs.setCoMOffset(comOffset);

// 3. RCS calculates torque with compensation
const rcsTorque = rcs.getTotalTorque();

// RCS internally:
for (const thruster of thrusters) {
  const r = {
    x: thruster.position.x - this.comOffset.x,
    y: thruster.position.y - this.comOffset.y,
    z: thruster.position.z - this.comOffset.z
  };

  // Cross product: r × F gives compensated torque
  torque = crossProduct(r, force);
}
```

#### Game Impact:
- **Consistent Handling**: Ship maintains predictable attitude control throughout mission
- **Autopilot Accuracy**: Nav computer maintains accurate pointing despite mass changes
- **Docking Precision**: Final approach remains stable even with minimal fuel
- **Combat Maneuvering**: Evasive maneuvers maintain effectiveness in extended engagements

---

### 4. Projectile Gravity Physics

**Location**: `src/kinetic-weapons.ts:747-790`
**Integration Points**: `spacecraft.ts:416-419, 601-604`

Projectiles now follow ballistic arcs based on local gravitational acceleration.

#### Physics Implementation:
Semi-implicit Euler integration for numerical stability:
```typescript
// Update velocity first
velocity.x += gravity.x * dt;
velocity.y += gravity.y * dt;
velocity.z += gravity.z * dt;

// Then update position using new velocity
position.x += velocity.x * dt / 1000; // m/s to km
position.y += velocity.y * dt / 1000;
position.z += velocity.z * dt / 1000;
```

#### Gravity Configuration:
```typescript
// Deep space (default)
weapons.setGravity({ x: 0, y: 0, z: 0 });

// Near Earth surface
weapons.setGravity({ x: 0, y: 0, z: -9.80665 });

// Lunar surface
weapons.setGravity({ x: 0, y: 0, z: -1.62 });

// Mars surface
weapons.setGravity({ x: 0, y: 0, z: -3.71 });
```

#### Game Impact:
- **Planetary Combat**: Projectiles drop significantly at range
- **Lead Calculation**: Fire control computer must account for gravity drop
- **Effective Range**: 8000 m/s railgun drops 100m over 20km in 1g
- **Tactical Advantages**: High ground provides real ballistic advantage
- **Zero-G Space**: No gravity compensation needed, straight-line ballistics

#### Ballistic Tables (1g gravity):
| Weapon | Muzzle Velocity | Range | Drop @ Range | Time of Flight |
|--------|----------------|-------|--------------|----------------|
| Autocannon | 1,200 m/s | 5 km | 8.5 m | 4.2 s |
| Railgun | 8,000 m/s | 50 km | 19.2 m | 6.25 s |
| Railgun | 8,000 m/s | 100 km | 76.9 m | 12.5 s |

---

### 5. Ammunition Center of Mass Tracking

**Location**: `src/weapons-control.ts:432-476`
**Integration Points**: `spacecraft.ts:363-375, 487-491`

Each magazine is tracked as a mass component, updated as ammunition is expended.

#### Ammunition Masses:
- **Autocannon 30mm Round**: 0.4 kg
- **Railgun 100mm Slug**: 2.0 kg
- **Medium-Range Missile**: ~200 kg

#### Full Magazine Masses:
- **Autocannon Magazine** (500 rounds): 200 kg
- **Railgun Magazine** (30 rounds): 60 kg
- **VLS Missile Bay** (4 missiles): 800 kg

#### Update Sequence:
```typescript
// weapons-control.ts:
public getMagazines(): Array<{
  id: string;
  weaponId: string;
  mass: number;
  location: { x, y, z };
}> {
  // Calculate current ammunition mass
  weapon.magazine.ammunition.forEach(ammo => {
    totalMass += ammo.count * ammo.mass;
  });

  // Missiles
  missileMass = launcher.loaded * 200; // kg per missile

  return magazines;
}

// spacecraft.ts update():
const magazines = weapons.getMagazines();
for (const mag of magazines) {
  comSystem.updateMass(`ammo_${mag.id}`, mag.mass);
}
```

#### Game Impact:
- **Weight Reduction**: Firing 30 railgun rounds (60 kg) slightly reduces ship mass
- **CoM Shift**: Expending forward magazine shifts CoM aft
- **Extended Combat**: Mass changes accumulate during long engagements
- **Resupply Planning**: Ammunition mass considerations for cargo capacity

---

## Systems Integrator

**Location**: `src/systems-integrator.ts`

The systems integrator manages all spacecraft subsystems and their interactions:

### Power Management Integration
All systems registered as power consumers with priorities:

| System | Priority | Base Power | Max Power | Essential |
|--------|----------|------------|-----------|-----------|
| Environmental | 10 | 800 W | 1.2 kW | Yes |
| Navigation | 9 | 150 W | 200 W | No |
| Thermal | 9 | 200 W | 400 W | Yes |
| Coolant | 9 | 150 W | 300 W | Yes |
| Main Engine | 8 | 100 W | 300 W | No |
| RCS | 8 | 50 W | 150 W | No |
| Weapons | 7 | 100 W | 75 MW | No |
| Comms | 6 | 30 W | 500 W | No |

### System Dependencies
```
Main Engine → depends on: Fuel, Electrical, Thermal (critical)
RCS → depends on: Fuel, Electrical (critical)
Weapons → depends on: Electrical, Thermal, CoM (critical)
CoM → depends on: Fuel, Cargo (non-critical)
Navigation → depends on: Electrical (critical)
```

### Cascading Failure Example
```
1. Reactor damaged (40% health loss)
2. Power output reduced to 60%
3. Brownout triggers at 95% load
4. Systems integrator sheds non-essential loads
5. Weapons (priority 7) powered down automatically
6. Weapons safety engaged
7. Life support (priority 10) maintained
```

---

## Telemetry and Game State

### Full State Access
```typescript
const state = spacecraft.getState();

// Access all subsystem states
state.physics         // Position, velocity, acceleration, orientation
state.centerOfMass    // CoM position, total mass, moment of inertia
state.weapons         // All weapons status, ammunition, targets
state.electrical      // Reactor output, battery charge
state.thermal         // All component temperatures
state.fuel            // All tank levels, consumption rates
state.cargo           // Inventory, mass, CoM
state.rcs             // Thruster states, fuel consumption

// Systems integration
state.systemsIntegration.overallHealth      // 0-1
state.systemsIntegration.systemHealth       // Per-system health map
state.systemsIntegration.powerManagement    // Power budget, brownout status
```

### Event Streams
All systems generate events for gameplay feedback:

```typescript
const events = spacecraft.getAllEvents();

// Weapons events
events.weapons.forEach(event => {
  switch(event.type) {
    case 'POWER_INSUFFICIENT':
      UI.showWarning(`Insufficient power for ${event.data.weaponType}`);
      break;
    case 'KINETIC_HIT':
      UI.showCombatLog(`Hit ${event.data.zone} - ${event.data.damage} damage`);
      break;
    case 'MAGAZINE_EXPLOSION':
      UI.showAlert(`CRITICAL: Magazine explosion on ${event.data.targetId}`);
      break;
  }
});

// Power management events
events.powerManagement.forEach(event => {
  switch(event.type) {
    case 'brownout_warning':
      UI.showWarning(`BROWNOUT: ${event.data.demand}W demanded, ${event.data.available}W available`);
      break;
    case 'load_shed':
      UI.showInfo(`Load shed: ${event.data.shedCount} systems powered down`);
      break;
  }
});
```

---

## Gameplay Integration Examples

### Example 1: Extended Combat Engagement
```typescript
// Initial state
spacecraft.fuel.getState().totalFuel // 12,000 kg
spacecraft.comSystem.getCoM() // { x: 0, y: 0.5, z: -2.3 }
spacecraft.weapons.getMagazines() // Railgun: 60 kg, Missiles: 1600 kg

// During 10-minute engagement:
// - Fire 25 railgun rounds (50 kg expended)
// - Fire 6 missiles (1200 kg expended)
// - RCS fuel consumed: 200 kg
// - Main engine fuel consumed: 800 kg

// Final state
spacecraft.fuel.getState().totalFuel // 10,000 kg
spacecraft.comSystem.getCoM() // { x: 0, y: 0.3, z: -2.1 } (shifted aft)
spacecraft.weapons.getMagazines() // Railgun: 10 kg, Missiles: 400 kg

// Game effects:
// - Ship pitch response changed (CoM aft)
// - RCS compensation maintained attitude control
// - Need to reload ammunition at station
// - Range slightly increased due to mass reduction
```

### Example 2: Power Management Crisis
```typescript
// Reactor damaged in combat
spacecraft.electrical.reactor.currentOutputKW // 3.0 kW → 1.8 kW

// Systems integrator responds:
systemsIntegrator.update(dt);

// Brownout triggered (load > 95% of generation)
powerManagement.browning // true

// Priority shedding:
// 1. Countermeasures (priority 3) - SHED
// 2. EW systems (priority 3) - SHED
// 3. Cargo management (priority 4) - SHED
// 4. Landing/docking (priority 5) - SHED
// 5. Communications (priority 6) - SHED
// 6. Weapons (priority 7) - SHED ← Critical for gameplay

// Player cannot fire weapons until:
// - Reactor repaired
// - Non-essential systems manually disabled
// - Divert battery power (temporary)
```

### Example 3: Planetary Landing Combat
```typescript
// Approaching Mars surface (gravity: 3.71 m/s²)
spacecraft.weapons.setGravity({ x: 0, y: 0, z: -3.71 });

// Railgun ballistics at 10 km range:
// - Muzzle velocity: 8000 m/s
// - Time of flight: 1.25 seconds
// - Gravitational drop: 2.9 meters
// - Fire control computer compensates automatically

// Tactical considerations:
// - High altitude provides ballistic advantage
// - Low altitude targets harder to hit (must aim higher)
// - Fire control lead calculation includes gravity drop
```

---

## Performance Considerations

### Update Order (Optimized)
```typescript
spacecraft.update(dt) {
  1. electrical.update()          // Power generation first
  2. thermal.update()              // Heat management
  3. fuel.update()                 // Fuel state
  4. rcs.update()                  // RCS propellant
  5. mainEngine.update()           // Main engine thrust

  // Consume propellant
  6. fuel.consumeFuel()            // Actual consumption

  // Update CoM BEFORE physics
  7. comSystem.updateMass()        // Fuel masses
  8. comSystem.updateMass()        // Ammunition masses
  9. comSystem.getCoM()            // Calculate new CoM

  // Use CoM for dynamics
  10. rcs.setCoMOffset()           // RCS compensation
  11. physics.setCoMOffset()       // Physics dynamics
  12. physics.update()             // Integrate motion

  // Weapons last (uses current physics state)
  13. weapons.setPowerAvailable()  // Brownout check
  14. weapons.setGravity()         // Ballistics
  15. weapons.update()             // Fire control

  16. systemsIntegrator.update()   // Overall coordination
}
```

### Computational Complexity
- **CoM Calculation**: O(n) where n = number of mass components (~20)
- **Power Management**: O(m) where m = number of power consumers (~15)
- **Projectile Physics**: O(p) where p = active projectiles (~100 max)
- **Total per frame**: O(n + m + p) ≈ O(135) operations

---

## Testing and Validation

### Unit Test Coverage
- ✅ Center of Mass calculations (moment of inertia tensor)
- ✅ Power brownout enforcement (insufficient power scenarios)
- ✅ RCS CoM compensation (torque accuracy)
- ✅ Projectile gravity physics (ballistic arc accuracy)
- ✅ Ammunition mass tracking (update frequency)

### Integration Test Scenarios
1. **Full Mission Simulation**: 30-minute mission with combat, CoM verified at key points
2. **Power Crisis**: Reactor damage → brownout → weapons disabled → recovery
3. **Planetary Descent**: Gravity enabled → ballistics verified → landing
4. **Extended Combat**: All ammunition types fired → CoM shift measured
5. **Cascade Failure**: Critical system damage → dependency propagation → recovery

---

## Future Enhancements

### Planned Features
1. **Sensor Systems** (High Priority)
   - Radar tracking with CoM-based antenna pointing
   - Optical sensors with gimbal compensation
   - ESM integration with power management

2. **Orbital Mechanics** (High Priority)
   - Keplerian elements integration with CoM
   - Hohmann transfer planning with current mass
   - Orbital decay calculation

3. **Advanced Ballistics** (Medium Priority)
   - Atmospheric drag (altitude-dependent)
   - Coriolis effect for planetary combat
   - Wind compensation for atmospheric landings

4. **Ammunition Resupply** (Medium Priority)
   - Docking-based reload mechanics
   - Mass transfer during cargo operations
   - Ammunition fabrication from raw materials

---

## Quick Reference

### Key Files
- `spacecraft.ts` - Master integration (lines 55-63, 151-170, 336-389, 410-424)
- `center-of-mass.ts` - CoM tracking system
- `weapons-control.ts` - Weapons integration (lines 416-476)
- `rcs-system.ts` - RCS compensation (lines 50-51, 359-405)
- `kinetic-weapons.ts` - Projectile physics (lines 747-790)
- `systems-integrator.ts` - Power management and dependencies

### API Quick Start
```typescript
// Initialize spacecraft
const ship = new Spacecraft();

// Access subsystems
ship.comSystem.getState();           // CoM telemetry
ship.weapons.getPowerDraw();         // Current weapons power
ship.systemsIntegrator.getState();   // Overall health

// Game loop
function update(dt: number) {
  ship.update(dt);

  // Check for events
  const events = ship.getAllEvents();
  processGameEvents(events);

  // Update UI
  updateTelemetry(ship.getState());
}
```

---

## Conclusion

All critical systems are now fully integrated:
- ✅ Center of Mass tracking with fuel, cargo, and ammunition
- ✅ Weapons power management with brownout enforcement
- ✅ RCS compensation for shifting CoM
- ✅ Projectile gravity physics for realistic ballistics
- ✅ Systems integrator managing all dependencies

The spacecraft simulation is now ready for realistic gameplay with proper physics, power management, and tactical depth.
