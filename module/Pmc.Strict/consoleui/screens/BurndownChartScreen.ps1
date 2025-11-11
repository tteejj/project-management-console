using namespace System.Collections.Generic
using namespace System.Text

# BurndownChartScreen - Shows burndown chart with task metrics
# Displays completion metrics and progress bar visualization


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Screen showing burndown chart with task completion metrics

.DESCRIPTION
Shows a burndown chart with:
- Task summary (total, completed, in progress, blocked, todo)
- Completion percentage
- Visual progress bar
- Legend

Can filter by project or show all projects.
This is a read-only chart screen with no task navigation.
#>
class BurndownChartScreen : PmcScreen {
    # Data
    [int]$TotalTasks = 0
    [int]$CompletedTasks = 0
    [int]$InProgressTasks = 0
    [int]$BlockedTasks = 0
    [int]$TodoTasks = 0
    [double]$CompletionPct = 0
    [string]$FilterProject = ""

    # Constructor
    BurndownChartScreen() : base("BurndownChart", "Burndown Chart") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Views", "Burndown"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("R", "Refresh")
        $this.Footer.AddShortcut("F", "Filter")
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
        $this.ShowStatus("Loading burndown metrics...")

        try {
            # Load PMC data
            $data = Get-PmcAllData

            # Filter tasks by project if needed
            $projectTasks = if ($this.FilterProject) {
                @($data.tasks | Where-Object { $_.project -eq $this.FilterProject })
            } else {
                @($data.tasks)
            }

            # Calculate burndown metrics
            $this.TotalTasks = $projectTasks.Count

            # Completed tasks (completed = true or status = 'done'/'completed')
            $this.CompletedTasks = @($projectTasks | Where-Object {
                $_.completed -or $_.status -eq 'done' -or $_.status -eq 'completed'
            }).Count

            # In progress tasks
            $this.InProgressTasks = @($projectTasks | Where-Object {
                -not $_.completed -and ($_.status -eq 'in-progress' -or $_.status -eq 'active')
            }).Count

            # Blocked tasks
            $this.BlockedTasks = @($projectTasks | Where-Object {
                -not $_.completed -and $_.status -eq 'blocked'
            }).Count

            # Todo tasks (everything else that's not completed)
            $this.TodoTasks = @($projectTasks | Where-Object {
                -not $_.completed -and
                $_.status -ne 'in-progress' -and
                $_.status -ne 'active' -and
                $_.status -ne 'blocked'
            }).Count

            # Calculate completion percentage
            $this.CompletionPct = if ($this.TotalTasks -gt 0) {
                [math]::Round(($this.CompletedTasks / $this.TotalTasks) * 100, 1)
            } else {
                0
            }

            # Update status
            $projectText = if ($this.FilterProject) { "Project: $($this.FilterProject)" } else { "All Projects" }
            $this.ShowStatus("$projectText - $($this.CompletionPct)% complete")

        } catch {
            $this.ShowError("Failed to load burndown metrics: $_")
            $this.TotalTasks = 0
            $this.CompletedTasks = 0
            $this.InProgressTasks = 0
            $this.BlockedTasks = 0
            $this.TodoTasks = 0
            $this.CompletionPct = 0
        }
    }

    [string] RenderContent() {
        $sb = [System.Text.StringBuilder]::new(2048)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $headerColor = $this.Header.GetThemedAnsi('Accent', $false)
        $completedColor = $this.Header.GetThemedAnsi('Success', $false)
        $inProgressColor = $this.Header.GetThemedAnsi('Warning', $false)
        $blockedColor = $this.Header.GetThemedAnsi('Error', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        $y = $this.Header.Y + 4  # Start after header and breadcrumb

        # Project title
        $projectTitle = if ($this.FilterProject) { "Project: $($this.FilterProject)" } else { "All Projects" }
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
        $sb.Append($headerColor)
        $sb.Append($projectTitle)
        $sb.Append($reset)
        $y++

        # Task Summary
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
        $sb.Append($headerColor)
        $sb.Append("Task Summary:")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
        $sb.Append($textColor)
        $sb.Append("Total Tasks:      $($this.TotalTasks)")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
        $sb.Append($completedColor)
        $sb.Append("Completed:        $($this.CompletedTasks)")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
        $sb.Append($inProgressColor)
        $sb.Append("In Progress:      $($this.InProgressTasks)")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
        $sb.Append($blockedColor)
        $sb.Append("Blocked:          $($this.BlockedTasks)")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
        $sb.Append($textColor)
        $sb.Append("To Do:            $($this.TodoTasks)")
        $sb.Append($reset)
        $y++

        # Completion percentage
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
        $sb.Append($headerColor)
        $sb.Append("Completion: $($this.CompletionPct)%")
        $sb.Append($reset)
        $y++

        # Draw progress bar
        $barWidth = 50
        $completedWidth = if ($this.TotalTasks -gt 0) {
            [math]::Floor(($this.CompletedTasks / $this.TotalTasks) * $barWidth)
        } else {
            0
        }
        $inProgressWidth = if ($this.TotalTasks -gt 0) {
            [math]::Floor(($this.InProgressTasks / $this.TotalTasks) * $barWidth)
        } else {
            0
        }
        $remainingWidth = $barWidth - $completedWidth - $inProgressWidth

        $bar = ""
        if ($completedWidth -gt 0) {
            $bar += [string]::new([char]0x2588, $completedWidth)  # █
        }
        if ($inProgressWidth -gt 0) {
            $bar += [string]::new([char]0x2592, $inProgressWidth)  # ▒
        }
        if ($remainingWidth -gt 0) {
            $bar += [string]::new([char]0x2591, $remainingWidth)  # ░
        }

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
        $sb.Append($textColor)
        $sb.Append("Progress:")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
        $sb.Append($textColor)
        $sb.Append("[$bar]")
        $sb.Append($reset)
        $y++

        # Legend
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
        $sb.Append($headerColor)
        $sb.Append("Legend:")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
        $sb.Append($completedColor)
        $sb.Append([char]0x2588)
        $sb.Append(" Completed")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
        $sb.Append($inProgressColor)
        $sb.Append([char]0x2592)
        $sb.Append(" In Progress")
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
        $sb.Append($mutedColor)
        $sb.Append([char]0x2591)
        $sb.Append(" To Do")
        $sb.Append($reset)

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # This is a chart screen with no navigation
        # Only handle refresh and filter commands
        $keyChar = [char]::ToLower($keyInfo.KeyChar)
        switch ($keyChar) {
            'r' {
                $this.LoadData()
                return $true
            }
            'f' {
                # Show project list for filtering
                $allData = Get-PmcAllData
                $projects = $allData.projects | Where-Object { -not $_.archived }

                if ($projects.Count -eq 0) {
                    $this.ShowError("No projects available")
                    return $true
                }

                # For now, cycle through projects
                $currentIndex = -1
                for ($i = 0; $i -lt $projects.Count; $i++) {
                    if ($projects[$i].name -eq $this.FilterProject) {
                        $currentIndex = $i
                        break
                    }
                }

                $nextIndex = ($currentIndex + 1) % ($projects.Count + 1)

                if ($nextIndex -eq $projects.Count) {
                    $this.FilterProject = ""
                    $this.ShowStatus("Filter cleared - showing all projects")
                } else {
                    $this.FilterProject = $projects[$nextIndex].name
                    $this.ShowStatus("Filtered to project: $($this.FilterProject)")
                }

                $this.LoadData()
                return $true
            }
        }

        return $false
    }
}

# Entry point function for compatibility
function Show-BurndownChartScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [BurndownChartScreen]::new()
    $App.PushScreen($screen)
}
