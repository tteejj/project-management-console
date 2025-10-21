# View Migration Analysis - Complete Documentation

## What This Is

A comprehensive analysis of 4 view methods in ConsoleUI.Core.ps1 that need to be migrated to Screen classes. All methods have been analyzed and documented in detail.

## The 4 Views Being Analyzed

1. **DrawTodayView** (Lines 4163-4241)
   - Shows tasks due today and overdue tasks
   - 2-section list view
   - Uses priority-based coloring

2. **DrawWeekView** (Lines 3905-3983)
   - Shows tasks due this week and overdue tasks
   - 2-section list view
   - Similar to TodayView but different date range

3. **DrawOverdueView** (Lines 4243-4288)
   - Shows only overdue tasks
   - Single flat list
   - Multi-part line rendering

4. **DrawKanbanView** (Lines 4336-4593)
   - Shows tasks organized in 3 columns by status
   - Complex board view with custom event loop
   - Most challenging to migrate

## Documentation Files

### 1. VIEW_MIGRATION_INDEX.md ⭐ START HERE
Master index that guides you through all documentation. Includes:
- Document descriptions
- Reading guides for different tasks
- Quick navigation paths
- FAQ section

### 2. MIGRATION_SUMMARY.txt (7.4K)
Executive overview. Read this first (5 minutes). Contains:
- Key findings summary
- 4-phase migration strategy
- Complexity assessment
- Common patterns overview
- Next steps

### 3. VIEW_MIGRATION_ANALYSIS.md (12K)
Deep technical analysis. Read this when implementing. Contains:
- Filtering logic for each view (with code)
- Rendering approach details
- Navigation/interaction patterns
- State management
- Technical notes
- Complete migration checklist

### 4. VIEW_QUICK_REFERENCE.md (6.4K)
Quick lookup tables. Keep this open while coding. Contains:
- Side-by-side comparison table
- Filtering patterns summary
- Task rendering formats (visual examples)
- Input key bindings
- State variables
- Critical notes

### 5. VIEW_CODE_SNIPPETS.md (15K)
Copy-paste ready code templates. Reference this while coding. Contains:
- Filtering templates (copy-paste ready)
- Rendering pattern examples (complete code)
- Selection checking patterns
- Multi-part rendering
- KanbanView-specific patterns
- Date formatting patterns

### 6. ANALYSIS_CHECKLIST.md
Verification that all analysis is complete. Lists:
- Views analyzed
- Documentation generated
- Analysis checklist for each view
- Common patterns documented
- Code examples provided
- Quality verification

### 7. README_ANALYSIS.md (This File)
Overview of what's been analyzed and where to find information.

## How to Use This Documentation

### If you have 5 minutes:
Read `MIGRATION_SUMMARY.txt` for the big picture

### If you're implementing a specific view:
1. Find your view in `VIEW_QUICK_REFERENCE.md` (quick facts)
2. Read detailed analysis in `VIEW_MIGRATION_ANALYSIS.md`
3. Copy code from `VIEW_CODE_SNIPPETS.md`

### If you forgot a detail:
1. Use `VIEW_QUICK_REFERENCE.md` for quick lookup
2. Check `VIEW_CODE_SNIPPETS.md` for pattern examples
3. Refer back to `VIEW_MIGRATION_ANALYSIS.md` for context

### If you're starting the migration:
1. Read `VIEW_MIGRATION_INDEX.md` (master guide)
2. Read `MIGRATION_SUMMARY.txt` (overview)
3. Choose OverdueView first (Phase 1 - simplest)
4. Reference other docs as needed

## Recommended Migration Order

1. **Phase 1: DrawOverdueView** (Start here)
   - Simplest: single filter, single list
   - Teaches basic patterns
   - Difficulty: Very Low

2. **Phase 2: DrawTodayView**
   - Two-section filtering
   - Priority-based coloring
   - Difficulty: Low

3. **Phase 3: DrawWeekView**
   - Similar to TodayView
   - Different date range
   - Difficulty: Low

4. **Phase 4: DrawKanbanView** (Do last)
   - Most complex
   - Custom event loop
   - 2D selection state
   - Difficulty: High

## Key Information by Topic

### Date Filtering
**Location:** VIEW_CODE_SNIPPETS.md > "TodayView Filtering Template"
See how to safely parse dates and compare them.

### Rendering
**Location:** VIEW_CODE_SNIPPETS.md > "Common Rendering Patterns"
See exact coordinates, colors, and formatting.

### Selection/Navigation
**Location:** VIEW_QUICK_REFERENCE.md > "Input Handling"
See all key bindings and how to handle them.

### State Management
**Location:** VIEW_QUICK_REFERENCE.md > "State Management"
See what variables to track for each view.

### Kanban Specifics
**Location:** VIEW_CODE_SNIPPETS.md > "KanbanView Specific Patterns"
See the unique event loop and column handling.

### Visual Examples
**Location:** VIEW_QUICK_REFERENCE.md > "Task Rendering Formats"
See visual mockups of how each view looks.

## File Statistics

- Total Documentation: ~57KB across 7 files
- Code Examples: 50+
- Visual Examples: 4+
- Filtering Templates: 5
- Common Patterns: 15+
- Source Code Analyzed: 8836 lines

## Source File

All original methods are in: `/home/teej/pmc/ConsoleUI.Core.ps1`

| View | Lines | Complexity |
|------|-------|-----------|
| DrawOverdueView | 4243-4288 | Very Low |
| DrawTodayView | 4163-4241 | Low |
| DrawWeekView | 3905-3983 | Low |
| DrawKanbanView | 4336-4593 | High |

## What's Documented for Each View

For every view, this analysis includes:

- **Filtering Logic**
  - Exact Where-Object clauses
  - Date comparison rules
  - Status conditions

- **Rendering Approach**
  - Layout structure (list vs board)
  - Colors for each element
  - Text formatting
  - Position coordinates

- **Input Handling**
  - Keyboard shortcuts
  - Navigation patterns
  - Event processing

- **State Management**
  - Variables to track
  - Selection mechanism
  - Scroll position (if applicable)

- **Helper Functions**
  - Functions called
  - Data structures used
  - Error handling

## Next Steps

1. Read `VIEW_MIGRATION_INDEX.md` to understand the documentation structure
2. Read `MIGRATION_SUMMARY.txt` for an overview (5 minutes)
3. Choose OverdueView as your first implementation (Phase 1)
4. Use `VIEW_QUICK_REFERENCE.md` for quick lookup while implementing
5. Copy code templates from `VIEW_CODE_SNIPPETS.md`
6. Reference `VIEW_MIGRATION_ANALYSIS.md` for detailed information

## Questions?

Most questions are answered in the FAQ section of `VIEW_MIGRATION_INDEX.md`

Common topics:
- Which view should I implement first? -> OverdueView (Phase 1)
- Why is KanbanView different? -> It has its own event loop
- Can I copy code directly? -> Yes, use VIEW_CODE_SNIPPETS.md
- How do I handle dates? -> Use Get-ConsoleUIDateOrNull helper

## Version Info

- Analysis Date: 2024-10-18
- Source File: ConsoleUI.Core.ps1 (8836 lines)
- Methods Analyzed: 4
- Documentation Files: 7
- Total Size: ~57KB

---

**Status: ANALYSIS COMPLETE AND VERIFIED**

All documentation is ready for implementation. Start with `VIEW_MIGRATION_INDEX.md`.
