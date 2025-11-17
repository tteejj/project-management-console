/**
 * Center of Mass Tracking System
 *
 * Tracks all mass components and calculates:
 * - Total mass
 * - Center of mass position
 * - Moment of inertia tensor
 * - Mass distribution
 *
 * This is critical for realistic flight dynamics, RCS compensation,
 * and proper handling as fuel/cargo/ammunition mass changes.
 */

export interface MassComponent {
  id: string;
  name: string;
  mass: number; // kg
  position: { x: number; y: number; z: number }; // meters from origin
  fixed: boolean; // true for structural components
}

export class CenterOfMassSystem {
  private components: Map<string, MassComponent> = new Map();

  // Cached calculations (updated when mass changes)
  private totalMass: number = 0;
  private centerOfMass: { x: number; y: number; z: number } = { x: 0, y: 0, z: 0 };
  private momentOfInertia: {
    Ixx: number; Iyy: number; Izz: number;
    Ixy: number; Ixz: number; Iyz: number;
  } = { Ixx: 0, Iyy: 0, Izz: 0, Ixy: 0, Ixz: 0, Iyz: 0 };

  private dirty: boolean = true; // Recalculate on next access

  /**
   * Register a mass component
   */
  public registerComponent(component: MassComponent): void {
    this.components.set(component.id, component);
    this.dirty = true;
  }

  /**
   * Update mass of a component (e.g., fuel consumption)
   */
  public updateMass(id: string, newMass: number): void {
    const component = this.components.get(id);
    if (component) {
      component.mass = Math.max(0, newMass); // Prevent negative mass
      this.dirty = true;
    }
  }

  /**
   * Update position of a component (e.g., cargo movement)
   */
  public updatePosition(id: string, position: { x: number; y: number; z: number }): void {
    const component = this.components.get(id);
    if (component && !component.fixed) {
      component.position = { ...position };
      this.dirty = true;
    }
  }

  /**
   * Remove a component (e.g., ammunition fired, cargo jettisoned)
   */
  public removeComponent(id: string): void {
    this.components.delete(id);
    this.dirty = true;
  }

  /**
   * Calculate center of mass: CoM = Σ(m_i * r_i) / Σ(m_i)
   * And moment of inertia tensor
   */
  private calculate(): void {
    if (!this.dirty) return;

    let totalMass = 0;
    let sumMx = 0, sumMy = 0, sumMz = 0;

    // Calculate total mass and weighted position sum
    for (const component of this.components.values()) {
      totalMass += component.mass;
      sumMx += component.mass * component.position.x;
      sumMy += component.mass * component.position.y;
      sumMz += component.mass * component.position.z;
    }

    this.totalMass = totalMass;

    if (totalMass > 0) {
      this.centerOfMass = {
        x: sumMx / totalMass,
        y: sumMy / totalMass,
        z: sumMz / totalMass
      };
    } else {
      this.centerOfMass = { x: 0, y: 0, z: 0 };
    }

    // Calculate moment of inertia tensor relative to CoM
    // Using parallel axis theorem:
    // I_xx = Σ m_i * (y_i² + z_i²) for axis along x
    // I_xy = -Σ m_i * x_i * y_i (products of inertia, negative)
    let Ixx = 0, Iyy = 0, Izz = 0;
    let Ixy = 0, Ixz = 0, Iyz = 0;

    for (const component of this.components.values()) {
      // Position relative to CoM
      const dx = component.position.x - this.centerOfMass.x;
      const dy = component.position.y - this.centerOfMass.y;
      const dz = component.position.z - this.centerOfMass.z;

      const m = component.mass;

      // Diagonal terms (moments of inertia)
      Ixx += m * (dy * dy + dz * dz);
      Iyy += m * (dx * dx + dz * dz);
      Izz += m * (dx * dx + dy * dy);

      // Off-diagonal terms (products of inertia)
      // Note: These are negative in the inertia tensor
      Ixy -= m * dx * dy;
      Ixz -= m * dx * dz;
      Iyz -= m * dy * dz;
    }

    this.momentOfInertia = { Ixx, Iyy, Izz, Ixy, Ixz, Iyz };
    this.dirty = false;
  }

  /**
   * Get current center of mass
   */
  public getCoM(): { x: number; y: number; z: number } {
    this.calculate();
    return { ...this.centerOfMass };
  }

