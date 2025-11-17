/**
 * Core Renderer
 * Main canvas rendering engine with CRT effects
 */

import { ColorPalette, PALETTES, PaletteName } from '../utils/color-palettes';

export interface RendererConfig {
  canvas: HTMLCanvasElement;
  palette: PaletteName;
  enableScanlines?: boolean;
  enableGlow?: boolean;
}

export class Renderer {
  public canvas: HTMLCanvasElement;
  public ctx: CanvasRenderingContext2D;
  public width: number;
  public height: number;
  public palette: ColorPalette;
  private enableScanlines: boolean;
  private enableGlow: boolean;

  constructor(config: RendererConfig) {
    this.canvas = config.canvas;
    this.ctx = this.canvas.getContext('2d')!;
    this.palette = PALETTES[config.palette];
    this.enableScanlines = config.enableScanlines ?? true;
    this.enableGlow = config.enableGlow ?? true;

    this.width = 0;
    this.height = 0;
    this.resize();

    // Set up canvas for crisp rendering
    this.ctx.imageSmoothingEnabled = false;

    // Bind resize handler
    window.addEventListener('resize', () => this.resize());
  }

  /**
   * Resize canvas to fill window
   */
  resize(): void {
    this.width = window.innerWidth;
    this.height = window.innerHeight;
    this.canvas.width = this.width;
    this.canvas.height = this.height;
  }

  /**
   * Clear the screen
   */
  clear(): void {
    this.ctx.fillStyle = this.palette.background;
    this.ctx.fillRect(0, 0, this.width, this.height);
  }

  /**
   * Apply CRT scanline effect
   */
  applyScanlines(): void {
    if (!this.enableScanlines) return;

    this.ctx.fillStyle = 'rgba(0, 0, 0, 0.1)';
    for (let y = 0; y < this.height; y += 2) {
      this.ctx.fillRect(0, y, this.width, 1);
    }
  }

  /**
   * Apply screen glow effect
   */
  applyGlow(): void {
    if (!this.enableGlow) return;

    // Subtle vignette effect
    const gradient = this.ctx.createRadialGradient(
      this.width / 2,
      this.height / 2,
      0,
      this.width / 2,
      this.height / 2,
      Math.max(this.width, this.height) / 2
    );

    gradient.addColorStop(0, 'rgba(0, 0, 0, 0)');
    gradient.addColorStop(1, 'rgba(0, 0, 0, 0.3)');

    this.ctx.fillStyle = gradient;
    this.ctx.fillRect(0, 0, this.width, this.height);
  }

  /**
   * Change color palette
   */
  setPalette(paletteName: PaletteName): void {
    this.palette = PALETTES[paletteName];
  }

  /**
   * Toggle scanlines
   */
  toggleScanlines(): void {
    this.enableScanlines = !this.enableScanlines;
  }

  /**
   * Toggle glow
   */
  toggleGlow(): void {
    this.enableGlow = !this.enableGlow;
  }
}
