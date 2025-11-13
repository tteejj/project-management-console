using namespace System.Collections.Generic
using namespace System.Text

# SearchFormScreen - Search tasks
# Input field for search query with live results display


Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Task search screen with live results

.DESCRIPTION
Shows an input field where users can type search queries.
Displays matching tasks as the user types (live search).
Search matches task text, project, and tags.
Supports:
- Text input for search query
- Live search results update
- Enter to view selected task
- Up/Down to navigate results
- Esc to cancel
#>
class SearchFormScreen : PmcScreen {
    # Data
    [string]$SearchQuery = ""
    [array]$MatchingTasks = @()
    [int]$SelectedIndex = 0

    # Backward compatible constructor
    SearchFormScreen() : base("SearchForm", "Search Tasks") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Search"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Type", "Search")
        $this.Footer.AddShortcut("Up/Down", "Navigate")
        $this.Footer.AddShortcut("Enter", "View Task")
        $this.Footer.AddShortcut("Esc", "Cancel")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    # Container constructor
    SearchFormScreen([object]$container) : base("SearchForm", "Search Tasks", $container) {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Search"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Type", "Search")
        $this.Footer.AddShortcut("Up/Down", "Navigate")
        $this.Footer.AddShortcut("Enter", "View Task")
        $this.Footer.AddShortcut("Esc", "Cancel")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")
    }

    [void] LoadData() {
        $this.ShowStatus("Type to search tasks...")
        $this._UpdateSearch()
    }

    hidden [void] _UpdateSearch() {
        try {
            $data = Get-PmcData

            if ([string]::IsNullOrWhiteSpace($this.SearchQuery)) {
                $this.MatchingTasks = @()
                $this.ShowStatus("Type to search tasks...")
                return
            }

            # Search in task text, project, and tags
            $query = $this.SearchQuery.ToLower()
            $this.MatchingTasks = @($data.tasks | Where-Object {
                -not $_.completed -and (
                    $_.text.ToLower().Contains($query) -or
                    $_.project.ToLower().Contains($query) -or
                    ($_.tags -and ($_.tags -join ' ').ToLower().Contains($query))
                )
            })

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.MatchingTasks.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.MatchingTasks.Count - 1)
            }

            $count = $this.MatchingTasks.Count
            if ($count -eq 0) {
                $this.ShowStatus("No matches found")
            } elseif ($count -eq 1) {
                $this.ShowStatus("1 match found")
            } else {
                $this.ShowStatus("$count matches found")
            }

        } catch {
            $this.ShowError("Search error: $_")
            $this.MatchingTasks = @()
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
        $priorityColor = $this.Header.GetThemedAnsi('Warning', $false)
        $reset = "`e[0m"

        $y = $contentRect.Y

        # Search prompt
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($textColor)
        $sb.Append("Search for:")
        $sb.Append($reset)
        $y += 2

        # Search input box
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
        $sb.Append($cursorColor)
        $sb.Append("> ")
        $sb.Append($textColor)
        $sb.Append($this.SearchQuery)
        $sb.Append($cursorColor)
        $sb.Append("_")
        $sb.Append($reset)
        $y += 3

        # Results header
        if ($this.MatchingTasks.Count -gt 0) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("Results:")
            $sb.Append($reset)
            $y += 2

            # Column headers
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("ID".PadRight(6))
            $sb.Append("PRI".PadRight(5))
            $sb.Append("PROJECT".PadRight(15))
            $sb.Append("TASK")
            $sb.Append($reset)
            $y++

            # Results list
            $maxLines = $contentRect.Height - 10
            for ($i = 0; $i -lt [Math]::Min($this.MatchingTasks.Count, $maxLines); $i++) {
                $task = $this.MatchingTasks[$i]
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

                # Task row
                $x = $contentRect.X + 4
                $sb.Append($this.Header.BuildMoveTo($x, $y))

                if ($isSelected) {
                    $sb.Append($selectedBg)
                    $sb.Append($selectedFg)
                }

                # ID
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

                # Project
                $projText = if ($task.project) { $task.project } else { "" }
                if ($projText.Length -gt 14) {
                    $projText = $projText.Substring(0, 11) + "..."
                }
                $sb.Append($projText.PadRight(15))

                # Task text
                $maxTaskWidth = $contentRect.Width - 35
                $taskText = if ($task.text) { $task.text } else { "" }
                if ($taskText.Length -gt $maxTaskWidth) {
                    $taskText = $taskText.Substring(0, $maxTaskWidth - 3) + "..."
                }
                $sb.Append($taskText)

                $sb.Append($reset)
                $y++
            }

            # Show "more results" indicator
            if ($this.MatchingTasks.Count -gt $maxLines) {
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
                $sb.Append($mutedColor)
                $sb.Append("... and $($this.MatchingTasks.Count - $maxLines) more")
                $sb.Append($reset)
            }
        } else {
            # No results message
            if (-not [string]::IsNullOrWhiteSpace($this.SearchQuery)) {
                $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
                $sb.Append($mutedColor)
                $sb.Append("No tasks match your search")
                $sb.Append($reset)
            }
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # CRITICAL: Call parent FIRST for MenuBar, F10, Alt+keys, content widgets
        $handled = ([PmcScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.MatchingTasks.Count -gt 0 -and $this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                    return $true
                }
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.MatchingTasks.Count - 1)) {
                    $this.SelectedIndex++
                    return $true
                }
            }
            'Enter' {
                if ($this.MatchingTasks.Count -gt 0) {
                    $this._ViewSelectedTask()
                }
                return $true
            }
            'Backspace' {
                if ($this.SearchQuery.Length -gt 0) {
                    $this.SearchQuery = $this.SearchQuery.Substring(0, $this.SearchQuery.Length - 1)
                    $this._UpdateSearch()
                    return $true
                }
            }
            default {
                # Add character to search query
                if ($keyInfo.KeyChar -and -not [char]::IsControl($keyInfo.KeyChar)) {
                    $this.SearchQuery += $keyInfo.KeyChar
                    $this._UpdateSearch()
                    return $true
                }
            }
        }

        return $false
    }

    hidden [void] _ViewSelectedTask() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.MatchingTasks.Count) {
            return
        }

        if ($this.MatchingTasks.Count -gt 0) {
            $task = $this.MatchingTasks[$this.SelectedIndex]
            . "$PSScriptRoot/TaskDetailScreen.ps1"
            $screen = New-Object TaskDetailScreen
            $screen.SetTask($task)
            $global:PmcApp.PushScreen($screen)
        }
    }
}

# Entry point function for compatibility
function Show-SearchFormScreen {
    param([object]$App)

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [SearchFormScreen]::new()
    $App.PushScreen($screen)
}
