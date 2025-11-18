using namespace System.Collections.Generic
using namespace System.Text

# KanbanScreen - Shows tasks in 3-column kanban board
# Displays tasks grouped by status: TODO / In Progress / Done


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Kanban board view with 3 columns

.DESCRIPTION
Shows tasks grouped into 3 columns based on status:
- TODO (pending/blocked/waiting)
- In Progress (in-progress)
- Done (done/completed in last 7 days)

Uses left/right arrow keys to navigate between columns.
#>
class KanbanScreen : PmcScreen {
    # Data
    [array]$TodoTasks = @()
    [array]$InProgressTasks = @()
    [array]$DoneTasks = @()

    # Navigation
    [int]$SelectedColumn = 0  # 0=TODO, 1=InProgress, 2=Done
    [int]$SelectedIndexTodo = 0
    [int]$SelectedIndexInProgress = 0
    [int]$SelectedIndexDone = 0

    # TaskStore for data access
    [TaskStore]$Store = $null

    # Constructor
    KanbanScreen() : base("Kanban", "Kanban Board") {
        # Initialize TaskStore
        $this.Store = [TaskStore]::GetInstance()
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks", "Kanban"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Left/Right", "Column")
        $this.Footer.AddShortcut("M", "Move")
        $this.Footer.AddShortcut("R", "Refresh")
        $this.Footer.AddShortcut("Esc", "Back")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
    }

    # Constructor with container
    KanbanScreen([object]$container) : base("Kanban", "Kanban Board", $container) {
        # Initialize TaskStore
        $this.Store = [TaskStore]::GetInstance()

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks", "Kanban"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Left/Right", "Column")
        $this.Footer.AddShortcut("M", "Move")
        $this.Footer.AddShortcut("R", "Refresh")
        $this.Footer.AddShortcut("Esc", "Back")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
    }

    [void] LoadData() {
        $this.ShowStatus("Loading kanban board...")

        try {
            # Load tasks from TaskStore
            $allTasks = $this.Store.GetAllTasks()
            $sevenDaysAgo = (Get-Date).AddDays(-7)

            # TODO column: pending, blocked, waiting (not completed)
            $this.TodoTasks = @($allTasks | Where-Object {
                $taskCompleted = Get-SafeProperty $_ 'completed'
                $taskStatus = Get-SafeProperty $_ 'status'
                -not $taskCompleted -and
                ($taskStatus -eq 'pending' -or $taskStatus -eq 'blocked' -or $taskStatus -eq 'waiting' -or -not $taskStatus)
            })
            $this.TodoTasks = @($this.TodoTasks | Sort-Object { Get-SafeProperty $_ 'priority' }, { Get-SafeProperty $_ 'id' } -Descending)

            # In Progress column: in-progress (not completed)
            $this.InProgressTasks = @($allTasks | Where-Object {
                $taskCompleted = Get-SafeProperty $_ 'completed'
                $taskStatus = Get-SafeProperty $_ 'status'
                -not $taskCompleted -and $taskStatus -eq 'in-progress'
            })
            $this.InProgressTasks = @($this.InProgressTasks | Sort-Object { Get-SafeProperty $_ 'priority' }, { Get-SafeProperty $_ 'id' } -Descending)

            # Done column: completed in last 7 days OR status=done
            $this.DoneTasks = @($allTasks | Where-Object {
                $taskCompleted = Get-SafeProperty $_ 'completed'
                $taskCompletedDate = Get-SafeProperty $_ 'completedDate'
                $taskStatus = Get-SafeProperty $_ 'status'
                ($taskCompleted -and $taskCompletedDate -and ([DateTime]$taskCompletedDate) -gt $sevenDaysAgo) -or
                ($taskStatus -eq 'done')
            })
            $this.DoneTasks = @($this.DoneTasks | Sort-Object { Get-SafeProperty $_ 'completedDate' }, { Get-SafeProperty $_ 'id' } -Descending)

            # Reset selections if out of bounds
            if ($this.SelectedIndexTodo -ge $this.TodoTasks.Count) {
                $this.SelectedIndexTodo = [Math]::Max(0, $this.TodoTasks.Count - 1)
            }
            if ($this.SelectedIndexInProgress -ge $this.InProgressTasks.Count) {
                $this.SelectedIndexInProgress = [Math]::Max(0, $this.InProgressTasks.Count - 1)
            }
            if ($this.SelectedIndexDone -ge $this.DoneTasks.Count) {
                $this.SelectedIndexDone = [Math]::Max(0, $this.DoneTasks.Count - 1)
            }

            # Update status
            $total = $this.TodoTasks.Count + $this.InProgressTasks.Count + $this.DoneTasks.Count
            $this.ShowStatus("Kanban: $($this.TodoTasks.Count) TODO, $($this.InProgressTasks.Count) In Progress, $($this.DoneTasks.Count) Done")

        } catch {
            $this.ShowError("Failed to load kanban board: $_")
            $this.TodoTasks = @()
            $this.InProgressTasks = @()
            $this.DoneTasks = @()
        }
    }

    [string] RenderContent() {
        return $this._RenderKanbanBoard()
    }

    hidden [string] _RenderKanbanBoard() {
        $sb = [System.Text.StringBuilder]::new(8192)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $selectedBg = $this.Header.GetThemedAnsi('Primary', $true)
        $selectedFg = $this.Header.GetThemedAnsi('Text', $false)
        $cursorColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $priorityColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
        $successColor = $this.Header.GetThemedAnsi('Success', $false)
        $reset = "`e[0m"

        # Calculate column widths (3 equal columns with borders)
        $columnWidth = [Math]::Floor(($contentRect.Width - 6) / 3)
        $col1X = $contentRect.X + 2
        $col2X = $col1X + $columnWidth + 2
        $col3X = $col2X + $columnWidth + 2

        # Starting Y position
        $startY = $contentRect.Y + 1

        # Render column headers
        $sb.Append($this.Header.BuildMoveTo($col1X, $startY))
        if ($this.SelectedColumn -eq 0) { $sb.Append($cursorColor) } else { $sb.Append($headerColor) }
        $sb.Append("TODO ($($this.TodoTasks.Count))")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($col2X, $startY))
        if ($this.SelectedColumn -eq 1) { $sb.Append($cursorColor) } else { $sb.Append($headerColor) }
        $sb.Append("IN PROGRESS ($($this.InProgressTasks.Count))")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($col3X, $startY))
        if ($this.SelectedColumn -eq 2) { $sb.Append($cursorColor) } else { $sb.Append($headerColor) }
        $sb.Append("DONE ($($this.DoneTasks.Count))")
        $sb.Append($reset)

        # Render separator line
        $separatorY = $startY + 1
        $sb.Append($this.Header.BuildMoveTo($contentRect.X, $separatorY))
        $sb.Append($mutedColor)
        $sb.Append("-" * $contentRect.Width)
        $sb.Append($reset)

        # Render task items in columns
        $maxLines = $contentRect.Height - 4
        $taskStartY = $separatorY + 1

        # Render TODO column
        $sb.Append($this._RenderColumn($col1X, $taskStartY, $maxLines, $columnWidth, $this.TodoTasks, $this.SelectedIndexTodo, ($this.SelectedColumn -eq 0)))

        # Render In Progress column
        $sb.Append($this._RenderColumn($col2X, $taskStartY, $maxLines, $columnWidth, $this.InProgressTasks, $this.SelectedIndexInProgress, ($this.SelectedColumn -eq 1)))

        # Render Done column
        $sb.Append($this._RenderColumn($col3X, $taskStartY, $maxLines, $columnWidth, $this.DoneTasks, $this.SelectedIndexDone, ($this.SelectedColumn -eq 2)))

        return $sb.ToString()
    }

    hidden [string] _RenderColumn([int]$x, [int]$y, [int]$maxLines, [int]$width, [array]$tasks, [int]$selectedIndex, [bool]$isActiveColumn) {
        $sb = [System.Text.StringBuilder]::new(2048)

        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $selectedBg = $this.Header.GetThemedAnsi('Primary', $true)
        $selectedFg = $this.Header.GetThemedAnsi('Text', $false)
        $cursorColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $priorityColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        for ($i = 0; $i -lt [Math]::Min($tasks.Count, $maxLines); $i++) {
            $task = $tasks[$i]
            $lineY = $y + $i
            $isSelected = ($i -eq $selectedIndex) -and $isActiveColumn

            # Cursor
            $sb.Append($this.Header.BuildMoveTo($x - 1, $lineY))
            if ($isSelected) {
                $sb.Append($cursorColor)
                $sb.Append(">")
                $sb.Append($reset)
            } else {
                $sb.Append(" ")
            }

            # Task text
            $sb.Append($this.Header.BuildMoveTo($x, $lineY))

            # Priority prefix if present
            $taskPriority = Get-SafeProperty $task 'priority'
            $taskTextValue = Get-SafeProperty $task 'text'
            $taskText = ""
            if ($taskPriority -gt 0) {
                $taskText = "P$taskPriority "
            }
            $taskText += $taskTextValue

            # Truncate if needed
            $maxWidth = $width - 2
            if ($taskText.Length -gt $maxWidth) {
                $taskText = $taskText.Substring(0, $maxWidth - 3) + "..."
            }

            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
                $sb.Append($taskText.PadRight($maxWidth))
                $sb.Append($reset)
            } else {
                if ($taskPriority -gt 0) {
                    $sb.Append($priorityColor)
                    $sb.Append("P$taskPriority ")
                    $sb.Append($reset)
                    $sb.Append($textColor)
                    $displayText = $taskTextValue
                    if ($displayText.Length -gt ($maxWidth - 4)) {
                        $displayText = $displayText.Substring(0, $maxWidth - 7) + "..."
                    }
                    $sb.Append($displayText)
                } else {
                    $sb.Append($textColor)
                    $sb.Append($taskText)
                }
                $sb.Append($reset)
            }
        }

        # Show truncation indicator if needed
        if ($tasks.Count -gt $maxLines) {
            $lineY = $y + $maxLines
            $remaining = $tasks.Count - $maxLines
            $sb.Append($this.Header.BuildMoveTo($x, $lineY))
            $sb.Append($mutedColor)
            $sb.Append("... +$remaining more")
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        $keyChar = [char]::ToLower($keyInfo.KeyChar)
        switch ($keyInfo.Key) {
            'LeftArrow' {
                if ($this.SelectedColumn -gt 0) {
                    $this.SelectedColumn--
                    return $true
                }
            }
            'RightArrow' {
                if ($this.SelectedColumn -lt 2) {
                    $this.SelectedColumn++
                    return $true
                }
            }
            'UpArrow' {
                $this._MoveSelectionUp()
                return $true
            }
            'DownArrow' {
                $this._MoveSelectionDown()
                return $true
            }
        }

        switch ($keyChar) {
            'm' {
                $this._MoveTask()
                return $true
            }
            'r' {
                $this.LoadData()
                return $true
            }
        }

        return $false
    }

    hidden [void] _MoveSelectionUp() {
        switch ($this.SelectedColumn) {
            0 {
                if ($this.SelectedIndexTodo -gt 0) {
                    $this.SelectedIndexTodo--
                }
            }
            1 {
                if ($this.SelectedIndexInProgress -gt 0) {
                    $this.SelectedIndexInProgress--
                }
            }
            2 {
                if ($this.SelectedIndexDone -gt 0) {
                    $this.SelectedIndexDone--
                }
            }
        }
    }

    hidden [void] _MoveSelectionDown() {
        switch ($this.SelectedColumn) {
            0 {
                if ($this.SelectedIndexTodo -lt ($this.TodoTasks.Count - 1)) {
                    $this.SelectedIndexTodo++
                }
            }
            1 {
                if ($this.SelectedIndexInProgress -lt ($this.InProgressTasks.Count - 1)) {
                    $this.SelectedIndexInProgress++
                }
            }
            2 {
                if ($this.SelectedIndexDone -lt ($this.DoneTasks.Count - 1)) {
                    $this.SelectedIndexDone++
                }
            }
        }
    }

    hidden [void] _MoveTask() {
        $task = $this._GetSelectedTask()
        if ($task) {
            # Cycle status: pending -> in-progress -> done -> pending
            $taskId = Get-SafeProperty $task 'id'
            $taskStatus = Get-SafeProperty $task 'status'
            $newStatus = 'in-progress'  # Initialize variable for strict mode
            $completedDate = $null
            switch ($taskStatus) {
                'pending' { $newStatus = 'in-progress' }
                'in-progress' {
                    $newStatus = 'done'
                    $completedDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                }
                'done' { $newStatus = 'pending' }
                default { $newStatus = 'in-progress' }
            }

            # Build changes hashtable
            $changes = @{ status = $newStatus }
            if ($newStatus -eq 'done') {
                $changes.completed = $true
                $changes.completedDate = $completedDate
            } elseif ($newStatus -eq 'pending') {
                $changes.completed = $false
                $changes.completedDate = $null
            }

            # Update via TaskStore (handles validation, events, persistence, rollback)
            $success = $this.Store.UpdateTask($taskId, $changes)
            if ($success) {
                $this.ShowSuccess("Moved task #$taskId to $newStatus")
                $this.LoadData()  # Reload to update columns
            } else {
                $this.ShowError("Failed to move task: $($this.Store.LastError)")
            }
        }
    }

    hidden [object] _GetSelectedTask() {
        switch ($this.SelectedColumn) {
            0 {
                if ($this.SelectedIndexTodo -ge 0 -and $this.SelectedIndexTodo -lt $this.TodoTasks.Count) {
                    return $this.TodoTasks[$this.SelectedIndexTodo]
                }
            }
            1 {
                if ($this.SelectedIndexInProgress -ge 0 -and $this.SelectedIndexInProgress -lt $this.InProgressTasks.Count) {
                    return $this.InProgressTasks[$this.SelectedIndexInProgress]
                }
            }
            2 {
                if ($this.SelectedIndexDone -ge 0 -and $this.SelectedIndexDone -lt $this.DoneTasks.Count) {
                    return $this.DoneTasks[$this.SelectedIndexDone]
                }
            }
        }
        return $null
    }
}

# Entry point function for compatibility
function Show-KanbanScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [KanbanScreen]::new()
    $App.PushScreen($screen)
}
