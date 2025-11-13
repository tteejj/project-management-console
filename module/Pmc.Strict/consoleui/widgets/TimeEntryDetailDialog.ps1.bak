using namespace System.Collections.Generic
using namespace System.Text

Set-StrictMode -Version Latest

<#
.SYNOPSIS
Dialog to show individual time entries within an aggregated group

.DESCRIPTION
Displays a list of individual time entries that were aggregated together,
allowing users to see the breakdown of hours for a specific day/project/timecode.
#>
class TimeEntryDetailDialog {
    [string]$Title
    [array]$Entries
    [int]$Width
    [int]$Height
    [bool]$IsComplete = $false
    [int]$ScrollOffset = 0
    [int]$SelectedIndex = 0

    TimeEntryDetailDialog([string]$title, [array]$entries) {
        $this.Title = $title
        $this.Entries = $entries
        $this.Width = 80
        $this.Height = [Math]::Min(25, $entries.Count + 7)
    }

    [string] Render([int]$termWidth, [int]$termHeight, [hashtable]$theme) {
        $sb = [System.Text.StringBuilder]::new(4096)

        # Calculate centered position
        $x = [Math]::Floor(($termWidth - $this.Width) / 2)
        $y = [Math]::Floor(($termHeight - $this.Height) / 2)

        # Colors from theme
        $bgColor = if ($theme.DialogBg) { $theme.DialogBg } else { "`e[48;2;45;55;72m" }
        $fgColor = if ($theme.DialogFg) { $theme.DialogFg } else { "`e[38;2;234;241;248m" }
        $borderColor = if ($theme.DialogBorder) { $theme.DialogBorder } else { "`e[38;2;95;107;119m" }
        $highlightColor = if ($theme.Highlight) { $theme.Highlight } else { "`e[38;2;136;153;170m" }
        $selectedBg = "`e[48;2;60;70;90m"
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
            $sb.Append($fgColor)

            if ($row -eq 0) {
                # Top border with title
                $sb.Append($borderColor)
                $sb.Append("┌")
                $titlePadding = $this.Width - $this.Title.Length - 4
                $leftPad = [Math]::Floor($titlePadding / 2)
                $rightPad = $titlePadding - $leftPad
                $sb.Append("─" * $leftPad)
                $sb.Append(" $($this.Title) ")
                $sb.Append("─" * $rightPad)
                $sb.Append("┐")
            }
            elseif ($row -eq 1) {
                # Column headers
                $sb.Append($borderColor)
                $sb.Append("│")
                $sb.Append($fgColor)
                $sb.Append($highlightColor)
                $header = " Task".PadRight(25) + " Hours  " + " Notes"
                $sb.Append($header.PadRight($this.Width - 2))
                $sb.Append($borderColor)
                $sb.Append("│")
            }
            elseif ($row -eq 2) {
                # Separator
                $sb.Append($borderColor)
                $sb.Append("├")
                $sb.Append("─" * ($this.Width - 2))
                $sb.Append("┤")
            }
            elseif ($row -eq ($this.Height - 3)) {
                # Separator before footer
                $sb.Append($borderColor)
                $sb.Append("├")
                $sb.Append("─" * ($this.Width - 2))
                $sb.Append("┤")
            }
            elseif ($row -eq ($this.Height - 2)) {
                # Footer with instructions
                $sb.Append($borderColor)
                $sb.Append("│")
                $sb.Append($fgColor)
                $footer = " ↑/↓: Navigate  Enter/Esc: Close"
                $sb.Append($footer.PadRight($this.Width - 2))
                $sb.Append($borderColor)
                $sb.Append("│")
            }
            elseif ($row -eq ($this.Height - 1)) {
                # Bottom border
                $sb.Append($borderColor)
                $sb.Append("└")
                $sb.Append("─" * ($this.Width - 2))
                $sb.Append("┘")
            }
            else {
                # Entry rows
                $entryIndex = $row - 3 + $this.ScrollOffset
                $sb.Append($borderColor)
                $sb.Append("│")

                if ($entryIndex -ge 0 -and $entryIndex -lt $this.Entries.Count) {
                    $entry = $this.Entries[$entryIndex]

                    # Highlight selected row
                    if ($entryIndex -eq $this.SelectedIndex) {
                        $sb.Append($selectedBg)
                    }
                    $sb.Append($fgColor)

                    # Format entry
                    $task = if ($entry.ContainsKey('task')) { $entry.task } else { '' }
                    if ($task.Length -gt 24) { $task = $task.Substring(0, 21) + "..." }

                    $minutes = if ($entry.ContainsKey('minutes')) { $entry.minutes } else { 0 }
                    $hours = [Math]::Round($minutes / 60.0, 2)

                    $notes = if ($entry.ContainsKey('notes')) { $entry.notes } else { '' }
                    $maxNotesLen = $this.Width - 35
                    if ($notes.Length -gt $maxNotesLen) { $notes = $notes.Substring(0, $maxNotesLen - 3) + "..." }

                    $line = " $($task.PadRight(24)) $($hours.ToString('0.00').PadLeft(5))  $notes"
                    $sb.Append($line.PadRight($this.Width - 2))

                    if ($entryIndex -eq $this.SelectedIndex) {
                        $sb.Append($bgColor)
                    }
                } else {
                    $sb.Append(" " * ($this.Width - 2))
                }

                $sb.Append($borderColor)
                $sb.Append("│")
            }
        }

        $sb.Append($reset)
        return $sb.ToString()
    }

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
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
                if ($this.SelectedIndex -lt ($this.Entries.Count - 1)) {
                    $this.SelectedIndex++
                    # Adjust scroll if needed
                    $maxVisible = $this.Height - 6  # 6 rows for border/header/footer
                    if ($this.SelectedIndex -ge ($this.ScrollOffset + $maxVisible)) {
                        $this.ScrollOffset = $this.SelectedIndex - $maxVisible + 1
                    }
                }
                return $true
            }
            'Enter' {
                $this.IsComplete = $true
                return $true
            }
            'Escape' {
                $this.IsComplete = $true
                return $true
            }
        }
        return $false
    }
}
