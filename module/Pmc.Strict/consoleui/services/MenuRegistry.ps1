# MenuRegistry.ps1 - Dynamic menu registration system
#
# Allows screens to register their own menu items instead of hardcoding
# menu structure in TaskListScreen.
#
# Usage in screen classes:
#   static [void] RegisterMenuItems([MenuRegistry]$registry) {
#       $registry.AddMenuItem('Tasks', 'Today View', 'Y', {
#           . "$PSScriptRoot/TodayViewScreen.ps1"
#           $global:PmcApp.PushScreen([TodayViewScreen]::new())
#       })
#   }

using namespace System
using namespace System.Collections.Generic

Set-StrictMode -Version Latest

<#
.SYNOPSIS
Dynamic menu registration system for PMC screens

.DESCRIPTION
MenuRegistry allows screens to register their own menu items dynamically.
This decouples menu structure from TaskListScreen and allows screens to
control their own menu presence.

Menu structure:
- Tasks: Task views and actions
- Projects: Project management screens
- Time: Time tracking screens
- Tools: Utilities and helpers
- Options: Settings and configuration
- Help: Help and about screens

.EXAMPLE
$registry = [MenuRegistry]::new()
$registry.AddMenuItem('Tasks', 'Today', 'Y', { Show-TodayView })
$menuItems = $registry.GetMenuItems('Tasks')
#>
class MenuRegistry {
    # Singleton instance
    static [MenuRegistry]$_instance = $null

    # Menu structure: @{ 'Tasks' = @( @{ Label='Today'; Hotkey='Y'; Action={...} }, ... ) }
    [hashtable]$_menuItems = @{
        'Tasks' = [List[hashtable]]::new()
        'Projects' = [List[hashtable]]::new()
        'Time' = [List[hashtable]]::new()
        'Tools' = [List[hashtable]]::new()
        'Options' = [List[hashtable]]::new()
        'Help' = [List[hashtable]]::new()
    }

    # === Singleton Pattern ===

    <#
    .SYNOPSIS
    Get the singleton instance of MenuRegistry

    .OUTPUTS
    MenuRegistry singleton instance
    #>
    static [MenuRegistry] GetInstance() {
        if ($null -eq [MenuRegistry]::_instance) {
            [MenuRegistry]::_instance = [MenuRegistry]::new()
        }
        return [MenuRegistry]::_instance
    }

    # Private constructor for singleton
    hidden MenuRegistry() {
        # Initialize menu structure
    }

    # === Registration ===

    <#
    .SYNOPSIS
    Register a menu item

    .PARAMETER menuName
    Menu to add item to ('Tasks', 'Projects', 'Time', 'Tools', 'Options', 'Help')

    .PARAMETER label
    Display label for menu item

    .PARAMETER hotkey
    Keyboard shortcut (single character or [char]0 for separator)

    .PARAMETER action
    Scriptblock to execute when item is selected

    .PARAMETER order
    Optional sort order (lower numbers appear first, default 100)
    #>
    [void] AddMenuItem([string]$menuName, [string]$label, [char]$hotkey, [scriptblock]$action) {
        $this.AddMenuItem($menuName, $label, $hotkey, $action, 100)
    }

    [void] AddMenuItem([string]$menuName, [string]$label, [char]$hotkey, [scriptblock]$action, [int]$order) {
        if (-not $this._menuItems.ContainsKey($menuName)) {
            throw "Invalid menu name: $menuName. Valid: Tasks, Projects, Time, Tools, Options, Help"
        }

        $item = @{
            Label = $label
            Hotkey = $hotkey
            Action = $action
            Order = $order
        }

        $this._menuItems[$menuName].Add($item)
    }

    <#
    .SYNOPSIS
    Add a menu separator

    .PARAMETER menuName
    Menu to add separator to
    #>
    [void] AddSeparator([string]$menuName) {
        $this.AddMenuItem($menuName, "", [char]0, $null, 100)
    }

    [void] AddSeparator([string]$menuName, [int]$order) {
        $this.AddMenuItem($menuName, "", [char]0, $null, $order)
    }

    # === Retrieval ===

    <#
    .SYNOPSIS
    Get all menu items for a specific menu, sorted by order

    .PARAMETER menuName
    Menu name ('Tasks', 'Projects', etc.)

    .OUTPUTS
    Array of menu item hashtables sorted by Order
    #>
    [array] GetMenuItems([string]$menuName) {
        if (-not $this._menuItems.ContainsKey($menuName)) {
            return @()
        }

        # Sort by Order, then by Label
        return $this._menuItems[$menuName] | Sort-Object -Property Order, Label
    }

    <#
    .SYNOPSIS
    Get all registered menus with items

    .OUTPUTS
    Hashtable of menu names to sorted item arrays
    #>
    [hashtable] GetAllMenus() {
        $result = @{}
        foreach ($menuName in $this._menuItems.Keys) {
            $items = $this.GetMenuItems($menuName)
            if ($items.Count -gt 0) {
                $result[$menuName] = $items
            }
        }
        return $result
    }

    <#
    .SYNOPSIS
    Clear all registered menu items (for testing/reset)
    #>
    [void] Clear() {
        foreach ($menuName in $this._menuItems.Keys) {
            $this._menuItems[$menuName].Clear()
        }
    }

    # === Auto-Discovery ===

    <#
    .SYNOPSIS
    Discover and register menu items from all screen classes

    .PARAMETER screenPaths
    Array of screen file paths to load and register

    .DESCRIPTION
    Loads screen files and calls static RegisterMenuItems method if it exists
    #>
    [void] DiscoverScreens([string[]]$screenPaths) {
        foreach ($screenPath in $screenPaths) {
            if (-not (Test-Path $screenPath)) { continue }

            try {
                # Dot-source the screen file
                . $screenPath

                # Get screen class name from file name
                $fileName = [System.IO.Path]::GetFileNameWithoutExtension($screenPath)

                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] MenuRegistry.DiscoverScreens: Checking '$fileName'"
                }

                # Try to call static RegisterMenuItems method if it exists
                $type = $fileName -as [Type]
                if ($null -ne $type) {
                    if ($global:PmcTuiLogFile) {
                        Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] MenuRegistry: Found type '$fileName'"
                    }
                    $method = $type.GetMethod('RegisterMenuItems', [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::Public)
                    if ($null -ne $method) {
                        if ($global:PmcTuiLogFile) {
                            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] MenuRegistry: Calling RegisterMenuItems for '$fileName'"
                        }
                        $method.Invoke($null, @($this))
                    } else {
                        if ($global:PmcTuiLogFile) {
                            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] MenuRegistry: No RegisterMenuItems method on '$fileName'"
                        }
                    }
                } else {
                    if ($global:PmcTuiLogFile) {
                        Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] MenuRegistry: Type '$fileName' not found (not loaded yet?)"
                    }
                }
            } catch {
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] MenuRegistry: Error discovering '$fileName': $_"
                }
                # Silently skip screens that don't have RegisterMenuItems or fail to load
                # This allows gradual adoption without breaking existing screens
            }
        }
    }
}

# Export for module usage
if ($MyInvocation.MyCommand.Path) {
    Export-ModuleMember -Variable MenuRegistry
}
