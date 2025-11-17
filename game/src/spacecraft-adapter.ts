/**
 * Spacecraft Adapter
 * Bridges the UI to the physics simulation
 */

// @ts-ignore - Import from parent directory physics-modules
import { Spacecraft } from '../../physics-modules/src/spacecraft';

export class SpacecraftAdapter {
    public spacecraft: Spacecraft;
    private updateCallbacks: Array<() => void> = [];

    constructor() {
        // Initialize spacecraft at 15km altitude above moon
        this.spacecraft = new Spacecraft({
            shipPhysicsConfig: {
                initialPosition: { x: 0, y: 0, z: 1737400 + 15000 }, // Moon radius + 15km
                initialVelocity: { x: 0, y: 0, z: -40 } // Descending at 40 m/s
            }
        });

        // Start essential systems
        this.initializeSystems();
    }

    private initializeSystems(): void {
        // Start reactor (takes 30 seconds to come online)
        this.spacecraft.startReactor();

        // Start coolant pumps
        this.spacecraft.startCoolantPump(0);
        this.spacecraft.startCoolantPump(1);

        console.log('Spacecraft systems initializing...');
    }

    /**
     * Update physics simulation
     */
    update(deltaTime: number): void {
        this.spacecraft.update(deltaTime);

        // Notify UI of state changes
        this.updateCallbacks.forEach(cb => cb());
    }

    /**
     * Register callback for state updates
     */
    onUpdate(callback: () => void): void {
        this.updateCallbacks.push(callback);
    }

    // ========== HELM / PROPULSION CONTROLS ==========

    setFuelValve(open: boolean): void {
        if (open) {
            this.spacecraft.openMainEngineFuelValve();
        } else {
            this.spacecraft.closeMainEngineFuelValve();
        }
    }

    armIgnition(): void {
        this.spacecraft.armMainEngine();
    }

    fireEngine(): void {
        this.spacecraft.igniteMainEngine();
    }

    cutoffEngine(): void {
        this.spacecraft.shutdownMainEngine();
    }

    setThrottle(percent: number): void {
        this.spacecraft.setMainEngineThrottle(percent / 100);
    }

    setGimbal(x: number, y: number): void {
        // Convert degrees to radians
        const xRad = (x * Math.PI) / 180;
        const yRad = (y * Math.PI) / 180;
        this.spacecraft.setMainEngineGimbal(xRad, yRad);
    }

    fireRCS(thrusterIndex: number, fire: boolean): void {
        // Map UI thruster indices to RCS system
        // 0-11 maps to bow/mid/stern port/starboard/dorsal/ventral
        if (fire) {
            this.spacecraft.fireRCSThruster(thrusterIndex);
        } else {
            this.spacecraft.stopRCSThruster(thrusterIndex);
        }
    }

    // ========== ENGINEERING CONTROLS ==========

    startReactor(): void {
        this.spacecraft.startReactor();
    }

    scramReactor(): void {
        this.spacecraft.scramReactor();
    }

    setReactorThrottle(percent: number): void {
        this.spacecraft.setReactorPower(percent / 100);
    }

    toggleBreaker(index: number, state: boolean): void {
        this.spacecraft.setCircuitBreaker(index, state);
    }

    toggleRadiators(deploy: boolean): void {
        if (deploy) {
            this.spacecraft.deployRadiators();
        } else {
            this.spacecraft.retractRadiators();
        }
    }

    toggleCoolantPump(index: number, on: boolean): void {
        if (on) {
            this.spacecraft.startCoolantPump(index);
        } else {
            this.spacecraft.stopCoolantPump(index);
        }
    }

    // ========== NAVIGATION CONTROLS ==========

    setRadarActive(active: boolean): void {
        this.spacecraft.setRadarActive(active);
    }

    setRadarRange(rangeKm: number): void {
        this.spacecraft.setRadarRange(rangeKm * 1000); // Convert to meters
    }

    // ========== TELEMETRY GETTERS ==========

    getState(): any {
        return this.spacecraft.getState();
    }

    getNavigationTelemetry(): any {
        return this.spacecraft.getNavigationTelemetry();
    }

    getMainEngineState(): any {
        return this.spacecraft.mainEngine.getState();
    }

    getElectricalState(): any {
        return this.spacecraft.getState().electrical;
    }

    getThermalState(): any {
        return this.spacecraft.getState().thermal;
    }

    getFuelState(): any {
        return this.spacecraft.getState().fuel;
    }
}
