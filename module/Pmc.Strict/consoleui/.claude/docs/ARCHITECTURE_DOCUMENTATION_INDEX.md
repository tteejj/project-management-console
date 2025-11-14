# PMC TUI Architecture Documentation Index

**Created**: November 13, 2025
**Purpose**: Index and guide to all architecture documentation
**Audience**: Developers working on PMC TUI codebase

---

## Documentation Files

### 1. PMC_ARCHITECTURE_ANALYSIS.md (41 KB, 1,279 lines)

**Comprehensive deep-dive** into all architectural aspects.

**Contents**:
- Executive summary
- Complete directory structure with annotations
- Initialization flow and entry points
- 5 major architectural patterns explained
- Detailed class relationships and hierarchies
- UI/rendering system architecture
- Input handling and keyboard management
- Configuration and state management
- Dependency injection patterns
- Module organization and boundaries
- Test coverage assessment
- Design patterns used (creational, structural, behavioral)
- Performance optimizations (6 areas)
- Known limitations and future work
- Critical success factors
- Architecture decisions explained
- Summary and recommendations

**Best for**:
- Understanding complete architecture
- Deep learning of design patterns
- Reference guide for complex interactions
- Detailed class relationships
- Performance optimization understanding

**Reading time**: 45-60 minutes for complete read

### 2. ARCHITECTURE_QUICK_REFERENCE.md (13 KB, 300+ lines)

**Quick lookup guide** for common questions and tasks.

**Contents**:
- Quick statistics and metrics
- Directory structure quick map
- 12-step initialization sequence
- 4 core architectural patterns with code examples
- Key classes at a glance (tables)
- Rendering pipeline (visual)
- Input handling pipeline (visual)
- ServiceContainer dependency graph
- How to add a new screen (step-by-step)
- Performance tips and optimization table
- Common development tasks (6 examples with code)
- Architecture decision summary (table)
- 8 debugging quick tips
- File organization best practices
- Key files to study first

**Best for**:
- Quick lookups
- Common development tasks
- Debugging issues
- Adding new screens
- Performance optimization

**Reading time**: 10-15 minutes for lookup, 30 minutes for complete read

### 3. ARCHITECTURE_DECISIONS.md (already exists)

**Rationale** for 10 key architecture decisions.

**Explains**:
1. Hybrid DI + Globals Pattern
2. PowerShell Classes vs Functions
3. Thread Safety Approach
4. Logging Disabled by Default
5. Dual Constructor Pattern
6. Three Service Access Patterns
7. Hidden Fields for Encapsulation
8. Testing Strategy
9. Error Handling Philosophy
10. Performance vs Purity Trade-offs

**Best for**:
- Understanding design philosophy
- Learning rationale behind decisions
- Evaluating trade-offs
- Contributing with aligned decisions

---

## Documentation Map

### For Different Scenarios

**I'm new to the codebase, where do I start?**
1. Read: ARCHITECTURE_DECISIONS.md (understand philosophy)
2. Read: ARCHITECTURE_QUICK_REFERENCE.md (overview)
3. Study: PmcScreen.ps1 (foundation)
4. Study: TaskListScreen.ps1 (complete example)
5. Read: PMC_ARCHITECTURE_ANALYSIS.md (details)

**I need to add a new screen**
1. Check: ARCHITECTURE_QUICK_REFERENCE.md → "How to Add a New Screen"
2. Study: TaskListScreen.ps1 (similar screen example)
3. Study: StandardListScreen.ps1 (base class)
4. Read: SCREEN_PATTERNS.md (implementation patterns)

**I'm debugging a rendering issue**
1. Check: ARCHITECTURE_QUICK_REFERENCE.md → "Debugging Quick Tips"
2. Read: PMC_ARCHITECTURE_ANALYSIS.md → Section 5 (Rendering)
3. Study: PmcApplication.ps1 → _RenderCurrentScreen method
4. Enable logging: Start-PmcTUI -DebugLog -LogLevel 3

**I need to understand the event loop**
1. Check: ARCHITECTURE_QUICK_REFERENCE.md → "Rendering Pipeline"
2. Read: PMC_ARCHITECTURE_ANALYSIS.md → Section 3.5 (Input Handling)
3. Study: PmcApplication.ps1 → Run method
4. Study: PmcScreen.ps1 → HandleKeyPress method

