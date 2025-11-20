# EditableGrid.ps1
# Excel-style editable grid widget extending UniversalList

class EditableGrid : UniversalList {
    # Grid components
    [CellEditorRegistry]$EditorRegistry
    [object]$CellRenderer  # Can be ThemedCellRenderer or temporary dummy object
    [GridChangeTracker]$ChangeTracker

    # Edit state
    hidden [hashtable]$_cells = @{}           # Dictionary of GridCell objects (key: "rowId:columnName")
    hidden [int]$_activeColumnIndex = -1      # Currently selected column (-1 = none)
    hidden [GridCell]$_activeCell = $null     # Currently editing cell
    hidden [object]$_activeCellEditor = $null # Editor instance for active cell
    hidden [string[]]$_editableColumns = @()  # List of editable column names

    # Widget overlay state
    hidden [object]$_activeWidget = $null     # Active popup widget (DatePicker, etc.)
    hidden [string]$_activeWidgetType = ""    # Type of active widget

    # Column metadata
    hidden [hashtable]$_columnMetadata = @{}  # Parsed column configuration

    # Options
    [bool]$AutoCommitOnMove = $true           # Auto-commit when moving to another cell
    [bool]$EnableUndo = $true                 # Enable undo/redo support
    [bool]$ShowDirtyIndicator = $true         # Show * for modified cells
    [bool]$InlineValidation = $true           # Validate on every keystroke

    # Callbacks
    [scriptblock]$OnCellChanged = $null
    [scriptblock]$OnCellValidationFailed = $null
    [scriptblock]$OnBeforeCellEdit = $null

    # Constructor
    EditableGrid([hashtable]$options) : base() {
        # Initialize registry with default editors
        $this.EditorRegistry = [CellEditorRegistry]::new()

        # Create temporary dummy renderer - will be replaced with themed one when ThemeManager available
        # This ensures Format callbacks never see NULL CellRenderer
        $dummyRenderer = New-Object PSObject
        $dummyRenderer | Add-Member -MemberType ScriptMethod -Name GetHighlightBg -Value {
            # Fallback: grey background (ANSI 256 color)
            return "`e[48;5;236m"
        }
        $this.CellRenderer = $dummyRenderer

        # Change tracker
        $this.ChangeTracker = [GridChangeTracker]::new()
        $this.ChangeTracker.IsEnabled = $this.EnableUndo

        # Apply options to base UniversalList properties
        if ($null -ne $options) {
            if ($options.ContainsKey('Columns')) {
                $this.SetColumns($options['Columns'])
                $this._ParseColumnMetadata($options['Columns'])
            }
            if ($options.ContainsKey('Items')) {
                $this.SetData($options['Items'])
            }
            if ($options.ContainsKey('SelectedIndex')) {
                $this._selectedIndex = $options['SelectedIndex']
            }
        }

        # Set up callbacks for UniversalList to know about edit state
        $self = $this
        Write-PmcTuiLog "========== EditableGrid Constructor: Setting up callbacks ==========" "DEBUG"
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') ========== EditableGrid Constructor: Setting up callbacks =========="

        $this.GetIsInEditMode = {
            param($item)
            Write-PmcTuiLog "EditableGrid.GetIsInEditMode: Called" "DEBUG"
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.GetIsInEditMode: CALLBACK INVOKED - activeCell null=$($null -eq $self._activeCell)"
            if ($null -eq $self._activeCell) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.GetIsInEditMode: Returning FALSE (no active cell)"
                return $false
            }
            $rowId = $self._GetRowId($item)
            $result = $self._activeCell.RowId -eq $rowId -and $self._activeCell.IsEditing
            Write-PmcTuiLog "EditableGrid.GetIsInEditMode: Returning $result" "DEBUG"
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.GetIsInEditMode: Returning $result (rowId=$rowId activeCell.RowId=$($self._activeCell.RowId) IsEditing=$($self._activeCell.IsEditing))"
            return $result
        }.GetNewClosure()

        $this.GetFocusedColumnIndex = {
            param($item)
            # Convert from editable column index to VISIBLE column index (excluding width=0 columns)
            if ($self._activeColumnIndex -ge 0 -and $self._activeColumnIndex -lt $self._editableColumns.Count) {
                $columnName = $self._editableColumns[$self._activeColumnIndex]
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') GetFocusedColumnIndex: Looking for column='$columnName'"

                # Find the column in _columns array and count visible columns before it
                $visibleIndex = 0
                for ($i = 0; $i -lt $self._columns.Count; $i++) {
                    $col = $self._columns[$i]
                    $colName = if ($col -is [hashtable]) { $col['Name'] } else { $col.Name }
                    $colWidth = if ($col -is [hashtable]) { $col['Width'] } else { $col.Width }

                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') GetFocusedColumnIndex: _columns[$i] Name='$colName' Width=$colWidth"

                    if ($colName -eq $columnName) {
                        # Found target column - return visible index
                        Write-PmcTuiLog "EditableGrid.GetFocusedColumnIndex: Editable idx=$($self._activeColumnIndex) column=$columnName -> visible idx=$visibleIndex" "DEBUG"
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.GetFocusedColumnIndex: Editable idx=$($self._activeColumnIndex) column=$columnName -> visible idx=$visibleIndex"
                        return $visibleIndex
                    }

                    # Count this column if it's visible (width > 0)
                    if ($null -ne $colWidth -and $colWidth -gt 0) {
                        $visibleIndex++
                    }
                }
            }
            Write-PmcTuiLog "EditableGrid.GetFocusedColumnIndex: Returning -1 (no focus)" "DEBUG"
            return -1
        }.GetNewClosure()

