"use strict";
/**
 * Sensor Systems
 *
 * Implements radar, thermal IR, LIDAR, and mass detector physics
 * NO RENDERING - physics only
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.SensorSystem = exports.MassDetector = exports.LIDARSensor = exports.ThermalSensor = exports.RadarSensor = exports.RadarBand = exports.SensorType = void 0;
const math_utils_1 = require("./math-utils");
var SensorType;
(function (SensorType) {
    SensorType["RADAR"] = "radar";
    SensorType["THERMAL"] = "thermal";
    SensorType["LIDAR"] = "lidar";
    SensorType["MASS_DETECTOR"] = "mass_detector";
})(SensorType || (exports.SensorType = SensorType = {}));
var RadarBand;
(function (RadarBand) {
    RadarBand["X_BAND"] = "X";
    RadarBand["KU_BAND"] = "Ku";
    RadarBand["KA_BAND"] = "Ka"; // 26-40 GHz
})(RadarBand || (exports.RadarBand = RadarBand = {}));
/**
 * Radar sensor using radar equation
 * Range equation: Pr = (Pt * Gt * Gr * λ² * σ) / ((4π)³ * R⁴ * L)
 * Simplified for game: Detection range based on RCS and power
 */
class RadarSensor {
    constructor(config) {
        this.config = config;
        // Calculate wavelength from band
        const frequencies = {
            [RadarBand.X_BAND]: 10e9, // 10 GHz
            [RadarBand.KU_BAND]: 15e9, // 15 GHz
            [RadarBand.KA_BAND]: 35e9 // 35 GHz
        };
        const frequency = frequencies[config.band];
        this.wavelength = 3e8 / frequency; // c / f
    }
    scan(observerPos, world, excludeBody) {
        const contacts = [];
        const bodies = world.getAllBodies();
        for (const body of bodies) {
            if (excludeBody && body.id === excludeBody.id)
                continue;
            const range = math_utils_1.VectorMath.distance(observerPos, body.position);
            // Skip if beyond max range
            if (range > this.config.maxRange)
                continue;
            // Skip if zero range (observer at target position or self)
            if (range < 1)
                continue;
            const rcs = body.radarCrossSection || 0;
            // Skip if zero RCS (perfect stealth)
            if (rcs <= 0)
                continue;
            // Radar equation (simplified)
            // Received power: Pr = (Pt * Gt * Gr * λ² * RCS) / ((4π)³ * R⁴)
            // Assuming Gt = Gr (same antenna for transmit/receive)
            const Pt = this.config.power;
            const Gt = Math.pow(10, this.config.antennaGain / 10); // Convert dB to linear
            const lambda = this.wavelength;
            // Simplified radar equation
            const numerator = Pt * Gt * Gt * lambda * lambda * rcs;
            const denominator = Math.pow(4 * Math.PI, 3) * Math.pow(range, 4);
            const Pr = numerator / denominator;
            // Convert to dBm
            const PrdBm = 10 * Math.log10(Pr * 1000); // Convert to milliwatts
            // Check if above noise floor
            if (PrdBm < this.config.noiseFloor)
                continue;
            // Calculate bearing (unit vector to target)
            const bearing = math_utils_1.VectorMath.normalize(math_utils_1.VectorMath.subtract(body.position, observerPos));
            // Confidence based on SNR (signal-to-noise ratio)
            const snr = PrdBm - this.config.noiseFloor;
            const confidence = Math.min(1.0, snr / 20); // 20dB SNR = perfect confidence
            contacts.push({
                bodyId: body.id,
                sensorType: SensorType.RADAR,
                range,
                bearing,
                signalStrength: PrdBm,
                confidence,
                timestamp: 0
            });
        }
        return contacts;
    }
}
exports.RadarSensor = RadarSensor;
/**
 * Thermal IR sensor
 * Detects infrared radiation from warm objects
 */
