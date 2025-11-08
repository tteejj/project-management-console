# FilterPanel Widget

Dynamic filter builder with visual filter chips and smart data filtering.

## Overview

FilterPanel is a dynamic filter builder widget that allows users to construct complex filters visually. It displays filters as colored chips and provides an intuitive interface for adding, removing, and managing filters. The panel can apply filters to any data array and supports export/import of filter presets.

## Features

- ✅ **Visual filter chips** - `[Project: work] [Priority >= 3] [Due: This Week]`
- ✅ **Dynamic filter management** - Add/remove filters on the fly
- ✅ **Multiple filter types** - Project, Priority, DueDate, Tags, Status, Text
- ✅ **Filter operators** - Equals, contains, <, <=, >, >=, has, between
- ✅ **Apply to data arrays** - Filter any array of objects
- ✅ **Filter presets** - Save/load common filter combinations
- ✅ **Keyboard-driven** - Alt+A (add), Alt+R (remove), Alt+C (clear)
- ✅ **Color-coded chips** - Each filter type has a distinct color
- ✅ **Export/import** - Save filter configurations as presets

## Supported Filter Types

| Type | Description | Operators |
|------|-------------|-----------|
| **Project** | Filter by project name | equals, contains |
| **Priority** | Filter by priority number | =, !=, <, <=, >, >= |
| **DueDate** | Filter by due date | equals, before, after, between |
| **Tags** | Filter by tags | has, has all, has any |
| **Status** | Filter by status | equals (pending, completed, archived) |
| **Text** | Full-text search in task text | contains, startswith |

## Usage

### Basic Example

```powershell
. "$PSScriptRoot/FilterPanel.ps1"

# Create filter panel
$panel = [FilterPanel]::new()
$panel.SetPosition(5, 5)
$panel.SetSize(80, 12)
$panel.Title = "Task Filters"

# Set callback for filter changes
$panel.OnFiltersChanged = { param($filters)
    Write-Host "Filters changed: $($filters.Count) active"
    # Reload data with new filters
}

# Add filters programmatically
$panel.AddFilter(@{ Type='Project'; Op='equals'; Value='work' })
$panel.AddFilter(@{ Type='Priority'; Op='>='; Value=3 })

# Apply filters to data
$allTasks = Get-PmcData | Select-Object -ExpandProperty tasks
$filteredTasks = $panel.ApplyFilters($allTasks)

Write-Host "Filtered from $($allTasks.Count) to $($filteredTasks.Count) tasks"

# Render loop
while ($true) {
    Clear-Host
    $output = $panel.Render()
    Write-Host $output -NoNewline

    $key = [Console]::ReadKey($true)
    if ($key.Key -eq 'Escape') { break }

    $panel.HandleInput($key)
}
```

### Adding Filters Interactively

```powershell
# User presses Alt+A to open add menu
# Selects filter type with arrows
# Presses Enter to add filter with default values

# Example: Add high-priority filter
$panel.AddFilter(@{
    Type = 'Priority'
    Op = '>='
    Value = 4
})
```

### Filter Configuration

Each filter is a hashtable with three required properties:

