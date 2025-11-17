/**
 * Damage Control System
 *
 * Crew-based repair mechanics for hull breaches and system damage
 */

import { CrewMember } from './life-support';
import { ShipSystem } from './system-damage';
import { HullStructure, Breach } from './hull-damage';

export enum RepairTaskType {
  BREACH = 'breach',
  SYSTEM = 'system',
  STRUCTURAL = 'structural'
}

export enum RepairPriority {
  CRITICAL = 0,
  HIGH = 1,
  MEDIUM = 2,
  LOW = 3
}

export interface RepairTask {
  id: string;
  type: RepairTaskType;
  targetId: string;           // Breach ID, System ID, or Compartment ID
  compartmentId: string;
  priority: RepairPriority;
  progress: number;           // 0-1
  timeRequired: number;       // seconds
  assignedCrewId: string | null;
}

export interface RepairCrew {
  crewMember: CrewMember;
  repairSkill: number;        // 0-1 (multiplier for repair speed)
  efficiency: number;         // 0-1 (affected by fatigue, health)
  currentTask: RepairTask | null;
  fatigueLevel: number;       // 0-1 (0 = fresh, 1 = exhausted)
}

export interface RepairConfig {
  repairCrews: RepairCrew[];
  hull: HullStructure;
  systems?: ShipSystem[];
}

export interface RepairStatistics {
  tasksCompleted: number;
  totalRepairTime: number;    // seconds
  breachesSealed: number;
  systemsRepaired: number;
}

/**
 * Damage Control System
 */
export class DamageControlSystem {
  private repairCrews: Map<string, RepairCrew> = new Map();
  private tasks: Map<string, RepairTask> = new Map();
  private hull: HullStructure;
  private systems: Map<string, ShipSystem> = new Map();

  // Statistics
  private tasksCompleted: number = 0;
  private totalRepairTime: number = 0;
  private breachesSealed: number = 0;
  private systemsRepaired: number = 0;

  // Constants
  private readonly FATIGUE_RATE = 0.001;          // per second while working
  private readonly RECOVERY_RATE = 0.005;         // per second while resting
  private readonly BASE_BREACH_REPAIR_TIME = 100; // seconds for 0.01 m² breach
  private readonly BASE_SYSTEM_REPAIR_RATE = 0.005; // integrity per second
  private readonly BASE_STRUCTURAL_REPAIR_RATE = 0.002; // integrity per second

  constructor(config: RepairConfig) {
    for (const crew of config.repairCrews) {
      this.repairCrews.set(crew.crewMember.id, crew);
    }
    this.hull = config.hull;
    if (config.systems) {
      for (const system of config.systems) {
        this.systems.set(system.id, system);
      }
    }
  }

  /**
   * Update damage control system
   */
  update(dt: number): void {
    // PHASE 1: Update crew efficiency based on health and fatigue
    for (const crew of this.repairCrews.values()) {
      this.updateCrewEfficiency(crew);
    }

    // PHASE 2: Process repair tasks
    for (const crew of this.repairCrews.values()) {
      if (crew.currentTask) {
        this.processRepairTask(crew, dt);
      } else {
        // Crew resting - recover from fatigue
        crew.fatigueLevel = Math.max(0, crew.fatigueLevel - this.RECOVERY_RATE * dt);
      }
    }

    // PHASE 3: Remove completed tasks
    for (const [id, task] of this.tasks.entries()) {
      if (task.progress >= 1.0) {
        this.completeTask(task);
        this.tasks.delete(id);
      }
    }
  }

  /**
   * Update crew efficiency
   */
  private updateCrewEfficiency(crew: RepairCrew): void {
    // Base efficiency from health
    let efficiency = crew.crewMember.health;

    // Reduce by fatigue
    efficiency *= (1 - crew.fatigueLevel * 0.5); // Max 50% penalty at full fatigue

    // Reduce if hypoxic
    efficiency *= crew.crewMember.oxygenLevel;

    crew.efficiency = Math.max(0, Math.min(1, efficiency));
  }

