# GridScreen.ps1
# Base class for screens using EditableGrid widget

class GridScreen : StandardListScreen {
    # Grid widget (type is EditableGrid but declared as object to avoid parse-time dependency)
    [object]$Grid

    # Grid configuration
    hidden [bool]$_gridInitialized = $false
    hidden [string[]]$_editableColumns = @()
    hidden [object]$_editorRegistry  # Type is CellEditorRegistry but declared as object

    # Constructor (backward compatible - no container)
    GridScreen([string]$screenId, [string]$title) : base($screenId, $title) {
        # Grid will be created in InitializeList override
    }

    # Constructor (with ServiceContainer)
    GridScreen([string]$screenId, [string]$title, [object]$container) : base($screenId, $title, $container) {
        # Grid will be created in InitializeList override
    }

    # Override Initialize to set up renderer BEFORE first render
    [void] Initialize() {
        Write-PmcTuiLog "GridScreen.Initialize: START" "DEBUG"

        # Initialize Grid renderer with ThemeManager BEFORE base.Initialize()
        # This ensures CellRenderer is available when Format callbacks run
        try {
            if ($null -ne $this.Grid) {
                Write-PmcTuiLog "GridScreen.Initialize: Initializing Grid.CellRenderer" "DEBUG"
                # ThemeManager is injected by container - access it using PSObject
                $tm = $this.PSObject.Properties['ThemeManager']
                if ($null -ne $tm -and $null -ne $tm.Value) {
                    $this.Grid.InitializeRenderer($tm.Value)
                    Write-PmcTuiLog "GridScreen.Initialize: CellRenderer initialized successfully" "DEBUG"
                } else {
                    Write-PmcTuiLog "GridScreen.Initialize: ThemeManager not available yet" "WARN"
                }
            }
        } catch {
            Write-PmcTuiLog "GridScreen.Initialize: Error initializing renderer: $($_.Exception.Message)" "ERROR"
        }

        # Call base class initialization (this calls LoadData which triggers first render)
        ([StandardListScreen]$this).Initialize()

        Write-PmcTuiLog "GridScreen.Initialize: COMPLETE" "DEBUG"
    }

    # Override _InitializeComponents to use InitializeList() for creating grid
    hidden [void] _InitializeComponents() {
        Write-PmcTuiLog "GridScreen._InitializeComponents: START" "DEBUG"

        # Get terminal size
        $termSize = $this._GetTerminalSize()
        $this.TermWidth = $termSize.Width
        $this.TermHeight = $termSize.Height

        # Initialize TaskStore singleton
        $this.Store = [TaskStore]::GetInstance()

        # Call InitializeList to create EditableGrid (not UniversalList)
        Write-PmcTuiLog "GridScreen._InitializeComponents: Calling InitializeList" "DEBUG"
        $this.InitializeList()
        Write-PmcTuiLog "GridScreen._InitializeComponents: Grid created, List=$($null -ne $this.List)" "DEBUG"

        # Set list properties
        $this.List.SetPosition(0, 3)
        $this.List.SetSize($this.TermWidth, $this.TermHeight - 6)
        $this.List.Title = $this.ScreenTitle
        $this.List.AllowMultiSelect = $this.AllowMultiSelect
        # Note: AllowInlineEdit and AllowSearch are handled by EditableGrid

        # Wire up list events using GetNewClosure()
        $self = $this
        $this.List.OnSelectionChanged = {
            param($item)
            $self.OnItemSelected($item)
        }.GetNewClosure()

        $this.List.OnItemEdit = {
            param($data)
            # Data is hashtable with Item and Values keys from inline editing
            if ($data -is [hashtable] -and $data.ContainsKey('Values')) {
                $self.OnItemUpdated($data.Item, $data.Values)
            } else {
                # Legacy callback - just open editor
                $self.EditItem($data)
            }
        }.GetNewClosure()

        $this.List.OnItemDelete = {
            param($item)
            $self.DeleteItem($item)
        }.GetNewClosure()

        $this.List.OnItemActivated = {
            param($item)
            $self.OnItemActivated($item)
        }.GetNewClosure()

        # Initialize FilterPanel
        $this.FilterPanel = [FilterPanel]::new()
        $this.FilterPanel.SetPosition(10, 5)
        $this.FilterPanel.SetSize(80, 12)
        $this.FilterPanel.OnFiltersChanged = {
            param($filters)
            $this._ApplyFilters()
        }

        # Initialize InlineEditor (even though EditableGrid doesn't use it directly)
        $this.InlineEditor = [InlineEditor]::new()
        $this.InlineEditor.SetPosition(10, 5)
        $this.InlineEditor.SetSize(70, 25)

        Write-PmcTuiLog "GridScreen._InitializeComponents: COMPLETE" "DEBUG"
    }

