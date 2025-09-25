#!/usr/bin/env pwsh

# Test script for verifying the universal display system is working

Write-Host "Testing PMC Universal Display System Integration" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

try {
    Import-Module "/home/teej/pmc/module/Pmc.Strict" -Force

    Write-Host "`nTesting direct function calls:" -ForegroundColor Yellow

    # Test 1: Direct grid function
    Write-Host "1. Testing Show-PmcDataGrid..." -ForegroundColor Cyan
    try {
        Show-PmcDataGrid -Domains @("task") -Filters @{"status" = "pending"} -Title "📋 TEST: All Pending Tasks"
        Write-Host "✅ Show-PmcDataGrid works!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Show-PmcDataGrid failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 2: Universal dispatcher
    Write-Host "`n2. Testing Show-PmcData universal dispatcher..." -ForegroundColor Cyan
    try {
        Show-PmcData -DataType "task" -Filters @{"status" = "pending"} -Title "📋 TEST: Universal Dispatcher"
        Write-Host "✅ Show-PmcData works!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Show-PmcData failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 3: View functions
    Write-Host "`n3. Testing updated view functions..." -ForegroundColor Cyan
    try {
        Show-PmcTodayTasks
        Write-Host "✅ Show-PmcTodayTasks works!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Show-PmcTodayTasks failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`nAll tests completed!" -ForegroundColor Green
    Write-Host "`nTry these commands to see the interactive grid in action:" -ForegroundColor Yellow
    Write-Host "  • Show-PmcTodayTasks" -ForegroundColor White
    Write-Host "  • Show-PmcOverdueTasks" -ForegroundColor White
    Write-Host "  • Show-PmcDataGrid -Domains @('task') -Interactive" -ForegroundColor White

} catch {
    Write-Host "❌ Module import or setup failed: $($_.Exception.Message)" -ForegroundColor Red
}