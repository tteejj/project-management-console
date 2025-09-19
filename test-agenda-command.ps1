#!/usr/bin/env pwsh

# Test PMC agenda command through the actual command system

. ./start-pmc.ps1

# Simulate the agenda command through the PMC command processor
try {
    Invoke-PmcCommand -Buffer "agenda"
} catch {
    Write-Host "Error running agenda: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}