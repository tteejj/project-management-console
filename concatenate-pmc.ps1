#!/usr/bin/env pwsh
# Concatenate all PMC module files into a single transportable file

Set-StrictMode -Version Latest

Write-Host "=== PMC Module Concatenation Script ===" -ForegroundColor Green

$outputFile = "./pmc-complete.ps1"
$moduleRoot = "./module/Pmc.Strict"

# Get all PowerShell files that are actually used by PMC
$allFiles = @()

# Main module files
$allFiles += Get-Item "$moduleRoot/Pmc.Strict.psd1" -ErrorAction SilentlyContinue
$allFiles += Get-Item "$moduleRoot/Pmc.Strict.psm1" -ErrorAction SilentlyContinue

# Get all .ps1 files from the module
$sourceFiles = Get-ChildItem -Path $moduleRoot -Recurse -Filter "*.ps1" | Sort-Object FullName
$allFiles += $sourceFiles

# Filter out any test files or temp files
$filteredFiles = $allFiles | Where-Object {
    $_.Name -notmatch "test|Test|tmp|temp" -and
    $_.Extension -in @('.ps1', '.psm1', '.psd1')
}

Write-Host "Found $($filteredFiles.Count) PMC module files to concatenate:" -ForegroundColor Yellow
$filteredFiles | ForEach-Object {
    Write-Host "  $($_.FullName.Replace((Get-Location), '.'))" -ForegroundColor Gray
}

# Create the concatenated file
Write-Host "`nCreating concatenated file: $outputFile" -ForegroundColor Cyan

$content = @()

# Add header
$content += @"
# ===============================================================================
# PMC (Project Management Console) - Complete Module Bundle
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
#
# This file contains the complete PMC module concatenated into a single file
# for easy transport and deployment.
#
# Original structure:
# - Module manifest (.psd1)
# - Main module file (.psm1)
# - $(($filteredFiles | Where-Object Extension -eq '.ps1').Count) PowerShell source files
#
# To use this file:
# 1. Extract individual files or
# 2. Load sections as needed or
# 3. Use as reference for the complete codebase
# ===============================================================================

"@

# Process each file
foreach ($file in $filteredFiles) {
    $relativePath = $file.FullName.Replace((Get-Location), '.').Replace('\', '/')

    Write-Host "Processing: $relativePath" -ForegroundColor Gray

    $content += ""
    $content += "# " + "="*80
    $content += "# FILE: $relativePath"
    $content += "# SIZE: $([math]::Round($file.Length / 1024, 2)) KB"
    $content += "# MODIFIED: $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    $content += "# " + "="*80
    $content += ""

    try {
        $fileContent = Get-Content $file.FullName -Raw -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($fileContent)) {
            $content += "# (Empty file)"
        } else {
            $content += $fileContent
        }
    } catch {
        $content += "# ERROR: Could not read file - $_"
    }

    $content += ""
    $content += "# END FILE: $relativePath"
    $content += ""
}

# Add footer with statistics
$totalSize = ($filteredFiles | Measure-Object Length -Sum).Sum
$content += ""
$content += "# " + "="*80
$content += "# PMC MODULE CONCATENATION COMPLETE"
$content += "# " + "="*80
$content += "# Files included: $($filteredFiles.Count)"
$content += "# Total size: $([math]::Round($totalSize / 1024, 2)) KB"
$content += "# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$content += "# " + "="*80

# Write the concatenated file
try {
    $content | Out-File -FilePath $outputFile -Encoding UTF8

    $outputInfo = Get-Item $outputFile
    Write-Host "`n✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Concatenated file created: $outputFile" -ForegroundColor White
    Write-Host "Size: $([math]::Round($outputInfo.Length / 1024, 2)) KB" -ForegroundColor Gray
    Write-Host "Files included: $($filteredFiles.Count)" -ForegroundColor Gray

    # Show breakdown by directory
    Write-Host "`nFile breakdown by directory:" -ForegroundColor White
    $filteredFiles | Group-Object { Split-Path $_.FullName -Parent } | Sort-Object Name | ForEach-Object {
        $dirName = $_.Name.Replace((Get-Location), '.').Replace('\', '/')
        Write-Host "  $dirName : $($_.Count) files" -ForegroundColor Gray
    }

    Write-Host "`nThe file $outputFile is ready for transport/upload." -ForegroundColor Green

} catch {
    Write-Host "❌ ERROR creating concatenated file: $_" -ForegroundColor Red
    exit 1
}