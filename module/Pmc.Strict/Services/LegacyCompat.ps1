Set-StrictMode -Version Latest

# Helper: get and save data
function _Get-PmcData() { return Get-PmcDataAlias }
function _Save-PmcData($data,$action='') { Save-StrictData $data $action }

# Legacy compatibility wrapper
function Get-PmcData() { return Get-PmcDataAlias }

# Helper: resolve task ids from context
function _Resolve-TaskIds {
    param([PmcCommandContext]$Context)
    $ids = @()
    if ($Context.Args.ContainsKey('ids')) { $ids = @($Context.Args['ids']) }
    elseif (@($Context.FreeText).Count -gt 0) {
        $t0 = [string]$Context.FreeText[0]
        if ($t0 -match '^[0-9,\-]+$') {
            $ids = @($t0 -split ',' | ForEach-Object { if ($_ -match '^\d+$') { [int]$_ } })
        } elseif ($t0 -match '^\d+$') { $ids = @([int]$t0) }
    }
    return ,$ids
}

# Task domain wrappers
function Show-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context
    $data = _Get-PmcData
    $rows = if ($ids.Count -gt 0) { @($data.tasks | Where-Object { $_.id -in $ids }) } else { @() }
    Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $rows -Title 'Task'
}

function Set-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context
    if ($ids.Count -eq 0) { Write-PmcStyled -Style 'Warning' -Text 'No task id provided'; return }
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) {
        foreach ($k in $Context.Args.Keys) { if ($k -ne 'ids') { try { $t | Add-Member -NotePropertyName $k -NotePropertyValue $Context.Args[$k] -Force } catch {} } }
    }
    _Save-PmcData $data 'task:update'
    Write-PmcStyled -Style 'Success' -Text ("✓ Updated {0} task(s)" -f $ids.Count)
}

function Complete-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; if ($ids.Count -eq 0) { return }
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) { $t.status = 'completed'; $t.completed = (Get-Date).ToString('o') }
    _Save-PmcData $data 'task:done'
    Write-PmcStyled -Style 'Success' -Text ("✓ Completed {0} task(s)" -f $ids.Count)
}

function Remove-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; if ($ids.Count -eq 0) { return }
    $data = _Get-PmcData
    $data.tasks = @($data.tasks | Where-Object { $_.id -notin $ids })
    _Save-PmcData $data 'task:remove'
    Write-PmcStyled -Style 'Warning' -Text ("✗ Removed {0} task(s)" -f $ids.Count)
}

function Move-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; $proj = [string]$Context.Args['project']
    if ($ids.Count -eq 0 -or [string]::IsNullOrWhiteSpace($proj)) { return }
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) { $t.project = $proj }
    _Save-PmcData $data 'task:move'
    Write-PmcStyled -Style 'Success' -Text ("✓ Moved {0} task(s) to @{1}" -f $ids.Count,$proj)
}

function Set-PmcTaskPostponed { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; $days = 1; if ($Context.Args['days']) { $days = [int]$Context.Args['days'] }
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) {
        $d = if ($t.due) { [datetime]$t.due } else { (Get-Date) }
        $t.due = $d.AddDays($days).ToString('yyyy-MM-dd')
    }
    _Save-PmcData $data 'task:postpone'
    Write-PmcStyled -Style 'Success' -Text ("✓ Postponed {0} task(s) by {1} day(s)" -f $ids.Count,$days)
}

function Copy-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; if ($ids.Count -eq 0) { return }
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) {
        $clone = $t.PSObject.Copy(); $clone.id = ($data.tasks | ForEach-Object { $_.id } | Measure-Object -Maximum).Maximum + 1
        $data.tasks += $clone
    }
    _Save-PmcData $data 'task:copy'
    Write-PmcStyled -Style 'Success' -Text ("✓ Duplicated {0} task(s)" -f $ids.Count)
}

function Add-PmcTaskNote { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; $note = ($Context.FreeText | Select-Object -Skip 1) -join ' '
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) { if (-not $t.notes) { $t.notes=@() }; $t.notes += $note }
    _Save-PmcData $data 'task:note'
}

function Edit-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; $text = ($Context.FreeText | Select-Object -Skip 1) -join ' '
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) { $t.text = $text }
    _Save-PmcData $data 'task:edit'
}

function Find-PmcTask { param([PmcCommandContext]$Context)
    $needle = ($Context.FreeText -join ' ')
    $res = Invoke-PmcEnhancedQuery -Tokens @('tasks',$needle)
    Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title "Search: $needle"
}