```powershell
@{
    Type = 'FilterType'    # Project, Priority, DueDate, Tags, Status, Text
    Op = 'operator'        # equals, >=, contains, has, etc.
    Value = $value         # Filter value (type-specific)
}
```

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Alt+A` | Add filter (opens filter type menu) |
| `Alt+R` | Remove currently selected filter |
| `Alt+C` | Clear all filters |
| `←` / `→` | Navigate between filter chips |
| `Delete` | Remove selected filter |
| `Esc` | Close filter panel |

## API Reference

### Properties

- `Title` (string) - Panel title (default: "Filters")

### Methods

#### `SetFilters([hashtable[]]$filters)`
Set all active filters at once.

```powershell
$filters = @(
    @{ Type='Project'; Op='equals'; Value='work' }
    @{ Type='Priority'; Op='>='; Value=3 }
)
$panel.SetFilters($filters)
```

#### `GetFilters() : hashtable[]`
Get current filters as array.

```powershell
$activeFilters = $panel.GetFilters()
foreach ($filter in $activeFilters) {
    Write-Host "$($filter.Type) $($filter.Op) $($filter.Value)"
}
```

#### `AddFilter([hashtable]$filter)`
Add a new filter.

```powershell
$panel.AddFilter(@{
    Type = 'Tags'
    Op = 'has'
    Value = 'urgent'
})
```

#### `RemoveFilter([int]$index)`
Remove filter by index (0-based).

```powershell
$panel.RemoveFilter(0)  # Remove first filter
```

#### `ClearFilters()`
Remove all filters.

```powershell
$panel.ClearFilters()
```

#### `ApplyFilters([array]$dataArray) : array`
Apply filters to data array and return filtered results.

```powershell
$tasks = Get-PmcData | Select-Object -ExpandProperty tasks
$filtered = $panel.ApplyFilters($tasks)
```

#### `GetFilterString() : string`
Get human-readable filter description.

```powershell
$description = $panel.GetFilterString()
Write-Host "Active filters: $description"
# Output: "Project = work AND Priority >= 3"
```

#### `GetFilterPreset() : hashtable`
Export current filters as a preset.

```powershell
$preset = $panel.GetFilterPreset()
Save-PmcFilterPreset 'HighPriorityWork' $preset
```

#### `LoadFilterPreset([hashtable]$preset)`
Load filters from a preset.

```powershell
$preset = Load-PmcFilterPreset 'HighPriorityWork'
$panel.LoadFilterPreset($preset)
```

### Events

#### `OnFiltersChanged`
Called when filters change (add, remove, clear).

```powershell
$panel.OnFiltersChanged = { param($filters)
    # Reload data with new filters
    $global:filteredData = $panel.ApplyFilters($global:allData)
}
```

#### `OnFilterAdded`
Called when a filter is added.

```powershell
$panel.OnFilterAdded = { param($filter)
    Write-Host "Added filter: $($filter.Type)"
}
```

#### `OnFilterRemoved`
Called when a filter is removed.

```powershell
$panel.OnFilterRemoved = { param($index)
    Write-Host "Removed filter at index $index"
}
```

#### `OnFiltersCleared`
Called when all filters are cleared.

```powershell
$panel.OnFiltersCleared = {
    Write-Host "All filters cleared"
}
```

## Filter Examples

### Project Filter

```powershell
# Exact match
@{ Type='Project'; Op='equals'; Value='work' }

# Contains
@{ Type='Project'; Op='contains'; Value='proj' }
```

### Priority Filter

```powershell
# Greater than or equal
@{ Type='Priority'; Op='>='; Value=3 }

# Exact match
@{ Type='Priority'; Op='='; Value=5 }

# Less than
@{ Type='Priority'; Op='<'; Value=2 }
```

### Date Filter

```powershell
# Today
@{ Type='DueDate'; Op='equals'; Value=[DateTime]::Today }

# This week
@{ Type='DueDate'; Op='between'; Value=@([DateTime]::Today, [DateTime]::Today.AddDays(7)) }

# Before date
@{ Type='DueDate'; Op='<'; Value=[DateTime]::Parse('2025-12-31') }
```

### Tag Filter

```powershell
# Has specific tag
@{ Type='Tags'; Op='has'; Value='urgent' }

# Has all tags
@{ Type='Tags'; Op='hasall'; Value=@('urgent', 'bug') }

# Has any of these tags
@{ Type='Tags'; Op='hasany'; Value=@('urgent', 'important', 'critical') }
```

### Status Filter

```powershell
# Pending tasks only
@{ Type='Status'; Op='equals'; Value='pending' }

# Completed tasks
@{ Type='Status'; Op='equals'; Value='completed' }
```

### Text Search

```powershell
# Contains text
@{ Type='Text'; Op='contains'; Value='meeting' }

# Starts with
@{ Type='Text'; Op='startswith'; Value='Fix' }
```

## Visual Layout

```
┌─────────────[Filters]────────────────────────────────────────────(2 active)─┐
│ [Project: work] [Priority >= 3] [Due: This Week]                           │
│                                                                              │
│                                                                              │
│                                                                              │
│                                                                              │
│                                                                              │
│                                                                              │
│                                                                              │
│                                                                              │
│ Alt+A: Add | Alt+R: Remove | Alt+C: Clear | Arrows: Navigate               │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Add Filter Menu

```
┌─────────────[Filters]─────────────────────────
│       ┌────[Add Filter]────────┐
│       │ Project               │
│       │ Priority              │  ← Selected
│       │ DueDate               │
│       │ Tags                  │
│       │ Status                │
│       │ Text                  │
│       │                        │
│       │ Enter=Add | Esc=Cancel│
│       └────────────────────────┘
└──────────────────────────────────────────────
```

## Filter Logic

### AND Logic

All filters use AND logic - items must match ALL active filters:

```powershell
$panel.AddFilter(@{ Type='Project'; Op='equals'; Value='work' })
$panel.AddFilter(@{ Type='Priority'; Op='>='; Value=3 })

# Result: Tasks where (Project='work' AND Priority>=3)
```

