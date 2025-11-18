# TestApplicationBootstrapper.ps1 - Tests for ApplicationBootstrapper
#
# Tests application bootstrap functionality:
# - Dependency loading order
# - Service initialization
# - Screen registration
# - Configuration
# - Error handling
#
# Usage:
#   . "$PSScriptRoot/TestApplicationBootstrapper.ps1"
#   Test-ApplicationBootstrapper

Set-StrictMode -Version Latest

<#
.SYNOPSIS
Run application bootstrapper tests

.DESCRIPTION
Executes test suite for ApplicationBootstrapper.
NOTE: These are basic tests - full bootstrap testing requires complete environment.

.OUTPUTS
Test results summary
#>
function Test-ApplicationBootstrapper {
    Write-Host "=== ApplicationBootstrapper Test Suite ===" -ForegroundColor Cyan
    Write-Host ""

    $totalTests = 0
    $passedTests = 0
    $failedTests = 0

    # Test: BootstrapConfig class
    Write-Host "Testing BootstrapConfig Class..." -ForegroundColor Yellow

    # Create default config
    $config = [BootstrapConfig]::new()
    $totalTests++
    if ($null -ne $config -and $config.StartScreen -eq 'TaskList') {
        $passedTests++
        Write-Host "  [PASS] Create default BootstrapConfig" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Default BootstrapConfig incorrect" -ForegroundColor Red
    }

    # Create config with custom start screen
    $config = [BootstrapConfig]::new('Dashboard')
    $totalTests++
    if ($config.StartScreen -eq 'Dashboard') {
        $passedTests++
        Write-Host "  [PASS] Create BootstrapConfig with custom start screen" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Custom start screen not set" -ForegroundColor Red
    }

    # Test config properties
    $config.LoadSampleData = $true
    $config.EnableDebugLogging = $true
    $config.ThemeName = 'dark'
    $totalTests++
    if ($config.LoadSampleData -and $config.EnableDebugLogging -and $config.ThemeName -eq 'dark') {
        $passedTests++
        Write-Host "  [PASS] BootstrapConfig properties work correctly" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] BootstrapConfig properties incorrect" -ForegroundColor Red
    }

    Write-Host ""

    # Test: Get-BootstrapDiagnostics (if available)
    Write-Host "Testing Get-BootstrapDiagnostics..." -ForegroundColor Yellow

    if (Get-Command Get-BootstrapDiagnostics -ErrorAction SilentlyContinue) {
        try {
            $diag = Get-BootstrapDiagnostics
            $totalTests++
            if ($null -ne $diag -and $diag.ContainsKey('timestamp')) {
                $passedTests++
                Write-Host "  [PASS] Get-BootstrapDiagnostics returns valid data" -ForegroundColor Green
            } else {
                $failedTests++
                Write-Host "  [FAIL] Get-BootstrapDiagnostics returned invalid data" -ForegroundColor Red
            }
        } catch {
            $totalTests++
            $failedTests++
            Write-Host "  [FAIL] Get-BootstrapDiagnostics threw exception: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  [SKIP] Get-BootstrapDiagnostics not loaded" -ForegroundColor Yellow
    }

    Write-Host ""

    # Test: Path validation
    Write-Host "Testing Path Validation..." -ForegroundColor Yellow

    $basePath = Split-Path -Parent $PSScriptRoot
    $totalTests++
    if (Test-Path $basePath) {
        $passedTests++
        Write-Host "  [PASS] Base path exists: $basePath" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Base path does not exist: $basePath" -ForegroundColor Red
    }

    # Check for key directories
    $directories = @('helpers', 'infrastructure', 'base', 'services', 'widgets')
    foreach ($dir in $directories) {
        $dirPath = Join-Path $basePath $dir
        $totalTests++
        if (Test-Path $dirPath) {
            $passedTests++
            Write-Host "  [PASS] Directory exists: $dir" -ForegroundColor Green
        } else {
            $failedTests++
            Write-Host "  [FAIL] Directory missing: $dir" -ForegroundColor Red
        }
    }

    Write-Host ""

    # Test: Key file existence
    Write-Host "Testing Key Files..." -ForegroundColor Yellow

    $keyFiles = @(
        'helpers/ValidationHelper.ps1',
        'helpers/DataBindingHelper.ps1',
        'infrastructure/ScreenRegistry.ps1',
        'infrastructure/NavigationManager.ps1',
        'infrastructure/KeyboardManager.ps1',
        'infrastructure/ApplicationBootstrapper.ps1',
        'services/TaskStore.ps1',
        'base/StandardListScreen.ps1',
        'base/StandardFormScreen.ps1',
        'base/StandardDashboard.ps1'
    )

    foreach ($file in $keyFiles) {
        $filePath = Join-Path $basePath $file
        $totalTests++
        if (Test-Path $filePath) {
            $passedTests++
            Write-Host "  [PASS] File exists: $file" -ForegroundColor Green
        } else {
            $failedTests++
            Write-Host "  [FAIL] File missing: $file" -ForegroundColor Red
        }
    }

    Write-Host ""

    # Test: Loading order (verify files can be loaded without errors)
    Write-Host "Testing File Loading..." -ForegroundColor Yellow

    $loadableFiles = @(
        'helpers/ValidationHelper.ps1',
        'infrastructure/ScreenRegistry.ps1'
    )

    foreach ($file in $loadableFiles) {
        $filePath = Join-Path $basePath $file
        if (Test-Path $filePath) {
            try {
                . $filePath
                $totalTests++
                $passedTests++
                Write-Host "  [PASS] Loaded: $file" -ForegroundColor Green
            } catch {
                $totalTests++
                $failedTests++
                Write-Host "  [FAIL] Load error in $file`: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    Write-Host ""

    # Summary
    Write-Host "=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "Total Tests:  $totalTests" -ForegroundColor White
    Write-Host "Passed:       $passedTests" -ForegroundColor Green
    Write-Host "Failed:       $failedTests" -ForegroundColor Red
    Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor $(if ($failedTests -eq 0) { 'Green' } else { 'Yellow' })
    Write-Host ""

    Write-Host "NOTE: Full bootstrap testing requires running Start-PmcApplication" -ForegroundColor Cyan
    Write-Host ""

    return @{
        Total = $totalTests
        Passed = $passedTests
        Failed = $failedTests
        SuccessRate = if ($totalTests -gt 0) { ($passedTests / $totalTests) * 100 } else { 0 }
    }
}

# Run tests if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Test-ApplicationBootstrapper
}
