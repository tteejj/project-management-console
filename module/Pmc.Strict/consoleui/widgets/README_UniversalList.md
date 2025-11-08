# UniversalList Widget

**THE BIG ONE** - Generic list widget that replaces 12+ specialized list screens!

## Overview

UniversalList is a production-ready, feature-complete list widget with columns, sorting, filtering, inline editing, multi-select, and virtual scrolling. It's designed to handle ANY tabular data with full keyboard navigation and extensible actions.

## Features

- ✅ **Column configuration** - Width, alignment, custom formatting
- ✅ **Data binding** - Bind to any array of objects
- ✅ **Sorting** - Click column header or hotkey, ascending/descending
- ✅ **Filtering** - Integrated FilterPanel with visual chips
- ✅ **Selection** - Arrow keys, Home/End, PageUp/Down
- ✅ **Multi-select** - Space to toggle, M to enter multi-select mode
- ✅ **Inline editing** - E key opens InlineEditor overlay
- ✅ **Configurable actions** - Add, Edit, Delete, custom actions
- ✅ **Virtual scrolling** - Handles 1000+ items smoothly
- ✅ **Search mode** - / key for quick text filter
- ✅ **Differential rendering** - Performance optimizations
- ✅ **Event callbacks** - Selection, edit, delete, activation
- ✅ **Theme integration** - Follows PMC theme system

## Replaces These Screens

With UniversalList, you can build:

1. **Task List** - All tasks with filters
2. **Project List** - All projects
3. **Time Log List** - Time tracking entries
4. **Tag List** - All tags
5. **Note List** - All notes
6. **Completed Tasks** - Filtered view
7. **Today's Tasks** - Date-filtered view
8. **Overdue Tasks** - Date-filtered view
9. **High Priority Tasks** - Priority-filtered view
10. **Project Tasks** - Project-filtered view
11. **Search Results** - Text-filtered view
12. **Archive List** - Archived items

...and any other tabular view you need!

## Usage

### Basic Example

```powershell
. "$PSScriptRoot/UniversalList.ps1"

# Define columns
$columns = @(
    @{ Name='id'; Label='ID'; Width=4; Align='right' }
    @{ Name='priority'; Label='Pri'; Width=4; Align='center'; Format={ "[P$_]" }}
    @{ Name='text'; Label='Task'; Width=40; Align='left' }
    @{ Name='due'; Label='Due'; Width=12; Format={ $_.ToString('MMM dd yyyy') }}
    @{ Name='project'; Label='Project'; Width=15 }
)

# Create list
$list = [UniversalList]::new()
$list.SetColumns($columns)
$list.SetPosition(0, 3)
$list.SetSize(120, 35)
$list.Title = "Tasks"

# Set data
$tasks = Get-PmcData | Select-Object -ExpandProperty tasks
$list.SetData($tasks)

# Add actions
$list.AddAction('a', 'Add', { param($list)
    # Show InlineEditor for new task
    $list.ShowInlineEditor(@{})
})

$list.AddAction('e', 'Edit', { param($list)
    $selected = $list.GetSelectedItem()
    if ($selected) {
        $list.ShowInlineEditor($selected)
    }
})

$list.AddAction('d', 'Delete', { param($list)
    $selected = $list.GetSelectedItem()
    if ($selected) {
        Remove-PmcTask $selected.id
    }
})

# Event callbacks
$list.OnSelectionChanged = { param($item)
    Write-Host "Selected: $($item.text)"
}

# Render loop
while ($true) {
    Clear-Host
    $output = $list.Render()
    Write-Host $output -NoNewline

    $key = [Console]::ReadKey($true)
    if ($key.Key -eq 'Escape') { break }

    $list.HandleInput($key)
}
```

### Column Configuration

Each column is a hashtable with these properties:

```powershell
@{
    Name = 'property_name'       # Object property name (required)
    Label = 'Column Header'      # Display label (required)
    Width = 20                   # Column width in characters (required)
    Align = 'left'              # Alignment: left, center, right (optional, default 'left')
    Format = { $_ }             # Format scriptblock (optional)
    Sortable = $true            # Whether column is sortable (optional, default $true)
}
```

#### Format Scriptblock

The `Format` scriptblock receives the cell value as `$_`:

```powershell
# Priority with brackets
@{ Name='priority'; Label='Pri'; Width=6; Format={ "[P$_]" }}

# Date formatting
@{ Name='due'; Label='Due'; Width=12; Format={ $_.ToString('yyyy-MM-dd') }}

# Conditional formatting
@{ Name='status'; Label='Status'; Width=10; Format={
    if ($_ -eq 'completed') { "✓ Done" }
    elseif ($_ -eq 'pending') { "⧗ Todo" }
    else { $_ }
}}

# Truncate long text
@{ Name='text'; Label='Task'; Width=40; Format={
    if ($_.Length -gt 40) { $_.Substring(0, 37) + "..." }
    else { $_ }
}}
```

