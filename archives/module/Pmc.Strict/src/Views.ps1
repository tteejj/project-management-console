# Views.ps1 - Task view functions updated for current PMC system

function Show-PmcTodayTasks {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData
        $today = (Get-Date).Date

        # Filter tasks due today
        $todayTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.due -and
            [datetime]::ParseExact($_.due, 'yyyy-MM-dd', $null).Date -eq $today
        })

        Show-PmcCustomGrid -Domain 'task' -Data $todayTasks -Title "📅 Tasks Due Today" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing today's tasks: $_"
    }
}

function Show-PmcTomorrowTasks {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData
        $tomorrow = (Get-Date).Date.AddDays(1)

        # Filter tasks due tomorrow
        $tomorrowTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.due -and
            [datetime]::ParseExact($_.due, 'yyyy-MM-dd', $null).Date -eq $tomorrow
        })

        Show-PmcCustomGrid -Domain 'task' -Data $tomorrowTasks -Title "📅 Tasks Due Tomorrow" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing tomorrow's tasks: $_"
    }
}

function Show-PmcOverdueTasks {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData
        $today = (Get-Date).Date

        # Filter overdue tasks
        $overdueTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.due -and
            [datetime]::ParseExact($_.due, 'yyyy-MM-dd', $null).Date -lt $today
        })

        Show-PmcCustomGrid -Domain 'task' -Data $overdueTasks -Title "⚠️ Overdue Tasks" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing overdue tasks: $_"
    }
}

function Show-PmcUpcomingTasks {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData
        $today = (Get-Date).Date
        $nextWeek = $today.AddDays(7)

        # Filter upcoming tasks (next 7 days)
        $upcomingTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.due -and {
                $dueDate = [datetime]::ParseExact($_.due, 'yyyy-MM-dd', $null).Date
                $dueDate -gt $today -and $dueDate -le $nextWeek
            }
        })

        Show-PmcCustomGrid -Domain 'task' -Data $upcomingTasks -Title "📆 Upcoming Tasks (Next 7 Days)" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing upcoming tasks: $_"
    }
}

function Show-PmcBlockedTasks {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData

        # Filter blocked tasks (tasks with dependencies)
        $blockedTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.depends -and $_.depends.Count -gt 0
        })

        Show-PmcCustomGrid -Domain 'task' -Data $blockedTasks -Title "🚫 Blocked Tasks" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing blocked tasks: $_"
    }
}

function Show-PmcNoDueDateTasks {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData

        # Filter tasks with no due date
        $noDueTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and (-not $_.due -or $_.due -eq '')
        })

        Show-PmcCustomGrid -Domain 'task' -Data $noDueTasks -Title "📋 Tasks Without Due Date" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing tasks without due date: $_"
    }
}

function Show-PmcWeekTasksInteractive {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData
        $today = (Get-Date).Date
        $endOfWeek = $today.AddDays(6)

        # Filter tasks for this week
        $weekTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.due -and {
                $dueDate = [datetime]::ParseExact($_.due, 'yyyy-MM-dd', $null).Date
                $dueDate -ge $today -and $dueDate -le $endOfWeek
            }
        })

        Show-PmcCustomGrid -Domain 'task' -Data $weekTasks -Title "📆 This Week's Tasks" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing week's tasks: $_"
    }
}

function Show-PmcMonthTasksInteractive {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData
        $today = (Get-Date).Date
        $endOfMonth = $today.AddDays(29)

        # Filter tasks for this month
        $monthTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.due -and {
                $dueDate = [datetime]::ParseExact($_.due, 'yyyy-MM-dd', $null).Date
                $dueDate -ge $today -and $dueDate -le $endOfMonth
            }
        })

        Show-PmcCustomGrid -Domain 'task' -Data $monthTasks -Title "📅 This Month's Tasks" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing month's tasks: $_"
    }
}

function Show-PmcProjectList {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData
        $projects = $allData.projects | Where-Object { -not $_.isArchived }

        Show-PmcCustomGrid -Domain 'project' -Data $projects -Title "📁 Active Projects" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing projects: $_"
    }
}

function Show-PmcNextActions {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData

        # Get high priority pending tasks
        $nextActions = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.priority -gt 0
        } | Sort-Object priority -Descending | Select-Object -First 10)

        Show-PmcCustomGrid -Domain 'task' -Data $nextActions -Title "⭐ Next Actions (Top 10)" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing next actions: $_"
    }
}

# Add Interactive aliases for CommandMap compatibility
function Show-PmcTodayTasksInteractive { param([PmcCommandContext]$Context); Show-PmcTodayTasks -Context $Context }
function Show-PmcTomorrowTasksInteractive { param([PmcCommandContext]$Context); Show-PmcTomorrowTasks -Context $Context }
function Show-PmcOverdueTasksInteractive { param([PmcCommandContext]$Context); Show-PmcOverdueTasks -Context $Context }
function Show-PmcUpcomingTasksInteractive { param([PmcCommandContext]$Context); Show-PmcUpcomingTasks -Context $Context }
function Show-PmcBlockedTasksInteractive { param([PmcCommandContext]$Context); Show-PmcBlockedTasks -Context $Context }
function Show-PmcTasksWithoutDueDateInteractive { param([PmcCommandContext]$Context); Show-PmcNoDueDateTasks -Context $Context }
function Show-PmcProjectsInteractive { param([PmcCommandContext]$Context); Show-PmcProjectList -Context $Context }
function Show-PmcNextTasksInteractive { param([PmcCommandContext]$Context); Show-PmcNextActions -Context $Context }

# Export view functions
Export-ModuleMember -Function Show-PmcTodayTasks, Show-PmcTomorrowTasks, Show-PmcOverdueTasks, Show-PmcUpcomingTasks, Show-PmcBlockedTasks, Show-PmcNoDueDateTasks, Show-PmcWeekTasksInteractive, Show-PmcMonthTasksInteractive, Show-PmcProjectList, Show-PmcNextActions, Show-PmcTodayTasksInteractive, Show-PmcTomorrowTasksInteractive, Show-PmcOverdueTasksInteractive, Show-PmcUpcomingTasksInteractive, Show-PmcBlockedTasksInteractive, Show-PmcTasksWithoutDueDateInteractive, Show-PmcProjectsInteractive, Show-PmcNextTasksInteractive