# Target Selection & Intercept Planning System Design

## Overview

**Purpose:** Select destinations, calculate intercept trajectories, plan rendezvous burns

**Like:**
- Apollo lunar module rendezvous
- Space Shuttle ISS docking
- KSP orbital intercept maneuvers
- Real orbital mechanics

**Gameplay:** Navigate to stations, intercept derelicts, rendezvous with other ships

---

## Target Selection

### Target Types

```typescript
interface Target {
  id: string;
  body: CelestialBody;

  // Selection metadata
  selectedAt: number;       // Timestamp
  priority: TargetPriority;

  // Tracking data (from sensors)
  lastKnownPosition: Vector3;
  lastKnownVelocity: Vector3;
  lastUpdate: number;

  // Mission context
  objective?: TargetObjective;
}

enum TargetPriority {
  PRIMARY,      // Main destination
  SECONDARY,    // Alternate destination
  WAYPOINT,     // Intermediate point
  THREAT        // Avoid this
}

enum TargetObjective {
  DOCK,         // Rendezvous and dock
  APPROACH,     // Get close (for scanning)
  AVOID,        // Stay away from
  INVESTIGATE,  // Approach cautiously
  INTERCEPT     // Match velocity
}
```

### Target Selection UI

```typescript
class TargetingSystem {
  private currentTarget: Target | null = null;
  private targetHistory: Target[] = [];

  selectTarget(contactId: string, objective: TargetObjective): void {
    const body = this.world.bodies.get(contactId);
    if (!body) return;

    // Get latest sensor data
    const sensorData = this.sensors.getContact(contactId);

    this.currentTarget = {
      id: contactId,
      body,
      selectedAt: Date.now(),
      priority: TargetPriority.PRIMARY,
      lastKnownPosition: sensorData.position,
      lastKnownVelocity: sensorData.velocity,
      lastUpdate: Date.now(),
      objective
    };

    // Clear previous primary target
    for (const target of this.targetHistory) {
      if (target.priority === TargetPriority.PRIMARY) {
        target.priority = TargetPriority.SECONDARY;
      }
    }

    this.targetHistory.push(this.currentTarget);
  }

  clearTarget(): void {
    if (this.currentTarget) {
      this.currentTarget.priority = TargetPriority.SECONDARY;
      this.currentTarget = null;
    }
  }

  cycleTo nextTarget(): void {
    // Cycle through available contacts
    const contacts = this.sensors.getAllContacts();
    const currentIndex = contacts.findIndex(c => c.id === this.currentTarget?.id);
    const nextIndex = (currentIndex + 1) % contacts.length;
    this.selectTarget(contacts[nextIndex].id, TargetObjective.APPROACH);
  }
}
```

---

## Relative Motion Analysis

### Relative State Calculation

