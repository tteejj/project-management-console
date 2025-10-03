# PMC FakeTUI CLI Integration - Bridge between FakeTUI and PMC commands
# Maps menu actions to CLI commands and handles form input

<#
.SYNOPSIS
Adapter class to bridge FakeTUI actions to PMC CLI commands
.DESCRIPTION
This class maps the action strings from the menu system to actual
PMC CLI commands, handles form input for complex commands, and
manages the integration between the GUI and CLI systems.
#>
class PmcCLIAdapter {
    [object]$pmcCore  # Reference to PMC core functionality

    PmcCLIAdapter() {
        # Initialize connection to PMC core
        $this.pmcCore = $null  # Will be set by the main app
    }

    # Execute an action from the menu system
    [hashtable] ExecuteAction([string]$action) {
        Write-PmcDebug -Level 2 -Category 'FakeTUI' -Message "Executing action: $action"

        try {
            $parts = $action.Split(':')
            if ($parts.Count -ne 2) {
                return $this.CreateResult('error', "Invalid action format: $action")
            }

            $domain = $parts[0].ToLower()
            $command = $parts[1].ToLower()

            switch ($domain) {
                'app' { return $this.HandleAppActions($command) }
                'task' { return $this.HandleTaskActions($command) }
                'project' { return $this.HandleProjectActions($command) }
                'view' { return $this.HandleViewActions($command) }
                'file' { return $this.HandleFileActions($command) }
                'tools' { return $this.HandleToolsActions($command) }
                'help' { return $this.HandleHelpActions($command) }
                default {
                    return $this.CreateResult('error', "Unknown domain: $domain")
                }
            }
        } catch {
            Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Error executing action ${action}: $_"
            return $this.CreateResult('error', "Error executing action: $($_.Exception.Message)")
        }
        return $this.CreateResult('error', 'Unhandled action path')
    }

    # Application-level actions
    [hashtable] HandleAppActions([string]$command) {
        switch ($command) {
            'exit' {
                return $this.CreateResult('exit', 'Exiting PMC FakeTUI...')
            }
            default {
                return $this.CreateResult('error', "Unknown app command: $command")
            }
        }
        return $this.CreateResult('error','Unhandled app action')
    }

    # Task management actions
    [hashtable] HandleTaskActions([string]$command) {
        $taskId = $null
        switch ($command) {
            'add' {
                $form = $this.ShowTaskForm('new')
                if ($form -and $form.Text) {
                    $cliCommand = $this.BuildTaskAddCommand($form)
                    return $this.ExecuteCLICommand($cliCommand)
                }
                return $this.CreateResult('cancelled', 'Task creation cancelled')
            }
            'list' {
                $cliCommand = 'task list'
                return $this.ExecuteCLICommand($cliCommand)
            }
            'search' {
                $searchText = $this.PromptForText('Search tasks', 'Enter search term:')
                if ($searchText) {
                    $cliCommand = "task search text:$searchText"
                    return $this.ExecuteCLICommand($cliCommand)
                }
                return $this.CreateResult('cancelled', 'Search cancelled')
            }
            'done' {
                $taskId = $this.PromptForText('Mark Done', 'Enter task ID:')
                if ($taskId) {
                    $cliCommand = "task done $taskId"
                    return $this.ExecuteCLICommand($cliCommand)
                }
                return $this.CreateResult('cancelled', 'Mark done cancelled')
            }
            'edit' {
                $taskId = $this.PromptForText('Edit Task', 'Enter task ID:')
                if ($taskId) {
                    # Get existing task data first
                    $task = $this.GetTaskById($taskId)
                    if ($task) {
                        $form = $this.ShowTaskForm('edit', $task)
                        if ($form) {
                            $cliCommand = $this.BuildTaskEditCommand($taskId, $form)
                            return $this.ExecuteCLICommand($cliCommand)
                        }
                    }
                }
                return $this.CreateResult('cancelled', 'Task edit cancelled')
            }
            'delete' {
                $taskId = $this.PromptForText('Delete Task', 'Enter task ID:')
                if ($taskId -and $this.ConfirmAction(("Delete task #{0}?" -f $taskId))) {
                    $cliCommand = "task delete $taskId"
                    return $this.ExecuteCLICommand($cliCommand)
                }
                return $this.CreateResult('cancelled', 'Task deletion cancelled')
            }
            default {
                return $this.CreateResult('error', "Unknown task command: $command")
            }
        }
        return $this.CreateResult('error','Unhandled task action')
    }

