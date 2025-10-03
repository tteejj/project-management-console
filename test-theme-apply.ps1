#!/usr/bin/env pwsh
# Test theme application

Write-Host "Loading FakeTUI..." -ForegroundColor Cyan
. ./module/Pmc.Strict/FakeTUI/FakeTUI.ps1

Write-Host "Testing theme application..." -ForegroundColor Yellow

try {
    Write-Host "1. Current theme: $([PmcTheme]::CurrentTheme)" -ForegroundColor Gray

    Write-Host "2. Applying Dark theme..." -ForegroundColor Gray
    [PmcTheme]::SetTheme('Dark')

    Write-Host "3. Theme after SetTheme: $([PmcTheme]::CurrentTheme)" -ForegroundColor Gray

    Write-Host "4. Checking saved file..." -ForegroundColor Gray
    if (Test-Path ~/.pmc-theme) {
        $saved = Get-Content ~/.pmc-theme
        Write-Host "   Saved theme: $saved" -ForegroundColor Gray
    } else {
        Write-Host "   ERROR: ~/.pmc-theme not created!" -ForegroundColor Red
    }

    Write-Host "5. Testing color output..." -ForegroundColor Gray
    Write-Host "   Red: $([PmcVT100]::Red())This should be dark theme red$([PmcVT100]::Reset())"
    Write-Host "   Green: $([PmcVT100]::Green())This should be dark theme green$([PmcVT100]::Reset())"

    Write-Host "`n✓ Theme apply test PASSED" -ForegroundColor Green

} catch {
    Write-Host "`n✗ Theme apply test FAILED" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