```typescript
interface RelativeState {
  // Position
  range: number;            // m (distance)
  bearing: number;          // degrees (horizontal angle)
  elevation: number;        // degrees (vertical angle)

  // Velocity
  closingVelocity: number;  // m/s (negative = approaching)
  lateralVelocity: number;  // m/s (sideways motion)

  // Rates
  rangeRate: number;        // m/s (rate of change of distance)
  bearingRate: number;      // deg/s (angular rate)

  // Derived
  timeToClosestApproach: number; // seconds
  closestApproachDistance: number; // m
}

class RelativeMotionCalculator {
  calculateRelativeState(
    shipPosition: Vector3,
    shipVelocity: Vector3,
    targetPosition: Vector3,
    targetVelocity: Vector3
  ): RelativeState {
    // 1. Relative position
    const relativePos = subtract(targetPosition, shipPosition);
    const range = magnitude(relativePos);

    // 2. Bearing and elevation
    const bearing = Math.atan2(relativePos.y, relativePos.x) * RAD_TO_DEG;
    const elevation = Math.atan2(
      relativePos.z,
      Math.sqrt(relativePos.x ** 2 + relativePos.y ** 2)
    ) * RAD_TO_DEG;

    // 3. Relative velocity
    const relativeVel = subtract(targetVelocity, shipVelocity);

    // 4. Closing velocity (along line of sight)
    const lineOfSight = normalize(relativePos);
    const closingVelocity = dot(relativeVel, lineOfSight);

    // 5. Lateral velocity (perpendicular to line of sight)
    const closingVelVector = scale(lineOfSight, closingVelocity);
    const lateralVelVector = subtract(relativeVel, closingVelVector);
    const lateralVelocity = magnitude(lateralVelVector);

    // 6. Range rate (negative = closing)
    const rangeRate = -closingVelocity;

    // 7. Bearing rate
    const bearingRate = (lateralVelocity / range) * RAD_TO_DEG;

    // 8. Closest approach (assuming no thrust)
    const { time, distance } = this.calculateClosestApproach(
      relativePos,
      relativeVel
    );

    return {
      range,
      bearing,
      elevation,
      closingVelocity,
      lateralVelocity,
      rangeRate,
      bearingRate,
      timeToClosestApproach: time,
      closestApproachDistance: distance
    };
  }

  private calculateClosestApproach(
    relativePos: Vector3,
    relativeVel: Vector3
  ): { time: number; distance: number } {
    // Closest approach occurs when range rate = 0
    // t = -(r · v) / (v · v)

    const r_dot_v = dot(relativePos, relativeVel);
    const v_dot_v = dot(relativeVel, relativeVel);

    if (v_dot_v < 1e-6) {
      // Not moving relative to each other
      return {
        time: Infinity,
        distance: magnitude(relativePos)
      };
    }

    const timeToCA = -r_dot_v / v_dot_v;

    if (timeToCA < 0) {
      // Already passed closest approach
      return {
        time: 0,
        distance: magnitude(relativePos)
      };
    }

    // Position at closest approach
    const posAtCA = add(relativePos, scale(relativeVel, timeToCA));
    const distanceAtCA = magnitude(posAtCA);

    return {
      time: timeToCA,
      distance: distanceAtCA
    };
  }
}
```

---

## Intercept Trajectory Calculation

### Lambert's Problem (Time-Fixed Intercept)

