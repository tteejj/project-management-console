using namespace System.Collections.Generic
using namespace System.Text

# UndoViewScreen - Undo last action
# Shows last action details and allows undoing

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Undo last action screen

.DESCRIPTION
Shows last action details.
Supports:
- Viewing last action
- Confirming undo (U key)
- Canceling (Esc key)
#>
class UndoViewScreen : PmcScreen {
    # Data
    [object]$UndoStatus = $null

    # Constructor
    UndoViewScreen() : base("UndoView", "Undo Last Action") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Undo"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("U", "Undo")
        $this.Footer.AddShortcut("Esc", "Cancel")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    [void] LoadData() {
        $this.ShowStatus("Loading undo status...")

        try {
            $this.UndoStatus = Get-PmcUndoStatus

            if ($this.UndoStatus.UndoAvailable) {
                $this.ShowStatus("Press U to undo last action")
            } else {
                $this.ShowStatus("No changes available to undo")
            }
        } catch {
            $this.ShowError("Failed to load undo status: $_")
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
        $title = " Undo Last Change "
        $titleX = $contentRect.X + [Math]::Floor(($contentRect.Width - $title.Length) / 2)
        $sb.Append($this.Header.BuildMoveTo($titleX, $y))
        $sb.Append($highlightColor)
        $sb.Append($title)
        $sb.Append($reset)
        $y += 2

        if ($null -eq $this.UndoStatus) {
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($warningColor)
            $sb.Append("Error loading undo status")
            $sb.Append($reset)
        } elseif ($this.UndoStatus.UndoAvailable) {
            # Show undo stack info
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($successColor)
            $sb.Append("Undo stack has $($this.UndoStatus.UndoCount) change(s) available")
            $sb.Append($reset)
            $y += 2

            # Show last action
            $sb.Append($this.Header.BuildMoveTo($x, $y++))
            $sb.Append($textColor)
            $sb.Append("Last action: $($this.UndoStatus.LastAction)")
            $sb.Append($reset)

            $y += 2
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($warningColor)
            $sb.Append("Press 'U' to undo the last change")
            $sb.Append($reset)
        } else {
            # No undo available
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($warningColor)
            $sb.Append("No changes available to undo")
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'U' {
                if ($this.UndoStatus -and $this.UndoStatus.UndoAvailable) {
                    $this._PerformUndo()
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

    hidden [void] _PerformUndo() {
        try {
            Invoke-PmcUndo
            $this.ShowSuccess("Undo successful")
            $this.App.PopScreen()
        } catch {
            $this.ShowError("Failed to undo: $_")
        }
    }
}

# Entry point function for compatibility
function Show-UndoViewScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [UndoViewScreen]::new()
    $App.PushScreen($screen)
}
