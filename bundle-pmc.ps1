#!/usr/bin/env pwsh
# Bundle PMC into a self-extracting PowerShell script

$bundleFile = "pmc-bundle.ps1"
$output = @()

# Header
$output += @"
#!/usr/bin/env pwsh
# PMC Self-Extracting Bundle
# Usage: pwsh pmc-bundle.ps1 [destination_path]
# If no path provided, extracts to ./pmc

param([string]`$DestPath = './pmc')

Write-Host "Extracting PMC to `$DestPath..." -ForegroundColor Green

# Create base directory
New-Item -ItemType Directory -Path "`$DestPath" -Force | Out-Null

# File manifest - each entry: PATH|BASE64_CONTENT
`$files = @(
"@

# Get all relevant files
$files = Get-ChildItem -Recurse -File | Where-Object {
    $_.FullName -notmatch '(archives|old_backup|pmcapp|_tui|\.git|pmc-bundle|bundle-pmc|extract-pmc|test-|debug\.log)' -and
    $_.Extension -in @('.ps1', '.psd1', '.psm1', '.json', '.md', '.txt')
}

Write-Host "Bundling $($files.Count) files..." -ForegroundColor Cyan

foreach ($file in $files) {
    $relativePath = $file.FullName.Replace((Get-Location).Path + '/', '')
    $content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Raw $file.FullName)))
    $output += "    '$relativePath|$content'"
}

$output += @"
)

# Extract files
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

Write-Host "`nPMC extracted successfully to `$DestPath" -ForegroundColor Green
Write-Host "To run: cd `$DestPath && pwsh start-pmc.ps1" -ForegroundColor Cyan
"@

# Write bundle
$output | Set-Content -Path $bundleFile

Write-Host "`n✓ Bundle created: $bundleFile" -ForegroundColor Green
Write-Host "Size: $([math]::Round((Get-Item $bundleFile).Length / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host "`nTo extract: pwsh $bundleFile [destination]" -ForegroundColor Yellow
