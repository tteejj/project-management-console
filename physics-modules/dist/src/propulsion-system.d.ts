/**
 * Propulsion System
 *
 * Integrates thrusters with fuel, power, thermal, and physics systems
 */
import { Vector3 } from './math-utils';
export declare enum PropellantType {
    HYDRAZINE = "hydrazine",
    LOX_LH2 = "lox_lh2",
    MMH_NTO = "mmh_nto",
    XENON = "xenon"
}
export declare enum ThrusterType {
    MAIN_ENGINE = "main_engine",
    RCS = "rcs",
    ION_DRIVE = "ion_drive"
}
export interface ThrusterConfig {
    id: string;
    type: ThrusterType;
    position: Vector3;
    direction: Vector3;
    maxThrust: number;
    isp: number;
    propellantType: PropellantType;
    fuelTankId: string;
    canGimbal: boolean;
    gimbalRange?: number;
    minThrottle?: number;
    pumpPower?: number;
    gimbalPower?: number;
    efficiency: number;
}
export interface ThrusterState {
    enabled: boolean;
    throttle: number;
    gimbalAngle: Vector3;
    temperature: number;
    fuelFlow: number;
    powerDraw: number;
    heatGeneration: number;
    damaged: boolean;
    integrity: number;
    actualThrust: number;
}
export interface FuelTankInterface {
    getCurrentMass(): number;
    consume(amount: number): boolean;
    getPressure(): number;
}
export interface PowerBudgetInterface {
    requestPower(consumerId: string, amount: number): boolean;
}
export interface ThrustOutput {
    force: Vector3;
    torque: Vector3;
    fuelConsumed: number;
    powerConsumed: number;
    heatGenerated: number;
}
/**
 * Propulsion System - Manages all thrusters
 */
export declare class PropulsionSystem {
    private thrusters;
    private fuelTanks;
    private powerBudget?;
    private readonly G0;
    private readonly GIMBAL_RATE;
    /**
     * Add thruster to system
     */
    addThruster(config: ThrusterConfig): void;
    /**
     * Register fuel tank
     */
    registerFuelTank(tankId: string, tank: FuelTankInterface): void;
    /**
     * Register power budget
     */
    registerPowerBudget(powerBudget: PowerBudgetInterface): void;
    /**
     * Get thruster config
     */
    getThrusterConfig(id: string): ThrusterConfig | undefined;
    /**
     * Get thruster state
     */
    getThrusterState(id: string): ThrusterState | undefined;
    /**
     * Fire thruster at given throttle
     */
    fireThruster(id: string, throttle: number): boolean;
    /**
     * Set gimbal angle (for thrust vectoring)
     */
    setGimbal(id: string, targetAngle: Vector3): boolean;
    /**
     * Get current thrust vector (force and torque)
     */
    getThrustVector(id: string): {
        force: Vector3;
        torque: Vector3;
    };
    /**
     * Update all thrusters
     */
    update(dt: number): ThrustOutput;
    /**
     * Calculate thrust, fuel consumption, power, and heat
     */
    private calculateThrust;
    /**
     * Calculate thrust direction with gimbal
     */
    private calculateThrustDirection;
    /**
     * Update thruster temperature
     */
    private updateThrusterTemperature;
    /**
     * Get total thrust vector for all active thrusters
     */
    getTotalThrust(): {
        force: Vector3;
        torque: Vector3;
    };
    /**
     * Get statistics
     */
    getStatistics(): {
        totalThrusters: number;
        activeThrusters: number;
        damagedThrusters: number;
        totalThrust: number;
    };
}
//# sourceMappingURL=propulsion-system.d.ts.map