using namespace System.Collections.Generic
using namespace System.Text

# FocusStatusScreen - Show focus status
# Displays current focused project with task statistics


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Focus status display screen

.DESCRIPTION
Shows the current focused project or "No focus set".
Displays task count statistics for the focused project:
- Total active tasks
- Overdue tasks (if any)
Supports:
- Esc to exit
#>
class FocusStatusScreen : PmcScreen {
    # Data
    [string]$CurrentFocus = ""
    [int]$ActiveTaskCount = 0
    [int]$OverdueTaskCount = 0

    # Constructor
    FocusStatusScreen() : base("FocusStatus", "Focus Status") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Focus", "Status"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Esc", "Exit")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    # Constructor with container
    FocusStatusScreen([object]$container) : base("FocusStatus", "Focus Status", $container) {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Focus", "Status"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Esc", "Exit")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    [void] LoadData() {
        $this.ShowStatus("Loading focus status...")

        try {
            # Get PMC data
            $data = Get-PmcData

            # Get current focus
            $this.CurrentFocus = if ($data.PSObject.Properties['currentContext']) {
                $data.currentContext
            } else {
                'inbox'
            }

            # Count tasks if focus is set
            if ($this.CurrentFocus -and $this.CurrentFocus -ne 'inbox') {
                # Count active tasks
                $contextTasks = @($data.tasks | Where-Object {
                    $_.project -eq $this.CurrentFocus -and -not $_.completed
                })
                $this.ActiveTaskCount = $contextTasks.Count

                # Count overdue tasks
                $today = (Get-Date).Date
                $this.OverdueTaskCount = @($contextTasks | Where-Object {
                    if (-not $_.due) { return $false }
                    try {
                        $dueDate = [DateTime]::Parse($_.due)
                        return ($dueDate.Date -lt $today)
                    } catch {
                        return $false
                    }
                }).Count
            } else {
                $this.ActiveTaskCount = 0
                $this.OverdueTaskCount = 0
            }

            $this.ShowStatus("Focus: $($this.CurrentFocus)")

        } catch {
            $this.ShowError("Failed to load focus status: $_")
            $this.CurrentFocus = ""
            $this.ActiveTaskCount = 0
            $this.OverdueTaskCount = 0
        }
    }

    [string] RenderContent() {
        $sb = [System.Text.StringBuilder]::new(1024)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $highlightColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $successColor = $this.Header.GetThemedAnsi('Success', $false)
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        # Center content vertically
        $startY = $contentRect.Y + [Math]::Floor($contentRect.Height / 3)

        # Show current focus
        $y = $startY
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($mutedColor)
        $sb.Append("Current Focus:")
        $sb.Append($reset)
        $y++

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($highlightColor)
        if ($this.CurrentFocus -eq 'inbox' -or -not $this.CurrentFocus) {
            $sb.Append("No focus set")
        } else {
            $sb.Append($this.CurrentFocus)
        }
        $sb.Append($reset)
        $y += 3

        # Show task statistics if focus is set
        if ($this.CurrentFocus -and $this.CurrentFocus -ne 'inbox') {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("Active Tasks:")
            $sb.Append($reset)
            $sb.Append(" ")
            $sb.Append($textColor)
            $sb.Append($this.ActiveTaskCount)
            $sb.Append($reset)
            $y += 2

            # Show overdue count if any
            if ($this.OverdueTaskCount -gt 0) {
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
                $sb.Append($warningColor)
                $sb.Append("Overdue:")
                $sb.Append($reset)
                $sb.Append(" ")
                $sb.Append($warningColor)
                $sb.Append($this.OverdueTaskCount)
                $sb.Append($reset)
                $y += 2
            }
        }

        # Show hint
        $y += 2
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($mutedColor)
        $sb.Append("Press Esc to exit")
        $sb.Append($reset)

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # No special input handling needed
        # Esc is handled by base class
        return $false
    }
}

# Entry point function for compatibility
function Show-FocusStatusScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [FocusStatusScreen]::new()
    $App.PushScreen($screen)
}