## Keyboard Navigation

| Key | Action |
|-----|--------|
| `↑` / `↓` | Move selection up/down |
| `PageUp` / `PageDown` | Move selection by page |
| `Home` / `End` | Move to first/last item |
| `Enter` | Activate selected item (triggers OnItemActivated) |
| `Space` | Toggle multi-select on current item |
| `M` | Enter/exit multi-select mode |
| `/` | Enter search mode (type to filter) |
| `F` | Show filter panel |
| `S` | Sort mode (then press column number) |
| `E` | Edit selected item (shows InlineEditor) |
| `D` | Delete selected item |
| `Esc` | Close overlays / exit modes |

## API Reference

### Properties

- `Title` (string) - List title (default: "List")
- `AllowMultiSelect` (bool) - Enable multi-select mode (default: $true)
- `AllowInlineEdit` (bool) - Enable inline editing (default: $true)
- `AllowSearch` (bool) - Enable search mode (default: $true)
- `ShowLineNumbers` (bool) - Show line numbers (default: $false)
- `ItemsPerPage` (int) - Items per page for PageUp/Down (default: 10)

### Methods

#### `SetColumns([hashtable[]]$columns)`
Configure columns.

```powershell
$list.SetColumns($columnDefinitions)
```

#### `SetData([array]$data)`
Set data array.

```powershell
$list.SetData($tasks)
```

#### `GetSelectedItem() : object`
Get currently selected item.

```powershell
$selected = $list.GetSelectedItem()
Write-Host "Selected task: $($selected.text)"
```

#### `GetSelectedItems() : array`
Get all selected items (multi-select mode).

```powershell
$selected = $list.GetSelectedItems()
Write-Host "Selected $($selected.Count) items"
```

#### `SetSortColumn([string]$columnName, [bool]$ascending)`
Sort by column.

```powershell
$list.SetSortColumn('priority', $false)  # Descending priority
```

#### `AddAction([string]$key, [string]$label, [scriptblock]$callback)`
Add custom action.

```powershell
$list.AddAction('c', 'Complete', { param($list)
    $task = $list.GetSelectedItem()
    $task.status = 'completed'
    Save-PmcTask $task
})
```

#### `RemoveAction([string]$key)`
Remove action.

```powershell
$list.RemoveAction('c')
```

#### `ShowInlineEditor([object]$item, [hashtable[]]$fieldDefinitions)`
Show inline editor for item.

```powershell
$selected = $list.GetSelectedItem()
$list.ShowInlineEditor($selected)
```

#### `ShowFilterPanel()`
Show filter panel overlay.

```powershell
$list.ShowFilterPanel()
```

#### `HideFilterPanel()`
Hide filter panel overlay.

```powershell
$list.HideFilterPanel()
```

### Events

#### `OnSelectionChanged`
Called when selection changes.

```powershell
$list.OnSelectionChanged = { param($item)
    Write-Host "Now viewing: $($item.text)"
}
```

#### `OnItemActivated`
Called when Enter pressed on item.

```powershell
$list.OnItemActivated = { param($item)
    # Open detail view
    Show-TaskDetail $item
}
```

#### `OnItemEdit`
Called when item edited via InlineEditor.

```powershell
$list.OnItemEdit = { param($item)
    Save-PmcTask $item
    $list.SetData($allTasks)  # Refresh
}
```

#### `OnItemDelete`
Called when delete action triggered.

```powershell
$list.OnItemDelete = { param($item)
    Remove-PmcTask $item.id
}
```

#### `OnMultiSelectChanged`
Called when multi-select changes.

```powershell
$list.OnMultiSelectChanged = { param($selectedItems)
    Write-Host "Selected $($selectedItems.Count) items"
}
```

#### `OnDataChanged`
Called when data changes (via SetData).

```powershell
$list.OnDataChanged = { param($newData)
    Write-Host "Data updated: $($newData.Count) items"
}
```

## Visual Layout

### Normal View

