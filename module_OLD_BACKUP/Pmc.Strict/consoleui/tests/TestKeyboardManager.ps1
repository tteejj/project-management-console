# TestKeyboardManager.ps1 - Comprehensive tests for KeyboardManager
#
# Tests keyboard shortcut functionality:
# - Global shortcut registration
# - Screen-specific shortcut registration
# - Key handling and execution
# - Priority system (global vs screen)
# - Conflict detection
# - Help generation
#
# Usage:
#   . "$PSScriptRoot/../infrastructure/KeyboardManager.ps1"
#   . "$PSScriptRoot/TestKeyboardManager.ps1"
#   Test-KeyboardManager

Set-StrictMode -Version Latest

# Load KeyboardManager
$infraPath = Join-Path (Split-Path -Parent $PSScriptRoot) "infrastructure"
. (Join-Path $infraPath "KeyboardManager.ps1")

<#
.SYNOPSIS
Run all keyboard manager tests

.DESCRIPTION
Executes comprehensive test suite for KeyboardManager

.OUTPUTS
Test results summary
#>
function Test-KeyboardManager {
    Write-Host "=== KeyboardManager Test Suite ===" -ForegroundColor Cyan
    Write-Host ""

    $totalTests = 0
    $passedTests = 0
    $failedTests = 0

    $km = [KeyboardManager]::new()

    # Test: Register global shortcuts
    Write-Host "Testing Global Shortcut Registration..." -ForegroundColor Yellow

    # Register valid global shortcut
    $script:globalActionCalled = $false
    $result = $km.RegisterGlobal([ConsoleKey]::Q, [ConsoleModifiers]::Control, { $script:globalActionCalled = $true }, "Quit")
    $totalTests++
    if ($result) {
        $passedTests++
        Write-Host "  [PASS] Register global shortcut" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Register global shortcut: $($km.LastError)" -ForegroundColor Red
    }

    # Register duplicate (should fail)
    $result = $km.RegisterGlobal([ConsoleKey]::Q, [ConsoleModifiers]::Control, { Write-Host "Duplicate" }, "Duplicate")
    $totalTests++
    if (-not $result) {
        $passedTests++
        Write-Host "  [PASS] Reject duplicate global shortcut" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Allowed duplicate global shortcut" -ForegroundColor Red
    }

    # Register another global shortcut
    $result = $km.RegisterGlobal([ConsoleKey]::H, [ConsoleModifiers]::Control, { Write-Host "Help" }, "Help")
    $totalTests++
    if ($result) {
        $passedTests++
        Write-Host "  [PASS] Register second global shortcut" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Register second global shortcut" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Register screen-specific shortcuts
    Write-Host "Testing Screen-Specific Shortcut Registration..." -ForegroundColor Yellow

    # Register valid screen shortcut
    $script:screenActionCalled = $false
    $result = $km.RegisterScreen('TaskList', [ConsoleKey]::E, [ConsoleModifiers]::None, { $script:screenActionCalled = $true }, "Edit")
    $totalTests++
    if ($result) {
        $passedTests++
        Write-Host "  [PASS] Register screen shortcut" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Register screen shortcut: $($km.LastError)" -ForegroundColor Red
    }

    # Register duplicate screen shortcut (should fail)
    $result = $km.RegisterScreen('TaskList', [ConsoleKey]::E, [ConsoleModifiers]::None, { Write-Host "Duplicate" }, "Duplicate")
    $totalTests++
    if (-not $result) {
        $passedTests++
        Write-Host "  [PASS] Reject duplicate screen shortcut" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Allowed duplicate screen shortcut" -ForegroundColor Red
    }

    # Register another screen shortcut
    $result = $km.RegisterScreen('TaskList', [ConsoleKey]::D, [ConsoleModifiers]::None, { Write-Host "Delete" }, "Delete")
    $totalTests++
    if ($result) {
        $passedTests++
        Write-Host "  [PASS] Register second screen shortcut" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Register second screen shortcut" -ForegroundColor Red
    }

    # Register shortcut for different screen (same key, different screen)
    $result = $km.RegisterScreen('ProjectList', [ConsoleKey]::E, [ConsoleModifiers]::None, { Write-Host "Edit Project" }, "Edit Project")
    $totalTests++
    if ($result) {
        $passedTests++
        Write-Host "  [PASS] Register same key for different screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Register same key for different screen" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Key handling (simulated)
    Write-Host "Testing Key Handling..." -ForegroundColor Yellow

    # Create mock ConsoleKeyInfo objects
    $ctrlQ = New-Object System.ConsoleKeyInfo([char]'q', [ConsoleKey]::Q, $false, $false, $true)
    $keyE = New-Object System.ConsoleKeyInfo([char]'e', [ConsoleKey]::E, $false, $false, $false)
    $keyD = New-Object System.ConsoleKeyInfo([char]'d', [ConsoleKey]::D, $false, $false, $false)
    $keyX = New-Object System.ConsoleKeyInfo([char]'x', [ConsoleKey]::X, $false, $false, $false)

    # Test global shortcut execution
    $script:globalActionCalled = $false
    $handled = $km.HandleKey($ctrlQ, 'TaskList')
    $totalTests++
    if ($handled -and $script:globalActionCalled) {
        $passedTests++
        Write-Host "  [PASS] Global shortcut executed" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Global shortcut not executed (handled: $handled, called: $script:globalActionCalled)" -ForegroundColor Red
    }

    # Test screen-specific shortcut execution
    $script:screenActionCalled = $false
    $handled = $km.HandleKey($keyE, 'TaskList')
    $totalTests++
    if ($handled -and $script:screenActionCalled) {
        $passedTests++
        Write-Host "  [PASS] Screen shortcut executed" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Screen shortcut not executed (handled: $handled, called: $script:screenActionCalled)" -ForegroundColor Red
    }

    # Test unhandled key
    $handled = $km.HandleKey($keyX, 'TaskList')
    $totalTests++
    if (-not $handled) {
        $passedTests++
        Write-Host "  [PASS] Unhandled key returns false" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Unhandled key returned true" -ForegroundColor Red
    }

    # Test screen-specific shortcut not executed on different screen
    $handled = $km.HandleKey($keyE, 'DifferentScreen')
    $totalTests++
    if (-not $handled) {
        $passedTests++
        Write-Host "  [PASS] Screen shortcut not executed on different screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Screen shortcut executed on wrong screen" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Query methods
    Write-Host "Testing Query Methods..." -ForegroundColor Yellow

    # GetGlobalShortcuts
    $globalShortcuts = $km.GetGlobalShortcuts()
    $totalTests++
    if ($globalShortcuts.Count -eq 2) {
        $passedTests++
        Write-Host "  [PASS] GetGlobalShortcuts returns correct count" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] GetGlobalShortcuts returned $($globalShortcuts.Count), expected 2" -ForegroundColor Red
    }

    # GetScreenShortcuts
    $taskListShortcuts = $km.GetScreenShortcuts('TaskList')
    $totalTests++
    if ($taskListShortcuts.Count -eq 2) {
        $passedTests++
        Write-Host "  [PASS] GetScreenShortcuts returns correct count" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] GetScreenShortcuts returned $($taskListShortcuts.Count), expected 2" -ForegroundColor Red
    }

    # GetAllShortcuts
    $allShortcuts = $km.GetAllShortcuts()
    $totalTests++
    if ($allShortcuts.Count -eq 5) {  # 2 global + 2 TaskList + 1 ProjectList
        $passedTests++
        Write-Host "  [PASS] GetAllShortcuts returns correct count" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] GetAllShortcuts returned $($allShortcuts.Count), expected 5" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Unregistration
    Write-Host "Testing Shortcut Unregistration..." -ForegroundColor Yellow

    # Unregister global shortcut
    $result = $km.UnregisterGlobal([ConsoleKey]::H, [ConsoleModifiers]::Control)
    $totalTests++
    if ($result) {
        $passedTests++
        Write-Host "  [PASS] Unregister global shortcut" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Unregister global shortcut" -ForegroundColor Red
    }

    # Unregister non-existent global shortcut
    $result = $km.UnregisterGlobal([ConsoleKey]::Z, [ConsoleModifiers]::Control)
    $totalTests++
    if (-not $result) {
        $passedTests++
        Write-Host "  [PASS] Reject unregistering non-existent global shortcut" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Allowed unregistering non-existent global shortcut" -ForegroundColor Red
    }

    # Unregister screen shortcut
    $result = $km.UnregisterScreen('TaskList', [ConsoleKey]::D, [ConsoleModifiers]::None)
    $totalTests++
    if ($result) {
        $passedTests++
        Write-Host "  [PASS] Unregister screen shortcut" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Unregister screen shortcut" -ForegroundColor Red
    }

    # Unregister non-existent screen shortcut
    $result = $km.UnregisterScreen('TaskList', [ConsoleKey]::Z, [ConsoleModifiers]::None)
    $totalTests++
    if (-not $result) {
        $passedTests++
        Write-Host "  [PASS] Reject unregistering non-existent screen shortcut" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Allowed unregistering non-existent screen shortcut" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Help generation
    Write-Host "Testing Help Generation..." -ForegroundColor Yellow

    $helpText = $km.GetHelpText('TaskList')
    $totalTests++
    if ($helpText.Contains('Keyboard Shortcuts') -and $helpText.Contains('Ctrl+Q')) {
        $passedTests++
        Write-Host "  [PASS] GetHelpText generates valid help" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] GetHelpText generated invalid help" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Statistics
    Write-Host "Testing Statistics..." -ForegroundColor Yellow

    $stats = $km.GetStatistics()
    $totalTests++
    if ($null -ne $stats -and $stats.ContainsKey('globalShortcuts')) {
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

    return @{
        Total = $totalTests
        Passed = $passedTests
        Failed = $failedTests
        SuccessRate = ($passedTests / $totalTests) * 100
    }
}

# Run tests if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Test-KeyboardManager
}
