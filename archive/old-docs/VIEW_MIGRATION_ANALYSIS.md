# View Migration Analysis - Screen Class Migration Guide

## Overview
This document analyzes the four main view methods that need to be migrated to Screen classes:
- DrawWeekView (Line 3905-3983)
- DrawTodayView (Line 4163-4241)
- DrawOverdueView (Line 4243-4288)
- DrawKanbanView (Line 4336-4593)

---

## 1. DrawTodayView

**Location:** Lines 4163-4241

### Filtering Logic
```powershell
# Filter 1: Overdue tasks
$overdue = @($data.tasks | Where-Object {
    if ($_.status -eq 'completed' -or -not $_.due) { return $false }
    $d = Get-ConsoleUIDateOrNull $_.due
    if ($d) { return ($d.Date -lt $today) } else { return $false }
} | Sort-Object { ... })

# Filter 2: Today's tasks  
$todayTasks = @($data.tasks | Where-Object {
    if ($_.status -eq 'completed' -or -not $_.due) { return $false }
    $d = Get-ConsoleUIDateOrNull $_.due
    if ($d) { return ($d.Date -eq $today) } else { return $false }
})
```

**Filtering Approach:**
- Excludes completed tasks
- Excludes tasks with no due date
- Filters by date comparison using `Get-ConsoleUIDateOrNull` helper
- Creates two groups: OVERDUE and DUE TODAY

### Rendering Approach
1. **Title:** Centered at Y=3 with blue background: " Today's Tasks "
2. **Two Sections:**
   - **OVERDUE:** Red background header, lists overdue tasks with days-ago counter
   - **DUE TODAY:** Cyan header, lists today's tasks with priority indicators [H]/[M]/[L]
3. **Task Display Format:**
   - `[ID] due-date (days-ago) - task-text` (overdue)
   - `[P] [ID] task-text` (today, where P = priority letter)
4. **Selection:** Yellow indicator ">" and blue background highlighting for selected task
5. **Footer:** Standard interaction help text

### Key Variables/State
- `$this.specialSelectedIndex` - current selection index
- `$this.specialItems` - list of items matching selection

### Navigation/Interaction
- **Up/Down arrows:** Move selection between tasks
- **Enter:** View task detail
- **E:** Edit selected task
- **D:** Toggle task status
- **F10/Alt:** Show menus
- **Esc:** Back to previous view

---

## 2. DrawWeekView

**Location:** Lines 3905-3983

### Filtering Logic
```powershell
$today = (Get-Date).Date
$weekEnd = $today.AddDays(7)

# Filter 1: Overdue tasks (same as TodayView)
$overdue = @($data.tasks | Where-Object {
    if ($_.status -eq 'completed' -or -not $_.due) { return $false }
    $d = Get-ConsoleUIDateOrNull $_.due
    if ($d) { return ($d.Date -lt $today) } else { return $false }
})

# Filter 2: This week's tasks
$thisWeek = @($data.tasks | Where-Object {
    if ($_.status -eq 'completed' -or -not $_.due) { return $false }
    $d = Get-ConsoleUIDateOrNull $_.due
    if ($d) { return ($d.Date -ge $today -and $d.Date -le $weekEnd) } else { return $false }
} | Sort-Object { ... })
```

**Filtering Approach:**
- Same as TodayView but includes 7-day window
- Range: Today to Today+7 days inclusive
- Excludes completed and undated tasks
- Creates two groups: OVERDUE and DUE THIS WEEK

### Rendering Approach
1. **Title:** Centered at Y=3 with green background: " This Week's Tasks "
2. **Two Sections:**
   - **OVERDUE:** Red background header, red text for unselected items
   - **DUE THIS WEEK:** Green header, normal text for unselected items
3. **Task Display Format:**
   - `[ID] MMM dd (X days ago) - task-text` (overdue)
   - `[ID] ddd MMM dd - task-text` (this week)
4. **Selection:** Yellow ">" indicator and blue background highlighting
5. **Empty State:** Message "No tasks due this week" if both groups empty

### Key Variables/State
- Same as TodayView (`$this.specialSelectedIndex`, `$this.specialItems`)

### Navigation/Interaction
- Same as TodayView (Up/Down/Enter/E/D/F10/Esc)

---

## 3. DrawOverdueView

**Location:** Lines 4243-4288

