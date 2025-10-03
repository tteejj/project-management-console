#!/usr/bin/env pwsh
# Visual demo of all themes

. ./module/Pmc.Strict/FakeTUI/FakeTUI.ps1

$themes = @('Default', 'Dark', 'Light', 'Solarized')

foreach ($theme in $themes) {
    Clear-Host
    [PmcTheme]::SetTheme($theme)

    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor White
    Write-Host "║     $theme Theme Demo" -ForegroundColor White -NoNewline
    Write-Host (" " * (38 - $theme.Length - 18)) -NoNewline
    Write-Host "║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor White

    # Headers
    Write-Host "$([PmcVT100]::Cyan())$([PmcVT100]::Bold())TASK LIST$([PmcVT100]::Reset())"
    Write-Host ""

    # Task examples
    Write-Host "  $([PmcVT100]::Yellow())>$([PmcVT100]::Reset()) #1234 Fix critical bug          " -NoNewline
    Write-Host "$([PmcVT100]::Red())!!!$([PmcVT100]::Reset()) " -NoNewline
    Write-Host "$([PmcVT100]::Red())⚠️$([PmcVT100]::Reset())  " -NoNewline
    Write-Host "@backend"

    Write-Host "    #1235 Implement new feature      " -NoNewline
    Write-Host "$([PmcVT100]::Yellow())!!$([PmcVT100]::Reset())  " -NoNewline
    Write-Host "   " -NoNewline
    Write-Host "@frontend"

    Write-Host "    #1236 Update documentation       " -NoNewline
    Write-Host "$([PmcVT100]::Green())!$([PmcVT100]::Reset())   " -NoNewline
    Write-Host "   " -NoNewline
    Write-Host "@docs"

    Write-Host ""
    Write-Host "$([PmcVT100]::Cyan())MESSAGES$([PmcVT100]::Reset())"
    Write-Host "  $([PmcVT100]::Green())✓ Task completed successfully$([PmcVT100]::Reset())"
    Write-Host "  $([PmcVT100]::Red())✗ Error: File not found$([PmcVT100]::Reset())"
    Write-Host "  $([PmcVT100]::Yellow())⚠ Warning: Deadline approaching$([PmcVT100]::Reset())"
    Write-Host "  $([PmcVT100]::Blue())ℹ Info: 3 tasks remaining$([PmcVT100]::Reset())"

    Write-Host ""
    Write-Host "$([PmcVT100]::Gray())━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$([PmcVT100]::Reset())"
    Write-Host "$([PmcVT100]::Gray())Status Bar | A:Add E:Edit D:Delete H:Help$([PmcVT100]::Reset())"

    Write-Host "`n"
    if ($theme -ne 'Solarized') {
        Write-Host "Press any key for next theme..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    } else {
        Write-Host "Demo complete! Theme persisted to ~/.pmc-theme" -ForegroundColor Green
    }
}

Write-Host "`n✓ All themes working!`n" -ForegroundColor Green
