/**
 * 7-Segment LED Display Renderer
 * Classic angled-segment LED style for numerical readouts
 */

import { ColorPalette } from '../../utils/color-palettes';

export interface SevenSegmentConfig {
  digitWidth: number;
  digitHeight: number;
  segmentWidth: number;
  spacing: number;
  glowIntensity: number;  // 0-1, for LED glow effect
}

const DEFAULT_CONFIG: SevenSegmentConfig = {
  digitWidth: 30,
  digitHeight: 50,
  segmentWidth: 4,
  spacing: 8,
  glowIntensity: 0.3
};

/**
 * Segment layout:
 *     AAA
 *    F   B
 *     GGG
 *    E   C
 *     DDD
 */
const SEGMENT_MAP: Record<string, number> = {
  '0': 0b1111110,
  '1': 0b0110000,
  '2': 0b1101101,
  '3': 0b1111001,
  '4': 0b0110011,
  '5': 0b1011011,
  '6': 0b1011111,
  '7': 0b1110000,
  '8': 0b1111111,
  '9': 0b1111011,
  'A': 0b1110111,
  'B': 0b0011111,
  'C': 0b1001110,
  'D': 0b0111101,
  'E': 0b1001111,
  'F': 0b1000111,
  '-': 0b0000001,
  ' ': 0b0000000,
  '.': 0b0000000  // Handled separately
};

export class SevenSegmentDisplay {
  private config: SevenSegmentConfig;

  constructor(config: Partial<SevenSegmentConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /**
   * Draw a multi-digit number or text
   */
  drawText(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    text: string,
    palette: ColorPalette,
    _decimalPlaces: number = 0
  ): void {
    const chars = text.toUpperCase().split('');
    let currentX = x;

    for (let i = 0; i < chars.length; i++) {
      const char = chars[i];

      if (char === '.') {
        // Draw decimal point
        this.drawDecimalPoint(ctx, currentX - this.config.spacing / 2, y, palette);
      } else {
        this.drawDigit(ctx, currentX, y, char, palette);
        currentX += this.config.digitWidth + this.config.spacing;
      }
    }
  }

  /**
   * Draw a formatted number with fixed decimal places
   */
  drawNumber(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    value: number,
    palette: ColorPalette,
    digits: number = 6,
    decimalPlaces: number = 1
  ): void {
    let text = value.toFixed(decimalPlaces);

    // Pad with leading spaces if needed
    const totalLength = digits + (decimalPlaces > 0 ? 1 : 0); // +1 for decimal point
    text = text.padStart(totalLength, ' ');

    this.drawText(ctx, x, y, text, palette, decimalPlaces);
  }

  /**
   * Draw a single digit
   */
  private drawDigit(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    char: string,
    palette: ColorPalette
  ): void {
    const segments = SEGMENT_MAP[char] || 0;
    const w = this.config.digitWidth;
    const h = this.config.digitHeight;
    const sw = this.config.segmentWidth;

    // Draw glow effect first
    if (this.config.glowIntensity > 0) {
      ctx.shadowBlur = 10;
      ctx.shadowColor = palette.primary;
    }

    // Segment positions (angled LED style)
    const segmentPaths = [
      // A (top)
      () => this.drawSegmentH(ctx, x + sw, y, w - sw * 2),
      // B (top right)
      () => this.drawSegmentV(ctx, x + w - sw, y + sw, h / 2 - sw),
      // C (bottom right)
      () => this.drawSegmentV(ctx, x + w - sw, y + h / 2 + sw, h / 2 - sw),
      // D (bottom)
      () => this.drawSegmentH(ctx, x + sw, y + h - sw, w - sw * 2),
      // E (bottom left)
      () => this.drawSegmentV(ctx, x, y + h / 2 + sw, h / 2 - sw),
      // F (top left)
      () => this.drawSegmentV(ctx, x, y + sw, h / 2 - sw),
      // G (middle)
      () => this.drawSegmentH(ctx, x + sw, y + h / 2 - sw / 2, w - sw * 2)
    ];

    // Draw each segment if it's active
    for (let i = 0; i < 7; i++) {
      const isActive = (segments >> (6 - i)) & 1;

      if (isActive) {
        ctx.fillStyle = palette.primary;
        ctx.strokeStyle = palette.primary;
      } else {
        // Dim/off segments (barely visible)
        ctx.fillStyle = `${palette.primary}22`;
        ctx.strokeStyle = `${palette.primary}22`;
      }

      segmentPaths[i]();
    }

    // Reset shadow
    ctx.shadowBlur = 0;
  }

  /**
   * Draw horizontal segment (angled trapezoid)
   */
  private drawSegmentH(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    length: number
  ): void {
    const sw = this.config.segmentWidth;
    const angle = 2; // Angle offset for LED style

    ctx.beginPath();
    ctx.moveTo(x + angle, y);
    ctx.lineTo(x + length - angle, y);
    ctx.lineTo(x + length, y + sw / 2);
    ctx.lineTo(x + length - angle, y + sw);
    ctx.lineTo(x + angle, y + sw);
    ctx.lineTo(x, y + sw / 2);
    ctx.closePath();
    ctx.fill();
  }

  /**
   * Draw vertical segment (angled trapezoid)
   */
  private drawSegmentV(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    length: number
  ): void {
    const sw = this.config.segmentWidth;
    const angle = 2;

    ctx.beginPath();
    ctx.moveTo(x, y + angle);
    ctx.lineTo(x + sw / 2, y);
    ctx.lineTo(x + sw, y + angle);
    ctx.lineTo(x + sw, y + length - angle);
    ctx.lineTo(x + sw / 2, y + length);
    ctx.lineTo(x, y + length - angle);
    ctx.closePath();
    ctx.fill();
  }

  /**
   * Draw decimal point
   */
  private drawDecimalPoint(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    palette: ColorPalette
  ): void {
    const h = this.config.digitHeight;
    const sw = this.config.segmentWidth;

    ctx.fillStyle = palette.primary;
    ctx.beginPath();
    ctx.arc(x, y + h - sw, sw / 2, 0, Math.PI * 2);
    ctx.fill();
  }

  /**
   * Get total width for a text string
   */
  getTextWidth(text: string): number {
    const chars = text.replace('.', ''); // Decimal points don't add width
    return chars.length * (this.config.digitWidth + this.config.spacing) - this.config.spacing;
  }
}
