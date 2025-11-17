/**
 * Combat Computer System Tests
 *
 * Tests sensor fusion, targeting, and fire control
 */

import { describe, it, expect } from 'vitest';
import {
  CombatComputer,
  Track,
  TargetPriority,
  FireSolution,
  ThreatLevel
} from '../src/combat-computer';
import { SensorContact } from '../src/sensors';
import { Vector3 } from '../src/math-utils';

describe('Combat Computer System', () => {
  describe('Sensor Fusion', () => {
    it('should fuse contacts from multiple sensors', () => {
      const radarContact: SensorContact = {
        targetId: 'target-1',
        position: { x: 10000, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 },
        signalStrength: 0.8,
        sensorType: 'radar'
      };

      const thermalContact: SensorContact = {
        targetId: 'target-1',
        position: { x: 10100, y: 0, z: 0 },  // Slightly different position
        velocity: { x: 0, y: 0, z: 0 },
        signalStrength: 0.6,
        sensorType: 'thermal'
      };

      const combatComputer = new CombatComputer({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      });

      combatComputer.updateSensorContacts([radarContact, thermalContact]);

      const tracks = combatComputer.getTracks();
      expect(tracks.length).toBe(1);  // Should fuse into single track
    });

    it('should track multiple separate targets', () => {
      const contact1: SensorContact = {
        targetId: 'target-1',
        position: { x: 10000, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 },
        signalStrength: 0.8,
        sensorType: 'radar'
      };

      const contact2: SensorContact = {
        targetId: 'target-2',
        position: { x: 0, y: 20000, z: 0 },
        velocity: { x: 0, y: 0, z: 0 },
        signalStrength: 0.7,
        sensorType: 'radar'
      };

      const combatComputer = new CombatComputer({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      });

      combatComputer.updateSensorContacts([contact1, contact2]);

      const tracks = combatComputer.getTracks();
      expect(tracks.length).toBe(2);
    });
  });

  describe('Target Tracking', () => {
    it('should estimate target velocity from position updates', () => {
      const combatComputer = new CombatComputer({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      });

      // First observation
      combatComputer.updateSensorContacts([{
        targetId: 'target-1',
        position: { x: 10000, y: 0, z: 0 },
        velocity: { x: 100, y: 0, z: 0 },
        signalStrength: 0.8,
        sensorType: 'radar'
      }]);

      combatComputer.update(10);

      // Second observation (target moved)
      combatComputer.updateSensorContacts([{
        targetId: 'target-1',
        position: { x: 11000, y: 0, z: 0 },  // Moved 1000m in 10s = 100 m/s
        velocity: { x: 100, y: 0, z: 0 },
        signalStrength: 0.8,
        sensorType: 'radar'
      }]);

      const tracks = combatComputer.getTracks();
      expect(tracks[0].velocity.x).toBeCloseTo(100, 0);
    });

    it('should drop stale tracks', () => {
      const combatComputer = new CombatComputer({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      });

      combatComputer.updateSensorContacts([{
        targetId: 'target-1',
        position: { x: 10000, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 },
        signalStrength: 0.8,
        sensorType: 'radar'
      }]);

      // Update with no new contacts for long time
      for (let i = 0; i < 100; i++) {
        combatComputer.update(1);
        combatComputer.updateSensorContacts([]);
      }

      const tracks = combatComputer.getTracks();
      expect(tracks.length).toBe(0);  // Stale track should be dropped
    });
  });

  describe('Threat Assessment', () => {
    it('should assess threat based on range and closure rate', () => {
      const combatComputer = new CombatComputer({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      });

      // Close, fast-approaching target
      combatComputer.updateSensorContacts([{
        targetId: 'threat',
        position: { x: 5000, y: 0, z: 0 },    // 5km away
        velocity: { x: -500, y: 0, z: 0 },    // Approaching at 500 m/s
        signalStrength: 0.9,
        sensorType: 'radar'
      }]);

      combatComputer.update(1);

      const tracks = combatComputer.getTracks();
      expect(tracks[0].threatLevel).toBe(ThreatLevel.HIGH);
    });

    it('should assess lower threat for distant targets', () => {
      const combatComputer = new CombatComputer({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      });

      combatComputer.updateSensorContacts([{
        targetId: 'distant',
        position: { x: 100000, y: 0, z: 0 },  // 100km away
        velocity: { x: 0, y: 0, z: 0 },       // Not moving
        signalStrength: 0.3,
        sensorType: 'radar'
      }]);

      combatComputer.update(1);

      const tracks = combatComputer.getTracks();
      expect(tracks[0].threatLevel).toBe(ThreatLevel.LOW);
    });
  });

  describe('Fire Control', () => {
    it('should calculate lead angle for moving target', () => {
      const combatComputer = new CombatComputer({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      });

      combatComputer.updateSensorContacts([{
        targetId: 'target-1',
        position: { x: 10000, y: 10000, z: 0 },
        velocity: { x: 0, y: 100, z: 0 },      // Moving perpendicular
        signalStrength: 0.8,
        sensorType: 'radar'
      }]);

      combatComputer.update(1);

      const solution = combatComputer.getFireSolution('target-1', 2000);  // 2000 m/s projectile

      expect(solution).not.toBeNull();
      expect(solution!.aimPoint.y).toBeGreaterThan(10000);  // Should lead target
    });

    it('should provide best-effort solution for difficult shot', () => {
      const combatComputer = new CombatComputer({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      });

      combatComputer.updateSensorContacts([{
        targetId: 'fast-target',
        position: { x: 10000, y: 0, z: 0 },
        velocity: { x: 3000, y: 0, z: 0 },     // Faster than projectile
        signalStrength: 0.8,
        sensorType: 'radar'
      }]);

      combatComputer.update(1);

      const solution = combatComputer.getFireSolution('fast-target', 2000);

      // Should still provide a solution (best-effort), even if interception unlikely
      expect(solution).not.toBeNull();
      expect(solution!.valid).toBe(true);
    });
  });

  describe('Target Prioritization', () => {
    it('should prioritize targets by threat', () => {
      const combatComputer = new CombatComputer({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      });

      combatComputer.updateSensorContacts([
        {
          targetId: 'close-threat',
          position: { x: 3000, y: 0, z: 0 },
          velocity: { x: -100, y: 0, z: 0 },
          signalStrength: 0.9,
          sensorType: 'radar'
        },
        {
          targetId: 'distant-target',
          position: { x: 50000, y: 0, z: 0 },
          velocity: { x: 0, y: 0, z: 0 },
          signalStrength: 0.5,
          sensorType: 'radar'
        }
      ]);

      combatComputer.update(1);

      const prioritized = combatComputer.getPrioritizedTargets();

      expect(prioritized[0].targetId).toBe('close-threat');
    });
  });

  describe('Weapon Assignment', () => {
    it('should assign available weapons to targets', () => {
      const combatComputer = new CombatComputer({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      });

      combatComputer.updateSensorContacts([{
        targetId: 'target-1',
        position: { x: 10000, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 },
        signalStrength: 0.8,
        sensorType: 'radar'
      }]);

      combatComputer.update(1);

      // Register and assign weapon to target
      combatComputer.registerWeapon('railgun-1', 5);
      const assigned = combatComputer.assignWeapon('railgun-1', 'target-1');

      expect(assigned).toBe(true);
    });

    it('should track weapon cooldowns', () => {
      const combatComputer = new CombatComputer({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      });

      combatComputer.registerWeapon('railgun-1', 10);  // 10s cooldown

      combatComputer.fireWeapon('railgun-1');

      const ready = combatComputer.isWeaponReady('railgun-1');
      expect(ready).toBe(false);

      // Wait for cooldown
      for (let i = 0; i < 11; i++) {
        combatComputer.update(1);
      }

      const readyNow = combatComputer.isWeaponReady('railgun-1');
      expect(readyNow).toBe(true);
    });
  });

  describe('Track Quality', () => {
    it('should track confidence based on sensor quality', () => {
      const combatComputer = new CombatComputer({
        position: { x: 0, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 }
      });

      combatComputer.updateSensorContacts([{
        targetId: 'target-1',
        position: { x: 10000, y: 0, z: 0 },
        velocity: { x: 0, y: 0, z: 0 },
        signalStrength: 0.9,  // Strong signal
        sensorType: 'radar'
      }]);

      combatComputer.update(1);

      const tracks = combatComputer.getTracks();
      expect(tracks[0].confidence).toBeGreaterThan(0.7);
    });
  });
});
