/**
 * CommunicationSystem.ts
 * Realistic communication with light-speed delays, signal degradation, and relay networks
 */

import { Vector3 } from './CelestialBody';

export interface Message {
  id: string;
  from: string;              // Sender ID
  to: string;                // Recipient ID
  content: string;
  priority: MessagePriority;
  sentTime: number;          // timestamp when sent
  arrivalTime: number;       // timestamp when will arrive
  distance: number;          // meters
  delay: number;             // seconds
  signalStrength: number;    // 0-1
  encrypted: boolean;
  relayed: boolean;          // Was it relayed through a station?
  relayPath: string[];       // IDs of relay points
}

export type MessagePriority = 'LOW' | 'NORMAL' | 'HIGH' | 'EMERGENCY';

export interface CommunicationDevice {
  id: string;
  position: Vector3;
  power: number;             // watts (transmitter power)
  frequency: number;         // Hz
  bandwidth: number;         // bits/second
  range: number;             // meters (effective range)
  encryption: boolean;
  type: 'SHIP' | 'STATION' | 'RELAY' | 'BEACON';
}

export interface SignalRelay {
  id: string;
  position: Vector3;
  range: number;             // meters
  maxConnections: number;
  activeConnections: number;
  bandwidth: number;         // bits/second
  delay: number;             // seconds (processing delay)
}

export interface BroadcastMessage {
  id: string;
  from: string;
  content: string;
  timestamp: number;
  range: number;             // broadcast radius in meters
  frequency: number;         // Hz
  decayRate: number;         // signal strength decay per meter
}

export interface DataPacket {
  id: string;
  data: any;
  size: number;              // bytes
  from: string;
  to: string;
  progress: number;          // 0-1 (for large transfers)
  bandwidth: number;         // bytes/second
  estimatedTime: number;     // seconds remaining
}

/**
 * Communication System with Realistic Physics
 */
export class CommunicationSystem {
  private static readonly LIGHT_SPEED = 299792458; // m/s
  private messages: Message[] = [];
  private devices: Map<string, CommunicationDevice> = new Map();
  private relays: Map<string, SignalRelay> = new Map();
  private broadcasts: BroadcastMessage[] = [];
  private dataTransfers: Map<string, DataPacket> = new Map();
  private nextMessageId = 0;

  /**
   * Register communication device
   */
  registerDevice(device: CommunicationDevice): void {
    this.devices.set(device.id, device);
  }

  /**
   * Register signal relay
   */
  registerRelay(relay: SignalRelay): void {
    this.relays.set(relay.id, relay);
  }

  /**
   * Send message with realistic light-speed delay
   */
  sendMessage(
    from: string,
    to: string,
    content: string,
    priority: MessagePriority = 'NORMAL',
    encrypted: boolean = false
  ): Message | null {
    const fromDevice = this.devices.get(from);
    const toDevice = this.devices.get(to);

    if (!fromDevice || !toDevice) {
      console.error('Invalid sender or recipient');
      return null;
    }

    // Calculate distance
    const distance = this.distance(fromDevice.position, toDevice.position);

    // Calculate light-speed delay
    const lightDelay = distance / CommunicationSystem.LIGHT_SPEED;

    // Check if direct communication is possible
    const directPossible = distance < fromDevice.range;

    let actualDelay = lightDelay;
    let relayPath: string[] = [];
    let relayed = false;

    if (!directPossible) {
      // Need to use relay network
      const path = this.findRelayPath(fromDevice.position, toDevice.position);

      if (path) {
        relayed = true;
        relayPath = path.relays;
        actualDelay = path.totalDelay;
      } else {
        console.error('No communication path available');
        return null;
      }
    }

    // Calculate signal strength (inverse square law)
    const signalStrength = this.calculateSignalStrength(
      fromDevice.power,
      distance,
      fromDevice.frequency
    );

    const message: Message = {
      id: `msg_${this.nextMessageId++}`,
      from,
      to,
      content,
      priority,
      sentTime: Date.now(),
      arrivalTime: Date.now() + actualDelay * 1000,
      distance,
      delay: actualDelay,
      signalStrength,
      encrypted,
      relayed,
      relayPath
    };

    this.messages.push(message);
    return message;
  }

