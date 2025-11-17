/**
 * UI Manager
 * Manages control station panels and rendering
 */

import { SpacecraftAdapter } from '../spacecraft-adapter';
import { HelmPanel } from './panels/helm-panel';
import { EngineeringPanel } from './panels/engineering-panel';
import { NavigationPanel } from './panels/navigation-panel';
import { LifeSupportPanel } from './panels/lifesupport-panel';

export type StationPanel = HelmPanel | EngineeringPanel | NavigationPanel | LifeSupportPanel;

export class UIManager {
    private canvas: HTMLCanvasElement;
    private ctx: CanvasRenderingContext2D;
    private activeStationIndex: number = 0; // Start with Helm (Station 1)
    private stations: StationPanel[];
    private spacecraft: SpacecraftAdapter;

    // Color palette (green monochrome by default)
    palette = {
        background: '#000000',
        primary: '#00ff00',
        secondary: '#00aa00',
        muted: '#006600',
        warning: '#ffff00',
        danger: '#ff0000',
        info: '#00ffff'
    };

    constructor(canvas: HTMLCanvasElement, spacecraft: SpacecraftAdapter) {
        this.canvas = canvas;
        this.spacecraft = spacecraft;
        const ctx = canvas.getContext('2d');
        if (!ctx) {
            throw new Error('Could not get 2D context');
        }
        this.ctx = ctx;

        // Initialize all station panels with spacecraft reference
        this.stations = [
            new HelmPanel(this.ctx, this.palette, spacecraft),           // Station 1
            new EngineeringPanel(this.ctx, this.palette, spacecraft),    // Station 2
            new NavigationPanel(this.ctx, this.palette, spacecraft),     // Station 3
            new LifeSupportPanel(this.ctx, this.palette, spacecraft)     // Station 4
        ];

        // Start rendering
        this.startRenderLoop();
    }

    /**
     * Set the active station
     */
    setActiveStation(stationNum: number): void {
        if (stationNum >= 1 && stationNum <= this.stations.length) {
            this.activeStationIndex = stationNum - 1; // Convert to 0-based index
            console.log(`Switched to Station ${stationNum}: ${this.stations[this.activeStationIndex].constructor.name}`);
        }
    }

    /**
     * Handle input for active station
     */
    handleInput(key: string): void {
        const activeStation = this.stations[this.activeStationIndex];
        if (activeStation && typeof activeStation.handleInput === 'function') {
            activeStation.handleInput(key);
        }
    }

    /**
     * Start the render loop
     */
    private startRenderLoop(): void {
        const render = () => {
            this.render();
            requestAnimationFrame(render);
        };
        render();
    }

    /**
     * Render the active station
     */
    private render(): void {
        // Clear canvas
        this.ctx.fillStyle = this.palette.background;
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

        // Render active station
        const activeStation = this.stations[this.activeStationIndex];
        if (activeStation) {
            activeStation.render();
        }

        // Render station indicator
        this.renderStationIndicator();
    }

    /**
     * Render station indicator in top-right corner
     */
    private renderStationIndicator(): void {
        const stationNum = this.activeStationIndex + 1;
        const stationNames = ['HELM', 'ENGINEERING', 'NAVIGATION', 'LIFE SUPPORT'];
        const stationName = stationNames[this.activeStationIndex] || 'UNKNOWN';

        this.ctx.font = '16px "Courier New"';
        this.ctx.fillStyle = this.palette.info;
        this.ctx.textAlign = 'right';
        this.ctx.fillText(`[${stationNum}/4] ${stationName}`, this.canvas.width - 20, 30);
        this.ctx.textAlign = 'left'; // Reset
    }
}
