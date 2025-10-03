Set-StrictMode -Version Latest

# =====================================================================================
# REFERENCE ONLY - FUTURE ARCHITECTURE
# =====================================================================================
# Service Registry pattern for dependency injection and modular architecture.
# Currently DISABLED to avoid conflicts with current UniversalDisplay.ps1 system.
# Keep for reference and potential future migration.
# =====================================================================================

$Script:PmcServices = @{}

function Register-PmcService {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][object]$Instance
    )
    $Script:PmcServices[$Name] = $Instance
}

function Get-PmcService {
    param([Parameter(Mandatory=$true)][string]$Name)
    if ($Script:PmcServices.ContainsKey($Name)) { return $Script:PmcServices[$Name] }
    return $null
}

function Initialize-PmcServices {
    # Create core services and register them
    try {
        # TaskService
        if (Get-Command -Name Get-PmcSecureFileManager -ErrorAction SilentlyContinue) {
            $state = $Script:SecureStateManager
            $logger = $null
            if (Test-Path "$PSScriptRoot/TaskService.ps1") { . "$PSScriptRoot/TaskService.ps1" }
            if (Get-Command -Name New-PmcTaskService -ErrorAction SilentlyContinue) {
                $svc = New-PmcTaskService -StateManager $state -Logger $logger
                Register-PmcService -Name 'TaskService' -Instance $svc
            }
        }
    } catch {
        Write-PmcDebug -Level 1 -Category 'ServiceRegistry' -Message "TaskService initialization failed: $_"
    }

    try { # ProjectService
        $state = $Script:SecureStateManager; $logger = $null
        if (Test-Path "$PSScriptRoot/ProjectService.ps1") { . "$PSScriptRoot/ProjectService.ps1" }
        if (Get-Command -Name New-PmcProjectService -ErrorAction SilentlyContinue) { Register-PmcService -Name 'ProjectService' -Instance (New-PmcProjectService -StateManager $state -Logger $logger) }
    } catch { Write-PmcDebug -Level 1 -Category 'ServiceRegistry' -Message "ProjectService initialization failed: $_" }

    try { # TimeService
        $state = $Script:SecureStateManager; $logger = $null
        if (Test-Path "$PSScriptRoot/TimeService.ps1") { . "$PSScriptRoot/TimeService.ps1" }
        if (Get-Command -Name New-PmcTimeService -ErrorAction SilentlyContinue) { Register-PmcService -Name 'TimeService' -Instance (New-PmcTimeService -StateManager $state -Logger $logger) }
    } catch { Write-PmcDebug -Level 1 -Category 'ServiceRegistry' -Message "TimeService initialization failed: $_" }

    try { # TimerService
        $state = $Script:SecureStateManager
        if (Test-Path "$PSScriptRoot/TimerService.ps1") { . "$PSScriptRoot/TimerService.ps1" }
        if (Get-Command -Name New-PmcTimerService -ErrorAction SilentlyContinue) { Register-PmcService -Name 'TimerService' -Instance (New-PmcTimerService -StateManager $state) }
    } catch { Write-PmcDebug -Level 1 -Category 'ServiceRegistry' -Message "TimerService initialization failed: $_" }

    try { # FocusService
        $state = $Script:SecureStateManager
        if (Test-Path "$PSScriptRoot/FocusService.ps1") { . "$PSScriptRoot/FocusService.ps1" }
        if (Get-Command -Name New-PmcFocusService -ErrorAction SilentlyContinue) { Register-PmcService -Name 'FocusService' -Instance (New-PmcFocusService -StateManager $state) }
    } catch { Write-PmcDebug -Level 1 -Category 'ServiceRegistry' -Message "FocusService initialization failed: $_" }
}

Export-ModuleMember -Function Register-PmcService, Get-PmcService, Initialize-PmcServices
