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

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
    }

    # Constructor with container
    ProjectInfoScreen([object]$container) : base("ProjectInfo", "Project Information", $container) {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Projects", "Info"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("E", "Edit")
        $this.Footer.AddShortcut("D", "Delete")
        $this.Footer.AddShortcut("T", "Tasks")
        $this.Footer.AddShortcut("Esc", "Back")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
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
            $data = Get-PmcData

            # Find project
            $this.ProjectData = $data.projects | Where-Object {
                ($_ -is [string] -and $_ -eq $this.ProjectName) -or
                ((Get-SafeProperty $_ 'name') -eq $this.ProjectName)
            } | Select-Object -First 1

            if (-not $this.ProjectData) {
                $this.ShowError("Project '$($this.ProjectName)' not found")
                return
            }

            # Get project tasks
            $this.ProjectTasks = @($data.tasks | Where-Object { (Get-SafeProperty $_ 'project') -eq $this.ProjectName })

            # Calculate statistics
            $this.ProjectStats = @{
                TotalTasks = $this.ProjectTasks.Count
                ActiveTasks = @($this.ProjectTasks | Where-Object { (Get-SafeProperty $_ 'status') -ne 'completed' }).Count
                CompletedTasks = @($this.ProjectTasks | Where-Object { (Get-SafeProperty $_ 'status') -eq 'completed' }).Count
                OverdueTasks = 0
            }

            # Count overdue tasks
            $today = (Get-Date).Date
            foreach ($task in $this.ProjectTasks) {
                $taskStatus = Get-SafeProperty $task 'status'
                $taskDue = Get-SafeProperty $task 'due'
                if ($taskStatus -ne 'completed' -and $taskDue) {
                    try {
                        $dueDate = [DateTime]::Parse($taskDue)
                        if ($dueDate.Date -lt $today) {
                            $this.ProjectStats.OverdueTasks++
                        }
                    } catch {
                        if (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue) {
                            Write-PmcTuiLog "Failed to parse due date '$taskDue' for task: $($_.Exception.Message)" "DEBUG"
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
        $name = if ($this.ProjectData -is [string]) { $this.ProjectData } else { Get-SafeProperty $this.ProjectData 'name' }
        $sb.Append($name)
        $sb.Append($reset)
        $y++

        # Description
        $projectDescription = Get-SafeProperty $this.ProjectData 'description'
        if ($this.ProjectData -isnot [string] -and $projectDescription) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($mutedColor)
            $sb.Append("Description: ")
            $sb.Append($reset)
            $sb.Append($textColor)
            $sb.Append($projectDescription)
            $sb.Append($reset)
            $y++
        }

        # Status
        $projectStatus = Get-SafeProperty $this.ProjectData 'status'
        if ($this.ProjectData -isnot [string] -and $projectStatus) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($mutedColor)
            $sb.Append("Status: ")
            $sb.Append($reset)
            $sb.Append($textColor)
            $sb.Append($projectStatus)
            $sb.Append($reset)
        }

        # Created date
        $projectCreated = Get-SafeProperty $this.ProjectData 'created'
        if ($this.ProjectData -isnot [string] -and $projectCreated) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
            $sb.Append($mutedColor)
            $sb.Append("Created: ")
            $sb.Append($reset)
            $sb.Append($textColor)
            $sb.Append($projectCreated)
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

                $taskStatus = Get-SafeProperty $task 'status'
                $taskText = Get-SafeProperty $task 'text'
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y++))
                $statusIcon = if ($taskStatus -eq 'completed') { "[X]" } else { "[ ]" }
                $statusColor = if ($taskStatus -eq 'completed') { $successColor } else { $textColor }
                $sb.Append($statusColor)
                $sb.Append($statusIcon)
                $sb.Append($reset)
                $sb.Append(" ")
                $sb.Append($textColor)
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
        $keyChar = [char]::ToLower($keyInfo.KeyChar)

        switch ($keyChar) {
            'e' {
                $this._EditProject()
                return $true
            }
            'd' {
                $this._DeleteProject()
                return $true
            }
            't' {
                $this._ViewTasks()
                return $true
            }
            'r' {
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
        $allData = Get-PmcData
        $project = $allData.projects | Where-Object { (Get-SafeProperty $_ 'name') -eq $this.ProjectName }

        if ($project) {
            # Count tasks in this project
            $taskCount = ($allData.tasks | Where-Object { (Get-SafeProperty $_ 'project') -eq $this.ProjectName }).Count

            if ($taskCount -gt 0) {
                $this.ShowError("Cannot delete project with $taskCount tasks. Move or delete tasks first.")
            } else {
                $allData.projects = @($allData.projects | Where-Object { (Get-SafeProperty $_ 'name') -ne $this.ProjectName })
                # FIX: Use Save-PmcData instead of Set-PmcAllData
                Save-PmcData -Data $allData
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
