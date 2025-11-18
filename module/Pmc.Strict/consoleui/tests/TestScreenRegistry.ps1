# TestScreenRegistry.ps1 - Comprehensive tests for ScreenRegistry
#
# Tests screen registry functionality:
# - Screen registration and unregistration
# - Screen creation
# - Category management
# - Query methods
# - Singleton pattern
# - Error handling
#
# Usage:
#   . "$PSScriptRoot/../infrastructure/ScreenRegistry.ps1"
#   . "$PSScriptRoot/TestScreenRegistry.ps1"
#   Test-ScreenRegistry

Set-StrictMode -Version Latest

# Load ScreenRegistry
$infraPath = Join-Path (Split-Path -Parent $PSScriptRoot) "infrastructure"
. (Join-Path $infraPath "ScreenRegistry.ps1")

# Mock screen classes for testing
class TestScreenA {
    [string]$Name = "TestScreenA"
    TestScreenA() {}
}

class TestScreenB {
    [string]$Name = "TestScreenB"
    TestScreenB() {}
}

class TestScreenC {
    [string]$Name = "TestScreenC"
    [string]$Param
    TestScreenC([string]$param) {
        $this.Param = $param
    }
}

<#
.SYNOPSIS
Run all screen registry tests

.DESCRIPTION
Executes comprehensive test suite for ScreenRegistry

.OUTPUTS
Test results summary
#>
function Test-ScreenRegistry {
    Write-Host "=== ScreenRegistry Test Suite ===" -ForegroundColor Cyan
    Write-Host ""

    $totalTests = 0
    $passedTests = 0
    $failedTests = 0

    # Reset singleton before tests
    [ScreenRegistry]::ResetInstance()

    # Test: Singleton pattern
    Write-Host "Testing Singleton Pattern..." -ForegroundColor Yellow

    $instance1 = [ScreenRegistry]::GetInstance()
    $instance2 = [ScreenRegistry]::GetInstance()
    $totalTests++
    if ($instance1 -eq $instance2) {
        $passedTests++
        Write-Host "  [PASS] Singleton returns same instance" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Singleton returns different instances" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Screen registration
    Write-Host "Testing Screen Registration..." -ForegroundColor Yellow

    # Register valid screen
    $result = [ScreenRegistry]::Register('TestA', [TestScreenA], 'Tasks', 'Test screen A')
    $totalTests++
    if ($result) {
        $passedTests++
        Write-Host "  [PASS] Register valid screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Register valid screen: $([ScreenRegistry]::GetInstance().LastError)" -ForegroundColor Red
    }

    # Register duplicate (should fail)
    $result = [ScreenRegistry]::Register('TestA', [TestScreenA], 'Tasks', 'Duplicate')
    $totalTests++
    if (-not $result) {
        $passedTests++
        Write-Host "  [PASS] Reject duplicate screen name" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Allowed duplicate screen name" -ForegroundColor Red
    }

    # Register with invalid category
    $result = [ScreenRegistry]::Register('TestInvalid', [TestScreenA], 'InvalidCategory', 'Test')
    $totalTests++
    if (-not $result) {
        $passedTests++
        Write-Host "  [PASS] Reject invalid category" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Allowed invalid category" -ForegroundColor Red
    }

    # Register another screen
    $result = [ScreenRegistry]::Register('TestB', [TestScreenB], 'Projects', 'Test screen B')
    $totalTests++
    if ($result) {
        $passedTests++
        Write-Host "  [PASS] Register second screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Register second screen" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Screen creation
    Write-Host "Testing Screen Creation..." -ForegroundColor Yellow

    # Create registered screen
    $screen = [ScreenRegistry]::Create('TestA')
    $totalTests++
    if ($null -ne $screen -and $screen -is [TestScreenA]) {
        $passedTests++
        Write-Host "  [PASS] Create registered screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Create registered screen" -ForegroundColor Red
    }

    # Create unregistered screen
    $screen = [ScreenRegistry]::Create('NonExistent')
    $totalTests++
    if ($null -eq $screen) {
        $passedTests++
        Write-Host "  [PASS] Return null for unregistered screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Created unregistered screen" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Query methods
    Write-Host "Testing Query Methods..." -ForegroundColor Yellow

    # IsRegistered
    $totalTests++
    if ([ScreenRegistry]::IsRegistered('TestA')) {
        $passedTests++
        Write-Host "  [PASS] IsRegistered returns true for registered screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] IsRegistered returns false for registered screen" -ForegroundColor Red
    }

    $totalTests++
    if (-not [ScreenRegistry]::IsRegistered('NonExistent')) {
        $passedTests++
        Write-Host "  [PASS] IsRegistered returns false for unregistered screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] IsRegistered returns true for unregistered screen" -ForegroundColor Red
    }

    # GetAllScreens
    $allScreens = [ScreenRegistry]::GetAllScreens()
    $totalTests++
    if ($allScreens.Count -eq 2) {
        $passedTests++
        Write-Host "  [PASS] GetAllScreens returns correct count" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] GetAllScreens returns $($allScreens.Count), expected 2" -ForegroundColor Red
    }

    # GetByCategory
    $taskScreens = [ScreenRegistry]::GetByCategory('Tasks')
    $totalTests++
    if ($taskScreens.Count -eq 1 -and $taskScreens[0].Name -eq 'TestA') {
        $passedTests++
        Write-Host "  [PASS] GetByCategory returns correct screens" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] GetByCategory returned $($taskScreens.Count) screens" -ForegroundColor Red
    }

    # GetRegistration
    $registration = [ScreenRegistry]::GetRegistration('TestA')
    $totalTests++
    if ($null -ne $registration -and $registration.Name -eq 'TestA') {
        $passedTests++
        Write-Host "  [PASS] GetRegistration returns correct registration" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] GetRegistration failed" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Unregistration
    Write-Host "Testing Screen Unregistration..." -ForegroundColor Yellow

    # Unregister existing screen
    $result = [ScreenRegistry]::Unregister('TestB')
    $totalTests++
    if ($result -and -not [ScreenRegistry]::IsRegistered('TestB')) {
        $passedTests++
        Write-Host "  [PASS] Unregister existing screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Unregister existing screen" -ForegroundColor Red
    }

    # Unregister non-existent screen
    $result = [ScreenRegistry]::Unregister('NonExistent')
    $totalTests++
    if (-not $result) {
        $passedTests++
        Write-Host "  [PASS] Reject unregistering non-existent screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Allowed unregistering non-existent screen" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Category management
    Write-Host "Testing Category Management..." -ForegroundColor Yellow

    # Get categories
    $categories = [ScreenRegistry]::GetCategories()
    $totalTests++
    if ($categories.Count -ge 5) {  # Default categories
        $passedTests++
        Write-Host "  [PASS] GetCategories returns default categories" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] GetCategories returned $($categories.Count) categories" -ForegroundColor Red
    }

    # Add custom category
    $result = [ScreenRegistry]::AddCategory('CustomCategory')
    $totalTests++
    if ($result) {
        $passedTests++
        Write-Host "  [PASS] Add custom category" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Add custom category" -ForegroundColor Red
    }

    # Add duplicate category
    $result = [ScreenRegistry]::AddCategory('CustomCategory')
    $totalTests++
    if (-not $result) {
        $passedTests++
        Write-Host "  [PASS] Reject duplicate category" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Allowed duplicate category" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Statistics
    Write-Host "Testing Statistics..." -ForegroundColor Yellow

    $stats = [ScreenRegistry]::GetStatistics()
    $totalTests++
    if ($null -ne $stats -and $stats.ContainsKey('totalScreens')) {
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
    Test-ScreenRegistry
}