```typescript
interface InterceptSolution {
  // Maneuver parameters
  burnStart: number;         // Time to start burn (seconds from now)
  burnDuration: number;      // Duration of burn (seconds)
  burnDirection: Vector3;    // Thrust vector (normalized)
  throttle: number;          // Engine throttle (0-1)

  // Delta-v
  deltaV: number;            // Total Δv required (m/s)
  fuelRequired: number;      // Fuel consumption (kg)

  // Trajectory
  interceptTime: number;     // Total time to intercept (seconds)
  interceptPosition: Vector3; // Where intercept occurs
  finalRange: number;        // Distance at intercept (ideally 0)

  // Quality
  feasible: boolean;         // Can we do this with available fuel?
  efficiency: number;        // 0-1 (1 = most efficient)
}

class InterceptPlanner {
  // Plan intercept for given time of flight
  planIntercept(
    shipState: ShipState,
    targetState: { position: Vector3; velocity: Vector3 },
    timeOfFlight: number,
    shipCapabilities: { maxThrust: number; isp: number; fuelMass: number }
  ): InterceptSolution {
    // 1. Predict where target will be
    const targetPosAtIntercept = add(
      targetState.position,
      scale(targetState.velocity, timeOfFlight)
    );

    // 2. Calculate required velocity change
    // Simplified: v_required = (r_target - r_ship) / t
    const requiredPosition = subtract(targetPosAtIntercept, shipState.position);
    const requiredVelocity = scale(requiredPosition, 1 / timeOfFlight);

    // 3. Delta-v needed
    const deltaVVector = subtract(requiredVelocity, shipState.velocity);
    const deltaV = magnitude(deltaVVector);

    // 4. Check feasibility
    const fuelRequired = this.calculateFuelRequired(
      deltaV,
      shipState.mass,
      shipCapabilities.isp
    );

    const feasible = fuelRequired <= shipCapabilities.fuelMass;

    // 5. Burn parameters
    const acceleration = shipCapabilities.maxThrust / shipState.mass;
    const burnDuration = deltaV / acceleration;

    // 6. When to start burn (mid-course correction)
    const burnStart = (timeOfFlight - burnDuration) / 2;

    // 7. Efficiency (lower Δv = more efficient)
    const efficiency = 1 / (1 + deltaV / 100);

    return {
      burnStart,
      burnDuration,
      burnDirection: normalize(deltaVVector),
      throttle: 1.0,
      deltaV,
      fuelRequired,
      interceptTime: timeOfFlight,
      interceptPosition: targetPosAtIntercept,
      finalRange: 0, // Ideal intercept
      feasible,
      efficiency
    };
  }

  // Rocket equation: Δv = I_sp * g_0 * ln(m_0 / m_f)
  // Rearranged: m_fuel = m_0 * (1 - exp(-Δv / (I_sp * g_0)))
  private calculateFuelRequired(
    deltaV: number,
    shipMass: number,
    isp: number
  ): number {
    const g0 = 9.81; // Standard gravity
    const massRatio = Math.exp(-deltaV / (isp * g0));
    const finalMass = shipMass * massRatio;
    return shipMass - finalMass;
  }

  // Find optimal time of flight (minimum Δv)
  optimizeInterceptTime(
    shipState: ShipState,
    targetState: { position: Vector3; velocity: Vector3 },
    shipCapabilities: { maxThrust: number; isp: number; fuelMass: number },
    minTime: number = 60,
    maxTime: number = 600
  ): InterceptSolution {
    let bestSolution: InterceptSolution | null = null;
    let bestDeltaV = Infinity;

    // Sample different times of flight
    for (let t = minTime; t <= maxTime; t += 10) {
      const solution = this.planIntercept(
        shipState,
        targetState,
        t,
        shipCapabilities
      );

      if (solution.feasible && solution.deltaV < bestDeltaV) {
        bestDeltaV = solution.deltaV;
        bestSolution = solution;
      }
    }

    return bestSolution || this.planIntercept(
      shipState,
      targetState,
      minTime,
      shipCapabilities
    );
  }
}
```

---

## Rendezvous Phases

### Multi-Stage Approach

