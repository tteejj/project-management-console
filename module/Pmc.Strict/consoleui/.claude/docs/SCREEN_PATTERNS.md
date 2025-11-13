# Screen Implementation Patterns

This document describes the standard patterns for implementing different types of screens.

## Pattern Categories

### 1. Menu Screen Pattern

**When to use**: Presenting a list of options/actions to the user

**Required components**:
- `$this.menuItems` - Array of menu item hashtables
- `$this.selectedIndex` - Current cursor position (0-based)

**Standard implementation**:
```powershell
class ExampleMenuScreen : PmcScreen {
    [array]$menuItems
    [int]$selectedIndex = 0

    [void]Initialize() {
        parent::Initialize()

        $this.menuItems = @(
            @{
                Label = "Option 1"
                Action = { $this.DoSomething() }
            }
            @{
                Label = "Option 2"
                Action = { $this.NavigateTo([OtherScreen]::new($this.app)) }
            }
        )
    }

    [void]Show() {
        parent::Show()

        $this.speedTUI.Clear()
        $this.speedTUI.MoveCursor(0, 0)
        $this.speedTUI.Write("=== Menu Title ===")

        $row = 2
        for ($i = 0; $i -lt $this.menuItems.Count; $i++) {
            $item = $this.menuItems[$i]
            $this.speedTUI.MoveCursor(0, $row)

            if ($i -eq $this.selectedIndex) {
                $this.speedTUI.Write("> " + $item.Label, $true)  # Highlight
            } else {
                $this.speedTUI.Write("  " + $item.Label)
            }
            $row++
        }
    }

    [void]ProcessInput($key) {
        parent::ProcessInput($key)  # MUST CALL FIRST

        # Arrow Up (VK 38)
        if ($key.VirtualKeyCode -eq 38) {
            if ($this.selectedIndex -gt 0) {
                $this.selectedIndex--
            }
        }

        # Arrow Down (VK 40)
        if ($key.VirtualKeyCode -eq 40) {
            if ($this.selectedIndex -lt ($this.menuItems.Count - 1)) {
                $this.selectedIndex++
            }
        }

        # Enter (VK 13)
        if ($key.VirtualKeyCode -eq 13) {
            $action = $this.menuItems[$this.selectedIndex].Action
            if ($action) {
                & $action
            }
        }
    }
}
```

**Examples in codebase**:
- `screens/ChecklistsMenuScreen.ps1`
- `screens/NotesMenuScreen.ps1`
- `screens/KanbanScreen.ps1`

**Common mistakes**:
- Forgetting to call `parent::ProcessInput($key)` first
- Not bounds-checking `$this.selectedIndex` when using arrow keys
- Initializing `$this.selectedIndex` to null instead of 0

---

### 2. Form Screen Pattern

**When to use**: Collecting user input (text, selections, etc.)

**Required components**:
- Widget instance (TextInput, ProjectPicker, etc.)
- Input handling delegation to widget
- Submission logic

**Standard implementation**:
```powershell
class ExampleFormScreen : PmcScreen {
    [TextInput]$textInput
    [string]$label

    [void]Initialize() {
        parent::Initialize()

        $this.label = "Enter value:"
        $this.textInput = [TextInput]::new()
        $this.textInput.Initialize()
        $this.textInput.Value = ""  # Default value
    }

    [void]Show() {
        parent::Show()

        $this.speedTUI.Clear()
        $this.speedTUI.MoveCursor(0, 0)
        $this.speedTUI.Write("=== Form Title ===")

        $this.speedTUI.MoveCursor(0, 2)
        $this.speedTUI.Write($this.label)

        $this.speedTUI.MoveCursor(0, 3)
        $this.textInput.Render($this.speedTUI)
    }

    [void]ProcessInput($key) {
        parent::ProcessInput($key)

        # Delegate to widget first
        if ($this.textInput.HandleInput($key)) {
            return  # Widget consumed the input
        }

        # Handle Enter for submission (VK 13)
        if ($key.VirtualKeyCode -eq 13) {
            $value = $this.textInput.Value
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                $this.OnSubmit($value)
            }
        }
    }

    [void]OnSubmit($value) {
        # Do something with the value
        # Save to TaskStore, navigate to next screen, etc.
    }
}
```

**Examples in codebase**:
- `screens/FocusSetFormScreen.ps1`
- `screens/SearchFormScreen.ps1`
- `screens/DepAddFormScreen.ps1`

**Common mistakes**:
- Not checking if widget consumed input before handling keys
- Missing null/empty validation before submission
- Forgetting to call widget's `Initialize()` method

---

### 3. List Screen Pattern (extends StandardListScreen)

