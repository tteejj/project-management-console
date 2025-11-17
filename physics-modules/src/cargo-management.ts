/**
 * Cargo/Resource Management Subsystem
 *
 * Simulates:
 * - Cargo bay capacity and loading
 * - Mass distribution and center of mass tracking
 * - Resource inventory (consumables, spare parts, etc.)
 * - Transfer mechanics (loading/unloading)
 * - Cargo securing and damage in high-G maneuvers
 * - Automated handling systems
 * - Inventory tracking and consumption rates
 */

import type { CenterOfMassSystem } from './center-of-mass';

export interface CargoItem {
  id: string;
  type: 'consumable' | 'equipment' | 'spare_part' | 'payload' | 'cargo';
  name: string;
  mass: number; // kg
  volume: number; // m³
  quantity: number;
  secured: boolean;
  location: string; // Bay ID
  condition: number; // 0-1, health/quality
}

export interface CargoBay {
  id: string;
  maxCapacityKg: number;
  maxVolumeM3: number;
  currentMassKg: number;
  currentVolumeM3: number;
  centerOfMass: { x: number; y: number; z: number }; // meters from bay origin
  pressurized: boolean;
  doorOpen: boolean;
  operational: boolean;
}

export interface ResourceInventory {
  food: number; // kg
  water: number; // kg
  oxygen: number; // kg
  spareParts: number; // generic parts count
  medicalSupplies: number; // units
  fuel: number; // kg (for EVA, etc.)
}

export interface CargoManagementConfig {
  bays?: CargoBay[];
  initialInventory?: ResourceInventory;
  autoHandlingEnabled?: boolean;
  powerConsumptionW?: number;
}

export class CargoManagementSystem {
  // Cargo bays
  public bays: Map<string, CargoBay>;
  public items: Map<string, CargoItem>;

  // Resource inventory
  public inventory: ResourceInventory;

  // Systems
  public autoHandlingEnabled: boolean;
  public operational: boolean = true;
  public isPowered: boolean = true;

  // Transfer operations
  public transferInProgress: boolean = false;
  public transferProgress: number = 0; // 0-1
  public transferTimeS: number = 60.0; // Time to transfer cargo

  // Power tracking
  public currentPowerDraw: number = 0; // W
  public basePowerDraw: number = 20; // W (standby)
  public powerConsumptionW: number;

  // Tracking
  public totalMass: number = 0; // kg (all cargo)
  public totalVolume: number = 0; // m³ (all cargo)
  public overallCenterOfMass: { x: number; y: number; z: number } = { x: 0, y: 0, z: 0 };

  // Events
  public events: Array<{ time: number; type: string; data: any }> = [];

  // Center of Mass integration
  private comSystem?: CenterOfMassSystem;

  constructor(config?: CargoManagementConfig) {
    this.bays = new Map();
    this.items = new Map();

    if (config?.bays) {
      config.bays.forEach(bay => this.bays.set(bay.id, bay));
    } else {
      this.createDefaultBays();
    }

    this.inventory = config?.initialInventory || {
      food: 100, // kg
      water: 200, // kg
      oxygen: 150, // kg
      spareParts: 50,
      medicalSupplies: 20,
      fuel: 50 // kg
    };

    this.autoHandlingEnabled = config?.autoHandlingEnabled !== undefined ? config.autoHandlingEnabled : true;
    this.powerConsumptionW = config?.powerConsumptionW || 500.0;
    this.currentPowerDraw = this.basePowerDraw;
  }

  private createDefaultBays(): void {
    const defaultBays: CargoBay[] = [
      {
        id: 'main_bay',
        maxCapacityKg: 10000,
        maxVolumeM3: 50,
        currentMassKg: 0,
        currentVolumeM3: 0,
        centerOfMass: { x: 0, y: 0, z: 0 },
        pressurized: true,
        doorOpen: false,
        operational: true
      },
      {
        id: 'external_bay',
        maxCapacityKg: 5000,
        maxVolumeM3: 25,
        currentMassKg: 0,
        currentVolumeM3: 0,
        centerOfMass: { x: 0, y: 0, z: 0 },
        pressurized: false,
        doorOpen: false,
        operational: true
      }
    ];

    defaultBays.forEach(bay => this.bays.set(bay.id, bay));
  }

