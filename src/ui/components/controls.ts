/**
 * Control Renderers
 * Buttons, toggles, switches, and other interactive controls
 */

import { ColorPalette } from '../../utils/color-palettes';

export interface ButtonConfig {
  x: number;
  y: number;
  width: number;
  height: number;
  label: string;
  active?: boolean;
  pressed?: boolean;
  enabled?: boolean;
}

export interface ToggleConfig {
  x: number;
  y: number;
  label: string;
  state: boolean;
  enabled?: boolean;
  style?: 'switch' | 'radio' | 'checkbox';
}

export class Controls {
  /**
   * Draw a button
   */
  drawButton(
    ctx: CanvasRenderingContext2D,
    config: ButtonConfig,
    palette: ColorPalette
  ): void {
    const { x, y, width, height, label, active = false, pressed = false, enabled = true } = config;

    // Button background
    if (pressed) {
      ctx.fillStyle = palette.accent + '66';
      ctx.fillRect(x, y, width, height);
    } else if (active) {
      ctx.fillStyle = palette.accent + '33';
      ctx.fillRect(x, y, width, height);
    }

    // Button border
    ctx.strokeStyle = enabled ? palette.primary : palette.secondary;
    ctx.lineWidth = pressed ? 3 : 2;
    ctx.strokeRect(x, y, width, height);

    // Button label
    ctx.fillStyle = enabled ? (active ? palette.accent : palette.primary) : palette.secondary;
    ctx.font = '14px monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(label, x + width / 2, y + height / 2);

    // Brackets for retro look
    const bracketText = `[ ${label} ]`;
    ctx.fillText(bracketText, x + width / 2, y + height / 2);
  }

  /**
   * Draw a toggle switch
   */
  drawToggle(
    ctx: CanvasRenderingContext2D,
    config: ToggleConfig,
    palette: ColorPalette
  ): void {
    const { x, y, label, state, enabled = true, style = 'switch' } = config;

    switch (style) {
      case 'switch':
        this.drawSwitchToggle(ctx, x, y, label, state, enabled, palette);
        break;
      case 'radio':
        this.drawRadioToggle(ctx, x, y, label, state, enabled, palette);
        break;
      case 'checkbox':
        this.drawCheckboxToggle(ctx, x, y, label, state, enabled, palette);
        break;
    }
  }

  /**
   * Draw switch-style toggle (○/● ON/OFF)
   */
  private drawSwitchToggle(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    label: string,
    state: boolean,
    enabled: boolean,
    palette: ColorPalette
  ): void {
    const color = enabled ? palette.primary : palette.secondary;
    const activeColor = state ? palette.good : palette.secondary;

    // Circle
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(x, y, 8, 0, Math.PI * 2);
    ctx.stroke();

    // Fill if ON
    if (state) {
      ctx.fillStyle = activeColor;
      ctx.beginPath();
      ctx.arc(x, y, 5, 0, Math.PI * 2);
      ctx.fill();
    }

    // Label
    ctx.fillStyle = color;
    ctx.font = '14px monospace';
    ctx.textAlign = 'left';
    ctx.textBaseline = 'middle';
    ctx.fillText(label, x + 15, y);

    // State text
    ctx.fillStyle = activeColor;
    ctx.textAlign = 'right';
    const stateText = state ? 'ON' : 'OFF';
    ctx.fillText(stateText, x - 15, y);
  }

  /**
   * Draw radio-style toggle
   */
  private drawRadioToggle(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    label: string,
    state: boolean,
    enabled: boolean,
    palette: ColorPalette
  ): void {
    const color = enabled ? palette.primary : palette.secondary;

    // Outer circle
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(x, y, 8, 0, Math.PI * 2);
    ctx.stroke();

    // Inner dot if selected
    if (state) {
      ctx.fillStyle = palette.accent;
      ctx.beginPath();
      ctx.arc(x, y, 4, 0, Math.PI * 2);
      ctx.fill();
    }

    // Label
    ctx.fillStyle = color;
    ctx.font = '14px monospace';
    ctx.textAlign = 'left';
    ctx.textBaseline = 'middle';
    ctx.fillText(label, x + 15, y);
  }

  /**
   * Draw checkbox-style toggle
   */
  private drawCheckboxToggle(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    label: string,
    state: boolean,
    enabled: boolean,
    palette: ColorPalette
  ): void {
    const color = enabled ? palette.primary : palette.secondary;
    const size = 14;

    // Box
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.strokeRect(x - size / 2, y - size / 2, size, size);

    // Check mark if checked
    if (state) {
      ctx.strokeStyle = palette.accent;
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(x - 4, y);
      ctx.lineTo(x - 1, y + 4);
      ctx.lineTo(x + 5, y - 4);
      ctx.stroke();
    }

    // Label
    ctx.fillStyle = color;
    ctx.font = '14px monospace';
    ctx.textAlign = 'left';
    ctx.textBaseline = 'middle';
    ctx.fillText(label, x + 12, y);
  }

