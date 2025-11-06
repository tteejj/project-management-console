using namespace System.Collections.Generic
using namespace System.Text

# KanbanScreen - Shows tasks in 3-column kanban board
# Displays tasks grouped by status: TODO / In Progress / Done

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

    # Constructor
    KanbanScreen() : base("Kanban", "Kanban Board") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks", "Kanban"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Left/Right", "Column")
        $this.Footer.AddShortcut("Enter", "Detail")
        $this.Footer.AddShortcut("M", "Move")
        $this.Footer.AddShortcut("R", "Refresh")
        $this.Footer.AddShortcut("Esc", "Back")

        # Setup menu items
        $this._SetupMenus()
    }

    hidden [void] _SetupMenus() {
        # Capture $this in a variable so scriptblocks can access it
        $screen = $this

        # Tasks menu - Navigate to different task views
        $tasksMenu = $this.MenuBar.Menus[0]
        $tasksMenu.Items.Add([PmcMenuItem]::new("Task List", 'L', { Write-Host "Task List not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Tomorrow", 'T', { Write-Host "Tomorrow view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Upcoming", 'U', { Write-Host "Upcoming view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Next Actions", 'N', { Write-Host "Next Actions view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("No Due Date", 'D', { Write-Host "No Due Date view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::Separator())
        $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', { Write-Host "Month view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Agenda View", 'A', { Write-Host "Agenda view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Burndown Chart", 'B', { Write-Host "Burndown chart not implemented" }))

        # Projects menu
        $projectsMenu = $this.MenuBar.Menus[1]
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project List", 'L', { Write-Host "Project list not implemented" }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Stats", 'S', { Write-Host "Project stats not implemented" }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Info", 'I', { Write-Host "Project info not implemented" }))

        # Options menu
        $optionsMenu = $this.MenuBar.Menus[2]
        $optionsMenu.Items.Add([PmcMenuItem]::new("Theme Editor", 'T', { Write-Host "Theme editor not implemented" }))
        $optionsMenu.Items.Add([PmcMenuItem]::new("Settings", 'S', { Write-Host "Settings not implemented" }))

        # Help menu
        $helpMenu = $this.MenuBar.Menus[3]
        $helpMenu.Items.Add([PmcMenuItem]::new("Help View", 'H', { Write-Host "Help view not implemented" }))
        $helpMenu.Items.Add([PmcMenuItem]::new("About", 'A', { Write-Host "PMC TUI v1.0" }))
    }

    [void] LoadData() {
        $this.ShowStatus("Loading kanban board...")

        try {
            # Load PMC data
            $data = Get-PmcAllData
            $sevenDaysAgo = (Get-Date).AddDays(-7)

            # TODO column: pending, blocked, waiting (not completed)
            $this.TodoTasks = @($data.tasks | Where-Object {
                -not $_.completed -and
                ($_.status -eq 'pending' -or $_.status -eq 'blocked' -or $_.status -eq 'waiting' -or -not $_.status)
            })
            $this.TodoTasks = @($this.TodoTasks | Sort-Object -Property @{Expression={$_.priority}; Descending=$true}, id)

            # In Progress column: in-progress (not completed)
            $this.InProgressTasks = @($data.tasks | Where-Object {
                -not $_.completed -and $_.status -eq 'in-progress'
            })
            $this.InProgressTasks = @($this.InProgressTasks | Sort-Object -Property @{Expression={$_.priority}; Descending=$true}, id)

            # Done column: completed in last 7 days OR status=done
            $this.DoneTasks = @($data.tasks | Where-Object {
                ($_.completed -and $_.completedDate -and ([DateTime]$_.completedDate) -gt $sevenDaysAgo) -or
                ($_.status -eq 'done')
            })
            $this.DoneTasks = @($this.DoneTasks | Sort-Object -Property @{Expression={$_.completedDate}; Descending=$true}, id)

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
            $taskText = ""
            if ($task.priority -gt 0) {
                $taskText = "P$($task.priority) "
            }
            $taskText += $task.text

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
                if ($task.priority -gt 0) {
                    $sb.Append($priorityColor)
                    $sb.Append("P$($task.priority) ")
                    $sb.Append($reset)
                    $sb.Append($textColor)
                    $displayText = $task.text
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

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
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
            'Enter' {
                $this._ShowTaskDetail()
                return $true
            }
            'M' {
                $this._MoveTask()
                return $true
            }
            'R' {
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

    hidden [void] _ShowTaskDetail() {
        $task = $this._GetSelectedTask()
        if ($task) {
            $this.ShowStatus("Task detail: [$($task.id)] $($task.text)")
            # TODO: Push detail screen when implemented
        }
    }

    hidden [void] _MoveTask() {
        $task = $this._GetSelectedTask()
        if ($task) {
            # Cycle status: pending -> in-progress -> done -> pending
            switch ($task.status) {
                'pending' { $newStatus = 'in-progress' }
                'in-progress' { $newStatus = 'done'; $task.completed = $true; $task.completedDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') }
                'done' { $newStatus = 'pending'; $task.completed = $false; $task.completedDate = $null }
                default { $newStatus = 'in-progress' }
            }

            $task.status = $newStatus

            # Update storage
            $allData = Get-PmcAllData
            $taskToUpdate = $allData.tasks | Where-Object { $_.id -eq $task.id }
            if ($taskToUpdate) {
                $taskToUpdate.status = $newStatus
                if ($newStatus -eq 'done') {
                    $taskToUpdate.completed = $true
                    $taskToUpdate.completedDate = $task.completedDate
                } elseif ($newStatus -eq 'pending') {
                    $taskToUpdate.completed = $false
                    $taskToUpdate.completedDate = $null
                }
                Set-PmcAllData $allData
            }

            $this.ShowSuccess("Moved task #$($task.id) to $newStatus")
            $this.LoadData()  # Reload to update columns
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
