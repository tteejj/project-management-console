# Visual Design & UI Reference

## Visual Philosophy

**Retro-Futuristic Terminal Aesthetic**

Inspired by:
- 1980s CRT monitors
- Alien (1979) - MU-TH-UR computer terminals
- 2001: A Space Odyssey - HAL interface panels
- Das Boot - submarine control stations
- Early vector arcade games (Asteroids, Battlezone)

**Core Principles:**
- Monochrome vector graphics (player-selectable color)
- Fixed-width (monospace) fonts only
- ASCII-art style UI elements
- High contrast (bright on black)
- Minimal anti-aliasing (crisp lines)
- Functional over decorative
- Information density balanced with readability

---

## Color Palettes

### Green Monochrome (Classic CRT)
```
Background:  #000000 (Pure black)
Primary:     #00FF00 (Bright green)
Secondary:   #008800 (Dim green)
Accent:      #00FF88 (Cyan-green)
Good:        #00FF00 (Green)
Warning:     #AAFF00 (Yellow-green)
Critical:    #FF0000 (Red)
```

**Use Case:** Classic terminal look, high nostalgia factor

### Amber Monochrome (Old Terminals)
```
Background:  #000000
Primary:     #FFAA00 (Amber)
Secondary:   #AA6600 (Dim amber)
Accent:      #FFDD00 (Bright amber)
Good:        #88FF00 (Yellow-green)
Warning:     #FFAA00 (Amber)
Critical:    #FF0000 (Red)
```

**Use Case:** Warm aesthetic, easier on eyes

### Cyan Monochrome (Modern Terminal)
```
Background:  #000000
Primary:     #00FFFF (Cyan)
Secondary:   #0088AA (Dim cyan)
Accent:      #88FFFF (Light cyan)
Good:        #00FF00 (Green)
Warning:     #FFAA00 (Orange)
Critical:    #FF0000 (Red)
```

**Use Case:** Modern sci-fi look

### White Monochrome (High Contrast)
```
Background:  #000000
Primary:     #FFFFFF (White)
Secondary:   #888888 (Gray)
Accent:      #CCCCCC (Light gray)
Good:        #00FF00 (Green)
Warning:     #FFAA00 (Orange)
Critical:    #FF0000 (Red)
```

**Use Case:** Accessibility, highest contrast

---

## Typography

### Font Stack
```css
font-family: 'Courier New', 'Consolas', 'Monaco', monospace;
```

**All text must be monospace** - maintains grid alignment

### Font Sizes
- **Title/Headers:** 16px
- **Body/Labels:** 12px
- **Small/Details:** 10px
- **Large/Critical:** 20px

### Text Rendering
```typescript
ctx.font = '12px monospace';
ctx.fillStyle = colorPalette.primary;
ctx.textAlign = 'left';
ctx.textBaseline = 'top';
ctx.fillText('TEXT HERE', x, y);
```

---

## UI Components

### Box/Panel Border

**Style:** Single-line rectangle with title bar

```
┌─────────────────────────────────────┐
│ TITLE HERE                   [1/5] │
├─────────────────────────────────────┤
│                                     │
│  Content goes here                  │
│                                     │
└─────────────────────────────────────┘
```

**Implementation:**
```typescript
function drawBox(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, title: string) {
  // Outer border
  ctx.strokeStyle = colorPalette.primary;
  ctx.lineWidth = 1;
  ctx.strokeRect(x, y, w, h);

  // Title bar background
  ctx.fillStyle = colorPalette.background;
  ctx.fillRect(x + 1, y + 1, w - 2, 28);

  // Title bar border
  ctx.strokeRect(x, y, w, 30);

  // Title text
  ctx.fillStyle = colorPalette.primary;
  ctx.font = '16px monospace';
  ctx.fillText(title, x + 10, y + 18);
}
```

---

### Button

**Style:** Bracketed text, highlighted when active

```
Inactive: [ BUTTON ]
Active:   [■BUTTON■]
Disabled: [ ------ ]
```

**Implementation:**
```typescript
function drawButton(ctx: CanvasRenderingContext2D, x: number, y: number, label: string, active: boolean, enabled: boolean) {
  ctx.font = '12px monospace';

  if (!enabled) {
    ctx.fillStyle = colorPalette.secondary;
    ctx.fillText(`[ ${'─'.repeat(label.length)} ]`, x, y);
    return;
  }

  if (active) {
    ctx.fillStyle = colorPalette.accent;
    ctx.fillText(`[■${label}■]`, x, y);
  } else {
    ctx.fillStyle = colorPalette.primary;
    ctx.fillText(`[ ${label} ]`, x, y);
  }
}
```

