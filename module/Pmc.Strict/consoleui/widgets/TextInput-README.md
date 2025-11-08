# TextInput Widget

Single-line text input widget with cursor, validation, and event callbacks.

## Features

- **Single-line text input** with cursor position tracking
- **Left/Right arrow navigation**, Home/End keys
- **Backspace/Delete** character editing
- **Character insertion** with MaxLength enforcement
- **Visual cursor indicator** (inverted colors with blinking)
- **Placeholder text** with ANSI color support
- **Validation** with custom scriptblock
- **OnTextChanged** event callback
- **Theme integration** with border and colors
- **Horizontal scrolling** for long text

## Usage

```powershell
# Basic usage
$input = [TextInput]::new()
$input.SetPosition(5, 5)
$input.SetSize(40, 3)
$input.Text = "Initial value"
$input.Placeholder = "Enter task text..."
$input.MaxLength = 200

# Validation
$input.Validator = { param($text) $text.Length -gt 0 }

# Event handling
$input.OnTextChanged = { param($newText)
    Write-Host "Text changed: $newText"
}

$input.OnConfirmed = { param($text)
    Write-Host "Confirmed: $text"
}

# Render
$ansiOutput = $input.Render()
Write-Host $ansiOutput -NoNewline

# Handle input
$key = [Console]::ReadKey($true)
$handled = $input.HandleInput($key)

# Get result
if ($input.IsConfirmed) {
    $text = $input.GetText()
}
```

## Properties

- `Text` - Current text content
- `Placeholder` - Placeholder shown when empty
- `MaxLength` - Maximum text length (default: 500)
- `Validator` - Validation scriptblock: `param($text) -> bool` or `@{Valid=$bool; Message=$string}`
- `Label` - Optional label above input
- `IsConfirmed` - True when Enter pressed
- `IsCancelled` - True when Esc pressed
- `IsValid` - Current validation state

## Events

- `OnTextChanged` - Called when text changes: `param($newText)`
- `OnValidationFailed` - Called when validation fails: `param($text, $error)`
- `OnConfirmed` - Called when Enter pressed: `param($text)`
- `OnCancelled` - Called when Esc pressed

## Keyboard Controls

- **Enter** - Confirm input (only if valid)
- **Escape** - Cancel input
- **Left/Right Arrow** - Move cursor
- **Home/End** - Jump to start/end
- **Backspace** - Delete character before cursor
- **Delete** - Delete character at cursor
- **Ctrl+A** - Move to beginning
- **Ctrl+E** - Move to end
- **Ctrl+U** - Clear line
- **Any printable character** - Insert at cursor

## Validation

The `Validator` scriptblock can return:

1. **Boolean**: `$true` (valid) or `$false` (invalid)
2. **Hashtable**: `@{ Valid = $bool; Message = "error message" }`

Example validators:

```powershell
# Minimum length
$input.Validator = { param($text) $text.Length -ge 3 }

# With custom error message
$input.Validator = { param($text)
    if ($text.Length -lt 3) {
        return @{ Valid = $false; Message = "Too short (min 3)" }
    }
    return @{ Valid = $true }
}

# Pattern matching
$input.Validator = { param($text) $text -match '^[A-Za-z0-9]+$' }
```

## Testing

Run the test suite:

```powershell
./TestTextInput.ps1 -Verbose
```

## Implementation Details

- Extends `PmcWidget` base class
- Uses VT100 ANSI sequences for rendering
- Cursor blinks every 500ms
- Horizontal scrolling for text longer than display width
- Validation runs on every text change
- Theme colors from PMC theme system
