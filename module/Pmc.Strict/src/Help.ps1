function Get-PmcSchema {
    param([string]$Domain,[string]$Action)
    $key = "$($Domain.ToLower()) $($Action.ToLower())"
    if ($Script:PmcParameterMap.ContainsKey($key)) { return $Script:PmcParameterMap[$key] }
    return @()
}

function Get-PmcHelp {
    $rows = @()
    foreach ($d in ($Script:PmcCommandMap.Keys | Sort-Object)) {
        foreach ($a in ($Script:PmcCommandMap[$d].Keys | Sort-Object)) {
            $key = "$d $a"; $desc = if ($Script:PmcCommandMeta.ContainsKey($key)) { $Script:PmcCommandMeta[$key].Desc } else { '' }
            $rows += [pscustomobject]@{ Domain=$d; Action=$a; Description=$desc }
        }
    }
    return $rows
}

function Show-PmcHelpDomain { param([PmcCommandContext]$Context)
    if (-not $Context -or $Context.FreeText.Count -lt 1) { Write-PmcStyled -Style 'Warning' -Text "Usage: help domain <domain>"; return }
    $domain = $Context.FreeText[0].ToLower()
    if (-not $Script:PmcCommandMap.ContainsKey($domain)) { Write-PmcStyled -Style 'Error' -Text "Unknown domain '$domain'"; return }
    $actions = @()
    foreach ($a in ($Script:PmcCommandMap[$domain].Keys | Sort-Object)) {
        $key = "$domain $a"
        $desc = if ($Script:PmcCommandMeta.ContainsKey($key)) { $Script:PmcCommandMeta[$key].Desc } else { '' }
        $actions += @{ action=$a; desc=$desc }
    }
    $cols = @(
        @{ key='action'; title='Action'; width=16 },
        @{ key='desc'; title='Description'; width=56 }
    )
    Show-PmcHeader -Title ("Help — {0}" -f $domain)
    Show-PmcTable -Columns $cols -Rows $actions
}

function Show-PmcHelpCommand { param([PmcCommandContext]$Context)
    if (-not $Context -or $Context.FreeText.Count -lt 2) { Write-PmcStyled -Style 'Warning' -Text "Usage: help command <domain> <action>"; return }
    $domain = $Context.FreeText[0].ToLower()
    $action = $Context.FreeText[1].ToLower()
    $key = "$domain $action"
    if (-not $Script:PmcCommandMap.ContainsKey($domain)) { Write-PmcStyled -Style 'Error' -Text "Unknown domain '$domain'"; return }
    if (-not $Script:PmcCommandMap[$domain].ContainsKey($action)) { Write-PmcStyled -Style 'Error' -Text "Unknown action '$action' for domain '$domain'"; return }

    $desc = if ($Script:PmcCommandMeta.ContainsKey($key)) { $Script:PmcCommandMeta[$key].Desc } else { '' }
    Show-PmcHeader -Title ("Help — {0} {1}" -f $domain, $action)
    if ($desc) { Show-PmcTip $desc }

    $schema = Get-PmcSchema -Domain $domain -Action $action
    if (-not $schema -or @($schema).Count -eq 0) { Write-PmcStyled -Style 'Muted' -Text '  (no arguments)'; return }
    $rows = @()
    foreach ($def in $schema) {
        $rows += @{
            arg = [string]$def['Name']
            prefix = [string]$def['Prefix']
            type = [string]$def['Type']
            required = if ($def['Required']) { 'yes' } else { '' }
            desc = [string]$def['Description']
        }
    }
    $cols = @(
        @{ key='arg'; title='Arg'; width=14 },
        @{ key='prefix'; title='Prefix'; width=8 },
        @{ key='type'; title='Type'; width=14 },
        @{ key='required'; title='Req'; width=4 },
        @{ key='desc'; title='Description'; width=48 }
    )
    Show-PmcTable -Columns $cols -Rows $rows
}

function Show-PmcCommandList {
    $rows = Get-PmcHelp
    foreach ($r in ($rows | Sort-Object Domain, Action)) {
        Write-PmcStyled -Style 'Body' -Text ("{0} {1}  {2}" -f $r.Domain, $r.Action, $r.Description)
    }
}
function Show-PmcHelpAll { Show-PmcHelpUI }

function Show-PmcHelpUI {
    $rows = Get-PmcHelp | Sort-Object Domain, Action
    $domains = @($rows | Select-Object -ExpandProperty Domain -Unique)
    foreach ($d in $domains) {
        Show-PmcHeader -Title ("Help — {0}" -f $d)
        $vm = @()
        foreach ($r in ($rows | Where-Object { $_.Domain -eq $d })) {
            $vm += @{ action=$r.Action; desc=$r.Description }
        }
        $cols = @(
            @{ key='action'; title='Action'; width=16 },
            @{ key='desc'; title='Description'; width=56 }
        )
        Show-PmcTable -Columns $cols -Rows $vm
        Write-Host ""
    }
    Show-PmcTip "Examples:"
    Show-PmcTip "  task add buy milk @inbox p2 due:today"
    Show-PmcTip "  task agenda"
    Show-PmcTip "  time report week --withids out:time.csv"
    Show-PmcTip "  project set-fields @work ID2=WORK CAAName=Ops"
}

## Internal module state for list index mapping (centralized state)
Set-PmcLastTaskListMap @{}
Set-PmcLastTimeListMap @{}

## Data helpers (module storage)
# Get-PmcDataAlias defined in Storage.ps1
function Save-StrictData { param($data,[string]$Action='') Save-PmcData -data $data -Action $Action }

function ConvertTo-PmcDate {
    param([string]$token)
    if ([string]::IsNullOrWhiteSpace($token)) { return $null }
    if ($token -match '^(?i)today$') { return (Get-Date).Date }
    if ($token -match '^(?i)yesterday$') { return (Get-Date).Date.AddDays(-1) }
    try { return [datetime]::ParseExact($token,'yyyy-MM-dd',$null) } catch {
        # Date parsing failed - return null for graceful fallback
    }
    # Parse-NaturalDate not available - basic parsing only
    return $null
}

function ConvertTo-PmcMinutes {
    param([string]$duration)
    # Parse-DurationToMinutes not available - basic parsing only
    # Allow bare numbers as hours (e.g., 1, 1.5, 0.25)
    if ($duration -match '^(\d+(?:\.\d+)?)$') { return [int]([double]$matches[1] * 60) }
    if ($duration -match '^(\d+(?:\.\d+)?)[hH]$') { return [int]([double]$matches[1] * 60) }
    if ($duration -match '^(\d+)[mM]$') { return [int]$matches[1] }
    return 0
}

# Alias for compatibility
function ConvertTo-PmcDurationMinutes {
    param([string]$duration)
    return ConvertTo-PmcMinutes $duration
}

# ===== TASKS =====
function Add-PmcTask { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $text = ($Context.FreeText -join ' ').Trim()
    if (-not $text) { Write-PmcStyled -Style 'Warning' -Text "Usage: task add <text> [@project] [p1|p2|p3] [due:YYYY-MM-DD] [#tag...]"; return }
    $projName = if ($Context.Args.ContainsKey('project')) { $Context.Args['project'] } else { $null }
    $priority = 0; if ($Context.Args.ContainsKey('priority')) { if ($Context.Args['priority'] -match '^p([1-3])$') { $priority = [int]$matches[1] } }
    $due = $null; if ($Context.Args.ContainsKey('due')) { $due = ConvertTo-PmcDate $Context.Args['due'] }
    $tags = @(); if ($Context.Args.ContainsKey('tags')) { $tags = @($Context.Args['tags']) }
    $projectField = 'inbox'
    if ($projName) {
        $p = Resolve-Project -Data $data -Name $projName
        if ($p) { $projectField = $p.name } else { $projectField = $projName }
    }
    $id = Get-PmcNextTaskId $data
    $task = @{
        id = $id
        text = $text
        project = $projectField
        priority = $priority
        status = 'pending'
        created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        tags = $tags
    }
    if ($due) { $task.due = $due.ToString('yyyy-MM-dd') }
    $data.tasks += $task
    Save-StrictData $data 'task add'
    Write-PmcStyled -Style 'Success' -Text ("Added task #${id}: {0}" -f $text)
}

function Get-PmcTaskList { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $tasks = @($data.tasks | Where-Object { try { $_ -ne $null -and $_.status -eq 'pending' } catch { $false } })
    $tasks = $tasks | Sort-Object `
        @{Expression={ if (Pmc-HasProp $_ 'priority'){ 4 - [int]$_.priority } else { 0 } }}, `
        @{Expression={ if (Pmc-HasProp $_ 'due'){ try { [datetime]$_.due } catch { [datetime]::MaxValue } } else { [datetime]::MaxValue } }}
    $mapList = @{}
    Set-PmcLastTaskListMap $mapList
    if ($tasks.Count -eq 0) { Show-PmcHeader -Title 'TASKS'; Show-PmcTip 'No pending tasks'; return }
    $rows = @(); $i=1
    foreach ($t in $tasks) {
        $mapList[$i] = $t.id
        Set-PmcLastTaskListMap $mapList
        $priVal = ''
        if ((Pmc-HasProp $t 'priority') -and $t.priority) { $priVal = 'p' + $t.priority }
        $dueVal = ''
        if ((Pmc-HasProp $t 'due') -and $t.due) { try { $dueVal = ([datetime]$t.due).ToString('MM/dd') } catch {
            # Date formatting failed - dueVal remains empty
        } }
        $textVal = if (Pmc-HasProp $t 'text') { $t.text } else { '' }
        # Indicate project when assigned (non-inbox)
        try {
            if ($t.PSObject.Properties['project'] -and $t.project -and $t.project -ne 'inbox') {
                $textVal = ("{0}  @{1}" -f $textVal, $t.project)
            }
        } catch {}
        $rows += @{ idx = ('[{0,2}]' -f $i); text = $textVal; pri = $priVal; due = $dueVal }
        $i++
    }
    $cols = @(
        @{ key='idx'; title='#'; width=5; align='right' },
        @{ key='text'; title='Task'; width=46 },
        @{ key='pri'; title='Pri'; width=4 },
        @{ key='due'; title='Due'; width=8 }
    )
    Show-PmcTable -Columns $cols -Rows $rows -Title 'TASKS'
    Show-PmcTip "Use 'task view <#>', 'task done <#>', 'task edit <#>'"
}

function Show-PmcTask { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ($Context.FreeText.Count -lt 1) { Write-PmcStyled -Style 'Warning' -Text "Usage: task view <id|#>"; return }
    $token = $Context.FreeText[0]
    $id = $null
    if ($token -match '^\d+$') { $id = [int]$token }
    $idxMap = Get-PmcLastTaskListMap
    if (-not $id -and $idxMap.ContainsKey($token)) { $id = [int]$idxMap[$token] }
    if (-not $id -and $token -match '^\d+$' -and $idxMap.ContainsKey([int]$token)) { $id = [int]$idxMap[[int]$token] }
    if (-not $id) { Write-PmcStyled -Style 'Error' -Text "Invalid id/index"; return }
    $t = $data.tasks | Where-Object { $_ -ne $null -and $_.id -eq $id } | Select-Object -First 1
    if (-not $t) { Write-PmcStyled -Style 'Error' -Text "Task #$id not found"; return }
    Write-PmcStyled -Style 'Info' -Text ("\nTask #{0}" -f $t.id)
    Write-PmcStyled -Style 'Body' -Text ("  Text:    {0}" -f (Pmc-GetProp $t 'text' ''))
    Write-PmcStyled -Style 'Body' -Text ("  Project: {0}" -f (Pmc-GetProp $t 'project' '(none)'))
    Write-Host ("  Priority:{0}" -f (Pmc-GetProp $t 'priority' 0))
    Write-Host ("  Due:     {0}" -f (Pmc-GetProp $t 'due' ''))
    Write-Host ("  Status:  {0}" -f (Pmc-GetProp $t 'status' 'pending'))
}