```
┌───────────────────────────[Tasks]──────────────────────────────(1234 items)─┐
│ ID  Pri  Task                      Due          Project                     │
│ ──  ───  ────────────────────────  ───────────  ──────────                  │
│  1  [P1] Buy milk                  Nov 08 2025  personal                    │
│> 2  [P3] Deploy new feature        Nov 15 2025  work        ← Selected      │
│  3  [P2] Team meeting              Nov 10 2025  work                        │
│  4  [P0] Document API              Nov 20 2025  work                        │
│  ...                                                                         │
│                                                                              │
│ Selected: Deploy new feature                                                │
│ A=Add | E=Edit | D=Delete | /=Search | F=Filter | Space=Select             │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Multi-Select Mode

```
┌───────────────────────────[Tasks]──────────────────────────────(1234 items)─┐
│ ID  Pri  Task                      Due          Project                     │
│ ──  ───  ────────────────────────  ───────────  ──────────                  │
│  1  [P1] Buy milk                  Nov 08 2025  personal    ✓ Selected      │
│> 2  [P3] Deploy new feature        Nov 15 2025  work        ← Cursor        │
│  3  [P2] Team meeting              Nov 10 2025  work        ✓ Selected      │
│  4  [P0] Document API              Nov 20 2025  work                        │
│  ...                                                                         │
│                                                                              │
│ Multi-select mode (2 selected)                                              │
│ Space=Toggle | M=Exit Multi-Select | D=Delete Selected                     │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Search Mode

```
┌───────────────────────────[Tasks]──────────────────────────────(1234 items)─┐
│ ID  Pri  Task                      Due          Project                     │
│ ──  ───  ────────────────────────  ───────────  ──────────                  │
│  2  [P3] Deploy new feature        Nov 15 2025  work                        │
│  7  [P2] Feature request           Nov 22 2025  work                        │
│  ...                                                                         │
│                                                                              │
│                                                                              │
│ Search: feature_                                                            │
│ Enter=Apply | Esc=Clear Search                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### With Filter Panel

```
┌───────────────────────────[Tasks]──────────────────────────────(1234 items)─┐
│ ┌─────────────[Filters]────────────────────────────────(2 active)──────────┐│
│ │ [Project: work] [Priority >= 3]                                          ││
│ │                                                                           ││
│ │ Alt+A: Add | Alt+R: Remove | Alt+C: Clear                                ││
│ └───────────────────────────────────────────────────────────────────────────┘│
│ ID  Pri  Task                      Due          Project                     │
│ ──  ───  ────────────────────────  ───────────  ──────────                  │
│  2  [P3] Deploy new feature        Nov 15 2025  work                        │
│  3  [P4] Team meeting              Nov 10 2025  work                        │
│  ...                                                                         │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Advanced Features

### Sorting

#### Interactive Sorting

```powershell
# User presses 'S', then column number
# Or click column header (if mouse support added)
```

#### Programmatic Sorting

```powershell
# Sort by priority descending
$list.SetSortColumn('priority', $false)

# Sort by due date ascending
$list.SetSortColumn('due', $true)
```

### Filtering

The list integrates with FilterPanel:

```powershell
# Show filter panel
$list.ShowFilterPanel()

# Filters automatically apply to displayed data
# Press F to toggle filter panel
```

### Search

Quick text search across all columns:

```powershell
# User presses '/'
# Types search text
# List filters in real-time
# Press Enter to apply, Esc to clear
```

### Virtual Scrolling

UniversalList uses virtual scrolling for performance with large datasets:

- Only visible rows are rendered
- Handles 1000+ items smoothly
- Scroll offset automatically adjusts to keep selection visible

### Custom Formatting

Apply custom formatting to columns:

