#!/usr/bin/env pwsh
# Test theme system

. ./module/Pmc.Strict/FakeTUI/FakeTUI.ps1

Write-Host "`n=== Theme System Test ===`n" -ForegroundColor Cyan

# Test default theme
Write-Host "Testing Default theme..." -ForegroundColor Yellow
[PmcTheme]::SetTheme('Default')
Write-Host "  Red: $([PmcVT100]::Red())This is red$([PmcVT100]::Reset())"
Write-Host "  Green: $([PmcVT100]::Green())This is green$([PmcVT100]::Reset())"
Write-Host "  Yellow: $([PmcVT100]::Yellow())This is yellow$([PmcVT100]::Reset())"
Write-Host "  Cyan: $([PmcVT100]::Cyan())This is cyan$([PmcVT100]::Reset())"
Write-Host ""

# Test Dark theme
Write-Host "Testing Dark theme..." -ForegroundColor Yellow
[PmcTheme]::SetTheme('Dark')
Write-Host "  Red: $([PmcVT100]::Red())This is red$([PmcVT100]::Reset())"
Write-Host "  Green: $([PmcVT100]::Green())This is green$([PmcVT100]::Reset())"
Write-Host "  Yellow: $([PmcVT100]::Yellow())This is yellow$([PmcVT100]::Reset())"
Write-Host "  Cyan: $([PmcVT100]::Cyan())This is cyan$([PmcVT100]::Reset())"
Write-Host ""

# Test Light theme
Write-Host "Testing Light theme..." -ForegroundColor Yellow
[PmcTheme]::SetTheme('Light')
Write-Host "  Red: $([PmcVT100]::Red())This is red$([PmcVT100]::Reset())"
Write-Host "  Green: $([PmcVT100]::Green())This is green$([PmcVT100]::Reset())"
Write-Host "  Yellow: $([PmcVT100]::Yellow())This is yellow$([PmcVT100]::Reset())"
Write-Host "  Cyan: $([PmcVT100]::Cyan())This is cyan$([PmcVT100]::Reset())"
Write-Host ""

# Test Solarized theme
Write-Host "Testing Solarized theme..." -ForegroundColor Yellow
[PmcTheme]::SetTheme('Solarized')
Write-Host "  Red: $([PmcVT100]::Red())This is red$([PmcVT100]::Reset())"
Write-Host "  Green: $([PmcVT100]::Green())This is green$([PmcVT100]::Reset())"
Write-Host "  Yellow: $([PmcVT100]::Yellow())This is yellow$([PmcVT100]::Reset())"
Write-Host "  Cyan: $([PmcVT100]::Cyan())This is cyan$([PmcVT100]::Reset())"
Write-Host ""

# Test persistence
Write-Host "Testing persistence..." -ForegroundColor Yellow
[PmcTheme]::SetTheme('Dark')
$savedTheme = Get-Content ~/.pmc-theme -ErrorAction SilentlyContinue
Write-Host "  Saved theme: $savedTheme"
Write-Host "  Current theme: $([PmcTheme]::CurrentTheme)"

# Test loading
[PmcTheme]::LoadTheme()
Write-Host "  Loaded theme: $([PmcTheme]::CurrentTheme)"

Write-Host "`n✓ Theme system test complete!`n" -ForegroundColor Green

# Reset to default
[PmcTheme]::SetTheme('Default')