  /**
   * Process repair task
   */
  private processRepairTask(crew: RepairCrew, dt: number): void {
    if (!crew.currentTask) return;

    const task = crew.currentTask;

    // Calculate repair rate
    const baseRate = 1 / task.timeRequired;  // Progress per second
    const effectiveRate = baseRate * crew.repairSkill * crew.efficiency;

    // Update progress
    task.progress = Math.min(1.0, task.progress + effectiveRate * dt);

    // Increase fatigue
    crew.fatigueLevel = Math.min(1.0, crew.fatigueLevel + this.FATIGUE_RATE * dt);

    // Track repair time
    this.totalRepairTime += dt;

    // Apply partial repairs for ongoing work
    if (task.type === RepairTaskType.SYSTEM) {
      const system = this.systems.get(task.targetId);
      if (system) {
        const repairAmount = this.BASE_SYSTEM_REPAIR_RATE * crew.repairSkill * crew.efficiency * dt;
        system.integrity = Math.min(1.0, system.integrity + repairAmount);
      }
    } else if (task.type === RepairTaskType.STRUCTURAL) {
      const compartment = this.hull.getCompartment(task.targetId);
      if (compartment) {
        const repairAmount = this.BASE_STRUCTURAL_REPAIR_RATE * crew.repairSkill * crew.efficiency * dt;
        compartment.structuralIntegrity = Math.min(1.0, compartment.structuralIntegrity + repairAmount);
      }
    }
  }

  /**
   * Complete repair task
   */
  private completeTask(task: RepairTask): void {
    this.tasksCompleted++;

    // Apply completion effects
    if (task.type === RepairTaskType.BREACH) {
      const breach = this.findBreach(task.targetId);
      if (breach) {
        breach.sealed = true;
        this.breachesSealed++;
      }
    } else if (task.type === RepairTaskType.SYSTEM) {
      this.systemsRepaired++;
    }

    // Clear crew assignment
    for (const crew of this.repairCrews.values()) {
      if (crew.currentTask?.id === task.id) {
        crew.currentTask = null;
      }
    }
  }

  /**
   * Find breach by ID
   */
  private findBreach(breachId: string): Breach | null {
    for (const compartment of this.hull.getAllCompartments()) {
      const breach = compartment.breaches.find(b => b.id === breachId);
      if (breach) return breach;
    }
    return null;
  }

  /**
   * Assign repair task to crew
   */
  assignRepairTask(crewId: string, task: RepairTask): void {
    const crew = this.repairCrews.get(crewId);
    if (!crew) return;

    // Check if crew is in same compartment as task
    if (crew.crewMember.location !== task.compartmentId) {
      return;  // Can't repair from different compartment
    }

    task.assignedCrewId = crewId;
    crew.currentTask = task;
    this.tasks.set(task.id, task);
  }

  /**
   * Auto-assign tasks to available crew
   */
  autoAssignTasks(): void {
    // Find available crew
    const availableCrew = Array.from(this.repairCrews.values())
      .filter(c => c.currentTask === null);

    if (availableCrew.length === 0) return;

    // Generate tasks from hull damage
    const pendingTasks = this.generateTasks();

    // Sort by priority
    pendingTasks.sort((a, b) => a.priority - b.priority);

    // Assign tasks to crew
    for (const task of pendingTasks) {
      // Find crew in same compartment
      const crew = availableCrew.find(c =>
        c.crewMember.location === task.compartmentId && c.currentTask === null
      );

      if (crew) {
        this.assignRepairTask(crew.crewMember.id, task);
      }
    }
  }

  /**
   * Generate repair tasks from current damage
   */
  private generateTasks(): RepairTask[] {
    const tasks: RepairTask[] = [];

    // Breach tasks
    for (const compartment of this.hull.getAllCompartments()) {
      for (const breach of compartment.breaches) {
        if (!breach.sealed && !this.isTaskActive(breach.id)) {
          const priority = breach.area > 0.05 ? RepairPriority.CRITICAL : RepairPriority.HIGH;
          const timeRequired = this.BASE_BREACH_REPAIR_TIME * Math.sqrt(breach.area / 0.01);

          tasks.push({
            id: `breach-${breach.id}`,
            type: RepairTaskType.BREACH,
            targetId: breach.id,
            compartmentId: compartment.id,
            priority,
            progress: 0,
            timeRequired,
            assignedCrewId: null
          });
        }
      }
    }

    return tasks;
  }

  /**
   * Check if task is already active
   */
  private isTaskActive(targetId: string): boolean {
    for (const crew of this.repairCrews.values()) {
      if (crew.currentTask?.targetId === targetId) {
        return true;
      }
    }
    return false;
  }

  /**
   * Get statistics
   */
  getStatistics(): RepairStatistics {
    return {
      tasksCompleted: this.tasksCompleted,
      totalRepairTime: this.totalRepairTime,
      breachesSealed: this.breachesSealed,
      systemsRepaired: this.systemsRepaired
    };
  }

  /**
   * Get crew by ID
   */
  getCrew(id: string): RepairCrew | undefined {
    return this.repairCrews.get(id);
  }

  /**
   * Add repair crew
   */
  addRepairCrew(crew: RepairCrew): void {
    this.repairCrews.set(crew.crewMember.id, crew);
  }

  /**
   * Add system for repair tracking
   */
  addSystem(system: ShipSystem): void {
    this.systems.set(system.id, system);
  }
}
