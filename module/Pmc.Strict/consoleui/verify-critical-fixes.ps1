#!/usr/bin/env pwsh
# verify-critical-fixes.ps1 - Verify all critical fixes are in place

Write-Host "Verifying Critical Fixes Applied..." -ForegroundColor Cyan
Write-Host ""

$allPassed = $true

# CRITICAL-6: Check defensive guards in Storage.ps1
Write-Host "Checking CRITICAL-6: Defensive Guards in Storage.ps1..." -NoNewline
$storage = Get-Content "/home/teej/pmc/module/Pmc.Strict/src/Storage.ps1" -Raw
if ($storage -match 'Check if Pmc-HasProp function exists before using it' -and 
    $storage -match 'Write-PmcDebug -Level 3 -Category ''STORAGE'' -Message "Failed to normalize task\.') {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $allPassed = $false
}

# CRITICAL-2: Check COM error logging in ExcelComReader.ps1
Write-Host "Checking CRITICAL-2: COM Cleanup Error Logging..." -NoNewline
$excel = Get-Content "/home/teej/pmc/module/Pmc.Strict/consoleui/services/ExcelComReader.ps1" -Raw
if ($excel -match 'Write-PmcTuiLog "Failed to release COM object' -and
    ($excel -match 'Failed to release COM object \(cell\)' -or $excel -match 'Failed to release COM object \(range\)')) {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $allPassed = $false
}

# HIGH-1: Check file verification in Storage.ps1
Write-Host "Checking HIGH-1: File Verification After Save..." -NoNewline
if ($storage -match 'Verify that the written file is valid JSON' -and
    $storage -match 'File verification successful after save') {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $allPassed = $false
}

# HIGH-6: Check null checks in TaskListScreen.ps1
Write-Host "Checking HIGH-6: Null Checks After Filtering..." -NoNewline
$taskList = Get-Content "/home/teej/pmc/module/Pmc.Strict/consoleui/screens/TaskListScreen.ps1" -Raw
if ($taskList -match 'Null check after filtering to prevent crashes' -and
    $taskList -match 'Null check after sorting to prevent crashes') {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $allPassed = $false
}

# HIGH-7: Check try-catch in PmcScreen.ps1
Write-Host "Checking HIGH-7: Try-Catch Protection for Render()..." -NoNewline
$screen = Get-Content "/home/teej/pmc/module/Pmc.Strict/consoleui/PmcScreen.ps1" -Raw
if ($screen -match 'wrap in try-catch to prevent rendering crashes' -and
    $screen -match 'RenderContent\(\) crashed') {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $allPassed = $false
}

Write-Host ""
if ($allPassed) {
    Write-Host "All Critical Fixes Verified!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some fixes are missing or incomplete!" -ForegroundColor Red
    exit 1
}
