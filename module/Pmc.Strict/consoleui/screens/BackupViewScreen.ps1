using namespace System.Collections.Generic
using namespace System.Text

# BackupViewScreen - View and manage backup files
# Shows list of backup files with dates


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Backup management screen

.DESCRIPTION
Shows automatic backups (.bak1-.bak9) and manual backups.
Supports:
- Viewing backup list with dates and sizes (Up/Down arrows)
- Creating manual backup (C key)
- Restoring from backup (R key)
- Deleting backups (D key)
#>
class BackupViewScreen : PmcScreen {
    # Data
    [array]$Backups = @()
    [int]$SelectedIndex = 0

    # Constructor
    BackupViewScreen() : base("BackupView", "Backups") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Backups"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("C", "Create")
        $this.Footer.AddShortcut("R", "Restore")
        $this.Footer.AddShortcut("D", "Delete")
        $this.Footer.AddShortcut("Esc", "Back")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
    }

    BackupViewScreen([object]$container) : base("BackupView", "Backups", $container) {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Backups"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("C", "Create")
        $this.Footer.AddShortcut("R", "Restore")
        $this.Footer.AddShortcut("D", "Delete")
        $this.Footer.AddShortcut("Esc", "Back")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
    }

    [void] LoadData() {
        $this.ShowStatus("Loading backups...")

        try {
            $file = Get-PmcTaskFilePath
            $this.Backups = @()

            # Collect .bak1 through .bak9 files
            for ($i = 1; $i -le 9; $i++) {
                $bakFile = "$file.bak$i"
                if (Test-Path $bakFile) {
                    $info = Get-Item $bakFile
                    $this.Backups += [PSCustomObject]@{
                        Number = $i
                        Name = ".bak$i"
                        Path = $bakFile
                        Size = $info.Length
                        Modified = $info.LastWriteTime
                        Type = "auto"
                    }
                }
            }

            # Collect manual backups from backups directory
            $backupDir = Join-Path (Get-PmcRootPath) "backups"
            if (Test-Path $backupDir) {
                $manualBackups = @(Get-ChildItem $backupDir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 10)
                foreach ($backup in $manualBackups) {
                    $this.Backups += [PSCustomObject]@{
                        Number = $this.Backups.Count + 1
                        Name = $backup.Name
                        Path = $backup.FullName
                        Size = $backup.Length
                        Modified = $backup.LastWriteTime
                        Type = "manual"
                    }
                }
            }

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.Backups.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.Backups.Count - 1)
            }

            # Update status
            if ($this.Backups.Count -eq 0) {
                $this.ShowStatus("No backups found")
            } else {
                $this.ShowStatus("$($this.Backups.Count) backups available")
            }

        } catch {
            $this.ShowError("Failed to load backups: $_")
            $this.Backups = @()
        }
    }

    [string] RenderContent() {
        if ($this.Backups.Count -eq 0) {
            return $this._RenderEmptyState()
        }

        return $this._RenderBackupList()
    }

    hidden [string] _RenderEmptyState() {
        $sb = [System.Text.StringBuilder]::new(512)

        # Get content area
        if ($this.LayoutManager) {
            $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

            # Center message
            $message = "No backups found - Press C to create one"
            $x = $contentRect.X + [Math]::Floor(($contentRect.Width - $message.Length) / 2)
            $y = $contentRect.Y + [Math]::Floor($contentRect.Height / 2)

            $textColor = $this.Header.GetThemedFg('Foreground.Field')
            $reset = "`e[0m"

            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($textColor)
            $sb.Append($message)
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    hidden [string] _RenderBackupList() {
        $sb = [System.Text.StringBuilder]::new(4096)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedFg('Foreground.Field')
        $selectedBg = $this.Header.GetThemedBg('Background.FieldFocused', 80, 0)
        $selectedFg = $this.Header.GetThemedFg('Foreground.Field')
        $cursorColor = $this.Header.GetThemedFg('Foreground.FieldFocused')
        $mutedColor = $this.Header.GetThemedFg('Foreground.Muted')
        $headerColor = $this.Header.GetThemedFg('Foreground.Muted')
        $reset = "`e[0m"

        # Render column headers
        $headerY = $this.Header.Y + 3
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($headerColor)
        $sb.Append("TYPE    ")
        $sb.Append("NAME         ")
        $sb.Append("MODIFIED            ")
        $sb.Append("SIZE")
        $sb.Append($reset)

        # Render backup rows
        $startY = $headerY + 2
        $maxLines = $contentRect.Height - 4

        for ($i = 0; $i -lt [Math]::Min($this.Backups.Count, $maxLines); $i++) {
            $backup = $this.Backups[$i]
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

            # Type column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $typeLabel = if ($backup.Type -eq "auto") { "[Auto]" } else { "[Manual]" }
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($mutedColor)
            }
            $sb.Append($typeLabel.PadRight(8))
            $sb.Append($reset)
            $x += 8

            # Name column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }
            $sb.Append($backup.Name.PadRight(13))
            $sb.Append($reset)
            $x += 13

            # Modified column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($mutedColor)
            }
            $sb.Append($backup.Modified.ToString('yyyy-MM-dd HH:mm:ss').PadRight(20))
            $sb.Append($reset)
            $x += 20

            # Size column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sizeKB = [math]::Round($backup.Size / 1KB, 2)
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }
            $sb.Append("$sizeKB KB")
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        $keyChar = [char]::ToLower($keyInfo.KeyChar)
        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.Backups.Count - 1)) {
                    $this.SelectedIndex++
                    return $true
                }
            }
        }

        switch ($keyChar) {
            'c' {
                $this._CreateBackup()
                return $true
            }
            'r' {
                $this._RestoreBackup()
                return $true
            }
            'd' {
                $this._DeleteBackup()
                return $true
            }
        }

        return $false
    }

    hidden [void] _CreateBackup() {
        try {
            $file = Get-PmcTaskFilePath
            if (Test-Path $file) {
                # Rotate backups
                for ($i = 8; $i -ge 1; $i--) {
                    $src = "$file.bak$i"
                    $dst = "$file.bak$($i+1)"
                    if (Test-Path $src) {
                        Move-Item -Force $src $dst
                    }
                }
                Copy-Item $file "$file.bak1" -Force

                $this.ShowSuccess("Backup created successfully")
                $this.LoadData()
            } else {
                $this.ShowError("Data file not found")
            }
        } catch {
            $this.ShowError("Error creating backup: $_")
        }
    }

    hidden [void] _RestoreBackup() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Backups.Count) {
            $this.ShowError("No backup selected")
            return
        }

        if ($this.Backups.Count -gt 0) {
            $backup = $this.Backups[$this.SelectedIndex]
            . "$PSScriptRoot/RestoreBackupScreen.ps1"
            $screen = New-Object RestoreBackupScreen
            $screen.SetBackupFile($backup.path)
            $global:PmcApp.PushScreen($screen)
        }
    }

    hidden [void] _DeleteBackup() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Backups.Count) {
            $this.ShowError("No backup selected")
            return
        }

        $backup = $this.Backups[$this.SelectedIndex]

        try {
            if (Test-Path $backup.Path) {
                Remove-Item $backup.Path -Force -ErrorAction Stop
                $this.ShowSuccess("Backup deleted: $($backup.Name)")
                $this.LoadData()
            } else {
                $this.ShowError("Backup file not found")
            }
        } catch {
            $this.ShowError("Error deleting backup: $_")
        }
    }
}

# Entry point function for compatibility
function Show-BackupViewScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [BackupViewScreen]::new()
    $App.PushScreen($screen)
}
