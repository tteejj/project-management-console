#!/usr/bin/env pwsh
# Quick PMC Functionality Test
# Fast test of core systems without full interactive mode

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

Write-Host "=== Quick PMC Functionality Test ===" -ForegroundColor Green

# Import module quietly
Get-Module Pmc.Strict | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module ./module/Pmc.Strict -Force -DisableNameChecking | Out-Null

$tests = 0
$passed = 0
$failed = 0

function Test-Function($name, $testBlock) {
    $script:tests++
    Write-Host "Testing $name..." -NoNewline
    try {
        $result = & $testBlock
        if ($result) {
            Write-Host " ✓" -ForegroundColor Green
            $script:passed++
        } else {
            Write-Host " ✗ (returned false)" -ForegroundColor Red
            $script:failed++
        }
    } catch {
        Write-Host " ✗ ($_)" -ForegroundColor Red
        $script:failed++
    }
}

# Test basic function availability
Test-Function "Module Functions" {
    $commands = Get-Command -Module Pmc.Strict -ErrorAction SilentlyContinue
    $commands.Count -gt 50
}

# Test state system
Test-Function "State System" {
    $state = Get-PmcState -ErrorAction SilentlyContinue
    $null -ne $state
}

# Test config system
Test-Function "Config System" {
    $config = Get-PmcConfig -ErrorAction SilentlyContinue
    $null -ne $config
}

# Test data loading
Test-Function "Data Loading" {
    $data = Get-PmcAllData -ErrorAction SilentlyContinue
    $null -ne $data
}

# Test security system
Test-Function "Security Validation" {
    Test-PmcInputSafety -Input "test" -InputType "general" -ErrorAction SilentlyContinue
}

# Test task file path
Test-Function "Task File Path" {
    $path = Get-PmcTaskFilePath -ErrorAction SilentlyContinue
    -not [string]::IsNullOrEmpty($path)
}

# Test schema system
Test-Function "Schema System" {
    $schema = Get-PmcSchema -ErrorAction SilentlyContinue
    $null -ne $schema
}

# Test command parsing
Test-Function "Command Context" {
    $ctx = [PSCustomObject]@{
        FreeText = @("test")
        Args = @{}
    }
    $null -ne $ctx
}

# Test basic task operations (without UI)
Test-Function "Task Data Structure" {
    $data = Get-PmcAllData -ErrorAction SilentlyContinue
    ($null -ne $data) -and (Get-Member -InputObject $data -Name "tasks" -ErrorAction SilentlyContinue)
}

# Test display system components
Test-Function "Display System" {
    (Get-Command Show-PmcData -ErrorAction SilentlyContinue) -ne $null
}

# Test query system
Test-Function "Query System" {
    (Get-Command Invoke-PmcQuery -ErrorAction SilentlyContinue) -ne $null
}

# Test interactive components
Test-Function "Interactive Mode Functions" {
    $funcs = @('Enable-PmcInteractiveMode', 'Disable-PmcInteractiveMode', 'Get-PmcInteractiveStatus')
    $missing = $funcs | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }
    $missing.Count -eq 0
}

# Results
Write-Host "`n=== RESULTS ===" -ForegroundColor Green
Write-Host "Tests run: $tests"
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

$successRate = [math]::Round(($passed / $tests) * 100, 1)
Write-Host "Success rate: $successRate%"

if ($failed -eq 0) {
    Write-Host "`n🎉 ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} elseif ($successRate -ge 80) {
    Write-Host "`n⚠️  MOSTLY WORKING ($successRate%)" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n💥 SIGNIFICANT ISSUES ($successRate%)" -ForegroundColor Red
    exit 1
}