### Filtering Logic
```powershell
$today = (Get-Date).Date
$overdueTasks = @($data.tasks | Where-Object {
    if ($_.status -eq 'completed' -or -not $_.due) { return $false }
    $d = Get-ConsoleUIDateOrNull $_.due
    if ($d) { return ($d.Date -lt $today) } else { return $false }
})
```

**Filtering Approach:**
- Simplest filter: only overdue tasks (no other grouping)
- Excludes completed and undated tasks
- Condition: due date < today

### Rendering Approach
1. **Title:** Centered at Y=3 with red background: " Overdue Tasks "
2. **Single List:** All overdue tasks displayed in sequence
3. **Task Display Format:** Multi-part rendering
   - `[ID]` at X=4 (red/blue)
   - `task-text` at X=10 (normal/blue)
   - `(X days overdue)` at X=70 (red/blue)
4. **Empty State:** Green message "No overdue tasks! 🎉"
5. **Selection:** Yellow ">" indicator and blue background highlighting

### Key Variables/State
- Same selection mechanism: `$this.specialSelectedIndex`, `$this.specialItems`

### Navigation/Interaction
- Same as TodayView (Up/Down/Enter/E/D/F10/Esc)

---

## 4. DrawKanbanView

**Location:** Lines 4336-4593

### Rendering Approach - UNIQUE (Different Pattern!)
This is a **stateful modal view** with its own event loop, unlike the others.

1. **Title:** Centered at Y=3 with blue background: " Kanban Board "

2. **Three-Column Layout:**
   - Column 0: TODO (active, todo, '', pending statuses)
   - Column 1: IN PROGRESS (in-progress, started, working)
   - Column 2: DONE (completed, done)

3. **Column Structure:**
   ```
   ╭──────────────────────────────────────╮
   │ TODO (5)                             │
   ├──────────────────────────────────────┤
   │ ! #1 Task text                 01/15 │
   │ * #2 Task text 2               01/20 │
   │ ...                                  │
   ╰──────────────────────────────────────╯
   ```

4. **Visual Elements:**
   - Rounded box borders: ╭─╮ ├─┤ ╰─╯
   - Column header: `NAME (count)`
   - Task line: `[priority-symbol] #[id] [text] [due-date]`
   - Priority symbols: `!` (high), `*` (medium), ` ` (low)
   - Date format: MM/dd
   - Cyan borders for unselected, cyan background for selected
   - Color coding: High=Red text, Medium=Yellow text, Low=normal

5. **Scrolling:**
   - Each column independently scrollable
   - Scroll indicators: `[start-end/total]` at bottom of column
   - Visible rows calculated: `Height - startY - headerHeight - 2`

### Filtering Logic
Tasks are categorized by status into columns (implicit filtering).

### Key Variables/State
```powershell
$kbColSc = @(0, 0, 0)          # Scroll position for each column
$selectedCol = 0                # Current column (0-2)
$selectedRow = 0                # Current row within column
$focusTaskId = -1               # Task ID to focus after operation
$focusCol = -1                  # Column to look in for focus task
$kanbanActive = $true           # Loop control

# Calculated dimensions
$colWidth = 30                  # Default, adjusted based on terminal width
$columnHeight = 20              # Default, adjusted based on terminal height
$startY = 5
$headerHeight = 3
$gap = 3                        # Gap between columns
```

### Navigation/Interaction - UNIQUE EVENT LOOP
```
LEFT/RIGHT ARROW:  Move between columns (0-2)
UP ARROW:          Scroll up in current column
DOWN ARROW:        Scroll down in current column
1-3 (NUMERIC):     Move selected task to column (1=TODO, 2=IN PROGRESS, 3=DONE)
D KEY:             Mark task as DONE (moves to column 2)
ENTER:             (Not implemented in loop, but shown in footer as "Edit")
ESC:               Exit kanban view, go back
```

**Important:** This view has its own `while ($kanbanActive)` loop and calls `[Console]::ReadKey($true)` directly!

### Task Update Flow
1. User presses 1-3 or D
2. Find selected task in column
3. Change task status
4. Call `Save-PmcData -Data $data`
5. Set `$focusTaskId` and `$focusCol` to re-locate task after refresh
6. Next loop iteration finds task in new column and highlights it

### Global Keys Handling
Kanban view checks for global actions first:
```powershell
$globalAction = $this.CheckGlobalKeys($key)
if ($globalAction) {
    $this.ProcessMenuAction($globalAction)
    return  # Exit kanban view
}
```

