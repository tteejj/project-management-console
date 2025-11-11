# Start-PmcTUI - Entry point for new PMC TUI architecture
# Replaces old ConsoleUI.Core.ps1 monolithic approach

# Setup logging
# M-CFG-1: Configurable Log Path - uses environment variable or default from Constants
$logPath = if ($env:PMC_LOG_PATH) { $env:PMC_LOG_PATH } else { "/tmp" }
$global:PmcTuiLogFile = Join-Path $logPath "pmc-tui-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-PmcTuiLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logLine = "[$timestamp] [$Level] $Message"
    Add-Content -Path $global:PmcTuiLogFile -Value $logLine
    if ($Level -eq "ERROR") {
        Write-Host $logLine -ForegroundColor Red
    }
}

Write-PmcTuiLog "Loading PMC module..." "INFO"

try {
    # Import PMC module for data functions
    Import-Module "$PSScriptRoot/../Pmc.Strict.psd1" -Force -ErrorAction Stop
    Write-PmcTuiLog "PMC module loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load PMC module: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw
}

Write-PmcTuiLog "Loading dependencies (FieldSchemas, etc.)..." "INFO"

try {
    . "$PSScriptRoot/DepsLoader.ps1"
    Write-PmcTuiLog "Dependencies loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load dependencies: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw
}

Write-PmcTuiLog "Loading SpeedTUI framework..." "INFO"

try {
    . "$PSScriptRoot/SpeedTUILoader.ps1"
    Write-PmcTuiLog "SpeedTUI framework loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load SpeedTUI: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw
}

Write-PmcTuiLog "Loading PraxisVT (ANSI/VT100 helpers)..." "INFO"

try {
    . "$PSScriptRoot/../src/PraxisVT.ps1"
    Write-PmcTuiLog "PraxisVT loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load PraxisVT: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw
}

Write-PmcTuiLog "Loading helpers..." "INFO"

try {
    Get-ChildItem -Path "$PSScriptRoot/helpers" -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
        . $_.FullName
    }
    Write-PmcTuiLog "Helpers loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load helpers: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw
}

Write-PmcTuiLog "Loading services..." "INFO"

try {
    Get-ChildItem -Path "$PSScriptRoot/services" -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
        . $_.FullName
    }
    Write-PmcTuiLog "Services loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load services: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw
}

Write-PmcTuiLog "Loading PMC widget layer (extends SpeedTUI)..." "INFO"

try {
    . "$PSScriptRoot/widgets/PmcWidget.ps1"
    . "$PSScriptRoot/widgets/PmcPanel.ps1"
    . "$PSScriptRoot/widgets/PmcMenuBar.ps1"
    . "$PSScriptRoot/widgets/PmcHeader.ps1"
    . "$PSScriptRoot/widgets/PmcFooter.ps1"
    . "$PSScriptRoot/widgets/PmcStatusBar.ps1"
    . "$PSScriptRoot/layout/PmcLayoutManager.ps1"
    . "$PSScriptRoot/theme/PmcThemeManager.ps1"
    Write-PmcTuiLog "Legacy infrastructure loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load legacy infrastructure: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw
}

Write-PmcTuiLog "Loading PmcScreen base class..." "INFO"

try {
    . "$PSScriptRoot/PmcScreen.ps1"
    Write-PmcTuiLog "PmcScreen loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load PmcScreen: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw
}

Write-PmcTuiLog "Loading widgets..." "INFO"

try {
    $widgetFiles = @(
        "TextInput.ps1",
        "DatePicker.ps1",
        "ProjectPicker.ps1",
        "TagEditor.ps1",
        "FilterPanel.ps1",
        "InlineEditor.ps1",
        "UniversalList.ps1",
        "TimeEntryDetailDialog.ps1",
        "TextAreaEditor.ps1"
    )

    foreach ($widgetFile in $widgetFiles) {
        $widgetPath = Join-Path "$PSScriptRoot/widgets" $widgetFile
        if (Test-Path $widgetPath) {
            . $widgetPath
        }
    }
    Write-PmcTuiLog "Widgets loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load widgets: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw
}

Write-PmcTuiLog "Loading base classes..." "INFO"

try {
    . "$PSScriptRoot/base/StandardFormScreen.ps1"
    . "$PSScriptRoot/base/StandardListScreen.ps1"
    . "$PSScriptRoot/base/StandardDashboard.ps1"
    Write-PmcTuiLog "Base classes loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load base classes: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw
}