---

### Toggle Switch

**Style:** Radio button style

```
Inactive: ○ OPTION
Active:   ● OPTION
```

**Implementation:**
```typescript
function drawToggle(ctx: CanvasRenderingContext2D, x: number, y: number, label: string, active: boolean) {
  ctx.font = '12px monospace';
  ctx.fillStyle = colorPalette.primary;

  const symbol = active ? '●' : '○';
  ctx.fillText(`${symbol} ${label}`, x, y);
}
```

---

### Gauge/Progress Bar

**Style:** Horizontal bar with fill

```
Label:  [████████░░] 80%
```

**Implementation:**
```typescript
function drawGauge(ctx: CanvasRenderingContext2D, x: number, y: number, label: string, value: number, max: number) {
  const barWidth = 100;
  const barHeight = 12;
  const fillWidth = (value / max) * barWidth;

  // Label
  ctx.fillStyle = colorPalette.primary;
  ctx.font = '12px monospace';
  ctx.fillText(label, x, y);

  // Bar outline
  ctx.strokeStyle = colorPalette.primary;
  ctx.strokeRect(x + 100, y, barWidth, barHeight);

  // Bar fill
  const percent = value / max;
  let fillColor = colorPalette.good;
  if (percent < 0.6) fillColor = colorPalette.warning;
  if (percent < 0.3) fillColor = colorPalette.critical;

  ctx.fillStyle = fillColor;
  ctx.fillRect(x + 100, y, fillWidth, barHeight);

  // Percentage text
  ctx.fillStyle = colorPalette.primary;
  ctx.fillText(`${Math.round(percent * 100)}%`, x + 210, y);
}
```

---

### Slider

**Style:** Line with position indicator

```
Throttle: [||||    ] 40%
          0%     100%
```

**Implementation:**
```typescript
function drawSlider(ctx: CanvasRenderingContext2D, x: number, y: number, label: string, value: number, max: number) {
  const sliderWidth = 100;
  const position = (value / max) * sliderWidth;

  // Label
  ctx.fillStyle = colorPalette.primary;
  ctx.font = '12px monospace';
  ctx.fillText(label, x, y);

  // Track
  ctx.strokeStyle = colorPalette.secondary;
  ctx.beginPath();
  ctx.moveTo(x + 100, y + 6);
  ctx.lineTo(x + 200, y + 6);
  ctx.stroke();

  // Fill
  ctx.strokeStyle = colorPalette.primary;
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.moveTo(x + 100, y + 6);
  ctx.lineTo(x + 100 + position, y + 6);
  ctx.stroke();
  ctx.lineWidth = 1;

  // Thumb
  ctx.fillStyle = colorPalette.accent;
  ctx.fillRect(x + 100 + position - 2, y + 2, 4, 8);

  // Value
  ctx.fillStyle = colorPalette.primary;
  ctx.fillText(`${Math.round(value)}%`, x + 210, y);
}
```

---

### Indicator Light

**Style:** Simple status indicator

```
● ONLINE
○ OFFLINE
⚠ WARNING
```

**Implementation:**
```typescript
enum Status {
  ONLINE,
  OFFLINE,
  WARNING,
  CRITICAL
}

function drawIndicator(ctx: CanvasRenderingContext2D, x: number, y: number, label: string, status: Status) {
  ctx.font = '12px monospace';

  let symbol = '○';
  let color = colorPalette.secondary;

  switch (status) {
    case Status.ONLINE:
      symbol = '●';
      color = colorPalette.good;
      break;
    case Status.WARNING:
      symbol = '⚠';
      color = colorPalette.warning;
      break;
    case Status.CRITICAL:
      symbol = '✕';
      color = colorPalette.critical;
      break;
  }

  ctx.fillStyle = color;
  ctx.fillText(`${symbol} ${label}`, x, y);
}
```

---

### List/Table

**Style:** Aligned columns, monospace

```
RNG     BRG     VEL     STATUS
8.2km   045°    12.5m/s CLOSING
15.7km  310°    5.2m/s  OPENING
```