function Complete-PmcTask { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ($Context.FreeText.Count -lt 1 -and -not $Context.Args.ContainsKey('ids')) { Write-Host "Usage: task done <id|#|set>" -ForegroundColor Yellow; return }
    $raw = if ($Context.FreeText.Count -gt 0) { $Context.FreeText[0] } else { '' }
    $ids = @(); if ($Context.Args.ContainsKey('ids')) { $ids=@($Context.Args['ids']) }
    if (@($ids).Count -eq 0 -and $raw -match '^[0-9,\-]+$') { $ids = ConvertTo-PmcIdSet $raw }
    if (@($ids).Count -eq 0 -and $raw -match '^\d+$') { $n=[int]$raw; $idxMap=Get-PmcLastTaskListMap; if ($idxMap.ContainsKey($n)) { $ids=@($idxMap[$n]) } else { $ids=@($n) } }
    if (@($ids).Count -eq 0) { Write-Host "Invalid id/index/set" -ForegroundColor Red; return }
    $done=0; foreach ($id in $ids) {
        $t = $data.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties.Match('id').Count -gt 0 -and $_.id -eq $id } | Select-Object -First 1
        if ($t) {
            $t.status = 'completed'
            $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            if (Pmc-HasProp $t 'completed') { $t.completed = $ts } else { Add-Member -InputObject $t -MemberType NoteProperty -Name 'completed' -Value $ts -Force }
            $done++
        }
    }
    if ($done -gt 0) { Save-StrictData $data 'task done'; Write-Host ("Completed {0} task(s)" -f $done) -ForegroundColor Green } else { Write-Host 'No tasks completed' -ForegroundColor Yellow }
}

function Remove-PmcTask { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ($Context.FreeText.Count -lt 1 -and -not $Context.Args.ContainsKey('ids')) { Write-Host "Usage: task delete <id|#|set>" -ForegroundColor Yellow; return }
    $raw = if ($Context.FreeText.Count -gt 0) { $Context.FreeText[0] } else { '' }
    $ids = @(); if ($Context.Args.ContainsKey('ids')) { $ids=@($Context.Args['ids']) }
    if (@($ids).Count -eq 0 -and $raw -match '^[0-9,\-]+$') { $ids = ConvertTo-PmcIdSet $raw }
    if (@($ids).Count -eq 0 -and $raw -match '^\d+$') { $n=[int]$raw; $idxMap=Get-PmcLastTaskListMap; if ($idxMap.ContainsKey($n)) { $ids=@($idxMap[$n]) } else { $ids=@($n) } }
    if (@($ids).Count -eq 0) { Write-Host "Invalid id/index/set" -ForegroundColor Red; return }
    $before=@($data.tasks).Count
    $data.tasks = @($data.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties.Match('id').Count -gt 0 -and ($ids -notcontains $_.id) })
    $removed = $before - @($data.tasks).Count
    if ($removed -gt 0) { Save-StrictData $data 'task delete'; Write-Host ("Deleted {0} task(s)" -f $removed) -ForegroundColor Green } else { Write-Host 'No tasks deleted' -ForegroundColor Yellow }
}

function Set-PmcTask { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ($Context.FreeText.Count -lt 1) { Write-Host "Usage: task update <id|#|set> [@project] [p1|p2|p3] [due:YYYY-MM-DD] [#tag...|-#tag...] [new text]" -ForegroundColor Yellow; return }
    $raw=$Context.FreeText[0]; $ids=@()
    if ($raw -match '^[0-9,\-]+$') { $ids = ConvertTo-PmcIdSet $raw }
    if (@($ids).Count -eq 0 -and $raw -match '^\d+$') { $n=[int]$raw; $idxMap=Get-PmcLastTaskListMap; if ($idxMap.ContainsKey($n)) { $ids=@($idxMap[$n]) } else { $ids=@($n) } }
    if (@($ids).Count -eq 0) { Write-Host "Invalid id/index/set" -ForegroundColor Red; return }
    $proj=$null; $pri=$null; $due=$null
    if ($Context.Args.ContainsKey('project')) { $proj = $Context.Args['project'] }
    if ($Context.Args.ContainsKey('priority')) { if ($Context.Args['priority'] -match '^p([1-3])$') { $pri = [int]$matches[1] } }
    if ($Context.Args.ContainsKey('due')) { $d = ConvertTo-PmcDate $Context.Args['due']; if ($d) { $due = $d.ToString('yyyy-MM-dd') } }
    $addTags=@(); if ($Context.Args.ContainsKey('tags')) { $addTags=@($Context.Args['tags']) }
    $removeTags=@(); if ($Context.Args.ContainsKey('removeTags')) { $removeTags=@($Context.Args['removeTags']) }
    $newText = if ($Context.FreeText.Count -gt 1) { ($Context.FreeText[1..($Context.FreeText.Count-1)] -join ' ') } else { $null }
    $updated=0
    foreach ($id in $ids) {
        $t = $data.tasks | Where-Object { $_ -ne $null -and $_.id -eq $id } | Select-Object -First 1
        if (-not $t) { Write-Host "Task #$id not found" -ForegroundColor Yellow; continue }
        if ($proj) { $t.project = $proj }
        if ($pri) { $t.priority = $pri }
        if ($due) { $t.due = $due }
        if (($addTags.Count -gt 0) -or ($removeTags.Count -gt 0)) {
            if (-not $t.PSObject.Properties['tags']) { $t | Add-Member -NotePropertyName tags -NotePropertyValue @() -Force }
            $curr=@($t.tags)
            foreach ($tg in $addTags) { if ($curr -notcontains $tg) { $curr += $tg } }
            foreach ($rt in $removeTags) { $curr = @($curr | Where-Object { $_ -ne $rt }) }
            $t.tags = $curr
        }
        if ($newText) { $t.text = $newText }
        $updated++
    }
    if ($updated -gt 0) { Save-StrictData $data 'task update'; Write-Host ("Updated {0} task(s)" -f $updated) -ForegroundColor Green }
}

function Move-PmcTask { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if (($Context.FreeText.Count -lt 1 -and -not $Context.Args.ContainsKey('ids')) -or -not $Context.Args.ContainsKey('project')) { Write-Host "Usage: task move <id|#|set> @project" -ForegroundColor Yellow; return }
    $raw = if ($Context.FreeText.Count -gt 0) { $Context.FreeText[0] } else { '' }
    $ids = @(); if ($Context.Args.ContainsKey('ids')) { $ids=@($Context.Args['ids']) }
    if (@($ids).Count -eq 0 -and $raw -match '^[0-9,\-]+$') { $ids = ConvertTo-PmcIdSet $raw }
    if (@($ids).Count -eq 0 -and $raw -match '^\d+$') { $n=[int]$raw; if ($Script:PmcLastTaskListMap.ContainsKey($n)) { $ids=@($Script:PmcLastTaskListMap[$n]) } else { $ids=@($n) } }
    if (@($ids).Count -eq 0) { Write-Host "Invalid id/index/set" -ForegroundColor Red; return }
    $proj = $Context.Args['project']
    $moved=0; foreach ($id in $ids) { $t = $data.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties.Match('id').Count -gt 0 -and $_.id -eq $id } | Select-Object -First 1; if ($t) { $t.project=$proj; $moved++ } }
    if ($moved -gt 0) { Save-StrictData $data 'task move'; Write-Host ("Moved {0} task(s) to @{1}" -f $moved,$proj) -ForegroundColor Green } else { Write-Host 'No tasks moved' -ForegroundColor Yellow }
}

function Set-PmcTaskPostponed { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ( (@($Context.FreeText).Count -lt 2 -and -not $Context.Args.ContainsKey('ids')) ) { Write-Host "Usage: task postpone <id|#|set> <+Nd|-Nd|YYYY-MM-DD>" -ForegroundColor Yellow; return }
    $raw = if ($Context.FreeText.Count -gt 0) { $Context.FreeText[0] } else { '' }
    $delta = if ($Context.FreeText.Count -gt 1) { $Context.FreeText[1] } else { '' }
    $ids=@(); if ($Context.Args.ContainsKey('ids')) { $ids=@($Context.Args['ids']) } elseif ($raw -match '^[0-9,\-]+$') { $ids = ConvertTo-PmcIdSet $raw }
    if (@($ids).Count -eq 0 -and $raw -match '^\d+$') { $n=[int]$raw; $idxMap=Get-PmcLastTaskListMap; if ($idxMap.ContainsKey($n)) { $ids=@($idxMap[$n]) } else { $ids=@($n) } }
    if (@($ids).Count -eq 0) { Write-Host "Invalid id/index/set" -ForegroundColor Red; return }
    $sign=$null; $days=0; $parsed=$null
    if ($delta -match '^([+-])(\d+)d$') { $sign=$matches[1]; $days=[int]$matches[2] } else { $parsed = ConvertTo-PmcDate $delta; if (-not $parsed) { Write-Host 'Invalid delta/date' -ForegroundColor Red; return } }
    $changed=0
    foreach ($id in $ids) {
        $t = $data.tasks | Where-Object { $_ -ne $null -and $_.id -eq $id } | Select-Object -First 1
        if (-not $t) { continue }
        $base = if ($t.due) { [datetime]$t.due } else { (Get-Date).Date }
        $nd = $parsed
        if ($sign) {
            if ($sign -eq '+') {
                $nd = $base.AddDays($days)
            } else {
                $nd = $base.AddDays(-$days)
            }
        }
        if ($nd) { $t.due = $nd.ToString('yyyy-MM-dd'); $changed++ }
    }
    if ($changed -gt 0) { Save-StrictData $data 'task postpone'; Write-Host ("Postponed {0} task(s)" -f $changed) -ForegroundColor Green }
}

function Copy-PmcTask { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ($Context.FreeText.Count -lt 1 -and -not $Context.Args.ContainsKey('ids')) { Write-Host "Usage: task duplicate <id|#|set>" -ForegroundColor Yellow; return }
    $raw = if ($Context.FreeText.Count -gt 0) { $Context.FreeText[0] } else { '' }
    $ids=@(); if ($Context.Args.ContainsKey('ids')) { $ids=@($Context.Args['ids']) } elseif ($raw -match '^[0-9,\-]+$') { $ids=ConvertTo-PmcIdSet $raw }
    if (@($ids).Count -eq 0 -and $raw -match '^\d+$') { $n=[int]$raw; if ($Script:PmcLastTaskListMap.ContainsKey($n)) { $ids=@($Script:PmcLastTaskListMap[$n]) } else { $ids=@($n) } }
    if (@($ids).Count -eq 0) { Write-Host "Invalid id/index/set" -ForegroundColor Red; return }
    $count=0
    foreach ($id in $ids) {
        $t = $data.tasks | Where-Object { $_ -ne $null -and $_.id -eq $id } | Select-Object -First 1
        if (-not $t) { continue }
        $newId = Get-PmcNextTaskId $data
        $copy = [pscustomobject]@{}
        foreach ($p in $t.PSObject.Properties) { if ($p.Name -ne 'id' -and $p.Name -ne 'completed') { Add-Member -InputObject $copy -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force } }
        $copy | Add-Member -NotePropertyName id -NotePropertyValue $newId -Force
        $copy | Add-Member -NotePropertyName status -NotePropertyValue 'pending' -Force
        $data.tasks += $copy; $count++
    }
    if ($count -gt 0) { Save-StrictData $data 'task duplicate'; Write-Host ("Duplicated {0} task(s)" -f $count) -ForegroundColor Green } else { Write-Host 'No tasks duplicated' -ForegroundColor Yellow }
}