    # Override InitializeList to create EditableGrid instead of UniversalList
    [void] InitializeList() {
        if ($null -ne $this.List) {
            return
        }

        # Get columns from derived class
        $columns = $this.GetColumns()
        if ($null -eq $columns) {
            throw "GetColumns() must return column definitions"
        }

        # Create EditableGrid
        $options = @{
            Columns = $columns
            Items = @()
            SelectedIndex = 0
        }

        $this.Grid = [EditableGrid]::new($options)
        $this.List = $this.Grid  # Expose as List for base class compatibility

        # Note: ThemeManager initialization happens in Initialize() override
        # after base class sets up ThemeManager

        # Configure grid options
        $this.Grid.AutoCommitOnMove = $true
        $this.Grid.EnableUndo = $true
        $this.Grid.ShowDirtyIndicator = $true
        $this.Grid.InlineValidation = $true

        # Set up callbacks
        $self = $this
        $this.Grid.OnCellChanged = { param($cell) $self._OnCellChanged($cell) }.GetNewClosure()
        $this.Grid.OnCellValidationFailed = { param($cell) $self._OnCellValidationFailed($cell) }.GetNewClosure()
        $this.Grid.OnBeforeCellEdit = { param($cell) $self._OnBeforeCellEdit($cell) }.GetNewClosure()

        # Configure editable columns
        $editableColumns = $this.GetEditableColumns()
        if ($null -ne $editableColumns -and $editableColumns.Count -gt 0) {
            $this.Grid.SetEditableColumns($editableColumns)
            $this._editableColumns = $editableColumns
        }

        # Configure cell editors
        $this._ConfigureCellEditors()

        $this._gridInitialized = $true
    }

    # Get editable columns (override in derived classes)
    [string[]] GetEditableColumns() {
        # Default: all columns except 'id' are editable
        $columns = $this.GetColumns()
        if ($null -eq $columns) {
            return @()
        }

        $editable = @()
        foreach ($col in $columns) {
            $colName = if ($col -is [hashtable]) { $col['Name'] } else { $col.Name }
            if ($colName -ne 'id' -and $colName -ne 'ID' -and $colName -ne 'Id') {
                $editable += $colName
            }
        }

        return $editable
    }

    # Configure cell editors (override in derived classes to customize)
    [void] _ConfigureCellEditors() {
        # Default implementation - derived classes can override
        # Example:
        # $this.Grid.EditorRegistry.RegisterTextEditor('title', @{ MaxLength = 200 })
        # $this.Grid.EditorRegistry.RegisterNumberEditor('priority', @{ MinValue = 1; MaxValue = 5 })
    }

    # Cell change callback (override in derived classes)
    [void] _OnCellChanged([GridCell]$cell) {
        # Default: trigger data save
        # Derived classes can override for custom behavior
    }

    # Cell validation failed callback (override in derived classes)
    [void] _OnCellValidationFailed([GridCell]$cell) {
        # Default: show error in status bar
        if ($null -ne $cell.ValidationError) {
            $this.SetStatusMessage("Validation error: $($cell.ValidationError)", "error")
        }
    }

    # Before cell edit callback (override in derived classes)
    [bool] _OnBeforeCellEdit([GridCell]$cell) {
        # Default: allow all edits
        # Return $false to cancel edit
        return $true
    }

    # Override HandleKeyPress to integrate grid key handling
    [bool] HandleKeyPress([System.ConsoleKeyInfo]$key) {
        Write-PmcTuiLog "GridScreen.HandleKeyPress: Key=$($key.Key)" "DEBUG"

        # Let grid handle keys first
        if ($null -ne $this.Grid) {
            Write-PmcTuiLog "GridScreen.HandleKeyPress: Calling Grid.HandleKey" "DEBUG"
            $handled = $this.Grid.HandleKey($key)
            if ($handled) {
                Write-PmcTuiLog "GridScreen.HandleKeyPress: Grid handled key" "DEBUG"
                # Grid handled it, screen will auto-refresh
                return $true
            }
            Write-PmcTuiLog "GridScreen.HandleKeyPress: Grid did not handle key, falling back" "DEBUG"
        }

        # Fall back to base class handling
        return ([StandardListScreen]$this).HandleKeyPress($key)
    }