**I want to optimize performance**
1. Check: ARCHITECTURE_QUICK_REFERENCE.md → "Performance Tips"
2. Read: PMC_ARCHITECTURE_ANALYSIS.md → Section 12 (Performance)
3. Study: ARCHITECTURE_DECISIONS.md → ADR-004 (Logging)
4. Profile: Enable logging, measure, disable logging

**I need to understand the data model**
1. Check: ARCHITECTURE_QUICK_REFERENCE.md → "ServiceContainer Dependency Graph"
2. Read: PMC_ARCHITECTURE_ANALYSIS.md → Section 3.3 (Observable Data)
3. Study: TaskStore.ps1 (complete implementation)
4. Study: TaskListScreen.ps1 → _InitializeComponents method

**I'm adding a new widget**
1. Read: WIDGET_CONTRACTS.md (widget API reference)
2. Study: UniversalList.ps1 or TextInput.ps1 (similar widget)
3. Check: ARCHITECTURE_QUICK_REFERENCE.md → File Organization
4. Reference: PmcWidget.ps1 (base class)

---

## Quick Reference Tables

### 10-Minute Overview

| Topic | File | Section |
|-------|------|---------|
| **What is PMC TUI?** | ARCH_ANALYSIS | Executive Summary |
| **How does it start?** | QUICK_REF | Initialization Sequence |
| **Key classes?** | QUICK_REF | Key Classes at a Glance |
| **How do screens work?** | ARCH_DECISIONS | ADR-005, ADR-006 |
| **Data persistence?** | ARCH_ANALYSIS | Section 7.3 |
| **How fast is it?** | ARCH_ANALYSIS | Section 12 |
| **What's broken?** | ARCH_ANALYSIS | Section 13 |

### Learning Paths

**Path 1: Architecture Overview (2 hours)**
1. ARCHITECTURE_DECISIONS.md (30 min)
2. ARCHITECTURE_QUICK_REFERENCE.md (20 min)
3. PMC_ARCHITECTURE_ANALYSIS.md - Skim (30 min)
4. Study PmcScreen.ps1 (15 min)
5. Study Start-PmcTUI.ps1 (15 min)

**Path 2: Building Skills (4 hours)**
1. Complete Path 1
2. Study TaskListScreen.ps1 (30 min)
3. Study StandardListScreen.ps1 (20 min)
4. Study UniversalList.ps1 (30 min)
5. Study TaskStore.ps1 (30 min)
6. Read WIDGET_CONTRACTS.md (15 min)
7. Do "How to Add a New Screen" exercise (30 min)

**Path 3: Performance & Optimization (3 hours)**
1. ARCHITECTURE_QUICK_REFERENCE.md → Performance Tips (10 min)
2. PMC_ARCHITECTURE_ANALYSIS.md → Section 12 (30 min)
3. ARCHITECTURE_DECISIONS.md → ADR-004, ADR-010 (20 min)
4. Study ConfigCache.ps1 (15 min)
5. Study OptimizedRenderEngine (SpeedTUI/Core/) (20 min)
6. Enable logging and profile (30 min)
7. Implement optimization (1 hour)

**Path 4: Advanced Patterns (5 hours)**
1. Complete Path 2
2. PMC_ARCHITECTURE_ANALYSIS.md → Section 11 (Design Patterns) (30 min)
3. Study ServiceContainer.ps1 (20 min)
4. Study MenuRegistry.ps1 (15 min)
5. Study all widget files (1.5 hours)
6. Do "Add a Widget" exercise (1 hour)
7. Do "Add a Service" exercise (1 hour)

---

## File Statistics

| File | Size | Lines | Type | Created |
|------|------|-------|------|---------|
| PMC_ARCHITECTURE_ANALYSIS.md | 41 KB | 1,279 | Comprehensive | 2025-11-13 |
| ARCHITECTURE_QUICK_REFERENCE.md | 13 KB | 380 | Quick Guide | 2025-11-13 |
| ARCHITECTURE_DECISIONS.md | ~20 KB | 557 | Decision Records | Existing |
| SCREEN_PATTERNS.md | - | - | Patterns | Existing |
| WIDGET_CONTRACTS.md | - | - | API Reference | Existing |
| INTEGRATION_POINTS.md | - | - | Integration | Existing |
| COMMON_FIXES.md | - | - | Fixes | Existing |

