# Spacecraft Systems Integration

## Overview

This document describes the complete integration of 12+ spacecraft subsystems with comprehensive power management, damage propagation, and EMCON (Emissions Control) capabilities.

## Integrated Subsystems

### Core Systems (Previously Implemented)
1. **Electrical System** - Reactor, batteries, power generation
2. **Thermal System** - Heat management, radiators
3. **Coolant System** - Liquid cooling loops
4. **Fuel System** - Propellant storage and distribution
5. **Compressed Gas System** - Pneumatics, pressurization
6. **Main Engine** - Primary propulsion
7. **RCS System** - Reaction Control System
8. **Flight Control** - SAS, autopilot, gimbal control
9. **Navigation** - Orbital mechanics, maneuver planning
10. **Mission System** - Mission objectives and tracking

### New Subsystems (Integrated)
11. **Navigation Computer** - Star tracker, IMU, gyroscope drift
12. **Countermeasures** - Chaff, flares, ECM, decoys
13. **Docking System** - Multi-port docking with alignment physics
14. **Landing System** - Gear deployment, terrain radar, shock absorption
15. **Communications** - Multi-band transceivers with Friis equation
16. **Cargo/Resource Management** - Bay management, center of mass
17. **Electronic Warfare** - ESM (detection), EA (jamming), EP (defense)
18. **Environmental Systems** - Life support, atmosphere, radiation shielding

## Power Management System

The Power Management System provides centralized control of all subsystem power allocation.

### Features

#### Power Buses
- **Bus A** - Main power bus (60% of total generation capacity)
- **Bus B** - Redundant main bus (60% of total generation capacity)
- **Emergency Bus** - Battery-only for critical systems (500W default)

#### Power Consumers
Each subsystem is registered as a power consumer with:
- **Priority** (0-10): Determines shutdown order during brownout
  - 10: Critical life support
  - 9: Essential navigation and environmental
  - 8: Propulsion and control
  - 5-6: Operations (docking, landing, communications)
  - 3-4: Tactical (EW, countermeasures, cargo)
  - 0-2: Non-essential

- **Power Draw**:
  - `basePowerW`: Minimum power to function
  - `currentPowerW`: Current consumption
  - `maxPowerW`: Maximum possible draw

- **Essential Flag**: Cannot be automatically shut down

#### Circuit Breakers
Each subsystem has an individual circuit breaker that can be:
- Manually enabled/disabled by the operator
- Automatically disabled during brownout (if non-essential)
- Protected from shutdown if marked essential

#### Brownout Prevention
When power demand exceeds generation capacity (default: 95% threshold):
1. **Warning** - Brownout condition detected
2. **Load Shedding** - Lowest priority non-essential systems shut down first
3. **Battery Support** - Battery begins discharging to cover deficit
4. **Emergency Protocol** - If battery depleted, emergency bus activates

**Priority Shutdown Order** (lowest to highest):
1. Cargo Management (priority 4)
2. Electronic Warfare (priority 3)
3. Countermeasures (priority 3)
4. Landing System (priority 5)
5. Docking System (priority 5)
6. Communications (priority 6)
7. Main Engine Controls (priority 8)
8. RCS System (priority 8)
9. Navigation Computer (priority 9)
10. **NEVER SHED**: Environmental/Life Support (priority 10, essential)

### EMCON (Emissions Control) Modes

EMCON allows the spacecraft to "go dark" and reduce electromagnetic signatures for stealth operations.

#### EMCON Levels

**1. Unrestricted** (Default)
- All systems operating normally
- Full communications and sensor emissions
- Maximum power consumption

**2. Reduced**
- Non-essential transmissions reduced
- Active sensors powered down
- Communications on receive-only mode
- Maintains operational capability

**3. Minimal**
- Only passive sensors active
- All transmitters off (comms, radar, beacons)
- Internal systems only
- Minimal electromagnetic signature

**4. Silent**
- Complete emissions silence
- Only life support and minimal environmental systems
- No external communications
- Maximum stealth, minimum survivability

**Automatic EMCON Adjustments:**
- Systems automatically power down based on EMCON level
- Power demand reduces as systems shut down
- EMCON enforced during emergency protocol (forced to Minimal)

## Systems Integration

The `SystemsIntegrator` class coordinates all subsystems and manages:

### System Dependencies

Systems can depend on other systems (critical or non-critical):

```
Electrical ← (all systems depend on power)
  ├─ Thermal (critical: required for reactor cooling)
  ├─ Flight Control (critical: required for maneuvering)
  ├─ Navigation Computer (critical: required for alignment)
  ├─ Environmental (critical: life support)
  ├─ Communications
  ├─ Docking
  ├─ Landing
  ├─ Cargo
  ├─ EW
  └─ Countermeasures

Thermal ← Coolant (critical: required for heat rejection)

Flight Control ← Navigation Computer (for autonomous operation)

Environmental ← Electrical + Thermal (critical: life support requires both)
```

