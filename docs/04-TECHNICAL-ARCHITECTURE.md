# Technical Architecture

## Technology Stack

### Core Technologies

**Language:** TypeScript
- Type safety for complex simulations
- Better IDE support
- Catches bugs at compile time
- Easy refactoring

**Runtime:** Browser (HTML5)
- Universal platform
- No installation required
- Instant distribution
- Cross-platform by default

**Rendering:** HTML5 Canvas 2D
- Perfect for vector graphics
- Lightweight
- Direct pixel control
- Fast enough for our needs

**Build Tools:**
- **Vite** - Fast dev server, hot reload, optimized builds
- **TypeScript Compiler** - Type checking and transpilation
- **ESLint** - Code quality
- **Prettier** - Code formatting

**No External Game Engines:**
- Full control over simulation
- Minimal overhead
- Easier to debug
- Smaller bundle size

---

## Project Structure

```
/moon-lander
├── /src
│   ├── main.ts                    # Entry point, game initialization
│   ├── game.ts                    # Main game loop, orchestration
│   ├── input.ts                   # Keyboard/mouse input handling
│   ├── settings.ts                # Game settings, config
│   │
│   ├── /core                      # Core game systems
│   │   ├── ship.ts                # Ship state and properties
│   │   ├── physics.ts             # Physics engine (2D)
│   │   ├── simulation.ts          # Master simulation coordinator
│   │   └── types.ts               # Shared type definitions
│   │
│   ├── /systems                   # Ship systems (modular)
│   │   ├── propulsion.ts          # Engine, RCS, fuel
│   │   ├── electrical.ts          # Reactor, power, batteries
│   │   ├── thermal.ts             # Heat generation/dissipation
│   │   ├── atmosphere.ts          # Life support, gases
│   │   ├── damage.ts              # Damage model, repairs
│   │   └── sensors.ts             # Radar, LIDAR, etc.
│   │
│   ├── /ui                        # User interface
│   │   ├── renderer.ts            # Canvas rendering engine
│   │   ├── ui-manager.ts          # UI state management
│   │   ├── hud.ts                 # HUD overlay
│   │   └── /panels                # Control station panels
│   │       ├── helm-panel.ts
│   │       ├── engineering-panel.ts
│   │       ├── navigation-panel.ts
│   │       └── lifesupport-panel.ts
│   │
│   ├── /campaign                  # Campaign/progression
│   │   ├── campaign.ts            # Campaign state management
│   │   ├── sector-map.ts          # Node-based map generation
│   │   ├── events.ts              # Event system
│   │   └── progression.ts         # Unlocks, achievements
│   │
│   ├── /events                    # Event definitions
│   │   ├── event-manager.ts       # Event orchestration
│   │   ├── navigation-events.ts   # Navigation challenges
│   │   ├── operational-events.ts  # System failures, etc.
│   │   └── encounter-events.ts    # Derelicts, distress, etc.
│   │
│   ├── /utils                     # Utility functions
│   │   ├── vector2.ts             # 2D vector math
│   │   ├── math-utils.ts          # Common math functions
│   │   └── constants.ts           # Game constants
│   │
│   └── /data                      # Game data (JSON)
│       ├── ship-configs.json      # Ship specifications
│       ├── events-db.json         # Event definitions
│       └── unlocks.json           # Progression data
│
├── /public                        # Static assets
│   ├── index.html                 # HTML shell
│   └── styles.css                 # Minimal CSS
│
├── /docs                          # Design documentation
│   ├── 00-OVERVIEW.md
│   ├── 01-CONTROL-STATIONS.md
│   ├── 02-PHYSICS-SIMULATION.md
│   ├── 03-EVENTS-PROGRESSION.md
│   └── 04-TECHNICAL-ARCHITECTURE.md
│
├── package.json                   # Dependencies
├── tsconfig.json                  # TypeScript config
├── vite.config.ts                 # Vite config
└── README.md                      # Project readme
```

---

## Core Architecture Patterns

### 1. Entity-Component-System (Simplified)

