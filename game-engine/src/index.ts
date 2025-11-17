/**
 * Space Game Engine
 * Complete integration of universe generation and ship physics
 */

export { SpaceGame, GameConfig } from './SpaceGame';
export { runGameDemo } from './demo';

// Re-export universe system
export * from '../../universe-system/src';

// Re-export physics modules
export { Spacecraft } from '../../physics-modules/src/spacecraft';
export { ShipPhysics } from '../../physics-modules/src/ship-physics';
export { MainEngine } from '../../physics-modules/src/main-engine';
export { RCSSystem } from '../../physics-modules/src/rcs-system';
export { FuelSystem } from '../../physics-modules/src/fuel-system';
export { ElectricalSystem } from '../../physics-modules/src/electrical-system';
export { ThermalSystem } from '../../physics-modules/src/thermal-system';
export { FlightControl } from '../../physics-modules/src/flight-control';
export { Navigation } from '../../physics-modules/src/navigation';
