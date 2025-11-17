/**
 * TrafficControl.ts
 * Manages ship traffic, routing, collision avoidance, and space lanes
 */

import { Vector3 } from './CelestialBody';
import { SpaceStation } from './StationGenerator';
import { NPCShip } from './NPCShipAI';

export interface SpaceLane {
  id: string;
  from: Vector3;
  to: Vector3;
  waypoints: Vector3[];
  width: number;              // meters
  speedLimit: number;         // m/s
  traffic: number;            // current ship count
  maxTraffic: number;         // capacity
  hazardLevel: number;        // 0-1
}

export interface TrafficZone {
  id: string;
  center: Vector3;
  radius: number;
  zoneType: 'APPROACH' | 'DEPARTURE' | 'HOLDING' | 'RESTRICTED' | 'PATROL';
  speedLimit: number;
  priority: number;           // Higher priority zones take precedence
}

export interface DockingQueue {
  stationId: string;
  queue: string[];            // ship IDs
  maxSlots: number;
  activelyDocking: Set<string>;
}

export interface TrafficWarning {
  severity: 'INFO' | 'CAUTION' | 'WARNING' | 'CRITICAL';
  message: string;
  affectedShips: string[];
  position: Vector3;
  timestamp: number;
}

export interface CollisionPrediction {
  ship1: string;
  ship2: string;
  timeToCollision: number;    // seconds
  collisionPoint: Vector3;
  relativeVelocity: number;   // m/s
  severity: number;           // 0-1
}

/**
 * Traffic Control System
 */
export class TrafficControl {
  private lanes: Map<string, SpaceLane> = new Map();
  private zones: Map<string, TrafficZone> = new Map();
  private dockingQueues: Map<string, DockingQueue> = new Map();
  private warnings: TrafficWarning[] = [];
  private collisionPredictions: CollisionPrediction[] = [];

  /**
   * Initialize traffic control for a star system
   */
  initializeSystem(stations: SpaceStation[]): void {
    // Create space lanes between major stations
    for (let i = 0; i < stations.length; i++) {
      for (let j = i + 1; j < stations.length; j++) {
        this.createSpaceLane(
          stations[i].position,
          stations[j].position,
          `lane_${i}_${j}`
        );
      }
    }

    // Create traffic zones around each station
    for (const station of stations) {
      this.createStationZones(station);
      this.initializeDockingQueue(station);
    }
  }

  /**
   * Create a space lane between two points
   */
  private createSpaceLane(from: Vector3, to: Vector3, id: string): SpaceLane {
    const distance = this.distance(from, to);
    const numWaypoints = Math.max(2, Math.floor(distance / 1e7)); // Waypoint every 10,000 km

    const waypoints: Vector3[] = [];
    for (let i = 0; i <= numWaypoints; i++) {
      const t = i / numWaypoints;
      waypoints.push({
        x: from.x + (to.x - from.x) * t,
        y: from.y + (to.y - from.y) * t,
        z: from.z + (to.z - from.z) * t
      });
    }

    const lane: SpaceLane = {
      id,
      from,
      to,
      waypoints,
      width: 10000, // 10 km wide
      speedLimit: 300, // m/s
      traffic: 0,
      maxTraffic: 100,
      hazardLevel: 0
    };

    this.lanes.set(id, lane);
    return lane;
  }

  /**
   * Create traffic zones around a station
   */
  private createStationZones(station: SpaceStation): void {
    // Approach zone
    this.zones.set(`${station.id}_approach`, {
      id: `${station.id}_approach`,
      center: { ...station.position },
      radius: 50000, // 50 km
      zoneType: 'APPROACH',
      speedLimit: 100,
      priority: 2
    });

    // Departure zone
    this.zones.set(`${station.id}_departure`, {
      id: `${station.id}_departure`,
      center: { ...station.position },
      radius: 30000, // 30 km
      zoneType: 'DEPARTURE',
      speedLimit: 150,
      priority: 2
    });

    // Holding zone
    this.zones.set(`${station.id}_holding`, {
      id: `${station.id}_holding`,
      center: {
        x: station.position.x + 100000,
        y: station.position.y,
        z: station.position.z
      },
      radius: 20000,
      zoneType: 'HOLDING',
      speedLimit: 50,
      priority: 1
    });

    // Restricted zone (immediate vicinity)
    this.zones.set(`${station.id}_restricted`, {
      id: `${station.id}_restricted`,
      center: { ...station.position },
      radius: 5000, // 5 km
      zoneType: 'RESTRICTED',
      speedLimit: 20,
      priority: 3
    });
  }

