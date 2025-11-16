/**
 * ASCII Box/Border Renderer
 * Retro terminal-style boxes and panels using box-drawing characters
 */

import { ColorPalette } from '../../utils/color-palettes';

export interface BoxConfig {
  x: number;
  y: number;
  width: number;
  height: number;
  title?: string;
  style?: 'single' | 'double' | 'thick';
  titleAlign?: 'left' | 'center' | 'right';
}

// Box drawing characters
const BOX_CHARS = {
  single: {
    topLeft: '┌',
    topRight: '┐',
    bottomLeft: '└',
    bottomRight: '┘',
    horizontal: '─',
    vertical: '│',
    teeTop: '┬',
    teeBottom: '┴',
    teeLeft: '├',
    teeRight: '┤',
    cross: '┼'
  },
  double: {
    topLeft: '╔',
    topRight: '╗',
    bottomLeft: '╚',
    bottomRight: '╝',
    horizontal: '═',
    vertical: '║',
    teeTop: '╦',
    teeBottom: '╩',
    teeLeft: '╠',
    teeRight: '╣',
    cross: '╬'
  },
  thick: {
    topLeft: '█',
    topRight: '█',
    bottomLeft: '█',
    bottomRight: '█',
    horizontal: '█',
    vertical: '█',
    teeTop: '█',
    teeBottom: '█',
    teeLeft: '█',
    teeRight: '█',
    cross: '█'
  }
};

export class AsciiBox {
  private readonly charWidth: number;
  private readonly charHeight: number;

  constructor(charWidth: number = 9, charHeight: number = 16) {
    this.charWidth = charWidth;
    this.charHeight = charHeight;
  }

  /**
   * Draw a box with optional title
   */
  drawBox(
    ctx: CanvasRenderingContext2D,
    config: BoxConfig,
    palette: ColorPalette
  ): void {
    const { x, y, width, height, title, style = 'single', titleAlign = 'left' } = config;
    const chars = BOX_CHARS[style];

    ctx.fillStyle = palette.primary;
    ctx.font = '16px monospace';
    ctx.textBaseline = 'top';

    const cols = Math.floor(width / this.charWidth);
    const rows = Math.floor(height / this.charHeight);

    // Top border
    ctx.fillText(chars.topLeft, x, y);
    for (let i = 1; i < cols - 1; i++) {
      ctx.fillText(chars.horizontal, x + i * this.charWidth, y);
    }
    ctx.fillText(chars.topRight, x + (cols - 1) * this.charWidth, y);

    // Title (if provided)
    if (title) {
      const titleWithPadding = ` ${title} `;
      let titleX: number;

      switch (titleAlign) {
        case 'center':
          titleX = x + (cols * this.charWidth - titleWithPadding.length * this.charWidth) / 2;
          break;
        case 'right':
          titleX = x + (cols - titleWithPadding.length - 1) * this.charWidth;
          break;
        default: // left
          titleX = x + this.charWidth;
      }

      ctx.fillStyle = palette.accent;
      ctx.fillText(titleWithPadding, titleX, y);
      ctx.fillStyle = palette.primary;
    }

    // Side borders
    for (let i = 1; i < rows - 1; i++) {
      ctx.fillText(chars.vertical, x, y + i * this.charHeight);
      ctx.fillText(chars.vertical, x + (cols - 1) * this.charWidth, y + i * this.charHeight);
    }

    // Bottom border
    ctx.fillText(chars.bottomLeft, x, y + (rows - 1) * this.charHeight);
    for (let i = 1; i < cols - 1; i++) {
      ctx.fillText(chars.horizontal, x + i * this.charWidth, y + (rows - 1) * this.charHeight);
    }
    ctx.fillText(chars.bottomRight, x + (cols - 1) * this.charWidth, y + (rows - 1) * this.charHeight);
  }

  /**
   * Draw a horizontal divider line inside a box
   */
  drawHorizontalDivider(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    width: number,
    palette: ColorPalette,
    style: 'single' | 'double' | 'thick' = 'single'
  ): void {
    const chars = BOX_CHARS[style];
    const cols = Math.floor(width / this.charWidth);

    ctx.fillStyle = palette.primary;
    ctx.font = '16px monospace';
    ctx.textBaseline = 'top';

    ctx.fillText(chars.teeLeft, x, y);
    for (let i = 1; i < cols - 1; i++) {
      ctx.fillText(chars.horizontal, x + i * this.charWidth, y);
    }
    ctx.fillText(chars.teeRight, x + (cols - 1) * this.charWidth, y);
  }

