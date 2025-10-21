# View Migration Documentation Index

## Quick Start

You have 4 comprehensive documents to guide the migration of view methods to Screen classes:

### 1. MIGRATION_SUMMARY.txt
**Best for:** High-level overview and quick reference
- Executive summary of all findings
- 4-phase migration strategy (ordered by complexity)
- Key findings summary
- File locations and next steps
- **Start here if you want the big picture**

### 2. VIEW_MIGRATION_ANALYSIS.md
**Best for:** Deep understanding of each view's implementation
- Detailed analysis of each view method (DrawTodayView, DrawWeekView, DrawOverdueView, DrawKanbanView)
- Filtering logic for each view with code examples
- Rendering approach and visual layout
- Navigation/interaction patterns
- Common patterns across all views
- Complete migration checklist
- **Read this when implementing a specific view**

### 3. VIEW_QUICK_REFERENCE.md
**Best for:** Quick lookup during implementation
- Side-by-side comparison table of all 4 views
- Filtering patterns summary
- Task rendering format examples (visual)
- Input handling key bindings
- State management variables
- Critical implementation notes
- Migration strategy phases
- **Keep this open while coding**

### 4. VIEW_CODE_SNIPPETS.md
**Best for:** Copy-paste ready code templates
- Common filtering helpers
- TodayView/WeekView/OverdueView filtering templates
- KanbanView status grouping template
- Common rendering patterns (title, headers, selection, etc.)
- Multi-part line rendering example
- Footer rendering examples
- Empty state examples
- KanbanView-specific patterns (borders, scrolling, input, focus)
- Date formatting patterns
- **Copy these snippets as starting points for your Screen classes**

---

## Reading Guide by Task

### "I need to understand what I'm migrating"
1. Start: MIGRATION_SUMMARY.txt (5 min)
2. Then: VIEW_MIGRATION_ANALYSIS.md (30 min)
3. Reference: VIEW_QUICK_REFERENCE.md (as needed)

### "I'm implementing DrawTodayView Screen class"
1. Start: VIEW_QUICK_REFERENCE.md (find TodayView row)
2. Then: VIEW_MIGRATION_ANALYSIS.md (Section 1)
3. Copy templates from: VIEW_CODE_SNIPPETS.md (TodayView Filtering Template + Common Rendering Patterns)
4. Verify: Use migration checklist from VIEW_MIGRATION_ANALYSIS.md

### "I'm implementing DrawKanbanView Screen class"
1. Start: VIEW_QUICK_REFERENCE.md (find KanbanView row)
2. Then: VIEW_MIGRATION_ANALYSIS.md (Section 4)
3. Copy patterns from: VIEW_CODE_SNIPPETS.md (all KanbanView Specific Patterns sections)
4. Note: KanbanView has unique event loop - read "KanbanView Uses Own Event Loop" carefully

### "I forgot how date filtering works"
1. Go to: VIEW_CODE_SNIPPETS.md
2. Find: "TodayView Filtering Template" or "WeekView Filtering Template"
3. Or reference: "Date Handling" under Common Patterns

### "I need the exact colors and positions"
1. Go to: VIEW_QUICK_REFERENCE.md (Task Rendering Formats section)
2. Visual examples show exact layout and colors
3. Reference: VIEW_CODE_SNIPPETS.md (Common Rendering Patterns)

### "What's the difference between these views?"
1. Go to: VIEW_QUICK_REFERENCE.md
2. See: Side-by-side comparison table at top
3. Or: MIGRATION_SUMMARY.txt (KEY FINDINGS SUMMARY section)

---

## Source Code Locations

All original methods are in: **/home/teej/pmc/ConsoleUI.Core.ps1**

| View | Lines | Complexity |
|------|-------|-----------|
| DrawTodayView | 4163-4241 | Low |
| DrawWeekView | 3905-3983 | Low |
| DrawOverdueView | 4243-4288 | Very Low |
| DrawKanbanView | 4336-4593 | High |

---

## Recommended Migration Order

1. **Phase 1: DrawOverdueView** (simplest)
   - Single filter: due date < today
   - Single list: no grouping
   - Multi-part line rendering
   - Good foundation for understanding selection mechanism

