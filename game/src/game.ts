/**
 * Main Game Class
 * Orchestrates game loop, physics simulation, and rendering
 */

import { SpacecraftAdapter } from './spacecraft-adapter';

export class Game {
    private canvas: HTMLCanvasElement;
    private ctx: CanvasRenderingContext2D;
    private running: boolean = false;
    private lastFrameTime: number = 0;
    private fps: number = 60;
    private fixedTimestep: number = 1 / 60; // 60 FPS

    // Game state
    private paused: boolean = false;

    // Spacecraft simulation
    public spacecraft: SpacecraftAdapter;

    constructor(canvas: HTMLCanvasElement) {
        this.canvas = canvas;
        const ctx = canvas.getContext('2d');
        if (!ctx) {
            throw new Error('Could not get 2D context from canvas');
        }
        this.ctx = ctx;

        // Set up canvas for crisp rendering
        this.ctx.imageSmoothingEnabled = false;

        // Initialize spacecraft
        this.spacecraft = new SpacecraftAdapter();
        console.log('Spacecraft initialized');
    }

    /**
     * Start the game loop
     */
    start(): void {
        this.running = true;
        this.lastFrameTime = performance.now();
        this.gameLoop();
    }

    /**
     * Stop the game loop
     */
    stop(): void {
        this.running = false;
    }

    /**
     * Toggle pause
     */
    togglePause(): void {
        this.paused = !this.paused;
    }

    /**
     * Main game loop using requestAnimationFrame
     */
    private gameLoop = (): void => {
        if (!this.running) return;

        const currentTime = performance.now();
        const deltaTime = (currentTime - this.lastFrameTime) / 1000; // Convert to seconds
        this.lastFrameTime = currentTime;

        if (!this.paused) {
            // Update game state
            this.update(deltaTime);
        }

        // Render always (even when paused, to show pause screen)
        this.render();

        // Request next frame
        requestAnimationFrame(this.gameLoop);
    };

    /**
     * Update game state
     */
    private update(deltaTime: number): void {
        // Update spacecraft physics simulation
        // Use fixed timestep for stability
        const dt = Math.min(deltaTime, this.fixedTimestep * 2); // Clamp to prevent spiral of death
        this.spacecraft.update(dt);
    }

    /**
     * Render the current frame
     */
    private render(): void {
        // Clear canvas
        this.ctx.fillStyle = '#000000';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

        // Render will be handled by UIManager
        // This is just the base game rendering
    }
}