**Ship as Entity:**
```typescript
class Ship {
  // Core state
  position: Vector2;
  velocity: Vector2;
  rotation: number;
  mass: number;

  // Systems (components)
  propulsion: PropulsionSystem;
  electrical: ElectricalSystem;
  thermal: ThermalSystem;
  atmosphere: AtmosphereSystem;
  damage: DamageSystem;
  sensors: SensorSystem;

  // Update all systems
  update(dt: number) {
    this.propulsion.update(dt, this);
    this.electrical.update(dt, this);
    this.thermal.update(dt, this);
    this.atmosphere.update(dt, this);
    this.damage.update(dt, this);
    this.sensors.update(dt, this);
  }
}
```

**Benefits:**
- Modular systems
- Easy to add/remove systems
- Clear dependencies
- Testable in isolation

### 2. Event-Driven Architecture

**Event Bus:**
```typescript
class EventBus {
  private listeners: Map<string, Function[]> = new Map();

  on(event: string, callback: Function) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event)!.push(callback);
  }

  emit(event: string, data?: any) {
    if (this.listeners.has(event)) {
      for (let callback of this.listeners.get(event)!) {
        callback(data);
      }
    }
  }
}

// Usage:
eventBus.on('fire-started', (compartment) => {
  ui.showWarning(`Fire in compartment ${compartment}!`);
  audio.playAlert();
});

eventBus.emit('fire-started', 3);
```

**Benefits:**
- Decoupled systems
- Easy to add new reactions
- Clear cause-effect chains
- Debugging-friendly (can log all events)

### 3. State Machine for Game States

**Game States:**
```typescript
enum GameState {
  MAIN_MENU,
  CAMPAIGN_MAP,
  IN_MISSION,
  PAUSED,
  EVENT_SCREEN,
  GAME_OVER,
  VICTORY
}

class GameStateMachine {
  private currentState: GameState;
  private states: Map<GameState, StateHandler> = new Map();

  transition(newState: GameState) {
    this.states.get(this.currentState)?.onExit();
    this.currentState = newState;
    this.states.get(this.currentState)?.onEnter();
  }

  update(dt: number) {
    this.states.get(this.currentState)?.update(dt);
  }

  render(ctx: CanvasRenderingContext2D) {
    this.states.get(this.currentState)?.render(ctx);
  }
}
```

**Benefits:**
- Clear state transitions
- No state confusion
- Easy to add new states
- Prevents invalid operations

### 4. Fixed Timestep Game Loop

**Ensures deterministic physics:**
```typescript
class Game {
  private lastTime = 0;
  private accumulator = 0;
  private readonly FIXED_DT = 1/60; // 60 FPS physics

  gameLoop(currentTime: number) {
    const frameTime = (currentTime - this.lastTime) / 1000; // to seconds
    this.lastTime = currentTime;

    this.accumulator += frameTime;

    // Fixed timestep updates
    while (this.accumulator >= this.FIXED_DT) {
      this.update(this.FIXED_DT);
      this.accumulator -= this.FIXED_DT;
    }

    // Render (can be at variable framerate)
    this.render();

    requestAnimationFrame((t) => this.gameLoop(t));
  }

  update(dt: number) {
    if (this.isPaused) return;

    this.ship.update(dt);
    this.events.update(dt);
    this.ui.update(dt);
  }

  render() {
    this.renderer.clear();
    this.renderer.renderShip(this.ship);
    this.renderer.renderUI(this.ui);
    this.renderer.present();
  }
}
```

**Benefits:**
- Consistent physics regardless of framerate
- Deterministic (same inputs = same outputs)
- Prevents spiral of death
- Smooth rendering

---

## Data Flow

```
User Input
    ↓
Input Manager (keyboard/mouse)
    ↓
UI Panels (process input, update ship systems)
    ↓
Ship Systems (update internal state)
    ↓
Physics Engine (apply forces, integrate motion)
    ↓
Event System (check triggers, emit events)
    ↓
UI Manager (update displays)
    ↓
Renderer (draw to canvas)
    ↓
Screen
```

**One-Way Data Flow:**
- Input → State → Render
- No circular dependencies
- Predictable behavior
- Easy to debug

---

## Rendering Pipeline

### Canvas Setup

