# TaskListScreen.ps1 - Complete Task List with CRUD + Filters
#
# Full-featured task list screen with:
# - UniversalList integration (sorting, virtual scrolling, multi-select)
# - FilterPanel integration (dynamic filtering by project, priority, due date, tags, status)
# - InlineEditor integration (full CRUD operations)
# - TaskStore integration (observable data layer with auto-refresh)
# - Keyboard shortcuts (CRUD operations, filters, search)
# - Custom actions (complete, archive, clone, bulk operations)
#
# Usage:
#   $screen = [TaskListScreen]::new()
#   $screen.Initialize()
#   $screen.Render()
#   $screen.HandleInput($key)

using namespace System

Set-StrictMode -Version Latest

# Ensure base class is loaded
# NOTE: Base class is now loaded by the launcher script in the correct order.
# Commenting out to avoid circular dependency issues.
# $baseClassPath = Join-Path $PSScriptRoot '../base/StandardListScreen.ps1'
# if (Test-Path $baseClassPath) {
#     . $baseClassPath
# }

<#
.SYNOPSIS
Complete task list screen with full CRUD and filtering

.DESCRIPTION
Extends StandardListScreen to provide:
- Full task CRUD (Create, Read, Update, Delete)
- Dynamic filtering (project, priority, due date, tags, status, text search)
- Sorting by any column
- Multi-select bulk operations
- Quick actions (complete, archive, clone)
- Auto-refresh on data changes
- Inline editing
- Comprehensive keyboard shortcuts

.EXAMPLE
$screen = [TaskListScreen]::new()
$screen.Initialize()
while (-not $screen.ShouldExit) {
    $output = $screen.Render()
    Write-Host $output
    $key = [Console]::ReadKey($true)
    $screen.HandleInput($key)
}
#>
class TaskListScreen : StandardListScreen {
    # Additional state
    [string]$_viewMode = 'all'  # all, active, completed, overdue, today, week
    [bool]$_showCompleted = $true
    [string]$_sortColumn = 'due'
    [bool]$_sortAscending = $true
    [hashtable]$_stats = @{}

    # Constructor
    TaskListScreen() : base("TaskList", "Task List") {
        $this._viewMode = 'active'
        $this._showCompleted = $false
        $this._sortColumn = 'due'
        $this._sortAscending = $true
    }

    # Implement abstract method: Load data from TaskStore
    [void] LoadData() {
        $allTasks = $this.Store.GetAllTasks()

        # Apply view mode filter
        $filteredTasks = switch ($this._viewMode) {
            'all' { $allTasks }
            'active' { $allTasks | Where-Object { -not $_.completed } }
            'completed' { $allTasks | Where-Object { $_.completed } }
            'overdue' {
                $allTasks | Where-Object {
                    -not $_.completed -and
                    $_.due -and
                    $_.due -lt [DateTime]::Today
                }
            }
            'today' {
                $allTasks | Where-Object {
                    -not $_.completed -and
                    $_.due -and
                    $_.due.Date -eq [DateTime]::Today
                }
            }
            'week' {
                $weekEnd = [DateTime]::Today.AddDays(7)
                $allTasks | Where-Object {
                    -not $_.completed -and
                    $_.due -and
                    $_.due -ge [DateTime]::Today -and
                    $_.due -le $weekEnd
                }
            }
            default { $allTasks }
        }

        # Apply completed filter if needed
        if (-not $this._showCompleted) {
            $filteredTasks = $filteredTasks | Where-Object { -not $_.completed }
        }

        # Apply sorting
        $sortedTasks = switch ($this._sortColumn) {
            'priority' { $filteredTasks | Sort-Object -Property priority -Descending:(-not $this._sortAscending) }
            'text' { $filteredTasks | Sort-Object -Property text -Descending:(-not $this._sortAscending) }
            'due' {
                # Sort with nulls last
                $withDue = $filteredTasks | Where-Object { $_.due }
                $withoutDue = $filteredTasks | Where-Object { -not $_.due }
                if ($this._sortAscending) {
                    ($withDue | Sort-Object -Property due) + $withoutDue
                } else {
                    ($withDue | Sort-Object -Property due -Descending) + $withoutDue
                }
            }
            'project' { $filteredTasks | Sort-Object -Property project -Descending:(-not $this._sortAscending) }
            default { $filteredTasks }
        }

        # Update stats
        $this._UpdateStats($allTasks)

        # Set data to list
        $this.List.SetData($sortedTasks)
    }