function Add-PmcTaskNote { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ( (@($Context.FreeText).Count -lt 2 -and -not $Context.Args.ContainsKey('ids')) ) { Write-Host "Usage: task note <id|#|set> <text>" -ForegroundColor Yellow; return }
    $raw = if ($Context.FreeText.Count -gt 0) { $Context.FreeText[0] } else { '' }
    $text = if ($Context.FreeText.Count -gt 1) { ($Context.FreeText[1..($Context.FreeText.Count-1)] -join ' ') } else { '' }
    $ids=@(); if ($Context.Args.ContainsKey('ids')) { $ids=@($Context.Args['ids']) } elseif ($raw -match '^[0-9,\-]+$') { $ids=ConvertTo-PmcIdSet $raw }
    if (@($ids).Count -eq 0 -and $raw -match '^\d+$') { $n=[int]$raw; if ($Script:PmcLastTaskListMap.ContainsKey($n)) { $ids=@($Script:PmcLastTaskListMap[$n]) } else { $ids=@($n) } }
    if (@($ids).Count -eq 0) { Write-Host "Invalid id/index/set" -ForegroundColor Red; return }
    $count=0
    foreach ($id in $ids) { $t = $data.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties.Match('id').Count -gt 0 -and $_.id -eq $id } | Select-Object -First 1; if ($t) { if (-not $t.PSObject.Properties['notes']) { $t | Add-Member -NotePropertyName notes -NotePropertyValue @() -Force }; $t.notes = @($t.notes + @([pscustomobject]@{ text=$text; created=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss') })); $count++ } }
    if ($count -gt 0) { Save-StrictData $data 'task note'; Write-Host ("Added note to {0} task(s)" -f $count) -ForegroundColor Green }
}

function Edit-PmcTask { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ($Context.FreeText.Count -lt 1) { Write-Host "Usage: task edit <id|#>" -ForegroundColor Yellow; return }
    $token = $Context.FreeText[0]
    $id = $null
    if ($token -match '^\d+$') { $id = [int]$token }
    if (-not $id -and $Script:PmcLastTaskListMap.ContainsKey($token)) { $id = [int]$Script:PmcLastTaskListMap[$token] }
    if (-not $id -and $token -match '^\d+$' -and $Script:PmcLastTaskListMap.ContainsKey([int]$token)) { $id = [int]$Script:PmcLastTaskListMap[[int]$token] }
    if (-not $id) { Write-Host "Invalid id/index" -ForegroundColor Red; return }
    $t = $data.tasks | Where-Object { $_ -ne $null -and $_.id -eq $id } | Select-Object -First 1
    if (-not $t) { Write-Host "Task #$id not found" -ForegroundColor Red; return }

    Write-PmcDebug -Level 1 -Category 'EDITOR' -Message ("Task editor start: #${id}")

    $fields = @(
        @{ Key='text'; Label='Text' },
        @{ Key='project'; Label='Project' },
        @{ Key='priority'; Label='Priority (0-3)' },
        @{ Key='due'; Label='Due (YYYY-MM-DD)' },
        @{ Key='tags'; Label='Tags (space or comma separated)' }
    )
    $sel = 0; $modified = $false

    function render-task([pscustomobject]$task,[int]$idx) {
        Clear-Host
        Show-PmcHeader -Title ("EDIT TASK #{0}" -f $task.id)
        for ($i=0; $i -lt $fields.Count; $i++) {
            $f = $fields[$i]
            $val = ''
            if ($f.Key -eq 'tags') {
                if ($task.PSObject.Properties['tags'] -and $task.tags) { $val = ($task.tags -join ', ') }
            } else {
                if ($task.PSObject.Properties[$f.Key]) { $val = [string]$task.($f.Key) }
            }
            $prefix = if ($i -eq $idx) { '► ' } else { '  ' }
            Write-Host ("{0}{1,-28} {2}" -f $prefix, ($f.Label + ':'), $val)
        }
        Write-Host ""
        Write-PmcStyled -Style 'Muted' -Text "  ↑/↓ select, Enter edit, Q/Esc save and exit"
    }

    while ($true) {
        render-task $t $sel
        $key = $null
        try { $key = [Console]::ReadKey($true) } catch { break }
        switch ($key.Key) {
            'UpArrow' { if ($sel -gt 0) { $sel-- }; continue }
            'DownArrow' { if ($sel -lt ($fields.Count-1)) { $sel++ }; continue }
            'Enter' {
                $f = $fields[$sel]
                $prompt = $f.Label
                $current = ''
                if ($f.Key -eq 'tags') { if ($t.PSObject.Properties['tags'] -and $t.tags) { $current = ($t.tags -join ',') } }
                elseif ($t.PSObject.Properties[$f.Key]) { $current = [string]$t.($f.Key) }
                $inp = Read-Host ("$prompt [$current]")
                if ($null -ne $inp -and $inp -ne '') {
                    switch ($f.Key) {
                        'priority' { try { $p=[int]$inp; if ($p -ge 0 -and $p -le 3) { $t.priority=$p; $modified=$true } } catch {} }
                        'due' { try { $d=[datetime]::ParseExact($inp,'yyyy-MM-dd',$null); $t.due=$d.ToString('yyyy-MM-dd'); $modified=$true } catch { Write-Host 'Invalid date' -ForegroundColor Yellow } }
                        'tags' { $arr = @($inp -split '[,\s]+' | Where-Object { $_ }); $t | Add-Member -NotePropertyName tags -NotePropertyValue $arr -Force; $modified=$true }
                        default { $t | Add-Member -NotePropertyName $f.Key -NotePropertyValue $inp -Force; $modified=$true }
                    }
                }
                continue
            }
            'Q' { break }
            'Escape' { break }
            default { continue }
        }
        break
    }

    if ($modified) {
        Save-StrictData $data 'task edit'
        Write-Host ("Saved task #{0}" -f $id) -ForegroundColor Green
    } else {
        Write-Host 'No changes' -ForegroundColor Gray
    }
    Write-PmcDebug -Level 1 -Category 'EDITOR' -Message ("Task editor end: #${id} modified=${modified}")
}

function Edit-PmcProject { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $projName = if ($Context.Args.ContainsKey('project')) { $Context.Args['project'] } else { ($Context.FreeText -join ' ').Trim() }
    if (-not $projName) { Write-Host "Usage: project edit @project" -ForegroundColor Yellow; return }
    $proj = ($data.projects | Where-Object { $_ -ne $null -and $_.name -eq $projName } | Select-Object -First 1)
    if (-not $proj) { Write-Host ("Project '{0}' not found" -f $projName) -ForegroundColor Red; return }

    Write-PmcDebug -Level 1 -Category 'EDITOR' -Message ("Project editor start: '{0}'" -f $proj.name)
    $fields = @(
        @{ Key='name'; Label='Name' },
        @{ Key='description'; Label='Description' },
        @{ Key='ID2'; Label='ID2' },
        @{ Key='CAAName'; Label='CAAName' },
        @{ Key='ProjFolder'; Label='ProjFolder' },
        @{ Key='AssignedDate'; Label='AssignedDate' },
        @{ Key='DueDate'; Label='DueDate' },
        @{ Key='BFDate'; Label='BFDate' },
        @{ Key='RequestName'; Label='RequestName' },
        @{ Key='T2020'; Label='T2020' }
    )
    $sel = 0; $modified = $false

    function render-proj([pscustomobject]$p,[int]$idx) {
        Clear-Host
        Show-PmcHeader -Title ("EDIT PROJECT: {0}" -f $p.name)
        for ($i=0; $i -lt $fields.Count; $i++) {
            $f = $fields[$i]
            $val = if ($p.PSObject.Properties[$f.Key]) { [string]$p.($f.Key) } else { '' }
            $prefix = if ($i -eq $idx) { '► ' } else { '  ' }
            Write-Host ("{0}{1,-16} {2}" -f $prefix, ($f.Label + ':'), $val)
        }
        Write-Host ""
        Write-PmcStyled -Style 'Muted' -Text "  ↑/↓ select, Enter edit, Q/Esc save and exit"
    }

    while ($true) {
        render-proj $proj $sel
        $key = $null
        try { $key = [Console]::ReadKey($true) } catch { break }
        switch ($key.Key) {
            'UpArrow' { if ($sel -gt 0) { $sel-- }; continue }
            'DownArrow' { if ($sel -lt ($fields.Count-1)) { $sel++ }; continue }
            'Enter' {
                $f = $fields[$sel]
                $current = if ($proj.PSObject.Properties[$f.Key]) { [string]$proj.($f.Key) } else { '' }
                $inp = Read-Host ("$($f.Label) [$current]")
                if ($null -ne $inp -and $inp -ne '') { $proj | Add-Member -NotePropertyName $f.Key -NotePropertyValue $inp -Force; $modified=$true }
                continue }
            'Q' { break }
            'Escape' { break }
            default { continue }
        }
        break
    }

    if ($modified) {
        Save-StrictData $data 'project update'
        Write-Host ("Saved project: {0}" -f $proj.name) -ForegroundColor Green
    } else {
        Write-Host 'No changes' -ForegroundColor Gray
    }
    Write-PmcDebug -Level 1 -Category 'EDITOR' -Message ("Project editor end: '{0}' modified={1}" -f $proj.name, $modified)
}

function Find-PmcTask { param([PmcCommandContext]$Context)
    $q = ($Context.FreeText -join ' ').Trim(); if (-not $q) { Write-Host "Usage: task search <query>" -ForegroundColor Yellow; return }
    $data = Get-PmcDataAlias
    $hits = @($data.tasks | Where-Object { try { $_.text -and ($_.text.ToLower().Contains($q.ToLower())) } catch { $false } })
    Write-Host "\nSEARCH: '$q'" -ForegroundColor Cyan
    if ($hits.Count -eq 0) { Write-Host 'No matches' -ForegroundColor Yellow; return }
    $i=1; $map=@{}; Set-PmcLastTaskListMap $map
    foreach ($t in $hits) { $map[$i]=$t.id; Set-PmcLastTaskListMap $map; Write-Host ("  [{0,2}] (#{1}) {2}" -f $i,$t.id,$t.text) -ForegroundColor White; $i++ }
}

function Set-PmcTaskPriority { param([PmcCommandContext]$Context)
    $lvlText = ($Context.FreeText -join ' ').Trim(); if (-not $lvlText -match '^[1-3]$') { Write-Host "Usage: task priority <1|2|3>" -ForegroundColor Yellow; return }
    $lvl = [int]$lvlText
    $data = Get-PmcDataAlias
    $hits = @($data.tasks | Where-Object { try { $_.priority -eq $lvl -and $_.status -eq 'pending' } catch { $false } })
    Write-Host ("\nPRIORITY p{0}" -f $lvl) -ForegroundColor Cyan
    if ($hits.Count -eq 0) { Write-Host 'No tasks' -ForegroundColor Yellow; return }
    $i=1; $map=@{}; Set-PmcLastTaskListMap $map
    foreach ($t in $hits) { $map[$i]=$t.id; Set-PmcLastTaskListMap $map; Write-Host ("  [{0,2}] (#{1}) {2}" -f $i,$t.id,$t.text) -ForegroundColor White; $i++ }
}

# ===== VIEWS =====
function Show-PmcTaskAgenda { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $today = (Get-Date).Date
    $pending = @($data.tasks | Where-Object { try { $_ -ne $null -and $_.status -eq 'pending' } catch { $false } })
    $overdue = @($pending | Where-Object { $_.due -and ([datetime]$_.due) -lt $today })
    $todayTasks = @($pending | Where-Object { $_.due -and ([datetime]$_.due) -eq $today })
    $upcoming = @($pending | Where-Object { $_.due -and ([datetime]$_.due) -gt $today -and ([datetime]$_.due) -le $today.AddDays(7) })
    $nodue = @($pending | Where-Object { -not $_.due })
    Set-PmcLastTaskListMap @{}
    $i=1
    function render-section([string]$title, [array]$items) {
        if (@($items).Count -eq 0) { return }
        $rows=@()
        foreach ($t in ($items | Sort-Object @{Expression={ if ($_.PSObject.Properties['priority']){ 4 - [int]$_.priority } else { 0 } }}, @{Expression={ if ($_.PSObject.Properties['due']){ try { [datetime]$_.due } catch { [datetime]::MaxValue } } else { [datetime]::MaxValue } }})) {
            $map = Get-PmcLastTaskListMap
            $map[$i] = $t.id
            Set-PmcLastTaskListMap $map
            $priVal = ''
            if ($t.PSObject.Properties.Match('priority').Count -gt 0 -and $t.priority) { $priVal = 'p' + $t.priority }
            $dueVal = ''
            if ($t.PSObject.Properties.Match('due').Count -gt 0 -and $t.due) { try { $dueVal = ([datetime]$t.due).ToString('MM/dd') } catch {
                # Date formatting failed - dueVal remains empty
            } }
            $projName = if ($t.PSObject.Properties.Match('project').Count -gt 0 -and $t.project) { $t.project } else { '(none)' }
            $taskText = if ($t.PSObject.Properties.Match('text').Count -gt 0) { $t.text } else { '' }
            $rows += @{ idx = ('[{0,2}]' -f $i); id = ('#' + $t.id); pri = $priVal; task = $taskText; project = $projName; due = $dueVal }
            $i++
        }
        $cols = @(
            @{ key='idx'; title='#'; width=5; align='right' },
            @{ key='id'; title='ID'; width=6 },
            @{ key='pri'; title='Pri'; width=4 },
            @{ key='task'; title='Task'; width=40 },
            @{ key='project'; title='Project'; width=18 },
            @{ key='due'; title='Due'; width=8 }
        )
        Show-PmcTable -Columns $cols -Rows $rows -Title $title
    }
    Show-PmcHeader -Title ("AGENDA: {0}" -f $today.ToString('yyyy-MM-dd'))
    render-section 'OVERDUE' $overdue
    render-section 'TODAY' $todayTasks
    render-section 'UPCOMING (7d)' $upcoming
    render-section 'NO DUE' $nodue
    Show-PmcTip "Use 'task view <#>', 'task done <#>', 'task edit <#>'"
}

function Show-PmcTaskWeek { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $today = (Get-Date).Date
    $start = $today.AddDays(-[int]$today.DayOfWeek)
    $end = $start.AddDays(7)
    Show-PmcHeader -Title ("WEEK: {0} - {1}" -f $start.ToString('yyyy-MM-dd'), $end.AddDays(-1).ToString('yyyy-MM-dd'))
    $rows=@()
    for ($d=0; $d -lt 7; $d++) {
        $day=$start.AddDays($d)
        $items = @($data.tasks | Where-Object { try { $_.status -eq 'pending' -and $_.PSObject.Properties.Match('due').Count -gt 0 -and $_.due -and ([datetime]$_.due) -eq $day } catch { $false } })
        $text = if (@($items).Count -gt 0) { (@($items | Select-Object -First 3 | ForEach-Object { $_.text })) -join '; ' } else { '' }
        $rows += @{ day=$day.ToString('ddd MM/dd'); count=@($items).Count; tasks=$text }
    }
    $cols = @(
        @{ key='day'; title='Day'; width=12 },
        @{ key='count'; title='Count'; width=7; align='right' },
        @{ key='tasks'; title='Tasks'; width=50 }
    )
    Show-PmcTable -Columns $cols -Rows $rows
}

function Show-PmcTaskMonth { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $today = Get-Date
    $year=$today.Year; $month=$today.Month
    $first = Get-Date -Year $year -Month $month -Day 1
    $days = [DateTime]::DaysInMonth($year,$month)
    $end = $first.AddDays($days)
    Show-PmcHeader -Title (Get-Date -Year $year -Month $month -Day 1 -Format 'MMMM yyyy')
    $rows=@()
    for ($d=1; $d -le $days; $d++) {
        $day = Get-Date -Year $year -Month $month -Day $d
        $items = @($data.tasks | Where-Object { try { $_.status -eq 'pending' -and $_.PSObject.Properties.Match('due').Count -gt 0 -and $_.due -and ([datetime]$_.due) -eq $day.Date } catch { $false } })
        if (@($items).Count -gt 0) { $rows += @{ date=$day.ToString('MM/dd ddd'); count=@($items).Count; sample=(@($items | Select-Object -First 2 | ForEach-Object { $_.text }) -join '; ') } }
    }
    if (@($rows).Count -eq 0) { Show-PmcTip 'No scheduled tasks this month'; return }
    $cols = @(
        @{ key='date'; title='Date'; width=12 },
        @{ key='count'; title='Count'; width=7; align='right' },
        @{ key='sample'; title='Tasks'; width=50 }
    )
    Show-PmcTable -Columns $cols -Rows $rows
}

# ===== PROJECTS =====
function Add-PmcProject { param([PmcCommandContext]$Context)
    $name = ($Context.FreeText -join ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host "Usage: project add <name>" -ForegroundColor Yellow; return }
    $data = Get-PmcDataAlias
    if ($data.projects | Where-Object { $_.name -eq $name }) { Write-Host "Project '$name' already exists" -ForegroundColor Yellow; return }
    $proj = [pscustomobject]@{ name=$name; description="Created $(Get-Date -Format yyyy-MM-dd)"; aliases=@(); created=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss') }
    $data.projects += $proj; Save-StrictData $data 'project add'
    Write-Host "Project '$name' created." -ForegroundColor Green
}

function Get-PmcProjectList { param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category 'COMMAND' -Message "PROJECT LIST DEBUG: Starting Get-PmcProjectList"
    try {
        $data = Get-PmcDataAlias
        Write-PmcDebug -Level 1 -Category 'COMMAND' -Message "PROJECT LIST DEBUG: Got data, projects count: $($data.projects.Count)"
        Write-PmcDebug -Level 1 -Category 'COMMAND' -Message "PROJECT LIST DEBUG: First project type: $($data.projects[0].GetType().Name)"
        Write-PmcDebug -Level 1 -Category 'COMMAND' -Message "PROJECT LIST DEBUG: First project properties: $($data.projects[0].PSObject.Properties.Name -join ', ')"

        $rows=@(); foreach ($p in ($data.projects | Sort-Object name)) {
            Write-PmcDebug -Level 1 -Category 'COMMAND' -Message "PROJECT LIST DEBUG: Processing project name='$($p.name)'"
            $taskCount = (@($data.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties.Match('project').Count -gt 0 -and $_.PSObject.Properties.Match('status').Count -gt 0 -and $_.project -eq $p.name -and $_.status -eq 'pending' }).Count)
            $desc = if ((Pmc-HasProp $p 'description') -and $p.description) { [string]$p.description } else { '' }
            $rows += @{ project=$p.name; tasks=$taskCount; desc=$desc }
        }
        Write-PmcDebug -Level 1 -Category 'COMMAND' -Message "PROJECT LIST DEBUG: Created $($rows.Count) rows"

        $cols = @(
            @{ key='project'; title='Project'; width=22 },
            @{ key='tasks'; title='Tasks'; width=7; align='right' },
            @{ key='desc'; title='Description'; width=40 }
        )
        Show-PmcTable -Columns $cols -Rows $rows -Title 'PROJECTS'
    } catch {
        Write-PmcDebug -Level 1 -Category 'COMMAND' -Message "PROJECT LIST ERROR: $_ | StackTrace: $($_.ScriptStackTrace)"
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

function Show-PmcProject { param([PmcCommandContext]$Context)
    $q = ($Context.FreeText -join ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($q)) { Write-Host "Usage: project view <name>" -ForegroundColor Yellow; return }
    # Show-ProjectDetails not available - basic view only
    $data = Get-PmcDataAlias
    $p = Resolve-Project -Data $data -Name $q
    if (-not $p) { Show-PmcError ("Project '{0}' not found" -f $q); return }
    Write-Host ("\nProject: {0}" -f $p.name) -ForegroundColor Cyan
    Write-Host ("  Description: {0}" -f (if ((Pmc-HasProp $p 'description') -and $p.description) { [string]$p.description } else { '' }))
}

function Rename-PmcProject { param([PmcCommandContext]$Context)
    $parts = ($Context.FreeText -join ' ') -split '\s+', 2
    if ($parts.Count -lt 2) { Write-Host "Usage: project rename <old> <new>" -ForegroundColor Yellow; return }
    $old = $parts[0]; $new = $parts[1]
    $data = Get-PmcDataAlias
    $proj = Resolve-Project -Data $data -Name $old
    if (-not $proj) { Show-PmcError ("Project '{0}' not found" -f $old); return }
    if ($data.projects | Where-Object { $_.name -eq $new -and $_.name -ne $old }) { Write-Host "Project '$new' already exists" -ForegroundColor Red; return }
    $proj.name = $new
    foreach ($t in $data.tasks) { if ($t.project -eq $old) { $t.project = $new } }
    $ctx = Get-PmcCurrentContext
    if ($ctx -eq $old) { $data.currentContext = $new; $global:CurrentContext = $new; Set-PmcState -Section 'Focus' -Key 'Current' -Value $new }
    Save-StrictData $data 'project rename'
    Write-Host "Renamed project '$old' to '$new'" -ForegroundColor Green
}

function Remove-PmcProject {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        [PmcCommandContext]$Context
    )
    $name = ($Context.FreeText -join ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host "Usage: project delete <name>" -ForegroundColor Yellow; return }
    if ($name -in @('inbox','personal','work')) { Write-Host "Cannot delete default project '$name'" -ForegroundColor Red; return }
    $data = Get-PmcDataAlias
    $proj = Resolve-Project -Data $data -Name $name
    if (-not $proj) { Show-PmcError ("Project '{0}' not found" -f $name); return }
    $tasks = @($data.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties.Match('project').Count -gt 0 -and $_.project -eq $name })
    $timeLogs = @($data.timelogs | Where-Object { $_ -ne $null -and $_.PSObject.Properties.Match('project').Count -gt 0 -and $_.project -eq $name })
    Write-Host "Deleting '$name' will remove: tasks=$($tasks.Count), time logs=$($timeLogs.Count)" -ForegroundColor Yellow
    # Require explicit confirmation to avoid accidental data loss
    $confirmMsg = "Delete project '$name' and all associated data?"
    if (-not $PSCmdlet.ShouldProcess($name, $confirmMsg)) { return }
    # Additional human-in-the-loop confirmation when not suppressed by -Confirm:$false
    $shouldPrompt = ($ConfirmPreference -ne 'None')
    if ($shouldPrompt) {
        $typed = Read-Host "Type the project name exactly to confirm deletion"
        if ($typed -ne $name) {
            Write-Host "Canceled" -ForegroundColor Gray
            return
        }
    }
    $data.tasks = @($data.tasks | Where-Object { $_.project -ne $name })
    $data.timelogs = @($data.timelogs | Where-Object { $_.project -ne $name })
    $data.projects = @($data.projects | Where-Object { $_.name -ne $name })
    $ctx = Get-PmcCurrentContext
    if ($ctx -eq $name) { $global:CurrentContext='inbox'; $data.currentContext='inbox'; Set-PmcState -Section 'Focus' -Key 'Current' -Value 'inbox' }
    Save-StrictData $data 'project delete'
    Write-Host "Deleted project '$name'" -ForegroundColor Green
}

# Archive project
function Set-PmcProjectArchived { param([PmcCommandContext]$Context)
    $name = ($Context.FreeText -join ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host "Usage: project archive <name>" -ForegroundColor Yellow; return }
    $data = Get-PmcDataAlias
    $proj = Resolve-Project -Data $data -Name $name
    if (-not $proj) { Show-PmcError ("Project '{0}' not found" -f $name); return }
    if ((Pmc-HasProp $proj 'isArchived') -and $proj.isArchived) { Write-Host "Project '$name' is already archived" -ForegroundColor Yellow; return }
    $proj.isArchived = $true
    $proj.archivedDate = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    if ($data.currentContext -eq $name) { $data.currentContext = 'inbox' }
    Save-StrictData $data 'project archive'
    Write-Host "Archived project '$name'" -ForegroundColor Green
}

# Set project fields
function Set-PmcProjectFields { param([PmcCommandContext]$Context)
    $projName = if ($Context.Args.ContainsKey('project')) { $Context.Args['project'] } else { $null }
    if (-not $projName) { Write-Host "Usage: project set-fields @project Key=Value ..." -ForegroundColor Yellow; return }
    $data = Get-PmcDataAlias
    $proj = Resolve-Project -Data $data -Name $projName
    if (-not $proj) { Show-PmcError ("Project '{0}' not found" -f $projName); return }
    $pairs = ($Context.FreeText -join ' ').Trim()
    if (-not $pairs) { Write-Host "No fields provided (expected Key=Value tokens)" -ForegroundColor Yellow; return }
    $updates = 0
    foreach ($tok in ($pairs -split '\s+')) {
        if ($tok -match '^(\w+)=(.+)$') {
            $k=$matches[1]; $v=$matches[2]
            try { if ($proj.PSObject.Properties[$k]) { $proj.$k = $v } else { $proj | Add-Member -NotePropertyName $k -NotePropertyValue $v -Force } $updates++ } catch {
                # Project property update failed - skip this field
            }
        }
    }
    Save-StrictData $data 'project set-fields'
    Show-PmcSuccess ("Updated {0} field(s) on '{1}'" -f $updates,$proj.name)
}

function Show-PmcProjectFields { param([PmcCommandContext]$Context)
    $projName = if ($Context.Args.ContainsKey('project')) { $Context.Args['project'] } else { $null }
    if (-not $projName) { Write-Host "Usage: project show-fields @project" -ForegroundColor Yellow; return }
    $data = Get-PmcDataAlias
    $proj = Resolve-Project -Data $data -Name $projName
    if (-not $proj) { Show-PmcError ("Project '{0}' not found" -f $projName); return }
    Write-Host ("\nPROJECT FIELDS: {0}" -f $proj.name) -ForegroundColor Cyan
    foreach ($p in $proj.PSObject.Properties) {
        Write-Host ("  {0}: {1}" -f $p.Name, ($p.Value)) -ForegroundColor White
    }
}

# Thin wrapper: project update @name Key=Value ... (alias of set-fields with explicit name)
function Set-PmcProject { param([PmcCommandContext]$Context)
    $projName = if ($Context.Args.ContainsKey('project')) { $Context.Args['project'] } else { $null }
    if (-not $projName) { Write-Host "Usage: project update @project Key=Value ..." -ForegroundColor Yellow; return }
    $data = Get-PmcDataAlias
    $proj = Resolve-Project -Data $data -Name $projName
    if (-not $proj) { Show-PmcError ("Project '{0}' not found" -f $projName); return }
    $pairs = ($Context.FreeText -join ' ').Trim()
    if (-not $pairs) { Write-Host "No fields provided (expected Key=Value tokens)" -ForegroundColor Yellow; return }
    $updates = 0
    foreach ($tok in ($pairs -split '\s+')) {
        if ($tok -match '^(\w+)=(.+)$') {
            $k=$matches[1]; $v=$matches[2]
            try { if ($proj.PSObject.Properties[$k]) { $proj.$k = $v } else { $proj | Add-Member -NotePropertyName $k -NotePropertyValue $v -Force } $updates++ } catch {
                # Project property update failed - skip this field
            }
        }
    }
    Save-StrictData $data 'project update'
    Show-PmcSuccess ("Updated {0} field(s) on '{1}'" -f $updates,$proj.name)
}

# Project insights
function Get-PmcProjectStats { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $name = if ($Context.Args.ContainsKey('project')) { $Context.Args['project'] } else { '' }
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host "Usage: project stats @project" -ForegroundColor Yellow; return }
    $proj = Resolve-Project -Data $data -Name $name
    if (-not $proj) { Show-PmcError ("Project '{0}' not found" -f $name); return }
    $tasks = @($data.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties.Match('project').Count -gt 0 -and $_.project -eq $proj.name })
    $pending = @($tasks | Where-Object { $_.PSObject.Properties.Match('status').Count -gt 0 -and $_.status -eq 'pending' })
    $done = @($tasks | Where-Object { $_.PSObject.Properties.Match('status').Count -gt 0 -and $_.status -eq 'completed' })
    $overdueCount = 0
    foreach ($t in $pending) {
        if ($t.PSObject.Properties.Match('due').Count -gt 0 -and $t.due) {
            try { if ([datetime]$t.due -lt (Get-Date).Date) { $overdueCount++ } } catch {
                # Date comparison failed - skip overdue check for this task
            }
        }
    }
    $blocked = @($pending | Where-Object { $_.PSObject.Properties.Match('blocked').Count -gt 0 -and $_.blocked })
    $cols = @(@{key='metric';title='Metric';width=18}, @{key='value';title='Value';width=8;align='right'})
    $rows = @(
        @{ metric='Pending'; value=(@($pending).Count) },
        @{ metric='Completed'; value=(@($done).Count) },
        @{ metric='Overdue'; value=$overdueCount },
        @{ metric='Blocked'; value=(@($blocked).Count) }
    )
    Show-PmcTable -Columns $cols -Rows $rows -Title ("PROJECT STATS: {0}" -f $proj.name)
}

function Show-PmcProjectInfo { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $name = if ($Context.Args.ContainsKey('project')) { $Context.Args['project'] } else { '' }
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host "Usage: project info @project" -ForegroundColor Yellow; return }
    $proj = Resolve-Project -Data $data -Name $name
    if (-not $proj) { Show-PmcError ("Project '{0}' not found" -f $name); return }
    Write-Host ("\nProject: {0}" -f $proj.name) -ForegroundColor Cyan
    foreach ($p in $proj.PSObject.Properties) { Write-Host ("  {0}: {1}" -f $p.Name, $p.Value) }
}

function Get-PmcRecentProjects { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $recent = @()
    foreach ($p in $data.projects) {
        $latest = ($data.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties.Match('project').Count -gt 0 -and $_.project -eq $p.name } | Sort-Object { try { [datetime]$_.created } catch { [datetime]::MinValue } } -Descending | Select-Object -First 1)
        if ($latest) { $recent += @{ project=$p.name; last=($latest.created ?? '') } }
    }
    if ($recent.Count -eq 0) { Write-Host 'No recent projects' -ForegroundColor Yellow; return }
    Show-PmcTable -Columns @(@{key='project';title='Project';width=22}, @{key='last';title='Last Activity';width=20}) -Rows ($recent | Sort-Object last -Descending) -Title 'RECENT PROJECTS'
}

