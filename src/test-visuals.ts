/**
 * Visual Component Test Screen
 * Showcases all UI components for visual feedback
 */

import { Game } from './core/game';
import { Renderer } from './core/renderer';
import { InputManager } from './core/input';
import { SevenSegmentDisplay } from './ui/components/seven-segment-display';
import { AnalogGauge } from './ui/components/analog-gauge';
import { WireGraphics, WireSegment, WireNode, Point } from './ui/components/wire-graphics';
import { AsciiBox } from './ui/components/ascii-box';
import { Controls } from './ui/components/controls';
import { PaletteName } from './utils/color-palettes';

class VisualTest extends Game {
  private input: InputManager;
  private sevenSegment: SevenSegmentDisplay;
  private wireGraphics: WireGraphics;
  private asciiBox: AsciiBox;
  private controls: Controls;

  // Test data
  private testValue: number = 123.4;
  private testGaugeValue: number = 65;
  private testSliderValue: number = 0.7;
  private testToggleState: boolean = true;
  private testButtonPressed: boolean = false;
  private testFuelLevel: number = 0.75;
  private testValveOpen: boolean = true;
  private testPumpActive: boolean = true;
  private currentPalette: number = 0;
  private paletteNames: PaletteName[] = ['green', 'amber', 'cyan', 'white'];

  // Animation
  private animTime: number = 0;

  constructor(renderer: Renderer) {
    super(renderer);
    this.input = new InputManager();
    this.sevenSegment = new SevenSegmentDisplay({
      digitWidth: 30,
      digitHeight: 50,
      segmentWidth: 4,
      spacing: 8,
      glowIntensity: 0.3
    });
    this.wireGraphics = new WireGraphics();
    this.asciiBox = new AsciiBox();
    this.controls = new Controls();
  }

  protected update(dt: number): void {
    this.input.update();

    // Cycle palettes with P key
    if (this.input.isKeyJustPressed('p')) {
      this.currentPalette = (this.currentPalette + 1) % this.paletteNames.length;
      this.getRenderer().setPalette(this.paletteNames[this.currentPalette]);
    }

    // Toggle scanlines with S key
    if (this.input.isKeyJustPressed('s')) {
      this.getRenderer().toggleScanlines();
    }

    // Toggle glow with G key
    if (this.input.isKeyJustPressed('g')) {
      this.getRenderer().toggleGlow();
    }

    // Animate test values
    this.animTime += dt;
    this.testGaugeValue = 50 + Math.sin(this.animTime) * 40;
    this.testValue = 100 + Math.sin(this.animTime * 0.5) * 50;
    this.testFuelLevel = 0.5 + Math.sin(this.animTime * 0.3) * 0.4;

    // Update wire graphics animation
    this.wireGraphics.update(dt);

    // Toggle test button
    if (this.input.isKeyPressed(' ')) {
      this.testButtonPressed = true;
    } else {
      this.testButtonPressed = false;
    }

    // Toggle test switch
    if (this.input.isKeyJustPressed('t')) {
      this.testToggleState = !this.testToggleState;
    }

    // Toggle valve
    if (this.input.isKeyJustPressed('v')) {
      this.testValveOpen = !this.testValveOpen;
    }

    // Toggle pump
    if (this.input.isKeyJustPressed('u')) {
      this.testPumpActive = !this.testPumpActive;
    }
  }

