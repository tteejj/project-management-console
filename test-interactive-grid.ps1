#!/usr/bin/env pwsh

# Test script for the enhanced interactive grid system

# Import the PMC module
Push-Location (Split-Path $PSScriptRoot)
try {
    Import-Module "./module/Pmc.Strict" -Force -Verbose

    Write-Host "Testing Enhanced PMC Grid System" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    Write-Host ""

    Write-Host "Available test commands:" -ForegroundColor Yellow
    Write-Host "  1. Test static grid:      Show-PmcDataGrid -Domains @('task') -Filters @{'status'='pending'}"
    Write-Host "  2. Test interactive grid: Show-PmcDataGrid -Domains @('task') -Filters @{'status'='pending'} -Interactive"
    Write-Host "  3. Test today's tasks:    Show-PmcData -DataType 'task' -Filters @{'status'='pending'; 'due_range'='today'} -Interactive"
    Write-Host ""

    # Test 1: Static grid display
    Write-Host "Testing static grid display..." -ForegroundColor Cyan
    try {
        Show-PmcDataGrid -Domains @("task") -Filters @{
            "status" = "pending"
        } -Title "📋 TEST STATIC GRID"
        Write-Host "✅ Static grid test completed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Static grid test failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "Press any key to test interactive mode (press 'q' to exit interactive mode)..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    # Test 2: Interactive grid
    Write-Host "Testing interactive grid..." -ForegroundColor Cyan
    try {
        Show-PmcDataGrid -Domains @("task") -Filters @{
            "status" = "pending"
        } -Title "📋 TEST INTERACTIVE GRID" -Interactive
        Write-Host "✅ Interactive grid test completed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Interactive grid test failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Error details: $($_.Exception)" -ForegroundColor Red
    }

} catch {
    Write-Host "❌ Module import failed: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Pop-Location
}