  /**
   * Broadcast message to all devices in range
   */
  broadcast(
    from: string,
    content: string,
    range?: number
  ): BroadcastMessage | null {
    const fromDevice = this.devices.get(from);
    if (!fromDevice) return null;

    const broadcast: BroadcastMessage = {
      id: `broadcast_${this.nextMessageId++}`,
      from,
      content,
      timestamp: Date.now(),
      range: range || fromDevice.range,
      frequency: fromDevice.frequency,
      decayRate: 1e-9 // Signal strength decay
    };

    this.broadcasts.push(broadcast);
    return broadcast;
  }

  /**
   * Start data transfer
   */
  startDataTransfer(
    from: string,
    to: string,
    data: any,
    size: number // bytes
  ): DataPacket | null {
    const fromDevice = this.devices.get(from);
    const toDevice = this.devices.get(to);

    if (!fromDevice || !toDevice) return null;

    const distance = this.distance(fromDevice.position, toDevice.position);

    // Bandwidth decreases with distance
    const effectiveBandwidth = fromDevice.bandwidth * Math.exp(-distance / fromDevice.range);
    const transferTime = size / effectiveBandwidth;

    const packet: DataPacket = {
      id: `data_${this.nextMessageId++}`,
      data,
      size,
      from,
      to,
      progress: 0,
      bandwidth: effectiveBandwidth,
      estimatedTime: transferTime
    };

    this.dataTransfers.set(packet.id, packet);
    return packet;
  }

  /**
   * Update communication system
   */
  update(deltaTime: number): void {
    const now = Date.now();

    // Update data transfers
    for (const [id, packet] of this.dataTransfers) {
      const transferred = packet.bandwidth * deltaTime;
      const progressIncrease = transferred / packet.size;
      packet.progress += progressIncrease;
      packet.estimatedTime -= deltaTime;

      if (packet.progress >= 1.0) {
        this.dataTransfers.delete(id);
        // Transfer complete
      }
    }

    // Clean old broadcasts (after 1 hour)
    this.broadcasts = this.broadcasts.filter(b => now - b.timestamp < 3600000);

    // Clean delivered messages (after 1 minute)
    this.messages = this.messages.filter(m => {
      if (now >= m.arrivalTime) {
        // Message delivered, keep for 1 minute
        return now - m.arrivalTime < 60000;
      }
      return true;
    });
  }

  /**
   * Get messages for recipient
   */
  getMessages(recipientId: string, undeliveredOnly: boolean = false): Message[] {
    const now = Date.now();

    return this.messages.filter(m => {
      if (m.to !== recipientId) return false;
      if (undeliveredOnly && now < m.arrivalTime) return true;
      if (!undeliveredOnly && now >= m.arrivalTime) return true;
      return false;
    });
  }

  /**
   * Get pending messages (not yet arrived)
   */
  getPendingMessages(recipientId: string): Message[] {
    const now = Date.now();
    return this.messages.filter(m =>
      m.to === recipientId && now < m.arrivalTime
    );
  }

  /**
   * Get broadcasts in range
   */
  getBroadcastsInRange(deviceId: string): BroadcastMessage[] {
    const device = this.devices.get(deviceId);
    if (!device) return [];

    return this.broadcasts.filter(b => {
      const distance = this.distance(device.position, this.devices.get(b.from)?.position || { x: 0, y: 0, z: 0 });
      return distance <= b.range;
    });
  }