  /**
   * Initialize docking queue for station
   */
  private initializeDockingQueue(station: SpaceStation): void {
    this.dockingQueues.set(station.id, {
      stationId: station.id,
      queue: [],
      maxSlots: station.dockingPorts?.length || 10,
      activelyDocking: new Set()
    });
  }

  /**
   * Update traffic control
   */
  update(ships: NPCShip[], deltaTime: number): void {
    // Clear old warnings
    this.warnings = this.warnings.filter(w => Date.now() - w.timestamp < 60000); // Keep for 1 minute

    // Update lane traffic counts
    this.updateLaneTraffic(ships);

    // Check for collisions
    this.checkCollisions(ships);

    // Update docking queues
    this.updateDockingQueues(ships);

    // Generate traffic advisories
    this.generateAdvisories(ships);
  }

  /**
   * Update traffic count on lanes
   */
  private updateLaneTraffic(ships: NPCShip[]): void {
    // Reset counts
    for (const lane of this.lanes.values()) {
      lane.traffic = 0;
    }

    // Count ships on each lane
    for (const ship of ships) {
      const nearestLane = this.findNearestLane(ship.position);
      if (nearestLane) {
        const distanceToLane = this.distanceToLane(ship.position, nearestLane);
        if (distanceToLane < nearestLane.width) {
          nearestLane.traffic++;
        }
      }
    }
  }

  /**
   * Check for potential collisions
   */
  private checkCollisions(ships: NPCShip[]): void {
    this.collisionPredictions = [];

    for (let i = 0; i < ships.length; i++) {
      for (let j = i + 1; j < ships.length; j++) {
        const ship1 = ships[i];
        const ship2 = ships[j];

        const prediction = this.predictCollision(ship1, ship2);
        if (prediction && prediction.timeToCollision < 300) { // Within 5 minutes
          this.collisionPredictions.push(prediction);

          if (prediction.timeToCollision < 60) { // Critical: within 1 minute
            this.warnings.push({
              severity: 'CRITICAL',
              message: `Collision alert: ${ship1.name} and ${ship2.name}`,
              affectedShips: [ship1.id, ship2.id],
              position: prediction.collisionPoint,
              timestamp: Date.now()
            });
          }
        }
      }
    }
  }

  /**
   * Predict collision between two ships
   */
  private predictCollision(ship1: NPCShip, ship2: NPCShip): CollisionPrediction | null {
    // Relative position and velocity
    const relPos = {
      x: ship2.position.x - ship1.position.x,
      y: ship2.position.y - ship1.position.y,
      z: ship2.position.z - ship1.position.z
    };

    const relVel = {
      x: ship2.velocity.x - ship1.velocity.x,
      y: ship2.velocity.y - ship1.velocity.y,
      z: ship2.velocity.z - ship1.velocity.z
    };

    // Check if ships are approaching
    const dotProduct = relPos.x * relVel.x + relPos.y * relVel.y + relPos.z * relVel.z;
    if (dotProduct >= 0) {
      // Ships are moving apart
      return null;
    }

    // Time of closest approach
    const relVelMagSq = relVel.x * relVel.x + relVel.y * relVel.y + relVel.z * relVel.z;
    if (relVelMagSq < 0.001) {
      // Ships are stationary relative to each other
      return null;
    }

    const timeToClosest = -dotProduct / relVelMagSq;

    // Position at closest approach
    const closestPos1 = {
      x: ship1.position.x + ship1.velocity.x * timeToClosest,
      y: ship1.position.y + ship1.velocity.y * timeToClosest,
      z: ship1.position.z + ship1.velocity.z * timeToClosest
    };

    const closestPos2 = {
      x: ship2.position.x + ship2.velocity.x * timeToClosest,
      y: ship2.position.y + ship2.velocity.y * timeToClosest,
      z: ship2.position.z + ship2.velocity.z * timeToClosest
    };

    const closestDistance = this.distance(closestPos1, closestPos2);

    // Collision if closer than safety margin
    const safetyMargin = 1000; // 1 km
    if (closestDistance < safetyMargin) {
      const collisionPoint = {
        x: (closestPos1.x + closestPos2.x) / 2,
        y: (closestPos1.y + closestPos2.y) / 2,
        z: (closestPos1.z + closestPos2.z) / 2
      };

      return {
        ship1: ship1.id,
        ship2: ship2.id,
        timeToCollision: timeToClosest,
        collisionPoint,
        relativeVelocity: Math.sqrt(relVelMagSq),
        severity: 1 - (closestDistance / safetyMargin)
      };
    }

    return null;
  }

