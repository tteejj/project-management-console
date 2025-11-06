using namespace System.Collections.Generic
using namespace System.Text

# MultiSelectModeScreen - Multi-select task operations
# Task list with checkboxes for bulk operations

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Multi-select mode for bulk task operations

.DESCRIPTION
Shows task list with checkboxes for selection.
Supports bulk operations on selected tasks:
- Space to toggle individual selection
- A to select all
- N to clear all selections
- B to bulk complete
- D to bulk delete
- P to change priority for all selected
Shows selected count in footer.
#>
class MultiSelectModeScreen : PmcScreen {
    # Data
    [array]$Tasks = @()
    [int]$SelectedIndex = 0
    [hashtable]$MultiSelect = @{}
    [int]$ScrollOffset = 0

    # Constructor
    MultiSelectModeScreen() : base("MultiSelectMode", "Multi-Select Mode") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Tasks", "Multi-Select"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Space", "Toggle")
        $this.Footer.AddShortcut("A", "All")
        $this.Footer.AddShortcut("N", "None")
        $this.Footer.AddShortcut("B", "Bulk Complete")
        $this.Footer.AddShortcut("D", "Bulk Delete")
        $this.Footer.AddShortcut("P", "Set Priority")
        $this.Footer.AddShortcut("Esc", "Exit")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    [void] LoadData() {
        $this.ShowStatus("Loading tasks...")

        try {
            # Get PMC data
            $data = Get-PmcAllData

            # Filter active tasks
            $this.Tasks = @($data.tasks | Where-Object {
                -not $_.completed
            })

            # Sort by priority (descending), then id
            $this.Tasks = @($this.Tasks | Sort-Object -Property @{Expression={$_.priority}; Descending=$true}, id)

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.Tasks.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.Tasks.Count - 1)
            }

            # Update status
            $selectedCount = ($this.MultiSelect.Values | Where-Object { $_ }).Count
            $this.ShowStatus("$($this.Tasks.Count) tasks | $selectedCount selected")

        } catch {
            $this.ShowError("Failed to load tasks: $_")
            $this.Tasks = @()
        }
    }

    [string] RenderContent() {
        $sb = [System.Text.StringBuilder]::new(4096)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $selectedBg = $this.Header.GetThemedAnsi('Primary', $true)
        $selectedFg = $this.Header.GetThemedAnsi('Text', $false)
        $cursorColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $successColor = $this.Header.GetThemedAnsi('Success', $false)
        $priorityColor = $this.Header.GetThemedAnsi('Warning', $false)
        $reset = "`e[0m"

        $y = $contentRect.Y

        # Show selected count
        $selectedCount = ($this.MultiSelect.Values | Where-Object { $_ }).Count
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($successColor)
        $sb.Append("$selectedCount selected")
        $sb.Append($reset)
        $y += 2

        # Column headers
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($mutedColor)
        $sb.Append("SEL".PadRight(5))
        $sb.Append("ID".PadRight(6))
        $sb.Append("PRI".PadRight(5))
        $sb.Append("TASK")
        $sb.Append($reset)
        $y++

        # Task list
        $maxLines = $contentRect.Height - 5
        for ($i = 0; $i -lt [Math]::Min($this.Tasks.Count, $maxLines); $i++) {
            $taskIdx = $i + $this.ScrollOffset
            if ($taskIdx -ge $this.Tasks.Count) { break }

            $task = $this.Tasks[$taskIdx]
            $isSelected = ($taskIdx -eq $this.SelectedIndex)
            $isMarked = $this.MultiSelect[$task.id]

            # Cursor
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
            if ($isSelected) {
                $sb.Append($cursorColor)
                $sb.Append(">")
                $sb.Append($reset)
            } else {
                $sb.Append(" ")
            }

            # Task row
            $x = $contentRect.X + 4
            $sb.Append($this.Header.BuildMoveTo($x, $y))

            # Checkbox
            $marker = if ($isMarked) { "[X]" } else { "[ ]" }
            if ($isMarked) {
                $sb.Append($successColor)
            } else {
                $sb.Append($mutedColor)
            }
            $sb.Append($marker.PadRight(5))
            $sb.Append($reset)

            # ID
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }
            $sb.Append("#$($task.id)".PadRight(6))

            # Priority
            if ($task.priority -and $task.priority -gt 0) {
                if (-not $isSelected) {
                    $sb.Append($reset)
                    $sb.Append($priorityColor)
                }
                $sb.Append("P$($task.priority)".PadRight(5))
                if (-not $isSelected) {
                    $sb.Append($reset)
                    $sb.Append($textColor)
                }
            } else {
                $sb.Append("  ".PadRight(5))
            }

            # Task text
            $maxTaskWidth = $contentRect.Width - 25
            $taskText = if ($task.text) { $task.text } else { "" }
            if ($taskText.Length -gt $maxTaskWidth) {
                $taskText = $taskText.Substring(0, $maxTaskWidth - 3) + "..."
            }
            $sb.Append($taskText)

            $sb.Append($reset)
            $y++
        }

        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                    if ($this.SelectedIndex -lt $this.ScrollOffset) {
                        $this.ScrollOffset = $this.SelectedIndex
                    }
                    return $true
                }
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.Tasks.Count - 1)) {
                    $this.SelectedIndex++
                    $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)
                    $maxLines = $contentRect.Height - 5
                    if ($this.SelectedIndex -ge $this.ScrollOffset + $maxLines) {
                        $this.ScrollOffset = $this.SelectedIndex - $maxLines + 1
                    }
                    return $true
                }
            }
            'Spacebar' {
                if ($this.SelectedIndex -lt $this.Tasks.Count) {
                    $task = $this.Tasks[$this.SelectedIndex]
                    $this.MultiSelect[$task.id] = -not $this.MultiSelect[$task.id]
                    $this._UpdateStatus()
                    return $true
                }
            }
            'A' {
                foreach ($task in $this.Tasks) {
                    $this.MultiSelect[$task.id] = $true
                }
                $this._UpdateStatus()
                return $true
            }
            'N' {
                $this.MultiSelect.Clear()
                $this._UpdateStatus()
                return $true
            }
            'B' {
                $this._BulkComplete()
                return $true
            }
            'D' {
                $this._BulkDelete()
                return $true
            }
            'P' {
                $this._BulkSetPriority()
                return $true
            }
        }

        return $false
    }

    hidden [void] _UpdateStatus() {
        $selectedCount = ($this.MultiSelect.Values | Where-Object { $_ }).Count
        $this.ShowStatus("$($this.Tasks.Count) tasks | $selectedCount selected")
    }

    hidden [void] _BulkComplete() {
        $selectedIds = @($this.MultiSelect.Keys | Where-Object { $this.MultiSelect[$_] })
        if ($selectedIds.Count -eq 0) {
            $this.ShowStatus("No tasks selected")
            return
        }

        try {
            $data = Get-PmcAllData
            $count = 0

            foreach ($id in $selectedIds) {
                $task = $data.tasks | Where-Object { $_.id -eq $id } | Select-Object -First 1
                if ($task) {
                    $task.completed = $true
                    $task.completedDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                    $count++
                }
            }

            Save-PmcData -Data $data -Action "Bulk completed $count tasks"

            $this.ShowSuccess("Completed $count tasks")
            $this.MultiSelect.Clear()

            # Reload data
            Start-Sleep -Milliseconds 500
            $this.LoadData()

        } catch {
            $this.ShowError("Failed to complete tasks: $_")
        }
    }

    hidden [void] _BulkDelete() {
        $selectedIds = @($this.MultiSelect.Keys | Where-Object { $this.MultiSelect[$_] })
        if ($selectedIds.Count -eq 0) {
            $this.ShowStatus("No tasks selected")
            return
        }

        try {
            $data = Get-PmcAllData
            $count = $selectedIds.Count

            # Remove selected tasks
            $data.tasks = @($data.tasks | Where-Object { $selectedIds -notcontains $_.id })

            Save-PmcData -Data $data -Action "Bulk deleted $count tasks"

            $this.ShowSuccess("Deleted $count tasks")
            $this.MultiSelect.Clear()

            # Reload data
            Start-Sleep -Milliseconds 500
            $this.LoadData()

        } catch {
            $this.ShowError("Failed to delete tasks: $_")
        }
    }

    hidden [void] _BulkSetPriority() {
        $selectedIds = @($this.MultiSelect.Keys | Where-Object { $this.MultiSelect[$_] })
        if ($selectedIds.Count -eq 0) {
            $this.ShowStatus("No tasks selected")
            return
        }

        # TODO: Show priority selection dialog
        # For now, just show message
        $this.ShowStatus("Priority selection not yet implemented")
    }
}

# Entry point function for compatibility
function Show-MultiSelectModeScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [MultiSelectModeScreen]::new()
    $App.PushScreen($screen)
}
