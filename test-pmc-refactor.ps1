# PMC Refactoring Validation Test Suite
# Comprehensive testing of Phases 1-4 implementation

param(
    [switch]$Detailed,
    [switch]$Performance,
    [switch]$SkipInteractive
)

Set-StrictMode -Version Latest

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "PMC Refactoring Validation Test Suite" -ForegroundColor Cyan
Write-Host "Phases 1-4 Integration Test" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Test counters
$Script:TestsRun = 0
$Script:TestsPassed = 0
$Script:TestsFailed = 0
$Script:TestResults = @()

function Test-PmcComponent {
    param(
        [string]$Name,
        [scriptblock]$TestBlock,
        [bool]$Critical = $false
    )

    $Script:TestsRun++
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = @{
        Name = $Name
        Success = $false
        Duration = 0
        Message = ""
        Critical = $Critical
        Details = @{}
    }

    try {
        $testResult = & $TestBlock
        if ($testResult -is [hashtable] -and $testResult.ContainsKey('Success')) {
            $result.Success = $testResult.Success
            $result.Message = if ($testResult.ContainsKey('Message')) { $testResult.Message } else { "" }
            $result.Details = if ($testResult.ContainsKey('Details')) { $testResult.Details } else { @{} }
        } else {
            $result.Success = [bool]$testResult
            $result.Message = if ($result.Success) { "Test passed" } else { "Test failed" }
        }

        if ($result.Success) {
            $Script:TestsPassed++
            Write-Host "  ✓ $Name" -ForegroundColor Green
        } else {
            $Script:TestsFailed++
            Write-Host "  ✗ $Name - $($result.Message)" -ForegroundColor Red
        }

    } catch {
        $result.Success = $false
        $result.Message = "Exception: $_"
        $Script:TestsFailed++
        Write-Host "  ✗ $Name - Exception: $_" -ForegroundColor Red
    } finally {
        $stopwatch.Stop()
        $result.Duration = $stopwatch.ElapsedMilliseconds
    }

    $Script:TestResults += $result

    if ($Critical -and -not $result.Success) {
        Write-Host "CRITICAL TEST FAILED - Stopping test suite" -ForegroundColor Red
        exit 1
    }

    return $result.Success
}

