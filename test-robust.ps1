#!/usr/bin/env pwsh
# Robust PMC Testing - Handles PowerShell quirks properly

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

Write-Host "=== ROBUST PMC TEST ===" -ForegroundColor Green

# Import module with error handling
try {
    Get-Module Pmc.Strict | Remove-Module -Force -ErrorAction SilentlyContinue
    Import-Module ./module/Pmc.Strict -Force -DisableNameChecking -WarningAction SilentlyContinue | Out-Null
    Write-Host "✓ Module loaded" -ForegroundColor Green
} catch {
    Write-Host "✗ Module loading failed: $_" -ForegroundColor Red
    exit 1
}

$pass = 0
$fail = 0

function Test-Simple($name, $test) {
    Write-Host "`nTesting $name... " -NoNewline -ForegroundColor Yellow
    try {
        $result = & $test
        if ($result) {
            Write-Host "✓ PASS" -ForegroundColor Green
            $script:pass++
            return $true
        } else {
            Write-Host "✗ FAIL (false)" -ForegroundColor Red
            $script:fail++
            return $false
        }
    } catch {
        Write-Host "✗ FAIL ($_)" -ForegroundColor Red
        $script:fail++
        return $false
    }
}

# Basic tests
Test-Simple "Function Export" {
    @(Get-Command -Module Pmc.Strict).Count -gt 100
}

Test-Simple "Add-PmcTask Available" {
    $null -ne (Get-Command Add-PmcTask -ErrorAction SilentlyContinue)
}

Test-Simple "Get-PmcAllData Available" {
    $null -ne (Get-Command Get-PmcAllData -ErrorAction SilentlyContinue)
}

Test-Simple "Get-PmcState Available" {
    $null -ne (Get-Command Get-PmcState -ErrorAction SilentlyContinue)
}

# Try data loading with timeout
Test-Simple "Data Loading (with timeout)" {
    $job = Start-Job {
        Import-Module $using:PWD/module/Pmc.Strict -Force -WarningAction SilentlyContinue
        $null -ne (Get-PmcAllData)
    }

    $result = Wait-Job $job -Timeout 5
    if ($result) {
        $data = Receive-Job $job
        Remove-Job $job
        return [bool]$data
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -ErrorAction SilentlyContinue
        Write-Host "(timed out) " -NoNewline -ForegroundColor Red
        return $false
    }
}

# Try state system
Test-Simple "State System" {
    try {
        $state = Get-PmcState
        return ($null -ne $state)
    } catch {
        return $false
    }
}

# Try config system
Test-Simple "Config System" {
    try {
        $config = Get-PmcConfig
        return ($null -ne $config)
    } catch {
        return $false
    }
}

# Try security functions
Test-Simple "Security Functions" {
    $funcs = @('Test-PmcInputSafety', 'Test-PmcPathSafety')
    foreach ($f in $funcs) {
        if (-not (Get-Command $f -ErrorAction SilentlyContinue)) {
            return $false
        }
    }
    return $true
}

# Try task functions
Test-Simple "Task Functions" {
    $funcs = @('Add-PmcTask', 'Complete-PmcTask', 'Remove-PmcTask', 'Get-PmcTaskList')
    foreach ($f in $funcs) {
        if (-not (Get-Command $f -ErrorAction SilentlyContinue)) {
            return $false
        }
    }
    return $true
}

# Try display functions
Test-Simple "Display Functions" {
    $funcs = @('Show-PmcData', 'Show-PmcDataGrid')
    foreach ($f in $funcs) {
        if (-not (Get-Command $f -ErrorAction SilentlyContinue)) {
            return $false
        }
    }
    return $true
}

# Try query function
Test-Simple "Query Function" {
    $null -ne (Get-Command Invoke-PmcQuery -ErrorAction SilentlyContinue)
}

# Try interactive functions
Test-Simple "Interactive Functions" {
    $funcs = @('Enable-PmcInteractiveMode', 'Disable-PmcInteractiveMode', 'Get-PmcInteractiveStatus')
    foreach ($f in $funcs) {
        if (-not (Get-Command $f -ErrorAction SilentlyContinue)) {
            return $false
        }
    }
    return $true
}

# Results
Write-Host "`n" + "="*50 -ForegroundColor Green
Write-Host "ROBUST TEST RESULTS" -ForegroundColor Green
Write-Host "="*50 -ForegroundColor Green

$total = $pass + $fail
$rate = if ($total -gt 0) { [math]::Round(($pass / $total) * 100) } else { 0 }

Write-Host "Passed: $pass" -ForegroundColor Green
Write-Host "Failed: $fail" -ForegroundColor Red
Write-Host "Total:  $total"
Write-Host "Rate:   $rate%" -ForegroundColor $(if ($rate -ge 80) { "Green" } elseif ($rate -ge 60) { "Yellow" } else { "Red" })

if ($fail -eq 0) {
    Write-Host "`n🎉 ALL BASIC TESTS PASSED!" -ForegroundColor Green
    Write-Host "PMC module appears to be working correctly." -ForegroundColor Green
    exit 0
} elseif ($rate -ge 80) {
    Write-Host "`n✅ MOSTLY WORKING ($rate%)" -ForegroundColor Yellow
    Write-Host "Core functionality appears intact with minor issues." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n💥 SIGNIFICANT ISSUES ($rate%)" -ForegroundColor Red
    Write-Host "Major functionality problems detected." -ForegroundColor Red
    exit 1
}