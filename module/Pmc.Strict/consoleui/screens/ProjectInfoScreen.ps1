using namespace System.Collections.Generic
using namespace System.Text

# ProjectInfoScreen - Detailed project information
# Shows comprehensive details about a single project


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Project information screen showing detailed project data

.DESCRIPTION
Shows detailed information for a single project including:
- Project name and description
- Task counts (active/completed/total)
- Recent tasks
- Project metadata (status, created date, tags)
Supports:
- Editing project (E key)
- Deleting project (D key)
- Viewing tasks (T key)
#>
class ProjectInfoScreen : PmcScreen {
    # Data
    [string]$ProjectName = ""
    [object]$ProjectData = $null
    [array]$ProjectTasks = @()
    [hashtable]$ProjectStats = @{}

    # Constructor
    ProjectInfoScreen() : base("ProjectInfo", "Project Information") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Projects", "Info"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("E", "Edit")
        $this.Footer.AddShortcut("D", "Delete")
        $this.Footer.AddShortcut("T", "Tasks")
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

    [void] SetProject([string]$projectName) {
        $this.ProjectName = $projectName
    }

    [void] LoadData() {
        if ([string]::IsNullOrWhiteSpace($this.ProjectName)) {
            $this.ShowError("No project selected")
            return
        }

        $this.ShowStatus("Loading project information...")

        try {
            # Get PMC data
            $data = Get-PmcAllData

            # Find project
            $this.ProjectData = $data.projects | Where-Object {
                ($_ -is [string] -and $_ -eq $this.ProjectName) -or
                ($_.PSObject.Properties['name'] -and $_.name -eq $this.ProjectName)
            } | Select-Object -First 1

            if (-not $this.ProjectData) {
                $this.ShowError("Project '$($this.ProjectName)' not found")
                return
            }

            # Get project tasks
            $this.ProjectTasks = @($data.tasks | Where-Object { $_.project -eq $this.ProjectName })

            # Calculate statistics
            $this.ProjectStats = @{
                TotalTasks = $this.ProjectTasks.Count
                ActiveTasks = @($this.ProjectTasks | Where-Object { $_.status -ne 'completed' }).Count
                CompletedTasks = @($this.ProjectTasks | Where-Object { $_.status -eq 'completed' }).Count
                OverdueTasks = 0
            }

            # Count overdue tasks
            $today = (Get-Date).Date
            foreach ($task in $this.ProjectTasks) {
                if ($task.status -ne 'completed' -and $task.due) {
                    try {
                        $dueDate = [DateTime]::Parse($task.due)
                        if ($dueDate.Date -lt $today) {
                            $this.ProjectStats.OverdueTasks++
                        }
                    } catch {
                        if (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue) {
                            Write-PmcTuiLog "Failed to parse due date '$($task.due)' for task: $($_.Exception.Message)" "DEBUG"
                        }
                    }
                }
            }

            # Calculate completion percentage
            if ($this.ProjectStats.TotalTasks -gt 0) {
                $this.ProjectStats.CompletionPercent = [Math]::Round(
                    ($this.ProjectStats.CompletedTasks / $this.ProjectStats.TotalTasks) * 100, 1
                )
            } else {
                $this.ProjectStats.CompletionPercent = 0
            }

            $this.ShowSuccess("Loaded project: $($this.ProjectName)")

        } catch {
            $this.ShowError("Failed to load project: $_")
            $this.ProjectData = $null
            $this.ProjectTasks = @()
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
        $highlightColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
        $successColor = $this.Header.GetThemedAnsi('Success', $false)
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $reset = "`e[0m"

        $y = $contentRect.Y + 1

        if (-not $this.ProjectData) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("No project loaded")
            $sb.Append($reset)
            return $sb.ToString()
        }

        # Project name
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
        $sb.Append($highlightColor)
        $name = if ($this.ProjectData -is [string]) { $this.ProjectData } else { $this.ProjectData.name }
        $sb.Append($name)
        $sb.Append($reset)
        $y++

        # Description
        if ($this.ProjectData -isnot [string] -and $this.ProjectData.PSObject.Properties['description'] -and $this.ProjectData.description) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($mutedColor)
            $sb.Append("Description: ")
            $sb.Append($reset)
            $sb.Append($textColor)
            $sb.Append($this.ProjectData.description)
            $sb.Append($reset)
            $y++
        }

