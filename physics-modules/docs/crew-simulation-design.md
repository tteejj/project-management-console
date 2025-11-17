# Crew Simulation System Design

## Overview
Comprehensive crew member simulation including health, injuries, medical treatment, skills, morale, and task performance.

## Injury System

### Injury Types
- **Trauma** - Physical impacts, collisions, explosions
- **Burns** - Thermal, electrical, radiation
- **Asphyxiation** - Oxygen deprivation
- **Radiation Poisoning** - Cumulative radiation exposure
- **Decompression** - Rapid pressure loss injuries

### Injury Severity
- **Minor** (0-25%) - Reduced efficiency, can self-treat
- **Moderate** (25-50%) - Significant performance penalty, needs medical attention
- **Severe** (50-75%) - Incapacitated, requires immediate treatment
- **Critical** (75-100%) - Life threatening, will die without treatment

## Medical Treatment

### Treatment Actions
- **First Aid** - Stabilize injuries, stop bleeding (any crew with first aid training)
- **Surgery** - Treat severe injuries (requires medical officer + med bay)
- **Medication** - Pain relief, infection prevention
- **Rest** - Natural healing over time

### Healing Rates
- **Minor injuries**: 5% per hour with rest
- **Moderate injuries**: 2% per hour with medical treatment
- **Severe injuries**: 1% per hour with surgery + medication
- **Critical injuries**: Stabilize first, then 0.5% per hour

## Crew Skills

### Skill Categories
- **Engineering** (0-100) - Repair speed, system maintenance
- **Piloting** (0-100) - Ship control, docking precision
- **Combat** (0-100) - Weapon accuracy, tactical decisions
- **Medical** (0-100) - Healing rate, diagnosis accuracy
- **Science** (0-100) - Sensor effectiveness, analysis

### Skill Application
- Repair tasks: `effectiveRate = baseRate * (1 + engineering/100)`
- Medical treatment: `healingBonus = medical/100 * baseHealing`
- Combat: `accuracy = baseAccuracy * (1 + combat/200)`

## Morale and Stress

### Stress Factors
- **Combat** - +5% stress per minute in combat
- **Injuries** - +10% stress when injured crew present
- **Low oxygen** - +8% stress per minute under hypoxia
- **Isolation** - +1% stress per day (deep space)
- **Deaths** - +30% stress (decays over days)

### Stress Effects
- **Low stress** (0-30%): Normal performance
- **Medium stress** (30-60%): -10% efficiency
- **High stress** (60-85%): -25% efficiency, mistakes possible
- **Breaking point** (85-100%): Panic, refuses orders, errors

### Morale Recovery
- **Rest** - -5% stress per hour when resting
- **Success** - -10% stress on mission completion
- **Recreation** - -3% stress per hour (requires rec facilities)

## Task Performance

### Performance Modifiers
```
effectiveSkill = baseSkill
  * (1 - injuries * 0.5)      // Injuries reduce skill
  * (1 - fatigue * 0.3)       // Fatigue reduces skill
  * (1 - stress * 0.2)        // Stress reduces skill
  * oxygenLevel               // Hypoxia reduces skill
```

### Task Assignment
- Each crew member can be assigned to one task
- Task switching takes time (1-5 minutes depending on complexity)
- Some tasks require minimum skill levels
- Multiple crew can collaborate on tasks

## Death and Incapacitation

### Death Conditions
- Health reaches 0%
- Critical injury untreated for >30 minutes
- Oxygen level at 0% for >2 minutes
- Radiation dose exceeds lethal threshold

### Incapacitation
- Severe or critical injuries → cannot perform tasks
- Unconscious (oxygen < 40%) → cannot perform tasks
- High stress (>90%) → refuses dangerous tasks

## Physics Integration

### Injury Sources
- **Hull breach** → Decompression injuries (instant)
- **Explosion** → Trauma + burns (blast damage)
- **Fire** → Burns (area effect)
- **Radiation** → Cumulative over time
- **Collision** → Trauma (G-force dependent)

### Environmental Effects
- Low oxygen → Asphyxiation damage over time
- High temperature → Heat stress, eventual burns
- Radiation zones → Cumulative radiation exposure

## Implementation Notes

### Data Structures
```typescript
interface Injury {
  id: string;
  type: InjuryType;
  severity: number;        // 0-1 (0 = healed, 1 = fatal)
  bodyPart: BodyPart;
  timestamp: number;
  treated: boolean;
  stabilized: boolean;
}

interface CrewMemberState {
  id: string;
  name: string;
  role: CrewRole;

  // Health
  health: number;          // 0-1
  injuries: Injury[];

  // Skills
  skills: SkillSet;

  // State
  fatigue: number;         // 0-1
  stress: number;          // 0-1
  morale: number;          // 0-1

  // Status
  location: string;        // Compartment ID
  currentTask?: Task;
  incapacitated: boolean;
  alive: boolean;
}

interface MedicalSystem {
  medBays: MedBay[];
  supplies: MedicalSupplies;

  diagnose(crew: CrewMember): Diagnosis;
  treat(crew: CrewMember, treatment: Treatment): void;
  update(dt: number): void;
}
```

### Update Loop
1. **Apply environmental damage** (oxygen, radiation, temperature)
2. **Update injury severity** (bleeding, infection progression)
3. **Apply treatments** (healing, stabilization)
4. **Update stress** (environmental factors, events)
5. **Calculate performance** (skills × modifiers)
6. **Check death conditions**
7. **Update task efficiency**

## Test Coverage

- [x] Injury application from various sources
- [x] Injury severity progression
- [x] Medical treatment and healing
- [x] Skill-based task performance
- [x] Stress accumulation and recovery
- [x] Death from various causes
- [x] Incapacitation from injuries
- [x] Environmental damage (oxygen, radiation)
- [x] Multi-crew medical scenarios
- [x] Skill improvement over time
