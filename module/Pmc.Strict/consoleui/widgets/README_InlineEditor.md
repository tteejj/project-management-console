# InlineEditor Widget

**THE KEY WIDGET** - Composes multiple input types into a unified inline editor.

## Overview

InlineEditor is a multi-field composer widget that replaces ALL inline editing screens in PMC TUI. It dynamically composes existing widgets (TextInput, DatePicker, ProjectPicker, TagEditor) into a single, cohesive editing interface.

## Features

- ✅ **Multi-field composition** - Combine text, date, project, number, and tag fields
- ✅ **Tab/Shift+Tab navigation** - Cycle between fields seamlessly
- ✅ **Field validation** - Required fields, number ranges, custom validators
- ✅ **Smart field widgets** - Uses existing widgets (no code duplication)
- ✅ **Visual field list** - Clear display of all fields with labels
- ✅ **Inline editing** - Edit WHERE YOU ARE, no modal dialogs
- ✅ **Event callbacks** - OnFieldChanged, OnConfirmed, OnCancelled
- ✅ **Theme integration** - Follows PMC theme system

## Supported Field Types

| Type | Widget | Description |
|------|--------|-------------|
| `text` | TextInput | Single-line text input with cursor |
| `date` | DatePicker | Date selection with calendar/text modes |
| `project` | ProjectPicker | Project selection with fuzzy search |
| `tags` | TagEditor | Multi-tag editor with autocomplete |
| `number` | Inline | Number input with visual slider |

## Usage

### Basic Example

```powershell
. "$PSScriptRoot/InlineEditor.ps1"

# Define fields
$fields = @(
    @{ Name='text'; Label='Task'; Type='text'; Value='Buy milk'; Required=$true }
    @{ Name='due'; Label='Due Date'; Type='date'; Value=[DateTime]::Today }
    @{ Name='project'; Label='Project'; Type='project'; Value='personal' }
    @{ Name='priority'; Label='Priority'; Type='number'; Value=3; Min=0; Max=5 }
    @{ Name='tags'; Label='Tags'; Type='tags'; Value=@('urgent') }
)

# Create editor
$editor = [InlineEditor]::new()
$editor.SetFields($fields)
$editor.SetPosition(5, 5)
$editor.Title = "Edit Task"

# Set callbacks
$editor.OnConfirmed = { param($values)
    Write-Host "Saved values:"
    $values.GetEnumerator() | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)"
    }
}

$editor.OnCancelled = {
    Write-Host "Edit cancelled"
}

# Render loop
while (-not $editor.IsConfirmed -and -not $editor.IsCancelled) {
    Clear-Host
    $output = $editor.Render()
    Write-Host $output -NoNewline

    $key = [Console]::ReadKey($true)
    $editor.HandleInput($key)
}

# Get final values
if ($editor.IsConfirmed) {
    $values = $editor.GetValues()
    # Save to database, etc.
}
```

### Field Configuration

Each field is defined as a hashtable with the following properties:

```powershell
@{
    Name = 'field_name'          # Field identifier (required)
    Label = 'Display Label'      # Display label (required)
    Type = 'text'                # Field type (required)
    Value = 'initial value'      # Initial value (optional)
    Required = $true             # Whether field is required (optional, default $false)

    # Type-specific properties:
    MaxLength = 200              # For 'text' type
    Placeholder = "Enter..."     # For 'text' type
    Min = 0                      # For 'number' type
    Max = 5                      # For 'number' type
}
```

### Full Example with All Field Types

```powershell
$fields = @(
    # Text field with validation
    @{
        Name = 'task_name'
        Label = 'Task Name'
        Type = 'text'
        Value = ''
        Required = $true
        MaxLength = 200
        Placeholder = 'Enter task description...'
    }

    # Date field
    @{
        Name = 'due_date'
        Label = 'Due Date'
        Type = 'date'
        Value = [DateTime]::Today.AddDays(7)
    }

    # Project picker
    @{
        Name = 'project'
        Label = 'Project'
        Type = 'project'
        Value = 'work'
        Required = $true
    }

    # Number field with range
    @{
        Name = 'priority'
        Label = 'Priority'
        Type = 'number'
        Value = 3
        Min = 0
        Max = 5
    }

    # Tag editor
    @{
        Name = 'tags'
        Label = 'Tags'
        Type = 'tags'
        Value = @('urgent', 'bug')
    }
)

$editor = [InlineEditor]::new()
$editor.SetFields($fields)
```

## Keyboard Navigation

| Key | Action |
|-----|--------|
| `Tab` | Move to next field |
| `Shift+Tab` | Move to previous field |
| `↑` / `↓` | Navigate between fields |
| `Space` / `F2` | Expand current field widget |
| `Enter` | Confirm all changes (validates first) |
| `Esc` | Cancel editing |

## API Reference

### Properties

- `Title` (string) - Editor title (default: "Edit")
- `IsConfirmed` (bool) - True when user presses Enter and validation passes
- `IsCancelled` (bool) - True when user presses Esc

### Methods

#### `SetFields([hashtable[]]$fields)`
Configure the fields for this editor.

```powershell
$editor.SetFields($fieldDefinitions)
```

#### `GetValues() : hashtable`
Get all field values as a hashtable.

