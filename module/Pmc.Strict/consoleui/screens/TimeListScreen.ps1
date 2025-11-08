using namespace System.Collections.Generic
using namespace System.Text

# TimeListScreen - Time log entries list
# Shows time log entries with date, hours, project, description

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Time log list screen

.DESCRIPTION
Shows all time log entries with date, hours, project, and description.
Supports:
- Navigation (Up/Down arrows)
- Deleting entries (D key)
- Refreshing list (R key)
- Viewing report (Rep key)
#>
class TimeListScreen : PmcScreen {
    # Data
    [array]$TimeLogs = @()
    [int]$SelectedIndex = 0

    # Constructor
    TimeListScreen() : base("TimeList", "Time Entries") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Time Entries"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("A", "Add")
        $this.Footer.AddShortcut("E", "Edit")
        $this.Footer.AddShortcut("D", "Delete")
        $this.Footer.AddShortcut("R", "Refresh")
        $this.Footer.AddShortcut("Esc", "Back")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")

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
        $this.ShowStatus("Loading time entries...")

        try {
            $data = Get-PmcAllData

            # Get time logs
            if ($data.PSObject.Properties['timelogs']) {
                $this.TimeLogs = @($data.timelogs | Sort-Object -Property date -Descending)
            } else {
                $this.TimeLogs = @()
            }

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.TimeLogs.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.TimeLogs.Count - 1)
            }

            # Update status
            if ($this.TimeLogs.Count -eq 0) {
                $this.ShowStatus("No time entries")
            } else {
                $totalMinutes = ($this.TimeLogs | Measure-Object -Property minutes -Sum).Sum
                $totalHours = [math]::Round($totalMinutes / 60.0, 2)
                $this.ShowStatus("$($this.TimeLogs.Count) entries, $totalHours hours total")
            }

        } catch {
            $this.ShowError("Failed to load time entries: $_")
            $this.TimeLogs = @()
        }
    }

    [string] RenderContent() {
        if ($this.TimeLogs.Count -eq 0) {
            return $this._RenderEmptyState()
        }

        return $this._RenderTimeLogList()
    }

    hidden [string] _RenderEmptyState() {
        $sb = [System.Text.StringBuilder]::new(512)

        # Get content area
        if ($this.LayoutManager) {
            $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

            # Center message
            $message = "No time entries - Press A to add one"
            $x = $contentRect.X + [Math]::Floor(($contentRect.Width - $message.Length) / 2)
            $y = $contentRect.Y + [Math]::Floor($contentRect.Height / 2)

            $textColor = $this.Header.GetThemedAnsi('Text', $false)
            $reset = "`e[0m"

            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($textColor)
            $sb.Append($message)
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    hidden [string] _RenderTimeLogList() {
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
        $highlightColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $reset = "`e[0m"

        # Column widths
        $idWidth = 5
        $dateWidth = 12
        $projectWidth = 20
        $hoursWidth = 8
        $descWidth = $contentRect.Width - $idWidth - $dateWidth - $projectWidth - $hoursWidth - 10

        # Render column headers
        $headerY = $this.Header.Y + 3
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($headerColor)
        $sb.Append("ID   ")
        $sb.Append("DATE        ")
        $sb.Append("PROJECT             ")
        $sb.Append("HOURS   ")
        $sb.Append("DESCRIPTION")
        $sb.Append($reset)

        # Render time log rows
        $startY = $headerY + 2
        $maxLines = $contentRect.Height - 4

        for ($i = 0; $i -lt [Math]::Min($this.TimeLogs.Count, $maxLines); $i++) {
            $log = $this.TimeLogs[$i]
            $y = $startY + $i
            $isSelected = ($i -eq $this.SelectedIndex)

            # Cursor
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
            if ($isSelected) {
                $sb.Append($cursorColor)
                $sb.Append(">")
                $sb.Append($reset)
            } else {
                $sb.Append(" ")
            }

            $x = $contentRect.X + 4

            # ID column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($mutedColor)
            }
            $sb.Append($log.id.ToString().PadRight($idWidth))
            $sb.Append($reset)
            $x += $idWidth

            # Date column - normalize "today" to actual date
            $rawDate = if ($log.date) { $log.date.ToString() } else { "" }
            $dateStr = if ($rawDate -eq 'today') {
                (Get-Date).ToString('yyyy-MM-dd')
            } elseif ($rawDate -eq 'tomorrow') {
                (Get-Date).AddDays(1).ToString('yyyy-MM-dd')
            } else {
                $rawDate
            }

            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }
            $displayDate = $dateStr.Substring(0, [Math]::Min(10, $dateStr.Length))
            $sb.Append($displayDate.PadRight($dateWidth))
            $sb.Append($reset)
            $x += $dateWidth

            # Project column
            $projectStr = if ($log.project) { $log.project.ToString() } else { if ($log.id1) { "#$($log.id1)" } else { "" } }
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($mutedColor)
            }
            $displayProject = $projectStr.Substring(0, [Math]::Min($projectWidth - 1, $projectStr.Length))
            $sb.Append($displayProject.PadRight($projectWidth))
            $sb.Append($reset)
            $x += $projectWidth

            # Hours column
            $hours = if ($log.minutes) { [math]::Round($log.minutes / 60.0, 2) } else { 0 }
            $hoursStr = $hours.ToString("0.00")
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($highlightColor)
            } else {
                $sb.Append($highlightColor)
            }
            $sb.Append($hoursStr.PadRight($hoursWidth))
            $sb.Append($reset)
            $x += $hoursWidth

            # Description column
            $descStr = if ($log.PSObject.Properties['description'] -and $log.description) { $log.description.ToString() } else { "" }
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }

            if ($descStr.Length -gt 0) {
                $displayDesc = $descStr.Substring(0, [Math]::Min($descWidth, $descStr.Length))
                if ($descStr.Length -gt $descWidth) {
                    $displayDesc = $displayDesc.Substring(0, $descWidth - 3) + "..."
                }
                $sb.Append($displayDesc)
            }
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.TimeLogs.Count - 1)) {
                    $this.SelectedIndex++
                    return $true
                }
            }
            'A' {
                $this._AddEntry()
                return $true
            }
            'E' {
                $this._EditEntry()
                return $true
            }
            'D' {
                $this._DeleteEntry()
                return $true
            }
            'R' {
                $this.LoadData()
                return $true
            }
        }

        return $false
    }

    hidden [void] _AddEntry() {
        . "$PSScriptRoot/TimerStartScreen.ps1"
        $global:PmcApp.PushScreen((New-Object TimerStartScreen))
    }

    hidden [void] _EditEntry() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.TimeLogs.Count) {
            $this.ShowError("No entry selected")
            return
        }

        $entry = $this.TimeLogs[$this.SelectedIndex]
        $this.ShowStatus("Edit time entry: $($entry.id)")
        # Time entries are simple records, editing requires recreation
    }

    hidden [void] _DeleteEntry() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.TimeLogs.Count) {
            $this.ShowError("No entry selected")
            return
        }

        $log = $this.TimeLogs[$this.SelectedIndex]
        $logId = $log.id

        try {
            # Load data
            $data = Get-PmcAllData

            # Remove entry
            $data.timelogs = @($data.timelogs | Where-Object { $_.id -ne $logId })

            # Save
            Set-PmcAllData $data

            $this.ShowSuccess("Time entry #$logId deleted")

            # Reload
            $this.LoadData()

        } catch {
            $this.ShowError("Failed to delete time entry: $_")
        }
    }

    hidden [void] _ViewReport() {
        . "$PSScriptRoot/TimeReportScreen.ps1"
        $global:PmcApp.PushScreen((New-Object TimeReportScreen))
    }
}

# Entry point function for compatibility
function Show-TimeListScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [TimeListScreen]::new()
    $App.PushScreen($screen)
}