**Implementation:**
```typescript
function drawTable(ctx: CanvasRenderingContext2D, x: number, y: number, headers: string[], rows: string[][]) {
  ctx.font = '12px monospace';
  ctx.fillStyle = colorPalette.primary;

  // Headers
  let xOffset = x;
  for (let header of headers) {
    ctx.fillText(header, xOffset, y);
    xOffset += 100; // column width
  }

  // Separator
  ctx.strokeStyle = colorPalette.secondary;
  ctx.beginPath();
  ctx.moveTo(x, y + 15);
  ctx.lineTo(x + headers.length * 100, y + 15);
  ctx.stroke();

  // Rows
  let yOffset = y + 30;
  for (let row of rows) {
    xOffset = x;
    for (let cell of row) {
      ctx.fillText(cell, xOffset, yOffset);
      xOffset += 100;
    }
    yOffset += 20;
  }
}
```

---

## Screen Layouts

### Main Game Screen (MVP)

**Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ [PAUSE] [STATION: HELM]         FUEL: 45%  POWER: 78%      │ ← HUD
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────┐  ┌──────────────────────┐    │
│  │ HELM CONTROL      [1/5] │  │ TACTICAL       [TAB]│    │
│  ├──────────────────────────┤  ├──────────────────────┤    │
│  │                          │  │        N             │    │
│  │  [Main Engine Controls]  │  │        ↑             │    │
│  │  [RCS Thrusters]         │  │                      │    │
│  │  [Fuel Management]       │  │    *   █   ○         │    │
│  │                          │  │        +             │    │
│  │                          │  │                      │    │
│  │                          │  │  * = Contact         │    │
│  │                          │  │  ○ = Target          │    │
│  └──────────────────────────┘  └──────────────────────┘    │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ MISSION: Dock with Station Alpha                     │  │
│  │ TIME: 04:35  DISTANCE: 2.4km  REL VEL: 8.2m/s       │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Elements:**
- **HUD (top bar):** Always visible, shows critical info
- **Main Panel (left):** Current control station
- **Tactical Display (right):** Mini nav view (always visible in MVP)
- **Mission Objective (bottom):** Current goal and status

---

### Helm Panel (Full)

See `01-CONTROL-STATIONS.md` for detailed layout

**Key Features:**
- Main engine controls (top left)
- RCS thruster grid (top right)
- Fuel status (bottom right)
- Engine gauges (bottom left)

---

### Engineering Panel (Full)

See `01-CONTROL-STATIONS.md` for detailed layout

**Key Features:**
- Reactor controls (top left)
- Power distribution grid (top right)
- Thermal management (middle right)
- Damage control (bottom left)

---

### Navigation Panel (Full)

See `01-CONTROL-STATIONS.md` for detailed layout

**Key Features:**
- Large tactical display (center left)
- Sensor controls (top right)
- Contact list (middle right)
- Velocity vectors (bottom left)
- Nav computer (bottom)

---

### Life Support Panel (Full)

See `01-CONTROL-STATIONS.md` for detailed layout

**Key Features:**
- Compartment schematic (top)
- Selected compartment details (center)
- Global systems (bottom)

---

## Animations & Visual Feedback

### Flashing Warnings

**DO:**
- Flash on state change (fire starts → flash once)
- Pulse slowly if critical (1Hz)
- Use color coding

**DON'T:**
- Constant rapid flashing (seizure risk, annoying)
- Flash multiple things at once
- Flash without reason

**Implementation:**
```typescript
class Warning {
  flashTimer = 0;
  flashDuration = 0.5; // seconds
  triggered = false;

  trigger() {
    this.flashTimer = this.flashDuration;
    this.triggered = true;
  }

  update(dt: number) {
    if (this.flashTimer > 0) {
      this.flashTimer -= dt;
    }
  }

  shouldRender(): boolean {
    return this.flashTimer > 0;
  }

  render(ctx: CanvasRenderingContext2D, x: number, y: number, message: string) {
    if (!this.shouldRender()) return;

    ctx.fillStyle = colorPalette.critical;
    ctx.font = '20px monospace';
    ctx.fillText(message, x, y);
  }
}
```

---

### Button Highlight

**Highlight when key pressed:**
```typescript
class Button {
  pressed = false;
  keyCode: string;

  update(input: InputManager) {
    this.pressed = input.isKeyDown(this.keyCode);
  }

  render(ctx: CanvasRenderingContext2D, x: number, y: number, label: string) {
    if (this.pressed) {
      // Highlight background
      ctx.fillStyle = colorPalette.accent;
      ctx.fillRect(x - 2, y - 2, label.length * 10, 16);
    }

    ctx.fillStyle = this.pressed ? colorPalette.background : colorPalette.primary;
    ctx.font = '12px monospace';
    ctx.fillText(`[ ${label} ]`, x, y);
  }
}
```

---

### Gauge Animations