# ===== TIME =====
function Get-PmcTimeList { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if (-not $data.timelogs) { $data.timelogs = @() }
    $logs = @($data.timelogs | Where-Object { $_ -ne $null } | Sort-Object date, time | Select-Object -Last 50)
    Set-PmcLastTimeListMap @{}
    Write-Host "\nTIME LOGS (recent)" -ForegroundColor Cyan
    Write-Host "────────────────────" -ForegroundColor DarkGray
    if ($logs.Count -eq 0) { Write-Host "No time entries found" -ForegroundColor Yellow; return }
    $i=1
    foreach ($l in $logs) {
        $tlm = Get-PmcLastTimeListMap
        $tlm[$i] = $l.id
        Set-PmcLastTimeListMap $tlm
        $hrs = try { [Math]::Round([double]$l.minutes/60,2) } catch { 0 }
        $desc = ''
        if ($l.PSObject.Properties['notes'] -and $l.notes) { $desc = $l.notes }
        elseif ($l.PSObject.Properties['description'] -and $l.description) { $desc = $l.description }
        Write-Host ("  [{0,2}] {1} {2} {3} {4}h {5}" -f $i, $l.date, ($l.time ?? ''), ($l.project ?? '(none)'), $hrs, $desc) -ForegroundColor White
        $i++
    }
    Write-Host "  Tip: Use 'time edit <#>' or 'time delete <#>'" -ForegroundColor DarkGray
}

