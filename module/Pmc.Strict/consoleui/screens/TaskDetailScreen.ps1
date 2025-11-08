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
        $tasksMenu.Items.Add([PmcMenuItem]::new("Task List", 'L', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen((New-Object TaskListScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Today", 'Y', {
            . "$PSScriptRoot/TodayViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object TodayViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Tomorrow", 'T', {
            . "$PSScriptRoot/TomorrowViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object TomorrowViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Week View", 'W', {
            . "$PSScriptRoot/WeekViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object WeekViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Upcoming", 'U', {
            . "$PSScriptRoot/UpcomingViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object UpcomingViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Overdue", 'V', {
            . "$PSScriptRoot/OverdueViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object OverdueViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Next Actions", 'N', {
            . "$PSScriptRoot/NextActionsViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object NextActionsViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("No Due Date", 'D', {
            . "$PSScriptRoot/NoDueDateViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object NoDueDateViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Blocked Tasks", 'B', {
            . "$PSScriptRoot/BlockedTasksScreen.ps1"
            $global:PmcApp.PushScreen((New-Object BlockedTasksScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::Separator())
        $tasksMenu.Items.Add([PmcMenuItem]::new("Kanban Board", 'K', {
            . "$PSScriptRoot/KanbanScreen.ps1"
            $global:PmcApp.PushScreen((New-Object KanbanScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', {
            . "$PSScriptRoot/MonthViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object MonthViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Agenda View", 'A', {
            . "$PSScriptRoot/AgendaViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object AgendaViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Burndown Chart", 'C', {
            . "$PSScriptRoot/BurndownChartScreen.ps1"
            $global:PmcApp.PushScreen((New-Object BurndownChartScreen))
        }))

        # Projects menu
        $projectsMenu = $this.MenuBar.Menus[1]
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project List", 'L', {
            . "$PSScriptRoot/ProjectListScreen.ps1"
            $global:PmcApp.PushScreen((New-Object ProjectListScreen))
        }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Stats", 'S', {
            . "$PSScriptRoot/ProjectStatsScreen.ps1"
            $global:PmcApp.PushScreen((New-Object ProjectStatsScreen))
        }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Info", 'I', {
            . "$PSScriptRoot/ProjectInfoScreen.ps1"
            $global:PmcApp.PushScreen((New-Object ProjectInfoScreen))
        }))

        # Options menu
        $optionsMenu = $this.MenuBar.Menus[2]
        $optionsMenu.Items.Add([PmcMenuItem]::new("Theme Editor", 'T', {
            . "$PSScriptRoot/ThemeEditorScreen.ps1"
            $global:PmcApp.PushScreen((New-Object ThemeEditorScreen))
        }))
        $optionsMenu.Items.Add([PmcMenuItem]::new("Settings", 'S', {
            . "$PSScriptRoot/SettingsScreen.ps1"
            $global:PmcApp.PushScreen((New-Object SettingsScreen))
        }))

        # Help menu
        $helpMenu = $this.MenuBar.Menus[3]
        $helpMenu.Items.Add([PmcMenuItem]::new("Help View", 'H', {
            . "$PSScriptRoot/HelpViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object HelpViewScreen))
        }))
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

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
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
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PopScreen()
            $global:PmcApp.PushScreen((New-Object TaskListScreen))
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
