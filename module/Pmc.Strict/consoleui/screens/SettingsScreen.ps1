using namespace System.Collections.Generic
using namespace System.Text

# SettingsScreen - PMC TUI Settings configuration
# Interactive screen for viewing and modifying PMC settings


Set-StrictMode -Version Latest

# NOTE: PmcScreen is loaded by Start-PmcTUI.ps1 - don't load again
# . "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Settings screen for configuring PMC TUI preferences

.DESCRIPTION
Interactive settings screen showing:
- Data file location
- Default project
- Theme selection
- Auto-save settings
- Backup settings
Navigation: Up/Down to select, Enter to edit, Esc to exit
#>
class SettingsScreen : PmcScreen {
    # Data
    [array]$SettingsList = @()
    [int]$SelectedIndex = 0
    [string]$InputMode = 'none'  # 'none', 'edit'
    [string]$InputBuffer = ''
    [int]$EditingIndex = -1

    # Static: Register menu items
    static [void] RegisterMenuItems([object]$registry) {
        $registry.AddMenuItem('Options', 'Settings', 'S', {
            . "$PSScriptRoot/SettingsScreen.ps1"
            $global:PmcApp.PushScreen([SettingsScreen]::new())
        }, 20)
    }

    # Constructor
    SettingsScreen() : base("Settings", "Settings") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Settings"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "Edit")
        $this.Footer.AddShortcut("Esc", "Back")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via static RegisterMenuItems()
        # Old pattern was adding duplicate/misplaced menu items
    }

    # Constructor with container (DI-enabled)
    SettingsScreen([object]$container) : base("Settings", "Settings", $container) {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Settings"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "Edit")
        $this.Footer.AddShortcut("Esc", "Back")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via static RegisterMenuItems()
        # Old pattern was adding duplicate/misplaced menu items
    }

    [void] LoadData() {
        # Load current settings
        $dataFile = "~/.pmc/data.json"
        try {
            $dataFile = Get-PmcTaskFilePath
        } catch {
            # Use default if Get-PmcTaskFilePath fails
        }

        $currentContext = "inbox"
        try {
            $currentContext = Get-PmcCurrentContext
        } catch {
            # Use default if Get-PmcCurrentContext fails
        }

        $this.SettingsList = @(
            @{
                name = "Data File"
                key = "dataFile"
                value = $dataFile
                editable = $false
                description = "Location of PMC data storage"
            }
            @{
                name = "Default Project"
                key = "defaultProject"
                value = $currentContext
                editable = $true
                description = "Default project for new tasks"
            }
            @{
                name = "Auto-save"
                key = "autoSave"
                value = "enabled"
                editable = $false
                description = "Automatically save changes"
            }
            @{
                name = "Theme"
                key = "theme"
                value = "default"
                editable = $false
                action = "launchThemeEditor"
                description = "UI color theme (press Enter to change)"
            }
            @{
                name = "TUI Version"
                key = "version"
                value = "1.0.0"
                editable = $false
                description = "PMC TUI version"
            }
        )

        $this.ShowStatus("$($this.SettingsList.Count) settings available")
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
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $selectedBg = $this.Header.GetThemedAnsi('Primary', $true)
        $selectedFg = $this.Header.GetThemedAnsi('Text', $false)
        $cursorColor = $this.Header.GetThemedAnsi('Accent', $false)
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        # Column widths
        $nameWidth = 20
        $valueWidth = 30
        $descWidth = $contentRect.Width - $nameWidth - $valueWidth - 10

        # Render column headers
        $headerY = $this.Header.Y + 3
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($headerColor)
        $sb.Append("SETTING".PadRight($nameWidth))
        $sb.Append("VALUE".PadRight($valueWidth))
        $sb.Append("DESCRIPTION")
        $sb.Append($reset)

        # Render settings rows
        $startY = $headerY + 2
        $maxLines = $contentRect.Height - 4

        for ($i = 0; $i -lt [Math]::Min($this.SettingsList.Count, $maxLines); $i++) {
            $setting = $this.SettingsList[$i]
            $y = $startY + $i
            $isSelected = ($i -eq $this.SelectedIndex)
            $isEditing = ($i -eq $this.EditingIndex) -and ($this.InputMode -eq 'edit')

            # Cursor
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
            if ($isSelected) {
                $sb.Append($cursorColor)
                $cursorChar = if ($isEditing) { "E" } else { ">" }
                $sb.Append($cursorChar)
                $sb.Append($reset)
            } else {
                $sb.Append(" ")
            }

            # Setting name column
            $x = $contentRect.X + 4
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected -and -not $isEditing) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }
            $displayName = $setting.name
            if ($displayName.Length -gt $nameWidth) {
                $displayName = $displayName.Substring(0, $nameWidth - 3) + "..."
            }
            $sb.Append($displayName.PadRight($nameWidth))
            $sb.Append($reset)
            $x += $nameWidth

            # Value column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isEditing) {
                # Show edit buffer
                $sb.Append($cursorColor)
                $sb.Append(($this.InputBuffer + "_").PadRight($valueWidth))
                $sb.Append($reset)
            } else {
                $sb.Append($highlightColor)
                $displayValue = $setting.value
                if ($displayValue.Length -gt $valueWidth) {
                    $displayValue = $displayValue.Substring(0, $valueWidth - 3) + "..."
                }
                $sb.Append($displayValue.PadRight($valueWidth))
                $sb.Append($reset)
            }
            $x += $valueWidth

            # Description column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($mutedColor)
            $displayDesc = $setting.description
            if ($displayDesc.Length -gt $descWidth) {
                $displayDesc = $displayDesc.Substring(0, $descWidth - 3) + "..."
            }
            $sb.Append($displayDesc)
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        # Handle input mode
        if ($this.InputMode -eq 'edit') {
            return $this._HandleEditMode($keyInfo)
        }

        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                }
                return $true
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.SettingsList.Count - 1)) {
                    $this.SelectedIndex++
                }
                return $true
            }
            'Enter' {
                if ($this.SettingsList.Count -gt 0) {
                    $this._StartEdit()
                }
                return $true
            }
            'Escape' {
                # Go back to previous screen
                if ($global:PmcApp) {
                    $global:PmcApp.PopScreen()
                }
                return $true
            }
        }
        return $false
    }

    hidden [void] _StartEdit() {
        $setting = $this.SettingsList[$this.SelectedIndex]

        # Check if this setting has a special action
        if ($setting.action) {
            switch ($setting.action) {
                'launchThemeEditor' {
                    # Lazy-load Theme Editor screen
                    . "$PSScriptRoot/ThemeEditorScreen.ps1"
                    if ($global:PmcApp) {
                        $themeScreen = New-Object ThemeEditorScreen
                        $global:PmcApp.PushScreen($themeScreen)
                    }
                    return
                }
            }
        }

        if (-not $setting.editable) {
            try { $this.ShowError("$($setting.name) is read-only") } catch { }
            return
        }

        $this.InputMode = 'edit'
        $this.EditingIndex = $this.SelectedIndex
        $this.InputBuffer = $setting.value
        try { $this.ShowStatus("Edit value (Enter: save, Esc: cancel)") } catch { }
    }

    hidden [bool] _HandleEditMode([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'Escape' {
                $this._CancelEdit()
                return $true
            }
            'Enter' {
                $this._SaveEdit()
                return $true
            }
            'Backspace' {
                if ($this.InputBuffer.Length > 0) {
                    $this.InputBuffer = $this.InputBuffer.Substring(0, $this.InputBuffer.Length - 1)
                }
                return $true
            }
            default {
                if ($keyInfo.KeyChar -ge 32 -and $keyInfo.KeyChar -le 126) {
                    $this.InputBuffer += $keyInfo.KeyChar
                }
                return $true
            }
        }
        return $false  # Fallback return
    }

    hidden [void] _SaveEdit() {
        $setting = $this.SettingsList[$this.EditingIndex]
        $oldValue = $setting.value
        $newValue = $this.InputBuffer

        # Update the setting value
        $setting.value = $newValue

        # Apply the setting based on key
        switch ($setting.key) {
            'defaultProject' {
                try {
                    # Use Set-PmcFocus to change the current context
                    Set-PmcFocus -Project $newValue
                    $this.ShowSuccess("Default project updated to '$newValue'")
                } catch {
                    $this.ShowError("Failed to set default project: $_")
                    # Revert the value
                    $setting.value = $oldValue
                }
            }
            default {
                $this.ShowSuccess("$($setting.name) updated")
            }
        }

        # Reset edit mode
        $this.InputMode = 'none'
        $this.EditingIndex = -1
        $this.InputBuffer = ''
    }

    hidden [void] _CancelEdit() {
        $this.InputMode = 'none'
        $this.EditingIndex = -1
        $this.InputBuffer = ''
        $this.ShowStatus("Edit cancelled")
    }
}
