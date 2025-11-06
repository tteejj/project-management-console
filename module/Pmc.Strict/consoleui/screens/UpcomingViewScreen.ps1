using namespace System.Collections.Generic
using namespace System.Text

# UpcomingViewScreen - Shows tasks due in the future
# Displays tasks with due date > today, sorted by due date

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Screen showing upcoming tasks

.DESCRIPTION
Shows list of tasks with due date in the future (> today) and not completed.
Tasks are sorted by due date (earliest first), then by priority.
Useful for planning ahead and seeing what's coming up.
#>
class UpcomingViewScreen : PmcScreen {
    # Data
    [array]$UpcomingTasks = @()
    [int]$SelectedIndex = 0

    # Constructor
    UpcomingViewScreen() : base("UpcomingView", "Upcoming Tasks (Next 7 Days)") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks", "Upcoming"))

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
        $tasksMenu.Items.Add([PmcMenuItem]::new("Upcoming", 'U', { $screen.LoadData() }.GetNewClosure()))
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
        $this.ShowStatus("Loading upcoming tasks...")

        try {
            # Load PMC data
            $data = Get-PmcAllData
            $today = (Get-Date).Date
            $weekEnd = $today.AddDays(7)

            # Filter upcoming tasks (due > today AND due <= today+7 days and not completed)
            # This matches original: next 7 days ONLY, not all future tasks
            $this.UpcomingTasks = @($data.tasks | Where-Object {
                -not $_.completed -and $_.due -and
                ([DateTime]$_.due).Date -gt $today -and ([DateTime]$_.due).Date -le $weekEnd
            })

            # Sort by due date (earliest first), then priority (descending)
            $this.UpcomingTasks = @($this.UpcomingTasks | Sort-Object -Property @{Expression={$_.due}; Ascending=$true}, @{Expression={$_.priority}; Descending=$true})

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.UpcomingTasks.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.UpcomingTasks.Count - 1)
            }

            # Update status
            if ($this.UpcomingTasks.Count -eq 0) {
                $this.ShowStatus("No upcoming tasks")
            } else {
                $this.ShowStatus("$($this.UpcomingTasks.Count) upcoming task(s)")
            }

        } catch {
            $this.ShowError("Failed to load upcoming tasks: $_")
            $this.UpcomingTasks = @()
        }
    }

    [string] RenderContent() {
        if ($this.UpcomingTasks.Count -eq 0) {
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
            $message = "No upcoming tasks"
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
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
        $priorityColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $infoColor = $this.Header.GetThemedAnsi('Info', $false)
        $reset = "`e[0m"

        # Render column headers at line 4 (ABOVE separator which is at line 5)
        $headerY = $this.Header.Y + 3
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($headerColor)
        $sb.Append("PRI ")
        $sb.Append("DUE      ")
        $sb.Append("IN     ")
        $sb.Append("TASK")
        $sb.Append($reset)

        # Render task rows
        $startY = $headerY + 2
        $maxLines = $contentRect.Height - 4
        $today = (Get-Date).Date

        for ($i = 0; $i -lt [Math]::Min($this.UpcomingTasks.Count, $maxLines); $i++) {
            $task = $this.UpcomingTasks[$i]
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

            # Task row
            $x = $contentRect.X + 4

            # Priority column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } elseif ($task.priority -gt 0) {
                $sb.Append($priorityColor)
            }
            $priText = if ($task.priority) { $task.priority.ToString().PadLeft(3) } else { "   " }
            $sb.Append($priText)
            $sb.Append(" ")
            $sb.Append($reset)
            $x += 4

            # Due date column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($infoColor)
            }
            $dueText = if ($task.due) { ([DateTime]$task.due).ToString("yyyy-MM-dd") } else { "          " }
            $sb.Append($dueText)
            $sb.Append(" ")
            $sb.Append($reset)
            $x += 11

            # Days until due column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($mutedColor)
            }
            if ($task.due) {
                $dueDate = ([DateTime]$task.due).Date
                $daysUntil = ($dueDate - $today).Days
                $inText = if ($daysUntil -eq 1) { "1 day" } else { "$daysUntil days" }
                $sb.Append($inText.PadRight(7))
            } else {
                $sb.Append("       ")
            }
            $sb.Append($reset)
            $x += 7

            # Task text column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }
            $maxTaskWidth = $contentRect.Width - ($x - $contentRect.X)
            $taskText = $task.text
            if ($taskText.Length -gt $maxTaskWidth) {
                $taskText = $taskText.Substring(0, $maxTaskWidth - 3) + "..."
            }
            $sb.Append($taskText)
            $sb.Append($reset)
        }

        # Show truncation indicator if needed
        if ($this.UpcomingTasks.Count -gt $maxLines) {
            $y = $startY + $maxLines
            $remaining = $this.UpcomingTasks.Count - $maxLines
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("... and $remaining more")
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        if ($this.UpcomingTasks.Count -eq 0) {
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
                if ($this.SelectedIndex -lt ($this.UpcomingTasks.Count - 1)) {
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
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.UpcomingTasks.Count) {
            $task = $this.UpcomingTasks[$this.SelectedIndex]
            $this.ShowStatus("Task detail: [$($task.id)] $($task.text)")
            # TODO: Push detail screen when implemented
        }
    }

    hidden [void] _EditTask() {
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.UpcomingTasks.Count) {
            $task = $this.UpcomingTasks[$this.SelectedIndex]
            $this.ShowStatus("Edit task: [$($task.id)]")
            # TODO: Push edit screen when implemented
        }
    }

    hidden [void] _CompleteTask() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.UpcomingTasks.Count) {
            return
        }

        $task = $this.UpcomingTasks[$this.SelectedIndex]
        $taskId = $task.id

        # Remove from in-memory array
        $this.UpcomingTasks = @($this.UpcomingTasks | Where-Object { $_.id -ne $taskId })

        # Adjust selection
        if ($this.SelectedIndex -ge $this.UpcomingTasks.Count -and $this.UpcomingTasks.Count -gt 0) {
            $this.SelectedIndex = $this.UpcomingTasks.Count - 1
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
function Show-UpcomingViewScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [UpcomingViewScreen]::new()
    $App.PushScreen($screen)
}
