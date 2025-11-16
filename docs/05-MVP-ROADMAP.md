# MVP Development Roadmap

## MVP Scope Definition

**Goal:** Playable prototype demonstrating core mechanics

**Time Estimate:** 2-3 weeks

**Success Criteria:**
- Can pilot ship using Helm controls
- Basic physics (thrust → velocity → position)
- 2-3 control stations functional
- 1-2 event types working
- Visual feedback (vector graphics)
- Settings (pause, color selection)
- One complete mission playable

**NOT in MVP:**
- Full campaign map
- All event types
- Meta-progression/unlocks
- Sound
- Polish/juice
- Tutorial
- Save system

---

## Phase 1: Foundation (Days 1-3)

### Day 1: Project Setup & Basic Rendering

**Tasks:**
- [ ] Initialize project with Vite + TypeScript
- [ ] Set up basic HTML structure
- [ ] Create Canvas rendering context
- [ ] Implement color palette system
- [ ] Basic vector renderer (lines, circles, text)
- [ ] Draw simple test shapes

**Deliverable:** Black canvas with colored vector graphics

**Files Created:**
```
/src
  - main.ts
  - renderer.ts
  - types.ts
/public
  - index.html
  - styles.css
package.json
tsconfig.json
vite.config.ts
```

---

### Day 2: Core Game Loop & Input

**Tasks:**
- [ ] Implement fixed timestep game loop
- [ ] Set up requestAnimationFrame
- [ ] Create input manager (keyboard)
- [ ] FPS counter / debug display
- [ ] Pause functionality

**Deliverable:** Game loop running at 60 FPS with pause toggle

**Files Created:**
```
/src
  - game.ts
  - input.ts
  - /utils
    - vector2.ts
    - math-utils.ts
```

---

### Day 3: Basic Physics & Ship Entity

**Tasks:**
- [ ] Implement Vector2 math utilities
- [ ] Create Ship class with position/velocity/rotation
- [ ] Implement basic 2D physics (F=ma integration)
- [ ] Apply thrust force → acceleration → velocity → position
- [ ] Render ship as simple triangle
- [ ] Render velocity vector

**Deliverable:** Ship that moves in response to thrust

**Files Created:**
```
/src
  - /core
    - ship.ts
    - physics.ts
```

**Test:**
```
Apply constant thrust → ship accelerates
Stop thrust → ship maintains velocity
Apply opposite thrust → ship decelerates
```

---

## Phase 2: Propulsion System (Days 4-6)

### Day 4: Main Engine Controls

**Tasks:**
- [ ] Create PropulsionSystem class
- [ ] Implement fuel valve (open/closed)
- [ ] Implement ignition (arm/fire sequence)
- [ ] Implement throttle (0-100%)
- [ ] Implement gimbal (X/Y angles)
- [ ] Fuel consumption based on throttle
- [ ] Engine temperature simulation

**Deliverable:** Functional main engine with multi-step startup

**Files Created:**
```
/src
  - /systems
    - propulsion.ts
```

**Test Procedure:**
```
1. Open fuel valve (F key)
2. Check fuel pressure (visual gauge)
3. Arm ignition (G key)
4. Fire ignition (H key)
5. Increase throttle (Q key)
6. Adjust gimbal (WASD keys)
7. Observe ship acceleration
8. Monitor engine temperature rising
```

---

### Day 5: RCS Thrusters & Fuel Management

**Tasks:**
- [ ] Implement 12 RCS thrusters (positions on ship)
- [ ] Each thruster applies force + torque
- [ ] Number keys (1-9,0,-,=) fire thrusters
- [ ] Implement fuel tank system (3 tanks)
- [ ] Fuel transfer between tanks
- [ ] Fuel mass affects ship mass
- [ ] Tank balance affects rotation tendency

**Deliverable:** Fine control using RCS, fuel management

**Files:**
- Extend `propulsion.ts`

