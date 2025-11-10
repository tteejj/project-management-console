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

        if ($null -eq $columns -or $columns.Count -eq 0) {
            throw "At least one column is required"
        }

        foreach ($col in $columns) {
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
        $this._data = if ($null -ne $data) { $data } else { @() }
        $this._filteredData = $this._data
        $this._selectedIndex = 0
        $this._scrollOffset = 0
        $this._selectedIndices.Clear()

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

        # Action handling
        $keyChar = $keyInfo.KeyChar.ToString().ToLower()

        # DEBUG: Write directly to log file for troubleshooting
        $debugMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] UniversalList HandleInput: char='$keyChar' Key=$($keyInfo.Key) Actions=$($this._actions.Keys -join ',')"
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value $debugMsg
        }

        if ($this._actions.ContainsKey($keyChar)) {
            $action = $this._actions[$keyChar]
            $actionMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] UniversalList: Triggering action '$keyChar' - $($action.Label)"
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value $actionMsg
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
        foreach ($col in $this._columns) {
            $label = $col.Label
            $width = $col.Width

            # Add sort indicator
            if ($this._sortColumn -eq $col.Name) {
                $sortIndicator = if ($this._sortAscending) { " ↑" } else { " ↓" }
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
        $visibleEndIndex = [Math]::Min($this._scrollOffset + $maxVisibleRows, $this._filteredData.Count)

        for ($i = $visibleStartIndex; $i -lt $visibleEndIndex; $i++) {
            $item = $this._filteredData[$i]
            $rowY = $this.Y + $currentRow
            $isSelected = ($i -eq $this._selectedIndex)
            $isMultiSelected = $this._selectedIndices.Contains($i)

            # Row border
            $sb.Append($this.BuildMoveTo($this.X, $rowY))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            # Row content
            $sb.Append($this.BuildMoveTo($this.X + 2, $rowY))

            # Highlight selected row
            if ($isSelected) {
                $sb.Append($highlightBg)
                $sb.Append("`e[30m")
            } elseif ($isMultiSelected) {
                $sb.Append($successColor)
            } else {
                $sb.Append($textColor)
            }

            # Render columns
            $currentX = 2
            foreach ($col in $this._columns) {
                $value = $item.($col.Name)
                $width = $col.Width

                # Format value if formatter provided
                if ($col.ContainsKey('Format') -and $null -ne $col.Format) {
                    try {
                        # Pass the WHOLE ITEM to formatter, not just the field value
                        $value = & $col.Format $item
                    } catch {
                        $value = "(error)"
                    }
                }

                # Convert to string
                $valueStr = if ($null -ne $value) { $value.ToString() } else { "" }

                # Truncate and pad
                $displayValue = $this.PadText($this.TruncateText($valueStr, $width), $width, $col.Align)
                $sb.Append($displayValue)
                $sb.Append("  ")

                $currentX += $width + 2
            }

            $sb.Append($reset)

            # Padding to fill row
            $contentWidth = $currentX - 2
            $padding = $this.Width - $contentWidth - 2
            if ($padding -gt 0) {
                if ($isSelected) {
                    $sb.Append($highlightBg)
                }
                $sb.Append(" " * $padding)
                $sb.Append($reset)
            }

            # Right border
            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $rowY))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

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
            $sb.Append("Search: $($this._searchText)_")
        } elseif ($this.IsInMultiSelectMode) {
            $sb.Append($successColor)
            $sb.Append("Multi-select mode ($($this._selectedIndices.Count) selected)")
        } else {
            $sb.Append($mutedColor)
            $selectedItem = $this.GetSelectedItem()
            if ($null -ne $selectedItem) {
                $preview = "Selected: "
                # Handle both hashtables and objects
                $text = if ($selectedItem -is [hashtable]) { $selectedItem['text'] } else { $selectedItem.text }
                $id = if ($selectedItem -is [hashtable]) { $selectedItem['id'] } else { $selectedItem.id }

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
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] UniversalList._RenderList: actionsStr='$actionsStr' (Keys=$($this._actions.Keys.Count))"
        }

        if ($actionsStr.Length -eq 0) {
            $actionsStr = "↑/↓: Nav | Space: Select | /: Search | F: Filter | Enter: Open"
        }

        # Split into multiple lines if too long
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
                $currentLine = $actionPair
            }
        }
        if ($currentLine.Length -gt 0) {
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
            $this._filteredData = $this._filteredData | Sort-Object -Property $this._sortColumn
        } else {
            $this._filteredData = $this._filteredData | Sort-Object -Property $this._sortColumn -Descending
        }
    }

    <#
    .SYNOPSIS
    Apply filters to data
    #>
    hidden [void] _ApplyFilters() {
        $this._filteredData = $this._filterPanel.ApplyFilters($this._data)
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
        $filtered = @()

        foreach ($item in $this._filteredData) {
            # Search in all columns
            $match = $false
            foreach ($col in $this._columns) {
                $value = $item.($col.Name)
                if ($null -ne $value) {
                    $valueStr = $value.ToString().ToLower()
                    if ($valueStr.Contains($searchLower)) {
                        $match = $true
                        break
                    }
                }
            }

            if ($match) {
                $filtered += $item
            }
        }

        $this._filteredData = $filtered
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
