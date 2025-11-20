# EditableGrid Architecture

## Overview

The EditableGrid system provides Excel-style inline editing for PowerShell TUI applications. It was designed to replace the hacky inline editing in TaskListScreen with a proper, reusable grid editing framework.

## Architecture

```
TaskGridScreen : GridScreen : StandardListScreen
    └─ EditableGrid : UniversalList
         ├─ GridCell[] (cell models)
         ├─ CellEditorRegistry (factory)
         ├─ ThemedCellRenderer (rendering)
         └─ GridChangeTracker (undo/redo)
```

## Core Components

### 1. GridCell (widgets/GridCell.ps1)

**Purpose**: Encapsulates the state of a single cell in the grid.

**Key Features**:
- Edit lifecycle: `BeginEdit()`, `CommitEdit()`, `CancelEdit()`
- Cursor management: position tracking, text insertion/deletion
- Validation: error tracking, validation callbacks
- Dirty tracking: `IsDirty` flag for unsaved changes
- Snapshot/restore for undo/redo
- Separate display vs edit values

**Properties**:
- `RowId`, `ColumnName`: Cell location
- `OriginalValue`, `EditValue`: Data state
- `IsEditing`, `IsDirty`, `IsValid`: Status flags
- `CursorPos`: Cursor position within edit string
- `ValidationError`: Error message if validation fails
- `Metadata`: Additional cell configuration (formatters, etc.)

**Methods**:
- `BeginEdit()`: Start editing
- `CommitEdit($validator)`: Save with validation
- `CancelEdit()`: Discard changes
- `InsertTextAtCursor($text)`: Insert text at cursor
- `DeleteCharBeforeCursor()`: Backspace
- `DeleteCharAfterCursor()`: Delete
- `MoveCursor*()`: Cursor navigation
- `GetDisplayValue()`: Formatted display
- `GetEditValue()`: Raw edit value

### 2. CellEditor (widgets/CellEditor.ps1)

**Purpose**: Handles keyboard input for different cell types.

**Base Class**: `CellEditor`
- `HandleKey($cell, $key)`: Process keystroke
- `Validate($value)`: Validate value
- `FormatDisplay($value)`: Format for display
- `FormatEdit($value)`: Format for editing

**Implementations**:

#### TextCellEditor
- String input with optional max length
- Pattern validation (regex)
- Allow/disallow empty

**Options**:
```powershell
@{
    MaxLength = 200
    Pattern = '^[a-zA-Z0-9 ]+$'
    AllowEmpty = $false
}
```

#### NumberCellEditor
- Numeric input only (digits, minus, decimal)
- Min/max range validation
- Allow/disallow decimals and negatives

**Options**:
```powershell
@{
    MinValue = 1
    MaxValue = 5
    AllowDecimals = $false
    AllowNegative = $false
}
```

#### CheckboxCellEditor
- Boolean toggle with Space/Enter
- Customizable display (`[X]` / `[ ]`)

**Options**:
```powershell
@{
    TrueDisplay = '[X]'
    FalseDisplay = '[ ]'
}
```

#### WidgetCellEditor
- Launches popup widgets (DatePicker, ProjectPicker, TagEditor)
- Fallback to text editing
- Widget-specific formatting

**Types**: `'date'`, `'project'`, `'tags'`

### 3. CellEditorRegistry (widgets/CellEditorRegistry.ps1)

**Purpose**: Factory for creating appropriate editors per column.

**Key Methods**:
- `RegisterEditor($columnName, $editor)`: Register custom editor
- `RegisterTextEditor($columnName, $options)`: Register text editor with options
- `RegisterNumberEditor($columnName, $options)`: Register number editor
- `RegisterCheckboxEditor($columnName, $options)`: Register checkbox editor
- `RegisterWidgetEditor($columnName, $widgetType, $factory)`: Register widget editor
- `GetEditor($columnName, $value)`: Get editor for column (registered or default)

**Pre-configured Registries**:
- `CreateTaskListRegistry()`: Task-specific editors
- `CreateProjectListRegistry()`: Project-specific editors
- `CreateContextListRegistry()`: Context-specific editors

**Example**:
```powershell
$registry = [CellEditorRegistry]::new()
$registry.RegisterTextEditor('title', @{ MaxLength = 200; AllowEmpty = $false })
$registry.RegisterNumberEditor('priority', @{ MinValue = 1; MaxValue = 5 })
$registry.RegisterWidgetEditor('due', 'date')
```

### 4. ThemedCellRenderer (widgets/ThemedCellRenderer.ps1)

**Purpose**: Theme-aware rendering of cells with proper ANSI codes.

