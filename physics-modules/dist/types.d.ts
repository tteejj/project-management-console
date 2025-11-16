/**
 * Common types used across physics modules
 */
export interface Vector2 {
    x: number;
    y: number;
}
export interface FuelTank {
    id: string;
    volume: number;
    fuelMass: number;
    capacity: number;
    position: Vector2;
    pressurized: boolean;
    pressureBar: number;
    pressurantType: 'N2' | 'He' | 'none';
    pressurantMass: number;
    temperature: number;
    valves: {
        feedToEngine: boolean;
        feedToRCS: boolean;
        crossfeedTo?: string;
        fillPort: boolean;
        vent: boolean;
    };
}
export interface FuelLine {
    connectedTank: string | null;
    flowRate: number;
    pressure: number;
    fuelPumpActive: boolean;
}
export interface SimulationState {
    time: number;
    dt: number;
}
//# sourceMappingURL=types.d.ts.map