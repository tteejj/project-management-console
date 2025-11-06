using namespace System.Collections.Generic
using namespace System.Text

# MonthViewScreen - Shows tasks due this month
# Displays tasks in three sections: overdue, this month, and no due date

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Screen showing this month's tasks with overdue and undated tasks

.DESCRIPTION
Shows tasks in three sections:
- OVERDUE: Tasks with due date before today
- DUE THIS MONTH: Tasks with due date between today and 30 days from now
- NO DUE DATE: Tasks without a due date

Tasks are selectable and can be completed with the C key.
#>
class MonthViewScreen : PmcScreen {
    # Data
    [array]$OverdueTasks = @()
    [array]$ThisMonthTasks = @()
    [array]$NoDueDateTasks = @()
    [array]$SelectableTasks = @()  # Combined list for navigation
    [int]$SelectedIndex = 0

    # Constructor
    MonthViewScreen() : base("MonthView", "This Month's Tasks") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Views", "Month"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("C", "Complete")
        $this.Footer.AddShortcut("E", "Edit")
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
        $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', { $screen.LoadData() }.GetNewClosure()))
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
        $this.ShowStatus("Loading this month's tasks...")

        try {
            # Load PMC data
            $data = Get-PmcAllData
            $today = (Get-Date).Date
            $monthEnd = $today.AddDays(30)

            # Get overdue tasks
            $this.OverdueTasks = @($data.tasks | Where-Object {
                if ($_.completed -or -not $_.due) { return $false }
                try {
                    $dueDate = [DateTime]$_.due
                    return ($dueDate.Date -lt $today)
                } catch {
                    return $false
                }
            } | Sort-Object { [DateTime]$_.due })

            # Get tasks due this month
            $this.ThisMonthTasks = @($data.tasks | Where-Object {
                if ($_.completed -or -not $_.due) { return $false }
                try {
                    $dueDate = [DateTime]$_.due
                    return ($dueDate.Date -ge $today -and $dueDate.Date -le $monthEnd)
                } catch {
                    return $false
                }
            } | Sort-Object { [DateTime]$_.due })

            # Get undated tasks
            $this.NoDueDateTasks = @($data.tasks | Where-Object {
                -not $_.completed -and -not $_.due
            })

            # Build selectable tasks list (all tasks)
            $this.SelectableTasks = @()
            $this.SelectableTasks += $this.OverdueTasks
            $this.SelectableTasks += $this.ThisMonthTasks
            $this.SelectableTasks += $this.NoDueDateTasks

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.SelectableTasks.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.SelectableTasks.Count - 1)
            }

            # Update status
            $totalCount = $this.OverdueTasks.Count + $this.ThisMonthTasks.Count + $this.NoDueDateTasks.Count
            if ($totalCount -eq 0) {
                $this.ShowStatus("No active tasks")
            } else {
                $this.ShowStatus("$totalCount task(s) (Overdue: $($this.OverdueTasks.Count), This Month: $($this.ThisMonthTasks.Count), No Date: $($this.NoDueDateTasks.Count))")
            }

        } catch {
            $this.ShowError("Failed to load this month's tasks: $_")
            $this.OverdueTasks = @()
            $this.ThisMonthTasks = @()
            $this.NoDueDateTasks = @()
            $this.SelectableTasks = @()
        }
    }

    [string] RenderContent() {
        if ($this.SelectableTasks.Count -eq 0) {
            return $this._RenderEmptyState()
        }

        return $this._RenderTaskList()
    }

    hidden [string] _RenderEmptyState() {
        $sb = [System.Text.StringBuilder]::new(512)

        # Get content area
        if ($this.LayoutManager) {
            $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

            # Center message
            $message = "No active tasks"
            $x = $contentRect.X + [Math]::Floor(($contentRect.Width - $message.Length) / 2)
            $y = $contentRect.Y + [Math]::Floor($contentRect.Height / 2)

            $textColor = $this.Header.GetThemedAnsi('Text', $false)
            $reset = "`e[0m"

            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($textColor)
            $sb.Append($message)
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    hidden [string] _RenderTaskList() {
        $sb = [System.Text.StringBuilder]::new(4096)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $selectedBg = $this.Header.GetThemedAnsi('Primary', $true)
        $selectedFg = $this.Header.GetThemedAnsi('Text', $false)
        $cursorColor = $this.Header.GetThemedAnsi('Accent', $false)
        $overdueColor = $this.Header.GetThemedAnsi('Error', $false)
        $monthColor = $this.Header.GetThemedAnsi('Accent', $false)
        $noDueColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        # Start rendering sections
        $y = $this.Header.Y + 4  # Start after header and breadcrumb
        $taskIndex = 0  # Track position in SelectableTasks

        # OVERDUE section
        if ($this.OverdueTasks.Count -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($overdueColor)
            $sb.Append("=== OVERDUE ($($this.OverdueTasks.Count)) ===")
            $sb.Append($reset)
            $y++

            foreach ($task in $this.OverdueTasks) {
                if ($y -ge $contentRect.Y + $contentRect.Height - 2) { break }

                $isSelected = ($taskIndex -eq $this.SelectedIndex)
                $dueDate = [DateTime]$task.due
                $daysOverdue = ((Get-Date).Date - $dueDate.Date).Days
                $taskText = "[$($task.id)] $($dueDate.ToString('MMM dd')) ($daysOverdue days ago) - $($task.text)"

                # Cursor
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
                if ($isSelected) {
                    $sb.Append($cursorColor)
                    $sb.Append(">")
                    $sb.Append($reset)
                } else {
                    $sb.Append(" ")
                }

                # Task text
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
                if ($isSelected) {
                    $sb.Append($selectedBg)
                    $sb.Append($selectedFg)
                } else {
                    $sb.Append($overdueColor)
                }

                $maxWidth = $contentRect.Width - 6
                if ($taskText.Length -gt $maxWidth) {
                    $taskText = $taskText.Substring(0, $maxWidth - 3) + "..."
                }
                $sb.Append($taskText)
                $sb.Append($reset)

                $y++
                $taskIndex++
            }
            $y++
        }

        # THIS MONTH section
        if ($this.ThisMonthTasks.Count -gt 0) {
            if ($y -ge $contentRect.Y + $contentRect.Height - 2) {
                return $sb.ToString()
            }

            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($monthColor)
            $sb.Append("=== DUE THIS MONTH ($($this.ThisMonthTasks.Count)) ===")
            $sb.Append($reset)
            $y++

            foreach ($task in $this.ThisMonthTasks) {
                if ($y -ge $contentRect.Y + $contentRect.Height - 2) { break }

                $isSelected = ($taskIndex -eq $this.SelectedIndex)
                $dueDate = [DateTime]$task.due
                $taskText = "[$($task.id)] $($dueDate.ToString('MMM dd')) - $($task.text)"

                # Cursor
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
                if ($isSelected) {
                    $sb.Append($cursorColor)
                    $sb.Append(">")
                    $sb.Append($reset)
                } else {
                    $sb.Append(" ")
                }

                # Task text
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
                if ($isSelected) {
                    $sb.Append($selectedBg)
                    $sb.Append($selectedFg)
                } else {
                    $sb.Append($textColor)
                }

                $maxWidth = $contentRect.Width - 6
                if ($taskText.Length -gt $maxWidth) {
                    $taskText = $taskText.Substring(0, $maxWidth - 3) + "..."
                }
                $sb.Append($taskText)
                $sb.Append($reset)

                $y++
                $taskIndex++
            }
            $y++
        }

        # NO DUE DATE section
        if ($this.NoDueDateTasks.Count -gt 0) {
            if ($y -ge $contentRect.Y + $contentRect.Height - 2) {
                return $sb.ToString()
            }

            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($noDueColor)
            $sb.Append("=== NO DUE DATE ($($this.NoDueDateTasks.Count)) ===")
            $sb.Append($reset)
            $y++

            foreach ($task in $this.NoDueDateTasks) {
                if ($y -ge $contentRect.Y + $contentRect.Height - 2) { break }

                $isSelected = ($taskIndex -eq $this.SelectedIndex)
                $taskText = "[$($task.id)] $($task.text)"

                # Cursor
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
                if ($isSelected) {
                    $sb.Append($cursorColor)
                    $sb.Append(">")
                    $sb.Append($reset)
                } else {
                    $sb.Append(" ")
                }

                # Task text
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
                if ($isSelected) {
                    $sb.Append($selectedBg)
                    $sb.Append($selectedFg)
                } else {
                    $sb.Append($noDueColor)
                }

                $maxWidth = $contentRect.Width - 6
                if ($taskText.Length -gt $maxWidth) {
                    $taskText = $taskText.Substring(0, $maxWidth - 3) + "..."
                }
                $sb.Append($taskText)
                $sb.Append($reset)

                $y++
                $taskIndex++
            }
        }

        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        if ($this.SelectableTasks.Count -eq 0) {
            return $false
        }

        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.SelectableTasks.Count - 1)) {
                    $this.SelectedIndex++
                    return $true
                }
            }
            'C' {
                $this._CompleteTask()
                return $true
            }
            'E' {
                $this._EditTask()
                return $true
            }
            'R' {
                $this.LoadData()
                return $true
            }
        }

        return $false
    }

    hidden [void] _CompleteTask() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.SelectableTasks.Count) {
            return
        }

        $task = $this.SelectableTasks[$this.SelectedIndex]
        $taskId = $task.id

        # Remove from in-memory arrays
        $this.OverdueTasks = @($this.OverdueTasks | Where-Object { $_.id -ne $taskId })
        $this.ThisMonthTasks = @($this.ThisMonthTasks | Where-Object { $_.id -ne $taskId })
        $this.NoDueDateTasks = @($this.NoDueDateTasks | Where-Object { $_.id -ne $taskId })
        $this.SelectableTasks = @($this.SelectableTasks | Where-Object { $_.id -ne $taskId })

        # Adjust selection
        if ($this.SelectedIndex -ge $this.SelectableTasks.Count -and $this.SelectableTasks.Count -gt 0) {
            $this.SelectedIndex = $this.SelectableTasks.Count - 1
        }

        # Update storage
        $allData = Get-PmcAllData
        $taskToComplete = $allData.tasks | Where-Object { $_.id -eq $taskId }

        if ($taskToComplete) {
            $taskToComplete.completed = $true
            $taskToComplete.completedDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            Set-PmcAllData $allData
        }

        $this.ShowSuccess("Task #$taskId completed")
    }

    hidden [void] _EditTask() {
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.SelectableTasks.Count) {
            $task = $this.SelectableTasks[$this.SelectedIndex]
            $this.ShowStatus("Edit task: [$($task.id)]")
            # TODO: Push edit screen when implemented
        }
    }
}

# Entry point function for compatibility
function Show-MonthViewScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [MonthViewScreen]::new()
    $App.PushScreen($screen)
}