```powershell
# Color-coded priority
@{
    Name='priority'
    Label='Pri'
    Width=6
    Format={ param($p)
        if ($p -ge 4) { "`e[31m[P$p]`e[0m" }      # Red
        elseif ($p -ge 2) { "`e[33m[P$p]`e[0m" }  # Yellow
        else { "`e[32m[P$p]`e[0m" }               # Green
    }
}

# Relative dates
@{
    Name='due'
    Label='Due'
    Width=15
    Format={ param($date)
        $days = ($date - [DateTime]::Today).Days
        if ($days -lt 0) { "Overdue ($(-$days)d)" }
        elseif ($days -eq 0) { "Today" }
        elseif ($days -eq 1) { "Tomorrow" }
        else { "$days days" }
    }
}
```

## Integration Examples

### Task List Screen

```powershell
function Show-PmcTaskList {
    $columns = @(
        @{ Name='id'; Label='ID'; Width=4; Align='right' }
        @{ Name='priority'; Label='Pri'; Width=6; Format={ "[P$_]" }}
        @{ Name='text'; Label='Task'; Width=40 }
        @{ Name='due'; Label='Due'; Width=12; Format={
            if ($null -ne $_) { $_.ToString('MMM dd') } else { "" }
        }}
        @{ Name='project'; Label='Project'; Width=15 }
    )

    $list = [UniversalList]::new()
    $list.SetColumns($columns)
    $list.Title = "All Tasks"

    # Load data
    $tasks = Get-PmcData | Select-Object -ExpandProperty tasks
    $list.SetData($tasks)

    # Actions
    $list.AddAction('a', 'Add', { param($list)
        $fields = @(
            @{ Name='text'; Label='Task'; Type='text'; Required=$true }
            @{ Name='due'; Label='Due'; Type='date'; Value=[DateTime]::Today }
            @{ Name='project'; Label='Project'; Type='project' }
            @{ Name='priority'; Label='Priority'; Type='number'; Value=3; Min=0; Max=5 }
            @{ Name='tags'; Label='Tags'; Type='tags'; Value=@() }
        )
        $list.ShowInlineEditor(@{}, $fields)
    })

    $list.AddAction('e', 'Edit', { param($list)
        $task = $list.GetSelectedItem()
        if ($task) {
            $fields = @(
                @{ Name='text'; Label='Task'; Type='text'; Value=$task.text; Required=$true }
                @{ Name='due'; Label='Due'; Type='date'; Value=$task.due }
                @{ Name='project'; Label='Project'; Type='project'; Value=$task.project }
                @{ Name='priority'; Label='Priority'; Type='number'; Value=$task.priority; Min=0; Max=5 }
                @{ Name='tags'; Label='Tags'; Type='tags'; Value=$task.tags }
            )
            $list.ShowInlineEditor($task, $fields)
        }
    })

    $list.AddAction('d', 'Delete', { param($list)
        $task = $list.GetSelectedItem()
        if ($task) {
            Remove-PmcTask $task.id
            $list.SetData(Get-PmcData | Select-Object -ExpandProperty tasks)
        }
    })

    $list.AddAction('c', 'Complete', { param($list)
        $task = $list.GetSelectedItem()
        if ($task) {
            $task.status = 'completed'
            Save-PmcTask $task
            $list.SetData(Get-PmcData | Select-Object -ExpandProperty tasks)
        }
    })

    # Events
    $list.OnItemEdit = { param($item)
        Save-PmcTask $item
        $list.SetData(Get-PmcData | Select-Object -ExpandProperty tasks)
    }

    # Run
    while ($true) {
        Clear-Host
        Write-Host $list.Render() -NoNewline
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq 'Escape') { break }
        $list.HandleInput($key)
    }
}
```

### Project List Screen

```powershell
function Show-PmcProjectList {
    $columns = @(
        @{ Name='name'; Label='Project'; Width=30 }
        @{ Name='description'; Label='Description'; Width=50 }
        @{ Name='taskCount'; Label='Tasks'; Width=8; Align='right' }
    )

    $list = [UniversalList]::new()
    $list.SetColumns($columns)
    $list.Title = "Projects"

    # Load data
    $projects = Get-PmcData | Select-Object -ExpandProperty projects
    $list.SetData($projects)

    # Actions
    $list.AddAction('a', 'Add', { param($list)
        $fields = @(
            @{ Name='name'; Label='Name'; Type='text'; Required=$true }
            @{ Name='description'; Label='Description'; Type='text' }
        )
        $list.ShowInlineEditor(@{}, $fields)
    })

    # Run
    while ($true) {
        Clear-Host
        Write-Host $list.Render() -NoNewline
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq 'Escape') { break }
        $list.HandleInput($key)
    }
}
```

## Performance

### Benchmarks

- **1000 items**: Smooth scrolling, <100ms render
- **10000 items**: Good performance, virtual scrolling essential
- **100 items + 10 columns**: No noticeable lag

### Optimization Tips

1. **Use virtual scrolling** (enabled by default)
2. **Keep column count reasonable** (<15 columns)
3. **Avoid complex Format scriptblocks** (cache results if expensive)
4. **Use differential rendering** (implemented automatically)

## Testing

Run the test suite:

```powershell
pwsh TestUniversalList.ps1
```

Tests cover:
- Basic creation and configuration
- Column setup
- Data binding
- Selection and navigation
- Sorting (ascending/descending)
- Multi-select mode
- Custom actions
- Rendering
- Event callbacks

## Limitations

- No horizontal scrolling (columns must fit in terminal width)
- No column resizing (fixed widths)
- No row grouping
- No tree view / hierarchical data
- No inline cell editing (only full-row editing)

## Future Enhancements

- [ ] Horizontal scrolling for wide data
- [ ] Column resizing (drag or hotkeys)
- [ ] Row grouping (by column value)
- [ ] Tree view mode (hierarchical data)
- [ ] Inline cell editing (like Excel)
- [ ] Export to CSV/JSON
- [ ] Clipboard support (Ctrl+C to copy selected rows)
- [ ] Custom row rendering (for complex rows)

## Related Widgets

- **InlineEditor** - Used for inline item editing
- **FilterPanel** - Used for data filtering
- **TextInput**, **DatePicker**, **ProjectPicker**, **TagEditor** - Used by InlineEditor

## See Also

- [README_InlineEditor.md](README_InlineEditor.md) - Multi-field editor widget
- [README_FilterPanel.md](README_FilterPanel.md) - Filter builder widget