    # Override RenderContent to use grid rendering
    [string] RenderContent() {
        Write-PmcTuiLog "GridScreen.RenderContent: ENTRY" "DEBUG"

        if ($null -eq $this.Grid) {
            Write-PmcTuiLog "GridScreen.RenderContent: Grid is NULL, returning empty" "ERROR"
            return ""
        }
        Write-PmcTuiLog "GridScreen.RenderContent: Grid exists" "DEBUG"

        # Get content region
        Write-PmcTuiLog "GridScreen.RenderContent: About to call LayoutManager.GetRegion('Content', $($this.TermWidth), $($this.TermHeight))" "DEBUG"
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        if ($null -eq $contentRect) {
            Write-PmcTuiLog "GridScreen.RenderContent: contentRect is NULL, returning empty" "ERROR"
            return ""
        }
        Write-PmcTuiLog "GridScreen.RenderContent: contentRect OK - X=$($contentRect.X) Y=$($contentRect.Y) W=$($contentRect.Width) H=$($contentRect.Height)" "DEBUG"

        # Set grid position and size
        $this.Grid.X = $contentRect.X
        $this.Grid.Y = $contentRect.Y
        $this.Grid.Width = $contentRect.Width
        $this.Grid.Height = $contentRect.Height
        Write-PmcTuiLog "GridScreen.RenderContent: Set Grid position/size - X=$($this.Grid.X) Y=$($this.Grid.Y) W=$($this.Grid.Width) H=$($this.Grid.Height)" "DEBUG"

        # Render grid
        Write-PmcTuiLog "GridScreen.RenderContent: About to call Grid.Render($($contentRect.Width), $($contentRect.Height))" "DEBUG"
        $output = $this.Grid.Render($contentRect.Width, $contentRect.Height)
        Write-PmcTuiLog "GridScreen.RenderContent: Grid.Render returned output length=$($output.Length)" "DEBUG"

        # Show unsaved changes indicator if needed
        if ($this.Grid.HasUnsavedChanges()) {
            $output += $this._RenderUnsavedIndicator($contentRect)
        }

        Write-PmcTuiLog "GridScreen.RenderContent: Returning output length=$($output.Length)" "DEBUG"
        return $output
    }

    # Override GetEditFields - not used in grid mode (grid uses inline editing)
    [array] GetEditFields($item) {
        # Grid editing happens inline, not via the old InlineEditor
        # Return empty array to avoid error
        return @()
    }

    # Render unsaved changes indicator
    hidden [string] _RenderUnsavedIndicator($contentRect) {
        if ($null -eq $contentRect) {
            return ""
        }

        $x = $contentRect.X + $contentRect.Width - 15
        $y = $contentRect.Y

        $indicator = " [Unsaved *] "
        $output = ""
        $output += [PraxisVT]::MoveTo($x, $y)
        $output += "`e[33m"  # Yellow
        $output += $indicator
        $output += [PraxisVT]::Reset()

        return $output
    }

    # Save all changes
    [bool] SaveChanges() {
        if ($null -eq $this.Grid) {
            return $false
        }

        # Commit any active edit first
        if ($null -ne $this.Grid._activeCell) {
            if (-not $this.Grid.CommitEdit()) {
                return $false
            }
        }

        # Get all dirty cells
        $dirtyCells = $this.Grid.GetDirtyCells()
        if ($dirtyCells.Count -eq 0) {
            return $true
        }

        # Save logic should be implemented by derived classes
        # This is just the base implementation
        $success = $this._SaveDirtyCells($dirtyCells)

        if ($success) {
            # Mark all as saved
            $this.Grid.ChangeTracker.MarkAllSaved()
            $this.SetStatusMessage("Changes saved successfully", "success")
        }

        return $success
    }

