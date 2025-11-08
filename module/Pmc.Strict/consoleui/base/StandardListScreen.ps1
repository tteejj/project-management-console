# StandardListScreen.ps1 - Base class for ALL list-based screens
#
# This is the FOUNDATION for every screen that shows a list of items:
# - TaskListScreen
# - ProjectListScreen
# - TimeLogListScreen
# - SearchResultsScreen
# - etc.
#
# Provides:
# - UniversalList integration (columns, sorting, filtering, search)
# - FilterPanel integration (dynamic filter builder)
# - InlineEditor integration (add/edit items)
# - TaskStore integration (automatic CRUD + events)
# - Keyboard navigation (arrows, PageUp/Down, Home/End)
# - Action handling (Add, Edit, Delete, custom actions)
# - Automatic UI refresh on data changes
#
# Usage:
#   class TaskListScreen : StandardListScreen {
#       TaskListScreen() : base("TaskList", "My Tasks") {
#           # Configuration in constructor
#       }
#
#       [void] LoadData() {
#           $tasks = $this.Store.GetAllTasks() | Where { -not $_.completed }
#           $this.List.SetData($tasks)
#       }
#
#       [array] GetColumns() {
#           return @(
#               @{ Name='priority'; Label='Pri'; Width=4 }
#               @{ Name='text'; Label='Task'; Width=40 }
#               @{ Name='due'; Label='Due'; Width=12 }
#           )
#       }
#
#       [array] GetEditFields($item) {
#           return @(
#               @{ Name='text'; Type='text'; Label='Task'; Value=$item.text; Required=$true }
#               @{ Name='due'; Type='date'; Label='Due'; Value=$item.due }
#               @{ Name='priority'; Type='number'; Label='Priority'; Value=$item.priority; Min=0; Max=5 }
#           )
#       }
#   }

using namespace System
using namespace System.Collections.Generic
using namespace System.Text

# Load dependencies
# NOTE: These are now loaded by the launcher script in the correct order.
# Commenting out to avoid circular dependency issues.
# $scriptDir = Split-Path -Parent $PSScriptRoot
# . "$scriptDir/PmcScreen.ps1"
# . "$scriptDir/widgets/UniversalList.ps1"
# . "$scriptDir/widgets/FilterPanel.ps1"
# . "$scriptDir/widgets/InlineEditor.ps1"
# . "$scriptDir/services/TaskStore.ps1"

<#
.SYNOPSIS
Base class for all list-based screens in PMC TUI

.DESCRIPTION
StandardListScreen provides a complete list-viewing experience with:
- Universal list widget with columns, sorting, filtering
- Filter panel for advanced filtering
- Inline editor for add/edit operations
- TaskStore integration for automatic CRUD
- Event-driven UI updates
- Keyboard-driven navigation
- Extensible via abstract methods

Abstract Methods (override in subclasses):
- LoadData() - Load data into list
- GetColumns() - Define column configuration
- GetEditFields($item) - Define edit form fields

Optional Overrides:
- OnItemSelected($item) - Handle item selection
- OnItemActivated($item) - Handle item activation (Enter key)
- GetCustomActions() - Add custom actions beyond Add/Edit/Delete
- GetEntityType() - Return 'task', 'project', or 'timelog' for store operations

.EXAMPLE
class TaskListScreen : StandardListScreen {
    TaskListScreen() : base("TaskList", "My Tasks") {}

    [void] LoadData() {
        $tasks = $this.Store.GetAllTasks()
        $this.List.SetData($tasks)
    }

    [array] GetColumns() {
        return @(
            @{ Name='text'; Label='Task'; Width=40 }
            @{ Name='due'; Label='Due'; Width=12 }
        )
    }

    [array] GetEditFields($item) {
        return @(
            @{ Name='text'; Type='text'; Label='Task'; Value=$item.text; Required=$true }
        )
    }
}
#>
class StandardListScreen : PmcScreen {
    # === Core Components ===
    [UniversalList]$List = $null
    [FilterPanel]$FilterPanel = $null
    [InlineEditor]$InlineEditor = $null
    [TaskStore]$Store = $null

