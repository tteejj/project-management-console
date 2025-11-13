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

# Helper function to get title based on view mode
function Get-TaskListTitle {
    param([string]$viewMode)
    switch ($viewMode) {
        'all' { return 'All Tasks' }
        'active' { return 'Active Tasks' }
        'completed' { return 'Completed Tasks' }
        'overdue' { return 'Overdue Tasks' }
        'today' { return "Today's Tasks" }
        'tomorrow' { return "Tomorrow's Tasks" }
        'week' { return 'This Week' }
        'nextactions' { return 'Next Actions' }
        'noduedate' { return 'No Due Date' }
        'month' { return 'This Month' }
        'agenda' { return 'Agenda View' }
        'upcoming' { return 'Upcoming Tasks' }
        default { return 'Task List' }
    }
}

class TaskListScreen : StandardListScreen {
    # Additional state
    [string]$_viewMode = 'all'  # all, active, completed, overdue, today, tomorrow, week, nextactions, noduedate, month, agenda, upcoming
    [bool]$_showCompleted = $true
    [string]$_sortColumn = 'due'
    [bool]$_sortAscending = $true
    [hashtable]$_stats = @{}

    # Caching for performance
    hidden [array]$_cachedFilteredTasks = $null
    hidden [string]$_cacheKey = ""  # viewMode:sortColumn:sortAsc:showCompleted

    # L-POL-14: Strikethrough support detection
    hidden [bool]$_supportsStrikethrough = $true  # Assume support, can be overridden

    # Constructor with optional view mode
    TaskListScreen() : base("TaskList", "Task List") {
        $this._viewMode = 'active'
        $this._showCompleted = $false
        $this._sortColumn = 'due'
        $this._sortAscending = $true

        # Setup menus after base constructor
        $this._SetupMenus()
    }

    # Constructor with container (DI-enabled)
    TaskListScreen([object]$container) : base("TaskList", "Task List", $container) {
        $this._viewMode = 'active'
        $this._showCompleted = $false
        $this._sortColumn = 'due'
        $this._sortAscending = $true

        # Setup menus after base constructor
        $this._SetupMenus()
    }

    # Constructor with explicit view mode
    TaskListScreen([string]$viewMode) : base("TaskList", (Get-TaskListTitle $viewMode)) {
        $this._viewMode = $viewMode
        $this._showCompleted = $false
        $this._sortColumn = 'due'
        $this._sortAscending = $true

        # Setup menus after base constructor
        $this._SetupMenus()
    }

    # Constructor with container and view mode (DI-enabled)
    TaskListScreen([object]$container, [string]$viewMode) : base("TaskList", (Get-TaskListTitle $viewMode), $container) {
        $this._viewMode = $viewMode
        $this._showCompleted = $false
        $this._sortColumn = 'due'
        $this._sortAscending = $true

        # Setup menus after base constructor
        $this._SetupMenus()
    }

    # Override to add cache invalidation to TaskStore event handler
    hidden [void] _InitializeComponents() {
        # Call parent initialization first
        ([StandardListScreen]$this)._InitializeComponents()

        # CRITICAL FIX: Override the TaskStore event handler to invalidate cache before refresh
        $self = $this
        $this.Store.OnTasksChanged = {
            param($tasks)
            # Invalidate cache so LoadData will reload
            $self._cachedFilteredTasks = $null
            $self._cacheKey = ""
            # Then refresh the list
            if ($self.IsActive) {
                $self.RefreshList()
            }
        }.GetNewClosure()
    }

    # Setup menu items using MenuRegistry
    hidden [void] _SetupMenus() {
        # Get MenuRegistry from DI container
        if ($this.Container) {
            $registry = $this.Container.Resolve('MenuRegistry')
        } else {
            $registry = $global:Pmc.Container.Resolve('MenuRegistry')
        }

        # Load menu items from manifest (only if not already loaded)
        $tasksMenuItems = $registry.GetMenuItems('Tasks')
        if (-not $tasksMenuItems -or @($tasksMenuItems).Count -eq 0) {
            $manifestPath = Join-Path $PSScriptRoot "MenuItems.psd1"

            # Get or create the service container
            if (-not $global:PmcContainer) {
                # Load ServiceContainer if not already loaded
                . "$PSScriptRoot/../ServiceContainer.ps1"
                $global:PmcContainer = [ServiceContainer]::new()

                if ($global:PmcTuiLogFile) {
                    Write-PmcTuiLog "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TaskListScreen: Created new ServiceContainer" "INFO"
                }
            }

            # Load manifest with container
            $registry.LoadFromManifest($manifestPath, $global:PmcContainer)
        }

        # Build menus from registry
        $this._PopulateMenusFromRegistry($registry)

        # Store populated MenuBar globally for other screens to use
        $global:PmcSharedMenuBar = $this.MenuBar
    }

