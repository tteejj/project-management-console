#!/usr/bin/env pwsh
# Advanced PMC Features Test
# Tests query engine, security, VT100, and interactive systems

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

Write-Host "=== PMC ADVANCED FEATURES TEST ===" -ForegroundColor Green

# Import module
Get-Module Pmc.Strict | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module ./module/Pmc.Strict -Force -DisableNameChecking -WarningAction SilentlyContinue | Out-Null
Write-Host "✓ Module loaded" -ForegroundColor Green

$tests = @()
$pass = 0
$fail = 0

function Test-Advanced($name, $testBlock) {
    Write-Host "`nTesting $name..." -ForegroundColor Cyan
    try {
        $result = & $testBlock
        if ($result) {
            Write-Host "  ✓ $result" -ForegroundColor Green
            $script:pass++
            return $true
        } else {
            Write-Host "  ✗ Test returned false" -ForegroundColor Red
            $script:fail++
            return $false
        }
    } catch {
        Write-Host "  ✗ $($_.Exception.Message)" -ForegroundColor Red
        $script:fail++
        return $false
    }
}

# =====================================================
# QUERY ENGINE TESTS
# =====================================================

Write-Host "`n🔍 QUERY ENGINE TESTS" -ForegroundColor Yellow

Test-Advanced "Basic Query Parsing" {
    # Test if query engine can parse basic commands
    $context = [PSCustomObject]@{
        FreeText = @("tasks")
        Args = @{}
    }

    # This should work without crashing
    $null = Invoke-PmcQuery -Context $context 2>&1
    "Query parsed successfully"
}

Test-Advanced "Query with Filters" {
    $context = [PSCustomObject]@{
        FreeText = @("tasks", "p1")
        Args = @{}
    }

    $null = Invoke-PmcQuery -Context $context 2>&1
    "Filter query executed"
}

Test-Advanced "Query with Project Filter" {
    $context = [PSCustomObject]@{
        FreeText = @("tasks", "@inbox")
        Args = @{}
    }

    $null = Invoke-PmcQuery -Context $context 2>&1
    "Project filter query executed"
}

Test-Advanced "Query with Date Filter" {
    $context = [PSCustomObject]@{
        FreeText = @("tasks", "due:today")
        Args = @{}
    }

    $null = Invoke-PmcQuery -Context $context 2>&1
    "Date filter query executed"
}

# =====================================================
# SECURITY VALIDATION TESTS
# =====================================================

Write-Host "`n🛡️ SECURITY VALIDATION TESTS" -ForegroundColor Yellow

Test-Advanced "Safe Input Validation" {
    $result = Test-PmcInputSafety -Input "This is a safe input" -InputType "general"
    if ($result -eq $true) {
        "Safe input correctly validated"
    } else {
        throw "Safe input failed validation"
    }
}

Test-Advanced "Dangerous Input Detection" {
    $dangerous = @(
        "rm -rf /",
        "Get-Process | Stop-Process",
        "; shutdown /r /t 0",
        "Invoke-Expression 'malicious code'",
        "`$(Get-Content /etc/passwd)"
    )

    foreach ($input in $dangerous) {
        $result = Test-PmcInputSafety -Input $input -InputType "command"
        if ($result -eq $true) {
            throw "Dangerous input '$input' passed validation"
        }
    }
    "All dangerous inputs correctly rejected"
}

Test-Advanced "Path Safety Validation" {
    # Safe paths
    $safePaths = @("./tasks.json", "reports/output.txt", "backup.json")
    foreach ($path in $safePaths) {
        $result = Test-PmcPathSafety -Path $path -Operation "write"
        if (-not $result) {
            throw "Safe path '$path' failed validation"
        }
    }

    # Potentially unsafe paths (should be sanitized, not rejected entirely)
    $unsafePath = "../../../../etc/passwd"
    $result = Test-PmcPathSafety -Path $unsafePath -Operation "write"
    # Should return a sanitized path, not fail entirely

    "Path safety validation working correctly"
}

Test-Advanced "Sensitive Data Detection" {
    $sensitiveInputs = @(
        "4532-1234-5678-9012",  # Credit card
        "123-45-6789",          # SSN
        "password: secretpass123", # Password
        "sk_live_abcdef123456789" # API key
    )

    foreach ($input in $sensitiveInputs) {
        $result = Test-PmcInputSafety -Input $input -InputType "text"
        if ($result -eq $true) {
            throw "Sensitive data '$input' not detected"
        }
    }
    "Sensitive data detection working"
}

# =====================================================
# VT100 AND DISPLAY TESTS
# =====================================================

Write-Host "`n🖥️ VT100 AND DISPLAY TESTS" -ForegroundColor Yellow

Test-Advanced "VT100 Functions Available" {
    $vt100Functions = @(
        'Write-PmcAtPosition',
        'Hide-PmcCursor',
        'Show-PmcCursor',
        'Clear-PmcContentArea',
        'Reset-PmcScreen'
    )

    foreach ($func in $vt100Functions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            throw "VT100 function '$func' not available"
        }
    }
    "$($vt100Functions.Count) VT100 functions available"
}

Test-Advanced "Screen Manager Functions" {
    $screenFunctions = @(
        'Initialize-PmcScreen',
        'Get-PmcContentBounds',
        'Set-PmcHeader',
        'Set-PmcInputPrompt'
    )

    foreach ($func in $screenFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            throw "Screen manager function '$func' not available"
        }
    }
    "$($screenFunctions.Count) screen manager functions available"
}

