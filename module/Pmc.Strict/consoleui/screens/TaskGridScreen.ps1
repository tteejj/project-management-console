# TaskGridScreen.ps1
# Grid-based task list screen using EditableGrid

using namespace System

Set-StrictMode -Version Latest

<#
.SYNOPSIS
Grid-style task list screen with Excel-like inline editing

.DESCRIPTION
Extends GridScreen to provide task list with:
- Excel-style inline cell editing
- Type-to-edit interaction
- Tab/Arrow navigation between cells
- Undo/redo support
- Auto-commit on navigation
- Validation and error feedback

.EXAMPLE
$screen = [TaskGridScreen]::new()
$screen.Initialize()
$screen.Render()
#>

class TaskGridScreen : GridScreen {
    # TaskStore reference
    [object]$Store

    # View mode (inherited functionality from TaskListScreen)
    [string]$_viewMode = 'all'
    [bool]$_showCompleted = $true
    [string]$_sortColumn = 'due'
    [bool]$_sortAscending = $true

    # Loading state flag to prevent reentrant LoadData() calls
    hidden [bool]$_isLoading = $false

    # Constructor (backward compatible - no container)
    TaskGridScreen() : base('TaskGrid', 'Task List (Grid Mode)') {
        $this.AllowAdd = $true
        $this.AllowEdit = $true
        $this.AllowDelete = $true
    }

    # Constructor (with ServiceContainer)
    TaskGridScreen([object]$container) : base('TaskGrid', 'Task List (Grid Mode)', $container) {
        $this.AllowAdd = $true
        $this.AllowEdit = $true
        $this.AllowDelete = $true
    }

    # Override Initialize to set up TaskStore
    [void] Initialize() {
        Write-PmcTuiLog "TaskGridScreen.Initialize: START" "DEBUG"

        # Load TaskStore
        . "$PSScriptRoot/../../src/TaskStore.ps1"
        $this.Store = [TaskStore]::GetInstance()
        Write-PmcTuiLog "TaskGridScreen.Initialize: TaskStore loaded" "DEBUG"

        # Subscribe to store changes
        $self = $this
        $this.Store.Subscribe({
            if ($self.IsActive -and -not $self._isLoading) {
                $self.RefreshList()
            }
        }.GetNewClosure())

        # Call base initialization
        Write-PmcTuiLog "TaskGridScreen.Initialize: Calling base Initialize" "DEBUG"
        ([GridScreen]$this).Initialize()

        # Set up SkipRowHighlight callback to disable row highlight during edit mode
        Write-PmcTuiLog "TaskGridScreen.Initialize: About to install SkipRowHighlight - Grid=$($this.Grid) List=$($this.List)" "DEBUG"
        if ($null -ne $this.Grid -and $null -ne $this.Grid._columns -and $this.Grid._columns.Count -gt 0) {
            Write-PmcTuiLog "TaskGridScreen.Initialize: Grid has $($this.Grid._columns.Count) columns" "DEBUG"
            $grid = $this.Grid
            $this.Grid._columns[0]['SkipRowHighlight'] = {
                param($item)
                Write-PmcTuiLog "SkipRowHighlight CALLBACK: Called for item" "DEBUG"
                if ($null -ne $grid.GetIsInEditMode) {
                    $result = & $grid.GetIsInEditMode $item
                    Write-PmcTuiLog "SkipRowHighlight CALLBACK: Returning $result" "DEBUG"
                    return $result
                }
                Write-PmcTuiLog "SkipRowHighlight CALLBACK: No GetIsInEditMode, returning false" "DEBUG"
                return $false
            }.GetNewClosure()
            Write-PmcTuiLog "TaskGridScreen.Initialize: SkipRowHighlight callback INSTALLED" "DEBUG"
        } else {
            Write-PmcTuiLog "TaskGridScreen.Initialize: FAILED to install SkipRowHighlight - Grid or columns null" "ERROR"
        }

        Write-PmcTuiLog "TaskGridScreen.Initialize: COMPLETE" "DEBUG"
    }