function Set-PmcTaskPriority { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; $p = [string]$Context.Args['priority']
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) { $t.priority = $p }
    _Save-PmcData $data 'task:priority'
}

function Show-PmcAgenda { $res = Invoke-PmcEnhancedQuery -Tokens @('tasks','due:today'); Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title 'Agenda' }
function Show-PmcWeekTasksInteractive { $res = Invoke-PmcEnhancedQuery -Tokens @('tasks','due:+7'); Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title 'Week' -Interactive }
function Show-PmcMonthTasksInteractive { $res = Invoke-PmcEnhancedQuery -Tokens @('tasks','due:eom'); Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title 'Month' -Interactive }

function Show-PmcTodayTasksInteractive { $res = Invoke-PmcEnhancedQuery -Tokens @('tasks','due:today'); Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title 'Today' -Interactive }
function Show-PmcOverdueTasksInteractive { $res = Invoke-PmcEnhancedQuery -Tokens @('tasks','overdue'); Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title 'Overdue' -Interactive }
function Show-PmcProjectsInteractive { $res = Invoke-PmcEnhancedQuery -Tokens @('projects'); Show-PmcDataGrid -Domains @('project') -Columns (Get-PmcDefaultColumns -DataType 'project') -Data $res.Data -Title 'Projects' -Interactive }
function Show-PmcAllTasksInteractive { $res = Invoke-PmcEnhancedQuery -Tokens @('tasks'); Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title 'All Tasks' -Interactive }

# Project domain wrappers
function Show-PmcProject { param([PmcCommandContext]$Context)
    $name = if (@($Context.FreeText).Count -gt 0) { [string]$Context.FreeText[0] } else { '' }
    $data = _Get-PmcData
    $rows = @($data.projects | Where-Object { $_.name -eq $name })
    Show-PmcDataGrid -Domains @('project') -Columns (Get-PmcDefaultColumns -DataType 'project') -Data $rows -Title 'Project'
}

function Set-PmcProject { param([PmcCommandContext]$Context)
    $name = if (@($Context.FreeText).Count -gt 0) { [string]$Context.FreeText[0] } else { '' }
    $data = _Get-PmcData
    $p = @($data.projects | Where-Object { $_.name -eq $name }) | Select-Object -First 1
    if (-not $p) { Write-PmcStyled -Style 'Warning' -Text "Project not found"; return }
    foreach ($k in $Context.Args.Keys) { try { $p | Add-Member -NotePropertyName $k -NotePropertyValue $Context.Args[$k] -Force } catch {} }
    _Save-PmcData $data 'project:update'
    Write-PmcStyled -Style 'Success' -Text ("✓ Updated project: {0}" -f $name)
}

function Rename-PmcProject { param([PmcCommandContext]$Context)
    if (@($Context.FreeText).Count -lt 2) { return }
    $old = [string]$Context.FreeText[0]; $new = [string]$Context.FreeText[1]
    $data = _Get-PmcData
    $p = @($data.projects | Where-Object { $_.name -eq $old }) | Select-Object -First 1
    if ($p) { $p.name = $new; _Save-PmcData $data 'project:rename'; Write-PmcStyled -Style 'Success' -Text ("✓ Renamed project to {0}" -f $new) }
}

function Remove-PmcProject { param([PmcCommandContext]$Context)
    $name = if (@($Context.FreeText).Count -gt 0) { [string]$Context.FreeText[0] } else { '' }
    $data = _Get-PmcData
    $data.projects = @($data.projects | Where-Object { $_.name -ne $name })
    _Save-PmcData $data 'project:remove'
}

function Set-PmcProjectArchived { param([PmcCommandContext]$Context)
    $name = if (@($Context.FreeText).Count -gt 0) { [string]$Context.FreeText[0] } else { '' }
    $data = _Get-PmcData
    $p = @($data.projects | Where-Object { $_.name -eq $name }) | Select-Object -First 1
    if ($p) { $p.status = 'archived'; _Save-PmcData $data 'project:archive' }
}

