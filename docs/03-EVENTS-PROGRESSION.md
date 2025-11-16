# Events, Progression & Campaign Structure

## Campaign Overview

**Structure:** Node-based map inspired by FTL/Out There

**Goal:** Travel from outer rim to inner core (20-30 jumps)

**Duration:** 2-5 hours for complete playthrough

**Difficulty Curve:** Progressive - outer sectors easier, inner sectors brutal

**Persistence:** Ship damage and resource depletion carry forward between nodes

**Failure:** Permadeath, but meta-progression unlocks

---

## Sector Map Structure

### Map Generation

**Procedural with constraints:**
- 4-6 sectors, each with 5-8 nodes
- Total 20-40 nodes per campaign
- Player chooses path (branch points)
- Some paths safer but longer
- Some paths dangerous but shorter/better rewards

**Example Map:**
```
SECTOR 1 (RIM) - Tutorial Easy
    Start → [Navigate] → [Empty] → [Derelict] → JUMP GATE
                    ↘ [Debris] ↗

SECTOR 2 (OUTER) - Moderate
    → [Salvage] → [Asteroid] → [Station] → [Empty] → JUMP GATE
          ↘ [Anomaly] → [Hazard] ↗

SECTOR 3 (MIDDLE) - Hard
    → [Combat] → [Dense Debris] → [Derelict] → JUMP GATE
          ↘ [Repair Station] ↗ (costs resources but safe)

SECTOR 4 (CORE) - Very Hard
    → [Final Approach] → [Desperate Survival] → GOAL
```

**Node Types Distribution:**
- 40% Navigation Challenges
- 30% Operational Events
- 20% Encounters (trade, salvage, distress)
- 10% Safe Havens (repair/rest)

---

## Event Types

### 1. Navigation Challenges (Piloting Skill)

These require active use of helm/propulsion controls.

#### **1.1 Precision Docking**
- **Objective:** Rendezvous with station/derelict within time limit
- **Challenge:** Must match velocity vector exactly (delta-v < 0.5 m/s)
- **Systems Used:** Helm, Navigation, Propulsion
- **Failure:** Collision damage, bounce off, fuel wasted
- **Success Reward:** Access to station/salvage
- **Fuel Cost:** Medium

#### **1.2 Asteroid Field Threading**
- **Objective:** Navigate through dense asteroid field to reach waypoint
- **Challenge:** Avoid collisions while maintaining forward progress
- **Systems Used:** Helm, Navigation, Sensors
- **Obstacles:** 10-20 moving asteroids, varying sizes
- **Failure:** Hull damage, system damage, game over if critical
- **Success Reward:** Shortcut (saves time/fuel), or mineral salvage
- **Fuel Cost:** Medium-High (lots of maneuvering)

#### **1.3 Debris Cloud Navigation**
- **Objective:** Cross region of high-velocity microdebris
- **Challenge:** Minimize exposure time, orient ship to minimize cross-section
- **Systems Used:** Helm, Navigation
- **Hazard:** Random impacts (1-5 per crossing)
- **Failure:** Hull breaches, system damage
- **Success Reward:** Faster route
- **Fuel Cost:** Low-Medium

#### **1.4 High-G Intercept**
- **Objective:** Intercept fast-moving target (another ship, probe, etc.)
- **Challenge:** Requires high thrust, fuel management, overheat management
- **Systems Used:** Helm, Engineering (thermal), Navigation
- **Failure:** Target escapes, engine damage from overheating
- **Success Reward:** Salvage, data, mission objective
- **Fuel Cost:** High

#### **1.5 Gravity Well Escape**
- **Objective:** Escape strong gravity field (too close to planet/star)
- **Challenge:** Limited fuel, must plot efficient burn
- **Systems Used:** Helm, Navigation, Fuel management
- **Failure:** Crash into body, or stranded in orbit (fuel depleted)
- **Success Reward:** Survival, bonus if fuel-efficient
- **Fuel Cost:** High

---

### 2. Operational Events (System Management)

These test system management skills, less about piloting.

#### **2.1 Reactor Failure (Mid-Transit)**
- **Trigger:** Random (5-10% chance per jump)
- **Event:** Reactor SCRAMs unexpectedly
- **Challenge:** Restart reactor before battery depletes
- **Time Limit:** 5-10 minutes (based on battery charge)
- **Systems Used:** Engineering, Power Management
- **Consequences:** If battery depletes → blackout → must manually restore all systems
- **Complexity:** Must manage power priorities during restart
- **Success:** Resume journey
- **Failure:** Blackout, extended time loss, possible system damage

#### **2.2 Fire Outbreak**
- **Trigger:** Random (8% chance), or caused by overheat event
- **Location:** Random compartment
- **Challenge:** Extinguish fire before spreads or consumes all O2
- **Systems Used:** Life Support, Damage Control, Thermal
- **Options:**
  - Fire suppression (uses Halon, limited quantity)
  - Vent compartment (loses atmosphere, creates thrust vector)
  - Seal and starve (slow, but safe if contained)
