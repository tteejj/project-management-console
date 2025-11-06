using namespace System.Collections.Generic
using namespace System.Text

# WeekViewScreen - Shows tasks for the current week
# Displays tasks with due date in current week (Monday-Sunday)

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Screen showing this week's tasks

.DESCRIPTION
Shows list of tasks with due date in current week (Monday-Sunday).
Tasks are sorted by due date, then by priority (descending).
#>
class WeekViewScreen : PmcScreen {
    # Data
    [array]$WeekTasks = @()
    [int]$SelectedIndex = 0
    [DateTime]$WeekStart
    [DateTime]$WeekEnd

    # Constructor
    WeekViewScreen() : base("WeekView", "This Week's Tasks") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks", "This Week"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "Detail")
        $this.Footer.AddShortcut("E", "Edit")
        $this.Footer.AddShortcut("C", "Complete")
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
        $this.ShowStatus("Loading this week's tasks...")

        try {
            # Calculate week start (Monday) and end (Sunday)
            $today = (Get-Date).Date
            $dayOfWeek = [int]$today.DayOfWeek
            # If Sunday (0), adjust to 7 for calculation
            if ($dayOfWeek -eq 0) { $dayOfWeek = 7 }

            # Monday of current week
            $this.WeekStart = $today.AddDays(1 - $dayOfWeek)
            # Sunday of current week
            $this.WeekEnd = $this.WeekStart.AddDays(6)

            # Load PMC data
            $data = Get-PmcAllData

            # Filter week's tasks (due >= weekStart and due <= weekEnd and not completed)
            $this.WeekTasks = @($data.tasks | Where-Object {
                -not $_.completed -and $_.due -and
                ([DateTime]$_.due).Date -ge $this.WeekStart -and
                ([DateTime]$_.due).Date -le $this.WeekEnd
            })

            # Sort by due date, then priority (descending)
            $this.WeekTasks = @($this.WeekTasks | Sort-Object -Property @{Expression={$_.due}; Ascending=$true}, @{Expression={$_.priority}; Descending=$true})

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.WeekTasks.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.WeekTasks.Count - 1)
            }

            # Update status with week range
            $weekRange = "$($this.WeekStart.ToString('MMM dd')) - $($this.WeekEnd.ToString('MMM dd'))"
            if ($this.WeekTasks.Count -eq 0) {
                $this.ShowSuccess("No tasks this week ($weekRange)")
            } else {
                $this.ShowStatus("$($this.WeekTasks.Count) tasks this week ($weekRange)")
            }

        } catch {
            $this.ShowError("Failed to load week's tasks: $_")
            $this.WeekTasks = @()
        }
    }

    [string] RenderContent() {
        if ($this.WeekTasks.Count -eq 0) {
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
            $weekRange = "$($this.WeekStart.ToString('MMM dd')) - $($this.WeekEnd.ToString('MMM dd'))"
            $message = "No tasks this week ($weekRange)"
            $x = $contentRect.X + [Math]::Floor(($contentRect.Width - $message.Length) / 2)
            $y = $contentRect.Y + [Math]::Floor($contentRect.Height / 2)

            $successColor = $this.Header.GetThemedAnsi('Success', $false)
            $reset = "`e[0m"

            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($successColor)
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
        $cursorColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $priorityColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
        $todayColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $overdueColor = $this.Header.GetThemedAnsi('Error', $false)
        $reset = "`e[0m"

        # Column widths
        $priorityWidth = 4   # "P2  "
        $dueWidth = 8        # "11/15   "
        $dayWidth = 4        # "Mon "
        $textWidth = $contentRect.Width - $priorityWidth - $dueWidth - $dayWidth - 10

        # Render column headers
        $headerY = $this.Header.Y + 3
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($headerColor)
        $sb.Append("PRI ")
        $sb.Append("DUE      ")
        $sb.Append("DAY  ")
        $sb.Append("TASK")
        $sb.Append($reset)

        # Render task rows
        $startY = $headerY + 2
        $maxLines = $contentRect.Height - 4
        $today = (Get-Date).Date

        for ($i = 0; $i -lt [Math]::Min($this.WeekTasks.Count, $maxLines); $i++) {
            $task = $this.WeekTasks[$i]
            $y = $startY + $i
            $isSelected = ($i -eq $this.SelectedIndex)

            # Cursor
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
            if ($isSelected) {
                $sb.Append($cursorColor)
                $sb.Append(">")
                $sb.Append($reset)
            } else {
                $sb.Append(" ")
            }

            # Task row with columns
            $x = $contentRect.X + 4

            # Priority column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($task.priority -gt 0) {
                $sb.Append($priorityColor)
                $sb.Append("P$($task.priority)".PadRight($priorityWidth))
                $sb.Append($reset)
            } else {
                $sb.Append(" " * $priorityWidth)
            }
            $x += $priorityWidth

            # Due column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($task.due) {
                $dueDate = ([DateTime]$task.due).Date
                $schema = Get-PmcFieldSchema -Domain 'task' -Field 'due'
                $dueDisplay = & $schema.DisplayFormat $task.due

                # Color based on due date
                if ($dueDate -lt $today) {
                    $sb.Append($overdueColor)
                } elseif ($dueDate -eq $today) {
                    $sb.Append($todayColor)
                } else {
                    $sb.Append($mutedColor)
                }
                $sb.Append($dueDisplay.PadRight($dueWidth))
                $sb.Append($reset)
            } else {
                $sb.Append(" " * $dueWidth)
            }
            $x += $dueWidth

            # Day of week column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($task.due) {
                $dueDate = [DateTime]$task.due
                $dayName = $dueDate.ToString('ddd')
                $sb.Append($mutedColor)
                $sb.Append($dayName.PadRight($dayWidth))
                $sb.Append($reset)
            } else {
                $sb.Append(" " * $dayWidth)
            }
            $x += $dayWidth

            # Text column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }

            $taskText = $task.text
            if ($taskText.Length -gt $textWidth) {
                $taskText = $taskText.Substring(0, $textWidth - 3) + "..."
            }
            $sb.Append($taskText)
            $sb.Append($reset)
        }

        # Show truncation indicator if needed
        if ($this.WeekTasks.Count -gt $maxLines) {
            $y = $startY + $maxLines
            $remaining = $this.WeekTasks.Count - $maxLines
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("... and $remaining more")
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        if ($this.WeekTasks.Count -eq 0) {
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
                if ($this.SelectedIndex -lt ($this.WeekTasks.Count - 1)) {
                    $this.SelectedIndex++
                    return $true
                }
            }
            'Enter' {
                $this._ShowTaskDetail()
                return $true
            }
            'E' {
                $this._EditTask()
                return $true
            }
            'C' {
                $this._CompleteTask()
                return $true
            }
            'R' {
                $this.LoadData()
                return $true
            }
        }

        return $false
    }

    hidden [void] _ShowTaskDetail() {
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.WeekTasks.Count) {
            $task = $this.WeekTasks[$this.SelectedIndex]
            $this.ShowStatus("Task detail: [$($task.id)] $($task.text)")
            # TODO: Push detail screen when implemented
        }
    }

    hidden [void] _EditTask() {
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.WeekTasks.Count) {
            $task = $this.WeekTasks[$this.SelectedIndex]
            $this.ShowStatus("Edit task: [$($task.id)]")
            # TODO: Push edit screen when implemented
        }
    }

    hidden [void] _CompleteTask() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.WeekTasks.Count) {
            return
        }

        $task = $this.WeekTasks[$this.SelectedIndex]
        $taskId = $task.id

        # Remove from in-memory array
        $this.WeekTasks = @($this.WeekTasks | Where-Object { $_.id -ne $taskId })

        # Adjust selection
        if ($this.SelectedIndex -ge $this.WeekTasks.Count -and $this.WeekTasks.Count -gt 0) {
            $this.SelectedIndex = $this.WeekTasks.Count - 1
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
}

# Entry point function for compatibility
function Show-WeekViewScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [WeekViewScreen]::new()
    $App.PushScreen($screen)
}
