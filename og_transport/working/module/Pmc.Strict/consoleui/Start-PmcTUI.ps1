# Start-PmcTUI - Entry point for new PMC TUI architecture
# Replaces old ConsoleUI.Core.ps1 monolithic approach

param(
    [switch]$DebugLog,      # Enable debug logging to file
    [int]$LogLevel = 0      # 0=off, 1=errors only, 2=info, 3=verbose
)

Set-StrictMode -Version Latest

# Setup logging (DISABLED BY DEFAULT for performance)
# M-CFG-1: Configurable Log Path - uses environment variable or local directory for portability
# PORTABILITY: Default to .pmc-data/logs directory relative to module root (self-contained)
if ($DebugLog -or $LogLevel -gt 0) {
    $logPath = $(if ($env:PMC_LOG_PATH) {
        $env:PMC_LOG_PATH
    } else {
        $moduleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $localLogDir = Join-Path $moduleRoot ".pmc-data/logs"
        if (-not (Test-Path $localLogDir)) {
            New-Item -ItemType Directory -Path $localLogDir -Force | Out-Null
        }
        $localLogDir
    })
    $global:PmcTuiLogFile = Join-Path $logPath "pmc-tui-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    $global:PmcTuiLogLevel = $LogLevel
    Write-Host "Debug logging enabled: $global:PmcTuiLogFile (Level $LogLevel)" -ForegroundColor Yellow
} else {
    $global:PmcTuiLogFile = $null
    $global:PmcTuiLogLevel = 0
}

# PERFORMANCE FIX: Global flag to disable ALL debug logging
# Set to $false to disable pmc-flow-debug.log writes (huge performance gain)
$global:PmcEnableFlowDebug = $false

