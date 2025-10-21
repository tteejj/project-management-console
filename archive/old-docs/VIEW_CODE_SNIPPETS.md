# View Migration Code Snippets

## Common Filtering Helpers

### Get Today's Date (Used in All Views)
```powershell
$today = (Get-Date).Date
```

### Safe Date Parsing (Used Everywhere)
```powershell
$dueDate = Get-ConsoleUIDateOrNull $task.due
if ($dueDate) {
    # Safe to use $dueDate.Date for comparisons
} else {
    # Task has invalid or missing due date
}
```

### Load All Task Data (Used in All Views)
```powershell
$data = Get-PmcAllData
# Returns object with:
#   $data.tasks = @(task1, task2, ...)
#   Each task has: .id, .text, .status, .due, .priority, .project
```

---

## TodayView Filtering Template

```powershell
# Step 1: Get today's date
$today = (Get-Date).Date

# Step 2: Filter overdue tasks
$overdue = @($data.tasks | Where-Object {
    if ($_.status -eq 'completed' -or -not $_.due) { return $false }
    $d = Get-ConsoleUIDateOrNull $_.due
    if ($d) { return ($d.Date -lt $today) } else { return $false }
} | Sort-Object { ($tmp = Get-ConsoleUIDateOrNull $_.due); if ($tmp) { $tmp } else { [DateTime]::MaxValue } })

# Step 3: Filter today's tasks
$todayTasks = @($data.tasks | Where-Object {
    if ($_.status -eq 'completed' -or -not $_.due) { return $false }
    $d = Get-ConsoleUIDateOrNull $_.due
    if ($d) { return ($d.Date -eq $today) } else { return $false }
})
```

---

## WeekView Filtering Template

```powershell
# Step 1: Calculate date range
$today = (Get-Date).Date
$weekEnd = $today.AddDays(7)  # Inclusive: today through 7 days from now

# Step 2: Filter overdue tasks (same as TodayView)
$overdue = @($data.tasks | Where-Object {
    if ($_.status -eq 'completed' -or -not $_.due) { return $false }
    $d = Get-ConsoleUIDateOrNull $_.due
    if ($d) { return ($d.Date -lt $today) } else { return $false }
})

# Step 3: Filter this week's tasks
$thisWeek = @($data.tasks | Where-Object {
    if ($_.status -eq 'completed' -or -not $_.due) { return $false }
    $d = Get-ConsoleUIDateOrNull $_.due
    if ($d) { return ($d.Date -ge $today -and $d.Date -le $weekEnd) } else { return $false }
} | Sort-Object { ($tmp = Get-ConsoleUIDateOrNull $_.due); if ($tmp) { $tmp } else { [DateTime]::MaxValue } })
```

---

## OverdueView Filtering Template

```powershell
# Step 1: Get today's date
$today = (Get-Date).Date

# Step 2: Filter overdue tasks (simplest of all)
$overdueTasks = @($data.tasks | Where-Object {
    if ($_.status -eq 'completed' -or -not $_.due) { return $false }
    $d = Get-ConsoleUIDateOrNull $_.due
    if ($d) { return ($d.Date -lt $today) } else { return $false }
})
```

---

## KanbanView Status Grouping Template

```powershell
# Step 1: Define column structure
$columns = @(
    @{Name='TODO'; Status=@('active', 'todo', '', 'pending'); Tasks=@()}
    @{Name='IN PROGRESS'; Status=@('in-progress', 'started', 'working'); Tasks=@()}
    @{Name='DONE'; Status=@('completed', 'done'); Tasks=@()}
)

# Step 2: Populate columns by status
foreach ($task in $data.tasks) {
    $taskStatus = if ($task.status) { $task.status.ToLower() } else { '' }
    for ($i = 0; $i -lt $columns.Count; $i++) {
        if ($columns[$i].Status -contains $taskStatus) {
            $columns[$i].Tasks += $task
            break
        }
    }
}

# Step 3: Access tasks for column
$colTasks = $columns[0].Tasks  # Get TODO tasks
$colCount = $columns[0].Tasks.Count
```

---

## Common Rendering Patterns

### Title Rendering (All Views)
```powershell
# Calculate center position
$title = " Today's Tasks "
$titleX = ($this.terminal.Width - $title.Length) / 2

# Draw with background color
$this.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
```

