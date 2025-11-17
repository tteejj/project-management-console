/**
 * Analog Gauge Renderer
 * Speedometer/dial style gauges for retro control panels
 */

import { ColorPalette } from '../../utils/color-palettes';

export interface AnalogGaugeConfig {
  radius: number;
  startAngle: number;   // In radians
  endAngle: number;     // In radians
  minValue: number;
  maxValue: number;
  majorTicks: number;   // Number of major tick marks
  minorTicks: number;   // Minor ticks per major tick
  showValue: boolean;   // Show numerical value in center
  needleLength: number; // As fraction of radius
  label?: string;       // Gauge label
  unit?: string;        // Unit label (e.g., "m/s", "K", "%")
  dangerZone?: {        // Red zone
    start: number;      // Value where danger zone starts
    end: number;        // Value where danger zone ends
  };
  warningZone?: {       // Yellow zone
    start: number;
    end: number;
  };
}

const DEFAULT_CONFIG: Partial<AnalogGaugeConfig> = {
  radius: 50,
  startAngle: -Math.PI * 0.75,  // 225° (bottom-left)
  endAngle: Math.PI * 0.75,      // 135° (bottom-right)
  majorTicks: 10,
  minorTicks: 5,
  showValue: true,
  needleLength: 0.8
};

export class AnalogGauge {
  private config: AnalogGaugeConfig;

