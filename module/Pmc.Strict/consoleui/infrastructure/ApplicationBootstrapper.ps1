# ApplicationBootstrapper.ps1 - Bootstrap Entire PMC TUI Application
#
# Provides centralized application initialization with:
# - Load SpeedTUI framework
# - Load PMC module
# - Load all dependencies (helpers, infrastructure, widgets, base classes)
# - Initialize TaskStore
# - Initialize NavigationManager
# - Initialize KeyboardManager
# - Register all screens
# - Configure global shortcuts
# - Return configured application instance ready to run
#
# Usage:
#   . "$PSScriptRoot/infrastructure/ApplicationBootstrapper.ps1"
#   $app = Start-PmcApplication -StartScreen 'TaskList'
#   # Application is now running

using namespace System
using namespace System.IO

<#
.SYNOPSIS
Application bootstrap configuration

.DESCRIPTION
Contains configuration for application startup
#>
class BootstrapConfig {
    [string]$StartScreen = 'TaskList'
    [bool]$LoadSampleData = $false
    [bool]$EnableDebugLogging = $false
    [string]$ThemeName = 'default'
    [hashtable]$CustomSettings = @{}

    BootstrapConfig() {}

    BootstrapConfig([string]$startScreen) {
        $this.StartScreen = $startScreen
    }
}

<#
.SYNOPSIS
Bootstrap the PMC TUI application

.DESCRIPTION
Loads all dependencies and initializes the application in the correct order:
1. SpeedTUI framework
2. PMC module
3. Helper functions
4. Infrastructure components
5. Base classes
6. Widgets
7. Screens
8. Services (TaskStore, etc.)
9. Managers (Navigation, Keyboard)
10. Global shortcuts
11. Screen registrations

.PARAMETER StartScreen
Name of the screen to show on startup (default: TaskList)

.PARAMETER LoadSampleData
Whether to load sample data for testing (default: false)

.PARAMETER Config
Optional BootstrapConfig object for advanced configuration

.OUTPUTS
Configured PmcApplication instance ready to run

.EXAMPLE
$app = Start-PmcApplication -StartScreen 'TaskList'