    # Save dirty cells (override in derived classes)
    [bool] _SaveDirtyCells([GridCell[]]$dirtyCells) {
        # Default implementation - derived classes should override
        # This is where you'd call PmcTaskManager::SaveTask, etc.
        return $true
    }

    # Discard all changes
    [void] DiscardChanges() {
        if ($null -eq $this.Grid) {
            return
        }

        # Revert all dirty cells
        foreach ($cell in $this.Grid.GetDirtyCells()) {
            $cell.CancelEdit()
        }

        # Clear change tracker
        $this.Grid.ChangeTracker.Clear()

        # Reload data
        $this.RefreshData()

        $this.SetStatusMessage("Changes discarded", "info")
    }

    # Undo last change
    [void] UndoChange() {
        if ($null -eq $this.Grid) {
            return
        }

        if ($this.Grid.Undo()) {
            $this.InvalidateCache()
            $this.SetStatusMessage("Undone", "info")
        }
    }

    # Redo last undone change
    [void] RedoChange() {
        if ($null -eq $this.Grid) {
            return
        }

        if ($this.Grid.Redo()) {
            $this.InvalidateCache()
            $this.SetStatusMessage("Redone", "info")
        }
    }

    # Get menu items (override to add grid-specific items)
    [array] GetMenuItems() {
        $baseItems = ([StandardListScreen]$this).GetMenuItems()

        # Add grid-specific menu items
        $gridItems = @(
            @{
                Key = 's'
                Label = 'Save'
                Description = 'Save changes'
                Action = { $this.SaveChanges() }
            }
            @{
                Key = 'Ctrl+Z'
                Label = 'Undo'
                Description = 'Undo last change'
                Action = { $this.UndoChange() }
            }
            @{
                Key = 'Ctrl+Y'
                Label = 'Redo'
                Description = 'Redo last undone change'
                Action = { $this.RedoChange() }
            }
            @{
                Key = 'Esc'
                Label = 'Discard'
                Description = 'Discard all changes'
                Action = { $this.DiscardChanges() }
            }
        )

        # Merge with base items
        return $baseItems + $gridItems
    }

    # Override LoadData to refresh grid
    [void] LoadData() {
        # Call base implementation
        ([StandardListScreen]$this).LoadData()

        # Refresh grid if initialized
        if ($this._gridInitialized -and $null -ne $this.Grid) {
            # Grid shares same data source as List
            $this.Grid.InvalidateCache()
        }
    }

    # Export grid data (utility method)
    [hashtable[]] ExportGridData() {
        if ($null -eq $this.Grid) {
            return @()
        }

        $items = $this.Grid.GetItems()
        if ($null -eq $items) {
            return @()
        }

        $exported = @()
        foreach ($item in $items) {
            $row = @{}
            foreach ($colName in $this._editableColumns) {
                if ($item.PSObject.Properties.Name -contains $colName) {
                    $row[$colName] = $item.$colName
                }
            }
            $exported += $row
        }

        return $exported
    }

    # Import grid data (utility method)
    [void] ImportGridData([hashtable[]]$data) {
        if ($null -eq $this.Grid) {
            return
        }

        # This would need to be implemented based on the data model
        # For now, just a placeholder
    }

    # Get column statistics (utility method)
    [hashtable] GetColumnStatistics([string]$columnName) {
        if ($null -eq $this.Grid) {
            return @{}
        }

        $items = $this.Grid.GetItems()
        if ($null -eq $items) {
            return @{}
        }

        $values = @()
        foreach ($item in $items) {
            if ($item.PSObject.Properties.Name -contains $columnName) {
                $value = $item.$columnName
                if ($null -ne $value) {
                    $values += $value
                }
            }
        }

        $stats = @{
            Count = $values.Count
            Unique = ($values | Select-Object -Unique).Count
        }

        # Try to calculate numeric stats
        $numericValues = @()
        foreach ($v in $values) {
            $num = 0.0
            if ([double]::TryParse($v.ToString(), [ref]$num)) {
                $numericValues += $num
            }
        }

        if ($numericValues.Count -gt 0) {
            $stats.Min = ($numericValues | Measure-Object -Minimum).Minimum
            $stats.Max = ($numericValues | Measure-Object -Maximum).Maximum
            $stats.Average = ($numericValues | Measure-Object -Average).Average
            $stats.Sum = ($numericValues | Measure-Object -Sum).Sum
        }

        return $stats
    }
}
