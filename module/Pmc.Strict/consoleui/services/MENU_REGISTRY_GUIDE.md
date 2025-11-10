# Menu Registry System

## Overview

The Menu Registry system allows screens to register their own menu items dynamically, instead of hardcoding menu structures in TaskListScreen. This creates a **decoupled, extensible menu system** where:

- Each screen controls its own menu presence
- New screens automatically appear in menus
- No central menu configuration to maintain
- Screens can be added/removed without breaking menus

## Architecture

```
┌─────────────────────┐
│  TaskListScreen     │
│  _SetupMenus()      │ 1. Creates MenuRegistry
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  MenuRegistry       │
│  DiscoverScreens()  │ 2. Scans screens/*.ps1
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  TodayViewScreen    │
│  RegisterMenuItems()│ 3. Each screen registers itself
└─────────────────────┘
           ↓
┌─────────────────────┐
│  MenuBar populated  │ 4. Menu items added to MenuBar
└─────────────────────┘
```

## Menu Structure

The registry supports these menus:

- **Tasks**: Task views and actions
- **Projects**: Project management screens
- **Time**: Time tracking screens
- **Tools**: Utilities and helpers
- **Options**: Settings and configuration
- **Help**: Help and documentation

## Adding Menu Items to Your Screen

### Step 1: Add static RegisterMenuItems method

In your screen class file (e.g., `TodayViewScreen.ps1`), add a static method:

```powershell
class TodayViewScreen : PmcScreen {

    # Static: Register menu items
    static [void] RegisterMenuItems([object]$registry) {
        $registry.AddMenuItem(
            'Tasks',                    # Menu name
            'Today',                    # Display label
            'Y',                        # Hotkey
            {                           # Action scriptblock
                . "$PSScriptRoot/TodayViewScreen.ps1"
                $global:PmcApp.PushScreen([TodayViewScreen]::new())
            },
            10                          # Sort order (optional, default 100)
        )
    }

    # Constructor and rest of class...
}
```

### Step 2: That's it!

The registry will automatically discover and register your screen when `_SetupMenus()` is called.

## Menu Item Sort Order

The `order` parameter (5th argument) controls where items appear in the menu:

- **Lower numbers appear first**
- Default order is `100`
- Use orders like:
  - `10` - Top-level views (Today, Week, etc.)
  - `50` - Specialized views (Kanban, Month View)
  - `100` - Standard items
  - `200` - Less commonly used items

### Example ordering:

```powershell
# Appears first
$registry.AddMenuItem('Tasks', 'Today', 'Y', {...}, 10)

# Appears second
$registry.AddMenuItem('Tasks', 'Week View', 'W', {...}, 20)

# Appears last
$registry.AddMenuItem('Tasks', 'Archive', 'A', {...}, 200)
```

## Adding Separators

Use separators to group related menu items:

```powershell
static [void] RegisterMenuItems([object]$registry) {
    # Main views
    $registry.AddMenuItem('Tasks', 'Today', 'Y', {...}, 10)
    $registry.AddMenuItem('Tasks', 'Week View', 'W', {...}, 20)

    # Separator before specialized views
    $registry.AddSeparator('Tasks', 40)

    # Specialized views
    $registry.AddMenuItem('Tasks', 'Kanban', 'K', {...}, 50)
}
```

## Multiple Menu Items

A single screen can register items in multiple menus:

```powershell
static [void] RegisterMenuItems([object]$registry) {
    # Add to Tasks menu
    $registry.AddMenuItem('Tasks', 'Today', 'Y', {...}, 10)

    # Add to Tools menu
    $registry.AddMenuItem('Tools', 'Quick Add', 'Q', {...}, 10)

    # Add to Help menu
    $registry.AddMenuItem('Help', 'Today Help', 'T', {...}, 50)
}
```

## Example Screens

### Simple Screen

```powershell
class ProjectStatsScreen : PmcScreen {

    static [void] RegisterMenuItems([object]$registry) {
        $registry.AddMenuItem('Projects', 'Project Stats', 'S', {
            . "$PSScriptRoot/ProjectStatsScreen.ps1"
            $global:PmcApp.PushScreen([ProjectStatsScreen]::new())
        }, 20)
    }

    # Rest of class...
}
```

### Screen with Multiple Items

