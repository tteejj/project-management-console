Set-StrictMode -Version Latest

# =====================================================================================
# REFERENCE ONLY - FUTURE ARCHITECTURE
# =====================================================================================
# Service-oriented architecture pattern - currently DISABLED.
# =====================================================================================

class PmcTimeService {
    hidden $_state
    hidden $_logger

    PmcTimeService([object]$stateManager, [object]$logger) {
        $this._state = $stateManager
        $this._logger = $logger
    }

    [pscustomobject] AddTimeEntry([int]$TaskId, [string]$Project, [string]$Duration, [string]$Description) {
        $data = Get-PmcData
        if (-not $data.timelogs) { $data.timelogs = @() }

        $hours = 0.0
        if ($Duration) {
            if ($Duration -match '^(\d+(?:\.\d+)?)h$') { $hours = [double]$matches[1] }
            elseif ($Duration -match '^(\d+)m$') { $hours = [double]$matches[1] / 60.0 }
            elseif ($Duration -match '^(\d+)h(\d+)m$') { $hours = [double]$matches[1] + ([double]$matches[2]/60.0) }
            elseif ($Duration -match '^\d+(?:\.\d+)?$') { $hours = [double]$Duration }
        }

        $entry = [pscustomobject]@{
            id = $this.GetNextId($data)
            task = $TaskId
            project = $Project
            start = (Get-Date).ToString('o')
            end = (Get-Date).ToString('o')
            duration = $hours
            description = $Description
        }
        $data.timelogs += $entry
        Save-PmcData $data
        return $entry
    }

    [object[]] GetTimeList() { $data = Get-PmcData; return ,@($data.timelogs) }

    [pscustomobject] GetReport([datetime]$From,[datetime]$To) {
        $items = $this.GetTimeList() | Where-Object { try { $d=[datetime]$_.start; $d -ge $From -and $d -le $To } catch { $false } }
        $total = ($items | Measure-Object duration -Sum).Sum
        return [pscustomobject]@{ From=$From; To=$To; Hours=$total; Entries=$items }
    }

    hidden [int] GetNextId($data) {
        try { $ids = @($data.timelogs | ForEach-Object { try { [int]$_.id } catch { 0 } }); $max = ($ids | Measure-Object -Maximum).Maximum; return ([int]$max + 1) } catch { return 1 }
    }
}

function New-PmcTimeService { param($StateManager,$Logger) return [PmcTimeService]::new($StateManager,$Logger) }

function Add-PmcTimeEntry { param([PmcCommandContext]$Context)
    $svc = Get-PmcService -Name 'TimeService'; if (-not $svc) { throw 'TimeService not available' }
    $taskId = 0; if ($Context.Args.ContainsKey('task')) { $taskId = [int]$Context.Args['task'] } elseif (@($Context.FreeText).Count -gt 0 -and $Context.FreeText[0] -match '^\d+$') { $taskId = [int]$Context.FreeText[0] }
    $proj = if ($Context.Args.ContainsKey('project')) { [string]$Context.Args['project'] } else { $null }
    $dur  = if ($Context.Args.ContainsKey('duration')) { [string]$Context.Args['duration'] } else { $null }
    $desc = if (@($Context.FreeText).Count -gt 1) { ($Context.FreeText | Select-Object -Skip 1) -join ' ' } else { '' }
    $res = $svc.AddTimeEntry($taskId,$proj,$dur,$desc)
    Write-PmcStyled -Style 'Success' -Text ("✓ Time logged: {0}h on task {1}" -f $res.duration,$res.task)
    return $res
}

function Get-PmcTimeList { $svc = Get-PmcService -Name 'TimeService'; if (-not $svc) { throw 'TimeService not available' }; return $svc.GetTimeList() }

function Get-PmcTimeReport {
    param([datetime]$From=(Get-Date).Date.AddDays(-7), [datetime]$To=(Get-Date))
    $svc = Get-PmcService -Name 'TimeService'; if (-not $svc) { throw 'TimeService not available' }
    return $svc.GetReport($From,$To)
}

Export-ModuleMember -Function Add-PmcTimeEntry, Get-PmcTimeList, Get-PmcTimeReport, New-PmcTimeService

