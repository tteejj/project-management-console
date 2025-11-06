using namespace System.Collections.Generic
using namespace System.Text

# AgendaViewScreen - Shows agenda view of tasks by date buckets
# Displays tasks grouped: overdue, today, tomorrow, this week, later, no due date

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Screen showing agenda view with tasks grouped by date

.DESCRIPTION
Shows tasks in six sections:
- OVERDUE: Tasks with due date before today (first 5 shown)
- TODAY: Tasks due today (first 5 shown)
- TOMORROW: Tasks due tomorrow (first 3 shown)
- THIS WEEK: Tasks due within next 7 days (first 3 shown)
- LATER: Count only of tasks due beyond this week
- NO DUE DATE: Count only of tasks without due dates

Navigation works only through the selectable tasks shown on screen.
#>
class AgendaViewScreen : PmcScreen {
    # Data
    [array]$OverdueTasks = @()
    [array]$TodayTasks = @()
    [array]$TomorrowTasks = @()
    [array]$ThisWeekTasks = @()
    [array]$LaterTasks = @()
    [array]$NoDueTasks = @()
    [array]$SelectableTasks = @()  # Only tasks shown on screen
    [int]$SelectedIndex = 0

    # Constructor
    AgendaViewScreen() : base("AgendaView", "Agenda View") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Views", "Agenda"))

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
        $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', { Write-Host "Month view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Agenda View", 'A', { $screen.LoadData() }.GetNewClosure()))
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
        $this.ShowStatus("Loading agenda...")

