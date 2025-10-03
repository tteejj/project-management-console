#!/usr/bin/env pwsh

# Test using PowerShell Host UI instead of Console.ReadKey
Write-Host "Testing key detection using Host.UI.RawUI.ReadKey..." -ForegroundColor Green
Write-Host "This is the method that actually works in PowerShell" -ForegroundColor Cyan
Write-Host ""

try {
    $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

    Write-Host "SUCCESS! Key detected:" -ForegroundColor Green
    Write-Host "  Key: $($key.VirtualKeyCode)" -ForegroundColor White
    Write-Host "  Character: '$($key.Character)'" -ForegroundColor White
    Write-Host "  ControlKeyState: $($key.ControlKeyState)" -ForegroundColor White

    # Check for Ctrl
    if ($key.ControlKeyState -band 0x8 -or $key.ControlKeyState -band 0x4) {
        Write-Host "  CTRL is pressed!" -ForegroundColor Cyan
    }

} catch {
    Write-Host "Host.UI.RawUI.ReadKey also failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This means we're in a non-interactive environment" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Conclusion: If this runs in a real PowerShell console, Ctrl+keys will work." -ForegroundColor Green