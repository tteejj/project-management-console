using namespace System.Collections.Generic
using namespace System.Text

# TimeListScreen - Time tracking list with full CRUD operations
# Uses UniversalList widget and InlineEditor for consistent UX


Set-StrictMode -Version Latest

. "$PSScriptRoot/../base/StandardListScreen.ps1"

<#
.SYNOPSIS
Time tracking list screen with CRUD operations

.DESCRIPTION
Shows all time entries with:
- Add/Edit/Delete via InlineEditor (a/e/d keys)
- View entries by task or project
- Generate time reports
- Filter by date range
#>
class TimeListScreen : StandardListScreen {

    # Constructor
    TimeListScreen() : base("TimeList", "Time Tracking") {
        # Configure capabilities
        $this.AllowAdd = $true
        $this.AllowEdit = $true
        $this.AllowDelete = $true
        $this.AllowFilter = $true

        # Configure list columns
        $this.ConfigureColumns(@(
            @{ Name='date'; Header='Date'; Width=12; Align='left' }
            @{ Name='task'; Header='Task'; Width=30; Align='left' }
            @{ Name='project'; Header='Project'; Width=20; Align='left' }
            @{ Name='duration'; Header='Duration'; Width=10; Align='right' }
            @{ Name='notes'; Header='Notes'; Width=30; Align='left' }
        ))

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

    # Load items from data store
    [array] LoadItems() {
        $entries = $this.Store.GetAllTimeLogs()

        # Add computed fields and format
        foreach ($entry in $entries) {
            # Format duration as HH:MM
            if ($entry.ContainsKey('minutes')) {
                $hours = [Math]::Floor($entry.minutes / 60)
                $mins = $entry.minutes % 60
                $entry['duration'] = "{0:D2}:{1:D2}" -f $hours, $mins
            } else {
                $entry['duration'] = "00:00"
            }

            # Format date
            if ($entry.ContainsKey('date') -and $entry.date -is [DateTime]) {
                $entry['date_display'] = $entry.date.ToString('yyyy-MM-dd')
            } else {
                $entry['date_display'] = ''
            }

            # Ensure task and project fields exist
            if (-not $entry.ContainsKey('task')) {
                $entry['task'] = ''
            }
            if (-not $entry.ContainsKey('project')) {
                $entry['project'] = ''
            }
            if (-not $entry.ContainsKey('notes')) {
                $entry['notes'] = ''
            }
        }

        # Sort by date descending (most recent first)
        return $entries | Sort-Object -Property date -Descending
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
                @{ Name='project'; Type='project'; Label='Project'; Value='' }
                @{ Name='minutes'; Type='number'; Label='Minutes'; Min=0; Max=480; Value=60 }
                @{ Name='notes'; Type='text'; Label='Notes'; Value='' }
            )
        } else {
            # Existing time entry - populate from item
            return @(
                @{ Name='date'; Type='date'; Label='Date'; Required=$true; Value=$item.date }
                @{ Name='task'; Type='text'; Label='Task'; Value=$item.task }
                @{ Name='project'; Type='project'; Label='Project'; Value=$item.project }
                @{ Name='minutes'; Type='number'; Label='Minutes'; Min=0; Max=480; Value=$item.minutes }
                @{ Name='notes'; Type='text'; Label='Notes'; Value=$item.notes }
            )
        }
    }

    # Handle item creation
    [void] OnItemCreated([hashtable]$values) {
        $timeData = @{
            date = [DateTime]$values.date
            task = $values.task
            project = $values.project
            minutes = [int]$values.minutes
            notes = $values.notes
            created = [DateTime]::Now
        }

        $this.Store.AddTimeLog($timeData)

        $hours = [Math]::Floor($timeData.minutes / 60)
        $mins = $timeData.minutes % 60
        $this.SetStatusMessage("Time entry added: {0:D2}:{1:D2}" -f $hours, $mins, "success")
    }

    # Handle item update
    [void] OnItemUpdated([object]$item, [hashtable]$values) {
        $changes = @{
            date = [DateTime]$values.date
            task = $values.task
            project = $values.project
            minutes = [int]$values.minutes
            notes = $values.notes
        }

        # Time logs typically don't support update in PMC - might need to delete and re-add
        # For now, try to update by ID if it exists
        if ($item.ContainsKey('id')) {
            $this.Store.UpdateTimeLog($item.id, $changes)
            $this.SetStatusMessage("Time entry updated", "success")
        } else {
            $this.SetStatusMessage("Cannot update time entry without ID", "error")
        }
    }

    # Handle item deletion
    [void] OnItemDeleted([object]$item) {
        if ($item.ContainsKey('id')) {
            $this.Store.DeleteTimeLog($item.id)
            $this.SetStatusMessage("Time entry deleted", "success")
        } else {
            $this.SetStatusMessage("Cannot delete time entry without ID", "error")
        }
    }

    # === Custom Actions ===

    # Generate time report for selected period
    [void] GenerateReport() {
        # Navigate to time report screen
        . "$PSScriptRoot/TimeReportScreen.ps1"
        $this.App.PushScreen([TimeReportScreen]::new())
    }

    # === Input Handling ===

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Call parent handler first (handles list navigation, add/edit/delete)
        $handled = ([StandardListScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        # Custom key: G = Generate report
        if ($keyInfo.Key -eq 'G') {
            $this.GenerateReport()
            return $true
        }

        return $false
    }
}
