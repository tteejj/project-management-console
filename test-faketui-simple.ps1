#!/usr/bin/env pwsh
# Simple test showing FakeTUI works with PMC data

Import-Module ./module/Pmc.Strict -Force

Write-Host "Loading FakeTUI (simple all-in-one version)..." -ForegroundColor Yellow
. ./module/Pmc.Strict/FakeTUI/FakeTUI.ps1

Write-Host "Loading PMC data..." -ForegroundColor Yellow
$data = Get-PmcAllData
Write-Host "Found $($data.tasks.Count) tasks and $($data.projects.Count) projects" -ForegroundColor Cyan

Write-Host ""
Write-Host "Starting FakeTUI (Press Alt for menus, Esc to exit)..." -ForegroundColor Green
Start-Sleep -Seconds 1

try {
    $app = [PmcFakeTUIApp]::new()
    $app.Initialize()
    $app.Run()
    $app.Shutdown()
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host "FakeTUI exited" -ForegroundColor Green