- **Consequences:**
  - Damage to systems in burning compartment
  - O2 loss if vented
  - Heat buildup affects adjacent compartments
- **Success:** Fire extinguished, minimal damage
- **Failure:** Ship-wide fire, critical damage, game over

#### **2.3 Hull Breach (Micrometeorite)**
- **Trigger:** Random (10% in debris fields, 3% in open space)
- **Event:** Small puncture in random compartment
- **Challenge:** Detect and seal breach before too much atmosphere lost
- **Systems Used:** Life Support, Damage Control
- **Detection:** Pressure drop in compartment (must notice!)
- **Response Time:** 30-120 seconds depending on breach size
- **Options:**
  - Seal compartment (loses that compartment until repaired)
  - Emergency patch (uses repair kit)
  - Ignore and vent atmosphere (if compartment non-essential)
- **Side Effect:** Venting creates small thrust vector (can be useful or annoying)
- **Success:** Breach sealed, minimal loss
- **Failure:** Complete atmosphere loss, possible crew death (if crew), frozen systems

#### **2.4 Power Distribution Puzzle**
- **Trigger:** Scripted or random
- **Event:** Damaged power bus, must reroute systems
- **Challenge:** Limited power available, must choose what stays on
- **Systems Used:** Engineering
- **Scenario:** "Bus A damaged, only Bus B working at 60% capacity"
- **Player Choice:** What to power? Life support + nav? Or propulsion + sensors?
- **Time Pressure:** No immediate danger, but affects next challenge
- **Success:** Optimal routing maintained
- **Failure:** Wrong systems offline for next event

#### **2.5 Thermal Overload**
- **Trigger:** After extended high-thrust burn, or reactor overheat
- **Event:** Ship temperature critical, coolant system overwhelmed
- **Challenge:** Reduce heat before systems fail
- **Systems Used:** Engineering, Thermal Management
- **Options:**
  - Deploy radiators (must be moving slowly)
  - Reduce reactor output (less power available)
  - Emergency coolant dump (one-time, uses all coolant)
  - Shut down non-essential systems (reduces heat generation)
- **Time Limit:** 2-5 minutes before critical
- **Consequences:** System failures if not resolved
- **Success:** Temperature stabilized
- **Failure:** Reactor shutdown, system damage

#### **2.6 Fuel Tank Imbalance**
- **Trigger:** After heavy maneuvering
- **Event:** Fuel sloshed, tanks unbalanced
- **Challenge:** Ship has rotation tendency, hard to control
- **Systems Used:** Helm (Fuel Management)
- **Solution:** Transfer fuel between tanks to rebalance
- **Complication:** Can't transfer too fast (pump rate limited)
- **Time Pressure:** Makes next navigation challenge harder if not fixed
- **Success:** Balance restored
- **Failure:** Wasted fuel fighting rotation, harder piloting

---

### 3. Encounter Events (Decision-Making)

These involve choices with trade-offs.

#### **3.1 Derelict Vessel**
- **Situation:** Detect abandoned ship
- **Options:**
  1. **Investigate** (dock and salvage)
     - Requires: Precision docking challenge
     - Reward: Fuel, parts, O2, or equipment
     - Risk: Derelict may be damaged (radiation, hull unstable)
     - Time: 5-10 minutes
  2. **Ignore** (continue journey)
     - Safe but no rewards
  3. **Scan only** (sensors)
     - Requires: Sensors powered
     - Reveals: What's aboard, risk level
     - Time: 30 seconds
- **Random Outcomes:**
  - 60% good salvage
  - 20% minimal salvage, not worth fuel
  - 15% trap (hull collapse causes damage)
  - 5% jackpot (major equipment upgrade)

#### **3.2 Distress Signal**
- **Situation:** Receive SOS from another vessel
- **Options:**
  1. **Respond** (rendezvous)
     - Requires: Navigation challenge
     - Reward: Gratitude (repair help, info, resources)
     - Risk: Could be ambush (future: if combat added)
     - Time: 5-15 minutes
     - Fuel Cost: Medium-High
  2. **Ignore** (continue)
     - No cost, no benefit
     - Moral weight (flavor text only)
- **Outcomes:**
  - 70% genuine, rewards given
  - 20% nothing (ship already dead)
  - 10% complications (ship explodes, rescue is hard)

#### **3.3 Repair Station**
- **Situation:** Arrive at inhabited station
- **Services:**
  - Repair systems (costs credits or resources)
  - Refuel (costs credits)
  - Restock O2/parts (costs credits)
  - Upgrade ship (costs credits, post-MVP)