  /**
   * Draw a slider control
   */
  drawSlider(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    width: number,
    value: number,  // 0-1
    label: string,
    palette: ColorPalette,
    enabled: boolean = true
  ): void {
    const trackHeight = 4;
    const thumbSize = 12;

    // Label
    ctx.fillStyle = enabled ? palette.primary : palette.secondary;
    ctx.font = '14px monospace';
    ctx.textAlign = 'left';
    ctx.textBaseline = 'bottom';
    ctx.fillText(label, x, y - 5);

    // Track
    ctx.fillStyle = palette.secondary + '66';
    ctx.fillRect(x, y - trackHeight / 2, width, trackHeight);

    // Fill (active portion)
    const fillWidth = width * value;
    ctx.fillStyle = enabled ? palette.accent : palette.secondary;
    ctx.fillRect(x, y - trackHeight / 2, fillWidth, trackHeight);

    // Thumb
    const thumbX = x + fillWidth;
    ctx.fillStyle = enabled ? palette.accent : palette.secondary;
    ctx.fillRect(
      thumbX - thumbSize / 2,
      y - thumbSize / 2,
      thumbSize,
      thumbSize
    );

    // Value
    ctx.font = '12px monospace';
    ctx.textAlign = 'right';
    ctx.textBaseline = 'bottom';
    ctx.fillText(`${(value * 100).toFixed(0)}%`, x + width, y - 5);
  }

  /**
   * Draw a keypad button (single character/number)
   */
  drawKeypadButton(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    size: number,
    label: string,
    active: boolean,
    palette: ColorPalette
  ): void {
    // Background
    if (active) {
      ctx.fillStyle = palette.accent + '66';
      ctx.fillRect(x, y, size, size);
    }

    // Border
    ctx.strokeStyle = active ? palette.accent : palette.primary;
    ctx.lineWidth = active ? 3 : 2;
    ctx.strokeRect(x, y, size, size);

    // Label
    ctx.fillStyle = active ? palette.accent : palette.primary;
    ctx.font = 'bold 16px monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(label, x + size / 2, y + size / 2);
  }

  /**
   * Draw a rotary knob/dial
   */
  drawKnob(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    radius: number,
    value: number,  // 0-1
    label: string,
    palette: ColorPalette,
    enabled: boolean = true
  ): void {
    const startAngle = -Math.PI * 0.75;
    const endAngle = Math.PI * 0.75;
    const angle = startAngle + (endAngle - startAngle) * value;

    // Outer circle
    ctx.beginPath();
    ctx.arc(x, y, radius, 0, Math.PI * 2);
    ctx.strokeStyle = enabled ? palette.primary : palette.secondary;
    ctx.lineWidth = 2;
    ctx.stroke();

    // Active arc
    ctx.beginPath();
    ctx.arc(x, y, radius - 3, startAngle, angle);
    ctx.strokeStyle = enabled ? palette.accent : palette.secondary;
    ctx.lineWidth = 4;
    ctx.stroke();

    // Indicator line
    ctx.beginPath();
    ctx.moveTo(x, y);
    const indicatorX = x + Math.cos(angle) * (radius - 8);
    const indicatorY = y + Math.sin(angle) * (radius - 8);
    ctx.lineTo(indicatorX, indicatorY);
    ctx.strokeStyle = enabled ? palette.accent : palette.secondary;
    ctx.lineWidth = 3;
    ctx.stroke();

    // Center dot
    ctx.beginPath();
    ctx.arc(x, y, 3, 0, Math.PI * 2);
    ctx.fillStyle = enabled ? palette.primary : palette.secondary;
    ctx.fill();

    // Label
    ctx.fillStyle = enabled ? palette.primary : palette.secondary;
    ctx.font = '12px monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillText(label, x, y + radius + 5);

    // Value
    ctx.font = 'bold 14px monospace';
    ctx.textBaseline = 'middle';
    ctx.fillText(`${(value * 100).toFixed(0)}%`, x, y);
  }

  /**
   * Draw a thruster button (for RCS controls)
   */
  drawThrusterButton(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    direction: 'up' | 'down' | 'left' | 'right',
    active: boolean,
    label: string,
    palette: ColorPalette
  ): void {
    const size = 30;

    // Background
    if (active) {
      ctx.fillStyle = palette.accent + '88';
      ctx.fillRect(x, y, size, size);
    }

    // Border
    ctx.strokeStyle = active ? palette.accent : palette.primary;
    ctx.lineWidth = active ? 3 : 2;
    ctx.strokeRect(x, y, size, size);

    // Arrow
    ctx.fillStyle = active ? palette.accent : palette.primary;
    ctx.beginPath();

    const centerX = x + size / 2;
    const centerY = y + size / 2;
    const arrowSize = 8;

    switch (direction) {
      case 'up':
        ctx.moveTo(centerX, centerY - arrowSize);
        ctx.lineTo(centerX - arrowSize / 2, centerY + arrowSize / 2);
        ctx.lineTo(centerX + arrowSize / 2, centerY + arrowSize / 2);
        break;
      case 'down':
        ctx.moveTo(centerX, centerY + arrowSize);
        ctx.lineTo(centerX - arrowSize / 2, centerY - arrowSize / 2);
        ctx.lineTo(centerX + arrowSize / 2, centerY - arrowSize / 2);
        break;
      case 'left':
        ctx.moveTo(centerX - arrowSize, centerY);
        ctx.lineTo(centerX + arrowSize / 2, centerY - arrowSize / 2);
        ctx.lineTo(centerX + arrowSize / 2, centerY + arrowSize / 2);
        break;
      case 'right':
        ctx.moveTo(centerX + arrowSize, centerY);
        ctx.lineTo(centerX - arrowSize / 2, centerY - arrowSize / 2);
        ctx.lineTo(centerX - arrowSize / 2, centerY + arrowSize / 2);
        break;
    }

    ctx.closePath();
    ctx.fill();

    // Label (below button)
    ctx.font = '10px monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillText(label, centerX, y + size + 2);
  }
}
