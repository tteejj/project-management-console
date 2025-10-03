#!/usr/bin/env pwsh

# Test script to verify Ctrl+key combinations work in PowerShell
Write-Host "Testing Ctrl+key detection in PowerShell..." -ForegroundColor Green
Write-Host "Press various keys to test. Press Ctrl+Q to exit." -ForegroundColor Yellow
Write-Host ""

while ($true) {
    try {
        $key = [Console]::ReadKey($true)

        $modifiers = @()
        if ($key.Modifiers -band [System.ConsoleModifiers]::Control) { $modifiers += "Ctrl" }
        if ($key.Modifiers -band [System.ConsoleModifiers]::Alt) { $modifiers += "Alt" }
        if ($key.Modifiers -band [System.ConsoleModifiers]::Shift) { $modifiers += "Shift" }

        $modifierText = if ($modifiers.Count -gt 0) { ($modifiers -join "+") + "+" } else { "" }

        Write-Host "Key: $modifierText$($key.Key) | KeyChar: '$($key.KeyChar)' | Modifiers: $($key.Modifiers)"

        # Test specific Ctrl combinations
        if ($key.Modifiers -band [System.ConsoleModifiers]::Control) {
            switch ($key.Key) {
                'T' { Write-Host "  -> Detected Ctrl+T!" -ForegroundColor Green }
                'P' { Write-Host "  -> Detected Ctrl+P!" -ForegroundColor Green }
                'O' { Write-Host "  -> Detected Ctrl+O!" -ForegroundColor Green }
                'Q' {
                    Write-Host "  -> Detected Ctrl+Q! Exiting..." -ForegroundColor Green
                    return
                }
                'H' { Write-Host "  -> Detected Ctrl+H!" -ForegroundColor Green }
                'N' { Write-Host "  -> Detected Ctrl+N!" -ForegroundColor Green }
                'R' { Write-Host "  -> Detected Ctrl+R!" -ForegroundColor Green }
            }
        }

        if ($key.Key -eq 'Escape') {
            Write-Host "Escape pressed - exiting test"
            break
        }

    } catch {
        Write-Host "Error reading key: $($_.Exception.Message)" -ForegroundColor Red
        break
    }
}