function Write-PmcTuiLog {
    param([string]$Message, [string]$Level = "INFO")

    # Skip if logging disabled
    if (-not $global:PmcTuiLogFile) { return }

    # Filter by log level
    $levelValue = switch ($Level) {
        "ERROR" { 1 }
        "INFO"  { 2 }
        "DEBUG" { 3 }
        default { 2 }
    }

    if ($levelValue -gt $global:PmcTuiLogLevel) { return }

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

# ============================================================================
# DIRECT LOAD SEQUENCE - Everything in correct dependency order, no duplicates
# ============================================================================

Write-PmcTuiLog "Loading SpeedTUI framework..." "INFO"
try {
    . "$PSScriptRoot/SpeedTUILoader.ps1"
    Write-PmcTuiLog "SpeedTUI framework loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load SpeedTUI: $_" "ERROR"
    throw
}

Write-PmcTuiLog "Loading PMC core classes..." "INFO"
try {
    # Core primitives
    . "$PSScriptRoot/../src/PraxisVT.ps1"
    . "$PSScriptRoot/src/PmcThemeEngine.ps1"
    . "$PSScriptRoot/ZIndex.ps1"
    . "$PSScriptRoot/layout/PmcLayoutManager.ps1"
    . "$PSScriptRoot/PmcScreen.ps1"
    Write-PmcTuiLog "Core classes loaded (PraxisVT, PmcThemeEngine, ZIndex, PmcLayoutManager, PmcScreen)" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load PMC core: $_" "ERROR"
    throw
}

Write-PmcTuiLog "Loading theme system..." "INFO"
try {
    . "$PSScriptRoot/theme/PmcThemeManager.ps1"
    Write-PmcTuiLog "Theme system loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load theme: $_" "ERROR"
    throw
}

Write-PmcTuiLog "Loading widgets..." "INFO"
try {
    # Base widgets first
    . "$PSScriptRoot/widgets/PmcWidget.ps1"
    . "$PSScriptRoot/widgets/PmcDialog.ps1"

    # All other widgets (excluding Test* files)
    . "$PSScriptRoot/widgets/DatePicker.ps1"
    . "$PSScriptRoot/widgets/FilterPanel.ps1"
    . "$PSScriptRoot/widgets/InlineEditor.ps1"
    . "$PSScriptRoot/widgets/PmcFilePicker.ps1"
    . "$PSScriptRoot/widgets/PmcFooter.ps1"
    . "$PSScriptRoot/widgets/PmcHeader.ps1"
    . "$PSScriptRoot/widgets/PmcMenuBar.ps1"
    . "$PSScriptRoot/widgets/PmcPanel.ps1"
    . "$PSScriptRoot/widgets/PmcStatusBar.ps1"
    . "$PSScriptRoot/widgets/ProjectPicker.ps1"
    . "$PSScriptRoot/widgets/SimpleFilePicker.ps1"
    . "$PSScriptRoot/widgets/TabPanel.ps1"
    . "$PSScriptRoot/widgets/TagEditor.ps1"
    . "$PSScriptRoot/widgets/TextAreaEditor.ps1"
    . "$PSScriptRoot/widgets/TextInput.ps1"
    . "$PSScriptRoot/widgets/TimeEntryDetailDialog.ps1"
    . "$PSScriptRoot/widgets/UniversalList.ps1"
    Write-PmcTuiLog "Widgets loaded (19 total)" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load widgets: $_" "ERROR"
    throw
}

Write-PmcTuiLog "Loading base classes..." "INFO"
try {
    . "$PSScriptRoot/base/StandardDashboard.ps1"
    . "$PSScriptRoot/base/StandardFormScreen.ps1"
    . "$PSScriptRoot/base/StandardListScreen.ps1"
    . "$PSScriptRoot/base/TabbedScreen.ps1"
    Write-PmcTuiLog "Base classes loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load base classes: $_" "ERROR"
    throw
}

Write-PmcTuiLog "Loading services..." "INFO"
try {
    . "$PSScriptRoot/services/ChecklistService.ps1"
    . "$PSScriptRoot/services/CommandService.ps1"
    . "$PSScriptRoot/services/ExcelComReader.ps1"
    . "$PSScriptRoot/services/ExcelMappingService.ps1"
    . "$PSScriptRoot/services/MenuRegistry.ps1"
    . "$PSScriptRoot/services/NoteService.ps1"
    . "$PSScriptRoot/services/PreferencesService.ps1"
    . "$PSScriptRoot/services/TaskStore.ps1"
    Write-PmcTuiLog "Services loaded (8 total)" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load services: $_" "ERROR"
    throw
}

Write-PmcTuiLog "Loading helpers..." "INFO"
try {
    . "$PSScriptRoot/helpers/ConfigCache.ps1"
    . "$PSScriptRoot/helpers/Constants.ps1"
    . "$PSScriptRoot/helpers/DataBindingHelper.ps1"
    . "$PSScriptRoot/helpers/GapBuffer.ps1"
    . "$PSScriptRoot/helpers/LinuxKeyHelper.ps1"
    . "$PSScriptRoot/helpers/ShortcutRegistry.ps1"
    . "$PSScriptRoot/helpers/ThemeHelper.ps1"
    . "$PSScriptRoot/helpers/TypeNormalization.ps1"
    . "$PSScriptRoot/helpers/ValidationHelper.ps1"
    Write-PmcTuiLog "Helpers loaded (9 total)" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load helpers: $_" "ERROR"
    throw
}

Write-PmcTuiLog "Loading ServiceContainer and Application..." "INFO"
try {
    . "$PSScriptRoot/ServiceContainer.ps1"
    . "$PSScriptRoot/PmcApplication.ps1"
    Write-PmcTuiLog "ServiceContainer and Application loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load application: $_" "ERROR"
    throw
}

Write-PmcTuiLog "Loading initial screens..." "INFO"
try {
    . "$PSScriptRoot/screens/HelpViewScreen.ps1"
    . "$PSScriptRoot/screens/TaskListScreen.ps1"
    . "$PSScriptRoot/screens/ProjectListScreen.ps1"
    . "$PSScriptRoot/screens/ProjectInfoScreenV4.ps1"
    Write-PmcTuiLog "Initial screens loaded (4 screens - others lazy-loaded via MenuRegistry)" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load initial screens: $_" "ERROR"
    throw
}

Write-PmcTuiLog "All components loaded successfully" "INFO"

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
        # === Clear stale global state ===
        # CRITICAL FIX: Clear shared menu bar and registry singleton to ensure fresh menus are loaded
        # This fixes the issue where Notes and Checklist screens don't appear after manifest updates
        $global:PmcSharedMenuBar = $null

        # Clear MenuRegistry singleton (it caches menu items across sessions)
        if ([MenuRegistry]) {
            [MenuRegistry]::_instance = $null
        }
        Write-PmcTuiLog "Cleared stale PmcSharedMenuBar and MenuRegistry singleton" "INFO"

        # === Create DI Container ===
        Write-PmcTuiLog "Creating ServiceContainer..." "INFO"
        $global:PmcContainer = [ServiceContainer]::new()
        Write-PmcTuiLog "ServiceContainer created" "INFO"

        # === Register Core Services (in dependency order) ===

        # 1. Theme (no dependencies)
        Write-PmcTuiLog "Registering Theme service..." "INFO"
        $global:PmcContainer.Register('Theme', {
            param($container)
            Write-PmcTuiLog "Resolving Theme: Calling Initialize-PmcThemeSystem..." "INFO"
            Initialize-PmcThemeSystem
            $theme = Get-PmcState -Section 'Display' | Select-Object -ExpandProperty Theme
            Write-PmcTuiLog "Theme resolved: $($theme.Hex)" "INFO"

            # CRITICAL FIX: Initialize PmcThemeEngine with theme data from PMC palette
            Write-PmcTuiLog "Loading PmcThemeEngine..." "INFO"
            $engine = [PmcThemeEngine]::GetInstance()

            # Get PMC color palette (derived from theme hex)
            $palette = Get-PmcColorPalette

            # Convert RGB objects to hex strings for PmcThemeEngine
            $paletteHex = @{}
            foreach ($key in $palette.Keys) {
                $rgb = $palette[$key]
                $paletteHex[$key] = "#{0:X2}{1:X2}{2:X2}" -f $rgb.R, $rgb.G, $rgb.B
            }

            # Load theme config with palette
            $themeConfig = @{
                Palette = $paletteHex
            }
            $engine.LoadFromConfig($themeConfig)
            Write-PmcTuiLog "PmcThemeEngine initialized with PMC palette ($($paletteHex.Count) colors)" "INFO"

            return $theme
        }, $true)

        # Register ThemeManager (depends on Theme)
        Write-PmcTuiLog "Registering ThemeManager..." "INFO"
        $global:PmcContainer.Register('ThemeManager', {
            param($container)
            Write-PmcTuiLog "Resolving ThemeManager..." "INFO"
            $null = $container.Resolve('Theme')
            return [PmcThemeManager]::GetInstance()
        }, $true)

        # 2. Config (no dependencies) - CACHED for performance
        Write-PmcTuiLog "Registering Config service..." "INFO"
        $global:PmcContainer.Register('Config', {
            param($container)
            Write-PmcTuiLog "Resolving Config..." "INFO"

            # Determine config path (same logic as Get-PmcConfig)
            # CRITICAL FIX: Use workspace root (three levels up from module dir)
            $root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
            $configPath = Join-Path $root 'config.json'

            # Use cached config for performance (eliminates repeated file I/O)
            try {
                return [ConfigCache]::GetConfig($configPath)
            } catch {
                Write-PmcTuiLog "Config load failed, falling back to Get-PmcConfig: $_" "ERROR"
                # Fallback to original method if cache fails
                return Get-PmcConfig
            }
        }, $true)

        # 3. TaskStore (depends on Theme via state)
        Write-PmcTuiLog "Registering TaskStore service..." "INFO"
        $global:PmcContainer.Register('TaskStore', {
            param($container)
            Write-PmcTuiLog "Resolving TaskStore..." "INFO"
            # Ensure theme is initialized first
            $null = $container.Resolve('Theme')
            return [TaskStore]::GetInstance()
        }, $true)

        # 4. MenuRegistry (depends on Theme)
        Write-PmcTuiLog "Registering MenuRegistry service..." "INFO"
        $global:PmcContainer.Register('MenuRegistry', {
            param($container)
            Write-PmcTuiLog "Resolving MenuRegistry..." "INFO"
            # Ensure theme is initialized first
            $null = $container.Resolve('Theme')
            return [MenuRegistry]::new()
        }, $true)

        # 5. Application (depends on Theme)
        Write-PmcTuiLog "Registering Application service..." "INFO"
        $global:PmcContainer.Register('Application', {
            param($container)
            Write-PmcTuiLog "Resolving Application..." "INFO"
            # Ensure theme is initialized first
            $null = $container.Resolve('Theme')
            return [PmcApplication]::new($container)
        }, $true)

        # 6. CommandService (no dependencies)
        Write-PmcTuiLog "Registering CommandService..." "INFO"
        $global:PmcContainer.Register('CommandService', {
            param($container)
            Write-PmcTuiLog "Resolving CommandService..." "INFO"
            return [CommandService]::GetInstance()
        }, $true)

        # 7. ChecklistService (no dependencies)
        Write-PmcTuiLog "Registering ChecklistService..." "INFO"
        $global:PmcContainer.Register('ChecklistService', {
            param($container)
            Write-PmcTuiLog "Resolving ChecklistService..." "INFO"
            return [ChecklistService]::GetInstance()
        }, $true)

        # 8. NoteService (no dependencies)
        Write-PmcTuiLog "Registering NoteService..." "INFO"
        $global:PmcContainer.Register('NoteService', {
            param($container)
            Write-PmcTuiLog "Resolving NoteService..." "INFO"
            return [NoteService]::GetInstance()
        }, $true)

        # 9. ExcelMappingService (no dependencies)
        Write-PmcTuiLog "Registering ExcelMappingService..." "INFO"
        $global:PmcContainer.Register('ExcelMappingService', {
            param($container)
            Write-PmcTuiLog "Resolving ExcelMappingService..." "INFO"
            return [ExcelMappingService]::GetInstance()
        }, $true)

        # 10. PreferencesService (no dependencies)
        Write-PmcTuiLog "Registering PreferencesService..." "INFO"
        $global:PmcContainer.Register('PreferencesService', {
            param($container)
            Write-PmcTuiLog "Resolving PreferencesService..." "INFO"
            return [PreferencesService]::GetInstance()
        }, $true)

        # 11. Screen factories (depend on Application, TaskStore, etc.)
        Write-PmcTuiLog "Registering screen factories..." "INFO"

        $global:PmcContainer.Register('TaskListScreen', {
            param($container)
            Write-PmcTuiLog "Resolving TaskListScreen..." "INFO"
            # Ensure dependencies
            $null = $container.Resolve('Theme')
            $null = $container.Resolve('TaskStore')
            return [TaskListScreen]::new($container)
        }, $false)  # Not singleton - create new instance each time

        # === Resolve Application ===
        Write-PmcTuiLog "Resolving Application from container..." "INFO"
        $global:PmcApp = $global:PmcContainer.Resolve('Application')
        Write-PmcTuiLog "Application resolved and assigned to `$global:PmcApp" "INFO"

        # === Load Menus from Manifest ===
        Write-PmcTuiLog "Loading menus from manifest..." "INFO"
        $menuRegistry = $global:PmcContainer.Resolve('MenuRegistry')
        $manifestPath = Join-Path $PSScriptRoot "screens/MenuItems.psd1"
        if (Test-Path $manifestPath) {
            $menuRegistry.LoadFromManifest($manifestPath, $global:PmcContainer)
            Write-PmcTuiLog "Menus loaded from $manifestPath" "INFO"
        } else {
            Write-PmcTuiLog "Menu manifest not found at $manifestPath" "ERROR"
        }

        # === Launch Initial Screen ===
        Write-PmcTuiLog "Launching screen: $StartScreen" "INFO"
        switch ($StartScreen) {
            'TaskList' {
                Write-PmcTuiLog "Resolving TaskListScreen from container..." "INFO"
                $screen = $global:PmcContainer.Resolve('TaskListScreen')
                Write-PmcTuiLog "Pushing screen to app..." "INFO"
                $global:PmcApp.PushScreen($screen)
                Write-PmcTuiLog "Screen pushed successfully" "INFO"
            }
            'BlockedTasks' {
                Write-PmcTuiLog "Creating BlockedTasksScreen with container..." "INFO"
                $screen = [BlockedTasksScreen]::new($global:PmcContainer)
                Write-PmcTuiLog "Pushing screen to app..." "INFO"
                $global:PmcApp.PushScreen($screen)
                Write-PmcTuiLog "Screen pushed successfully" "INFO"
            }
            'Demo' {
                Write-PmcTuiLog "Loading DemoScreen (not containerized)..." "INFO"
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