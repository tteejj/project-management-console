# UniversalList.ps1 - Generic list widget with columns, sorting, filtering, and inline editing
# THE BIG ONE - Replaces 12+ specialized list screens!
#
#
# Usage:
#   $columns = @(
#       @{ Name='id'; Label='ID'; Width=4; Align='right' }
#       @{ Name='priority'; Label='Pri'; Width=4; Align='center'; Format={ "[P$_]" }}
#       @{ Name='text'; Label='Task'; Width=40; Align='left' }
#       @{ Name='due'; Label='Due'; Width=12; Format={ $_.ToString('MMM dd yyyy') }}
#       @{ Name='project'; Label='Project'; Width=15 }
#   )
#
#   $list = [UniversalList]::new()
#   $list.SetColumns($columns)
#   $list.SetData($tasks)
#   $list.SetPosition(0, 3)
#   $list.SetSize(120, 35)
#
#   # Events
#   $list.OnSelectionChanged = { param($item) Write-Host "Selected: $($item.text)" }
#   $list.OnItemEdit = { param($item) $this.ShowInlineEditor($item) }
#   $list.OnItemDelete = { param($item) Remove-PmcTask $item.id }
#
#   # Actions (shown in footer)
#   $list.AddAction('a', 'Add', { $this.ShowInlineEditor(@{}) })
#   $list.AddAction('e', 'Edit', { $this.ShowInlineEditor($this.SelectedItem) })
#   $list.AddAction('d', 'Delete', { $this.DeleteSelectedItem() })

using namespace System
using namespace System.Collections.Generic
using namespace System.Text

Set-StrictMode -Version Latest

# Load PmcWidget base class
if (-not ([System.Management.Automation.PSTypeName]'PmcWidget').Type) {
    . "$PSScriptRoot/PmcWidget.ps1"
}

# NOTE: InlineEditor and FilterPanel are now loaded by the launcher script.
# Commenting out to avoid circular dependency issues.
# . "$PSScriptRoot/InlineEditor.ps1"
# . "$PSScriptRoot/FilterPanel.ps1"

<#
.SYNOPSIS
Universal list widget with columns, sorting, filtering, inline editing

.DESCRIPTION
Features:
- Column configuration with width, alignment, formatting
- Data binding to array of objects
- Sorting by column (click header or hotkey)
- Filtering with FilterPanel integration
- Selection with arrow keys, Home/End, PageUp/Down
- Multi-select mode (Space to toggle)
- Inline editing with InlineEditor integration
- Configurable actions (Add, Edit, Delete, etc.)
- Virtual scrolling for large datasets (handles 1000+ items)
- Differential rendering for performance
- Search mode (/ key to filter by text)
- Column resizing (future enhancement)

.EXAMPLE
$list = [UniversalList]::new()
$columns = @(
    @{ Name='id'; Label='ID'; Width=4 }
    @{ Name='text'; Label='Task'; Width=40 }
)
$list.SetColumns($columns)
$list.SetData($tasks)
#>

<#
.SYNOPSIS
Cell information passed to Format callbacks

.DESCRIPTION
Provides context about a cell during rendering:
- Column metadata (name, width, alignment)
- Screen position (X, Y coordinates)
- Edit state (is this cell focused for editing?)
- Row state (is the row being edited?)

This allows Format callbacks to make rendering decisions based on
cell state without needing to check global variables.

.EXAMPLE
Format = { param($item, $cellInfo)
    if ($cellInfo.IsFocused) {
        return "$orangeColor$($cellInfo.Value)"
    }
    return $cellInfo.Value
}
#>
class CellInfo {
    [string]$ColumnName        # Column identifier
    [object]$Value             # Raw cell value (from item data)
    [int]$X                    # Screen X position
    [int]$Y                    # Screen Y position
    [int]$Width                # Allocated width for this cell
    [string]$Align             # Alignment: 'left', 'center', 'right'
    [bool]$IsFocused           # Is this cell currently focused in edit mode?
    [bool]$IsInEditMode        # Is the parent row in edit mode?
    [bool]$IsSelected          # Is the parent row selected?
    [int]$RowIndex             # Row index in the list
    [int]$ColumnIndex          # Column index in the row

    CellInfo(
        [string]$columnName,
        [object]$value,
        [int]$x,
        [int]$y,
        [int]$width,
        [string]$align,
        [bool]$isFocused,
        [bool]$isInEditMode,
        [bool]$isSelected,
        [int]$rowIndex,
        [int]$columnIndex
    ) {
        $this.ColumnName = $columnName
        $this.Value = $value
        $this.X = $x
        $this.Y = $y
        $this.Width = $width
        $this.Align = $align
        $this.IsFocused = $isFocused
        $this.IsInEditMode = $isInEditMode
        $this.IsSelected = $isSelected
        $this.RowIndex = $rowIndex
        $this.ColumnIndex = $columnIndex
    }
}

class UniversalList : PmcWidget {
    # === Public Properties ===
    [string]$Title = "List"                    # List title
    [bool]$AllowMultiSelect = $true            # Allow multi-select mode
    [bool]$AllowInlineEdit = $true             # Allow inline editing
    [bool]$AllowSearch = $true                 # Allow search mode
    [bool]$ShowLineNumbers = $false            # Show line numbers in first column
    [int]$ItemsPerPage = 10                    # Items per page (for PageUp/Down)

    # === Event Callbacks ===
    [scriptblock]$OnSelectionChanged = {}      # Called when selection changes: param($item)
    [scriptblock]$OnItemEdit = {}              # Called when item edited: param($item)
    [scriptblock]$OnItemDelete = {}            # Called when item deleted: param($item)
    [scriptblock]$OnItemActivated = {}         # Called when item activated (Enter): param($item)
    [scriptblock]$OnMultiSelectChanged = {}    # Called when multi-select changes: param($selectedItems)
    [scriptblock]$OnDataChanged = {}           # Called when data changes: param($newData)

    # === Edit Mode Callbacks (for CellInfo) ===
    # Parent screen sets these to provide edit state info to Format callbacks via CellInfo
    [scriptblock]$GetIsInEditMode = {}         # Returns true if row is in edit mode: param($item)
    [scriptblock]$GetFocusedColumnIndex = {}   # Returns focused column index: param($item) -> int (-1 if not focused)
    [scriptblock]$GetEditValue = {}            # Returns edit value for cell: param($item, $columnName) -> value or null

    # === State Flags ===
    [bool]$IsInMultiSelectMode = $false        # True when in multi-select mode
    [bool]$IsInSearchMode = $false             # True when in search mode
    [bool]$IsInFilterMode = $false             # True when filter panel shown

    # === Private State ===
    hidden [List[hashtable]]$_columns = [List[hashtable]]::new()         # Column definitions
    hidden [object[]]$_data = @()                                        # Original data array
    hidden [object[]]$_filteredData = @()                                # Filtered/sorted data
    hidden [int]$_selectedIndex = 0                                      # Selected item index
    hidden [HashSet[int]]$_selectedIndices = [HashSet[int]]::new()       # Multi-select indices
    hidden [int]$_scrollOffset = 0                                       # Virtual scroll offset
    hidden [string]$_sortColumn = ""                                     # Current sort column
    hidden [bool]$_sortAscending = $true                                 # Sort direction
    hidden [string]$_searchText = ""                                     # Search filter text
    hidden [hashtable]$_actions = @{}                                    # Registered actions (key -> scriptblock)
    hidden [object]$_filterPanel = $null                                 # Filter panel instance (FilterPanel)
    hidden [object]$_inlineEditor = $null                                # Inline editor instance (InlineEditor)
    hidden [bool]$_showInlineEditor = $false                             # Show inline editor overlay
    hidden [string]$_lastRenderedContent = ""                            # Last rendered content (for diff)
    # L-POL-22: Column width adjustment
    hidden [hashtable]$_columnWidths = @{}                               # Custom column widths (overrides defaults)

    # Reset column widths to defaults
    [void] ResetColumnWidths() {
        $this._columnWidths.Clear()
        $this._cacheGeneration++
        $this._rowCache.Clear()
        $this._cacheAccessOrder.Clear()
    }
    hidden [int]$_selectedColumnIndex = -1                               # Currently selected column for width adjustment

    # === Row-Level Caching for Performance ===
    hidden [hashtable]$_rowCache = @{}                                   # Cache of rendered rows by index
    hidden [int]$_cacheGeneration = 0                                    # Increment to invalidate all cache
    # H-MEM-1: LRU cache management
    hidden [System.Collections.Generic.LinkedList[string]]$_cacheAccessOrder = [System.Collections.Generic.LinkedList[string]]::new()
    hidden [int]$_maxCacheSize = 500                                     # Maximum cache entries

    # === Constructor ===
    UniversalList() : base("UniversalList") {
        $this.Width = 120
        $this.Height = 35
        $this.CanFocus = $true

        # Initialize filter panel
        $this._filterPanel = [FilterPanel]::new()
        $this._filterPanel.SetPosition($this.X + 10, $this.Y + 5)
        $this._filterPanel.SetSize(60, 12)
        $self = $this
        $this._filterPanel.OnFiltersChanged = { param($filters)
            $self._ApplyFilters()
        }
    }

    # === Helper Methods ===

    <#
    .SYNOPSIS
    Get property value from item (handles both hashtable and PSCustomObject)

    .PARAMETER item
    The item (hashtable or PSCustomObject)

    .PARAMETER propertyName
    Property name to retrieve

