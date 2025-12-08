# SimpleFilePicker.ps1 - Simple file/folder picker that works with SpeedTUI

using namespace System.Collections.Generic

Set-StrictMode -Version Latest

class SimpleFilePicker {
    [string]$CurrentPath = ''
    [List[object]]$Items = $null
    [int]$SelectedIndex = 0
    [int]$ScrollOffset = 0
    [bool]$IsComplete = $false
    [bool]$Result = $false
    [string]$SelectedPath = ''
    [bool]$DirectoriesOnly = $false

    SimpleFilePicker([string]$startPath, [bool]$directoriesOnly) {
        $this.DirectoriesOnly = $directoriesOnly
        $this.Items = [List[object]]::new()

        # Validate and set start path
        if ([string]::IsNullOrWhiteSpace($startPath) -or -not (Test-Path $startPath)) {
            $this.CurrentPath = [Environment]::GetFolderPath('UserProfile')
        } else {
            if (Test-Path -Path $startPath -PathType Leaf) {
                # If it's a file, use parent directory
                $this.CurrentPath = Split-Path -Parent $startPath
            } else {
                $this.CurrentPath = $startPath
            }
        }

        $this.LoadItems()
    }

    [void] LoadItems() {
        $this.Items.Clear()
        $this.SelectedIndex = 0
        $this.ScrollOffset = 0

        try {
            # Add parent directory
            $parent = Split-Path -Parent $this.CurrentPath
            if ($parent) {
                $this.Items.Add(@{
                    Name = '..'
                    Path = $parent
                    IsDirectory = $true
                })
            }

            # Get directories
            $dirs = Get-ChildItem -Path $this.CurrentPath -Directory -ErrorAction SilentlyContinue | Sort-Object Name
            foreach ($dir in $dirs) {
                $this.Items.Add(@{
                    Name = $dir.Name
                    Path = $dir.FullName
                    IsDirectory = $true
                })
            }

            # Get files if not directories-only
            if (-not $this.DirectoriesOnly) {
                $files = Get-ChildItem -Path $this.CurrentPath -File -ErrorAction SilentlyContinue | Sort-Object Name
                foreach ($file in $files) {
                    $this.Items.Add(@{
                        Name = $file.Name
                        Path = $file.FullName
                        IsDirectory = $false
                    })
                }
            }
        } catch {
            # On error, go to home
            $this.CurrentPath = [Environment]::GetFolderPath('UserProfile')
            $this.LoadItems()
        }
    }

    [bool] HandleInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                    # Adjust scroll if needed
                    if ($this.SelectedIndex -lt $this.ScrollOffset) {
                        $this.ScrollOffset = $this.SelectedIndex
                    }
                }
                return $true
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.Items.Count - 1)) {
                    $this.SelectedIndex++
                    # Adjust scroll if needed (show 15 items at a time)
                    if ($this.SelectedIndex -ge ($this.ScrollOffset + 15)) {
                        $this.ScrollOffset = $this.SelectedIndex - 14
                    }
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
                    $this.LoadItems()
                } else {
                    # Select file
                    $this.SelectedPath = $selected.Path
                    $this.Result = $true
                    $this.IsComplete = $true
                }
                return $true
            }
            'Spacebar' {
                # Select current directory
                $this.SelectedPath = $this.CurrentPath
                $this.Result = $true
                $this.IsComplete = $true
                return $true
            }
            'Escape' {
                $this.Result = $false
                $this.IsComplete = $true
                return $true
            }
        }
        return $false
    }

    [string] Render() {
        $output = [System.Text.StringBuilder]::new()

        # Box drawing characters
        $esc = [char]27
        $reset = "$esc[0m"

        # Clear screen
        $output.Append("$esc[2J$esc[H")

        # Title
        $title = if ($this.DirectoriesOnly) { "Select Folder" } else { "Select File" }
        $output.AppendLine("$esc[1;36m=== $title ===$reset")
        $output.AppendLine("$esc[37mCurrent: $($this.CurrentPath)$reset")
        $output.AppendLine("")

        # Show items (max 15 visible)
        $visibleCount = [Math]::Min(15, $this.Items.Count)
        $endIndex = [Math]::Min($this.ScrollOffset + $visibleCount, $this.Items.Count)

        for ($i = $this.ScrollOffset; $i -lt $endIndex; $i++) {
            $item = $this.Items[$i]
            $prefix = if ($item.IsDirectory) { "[DIR]" } else { "[FILE]" }

            if ($i -eq $this.SelectedIndex) {
                # Highlighted
                $output.AppendLine("$esc[1;30;47m > $prefix $($item.Name)$reset")
            } else {
                # Normal
                $color = if ($item.IsDirectory) { "33" } else { "37" }
                $output.AppendLine("$esc[${color}m   $prefix $($item.Name)$reset")
            }
        }

        # Instructions
        $output.AppendLine("")
        $output.AppendLine("$esc[36mUp/Down: Navigate | Enter: Open/Select | Space: Select Current Dir | Esc: Cancel$reset")

        return $output.ToString()
    }
}
