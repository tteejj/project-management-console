# Vector Moon Lander - Ship Control Stations UI

**Status:** ✅ Initial Implementation Complete

This is the HTML5 Canvas-based UI for the Vector Moon Lander game, featuring **4 separate control stations** as specified in the design documents.

## Overview

A spacecraft systems simulator emphasizing indirect control through complex subsystems. Players operate (not fly) a spacecraft by switching between dedicated control stations, managing interconnected systems and responding to cascading failures.

**Design Philosophy:** "Submarine simulator in space" - No single station shows everything. Players must switch between stations to get complete situational awareness.

## Implemented Stations

### Station 1: HELM / PROPULSION [1]
**Purpose:** Direct control of ship movement and propulsion systems

**Controls:**
- `F` - Toggle fuel valve (OPEN/CLOSED)
- `G` - Arm/disarm ignition
- `H` - Fire ignition (requires arm + valve open + pressure good)
- `R` - Emergency cutoff
- `Q/A` - Increase/decrease throttle
- `W/S` - Gimbal up/down
- `E/D` - Gimbal left/right
- `1-0` - Fire RCS thrusters

**Displays:**
- Main engine status (valve, ignition, thrust, throttle)
- Gimbal angles (X/Y)
- RCS thruster layout (12 thrusters)
- Fuel tanks (3 tanks with percentages)
- Engine temperature, pressure, flow

### Station 2: ENGINEERING / POWER [2]
**Purpose:** Power generation, distribution, thermal management

**Controls:**
- `R` - Start reactor
- `T` - SCRAM (emergency shutdown)
- `I/K` - Increase/decrease reactor throttle
- `1-0` - Toggle 10 circuit breakers
- `G` - Deploy/retract radiators

**Displays:**
- Reactor status and throttle
- Power distribution (10 breakers)
- Battery charge
- Thermal management (coolant, radiators)

### Station 3: NAVIGATION / SENSORS [3]
**Purpose:** Situational awareness, trajectory planning, sensor management

**Controls:**
- `R` - Toggle radar ON/OFF
- `Z/X` - Increase/decrease radar range
- `C/V` - Increase/decrease radar gain
- `L` - Toggle LIDAR active/passive

**Displays:**
- Tactical radar display (top-down 2D)
- Sensor status (radar, LIDAR, thermal)
- Contact list (range, bearing, velocity)
- Velocity vectors

### Station 4: LIFE SUPPORT / ENVIRONMENTAL [4]
**Purpose:** Atmosphere management, compartment control

**Controls:**
- `1-6` - Select compartment
- `O` - Toggle O2 generator ON/OFF
- `S` - Toggle CO2 scrubber ON/OFF

**Displays:**
- Ship layout (6 compartments)
- Atmosphere readings (O2, CO2, pressure, temp)
- Global systems status
- Fire suppression (future)
- Emergency venting (future)

## Station Switching

- **Number keys `1-4`** - Jump directly to a station
- **TAB** - Cycle through stations (future)
- Current station shown in top-right corner: `[X/4] STATION NAME`

## Tech Stack

- **TypeScript** - Type-safe game logic
- **HTML5 Canvas 2D** - Vector graphics rendering
- **Vite** - Fast dev server and build tool
- **No game engine** - Full control, minimal overhead

## Project Structure

```
/game
├── index.html              # HTML shell
├── styles.css              # Minimal CSS
├── package.json            # Dependencies
├── tsconfig.json           # TypeScript config
├── vite.config.ts          # Vite config
└── /src
    ├── main.ts             # Entry point
    ├── game.ts             # Game loop
    ├── input.ts            # Input handling
    └── /ui
        ├── ui-manager.ts           # Station switching
        └── /panels
            ├── helm-panel.ts        # Station 1
            ├── engineering-panel.ts # Station 2
            ├── navigation-panel.ts  # Station 3
            └── lifesupport-panel.ts # Station 4
```

## Development

```bash
cd game

# Install dependencies
npm install

# Run dev server (http://localhost:3000)
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Integration with Physics Engine

**Status:** Not yet integrated

The physics modules are located in `/physics-modules` and need to be imported and connected to the UI. Each station will read from and control the spacecraft simulation.

### Next Steps for Integration:
1. Import `Spacecraft` class from `../physics-modules/src/spacecraft`
2. Create spacecraft instance in `game.ts`
3. Connect each station panel to corresponding spacecraft systems:
   - HELM → mainEngine, rcs, fuelSystem
   - ENGINEERING → electrical, thermal, coolant
   - NAVIGATION → navigation, sensors
   - LIFE SUPPORT → atmosphere (future)
4. Update station displays based on real spacecraft telemetry
5. Route control inputs to spacecraft systems

## Design Documents

See `/docs` for comprehensive design specifications:
- `01-CONTROL-STATIONS.md` - Complete station specifications
- `02-PHYSICS-SIMULATION.md` - Physics engine details
- `04-TECHNICAL-ARCHITECTURE.md` - Architecture overview
- `05-MVP-ROADMAP.md` - Development plan

## Color Palette

**Current:** Green monochrome (retro terminal aesthetic)
- Background: `#000000`
- Primary: `#00ff00`
- Secondary: `#00aa00`
- Muted: `#006600`
- Warning: `#ffff00`
- Danger: `#ff0000`
- Info: `#00ffff`

**Future:** Selectable palettes (green, amber, cyan, white)

## Status

### ✅ Completed
- [x] HTML5 Canvas infrastructure
- [x] Station switching system (1-4 keys)
- [x] All 4 station panels implemented with UI
- [x] HELM station fully functional (26 controls)
- [x] ENGINEERING station skeleton (22 controls)
- [x] NAVIGATION station skeleton (18 controls)
- [x] LIFE SUPPORT station skeleton (20 controls)
- [x] Keyboard input handling
- [x] Retro terminal aesthetic

### 🚧 In Progress
- [ ] Integration with physics engine
- [ ] Real telemetry displays
- [ ] TAB key station cycling
- [ ] Settings menu (pause, color palette)

### 📋 TODO
- [ ] Connect to spacecraft simulation
- [ ] Implement game loop with physics updates
- [ ] Add visual feedback (warnings, highlights)
- [ ] Mission system integration
- [ ] Event system
- [ ] Save/load system
- [ ] Tutorial/help screen

## Screenshots

*(Screenshots will be added once game is running)*

## License

MIT

---

**Built according to design docs in `/docs`**
**Physics engine in `/physics-modules`**
