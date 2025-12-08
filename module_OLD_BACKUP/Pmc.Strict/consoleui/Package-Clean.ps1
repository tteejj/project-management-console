#!/usr/bin/env pwsh
# Creates MINIMAL package with ONLY files actually loaded at runtime
# NO logs, NO backups, NO test files, NO cruft

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$staging = Join-Path $PSScriptRoot "staging"

Write-Host "Creating clean staging directory..." -ForegroundColor Cyan
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging | Out-Null

function Copy-File {
    param([string]$Source, [string]$Dest)
    $destDir = Split-Path $Dest -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    Copy-Item $Source $Dest -Force
}

# === PMC MODULE CORE ===
Write-Host "Copying PMC module core..." -ForegroundColor Yellow
Copy-File "$root/module/Pmc.Strict/Pmc.Strict.psd1" "$staging/module/Pmc.Strict/Pmc.Strict.psd1"
Copy-File "$root/module/Pmc.Strict/Pmc.Strict.psm1" "$staging/module/Pmc.Strict/Pmc.Strict.psm1"

# === PMC SRC (files loaded by Pmc.Strict.psm1) ===
Write-Host "Copying PMC src files..." -ForegroundColor Yellow
$srcFiles = @(
    'Types.ps1', 'TerminalDimensions.ps1', 'State.ps1', 'Config.ps1',
    'Debug.ps1', 'Security.ps1', 'Storage.ps1', 'UI.ps1',
    'ScreenManager.ps1', 'Resolvers.ps1', 'CommandMap.ps1', 'Schemas.ps1',
    'AstCommandParser.ps1', 'AstCompletion.ps1', 'TemplateDisplay.ps1',
    'Execution.ps1', 'Help.ps1', 'Interactive.ps1', 'Dependencies.ps1',
    'Focus.ps1', 'Time.ps1', 'UndoRedo.ps1', 'FakeTUICommand.ps1',
    'Aliases.ps1', 'Analytics.ps1', 'Theme.ps1', 'Excel.ps1',
    'ExcelFlowLite.ps1', 'ImportExport.ps1', 'Shortcuts.ps1', 'Review.ps1',
    'HelpUI.ps1', 'TaskEditor.ps1', 'ProjectWizard.ps1', 'Projects.ps1',
    'Tasks.ps1', 'Views.ps1', 'PraxisVT.ps1', 'PraxisStringBuilder.ps1',
    'FieldSchemas.ps1', 'QuerySpec.ps1', 'Query.ps1', 'ComputedFields.ps1',
    'QueryEvaluator.ps1', 'PraxisFrameRenderer.ps1', 'DataDisplay.ps1',
    'UniversalDisplay.ps1'
)

foreach ($file in $srcFiles) {
    $source = "$root/module/Pmc.Strict/src/$file"
    if (Test-Path $source) {
        Copy-File $source "$staging/module/Pmc.Strict/src/$file"
    }
}

# === PMC CORE (EnhancedQueryEngine, etc) ===
Write-Host "Copying PMC Core files..." -ForegroundColor Yellow
$coreFiles = @('EnhancedQueryEngine.ps1', 'EnhancedCommandProcessor.ps1')
foreach ($file in $coreFiles) {
    $source = "$root/module/Pmc.Strict/Core/$file"
    if (Test-Path $source) {
        Copy-File $source "$staging/module/Pmc.Strict/Core/$file"
    }
}

# === CONSOLEUI ENTRY POINT ===
Write-Host "Copying ConsoleUI entry point..." -ForegroundColor Yellow
Copy-File "$PSScriptRoot/Start-PmcTUI.ps1" "$staging/module/Pmc.Strict/consoleui/Start-PmcTUI.ps1"

# === CONSOLEUI LOADERS ===
Write-Host "Copying ConsoleUI loaders..." -ForegroundColor Yellow
Copy-File "$PSScriptRoot/DepsLoader.ps1" "$staging/module/Pmc.Strict/consoleui/DepsLoader.ps1"
Copy-File "$PSScriptRoot/SpeedTUILoader.ps1" "$staging/module/Pmc.Strict/consoleui/SpeedTUILoader.ps1"

# === CONSOLEUI INFRASTRUCTURE ===
Write-Host "Copying ConsoleUI infrastructure..." -ForegroundColor Yellow
$infraFiles = @(
    'ServiceContainer.ps1', 'PmcApplication.ps1', 'PmcScreen.ps1', 'ZIndex.ps1'
)
foreach ($file in $infraFiles) {
    Copy-File "$PSScriptRoot/$file" "$staging/module/Pmc.Strict/consoleui/$file"
}