  /**
   * Find relay path between two points
   */
  private findRelayPath(from: Vector3, to: Vector3): {
    relays: string[];
    totalDelay: number;
  } | null {
    // Simple pathfinding through relay network
    // In a real implementation, would use A* or Dijkstra

    const relays = Array.from(this.relays.values());
    let currentPos = from;
    const usedRelays: string[] = [];
    let totalDelay = 0;
    const maxHops = 10;

    for (let hop = 0; hop < maxHops; hop++) {
      // Find nearest relay that gets us closer to destination
      let bestRelay: SignalRelay | null = null;
      let bestScore = Infinity;

      for (const relay of relays) {
        if (usedRelays.includes(relay.id)) continue;

        const distToRelay = this.distance(currentPos, relay.position);
        const relayToDest = this.distance(relay.position, to);

        // Can we reach this relay?
        if (distToRelay > (usedRelays.length === 0 ? 1e9 : relays[0].range)) continue;

        // Score: prefer relays closer to destination
        const score = distToRelay + relayToDest;

        if (score < bestScore) {
          bestScore = score;
          bestRelay = relay;
        }
      }

      if (!bestRelay) break;

      // Add relay to path
      usedRelays.push(bestRelay.id);
      totalDelay += this.distance(currentPos, bestRelay.position) / CommunicationSystem.LIGHT_SPEED;
      totalDelay += bestRelay.delay; // Processing delay
      currentPos = bestRelay.position;

      // Can we reach destination from here?
      const finalDistance = this.distance(currentPos, to);
      if (finalDistance < bestRelay.range) {
        totalDelay += finalDistance / CommunicationSystem.LIGHT_SPEED;
        return { relays: usedRelays, totalDelay };
      }
    }

    return null; // No path found
  }

  /**
   * Calculate signal strength (inverse square law)
   */
  private calculateSignalStrength(
    power: number, // watts
    distance: number, // meters
    frequency: number // Hz
  ): number {
    // Friis transmission equation (simplified)
    // Received power = (P_t * G_t * G_r * λ²) / ((4π)² * d²)

    const c = CommunicationSystem.LIGHT_SPEED;
    const wavelength = c / frequency;

    // Assuming unity gain antennas (G_t = G_r = 1)
    const receivedPower = (power * wavelength * wavelength) /
                          (Math.pow(4 * Math.PI * distance, 2));

    // Normalize to 0-1 (assume 1 pW minimum detectable)
    const minDetectable = 1e-12; // 1 pW
    const strength = Math.min(1, receivedPower / minDetectable);

    return strength;
  }

  /**
   * Calculate light-speed delay
   */
  getLightSpeedDelay(distance: number): number {
    return distance / CommunicationSystem.LIGHT_SPEED;
  }

  /**
   * Get communication latency between two devices
   */
  getLatency(from: string, to: string): number {
    const fromDevice = this.devices.get(from);
    const toDevice = this.devices.get(to);

    if (!fromDevice || !toDevice) return Infinity;

    const distance = this.distance(fromDevice.position, toDevice.position);
    return this.getLightSpeedDelay(distance);
  }

  /**
   * Can two devices communicate directly?
   */
  canCommunicate(from: string, to: string): boolean {
    const fromDevice = this.devices.get(from);
    const toDevice = this.devices.get(to);

    if (!fromDevice || !toDevice) return false;

    const distance = this.distance(fromDevice.position, toDevice.position);
    return distance < fromDevice.range;
  }

  /**
   * Get all active data transfers
   */
  getActiveTransfers(): DataPacket[] {
    return Array.from(this.dataTransfers.values());
  }

  /**
   * Cancel data transfer
   */
  cancelTransfer(transferId: string): boolean {
    return this.dataTransfers.delete(transferId);
  }

  /**
   * Get device
   */
  getDevice(id: string): CommunicationDevice | undefined {
    return this.devices.get(id);
  }

  /**
   * Update device position
   */
  updateDevicePosition(id: string, position: Vector3): void {
    const device = this.devices.get(id);
    if (device) {
      device.position = { ...position };
    }
  }

  /**
   * Distance between points
   */
  private distance(p1: Vector3, p2: Vector3): number {
    const dx = p1.x - p2.x;
    const dy = p1.y - p2.y;
    const dz = p1.z - p2.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /**
   * Format delay for display
   */
  static formatDelay(seconds: number): string {
    if (seconds < 1) return `${(seconds * 1000).toFixed(0)}ms`;
    if (seconds < 60) return `${seconds.toFixed(1)}s`;
    if (seconds < 3600) return `${(seconds / 60).toFixed(1)}m`;
    return `${(seconds / 3600).toFixed(1)}h`;
  }
}
