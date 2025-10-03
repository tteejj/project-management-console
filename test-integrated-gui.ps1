#!/usr/bin/env pwsh

# Test script for integrated FakeTUI with real PMC data
# Run this in a PowerShell terminal (not bash) for proper keyboard input

param([switch]$NoInteractive)

Write-Host "Testing PMC FakeTUI Integration..." -ForegroundColor Green

# Import PMC module
Import-Module "./module/Pmc.Strict" -Force

# Check if we have PMC data
Write-Host "Checking PMC data..." -ForegroundColor Yellow
try {
    $data = Get-PmcData
    $taskCount = if ($data.tasks) { $data.tasks.Count } else { 0 }
    $projectCount = if ($data.projects) { $data.projects.Count } else { 0 }

    Write-Host "Found $taskCount tasks and $projectCount projects" -ForegroundColor Green

    # Show sample data
    if ($taskCount -gt 0) {
        Write-Host "Sample tasks:" -ForegroundColor Cyan
        $data.tasks | Select-Object -First 3 | ForEach-Object {
            Write-Host "  #$($_.id): $($_.text) [$($_.status)]" -ForegroundColor Gray
        }
    }

    if ($projectCount -gt 0) {
        Write-Host "Sample projects:" -ForegroundColor Cyan
        $data.projects | Select-Object -First 3 | ForEach-Object {
            Write-Host "  $($_.name) [$($_.status)]" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "No PMC data found or error loading: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Creating sample data for testing..." -ForegroundColor Yellow

    # Create sample data
    try {
        Invoke-Expression 'add task "Sample task 1" --project "Test Project" --priority high'
        Invoke-Expression 'add task "Sample task 2" --project "Test Project" --priority medium'
        Invoke-Expression 'add task "Sample task 3" --priority low'
        Write-Host "Sample data created" -ForegroundColor Green
    } catch {
        Write-Host "Failed to create sample data: $_" -ForegroundColor Red
    }
}

if ($NoInteractive) {
    Write-Host "Skipping FakeTUI launch (NoInteractive mode)" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Launching PMC FakeTUI..." -ForegroundColor Green
Write-Host "Note: This requires a proper PowerShell console with keyboard input" -ForegroundColor Yellow
Write-Host "If you see ReadKey errors, run this directly in PowerShell, not through bash" -ForegroundColor Yellow
Write-Host ""

try {
    # Load and start FakeTUI
    . "./module/Pmc.Strict/FakeTUI/FakeTUIAppIntegrated.ps1"

    $app = [PmcFakeTUIAppIntegrated]::new()
    $app.Initialize()
    $app.Run()
    $app.Shutdown()

    Write-Host "FakeTUI exited successfully" -ForegroundColor Green

} catch {
    Write-Host "FakeTUI failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.Exception.StackTrace)" -ForegroundColor Red
}

Write-Host "Test completed" -ForegroundColor Green