        # Status
        if ($this.ProjectData -isnot [string] -and $this.ProjectData.PSObject.Properties['status'] -and $this.ProjectData.status) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($mutedColor)
            $sb.Append("Status: ")
            $sb.Append($reset)
            $sb.Append($textColor)
            $sb.Append($this.ProjectData.status)
            $sb.Append($reset)
        }

        # Created date
        if ($this.ProjectData -isnot [string] -and $this.ProjectData.PSObject.Properties['created'] -and $this.ProjectData.created) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($mutedColor)
            $sb.Append("Created: ")
            $sb.Append($reset)
            $sb.Append($textColor)
            $sb.Append($this.ProjectData.created)
            $sb.Append($reset)
        }

        $y++

        # Task statistics
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
        $sb.Append($headerColor)
        $sb.Append("Task Statistics:")
        $sb.Append($reset)
        $y++

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
        $sb.Append($mutedColor)
        $sb.Append("Total Tasks:     ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sb.Append($this.ProjectStats.TotalTasks)
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
        $sb.Append($mutedColor)
        $sb.Append("Active Tasks:    ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sb.Append($this.ProjectStats.ActiveTasks)
        $sb.Append($reset)

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
        $sb.Append($mutedColor)
        $sb.Append("Completed Tasks: ")
        $sb.Append($reset)
        $sb.Append($successColor)
        $sb.Append($this.ProjectStats.CompletedTasks)
        $sb.Append($reset)

        if ($this.ProjectStats.OverdueTasks -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
            $sb.Append($mutedColor)
            $sb.Append("Overdue Tasks:   ")
            $sb.Append($reset)
            $sb.Append($warningColor)
            $sb.Append($this.ProjectStats.OverdueTasks)
            $sb.Append($reset)
        }

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
        $sb.Append($mutedColor)
        $sb.Append("Completion:      ")
        $sb.Append($reset)
        $sb.Append($successColor)
        $sb.Append("$($this.ProjectStats.CompletionPercent)%")
        $sb.Append($reset)

        $y++

        # Recent tasks
        if ($this.ProjectTasks.Count -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($headerColor)
            $sb.Append("Recent Tasks:")
            $sb.Append($reset)
            $y++

            $recentTasks = $this.ProjectTasks | Select-Object -First 5
            foreach ($task in $recentTasks) {
                if ($y -ge $contentRect.Y + $contentRect.Height - 2) { break }

                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
                $statusIcon = if ($task.status -eq 'completed') { "[X]" } else { "[ ]" }
                $statusColor = if ($task.status -eq 'completed') { $successColor } else { $textColor }
                $sb.Append($statusColor)
                $sb.Append($statusIcon)
                $sb.Append($reset)
                $sb.Append(" ")
                $sb.Append($textColor)
                $taskText = $task.text
                if ($taskText.Length -gt 60) {
                    $taskText = $taskText.Substring(0, 57) + "..."
                }
                $sb.Append($taskText)
                $sb.Append($reset)
            }
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'E' {
                $this._EditProject()
                return $true
            }
            'D' {
                $this._DeleteProject()
                return $true
            }
            'T' {
                $this._ViewTasks()
                return $true
            }
            'R' {
                $this.LoadData()
                return $true
            }
        }

        return $false
    }

    hidden [void] _EditProject() {
        $this.ShowStatus("Edit project: $($this.ProjectName)")
        # In a real implementation, would open edit form
    }

    hidden [void] _DeleteProject() {
        # Confirm and delete project
        $allData = Get-PmcAllData
        $project = $allData.projects | Where-Object { $_.name -eq $this.ProjectName }

        if ($project) {
            # Count tasks in this project
            $taskCount = ($allData.tasks | Where-Object { $_.project -eq $this.ProjectName }).Count

            if ($taskCount -gt 0) {
                $this.ShowError("Cannot delete project with $taskCount tasks. Move or delete tasks first.")
            } else {
                $allData.projects = @($allData.projects | Where-Object { $_.name -ne $this.ProjectName })
                Set-PmcAllData $allData
                $this.ShowSuccess("Project deleted: $($this.ProjectName)")
                $global:PmcApp.PopScreen()
            }
        }
    }

    hidden [void] _ViewTasks() {
        $this.ShowStatus("Viewing tasks for: $($this.ProjectName)")
        # In a real implementation, would navigate to filtered task list
    }
}

# Entry point function for compatibility
function Show-ProjectInfoScreen {
    param(
        [object]$App,
        [string]$ProjectName
    )

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [ProjectInfoScreen]::new()
    if ($ProjectName) {
        $screen.SetProject($ProjectName)
    }
    $App.PushScreen($screen)
}
