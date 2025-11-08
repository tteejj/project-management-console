#!/usr/bin/env pwsh
# Fix ALL remaining files

$files = Get-ChildItem -Path @(
    "$PSScriptRoot/screens/*.ps1",
    "$PSScriptRoot/widgets/*.ps1",
    "$PSScriptRoot/base/*.ps1"
) | Where-Object { $_.Name -notmatch "^Test" -and $_.Name -notmatch "Demo" }

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw

    if ($content -match 'Set-StrictMode') {
        continue  # Already has it
    }

    $lines = Get-Content $file.FullName
    $output = @()
    $inserted = $false
    $pastUsing = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # If we see using namespace, mark that we're in using section
        if ($line -match '^\s*using namespace') {
            $output += $line
            $pastUsing = $true
            continue
        }

        # If we were in using section and hit first non-using/non-blank/non-comment
        if ($pastUsing -and -not $inserted -and $line -notmatch '^\s*using' -and $line -notmatch '^\s*$' -and $line -notmatch '^\s*#') {
            $output += ""
            $output += "Set-StrictMode -Version Latest"
            $output += ""
            $inserted = $true
        }

        # If no using found and hit first non-comment/non-blank
        if (-not $pastUsing -and -not $inserted -and $line -notmatch '^\s*#' -and $line -notmatch '^\s*$') {
            $output += ""
            $output += "Set-StrictMode -Version Latest"
            $output += ""
            $inserted = $true
        }

        $output += $line
    }

    if ($inserted) {
        $output | Set-Content $file.FullName
        Write-Host "FIXED: $($file.Name)" -ForegroundColor Green
    }
}
