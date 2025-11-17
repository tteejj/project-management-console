/**
 * RCS (Reaction Control System) Physics Module
 *
 * Simulates:
 * - 12 individual cold-gas thrusters for attitude control
 * - 4 control groups: pitch, yaw, roll, translation
 * - Thruster coupling and moment arm calculations
 * - Individual thruster on/off control
 * - Fuel consumption from compressed gas bottles
 * - Thrust and torque generation
 * - Minimum pulse width and duty cycle limits
 */
export interface Thruster {
    id: number;
    name: string;
    position: {
        x: number;
        y: number;
        z: number;
    };
    direction: {
        x: number;
        y: number;
        z: number;
    };
    thrustN: number;
    active: boolean;
    totalFiredSeconds: number;
    pulseCount: number;
}
export interface ThrusterGroup {
    name: string;
    thrusterIds: number[];
    active: boolean;
}
export interface RCSConfig {
    thrusterThrustN?: number;
    minPulseWidthS?: number;
    maxDutyCycle?: number;
}
export declare class RCSSystem {
    thrusters: Thruster[];
    groups: Map<string, ThrusterGroup>;
    thrusterThrustN: number;
    minPulseWidthS: number;
    maxDutyCycle: number;
    totalFuelConsumedKg: number;
    events: Array<{
        time: number;
        type: string;
        data: any;
    }>;
    private readonly SPECIFIC_IMPULSE_SEC;
    private readonly G0;
    constructor(config?: RCSConfig);
    /**
     * Create 12 thrusters in standard configuration
     * 4 clusters of 3 thrusters each (forward, aft, left, right)
     */
    private createDefaultThrusters;
    /**
     * Create control groups
     */
    private createDefaultGroups;
    /**
     * Main update loop
     */
    update(dt: number, simulationTime: number): void;
    /**
     * Activate a control group
     */
    activateGroup(groupName: string): boolean;
    /**
     * Deactivate a control group
     */
    deactivateGroup(groupName: string): void;
    /**
     * Activate individual thruster
     */
    activateThruster(thrusterId: number): boolean;
    /**
     * Deactivate individual thruster
     */
    deactivateThruster(thrusterId: number): void;
    /**
     * Fire a pulse (minimum pulse width)
     */
    firePulse(groupName: string): void;
    /**
     * Calculate total thrust force vector
     * Returns net force in (x, y, z)
     */
    getTotalThrustVector(): {
        x: number;
        y: number;
        z: number;
    };
    /**
     * Calculate total torque vector
     * τ = r × F
     * Returns net torque in (x, y, z) in N·m
     */
    getTotalTorque(): {
        x: number;
        y: number;
        z: number;
    };
    /**
     * Calculate fuel consumption
     * ṁ = F / (Isp * g0)
     */
    consumeFuel(dt: number, availableFuelKg: number): number;
    /**
     * Get total thrust from active thrusters
     */
    getTotalActiveThrust(): number;
    /**
     * Get number of active thrusters
     */
    getActiveThrusterCount(): number;
    /**
     * Get thruster by ID
     */
    getThruster(id: number): Thruster | undefined;
    /**
     * Get group by name
     */
    getGroup(name: string): ThrusterGroup | undefined;
    /**
     * Get current state
     */
    getState(): {
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
    /**
     * Log an event
     */
    private logEvent;
    /**
     * Get all events
     */
    getEvents(): {
        time: number;
        type: string;
        data: any;
    }[];
    /**
     * Clear events
     */
    clearEvents(): void;
}
//# sourceMappingURL=rcs-system.d.ts.map