    # Project management actions
    [hashtable] HandleProjectActions([string]$command) {
        switch ($command) {
            'create' {
                $projectName = $this.PromptForText('Create Project', 'Enter project name:')
                if ($projectName) {
                    $cliCommand = "project add name:'$projectName'"
                    return $this.ExecuteCLICommand($cliCommand)
                }
                return $this.CreateResult('cancelled', 'Project creation cancelled')
            }
            'switch' {
                $projects = $this.GetProjectList()
                if ($projects.Count -gt 0) {
                    $selected = $this.ShowSelectionList('Switch Project', $projects)
                    if ($selected) {
                        $cliCommand = "focus set @$selected"
                        return $this.ExecuteCLICommand($cliCommand)
                    }
                }
                return $this.CreateResult('cancelled', 'Project switch cancelled')
            }
            'stats' {
                $cliCommand = 'project stats'
                return $this.ExecuteCLICommand($cliCommand)
            }
            'archive' {
                $projects = $this.GetProjectList()
                if ($projects.Count -gt 0) {
                    $selected = $this.ShowSelectionList('Archive Project', $projects)
                    if ($selected -and $this.ConfirmAction("Archive project '$selected'?")) {
                        $cliCommand = "project archive '$selected'"
                        return $this.ExecuteCLICommand($cliCommand)
                    }
                }
                return $this.CreateResult('cancelled', 'Project archive cancelled')
            }
            default {
                return $this.CreateResult('error', "Unknown project command: $command")
            }
        }
        return $this.CreateResult('error','Unhandled project action')
    }

    # View actions
    [hashtable] HandleViewActions([string]$command) {
        switch ($command) {
            'today' {
                $cliCommand = 'view today'
                return $this.ExecuteCLICommand($cliCommand)
            }
            'week' {
                $cliCommand = 'view upcoming'
                return $this.ExecuteCLICommand($cliCommand)
            }
            'overdue' {
                $cliCommand = 'view overdue'
                return $this.ExecuteCLICommand($cliCommand)
            }
            'kanban' {
                # Use unified query engine with kanban view
                $cliCommand = 'q tasks view:kanban'
                return $this.ExecuteCLICommand($cliCommand)
            }
            'grid' {
                $cliCommand = 'task list'
                return $this.ExecuteCLICommand($cliCommand)
            }
            default {
                return $this.CreateResult('error', "Unknown view command: $command")
            }
        }
        return $this.CreateResult('error','Unhandled view action')
    }

    # File actions
    [hashtable] HandleFileActions([string]$command) {
        switch ($command) {
            'recent' {
                # Show recent projects or files
                return $this.CreateResult('info', 'Recent files feature not yet implemented')
            }
            default {
                return $this.CreateResult('error', "Unknown file command: $command")
            }
        }
        return $this.CreateResult('error','Unhandled file action')
    }

    # Tools actions
    [hashtable] HandleToolsActions([string]$command) {
        switch ($command) {
            'settings' {
                $cliCommand = 'config show'
                return $this.ExecuteCLICommand($cliCommand)
            }
            'theme' {
                $themes = @('default', 'dark', 'light')
                $selected = $this.ShowSelectionList('Select Theme', $themes)
                if ($selected) {
                    $cliCommand = "theme set $selected"
                    return $this.ExecuteCLICommand($cliCommand)
                }
                return $this.CreateResult('cancelled', 'Theme change cancelled')
            }
            'debug' {
                $cliCommand = 'system debug'
                return $this.ExecuteCLICommand($cliCommand)
            }
            'backup' {
                if ($this.ConfirmAction('Create backup of all PMC data?')) {
                    $cliCommand = 'system backup'
                    return $this.ExecuteCLICommand($cliCommand)
                }
                return $this.CreateResult('cancelled', 'Backup cancelled')
            }
            default {
                return $this.CreateResult('error', "Unknown tools command: $command")
            }
        }
        return $this.CreateResult('error','Unhandled tools action')
    }

