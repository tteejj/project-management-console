using namespace System.Collections.Generic
using namespace System.Text

# TaskDetailScreen - Shows detailed view of a single task
# Displays all fields for a specific task

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Screen showing detailed view of a single task

.DESCRIPTION
Shows all fields and metadata for a specific task:
- ID, text, project
- Priority, status, due date
- Created/completed dates
- Tags, dependencies
- Notes, subtasks
- Recurrence, estimated time
#>
class TaskDetailScreen : PmcScreen {
    # Data
    [object]$Task = $null
    [int]$TaskId = 0

    # Constructor with task ID
    TaskDetailScreen([int]$taskId) : base("TaskDetail", "Task Detail") {
        $this.TaskId = $taskId

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks", "Detail"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("E", "Edit")
        $this.Footer.AddShortcut("C", "Complete")
        $this.Footer.AddShortcut("D", "Delete")
        $this.Footer.AddShortcut("R", "Refresh")
        $this.Footer.AddShortcut("Esc", "Back")

        # Setup menu items
        $this._SetupMenus()
    }

    # Default constructor (for compatibility)
    TaskDetailScreen() : base("TaskDetail", "Task Detail") {
        $this.TaskId = 0

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks", "Detail"))

        # Configure footer
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Esc", "Back")

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
        if ($this.TaskId -eq 0) {
            $this.ShowError("No task ID specified")
            return
        }

        $this.ShowStatus("Loading task #$($this.TaskId)...")

        try {
            # Load PMC data
            $data = Get-PmcAllData

            # Find the task
            $this.Task = $data.tasks | Where-Object { $_.id -eq $this.TaskId } | Select-Object -First 1

            if (-not $this.Task) {
                $this.ShowError("Task #$($this.TaskId) not found")
                return
            }

            # Update header with task ID
            $this.Header.SetTitle("Task #$($this.TaskId)")
            $this.ShowStatus("Loaded task #$($this.TaskId)")

        } catch {
            $this.ShowError("Failed to load task: $_")
            $this.Task = $null
        }
    }

    [string] RenderContent() {
        if (-not $this.Task) {
            return $this._RenderEmptyState()
        }

        return $this._RenderTaskDetail()
    }

