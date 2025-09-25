Set-StrictMode -Version Latest

class PmcHandlerDescriptor {
    [string] $Domain
    [string] $Action
    [scriptblock] $Validate
    [scriptblock] $Execute
    PmcHandlerDescriptor([string]$d,[string]$a,[scriptblock]$v,[scriptblock]$e){ $this.Domain=$d; $this.Action=$a; $this.Validate=$v; $this.Execute=$e }
}

$Script:PmcHandlers = @{}

function Register-PmcHandler {
    param([Parameter(Mandatory=$true)][string]$Domain,[Parameter(Mandatory=$true)][string]$Action,[Parameter(Mandatory=$true)][scriptblock]$Execute,[scriptblock]$Validate)
    $key = ("{0}:{1}" -f $Domain.ToLower(), $Action.ToLower())
    $Script:PmcHandlers[$key] = [PmcHandlerDescriptor]::new($Domain,$Action,$Validate,$Execute)
}

function Get-PmcHandler {
    param([string]$Domain,[string]$Action)
    $key = ("{0}:{1}" -f $Domain.ToLower(), $Action.ToLower())
    if ($Script:PmcHandlers.ContainsKey($key)) { return $Script:PmcHandlers[$key] }
    return $null
}

function Initialize-PmcHandlers {
    # Auto-register all domain/action functions from CommandMap as handlers
    try {
        if ($Script:PmcCommandMap) {
            foreach ($domain in $Script:PmcCommandMap.Keys) {
                foreach ($action in $Script:PmcCommandMap[$domain].Keys) {
                    $fnName = [string]$Script:PmcCommandMap[$domain][$action]
                    $d = $domain; $a = $action; $f = $fnName
                    # Build an execute block that prefers services for key domains
                    $exec = {
                        param([PmcCommandContext]$Context)
                        try {
                            $domainLower = "$d".ToLower()
                            if ($domainLower -eq 'task') {
                                $svc = $null; try { $svc = Get-PmcService -Name 'TaskService' } catch {}
                                if ($svc) {
                                    switch ("$a".ToLower()) {
                                        'add' { return (Add-PmcTask -Context $Context) }
                                        'list' { return (Get-PmcTaskList) }
                                    }
                                }
                            }
                            elseif ($domainLower -eq 'project') {
                                $psvc = $null; try { $psvc = Get-PmcService -Name 'ProjectService' } catch {}
                                if ($psvc) {
                                    switch ("$a".ToLower()) {
                                        'add' { return (Add-PmcProject -Context $Context) }
                                        'list' { return (Get-PmcProjectList) }
                                    }
                                }
                            }
                            elseif ($domainLower -eq 'time') {
                                $tsvc = $null; try { $tsvc = Get-PmcService -Name 'TimeService' } catch {}
                                if ($tsvc) {
                                    switch ("$a".ToLower()) {
                                        'log' { return (Add-PmcTimeEntry -Context $Context) }
                                        'list' { return (Get-PmcTimeList) }
                                        'report' { return (Get-PmcTimeReport) }
                                    }
                                }
                            }
                            elseif ($domainLower -eq 'timer') {
                                $timersvc = $null; try { $timersvc = Get-PmcService -Name 'TimerService' } catch {}
                                if ($timersvc) {
                                    switch ("$a".ToLower()) {
                                        'start' { return (Start-PmcTimer) }
                                        'stop' { return (Stop-PmcTimer) }
                                        'status' { return (Get-PmcTimerStatus) }
                                    }
                                }
                            }
                            elseif ($domainLower -eq 'focus') {
                                $fsvc = $null; try { $fsvc = Get-PmcService -Name 'FocusService' } catch {}
                                if ($fsvc) {
                                    switch ("$a".ToLower()) {
                                        'set' { return (Set-PmcFocus -Context $Context) }
                                        'clear' { return (Clear-PmcFocus) }
                                        'status' { return (Get-PmcFocusStatus) }
                                    }
                                }
                            }

                            if (Get-Command -Name $f -ErrorAction SilentlyContinue) { & $f -Context $Context }
                            else { Write-PmcStyled -Style 'Warning' -Text ("Handler not implemented: {0} {1}" -f $d,$a) }
                        } catch { Write-PmcStyled -Style 'Error' -Text (("{0} {1} failed: {2}" -f $d,$a,$_)) }
                    }
                    Register-PmcHandler -Domain $d -Action $a -Execute $exec
                }
            }
        }
    } catch { Write-PmcDebug -Level 1 -Category 'Handlers' -Message "Auto-registration failed: $_" }
}

Export-ModuleMember -Function Register-PmcHandler, Get-PmcHandler, Initialize-PmcHandlers