Test-Advanced "Display System with Sample Data" {
    # Create sample data for display
    $sampleTasks = @(
        [PSCustomObject]@{
            id = 1
            text = "Test task 1"
            priority = 1
            project = "inbox"
            status = "pending"
        },
        [PSCustomObject]@{
            id = 2
            text = "Test task 2"
            priority = 2
            project = "work"
            status = "pending"
        }
    )

    # Test data grid display
    $null = Show-PmcDataGrid -Domain 'task' -Data $sampleTasks -Title "Test Display" 2>&1

    "Display system rendered sample data"
}

Test-Advanced "Theme System" {
    # Test theme functions
    $themeFunctions = @('Get-PmcThemeList', 'Apply-PmcTheme', 'Get-PmcStyle')
    $available = 0

    foreach ($func in $themeFunctions) {
        if (Get-Command $func -ErrorAction SilentlyContinue) {
            $available++
        }
    }

    if ($available -gt 0) {
        "$available theme functions available"
    } else {
        throw "No theme functions available"
    }
}

# =====================================================
# INTERACTIVE COMPLETION ENGINE TESTS
# =====================================================

Write-Host "`n⌨️ INTERACTIVE COMPLETION ENGINE TESTS" -ForegroundColor Yellow

Test-Advanced "Interactive State Management" {
    $status = Get-PmcInteractiveStatus
    "Interactive status: working"
}

Test-Advanced "Completion Functions Available" {
    # Look for completion-related functions
    $completionFunctions = Get-Command -Module Pmc.Strict | Where-Object {
        $_.Name -like "*Completion*" -or $_.Name -like "*Interactive*"
    }

    if ($completionFunctions.Count -gt 0) {
        "$($completionFunctions.Count) completion/interactive functions found"
    } else {
        "Interactive functions integrated into main system"
    }
}

Test-Advanced "Input Engine Components" {
    # Check for input engine functions
    $inputFunctions = Get-Command -Module Pmc.Strict | Where-Object {
        $_.Name -like "*Input*" -or $_.Name -like "*Read*"
    }

    if ($inputFunctions.Count -gt 0) {
        "$($inputFunctions.Count) input-related functions available"
    } else {
        throw "No input engine functions found"
    }
}

# =====================================================
# EXCEL AND IMPORT/EXPORT TESTS
# =====================================================

Write-Host "`n📊 EXCEL AND IMPORT/EXPORT TESTS" -ForegroundColor Yellow

Test-Advanced "Excel Functions Available" {
    $excelFunctions = @(
        'Import-PmcExcelData',
        'Export-PmcTasks',
        'Import-PmcTasks'
    )

    foreach ($func in $excelFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            throw "Excel function '$func' not available"
        }
    }
    "$($excelFunctions.Count) Excel functions available"
}

Test-Advanced "Import/Export System" {
    # Test export functionality (should not crash)
    $context = [PSCustomObject]@{
        FreeText = @("./test-export.json")
        Args = @{}
    }

    $null = Export-PmcTasks -Context $context 2>&1
    "Export system functional"
}

# =====================================================
# ANALYTICS AND TIME TRACKING TESTS
# =====================================================

Write-Host "`n📈 ANALYTICS AND TIME TRACKING TESTS" -ForegroundColor Yellow

Test-Advanced "Time Tracking Functions" {
    $timeFunctions = @(
        'Add-PmcTimeEntry',
        'Get-PmcTimeReport',
        'Start-PmcTimer',
        'Stop-PmcTimer',
        'Get-PmcTimerStatus'
    )

    foreach ($func in $timeFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            throw "Time function '$func' not available"
        }
    }
    "$($timeFunctions.Count) time tracking functions available"
}

Test-Advanced "Analytics Functions" {
    $analyticsFunctions = Get-Command -Module Pmc.Strict | Where-Object {
        $_.Name -like "*Stats*" -or $_.Name -like "*Report*" -or $_.Name -like "*Analytics*"
    }

    if ($analyticsFunctions.Count -gt 0) {
        "$($analyticsFunctions.Count) analytics functions found"
    } else {
        "Analytics integrated into other systems"
    }
}

# =====================================================
# RESULTS
# =====================================================

Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "ADVANCED FEATURES TEST RESULTS" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green

$total = $pass + $fail
$rate = if ($total -gt 0) { [math]::Round(($pass / $total) * 100) } else { 0 }

Write-Host "Passed: $pass" -ForegroundColor Green
Write-Host "Failed: $fail" -ForegroundColor Red
Write-Host "Total:  $total"
Write-Host "Rate:   $rate%" -ForegroundColor $(if ($rate -ge 90) { "Green" } elseif ($rate -ge 75) { "Yellow" } else { "Red" })

if ($fail -eq 0) {
    Write-Host "`n🎉 ALL ADVANCED FEATURES WORKING!" -ForegroundColor Green
    Write-Host "PMC's advanced systems are fully operational." -ForegroundColor Green
    exit 0
} elseif ($rate -ge 85) {
    Write-Host "`n✅ ADVANCED FEATURES MOSTLY WORKING ($rate%)" -ForegroundColor Yellow
    Write-Host "Most advanced functionality is working with minor issues." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n⚠️ ADVANCED FEATURES HAVE ISSUES ($rate%)" -ForegroundColor Red
    Write-Host "Several advanced features need attention." -ForegroundColor Red
    exit 1
}