    # Help actions
    [hashtable] HandleHelpActions([string]$command) {
        switch ($command) {
            'commands' {
                $cliCommand = 'help commands'
                return $this.ExecuteCLICommand($cliCommand)
            }
            'keys' {
                return $this.CreateResult('info', $this.GetKeyboardShortcutsText())
            }
            'guide' {
                $cliCommand = 'help guide'
                return $this.ExecuteCLICommand($cliCommand)
            }
            'about' {
                return $this.CreateResult('info', $this.GetAboutText())
            }
            default {
                return $this.CreateResult('error', "Unknown help command: $command")
            }
        }
        return $this.CreateResult('error','Unhandled help action')
    }

    # Execute PMC CLI command and return structured result
    [hashtable] ExecuteCLICommand([string]$command) {
        try {
            Write-PmcDebug -Level 2 -Category 'FakeTUI' -Message "Executing CLI command: $command"

            # Use PMC's existing command processor
            # Validate input safety before dispatch (best-effort)
            try {
                if (Get-Command Test-PmcInputSafety -ErrorAction SilentlyContinue) {
                    if (-not (Test-PmcInputSafety -Input $command -InputType 'command')) {
                        return $this.CreateResult('error', 'Command failed safety validation')
                    }
                }
            } catch { }

            $result = Invoke-PmcCommand $command

            return $this.CreateResult('success', "Command executed: $command", $result)
        } catch {
            Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "CLI command failed: $command - $_"
            return $this.CreateResult('error', "Command failed: $($_.Exception.Message)")
        }
    }

    # Helper method to create standardized results
    [hashtable] CreateResult([string]$type, [string]$message, [object]$data = $null) {
        return @{
            Type = $type
            Message = $message
            Data = $data
            Timestamp = Get-Date
        }
    }

    # Simple form for task input (placeholder - would be enhanced)
    [hashtable] ShowTaskForm([string]$mode, [object]$existingTask = $null) {
        # This is a simplified version - would be replaced with actual form UI
        Write-Host "`n=== $($mode.ToUpper()) TASK ===" -ForegroundColor Cyan

        $text = Read-Host "Task text"
        if ([string]::IsNullOrWhiteSpace($text)) { return $null }

        $due = Read-Host "Due date (optional)"
        $priority = Read-Host "Priority (1-3, optional)"
        $project = Read-Host "Project (optional)"

        return @{
            Text = $text.Trim()
            Due = if ($due) { $due.Trim() } else { $null }
            Priority = if ($priority) { $priority.Trim() } else { $null }
            Project = if ($project) { $project.Trim() } else { $null }
        }
    }

    # Simple text prompt (placeholder)
    [string] PromptForText([string]$title, [string]$prompt) {
        Write-Host "`n=== $title ===" -ForegroundColor Cyan
        $result = Read-Host $prompt
        return if ($result) { $result.Trim() } else { $null }
    }

    # Simple confirmation dialog
    [bool] ConfirmAction([string]$message) {
        Write-Host "`n$message" -ForegroundColor Yellow
        $response = Read-Host "Continue? (y/N)"
        return $response -match '^y(es)?$'
    }

    # Simple selection list (placeholder)
    [string] ShowSelectionList([string]$title, [string[]]$items) {
        Write-Host "`n=== $title ===" -ForegroundColor Cyan
        for ($i = 0; $i -lt $items.Count; $i++) {
            Write-Host "$($i + 1). $($items[$i])"
        }

        $choice = Read-Host "Select number (1-$($items.Count))"
        if ($choice -match '^\d+$') {
            $index = [int]$choice - 1
            if ($index -ge 0 -and $index -lt $items.Count) {
                return $items[$index]
            }
        }
        return $null
    }

