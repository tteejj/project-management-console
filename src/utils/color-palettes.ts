/**
 * Color Palette System
 * Player-selectable monochrome themes for retro CRT aesthetic
 */

export interface ColorPalette {
  background: string;    // Usually black
  primary: string;       // Main UI color
  secondary: string;     // Secondary elements
  accent: string;        // Highlights
  good: string;          // Positive status (green zone)
  warning: string;       // Caution (yellow zone)
  critical: string;      // Danger (red zone)
}

export const PALETTES: Record<string, ColorPalette> = {
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

export type PaletteName = keyof typeof PALETTES;

export function getPalette(name: PaletteName): ColorPalette {
  return PALETTES[name];
}
