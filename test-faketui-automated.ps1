#!/usr/bin/env pwsh
# Automated test for FakeTUI Draw methods (non-interactive portions)

Write-Host "=== FakeTUI Automated Tests ===" -ForegroundColor Cyan
Write-Host ""

# Load the FakeTUI system
. "$PSScriptRoot/module/Pmc.Strict/FakeTUI/FakeTUI.ps1"

$testResults = @()

function Test-DrawMethod {
    param(
        [string]$Name,
        [scriptblock]$TestCode
    )

    try {
        & $TestCode
        $testResults += @{ Name = $Name; Status = "PASS"; Error = $null }
        Write-Host "✓ $Name" -ForegroundColor Green
        return $true
    } catch {
        $testResults += @{ Name = $Name; Status = "FAIL"; Error = $_.Exception.Message }
        Write-Host "✗ $Name - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host "Testing Draw methods (checking they don't crash)..." -ForegroundColor Yellow
Write-Host ""

# Create app instance
$app = [PmcFakeTUIApp]::new()
$app.Initialize()

# Test each Draw method by calling it directly
# These should not crash even without interactive input

Test-DrawMethod "DrawDependencyGraph" {
    $app.DrawDependencyGraph()
}

Test-DrawMethod "DrawBurndownChart" {
    $app.DrawBurndownChart()
}

Test-DrawMethod "DrawStartReview" {
    $app.DrawStartReview()
}

Test-DrawMethod "DrawProjectWizard" {
    $app.DrawProjectWizard()
}

Test-DrawMethod "DrawTemplates" {
    $app.DrawTemplates()
}

Test-DrawMethod "DrawStatistics" {
    $app.DrawStatistics()
}

Test-DrawMethod "DrawVelocity" {
    $app.DrawVelocity()
}

Test-DrawMethod "DrawPreferences" {
    $app.DrawPreferences()
}

Test-DrawMethod "DrawConfigEditor" {
    $app.DrawConfigEditor()
}

Test-DrawMethod "DrawManageAliases" {
    $app.DrawManageAliases()
}

Test-DrawMethod "DrawQueryBrowser" {
    $app.DrawQueryBrowser()
}

Test-DrawMethod "DrawWeeklyReport" {
    $app.DrawWeeklyReport()
}

Test-DrawMethod "DrawHelpBrowser" {
    $app.DrawHelpBrowser()
}

Test-DrawMethod "DrawHelpCategories" {
    $app.DrawHelpCategories()
}

Test-DrawMethod "DrawHelpSearch" {
    $app.DrawHelpSearch()
}

Test-DrawMethod "DrawAboutPMC" {
    $app.DrawAboutPMC()
}

Test-DrawMethod "DrawEditProjectForm" {
    $app.DrawEditProjectForm()
}

Test-DrawMethod "DrawProjectInfoView" {
    $app.DrawProjectInfoView()
}

Test-DrawMethod "DrawRecentProjectsView" {
    $app.DrawRecentProjectsView()
}

# Cleanup
$app.Shutdown()

# Summary
Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
$passed = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $testResults.Count

Write-Host "Total: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Failed tests:" -ForegroundColor Red
    $testResults | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - $($_.Name): $($_.Error)" -ForegroundColor Red
    }
    exit 1
}

exit 0