    # Populate MenuBar from registry
    hidden [void] _PopulateMenusFromRegistry([object]$registry) {
        $menuMapping = @{
            'Tasks' = 0
            'Projects' = 1
            'Time' = 2
            'Tools' = 3
            'Options' = 4
            'Help' = 5
        }

        foreach ($menuName in $menuMapping.Keys) {
            $menuIndex = $menuMapping[$menuName]

            # CRITICAL: Validate menu index bounds before access
            if ($null -eq $this.MenuBar -or $null -eq $this.MenuBar.Menus) {
                Write-PmcTuiLog "MenuBar or Menus collection is null - cannot populate menus" "ERROR"
                continue
            }

            if ($menuIndex -lt 0 -or $menuIndex -ge $this.MenuBar.Menus.Count) {
                Write-PmcTuiLog "Menu index $menuIndex out of range (0-$($this.MenuBar.Menus.Count-1))" "ERROR"
                continue
            }

            $menu = $this.MenuBar.Menus[$menuIndex]
            $items = $registry.GetMenuItems($menuName)

            if ($global:PmcTuiLogFile) {
                if ($null -eq $items) {
                    Write-PmcTuiLog "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _PopulateMenusFromRegistry: Menu '$menuName' has 0 items from registry (null)" "INFO"
                } elseif ($items -is [array]) {
                    Write-PmcTuiLog "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _PopulateMenusFromRegistry: Menu '$menuName' has $($items.Count) items from registry (array)" "INFO"
                } else {
                    Write-PmcTuiLog "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _PopulateMenusFromRegistry: Menu '$menuName' has 1 item from registry (type: $($items.GetType().Name))" "INFO"
                }
            }

            if ($null -ne $items) {
                # CRITICAL: Clear existing items to prevent duplication
                $menu.Items.Clear()

                foreach ($item in $items) {
                    # MenuRegistry returns hashtables, use hashtable indexing
                    $menuItem = [PmcMenuItem]::new($item['Label'], $item['Hotkey'], $item['Action'])
                    $menu.Items.Add($menuItem)
                }
            }
        }
    }

