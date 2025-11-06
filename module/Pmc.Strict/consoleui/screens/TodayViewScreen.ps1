using namespace System.Collections.Generic
using namespace System.Text

# TodayViewScreen - Shows tasks due today
# Displays tasks with due date == today

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Screen showing today's tasks

.DESCRIPTION
Shows list of tasks with due date == today and not completed.
Tasks are sorted by priority (descending), then by id.
#>
class TodayViewScreen : PmcScreen {
    # Data
    [array]$TodayTasks = @()
    [int]$SelectedIndex = 0

    # Constructor
    TodayViewScreen() : base("TodayView", "Today's Tasks") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks", "Today"))

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
        $this.ShowStatus("Loading today's tasks...")

        try {
            # Load PMC data
            $data = Get-PmcAllData
            $today = (Get-Date).Date

            # Filter today's tasks (due == today and not completed)
            $this.TodayTasks = @($data.tasks | Where-Object {
                -not $_.completed -and $_.due -and ([DateTime]$_.due).Date -eq $today
            })

            # Sort by priority (descending), then id
            $this.TodayTasks = @($this.TodayTasks | Sort-Object -Property @{Expression={$_.priority}; Descending=$true}, id)

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.TodayTasks.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.TodayTasks.Count - 1)
            }

            # Update status
            if ($this.TodayTasks.Count -eq 0) {
                $this.ShowSuccess("No tasks due today")
            } else {
                $this.ShowStatus("$($this.TodayTasks.Count) tasks due today")
            }

        } catch {
            $this.ShowError("Failed to load today's tasks: $_")
            $this.TodayTasks = @()
        }
    }

    [string] RenderContent() {
        if ($this.TodayTasks.Count -eq 0) {
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
            $message = "No tasks due today - Enjoy your day!"
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
        $successColor = $this.Header.GetThemedAnsi('Success', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        # Column widths
        $priorityWidth = 4   # "P2  "
        $statusWidth = 12    # "in-progress "
        $textWidth = $contentRect.Width - $priorityWidth - $statusWidth - 10

        # Render column headers
        $headerY = $this.Header.Y + 3
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($headerColor)
        $sb.Append("PRI ")
        $sb.Append("STATUS       ")
        $sb.Append("TASK")
        $sb.Append($reset)

        # Render task rows
        $startY = $headerY + 2
        $maxLines = $contentRect.Height - 4

        for ($i = 0; $i -lt [Math]::Min($this.TodayTasks.Count, $maxLines); $i++) {
            $task = $this.TodayTasks[$i]
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

            # Status column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($task.status) {
                $statusColor = $textColor
                if ($task.status -eq 'done') {
                    $statusColor = $successColor
                } elseif ($task.status -eq 'in-progress') {
                    $statusColor = $priorityColor
                }
                $sb.Append($statusColor)
                $sb.Append($task.status.PadRight($statusWidth))
                $sb.Append($reset)
            } else {
                $sb.Append(" " * $statusWidth)
            }
            $x += $statusWidth

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
        if ($this.TodayTasks.Count -gt $maxLines) {
            $y = $startY + $maxLines
            $remaining = $this.TodayTasks.Count - $maxLines
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("... and $remaining more")
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        if ($this.TodayTasks.Count -eq 0) {
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
                if ($this.SelectedIndex -lt ($this.TodayTasks.Count - 1)) {
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
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.TodayTasks.Count) {
            $task = $this.TodayTasks[$this.SelectedIndex]
            $this.ShowStatus("Task detail: [$($task.id)] $($task.text)")
            # TODO: Push detail screen when implemented
        }
    }

    hidden [void] _EditTask() {
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.TodayTasks.Count) {
            $task = $this.TodayTasks[$this.SelectedIndex]
            $this.ShowStatus("Edit task: [$($task.id)]")
            # TODO: Push edit screen when implemented
        }
    }

    hidden [void] _CompleteTask() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.TodayTasks.Count) {
            return
        }

        $task = $this.TodayTasks[$this.SelectedIndex]
        $taskId = $task.id

        # Remove from in-memory array
        $this.TodayTasks = @($this.TodayTasks | Where-Object { $_.id -ne $taskId })

        # Adjust selection
        if ($this.SelectedIndex -ge $this.TodayTasks.Count -and $this.TodayTasks.Count -gt 0) {
            $this.SelectedIndex = $this.TodayTasks.Count - 1
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
function Show-TodayViewScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [TodayViewScreen]::new()
    $App.PushScreen($screen)
}
