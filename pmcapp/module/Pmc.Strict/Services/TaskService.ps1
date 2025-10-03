Set-StrictMode -Version Latest

# =====================================================================================
# REFERENCE ONLY - FUTURE ARCHITECTURE
# =====================================================================================
# Service-oriented architecture pattern - currently DISABLED.
# =====================================================================================

class PmcTaskService {
    hidden $_state
    hidden $_logger

    PmcTaskService([object]$stateManager, [object]$logger) {
        $this._state = $stateManager
        $this._logger = $logger
    }

    [pscustomobject] AddTask([string]$Text, [string]$Project, [string]$Priority, [string]$Due, [string[]]$Tags) {
        $data = Get-PmcData
        if (-not $data.tasks) { $data.tasks = @() }

        $new = [pscustomobject]@{
            id       = $this.GetNextId($data)
            text     = $Text
            project  = $Project
            priority = if ($Priority) { $Priority } else { 'p2' }
            due      = $Due
            tags     = if ($Tags) { $Tags } else { @() }
            status   = 'pending'
            created  = (Get-Date).ToString('o')
        }

        $data.tasks += $new
        Save-PmcData $data
        return $new
    }

    [object[]] GetTasks() {
        $data = Get-PmcData
        return ,@($data.tasks)
    }

    hidden [int] GetNextId($data) {
        try {
            $ids = @($data.tasks | ForEach-Object { try { [int]$_.id } catch { 0 } })
            $max = ($ids | Measure-Object -Maximum).Maximum
            return ([int]$max + 1)
        } catch { return 1 }
    }
}

function New-PmcTaskService { param($StateManager,$Logger) return [PmcTaskService]::new($StateManager,$Logger) }

# Public function wrappers (compat with CommandMap)
function Add-PmcTask {
    param([PmcCommandContext]$Context)
    $svc = Get-PmcService -Name 'TaskService'
    if (-not $svc) { throw 'TaskService not available' }
    $text = ($Context.FreeText -join ' ').Trim()
    $proj = if ($Context.Args.ContainsKey('project')) { [string]$Context.Args['project'] } else { $null }
    $prio = if ($Context.Args.ContainsKey('priority')) { [string]$Context.Args['priority'] } else { $null }
    $due  = if ($Context.Args.ContainsKey('due')) { [string]$Context.Args['due'] } else { $null }
    $tags = if ($Context.Args.ContainsKey('tags')) { @($Context.Args['tags']) } else { @() }
    $res = $svc.AddTask($text,$proj,$prio,$due,$tags)
    Write-PmcStyled -Style 'Success' -Text ("✓ Task added: [{0}] {1}" -f $res.id,$res.text)
    return $res
}

function Get-PmcTaskList {
    $svc = Get-PmcService -Name 'TaskService'
    if (-not $svc) { throw 'TaskService not available' }
    return $svc.GetTasks()
}

Export-ModuleMember -Function Add-PmcTask, Get-PmcTaskList, New-PmcTaskService

