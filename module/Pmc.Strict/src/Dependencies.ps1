# Dependencies System Implementation
# Based on t2.ps1 dependencies functionality

function Update-PmcBlockedStatus {
    param($data = (Get-PmcDataAlias))

    Write-PmcDebug -Level 3 -Category "Dependencies" -Message "Updating blocked status for all tasks"

    # Clear all blocked status first
    foreach ($task in @($data.tasks)) {
        if ($null -eq $task) { continue }
        if (Pmc-HasProp $task 'blocked') { $task.PSObject.Properties.Remove('blocked') }
    }

    # Set blocked status for tasks with pending dependencies
    foreach ($task in @($data.tasks) | Where-Object {
        $null -ne $_ -and
        (Pmc-HasProp $_ 'depends') -and
        $_.depends -and
        $_.depends.Count -gt 0
    }) {
        $blockers = $data.tasks | Where-Object {
            Pmc-HasProp $_ 'id' -and ($_.id -in $task.depends) -and (Pmc-HasProp $_ 'status') -and $_.status -eq 'pending'
        }
        $isBlocked = ($blockers.Count -gt 0)

        if ($isBlocked) {
            if (Pmc-HasProp $task 'blocked') { $task.blocked = $true } else { Add-Member -InputObject $task -MemberType NoteProperty -Name blocked -Value $true }
        }
    }

    Write-PmcDebug -Level 3 -Category "Dependencies" -Message "Blocked status update completed"
}

function Add-PmcDependency {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Dependencies" -Message "Starting dep add" -Data @{ FreeText = $Context.FreeText }

    $data = Get-PmcDataAlias
    $ids = $Context.FreeText

    if ($ids.Count -lt 2) {
        Write-Host "Usage: dep add <task> <depends-on>" -ForegroundColor Yellow
        return
    }

    $taskId = $null
    $dependsOnId = $null

    # Resolve task IDs
    if ($ids[0] -match '^\d+$') { $taskId = [int]$ids[0] }
    if ($ids[1] -match '^\d+$') { $dependsOnId = [int]$ids[1] }

    if (-not $taskId -or -not $dependsOnId) {
        Write-Host "Invalid task IDs" -ForegroundColor Red
        return
    }

    $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1
    $dependsOnTask = $data.tasks | Where-Object { $_.id -eq $dependsOnId } | Select-Object -First 1

    if (-not $task) {
        Write-Host "Task #$taskId not found" -ForegroundColor Red
        return
    }

    if (-not $dependsOnTask) {
        Write-Host "Task #$dependsOnId not found" -ForegroundColor Red
        return
    }

    # Initialize depends array if needed
    if (-not (Pmc-HasProp $task 'depends')) { $task | Add-Member -NotePropertyName depends -NotePropertyValue @() -Force }

    # Check if dependency already exists
    if ($task.depends -contains $dependsOnId) {
        Write-Host "Dependency already exists" -ForegroundColor Yellow
        return
    }

    # Add dependency
    $task.depends = @($task.depends + $dependsOnId)

    # Update blocked status for all tasks
    Update-PmcBlockedStatus -data $data

    Save-StrictData $data 'dep add'
    Write-Host "Added dependency: Task #$taskId depends on Task #$dependsOnId" -ForegroundColor Green

    Write-PmcDebug -Level 2 -Category "Dependencies" -Message "Dependency added successfully" -Data @{ TaskId = $taskId; DependsOn = $dependsOnId }
}

function Remove-PmcDependency {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Dependencies" -Message "Starting dep remove" -Data @{ FreeText = $Context.FreeText }

    $data = Get-PmcDataAlias
    $ids = $Context.FreeText

    if ($ids.Count -lt 2) {
        Write-Host "Usage: dep remove <task> <depends-on>" -ForegroundColor Yellow
        return
    }

    $taskId = $null
    $dependsOnId = $null

    # Resolve task IDs
    if ($ids[0] -match '^\d+$') { $taskId = [int]$ids[0] }
    if ($ids[1] -match '^\d+$') { $dependsOnId = [int]$ids[1] }

    if (-not $taskId -or -not $dependsOnId) {
        Write-Host "Invalid task IDs" -ForegroundColor Red
        return
    }

    $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1

    if (-not $task -or -not (Pmc-HasProp $task 'depends') -or -not $task.depends) {
        Write-Host "No such dependency found" -ForegroundColor Yellow
        return
    }

    # Remove dependency
    $task.depends = @($task.depends | Where-Object { $_ -ne $dependsOnId })

    # Clean up empty depends array
    if ($task.depends.Count -eq 0) { try { $task.PSObject.Properties.Remove('depends') } catch {} }

    # Update blocked status for all tasks
    Update-PmcBlockedStatus -data $data

    Save-StrictData $data 'dep remove'
    Write-Host "Removed dependency: Task #$taskId no longer depends on Task #$dependsOnId" -ForegroundColor Green

    Write-PmcDebug -Level 2 -Category "Dependencies" -Message "Dependency removed successfully" -Data @{ TaskId = $taskId; DependsOn = $dependsOnId }
}

