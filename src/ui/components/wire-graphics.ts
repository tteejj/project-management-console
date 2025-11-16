/**
 * Wire Graphics Renderer
 * Animated schematic diagrams for system flows (fuel, power, coolant, etc.)
 */

import { ColorPalette } from '../../utils/color-palettes';

export interface Point {
  x: number;
  y: number;
}

export interface WireSegment {
  start: Point;
  end: Point;
  active: boolean;      // Whether flow is active
  flowRate?: number;    // 0-1, affects animation speed
}

export interface WireNode {
  position: Point;
  type: 'source' | 'sink' | 'junction' | 'component';
  label?: string;
  active?: boolean;
}

export class WireGraphics {
  private animationOffset: number = 0;
  private readonly dashLength: number = 10;
  private readonly dashGap: number = 10;

  /**
   * Update animation state (call this each frame)
   */
  update(dt: number): void {
    this.animationOffset += dt * 50; // Animation speed
    if (this.animationOffset > this.dashLength + this.dashGap) {
      this.animationOffset = 0;
    }
  }

  /**
   * Draw a wire/pipe segment
   */
  drawWire(
    ctx: CanvasRenderingContext2D,
    segment: WireSegment,
    palette: ColorPalette,
    thickness: number = 2
  ): void {
    const { start, end, active, flowRate = 1 } = segment;

    // Draw base wire
    ctx.beginPath();
    ctx.moveTo(start.x, start.y);
    ctx.lineTo(end.x, end.y);
    ctx.strokeStyle = active ? palette.primary : palette.secondary;
    ctx.lineWidth = thickness;
    ctx.stroke();

    // Draw flow animation if active
    if (active && flowRate > 0) {
      this.drawFlowAnimation(ctx, start, end, palette, flowRate, thickness);
    }
  }

  /**
   * Draw animated flow along a wire
   */
  private drawFlowAnimation(
    ctx: CanvasRenderingContext2D,
    start: Point,
    end: Point,
    palette: ColorPalette,
    flowRate: number,
    thickness: number
  ): void {
    const length = Math.sqrt(Math.pow(end.x - start.x, 2) + Math.pow(end.y - start.y, 2));
    const angle = Math.atan2(end.y - start.y, end.x - start.x);

    // Draw moving dashes
    ctx.save();
    ctx.translate(start.x, start.y);
    ctx.rotate(angle);

    ctx.strokeStyle = palette.accent;
    ctx.lineWidth = thickness + 2;
    ctx.lineCap = 'round';

    const offset = this.animationOffset * flowRate;
    const dashPattern = this.dashLength + this.dashGap;

    for (let pos = -offset; pos < length + dashPattern; pos += dashPattern) {
      const dashStart = Math.max(0, pos);
      const dashEnd = Math.min(length, pos + this.dashLength);

      if (dashStart < dashEnd) {
        ctx.beginPath();
        ctx.moveTo(dashStart, 0);
        ctx.lineTo(dashEnd, 0);
        ctx.stroke();
      }
    }

    ctx.restore();
  }

  /**
   * Draw a node (component, junction, etc.)
   */
  drawNode(
    ctx: CanvasRenderingContext2D,
    node: WireNode,
    palette: ColorPalette,
    size: number = 8
  ): void {
    const { position, type, label, active = true } = node;

    ctx.fillStyle = active ? palette.primary : palette.secondary;
    ctx.strokeStyle = active ? palette.primary : palette.secondary;

    switch (type) {
      case 'source':
        // Triangle pointing right (source of flow)
        ctx.beginPath();
        ctx.moveTo(position.x - size, position.y - size);
        ctx.lineTo(position.x + size, position.y);
        ctx.lineTo(position.x - size, position.y + size);
        ctx.closePath();
        ctx.fill();
        break;

      case 'sink':
        // Triangle pointing left (destination)
        ctx.beginPath();
        ctx.moveTo(position.x + size, position.y - size);
        ctx.lineTo(position.x - size, position.y);
        ctx.lineTo(position.x + size, position.y + size);
        ctx.closePath();
        ctx.fill();
        break;

      case 'junction':
        // Circle (junction point)
        ctx.beginPath();
        ctx.arc(position.x, position.y, size / 2, 0, Math.PI * 2);
        ctx.fill();
        break;

      case 'component':
        // Square (component like valve, pump, etc.)
        ctx.strokeRect(
          position.x - size,
          position.y - size,
          size * 2,
          size * 2
        );
        if (active) {
          ctx.fillStyle = palette.accent + '44';
          ctx.fillRect(
            position.x - size,
            position.y - size,
            size * 2,
            size * 2
          );
        }
        break;
    }

    // Draw label if provided
    if (label) {
      ctx.fillStyle = palette.primary;
      ctx.font = '10px monospace';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';
      ctx.fillText(label, position.x, position.y + size + 4);
    }
  }