  protected render(): void {
    const renderer = this.getRenderer();
    const ctx = renderer.ctx;
    const palette = renderer.palette;

    renderer.clear();

    // Title
    ctx.fillStyle = palette.accent;
    ctx.font = 'bold 24px monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillText('VECTOR MOON LANDER - VISUAL COMPONENT TEST', renderer.width / 2, 20);

    // Instructions
    ctx.fillStyle = palette.secondary;
    ctx.font = '12px monospace';
    ctx.fillText(
      'P: Change Palette | S: Toggle Scanlines | G: Toggle Glow | SPACE: Press Button | T: Toggle | V: Valve | U: Pump',
      renderer.width / 2,
      50
    );

    // Current palette
    ctx.fillStyle = palette.primary;
    ctx.fillText(
      `Current Palette: ${this.paletteNames[this.currentPalette].toUpperCase()}`,
      renderer.width / 2,
      70
    );

    const startY = 100;
    const col1X = 50;
    const col2X = 450;
    const col3X = 850;

    // === COLUMN 1: Digital Displays ===
    this.asciiBox.drawSectionHeader(ctx, col1X, startY, 400, '7-SEGMENT DISPLAYS', palette);

    // Large display
    this.sevenSegment.drawNumber(ctx, col1X, startY + 40, this.testValue, palette, 6, 1);

    // Medium display
    const mediumDisplay = new SevenSegmentDisplay({
      digitWidth: 20,
      digitHeight: 35,
      segmentWidth: 3,
      spacing: 5,
      glowIntensity: 0.2
    });
    mediumDisplay.drawNumber(ctx, col1X, startY + 110, 456.78, palette, 6, 2);

    // Small display
    const smallDisplay = new SevenSegmentDisplay({
      digitWidth: 15,
      digitHeight: 25,
      segmentWidth: 2,
      spacing: 4,
      glowIntensity: 0.1
    });
    smallDisplay.drawText(ctx, col1X, startY + 170, '88888', palette);

    // Hex display
    smallDisplay.drawText(ctx, col1X, startY + 210, 'ABCDEF', palette);

    // === COLUMN 1: Gauges ===
    this.asciiBox.drawSectionHeader(ctx, col1X, startY + 260, 400, 'ANALOG GAUGES', palette);

    // Temperature gauge
    const tempGauge = new AnalogGauge({
      radius: 60,
      minValue: 0,
      maxValue: 1000,
      label: 'TEMP',
      unit: 'K',
      dangerZone: { start: 800, end: 1000 },
      warningZone: { start: 600, end: 800 }
    });
    tempGauge.draw(ctx, col1X + 70, startY + 340, this.testGaugeValue * 10, palette);

    // Pressure gauge
    const pressureGauge = new AnalogGauge({
      radius: 50,
      minValue: 0,
      maxValue: 5,
      label: 'PRESSURE',
      unit: 'bar',
      majorTicks: 5,
      warningZone: { start: 0, end: 1 },
      dangerZone: { start: 4, end: 5 }
    });
    pressureGauge.draw(ctx, col1X + 230, startY + 340, 2.5 + Math.sin(this.animTime * 2), palette);

    // === COLUMN 2: Controls ===
    this.asciiBox.drawSectionHeader(ctx, col2X, startY, 400, 'CONTROLS & BUTTONS', palette);

    // Button
    this.controls.drawButton(
      ctx,
      { x: col2X, y: startY + 30, width: 120, height: 40, label: 'FIRE', pressed: this.testButtonPressed },
      palette
    );

    this.controls.drawButton(
      ctx,
      { x: col2X + 130, y: startY + 30, width: 120, height: 40, label: 'ARM', active: true },
      palette
    );

    // Toggle switches
    this.controls.drawToggle(
      ctx,
      { x: col2X + 20, y: startY + 90, label: 'MAIN ENGINE', state: this.testToggleState, style: 'switch' },
      palette
    );

    this.controls.drawToggle(
      ctx,
      { x: col2X + 20, y: startY + 120, label: 'RCS SYSTEM', state: false, style: 'switch' },
      palette
    );

    this.controls.drawToggle(
      ctx,
      { x: col2X + 20, y: startY + 150, label: 'AUTOPILOT', state: true, style: 'radio' },
      palette
    );

    this.controls.drawToggle(
      ctx,
      { x: col2X + 20, y: startY + 180, label: 'NAV COMPUTER', state: this.testToggleState, style: 'checkbox' },
      palette
    );

    // Slider
    this.controls.drawSlider(ctx, col2X, startY + 220, 200, this.testSliderValue, 'THROTTLE', palette);

    // Knob
    this.controls.drawKnob(ctx, col2X + 280, startY + 240, 40, this.testSliderValue, 'GIMBAL', palette);

    // Keypad
    const keypadStartX = col2X;
    const keypadStartY = startY + 300;
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (let i = 0; i < 9; i++) {
      const row = Math.floor(i / 3);
      const col = i % 3;
      const active = this.input.isKeyPressed(keys[i]);
      this.controls.drawKeypadButton(
        ctx,
        keypadStartX + col * 40,
        keypadStartY + row * 40,
        35,
        keys[i],
        active,
        palette
      );
    }

    // Thruster buttons
    this.controls.drawThrusterButton(ctx, col2X + 180, startY + 310, 'up', this.input.isKeyPressed('w'), 'BOW', palette);
    this.controls.drawThrusterButton(ctx, col2X + 180, startY + 380, 'down', this.input.isKeyPressed('s'), 'STERN', palette);
    this.controls.drawThrusterButton(ctx, col2X + 145, startY + 345, 'left', this.input.isKeyPressed('a'), 'PORT', palette);
    this.controls.drawThrusterButton(ctx, col2X + 215, startY + 345, 'right', this.input.isKeyPressed('d'), 'STBD', palette);

    // === COLUMN 3: Wire Graphics & Schematics ===
    this.asciiBox.drawSectionHeader(ctx, col3X, startY, 400, 'WIRE GRAPHICS & SCHEMATICS', palette);

    // Fuel system schematic
    const fuelStartX = col3X;
    const fuelStartY = startY + 40;

    // Tank
    this.wireGraphics.drawTank(ctx, fuelStartX, fuelStartY, 60, 80, this.testFuelLevel, 'TANK 1', palette);

    // Valve
    const valvePos: Point = { x: fuelStartX + 100, y: fuelStartY + 40 };
    this.wireGraphics.drawValve(ctx, valvePos, 0, this.testValveOpen, palette);

    // Pump
    const pumpPos: Point = { x: fuelStartX + 160, y: fuelStartY + 40 };
    this.wireGraphics.drawPump(ctx, pumpPos, 0, this.testPumpActive, palette);

    // Engine
    const enginePos: Point = { x: fuelStartX + 220, y: fuelStartY + 40 };
    this.wireGraphics.drawNode(
      ctx,
      { position: enginePos, type: 'component', label: 'ENGINE', active: this.testPumpActive },
      palette,
      12
    );

    // Pipes connecting them
    const pipes: WireSegment[] = [
      {
        start: { x: fuelStartX + 60, y: fuelStartY + 40 },
        end: { x: valvePos.x - 12, y: fuelStartY + 40 },
        active: true,
        flowRate: this.testFuelLevel
      },
      {
        start: { x: valvePos.x + 12, y: fuelStartY + 40 },
        end: { x: pumpPos.x - 12, y: fuelStartY + 40 },
        active: this.testValveOpen,
        flowRate: this.testValveOpen ? this.testFuelLevel : 0
      },
      {
        start: { x: pumpPos.x + 12, y: fuelStartY + 40 },
        end: { x: enginePos.x - 12, y: fuelStartY + 40 },
        active: this.testPumpActive && this.testValveOpen,
        flowRate: this.testPumpActive && this.testValveOpen ? 1 : 0
      }
    ];

    pipes.forEach(pipe => this.wireGraphics.drawWire(ctx, pipe, palette, 3));

    // Complex schematic with junctions
    const schematicY = startY + 160;

    const powerSegments = this.wireGraphics.createPath(
      [
        { x: col3X, y: schematicY },
        { x: col3X + 80, y: schematicY },
        { x: col3X + 80, y: schematicY + 40 },
        { x: col3X + 160, y: schematicY + 40 }
      ],
      true,
      0.8
    );

    const branch1 = this.wireGraphics.createLPath(
      { x: col3X + 80, y: schematicY },
      { x: col3X + 160, y: schematicY - 30 },
      true,
      true,
      0.5
    );

    const branch2 = this.wireGraphics.createLPath(
      { x: col3X + 80, y: schematicY + 40 },
      { x: col3X + 160, y: schematicY + 80 },
      true,
      true,
      0.6
    );

    const allSegments = [...powerSegments, ...branch1, ...branch2];
    allSegments.forEach(seg => this.wireGraphics.drawWire(ctx, seg, palette, 2));

    // Nodes
    const nodes: WireNode[] = [
      { position: { x: col3X, y: schematicY }, type: 'source', label: 'REACTOR', active: true },
      { position: { x: col3X + 80, y: schematicY }, type: 'junction', active: true },
      { position: { x: col3X + 80, y: schematicY + 40 }, type: 'junction', active: true },
      { position: { x: col3X + 160, y: schematicY - 30 }, type: 'sink', label: 'BUS A', active: true },
      { position: { x: col3X + 160, y: schematicY + 40 }, type: 'sink', label: 'BUS B', active: true },
      { position: { x: col3X + 160, y: schematicY + 80 }, type: 'sink', label: 'BACKUP', active: true }
    ];

    nodes.forEach(node => this.wireGraphics.drawNode(ctx, node, palette));

    // === ASCII Boxes ===
    this.asciiBox.drawSectionHeader(ctx, col3X, schematicY + 130, 400, 'ASCII BOXES & PANELS', palette);

    // Single border box
    this.asciiBox.drawBox(
      ctx,
      { x: col3X, y: schematicY + 160, width: 200, height: 80, title: 'SINGLE', style: 'single' },
      palette
    );

    // Double border box
    this.asciiBox.drawBox(
      ctx,
      { x: col3X, y: schematicY + 250, width: 200, height: 80, title: 'DOUBLE', style: 'double' },
      palette
    );

    // Status indicators
    this.asciiBox.drawStatus(ctx, col3X + 220, schematicY + 170, 'SYSTEMS ONLINE', 'good', palette);
    this.asciiBox.drawStatus(ctx, col3X + 220, schematicY + 200, 'TEMPERATURE HIGH', 'warning', palette);
    this.asciiBox.drawStatus(ctx, col3X + 220, schematicY + 230, 'HULL BREACH', 'critical', palette);
    this.asciiBox.drawStatus(ctx, col3X + 220, schematicY + 260, 'RADAR OFFLINE', 'offline', palette);

    // Apply CRT effects
    renderer.applyScanlines();
    renderer.applyGlow();

    // FPS counter
    ctx.fillStyle = palette.secondary;
    ctx.font = '12px monospace';
    ctx.textAlign = 'right';
    ctx.textBaseline = 'top';
    ctx.fillText(`FPS: ${this.getFPS()}`, renderer.width - 10, 10);
  }
}

// Initialize and start
window.addEventListener('DOMContentLoaded', () => {
  const canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
  const renderer = new Renderer({
    canvas,
    palette: 'green',
    enableScanlines: true,
    enableGlow: true
  });

  const game = new VisualTest(renderer);
  game.start();
});