    .OUTPUTS
    Property value or $null if not found
    #>
    hidden [object] _GetItemProperty([object]$item, [string]$propertyName) {
        if ($null -eq $item) { return $null }

        if ($item -is [hashtable]) {
            $hasKey = $item.ContainsKey($propertyName)
            # Write-PmcTuiLog "_GetItemProperty: hashtable propertyName='$propertyName' hasKey=$hasKey"
            if ($hasKey) {
                $value = $item[$propertyName]
                $typeStr = $(if ($null -ne $value) { $value.GetType().Name } else { 'NULL' })
                # Write-PmcTuiLog "_GetItemProperty: returning value='$value' (type=$typeStr)"
                return $value
            }
        } elseif ($item.PSObject.Properties[$propertyName]) {
            $value = $item.$propertyName
            # Write-PmcTuiLog "_GetItemProperty: PSObject propertyName='$propertyName' value='$value'"
            return $value
        }

        # Write-PmcTuiLog "_GetItemProperty: propertyName='$propertyName' NOT FOUND, returning null"
        return $null
    }

    <#
    .SYNOPSIS
    Check if item has property (handles both hashtable and PSCustomObject)
    #>
    hidden [bool] _HasItemProperty([object]$item, [string]$propertyName) {
        if ($null -eq $item) { return $false }

        if ($item -is [hashtable]) {
            return $item.ContainsKey($propertyName)
        } else {
            return $null -ne $item.PSObject.Properties[$propertyName]
        }
    }

    # === Public API Methods ===

    <#
    .SYNOPSIS
    Set column definitions

    .PARAMETER columns
    Array of column hashtables:
    - Name: Property name (required)
    - Label: Display label (required)
    - Width: Column width in characters (required)
    - Align: 'left', 'center', 'right' (optional, default 'left')
    - Format: Scriptblock to format value (optional)
    - Sortable: Whether column is sortable (optional, default $true)
    #>
    [void] SetColumns([hashtable[]]$columns) {
        $this._columns.Clear()

        # Force array type to prevent unwrapping
        $columnsArray = @($columns)

        if ($null -eq $columnsArray -or $columnsArray.Count -eq 0) {
            throw "At least one column is required"
        }

        foreach ($col in $columnsArray) {
            if (-not $col.ContainsKey('Name')) {
                throw "Column missing 'Name' property"
            }
            if (-not $col.ContainsKey('Label')) {
                throw "Column missing 'Label' property"
            }
            if (-not $col.ContainsKey('Width')) {
                throw "Column missing 'Width' property"
            }

            # Set defaults
            if (-not $col.ContainsKey('Align')) {
                $col.Align = 'left'
            }
            if (-not $col.ContainsKey('Sortable')) {
                $col.Sortable = $true
            }

            $this._columns.Add($col)
        }
    }

    <#
    .SYNOPSIS
    Set data array

    .PARAMETER data
    Array of objects to display
    #>
    [void] SetData([array]$data) {
        try {
            $dataTypeStr = $(if ($null -eq $data) { "NULL" } else { $data.GetType().FullName })
            Write-PmcTuiLog "UniversalList.SetData: START, data param type=$dataTypeStr"
        } catch {
            Write-PmcTuiLog "UniversalList.SetData: ERROR getting data type: $_" "ERROR"
        }
        try {
            Write-PmcTuiLog "UniversalList.SetData: About to assign _data"
            if ($null -ne $data) {
                $this._data = [object[]]@($data)
            } else {
                $this._data = [object[]]@()
            }
            Write-PmcTuiLog "UniversalList.SetData: _data assigned successfully"
            Write-PmcTuiLog "UniversalList.SetData: About to check _data type"
            $dataType = $this._data.GetType().FullName
            Write-PmcTuiLog "UniversalList.SetData: _data type=$dataType"
            Write-PmcTuiLog "UniversalList.SetData: About to access _data.Count"
            $dataCount = $this._data.Count
            Write-PmcTuiLog "UniversalList.SetData: _data.Count=$dataCount"
        } catch {
            Write-PmcTuiLog "UniversalList.SetData: ERROR in _data assignment: $_" "ERROR"
            Write-PmcTuiLog "UniversalList.SetData: Stack: $($_.ScriptStackTrace)" "ERROR"
            throw
        }
        $this._filteredData = [object[]]@($this._data)
        Write-PmcTuiLog "UniversalList.SetData: _filteredData assigned"
        $this._selectedIndex = 0
        $this._scrollOffset = 0
        Write-PmcTuiLog "UniversalList.SetData: About to clear _selectedIndices"
        $this._selectedIndices.Clear()
        Write-PmcTuiLog "UniversalList.SetData: _selectedIndices cleared"

        Write-PmcTuiLog "UniversalList.SetData: Received $($this._data.Count) items"
        if ($this._data.Count -gt 0) {
            $firstItem = $this._data[0]
            if ($null -ne $firstItem) {
                Write-PmcTuiLog "UniversalList.SetData: First item type=$($firstItem.GetType().Name) isHashtable=$($firstItem -is [hashtable])"
                if ($firstItem -is [hashtable]) {
                    Write-PmcTuiLog "UniversalList.SetData: First item keys: $($firstItem.Keys -join ', ')"
                }
            } else {
                Write-PmcTuiLog "UniversalList.SetData: First item is null"
            }
        }

        # Invalidate row cache when data changes
        Write-PmcTuiLog "UniversalList.SetData: Incrementing cache generation"
        $this._cacheGeneration++
        Write-PmcTuiLog "UniversalList.SetData: Clearing row cache"
        $this._rowCache.Clear()
        # H-MEM-1: Clear LRU access order as well
        Write-PmcTuiLog "UniversalList.SetData: Clearing cache access order"
        $this._cacheAccessOrder.Clear()

        # Apply any active filters/search
        Write-PmcTuiLog "UniversalList.SetData: Applying filters"
        $this._ApplyFilters()
        Write-PmcTuiLog "UniversalList.SetData: Applying search"
        $this._ApplySearch()

        Write-PmcTuiLog "UniversalList.SetData: Invoking OnDataChanged callback"
        $this._InvokeCallback($this.OnDataChanged, $this._data)
        Write-PmcTuiLog "UniversalList.SetData: COMPLETE"
    }

    <#
    .SYNOPSIS
    Get currently selected item

    .OUTPUTS
    Selected item object or $null if none selected
    #>
    [object] GetSelectedItem() {
        if ($this._filteredData.Count -eq 0) {
            return $null
        }

        if ($this._selectedIndex -ge 0 -and $this._selectedIndex -lt $this._filteredData.Count) {
            return $this._filteredData[$this._selectedIndex]
        }

        return $null
    }

    <#
    .SYNOPSIS
    Get currently selected index
    #>
    [int] GetSelectedIndex() {
        return $this._selectedIndex
    }

    <#
    .SYNOPSIS
    Set selected index
    #>
    [void] SelectIndex([int]$index) {
        if ($index -ge 0 -and $index -lt $this._filteredData.Count) {
            $this._selectedIndex = $index
            $this._AdjustScrollOffset()
            $this._TriggerSelectionChanged()
        }
    }

    <#
    .SYNOPSIS
    Get all selected items (multi-select mode)

    .OUTPUTS
    Array of selected items
    #>
    [array] GetSelectedItems() {
        $selected = @()

        foreach ($index in $this._selectedIndices) {
            if ($index -ge 0 -and $index -lt $this._filteredData.Count) {
                $selected += $this._filteredData[$index]
            }
        }

        return $selected
    }

    <#
    .SYNOPSIS
    Get the count of filtered items
    #>
    [int] GetItemCount() {
        return $this._filteredData.Count
    }

    <#
    .SYNOPSIS
    Invalidate the row rendering cache.
    Call this when external state that affects row rendering changes.
    #>
    [void] InvalidateCache() {
        $this._cacheGeneration++
        $this._rowCache.Clear()
        $this._cacheAccessOrder.Clear()
    }

    <#
    .SYNOPSIS
    Set sort column and direction

    .PARAMETER columnName
    Column name to sort by

    .PARAMETER ascending
    Sort ascending if $true, descending if $false
    #>
    [void] SetSortColumn([string]$columnName, [bool]$ascending) {
        $this._sortColumn = $columnName
        $this._sortAscending = $ascending
        $this._ApplySort()
    }

    <#
    .SYNOPSIS
    Add an action (hotkey + callback)

    .PARAMETER key
    Hotkey character

    .PARAMETER label
    Action label for display

    .PARAMETER callback
    Scriptblock to invoke when action triggered
    #>
    [void] AddAction([string]$key, [string]$label, [scriptblock]$callback) {
        $this._actions[$key] = @{
            Label = $label
            Callback = $callback
        }
    }

    <#
    .SYNOPSIS
    Remove an action

    .PARAMETER key
    Hotkey character
    #>
    [void] RemoveAction([string]$key) {
        $this._actions.Remove($key)
    }

    <#
    .SYNOPSIS
    Show inline editor for an item

    .PARAMETER item
    Item to edit (or empty hashtable for new item)

