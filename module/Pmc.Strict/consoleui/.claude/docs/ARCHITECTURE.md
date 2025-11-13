# PMC TUI Architecture

## Overview
The PMC TUI is a PowerShell-based terminal user interface for project management tasks. Built on SpeedTUI rendering engine with VT100 escape codes.

## Core Components

### PmcScreen (Base Class)
Location: `PmcScreen.ps1`

Base class for all TUI screens. Provides:
- **Rendering lifecycle**: `Initialize()` → `Show()` → `ProcessInput()` → `Cleanup()`
- **Navigation**: `$this.NavigateTo()`, `$this.NavigateBack()`
- **State management**: `$this.State` hashtable for screen-specific data
- **SpeedTUI integration**: `$this.speedTUI` instance for rendering

Key methods all screens must implement:
- `Initialize()` - Setup screen state, load data
- `Show()` - Render screen content
- `ProcessInput($key)` - Handle keyboard input
- `Cleanup()` - Teardown resources

### PmcApplication
Location: `PmcApplication.ps1`

Application controller that manages:
- Screen navigation stack
- Global application state
- Service initialization (TaskStore, PreferencesService)
- Main event loop

## Screen Types

### Menu Screens
**Purpose**: Present list of options to user

**Standard structure**:
```powershell
class MyMenuScreen : PmcScreen {
    [array]$menuItems
    [int]$selectedIndex = 0

    [void]Initialize() {
        parent::Initialize()
        $this.menuItems = @(
            @{Label="Option 1"; Action={...}}
            @{Label="Option 2"; Action={...}}
        )
    }

    [void]ProcessInput($key) {
        parent::ProcessInput($key)  # MUST call first
        # Handle arrow keys to move selectedIndex
        # Handle Enter to invoke action
    }
}
```

**Examples**: ChecklistsMenuScreen, NotesMenuScreen, KanbanScreen

### Form Screens
**Purpose**: Collect user input (single or multiple fields)

**Standard structure**:
```powershell
class MyFormScreen : PmcScreen {
    [object]$widget  # TextInput or other input widget

    [void]Initialize() {
        parent::Initialize()
        $this.widget = [TextInput]::new()
        $this.widget.Initialize()
    }

    [void]ProcessInput($key) {
        parent::ProcessInput($key)
        if ($this.widget.HandleInput($key)) {
            # Widget consumed input
            return
        }
        # Handle form submission, navigation
    }
}
```

**Examples**: FocusSetFormScreen, SearchFormScreen, DepAddFormScreen

### List Screens
**Purpose**: Display scrollable data lists with filtering/selection

**Standard structure**:
```powershell
class MyListScreen : StandardListScreen {
    [void]LoadData() {
        # Load items from TaskStore or other service
        $this.items = @(...)
    }

    [void]OnItemSelected($item) {
        # Handle item selection
    }
}
```

**Examples**: TaskListScreen, ProjectListScreen, TimeListScreen

## Widget System

### UniversalList
Location: `widgets/UniversalList.ps1`

Generic list widget with:
- Scrolling with arrow keys/Page Up/Page Down
- Multi-select mode (Space to toggle, Ctrl+A for all)
- Filtering support
- Custom rendering per item

### TextInput
Location: `widgets/TextInput.ps1`

Single-line text input with:
- Cursor management
- Backspace/Delete support
- Character insertion at cursor position

### FilterPanel
Location: `widgets/FilterPanel.ps1`

Filter UI overlay for lists

### ProjectPicker
Location: `widgets/ProjectPicker.ps1`

Project selection widget

## Service Layer

### TaskStore
Location: `services/TaskStore.ps1`

Central data store for tasks. Methods:
- `GetAllTasks()` - Retrieve all tasks
- `AddTask($task)` - Create new task
- `UpdateTask($task)` - Update existing task
- `DeleteTask($id)` - Remove task
- `Save()` - Persist to disk
- `Load()` - Load from disk

**Important**: Always call `.Save()` after mutations!

### PreferencesService
Location: `services/PreferencesService.ps1`

User preferences storage (filters, view settings, etc.)

### ExcelComReader
Location: `services/ExcelComReader.ps1`

Excel import functionality via COM interop

## Rendering Flow

1. Application calls `$screen.Initialize()`
2. Application calls `$screen.Show()`
   - Screen uses `$this.speedTUI.MoveCursor()`, `.Write()`, etc.
   - SpeedTUI buffers VT100 commands
3. SpeedTUI flushes buffer to stdout
4. User presses key
5. Application calls `$screen.ProcessInput($key)`
6. Goto step 2 (re-render)

## Navigation Pattern

```powershell
# Navigate to new screen
$this.NavigateTo([TaskListScreen]::new($this.app))

# Navigate back
$this.NavigateBack()

# Pass data to next screen
$nextScreen = [TaskDetailScreen]::new($this.app)
$nextScreen.State.TaskId = $taskId
$this.NavigateTo($nextScreen)
```

## Common Patterns

### Cursor Management in Menus
```powershell
# Arrow up
if ($key.VirtualKeyCode -eq 38) {
    if ($this.selectedIndex -gt 0) {
        $this.selectedIndex--
    }
}

# Arrow down
if ($key.VirtualKeyCode -eq 40) {
    if ($this.selectedIndex -lt ($this.menuItems.Count - 1)) {
        $this.selectedIndex++
    }
}
```

### Parent Call Pattern
**CRITICAL**: Always call `parent::ProcessInput($key)` at the START of ProcessInput to handle common keys (Escape for back, etc.)

### Widget Integration
```powershell
[void]Initialize() {
    parent::Initialize()
    $this.myWidget = [SomeWidget]::new()
    $this.myWidget.Initialize()
}

[void]Show() {
    parent::Show()
    $this.myWidget.Render($this.speedTUI)
}

[void]ProcessInput($key) {
    parent::ProcessInput($key)
    if ($this.myWidget.HandleInput($key)) {
        return  # Widget consumed input
    }
    # Handle other keys
}
```

## To Be Documented
- Exact initialization order
- Theme system
- Layout system
- Error handling patterns
- State persistence between navigation
