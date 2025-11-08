# TagEditor Widget

Multi-select tag editor with autocomplete chips.

## Features

- **Display selected tags** as colored chips: `[work] [urgent] [bug]`
- **Type to add tags** with autocomplete from existing tags
- **Backspace to remove** last tag or edit current input
- **Tab/Enter to confirm** current input as tag
- **Arrow keys** to navigate autocomplete suggestions
- **OnTagsChanged** event callback
- **Visual chip layout** with color coding
- **Max tags limit** (configurable, default 10)
- **Load existing tags** from all tasks for autocomplete
- **Validation**: No duplicate tags, no empty tags
- **Color-coded chips** (hash tag name to consistent color)

## Usage

```powershell
# Basic usage
$editor = [TagEditor]::new()
$editor.SetPosition(5, 10)
$editor.SetSize(60, 5)
$editor.SetTags(@("work", "urgent"))
$editor.MaxTags = 5

# Event handling
$editor.OnTagsChanged = { param($tags)
    Write-Host "Tags changed: $($tags -join ', ')"
}

$editor.OnConfirmed = { param($tags)
    Write-Host "Final tags: $($tags -join ', ')"
}

# Render
$ansiOutput = $editor.Render()
Write-Host $ansiOutput -NoNewline

# Handle input
$key = [Console]::ReadKey($true)
$handled = $editor.HandleInput($key)

# Get result
if ($editor.IsConfirmed) {
    $tags = $editor.GetTags()
}
```

## Properties

- `Label` - Widget title (default: "Tags")
- `MaxTags` - Maximum number of tags (default: 10)
- `AllowNewTags` - Allow creating tags not in autocomplete list (default: true)
- `IsConfirmed` - True when Enter pressed
- `IsCancelled` - True when Esc pressed

## Methods

- `SetTags($tags)` - Set tags collection (deduplicates automatically)
- `GetTags()` - Get current tags as array
- `AddTag($tag)` - Add a single tag (returns true if added)
- `RemoveTag($tag)` - Remove a single tag (returns true if removed)
- `ClearTags()` - Remove all tags

## Events

- `OnTagsChanged` - Called when tags change: `param($tags)`
- `OnConfirmed` - Called when Enter pressed: `param($tags)`
- `OnCancelled` - Called when Esc pressed

## Keyboard Controls

- **Enter** - Add current input as tag, then confirm
- **Tab** - Add current input as tag (or use autocomplete suggestion)
- **Comma** - Treat as tag separator (adds current input)
- **Escape** - Cancel/done
- **Backspace** - Remove last tag (if input empty) or edit input
- **Delete** - Delete character at cursor
- **Up/Down Arrow** - Navigate autocomplete suggestions
- **Left/Right Arrow** - Move cursor in input
- **Home/End** - Jump to start/end of input
- **Type characters** - Build tag name (shows autocomplete)

## Autocomplete

Tags are loaded from all tasks in PMC data:
```powershell
$data = Get-PmcData
foreach ($task in $data.tasks) {
    foreach ($tag in $task.tags) {
        # Collect unique tags for autocomplete
    }
}
```

Autocomplete shows up to 3 matching suggestions:
- Type "ur" → suggests "urgent"
- Type "wo" → suggests "work"
- Use Up/Down arrows to select
- Press Tab to use suggestion

Auto-refreshes every 10 seconds.

## Tag Chips

Tags are displayed as colored chips with consistent colors:
```
[work] [urgent] [bug] [feature]
```

Colors are assigned by hashing the tag name, so the same tag always gets the same color.

Color palette (8 colors, cycling):
- Blue (#3498db)
- Green (#2ecc71)
- Red (#e74c3c)
- Orange (#f39c12)
- Purple (#9b59b6)
- Teal (#1abc9c)
- Dark orange (#e67e22)
- Dark teal (#16a085)

## Layout

The widget uses 2 rows for chips and input:
```
┌─ Tags ─────────────────────────────────────────────────── (2/10) ─┐
│ [work] [urgent] [bug] type tag...                                 │
│                                                                    │
│ Tab/Enter=Add | Backspace=Remove | Esc=Done                       │
└────────────────────────────────────────────────────────────────────┘
```

If autocomplete is active:
```
┌─ Tags ─────────────────────────────────────────────────── (2/10) ─┐
│ [work] [urgent] ur                                                 │
│   urgent                                                           │
│   urgent-fix                                                       │
│ Tab/Enter=Add | Backspace=Remove | Esc=Done                       │
└────────────────────────────────────────────────────────────────────┘
```

## Validation

- **No duplicates**: Adding an existing tag shows error
- **No empty tags**: Empty input is ignored
- **Max limit**: Cannot exceed MaxTags (default 10)
- **Whitespace**: Tags are trimmed automatically
- **New tags**: If AllowNewTags=false, only existing tags allowed

## Testing

Run the test suite:

```powershell
./TestTagEditor.ps1 -Verbose
```

Test suite includes mocked `Get-PmcData` function.

## Implementation Details

- Extends `PmcWidget` base class
- Uses List[string] for tag collection (efficient add/remove)
- Autocomplete uses HashSet for deduplication
- Color hashing ensures consistency
- Theme colors from PMC theme system
- Auto-wrapping for long tag lists
