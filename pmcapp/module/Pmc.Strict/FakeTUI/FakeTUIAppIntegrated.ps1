# PMC FakeTUI Application - Integrated version with real screens
# Main application class that coordinates all screens and components

# All required components (core, components, screens) are preloaded by
# pmcapp/module/Pmc.Strict/src/FakeTUICommand.ps1 at module import time.

class PmcFakeTUIAppIntegrated {
    [object]$Terminal
    [object]$MenuSystem
    [object]$CLIAdapter
    [object]$CurrentScreen
    [string]$CurrentView = 'tasks'  # tasks, projects
    [bool]$IsRunning = $false
    [bool]$NeedsRedraw = $true

    # Screen instances
    [object]$TaskListScreen
    [object]$ProjectListScreen
    [object]$CommandPalette

    PmcFakeTUIAppIntegrated() {
        Write-Host "Initializing PMC FakeTUI Integrated Application..." -ForegroundColor Green
    }

    [void] Initialize() {
        try {
            # Initialize string cache for performance
            [PmcStringCache]::Initialize()

            # Initialize terminal
            $this.Terminal = [PmcSimpleTerminal]::GetInstance()

            # Initialize menu system
            $this.MenuSystem = [PmcMenuSystem]::new($this.Terminal)
            $this.MenuSystem.InitializeDefaultMenus()

            # Initialize CLI adapter
            $this.CLIAdapter = [PmcCLIAdapter]::new()

            # Initialize screens
            $this.TaskListScreen = [PmcTaskListScreen]::new($this.Terminal, $this.MenuSystem)
            $this.ProjectListScreen = [PmcProjectListScreen]::new($this.Terminal, $this.MenuSystem)
            $this.CommandPalette = [PmcCommandPalette]::new($this.Terminal)

            # Set initial screen
            $this.SwitchToView('tasks')

            Write-Host "PMC FakeTUI initialized successfully" -ForegroundColor Green

        } catch {
            Write-Host "Failed to initialize FakeTUI: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    }

    [void] Run() {
        $this.IsRunning = $true

        try {
            # Clear screen and hide cursor
            [Console]::CursorVisible = $false
            $this.Terminal.WriteAt(0, 0, [PmcStringCache]::GetAnsiSequence("clear"))
            $this.Terminal.WriteAt(0, 0, [PmcStringCache]::GetAnsiSequence("hidecursor"))

            Write-Host "PMC FakeTUI is starting..." -ForegroundColor Green
            Start-Sleep -Milliseconds 500  # Brief pause to show startup message

            while ($this.IsRunning) {
                if ($this.NeedsRedraw) {
                    $this.Draw()
                    $this.NeedsRedraw = $false
                }

                # Handle input
                try {
                    $key = [Console]::ReadKey($true)
                    $this.HandleKey($key)
                } catch {
                    # Key reading failed - might be non-interactive environment
                    Write-Host "Input error: $($_.Exception.Message)" -ForegroundColor Red
                    $this.IsRunning = $false
                }
            }

        } finally {
            # Restore cursor
            [Console]::CursorVisible = $true
            $this.Terminal.WriteAt(0, 0, [PmcStringCache]::GetAnsiSequence("showcursor"))
        }
    }

    [void] Draw() {
        # Clear screen
        $this.Terminal.WriteAt(0, 0, [PmcStringCache]::GetAnsiSequence("clear"))
        $this.Terminal.WriteAt(0, 0, [PmcStringCache]::GetAnsiSequence("home"))

        # Draw menu bar
        $this.MenuSystem.Draw()

        # Draw current screen
        if ($this.CurrentScreen) {
            $this.CurrentScreen.Draw()
        }

        # Draw status information at bottom
        $this.DrawStatusBar()
    }

    [void] DrawStatusBar() {
        $width = [Console]::WindowWidth
        $height = [Console]::WindowHeight
        $statusY = $height - 1

        # Clear status bar
        $this.Terminal.WriteAt(0, $statusY, (' ' * $width))

        # Build status text
        $statusText = "PMC FakeTUI - View: $($this.CurrentView.ToUpper())"

        try {
            $data = Get-PmcData
            $taskCount = if ($data.tasks) { $data.tasks.Count } else { 0 }
            $projectCount = if ($data.projects) { $data.projects.Count } else { 0 }
            $activeCount = if ($data.tasks) { @($data.tasks | Where-Object { $_.status -ne 'completed' }).Count } else { 0 }

            $statusText += " | Tasks: $taskCount ($activeCount active) | Projects: $projectCount"
        } catch {
            $statusText += " | Data loading error"
        }

        $statusText += " | Ctrl+T: Tasks | Ctrl+P: Projects | Ctrl+O: Commands | Ctrl+Q: Exit"

        # Draw status text (truncate if too long)
        $displayText = if ($statusText.Length -gt $width) {
            $statusText.Substring(0, $width - 3) + "..."
        } else {
            $statusText
        }

        $this.Terminal.WriteAt(0, $statusY, "`e[44m`e[37m$displayText`e[0m")
    }

    [void] HandleKey([System.ConsoleKeyInfo]$key) {
        $handled = $false

        # Ctrl+key combinations - PMC already uses these successfully
        if ($key.Modifiers -band [System.ConsoleModifiers]::Control) {
            switch ($key.Key) {
                'T' {
                    $this.SwitchToView('tasks')
                    $handled = $true
                }
                'P' {
                    $this.SwitchToView('projects')
                    $handled = $true
                }
                'O' {
                    # Command Palette
                    $selectedCommand = $this.CommandPalette.Show()
                    if ($selectedCommand) {
                        $this.ExecuteCommand($selectedCommand)
                    }
                    $this.NeedsRedraw = $true
                    $handled = $true
                }
                'N' {
                    $this.AddNewTask()
                    $handled = $true
                }
                'R' {
                    $this.RefreshData()
                    $handled = $true
                }
                'H' {
                    $this.ShowHelp()
                    $handled = $true
                }
                'Q' {
                    $this.IsRunning = $false
                    $handled = $true
                }
            }
        }

        # Function keys as backup
        switch ($key.Key) {
            'F1' {
                $this.ShowHelp()
                $handled = $true
            }
            'F5' {
                $this.RefreshData()
                $handled = $true
            }
            'F10' {
                $this.IsRunning = $false
                $handled = $true
            }
            'Escape' {
                $this.IsRunning = $false
                $handled = $true
            }
        }

        # If not handled globally, pass to current screen
        if (-not $handled -and $this.CurrentScreen) {
            $handled = $this.CurrentScreen.HandleKey($key)
            if ($handled) {
                $this.NeedsRedraw = $true
            }
        }

        # If still not handled, check menu system
        if (-not $handled) {
            $handled = $this.MenuSystem.HandleKey($key)
            if ($handled) {
                $this.NeedsRedraw = $true
            }
        }
    }

    [void] SwitchToView([string]$viewName) {
        $this.CurrentView = $viewName

        switch ($viewName) {
            'tasks' {
                $this.CurrentScreen = $this.TaskListScreen
                $this.TaskListScreen.LoadData()
            }
            'projects' {
                $this.CurrentScreen = $this.ProjectListScreen
                $this.ProjectListScreen.LoadData()
            }
            default {
                Write-Host "Unknown view: $viewName" -ForegroundColor Yellow
                return
            }
        }

        $this.NeedsRedraw = $true
    }

    [void] ExecuteCommand([object]$command) {
        try {
            switch ($command.Command) {
                'add task' { $this.AddNewTask() }
                'edit task' { $this.EditCurrentTask() }
                'complete task' { $this.CompleteCurrentTask() }
                'delete task' { $this.DeleteCurrentTask() }

                'add project' { $this.AddNewProject() }
                'edit project' { $this.EditCurrentProject() }

                'filter active' { $this.SetTaskFilter('active') }
                'filter completed' { $this.SetTaskFilter('completed') }
                'filter all' { $this.SetTaskFilter('all') }

                'sort priority' { $this.SetTaskSort('priority') }
                'sort status' { $this.SetTaskSort('status') }
                'sort project' { $this.SetTaskSort('project') }

                'view tasks' { $this.SwitchToView('tasks') }
                'view projects' { $this.SwitchToView('projects') }

                'undo' { $this.ExecutePmcCommand('system undo') }
                'redo' { $this.ExecutePmcCommand('system redo') }
                'backup' { $this.ExecutePmcCommand('system backup') }
                'clean' { $this.ExecutePmcCommand('system clean') }

                'refresh' { $this.RefreshData() }
                'exit' { $this.IsRunning = $false }

                default {
                    Write-Host "Command not implemented: $($command.Command)" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "Error executing command: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    [void] AddNewTask() {
        $dialog = [PmcTaskEditDialog]::new($this.Terminal, $null)
        $result = $dialog.Show()

        if ($result -eq 'save') {
            $this.RefreshData()
        }
    }

    [void] EditCurrentTask() {
        if ($this.CurrentView -eq 'tasks' -and $this.TaskListScreen.SelectedIndex -lt $this.TaskListScreen.FilteredTasks.Count) {
            $task = $this.TaskListScreen.FilteredTasks[$this.TaskListScreen.SelectedIndex]
            $dialog = [PmcTaskEditDialog]::new($this.Terminal, $task)
            $result = $dialog.Show()

            if ($result -eq 'save' -or $result -eq 'delete') {
                $this.RefreshData()
            }
        }
    }

    [void] CompleteCurrentTask() {
        if ($this.CurrentView -eq 'tasks' -and $this.TaskListScreen.SelectedIndex -lt $this.TaskListScreen.FilteredTasks.Count) {
            $task = $this.TaskListScreen.FilteredTasks[$this.TaskListScreen.SelectedIndex]
            $this.ExecutePmcCommand("complete $($task.id)")
            $this.RefreshData()
        }
    }

    [void] DeleteCurrentTask() {
        if ($this.CurrentView -eq 'tasks' -and $this.TaskListScreen.SelectedIndex -lt $this.TaskListScreen.FilteredTasks.Count) {
            $task = $this.TaskListScreen.FilteredTasks[$this.TaskListScreen.SelectedIndex]
            # Simple confirmation for now
            Write-Host "Delete task #$($task.id)? (This would show a confirmation dialog)"
        }
    }

    [void] AddNewProject() {
        # Simple project creation - would show a dialog in full implementation
        Write-Host "Add new project functionality - would show project creation dialog"
    }

    [void] EditCurrentProject() {
        if ($this.CurrentView -eq 'projects' -and $this.ProjectListScreen.SelectedIndex -lt $this.ProjectListScreen.FilteredProjects.Count) {
            $project = $this.ProjectListScreen.FilteredProjects[$this.ProjectListScreen.SelectedIndex]
            Write-Host "Edit project '$($project.name)' - would show project edit dialog"
        }
    }

    [void] SetTaskFilter([string]$filterMode) {
        if ($this.CurrentView -eq 'tasks') {
            $this.TaskListScreen.FilterMode = $filterMode
            $this.TaskListScreen.ApplyFilters()
            $this.TaskListScreen.NeedsRefresh = $true
        }
    }

    [void] SetTaskSort([string]$sortMode) {
        if ($this.CurrentView -eq 'tasks') {
            $this.TaskListScreen.SortMode = $sortMode
            $this.TaskListScreen.ApplyFilters()
            $this.TaskListScreen.NeedsRefresh = $true
        }
    }

    [void] ExecutePmcCommand([string]$command) {
        try {
            $this.CLIAdapter.ExecuteAction($command)
        } catch {
            Write-Host "Failed to execute PMC command: $command - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    [void] RefreshData() {
        if ($this.CurrentScreen) {
            $this.CurrentScreen.LoadData()
            $this.NeedsRedraw = $true
        }
    }

    [void] ShowHelp() {
        # Clear screen for help display
        [Console]::Clear()

        $helpText = @"
PMC FakeTUI - Help

NAVIGATION:
  F2 / F3         - Switch between Tasks and Projects views
  ↑↓ arrows       - Navigate through list items
  Page Up/Down    - Navigate by page
  Home/End        - Go to first/last item

ACTIONS:
  Enter           - Edit selected item
  Insert / F6     - Add new item
  Delete          - Delete selected item
  F5              - Refresh data

EDITING:
  When editing tasks/projects:
  - Type normally to enter text
  - Use arrow keys to move cursor
  - Backspace/Delete to remove text
  - Enter to save changes
  - Escape to cancel without saving

GLOBAL COMMANDS:
  F1              - This help screen
  F4              - Command Palette (search all actions)
  F10 / Escape    - Exit PMC FakeTUI

WORKFLOW:
  1. Use F2/F3 to switch between Tasks and Projects
  2. Use arrows to find what you want
  3. Press Enter to edit, or F6 to add new
  4. In edit dialogs, type normally and use Enter/Escape
  5. Use F4 for quick access to all commands

Note: Function keys (F1-F10) for navigation and commands.
Regular keys (a-z, 0-9) are for typing text in edit forms.
"@

        Write-Host $helpText -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Press any key to return to PMC..." -ForegroundColor Yellow
        try {
            [Console]::ReadKey($true) | Out-Null
        } catch {
            # If ReadKey fails, just continue
        }
        $this.NeedsRedraw = $true
    }

    [void] Shutdown() {
        Write-Host "PMC FakeTUI shutting down..." -ForegroundColor Green

        try {
            # Restore cursor and clear screen
            [Console]::CursorVisible = $true
            $this.Terminal.WriteAt(0, 0, [PmcStringCache]::GetAnsiSequence("clear"))
            $this.Terminal.WriteAt(0, 0, [PmcStringCache]::GetAnsiSequence("showcursor"))
        } catch {
            # Cleanup failed, but don't throw
        }
    }
}

# No exports from this file; it defines classes used by Start-PmcFakeTUI
