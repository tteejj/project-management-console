# ProjectPicker Widget

Project selection widget with fuzzy search and inline project creation.

## Features

- **Load projects** from Get-PmcData
- **Type-ahead fuzzy filtering** (matches substrings and initials)
- **Arrow key navigation** through filtered list
- **Enter to select** project
- **Alt+N to create** new project inline (switches to TextInput mode)
- **Recent projects** shown at top (optional)
- **Project count** display
- **OnProjectSelected** event callback
- **Visual list** with scroll indicators
- **Empty state** handling

## Usage

```powershell
# Basic usage
$picker = [ProjectPicker]::new()
$picker.SetPosition(10, 5)
$picker.SetSize(35, 12)
$picker.Label = "Select Project"

# Event handling
$picker.OnProjectSelected = { param($projectName)
    Write-Host "Selected: $projectName"
}

$picker.OnProjectCreated = { param($projectName)
    Write-Host "Created new project: $projectName"
}

# Render
$ansiOutput = $picker.Render()
Write-Host $ansiOutput -NoNewline

# Handle input
$key = [Console]::ReadKey($true)
$handled = $picker.HandleInput($key)

# Get result
if ($picker.IsConfirmed) {
    $selected = $picker.GetSelectedProject()
}
```

## Properties

- `Label` - Widget title (default: "Select Project")
- `ShowRecentFirst` - Show recent projects at top (default: true)
- `IsConfirmed` - True when project selected
- `IsCancelled` - True when Esc pressed

## Events

- `OnProjectSelected` - Called when project selected: `param($projectName)`
- `OnProjectCreated` - Called when new project created: `param($projectName)`
- `OnCancelled` - Called when Esc pressed

## Keyboard Controls

### Browse Mode
- **Enter** - Select current project
- **Escape** - Cancel
- **Up/Down Arrow** - Navigate list
- **PageUp/PageDown** - Fast navigation
- **Home/End** - Jump to first/last
- **Type characters** - Filter list (fuzzy search)
- **Backspace** - Remove last search character
- **Ctrl+U** - Clear search
- **Alt+N** - Create new project

### Create Mode (Alt+N)
- **Enter** - Create project and select it
- **Escape** - Cancel creation, return to browse mode
- **Left/Right Arrow** - Move cursor
- **Home/End** - Jump to start/end
- **Backspace/Delete** - Edit text
- **Type characters** - Enter project name

## Fuzzy Search

The fuzzy search matches:
- **Substrings**: "web" matches "webapp", "web-backend"
- **Initials**: "wb" matches "work-backend", "webapp"
- **Character sequences**: "wap" matches "webapp"

Examples:
```
Search: "wb"     → Matches: "webapp", "work-backend"
Search: "work"   → Matches: "work", "work-backend"
Search: "end"    → Matches: "backend", "frontend"
```

## Project Creation

When you press Alt+N:
1. Widget switches to create mode
2. Enter new project name
3. Press Enter to create (validates for duplicates and empty names)
4. New project is automatically selected
5. OnProjectCreated and OnProjectSelected events fire

Validation:
- Project name cannot be empty
- Duplicate project names are rejected

## Data Integration

Projects are loaded from `Get-PmcData`:
```powershell
$data = Get-PmcData
foreach ($project in $data.projects) {
    # project.name is displayed
}
```

New projects are saved via `Save-PmcData`:
```powershell
$newProject = [PSCustomObject]@{
    name = $projectName
    description = ""
    aliases = @()
    created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}
$data.projects += $newProject
Save-PmcData $data
```

## Testing

Run the test suite:

```powershell
./TestProjectPicker.ps1 -Verbose
```

Test suite includes mocked `Get-PmcData` and `Save-PmcData` functions.

## Implementation Details

- Extends `PmcWidget` base class
- Auto-refreshes project list every 5 seconds
- Scroll offset adjusts to keep selection visible
- Two-mode operation: browse and create
- Theme colors from PMC theme system