**Key Methods**:
- `RenderCell($cell, $width, $isSelected, $isEditing)`: Render cell with theme colors
- `RenderCellWithCursor($cell, $width, $isSelected)`: Render with cursor highlighting
- `RenderHeader($headerText, $width, $isActiveColumn)`: Render column header
- `RenderValidationError($errorMessage, $width)`: Render error message

**Theme Colors Used**:
- **Normal**: `ListFG`, `ListBG`
- **Selected**: `SelectedFG`, `SelectedBG`
- **Editing**: `AccentFG`, `AccentBG`
- **Error**: `ErrorFG`, `ErrorBG`
- **Dirty indicator**: Yellow asterisk

**Features**:
- Dirty indicator (`*`) for modified cells
- Cursor highlighting with reverse video
- Validation error display
- Padding/truncation to fit column width

### 5. GridChangeTracker (widgets/GridChangeTracker.ps1)

**Purpose**: Track changes with undo/redo capability.

**Classes**:

#### GridChange
- Represents a single change operation
- Properties: `ChangeType` (`'edit'`, `'insert'`, `'delete'`), `RowId`, `ColumnName`, `OldValue`, `NewValue`, `Timestamp`
- `CreateInverse()`: Create inverse for undo
- `GetDescription()`: Human-readable description

#### GridChangeTracker
- Maintains undo/redo stacks
- `TrackEdit($rowId, $columnName, $oldValue, $newValue)`: Record edit
- `TrackInsert($rowId, $rowData)`: Record insertion
- `TrackDelete($rowId, $rowData)`: Record deletion
- `Undo()`: Undo last change
- `Redo()`: Redo last undone change
- `CanUndo()`, `CanRedo()`: Check availability
- `MarkAllSaved()`: Clear after save
- `CreateSavepoint()`, `RollbackToSavepoint()`: Transaction support

#### GridChangeBatch
- Groups multiple changes into atomic operation
- `AddChange()`: Add to batch
- `Commit()`: Apply all changes
- `Rollback()`: Discard all changes

**Configuration**:
- `MaxUndoLevels`: Default 100
- `IsEnabled`: Toggle undo/redo

### 6. EditableGrid (widgets/EditableGrid.ps1)

**Purpose**: Main grid widget extending UniversalList with editing capabilities.

**Key Properties**:
- `EditorRegistry`: Cell editor factory
- `CellRenderer`: Theme-aware renderer
- `ChangeTracker`: Undo/redo manager
- `AutoCommitOnMove`: Auto-save when navigating
- `EnableUndo`: Enable undo/redo
- `ShowDirtyIndicator`: Show `*` for modified cells
- `InlineValidation`: Validate on every keystroke

**Key Methods**:

#### Initialization
- `InitializeRenderer($themeManager)`: Set up renderer
- `SetEditableColumns($columnNames)`: Configure editable columns

#### Editing
- `BeginEdit($columnName)`: Start editing cell
- `CommitEdit()`: Save changes with validation
- `CancelEdit()`: Discard changes

#### Navigation
- `HandleKey($key)`: Process keyboard input
- `_MoveToNextEditableColumn()`: Navigate right (skips read-only)
- `_MoveToPreviousEditableColumn()`: Navigate left (skips read-only)
- `_GetFirstEditableColumnIndex()`: Find first editable
- `_GetLastEditableColumnIndex()`: Find last editable

#### Undo/Redo
- `Undo()`: Undo last change (Ctrl+Z)
- `Redo()`: Redo last undone change (Ctrl+Y)

#### State
- `HasUnsavedChanges()`: Check for dirty cells
- `GetDirtyCells()`: Get all modified cells

**Keyboard Shortcuts**:
- **Enter**: Begin editing / commit and move down
- **Tab**: Move to next column (Shift+Tab for previous)
- **Arrow Keys**: Navigate cells
- **Home/End**: First/last column
- **Ctrl+Home/End**: First/last row
- **Ctrl+Z**: Undo
- **Ctrl+Y**: Redo
- **Escape**: Cancel edit
- **Type any character**: Start editing

**Callbacks**:
- `OnCellChanged`: Fired after successful commit
- `OnCellValidationFailed`: Fired when validation fails
- `OnBeforeCellEdit`: Fired before editing starts (can cancel)

### 7. GridScreen (screens/GridScreen.ps1)

**Purpose**: Base class for screens using EditableGrid.

**Extends**: `StandardListScreen`

**Key Methods**:

#### Override Points
- `GetColumns()`: Define grid columns
- `GetEditableColumns()`: Specify editable columns
- `_ConfigureCellEditors()`: Configure editors
- `_SaveDirtyCells($dirtyCells)`: Save changes to data source
- `_OnCellChanged($cell)`: Handle cell change
- `_OnCellValidationFailed($cell)`: Handle validation error
- `_OnBeforeCellEdit($cell)`: Intercept before edit

