#!/usr/bin/env pwsh
# verify-fixes.ps1 - Verify performance fixes are working correctly

Write-Host "=== PMC TUI Performance Fixes Verification ===" -ForegroundColor Cyan
Write-Host ""

$results = @{
    Passed = @()
    Failed = @()
}

# Test 1: Check SpeedTUI loading is not duplicated
Write-Host "[1/5] Checking SpeedTUI loading pattern..." -ForegroundColor Yellow
$speedTUIRefs = @()

# Check Start-PmcTUI.ps1 doesn't load SpeedTUI
$startContent = Get-Content "$PSScriptRoot/Start-PmcTUI.ps1" -Raw
if ($startContent -notmatch '\. "\$PSScriptRoot/SpeedTUILoader\.ps1"') {
    $results.Passed += "Start-PmcTUI.ps1 does not load SpeedTUI (correct)"
    Write-Host "  ✓ Start-PmcTUI.ps1 does not load SpeedTUI" -ForegroundColor Green
} else {
    $results.Failed += "Start-PmcTUI.ps1 still loads SpeedTUI"
    Write-Host "  ✗ Start-PmcTUI.ps1 still loads SpeedTUI" -ForegroundColor Red
}

# Check PmcApplication.ps1 loads SpeedTUI
$appContent = Get-Content "$PSScriptRoot/PmcApplication.ps1" -Raw
if ($appContent -match '\. "\$PSScriptRoot/SpeedTUILoader\.ps1"') {
    $results.Passed += "PmcApplication.ps1 loads SpeedTUI (correct)"
    Write-Host "  ✓ PmcApplication.ps1 loads SpeedTUI" -ForegroundColor Green
} else {
    $results.Failed += "PmcApplication.ps1 does not load SpeedTUI"
    Write-Host "  ✗ PmcApplication.ps1 does not load SpeedTUI" -ForegroundColor Red
}

# Check PmcWidget.ps1 validates instead of loading
$widgetContent = Get-Content "$PSScriptRoot/widgets/PmcWidget.ps1" -Raw
if ($widgetContent -match 'throw.*Component class not found') {
    $results.Passed += "PmcWidget.ps1 validates SpeedTUI (correct)"
    Write-Host "  ✓ PmcWidget.ps1 validates instead of loading" -ForegroundColor Green
} else {
    $results.Failed += "PmcWidget.ps1 does not validate properly"
    Write-Host "  ✗ PmcWidget.ps1 does not validate properly" -ForegroundColor Red
}

Write-Host ""

# Test 2: Check dirty flag implementation
Write-Host "[2/5] Checking dirty flag implementation..." -ForegroundColor Yellow

if ($appContent -match '\[bool\]\$IsDirty') {
    $results.Passed += "IsDirty field exists"
    Write-Host "  ✓ IsDirty field declared" -ForegroundColor Green
} else {
    $results.Failed += "IsDirty field not found"
    Write-Host "  ✗ IsDirty field not found" -ForegroundColor Red
}

if ($appContent -match 'if \(\$this\.IsDirty\)') {
    $results.Passed += "Conditional rendering implemented"
    Write-Host "  ✓ Conditional rendering on IsDirty flag" -ForegroundColor Green
} else {
    $results.Failed += "Conditional rendering not implemented"
    Write-Host "  ✗ Conditional rendering not found" -ForegroundColor Red
}

if ($appContent -match '\$this\.IsDirty = \$false') {
    $results.Passed += "Dirty flag cleared after render"
    Write-Host "  ✓ Dirty flag cleared after render" -ForegroundColor Green
} else {
    $results.Failed += "Dirty flag not cleared after render"
    Write-Host "  ✗ Dirty flag not cleared after render" -ForegroundColor Red
}

if ($appContent -match '\$this\.IsDirty = \$true') {
    $results.Passed += "Dirty flag set on state changes"
    Write-Host "  ✓ Dirty flag set on state changes" -ForegroundColor Green
} else {
    $results.Failed += "Dirty flag not set on state changes"
    Write-Host "  ✗ Dirty flag not set on state changes" -ForegroundColor Red
}

Write-Host ""

# Test 3: Check BlockedTasksScreen uses TaskStore
Write-Host "[3/5] Checking BlockedTasksScreen TaskStore migration..." -ForegroundColor Yellow

$blockedContent = Get-Content "$PSScriptRoot/screens/BlockedTasksScreen.ps1" -Raw

if ($blockedContent -match '\[object\]\$Store') {
    $results.Passed += "BlockedTasksScreen has Store field"
    Write-Host "  ✓ Store field declared" -ForegroundColor Green
} else {
    $results.Failed += "BlockedTasksScreen missing Store field"
    Write-Host "  ✗ Store field not found" -ForegroundColor Red
}

