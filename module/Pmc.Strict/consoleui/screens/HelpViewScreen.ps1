using namespace System.Collections.Generic
using namespace System.Text

# HelpViewScreen - PMC TUI Help documentation
# Static help screen showing keyboard shortcuts and commands


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Help screen showing PMC TUI keyboard shortcuts and commands

.DESCRIPTION
Static help documentation screen showing:
- Global keyboard shortcuts
- Task list commands
- Multi-select mode keys
- Quick add syntax
- Feature overview
No navigation needed, just Esc to exit.
#>
class HelpViewScreen : PmcScreen {

    # Static: Register menu items
    static [void] RegisterMenuItems([object]$registry) {
        $registry.AddMenuItem('Help', 'Help', 'H', {
            . "$PSScriptRoot/HelpViewScreen.ps1"
            $global:PmcApp.PushScreen([HelpViewScreen]::new())
        }, 10)
    }

    # Constructor
    HelpViewScreen() : base("HelpView", "PMC TUI Help") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Help"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Esc", "Back")

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
        # Archived view screens - these were consolidated/removed
        # $tasksMenu.Items.Add([PmcMenuItem]::new("Today", 'Y', {
        #     . "$PSScriptRoot/TodayViewScreen.ps1"
        #     $global:PmcApp.PushScreen((New-Object TodayViewScreen))
        # }))
        # $tasksMenu.Items.Add([PmcMenuItem]::new("Tomorrow", 'T', {
        #     . "$PSScriptRoot/TomorrowViewScreen.ps1"
        #     $global:PmcApp.PushScreen((New-Object TomorrowViewScreen))
        # }))
        # $tasksMenu.Items.Add([PmcMenuItem]::new("Week View", 'W', {
        #     . "$PSScriptRoot/WeekViewScreen.ps1"
        #     $global:PmcApp.PushScreen((New-Object WeekViewScreen))
        # }))
        # $tasksMenu.Items.Add([PmcMenuItem]::new("Upcoming", 'U', {
        #     . "$PSScriptRoot/UpcomingViewScreen.ps1"
        #     $global:PmcApp.PushScreen((New-Object UpcomingViewScreen))
        # }))
        # $tasksMenu.Items.Add([PmcMenuItem]::new("Overdue", 'V', {
        #     . "$PSScriptRoot/OverdueViewScreen.ps1"
        #     $global:PmcApp.PushScreen((New-Object OverdueViewScreen))
        # }))
        # $tasksMenu.Items.Add([PmcMenuItem]::new("Next Actions", 'N', {
        #     . "$PSScriptRoot/NextActionsViewScreen.ps1"
        #     $global:PmcApp.PushScreen((New-Object NextActionsViewScreen))
        # }))
        # $tasksMenu.Items.Add([PmcMenuItem]::new("No Due Date", 'D', {
        #     . "$PSScriptRoot/NoDueDateViewScreen.ps1"
        #     $global:PmcApp.PushScreen((New-Object NoDueDateViewScreen))
        # }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Blocked Tasks", 'B', {
            . "$PSScriptRoot/BlockedTasksScreen.ps1"
            $global:PmcApp.PushScreen((New-Object BlockedTasksScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::Separator())
        $tasksMenu.Items.Add([PmcMenuItem]::new("Kanban Board", 'K', {
            . "$PSScriptRoot/KanbanScreen.ps1"
            $global:PmcApp.PushScreen((New-Object KanbanScreen))
        }))
        # $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', {
        #     . "$PSScriptRoot/MonthViewScreen.ps1"
        #     $global:PmcApp.PushScreen((New-Object MonthViewScreen))
        # }))
        # $tasksMenu.Items.Add([PmcMenuItem]::new("Agenda View", 'A', {
        #     . "$PSScriptRoot/AgendaViewScreen.ps1"
        #     $global:PmcApp.PushScreen((New-Object AgendaViewScreen))
        # }))
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
        # Static content, no data to load
        $this.ShowStatus("Help documentation")
    }

    [string] RenderContent() {
        $sb = [System.Text.StringBuilder]::new(4096)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $highlightColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $headerColor = $this.Header.GetThemedAnsi('Primary', $false)
        $reset = "`e[0m"

        $y = $contentRect.Y + 1
        $indent = $contentRect.X + 4
        $subIndent = $contentRect.X + 6

        # Global Keys
        $sb.Append($this.Header.BuildMoveTo($indent, $y++))
        $sb.Append($headerColor)
        $sb.Append("Global Keys:")
        $sb.Append($reset)
        $y++

        $globalKeys = @(
            "?         - Show this help screen"
            "F10       - Open menu bar"
            "Esc       - Back / Close menus / Exit"
            "R         - Refresh current view"
            "F         - Filter panel (when available)"
            "Alt+X     - Quick exit PMC"
            "Alt+T     - Open task list"
            "Alt+A     - Add new task"
            "Alt+P     - Project list"
        )
        foreach ($line in $globalKeys) {
            $sb.Append($this.Header.BuildMoveTo($subIndent, $y++))
            $sb.Append($textColor)
            $sb.Append($line)
            $sb.Append($reset)
        }
        $y++

        # Task List Keys
        $sb.Append($this.Header.BuildMoveTo($indent, $y++))
        $sb.Append($headerColor)
        $sb.Append("Task List Keys:")
        $sb.Append($reset)
        $y++

        $taskKeys = @(
            "Up/Down   - Navigate tasks"
            "PgUp/PgDn - Scroll page"
            "Enter     - View task details"
            "A         - Add new task"
            "E         - Edit task"
            "C         - Complete task"
            "D         - Delete task"
            "X         - Clone task"
            "S         - Add subtask to selected"
            "H         - Toggle show completed"
            "Tab       - Next field (when editing)"
            "/         - Search tasks"
            "1         - View: All tasks"
            "2         - View: Active tasks"
            "3         - View: Completed tasks"
            "4         - View: Overdue tasks"
            "5         - View: Today's tasks"
            "6         - View: This week's tasks"
        )
        foreach ($line in $taskKeys) {
            $sb.Append($this.Header.BuildMoveTo($subIndent, $y++))
            $sb.Append($textColor)
            $sb.Append($line)
            $sb.Append($reset)
        }
        $y++

        # Multi-Select Mode
        if ($y -lt $contentRect.Y + $contentRect.Height - 10) {
            $sb.Append($this.Header.BuildMoveTo($indent, $y++))
            $sb.Append($headerColor)
            $sb.Append("Multi-Select Mode:")
            $sb.Append($reset)
            $y++

            $multiKeys = @(
                "Space     - Toggle task selection"
                "A         - Select all visible tasks"
                "N         - Clear all selections"
                "D         - Complete selected tasks"
                "X         - Delete selected tasks"
            )
            foreach ($line in $multiKeys) {
                $sb.Append($this.Header.BuildMoveTo($subIndent, $y++))
                $sb.Append($textColor)
                $sb.Append($line)
                $sb.Append($reset)
            }
            $y++
        }

        # Project List Keys
        if ($y -lt $contentRect.Y + $contentRect.Height - 12) {
            $sb.Append($this.Header.BuildMoveTo($indent, $y++))
            $sb.Append($headerColor)
            $sb.Append("Project List Keys:")
            $sb.Append($reset)
            $y++

            $projectKeys = @(
                "A         - Add new project"
                "E         - Edit project"
                "D         - Delete project"
                "R         - Archive/Unarchive project"
                "V         - View project details"
            )
            foreach ($line in $projectKeys) {
                $sb.Append($this.Header.BuildMoveTo($subIndent, $y++))
                $sb.Append($textColor)
                $sb.Append($line)
                $sb.Append($reset)
            }
            $y++
        }

        # Time Tracking Keys
        if ($y -lt $contentRect.Y + $contentRect.Height - 10) {
            $sb.Append($this.Header.BuildMoveTo($indent, $y++))
            $sb.Append($headerColor)
            $sb.Append("Time Tracking Keys:")
            $sb.Append($reset)
            $y++

            $timeKeys = @(
                "A         - Add time entry"
                "E         - Edit time entry"
                "D         - Delete time entry"
                "Enter     - View entry details (aggregated entries)"
                "W         - Weekly time report"
                "G         - Generate time report"
                "←/→       - Navigate weeks (in week view)"
            )
            foreach ($line in $timeKeys) {
                $sb.Append($this.Header.BuildMoveTo($subIndent, $y++))
                $sb.Append($textColor)
                $sb.Append($line)
                $sb.Append($reset)
            }
            $y++
        }

        # Quick Add Syntax
        if ($y -lt $contentRect.Y + $contentRect.Height - 8) {
            $sb.Append($this.Header.BuildMoveTo($indent, $y++))
            $sb.Append($headerColor)
            $sb.Append("Quick Add Syntax:")
            $sb.Append($reset)
            $y++

            $quickAdd = @(
                "@project  - Set project (e.g., 'Fix bug @work')"
                "#priority - Set priority: #high #medium #low or #h #m #l"
                "!due      - Set due date: !today !tomorrow !+7 (days)"
            )
            foreach ($line in $quickAdd) {
                $sb.Append($this.Header.BuildMoveTo($subIndent, $y++))
                $sb.Append($mutedColor)
                $sb.Append($line)
                $sb.Append($reset)
            }
            $y++
        }

        # Features
        if ($y -lt $contentRect.Y + $contentRect.Height - 5) {
            $sb.Append($this.Header.BuildMoveTo($indent, $y++))
            $sb.Append($headerColor)
            $sb.Append("Features:")
            $sb.Append($reset)
            $y++

            $features = @(
                "Real-time PMC data integration"
                "Quick add syntax for fast task creation"
                "Multi-select mode for bulk operations"
                "Color-coded priorities and overdue warnings"
                "Project filtering and task search"
                "Inline editing with Tab navigation"
            )
            foreach ($line in $features) {
                if ($y -ge $contentRect.Y + $contentRect.Height - 2) { break }
                $sb.Append($this.Header.BuildMoveTo($subIndent, $y++))
                $sb.Append($mutedColor)
                $sb.Append("• ")
                $sb.Append($textColor)
                $sb.Append($line)
                $sb.Append($reset)
            }
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Let MenuBar handle its keys first (F10, menu navigation, etc.)
        if ($null -ne $this.MenuBar -and $this.MenuBar.HandleKeyPress($keyInfo)) {
            return $true
        }

        # All other keys are ignored on help screen
        return $false
    }

    hidden [void] _ShowAbout() {
        $this.ShowStatus("PMC TUI v1.0 - Project Management Console")
    }

    hidden [void] _ShowVersion() {
        $this.ShowStatus("Version 1.0.0")
    }
}

# Entry point function for compatibility
function Show-HelpViewScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [HelpViewScreen]::new()
    $App.PushScreen($screen)
}
