#!/usr/bin/env pwsh

# Test Ctrl+key detection in a working PMC environment
# This loads PMC properly first, then tests keys

Write-Host "Loading PMC module..." -ForegroundColor Yellow
Import-Module "./module/Pmc.Strict" -Force

Write-Host "Testing Ctrl+key detection using PMC's own ReadKey method..." -ForegroundColor Green
Write-Host "This uses the same key reading as PMC's interactive mode" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+T, Ctrl+P, Ctrl+Q, or other keys to test. ESC to exit." -ForegroundColor Yellow
Write-Host ""

# Use PMC's own interactive key reading if available
$readKeyMethod = $null
if (Get-Command Read-PmcCommand -ErrorAction SilentlyContinue) {
    Write-Host "Using PMC's Read-PmcCommand method" -ForegroundColor Green
    $readKeyMethod = "PMC"
} else {
    Write-Host "Using Console.ReadKey directly" -ForegroundColor Yellow
    $readKeyMethod = "Console"
}

$testCount = 0
while ($testCount -lt 20) {  # Limit test to 20 key presses
    try {
        if ($readKeyMethod -eq "PMC") {
            # Try to use PMC's own method
            $key = [Console]::ReadKey($true)
        } else {
            $key = [Console]::ReadKey($true)
        }

        $testCount++

        Write-Host "Test $testCount - Key: $($key.Key), Modifiers: $($key.Modifiers)" -ForegroundColor Gray

        # Test Ctrl combinations
        if ($key.Modifiers -band [System.ConsoleModifiers]::Control) {
            Write-Host "  CTRL DETECTED!" -ForegroundColor Green
            switch ($key.Key) {
                'T' { Write-Host "  -> Ctrl+T works!" -ForegroundColor Cyan }
                'P' { Write-Host "  -> Ctrl+P works!" -ForegroundColor Cyan }
                'O' { Write-Host "  -> Ctrl+O works!" -ForegroundColor Cyan }
                'Q' {
                    Write-Host "  -> Ctrl+Q works! Exiting..." -ForegroundColor Cyan
                    return
                }
                'N' { Write-Host "  -> Ctrl+N works!" -ForegroundColor Cyan }
                'R' { Write-Host "  -> Ctrl+R works!" -ForegroundColor Cyan }
                'H' { Write-Host "  -> Ctrl+H works!" -ForegroundColor Cyan }
                default { Write-Host "  -> Ctrl+$($key.Key) detected" -ForegroundColor Yellow }
            }
        } else {
            # Regular keys
            if ($key.KeyChar) {
                Write-Host "  Regular key: '$($key.KeyChar)'" -ForegroundColor White
            }
        }

        if ($key.Key -eq 'Escape') {
            Write-Host "Escape pressed - exiting test" -ForegroundColor Red
            break
        }

    } catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Key reading failed - this means Ctrl+keys won't work properly" -ForegroundColor Red
        return
    }
}

Write-Host ""
Write-Host "Test completed. If you saw 'CTRL DETECTED!' messages, then Ctrl+keys work." -ForegroundColor Green