    # Define columns for grid
    [array] GetColumns() {
        $selfScreen = $this
        return @(
            @{
                Name = 'title'
                Property = 'text'  # Map to 'text' field in task data
                Label = 'Task'
                Width = 35
                Align = 'left'
                Editable = $true
                Type = 'text'
                Validator = { param($value)
                    if ([string]::IsNullOrWhiteSpace($value)) {
                        return @{ IsValid = $false; Error = 'Task title cannot be empty' }
                    }
                    if ($value.Length -gt 200) {
                        return @{ IsValid = $false; Error = 'Task title too long (max 200 chars)' }
                    }
                    return @{ IsValid = $true; Error = $null }
                }
                Format = {
                    param($task, $cellInfo)
                    $value = $cellInfo.Value
                    if ([string]::IsNullOrWhiteSpace($value)) { $value = "" }

                    # In edit mode: ALL cells highlighted, FOCUSED cell has reverse video
                    if ($cellInfo.IsInEditMode) {
                        $ESC = [char]27
                        if ($cellInfo.IsFocused) {
                            # Focused cell: reverse video (swap fg/bg)
                            $displayValue = if ($value -eq "") { " " } else { $value }
                            return $ESC + "[7m" + $displayValue + $ESC + "[27m"
                        } else {
                            # Non-focused cells: use theme Highlight background
                            $displayValue = if ($value -eq "") { " " } else { $value }
                            # TEMP DEBUG
                            Add-Content -Path "/tmp/pmc-color-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') TITLE edit mode non-focused: Grid null=$($null -eq $selfScreen.Grid) CellRenderer null=$(if ($null -ne $selfScreen.Grid) { $null -eq $selfScreen.Grid.CellRenderer } else { 'N/A' })"
                            # Use CellRenderer to get themed background
                            if ($null -ne $selfScreen.Grid -and $null -ne $selfScreen.Grid.CellRenderer) {
                                $bg = $selfScreen.Grid.CellRenderer.GetHighlightBg()
                                Add-Content -Path "/tmp/pmc-color-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') TITLE: bg length=$($bg.Length)"
                                return $bg + $displayValue + $ESC + "[0m"
                            }
                            # Fallback if renderer not initialized (shouldn't happen)
                            Add-Content -Path "/tmp/pmc-color-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') TITLE: FALLBACK - returning plain value"
                            return $displayValue
                        }
                    }
                    return $value
                }.GetNewClosure()
                DisplayFormatter = { param($value)
                    if ([string]::IsNullOrWhiteSpace($value)) { return "" }
                    return $value
                }
            }
            @{
                Name = 'details'
                Label = 'Details'
                Width = 25
                Align = 'left'
                Editable = $true
                Type = 'text'
                Format = { param($task, $cellInfo)
                    $value = $cellInfo.Value
                    if ([string]::IsNullOrWhiteSpace($value)) { $value = "" }

                    # In edit mode: ALL cells highlighted, FOCUSED cell has reverse video
                    # DON'T pad - UniversalList adds padding WITHOUT background color
                    if ($cellInfo.IsInEditMode) {
                        $ESC = [char]27
                        if ($cellInfo.IsFocused) {
                            # Focused cell: reverse video (swap fg/bg)
                            # Add space if empty so background shows
                            $displayValue = if ($value -eq "") { " " } else { $value }
                            return $ESC + "[7m" + $displayValue + $ESC + "[27m"
                        } else {
                            # Non-focused cells in edit mode: lighter grey than row highlight (236 vs 235)
                            # Add space if empty so background shows
                            $displayValue = if ($value -eq "") { " " } else { $value }
                            # Use CellRenderer to get themed background
                            if ($null -ne $selfScreen.Grid -and $null -ne $selfScreen.Grid.CellRenderer) {
                                $bg = $selfScreen.Grid.CellRenderer.GetHighlightBg()
                                return $bg + $displayValue + $ESC + "[0m"
                            }
                            return $displayValue
                        }
                    }
                    return $value
                }.GetNewClosure()
                DisplayFormatter = { param($value)
                    if ([string]::IsNullOrWhiteSpace($value)) { return "" }
                    # Truncate with ellipsis
                    if ($value.Length -gt 23) {
                        return $value.Substring(0, 20) + "..."
                    }
                    return $value
                }
            }
            @{
                Name = 'priority'
                Label = 'Pri'
                Width = 3
                Align = 'center'
                Editable = $true
                Type = 'number'
                Format = { param($task, $cellInfo)
                    $value = $cellInfo.Value
                    if ($null -eq $value) { $value = "3" }
                    if ([string]::IsNullOrWhiteSpace($value)) { $value = "3" }

                    # In edit mode: ALL cells highlighted, FOCUSED cell has reverse video
                    # DON'T pad - UniversalList adds padding WITHOUT background color
                    $ESC = [char]27
                    if ($cellInfo.IsInEditMode) {
                        if ($cellInfo.IsFocused) {
                            # Focused cell: reverse video
                            $displayValue = if ($value -eq "") { " " } else { $value.ToString() }
                            return $ESC + "[7m" + $displayValue + $ESC + "[27m"
                        } else {
                            # Non-focused cells: lighter grey (236)
                            $displayValue = if ($value -eq "") { " " } else { $value.ToString() }
                            # Use CellRenderer to get themed background
                            if ($null -ne $selfScreen.Grid -and $null -ne $selfScreen.Grid.CellRenderer) {
                                $bg = $selfScreen.Grid.CellRenderer.GetHighlightBg()
                                return $bg + $displayValue + $ESC + "[0m"
                            }
                            return $displayValue
                        }
                    }

                    # Not in edit mode - color by priority
                    # Reset FOREGROUND only (\e[39m) to preserve row highlight BACKGROUND
                    $pri = $value
                    if ($pri -le 2) { return $ESC + "[91m" + $value + $ESC + "[39m" }
                    if ($pri -eq 3) { return $ESC + "[93m" + $value + $ESC + "[39m" }
                    return $ESC + "[92m" + $value + $ESC + "[39m"
                }.GetNewClosure()
                Validator = { param($value)
                    $num = 0
                    if (-not [int]::TryParse($value.ToString(), [ref]$num)) {
                        return @{ IsValid = $false; Error = 'Priority must be a number' }
                    }
                    if ($num -lt 1 -or $num -gt 5) {
                        return @{ IsValid = $false; Error = 'Priority must be 1-5' }
                    }
                    return @{ IsValid = $true; Error = $null }
                }
                DisplayFormatter = { param($value)
                    if ($null -eq $value) { return "3" }
                    return $value.ToString()
                }
                ColorFormatter = { param($task)
                    $pri = Get-SafeProperty $task 'priority'
                    if ($null -eq $pri) { $pri = 3 }
                    if ($pri -le 2) { return "`e[91m" }  # High priority = red
                    if ($pri -eq 3) { return "`e[93m" }  # Medium = yellow
                    return "`e[92m"  # Low = green
                }
            }
            @{
                Name = 'due'
                Label = 'Due Date'
                Width = 12
                Align = 'left'
                Editable = $true
                Type = 'date'
                Widget = 'date'
                Format = { param($task, $cellInfo)
                    $value = $cellInfo.Value
                    # Convert DateTime to string if needed
                    if ($value -is [DateTime]) {
                        $value = $value.ToString('yyyy-MM-dd')
                    }
                    if ([string]::IsNullOrWhiteSpace($value)) { $value = "" }

                    # In edit mode: ALL cells highlighted, FOCUSED cell has reverse video
                    # DON'T pad - UniversalList adds padding WITHOUT background color
                    if ($cellInfo.IsInEditMode) {
                        $ESC = [char]27
                        if ($cellInfo.IsFocused) {
                            # Focused cell: reverse video
                            $displayValue = if ($value -eq "") { " " } else { $value }
                            return $ESC + "[7m" + $displayValue + $ESC + "[27m"
                        } else {
                            # Non-focused cells: lighter grey (236)
                            $displayValue = if ($value -eq "") { " " } else { $value }
                            # Use CellRenderer to get themed background
                            if ($null -ne $selfScreen.Grid -and $null -ne $selfScreen.Grid.CellRenderer) {
                                $bg = $selfScreen.Grid.CellRenderer.GetHighlightBg()
                                return $bg + $displayValue + $ESC + "[0m"
                            }
                            return $displayValue
                        }
                    }
                    return $value
                }.GetNewClosure()
                DisplayFormatter = { param($value)
                    if ([string]::IsNullOrWhiteSpace($value)) { return "" }
                    try {
                        $date = [DateTime]::Parse($value)
                        $today = [DateTime]::Today
                        if ($date.Date -eq $today) {
                            return "Today"
                        } elseif ($date.Date -eq $today.AddDays(1)) {
                            return "Tomorrow"
                        } elseif ($date.Date -lt $today) {
                            return "OVERDUE!"
                        } else {
                            return $date.ToString('MMM dd')
                        }
                    } catch {
                        return $value
                    }
                }
                EditFormatter = { param($value)
                    if ([string]::IsNullOrWhiteSpace($value)) { return "" }
                    try {
                        $date = [DateTime]::Parse($value)
                        return $date.ToString('yyyy-MM-dd')
                    } catch {
                        return $value
                    }
                }
                ColorFormatter = { param($task)
                    $due = Get-SafeProperty $task 'due'
                    if ([string]::IsNullOrWhiteSpace($due)) { return "`e[90m" }  # Gray
                    try {
                        $date = [DateTime]::Parse($due)
                        $today = [DateTime]::Today
                        if ($date.Date -lt $today) {
                            return "`e[91m"  # Red for overdue
                        } elseif ($date.Date -eq $today) {
                            return "`e[93m"  # Yellow for today
                        }
                        return "`e[92m"  # Green for future
                    } catch {
                        return "`e[37m"
                    }
                }
            }
            @{
                Name = 'project'
                Label = 'Project'
                Width = 15
                Align = 'left'
                Editable = $true
                Type = 'text'
                Widget = 'project'
                Format = { param($task, $cellInfo)
                    $value = $cellInfo.Value
                    if ([string]::IsNullOrWhiteSpace($value)) { $value = "" }

                    # In edit mode: ALL cells highlighted, FOCUSED cell has reverse video
                    # DON'T pad - UniversalList adds padding WITHOUT background color
                    if ($cellInfo.IsInEditMode) {
                        $ESC = [char]27
                        if ($cellInfo.IsFocused) {
                            # Focused cell: reverse video (swap fg/bg)
                            # Add space if empty so background shows
                            $displayValue = if ($value -eq "") { " " } else { $value }
                            return $ESC + "[7m" + $displayValue + $ESC + "[27m"
                        } else {
                            # Non-focused cells in edit mode: lighter grey than row highlight (236 vs 235)
                            # Add space if empty so background shows
                            $displayValue = if ($value -eq "") { " " } else { $value }
                            # Use CellRenderer to get themed background
                            if ($null -ne $selfScreen.Grid -and $null -ne $selfScreen.Grid.CellRenderer) {
                                $bg = $selfScreen.Grid.CellRenderer.GetHighlightBg()
                                return $bg + $displayValue + $ESC + "[0m"
                            }
                            return $displayValue
                        }
                    }
                    return $value
                }.GetNewClosure()
                DisplayFormatter = { param($value)
                    if ([string]::IsNullOrWhiteSpace($value)) { return "-" }
                    # Truncate project name if too long
                    if ($value.Length -gt 13) {
                        return $value.Substring(0, 10) + "..."
                    }
                    return $value
                }
            }
            @{
                Name = 'tags'
                Label = 'Tags'
                Width = 20
                Align = 'left'
                Editable = $true
                Type = 'text'
                Widget = 'tags'
                Format = { param($task, $cellInfo)
                    $value = $cellInfo.Value
                    if ([string]::IsNullOrWhiteSpace($value)) { $value = "" }

                    # In edit mode: ALL cells highlighted, FOCUSED cell has reverse video
                    # DON'T pad - UniversalList adds padding WITHOUT background color
                    if ($cellInfo.IsInEditMode) {
                        $ESC = [char]27
                        if ($cellInfo.IsFocused) {
                            # Focused cell: reverse video (swap fg/bg)
                            # Add space if empty so background shows
                            $displayValue = if ($value -eq "") { " " } else { $value }
                            return $ESC + "[7m" + $displayValue + $ESC + "[27m"
                        } else {
                            # Non-focused cells in edit mode: lighter grey than row highlight (236 vs 235)
                            # Add space if empty so background shows
                            $displayValue = if ($value -eq "") { " " } else { $value }
                            # Use CellRenderer to get themed background
                            if ($null -ne $selfScreen.Grid -and $null -ne $selfScreen.Grid.CellRenderer) {
                                $bg = $selfScreen.Grid.CellRenderer.GetHighlightBg()
                                return $bg + $displayValue + $ESC + "[0m"
                            }
                            return $displayValue
                        }
                    }
                    return $value
                }.GetNewClosure()
                DisplayFormatter = { param($value)
                    if ($null -eq $value) { return "" }
                    if ($value -is [array]) {
                        $tagStr = ($value -join ', ')
                        if ($tagStr.Length -gt 18) {
                            return $tagStr.Substring(0, 15) + "..."
                        }
                        return $tagStr
                    }
                    return $value.ToString()
                }
                EditFormatter = { param($value)
                    if ($null -eq $value) { return "" }
                    if ($value -is [array]) {
                        return ($value -join ', ')
                    }
                    return $value.ToString()
                }
            }
            @{
                Name = 'status'
                Label = 'Status'
                Width = 12
                Align = 'left'
                Editable = $true
                Type = 'text'
                Format = { param($task, $cellInfo)
                    $value = $cellInfo.Value
                    if ([string]::IsNullOrWhiteSpace($value)) { $value = "" }

                    # In edit mode: ALL cells highlighted, FOCUSED cell has reverse video
                    # DON'T pad - UniversalList adds padding WITHOUT background color
                    if ($cellInfo.IsInEditMode) {
                        $ESC = [char]27
                        if ($cellInfo.IsFocused) {
                            # Focused cell: reverse video (swap fg/bg)
                            # Add space if empty so background shows
                            $displayValue = if ($value -eq "") { " " } else { $value }
                            return $ESC + "[7m" + $displayValue + $ESC + "[27m"
                        } else {
                            # Non-focused cells in edit mode: lighter grey than row highlight (236 vs 235)
                            # Add space if empty so background shows
                            $displayValue = if ($value -eq "") { " " } else { $value }
                            # Use CellRenderer to get themed background
                            if ($null -ne $selfScreen.Grid -and $null -ne $selfScreen.Grid.CellRenderer) {
                                $bg = $selfScreen.Grid.CellRenderer.GetHighlightBg()
                                return $bg + $displayValue + $ESC + "[0m"
                            }
                            return $displayValue
                        }
                    }
                    return $value
                }.GetNewClosure()
                DisplayFormatter = { param($value)
                    if ([string]::IsNullOrWhiteSpace($value)) { return "TODO" }
                    return $value.ToUpper()
                }
                ColorFormatter = { param($task)
                    $status = Get-SafeProperty $task 'status'
                    if ([string]::IsNullOrWhiteSpace($status)) { $status = "TODO" }
                    switch ($status.ToUpper()) {
                        'DONE' { return "`e[92m" }  # Green
                        'IN_PROGRESS' { return "`e[93m" }  # Yellow
                        'BLOCKED' { return "`e[91m" }  # Red
                        default { return "`e[37m" }  # White
                    }
                }
            }
            @{
                Name = 'id'
                Label = 'ID'
                Width = 0  # Hidden
                Align = 'left'
                Editable = $false
                ReadOnly = $true
            }
        )
    }

