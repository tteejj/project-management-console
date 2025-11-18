using namespace System.Collections.Generic
using namespace System.Text

# TimeListScreen - Time tracking list with full CRUD operations
# Uses UniversalList widget and InlineEditor for consistent UX


Set-StrictMode -Version Latest

. "$PSScriptRoot/../base/StandardListScreen.ps1"
. "$PSScriptRoot/../widgets/TimeEntryDetailDialog.ps1"

<#
.SYNOPSIS
Time tracking list screen with CRUD operations

.DESCRIPTION
Shows all time entries with:
- Add/Edit/Delete via InlineEditor (a/e/d keys)
- View entries by task or project
- Generate time reports
- Automatic aggregation by date/project/timecode
- Press Enter on aggregated entries (shown with count) to see individual entries
- Filter by date range
#>
class TimeListScreen : StandardListScreen {

    # Static: Register menu items
    static [void] RegisterMenuItems([object]$registry) {
        $registry.AddMenuItem('Time', 'Time Tracking', 'T', {
            . "$PSScriptRoot/TimeListScreen.ps1"
            $global:PmcApp.PushScreen([TimeListScreen]::new())
        }, 5)
    }

    # Constructor
    TimeListScreen() : base("TimeList", "Time Tracking") {
        # Configure capabilities
        $this.AllowAdd = $true
        $this.AllowEdit = $true
        $this.AllowDelete = $true
        $this.AllowFilter = $true

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Time Tracking"))

        # Load time entries
        $this.RefreshList()
    }

    # Constructor with container (DI-enabled)
    TimeListScreen([object]$container) : base("TimeList", "Time Tracking", $container) {
        # Configure capabilities
        $this.AllowAdd = $true
        $this.AllowEdit = $true
        $this.AllowDelete = $true
        $this.AllowFilter = $true

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Time Tracking"))

        # Load time entries
        $this.RefreshList()
    }

    # === Abstract Method Implementations ===

    # Get entity type for store operations
    [string] GetEntityType() {
        return 'timelog'
    }

    # Define columns for list display
    [array] GetColumns() {
        return @(
            @{ Name='date_display'; Label='Date'; Width=12 }
            @{ Name='task'; Label='Task'; Width=25 }
            @{ Name='project'; Label='Project'; Width=15 }
            @{ Name='timecode'; Label='Code'; Width=8 }
            @{ Name='duration'; Label='Duration'; Width=10 }
            @{ Name='notes'; Label='Notes'; Width=35 }
        )
    }

    # Load data and refresh list (required by StandardListScreen)
    [void] LoadData() {
        $items = $this.LoadItems()
        $this.List.SetData($items)
    }

