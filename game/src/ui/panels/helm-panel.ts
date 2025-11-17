/**
 * HELM / PROPULSION Station
 * Main engine, RCS thrusters, fuel management
 * Based on design: 01-CONTROL-STATIONS.md
 */

export class HelmPanel {
    private ctx: CanvasRenderingContext2D;
    private palette: any;

    // Control state
    private fuelValveOpen: boolean = false;
    private ignitionArmed: boolean = false;
    private engineFiring: boolean = false;
    private throttle: number = 0; // 0-100%
    private gimbalX: number = 0; // -15 to +15 degrees
    private gimbalY: number = 0; // -15 to +15 degrees

    // Fuel tanks (3 tanks)
    private tankLevels: number[] = [70, 55, 95]; // Percentages

    // RCS thrusters (12 thrusters)
    private rcsActive: boolean[] = new Array(12).fill(false);

    // Engine status
    private engineTemp: number = 425; // Kelvin
    private fuelPressure: number = 2.1; // bar
    private fuelFlow: number = 85; // percent

    constructor(ctx: CanvasRenderingContext2D, palette: any) {
        this.ctx = ctx;
        this.palette = palette;
    }

    /**
     * Handle keyboard input for HELM controls
     */
    handleInput(key: string): void {
        const keyLower = key.toLowerCase();

        switch (keyLower) {
            // Main Engine Controls
            case 'f':
                this.fuelValveOpen = !this.fuelValveOpen;
                console.log(`Fuel valve: ${this.fuelValveOpen ? 'OPEN' : 'CLOSED'}`);
                break;
            case 'g':
                this.ignitionArmed = !this.ignitionArmed;
                console.log(`Ignition: ${this.ignitionArmed ? 'ARMED' : 'DISARMED'}`);
                break;
            case 'h':
                if (this.ignitionArmed && this.fuelValveOpen && this.fuelPressure > 1.5) {
                    this.engineFiring = true;
                    console.log('Engine FIRING!');
                } else {
                    console.log('Cannot fire: Check valve, ignition, and pressure');
                }
                break;
            case 'r':
                this.engineFiring = false;
                this.ignitionArmed = false;
                console.log('EMERGENCY CUTOFF!');
                break;

            // Throttle
            case 'q':
                this.throttle = Math.min(100, this.throttle + 5);
                console.log(`Throttle: ${this.throttle}%`);
                break;
            case 'a':
                this.throttle = Math.max(0, this.throttle - 5);
                console.log(`Throttle: ${this.throttle}%`);
                break;

            // Gimbal
            case 'w':
                this.gimbalX = Math.min(15, this.gimbalX + 1);
                console.log(`Gimbal X: ${this.gimbalX}°`);
                break;
            case 's':
                this.gimbalX = Math.max(-15, this.gimbalX - 1);
                console.log(`Gimbal X: ${this.gimbalX}°`);
                break;
            case 'e':
                this.gimbalY = Math.min(15, this.gimbalY + 1);
                console.log(`Gimbal Y: ${this.gimbalY}°`);
                break;
            case 'd':
                this.gimbalY = Math.max(-15, this.gimbalY - 1);
                console.log(`Gimbal Y: ${this.gimbalY}°`);
                break;

            // RCS Thrusters (1-9, 0, -, =)
            case '1': case '2': case '3': case '4':
            case '5': case '6': case '7': case '8':
            case '9': case '0':
                const num = key === '0' ? 9 : parseInt(key) - 1;
                this.rcsActive[num] = !this.rcsActive[num];
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
        ctx.fillStyle = this.fuelValveOpen ? this.palette.primary : this.palette.muted;
        ctx.fillText(this.fuelValveOpen ? '● OPEN' : '○ CLOSED', 80, y + 25);
        y += 60;

        // Ignition
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('IGNITION', 60, y);
        ctx.fillStyle = this.ignitionArmed ? this.palette.warning : this.palette.muted;
        ctx.fillText(this.ignitionArmed ? '[  ARMED  ]' : '[ DISARM  ]', 80, y + 25);
        ctx.fillStyle = this.engineFiring ? this.palette.danger : this.palette.muted;
        ctx.fillText(this.engineFiring ? '[  FIRE!  ]' : '[  FIRE   ]', 80, y + 45);
        y += 85;

        // Throttle
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('THROTTLE', 60, y);
        this.drawGauge(80, y + 10, 200, 20, this.throttle, 100);
        ctx.fillStyle = this.palette.secondary;
        ctx.fillText(`${this.throttle}%  (Q/A)`, 80, y + 50);
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
        for (let i = 0; i < 3; i++) {
            ctx.fillStyle = this.palette.primary;
            ctx.fillText(`TANK ${i + 1}`, 440, y);
            this.drawGauge(550, y - 12, 150, 16, this.tankLevels[i], 100);
            ctx.fillStyle = this.palette.secondary;
            ctx.fillText(`${this.tankLevels[i]}%`, 720, y);
            y += 40;
        }

        // Engine Status
        y += 20;
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('ENGINE STATUS', 440, y);
        y += 25;
        const tempColor = this.engineTemp > 500 ? this.palette.danger : this.palette.primary;
        ctx.fillStyle = tempColor;
        ctx.fillText(`TEMP:  ${this.engineTemp}K`, 460, y);
        y += 20;
        ctx.fillStyle = this.palette.secondary;
        ctx.fillText(`PRESS: ${this.fuelPressure.toFixed(1)}bar`, 460, y);
        y += 20;
        ctx.fillText(`FLOW:  ${this.fuelFlow}%`, 460, y);

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
