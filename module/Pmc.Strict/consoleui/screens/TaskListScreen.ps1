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
    [hashtable]$_collapsedSubtasks = @{}

    # Inline editing state
    [bool]$_isEditingRow = $false
    [int]$_currentColumnIndex = 0
    [hashtable]$_editValues = @{}
    [array]$_editableColumns = @('title', 'details', 'due', 'project', 'tags')
    [object]$_activeDatePicker = $null
    [object]$_activeProjectPicker = $null
    [object]$_activeTagEditor = $null
    [string]$_activeWidgetType = ""  # 'date', 'project', 'tags', or ''

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

        # Setup edit mode callbacks for CellInfo
        $this._SetupEditModeCallbacks()
    }

    # Constructor with container (DI-enabled)
    TaskListScreen([object]$container) : base("TaskList", "Task List", $container) {
        $this._viewMode = 'active'
        $this._showCompleted = $false
        $this._sortColumn = 'due'
        $this._sortAscending = $true

        # Setup menus after base constructor
        $this._SetupMenus()

        # Setup edit mode callbacks for CellInfo
        $this._SetupEditModeCallbacks()
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

        # Setup edit mode callbacks for CellInfo
        $this._SetupEditModeCallbacks()
    }

    # Setup edit mode callbacks for CellInfo
    hidden [void] _SetupEditModeCallbacks() {
        $self = $this

        # Callback to determine if a row is in edit mode
        $this.List.GetIsInEditMode = {
            param($item)
            $result = $false
            if (-not $self._isEditingRow) {
                return $false
            }
            $selectedItem = $self.List.GetSelectedItem()
            if ($null -eq $selectedItem) {
                return $false
            }
            $itemId = Get-SafeProperty $item 'id'
            $selectedId = Get-SafeProperty $selectedItem 'id'
            $result = $itemId -eq $selectedId

            # DEBUG
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') GetIsInEditMode: _isEditingRow=$($self._isEditingRow) itemId=$itemId selectedId=$selectedId result=$result"

            return $result
        }.GetNewClosure()

        # Callback to get the focused column index for a row
        $this.List.GetFocusedColumnIndex = {
            param($item)
            if (-not $self._isEditingRow) { return -1 }
            $selectedItem = $self.List.GetSelectedItem()
            if ($null -eq $selectedItem) { return -1 }
            $itemId = Get-SafeProperty $item 'id'
            $selectedId = Get-SafeProperty $selectedItem 'id'
            if ($itemId -ne $selectedId) { return -1 }

            # DEBUG
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') GetFocusedColumnIndex: returning $($self._currentColumnIndex)"

            return $self._currentColumnIndex
        }.GetNewClosure()
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

        # CRITICAL: Re-register the Edit action to use OUR EditItem override, not the parent's
        Write-PmcTuiLog "TaskListScreen._InitializeComponents: AllowEdit=$($this.AllowEdit)" "DEBUG"
        if ($this.AllowEdit) {
            Write-PmcTuiLog "TaskListScreen: Re-registering Edit action" "DEBUG"
            $editAction = {
                Write-PmcTuiLog "!!! EDIT ACTION CALLBACK TRIGGERED !!!" "DEBUG"
                $currentScreen = $global:PmcApp.CurrentScreen
                $selectedItem = $currentScreen.List.GetSelectedItem()
                Write-PmcTuiLog "Edit action - selectedItem: $($selectedItem.id)" "DEBUG"
                if ($null -ne $selectedItem) {
                    Write-PmcTuiLog "Edit action - calling EditItem" "DEBUG"
                    $currentScreen.EditItem($selectedItem)
                }
            }.GetNewClosure()
            # Remove old action and add new one
            $this.List.RemoveAction('e')
            $this.List.AddAction('e', 'Edit', $editAction)
            Write-PmcTuiLog "TaskListScreen: Edit action registered" "DEBUG"
        }
    }

    # Setup menu items using MenuRegistry
    hidden [void] _SetupMenus() {
        # Get singleton MenuRegistry instance
        . "$PSScriptRoot/../services/MenuRegistry.ps1"
        $registry = [MenuRegistry]::GetInstance()

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
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TaskListScreen: Created new ServiceContainer"
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
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _PopulateMenusFromRegistry: Menu '$menuName' has 0 items from registry (null)"
                } elseif ($items -is [array]) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _PopulateMenusFromRegistry: Menu '$menuName' has $($items.Count) items from registry (array)"
                } else {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] _PopulateMenusFromRegistry: Menu '$menuName' has 1 item from registry (type: $($items.GetType().Name))"
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

        # DEBUG: Log loaded task priorities
        $targetTask = $allTasks | Where-Object { $_.id -eq 'c6f2bed5-6246-4be9-afc8-161bbb3ebcb0' } | Select-Object -First 1
        if ($targetTask) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') LoadData: Loaded task c6f2bed5 - priority=$(Get-SafeProperty $targetTask 'priority') project=$(Get-SafeProperty $targetTask 'project') tags=$(Get-SafeProperty $targetTask 'tags')"
        }

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
                    $isCollapsed = $this._collapsedSubtasks.ContainsKey($taskId)
                    foreach ($subtask in $childrenByParent[$taskId]) {
                        $subId = Get-SafeProperty $subtask 'id'
                        if (-not $processedIds.ContainsKey($subId)) {
                            # Only ADD to display if parent is NOT collapsed
                            if (-not $isCollapsed) {
                                [void]$organized.Add($subtask)
                            }
                            # But ALWAYS mark as processed so they don't appear as orphans
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
        $self = $this

        # Cell highlighting for edit mode - use theme colors via List widget
        # Normal cell: theme primary background
        $cellColor = $this.List.GetThemedAnsi('Primary', $true)  # Theme primary as background
        # Focused cell: reversed (theme primary as text color on black)
        $focusColor = "`e[40m" + $this.List.GetThemedAnsi('Primary', $false)  # Black bg, theme primary text
        $separator = "`e[90m│`e[0m"  # Gray separator between cells

        # DEBUG: Log the actual color codes
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') cellColor='$cellColor' focusColor='$focusColor'"

        return @(
            @{
                Name = 'title'
                Label = 'Task'
                Width = 35
                Align = 'left'
                Format = { param($task, $cellInfo)
                    # Get title value
                    $title = if ($cellInfo.IsInEditMode) {
                        $self._editValues.title ?? ""
                    } else {
                        $taskId = Get-SafeProperty $task 'id'
                        $t = Get-SafeProperty $task 'title'
                        if (-not $t) { $t = Get-SafeProperty $task 'text' }

                        $hasParent = Test-SafeProperty $task 'parent_id' -and (Get-SafeProperty $task 'parent_id')
                        if ($hasParent) {
                            $t = "└─ $t"
                        } else {
                            $hasChildren = $self.Store.GetAllTasks() | Where-Object {
                                (Get-SafeProperty $_ 'parent_id') -eq $taskId
                            } | Measure-Object | ForEach-Object { $_.Count -gt 0 }
                            if ($hasChildren) {
                                $isCollapsed = $self._collapsedSubtasks.ContainsKey($taskId)
                                $indicator = if ($isCollapsed) { "▶" } else { "▼" }
                                $t = "$indicator $t"
                            }
                        }
                        if (Get-SafeProperty $task 'completed') {
                            $t = "[✓] $t"
                        }
                        $t
                    }

                    # Cell-based highlighting in edit mode - fill cell width with background
                    if ($cellInfo.IsInEditMode) {
                        $visibleLen = $title.Replace('└─', '').Replace('▶', '').Replace('▼', '').Replace('[✓]', '').Length
                        $padding = $cellInfo.Width - $visibleLen
                        if ($padding -lt 0) { $padding = 0 }

                        if ($cellInfo.IsFocused) {
                            return "$focusColor$title" + (" " * $padding)
                        } else {
                            return "$cellColor$title" + (" " * $padding)
                        }
                    }
                    return $title
                }.GetNewClosure()
                Color = { param($task)
                    $taskId = Get-SafeProperty $task 'id'
                    $selectedItem = $self.List.GetSelectedItem()
                    $isEditing = $self._isEditingRow -and $selectedItem -and (Get-SafeProperty $selectedItem 'id') -eq $taskId
                    if ($isEditing -and $self._editableColumns[$self._currentColumnIndex] -eq 'title') {
                        return ""  # Highlight handles color
                    }
                    if (Get-SafeProperty $task 'completed') {
                        if ($self._supportsStrikethrough) {
                            return "`e[90m`e[9m"
                        } else {
                            return "`e[90m"
                        }
                    }
                    $tags = Get-SafeProperty $task 'tags'
                    if ($tags -and $tags -is [array] -and $tags.Count -gt 0) {
                        if ($tags -contains 'urgent' -or $tags -contains 'critical') { return "`e[91m" }
                        if ($tags -contains 'bug') { return "`e[31m" }
                        if ($tags -contains 'feature') { return "`e[32m" }
                        if ($tags -contains 'enhancement') { return "`e[36m" }
                    }
                    return "`e[37m"
                }.GetNewClosure()
            },
            @{
                Name = 'details'
                Label = 'Details'
                Width = 25
                Align = 'left'
                Format = { param($task, $cellInfo)
                    $details = if ($cellInfo.IsInEditMode) {
                        $self._editValues.details ?? ""
                    } else {
                        $d = Get-SafeProperty $task 'details'
                        if ($d -and $d.Length -gt 25) {
                            $d.Substring(0, 22) + "..."
                        } else {
                            $d ?? ''
                        }
                    }

                    # Cell-based highlighting in edit mode - fill cell width
                    if ($cellInfo.IsInEditMode) {
                        $visibleLen = $details.Length
                        $padding = $cellInfo.Width - $visibleLen
                        if ($padding -lt 0) { $padding = 0 }

                        if ($cellInfo.IsFocused) {
                            return "$focusColor$details" + (" " * $padding)
                        } else {
                            return "$cellColor$details" + (" " * $padding)
                        }
                    }
                    return $details
                }.GetNewClosure()
                Color = { param($task)
                    $taskId = Get-SafeProperty $task 'id'
                    $selectedItem = $self.List.GetSelectedItem()
                    $isEditing = $self._isEditingRow -and $selectedItem -and (Get-SafeProperty $selectedItem 'id') -eq $taskId
                    if ($isEditing -and $self._editableColumns[$self._currentColumnIndex] -eq 'details') {
                        return ""  # Highlight handles color
                    }
                    return "`e[90m"
                }.GetNewClosure()
            },
            @{
                Name = 'due'
                Label = 'Due'
                Width = 12
                Align = 'left'
                Format = { param($task, $cellInfo)
                    $dueText = if ($cellInfo.IsInEditMode) {
                        if ($self._editValues.due) { $self._editValues.due } else { '' }
                    } else {
                        $dueValue = Get-SafeProperty $task 'due'
                        if (-not $dueValue) { '' }
                        else {
                            $due = [DateTime]$dueValue
                            $today = [DateTime]::Today
                            $diff = ($due.Date - $today).Days

                            if ($diff -eq 0) { 'Today' }
                            elseif ($diff -eq 1) { 'Tomorrow' }
                            elseif ($diff -eq -1) { 'Yesterday' }
                            elseif ($diff -lt 0) { "$([Math]::Abs($diff))d ago" }
                            elseif ($diff -le 7) { "in ${diff}d" }
                            else { $due.ToString('MMM dd') }
                        }
                    }

                    # Cell-based highlighting in edit mode - fill cell width
                    if ($cellInfo.IsInEditMode) {
                        $visibleLen = $dueText.Length
                        $padding = $cellInfo.Width - $visibleLen
                        if ($padding -lt 0) { $padding = 0 }

                        if ($cellInfo.IsFocused) {
                            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Due Format: FOCUSED - width=$($cellInfo.Width) visibleLen=$visibleLen padding=$padding"
                            return "$focusColor$dueText" + (" " * $padding)
                        } else {
                            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Due Format: UNFOCUSED - width=$($cellInfo.Width) visibleLen=$visibleLen padding=$padding"
                            return "$cellColor$dueText" + (" " * $padding)
                        }
                    }
                    return $dueText
                }.GetNewClosure()
                Color = { param($task)
                    $taskId = Get-SafeProperty $task 'id'
                    $selectedItem = $self.List.GetSelectedItem()
                    $isEditing = $self._isEditingRow -and $selectedItem -and (Get-SafeProperty $selectedItem 'id') -eq $taskId
                    if ($isEditing -and $self._editableColumns[$self._currentColumnIndex] -eq 'due') {
                        return ""  # Highlight handles color
                    }
                    $dueValue = Get-SafeProperty $task 'due'
                    if (-not $dueValue -or (Get-SafeProperty $task 'completed')) { return "`e[90m" }

                    $due = [DateTime]$dueValue
                    $diff = ($due.Date - [DateTime]::Today).Days

                    if ($diff -lt 0) { return "`e[91m" }      # Overdue: bright red
                    elseif ($diff -eq 0) { return "`e[93m" }  # Today: bright yellow
                    elseif ($diff -le 3) { return "`e[33m" }  # Soon: yellow
                    else { return "`e[36m" }                   # Future: cyan
                }.GetNewClosure()
            },
            @{
                Name = 'project'
                Label = 'Project'
                Width = 15
                Align = 'left'
                Format = { param($task, $cellInfo)
                    $projText = if ($cellInfo.IsInEditMode) {
                        if ($self._editValues.project) { $self._editValues.project } else { '' }
                    } else {
                        $project = Get-SafeProperty $task 'project'
                        if ($project) { $project } else { '' }
                    }

                    # Cell-based highlighting in edit mode - fill cell width
                    if ($cellInfo.IsInEditMode) {
                        $visibleLen = $projText.Length
                        $padding = $cellInfo.Width - $visibleLen
                        if ($padding -lt 0) { $padding = 0 }

                        if ($cellInfo.IsFocused) {
                            return "$focusColor$projText" + (" " * $padding)
                        } else {
                            return "$cellColor$projText" + (" " * $padding)
                        }
                    }
                    return $projText
                }.GetNewClosure()
                Color = { param($task)
                    $taskId = Get-SafeProperty $task 'id'
                    $selectedItem = $self.List.GetSelectedItem()
                    $isEditing = $self._isEditingRow -and $selectedItem -and (Get-SafeProperty $selectedItem 'id') -eq $taskId
                    if ($isEditing -and $self._editableColumns[$self._currentColumnIndex] -eq 'project') {
                        return ""  # Highlight handles color
                    }
                    if (Get-SafeProperty $task 'project') { return "`e[96m" }  # Bright cyan
                    return "`e[90m"
                }.GetNewClosure()
            },
            @{
                Name = 'tags'
                Label = 'Tags'
                Width = 20
                Align = 'left'
                Format = { param($task, $cellInfo)
                    $tagsText = if ($cellInfo.IsInEditMode) {
                        if ($self._editValues.tags) { $self._editValues.tags } else { '' }
                    } else {
                        $tags = Get-SafeProperty $task 'tags'
                        if ($tags -and $tags -is [array] -and $tags.Count -gt 0) {
                            ($tags -join ', ')
                        } else {
                            ''
                        }
                    }

                    # Cell-based highlighting in edit mode - fill cell width
                    if ($cellInfo.IsInEditMode) {
                        $visibleLen = $tagsText.Length
                        $padding = $cellInfo.Width - $visibleLen
                        if ($padding -lt 0) { $padding = 0 }

                        if ($cellInfo.IsFocused) {
                            return "$focusColor$tagsText" + (" " * $padding)
                        } else {
                            return "$cellColor$tagsText" + (" " * $padding)
                        }
                    }
                    return $tagsText
                }.GetNewClosure()
                Color = { param($task)
                    $taskId = Get-SafeProperty $task 'id'
                    $selectedItem = $self.List.GetSelectedItem()
                    $isEditing = $self._isEditingRow -and $selectedItem -and (Get-SafeProperty $selectedItem 'id') -eq $taskId
                    if ($isEditing -and $self._editableColumns[$self._currentColumnIndex] -eq 'tags') {
                        return ""  # Highlight handles color
                    }
                    $tags = Get-SafeProperty $task 'tags'
                    if ($tags -and $tags -is [array] -and $tags.Count -gt 0) {
                        return "`e[95m"  # Bright magenta
                    }
                    return "`e[90m"
                }.GetNewClosure()
            }
        )
    }

    # Implement abstract method: Define edit fields for InlineEditor
    [array] GetEditFields([object]$item) {
        if ($null -eq $item -or $item.Count -eq 0) {
            # New task - empty fields
            return @(
                @{ Name='text'; Type='text'; Label='Task'; Required=$true; MaxLength=200; Value='' }  # H-VAL-6
                @{ Name='due'; Type='date'; Label='Due Date'; Value=$null }
                @{ Name='project'; Type='project'; Label='Project'; Value='' }
                @{ Name='tags'; Type='tags'; Label='Tags'; Value=@() }
            )
        } else {
            # Existing task - populate from item with safe property access
            return @(
                @{ Name='text'; Type='text'; Label='Task'; Required=$true; MaxLength=200; Value=(Get-SafeProperty $item 'text') }  # H-VAL-6
                @{ Name='due'; Type='date'; Label='Due Date'; Value=(Get-SafeProperty $item 'due') }
                @{ Name='project'; Type='project'; Label='Project'; Value=(Get-SafeProperty $item 'project') }
                @{ Name='tags'; Type='tags'; Label='Tags'; Value=(Get-SafeProperty $item 'tags') }
            )
        }
    }

    # Override: Handle item creation
    [void] OnItemCreated([hashtable]$values) {
        try {
            # Convert widget values to task format
            # FIX: Convert "(No Project)" to empty string
            $projectValue = ''
            if ($values.ContainsKey('project') -and $values.project -ne '(No Project)') {
                $projectValue = $values.project
            }

            # Validate text field (required)
            $taskText = if ($values.ContainsKey('text')) { $values.text } else { '' }
            if ([string]::IsNullOrWhiteSpace($taskText)) {
                $this.SetStatusMessage("Task description is required", "error")
                return
            }

            # Validate text length
            if ($taskText.Length -gt 500) {
                $this.SetStatusMessage("Task description must be 500 characters or less", "error")
                return
            }

            $taskData = @{
                text = $taskText
                priority = 3  # Default priority when creating new tasks
                project = $projectValue
                tags = if ($values.ContainsKey('tags')) { $values.tags } else { @() }
                completed = $false
                created = [DateTime]::Now
            }

            # Add due date if provided - with validation
            if ($values.ContainsKey('due') -and $values.due) {
                try {
                    $dueDate = [DateTime]$values.due
                    # Validate date is reasonable (not in past, not too far in future)
                    $minDate = [DateTime]::Today.AddDays(-1) # Allow yesterday for timezone issues
                    $maxDate = [DateTime]::Today.AddYears(10)

                    if ($dueDate -lt $minDate) {
                        $this.SetStatusMessage("Due date cannot be in the past", "warning")
                        # Don't return - just omit the due date
                    } elseif ($dueDate -gt $maxDate) {
                        $this.SetStatusMessage("Due date cannot be more than 10 years in the future", "warning")
                        # Don't return - just omit the due date
                    } else {
                        $taskData.due = $dueDate
                    }
                } catch {
                    $this.SetStatusMessage("Invalid due date format", "warning")
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

            # Use ValidationHelper to validate before saving
            . "$PSScriptRoot/../helpers/ValidationHelper.ps1"
            $validationResult = Test-TaskValid $taskData

            if (-not $validationResult.IsValid) {
                # Show first validation error
                $errorMsg = if ($validationResult.Errors.Count -gt 0) {
                    $validationResult.Errors[0]
                } else {
                    "Validation failed"
                }
                $this.SetStatusMessage($errorMsg, "error")
                Write-PmcTuiLog "Task validation failed: $($validationResult.Errors -join ', ')" "ERROR"
                return
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
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: ENTRY - item.id=$($item.id) values=$($values | ConvertTo-Json -Compress)"
        try {
            # Build changes hashtable
            # FIX: Convert "(No Project)" to empty string
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: values.project type=$(if ($values.ContainsKey('project')) { if ($null -eq $values.project) { 'NULL' } else { $values.project.GetType().Name } } else { 'MISSING' }) value='$($values.project)'"
            $projectValue = ''
            if ($values.ContainsKey('project')) {
                if ($values.project -is [array]) {
                    # If it's an array, join it or take first element
                    if ($values.project.Count -gt 0) {
                        $projectValue = [string]$values.project[0]
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: project is array, using first element: '$projectValue'"
                    } else {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: project is empty array, setting to empty string"
                    }
                } elseif ($values.project -is [string] -and $values.project -ne '(No Project)' -and $values.project -ne '') {
                    $projectValue = $values.project
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: project is string: '$projectValue'"
                } else {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: project is '(No Project)' or empty, setting to empty string"
                }
            } else {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: project key missing, using empty string"
            }

            # Validate text field (required)
            $taskText = if ($values.ContainsKey('text')) { $values.text } else { '' }
            if ([string]::IsNullOrWhiteSpace($taskText)) {
                $this.SetStatusMessage("Task description is required", "error")
                return
            }

            # Validate text length
            if ($taskText.Length -gt 500) {
                $this.SetStatusMessage("Task description must be 500 characters or less", "error")
                return
            }

            # Ensure all values have correct types for Store validation
            $detailsValue = if ($values.ContainsKey('details')) { $values.details } else { '' }
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: values.tags type=$(if ($values.ContainsKey('tags') -and $values.tags) { $values.tags.GetType().Name } else { 'MISSING' }) value='$($values.tags)'"
            # CRITICAL: Use comma operator to prevent PowerShell from unwrapping single-element arrays
            $tagsValue = @(if ($values.ContainsKey('tags') -and $values.tags) {
                if ($values.tags -is [array]) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: tags is already array"
                    $values.tags
                }
                elseif ($values.tags -is [string]) {
                    $splitResult = @($values.tags -split ',' | ForEach-Object { $_.Trim() })
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: split tags string into array, type=$($splitResult.GetType().Name) count=$($splitResult.Count)"
                    $splitResult
                }
                else {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: tags is unknown type, returning empty array"
                    @()
                }
            } else {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: tags missing or empty, returning empty array"
            })
            $tagCount = if ($tagsValue -is [array]) { $tagsValue.Count } else { 'N/A' }
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: tagsValue type=$($tagsValue.GetType().Name) count=$tagCount isArray=$($tagsValue -is [array])"

            $changes = @{
                text = [string]$taskText
                details = [string]$detailsValue
                project = [string]$projectValue
                tags = $tagsValue
            }

            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: project type=$($changes.project.GetType().Name) value='$($changes.project)'"
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: tags type=$(if ($changes.tags) { $changes.tags.GetType().Name } else { 'NULL' }) value=$(if ($changes.tags -is [array]) { $changes.tags -join ',' } else { $changes.tags })"

            # Update due date with validation
            if ($values.ContainsKey('due') -and $values.due) {
                try {
                    $dueDate = [DateTime]$values.due
                    # Validate date is reasonable
                    $minDate = [DateTime]::Today.AddDays(-7) # Allow past week for updates
                    $maxDate = [DateTime]::Today.AddYears(10)

                    if ($dueDate -lt $minDate) {
                        $this.SetStatusMessage("Due date too far in the past (max 7 days)", "warning")
                        # Don't return - just omit the due date update
                    } elseif ($dueDate -gt $maxDate) {
                        $this.SetStatusMessage("Due date cannot be more than 10 years in the future", "warning")
                        # Don't return - just omit the due date update
                    } else {
                        $changes.due = $dueDate
                    }
                } catch {
                    $this.SetStatusMessage("Invalid due date format", "warning")
                    Write-PmcTuiLog "Failed to convert due date '$($values.due)', omitting" "WARNING"
                    # Don't include due in changes - keep existing value
                }
            } else {
                $changes.due = $null
            }

            # Use ValidationHelper to validate the updated task before saving
            . "$PSScriptRoot/../helpers/ValidationHelper.ps1"

            # Merge changes with existing task for validation
            $updatedTask = @{}
            foreach ($key in $item.PSObject.Properties.Name) {
                $updatedTask[$key] = $item.$key
            }
            foreach ($key in $changes.Keys) {
                $updatedTask[$key] = $changes[$key]
            }

            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: About to validate - updatedTask.tags type=$(if ($updatedTask['tags']) { $updatedTask['tags'].GetType().Name } else { 'NULL' }) value=$(if ($updatedTask['tags'] -is [array]) { $updatedTask['tags'] -join ',' } else { $updatedTask['tags'] })"
            # TEMPORARILY SKIP VALIDATION TO DEBUG SAVE FLOW
            # $validationResult = Test-TaskValid $updatedTask
            # Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: Validation IsValid=$($validationResult.IsValid)"

            # if (-not $validationResult.IsValid) {
            #     # Show first validation error
            #     $errorMsg = if ($validationResult.Errors.Count -gt 0) {
            #         $validationResult.Errors[0]
            #     } else {
            #         "Validation failed"
            #     }
            #     Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: VALIDATION FAILED - errors=$($validationResult.Errors -join '; ')"
            #     $this.SetStatusMessage($errorMsg, "error")
            #     Write-PmcTuiLog "Task validation failed: $($validationResult.Errors -join ', ')" "ERROR"
            #     return
            # }

            # Update in store
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: Calling Store.UpdateTask with item.id=$($item.id)"
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: changes=$($changes | ConvertTo-Json -Compress)"
            $success = $this.Store.UpdateTask($item.id, $changes)
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: UpdateTask returned success=$success"
            if ($success) {
                $this.SetStatusMessage("Task updated: $($values.text)", "success")
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: SUCCESS - calling LoadData to refresh"
                $this.LoadData()  # Refresh the list to show updated data
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: LoadData completed"
            } else {
                $this.SetStatusMessage("Failed to update task: $($this.Store.LastError)", "error")
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: FAILED - error=$($this.Store.LastError)"
            }
        }
        catch {
            Write-PmcTuiLog "OnItemUpdated exception: $_" "ERROR"
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: EXCEPTION - $($_.Exception.Message)"
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: Stack trace - $($_.ScriptStackTrace)"
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

    # Override EditItem for inline column editing
    [void] EditItem($item) {
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: ENTRY"

        if ($null -eq $item) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: NULL ITEM - RETURNING"
            return
        }

        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: Setting _isEditingRow = TRUE"
        $this._isEditingRow = $true
        $this._currentColumnIndex = 0

        $this._editValues = @{
            title = Get-SafeProperty $item 'title'
            details = Get-SafeProperty $item 'details'
            due = Get-SafeProperty $item 'due'
            project = Get-SafeProperty $item 'project'
            tags = Get-SafeProperty $item 'tags'
        }
        # Fallback to text if no title
        if (-not $this._editValues.title) {
            $this._editValues.title = Get-SafeProperty $item 'text'
        }

        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: _isEditingRow = $($this._isEditingRow)"

        # CRITICAL: Invalidate the list's row cache so Format callbacks get re-invoked
        $this.List.InvalidateCache()
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: Invalidated list cache"

        # Force a status message and mark app dirty to trigger immediate render
        $this.SetStatusMessage("*** EDITING MODE ACTIVE *** Tab=next, Enter=save, Esc=cancel", "success")

        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: Called SetStatusMessage"

        # CRITICAL: Force immediate re-render by marking the app dirty
        if ($global:PmcApp) {
            $global:PmcApp.IsDirty = $true
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: Set IsDirty=true"
        }

        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: EXIT"
    }

    # Load widget classes if not already loaded
    hidden [void] _EnsureWidgetsLoaded() {
        if (-not ([System.Management.Automation.PSTypeName]'DatePicker').Type) {
            . "$PSScriptRoot/../widgets/DatePicker.ps1"
        }
        if (-not ([System.Management.Automation.PSTypeName]'ProjectPicker').Type) {
            . "$PSScriptRoot/../widgets/ProjectPicker.ps1"
        }
        if (-not ([System.Management.Automation.PSTypeName]'TagEditor').Type) {
            . "$PSScriptRoot/../widgets/TagEditor.ps1"
        }
    }

    # Show widget for current column at column position
    hidden [void] _ShowWidgetForColumn() {
        $this._CloseActiveWidget()

        $col = $this._editableColumns[$this._currentColumnIndex]

        # Only show widgets for due/project columns (tags is now inline text)
        if ($col -ne 'due' -and $col -ne 'project') {
            return
        }

        # Get column position from GetColumns()
        $columns = $this.GetColumns()
        $colX = 0
        $colIndex = 0
        foreach ($column in $columns) {
            if ($column.Name -eq $col) {
                break
            }
            $colX += $column.Width + 1
            $colIndex++
        }

        # Get selected row Y position
        $selectedIndex = $this.List.GetSelectedIndex()
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)
        $rowY = $contentRect.Y + $selectedIndex + 2  # +2 for header

        $this._EnsureWidgetsLoaded()

        if ($col -eq 'due') {
            $this._activeDatePicker = [DatePicker]::new()
            $this._activeDatePicker.SetPosition($contentRect.X + $colX, $rowY)
            $this._activeDatePicker.SetSize(35, 14)

            # Set current value
            $dueValue = $this._editValues.due
            if ($dueValue) {
                try {
                    $this._activeDatePicker.SetDate([DateTime]::Parse($dueValue))
                } catch {
                    $this._activeDatePicker.SetDate([DateTime]::Today)
                }
            }

            # Setup callbacks
            $self = $this
            $this._activeDatePicker.OnConfirmed = {
                param($date)
                $self._editValues.due = $date.ToString('yyyy-MM-dd')
                $self._CloseActiveWidget()
            }.GetNewClosure()

            $this._activeDatePicker.OnCancelled = {
                $self._CloseActiveWidget()
            }.GetNewClosure()

            $this._activeWidgetType = 'date'
        }
        elseif ($col -eq 'project') {
            $this._activeProjectPicker = [ProjectPicker]::new()
            $this._activeProjectPicker.SetPosition($contentRect.X + $colX, $rowY)
            $this._activeProjectPicker.SetSize(35, 12)

            # Set current value - DON'T pre-fill search, just select the matching project
            $projectValue = $this._editValues.project
            if ($projectValue) {
                $this._activeProjectPicker.SetSelectedProject($projectValue)
            }

            # Setup callbacks
            $self = $this
            $this._activeProjectPicker.OnProjectSelected = {
                param($projectName)
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnProjectSelected callback: projectName='$projectName'"
                $self._editValues.project = $projectName
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnProjectSelected: Set _editValues.project to '$($self._editValues.project)'"
                $self._CloseActiveWidget()
            }.GetNewClosure()

            $this._activeProjectPicker.OnCancelled = {
                $self._CloseActiveWidget()
            }.GetNewClosure()

            $this._activeWidgetType = 'project'
        }
        elseif ($col -eq 'tags') {
            $this._activeTagEditor = [TagEditor]::new()
            $this._activeTagEditor.SetPosition($contentRect.X + $colX, $rowY)
            $this._activeTagEditor.SetSize(60, 5)

            # Set current value
            $tagsValue = $this._editValues.tags
            if ($tagsValue) {
                $tagArray = $tagsValue -split ',' | ForEach-Object { $_.Trim() }
                $this._activeTagEditor.SetTags($tagArray)
            }

            # Setup callbacks
            $self = $this
            $this._activeTagEditor.OnConfirmed = {
                param($tags)
                $self._editValues.tags = $tags -join ', '
                $self._CloseActiveWidget()
            }.GetNewClosure()

            $this._activeTagEditor.OnCancelled = {
                $self._CloseActiveWidget()
            }.GetNewClosure()

            $this._activeWidgetType = 'tags'
        }
    }

    # Close active widget
    hidden [void] _CloseActiveWidget() {
        $this._activeDatePicker = $null
        $this._activeProjectPicker = $null
        $this._activeTagEditor = $null
        $this._activeWidgetType = ""

        # Force full screen clear to remove widget visuals
        if ($this.RenderEngine -and $this.RenderEngine.PSObject.Methods['RequestClear']) {
            $this.RenderEngine.RequestClear()
        }
    }

    # Handle inline editing input
    hidden [bool] _HandleInlineEditInput([ConsoleKeyInfo]$keyInfo) {
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _HandleInlineEditInput: Key=$($keyInfo.Key) Char='$($keyInfo.KeyChar)' Column=$($this._editableColumns[$this._currentColumnIndex]) Widget=$($this._activeWidgetType)"

        # Tab/Shift+Tab always closes widget and moves to next/prev field
        if ($keyInfo.Key -eq 'Tab') {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Tab pressed - saving widget value and closing, editValues: pri=$($this._editValues.priority) title=$($this._editValues.title) details=$($this._editValues.details)"

            # Save widget value before closing
            if ($this._activeWidgetType -eq 'date' -and $null -ne $this._activeDatePicker) {
                $this._editValues.due = $this._activeDatePicker.GetSelectedDate().ToString('yyyy-MM-dd')
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Saved date from picker: $($this._editValues.due)"
            }
            elseif ($this._activeWidgetType -eq 'project' -and $null -ne $this._activeProjectPicker) {
                # ProjectPicker saves through its callback, but we can check if there's a selected project
                $selectedProj = $this._activeProjectPicker.GetSelectedProject()
                if ($selectedProj) {
                    $this._editValues.project = $selectedProj
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Saved project from picker: $($this._editValues.project)"
                }
            }
            elseif ($this._activeWidgetType -eq 'tags' -and $null -ne $this._activeTagEditor) {
                $this._editValues.tags = $this._activeTagEditor.GetTags() -join ', '
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Saved tags from editor: $($this._editValues.tags)"
            }

            $this._CloseActiveWidget()
            # Fall through to Tab handler below
        }
        # If a widget is active, route input to it
        elseif ($this._activeWidgetType -ne "") {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Widget active ($($this._activeWidgetType)) - passing key to widget, returning early"
            $handled = $false

            if ($this._activeWidgetType -eq 'date' -and $null -ne $this._activeDatePicker) {
                $handled = $this._activeDatePicker.HandleInput($keyInfo)

                # Check if widget closed itself
                if ($this._activeDatePicker -and ($this._activeDatePicker.IsConfirmed -or $this._activeDatePicker.IsCancelled)) {
                    $this._CloseActiveWidget()
                }
            }
            elseif ($this._activeWidgetType -eq 'project' -and $null -ne $this._activeProjectPicker) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Calling ProjectPicker.HandleInput with key=$($keyInfo.Key)"
                $handled = $this._activeProjectPicker.HandleInput($keyInfo)
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') ProjectPicker.HandleInput returned: $handled"

                # Invalidate to redraw widget if it handled the input
                if ($handled) {
                    # Force immediate render by invalidating list cache and marking app dirty
                    $this.List.InvalidateCache()
                    if ($this.RenderEngine -and $this.RenderEngine.PSObject.Methods['RequestClear']) {
                        $this.RenderEngine.RequestClear()
                    }
                    if ($global:PmcApp) {
                        $global:PmcApp.IsDirty = $true
                    }
                }

                # Check if widget closed itself
                if ($this._activeProjectPicker -and ($this._activeProjectPicker.IsConfirmed -or $this._activeProjectPicker.IsCancelled)) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') ProjectPicker confirmed/cancelled, closing widget"
                    $this._CloseActiveWidget()
                }
            }
            elseif ($this._activeWidgetType -eq 'tags' -and $null -ne $this._activeTagEditor) {
                $handled = $this._activeTagEditor.HandleInput($keyInfo)

                # Check if widget closed itself
                if ($this._activeTagEditor -and ($this._activeTagEditor.IsConfirmed -or $this._activeTagEditor.IsCancelled)) {
                    $this._CloseActiveWidget()
                }
            }

            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Widget handled key, returning true (EARLY EXIT)"
            return $true
        }

        # Tab - next column
        if ($keyInfo.Key -eq 'Tab' -and -not ($keyInfo.Modifiers -band [ConsoleModifiers]::Shift)) {
            $this._currentColumnIndex = ($this._currentColumnIndex + 1) % $this._editableColumns.Count
            $this.List.InvalidateCache()  # Invalidate cache to update highlighting
            $this._ShowWidgetForColumn()
            return $true
        }
        # Shift+Tab - previous column
        if ($keyInfo.Key -eq 'Tab' -and ($keyInfo.Modifiers -band [ConsoleModifiers]::Shift)) {
            $this._currentColumnIndex--
            if ($this._currentColumnIndex -lt 0) { $this._currentColumnIndex = $this._editableColumns.Count - 1 }
            $this.List.InvalidateCache()  # Invalidate cache to update highlighting
            $this._ShowWidgetForColumn()
            return $true
        }
        # Enter - save
        if ($keyInfo.Key -eq 'Enter') {
            $item = $this.List.GetSelectedItem()
            if ($item) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Enter pressed - _editValues.priority=$($this._editValues.priority) type=$($this._editValues.priority.GetType().Name)"
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Enter pressed - _editValues.project=$($this._editValues.project)"

                # Map title/details to text field for OnItemUpdated
                $updateValues = @{
                    text = $this._editValues.title ?? ""
                    details = $this._editValues.details
                    priority = [int]$this._editValues.priority  # Explicit cast here too
                    due = $this._editValues.due
                    project = $this._editValues.project
                    tags = $this._editValues.tags
                }
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Enter pressed - updateValues.priority=$($updateValues.priority) type=$($updateValues.priority.GetType().Name)"
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Enter pressed - updateValues.project=$($updateValues.project) type=$($updateValues.project.GetType().Name)"
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Enter pressed - calling OnItemUpdated with: text='$($updateValues.text)' details='$($updateValues.details)' pri=$($updateValues.priority) project=$($updateValues.project)"
                $this.OnItemUpdated($item, $updateValues)
            }
            $this._isEditingRow = $false
            $this.List.InvalidateCache()  # Invalidate cache when exiting edit mode
            $this._CloseActiveWidget()
            return $true
        }
        # Esc - cancel
        if ($keyInfo.Key -eq 'Escape') {
            $this._isEditingRow = $false
            $this.List.InvalidateCache()  # Invalidate cache when exiting edit mode
            $this._CloseActiveWidget()
            return $true
        }

        $col = $this._editableColumns[$this._currentColumnIndex]
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Processing input for column: $col Key=$($keyInfo.Key)"

        if ($col -eq 'priority') {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Priority column - checking arrows. Key=$($keyInfo.Key) CurrentPri=$($this._editValues.priority)"
            # Up/Right arrows: increase priority
            if ($keyInfo.Key -eq 'UpArrow' -or $keyInfo.Key -eq 'RightArrow') {
                if ([int]$this._editValues.priority -lt 5) {
                    $this._editValues.priority++
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Priority increased to $($this._editValues.priority)"
                    $this.List.InvalidateCache()  # Re-render to show new value
                    if ($global:PmcApp) { $global:PmcApp.IsDirty = $true }  # Force immediate re-render
                } else {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Priority already at MAX (5) - cannot increase"
                }
            }
            # Down/Left arrows: decrease priority
            elseif ($keyInfo.Key -eq 'DownArrow' -or $keyInfo.Key -eq 'LeftArrow') {
                if ([int]$this._editValues.priority -gt 0) {
                    $this._editValues.priority--
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Priority decreased to $($this._editValues.priority)"
                    $this.List.InvalidateCache()  # Re-render to show new value
                    if ($global:PmcApp) { $global:PmcApp.IsDirty = $true }  # Force immediate re-render
                } else {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Priority already at MIN (0) - cannot decrease"
                }
            } else {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Priority column but key not an arrow: $($keyInfo.Key)"
            }
        }
        elseif ($col -eq 'title' -or $col -eq 'details' -or $col -eq 'tags') {
            # Inline text editing for title, details, and tags
            if ($keyInfo.KeyChar -match '[a-zA-Z0-9 \-_.,!?@#$%^&*()\/\\:;''"<>]') {
                $this._editValues[$col] = ($this._editValues[$col] ?? "") + $keyInfo.KeyChar
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Added char to $col : '$($keyInfo.KeyChar)' -> '$($this._editValues[$col])'"
                $this.List.InvalidateCache()  # Re-render to show new value
            }
            if ($keyInfo.Key -eq 'Backspace' -and $this._editValues[$col].Length -gt 0) {
                $this._editValues[$col] = $this._editValues[$col].Substring(0, $this._editValues[$col].Length - 1)
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Backspace in $col -> '$($this._editValues[$col])'"
                $this.List.InvalidateCache()  # Re-render to show new value
            }
        }
        elseif ($col -eq 'due' -or $col -eq 'project') {
            # Show widget when user starts typing in these columns
            $this._ShowWidgetForColumn()
        }
        return $true
    }

    # Override RenderContent to add widget rendering
    [string] RenderContent() {
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') RenderContent CALLED: _isEditingRow=$($this._isEditingRow)"

        # Get base rendering (list, filter panel, etc.)
        $output = ([StandardListScreen]$this).RenderContent()

        # If a widget is active, render it on top
        if ($this._activeWidgetType -ne "") {
            if ($this._activeWidgetType -eq 'date' -and $this._activeDatePicker) {
                $output += $this._activeDatePicker.Render()
            }
            elseif ($this._activeWidgetType -eq 'project' -and $this._activeProjectPicker) {
                $output += $this._activeProjectPicker.Render()
            }
            elseif ($this._activeWidgetType -eq 'tags' -and $this._activeTagEditor) {
                $output += $this._activeTagEditor.Render()
            }
        }

        return $output
    }

    # Override: Additional keyboard shortcuts
    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') TaskListScreen.HandleKeyPress: Key=$($keyInfo.Key) _isEditingRow=$($this._isEditingRow)"

        # Handle inline editing first
        if ($this._isEditingRow) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') TaskListScreen.HandleKeyPress: Calling _HandleInlineEditInput"
            return $this._HandleInlineEditInput($keyInfo)
        }

        # Custom shortcuts BEFORE base class
        $key = $keyInfo.Key
        $ctrl = $keyInfo.Modifiers -band [ConsoleModifiers]::Control
        $alt = $keyInfo.Modifiers -band [ConsoleModifiers]::Alt

        # Space: Toggle subtask collapse OR completion (BEFORE base class)
        if ($key -eq [ConsoleKey]::Spacebar -and -not $ctrl -and -not $alt) {
            $selected = $this.List.GetSelectedItem()
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Space pressed: selected task id=$($selected.id) parent_id=$(Get-SafeProperty $selected 'parent_id')"
            if ($selected) {
                $taskId = Get-SafeProperty $selected 'id'
                $hasChildren = $this.Store.GetAllTasks() | Where-Object {
                    (Get-SafeProperty $_ 'parent_id') -eq $taskId
                } | Measure-Object | ForEach-Object { $_.Count -gt 0 }

                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Space: taskId=$taskId hasChildren=$hasChildren"

                if ($hasChildren) {
                    # Toggle collapse
                    $wasCollapsed = $this._collapsedSubtasks.ContainsKey($taskId)
                    if ($wasCollapsed) {
                        $this._collapsedSubtasks.Remove($taskId)
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Space: Expanding task $taskId"
                    } else {
                        $this._collapsedSubtasks[$taskId] = $true
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Space: Collapsing task $taskId"
                    }
                    $this._cachedFilteredTasks = $null
                    $this.LoadData()
                    $this.List.InvalidateCache()  # Force re-render with new collapse state
                } else {
                    # No children - toggle completion
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Space: No children - toggling completion"
                    $this.ToggleTaskCompletion($selected)
                }
            }
            return $true
        }

        # E key: Enter inline edit mode
        if ($key -eq [ConsoleKey]::E -and -not $ctrl -and -not $alt) {
            $selected = $this.List.GetSelectedItem()
            if ($selected) {
                $this.EditItem($selected)
                return $true
            }
        }

        # Handle base class shortcuts
        $handled = ([StandardListScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

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