```typescript
class Renderer {
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D;
  private width: number;
  private height: number;
  private colorPalette: ColorPalette;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d')!;
    this.resize();
  }

  resize() {
    this.width = window.innerWidth;
    this.height = window.innerHeight;
    this.canvas.width = this.width;
    this.canvas.height = this.height;
  }

  clear() {
    this.ctx.fillStyle = this.colorPalette.background;
    this.ctx.fillRect(0, 0, this.width, this.height);
  }
}
```

### Vector Graphics Rendering

**All graphics are vector-based (lines, circles, text):**

```typescript
class VectorRenderer {
  drawShip(ship: Ship, ctx: CanvasRenderingContext2D) {
    ctx.save();
    ctx.translate(ship.position.x, ship.position.y);
    ctx.rotate(ship.rotation);

    // Draw ship outline (triangle)
    ctx.beginPath();
    ctx.moveTo(10, 0);
    ctx.lineTo(-5, 5);
    ctx.lineTo(-5, -5);
    ctx.closePath();
    ctx.strokeStyle = this.colorPalette.primary;
    ctx.lineWidth = 2;
    ctx.stroke();

    // Draw engine thrust indicator
    if (ship.propulsion.isThrusting) {
      ctx.beginPath();
      ctx.moveTo(-5, 0);
      ctx.lineTo(-10, 0);
      ctx.strokeStyle = this.colorPalette.accent;
      ctx.stroke();
    }

    ctx.restore();
  }

  drawTrajectory(ship: Ship, ctx: CanvasRenderingContext2D) {
    // Project future position
    const steps = 100;
    const dt = 1.0;
    let pos = {...ship.position};
    let vel = {...ship.velocity};

    ctx.beginPath();
    ctx.moveTo(pos.x, pos.y);

    for (let i = 0; i < steps; i++) {
      // Simple integration
      pos.x += vel.x * dt;
      pos.y += vel.y * dt;
      ctx.lineTo(pos.x, pos.y);
    }

    ctx.strokeStyle = this.colorPalette.secondary;
    ctx.setLineDash([5, 5]);
    ctx.stroke();
    ctx.setLineDash([]);
  }
}
```

### Panel Rendering

**Each control panel is a separate render function:**

```typescript
class HelmPanelRenderer {
  render(ctx: CanvasRenderingContext2D, ship: Ship) {
    const x = 50;
    const y = 50;

    // Draw panel background
    this.drawBox(ctx, x, y, 400, 600, 'HELM CONTROL [1/5]');

    // Draw main engine controls
    this.drawEngineControls(ctx, x + 20, y + 40, ship.propulsion);

    // Draw RCS thrusters
    this.drawRCSControls(ctx, x + 220, y + 40, ship.propulsion);

    // Draw fuel status
    this.drawFuelStatus(ctx, x + 220, y + 300, ship.propulsion);
  }

  drawBox(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, title: string) {
    // Draw border
    ctx.strokeStyle = this.colorPalette.primary;
    ctx.strokeRect(x, y, w, h);

    // Draw title bar
    ctx.fillStyle = this.colorPalette.background;
    ctx.fillRect(x, y, w, 30);
    ctx.strokeRect(x, y, w, 30);

    // Draw title text
    ctx.fillStyle = this.colorPalette.primary;
    ctx.font = '16px monospace';
    ctx.fillText(title, x + 10, y + 20);
  }

  drawGauge(ctx: CanvasRenderingContext2D, x: number, y: number, value: number, max: number, label: string) {
    const width = 100;
    const height = 10;
    const fillWidth = (value / max) * width;

    // Draw outline
    ctx.strokeStyle = this.colorPalette.primary;
    ctx.strokeRect(x, y, width, height);

    // Draw fill
    ctx.fillStyle = this.getGaugeColor(value, max);
    ctx.fillRect(x, y, fillWidth, height);

    // Draw label
    ctx.fillStyle = this.colorPalette.primary;
    ctx.font = '12px monospace';
    ctx.fillText(label, x, y - 5);
    ctx.fillText(`${value.toFixed(0)}%`, x + width + 10, y + 10);
  }

  getGaugeColor(value: number, max: number): string {
    const percent = value / max;
    if (percent > 0.6) return this.colorPalette.good;
    if (percent > 0.3) return this.colorPalette.warning;
    return this.colorPalette.critical;
  }
}
```

---

## Color Palette System

**Player-selectable monochrome themes:**