```powershell
$values = $editor.GetValues()
Write-Host "Task: $($values['task_name'])"
```

#### `GetField([string]$name) : object`
Get value of a specific field.

```powershell
$taskName = $editor.GetField('task_name')
```

#### `SetFocus([int]$fieldIndex)`
Set focus to a specific field by index (0-based).

```powershell
$editor.SetFocus(0)  # Focus first field
```

#### `HandleInput([ConsoleKeyInfo]$keyInfo) : bool`
Handle keyboard input. Returns true if input was handled.

```powershell
$key = [Console]::ReadKey($true)
$handled = $editor.HandleInput($key)
```

#### `Render() : string`
Render the editor as ANSI string.

```powershell
$output = $editor.Render()
Write-Host $output -NoNewline
```

### Events

#### `OnFieldChanged`
Called when any field value changes.

```powershell
$editor.OnFieldChanged = { param($fieldName, $value)
    Write-Host "Field '$fieldName' changed to: $value"
}
```

#### `OnConfirmed`
Called when user presses Enter and all validation passes.

```powershell
$editor.OnConfirmed = { param($allValues)
    # Save to database
    Save-PmcTask $allValues
}
```

#### `OnCancelled`
Called when user presses Esc.

```powershell
$editor.OnCancelled = {
    Write-Host "User cancelled edit"
}
```

#### `OnValidationFailed`
Called when validation fails.

```powershell
$editor.OnValidationFailed = { param($errors)
    Write-Host "Validation errors:"
    $errors | ForEach-Object { Write-Host "  - $_" }
}
```

## Validation

### Required Fields

Mark fields as required:

```powershell
@{ Name='task'; Label='Task'; Type='text'; Required=$true }
```

### Number Range Validation

Set min/max for number fields:

```powershell
@{ Name='priority'; Label='Priority'; Type='number'; Min=0; Max=5 }
```

### Validation Errors

When validation fails:
1. `OnValidationFailed` event fires with error array
2. First error is displayed in editor UI
3. `IsConfirmed` remains `$false`

## Visual Layout

```
┌───────────[Edit Task]───────────────────────────────────────┐
│ Task:     Buy milk                                          │  ← Focused field (highlighted)
│                                                              │
│ Due Date: 2025-11-08 (Fri)                                  │
│                                                              │
│ Project:  personal                                          │
│                                                              │
│ Priority: [==●==] 3                                         │  ← Number field with slider
│                                                              │
│ Tags:     [urgent] [work]                                   │
│                                                              │
│ Tab: Next | Space: Edit | Enter: Save | Esc: Cancel        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Integration with PMC

### Task Editing

```powershell
function Edit-PmcTask($task) {
    $fields = @(
        @{ Name='text'; Label='Task'; Type='text'; Value=$task.text; Required=$true }
        @{ Name='due'; Label='Due'; Type='date'; Value=$task.due }
        @{ Name='project'; Label='Project'; Type='project'; Value=$task.project }
        @{ Name='priority'; Label='Priority'; Type='number'; Value=$task.priority; Min=0; Max=5 }
        @{ Name='tags'; Label='Tags'; Type='tags'; Value=$task.tags }
    )

    $editor = [InlineEditor]::new()
    $editor.SetFields($fields)
    $editor.SetPosition(10, 5)
    $editor.Title = "Edit Task #$($task.id)"

    $editor.OnConfirmed = { param($values)
        # Update task
        $task.text = $values['text']
        $task.due = $values['due']
        $task.project = $values['project']
        $task.priority = $values['priority']
        $task.tags = $values['tags']

        Save-PmcTask $task
    }

    # Render loop
    while (-not $editor.IsConfirmed -and -not $editor.IsCancelled) {
        $output = $editor.Render()
        Write-Host $output -NoNewline
        $key = [Console]::ReadKey($true)
        $editor.HandleInput($key)
    }
}
```

## Performance

- **Field Widgets**: Reuses existing widget instances (TextInput, DatePicker, etc.)
- **Render Optimization**: Only expanded field widget renders when editing
- **Memory**: Minimal overhead, widgets created once per field

## Testing

Run the test suite:

```powershell
pwsh TestInlineEditor.ps1
```

Tests cover:
- Basic creation and configuration
- All field types (text, date, project, tags, number)
- Validation (required fields, number ranges)
- Navigation (Tab, arrows)
- Event callbacks
- Rendering

## Limitations

- Number fields are inline (no popup widget yet)
- No custom field types (extensibility not yet implemented)
- Field widgets render in fixed positions (not adaptive)

## Future Enhancements

- [ ] Custom field type registration
- [ ] Number field popup widget (arrow key adjustment)
- [ ] Field groups/sections
- [ ] Conditional field visibility
- [ ] Field dependencies (e.g., "Show X when Y = Z")
- [ ] Horizontal layout mode

## Related Widgets

- **TextInput** - Single-line text input
- **DatePicker** - Date selection widget
- **ProjectPicker** - Project selection widget
- **TagEditor** - Tag management widget

## See Also

- [README_UniversalList.md](README_UniversalList.md) - Uses InlineEditor for inline editing
- [README_FilterPanel.md](README_FilterPanel.md) - Filtering complement to editing
