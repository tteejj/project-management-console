using namespace System.Collections.Generic
using namespace System.Text

# RedoViewScreen - Redo last undone action
# Shows last undone action and allows redoing


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Redo last undone action screen

.DESCRIPTION
Shows last undone action details.
Supports:
- Viewing redo stack
- Confirming redo (R key)
- Canceling (Esc key)
#>
class RedoViewScreen : PmcScreen {
    # Data
    [object]$UndoStatus = $null

    # Constructor
    RedoViewScreen() : base("RedoView", "Redo Last Action") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Redo"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("R", "Redo")
        $this.Footer.AddShortcut("Esc", "Cancel")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    [void] LoadData() {
        $this.ShowStatus("Loading redo status...")

        try {
            $this.UndoStatus = Get-PmcUndoStatus

            if ($this.UndoStatus.RedoAvailable) {
                $this.ShowStatus("Press R to redo last undone action")
            } else {
                $this.ShowStatus("No changes available to redo")
            }
        } catch {
            $this.ShowError("Failed to load redo status: $_")
            $this.UndoStatus = $null
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
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $highlightColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $successColor = $this.Header.GetThemedAnsi('Success', $false)
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        $y = $contentRect.Y + 2
        $x = $contentRect.X + 4

        # Title
        $title = " Redo Last Undone Change "
        $titleX = $contentRect.X + [Math]::Floor(($contentRect.Width - $title.Length) / 2)
        $sb.Append($this.Header.BuildMoveTo($titleX, $y))
        $sb.Append($highlightColor)
        $sb.Append($title)
        $sb.Append($reset)
        $y += 2

        if ($null -eq $this.UndoStatus) {
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($warningColor)
            $sb.Append("Error loading redo status")
            $sb.Append($reset)
        } elseif ($this.UndoStatus.RedoAvailable) {
            # Show redo stack info
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($successColor)
            $sb.Append("Redo stack has $($this.UndoStatus.RedoCount) change(s) available")
            $sb.Append($reset)
            $y += 2

            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($warningColor)
            $sb.Append("Press 'R' to redo the last undone change")
            $sb.Append($reset)
        } else {
            # No redo available
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($warningColor)
            $sb.Append("No changes available to redo")
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'R' {
                if ($this.UndoStatus -and $this.UndoStatus.RedoAvailable) {
                    $this._PerformRedo()
                    return $true
                }
            }
            'Escape' {
                $this.App.PopScreen()
                return $true
            }
        }

        return $false
    }

    hidden [void] _PerformRedo() {
        try {
            Invoke-PmcRedo
            $this.ShowSuccess("Redo successful")
            $this.App.PopScreen()
        } catch {
            $this.ShowError("Failed to redo: $_")
        }
    }
}

# Entry point function for compatibility
function Show-RedoViewScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [RedoViewScreen]::new()
    $App.PushScreen($screen)
}
