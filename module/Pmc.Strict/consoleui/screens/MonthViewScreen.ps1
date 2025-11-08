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
    [string]$InputBuffer = ""
    [string]$InputMode = ""  # "", "edit-field"
    [string]$EditField = ""  # Which field being edited (due, priority, text)
    [array]$EditableFields = @('priority', 'due', 'text')
    [int]$EditFieldIndex = 0

    # Constructor
    MonthViewScreen() : base("MonthView", "This Month's Tasks") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Views", "Month"))

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
                $isEditing = ($taskIndex -eq $this.SelectedIndex) -and ($this.InputMode -eq 'edit-field')

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

                # Task text with inline editing
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))

                if ($isEditing) {
                    # Show inline edit format: [ID] Field: Value_
                    $editDisplay = "[$($task.id)] $($this.EditField): $($this.InputBuffer)_"
                    $sb.Append($cursorColor)
                    $maxWidth = $contentRect.Width - 6
                    if ($editDisplay.Length -gt $maxWidth) {
                        $editDisplay = $editDisplay.Substring(0, $maxWidth)
                    }
                    $sb.Append($editDisplay)
                    $sb.Append($reset)
                } else {
                    $dueDate = [DateTime]$task.due
                    $daysOverdue = ((Get-Date).Date - $dueDate.Date).Days
                    $taskText = "[$($task.id)] $($dueDate.ToString('MMM dd')) ($daysOverdue days ago) - $($task.text)"

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
                }

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
                $isEditing = ($taskIndex -eq $this.SelectedIndex) -and ($this.InputMode -eq 'edit-field')

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

                # Task text with inline editing
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))

                if ($isEditing) {
                    # Show inline edit format: [ID] Field: Value_
                    $editDisplay = "[$($task.id)] $($this.EditField): $($this.InputBuffer)_"
                    $sb.Append($cursorColor)
                    $maxWidth = $contentRect.Width - 6
                    if ($editDisplay.Length -gt $maxWidth) {
                        $editDisplay = $editDisplay.Substring(0, $maxWidth)
                    }
                    $sb.Append($editDisplay)
                    $sb.Append($reset)
                } else {
                    $dueDate = [DateTime]$task.due
                    $taskText = "[$($task.id)] $($dueDate.ToString('MMM dd')) - $($task.text)"

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
                }

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
                $isEditing = ($taskIndex -eq $this.SelectedIndex) -and ($this.InputMode -eq 'edit-field')

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

                # Task text with inline editing
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))

                if ($isEditing) {
                    # Show inline edit format: [ID] Field: Value_
                    $editDisplay = "[$($task.id)] $($this.EditField): $($this.InputBuffer)_"
                    $sb.Append($cursorColor)
                    $maxWidth = $contentRect.Width - 6
                    if ($editDisplay.Length -gt $maxWidth) {
                        $editDisplay = $editDisplay.Substring(0, $maxWidth)
                    }
                    $sb.Append($editDisplay)
                    $sb.Append($reset)
                } else {
                    $taskText = "[$($task.id)] $($task.text)"

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
                }

                $y++
                $taskIndex++
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

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Input mode handling
        if ($this.InputMode) {
            return $this._HandleInputMode($keyInfo)
        }

        # Normal mode handling
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
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.SelectableTasks.Count) {
            return
        }

        $task = $this.SelectableTasks[$this.SelectedIndex]
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
            if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.SelectableTasks.Count) {
                return
            }

            $task = $this.SelectableTasks[$this.SelectedIndex]

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
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.SelectableTasks.Count) {
            return
        }

        $task = $this.SelectableTasks[$this.SelectedIndex]

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
