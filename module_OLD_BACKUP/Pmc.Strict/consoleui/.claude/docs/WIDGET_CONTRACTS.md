# Widget System Reference

## Overview
Widgets are reusable UI components that handle their own input and rendering. All screens should delegate to widgets rather than reimplementing input handling.

---

## UniversalList

**Location**: `widgets/UniversalList.ps1`

**Purpose**: Scrollable, selectable list with multi-select support and filtering

### Properties

```powershell
[array]$Items              # Array of items to display
[int]$SelectedIndex        # Currently selected item (0-based)
[int]$ScrollOffset         # Scroll position for viewport
[int]$ViewportHeight       # Visible rows (default 20)
[bool]$MultiSelectEnabled  # Allow multi-select with Space
[hashtable]$SelectedItems  # Selected item tracking (multi-select)
[string]$FilterText        # Current filter string
```

### Methods

#### `[void]Initialize()`
Must be called after construction. Sets up initial state.

#### `[void]SetItems($items)`
Set the list items. Each item should be a hashtable with at least:
- `Display` - String to show
- Other fields for your use

#### `[object]GetSelectedItem()`
Returns currently selected item

#### `[array]GetSelectedItems()`
Returns all selected items (multi-select mode)

#### `[bool]HandleInput($key)`
Process keyboard input. Returns `$true` if consumed, `$false` otherwise.

**Handled keys**:
- Arrow Up/Down - Navigate
- Page Up/Down - Scroll by page
- Home/End - Jump to start/end
- Space - Toggle selection (if MultiSelectEnabled)
- Ctrl+A - Select all (if MultiSelectEnabled)

#### `[void]Render($speedTUI, $startRow)`
Render the list starting at `$startRow`

### Usage Example

```powershell
class MyListScreen : PmcScreen {
    [UniversalList]$list

    [void]Initialize() {
        parent::Initialize()

        $this.list = [UniversalList]::new()
        $this.list.Initialize()
        $this.list.ViewportHeight = 15
        $this.list.MultiSelectEnabled = $true

        $items = @(
            @{ Display = "Item 1"; Id = 1 }
            @{ Display = "Item 2"; Id = 2 }
        )
        $this.list.SetItems($items)
    }

    [void]Show() {
        parent::Show()
        $this.speedTUI.Clear()
        $this.speedTUI.MoveCursor(0, 0)
        $this.speedTUI.Write("=== My List ===")
        $this.list.Render($this.speedTUI, 2)
    }

    [void]ProcessInput($key) {
        parent::ProcessInput($key)

        if ($this.list.HandleInput($key)) {
            return  # Widget consumed input
        }

        if ($key.VirtualKeyCode -eq 13) {  # Enter
            $selected = $this.list.GetSelectedItem()
            # Do something with selected item
        }
    }
}
```

---

## TextInput

**Location**: `widgets/TextInput.ps1`

**Purpose**: Single-line text input with cursor support

### Properties

```powershell
[string]$Value          # Current text value
[int]$CursorPosition    # Cursor position in string (0-based)
[string]$Prompt         # Optional prompt text
[int]$MaxLength         # Max input length (0 = unlimited)
```

### Methods

#### `[void]Initialize()`
Must be called after construction

#### `[bool]HandleInput($key)`
Process keyboard input. Returns `$true` if consumed.

**Handled keys**:
- Character keys - Insert at cursor
- Backspace - Delete before cursor
- Delete - Delete at cursor
- Arrow Left/Right - Move cursor
- Home/End - Jump to start/end

#### `[void]Render($speedTUI)`
Render the input field at current cursor position

### Usage Example

```powershell
class MyFormScreen : PmcScreen {
    [TextInput]$input

    [void]Initialize() {
        parent::Initialize()

        $this.input = [TextInput]::new()
        $this.input.Initialize()
        $this.input.Prompt = "Enter name: "
        $this.input.Value = ""
    }

    [void]Show() {
        parent::Show()
        $this.speedTUI.Clear()
        $this.speedTUI.MoveCursor(0, 2)
        $this.input.Render($this.speedTUI)
    }

    [void]ProcessInput($key) {
        parent::ProcessInput($key)

        if ($this.input.HandleInput($key)) {
            return
        }

        if ($key.VirtualKeyCode -eq 13) {  # Enter
            $value = $this.input.Value
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                $this.OnSubmit($value)
            }
        }
    }
}
```

---

## FilterPanel

**Location**: `widgets/FilterPanel.ps1`

**Purpose**: Overlay filter UI for lists

### Properties

```powershell
[string]$FilterText     # Current filter value
[bool]$IsActive         # Whether filter is visible/active
```

### Methods

#### `[void]Initialize()`
Must be called after construction

#### `[void]Show()`
Display the filter panel

#### `[void]Hide()`
Hide the filter panel

#### `[bool]HandleInput($key)`
Process input when active

#### `[void]Render($speedTUI, $row)`
Render at specified row

### Usage Example

```powershell
class MyListScreen : StandardListScreen {
    [FilterPanel]$filterPanel

    [void]Initialize() {
        parent::Initialize()
        $this.filterPanel = [FilterPanel]::new()
        $this.filterPanel.Initialize()
    }

    [void]ProcessInput($key) {
        parent::ProcessInput($key)

        # F key to toggle filter
        if ($key.Character -eq 'f') {
            if ($this.filterPanel.IsActive) {
                $this.filterPanel.Hide()
            } else {
                $this.filterPanel.Show()
            }
            return
        }

        if ($this.filterPanel.IsActive) {
            if ($this.filterPanel.HandleInput($key)) {
                $this.ApplyFilter($this.filterPanel.FilterText)
                return
            }
        }
    }
}
```

