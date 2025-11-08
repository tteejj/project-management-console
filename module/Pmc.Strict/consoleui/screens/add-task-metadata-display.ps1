#!/usr/bin/env pwsh
# Add subtasks, tags, dependencies, and notes display to all task view screens

$screens = @(
    'TodayViewScreen.ps1',
    'TomorrowViewScreen.ps1',
    'OverdueViewScreen.ps1',
    'WeekViewScreen.ps1',
    'UpcomingViewScreen.ps1',
    'NoDueDateViewScreen.ps1',
    'NextActionsViewScreen.ps1',
    'MonthViewScreen.ps1',
    'AgendaViewScreen.ps1'
)

foreach ($screen in $screens) {
    $path = "/home/teej/pmc/module/Pmc.Strict/consoleui/screens/$screen"

    if (-not (Test-Path $path)) {
        Write-Host "Skipping $screen - not found"
        continue
    }

    Write-Host "Processing $screen..."
    $content = Get-Content $path -Raw

    # Find the task rendering loop - look for the pattern that ends with the task text rendering
    $oldPattern = @'
            }
        }

        return $sb.ToString()
    }
'@

    $newPattern = @'
            }

            $currentY++

            # Render subtasks if present
            if ($task.subtasks -and $task.subtasks.Count -gt 0) {
                foreach ($subtask in $task.subtasks) {
                    if ($currentY -ge ($startY + $maxLines)) { break }

                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  └─ ")
                    $sb.Append($subtask)
                    $sb.Append($reset)
                    $currentY++
                }
            }

            # Render tags if present
            if ($task.tags -and $task.tags.Count -gt 0) {
                if ($currentY -lt ($startY + $maxLines)) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Tags: ")
                    $sb.Append(($task.tags -join ', '))
                    $sb.Append($reset)
                    $currentY++
                }
            }

            # Render dependencies if present
            if ($task.depends -and $task.depends.Count -gt 0) {
                if ($currentY -lt ($startY + $maxLines)) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Deps: ")
                    $sb.Append(($task.depends -join ', '))
                    $sb.Append($reset)
                    $currentY++
                }
            }

            # Render notes if present (first line only)
            if ($task.notes -and $task.notes.Count -gt 0) {
                if ($currentY -lt ($startY + $maxLines)) {
                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 6, $currentY))
                    $sb.Append($mutedColor)
                    $sb.Append("  Note: ")
                    $noteText = $task.notes[0]
                    if ($noteText.Length -gt ($textWidth - 10)) {
                        $noteText = $noteText.Substring(0, $textWidth - 13) + "..."
                    }
                    $sb.Append($noteText)
                    $sb.Append($reset)
                    $currentY++
                }
            }
        }

        return $sb.ToString()
    }
'@

    # Check if this screen already has the update
    if ($content -match 'Render subtasks if present') {
        Write-Host "  Already updated - skipping"
        continue
    }

    # Replace the for loop counter
    $content = $content -replace 'for \(\$i = 0; \$i -lt \[Math\]::Min\(\$this\.\w+\.Count, \$maxLines\); \$i\+\+\) \{', {
        $match = $_.Value
        # Extract the array name (e.g., TodayTasks, WeekTasks)
        if ($match -match '\$this\.(\w+)\.Count') {
            $arrayName = $Matches[1]
            "for (`$i = 0; `$i -lt [Math]::Min(`$this.$arrayName.Count, `$maxLines); `$i++) {"
        } else {
            $match
        }
    }

    # Change loop variable references
    $content = $content -replace '\$y = \$startY \+ \$i', '$y = $currentY'

    # Add $currentY initialization before the loop
    $content = $content -replace '(\s+# Render task rows.*\r?\n\s+\$maxLines = .*\r?\n)', "`$1        `$currentY = `$startY`n"

    # Replace the ending pattern
    if ($content -match [regex]::Escape($oldPattern)) {
        $content = $content -replace [regex]::Escape($oldPattern), $newPattern
        Set-Content $path $content -NoNewline
        Write-Host "  Updated successfully"
    } else {
        Write-Host "  Could not find pattern to replace - manual update needed"
    }
}

Write-Host "Done!"
