#!/usr/bin/env pwsh
# Bundle PMC into TWO self-extracting PowerShell scripts (for email size limits)

$bundle1File = "pmc-bundle-part1.ps1"
$bundle2File = "pmc-bundle-part2.ps1"

# Get all relevant files
$files = Get-ChildItem -Recurse -File | Where-Object {
    $_.FullName -notmatch '(archives|old_backup|pmcapp|_tui|\.git|pmc-bundle|bundle-pmc|extract-pmc|test-|debug\.log)' -and
    $_.Extension -in @('.ps1', '.psd1', '.psm1', '.json', '.md', '.txt')
}

Write-Host "Bundling $($files.Count) files into 2 parts..." -ForegroundColor Cyan

# Split files into two groups
$midpoint = [math]::Floor($files.Count / 2)
$part1Files = $files[0..($midpoint - 1)]
$part2Files = $files[$midpoint..($files.Count - 1)]

# === PART 1 ===
$output1 = @()
$output1 += @"
#!/usr/bin/env pwsh
# PMC Self-Extracting Bundle - PART 1 of 2
# Usage:
#   1. Run this script: pwsh pmc-bundle-part1.ps1 [destination]
#   2. Run part 2: pwsh pmc-bundle-part2.ps1 [same_destination]

param([string]`$DestPath = './pmc')

Write-Host "Extracting PMC PART 1 to `$DestPath..." -ForegroundColor Green
New-Item -ItemType Directory -Path "`$DestPath" -Force | Out-Null

`$files = @(
"@

foreach ($file in $part1Files) {
    $relativePath = $file.FullName.Replace((Get-Location).Path + '/', '')
    $content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Raw $file.FullName)))
    $output1 += "    '$relativePath|$content'"
}

$output1 += @"
)

foreach (`$entry in `$files) {
    `$parts = `$entry -split '\|', 2
    `$path = `$parts[0]
    `$content = `$parts[1]
    `$fullPath = Join-Path `$DestPath `$path
    `$dir = Split-Path `$fullPath -Parent
    if (-not (Test-Path `$dir)) {
        New-Item -ItemType Directory -Path `$dir -Force | Out-Null
    }
    `$decoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(`$content))
    Set-Content -Path `$fullPath -Value `$decoded -NoNewline
    Write-Host "  Extracted: `$path" -ForegroundColor Gray
}

Write-Host "`n✓ PART 1 extracted successfully" -ForegroundColor Green
Write-Host "⚠ NOW RUN: pwsh pmc-bundle-part2.ps1 `$DestPath" -ForegroundColor Yellow
"@

# === PART 2 ===
$output2 = @()
$output2 += @"
#!/usr/bin/env pwsh
# PMC Self-Extracting Bundle - PART 2 of 2

param([string]`$DestPath = './pmc')

Write-Host "Extracting PMC PART 2 to `$DestPath..." -ForegroundColor Green

if (-not (Test-Path `$DestPath)) {
    Write-Host "ERROR: `$DestPath does not exist. Run part1 first!" -ForegroundColor Red
    exit 1
}

`$files = @(
"@

foreach ($file in $part2Files) {
    $relativePath = $file.FullName.Replace((Get-Location).Path + '/', '')
    $content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Raw $file.FullName)))
    $output2 += "    '$relativePath|$content'"
}

$output2 += @"
)

foreach (`$entry in `$files) {
    `$parts = `$entry -split '\|', 2
    `$path = `$parts[0]
    `$content = `$parts[1]
    `$fullPath = Join-Path `$DestPath `$path
    `$dir = Split-Path `$fullPath -Parent
    if (-not (Test-Path `$dir)) {
        New-Item -ItemType Directory -Path `$dir -Force | Out-Null
    }
    `$decoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(`$content))
    Set-Content -Path `$fullPath -Value `$decoded -NoNewline
    Write-Host "  Extracted: `$path" -ForegroundColor Gray
}

Write-Host "`n✓ PMC fully extracted to `$DestPath" -ForegroundColor Green
Write-Host "To run: cd `$DestPath && pwsh start-pmc.ps1" -ForegroundColor Cyan
"@

# Write bundles
$output1 | Set-Content -Path $bundle1File
$output2 | Set-Content -Path $bundle2File

$size1 = [math]::Round((Get-Item $bundle1File).Length / 1MB, 2)
$size2 = [math]::Round((Get-Item $bundle2File).Length / 1MB, 2)

Write-Host "`n✓ Bundles created:" -ForegroundColor Green
Write-Host "  Part 1: $bundle1File ($size1 MB)" -ForegroundColor Cyan
Write-Host "  Part 2: $bundle2File ($size2 MB)" -ForegroundColor Cyan
Write-Host "`nTo extract:" -ForegroundColor Yellow
Write-Host "  1. pwsh $bundle1File [destination]" -ForegroundColor Gray
Write-Host "  2. pwsh $bundle2File [same_destination]" -ForegroundColor Gray