### Section Header (TodayView, WeekView)
```powershell
# Overdue header with count
$y = 6
$this.terminal.WriteAtColor(4, $y++, "=== OVERDUE ($($overdue.Count)) ===", [PmcVT100]::BgRed(), [PmcVT100]::White())
$y++  # Extra blank line after header

# Today header with count
$this.terminal.WriteAtColor(4, $y++, "=== DUE TODAY ($($todayTasks.Count)) ===", [PmcVT100]::Cyan(), "")
$y++
```

### Task Selection Check (All List Views)
```powershell
$isSel = ($this.specialSelectedIndex -lt $this.specialItems.Count -and 
          $this.specialItems[$this.specialSelectedIndex].id -eq $task.id)

if ($isSel) {
    # Render selected: blue background
    $this.terminal.WriteAtColor(2, $y, "> ", [PmcVT100]::Yellow(), "")
    $this.terminal.WriteAtColor(4, $y++, "[$($task.id)] $($task.text)", [PmcVT100]::BgBlue(), [PmcVT100]::White())
} else {
    # Render unselected: normal colors
    $this.terminal.WriteAt(4, $y++, "[$($task.id)] $($task.text)")
}
```

### Priority-Based Coloring (TodayView)
```powershell
$priColor = switch ($task.priority) {
    'high' { [PmcVT100]::Red() }
    'medium' { [PmcVT100]::Yellow() }
    'low' { [PmcVT100]::Green() }
    default { "" }
}

$pri = if ($task.priority) { "[$($task.priority.Substring(0,1).ToUpper())] " } else { "" }

if ($priColor -and -not $isSel) { 
    $this.terminal.WriteAtColor(4, $y++, "$pri[$($task.id)] $($task.text)", $priColor, "") 
} elseif ($isSel) { 
    $this.terminal.WriteAtColor(4, $y++, "$pri[$($task.id)] $($task.text)", [PmcVT100]::BgBlue(), [PmcVT100]::White()) 
} else { 
    $this.terminal.WriteAt(4, $y++, "[$($task.id)] $($task.text)") 
}
```

### Multi-Part Line Rendering (OverdueView)
```powershell
# Rendering same line with different colors/positions
$isSel = ...  # Check selection logic

if ($isSel) {
    $this.terminal.WriteAtColor(2, $y, "> ", [PmcVT100]::Yellow(), "")
    $this.terminal.WriteAtColor(4, $y, "[$($task.id)] ", [PmcVT100]::BgBlue(), [PmcVT100]::White())
    $this.terminal.WriteAtColor(10, $y, "$($task.text) ", [PmcVT100]::BgBlue(), [PmcVT100]::White())
    $this.terminal.WriteAtColor(70, $y, "($daysOverdue days overdue)", [PmcVT100]::BgBlue(), [PmcVT100]::White())
} else {
    $this.terminal.WriteAtColor(4, $y, "[$($task.id)] ", [PmcVT100]::Red(), "")
    $this.terminal.WriteAt(10, $y, "$($task.text) ")
    $this.terminal.WriteAtColor(70, $y, "($daysOverdue days overdue)", [PmcVT100]::Red(), "")
}
$y++
```

### Footer Rendering (All Views)
```powershell
# Standard footer for list views
$this.terminal.DrawFooter("↑/↓:Select  Enter:Detail  E:Edit  D:Toggle  F10/Alt:Menus  Esc:Back")

# Kanban-specific footer
$this.terminal.DrawFooter("←→:Column | ↑↓:Scroll | 1-3:Move | Enter:Edit | D:Done | Esc:Exit")
```

### Empty State Messages
```powershell
if ($todayTasks.Count -eq 0 -and $overdue.Count -eq 0) {
    $this.terminal.WriteAtColor(4, $y, "No tasks due today", [PmcVT100]::Green(), "")
}

if ($overdueTasks.Count -eq 0) {
    $this.terminal.WriteAtColor(4, $y, "No overdue tasks! 🎉", [PmcVT100]::Green(), "")
}
```

---

## KanbanView Specific Patterns

