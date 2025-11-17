/**
 * ENGINEERING / POWER Station
 * Reactor, power distribution, thermal management, damage control
 * Based on design: 01-CONTROL-STATIONS.md
 */

export class EngineeringPanel {
    private ctx: CanvasRenderingContext2D;
    private palette: any;

    // State
    private reactorStatus: string = 'offline';
    private reactorThrottle: number = 75;
    private batteryCharge: number = 78;
    private breakers: boolean[] = new Array(10).fill(true); // 10 circuit breakers
    private coolantPumpOn: boolean = true;
    private radiatorsDeployed: boolean = false;

    constructor(ctx: CanvasRenderingContext2D, palette: any) {
        this.ctx = ctx;
        this.palette = palette;
    }

    handleInput(key: string): void {
        const keyLower = key.toLowerCase();

        switch (keyLower) {
            case 'r':
                console.log('Starting reactor...');
                this.reactorStatus = 'starting';
                break;
            case 't':
                console.log('Reactor SCRAM!');
                this.reactorStatus = 'offline';
                break;
            case 'i':
                this.reactorThrottle = Math.min(100, this.reactorThrottle + 5);
                console.log(`Reactor throttle: ${this.reactorThrottle}%`);
                break;
            case 'k':
                this.reactorThrottle = Math.max(0, this.reactorThrottle - 5);
                console.log(`Reactor throttle: ${this.reactorThrottle}%`);
                break;
            case '1': case '2': case '3': case '4': case '5':
            case '6': case '7': case '8': case '9': case '0':
                const num = key === '0' ? 9 : parseInt(key) - 1;
                this.breakers[num] = !this.breakers[num];
                console.log(`Breaker ${num + 1}: ${this.breakers[num] ? 'ON' : 'OFF'}`);
                break;
            case 'g':
                this.radiatorsDeployed = !this.radiatorsDeployed;
                console.log(`Radiators: ${this.radiatorsDeployed ? 'DEPLOYED' : 'RETRACTED'}`);
                break;
        }
    }

    render(): void {
        const ctx = this.ctx;

        ctx.font = 'bold 20px "Courier New"';
        ctx.fillStyle = this.palette.info;
        ctx.fillText('ENGINEERING', 40, 40);

        ctx.font = '14px "Courier New"';
        ctx.fillStyle = this.palette.primary;

        // Reactor section
        let y = 80;
        ctx.fillText('REACTOR', 40, y);
        y += 25;
        ctx.fillStyle = this.reactorStatus === 'online' ? this.palette.primary : this.palette.danger;
        ctx.fillText(`Status: ${this.reactorStatus.toUpperCase()}`, 60, y);
        y += 25;
        ctx.fillStyle = this.palette.secondary;
        ctx.fillText(`Throttle: ${this.reactorThrottle}%  (I/K)`, 60, y);

        // Power Distribution
        y += 50;
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('POWER DISTRIBUTION', 40, y);
        y += 25;
        ctx.fillStyle = this.palette.secondary;
        ctx.fillText('BREAKERS: 1-0 to toggle', 60, y);
        y += 25;
        for (let i = 0; i < 10; i++) {
            const status = this.breakers[i] ? 'ON ' : 'OFF';
            const color = this.breakers[i] ? this.palette.primary : this.palette.muted;
            ctx.fillStyle = color;
            ctx.fillText(`[${i + 1}] ${status}`, 60 + (i % 5) * 120, y + Math.floor(i / 5) * 25);
        }

        // Thermal
        y += 80;
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('THERMAL MANAGEMENT', 40, y);
        y += 25;
        ctx.fillStyle = this.palette.secondary;
        ctx.fillText(`Coolant Pump: ${this.coolantPumpOn ? 'ON' : 'OFF'}`, 60, y);
        y += 25;
        ctx.fillText(`Radiators: ${this.radiatorsDeployed ? 'DEPLOYED' : 'RETRACTED'}  (G)`, 60, y);

        // Keyboard hints
        const hintsY = ctx.canvas.height - 30;
        ctx.fillStyle = this.palette.muted;
        ctx.font = '12px "Courier New"';
        ctx.fillText('R=Start Reactor  T=SCRAM  I/K=Throttle  1-0=Breakers  G=Radiators', 40, hintsY);
    }
}
