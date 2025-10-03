Set-StrictMode -Version Latest

# =====================================================================================
# REFERENCE ONLY - FUTURE ARCHITECTURE
# =====================================================================================
# Service-oriented architecture pattern - currently DISABLED.
# =====================================================================================

class PmcFocusService {
    hidden $_state
    PmcFocusService([object]$stateManager) { $this._state = $stateManager }

    [string] SetFocus([string]$Project) {
        Set-PmcState -Section 'Focus' -Key 'Project' -Value $Project
        return $Project
    }

    [void] ClearFocus() { Set-PmcState -Section 'Focus' -Key 'Project' -Value $null }

    [pscustomobject] GetStatus() {
        $p = Get-PmcState -Section 'Focus' -Key 'Project'
        return [pscustomobject]@{ Project=$p; Active=([string]::IsNullOrWhiteSpace($p) -eq $false) }
    }
}

function New-PmcFocusService { param($StateManager) return [PmcFocusService]::new($StateManager) }

function Set-PmcFocus { param([PmcCommandContext]$Context)
    $svc = Get-PmcService -Name 'FocusService'; if (-not $svc) { throw 'FocusService not available' }
    $p = if (@($Context.FreeText).Count -gt 0) { ($Context.FreeText -join ' ') } else { [string]$Context.Args['project'] }
    $v = $svc.SetFocus($p)
    Write-PmcStyled -Style 'Success' -Text ("🎯 Focus set: {0}" -f $v)
    return $v
}

function Clear-PmcFocus { $svc = Get-PmcService -Name 'FocusService'; if (-not $svc) { throw 'FocusService not available' }; $svc.ClearFocus(); Write-PmcStyled -Style 'Warning' -Text '🎯 Focus cleared' }
function Get-PmcFocusStatus { $svc = Get-PmcService -Name 'FocusService'; if (-not $svc) { throw 'FocusService not available' }; return $svc.GetStatus() }

Export-ModuleMember -Function Set-PmcFocus, Clear-PmcFocus, Get-PmcFocusStatus, New-PmcFocusService

