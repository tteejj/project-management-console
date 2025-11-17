/**
 * Damage Control System
 *
 * Crew-based repair mechanics for hull breaches and system damage
 */
import { CrewMember } from './life-support';
import { ShipSystem } from './system-damage';
import { HullStructure } from './hull-damage';
export declare enum RepairTaskType {
    BREACH = "breach",
    SYSTEM = "system",
    STRUCTURAL = "structural"
}
export declare enum RepairPriority {
    CRITICAL = 0,
    HIGH = 1,
    MEDIUM = 2,
    LOW = 3
}
export interface RepairTask {
    id: string;
    type: RepairTaskType;
    targetId: string;
    compartmentId: string;
    priority: RepairPriority;
    progress: number;
    timeRequired: number;
    assignedCrewId: string | null;
}
export interface RepairCrew {
    crewMember: CrewMember;
    repairSkill: number;
    efficiency: number;
    currentTask: RepairTask | null;
    fatigueLevel: number;
}
export interface RepairConfig {
    repairCrews: RepairCrew[];
    hull: HullStructure;
    systems?: ShipSystem[];
}
export interface RepairStatistics {
    tasksCompleted: number;
    totalRepairTime: number;
    breachesSealed: number;
    systemsRepaired: number;
}
/**
 * Damage Control System
 */
export declare class DamageControlSystem {
    private repairCrews;
    private tasks;
    private hull;
    private systems;
    private tasksCompleted;
    private totalRepairTime;
    private breachesSealed;
    private systemsRepaired;
    private readonly FATIGUE_RATE;
    private readonly RECOVERY_RATE;
    private readonly BASE_BREACH_REPAIR_TIME;
    private readonly BASE_SYSTEM_REPAIR_RATE;
    private readonly BASE_STRUCTURAL_REPAIR_RATE;
    constructor(config: RepairConfig);
    /**
     * Update damage control system
     */
    update(dt: number): void;
    /**
     * Update crew efficiency
     */
    private updateCrewEfficiency;
    /**
     * Process repair task
     */
    private processRepairTask;
    /**
     * Complete repair task
     */
    private completeTask;
    /**
     * Find breach by ID
     */
    private findBreach;
    /**
     * Assign repair task to crew
     */
    assignRepairTask(crewId: string, task: RepairTask): void;
    /**
     * Auto-assign tasks to available crew
     */
    autoAssignTasks(): void;
    /**
     * Generate repair tasks from current damage
     */
    private generateTasks;
    /**
     * Check if task is already active
     */
    private isTaskActive;
    /**
     * Get statistics
     */
    getStatistics(): RepairStatistics;
    /**
     * Get crew by ID
     */
    getCrew(id: string): RepairCrew | undefined;
    /**
     * Add repair crew
     */
    addRepairCrew(crew: RepairCrew): void;
    /**
     * Add system for repair tracking
     */
    addSystem(system: ShipSystem): void;
}
//# sourceMappingURL=damage-control.d.ts.map