    .PARAMETER fieldDefinitions
    Field definitions for InlineEditor (optional, will infer from columns)
    #>
    [void] ShowInlineEditor([object]$item, [hashtable[]]$fieldDefinitions = $null) {
        if (-not $this.AllowInlineEdit) {
            return
        }

        # Create inline editor if not exists
        if ($null -eq $this._inlineEditor) {
            $this._inlineEditor = [InlineEditor]::new()
            $this._inlineEditor.SetPosition($this.X + 10, $this.Y + 5)
            $this._inlineEditor.SetSize(70, 25)
        }

        # Build field definitions from columns if not provided
        if ($null -eq $fieldDefinitions) {
            $fields = @()
            foreach ($col in $this._columns) {
                $field = @{
                    Name = $col.Name
                    Label = $col.Label
                    Type = 'text'  # Default to text, could be smarter
                    Value = $(if ($item.($col.Name)) { $item.($col.Name) } else { "" })
                }
                $fields += $field
            }
            $fieldDefinitions = $fields
        }

        $this._inlineEditor.SetFields($fieldDefinitions)
        $this._inlineEditor.IsConfirmed = $false
        $this._inlineEditor.IsCancelled = $false

        # Set callback for when editor confirms
        $this._inlineEditor.OnConfirmed = { param($values)
            # Update item with new values
            foreach ($key in $values.Keys) {
                $item.$key = $values[$key]
            }
            $this._InvokeCallback($this.OnItemEdit, $item)
            $this._showInlineEditor = $false
        }

        $this._inlineEditor.OnCancelled = {
            $this._showInlineEditor = $false
        }

        $this._showInlineEditor = $true
    }

    <#
    .SYNOPSIS
    Show filter panel
    #>
    [void] ShowFilterPanel() {
        $this.IsInFilterMode = $true
    }

    <#
    .SYNOPSIS
    Hide filter panel
    #>
    [void] HideFilterPanel() {
        $this.IsInFilterMode = $false
    }

    <#
    .SYNOPSIS
    Handle keyboard input

    .PARAMETER keyInfo
    ConsoleKeyInfo from [Console]::ReadKey($true)

    .OUTPUTS
    True if input was handled, False otherwise
    #>
    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        # DON'T handle inline editor input here - let StandardListScreen handle it
        # This prevents the list and screen from getting out of sync
        # if ($this._showInlineEditor) {
        #     $handled = $this._inlineEditor.HandleInput($keyInfo)
        #
        #     if ($this._inlineEditor.IsConfirmed -or $this._inlineEditor.IsCancelled) {
        #         $this._showInlineEditor = $false
        #     }
        #
        #     # If editor handled the key, we're done
        #     # Otherwise, fall through to allow parent/global handlers (e.g., Ctrl+Q)
        #     if ($handled) {
        #         return $true
        #     }
        #     # Don't return false here - let parent handlers have a chance
        # }

        # Route input to filter panel if shown
        if ($this.IsInFilterMode) {
            $handled = $this._filterPanel.HandleInput($keyInfo)

            # Esc closes filter panel
            if ($keyInfo.Key -eq 'Escape') {
                $this.IsInFilterMode = $false
                return $true
            }

            # If filter panel handled the key, we're done
            # Otherwise, fall through to allow parent/global handlers
            if ($handled) {
                return $true
            }
            # Don't return false here - let parent handlers have a chance
        }

        # Search mode input
        if ($this.IsInSearchMode) {
            $handled = $this._HandleSearchInput($keyInfo)
            # If search handled the key, we're done
            # Otherwise, fall through to allow parent/global handlers (e.g., Ctrl+Q)
            if ($handled) {
                return $true
            }
            # Don't return false here - let parent handlers have a chance
        }

        # Global shortcuts
        if ($keyInfo.Key -eq 'Enter') {
            # PERF FIX: Disabled - Add-Content -Path "$($env:TEMP)/pmc-flow-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') [UniversalList.HandleInput] ENTER pressed, _showInlineEditor=$($this._showInlineEditor)"
            # Don't activate item if inline editor is showing
            if ($this._showInlineEditor) {
                # PERF FIX: Disabled - Add-Content -Path "$($env:TEMP)/pmc-flow-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') [UniversalList.HandleInput] Editor showing, returning false to let parent handle"
                return $false  # Let parent handle it
            }
            # Activate selected item
            # PERF FIX: Disabled - Add-Content -Path "$($env:TEMP)/pmc-flow-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') [UniversalList.HandleInput] About to call GetSelectedItem, _selectedIndex=$($this._selectedIndex) _filteredData.Count=$($this._filteredData.Count)"
            try {
                $selectedItem = $this.GetSelectedItem()
                # PERF FIX: Disabled - Add-Content -Path "$($env:TEMP)/pmc-flow-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') [UniversalList.HandleInput] GetSelectedItem returned: $($selectedItem -ne $null) id=$($selectedItem.id)"
                if ($null -ne $selectedItem) {
                    # PERF FIX: Disabled - Add-Content -Path "$($env:TEMP)/pmc-flow-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') [UniversalList.HandleInput] Calling OnItemActivated callback"
                    $this._InvokeCallback($this.OnItemActivated, $selectedItem)
                    # PERF FIX: Disabled - Add-Content -Path "$($env:TEMP)/pmc-flow-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') [UniversalList.HandleInput] OnItemActivated callback completed"
                } else {
                    # PERF FIX: Disabled - Add-Content -Path "$($env:TEMP)/pmc-flow-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') [UniversalList.HandleInput] selectedItem is NULL - no item selected!"
                }
            } catch {
                # PERF FIX: Disabled - Add-Content -Path "$($env:TEMP)/pmc-flow-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') [UniversalList.HandleInput] ERROR in GetSelectedItem or callback: $($_.Exception.Message)"
            }
            return $true
        }

        # Navigation
        if ($keyInfo.Key -eq 'UpArrow') {
            $this._MoveSelectionUp(1)
            return $true
        }

        if ($keyInfo.Key -eq 'DownArrow') {
            $this._MoveSelectionDown(1)
            return $true
        }

        if ($keyInfo.Key -eq 'PageUp') {
            $this._MoveSelectionUp($this.ItemsPerPage)
            return $true
        }

        if ($keyInfo.Key -eq 'PageDown') {
            $this._MoveSelectionDown($this.ItemsPerPage)
            return $true
        }

        if ($keyInfo.Key -eq 'Home') {
            if ($this._filteredData.Count -eq 0) {
                $this._selectedIndex = -1
            } else {
                $this._selectedIndex = 0
            }
            $this._AdjustScrollOffset()
            $this._TriggerSelectionChanged()
            return $true
        }

        if ($keyInfo.Key -eq 'End') {
            if ($this._filteredData.Count -eq 0) {
                $this._selectedIndex = -1
            } else {
                $this._selectedIndex = $this._filteredData.Count - 1
            }
            $this._AdjustScrollOffset()
            $this._TriggerSelectionChanged()
            return $true
        }

        # Multi-select mode
        if ($keyInfo.Key -eq 'Spacebar' -and $this.AllowMultiSelect) {
            $this._ToggleMultiSelect()
            return $true
        }

        # Enter multi-select mode
        if ($keyInfo.Key -eq 'M' -and $this.AllowMultiSelect) {
            $this.IsInMultiSelectMode = -not $this.IsInMultiSelectMode
            if (-not $this.IsInMultiSelectMode) {
                $this._selectedIndices.Clear()
            }
            return $true
        }

        # /: Toggle sort (cycle through columns)
        if ($keyInfo.KeyChar -eq '/') {
            if ($this._columns.Count -gt 0) {
                # Find current sort column index
                $currentIdx = -1
                for ($i = 0; $i -lt $this._columns.Count; $i++) {
                    if ($this._columns[$i].Name -eq $this._sortColumn) {
                        $currentIdx = $i
                        break
                    }
                }

                # Move to next column (or reverse if same column)
                if ($currentIdx -eq -1) {
                    # No sort, start with first column
                    $this._sortColumn = $this._columns[0].Name
                    $this._sortAscending = $true
                } elseif ($this._sortAscending) {
                    # Same column, reverse to descending
                    $this._sortAscending = $false
                } else {
                    # Next column, ascending
                    $nextIdx = ($currentIdx + 1) % $this._columns.Count
                    $this._sortColumn = $this._columns[$nextIdx].Name
                    $this._sortAscending = $true
                }

                # Re-sort data
                $this._ApplySort()
                return $true
            }
        }

        # ?: Search mode (filter by text)
        if ($keyInfo.KeyChar -eq '?' -and $this.AllowSearch) {
            $this.IsInSearchMode = $true
            $this._searchText = ""
            return $true
        }

        # F: Filter mode
        if ($keyInfo.Key -eq 'F') {
            $this.ShowFilterPanel()
            return $true
        }

        # L-POL-22: Alt+Left/Right - adjust column width, Alt+0 - reset all widths
        if ($keyInfo.Modifiers -band [ConsoleModifiers]::Alt) {
            if ($keyInfo.Key -eq 'LeftArrow') {
                # Decrease width of current column
                if ($this._selectedColumnIndex -ge 0 -and $this._selectedColumnIndex -lt $this._columns.Count) {
                    $colName = $this._columns[$this._selectedColumnIndex].Name
                    $currentWidth = $(if ($this._columnWidths.ContainsKey($colName)) {
                        $this._columnWidths[$colName]
                    } else {
                        $this._columns[$this._selectedColumnIndex].Width
                    })
                    $this._columnWidths[$colName] = [Math]::Max(5, $currentWidth - 2)
                    # Invalidate row cache
                    $this._cacheGeneration++
                    $this._rowCache.Clear()
                    $this._cacheAccessOrder.Clear()
                }
                return $true
            }
            if ($keyInfo.Key -eq 'RightArrow') {
                # Increase width of current column
                if ($this._selectedColumnIndex -ge 0 -and $this._selectedColumnIndex -lt $this._columns.Count) {
                    $colName = $this._columns[$this._selectedColumnIndex].Name
                    $currentWidth = $(if ($this._columnWidths.ContainsKey($colName)) {
                        $this._columnWidths[$colName]
                    } else {
                        $this._columns[$this._selectedColumnIndex].Width
                    })
                    $this._columnWidths[$colName] = [Math]::Min(100, $currentWidth + 2)
                    # Invalidate row cache
                    $this._cacheGeneration++
                    $this._rowCache.Clear()
                    $this._cacheAccessOrder.Clear()
                }
                return $true
            }
            if ($keyInfo.Key -eq 'D0' -or $keyInfo.KeyChar -eq '0') {
                # Reset all column widths to defaults
                $this.ResetColumnWidths()
                return $true
            }
        }