**Total Documentation**: 2,600+ lines of architecture guides

---

## Key Insights Summary

### Architecture Quality: 8/10

**Strengths**:
- Clear 5-layer separation (presentation, widgets, services, infrastructure, framework)
- Professional PowerShell OOP (87+ classes)
- Well-designed base classes (StandardListScreen, StandardFormScreen)
- Performance-optimized (30-40% CPU reduction)
- Observable event-driven data model
- Pragmatic design decisions (documented in ADR format)

**Weaknesses**:
- No automated tests (manual only)
- Global variables (pragmatic but not enterprise)
- Hidden fields make debugging harder
- Mixed error handling approach
- Logging disabled by default (impacts troubleshooting)

---

## Common Questions

**Q: How do I understand the event loop?**
A: Start with ARCHITECTURE_QUICK_REFERENCE.md "Rendering Pipeline", then read PMC_ARCHITECTURE_ANALYSIS.md Section 3.5 "Input Handling Flow", then study PmcApplication.ps1 Run() method.

**Q: How do I add a new screen?**
A: Follow ARCHITECTURE_QUICK_REFERENCE.md "How to Add a New Screen" (3 steps), using TaskListScreen.ps1 as example.

**Q: Why doesn't my widget render?**
A: Check ARCHITECTURE_QUICK_REFERENCE.md "Debugging Quick Tips", enable logging with `-DebugLog -LogLevel 3`, and verify RenderToEngine() or Render() method.

**Q: How do I subscribe to data changes?**
A: Study TaskListScreen.ps1 around line 135-150, use `.GetNewClosure()` pattern, subscribe to TaskStore.OnTasksChanged event.

**Q: Is this production-ready?**
A: Yes for personal use (single-user tool), requires refactoring if shipping as library (add tests, pure DI, better error handling).

**Q: What's the biggest issue?**
A: No automated tests (116,000 lines with manual testing only) - biggest gap for long-term maintainability.

---

## Next Steps for Developers

1. **Read**: ARCHITECTURE_DECISIONS.md (philosophy)
2. **Understand**: ARCHITECTURE_QUICK_REFERENCE.md (overview)
3. **Study**: Core classes (PmcScreen, PmcApplication, TaskStore)
4. **Practice**: Add a new screen using the guide
5. **Deep Dive**: Read PMC_ARCHITECTURE_ANALYSIS.md as needed

---

## Contributing Guidelines

When working on PMC TUI:

1. ✅ Understand architecture first (read relevant section)
2. ✅ Follow existing patterns (study similar code)
3. ✅ Use dual constructors for screens (legacy + DI)
4. ✅ Subscribe to data changes with .GetNewClosure()
5. ✅ Enable logging when debugging (-DebugLog -LogLevel 3)
6. ✅ Check similar screens for regressions
7. ✅ Update documentation if patterns change

---

## Resources

**In this directory (.claude/docs/)**:
- ARCHITECTURE_ANALYSIS.md - This file
- ARCHITECTURE_QUICK_REFERENCE.md - Quick lookup guide
- ARCHITECTURE_DECISIONS.md - Design decision rationale
- SCREEN_PATTERNS.md - Screen implementation patterns
- WIDGET_CONTRACTS.md - Widget API reference
- INTEGRATION_POINTS.md - Service integration patterns
- COMMON_FIXES.md - Recurring issues and solutions
- REGRESSION_CHECKLIST.md - Testing checklist

**Code Examples**:
- /screens/TaskListScreen.ps1 (1179 lines - complete example)
- /screens/ProjectListScreen.ps1 (609 lines - list example)
- /base/StandardListScreen.ps1 (300+ lines - base class)
- /widgets/UniversalList.ps1 (400+ lines - widget example)
- /services/TaskStore.ps1 (600+ lines - observable data)

---

**Documentation Index Version**: 1.0
**Last Updated**: 2025-11-13
**Status**: Complete - 2,600+ lines across 4 guides

For questions or additions, refer to the main documentation files or existing code examples.