function Show-PmcDependencies {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Dependencies" -Message "Starting dep show" -Data @{ FreeText = $Context.FreeText }

    $data = Get-PmcDataAlias
    $text = ($Context.FreeText -join ' ').Trim()

    if (-not $text) {
        Write-Host "Usage: dep show <task>" -ForegroundColor Yellow
        return
    }

    $taskId = $null
    if ($text -match '^\d+$') { $taskId = [int]$text }

    if (-not $taskId) {
        Write-Host "Invalid task ID" -ForegroundColor Red
        return
    }

    $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1

    if (-not $task) {
        Write-Host "Task #$taskId not found" -ForegroundColor Red
        return
    }

    Write-Host "`nDEPENDENCIES for Task #$taskId" -ForegroundColor Cyan
    Write-Host ("Task: {0}" -f $task.text) -ForegroundColor White
    Write-Host "─────────────────────────────────" -ForegroundColor DarkGray

    $depends = if ((Pmc-HasProp $task 'depends') -and $task.depends) { $task.depends } else { @() }

    if ($depends.Count -eq 0) {
        Write-Host "  No dependencies" -ForegroundColor Gray
        return
    }

    $rows = @()
    foreach ($depId in $depends) {
        $depTask = $data.tasks | Where-Object { $_.id -eq $depId } | Select-Object -First 1
        $status = if ($depTask) { $depTask.status } else { 'missing' }
        $text = if ($depTask) { $depTask.text } else { '(missing task)' }
        $rows += @{ id = "#$depId"; status = $status; text = $text }
    }

    $cols = @(
        @{ key='id'; title='ID'; width=6 },
        @{ key='status'; title='Status'; width=10 },
        @{ key='text'; title='Task'; width=50 }
    )

    Show-PmcTable -Columns $cols -Rows $rows -Title "Dependencies for Task #$taskId"

    # Show if this task is blocked
    if ($task.blocked) {
        Write-Host "`n⚠️  This task is BLOCKED by pending dependencies" -ForegroundColor Red
    } else {
        Write-Host "`n✅ This task is ready to work on" -ForegroundColor Green
    }

    Write-PmcDebug -Level 2 -Category "Dependencies" -Message "Dependencies shown successfully" -Data @{ TaskId = $taskId; DependencyCount = $depends.Count }
}

function Show-PmcDependencyGraph {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Dependencies" -Message "Starting dep graph"

    $data = Get-PmcDataAlias
    $rows = @()

    foreach ($task in $data.tasks) {
        if ((Pmc-HasProp $task 'depends') -and @($task.depends).Count -gt 0) {
            $dependsText = ($task.depends -join ', ')
            $status = if ($task.blocked) { "🔒 BLOCKED" } else { "✅ Ready" }
            $rows += @{
                task = "#$($task.id)"
                depends = $dependsText
                status = $status
                text = $task.text
            }
        }
    }

    if (@($rows).Count -eq 0) {
        Write-Host "`nDEPENDENCY GRAPH" -ForegroundColor Cyan
        Write-Host "No task dependencies found" -ForegroundColor Gray
        return
    }

    $cols = @(
        @{ key='task'; title='Task'; width=8 },
        @{ key='depends'; title='Depends On'; width=15 },
        @{ key='status'; title='Status'; width=12 },
        @{ key='text'; title='Description'; width=40 }
    )

    Show-PmcTable -Columns $cols -Rows $rows -Title 'DEPENDENCY GRAPH'

    # Summary statistics
    $blockedCount = @($data.tasks | Where-Object { $_.blocked }).Count
    $dependentCount = @($data.tasks | Where-Object { (Pmc-HasProp $_ 'depends') -and $_.depends }).Count

    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Tasks with dependencies: $dependentCount" -ForegroundColor White
    Write-Host "  Currently blocked tasks: $blockedCount" -ForegroundColor $(if ($blockedCount -gt 0) { 'Red' } else { 'Green' })

    Write-PmcDebug -Level 2 -Category "Dependencies" -Message "Dependency graph shown successfully" -Data @{ DependentTasks = $dependentCount; BlockedTasks = $blockedCount }
}