  /**
   * Draw a valve symbol
   */
  drawValve(
    ctx: CanvasRenderingContext2D,
    position: Point,
    angle: number,
    open: boolean,
    palette: ColorPalette,
    size: number = 12
  ): void {
    ctx.save();
    ctx.translate(position.x, position.y);
    ctx.rotate(angle);

    // Valve body
    ctx.strokeStyle = palette.primary;
    ctx.lineWidth = 2;
    ctx.strokeRect(-size, -size, size * 2, size * 2);

    // Valve gate (vertical bar)
    ctx.beginPath();
    if (open) {
      // Open position (top)
      ctx.moveTo(0, -size);
      ctx.lineTo(0, -size / 2);
      ctx.strokeStyle = palette.good;
    } else {
      // Closed position (center, blocking flow)
      ctx.moveTo(0, -size / 2);
      ctx.lineTo(0, size / 2);
      ctx.strokeStyle = palette.critical;
    }
    ctx.lineWidth = 3;
    ctx.stroke();

    ctx.restore();
  }

  /**
   * Draw a pump symbol
   */
  drawPump(
    ctx: CanvasRenderingContext2D,
    position: Point,
    angle: number,
    active: boolean,
    palette: ColorPalette,
    size: number = 12
  ): void {
    ctx.save();
    ctx.translate(position.x, position.y);
    ctx.rotate(angle);

    // Pump body (circle)
    ctx.beginPath();
    ctx.arc(0, 0, size, 0, Math.PI * 2);
    ctx.strokeStyle = palette.primary;
    ctx.lineWidth = 2;
    ctx.stroke();

    // Impeller (rotating if active)
    const rotation = active ? this.animationOffset * 0.1 : 0;
    ctx.rotate(rotation);

    ctx.strokeStyle = active ? palette.accent : palette.secondary;
    ctx.lineWidth = 2;

    // Draw 3 impeller blades
    for (let i = 0; i < 3; i++) {
      const bladeAngle = (i * Math.PI * 2) / 3;
      const x = Math.cos(bladeAngle) * size * 0.7;
      const y = Math.sin(bladeAngle) * size * 0.7;

      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.lineTo(x, y);
      ctx.stroke();
    }

    ctx.restore();
  }

  /**
   * Draw a tank/reservoir
   */
  drawTank(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    width: number,
    height: number,
    fillLevel: number,  // 0-1
    label: string,
    palette: ColorPalette
  ): void {
    // Tank outline
    ctx.strokeStyle = palette.primary;
    ctx.lineWidth = 2;
    ctx.strokeRect(x, y, width, height);

    // Fill level
    const fillHeight = height * fillLevel;
    ctx.fillStyle = palette.accent + '66';
    ctx.fillRect(x, y + height - fillHeight, width, fillHeight);

    // Fill percentage
    ctx.fillStyle = palette.primary;
    ctx.font = 'bold 12px monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(`${(fillLevel * 100).toFixed(0)}%`, x + width / 2, y + height / 2);

    // Label
    ctx.font = '10px monospace';
    ctx.textBaseline = 'top';
    ctx.fillText(label, x + width / 2, y + height + 4);
  }

  /**
   * Draw a complete schematic diagram
   */
  drawSchematic(
    ctx: CanvasRenderingContext2D,
    segments: WireSegment[],
    nodes: WireNode[],
    palette: ColorPalette
  ): void {
    // Draw wires first (background)
    segments.forEach(segment => this.drawWire(ctx, segment, palette));

    // Draw nodes on top
    nodes.forEach(node => this.drawNode(ctx, node, palette));
  }

  /**
   * Helper: Create a path of connected points
   */
  createPath(points: Point[], active: boolean = true, flowRate: number = 1): WireSegment[] {
    const segments: WireSegment[] = [];

    for (let i = 0; i < points.length - 1; i++) {
      segments.push({
        start: points[i],
        end: points[i + 1],
        active,
        flowRate
      });
    }

    return segments;
  }

  /**
   * Helper: Create L-shaped path (horizontal then vertical, or vice versa)
   */
  createLPath(
    start: Point,
    end: Point,
    horizontalFirst: boolean,
    active: boolean = true,
    flowRate: number = 1
  ): WireSegment[] {
    const corner = horizontalFirst
      ? { x: end.x, y: start.y }
      : { x: start.x, y: end.y };

    return this.createPath([start, corner, end], active, flowRate);
  }
}