    # Implement abstract method: Load data from TaskStore
    [void] LoadData() {
        # Build cache key from current filter/sort settings
        $currentKey = "$($this._viewMode):$($this._sortColumn):$($this._sortAscending):$($this._showCompleted)"

        # Return cached result if nothing changed
        if ($this._cacheKey -eq $currentKey -and $null -ne $this._cachedFilteredTasks) {
            $this.List.SetData($this._cachedFilteredTasks)
            # Force full re-render when data changes
            if ($this.RenderEngine -and $this.RenderEngine.PSObject.Methods['RequestClear']) {
                $this.RenderEngine.RequestClear()
            }
            return
        }

        $allTasks = $this.Store.GetAllTasks()

        # Null check to prevent crashes
        if ($null -eq $allTasks -or $allTasks.Count -eq 0) {
            $this.List.SetData(@())
            $this._cachedFilteredTasks = @()
            $this._cacheKey = $currentKey
            return
        }

        # NOTE: TaskStore already converts to hashtables in LoadData (TaskStore.ps1:233-242)
        # No need for redundant type conversion here - removed for performance

        # Apply view mode filter
        $filteredTasks = switch ($this._viewMode) {
            'all' { $allTasks }
            'active' { $allTasks | Where-Object { -not (Get-SafeProperty $_ 'completed') } }
            'completed' { $allTasks | Where-Object { Get-SafeProperty $_ 'completed' } }
            'overdue' {
                $allTasks | Where-Object {
                    $due = Get-SafeProperty $_ 'due'
                    -not (Get-SafeProperty $_ 'completed') -and
                    $due -and
                    $due -lt [DateTime]::Today
                }
            }
            'today' {
                $allTasks | Where-Object {
                    $due = Get-SafeProperty $_ 'due'
                    -not (Get-SafeProperty $_ 'completed') -and
                    $due -and
                    $due.Date -eq [DateTime]::Today
                }
            }
            'tomorrow' {
                $tomorrow = [DateTime]::Today.AddDays(1)
                $allTasks | Where-Object {
                    $due = Get-SafeProperty $_ 'due'
                    -not (Get-SafeProperty $_ 'completed') -and
                    $due -and
                    $due.Date -eq $tomorrow
                }
            }
            'week' {
                $weekEnd = [DateTime]::Today.AddDays(7)
                $allTasks | Where-Object {
                    $due = Get-SafeProperty $_ 'due'
                    -not (Get-SafeProperty $_ 'completed') -and
                    $due -and
                    $due -ge [DateTime]::Today -and
                    $due -le $weekEnd
                }
            }
            'nextactions' {
                # Tasks with no dependencies or all dependencies completed
                $allTasks | Where-Object {
                    $dependsOn = Get-SafeProperty $_ 'depends_on'
                    -not (Get-SafeProperty $_ 'completed') -and
                    (-not $dependsOn -or (-not ($dependsOn -is [array])) -or $dependsOn.Count -eq 0)
                }
            }
            'noduedate' {
                $allTasks | Where-Object {
                    -not (Get-SafeProperty $_ 'completed') -and
                    -not (Get-SafeProperty $_ 'due')
                }
            }
            'month' {
                $monthEnd = [DateTime]::Today.AddDays(30)
                $allTasks | Where-Object {
                    $due = Get-SafeProperty $_ 'due'
                    -not (Get-SafeProperty $_ 'completed') -and
                    $due -and
                    $due -ge [DateTime]::Today -and
                    $due -le $monthEnd
                }
            }
            'agenda' {
                # All tasks with due dates, sorted by date
                $allTasks | Where-Object {
                    -not (Get-SafeProperty $_ 'completed') -and
                    (Get-SafeProperty $_ 'due')
                }
            }
            'upcoming' {
                # Tasks due in the future (beyond today)
                $allTasks | Where-Object {
                    $due = Get-SafeProperty $_ 'due'
                    -not (Get-SafeProperty $_ 'completed') -and
                    $due -and
                    $due.Date -gt [DateTime]::Today
                }
            }
            default { $allTasks }
        }

        # Null check after filtering to prevent crashes
        if ($null -eq $filteredTasks) { $filteredTasks = @() }

        # Apply completed filter if needed
        if (-not $this._showCompleted) {
            $filteredTasks = $filteredTasks | Where-Object { -not (Get-SafeProperty $_ 'completed') }
            # Null check after additional filtering
            if ($null -eq $filteredTasks) { $filteredTasks = @() }
        }

        # Apply sorting
        $sortedTasks = switch ($this._sortColumn) {
            'priority' { $filteredTasks | Sort-Object { Get-SafeProperty $_ 'priority' } -Descending:(-not $this._sortAscending) }
            'text' { $filteredTasks | Sort-Object { Get-SafeProperty $_ 'text' } -Descending:(-not $this._sortAscending) }
            'due' {
                # Sort with nulls last
                $withDue = @($filteredTasks | Where-Object { Get-SafeProperty $_ 'due' })
                $withoutDue = @($filteredTasks | Where-Object { -not (Get-SafeProperty $_ 'due') })
                if ($this._sortAscending) {
                    @($withDue | Sort-Object { Get-SafeProperty $_ 'due' }) + $withoutDue
                } else {
                    @($withDue | Sort-Object { Get-SafeProperty $_ 'due' } -Descending) + $withoutDue
                }
            }
            'project' { $filteredTasks | Sort-Object { Get-SafeProperty $_ 'project' } -Descending:(-not $this._sortAscending) }
            default { $filteredTasks }
        }

        # Null check after sorting to prevent crashes
        if ($null -eq $sortedTasks) { $sortedTasks = @() }

        # Reorganize to group subtasks with parents - OPTIMIZED O(n) using hashtable index
        $organized = [System.Collections.ArrayList]::new()
        $processedIds = @{}

        # Build hashtable index of children by parent_id - O(n)
        $childrenByParent = @{}
        foreach ($task in $sortedTasks) {
            $parentId = Get-SafeProperty $task 'parent_id'
            if ($parentId) {
                if (-not $childrenByParent.ContainsKey($parentId)) {
                    $childrenByParent[$parentId] = [System.Collections.ArrayList]::new()
                }
                [void]$childrenByParent[$parentId].Add($task)
            }
        }

        # Process all parent tasks and their children - O(n)
        foreach ($task in $sortedTasks) {
            $taskId = Get-SafeProperty $task 'id'
            $parentId = Get-SafeProperty $task 'parent_id'

            # Skip if already processed (was added as subtask)
            if ($processedIds.ContainsKey($taskId)) { continue }

            # Add parent task only if it has no parent
            if (-not $parentId) {
                [void]$organized.Add($task)
                $processedIds[$taskId] = $true

                # Add all children immediately after parent using hashtable lookup - O(1)
                if ($childrenByParent.ContainsKey($taskId)) {
                    foreach ($subtask in $childrenByParent[$taskId]) {
                        $subId = Get-SafeProperty $subtask 'id'
                        if (-not $processedIds.ContainsKey($subId)) {
                            [void]$organized.Add($subtask)
                            $processedIds[$subId] = $true
                        }
                    }
                }
            }
        }

        # Add orphaned subtasks at the end (subtasks whose parent was filtered out or deleted)
        foreach ($task in $sortedTasks) {
            $taskId = Get-SafeProperty $task 'id'
            if (-not $processedIds.ContainsKey($taskId)) {
                [void]$organized.Add($task)
                $processedIds[$taskId] = $true
            }
        }

        $sortedTasks = $organized

        # Update stats
        $this._UpdateStats($allTasks)

        # Cache the filtered/sorted result
        $this._cachedFilteredTasks = $sortedTasks
        $this._cacheKey = $currentKey

        # DEBUG: Log the data being set
        Write-PmcTuiLog "TaskListScreen.LoadData: Setting $($sortedTasks.Count) tasks to list (viewMode=$($this._viewMode), allTasks=$($allTasks.Count), filtered=$($filteredTasks.Count))" "DEBUG"

        # Set data to list
        $this.List.SetData($sortedTasks)

        # Force full re-render when data changes
        if ($this.RenderEngine -and $this.RenderEngine.PSObject.Methods['RequestClear']) {
            $this.RenderEngine.RequestClear()
        }
    }

