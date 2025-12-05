# PmcFilePicker - Simple directory/file picker widget
# Keyboard navigation with Up/Down, Enter to select, Esc to cancel

using namespace System.Text

Set-StrictMode -Version Latest

# Ensure PmcWidget is loaded
if (-not ([System.Management.Automation.PSTypeName]'PmcWidget').Type) {
    . "$PSScriptRoot/PmcWidget.ps1"
}

class PmcFilePicker : PmcWidget {
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

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcFilePicker._LoadItems: CurrentPath='$($this.CurrentPath)'"
        }

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
            $dirs = @(Get-ChildItem -Path $this.CurrentPath -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcFilePicker: Found $($dirs.Count) directories"
            }
            foreach ($dir in $dirs) {
                $this.Items += @{
                    Name = $dir.Name
                    Path = $dir.FullName
                    IsDirectory = $true
                }
            }

            # Get files if not directories-only
            if (-not $this.DirectoriesOnly) {
                $files = @(Get-ChildItem -Path $this.CurrentPath -File -ErrorAction SilentlyContinue | Sort-Object Name)
                foreach ($file in $files) {
                    $this.Items += @{
                        Name = $file.Name
                        Path = $file.FullName
                        IsDirectory = $false
                    }
                }
            }

            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcFilePicker: Total items loaded: $($this.Items.Count)"
            }
        } catch {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcFilePicker: ERROR loading items: $_"
            }
            # If can't read directory, go to home
            $this.CurrentPath = [Environment]::GetFolderPath('UserProfile')
            $this._LoadItems()
        }
    }

    [string] Render([int]$termWidth, [int]$termHeight) {
        $sb = [System.Text.StringBuilder]::new(4096)

        # Position on the right side of the screen instead of centered
        $x = $termWidth - $this.Width - 2
        $y = 2

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcFilePicker.Render: termWidth=$termWidth, termHeight=$termHeight, x=$x, y=$y, Width=$($this.Width), Height=$($this.Height)"
        }

        # Colors - MAXIMUM CONTRAST for visibility testing
        $bgColor = "`e[48;5;16m"         # Pure black background
        $fgColor = "`e[38;5;231m"        # Pure white text
        $borderColor = "`e[38;5;255m"    # Bright white border
        $highlightBg = "`e[48;5;226m"    # Bright yellow highlight background
        $highlightFg = "`e[38;5;16m"     # Black highlight text
        $dirColor = "`e[38;5;226m"       # Bright yellow for directories
        $fileColor = "`e[38;5;231m"      # Bright white for files
        $reset = "`e[0m"

        # Draw shadow
        for ($row = 0; $row -lt $this.Height; $row++) {
            $sb.Append($this.BuildMoveTo($x + 2, $y + $row + 1))
            $sb.Append("`e[48;2;0;0;0m")
            $sb.Append(" " * $this.Width)
        }

        # Draw dialog box
        for ($row = 0; $row -lt $this.Height; $row++) {
            $sb.Append($this.BuildMoveTo($x, $y + $row))
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
        $sb.Append($this.BuildMoveTo($titleX, $y + 1))
        $sb.Append($bgColor)
        $sb.Append($highlightFg)
        $sb.Append($title)

        # Current path
        $displayPath = $this.CurrentPath
        $maxPathWidth = $this.Width - 6
        if ($displayPath.Length > $maxPathWidth) {
            $displayPath = "..." + $displayPath.Substring($displayPath.Length - $maxPathWidth + 3)
        }
        $sb.Append($this.BuildMoveTo($x + 3, $y + 2))
        $sb.Append($bgColor)
        $sb.Append($fgColor)
        $sb.Append($displayPath)

        # Items list
        $listStartY = $y + 4
        $maxItems = $this.Height - 7

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcFilePicker.Render: About to render items (Count=$($this.Items.Count), maxItems=$maxItems, x=$x, y=$y, listStartY=$listStartY)"
        }

        # Render ALL lines to ensure background fills properly
        for ($i = 0; $i -lt $maxItems; $i++) {
            $itemY = $listStartY + $i

            if ($i -lt $this.Items.Count) {
                $item = $this.Items[$i]
                $isSelected = ($i -eq $this.SelectedIndex)

                if ($global:PmcTuiLogFile -and $i -lt 3) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcFilePicker: Rendering item ${i} '$($item.Name)' at y=$itemY"
                }

                # Selection indicator
                $sb.Append($this.BuildMoveTo($x + 2, $itemY))
                if ($isSelected) {
                    $sb.Append($highlightBg)
                    $sb.Append($highlightFg)
                    $sb.Append(">")
                } else {
                    $sb.Append($bgColor)
                    $sb.Append($dirColor)
                    $sb.Append(" ")
                }

                # Item name
                $sb.Append($this.BuildMoveTo($x + 4, $itemY))
                if ($isSelected) {
                    $sb.Append($highlightBg)  # Yellow background for selected
                    $sb.Append($highlightFg)  # Black text for selected
                } else {
                    $sb.Append($bgColor)      # Black background for unselected
                    $sb.Append($dirColor)     # Yellow text for unselected
                }

                $displayName = $item.Name
                if ($item.IsDirectory) {
                    $displayName = "📁 $displayName"
                }
                $maxNameWidth = $this.Width - 8
                if ($displayName.Length > $maxNameWidth) {
                    $displayName = $displayName.Substring(0, $maxNameWidth - 3) + "..."
                }

                # Append the text
                $sb.Append($displayName)

                # Manually add padding spaces with background color still active
                $paddingNeeded = $maxNameWidth - $displayName.Length
                if ($paddingNeeded -gt 0) {
                    $sb.Append(" " * $paddingNeeded)
                }

                $sb.Append($reset)  # Reset colors after entire line including padding

                if ($global:PmcTuiLogFile -and $i -eq 0) {
                    # Get last 200 chars of sb to see what was just added
                    $sbStr = $sb.ToString()
                    $tail = if ($sbStr.Length -gt 200) { $sbStr.Substring($sbStr.Length - 200) } else { $sbStr }
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcFilePicker: Item 0 - Last 200 chars: $($tail -replace "`e", '<ESC>')"
                }
            } else {
                # Empty line - fill with background
                $sb.Append($this.BuildMoveTo($x + 2, $itemY))
                $sb.Append($bgColor)
                $sb.Append(" " * ($this.Width - 4))
            }
        }

        # Instructions
        $instructions = "↑/↓: Move | Enter: Open/Select | Space: Select Current | Esc: Cancel"
        $instructionsY = $y + $this.Height - 2
        $instructionsX = $x + [Math]::Floor(($this.Width - $instructions.Length) / 2)
        $sb.Append($this.BuildMoveTo($instructionsX, $instructionsY))
        $sb.Append($bgColor)
        $sb.Append($fileColor)
        $sb.Append($instructions)

        $sb.Append($reset)
        $output = $sb.ToString()

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcFilePicker.Render: Generated output length=$($output.Length)"

            # COMPREHENSIVE DEBUG OUTPUT
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] === FULL RENDER DEBUG ==="
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Items.Count=$($this.Items.Count)"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] SelectedIndex=$($this.SelectedIndex)"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Position: x=$x y=$y Width=$($this.Width) Height=$($this.Height)"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Terminal: ${termWidth}x${termHeight}"

            # Show color codes being used
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Colors:"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')]   bgColor: $($bgColor -replace "`e", '<ESC>')"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')]   dirColor: $($dirColor -replace "`e", '<ESC>')"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')]   highlightBg: $($highlightBg -replace "`e", '<ESC>')"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')]   highlightFg: $($highlightFg -replace "`e", '<ESC>')"

            # Show first 3 items
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] First 3 items:"
            for ($i = 0; $i -lt [Math]::Min(3, $this.Items.Count); $i++) {
                $item = $this.Items[$i]
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')]   [$i] Name='$($item.Name)' IsDir=$($item.IsDirectory)"
            }

            # Find emoji in output
            $emojiPos = $output.IndexOf("📁")
            if ($emojiPos -gt 0) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] EMOJI FOUND at position $emojiPos"
                $start = [Math]::Max(0, $emojiPos - 100)
                $len = [Math]::Min(300, $output.Length - $start)
                $sample = $output.Substring($start, $len)
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Output around emoji:"
                Add-Content -Path $global:PmcTuiLogFile -Value "    $($sample -replace "`e", '<ESC>')"
            } else {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] !!! NO EMOJI FOUND IN OUTPUT !!!"
                # Show first 500 chars
                $sample = $output.Substring(0, [Math]::Min(500, $output.Length))
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] First 500 chars of output:"
                Add-Content -Path $global:PmcTuiLogFile -Value "    $($sample -replace "`e", '<ESC>')"
            }

            # Search for item names in output
            if ($this.Items.Count -gt 0) {
                $firstItemName = $this.Items[0].Name
                $namePos = $output.IndexOf($firstItemName)
                if ($namePos -gt 0) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] First item name '$firstItemName' FOUND at position $namePos"
                } else {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] !!! First item name '$firstItemName' NOT FOUND in output !!!"
                }
            }

            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] === END RENDER DEBUG ==="
        }

        return $output
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcFilePicker.HandleInput: Key=$($keyInfo.Key) SelectedIndex=$($this.SelectedIndex) ItemCount=$($this.Items.Count)"
        }

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
            'Spacebar' {
                # Space selects current directory
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcFilePicker: SPACE pressed - selecting CurrentPath='$($this.CurrentPath)'"
                }
                $this.SelectedPath = $this.CurrentPath
                $this.Result = $true
                $this.IsComplete = $true

                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] PmcFilePicker: After SPACE - SelectedPath='$($this.SelectedPath)' Result=$($this.Result) IsComplete=$($this.IsComplete)"
                }
                return $true
            }
        }
        return $false
    }
}
