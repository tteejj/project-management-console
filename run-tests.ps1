# PMC Test Runner
# Runs Pester tests and provides detailed reporting

param(
    [string]$TestPath = "./tests/PMC.Tests.ps1",
    [switch]$Detailed,
    [switch]$Coverage
)

# Ensure Pester is available
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Installing Pester module..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -Scope CurrentUser
}

Import-Module Pester -Force

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "PMC Refactoring Safety Tests" -ForegroundColor Cyan
Write-Host "Running baseline validation before integration" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Configure Pester
$PesterConfiguration = New-PesterConfiguration
$PesterConfiguration.Run.Path = $TestPath
$PesterConfiguration.Output.Verbosity = if ($Detailed) { 'Detailed' } else { 'Normal' }
$PesterConfiguration.TestResult.Enabled = $true
$PesterConfiguration.TestResult.OutputPath = './tests/TestResults.xml'

if ($Coverage) {
    $PesterConfiguration.CodeCoverage.Enabled = $true
    $PesterConfiguration.CodeCoverage.Path = './module/Pmc.Strict/**/*.ps1'
    $PesterConfiguration.CodeCoverage.OutputPath = './tests/Coverage.xml'
}

# Run tests
$TestResults = Invoke-Pester -Configuration $PesterConfiguration

# Report results
Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

$TotalTests = $TestResults.TotalCount
$PassedTests = $TestResults.PassedCount
$FailedTests = $TestResults.FailedCount
$SkippedTests = $TestResults.SkippedCount

Write-Host "Total Tests: $TotalTests"
Write-Host "Passed: $PassedTests" -ForegroundColor Green
Write-Host "Failed: $FailedTests" -ForegroundColor $(if ($FailedTests -gt 0) { "Red" } else { "Green" })
Write-Host "Skipped: $SkippedTests" -ForegroundColor Yellow

$SuccessRate = if ($TotalTests -gt 0) { [Math]::Round(($PassedTests * 100.0) / $TotalTests, 1) } else { 0 }
Write-Host "Success Rate: $SuccessRate%" -ForegroundColor $(if ($SuccessRate -ge 90) { "Green" } elseif ($SuccessRate -ge 70) { "Yellow" } else { "Red" })

if ($FailedTests -gt 0) {
    Write-Host ""
    Write-Host "Failed Tests:" -ForegroundColor Red
    foreach ($test in $TestResults.Tests | Where-Object { $_.Result -eq 'Failed' }) {
        Write-Host "  ✗ $($test.Name)" -ForegroundColor Red
        if ($test.ErrorRecord) {
            Write-Host "    Error: $($test.ErrorRecord)" -ForegroundColor Gray
        }
    }
}

if ($Coverage -and $TestResults.CodeCoverage) {
    Write-Host ""
    Write-Host "Code Coverage:" -ForegroundColor Yellow
    $CoveragePercent = [Math]::Round($TestResults.CodeCoverage.CoveragePercent, 1)
    Write-Host "Coverage: $CoveragePercent%" -ForegroundColor $(if ($CoveragePercent -ge 80) { "Green" } elseif ($CoveragePercent -ge 60) { "Yellow" } else { "Red" })
}

Write-Host ""
if ($FailedTests -eq 0) {
    Write-Host "🎉 ALL TESTS PASSED - Safe to proceed with integration!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some tests failed - Review before proceeding with integration" -ForegroundColor Yellow
}

# Return exit code for CI/CD
exit $FailedTests