  constructor(config: Partial<AnalogGaugeConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config } as AnalogGaugeConfig;
  }

  /**
   * Draw the complete gauge
   */
  draw(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    value: number,
    palette: ColorPalette
  ): void {
    // Draw colored zones first (behind everything)
    if (this.config.dangerZone) {
      this.drawZone(ctx, x, y, this.config.dangerZone.start, this.config.dangerZone.end, palette.critical);
    }
    if (this.config.warningZone) {
      this.drawZone(ctx, x, y, this.config.warningZone.start, this.config.warningZone.end, palette.warning);
    }

    // Draw outer circle
    this.drawCircle(ctx, x, y, palette);

    // Draw tick marks
    this.drawTicks(ctx, x, y, palette);

    // Draw tick labels
    this.drawTickLabels(ctx, x, y, palette);

    // Draw center hub
    this.drawCenterHub(ctx, x, y, palette);

    // Draw needle
    this.drawNeedle(ctx, x, y, value, palette);

    // Draw label
    if (this.config.label) {
      this.drawLabel(ctx, x, y, palette);
    }

    // Draw value
    if (this.config.showValue) {
      this.drawValue(ctx, x, y, value, palette);
    }
  }

  /**
   * Draw outer circle and arc
   */
  private drawCircle(ctx: CanvasRenderingContext2D, x: number, y: number, palette: ColorPalette): void {
    const r = this.config.radius;

    // Outer circle
    ctx.beginPath();
    ctx.arc(x, y, r, 0, Math.PI * 2);
    ctx.strokeStyle = palette.primary;
    ctx.lineWidth = 2;
    ctx.stroke();

    // Arc showing active range
    ctx.beginPath();
    ctx.arc(x, y, r - 5, this.config.startAngle, this.config.endAngle);
    ctx.strokeStyle = palette.secondary;
    ctx.lineWidth = 1;
    ctx.stroke();
  }

  /**
   * Draw colored zones (warning/danger)
   */
  private drawZone(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    startValue: number,
    endValue: number,
    color: string
  ): void {
    const r = this.config.radius - 5;
    const startAngle = this.valueToAngle(startValue);
    const endAngle = this.valueToAngle(endValue);

    ctx.beginPath();
    ctx.arc(x, y, r, startAngle, endAngle);
    ctx.strokeStyle = color + '66'; // Semi-transparent
    ctx.lineWidth = 8;
    ctx.stroke();
  }

  /**
   * Draw tick marks
   */
  private drawTicks(ctx: CanvasRenderingContext2D, x: number, y: number, palette: ColorPalette): void {
    const r = this.config.radius;
    const range = this.config.maxValue - this.config.minValue;

    // Major ticks
    for (let i = 0; i <= this.config.majorTicks; i++) {
      const value = this.config.minValue + (range * i / this.config.majorTicks);
      const angle = this.valueToAngle(value);

      const x1 = x + Math.cos(angle) * (r - 10);
      const y1 = y + Math.sin(angle) * (r - 10);
      const x2 = x + Math.cos(angle) * (r - 3);
      const y2 = y + Math.sin(angle) * (r - 3);

      ctx.beginPath();
      ctx.moveTo(x1, y1);
      ctx.lineTo(x2, y2);
      ctx.strokeStyle = palette.primary;
      ctx.lineWidth = 2;
      ctx.stroke();
    }

    // Minor ticks
    const totalMinorTicks = this.config.majorTicks * this.config.minorTicks;
    for (let i = 0; i <= totalMinorTicks; i++) {
      // Skip positions where major ticks are
      if (i % this.config.minorTicks === 0) continue;

      const value = this.config.minValue + (range * i / totalMinorTicks);
      const angle = this.valueToAngle(value);

      const x1 = x + Math.cos(angle) * (r - 7);
      const y1 = y + Math.sin(angle) * (r - 7);
      const x2 = x + Math.cos(angle) * (r - 3);
      const y2 = y + Math.sin(angle) * (r - 3);

      ctx.beginPath();
      ctx.moveTo(x1, y1);
      ctx.lineTo(x2, y2);
      ctx.strokeStyle = palette.secondary;
      ctx.lineWidth = 1;
      ctx.stroke();
    }
  }

  /**
   * Draw tick labels (numbers)
   */
  private drawTickLabels(ctx: CanvasRenderingContext2D, x: number, y: number, palette: ColorPalette): void {
    const r = this.config.radius - 15;
    const range = this.config.maxValue - this.config.minValue;

    ctx.fillStyle = palette.primary;
    ctx.font = '10px monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    for (let i = 0; i <= this.config.majorTicks; i++) {
      const value = this.config.minValue + (range * i / this.config.majorTicks);
      const angle = this.valueToAngle(value);

      const labelX = x + Math.cos(angle) * r;
      const labelY = y + Math.sin(angle) * r;

      // Format label
      let label = value.toString();
      if (Math.abs(value) >= 1000) {
        label = (value / 1000).toFixed(1) + 'k';
      } else if (Math.abs(value) < 1 && value !== 0) {
        label = value.toFixed(1);
      }

      ctx.fillText(label, labelX, labelY);
    }
  }

  /**
   * Draw center hub
   */
  private drawCenterHub(ctx: CanvasRenderingContext2D, x: number, y: number, palette: ColorPalette): void {
    ctx.beginPath();
    ctx.arc(x, y, 4, 0, Math.PI * 2);
    ctx.fillStyle = palette.primary;
    ctx.fill();
  }

  /**
   * Draw needle
   */
  private drawNeedle(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    value: number,
    palette: ColorPalette
  ): void {
    // Clamp value
    const clampedValue = Math.max(this.config.minValue, Math.min(this.config.maxValue, value));
    const angle = this.valueToAngle(clampedValue);
    const needleLength = this.config.radius * this.config.needleLength;

    // Needle tip
    const tipX = x + Math.cos(angle) * needleLength;
    const tipY = y + Math.sin(angle) * needleLength;

    // Needle base (triangle)
    const baseWidth = 6;
    const baseAngle1 = angle + Math.PI / 2;
    const baseAngle2 = angle - Math.PI / 2;
    const base1X = x + Math.cos(baseAngle1) * baseWidth / 2;
    const base1Y = y + Math.sin(baseAngle1) * baseWidth / 2;
    const base2X = x + Math.cos(baseAngle2) * baseWidth / 2;
    const base2Y = y + Math.sin(baseAngle2) * baseWidth / 2;

    // Draw needle
    ctx.beginPath();
    ctx.moveTo(tipX, tipY);
    ctx.lineTo(base1X, base1Y);
    ctx.lineTo(base2X, base2Y);
    ctx.closePath();

    // Color based on zones
    let needleColor = palette.accent;
    if (this.config.dangerZone && value >= this.config.dangerZone.start && value <= this.config.dangerZone.end) {
      needleColor = palette.critical;
    } else if (this.config.warningZone && value >= this.config.warningZone.start && value <= this.config.warningZone.end) {
      needleColor = palette.warning;
    }

    ctx.fillStyle = needleColor;
    ctx.fill();
    ctx.strokeStyle = needleColor;
    ctx.lineWidth = 2;
    ctx.stroke();
  }

  /**
   * Draw label
   */
  private drawLabel(ctx: CanvasRenderingContext2D, x: number, y: number, palette: ColorPalette): void {
    ctx.fillStyle = palette.secondary;
    ctx.font = '12px monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(this.config.label!, x, y - this.config.radius / 3);
  }

  /**
   * Draw current value in center
   */
  private drawValue(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    value: number,
    palette: ColorPalette
  ): void {
    ctx.fillStyle = palette.primary;
    ctx.font = 'bold 14px monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    const valueText = value.toFixed(1);
    const unit = this.config.unit || '';
    ctx.fillText(valueText, x, y + this.config.radius / 2.5);

    if (unit) {
      ctx.font = '10px monospace';
      ctx.fillText(unit, x, y + this.config.radius / 2.5 + 12);
    }
  }

  /**
   * Convert value to angle
   */
  private valueToAngle(value: number): number {
    const range = this.config.maxValue - this.config.minValue;
    const valueRange = this.config.endAngle - this.config.startAngle;
    const normalized = (value - this.config.minValue) / range;
    return this.config.startAngle + normalized * valueRange;
  }
}
