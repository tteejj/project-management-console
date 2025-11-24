using namespace System.Collections.Generic
using namespace System.Text

# TimerStatusScreen - View timer status
# Shows current timer status: running/stopped, task, elapsed time


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Timer status display screen

.DESCRIPTION
Shows current timer status.
Supports:
- Viewing timer status (running/stopped)
- Viewing elapsed time
- Stopping timer if running (S key)
- Exiting (Esc key)
#>
class TimerStatusScreen : PmcScreen {
    # Data
    [object]$TimerStatus = $null

    # Legacy constructor (backward compatible)
    TimerStatusScreen() : base("TimerStatus", "Timer Status") {
        $this._InitializeScreen()
    }

    # Container constructor
    TimerStatusScreen([object]$container) : base("TimerStatus", "Timer Status", $container) {
        $this._InitializeScreen()
    }

    hidden [void] _InitializeScreen() {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Timer", "Status"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("S", "Stop Timer")
        $this.Footer.AddShortcut("Esc", "Back")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    [void] LoadData() {
        $this.ShowStatus("Loading timer status...")

        try {
            $this.TimerStatus = Get-PmcTimerStatus

            if ($this.TimerStatus.Running) {
                $this.ShowStatus("Timer is running")
            } else {
                $this.ShowStatus("Timer is not running")
            }
        } catch {
            $this.ShowError("Failed to load timer status: $_")
            $this.TimerStatus = $null
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
        $textColor = $this.Header.GetThemedFg('Foreground.Field')
        $highlightColor = $this.Header.GetThemedFg('Foreground.FieldFocused')
        $successColor = $this.Header.GetThemedFg('Foreground.Success')
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedFg('Foreground.Muted')
        $reset = "`e[0m"

        $y = $contentRect.Y + 2
        $x = $contentRect.X + 4

        # Title
        $title = " Timer Status "
        $titleX = $contentRect.X + [Math]::Floor(($contentRect.Width - $title.Length) / 2)
        $sb.Append($this.Header.BuildMoveTo($titleX, $y))
        $sb.Append($highlightColor)
        $sb.Append($title)
        $sb.Append($reset)
        $y += 2

        if ($null -eq $this.TimerStatus) {
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($warningColor)
            $sb.Append("Error loading timer status")
            $sb.Append($reset)
        } elseif ($this.TimerStatus.Running) {
            # Show timer is running
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($successColor)
            $sb.Append("Timer is RUNNING")
            $sb.Append($reset)
            $y += 2

            # Show details
            $sb.Append($this.Header.BuildMoveTo($x, $y++))
            $sb.Append($textColor)
            $sb.Append("Started: $($this.TimerStatus.StartTime)")
            $sb.Append($reset)

            $sb.Append($this.Header.BuildMoveTo($x, $y++))
            $sb.Append($textColor)
            $sb.Append("Elapsed: $($this.TimerStatus.Elapsed)h")
            $sb.Append($reset)

            if ($this.TimerStatus.Task) {
                $y++
                $sb.Append($this.Header.BuildMoveTo($x, $y++))
                $sb.Append($textColor)
                $sb.Append("Task: $($this.TimerStatus.Task)")
                $sb.Append($reset)
            }

            if ($this.TimerStatus.Project) {
                $sb.Append($this.Header.BuildMoveTo($x, $y++))
                $sb.Append($textColor)
                $sb.Append("Project: $($this.TimerStatus.Project)")
                $sb.Append($reset)
            }

            $y += 2
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($mutedColor)
            $sb.Append("Press 'S' to stop timer")
            $sb.Append($reset)
        } else {
            # Timer not running
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($warningColor)
            $sb.Append("Timer is not running")
            $sb.Append($reset)

            if ($this.TimerStatus.LastElapsed) {
                $y += 2
                $sb.Append($this.Header.BuildMoveTo($x, $y))
                $sb.Append($mutedColor)
                $sb.Append("Last session: $($this.TimerStatus.LastElapsed)h")
                $sb.Append($reset)
            }
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        $keyChar = [char]::ToLower($keyInfo.KeyChar)
        switch ($keyInfo.Key) {
            'Escape' {
                $this.App.PopScreen()
                return $true
            }
        }

        switch ($keyChar) {
            's' {
                if ($this.TimerStatus -and $this.TimerStatus.Running) {
                    try {
                        Stop-PmcTimer
                        $this.ShowSuccess("Timer stopped")
                        $this.LoadData()
                        return $true
                    } catch {
                        $this.ShowError("Failed to stop timer: $_")
                    }
                }
            }
        }

        return $false
    }
}

# Entry point function for compatibility
function Show-TimerStatusScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [TimerStatusScreen]::new()
    $App.PushScreen($screen)
}
