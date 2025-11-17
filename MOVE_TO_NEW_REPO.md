# Moving Vector Moon Lander to Separate Repository

**Date:** 2025-11-17
**Current Status:** game-main branch ready, but contains PMC files
**Action Required:** Clean separation to new repository

---

## Option 1: Clean Extraction (Recommended)

This creates a fresh repository with only game files and clean history.

### Step 1: Create New Repository on GitHub
1. Go to GitHub
2. Click "New repository"
3. Name: `vector-moon-lander` (or your preferred name)
4. Description: "Spacecraft systems simulator - submarine in space"
5. **Leave empty** (no README, no .gitignore)
6. Click "Create repository"

### Step 2: Extract Game Files Locally
```bash
# Create a new directory for the game
mkdir ~/vector-moon-lander
cd ~/vector-moon-lander

# Initialize new git repository
git init
git branch -m main

# Copy game files from game-main branch
cd /home/user/project-management-console
git checkout game-main

# Copy only game-related directories and files
cp -r physics-modules ~/vector-moon-lander/
cp -r game ~/vector-moon-lander/
cp -r game-engine ~/vector-moon-lander/
cp -r universe-system ~/vector-moon-lander/
cp -r docs ~/vector-moon-lander/

# Copy game-related markdown files
cp BRANCH_MERGE_ANALYSIS.md ~/vector-moon-lander/
cp MERGE_COMPLETE.md ~/vector-moon-lander/
cp COLLISION_DETECTION_SYSTEM_DESIGN.md ~/vector-moon-lander/
cp COMPONENT_SUMMARY.md ~/vector-moon-lander/
cp ENHANCED_UNIVERSE_SYSTEMS.md ~/vector-moon-lander/
cp GAMEPLAY_SEQUENCES_DESIGN.md ~/vector-moon-lander/
cp HULL_DAMAGE_SYSTEM_DESIGN.md ~/vector-moon-lander/
cp INTEGRATION_COMPLETE.md ~/vector-moon-lander/
cp PHYSICS_STATUS_AND_GAPS.md ~/vector-moon-lander/
cp PROCEDURAL_GENERATION_DESIGN.md ~/vector-moon-lander/
cp QUICK_REFERENCE.md ~/vector-moon-lander/
cp REAL_PHYSICS_IMPLEMENTATION.md ~/vector-moon-lander/
cp SENSOR_DISPLAY_SYSTEM_DESIGN.md ~/vector-moon-lander/
cp SOURCE_CODE_REFERENCE.md ~/vector-moon-lander/
cp SPACE_GAME_ANALYSIS.md ~/vector-moon-lander/
cp TARGETING_INTERCEPT_SYSTEM_DESIGN.md ~/vector-moon-lander/
cp UNIVERSE_OVERVIEW.md ~/vector-moon-lander/
cp VISUAL_FRAMEWORK_README.md ~/vector-moon-lander/
cp WHAT_WORKS.md ~/vector-moon-lander/
cp WORLD_ENVIRONMENT_DESIGN.md ~/vector-moon-lander/
cp CODEBASE_EXPLORATION_SUMMARY.md ~/vector-moon-lander/

# Copy root-level game files if they exist
cp index.html ~/vector-moon-lander/ 2>/dev/null || true
cp .gitignore ~/vector-moon-lander/ 2>/dev/null || true
```

