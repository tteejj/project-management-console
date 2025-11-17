/**
 * Spacecraft Integration Module
 *
 * Integrates all physics modules into a unified spacecraft simulation:
 * - Fuel System
 * - Electrical System
 * - Compressed Gas System
 * - Thermal System
 * - Coolant System
 * - Main Engine
 * - RCS System
 * - Ship Physics Core
 * - Flight Control System (PID, SAS, Autopilot)
 * - Navigation System (Trajectory, Telemetry)
 * - Mission System (Objectives, Scoring)
 *
 * Handles:
 * - System interconnections
 * - Resource management
 * - Power distribution
 * - Thermal coupling
 * - Flight automation
 * - Navigation and guidance
 * - Mission management
 * - Complete update loop
 */
import { FuelSystem } from './fuel-system';
import { ElectricalSystem } from './electrical-system';
import { CompressedGasSystem } from './compressed-gas-system';
import { ThermalSystem } from './thermal-system';
import { CoolantSystem } from './coolant-system';
import { MainEngine } from './main-engine';
import { RCSSystem } from './rcs-system';
import { ShipPhysics } from './ship-physics';
import { FlightControlSystem, type SASMode, type AutopilotMode } from './flight-control';
import { NavigationSystem } from './navigation';
import { MissionSystem, type Mission } from './mission';
import { TerrainSystem } from './terrain-system';
export interface SpacecraftConfig {
    fuelConfig?: any;
    electricalConfig?: any;
    gasConfig?: any;
    thermalConfig?: any;
    coolantConfig?: any;
    mainEngineConfig?: any;
    rcsConfig?: any;
    shipPhysicsConfig?: any;
    flightControlConfig?: any;
    navigationConfig?: any;
    missionConfig?: any;
    terrainConfig?: any;
}
export declare class Spacecraft {
    fuel: FuelSystem;
    electrical: ElectricalSystem;
    gas: CompressedGasSystem;
    thermal: ThermalSystem;
    coolant: CoolantSystem;
    mainEngine: MainEngine;
    rcs: RCSSystem;
    physics: ShipPhysics;
    flightControl: FlightControlSystem;
    navigation: NavigationSystem;
    mission: MissionSystem;
    terrain: TerrainSystem;
    simulationTime: number;
    private initialFuelCapacity;
    constructor(config?: SpacecraftConfig);
    /**
     * Master update loop - integrates all systems
     */
    update(dt: number): void;
    /**
     * Get available RCS fuel
     */
    private getAvailableRCSFuel;
    /**
     * Get comprehensive spacecraft state
     */
    getState(): {
        simulationTime: number;
        physics: {
            position: {
                x: number;
                y: number;
                z: number;
            };
            velocity: {
                x: number;
                y: number;
                z: number;
            };
            altitude: number;
            speed: number;
            verticalSpeed: number;
            attitude: {
                w: number;
                x: number;
                y: number;
                z: number;
            };
            eulerAngles: {
                roll: number;
                pitch: number;
                yaw: number;
            };
            angularVelocity: {
                x: number;
                y: number;
                z: number;
            };
            dryMass: number;
            propellantMass: number;
            totalMass: number;
            simulationTime: number;
        };
        fuel: {
            tanks: {
                id: string;
                fuelMass: number;
                pressureBar: number;
                temperature: number;
                fuelPercent: number;
            }[];
            fuelLines: {
                mainEngine: import("./types").FuelLine;
                rcsManifold: import("./types").FuelLine;
            };
            totalFuel: number;
            balance: {
                offset: import("./types").Vector2;
                magnitude: number;
            };
            totalConsumed: number;
        };
        electrical: {
            reactor: {
                status: "online" | "offline" | "starting" | "scrammed";
                outputKW: number;
                throttle: number;
                fuelRemaining: number;
                temperature: number;
                heatGenerationW: number;
            };
            battery: {
                chargeKWh: number;
                chargePercent: number;
                temperature: number;
                health: number;
                chargeCycles: number;
            };
            capacitor: {
                chargeKJ: number;
                chargePercent: number;
            };
            buses: {
                name: "A" | "B";
                loadKW: number;
                capacityKW: number;
                loadPercent: number;
                crosstieEnabled: boolean;
            }[];
            totalLoad: number;
            netPower: number;
            breakerStatus: {
                key: string;
                name: string;
                on: boolean;
                tripped: boolean;
                bus: "A" | "B";
            }[];
        };
        gas: {
            bottles: {
                index: number;
                gas: "N2" | "O2" | "He";
                pressureBar: number;
                massKg: number;
                temperature: number;
                percentFull: number;
                ruptured: boolean;
            }[];
            regulators: {
                name: string;
                active: boolean;
                outputPressure: number;
                inputBottle: number;
            }[];
            totalConsumed: {
                [k: string]: number;
            };
            ambientTemperature: number;
        };
        thermal: {
            components: {
                name: string;
                temperature: number;
                heatGeneration: number;
                compartmentId: number;
            }[];
            compartments: {
                id: number;
                name: string;
                temperature: number;
                gasMass: number;
            }[];
            totalHeatGenerated: number;
        };
        coolant: {
            loops: {
                id: number;
                name: string;
                coolantMassKg: number;
                percentFull: number;
                temperature: number;
                radiatorTemperature: number;
                flowRateLPerMin: number;
                pumpActive: boolean;
                pumpPowerW: number;
                frozen: boolean;
                boiling: boolean;
                leaking: boolean;
            }[];
            crossConnectOpen: boolean;
            totalHeatRejected: number;
        };
        mainEngine: {
            status: "off" | "igniting" | "running" | "shutdown";
            throttle: number;
            currentThrustN: number;
            currentThrustKN: number;
            gimbalPitch: number;
            gimbalYaw: number;
            chamberPressureBar: number;
            chamberTempK: number;
            health: number;
            totalFiredSeconds: number;
            ignitionCount: number;
            massFlowRateKgPerSec: number;
            totalFuelConsumedKg: number;
            totalOxidizerConsumedKg: number;
            restartCooldownS: number;
        };
        rcs: {
            thrusters: {
                id: number;
                name: string;
                active: boolean;
                thrustN: number;
                totalFiredSeconds: number;
                pulseCount: number;
            }[];
            groups: {
                name: string;
                active: boolean;
                thrusterCount: number;
            }[];
            totalActiveThrust: number;
            activeThrusterCount: number;
            totalFuelConsumed: number;
            thrustVector: {
                x: number;
                y: number;
                z: number;
            };
            torqueVector: {
                x: number;
                y: number;
                z: number;
            };
        };
        flightControl: import("./flight-control").FlightControlState;
        navigation: import("./navigation").FlightTelemetry;
        mission: Mission | null;
    };
    /**
     * Get navigation telemetry
     */
    getNavigationTelemetry(): import("./navigation").FlightTelemetry;
    /**
     * Command interface: Ignite main engine
     */
    igniteMainEngine(): boolean;
    /**
     * Command interface: Shutdown main engine
     */
    shutdownMainEngine(): void;
    /**
     * Command interface: Set main engine throttle
     */
    setMainEngineThrottle(throttle: number): void;
    /**
     * Command interface: Activate RCS group
     */
    activateRCS(groupName: string): boolean;
    /**
     * Command interface: Deactivate RCS group
     */
    deactivateRCS(groupName: string): void;
    /**
     * Command interface: Start reactor
     */
    startReactor(): boolean;
    /**
     * Command interface: Start coolant pump
     */
    startCoolantPump(loopId: number): boolean;
    /**
     * Set SAS mode
     */
    setSASMode(mode: SASMode): void;
    /**
     * Get current SAS mode
     */
    getSASMode(): SASMode;
    /**
     * Set autopilot mode
     */
    setAutopilotMode(mode: AutopilotMode): void;
    /**
     * Get current autopilot mode
     */
    getAutopilotMode(): AutopilotMode;
    /**
     * Set target altitude for altitude hold autopilot
     */
    setTargetAltitude(altitude: number): void;
    /**
     * Set target vertical speed for vertical speed hold autopilot
     */
    setTargetVerticalSpeed(speed: number): void;
    /**
     * Enable/disable gimbal autopilot
     */
    setGimbalAutopilot(enabled: boolean): void;
    /**
     * Set navigation target
     */
    setNavigationTarget(position: {
        x: number;
        y: number;
        z: number;
    }): void;
    /**
     * Clear navigation target
     */
    clearNavigationTarget(): void;
    /**
     * Get trajectory prediction
     */
    predictTrajectory(): import("./navigation").ImpactPrediction;
    /**
     * Get suicide burn data
     */
    getSuicideBurnData(): import("./navigation").SuicideBurnData;
    /**
     * Render navball display
     */
    renderNavball(): string;
    /**
     * Load mission
     */
    loadMission(mission: Mission): void;
    /**
     * Start mission
     */
    startMission(): void;
    /**
     * Get current mission
     */
    getCurrentMission(): Mission | null;
    /**
     * Complete mission objective
     */
    completeObjective(objectiveId: string): void;
    /**
     * Calculate mission score
     */
    calculateMissionScore(landingSpeed: number, landingAngle: number): import("./mission").MissionResult;
    /**
     * Get all system events
     */
    getAllEvents(): {
        fuel: {
            time: number;
            type: string;
            data: any;
        }[];
        electrical: {
            time: number;
            type: string;
            data: any;
        }[];
        gas: {
            time: number;
            type: string;
            data: any;
        }[];
        thermal: {
            time: number;
            type: string;
            data: any;
        }[];
        coolant: {
            time: number;
            type: string;
            data: any;
        }[];
        mainEngine: {
            time: number;
            type: string;
            data: any;
        }[];
        rcs: {
            time: number;
            type: string;
            data: any;
        }[];
        physics: {
            time: number;
            type: string;
            data: any;
        }[];
    };
}
//# sourceMappingURL=spacecraft.d.ts.map