**Smooth transitions:**
```typescript
class AnimatedGauge {
  currentValue = 0;
  targetValue = 0;
  speed = 50; // units per second

  setValue(value: number) {
    this.targetValue = value;
  }

  update(dt: number) {
    const diff = this.targetValue - this.currentValue;
    if (Math.abs(diff) < 0.1) {
      this.currentValue = this.targetValue;
    } else {
      this.currentValue += Math.sign(diff) * this.speed * dt;
    }
  }

  render(ctx: CanvasRenderingContext2D, x: number, y: number, max: number) {
    drawGauge(ctx, x, y, 'FUEL', this.currentValue, max);
  }
}
```

---

## Scanline Effect (Optional)

**Subtle CRT effect:**

```typescript
class ScanlineEffect {
  enabled = false;
  lineSpacing = 2; // px
  opacity = 0.1;

  render(ctx: CanvasRenderingContext2D) {
    if (!this.enabled) return;

    ctx.fillStyle = `rgba(0, 0, 0, ${this.opacity})`;
    for (let y = 0; y < ctx.canvas.height; y += this.lineSpacing) {
      ctx.fillRect(0, y, ctx.canvas.width, 1);
    }
  }
}
```

**Toggle in settings menu**

---

## Vector Graphics Rendering

### Ship

**Simple triangle (MVP):**
```typescript
function drawShip(ctx: CanvasRenderingContext2D, ship: Ship) {
  ctx.save();
  ctx.translate(ship.position.x, ship.position.y);
  ctx.rotate(ship.rotation);

  // Hull
  ctx.beginPath();
  ctx.moveTo(15, 0);      // Nose
  ctx.lineTo(-10, 10);    // Bottom left
  ctx.lineTo(-10, -10);   // Top left
  ctx.closePath();
  ctx.strokeStyle = colorPalette.primary;
  ctx.lineWidth = 2;
  ctx.stroke();

  // Center dot
  ctx.fillStyle = colorPalette.accent;
  ctx.fillRect(-2, -2, 4, 4);

  ctx.restore();
}
```

**More detailed (full version):**
- Add RCS thruster positions
- Show engine glow when thrusting
- Show damage (cracks, missing parts)

---

### Trajectory Line

**Predicted path:**
```typescript
function drawTrajectory(ctx: CanvasRenderingContext2D, ship: Ship, steps: number) {
  let pos = {...ship.position};
  let vel = {...ship.velocity};

  ctx.beginPath();
  ctx.moveTo(pos.x, pos.y);

  for (let i = 0; i < steps; i++) {
    pos.x += vel.x * 0.5;
    pos.y += vel.y * 0.5;

    ctx.lineTo(pos.x, pos.y);
  }

  ctx.strokeStyle = colorPalette.secondary;
  ctx.setLineDash([5, 5]);
  ctx.lineWidth = 1;
  ctx.stroke();
  ctx.setLineDash([]);
}
```

---

### Velocity Vector

**Arrow showing velocity:**
```typescript
function drawVelocityVector(ctx: CanvasRenderingContext2D, ship: Ship) {
  const scale = 10; // pixels per m/s
  const vx = ship.velocity.x * scale;
  const vy = ship.velocity.y * scale;

  // Line
  ctx.beginPath();
  ctx.moveTo(ship.position.x, ship.position.y);
  ctx.lineTo(ship.position.x + vx, ship.position.y + vy);
  ctx.strokeStyle = colorPalette.accent;
  ctx.lineWidth = 2;
  ctx.stroke();

  // Arrowhead
  const angle = Math.atan2(vy, vx);
  const arrowSize = 8;

  ctx.beginPath();
  ctx.moveTo(ship.position.x + vx, ship.position.y + vy);
  ctx.lineTo(
    ship.position.x + vx - arrowSize * Math.cos(angle - Math.PI/6),
    ship.position.y + vy - arrowSize * Math.sin(angle - Math.PI/6)
  );
  ctx.lineTo(
    ship.position.x + vx - arrowSize * Math.cos(angle + Math.PI/6),
    ship.position.y + vy - arrowSize * Math.sin(angle + Math.PI/6)
  );
  ctx.closePath();
  ctx.fillStyle = colorPalette.accent;
  ctx.fill();
}
```

---

### Radar Display (Tactical)

