/**
 * Common types used across physics modules
 */

export interface Vector2 {
  x: number;
  y: number;
}

export interface Vector3 {
  x: number;
  y: number;
  z: number;
}

export interface Quaternion {
  w: number;
  x: number;
  y: number;
  z: number;
}

export interface FuelTank {
  id: string;
  volume: number; // liters
  fuelMass: number; // kg
  capacity: number; // kg max
  position: Vector2; // position on ship for balance calculation

  pressurized: boolean;
  pressureBar: number; // current pressure in bar
  pressurantType: 'N2' | 'He' | 'none';
  pressurantMass: number; // kg of compressed gas

  temperature: number; // Kelvin

  valves: {
    feedToEngine: boolean;
    feedToRCS: boolean;
    crossfeedTo?: string; // ID of tank to crossfeed to
    fillPort: boolean;
    vent: boolean;
  };
}

export interface FuelLine {
  connectedTank: string | null; // tank ID
  flowRate: number; // L/s current flow
  pressure: number; // bar
  fuelPumpActive: boolean;
}

export interface SimulationState {
  time: number; // seconds since start
  dt: number; // delta time for this step
}
