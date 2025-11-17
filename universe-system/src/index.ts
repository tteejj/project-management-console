/**
 * Universe System
 * Complete procedural universe generation system for space games
 */

// Core celestial bodies
export {
  Vector3,
  OrbitalElements,
  PhysicalProperties,
  VisualProperties,
  RingSystem,
  CelestialBodyType,
  PlanetClass,
  StarClass,
  CelestialBody,
  Star,
  Planet,
  Moon,
  Asteroid
} from './CelestialBody';

// Planet generation
export {
  PlanetGenerator,
  PlanetGenerationConfig,
  MoonGenerationConfig
} from './PlanetGenerator';

// Space stations
export {
  StationType,
  StationFaction,
  StationServices,
  DockingPort,
  StationEconomy,
  SpaceStation,
  StationGenerator
} from './StationGenerator';

// Environmental hazards
export {
  HazardType,
  HazardSeverity,
  HazardEffect,
  HazardZone,
  Hazard,
  SolarStorm,
  RadiationBelt,
  DebrisField,
  IonStorm,
  HazardSystem
} from './HazardSystem';

// Star systems
export {
  StarSystemConfig,
  StarSystemData,
  StarSystem,
  generateStarSystem
} from './StarSystem';

// Universe designer and manager
export {
  UniverseConfig,
  JumpRoute,
  GameState,
  Mission,
  UniverseDesigner,
  createUniverse
} from './UniverseDesigner';

// Examples
export {
  createSandboxUniverse,
  createOpenWorldUniverse,
  createCampaignUniverse,
  createSolSystem,
  createFrontierSystem,
  createCoreWorldSystem,
  demoUniversePlaythrough,
  demoCustomSystem,
  demoStationTrading
} from './examples';
