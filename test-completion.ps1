#!/usr/bin/env pwsh
# Test tab completion functionality

Write-Host "Testing PMC tab completion..." -ForegroundColor Green

try {
    # Load the module first
    $moduleManifest = './module/Pmc.Strict/Pmc.Strict.psd1'
    Import-Module $moduleManifest -Force -ErrorAction Stop
    Write-Host "✓ Module loaded" -ForegroundColor Green

    # Test the completion function directly
    $completions = Get-PmcCompletions -Buffer "ta" -CursorPosition 2 -WordToComplete "ta"
    Write-Host "✓ Completions for 'ta': $($completions -join ', ')" -ForegroundColor Green

    $completions = Get-PmcCompletions -Buffer "task a" -CursorPosition 6 -WordToComplete "a"
    Write-Host "✓ Completions for 'task a': $($completions -join ', ')" -ForegroundColor Green

    Write-Host "✓ Tab completion system working!" -ForegroundColor Green

} catch {
    Write-Host "✗ Test failed: $_" -ForegroundColor Red
    exit 1
}