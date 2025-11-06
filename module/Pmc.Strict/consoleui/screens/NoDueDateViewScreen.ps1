using namespace System.Collections.Generic
using namespace System.Text

# NoDueDateViewScreen - Shows tasks without a due date
# Displays incomplete tasks that have no due date set

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Screen showing tasks without due dates

.DESCRIPTION
Shows list of tasks with no due date set and not completed.
Tasks are sorted by priority (descending), then by id.
Useful for tracking backlog items or tasks that need scheduling.
#>
class NoDueDateViewScreen : PmcScreen {
    # Data
    [array]$NoDueDateTasks = @()
    [int]$SelectedIndex = 0

    # Constructor
    NoDueDateViewScreen() : base("NoDueDateView", "Tasks Without Due Date") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks", "No Due Date"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "Detail")
        $this.Footer.AddShortcut("E", "Edit")
        $this.Footer.AddShortcut("C", "Complete")
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
        $tasksMenu.Items.Add([PmcMenuItem]::new("Task List", 'L', { Write-Host "Task List not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Tomorrow", 'T', { Write-Host "Tomorrow view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Upcoming", 'U', { Write-Host "Upcoming view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Next Actions", 'N', { Write-Host "Next Actions view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("No Due Date", 'D', { $screen.LoadData() }.GetNewClosure()))
        $tasksMenu.Items.Add([PmcMenuItem]::Separator())
        $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', { Write-Host "Month view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Agenda View", 'A', { Write-Host "Agenda view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Burndown Chart", 'B', { Write-Host "Burndown chart not implemented" }))

        # Projects menu
        $projectsMenu = $this.MenuBar.Menus[1]
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project List", 'L', { Write-Host "Project list not implemented" }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Stats", 'S', { Write-Host "Project stats not implemented" }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Info", 'I', { Write-Host "Project info not implemented" }))

        # Options menu
        $optionsMenu = $this.MenuBar.Menus[2]
        $optionsMenu.Items.Add([PmcMenuItem]::new("Theme Editor", 'T', { Write-Host "Theme editor not implemented" }))
        $optionsMenu.Items.Add([PmcMenuItem]::new("Settings", 'S', { Write-Host "Settings not implemented" }))

        # Help menu
        $helpMenu = $this.MenuBar.Menus[3]
        $helpMenu.Items.Add([PmcMenuItem]::new("Help View", 'H', { Write-Host "Help view not implemented" }))
        $helpMenu.Items.Add([PmcMenuItem]::new("About", 'A', { Write-Host "PMC TUI v1.0" }))
    }

    [void] LoadData() {
        $this.ShowStatus("Loading tasks without due dates...")

        try {
            # Load PMC data
            $data = Get-PmcAllData

            # Filter tasks with no due date and not completed
            $this.NoDueDateTasks = @($data.tasks | Where-Object {
                -not $_.completed -and (-not $_.due -or $_.due -eq $null -or $_.due -eq '')
            })

            # Sort by priority (descending), then by id
            $this.NoDueDateTasks = @($this.NoDueDateTasks | Sort-Object -Property @{Expression={$_.priority}; Descending=$true}, @{Expression={$_.id}; Ascending=$true})

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.NoDueDateTasks.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.NoDueDateTasks.Count - 1)
            }

            # Update status
            if ($this.NoDueDateTasks.Count -eq 0) {
                $this.ShowSuccess("All tasks have due dates")
            } else {
                $this.ShowStatus("$($this.NoDueDateTasks.Count) task(s) without due date")
            }

        } catch {
            $this.ShowError("Failed to load tasks: $_")
            $this.NoDueDateTasks = @()
        }
    }

    [string] RenderContent() {
        if ($this.NoDueDateTasks.Count -eq 0) {
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
            $message = "All tasks have due dates"
            $x = $contentRect.X + [Math]::Floor(($contentRect.Width - $message.Length) / 2)
            $y = $contentRect.Y + [Math]::Floor($contentRect.Height / 2)

            $successColor = $this.Header.GetThemedAnsi('Success', $false)
            $reset = "`e[0m"

            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($successColor)
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
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
        $priorityColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        # Render column headers at line 4 (ABOVE separator which is at line 5)
        $headerY = $this.Header.Y + 3
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($headerColor)
        $sb.Append("PRI ")
        $sb.Append("ID    ")
        $sb.Append("TASK")
        $sb.Append($reset)

        # Render task rows
        $startY = $headerY + 2
        $maxLines = $contentRect.Height - 4

        for ($i = 0; $i -lt [Math]::Min($this.NoDueDateTasks.Count, $maxLines); $i++) {
            $task = $this.NoDueDateTasks[$i]
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

            # Task row
            $x = $contentRect.X + 4

            # Priority column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } elseif ($task.priority -gt 0) {
                $sb.Append($priorityColor)
            }
            $priText = if ($task.priority) { $task.priority.ToString().PadLeft(3) } else { "   " }
            $sb.Append($priText)
            $sb.Append(" ")
            $sb.Append($reset)
            $x += 4

            # ID column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($mutedColor)
            }
            $idText = "#$($task.id)".PadRight(6)
            $sb.Append($idText)
            $sb.Append($reset)
            $x += 6

            # Task text column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }
            $maxTaskWidth = $contentRect.Width - ($x - $contentRect.X)
            $taskText = $task.text
            if ($taskText.Length -gt $maxTaskWidth) {
                $taskText = $taskText.Substring(0, $maxTaskWidth - 3) + "..."
            }
            $sb.Append($taskText)
            $sb.Append($reset)
        }

        # Show truncation indicator if needed
        if ($this.NoDueDateTasks.Count -gt $maxLines) {
            $y = $startY + $maxLines
            $remaining = $this.NoDueDateTasks.Count - $maxLines
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("... and $remaining more")
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        if ($this.NoDueDateTasks.Count -eq 0) {
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
                if ($this.SelectedIndex -lt ($this.NoDueDateTasks.Count - 1)) {
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
            'C' {
                $this._CompleteTask()
                return $true
            }
            'S' {
                $this._SetDueDate()
                return $true
            }
            'R' {
                $this.LoadData()
                return $true
            }
        }

        return $false
    }

    hidden [void] _ShowTaskDetail() {
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.NoDueDateTasks.Count) {
            $task = $this.NoDueDateTasks[$this.SelectedIndex]
            $this.ShowStatus("Task detail: [$($task.id)] $($task.text)")
            # TODO: Push detail screen when implemented
        }
    }

    hidden [void] _EditTask() {
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.NoDueDateTasks.Count) {
            $task = $this.NoDueDateTasks[$this.SelectedIndex]
            $this.ShowStatus("Edit task: [$($task.id)]")
            # TODO: Push edit screen when implemented
        }
    }

    hidden [void] _SetDueDate() {
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.NoDueDateTasks.Count) {
            $task = $this.NoDueDateTasks[$this.SelectedIndex]
            $this.ShowStatus("Set due date for task: [$($task.id)]")
            # TODO: Show date picker when implemented
        }
    }

    hidden [void] _CompleteTask() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.NoDueDateTasks.Count) {
            return
        }

        $task = $this.NoDueDateTasks[$this.SelectedIndex]
        $taskId = $task.id

        # Remove from in-memory array
        $this.NoDueDateTasks = @($this.NoDueDateTasks | Where-Object { $_.id -ne $taskId })

        # Adjust selection
        if ($this.SelectedIndex -ge $this.NoDueDateTasks.Count -and $this.NoDueDateTasks.Count -gt 0) {
            $this.SelectedIndex = $this.NoDueDateTasks.Count - 1
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
function Show-NoDueDateViewScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [NoDueDateViewScreen]::new()
    $App.PushScreen($screen)
}