**When to use**: Displaying scrollable, selectable lists of data

**Required components**:
- Inherit from `StandardListScreen` (which uses UniversalList internally)
- Implement `LoadData()` to populate items
- Implement `OnItemSelected($item)` for selection handling

**Standard implementation**:
```powershell
class ExampleListScreen : StandardListScreen {
    [void]Initialize() {
        parent::Initialize()
        $this.Title = "My List"
        $this.LoadData()
    }

    [void]LoadData() {
        # Load from TaskStore or other service
        $tasks = $this.app.taskStore.GetAllTasks()
        $this.items = $tasks | ForEach-Object {
            @{
                Id = $_.Id
                Display = "$($_.Title) - $($_.Status)"
                Data = $_
            }
        }
    }

    [void]OnItemSelected($item) {
        # Navigate to detail screen
        $detailScreen = [TaskDetailScreen]::new($this.app)
        $detailScreen.State.TaskId = $item.Id
        $this.NavigateTo($detailScreen)
    }
}
```

**StandardListScreen provides**:
- `$this.items` - Array of items to display
- `$this.universalList` - UniversalList widget instance
- Arrow key handling, scrolling, Page Up/Down
- Multi-select mode (if enabled)

**Examples in codebase**:
- `screens/TaskListScreen.ps1`
- `screens/ProjectListScreen.ps1`
- `screens/TimeListScreen.ps1`

**Common mistakes**:
- Not setting `$this.Title` before calling parent Initialize
- Forgetting to call `LoadData()` in Initialize
- Not handling empty item lists

---

## Cross-Cutting Patterns

### Parent Method Call Pattern
**CRITICAL**: All screens must call parent methods to inherit base behavior

```powershell
[void]Initialize() {
    parent::Initialize()  # ALWAYS FIRST
    # Your initialization
}

[void]Show() {
    parent::Show()  # ALWAYS FIRST
    # Your rendering
}

[void]ProcessInput($key) {
    parent::ProcessInput($key)  # ALWAYS FIRST
    # Your input handling
}
```

**Why**: Parent class handles:
- Common keyboard shortcuts (Escape to go back, etc.)
- State initialization
- SpeedTUI setup

---

### State Passing Pattern
When navigating between screens and need to pass data:

```powershell
# From source screen
$nextScreen = [TargetScreen]::new($this.app)
$nextScreen.State.ItemId = $selectedItemId
$nextScreen.State.Mode = "edit"
$this.NavigateTo($nextScreen)

# In target screen Initialize()
[void]Initialize() {
    parent::Initialize()
    $itemId = $this.State.ItemId
    $mode = $this.State.Mode
    # Use the data
}
```

---

### Data Mutation Pattern
When modifying tasks, always save:

```powershell
# Load
$task = $this.app.taskStore.GetTaskById($id)

# Modify
$task.Title = "New Title"

# Save
$this.app.taskStore.UpdateTask($task)
$this.app.taskStore.Save()  # MUST CALL

# Navigate back or show confirmation
$this.NavigateBack()
```

---

### Keyboard Input Reference

Common VirtualKeyCode values:
- `13` - Enter
- `27` - Escape (handled by parent)
- `32` - Space
- `38` - Arrow Up
- `40` - Arrow Down
- `37` - Arrow Left
- `39` - Arrow Right
- `33` - Page Up
- `34` - Page Down
- `8` - Backspace
- `46` - Delete

---

## Anti-Patterns (DO NOT DO)

### ❌ Forgetting Parent Call
```powershell
[void]ProcessInput($key) {
    # Missing parent::ProcessInput($key)
    if ($key.VirtualKeyCode -eq 40) {
        $this.selectedIndex++
    }
}
```
**Result**: Escape key won't work, other base functionality breaks

### ❌ Not Delegating to Widgets
```powershell
[void]ProcessInput($key) {
    parent::ProcessInput($key)
    # Directly handling keys widget should handle
    if ($key.Character -eq 'a') {
        $this.textInput.Value += 'a'
    }
}
```
**Result**: Widget state gets out of sync

### ❌ Mutating Without Save
```powershell
$task.Status = "Done"
$this.app.taskStore.UpdateTask($task)
# Missing: $this.app.taskStore.Save()
```
**Result**: Changes lost on next app restart

### ❌ Direct Array Access Without Bounds Check
```powershell
if ($key.VirtualKeyCode -eq 40) {
    $this.selectedIndex++  # Can go out of bounds!
}
```
**Result**: IndexOutOfRange errors

---

## To Be Documented
- Multi-field form pattern
- Validation patterns
- Error display pattern
- Loading state pattern
- Confirmation dialog pattern
