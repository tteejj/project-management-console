#!/usr/bin/env pwsh
# PMC Module Loading Test
# Tests the critical path of module initialization and basic functionality

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "=== PMC Module Loading Test ===" -ForegroundColor Green

$testResults = @()

function Add-TestResult {
    param($Name, $Status, $Details = "", $Error = "")
    $testResults += [PSCustomObject]@{
        Test = $Name
        Status = $Status
        Details = $Details
        Error = $Error
        Timestamp = Get-Date
    }
}

try {
    # Test 1: Module Import
    Write-Host "`n1. Testing module import..." -ForegroundColor Yellow
    $moduleePath = "./module/Pmc.Strict"

    if (-not (Test-Path $moduleePath)) {
        throw "Module path not found: $moduleePath"
    }

    # Remove any existing module
    Get-Module Pmc.Strict | Remove-Module -Force -ErrorAction SilentlyContinue

    $importStart = Get-Date
    Import-Module $moduleePath -Force -DisableNameChecking
    $importTime = (Get-Date) - $importStart

    Add-TestResult -Name "Module Import" -Status "PASS" -Details "Imported in $($importTime.TotalMilliseconds)ms"
    Write-Host "✓ Module imported successfully" -ForegroundColor Green

    # Test 2: Check exported functions
    Write-Host "`n2. Testing exported functions..." -ForegroundColor Yellow
    $commands = Get-Command -Module Pmc.Strict
    $functionCount = $commands.Count

    # Key functions that should be available
    $criticalFunctions = @(
        'Invoke-PmcCommand',
        'Add-PmcTask',
        'Get-PmcTaskList',
        'Complete-PmcTask',
        'Get-PmcState',
        'Show-PmcData',
        'Enable-PmcInteractiveMode'
    )

    $missingFunctions = @()
    foreach ($func in $criticalFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $missingFunctions += $func
        }
    }

    if ($missingFunctions.Count -eq 0) {
        Add-TestResult -Name "Critical Functions" -Status "PASS" -Details "$functionCount total functions, all critical functions present"
        Write-Host "✓ All critical functions exported ($functionCount total)" -ForegroundColor Green
    } else {
        Add-TestResult -Name "Critical Functions" -Status "FAIL" -Details "Missing: $($missingFunctions -join ', ')"
        Write-Host "✗ Missing critical functions: $($missingFunctions -join ', ')" -ForegroundColor Red
    }

    # Test 3: State system initialization
    Write-Host "`n3. Testing state system..." -ForegroundColor Yellow
    try {
        $state = Get-PmcState
        $sections = $state.Keys

        $expectedSections = @('Config', 'Security', 'Debug', 'Display', 'Interactive', 'Commands')
        $missingSections = $expectedSections | Where-Object { $_ -notin $sections }

        if ($missingSections.Count -eq 0) {
            Add-TestResult -Name "State System" -Status "PASS" -Details "All expected state sections present: $($sections -join ', ')"
            Write-Host "✓ State system initialized with sections: $($sections -join ', ')" -ForegroundColor Green
        } else {
            Add-TestResult -Name "State System" -Status "WARN" -Details "Missing sections: $($missingSections -join ', ')"
            Write-Host "⚠ Missing state sections: $($missingSections -join ', ')" -ForegroundColor Yellow
        }
    } catch {
        Add-TestResult -Name "State System" -Status "FAIL" -Error $_.ToString()
        Write-Host "✗ State system failed: $_" -ForegroundColor Red
    }

    # Test 4: Configuration system
    Write-Host "`n4. Testing configuration system..." -ForegroundColor Yellow
    try {
        $config = Get-PmcConfig
        if ($config) {
            Add-TestResult -Name "Configuration" -Status "PASS" -Details "Config loaded successfully"
            Write-Host "✓ Configuration system working" -ForegroundColor Green
        } else {
            Add-TestResult -Name "Configuration" -Status "WARN" -Details "Config is empty/null"
            Write-Host "⚠ Configuration returned empty" -ForegroundColor Yellow
        }
    } catch {
        Add-TestResult -Name "Configuration" -Status "FAIL" -Error $_.ToString()
        Write-Host "✗ Configuration failed: $_" -ForegroundColor Red
    }

    # Test 5: Data system initialization
    Write-Host "`n5. Testing data system..." -ForegroundColor Yellow
    try {
        $data = Get-PmcAllData
        $dataPath = Get-PmcTaskFilePath

        if ($data) {
            $taskCount = if ($data.tasks) { $data.tasks.Count } else { 0 }
            $projectCount = if ($data.projects) { $data.projects.Count } else { 0 }

            Add-TestResult -Name "Data System" -Status "PASS" -Details "Data loaded: $taskCount tasks, $projectCount projects from $dataPath"
            Write-Host "✓ Data system working - $taskCount tasks, $projectCount projects" -ForegroundColor Green
            Write-Host "  Data path: $dataPath" -ForegroundColor Gray
        } else {
            Add-TestResult -Name "Data System" -Status "FAIL" -Details "Data load returned null"
            Write-Host "✗ Data system returned null" -ForegroundColor Red
        }
    } catch {
        Add-TestResult -Name "Data System" -Status "FAIL" -Error $_.ToString()
        Write-Host "✗ Data system failed: $_" -ForegroundColor Red
    }

    # Test 6: Security system
    Write-Host "`n6. Testing security system..." -ForegroundColor Yellow
    try {
        $securityTest = Test-PmcInputSafety -Input "test input" -InputType "general"
        $securityState = Get-PmcSecurityState

        if ($securityState) {
            Add-TestResult -Name "Security System" -Status "PASS" -Details "Security validation working"
            Write-Host "✓ Security system initialized" -ForegroundColor Green
        } else {
            Add-TestResult -Name "Security System" -Status "FAIL" -Details "Security state is null"
            Write-Host "✗ Security state is null" -ForegroundColor Red
        }
    } catch {
        Add-TestResult -Name "Security System" -Status "FAIL" -Error $_.ToString()
        Write-Host "✗ Security system failed: $_" -ForegroundColor Red
    }

} catch {
    Add-TestResult -Name "Module Loading" -Status "FAIL" -Error $_.ToString()
    Write-Host "✗ CRITICAL: Module loading failed: $_" -ForegroundColor Red
}

# Test Results Summary
Write-Host "`n=== TEST RESULTS SUMMARY ===" -ForegroundColor Green
$passCount = ($testResults | Where-Object Status -eq "PASS").Count
$warnCount = ($testResults | Where-Object Status -eq "WARN").Count
$failCount = ($testResults | Where-Object Status -eq "FAIL").Count

Write-Host "PASSED: $passCount" -ForegroundColor Green
Write-Host "WARNED: $warnCount" -ForegroundColor Yellow
Write-Host "FAILED: $failCount" -ForegroundColor Red

Write-Host "`nDetailed Results:" -ForegroundColor Gray
$testResults | ForEach-Object {
    $color = switch ($_.Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
    }
    Write-Host "[$($_.Status)] $($_.Test): $($_.Details)" -ForegroundColor $color
    if ($_.Error) {
        Write-Host "  Error: $($_.Error)" -ForegroundColor Red
    }
}

# Overall result
if ($failCount -eq 0) {
    Write-Host "`n🎉 MODULE LOADING TEST PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n💥 MODULE LOADING TEST FAILED" -ForegroundColor Red
    exit 1
}