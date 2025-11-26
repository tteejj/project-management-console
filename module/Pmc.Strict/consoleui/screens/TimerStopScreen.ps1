using namespace System.Collections.Generic
using namespace System.Text

# TimerStopScreen - Stop running timer
# Shows current timer info and allows stopping/logging time


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Stop timer screen with confirmation

.DESCRIPTION
Shows current running timer information.
Supports:
- Viewing timer status (running/stopped)
- Stopping timer and logging time (S key)
- Canceling (Esc key)
#>
class TimerStopScreen : PmcScreen {
    # Data
    [object]$TimerStatus = $null
    [bool]$IsConfirming = $false

    # Legacy constructor (backward compatible)
    TimerStopScreen() : base("TimerStop", "Stop Timer") {
        $this._InitializeScreen()
    }

    # Container constructor
    TimerStopScreen([object]$container) : base("TimerStop", "Stop Timer", $container) {
        $this._InitializeScreen()
    }

    hidden [void] _InitializeScreen() {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Timer", "Stop"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("S", "Stop & Log")
        $this.Footer.AddShortcut("Esc", "Cancel")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    [void] LoadData() {
        $this.ShowStatus("Loading timer status...")

        try {
            $this.TimerStatus = Get-PmcTimerStatus

            if ($this.TimerStatus.Running) {
                $this.ShowStatus("Timer is running - Press S to stop and log time")
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
        $title = " Stop Timer "
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
            $sb.Append($warningColor)
            $sb.Append("Press 'S' to stop and log this time")
            $sb.Append($reset)
        } else {
            # Timer not running
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($warningColor)
            $sb.Append("Timer is not running")
            $sb.Append($reset)
            $y += 2

            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($mutedColor)
            $sb.Append("There is nothing to stop.")
            $sb.Append($reset)
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
                    $this._StopTimer()
                    return $true
                }
            }
        }

        return $false
    }

    hidden [void] _StopTimer() {
        try {
            Stop-PmcTimer
            $this.ShowSuccess("Timer stopped and time logged")
            $this.App.PopScreen()
        } catch {
            $this.ShowError("Failed to stop timer: $_")
        }
    }
}

# Entry point function for compatibility
function Show-TimerStopScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = New-Object TimerStopScreen
    $App.PushScreen($screen)
}