---

## ProjectPicker

**Location**: `widgets/ProjectPicker.ps1`

**Purpose**: Project selection widget (likely uses UniversalList internally)

### Properties

```powershell
[string]$SelectedProjectId
[array]$Projects
```

### Methods

#### `[void]Initialize()`
Must be called after construction

#### `[bool]HandleInput($key)`
Process input

#### `[void]Render($speedTUI, $row)`
Render at specified row

#### `[string]GetSelectedProject()`
Get currently selected project ID

### Usage Example

```powershell
class TaskFormScreen : PmcScreen {
    [ProjectPicker]$projectPicker

    [void]Initialize() {
        parent::Initialize()

        $this.projectPicker = [ProjectPicker]::new($this.app)
        $this.projectPicker.Initialize()
        $this.projectPicker.Projects = $this.app.taskStore.GetProjects()
    }

    [void]ProcessInput($key) {
        parent::ProcessInput($key)

        if ($this.projectPicker.HandleInput($key)) {
            return
        }

        if ($key.VirtualKeyCode -eq 13) {
            $projectId = $this.projectPicker.GetSelectedProject()
            # Use project ID
        }
    }
}
```

---

## InlineEditor

**Location**: `widgets/InlineEditor.ps1`

**Purpose**: Multi-line text editor widget

### Properties

```powershell
[array]$Lines               # Array of text lines
[int]$CursorRow             # Current row
[int]$CursorCol             # Current column
[int]$ScrollOffset          # Vertical scroll position
[int]$ViewportHeight        # Visible rows
```

### Methods

#### `[void]Initialize()`
Must be called after construction

#### `[void]SetText($text)`
Set content (splits into lines)

#### `[string]GetText()`
Get content (joins lines)

#### `[bool]HandleInput($key)`
Process keyboard input

**Handled keys**:
- Character keys - Insert at cursor
- Enter - New line
- Backspace/Delete - Delete characters
- Arrow keys - Navigate
- Page Up/Down - Scroll

#### `[void]Render($speedTUI, $startRow)`
Render editor at specified row

### Usage Example

```powershell
class NoteEditorScreen : PmcScreen {
    [InlineEditor]$editor

    [void]Initialize() {
        parent::Initialize()

        $this.editor = [InlineEditor]::new()
        $this.editor.Initialize()
        $this.editor.ViewportHeight = 20

        $note = $this.app.noteService.GetNote($this.State.NoteId)
        $this.editor.SetText($note.Content)
    }

    [void]Show() {
        parent::Show()
        $this.speedTUI.Clear()
        $this.speedTUI.MoveCursor(0, 0)
        $this.speedTUI.Write("=== Note Editor (Ctrl+S to save) ===")
        $this.editor.Render($this.speedTUI, 2)
    }

    [void]ProcessInput($key) {
        parent::ProcessInput($key)

        # Ctrl+S to save
        if ($key.Character -eq 's' -and $key.ControlKeyState -band 0x08) {
            $content = $this.editor.GetText()
            $this.SaveNote($content)
            return
        }

        if ($this.editor.HandleInput($key)) {
            return
        }
    }
}
```

---

## Widget Design Principles

### 1. Delegation Pattern
Screens should ALWAYS delegate input to widgets first:

```powershell
[void]ProcessInput($key) {
    parent::ProcessInput($key)

    # Widget input FIRST
    if ($this.widget.HandleInput($key)) {
        return
    }

    # Screen-specific input AFTER
    # ...
}
```

### 2. Stateless Rendering
Widgets should not rely on screen state. All necessary data passed via properties or Render parameters.

### 3. Initialization Required
All widgets require explicit `Initialize()` call after construction.

### 4. Boolean Return Convention
`HandleInput()` returns:
- `$true` - Input consumed, screen should not process further
- `$false` - Input not handled, screen can process

### 5. Render Positioning
Widgets should render at position provided by screen, not hardcoded positions.

---

## Common Widget Integration Mistakes

### ❌ Not calling Initialize
```powershell
$this.widget = [TextInput]::new()
# Missing: $this.widget.Initialize()
```

### ❌ Processing input before delegating
```powershell
[void]ProcessInput($key) {
    if ($key.Character -eq 'a') {
        # Should let widget handle character input
    }
    $this.widget.HandleInput($key)
}
```

### ❌ Ignoring HandleInput return value
```powershell
[void]ProcessInput($key) {
    $this.widget.HandleInput($key)
    # Still processing input even if widget consumed it
    if ($key.VirtualKeyCode -eq 13) {
        # ...
    }
}
```

### ❌ Not re-rendering after widget state change
```powershell
[void]ProcessInput($key) {
    if ($this.widget.HandleInput($key)) {
        return  # Correct delegation
    }
    # But Show() must be called to see changes
}
```
**Note**: Framework typically handles re-render, but be aware of this.

---

## To Be Documented
- Widget lifecycle in detail
- Creating custom widgets
- Widget composition patterns
- Advanced widget features (validation, formatting, etc.)
