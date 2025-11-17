/**
 * NAVIGATION / SENSORS Station
 * Sensors, radar, tactical display, navigation computer
 * Based on design: 01-CONTROL-STATIONS.md
 */

import { SpacecraftAdapter } from '../../spacecraft-adapter';

export class NavigationPanel {
    private ctx: CanvasRenderingContext2D;
    private palette: any;
    private spacecraft: SpacecraftAdapter;

    // State
    private radarRange: number = 10; // km

    constructor(ctx: CanvasRenderingContext2D, palette: any, spacecraft: SpacecraftAdapter) {
        this.ctx = ctx;
        this.palette = palette;
        this.spacecraft = spacecraft;
    }

    handleInput(key: string): void {
        const keyLower = key.toLowerCase();

        switch (keyLower) {
            case 'r':
                this.spacecraft.setRadarActive(true);
                console.log('Radar toggled');
                break;
            case 'z':
                this.radarRange = Math.min(100, this.radarRange + 5);
                this.spacecraft.setRadarRange(this.radarRange);
                console.log(`Radar range: ${this.radarRange}km`);
                break;
            case 'x':
                this.radarRange = Math.max(1, this.radarRange - 5);
                this.spacecraft.setRadarRange(this.radarRange);
                console.log(`Radar range: ${this.radarRange}km`);
                break;
        }
    }

    render(): void {
        const ctx = this.ctx;
        const navData = this.spacecraft.getNavigationTelemetry();

        ctx.font = 'bold 20px "Courier New"';
        ctx.fillStyle = this.palette.info;
        ctx.fillText('NAVIGATION', 40, 40);

        ctx.font = '14px "Courier New"';

        // Show altitude and velocity
        let infoY = 620;
        ctx.fillStyle = this.palette.primary;
        ctx.fillText(`Altitude: ${navData.altitude.toFixed(0)}m`, 40, infoY);
        ctx.fillText(`V/S: ${navData.verticalSpeed.toFixed(1)}m/s`, 250, infoY);
        ctx.fillText(`Speed: ${navData.horizontalSpeed.toFixed(1)}m/s`, 450, infoY);

        // Tactical Display (left side)
        let y = 80;
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('TACTICAL DISPLAY', 40, y);

        // Draw radar circle
        const radarX = 200;
        const radarY = 250;
        const radarRadius = 120;
        ctx.strokeStyle = this.palette.primary;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(radarX, radarY, radarRadius, 0, Math.PI * 2);
        ctx.stroke();

        // Draw crosshairs
        ctx.beginPath();
        ctx.moveTo(radarX - radarRadius, radarY);
        ctx.lineTo(radarX + radarRadius, radarY);
        ctx.moveTo(radarX, radarY - radarRadius);
        ctx.lineTo(radarX, radarY + radarRadius);
        ctx.stroke();

        // Draw ship (center)
        ctx.fillStyle = this.palette.primary;
        ctx.fillRect(radarX - 3, radarY - 3, 6, 6);

        // Sensors (right side)
        y = 80;
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('SENSORS', 450, y);
        y += 30;
        ctx.fillStyle = this.radarActive ? this.palette.primary : this.palette.muted;
        ctx.fillText(`RADAR: ${this.radarActive ? 'ACTIVE' : 'OFF'}  (R)`, 470, y);
        y += 25;
        ctx.fillStyle = this.palette.secondary;
        ctx.fillText(`Range: ${this.radarRange}km  (Z/X)`, 470, y);
        y += 20;
        ctx.fillText(`Gain: ${this.radarGain}%  (C/V)`, 470, y);
        y += 40;
        ctx.fillStyle = this.lidarActive ? this.palette.primary : this.palette.muted;
        ctx.fillText(`LIDAR: ${this.lidarActive ? 'ACTIVE' : 'PASSIVE'}  (L)`, 470, y);

        // Contacts
        y += 50;
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('CONTACTS', 450, y);
        y += 25;
        ctx.fillStyle = this.palette.muted;
        ctx.fillText('No contacts detected', 470, y);

        // Keyboard hints
        const hintsY = ctx.canvas.height - 30;
        ctx.fillStyle = this.palette.muted;
        ctx.font = '12px "Courier New"';
        ctx.fillText('R=Radar  Z/X=Range  C/V=Gain  L=LIDAR', 40, hintsY);
    }
}
