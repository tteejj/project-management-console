#!/usr/bin/env pwsh

# Force agenda test - bypass interactive requirement

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Import the module directly
Import-Module "./module/Pmc.Strict" -Force

# Call Show-PmcAgenda directly without going through PMC's command system
try {
    Write-Host "=== DIRECT CALL TO Show-PmcAgenda ===" -ForegroundColor Yellow
    $context = $null  # Most functions don't actually use the context parameter
    Show-PmcAgenda -Context $context
    Write-Host "=== END DIRECT CALL ===" -ForegroundColor Yellow
} catch {
    Write-Host "Error calling Show-PmcAgenda directly: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}

Write-Host "`n=== ALTERNATIVE: Call via command system ===" -ForegroundColor Yellow
try {
    # Try calling through PMC's command processor
    Invoke-PmcCommand -Buffer "agenda"
} catch {
    Write-Host "Error via command system: $($_.Exception.Message)" -ForegroundColor Red
}