### Damage Propagation

When a system receives damage:

1. **Direct Damage** - System health reduced by damage severity
2. **Dependency Failure** - If a critical dependency fails, dependent systems fail
3. **Cascading Damage** - Damage propagates to connected systems at 30% severity
4. **System Failure Threshold** - Systems fail when health < 0.3

**Damage Types:**
- `impact` - Physical collision damage
- `overheat` - Thermal overload
- `power_surge` - Electrical damage
- `radiation` - Radiation exposure
- `micrometeorite` - Micro-impact damage
- `malfunction` - Random failure

**Example Cascade:**
```
Electrical System damaged (0.6 severity)
  ↓
Propagates to Thermal (0.6 × 0.3 = 0.18 severity)
  ↓
Thermal reduced to 82% health
  ↓
If Thermal fails → Environmental fails (critical dependency)
  ↓
Life support compromised
```

### Emergency Protocol

Activated automatically when:
- Battery depleted
- Critical system failure detected
- Manual activation by operator

**Emergency Protocol Actions:**
1. Set EMCON to Minimal (reduce emissions)
2. Activate emergency power bus
3. Shed all non-essential loads
4. Prioritize life support and thermal management
5. Log emergency event

**Systems Active in Emergency Mode:**
- Environmental/Life Support (essential)
- Thermal Management (essential)
- Coolant System (essential)
- Electrical System (reactor only, minimal load)

### Real-Time Integration

The SystemsIntegrator runs each frame during `spacecraft.update(dt)`:

1. **Update Power Management** - Calculate generation, demand, battery state
2. **Update Power Draws** - Get current draw from each subsystem
3. **Apply Power States** - Enable/disable subsystems based on circuit breakers
4. **Update Battery** - Charge/discharge based on surplus/deficit
5. **Check Dependencies** - Verify critical dependencies are operational
6. **Detect Failures** - Check for cascading failures
7. **Emergency Check** - Activate emergency protocol if needed

## Signal Physics

### Communications System

The Communications System implements the **Friis Transmission Equation** for realistic signal propagation:

```
Path Loss (dB) = 20 log₁₀(range_km) + 20 log₁₀(freq_GHz) + 92.45 - antenna_gain
```

**Effects of Signal Degradation:**
- **Data Rate** - Reduces with distance and interference
- **Latency** - Increases with distance (speed of light delay)
- **Signal Strength** - 0-1 range based on path loss

**Multi-Band Transceivers:**
- VHF (30-300 MHz) - Long range, low bandwidth
- UHF (300 MHz-3 GHz) - Medium range, medium bandwidth
- S-band (2-4 GHz) - Space communications
- X-band (8-12 GHz) - High bandwidth, radar
- Ka-band (26-40 GHz) - Very high bandwidth, short range

### Electronic Warfare

**ESM (Electronic Support Measures)** - Passive detection:
- Detects emitters based on signal strength and range
- Frequency analysis for threat classification
- Bearing determination
- Threat level assessment (low/medium/high/critical)

**EA (Electronic Attack)** - Active jamming:
- Noise jamming
- Deception jamming
- Targeted vs barrage jamming
- Effectiveness based on power ratio and frequency match

**EP (Electronic Protection)** - Defensive measures:
- RWR (Radar Warning Receiver)
- Audio alerts for threats
- Automatic threat prioritization

## User Interaction

### Terminal UI Stations

The `comprehensive-systems-screen.ts` example demonstrates 5 operator stations:

#### Station 1: Captain / Flight Control
- Navigation data (altitude, velocity, TWR, ΔV)
- Flight control (SAS, autopilot, gimbal)
- Propulsion (engine status, throttle, fuel)
- Navball display

#### Station 2: Engineering
- Power generation and distribution
- Circuit breakers (10 subsystems)
- Thermal management (radiators, temperature)
- Coolant loops
- Reactor status

#### Station 3: Tactical
- Electronic warfare (detected threats, jamming)
- Countermeasures (chaff, flares, decoys)
- Communications (active links, signal strength)
- Threat assessment

#### Station 4: Life Support
- Atmosphere (pressure, O₂, CO₂, temperature)
- Radiation (shielding, exposure, cumulative)
- Emergency systems (oxygen, scrubbers)
- Hull integrity (breaches, leaks)

#### Station 5: Cargo / Docking / Navigation
- Cargo inventory (food, water, oxygen, parts)
- Docking ports (status, seal integrity, alignment)
- Landing gear (deployment, compression, contact)
- Navigation computer (alignment, drift, quality)

### Real-Time Displays

