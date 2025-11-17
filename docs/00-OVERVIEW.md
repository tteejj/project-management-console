# Vector Moon Lander - Design Overview

## Project Vision

A spacecraft systems simulator that emphasizes **indirect control through complex subsystems** rather than direct piloting. Players manage a small spacecraft through detailed control panels, responding to cascading system failures, resource scarcity, and navigational challenges.

## Core Concept

**"Submarine Simulator in Space"**

Players don't fly the ship - they **operate** it. Navigation happens through instruments, controls require multi-step procedures, and every action has physical consequences through interconnected systems.

## Design Inspirations

### Primary Influences

**1. FTL: Faster Than Light**
- **What we take**: Event-driven exploration, node-based campaign map, permadeath stakes, resource scarcity
- **What we add**: Actual system operation instead of clicking abstract buttons
- **Why**: Proven gameplay loop that creates tension and meaningful choices

**2. Out There / Out There: Omega Edition**
- **What we take**: Resource management focus, exploration structure, event variety, procedural encounters
- **What we add**: Deep simulation and manual control of ship systems
- **Why**: Perfect balance of strategy and storytelling through gameplay

**3. Highfleet**
- **What we take**: Esoteric control schemes, indirect control philosophy, multiple workstations, systems that can fail
- **What we add**: More focus on procedures and detailed simulation
- **Why**: Creates engaging skill-based gameplay through unusual interfaces

**4. DCS World / Microsoft Flight Simulator**
- **What we take**: Procedural complexity, checklist-driven operations, systems mastery
- **What we simplify**: Not aiming for real-world accuracy, but capturing the *feel* of complex procedures
- **Why**: Provides depth and learning curve

**5. Dwarf Fortress**
- **What we take**: Deep simulation with emergent behaviors, interconnected systems
- **What we simplify**: Much simpler presentation, focused scope
- **Why**: Creates memorable moments through system interactions

**6. 1980s Sci-Fi Films (Alien, 2001, Das Boot)**
- **What we take**: Aesthetic (CRT displays, vector graphics, utilitarian interfaces), claustrophobic atmosphere
- **Why**: Creates immersive retro-futuristic feel

## Design Pillars

### 1. Procedural Complexity
Every action requires multiple steps across different panels. This IS the game.

**Example**: Firing main engine
- NOT: Press spacebar
- INSTEAD: Open fuel valve → check pressure → arm ignition → set throttle → adjust gimbal → monitor temperature → manage coolant

### 2. Emergent Simulation
Systems interact realistically to create unexpected situations.

**Example**: Hull breach creates thrust vector from venting atmosphere, which could save you or doom you depending on direction.

### 3. Resource Scarcity
Limited fuel, oxygen, power, and repair parts create constant tension and meaningful choices.

### 4. Learning Through Failure
Permadeath roguelike structure where each run teaches you more about the systems.

### 5. Retro-Futuristic Presentation
Vector graphics, monochrome displays, keyboard-driven interfaces evoke 1980s spacecraft aesthetics.

## What This Game IS

- A **systems management simulator** with exploration framework
- About **mastering procedures** and managing cascading failures
- **Short sessions** (5-20 minutes per run, 2-5 hours total campaign)
- **Keyboard-driven** procedural gameplay
- **Emergent stories** from system interactions

## What This Game IS NOT

- NOT a traditional space shooter or arcade game
- NOT scientifically accurate (simplified physics that feel right)
- NOT story-heavy (narrative emerges from gameplay)
- NOT graphically complex (deliberately simple vector graphics)
- NOT thousands of hours of content (focused, replayable experience)

## Design Decisions Taken

### ✅ Chosen Directions

**Technology Stack: TypeScript + HTML5 Canvas**
- Rationale: Full control, lightweight, instant distribution, proven performance
- Alternative considered: Python (rejected - wrong platform, unnecessary complexity)
- Alternative considered: Game engine (rejected - too much overhead for this style)

**No Crew System (MVP)**
- Rationale: Reduces complexity, focuses on ship systems
- Future: Could add crew as expansion

**Real-time with Optional Pause**
- Rationale: Player choice, enables different playstyles
- Implementation: Toggle in settings, pause anytime

**Player-Selectable Color Palette**
- Rationale: Accessibility and personal preference
- Options: Green, amber, white, cyan monochrome

**No Sound (Initial)**
- Rationale: Focus on core gameplay first
- Future: Add bleeps/bloops later for atmosphere

**Small Ship Focus**
- Rationale: Easier to learn, faster iterations, clearer cause-effect
- Future: Unlock larger ships with more systems

**Node-Based Campaign Map**
- Rationale: Proven structure (FTL), creates pacing, enables varied content
- Alternative considered: Open space (rejected - too diffuse)

**Permadeath Roguelike**
- Rationale: Creates stakes, encourages mastery, high replayability
- Mitigation: Meta-progression unlocks

## Design Decisions NOT Taken

### ❌ Rejected or Deferred

**Scientific Accuracy**
- Why not: Would require complex 3D orbital mechanics, real atmospheric chemistry
- What instead: Simplified 2D physics that *feel* right
- Future: Could add "simulation mode" for enthusiasts

**Story Campaign**
- Why not: Development time, not core to gameplay
- What instead: Procedural encounters create emergent narrative
- Future: Could add lore through encounter text

**Multiplayer/Co-op**
- Why not: Scope, technical complexity
- What instead: Single-player focused experience
- Future: Co-op could be interesting (multiple stations)

**3D Graphics**
- Why not: Unnecessary complexity, wrong aesthetic
- What instead: Pure 2D vector graphics
- Never: This is a deliberate aesthetic choice

**Combat Focus**
- Why not: Changes genre to shooter
- What instead: Navigation, operations, and survival challenges
- Maybe: Light combat/defense as one challenge type

**Huge Game World**
- Why not: Not "shortish" anymore
- What instead: 20-30 node campaign, 2-5 hour completion time
- Future: Could add endless mode

**Voice Acting / Cutscenes**
- Why not: Wrong tone, development time
- What instead: Text-based encounters, silent operation
- Never: Breaks immersion of being alone with instruments

**Tutorial Missions**
- Why not (initially): Development time
- What instead: Jump in and learn by doing
- Future: Tutorial could be added based on feedback

**Crew Management**
- Why deferred: Adds complexity before core systems proven
- What instead: Solo operation initially
- Future: Strong candidate for expansion

**Economy/Trading System**
- Why deferred: Not core loop
- What instead: Simple resource management
- Future: Could add station trading

## Success Criteria

### MVP Success
- Controls feel tactile and meaningful
- Basic system simulation creates emergent situations
- One complete run takes 15-30 minutes
- Players want to retry after failure

### Full Release Success
- Players spend 2-5 hours to complete campaign
- High replayability (different challenges each run)
- Community shares "war stories" of memorable moments
- Speedrunning community emerges

## Project Scope

**Target Timeline:**
- MVP: 2-3 weeks
- Full release: 6-8 weeks
- Polish/balance: 2-4 weeks

**Target Complexity:**
- 30-40 ship systems in final version
- 4-5 control stations
- 80-120 individual controls
- 20-30 campaign nodes
- 15-25 event types

**File Size Goals:**
- Under 5MB total (mostly code, minimal assets)
- Runs in any modern browser
- No external dependencies at runtime