```powershell
class TimeTrackingScreen : PmcScreen {

    static [void] RegisterMenuItems([object]$registry) {
        # Time menu items
        $registry.AddMenuItem('Time', 'Start Timer', 'S', {
            . "$PSScriptRoot/TimeTrackingScreen.ps1"
            $screen = [TimeTrackingScreen]::new()
            $screen.ShowStartDialog()
            $global:PmcApp.PushScreen($screen)
        }, 10)

        $registry.AddMenuItem('Time', 'Time Report', 'R', {
            . "$PSScriptRoot/TimeReportScreen.ps1"
            $global:PmcApp.PushScreen([TimeReportScreen]::new())
        }, 20)

        # Also add to Tools menu
        $registry.AddMenuItem('Tools', 'Quick Timer', 'T', {
            [TimeTracker]::QuickStart()
        }, 50)
    }

    # Rest of class...
}
```

## Migration Guide

### Old Way (Hardcoded in TaskListScreen)

```powershell
# In TaskListScreen._SetupMenus():
$tasksMenu.Items.Add([PmcMenuItem]::new("Today", 'Y', {
    . "$PSScriptRoot/TodayViewScreen.ps1"
    $global:PmcApp.PushScreen([TodayViewScreen]::new())
}))
```

### New Way (Self-registered)

```powershell
# In TodayViewScreen.ps1:
class TodayViewScreen : PmcScreen {
    static [void] RegisterMenuItems([object]$registry) {
        $registry.AddMenuItem('Tasks', 'Today', 'Y', {
            . "$PSScriptRoot/TodayViewScreen.ps1"
            $global:PmcApp.PushScreen([TodayViewScreen]::new())
        }, 10)
    }
}
```

## Benefits

1. **Decoupling**: Screens don't depend on TaskListScreen
2. **Discoverability**: New screens automatically appear in menus
3. **Maintainability**: Each screen owns its menu presence
4. **Flexibility**: Screens can register in multiple menus
5. **Order Control**: Fine-grained control over menu item placement
6. **No Central Config**: No need to edit TaskListScreen when adding screens

## API Reference

### MenuRegistry Methods

#### AddMenuItem
```powershell
[void] AddMenuItem([string]$menuName, [string]$label, [char]$hotkey, [scriptblock]$action)
[void] AddMenuItem([string]$menuName, [string]$label, [char]$hotkey, [scriptblock]$action, [int]$order)
```

Add a menu item to the specified menu.

**Parameters:**
- `$menuName` - Menu to add to ('Tasks', 'Projects', 'Time', 'Tools', 'Options', 'Help')
- `$label` - Display label for the menu item
- `$hotkey` - Keyboard shortcut (single character)
- `$action` - Scriptblock to execute when selected
- `$order` - Sort order (lower numbers appear first, default 100)

#### AddSeparator
```powershell
[void] AddSeparator([string]$menuName)
[void] AddSeparator([string]$menuName, [int]$order)
```

Add a separator line to visually group menu items.

**Parameters:**
- `$menuName` - Menu to add separator to
- `$order` - Sort order for the separator (default 100)

#### GetMenuItems
```powershell
[array] GetMenuItems([string]$menuName)
```

Get all menu items for a specific menu, sorted by order.

**Returns:** Array of menu item hashtables `@{ Label='...'; Hotkey='...'; Action={...}; Order=10 }`

#### GetAllMenus
```powershell
[hashtable] GetAllMenus()
```

Get all registered menus with items.

**Returns:** Hashtable mapping menu names to sorted item arrays

#### DiscoverScreens
```powershell
[void] DiscoverScreens([string[]]$screenPaths)
```

Scan screen files and call their RegisterMenuItems methods.

**Parameters:**
- `$screenPaths` - Array of .ps1 file paths to scan

## Troubleshooting

### Menu items not appearing

1. Check that your screen file ends with `Screen.ps1`
2. Verify the static method is exactly: `static [void] RegisterMenuItems([object]$registry)`
3. Ensure the screen class is defined before the registration method
4. Check for syntax errors in the scriptblock

### Wrong menu order

- Remember: **lower numbers = appear first**
- Check other items' order values in the same menu
- Use intermediate values (15, 25) to insert between existing items

### Hotkey conflicts

- Each hotkey should be unique within a menu
- The MenuBar widget will show conflicts visually
- Choose a different letter or use less common keys

## Future Enhancements

Possible future additions:

- Dynamic menu updates when screens are loaded at runtime
- Menu item enable/disable based on context
- Submenu support
- Icon/emoji support for menu items
- Localization support for labels
