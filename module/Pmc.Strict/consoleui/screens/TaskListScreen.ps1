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

    # Debug logging flag - set to $false to disable debug file writes
    hidden [bool]$_enableDebugLogging = $false

    # LOW FIX TLS-L4: Centralized initialization to reduce constructor duplication
    hidden [void] _InitializeTaskListScreen([string]$viewMode, [bool]$setupCallbacks) {
        $this._viewMode = $viewMode
        $this._showCompleted = $false
        $this._sortColumn = 'due'
        $this._sortAscending = $true
        $this._SetupMenus()
        if ($setupCallbacks) {
            $this._SetupEditModeCallbacks()
        }
    }

    # Constructor with optional view mode
    TaskListScreen() : base("TaskList", "Task List") {
        $this._InitializeTaskListScreen('active', $true)
    }

    # Constructor with container (DI-enabled)
    TaskListScreen([object]$container) : base("TaskList", "Task List", $container) {
        $this._InitializeTaskListScreen('active', $true)
    }

    # Constructor with explicit view mode
    TaskListScreen([string]$viewMode) : base("TaskList", (Get-TaskListTitle $viewMode)) {
        $this._InitializeTaskListScreen($viewMode, $false)
    }

    # Constructor with container and view mode (DI-enabled)
    TaskListScreen([object]$container, [string]$viewMode) : base("TaskList", (Get-TaskListTitle $viewMode), $container) {
        $this._InitializeTaskListScreen($viewMode, $true)
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
            if ($self._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') GetIsInEditMode: _isEditingRow=$($self._isEditingRow) itemId=$itemId selectedId=$selectedId result=$result"
            }

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
            if ($self._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') GetFocusedColumnIndex: returning $($self._currentColumnIndex)"
            }

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
                # HIGH FIX TLS-H1: Add null check on $global:PmcApp
                Write-PmcTuiLog "!!! EDIT ACTION CALLBACK TRIGGERED !!!" "DEBUG"
                if ($null -eq $global:PmcApp) {
                    Write-PmcTuiLog "Edit action failed: PmcApp is null" "ERROR"
                    return
                }
                $currentScreen = $global:PmcApp.CurrentScreen
                if ($null -eq $currentScreen -or $null -eq $currentScreen.List) {
                    Write-PmcTuiLog "Edit action failed: CurrentScreen or List is null" "ERROR"
                    return
                }
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
                    # MEDIUM FIX TLS-M7: Validate $item is a hashtable before indexing
                    if ($item -isnot [hashtable]) {
                        Write-PmcTuiLog "_PopulateMenusFromRegistry: Item is not a hashtable, type: $($item.GetType().Name)" "WARNING"
                        continue
                    }
                    # MenuRegistry returns hashtables, use hashtable indexing
                    $menuItem = [PmcMenuItem]::new($item['Label'], $item['Hotkey'], $item['Action'])
                    $menu.Items.Add($menuItem)
                }
            }
        }
    }

    # Implement abstract method: Load data from TaskStore
    [void] LoadData() {
        # CRITICAL FIX TLS-C1: Invalidate cache BEFORE building key to prevent race condition
        # where TaskStore events invalidate cache after key check but before data load
        $this._cachedFilteredTasks = $null
        $this._cacheKey = ""

        # Build cache key from current filter/sort settings
        $currentKey = "$($this._viewMode):$($this._sortColumn):$($this._sortAscending):$($this._showCompleted)"

        $allTasks = $this.Store.GetAllTasks()

        # DEBUG: Log loaded task priorities
        if ($this._enableDebugLogging) {
            $targetTask = $allTasks | Where-Object { $_.id -eq 'c6f2bed5-6246-4be9-afc8-161bbb3ebcb0' } | Select-Object -First 1
            if ($targetTask) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') LoadData: Loaded task c6f2bed5 - priority=$(Get-SafeProperty $targetTask 'priority') project=$(Get-SafeProperty $targetTask 'project') tags=$(Get-SafeProperty $targetTask 'tags')"
            }
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
        # HIGH FIX TLS-H2: Add null check on $this.List
        if ($null -eq $this.List) {
            Write-PmcTuiLog "GetColumns called with null List widget" "ERROR"
            return @()
        }
        # Normal cell: theme primary background
        $cellColor = $this.List.GetThemedAnsi('Primary', $true)  # Theme primary as background
        # Focused cell: reversed (theme primary as text color on black)
        $focusColor = "`e[40m" + $this.List.GetThemedAnsi('Primary', $false)  # Black bg, theme primary text
        $separator = "`e[90m│`e[0m"  # Gray separator between cells

        # DEBUG: Log the actual color codes
        if ($this._enableDebugLogging) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') cellColor='$cellColor' focusColor='$focusColor'"
        }

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
                            # HIGH FIX TLS-H4: Add null check on GetAllTasks()
                            $allTasks = $self.Store.GetAllTasks()
                            if ($null -eq $allTasks) { $allTasks = @() }
                            $hasChildren = $allTasks | Where-Object {
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
                            # CRITICAL FIX TLS-C4: Safe DateTime parsing
                            try {
                                $due = [DateTime]$dueValue
                                $today = [DateTime]::Today
                                $diff = ($due.Date - $today).Days

                                if ($diff -eq 0) { 'Today' }
                                elseif ($diff -eq 1) { 'Tomorrow' }
                                elseif ($diff -eq -1) { 'Yesterday' }
                                elseif ($diff -lt 0) { "$([Math]::Abs($diff))d ago" }
                                elseif ($diff -le 7) { "in ${diff}d" }
                                else { $due.ToString('MMM dd') }
                            } catch {
                                # Invalid date format - return raw value
                                Write-PmcTuiLog "Invalid due date format: $dueValue" "WARNING"
                                $dueValue
                            }
                        }
                    }

                    # Cell-based highlighting in edit mode - fill cell width
                    if ($cellInfo.IsInEditMode) {
                        $visibleLen = $dueText.Length
                        $padding = $cellInfo.Width - $visibleLen
                        if ($padding -lt 0) { $padding = 0 }

                        if ($cellInfo.IsFocused) {
                            if ($self._enableDebugLogging) {
                                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Due Format: FOCUSED - width=$($cellInfo.Width) visibleLen=$visibleLen padding=$padding"
                            }
                            return "$focusColor$dueText" + (" " * $padding)
                        } else {
                            if ($self._enableDebugLogging) {
                                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Due Format: UNFOCUSED - width=$($cellInfo.Width) visibleLen=$visibleLen padding=$padding"
                            }
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

                    # CRITICAL FIX TLS-C4: Safe DateTime parsing
                    try {
                        $due = [DateTime]$dueValue
                        $diff = ($due.Date - [DateTime]::Today).Days
                    } catch {
                        # Invalid date - return default color
                        return "`e[90m"
                    }

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
        # LOW FIX TLS-L4 & EDGE-1: Add type check before accessing .Count
        if ($null -eq $item -or ($item -is [hashtable] -and $item.Count -eq 0) -or ($item -is [array] -and $item.Count -eq 0)) {
            # New task - empty fields
            return @(
                @{ Name='text'; Type='text'; Label='Task'; Required=$true; MaxLength=200; Value='' }  # H-VAL-6
                @{ Name='due'; Type='date'; Label='Due Date'; Value=$null }
                @{ Name='project'; Type='project'; Label='Project'; Value='' }
                @{ Name='tags'; Type='tags'; Label='Tags'; Value=@() }
            )
        } else {
            # TLS-M3 FIX: Validate item is a valid object type before accessing properties
            if ($item -isnot [hashtable] -and $item.GetType().Name -ne 'PSCustomObject') {
                Write-PmcTuiLog "GetEditFields: Invalid item type '$($item.GetType().Name)', returning empty fields" "WARNING"
                return @(
                    @{ Name='text'; Type='text'; Label='Task'; Required=$true; MaxLength=200; Value='' }
                    @{ Name='due'; Type='date'; Label='Due Date'; Value=$null }
                    @{ Name='project'; Type='project'; Label='Project'; Value='' }
                    @{ Name='tags'; Type='tags'; Label='Tags'; Value=@() }
                )
            }

            # Existing task - populate from item with safe property access
            # TLS-M3 FIX: Validate field values before using them
            $textValue = Get-SafeProperty $item 'text'
            if ([string]::IsNullOrWhiteSpace($textValue)) {
                $textValue = ''
            }

            $dueValue = Get-SafeProperty $item 'due'
            $projectValue = Get-SafeProperty $item 'project'
            if ($null -eq $projectValue) {
                $projectValue = ''
            }

            $tagsValue = Get-SafeProperty $item 'tags'
            # Ensure tags is an array
            if ($null -eq $tagsValue -or $tagsValue -isnot [array]) {
                $tagsValue = @()
            }

            return @(
                @{ Name='text'; Type='text'; Label='Task'; Required=$true; MaxLength=200; Value=$textValue }  # H-VAL-6
                @{ Name='due'; Type='date'; Label='Due Date'; Value=$dueValue }
                @{ Name='project'; Type='project'; Label='Project'; Value=$projectValue }
                @{ Name='tags'; Type='tags'; Label='Tags'; Value=$tagsValue }
            )
        }
    }

    # Override: Handle item creation
    [void] OnItemCreated([hashtable]$values) {
        # MEDIUM FIX TLS-M3: Add null check on $values parameter
        if ($null -eq $values) {
            Write-PmcTuiLog "OnItemCreated called with null values" "ERROR"
            $this.SetStatusMessage("Cannot create task: no data provided", "error")
            return
        }
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
            # MEDIUM FIX TLS-M1 & TLS-M2: Correct error message to match actual limit (200, not 500)
            if ($taskText.Length -gt 200) {
                $this.SetStatusMessage("Task description must be 200 characters or less", "error")
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
                    # HIGH FIX TLS-H6: Circular dependency check is ineffective here
                    # Since we're creating a NEW task (no ID yet), it cannot create a cycle
                    # Circular dependency should be checked in OnItemUpdated when changing parent_id
                    # For new tasks being created as subtasks, simply set the parent_id
                    $taskData.parent_id = $parentId
                }
            }

            # Use ValidationHelper to validate before saving
            try {
                . "$PSScriptRoot/../helpers/ValidationHelper.ps1"
            } catch {
                Write-PmcTuiLog "Failed to load ValidationHelper: $_" "ERROR"
                $this.SetStatusMessage("Validation system error, task not created", "error")
                return
            }

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
            # LOW FIX TLS-L1: Add context to exception messages
            $taskText = if ($values.ContainsKey('text')) { $values.text } else { "(no title)" }
            Write-PmcTuiLog "OnItemCreated exception while creating task '$taskText': $_" "ERROR"
            $this.SetStatusMessage("Error creating task '$taskText': $($_.Exception.Message)", "error")
        }
    }

    # Override: Handle item update
    [void] OnItemUpdated([object]$item, [hashtable]$values) {
        # MEDIUM FIX TLS-M4: Add null checks on parameters
        if ($null -eq $item) {
            Write-PmcTuiLog "OnItemUpdated called with null item" "ERROR"
            $this.SetStatusMessage("Cannot update task: no item selected", "error")
            return
        }
        if ($null -eq $values) {
            Write-PmcTuiLog "OnItemUpdated called with null values" "ERROR"
            $this.SetStatusMessage("Cannot update task: no data provided", "error")
            return
        }
        if ($this._enableDebugLogging) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: ENTRY - item.id=$($item.id) values=$($values | ConvertTo-Json -Compress)"
        }
        try {
            # Build changes hashtable
            # FIX: Convert "(No Project)" to empty string
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: values.project type=$(if ($values.ContainsKey('project')) { if ($null -eq $values.project) { 'NULL' } else { $values.project.GetType().Name } } else { 'MISSING' }) value='$($values.project)'"
            }
            $projectValue = ''
            if ($values.ContainsKey('project')) {
                if ($values.project -is [array]) {
                    # If it's an array, join it or take first element
                    if ($values.project.Count -gt 0) {
                        $projectValue = [string]$values.project[0]
                        if ($this._enableDebugLogging) {
                            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: project is array, using first element: '$projectValue'"
                        }
                    } else {
                        if ($this._enableDebugLogging) {
                            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: project is empty array, setting to empty string"
                        }
                    }
                } elseif ($values.project -is [string] -and $values.project -ne '(No Project)' -and $values.project -ne '') {
                    $projectValue = $values.project
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: project is string: '$projectValue'"
                    }
                } else {
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: project is '(No Project)' or empty, setting to empty string"
                    }
                }
            } else {
                if ($this._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: project key missing, using empty string"
                }
            }

            # Validate text field (required)
            $taskText = if ($values.ContainsKey('text')) { $values.text } else { '' }
            if ([string]::IsNullOrWhiteSpace($taskText)) {
                $this.SetStatusMessage("Task description is required", "error")
                return
            }

            # Validate text length
            # MEDIUM FIX TLS-M1 & TLS-M2: Correct error message to match actual limit (200, not 500)
            if ($taskText.Length -gt 200) {
                $this.SetStatusMessage("Task description must be 200 characters or less", "error")
                return
            }

            # Ensure all values have correct types for Store validation
            $detailsValue = if ($values.ContainsKey('details')) { $values.details } else { '' }
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: values.tags type=$(if ($values.ContainsKey('tags') -and $values.tags) { $values.tags.GetType().Name } else { 'MISSING' }) value='$($values.tags)'"
            }
            # CRITICAL: Use comma operator to prevent PowerShell from unwrapping single-element arrays
            # TLS-M1 FIX: Added comma operator to prevent array unwrapping
            $tagsValue = @(if ($values.ContainsKey('tags') -and $values.tags) {
                if ($values.tags -is [array]) {
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: tags is already array"
                    }
                    ,$values.tags  # TLS-M1: Comma operator prevents unwrapping
                }
                elseif ($values.tags -is [string]) {
                    $splitResult = @($values.tags -split ',' | ForEach-Object { $_.Trim() })
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: split tags string into array, type=$($splitResult.GetType().Name) count=$($splitResult.Count)"
                    }
                    ,$splitResult  # TLS-M1: Comma operator prevents unwrapping
                }
                else {
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: tags is unknown type, returning empty array"
                    }
                    @()
                }
            } else {
                if ($this._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: tags missing or empty, returning empty array"
                }
            })
            $tagCount = if ($tagsValue -is [array]) { $tagsValue.Count } else { 'N/A' }
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: tagsValue type=$($tagsValue.GetType().Name) count=$tagCount isArray=$($tagsValue -is [array])"
            }

            $changes = @{
                text = [string]$taskText
                details = [string]$detailsValue
                project = [string]$projectValue
                tags = $tagsValue
            }

            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: project type=$($changes.project.GetType().Name) value='$($changes.project)'"
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: tags type=$(if ($changes.tags) { $changes.tags.GetType().Name } else { 'NULL' }) value=$(if ($changes.tags -is [array]) { $changes.tags -join ',' } else { $changes.tags })"
            }

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
            try {
                . "$PSScriptRoot/../helpers/ValidationHelper.ps1"
            } catch {
                Write-PmcTuiLog "Failed to load ValidationHelper: $_" "ERROR"
                $this.SetStatusMessage("Validation system error, task not updated", "error")
                return
            }

            # Merge changes with existing task for validation
            # CRITICAL FIX TLS-C1: Handle both hashtables and PSObjects
            $updatedTask = @{}
            if ($item -is [hashtable]) {
                foreach ($key in $item.Keys) {
                    $updatedTask[$key] = $item[$key]
                }
            } elseif ($null -ne $item.PSObject.Properties) {
                foreach ($key in $item.PSObject.Properties.Name) {
                    $updatedTask[$key] = $item.$key
                }
            }
            foreach ($key in $changes.Keys) {
                $updatedTask[$key] = $changes[$key]
            }

            # Validate updated task
            $validationResult = Test-TaskValid $updatedTask

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

            # Update in store
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: Calling Store.UpdateTask with item.id=$($item.id)"
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: changes=$($changes | ConvertTo-Json -Compress)"
            }
            $success = $this.Store.UpdateTask($item.id, $changes)
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: UpdateTask returned success=$success"
            }
            if ($success) {
                $this.SetStatusMessage("Task updated: $($values.text)", "success")
                if ($this._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: SUCCESS - calling LoadData to refresh"
                }
                try {
                    $this.LoadData()  # Refresh the list to show updated data
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: LoadData completed"
                    }
                } catch {
                    Write-PmcTuiLog "OnItemUpdated: LoadData failed: $_" "WARNING"
                    $this.SetStatusMessage("Task updated but display refresh failed", "warning")
                }
            } else {
                $this.SetStatusMessage("Failed to update task: $($this.Store.LastError)", "error")
                if ($this._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: FAILED - error=$($this.Store.LastError)"
                }
            }
        }
        catch {
            # LOW FIX TLS-L1: Add context to exception messages
            $taskId = if ($null -ne $item -and (Get-SafeProperty $item 'id')) { $item.id } else { "(unknown)" }
            $taskText = if ($values.ContainsKey('text')) { $values.text } else { if ($null -ne $item) { (Get-SafeProperty $item 'text') } else { "(no title)" } }
            Write-PmcTuiLog "OnItemUpdated exception while updating task '$taskText' (ID: $taskId): $_" "ERROR"
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: EXCEPTION for task $taskId - $($_.Exception.Message)"
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnItemUpdated: Stack trace - $($_.ScriptStackTrace)"
            }
            $this.SetStatusMessage("Error updating task '$taskText': $($_.Exception.Message)", "error")
        }
    }

    # Override: Handle item deletion
    [void] OnItemDeleted([object]$item) {
        # CRITICAL FIX TLS-C2: Add null check on $item
        if ($null -eq $item) {
            Write-PmcTuiLog "OnItemDeleted called with null item" "ERROR"
            $this.SetStatusMessage("Cannot delete: no item selected", "error")
            return
        }
        $taskId = Get-SafeProperty $item 'id'
        if ($null -eq $taskId) {
            Write-PmcTuiLog "OnItemDeleted called with item missing id property" "ERROR"
            $this.SetStatusMessage("Cannot delete: task has no ID", "error")
            return
        }
        try {
            $success = $this.Store.DeleteTask($taskId)
            if ($success) {
                $this.SetStatusMessage("Task deleted: $($item.text)", "success")
            } else {
                $this.SetStatusMessage("Failed to delete task: $($this.Store.LastError)", "error")
            }
        }
        catch {
            # LOW FIX TLS-L1: Add context to exception messages
            $taskId = if ($null -ne $item) { (Get-SafeProperty $item 'id') } else { "(unknown)" }
            $taskText = if ($null -ne $item) { (Get-SafeProperty $item 'text') } else { "(no title)" }
            Write-PmcTuiLog "OnItemDeleted exception while deleting task '$taskText' (ID: $taskId): $_" "ERROR"
            $this.SetStatusMessage("Error deleting task '$taskText': $($_.Exception.Message)", "error")
        }
    }

    # Custom action: Toggle task completion
    [void] ToggleTaskCompletion([object]$task) {
        if ($null -eq $task) { return }

        $completed = Get-SafeProperty $task 'completed'
        $taskId = Get-SafeProperty $task 'id'
        $taskText = Get-SafeProperty $task 'text'

        $newStatus = -not $completed
        $success = $this.Store.UpdateTask($taskId, @{ completed = $newStatus })

        if ($success) {
            $statusText = if ($newStatus) { "completed" } else { "reopened" }
            $this.SetStatusMessage("Task ${statusText}: $taskText", "success")
            # TLS-M2 FIX: Invalidate cache after successful update
            $this._cachedFilteredTasks = $null
            $this._cacheKey = ""
            $this.LoadData()
        } else {
            $this.SetStatusMessage("Failed to update task: $($this.Store.LastError)", "error")
            Write-PmcTuiLog "ToggleTaskCompletion failed: $($this.Store.LastError)" "ERROR"
        }
    }

    # Custom action: Mark task complete
    [void] CompleteTask([object]$task) {
        if ($null -eq $task) { return }

        $taskId = Get-SafeProperty $task 'id'
        $taskText = Get-SafeProperty $task 'text'

        $success = $this.Store.UpdateTask($taskId, @{
            completed = $true
            completed_at = [DateTime]::Now
        })

        if ($success) {
            $this.SetStatusMessage("Task completed: $taskText", "success")
            # TLS-M2 FIX: Invalidate cache after successful update
            $this._cachedFilteredTasks = $null
            $this._cacheKey = ""
            $this.LoadData()
        } else {
            $this.SetStatusMessage("Failed to complete task: $($this.Store.LastError)", "error")
            Write-PmcTuiLog "CompleteTask failed: $($this.Store.LastError)" "ERROR"
        }
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

        $success = $this.Store.AddTask($clonedTask)
        if ($success) {
            $this.SetStatusMessage("Task cloned: $($clonedTask.text)", "success")
            # TLS-M2 FIX: Invalidate cache after successful add
            $this._cachedFilteredTasks = $null
            $this._cacheKey = ""
            $this.LoadData()
        } else {
            $this.SetStatusMessage("Failed to clone task: $($this.Store.LastError)", "error")
            Write-PmcTuiLog "CloneTask failed: $($this.Store.LastError)" "ERROR"
        }
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

        # Get parent id with null check
        $parentId = $null
        if ($parentTask -is [hashtable] -and $parentTask.ContainsKey('id')) {
            $parentId = $parentTask['id']
        } elseif ($parentTask.PSObject.Properties['id']) {
            $parentId = $parentTask.id
        }

        if ($null -eq $parentId) {
            $this.SetStatusMessage("Cannot add subtask: parent task has no ID", "error")
            return
        }

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
        # MEDIUM FIX TLS-M5: Add null check on InlineEditor
        if ($null -eq $this.InlineEditor) {
            Write-PmcTuiLog "AddSubtask: InlineEditor is null" "ERROR"
            $this.SetStatusMessage("Cannot add subtask: editor not initialized", "error")
            return
        }
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

        $successCount = 0
        $failCount = 0
        foreach ($task in $selected) {
            $taskId = Get-SafeProperty $task 'id'
            $success = $this.Store.UpdateTask($taskId, @{
                completed = $true
                completed_at = [DateTime]::Now
            })
            if ($success) {
                $successCount++
            } else {
                $failCount++
                Write-PmcTuiLog "BulkCompleteSelected failed for task $taskId: $($this.Store.LastError)" "ERROR"
            }
        }

        if ($failCount -eq 0) {
            $this.SetStatusMessage("Completed $successCount tasks", "success")
        } else {
            $this.SetStatusMessage("Completed $successCount tasks, failed $failCount", "warning")
        }
        $this.List.ClearSelection()
    }

    # Custom action: Bulk delete selected tasks
    [void] BulkDeleteSelected() {
        $selected = $this.List.GetSelectedItems()
        if ($selected.Count -eq 0) {
            $this.SetStatusMessage("No tasks selected", "warning")
            return
        }

        $successCount = 0
        $failCount = 0
        foreach ($task in $selected) {
            $taskId = Get-SafeProperty $task 'id'
            $success = $this.Store.DeleteTask($taskId)
            if ($success) {
                $successCount++
            } else {
                $failCount++
                Write-PmcTuiLog "BulkDeleteSelected failed for task $taskId: $($this.Store.LastError)" "ERROR"
            }
        }

        if ($failCount -eq 0) {
            $this.SetStatusMessage("Deleted $successCount tasks", "success")
        } else {
            $this.SetStatusMessage("Deleted $successCount tasks, failed $failCount", "warning")
        }
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
        if ($this._enableDebugLogging) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: ENTRY"
        }

        if ($null -eq $item) {
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: NULL ITEM - RETURNING"
            }
            return
        }

        if ($this._enableDebugLogging) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: Setting _isEditingRow = TRUE"
        }
        $this._isEditingRow = $true
        $this._currentColumnIndex = 0

        # LOW FIX TLS-L3: Clear old _editValues to prevent potential memory leak
        if ($null -ne $this._editValues) {
            $this._editValues.Clear()
        }

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

        if ($this._enableDebugLogging) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: _isEditingRow = $($this._isEditingRow)"
        }

        # CRITICAL: Invalidate the list's row cache so Format callbacks get re-invoked
        # HIGH FIX TLS-H2: Add null check before List operations
        if ($null -ne $this.List) {
            $this.List.InvalidateCache()
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: Invalidated list cache"
            }
        } else {
            Write-PmcTuiLog "EditItem: List is null, cannot invalidate cache" "ERROR"
        }

        # Force a status message and mark app dirty to trigger immediate render
        $this.SetStatusMessage("*** EDITING MODE ACTIVE *** Tab=next, Enter=save, Esc=cancel", "success")

        if ($this._enableDebugLogging) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: Called SetStatusMessage"
        }

        # CRITICAL: Force immediate re-render by marking the app dirty
        if ($global:PmcApp) {
            $global:PmcApp.IsDirty = $true
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: Set IsDirty=true"
            }
        }

        if ($this._enableDebugLogging) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditItem: EXIT"
        }
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

        # HIGH FIX TLS-H3 & MEDIUM FIX TLS-M8: Add array bounds check on _currentColumnIndex
        if ($this._currentColumnIndex -lt 0 -or $this._currentColumnIndex -ge $this._editableColumns.Count) {
            Write-PmcTuiLog "_ShowWidgetForColumn: Invalid column index $($this._currentColumnIndex)" "ERROR"
            return
        }
        $col = $this._editableColumns[$this._currentColumnIndex]

        # Only show widgets for due/project columns (tags is now inline text)
        if ($col -ne 'due' -and $col -ne 'project') {
            return
        }

        # Get column position from GetColumns()
        $columns = $this.GetColumns()
        $colX = 0
        $colIndex = 0
        $columnFound = $false
        foreach ($column in $columns) {
            if ($column.Name -eq $col) {
                $columnFound = $true
                break
            }
            $colX += $column.Width + 1
            $colIndex++
        }
        # MEDIUM FIX TLS-M8: Validate column was found
        if (-not $columnFound) {
            Write-PmcTuiLog "_ShowWidgetForColumn: Column '$col' not found in GetColumns()" "WARNING"
            return
        }

        # Get selected row Y position
        $selectedIndex = $this.List.GetSelectedIndex()
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)
        if ($null -eq $contentRect) {
            Write-PmcTuiLog "_ShowWidgetForColumn: LayoutManager.GetRegion returned null" "WARNING"
            return
        }
        # HIGH FIX TLS-H5: Account for scroll offset when calculating widget position
        $scrollOffset = if ($this.List -and $this.List.PSObject.Properties['_scrollOffset']) {
            $this.List._scrollOffset
        } else {
            0
        }
        $rowY = $contentRect.Y + ($selectedIndex - $scrollOffset) + 2  # +2 for header

        $this._EnsureWidgetsLoaded()

        if ($col -eq 'due') {
            try {
                $this._activeDatePicker = [DatePicker]::new()
            } catch {
                Write-PmcTuiLog "Failed to create DatePicker: $_" "ERROR"
                $this.SetStatusMessage("Failed to open date picker", "error")
                return
            }

            if ($null -eq $this._activeDatePicker) {
                Write-PmcTuiLog "DatePicker constructor returned null" "ERROR"
                $this.SetStatusMessage("Failed to open date picker", "error")
                return
            }

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
            try {
                $this._activeProjectPicker = [ProjectPicker]::new()
            } catch {
                Write-PmcTuiLog "Failed to create ProjectPicker: $_" "ERROR"
                $this.SetStatusMessage("Failed to open project picker", "error")
                return
            }

            if ($null -eq $this._activeProjectPicker) {
                Write-PmcTuiLog "ProjectPicker constructor returned null" "ERROR"
                $this.SetStatusMessage("Failed to open project picker", "error")
                return
            }

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
                if ($self._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnProjectSelected callback: projectName='$projectName'"
                }
                $self._editValues.project = $projectName
                if ($self._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') OnProjectSelected: Set _editValues.project to '$($self._editValues.project)'"
                }
                $self._CloseActiveWidget()
            }.GetNewClosure()

            $this._activeProjectPicker.OnCancelled = {
                $self._CloseActiveWidget()
            }.GetNewClosure()

            $this._activeWidgetType = 'project'
        }
        elseif ($col -eq 'tags') {
            try {
                $this._activeTagEditor = [TagEditor]::new()
            } catch {
                Write-PmcTuiLog "Failed to create TagEditor: $_" "ERROR"
                $this.SetStatusMessage("Failed to open tag editor", "error")
                return
            }

            if ($null -eq $this._activeTagEditor) {
                Write-PmcTuiLog "TagEditor constructor returned null" "ERROR"
                $this.SetStatusMessage("Failed to open tag editor", "error")
                return
            }

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
        if ($this._enableDebugLogging) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _HandleInlineEditInput: Key=$($keyInfo.Key) Char='$($keyInfo.KeyChar)' Column=$($this._editableColumns[$this._currentColumnIndex]) Widget=$($this._activeWidgetType)"
        }

        # Tab/Shift+Tab always closes widget and moves to next/prev field
        if ($keyInfo.Key -eq 'Tab') {
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Tab pressed - saving widget value and closing, editValues: pri=$($this._editValues.priority) title=$($this._editValues.title) details=$($this._editValues.details)"
            }

            # Save widget value before closing
            if ($this._activeWidgetType -eq 'date' -and $null -ne $this._activeDatePicker) {
                # HIGH FIX TLS-H5 & TLS-H7: Validate GetSelectedDate() return value
                $selectedDate = $this._activeDatePicker.GetSelectedDate()
                if ($null -ne $selectedDate) {
                    $this._editValues.due = $selectedDate.ToString('yyyy-MM-dd')
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Saved date from picker: $($this._editValues.due)"
                    }
                } else {
                    Write-PmcTuiLog "DatePicker.GetSelectedDate() returned null" "WARNING"
                }
            }
            elseif ($this._activeWidgetType -eq 'project' -and $null -ne $this._activeProjectPicker) {
                # ProjectPicker saves through its callback, but we can check if there's a selected project
                $selectedProj = $this._activeProjectPicker.GetSelectedProject()
                if ($selectedProj) {
                    $this._editValues.project = $selectedProj
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Saved project from picker: $($this._editValues.project)"
                    }
                }
            }
            elseif ($this._activeWidgetType -eq 'tags' -and $null -ne $this._activeTagEditor) {
                $this._editValues.tags = $this._activeTagEditor.GetTags() -join ', '
                if ($this._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Saved tags from editor: $($this._editValues.tags)"
                }
            }

            $this._CloseActiveWidget()
            # Fall through to Tab handler below
        }
        # If a widget is active, route input to it
        elseif ($this._activeWidgetType -ne "") {
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Widget active ($($this._activeWidgetType)) - passing key to widget, returning early"
            }
            $handled = $false

            if ($this._activeWidgetType -eq 'date' -and $null -ne $this._activeDatePicker) {
                $handled = $this._activeDatePicker.HandleInput($keyInfo)

                # Check if widget closed itself
                if ($this._activeDatePicker -and ($this._activeDatePicker.IsConfirmed -or $this._activeDatePicker.IsCancelled)) {
                    $this._CloseActiveWidget()
                }
            }
            elseif ($this._activeWidgetType -eq 'project' -and $null -ne $this._activeProjectPicker) {
                if ($this._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Calling ProjectPicker.HandleInput with key=$($keyInfo.Key)"
                }
                $handled = $this._activeProjectPicker.HandleInput($keyInfo)
                if ($this._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') ProjectPicker.HandleInput returned: $handled"
                }

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
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') ProjectPicker confirmed/cancelled, closing widget"
                    }
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

            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Widget handled key, returning true (EARLY EXIT)"
            }
            return $true
        }

        # Tab - next column
        if ($keyInfo.Key -eq 'Tab' -and -not ($keyInfo.Modifiers -band [ConsoleModifiers]::Shift)) {
            # CRITICAL FIX TLS-C3: Prevent division by zero
            if ($this._editableColumns.Count -gt 0) {
                $this._currentColumnIndex = ($this._currentColumnIndex + 1) % $this._editableColumns.Count
                $this.List.InvalidateCache()  # Invalidate cache to update highlighting
                $this._ShowWidgetForColumn()
            }
            return $true
        }
        # Shift+Tab - previous column
        if ($keyInfo.Key -eq 'Tab' -and ($keyInfo.Modifiers -band [ConsoleModifiers]::Shift)) {
            # CRITICAL FIX TLS-C3 & EDGE-2: Prevent division by zero and negative index
            if ($this._editableColumns.Count -gt 0) {
                $this._currentColumnIndex--
                if ($this._currentColumnIndex -lt 0) { $this._currentColumnIndex = $this._editableColumns.Count - 1 }
                $this.List.InvalidateCache()  # Invalidate cache to update highlighting
                $this._ShowWidgetForColumn()
            }
            return $true
        }
        # Enter - save
        if ($keyInfo.Key -eq 'Enter') {
            $item = $this.List.GetSelectedItem()
            if ($item) {
                if ($this._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Enter pressed - _editValues.priority=$($this._editValues.priority) type=$($this._editValues.priority.GetType().Name)"
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Enter pressed - _editValues.project=$($this._editValues.project)"
                }

                # Map title/details to text field for OnItemUpdated
                # Safely cast priority with validation
                $priorityValue = 3  # Default priority
                if ($null -ne $this._editValues.priority) {
                    $tempPriority = 0
                    if ([int]::TryParse($this._editValues.priority.ToString(), [ref]$tempPriority)) {
                        $priorityValue = $tempPriority
                    } else {
                        Write-PmcTuiLog "Invalid priority value '$($this._editValues.priority)', using default 3" "WARNING"
                    }
                }

                $updateValues = @{
                    text = $this._editValues.title ?? ""
                    details = $this._editValues.details
                    priority = $priorityValue
                    due = $this._editValues.due
                    project = $this._editValues.project
                    tags = $this._editValues.tags
                }
                if ($this._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Enter pressed - updateValues.priority=$($updateValues.priority) type=$($updateValues.priority.GetType().Name)"
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Enter pressed - updateValues.project=$($updateValues.project) type=$($updateValues.project.GetType().Name)"
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Enter pressed - calling OnItemUpdated with: text='$($updateValues.text)' details='$($updateValues.details)' pri=$($updateValues.priority) project=$($updateValues.project)"
                }
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
        if ($this._enableDebugLogging) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Processing input for column: $col Key=$($keyInfo.Key)"
        }

        if ($col -eq 'priority') {
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Priority column - checking arrows. Key=$($keyInfo.Key) CurrentPri=$($this._editValues.priority)"
            }
            # Safely parse current priority value
            $currentPriority = 3  # Default
            if ($null -ne $this._editValues.priority) {
                $tempPri = 0
                if ([int]::TryParse($this._editValues.priority.ToString(), [ref]$tempPri)) {
                    $currentPriority = $tempPri
                }
            }

            # Up/Right arrows: increase priority
            if ($keyInfo.Key -eq 'UpArrow' -or $keyInfo.Key -eq 'RightArrow') {
                if ($currentPriority -lt 5) {
                    $this._editValues.priority = $currentPriority + 1
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Priority increased to $($this._editValues.priority)"
                    }
                    $this.List.InvalidateCache()  # Re-render to show new value
                    if ($global:PmcApp) { $global:PmcApp.IsDirty = $true }  # Force immediate re-render
                } else {
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Priority already at MAX (5) - cannot increase"
                    }
                }
            }
            # Down/Left arrows: decrease priority
            elseif ($keyInfo.Key -eq 'DownArrow' -or $keyInfo.Key -eq 'LeftArrow') {
                if ($currentPriority -gt 0) {
                    $this._editValues.priority = $currentPriority - 1
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Priority decreased to $($this._editValues.priority)"
                    }
                    $this.List.InvalidateCache()  # Re-render to show new value
                    if ($global:PmcApp) { $global:PmcApp.IsDirty = $true }  # Force immediate re-render
                } else {
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Priority already at MIN (0) - cannot decrease"
                    }
                }
            } else {
                if ($this._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Priority column but key not an arrow: $($keyInfo.Key)"
                }
            }
        }
        elseif ($col -eq 'title' -or $col -eq 'details' -or $col -eq 'tags') {
            # Inline text editing for title, details, and tags
            if ($keyInfo.KeyChar -match '[a-zA-Z0-9 \-_.,!?@#$%^&*()\/\\:;''"<>]') {
                $this._editValues[$col] = ($this._editValues[$col] ?? "") + $keyInfo.KeyChar
                if ($this._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Added char to $col : '$($keyInfo.KeyChar)' -> '$($this._editValues[$col])'"
                }
                $this.List.InvalidateCache()  # Re-render to show new value
            }
            # MEDIUM FIX TLS-M6: Add defensive null check before .Length access
            if ($keyInfo.Key -eq 'Backspace') {
                $currentValue = $this._editValues[$col]
                if ($null -ne $currentValue -and $currentValue.Length -gt 0) {
                    $this._editValues[$col] = $currentValue.Substring(0, $currentValue.Length - 1)
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Backspace in $col -> '$($this._editValues[$col])'"
                    }
                    $this.List.InvalidateCache()  # Re-render to show new value
                }
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
        if ($this._enableDebugLogging) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') RenderContent CALLED: _isEditingRow=$($this._isEditingRow)"
        }

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
        if ($this._enableDebugLogging) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') TaskListScreen.HandleKeyPress: Key=$($keyInfo.Key) _isEditingRow=$($this._isEditingRow)"
        }

        # Handle inline editing first
        if ($this._isEditingRow) {
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') TaskListScreen.HandleKeyPress: Calling _HandleInlineEditInput"
            }
            return $this._HandleInlineEditInput($keyInfo)
        }

        # Custom shortcuts BEFORE base class
        $key = $keyInfo.Key
        $ctrl = $keyInfo.Modifiers -band [ConsoleModifiers]::Control
        $alt = $keyInfo.Modifiers -band [ConsoleModifiers]::Alt

        # Space: Toggle subtask collapse OR completion (BEFORE base class)
        if ($key -eq [ConsoleKey]::Spacebar -and -not $ctrl -and -not $alt) {
            $selected = $this.List.GetSelectedItem()
            if ($this._enableDebugLogging) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Space pressed: selected task id=$($selected.id) parent_id=$(Get-SafeProperty $selected 'parent_id')"
            }
            if ($selected) {
                $taskId = Get-SafeProperty $selected 'id'
                # LOW FIX TLS-L6 (MEDIUM priority): Add null check on GetAllTasks()
                $allTasks = $this.Store.GetAllTasks()
                if ($null -eq $allTasks) { $allTasks = @() }
                $hasChildren = $allTasks | Where-Object {
                    (Get-SafeProperty $_ 'parent_id') -eq $taskId
                } | Measure-Object | ForEach-Object { $_.Count -gt 0 }

                if ($this._enableDebugLogging) {
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Space: taskId=$taskId hasChildren=$hasChildren"
                }

                if ($hasChildren) {
                    # Toggle collapse
                    $wasCollapsed = $this._collapsedSubtasks.ContainsKey($taskId)
                    if ($wasCollapsed) {
                        $this._collapsedSubtasks.Remove($taskId)
                        if ($this._enableDebugLogging) {
                            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Space: Expanding task $taskId"
                        }
                    } else {
                        $this._collapsedSubtasks[$taskId] = $true
                        if ($this._enableDebugLogging) {
                            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Space: Collapsing task $taskId"
                        }
                    }
                    $this._cachedFilteredTasks = $null
                    $this.LoadData()
                    $this.List.InvalidateCache()  # Force re-render with new collapse state
                } else {
                    # No children - toggle completion
                    if ($this._enableDebugLogging) {
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') Space: No children - toggling completion"
                    }
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
        # LOW FIX TLS-L5: Add null check before ToUpper()
        $viewMode = if ($this._viewMode) { $this._viewMode.ToUpper() } else { 'ALL' }
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
