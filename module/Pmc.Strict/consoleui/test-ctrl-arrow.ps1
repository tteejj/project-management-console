# Test Ctrl+Arrow key detection
Write-Host "Press Ctrl+Arrow keys (or Ctrl+C to exit)" -ForegroundColor Green
Write-Host ""

while ($true) {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)

        $modStr = $key.Modifiers.ToString()
        $keyStr = $key.Key.ToString()
        $charStr = if ($key.KeyChar) { [int]$key.KeyChar } else { "null" }

        Write-Host "Key: $keyStr  |  Modifiers: $modStr  |  KeyChar: $charStr" -ForegroundColor Cyan

        # Check for Ctrl+Arrow specifically
        $ctrl = $key.Modifiers -band [ConsoleModifiers]::Control
        if ($ctrl) {
            if ($key.Key -eq [ConsoleKey]::UpArrow) {
                Write-Host "  >>> DETECTED: Ctrl+Up" -ForegroundColor Green
            }
            elseif ($key.Key -eq [ConsoleKey]::DownArrow) {
                Write-Host "  >>> DETECTED: Ctrl+Down" -ForegroundColor Green
            }
            elseif ($key.Key -eq [ConsoleKey]::LeftArrow) {
                Write-Host "  >>> DETECTED: Ctrl+Left" -ForegroundColor Green
            }
            elseif ($key.Key -eq [ConsoleKey]::RightArrow) {
                Write-Host "  >>> DETECTED: Ctrl+Right" -ForegroundColor Green
            }
            elseif ($key.Key -eq [ConsoleKey]::C) {
                Write-Host "Exiting..." -ForegroundColor Yellow
                break
            }
        }

        Start-Sleep -Milliseconds 10
    }
}
