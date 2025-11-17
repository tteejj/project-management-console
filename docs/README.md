# Vector Moon Lander - Design Documentation

## Overview

This directory contains comprehensive design documentation for the Vector Moon Lander game - a spacecraft systems simulator emphasizing indirect control through complex subsystems.

## Document Index

### [ARCHITECTURE_REVIEW.md](./ARCHITECTURE_REVIEW.md) ⭐ NEW
**Comprehensive architecture review and implementation status**

- Forward trace: Controls → Ship → Universe → Physics
- Reverse trace: Physics → Universe → Ship → Stations
- Gap analysis between documentation and implementation
- What's working, what's missing, what needs to be done
- Implementation roadmap with priorities
- Critical issues and recommendations

**Read this first** to understand current implementation status and next steps.

---

### [00-OVERVIEW.md](./00-OVERVIEW.md)
**Project vision, design philosophy, and core decisions**

- Design inspirations (FTL, Out There, Highfleet, DCS World, Dwarf Fortress)
- Core design pillars
- What this game is and isn't
- Design decisions taken and rejected
- Success criteria
- Project scope

**Read this second** to understand the overall vision.

---

### [01-CONTROL-STATIONS.md](./01-CONTROL-STATIONS.md)
**Complete specification of all control stations and controls**

- Helm/Propulsion Station (main engine, RCS, fuel management)
- Engineering Station (reactor, power distribution, thermal management)
- Navigation Station (sensors, radar, trajectory planning)
- Life Support Station (atmosphere, fire suppression, compartment control)
- UI/UX principles
- Control counts (MVP vs Full)

**Read this** for detailed panel layouts and control specifications.

---

### [02-PHYSICS-SIMULATION.md](./02-PHYSICS-SIMULATION.md)
**Physics engine and simulation systems**

- Orbital mechanics (simplified 2D)
- Propulsion physics (thrust, fuel, heat)
- Thermal physics (heat generation, propagation, cooling)
- Atmosphere & life support physics
- Fire & damage simulation
- Electrical system simulation
- System interconnections and emergent gameplay
- Performance considerations
- Tuning guidelines

**Read this** to understand how the simulation works under the hood.

---

### [03-EVENTS-PROGRESSION.md](./03-EVENTS-PROGRESSION.md)
**Campaign structure, events, and progression systems**

- Sector map structure (node-based, FTL-style)
- Event types:
  - Navigation challenges (docking, asteroid fields, intercepts)
  - Operational events (failures, fires, power loss)
  - Encounter events (derelicts, distress calls, trading)
  - Safe havens
- Random events (mid-jump)
- Resource economy (fuel, O2, parts)
- Meta-progression (unlocks, achievements)
- Difficulty curve
- Event scripting system

**Read this** for gameplay structure and content design.

---

### [04-TECHNICAL-ARCHITECTURE.md](./04-TECHNICAL-ARCHITECTURE.md)
**Technical implementation details**

- Technology stack (TypeScript + HTML5 Canvas)
- Project structure
- Core architecture patterns (ECS, event-driven, state machine)
- Data flow
- Rendering pipeline
- Color palette system
- Performance optimization
- Save system
- Testing strategy
- Build & deployment

**Read this** for technical implementation details.

---

### [05-MVP-ROADMAP.md](./05-MVP-ROADMAP.md)
**Development roadmap from MVP to full release**

- MVP scope definition
- 18-day MVP development plan (broken down by day)
- Phase-by-phase implementation
- Feature checklist
- Post-MVP roadmap (Weeks 4-12)
- Success metrics
- Risk mitigation
- Completion criteria

**Read this** for the development plan and timeline.

---

### [06-VISUAL-DESIGN-REFERENCE.md](./06-VISUAL-DESIGN-REFERENCE.md)
**Visual design, UI components, and rendering**

- Visual philosophy (retro-futuristic terminal aesthetic)
- Color palettes (green, amber, cyan, white)
- Typography (monospace only)
- UI components (boxes, buttons, gauges, sliders, indicators)
- Screen layouts
- Animations & visual feedback
- Vector graphics rendering (ship, trajectory, radar)
- Scanline effects
- Debug overlay

**Read this** for visual design guidelines and UI implementation.

---

## Quick Start

**For designers/game designers:**
1. Start with `00-OVERVIEW.md` (vision)
2. Read `01-CONTROL-STATIONS.md` (gameplay)
3. Read `03-EVENTS-PROGRESSION.md` (content)

