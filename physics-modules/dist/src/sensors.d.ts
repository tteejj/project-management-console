/**
 * Sensor Systems
 *
 * Implements radar, thermal IR, LIDAR, and mass detector physics
 * NO RENDERING - physics only
 */
import { Vector3 } from './math-utils';
import { World, CelestialBody } from './world';
export declare enum SensorType {
    RADAR = "radar",
    THERMAL = "thermal",
    LIDAR = "lidar",
    MASS_DETECTOR = "mass_detector"
}
export declare enum RadarBand {
    X_BAND = "X",// 8-12 GHz (most common)
    KU_BAND = "Ku",// 12-18 GHz
    KA_BAND = "Ka"
}
export interface SensorContact {
    bodyId: string;
    sensorType: SensorType;
    range: number;
    bearing: Vector3;
    signalStrength: number;
    confidence: number;
    timestamp: number;
}
export interface RadarConfig {
    maxRange: number;
    band: RadarBand;
    power: number;
    antennaGain: number;
    noiseFloor: number;
}
export interface ThermalConfig {
    maxRange: number;
    sensitivity: number;
    fov: number;
}
export interface LIDARConfig {
    maxRange: number;
    angularResolution: number;
    rangeResolution: number;
}
export interface MassDetectorConfig {
    sensitivity: number;
    maxRange: number;
}
/**
 * Radar sensor using radar equation
 * Range equation: Pr = (Pt * Gt * Gr * λ² * σ) / ((4π)³ * R⁴ * L)
 * Simplified for game: Detection range based on RCS and power
 */
export declare class RadarSensor {
    private config;
    private wavelength;
    constructor(config: RadarConfig);
    scan(observerPos: Vector3, world: World, excludeBody?: CelestialBody): SensorContact[];
}
/**
 * Thermal IR sensor
 * Detects infrared radiation from warm objects
 */
export declare class ThermalSensor {
    private config;
    constructor(config: ThermalConfig);
    scan(observerPos: Vector3, world: World, excludeBody?: CelestialBody): SensorContact[];
}
/**
 * LIDAR (Light Detection and Ranging)
 * High-precision ranging using laser pulses
 */
export declare class LIDARSensor {
    private config;
    constructor(config: LIDARConfig);
    scan(observerPos: Vector3, world: World, excludeBody?: CelestialBody): SensorContact[];
}
/**
 * Mass Detector
 * Detects gravitational anomalies from massive objects
 */
export declare class MassDetector {
    private config;
    constructor(config: MassDetectorConfig);
    scan(observerPos: Vector3, world: World, excludeBody?: CelestialBody): SensorContact[];
}
/**
 * Sensor system integration
 */
export interface Sensor {
    scan(observerPos: Vector3, world: World, excludeBody?: CelestialBody): SensorContact[];
}
export declare class SensorSystem {
    private sensors;
    addSensor(id: string, sensor: Sensor): void;
    removeSensor(id: string): void;
    setSensorPower(id: string, active: boolean): void;
    isSensorActive(id: string): boolean;
    scanAll(observerPos: Vector3, world: World, excludeBody?: CelestialBody): SensorContact[];
    getSensor(id: string): Sensor | undefined;
}
//# sourceMappingURL=sensors.d.ts.map