    # === Component State ===
    [bool]$ShowFilterPanel = $false
    [bool]$ShowInlineEditor = $false
    [string]$EditorMode = ""  # 'add' or 'edit'
    [object]$CurrentEditItem = $null

    # === Configuration ===
    [bool]$AllowAdd = $true
    [bool]$AllowEdit = $true
    [bool]$AllowDelete = $true
    [bool]$AllowFilter = $true
    [bool]$AllowSearch = $true
    [bool]$AllowMultiSelect = $true

    # === Constructor ===
    StandardListScreen([string]$key, [string]$title) : base($key, $title) {
        # Initialize components
        $this._InitializeComponents()
    }

    # === Abstract Methods (MUST override) ===

    <#
    .SYNOPSIS
    Load data into the list (ABSTRACT - must override)
    #>
    [void] LoadData() {
        throw "LoadData() must be implemented in subclass"
    }

    <#
    .SYNOPSIS
    Get column configuration (ABSTRACT - must override)

    .OUTPUTS
    Array of column hashtables with Name, Label, Width, Align, Format properties
    #>
    [array] GetColumns() {
        throw "GetColumns() must be implemented in subclass"
    }

    <#
    .SYNOPSIS
    Get edit field configuration (ABSTRACT - must override)

    .PARAMETER item
    Item being edited (or empty hashtable for new item)

    .OUTPUTS
    Array of field hashtables for InlineEditor
    #>
    [array] GetEditFields($item) {
        throw "GetEditFields() must be implemented in subclass"
    }

    # === Optional Override Methods ===

    <#
    .SYNOPSIS
    Get entity type for store operations ('task', 'project', 'timelog')

    .OUTPUTS
    Entity type string
    #>
    [string] GetEntityType() {
        # Default to 'task' - override if using projects or timelogs
        return 'task'
    }

    <#
    .SYNOPSIS
    Handle item selection change (optional override)

    .PARAMETER item
    Selected item
    #>
    [void] OnItemSelected($item) {
        # Default: update status bar
        if ($null -ne $item -and $item.Count -gt 0 -and $this.StatusBar) {
            $text = if ($item.ContainsKey('text')) { $item.text } elseif ($item.ContainsKey('name')) { $item.name } else { "Item selected" }
            $this.StatusBar.SetLeftText($text)
        }
    }

    <#
    .SYNOPSIS
    Handle item activation (Enter key) (optional override)

    .PARAMETER item
    Activated item
    #>
    [void] OnItemActivated($item) {
        # Default: open inline editor
        $this.EditItem($item)
    }

    <#
    .SYNOPSIS
    Get custom actions beyond Add/Edit/Delete (optional override)

    .OUTPUTS
    Array of action hashtables with Key, Label, Callback properties
    #>
    [array] GetCustomActions() {
        return @()
    }

    # === Component Initialization ===

