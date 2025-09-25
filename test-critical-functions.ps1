# PMC Critical Function Tests
# Simple validation of core functionality before integration

param([switch]$Verbose)

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "PMC Critical Function Validation" -ForegroundColor Cyan
Write-Host "Testing core functionality before integration" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Import PMC without interactive mode
$env:PMC_NON_INTERACTIVE = "1"
Import-Module ./module/Pmc.Strict/Pmc.Strict.psm1 -Force

$TestsPassed = 0
$TestsFailed = 0

function Test-Function {
    param([string]$Name, [scriptblock]$Test)

    try {
        $result = & $Test
        if ($result) {
            Write-Host "  ✓ $Name" -ForegroundColor Green
            $Script:TestsPassed++
        } else {
            Write-Host "  ✗ $Name - Test returned false" -ForegroundColor Red
            $Script:TestsFailed++
        }
    } catch {
        Write-Host "  ✗ $Name - Error: $_" -ForegroundColor Red
        $Script:TestsFailed++
        if ($Verbose) {
            Write-Host "    Details: $($_.Exception.Message)" -ForegroundColor Gray
        }
    }
}

Write-Host "Core Module Functions:" -ForegroundColor Yellow

Test-Function "PMC Module Loaded" {
    return (Get-Module "Pmc.Strict") -ne $null
}

Test-Function "State Management Available" {
    return (Get-Command "Get-PmcState" -ErrorAction SilentlyContinue) -ne $null
}

Test-Function "Enhanced Systems Initialized" {
    $status = Get-PmcInitializationStatus -ErrorAction SilentlyContinue
    return $status -and $status.IsInitialized
}

Test-Function "Task List Function" {
    $tasks = Get-PmcTaskList -ErrorAction SilentlyContinue
    return $tasks -ne $null
}

Test-Function "Project List Function" {
    $projects = Get-PmcProjectList -ErrorAction SilentlyContinue
    return $projects -ne $null
}

Test-Function "Help System" {
    $help = Get-PmcHelpData -ErrorAction SilentlyContinue
    return $help -ne $null -and $help.Count -gt 0
}

Test-Function "Schema System" {
    $schema = Get-PmcSchema -ErrorAction SilentlyContinue
    return $schema -ne $null
}

Write-Host ""
Write-Host "Enhanced System Functions:" -ForegroundColor Yellow

Test-Function "Enhanced Command Processor" {
    $processor = Get-PmcEnhancedCommandProcessor -ErrorAction SilentlyContinue
    return $processor -ne $null
}

Test-Function "Enhanced Query Engine" {
    $result = Invoke-PmcEnhancedQuery @('tasks') -ErrorAction SilentlyContinue
    return $result -ne $null
}

Test-Function "Enhanced Data Validator" {
    $testData = @{ text = "Test"; priority = "p1" }
    $result = Test-PmcEnhancedData -Domain "task" -Data $testData -ErrorAction SilentlyContinue
    return $result -ne $null -and $result.ContainsKey('IsValid')
}

Test-Function "Performance Monitoring" {
    $result = Measure-PmcOperation -Operation "test" -ScriptBlock { return "success" } -ErrorAction SilentlyContinue
    return $result -eq "success"
}

Write-Host ""
Write-Host "Integration Functions:" -ForegroundColor Yellow

Test-Function "Legacy Command Execution" {
    # Test non-interactive command
    $result = $null
    try {
        # Capture help without interactive display
        $originalErrorAction = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'

        # Test basic command parsing
        $tokens = ConvertTo-PmcTokens "help"
        $result = $tokens -ne $null -and $tokens.Count -gt 0

        $ErrorActionPreference = $originalErrorAction
    } catch {
        $result = $false
    }
    return $result
}

Test-Function "Enhanced Command Execution" {
    $result = Invoke-PmcEnhancedCommand "help" -ErrorAction SilentlyContinue
    return $result -ne $null
}

Test-Function "Query System Integration" {
    # Test basic query without interactive output
    try {
        $result = Invoke-PmcQuery "tasks" -ErrorAction SilentlyContinue 2>$null
        return $true  # If no exception, query system is working
    } catch {
        return $false
    }
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

$TotalTests = $TestsPassed + $TestsFailed
$SuccessRate = if ($TotalTests -gt 0) { [Math]::Round(($TestsPassed * 100.0) / $TotalTests, 1) } else { 0 }

Write-Host "Total Tests: $TotalTests"
Write-Host "Passed: $TestsPassed" -ForegroundColor Green
Write-Host "Failed: $TestsFailed" -ForegroundColor $(if ($TestsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "Success Rate: $SuccessRate%" -ForegroundColor $(if ($SuccessRate -ge 90) { "Green" } elseif ($SuccessRate -ge 70) { "Yellow" } else { "Red" })

Write-Host ""
if ($TestsFailed -eq 0) {
    Write-Host "🎉 ALL CRITICAL FUNCTIONS WORKING - Safe to proceed with integration!" -ForegroundColor Green
    Write-Host "Ready to begin migrating legacy state to secure state manager." -ForegroundColor Green
} else {
    Write-Host "⚠️  Some critical functions failed - Need to fix before integration" -ForegroundColor Yellow
    Write-Host "Review failures above before proceeding." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Migrate src files from \$Script:PmcGlobalState to secure state manager"
Write-Host "2. Replace entry points with enhanced UI system"
Write-Host "3. Wire enhanced systems to existing command logic"
Write-Host "4. Complete core logic refactor with AST-based executor"

exit $TestsFailed