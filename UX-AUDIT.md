# FakeTUI UX/UI Audit & Improvement Recommendations

## Critical Issues (Fix Now)

### 1. **No Visual Feedback for Menu Selection**
**Problem**: When you navigate menus with arrow keys, there's no clear indicator of which item is selected.
**Impact**: Users can't tell where they are in the menu.
**Fix**: Add background highlight or `▶` indicator for selected menu item.
```powershell
# Current: All items look the same
# Fix: Selected item gets different color or prefix
$indicator = if ($selected) { "▶ " } else { "  " }
```

### 2. **Task List: No Selection Indicator**
**Problem**: In tasklist view, no visual indicator shows which task is selected.
**Impact**: Users press keys and don't know which task will be affected.
**Fix**: Add cursor/highlight to selected task.
```powershell
$indicator = if ($i -eq $this.selectedTaskIndex) { "→ " } else { "  " }
```

### 3. **No Status Bar**
**Problem**: No persistent status bar showing current mode, filters, or available keys.
**Impact**: Users forget what keys do what, what mode they're in.
**Fix**: Add bottom status bar with context-sensitive help.
```powershell
# Bottom line always shows:
# [Tasklist] Filter: @project | Sort: priority | ? for help | F10 menu
```

### 4. **Statistics/Velocity Show Wrong Numbers**
**Problem**: The mock data causes 200% completion (counting tasks twice?).
**Impact**: Charts and stats are confusing/wrong.
**Fix**: Review the counting logic in DrawStatistics, DrawVelocity, DrawBurndownChart.

### 5. **No Confirmation Messages**
**Problem**: After adding/editing/deleting, no success message shown.
**Impact**: Users don't know if action worked.
**Fix**: Flash green success message for 1 second after successful operations.

## High Priority (Significant UX Issues)

### 6. **Search Form Doesn't Show Current Search**
**Problem**: When in search mode, can't see what you're searching for.
**Fix**: Show search box with current term at top of screen.

### 7. **No Undo Indicator**
**Problem**: Undo/Redo implemented but no feedback about what was undone.
**Fix**: Show "↶ Undone: [action]" message after undo.

### 8. **Task Detail View Missing Key Info**
**Problem**: Task detail doesn't show creation date, last modified, completed date.
**Fix**: Add metadata section to task detail view.

### 9. **No Quick Task Complete**
**Problem**: To complete a task, need to press Enter → navigate detail → mark done.
**Fix**: Space bar in task list should toggle complete/active (ALREADY EXISTS, needs better documentation).

### 10. **Project Filter Not Visible**
**Problem**: When filtered by project, no indicator shows you're in filtered mode.
**Fix**: Show "[Filter: @ProjectName]" in status bar or header.

## Medium Priority (Usability Improvements)

### 11. **Help System Not Searchable**
**Problem**: Help search form exists but doesn't actually search help content.
**Fix**: Implement regex matching against help topics array.

### 12. **No Task Tags/Labels**
**Problem**: Can only filter by project, not by tags.
**Fix**: Add tag support: #tag1 #tag2 in task text, filter by tag.

### 13. **Burndown Chart Visual Is Basic**
**Problem**: Just a text bar, hard to see progress.
**Fix**: Add ASCII graph showing trend over time.
```
Week 1: ████████░░ 80%
Week 2: ██████████ 100%
```

### 14. **No Bulk Operations**
**Problem**: Multi-select mode exists but no bulk actions (complete all, delete all, move all).
**Fix**: In multi-select mode, add 'C' complete all, 'D' delete all, 'M' move all.

### 15. **Project Wizard Doesn't Validate**
**Problem**: Can create project with empty name or duplicate name.
**Fix**: Add validation before saving.

### 16. **Recent Projects Shows Wrong Count**
**Problem**: Says "1 active tasks" but should show actual count per project.
**Fix**: Count tasks correctly by filtering data.tasks by project.

### 17. **No Keyboard Shortcuts Legend**
**Problem**: Users have to guess or press H for help.
**Fix**: Add footer with most common keys always visible:
```
A:Add  E:Edit  D:Delete  /:Search  S:Sort  C:Clear  H:Help  F10:Menu
```

### 18. **Templates Don't Actually Create Tasks**
**Problem**: Templates just show list, don't do anything.
**Fix**: Let user press 1-4 to create task from template.

### 19. **Query Browser Doesn't Run Queries**
**Problem**: Just shows list, doesn't execute.
**Fix**: Let user press 1-4 to run query and show filtered results.

### 20. **Preferences/Config Not Editable**
**Problem**: Just display, can't actually change settings.
**Fix**: Make them editable forms.

## Low Priority (Nice to Have)

### 21. **No Color Themes**
**Problem**: Theme editor shows themes but doesn't apply them.
**Fix**: Actually implement theme switching (requires refactoring color codes).