**For developers:**
1. Start with `00-OVERVIEW.md` (vision)
2. Read `04-TECHNICAL-ARCHITECTURE.md` (tech stack)
3. Read `05-MVP-ROADMAP.md` (implementation plan)
4. Reference `02-PHYSICS-SIMULATION.md` as needed

**For artists/UI designers:**
1. Start with `00-OVERVIEW.md` (vision)
2. Read `06-VISUAL-DESIGN-REFERENCE.md` (visual style)
3. Reference `01-CONTROL-STATIONS.md` (panel layouts)

---

## Design Philosophy Summary

**Core Concept:**
A "submarine simulator in space" where players operate (not fly) a spacecraft through detailed control panels, managing interconnected systems and responding to cascading failures.

**Key Influences:**
- **FTL** (campaign structure, events)
- **Out There** (resource scarcity, exploration)
- **Highfleet** (esoteric controls, multi-panel interfaces)
- **DCS/MSFS** (procedural complexity)
- **Dwarf Fortress** (deep simulation, emergent gameplay)

**Design Pillars:**
1. Procedural complexity (multi-step operations)
2. Emergent simulation (system interactions)
3. Resource scarcity (meaningful choices)
4. Learning through failure (roguelike)
5. Retro-futuristic presentation (vector graphics, terminal UI)

**Scope:**
- 2-5 hour campaign
- 4-5 control stations
- 80-120 individual controls (full version)
- 20-30 campaign nodes
- Permadeath roguelike structure

---

## Document Status

**Design Docs:** ✅ Complete (v1.0)
**Implementation:** ⚠️ In Progress (40-50%)
**Last Updated:** 2025-11-17
**Version:** 1.1

## Implementation Status

### ✅ Complete (90-95%)
- **Physics simulation** - 9 integrated modules, 218/219 tests passing
- **Ship systems** - Fuel, electrical, thermal, coolant, propulsion, RCS
- **Flight control** - SAS with 10 modes, Autopilot with 5 modes
- **Navigation** - Trajectory prediction, telemetry, delta-V calculation

### ⚠️ Partial (40-50%)
- **User interface** - Single unified Captain Screen (vs. 4 planned stations)
- **Controls** - Simplified control set (20 vs. 86 documented controls)
- **Visual design** - Basic terminal text (vs. retro-futuristic aesthetic)

### ❌ Not Started (0-10%)
- **Life support system** - Atmosphere, fire simulation, compartments
- **Campaign structure** - FTL-style node map, events, progression
- **Multi-station interface** - 4 separate control stations with switching
- **Damage/repair system** - Detailed component health and repairs

**Current Priority:** Implement multi-station interface (see ARCHITECTURE_REVIEW.md)

**Estimated Time to MVP:** 5-6 weeks

**Next Steps:**
1. Read `ARCHITECTURE_REVIEW.md` for detailed gap analysis
2. Implement Priority 1 items (multi-station interface, detailed controls)
3. Implement Priority 2 items (life support, campaign structure)
4. Polish and playtest

---

## Contributing to Documentation

**When updating these docs:**
1. Maintain consistent formatting
2. Update "Last Updated" date
3. Increment version if major changes
4. Keep cross-references accurate
5. Add examples where helpful

**Markdown Style:**
- Use headers consistently (##, ###)
- Code blocks with language tags
- Tables for comparisons
- Lists for sequences
- Bold for emphasis, *italics* for terms

---

## Contact & Feedback

This is a living document. As development progresses and playtesting reveals insights, these docs will evolve.

**Key Questions to Revisit:**
- Are controls too complex or too simple?
- Is simulation depth appropriate?
- Is visual style effective?
- Is campaign length right?
- Is difficulty curve balanced?

**Playtesting will answer these questions.**

---

## License

[TBD - Add license for game and documentation]

---

## Changelog

**v1.1 (2025-11-17)**
- Added comprehensive architecture review (ARCHITECTURE_REVIEW.md)
- Added detailed implementation TODO (IMPLEMENTATION_TODO.md)
- Documented implementation status (40-50% complete)
- Identified critical gaps: multi-station interface, life support, campaign
- Updated README with current status
- Defined 5-6 week path to MVP

**v1.0 (2024-11-16)**
- Initial comprehensive documentation
- All 6 core documents completed
- MVP roadmap defined
- Ready for development