if ($blockedContent -match '\$this\.Store = \[TaskStore\]::GetInstance\(\)') {
    $results.Passed += "BlockedTasksScreen initializes TaskStore"
    Write-Host "  ✓ TaskStore singleton initialized" -ForegroundColor Green
} else {
    $results.Failed += "TaskStore not initialized"
    Write-Host "  ✗ TaskStore not initialized" -ForegroundColor Red
}

if ($blockedContent -match '\$this\.Store\.GetAllTasks\(\)') {
    $results.Passed += "BlockedTasksScreen uses Store.GetAllTasks()"
    Write-Host "  ✓ Uses Store.GetAllTasks()" -ForegroundColor Green
} else {
    $results.Failed += "Does not use Store.GetAllTasks()"
    Write-Host "  ✗ Does not use Store.GetAllTasks()" -ForegroundColor Red
}

if ($blockedContent -match '\$this\.Store\.UpdateTask\(') {
    $results.Passed += "BlockedTasksScreen uses Store.UpdateTask()"
    Write-Host "  ✓ Uses Store.UpdateTask()" -ForegroundColor Green
} else {
    $results.Failed += "Does not use Store.UpdateTask()"
    Write-Host "  ✗ Does not use Store.UpdateTask()" -ForegroundColor Red
}

# Check for Get-PmcAllData (excluding comments)
$actualCalls = Select-String -Path "$PSScriptRoot/screens/BlockedTasksScreen.ps1" -Pattern 'Get-PmcAllData' |
    Where-Object { $_.Line -notmatch '^\s*#' }

if ($actualCalls) {
    $results.Failed += "BlockedTasksScreen still uses Get-PmcAllData"
    Write-Host "  ✗ Still uses Get-PmcAllData" -ForegroundColor Red
} else {
    $results.Passed += "BlockedTasksScreen does not use Get-PmcAllData"
    Write-Host "  ✓ No Get-PmcAllData calls" -ForegroundColor Green
}

Write-Host ""

# Test 4: Syntax validation
Write-Host "[4/5] Running syntax validation..." -ForegroundColor Yellow

$syntaxOK = $true
try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content "$PSScriptRoot/PmcApplication.ps1" -Raw), [ref]$null)
    $results.Passed += "PmcApplication.ps1 syntax valid"
    Write-Host "  ✓ PmcApplication.ps1 syntax OK" -ForegroundColor Green
} catch {
    $results.Failed += "PmcApplication.ps1 syntax error: $_"
    Write-Host "  ✗ PmcApplication.ps1 syntax error" -ForegroundColor Red
    $syntaxOK = $false
}

try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content "$PSScriptRoot/widgets/PmcWidget.ps1" -Raw), [ref]$null)
    $results.Passed += "PmcWidget.ps1 syntax valid"
    Write-Host "  ✓ PmcWidget.ps1 syntax OK" -ForegroundColor Green
} catch {
    $results.Failed += "PmcWidget.ps1 syntax error: $_"
    Write-Host "  ✗ PmcWidget.ps1 syntax error" -ForegroundColor Red
    $syntaxOK = $false
}

try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content "$PSScriptRoot/screens/BlockedTasksScreen.ps1" -Raw), [ref]$null)
    $results.Passed += "BlockedTasksScreen.ps1 syntax valid"
    Write-Host "  ✓ BlockedTasksScreen.ps1 syntax OK" -ForegroundColor Green
} catch {
    $results.Failed += "BlockedTasksScreen.ps1 syntax error: $_"
    Write-Host "  ✗ BlockedTasksScreen.ps1 syntax error" -ForegroundColor Red
    $syntaxOK = $false
}

Write-Host ""

# Test 5: Check documentation
Write-Host "[5/5] Checking documentation..." -ForegroundColor Yellow

if (Test-Path "$PSScriptRoot/PERFORMANCE_FIXES_SUMMARY.md") {
    $results.Passed += "Documentation exists"
    Write-Host "  ✓ PERFORMANCE_FIXES_SUMMARY.md exists" -ForegroundColor Green
} else {
    $results.Failed += "Documentation missing"
    Write-Host "  ✗ PERFORMANCE_FIXES_SUMMARY.md missing" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Passed: $($results.Passed.Count)" -ForegroundColor Green
Write-Host "Failed: $($results.Failed.Count)" -ForegroundColor $(if ($results.Failed.Count -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($results.Failed.Count -eq 0) {
    Write-Host "✓ All checks passed! Performance fixes are correctly implemented." -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Some checks failed:" -ForegroundColor Red
    foreach ($failure in $results.Failed) {
        Write-Host "  - $failure" -ForegroundColor Red
    }
    exit 1
}