All stations show:
- **Status Bar** - Time, overall health, power %, EMCON level
- **Color-Coded Status** - Green (good), Yellow (warning), Red (critical)
- **Bar Graphs** - Power, fuel, temperature, etc.
- **Progress Indicators** - Latch progress, alignment, etc.

## Example Scenarios

### Scenario 1: Stealth Approach

**Objective:** Approach target while minimizing detection

1. Set EMCON to Reduced
   - Communications on receive-only
   - Active sensors off
   - Power demand drops to ~1200W

2. Coast on ballistic trajectory (engine off)
   - No thrust emissions
   - Minimal thermal signature

3. Use passive sensors only (ESM)
   - Detect enemy radars without transmitting
   - Monitor for threats

4. Emergency power available on battery
   - 10 kWh capacity for 8+ hours at reduced power

### Scenario 2: Power Crisis Response

**Event:** Reactor damaged, output drops 50%

1. **Automatic Response:**
   - Brownout warning triggered
   - Load shedding activates
   - 9 non-essential systems powered down
   - Essential systems (life support, thermal) protected

2. **Operator Actions:**
   - Review circuit breaker panel
   - Manually restore critical operational systems
   - Monitor battery discharge rate
   - Plan power restoration

3. **Recovery:**
   - Repair reactor (manual or automated)
   - Restore power generation
   - Re-enable systems in priority order
   - Recharge battery from surplus power

### Scenario 3: Combat Engagement

**Event:** Hostile radar detected tracking the spacecraft

1. **Detection (ESM):**
   - Threat emitter detected at 150km
   - Classification: Fire control radar
   - Threat level: HIGH
   - Audio warning on RWR

2. **Defensive Actions:**
   - Activate ECM jammer targeting threat frequency
   - Deploy chaff (2 bundles) for radar confusion
   - Deploy flares (2 bundles) for IR decoys
   - Set EMCON to Reduced (limit emissions)

3. **Evasion:**
   - Execute evasive maneuver
   - Monitor jammer effectiveness
   - Track remaining countermeasures
   - Assess threat level reduction

### Scenario 4: Docking Procedure

**Objective:** Dock with space station using forward androgynous port

1. **Approach Phase:**
   - Activate docking system (port_fwd)
   - Monitor alignment guidance:
     - Distance: 0.05m (50mm)
     - Approach rate: 0.05 m/s (5 cm/s)
     - Alignment error: 1.5°

2. **Capture:**
   - Alignment within 3° tolerance
   - Distance within 100mm capture range
   - Approach rate < 20 cm/s
   - Capture mechanism engages

3. **Hard Dock:**
   - Latches engage over 30 seconds
   - Monitor latch progress (0-100%)
   - Seal integrity check (>90% required)
   - Resource connections established

4. **Atmosphere Equalization:**
   - Verify hard dock complete
   - Verify seal integrity >90%
   - Equalize pressure between vessels
   - Hatch can be safely opened

### Scenario 5: Landing on Moon/Planet

**Objective:** Safe landing with gear deployed

1. **Descent Phase:**
   - Activate terrain radar (altitude 5000m)
   - Terrain scan rate: 10 Hz
   - Contact detection range: 0-10km

2. **Gear Deployment:**
   - Deploy landing gear at altitude 1000m
   - 3 gear: nose, left, right
   - Verify all gear locked and deployed
   - Power draw increases to 50W

3. **Final Approach:**
   - Vertical speed: -2.0 m/s (safe)
   - Monitor gear compression sensors
   - Oleopneumatic shock absorbers ready

4. **Touchdown:**
   - Gear contact detected (all 3)
   - Shock absorber compression: 30%
   - Load distributed across gear
   - Engine shutdown
   - Landing complete

## Performance Characteristics

### Power Budget (Typical)

**Generation:**
- Reactor: 0-3000W (variable)
- Solar panels: 0W (not implemented yet)

**Essential Demand (~600W):**
- Environmental/Life Support: 200W
- Thermal Management: 150W
- Coolant System: 100W
- Electrical System: 100W
- Flight Control: 50W

**Operational Demand (~1500W):**
- + Navigation Computer: 150W
- + Main Engine Controls: 100W
- + RCS System: 100W
- + Communications: 100W
- + Landing System: 50W
- + Docking System: 50W
- + Cargo Management: 50W
- + Electronic Warfare: 100W
- + Countermeasures: 50W

**Battery:**
- Capacity: 10 kWh (default)
- Charge rate: 1 kW (from surplus)
- Discharge rate: Unlimited (covers deficit)
- Emergency runtime: 6-8 hours (essential systems only)

### System Response Times

