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
    [string]$InputBuffer = ""
    [string]$InputMode = ""  # "", "edit-field"
    [string]$EditField = ""  # Which field being edited (due, priority, text)
    [array]$EditableFields = @('priority', 'due', 'text')
    [int]$EditFieldIndex = 0

    # Constructor
    TodayViewScreen() : base("TodayView", "Today's Tasks") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks", "Today"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("E", "Edit")
        $this.Footer.AddShortcut("Tab", "Next Field")
        $this.Footer.AddShortcut("C", "Complete")
        $this.Footer.AddShortcut("Esc", "Cancel")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")

        # Setup menu items
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

        # Render inline edit overlays if in edit mode
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

        $currentY = $startY
        for ($i = 0; $i -lt [Math]::Min($this.TodayTasks.Count, $maxLines); $i++) {
            $task = $this.TodayTasks[$i]
            $y = $currentY
            $isSelected = ($i -eq $this.SelectedIndex)
            $isEditing = ($i -eq $this.SelectedIndex) -and ($this.InputMode -eq 'edit-field')

            # Cursor
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
            if ($isSelected -or $isEditing) {
                $sb.Append($cursorColor)
                $cursorChar = if ($isEditing) { "E" } else { ">" }
                $sb.Append($cursorChar)
                $sb.Append($reset)
            } else {
                $sb.Append(" ")
            }

            # Task row with columns
            $x = $contentRect.X + 4

            # Priority column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isEditing -and $this.EditField -eq 'priority') {
                # Inline edit for priority
                $sb.Append($cursorColor)
                $sb.Append(($this.InputBuffer + "_").PadRight($priorityWidth))
                $sb.Append($reset)
            } elseif ($task.priority -gt 0) {
                $sb.Append($priorityColor)
                $sb.Append("P$($task.priority)".PadRight($priorityWidth))
                $sb.Append($reset)
            } else {
                $sb.Append(" " * $priorityWidth)
            }
            $x += $priorityWidth

            # Status column (skip for now - not editable in this simplified version)
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
            if ($isEditing -and $this.EditField -eq 'text') {
                # Inline edit for text
                $sb.Append($cursorColor)
                $text = $this.InputBuffer + "_"
                if ($text.Length -gt $textWidth) {
                    $text = $text.Substring(0, $textWidth)
                }
                $sb.Append($text)
                $sb.Append($reset)
            } else {
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

            $currentY++

            # Render subtasks if present
            if ($task.subtasks -and $task.subtasks.Count -gt 0) {
                foreach ($subtask in $task.subtasks) {
                    if ($currentY -ge ($startY + $maxLines)) { break }

                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  └─ ")
                    $sb.Append($subtask)
                    $sb.Append($reset)
                    $currentY++
                }
            }

            # Render tags if present
            if ($task.tags -and $task.tags.Count -gt 0) {
                if ($currentY -lt ($startY + $maxLines)) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Tags: ")
                    $sb.Append(($task.tags -join ', '))
                    $sb.Append($reset)
                    $currentY++
                }
            }

            # Render dependencies if present
            if ($task.depends -and $task.depends.Count -gt 0) {
                if ($currentY -lt ($startY + $maxLines)) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Deps: ")
                    $sb.Append(($task.depends -join ', '))
                    $sb.Append($reset)
                    $currentY++
                }
            }

            # Render notes if present (first line only)
            if ($task.notes -and $task.notes.Count -gt 0) {
                if ($currentY -lt ($startY + $maxLines)) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Note: ")
                    $noteText = $task.notes[0]
                    if ($noteText.Length -gt ($textWidth - 10)) {
                        $noteText = $noteText.Substring(0, $textWidth - 13) + "..."
                    }
                    $sb.Append($noteText)
                    $sb.Append($reset)
                    $currentY++
                }
            }
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

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Input mode handling
        if ($this.InputMode) {
            return $this._HandleInputMode($keyInfo)
        }

        # Normal mode handling
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
            'E' {
                $this._StartEditField()
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

    hidden [bool] _HandleInputMode([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'Enter' {
                $this._SubmitInput()
                return $true
            }
            'Escape' {
                $this._CancelInput()
                return $true
            }
            'Tab' {
                if ($this.InputMode -eq 'edit-field') {
                    $this._CycleField()
                    return $true
                }
            }
            'Backspace' {
                if ($this.InputBuffer.Length -gt 0) {
                    $this.InputBuffer = $this.InputBuffer.Substring(0, $this.InputBuffer.Length - 1)
                    return $true
                }
            }
            default {
                # Add character to buffer
                if ($keyInfo.KeyChar -and -not [char]::IsControl($keyInfo.KeyChar)) {
                    $this.InputBuffer += $keyInfo.KeyChar
                    return $true
                }
            }
        }
        return $false
    }

    hidden [void] _StartEditField() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.TodayTasks.Count) {
            return
        }

        $task = $this.TodayTasks[$this.SelectedIndex]
        $this.InputMode = "edit-field"
        $this.EditFieldIndex = 0
        $this.EditField = $this.EditableFields[$this.EditFieldIndex]

        # Pre-fill with current value
        $currentValue = $task.($this.EditField)
        if ($currentValue) {
            $this.InputBuffer = [string]$currentValue
        } else {
            $this.InputBuffer = ""
        }

        $this.ShowStatus("Editing task #$($task.id) - Press Tab to cycle fields")
    }

    hidden [void] _SubmitInput() {
        try {
            if ($this.InputMode -eq 'edit-field') {
                # Update current field value
                $this._UpdateField($this.EditField, $this.InputBuffer)
                # Exit edit mode
                $this.InputMode = ""
                $this.InputBuffer = ""
                $this.EditField = ""
                $this.EditFieldIndex = 0
            }
        } catch {
            $this.ShowError("Operation failed: $_")
            $this.InputMode = ""
            $this.InputBuffer = ""
            $this.EditField = ""
            $this.EditFieldIndex = 0
        }
    }

    hidden [void] _CancelInput() {
        $this.InputMode = ""
        $this.InputBuffer = ""
        $this.EditField = ""
        $this.EditFieldIndex = 0
        $this.ShowStatus("Cancelled")
    }

    hidden [void] _CycleField() {
        if ($this.InputMode -eq 'edit-field') {
            if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.TodayTasks.Count) {
                return
            }

            $task = $this.TodayTasks[$this.SelectedIndex]

            # Save current field value before switching
            try {
                if ($this.InputBuffer) {
                    $this._UpdateField($this.EditField, $this.InputBuffer)
                }
            } catch {
                # If update fails, show error but continue to next field
                $this.ShowError("Invalid value for $($this.EditField): $_")
            }

            # Move to next field
            $this.EditFieldIndex = ($this.EditFieldIndex + 1) % $this.EditableFields.Count
            $this.EditField = $this.EditableFields[$this.EditFieldIndex]

            # Load new field value
            $currentValue = $task.($this.EditField)
            if ($currentValue) {
                $this.InputBuffer = [string]$currentValue
            } else {
                $this.InputBuffer = ""
            }

            $this.ShowStatus("Now editing: $($this.EditField) - Press Tab for next field, Enter to finish")
        }
    }

    hidden [void] _UpdateField([string]$field, [string]$value) {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.TodayTasks.Count) {
            return
        }

        $task = $this.TodayTasks[$this.SelectedIndex]

        try {
            # Use existing FieldSchema to normalize and validate
            $schema = Get-PmcFieldSchema -Domain 'task' -Field $field

            if (-not $schema) {
                $this.ShowError("Unknown field: $field")
                return
            }

            # Normalize the value using existing schema logic
            $normalizedValue = $value
            if ($schema.Normalize) {
                $normalizedValue = & $schema.Normalize $value
            }

            # Validate using existing schema logic
            if ($schema.Validate) {
                $isValid = & $schema.Validate $normalizedValue
                if (-not $isValid) {
                    $this.ShowError("Invalid value for $field")
                    return
                }
            }

            # Update in-memory task
            $task.$field = $normalizedValue

            # Update storage
            $allData = Get-PmcAllData
            $taskToUpdate = $allData.tasks | Where-Object { $_.id -eq $task.id }

            if ($taskToUpdate) {
                $taskToUpdate.$field = $normalizedValue
                Set-PmcAllData $allData
            }

            # Show formatted value in success message
            $displayValue = $normalizedValue
            if ($schema.DisplayFormat) {
                $displayValue = & $schema.DisplayFormat $normalizedValue
            }

            $this.ShowSuccess("Task #$($task.id) $field = $displayValue")

        } catch {
            $this.ShowError("Error updating $field`: $_")
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
