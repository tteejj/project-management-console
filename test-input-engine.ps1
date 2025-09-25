#!/usr/bin/env pwsh
# Test the new input engine

Write-Host "Testing input engine..." -ForegroundColor Green
Write-Host "Instructions:" -ForegroundColor Yellow
Write-Host "1. Type 'ta' and press Tab - should complete to 'task'" -ForegroundColor Gray
Write-Host "2. Press space, type 'l' and press Tab - should complete to 'list'" -ForegroundColor Gray
Write-Host "3. Press Enter to execute 'task list'" -ForegroundColor Gray
Write-Host "4. Type 'exit' to quit" -ForegroundColor Gray
Write-Host ""

try {
    # Load just the input engine
    $moduleManifest = './module/Pmc.Strict/Pmc.Strict.psd1'
    Import-Module $moduleManifest -Force -ErrorAction Stop

    # Test the input engine directly
    $attempts = 0
    while ($attempts -lt 5) {
        $command = Read-PmcCommand
        $attempts++
        if ($command -eq "exit") { break }
        if ([string]::IsNullOrWhiteSpace($command)) {
            Write-Host "Empty input received (attempt $attempts/5)" -ForegroundColor Yellow
            continue
        }
        Write-Host "You entered: '$command'" -ForegroundColor Green
        if ($command -eq "task list") {
            Write-Host "Tab completion working!" -ForegroundColor Green
        }
    }
    Write-Host "Test completed" -ForegroundColor Blue

} catch {
    Write-Host "Test failed: $_" -ForegroundColor Red
}