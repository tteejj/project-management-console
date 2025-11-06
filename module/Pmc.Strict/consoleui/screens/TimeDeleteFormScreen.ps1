using namespace System.Collections.Generic
using namespace System.Text

# TimeDeleteFormScreen - Delete time entry confirmation
# Shows entry details and asks for confirmation

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

    # Constructor
    TimeDeleteFormScreen() : base("TimeDeleteForm", "Delete Time Entry") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Time Entries", "Delete"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Y", "Confirm")
        $this.Footer.AddShortcut("N", "Cancel")
        $this.Footer.AddShortcut("Esc", "Back")

        # Setup menu items
        $this._SetupMenus()
    }

    TimeDeleteFormScreen([object]$entry) : base("TimeDeleteForm", "Delete Time Entry") {
        $this.TimeEntry = $entry

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Time Entries", "Delete"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Y", "Confirm")
        $this.Footer.AddShortcut("N", "Cancel")
        $this.Footer.AddShortcut("Esc", "Back")

        # Setup menu items
        $this._SetupMenus()
    }

    hidden [void] _SetupMenus() {
        # Capture $this in a variable so scriptblocks can access it
        $screen = $this

        # Tasks menu - Navigate to different task views
        $tasksMenu = $this.MenuBar.Menus[0]
        $tasksMenu.Items.Add([PmcMenuItem]::new("Task List", 'L', { Write-Host "Task List not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Tomorrow", 'T', { Write-Host "Tomorrow view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Upcoming", 'U', { Write-Host "Upcoming view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Next Actions", 'N', { Write-Host "Next Actions view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("No Due Date", 'D', { Write-Host "No Due Date view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::Separator())
        $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', { Write-Host "Month view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Agenda View", 'A', { Write-Host "Agenda view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Burndown Chart", 'B', { Write-Host "Burndown chart not implemented" }))

        # Projects menu
        $projectsMenu = $this.MenuBar.Menus[1]
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project List", 'L', { Write-Host "Project list not implemented" }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Stats", 'S', { Write-Host "Project stats not implemented" }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Info", 'I', { Write-Host "Project info not implemented" }))

        # Options menu
        $optionsMenu = $this.MenuBar.Menus[2]
        $optionsMenu.Items.Add([PmcMenuItem]::new("Theme Editor", 'T', { Write-Host "Theme editor not implemented" }))
        $optionsMenu.Items.Add([PmcMenuItem]::new("Settings", 'S', { Write-Host "Settings not implemented" }))

        # Help menu
        $helpMenu = $this.MenuBar.Menus[3]
        $helpMenu.Items.Add([PmcMenuItem]::new("Help View", 'H', { Write-Host "Help view not implemented" }))
        $helpMenu.Items.Add([PmcMenuItem]::new("About", 'A', { Write-Host "PMC TUI v1.0" }))
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
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $highlightColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $errorColor = $this.Header.GetThemedAnsi('Error', $false)
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
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("ID: ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sb.Append($this.TimeEntry.id)
        $sb.Append($reset)
        $y++

        # Date
        $rawDate = if ($this.TimeEntry.date) { $this.TimeEntry.date.ToString() } else { "" }
        $dateStr = if ($rawDate -eq 'today') {
            (Get-Date).ToString('yyyy-MM-dd')
        } elseif ($rawDate -eq 'tomorrow') {
            (Get-Date).AddDays(1).ToString('yyyy-MM-dd')
        } else {
            $rawDate
        }

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("Date: ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sb.Append($dateStr)
        $sb.Append($reset)
        $y++

        # Project
        $projectStr = if ($this.TimeEntry.project) { $this.TimeEntry.project.ToString() } else { if ($this.TimeEntry.id1) { "#$($this.TimeEntry.id1)" } else { "" } }
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("Project: ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sb.Append($projectStr)
        $sb.Append($reset)
        $y++

        # Hours
        $hours = if ($this.TimeEntry.minutes) { [math]::Round($this.TimeEntry.minutes / 60.0, 2) } else { 0 }
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("Hours: ")
        $sb.Append($reset)
        $sb.Append($highlightColor)
        $sb.Append($hours.ToString("0.00"))
        $sb.Append($reset)
        $y++

        # Description
        if ($this.TimeEntry.PSObject.Properties['description'] -and $this.TimeEntry.description) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
            $sb.Append($mutedColor)
            $sb.Append("Description: ")
            $sb.Append($reset)
            $sb.Append($textColor)
            $descStr = $this.TimeEntry.description.ToString()
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

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'Y' {
                $this._ConfirmDelete()
                return $true
            }
            'N' {
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
            $data = Get-PmcAllData

            # Remove entry
            $entryId = $this.TimeEntry.id
            $data.timelogs = @($data.timelogs | Where-Object { $_.id -ne $entryId })

            # Save
            Set-PmcAllData $data

            $this.ShowSuccess("Time entry #$entryId deleted successfully")

            # Return to time list
            # TODO: Pop screen to go back
        } catch {
            $this.ShowError("Error deleting time entry: $_")
        }
    }

    hidden [void] _Cancel() {
        $this.ShowStatus("Delete cancelled")
        # TODO: Pop screen to go back
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

    $screen = [TimeDeleteFormScreen]::new($TimeEntry)
    $App.PushScreen($screen)
}