function Set-PmcProjectFields { param([PmcCommandContext]$Context) Set-PmcProject -Context $Context }
function Show-PmcProjectFields { $schemas = Get-PmcFieldSchemasForDomain -Domain 'project'; $rows=@(); foreach ($k in $schemas.Keys) { $rows += [pscustomobject]@{ Field=$k; Type=$schemas[$k].Type } }; Show-PmcDataGrid -Domains @('project-fields') -Columns @{ Field=@{Header='Field';Width=24}; Type=@{Header='Type';Width=12} } -Data $rows -Title 'Project Fields' }
function Get-PmcProjectStats { $data=_Get-PmcData; $rows=@(); foreach ($p in $data.projects) { $c = @($data.tasks | Where-Object { $_.project -eq $p.name }).Count; $rows += [pscustomobject]@{ Project=$p.name; Tasks=$c } }; return $rows }
function Show-PmcProjectInfo { $data=_Get-PmcData; $rows=@(); foreach ($p in $data.projects) { $rows += [pscustomobject]@{ Project=$p.name; Status=$p.status; Created=$p.created } }; Show-PmcDataGrid -Domains @('project-info') -Columns @{ Project=@{Header='Project';Width=24}; Status=@{Header='Status';Width=10}; Created=@{Header='Created';Width=24} } -Data $rows -Title 'Projects Info' }
function Get-PmcRecentProjects { $data=_Get-PmcData; return @($data.projects | Sort-Object { try { [datetime]$_.created } catch { Get-Date } } -Descending | Select-Object -First 10) }

# Time domain wrappers (edit/delete)
function Edit-PmcTimeEntry { param([PmcCommandContext]$Context)
    $id = 0; if ($Context.Args['id']) { $id = [int]$Context.Args['id'] } elseif (@($Context.FreeText).Count -gt 0) { $id = [int]$Context.FreeText[0] }
    $data=_Get-PmcData; $e=@($data.timelogs | Where-Object { $_.id -eq $id }) | Select-Object -First 1
    if ($e) { foreach ($k in $Context.Args.Keys) { if ($k -ne 'id') { $e | Add-Member -NotePropertyName $k -NotePropertyValue $Context.Args[$k] -Force } } ; _Save-PmcData $data 'time:edit' }
}
function Remove-PmcTimeEntry { param([PmcCommandContext]$Context)
    $id = 0; if ($Context.Args['id']) { $id = [int]$Context.Args['id'] } elseif (@($Context.FreeText).Count -gt 0) { $id = [int]$Context.FreeText[0] }
    $data=_Get-PmcData; $data.timelogs = @($data.timelogs | Where-Object { $_.id -ne $id }); _Save-PmcData $data 'time:remove'
}

# Alias wrappers
function Add-PmcAlias { param([PmcCommandContext]$Context)
    $name = if (@($Context.FreeText).Count -gt 0) { [string]$Context.FreeText[0] } else { '' }
    $value = if (@($Context.FreeText).Count -gt 1) { ($Context.FreeText | Select-Object -Skip 1) -join ' ' } else { '' }
    $data=_Get-PmcData; if (-not $data.aliases) { $data | Add-Member -NotePropertyName aliases -NotePropertyValue @{} -Force }
    $data.aliases[$name] = $value; _Save-PmcData $data 'alias:add'
}
function Remove-PmcAlias { param([PmcCommandContext]$Context)
    $name = if (@($Context.FreeText).Count -gt 0) { [string]$Context.FreeText[0] } else { '' }
    $data=_Get-PmcData; if ($data.aliases) { $data.aliases.Remove($name) | Out-Null }; _Save-PmcData $data 'alias:remove'
}
function Get-PmcAliasList { $data=_Get-PmcData; $rows=@(); if ($data.aliases) { foreach ($k in $data.aliases.Keys) { $rows += [pscustomobject]@{ Name=$k; Value=$data.aliases[$k] } } }; Show-PmcDataGrid -Domains @('aliases') -Columns @{ Name=@{Header='Name';Width=20}; Value=@{Header='Value';Width=60} } -Data $rows -Title 'Aliases' }

# System wrappers
function New-PmcBackup { $file = (Get-Item (Get-PmcTaskFilePath)).FullName; $dest = "$file.bak_$(Get-Date -Format yyyyMMdd_HHmmss)"; Copy-Item $file $dest -Force; Write-PmcStyled -Style 'Success' -Text ("Backup created: {0}" -f (Split-Path $dest -Leaf)) }
function Clear-PmcCompletedTasks { $data=_Get-PmcData; $before=@($data.tasks).Count; $data.tasks=@($data.tasks | Where-Object { $_.status -ne 'completed' }); _Save-PmcData $data 'system:clean'; Write-PmcStyled -Style 'Warning' -Text ("Removed {0} completed task(s)" -f ($before-@($data.tasks).Count)) }
function Invoke-PmcUndo { Write-PmcStyled -Style 'Warning' -Text 'Undo not available (legacy in-memory undo removed)'; }
function Invoke-PmcRedo { Write-PmcStyled -Style 'Warning' -Text 'Redo not available (legacy in-memory redo removed)'; }