### Step 3: Create Clean Game README
```bash
cd ~/vector-moon-lander

cat > README.md << 'EOF'
# Vector Moon Lander

A spacecraft systems simulator emphasizing indirect control through complex subsystems. "Submarine in space."

## Overview

Vector Moon Lander is a deep physics-based spacecraft simulator with:
- 65+ integrated physics modules
- Realistic orbital mechanics, propulsion, thermal management
- Multi-station interface (browser-based + terminal)
- Procedural universe generation
- FTL-style campaign structure (planned)

## Project Status

**Implementation:** ~50% complete
- ✅ Physics simulation: 95% (45/45 tests passing)
- ✅ Ship systems: 90%
- ⚠️ User interface: 40% (browser UI exists, needs expansion)
- ❌ Campaign: 10%

See `docs/ARCHITECTURE_REVIEW.md` for detailed status.

## Quick Start

### Physics Modules
```bash
cd physics-modules
npm install
npm test  # Run 45 physics tests
```

### Browser UI
```bash
cd game
npm install
npm run dev  # Start development server
```

### Examples
```bash
cd physics-modules/examples
ts-node interactive-game.ts  # Play terminal-based moon lander
ts-node lunar-lander-game.ts  # Full simulation
```

## Documentation

Start with these documents in order:
1. `docs/ARCHITECTURE_REVIEW.md` - Current status, gaps, roadmap
2. `docs/00-OVERVIEW.md` - Design vision and philosophy
3. `docs/01-CONTROL-STATIONS.md` - UI specification
4. `docs/IMPLEMENTATION_TODO.md` - Week-by-week development plan

## Architecture

```
physics-modules/     65+ physics simulation modules
game/                Browser-based 4-station UI
game-engine/         Complete game engine
universe-system/     Procedural generation
docs/                Comprehensive design documentation
```

## Key Features

**Physics Simulation:**
- Orbital mechanics (validated against NASA data, <0.1% error)
- Tsiolkovsky rocket equation
- 6-DOF dynamics with quaternion attitude
- Thermal management (Stefan-Boltzmann radiation)
- Life support (atmosphere, fire, crew)
- Damage and repair systems
- Sensors (radar, optical, ESM)
- Weapons and combat (optional)

**Gameplay:**
- Multi-station interface (Helm, Engineering, Navigation, Life Support)
- Procedural complexity (multi-step operations)
- Resource scarcity
- Emergent simulation
- Roguelike campaign structure

## Development Roadmap

**Next 5-6 weeks to MVP:**
- Week 1-2: Complete multi-station interface
- Week 3: Integrate life support fully
- Week 4: Campaign structure
- Week 5: Polish and balance

See `docs/IMPLEMENTATION_TODO.md` for detailed tasks.

## Testing

```bash
cd physics-modules
npm test

# Expected output:
# 45 passed, 0 failed (45 total)
# 🎉 All tests passed!
```

## Technology Stack

- **Language:** TypeScript
- **Physics:** Custom simulation engine
- **UI:** HTML5 + Vite (browser), Terminal (examples)
- **Build:** npm, TypeScript compiler
- **Testing:** Custom test runner

## Design Inspiration

- **FTL: Faster Than Light** - Campaign structure, multi-station gameplay
- **Out There** - Resource scarcity, exploration
- **Highfleet** - Esoteric controls, submarine aesthetic
- **DCS World / MS Flight Simulator** - Procedural complexity
- **Dwarf Fortress** - Deep simulation, emergent gameplay

## License

[TBD]

## Contributing

This project is currently in active development. See `MERGE_COMPLETE.md` for recent integration work.

## Credits

Developed with comprehensive physics modeling, extensive testing, and attention to detail.

**"Submarine in space" - Complex, realistic, and beautiful.**
EOF
```

### Step 4: Initialize and Commit
```bash
cd ~/vector-moon-lander

# Add all game files
git add .

# Create initial commit
git commit -m "Initial commit: Vector Moon Lander game

Complete spacecraft systems simulator with:
- 65+ physics modules (45/45 tests passing)
- Browser-based 4-station UI
- Terminal-based game examples
- Procedural universe generation
- Comprehensive documentation

Merged from 9 development branches:
- Physics foundation (35 modules)
- Browser UI (4 stations)
- Terrain and landing systems
- Enhanced life support with crew
- Architecture documentation
- Procedural generation
- Game engine

Total development time: ~500+ hours
Status: 50% complete, ready for MVP development

See MERGE_COMPLETE.md for full merge history."
```

### Step 5: Push to GitHub
```bash
# Add remote (replace USERNAME with your GitHub username)
git remote add origin https://github.com/USERNAME/vector-moon-lander.git

# Push to GitHub
git push -u origin main
```

---

## Option 2: Preserve Full History (Advanced)

This keeps the complete git history but requires filtering.

```bash
# Clone the repo to a new location
git clone /home/user/project-management-console ~/vector-moon-lander
cd ~/vector-moon-lander

# Checkout game-main
git checkout game-main

# Remove PMC-related files
git rm -r .pmc Handlers archive deps module screens tests tools ui
git rm *.ps1 pmc.ps1 Debug.ps1 DepsLoader.ps1 Pack-ConsoleUI.ps1 Start-ConsoleUI.ps1
git rm config.json tasks.json test-*.ps1 start.ps1 run-tui.sh start-pmc.ps1
git rm unused_files_backup.zip 2>/dev/null || true

# Commit cleanup
git commit -m "Remove PMC files, prepare for game repository"

# Remove PMC branches
git branch -D main 2>/dev/null || true
git branch | grep -v game-main | xargs git branch -D 2>/dev/null || true

# Rename game-main to main
git branch -m game-main main

# Add new remote
git remote remove origin
git remote add origin https://github.com/USERNAME/vector-moon-lander.git

# Push
git push -u origin main
```

---

## Option 3: Scripted Clean Extraction (Fastest)