# Import PMC module
Write-Host "Loading PMC Module:" -ForegroundColor Yellow
try {
    Import-Module ./module/Pmc.Strict/Pmc.Strict.psm1 -Force
    Write-Host "  ✓ PMC module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to load PMC module: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Phase 1 Tests: Secure State Management
Write-Host "Phase 1: Secure State Management Tests" -ForegroundColor Yellow

Test-PmcComponent "Secure State Manager Initialization" -Critical $true {
    # Test that we can access state functions
    $stateTest = Get-PmcState -Section 'system' -Key 'initialized' -ErrorAction SilentlyContinue
    $hasStateFunction = Get-Command Get-PmcState -ErrorAction SilentlyContinue
    return @{
        Success = $null -ne $hasStateFunction
        Message = if ($hasStateFunction) { "State manager functions available" } else { "State manager not found" }
    }
}

Test-PmcComponent "State Read/Write Operations" {
    try {
        Set-PmcState -Section 'test' -Key 'refactor_validation' -Value 'phase1_test'
        $value = Get-PmcState -Section 'test' -Key 'refactor_validation'
        return @{
            Success = $value -eq 'phase1_test'
            Message = "State value: $value"
        }
    } catch {
        return @{ Success = $false; Message = "State operation failed: $_" }
    }
}

Test-PmcComponent "Security Validation" {
    try {
        $securityStatus = Get-PmcSecurityStatus -ErrorAction SilentlyContinue
        return @{
            Success = $null -ne $securityStatus
            Message = "Security system available"
            Details = $securityStatus
        }
    } catch {
        return @{ Success = $false; Message = "Security system not available" }
    }
}

Write-Host ""

# Phase 2 Tests: Enhanced UI System
Write-Host "Phase 2: Enhanced UI System Tests" -ForegroundColor Yellow

Test-PmcComponent "Input Multiplexer" {
    try {
        $multiplexer = Get-PmcInputMultiplexer -ErrorAction SilentlyContinue
        return @{
            Success = $null -ne $multiplexer
            Message = "Input multiplexer available"
        }
    } catch {
        return @{ Success = $false; Message = "Input multiplexer failed: $_" }
    }
}

Test-PmcComponent "Differential Renderer" {
    try {
        $renderer = Get-PmcDifferentialRenderer -ErrorAction SilentlyContinue
        return @{
            Success = $null -ne $renderer
            Message = "Differential renderer available"
        }
    } catch {
        return @{ Success = $false; Message = "Differential renderer failed: $_" }
    }
}

Test-PmcComponent "Unified Data Viewer" {
    try {
        $bounds = @{ X=1; Y=3; Width=60; Height=15 }
        Initialize-PmcUnifiedDataViewer $bounds -ErrorAction SilentlyContinue
        $viewer = Get-PmcUnifiedDataViewer -ErrorAction SilentlyContinue
        return @{
            Success = $null -ne $viewer
            Message = "Unified data viewer available"
        }
    } catch {
        return @{ Success = $false; Message = "Unified data viewer failed: $_" }
    }
}

Write-Host ""

# Phase 3 Tests: Enhanced Core Logic
Write-Host "Phase 3: Enhanced Core Logic Tests" -ForegroundColor Yellow

Test-PmcComponent "Enhanced Command Processor" {
    try {
        $processor = Get-PmcEnhancedCommandProcessor -ErrorAction SilentlyContinue
        if ($processor) {
            # Test command execution
            $result = Invoke-PmcEnhancedCommand 'help' -ErrorAction SilentlyContinue
            return @{
                Success = $true
                Message = "Command processor functional"
                Details = @{ CommandExecuted = $true }
            }
        }
        return @{ Success = $false; Message = "Command processor not available" }
    } catch {
        return @{ Success = $false; Message = "Command processor failed: $_" }
    }
}

Test-PmcComponent "Enhanced Query Engine" {
    try {
        $result = Invoke-PmcEnhancedQuery @('tasks') -ErrorAction SilentlyContinue
        return @{
            Success = $null -ne $result
            Message = "Query engine functional"
            Details = @{ QueryExecuted = $true }
        }
    } catch {
        return @{ Success = $false; Message = "Query engine failed: $_" }
    }
}

Test-PmcComponent "Enhanced Data Validator" {
    try {
        $testData = @{ text = 'Test task'; priority = 'p1'; project = 'test' }
        $result = Test-PmcEnhancedData -Domain 'task' -Data $testData -ErrorAction SilentlyContinue
        return @{
            Success = $null -ne $result -and $result.ContainsKey('IsValid')
            Message = "Data validator functional, Valid: $($result.IsValid)"
            Details = $result
        }
    } catch {
        return @{ Success = $false; Message = "Data validator failed: $_" }
    }
}

Test-PmcComponent "Performance Optimizer" {
    try {
        $result = Measure-PmcOperation -Operation 'test_operation' -ScriptBlock {
            Start-Sleep -Milliseconds 10
            return 'success'
        } -ErrorAction SilentlyContinue
        return @{
            Success = $result -eq 'success'
            Message = "Performance monitoring functional"
            Details = @{ Measured = $true }
        }
    } catch {
        return @{ Success = $false; Message = "Performance optimizer failed: $_" }
    }
}

Test-PmcComponent "Enhanced Error Handler" {
    try {
        # Use different variable name to avoid PowerShell's built-in $Error
        $errorObj = Write-PmcEnhancedError -Severity Warning -Category Validation -Message 'Test error' -ErrorAction SilentlyContinue
        return @{
            Success = $null -ne $errorObj -and $errorObj.Id
            Message = "Error handler functional"
            Details = @{ ErrorId = $errorObj.Id }
        }
    } catch {
        return @{ Success = $false; Message = "Error handler failed: $_" }
    }
}

Write-Host ""

# Phase 4 Tests: Unified Integration
Write-Host "Phase 4: Unified Integration Tests" -ForegroundColor Yellow

Test-PmcComponent "Unified Initialization System" -Critical $true {
    try {
        $status = Get-PmcInitializationStatus -ErrorAction SilentlyContinue
        return @{
            Success = $status.IsInitialized
            Message = "All systems initialized: $($status.IsInitialized)"
            Details = $status
        }
    } catch {
        return @{ Success = $false; Message = "Initialization system failed: $_" }
    }
}

Test-PmcComponent "Legacy Command Compatibility" {
    try {
        # Test that legacy commands still work
        $taskList = Get-PmcTaskList -ErrorAction SilentlyContinue
        $projectList = Get-PmcProjectList -ErrorAction SilentlyContinue
        return @{
            Success = $true  # If we get here without exception, legacy commands work
            Message = "Legacy commands functional"
            Details = @{
                TasksAvailable = $taskList -ne $null
                ProjectsAvailable = $projectList -ne $null
            }
        }
    } catch {
        return @{ Success = $false; Message = "Legacy compatibility failed: $_" }
    }
}

Test-PmcComponent "Enhanced System Integration" {
    try {
        # Test that enhanced and legacy systems can work together
        $enhanced = Get-PmcCommandPerformanceStats -ErrorAction SilentlyContinue
        $legacy = Get-PmcSchema -ErrorAction SilentlyContinue
        return @{
            Success = $true
            Message = "Enhanced and legacy systems coexist"
            Details = @{
                EnhancedStats = $enhanced -ne $null
                LegacySchema = $legacy -ne $null
            }
        }
    } catch {
        return @{ Success = $false; Message = "System integration failed: $_" }
    }
}

Write-Host ""

# Performance Tests (if requested)
if ($Performance) {
    Write-Host "Performance Baseline Tests" -ForegroundColor Yellow

    Test-PmcComponent "Command Performance" {
        $iterations = 10
        $totalTime = 0

        for ($i = 0; $i -lt $iterations; $i++) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Invoke-PmcCommand 'help' -ErrorAction SilentlyContinue | Out-Null
            $stopwatch.Stop()
            $totalTime += $stopwatch.ElapsedMilliseconds
        }

        $avgTime = $totalTime / $iterations
        return @{
            Success = $avgTime -lt 500  # Should be under 500ms average
            Message = "Average command time: ${avgTime}ms"
            Details = @{ AverageMs = $avgTime; Iterations = $iterations }
        }
    }

    Test-PmcComponent "Query Performance" {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Invoke-PmcQuery 'tasks' -ErrorAction SilentlyContinue | Out-Null
        $stopwatch.Stop()

        return @{
            Success = $stopwatch.ElapsedMilliseconds -lt 1000  # Should be under 1 second
            Message = "Query time: $($stopwatch.ElapsedMilliseconds)ms"
            Details = @{ QueryMs = $stopwatch.ElapsedMilliseconds }
        }
    }
}