```typescript
enum RendezvousPhase {
  COARSE_APPROACH,   // Get within 10km
  FINE_APPROACH,     // Get within 1km
  STATION_KEEPING,   // Match velocity at distance
  FINAL_APPROACH,    // Close to docking range
  DOCKING            // Align and capture
}

class RendezvousManager {
  private phase: RendezvousPhase = RendezvousPhase.COARSE_APPROACH;

  update(
    ship: Spacecraft,
    target: Target,
    relativeState: RelativeState
  ): RendezvousGuidance {
    switch (this.phase) {
      case RendezvousPhase.COARSE_APPROACH:
        return this.coarseApproach(ship, target, relativeState);

      case RendezvousPhase.FINE_APPROACH:
        return this.fineApproach(ship, target, relativeState);

      case RendezvousPhase.STATION_KEEPING:
        return this.stationKeeping(ship, target, relativeState);

      case RendezvousPhase.FINAL_APPROACH:
        return this.finalApproach(ship, target, relativeState);

      case RendezvousPhase.DOCKING:
        return this.docking(ship, target, relativeState);
    }
  }

  // Phase 1: Coarse Approach (>10km)
  private coarseApproach(
    ship: Spacecraft,
    target: Target,
    relativeState: RelativeState
  ): RendezvousGuidance {
    // Goal: Get within 10km with low closing velocity

    if (relativeState.range < 10000) {
      this.phase = RendezvousPhase.FINE_APPROACH;
      return this.fineApproach(ship, target, relativeState);
    }

    // Calculate intercept burn
    const intercept = new InterceptPlanner().optimizeInterceptTime(
      ship.state,
      { position: target.lastKnownPosition, velocity: target.lastKnownVelocity },
      {
        maxThrust: ship.engine.maxThrust,
        isp: ship.engine.isp,
        fuelMass: ship.fuel.totalMass
      }
    );

    return {
      phase: RendezvousPhase.COARSE_APPROACH,
      instruction: `Burn ${intercept.deltaV.toFixed(1)} m/s in ${this.formatTime(intercept.burnStart)}`,
      burn: intercept,
      autopilotMode: 'prograde' // Point toward target
    };
  }

  // Phase 2: Fine Approach (1-10km)
  private fineApproach(
    ship: Spacecraft,
    target: Target,
    relativeState: RelativeState
  ): RendezvousGuidance {
    // Goal: Get within 1km, reduce closing velocity to <5 m/s

    if (relativeState.range < 1000) {
      this.phase = RendezvousPhase.STATION_KEEPING;
      return this.stationKeeping(ship, target, relativeState);
    }

    // Reduce closing velocity if too fast
    const maxClosingVelocity = 10; // m/s
    if (relativeState.closingVelocity < -maxClosingVelocity) {
      // Braking burn
      const brakingDeltaV = Math.abs(relativeState.closingVelocity) - maxClosingVelocity;
      return {
        phase: RendezvousPhase.FINE_APPROACH,
        instruction: `BRAKE: Reduce velocity by ${brakingDeltaV.toFixed(1)} m/s`,
        burn: this.calculateBrakingBurn(brakingDeltaV, ship),
        autopilotMode: 'retrograde'
      };
    }

    return {
      phase: RendezvousPhase.FINE_APPROACH,
      instruction: `Coast to 1km range (ETA ${this.formatTime(relativeState.range / Math.abs(relativeState.closingVelocity))})`,
      burn: null,
      autopilotMode: 'target'
    };
  }

  // Phase 3: Station Keeping (matching velocity at distance)
  private stationKeeping(
    ship: Spacecraft,
    target: Target,
    relativeState: RelativeState
  ): RendezvousGuidance {
    // Goal: Match velocity precisely, hold position at 500m

    const targetRange = 500; // m
    const velocityTolerance = 0.5; // m/s

    // Check if velocity matched
    if (Math.abs(relativeState.closingVelocity) < velocityTolerance &&
        Math.abs(relativeState.lateralVelocity) < velocityTolerance) {
      // Velocity matched!
      if (relativeState.range < 100) {
        this.phase = RendezvousPhase.FINAL_APPROACH;
        return this.finalApproach(ship, target, relativeState);
      }

      return {
        phase: RendezvousPhase.STATION_KEEPING,
        instruction: `Station keeping at ${relativeState.range.toFixed(0)}m - Ready for final approach`,
        burn: null,
        autopilotMode: 'target'
      };
    }

    // Match velocity
    const deltaVNeeded = Math.abs(relativeState.closingVelocity) +
                        Math.abs(relativeState.lateralVelocity);

    return {
      phase: RendezvousPhase.STATION_KEEPING,
      instruction: `Match velocity: ${deltaVNeeded.toFixed(2)} m/s Δv required`,
      burn: this.calculateVelocityMatchBurn(ship, target),
      autopilotMode: 'target'
    };
  }

  // Phase 4: Final Approach (<100m)
  private finalApproach(
    ship: Spacecraft,
    target: Target,
    relativeState: RelativeState
  ): RendezvousGuidance {
    // Goal: Approach slowly to docking range (50m)

    const dockingRange = 50; // m
    const approachSpeed = 0.5; // m/s

    if (relativeState.range < dockingRange) {
      this.phase = RendezvousPhase.DOCKING;
      return this.docking(ship, target, relativeState);
    }

    // Gentle approach
    if (Math.abs(relativeState.closingVelocity) > approachSpeed) {
      return {
        phase: RendezvousPhase.FINAL_APPROACH,
        instruction: `SLOW DOWN: Reduce to ${approachSpeed} m/s approach`,
        burn: this.calculateBrakingBurn(
          Math.abs(relativeState.closingVelocity) - approachSpeed,
          ship
        ),
        autopilotMode: 'retrograde'
      };
    }

    return {
      phase: RendezvousPhase.FINAL_APPROACH,
      instruction: `Approaching at ${Math.abs(relativeState.closingVelocity).toFixed(2)} m/s - ${relativeState.range.toFixed(1)}m to docking`,
      burn: null,
      autopilotMode: 'target'
    };
  }

  // Phase 5: Docking (<50m)
  private docking(
    ship: Spacecraft,
    target: Target,
    relativeState: RelativeState
  ): RendezvousGuidance {
    // See docking system in collision detection design
    // This hands off to precision docking controls

    return {
      phase: RendezvousPhase.DOCKING,
      instruction: `DOCKING MODE - Use RCS for fine control`,
      burn: null,
      autopilotMode: 'target',
      dockingActive: true
    };
  }
}

interface RendezvousGuidance {
  phase: RendezvousPhase;
  instruction: string;
  burn: InterceptSolution | null;
  autopilotMode: string;
  dockingActive?: boolean;
}
```