```bash
#!/bin/bash
# save this as: extract-game.sh

GAME_DIR=~/vector-moon-lander
PMC_DIR=/home/user/project-management-console

# Create new directory
mkdir -p $GAME_DIR
cd $GAME_DIR
git init
git branch -m main

# Copy game directories
cd $PMC_DIR
git checkout game-main

for dir in physics-modules game game-engine universe-system docs; do
  if [ -d "$dir" ]; then
    cp -r "$dir" "$GAME_DIR/"
    echo "Copied $dir"
  fi
done

# Copy game markdown files
for file in *_DESIGN.md *_COMPLETE.md *_ANALYSIS.md MERGE_*.md BRANCH_*.md *_OVERVIEW.md *_REFERENCE.md *_STATUS.md WHAT_WORKS.md; do
  if [ -f "$file" ]; then
    cp "$file" "$GAME_DIR/"
    echo "Copied $file"
  fi
done

# Copy other game files
[ -f "index.html" ] && cp index.html "$GAME_DIR/"
[ -f ".gitignore" ] && cp .gitignore "$GAME_DIR/"

cd $GAME_DIR

# Create README (use README content from Step 3 above)

git add .
git commit -m "Initial commit: Vector Moon Lander game"

echo "Game extracted to: $GAME_DIR"
echo "Next steps:"
echo "1. cd $GAME_DIR"
echo "2. Create GitHub repository: vector-moon-lander"
echo "3. git remote add origin https://github.com/USERNAME/vector-moon-lander.git"
echo "4. git push -u origin main"
```

---

## After Migration: Clean Up PMC Repository

Once the game is safely in its own repository, clean up the PMC repo:

```bash
cd /home/user/project-management-console

# Checkout main
git checkout main

# Delete all game branches (DO THIS ONLY AFTER CONFIRMING GAME REPO IS PUSHED)
git branch -D game-main
git push origin --delete claude/vector-moon-lander-game-01Cx4P7A34QkDZ5YiDJwLL3M
git push origin --delete claude/game-ui-stations-01YbLPRtFn8vZ3KhXcszYzRc
git push origin --delete claude/add-spacecraft-subsystems-01Jz9rUfi9CMWBWaMz2yRFwi
git push origin --delete claude/review-game-design-01K23pP92gfUtcpS3KtxfgGS
git push origin --delete claude/review-game-implementation-01LdtPX8AMrZ2pRXCZo47A7j
git push origin --delete claude/review-game-docs-01Qx3EUPRkrgxrxTij3QRHnE
git push origin --delete claude/universe-generator-01XrLN8VFxdDqCS7dMffGY34
git push origin --delete claude/improve-physics-01AE7VR31GFxb29ziCYrrgG7
git push origin --delete claude/review-ui-fix-integration-01YbLPRtFn8vZ3KhXcszYzRc

# Remove BRANCH_MERGE_ANALYSIS.md if present in main
git rm BRANCH_MERGE_ANALYSIS.md 2>/dev/null || true
git commit -m "Remove game branch analysis (moved to game repo)" || true
```

---

## Verification Checklist

After moving to new repository:

### In New Game Repository
- [ ] All physics modules present (65+ .ts files in physics-modules/src/)
- [ ] Tests pass: `cd physics-modules && npm test` (45/45)
- [ ] Game UI present: `game/` directory with 4 panels
- [ ] Documentation complete: `docs/` with all .md files
- [ ] Examples work: `physics-modules/examples/`
- [ ] Game engine present: `game-engine/`
- [ ] Universe system present: `universe-system/`
- [ ] README.md created with project info
- [ ] .gitignore appropriate for TypeScript/Node project
- [ ] No PMC files (no .ps1, no pmc.ps1, no module/, etc.)

### In PMC Repository
- [ ] Main branch clean (only PMC files)
- [ ] No game branches remaining
- [ ] No game files in main
- [ ] PMC functionality intact

---

## Recommended Approach

**I recommend Option 1 (Clean Extraction)** because:
- ✅ Clean git history starting fresh
- ✅ No PMC remnants
- ✅ Smaller repository size
- ✅ Clear separation of concerns
- ✅ Easy to understand

Option 2 preserves full history but includes PMC commits (confusing).
Option 3 is just a scripted version of Option 1.

---

## Next Steps After Migration

1. **Verify tests pass** in new repository
2. **Update documentation** with new repository URLs
3. **Set up CI/CD** (GitHub Actions for tests)
4. **Create initial release** (v0.5.0-alpha or similar)
5. **Continue development** following `docs/IMPLEMENTATION_TODO.md`

---

**Migration Status:** Ready to proceed
**Recommendation:** Use Option 1 (Clean Extraction)
**Time Required:** 15-20 minutes