```typescript
interface ColorPalette {
  background: string;    // Usually black
  primary: string;       // Main UI color
  secondary: string;     // Secondary elements
  accent: string;        // Highlights
  good: string;          // Positive status (green zone)
  warning: string;       // Caution (yellow zone)
  critical: string;      // Danger (red zone)
}

const PALETTES: Record<string, ColorPalette> = {
  green: {
    background: '#000000',
    primary: '#00FF00',
    secondary: '#008800',
    accent: '#00FF88',
    good: '#00FF00',
    warning: '#88FF00',
    critical: '#FF0000'
  },
  amber: {
    background: '#000000',
    primary: '#FFAA00',
    secondary: '#AA6600',
    accent: '#FFDD00',
    good: '#88FF00',
    warning: '#FFAA00',
    critical: '#FF0000'
  },
  cyan: {
    background: '#000000',
    primary: '#00FFFF',
    secondary: '#0088AA',
    accent: '#88FFFF',
    good: '#00FF00',
    warning: '#FFAA00',
    critical: '#FF0000'
  },
  white: {
    background: '#000000',
    primary: '#FFFFFF',
    secondary: '#888888',
    accent: '#CCCCCC',
    good: '#00FF00',
    warning: '#FFAA00',
    critical: '#FF0000'
  }
};
```

**Scanline Effect (Optional):**
```typescript
class ScanlineEffect {
  apply(ctx: CanvasRenderingContext2D) {
    ctx.fillStyle = 'rgba(0, 0, 0, 0.1)';
    for (let y = 0; y < ctx.canvas.height; y += 2) {
      ctx.fillRect(0, y, ctx.canvas.width, 1);
    }
  }
}
```

---

## Performance Optimization

### 1. Object Pooling

**For frequently created/destroyed objects:**
```typescript
class ParticlePool {
  private pool: Particle[] = [];
  private active: Particle[] = [];

  get(): Particle {
    let particle = this.pool.pop();
    if (!particle) {
      particle = new Particle();
    }
    this.active.push(particle);
    return particle;
  }

  release(particle: Particle) {
    const index = this.active.indexOf(particle);
    if (index > -1) {
      this.active.splice(index, 1);
      this.pool.push(particle);
    }
  }
}
```

### 2. Spatial Partitioning

**For collision detection (if needed):**
```typescript
class QuadTree {
  // Only check collisions for nearby objects
  // Reduces O(n²) to O(n log n)
}
```

### 3. Dirty Flag Pattern

**Only re-render when something changed:**
```typescript
class Panel {
  private dirty = true;
  private cachedCanvas: HTMLCanvasElement;

  render(ctx: CanvasRenderingContext2D) {
    if (this.dirty) {
      this.renderToCache();
      this.dirty = false;
    }
    ctx.drawImage(this.cachedCanvas, 0, 0);
  }

  markDirty() {
    this.dirty = true;
  }
}
```

### 4. requestAnimationFrame

**Browser-optimized rendering:**
```typescript
function gameLoop(timestamp: number) {
  update(deltaTime);
  render();
  requestAnimationFrame(gameLoop);
}
requestAnimationFrame(gameLoop);
```

---

## Save System

**LocalStorage for persistence:**

```typescript
interface SaveData {
  version: number;
  ship: ShipState;
  campaign: CampaignState;
  unlocks: UnlockState;
  settings: SettingsState;
}

class SaveManager {
  save(data: SaveData) {
    const json = JSON.stringify(data);
    localStorage.setItem('moon-lander-save', json);
  }

  load(): SaveData | null {
    const json = localStorage.getItem('moon-lander-save');
    if (!json) return null;

    const data = JSON.parse(json);

    // Version migration
    if (data.version < CURRENT_VERSION) {
      return this.migrate(data);
    }

    return data;
  }

  delete() {
    localStorage.removeItem('moon-lander-save');
  }
}
```

---

## Testing Strategy

### Unit Tests
- Physics calculations (vector math, integration)
- System logic (fuel consumption, heat transfer)
- Event conditions (triggers, outcomes)

### Integration Tests
- System interactions (fire → heat → power loss)
- Event chains
- Save/load

### Manual Playtesting
- Balance
- Fun factor
- Edge cases
- Exploits

