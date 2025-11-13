using namespace System.Collections.Generic
using namespace System.Text

# WeeklyTimeReportScreen - Weekly time tracking report
# Shows time entries grouped by project with daily breakdown (Mon-Fri)
# Matches the old renderer's weekly report functionality


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Weekly time tracking report screen

.DESCRIPTION
Shows time summary grouped by project with daily breakdown.
Displays:
- Hours per day (Mon-Fri) for each project
- Total hours per project
- Grand total
- Week navigation (=/-keys)
Based on the old renderer's DrawWeeklyReport implementation.
#>
class WeeklyTimeReportScreen : PmcScreen {
    # Data
    [hashtable]$ProjectSummaries = @{}
    [double]$GrandTotal = 0
    [int]$WeekOffset = 0
    [DateTime]$WeekStart
    [DateTime]$WeekEnd
    [string]$WeekHeader = ""
    [string]$WeekIndicator = ""
    [TaskStore]$Store = $null

    # Static: Register menu items
    static [void] RegisterMenuItems([object]$registry) {
        $registry.AddMenuItem('Time', 'Weekly Report', 'W', {
            . "$PSScriptRoot/WeeklyTimeReportScreen.ps1"
            $global:PmcApp.PushScreen([WeeklyTimeReportScreen]::new())
        }, 10)
    }

    # Constructor
    WeeklyTimeReportScreen() : base("WeeklyTimeReport", "Weekly Time Report") {
        # Initialize TaskStore from global DI container
        $this.Store = $global:Pmc.Container.Resolve('TaskStore')

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Time Entries", "Weekly Report"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("=", "Next Week")
        $this.Footer.AddShortcut("-", "Prev Week")
        $this.Footer.AddShortcut("R", "Refresh")
        $this.Footer.AddShortcut("Esc", "Back")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via static RegisterMenuItems()
        # Old pattern was adding duplicate/misplaced menu items
    }

    # Constructor with container (DI-enabled)
    WeeklyTimeReportScreen([object]$container) : base("WeeklyTimeReport", "Weekly Time Report", $container) {
        # Initialize TaskStore from DI container
        $this.Store = $container.Resolve('TaskStore')

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Time Entries", "Weekly Report"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("=", "Next Week")
        $this.Footer.AddShortcut("-", "Prev Week")
        $this.Footer.AddShortcut("R", "Refresh")
        $this.Footer.AddShortcut("Esc", "Back")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via static RegisterMenuItems()
        # Old pattern was adding duplicate/misplaced menu items
    }

    # OnEnter - Load data when screen becomes active (consistent with other screens)
    [void] OnEnter() {
        # Call parent to ensure proper lifecycle (sets IsActive, calls LoadData, executes OnEnterHandler)
        ([PmcScreen]$this).OnEnter()
    }