---

## Common Patterns Across All Views

### Helper Functions Used
1. **Get-ConsoleUIDateOrNull($value)** - Safely parse date strings
2. **Get-PmcAllData()** - Load all task data
3. **Save-PmcData($data, $action)** - Persist changes
4. **Show-InfoMessage($message, $title, $color)** - Show modal message
5. **$this.CheckGlobalKeys($key)** - Check for menu/global shortcuts
6. **$this.ProcessMenuAction($action)** - Execute menu actions

### Terminal Methods Used
```powershell
$this.terminal.BeginFrame()              # Start frame render
$this.terminal.EndFrame()                # Flush frame to console
$this.terminal.WriteAt(x, y, text)       # Write unformatted
$this.terminal.WriteAtColor(x, y, text, fg, bg)  # Write with colors
$this.terminal.DrawFooter(text)          # Draw footer help text
$this.menuSystem.DrawMenuBar()           # Draw menu bar at top
```

### Selection State Management
- Simple views use: `$this.specialSelectedIndex` and `$this.specialItems`
- Items array contains tasks with `.id` property for comparison
- Selection rendering: Yellow ">" prefix + blue background

### Frame Structure (Non-Kanban Views)
```
Line 1:     (blank)
Line 2:     (blank)
Line 3:     TITLE (centered, colored background)
Line 4:     (blank)
Line 5:     (blank)
Line 6+:    CONTENT (tasks displayed here)
...
Last-1:     FOOTER (help text)
Last:       (blank)
```

---

## Migration Checklist

### For WeekView, TodayView, OverdueView Screen Classes
- [ ] Inherit from Screen base class
- [ ] Implement filtering in Initialize() or separate Filter() method
- [ ] Implement rendering in Render() method
- [ ] Implement HandleInput() for Up/Down/Enter/E/D/F10/Esc
- [ ] Manage selection state via `$this.specialSelectedIndex` 
- [ ] Use `$this.terminal` for drawing
- [ ] Use `$this.menuSystem` for menu bar
- [ ] Call appropriate helper functions (Get-PmcAllData, Save-PmcData, etc.)

### For KanbanView Screen Class - SPECIAL HANDLING NEEDED
- [ ] Implement custom event loop within Render() or Create HandleInputLoop()
- [ ] Manage 3-column selection state (selectedCol, selectedRow)
- [ ] Manage column scroll positions (kbColSc array)
- [ ] Implement column-based filtering/grouping
- [ ] Implement focus-after-update tracking (focusTaskId, focusCol)
- [ ] Handle numeric keys 1-3 for column moves
- [ ] Handle global key checking with exit capability
- [ ] Use direct `[Console]::ReadKey($true)` OR implement via HandleInput() loop callback

### Data Structure Considerations
- All views need access to: `$data.tasks` array
- Each task has: `.id`, `.text`, `.status`, `.due`, `.priority`, `.project`
- Date parsing via: `Get-ConsoleUIDateOrNull`
- Status values: 'completed', 'done', 'active', 'todo', '', 'pending', 'in-progress', 'started', 'working', 'blocked', 'waiting'

---

## Technical Notes

### Date Handling
- All due dates converted via `Get-ConsoleUIDateOrNull` which returns `[datetime]` or `$null`
- Compare using `.Date` property to ignore time component
- Format using `.ToString('format-string')`
- Common formats: 'MMM dd', 'ddd MMM dd', 'MM/dd', 'yyyy-MM-dd'

### Status Mapping for Kanban
```
TODO Column:        'active', 'todo', '', 'pending'
IN PROGRESS Column: 'in-progress', 'started', 'working'
DONE Column:        'completed', 'done'
```

### Color Constants
Used via `[PmcVT100]::` class methods:
- `Red()`, `Green()`, `Yellow()`, `Blue()`, `Cyan()`, `White()`, `Gray()`, `Black()`
- `BgRed()`, `BgGreen()`, `BgBlue()`, `BgYellow()` for backgrounds

---

## Footer Text Examples

```powershell
# TodayView / WeekView / OverdueView
"↑/↓:Select  Enter:Detail  E:Edit  D:Toggle  F10/Alt:Menus  Esc:Back"

# KanbanView
"←→:Column | ↑↓:Scroll | 1-3:Move | Enter:Edit | D:Done | Esc:Exit"
```