**Test:**
```
Fire bow thruster → ship rotates
Fire port thruster → ship translates sideways
Transfer fuel → balance indicator changes
Unbalanced fuel → ship has rotation bias
```

---

### Day 6: Helm Panel UI

**Tasks:**
- [ ] Design Helm panel layout (ASCII mock-up)
- [ ] Implement panel rendering
- [ ] Draw all gauges (fuel, temp, pressure, throttle)
- [ ] Draw button states (valve, ignition, armed)
- [ ] Highlight active controls
- [ ] Real-time gauge updates

**Deliverable:** Full Helm station UI

**Files Created:**
```
/src
  - /ui
    - ui-manager.ts
    - /panels
      - helm-panel.ts
```

**Visual Check:**
- All controls visible
- Gauges update in real-time
- Color coding (green/yellow/red)
- Readable text

---

## Phase 3: Additional Systems (Days 7-10)

### Day 7: Electrical System

**Tasks:**
- [ ] Create ElectricalSystem class
- [ ] Implement reactor (start/scram/throttle)
- [ ] Implement battery (charge/discharge)
- [ ] Implement power buses (A/B)
- [ ] Implement circuit breakers (10 systems)
- [ ] Power consumption per system
- [ ] Blackout if battery depletes

**Deliverable:** Working power system with consequences

**Files Created:**
```
/src
  - /systems
    - electrical.ts
```

**Test:**
```
Start reactor → power generation
Turn on many breakers → battery drains
Battery hits 0% → blackout
Manually restore power → systems reboot
```

---

### Day 8: Thermal System (Simplified)

**Tasks:**
- [ ] Create ThermalSystem class
- [ ] Heat generation from engines and reactor
- [ ] Simplified heat propagation (single temperature for MVP)
- [ ] Coolant pump control
- [ ] Radiator deploy/retract
- [ ] Overheating consequences (engine shutdown, reactor SCRAM)

**Deliverable:** Heat management required during high thrust

**Files Created:**
```
/src
  - /systems
    - thermal.ts
```

**Test:**
```
Run engine at 100% for 60s → overheat warning
Continue → engine shuts down automatically
Deploy radiators → heat decreases
Activate coolant → heat decreases faster
```

---

### Day 9: Engineering Panel UI

**Tasks:**
- [ ] Design Engineering panel layout
- [ ] Render reactor controls
- [ ] Render circuit breaker grid
- [ ] Render thermal management controls
- [ ] Render system status indicators
- [ ] Real-time updates

**Deliverable:** Engineering station UI

**Files Created:**
```
/src
  - /ui
    - /panels
      - engineering-panel.ts
```

---

### Day 10: Station Switching & Settings

**Tasks:**
- [ ] Implement panel switching (1-4 number keys, or TAB)
- [ ] Show current panel indicator
- [ ] Create settings menu
- [ ] Implement color palette selection
- [ ] Implement pause toggle
- [ ] Settings persistence (localStorage)

**Deliverable:** Can switch between Helm and Engineering panels, customize colors

**Files Created:**
```
/src
  - settings.ts
```

---

## Phase 4: Navigation & Events (Days 11-14)

### Day 11: Navigation System & Sensors

**Tasks:**
- [ ] Create SensorSystem class
- [ ] Implement simple radar (detects nearby objects)
- [ ] Render tactical display (top-down 2D)
- [ ] Create celestial bodies (planets, asteroids)
- [ ] Calculate range/bearing to objects
- [ ] Velocity vector display

**Deliverable:** Navigation awareness

**Files Created:**
```
/src
  - /systems
    - sensors.ts
  - /core
    - world.ts (contains celestial bodies)
```

---

### Day 12: Navigation Panel UI

**Tasks:**
- [ ] Design Navigation panel layout
- [ ] Render tactical radar display
- [ ] Render contact list
- [ ] Render velocity vectors
- [ ] Sensor controls (range, gain)

**Deliverable:** Navigation station UI

**Files Created:**
```
/src
  - /ui
    - /panels
      - navigation-panel.ts
```

---

### Day 13: First Event - Precision Docking