  /**
   * Update docking queues
   */
  private updateDockingQueues(ships: NPCShip[]): void {
    for (const queue of this.dockingQueues.values()) {
      // Remove ships that are no longer waiting
      queue.queue = queue.queue.filter(shipId => {
        const ship = ships.find(s => s.id === shipId);
        return ship && (ship.state === 'DOCKING' || ship.currentTarget === queue.stationId);
      });

      // Remove ships that finished docking
      const finishedDocking = Array.from(queue.activelyDocking).filter(shipId => {
        const ship = ships.find(s => s.id === shipId);
        return !ship || ship.state !== 'DOCKING';
      });
      finishedDocking.forEach(shipId => queue.activelyDocking.delete(shipId));

      // Process queue
      while (queue.activelyDocking.size < queue.maxSlots && queue.queue.length > 0) {
        const nextShip = queue.queue.shift()!;
        queue.activelyDocking.add(nextShip);
      }
    }
  }

  /**
   * Request docking clearance
   */
  requestDocking(shipId: string, stationId: string): {
    granted: boolean;
    position?: number;
    estimatedWait?: number;
  } {
    const queue = this.dockingQueues.get(stationId);
    if (!queue) {
      return { granted: false };
    }

    // Already in queue or docking?
    if (queue.queue.includes(shipId) || queue.activelyDocking.has(shipId)) {
      const position = queue.queue.indexOf(shipId) + 1;
      return {
        granted: position === 0,
        position: position > 0 ? position : undefined,
        estimatedWait: position * 120 // 2 minutes per ship
      };
    }

    // Add to queue
    if (queue.activelyDocking.size < queue.maxSlots) {
      queue.activelyDocking.add(shipId);
      return { granted: true, position: 0, estimatedWait: 0 };
    } else {
      queue.queue.push(shipId);
      return {
        granted: false,
        position: queue.queue.length,
        estimatedWait: queue.queue.length * 120
      };
    }
  }

  /**
   * Generate traffic advisories
   */
  private generateAdvisories(ships: NPCShip[]): void {
    // Check for congested lanes
    for (const lane of this.lanes.values()) {
      if (lane.traffic > lane.maxTraffic * 0.8) {
        const existingWarning = this.warnings.find(w =>
          w.message.includes(lane.id) && Date.now() - w.timestamp < 30000
        );

        if (!existingWarning) {
          this.warnings.push({
            severity: 'WARNING',
            message: `Traffic congestion on ${lane.id}`,
            affectedShips: [],
            position: lane.waypoints[Math.floor(lane.waypoints.length / 2)],
            timestamp: Date.now()
          });
        }
      }
    }

    // Check for speed violations
    for (const ship of ships) {
      const zone = this.getZoneAt(ship.position);
      if (zone) {
        const speed = this.magnitude(ship.velocity);
        if (speed > zone.speedLimit * 1.2) {
          this.warnings.push({
            severity: 'CAUTION',
            message: `Speed violation: ${ship.name} exceeding ${zone.speedLimit} m/s limit`,
            affectedShips: [ship.id],
            position: { ...ship.position },
            timestamp: Date.now()
          });
        }
      }
    }
  }

  /**
   * Get optimal route between two points
   */
  getRoute(from: Vector3, to: Vector3): {
    waypoints: Vector3[];
    distance: number;
    estimatedTime: number;
    lanes: string[];
  } {
    // Find connecting lanes
    const route: Vector3[] = [from];
    const usedLanes: string[] = [];
    let totalDistance = 0;

    // Simple pathfinding: find lane that gets closest to destination
    let currentPos = from;
    let remainingDistance = this.distance(from, to);

    while (remainingDistance > 1e6) { // Continue until within 1000 km
      const nearestLane = this.findBestLane(currentPos, to);

      if (!nearestLane) {
        // Direct route
        route.push(to);
        totalDistance += remainingDistance;
        break;
      }

      // Add lane waypoints
      const closestWaypoint = this.findClosestWaypoint(currentPos, nearestLane);
      for (let i = closestWaypoint; i < nearestLane.waypoints.length; i++) {
        route.push(nearestLane.waypoints[i]);
        if (i > closestWaypoint) {
          totalDistance += this.distance(nearestLane.waypoints[i - 1], nearestLane.waypoints[i]);
        }
      }

      usedLanes.push(nearestLane.id);
      currentPos = nearestLane.to;
      remainingDistance = this.distance(currentPos, to);
    }

    // Final leg
    if (route[route.length - 1] !== to) {
      route.push(to);
      totalDistance += this.distance(currentPos, to);
    }

    return {
      waypoints: route,
      distance: totalDistance,
      estimatedTime: totalDistance / 200, // Assume average 200 m/s
      lanes: usedLanes
    };
  }

