#!/usr/bin/env pwsh
# Test TUI behavior with proper screen clearing

Write-Host "Testing TUI behavior..." -ForegroundColor Green

try {
    # Load and test basic TUI operations
    $moduleManifest = './module/Pmc.Strict/Pmc.Strict.psd1'
    Import-Module $moduleManifest -Force -ErrorAction Stop

    # Test screen manager functions
    Write-Host "✓ Initializing screen..." -ForegroundColor Green
    Initialize-PmcScreen -Title "Test TUI"

    Write-Host "✓ Clearing content area..." -ForegroundColor Green
    Clear-PmcContentArea

    Write-Host "✓ Getting content bounds..." -ForegroundColor Green
    $bounds = Get-PmcContentBounds
    Write-Host "Content area: $($bounds.X),$($bounds.Y) $($bounds.Width)x$($bounds.Height)" -ForegroundColor Blue

    Write-Host "✓ Testing command execution..." -ForegroundColor Green
    Write-Host "Simulating: task list"
    Invoke-PmcCommand -Buffer "task list"

    Write-Host "`n✓ TUI functionality working!" -ForegroundColor Green

} catch {
    Write-Host "✗ TUI test failed: $_" -ForegroundColor Red
    exit 1
}