    # Load items from data store
    [array] LoadItems() {
        $entries = $this.Store.GetAllTimeLogs()

        # Group entries by date, project, and timecode
        $grouped = @{}
        foreach ($entry in $entries) {
            # TIM-1 FIX: Format date for grouping with error handling
            $dateStr = ''
            if ($entry.ContainsKey('date') -and $entry.date) {
                try {
                    if ($entry.date -is [DateTime]) {
                        $dateStr = $entry.date.ToString('yyyy-MM-dd')
                    } else {
                        # Try to parse as DateTime
                        $parsedDate = [DateTime]::Parse($entry.date)
                        $dateStr = $parsedDate.ToString('yyyy-MM-dd')
                    }
                } catch {
                    Write-PmcTuiLog "TimeListScreen.LoadItems: Failed to parse date '$($entry.date)': $_" "WARNING"
                    $dateStr = ''
                }
            }

            # Create grouping key
            $project = if ($entry.ContainsKey('project')) { $entry.project } else { '' }
            $timecode = if ($entry.ContainsKey('timecode')) { $entry.timecode } else { '' }
            $groupKey = "$dateStr|$project|$timecode"

            # Initialize group if needed
            if (-not $grouped.ContainsKey($groupKey)) {
                $grouped[$groupKey] = @{
                    date = $entry.date
                    date_display = $dateStr
                    project = $project
                    timecode = $timecode
                    task = if ($entry.ContainsKey('task')) { $entry.task } else { '' }
                    notes = if ($entry.ContainsKey('notes')) { $entry.notes } else { '' }
                    minutes = 0
                    entry_count = 0
                    entry_ids = @()
                }
            }

            # Aggregate minutes
            if ($entry.ContainsKey('minutes')) {
                $grouped[$groupKey].minutes += $entry.minutes
            }
            $grouped[$groupKey].entry_count++
            if ($entry.ContainsKey('id')) {
                $grouped[$groupKey].entry_ids += $entry.id
            }

            # Store original entry for drill-down
            if (-not $grouped[$groupKey].ContainsKey('original_entries')) {
                $grouped[$groupKey].original_entries = @()
            }
            $grouped[$groupKey].original_entries += $entry

            # Concatenate tasks if multiple
            if ($entry.ContainsKey('task') -and $entry.task) {
                $currentTask = $grouped[$groupKey].task
                if ($currentTask -and $currentTask -ne $entry.task) {
                    $grouped[$groupKey].task = "$currentTask; $($entry.task)"
                } elseif (-not $currentTask) {
                    $grouped[$groupKey].task = $entry.task
                }
            }

            # Concatenate notes if multiple
            if ($entry.ContainsKey('notes') -and $entry.notes) {
                $currentNotes = $grouped[$groupKey].notes
                if ($currentNotes -and $currentNotes -ne $entry.notes) {
                    $grouped[$groupKey].notes = "$currentNotes; $($entry.notes)"
                } elseif (-not $currentNotes) {
                    $grouped[$groupKey].notes = $entry.notes
                }
            }
        }

        # Convert to array and format
        $aggregated = @()
        foreach ($key in $grouped.Keys) {
            $entry = $grouped[$key]

            # Format duration as HH:MM
            $hours = [int][Math]::Floor($entry.minutes / 60)
            $mins = [int]($entry.minutes % 60)
            $entry['duration'] = "{0:D2}:{1:D2}" -f $hours, $mins

            # Add indicator if aggregated
            if ($entry.entry_count -gt 1) {
                $entry['duration'] = "$($entry.duration) ($($entry.entry_count))"
            }

            $aggregated += $entry
        }

        # Sort by date descending (most recent first)
        return $aggregated | Sort-Object { Get-SafeProperty $_ 'date' } -Descending
    }

    # Define columns for list display
    [array] GetListColumns() {
        return @(
            @{ Name='date_display'; Header='Date'; Width=12 }
            @{ Name='task'; Header='Task'; Width=30 }
            @{ Name='project'; Header='Project'; Width=20 }
            @{ Name='duration'; Header='Duration'; Width=10 }
            @{ Name='notes'; Header='Notes'; Width=30 }
        )
    }

    # Define edit fields for InlineEditor
    [array] GetEditFields([object]$item) {
        if ($null -eq $item -or $item.Count -eq 0) {
            # New time entry - empty fields
            return @(
                @{ Name='date'; Type='date'; Label='Date'; Required=$true; Value=[DateTime]::Now }
                @{ Name='task'; Type='text'; Label='Task'; Value='' }
                @{ Name='project'; Type='project'; Label='Project (or leave blank for timecode)'; Value='' }
                @{ Name='timecode'; Type='text'; Label='Timecode (2-5 digits, or leave blank for project)'; Value=''; MaxLength=5 }
                @{ Name='hours'; Type='number'; Label='Hours'; Min=0.25; Max=8; Step=0.25; Value=0.25 }
                @{ Name='notes'; Type='text'; Label='Notes'; Value='' }
            )
        } else {
            # Existing time entry - populate from item
            $projectVal = if ($item.ContainsKey('project')) { $item.project } else { '' }
            $timecodeVal = if ($item.ContainsKey('timecode')) { $item.timecode } else { '' }
            # Convert minutes to hours for display
            $hoursVal = if ($item.ContainsKey('minutes')) { [math]::Round($item.minutes / 60, 2) } else { 0.25 }
            return @(
                @{ Name='date'; Type='date'; Label='Date'; Required=$true; Value=$item.date }
                @{ Name='task'; Type='text'; Label='Task'; Value=$item.task }
                @{ Name='project'; Type='project'; Label='Project (or leave blank for timecode)'; Value=$projectVal }
                @{ Name='timecode'; Type='text'; Label='Timecode (2-5 digits, or leave blank for project)'; Value=$timecodeVal; MaxLength=5 }
                @{ Name='hours'; Type='number'; Label='Hours'; Min=0.25; Max=8; Step=0.25; Value=$hoursVal }
                @{ Name='notes'; Type='text'; Label='Notes'; Value=$item.notes }
            )
        }
    }