Write-PmcTuiLog "Loading PmcApplication..." "INFO"

try {
    . "$PSScriptRoot/PmcApplication.ps1"
    Write-PmcTuiLog "PmcApplication loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load PmcApplication: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw
}

Write-PmcTuiLog "Loading screens..." "INFO"

try {
    . "$PSScriptRoot/screens/TaskListScreen.ps1"
    Write-PmcTuiLog "TaskListScreen loaded" "INFO"
    . "$PSScriptRoot/screens/BlockedTasksScreen.ps1"
    Write-PmcTuiLog "BlockedTasksScreen loaded" "INFO"
    . "$PSScriptRoot/screens/SettingsScreen.ps1"
    Write-PmcTuiLog "SettingsScreen loaded" "INFO"
    . "$PSScriptRoot/screens/ThemeEditorScreen.ps1"
    Write-PmcTuiLog "ThemeEditorScreen loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load screens: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw
}

<#
.SYNOPSIS
Start PMC TUI with new architecture

.DESCRIPTION
Entry point for SpeedTUI-based PMC interface.
Creates application and launches screens.

.PARAMETER StartScreen
Which screen to launch (default: BlockedTasks)

.EXAMPLE
Start-PmcTUI
Start-PmcTUI -StartScreen BlockedTasks
#>
function Start-PmcTUI {
    param(
        [string]$StartScreen = "TaskList"
    )

    Write-Host "Starting PMC TUI (SpeedTUI Architecture)..." -ForegroundColor Cyan
    Write-PmcTuiLog "Starting PMC TUI with screen: $StartScreen" "INFO"

    try {
        # Create application
        Write-PmcTuiLog "Creating PmcApplication..." "INFO"
        $global:PmcApp = [PmcApplication]::new()
        Write-PmcTuiLog "PmcApplication created" "INFO"

        # Launch requested screen
        Write-PmcTuiLog "Launching screen: $StartScreen" "INFO"
        switch ($StartScreen) {
            'TaskList' {
                Write-PmcTuiLog "Creating TaskListScreen..." "INFO"
                $screen = [TaskListScreen]::new()
                Write-PmcTuiLog "Pushing screen to app..." "INFO"
                $global:PmcApp.PushScreen($screen)
                Write-PmcTuiLog "Screen pushed successfully" "INFO"
            }
            'BlockedTasks' {
                Write-PmcTuiLog "Creating BlockedTasksScreen..." "INFO"
                $screen = [BlockedTasksScreen]::new()
                Write-PmcTuiLog "Pushing screen to app..." "INFO"
                $global:PmcApp.PushScreen($screen)
                Write-PmcTuiLog "Screen pushed successfully" "INFO"
            }
            'Demo' {
                Write-PmcTuiLog "Loading DemoScreen..." "INFO"
                . "$PSScriptRoot/DemoScreen.ps1"
                $screen = [DemoScreen]::new()
                $global:PmcApp.PushScreen($screen)
                Write-PmcTuiLog "Demo screen pushed" "INFO"
            }
            default {
                Write-PmcTuiLog "Unknown screen: $StartScreen" "ERROR"
                throw "Unknown screen: $StartScreen"
            }
        }

        # Run event loop
        Write-PmcTuiLog "Starting event loop..." "INFO"
        $global:PmcApp.Run()
        Write-PmcTuiLog "Event loop exited normally" "INFO"

    } catch {
        Write-PmcTuiLog "EXCEPTION: $_" "ERROR"
        Write-PmcTuiLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
        Write-PmcTuiLog "Exception details: $($_.Exception | Out-String)" "ERROR"

        Write-Host "`e[?25h"  # Show cursor
        Write-Host "`e[2J`e[H"  # Clear screen
        Write-Host "PMC TUI Error: $_" -ForegroundColor Red
        Write-Host "Log file: $global:PmcTuiLogFile" -ForegroundColor Yellow
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        throw
    } finally {
        # Cleanup
        Write-PmcTuiLog "Cleanup - showing cursor and resetting terminal" "INFO"
        Write-Host "`e[?25h"  # Show cursor
        Write-Host "`e[0m"    # Reset colors
        Write-Host "Log saved to: $global:PmcTuiLogFile" -ForegroundColor Gray
    }
}

# Allow direct execution
if ($MyInvocation.InvocationName -match 'Start-PmcTUI') {
    Start-PmcTUI @args
}
