#!/usr/bin/env pwsh
# Simple PMC launcher that bypasses problematic initialization

param([switch]$Debug)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

# Import just the essential parts
Import-Module './module/Pmc.Strict' -Force

Write-Host ""
Write-Host "pmc — enhanced project management console" -ForegroundColor Cyan
Write-Host "Type 'help' for commands, 'status' for system info, 'exit' to quit." -ForegroundColor Gray
Write-Host ""

if ($Debug) {
    Write-Host "✓ Debug mode enabled" -ForegroundColor Green
    Write-Host "✓ Interactive mode: Tab for completions enabled" -ForegroundColor Green
}

# Simple interactive mode - no fallbacks
Enable-PmcInteractiveMode

Write-Host "Goodbye!" -ForegroundColor Green