#!/usr/bin/env pwsh

# Quick test of PMC FakeTUI integration

Import-Module "./module/Pmc.Strict" -Force

Write-Host "Loading FakeTUI..." -ForegroundColor Yellow

# Load FakeTUI directly
. "./module/Pmc.Strict/FakeTUI/FakeTUI.ps1"

Write-Host "Starting FakeTUI..." -ForegroundColor Green

try {
    $app = [PmcFakeTUIApp]::new()
    $app.Initialize()
    $app.Run()
    $app.Shutdown()
    Write-Host "FakeTUI exited successfully" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}