### Operator Behavior

| Operator | Description | Example |
|----------|-------------|---------|
| `equals` | Exact match | Project = 'work' |
| `notequals` | Not equal | Status != 'completed' |
| `contains` | Substring match | Text contains 'meeting' |
| `startswith` | Starts with | Text starts with 'Fix' |
| `<` | Less than | Priority < 3 |
| `<=` | Less than or equal | Priority <= 2 |
| `>` | Greater than | Priority > 3 |
| `>=` | Greater than or equal | Priority >= 4 |
| `has` | Array contains item | Tags has 'urgent' |
| `hasall` | Array contains all items | Tags has all ['urgent', 'bug'] |
| `hasany` | Array contains any item | Tags has any ['urgent', 'important'] |
| `between` | Value in range | Due between [start, end] |

## Integration with PMC

### Task List Integration

```powershell
function Show-PmcTaskList {
    $allTasks = Get-PmcData | Select-Object -ExpandProperty tasks

    # Create filter panel
    $filterPanel = [FilterPanel]::new()
    $filterPanel.SetPosition(0, 0)
    $filterPanel.SetSize(100, 8)

    # Create task list (UniversalList)
    $taskList = [UniversalList]::new()
    $taskList.SetPosition(0, 8)
    $taskList.SetSize(100, 30)

    # Link filter panel to task list
    $filterPanel.OnFiltersChanged = { param($filters)
        $filtered = $filterPanel.ApplyFilters($allTasks)
        $taskList.SetData($filtered)
    }

    # Initial data
    $taskList.SetData($allTasks)

    # Render loop
    while ($true) {
        Clear-Host
        Write-Host $filterPanel.Render() -NoNewline
        Write-Host $taskList.Render() -NoNewline

        $key = [Console]::ReadKey($true)
        if ($key.Key -eq 'Escape') { break }

        # Route input based on focus
        if ($filterPanel.HasFocus) {
            $filterPanel.HandleInput($key)
        } else {
            $taskList.HandleInput($key)
        }
    }
}
```

## Filter Presets

### Built-in Presets

The FilterPanel includes built-in filter presets:

```powershell
# Today's tasks
$panel.LoadFilterPreset($panel._presets['Today'])

# This week's tasks
$panel.LoadFilterPreset($panel._presets['This Week'])

# High priority tasks
$panel.LoadFilterPreset($panel._presets['High Priority'])

# Work project tasks
$panel.LoadFilterPreset($panel._presets['Work Project'])
```

### Custom Presets

Save and load custom presets:

```powershell
# Create custom filters
$panel.AddFilter(@{ Type='Project'; Op='equals'; Value='work' })
$panel.AddFilter(@{ Type='Priority'; Op='>='; Value=4 })
$panel.AddFilter(@{ Type='Tags'; Op='has'; Value='urgent' })

# Save as preset
$preset = $panel.GetFilterPreset()
$preset | ConvertTo-Json | Out-File "~/urgent_work_preset.json"

# Load preset later
$preset = Get-Content "~/urgent_work_preset.json" | ConvertFrom-Json
$panel.LoadFilterPreset($preset)
```

## Performance

- **Filter Application**: O(n × m) where n=items, m=filters
- **Chip Rendering**: Efficient text wrapping (handles 20+ filters)
- **Memory**: Minimal - filters stored as small hashtables

## Testing

Run the test suite:

```powershell
pwsh TestFilterPanel.ps1
```

Tests cover:
- Basic creation
- Add/remove/clear filters
- Apply filters to data
- Multiple filter logic (AND)
- Date filters
- Tag filters
- Filter string generation
- Preset save/load

## Limitations

- Only AND logic (no OR support yet)
- Filter values are fixed after creation (no inline editing)
- No filter grouping or nesting
- Chip overflow may hide filters on small terminals

## Future Enhancements

- [ ] OR logic support (filter groups)
- [ ] Inline filter value editing
- [ ] Filter suggestions based on data
- [ ] Filter templates (save/load named presets)
- [ ] Smart date filters ("last 7 days", "next month")
- [ ] Negation operator (NOT)
- [ ] Regex support for text filters

## Related Widgets

- **UniversalList** - Uses FilterPanel for data filtering
- **InlineEditor** - Editing complement to filtering

## See Also

- [README_UniversalList.md](README_UniversalList.md) - List widget with integrated filtering
- [README_InlineEditor.md](README_InlineEditor.md) - Multi-field editor widget
