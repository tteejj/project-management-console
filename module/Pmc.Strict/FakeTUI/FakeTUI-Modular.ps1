# FakeTUI Modular Loader
# This file loads the main FakeTUI.ps1 and extends it with additional handlers from modular files

# Load debug system first
. "$PSScriptRoot/Debug.ps1"
Write-FakeTUIDebug "Loading FakeTUI modular system" "LOADER"

# Load main FakeTUI
. "$PSScriptRoot/FakeTUI.ps1"
Write-FakeTUIDebug "FakeTUI.ps1 loaded" "LOADER"

# Load handler modules
. "$PSScriptRoot/Handlers/TaskHandlers.ps1"
Write-FakeTUIDebug "TaskHandlers.ps1 loaded" "LOADER"
. "$PSScriptRoot/Handlers/ProjectHandlers.ps1"
Write-FakeTUIDebug "ProjectHandlers.ps1 loaded" "LOADER"

# Extend PmcFakeTUIApp class with additional action handlers
# This uses PowerShell's ability to add methods to existing instances

# Add helper method to wire up all extended handlers
Add-Member -InputObject ([PmcFakeTUIApp]) -MemberType ScriptMethod -Name 'ProcessExtendedActions' -Value {
    param([string]$action)

    # Task handlers
    if ($action -eq 'task:copy') {
        Invoke-TaskCopyHandler -app $this
        return $true
    } elseif ($action -eq 'task:move') {
        Invoke-TaskMoveHandler -app $this
        return $true
    } elseif ($action -eq 'task:find') {
        Invoke-TaskFindHandler -app $this
        return $true
    } elseif ($action -eq 'task:priority') {
        Invoke-TaskPriorityHandler -app $this
        return $true
    } elseif ($action -eq 'task:postpone') {
        Invoke-TaskPostponeHandler -app $this
        return $true
    } elseif ($action -eq 'task:note') {
        Invoke-TaskNoteHandler -app $this
        return $true
    }

    # Project handlers
    elseif ($action -eq 'project:edit') {
        Invoke-ProjectEditHandler -app $this
        return $true
    } elseif ($action -eq 'project:info') {
        Invoke-ProjectInfoHandler -app $this
        return $true
    } elseif ($action -eq 'project:recent') {
        Invoke-RecentProjectsHandler -app $this
        return $true
    }

    # View handlers (stubs for now - can be implemented in separate files)
    elseif ($action -eq 'view:agenda') {
        Show-PmcAgendaInteractive
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'main'
        $this.DrawLayout()
        return $true
    } elseif ($action -eq 'view:all') {
        Show-PmcAllTasksInteractive
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'main'
        $this.DrawLayout()
        return $true
    }

    # Tool handlers (stubs)
    elseif ($action -eq 'tools:templates') {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $templates = Get-PmcTemplates
        $y = 5
        $this.terminal.WriteAtColor(4, $y, "Available Templates:", [PmcVT100]::Yellow(), "")
        $y += 2
        foreach ($template in $templates) {
            $this.terminal.WriteAt(4, $y, "• $template")
            $y++
            if ($y -ge $this.terminal.Height - 3) { break }
        }
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'main'
        $this.DrawLayout()
        return $true
    } elseif ($action -eq 'tools:statistics') {
        $stats = Get-PmcStatistics
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $y = 5
        $this.terminal.WriteAtColor(4, $y, "PMC Statistics:", [PmcVT100]::Cyan(), "")
        $y += 2
        foreach ($key in $stats.Keys) {
            $value = $stats[$key]
            $this.terminal.WriteAt(4, $y, "$key`: $value")
            $y++
            if ($y -ge $this.terminal.Height - 3) { break }
        }
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'main'
        $this.DrawLayout()
        return $true
    } elseif ($action -eq 'tools:velocity') {
        $velocity = Get-PmcVelocity
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $this.terminal.WriteAtColor(4, 5, "Task Velocity:", [PmcVT100]::Cyan(), "")
        $this.terminal.WriteAt(4, 7, "Tasks completed per week: $velocity")
        $this.terminal.WriteAt(2, $this.terminal.Height - 1, "Press any key to return")
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'main'
        $this.DrawLayout()
        return $true
    } elseif ($action -eq 'tools:preferences') {
        Show-PmcPreferences
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'main'
        $this.DrawLayout()
        return $true
    } elseif ($action -eq 'tools:applytheme') {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $this.terminal.WriteAtColor(4, 5, "Theme name:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(18, 5, "")
        [Console]::SetCursorPosition(18, 5)
        $themeName = [Console]::ReadLine()
        if (-not [string]::IsNullOrWhiteSpace($themeName)) {
            try {
                Apply-PmcTheme -ThemeName $themeName
                $this.terminal.WriteAtColor(4, 7, "Theme '$themeName' applied!", [PmcVT100]::Green(), "")
            } catch {
                $this.terminal.WriteAtColor(4, 7, "Error: $_", [PmcVT100]::Red(), "")
            }
            Start-Sleep -Milliseconds 1500
        }
        $this.currentView = 'main'
        $this.DrawLayout()
        return $true
    } elseif ($action -eq 'tools:query') {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $this.terminal.WriteAtColor(4, 5, "Query:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(12, 5, "")
        [Console]::SetCursorPosition(12, 5)
        $query = [Console]::ReadLine()
        if (-not [string]::IsNullOrWhiteSpace($query)) {
            try {
                $results = Invoke-PmcQuery -Query $query
                $this.terminal.WriteAtColor(4, 7, "Results: $($results.Count) items", [PmcVT100]::Green(), "")
                # Could display results here
            } catch {
                $this.terminal.WriteAtColor(4, 7, "Error: $_", [PmcVT100]::Red(), "")
            }
            Start-Sleep -Milliseconds 2000
        }
        $this.currentView = 'main'
        $this.DrawLayout()
        return $true
    }

    # Help handlers
    elseif ($action -eq 'help:browser') {
        Show-PmcHelpCategories
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'main'
        $this.DrawLayout()
        return $true
    } elseif ($action -eq 'help:categories') {
        Show-PmcHelpCategories
        [Console]::ReadKey($true) | Out-Null
        $this.currentView = 'main'
        $this.DrawLayout()
        return $true
    } elseif ($action -eq 'help:search') {
        $this.terminal.Clear()
        $this.menuSystem.DrawMenuBar()
        $this.terminal.WriteAtColor(4, 5, "Search help:", [PmcVT100]::Yellow(), "")
        $this.terminal.WriteAt(18, 5, "")
        [Console]::SetCursorPosition(18, 5)
        $searchTerm = [Console]::ReadLine()
        if (-not [string]::IsNullOrWhiteSpace($searchTerm)) {
            Show-PmcHelpSearch -SearchTerm $searchTerm
            [Console]::ReadKey($true) | Out-Null
        }
        $this.currentView = 'main'
        $this.DrawLayout()
        return $true
    }

    # Not handled
    return $false
} -Force

Write-Host "FakeTUI modular extensions loaded successfully" -ForegroundColor Green

