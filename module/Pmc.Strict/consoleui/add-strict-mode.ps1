#!/usr/bin/env pwsh
# Add Set-StrictMode to all active files that don't have it

$files = @(
    # Widgets
    "widgets/PmcWidget.ps1",
    "widgets/PmcMenuBar.ps1",
    "widgets/PmcHeader.ps1",
    "widgets/PmcFooter.ps1",
    "widgets/PmcStatusBar.ps1",
    "widgets/PmcPanel.ps1",
    "widgets/PmcDialog.ps1",
    "widgets/DatePicker.ps1",
    "widgets/TextInput.ps1",
    "widgets/ProjectPicker.ps1",
    "widgets/TagEditor.ps1",
    "widgets/FilterPanel.ps1",

    # Helpers
    "helpers/DataBindingHelper.ps1",
    "helpers/ValidationHelper.ps1",

    # Services
    "services/TaskStore.ps1",

    # Layout
    "layout/PmcLayoutManager.ps1",

    # Base
    "base/StandardFormScreen.ps1",
    "base/StandardDashboard.ps1",

    # Screens
    "screens/BlockedTasksScreen.ps1"
)

foreach ($file in $files) {
    $path = Join-Path $PSScriptRoot $file

    if (-not (Test-Path $path)) {
        Write-Host "SKIP: $file (not found)" -ForegroundColor Yellow
        continue
    }

    $content = Get-Content $path -Raw

    # Check if already has Set-StrictMode
    if ($content -match 'Set-StrictMode') {
        Write-Host "SKIP: $file (already has Set-StrictMode)" -ForegroundColor Gray
        continue
    }

    # Find where to insert Set-StrictMode
    # It must come AFTER any "using namespace" statements

    $lines = Get-Content $path
    $insertIndex = 0
    $foundUsing = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # If line is "using namespace", remember we found it
        if ($line -match '^\s*using namespace') {
            $foundUsing = $true
            $insertIndex = $i + 1
        }
        # If we found using statements, keep going until we find non-using, non-blank, non-comment
        elseif ($foundUsing -and $line -match '^\s*$') {
            # Blank line after using - keep going
            $insertIndex = $i + 1
        }
        elseif ($foundUsing -and $line -notmatch '^\s*#' -and $line -notmatch '^\s*$' -and $line -notmatch '^\s*using') {
            # Found first non-using, non-comment, non-blank line after using statements
            break
        }
        # If no using found yet, skip comments and blank lines at top
        elseif (-not $foundUsing -and ($line -match '^\s*#' -or $line -match '^\s*$')) {
            $insertIndex = $i + 1
        }
        # First non-comment, non-blank, non-using line
        elseif (-not $foundUsing) {
            break
        }
    }

    # Insert Set-StrictMode at the right place
    if ($insertIndex -ge $lines.Count) {
        $insertIndex = $lines.Count
    }

    $newLines = @()
    $newLines += $lines[0..($insertIndex-1)]

    # Add blank line if previous line isn't blank
    if ($insertIndex -gt 0 -and $lines[$insertIndex-1] -notmatch '^\s*$') {
        $newLines += ""
    }

    $newLines += "Set-StrictMode -Version Latest"
    $newLines += ""

    $newLines += $lines[$insertIndex..($lines.Count-1)]

    # Write back
    $newLines | Set-Content $path

    Write-Host "ADDED: $file (inserted at line $($insertIndex + 1))" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Cyan