  /**
   * Find best lane toward destination
   */
  private findBestLane(from: Vector3, to: Vector3): SpaceLane | null {
    let bestLane: SpaceLane | null = null;
    let bestScore = Infinity;

    for (const lane of this.lanes.values()) {
      // Distance to lane start
      const distToLaneStart = this.distance(from, lane.from);

      // How much closer does lane get us to destination?
      const currentDist = this.distance(from, to);
      const afterLaneDist = this.distance(lane.to, to);
      const progress = currentDist - afterLaneDist;

      // Score: prefer lanes that make good progress without too much detour
      const score = distToLaneStart + afterLaneDist - progress * 0.5;

      if (score < bestScore && progress > 0) {
        bestScore = score;
        bestLane = lane;
      }
    }

    return bestLane;
  }

  /**
   * Find nearest lane to position
   */
  private findNearestLane(position: Vector3): SpaceLane | null {
    let nearest: SpaceLane | null = null;
    let minDistance = Infinity;

    for (const lane of this.lanes.values()) {
      const distance = this.distanceToLane(position, lane);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = lane;
      }
    }

    return nearest;
  }

  /**
   * Distance from point to lane
   */
  private distanceToLane(point: Vector3, lane: SpaceLane): number {
    let minDist = Infinity;

    for (let i = 0; i < lane.waypoints.length - 1; i++) {
      const dist = this.distanceToSegment(point, lane.waypoints[i], lane.waypoints[i + 1]);
      minDist = Math.min(minDist, dist);
    }

    return minDist;
  }

  /**
   * Distance from point to line segment
   */
  private distanceToSegment(point: Vector3, segStart: Vector3, segEnd: Vector3): number {
    const segVec = {
      x: segEnd.x - segStart.x,
      y: segEnd.y - segStart.y,
      z: segEnd.z - segStart.z
    };

    const pointVec = {
      x: point.x - segStart.x,
      y: point.y - segStart.y,
      z: point.z - segStart.z
    };

    const segLenSq = segVec.x * segVec.x + segVec.y * segVec.y + segVec.z * segVec.z;
    const dot = pointVec.x * segVec.x + pointVec.y * segVec.y + pointVec.z * segVec.z;

    const t = Math.max(0, Math.min(1, dot / segLenSq));

    const closest = {
      x: segStart.x + segVec.x * t,
      y: segStart.y + segVec.y * t,
      z: segStart.z + segVec.z * t
    };

    return this.distance(point, closest);
  }

  /**
   * Find closest waypoint index in lane
   */
  private findClosestWaypoint(position: Vector3, lane: SpaceLane): number {
    let closest = 0;
    let minDist = Infinity;

    for (let i = 0; i < lane.waypoints.length; i++) {
      const dist = this.distance(position, lane.waypoints[i]);
      if (dist < minDist) {
        minDist = dist;
        closest = i;
      }
    }

    return closest;
  }

  /**
   * Get zone at position
   */
  private getZoneAt(position: Vector3): TrafficZone | null {
    let currentZone: TrafficZone | null = null;
    let highestPriority = -1;

    for (const zone of this.zones.values()) {
      const distance = this.distance(position, zone.center);
      if (distance <= zone.radius && zone.priority > highestPriority) {
        currentZone = zone;
        highestPriority = zone.priority;
      }
    }

    return currentZone;
  }

  /**
   * Get current warnings
   */
  getWarnings(): TrafficWarning[] {
    return this.warnings;
  }

  /**
   * Get collision predictions
   */
  getCollisionPredictions(): CollisionPrediction[] {
    return this.collisionPredictions;
  }

  /**
   * Get all lanes
   */
  getLanes(): SpaceLane[] {
    return Array.from(this.lanes.values());
  }

  /**
   * Get all zones
   */
  getZones(): TrafficZone[] {
    return Array.from(this.zones.values());
  }

  /**
   * Vector magnitude
   */
  private magnitude(v: Vector3): number {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  }

  /**
   * Distance between two points
   */
  private distance(p1: Vector3, p2: Vector3): number {
    const dx = p1.x - p2.x;
    const dy = p1.y - p2.y;
    const dz = p1.z - p2.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }
}
