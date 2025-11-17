/**
 * Input Manager
 * Handles keyboard and mouse input
 */

export class InputManager {
    private keysPressed: Set<string> = new Set();

    // Callbacks
    onStationSwitch: ((station: number) => void) | null = null;
    onKeyPress: ((key: string) => void) | null = null;

    constructor() {
        this.setupListeners();
    }

    private setupListeners(): void {
        window.addEventListener('keydown', this.onKeyDown);
        window.addEventListener('keyup', this.onKeyUp);
    }

    private onKeyDown = (e: KeyboardEvent): void => {
        const key = e.key;
        this.keysPressed.add(key);

        // Station switching (1-5 keys)
        if (key >= '1' && key <= '5') {
            const stationNum = parseInt(key);
            if (this.onStationSwitch) {
                this.onStationSwitch(stationNum);
            }
            e.preventDefault();
            return;
        }

        // TAB for cycling stations
        if (key === 'Tab') {
            // Will cycle through stations
            e.preventDefault();
            return;
        }

        // Pass other keys to active station
        if (this.onKeyPress) {
            this.onKeyPress(key);
        }
    };

    private onKeyUp = (e: KeyboardEvent): void {
        this.keysPressed.delete(e.key);
    };

    isKeyPressed(key: string): boolean {
        return this.keysPressed.has(key);
    }

    destroy(): void {
        window.removeEventListener('keydown', this.onKeyDown);
        window.removeEventListener('keyup', this.onKeyUp);
    }
}
