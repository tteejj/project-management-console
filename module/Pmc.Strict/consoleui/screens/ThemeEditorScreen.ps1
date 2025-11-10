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

        # Setup menu items
        $this._SetupMenus()
    }

    hidden [void] _SetupMenus() {
        # Capture $this in a variable so scriptblocks can access it
        $screen = $this

        # Tasks menu - Navigate to different task views
        $tasksMenu = $this.MenuBar.Menus[0]
        $tasksMenu.Items.Add([PmcMenuItem]::new("Task List", 'L', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen((New-Object TaskListScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Today", 'Y', {
            . "$PSScriptRoot/TodayViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object TodayViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Tomorrow", 'T', {
            . "$PSScriptRoot/TomorrowViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object TomorrowViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Week View", 'W', {
            . "$PSScriptRoot/WeekViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object WeekViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Upcoming", 'U', {
            . "$PSScriptRoot/UpcomingViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object UpcomingViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Overdue", 'V', {
            . "$PSScriptRoot/OverdueViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object OverdueViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Next Actions", 'N', {
            . "$PSScriptRoot/NextActionsViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object NextActionsViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("No Due Date", 'D', {
            . "$PSScriptRoot/NoDueDateViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object NoDueDateViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Blocked Tasks", 'B', {
            . "$PSScriptRoot/BlockedTasksScreen.ps1"
            $global:PmcApp.PushScreen((New-Object BlockedTasksScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::Separator())
        $tasksMenu.Items.Add([PmcMenuItem]::new("Kanban Board", 'K', {
            . "$PSScriptRoot/KanbanScreen.ps1"
            $global:PmcApp.PushScreen((New-Object KanbanScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', {
            . "$PSScriptRoot/MonthViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object MonthViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Agenda View", 'A', {
            . "$PSScriptRoot/AgendaViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object AgendaViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Burndown Chart", 'C', {
            . "$PSScriptRoot/BurndownChartScreen.ps1"
            $global:PmcApp.PushScreen((New-Object BurndownChartScreen))
        }))

        # Projects menu
        $projectsMenu = $this.MenuBar.Menus[1]
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project List", 'L', {
            . "$PSScriptRoot/ProjectListScreen.ps1"
            $global:PmcApp.PushScreen((New-Object ProjectListScreen))
        }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Stats", 'S', {
            . "$PSScriptRoot/ProjectStatsScreen.ps1"
            $global:PmcApp.PushScreen((New-Object ProjectStatsScreen))
        }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Info", 'I', {
            . "$PSScriptRoot/ProjectInfoScreen.ps1"
            $global:PmcApp.PushScreen((New-Object ProjectInfoScreen))
        }))

        # Options menu
        $optionsMenu = $this.MenuBar.Menus[2]
        $optionsMenu.Items.Add([PmcMenuItem]::new("Theme Editor", 'T', {
            . "$PSScriptRoot/ThemeEditorScreen.ps1"
            $global:PmcApp.PushScreen((New-Object ThemeEditorScreen))
        }))
        $optionsMenu.Items.Add([PmcMenuItem]::new("Settings", 'S', {
            . "$PSScriptRoot/SettingsScreen.ps1"
            $global:PmcApp.PushScreen((New-Object SettingsScreen))
        }))

        # Help menu
        $helpMenu = $this.MenuBar.Menus[3]
        $helpMenu.Items.Add([PmcMenuItem]::new("Help View", 'H', {
            . "$PSScriptRoot/HelpViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object HelpViewScreen))
        }))
        $helpMenu.Items.Add([PmcMenuItem]::new("About", 'A', { Write-Host "PMC TUI v1.0" }))
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

            $this.ShowSuccess("$($this.Themes.Count) themes available")

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
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $selectedBg = $this.Header.GetThemedAnsi('Primary', $true)
        $selectedFg = $this.Header.GetThemedAnsi('Text', $false)
        $cursorColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
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
                $successColor = $this.Header.GetThemedAnsi('Success', $false)
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
                $sb.Append($this.Header.GetThemedAnsi('Highlight', $false))
                $sb.Append($theme.Name)
                $sb.Append($reset)

                $previewY++
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $previewY))
                $sb.Append($mutedColor)
                $sb.Append("Hex Code: ")
                $sb.Append($this.Header.GetThemedAnsi('Success', $false))
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

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
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
            'T' {
                $this._TestTheme()
                return $true
            }
            'Escape' {
                if ($global:PmcApp) {
                    $global:PmcApp.PopScreen()
                }
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
            # Get PMC config and set theme hex
            $cfg = Get-PmcConfig

            # Create Display property if it doesn't exist
            if (-not (Get-Member -InputObject $cfg -Name Display -MemberType Properties)) {
                $cfg | Add-Member -NotePropertyName Display -NotePropertyValue @{} -Force
            }
            if (-not $cfg.Display) {
                $cfg.Display = @{}
            }

            # Create Theme property if it doesn't exist
            if (-not (Get-Member -InputObject $cfg.Display -Name Theme -MemberType Properties)) {
                $cfg.Display | Add-Member -NotePropertyName Theme -NotePropertyValue @{} -Force
            }
            if (-not $cfg.Display.Theme) {
                $cfg.Display.Theme = @{}
            }

            # Set theme properties
            if (-not (Get-Member -InputObject $cfg.Display.Theme -Name Hex -MemberType Properties)) {
                $cfg.Display.Theme | Add-Member -NotePropertyName Hex -NotePropertyValue $theme.Hex -Force
            } else {
                $cfg.Display.Theme.Hex = $theme.Hex
            }

            if (-not (Get-Member -InputObject $cfg.Display.Theme -Name Enabled -MemberType Properties)) {
                $cfg.Display.Theme | Add-Member -NotePropertyName Enabled -NotePropertyValue $true -Force
            } else {
                $cfg.Display.Theme.Enabled = $true
            }

            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Saving config..."
            }

            try {
                Save-PmcConfig $cfg
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Save-PmcConfig completed successfully"
                }
            } catch {
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Save-PmcConfig FAILED: $_"
                }
                throw
            }

            # Update current theme marker
            $this.CurrentTheme = $theme.Name

            # Reinitialize theme system to apply changes
            try {
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Reinitializing theme system..."
                }
                Initialize-PmcThemeSystem
            } catch {
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: Initialize-PmcThemeSystem failed: $_"
                }
            }

            try {
                $this.ShowSuccess("Theme saved! Restart TUI to see changes: Ctrl+Q then run again")
            } catch {
                # ShowSuccess may fail
            }

            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ThemeEditor._ApplyTheme: SUCCESS - Config saved, theme will apply on restart"
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

    $screen = [ThemeEditorScreen]::new()
    $App.PushScreen($screen)
}