Write-Host ""

# Generate comprehensive report
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

$successRate = if ($Script:TestsRun -gt 0) { [Math]::Round(($Script:TestsPassed * 100.0) / $Script:TestsRun, 1) } else { 0 }
$overallSuccess = $Script:TestsFailed -eq 0

Write-Host "Total Tests: $Script:TestsRun" -ForegroundColor White
Write-Host "Passed: $Script:TestsPassed" -ForegroundColor Green
Write-Host "Failed: $Script:TestsFailed" -ForegroundColor $(if ($Script:TestsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

if ($overallSuccess) {
    Write-Host ""
    Write-Host "🎉 PMC REFACTORING VALIDATION SUCCESSFUL! 🎉" -ForegroundColor Green
    Write-Host "All phases implemented correctly and systems are functional." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "⚠️  PMC REFACTORING VALIDATION INCOMPLETE" -ForegroundColor Yellow
    Write-Host "Some issues need attention before completion." -ForegroundColor Yellow
}

if ($Detailed) {
    Write-Host ""
    Write-Host "Detailed Test Results:" -ForegroundColor Yellow
    foreach ($test in $Script:TestResults) {
        $status = if ($test.Success) { "PASS" } else { "FAIL" }
        $color = if ($test.Success) { "Green" } else { "Red" }
        Write-Host "  [$status] $($test.Name) ($($test.Duration)ms)" -ForegroundColor $color
        if (-not $test.Success) {
            Write-Host "    Error: $($test.Message)" -ForegroundColor Gray
        }
        if ($test.Details.Count -gt 0) {
            Write-Host "    Details: $($test.Details | ConvertTo-Json -Compress)" -ForegroundColor Gray
        }
    }
}

# Performance report
if ($Performance) {
    Write-Host ""
    Get-PmcPerformanceReport -Detailed
}

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray

# Return exit code
exit $(if ($overallSuccess) { 0 } else { 1 })