    # Handle item creation
    [void] OnItemCreated([hashtable]$values) {
        try {
            # ENDEMIC FIX: Safe conversion with validation
            if (-not $values.ContainsKey('hours') -or [string]::IsNullOrWhiteSpace($values.hours)) {
                $this.SetStatusMessage("Hours field is required", "error")
                return
            }

            $hoursValue = 0.0
            try {
                $hoursValue = [double]$values.hours
            } catch {
                $this.SetStatusMessage("Invalid hours value: $($values.hours)", "error")
                return
            }

            # Validate hour range
            if ($hoursValue -le 0) {
                $this.SetStatusMessage("Hours must be greater than 0", "error")
                return
            }
            if ($hoursValue -gt 24) {
                $this.SetStatusMessage("Hours must be 24 or less", "error")
                return
            }

            $minutes = [int]($hoursValue * 60)

            # Safe date conversion
            $dateValue = [DateTime]::Today
            if ($values.ContainsKey('date') -and $values.date) {
                try {
                    $dateValue = [DateTime]$values.date
                } catch {
                    Write-PmcTuiLog "Failed to parse date '$($values.date)', using today" "WARNING"
                }
            }

            $timeData = @{
                date = $dateValue
                task = if ($values.ContainsKey('task')) { $values.task } else { '' }
                project = if ($values.ContainsKey('project')) { $values.project } else { '' }
                timecode = if ($values.ContainsKey('timecode')) { $values.timecode } else { '' }
                minutes = $minutes
                notes = if ($values.ContainsKey('notes')) { $values.notes } else { '' }
                created = [DateTime]::Now
            }

            $success = $this.Store.AddTimeLog($timeData)

            $statusMsg = "Time entry added: {0:F2} hours" -f $hoursValue
            if ($success) {
                $this.SetStatusMessage($statusMsg, "success")
            } else {
                $this.SetStatusMessage("Failed to add time entry: $($this.Store.LastError)", "error")
            }
        } catch {
            Write-PmcTuiLog "OnItemCreated exception: $_" "ERROR"
            $this.SetStatusMessage("Unexpected error: $($_.Exception.Message)", "error")
        }
    }

    # Handle item update
    [void] OnItemUpdated([object]$item, [hashtable]$values) {
        try {
            # ENDEMIC FIX: Safe conversion with validation
            if (-not $values.ContainsKey('hours') -or [string]::IsNullOrWhiteSpace($values.hours)) {
                $this.SetStatusMessage("Hours field is required", "error")
                return
            }

            $hoursValue = 0.0
            try {
                $hoursValue = [double]$values.hours
            } catch {
                $this.SetStatusMessage("Invalid hours value: $($values.hours)", "error")
                return
            }

            # Validate hour range
            if ($hoursValue -le 0) {
                $this.SetStatusMessage("Hours must be greater than 0", "error")
                return
            }
            if ($hoursValue -gt 24) {
                $this.SetStatusMessage("Hours must be 24 or less", "error")
                return
            }

            $minutes = [int]($hoursValue * 60)

            # Safe date conversion
            $dateValue = [DateTime]::Today
            if ($values.ContainsKey('date') -and $values.date) {
                try {
                    $dateValue = [DateTime]$values.date
                } catch {
                    Write-PmcTuiLog "Failed to parse date '$($values.date)', using today" "WARNING"
                }
            }

            $changes = @{
                date = $dateValue
                task = if ($values.ContainsKey('task')) { $values.task } else { '' }
                project = if ($values.ContainsKey('project')) { $values.project } else { '' }
                timecode = if ($values.ContainsKey('timecode')) { $values.timecode } else { '' }
                minutes = $minutes
                notes = if ($values.ContainsKey('notes')) { $values.notes } else { '' }
            }

            # Update time log via TaskStore
            if ($item.ContainsKey('id') -and -not [string]::IsNullOrWhiteSpace($item.id)) {
                $success = $this.Store.UpdateTimeLog($item.id, $changes)
                if ($success) {
                    $this.SetStatusMessage("Time entry updated", "success")
                    $this.LoadData()  # Refresh to show updated data
                } else {
                    $this.SetStatusMessage("Failed to update time entry: $($this.Store.LastError)", "error")
                }
            } else {
                $this.SetStatusMessage("Cannot update time entry without ID", "error")
            }
        } catch {
            Write-PmcTuiLog "OnItemUpdated exception: $_" "ERROR"
            $this.SetStatusMessage("Unexpected error: $($_.Exception.Message)", "error")
        }
    }

