/**
 * Moon Lander Physics - Complete Physical World
 *
 * Exports all physics systems for integration
 */

// Shared types
export * from './types';

// Export individual physics modules
export { TerrainSystem } from './terrain-system';
export { LandingGear } from './landing-gear';
export { OrbitalBody, OrbitalBodiesManager, createDefaultSatellite } from './orbital-bodies';
export { EnvironmentSystem } from './environment';
export { WaypointManager, createPracticeWaypoints } from './waypoints';

// Export integrated game systems
export { GameWorld } from './game-world';
export { GameSpacecraft } from './game-spacecraft';

// Export simple game systems (standalone, no external dependencies)
export { SimpleWorld } from './simple-world';
export { SimpleSpacecraft } from './simple-spacecraft';
