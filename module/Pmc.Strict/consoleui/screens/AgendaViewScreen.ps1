using namespace System.Collections.Generic
using namespace System.Text

# AgendaViewScreen - Shows agenda view of tasks by date buckets
# Displays tasks grouped: overdue, today, tomorrow, this week, later, no due date


Set-StrictMode -Version Latest

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
    [string]$InputBuffer = ""
    [string]$InputMode = ""  # "", "edit-field"
    [string]$EditField = ""  # Which field being edited (due, priority, text)
    [array]$EditableFields = @('priority', 'due', 'text')
    [int]$EditFieldIndex = 0

    # Constructor
    AgendaViewScreen() : base("AgendaView", "Agenda View") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Views", "Agenda"))

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
            $currentY = $y
            for ($i = 0; $i -lt $displayCount; $i++) {
                $task = $this.OverdueTasks[$i]
                $isSelected = ($taskIndex -eq $this.SelectedIndex)
                $isEditing = ($taskIndex -eq $this.SelectedIndex) -and ($this.InputMode -eq 'edit-field')
                $dueDate = [DateTime]$task.due
                $daysOverdue = ($todayDate - $dueDate.Date).Days
                $taskText = "[$($task.id)] $($task.text) (-$daysOverdue days)"

                # Cursor
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $currentY))
                if ($isSelected -or $isEditing) {
                    $sb.Append($cursorColor)
                    $cursorChar = if ($isEditing) { "E" } else { ">" }
                    $sb.Append($cursorChar)
                    $sb.Append($reset)
                } else {
                    $sb.Append(" ")
                }

                # Task text
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
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
                $currentY++

                # Show inline edit buffer if editing this task
                if ($isEditing) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 8, $currentY))
                    $sb.Append($cursorColor)
                    $sb.Append("[$($this.EditField)]: ")
                    $sb.Append($this.InputBuffer)
                    $sb.Append("_")
                    $sb.Append($reset)
                    $currentY++
                }

                # Render subtasks if present
                if ($task.subtasks -and $task.subtasks.Count -gt 0) {
                    foreach ($subtask in $task.subtasks) {
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
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Tags: ")
                    $sb.Append(($task.tags -join ', '))
                    $sb.Append($reset)
                    $currentY++
                }

                # Render dependencies if present
                if ($task.depends -and $task.depends.Count -gt 0) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Deps: ")
                    $sb.Append(($task.depends -join ', '))
                    $sb.Append($reset)
                    $currentY++
                }

                # Render notes if present (first line only)
                if ($task.notes -and $task.notes.Count -gt 0) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Note: ")
                    $noteText = $task.notes[0]
                    $textWidth = $contentRect.Width - 8
                    if ($noteText.Length -gt ($textWidth - 10)) {
                        $noteText = $noteText.Substring(0, $textWidth - 13) + "..."
                    }
                    $sb.Append($noteText)
                    $sb.Append($reset)
                    $currentY++
                }

                $taskIndex++
            }
            $y = $currentY

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
            $currentY = $y
            for ($i = 0; $i -lt $displayCount; $i++) {
                $task = $this.TodayTasks[$i]
                $isSelected = ($taskIndex -eq $this.SelectedIndex)
                $isEditing = ($taskIndex -eq $this.SelectedIndex) -and ($this.InputMode -eq 'edit-field')
                $taskText = "[$($task.id)] $($task.text)"

                # Cursor
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $currentY))
                if ($isSelected -or $isEditing) {
                    $sb.Append($cursorColor)
                    $cursorChar = if ($isEditing) { "E" } else { ">" }
                    $sb.Append($cursorChar)
                    $sb.Append($reset)
                } else {
                    $sb.Append(" ")
                }

                # Task text
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
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
                $currentY++

                # Show inline edit buffer if editing this task
                if ($isEditing) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 8, $currentY))
                    $sb.Append($cursorColor)
                    $sb.Append("[$($this.EditField)]: ")
                    $sb.Append($this.InputBuffer)
                    $sb.Append("_")
                    $sb.Append($reset)
                    $currentY++
                }

                # Render subtasks if present
                if ($task.subtasks -and $task.subtasks.Count -gt 0) {
                    foreach ($subtask in $task.subtasks) {
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
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Tags: ")
                    $sb.Append(($task.tags -join ', '))
                    $sb.Append($reset)
                    $currentY++
                }

                # Render dependencies if present
                if ($task.depends -and $task.depends.Count -gt 0) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Deps: ")
                    $sb.Append(($task.depends -join ', '))
                    $sb.Append($reset)
                    $currentY++
                }

                # Render notes if present (first line only)
                if ($task.notes -and $task.notes.Count -gt 0) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Note: ")
                    $noteText = $task.notes[0]
                    $textWidth = $contentRect.Width - 8
                    if ($noteText.Length -gt ($textWidth - 10)) {
                        $noteText = $noteText.Substring(0, $textWidth - 13) + "..."
                    }
                    $sb.Append($noteText)
                    $sb.Append($reset)
                    $currentY++
                }

                $taskIndex++
            }
            $y = $currentY

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
            $currentY = $y
            for ($i = 0; $i -lt $displayCount; $i++) {
                $task = $this.TomorrowTasks[$i]
                $isSelected = ($taskIndex -eq $this.SelectedIndex)
                $isEditing = ($taskIndex -eq $this.SelectedIndex) -and ($this.InputMode -eq 'edit-field')
                $taskText = "[$($task.id)] $($task.text)"

                # Cursor
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $currentY))
                if ($isSelected -or $isEditing) {
                    $sb.Append($cursorColor)
                    $cursorChar = if ($isEditing) { "E" } else { ">" }
                    $sb.Append($cursorChar)
                    $sb.Append($reset)
                } else {
                    $sb.Append(" ")
                }

                # Task text
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
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
                $currentY++

                # Show inline edit buffer if editing this task
                if ($isEditing) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 8, $currentY))
                    $sb.Append($cursorColor)
                    $sb.Append("[$($this.EditField)]: ")
                    $sb.Append($this.InputBuffer)
                    $sb.Append("_")
                    $sb.Append($reset)
                    $currentY++
                }

                # Render subtasks if present
                if ($task.subtasks -and $task.subtasks.Count -gt 0) {
                    foreach ($subtask in $task.subtasks) {
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
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Tags: ")
                    $sb.Append(($task.tags -join ', '))
                    $sb.Append($reset)
                    $currentY++
                }

                # Render dependencies if present
                if ($task.depends -and $task.depends.Count -gt 0) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Deps: ")
                    $sb.Append(($task.depends -join ', '))
                    $sb.Append($reset)
                    $currentY++
                }

                # Render notes if present (first line only)
                if ($task.notes -and $task.notes.Count -gt 0) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Note: ")
                    $noteText = $task.notes[0]
                    $textWidth = $contentRect.Width - 8
                    if ($noteText.Length -gt ($textWidth - 10)) {
                        $noteText = $noteText.Substring(0, $textWidth - 13) + "..."
                    }
                    $sb.Append($noteText)
                    $sb.Append($reset)
                    $currentY++
                }

                $taskIndex++
            }
            $y = $currentY

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
            $currentY = $y
            for ($i = 0; $i -lt $displayCount; $i++) {
                $task = $this.ThisWeekTasks[$i]
                $isSelected = ($taskIndex -eq $this.SelectedIndex)
                $isEditing = ($taskIndex -eq $this.SelectedIndex) -and ($this.InputMode -eq 'edit-field')
                $dueDate = [DateTime]$task.due
                $taskText = "[$($task.id)] $($task.text) ($($dueDate.ToString('ddd MMM dd')))"

                # Cursor
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $currentY))
                if ($isSelected -or $isEditing) {
                    $sb.Append($cursorColor)
                    $cursorChar = if ($isEditing) { "E" } else { ">" }
                    $sb.Append($cursorChar)
                    $sb.Append($reset)
                } else {
                    $sb.Append(" ")
                }

                # Task text
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
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
                $currentY++

                # Show inline edit buffer if editing this task
                if ($isEditing) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 8, $currentY))
                    $sb.Append($cursorColor)
                    $sb.Append("[$($this.EditField)]: ")
                    $sb.Append($this.InputBuffer)
                    $sb.Append("_")
                    $sb.Append($reset)
                    $currentY++
                }

                # Render subtasks if present
                if ($task.subtasks -and $task.subtasks.Count -gt 0) {
                    foreach ($subtask in $task.subtasks) {
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
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Tags: ")
                    $sb.Append(($task.tags -join ', '))
                    $sb.Append($reset)
                    $currentY++
                }

                # Render dependencies if present
                if ($task.depends -and $task.depends.Count -gt 0) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Deps: ")
                    $sb.Append(($task.depends -join ', '))
                    $sb.Append($reset)
                    $currentY++
                }

                # Render notes if present (first line only)
                if ($task.notes -and $task.notes.Count -gt 0) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Note: ")
                    $noteText = $task.notes[0]
                    $textWidth = $contentRect.Width - 8
                    if ($noteText.Length -gt ($textWidth - 10)) {
                        $noteText = $noteText.Substring(0, $textWidth - 13) + "..."
                    }
                    $sb.Append($noteText)
                    $sb.Append($reset)
                    $currentY++
                }

                $taskIndex++
            }
            $y = $currentY

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
