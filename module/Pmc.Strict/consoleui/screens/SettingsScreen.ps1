using namespace System.Collections.Generic
using namespace System.Text

# SettingsScreen - PMC TUI Settings configuration
# Interactive screen for viewing and modifying PMC settings

. "$PSScriptRoot/../PmcScreen.ps1"

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

    # Constructor
    SettingsScreen() : base("Settings", "Settings") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Settings"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "Edit")
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
        $optionsMenu.Items.Add([PmcMenuItem]::new("Settings", 'S', { $screen.LoadData() }.GetNewClosure()))

        # Help menu
        $helpMenu = $this.MenuBar.Menus[3]
        $helpMenu.Items.Add([PmcMenuItem]::new("Help View", 'H', {
            . "$PSScriptRoot/HelpViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object HelpViewScreen))
        }))
        $helpMenu.Items.Add([PmcMenuItem]::new("About", 'A', { Write-Host "PMC TUI v1.0" }))
    }

    [void] LoadData() {
        # Load current settings
        $this.SettingsList = @(
            @{
                name = "Data File"
                key = "dataFile"
                value = if ($global:PmcDataFile) { $global:PmcDataFile } else { "~/.pmc/data.json" }
                editable = $false
                description = "Location of PMC data storage"
            }
            @{
                name = "Default Project"
                key = "defaultProject"
                value = if ($global:PmcDefaultProject) { $global:PmcDefaultProject } else { "inbox" }
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
                description = "UI color theme (use Theme Editor to change)"
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

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Handle input mode
        if ($this.InputMode -eq 'edit') {
            return $this._HandleEditMode($keyInfo)
        }

        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex > 0) {
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
                if ($this.SettingsList.Count > 0) {
                    $this._StartEdit()
                }
                return $true
            }
        }
        return $false
    }

    hidden [void] _StartEdit() {
        $setting = $this.SettingsList[$this.SelectedIndex]

        if (-not $setting.editable) {
            $this.ShowError("$($setting.name) is read-only")
            return
        }

        $this.InputMode = 'edit'
        $this.EditingIndex = $this.SelectedIndex
        $this.InputBuffer = $setting.value
        $this.ShowStatus("Edit value (Enter: save, Esc: cancel)")
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
                $global:PmcDefaultProject = $newValue
                $this.ShowSuccess("Default project updated to '$newValue'")
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
