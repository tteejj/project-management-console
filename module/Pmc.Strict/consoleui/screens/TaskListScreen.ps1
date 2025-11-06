using namespace System.Collections.Generic
using namespace System.Text

# TaskListScreen - Main task list with CRUD operations
# Shows all active tasks with ability to add, edit, delete, complete

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Main task list screen with full CRUD operations

.DESCRIPTION
Shows all active (non-completed) tasks.
Supports:
- Adding new tasks (A key)
- Editing tasks (E key)
- Completing tasks (C key)
- Deleting tasks (D key)
- Navigation (Up/Down arrows)
- Filtering (F key)
#>
class TaskListScreen : PmcScreen {
    # Data
    [array]$Tasks = @()
    [int]$SelectedIndex = 0
    [string]$FilterProject = ""
    [string]$InputBuffer = ""
    [string]$InputMode = ""  # "", "add-multi", "edit-field", "delete"
    [string]$EditField = ""  # Which field being edited (due, priority, text)
    [array]$EditableFields = @('priority', 'due', 'text')  # Fields that can be edited with Tab - matches column order
    [int]$EditFieldIndex = 0  # Current field index when tabbing
    [hashtable]$NewTaskData = @{}  # Temporary storage for new task being added

    # Constructor
    TaskListScreen() : base("TaskList", "Task List") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("A", "Add")
        $this.Footer.AddShortcut("E", "Edit")
        $this.Footer.AddShortcut("Tab", "Next Field")
        $this.Footer.AddShortcut("C", "Complete")
        $this.Footer.AddShortcut("D", "Delete")
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
        $tasksMenu.Items.Add([PmcMenuItem]::new("Task List", 'L', { $screen.LoadData() }.GetNewClosure()))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Today", 'Y', {
            . "$PSScriptRoot/TodayViewScreen.ps1"
            $global:PmcApp.PushScreen([TodayViewScreen]::new())
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Tomorrow", 'T', {
            . "$PSScriptRoot/TomorrowViewScreen.ps1"
            $global:PmcApp.PushScreen([TomorrowViewScreen]::new())
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Week View", 'W', {
            . "$PSScriptRoot/WeekViewScreen.ps1"
            $global:PmcApp.PushScreen([WeekViewScreen]::new())
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Upcoming", 'U', {
            . "$PSScriptRoot/UpcomingViewScreen.ps1"
            $global:PmcApp.PushScreen([UpcomingViewScreen]::new())
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Overdue", 'V', {
            . "$PSScriptRoot/OverdueViewScreen.ps1"
            $global:PmcApp.PushScreen([OverdueViewScreen]::new())
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Next Actions", 'N', {
            . "$PSScriptRoot/NextActionsViewScreen.ps1"
            $global:PmcApp.PushScreen([NextActionsViewScreen]::new())
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("No Due Date", 'D', {
            . "$PSScriptRoot/NoDueDateViewScreen.ps1"
            $global:PmcApp.PushScreen([NoDueDateViewScreen]::new())
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Blocked Tasks", 'B', {
            . "$PSScriptRoot/BlockedTasksScreen.ps1"
            $global:PmcApp.PushScreen([BlockedTasksScreen]::new())
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::Separator())
        $tasksMenu.Items.Add([PmcMenuItem]::new("Kanban Board", 'K', {
            . "$PSScriptRoot/KanbanScreen.ps1"
            $global:PmcApp.PushScreen([KanbanScreen]::new())
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', {
            . "$PSScriptRoot/MonthViewScreen.ps1"
            $global:PmcApp.PushScreen([MonthViewScreen]::new())
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Agenda View", 'A', {
            . "$PSScriptRoot/AgendaViewScreen.ps1"
            $global:PmcApp.PushScreen([AgendaViewScreen]::new())
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Burndown Chart", 'C', {
            . "$PSScriptRoot/BurndownChartScreen.ps1"
            $global:PmcApp.PushScreen([BurndownChartScreen]::new())
        }))

        # Projects menu
        $projectsMenu = $this.MenuBar.Menus[1]
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project List", 'L', {
            . "$PSScriptRoot/ProjectListScreen.ps1"
            $global:PmcApp.PushScreen([ProjectListScreen]::new())
        }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Stats", 'S', {
            . "$PSScriptRoot/ProjectStatsScreen.ps1"
            $global:PmcApp.PushScreen([ProjectStatsScreen]::new())
        }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Info", 'I', {
            . "$PSScriptRoot/ProjectInfoScreen.ps1"
            $global:PmcApp.PushScreen([ProjectInfoScreen]::new())
        }))

        # Options menu
        $optionsMenu = $this.MenuBar.Menus[2]
        $optionsMenu.Items.Add([PmcMenuItem]::new("Theme Editor", 'T', {
            . "$PSScriptRoot/ThemeEditorScreen.ps1"
            $global:PmcApp.PushScreen([ThemeEditorScreen]::new())
        }))
        $optionsMenu.Items.Add([PmcMenuItem]::new("Settings", 'S', { Write-Host "Settings not yet implemented" }))

        # Help menu
        $helpMenu = $this.MenuBar.Menus[3]
        $helpMenu.Items.Add([PmcMenuItem]::new("Help View", 'H', {
            . "$PSScriptRoot/HelpViewScreen.ps1"
            $global:PmcApp.PushScreen([HelpViewScreen]::new())
        }))
        $helpMenu.Items.Add([PmcMenuItem]::new("About", 'A', { Write-Host "PMC TUI v1.0" }))
    }

    [void] LoadData() {
        $this.ShowStatus("Loading tasks...")

        try {
            # Get PMC data (module must be imported already)
            $data = Get-PmcAllData

            # Filter active tasks
            $this.Tasks = @($data.tasks | Where-Object {
                -not $_.completed
            })

            # Apply project filter if set
            if ($this.FilterProject) {
                $this.Tasks = @($this.Tasks | Where-Object {
                    $_.project -eq $this.FilterProject
                })
            }

            # Sort by priority (descending), then id
            $this.Tasks = @($this.Tasks | Sort-Object -Property @{Expression={$_.priority}; Descending=$true}, id)

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.Tasks.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.Tasks.Count - 1)
            }

            # Update status
            if ($this.Tasks.Count -eq 0) {
                $this.ShowSuccess("No active tasks")
            } else {
                $this.ShowStatus("$($this.Tasks.Count) active tasks")
            }

        } catch {
            $this.ShowError("Failed to load tasks: $_")
            $this.Tasks = @()
        }
    }

    [string] RenderContent() {
        # Delete mode uses popup dialog
        if ($this.InputMode -eq 'delete') {
            return $this._RenderInputMode()
        }

        # Always show task list with column headers - inline add/edit
        return $this._RenderTaskList()
    }

    hidden [string] _RenderEmptyState() {
        $sb = [System.Text.StringBuilder]::new(512)

        # Get content area
        if ($this.LayoutManager) {
            $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

            # Center message
            $message = "No active tasks - Press A to add one"
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
        $cursorColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $priorityColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        # Column widths
        $priorityWidth = 4   # "P2  "
        $dueWidth = 8        # "11/15   "
        $textWidth = $contentRect.Width - $priorityWidth - $dueWidth - 10  # remaining for text

        # Render column headers at line 4 (ABOVE separator which is at line 5)
        # Header.Y=1, breadcrumb at Y+2=3, headers at Y+3=4, separator at Y+4=5
        $headerY = $this.Header.Y + 3  # Y=1 + 3 = 4 (1-based ANSI line 4)
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($headerColor)
        $sb.Append("PRI ")
        $sb.Append("DUE      ")
        $sb.Append("TASK")
        $sb.Append($reset)

        # Render inline add row if in add mode (starts after separator at line 5, so line 6)
        $startY = $headerY + 2
        if ($this.InputMode -eq 'add-multi') {
            $sb.Append($this._RenderInlineAddRow($startY, $contentRect, $priorityWidth, $dueWidth, $textWidth))
            $startY++
        }

        # Render task rows (including inline edit)
        $maxLines = $contentRect.Height - 4
        for ($i = 0; $i -lt [Math]::Min($this.Tasks.Count, $maxLines); $i++) {
            $task = $this.Tasks[$i]
            $y = $startY + $i
            $isSelected = ($i -eq $this.SelectedIndex) -and ($this.InputMode -ne 'add-multi')
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

            # Due column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isEditing -and $this.EditField -eq 'due') {
                # Inline edit for due
                $sb.Append($cursorColor)
                $sb.Append(($this.InputBuffer + "_").PadRight($dueWidth))
                $sb.Append($reset)
            } elseif ($task.due) {
                $schema = Get-PmcFieldSchema -Domain 'task' -Field 'due'
                $dueDisplay = & $schema.DisplayFormat $task.due
                $sb.Append($mutedColor)
                $sb.Append($dueDisplay.PadRight($dueWidth))
                $sb.Append($reset)
            } else {
                $sb.Append(" " * $dueWidth)
            }
            $x += $dueWidth

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
        }

        return $sb.ToString()
    }

    hidden [string] _RenderInlineAddRow([int]$y, [object]$contentRect, [int]$priorityWidth, [int]$dueWidth, [int]$textWidth) {
        $sb = [System.Text.StringBuilder]::new(512)

        $cursorColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $inputColor = $this.Header.GetThemedAnsi('Text', $false)
        $reset = "`e[0m"

        # Add row cursor
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
        $sb.Append($cursorColor)
        $sb.Append("+")
        $sb.Append($reset)

        $x = $contentRect.X + 4

        # Priority column
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        if ($this.EditField -eq 'priority') {
            $sb.Append($cursorColor)
            $sb.Append(($this.InputBuffer + "_").PadRight($priorityWidth))
            $sb.Append($reset)
        } else {
            $value = if ($this.NewTaskData.ContainsKey('priority')) { "P" + $this.NewTaskData['priority'] } else { "" }
            $sb.Append($inputColor)
            $sb.Append($value.PadRight($priorityWidth))
            $sb.Append($reset)
        }
        $x += $priorityWidth

        # Due column
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        if ($this.EditField -eq 'due') {
            $sb.Append($cursorColor)
            $sb.Append(($this.InputBuffer + "_").PadRight($dueWidth))
            $sb.Append($reset)
        } else {
            $value = if ($this.NewTaskData.ContainsKey('due')) { $this.NewTaskData['due'] } else { "" }
            $sb.Append($inputColor)
            $sb.Append($value.PadRight($dueWidth))
            $sb.Append($reset)
        }
        $x += $dueWidth

        # Text column
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        if ($this.EditField -eq 'text') {
            $sb.Append($cursorColor)
            $text = $this.InputBuffer + "_"
            if ($text.Length -gt $textWidth) {
                $text = $text.Substring(0, $textWidth)
            }
            $sb.Append($text)
            $sb.Append($reset)
        } else {
            $value = if ($this.NewTaskData.ContainsKey('text')) { $this.NewTaskData['text'] } else { "" }
            if ($value.Length -gt $textWidth) {
                $value = $value.Substring(0, $textWidth - 3) + "..."
            }
            $sb.Append($inputColor)
            $sb.Append($value)
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    hidden [string] _RenderInputMode() {
        $sb = [System.Text.StringBuilder]::new(1024)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $highlightColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        $promptY = $contentRect.Y + [Math]::Floor($contentRect.Height / 2)
        $inputY = $promptY + 2

        # Show prompt based on mode
        $prompt = ""
        $hint = ""

        switch ($this.InputMode) {
            "add-multi" {
                # Show which field we're adding
                $schema = Get-PmcFieldSchema -Domain 'task' -Field $this.EditField
                $fieldName = $this.EditField.Substring(0,1).ToUpper() + $this.EditField.Substring(1)
                $prompt = "New Task - ${fieldName}: (Tab for next field)"
                if ($schema -and $schema.Hint) {
                    $hint = $schema.Hint
                }
            }
            "edit-field" {
                # Use existing FieldSchema for hints
                $schema = Get-PmcFieldSchema -Domain 'task' -Field $this.EditField
                $fieldName = $this.EditField.Substring(0,1).ToUpper() + $this.EditField.Substring(1)
                $prompt = "Edit ${fieldName}: (Tab for next field)"
                if ($schema -and $schema.Hint) {
                    $hint = $schema.Hint
                }
            }
            "delete" {
                $prompt = "Type 'yes' to confirm delete:"
            }
            default {
                $prompt = "Input:"
            }
        }

        $promptX = $contentRect.X + 4
        $sb.Append($this.Header.BuildMoveTo($promptX, $promptY))
        $sb.Append($highlightColor)
        $sb.Append($prompt)
        $sb.Append($reset)

        # Show hint if available
        if ($hint) {
            $hintY = $promptY + 1
            $sb.Append($this.Header.BuildMoveTo($promptX, $hintY))
            $sb.Append($mutedColor)
            $sb.Append("($hint)")
            $sb.Append($reset)
        }

        # Show input
        $sb.Append($this.Header.BuildMoveTo($promptX, $inputY))
        $sb.Append($textColor)
        $sb.Append($this.InputBuffer)
        $sb.Append("_")
        $sb.Append($reset)

        # Show instructions
        $instructY = $inputY + 2
        $sb.Append($this.Header.BuildMoveTo($promptX, $instructY))
        $sb.Append($mutedColor)
        $sb.Append("Enter to submit, Esc to cancel")
        $sb.Append($reset)

        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        # Input mode handling
        if ($this.InputMode) {
            return $this._HandleInputMode($keyInfo)
        }

        # Normal mode handling
        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.Tasks.Count - 1)) {
                    $this.SelectedIndex++
                    return $true
                }
            }
            'A' {
                $this._StartAddTask()
                return $true
            }
            'E' {
                $this._StartEditField()
                return $true
            }
            'C' {
                $this._CompleteTask()
                return $true
            }
            'D' {
                $this._StartDeleteTask()
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
                if ($this.InputMode -eq 'edit-field' -or $this.InputMode -eq 'add-multi') {
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

    hidden [void] _StartAddTask() {
        $this.InputMode = "add-multi"
        $this.EditFieldIndex = 0
        $this.EditField = $this.EditableFields[$this.EditFieldIndex]
        $this.InputBuffer = ""
        $this.NewTaskData = @{}
        $this.ShowStatus("Adding new task - Press Tab to cycle fields, Enter to save")
    }

    hidden [void] _StartDeleteTask() {
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.Tasks.Count) {
            $task = $this.Tasks[$this.SelectedIndex]
            $this.InputMode = "delete"
            $this.InputBuffer = ""
            $this.ShowStatus("Confirm delete task #$($task.id)")
        }
    }

    hidden [void] _SubmitInput() {
        try {
            switch ($this.InputMode) {
                "add-multi" {
                    # Save current field
                    if ($this.InputBuffer) {
                        $this.NewTaskData[$this.EditField] = $this.InputBuffer
                    }
                    # Create task with all collected data
                    $this._CreateTaskFromData()
                    # Clear and exit
                    $this.InputMode = ""
                    $this.InputBuffer = ""
                    $this.EditField = ""
                    $this.EditFieldIndex = 0
                    $this.NewTaskData = @{}
                }
                "edit-field" {
                    # Update current field value
                    $this._UpdateField($this.EditField, $this.InputBuffer)
                    # Exit edit mode
                    $this.InputMode = ""
                    $this.InputBuffer = ""
                    $this.EditField = ""
                    $this.EditFieldIndex = 0
                }
                "delete" {
                    if ($this.InputBuffer.ToLower() -eq "yes") {
                        $this._DeleteTask()
                    } else {
                        $this.ShowStatus("Delete cancelled")
                    }
                    # Clear and exit
                    $this.InputMode = ""
                    $this.InputBuffer = ""
                }
            }
        } catch {
            $this.ShowError("Operation failed: $_")
            $this.InputMode = ""
            $this.InputBuffer = ""
            $this.EditField = ""
            $this.EditFieldIndex = 0
            $this.NewTaskData = @{}
        }
    }

    hidden [void] _CancelInput() {
        $this.InputMode = ""
        $this.InputBuffer = ""
        $this.EditField = ""
        $this.EditFieldIndex = 0
        $this.ShowStatus("Cancelled")
    }

    hidden [void] _StartEditField() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Tasks.Count) {
            return
        }

        $task = $this.Tasks[$this.SelectedIndex]
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

    hidden [void] _CycleField() {
        if ($this.InputMode -eq 'edit-field') {
            # Editing existing task
            if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Tasks.Count) {
                return
            }

            $task = $this.Tasks[$this.SelectedIndex]

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

        } elseif ($this.InputMode -eq 'add-multi') {
            # Adding new task
            # Save current field value
            if ($this.InputBuffer) {
                $this.NewTaskData[$this.EditField] = $this.InputBuffer
            }

            # Move to next field
            $this.EditFieldIndex = ($this.EditFieldIndex + 1) % $this.EditableFields.Count
            $this.EditField = $this.EditableFields[$this.EditFieldIndex]

            # Load existing value if any
            if ($this.NewTaskData.ContainsKey($this.EditField)) {
                $this.InputBuffer = $this.NewTaskData[$this.EditField]
            } else {
                $this.InputBuffer = ""
            }

            $this.ShowStatus("New task field: $($this.EditField) - Press Tab for next field, Enter to save")
        }
    }

    hidden [void] _CreateTaskFromData() {
        # Get text field (required)
        $text = $this.NewTaskData['text']
        if (-not $text) {
            $this.ShowError("Task description cannot be empty")
            return
        }

        $allData = Get-PmcAllData

        # Create new task with defaults
        $newTask = @{
            id = $this._GetNextTaskId($allData)
            text = $text
            project = $allData.currentContext
            priority = 0
            completed = $false
            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            status = 'pending'
            tags = @()
            depends = @()
            notes = @()
            subtasks = @()
            recur = $null
            estimatedMinutes = $null
            due = $null
        }

        # Apply due date if provided, using FieldSchema normalization
        if ($this.NewTaskData.ContainsKey('due') -and $this.NewTaskData['due']) {
            try {
                $schema = Get-PmcFieldSchema -Domain 'task' -Field 'due'
                $normalized = & $schema.Normalize $this.NewTaskData['due']
                $newTask.due = $normalized
            } catch {
                $this.ShowError("Invalid due date: $_")
                return
            }
        }

        # Apply priority if provided, using FieldSchema normalization
        if ($this.NewTaskData.ContainsKey('priority') -and $this.NewTaskData['priority']) {
            try {
                $schema = Get-PmcFieldSchema -Domain 'task' -Field 'priority'
                $normalized = & $schema.Normalize $this.NewTaskData['priority']
                $newTask.priority = [int]$normalized
            } catch {
                $this.ShowError("Invalid priority: $_")
                return
            }
        }

        # Add to in-memory array
        $this.Tasks += $newTask

        # Add to storage data
        if (-not $allData.tasks) { $allData.tasks = @() }
        $allData.tasks += $newTask

        # Save data
        Set-PmcAllData $allData

        $this.ShowSuccess("Task added: #$($newTask.id)")
    }

    hidden [void] _UpdateField([string]$field, [string]$value) {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Tasks.Count) {
            return
        }

        $task = $this.Tasks[$this.SelectedIndex]

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
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Tasks.Count) {
            return
        }

        $task = $this.Tasks[$this.SelectedIndex]
        $taskId = $task.id

        # Remove from in-memory array
        $this.Tasks = @($this.Tasks | Where-Object { $_.id -ne $taskId })

        # Adjust selection
        if ($this.SelectedIndex -ge $this.Tasks.Count -and $this.Tasks.Count -gt 0) {
            $this.SelectedIndex = $this.Tasks.Count - 1
        }

        # Load storage functions


        $allData = Get-PmcAllData
        $taskToComplete = $allData.tasks | Where-Object { $_.id -eq $taskId }

        if ($taskToComplete) {
            $taskToComplete.completed = $true
            $taskToComplete.completedDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            Set-PmcAllData $allData
        }

        $this.ShowSuccess("Task #$taskId completed")
    }

    hidden [void] _DeleteTask() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Tasks.Count) {
            return
        }

        $task = $this.Tasks[$this.SelectedIndex]
        $taskId = $task.id

        # Remove from in-memory array
        $this.Tasks = @($this.Tasks | Where-Object { $_.id -ne $taskId })

        # Adjust selection
        if ($this.SelectedIndex -ge $this.Tasks.Count -and $this.Tasks.Count -gt 0) {
            $this.SelectedIndex = $this.Tasks.Count - 1
        }

        # Load storage functions


        $allData = Get-PmcAllData
        $allData.tasks = @($allData.tasks | Where-Object { $_.id -ne $taskId })

        Set-PmcAllData $allData
        $this.ShowSuccess("Task #$taskId deleted")
    }

    hidden [int] _GetNextTaskId([object]$allData) {
        if (-not $allData.tasks -or $allData.tasks.Count -eq 0) {
            return 1
        }
        $maxId = ($allData.tasks | Measure-Object -Property id -Maximum).Maximum
        return $maxId + 1
    }
}

# Entry point function for compatibility
function Show-TaskListScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [TaskListScreen]::new()
    $App.PushScreen($screen)
}