    <#
    .SYNOPSIS
    Initialize all components
    #>
    hidden [void] _InitializeComponents() {
        # Get terminal size
        $termSize = $this._GetTerminalSize()
        $this.TermWidth = $termSize.Width
        $this.TermHeight = $termSize.Height

        # Initialize TaskStore singleton
        $this.Store = [TaskStore]::GetInstance()

        # Initialize UniversalList
        $this.List = [UniversalList]::new()
        $this.List.SetPosition(0, 3)
        $this.List.SetSize($this.TermWidth, $this.TermHeight - 6)
        $this.List.Title = $this.ScreenTitle
        $this.List.AllowMultiSelect = $this.AllowMultiSelect
        $this.List.AllowInlineEdit = $this.AllowEdit
        $this.List.AllowSearch = $this.AllowSearch

        # Wire up list events (capture $this as $screen for scriptblock scope)
        $screen = $this

        $this.List.OnSelectionChanged = {
            param($item)
            $screen.OnItemSelected($item)
        }

        $this.List.OnItemEdit = {
            param($item)
            $screen.EditItem($item)
        }

        $this.List.OnItemDelete = {
            param($item)
            $screen.DeleteItem($item)
        }

        $this.List.OnItemActivated = {
            param($item)
            $screen.OnItemActivated($item)
        }

        # Initialize FilterPanel
        $this.FilterPanel = [FilterPanel]::new()
        $this.FilterPanel.SetPosition(10, 5)
        $this.FilterPanel.SetSize(80, 12)
        $this.FilterPanel.OnFiltersChanged = {
            param($filters)
            $this._ApplyFilters()
        }

        # Initialize InlineEditor
        $this.InlineEditor = [InlineEditor]::new()
        $this.InlineEditor.SetPosition(10, 5)
        $this.InlineEditor.SetSize(70, 25)
        $this.InlineEditor.OnConfirmed = {
            param($values)
            $this._SaveEditedItem($values)
        }
        $this.InlineEditor.OnCancelled = {
            $this.ShowInlineEditor = $false
            $this.EditorMode = ""
            $this.CurrentEditItem = $null
        }

        # Wire up store events for auto-refresh
        $entityType = $this.GetEntityType()
        switch ($entityType) {
            'task' {
                $this.Store.OnTasksChanged = {
                    param($tasks)
                    $this.RefreshList()
                }
            }
            'project' {
                $this.Store.OnProjectsChanged = {
                    param($projects)
                    $this.RefreshList()
                }
            }
            'timelog' {
                $this.Store.OnTimeLogsChanged = {
                    param($logs)
                    $this.RefreshList()
                }
            }
        }

        # Configure list actions
        $this._ConfigureListActions()
    }

    <#
    .SYNOPSIS
    Configure list actions (Add, Edit, Delete, + custom)
    #>
    hidden [void] _ConfigureListActions() {
        # Capture $this in local variable for use in scriptblocks
        $screen = $this

        if ($this.AllowAdd) {
            $this.List.AddAction('a', 'Add', {
                $screen.AddItem()
            })
        }

        if ($this.AllowEdit) {
            $this.List.AddAction('e', 'Edit', {
                $selectedItem = $screen.List.GetSelectedItem()
                if ($null -ne $selectedItem) {
                    $screen.EditItem($selectedItem)
                }
            })
        }

        if ($this.AllowDelete) {
            $this.List.AddAction('d', 'Delete', {
                $selectedItem = $screen.List.GetSelectedItem()
                if ($null -ne $selectedItem) {
                    $screen.DeleteItem($selectedItem)
                }
            })
        }

        # Add custom actions from subclass
        $customActions = $this.GetCustomActions()
        foreach ($action in $customActions) {
            $this.List.AddAction($action.Key, $action.Label, $action.Callback)
        }
    }

    # === Lifecycle Methods ===

    <#
    .SYNOPSIS
    Called when screen enters view
    #>
    [void] OnEnter() {
        $this.IsActive = $true

        # Set columns
        $columns = $this.GetColumns()
        $this.List.SetColumns($columns)

        # Load data
        $this.LoadData()

        # Update header breadcrumb
        if ($this.Header) {
            $this.Header.SetBreadcrumb(@("Home", $this.ScreenTitle))
        }

        # Update status bar
        if ($this.StatusBar) {
            $itemCount = $this.List._filteredData.Count
            $this.StatusBar.SetLeftText("$itemCount items")
        }
    }

    <#
    .SYNOPSIS
    Called when screen exits view
    #>
    [void] OnExit() {
        $this.IsActive = $false
    }

    # === CRUD Operations ===