        try {
            # Load PMC data
            $data = Get-PmcAllData
            $activeTasks = @($data.tasks | Where-Object { -not $_.completed })

            # Date boundaries
            $nowDate = Get-Date
            $todayDate = $nowDate.Date
            $tomorrowDate = $todayDate.AddDays(1)
            $weekEndDate = $todayDate.AddDays(7)

            # Initialize arrays
            $this.OverdueTasks = @()
            $this.TodayTasks = @()
            $this.TomorrowTasks = @()
            $this.ThisWeekTasks = @()
            $this.LaterTasks = @()
            $this.NoDueTasks = @()

            # Group tasks by date
            foreach ($task in $activeTasks) {
                if ($task.due) {
                    try {
                        $dueDate = [DateTime]$task.due
                        $dueDateOnly = $dueDate.Date

                        if ($dueDateOnly -lt $todayDate) {
                            $this.OverdueTasks += $task
                        } elseif ($dueDateOnly -eq $todayDate) {
                            $this.TodayTasks += $task
                        } elseif ($dueDateOnly -eq $tomorrowDate) {
                            $this.TomorrowTasks += $task
                        } elseif ($dueDateOnly -le $weekEndDate) {
                            $this.ThisWeekTasks += $task
                        } else {
                            $this.LaterTasks += $task
                        }
                    } catch {
                        # Invalid date, treat as no due date
                        $this.NoDueTasks += $task
                    }
                } else {
                    $this.NoDueTasks += $task
                }
            }

            # Build selectable tasks list (only shown tasks)
            # First 5 overdue + first 5 today + first 3 tomorrow + first 3 this week
            $this.SelectableTasks = @()
            $this.SelectableTasks += @($this.OverdueTasks | Select-Object -First 5)
            $this.SelectableTasks += @($this.TodayTasks | Select-Object -First 5)
            $this.SelectableTasks += @($this.TomorrowTasks | Select-Object -First 3)
            $this.SelectableTasks += @($this.ThisWeekTasks | Select-Object -First 3)

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.SelectableTasks.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.SelectableTasks.Count - 1)
            }

            # Update status
            $totalSelectable = $this.SelectableTasks.Count
            $totalAll = $activeTasks.Count
            $this.ShowStatus("Showing $totalSelectable of $totalAll active tasks")

        } catch {
            $this.ShowError("Failed to load agenda: $_")
            $this.OverdueTasks = @()
            $this.TodayTasks = @()
            $this.TomorrowTasks = @()
            $this.ThisWeekTasks = @()
            $this.LaterTasks = @()
            $this.NoDueTasks = @()
            $this.SelectableTasks = @()
        }
    }

    [string] RenderContent() {
        return $this._RenderTaskList()
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
        $todayColor = $this.Header.GetThemedAnsi('Warning', $false)
        $tomorrowColor = $this.Header.GetThemedAnsi('Accent', $false)
        $weekColor = $this.Header.GetThemedAnsi('Success', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        $y = $this.Header.Y + 4  # Start after header and breadcrumb
        $taskIndex = 0  # Track position in SelectableTasks
        $todayDate = (Get-Date).Date

        # OVERDUE section
        if ($this.OverdueTasks.Count -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($overdueColor)
            $sb.Append("OVERDUE ($($this.OverdueTasks.Count)):")
            $sb.Append($reset)

            $displayCount = [Math]::Min(5, $this.OverdueTasks.Count)
            for ($i = 0; $i -lt $displayCount; $i++) {
                $task = $this.OverdueTasks[$i]
                $isSelected = ($taskIndex -eq $this.SelectedIndex)
                $dueDate = [DateTime]$task.due
                $daysOverdue = ($todayDate - $dueDate.Date).Days
                $taskText = "[$($task.id)] $($task.text) (-$daysOverdue days)"

                # Cursor
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
                if ($isSelected) {
                    $sb.Append($cursorColor)
                    $sb.Append(">")
                    $sb.Append($reset)
                } else {
                    $sb.Append(" ")
                }

                # Task text
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
                if ($isSelected) {
                    $sb.Append($selectedBg)
                    $sb.Append($selectedFg)
                } else {
                    $sb.Append($overdueColor)
                }

                $maxWidth = $contentRect.Width - 8
                if ($taskText.Length -gt $maxWidth) {
                    $taskText = $taskText.Substring(0, $maxWidth - 3) + "..."
                }
                $sb.Append($taskText)
                $sb.Append($reset)

                $taskIndex++
            }

            if ($this.OverdueTasks.Count -gt 5) {
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
                $sb.Append($mutedColor)
                $sb.Append("... and $($this.OverdueTasks.Count - 5) more")
                $sb.Append($reset)
            }
            $y++
        }

        # TODAY section
        if ($this.TodayTasks.Count -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($todayColor)
            $sb.Append("TODAY ($($this.TodayTasks.Count)):")
            $sb.Append($reset)

            $displayCount = [Math]::Min(5, $this.TodayTasks.Count)
            for ($i = 0; $i -lt $displayCount; $i++) {
                $task = $this.TodayTasks[$i]
                $isSelected = ($taskIndex -eq $this.SelectedIndex)
                $taskText = "[$($task.id)] $($task.text)"

                # Cursor
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
                if ($isSelected) {
                    $sb.Append($cursorColor)
                    $sb.Append(">")
                    $sb.Append($reset)
                } else {
                    $sb.Append(" ")
                }

                # Task text
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
                if ($isSelected) {
                    $sb.Append($selectedBg)
                    $sb.Append($selectedFg)
                } else {
                    $sb.Append($todayColor)
                }

                $maxWidth = $contentRect.Width - 8
                if ($taskText.Length -gt $maxWidth) {
                    $taskText = $taskText.Substring(0, $maxWidth - 3) + "..."
                }
                $sb.Append($taskText)
                $sb.Append($reset)

                $taskIndex++
            }

            if ($this.TodayTasks.Count -gt 5) {
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
                $sb.Append($mutedColor)
                $sb.Append("... and $($this.TodayTasks.Count - 5) more")
                $sb.Append($reset)
            }
            $y++
        }

        # TOMORROW section
        if ($this.TomorrowTasks.Count -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($tomorrowColor)
            $sb.Append("TOMORROW ($($this.TomorrowTasks.Count)):")
            $sb.Append($reset)

            $displayCount = [Math]::Min(3, $this.TomorrowTasks.Count)
            for ($i = 0; $i -lt $displayCount; $i++) {
                $task = $this.TomorrowTasks[$i]
                $isSelected = ($taskIndex -eq $this.SelectedIndex)
                $taskText = "[$($task.id)] $($task.text)"

                # Cursor
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
                if ($isSelected) {
                    $sb.Append($cursorColor)
                    $sb.Append(">")
                    $sb.Append($reset)
                } else {
                    $sb.Append(" ")
                }

                # Task text
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
                if ($isSelected) {
                    $sb.Append($selectedBg)
                    $sb.Append($selectedFg)
                } else {
                    $sb.Append($tomorrowColor)
                }

                $maxWidth = $contentRect.Width - 8
                if ($taskText.Length -gt $maxWidth) {
                    $taskText = $taskText.Substring(0, $maxWidth - 3) + "..."
                }
                $sb.Append($taskText)
                $sb.Append($reset)

                $taskIndex++
            }

            if ($this.TomorrowTasks.Count -gt 3) {
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
                $sb.Append($mutedColor)
                $sb.Append("... and $($this.TomorrowTasks.Count - 3) more")
                $sb.Append($reset)
            }
            $y++
        }

        # THIS WEEK section
        if ($this.ThisWeekTasks.Count -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($weekColor)
            $sb.Append("THIS WEEK ($($this.ThisWeekTasks.Count)):")
            $sb.Append($reset)

            $displayCount = [Math]::Min(3, $this.ThisWeekTasks.Count)
            for ($i = 0; $i -lt $displayCount; $i++) {
                $task = $this.ThisWeekTasks[$i]
                $isSelected = ($taskIndex -eq $this.SelectedIndex)
                $dueDate = [DateTime]$task.due
                $taskText = "[$($task.id)] $($task.text) ($($dueDate.ToString('ddd MMM dd')))"

                # Cursor
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
                if ($isSelected) {
                    $sb.Append($cursorColor)
                    $sb.Append(">")
                    $sb.Append($reset)
                } else {
                    $sb.Append(" ")
                }

                # Task text
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
                if ($isSelected) {
                    $sb.Append($selectedBg)
                    $sb.Append($selectedFg)
                } else {
                    $sb.Append($textColor)
                }

                $maxWidth = $contentRect.Width - 8
                if ($taskText.Length -gt $maxWidth) {
                    $taskText = $taskText.Substring(0, $maxWidth - 3) + "..."
                }
                $sb.Append($taskText)
                $sb.Append($reset)

                $taskIndex++
            }

            if ($this.ThisWeekTasks.Count -gt 3) {
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
                $sb.Append($mutedColor)
                $sb.Append("... and $($this.ThisWeekTasks.Count - 3) more")
                $sb.Append($reset)
            }
            $y++
        }

        # LATER section (count only)
        if ($this.LaterTasks.Count -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($textColor)
            $sb.Append("LATER ($($this.LaterTasks.Count))")
            $sb.Append($reset)
            $y++
        }

        # NO DUE DATE section (count only)
        if ($this.NoDueTasks.Count -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($mutedColor)
            $sb.Append("NO DUE DATE ($($this.NoDueTasks.Count))")
            $sb.Append($reset)
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

        # Update storage
        $allData = Get-PmcAllData
        $taskToComplete = $allData.tasks | Where-Object { $_.id -eq $taskId }

        if ($taskToComplete) {
            $taskToComplete.completed = $true
            $taskToComplete.completedDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            Set-PmcAllData $allData
        }

        # Reload data to refresh all buckets
        $this.LoadData()

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
function Show-AgendaViewScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [AgendaViewScreen]::new()
    $App.PushScreen($screen)
}
