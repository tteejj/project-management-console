using namespace System.Collections.Generic
using namespace System.Text

# TimeReportScreen - Time report summary
# Shows summary by project: total hours, task breakdown


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Time report summary screen

.DESCRIPTION
Shows time summary grouped by project.
Displays:
- Total hours per project
- Number of entries per project
- Overall total
No navigation, just view (read-only).
#>
class TimeReportScreen : PmcScreen {
    # Data
    [array]$ProjectSummaries = @()
    [int]$TotalMinutes = 0
    [double]$TotalHours = 0

    # Static: Register menu items
    static [void] RegisterMenuItems([object]$registry) {
        $registry.AddMenuItem('Time', 'Time Report', 'R', {
            . "$PSScriptRoot/TimeReportScreen.ps1"
            $global:PmcApp.PushScreen((New-Object -TypeName TimeReportScreen))
        }, 20)
    }

    # Constructor
    TimeReportScreen() : base("TimeReport", "Time Report") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Time Entries", "Report"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("W", "Weekly")
        $this.Footer.AddShortcut("R", "Refresh")
        $this.Footer.AddShortcut("Esc", "Back")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via static RegisterMenuItems()
        # Old pattern was adding duplicate/misplaced menu items
    }

    # Constructor with container (DI-enabled)
    TimeReportScreen([object]$container) : base("TimeReport", "Time Report", $container) {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Time Entries", "Report"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("W", "Weekly")
        $this.Footer.AddShortcut("R", "Refresh")
        $this.Footer.AddShortcut("Esc", "Back")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via static RegisterMenuItems()
        # Old pattern was adding duplicate/misplaced menu items
    }

    [void] OnEnter() {
        # Call parent to ensure proper lifecycle (sets IsActive, calls LoadData, executes OnEnterHandler)
        ([PmcScreen]$this).OnEnter()
    }

    [void] LoadData() {
        $this.ShowStatus("Loading time report...")

        try {
            # Use TaskStore singleton instead of loading from disk
            $timelogs = $this.Store.GetAllTimeLogs()

            # CRITICAL FIX: Add null check for GetAllTimeLogs()
            if ($null -eq $timelogs) {
                $timelogs = @()
            }

            # TS-M8 FIX: Add better feedback for empty state
            if ($timelogs.Count -eq 0) {
                $this.ProjectSummaries = @()
                $this.TotalMinutes = 0
                $this.TotalHours = 0
                # Enhanced feedback to guide user on what to do next
                $this.ShowStatus("No time entries found. Press 'T' to add time entries in Time Tracking screen.")
                Write-PmcTuiLog "TimeReportScreen: No time entries found for report" "INFO"
                return
            }

            # TS-M7 FIX: Group by project ID if available, otherwise by name
            # Create grouping key for each entry: use id1 if present, otherwise project name
            $groupedData = @{}
            foreach ($log in $timelogs) {
                # Determine grouping key (prefer ID over name)
                $groupKey = ''
                $projectDisplay = ''
                if ($log.ContainsKey('id1') -and $log.id1) {
                    $groupKey = "ID:$($log.id1)"
                    $projectDisplay = $(if ($log.ContainsKey('project') -and $log.project) { "$($log.project) [#$($log.id1)]" } else { "#$($log.id1)" })
                } else {
                    $projectVal = $(if ($log.ContainsKey('project')) { $log.project } else { 'Unknown' })
                    $groupKey = "NAME:$projectVal"
                    $projectDisplay = $projectVal
                }

                # Initialize group if needed
                if (-not $groupedData.ContainsKey($groupKey)) {
                    $groupedData[$groupKey] = @{
                        DisplayName = $projectDisplay
                        Entries = @()
                    }
                }

                $groupedData[$groupKey].Entries += $log
            }

            $this.ProjectSummaries = @()
            $this.TotalMinutes = 0
            # LOW FIX TS-L2: Accumulate hours to avoid redundant calculation
            $totalHoursAccumulated = 0.0

            foreach ($key in ($groupedData.Keys | Sort-Object)) {
                $group = $groupedData[$key]
                $minutes = ($group.Entries | Measure-Object -Property minutes -Sum).Sum
                $hours = [Math]::Round($minutes / 60.0, 2)
                $this.TotalMinutes += $minutes
                $totalHoursAccumulated += $hours

                $this.ProjectSummaries += [PSCustomObject]@{
                    Project = $group.DisplayName
                    EntryCount = $group.Entries.Count
                    Minutes = $minutes
                    Hours = $hours
                }
            }

            # Use accumulated hours (sum of rounded values) instead of recalculating
            $this.TotalHours = $totalHoursAccumulated

            $this.ShowStatus("Report generated: $($this.ProjectSummaries.Count) projects, $($this.TotalHours) hours total")

        } catch {
            $this.ShowError("Failed to load time report: $_")
            $this.ProjectSummaries = @()
            $this.TotalMinutes = 0
            $this.TotalHours = 0
        }
    }

    [string] RenderContent() {
        if ($this.ProjectSummaries.Count -eq 0) {
            return $this._RenderEmptyState()
        }

        return $this._RenderReport()
    }

    hidden [string] _RenderEmptyState() {
        $sb = [System.Text.StringBuilder]::new(512)

        # Get content area
        if ($this.LayoutManager) {
            $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

            # TS-M8 FIX: Enhanced empty state feedback with actionable guidance
            $textColor = $this.Header.GetThemedFg('Foreground.Field')
            $mutedColor = $this.Header.GetThemedFg('Foreground.Muted')
            $reset = "`e[0m"

            # Main message
            $message = "No time entries to report"
            $x = $contentRect.X + [Math]::Floor(($contentRect.Width - $message.Length) / 2)
            $y = $contentRect.Y + [Math]::Floor($contentRect.Height / 2) - 1

            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($textColor)
            $sb.Append($message)
            $sb.Append($reset)

            # Helpful guidance
            $hint = "Press 'T' to add time entries in Time Tracking screen"
            $hintX = $contentRect.X + [Math]::Floor(($contentRect.Width - $hint.Length) / 2)
            $sb.Append($this.Header.BuildMoveTo($hintX, $y + 2))
            $sb.Append($mutedColor)
            $sb.Append($hint)
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    hidden [string] _RenderReport() {
        $sb = [System.Text.StringBuilder]::new(4096)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedFg('Foreground.Field')
        $highlightColor = $this.Header.GetThemedFg('Foreground.FieldFocused')
        $mutedColor = $this.Header.GetThemedFg('Foreground.Muted')
        $headerColor = $this.Header.GetThemedFg('Foreground.Muted')
        $successColor = $this.Header.GetThemedFg('Foreground.Success')
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $reset = "`e[0m"

        $y = $contentRect.Y + 1

        # Title
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($highlightColor)
        $sb.Append("Time Summary by Project")
        $sb.Append($reset)
        $y += 2

        # Column headers
        $headerY = $y
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($headerColor)
        $sb.Append("PROJECT                     ")
        $sb.Append("ENTRIES  ")
        $sb.Append("MINUTES      ")
        $sb.Append("HOURS")
        $sb.Append($reset)
        $y++

        # Separator line
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
        $sb.Append($mutedColor)
        for ($i = 0; $i -lt ($contentRect.Width - 4); $i++) {
            $sb.Append("-")
        }
        $sb.Append($reset)
        $y++

        # Project rows
        $maxLines = $contentRect.Height - 8
        $displayCount = [Math]::Min($this.ProjectSummaries.Count, $maxLines)

        for ($i = 0; $i -lt $displayCount; $i++) {
            $summary = $this.ProjectSummaries[$i]

            $x = $contentRect.X + 4

            # Project name
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($textColor)
            $projectName = $summary.Project
            if ($projectName.Length -gt 26) {
                $projectName = $projectName.Substring(0, 23) + "..."
            }
            $sb.Append($projectName.PadRight(28))
            $sb.Append($reset)
            $x += 28

            # Entry count
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($mutedColor)
            $sb.Append($summary.EntryCount.ToString().PadRight(9))
            $sb.Append($reset)
            $x += 9

            # Minutes
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($warningColor)
            $sb.Append($summary.Minutes.ToString().PadRight(13))
            $sb.Append($reset)
            $x += 13

            # Hours
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($successColor)
            $sb.Append($summary.Hours.ToString("0.00"))
            $sb.Append($reset)

            $y++
        }

        # Separator line
        $y++
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
        $sb.Append($mutedColor)
        for ($i = 0; $i -lt ($contentRect.Width - 4); $i++) {
            $sb.Append("-")
        }
        $sb.Append($reset)
        $y++

        # Total row
        $x = $contentRect.X + 4

        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($highlightColor)
        $sb.Append("TOTAL:".PadRight(28))
        $sb.Append($reset)
        $x += 28

        # Total entries
        $totalEntries = ($this.ProjectSummaries | Measure-Object -Property EntryCount -Sum).Sum
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($mutedColor)
        $sb.Append($totalEntries.ToString().PadRight(9))
        $sb.Append($reset)
        $x += 9

        # Total minutes
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($warningColor)
        $sb.Append($this.TotalMinutes.ToString().PadRight(13))
        $sb.Append($reset)
        $x += 13

        # Total hours
        $sb.Append($this.Header.BuildMoveTo($x, $y))
        $sb.Append($successColor)
        $sb.Append($this.TotalHours.ToString("0.00"))
        $sb.Append($reset)

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # CRITICAL: Call parent FIRST for MenuBar, F10, Alt+keys, content widgets
        $handled = ([PmcScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        # F10 - Menu
        if ($keyInfo.Key -eq ([ConsoleKey]::F10)) {
            if ($this.MenuBar) {
                $this.MenuBar.Activate()
                return $true
            }
        }

        # Escape - Go back
        if ($keyInfo.Key -eq ([ConsoleKey]::Escape)) {
            $global:PmcApp.PopScreen()
            return $true
        }

        # Ctrl+Q - Quit
        if ($keyInfo.Modifiers -band [ConsoleModifiers]::Control -and $keyInfo.Key -eq ([ConsoleKey]::Q)) {
            $global:PmcApp.Quit()
            return $true
        }

        # Refresh on R key
        if ($keyInfo.Key -eq ([ConsoleKey]::R)) {
            $this.LoadData()
            return $true
        }

        # Weekly report on W key
        if ($keyInfo.Key -eq ([ConsoleKey]::W)) {
            . "$PSScriptRoot/WeeklyTimeReportScreen.ps1"
            $screen = New-Object WeeklyTimeReportScreen
            $global:PmcApp.PushScreen($screen)
            return $true
        }

        return $false
    }
}

# Entry point function for compatibility
function Show-TimeReportScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = New-Object TimeReportScreen
    $App.PushScreen($screen)
}