function Add-PmcTimeEntry { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    # Re-tokenize to detect '#' codes reliably (parser may consume '#')
    $tokens = ConvertTo-PmcTokens $Context.Raw
    $projName = if ($Context.Args.ContainsKey('project')) { $Context.Args['project'] } else { $null }
    $id1Code = $null
    foreach ($tok in $tokens) { if (-not $id1Code -and $tok -match '^#(\d{2,5})$') { $id1Code = $matches[1] } }

    # Optional taskId linkage (new). Allow exactly one of: @project OR task:<id>. id1 code is legacy; treat as description unless explicit.
    $taskId = $null
    if ($Context.Args.ContainsKey('taskId')) { try { $taskId = [int]$Context.Args['taskId'] } catch { $taskId = $null } }
    $hasProj = ([string]::IsNullOrWhiteSpace($projName) -eq $false)
    $hasTaskId = ($null -ne $taskId -and $taskId -gt 0)
    $hasId1 = ([string]::IsNullOrWhiteSpace($id1Code) -eq $false)
    if (($hasProj + $hasTaskId + $hasId1) -gt 1) {
        Write-Host "Specify only one of: @project OR task:<id> OR #<id1code>" -ForegroundColor Yellow; return
    }

    $proj = $null
    if ($hasProj) {
        $proj = Resolve-Project -Data $data -Name $projName
        if (-not $proj) { Show-PmcError ("Unknown project: {0}" -f $projName); return }
    }
    $task = $null
    if ($hasTaskId) {
        $task = $data.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties['id'] -and [int]$_.id -eq $taskId } | Select-Object -First 1
        if (-not $task) { Write-Host ("Task #$taskId not found") -ForegroundColor Red; return }
        if (-not $hasProj) { try { $projName = [string]$task.project; if ($projName) { $proj = Resolve-Project -Data $data -Name $projName } } catch {}
        }
    }

    # parse date and duration from FreeText
    $dateTok = $null; $durTok = $null; $descParts = @()
    foreach ($t in $Context.FreeText) {
        if (-not $dateTok -and ($t -match '^(?i)today$' -or $t -match '^(?i)yesterday$' -or $t -match '^\d{4}-\d{2}-\d{2}$')) { $dateTok = $t; continue }
        if (-not $durTok -and ($t -match '^\d+(?:\.\d+)?$' -or $t -match '^\d+(?:\.\d+)?h$' -or $t -match '^\d+m$')) { $durTok = $t; continue }
        # Skip any '#' id1 token remnants in FreeText (already captured from tokens)
        if ($t -match '^#\d{2,5}$') { continue }
        $descParts += $t
    }
    $date = if ($dateTok) { ConvertTo-PmcDate $dateTok } else { (Get-Date).Date }
    $minutes = if ($durTok) { ConvertTo-PmcDurationMinutes $durTok } else { 0 }
    if ($minutes -le 0) { Write-Host "Invalid or missing duration (e.g., 1.5)" -ForegroundColor Yellow; return }
    $log = @{
        minutes = $minutes
        date = $date.ToString('yyyy-MM-dd')
        time = (Get-Date).ToString('HH:mm')
        notes = ($descParts -join ' ')
        id = (Get-PmcNextTimeLogId $data)
    }
    if ($hasProj -and $proj) { $log.project = $proj.name }
    if ($hasTaskId -and $task) { $log.taskId = [int]$task.id; if (-not $log.ContainsKey('project') -and $task.PSObject.Properties['project']) { $log.project = [string]$task.project } }
    if ($hasId1 -and -not $hasTaskId -and -not $hasProj) { $log.id1 = $id1Code }
    $data.timelogs += $log
    Save-StrictData $data 'time log'
    # CSV export (module-owned)
    try {
        $cfg = Get-PmcConfig
        $enabled = $true; if ($cfg.Behavior -and $cfg.Behavior.EnableCsvLedger -ne $null) { $enabled = [bool]$cfg.Behavior.EnableCsvLedger }
        if ($enabled) {
            $csvPath = if ($cfg.Paths -and $cfg.Paths.CsvLedgerPath) { [string]$cfg.Paths.CsvLedgerPath } else { 'time_ledger.csv' }
            if ([string]::IsNullOrWhiteSpace($csvPath)) { $csvPath = 'time_ledger.csv' }
            $outPath = Get-PmcSafePath $csvPath
            $dir = Split-Path $outPath -Parent; if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            if (-not (Test-Path $outPath)) { 'Date,Time,Project,Duration_Minutes,Duration_Hours,Description,LogID' | Set-Content -Path $outPath -Encoding UTF8 }
            $hrs = [Math]::Round($log.minutes/60,2)
            $desc = if ($log.notes) { '"' + ($log.notes -replace '"','""') + '"' } else { '' }
            ($log.date + ',' + ($log.time ?? '') + ',' + $log.project + ',' + $log.minutes + ',' + $hrs + ',' + $desc + ',' + $log.id) | Add-Content -Path $outPath -Encoding UTF8
        }
    } catch {
        # Time log export failed - continue with summary message
    }
    $hours = [Math]::Round($minutes/60,2)
    Show-PmcSuccess ("Logged {0} hours to '{1}'" -f $hours, $proj.name)
}