    # Override to invalidate cache when data changes
    hidden [void] _OnTaskStoreDataChanged() {
        $this._cachedFilteredTasks = $null
        $this._cacheKey = ""
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
                    $priority = Get-SafeProperty $task 'priority'
                    if ($null -ne $priority -and $priority -is [int] -and $priority -ge 0 -and $priority -le 5) {
                        return $priority.ToString()
                    }
                    return '-'
                }
                Color = { param($task)
                    switch (Get-SafeProperty $task 'priority') {
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
                    $text = Get-SafeProperty $task 'text'
                    # L-POL-13: Indent subtasks with 4 spaces if they have a parent
                    $hasParent = Test-SafeProperty $task 'parent_id' -and (Get-SafeProperty $task 'parent_id')
                    if ($hasParent) {
                        $text = "    $text"  # 4 spaces instead of 2
                    }
                    if (Get-SafeProperty $task 'completed') {
                        $text = "[✓] $text"
                    }
                    return $text
                }
                Color = { param($task)
                    if (Get-SafeProperty $task 'completed') {
                        # L-POL-14: Use strikethrough or [DONE] prefix depending on terminal support
                        if ($this._supportsStrikethrough) {
                            return "`e[90m`e[9m"  # Gray + strikethrough
                        } else {
                            # Fallback already applied in Format (adds [DONE] prefix)
                            return "`e[90m"  # Just gray
                        }
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
                    $dueValue = Get-SafeProperty $task 'due'
                    if (-not $dueValue) { return '' }

                    $due = [DateTime]$dueValue
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
                    $dueValue = Get-SafeProperty $task 'due'
                    if (-not $dueValue -or (Get-SafeProperty $task 'completed')) { return "`e[90m" }

                    $due = [DateTime]$dueValue
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
                    $project = Get-SafeProperty $task 'project'
                    if ($project) { return $project }
                    return ''
                }
                Color = { param($task)
                    if (Get-SafeProperty $task 'project') { return "`e[96m" }  # Bright cyan
                    return "`e[90m"
                }
            },
            @{
                Name = 'tags'
                Label = 'Tags'
                Width = 20
                Align = 'left'
                Format = { param($task)
                    $tags = Get-SafeProperty $task 'tags'
                    if ($tags -and $tags -is [array] -and $tags.Count -gt 0) {
                        return ($tags -join ', ')
                    }
                    return ''
                }
                Color = { param($task)
                    $tags = Get-SafeProperty $task 'tags'
                    if ($tags -and $tags -is [array] -and $tags.Count -gt 0) {
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
                @{ Name='text'; Type='text'; Label='Task'; Required=$true; MaxLength=200; Value='' }  # H-VAL-6
                @{ Name='priority'; Type='number'; Label='Priority'; Min=0; Max=5; Value=3 }
                @{ Name='due'; Type='date'; Label='Due Date'; Value=$null }
                @{ Name='project'; Type='project'; Label='Project'; Value='' }
                @{ Name='tags'; Type='tags'; Label='Tags'; Value=@() }
            )
        } else {
            # Existing task - populate from item with safe property access
            return @(
                @{ Name='text'; Type='text'; Label='Task'; Required=$true; MaxLength=200; Value=(Get-SafeProperty $item 'text') }  # H-VAL-6
                @{ Name='priority'; Type='number'; Label='Priority'; Min=0; Max=5; Value=(Get-SafeProperty $item 'priority') }
                @{ Name='due'; Type='date'; Label='Due Date'; Value=(Get-SafeProperty $item 'due') }
                @{ Name='project'; Type='project'; Label='Project'; Value=(Get-SafeProperty $item 'project') }
                @{ Name='tags'; Type='tags'; Label='Tags'; Value=(Get-SafeProperty $item 'tags') }
            )
        }
    }

    # Override: Handle item creation
    [void] OnItemCreated([hashtable]$values) {
        try {
            # RUNTIME FIX: Safe conversion of priority with fallback to default
            $priority = 3  # Default priority
            if ($values.ContainsKey('priority') -and $null -ne $values.priority) {
                try {
                    $priority = [int]$values.priority
                } catch {
                    Write-PmcTuiLog "Failed to convert priority '$($values.priority)' to int, using default 3" "WARNING"
                }
            }

            # Convert widget values to task format
            # FIX: Convert "(No Project)" to empty string
            $projectValue = ''
            if ($values.ContainsKey('project') -and $values.project -ne '(No Project)') {
                $projectValue = $values.project
            }

            $taskData = @{
                text = if ($values.ContainsKey('text')) { $values.text } else { '' }
                priority = $priority
                project = $projectValue
                tags = if ($values.ContainsKey('tags')) { $values.tags } else { @() }
                completed = $false
                created = [DateTime]::Now
            }

            # Add due date if provided
            if ($values.ContainsKey('due') -and $values.due) {
                try {
                    $taskData.due = [DateTime]$values.due
                } catch {
                    Write-PmcTuiLog "Failed to convert due date '$($values.due)', omitting" "WARNING"
                }
            }

            # H-VAL-3: Preserve parent_id from CurrentEditItem if it exists (for subtasks)
            # FIX: Safe property access for parent_id
            if ($this.CurrentEditItem) {
                $parentId = Get-SafeProperty $this.CurrentEditItem 'parent_id'
                if ($parentId) {
                    $taskData.parent_id = $parentId
                }
            }

            # Add to store (auto-persists and fires events)
            $success = $this.Store.AddTask($taskData)
            if ($success) {
                $this.SetStatusMessage("Task created: $($taskData.text)", "success")
            } else {
                $this.SetStatusMessage("Failed to create task: $($this.Store.LastError)", "error")
            }
        }
        catch {
            Write-PmcTuiLog "OnItemCreated exception: $_" "ERROR"
            $this.SetStatusMessage("Unexpected error: $($_.Exception.Message)", "error")
        }
    }

    # Override: Handle item update
    [void] OnItemUpdated([object]$item, [hashtable]$values) {
        try {
            # RUNTIME FIX: Safe conversion of priority with fallback
            $priority = 3  # Default priority
            if ($values.ContainsKey('priority') -and $null -ne $values.priority) {
                try {
                    $priority = [int]$values.priority
                } catch {
                    Write-PmcTuiLog "Failed to convert priority '$($values.priority)' to int, using default 3" "WARNING"
                }
            }

            # Build changes hashtable
            # FIX: Convert "(No Project)" to empty string
            $projectValue = ''
            if ($values.ContainsKey('project') -and $values.project -ne '(No Project)') {
                $projectValue = $values.project
            }

            $changes = @{
                text = if ($values.ContainsKey('text')) { $values.text } else { '' }
                priority = $priority
                project = $projectValue
                tags = if ($values.ContainsKey('tags')) { $values.tags } else { @() }
            }

            # Update due date
            if ($values.ContainsKey('due') -and $values.due) {
                try {
                    $changes.due = [DateTime]$values.due
                } catch {
                    Write-PmcTuiLog "Failed to convert due date '$($values.due)', setting to null" "WARNING"
                    $changes.due = $null
                }
            } else {
                $changes.due = $null
            }

            # Update in store
            $success = $this.Store.UpdateTask($item.id, $changes)
            if ($success) {
                $this.SetStatusMessage("Task updated: $($values.text)", "success")
            } else {
                $this.SetStatusMessage("Failed to update task: $($this.Store.LastError)", "error")
            }
        }
        catch {
            Write-PmcTuiLog "OnItemUpdated exception: $_" "ERROR"
            $this.SetStatusMessage("Unexpected error: $($_.Exception.Message)", "error")
        }
    }

    # Override: Handle item deletion
    [void] OnItemDeleted([object]$item) {
        try {
            $success = $this.Store.DeleteTask($item.id)
            if ($success) {
                $this.SetStatusMessage("Task deleted: $($item.text)", "success")
            } else {
                $this.SetStatusMessage("Failed to delete task: $($this.Store.LastError)", "error")
            }
        }
        catch {
            Write-PmcTuiLog "OnItemDeleted exception: $_" "ERROR"
            $this.SetStatusMessage("Unexpected error: $($_.Exception.Message)", "error")
        }
    }

    # Custom action: Toggle task completion
    [void] ToggleTaskCompletion([object]$task) {
        if ($null -eq $task) { return }

        $completed = Get-SafeProperty $task 'completed'
        $taskId = Get-SafeProperty $task 'id'
        $taskText = Get-SafeProperty $task 'text'

        $newStatus = -not $completed
        $this.Store.UpdateTask($taskId, @{ completed = $newStatus })

        $statusText = if ($newStatus) { "completed" } else { "reopened" }
        $this.SetStatusMessage("Task ${statusText}: $taskText", "success")
    }

    # Custom action: Mark task complete
    [void] CompleteTask([object]$task) {
        if ($null -eq $task) { return }

        $taskId = Get-SafeProperty $task 'id'
        $taskText = Get-SafeProperty $task 'text'

        $this.Store.UpdateTask($taskId, @{
            completed = $true
            completed_at = [DateTime]::Now
        })

        $this.SetStatusMessage("Task completed: $taskText", "success")
    }

    # Custom action: Clone task
    [void] CloneTask([object]$task) {
        if ($null -eq $task) { return }

        $taskText = Get-SafeProperty $task 'text'
        $taskPriority = Get-SafeProperty $task 'priority'
        $taskProject = Get-SafeProperty $task 'project'
        $taskTags = Get-SafeProperty $task 'tags'
        $taskDue = Get-SafeProperty $task 'due'

        $clonedTask = @{
            text = "$taskText (copy)"
            priority = $taskPriority
            project = $taskProject
            tags = $taskTags
            completed = $false
            created = [DateTime]::Now
        }

        if ($taskDue) {
            $clonedTask.due = $taskDue
        }

        $this.Store.AddTask($clonedTask)
        $this.SetStatusMessage("Task cloned: $($clonedTask.text)", "success")
    }

    # H-VAL-3: Check for circular dependency in task hierarchy
    hidden [bool] _IsCircularDependency([string]$parentId, [string]$childId) {
        $current = $parentId
        $visited = @{}

        while ($current) {
            # If we encounter the child ID in the parent chain, it's circular
            if ($current -eq $childId) { return $true }

            # Detect infinite loop (same parent visited twice)
            if ($visited.ContainsKey($current)) { return $true }
            $visited[$current] = $true

            # Get the parent of the current task
            $task = $this.Store.GetTask($current)
            $current = if ($task) { Get-SafeProperty $task 'parent_id' } else { $null }
        }

        return $false
    }

    # Custom action: Add subtask
    [void] AddSubtask([object]$parentTask) {
        if ($null -eq $parentTask) { return }

        # Get parent id
        $parentId = if ($parentTask -is [hashtable]) { $parentTask['id'] } else { $parentTask.id }

        # Create new task with parent_id set
        $subtask = @{
            text = ""
            priority = 3
            project = ""
            tags = @()
            completed = $false
            created = [DateTime]::Now
            parent_id = $parentId
        }

        # Open inline editor in 'add' mode with parent_id pre-filled
        $this.EditorMode = 'add'
        $this.CurrentEditItem = $subtask
        $fields = $this.GetEditFields($subtask)
        $this.InlineEditor.SetFields($fields)
        $this.InlineEditor.Title = "Add Subtask"
        $this.ShowInlineEditor = $true
    }

    # Custom action: Bulk complete selected tasks
    [void] BulkCompleteSelected() {
        $selected = $this.List.GetSelectedItems()
        if ($selected.Count -eq 0) {
            $this.SetStatusMessage("No tasks selected", "warning")
            return
        }

        foreach ($task in $selected) {
            $taskId = Get-SafeProperty $task 'id'
            $this.Store.UpdateTask($taskId, @{
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
            $taskId = Get-SafeProperty $task 'id'
            $this.Store.DeleteTask($taskId)
        }

        $this.SetStatusMessage("Deleted $($selected.Count) tasks", "success")
        $this.List.ClearSelection()
    }

    # Change view mode
    [void] SetViewMode([string]$mode) {
        $validModes = @('all', 'active', 'completed', 'overdue', 'today', 'tomorrow', 'week', 'nextactions', 'noduedate', 'month', 'agenda', 'upcoming')
        if ($mode -notin $validModes) {
            $this.SetStatusMessage("Invalid view mode: $mode", "error")
            return
        }

        $this._viewMode = $mode
        $titleText = Get-TaskListTitle $mode
        $this.ScreenTitle = $titleText
        if ($this.List) {
            $this.List.Title = $titleText
        }
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

        $tomorrow = [DateTime]::Today.AddDays(1)
        $weekEnd = [DateTime]::Today.AddDays(7)
        $monthEnd = [DateTime]::Today.AddDays(30)

        $this._stats = @{
            Total = $allTasks.Count
            Active = @($allTasks | Where-Object { -not (Get-SafeProperty $_ 'completed') }).Count
            Completed = @($allTasks | Where-Object { Get-SafeProperty $_ 'completed' }).Count
            Overdue = @($allTasks | Where-Object {
                $due = Get-SafeProperty $_ 'due'
                -not (Get-SafeProperty $_ 'completed') -and $due -and $due -lt [DateTime]::Today
            }).Count
            Today = @($allTasks | Where-Object {
                $due = Get-SafeProperty $_ 'due'
                -not (Get-SafeProperty $_ 'completed') -and $due -and $due.Date -eq [DateTime]::Today
            }).Count
            Tomorrow = @($allTasks | Where-Object {
                $due = Get-SafeProperty $_ 'due'
                -not (Get-SafeProperty $_ 'completed') -and $due -and $due.Date -eq $tomorrow
            }).Count
            Week = @($allTasks | Where-Object {
                $due = Get-SafeProperty $_ 'due'
                -not (Get-SafeProperty $_ 'completed') -and $due -and
                $due -ge [DateTime]::Today -and
                $due -le $weekEnd
            }).Count
            Month = @($allTasks | Where-Object {
                $due = Get-SafeProperty $_ 'due'
                -not (Get-SafeProperty $_ 'completed') -and $due -and
                $due -ge [DateTime]::Today -and
                $due -le $monthEnd
            }).Count
            NextActions = @($allTasks | Where-Object {
                $dependsOn = Get-SafeProperty $_ 'depends_on'
                -not (Get-SafeProperty $_ 'completed') -and
                (-not $dependsOn -or (-not ($dependsOn -is [array])) -or $dependsOn.Count -eq 0)
            }).Count
            NoDueDate = @($allTasks | Where-Object {
                -not (Get-SafeProperty $_ 'completed') -and -not (Get-SafeProperty $_ 'due')
            }).Count
            Upcoming = @($allTasks | Where-Object {
                $due = Get-SafeProperty $_ 'due'
                -not (Get-SafeProperty $_ 'completed') -and $due -and $due.Date -gt [DateTime]::Today
            }).Count
        }
    }

    # Get custom actions for footer display
    [array] GetCustomActions() {
        $self = $this
        return @(
            @{ Key='c'; Label='Complete'; Callback={
                $selected = $self.List.GetSelectedItem()
                $self.CompleteTask($selected)
            }.GetNewClosure() }
            @{ Key='x'; Label='Clone'; Callback={
                $selected = $self.List.GetSelectedItem()
                $self.CloneTask($selected)
            }.GetNewClosure() }
            @{ Key='s'; Label='Subtask'; Callback={
                $selected = $self.List.GetSelectedItem()
                if ($selected) {
                    $self.AddSubtask($selected)
                }
            }.GetNewClosure() }
            @{ Key='h'; Label='Hide Done'; Callback={
                $self.ToggleShowCompleted()
            }.GetNewClosure() }
            @{ Key='1'; Label='All'; Callback={
                $self.SetViewMode('all')
            }.GetNewClosure() }
            @{ Key='2'; Label='Active'; Callback={
                $self.SetViewMode('active')
            }.GetNewClosure() }
            @{ Key='3'; Label='Done'; Callback={
                $self.SetViewMode('completed')
            }.GetNewClosure() }
            @{ Key='4'; Label='Overdue'; Callback={
                $self.SetViewMode('overdue')
            }.GetNewClosure() }
            @{ Key='5'; Label='Today'; Callback={
                $self.SetViewMode('today')
            }.GetNewClosure() }
            @{ Key='6'; Label='Week'; Callback={
                $self.SetViewMode('week')
            }.GetNewClosure() }
        )
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

        # S: Add subtask
        if ($keyInfo.KeyChar -eq 's' -or $keyInfo.KeyChar -eq 'S') {
            $selected = $this.List.GetSelectedItem()
            if ($selected) {
                $this.AddSubtask($selected)
            }
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

    # Static: Register menu items for all view modes
    static [void] RegisterMenuItems([object]$registry) {
        # Task List (all tasks)
        $registry.AddMenuItem('Tasks', 'Task List', 'L', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen([TaskListScreen]::new())
        }, 5)

        # Today's tasks
        $registry.AddMenuItem('Tasks', 'Today', 'Y', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen([TaskListScreen]::new('today'))
        }, 10)

        # Tomorrow's tasks
        $registry.AddMenuItem('Tasks', 'Tomorrow', 'T', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen([TaskListScreen]::new('tomorrow'))
        }, 15)

        # This week
        $registry.AddMenuItem('Tasks', 'Week View', 'W', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen([TaskListScreen]::new('week'))
        }, 20)

        # Upcoming tasks
        $registry.AddMenuItem('Tasks', 'Upcoming', 'U', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen([TaskListScreen]::new('upcoming'))
        }, 25)

        # Overdue tasks
        $registry.AddMenuItem('Tasks', 'Overdue', 'V', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen([TaskListScreen]::new('overdue'))
        }, 30)

        # Next actions (no dependencies)
        $registry.AddMenuItem('Tasks', 'Next Actions', 'N', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen([TaskListScreen]::new('nextactions'))
        }, 35)

        # No due date
        $registry.AddMenuItem('Tasks', 'No Due Date', 'D', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen([TaskListScreen]::new('noduedate'))
        }, 40)

        # Month view
        $registry.AddMenuItem('Tasks', 'Month View', 'M', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen([TaskListScreen]::new('month'))
        }, 45)

        # Agenda view
        $registry.AddMenuItem('Tasks', 'Agenda View', 'A', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen([TaskListScreen]::new('agenda'))
        }, 50)
    }
}

# Export for use in other modules
if ($MyInvocation.MyCommand.Path) {
    Export-ModuleMember -Variable TaskListScreen
}
