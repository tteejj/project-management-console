# TestNavigationManager.ps1 - Comprehensive tests for NavigationManager
#
# Tests navigation functionality:
# - NavigateTo with history
# - GoBack navigation
# - Replace without history
# - History management
# - State preservation
# - Error handling
#
# Usage:
#   . "$PSScriptRoot/../infrastructure/ScreenRegistry.ps1"
#   . "$PSScriptRoot/../infrastructure/NavigationManager.ps1"
#   . "$PSScriptRoot/TestNavigationManager.ps1"
#   Test-NavigationManager

# Load dependencies
$infraPath = Join-Path (Split-Path -Parent $PSScriptRoot) "infrastructure"
. (Join-Path $infraPath "ScreenRegistry.ps1")
. (Join-Path $infraPath "NavigationManager.ps1")

# Mock application class
class MockApplication {
    [object]$CurrentScreen = $null

    [void] SetScreen([object]$screen) {
        $this.CurrentScreen = $screen
    }
}

# Mock screen classes
class MockScreenA {
    [string]$Name = "MockScreenA"
    [hashtable]$State = @{}

    MockScreenA() {}

    [hashtable] SaveState() {
        return $this.State
    }

    [void] RestoreState([hashtable]$state) {
        $this.State = $state
    }
}

class MockScreenB {
    [string]$Name = "MockScreenB"
    MockScreenB() {}
}

class MockScreenC {
    [string]$Name = "MockScreenC"
    MockScreenC() {}
}

<#
.SYNOPSIS
Run all navigation manager tests

.DESCRIPTION
Executes comprehensive test suite for NavigationManager