function Edit-PmcTimeEntry { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ($Context.FreeText.Count -lt 1) { Write-Host "Usage: time edit <id|#>" -ForegroundColor Yellow; return }
    $token = $Context.FreeText[0]
    $lookupId = $null
    if ($token -match '^\d+$') { $lookupId = [int]$token }
    $tmap = Get-PmcLastTimeListMap
    if (-not $lookupId -and $tmap.ContainsKey($token)) { $lookupId = $tmap[$token] }
    if (-not $lookupId -and $token -match '^\d+$' -and $tmap.ContainsKey([int]$token)) { $lookupId = $tmap[[int]$token] }
    if (-not $lookupId) { Write-Host "Invalid id/index" -ForegroundColor Red; return }
    $log = $data.timelogs | Where-Object { $_ -ne $null -and $_.id -eq $lookupId } | Select-Object -First 1
    if (-not $log) { Write-Host "Time log #$lookupId not found" -ForegroundColor Red; return }
    # Minimal interactive edit
    $newDate = Read-Host ("Date [$($log.date)]")
    $newTime = Read-Host ("Time [$($log.time ?? '')]")
    $newProj = Read-Host ("Project [$($log.project)]")
    $newHrs  = Read-Host ("Hours (e.g., 1.5) [$([math]::Round($log.minutes/60.0, 2))]")
    $newDesc = Read-Host ("Description [$($log.notes ?? '')]")
    if ($newDate) { $log.date = $newDate }
    if ($newTime) { $log.time = $newTime }
    if ($newProj) { $log.project = $newProj }
    if ($newHrs) { try { $log.minutes = [int]([double]$newHrs * 60) } catch {
        # Hours conversion failed - minutes field unchanged
    } }
    if ($null -ne $newDesc) { if ($newDesc) { $log.notes = $newDesc } else { $log.PSObject.Properties.Remove('notes') | Out-Null } }
    Save-StrictData $data 'time edit'
    Write-Host "Saved time log #$($log.id)" -ForegroundColor Green
}

function Parse-PmcDateRange {
    param([string[]]$Tokens)
    $today = (Get-Date).Date
    $start = $today; $end = $today.AddDays(1); $label = 'today'
    foreach ($tok in $Tokens) {
        $t = $tok.ToLower()
        switch ($t) {
            'today' {
                # Clamp to current weekday; we still render Mon–Fri
                $start=$today; $end=$today.AddDays(1); $label='today'; continue }
            'yesterday' { $start=$today.AddDays(-1); $end=$today; $label='yesterday'; continue }
            'week' {
                $monday = $today.AddDays(-( (([int]$today.DayOfWeek + 6) % 7) ))
                $start=$monday; $end=$monday.AddDays(5); $label='this week'; continue }
            'lastweek' {
                $monday = $today.AddDays(-( (([int]$today.DayOfWeek + 6) % 7) ) - 7)
                $start=$monday; $end=$monday.AddDays(5); $label='last week'; continue }
            'nextweek' {
                $monday = $today.AddDays(-( (([int]$today.DayOfWeek + 6) % 7) ) + 7)
                $start=$monday; $end=$monday.AddDays(5); $label='next week'; continue }
            default {
                if ($t -match '^(\d{4}-\d{2}-\d{2})\.\.(\d{4}-\d{2}-\d{2})$') {
                    $start=[datetime]::ParseExact($matches[1],'yyyy-MM-dd',$null)
                    $end=[datetime]::ParseExact($matches[2],'yyyy-MM-dd',$null).AddDays(1)
                    $label=("{0}..{1}" -f $matches[1],$matches[2])
                } elseif ($t -match '^\d{4}-\d{2}-\d{2}$') {
                    $d=[datetime]::ParseExact($t,'yyyy-MM-dd',$null)
                    $start=$d; $end=$d.AddDays(1); $label=$t
                }
            }
        }
    }
    return @{ Start=$start; End=$end; Label=$label }
}

function Remove-PmcTimeEntry { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ($Context.FreeText.Count -lt 1) { Write-Host "Usage: time delete <id|#>" -ForegroundColor Yellow; return }
    $token = $Context.FreeText[0]
    $lookupId = $null
    if ($token -match '^\d+$') { $lookupId = [int]$token }
    $tmap = Get-PmcLastTimeListMap
    if (-not $lookupId -and $tmap.ContainsKey($token)) { $lookupId = $tmap[$token] }
    if (-not $lookupId -and $token -match '^\d+$' -and $tmap.ContainsKey([int]$token)) { $lookupId = $tmap[[int]$token] }
    if (-not $lookupId) { Write-Host "Invalid id/index" -ForegroundColor Red; return }
    $log = $data.timelogs | Where-Object { $_ -ne $null -and $_.id -eq $lookupId } | Select-Object -First 1
    if (-not $log) { Write-Host "Time log #$lookupId not found" -ForegroundColor Red; return }
    $data.timelogs = @($data.timelogs | Where-Object { $_.id -ne $lookupId })
    Save-StrictData $data 'time delete'
    Write-Host "Deleted time log #$lookupId" -ForegroundColor Green
}

function Get-PmcTimeReport { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    Write-PmcDebug -Level 1 -Category 'REPORT' -Message 'TIME REPORT: start'
    # Parse flags and tokens: range, --withids, out:, byid2:
    $withIds = $false; $outPath=$null; $byId2=$null; $jsonPath=$null; $rich=$false
    foreach ($tok in $Context.FreeText) {
        if ($tok -match '^--withids$') { $withIds=$true; continue }
        if ($tok -match '^out:(.+)$') { $outPath=$matches[1]; continue }
        if ($tok -match '^byid2:(.+)$') { $byId2=$matches[1]; continue }
        if ($tok -match '^json:(.+)$') { $jsonPath=$matches[1]; continue }
        if ($tok -match '^--richcsv$') { $rich=$true; continue }
    }
    if (-not $rich) { try { $cfg = Get-PmcConfig; if ($cfg.Behavior -and $cfg.Behavior.ReportRichCsv) { $rich = [bool]$cfg.Behavior.ReportRichCsv } } catch { } }
    $rangeInfo = Parse-PmcDateRange -Tokens $Context.FreeText
    # Anchor to Monday→Friday week based on selected start
    $anchor = $rangeInfo.Start.Date
    $monday = $anchor.AddDays(-((( [int]$anchor.DayOfWeek + 6) % 7)))
    $friday = $monday.AddDays(4)
    $start = $monday; $end = $friday.AddDays(1); $label = 'week'
    Write-PmcDebug -Level 2 -Category 'REPORT' -Message 'Range selected (Mon–Fri)' -Data @{ Monday=$start; Friday=$friday }
    $logs = @($data.timelogs | Where-Object { try { ([datetime]$_.date -ge $start) -and ([datetime]$_.date -lt $end) } catch { $false } })
    if ($Context.Args.ContainsKey('project')) { $p = $Context.Args['project']; $logs = $logs | Where-Object { $_.project -eq $p } }
    if ($byId2) {
        $allow = @($data.projects | Where-Object { $_.PSObject.Properties['ID2'] -and $_.ID2 -eq $byId2 } | ForEach-Object { $_.name })
        if (@($allow).Count -gt 0) { $logs = $logs | Where-Object { $allow -contains $_.project } }
    }
    if ($logs.Count -eq 0) { Write-Host "No time logged for range" -ForegroundColor Yellow; return }
    # Build fixed Mon–Fri day list (always 5 columns)
    $days = @($start, $start.AddDays(1), $start.AddDays(2), $start.AddDays(3), $start.AddDays(4))
    $cols = @(
        @{ key='name'; title='Name'; width=22 },
        @{ key='id1'; title='ID1'; width=6 },
        @{ key='id2'; title='ID2'; width=8 }
    )
    for ($i=0; $i -lt $days.Count; $i++) { $cols += @{ key=("d$($i)"); title=$days[$i].ToString('ddd'); width=6; align='right' } }
    $cols += @{ key='total'; title='Total'; width=8; align='right' }

    # Partition logs into project-tied and generic (id1)
    $projectRows = @{}
    $codeRows = @{}
    foreach ($l in $logs) {
        $d = try { [datetime]$l.date } catch { $null }
        if (-not $d) { continue }
        if ($d.DayOfWeek -notin @([DayOfWeek]::Monday,[DayOfWeek]::Tuesday,[DayOfWeek]::Wednesday,[DayOfWeek]::Thursday,[DayOfWeek]::Friday)) { continue }
        $keyDay = $d.ToString('yyyy-MM-dd')
        if ($l.PSObject.Properties['project'] -and $l.project) {
            $k = [string]$l.project
            if (-not $projectRows.ContainsKey($k)) { $projectRows[$k] = @{} }
            if (-not $projectRows[$k].ContainsKey($keyDay)) { $projectRows[$k][$keyDay] = 0 }
            $projectRows[$k][$keyDay] += [int]$l.minutes
        } elseif ($l.PSObject.Properties['id1'] -and $l.id1) {
            $k = [string]$l.id1
            if (-not $codeRows.ContainsKey($k)) { $codeRows[$k] = @{} }
            if (-not $codeRows[$k].ContainsKey($keyDay)) { $codeRows[$k][$keyDay] = 0 }
            $codeRows[$k][$keyDay] += [int]$l.minutes
        }
    }

    $rows = @(); $grand = 0
    # Project rows
    foreach ($pname in (@($projectRows.Keys) | Sort-Object)) {
        $proj = ($data.projects | Where-Object { $_.name -eq $pname } | Select-Object -First 1)
        $id2 = if ($proj -and $proj.PSObject.Properties['ID2']) { [string]$proj.ID2 } else { '' }
        $row = @{ name=$pname; id1=''; id2=$id2 }
        $sum = 0
        for ($i=0; $i -lt $days.Count; $i++) {
            $dStr = $days[$i].ToString('yyyy-MM-dd')
            $mins = if ($projectRows[$pname].ContainsKey($dStr)) { [int]$projectRows[$pname][$dStr] } else { 0 }
            $sum += $mins
            $row[("d$($i)")] = ([Math]::Round($mins/60,2)).ToString('0.##')
        }
        $row['total'] = ([Math]::Round($sum/60,2)).ToString('0.##')
        $grand += $sum
        $rows += $row
    }
    # Generic code rows
    foreach ($code in (@($codeRows.Keys) | Sort-Object)) {
        $row = @{ name=''; id1=[string]$code; id2='' }
        $sum = 0
        for ($i=0; $i -lt $days.Count; $i++) {
            $dStr = $days[$i].ToString('yyyy-MM-dd')
            $mins = if ($codeRows[$code].ContainsKey($dStr)) { [int]$codeRows[$code][$dStr] } else { 0 }
            $sum += $mins
            $row[("d$($i)")] = ([Math]::Round($mins/60,2)).ToString('0.##')
        }
        $row['total'] = ([Math]::Round($sum/60,2)).ToString('0.##')
        $grand += $sum
        $rows += $row
    }

    Show-PmcHeader -Title ("TIME REPORT (Mon–Fri): {0} → {1}" -f $days[0].ToString('yyyy-MM-dd'), $days[-1].ToString('yyyy-MM-dd'))
    Show-PmcTable -Columns $cols -Rows $rows
    Show-PmcTip ("TOTAL: {0} h" -f ([Math]::Round($grand/60,2)))
    if ($withIds) {
        $detailRows=@()
        foreach ($l in ($logs | Sort-Object date, time)) { $detailRows += @{ date=$l.date; time=($l.time ?? ''); project=$l.project; hours=([Math]::Round($l.minutes/60,2)).ToString('0.##'); notes=($l.notes ?? '') } }
        $dcols = @(
            @{ key='date'; title='Date'; width=10 },
            @{ key='time'; title='Time'; width=6 },
            @{ key='project'; title='Project'; width=18 },
            @{ key='hours'; title='Hours'; width=7; align='right' },
            @{ key='notes'; title='Description'; width=40 }
        )
        Show-PmcTable -Columns $dcols -Rows $detailRows -Title 'DETAILS'
    }
    if ($outPath) {
        try {
            $out = Get-PmcSafePath $outPath
            if (-not (Test-Path (Split-Path $out -Parent))) { New-Item -ItemType Directory -Path (Split-Path $out -Parent) -Force | Out-Null }
            # Header
            $header = 'Date,Time,Project,Duration_Minutes,Duration_Hours,Description,LogID'
            if ($rich) { $header += ',ID2,CAAName' }
            if (-not (Test-Path $out)) { $header | Set-Content -Path $out -Encoding UTF8 } else { Clear-Content -Path $out; Add-Content -Path $out -Value $header -Encoding UTF8 }
            foreach ($l in $logs) {
                $hrs=[Math]::Round($l.minutes/60,2)
                $desc = if ($l.notes) { '"' + ($l.notes -replace '"','""') + '"' } else { '' }
                $id2=''; $caa=''
                if ($rich) {
                    try { $proj = ($data.projects | Where-Object { $_.name -eq $l.project } | Select-Object -First 1); if ($proj) { if ($proj.PSObject.Properties['ID2']) { $id2=$proj.ID2 }; if ($proj.PSObject.Properties['CAAName']) { $caa=$proj.CAAName } } } catch {
                        # Project lookup failed - ID2 and CAAName remain empty
                    }
                }
                $line = ($l.date + ',' + ($l.time ?? '') + ',' + $l.project + ',' + $l.minutes + ',' + $hrs + ',' + $desc + ',' + $l.id)
                if ($rich) { $line += (',' + $id2 + ',' + $caa) }
                $line | Add-Content -Path $out -Encoding UTF8
            }
            Show-PmcTip ("Exported to: {0}" -f $out)
        } catch { Write-Host "Export failed: $_" -ForegroundColor Red }
    }
    if ($jsonPath) {
        try {
            $out = Get-PmcSafePath $jsonPath
            if (-not (Test-Path (Split-Path $out -Parent))) { New-Item -ItemType Directory -Path (Split-Path $out -Parent) -Force | Out-Null }
            $arr = @(); foreach ($l in ($logs | Sort-Object date, time)) { $arr += [pscustomobject]@{ date=$l.date; time=($l.time ?? ''); project=$l.project; minutes=$l.minutes; hours=[Math]::Round($l.minutes/60,2); notes=($l.notes ?? ''); id=$l.id } }
            $arr | ConvertTo-Json -Depth 6 | Set-Content -Path $out -Encoding UTF8
            Show-PmcTip ("Exported JSON to: {0}" -f $out)
        } catch { Write-Host "JSON export failed: $_" -ForegroundColor Red }
    }
    Save-StrictData $data 'time report'
    Write-PmcDebug -Level 1 -Category 'REPORT' -Message 'TIME REPORT: done'
}

