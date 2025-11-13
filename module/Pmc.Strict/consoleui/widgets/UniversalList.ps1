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

    # === State Flags ===
    [bool]$IsInMultiSelectMode = $false        # True when in multi-select mode
    [bool]$IsInSearchMode = $false             # True when in search mode
    [bool]$IsInFilterMode = $false             # True when filter panel shown

    # === Private State ===
    hidden [List[hashtable]]$_columns = [List[hashtable]]::new()         # Column definitions
    hidden [array]$_data = @()                                           # Original data array
    hidden [array]$_filteredData = @()                                   # Filtered/sorted data
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
        $this._data = if ($null -ne $data) { @($data) } else { @() }
        $this._filteredData = @($this._data)
        $this._selectedIndex = 0
        $this._scrollOffset = 0
        $this._selectedIndices.Clear()

        # Invalidate row cache when data changes
        $this._cacheGeneration++
        $this._rowCache.Clear()
        # H-MEM-1: Clear LRU access order as well
        $this._cacheAccessOrder.Clear()

        # Apply any active filters/search
        $this._ApplyFilters()
        $this._ApplySearch()

        $this._InvokeCallback($this.OnDataChanged, $this._data)
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
                    Value = if ($item.($col.Name)) { $item.($col.Name) } else { "" }
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
        # Route input to inline editor if shown
        if ($this._showInlineEditor) {
            $handled = $this._inlineEditor.HandleInput($keyInfo)

            if ($this._inlineEditor.IsConfirmed -or $this._inlineEditor.IsCancelled) {
                $this._showInlineEditor = $false
            }

            # If editor handled the key, we're done
            # Otherwise, fall through to allow parent/global handlers (e.g., Ctrl+Q)
            if ($handled) {
                return $true
            }
            # Don't return false here - let parent handlers have a chance
        }

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
            # Activate selected item
            $selectedItem = $this.GetSelectedItem()
            if ($null -ne $selectedItem) {
                $this._InvokeCallback($this.OnItemActivated, $selectedItem)
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

        # L-POL-22: Alt+Left/Right - adjust column width
        if ($keyInfo.Modifiers -band [ConsoleModifiers]::Alt) {
            if ($keyInfo.Key -eq 'LeftArrow') {
                # Decrease width of current column
                if ($this._selectedColumnIndex -ge 0 -and $this._selectedColumnIndex -lt $this._columns.Count) {
                    $colName = $this._columns[$this._selectedColumnIndex].Name
                    $currentWidth = if ($this._columnWidths.ContainsKey($colName)) {
                        $this._columnWidths[$colName]
                    } else {
                        $this._columns[$this._selectedColumnIndex].Width
                    }
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
                    $currentWidth = if ($this._columnWidths.ContainsKey($colName)) {
                        $this._columnWidths[$colName]
                    } else {
                        $this._columns[$this._selectedColumnIndex].Width
                    }
                    $this._columnWidths[$colName] = [Math]::Min(100, $currentWidth + 2)
                    # Invalidate row cache
                    $this._cacheGeneration++
                    $this._rowCache.Clear()
                    $this._cacheAccessOrder.Clear()
                }
                return $true
            }
        }

        # C key - cycle selected column for width adjustment
        if ($keyInfo.KeyChar -eq 'c' -or $keyInfo.KeyChar -eq 'C') {
            $this._selectedColumnIndex = ($this._selectedColumnIndex + 1) % $this._columns.Count
            return $true
        }

        # Action handling
        # DEBUG: Write directly to log file for troubleshooting
        if ($global:PmcTuiLogFile) {
            $keyChar = $keyInfo.KeyChar.ToString().ToLower()
            Write-PmcTuiLog "UniversalList HandleInput: char='$keyChar' Key=$($keyInfo.Key) Actions=$($this._actions.Keys -join ',')" "DEBUG"
        }

        if ($this._actions.ContainsKey($keyChar)) {
            $action = $this._actions[$keyChar]
            if ($global:PmcTuiLogFile) {
                Write-PmcTuiLog "UniversalList: Triggering action '$keyChar' - $($action.Label)" "DEBUG"
            }
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
        # If inline editor is shown, render it instead
        if ($this._showInlineEditor) {
            return $this._inlineEditor.Render()
        }

        # If filter panel is shown, render it as overlay
        if ($this.IsInFilterMode) {
            # Render list first, then filter panel on top
            $listContent = $this._RenderList()
            $filterContent = $this._filterPanel.Render()
            return $listContent + "`n" + $filterContent
        }

        return $this._RenderList()
    }

    <#
    .SYNOPSIS
    Render directly to engine (optimized path)

    .PARAMETER engine
    RenderEngine instance to write to

    .DESCRIPTION
    Optimized rendering that writes directly to engine.
    Handles inline editor and filter panel delegation.
    #>
    [void] RenderToEngine([object]$engine) {
        # If inline editor is shown, delegate to it
        if ($this._showInlineEditor) {
            if ($this._inlineEditor.PSObject.Methods['RenderToEngine']) {
                $this._inlineEditor.RenderToEngine($engine)
            } else {
                # Fall back to ANSI parsing for child widget
                $output = $this._inlineEditor.Render()
                if ($output) {
                    # Parse and write (temporary until InlineEditor migrated)
                    $this._ParseAndWriteToEngine($engine, $output)
                }
            }
            return
        }

        # Render main list content
        $this._RenderListToEngine($engine)

        # If filter panel is shown, render it as overlay
        if ($this.IsInFilterMode) {
            if ($this._filterPanel.PSObject.Methods['RenderToEngine']) {
                $this._filterPanel.RenderToEngine($engine)
            } else {
                # Fall back to ANSI parsing for child widget
                $output = $this._filterPanel.Render()
                if ($output) {
                    $this._ParseAndWriteToEngine($engine, $output)
                }
            }
        }
    }

    hidden [void] _ParseAndWriteToEngine([object]$engine, [string]$ansiOutput) {
        # Simple ANSI parser for fallback (matches PmcScreen._ParseAnsiAndWrite logic)
        $lines = $ansiOutput -split "`n"
        $currentY = 0
        foreach ($line in $lines) {
            if ($line -match '\x1b\[(\d+);(\d+)H') {
                $row = [int]$matches[1] - 1
                $col = [int]$matches[2] - 1
                $currentY = $row
                # Remove positioning codes and write
                $cleanLine = $line -replace '\x1b\[\d+;\d+H', ''
                if ($cleanLine) {
                    $engine.WriteAt($col, $row, $cleanLine)
                }
            }
        }
    }

    hidden [void] _RenderListToEngine([object]$engine) {
        # TODO: Full engine-optimized rendering (currently falls back to ANSI for complex logic)
        # For now, use the string-based approach and parse it
        # This can be optimized later by converting _RenderList() logic to direct engine.WriteAt() calls
        $listContent = $this._RenderList()
        $this._ParseAndWriteToEngine($engine, $listContent)
    }

    # === Private Helper Methods ===

    <#
    .SYNOPSIS
    Render the main list
    #>
    hidden [string] _RenderList() {
        $sb = [StringBuilder]::new(8192)

        # Colors from theme
        $borderColor = $this.GetThemedAnsi('Border', $false)
        $textColor = $this.GetThemedAnsi('Text', $false)
        $primaryColor = $this.GetThemedAnsi('Primary', $false)
        $mutedColor = $this.GetThemedAnsi('Muted', $false)
        $errorColor = $this.GetThemedAnsi('Error', $false)
        $successColor = $this.GetThemedAnsi('Success', $false)
        $highlightBg = $this.GetThemedAnsi('Primary', $true)
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
        $sortUpSymbol = if ($supportsUnicode) { "↑" } else { "^" }
        $sortDownSymbol = if ($supportsUnicode) { "↓" } else { "v" }

        foreach ($col in $this._columns) {
            $label = $col.Label
            # L-POL-22: Use custom width if set, otherwise use default
            $width = if ($this._columnWidths.ContainsKey($col.Name)) {
                $this._columnWidths[$col.Name]
            } else {
                $col.Width
            }

            # Add sort indicator with fallback
            if ($this._sortColumn -eq $col.Name) {
                $sortIndicator = if ($this._sortAscending) { " $sortUpSymbol" } else { " $sortDownSymbol" }
                $label += $sortIndicator
            }

            $sb.Append($this.PadText($label, $width, $col.Align))
            $sb.Append("  ")
            $currentX += $width + 2
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
        $filteredCount = if ($null -eq $this._filteredData) {
            0
        } elseif ($this._filteredData -is [array]) {
            $this._filteredData.Count
        } else {
            1
        }

        $visibleEndIndex = [Math]::Min($this._scrollOffset + $maxVisibleRows, $filteredCount)

        # DEBUG: Log list state with type checking
        if ($global:PmcTuiLogFile) {
            $dataCount = if ($null -eq $this._data) { "NULL" } elseif ($this._data -is [array]) { $this._data.Count } else { "NOT_ARRAY:$($this._data.GetType().Name)" }
            $filteredCount = if ($null -eq $this._filteredData) { "NULL" } elseif ($this._filteredData -is [array]) { $this._filteredData.Count } else { "NOT_ARRAY:$($this._filteredData.GetType().Name)" }
            Write-PmcTuiLog "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] UniversalList._RenderList: _data=$dataCount _filteredData=$filteredCount maxVisible=$maxVisibleRows visibleStart=$visibleStartIndex visibleEnd=$visibleEndIndex" "INFO"
        }

        if ($global:PmcTuiLogFile) {
            Write-PmcTuiLog "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] UniversalList._RenderList LOOP: visibleStartIndex=$visibleStartIndex visibleEndIndex=$visibleEndIndex" "INFO"
        }

        for ($i = $visibleStartIndex; $i -lt $visibleEndIndex; $i++) {
            # Handle both array and scalar _filteredData
            $item = if ($this._filteredData -is [array]) {
                $this._filteredData[$i]
            } else {
                $this._filteredData
            }

            if ($global:PmcTuiLogFile) {
                $itemDesc = Get-SafeProperty $item 'text'
                if (-not $itemDesc) { $itemDesc = Get-SafeProperty $item 'name' }
                if (-not $itemDesc) { $itemDesc = Get-SafeProperty $item 'id' }
                if (-not $itemDesc) { $itemDesc = "unknown" }
                Write-PmcTuiLog "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] UniversalList._RenderList LOOP iteration $i - item=$itemDesc" "INFO"
            }

            $rowY = $this.Y + $currentRow
            $isSelected = ($i -eq $this._selectedIndex)
            $isMultiSelected = $this._selectedIndices.Contains($i)

            # Check row cache - cache key includes generation and selection state
            $cacheKey = "$($this._cacheGeneration)_${i}_${isSelected}_${isMultiSelected}"
            $cachedRow = $null
            if ($this._rowCache.ContainsKey($cacheKey)) {
                $cachedRow = $this._rowCache[$cacheKey]
                # H-MEM-1: Update LRU access order
                $this._cacheAccessOrder.Remove($cacheKey)
                [void]$this._cacheAccessOrder.AddLast($cacheKey)
                $sb.Append($cachedRow)
                $currentRow++
                continue
            }

            # Build row content (not in cache)
            $rowBuilder = [Text.StringBuilder]::new(256)

            # Row border
            $rowBuilder.Append($this.BuildMoveTo($this.X, $rowY))
            $rowBuilder.Append($borderColor)
            $rowBuilder.Append($this.GetBoxChar('single_vertical'))

            # Row content
            $rowBuilder.Append($this.BuildMoveTo($this.X + 2, $rowY))

            # Highlight selected row
            if ($isSelected) {
                $rowBuilder.Append($highlightBg)
                $rowBuilder.Append("`e[30m")
            } elseif ($isMultiSelected) {
                $rowBuilder.Append($successColor)
            } else {
                $rowBuilder.Append($textColor)
            }

            # Render columns
            $currentX = 2
            foreach ($col in $this._columns) {
                $value = Get-SafeProperty $item $col.Name
                # L-POL-22: Use custom width if set, otherwise use default
                $width = if ($this._columnWidths.ContainsKey($col.Name)) {
                    $this._columnWidths[$col.Name]
                } else {
                    $col.Width
                }

                # Format value if formatter provided
                if ($col.ContainsKey('Format') -and $null -ne $col.Format) {
                    try {
                        # Pass the WHOLE ITEM to formatter, not just the field value
                        $value = & $col.Format $item
                    } catch {
                        # HIGH FIX #7: Log error but return original value for graceful degradation
                        if (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue) {
                            Write-PmcTuiLog "Column format error for '$($col.Name)': $($_.Exception.Message)" "ERROR"
                        }
                        # Return original unformatted value instead of error text - use safe property access
                        $value = Get-SafeProperty $item $col.Name
                    }
                }

                # Convert to string
                $valueStr = if ($null -ne $value) { $value.ToString() } else { "" }

                # L-POL-16: Highlight search matches if in search mode
                if ($this.IsInSearchMode -and -not [string]::IsNullOrWhiteSpace($this._searchText)) {
                    $searchLower = $this._searchText.ToLower()
                    $valueLower = $valueStr.ToLower()
                    $highlightColor = "`e[43m`e[30m"  # Yellow background, black text
                    $resetHighlight = if ($isSelected) { $highlightBg + "`e[30m" } elseif ($isMultiSelected) { $successColor } else { $textColor }

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

                # Truncate and pad (note: TruncateText needs to be aware of ANSI codes, or we apply after)
                # For now, we'll truncate before highlighting to keep logic simple
                $displayValue = $this.PadText($this.TruncateText($valueStr, $width), $width, $col.Align)
                $rowBuilder.Append($displayValue)
                $rowBuilder.Append("  ")

                $currentX += $width + 2
            }

            $rowBuilder.Append($reset)

            # Padding to fill row
            $contentWidth = $currentX - 2
            $padding = $this.Width - $contentWidth - 2
            if ($padding -gt 0) {
                if ($isSelected) {
                    $rowBuilder.Append($highlightBg)
                }
                $rowBuilder.Append(" " * $padding)
                $rowBuilder.Append($reset)
            }

            # Right border
            $rowBuilder.Append($this.BuildMoveTo($this.X + $this.Width - 1, $rowY))
            $rowBuilder.Append($borderColor)
            $rowBuilder.Append($this.GetBoxChar('single_vertical'))

            # Cache the built row
            $builtRow = $rowBuilder.ToString()

            # H-MEM-1: Evict oldest cache entry if max size exceeded
            if ($this._rowCache.Count -ge $this._maxCacheSize) {
                $oldestKey = $this._cacheAccessOrder.First.Value
                $this._rowCache.Remove($oldestKey)
                $this._cacheAccessOrder.RemoveFirst()
            }

            $this._rowCache[$cacheKey] = $builtRow
            [void]$this._cacheAccessOrder.AddLast($cacheKey)
            $sb.Append($builtRow)

            $currentRow++
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
                # Handle both hashtables and objects
                $text = Get-SafeProperty $selectedItem 'text'
                $id = Get-SafeProperty $selectedItem 'id'

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

        if ($global:PmcTuiLogFile) {
            Write-PmcTuiLog "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] UniversalList._RenderList: actionsStr='$actionsStr' (Keys=$($this._actions.Keys.Count))" "INFO"
        }

        if ($actionsStr.Length -eq 0) {
            $actionsStr = "↑/↓: Nav | Space: Select | /: Search | F: Filter | Enter: Open"
        }

        # L-POL-24: Split into multiple lines with overflow handling
        $maxWidth = $this.Width - 4
        $actionLines = @()
        $currentLine = ""

        foreach ($actionPair in ($actionsStr -split ' \| ')) {
            $testLine = if ($currentLine.Length -eq 0) { $actionPair } else { "$currentLine | $actionPair" }
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
        $this._MoveSelectionDown()
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
                $value = Get-SafeProperty $item $col.Name
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
}