    # Get editable columns
    [string[]] GetEditableColumns() {
        return @('title', 'details', 'priority', 'due', 'project', 'tags', 'status')
    }

    # Configure cell editors
    [void] _ConfigureCellEditors() {
        # Use pre-configured registry
        $registry = [CellEditorRegistry]::CreateTaskListRegistry()

        # Override with grid's registry
        $this.Grid.EditorRegistry = $registry

        # Customize as needed
        $this.Grid.EditorRegistry.RegisterTextEditor('title', @{
            MaxLength = 200
            AllowEmpty = $false
        })

        $this.Grid.EditorRegistry.RegisterTextEditor('details', @{
            AllowEmpty = $true
        })

        $this.Grid.EditorRegistry.RegisterNumberEditor('priority', @{
            MinValue = 1
            MaxValue = 5
            AllowDecimals = $false
            AllowNegative = $false
        })

        $this.Grid.EditorRegistry.RegisterWidgetEditor('due', 'date', $null)
        $this.Grid.EditorRegistry.RegisterWidgetEditor('project', 'project', $null)
        $this.Grid.EditorRegistry.RegisterWidgetEditor('tags', 'tags', $null)

        $this.Grid.EditorRegistry.RegisterTextEditor('status', @{
            Pattern = '^(TODO|IN_PROGRESS|DONE|BLOCKED)$'
            AllowEmpty = $false
        })
    }

