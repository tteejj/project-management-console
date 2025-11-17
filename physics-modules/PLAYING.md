# Playing the Lunar Lander

## Quick Start

```bash
cd physics-modules
npm install
npm run play
```

## Interactive Game Controls

The game is **fully playable** with keyboard controls and a real-time flight computer display.

### Controls

| Key | Action |
|-----|--------|
| **W** | Throttle up (increase thrust) |
| **S** | Throttle down (decrease thrust) |
| **A** | Rotate left |
| **D** | Rotate right |
| **Q** | Translate left (RCS thrusters) |
| **E** | Translate right (RCS thrusters) |
| **G** | Toggle landing gear |
| **ESC** | Quit game |

## Flight Computer Display

The game displays real-time information:

### Primary Flight Data
- **Altitude Above Ground** - Distance from surface terrain
- **Altitude MSL** - Distance from moon center
- **Terrain Elevation** - Height of surface at current location
- **Vertical Speed** - Rate of ascent/descent (with visual bar)
- **Horizontal Speed** - Lateral velocity (with visual bar)

### Position & Navigation
- **Latitude/Longitude** - Current coordinates
- **Waypoint** - Distance and bearing to active navigation point
- **Satellite** - Distance to orbital practice satellite

### Spacecraft Systems
- **Landing Gear Status** - Deployed/retracted, legs in contact, stability
- **Landing Gear Health** - Damage from hard landings
- **Throttle** - Current engine power (0-100%)
- **Thrust** - Force output in kilonewtons

### Environment
- **Surface Temperature** - Lunar surface temp (100-400K)
- **Illumination** - Day/night cycle

## Mission Objective

Land safely on the lunar surface with:
- **All 4 landing legs in contact**
- **Vertical speed < 5 m/s** (preferably < 1 m/s)
- **Stable landing** (no tipping)
- **Minimal gear damage**

## Landing Grades

- **S** - Perfect Landing (< 1 m/s, all legs healthy, stable)
- **A** - Excellent Landing (< 2 m/s, minimal damage, stable)
- **B** - Good Landing (< 3 m/s, some damage, 3+ legs)
- **C** - Rough Landing (< 5 m/s, moderate damage)
- **D** - Hard Landing (survived but damaged)
- **F** - Crash (spacecraft destroyed)

## Tips for Successful Landing

1. **Deploy landing gear early** (Press G at altitude > 5km)
2. **Reduce vertical speed gradually** - Use W to throttle up and slow descent
3. **Keep horizontal speed low** - Use Q/E for lateral corrections
4. **Watch terrain elevation** - Varies across the surface (-100m to +300m)
5. **Final approach** - Aim for < 5 m/s vertical, < 2 m/s horizontal
6. **Touchdown** - Gentle contact with all 4 legs for best score

## Spacecraft Specifications

- **Mass**: 23,000 kg (15,000 kg dry + 8,000 kg propellant)
- **Main Engine**: 45 kN maximum thrust
- **RCS Thrusters**: 25 N each (translation control)
- **Landing Gear**: 4 legs with spring-damper suspension
- **Leg Length**: 2.0 meters
- **Breaking Force**: 100 kN per leg

## Physics Simulation

All systems are fully simulated:

- **Gravity**: 1.622 m/s² (lunar gravity)
- **Terrain**: Procedurally generated with craters
- **Landing Gear**: Spring-damper physics (F = -kx - cv)
- **Environment**: Solar position, thermal cycling
- **Orbital Mechanics**: Satellite in 100km orbit
- **Navigation**: Waypoint guidance system

## Other Modes

### Watch Mode (Auto-simulation)
```bash
npm run game
```
Watch the spacecraft descend without controls (demonstrates physics).

### Demo Mode
```bash
npm run demo
```
See all physics systems in action with detailed output.

### Test Mode
```bash
npm test
```
Run 23 integration tests (100% passing).

## Troubleshooting

**Terminal too small?**
- Resize terminal to at least 80 columns x 40 rows for best display

**Controls not working?**
- Make sure terminal has focus
- Try pressing keys more deliberately
- ESC always quits

**Game runs too fast/slow?**
- Simulation runs at 10 FPS (0.1s timestep)
- Adjust FPS constant in code if needed

## Have Fun! 🚀🌙

Try to beat your landing score. Can you achieve the perfect S-rank landing?