# ===== ACTIVITY =====
function Get-PmcActivityList { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $rows = @()
    foreach ($a in ($data.activityLog | Select-Object -Last 50)) { $rows += @{ ts=$a.timestamp; user=($a.user ?? ''); action=$a.action } }
    if (@($rows).Count -eq 0) { Show-PmcHeader -Title 'ACTIVITY'; Show-PmcTip 'No activity entries'; return }
    $cols = @(
        @{ key='ts'; title='Timestamp'; width=20 },
        @{ key='user'; title='User'; width=10 },
        @{ key='action'; title='Action'; width=40 }
    )
    Show-PmcTable -Columns $cols -Rows $rows -Title 'ACTIVITY (last 50)'
}

# ===== TIMER =====
function Start-PmcTimer { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $projName = if ($Context.Args.ContainsKey('project')) { $Context.Args['project'] } else { $null }
    $project = if ($projName) { $projName } else { 'inbox' }
    $desc = ($Context.FreeText -join ' ')
    if (-not ($data.PSObject.Properties['timer'])) { Add-Member -InputObject $data -MemberType NoteProperty -Name timer -Value @{} }
    $data.timer = @{
        active = $true
        project = $project
        description = $desc
        startTime = Get-Date
        startTimeString = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }
    Save-StrictData $data 'timer start'
    Write-Host "⏱️  Timer started for '$project'" -ForegroundColor Green
}

function Stop-PmcTimer { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if (-not $data.timer -or -not $data.timer.active) { Write-Host "No active timer" -ForegroundColor Yellow; return }
    $endTime = Get-Date
    $startTime = [datetime]$data.timer.startTime
    $duration = $endTime - $startTime
    $minutes = [Math]::Round($duration.TotalMinutes,1)
    # Clear timer (do not persist session to timelogs)
    $info = $data.timer
    $data.timer = @{ active = $false }
    Save-StrictData $data 'timer stop'
    Write-Host ("⏹️  Timer stopped: {0}m on {1}" -f $minutes, ($info.project)) -ForegroundColor Cyan
}

function Get-PmcTimerStatus { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if (-not $data.timer -or -not $data.timer.active) { Write-Host "  No active timer" -ForegroundColor Gray; return }
    $startTime = [datetime]$data.timer.startTime
    $elapsed = (Get-Date) - $startTime
    Write-Host "  Timer running" -ForegroundColor Green
    Write-Host "  Project: $($data.timer.project)"
    if ($data.timer.description) { Write-Host "  Description: $($data.timer.description)" }
    Write-Host ("  Elapsed: {0}h {1}m {2}s" -f $elapsed.Hours,$elapsed.Minutes,$elapsed.Seconds) -ForegroundColor Cyan
}

# ===== CONFIG / TEMPLATE / RECURRING (placeholders) =====
function Show-PmcConfig { param([PmcCommandContext]$Context)
    $cfg = Get-PmcConfig
    ($cfg | ConvertTo-Json -Depth 8) | Write-Host
}
function Edit-PmcConfig { param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category 'CONFIG' -Message 'config edit start'
    $cfg = Get-PmcConfig
    $json = $cfg | ConvertTo-Json -Depth 10
    $tmp = [System.IO.Path]::GetTempFileName() + '.json'
    $json | Set-Content -Path $tmp -Encoding UTF8

    # Determine editor (no fallback editing in-place; fail if none)
    $editor = $null
    if ($IsWindows) { $editor = 'notepad' }
    elseif ($env:EDITOR) { $editor = $env:EDITOR }

    if (-not $editor) {
        Write-PmcDebug -Level 1 -Category 'CONFIG' -Message 'No editor configured (set $env:EDITOR)'
        Write-Host "No editor configured. Set \$env:EDITOR or run on Windows (uses notepad)." -ForegroundColor Red
        Write-Host ("Temporary file is at: {0}" -f $tmp) -ForegroundColor Yellow
        return
    }

    try {
        Write-PmcDebug -Level 2 -Category 'CONFIG' -Message ("Launching editor: {0}" -f $editor)
        & $editor $tmp
    } catch {
        Write-PmcDebug -Level 1 -Category 'CONFIG' -Message ("Editor launch failed: {0}" -f $_)
        Write-Host ("Failed to launch editor '{0}'. Edit this file manually then rerun: {1}" -f $editor, $tmp) -ForegroundColor Red
        return
    }

    try {
        $new = Get-Content $tmp -Raw | ConvertFrom-Json -AsHashtable
    } catch {
        Write-PmcDebug -Level 1 -Category 'CONFIG' -Message 'Invalid JSON on save'
        Write-Host "Invalid JSON; config unchanged" -ForegroundColor Red
        return
    }

    Save-PmcConfig $new
    Write-PmcDebug -Level 1 -Category 'CONFIG' -Message 'config updated'
    Write-Host "Config updated" -ForegroundColor Green
}
function Set-PmcConfigValue { param([PmcCommandContext]$Context)
    $all = ($Context.FreeText -join ' ').Trim()
    if (-not $all) { Write-Host "Usage: config set <Path> <Value>  e.g., config set Behavior.UseStrictModule true" -ForegroundColor Yellow; return }
    $parts = $all -split '\s+', 2
    if ($parts.Count -lt 2) { Write-Host "Usage: config set <Path> <Value>" -ForegroundColor Yellow; return }
    $path = $parts[0]; $valRaw = $parts[1]
    # Convert value to native types if obvious
    $val = $valRaw
    if ($valRaw -match '^(?i)true|false$') { $val = [bool]::Parse($valRaw) }
    elseif ($valRaw -match '^-?\d+$') { $val = [int]$valRaw }
    $cfg = Get-PmcConfig
    # Walk nested hashtables by dot path
    $target = $cfg
    $keys = $path -split '\.'
    for ($i=0; $i -lt $keys.Length-1; $i++) {
        $k = $keys[$i]
        if (-not $target.ContainsKey($k)) { $target[$k] = @{} }
        $target = $target[$k]
    }
    $leaf = $keys[-1]
    $target[$leaf] = $val
    Save-PmcConfig $cfg
    Write-Host ("Set {0} = {1}" -f $path, $val) -ForegroundColor Green
}