**Top-down 2D view:**
```typescript
function drawRadar(ctx: CanvasRenderingContext2D, ship: Ship, contacts: Contact[], range: number) {
  const centerX = 400;
  const centerY = 300;
  const radius = 150; // pixels

  // Outer circle
  ctx.beginPath();
  ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
  ctx.strokeStyle = colorPalette.primary;
  ctx.stroke();

  // Range rings
  ctx.strokeStyle = colorPalette.secondary;
  ctx.beginPath();
  ctx.arc(centerX, centerY, radius * 0.5, 0, Math.PI * 2);
  ctx.stroke();

  // Cardinal directions
  ctx.fillStyle = colorPalette.primary;
  ctx.font = '12px monospace';
  ctx.fillText('N', centerX - 6, centerY - radius - 10);
  ctx.fillText('S', centerX - 6, centerY + radius + 20);
  ctx.fillText('W', centerX - radius - 20, centerY + 6);
  ctx.fillText('E', centerX + radius + 10, centerY + 6);

  // Player ship (center)
  ctx.fillStyle = colorPalette.accent;
  ctx.fillRect(centerX - 3, centerY - 3, 6, 6);
  ctx.fillText('YOU', centerX + 10, centerY);

  // Contacts
  for (let contact of contacts) {
    const dx = contact.position.x - ship.position.x;
    const dy = contact.position.y - ship.position.y;
    const distance = Math.sqrt(dx*dx + dy*dy);

    if (distance > range) continue; // Out of range

    const scale = radius / range;
    const px = centerX + dx * scale;
    const py = centerY + dy * scale;

    ctx.beginPath();
    ctx.arc(px, py, 3, 0, Math.PI * 2);
    ctx.fillStyle = colorPalette.primary;
    ctx.fill();
  }
}
```

---

## Responsive Layout

**Minimum Resolution:** 1280x720 (720p)

**Target Resolution:** 1920x1080 (1080p)

**Scaling Strategy:**
- Fixed panel sizes (no scaling)
- Center UI if window larger than needed
- Prevent playing if window too small (show error message)

```typescript
function checkMinimumResolution(): boolean {
  return window.innerWidth >= 1280 && window.innerHeight >= 720;
}

if (!checkMinimumResolution()) {
  showError('Minimum resolution: 1280x720');
}
```

---

## Accessibility Considerations

### Color Blindness
- Solved by monochrome palette (no red/green confusion)
- Always use shapes/text in addition to color
- Critical info: use both color AND symbol (e.g., ⚠)

### Screen Readers
- Not primary focus (visual game)
- Could add ARIA labels to canvas regions (future)

### Font Size
- Minimum 12px (readable at 1080p)
- Option to increase font size (future)

### High Contrast
- Already high contrast by design
- White palette offers maximum contrast

---

## Asset List

**Required Assets:** NONE (all procedural)

**Optional Assets (future):**
- Font file (custom monospace)
- Sound effects (beeps, warnings)

**Everything is rendered via Canvas API - no images needed**

---

## Performance Considerations

### Rendering Optimization

**Canvas layering (if needed):**
```
Layer 1 (background): Static UI panels (rarely changes)
Layer 2 (foreground): Dynamic gauges, ship, contacts
Layer 3 (overlay): Warnings, HUD
```

**Dirty rectangles:**
```typescript
// Only redraw changed regions
ctx.clearRect(dirtyRect.x, dirtyRect.y, dirtyRect.w, dirtyRect.h);
// Redraw only affected elements
```

**Text caching:**
```typescript
// Pre-render static text to off-screen canvas
const labelCanvas = document.createElement('canvas');
// ... render text once
// Then draw pre-rendered canvas each frame (faster)
```

---

## Debug Overlay

**F12 to toggle:**

```
┌─ DEBUG ──────────────────┐
│ FPS: 60.0                │
│ Pos: (1250.3, 3421.7)    │
│ Vel: (12.5, -3.2) m/s    │
│ Fuel: 45.2 kg            │
│ Power: 2.4 kW / 3.0 kW   │
│ Heat: 350K / 700K        │
│ Systems:                 │
│  ● Propulsion   100%     │
│  ● Electrical   100%     │
│  ○ Thermal       75%     │
│                          │
│ [Add Fuel]    [Damage]   │
│ [Teleport]    [Skip]     │
└──────────────────────────┘
```

**Provides:**
- Performance metrics
- Ship state
- Cheat buttons (dev only)

---

## Style Guide Summary

**DO:**
- Use monospace fonts exclusively
- Keep contrast high (bright on black)
- Use ASCII-art style boxes/borders
- Provide clear visual feedback
- Keep layouts aligned to grid
- Use consistent spacing

**DON'T:**
- Use proportional fonts
- Use gradient fills
- Use rounded corners
- Use textures
- Mix different visual styles
- Clutter the screen

**Goal:** Clean, functional, retro-futuristic aesthetic that evokes 1980s spacecraft terminals.