    # Implement abstract method: Define columns for UniversalList
    [array] GetColumns() {
        return @(
            @{
                Name = 'priority'
                Label = 'Pri'
                Width = 4
                Align = 'center'
                Format = { param($task)
                    if ($task.priority -ge 0 -and $task.priority -le 5) {
                        return $task.priority.ToString()
                    }
                    return '-'
                }
                Color = { param($task)
                    switch ($task.priority) {
                        5 { return "`e[91m" }  # Bright red
                        4 { return "`e[31m" }  # Red
                        3 { return "`e[33m" }  # Yellow
                        2 { return "`e[36m" }  # Cyan
                        1 { return "`e[37m" }  # White
                        0 { return "`e[90m" }  # Gray
                        default { return "`e[37m" }
                    }
                }
            },
            @{
                Name = 'text'
                Label = 'Task'
                Width = 45
                Align = 'left'
                Format = { param($task)
                    $text = $task.text
                    if ($task.completed) {
                        $text = "[✓] $text"
                    }
                    return $text
                }
                Color = { param($task)
                    if ($task.completed) {
                        return "`e[90m`e[9m"  # Gray + strikethrough
                    }
                    return "`e[37m"
                }
            },
            @{
                Name = 'due'
                Label = 'Due'
                Width = 12
                Align = 'left'
                Format = { param($task)
                    if (-not $task.due) { return '' }

                    $due = [DateTime]$task.due
                    $today = [DateTime]::Today
                    $diff = ($due.Date - $today).Days

                    if ($diff -eq 0) { return 'Today' }
                    elseif ($diff -eq 1) { return 'Tomorrow' }
                    elseif ($diff -eq -1) { return 'Yesterday' }
                    elseif ($diff -lt 0) { return "$([Math]::Abs($diff))d ago" }
                    elseif ($diff -le 7) { return "in ${diff}d" }
                    else { return $due.ToString('MMM dd') }
                }
                Color = { param($task)
                    if (-not $task.due -or $task.completed) { return "`e[90m" }

                    $due = [DateTime]$task.due
                    $diff = ($due.Date - [DateTime]::Today).Days

                    if ($diff -lt 0) { return "`e[91m" }      # Overdue: bright red
                    elseif ($diff -eq 0) { return "`e[93m" }  # Today: bright yellow
                    elseif ($diff -le 3) { return "`e[33m" }  # Soon: yellow
                    else { return "`e[36m" }                   # Future: cyan
                }
            },
            @{
                Name = 'project'
                Label = 'Project'
                Width = 15
                Align = 'left'
                Format = { param($task)
                    if ($task.project) { return $task.project }
                    return ''
                }
                Color = { param($task)
                    if ($task.project) { return "`e[96m" }  # Bright cyan
                    return "`e[90m"
                }
            },
            @{
                Name = 'tags'
                Label = 'Tags'
                Width = 20
                Align = 'left'
                Format = { param($task)
                    if ($task.tags -and $task.tags.Count -gt 0) {
                        return ($task.tags -join ', ')
                    }
                    return ''
                }
                Color = { param($task)
                    if ($task.tags -and $task.tags.Count -gt 0) {
                        return "`e[95m"  # Bright magenta
                    }
                    return "`e[90m"
                }
            }
        )
    }

    # Implement abstract method: Define edit fields for InlineEditor
    [array] GetEditFields([object]$item) {
        if ($null -eq $item -or $item.Count -eq 0) {
            # New task - empty fields
            return @(
                @{ Name='text'; Type='text'; Label='Task'; Required=$true; Value='' }
                @{ Name='priority'; Type='number'; Label='Priority'; Min=0; Max=5; Value=3 }
                @{ Name='due'; Type='date'; Label='Due Date'; Value=$null }
                @{ Name='project'; Type='project'; Label='Project'; Value='' }
                @{ Name='tags'; Type='tags'; Label='Tags'; Value=@() }
            )
        } else {
            # Existing task - populate from item
            return @(
                @{ Name='text'; Type='text'; Label='Task'; Required=$true; Value=$item.text }
                @{ Name='priority'; Type='number'; Label='Priority'; Min=0; Max=5; Value=$item.priority }
                @{ Name='due'; Type='date'; Label='Due Date'; Value=$item.due }
                @{ Name='project'; Type='project'; Label='Project'; Value=$item.project }
                @{ Name='tags'; Type='tags'; Label='Tags'; Value=$item.tags }
            )
        }
    }

    # Override: Handle item creation
    [void] OnItemCreated([hashtable]$values) {
        # Convert widget values to task format
        $taskData = @{
            text = $values.text
            priority = [int]$values.priority
            project = $values.project
            tags = $values.tags
            completed = $false
            created = [DateTime]::Now
        }

        # Add due date if provided
        if ($values.due) {
            $taskData.due = [DateTime]$values.due
        }

        # Add to store (auto-persists and fires events)
        $this.Store.AddTask($taskData)

        $this.SetStatusMessage("Task created: $($taskData.text)", "success")
    }