  /**
   * Load cargo item into bay
   */
  public loadCargo(item: CargoItem, bayId: string): boolean {
    if (!this.operational || !this.isPowered) {
      this.logEvent('load_failed', { reason: 'system_offline', item: item.name });
      return false;
    }

    const bay = this.bays.get(bayId);
    if (!bay || !bay.operational) {
      this.logEvent('load_failed', { reason: 'bay_unavailable', bayId });
      return false;
    }

    const totalMass = item.mass * item.quantity;
    const totalVolume = item.volume * item.quantity;

    // Check capacity
    if (bay.currentMassKg + totalMass > bay.maxCapacityKg) {
      this.logEvent('load_failed', { reason: 'mass_exceeded', bayId, item: item.name });
      return false;
    }

    if (bay.currentVolumeM3 + totalVolume > bay.maxVolumeM3) {
      this.logEvent('load_failed', { reason: 'volume_exceeded', bayId, item: item.name });
      return false;
    }

    // Load item
    item.location = bayId;
    item.secured = false; // Need to secure after loading
    this.items.set(item.id, item);

    // Update bay
    bay.currentMassKg += totalMass;
    bay.currentVolumeM3 += totalVolume;

    // Recalculate center of mass
    this.updateCenterOfMass();

    // Start transfer operation
    if (this.autoHandlingEnabled) {
      this.transferInProgress = true;
      this.transferProgress = 0;
      this.currentPowerDraw = this.basePowerDraw + this.powerConsumptionW;
    }

    this.logEvent('cargo_loaded', { bayId, item: item.name, mass: totalMass });
    return true;
  }

  /**
   * Unload cargo from bay
   */
  public unloadCargo(itemId: string): boolean {
    if (!this.operational || !this.isPowered) {
      this.logEvent('unload_failed', { reason: 'system_offline', itemId });
      return false;
    }

    const item = this.items.get(itemId);
    if (!item) {
      this.logEvent('unload_failed', { reason: 'item_not_found', itemId });
      return false;
    }

    const bay = this.bays.get(item.location);
    if (!bay) {
      this.logEvent('unload_failed', { reason: 'bay_not_found', bayId: item.location });
      return false;
    }

    if (!bay.doorOpen) {
      this.logEvent('unload_failed', { reason: 'bay_door_closed', bayId: item.location });
      return false;
    }

    const totalMass = item.mass * item.quantity;
    const totalVolume = item.volume * item.quantity;

    // Remove item
    this.items.delete(itemId);
    bay.currentMassKg -= totalMass;
    bay.currentVolumeM3 -= totalVolume;

    this.updateCenterOfMass();

    this.logEvent('cargo_unloaded', { bayId: item.location, item: item.name, mass: totalMass });
    return true;
  }

  /**
   * Secure/unsecure cargo
   */
  public secureCargo(itemId: string, secured: boolean): boolean {
    const item = this.items.get(itemId);
    if (!item) return false;

    item.secured = secured;
    this.logEvent('cargo_secured', { itemId, secured });
    return true;
  }

  /**
   * Open/close bay doors
   */
  public setBayDoor(bayId: string, open: boolean): boolean {
    if (!this.operational || !this.isPowered) {
      this.logEvent('door_operation_failed', { reason: 'system_offline', bayId });
      return false;
    }

    const bay = this.bays.get(bayId);
    if (!bay || !bay.operational) {
      this.logEvent('door_operation_failed', { reason: 'bay_unavailable', bayId });
      return false;
    }

    bay.doorOpen = open;
    this.logEvent('bay_door_operated', { bayId, open });
    return true;
  }

  /**
   * Consume resources from inventory
   */
  public consumeResource(resourceType: keyof ResourceInventory, amount: number): boolean {
    if (this.inventory[resourceType] < amount) {
      this.logEvent('consumption_failed', { resourceType, amount, available: this.inventory[resourceType] });
      return false;
    }

    this.inventory[resourceType] -= amount;
    this.logEvent('resource_consumed', { resourceType, amount, remaining: this.inventory[resourceType] });

    // Alert if running low
    if (this.inventory[resourceType] < 10) {
      this.logEvent('resource_low', { resourceType, remaining: this.inventory[resourceType] });
    }

    return true;
  }

  /**
   * Resupply resources
   */
  public resupplyResource(resourceType: keyof ResourceInventory, amount: number): void {
    this.inventory[resourceType] += amount;
    this.logEvent('resource_resupplied', { resourceType, amount, total: this.inventory[resourceType] });
  }

  /**
   * Register with spacecraft CoM system
   */
  public registerCoMSystem(comSystem: CenterOfMassSystem): void {
    this.comSystem = comSystem;
  }