    # Handle item deletion
    [void] OnItemDeleted([object]$item) {
        if ($item.ContainsKey('id')) {
            $success = $this.Store.DeleteTimeLog($item.id)
            if ($success) {
                $this.SetStatusMessage("Time entry deleted", "success")
            } else {
                $this.SetStatusMessage("Failed to delete time entry: $($this.Store.LastError)", "error")
            }
        } else {
            $this.SetStatusMessage("Cannot delete time entry without ID", "error")
        }
    }

    # Get custom actions for footer display
    [array] GetCustomActions() {
        $self = $this
        return @(
            @{ Key='Enter'; Label='Details'; Callback={
                # Enter is handled by StandardListScreen's OnItemActivated
                # which TimeListScreen doesn't override, so no action needed
            }.GetNewClosure() }
            @{ Key='w'; Label='Week Report'; Callback={
                . "$PSScriptRoot/WeeklyTimeReportScreen.ps1"
                $screen = Invoke-Expression '[WeeklyTimeReportScreen]::new()'
                $self.App.PushScreen($screen)
            }.GetNewClosure() }
            @{ Key='g'; Label='Generate'; Callback={
                $self.GenerateReport()
            }.GetNewClosure() }
        )
    }

    # === Custom Actions ===

    # Show detail dialog for aggregated entries
    [void] ShowDetailDialog([hashtable]$item) {
        if (-not $item.ContainsKey('original_entries') -or $item.original_entries.Count -eq 0) {
            return
        }

        # Create dialog title
        $title = "Time Entry Details - $($item.date_display) - $($item.project)"
        if ($item.timecode) {
            $title += " [$($item.timecode)]"
        }
        $title += " ($($item.entry_count) entries)"

        # Create and show dialog
        $dialog = [TimeEntryDetailDialog]::new($title, $item.original_entries)

        # TIM-7 FIX: Dialog render loop with timeout protection
        $maxIterations = 120000  # 120000 * 50ms = 100 minutes max
        $iterations = 0

        while (-not $dialog.IsComplete -and $iterations -lt $maxIterations) {
            $iterations++

            # Get theme from theme manager
            $themeManager = [PmcThemeManager]::GetInstance()
            $theme = $themeManager.GetTheme()

            # Render dialog
            $termWidth = [Console]::WindowWidth
            $termHeight = [Console]::WindowHeight
            $dialogOutput = $dialog.Render($termWidth, $termHeight, $theme)
            Write-Host -NoNewline $dialogOutput

            # Handle input
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                $dialog.HandleInput($key)

                # Escape hatch: Ctrl+C or Escape should always close
                if ($key.Key -eq 'Escape' -or ($key.Modifiers -band [ConsoleModifiers]::Control)) {
                    $dialog.IsComplete = $true
                    break
                }
            }

            Start-Sleep -Milliseconds 50
        }

        # Log if timeout occurred
        if ($iterations -ge $maxIterations) {
            Write-PmcTuiLog "TimeListScreen.ShowDetailDialog: Timeout after $maxIterations iterations" "WARNING"
        }

        # Redraw screen after dialog closes
        $this.RenderEngine.ForceRedraw()
    }

    # Generate time report for selected period
    [void] GenerateReport() {
        # Navigate to time report screen
        . "$PSScriptRoot/TimeReportScreen.ps1"
        $screen = [TimeReportScreen]::new()
        $this.App.PushScreen($screen)
    }

    # === Input Handling ===

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Custom key: Enter = Show detail dialog for aggregated entries
        if ($keyInfo.Key -eq 'Enter' -and -not $this.ShowInlineEditor) {
            $selectedItem = $this.List.GetSelectedItem()
            if ($selectedItem -and $selectedItem.ContainsKey('entry_count') -and $selectedItem.entry_count -gt 1) {
                $this.ShowDetailDialog($selectedItem)
                return $true
            }
        }

        # Call parent handler (handles list navigation, add/edit/delete)
        $handled = ([StandardListScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        # Custom key: G = Generate report
        if ($keyInfo.KeyChar -eq 'g' -or $keyInfo.KeyChar -eq 'G') {
            $this.GenerateReport()
            return $true
        }

        # Custom key: W = Weekly time report
        if ($keyInfo.KeyChar -eq 'w' -or $keyInfo.KeyChar -eq 'W') {
            . "$PSScriptRoot/WeeklyTimeReportScreen.ps1"
            $screen = [WeeklyTimeReportScreen]::new()
            $this.App.PushScreen($screen)
            return $true
        }

        return $false
    }
}