    # Override: Handle item update
    [void] OnItemUpdated([object]$item, [hashtable]$values) {
        # Build changes hashtable
        $changes = @{
            text = $values.text
            priority = [int]$values.priority
            project = $values.project
            tags = $values.tags
        }

        # Update due date
        if ($values.due) {
            $changes.due = [DateTime]$values.due
        } else {
            $changes.due = $null
        }

        # Update in store
        $this.Store.UpdateTask($item.id, $changes)

        $this.SetStatusMessage("Task updated: $($values.text)", "success")
    }

    # Override: Handle item deletion
    [void] OnItemDeleted([object]$item) {
        $this.Store.DeleteTask($item.id)
        $this.SetStatusMessage("Task deleted: $($item.text)", "success")
    }

    # Custom action: Toggle task completion
    [void] ToggleTaskCompletion([object]$task) {
        if ($null -eq $task) { return }

        $newStatus = -not $task.completed
        $this.Store.UpdateTask($task.id, @{ completed = $newStatus })

        $statusText = if ($newStatus) { "completed" } else { "reopened" }
        $this.SetStatusMessage("Task ${statusText}: $($task.text)", "success")
    }

    # Custom action: Mark task complete
    [void] CompleteTask([object]$task) {
        if ($null -eq $task) { return }

        $this.Store.UpdateTask($task.id, @{
            completed = $true
            completed_at = [DateTime]::Now
        })

        $this.SetStatusMessage("Task completed: $($task.text)", "success")
    }

    # Custom action: Clone task
    [void] CloneTask([object]$task) {
        if ($null -eq $task) { return }

        $clonedTask = @{
            text = "$($task.text) (copy)"
            priority = $task.priority
            project = $task.project
            tags = $task.tags
            completed = $false
            created = [DateTime]::Now
        }

        if ($task.due) {
            $clonedTask.due = $task.due
        }

        $this.Store.AddTask($clonedTask)
        $this.SetStatusMessage("Task cloned: $($clonedTask.text)", "success")
    }

    # Custom action: Bulk complete selected tasks
    [void] BulkCompleteSelected() {
        $selected = $this.List.GetSelectedItems()
        if ($selected.Count -eq 0) {
            $this.SetStatusMessage("No tasks selected", "warning")
            return
        }

        foreach ($task in $selected) {
            $this.Store.UpdateTask($task.id, @{
                completed = $true
                completed_at = [DateTime]::Now
            })
        }

        $this.SetStatusMessage("Completed $($selected.Count) tasks", "success")
        $this.List.ClearSelection()
    }

    # Custom action: Bulk delete selected tasks
    [void] BulkDeleteSelected() {
        $selected = $this.List.GetSelectedItems()
        if ($selected.Count -eq 0) {
            $this.SetStatusMessage("No tasks selected", "warning")
            return
        }

        foreach ($task in $selected) {
            $this.Store.DeleteTask($task.id)
        }

        $this.SetStatusMessage("Deleted $($selected.Count) tasks", "success")
        $this.List.ClearSelection()
    }

    # Change view mode
    [void] SetViewMode([string]$mode) {
        $validModes = @('all', 'active', 'completed', 'overdue', 'today', 'week')
        if ($mode -notin $validModes) {
            $this.SetStatusMessage("Invalid view mode: $mode", "error")
            return
        }

        $this._viewMode = $mode
        $this.LoadData()
        $this.SetStatusMessage("View: $mode", "info")
    }

    # Toggle show completed
    [void] ToggleShowCompleted() {
        $this._showCompleted = -not $this._showCompleted
        $this.LoadData()

        $status = if ($this._showCompleted) { "showing" } else { "hiding" }
        $this.SetStatusMessage("Now $status completed tasks", "info")
    }

    # Change sort column
    [void] SetSortColumn([string]$column) {
        if ($this._sortColumn -eq $column) {
            # Toggle sort direction
            $this._sortAscending = -not $this._sortAscending
        } else {
            $this._sortColumn = $column
            $this._sortAscending = $true
        }

        $this.LoadData()

        $direction = if ($this._sortAscending) { "ascending" } else { "descending" }
        $this.SetStatusMessage("Sorting by $column ($direction)", "info")
    }