### Column Drawing (Borders and Header)
```powershell
$startY = 5
$headerHeight = 3
$gap = 3
$colWidth = 30

for ($i = 0; $i -lt $columns.Count; $i++) {
    $col = $columns[$i]
    $x = 4 + ($colWidth + $gap) * $i

    # Top border with rounded corners
    $this.terminal.WriteAtColor($x, $startY, "╭" + ("─" * ($colWidth - 2)) + "╮", [PmcVT100]::Cyan(), "")

    # Column header
    $headerText = " $($col.Name) ($($col.Tasks.Count)) "
    $headerPadding = [math]::Floor(($colWidth - $headerText.Length) / 2)
    $headerLine = (" " * $headerPadding) + $headerText
    $headerLine = $headerLine.PadRight($colWidth - 2)
    $this.terminal.WriteAtColor($x, $startY + 1, "│", [PmcVT100]::Gray(), "")
    $this.terminal.WriteAtColor($x + 1, $startY + 1, $headerLine, [PmcVT100]::White(), "")
    $this.terminal.WriteAtColor($x + $colWidth - 1, $startY + 1, "│", [PmcVT100]::Gray(), "")

    # Separator under header
    $this.terminal.WriteAtColor($x, $startY + 2, "├" + ("─" * ($colWidth - 2)) + "┤", [PmcVT100]::Gray(), "")

    # Side borders for content area
    for ($row = 0; $row -lt $columnHeight; $row++) {
        $this.terminal.WriteAtColor($x, $startY + 3 + $row, "│", [PmcVT100]::Gray(), "")
        $this.terminal.WriteAtColor($x + $colWidth - 1, $startY + 3 + $row, "│", [PmcVT100]::Gray(), "")
    }

    # Bottom border with rounded corners
    $this.terminal.WriteAtColor($x, $startY + 3 + $columnHeight, "╰" + ("─" * ($colWidth - 2)) + "╯", [PmcVT100]::Gray(), "")
}
```

### Kanban Task Rendering with Scrolling
```powershell
for ($i = 0; $i -lt $columns.Count; $i++) {
    $col = $columns[$i]
    $x = 4 + ($colWidth + $gap) * $i
    $contentWidth = $colWidth - 4  # Account for borders and padding

    $visibleStart = $kbColSc[$i]
    $visibleEnd = [math]::Min($visibleStart + $columnHeight, $col.Tasks.Count)

    for ($taskIdx = $visibleStart; $taskIdx -lt $visibleEnd; $taskIdx++) {
        $task = $col.Tasks[$taskIdx]
        $displayRow = $taskIdx - $visibleStart
        $row = $startY + 3 + $displayRow

        # Build task display text
        $pri = if ($task.priority -eq 'high') { "!" } elseif ($task.priority -eq 'medium') { "*" } else { " " }
        $due = if ($task.due) { " " + (Get-Date -Date $task.due).ToString('MM/dd') } else { "" }
        $text = "$pri #$($task.id) $($task.text)$due"

        if ($text.Length -gt $contentWidth) {
            $text = $text.Substring(0, $contentWidth - 3) + "..."
        }
        $text = " " + $text.PadRight($contentWidth)

        # Highlight if selected
        if ($i -eq $selectedCol -and $taskIdx -eq ($selectedRow + $kbColSc[$i])) {
            $this.terminal.WriteAtColor($x + 1, $row, $text, [PmcVT100]::BgCyan(), [PmcVT100]::White())
        } else {
            # Color by priority
            $taskColor = switch ($task.priority) {
                'high' { [PmcVT100]::Red() }
                'medium' { [PmcVT100]::Yellow() }
                default { "" }
            }
            if ($taskColor) {
                $this.terminal.WriteAtColor($x + 1, $row, $text, $taskColor, "")
            } else {
                $this.terminal.WriteAt($x + 1, $row, $text)
            }
        }
    }

    # Show scroll indicator if needed
    if ($col.Tasks.Count -gt $columnHeight) {
        $scrollInfo = "[$($visibleStart + 1)-$visibleEnd/$($col.Tasks.Count)]"
        $scrollX = $x + $colWidth - $scrollInfo.Length - 2
        $this.terminal.WriteAtColor($scrollX, $startY + 3 + $columnHeight, $scrollInfo, [PmcVT100]::Gray(), "")
    }
}
```