    # Get project list from PMC data
    [string[]] GetProjectList() {
        try {
            $data = Get-PmcData
            return @($data.projects | ForEach-Object { $_.name })
        } catch {
            return @()
        }
    }

    # Get task by ID
    [object] GetTaskById([string]$taskId) {
        try {
            $data = Get-PmcData
            return $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1
        } catch {
            return $null
        }
    }

    # Build CLI command for task creation
    [string] BuildTaskAddCommand([hashtable]$form) {
        $sb = Get-PmcStringBuilder
        try {
            $text = $this.EscapeSingleQuoted($form.Text)
            $sb.Append("task add text:'$text'") | Out-Null

            if ($form.Due) {
                $due = $this.EscapeSingleQuoted($form.Due)
                $sb.Append(" due:'$due'") | Out-Null
            }
            if ($form.Priority) {
                $sb.Append(" p$($form.Priority)") | Out-Null
            }
            if ($form.Project) {
                $sb.Append(" @$($form.Project)") | Out-Null
            }

            return $sb.ToString()
        } finally {
            Return-PmcStringBuilder $sb
        }
    }

    # Build CLI command for task editing
    [string] BuildTaskEditCommand([string]$taskId, [hashtable]$form) {
        $sb = Get-PmcStringBuilder
        try {
            $sb.Append("task edit $taskId") | Out-Null

            if ($form.Text) {
                $text = $this.EscapeSingleQuoted($form.Text)
                $sb.Append(" text:'$text'") | Out-Null
            }
            if ($form.Due) {
                $due = $this.EscapeSingleQuoted($form.Due)
                $sb.Append(" due:'$due'") | Out-Null
            }
            if ($form.Priority) {
                $sb.Append(" p$($form.Priority)") | Out-Null
            }
            if ($form.Project) {
                $sb.Append(" @$($form.Project)") | Out-Null
            }

            return $sb.ToString()
        } finally {
            Return-PmcStringBuilder $sb
        }
    }

    # Escape strings for inclusion inside single quotes
    [string] EscapeSingleQuoted([string]$s) {
        if (-not $s) { return '' }
        return $s -replace "'", "''"
    }

    # Get keyboard shortcuts help text
    [string] GetKeyboardShortcutsText() {
        return @"
PMC FakeTUI Keyboard Shortcuts:

MENU NAVIGATION:
  Alt               Enter menu mode
  Alt+Letter        Direct menu access (Alt+F for File, Alt+T for Task, etc.)
  ←→                Navigate between menus
  ↑↓                Navigate within dropdowns
  Enter             Select menu item
  Esc               Exit menu mode / Cancel

GLOBAL SHORTCUTS:
  Ctrl+Q            Exit PMC
  F10               Enter menu mode (alternative to Alt)

MENU HOTKEYS:
  File Menu (Alt+F):   N=New Project, I=Import, E=Export, X=Exit
  Task Menu (Alt+T):   A=Add, L=List, S=Search, D=Done, E=Edit, X=Delete
  Project Menu (Alt+P): C=Create, S=Switch, T=Stats, A=Archive
  View Menu (Alt+V):   T=Today, W=Week, O=Overdue, K=Kanban, G=Grid
  Tools Menu (Alt+O):  S=Settings, T=Theme, D=Debug, B=Backup
  Help Menu (Alt+H):   C=Commands, K=Keys, G=Guide, A=About
"@
    }

    # Get about text
    [string] GetAboutText() {
        return @"
PMC - Project Management Console
FakeTUI Interface Version 1.0

A keyboard-driven interface for PMC that provides Excel/lynx-style
menu navigation while maintaining the power of the CLI underneath.

Features:
- Full keyboard navigation (no mouse required)
- Alt+key menu activation
- Integration with existing PMC commands
- Performance optimized rendering
- Static UI with selective updates (no constant redraws)

Built on PMC's existing CLI architecture with SpeedTUI performance optimizations.
"@
    }
}
