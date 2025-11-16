/**
 * Main Game Class
 * Handles game loop, state management, and orchestration
 */

import { Renderer } from './renderer';

export enum GameState {
  LOADING,
  MAIN_MENU,
  PLAYING,
  PAUSED,
  GAME_OVER
}

export class Game {
  private renderer: Renderer;
  protected currentState: GameState;
  private lastTime: number = 0;
  private accumulator: number = 0;
  private readonly FIXED_DT: number = 1 / 60; // 60 FPS physics
  private running: boolean = false;
  private isPaused: boolean = false;
  private fps: number = 60;
  private frameCount: number = 0;
  private lastFpsUpdate: number = 0;

  constructor(renderer: Renderer) {
    this.renderer = renderer;
    this.currentState = GameState.LOADING;
  }

  /**
   * Start the game loop
   */
  start(): void {
    this.running = true;
    this.lastTime = performance.now();
    this.gameLoop(this.lastTime);
  }

  /**
   * Stop the game loop
   */
  stop(): void {
    this.running = false;
  }

  /**
   * Main game loop
   */
  private gameLoop(currentTime: number): void {
    if (!this.running) return;

    const frameTime = (currentTime - this.lastTime) / 1000; // Convert to seconds
    this.lastTime = currentTime;

    // Calculate FPS
    this.frameCount++;
    if (currentTime - this.lastFpsUpdate >= 1000) {
      this.fps = this.frameCount;
      this.frameCount = 0;
      this.lastFpsUpdate = currentTime;
    }

    // Fixed timestep updates
    this.accumulator += frameTime;
    while (this.accumulator >= this.FIXED_DT) {
      if (!this.isPaused) {
        this.update(this.FIXED_DT);
      }
      this.accumulator -= this.FIXED_DT;
    }

    // Render (can be at variable framerate)
    this.render();

    // Schedule next frame
    requestAnimationFrame((t) => this.gameLoop(t));
  }

  /**
   * Update game state (fixed timestep)
   */
  protected update(_dt: number): void {
    // Override in subclasses or extend
  }

  /**
   * Render the current frame
   */
  protected render(): void {
    this.renderer.clear();
    // Override in subclasses or extend
    this.renderer.applyScanlines();
    this.renderer.applyGlow();
  }

  /**
   * Pause the game
   */
  pause(): void {
    this.isPaused = true;
  }

  /**
   * Resume the game
   */
  resume(): void {
    this.isPaused = false;
  }

  /**
   * Toggle pause
   */
  togglePause(): void {
    this.isPaused = !this.isPaused;
  }

  /**
   * Change game state
   */
  setState(newState: GameState): void {
    this.currentState = newState;
  }

  /**
   * Get current FPS
   */
  getFPS(): number {
    return this.fps;
  }

  /**
   * Get renderer
   */
  getRenderer(): Renderer {
    return this.renderer;
  }
}