        $this.GetEditValue = {
            param($item, $columnName)
            Write-PmcTuiLog "EditableGrid.GetEditValue: Called for column=$columnName" "DEBUG"
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.GetEditValue: CALLBACK INVOKED for column=$columnName activeCell null=$($null -eq $self._activeCell)"
            if ($null -eq $self._activeCell) {
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.GetEditValue: Returning NULL (no active cell)"
                return $null
            }
            $rowId = $self._GetRowId($item)
            if ($self._activeCell.RowId -eq $rowId -and $self._activeCell.ColumnName -eq $columnName) {
                Write-PmcTuiLog "EditableGrid.GetEditValue: Returning EditValue=$($self._activeCell.EditValue)" "DEBUG"
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.GetEditValue: Returning EditValue='$($self._activeCell.EditValue)' for column=$columnName"
                # CRITICAL: Use comma operator to wrap value in array, preserving empty strings
                # Without this, PowerShell treats empty string returns as $null
                return ,$self._activeCell.EditValue
            }
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.GetEditValue: Returning NULL (no match - rowId=$rowId activeCell.RowId=$($self._activeCell.RowId) activeCell.ColumnName=$($self._activeCell.ColumnName))"
            return $null
        }.GetNewClosure()

        Write-PmcTuiLog "EditableGrid Constructor: Callbacks installed - GetIsInEditMode type=$($this.GetIsInEditMode.GetType().Name)" "DEBUG"
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid Constructor: Callbacks INSTALLED - GetIsInEditMode=$($null -eq $this.GetIsInEditMode) GetFocusedColumnIndex null=$($null -eq $this.GetFocusedColumnIndex) GetEditValue null=$($null -eq $this.GetEditValue)"
    }

    # Initialize with theme manager (called after construction)
    [void] InitializeRenderer([PmcThemeManager]$themeManager) {
        if ($null -eq $this.CellRenderer) {
            $this.CellRenderer = [ThemedCellRenderer]::new($themeManager)
        }
    }

    # Get items (wrapper around UniversalList's _filteredData)
    [array] GetItems() {
        return $this._filteredData
    }

    # Parse column metadata from column definitions
    hidden [void] _ParseColumnMetadata([array]$columns) {
        if ($null -eq $columns) {
            return
        }

        for ($i = 0; $i -lt $columns.Count; $i++) {
            $col = $columns[$i]
            $colName = if ($col -is [hashtable]) { $col['Name'] } else { $col.Name }

            if ([string]::IsNullOrWhiteSpace($colName)) {
                continue
            }

            # Extract metadata from column definition
            $metadata = @{
                Index = $i
                Name = $colName
                Editable = $false
                ReadOnly = $false
                Type = 'text'
                Widget = $null
                Validator = $null
                DisplayFormatter = $null
                EditFormatter = $null
                ColorFormatter = $null
                Width = 20
            }

            # Populate from column definition
            if ($col -is [hashtable]) {
                if ($col.ContainsKey('Editable')) { $metadata.Editable = $col['Editable'] }
                if ($col.ContainsKey('ReadOnly')) { $metadata.ReadOnly = $col['ReadOnly'] }
                if ($col.ContainsKey('Type')) { $metadata.Type = $col['Type'] }
                if ($col.ContainsKey('Widget')) { $metadata.Widget = $col['Widget'] }
                if ($col.ContainsKey('Validator')) { $metadata.Validator = $col['Validator'] }
                if ($col.ContainsKey('DisplayFormatter')) { $metadata.DisplayFormatter = $col['DisplayFormatter'] }
                if ($col.ContainsKey('EditFormatter')) { $metadata.EditFormatter = $col['EditFormatter'] }
                if ($col.ContainsKey('ColorFormatter')) { $metadata.ColorFormatter = $col['ColorFormatter'] }
                if ($col.ContainsKey('Width')) { $metadata.Width = $col['Width'] }
            } else {
                # Try property access
                if ($col.PSObject.Properties['Editable']) { $metadata.Editable = $col.Editable }
                if ($col.PSObject.Properties['ReadOnly']) { $metadata.ReadOnly = $col.ReadOnly }
                if ($col.PSObject.Properties['Type']) { $metadata.Type = $col.Type }
                if ($col.PSObject.Properties['Widget']) { $metadata.Widget = $col.Widget }
                if ($col.PSObject.Properties['Validator']) { $metadata.Validator = $col.Validator }
                if ($col.PSObject.Properties['DisplayFormatter']) { $metadata.DisplayFormatter = $col.DisplayFormatter }
                if ($col.PSObject.Properties['EditFormatter']) { $metadata.EditFormatter = $col.EditFormatter }
                if ($col.PSObject.Properties['ColorFormatter']) { $metadata.ColorFormatter = $col.ColorFormatter }
                if ($col.PSObject.Properties['Width']) { $metadata.Width = $col.Width }
            }

            $this._columnMetadata[$colName] = $metadata
        }
    }

    # Set editable columns
    [void] SetEditableColumns([string[]]$columnNames) {
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') ========== SetEditableColumns CALLED with $($columnNames.Count) columns: $($columnNames -join ', ') =========="
        $this._editableColumns = $columnNames

        # Update metadata to mark columns as editable
        foreach ($colName in $columnNames) {
            if ($this._columnMetadata.ContainsKey($colName)) {
                $this._columnMetadata[$colName].Editable = $true
            }
        }

        # Initialize cells for all rows and columns
        $this._InitializeCells()
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') SetEditableColumns: COMPLETE - _editableColumns.Count=$($this._editableColumns.Count)"
    }

    # Get or create cell
    hidden [GridCell] _GetOrCreateCell([string]$rowId, [string]$columnName) {
        $key = "$($rowId):$columnName"

        if (-not $this._cells.ContainsKey($key)) {
            # Get current value from data
            $value = $this._GetCellValue($rowId, $columnName)
            $valueType = if ($null -eq $value) { "NULL" } else { $value.GetType().Name }
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetOrCreateCell: Creating NEW cell - rowId=$rowId column=$columnName value='$value' (type=$valueType)"

            # Create new cell
            $cell = [GridCell]::new($rowId, $columnName, $value)
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetOrCreateCell: Cell created - OriginalValue='$($cell.OriginalValue)' EditValue='$($cell.EditValue)'"

            # Set up formatters from column definition
            $column = $this._GetColumnDefinition($columnName)
            if ($null -ne $column) {
                if ($column.ContainsKey('DisplayFormatter')) {
                    $cell.Metadata['DisplayFormatter'] = $column['DisplayFormatter']
                }
                if ($column.ContainsKey('EditFormatter')) {
                    $cell.Metadata['EditFormatter'] = $column['EditFormatter']
                }
                if ($column.ContainsKey('Width')) {
                    $cell.Metadata['Width'] = $column['Width']
                }
            }

            $this._cells[$key] = $cell
        }

        return $this._cells[$key]
    }

    # Initialize cells for all visible rows
    hidden [void] _InitializeCells() {
        if ($this._editableColumns.Count -eq 0) {
            return
        }

        $items = $this.GetItems()
        if ($null -eq $items) {
            return
        }

        foreach ($item in $items) {
            $rowId = $this._GetRowId($item)
            foreach ($columnName in $this._editableColumns) {
                $cell = $this._GetOrCreateCell($rowId, $columnName)
            }
        }
    }

    # Get row ID from item
    hidden [string] _GetRowId([object]$item) {
        if ($null -eq $item) {
            return ""
        }

        # Try common ID fields
        $idFields = @('id', 'Id', 'ID', 'task_id', 'taskId', 'uuid', 'guid')

        # Handle both hashtables and PSObjects
        if ($item -is [hashtable]) {
            foreach ($field in $idFields) {
                if ($item.ContainsKey($field)) {
                    $value = $item[$field]
                    if ($null -ne $value) {
                        $rowId = $value.ToString()
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetRowId: HASHTABLE found field='$field' value='$rowId'"
                        return $rowId
                    }
                }
            }
        } else {
            foreach ($field in $idFields) {
                if ($item.PSObject.Properties.Name -contains $field) {
                    $value = $item.$field
                    if ($null -ne $value) {
                        $rowId = $value.ToString()
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetRowId: PSOBJECT found field='$field' value='$rowId'"
                        return $rowId
                    }
                }
            }
        }

        # Fallback: use GetHashCode
        $hashId = $item.GetHashCode().ToString()
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetRowId: FALLBACK GetHashCode='$hashId'"
        return $hashId
    }

    # Get cell value from data source
    hidden [object] _GetCellValue([string]$rowId, [string]$columnName) {
        $items = $this.GetItems()
        if ($null -eq $items) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetCellValue: No items, returning null"
            return $null
        }

        # Check if column has Property mapping
        $propertyName = $columnName
        $colDef = $this._GetColumnDefinition($columnName)
        if ($null -ne $colDef -and $colDef.ContainsKey('Property')) {
            $propertyName = $colDef['Property']
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetCellValue: Column '$columnName' maps to property '$propertyName'"
        }

        foreach ($item in $items) {
            if ($this._GetRowId($item) -eq $rowId) {
                # Handle both hashtables and PSObjects
                if ($item -is [hashtable]) {
                    $availableProps = $item.Keys -join ', '
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetCellValue: Found HASHTABLE with rowId=$rowId, looking for property=$propertyName (column=$columnName). Available keys: $availableProps"
                    if ($item.ContainsKey($propertyName)) {
                        $value = $item[$propertyName]
                        $valueType = if ($null -eq $value) { "NULL" } else { $value.GetType().Name }
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetCellValue: Found key, value='$value' (type=$valueType)"
                        return $value
                    }
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetCellValue: Key '$propertyName' NOT FOUND in hashtable, returning null"
                    return $null
                } else {
                    $availableProps = $item.PSObject.Properties.Name -join ', '
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetCellValue: Found PSOBJECT with rowId=$rowId, looking for column=$columnName. Available properties: $availableProps"
                    if ($item.PSObject.Properties.Name -contains $columnName) {
                        $value = $item.$columnName
                        $valueType = if ($null -eq $value) { "NULL" } else { $value.GetType().Name }
                        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetCellValue: Found column, value='$value' (type=$valueType)"
                        return $value
                    }
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetCellValue: Column '$columnName' NOT FOUND in item, returning null"
                    return $null
                }
            }
        }

        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') _GetCellValue: No item found with rowId=$rowId, returning null"
        return $null
    }

    # Get column definition from Columns property
    hidden [hashtable] _GetColumnDefinition([string]$columnName) {
        if ($null -eq $this._columns) {
            return $null
        }

        foreach ($col in $this._columns) {
            if ($col.Name -eq $columnName) {
                return $col
            }
        }

        return $null
    }

    # Begin editing cell at current selection
    [bool] BeginEdit([string]$columnName = $null) {
        Write-PmcTuiLog "========== BEGINEDIT CALLED ==========" "DEBUG"
        Write-PmcTuiLog "EditableGrid.BeginEdit: ENTRY columnName=$columnName" "DEBUG"

        $selectedIndex = $this.GetSelectedIndex()
        if ($selectedIndex -lt 0) {
            Write-PmcTuiLog "EditableGrid.BeginEdit: No selection, returning false" "DEBUG"
            return $false
        }

        $selectedItem = $this.GetSelectedItem()
        if ($null -eq $selectedItem) {
            Write-PmcTuiLog "EditableGrid.BeginEdit: No selected item, returning false" "DEBUG"
            return $false
        }

        $rowId = $this._GetRowId($selectedItem)
        Write-PmcTuiLog "EditableGrid.BeginEdit: rowId=$rowId selectedIndex=$selectedIndex" "DEBUG"

        # Determine which column to edit
        Write-PmcTuiLog "EditableGrid.BeginEdit: columnName='$columnName' IsNullOrWhiteSpace=$([string]::IsNullOrWhiteSpace($columnName))" "DEBUG"
        Write-PmcTuiLog "EditableGrid.BeginEdit: _editableColumns.Count=$($this._editableColumns.Count) _activeColumnIndex=$($this._activeColumnIndex)" "DEBUG"
        if ($this._editableColumns.Count -gt 0) {
            Write-PmcTuiLog "EditableGrid.BeginEdit: _editableColumns=$($this._editableColumns -join ',')" "DEBUG"
        }

        if ([string]::IsNullOrWhiteSpace($columnName)) {
            # Use active column or first editable column
            if ($this._activeColumnIndex -ge 0 -and $this._activeColumnIndex -lt $this._editableColumns.Count) {
                $columnName = $this._editableColumns[$this._activeColumnIndex]
                Write-PmcTuiLog "EditableGrid.BeginEdit: Using active column: $columnName" "DEBUG"
            } elseif ($this._editableColumns.Count -gt 0) {
                $columnName = $this._editableColumns[0]
                $this._activeColumnIndex = 0
                Write-PmcTuiLog "EditableGrid.BeginEdit: Using first editable column: $columnName" "DEBUG"
            } else {
                Write-PmcTuiLog "EditableGrid.BeginEdit: No editable columns available, returning false" "DEBUG"
                return $false
            }
        } else {
            # Find column index
            $this._activeColumnIndex = [array]::IndexOf($this._editableColumns, $columnName)
            Write-PmcTuiLog "EditableGrid.BeginEdit: Found column index: $($this._activeColumnIndex)" "DEBUG"
            if ($this._activeColumnIndex -lt 0) {
                Write-PmcTuiLog "EditableGrid.BeginEdit: Column not in editable columns, returning false" "DEBUG"
                return $false
            }
        }

        # Check if column is editable and not read-only
        Write-PmcTuiLog "EditableGrid.BeginEdit: Checking column metadata for '$columnName'" "DEBUG"
        if ($this._columnMetadata.ContainsKey($columnName)) {
            $metadata = $this._columnMetadata[$columnName]
            Write-PmcTuiLog "EditableGrid.BeginEdit: Column metadata found - ReadOnly=$($metadata.ReadOnly) Editable=$($metadata.Editable)" "DEBUG"
            if ($metadata.ReadOnly -or -not $metadata.Editable) {
                Write-PmcTuiLog "EditableGrid.BeginEdit: Column is ReadOnly or not Editable, returning false" "DEBUG"
                return $false
            }
        } else {
            Write-PmcTuiLog "EditableGrid.BeginEdit: No metadata for column, assuming editable" "DEBUG"
        }

        # Get or create cell
        Write-PmcTuiLog "EditableGrid.BeginEdit: Calling _GetOrCreateCell($rowId, $columnName)" "DEBUG"
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') ========== BeginEdit: Getting/Creating cell for rowId=$rowId column=$columnName =========="
        $this._activeCell = $this._GetOrCreateCell($rowId, $columnName)
        if ($null -eq $this._activeCell) {
            Write-PmcTuiLog "EditableGrid.BeginEdit: _GetOrCreateCell returned null, returning false" "DEBUG"
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') BeginEdit: FAILED - _GetOrCreateCell returned null"
            return $false
        }
        Write-PmcTuiLog "EditableGrid.BeginEdit: Got cell, EditValue=$($this._activeCell.EditValue)" "DEBUG"
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') BeginEdit: Got _activeCell - RowId=$($this._activeCell.RowId) ColumnName=$($this._activeCell.ColumnName) EditValue='$($this._activeCell.EditValue)'"

        # Fire before-edit callback
        if ($null -ne $this.OnBeforeCellEdit) {
            Write-PmcTuiLog "EditableGrid.BeginEdit: Firing OnBeforeCellEdit callback" "DEBUG"
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') BeginEdit: Firing OnBeforeCellEdit callback"
            try {
                $result = & $this.OnBeforeCellEdit $this._activeCell
                if ($result -eq $false) {
                    Write-PmcTuiLog "EditableGrid.BeginEdit: OnBeforeCellEdit returned false, canceling edit" "DEBUG"
                    Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') BeginEdit: OnBeforeCellEdit returned FALSE - CANCELING EDIT"
                    $this._activeCell = $null
                    return $false
                }
            } catch {
                Write-PmcTuiLog "EditableGrid.BeginEdit: OnBeforeCellEdit threw exception: $($_.Exception.Message)" "ERROR"
                Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') BeginEdit: OnBeforeCellEdit EXCEPTION: $($_.Exception.Message)"
                $this._activeCell = $null
                return $false
            }
        }

        # Begin editing
        Write-PmcTuiLog "EditableGrid.BeginEdit: Calling _activeCell.BeginEdit()" "DEBUG"
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') BeginEdit: Calling _activeCell.BeginEdit() - ACTIVATING EDITING MODE"
        $this._activeCell.BeginEdit()
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') BeginEdit: _activeCell.BeginEdit() completed - IsEditing=$($this._activeCell.IsEditing)"

        # Create cell editor
        $cellType = if ($this._columnMetadata.ContainsKey($columnName)) {
            $this._columnMetadata[$columnName].Type
        } else {
            'text'
        }
        $this._activeCellEditor = $this.EditorRegistry.GetEditor($columnName, $this._activeCell.EditValue)

        Write-PmcTuiLog "========== BeginEdit: SUCCESS - Returning TRUE ==========" "DEBUG"
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') ========== BeginEdit: SUCCESS - EDIT MODE ACTIVE - _activeCell NOT NULL IsEditing=$($this._activeCell.IsEditing) =========="
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') BeginEdit: _activeColumnIndex=$($this._activeColumnIndex) for column=$($this._activeCell.ColumnName)"
        return $true
    }

    # Commit current edit
    [bool] CommitEdit() {
        if ($null -eq $this._activeCell -or -not $this._activeCell.IsEditing) {
            return $false
        }

        # Get editor and validator
        $editor = $this.EditorRegistry.GetEditor($this._activeCell.ColumnName, $this._activeCell.EditValue)
        $validator = if ($null -ne $editor) {
            { param($value, $original) $editor.Validate($value) }
        } else {
            $null
        }

        # Track old value for undo
        $oldValue = $this._activeCell.OriginalValue

        # Commit cell edit
        $success = $this._activeCell.CommitEdit($validator)

        if ($success) {
            # Track change
            if ($this.EnableUndo) {
                $this.ChangeTracker.TrackEdit(
                    $this._activeCell.RowId,
                    $this._activeCell.ColumnName,
                    $oldValue,
                    $this._activeCell.EditValue
                )
            }

            # Update data source
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.CommitEdit: Updating data source"
            $this._UpdateDataSource($this._activeCell)

            # Fire callback
            if ($null -ne $this.OnCellChanged) {
                try {
                    & $this.OnCellChanged $this._activeCell
                } catch {
                    # Ignore callback errors
                }
            }

            # Cleanup
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.CommitEdit: SUCCESS - invalidating cache"
            $this._activeCell = $null
            $this._activeCellEditor = $null
            # Invalidate cache to force re-render with new value
            $this.InvalidateCache()
            return $true
        } else {
            # Validation failed - fire callback
            if ($null -ne $this.OnCellValidationFailed) {
                try {
                    & $this.OnCellValidationFailed $this._activeCell
                } catch {
                    # Ignore callback errors
                }
            }
        }

        return $false
    }

    # Cancel current edit
    [void] CancelEdit() {
        if ($null -ne $this._activeCell) {
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.CancelEdit: CANCELING edit"
            $this._activeCell.CancelEdit()
            $this._activeCell = $null
            $this._activeCellEditor = $null
            # Invalidate cache to force re-render
            $this.InvalidateCache()
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.CancelEdit: Cache invalidated, render should update"
        }
    }

    # Update data source with cell value
    hidden [void] _UpdateDataSource([GridCell]$cell) {
        Write-PmcTuiLog "EditableGrid._UpdateDataSource: ENTRY rowId=$($cell.RowId) col=$($cell.ColumnName) value=$($cell.EditValue)" "DEBUG"
        $items = $this.GetItems()
        if ($null -eq $items) {
            Write-PmcTuiLog "EditableGrid._UpdateDataSource: No items!" "DEBUG"
            return
        }

        # Check if column has Property mapping
        $propertyName = $cell.ColumnName
        $colDef = $this._GetColumnDefinition($cell.ColumnName)
        if ($null -ne $colDef -and $colDef.ContainsKey('Property')) {
            $propertyName = $colDef['Property']
            Write-PmcTuiLog "EditableGrid._UpdateDataSource: Column '$($cell.ColumnName)' maps to property '$propertyName'" "DEBUG"
        }

        foreach ($item in $items) {
            if ($this._GetRowId($item) -eq $cell.RowId) {
                Write-PmcTuiLog "EditableGrid._UpdateDataSource: Found matching item, type=$($item.GetType().Name)" "DEBUG"
                # Handle both hashtables and PSObjects
                if ($item -is [hashtable]) {
                    Write-PmcTuiLog "EditableGrid._UpdateDataSource: Item is hashtable, updating key=$propertyName value=$($cell.EditValue)" "DEBUG"
                    $item[$propertyName] = $cell.EditValue
                    Write-PmcTuiLog "EditableGrid._UpdateDataSource: Updated! New value=$($item[$propertyName])" "DEBUG"
                } elseif ($item.PSObject.Properties.Name -contains $propertyName) {
                    Write-PmcTuiLog "EditableGrid._UpdateDataSource: Item is PSObject, updating property" "DEBUG"
                    $item.($propertyName) = $cell.EditValue
                }
                break
            }
        }
        Write-PmcTuiLog "EditableGrid._UpdateDataSource: COMPLETE" "DEBUG"
    }

    # Handle key input
    [bool] HandleKey([System.ConsoleKeyInfo]$key) {
        Write-PmcTuiLog "EditableGrid.HandleKey: Key=$($key.Key) Char=$($key.KeyChar) activeCell=$($null -ne $this._activeCell) isEditing=$(if ($this._activeCell) { $this._activeCell.IsEditing } else { 'N/A' })" "DEBUG"
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.HandleKey: Key=$($key.Key) _editableColumns.Count=$($this._editableColumns.Count)"

        # If widget is active, delegate to widget
        if ($null -ne $this._activeWidget) {
            Write-PmcTuiLog "EditableGrid.HandleKey: Delegating to widget" "DEBUG"
            return $this._HandleWidgetKey($key)
        }

        # If cell is being edited, handle edit keys
        if ($null -ne $this._activeCell -and $this._activeCell.IsEditing) {
            Write-PmcTuiLog "EditableGrid.HandleKey: Handling edit key" "DEBUG"
            Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.HandleKey: Delegating to _HandleEditKey"
            return $this._HandleEditKey($key)
        }

        # Handle navigation keys
        Write-PmcTuiLog "EditableGrid.HandleKey: Handling navigation key" "DEBUG"
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') EditableGrid.HandleKey: Delegating to _HandleNavigationKey"
        return $this._HandleNavigationKey($key)
    }

    # Handle key during cell editing
    hidden [bool] _HandleEditKey([System.ConsoleKeyInfo]$key) {
        $keyCode = $key.Key

        # Commit keys: Enter, Tab, Down, Up (auto-commit enabled)
        if ($keyCode -in @('Enter', 'Tab', 'DownArrow', 'UpArrow')) {
            if ($this.AutoCommitOnMove) {
                $committed = $this.CommitEdit()
                if (-not $committed) {
                    # Validation failed - stay in edit mode
                    return $true
                }
            }

            # Handle navigation after commit
            switch ($keyCode) {
                'Enter' {
                    # DO NOT move - stay on current row
                    # User will use arrow keys to navigate
                }
                'Tab' {
                    # Move to next column
                    if ($key.Modifiers -band [ConsoleModifiers]::Shift) {
                        $this._MoveToPreviousColumn()
                    } else {
                        $this._MoveToNextColumn()
                    }
                }
                'DownArrow' {
                    $this._MoveToNextRow()
                }
                'UpArrow' {
                    $this._MoveToPreviousRow()
                }
            }

            return $true
        }

        # Cancel key: Escape
        if ($keyCode -eq 'Escape') {
            $this.CancelEdit()
            return $true
        }

        # Delegate to cell editor
        $editor = $this.EditorRegistry.GetEditor($this._activeCell.ColumnName, $this._activeCell.EditValue)
        if ($null -ne $editor) {
            $handled = $editor.HandleKey($this._activeCell, $key)

            # Inline validation if enabled
            if ($handled -and $this.InlineValidation) {
                $result = $editor.Validate($this._activeCell.EditValue)
                $this._activeCell.IsValid = $result.IsValid
                $this._activeCell.ValidationError = $result.Error
            }

            return $handled
        }

        return $false
    }

    # Handle navigation keys when not editing
    hidden [bool] _HandleNavigationKey([System.ConsoleKeyInfo]$key) {
        $keyCode = $key.Key
        $modifiers = $key.Modifiers

        # Undo/Redo shortcuts
        if ($modifiers -band [ConsoleModifiers]::Control) {
            switch ($keyCode) {
                'Z' {
                    if ($this.Undo()) {
                        return $true
                    }
                }
                'Y' {
                    if ($this.Redo()) {
                        return $true
                    }
                }
            }
        }

        switch ($keyCode) {
            'Enter' {
                # Begin editing at current column
                return $this.BeginEdit($null)
            }
            'Tab' {
                # Move to next/previous editable column
                if ($modifiers -band [ConsoleModifiers]::Shift) {
                    $this._MoveToPreviousEditableColumn()
                } else {
                    $this._MoveToNextEditableColumn()
                }
                return $true
            }
            'RightArrow' {
                $this._MoveToNextEditableColumn()
                return $true
            }
            'LeftArrow' {
                $this._MoveToPreviousEditableColumn()
                return $true
            }
            'DownArrow' {
                # Just move selection, don't start editing
                if ($this._selectedIndex -lt ($this._filteredData.Count - 1)) {
                    $this._selectedIndex++
                }
                return $true
            }
            'UpArrow' {
                # Just move selection, don't start editing
                if ($this._selectedIndex -gt 0) {
                    $this._selectedIndex--
                }
                return $true
            }
            'Home' {
                if ($modifiers -band [ConsoleModifiers]::Control) {
                    # Ctrl+Home: Go to first row
                    $this.SetSelectedIndex(0)
                } else {
                    # Home: Go to first column
                    $this._activeColumnIndex = $this._GetFirstEditableColumnIndex()
                }
                return $true
            }
            'End' {
                if ($modifiers -band [ConsoleModifiers]::Control) {
                    # Ctrl+End: Go to last row
                    $items = $this.GetItems()
                    if ($null -ne $items -and $items.Count -gt 0) {
                        $this.SetSelectedIndex($items.Count - 1)
                    }
                } else {
                    # End: Go to last column
                    $this._activeColumnIndex = $this._GetLastEditableColumnIndex()
                }
                return $true
            }
            default {
                # Typing any character starts editing
                if ([char]::IsLetterOrDigit($key.KeyChar) -or [char]::IsPunctuation($key.KeyChar) -or [char]::IsSymbol($key.KeyChar)) {
                    if ($this.BeginEdit($null)) {
                        # Re-process key in edit mode
                        return $this._HandleEditKey($key)
                    }
                }
            }
        }

        return $false
    }

    # Handle keys when widget is active
    hidden [bool] _HandleWidgetKey([System.ConsoleKeyInfo]$key) {
        # TODO: Delegate to widget
        # For now, just close widget on Escape
        if ($key.Key -eq 'Escape') {
            $this._CloseWidget()
            return $true
        }

        return $false
    }

    # Move to next editable column (skip read-only)
    hidden [void] _MoveToNextEditableColumn() {
        if ($this._editableColumns.Count -eq 0) {
            return
        }

        $startIndex = $this._activeColumnIndex
        $attempts = 0
        $maxAttempts = $this._editableColumns.Count

        while ($attempts -lt $maxAttempts) {
            $this._activeColumnIndex = ($this._activeColumnIndex + 1) % $this._editableColumns.Count
            $columnName = $this._editableColumns[$this._activeColumnIndex]

            # Check if this column is editable and not read-only
            if ($this._IsColumnEditable($columnName)) {
                return
            }

            $attempts++
        }

        # No editable columns found, stay at current
        $this._activeColumnIndex = $startIndex
    }

    # Move to previous editable column (skip read-only)
    hidden [void] _MoveToPreviousEditableColumn() {
        if ($this._editableColumns.Count -eq 0) {
            return
        }

        $startIndex = $this._activeColumnIndex
        $attempts = 0
        $maxAttempts = $this._editableColumns.Count

        while ($attempts -lt $maxAttempts) {
            $this._activeColumnIndex--
            if ($this._activeColumnIndex -lt 0) {
                $this._activeColumnIndex = $this._editableColumns.Count - 1
            }

            $columnName = $this._editableColumns[$this._activeColumnIndex]

            # Check if this column is editable and not read-only
            if ($this._IsColumnEditable($columnName)) {
                return
            }

            $attempts++
        }

        # No editable columns found, stay at current
        $this._activeColumnIndex = $startIndex
    }

    # Get first editable column index
    hidden [int] _GetFirstEditableColumnIndex() {
        for ($i = 0; $i -lt $this._editableColumns.Count; $i++) {
            $columnName = $this._editableColumns[$i]
            if ($this._IsColumnEditable($columnName)) {
                return $i
            }
        }
        return 0
    }

    # Get last editable column index
    hidden [int] _GetLastEditableColumnIndex() {
        for ($i = $this._editableColumns.Count - 1; $i -ge 0; $i--) {
            $columnName = $this._editableColumns[$i]
            if ($this._IsColumnEditable($columnName)) {
                return $i
            }
        }
        return $this._editableColumns.Count - 1
    }

    # Check if column is editable (not read-only)
    hidden [bool] _IsColumnEditable([string]$columnName) {
        if (-not $this._columnMetadata.ContainsKey($columnName)) {
            return $true  # No metadata = assume editable
        }

        $metadata = $this._columnMetadata[$columnName]
        return $metadata.Editable -and -not $metadata.ReadOnly
    }

    # Close active widget
    hidden [void] _CloseWidget() {
        $this._activeWidget = $null
        $this._activeWidgetType = ""
    }

    # Undo last change
    [bool] Undo() {
        if (-not $this.EnableUndo -or -not $this.ChangeTracker.CanUndo()) {
            return $false
        }

        $change = $this.ChangeTracker.Undo()
        if ($null -eq $change) {
            return $false
        }

        # Apply inverse change to cell
        $cell = $this._GetOrCreateCell($change.RowId, $change.ColumnName)
        $cell.SetEditValue($change.NewValue)
        $cell.CommitEdit()

        # Update data source
        $this._UpdateDataSource($cell)

        return $true
    }

    # Redo last undone change
    [bool] Redo() {
        if (-not $this.EnableUndo -or -not $this.ChangeTracker.CanRedo()) {
            return $false
        }

        $change = $this.ChangeTracker.Redo()
        if ($null -eq $change) {
            return $false
        }

        # Apply change to cell
        $cell = $this._GetOrCreateCell($change.RowId, $change.ColumnName)
        $cell.SetEditValue($change.NewValue)
        $cell.CommitEdit()

        # Update data source
        $this._UpdateDataSource($cell)

        return $true
    }

    # Check if grid has unsaved changes
    [bool] HasUnsavedChanges() {
        foreach ($cell in $this._cells.Values) {
            if ($cell.IsDirty) {
                return $true
            }
        }
        return $false
    }

    # Get all dirty cells
    [GridCell[]] GetDirtyCells() {
        $dirtyCells = @()
        foreach ($cell in $this._cells.Values) {
            if ($cell.IsDirty) {
                $dirtyCells += $cell
            }
        }
        return $dirtyCells
    }

    # Calculate screen position for a cell
    hidden [hashtable] _CalculateCellScreenPosition([int]$rowIndex, [int]$columnIndex) {
        # This is a placeholder implementation
        # Real implementation would need to account for:
        # - Content rect from LayoutManager
        # - Scroll offset
        # - Header height
        # - Column widths and positions

        # Return null for now - will be implemented when integrating with screen
        return $null
    }

    # Render grid (override from UniversalList)
    [string] Render([int]$width, [int]$height) {
        Write-PmcTuiLog "EditableGrid.Render: ENTRY (width=$width, height=$height)" "DEBUG"
        Write-PmcTuiLog "EditableGrid.Render: CellRenderer null? $($null -eq $this.CellRenderer)" "DEBUG"
        Write-PmcTuiLog "EditableGrid.Render: _filteredData count=$($this._filteredData.Count)" "DEBUG"
        Write-PmcTuiLog "EditableGrid.Render: _columns count=$($this._columns.Count)" "DEBUG"

        # Ensure renderer is initialized
        if ($null -eq $this.CellRenderer) {
            Write-PmcTuiLog "EditableGrid.Render: Using fallback to UniversalList._RenderList()" "DEBUG"
            try {
                Write-PmcTuiLog "EditableGrid.Render: Calling _RenderList..." "DEBUG"
                $result = $this._RenderList()
                Write-PmcTuiLog "EditableGrid.Render: _RenderList returned, length=$($result.Length)" "DEBUG"
                return $result
            } catch {
                Write-PmcTuiLog "EditableGrid.Render: ERROR in fallback: $_" "ERROR"
                return "ERROR: $_"
            }
        }

        Write-PmcTuiLog "EditableGrid.Render: About to call _RenderList (non-fallback path)" "DEBUG"
        try {
            $output = $this._RenderList()
            Write-PmcTuiLog "EditableGrid.Render: _RenderList returned, length=$($output.Length)" "DEBUG"
        } catch {
            Write-PmcTuiLog "EditableGrid.Render: ERROR calling _RenderList: $_" "ERROR"
            return "ERROR: $_"
        }

        # Add cursor positioning if editing
        Write-PmcTuiLog "EditableGrid.Render: Checking if need to add cursor positioning" "DEBUG"
        if ($null -ne $this._activeCell -and $this._activeCell.IsEditing) {
            Write-PmcTuiLog "EditableGrid.Render: Active cell is editing, adding cursor" "DEBUG"
            $selectedIndex = $this.GetSelectedIndex()
            if ($selectedIndex -ge 0 -and $this._activeColumnIndex -ge 0) {
                $cellPos = $this._CalculateCellScreenPosition($selectedIndex, $this._activeColumnIndex)
                if ($null -ne $cellPos) {
                    # Position cursor at cell
                    $cursorX = $cellPos.X + $this._activeCell.CursorPos
                    $cursorY = $cellPos.Y
                    $output += [PraxisVT]::MoveTo($cursorX, $cursorY)
                    $output += [PraxisVT]::ShowCursor()
                    Write-PmcTuiLog "EditableGrid.Render: Added cursor at ($cursorX, $cursorY)" "DEBUG"
                }
            }
        }

        Write-PmcTuiLog "EditableGrid.Render: COMPLETE, returning length=$($output.Length)" "DEBUG"
        return $output
    }

    # Move to next row, same column
    hidden [void] _MoveToNextRow() {
        $currentIdx = $this._selectedIndex
        $itemCount = $this._filteredData.Count

        if ($currentIdx -lt ($itemCount - 1)) {
            $this._selectedIndex = $currentIdx + 1
            $columnName = $this._editableColumns[$this._activeColumnIndex]
            $this.BeginEdit($columnName)
        }
    }

    # Move to previous row, same column
    hidden [void] _MoveToPreviousRow() {
        $currentIdx = $this._selectedIndex

        if ($currentIdx -gt 0) {
            $this._selectedIndex = $currentIdx - 1
            $columnName = $this._editableColumns[$this._activeColumnIndex]
            $this.BeginEdit($columnName)
        }
    }

    # Move to next editable column (Excel-style Tab navigation)
    hidden [void] _MoveToNextColumn() {
        if ($this._editableColumns.Count -eq 0) {
            return
        }

        # Move to next column
        $this._activeColumnIndex++

        # Wrap to first column if at end of columns (CYCLE on same row)
        if ($this._activeColumnIndex -ge $this._editableColumns.Count) {
            $this._activeColumnIndex = 0
        }

        # Begin editing the new cell
        $columnName = $this._editableColumns[$this._activeColumnIndex]
        $this.BeginEdit($columnName)
    }

    # Move to previous editable column (Excel-style Shift+Tab navigation)
    hidden [void] _MoveToPreviousColumn() {
        if ($this._editableColumns.Count -eq 0) {
            return
        }

        # Move to previous column
        $this._activeColumnIndex--

        # Wrap to last column if at beginning of columns (CYCLE on same row)
        if ($this._activeColumnIndex -lt 0) {
            $this._activeColumnIndex = $this._editableColumns.Count - 1
        }

        # Begin editing the new cell
        $columnName = $this._editableColumns[$this._activeColumnIndex]
        $this.BeginEdit($columnName)
    }
}