**Testing Tools:**
- Jest (unit testing)
- Playwright (browser testing)
- Dev console (manual testing, cheats)

---

## Build & Deployment

**Development:**
```bash
npm run dev        # Start Vite dev server
npm run build      # Production build
npm run preview    # Preview production build
```

**Production Build:**
- TypeScript → JavaScript (transpiled)
- Bundled (single .js file)
- Minified
- Source maps (for debugging)

**Deployment Options:**
1. **GitHub Pages** (free, easy)
2. **Netlify** (free tier, CI/CD)
3. **itch.io** (game platform)
4. **Self-hosted** (static files)

**Bundle Size Target:** < 1MB total (code + assets)

---

## Development Tools

### Debug Panel

**Toggle with F12:**
```typescript
class DebugPanel {
  render(ctx: CanvasRenderingContext2D, ship: Ship) {
    ctx.fillStyle = 'rgba(0, 0, 0, 0.8)';
    ctx.fillRect(10, 10, 300, 400);

    ctx.fillStyle = '#00FF00';
    ctx.font = '12px monospace';

    let y = 30;
    ctx.fillText(`FPS: ${this.fps.toFixed(1)}`, 20, y); y += 20;
    ctx.fillText(`Position: ${ship.position.x.toFixed(1)}, ${ship.position.y.toFixed(1)}`, 20, y); y += 20;
    ctx.fillText(`Velocity: ${ship.velocity.x.toFixed(2)}, ${ship.velocity.y.toFixed(2)}`, 20, y); y += 20;
    ctx.fillText(`Fuel: ${ship.propulsion.fuel.toFixed(1)} kg`, 20, y); y += 20;
    ctx.fillText(`Power: ${ship.electrical.reactor.outputKW.toFixed(2)} kW`, 20, y); y += 20;
    // ... more debug info
  }
}
```

### Console Commands

**For testing:**
```typescript
// Expose to window for console access
(window as any).debug = {
  addFuel: (amount: number) => game.ship.propulsion.fuel += amount,
  damage: (system: string, amount: number) => game.ship.damage.apply(system, amount),
  teleport: (x: number, y: number) => game.ship.position = {x, y},
  skipToNode: (nodeId: number) => game.campaign.jumpToNode(nodeId),
  unlockAll: () => game.progression.unlockAll()
};

// Usage in browser console:
// debug.addFuel(100);
// debug.damage('reactor', 50);
```

---

## Code Style & Conventions

**Naming:**
- Classes: PascalCase (`Ship`, `PropulsionSystem`)
- Functions: camelCase (`update()`, `calculateThrust()`)
- Constants: UPPER_SNAKE_CASE (`MAX_THRUST`, `FUEL_DENSITY`)
- Private members: prefix with `_` or use `private` keyword

**File Organization:**
- One class per file (usually)
- Related utilities grouped
- Exports at bottom

**Comments:**
- JSDoc for public APIs
- Inline comments for complex logic
- Explain "why", not "what"

**Type Safety:**
- Avoid `any` type
- Prefer interfaces for data structures
- Use enums for fixed sets

---

## Dependencies

**Runtime Dependencies:** NONE (vanilla TypeScript + Canvas)

**Dev Dependencies:**
```json
{
  "devDependencies": {
    "typescript": "^5.0.0",
    "vite": "^4.0.0",
    "@types/node": "^20.0.0",
    "eslint": "^8.0.0",
    "prettier": "^3.0.0"
  }
}
```

**Why minimal dependencies?**
- Faster builds
- Smaller bundle
- Less maintenance
- Full control
- Easier to understand

---

## Future Technical Considerations

### Modding Support
- JSON-based event definitions (already planned)
- Exposed API for custom ships
- Custom color palettes
- Workshop integration (Steam, itch.io)

### Multiplayer/Co-op (Far Future)
- WebRTC for peer-to-peer
- Each player controls different station
- Shared ship state
- Voice chat integration

### Mobile Port
- Touch controls (virtual buttons)
- Responsive UI scaling
- Battery optimization
- Portrait/landscape modes

### Accessibility
- Colorblind modes (already handled by palettes)
- Screen reader support (text labels)
- Rebindable keys
- Font size options