    [void] LoadData() {
        $this.ShowStatus("Loading weekly time report...")

        try {
            # Calculate week start (Monday) and end (Friday)
            $today = Get-Date
            $daysFromMonday = ($today.DayOfWeek.value__ + 6) % 7
            $thisMonday = $today.AddDays(-$daysFromMonday).Date
            $this.WeekStart = $thisMonday.AddDays($this.WeekOffset * 7)
            $this.WeekEnd = $this.WeekStart.AddDays(4)

            # Format week header
            $this.WeekHeader = "Week of {0} - {1}" -f $this.WeekStart.ToString('MMM dd'), $this.WeekEnd.ToString('MMM dd, yyyy')

            # Add indicator for current/past/future week
            if ($this.WeekOffset -eq 0) {
                $this.WeekIndicator = ' (This Week)'
            } elseif ($this.WeekOffset -lt 0) {
                $weeks = [Math]::Abs($this.WeekOffset)
                $plural = if ($weeks -gt 1) { 's' } else { '' }
                $this.WeekIndicator = " ($weeks week$plural ago)"
            } else {
                $plural = if ($this.WeekOffset -gt 1) { 's' } else { '' }
                $this.WeekIndicator = " ($($this.WeekOffset) week$plural from now)"
            }

            # Use TaskStore singleton instead of loading from disk
            $logs = $this.Store.GetAllTimeLogs()

            # Filter logs for the week (Monday-Friday)
            $weekLogs = @()
            for ($d = 0; $d -lt 5; $d++) {
                $dayDate = $this.WeekStart.AddDays($d).ToString('yyyy-MM-dd')
                $dayLogs = $logs | Where-Object {
                    $dateStr = if ($_.date -is [DateTime]) {
                        $_.date.ToString('yyyy-MM-dd')
                    } else {
                        $_.date
                    }
                    $dateStr -eq $dayDate
                }
                $weekLogs += $dayLogs
            }

            # Group by project/id1
            $this.ProjectSummaries = @{}
            $this.GrandTotal = 0

            foreach ($log in $weekLogs) {
                # Determine grouping key
                $key = ''
                if ($log.id1) {
                    $key = "#$($log.id1)"
                } else {
                    $name = $log.project
                    if (-not $name) { $name = 'Unknown' }
                    $key = $name
                }

                # Initialize project entry if needed
                if (-not $this.ProjectSummaries.ContainsKey($key)) {
                    $name = ''
                    $id1 = ''
                    if ($log.id1) {
                        $id1 = $log.id1
                        $name = $log.project
                        if (-not $name) { $name = '' }
                    } else {
                        $name = $log.project
                        if (-not $name) { $name = 'Unknown' }
                    }

                    $this.ProjectSummaries[$key] = @{
                        Name = $name
                        ID1 = $id1
                        Mon = 0.0
                        Tue = 0.0
                        Wed = 0.0
                        Thu = 0.0
                        Fri = 0.0
                        Total = 0.0
                    }
                }

                # Add hours to appropriate day
                $logDate = [datetime]$log.date
                $dayIndex = ($logDate.DayOfWeek.value__ + 6) % 7  # 0=Mon, 1=Tue, etc.
                $hours = [Math]::Round($log.minutes / 60.0, 1)

                switch ($dayIndex) {
                    0 { $this.ProjectSummaries[$key].Mon += $hours }
                    1 { $this.ProjectSummaries[$key].Tue += $hours }
                    2 { $this.ProjectSummaries[$key].Wed += $hours }
                    3 { $this.ProjectSummaries[$key].Thu += $hours }
                    4 { $this.ProjectSummaries[$key].Fri += $hours }
                }
                $this.ProjectSummaries[$key].Total += $hours
                $this.GrandTotal += $hours
            }

            # Update status
            if ($weekLogs.Count -eq 0) {
                $this.ShowStatus("No time entries for this week")
            } else {
                $this.ShowStatus("$($this.ProjectSummaries.Count) projects, $($this.GrandTotal.ToString('0.0')) hours total")
            }

        } catch {
            $this.ShowError("Failed to load weekly time report: $_")
            $this.ProjectSummaries = @{}
            $this.GrandTotal = 0
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

            # Colors
            $textColor = $this.Header.GetThemedAnsi('Text', $false)
            $highlightColor = $this.Header.GetThemedAnsi('Highlight', $false)
            $reset = "`e[0m"

            # Week header
            $y = $contentRect.Y + 2
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($highlightColor)
            $sb.Append($this.WeekHeader)
            $sb.Append($this.WeekIndicator)
            $sb.Append($reset)
            $y += 2

            # No entries message
            $message = "No time entries for this week"
            $x = $contentRect.X + 4
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($textColor)
            $sb.Append($message)
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
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $highlightColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
        $successColor = $this.Header.GetThemedAnsi('Success', $false)
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $reset = "`e[0m"

        $y = $contentRect.Y + 1

        # Week header
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($highlightColor)
        $sb.Append($this.WeekHeader)
        $sb.Append($this.WeekIndicator)
        $sb.Append($reset)
        $y += 2

        # Column headers - matching old renderer format
        # "Name                 ID1   Mon    Tue    Wed    Thu    Fri    Total"
        $headerY = $y
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($headerColor)
        $sb.Append("Name                 ID1   Mon    Tue    Wed    Thu    Fri    Total")
        $sb.Append($reset)
        $y++

        # Separator line
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($mutedColor)
        $sb.Append([string]::new([char]0x2500, 75))  # Unicode line character
        $sb.Append($reset)
        $y++

        # Project rows - sorted by key
        $sortedProjects = $this.ProjectSummaries.GetEnumerator() | Sort-Object Key

        foreach ($entry in $sortedProjects) {
            $d = $entry.Value

            # Format: "{0,-20} {1,-5} {2,6:F1} {3,6:F1} {4,6:F1} {5,6:F1} {6,6:F1} {7,8:F1}"
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($textColor)

            # Name (20 chars, left-aligned)
            $name = $d.Name
            if ($name.Length -gt 20) {
                $name = $name.Substring(0, 17) + "..."
            }
            $sb.Append($name.PadRight(20))
            $sb.Append(" ")

            # ID1 (5 chars, left-aligned)
            $id1Display = $d.ID1
            if ($id1Display.Length -gt 5) {
                $id1Display = $id1Display.Substring(0, 5)
            }
            $sb.Append($id1Display.PadRight(5))
            $sb.Append(" ")

            # Day columns (6 chars each, right-aligned with 1 decimal)
            $sb.Append($successColor)
            $sb.Append($d.Mon.ToString("0.0").PadLeft(6))
            $sb.Append(" ")
            $sb.Append($d.Tue.ToString("0.0").PadLeft(6))
            $sb.Append(" ")
            $sb.Append($d.Wed.ToString("0.0").PadLeft(6))
            $sb.Append(" ")
            $sb.Append($d.Thu.ToString("0.0").PadLeft(6))
            $sb.Append(" ")
            $sb.Append($d.Fri.ToString("0.0").PadLeft(6))
            $sb.Append(" ")

            # Total (8 chars, right-aligned with 1 decimal)
            $sb.Append($warningColor)
            $sb.Append($d.Total.ToString("0.0").PadLeft(8))
            $sb.Append($reset)

            $y++
        }

        # Footer separator
        $y++
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($mutedColor)
        $sb.Append([string]::new([char]0x2500, 75))
        $sb.Append($reset)
        $y++

        # Total row - matching old format
        # "                                                          Total: {0,8:F1}"
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($highlightColor)
        $sb.Append(" " * 58)
        $sb.Append("Total: ")
        $sb.Append($this.GrandTotal.ToString("0.0").PadLeft(8))
        $sb.Append($reset)

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # CRITICAL: Call parent FIRST for MenuBar, F10, Alt+keys, content widgets
        $handled = ([PmcScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        # Week navigation with arrow keys
        if ($keyInfo.Key -eq 'LeftArrow') {
            $this.WeekOffset--
            $this.LoadData()
            return $true
        }

        if ($keyInfo.Key -eq 'RightArrow') {
            $this.WeekOffset++
            $this.LoadData()
            return $true
        }

        # Week navigation with = and - keys
        if ($keyInfo.KeyChar -eq '=') {
            $this.WeekOffset++
            $this.LoadData()
            return $true
        }

        if ($keyInfo.KeyChar -eq '-') {
            $this.WeekOffset--
            $this.LoadData()
            return $true
        }

        # Refresh
        if ($keyInfo.KeyChar -eq 'r' -or $keyInfo.KeyChar -eq 'R') {
            $this.LoadData()
            return $true
        }

        return $false
    }
}

# Entry point function for compatibility
function Show-WeeklyTimeReportScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [WeeklyTimeReportScreen]::new()
    $App.PushScreen($screen)
}
