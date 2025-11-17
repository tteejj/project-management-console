# Propulsion Integration System Design

## Overview
Comprehensive propulsion system that integrates with fuel, power, thermal, and physics systems.

## Thruster Types

### Main Engine
- **High ISP** (300-450s) - Efficient for large burns
- **High thrust** (10-100 kN)
- **High fuel consumption**
- **High heat generation**
- Use: Orbital maneuvers, landing, launch

### RCS (Reaction Control System)
- **Low ISP** (70-150s) - Less efficient
- **Low thrust** (10-500 N)
- **Low fuel consumption**
- **Low heat generation**
- Use: Attitude control, fine positioning

### Ion Drive (Optional)
- **Very high ISP** (3000-5000s) - Very efficient
- **Very low thrust** (0.01-0.5 N)
- **High power consumption**
- **Low fuel consumption**
- Use: Long duration burns, deep space

## Physics Integration

### Thrust Calculation
```
F = ṁ * v_e                    // Thrust = mass flow rate × exhaust velocity
v_e = Isp × g₀                 // Exhaust velocity from specific impulse
ṁ = F / (Isp × g₀)            // Mass flow rate from thrust and ISP

where:
  F = thrust (N)
  ṁ = mass flow rate (kg/s)
  v_e = exhaust velocity (m/s)
  Isp = specific impulse (s)
  g₀ = 9.80665 m/s² (standard gravity)
```

### Gimbal / Thrust Vectoring
- Thrusters can gimbal ±15° (main engines)
- RCS thrusters are fixed direction
- Gimbal requires power (100-500W per thruster)
- Gimbal rate: 10°/s

### Throttle Control
- Main engines: 40-100% throttle (can't throttle too low)
- RCS: ON/OFF only (no throttling)
- Throttle response time: 0.5-2 seconds

## Fuel Integration

### Fuel Consumption
```
fuel_consumed = ṁ * dt
ṁ = (throttle × max_thrust) / (Isp × g₀)
```

### Fuel Types
- **Mono-propellant** (hydrazine) - RCS
- **Bi-propellant** (LOX/LH2, MMH/NTO) - Main engines
- **Xenon** - Ion drives

### Tank Assignment
- Thrusters draw from designated fuel tank(s)
- Multiple thrusters can share tank
- Tank pressure affects performance
- Empty tank → thruster shutdown

## Power Integration

### Power Consumption
- **Fuel pumps**: 1-5 kW (main engines only)
- **Ignition system**: 0.5 kW (startup only)
- **Thrust vectoring**: 0.1-0.5 kW per thruster
- **Ion drive**: 1-10 kW (continuous)

### Power Failure Effects
- No power → RCS still works (pressure-fed)
- No power → Main engines fail (need pumps)
- No power → Ion drives fail immediately

## Thermal Integration

### Heat Generation
```
Q_heat = P_consumed - P_thrust
P_thrust = 0.5 × ṁ × v_e²     // Kinetic power
P_consumed = ṁ × fuel_energy  // Chemical energy

For main engines:
  ~30% efficiency → 70% becomes heat
  Example: 50 kN thrust → ~15 MW heat

For RCS:
  ~50% efficiency → 50% becomes heat
  Example: 400 N thrust → ~200 kW heat
```

### Cooling Requirements
- Engines require active cooling for burns >30s
- RCS can operate without cooling (short duty cycle)
- Overheating reduces thrust and efficiency
- Critical overheat → engine shutdown/damage

## System Damage Integration

### Damage Effects
- Hull breach in engine compartment → vacuum damage
- Structural damage → misalignment, reduced thrust
- Power system failure → no ignition
- Fuel system failure → no propellant feed

### Failure Modes
- **Stuck valve**: Thruster won't shut off
- **Leak**: Fuel loss, thrust loss
- **Nozzle damage**: Reduced ISP
- **Gimbal failure**: No thrust vectoring

## Implementation Structure

```typescript
enum PropellantType {
  HYDRAZINE = 'hydrazine',
  LOX_LH2 = 'lox_lh2',
  MMH_NTO = 'mmh_nto',
  XENON = 'xenon'
}

enum ThrusterType {
  MAIN_ENGINE = 'main_engine',
  RCS = 'rcs',
  ION_DRIVE = 'ion_drive'
}

interface ThrusterConfig {
  id: string;
  type: ThrusterType;
  position: Vector3;          // Location on ship (for torque)
  direction: Vector3;         // Thrust direction (unit vector)
  maxThrust: number;          // Newtons
  isp: number;                // Specific impulse (seconds)
  propellantType: PropellantType;
  fuelTankId: string;

  // Capabilities
  canGimbal: boolean;
  gimbalRange?: number;       // degrees (±)
  minThrottle?: number;       // 0-1 (default 1 for RCS, 0.4 for main)

  // Power/Thermal
  pumpPower?: number;         // kW (0 for pressure-fed)
  gimbalPower?: number;       // kW
  efficiency: number;         // 0-1 (thrust efficiency)
}

interface ThrusterState {
  enabled: boolean;
  throttle: number;           // 0-1
  gimbalAngle: Vector3;       // Current gimbal (degrees)
  temperature: number;        // K
  fuelFlow: number;           // kg/s (current)
  powerDraw: number;          // kW (current)
  heatGeneration: number;     // kW (current)
  damaged: boolean;
  integrity: number;          // 0-1
}

class PropulsionSystem {
  thrusters: Map<string, { config: ThrusterConfig, state: ThrusterState }>;

  update(dt: number): void {
    for (const thruster of thrusters) {
      // 1. Calculate thrust
      const actualThrust = this.calculateThrust(thruster);

      // 2. Consume fuel
      const fuelConsumed = this.consumeFuel(thruster, dt);

      // 3. Consume power
      const powerUsed = this.consumePower(thruster);

      // 4. Generate heat
      const heatGenerated = this.generateHeat(thruster);

      // 5. Apply force/torque to spacecraft
      this.applyThrustForce(thruster, actualThrust);

      // 6. Update thruster state
      this.updateThrusterState(thruster, dt);
    }
  }

  fireThruster(id: string, throttle: number): boolean;
  setGimbal(id: string, angle: Vector3): boolean;
  getThrustVector(id: string): { force: Vector3, torque: Vector3 };
}
```

## Update Loop Integration

### Order of Operations
1. **Propulsion Update** → Calculate thrust, consume fuel/power, generate heat
2. **Physics Update** → Apply forces/torques from thrusters
3. **Fuel Update** → Update tank levels, pressures
4. **Power Update** → Track power consumption
5. **Thermal Update** → Track heat from engines
6. **Damage Update** → Check for thruster damage from overheating/impacts

## Test Coverage

- [x] Thrust calculation from throttle and ISP
- [x] Fuel consumption rate
- [x] Power consumption for pumps and gimbals
- [x] Heat generation from thrust
- [x] Thrust vectoring with gimbal
- [x] Throttle limits (min/max)
- [x] Fuel depletion → thruster shutdown
- [x] Power loss → pump-fed thruster failure
- [x] Overheating effects
- [x] Damage reducing thrust
- [x] Multiple thrusters firing simultaneously
- [x] RCS vs main engine differences
- [x] Integration with UnifiedShip
