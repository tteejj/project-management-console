using namespace System.Collections.Generic
using namespace System.Text

# TimeDeleteFormScreen - Delete time entry confirmation
# Shows entry details and asks for confirmation


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Time entry delete confirmation screen

.DESCRIPTION
Shows selected time entry details and asks for confirmation.
Supports:
- Viewing entry information
- Confirming delete (Y key)
- Canceling delete (N/Esc key)
#>
class TimeDeleteFormScreen : PmcScreen {
    # Data
    [object]$TimeEntry = $null

    # Backward compatible constructor
    TimeDeleteFormScreen() : base("TimeDeleteForm", "Delete Time Entry") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Time Entries", "Delete"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Y", "Confirm")
        $this.Footer.AddShortcut("N", "Cancel")
        $this.Footer.AddShortcut("Esc", "Back")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
    }

    # Container constructor
    TimeDeleteFormScreen([object]$container) : base("TimeDeleteForm", "Delete Time Entry", $container) {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Time Entries", "Delete"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Y", "Confirm")
        $this.Footer.AddShortcut("N", "Cancel")
        $this.Footer.AddShortcut("Esc", "Back")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
    }

    # Entry constructor (backward compatible)
    TimeDeleteFormScreen([object]$entry) : base("TimeDeleteForm", "Delete Time Entry") {
        $this.TimeEntry = $entry

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Time Entries", "Delete"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Y", "Confirm")
        $this.Footer.AddShortcut("N", "Cancel")
        $this.Footer.AddShortcut("Esc", "Back")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
    }

    [void] LoadData() {
        if (-not $this.TimeEntry) {
            $this.ShowError("No time entry selected")
            return
        }

        $this.ShowStatus("Ready to delete time entry")
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
        $highlightColor = $this.Header.GetThemedFg('Foreground.FieldFocused')
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedFg('Foreground.Muted')
        $errorColor = $this.Header.GetThemedFg('Foreground.Error')
        $reset = "`e[0m"

        $y = $contentRect.Y + 2

        if (-not $this.TimeEntry) {
            # No entry selected
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($warningColor)
            $sb.Append("No time entry selected")
            $sb.Append($reset)
            return $sb.ToString()
        }

        # Entry details
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($highlightColor)
        $sb.Append("Delete Time Entry:")
        $sb.Append($reset)
        $y += 2

        # ID
        $entryId = $this.TimeEntry.id
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("ID: ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sb.Append($entryId)
        $sb.Append($reset)
        $y++

        # Date
        $entryDate = $this.TimeEntry.date
        $rawDate = $(if ($entryDate) { $entryDate.ToString() } else { "" })
        $dateStr = $(if ($rawDate -eq 'today') {
            (Get-Date).ToString('yyyy-MM-dd')
        } elseif ($rawDate -eq 'tomorrow') {
            (Get-Date).AddDays(1).ToString('yyyy-MM-dd')
        } else {
            $rawDate
        })

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("Date: ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sb.Append($dateStr)
        $sb.Append($reset)
        $y++

        # Project
        $entryProject = $this.TimeEntry.project
        $entryId1 = $this.TimeEntry.id1
        $projectStr = $(if ($entryProject) { $entryProject.ToString() } else { if ($entryId1) { "#$entryId1" } else { "" } })
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("Project: ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sb.Append($projectStr)
        $sb.Append($reset)
        $y++

        # Hours
        $entryMinutes = $this.TimeEntry.minutes
        $hours = $(if ($entryMinutes) { [math]::Round($entryMinutes / 60.0, 2) } else { 0 })
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("Hours: ")
        $sb.Append($reset)
        $sb.Append($highlightColor)
        $sb.Append($hours.ToString("0.00"))
        $sb.Append($reset)
        $y++

        # Description
        $entryDescription = $this.TimeEntry.description
        if ($entryDescription) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
            $sb.Append($mutedColor)
            $sb.Append("Description: ")
            $sb.Append($reset)
            $sb.Append($textColor)
            $descStr = $entryDescription.ToString()
            $maxDescWidth = $contentRect.Width - 20
            if ($descStr.Length -gt $maxDescWidth) {
                $descStr = $descStr.Substring(0, $maxDescWidth - 3) + "..."
            }
            $sb.Append($descStr)
            $sb.Append($reset)
            $y++
        }

        $y += 2

        # Warning
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($errorColor)
        $sb.Append("WARNING: This action cannot be undone!")
        $sb.Append($reset)
        $y += 2

        # Confirmation prompt
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($highlightColor)
        $sb.Append("Press Y to confirm delete, N or Esc to cancel")
        $sb.Append($reset)

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        $keyChar = [char]::ToLower($keyInfo.KeyChar)
        switch ($keyChar) {
            'y' {
                $this._ConfirmDelete()
                return $true
            }
            'n' {
                $this._Cancel()
                return $true
            }
        }

        return $false
    }

    hidden [void] _ConfirmDelete() {
        if (-not $this.TimeEntry) {
            $this.ShowError("No time entry selected")
            return
        }

        try {
            # Load data
            $data = Get-PmcData

            # Remove entry
            $entryId = $this.TimeEntry.id
            $data.timelogs = @($data.timelogs | Where-Object { ($_.id) -ne $entryId })

            # Save
            # FIX: Use Save-PmcData instead of Set-PmcAllData
            Save-PmcData -Data $data

            $this.ShowSuccess("Time entry #$entryId deleted successfully")

            # Return to time list
            $global:PmcApp.PopScreen()
        } catch {
            $this.ShowError("Error deleting time entry: $_")
        }
    }

    hidden [void] _Cancel() {
        $this.ShowStatus("Delete cancelled")
        $global:PmcApp.PopScreen()
    }
}

# Entry point function for compatibility
function Show-TimeDeleteFormScreen {
    param(
        [object]$App,
        [object]$TimeEntry
    )

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = New-Object TimeDeleteFormScreen -ArgumentList $TimeEntry
    $App.PushScreen($screen)
}