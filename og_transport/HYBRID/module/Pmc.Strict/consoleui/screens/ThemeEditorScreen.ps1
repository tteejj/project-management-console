using namespace System.Collections.Generic
using namespace System.Text

# ThemeEditorScreen - Theme selection and preview
# Allows users to view available themes and apply them


Set-StrictMode -Version Latest

# NOTE: PmcScreen is loaded by Start-PmcTUI.ps1 - don't load again
# . "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Theme editor screen for selecting and applying color themes

.DESCRIPTION
Shows available color themes with previews.
Supports:
- Viewing theme list with color previews
- Testing themes before applying
- Applying selected theme
- Navigation (Up/Down arrows)
#>
class ThemeEditorScreen : PmcScreen {
    # Data
    [array]$Themes = @()
    [int]$SelectedIndex = 0
    [string]$CurrentTheme = "Default"

    # Constructor
    ThemeEditorScreen() : base("ThemeEditor", "Theme Editor") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Options", "Themes"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "Apply")
        $this.Footer.AddShortcut("T", "Test")
        $this.Footer.AddShortcut("Esc", "Back")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via static RegisterMenuItems() or manifest
        # Old pattern was adding duplicate/misplaced menu items AND breaking constructor
    }

    # Constructor with container (DI-enabled)
    ThemeEditorScreen([object]$container) : base("ThemeEditor", "Theme Editor", $container) {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Options", "Themes"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "Apply")
        $this.Footer.AddShortcut("T", "Test")
        $this.Footer.AddShortcut("Esc", "Back")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via static RegisterMenuItems() or manifest
        # Old pattern was adding duplicate/misplaced menu items AND breaking constructor
    }

    [void] LoadData() {
        $this.ShowStatus("Loading themes...")

        try {
            # Define available themes (using PMC theme system hex colors)
            $this.Themes = @(
                @{
                    Name = "Default"
                    Hex = "#33aaff"
                    Description = "Classic blue"
                }
                @{
                    Name = "Ocean"
                    Hex = "#33aaff"
                    Description = "Cool ocean blue"
                }
                @{
                    Name = "Lime"
                    Hex = "#33cc66"
                    Description = "Fresh lime green"
                }
                @{
                    Name = "Purple"
                    Hex = "#9966ff"
                    Description = "Vibrant purple"
                }
                @{
                    Name = "Slate"
                    Hex = "#8899aa"
                    Description = "Cool blue-gray"
                }
                @{
                    Name = "Forest"
                    Hex = "#228844"
                    Description = "Deep forest green"
                }
                @{
                    Name = "Sunset"
                    Hex = "#ff8833"
                    Description = "Warm sunset orange"
                }
                @{
                    Name = "Rose"
                    Hex = "#ff6699"
                    Description = "Soft rose pink"
                }
                @{
                    Name = "Sky"
                    Hex = "#66ccff"
                    Description = "Bright sky blue"
                }
                @{
                    Name = "Gold"
                    Hex = "#ffaa33"
                    Description = "Rich golden yellow"
                }
            )

            # Get current theme from config
            try {
                $cfg = Get-PmcConfig
                $currentHex = $null

                # Safely check for Display.Theme.Hex
                if ((Get-Member -InputObject $cfg -Name Display -MemberType Properties) -and
                    $cfg.Display -and
                    (Get-Member -InputObject $cfg.Display -Name Theme -MemberType Properties) -and
                    $cfg.Display.Theme -and
                    (Get-Member -InputObject $cfg.Display.Theme -Name Hex -MemberType Properties)) {
                    $currentHex = $cfg.Display.Theme.Hex
                }

                # Find theme by hex
                if ($currentHex) {
                    foreach ($theme in $this.Themes) {
                        if ($theme.Hex -eq $currentHex) {
                            $this.CurrentTheme = $theme.Name
                            break
                        }
                    }
                } else {
                    $this.CurrentTheme = "Default"
                }
            } catch {
                $this.CurrentTheme = "Default"
            }

            # Success message
            $count = $(if ($this.Themes) { $this.Themes.Count } else { 0 })
            $this.ShowSuccess("$count themes available")

        } catch {
            $this.ShowError("Failed to load themes: $_")
            $this.Themes = @()
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
        $textColor = $this.Header.GetThemedFg('Foreground.Field')
        $selectedBg = $this.Header.GetThemedBg('Background.FieldFocused', 80, 0)
        $selectedFg = $this.Header.GetThemedFg('Foreground.Field')
        $cursorColor = $this.Header.GetThemedFg('Foreground.FieldFocused')
        $mutedColor = $this.Header.GetThemedFg('Foreground.Muted')
        $headerColor = $this.Header.GetThemedFg('Foreground.Muted')
        $reset = "`e[0m"

        # Render column headers
        $headerY = $this.Header.Y + 3
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($headerColor)
        $sb.Append("THEME NAME")
        $sb.Append("     ")
        $sb.Append("DESCRIPTION")
        $sb.Append("                    ")
        $sb.Append("STATUS")
        $sb.Append($reset)

        # Render theme list
        $startY = $headerY + 2
        $maxLines = $contentRect.Height - 4

        for ($i = 0; $i -lt [Math]::Min($this.Themes.Count, $maxLines); $i++) {
            $theme = $this.Themes[$i]
            $y = $startY + $i
            $isSelected = ($i -eq $this.SelectedIndex)
            $isCurrent = ($theme.Name -eq $this.CurrentTheme)

            # Cursor
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
            if ($isSelected) {
                $sb.Append($cursorColor)
                $sb.Append(">")
                $sb.Append($reset)
            } else {
                $sb.Append(" ")
            }

            # Theme name
            $x = $contentRect.X + 4
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }
            $sb.Append($theme.Name.PadRight(15))
            $sb.Append($reset)

            # Description
            $x += 15
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($mutedColor)
            }
            $sb.Append($theme.Description.PadRight(30))
            $sb.Append($reset)

            # Current indicator
            $x += 30
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isCurrent) {
                $successColor = $this.Header.GetThemedFg('Foreground.Success')
                $sb.Append($successColor)
                $sb.Append("[CURRENT]")
                $sb.Append($reset)
            }
        }

        # Show color preview for selected theme
        if ($this.SelectedIndex -ge 0 -and $this.SelectedIndex -lt $this.Themes.Count) {
            $theme = $this.Themes[$this.SelectedIndex]
            $previewY = $startY + $this.Themes.Count + 2

            if ($previewY -lt $contentRect.Y + $contentRect.Height - 2) {
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $previewY))
                $sb.Append($headerColor)
                $sb.Append("━" * 40)
                $sb.Append($reset)

                $previewY++
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $previewY))
                $sb.Append($textColor)
                $sb.Append("Selected: ")
                $sb.Append($this.Header.GetThemedFg('Foreground.FieldFocused'))
                $sb.Append($theme.Name)
                $sb.Append($reset)

                $previewY++
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $previewY))
                $sb.Append($mutedColor)
                $sb.Append("Hex Code: ")
                $sb.Append($this.Header.GetThemedFg('Foreground.Success'))
                $sb.Append($theme.Hex)
                $sb.Append($reset)

                $previewY++
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $previewY))
                $sb.Append($mutedColor)
                $sb.Append("Description: ")
                $sb.Append($textColor)
                $sb.Append($theme.Description)
                $sb.Append($reset)

                $previewY += 2
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $previewY))
                $sb.Append($headerColor)
                $sb.Append("Press Enter to apply, T to test, Esc to cancel")
                $sb.Append($reset)
            }
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # CRITICAL: Call parent FIRST for MenuBar, F10, Alt+keys
        $handled = ([PmcScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        # Custom key handling
        $keyChar = [char]::ToLower($keyInfo.KeyChar)
        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.Themes.Count - 1)) {
                    $this.SelectedIndex++
                    return $true
                }
            }
            'Enter' {
                $this._ApplyTheme()
                return $true
            }
            'Escape' {
                if ($global:PmcApp) {
                    $global:PmcApp.PopScreen()
                }
                return $true
            }
        }

        switch ($keyChar) {
            't' {
                $this._TestTheme()
                return $true
            }
        }

        return $false
    }

    hidden [void] _ApplyTheme() {
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Called, SelectedIndex=$($this.SelectedIndex)"
        }

        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Themes.Count) {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Invalid index, returning"
            }
            return
        }

        $theme = $this.Themes[$this.SelectedIndex]
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Applying $($theme.Name) with hex $($theme.Hex)"
        }

        try {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Updating theme to $($theme.Hex)..."
            }

            # Use PmcThemeManager to set theme (handles config and state)
            $themeManager = [PmcThemeManager]::GetInstance()
            $themeManager.SetTheme($theme.Hex)

            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Theme config saved"
            }

            # Update current theme marker
            $this.CurrentTheme = $theme.Name

            # HOT RELOAD: Apply theme immediately without restarting or changing screens
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Invoking hot reload..."
            }

            $reloadSuccess = Invoke-ThemeHotReload $theme.Hex

            if ($reloadSuccess) {
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Hot reload SUCCESS - theme applied instantly"
                }
                try {
                    $this.ShowSuccess("Theme applied! Changes visible immediately.")
                } catch {
                    # ShowSuccess may fail
                }
            } else {
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Hot reload FAILED - falling back to screen pop"
                }
                # Fallback: pop screen if hot reload fails
                Start-Sleep -Milliseconds 800
                if ($global:PmcApp) {
                    $global:PmcApp.RenderEngine.RequestClear()
                    $global:PmcApp.PopScreen()
                }
            }
        } catch {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: ERROR: $_"
            }
            try {
                $this.ShowError("Failed to apply theme: $_")
            } catch {
                # ShowError may fail
            }
        }
    }

    hidden [void] _TestTheme() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Themes.Count) {
            return
        }

        $theme = $this.Themes[$this.SelectedIndex]
        $this.ShowStatus("Testing theme: $($theme.Name) - Press any key to return")
        # In a real implementation, would temporarily apply theme
    }

    hidden [void] _ResetTheme() {
        $this.CurrentTheme = "Default"
        $this.SelectedIndex = 0
        $this.ShowSuccess("Reset to default theme")
    }
}

# Entry point function for compatibility
function Show-ThemeEditorScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = New-Object ThemeEditorScreen
    $App.PushScreen($screen)
}