# === CONSOLEUI HELPERS (all .ps1 files) ===
Write-Host "Copying helpers..." -ForegroundColor Yellow
Get-ChildItem "$PSScriptRoot/helpers" -Filter "*.ps1" | ForEach-Object {
    Copy-File $_.FullName "$staging/module/Pmc.Strict/consoleui/helpers/$($_.Name)"
}

# === CONSOLEUI SERVICES (all .ps1 files) ===
Write-Host "Copying services..." -ForegroundColor Yellow
Get-ChildItem "$PSScriptRoot/services" -Filter "*.ps1" | ForEach-Object {
    Copy-File $_.FullName "$staging/module/Pmc.Strict/consoleui/services/$($_.Name)"
}

# === CONSOLEUI DEPS ===
Write-Host "Copying deps..." -ForegroundColor Yellow
$depsFiles = @('PmcTemplate.ps1', 'HelpContent.ps1', 'Project.ps1')
foreach ($file in $depsFiles) {
    $source = "$PSScriptRoot/deps/$file"
    if (Test-Path $source) {
        Copy-File $source "$staging/module/Pmc.Strict/consoleui/deps/$file"
    }
}

# === CONSOLEUI SRC ===
Write-Host "Copying consoleui/src..." -ForegroundColor Yellow
if (Test-Path "$PSScriptRoot/src") {
    Get-ChildItem "$PSScriptRoot/src" -Filter "*.ps1" | ForEach-Object {
        Copy-File $_.FullName "$staging/module/Pmc.Strict/consoleui/src/$($_.Name)"
    }
}

# === CONSOLEUI LAYOUT ===
Write-Host "Copying layout..." -ForegroundColor Yellow
Get-ChildItem "$PSScriptRoot/layout" -Filter "*.ps1" | ForEach-Object {
    Copy-File $_.FullName "$staging/module/Pmc.Strict/consoleui/layout/$($_.Name)"
}

# === CONSOLEUI THEME ===
Write-Host "Copying theme..." -ForegroundColor Yellow
Get-ChildItem "$PSScriptRoot/theme" -Filter "*.ps1" | ForEach-Object {
    Copy-File $_.FullName "$staging/module/Pmc.Strict/consoleui/theme/$($_.Name)"
}

# === CONSOLEUI BASE CLASSES ===
Write-Host "Copying base classes..." -ForegroundColor Yellow
Get-ChildItem "$PSScriptRoot/base" -Filter "*.ps1" | ForEach-Object {
    Copy-File $_.FullName "$staging/module/Pmc.Strict/consoleui/base/$($_.Name)"
}

# === CONSOLEUI WIDGETS (specific files) ===
Write-Host "Copying widgets..." -ForegroundColor Yellow
$widgetFiles = @(
    'PmcWidget.ps1', 'PmcPanel.ps1', 'PmcMenuBar.ps1', 'PmcHeader.ps1',
    'PmcFooter.ps1', 'PmcStatusBar.ps1', 'TextInput.ps1', 'DatePicker.ps1',
    'ProjectPicker.ps1', 'TagEditor.ps1', 'FilterPanel.ps1', 'InlineEditor.ps1',
    'UniversalList.ps1', 'TimeEntryDetailDialog.ps1', 'TextAreaEditor.ps1',
    'PmcFilePicker.ps1', 'TabPanel.ps1', 'PmcDialog.ps1'
)
foreach ($file in $widgetFiles) {
    $source = "$PSScriptRoot/widgets/$file"
    if (Test-Path $source) {
        Copy-File $source "$staging/module/Pmc.Strict/consoleui/widgets/$file"
    }
}

# === CONSOLEUI SCREENS (all .ps1 and MenuItems.psd1) ===
Write-Host "Copying screens..." -ForegroundColor Yellow
Get-ChildItem "$PSScriptRoot/screens" -Filter "*.ps1" | ForEach-Object {
    Copy-File $_.FullName "$staging/module/Pmc.Strict/consoleui/screens/$($_.Name)"
}
Copy-File "$PSScriptRoot/screens/MenuItems.psd1" "$staging/module/Pmc.Strict/consoleui/screens/MenuItems.psd1"

