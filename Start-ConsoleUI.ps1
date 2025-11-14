#!/usr/bin/env pwsh
<#
.SYNOPSIS
Launch PMC ConsoleUI (SpeedTUI-based TUI)

.DESCRIPTION
Windows/PowerShell launcher for PMC Terminal User Interface.
Supports debug logging and configurable log levels.

.PARAMETER DebugLog
Enable debug logging to file

.PARAMETER LogLevel
Set log verbosity: 0=off (default), 1=errors, 2=info, 3=verbose

.EXAMPLE
# Normal mode (logging disabled for performance)
.\Start-ConsoleUI.ps1

.EXAMPLE
# With debug logging
.\Start-ConsoleUI.ps1 -DebugLog -LogLevel 3

.EXAMPLE
# Errors only
.\Start-ConsoleUI.ps1 -LogLevel 1

.NOTES
File: Start-ConsoleUI.ps1
Purpose: Windows PowerShell launcher for PMC ConsoleUI
Performance: Logging disabled by default (30-40% CPU reduction)
#>

param(
    [switch]$DebugLog,
    [int]$LogLevel = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Get script directory
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Path to actual ConsoleUI entry point
$consoleUIScript = Join-Path $scriptRoot 'module/Pmc.Strict/consoleui/Start-PmcTUI.ps1'

# Verify entry point exists
if (-not (Test-Path $consoleUIScript)) {
    Write-Host "ERROR: ConsoleUI entry point not found at: $consoleUIScript" -ForegroundColor Red
    Write-Host "Expected location: module/Pmc.Strict/consoleui/Start-PmcTUI.ps1" -ForegroundColor Yellow
    exit 1
}

# Display startup message
Write-Host "PMC ConsoleUI - Terminal User Interface" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

if ($DebugLog -or $LogLevel -gt 0) {
    Write-Host "Debug Logging: ENABLED (Level $LogLevel)" -ForegroundColor Yellow
} else {
    Write-Host "Performance Mode: Logging DISABLED" -ForegroundColor Green
}

Write-Host ""

# Launch ConsoleUI with parameters
try {
    # Build parameter splat
    $params = @{}
    if ($DebugLog) {
        $params['DebugLog'] = $true
    }
    if ($LogLevel -gt 0) {
        $params['LogLevel'] = $LogLevel
    }

    # Invoke ConsoleUI entry point
    & $consoleUIScript @params

} catch {
    Write-Host ""
    Write-Host "ERROR: ConsoleUI failed to start" -ForegroundColor Red
    Write-Host "Message: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Ensure PMC module is installed" -ForegroundColor Gray
    Write-Host "  2. Check module/Pmc.Strict/Pmc.Strict.psd1 exists" -ForegroundColor Gray
    Write-Host "  3. Try with debug logging: .\Start-ConsoleUI.ps1 -DebugLog -LogLevel 3" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

