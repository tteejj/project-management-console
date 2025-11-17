/**
 * HELM / PROPULSION Station
 * Main engine, RCS thrusters, fuel management
 * Based on design: 01-CONTROL-STATIONS.md
 */

import { SpacecraftAdapter } from '../../spacecraft-adapter';

export class HelmPanel {
    private ctx: CanvasRenderingContext2D;
    private palette: any;
    private spacecraft: SpacecraftAdapter;

    // Control state (local UI state)
    private gimbalX: number = 0; // -15 to +15 degrees
    private gimbalY: number = 0; // -15 to +15 degrees

    // RCS thrusters (12 thrusters)
    private rcsActive: boolean[] = new Array(12).fill(false);

    constructor(ctx: CanvasRenderingContext2D, palette: any, spacecraft: SpacecraftAdapter) {
        this.ctx = ctx;
        this.palette = palette;
        this.spacecraft = spacecraft;
    }

    /**
     * Handle keyboard input for HELM controls
     */
    handleInput(key: string): void {
        const keyLower = key.toLowerCase();
        const engineState = this.spacecraft.getMainEngineState();

        switch (keyLower) {
            // Main Engine Controls
            case 'f':
                const currentValve = engineState.fuelValveOpen;
                this.spacecraft.setFuelValve(!currentValve);
                console.log(`Fuel valve: ${!currentValve ? 'OPEN' : 'CLOSED'}`);
                break;
            case 'g':
                this.spacecraft.armIgnition();
                console.log('Ignition ARMED');
                break;
            case 'h':
                this.spacecraft.fireEngine();
                console.log('Ignition FIRE!');
                break;
            case 'r':
                this.spacecraft.cutoffEngine();
                console.log('EMERGENCY CUTOFF!');
                break;

            // Throttle
            case 'q':
                const newThrottle = Math.min(100, (engineState.throttle * 100) + 5);
                this.spacecraft.setThrottle(newThrottle);
                console.log(`Throttle: ${newThrottle.toFixed(0)}%`);
                break;
            case 'a':
                const lowerThrottle = Math.max(0, (engineState.throttle * 100) - 5);
                this.spacecraft.setThrottle(lowerThrottle);
                console.log(`Throttle: ${lowerThrottle.toFixed(0)}%`);
                break;

            // Gimbal
            case 'w':
                this.gimbalX = Math.min(15, this.gimbalX + 1);
                this.spacecraft.setGimbal(this.gimbalX, this.gimbalY);
                console.log(`Gimbal X: ${this.gimbalX}°`);
                break;
            case 's':
                this.gimbalX = Math.max(-15, this.gimbalX - 1);
                this.spacecraft.setGimbal(this.gimbalX, this.gimbalY);
                console.log(`Gimbal X: ${this.gimbalX}°`);
                break;
            case 'e':
                this.gimbalY = Math.min(15, this.gimbalY + 1);
                this.spacecraft.setGimbal(this.gimbalX, this.gimbalY);
                console.log(`Gimbal Y: ${this.gimbalY}°`);
                break;
            case 'd':
                this.gimbalY = Math.max(-15, this.gimbalY - 1);
                this.spacecraft.setGimbal(this.gimbalX, this.gimbalY);
                console.log(`Gimbal Y: ${this.gimbalY}°`);
                break;

            // RCS Thrusters (1-9, 0)
            case '1': case '2': case '3': case '4':
            case '5': case '6': case '7': case '8':
            case '9': case '0':
                const num = key === '0' ? 9 : parseInt(key) - 1;
                this.rcsActive[num] = !this.rcsActive[num];
                this.spacecraft.fireRCS(num, this.rcsActive[num]);
                console.log(`RCS Thruster ${num + 1}: ${this.rcsActive[num] ? 'FIRING' : 'OFF'}`);
                break;
        }
    }