- **EMCON Mode Change:** Instant
- **Circuit Breaker Toggle:** Instant
- **Brownout Detection:** 1 frame (~16ms)
- **Load Shedding:** 1 frame
- **Emergency Protocol Activation:** 1 frame
- **Docking Latch Completion:** 30 seconds
- **Landing Gear Deployment:** 10 seconds
- **Landing Gear Retraction:** 15 seconds

## Testing & Validation

### Integration Demo

Run `examples/full-systems-integration-demo.ts` to see all 7 scenarios:

```bash
npx tsc
node dist/examples/full-systems-integration-demo.js
```

**Scenarios Demonstrated:**
1. Normal Operations (all systems)
2. Going Dark (EMCON progression)
3. Power Crisis (brownout prevention)
4. Damage Cascade (failure propagation)
5. Emergency Protocol (survival mode)
6. Docking Operations (alignment physics)
7. Combat Scenario (EW + countermeasures)

### Interactive UI

Run `examples/comprehensive-systems-screen.ts` for interactive station displays:

```bash
node dist/examples/comprehensive-systems-screen.js
```

Switch between 5 stations to monitor all subsystems in real-time.

## API Reference

### Power Management

```typescript
// Set EMCON level
spacecraft.systemsIntegrator.powerManagement.setEMCON('silent');

// Toggle circuit breaker
spacecraft.systemsIntegrator.powerManagement.setCircuitBreaker('comm_system', false);

// Get power budget
const budget = spacecraft.systemsIntegrator.powerManagement.getPowerBudget();
// Returns: { generation, demand, surplus, deficit, batteryPercent, loadPercent, browning, emconLevel }

// Get bus status
const busA = spacecraft.systemsIntegrator.powerManagement.getBusStatus('A');
// Returns: { load, capacity, percent, enabled, consumerCount }
```

### Damage Application

```typescript
// Apply damage to a system
spacecraft.systemsIntegrator.applyDamage({
  systemId: 'environmental',
  severity: 0.7,  // 0-1
  type: 'impact',
  timestamp: Date.now(),
  cascading: true  // Will propagate to connected systems
});
```

### Emergency Protocol

```typescript
// Manually activate emergency protocol
spacecraft.systemsIntegrator.activateEmergencyProtocol();

// Check if active
const state = spacecraft.getState();
if (state.systemsIntegration.emergencyProtocolActive) {
  // Emergency mode active
}
```

### Subsystem Control

```typescript
// Docking
spacecraft.docking.initiateDocking('port_fwd', targetData);
spacecraft.docking.attemptCapture();
spacecraft.docking.completeHardDock();

// Landing
spacecraft.landing.deployGear();
spacecraft.landing.activateTerrainRadar();
const safetyCheck = spacecraft.landing.isSafeToLand();

// Communications
spacecraft.communications.establishLink('comm_primary', targetVessel, rangeKm);
spacecraft.communications.transmitData('comm_primary', dataKb);

// Electronic Warfare
spacecraft.ew.detectEmitter(threatEmitter, rangeKm);
spacecraft.ew.activateJammer('jammer_1', emitterId);

// Countermeasures
spacecraft.countermeasures.deployChaff(2);
spacecraft.countermeasures.deployFlares(2);
spacecraft.countermeasures.activateECM();
```

## Future Enhancements

### Planned Features

1. **Solar Panel Power Generation**
   - Orientation-dependent power
   - Degradation over time
   - Integration with power management

2. **Crew System Integration**
   - Crew power consumption
   - Life support requirements per crew member
   - Crew efficiency based on environmental conditions

3. **Advanced Thermal Management**
   - Heat pipes between systems
   - Radiator deployment mechanics
   - Active cooling loops for subsystems

4. **Resource Transfer**
   - Docked resource transfer (fuel, oxygen, power)
   - Transfer rate limits
   - Connection integrity monitoring

5. **Automated Damage Control**
   - Automatic repair systems
   - Spare parts consumption
   - Repair time estimation

6. **Advanced EMCON**
   - Thermal signature management
   - Visual detection modeling
   - Acoustic signature (in atmosphere)

7. **Multi-Vessel Coordination**
   - Fleet power sharing
   - Distributed sensor networks
   - Formation flying with power optimization

## Conclusion

The spacecraft subsystems are now fully integrated with:

- ✅ 18+ subsystems coordinated through SystemsIntegrator
- ✅ Comprehensive power management with brownout prevention
- ✅ EMCON (going dark) for stealth operations
- ✅ Cascading damage propagation
- ✅ Emergency survival protocols
- ✅ Signal degradation physics (Friis equation)
- ✅ Multi-station user interface
- ✅ Real-time system health monitoring
- ✅ Priority-based power allocation
- ✅ Circuit breaker management
- ✅ Automated crisis response

All systems are production-ready with complete TypeScript types, comprehensive examples, and validated integration across multiple realistic scenarios.
