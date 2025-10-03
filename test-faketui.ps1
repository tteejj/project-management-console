#!/usr/bin/env pwsh

# PMC FakeTUI Demo Script
# Test the new lightweight TUI interface

param(
    [switch]$SkipModuleReload,
    [switch]$Verbose
)

Push-Location (Split-Path $PSScriptRoot)

try {
    Write-Host "PMC FakeTUI Demo" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    Write-Host ""

    # Import PMC module
    if (-not $SkipModuleReload) {
        Write-Host "Loading PMC module..." -ForegroundColor Yellow
        Import-Module "./module/Pmc.Strict" -Force -Verbose:$Verbose
        Write-Host "✓ PMC module loaded" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "FakeTUI Features:" -ForegroundColor Green
    Write-Host "• Keyboard-only navigation (no mouse)" -ForegroundColor White
    Write-Host "• Excel/lynx-style menu system" -ForegroundColor White
    Write-Host "• Alt+key direct access (Alt+T for Tasks, Alt+P for Projects)" -ForegroundColor White
    Write-Host "• Integration with existing PMC CLI commands" -ForegroundColor White
    Write-Host "• Static UI with selective updates (no constant redraws)" -ForegroundColor White
    Write-Host "• Performance optimized with SpeedTUI techniques" -ForegroundColor White
    Write-Host ""

    Write-Host "Navigation Quick Reference:" -ForegroundColor Cyan
    Write-Host "  Alt              - Activate menu mode" -ForegroundColor Yellow
    Write-Host "  Alt+Letter       - Direct menu access (F=File, T=Task, P=Project, etc.)" -ForegroundColor Yellow
    Write-Host "  ←→               - Navigate between menus" -ForegroundColor Yellow
    Write-Host "  ↑↓               - Navigate within dropdowns" -ForegroundColor Yellow
    Write-Host "  Enter            - Select menu item" -ForegroundColor Yellow
    Write-Host "  Esc              - Exit menu mode / Cancel" -ForegroundColor Yellow
    Write-Host "  Ctrl+Q           - Exit application" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Available Menus:" -ForegroundColor Cyan
    Write-Host "  File(F)    - New Project, Import/Export, Exit" -ForegroundColor White
    Write-Host "  Task(T)    - Add, List, Search, Done, Edit, Delete" -ForegroundColor White
    Write-Host "  Project(P) - Create, Switch, Stats, Archive" -ForegroundColor White
    Write-Host "  View(V)    - Today, Week, Overdue, Kanban, Grid" -ForegroundColor White
    Write-Host "  Tools(O)   - Settings, Theme, Debug, Backup" -ForegroundColor White
    Write-Host "  Help(H)    - Commands, Shortcuts, Guide, About" -ForegroundColor White
    Write-Host ""

    # Check if we have PMC data
    try {
        $data = Get-PmcData -ErrorAction SilentlyContinue
        if ($data) {
            $taskCount = @($data.tasks).Count
            $projectCount = @($data.projects).Count
            Write-Host "Current PMC Data:" -ForegroundColor Green
            Write-Host "  Tasks: $taskCount" -ForegroundColor White
            Write-Host "  Projects: $projectCount" -ForegroundColor White
        } else {
            Write-Host "No PMC data found - you can create tasks and projects through the TUI!" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "PMC data not accessible - using demo mode" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Starting FakeTUI..." -ForegroundColor Green
    Write-Host "Press any key to continue..."
    $null = [Console]::ReadKey($true)

    # Launch FakeTUI
    Start-PmcFakeTUI

    Write-Host ""
    Write-Host "FakeTUI Demo completed!" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "❌ Demo failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
} finally {
    Pop-Location
}