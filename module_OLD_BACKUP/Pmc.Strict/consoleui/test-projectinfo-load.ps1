#!/usr/bin/env pwsh
# Test script to verify ProjectInfoScreen can be loaded

Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

# Set global variables that PMC expects
$global:PmcTuiLogFile = $null
$global:PmcTuiLogLevel = 0

Write-Host "Testing ProjectInfoScreen loading..." -ForegroundColor Cyan

try {
    # Load PMC module
    Write-Host "1. Loading PMC module..." -ForegroundColor Yellow
    Import-Module "$PSScriptRoot/../Pmc.Strict.psd1" -Force
    Write-Host "   ✓ PMC module loaded" -ForegroundColor Green

    # Create stub for Write-PmcTuiLog if not available
    if (-not (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue)) {
        function Write-PmcTuiLog { param($Message, $Level) }
    }

    # Load dependencies
    Write-Host "2. Loading dependencies..." -ForegroundColor Yellow
    . "$PSScriptRoot/DepsLoader.ps1"
    Write-Host "   ✓ Dependencies loaded" -ForegroundColor Green

    # Load SpeedTUI
    Write-Host "3. Loading SpeedTUI..." -ForegroundColor Yellow
    . "$PSScriptRoot/SpeedTUILoader.ps1"
    Write-Host "   ✓ SpeedTUI loaded" -ForegroundColor Green

    # Load PraxisVT
    Write-Host "4. Loading PraxisVT..." -ForegroundColor Yellow
    . "$PSScriptRoot/../src/PraxisVT.ps1"
    Write-Host "   ✓ PraxisVT loaded" -ForegroundColor Green

    # Load helpers
    Write-Host "5. Loading helpers..." -ForegroundColor Yellow
    Get-ChildItem -Path "$PSScriptRoot/helpers" -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
        . $_.FullName
    }
    Write-Host "   ✓ Helpers loaded" -ForegroundColor Green

    # Load services
    Write-Host "6. Loading services..." -ForegroundColor Yellow
    Get-ChildItem -Path "$PSScriptRoot/services" -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
        . $_.FullName
    }
    Write-Host "   ✓ Services loaded" -ForegroundColor Green

    # Load PMC widget layer
    Write-Host "7. Loading PMC widgets..." -ForegroundColor Yellow
    . "$PSScriptRoot/widgets/PmcWidget.ps1"
    . "$PSScriptRoot/widgets/PmcPanel.ps1"
    . "$PSScriptRoot/widgets/PmcMenuBar.ps1"
    . "$PSScriptRoot/widgets/PmcHeader.ps1"
    . "$PSScriptRoot/widgets/PmcFooter.ps1"
    . "$PSScriptRoot/widgets/PmcStatusBar.ps1"
    . "$PSScriptRoot/layout/PmcLayoutManager.ps1"
    . "$PSScriptRoot/theme/PmcThemeManager.ps1"
    Write-Host "   ✓ PMC widgets loaded" -ForegroundColor Green

    # Load PmcScreen
    Write-Host "8. Loading PmcScreen..." -ForegroundColor Yellow
    . "$PSScriptRoot/PmcScreen.ps1"
    Write-Host "   ✓ PmcScreen loaded" -ForegroundColor Green

    # Load widgets (BEFORE base classes)
    Write-Host "9. Loading widgets..." -ForegroundColor Yellow
    $widgetFiles = @(
        "TextInput.ps1",
        "DatePicker.ps1",
        "ProjectPicker.ps1",
        "TagEditor.ps1",
        "FilterPanel.ps1",
        "InlineEditor.ps1",
        "UniversalList.ps1",
        "TimeEntryDetailDialog.ps1",
        "TextAreaEditor.ps1",
        "PmcFilePicker.ps1"
    )
    foreach ($widgetFile in $widgetFiles) {
        $widgetPath = Join-Path "$PSScriptRoot/widgets" $widgetFile
        if (Test-Path $widgetPath) {
            . $widgetPath
        }
    }
    Write-Host "   ✓ Widgets loaded" -ForegroundColor Green

    # Load base classes
    Write-Host "10. Loading base classes..." -ForegroundColor Yellow
    . "$PSScriptRoot/base/StandardFormScreen.ps1"
    . "$PSScriptRoot/base/StandardListScreen.ps1"
    . "$PSScriptRoot/base/StandardDashboard.ps1"
    Write-Host "   ✓ Base classes loaded" -ForegroundColor Green

    # NOW try to load ProjectInfoScreen
    Write-Host "11. Loading ProjectInfoScreen..." -ForegroundColor Yellow
    . "$PSScriptRoot/screens/ProjectInfoScreen.ps1"
    Write-Host "   ✓ ProjectInfoScreen loaded" -ForegroundColor Green

    # Try to instantiate it
    Write-Host "12. Instantiating ProjectInfoScreen..." -ForegroundColor Yellow
    $screen = New-Object ProjectInfoScreen
    Write-Host "   ✓ ProjectInfoScreen instantiated" -ForegroundColor Green

    Write-Host ""
    Write-Host "SUCCESS! ProjectInfoScreen can be loaded and instantiated." -ForegroundColor Green
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "FAILED: $_" -ForegroundColor Red
    Write-Host "Stack: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