- **Options:**
  1. **Dock and trade**
  2. **Skip** (if low on resources)
- **Currency:** Salvage/credits earned from missions
- **Pricing:** Balanced so player must make tough choices

#### **3.4 Strange Anomaly**
- **Situation:** Sensors detect unusual signature
- **Options:**
  1. **Investigate**
     - Reward: Rare resource, story snippet, data
     - Risk: Unpredictable (radiation burst, EM pulse, nothing)
     - Time: 2-5 minutes
  2. **Avoid**
     - Safe
- **Outcomes:** (Randomized)
  - 40% beneficial (resource, data)
  - 40% neutral (interesting but no effect)
  - 20% harmful (damage, system disruption)
- **Purpose:** Adds mystery, variety

#### **3.5 Resource Trade**
- **Situation:** Encounter trader or automated depot
- **Options:** Trade resources (fuel for O2, parts for fuel, etc.)
- **Exchange Rates:** Variable (sometimes favorable, sometimes not)
- **Player Choice:** Based on current needs
- **No Time Pressure:** Can consider carefully

---

### 4. Safe Haven Events

#### **4.1 Empty Space**
- **Situation:** Quiet sector, no threats
- **Benefit:** Time to repair, rebalance, plan
- **Activities:**
  - Manual repairs (takes time but free)
  - Fuel transfer/rebalancing
  - System checks
  - Rest (if crew added)
- **No time limit:** Can stay as long as wanted
- **Risk:** None, but campaign timer advances (future: if time-limited mode)

#### **4.2 Lagrange Point**
- **Situation:** Stable orbital position
- **Benefit:** Zero thrust needed, power savings
- **Activities:** Same as Empty Space, but can shut down engines completely
- **Rare:** Only 5-10% of nodes

---

## Random Events (Mid-Jump)

These can happen DURING transit between nodes:

### Random Event Pool

| Event | Chance | Impact |
|-------|--------|--------|
| Micrometeorite Hit | 10% | Hull breach |
| Reactor Hiccup | 5% | Power fluctuation |
| Fire Outbreak | 3% | Fire in random compartment |
| System Glitch | 8% | Random system reduced efficiency |
| Nothing | 74% | Peaceful transit |

**Frequency:** Check once per jump

**Purpose:** Keeps player alert, never fully safe

---

## Progression Systems

### 1. Ship Persistence

**Damage carries forward:**
- Hull integrity reduced permanently (until repaired)
- System health degrades over campaign
- Resource depletion (fuel, O2, parts)

**Philosophy:** Ship degrades over time, becomes harder to manage

**Repair Options:**
- Stations (expensive but full repair)
- Manual repairs in safe zones (slow, uses parts)
- Jury-rig (free but unreliable)

**Strategic Depth:** Do I repair now or push forward?

---

### 2. Resource Economy

**Core Resources:**
- **Fuel:** Finite, consumed by propulsion
- **O2:** Finite, consumed over time (when crew added), or vented
- **Spare Parts:** Used for repairs
- **Coolant:** Used for thermal dumps (can be refilled at stations)
- **Battery Charge:** Regenerated by reactor, but capacity degrades

**Resource Scarcity:**
- Early sectors: Plentiful
- Late sectors: Scarce
- Forces difficult decisions

**Resource Management Examples:**
```
Scenario: Hull breach, fire, low fuel
- Can vent atmosphere to fight fire (lose O2, create thrust, save fuel)
- Can use fire suppression (uses Halon, limited)
- Can seal compartment (lose access, but safe)
Choice depends on current resource levels and upcoming challenges
```

---

### 3. Meta-Progression (Unlocks)

**Purpose:** Reward failed runs, encourage replays

**Unlock Types:**

#### **Ship Classes** (Unlocked by reaching certain sectors)
1. **Scout** (Starting ship)
   - Small, nimble
   - Low fuel capacity
   - Fragile
   - 4 stations

2. **Hauler** (Unlock: Reach Sector 3)
   - Large, slow
   - High fuel capacity
   - Durable
   - 5 stations
   - More complex systems

3. **Raider** (Unlock: Complete campaign once)
   - Medium size
   - Weapons systems (if combat added)
   - Moderate fuel
   - 5 stations

#### **Starting Loadouts** (Unlocked by achievements)
- "Well-Supplied" (extra fuel/O2)
- "Engineer's Dream" (extra spare parts)
- "Hotshot Pilot" (upgraded RCS)
- "Long Haul" (larger battery, better reactor)

#### **Difficulty Modifiers** (Unlocked by completing campaign)
- "Ironman" (no pause)
- "Hardcore" (more random events)
- "Efficient" (score bonus for low fuel use)

**Unlock Tracking:**
- Persistent save file
- Achievements tracked
- Encourages experimentation

---

### 4. Difficulty Curve

