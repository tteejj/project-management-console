# PmcFilePicker - Simple directory/file picker widget
# Keyboard navigation with Up/Down, Enter to select, Esc to cancel

class PmcFilePicker {
    [string]$CurrentPath = ''
    [array]$Items = @()
    [int]$SelectedIndex = 0
    [bool]$IsComplete = $false
    [bool]$Result = $false
    [string]$SelectedPath = ''
    [bool]$DirectoriesOnly = $true
    [int]$Width = 60
    [int]$Height = 20

    PmcFilePicker([string]$startPath, [bool]$directoriesOnly) {
        $this.DirectoriesOnly = $directoriesOnly

        # Start at provided path or home
        if ([string]::IsNullOrWhiteSpace($startPath) -or -not (Test-Path $startPath)) {
            $this.CurrentPath = [Environment]::GetFolderPath('UserProfile')
        } else {
            $this.CurrentPath = $startPath
        }

        $this._LoadItems()
    }

    hidden [void] _LoadItems() {
        $this.Items = @()
        $this.SelectedIndex = 0

        try {
            # Add parent directory entry
            $parent = Split-Path -Parent $this.CurrentPath
            if ($parent) {
                $this.Items += @{
                    Name = '..'
                    Path = $parent
                    IsDirectory = $true
                }
            }

            # Get directories
            $dirs = Get-ChildItem -Path $this.CurrentPath -Directory -ErrorAction SilentlyContinue | Sort-Object Name
            foreach ($dir in $dirs) {
                $this.Items += @{
                    Name = $dir.Name
                    Path = $dir.FullName
                    IsDirectory = $true
                }
            }

            # Get files if not directories-only
            if (-not $this.DirectoriesOnly) {
                $files = Get-ChildItem -Path $this.CurrentPath -File -ErrorAction SilentlyContinue | Sort-Object Name
                foreach ($file in $files) {
                    $this.Items += @{
                        Name = $file.Name
                        Path = $file.FullName
                        IsDirectory = $false
                    }
                }
            }
        } catch {
            # If can't read directory, go to home
            $this.CurrentPath = [Environment]::GetFolderPath('UserProfile')
            $this._LoadItems()
        }
    }

    [string] Render([int]$termWidth, [int]$termHeight) {
        $sb = [System.Text.StringBuilder]::new(4096)

        # Calculate centered position
        $x = [Math]::Floor(($termWidth - $this.Width) / 2)
        $y = [Math]::Floor(($termHeight - $this.Height) / 2)

        # Colors
        $bgColor = "`e[48;2;30;30;30m"
        $fgColor = "`e[38;2;255;255;255m"
        $borderColor = "`e[38;2;150;150;150m"
        $highlightBg = "`e[48;2;0;100;180m"
        $highlightFg = "`e[38;2;255;255;255m"
        $dirColor = "`e[38;2;100;200;255m"
        $fileColor = "`e[38;2;200;200;200m"
        $reset = "`e[0m"

        # Draw shadow
        for ($row = 0; $row -lt $this.Height; $row++) {
            $sb.Append("`e[$($y + $row + 1);$($x + 2)H")
            $sb.Append("`e[48;2;0;0;0m")
            $sb.Append(" " * $this.Width)
        }

        # Draw dialog box
        for ($row = 0; $row -lt $this.Height; $row++) {
            $sb.Append("`e[$($y + $row);${x}H")
            $sb.Append($bgColor)
            $sb.Append($borderColor)

            if ($row -eq 0) {
                $sb.Append("┌" + ("─" * ($this.Width - 2)) + "┐")
            }
            elseif ($row -eq $this.Height - 1) {
                $sb.Append("└" + ("─" * ($this.Width - 2)) + "┘")
            }
            else {
                $sb.Append("│")
                $sb.Append($fgColor)
                $sb.Append(" " * ($this.Width - 2))
                $sb.Append($borderColor)
                $sb.Append("│")
            }
        }

        # Title
        $title = "Select Directory"
        $titleX = $x + [Math]::Floor(($this.Width - $title.Length) / 2)
        $sb.Append("`e[$($y + 1);${titleX}H")
        $sb.Append($bgColor)
        $sb.Append($highlightFg)
        $sb.Append($title)

        # Current path
        $displayPath = $this.CurrentPath
        $maxPathWidth = $this.Width - 6
        if ($displayPath.Length > $maxPathWidth) {
            $displayPath = "..." + $displayPath.Substring($displayPath.Length - $maxPathWidth + 3)
        }
        $sb.Append("`e[$($y + 2);$($x + 3)H")
        $sb.Append($bgColor)
        $sb.Append($fgColor)
        $sb.Append($displayPath)

        # Items list
        $listStartY = $y + 4
        $maxItems = $this.Height - 7

        # Render ALL lines to ensure background fills properly
        for ($i = 0; $i -lt $maxItems; $i++) {
            $itemY = $listStartY + $i

            if ($i -lt $this.Items.Count) {
                $item = $this.Items[$i]
                $isSelected = ($i -eq $this.SelectedIndex)

                # Selection indicator
                $sb.Append("`e[$itemY;$($x + 2)H")
                $sb.Append($bgColor)
                if ($isSelected) {
                    $sb.Append($highlightFg)
                    $sb.Append(">")
                } else {
                    $sb.Append(" ")
                }

                # Item name
                $sb.Append("`e[$itemY;$($x + 4)H")
                if ($isSelected) {
                    $sb.Append($highlightBg)
                    $sb.Append($highlightFg)
                } else {
                    $sb.Append($bgColor)
                    if ($item.IsDirectory) {
                        $sb.Append($dirColor)
                    } else {
                        $sb.Append($fileColor)
                    }
                }

                $displayName = $item.Name
                if ($item.IsDirectory) {
                    $displayName = "📁 $displayName"
                }
                $maxNameWidth = $this.Width - 8
                if ($displayName.Length > $maxNameWidth) {
                    $displayName = $displayName.Substring(0, $maxNameWidth - 3) + "..."
                }
                $sb.Append($displayName.PadRight($maxNameWidth))
            } else {
                # Empty line - fill with background
                $sb.Append("`e[$itemY;$($x + 2)H")
                $sb.Append($bgColor)
                $sb.Append(" " * ($this.Width - 4))
            }
        }

        # Instructions
        $instructions = "↑/↓: Navigate | Enter: Select | Esc: Cancel"
        $instructionsY = $y + $this.Height - 2
        $instructionsX = $x + [Math]::Floor(($this.Width - $instructions.Length) / 2)
        $sb.Append("`e[$instructionsY;${instructionsX}H")
        $sb.Append($bgColor)
        $sb.Append($fileColor)
        $sb.Append($instructions)

        $sb.Append($reset)
        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                }
                return $true
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.Items.Count - 1)) {
                    $this.SelectedIndex++
                }
                return $true
            }
            'Enter' {
                if ($this.Items.Count -eq 0) {
                    return $true
                }

                $selected = $this.Items[$this.SelectedIndex]
                if ($selected.IsDirectory) {
                    # Navigate into directory
                    $this.CurrentPath = $selected.Path
                    $this._LoadItems()
                } else {
                    # Select file
                    $this.SelectedPath = $selected.Path
                    $this.Result = $true
                    $this.IsComplete = $true
                }
                return $true
            }
            'Escape' {
                $this.Result = $false
                $this.IsComplete = $true
                return $true
            }
            'Space' {
                # Space selects current directory
                $this.SelectedPath = $this.CurrentPath
                $this.Result = $true
                $this.IsComplete = $true
                return $true
            }
        }
        return $false
    }
}
