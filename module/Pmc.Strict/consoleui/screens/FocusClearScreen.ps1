using namespace System.Collections.Generic
using namespace System.Text

# FocusClearScreen - Clear focus confirmation
# Shows current focus and asks for confirmation to clear


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Focus clear confirmation screen

.DESCRIPTION
Shows the current focus and prompts for confirmation to clear it.
The focus is reset to 'inbox' when cleared.
Supports:
- Y to confirm clear
- N/Esc to cancel
#>
class FocusClearScreen : PmcScreen {
    # Data
    [string]$CurrentFocus = ""
    [string]$InputBuffer = ""
    [bool]$InConfirm = $false

    # Constructor
    FocusClearScreen() : base("FocusClear", "Clear Focus") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Focus", "Clear"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Y", "Confirm")
        $this.Footer.AddShortcut("N/Esc", "Cancel")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    [void] LoadData() {
        $this.ShowStatus("Loading focus...")

        try {
            # Get PMC data
            $data = Get-PmcAllData

            # Get current focus
            $this.CurrentFocus = if ($data.PSObject.Properties['currentContext']) {
                $data.currentContext
            } else {
                'inbox'
            }

            if ($this.CurrentFocus -eq 'inbox') {
                $this.ShowStatus("No focus set")
            } else {
                $this.ShowStatus("Focus: $($this.CurrentFocus)")
            }

        } catch {
            $this.ShowError("Failed to load focus: $_")
            $this.CurrentFocus = ""
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
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        # Center content vertically
        $startY = $contentRect.Y + [Math]::Floor($contentRect.Height / 3)

        # Show current focus
        $y = $startY
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($textColor)
        $sb.Append("Current focus: ")
        $sb.Append($highlightColor)
        $sb.Append($this.CurrentFocus)
        $sb.Append($reset)
        $y += 3

        # Show confirmation prompt
        if ($this.CurrentFocus -eq 'inbox') {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("No focus is currently set.")
            $sb.Append($reset)
            $y += 2
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("Press Esc to return")
            $sb.Append($reset)
        } else {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($warningColor)
            $sb.Append("Clear this focus and return to 'inbox'?")
            $sb.Append($reset)
            $y += 3

            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($textColor)
            $sb.Append("Press Y to confirm, N or Esc to cancel")
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        $keyChar = [char]::ToLower($keyInfo.KeyChar)
        switch ($keyChar) {
            'y' {
                if ($this.CurrentFocus -ne 'inbox') {
                    $this._ClearFocus()
                }
                return $true
            }
            'n' {
                $this.ShowStatus("Cancelled")
                Start-Sleep -Milliseconds 300
                $this.RequestExit()
                return $true
            }
        }

        return $false
    }

    hidden [void] _ClearFocus() {
        try {
            $data = Get-PmcAllData

            # Clear focus (set to inbox)
            if (-not $data.PSObject.Properties['currentContext']) {
                $data | Add-Member -NotePropertyName currentContext -NotePropertyValue 'inbox' -Force
            } else {
                $data.currentContext = 'inbox'
            }

            Save-PmcData -Data $data -Action "Cleared focus"

            $this.ShowSuccess("Focus cleared")

            # Exit screen
            Start-Sleep -Milliseconds 500
            $this.RequestExit()

        } catch {
            $this.ShowError("Failed to clear focus: $_")
        }
    }
}

# Entry point function for compatibility
function Show-FocusClearScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [FocusClearScreen]::new()
    $App.PushScreen($screen)
}