#### Built-in Operations
- `SaveChanges()`: Save all dirty cells
- `DiscardChanges()`: Revert all changes
- `UndoChange()`: Undo last change
- `RedoChange()`: Redo last undone change

#### Menu Integration
- Adds Save, Undo, Redo, Discard to menu
- Shows unsaved indicator

**Example**:
```powershell
class MyGridScreen : GridScreen {
    [array] GetColumns() {
        return @(
            @{
                Name = 'title'
                Label = 'Title'
                Width = 40
                Editable = $true
                Type = 'text'
                Validator = { param($value)
                    if ($value.Length -gt 200) {
                        return @{ IsValid = $false; Error = 'Too long' }
                    }
                    return @{ IsValid = $true; Error = $null }
                }
            }
        )
    }

    [string[]] GetEditableColumns() {
        return @('title', 'details', 'status')
    }

    [void] _ConfigureCellEditors() {
        $this.Grid.EditorRegistry.RegisterTextEditor('title', @{
            MaxLength = 200
            AllowEmpty = $false
        })
    }

    [bool] _SaveDirtyCells([GridCell[]]$dirtyCells) {
        # Save to data source
        foreach ($cell in $dirtyCells) {
            # Update database, file, API, etc.
        }
        return $true
    }
}
```

### 8. TaskGridScreen (screens/TaskGridScreen.ps1)

**Purpose**: Grid-based task list implementation.

**Extends**: `GridScreen`

**Columns**:
- **title**: Text (required, max 200 chars)
- **details**: Text (optional)
- **priority**: Number (1-5)
- **due**: Date (widget editor)
- **project**: Text (widget editor)
- **tags**: Text (widget editor, comma-separated)
- **status**: Text (TODO/IN_PROGRESS/DONE/BLOCKED)
- **id**: Hidden (read-only)

**Features**:
- Color-coded priority (red=high, yellow=medium, green=low)
- Color-coded due dates (red=overdue, yellow=today, green=future)
- Color-coded status
- View modes: all, active, completed, overdue, today
- Sorting by any column
- TaskStore integration

**Data Flow**:
```
User types → CellEditor.HandleKey() → GridCell.InsertText()
          → Grid.InvalidateCache() → Cell rendered with cursor
User presses Enter → Grid.CommitEdit() → GridCell.CommitEdit()
                   → Validator runs → GridChangeTracker.TrackEdit()
                   → TaskGridScreen._SaveDirtyCells()
                   → TaskStore.UpdateTask()
```

## Integration with Start-PmcTUI.ps1

**Load Order** (critical for class dependencies):

1. **Widgets** (line 176-181):
   - GridCell.ps1
   - CellEditor.ps1
   - CellEditorRegistry.ps1
   - ThemedCellRenderer.ps1
   - GridChangeTracker.ps1
   - EditableGrid.ps1

2. **Base Classes** (line 215):
   - GridScreen.ps1

3. **Screens** (line 254-255):
   - TaskGridScreen.ps1

## PowerShell Strict Mode Considerations

**Issue**: Switch statements in methods returning values must have explicit fallback return.

**Solution**: Add `return` statement after switch closes:

```powershell
[string] FormatDisplay([object]$value) {
    switch ($this.Type) {
        'date' { return $value.ToString('yyyy-MM-dd') }
        'number' { return $value.ToString() }
        default { return $value.ToString() }
    }
    # Fallback return (satisfies strict mode)
    return $value.ToString()
}
```

**Files Fixed**:
- CellEditor.ps1:342 (`WidgetCellEditor.FormatDisplay`)
- GridChangeTracker.ps1:29 (`GridChange.GetDescription`)
- TaskGridScreen.ps1:323 (`_GetTasksForView`)

## Usage Examples

### Basic Grid Creation

```powershell
# Create grid
$options = @{ Columns = $columns; Items = @() }
$grid = [EditableGrid]::new($options)

# Initialize renderer
$grid.InitializeRenderer($themeManager)

# Configure editors
$grid.EditorRegistry.RegisterTextEditor('name', @{ MaxLength = 100 })
$grid.EditorRegistry.RegisterNumberEditor('age', @{ MinValue = 0; MaxValue = 120 })

# Set editable columns
$grid.SetEditableColumns(@('name', 'age', 'email'))

# Handle input
$key = [Console]::ReadKey($true)
$grid.HandleKey($key)

# Render
$output = $grid.Render($width, $height)
```

### Cell Editing

```powershell
# Start editing
$grid.BeginEdit('title')

# User types...
$grid.HandleKey($key)  # Automatically updates cell

# Commit
$success = $grid.CommitEdit()  # Returns false if validation fails

# Or cancel
$grid.CancelEdit()
```

### Undo/Redo

