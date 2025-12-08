using namespace System.Collections.Generic
using namespace System.Text

# FocusSetFormScreen - Set project focus
# Shows project list, user selects project to focus on


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Focus context selection screen

.DESCRIPTION
Shows list of available projects and allows user to select
one as the current focus context. The selected project is
saved to focus.txt file.
Supports:
- Project list display
- Enter to select
- Esc to cancel
#>
class FocusSetFormScreen : PmcScreen {
    # Data
    [array]$Projects = @()
    [int]$SelectedIndex = 0
    [string]$CurrentFocus = ""

    # Backward compatible constructor
    FocusSetFormScreen() : base("FocusSetForm", "Set Focus") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Focus", "Set"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "Set Focus")
        $this.Footer.AddShortcut("Esc", "Cancel")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    # Container constructor
    FocusSetFormScreen([object]$container) : base("FocusSetForm", "Set Focus", $container) {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Focus", "Set"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "Set Focus")
        $this.Footer.AddShortcut("Esc", "Cancel")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    [void] LoadData() {
        $this.ShowStatus("Loading projects...")

        try {
            # Get PMC data
            $data = Get-PmcData

            # Get current focus
            $this.CurrentFocus = $(if ($data.PSObject.Properties['currentContext']) {
                $data.currentContext
            } else {
                'inbox'
            })

            # Get project list
            $this.Projects = @('inbox') + @(
                $data.projects | ForEach-Object {
                    if ($_ -is [string]) { $_ }
                    elseif ($_.PSObject.Properties['name']) { $_.name }
                } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object
            )

            # Set selected to current focus
            $idx = [Array]::IndexOf($this.Projects, $this.CurrentFocus)
            if ($idx -ge 0) {
                $this.SelectedIndex = $idx
            }

            $this.ShowStatus("$($this.Projects.Count) projects available")

        } catch {
            $this.ShowError("Failed to load projects: $_")
            $this.Projects = @()
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
        $selectedBg = $this.Header.GetThemedBg('Background.FieldFocused', 80, 0)
        $selectedFg = $this.Header.GetThemedFg('Foreground.Field')
        $cursorColor = $this.Header.GetThemedFg('Foreground.FieldFocused')
        $mutedColor = $this.Header.GetThemedFg('Foreground.Muted')
        $reset = "`e[0m"

        # Title
        $y = $contentRect.Y
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($textColor)
        $sb.Append("Select a project to focus on:")
        $sb.Append($reset)
        $y += 2

        # Show current focus
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($mutedColor)
        $sb.Append("Current focus: ")
        $sb.Append($textColor)
        $sb.Append($this.CurrentFocus)
        $sb.Append($reset)
        $y += 3

        # Render project list
        $maxLines = $contentRect.Height - 6
        for ($i = 0; $i -lt [Math]::Min($this.Projects.Count, $maxLines); $i++) {
            $project = $this.Projects[$i]
            $isSelected = ($i -eq $this.SelectedIndex)

            # Cursor
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y + $i))
            if ($isSelected) {
                $sb.Append($cursorColor)
                $sb.Append(">")
                $sb.Append($reset)
            } else {
                $sb.Append(" ")
            }

            # Project name
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y + $i))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }
            $sb.Append($project)
            $sb.Append($reset)

            # Mark current focus
            if ($project -eq $this.CurrentFocus) {
                $sb.Append(" ")
                $sb.Append($mutedColor)
                $sb.Append("(current)")
                $sb.Append($reset)
            }
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # CRITICAL: Call parent FIRST for MenuBar, F10, Alt+keys, content widgets
        $handled = ([PmcScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.Projects.Count - 1)) {
                    $this.SelectedIndex++
                    return $true
                }
            }
            'Enter' {
                $this._SetFocus()
                return $true
            }
        }

        return $false
    }

    hidden [void] _SetFocus() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Projects.Count) {
            return
        }

        $selectedProject = $this.Projects[$this.SelectedIndex]

        try {
            $data = Get-PmcData

            # Set focus
            if (-not $data.PSObject.Properties['currentContext']) {
                $data | Add-Member -NotePropertyName currentContext -NotePropertyValue $selectedProject -Force
            } else {
                $data.currentContext = $selectedProject
            }

            Save-PmcData -Data $data -Action "Set focus to $selectedProject"

            $this.ShowSuccess("Focus set to: $selectedProject")

            # Exit screen
            Start-Sleep -Milliseconds 500
            $this.RequestDoExit()

        } catch {
            $this.ShowError("Failed to set focus: $_")
        }
    }
}

# Entry point function for compatibility
function Show-FocusSetFormScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = New-Object FocusSetFormScreen
    $App.PushScreen($screen)
}