    <#
    .SYNOPSIS
    Add a new item
    #>
    [void] AddItem() {
        # DEBUG logging
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] StandardListScreen.AddItem() called"
        }

        $this.EditorMode = 'add'
        $this.CurrentEditItem = @{}
        $fields = $this.GetEditFields($this.CurrentEditItem)

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] Got $($fields.Count) edit fields"
        }

        $this.InlineEditor.SetFields($fields)
        $this.InlineEditor.Title = "Add New"
        $this.ShowInlineEditor = $true

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ShowInlineEditor set to: $($this.ShowInlineEditor)"
        }
    }

    <#
    .SYNOPSIS
    Edit an existing item

    .PARAMETER item
    Item to edit
    #>
    [void] EditItem($item) {
        if ($null -eq $item) {
            return
        }

        $this.EditorMode = 'edit'
        $this.CurrentEditItem = $item
        $fields = $this.GetEditFields($item)
        $this.InlineEditor.SetFields($fields)
        $this.InlineEditor.Title = "Edit"
        $this.ShowInlineEditor = $true
    }

    <#
    .SYNOPSIS
    Delete an item with confirmation

    .PARAMETER item
    Item to delete
    #>
    [void] DeleteItem($item) {
        if ($null -eq $item) {
            return
        }

        # TODO: Show confirmation dialog
        # For now, delete directly

        $entityType = $this.GetEntityType()
        $success = $false

        switch ($entityType) {
            'task' {
                if ($item.ContainsKey('id')) {
                    $success = $this.Store.DeleteTask($item.id)
                }
            }
            'project' {
                if ($item.ContainsKey('name')) {
                    $success = $this.Store.DeleteProject($item.name)
                }
            }
            'timelog' {
                if ($item.ContainsKey('id')) {
                    $success = $this.Store.DeleteTimeLog($item.id)
                }
            }
        }

        if ($success) {
            if ($this.StatusBar) {
                $this.StatusBar.SetLeftText("Item deleted")
            }
        } else {
            if ($this.StatusBar) {
                $this.StatusBar.SetLeftText("Failed to delete: $($this.Store.LastError)")
            }
        }
    }

    <#
    .SYNOPSIS
    Save edited item to store

    .PARAMETER values
    Field values from InlineEditor
    #>
    hidden [void] _SaveEditedItem($values) {
        Write-PmcTuiLog "StandardListScreen._SaveEditedItem: Mode=$($this.EditorMode) Values=$($values | ConvertTo-Json -Compress)" "DEBUG"
        $entityType = $this.GetEntityType()
        $success = $false

        if ($this.EditorMode -eq 'add') {
            # Add new item
            Write-PmcTuiLog "Adding new $entityType with values: $($values | ConvertTo-Json -Compress)" "DEBUG"
            switch ($entityType) {
                'task' {
                    $success = $this.Store.AddTask($values)
                    Write-PmcTuiLog "AddTask returned: $success" "DEBUG"
                }
                'project' {
                    $success = $this.Store.AddProject($values)
                }
                'timelog' {
                    $success = $this.Store.AddTimeLog($values)
                }
            }

            if ($success) {
                if ($this.StatusBar) {
                    $this.StatusBar.SetLeftText("Item added")
                }
            }
        }
        elseif ($this.EditorMode -eq 'edit') {
            # Update existing item
            switch ($entityType) {
                'task' {
                    if ($this.CurrentEditItem.ContainsKey('id')) {
                        $success = $this.Store.UpdateTask($this.CurrentEditItem.id, $values)
                    }
                }
                'project' {
                    if ($this.CurrentEditItem.ContainsKey('name')) {
                        $success = $this.Store.UpdateProject($this.CurrentEditItem.name, $values)
                    }
                }
                'timelog' {
                    # Time logs don't support update - delete and re-add
                    $success = $false
                }
            }

            if ($success) {
                if ($this.StatusBar) {
                    $this.StatusBar.SetLeftText("Item updated")
                }
            }
        }

        if (-not $success) {
            if ($this.StatusBar) {
                $this.StatusBar.SetLeftText("Failed to save: $($this.Store.LastError)")
            }
        }

        # Close editor
        $this.ShowInlineEditor = $false
        $this.EditorMode = ""
        $this.CurrentEditItem = $null
    }

    # === Filtering ===

    <#
    .SYNOPSIS
    Apply filters to list data
    #>
    hidden [void] _ApplyFilters() {
        $this.LoadData()  # Reload data, filters are applied by FilterPanel
    }

    <#
    .SYNOPSIS
    Toggle filter panel visibility
    #>
    [void] ToggleFilterPanel() {
        $this.ShowFilterPanel = -not $this.ShowFilterPanel
    }

    # === Status Messages ===

    <#
    .SYNOPSIS
    Set status message (displayed in status bar or logged)

    .PARAMETER message
    Message to display

    .PARAMETER level
    Message level: info, success, warning, error
    #>
    [void] SetStatusMessage([string]$message, [string]$level = "info") {
        # Log the message
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [$level] $message"
        }

        # If we have a status bar, update it
        if ($this.StatusBar) {
            $this.StatusBar.SetRightText($message)
        }

        # TODO: Could show a temporary overlay notification
    }

    # === List Refresh ===

    <#
    .SYNOPSIS
    Refresh the list (reload data)
    #>
    [void] RefreshList() {
        $this.LoadData()
    }

    # === Input Handling ===

    <#
    .SYNOPSIS
    Handle keyboard input

    .PARAMETER keyInfo
    ConsoleKeyInfo from [Console]::ReadKey($true)

    .OUTPUTS
    True if input was handled, False otherwise
    #>
    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Route to inline editor if shown
        if ($this.ShowInlineEditor) {
            Write-PmcTuiLog "StandardListScreen: Routing to InlineEditor (Key=$($keyInfo.Key))" "DEBUG"
            $handled = $this.InlineEditor.HandleInput($keyInfo)

            # Check if editor closed
            if ($this.InlineEditor.IsConfirmed -or $this.InlineEditor.IsCancelled) {
                $this.ShowInlineEditor = $false
            }

            return $handled
        }

        # Route to filter panel if shown
        if ($this.ShowFilterPanel) {
            $handled = $this.FilterPanel.HandleInput($keyInfo)

            # Esc closes filter panel
            if ($keyInfo.Key -eq 'Escape') {
                $this.ShowFilterPanel = $false
                return $true
            }

            return $handled
        }

        # Global shortcuts
        if ($keyInfo.Key -eq 'F' -and $this.AllowFilter) {
            $this.ToggleFilterPanel()
            return $true
        }

        if ($keyInfo.Key -eq 'R') {
            # Refresh
            $this.RefreshList()
            return $true
        }

        # Route to list
        return $this.List.HandleInput($keyInfo)
    }

    # === Rendering ===

    <#
    .SYNOPSIS
    Render the screen content area

    .OUTPUTS
    ANSI string ready for display
    #>
    [string] RenderContent() {
        # Priority rendering order: editor > filter panel > list

        if ($this.ShowInlineEditor) {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] RenderContent: Rendering InlineEditor"
            }
            return $this.InlineEditor.Render()
        }

        if ($this.ShowFilterPanel) {
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] RenderContent: Rendering FilterPanel"
            }
            # Render list as background, filter panel as overlay
            $listContent = $this.List.Render()
            $filterContent = $this.FilterPanel.Render()
            return $listContent + "`n" + $filterContent
        }

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] RenderContent: Rendering List (ShowInlineEditor=$($this.ShowInlineEditor), ShowFilterPanel=$($this.ShowFilterPanel))"
        }

        return $this.List.Render()
    }

    <#
    .SYNOPSIS
    Render the complete screen

    .OUTPUTS
    ANSI string ready for display
    #>
    [string] Render() {
        $sb = [StringBuilder]::new(8192)

        # Clear screen
        $sb.Append("`e[2J")
        $sb.Append("`e[H")

        # Render menu bar (if exists)
        if ($null -ne $this.MenuBar) {
            $sb.Append($this.MenuBar.Render())
        }

        # Render header (if exists)
        if ($null -ne $this.Header) {
            $sb.Append($this.Header.Render())
        }

        # Render content
        $sb.Append($this.RenderContent())

        # Render footer (if exists)
        if ($null -ne $this.Footer) {
            $sb.Append($this.Footer.Render())
        }

        # Render status bar (if exists)
        if ($null -ne $this.StatusBar) {
            $sb.Append($this.StatusBar.Render())
        }

        return $sb.ToString()
    }

    # === Helper Methods ===

    <#
    .SYNOPSIS
    Get terminal size

    .OUTPUTS
    Hashtable with Width and Height properties
    #>
    hidden [hashtable] _GetTerminalSize() {
        try {
            $width = [Console]::WindowWidth
            $height = [Console]::WindowHeight
            return @{ Width = $width; Height = $height }
        }
        catch {
            # Default size if console not available
            return @{ Width = 120; Height = 40 }
        }
    }
}
