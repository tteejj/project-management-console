using namespace System.Collections.Generic
using namespace System.Text

# BlockedTasksScreen - Migrated from DrawBlockedView in ConsoleUI.Core.ps1
# Shows blocked and waiting tasks in new widget architecture

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Screen showing blocked/waiting tasks

.DESCRIPTION
Migrated from DrawBlockedView() method.
Shows list of tasks with status 'blocked' or 'waiting'.
#>
class BlockedTasksScreen : PmcScreen {
    # Data
    [array]$BlockedTasks = @()
    [int]$SelectedIndex = 0

    # Content panel
    [PmcPanel]$ContentPanel

    # Constructor
    BlockedTasksScreen() : base("BlockedTasks", "Blocked/Waiting Tasks") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks", "Blocked"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("↑↓", "Select")
        $this.Footer.AddShortcut("Enter", "Detail")
        $this.Footer.AddShortcut("E", "Edit")
        $this.Footer.AddShortcut("D", "Toggle")
        $this.Footer.AddShortcut("F10", "Menu")
        $this.Footer.AddShortcut("Esc", "Back")

        # Don't create panel here - will be created in LoadData after we know content size

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
            $global:PmcApp.PushScreen([TaskListScreen]::new())
        }))
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
        $tasksMenu.Items.Add([PmcMenuItem]::new("Blocked Tasks", 'B', { $screen.LoadData() }.GetNewClosure()))
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
        $this.ShowStatus("Loading blocked tasks...")

        try {
            # Load PMC data
            $data = Get-PmcAllData

            # Filter blocked/waiting tasks
            $this.BlockedTasks = @($data.tasks | Where-Object {
                $_.status -eq 'blocked' -or $_.status -eq 'waiting'
            })

            # Reset selection
            $this.SelectedIndex = 0

            # Update status
            if ($this.BlockedTasks.Count -eq 0) {
                $this.ShowSuccess("No blocked tasks")
            } else {
                $this.ShowStatus("$($this.BlockedTasks.Count) blocked/waiting tasks")
            }

        } catch {
            $this.ShowError("Failed to load blocked tasks: $_")
            $this.BlockedTasks = @()
        }
    }

    [string] RenderContent() {
        if ($this.BlockedTasks.Count -eq 0) {
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
            $message = "No blocked tasks"
            $x = $contentRect.X + [Math]::Floor(($contentRect.Width - $message.Length) / 2)
            $y = $contentRect.Y + [Math]::Floor($contentRect.Height / 2)

            $successColor = $this.Header.GetThemedAnsi('Success', $false)
            $reset = "`e[0m"

            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($successColor)
            $sb.Append($message)
            $sb.Append($reset)
        }

        $result = $sb.ToString()
        
        return $result
    }

    hidden [string] _RenderTaskList() {
        $sb = [System.Text.StringBuilder]::new(2048)

        if (-not $this.LayoutManager) {
            $result = $sb.ToString()
            
            return $result
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $blockedColor = $this.Header.GetThemedAnsi('Error', $false)
        $waitingColor = $this.Header.GetThemedAnsi('Warning', $false)
        $selectedBg = $this.Header.GetThemedAnsi('Primary', $true)
        $selectedFg = $this.Header.GetThemedAnsi('Text', $false)
        $cursorColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $reset = "`e[0m"

        # Render task list
        $startY = $contentRect.Y + 1
        $maxLines = $contentRect.Height - 2

        for ($i = 0; $i -lt [Math]::Min($this.BlockedTasks.Count, $maxLines); $i++) {
            $task = $this.BlockedTasks[$i]
            $y = $startY + $i
            $isSelected = ($i -eq $this.SelectedIndex)

            # Cursor
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
            if ($isSelected) {
                $sb.Append($cursorColor)
                $sb.Append("> ")
                $sb.Append($reset)
            } else {
                $sb.Append("  ")
            }

            # Task line
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))

            if ($isSelected) {
                # Selected - full highlight
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)

                $taskText = "[$($task.id)] $($task.text) ($($task.status))"
                $maxWidth = $contentRect.Width - 6
                $taskText = $this.Header.PadText($taskText, $maxWidth, 'left')

                $sb.Append($taskText)
                $sb.Append($reset)
            } else {
                # Not selected - regular display
                $sb.Append($textColor)
                $taskText = "[$($task.id)] $($task.text) "
                $sb.Append($taskText)
                $sb.Append($reset)

                # Status color-coded
                $statusColor = if ($task.status -eq 'blocked') { $blockedColor } else { $waitingColor }
                $sb.Append($statusColor)
                $sb.Append("($($task.status))")
                $sb.Append($reset)
            }
        }

        # Show truncation indicator if needed
        if ($this.BlockedTasks.Count -gt $maxLines) {
            $y = $startY + $maxLines
            $remaining = $this.BlockedTasks.Count - $maxLines
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
            $sb.Append($mutedColor)
            $sb.Append("... and $remaining more")
            $sb.Append($reset)
        }

        $result = $sb.ToString()
        
        return $result
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        if ($this.BlockedTasks.Count -eq 0) {
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
                if ($this.SelectedIndex -lt ($this.BlockedTasks.Count - 1)) {
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
            'D' {
                $this._ToggleStatus()
                return $true
            }
        }

        return $false
    }

    hidden [void] _ShowTaskDetail() {
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.BlockedTasks.Count) {
            $task = $this.BlockedTasks[$this.SelectedIndex]
            $this.ShowStatus("Task detail: [$($task.id)] $($task.text)")
            # TODO: Push detail screen when implemented
        }
    }

    hidden [void] _EditTask() {
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.BlockedTasks.Count) {
            $task = $this.BlockedTasks[$this.SelectedIndex]
            $this.ShowStatus("Edit task: [$($task.id)]")
            # TODO: Push edit screen when implemented
        }
    }

    hidden [void] _ToggleStatus() {
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.BlockedTasks.Count) {
            $task = $this.BlockedTasks[$this.SelectedIndex]
            # Toggle between blocked and waiting
            if ($task.status -eq 'blocked') {
                $task.status = 'waiting'
                $this.ShowSuccess("Changed to waiting")
            } else {
                $task.status = 'blocked'
                $this.ShowSuccess("Changed to blocked")
            }
            # TODO: Save task when save functions implemented
        }
    }
}

# Entry point function for compatibility
function Show-BlockedTasksScreen {
    param([PmcApplication]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [BlockedTasksScreen]::new()
    $App.PushScreen($screen)
}