---

## Autopilot Integration

### Automatic Burn Execution

```typescript
class InterceptAutopilot {
  private activeBurn: InterceptSolution | null = null;
  private burnStartTime: number = 0;
  private burning: boolean = false;

  // Engage autopilot for intercept
  executeIntercept(burn: InterceptSolution, currentTime: number): void {
    this.activeBurn = burn;
    this.burnStartTime = currentTime + burn.burnStart;
    this.burning = false;
  }

  update(
    dt: number,
    currentTime: number,
    ship: Spacecraft,
    flightControl: FlightControl
  ): void {
    if (!this.activeBurn) return;

    // Time to start burn?
    if (!this.burning && currentTime >= this.burnStartTime) {
      this.burning = true;
      flightControl.setSASMode('hold'); // Hold current orientation
    }

    if (this.burning) {
      // Calculate remaining burn time
      const elapsedBurnTime = currentTime - this.burnStartTime;
      const remainingBurnTime = this.activeBurn.burnDuration - elapsedBurnTime;

      if (remainingBurnTime > 0) {
        // Apply thrust
        ship.engine.setThrottle(this.activeBurn.throttle);

        // Orient toward burn direction
        const targetAttitude = this.vectorToQuaternion(this.activeBurn.burnDirection);
        flightControl.setTargetAttitude(targetAttitude);

      } else {
        // Burn complete
        ship.engine.setThrottle(0);
        this.activeBurn = null;
        this.burning = false;
      }
    }
  }

  abort(): void {
    if (this.activeBurn) {
      ship.engine.setThrottle(0);
      this.activeBurn = null;
      this.burning = false;
    }
  }
}
```

---

## Player Displays

### Target Information Panel

```
TARGET INFORMATION
┌─────────────────────────────────┐
│ SELECTED: Station Alpha         │
│ TYPE: Station                   │
│ OBJECTIVE: DOCK                 │
│                                 │
│ RANGE: 8,542 m                  │
│ BEARING: 045° (NE)              │
│ ELEVATION: +2°                  │
│                                 │
│ RELATIVE VELOCITY               │
│   Closing: -12.4 m/s ↓          │
│   Lateral:  +2.1 m/s →          │
│                                 │
│ CLOSEST APPROACH                │
│   Time: 11 min 29 sec           │
│   Distance: 245 m               │
│                                 │
│ [PLAN INTERCEPT]                │
│ [MATCH VELOCITY]                │
│ [CLEAR TARGET]                  │
└─────────────────────────────────┘
```

### Intercept Plan Display