**Tasks:**
- [ ] Create EventManager class
- [ ] Implement "Precision Docking" event
- [ ] Spawn target object with velocity
- [ ] Win condition: position within 50m, velocity within 0.5 m/s
- [ ] Failure condition: collision or timeout
- [ ] Event UI overlay (objective, timer)

**Deliverable:** Playable mission objective

**Files Created:**
```
/src
  - /events
    - event-manager.ts
    - navigation-events.ts
```

**Test:**
```
Event starts → target appears
Use helm controls → approach target
Match velocity → success message
Or crash into target → failure message
```

---

### Day 14: Second Event - Reactor Failure

**Tasks:**
- [ ] Implement "Reactor Failure" event
- [ ] Reactor shuts down mid-mission
- [ ] Player must restart before battery dies
- [ ] Timer display
- [ ] Success/failure outcomes

**Deliverable:** Second event type (operational)

**Files:**
- Extend `event-manager.ts`
- Add `operational-events.ts`

**Test:**
```
Reactor SCRAMs unexpectedly
Battery starts draining
Switch to Engineering panel
Restart reactor (10 second startup)
Monitor battery level
Success if reactor online before battery depletes
```

---

## Phase 5: Integration & Polish (Days 15-18)

### Day 15: System Interconnections

**Tasks:**
- [ ] Implement system dependency logic
  - No power → systems offline
  - Overheating → reactor/engine shutdown
  - Fuel depletion → engines offline
- [ ] Test cascade failures
- [ ] Balance tuning (fuel consumption, heat generation, power draw)

**Deliverable:** Systems feel interconnected

**Test Scenarios:**
```
1. Trip power breaker → dependent system stops
2. Overheat engine → automatic shutdown
3. Run out of fuel → engines disabled
4. Reactor SCRAM → battery drain → blackout
```

---

### Day 16: Simple Mission Sequence

**Tasks:**
- [ ] Create simple mission flow:
  1. Start with tutorial text ("Dock with station")
  2. Precision docking event
  3. Mid-mission reactor failure
  4. Resume to second docking
  5. Success screen
- [ ] Victory/defeat screens
- [ ] Basic mission state machine

**Deliverable:** Complete playable mission

**Files Created:**
```
/src
  - /campaign
    - mission.ts
```

---

### Day 17: UI Polish & Feedback

**Tasks:**
- [ ] Add visual feedback:
  - Button press highlights
  - Warning flashes (not constant blink)
  - Success/failure animations
- [ ] Improve layout consistency
- [ ] Ensure all text readable
- [ ] Add scanline effect (optional, toggle)
- [ ] Improve HUD clarity

**Deliverable:** UI feels polished

---

### Day 18: Bug Fixes & Balance

**Tasks:**
- [ ] Playtest extensively
- [ ] Fix critical bugs
- [ ] Balance tuning:
  - Fuel consumption rates
  - Heat generation/dissipation
  - Power draw
  - Event difficulty
  - Timer lengths
- [ ] Performance optimization (if needed)
- [ ] Write basic README

**Deliverable:** MVP ready for external playtesting

---

## MVP Feature Checklist

### Core Systems
- [x] 2D physics (position, velocity, acceleration)
- [x] Propulsion (main engine + RCS)
- [x] Fuel management (consumption, tanks, transfer)
- [x] Electrical (reactor, battery, breakers)
- [x] Thermal (heat generation, cooling)
- [x] Basic sensors (radar, contacts)

### UI/Controls
- [x] Helm panel (~25 controls)
- [x] Engineering panel (~20 controls)
- [x] Navigation panel (basic)
- [x] Panel switching
- [x] Settings menu (pause, color palette)
- [x] Vector graphics renderer
- [x] Real-time gauges/readouts

### Gameplay
- [x] Precision docking event
- [x] Reactor failure event
- [x] Mission structure (start → events → end)
- [x] Victory/defeat conditions
- [x] One complete playable mission