    # Load data from TaskStore
    [void] LoadData() {
        Write-PmcTuiLog "TaskGridScreen.LoadData: START" "DEBUG"
        $this._isLoading = $true

        # Install SkipRowHighlight callback if not already done
        if ($null -ne $this.Grid -and $null -ne $this.Grid._columns -and $this.Grid._columns.Count -gt 0) {
            if (-not $this.Grid._columns[0].ContainsKey('SkipRowHighlight')) {
                Write-PmcTuiLog "TaskGridScreen.LoadData: Installing SkipRowHighlight callback NOW" "DEBUG"
                $grid = $this.Grid
                $this.Grid._columns[0]['SkipRowHighlight'] = {
                    param($item)
                    if ($null -ne $grid.GetIsInEditMode) {
                        return & $grid.GetIsInEditMode $item
                    }
                    return $false
                }.GetNewClosure()
                Write-PmcTuiLog "TaskGridScreen.LoadData: SkipRowHighlight callback INSTALLED" "DEBUG"
            }
        }

        try {
            # Get tasks from store based on view mode
            $allTasks = $this._GetTasksForView()
            Write-PmcTuiLog "TaskGridScreen.LoadData: Got $($allTasks.Count) tasks from store" "DEBUG"

            # Apply sorting
            $allTasks = $this._SortTasks($allTasks)
            Write-PmcTuiLog "TaskGridScreen.LoadData: Sorted tasks, still have $($allTasks.Count)" "DEBUG"

            # Update list
            if ($null -ne $this.List) {
                Write-PmcTuiLog "TaskGridScreen.LoadData: List is NOT null, calling SetData" "DEBUG"
                $this.List.SetData($allTasks)
                # Debug: Show how many tasks loaded
                $this.SetStatusMessage("Loaded $($allTasks.Count) tasks", "info")
                Write-PmcTuiLog "TaskGridScreen.LoadData: SetData complete, status message set" "DEBUG"
            } else {
                Write-PmcTuiLog "TaskGridScreen.LoadData: ERROR - List is NULL!" "ERROR"
            }

        } finally {
            $this._isLoading = $false
            Write-PmcTuiLog "TaskGridScreen.LoadData: COMPLETE" "DEBUG"
        }
    }