class ThermalSensor {
    constructor(config) {
        this.config = config;
    }
    scan(observerPos, world, excludeBody) {
        const contacts = [];
        const bodies = world.getAllBodies();
        // Background temperature (cosmic microwave background + local environment)
        const backgroundTemp = 2.7 + 250; // ~253K (cold space + moon surface radiation)
        for (const body of bodies) {
            if (excludeBody && body.id === excludeBody.id)
                continue;
            const range = math_utils_1.VectorMath.distance(observerPos, body.position);
            if (range > this.config.maxRange)
                continue;
            if (range < 1)
                continue;
            const thermalSig = body.thermalSignature || backgroundTemp;
            // Temperature difference from background
            const deltaT = Math.abs(thermalSig - backgroundTemp);
            // Can we detect this temperature difference?
            if (deltaT < this.config.sensitivity)
                continue;
            // Apparent temperature based on solid angle
            // Solid angle = π * r² / d² (for a sphere)
            // Apparent signal strength proportional to solid angle and temperature
            const solidAngle = Math.PI * (body.radius * body.radius) / (range * range);
            const apparentDeltaT = deltaT * solidAngle * 1000; // Scale factor for detectability
            // Need minimum intensity to detect
            const minDetectable = this.config.sensitivity;
            if (apparentDeltaT < minDetectable)
                continue;
            // Signal strength proportional to apparent delta-T
            const signalStrength = apparentDeltaT / minDetectable;
            const bearing = math_utils_1.VectorMath.normalize(math_utils_1.VectorMath.subtract(body.position, observerPos));
            const confidence = Math.min(1.0, signalStrength);
            contacts.push({
                bodyId: body.id,
                sensorType: SensorType.THERMAL,
                range,
                bearing,
                signalStrength,
                confidence,
                timestamp: 0
            });
        }
        return contacts;
    }
}
exports.ThermalSensor = ThermalSensor;
/**
 * LIDAR (Light Detection and Ranging)
 * High-precision ranging using laser pulses
 */
class LIDARSensor {
    constructor(config) {
        this.config = config;
    }
    scan(observerPos, world, excludeBody) {
        const contacts = [];
        const bodies = world.getAllBodies();
        for (const body of bodies) {
            if (excludeBody && body.id === excludeBody.id)
                continue;
            const range = math_utils_1.VectorMath.distance(observerPos, body.position);
            if (range > this.config.maxRange)
                continue;
            if (range < 1)
                continue;
            const bearing = math_utils_1.VectorMath.normalize(math_utils_1.VectorMath.subtract(body.position, observerPos));
            // LIDAR has very high SNR for any detectable target
            const signalStrength = 1.0;
            const confidence = 1.0;
            contacts.push({
                bodyId: body.id,
                sensorType: SensorType.LIDAR,
                range,
                bearing,
                signalStrength,
                confidence,
                timestamp: 0
            });
        }
        return contacts;
    }
}
exports.LIDARSensor = LIDARSensor;
/**
 * Mass Detector
 * Detects gravitational anomalies from massive objects
 */
class MassDetector {
    constructor(config) {
        this.config = config;
    }
    scan(observerPos, world, excludeBody) {
        const contacts = [];
        const bodies = world.getAllBodies();
        for (const body of bodies) {
            if (excludeBody && body.id === excludeBody.id)
                continue;
            const range = math_utils_1.VectorMath.distance(observerPos, body.position);
            if (range > this.config.maxRange)
                continue;
            if (range < 1)
                continue;
            // Calculate gravitational acceleration: g = GM/r²
            const gravAccel = (math_utils_1.G * body.mass) / (range * range);
            // Check if detectable
            if (gravAccel < this.config.sensitivity)
                continue;
            const bearing = math_utils_1.VectorMath.normalize(math_utils_1.VectorMath.subtract(body.position, observerPos));
            // Signal strength is ratio of g-force to sensitivity
            const signalStrength = gravAccel / this.config.sensitivity;
            const confidence = Math.min(1.0, signalStrength);
            contacts.push({
                bodyId: body.id,
                sensorType: SensorType.MASS_DETECTOR,
                range,
                bearing,
                signalStrength,
                confidence,
                timestamp: 0
            });
        }
        return contacts;
    }
}
exports.MassDetector = MassDetector;
class SensorSystem {
    constructor() {
        this.sensors = new Map();
    }
    addSensor(id, sensor) {
        this.sensors.set(id, { sensor, active: true });
    }
    removeSensor(id) {
        this.sensors.delete(id);
    }
    setSensorPower(id, active) {
        const entry = this.sensors.get(id);
        if (entry) {
            entry.active = active;
        }
    }
    isSensorActive(id) {
        const entry = this.sensors.get(id);
        return entry ? entry.active : false;
    }
    scanAll(observerPos, world, excludeBody) {
        const allContacts = [];
        for (const [id, entry] of this.sensors.entries()) {
            if (!entry.active)
                continue;
            const contacts = entry.sensor.scan(observerPos, world, excludeBody);
            allContacts.push(...contacts);
        }
        return allContacts;
    }
    getSensor(id) {
        const entry = this.sensors.get(id);
        return entry ? entry.sensor : undefined;
    }
}
exports.SensorSystem = SensorSystem;
//# sourceMappingURL=sensors.js.map