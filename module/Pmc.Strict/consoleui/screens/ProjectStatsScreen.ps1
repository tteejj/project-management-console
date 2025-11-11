using namespace System.Collections.Generic
using namespace System.Text

# ProjectStatsScreen - Project statistics overview
# Shows task counts and completion percentages for all projects


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Project statistics screen showing task metrics for all projects

.DESCRIPTION
Shows statistics for each project including:
- Active task count
- Completed task count
- Total task count
- Completion percentage
Supports:
- Navigation (Up/Down arrows)
- View project details (Enter)
#>
class ProjectStatsScreen : PmcScreen {
    # Data
    [array]$Projects = @()
    [int]$SelectedIndex = 0

    # Constructor
    ProjectStatsScreen() : base("ProjectStats", "Project Statistics") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Projects", "Statistics"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "Details")
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
        $this.ShowStatus("Calculating project statistics...")

        try {
            # Get PMC data
            $data = Get-PmcAllData

            # Calculate stats for each project
            $projectStats = @{}

            # Count tasks per project
            foreach ($task in $data.tasks) {
                $projectName = if ($task.project) { $task.project } else { "inbox" }

                if (-not $projectStats.ContainsKey($projectName)) {
                    $projectStats[$projectName] = @{
                        Name = $projectName
                        Active = 0
                        Completed = 0
                        Total = 0
                        CompletionPercent = 0
                    }
                }

                $projectStats[$projectName].Total++

                if ($task.status -eq 'completed' -or $task.completed) {
                    $projectStats[$projectName].Completed++
                } else {
                    $projectStats[$projectName].Active++
                }
            }

            # Calculate completion percentages
            foreach ($projectName in $projectStats.Keys) {
                $stats = $projectStats[$projectName]
                if ($stats.Total -gt 0) {
                    $stats.CompletionPercent = [Math]::Round(($stats.Completed / $stats.Total) * 100, 1)
                }
            }

            # Convert to array and sort by name
            $this.Projects = @($projectStats.Values | Sort-Object -Property Name)

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.Projects.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.Projects.Count - 1)
            }

            $this.ShowSuccess("$($this.Projects.Count) projects analyzed")

        } catch {
            $this.ShowError("Failed to load project statistics: $_")
            $this.Projects = @()
        }
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
        $selectedBg = $this.Header.GetThemedAnsi('Primary', $true)
        $selectedFg = $this.Header.GetThemedAnsi('Text', $false)
        $cursorColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
        $successColor = $this.Header.GetThemedAnsi('Success', $false)
        $reset = "`e[0m"

        # Column widths
        $nameWidth = 25
        $activeWidth = 8
        $doneWidth = 8
        $totalWidth = 8
        $pctWidth = 10

        # Render column headers
        $headerY = $this.Header.Y + 3
        $x = $contentRect.X + 4
        $sb.Append($this.Header.BuildMoveTo($x, $headerY))
        $sb.Append($headerColor)
        $sb.Append("PROJECT NAME".PadRight($nameWidth))
        $x += $nameWidth
        $sb.Append($this.Header.BuildMoveTo($x, $headerY))
        $sb.Append("ACTIVE".PadRight($activeWidth))
        $x += $activeWidth
        $sb.Append($this.Header.BuildMoveTo($x, $headerY))
        $sb.Append("DONE".PadRight($doneWidth))
        $x += $doneWidth
        $sb.Append($this.Header.BuildMoveTo($x, $headerY))
        $sb.Append("TOTAL".PadRight($totalWidth))
        $x += $totalWidth
        $sb.Append($this.Header.BuildMoveTo($x, $headerY))
        $sb.Append("COMPL%")
        $sb.Append($reset)

        # Render project stats
        $startY = $headerY + 2
        $maxLines = $contentRect.Height - 4

        if ($this.Projects.Count -eq 0) {
            $emptyY = $startY + 2
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $emptyY))
            $sb.Append($mutedColor)
            $sb.Append("No projects found")
            $sb.Append($reset)
        } else {
            for ($i = 0; $i -lt [Math]::Min($this.Projects.Count, $maxLines); $i++) {
                $project = $this.Projects[$i]
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

                # Project name
                $x = $contentRect.X + 4
                $sb.Append($this.Header.BuildMoveTo($x, $y))
                if ($isSelected) {
                    $sb.Append($selectedBg)
                    $sb.Append($selectedFg)
                } else {
                    $sb.Append($textColor)
                }
                $name = $project.Name
                if ($name.Length -gt $nameWidth - 1) {
                    $name = $name.Substring(0, $nameWidth - 4) + "..."
                }
                $sb.Append($name.PadRight($nameWidth))
                $sb.Append($reset)

                # Active count
                $x += $nameWidth
                $sb.Append($this.Header.BuildMoveTo($x, $y))
                $sb.Append($textColor)
                $sb.Append($project.Active.ToString().PadLeft($activeWidth - 1))
                $sb.Append($reset)

                # Completed count
                $x += $activeWidth
                $sb.Append($this.Header.BuildMoveTo($x, $y))
                $sb.Append($successColor)
                $sb.Append($project.Completed.ToString().PadLeft($doneWidth - 1))
                $sb.Append($reset)

                # Total count
                $x += $doneWidth
                $sb.Append($this.Header.BuildMoveTo($x, $y))
                $sb.Append($textColor)
                $sb.Append($project.Total.ToString().PadLeft($totalWidth - 1))
                $sb.Append($reset)

                # Completion percentage
                $x += $totalWidth
                $sb.Append($this.Header.BuildMoveTo($x, $y))
                $pctColor = if ($project.CompletionPercent -ge 75) { $successColor }
                           elseif ($project.CompletionPercent -ge 50) { $textColor }
                           else { $mutedColor }
                $sb.Append($pctColor)
                $sb.Append("$($project.CompletionPercent)%")
                $sb.Append($reset)
            }
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        $keyChar = [char]::ToLower($keyInfo.KeyChar)
        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.Projects.Count - 1)) {
                    $this.SelectedIndex++
                    return $true
                }
            }
            'Enter' {
                $this._ViewDetails()
                return $true
            }
        }

        switch ($keyChar) {
            'r' {
                $this.LoadData()
                return $true
            }
        }

        return $false
    }

    hidden [void] _ViewDetails() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Projects.Count) {
            return
        }

        $project = $this.Projects[$this.SelectedIndex]
        $this.ShowStatus("Opening details for: $($project.Name)")
        # In a real implementation, would navigate to project detail screen
    }
}

# Entry point function for compatibility
function Show-ProjectStatsScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [ProjectStatsScreen]::new()
    $App.PushScreen($screen)
}
