Set-StrictMode -Version Latest

class PmcTimerService {
    hidden $_state
    PmcTimerService([object]$stateManager) { $this._state = $stateManager }

    [void] Start() {
        Set-PmcState -Section 'Time' -Key 'TimerStart' -Value (Get-Date).ToString('o')
        Set-PmcState -Section 'Time' -Key 'TimerRunning' -Value $true
    }

    [pscustomobject] Stop() {
        $startStr = Get-PmcState -Section 'Time' -Key 'TimerStart'
        $running = Get-PmcState -Section 'Time' -Key 'TimerRunning'
        if (-not $running -or -not $startStr) { return [pscustomobject]@{ Running=$false; Elapsed=0 } }
        $start = [datetime]$startStr
        $elapsed = ([datetime]::Now - $start).TotalHours
        Set-PmcState -Section 'Time' -Key 'TimerRunning' -Value $false
        return [pscustomobject]@{ Running=$false; Elapsed=[Math]::Round($elapsed,2) }
    }

    [pscustomobject] Status() {
        $startStr = Get-PmcState -Section 'Time' -Key 'TimerStart'
        $running = Get-PmcState -Section 'Time' -Key 'TimerRunning'
        $elapsed = 0
        if ($running -and $startStr) { $elapsed = ([datetime]::Now - [datetime]$startStr).TotalHours }
        return [pscustomobject]@{ Running=($running -eq $true); Started=$startStr; Elapsed=[Math]::Round($elapsed,2) }
    }
}

function New-PmcTimerService { param($StateManager) return [PmcTimerService]::new($StateManager) }

function Start-PmcTimer { $svc = Get-PmcService -Name 'TimerService'; if (-not $svc) { throw 'TimerService not available' }; $svc.Start(); Write-PmcStyled -Style 'Success' -Text '⏱ Timer started' }
function Stop-PmcTimer { $svc = Get-PmcService -Name 'TimerService'; if (-not $svc) { throw 'TimerService not available' }; $r=$svc.Stop(); Write-PmcStyled -Style 'Success' -Text ("⏹ Timer stopped ({0}h)" -f $r.Elapsed); return $r }
function Get-PmcTimerStatus { $svc = Get-PmcService -Name 'TimerService'; if (-not $svc) { throw 'TimerService not available' }; return $svc.Status() }

Export-ModuleMember -Function Start-PmcTimer, Stop-PmcTimer, Get-PmcTimerStatus, New-PmcTimerService