  /**
   * Update center of mass calculations
   * Also updates the spacecraft's CoM system if registered
   */
  private updateCenterOfMass(): void {
    let totalMass = 0;
    let comX = 0;
    let comY = 0;
    let comZ = 0;

    this.bays.forEach(bay => {
      totalMass += bay.currentMassKg;
      // Simplified - assume each bay has a fixed position
      // In reality, would need bay positions and individual item positions
      comX += bay.centerOfMass.x * bay.currentMassKg;
      comY += bay.centerOfMass.y * bay.currentMassKg;
      comZ += bay.centerOfMass.z * bay.currentMassKg;
    });

    if (totalMass > 0) {
      this.overallCenterOfMass = {
        x: comX / totalMass,
        y: comY / totalMass,
        z: comZ / totalMass
      };
    }

    this.totalMass = totalMass;

    // Update spacecraft CoM system if registered
    if (this.comSystem) {
      this.comSystem.updateMass('cargo', this.totalMass);
      // Also update position if cargo CoM has shifted
      if (this.totalMass > 0) {
        this.comSystem.updatePosition('cargo', this.overallCenterOfMass);
      }
    }
  }

  /**
   * Check for cargo damage during high-G maneuvers
   */
  public checkCargoIntegrity(gForce: number): void {
    this.items.forEach(item => {
      if (!item.secured && gForce > 2.0) {
        // Unsecured cargo takes damage in high-G
        const damageAmount = (gForce - 2.0) * 0.1;
        item.condition = Math.max(0, item.condition - damageAmount);

        if (item.condition < 0.5) {
          this.logEvent('cargo_damaged', {
            itemId: item.id,
            name: item.name,
            condition: item.condition,
            gForce
          });
        }
      }
    });
  }

  /**
   * Get cargo manifest
   */
  public getManifest(): any[] {
    const manifest: any[] = [];
    this.items.forEach(item => {
      manifest.push({
        id: item.id,
        name: item.name,
        type: item.type,
        mass: item.mass * item.quantity,
        volume: item.volume * item.quantity,
        quantity: item.quantity,
        location: item.location,
        secured: item.secured,
        condition: item.condition
      });
    });
    return manifest;
  }

  /**
   * Update cargo system
   */
  public update(dt: number): void {
    if (!this.isPowered) {
      this.operational = false;
      this.currentPowerDraw = 0;
      return;
    }

    if (!this.operational) return;

    // Handle transfer operations
    if (this.transferInProgress) {
      this.transferProgress += dt / this.transferTimeS;
      if (this.transferProgress >= 1.0) {
        this.transferProgress = 0;
        this.transferInProgress = false;
        this.currentPowerDraw = this.basePowerDraw;

        // Auto-secure cargo after transfer completes
        this.items.forEach(item => {
          if (!item.secured) {
            item.secured = true;
          }
        });

        this.logEvent('transfer_complete', {});
      }
    }
  }

  /**
   * Apply damage
   */
  public applyDamage(severity: number, bayId?: string): void {
    if (bayId) {
      const bay = this.bays.get(bayId);
      if (bay) {
        if (severity > 0.6) {
          bay.operational = false;
          bay.doorOpen = false; // Damage seals door
          this.logEvent('bay_destroyed', { bayId, severity });
        } else {
          // Damage some cargo
          this.items.forEach(item => {
            if (item.location === bayId) {
              item.condition *= (1 - severity * 0.5);
            }
          });
          this.logEvent('bay_damaged', { bayId, severity });
        }
      }
    } else {
      if (severity > 0.7) {
        this.operational = false;
        this.logEvent('cargo_system_destroyed', { severity });
      }
    }
  }

  /**
   * Repair system
   */
  public repair(bayId?: string): void {
    if (bayId) {
      const bay = this.bays.get(bayId);
      if (bay) {
        bay.operational = true;
        this.logEvent('bay_repaired', { bayId });
      }
    } else {
      this.operational = true;
      this.bays.forEach(bay => {
        bay.operational = true;
      });
      this.logEvent('cargo_system_repaired', {});
    }
  }

  /**
   * Set power state
   */
  public setPower(powered: boolean): void {
    this.isPowered = powered;
    if (!powered) {
      this.currentPowerDraw = 0;
      this.transferInProgress = false;
    } else {
      this.currentPowerDraw = this.basePowerDraw;
    }
  }

  public getState() {
    const baysArray: any[] = [];
    this.bays.forEach((bay, id) => {
      baysArray.push({ ...bay });
    });

    return {
      operational: this.operational,
      isPowered: this.isPowered,
      bays: baysArray,
      inventory: { ...this.inventory },
      manifest: this.getManifest(),
      totalMass: this.totalMass,
      totalVolume: this.totalVolume,
      centerOfMass: { ...this.overallCenterOfMass },
      transferInProgress: this.transferInProgress,
      transferProgress: this.transferProgress,
      autoHandlingEnabled: this.autoHandlingEnabled,
      powerDraw: this.currentPowerDraw
    };
  }

  private logEvent(type: string, data: any): void {
    this.events.push({ time: Date.now(), type, data });
  }
}