### 22. **No Task Notes Display**
**Problem**: Add Note operation exists, but notes never shown anywhere.
**Fix**: Show notes in task detail view.

### 23. **No Dependencies Visual**
**Problem**: Dependency graph shows tree but hard to understand relationships.
**Fix**: Add indentation or better tree visual:
```
Task #5: Main Feature
  └─> Depends on:
      ├─> Task #2: Setup Database [done] ✓
      └─> Task #3: API Integration [in-progress] ⏳
```

### 24. **No Task Time Estimate**
**Problem**: Can't estimate how long task will take.
**Fix**: Add 'estimate' field, show in task detail.

### 25. **No Focus Mode Visual**
**Problem**: Focus mode sets focus but no special display mode.
**Fix**: When focused on a task, hide everything else, full-screen task detail.

## Layout/Visual Issues

### 26. **Too Much Whitespace**
**Problem**: Lots of empty space, could fit more content.
**Fix**: Reduce padding, increase content density.

### 27. **Menu Bar Takes Up Space**
**Problem**: Menu bar always visible even though rarely used (F10 or Alt+key).
**Fix**: Make menu bar hideable, toggle with F10.

### 28. **Task List Column Alignment**
**Problem**: Task titles not aligned properly when IDs vary length.
**Fix**: Use fixed-width columns: `ID | Title | Project | Due | Status`

### 29. **No Progress Indicators**
**Problem**: When loading/saving, no indication operation is happening.
**Fix**: Show spinner or "Loading..." during operations.

### 30. **Colors Not Consistent**
**Problem**: Some screens use cyan, some yellow for headings.
**Fix**: Establish color scheme:
- Headers: Cyan
- Success: Green
- Warning: Yellow
- Error: Red
- Info: White
- Selected: Yellow background

## Functional Gaps

### 31. **No Recurring Tasks**
**Problem**: Can't set task to repeat daily/weekly/monthly.
**Fix**: Add recurrence field and auto-create next instance on complete.

### 32. **No Task Archiving**
**Problem**: Completed tasks stay in list forever.
**Fix**: Add archive function, hide archived tasks by default.

### 33. **No Export to Calendar**
**Problem**: Can't export tasks with due dates to .ics format.
**Fix**: Add Export → Calendar option.

### 34. **No Task Priority Visual**
**Problem**: Priority is stored but not visually obvious in list.
**Fix**: Use color coding: High=Red, Medium=Yellow, Low=Green
Or symbols: !!!High !!Medium !Low

### 35. **No Overdue Highlighting**
**Problem**: Overdue tasks look same as upcoming tasks.
**Fix**: Make overdue tasks RED and add ⚠️ icon.

## Data Display Issues

### 36. **Dates Format Inconsistent**
**Problem**: Some screens show full timestamp, some show just date.
**Fix**: Use consistent format: "2025-10-02" for dates, "14:30" for times.

### 37. **Long Task Titles Truncated**
**Problem**: Task titles cut off with no indication.
**Fix**: Add "..." when truncated, show full title in status bar on selection.

### 38. **Empty States Not Handled**
**Problem**: When no tasks, just blank screen.
**Fix**: Show helpful message: "No tasks yet. Press 'A' to add your first task!"

### 39. **Project List Not Sorted**
**Problem**: Projects in random order.
**Fix**: Sort alphabetically or by most recently used.

### 40. **Time Logs Not Integrated**
**Problem**: Time tracking exists but not visible in task views.
**Fix**: Show total time logged in task detail view.

## Recommendations Summary

### Must Fix (Top 5):
1. Add selection indicator (cursor/highlight) in lists
2. Add status bar with current mode and available keys
3. Fix statistics/velocity calculations (showing 200%)
4. Add confirmation messages after operations
5. Show filter status when active

### Should Fix (Next 10):
6. Make templates functional (create tasks)
7. Make queries functional (run filters)
8. Add bulk operations in multi-select
9. Show task notes in detail view
10. Better dependency graph visualization
11. Quick complete with spacebar (document better)
12. Project filter indicator
13. Undo/redo feedback
14. Help search actually search
15. Validation in forms

### Nice to Have:
- Theme switching
- Recurring tasks
- Task archiving
- Calendar export
- Color-coded priorities
- Better empty states
- Progress indicators

## Implementation Priority

**Week 1 (Critical UX)**:
- Selection indicators
- Status bar
- Fix statistics calculations
- Confirmation messages
- Filter indicators

**Week 2 (Functionality)**:
- Make templates work
- Make queries work
- Bulk operations
- Form validation
- Better help

**Week 3 (Polish)**:
- Color consistency
- Better layouts
- Progress indicators
- Keyboard shortcuts footer
- Task notes display