```powershell
# Make changes
$grid.BeginEdit('title')
# ... edit ...
$grid.CommitEdit()

# Undo
$grid.Undo()

# Redo
$grid.Redo()

# Check availability
if ($grid.ChangeTracker.CanUndo()) {
    # Undo available
}
```

### Custom Validators

```powershell
@{
    Name = 'email'
    Validator = { param($value)
        if ($value -notmatch '^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$') {
            return @{ IsValid = $false; Error = 'Invalid email format' }
        }
        return @{ IsValid = $true; Error = $null }
    }
}
```

### Custom Formatters

```powershell
@{
    Name = 'due'
    DisplayFormatter = { param($value)
        $date = [DateTime]::Parse($value)
        if ($date.Date -eq [DateTime]::Today) { return "Today" }
        return $date.ToString('MMM dd')
    }
    EditFormatter = { param($value)
        $date = [DateTime]::Parse($value)
        return $date.ToString('yyyy-MM-dd')
    }
}
```

## Implementation Status

### Phase 3: Menu Integration ✅ COMPLETE

**Completed**: Grid mode is now accessible via Tasks menu.

**Changes Made**:
1. **MenuItems.psd1**: Added TaskGridScreen entry
   - Menu: Tasks
   - Label: "Grid View (Excel-style)"
   - Hotkey: 'G'
   - Order: 53 (between Agenda and Kanban)
   - ScreenFile: TaskGridScreen.ps1

2. **GridScreen.ps1**: Added DI constructor
   - `GridScreen([string]$screenId, [string]$title)` - backward compatible
   - `GridScreen([string]$screenId, [string]$title, [object]$container)` - DI-enabled

3. **TaskGridScreen.ps1**: Added DI constructor
   - `TaskGridScreen()` - backward compatible
   - `TaskGridScreen([object]$container)` - DI-enabled for menu system

**Usage**:
- Launch TUI: `pwsh Start-PmcTUI.ps1`
- Press ESC to open menu
- Navigate to Tasks → Grid View (Excel-style) or press 'G'
- Excel-style inline editing active!

**Testing**:
- ✅ Classes load without errors
- ✅ Strict mode compliant
- ✅ Menu entry registered
- ✅ DI container integration working

## Future Enhancements

### Phase 4: Widget Integration (Next)
- Connect WidgetCellEditor to actual DatePicker, ProjectPicker, TagEditor
- Widget positioning at cell coordinates
- Widget result handling

### Phase 4: Advanced Features
- Column visibility toggle
- Column reordering
- Column resizing
- Multi-cell selection
- Copy/paste
- Find/replace
- Sorting by clicking header
- Filtering

### Phase 5: Performance
- Virtual scrolling for large datasets
- Lazy cell creation
- Render optimization

### Phase 6: Hierarchical Data
- Tree grid with expand/collapse
- Parent-child relationships
- Indentation rendering

## Testing

**Strict Mode Validation**:
```bash
pwsh -NoProfile -Command "
    Set-StrictMode -Version Latest
    . ./widgets/GridCell.ps1
    . ./widgets/CellEditor.ps1
    # ... all classes ...
    'All classes loaded successfully'
"
```

**Instantiation Test**:
```powershell
$cell = [GridCell]::new('row1', 'title', 'Test')
$editor = [TextCellEditor]::new()
$registry = [CellEditorRegistry]::new()
$tracker = [GridChangeTracker]::new()
```

**Full TUI Test**:
```bash
pwsh Start-PmcTUI.ps1
# Check for errors in console output
```

## Files Created

```
consoleui/
├── widgets/
│   ├── GridCell.ps1              (Cell model)
│   ├── CellEditor.ps1             (Base + 4 editor types)
│   ├── CellEditorRegistry.ps1     (Factory)
│   ├── ThemedCellRenderer.ps1     (Rendering)
│   ├── GridChangeTracker.ps1      (Undo/redo)
│   └── EditableGrid.ps1           (Main grid widget)
├── screens/
│   ├── GridScreen.ps1             (Base screen class)
│   └── TaskGridScreen.ps1         (Task implementation)
└── GRID_ARCHITECTURE.md           (This file)
```

## Summary

The EditableGrid architecture provides a complete, reusable solution for Excel-style inline editing in PowerShell TUI applications. It separates concerns (cell state, editing behavior, rendering, change tracking) into cohesive classes that work together through well-defined interfaces. The system is extensible (custom editors, validators, formatters), theme-aware, and fully compatible with PowerShell strict mode.

**Key Benefits**:
- ✅ Excel-style interaction (type-to-edit)
- ✅ Full undo/redo support
- ✅ Per-column validation
- ✅ Theme integration
- ✅ Extensible editor system
- ✅ Change tracking
- ✅ PowerShell strict mode compliant
- ✅ Reusable across all list screens
