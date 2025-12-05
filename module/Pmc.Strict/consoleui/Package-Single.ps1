#!/usr/bin/env pwsh
# Creates single-file PowerShell package

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "Reading clean package..." -ForegroundColor Cyan
$zipPath = "$PSScriptRoot/pmc-clean.zip"
if (-not (Test-Path $zipPath)) {
    Write-Error "pmc-clean.zip not found. Run Package-Clean.ps1 first."
    exit 1
}

$zipBytes = [System.IO.File]::ReadAllBytes($zipPath)
$base64 = [System.Convert]::ToBase64String($zipBytes)

Write-Host "Creating single-file package..." -ForegroundColor Yellow

$content = @"
#!/usr/bin/env pwsh
<#
.SYNOPSIS
PMC TUI Portable Package - Single File

.PARAMETER DestinationPath
Where to extract (default: ./pmc-tui)

.EXAMPLE
.\pmc.ps1
.\pmc.ps1 -DestinationPath C:\pmc-test
#>

param([string]`$DestinationPath = "./pmc-tui")

Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'

Write-Host "=== PMC TUI Package Extractor ===" -ForegroundColor Cyan
Write-Host ""

`$packageData = @'
$base64
'@

Write-Host "Decoding package..." -ForegroundColor Yellow
try {
    `$zipBytes = [System.Convert]::FromBase64String(`$packageData)
    `$sizeMB = [math]::Round(`$zipBytes.Length / 1MB, 2)
    Write-Host "  Decoded `$sizeMB MB" -ForegroundColor Green
} catch {
    Write-Error "Failed to decode package: `$_"
    exit 1
}

`$tempZip = [System.IO.Path]::GetTempFileName() + ".zip"
Write-Host "Creating temporary ZIP..." -ForegroundColor Yellow
[System.IO.File]::WriteAllBytes(`$tempZip, `$zipBytes)

Write-Host "Extracting to: `$DestinationPath" -ForegroundColor Yellow

if (Test-Path `$DestinationPath) {
    `$response = Read-Host "Destination exists. Overwrite? (y/n)"
    if (`$response -ne 'y') {
        Write-Host "Extraction cancelled" -ForegroundColor Red
        Remove-Item `$tempZip -Force
        exit 0
    }
    Remove-Item -Path `$DestinationPath -Recurse -Force
}

New-Item -ItemType Directory -Path `$DestinationPath -Force | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory(`$tempZip, `$DestinationPath)

Remove-Item `$tempZip -Force

Write-Host "  Extraction complete" -ForegroundColor Green
Write-Host ""
Write-Host "=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Navigate to TUI directory:" -ForegroundColor White
Write-Host "   cd `$DestinationPath/module/Pmc.Strict/consoleui" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Start the TUI:" -ForegroundColor White
Write-Host "   .\Start-PmcTUI.ps1" -ForegroundColor Yellow
Write-Host ""
"@

$content | Set-Content "$PSScriptRoot/pmc.ps1" -Encoding UTF8

$fileSize = (Get-Item "$PSScriptRoot/pmc.ps1").Length
Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "Single file created: pmc.ps1 ($([math]::Round($fileSize / 1KB, 0)) KB)" -ForegroundColor White
Write-Host ""
Write-Host "Email this one file and run on Windows:" -ForegroundColor Cyan
Write-Host "  .\pmc.ps1" -ForegroundColor Yellow