.EXAMPLE
$config = [BootstrapConfig]::new()
$config.StartScreen = 'Dashboard'
$config.EnableDebugLogging = $true
$app = Start-PmcApplication -Config $config
#>
function Start-PmcApplication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$StartScreen = 'TaskList',

        [Parameter(Mandatory=$false)]
        [bool]$LoadSampleData = $false,

        [Parameter(Mandatory=$false)]
        [BootstrapConfig]$Config = $null
    )

    # Use config if provided, otherwise create from parameters
    if ($null -eq $Config) {
        $Config = [BootstrapConfig]::new($StartScreen)
        $Config.LoadSampleData = $LoadSampleData
    }

    Write-Host "Bootstrapping PMC TUI Application..." -ForegroundColor Cyan

    # === Step 1: Determine base path ===
    $scriptPath = $PSScriptRoot
    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        $scriptPath = Get-Location
    }

    # Navigate up from infrastructure/ to consoleui/
    $basePath = Split-Path -Parent $scriptPath
    Write-Verbose "Base path: $basePath"

    # === Step 2: Load SpeedTUI Framework ===
    Write-Host "  [1/12] Loading SpeedTUI framework..." -ForegroundColor Gray
    $speedTUILoader = Join-Path $basePath "SpeedTUILoader.ps1"
    if (Test-Path $speedTUILoader) {
        . $speedTUILoader
        Write-Verbose "    SpeedTUI loaded"
    } else {
        throw "SpeedTUI loader not found at: $speedTUILoader"
    }

    # === Step 3: Load PMC Module ===
    Write-Host "  [2/12] Loading PMC module..." -ForegroundColor Gray
    if (-not (Get-Module -Name Pmc.Strict -ErrorAction SilentlyContinue)) {
        # Attempt to import module (adjust path as needed)
        $pmcModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $basePath)) "Pmc.Strict.psd1"
        if (Test-Path $pmcModulePath) {
            Import-Module $pmcModulePath -Force -ErrorAction Stop
            Write-Verbose "    PMC module loaded"
        } else {
            Write-Warning "    PMC module not found at $pmcModulePath, assuming already loaded"
        }
    } else {
        Write-Verbose "    PMC module already loaded"
    }

    # === Step 4: Load Dependencies ===
    Write-Host "  [3/12] Loading dependencies..." -ForegroundColor Gray
    $depsPath = Join-Path $basePath "deps"
    if (Test-Path $depsPath) {
        Get-ChildItem -Path $depsPath -Filter "*.ps1" | ForEach-Object {
            . $_.FullName
            Write-Verbose "    Loaded: $($_.Name)"
        }
    }

    # === Step 5: Load Helpers ===
    Write-Host "  [4/12] Loading helper functions..." -ForegroundColor Gray
    $helpersPath = Join-Path $basePath "helpers"
    if (Test-Path $helpersPath) {
        Get-ChildItem -Path $helpersPath -Filter "*.ps1" | ForEach-Object {
            . $_.FullName
            Write-Verbose "    Loaded: $($_.Name)"
        }
    }

    # === Step 6: Load Theme ===
    Write-Host "  [5/12] Loading theme system..." -ForegroundColor Gray
    $themePath = Join-Path $basePath "theme"
    if (Test-Path $themePath) {
        Get-ChildItem -Path $themePath -Filter "*.ps1" | ForEach-Object {
            . $_.FullName
            Write-Verbose "    Loaded: $($_.Name)"
        }
    }

    # === Step 7: Load Layout ===
    Write-Host "  [6/12] Loading layout system..." -ForegroundColor Gray
    $layoutPath = Join-Path $basePath "layout"
    if (Test-Path $layoutPath) {
        Get-ChildItem -Path $layoutPath -Filter "*.ps1" | ForEach-Object {
            . $_.FullName
            Write-Verbose "    Loaded: $($_.Name)"
        }
    }

    # === Step 8: Load Widgets ===
    Write-Host "  [7/12] Loading widget system..." -ForegroundColor Gray
    $widgetsPath = Join-Path $basePath "widgets"
    if (Test-Path $widgetsPath) {
        # Load base widget first
        $baseWidget = Join-Path $widgetsPath "PmcWidget.ps1"
        if (Test-Path $baseWidget) {
            . $baseWidget
            Write-Verbose "    Loaded: PmcWidget.ps1"
        }

        # Load other widgets
        Get-ChildItem -Path $widgetsPath -Filter "*.ps1" -Exclude "PmcWidget.ps1" | ForEach-Object {
            . $_.FullName
            Write-Verbose "    Loaded: $($_.Name)"
        }
    }

    # === Step 9: Load Base Classes ===
    Write-Host "  [8/12] Loading base screen classes..." -ForegroundColor Gray
    $basePath_screens = Join-Path $basePath "base"
    if (Test-Path $basePath_screens) {
        Get-ChildItem -Path $basePath_screens -Filter "*.ps1" | ForEach-Object {
            . $_.FullName
            Write-Verbose "    Loaded: $($_.Name)"
        }
    }

    # === Step 10: Load Infrastructure (except this file) ===
    Write-Host "  [9/12] Loading infrastructure components..." -ForegroundColor Gray
    $infraPath = Join-Path $basePath "infrastructure"
    if (Test-Path $infraPath) {
        Get-ChildItem -Path $infraPath -Filter "*.ps1" -Exclude "ApplicationBootstrapper.ps1" | ForEach-Object {
            . $_.FullName
            Write-Verbose "    Loaded: $($_.Name)"
        }
    }

    # === Step 11: Load Services ===
    Write-Host "  [10/12] Loading services..." -ForegroundColor Gray
    $servicesPath = Join-Path $basePath "services"
    if (Test-Path $servicesPath) {
        Get-ChildItem -Path $servicesPath -Filter "*.ps1" | ForEach-Object {
            . $_.FullName
            Write-Verbose "    Loaded: $($_.Name)"
        }
    }

    # === Step 12: Load Screens ===
    Write-Host "  [11/12] Loading screen implementations..." -ForegroundColor Gray
    $screensPath = Join-Path $basePath "screens"
    if (Test-Path $screensPath) {
        Get-ChildItem -Path $screensPath -Filter "*.ps1" -Recurse | ForEach-Object {
            . $_.FullName
            Write-Verbose "    Loaded: $($_.Name)"
        }
    }

    # === Step 13: Initialize Core Services ===
    Write-Host "  [12/12] Initializing application..." -ForegroundColor Gray

    # Initialize TaskStore
    Write-Verbose "    Initializing TaskStore..."
    $taskStore = [TaskStore]::GetInstance()

    # Load sample data if requested
    if ($Config.LoadSampleData) {
        Write-Verbose "    Loading sample data..."
        # TODO: Implement sample data loading
    }

    # Initialize PmcApplication
    Write-Verbose "    Creating PmcApplication..."
    $pmcAppPath = Join-Path $basePath "PmcApplication.ps1"
    if (Test-Path $pmcAppPath) {
        . $pmcAppPath
    }
    $app = [PmcApplication]::new()

    # Initialize NavigationManager
    Write-Verbose "    Initializing NavigationManager..."
    $navManager = [NavigationManager]::new($app)

    # Initialize KeyboardManager
    Write-Verbose "    Initializing KeyboardManager..."
    $keyManager = [KeyboardManager]::new()

    # === Step 14: Register Screens ===
    Write-Verbose "    Registering screens..."

    # Register screens (you'll add your actual screen classes here)
    # Example:
    # [ScreenRegistry]::Register('TaskList', [TaskListScreen], 'Tasks', 'View and manage tasks')
    # [ScreenRegistry]::Register('TaskDetail', [TaskDetailScreen], 'Tasks', 'View task details')
    # [ScreenRegistry]::Register('AddTask', [AddTaskScreen], 'Tasks', 'Add new task')
    # [ScreenRegistry]::Register('ProjectList', [ProjectListScreen], 'Projects', 'View projects')
    # [ScreenRegistry]::Register('Dashboard', [DashboardScreen], 'Other', 'Dashboard overview')

    # === Step 15: Register Global Shortcuts ===
    Write-Verbose "    Registering global shortcuts..."

    # Quit application (Ctrl+Q)
    $keyManager.RegisterGlobal(
        [ConsoleKey]::Q,
        [ConsoleModifiers]::Control,
        { $app.Stop() },
        "Quit application"
    )

    # Go back (Escape)
    $keyManager.RegisterGlobal(
        [ConsoleKey]::Escape,
        [ConsoleModifiers]::None,
        { $navManager.GoBack() },
        "Go back to previous screen"
    )

    # Show help (F1)
    $keyManager.RegisterGlobal(
        [ConsoleKey]::F1,
        [ConsoleModifiers]::None,
        {
            $helpText = $keyManager.GetHelpText($navManager.CurrentScreen)
            Write-Host $helpText
            [Console]::ReadKey($true) | Out-Null
        },
        "Show keyboard shortcuts"
    )

    # === Step 16: Store references in application ===
    # Add custom properties to app for easy access
    Add-Member -InputObject $app -MemberType NoteProperty -Name "TaskStore" -Value $taskStore -Force
    Add-Member -InputObject $app -MemberType NoteProperty -Name "Navigation" -Value $navManager -Force
    Add-Member -InputObject $app -MemberType NoteProperty -Name "Keyboard" -Value $keyManager -Force

    # === Step 17: Navigate to start screen ===
    Write-Verbose "    Navigating to start screen: $($Config.StartScreen)"
    if ([ScreenRegistry]::IsRegistered($Config.StartScreen)) {
        $navManager.NavigateTo($Config.StartScreen)
    } else {
        Write-Warning "Start screen '$($Config.StartScreen)' is not registered"
    }

    Write-Host "Application bootstrap complete!" -ForegroundColor Green
    Write-Host ""

    return $app
}

<#
.SYNOPSIS
Get bootstrap diagnostics

.DESCRIPTION
Returns information about the bootstrap process and loaded components

.OUTPUTS
Hashtable with diagnostic information

.EXAMPLE
$diagnostics = Get-BootstrapDiagnostics
$diagnostics | Format-Table
#>
function Get-BootstrapDiagnostics {
    $diag = @{
        speedTUILoaded = $null -ne (Get-Command "New-Object" -ErrorAction SilentlyContinue)
        pmcModuleLoaded = $null -ne (Get-Module -Name Pmc.Strict -ErrorAction SilentlyContinue)
        taskStoreInitialized = $null -ne [TaskStore]::GetInstance()
        registeredScreens = [ScreenRegistry]::GetInstance().ScreenCount
        screenCategories = [ScreenRegistry]::GetCategories()
        timestamp = Get-Date
    }

    return $diag
}

Export-ModuleMember -Function Start-PmcApplication, Get-BootstrapDiagnostics