    # Get tasks for current view mode
    hidden [array] _GetTasksForView() {
        $allTasks = $this.Store.GetAllTasks()
        if ($null -eq $allTasks) {
            return @()
        }

        switch ($this._viewMode) {
            'all' {
                return $allTasks
            }
            'active' {
                return $allTasks | Where-Object { -not (Get-SafeProperty $_ 'completed') }
            }
            'completed' {
                return $allTasks | Where-Object { Get-SafeProperty $_ 'completed' }
            }
            'overdue' {
                $today = [DateTime]::Today
                return $allTasks | Where-Object {
                    $due = Get-SafeProperty $_ 'due'
                    $due -and ([DateTime]::Parse($due).Date -lt $today) -and (-not (Get-SafeProperty $_ 'completed'))
                }
            }
            'today' {
                $today = [DateTime]::Today
                return $allTasks | Where-Object {
                    $due = Get-SafeProperty $_ 'due'
                    $due -and ([DateTime]::Parse($due).Date -eq $today)
                }
            }
            default {
                return $allTasks
            }
        }
        # Fallback return
        return $allTasks
    }

    # Sort tasks
    hidden [array] _SortTasks([array]$tasks) {
        if ($null -eq $tasks -or $tasks.Count -eq 0) {
            return @()
        }

        $sorted = $tasks | Sort-Object -Property $this._sortColumn -Descending:(-not $this._sortAscending)
        return $sorted
    }