### Focus-After-Update Logic
```powershell
# After task is moved
$focusTaskId = $tid
$focusCol = $targetCol

# At top of render loop, find and select the task
if ($focusTaskId -gt 0 -and $focusCol -ge 0 -and $focusCol -lt $columns.Count) {
    $targetTasks = $columns[$focusCol].Tasks
    $foundIndex = -1
    for ($i = 0; $i -lt $targetTasks.Count; $i++) {
        $t = $targetTasks[$i]
        try { if ([int]$t.id -eq $focusTaskId) { $foundIndex = $i; break } } catch {}
    }
    if ($foundIndex -ge 0) {
        $selectedCol = $focusCol
        $selectedRow = $foundIndex
        # Ensure scroll shows the selected row
        $visibleRows = $this.terminal.Height - $startY - $headerHeight - 2
        if ($selectedRow -lt $kbColSc[$selectedCol]) { $kbColSc[$selectedCol] = $selectedRow }
        if ($selectedRow -ge $kbColSc[$selectedCol] + $visibleRows) { $kbColSc[$selectedCol] = [Math]::Max(0, $selectedRow - $visibleRows + 1) }
    }
    # Clear focus request
    $focusTaskId = -1
    $focusCol = -1
}
```

### Kanban Input Handling
```powershell
$key = [Console]::ReadKey($true)

# Check for global keys first
$globalAction = $this.CheckGlobalKeys($key)
if ($globalAction) {
    $this.ProcessMenuAction($globalAction)
    return
}

switch ($key.Key) {
    'LeftArrow' {
        if ($selectedCol -gt 0) {
            $selectedCol--
            $selectedRow = 0
        }
    }
    'RightArrow' {
        if ($selectedCol -lt 2) {  # 3 columns: 0, 1, 2
            $selectedCol++
            $selectedRow = 0
        }
    }
    'UpArrow' {
        if ($selectedRow -gt 0) {
            $selectedRow--
            if ($selectedRow -lt $kbColSc[$selectedCol]) {
                $kbColSc[$selectedCol] = $selectedRow
            }
        }
    }
    'DownArrow' {
        $col = $columns[$selectedCol]
        $maxRow = $col.Tasks.Count - 1
        if ($selectedRow -lt $maxRow) {
            $selectedRow++
            $visibleRows = $this.terminal.Height - $startY - $headerHeight - 2
            if ($selectedRow -ge $kbColSc[$selectedCol] + $visibleRows) {
                $kbColSc[$selectedCol] = $selectedRow - $visibleRows + 1
            }
        }
    }
    'D' {
        # Mark task as done
        $col = $columns[$selectedCol]
        if ($col.Tasks.Count -gt $selectedRow) {
            $task = $col.Tasks[$selectedRow]
            try {
                $tid = try { [int]$task.id } catch { 0 }
                $task.status = 'done'
                Save-PmcData -Data $data -Action "Marked task $($task.id) as done"
                Show-InfoMessage -Message "Task marked as done!" -Title "Success" -Color "Green"
                $focusTaskId = $tid
                $focusCol = 2
            } catch {
                Show-InfoMessage -Message "Failed to update task: $_" -Title "Error" -Color "Red"
            }
        }
    }
    'Escape' {
        $kanbanActive = $false
        $this.GoBackOr('tasklist')
    }
}

# Number keys 1-3 to move task to column
if ($key.KeyChar -ge '1' -and $key.KeyChar -le '3') {
    $targetCol = [int]$key.KeyChar.ToString() - 1
    $col = $columns[$selectedCol]
    if ($col.Tasks.Count -gt $selectedRow) {
        $task = $col.Tasks[$selectedRow]
        $newStatus = $columns[$targetCol].Status[0]

        try {
            $tid = try { [int]$task.id } catch { 0 }
            $task.status = $newStatus
            Save-PmcData -Data $data -Action "Moved task $($task.id) to $($columns[$targetCol].Name)"
            $focusTaskId = $tid
            $focusCol = $targetCol
        } catch {
            Show-InfoMessage -Message "Failed to move task: $_" -Title "Error" -Color "Red"
        }
    }
}
```

---

## Date Formatting Patterns

```powershell
# Format strings used in views
$dueDate.ToString('MMM dd')           # "Jan 15"
$dueDate.ToString('ddd MMM dd')       # "Mon Jan 15"
$dueDate.ToString('MM/dd')            # "01/15"
$dueDate.ToString('yyyy-MM-dd')       # "2024-01-15"

# Days calculation
$daysOverdue = ($today - $dueDate.Date).Days    # Positive number
$daysUntil = ($dueDate.Date - $today).Days      # Positive number
```

