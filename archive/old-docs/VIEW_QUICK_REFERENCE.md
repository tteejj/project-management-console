# View Migration Quick Reference

## Side-by-Side Comparison

| Aspect | TodayView | WeekView | OverdueView | KanbanView |
|--------|-----------|----------|-------------|-----------|
| **Lines** | 4163-4241 | 3905-3983 | 4243-4288 | 4336-4593 |
| **Title** | "Today's Tasks" | "This Week's Tasks" | "Overdue Tasks" | "Kanban Board" |
| **Title BG** | Blue | Green | Red | Blue |
| **Sections** | 2 (Overdue + Today) | 2 (Overdue + Week) | 1 (Just Overdue) | 3 Columns |
| **Selection** | Simple List | Simple List | Simple List | 2D (Col+Row) |
| **Layout** | Vertical List | Vertical List | Vertical List | 3-Column Board |
| **Scrolling** | None | None | None | Per-Column |
| **Event Loop** | None | None | None | **YES** (Own loop) |
| **Date Range** | Today only | Today+7 days | Past only | Any |

## Filtering Patterns

### TodayView & WeekView
```powershell
# Both exclude:
- Completed tasks
- Tasks with no due date

# TodayView filters:
- Overdue: due.Date < today
- Today: due.Date == today

# WeekView filters:
- Overdue: due.Date < today
- Week: today <= due.Date <= today+7
```

### OverdueView
```powershell
# Only includes:
- Not completed
- Has due date
- Condition: due.Date < today
```

### KanbanView
```powershell
# Groups by status (all tasks included):
- TODO: status in ['active', 'todo', '', 'pending']
- IN PROGRESS: status in ['in-progress', 'started', 'working']
- DONE: status in ['completed', 'done']
```

## Task Rendering Formats

### TodayView
```
=== OVERDUE (3) ===
(Red background header)
[5] Jan 15 (3 days ago) - Task text
[H] [6] Today's high-priority task

=== DUE TODAY (2) ===
(Cyan header)
[M] [7] Medium priority task
[L] [8] Low priority task
```

### WeekView
```
=== OVERDUE (2) ===
(Red background header)
[5] Jan 15 (2 days ago) - Past task

=== DUE THIS WEEK (4) ===
(Green header)
[9] Mon Jan 18 - Due Monday
[10] Wed Jan 20 - Due Wednesday
```

### OverdueView
```
[ID]                  [TASK TEXT]                  (X days overdue)
[5] at X=4           Task at X=10                (days info at X=70)
(Multi-part rendering at different X coordinates)
```

### KanbanView
```
╭──────────────────╮  ╭──────────────────╮  ╭──────────────────╮
│ TODO (3)         │  │ IN PROGRESS (1)  │  │ DONE (2)         │
├──────────────────┤  ├──────────────────┤  ├──────────────────┤
│ ! #5 High task   │  │ * #7 Medium task │  │ ! #1 Done task   │
│ * #6 Medium task │  │                  │  │ * #2 Also done   │
│ * #8 Task 3      │  │   [1-1/1]        │  │   [1-2/2]        │
│   [1-3/3]        │  │                  │  │                  │
╰──────────────────╯  ╰──────────────────╯  ╰──────────────────╯
```

## Input Handling

### TodayView / WeekView / OverdueView
```
KEY         ACTION
─────────────────────────────────────
↑/↓         Move selection up/down
Enter       Open task detail view
E           Edit selected task
D           Toggle task status/completion
F10/Alt     Show menu bar
Esc         Return to previous view
```

### KanbanView (DIFFERENT!)
```
KEY         ACTION
─────────────────────────────────────
←/→         Move between columns (TODO ↔ IN PROGRESS ↔ DONE)
↑/↓         Scroll current column up/down
1-3         Move task to column (1=TODO, 2=IN PROGRESS, 3=DONE)
D           Mark task as DONE (moves to column 2)
Enter       (Footer shows "Edit" but not implemented in loop)
Esc         Exit kanban view
```

## State Management

### TodayView / WeekView / OverdueView
```
$this.specialSelectedIndex      Current position in task list
$this.specialItems              All tasks (combined from filters)
```

### KanbanView
```
$selectedCol                    Current column (0=TODO, 1=IN PROGRESS, 2=DONE)
$selectedRow                    Current row in column
$kbColSc[0-2]                   Scroll position for each column
$focusTaskId                    Task ID to highlight after update
$focusCol                       Column where task moved to
$kanbanActive                   Loop control flag
```

## Critical Implementation Notes

### 1. KanbanView Uses Own Event Loop
Unlike other views that return control to ConsoleUI main loop:
```powershell
while ($kanbanActive) {
    # Render frame
    # Handle input with [Console]::ReadKey($true)
    # Update state
}
# When done, exits while loop and returns from DrawKanbanView()
```

### 2. Focus-After-Update Pattern
KanbanView tracks which task was just moved:
```powershell
$focusTaskId = $tid           # Save task ID
$focusCol = $targetCol        # Save which column
# Next loop iteration finds and highlights it
```

### 3. Date Comparison Always Uses .Date
```powershell
$d = Get-ConsoleUIDateOrNull $task.due
if ($d) { 
    return ($d.Date -eq (Get-Date).Date)  # Compare dates, not times
}
```

### 4. Selection Check Pattern
```powershell
$isSel = ($this.specialSelectedIndex -lt $this.specialItems.Count -and 
          $this.specialItems[$this.specialSelectedIndex].id -eq $task.id)
if ($isSel) {
    # Render with blue background
} else {
    # Render with normal colors
}
```

### 5. Multi-Part Task Rendering
OverdueView uses multiple WriteAt calls for same line:
```powershell
$this.terminal.WriteAtColor(4, $y, "[5] ", [PmcVT100]::Red(), "")
$this.terminal.WriteAt(10, $y, "Task text ")
$this.terminal.WriteAtColor(70, $y, "(3 days overdue)", [PmcVT100]::Red(), "")
$y++
```

## Migration Strategy

### Phase 1: TodayView Screen
- Simplest: 2 sections, linear rendering
- Test selection mechanism
- Verify date filtering logic

### Phase 2: WeekView Screen
- Similar to TodayView but different date range
- Good for testing reusable filtering patterns

### Phase 3: OverdueView Screen
- Simplest filtering (single condition)
- Multi-part line rendering
- Test position-based drawing

### Phase 4: KanbanView Screen
- Most complex: custom event loop
- 2D selection state
- Per-column scrolling
- Focus-after-update tracking
- Should be last due to complexity

