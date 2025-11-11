using namespace System.Collections.Generic
using namespace System.Text

# ClearBackupsScreen - Clear all backup files
# Shows count of backups and asks for confirmation


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Clear backups confirmation screen

.DESCRIPTION
Shows count of automatic and manual backups and asks for confirmation.
Supports:
- Confirming delete all (Y key)
- Canceling (N/Esc key)
#>
class ClearBackupsScreen : PmcScreen {
    # Data
    [int]$AutoBackupCount = 0
    [int]$ManualBackupCount = 0
    [long]$AutoTotalSize = 0
    [long]$ManualTotalSize = 0
    [string]$BackupDir = ""
    [string]$MainFile = ""

    # Constructor
    ClearBackupsScreen() : base("ClearBackups", "Clear All Backups") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Backups", "Clear All"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("A", "Auto Only")
        $this.Footer.AddShortcut("M", "Manual Only")
        $this.Footer.AddShortcut("B", "Both")
        $this.Footer.AddShortcut("Esc", "Cancel")

        # Setup menu items
        $this._SetupMenus()
    }

    hidden [void] _SetupMenus() {
        # Tasks menu
        $tasksMenu = $this.MenuBar.Menus[0]
        $tasksMenu.Items.Add([PmcMenuItem]::new("Clear Auto Backups", 'A', { $this._ClearAutoBackups() }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Clear Manual Backups", 'M', { $this._ClearManualBackups() }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Clear Both", 'B', { $this._ClearBothBackups() }))
        $tasksMenu.Items.Add([PmcMenuItem]::Separator())
        $tasksMenu.Items.Add([PmcMenuItem]::new("Cancel", 'N', { $this._Cancel() }))

        # Help menu
        $helpMenu = $this.MenuBar.Menus[3]
        $helpMenu.Items.Add([PmcMenuItem]::new("About", 'A', { Write-Host "PMC TUI v1.0" }))
    }

    [void] LoadData() {
        $this.ShowStatus("Loading backup information...")

        try {
            $this.MainFile = Get-PmcTaskFilePath
            $this.BackupDir = Join-Path (Get-PmcRootPath) "backups"

            # Count automatic backups
            $this.AutoBackupCount = 0
            $this.AutoTotalSize = 0
            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$($this.MainFile).bak$i"
                if (Test-Path $bakFile) {
                    $this.AutoBackupCount++
                    $this.AutoTotalSize += (Get-Item $bakFile).Length
                }
            }

            # Count manual backups
            $this.ManualBackupCount = 0
            $this.ManualTotalSize = 0
            if (Test-Path $this.BackupDir) {
                $manualBackups = @(Get-ChildItem $this.BackupDir -Filter "*.json")
                $this.ManualBackupCount = $manualBackups.Count
                if ($manualBackups.Count -gt 0) {
                    $this.ManualTotalSize = ($manualBackups | Measure-Object -Property Length -Sum).Sum
                }
            }

            $totalCount = $this.AutoBackupCount + $this.ManualBackupCount
            $this.ShowStatus("$totalCount total backups found")

        } catch {
            $this.ShowError("Failed to load backup information: $_")
        }
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

        # Title
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($highlightColor)
        $sb.Append("Clear Backup Files")
        $sb.Append($reset)
        $y += 2

        # Automatic backups section
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($mutedColor)
        $sb.Append("Automatic backups (.bak1 - .bak9):")
        $sb.Append($reset)
        $y++

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($textColor)
        $sb.Append("Count: $($this.AutoBackupCount) files")
        $sb.Append($reset)
        $y++

        $autoSizeMB = [math]::Round($this.AutoTotalSize / 1MB, 2)
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($textColor)
        $sb.Append("Total size: $autoSizeMB MB")
        $sb.Append($reset)
        $y += 2

        # Manual backups section
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($mutedColor)
        $sb.Append("Manual backups (backups directory):")
        $sb.Append($reset)
        $y++

        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($textColor)
        $sb.Append("Count: $($this.ManualBackupCount) files")
        $sb.Append($reset)
        $y++

        $manualSizeMB = [math]::Round($this.ManualTotalSize / 1MB, 2)
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $y))
        $sb.Append($textColor)
        $sb.Append("Total size: $manualSizeMB MB")
        $sb.Append($reset)
        $y += 2

        # Warning
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($errorColor)
        $sb.Append("WARNING: This action cannot be undone!")
        $sb.Append($reset)
        $y += 2

        # Options
        if ($this.AutoBackupCount -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($warningColor)
            $sb.Append("Press 'A' to clear automatic backups (.bak files)")
            $sb.Append($reset)
            $y++
        }

        if ($this.ManualBackupCount -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($warningColor)
            $sb.Append("Press 'M' to clear manual backups (backups directory)")
            $sb.Append($reset)
            $y++
        }

        if ($this.AutoBackupCount -gt 0 -and $this.ManualBackupCount -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($errorColor)
            $sb.Append("Press 'B' to clear BOTH")
            $sb.Append($reset)
            $y++
        }

        if ($this.AutoBackupCount -eq 0 -and $this.ManualBackupCount -eq 0) {
            $y++
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("No backups to clear")
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        $keyChar = [char]::ToLower($keyInfo.KeyChar)
        switch ($keyChar) {
            'a' {
                $this._ClearAutoBackups()
                return $true
            }
            'm' {
                $this._ClearManualBackups()
                return $true
            }
            'b' {
                $this._ClearBothBackups()
                return $true
            }
            'n' {
                $this._Cancel()
                return $true
            }
        }

        return $false
    }

    hidden [void] _ClearAutoBackups() {
        if ($this.AutoBackupCount -eq 0) {
            $this.ShowStatus("No automatic backups to clear")
            return
        }

        try {
            $deleted = 0
            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$($this.MainFile).bak$i"
                if (Test-Path $bakFile) {
                    Remove-Item $bakFile -Force
                    $deleted++
                }
            }

            $this.ShowSuccess("Deleted $deleted automatic backup files")
            $this.LoadData()
        } catch {
            $this.ShowError("Error clearing automatic backups: $_")
        }
    }

    hidden [void] _ClearManualBackups() {
        if ($this.ManualBackupCount -eq 0) {
            $this.ShowStatus("No manual backups to clear")
            return
        }

        try {
            if (Test-Path $this.BackupDir) {
                $files = Get-ChildItem $this.BackupDir -Filter "*.json"
                $deleted = 0
                foreach ($file in $files) {
                    Remove-Item $file.FullName -Force
                    $deleted++
                }

                $this.ShowSuccess("Deleted $deleted manual backup files")
                $this.LoadData()
            }
        } catch {
            $this.ShowError("Error clearing manual backups: $_")
        }
    }

    hidden [void] _ClearBothBackups() {
        if ($this.AutoBackupCount -eq 0 -and $this.ManualBackupCount -eq 0) {
            $this.ShowStatus("No backups to clear")
            return
        }

        try {
            $totalDeleted = 0

            # Clear automatic backups
            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$($this.MainFile).bak$i"
                if (Test-Path $bakFile) {
                    Remove-Item $bakFile -Force
                    $totalDeleted++
                }
            }

            # Clear manual backups
            if (Test-Path $this.BackupDir) {
                $files = Get-ChildItem $this.BackupDir -Filter "*.json"
                foreach ($file in $files) {
                    Remove-Item $file.FullName -Force
                    $totalDeleted++
                }
            }

            $this.ShowSuccess("Deleted $totalDeleted backup files")
            $this.LoadData()
        } catch {
            $this.ShowError("Error clearing backups: $_")
        }
    }

    hidden [void] _Cancel() {
        $this.ShowStatus("Clear cancelled")
        $global:PmcApp.PopScreen()
    }
}

# Entry point function for compatibility
function Show-ClearBackupsScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [ClearBackupsScreen]::new()
    $App.PushScreen($screen)
}
