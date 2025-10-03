# Project operation handlers for FakeTUI
# Handles: Edit, Info, RecentProjects

function Invoke-ProjectEditHandler {
    param($app)

    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $title = " Edit Project "
    $titleX = ($app.terminal.Width - $title.Length) / 2
    $app.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

    $app.terminal.WriteAtColor(4, 6, "Project name:", [PmcVT100]::Yellow(), "")

    $app.terminal.FillArea(0, $app.terminal.Height - 1, $app.terminal.Width, 1, ' ')
    $app.terminal.WriteAt(2, $app.terminal.Height - 1, "Enter project name | Esc=Cancel")

    $app.terminal.WriteAt(19, 6, "")
    [Console]::SetCursorPosition(19, 6)
    $projectName = [Console]::ReadLine()

    if ([string]::IsNullOrWhiteSpace($projectName)) {
        $app.currentView = 'main'
        $app.DrawLayout()
        return
    }

    try {
        $data = Get-PmcAllData

        if ($data.projects -notcontains $projectName) {
            $app.terminal.WriteAtColor(4, 9, "Project '$projectName' not found!", [PmcVT100]::Red(), "")
            Start-Sleep -Milliseconds 2000
            $app.currentView = 'main'
            $app.DrawLayout()
            return
        }

        # For now, just show edit options
        $app.terminal.WriteAtColor(4, 9, "Edit options for '$projectName':", [PmcVT100]::Cyan(), "")
        $app.terminal.WriteAt(4, 11, "R - Rename project")
        $app.terminal.WriteAt(4, 12, "A - Archive project")
        $app.terminal.WriteAt(4, 13, "D - Delete project")
        $app.terminal.WriteAt(4, 14, "S - View statistics")
        $app.terminal.WriteAt(4, 16, "Use Project menu for these operations")

    } catch {
        $app.terminal.WriteAtColor(4, 9, "Error: $_", [PmcVT100]::Red(), "")
    }

    $app.terminal.FillArea(0, $app.terminal.Height - 1, $app.terminal.Width, 1, ' ')
    $app.terminal.WriteAt(2, $app.terminal.Height - 1, "Press any key to return")
    [Console]::ReadKey($true) | Out-Null

    $app.currentView = 'main'
    $app.DrawLayout()
}