.OUTPUTS
Test results summary
#>
function Test-NavigationManager {
    Write-Host "=== NavigationManager Test Suite ===" -ForegroundColor Cyan
    Write-Host ""

    $totalTests = 0
    $passedTests = 0
    $failedTests = 0

    # Setup
    [ScreenRegistry]::ResetInstance()
    [ScreenRegistry]::Register('ScreenA', [MockScreenA], 'Tasks', 'Test screen A')
    [ScreenRegistry]::Register('ScreenB', [MockScreenB], 'Tasks', 'Test screen B')
    [ScreenRegistry]::Register('ScreenC', [MockScreenC], 'Tasks', 'Test screen C')

    $app = [MockApplication]::new()
    $nav = [NavigationManager]::new($app)

    # Test: Initial state
    Write-Host "Testing Initial State..." -ForegroundColor Yellow

    $totalTests++
    if ($nav.CurrentScreen -eq "" -and $nav.GetDepth() -eq 0) {
        $passedTests++
        Write-Host "  [PASS] Initial state correct" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Initial state incorrect" -ForegroundColor Red
    }

    $totalTests++
    if (-not $nav.CanGoBack) {
        $passedTests++
        Write-Host "  [PASS] Cannot go back initially" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Can go back initially (should not)" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Navigate to first screen
    Write-Host "Testing First Navigation..." -ForegroundColor Yellow

    $result = $nav.NavigateTo('ScreenA')
    $totalTests++
    if ($result -and $nav.CurrentScreen -eq 'ScreenA') {
        $passedTests++
        Write-Host "  [PASS] Navigate to first screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Navigate to first screen: $($nav.LastError)" -ForegroundColor Red
    }

    $totalTests++
    if ($nav.GetDepth() -eq 0) {
        $passedTests++
        Write-Host "  [PASS] First navigation does not add to history" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] First navigation added to history (depth: $($nav.GetDepth()))" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Navigate to second screen
    Write-Host "Testing Second Navigation..." -ForegroundColor Yellow

    $result = $nav.NavigateTo('ScreenB')
    $totalTests++
    if ($result -and $nav.CurrentScreen -eq 'ScreenB') {
        $passedTests++
        Write-Host "  [PASS] Navigate to second screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Navigate to second screen: $($nav.LastError)" -ForegroundColor Red
    }

    $totalTests++
    if ($nav.GetDepth() -eq 1 -and $nav.CanGoBack) {
        $passedTests++
        Write-Host "  [PASS] Second navigation adds to history" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] History depth incorrect (depth: $($nav.GetDepth()))" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Navigate to third screen
    Write-Host "Testing Third Navigation..." -ForegroundColor Yellow

    $result = $nav.NavigateTo('ScreenC')
    $totalTests++
    if ($result -and $nav.CurrentScreen -eq 'ScreenC') {
        $passedTests++
        Write-Host "  [PASS] Navigate to third screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Navigate to third screen: $($nav.LastError)" -ForegroundColor Red
    }

    $totalTests++
    if ($nav.GetDepth() -eq 2) {
        $passedTests++
        Write-Host "  [PASS] Third navigation adds to history" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] History depth incorrect (depth: $($nav.GetDepth()))" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Go back
    Write-Host "Testing Back Navigation..." -ForegroundColor Yellow

    $result = $nav.GoBack()
    $totalTests++
    if ($result -and $nav.CurrentScreen -eq 'ScreenB') {
        $passedTests++
        Write-Host "  [PASS] Go back to previous screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Go back failed: $($nav.LastError)" -ForegroundColor Red
    }

    $totalTests++
    if ($nav.GetDepth() -eq 1) {
        $passedTests++
        Write-Host "  [PASS] Back navigation decrements history" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] History depth incorrect after back (depth: $($nav.GetDepth()))" -ForegroundColor Red
    }

    # Go back again
    $result = $nav.GoBack()
    $totalTests++
    if ($result -and $nav.CurrentScreen -eq 'ScreenA') {
        $passedTests++
        Write-Host "  [PASS] Go back to first screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Second back navigation failed: $($nav.LastError)" -ForegroundColor Red
    }

    $totalTests++
    if ($nav.GetDepth() -eq 0 -and -not $nav.CanGoBack) {
        $passedTests++
        Write-Host "  [PASS] Cannot go back when at first screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] CanGoBack state incorrect" -ForegroundColor Red
    }

    # Try to go back when no history
    $result = $nav.GoBack()
    $totalTests++
    if (-not $result) {
        $passedTests++
        Write-Host "  [PASS] Go back fails when no history" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Go back succeeded when no history" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Replace (no history)
    Write-Host "Testing Replace Navigation..." -ForegroundColor Yellow

    # Navigate to ScreenB, then replace with ScreenC
    $nav.NavigateTo('ScreenB')
    $depthBefore = $nav.GetDepth()
    $result = $nav.Replace('ScreenC')

    $totalTests++
    if ($result -and $nav.CurrentScreen -eq 'ScreenC') {
        $passedTests++
        Write-Host "  [PASS] Replace current screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Replace failed: $($nav.LastError)" -ForegroundColor Red
    }

    $totalTests++
    if ($nav.GetDepth() -eq $depthBefore) {
        $passedTests++
        Write-Host "  [PASS] Replace does not change history" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Replace changed history (before: $depthBefore, after: $($nav.GetDepth()))" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Clear history
    Write-Host "Testing Clear History..." -ForegroundColor Yellow

    $nav.NavigateTo('ScreenA')
    $nav.NavigateTo('ScreenB')
    $nav.ClearHistory()

    $totalTests++
    if ($nav.GetDepth() -eq 0 -and -not $nav.CanGoBack) {
        $passedTests++
        Write-Host "  [PASS] Clear history works" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Clear history failed (depth: $($nav.GetDepth()))" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Navigate to non-existent screen
    Write-Host "Testing Error Handling..." -ForegroundColor Yellow

    $result = $nav.NavigateTo('NonExistent')
    $totalTests++
    if (-not $result) {
        $passedTests++
        Write-Host "  [PASS] Navigate to non-existent screen fails" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Navigate to non-existent screen succeeded" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Statistics
    Write-Host "Testing Statistics..." -ForegroundColor Yellow

    $stats = $nav.GetStatistics()
    $totalTests++
    if ($null -ne $stats -and $stats.ContainsKey('currentScreen')) {
        $passedTests++
        Write-Host "  [PASS] GetStatistics returns valid data" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] GetStatistics returned invalid data" -ForegroundColor Red
    }

    Write-Host ""

    # Summary
    Write-Host "=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "Total Tests:  $totalTests" -ForegroundColor White
    Write-Host "Passed:       $passedTests" -ForegroundColor Green
    Write-Host "Failed:       $failedTests" -ForegroundColor Red
    Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor $(if ($failedTests -eq 0) { 'Green' } else { 'Yellow' })
    Write-Host ""

    # Cleanup
    [ScreenRegistry]::ResetInstance()

    return @{
        Total = $totalTests
        Passed = $passedTests
        Failed = $failedTests
        SuccessRate = ($passedTests / $totalTests) * 100
    }
}

# Run tests if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Test-NavigationManager
}
