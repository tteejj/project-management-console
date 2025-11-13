# Test theme color rendering
# This will show what hex color is ACTUALLY being rendered

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "PMC Theme Color Test" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# 1. Show config file
Write-Host "1. Config file theme:" -ForegroundColor Yellow
$cfg = Get-Content /home/teej/pmc/config.json | ConvertFrom-Json
Write-Host "   Hex: $($cfg.Display.Theme.Hex)" -ForegroundColor Green
Write-Host ""

# 2. Load PMC and check state
Write-Host "2. Loading PMC module..." -ForegroundColor Yellow
Import-Module "/home/teej/pmc/module/Pmc.Strict/Pmc.Strict.psd1" -Force
. "/home/teej/pmc/module/Pmc.Strict/src/Theme.ps1"
Initialize-PmcThemeSystem
$theme = Get-PmcState -Section 'Display' | Select-Object -ExpandProperty Theme
Write-Host "   State hex: $($theme.Hex)" -ForegroundColor Green
Write-Host ""

# 3. Convert to RGB
function ConvertHexToRgb([string]$hex) {
    $hex = $hex.TrimStart('#')
    $r = [Convert]::ToInt32($hex.Substring(0,2), 16)
    $g = [Convert]::ToInt32($hex.Substring(2,2), 16)
    $b = [Convert]::ToInt32($hex.Substring(4,2), 16)
    return @{R=$r; G=$g; B=$b}
}

$rgb = ConvertHexToRgb $theme.Hex
Write-Host "3. RGB values:" -ForegroundColor Yellow
Write-Host "   R: $($rgb.R), G: $($rgb.G), B: $($rgb.B)" -ForegroundColor Green
Write-Host ""

# 4. Render sample with that color
Write-Host "4. Sample rendering with theme color:" -ForegroundColor Yellow
$ansi = "`e[38;2;$($rgb.R);$($rgb.G);$($rgb.B)m"
$reset = "`e[0m"
Write-Host "   ${ansi}THIS TEXT SHOULD BE YOUR THEME COLOR${reset}"
Write-Host "   Expected: Light purple/blue (#AAAAFF = RGB(170,170,255))"
Write-Host ""

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Does the text above match your expected theme color?" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