    hidden [string] _RenderEmptyState() {
        $sb = [System.Text.StringBuilder]::new(512)

        # Get content area
        if ($this.LayoutManager) {
            $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

            # Center message
            $message = if ($this.TaskId -eq 0) { "No task selected" } else { "Task #$($this.TaskId) not found" }
            $x = $contentRect.X + [Math]::Floor(($contentRect.Width - $message.Length) / 2)
            $y = $contentRect.Y + [Math]::Floor($contentRect.Height / 2)

            $errorColor = $this.Header.GetThemedAnsi('Error', $false)
            $reset = "`e[0m"

            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($errorColor)
            $sb.Append($message)
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    hidden [string] _RenderTaskDetail() {
        $sb = [System.Text.StringBuilder]::new(4096)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $labelColor = $this.Header.GetThemedAnsi('Muted', $false)
        $valueColor = $this.Header.GetThemedAnsi('Text', $false)
        $priorityColor = $this.Header.GetThemedAnsi('Warning', $false)
        $successColor = $this.Header.GetThemedAnsi('Success', $false)
        $errorColor = $this.Header.GetThemedAnsi('Error', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        $x = $contentRect.X + 4
        $y = $contentRect.Y + 2
        $labelWidth = 18

        # Task ID and Status
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($labelColor)
        $sb.Append("ID:".PadRight($labelWidth))
        $sb.Append($reset)
        $sb.Append($valueColor)
        $sb.Append("#$($this.Task.id)")
        $sb.Append($reset)

        # Completion status indicator
        $sb.Append("  ")
        if ($this.Task.completed) {
            $sb.Append($successColor)
            $sb.Append("[COMPLETED]")
        } else {
            $statusColor = $textColor
            if ($this.Task.status -eq 'blocked') { $statusColor = $errorColor }
            elseif ($this.Task.status -eq 'in-progress') { $statusColor = $priorityColor }
            $sb.Append($statusColor)
            $sb.Append("[$($this.Task.status.ToUpper())]")
        }
        $sb.Append($reset)
        $y++

        # Text
        $y++
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($labelColor)
        $sb.Append("Task:".PadRight($labelWidth))
        $sb.Append($reset)
        $sb.Append($valueColor)
        $sb.Append($this.Task.text)
        $sb.Append($reset)
        $y++

        # Project
        $y++
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($labelColor)
        $sb.Append("Project:".PadRight($labelWidth))
        $sb.Append($reset)
        $sb.Append($valueColor)
        $sb.Append($this.Task.project)
        $sb.Append($reset)
        $y++

        # Priority
        $y++
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($labelColor)
        $sb.Append("Priority:".PadRight($labelWidth))
        $sb.Append($reset)
        if ($this.Task.priority -gt 0) {
            $sb.Append($priorityColor)
            $sb.Append("P$($this.Task.priority)")
        } else {
            $sb.Append($mutedColor)
            $sb.Append("None")
        }
        $sb.Append($reset)
        $y++

        # Status
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($labelColor)
        $sb.Append("Status:".PadRight($labelWidth))
        $sb.Append($reset)
        $sb.Append($valueColor)
        $sb.Append($this.Task.status)
        $sb.Append($reset)
        $y++

        # Due Date
        $y++
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($labelColor)
        $sb.Append("Due Date:".PadRight($labelWidth))
        $sb.Append($reset)
        if ($this.Task.due) {
            $schema = Get-PmcFieldSchema -Domain 'task' -Field 'due'
            $dueDisplay = & $schema.DisplayFormat $this.Task.due

            # Color based on due date
            $dueDate = ([DateTime]$this.Task.due).Date
            $today = (Get-Date).Date
            if (-not $this.Task.completed -and $dueDate -lt $today) {
                $sb.Append($errorColor)
                $sb.Append("$dueDisplay (OVERDUE)")
            } elseif ($dueDate -eq $today) {
                $sb.Append($priorityColor)
                $sb.Append("$dueDisplay (TODAY)")
            } else {
                $sb.Append($valueColor)
                $sb.Append($dueDisplay)
            }
        } else {
            $sb.Append($mutedColor)
            $sb.Append("Not set")
        }
        $sb.Append($reset)
        $y++

        # Created Date
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($labelColor)
        $sb.Append("Created:".PadRight($labelWidth))
        $sb.Append($reset)
        if ($this.Task.created) {
            $sb.Append($mutedColor)
            $sb.Append($this.Task.created)
        } else {
            $sb.Append($mutedColor)
            $sb.Append("Unknown")
        }
        $sb.Append($reset)
        $y++

        # Completed Date
        if ($this.Task.completed -and $this.Task.completedDate) {
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($labelColor)
            $sb.Append("Completed:".PadRight($labelWidth))
            $sb.Append($reset)
            $sb.Append($successColor)
            $sb.Append($this.Task.completedDate)
            $sb.Append($reset)
            $y++
        }

        # Estimated Time
        $y++
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($labelColor)
        $sb.Append("Estimated Time:".PadRight($labelWidth))
        $sb.Append($reset)
        if ($this.Task.estimatedMinutes) {
            $hours = [Math]::Floor($this.Task.estimatedMinutes / 60)
            $mins = $this.Task.estimatedMinutes % 60
            $sb.Append($valueColor)
            if ($hours -gt 0) {
                $sb.Append("${hours}h ${mins}m")
            } else {
                $sb.Append("${mins}m")
            }
        } else {
            $sb.Append($mutedColor)
            $sb.Append("Not set")
        }
        $sb.Append($reset)
        $y++

        # Recurrence
        if ($this.Task.recur) {
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($labelColor)
            $sb.Append("Recurrence:".PadRight($labelWidth))
            $sb.Append($reset)
            $sb.Append($valueColor)
            $sb.Append($this.Task.recur)
            $sb.Append($reset)
            $y++
        }

        # Tags
        $y++
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($labelColor)
        $sb.Append("Tags:".PadRight($labelWidth))
        $sb.Append($reset)
        if ($this.Task.tags -and $this.Task.tags.Count -gt 0) {
            $sb.Append($valueColor)
            $sb.Append(($this.Task.tags -join ", "))
        } else {
            $sb.Append($mutedColor)
            $sb.Append("None")
        }
        $sb.Append($reset)
        $y++

        # Dependencies
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($labelColor)
        $sb.Append("Depends On:".PadRight($labelWidth))
        $sb.Append($reset)
        if ($this.Task.depends -and $this.Task.depends.Count -gt 0) {
            $sb.Append($valueColor)
            $sb.Append(($this.Task.depends -join ", "))
        } else {
            $sb.Append($mutedColor)
            $sb.Append("None")
        }
        $sb.Append($reset)
        $y++

        # Notes
        if ($this.Task.notes -and $this.Task.notes.Count -gt 0) {
            $y++
            $y++
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($labelColor)
            $sb.Append("Notes:")
            $sb.Append($reset)
            $y++

            foreach ($note in $this.Task.notes) {
                $sb.Append($this.Header.BuildMoveTo($x + 2, $y))
                $sb.Append($mutedColor)
                $sb.Append("- ")
                $sb.Append($reset)
                $sb.Append($textColor)
                $noteText = [string]$note
                $maxWidth = $contentRect.Width - $x - 4
                if ($noteText.Length -gt $maxWidth) {
                    $noteText = $noteText.Substring(0, $maxWidth - 3) + "..."
                }
                $sb.Append($noteText)
                $sb.Append($reset)
                $y++
            }
        }

        # Subtasks
        if ($this.Task.subtasks -and $this.Task.subtasks.Count -gt 0) {
            $y++
            $y++
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($labelColor)
            $sb.Append("Subtasks:")
            $sb.Append($reset)
            $y++

            foreach ($subtask in $this.Task.subtasks) {
                $sb.Append($this.Header.BuildMoveTo($x + 2, $y))
                $sb.Append($mutedColor)
                $sb.Append("[ ] ")
                $sb.Append($reset)
                $sb.Append($textColor)
                $subtaskText = [string]$subtask
                $maxWidth = $contentRect.Width - $x - 6
                if ($subtaskText.Length -gt $maxWidth) {
                    $subtaskText = $subtaskText.Substring(0, $maxWidth - 3) + "..."
                }
                $sb.Append($subtaskText)
                $sb.Append($reset)
                $y++
            }
        }

        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        if (-not $this.Task) {
            return $false
        }

        switch ($keyInfo.Key) {
            'E' {
                $this._EditTask()
                return $true
            }
            'C' {
                $this._CompleteTask()
                return $true
            }
            'D' {
                $this._DeleteTask()
                return $true
            }
            'R' {
                $this.LoadData()
                return $true
            }
        }

        return $false
    }

    hidden [void] _EditTask() {
        if ($this.Task) {
            $this.ShowStatus("Edit task: [$($this.Task.id)]")
            # TODO: Push edit screen when implemented
        }
    }

    hidden [void] _CompleteTask() {
        if (-not $this.Task) {
            return
        }

        $taskId = $this.Task.id

        # Update storage
        $allData = Get-PmcAllData
        $taskToComplete = $allData.tasks | Where-Object { $_.id -eq $taskId }

        if ($taskToComplete) {
            $taskToComplete.completed = $true
            $taskToComplete.completedDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            Set-PmcAllData $allData
        }

        $this.ShowSuccess("Task #$taskId completed")
        $this.LoadData()  # Reload to show updated status
    }

    hidden [void] _DeleteTask() {
        if (-not $this.Task) {
            return
        }

        $taskId = $this.Task.id

        # Update storage
        $allData = Get-PmcAllData
        $allData.tasks = @($allData.tasks | Where-Object { $_.id -ne $taskId })
        Set-PmcAllData $allData

        $this.ShowSuccess("Task #$taskId deleted - Press Esc to go back")
        $this.Task = $null  # Clear task to show empty state
    }

    # Helper method to set task ID after construction
    [void] SetTaskId([int]$taskId) {
        $this.TaskId = $taskId
    }
}

# Entry point function for compatibility
function Show-TaskDetailScreen {
    param(
        [object]$App,
        [int]$TaskId
    )

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [TaskDetailScreen]::new($TaskId)
    $App.PushScreen($screen)
}
