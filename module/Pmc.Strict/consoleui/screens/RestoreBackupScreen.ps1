using namespace System.Collections.Generic
using namespace System.Text

# RestoreBackupScreen - Confirm and restore from backup
# Shows backup details and asks for confirmation

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Backup restore confirmation screen

.DESCRIPTION
Shows selected backup details and asks for confirmation.
Supports:
- Viewing backup information
- Confirming restore (Y key)
- Canceling restore (N/Esc key)
#>
class RestoreBackupScreen : PmcScreen {
    # Data
    [object]$Backup = $null
    [string]$InputBuffer = ""
    [bool]$ShowConfirm = $true

    # Constructor
    RestoreBackupScreen() : base("RestoreBackup", "Restore Backup") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Backups", "Restore"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Y", "Confirm")
        $this.Footer.AddShortcut("N", "Cancel")
        $this.Footer.AddShortcut("Esc", "Back")

        # Setup menu items
        $this._SetupMenus()
    }

    RestoreBackupScreen([object]$backup) : base("RestoreBackup", "Restore Backup") {
        $this.Backup = $backup

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Backups", "Restore"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Y", "Confirm")
        $this.Footer.AddShortcut("N", "Cancel")
        $this.Footer.AddShortcut("Esc", "Back")

        # Setup menu items
        $this._SetupMenus()
    }

    hidden [void] _SetupMenus() {
        # Tasks menu
        $tasksMenu = $this.MenuBar.Menus[0]
        $tasksMenu.Items.Add([PmcMenuItem]::new("Confirm Restore", 'Y', { $this._ConfirmRestore() }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Cancel", 'N', { $this._Cancel() }))

        # Help menu
        $helpMenu = $this.MenuBar.Menus[3]
        $helpMenu.Items.Add([PmcMenuItem]::new("About", 'A', { Write-Host "PMC TUI v1.0" }))
    }

    [void] LoadData() {
        if (-not $this.Backup) {
            $this.ShowError("No backup selected")
            return
        }

        # Validate backup file exists
        if (-not (Test-Path $this.Backup.Path)) {
            $this.ShowError("Backup file not found: $($this.Backup.Path)")
            return
        }

        $this.ShowStatus("Ready to restore backup")
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
        $reset = "`e[0m"

        $y = $contentRect.Y + 2

        if (-not $this.Backup) {
            # No backup selected
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($warningColor)
            $sb.Append("No backup selected")
            $sb.Append($reset)
            return $sb.ToString()
        }

        # Backup details
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($highlightColor)
        $sb.Append("Restore Backup Details:")
        $sb.Append($reset)
        $y += 2

        # Name
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("Name: ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sb.Append($this.Backup.Name)
        $sb.Append($reset)
        $y++

        # Type
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("Type: ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $typeLabel = if ($this.Backup.Type -eq "auto") { "Automatic" } else { "Manual" }
        $sb.Append($typeLabel)
        $sb.Append($reset)
        $y++

        # Modified
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("Date: ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sb.Append($this.Backup.Modified.ToString('yyyy-MM-dd HH:mm:ss'))
        $sb.Append($reset)
        $y++

        # Size
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("Size: ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sizeKB = [math]::Round($this.Backup.Size / 1KB, 2)
        $sb.Append("$sizeKB KB")
        $sb.Append($reset)
        $y++

        # Path
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($mutedColor)
        $sb.Append("Path: ")
        $sb.Append($reset)
        $sb.Append($mutedColor)
        $sb.Append($this.Backup.Path)
        $sb.Append($reset)
        $y += 2

        # Warning
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($warningColor)
        $sb.Append("WARNING: This will overwrite your current data!")
        $sb.Append($reset)
        $y += 2

        # Confirmation prompt
        if ($this.ShowConfirm) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($highlightColor)
            $sb.Append("Press Y to confirm restore, N or Esc to cancel")
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'Y' {
                $this._ConfirmRestore()
                return $true
            }
            'N' {
                $this._Cancel()
                return $true
            }
        }

        return $false
    }

    hidden [void] _ConfirmRestore() {
        if (-not $this.Backup) {
            $this.ShowError("No backup selected")
            return
        }

        try {
            # Load backup data
            $data = Get-Content $this.Backup.Path -Raw | ConvertFrom-Json

            # Save as current data
            Set-PmcAllData $data

            $this.ShowSuccess("Data restored successfully from $($this.Backup.Name)")

            # Return to backup list
            $global:PmcApp.PopScreen()
        } catch {
            $this.ShowError("Error restoring backup: $_")
        }
    }

    hidden [void] _Cancel() {
        $this.ShowStatus("Restore cancelled")
        $global:PmcApp.PopScreen()
    }
}

# Entry point function for compatibility
function Show-RestoreBackupScreen {
    param(
        [object]$App,
        [object]$Backup
    )

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [RestoreBackupScreen]::new($Backup)
    $App.PushScreen($screen)
}
