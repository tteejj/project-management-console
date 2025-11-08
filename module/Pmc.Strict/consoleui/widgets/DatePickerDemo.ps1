#!/usr/bin/env pwsh
# DatePickerDemo.ps1 - Interactive demonstration of DatePicker widget
#
# This script provides a full interactive demo of the DatePicker widget,
# showing both text and calendar modes in action.

using namespace System

# Load dependencies
$scriptPath = Split-Path -Parent $PSCommandPath
. "$scriptPath/../SpeedTUILoader.ps1"
. "$scriptPath/PmcWidget.ps1"
. "$scriptPath/DatePicker.ps1"

function Show-Instructions {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "     DatePicker Interactive Demo       " -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Controls:" -ForegroundColor Green
    Write-Host "  Tab/F2      - Toggle between Text and Calendar mode" -ForegroundColor Gray
    Write-Host "  Enter       - Confirm selection" -ForegroundColor Gray
    Write-Host "  Escape      - Cancel" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Text Mode:" -ForegroundColor Green
    Write-Host "  Type natural language dates:" -ForegroundColor Gray
    Write-Host "    today, tomorrow, +7, next friday, jan 15, 2025-03-15" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Calendar Mode:" -ForegroundColor Green
    Write-Host "  Arrow keys  - Navigate days" -ForegroundColor Gray
    Write-Host "  PgUp/PgDn   - Change months" -ForegroundColor Gray
    Write-Host "  Home/End    - Start/end of month" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Press any key to start..." -ForegroundColor Yellow
    $null = [Console]::ReadKey($true)
}

function Run-DatePickerDemo {
    # Clear screen
    Write-Host "`e[2J`e[H" -NoNewline

    Show-Instructions

    # Clear screen for picker
    Write-Host "`e[2J`e[H" -NoNewline

    # Create picker
    $picker = [DatePicker]::new()
    $picker.SetPosition(5, 2)
    $picker.SetDate([DateTime]::Today)
    $picker._textInput = [DateTime]::Today.ToString("yyyy-MM-dd")

    # Status message area
    $statusY = 20

    # Event handlers
    $picker.OnDateChanged = {
        param($date)
        # Update status
        Write-Host "`e[${statusY};0H" -NoNewline
        Write-Host "`e[K" -NoNewline  # Clear line
        Write-Host "Date changed to: $($date.ToString('yyyy-MM-dd (dddd)'))" -ForegroundColor Cyan -NoNewline
    }

    $picker.OnConfirmed = {
        param($date)
        Write-Host "`e[${statusY};0H" -NoNewline
        Write-Host "`e[K" -NoNewline
        Write-Host "Confirmed: $($date.ToString('yyyy-MM-dd (dddd)'))" -ForegroundColor Green -NoNewline
    }

    $picker.OnCancelled = {
        Write-Host "`e[${statusY};0H" -NoNewline
        Write-Host "`e[K" -NoNewline
        Write-Host "Cancelled" -ForegroundColor Red -NoNewline
    }

    # Main input loop
    while (-not $picker.IsConfirmed -and -not $picker.IsCancelled) {
        # Clear and render
        Write-Host "`e[2J`e[H" -NoNewline

        # Render picker
        $output = $picker.Render()
        Write-Host $output -NoNewline

        # Quick help reminder
        $helpY = 18
        Write-Host "`e[${helpY};0H" -NoNewline
        Write-Host "Quick help: Tab=Toggle mode | Arrows=Navigate | Enter=Confirm | Esc=Cancel" -ForegroundColor Gray -NoNewline

        # Read and handle input
        $key = [Console]::ReadKey($true)
        $picker.HandleInput($key) | Out-Null
    }

    # Clear screen
    Write-Host "`e[2J`e[H" -NoNewline

    # Show result
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "             Result                     " -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    if ($picker.IsConfirmed) {
        $selected = $picker.GetSelectedDate()
        Write-Host "You selected: " -NoNewline
        Write-Host $selected.ToString("yyyy-MM-dd (dddd)") -ForegroundColor Green
        Write-Host ""
        Write-Host "Full DateTime: $selected" -ForegroundColor Gray
        Write-Host "Day of Year: $($selected.DayOfYear)" -ForegroundColor Gray
        Write-Host "Week of Year: $($selected.DayOfYear / 7 + 1 | ForEach-Object { [Math]::Floor($_) })" -ForegroundColor Gray
        Write-Host "Is Leap Year: $([DateTime]::IsLeapYear($selected.Year))" -ForegroundColor Gray
    } else {
        Write-Host "Selection cancelled" -ForegroundColor Red
    }

    Write-Host ""
}

# Run demo
try {
    Run-DatePickerDemo
} catch {
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
    exit 1
}

Write-Host "Demo complete!" -ForegroundColor Green
Write-Host ""