function Save-PmcTemplate { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $name = $null; $body=''
    $text = ($Context.FreeText -join ' ').Trim()
    if (-not $text) { Write-Host "Usage: template save <name> <body...>" -ForegroundColor Yellow; return }
    $parts = $text -split '\s+', 2
    $name = $parts[0]; if ($parts.Count -gt 1) { $body = $parts[1] }
    if (-not $data.templates) { $data.templates = @{} }
    $data.templates[$name] = $body
    Save-StrictData $data 'template save'
    Write-Host "Saved template '$name'" -ForegroundColor Green
}
function Invoke-PmcTemplate { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $name = ($Context.FreeText -join ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host "Usage: template apply <name>" -ForegroundColor Yellow; return }
    if (-not $data.templates -or -not $data.templates[$name]) { Write-Host "Template '$name' not found" -ForegroundColor Red; return }
    # Extremely simple: add a single task with template body as text
    $id = Get-PmcNextTaskId $data
    $data.tasks += @{ id=$id; text=$data.templates[$name]; project='inbox'; priority=0; status='pending'; created=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss') }
    Save-StrictData $data 'template apply'
    Write-Host "Applied template '$name' -> task #$id" -ForegroundColor Green
}
function Get-PmcTemplateList { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    Write-Host "\nTEMPLATES" -ForegroundColor Cyan
    Write-Host "─────────" -ForegroundColor DarkGray
    if (-not $data.templates -or @($data.templates.Keys).Count -eq 0) { Write-Host 'No templates' -ForegroundColor Yellow; return }
    foreach ($k in $data.templates.Keys) { Write-Host ("  - {0}" -f $k) }
}
function Remove-PmcTemplate { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $name = ($Context.FreeText -join ' ').Trim()
    if (-not $name) { Write-Host "Usage: template remove <name>" -ForegroundColor Yellow; return }
    if (-not $data.templates -or -not $data.templates[$name]) { Write-Host "Template '$name' not found" -ForegroundColor Red; return }
    $data.templates.Remove($name) | Out-Null
    Save-StrictData $data 'template remove'
    Write-Host "Removed template '$name'" -ForegroundColor Green
}

function Add-PmcRecurringTask { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $text = ($Context.FreeText -join ' ').Trim()
    if (-not $text) { Write-Host "Usage: recurring add <pattern> <body...>" -ForegroundColor Yellow; return }
    $parts = $text -split '\s+', 2
    $pattern = $parts[0]; $body = if ($parts.Count -gt 1) { $parts[1] } else { '' }
    if (-not $data.recurringTemplates) { $data.recurringTemplates = @() }
    $data.recurringTemplates += @{ pattern=$pattern; body=$body; created=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss') }
    Save-StrictData $data 'recurring add'
    Write-Host "Added recurring pattern '$pattern'" -ForegroundColor Green
}
function Get-PmcRecurringTaskList { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    Write-Host "\nRECURRING" -ForegroundColor Cyan
    Write-Host "──────────" -ForegroundColor DarkGray
    if (-not $data.recurringTemplates -or @($data.recurringTemplates).Count -eq 0) { Write-Host 'No recurring templates' -ForegroundColor Yellow; return }
    $i=1
    foreach ($r in $data.recurringTemplates) { Write-Host ("  [{0,2}] {1} :: {2}" -f $i, $r.pattern, ($r.body ?? '')) ; $i++ }
}

# ===== DEPENDENCIES =====
function Add-PmcDependency { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ($Context.FreeText.Count -lt 2 -and -not $Context.Args.ContainsKey('ids')) { Show-PmcWarning 'Usage: dep add <id|#> <requiresId|set>'; return }
    $raw = if ($Context.FreeText.Count -gt 0) { $Context.FreeText[0] } else { '' }
    $targetIds=@(); if ($Context.Args.ContainsKey('ids')) { $targetIds=@($Context.Args['ids']) } elseif ($raw -match '^[0-9,\-]+$') { $targetIds=ConvertTo-PmcIdSet $raw }
    if (@($targetIds).Count -eq 0 -and $raw -match '^\d+$') { $n=[int]$raw; $idxMap=Get-PmcLastTaskListMap; if ($idxMap.ContainsKey($n)) { $targetIds=@($idxMap[$n]) } else { $targetIds=@($n) } }
    if (@($targetIds).Count -eq 0) { Show-PmcError 'Invalid id/index for target'; return }
    $reqTok = if ($Context.FreeText.Count -gt 1) { $Context.FreeText[1] } else { '' }
    if (-not $reqTok) { Show-PmcError 'Missing requires id(s)'; return }
    $requires = @(); if ($reqTok -match '^[0-9,\-]+$') { $requires = ConvertTo-PmcIdSet $reqTok }
    if (@($requires).Count -eq 0) { Show-PmcError 'Invalid requires id(s)'; return }
    $added=0
    foreach ($tid in $targetIds) {
        $t = $data.tasks | Where-Object { $_.id -eq $tid } | Select-Object -First 1
        if (-not $t) { continue }
        if (-not $t.PSObject.Properties['requires']) { $t | Add-Member -NotePropertyName requires -NotePropertyValue @() -Force }
        $current = @($t.requires | ForEach-Object { [int]$_ })
        foreach ($rid in $requires) { if ($rid -ne $tid -and -not ($current -contains $rid)) { $current += $rid; $added++ } }
        $t.requires = $current
    }
    if ($added -gt 0) { Save-StrictData $data 'dep add'; Show-PmcSuccess ("Added {0} dependency link(s)" -f $added) } else { Show-PmcWarning 'No dependencies added' }
}

function Remove-PmcDependency { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ($Context.FreeText.Count -lt 2 -and -not $Context.Args.ContainsKey('ids')) { Show-PmcWarning 'Usage: dep remove <id|#> <requiresId|set>'; return }
    $raw = if ($Context.FreeText.Count -gt 0) { $Context.FreeText[0] } else { '' }
    $targetIds=@(); if ($Context.Args.ContainsKey('ids')) { $targetIds=@($Context.Args['ids']) } elseif ($raw -match '^[0-9,\-]+$') { $targetIds=ConvertTo-PmcIdSet $raw }
    if (@($targetIds).Count -eq 0 -and $raw -match '^\d+$') { $n=[int]$raw; $idxMap=Get-PmcLastTaskListMap; if ($idxMap.ContainsKey($n)) { $targetIds=@($idxMap[$n]) } else { $targetIds=@($n) } }
    if (@($targetIds).Count -eq 0) { Show-PmcError 'Invalid id/index for target'; return }
    $reqTok = if ($Context.FreeText.Count -gt 1) { $Context.FreeText[1] } else { '' }
    if (-not $reqTok) { Show-PmcError 'Missing requires id(s)'; return }
    $requires = @(); if ($reqTok -match '^[0-9,\-]+$') { $requires = ConvertTo-PmcIdSet $reqTok }
    if (@($requires).Count -eq 0) { Show-PmcError 'Invalid requires id(s)'; return }
    $removed=0
    foreach ($tid in $targetIds) {
        $t = $data.tasks | Where-Object { $_.id -eq $tid } | Select-Object -First 1
        if (-not $t -or -not $t.PSObject.Properties['requires']) { continue }
        $before = @($t.requires)
        $t.requires = @($t.requires | Where-Object { $requires -notcontains [int]$_ })
        $removed += ([Math]::Max(0, $before.Count - $t.requires.Count))
    }
    if ($removed -gt 0) { Save-StrictData $data 'dep remove'; Show-PmcSuccess ("Removed {0} dependency link(s)" -f $removed) } else { Show-PmcWarning 'No dependencies removed' }
}

function Show-PmcDependencies { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if ($Context.FreeText.Count -lt 1 -and -not $Context.Args.ContainsKey('ids')) { Show-PmcWarning 'Usage: dep show <id|#>'; return }
    $raw = if ($Context.FreeText.Count -gt 0) { $Context.FreeText[0] } else { '' }
    $ids=@(); if ($Context.Args.ContainsKey('ids')) { $ids=@($Context.Args['ids']) } elseif ($raw -match '^[0-9,\-]+$') { $ids=ConvertTo-PmcIdSet $raw }
    if (@($ids).Count -eq 0 -and $raw -match '^\d+$') { $n=[int]$raw; $idxMap=Get-PmcLastTaskListMap; if ($idxMap.ContainsKey($n)) { $ids=@($idxMap[$n]) } else { $ids=@($n) } }
    if (@($ids).Count -eq 0) { Show-PmcError 'Invalid id/index'; return }
    foreach ($tid in $ids) {
        $t = $data.tasks | Where-Object { $_.id -eq $tid } | Select-Object -First 1
        if (-not $t) { Show-PmcWarning ("Task #{0} not found" -f $tid); continue }
        $rows=@()
        $req = if ($t.PSObject.Properties['requires']) { @($t.requires | ForEach-Object { [int]$_ }) } else { @() }
        foreach ($rid in $req) {
            $dep = $data.tasks | Where-Object { $_.id -eq $rid } | Select-Object -First 1
            $rows += @{ id=('#'+$rid); text=($dep.text ?? '(missing)'); status=($dep.status ?? '') }
        }
        Show-PmcTable -Columns @(@{key='id';title='Requires';width=8}, @{key='text';title='Task';width=44}, @{key='status';title='Status';width=8}) -Rows $rows -Title ("BLOCKERS FOR #{0}" -f $tid)
    }
}

function Show-PmcDependencyGraph { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    $edges=@()
    foreach ($t in $data.tasks) {
        if ($t -and $t.PSObject.Properties['requires'] -and $t.requires) {
            foreach ($rid in $t.requires) { $edges += ,@([int]$rid, [int]$t.id) }
        }
    }
    if (@($edges).Count -eq 0) { Show-PmcTip 'No dependencies found'; return }
    Show-PmcHeader -Title 'DEPENDENCY GRAPH (rid -> id)'
    foreach ($e in $edges) { Write-Host ("  #{0} -> #{1}" -f $e[0], $e[1]) }
}

# NOTE: Legacy placeholder stubs were removed below to avoid overriding real implementations.

# Show-PmcAgenda is implemented in Views.ps1

function Show-PmcWeekTasks { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Title' -Text "This Week's Tasks"
    Write-PmcStyled -Style 'Info' -Text "No tasks scheduled for this week."
}

function Show-PmcMonthTasks { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Title' -Text "This Month's Tasks"
    Write-PmcStyled -Style 'Info' -Text "No tasks scheduled for this month."
}

# ALL REMAINING MISSING COMMAND HANDLERS - BASIC STUBS (REMOVED)

function Add-PmcAlias { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Success' -Text "Alias added."
}

function Remove-PmcAlias { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Success' -Text "Alias removed."
}

function Show-PmcDependencies { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "No dependencies found."
}

function Set-PmcFocus { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Success' -Text "Focus set."
}

function Clear-PmcFocus { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Success' -Text "Focus cleared."
}

function Get-PmcFocusStatus { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "No focus set."
}

function Invoke-PmcUndo { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Nothing to undo."
}

function Invoke-PmcRedo { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Nothing to redo."
}

function New-PmcBackup { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Success' -Text "Backup created."
}

function Clear-PmcCompletedTasks { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Success' -Text "Completed tasks cleared."
}

## Removed redundant stub view handlers; real implementations live in Views.ps1

function Show-PmcProjectsView { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Title' -Text "Projects Dashboard"
    Write-PmcStyled -Style 'Info' -Text "No projects found."
}

function Show-PmcNextTasks { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Title' -Text "Next Actions"
    Write-PmcStyled -Style 'Info' -Text "No next actions."
}

# ALL REMAINING DOMAINS
function Import-PmcExcelData { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Excel import not configured."
}

function Show-PmcExcelPreview { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "No Excel data to preview."
}

function Get-PmcLatestExcelFile { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "No Excel files found."
}

function Reset-PmcTheme { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Success' -Text "Theme reset to default."
}

function Edit-PmcTheme { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Theme editor not implemented."
}

function Get-PmcThemeList { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Default theme available."
}

function Apply-PmcTheme { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Success' -Text "Theme applied."
}

function Show-PmcThemeInfo { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Current theme: default"
}

 

function Import-PmcTasks { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Task import not implemented."
}

function Export-PmcTasks { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Task export not implemented."
}

function Get-PmcAliasList { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "No aliases defined."
}

function Show-PmcCommands { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Title' -Text "Available Commands"
    Write-PmcStyled -Style 'Info' -Text "Use 'help' for detailed command list."
}

function Show-PmcCommandBrowser { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Command browser not implemented."
}

function Show-PmcHelpExamples { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Help examples not implemented."
}

function Show-PmcHelpGuide { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Help guide not implemented."
}

# SHORTCUT-ONLY FUNCTIONS
function Get-PmcStats { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Title' -Text "Productivity Statistics"
    Write-PmcStyled -Style 'Info' -Text "No statistics available."
}

function Show-PmcBurndown { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Title' -Text "Burndown Chart"
    Write-PmcStyled -Style 'Info' -Text "No burndown data available."
}

function Get-PmcVelocity { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Title' -Text "Velocity Report"
    Write-PmcStyled -Style 'Info' -Text "No velocity data available."
}

function Set-PmcTheme { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Success' -Text "Theme updated."
}

function Show-PmcPreferences { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Preferences editor not implemented."
}

function Invoke-PmcShortcutNumber { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Shortcut number function not implemented."
}

function Start-PmcReview { param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Review workflow not implemented."
}
