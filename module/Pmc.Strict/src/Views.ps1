# Advanced Task Views Implementation
# Implements today, overdue, blocked, upcoming, noduedate views

function Show-PmcTodayTasks {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Views" -Message "Starting today view (interactive)"

    $today = (Get-Date).Date
    $title = "📅 TASKS DUE TODAY - {0}" -f $today.ToString('yyyy-MM-dd')

    # Always use the interactive grid; no static fallback
    Show-PmcDataGrid -Domains @("task") -Columns @{
        "id" = @{ Header = "#"; Width = 4; Alignment = "Right" }
        "text" = @{ Header = "Task"; Width = 40; Alignment = "Left" }
        "project" = @{ Header = "Project"; Width = 12; Alignment = "Left"; Truncate = $true }
        "priority" = @{ Header = "P"; Width = 3; Alignment = "Center" }
    } -Filters @{
        "status" = "pending"
        "due_range" = "today"
    } -Title $title -Interactive

    Write-PmcDebug -Level 2 -Category "Views" -Message "Today view completed (interactive)"
}

function Show-PmcTomorrowTasks {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Views" -Message "Starting tomorrow view"

    $data = Get-PmcDataAlias
    $tomorrow = (Get-Date).Date.AddDays(1)

    # Initialize tasks array if null
    if (-not $data.tasks) { $data.tasks = @() }

    $tomorrowTasks = @($data.tasks | Where-Object {
        if ($_ -eq $null -or $_.status -ne 'pending' -or -not $_.due -or -not ($_.due -is [string])) { return $false }
        if ($_.due -notmatch '^\d{4}-\d{2}-\d{2}$') { return $false }
        $d = [datetime]::ParseExact([string]$_.due, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
        return ($d.Date -eq $tomorrow)
    })

    Write-PmcStyled -Style 'Title' -Text ("`n📅 TASKS DUE TOMORROW - {0}" -f $tomorrow.ToString('yyyy-MM-dd'))
    Write-PmcStyled -Style 'Border' -Text "───────────────────────────────────────────────────"

    if ($tomorrowTasks.Count -eq 0) {
        Write-PmcStyled -Style 'Muted' -Text "No tasks due tomorrow"
        return
    }

    Show-TaskListWithIndex $tomorrowTasks "TOMORROW'S TASKS"

    Write-PmcDebug -Level 2 -Category "Views" -Message "Tomorrow view completed" -Data @{ TaskCount = $tomorrowTasks.Count }
}

function Show-PmcOverdueTasks {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Views" -Message "Starting overdue view (interactive)"

    $title = "⚠️  OVERDUE TASKS"

    # Always use the interactive grid; no static fallback
    Show-PmcDataGrid -Domains @("task") -Columns @{
        "id" = @{ Header = "#"; Width = 4; Alignment = "Right" }
        "text" = @{ Header = "Task"; Width = 35; Alignment = "Left" }
        "project" = @{ Header = "Project"; Width = 12; Alignment = "Left"; Truncate = $true }
        "due" = @{ Header = "Due"; Width = 10; Alignment = "Center" }
        "priority" = @{ Header = "P"; Width = 3; Alignment = "Center" }
    } -Filters @{
        "status" = "pending"
        "due_range" = "overdue"
    } -Title $title -Interactive

    Write-PmcDebug -Level 2 -Category "Views" -Message "Overdue view completed (interactive)" -Data @{ }
}

function Show-PmcUpcomingTasks {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Views" -Message "Starting upcoming view (interactive)"

    $today = (Get-Date).Date
    $weekFromNow = $today.AddDays(7)
    $title = "📋 UPCOMING TASKS (Next 7 Days)"

    # Use the interactive grid system
    Show-PmcDataGrid -Domains @("task") -Columns @{
        "id" = @{ Header = "#"; Width = 4; Alignment = "Right" }
        "text" = @{ Header = "Task"; Width = 35; Alignment = "Left" }
        "project" = @{ Header = "Project"; Width = 12; Alignment = "Left"; Truncate = $true }
        "due" = @{ Header = "Due"; Width = 8; Alignment = "Center" }
        "priority" = @{ Header = "P"; Width = 3; Alignment = "Center" }
    } -Filters @{
        "status" = "pending"
        "due_range" = "upcoming"
    } -Title $title -Interactive -Sort "due:asc"

    Write-PmcDebug -Level 2 -Category "Views" -Message "Upcoming view completed (interactive)"
}

# Additional views: agenda, week, month
function Show-PmcAgenda {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 2 -Category 'Views' -Message 'Show-PmcAgenda called - using new grid system'
    Write-PmcDebug -Level 1 -Category "Views" -Message "Starting agenda view (grid)"

    $today = (Get-Date).Date
    $title = "🗓️ AGENDA - {0}" -f $today.ToString('yyyy-MM-dd')

    # Use the grid system - try interactive first, fallback to static
    try {
        Show-PmcDataGrid -Domains @("task") -Columns @{
            "id" = @{ Header = "#"; Alignment = "Right" }
            "text" = @{ Header = "Task"; Alignment = "Left" }
            "project" = @{ Header = "Project"; Alignment = "Left"; Truncate = $true }
            "due" = @{ Header = "Due"; Alignment = "Center" }
            "priority" = @{ Header = "P"; Alignment = "Center" }
        } -Filters @{
            "status" = "pending"
            "due_range" = "overdue_and_today"
        } -Title $title -Interactive
    } catch {
        # Fallback to static grid if interactive fails
        Show-PmcDataGrid -Domains @("task") -Columns @{
            "id" = @{ Header = "#"; Alignment = "Right" }
            "text" = @{ Header = "Task"; Alignment = "Left" }
            "project" = @{ Header = "Project"; Alignment = "Left"; Truncate = $true }
            "due" = @{ Header = "Due"; Alignment = "Center" }
            "priority" = @{ Header = "P"; Alignment = "Center" }
        } -Filters @{
            "status" = "pending"
            "due_range" = "overdue_and_today"
        } -Title $title
    }
}

function Show-PmcWeekTasks { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if (-not $data.tasks) { $data.tasks = @() }
    $today = (Get-Date).Date
    $end = $today.AddDays(6)
    $week = @($data.tasks | Where-Object {
        if ($_ -eq $null -or $_.status -ne 'pending' -or -not (Pmc-HasProp $_ 'due') -or -not $_.due) { return $false }
        if ($_.due -and ($_.due -is [string]) -and $_.due -match '^\d{4}-\d{2}-\d{2}$') {
            $d = [datetime]::ParseExact([string]$_.due, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
            return ($d.Date -ge $today -and $d.Date -le $end)
        }
        return $false
    })
    Write-PmcStyled -Style 'Title' -Text ("`n📆 THIS WEEK - {0}..{1}" -f $today.ToString('yyyy-MM-dd'), $end.ToString('yyyy-MM-dd'))
    Write-PmcStyled -Style 'Border' -Text "─────────────────────────────────────────────────"
    if ($week.Count -eq 0) { Write-PmcStyled -Style 'Muted' -Text 'No tasks due this week'; return }
    Show-TaskListWithIndex $week "THIS WEEK'S TASKS"
}

function Show-PmcMonthTasks { param([PmcCommandContext]$Context)
    $data = Get-PmcDataAlias
    if (-not $data.tasks) { $data.tasks = @() }
    $today = (Get-Date).Date
    $y = $today.Year; $m = $today.Month
    $month = @($data.tasks | Where-Object {
        if ($_ -eq $null -or $_.status -ne 'pending' -or -not (Pmc-HasProp $_ 'due') -or -not $_.due) { return $false }
        if ($_.due -and ($_.due -is [string]) -and $_.due -match '^\d{4}-\d{2}-\d{2}$') {
            $d = [datetime]::ParseExact([string]$_.due, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
            return ($d.Year -eq $y -and $d.Month -eq $m)
        }
        return $false
    })
    Write-PmcStyled -Style 'Title' -Text ("`n🗓️ THIS MONTH - {0}" -f $today.ToString('yyyy-MM'))
    Write-PmcStyled -Style 'Border' -Text "─────────────────────────────────────────────────"
    if ($month.Count -eq 0) { Write-PmcStyled -Style 'Muted' -Text 'No tasks due this month'; return }
    Show-TaskListWithIndex $month "THIS MONTH'S TASKS"
}

function Show-PmcBlockedTasks {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Views" -Message "Starting blocked view (interactive)"

    $title = "🔒 BLOCKED TASKS"

    # Use the interactive grid system
    Show-PmcDataGrid -Domains @("task") -Columns @{
        "id" = @{ Header = "#"; Width = 4; Alignment = "Right" }
        "text" = @{ Header = "Task"; Width = 35; Alignment = "Left" }
        "project" = @{ Header = "Project"; Width = 12; Alignment = "Left"; Truncate = $true }
        "due" = @{ Header = "Due"; Width = 8; Alignment = "Center" }
        "priority" = @{ Header = "P"; Width = 3; Alignment = "Center" }
    } -Filters @{
        "status" = "pending"
        "blocked" = $true
    } -Title $title -Interactive

    Write-PmcDebug -Level 2 -Category "Views" -Message "Blocked view completed (interactive)"
}

function Show-PmcTasksWithoutDueDate {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Views" -Message "Starting noduedate view (interactive)"

    $title = "📝 TASKS WITHOUT DUE DATES"

    # Use the interactive grid system
    Show-PmcDataGrid -Domains @("task") -Columns @{
        "id" = @{ Header = "#"; Width = 4; Alignment = "Right" }
        "text" = @{ Header = "Task"; Width = 35; Alignment = "Left" }
        "project" = @{ Header = "Project"; Width = 12; Alignment = "Left"; Truncate = $true }
        "priority" = @{ Header = "P"; Width = 3; Alignment = "Center" }
        "created" = @{ Header = "Created"; Width = 8; Alignment = "Center" }
    } -Filters @{
        "status" = "pending"
        "no_due_date" = $true
    } -Title $title -Interactive -Sort "-priority"

    Write-PmcDebug -Level 2 -Category "Views" -Message "NoDueDate view completed (interactive)"
}

function Show-PmcNextTasks {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Views" -Message "Starting next actions view"

    $data = Get-PmcDataAlias

    # Initialize tasks array if null
    if (-not $data.tasks) { $data.tasks = @() }

    # Consider current context when listing next actions (avoid clobbering $Context param)
    $focusContext = Get-PmcCurrentContext
    $tasks = @($data.tasks | Where-Object { $_ -ne $null -and $_.status -eq 'pending' })
    if ($focusContext -and $focusContext -ne 'inbox') {
        $tasks = @($tasks | Where-Object { $_ -ne $null -and $_.project -eq $focusContext })
    } else {
        $tasks = @($tasks | Where-Object { $_ -ne $null -and (-not $_.project -or $_.project -eq 'inbox') })
    }

    # Favor unblocked, higher priority, earlier due
    Update-PmcBlockedStatus -data $data
    $today = (Get-Date).Date
    $scored = @()
    foreach ($t in $tasks) {
        if ($t -eq $null) { continue }
        $pri = if ($t.priority) { [int]$t.priority } else { 3 }
        $dueDelta = 999
        if ($t.due -and ($t.due -is [string]) -and $t.due -match '^\d{4}-\d{2}-\d{2}$') {
            $d = [datetime]::ParseExact([string]$t.due, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
            $dueDelta = ($d.Date - $today).Days
        }
        $blocked = if ((Pmc-HasProp $t 'blocked') -and $t.blocked) { 1 } else { 0 }
        $score = ($blocked*1000) + (($pri-1)*100) + ([Math]::Max(0, $dueDelta))
        $scored += @{ task=$t; score=$score }
    }
    $ordered = @($scored | Sort-Object score | Select-Object -First 10 | ForEach-Object { $_.task })

    Write-PmcStyled -Style 'Info' -Text "`n🎯 NEXT ACTIONS"
    Write-PmcStyled -Style 'Border' -Text "───────────────"

    if ($ordered.Count -eq 0) {
        Write-PmcStyled -Style 'Muted' -Text "No next actions found"
        return
    }

    Show-TaskListWithIndex $ordered "NEXT ACTIONS"

    Write-PmcDebug -Level 2 -Category "Views" -Message "Next actions view completed" -Data @{ Count = $ordered.Count; Context=$context }
}

function Show-PmcProjectsView {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Views" -Message "Starting projects view (interactive)"

    # Always use the interactive grid; no static fallback
    Show-PmcDataGrid -Domains @("project") -Columns @{
        "name" = @{ Header = "Project"; Width = 20; Alignment = "Left" }
        "description" = @{ Header = "Description"; Width = 30; Alignment = "Left"; Truncate = $true }
        "task_count" = @{ Header = "Tasks"; Width = 6; Alignment = "Right" }
        "completion" = @{ Header = "%"; Width = 6; Alignment = "Right" }
    } -Filters @{
        "archived" = $false
    } -Title "📊 PROJECTS DASHBOARD" -Interactive
}

# Helper function to display task lists with consistent formatting
function Show-TaskListWithIndex {
    param(
        [array]$Tasks,
        [string]$Title,
        [switch]$ShowDaysOverdue,
        [switch]$ShowDaysUntil,
        [switch]$ShowBlockers
    )

    if ($Tasks.Count -eq 0) { return }

    Set-PmcLastTaskListMap @{}
    $rows = @()
    $i = 1

    foreach ($task in $Tasks) {
        if ($task -eq $null) { continue }
        $map = Get-PmcLastTaskListMap
        $map[$i] = $task.id
        Set-PmcLastTaskListMap $map

        $row = @{
            idx = "[$i]"
            text = (Pmc-GetProp $task 'text' '')
            project = (Pmc-GetProp $task 'project' 'inbox')
            pri = if ((Pmc-HasProp $task 'priority') -and $task.priority) { "p$($task.priority)" } else { '' }
        }

        if ($ShowDaysOverdue -and (Pmc-HasProp $task 'due') -and $task.due) {
            $daysOverdue = ((Get-Date).Date - [datetime]$task.due).Days
            $row.due = "$($daysOverdue)d ago"
        } elseif ($ShowDaysUntil -and (Pmc-HasProp $task 'due') -and $task.due) {
            $daysUntil = ([datetime]$task.due - (Get-Date).Date).Days
            $dayLabel = if ($daysUntil -eq 0) { "today" } elseif ($daysUntil -eq 1) { "tomorrow" } else { "${daysUntil}d" }
            $row.due = $dayLabel
        } elseif ((Pmc-HasProp $task 'due') -and $task.due) {
            $row.due = ([datetime]$task.due).ToString('MM/dd')
        } else {
            $row.due = ''
        }

        if ($ShowBlockers -and (Pmc-HasProp $task 'depends') -and $task.depends) {
            $row.blockers = ($task.depends -join ',')
        }

        $rows += $row
        $i++
    }

    $cols = @(
        @{ key='idx'; title='#'; width=5; align='right' },
        @{ key='text'; title='Task'; width=46 },
        @{ key='project'; title='Project'; width=15 },
        @{ key='pri'; title='Pri'; width=4 },
        @{ key='due'; title='Due'; width=10 }
    )

    if ($ShowBlockers) {
        $cols += @{ key='blockers'; title='Blocked By'; width=12 }
    }

    Show-PmcTable -Columns $cols -Rows $rows -Title $Title
    Show-PmcTip "Use 'task view <#>', 'task done <#>', 'task edit <#>'"
}