2. **Phase 2: DrawTodayView**
   - Two filters: overdue + today
   - Priority-based coloring
   - Tests filtering logic reusability

3. **Phase 3: DrawWeekView**
   - Similar to TodayView but different date range
   - Tests parameter-driven filtering
   - Almost identical to TodayView implementation

4. **Phase 4: DrawKanbanView** (most complex)
   - Custom event loop (different pattern!)
   - 2D selection state (column + row)
   - Per-column scrolling
   - Focus-after-update tracking
   - DO THIS LAST - it's very different

---

## Key Concepts to Understand

### For List Views (Today, Week, Overdue)
- **Filtering:** Combine multiple Where-Object clauses on $data.tasks
- **Rendering:** Loop through filtered tasks with Y counter
- **Selection:** Use `$this.specialSelectedIndex` to track current selection
- **State:** `$this.specialItems` holds the complete filtered list

### For Kanban View
- **Grouping:** Tasks organized into 3 columns by status
- **Selection:** 2D (column index 0-2, row index within column)
- **Scrolling:** Each column has independent scroll position
- **Event Loop:** Own while() loop with [Console]::ReadKey($true)
- **Focus:** After moving tasks, use focusTaskId/focusCol to re-highlight

### Universal Patterns
- Date parsing always via: `Get-ConsoleUIDateOrNull`
- Date comparison always on: `.Date` property (no time)
- Frame always: `BeginFrame()` ... `EndFrame()`
- Title always: Y=3 centered
- Content always: Y=6+ 
- Footer always: Last line
- Colors: Via `[PmcVT100]::` class methods

---

## File Cross-References

### MIGRATION_SUMMARY.txt contains links to:
- Specific line numbers in source file
- Document names and locations
- Recommended reading order

### VIEW_MIGRATION_ANALYSIS.md contains:
- Complete code examples
- Visual descriptions of rendering
- Technical deep-dives
- Complete migration checklist

### VIEW_QUICK_REFERENCE.md contains:
- Visual examples of output
- Input key bindings
- State variable names
- Critical notes about each view

### VIEW_CODE_SNIPPETS.md contains:
- Ready-to-use templates
- Copy-paste ready code
- Detailed inline comments
- Full examples of complex patterns

---

## Common Questions Answered

### Q: Where do I start?
A: Read MIGRATION_SUMMARY.txt first (5 min), then dive into the specific view analysis

### Q: Which view should I implement first?
A: OverdueView - it's the simplest and will teach you the basics

### Q: How is KanbanView different?
A: It has its own event loop. All others return control to main ConsoleUI loop. See VIEW_MIGRATION_ANALYSIS.md Section 4.

### Q: What about error handling?
A: Use Show-InfoMessage for user feedback and Save-PmcData for persistence. See examples in VIEW_CODE_SNIPPETS.md

### Q: How do I handle dates?
A: Always use Get-ConsoleUIDateOrNull and compare using .Date property. See "Date Handling" in VIEW_CODE_SNIPPETS.md

### Q: What state variables do I need?
A: For list views: `$this.specialSelectedIndex` + `$this.specialItems`. For Kanban: `$selectedCol`, `$selectedRow`, `$kbColSc[]`. See VIEW_QUICK_REFERENCE.md

### Q: Can I copy code directly?
A: Yes! VIEW_CODE_SNIPPETS.md has templates you can copy. Adapt the variable names to your Screen class structure.

---

## Version Information

- Analysis Date: 2024-10-18
- Source File: ConsoleUI.Core.ps1 (8836 lines)
- Methods Analyzed: 4 (DrawTodayView, DrawWeekView, DrawOverdueView, DrawKanbanView)
- Total Documentation: ~41KB across 4 files

---

## Document Statistics

| Document | Size | Focus |
|----------|------|-------|
| MIGRATION_SUMMARY.txt | 7.4K | Overview & strategy |
| VIEW_MIGRATION_ANALYSIS.md | 12K | Deep analysis |
| VIEW_QUICK_REFERENCE.md | 6.4K | Quick lookup |
| VIEW_CODE_SNIPPETS.md | 15K | Code templates |
| **TOTAL** | **~41K** | Complete guide |

---

Last updated: 2024-10-18
Location: /home/teej/pmc/
