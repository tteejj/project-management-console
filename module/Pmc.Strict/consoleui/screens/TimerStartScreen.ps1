using namespace System.Collections.Generic
using namespace System.Text

# TimerStartScreen - Start timer for a task
# Shows task list, select task to start timer for


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Timer start screen

.DESCRIPTION
Shows list of active tasks to start timer for.
Supports:
- Navigating task list (Up/Down arrows)
- Starting timer for selected task (Enter key)
- Canceling (Esc key)
#>
class TimerStartScreen : PmcScreen {
    # Data
    [array]$Tasks = @()
    [int]$SelectedIndex = 0
    [object]$TimerStatus = $null

    # Backward compatible constructor
    TimerStartScreen() : base("TimerStart", "Start Timer") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Timer", "Start"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "Start Timer")
        $this.Footer.AddShortcut("Esc", "Cancel")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
    }

    # Container constructor
    TimerStartScreen([object]$container) : base("TimerStart", "Start Timer", $container) {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Timer", "Start"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "Start Timer")
        $this.Footer.AddShortcut("Esc", "Cancel")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
    }

    [void] LoadData() {
        $this.ShowStatus("Loading tasks...")

        try {
            # Get timer status
            try {
                $this.TimerStatus = Get-PmcTimerStatus
            } catch {
                $this.TimerStatus = [PSCustomObject]@{
                    Running = $false
                    StartTime = $null
                    Elapsed = 0
                    Task = $null
                    Project = $null
                }
            }

            # Check if timer is already running
            if ($this.TimerStatus.Running) {
                $this.ShowStatus("Timer already running! Stop it first.")
                $this.Tasks = @()
                return
            }

            # Get PMC data
            $data = Get-PmcData

            # Filter active tasks
            $this.Tasks = @($data.tasks | Where-Object {
                -not $_.completed -and $_.status -ne 'completed'
            })

            # Sort by priority (descending), then id
            $this.Tasks = @($this.Tasks | Sort-Object -Property @{Expression={$_.priority}; Descending=$true}, id)

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.Tasks.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.Tasks.Count - 1)
            }

            # Update status
            if ($this.Tasks.Count -eq 0) {
                $this.ShowStatus("No active tasks to track")
            } else {
                $this.ShowStatus("Select a task to start timer")
            }

        } catch {
            $this.ShowError("Failed to load tasks: $_")
            $this.Tasks = @()
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
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $selectedBg = $this.Header.GetThemedAnsi('Primary', $true)
        $selectedFg = $this.Header.GetThemedAnsi('Text', $false)
        $cursorColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $priorityColor = $this.Header.GetThemedAnsi('Warning', $false)
        $successColor = $this.Header.GetThemedAnsi('Success', $false)
        $reset = "`e[0m"

        $y = $contentRect.Y + 1

        # Check if timer is already running
        if ($this.TimerStatus -and $this.TimerStatus.Running) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($warningColor)
            $sb.Append("Timer is already running!")
            $sb.Append($reset)
            $y += 2

            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
            $sb.Append($textColor)
            $sb.Append("Started: ")
            $sb.Append($this.TimerStatus.StartTime)
            $sb.Append($reset)
            $y++

            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
            $sb.Append($textColor)
            $sb.Append("Elapsed: ")
            $sb.Append($highlightColor)
            $sb.Append("$($this.TimerStatus.Elapsed)h")
            $sb.Append($reset)
            $y++

            if ($this.TimerStatus.Task) {
                $y++
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
                $sb.Append($textColor)
                $sb.Append("Task: ")
                $sb.Append($this.TimerStatus.Task)
                $sb.Append($reset)
                $y++
            }

            if ($this.TimerStatus.Project) {
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
                $sb.Append($textColor)
                $sb.Append("Project: ")
                $sb.Append($this.TimerStatus.Project)
                $sb.Append($reset)
                $y++
            }

            $y += 2
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("Stop the timer first before starting a new one.")
            $sb.Append($reset)

            return $sb.ToString()
        }

        # Show task list if no timer running
        if ($this.Tasks.Count -eq 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("No active tasks available")
            $sb.Append($reset)
            return $sb.ToString()
        }

        # Title
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($successColor)
        $sb.Append("Select a task to start timer:")
        $sb.Append($reset)
        $y += 2

        # Column headers
        $headerY = $y
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($mutedColor)
        $sb.Append("PRI ")
        $sb.Append("ID   ")
        $sb.Append("TASK")
        $sb.Append($reset)
        $y++

        # Render task rows
        $startY = $y
        $maxLines = $contentRect.Height - 6

        for ($i = 0; $i -lt [Math]::Min($this.Tasks.Count, $maxLines); $i++) {
            $task = $this.Tasks[$i]
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

            $x = $contentRect.X + 4

            # Priority column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($task.priority -gt 0) {
                if ($isSelected) {
                    $sb.Append($selectedBg)
                    $sb.Append($priorityColor)
                } else {
                    $sb.Append($priorityColor)
                }
                $sb.Append("P$($task.priority)".PadRight(4))
                $sb.Append($reset)
            } else {
                if ($isSelected) {
                    $sb.Append($selectedBg)
                    $sb.Append($selectedFg)
                }
                $sb.Append("    ")
                if ($isSelected) {
                    $sb.Append($reset)
                }
            }
            $x += 4

            # ID column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($mutedColor)
            }
            $sb.Append("#$($task.id)".PadRight(5))
            $sb.Append($reset)
            $x += 5

            # Task text
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $textWidth = $contentRect.Width - 15
            $taskText = $task.text
            if ($taskText.Length -gt $textWidth) {
                $taskText = $taskText.Substring(0, $textWidth - 3) + "..."
            }

            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }
            $sb.Append($taskText)
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Check if timer is running
        if ($this.TimerStatus -and $this.TimerStatus.Running) {
            # No navigation, just exit
            return $false
        }

        $keyChar = [char]::ToLower($keyInfo.KeyChar)
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
            'Enter' {
                $this._StartTimer()
                return $true
            }
        }

        switch ($keyChar) {
            's' {
                $this._StartTimer()
                return $true
            }
        }

        return $false
    }

    hidden [void] _StartTimer() {
        # Check if timer is already running
        if ($this.TimerStatus -and $this.TimerStatus.Running) {
            $this.ShowError("Timer is already running! Stop it first.")
            return
        }

        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Tasks.Count) {
            $this.ShowError("No task selected")
            return
        }

        $task = $this.Tasks[$this.SelectedIndex]

        try {
            # Start timer using PMC function
            Start-PmcTimer -TaskId $task.id -Project $task.project

            $this.ShowSuccess("Timer started for task #$($task.id)")

            # Return to previous screen
            $global:PmcApp.PopScreen()
        } catch {
            $this.ShowError("Error starting timer: $_")
        }
    }

    hidden [void] _Cancel() {
        $this.ShowStatus("Timer start cancelled")
        $global:PmcApp.PopScreen()
    }
}

# Entry point function for compatibility
function Show-TimerStartScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [TimerStartScreen]::new()
    $App.PushScreen($screen)
}