  /**
   * Get total mass
   */
  public getTotalMass(): number {
    this.calculate();
    return this.totalMass;
  }

  /**
   * Get moment of inertia tensor
   * Returns 3x3 tensor as 6 components (symmetric matrix)
   */
  public getMomentOfInertia(): {
    Ixx: number; Iyy: number; Izz: number;
    Ixy: number; Ixz: number; Iyz: number;
  } {
    this.calculate();
    return { ...this.momentOfInertia };
  }

  /**
   * Get diagonal inertia components (simplified version)
   * For systems that don't support full tensor
   */
  public getInertiaVector(): { x: number; y: number; z: number } {
    this.calculate();
    return {
      x: this.momentOfInertia.Ixx,
      y: this.momentOfInertia.Iyy,
      z: this.momentOfInertia.Izz
    };
  }

  /**
   * Get offset from origin to CoM
   * Used by RCS to compensate thrust and by main engine gimbal
   */
  public getCoMOffset(): { x: number; y: number; z: number } {
    this.calculate();
    return { ...this.centerOfMass };
  }

  /**
   * Get mass component by ID
   */
  public getComponent(id: string): MassComponent | undefined {
    return this.components.get(id);
  }

  /**
   * Get all components
   */
  public getAllComponents(): MassComponent[] {
    return Array.from(this.components.values());
  }

  /**
   * Calculate torque produced by a force applied at a position
   * relative to the current CoM
   *
   * Torque = r × F (cross product)
   * where r is position relative to CoM
   */
  public calculateTorque(
    forcePosition: { x: number; y: number; z: number },
    force: { x: number; y: number; z: number }
  ): { x: number; y: number; z: number } {
    this.calculate();

    // Vector from CoM to force application point
    const r = {
      x: forcePosition.x - this.centerOfMass.x,
      y: forcePosition.y - this.centerOfMass.y,
      z: forcePosition.z - this.centerOfMass.z
    };

    // Cross product: r × F
    return {
      x: r.y * force.z - r.z * force.y,
      y: r.z * force.x - r.x * force.z,
      z: r.x * force.y - r.y * force.x
    };
  }

  /**
   * Get distribution statistics
   */
  public getDistribution(): {
    massRange: { min: number; max: number };
    spreadX: number;
    spreadY: number;
    spreadZ: number;
  } {
    let minMass = Infinity;
    let maxMass = -Infinity;
    let minX = Infinity, maxX = -Infinity;
    let minY = Infinity, maxY = -Infinity;
    let minZ = Infinity, maxZ = -Infinity;

    for (const component of this.components.values()) {
      if (component.mass < minMass) minMass = component.mass;
      if (component.mass > maxMass) maxMass = component.mass;

      if (component.position.x < minX) minX = component.position.x;
      if (component.position.x > maxX) maxX = component.position.x;
      if (component.position.y < minY) minY = component.position.y;
      if (component.position.y > maxY) maxY = component.position.y;
      if (component.position.z < minZ) minZ = component.position.z;
      if (component.position.z > maxZ) maxZ = component.position.z;
    }

    return {
      massRange: { min: minMass, max: maxMass },
      spreadX: maxX - minX,
      spreadY: maxY - minY,
      spreadZ: maxZ - minZ
    };
  }

  /**
   * Get full state for debugging and telemetry
   */
  public getState() {
    this.calculate();
    return {
      totalMass: this.totalMass,
      centerOfMass: { ...this.centerOfMass },
      momentOfInertia: { ...this.momentOfInertia },
      componentCount: this.components.size,
      components: Array.from(this.components.values()).map(c => ({
        id: c.id,
        name: c.name,
        mass: c.mass,
        position: { ...c.position },
        fixed: c.fixed,
        distanceFromCoM: Math.sqrt(
          Math.pow(c.position.x - this.centerOfMass.x, 2) +
          Math.pow(c.position.y - this.centerOfMass.y, 2) +
          Math.pow(c.position.z - this.centerOfMass.z, 2)
        )
      })),
      distribution: this.getDistribution()
    };
  }

  /**
   * Reset all components (for testing or reinitialization)
   */
  public reset(): void {
    this.components.clear();
    this.dirty = true;
  }
}