### Polish
- [x] Visual feedback (highlights, warnings)
- [x] Consistent UI layout
- [x] Readable text
- [x] 60 FPS performance
- [x] No game-breaking bugs

---

## Post-MVP: Full Version Roadmap

### Phase 6: Life Support & Atmosphere (Week 4)
- Atmosphere simulation (O2, CO2, pressure)
- Compartment system (6 compartments)
- Fire simulation
- Hull breach events
- Life Support panel UI
- Venting mechanics

### Phase 7: Campaign Structure (Week 5)
- Sector map generation
- Node-based navigation
- Multiple event types (10+ events)
- Resource persistence between missions
- Basic progression system

### Phase 8: Damage & Repair (Week 6)
- Detailed damage model
- Repair system (spare parts)
- System degradation
- Hull integrity
- Damage control procedures

### Phase 9: Events & Content (Week 7)
- All navigation events (asteroid field, debris, etc.)
- All operational events (fire, breach, power loss)
- Encounter events (derelict, distress, trading)
- Event variety and randomization

### Phase 10: Progression & Meta (Week 8)
- Unlockable ships
- Unlockable loadouts
- Achievement system
- Campaign completion tracking
- Difficulty modes

### Phase 11: Polish & Balance (Week 9-10)
- Full playtesting
- Balance tuning
- Bug fixing
- Performance optimization
- Visual polish
- Accessibility improvements

### Phase 12: Audio & Juice (Week 11)
- Sound effects (bleeps, warnings, ambient)
- Audio feedback for actions
- Atmospheric background sounds
- Audio settings

### Phase 13: Release Prep (Week 12)
- Documentation
- Tutorial/help system
- Packaging for itch.io / web
- Marketing materials (screenshots, GIF, trailer)
- Launch!

---

## Success Metrics

### MVP Playtest Goals
- Players complete mission without instructions (intuitive controls)
- Players retry after failure (engaging gameplay)
- No crashes or game-breaking bugs
- Performance maintains 60 FPS

### Questions to Answer
- Are controls too complex or too simple?
- Is difficulty appropriate?
- Is resource management engaging?
- Do systems feel interconnected?
- Is visual style readable and appealing?

### Feedback Collection
- Watch players (don't help unless stuck)
- Ask open-ended questions
- Note pain points
- Track completion rate
- Gather "fun factor" ratings

---

## Risk Mitigation

### Potential Risks

**Risk: Scope Creep**
- Mitigation: Stick to MVP checklist, defer features to post-MVP
- Reality check: Can it be cut and still demonstrate core concept?

**Risk: Physics Too Complex**
- Mitigation: Start simple, add complexity if needed
- Fallback: Simplified arcade physics if simulation too hard

**Risk: UI Too Cluttered**
- Mitigation: Test with real players early
- Iteration: Redesign panels based on feedback

**Risk: Performance Issues**
- Mitigation: Profile early, optimize hot paths
- Fallback: Reduce simulation frequency, simplify rendering

**Risk: Not Fun**
- Mitigation: Playtest frequently
- Pivot: Adjust difficulty, add/remove mechanics as needed

---

## Daily Development Checklist

**Each day:**
- [ ] Define clear goal for the day
- [ ] Commit code at end of day (even if incomplete)
- [ ] Test new feature manually
- [ ] Update this roadmap if priorities change
- [ ] Take breaks (prevent burnout)

**Each week:**
- [ ] Playtest current build
- [ ] Review progress vs. roadmap
- [ ] Adjust timeline if needed
- [ ] Backup project

---

## MVP Completion Definition

**MVP is DONE when:**
1. Can start game and reach mission
2. Can control ship using Helm and Engineering panels
3. Can complete "Precision Docking" event
4. Can experience and recover from "Reactor Failure" event
5. Can complete full mission (docking → failure → docking)
6. Can see victory screen
7. Can change color palette in settings
8. Can pause game
9. No crashes during normal play
10. Runs at 60 FPS

**At this point:** Get feedback, iterate, then proceed to full version.
