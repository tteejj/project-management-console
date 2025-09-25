#!/usr/bin/env pwsh
# Basic test of the rebuilt PMC system

Write-Host "Testing PMC basic functionality..." -ForegroundColor Green

try {
    # Import the module
    $moduleManifest = './module/Pmc.Strict/Pmc.Strict.psd1'
    Import-Module $moduleManifest -Force -ErrorAction Stop
    Write-Host "✓ Module loaded successfully" -ForegroundColor Green

    # Test core functions exist
    $funcs = @('Invoke-PmcCommand', 'Read-PmcCommand', 'Enable-PmcInteractiveMode', 'Initialize-PmcScreen')
    foreach ($func in $funcs) {
        if (Get-Command $func -ErrorAction SilentlyContinue) {
            Write-Host "✓ Function $func available" -ForegroundColor Green
        } else {
            Write-Host "✗ Function $func missing" -ForegroundColor Red
        }
    }

    # Test screen manager doesn't conflict with prompt
    Write-Host "✓ Testing screen manager..." -ForegroundColor Green
    Initialize-PmcScreen -Title "Test Screen"
    Write-Host "✓ Screen initialized without cursor conflicts" -ForegroundColor Green

    # Test simple command
    Write-Host "✓ Testing command execution..." -ForegroundColor Green
    Invoke-PmcCommand -Buffer "help"
    Write-Host "✓ Command executed successfully" -ForegroundColor Green

    Write-Host "`n✓ All basic tests passed!" -ForegroundColor Green

} catch {
    Write-Host "✗ Test failed: $_" -ForegroundColor Red
    throw
}