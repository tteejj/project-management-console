/**
 * Input Manager
 * Handles keyboard and mouse input
 */

export class InputManager {
  private keysPressed: Set<string> = new Set();
  private keysJustPressed: Set<string> = new Set();
  private keysJustReleased: Set<string> = new Set();
  private mouseX: number = 0;
  private mouseY: number = 0;
  private mouseButtons: Set<number> = new Set();

  constructor() {
    // Keyboard events
    window.addEventListener('keydown', (e) => this.handleKeyDown(e));
    window.addEventListener('keyup', (e) => this.handleKeyUp(e));

    // Mouse events
    window.addEventListener('mousemove', (e) => this.handleMouseMove(e));
    window.addEventListener('mousedown', (e) => this.handleMouseDown(e));
    window.addEventListener('mouseup', (e) => this.handleMouseUp(e));
  }

  /**
   * Update input state (call this each frame)
   */
  update(): void {
    this.keysJustPressed.clear();
    this.keysJustReleased.clear();
  }

  /**
   * Check if a key is currently pressed
   */
  isKeyPressed(key: string): boolean {
    return this.keysPressed.has(key.toLowerCase());
  }

  /**
   * Check if a key was just pressed this frame
   */
  isKeyJustPressed(key: string): boolean {
    return this.keysJustPressed.has(key.toLowerCase());
  }

  /**
   * Check if a key was just released this frame
   */
  isKeyJustReleased(key: string): boolean {
    return this.keysJustReleased.has(key.toLowerCase());
  }

  /**
   * Get mouse position
   */
  getMousePosition(): { x: number; y: number } {
    return { x: this.mouseX, y: this.mouseY };
  }

  /**
   * Check if a mouse button is pressed
   */
  isMouseButtonPressed(button: number): boolean {
    return this.mouseButtons.has(button);
  }

  /**
   * Handle key down event
   */
  private handleKeyDown(e: KeyboardEvent): void {
    const key = e.key.toLowerCase();

    if (!this.keysPressed.has(key)) {
      this.keysJustPressed.add(key);
    }

    this.keysPressed.add(key);
  }

  /**
   * Handle key up event
   */
  private handleKeyUp(e: KeyboardEvent): void {
    const key = e.key.toLowerCase();

    this.keysPressed.delete(key);
    this.keysJustReleased.add(key);
  }

  /**
   * Handle mouse move event
   */
  private handleMouseMove(e: MouseEvent): void {
    this.mouseX = e.clientX;
    this.mouseY = e.clientY;
  }

  /**
   * Handle mouse down event
   */
  private handleMouseDown(e: MouseEvent): void {
    this.mouseButtons.add(e.button);
  }

  /**
   * Handle mouse up event
   */
  private handleMouseUp(e: MouseEvent): void {
    this.mouseButtons.delete(e.button);
  }
}