```
INTERCEPT SOLUTION
┌─────────────────────────────────┐
│ TARGET: Station Alpha (8.5 km)  │
│                                 │
│ OPTIMAL INTERCEPT               │
│   Time of Flight: 12 min 30 sec │
│   Total Δv: 45.2 m/s            │
│   Fuel Cost: 18.3 kg            │
│                                 │
│ BURN #1 (Prograde)              │
│   Start: T+2 min 15 sec         │
│   Duration: 22 seconds          │
│   Δv: 35.8 m/s                  │
│   Direction: 048° +5°           │
│   Throttle: 100%                │
│                                 │
│ BURN #2 (Retrograde)            │
│   Start: T+10 min 45 sec        │
│   Duration: 6 seconds           │
│   Δv: 9.4 m/s                   │
│   Direction: 228° -5°           │
│   Throttle: 100%                │
│                                 │
│ FEASIBLE: YES ✓                 │
│ Efficiency: 85%                 │
│                                 │
│ [EXECUTE AUTOPILOT]             │
│ [MANUAL CONTROL]                │
│ [RECALCULATE]                   │
└─────────────────────────────────┘
```

### Rendezvous Progress Display

```
RENDEZVOUS STATUS
┌─────────────────────────────────┐
│ PHASE: Station Keeping          │
│ TARGET: Station Alpha           │
│                                 │
│ PROGRESS: [████████░░] 80%      │
│                                 │
│ 1. Coarse Approach    ✓ DONE    │
│ 2. Fine Approach      ✓ DONE    │
│ 3. Station Keeping    ● CURRENT │
│ 4. Final Approach     ○ PENDING │
│ 5. Docking            ○ PENDING │
│                                 │
│ CURRENT STATUS                  │
│   Range: 485 m                  │
│   Closing: -0.2 m/s             │
│   Lateral: +0.1 m/s             │
│                                 │
│ GUIDANCE                        │
│ "Velocity matched - Ready for   │
│  final approach. Recommend RCS  │
│  control for precision."        │
│                                 │
│ [BEGIN FINAL APPROACH]          │
│ [HOLD POSITION]                 │
│ [ABORT RENDEZVOUS]              │
└─────────────────────────────────┘
```

---

## Integration with Game Systems

### With Navigation Computer

```typescript
class NavigationComputer {
  private targeting: TargetingSystem;
  private intercept: InterceptPlanner;
  private rendezvous: RendezvousManager;
  private autopilot: InterceptAutopilot;

  update(dt: number, ship: Spacecraft, world: World): void {
    if (!this.targeting.currentTarget) return;

    // Update target tracking
    const target = this.targeting.currentTarget;
    const targetBody = world.bodies.get(target.id);

    // Calculate relative state
    const relativeState = new RelativeMotionCalculator().calculateRelativeState(
      ship.state.position,
      ship.state.velocity,
      targetBody.position,
      targetBody.velocity
    );

    // Update rendezvous guidance
    const guidance = this.rendezvous.update(ship, target, relativeState);

    // Execute autopilot if active
    this.autopilot.update(dt, Date.now(), ship, ship.flightControl);

    // Display to player
    this.displayGuidance(guidance, relativeState);
  }
}
```

---

## Summary

**Target Selection:**
- Select from sensor contacts
- Different objectives (dock, approach, avoid, investigate)
- Track multiple targets with priorities

**Relative Motion:**
- Range, bearing, elevation
- Closing velocity, lateral velocity
- Closest approach prediction
- Time to intercept

**Intercept Planning:**
- Lambert's problem (time-fixed trajectory)
- Delta-v calculation
- Fuel cost estimation
- Optimal time of flight

**Rendezvous Phases:**
1. Coarse Approach (>10km)
2. Fine Approach (1-10km)
3. Station Keeping (velocity matching)
4. Final Approach (<100m)
5. Docking (<50m)

**Autopilot:**
- Automatic burn execution
- Attitude control during burns
- Multi-stage maneuvers
- Manual override available

**Player Experience:**
- All through instruments (no visual rendering)
- Clear guidance at each phase
- Autopilot option for convenience
- Manual control for precision

**Next:** Procedural content generation system design.
