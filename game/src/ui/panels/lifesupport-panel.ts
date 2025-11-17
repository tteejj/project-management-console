/**
 * LIFE SUPPORT / ENVIRONMENTAL Station
 * Atmosphere management, compartments, fire suppression
 * Based on design: 01-CONTROL-STATIONS.md
 */

import { SpacecraftAdapter } from '../../spacecraft-adapter';

export class LifeSupportPanel {
    private ctx: CanvasRenderingContext2D;
    private palette: any;
    private spacecraft: SpacecraftAdapter;

    // State
    private selectedCompartment: number = 5; // Center compartment

    constructor(ctx: CanvasRenderingContext2D, palette: any, spacecraft: SpacecraftAdapter) {
        this.ctx = ctx;
        this.palette = palette;
        this.spacecraft = spacecraft;
    }

    handleInput(key: string): void {
        const keyLower = key.toLowerCase();

        switch (keyLower) {
            case '1': case '2': case '3': case '4': case '5': case '6':
                this.selectedCompartment = parseInt(key);
                console.log(`Selected compartment: ${this.selectedCompartment}`);
                break;
            case 'o':
                this.o2GeneratorOn = !this.o2GeneratorOn;
                console.log(`O2 Generator: ${this.o2GeneratorOn ? 'ON' : 'OFF'}`);
                break;
            case 's':
                this.co2ScrubberOn = !this.co2ScrubberOn;
                console.log(`CO2 Scrubber: ${this.co2ScrubberOn ? 'ON' : 'OFF'}`);
                break;
        }
    }

    render(): void {
        const ctx = this.ctx;

        ctx.font = 'bold 20px "Courier New"';
        ctx.fillStyle = this.palette.info;
        ctx.fillText('LIFE SUPPORT', 40, 40);

        ctx.font = '14px "Courier New"';

        // Ship layout diagram
        let y = 80;
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('SHIP LAYOUT (6 COMPARTMENTS)', 40, y);
        y += 30;
        ctx.fillText('[1]──[2]──[3]', 60, y);
        y += 25;
        ctx.fillText(' │    │    │', 60, y);
        y += 25;
        ctx.fillText('[4]──[5]──[6]', 60, y);
        y += 30;
        ctx.fillStyle = this.palette.secondary;
        ctx.fillText('1=Bow   2=Bridge  3=Engineering', 60, y);
        y += 20;
        ctx.fillText('4=Port  5=Center  6=Stern', 60, y);

        // Selected compartment display
        y += 50;
        ctx.fillStyle = this.palette.primary;
        ctx.fillText(`COMPARTMENT: #${this.selectedCompartment}  (1-6 to select)`, 40, y);
        y += 30;

        // Atmosphere readings
        ctx.fillText('ATMOSPHERE', 60, y);
        y += 25;
        const o2Color = this.o2Percent < 19 ? this.palette.warning : this.palette.primary;
        ctx.fillStyle = o2Color;
        ctx.fillText(`O2:    ${this.o2Percent}%  (NORM: 21%)`, 80, y);
        y += 20;
        ctx.fillStyle = this.palette.secondary;
        ctx.fillText(`CO2:   ${this.co2Percent}%  (NORM: <1%)`, 80, y);
        y += 20;
        ctx.fillText(`PRESS: ${this.pressure}kPa  (NORM: 101kPa)`, 80, y);
        y += 20;
        ctx.fillText(`TEMP:  ${this.temperature}K  (NORM: 293K)`, 80, y);

        // Global systems
        y += 50;
        ctx.fillStyle = this.palette.primary;
        ctx.fillText('GLOBAL SYSTEMS', 40, y);
        y += 25;
        ctx.fillStyle = this.o2GeneratorOn ? this.palette.primary : this.palette.danger;
        ctx.fillText(`O2 Generator: ${this.o2GeneratorOn ? 'ON' : 'OFF'}  (O)`, 60, y);
        y += 25;
        ctx.fillStyle = this.co2ScrubberOn ? this.palette.primary : this.palette.danger;
        ctx.fillText(`CO2 Scrubber: ${this.co2ScrubberOn ? 'ON' : 'OFF'}  (S)`, 60, y);

        // Keyboard hints
        const hintsY = ctx.canvas.height - 30;
        ctx.fillStyle = this.palette.muted;
        ctx.font = '12px "Courier New"';
        ctx.fillText('1-6=Select Compartment  O=O2 Gen  S=Scrubber', 40, hintsY);
    }
}