  /**
   * Draw a vertical divider line inside a box
   */
  drawVerticalDivider(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    height: number,
    palette: ColorPalette,
    style: 'single' | 'double' | 'thick' = 'single'
  ): void {
    const chars = BOX_CHARS[style];
    const rows = Math.floor(height / this.charHeight);

    ctx.fillStyle = palette.primary;
    ctx.font = '16px monospace';
    ctx.textBaseline = 'top';

    ctx.fillText(chars.teeTop, x, y);
    for (let i = 1; i < rows - 1; i++) {
      ctx.fillText(chars.vertical, x, y + i * this.charHeight);
    }
    ctx.fillText(chars.teeBottom, x, y + (rows - 1) * this.charHeight);
  }

  /**
   * Draw a panel (filled box with background)
   */
  drawPanel(
    ctx: CanvasRenderingContext2D,
    config: BoxConfig,
    palette: ColorPalette,
    backgroundColor?: string
  ): void {
    const { x, y, width, height } = config;

    // Draw background
    if (backgroundColor) {
      ctx.fillStyle = backgroundColor;
      ctx.fillRect(x, y, width, height);
    }

    // Draw border
    this.drawBox(ctx, config, palette);
  }

  /**
   * Draw text inside a box (with word wrapping)
   */
  drawTextInBox(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    width: number,
    text: string,
    palette: ColorPalette,
    fontSize: number = 14
  ): void {
    ctx.fillStyle = palette.primary;
    ctx.font = `${fontSize}px monospace`;
    ctx.textBaseline = 'top';

    const maxCharsPerLine = Math.floor(width / (fontSize * 0.6));
    const words = text.split(' ');
    let line = '';
    let lineY = y;

    for (const word of words) {
      const testLine = line + (line ? ' ' : '') + word;

      if (testLine.length > maxCharsPerLine && line) {
        ctx.fillText(line, x, lineY);
        line = word;
        lineY += fontSize + 4;
      } else {
        line = testLine;
      }
    }

    if (line) {
      ctx.fillText(line, x, lineY);
    }
  }

  /**
   * Draw a label (text with optional background)
   */
  drawLabel(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    text: string,
    palette: ColorPalette,
    align: 'left' | 'center' | 'right' = 'left',
    highlight: boolean = false
  ): void {
    ctx.font = '14px monospace';
    ctx.textBaseline = 'top';

    const textWidth = ctx.measureText(text).width;
    let drawX = x;

    if (align === 'center') {
      drawX = x - textWidth / 2;
    } else if (align === 'right') {
      drawX = x - textWidth;
    }

    // Background highlight
    if (highlight) {
      ctx.fillStyle = palette.accent + '44';
      ctx.fillRect(drawX - 2, y - 2, textWidth + 4, 18);
    }

    ctx.fillStyle = highlight ? palette.accent : palette.primary;
    ctx.textAlign = 'left';
    ctx.fillText(text, drawX, y);
  }

  /**
   * Draw a status indicator with label
   */
  drawStatus(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    label: string,
    status: 'good' | 'warning' | 'critical' | 'offline',
    palette: ColorPalette
  ): void {
    // Status indicator
    const colors = {
      good: palette.good,
      warning: palette.warning,
      critical: palette.critical,
      offline: palette.secondary
    };

    ctx.fillStyle = colors[status];
    ctx.beginPath();
    ctx.arc(x, y + 7, 5, 0, Math.PI * 2);
    ctx.fill();

    // Label
    ctx.fillStyle = palette.primary;
    ctx.font = '14px monospace';
    ctx.textAlign = 'left';
    ctx.textBaseline = 'top';
    ctx.fillText(label, x + 12, y);
  }

  /**
   * Draw a section header
   */
  drawSectionHeader(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    width: number,
    text: string,
    palette: ColorPalette
  ): void {
    ctx.fillStyle = palette.accent;
    ctx.font = 'bold 16px monospace';
    ctx.textAlign = 'left';
    ctx.textBaseline = 'top';
    ctx.fillText(text, x, y);

    // Underline
    const textWidth = ctx.measureText(text).width;
    ctx.strokeStyle = palette.accent;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x, y + 18);
    ctx.lineTo(x + Math.min(textWidth, width), y + 18);
    ctx.stroke();
  }
}