    # Save dirty cells to TaskStore
    [bool] _SaveDirtyCells([GridCell[]]$dirtyCells) {
        if ($null -eq $dirtyCells -or $dirtyCells.Count -eq 0) {
            return $true
        }

        try {
            # Group cells by row ID
            $taskUpdates = @{}
            foreach ($cell in $dirtyCells) {
                if (-not $taskUpdates.ContainsKey($cell.RowId)) {
                    $taskUpdates[$cell.RowId] = @{}
                }
                $taskUpdates[$cell.RowId][$cell.ColumnName] = $cell.EditValue
            }

            # Update each task
            foreach ($taskId in $taskUpdates.Keys) {
                $updates = $taskUpdates[$taskId]

                # Map column names to actual task property names
                # Column 'title' -> property 'text'
                $propertyMap = @{
                    'title' = 'text'
                }

                # Build changes hashtable with correct property names
                $changes = @{}
                foreach ($colName in $updates.Keys) {
                    $propName = if ($propertyMap.ContainsKey($colName)) { $propertyMap[$colName] } else { $colName }
                    $changes[$propName] = $updates[$colName]
                }

                # Save to store using UpdateTask with changes hashtable
                $success = $this.Store.UpdateTask($taskId, $changes)
                if (-not $success) {
                    Write-PmcTuiLog "TaskGridScreen: Failed to update task $taskId" "WARNING"
                }
            }

            return $true

        } catch {
            Write-PmcTuiLog "TaskGridScreen: Error saving changes: $_" "ERROR"
            $this.SetStatusMessage("Error saving changes: $_", "error")
            return $false
        }
    }