        # C key - cycle selected column for width adjustment
        if ($keyInfo.KeyChar -eq 'c' -or $keyInfo.KeyChar -eq 'C') {
            $this._selectedColumnIndex = ($this._selectedColumnIndex + 1) % $this._columns.Count
            return $true
        }

        # Action handling
        $keyChar = $keyInfo.KeyChar.ToString().ToLower()

        # DEBUG: Write directly to log file for troubleshooting
        $debugMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] UniversalList HandleInput: char='$keyChar' Key=$($keyInfo.Key) Actions=$($this._actions.Keys -join ',')"
        # PERF: Disabled - if ($global:PmcTuiLogFile) {
            # PERF FIX: Disabled - Add-Content -Path $global:PmcTuiLogFile -Value $debugMsg
        # }

        if ($this._actions.ContainsKey($keyChar)) {
            $action = $this._actions[$keyChar]
            $actionMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] UniversalList: Triggering action '$keyChar' - $($action.Label)"
            # PERF: Disabled - if ($global:PmcTuiLogFile) {
                # PERF FIX: Disabled - Add-Content -Path $global:PmcTuiLogFile -Value $actionMsg
            # }
            $this._InvokeCallback($action.Callback, $this)
            return $true
        }

        return $false
    }

    <#
    .SYNOPSIS
    Render the universal list

    .OUTPUTS
    ANSI string ready for display
    #>
    [string] Render() {
        # PERF FIX: Disabled - Add-Content -Path "$($env:TEMP)\pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') UniversalList.Render() CALLED"

        # If filter panel is shown, render it as overlay
        if ($this.IsInFilterMode) {
            # Render list first, then filter panel on top
            $listContent = $this._RenderList()
            $filterContent = $this._filterPanel.Render()
            return $listContent + "`n" + $filterContent
        }

        return $this._RenderList()
    }

    # PERFORMANCE: Direct engine rendering (bypasses ANSI string building/parsing)
    [void] OnRenderToEngine([object]$engine) {

        # If filter panel is shown, render list + filter panel
        if ($this.IsInFilterMode) {
            $this._RenderListDirect($engine)
            # Filter panel still uses string path
            $filterOutput = $this._filterPanel.Render()
            if ($filterOutput) {
                $this._ParseAnsiToEngine($engine, $filterOutput)
            }
            return
        }

        $this._RenderListDirect($engine)
    }

    # === Private Helper Methods ===

    <#
    .SYNOPSIS
    Render the main list
    #>
    hidden [string] _RenderList() {
        $sb = [StringBuilder]::new(8192)

        # Colors from new theme system
        $borderColor = $this.GetThemedFg('Border.Widget')
        $textColor = $this.GetThemedFg('Foreground.Row')
        $primaryColor = $this.GetThemedFg('Foreground.Title')
        $mutedColor = $this.GetThemedFg('Foreground.Muted')
        $successColor = $this.GetThemedFg('Foreground.Success')

        # Selected row colors
        $highlightBg = $this.GetThemedBg('Background.RowSelected', 1, 0)
        $highlightFg = $this.GetThemedFg('Foreground.RowSelected')

        # CRITICAL FIX: Fallback if theme returns empty
        if ([string]::IsNullOrWhiteSpace($highlightBg)) {
            $highlightBg = "`e[48;2;64;94;117m"  # Fallback blue background
        }
        if ([string]::IsNullOrWhiteSpace($highlightFg)) {
            $highlightFg = "`e[38;2;255;255;255m"  # Fallback white foreground
        }

        $reset = "`e[0m"

        # Draw top border
        $sb.Append($this.BuildMoveTo($this.X, $this.Y))
        $sb.Append($borderColor)
        $sb.Append($this.BuildBoxBorder($this.Width, 'top', 'single'))

        # Title
        $titleText = " $($this.Title) "
        $titlePos = 2
        $sb.Append($this.BuildMoveTo($this.X + $titlePos, $this.Y))
        $sb.Append($primaryColor)
        $sb.Append($titleText)

        # Item count
        $countText = "($($this._filteredData.Count) items)"
        $sb.Append($this.BuildMoveTo($this.X + $this.Width - $countText.Length - 2, $this.Y))
        $sb.Append($mutedColor)
        $sb.Append($countText)

        $currentRow = 1

        # Column headers
        $headerY = $this.Y + $currentRow
        $sb.Append($this.BuildMoveTo($this.X, $headerY))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))

        $sb.Append($this.BuildMoveTo($this.X + 2, $headerY))
        $sb.Append($primaryColor)

        $currentX = 2
        # L-POL-4: Detect Unicode support for sort indicators
        $supportsUnicode = $env:LANG -match 'UTF-8' -or [Console]::OutputEncoding.EncodingName -match 'UTF'
        $sortUpSymbol = $(if ($supportsUnicode) { "↑" } else { "^" })
        $sortDownSymbol = $(if ($supportsUnicode) { "↓" } else { "v" })

        foreach ($col in $this._columns) {
            $label = $col.Label
            # L-POL-22: Use custom width if set, otherwise use default
            $width = $(if ($this._columnWidths.ContainsKey($col.Name)) {
                $this._columnWidths[$col.Name]
            } else {
                $col.Width
            })

            # Add sort indicator with fallback
            if ($this._sortColumn -eq $col.Name) {
                $sortIndicator = $(if ($this._sortAscending) { " $sortUpSymbol" } else { " $sortDownSymbol" })
                $label += $sortIndicator
            }

            # Use EXACT SAME logic as data rows
            $targetWidth = $width + 2
            $truncated = $this.TruncateText($label, $targetWidth)
            $padded = $this.PadText($truncated, $targetWidth, $col.Align)
            $sb.Append($padded)
            $sb.Append("    ")
            $currentX += $width + 6
        }

        $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $headerY))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))

        $currentRow++

        # Separator row
        $sepY = $this.Y + $currentRow
        $sb.Append($this.BuildMoveTo($this.X, $sepY))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))
        $sb.Append($this.BuildHorizontalLine($this.Width - 2, 'single'))
        $sb.Append($this.GetBoxChar('single_vertical'))

        $currentRow++

        # Data rows (virtual scrolling)
        $maxVisibleRows = $this.Height - 6  # Top, header, sep, bottom, footer, status
        $visibleStartIndex = $this._scrollOffset

        # Get count safely - handle both arrays and single items
        $filteredCount = $(if ($null -eq $this._filteredData) {
            0
        } elseif ($this._filteredData -is [array]) {
            $this._filteredData.Count
        } else {
            1
        })

        $visibleEndIndex = [Math]::Min($this._scrollOffset + $maxVisibleRows, $filteredCount)

        # DEBUG: Log list state with type checking
        # if ($global:PmcTuiLogFile) {
        #     $dataCount = $(if ($null -eq $this._data) { "NULL" } elseif ($this._data -is [array]) { $this._data.Count } else { "NOT_ARRAY:$($this._data.GetType().Name)" })
        #     $filteredCount = $(if ($null -eq $this._filteredData) { "NULL" } elseif ($this._filteredData -is [array]) { $this._filteredData.Count } else { "NOT_ARRAY:$($this._filteredData.GetType().Name)" })
        #     # PERF FIX: Disabled - Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] UniversalList._RenderList: _data=$dataCount _filteredData=$filteredCount maxVisible=$maxVisibleRows visibleStart=$visibleStartIndex visibleEnd=$visibleEndIndex"
        # }

        for ($i = $visibleStartIndex; $i -lt $visibleEndIndex; $i++) {
            # Handle both array and scalar _filteredData
            $item = $(if ($this._filteredData -is [array]) {
                $this._filteredData[$i]
            } else {
                $this._filteredData
            })

            $rowY = $this.Y + $currentRow
            $isSelected = ($i -eq $this._selectedIndex)
            $isMultiSelected = $this._selectedIndices.Contains($i)

            # CRITICAL FIX: Check skipRowHighlight BEFORE cache to determine if row should be rendered
            $skipRowHighlight = $false
            # Write-PmcTuiLog "UniversalList: Checking SkipRowHighlight for row $i"
            if ($this._columns[0].ContainsKey('SkipRowHighlight') -and $null -ne $this._columns[0].SkipRowHighlight) {
                try {
                    $skipRowHighlight = & $this._columns[0].SkipRowHighlight $item
                } catch {
                    # Write-PmcTuiLog "UniversalList: SkipRowHighlight callback ERROR: $($_.Exception.Message)" "ERROR"
                    $skipRowHighlight = $false
                }
            }

            # Check if row is in edit mode - if so, SKIP CACHE
            $rowInEditMode = $false
            if ($null -ne $this.GetIsInEditMode -and $this.GetIsInEditMode -is [scriptblock]) {
                try {
                    $result = & $this.GetIsInEditMode $item
                    $rowInEditMode = $(if ($result) { $true } else { $false })
                } catch {
                    $rowInEditMode = $false
                }
            }

            # CRITICAL FIX: ROW CACHE RE-ENABLED
            # Cache was storing ANSI escape codes that bleed to subsequent rows
            # Fixed by ensuring every row ends with reset and clear-to-eol codes
            $cacheKey = "$($this._cacheGeneration)_${i}_${isSelected}_${isMultiSelected}"
            $cachedRow = $null
            
            if (-not $rowInEditMode -and -not $skipRowHighlight -and $this._rowCache.ContainsKey($cacheKey)) {
                $cachedRow = $this._rowCache[$cacheKey]
                
                # Update LRU order
                $this._cacheAccessOrder.Remove($cacheKey)
                [void]$this._cacheAccessOrder.AddLast($cacheKey)
                
                $sb.Append($cachedRow)
                $currentRow++
                continue
            }

            # Build row content (not in cache)
            $rowBuilder = [Text.StringBuilder]::new(256)

            # Clear the line first to prevent any bleeding
            $rowBuilder.Append($this.BuildMoveTo($this.X, $rowY))
            $rowBuilder.Append("`e[0m`e[K")  # Reset and clear to end of line

            # Row border
            $rowBuilder.Append($this.BuildMoveTo($this.X, $rowY))
            $rowBuilder.Append($borderColor)
            $rowBuilder.Append($this.GetBoxChar('single_vertical'))

            # Row content
            $rowBuilder.Append($this.BuildMoveTo($this.X + 2, $rowY))

            # Highlight selected row (unless skipped OR in edit mode)
            # Write-PmcTuiLog "UniversalList: skipRowHighlight=$skipRowHighlight rowInEditMode=$rowInEditMode isSelected=$isSelected"
            if (-not $skipRowHighlight -and -not $rowInEditMode) {
                if ($isSelected) {
                    # Write-PmcTuiLog "UniversalList: APPLYING ROW HIGHLIGHT"
                    $rowBuilder.Append($highlightBg)
                    $rowBuilder.Append($highlightFg)  # Use Selected Fg (white) for contrast
                } elseif ($isMultiSelected) {
                    $rowBuilder.Append($successColor)
                } else {
                    $rowBuilder.Append($textColor)
                }
            } else {
                # When skipping row highlight (edit mode) - use theme colors
                # Write-PmcTuiLog "UniversalList: SKIPPING ROW HIGHLIGHT - using edit mode colors"
                $rowBuilder.Append($textColor)
            }

            # Render columns (CRITICAL: Each column must handle its own colors)
            $currentX = 2
            $columnIndex = 0
            foreach ($col in $this._columns) {
                # CRITICAL FIX: Reset colors at start of EACH column to prevent bleeding
                if ($columnIndex -eq 0) {
                    # First column keeps the row highlight (already applied above)
                } else {
                    # Subsequent columns: reset then reapply row color
                    $rowBuilder.Append($reset)
                    if ($isSelected -and -not $skipRowHighlight -and -not $rowInEditMode) {
                        $rowBuilder.Append($highlightBg)
                        $rowBuilder.Append($highlightFg)
                    } elseif (-not $skipRowHighlight -and -not $rowInEditMode) {
                        $rowBuilder.Append($textColor)
                    }
                }
                # L-POL-22: Use custom width if set, otherwise use default
                $width = $(if ($this._columnWidths.ContainsKey($col.Name)) {
                })
                # L-POL-22: Use custom width if set, otherwise use default
                $width = $(if ($this._columnWidths.ContainsKey($col.Name)) {
                    $this._columnWidths[$col.Name]
                } else {
                    $col.Width
                })
                # Write-PmcTuiLog "UniversalList._RenderList: row=$i col=$($col.Name) WIDTH=$width"

                # SKIP columns with width=0 (hidden columns)
                if ($width -eq 0) {
                    $columnIndex++
                    continue
                }

                # Get value - check if cell is being edited first
                $value = $null
                $hasEditValue = $false
                # Write-PmcTuiLog "UniversalList._RenderList: row=$i col=$columnIndex ($($col.Name)) CHECKING GetEditValue callback"
                if ($null -ne $this.GetEditValue) {
                    try {
                        $editValueRaw = & $this.GetEditValue $item $col.Name

                        # Unwrap array (callback uses comma operator to preserve empty strings)
                        $editValue = $(if ($editValueRaw -is [array] -and $editValueRaw.Count -eq 1) {
                            $editValueRaw[0]
                        } elseif ($editValueRaw -is [array] -and $editValueRaw.Count -eq 0) {
                            $null
                        } else {
                            $editValueRaw
                        })

                        # Use edit value if NOT null (empty string is valid!)
                        # The callback returns $null for non-edited cells, and a string (even "") for edited cells
                        if ($null -ne $editValue) {
                            $value = $editValue
                            $hasEditValue = $true
                        }
                    } catch {
                        # Ignore - fall through to normal value
                    }
                }

                # If not editing, get normal value - handle both hashtables and PSObjects
                if (-not $hasEditValue) {
                    $value = $this._GetItemProperty($item, $col.Name)
                    if ($null -eq $value) { $value = "" }
                }

                # Determine edit state for this cell
                $isInEditMode = $false
                $focusedColumnIdx = -1
                # DEBUG: Check callback state BEFORE null check
                if ($null -ne $this.GetIsInEditMode -and $this.GetIsInEditMode -is [scriptblock]) {
                    try {
                        $result = & $this.GetIsInEditMode $item
                        # Ensure boolean - PowerShell can return weird types
                        $isInEditMode = $(if ($result) { $true } else { $false })
                    } catch {
                        $isInEditMode = $false
                    }
                }

                if ($isInEditMode -and $null -ne $this.GetFocusedColumnIndex -and $this.GetFocusedColumnIndex -is [scriptblock]) {
                    try {
                        $focusedColumnIdx = & $this.GetFocusedColumnIndex $item
                        # Ensure int
                        if ($null -eq $focusedColumnIdx) { $focusedColumnIdx = -1 }
                    } catch {
                        $focusedColumnIdx = -1
                    }
                }

                # Ensure boolean
                $isFocused = $(if ($isInEditMode -and $focusedColumnIdx -eq $columnIndex) { $true } else { $false })

                # Create CellInfo for this cell
                try {
                    $cellInfo = [CellInfo]::new(
                        $col.Name,           # columnName
                        $value,              # value
                        $currentX,           # x
                        $rowY,               # y
                        $width,              # width
                        $col.Align,          # align
                        $isFocused,          # isFocused
                        $isInEditMode,       # isInEditMode
                        $isSelected,         # isSelected
                        $i,                  # rowIndex
                        $columnIndex         # columnIndex
                    )
                } catch {
                    throw
                }

                # Format value if formatter provided
                if ($col.ContainsKey('Format') -and $null -ne $col.Format) {
                    try {
                        # Pass the WHOLE ITEM + CellInfo to formatter
                        $value = & $col.Format $item $cellInfo
                    } catch {
                        # HIGH FIX #7: Log error but return original value for graceful degradation
                        if (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue) {
                            Write-PmcTuiLog "Column format error for '$($col.Name)': $($_.Exception.Message)" "ERROR"
                        }
                        # Return original unformatted value instead of error text - use safe property access
                        $value = $this._GetItemProperty($item, $col.Name)
                        if ($null -eq $value) { $value = "" }
                    }
                }

                $columnIndex++

                # Convert to string - handle arrays and other types safely
                # Convert to string - handle arrays and other types safely
                try {
                    $valueStr = $(if ($null -ne $value) {
                        if ($value -is [array]) {
                            ($value -join ', ')
                        } else {
                            $value.ToString()
                        }
                    } else { "" })
                } catch {
                    $valueStr = ""
                }

                # L-POL-16: Highlight search matches if in search mode
                if ($this.IsInSearchMode -and -not [string]::IsNullOrWhiteSpace($this._searchText)) {
                    $searchLower = $this._searchText.ToLower()
                    $valueLower = $valueStr.ToLower()
                    # Use theme Warning color for search highlight
                    $highlightColor = $this.GetThemedBg('Background.Warning', 1, 0) + $textColor
                    $resetHighlight = $(if ($isSelected) { $highlightBg + $highlightFg } else { $textColor })

                    # Find all occurrences and highlight them
                    $highlightedValue = ""
                    $lastIndex = 0
                    $index = $valueLower.IndexOf($searchLower, $lastIndex)

                    while ($index -ge 0) {
                        # Add text before match
                        $highlightedValue += $valueStr.Substring($lastIndex, $index - $lastIndex)
                        # Add highlighted match
                        $highlightedValue += $highlightColor + $valueStr.Substring($index, $this._searchText.Length) + $resetHighlight
                        $lastIndex = $index + $this._searchText.Length
                        $index = $valueLower.IndexOf($searchLower, $lastIndex)
                    }

                    # Add remaining text
                    if ($lastIndex -lt $valueStr.Length) {
                        $highlightedValue += $valueStr.Substring($lastIndex)
                    }

                    $valueStr = $highlightedValue
                }

                # In edit mode, Format callbacks include background colors
                # DON'T pad or truncate - they handle their own formatting
                if ($skipRowHighlight) {
                    # Use value exactly as Format callback returned it
                    try {
                        $rowBuilder.Append([string]$valueStr)
                    } catch {
                        throw
                    }
                    # Reset BEFORE padding to prevent color bleeding
                    $rowBuilder.Append($reset)
                    # Add fixed-width spacing to reach column width (now without background color)
                    $visibleLen = $this.GetVisibleLength($valueStr)
                    $targetWidth = $width + 2
                    if ($visibleLen -lt $targetWidth) {
                        $rowBuilder.Append(" " * ($targetWidth - $visibleLen))
                    }
                    # Separator spaces
                    $rowBuilder.Append("    ")
                } else {
                    # Normal mode - use padding
                    $valueStrLen = $(if ($null -ne $valueStr -and $valueStr -is [string]) { $valueStr.Length } else { 0 })
                    $targetWidth = $width + 2
                    $truncated = $this.TruncateText($valueStr, $targetWidth)
                    $truncLen = $(if ($null -ne $truncated -and $truncated -is [string]) { $truncated.Length } else { 0 })
                    $displayValue = $this.PadText($truncated, $targetWidth, $col.Align)
                    $dispLen = $(if ($null -ne $displayValue -and $displayValue -is [string]) { $displayValue.Length } else { 0 })
                    try {
                        $rowBuilder.Append([string]$displayValue)
                    } catch {
                        throw
                    }
                    $rowBuilder.Append("    ")
                }

                $currentX += $width + 6
            }

            # CRITICAL FIX: Always reset after row content to prevent color bleeding
            # Without this, unhighlighted rows don't clear the background color from previous frames
            # causing the "sticky highlight" bug
            $rowBuilder.Append($reset)

            # Padding to fill row - reset already applied above
            $contentWidth = $currentX - 2
            $padding = $this.Width - $contentWidth - 2
            if ($padding -gt 0) {
                # Reset already applied above (line 1284), padding inherits clean state
                $rowBuilder.Append(" " * $padding)
            }

            # Right border
            $rowBuilder.Append($this.BuildMoveTo($this.X + $this.Width - 1, $rowY))
            $rowBuilder.Append($borderColor)
            $rowBuilder.Append($this.GetBoxChar('single_vertical'))

            # CRITICAL FIX: Reset at END of row to prevent bleeding to next row
            $rowBuilder.Append($reset)
            # Clear to end of line to prevent any background color bleeding
            $rowBuilder.Append("`e[K")

            # CRITICAL FIX: ROW CACHE RE-ENABLED
            # The cache stores ANSI escape codes which bleed between rows
            # Fixed by ensuring every row ends with reset and clear-to-eol codes
            $builtRow = $rowBuilder.ToString()

            # Manage cache size (LRU)
            if ($this._rowCache.Count -ge $this._maxCacheSize) {
                $oldestKey = $this._cacheAccessOrder.First.Value
                $this._rowCache.Remove($oldestKey)
                $this._cacheAccessOrder.RemoveFirst()
            }
            
            $this._rowCache[$cacheKey] = $builtRow
            [void]$this._cacheAccessOrder.AddLast($cacheKey)

            # CRITICAL FIX: Skip rendering the row entirely when skipRowHighlight is true (inline editing mode)
            # The inline editor will render its own content at this row position
            if (-not $skipRowHighlight) {
                $sb.Append($builtRow)
            } else {
                # CRITICAL FIX: Clear the line BEFORE rendering inline editor to prevent highlight bleeding
                # Even though we skip the row content, we need to clear any previous highlighting
                # BUG FIX: Don't use `e[K` as it erases borders! Clear content area with spaces instead
                $sb.Append($this.BuildMoveTo($this.X, $rowY))
                $sb.Append($reset)
                # Render left border
                $sb.Append($borderColor + $this.GetBoxChar('single_vertical'))
                # Clear content area only (not borders)
                $sb.Append($reset)
                $sb.Append(" " * ($this.Width - 2))
                # Render right border
                $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $rowY))
                $sb.Append($borderColor + $this.GetBoxChar('single_vertical'))
                $sb.Append($reset)

                # Inline editor is active for this row - render the editor
                if ($this._showInlineEditor -and $this._inlineEditor) {
                    # Set editor position to this row (using properties, not method)
                    $this._inlineEditor.X = $this.X + 2
                    $this._inlineEditor.Y = $rowY
                    # Set editor width to fit within list borders
                    $this._inlineEditor.Width = $this.Width - 4
                    # Render the inline editor
                    $editorOutput = $this._inlineEditor.Render()
                    $sb.Append($editorOutput)

                    # BUG FIX: Account for expanded widget height in edit mode
                    # If a widget (DatePicker/ProjectPicker) is expanded, it renders below the editor row
                    # We need to skip past the widget's height to avoid overwriting it with subsequent rows
                    $editorHeight = 1  # Default: 1 row for collapsed editor
                    if ($this._inlineEditor._showFieldWidgets -and -not [string]::IsNullOrWhiteSpace($this._inlineEditor._expandedFieldName)) {
                        # Widget is expanded - add its height
                        $expandedFieldName = $this._inlineEditor._expandedFieldName
                        $widget = $null
                        if ($this._inlineEditor._datePickerMode -and $this._inlineEditor._datePickerWidgets.ContainsKey($expandedFieldName)) {
                            $widget = $this._inlineEditor._datePickerWidgets[$expandedFieldName]
                        } elseif ($this._inlineEditor._fieldWidgets.ContainsKey($expandedFieldName)) {
                            $widget = $this._inlineEditor._fieldWidgets[$expandedFieldName]
                        }
                        if ($widget -and $widget.PSObject.Properties['Height']) {
                            $editorHeight += $widget.Height
                        } else {
                            $editorHeight += 15  # Conservative estimate
                        }
                    }
                    # Increment currentRow by the full editor height (including expanded widget if any)
                    $currentRow += $editorHeight
                } else {
                    # No editor - render empty placeholder row
                    $emptyRow = $this.BuildMoveTo($this.X, $rowY)
                    $emptyRow += "`e[0m"  # Reset all formatting
                    $emptyRow += $borderColor + $this.GetBoxChar('single_vertical')
                    $emptyRow += " " * ($this.Width - 2)
                    $emptyRow += $borderColor + $this.GetBoxChar('single_vertical')
                    $emptyRow += "`e[0m"  # Final reset
                    $sb.Append($emptyRow)
                    $currentRow++
                }
            }

            # BUG FIX: Only increment currentRow for normal rows (not when editor was rendered)
            # When editor is rendered, currentRow was already incremented by editorHeight above
            if (-not $skipRowHighlight) {
                $currentRow++
            }
        }

        # If inline editor is shown and selectedIndex is beyond data (add mode), render editor row
        if ($this._showInlineEditor -and $this._inlineEditor -and $this._selectedIndex -ge $this._filteredData.Count) {
            $rowY = $this.Y + $currentRow
            $this._inlineEditor.X = $this.X + 2
            $this._inlineEditor.Y = $rowY
            $this._inlineEditor.Width = $this.Width - 4
            $editorOutput = $this._inlineEditor.Render()
            $sb.Append($editorOutput)

            # BUG FIX: Account for expanded widget height (e.g., DatePicker, ProjectPicker)
            # The InlineEditor can contain expanded widgets that take up 10-15 rows
            # We need to skip past the widget when filling empty rows to avoid overwriting it
            $editorHeight = 1  # Default: 1 row for collapsed editor
            if ($this._inlineEditor._showFieldWidgets -and -not [string]::IsNullOrWhiteSpace($this._inlineEditor._expandedFieldName)) {
                # Widget is expanded - add its height (typically 10-15 rows for DatePicker/ProjectPicker)
                # Get the actual widget height if available, otherwise use conservative estimate
                $expandedFieldName = $this._inlineEditor._expandedFieldName
                $widget = $null

                # Check which widget dictionary contains the expanded widget
                if ($this._inlineEditor._datePickerMode -and $this._inlineEditor._datePickerWidgets.ContainsKey($expandedFieldName)) {
                    $widget = $this._inlineEditor._datePickerWidgets[$expandedFieldName]
                } elseif ($this._inlineEditor._fieldWidgets.ContainsKey($expandedFieldName)) {
                    $widget = $this._inlineEditor._fieldWidgets[$expandedFieldName]
                }

                if ($widget -and $widget.PSObject.Properties['Height']) {
                    $editorHeight += $widget.Height
                } else {
                    # Conservative estimate: 15 rows for unknown widget height
                    $editorHeight += 15
                }
            }
            $currentRow += $editorHeight
        }

        # Fill empty rows
        for ($row = $currentRow; $row -lt ($this.Height - 3); $row++) {
            $rowY = $this.Y + $row
            $sb.Append($this.BuildMoveTo($this.X, $rowY))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))
            $sb.Append(" " * ($this.Width - 2))
            $sb.Append($this.GetBoxChar('single_vertical'))
        }

        # Status row
        $statusRowY = $this.Y + $this.Height - 3
        $sb.Append($this.BuildMoveTo($this.X, $statusRowY))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))

        $sb.Append($this.BuildMoveTo($this.X + 2, $statusRowY))

        if ($this.IsInSearchMode) {
            $sb.Append($primaryColor)
            # H-UI-7: Show search hint to explain what can be searched
            $sb.Append("Search (text, tags, project): $($this._searchText)_")
        } elseif ($this.IsInMultiSelectMode) {
            $sb.Append($successColor)
            $sb.Append("Multi-select mode ($($this._selectedIndices.Count) selected)")
        } else {
            $sb.Append($mutedColor)
            $selectedItem = $this.GetSelectedItem()
            if ($null -ne $selectedItem) {
                $preview = "Selected: "
                # Handle both hashtables and objects - items may have 'text' or 'name' property
                $text = $this._GetItemProperty($selectedItem, 'text')
                if (-not $text) { $text = $this._GetItemProperty($selectedItem, 'name') }
                $id = $this._GetItemProperty($selectedItem, 'id')

                if ($text) {
                    $preview += $text
                } elseif ($id) {
                    $preview += "ID $id"
                } else {
                    $preview += "(item)"
                }
                $sb.Append($this.TruncateText($preview, $this.Width - 4))
            } else {
                $sb.Append("No items")
            }
        }

        $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $statusRowY))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))

        # Actions row(s) - support multi-line if needed
        $actionsRowY = $this.Y + $this.Height - 2

        # Build actions string
        $actionsStr = ""
        foreach ($key in $this._actions.Keys) {
            $action = $this._actions[$key]
            if ($actionsStr.Length -gt 0) {
                $actionsStr += " | "
            }
            $actionsStr += "$($key.ToUpper())=$($action.Label)"
        }

        # PERF: Disabled - if ($global:PmcTuiLogFile) {
            # PERF FIX: Disabled - Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] UniversalList._RenderList: actionsStr='$actionsStr' (Keys=$($this._actions.Keys.Count))"
        # }

        if ($actionsStr.Length -eq 0) {
            $actionsStr = "↑/↓: Nav | Space: Select | /: Search | F: Filter | Enter: Open"
        }

        # L-POL-24: Split into multiple lines with overflow handling
        $maxWidth = $this.Width - 4
        $actionLines = @()
        $currentLine = ""

        foreach ($actionPair in ($actionsStr -split ' \| ')) {
            $testLine = $(if ($currentLine.Length -eq 0) { $actionPair } else { "$currentLine | $actionPair" })
            if ($testLine.Length -le $maxWidth) {
                $currentLine = $testLine
            } else {
                if ($currentLine.Length -gt 0) {
                    $actionLines += $currentLine
                }
                # L-POL-24: If action pair itself is too long, truncate it
                if ($actionPair.Length -gt $maxWidth) {
                    $currentLine = $actionPair.Substring(0, $maxWidth - 3) + "..."
                    $actionLines += $currentLine
                    $currentLine = ""
                } else {
                    $currentLine = $actionPair
                }
            }
        }
        if ($currentLine.Length -gt 0) {
            # L-POL-24: Truncate last line if it exceeds width
            if ($currentLine.Length -gt $maxWidth) {
                $currentLine = $currentLine.Substring(0, $maxWidth - 3) + "..."
            }
            $actionLines += $currentLine
        }

        # Render each action line (max 2 lines to not crowd the UI)
        $linesToRender = [Math]::Min($actionLines.Count, 2)
        for ($i = 0; $i -lt $linesToRender; $i++) {
            $lineY = $actionsRowY - ($linesToRender - 1 - $i)

            $sb.Append($this.BuildMoveTo($this.X, $lineY))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            $sb.Append($this.BuildMoveTo($this.X + 2, $lineY))
            $sb.Append($mutedColor)
            $sb.Append($this.TruncateText($actionLines[$i], $maxWidth))

            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $lineY))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))
        }

        # Bottom border
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + $this.Height - 1))
        $sb.Append($borderColor)
        $sb.Append($this.BuildBoxBorder($this.Width, 'bottom', 'single'))

        $sb.Append($reset)
        return $sb.ToString()
    }

    <#
    .SYNOPSIS
    Move selection up
    #>
    hidden [void] _MoveSelectionUp([int]$count = 1) {
        if ($this._filteredData.Count -eq 0) {
            $this._selectedIndex = -1
        } else {
            $this._selectedIndex = [Math]::Max(0, $this._selectedIndex - $count)
            $this._selectedIndex = [Math]::Min($this._selectedIndex, $this._filteredData.Count - 1)
        }
        $this._AdjustScrollOffset()
        $this._TriggerSelectionChanged()
    }

    <#
    .SYNOPSIS
    Move selection down
    #>
    hidden [void] _MoveSelectionDown([int]$count = 1) {
        if ($this._filteredData.Count -eq 0) {
            $this._selectedIndex = -1
        } else {
            $this._selectedIndex = [Math]::Min($this._filteredData.Count - 1, $this._selectedIndex + $count)
            $this._selectedIndex = [Math]::Max(0, $this._selectedIndex)
        }
        $this._AdjustScrollOffset()
        $this._TriggerSelectionChanged()
    }

    <#
    .SYNOPSIS
    Adjust scroll offset to keep selection visible
    #>
    hidden [void] _AdjustScrollOffset() {
        $maxVisibleRows = $this.Height - 6

        # If selected item is above visible area, scroll up
        if ($this._selectedIndex -lt $this._scrollOffset) {
            $this._scrollOffset = $this._selectedIndex
        }

        # If selected item is below visible area, scroll down
        if ($this._selectedIndex -ge ($this._scrollOffset + $maxVisibleRows)) {
            $this._scrollOffset = $this._selectedIndex - $maxVisibleRows + 1
        }

        # Clamp scroll offset
        if ($this._scrollOffset -lt 0) {
            $this._scrollOffset = 0
        }

        $maxScroll = [Math]::Max(0, $this._filteredData.Count - $maxVisibleRows)
        if ($this._scrollOffset -gt $maxScroll) {
            $this._scrollOffset = $maxScroll
        }
    }

    <#
    .SYNOPSIS
    Toggle multi-select for current item
    #>
    hidden [void] _ToggleMultiSelect() {
        # Don't toggle if no data or invalid selection
        if ($this._filteredData.Count -eq 0 -or $this._selectedIndex -lt 0) {
            return
        }

        if ($this._selectedIndices.Contains($this._selectedIndex)) {
            [void]$this._selectedIndices.Remove($this._selectedIndex)
        } else {
            [void]$this._selectedIndices.Add($this._selectedIndex)
        }

        $this._InvokeCallback($this.OnMultiSelectChanged, $this.GetSelectedItems())

        # Move down to next item
        $this._MoveSelectionDown(1)
    }

    <#
    .SYNOPSIS
    Trigger selection changed event
    #>
    hidden [void] _TriggerSelectionChanged() {
        $selectedItem = $this.GetSelectedItem()
        $this._InvokeCallback($this.OnSelectionChanged, $selectedItem)
    }

    <#
    .SYNOPSIS
    Apply sort to filtered data
    #>
    hidden [void] _ApplySort() {
        if ([string]::IsNullOrWhiteSpace($this._sortColumn)) {
            return
        }

        $col = $this._columns | Where-Object { $_.Name -eq $this._sortColumn } | Select-Object -First 1

        if ($null -eq $col -or ($col.ContainsKey('Sortable') -and -not $col.Sortable)) {
            return
        }

        # Sort filtered data
        if ($this._sortAscending) {
            $this._filteredData = @($this._filteredData | Sort-Object -Property $this._sortColumn)
        } else {
            $this._filteredData = @($this._filteredData | Sort-Object -Property $this._sortColumn -Descending)
        }
    }

    <#
    .SYNOPSIS
    Apply filters to data
    #>
    hidden [void] _ApplyFilters() {
        $this._filteredData = @($this._filterPanel.ApplyFilters($this._data))
        $this._ApplySearch()
        $this._ApplySort()

        # Reset selection with proper bounds checking
        if ($this._filteredData.Count -eq 0) {
            $this._selectedIndex = -1  # Explicitly invalid when no data
        } else {
            $this._selectedIndex = [Math]::Min($this._selectedIndex, $this._filteredData.Count - 1)
            $this._selectedIndex = [Math]::Max(0, $this._selectedIndex)
        }
        $this._AdjustScrollOffset()
    }

    <#
    .SYNOPSIS
    Apply search filter
    #>
    hidden [void] _ApplySearch() {
        if ([string]::IsNullOrWhiteSpace($this._searchText)) {
            return
        }

        $searchLower = $this._searchText.ToLower()
        $filtered = [System.Collections.ArrayList]::new()

        foreach ($item in $this._filteredData) {
            # Search in all columns
            $match = $false
            foreach ($col in $this._columns) {
                $value = $this._GetItemProperty($item, $col.Name)
                if ($null -eq $value) { $value = "" }
                if ($null -ne $value) {
                    $valueStr = $value.ToString().ToLower()
                    if ($valueStr.Contains($searchLower)) {
                        $match = $true
                        break
                    }
                }
            }

            if ($match) {
                [void]$filtered.Add($item)
            }
        }

        # Force array type - prevent PowerShell from unwrapping single-item arrays
        $this._filteredData = @($filtered)
    }

    <#
    .SYNOPSIS
    Handle search mode input
    #>
    hidden [bool] _HandleSearchInput([ConsoleKeyInfo]$keyInfo) {
        if ($keyInfo.Key -eq 'Escape') {
            $this.IsInSearchMode = $false
            $this._searchText = ""
            $this._ApplyFilters()
            return $true
        }

        if ($keyInfo.Key -eq 'Enter') {
            $this.IsInSearchMode = $false
            $this._ApplyFilters()
            return $true
        }

        if ($keyInfo.Key -eq 'Backspace') {
            if ($this._searchText.Length -gt 0) {
                $this._searchText = $this._searchText.Substring(0, $this._searchText.Length - 1)
                $this._ApplyFilters()
            }
            return $true
        }

        # Regular character input
        if ($keyInfo.KeyChar -ge 32 -and $keyInfo.KeyChar -le 126) {
            $this._searchText += $keyInfo.KeyChar
            $this._ApplyFilters()
            return $true
        }

        return $false
    }

    <#
    .SYNOPSIS
    L-POL-9: Get consistent color for a tag using hash-based selection

    .PARAMETER tag
    Tag string to colorize

    .OUTPUTS
    ANSI color code string
    #>
    hidden [string] _GetTagColor([string]$tag) {
        # Hash the tag name to get a consistent color
        $hash = 0
        foreach ($char in $tag.ToCharArray()) {
            $hash = ($hash * 31 + [int]$char) % 256
        }

        # Use a palette of distinct, readable colors
        $colors = @(
            "`e[94m"   # Bright blue
            "`e[92m"   # Bright green
            "`e[96m"   # Bright cyan
            "`e[93m"   # Bright yellow
            "`e[95m"   # Bright magenta
            "`e[91m"   # Bright red
            "`e[34m"   # Blue
            "`e[32m"   # Green
            "`e[36m"   # Cyan
            "`e[35m"   # Magenta
        )

        return $colors[$hash % $colors.Count]
    }

    <#
    .SYNOPSIS
    Invoke callback safely
    #>
    hidden [void] _InvokeCallback([scriptblock]$callback, $arg) {
        if ($null -ne $callback -and $callback -ne {}) {
            try {
                if ($null -ne $arg) {
                    # Use Invoke-Command with -ArgumentList to pass single arg without array wrapping
                    Invoke-Command -ScriptBlock $callback -ArgumentList (,$arg)
                } else {
                    & $callback
                }
            } catch {
                # Log callback errors but DON'T rethrow - callbacks must never crash the app
                if (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue) {
                    Write-PmcTuiLog "UniversalList callback error: $($_.Exception.Message)" "ERROR"
                    Write-PmcTuiLog "Callback code: $($callback.ToString())" "ERROR"
                    Write-PmcTuiLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
                }
                # DON'T rethrow - UI callbacks must not crash
            }
        }
    }

    # ===== PERFORMANCE: Direct Engine Rendering Methods =====

    # Parse ANSI string and write to engine (helper for child widgets not yet converted)
    hidden [void] _ParseAnsiToEngine([object]$engine, [string]$ansiOutput) {
        # Same logic as PmcScreen._ParseAnsiAndWrite
        $pattern = "`e\[(\d+);(\d+)H"
        $matches = [regex]::Matches($ansiOutput, $pattern)

        if ($matches.Count -eq 0) {
            if ($ansiOutput) {
                $engine.WriteAt(0, 0, $ansiOutput)
            }
            return
        }

        for ($i = 0; $i -lt $matches.Count; $i++) {
            $match = $matches[$i]
            $row = [int]$match.Groups[1].Value
            $col = [int]$match.Groups[2].Value
            $x = $col - 1  # Convert to 0-based
            $y = $row - 1

            $startIndex = $match.Index + $match.Length
            if ($i + 1 -lt $matches.Count) {
                $endIndex = $matches[$i + 1].Index
            } else {
                $endIndex = $ansiOutput.Length
            }

            $content = $ansiOutput.Substring($startIndex, $endIndex - $startIndex)
            if ($content) {
                $engine.WriteAt($x, $y, $content)
            }
        }
    }

    # Render list directly to engine (no string building)
    hidden [void] _RenderListDirect([object]$engine) {
        # Colors from new theme system
        $borderColor = $this.GetThemedFg('Border.Widget')
        $textColor = $this.GetThemedFg('Foreground.Row')
        $primaryColor = $this.GetThemedFg('Foreground.Title')
        $mutedColor = $this.GetThemedFg('Foreground.Muted')
        $successColor = $this.GetThemedFg('Foreground.Success')

        # Selected row colors
        $highlightBg = $this.GetThemedBg('Background.RowSelected', 1, 0)
        $highlightFg = $this.GetThemedFg('Foreground.RowSelected')

        # CRITICAL FIX: Fallback if theme returns empty
        if ([string]::IsNullOrWhiteSpace($highlightBg)) {
            $highlightBg = "`e[48;2;64;94;117m"  # Fallback blue background
        }
        if ([string]::IsNullOrWhiteSpace($highlightFg)) {
            $highlightFg = "`e[38;2;255;255;255m"  # Fallback white foreground
        }

        # EXTENSIVE DEBUG: Log ALL color values
        # PERF FIX: Disabled - Add-Content -Path "$($env:TEMP)\pmc-colors-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') highlightBg='$highlightBg' len=$($highlightBg.Length) highlightFg='$highlightFg' len=$($highlightFg.Length)"

        $reset = "`e[0m"

        # Draw top border
        $topLine = $borderColor + $this.BuildBoxBorder($this.Width, 'top', 'single')
        $engine.WriteAt($this.X - 1, $this.Y - 1, $topLine)

        # Title
        $titleText = " $($this.Title) "
        $engine.WriteAt($this.X + 1, $this.Y - 1, $primaryColor + $titleText + $reset)

        # Item count
        $countText = "($($this._filteredData.Count) items)"
        $engine.WriteAt($this.X + $this.Width - $countText.Length - 3, $this.Y - 1, $mutedColor + $countText + $reset)

        $currentRow = 1

        # Column headers
        $headerY = $this.Y + $currentRow
        $engine.WriteAt($this.X - 1, $headerY - 1, $borderColor + $this.GetBoxChar('single_vertical') + $reset)

        # Build header line
        $headerBuilder = [StringBuilder]::new()
        $currentX = 2
        $supportsUnicode = $env:LANG -match 'UTF-8' -or [Console]::OutputEncoding.EncodingName -match 'UTF'
        $sortUpSymbol = $(if ($supportsUnicode) { "↑" } else { "^" })
        $sortDownSymbol = $(if ($supportsUnicode) { "↓" } else { "v" })

        foreach ($col in $this._columns) {
            $label = $col.Label
            $width = $(if ($this._columnWidths.ContainsKey($col.Name)) {
                $this._columnWidths[$col.Name]
            } else {
                $col.Width
            })

            if ($this._sortColumn -eq $col.Name) {
                $sortIndicator = $(if ($this._sortAscending) { " $sortUpSymbol" } else { " $sortDownSymbol" })
                $label += $sortIndicator
            }

            # Use EXACT SAME logic as data rows
            $targetWidth = $width + 2
            $truncated = $this.TruncateText($label, $targetWidth)
            $padded = $this.PadText($truncated, $targetWidth, $col.Align)
            $headerBuilder.Append($padded)
            $headerBuilder.Append("    ")
        }

        $engine.WriteAt($this.X + 1, $headerY - 1, $primaryColor + $headerBuilder.ToString() + $reset)
        $engine.WriteAt($this.X + $this.Width - 2, $headerY - 1, $borderColor + $this.GetBoxChar('single_vertical') + $reset)

        $currentRow++

        # Separator row
        $sepY = $this.Y + $currentRow
        $sepLine = $borderColor + $this.GetBoxChar('single_vertical') + $this.BuildHorizontalLine($this.Width - 2, 'single') + $this.GetBoxChar('single_vertical') + $reset
        $engine.WriteAt($this.X - 1, $sepY - 1, $sepLine)

        $currentRow++

        # Data rows (virtual scrolling)
        $maxVisibleRows = $this.Height - 6
        $visibleStartIndex = $this._scrollOffset

        $filteredCount = $(if ($null -eq $this._filteredData) {
            0
        } elseif ($this._filteredData -is [array]) {
            $this._filteredData.Count
        } else {
            1
        })

        $linesToRender = [Math]::Min($maxVisibleRows, $filteredCount - $visibleStartIndex)

        for ($i = 0; $i -lt $linesToRender; $i++) {
            $dataIndex = $visibleStartIndex + $i
            $item = $this._filteredData[$dataIndex]
            $rowY = $this.Y + $currentRow + $i

            # Left border
            $engine.WriteAt($this.X - 1, $rowY - 1, $borderColor + $this.GetBoxChar('single_vertical') + $reset)

            # Determine if selected
            $isSelected = ($dataIndex -eq $this._selectedIndex)

            # Build row content
            $rowBuilder = [StringBuilder]::new()
            $currentX = 2

            foreach ($col in $this._columns) {
                $cellValue = $this._GetItemProperty($item, $col.Name)
                if ($null -eq $cellValue) {
                    $cellValue = ""
                }

                # Format cell value - convert to string
                $cellText = $(if ($cellValue -is [array]) {
                    ($cellValue -join ', ')
                } elseif ($null -ne $cellValue) {
                    $cellValue.ToString()
                } else {
                    ""
                })

                $width = $(if ($this._columnWidths.ContainsKey($col.Name)) {
                    $this._columnWidths[$col.Name]
                } else {
                    $col.Width
                })

                if ($isSelected) {
                    $rowBuilder.Append($highlightBg)
                }

                $rowBuilder.Append($this.PadText($cellText, $width, $col.Align))

                if ($isSelected) {
                    $rowBuilder.Append($reset)
                }

                $rowBuilder.Append("  ")
            }

            $engine.WriteAt($this.X + 1, $rowY - 1, $rowBuilder.ToString())

            # Right border
            $engine.WriteAt($this.X + $this.Width - 2, $rowY - 1, $borderColor + $this.GetBoxChar('single_vertical') + $reset)
        }

        # Bottom border
        $bottomY = $this.Y + $this.Height - 2
        $bottomLine = $borderColor + $this.BuildBoxBorder($this.Width, 'bottom', 'single') + $reset
        $engine.WriteAt($this.X - 1, $bottomY - 1, $bottomLine)

        # Status line
        $statusY = $this.Y + $this.Height - 1
        $statusText = " Row $($this._selectedIndex + 1) of $filteredCount "
        $engine.WriteAt($this.X - 1, $statusY - 1, $mutedColor + $statusText + $reset)
    }
}