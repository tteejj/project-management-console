using namespace System.Collections.Generic
using namespace System.Text

# ProjectInfoScreen - Detailed project information
# Shows comprehensive details about a single project

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
        $tasksMenu.Items.Add([PmcMenuItem]::new("Task List", 'L', { Write-Host "Task List not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Tomorrow", 'T', { Write-Host "Tomorrow view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Upcoming", 'U', { Write-Host "Upcoming view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Next Actions", 'N', { Write-Host "Next Actions view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("No Due Date", 'D', { Write-Host "No Due Date view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::Separator())
        $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', { Write-Host "Month view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Agenda View", 'A', { Write-Host "Agenda view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Burndown Chart", 'B', { Write-Host "Burndown chart not implemented" }))

        # Projects menu
        $projectsMenu = $this.MenuBar.Menus[1]
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project List", 'L', { Write-Host "Project list not implemented" }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Stats", 'S', { Write-Host "Project stats not implemented" }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Info", 'I', { $screen.LoadData() }.GetNewClosure()))

        # Options menu
        $optionsMenu = $this.MenuBar.Menus[2]
        $optionsMenu.Items.Add([PmcMenuItem]::new("Theme Editor", 'T', { Write-Host "Theme editor not implemented" }))
        $optionsMenu.Items.Add([PmcMenuItem]::new("Settings", 'S', { Write-Host "Settings not implemented" }))

        # Help menu
        $helpMenu = $this.MenuBar.Menus[3]
        $helpMenu.Items.Add([PmcMenuItem]::new("Help View", 'H', { Write-Host "Help view not implemented" }))
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
                    } catch {}
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

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
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
        $this.ShowStatus("Delete project: $($this.ProjectName) - Not implemented")
        # In a real implementation, would show confirmation and delete
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