# Import/Export and Excel/XFlow stubs
function Import-PmcTasks { Write-PmcStyled -Style 'Warning' -Text 'Import is temporarily unavailable in enhanced mode' }
function Export-PmcTasks { Write-PmcStyled -Style 'Warning' -Text 'Export is temporarily unavailable in enhanced mode' }
function Import-PmcExcelData { Write-PmcStyled -Style 'Warning' -Text 'Excel integration is temporarily unavailable in enhanced mode' }
function Show-PmcExcelPreview { Write-PmcStyled -Style 'Warning' -Text 'Excel preview unavailable' }
function Get-PmcLatestExcelFile { return $null }
function Set-PmcXFlowSourcePathInteractive { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Set-PmcXFlowDestPathInteractive { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Show-PmcXFlowPreview { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Invoke-PmcXFlowRun { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Export-PmcXFlowText { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Import-PmcXFlowMappingsFromFile { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Set-PmcXFlowLatestFromFile { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Show-PmcXFlowConfig { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }

# Show commands
function Show-PmcCommands { $rows=@(); foreach ($d in $Script:PmcCommandMap.Keys) { foreach ($a in $Script:PmcCommandMap[$d].Keys) { $rows += [pscustomobject]@{ Domain=$d; Action=$a; Handler=$Script:PmcCommandMap[$d][$a] } } }; Show-PmcDataGrid -Domains @('commands') -Columns @{ Domain=@{Header='Domain';Width=14}; Action=@{Header='Action';Width=16}; Handler=@{Header='Handler';Width=36} } -Data $rows -Title 'Commands' }

# Missing CommandMap functions
function Add-PmcRecurringTask { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Recurring tasks not yet implemented' }
function Get-PmcActivityList { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Activity list not yet implemented' }

# Missing Shortcut functions
function Invoke-PmcShortcutNumber { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Shortcut numbers not yet implemented' }
function Show-PmcWeekTasks { param($Context); Show-PmcWeekTasksInteractive -Context $Context }
function Get-PmcVelocity { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Velocity metrics not yet implemented' }
function Get-PmcStats { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Stats not yet implemented' }
function Start-PmcReview { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Review system not yet implemented' }
function Show-PmcBurndown { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Burndown chart not yet implemented' }
function Show-PmcNextTasks { param($Context); Show-PmcNextActions -Context $Context }
function Show-PmcMonthTasks { param($Context); Show-PmcMonthTasksInteractive -Context $Context }

# Export all legacy compatibility functions
Export-ModuleMember -Function Get-PmcData, Show-PmcTask, Set-PmcTask, Complete-PmcTask, Remove-PmcTask, Move-PmcTask, Set-PmcTaskPostponed, Copy-PmcTask, Add-PmcTaskNote, Edit-PmcTask, Find-PmcTask, Set-PmcTaskPriority, Show-PmcAgenda, Show-PmcWeekTasksInteractive, Show-PmcMonthTasksInteractive, Show-PmcTodayTasksInteractive, Show-PmcOverdueTasksInteractive, Show-PmcProjectsInteractive, Show-PmcAllTasksInteractive, Show-PmcProject, Set-PmcProject, Rename-PmcProject, Remove-PmcProject, Set-PmcProjectArchived, Set-PmcProjectFields, Show-PmcProjectFields, Get-PmcProjectStats, Show-PmcProjectInfo, Get-PmcRecentProjects, Edit-PmcTimeEntry, Remove-PmcTimeEntry, Add-PmcAlias, Remove-PmcAlias, Get-PmcAliasList, New-PmcBackup, Clear-PmcCompletedTasks, Invoke-PmcUndo, Invoke-PmcRedo, Import-PmcTasks, Export-PmcTasks, Import-PmcExcelData, Show-PmcExcelPreview, Get-PmcLatestExcelFile, Set-PmcXFlowSourcePathInteractive, Set-PmcXFlowDestPathInteractive, Show-PmcXFlowPreview, Invoke-PmcXFlowRun, Export-PmcXFlowText, Import-PmcXFlowMappingsFromFile, Set-PmcXFlowLatestFromFile, Show-PmcXFlowConfig, Show-PmcCommands, Add-PmcRecurringTask, Get-PmcActivityList, Invoke-PmcShortcutNumber, Show-PmcWeekTasks, Get-PmcVelocity, Get-PmcStats, Start-PmcReview, Show-PmcBurndown, Show-PmcNextTasks, Show-PmcMonthTasks