    # Cell change callback
    [void] _OnCellChanged([GridCell]$cell) {
        # Auto-save on each cell change (or defer to manual save)
        # For now, just mark as dirty and require explicit save
        $this.SetStatusMessage("Cell modified (press 's' to save)", "info")
    }

    # Cell validation failed callback
    [void] _OnCellValidationFailed([GridCell]$cell) {
        ([GridScreen]$this)._OnCellValidationFailed($cell)
    }

    # Add new task
    [void] AddItem() {
        # Create new task with defaults (use 'text' not 'title' for TaskStore)
        $newTask = @{
            id = [Guid]::NewGuid().ToString()
            text = "New Task"
            details = ""
            priority = 3
            due = ""
            project = ""
            tags = @()
            status = "TODO"
            completed = $false
            created = [DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss')
        }

        # Add to store
        $this.Store.AddTask($newTask)

        # Refresh list
        $this.RefreshList()

        # Select new task
        $items = $this.List._filteredData
        $newIndex = 0
        for ($i = 0; $i -lt $items.Count; $i++) {
            if ((Get-SafeProperty $items[$i] 'id') -eq $newTask.id) {
                $newIndex = $i
                break
            }
        }
        $this.List.SetSelectedIndex($newIndex)

        # Start editing title cell
        $this.Grid.BeginEdit('title')

        $this.SetStatusMessage("New task created", "success")
    }

    # Delete selected task
    [void] DeleteItem([object]$item) {
        if ($null -eq $item) {
            return
        }

        $taskId = Get-SafeProperty $item 'id'
        if ([string]::IsNullOrWhiteSpace($taskId)) {
            return
        }

        # Confirm deletion
        $title = Get-SafeProperty $item 'title'
        if ([string]::IsNullOrWhiteSpace($title)) { $title = "this task" }

        # TODO: Add confirmation dialog
        # For now, just delete

        # Delete from store
        $this.Store.DeleteTask($taskId)

        # Refresh list
        $this.RefreshList()

        $this.SetStatusMessage("Task deleted", "success")
    }
}