**Sector 1 (Rim) - Tutorial Difficulty:**
- Simple navigation challenges
- Few random events
- Abundant resources
- Forgiving timings
- **Goal:** Learn controls and systems

**Sector 2 (Outer) - Moderate:**
- Multi-system challenges (e.g., navigate while managing overheating)
- Occasional random events
- Moderate resources
- **Goal:** Master basic procedures

**Sector 3 (Middle) - Hard:**
- Cascading failures (one problem causes another)
- Frequent random events
- Scarce resources
- Degraded ship (accumulated damage)
- **Goal:** Improvisation and prioritization

**Sector 4 (Core) - Very Hard:**
- Multi-tasking required (manage 3+ problems simultaneously)
- Ship barely functional
- Minimal resources
- Desperate decisions
- **Goal:** Pure survival, creative solutions

**Difficulty Mechanics:**
- Random event frequency increases
- Resource scarcity increases
- Time pressures tighter
- Margin for error decreases
- Ship damage cumulative

---

## Mission Objectives (Campaign Goals)

### Primary Objective
**"Reach the Core"** - navigate to final node in innermost sector

**Why?** (Flavor, not heavy story):
- Retrieve data from abandoned core station
- Escape collapsing star system
- Deliver critical supplies
- (Player can imagine their own reason)

### Secondary Objectives (Optional)
- Complete in under 2 hours (speedrun)
- Complete with >50% fuel remaining (efficiency)
- Complete without any system reaching 0% health (perfectionist)
- Rescue 5+ distress calls (hero)

**Rewards:** Achievements, unlocks, bragging rights

---

## Event Scripting System

**Flexible event definition for easy content creation:**

```json
{
  "eventID": "precision_docking_01",
  "type": "navigation",
  "title": "Derelict Freighter",
  "description": "A large cargo vessel drifts ahead. Its beacon is still active.",
  "setup": {
    "targetDistance": 5000,
    "targetVelocity": {"x": 5, "y": 2},
    "timeLimit": 300,
    "dockingTolerance": 0.5
  },
  "success": {
    "rewards": {
      "fuel": 20,
      "parts": 2
    },
    "text": "Docking successful. Salvage teams recover fuel and parts."
  },
  "failure": {
    "penalties": {
      "hullDamage": 15,
      "systemDamage": "propulsion"
    },
    "text": "Collision! The impact damages your propulsion system."
  }
}
```

**Allows:**
- Easy event creation (JSON editing)
- Modding potential (future)
- Rapid content iteration
- Non-programmer contribution

---

## Campaign Persistence & Save System

**Save Points:**
- Auto-save at each node
- Can quit and resume
- No save scumming (single save slot, overwritten)

**Saved Data:**
- Ship state (all systems, health, resources)
- Current node position
- Unlocks and achievements
- Campaign seed (for procedural generation consistency)

**Permadeath:**
- If ship destroyed → save deleted
- Must start new campaign
- Unlocks persist

---

## Pacing & Session Design

**Target Session Lengths:**
- Single node: 5-15 minutes
- Single sector: 30-60 minutes
- Full campaign: 2-5 hours

**Pacing Rhythm:**
```
[Intense Challenge] → [Recovery/Planning] → [Moderate Challenge] → [Event/Decision] → [Intense Challenge] → ...
```

**Prevents:**
- Constant stress (burnout)
- Boredom (too easy stretches)

**Flow:**
- Tension → Relief → Tension
- Skill challenge → Decision challenge → Skill challenge
- Variety in challenge types

---

## Event Balance Guidelines

**Resource Costs Should:**
- Drain 10-30% of resource per major challenge
- Force hard choices by Sector 3
- Never be mathematically impossible (always some path to victory)

**Time Limits Should:**
- Feel tight but achievable with skill
- Allow for one mistake, not three
- Scale with player mastery (future: adaptive difficulty)

**Failure States Should:**
- Be recoverable (usually) - damage but not death
- Create new challenges (damaged systems change gameplay)
- Teach lessons (why did I fail? what should I do next time?)

**Randomness Should:**
- Add variety without being unfair
- Have mitigation options (sensors reduce surprise, repairs reduce damage, etc.)
- Feel like "bad luck but I could've prepared better"

---

## Testing & Iteration Plan

**Metrics to Track:**
- Average campaign completion rate (target: 30-40% for skilled players)
- Average fuel usage per sector
- Most common failure points
- Time to complete sectors
- Which events are most/least popular

**Balance Adjustments:**
- If everyone fails same spot → too hard, adjust
- If everyone passes easily → too easy, add challenge
- If event rarely chosen → increase reward or reduce risk
- If resource always plentiful → reduce availability

**Playtesting Phases:**
1. Solo dev testing (systems work?)
2. Friendly testing (is it fun?)
3. Blind testing (is it understandable?)
4. Balance testing (is it fair?)