    # Update statistics
    hidden [void] _UpdateStats([array]$allTasks) {
        # Handle null or empty tasks
        if ($null -eq $allTasks) {
            $allTasks = @()
        }

        $this._stats = @{
            Total = $allTasks.Count
            Active = @($allTasks | Where-Object { -not $_.completed }).Count
            Completed = @($allTasks | Where-Object { $_.completed }).Count
            Overdue = @($allTasks | Where-Object {
                -not $_.completed -and $_.due -and $_.due -lt [DateTime]::Today
            }).Count
            Today = @($allTasks | Where-Object {
                -not $_.completed -and $_.due -and $_.due.Date -eq [DateTime]::Today
            }).Count
            Week = @($allTasks | Where-Object {
                -not $_.completed -and $_.due -and
                $_.due -ge [DateTime]::Today -and
                $_.due -le [DateTime]::Today.AddDays(7)
            }).Count
        }
    }

    # Override: Additional keyboard shortcuts
    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Handle base class shortcuts first
        $handled = ([StandardListScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        # Custom shortcuts
        $key = $keyInfo.Key
        $ctrl = $keyInfo.Modifiers -band [ConsoleModifiers]::Control
        $alt = $keyInfo.Modifiers -band [ConsoleModifiers]::Alt

        # Space: Toggle task completion
        if ($key -eq [ConsoleKey]::Spacebar -and -not $ctrl -and -not $alt) {
            $selected = $this.List.GetSelectedItem()
            $this.ToggleTaskCompletion($selected)
            return $true
        }

        # C: Complete task
        if ($keyInfo.KeyChar -eq 'c' -or $keyInfo.KeyChar -eq 'C') {
            $selected = $this.List.GetSelectedItem()
            $this.CompleteTask($selected)
            return $true
        }

        # X: Clone task
        if ($keyInfo.KeyChar -eq 'x' -or $keyInfo.KeyChar -eq 'X') {
            $selected = $this.List.GetSelectedItem()
            $this.CloneTask($selected)
            return $true
        }

        # Ctrl+C: Bulk complete selected
        if ($key -eq [ConsoleKey]::C -and $ctrl) {
            $this.BulkCompleteSelected()
            return $true
        }

        # Ctrl+X: Bulk delete selected
        if ($key -eq [ConsoleKey]::X -and $ctrl) {
            $this.BulkDeleteSelected()
            return $true
        }

        # View mode shortcuts
        if ($keyInfo.KeyChar -eq '1') { $this.SetViewMode('all'); return $true }
        if ($keyInfo.KeyChar -eq '2') { $this.SetViewMode('active'); return $true }
        if ($keyInfo.KeyChar -eq '3') { $this.SetViewMode('completed'); return $true }
        if ($keyInfo.KeyChar -eq '4') { $this.SetViewMode('overdue'); return $true }
        if ($keyInfo.KeyChar -eq '5') { $this.SetViewMode('today'); return $true }
        if ($keyInfo.KeyChar -eq '6') { $this.SetViewMode('week'); return $true }

        # H: Toggle show completed
        if ($keyInfo.KeyChar -eq 'h' -or $keyInfo.KeyChar -eq 'H') {
            $this.ToggleShowCompleted()
            return $true
        }

        # S: Change sort (cycle through columns)
        if ($keyInfo.KeyChar -eq 's' -or $keyInfo.KeyChar -eq 'S') {
            $columns = @('priority', 'text', 'due', 'project')
            $currentIndex = $columns.IndexOf($this._sortColumn)
            $nextIndex = ($currentIndex + 1) % $columns.Count
            $this.SetSortColumn($columns[$nextIndex])
            return $true
        }

        return $false
    }

    # Override: Custom rendering (add header with stats and view mode)
    [string] Render() {
        $output = ""

        # Header with stats
        $header = "=== TASK LIST ==="
        $viewMode = $this._viewMode.ToUpper()
        $stats = "Total: $($this._stats.Total) | Active: $($this._stats.Active) | Completed: $($this._stats.Completed) | Overdue: $($this._stats.Overdue)"

        $output += "`e[1;36m$header`e[0m   `e[90m[$viewMode]`e[0m   `e[37m$stats`e[0m`n"
        $output += "`e[90m" + ("-" * 120) + "`e[0m`n"

        # Keyboard shortcuts help
        $help = "F:Filter  A:Add  E:Edit  D:Delete  Space:Toggle  C:Complete  X:Clone  1-6:Views  H:Show/Hide  S:Sort  Q:Quit"
        $output += "`e[90m$help`e[0m`n"
        $output += "`n"

        # Render base screen (UniversalList + FilterPanel + InlineEditor)
        $output += ([StandardListScreen]$this).Render()

        return $output
    }
}

# Export for use in other modules
if ($MyInvocation.MyCommand.Path) {
    Export-ModuleMember -Variable TaskListScreen
}