function Invoke-ProjectInfoHandler {
    param($app)

    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $title = " Project Information "
    $titleX = ($app.terminal.Width - $title.Length) / 2
    $app.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

    $app.terminal.WriteAtColor(4, 6, "Project name:", [PmcVT100]::Yellow(), "")

    $app.terminal.FillArea(0, $app.terminal.Height - 1, $app.terminal.Width, 1, ' ')
    $app.terminal.WriteAt(2, $app.terminal.Height - 1, "Enter project name | Esc=Cancel")

    $app.terminal.WriteAt(19, 6, "")
    [Console]::SetCursorPosition(19, 6)
    $projectName = [Console]::ReadLine()

    if ([string]::IsNullOrWhiteSpace($projectName)) {
        $app.currentView = 'main'
        $app.DrawLayout()
        return
    }

    try {
        $data = Get-PmcAllData

        if ($data.projects -notcontains $projectName) {
            $app.terminal.WriteAtColor(4, 9, "Project '$projectName' not found!", [PmcVT100]::Red(), "")
            Start-Sleep -Milliseconds 2000
            $app.currentView = 'main'
            $app.DrawLayout()
            return
        }

        # Get project info
        $projTasks = @($data.tasks | Where-Object { $_.project -eq $projectName })
        $activeTasks = @($projTasks | Where-Object { $_.status -ne 'completed' })
        $completedTasks = @($projTasks | Where-Object { $_.status -eq 'completed' })
        $highPriTasks = @($activeTasks | Where-Object { $_.priority -eq 'high' })
        $overdueTasks = @($activeTasks | Where-Object {
            $_.PSObject.Properties['dueDate'] -and $_.dueDate -and
            ([datetime]$_.dueDate).Date -lt (Get-Date).Date
        })

        # Time tracking
        $projTimelogs = @($data.timelogs | Where-Object { $_.project -eq $projectName })
        $totalMinutes = ($projTimelogs | Measure-Object -Property minutes -Sum).Sum
        $totalHours = [math]::Round($totalMinutes / 60, 2)

        # Display info
        $y = 9
        $app.terminal.WriteAtColor(4, $y, "Project: $projectName", [PmcVT100]::Cyan(), "")
        $y += 2

        $app.terminal.WriteAt(4, $y, "Tasks:")
        $y++
        $app.terminal.WriteAt(6, $y, "Total: $($projTasks.Count)")
        $y++
        $app.terminal.WriteAtColor(6, $y, "Active: $($activeTasks.Count)", [PmcVT100]::Yellow(), "")
        $y++
        $app.terminal.WriteAtColor(6, $y, "Completed: $($completedTasks.Count)", [PmcVT100]::Green(), "")
        $y++
        if ($highPriTasks.Count -gt 0) {
            $app.terminal.WriteAtColor(6, $y, "High Priority: $($highPriTasks.Count)", [PmcVT100]::Red(), "")
            $y++
        }
        if ($overdueTasks.Count -gt 0) {
            $app.terminal.WriteAtColor(6, $y, "Overdue: $($overdueTasks.Count)", [PmcVT100]::Red(), "")
            $y++
        }

        $y++
        $app.terminal.WriteAt(4, $y, "Time Tracking:")
        $y++
        $app.terminal.WriteAt(6, $y, "Total time: $totalHours hours")
        $y++
        $app.terminal.WriteAt(6, $y, "Time entries: $($projTimelogs.Count)")

        if ($projTasks.Count -gt 0) {
            $completionPct = [math]::Round(($completedTasks.Count / $projTasks.Count) * 100, 1)
            $y += 2
            $app.terminal.WriteAtColor(4, $y, "Completion: $completionPct%", [PmcVT100]::Cyan(), "")
        }

    } catch {
        $app.terminal.WriteAtColor(4, 9, "Error: $_", [PmcVT100]::Red(), "")
    }

    $app.terminal.FillArea(0, $app.terminal.Height - 1, $app.terminal.Width, 1, ' ')
    $app.terminal.WriteAt(2, $app.terminal.Height - 1, "Press any key to return")
    [Console]::ReadKey($true) | Out-Null

    $app.currentView = 'main'
    $app.DrawLayout()
}

function Invoke-RecentProjectsHandler {
    param($app)

    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $title = " Recent Projects "
    $titleX = ($app.terminal.Width - $title.Length) / 2
    $app.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

    try {
        $recentProjects = Get-PmcRecentProjects

        if ($recentProjects.Count -eq 0) {
            $app.terminal.WriteAt(4, 6, "No recent projects")
        } else {
            $app.terminal.WriteAtColor(4, 6, "Recently accessed projects:", [PmcVT100]::Yellow(), "")

            $y = 8
            for ($i = 0; $i -lt [Math]::Min(15, $recentProjects.Count); $i++) {
                $proj = $recentProjects[$i]
                $num = $i + 1

                if ($proj.PSObject.Properties['Name']) {
                    $name = $proj.Name
                    $count = if ($proj.PSObject.Properties['Count']) { $proj.Count } else { 0 }
                    $app.terminal.WriteAt(4, $y, "$num. $name ($count tasks)")
                } else {
                    # Simple string
                    $app.terminal.WriteAt(4, $y, "$num. $proj")
                }

                $y++
                if ($y -ge $app.terminal.Height - 3) { break }
            }
        }
    } catch {
        $app.terminal.WriteAtColor(4, 6, "Error loading recent projects: $_", [PmcVT100]::Red(), "")
    }

    $app.terminal.FillArea(0, $app.terminal.Height - 1, $app.terminal.Width, 1, ' ')
    $app.terminal.WriteAt(2, $app.terminal.Height - 1, "Press any key to return")
    [Console]::ReadKey($true) | Out-Null

    $app.currentView = 'main'
    $app.DrawLayout()
}