    /**
     * Render the HELM station panel
     */
    render(): void {
        const ctx = this.ctx;
        const width = ctx.canvas.width;
        const height = ctx.canvas.height;

        // Get live spacecraft data
        const engineState = this.spacecraft.getMainEngineState();
        const fuelState = this.spacecraft.getFuelState();
        const thermalState = this.spacecraft.getThermalState();

        // Set up text rendering
        ctx.font = '14px "Courier New"';
        ctx.fillStyle = this.palette.primary;

        // Draw title
        ctx.font = 'bold 20px "Courier New"';
        ctx.fillStyle = this.palette.info;
        ctx.fillText('HELM CONTROL', 40, 40);

        // Reset font
        ctx.font = '14px "Courier New"';

        // Main Engine Section (left side)
        this.drawBox(40, 60, 350, 400, 'MAIN ENGINE');
        let y = 100;

        // Fuel Valve
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('FUEL VALVE', 60, y);
        ctx.fillStyle = engineState.fuelValveOpen ? this.palette.primary : this.palette.muted;
        ctx.fillText(engineState.fuelValveOpen ? '● OPEN' : '○ CLOSED', 80, y + 25);
        y += 60;

        // Ignition
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('IGNITION', 60, y);
        const isArmed = engineState.status === 'armed' || engineState.status === 'igniting' || engineState.status === 'running';
        ctx.fillStyle = isArmed ? this.palette.warning : this.palette.muted;
        ctx.fillText(isArmed ? '[  ARMED  ]' : '[ DISARM  ]', 80, y + 25);
        const isRunning = engineState.status === 'running';
        ctx.fillStyle = isRunning ? this.palette.danger : this.palette.muted;
        ctx.fillText(isRunning ? '[  FIRE!  ]' : '[  FIRE   ]', 80, y + 45);
        y += 85;

        // Throttle
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('THROTTLE', 60, y);
        const throttlePct = engineState.throttle * 100;
        this.drawGauge(80, y + 10, 200, 20, throttlePct, 100);
        ctx.fillStyle = this.palette.secondary;
        ctx.fillText(`${throttlePct.toFixed(0)}%  (Q/A)`, 80, y + 50);
        y += 75;

        // Gimbal
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('GIMBAL', 60, y);
        ctx.fillStyle = this.palette.secondary;
        ctx.fillText(`X: ${this.gimbalX.toFixed(1)}°  (W/S)`, 80, y + 25);
        ctx.fillText(`Y: ${this.gimbalY.toFixed(1)}°  (E/D)`, 80, y + 45);

        // RCS Thrusters Section (right side, top)
        this.drawBox(420, 60, 420, 250, 'RCS THRUSTERS');
        y = 100;
        ctx.fillStyle = this.palette.secondary;
        ctx.fillText('BOW    [1][2][3][4]', 440, y);
        ctx.fillText('       P  S  D  V', 440, y + 20);
        y += 50;
        ctx.fillText('MID    [5][6][7][8]', 440, y);
        ctx.fillText('       P  S  D  V', 440, y + 20);
        y += 50;
        ctx.fillText('STERN  [9][0][-][=]', 440, y);
        ctx.fillText('       P  S  D  V', 440, y + 20);
        y += 50;
        ctx.fillStyle = this.palette.muted;
        ctx.fillText('P=Port S=Starboard', 440, y);
        ctx.fillText('D=Dorsal V=Ventral', 440, y + 20);

        // Fuel Status Section (right side, bottom)
        this.drawBox(420, 330, 420, 250, 'FUEL STATUS');
        y = 370;

        // Get fuel levels (approximation - fuel system may not have individual tank tracking)
        const totalFuel = fuelState.totalFuel;
        const capacity = fuelState.capacity;
        const fuelPercent = (totalFuel / capacity) * 100;

        // Show as 3 tanks (visual approximation)
        for (let i = 0; i < 3; i++) {
            ctx.fillStyle = this.palette.primary;
            ctx.fillText(`TANK ${i + 1}`, 440, y);
            // Approximate distribution
            const tankPercent = Math.max(0, Math.min(100, fuelPercent + (i - 1) * 10));
            this.drawGauge(550, y - 12, 150, 16, tankPercent, 100);
            ctx.fillStyle = this.palette.secondary;
            ctx.fillText(`${tankPercent.toFixed(0)}%`, 720, y);
            y += 40;
        }

        // Engine Status
        y += 20;
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('ENGINE STATUS', 440, y);
        y += 25;

        // Get engine temperature from thermal system
        const engineTemp = thermalState.nodes?.engine?.temperature || 293;
        const tempColor = engineTemp > 500 ? this.palette.danger : this.palette.primary;
        ctx.fillStyle = tempColor;
        ctx.fillText(`TEMP:  ${engineTemp.toFixed(0)}K`, 460, y);
        y += 20;
        ctx.fillStyle = this.palette.secondary;
        const fuelPressure = engineState.fuelPressure || 2.1;
        ctx.fillText(`PRESS: ${fuelPressure.toFixed(1)}bar`, 460, y);
        y += 20;
        const thrust = engineState.thrust || 0;
        const thrustPercent = (thrust / 45000) * 100; // Max thrust ~45kN
        ctx.fillText(`THRUST: ${thrustPercent.toFixed(0)}%`, 460, y);

        // Keyboard hints at bottom
        this.renderKeyboardHints();
    }

    private drawBox(x: number, y: number, w: number, h: number, title?: string): void {
        const ctx = this.ctx;

        // Draw box outline
        ctx.strokeStyle = this.palette.primary;
        ctx.lineWidth = 2;
        ctx.strokeRect(x, y, w, h);

        // Draw title if provided
        if (title) {
            ctx.fillStyle = this.palette.background;
            const titleWidth = ctx.measureText(title).width + 20;
            ctx.fillRect(x + 10, y - 10, titleWidth, 20);
            ctx.fillStyle = this.palette.info;
            ctx.fillText(title, x + 20, y + 5);
        }
    }

    private drawGauge(x: number, y: number, w: number, h: number, value: number, max: number): void {
        const ctx = this.ctx;
        const fillWidth = (value / max) * w;

        // Background
        ctx.fillStyle = this.palette.muted;
        ctx.fillRect(x, y, w, h);

        // Fill
        ctx.fillStyle = this.palette.primary;
        ctx.fillRect(x, y, fillWidth, h);

        // Border
        ctx.strokeStyle = this.palette.primary;
        ctx.lineWidth = 1;
        ctx.strokeRect(x, y, w, h);
    }

    private renderKeyboardHints(): void {
        const ctx = this.ctx;
        const y = ctx.canvas.height - 30;

        ctx.fillStyle = this.palette.muted;
        ctx.font = '12px "Courier New"';
        ctx.fillText('F=Valve  G=Arm  H=Fire  R=Cutoff  Q/A=Throttle  W/S/E/D=Gimbal  1-0=RCS', 40, y);
    }
}
