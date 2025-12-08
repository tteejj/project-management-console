# PMC TUI Documentation

This directory contains comprehensive documentation for maintaining and extending the PMC TUI.

## Document Index

### Core Architecture
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System overview, core components, rendering flow, and navigation patterns
  - PmcScreen base class
  - PmcApplication controller
  - Screen types (Menu, Form, List)
  - Widget system overview
  - Service layer overview

### Implementation Patterns
- **[SCREEN_PATTERNS.md](SCREEN_PATTERNS.md)** - Standard patterns for implementing screens
  - Menu screen pattern
  - Form screen pattern
  - List screen pattern
  - Parent method call pattern
  - State passing pattern
  - Anti-patterns to avoid

### Problem Solving
- **[COMMON_FIXES.md](COMMON_FIXES.md)** - Recurring issues and proven solutions
  - Menu cursor issues
  - Form input issues
  - Data persistence issues
  - Navigation issues
  - Rendering issues
  - List/UniversalList issues
  - Regression prevention checklist

### Widget Reference
- **[WIDGET_CONTRACTS.md](WIDGET_CONTRACTS.md)** - Detailed widget API documentation
  - UniversalList
  - TextInput
  - FilterPanel
  - ProjectPicker
  - InlineEditor
  - Widget integration patterns
  - Common widget mistakes

### Service Integration
- **[INTEGRATION_POINTS.md](INTEGRATION_POINTS.md)** - Service contracts and integration patterns
  - TaskStore service
  - PreferencesService
  - ExcelComReader
  - Application state
  - Screen-to-screen communication
  - Common integration patterns

### Regression Prevention
- **[REGRESSION_CHECKLIST.md](REGRESSION_CHECKLIST.md)** - Change impact analysis and testing
  - Change impact matrix
  - Screen groupings for testing
  - Pre-commit checklist
  - Regression testing scenarios
  - Known fragile areas

---

## Quick Reference

### When You Need To...

**Implement a new menu screen:**
→ See [SCREEN_PATTERNS.md - Menu Screen Pattern](SCREEN_PATTERNS.md#1-menu-screen-pattern)

**Implement a new form screen:**
→ See [SCREEN_PATTERNS.md - Form Screen Pattern](SCREEN_PATTERNS.md#2-form-screen-pattern)

**Implement a new list screen:**
→ See [SCREEN_PATTERNS.md - List Screen Pattern](SCREEN_PATTERNS.md#3-list-screen-pattern-extends-standardlistscreen)

**Fix a cursor navigation bug:**
→ See [COMMON_FIXES.md - Menu Cursor Issues](COMMON_FIXES.md#menu-cursor-issues)

**Integrate a widget:**
→ See [WIDGET_CONTRACTS.md - Widget Design Principles](WIDGET_CONTRACTS.md#widget-design-principles)

**Save/load task data:**
→ See [INTEGRATION_POINTS.md - TaskStore Service](INTEGRATION_POINTS.md#taskstore-service)

**Check impact of a change:**
→ See [REGRESSION_CHECKLIST.md - Change Impact Matrix](REGRESSION_CHECKLIST.md#change-impact-matrix)

**Understand base classes:**
→ See [ARCHITECTURE.md - Core Components](ARCHITECTURE.md#core-components)

---

## Documentation Philosophy

These docs are designed to be:

1. **Practical** - Show actual code patterns, not abstract theory
2. **Searchable** - Organized by problem domain, not alphabetically
3. **Prescriptive** - Clear dos and don'ts, not "it depends"
4. **Comprehensive** - Cover the full lifecycle of features
5. **Maintained** - Updated as patterns evolve

---

## For AI Assistants

When working on PMC TUI code:

1. **Read docs before coding** - Understand patterns first
2. **Follow established patterns** - Don't reinvent
3. **Check regression checklist** - Understand impact before changes
4. **Reference common fixes** - Don't repeat solved problems
5. **Update docs if you discover new patterns** - Keep knowledge current

### Recommended Reading Order for New Tasks

1. **ARCHITECTURE.md** - Understand system structure
2. **SCREEN_PATTERNS.md** - Learn standard patterns
3. **WIDGET_CONTRACTS.md** - Understand widget APIs (if working with widgets)
4. **INTEGRATION_POINTS.md** - Learn service integration (if working with data)
5. **REGRESSION_CHECKLIST.md** - Check impact before making changes
6. **COMMON_FIXES.md** - Reference when debugging issues

---

## Contributing to Documentation

When you discover:
- **New patterns** → Add to SCREEN_PATTERNS.md
- **New bugs and fixes** → Add to COMMON_FIXES.md
- **Widget behavior** → Update WIDGET_CONTRACTS.md
- **Service changes** → Update INTEGRATION_POINTS.md
- **New regression scenarios** → Add to REGRESSION_CHECKLIST.md

Keep docs synchronized with code!

---

## Status: Initial Version

These docs represent the initial documentation pass. Areas marked "To Be Documented" need further investigation and documentation.

**Next Steps:**
1. Deep codebase analysis to verify and expand details
2. Fill in "To Be Documented" sections
3. Add code examples from actual screens
4. Create testing guides
5. Add troubleshooting flowcharts

**Feedback:** As you use these docs, note:
- Incorrect information
- Missing patterns
- Unclear explanations
- Additional areas needing documentation

Update as you learn!