# === SPEEDTUI CORE (ONLY files loaded by SpeedTUILoader.ps1) ===
Write-Host "Copying SpeedTUI core..." -ForegroundColor Yellow
$speedTUIFiles = @(
    'Core/Logger.ps1',
    'Core/PerformanceMonitor.ps1',
    'Core/NullCheck.ps1',
    'Core/Internal/PerformanceCore.ps1',
    'Core/SimplifiedTerminal.ps1',
    'Core/CellBuffer.ps1',
    'Core/EnhancedRenderEngine.ps1',
    'Core/OptimizedRenderEngine.ps1',
    'Core/Component.ps1',
    'BorderHelper.ps1'
)
foreach ($file in $speedTUIFiles) {
    $source = "$root/lib/SpeedTUI/$file"
    if (Test-Path $source) {
        Copy-File $source "$staging/lib/SpeedTUI/$file"
    }
}

# === CONFIG & TASKS ===
Write-Host "Copying config and tasks..." -ForegroundColor Yellow
Copy-File "$root/config.json" "$staging/config.json"
# Create empty tasks.json
@{tasks = @(); nextId = 1} | ConvertTo-Json -Depth 10 | Set-Content "$staging/tasks.json" -Encoding UTF8

Write-Host ""
Write-Host "Creating ZIP..." -ForegroundColor Cyan
$zipPath = "$PSScriptRoot/pmc-clean.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($staging, $zipPath, 'Optimal', $false)

$zipSize = (Get-Item $zipPath).Length
Write-Host "ZIP created: $zipPath ($([math]::Round($zipSize / 1KB, 0)) KB)" -ForegroundColor Green

Write-Host ""
Write-Host "Creating split PowerShell files..." -ForegroundColor Cyan

# Read and encode
$zipBytes = [System.IO.File]::ReadAllBytes($zipPath)
$base64 = [System.Convert]::ToBase64String($zipBytes)
$midpoint = [Math]::Floor($base64.Length / 2)
$part1Data = $base64.Substring(0, $midpoint)
$part2Data = $base64.Substring($midpoint)

# Part 2
$part2 = @"
# PMC TUI Package - Part 2/2
`$global:PmcPackagePart2 = @'
$part2Data
'@
"@
$part2 | Set-Content "$PSScriptRoot/pmcp2.ps1" -Encoding UTF8

# Part 1
$part1 = @"
#!/usr/bin/env pwsh
param([string]`$DestinationPath = "./pmc-tui")
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
Write-Host "=== PMC TUI Package Extractor ===" -ForegroundColor Cyan
`$part1Data = @'
$part1Data
'@
Write-Host "Loading pmcp2.ps1..." -ForegroundColor Yellow
if (-not (Test-Path "`$PSScriptRoot/pmcp2.ps1")) {
    Write-Error "pmcp2.ps1 not found in same directory"
    exit 1
}
. "`$PSScriptRoot/pmcp2.ps1"
Write-Host "Combining package data..." -ForegroundColor Yellow
`$completeBase64 = `$part1Data + `$global:PmcPackagePart2
Write-Host "Decoding package..." -ForegroundColor Yellow
`$zipBytes = [System.Convert]::FromBase64String(`$completeBase64)
`$tempZip = [System.IO.Path]::GetTempFileName() + ".zip"
[System.IO.File]::WriteAllBytes(`$tempZip, `$zipBytes)
Write-Host "Extracting to: `$DestinationPath" -ForegroundColor Yellow
if (Test-Path `$DestinationPath) {
    `$response = Read-Host "Destination exists. Overwrite? (y/n)"
    if (`$response -ne 'y') {
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
Write-Host "1. cd `$DestinationPath/module/Pmc.Strict/consoleui" -ForegroundColor Yellow
Write-Host "2. .\Start-PmcTUI.ps1" -ForegroundColor Yellow
"@
$part1 | Set-Content "$PSScriptRoot/pmcp1.ps1" -Encoding UTF8

Write-Host "pmcp1.ps1 created ($([math]::Round((Get-Item "$PSScriptRoot/pmcp1.ps1").Length / 1KB, 0)) KB)" -ForegroundColor Green
Write-Host "pmcp2.ps1 created ($([math]::Round((Get-Item "$PSScriptRoot/pmcp2.ps1").Length / 1KB, 0)) KB)" -ForegroundColor Green

Write-Host ""
Write-Host "Cleanup staging..." -ForegroundColor Yellow
Remove-Item $staging -Recurse -Force

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "Files ready to email:" -ForegroundColor Cyan
Write-Host "  pmcp1.ps1" -ForegroundColor White
Write-Host "  pmcp2.ps1" -ForegroundColor White
