# PMC FakeTUI Menu System - Keyboard-driven menus with dropdowns
# Excel/lynx-style navigation with Alt+key hotkeys

. "$PSScriptRoot/../Core/SimpleTerminal.ps1"

<#
.SYNOPSIS
Menu definition class for FakeTUI
#>
class PmcMenuItem {
    [string]$Label
    [string]$Action  # Command to execute or submenu to open
    [char]$Hotkey    # Single character hotkey
    [bool]$Enabled = $true
    [bool]$Separator = $false  # Is this a separator line?

    PmcMenuItem([string]$label, [string]$action, [char]$hotkey) {
        $this.Label = $label
        $this.Action = $action
        $this.Hotkey = $hotkey
    }

    # Create separator
    static [PmcMenuItem] Separator() {
        $item = [PmcMenuItem]::new("", "", ' ')
        $item.Separator = $true
        return $item
    }
}

<#
.SYNOPSIS
Main menu system for PMC FakeTUI - keyboard-only navigation
.DESCRIPTION
Provides Excel/lynx-style menu navigation:
- Alt activates menu mode
- Letter keys navigate to menus
- Arrow keys navigate within dropdowns
- Enter selects, Escape cancels
- No mouse support, pure keyboard
#>
class PmcMenuSystem {
    [PmcSimpleTerminal]$terminal
    [hashtable]$menus = @{}
    [string[]]$menuOrder = @()
    [int]$selectedMenu = -1
    [bool]$inMenuMode = $false
    [bool]$showingDropdown = $false

    PmcMenuSystem() {
        $this.terminal = [PmcSimpleTerminal]::GetInstance()
        $this.InitializeDefaultMenus()
    }

    # Initialize default PMC menus
    [void] InitializeDefaultMenus() {
        # File menu
        $this.AddMenu('File', 'F', @(
            [PmcMenuItem]::new('New Project', 'project:new', 'N'),
            [PmcMenuItem]::new('Open Recent', 'file:recent', 'R'),
            [PmcMenuItem]::Separator(),
            [PmcMenuItem]::new('Import Data', 'import:data', 'I'),
            [PmcMenuItem]::new('Export Data', 'export:data', 'E'),
            [PmcMenuItem]::Separator(),
            [PmcMenuItem]::new('Exit', 'app:exit', 'X')
        ))

        # Task menu
        $this.AddMenu('Task', 'T', @(
            [PmcMenuItem]::new('Add Task', 'task:add', 'A'),
            [PmcMenuItem]::new('List Tasks', 'task:list', 'L'),
            [PmcMenuItem]::new('Search Tasks', 'task:search', 'S'),
            [PmcMenuItem]::Separator(),
            [PmcMenuItem]::new('Mark Done', 'task:done', 'D'),
            [PmcMenuItem]::new('Edit Task', 'task:edit', 'E'),
            [PmcMenuItem]::new('Delete Task', 'task:delete', 'X')
        ))

        # Project menu
        $this.AddMenu('Project', 'P', @(
            [PmcMenuItem]::new('Create Project', 'project:create', 'C'),
            [PmcMenuItem]::new('Switch Project', 'project:switch', 'S'),
            [PmcMenuItem]::new('Project Stats', 'project:stats', 'T'),
            [PmcMenuItem]::Separator(),
            [PmcMenuItem]::new('Archive Project', 'project:archive', 'A')
        ))

        # View menu
        $this.AddMenu('View', 'V', @(
            [PmcMenuItem]::new('Today', 'view:today', 'T'),
            [PmcMenuItem]::new('This Week', 'view:week', 'W'),
            [PmcMenuItem]::new('Overdue', 'view:overdue', 'O'),
            [PmcMenuItem]::Separator(),
            [PmcMenuItem]::new('Kanban Board', 'view:kanban', 'K'),
            [PmcMenuItem]::new('Grid View', 'view:grid', 'G')
        ))

        # Tools menu
        $this.AddMenu('Tools', 'O', @(
            [PmcMenuItem]::new('Settings', 'tools:settings', 'S'),
            [PmcMenuItem]::new('Theme', 'tools:theme', 'T'),
            [PmcMenuItem]::new('Debug Info', 'tools:debug', 'D'),
            [PmcMenuItem]::Separator(),
            [PmcMenuItem]::new('Backup Data', 'tools:backup', 'B')
        ))

        # Help menu
        $this.AddMenu('Help', 'H', @(
            [PmcMenuItem]::new('Commands', 'help:commands', 'C'),
            [PmcMenuItem]::new('Keyboard Shortcuts', 'help:keys', 'K'),
            [PmcMenuItem]::new('Quick Guide', 'help:guide', 'G'),
            [PmcMenuItem]::Separator(),
            [PmcMenuItem]::new('About PMC', 'help:about', 'A')
        ))
    }

    # Add a menu to the system
    [void] AddMenu([string]$name, [char]$hotkey, [PmcMenuItem[]]$items) {
        $this.menus[$name] = @{
            Name = $name
            Hotkey = $hotkey
            Items = $items
        }
        $this.menuOrder += $name
    }

    # Draw the menu bar
    [void] DrawMenuBar() {
        $this.terminal.UpdateDimensions()

        # Clear the menu bar line
        $this.terminal.FillArea(0, 0, $this.terminal.Width, 1, ' ')

        # Build menu bar text with hotkey indicators
        $menuText = ""
        $x = 2

        for ($i = 0; $i -lt $this.menuOrder.Count; $i++) {
            $menuName = $this.menuOrder[$i]
            $menu = $this.menus[$menuName]
            $hotkey = $menu.Hotkey

            # Highlight if this menu is selected
            if ($this.inMenuMode -and $i -eq $this.selectedMenu) {
                # Use colors for selection
                $this.terminal.WriteAtColor($x, 0, $menuName, [PmcVT100]::BgWhite(), [PmcVT100]::Blue())
                $this.terminal.WriteAtColor($x + $menuName.Length, 0, "($hotkey)", [PmcVT100]::Yellow(), "")
            } else {
                # Normal menu item
                $this.terminal.WriteAt($x, 0, $menuName)
                $this.terminal.WriteAtColor($x + $menuName.Length, 0, "($hotkey)", [PmcVT100]::Yellow(), "")
            }

            $x += $menuName.Length + 3 + 3  # name + "(X)" + spacing
        }

        # Add status text
        if ($this.inMenuMode) {
            $statusText = " [Menu Mode: Use arrow keys, Enter to select, Esc to exit] "
            $statusX = $this.terminal.Width - $statusText.Length
            if ($statusX -gt $x + 10) {  # Only show if there's room
                $this.terminal.WriteAtColor($statusX, 0, $statusText, [PmcVT100]::Cyan(), "")
            }
        } else {
            $statusText = " [Press Alt to activate menus] "
            $statusX = $this.terminal.Width - $statusText.Length
            if ($statusX -gt $x + 10) {
                $this.terminal.WriteAtColor($statusX, 0, $statusText, [PmcVT100]::Yellow(), "")
            }
        }

        # Draw separator line under menu bar
        $this.terminal.DrawHorizontalLine(0, 1, $this.terminal.Width)
    }

    # Show dropdown for selected menu
    [string] ShowDropdown([string]$menuName) {
        $menu = $this.menus[$menuName]
        if (-not $menu) { return "" }

        $items = $menu.Items
        $maxWidth = 20

        # Calculate dropdown size and position
        foreach ($item in $items) {
            if (-not $item.Separator -and $item.Label.Length -gt $maxWidth) {
                $maxWidth = $item.Label.Length + 2
            }
        }

        # Position dropdown under the menu
        $menuIndex = $this.menuOrder.IndexOf($menuName)
        $dropdownX = 2
        for ($i = 0; $i -lt $menuIndex; $i++) {
            $prevMenu = $this.menuOrder[$i]
            $dropdownX += $prevMenu.Length + 6  # name + "(X)" + spacing
        }

        $dropdownY = 2
        $dropdownHeight = $items.Count + 2

        # Draw dropdown box
        $this.terminal.DrawFilledBox($dropdownX, $dropdownY, $maxWidth, $dropdownHeight, $true)

        # Draw menu items
        $selectedItem = 0
        $this.showingDropdown = $true

        while ($this.showingDropdown) {
            # Draw all items
            for ($i = 0; $i -lt $items.Count; $i++) {
                $item = $items[$i]
                $itemY = $dropdownY + 1 + $i

                if ($item.Separator) {
                    # Draw separator line
                    $this.terminal.DrawHorizontalLine($dropdownX + 1, $itemY, $maxWidth - 2)
                } else {
                    # Prepare item text with hotkey
                    $itemText = " {0}({1}) " -f $item.Label, $item.Hotkey

                    # Highlight selected item
                    if ($i -eq $selectedItem -and $item.Enabled) {
                        $this.terminal.WriteAtColor($dropdownX + 1, $itemY, $itemText.PadRight($maxWidth - 2), [PmcVT100]::BgBlue(), [PmcVT100]::White())
                    } elseif (-not $item.Enabled) {
                        # Disabled item
                        $this.terminal.WriteAtColor($dropdownX + 1, $itemY, $itemText.PadRight($maxWidth - 2), [PmcVT100]::Blue(), "")
                    } else {
                        # Normal item
                        $this.terminal.WriteAt($dropdownX + 1, $itemY, $itemText.PadRight($maxWidth - 2))
                    }
                }
            }

            # Wait for key input
            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                'UpArrow' {
                    do {
                        $selectedItem--
                        if ($selectedItem -lt 0) { $selectedItem = $items.Count - 1 }
                    } while ($items[$selectedItem].Separator -or -not $items[$selectedItem].Enabled)
                }
                'DownArrow' {
                    do {
                        $selectedItem++
                        if ($selectedItem -ge $items.Count) { $selectedItem = 0 }
                    } while ($items[$selectedItem].Separator -or -not $items[$selectedItem].Enabled)
                }
                'Enter' {
                    if ($selectedItem -ge 0 -and $selectedItem -lt $items.Count) {
                        $selectedMenuItem = $items[$selectedItem]
                        if (-not $selectedMenuItem.Separator -and $selectedMenuItem.Enabled) {
                            $this.showingDropdown = $false
                            $this.inMenuMode = $false
                            $this.selectedMenu = -1
                            # Clear dropdown area
                            $this.terminal.FillArea($dropdownX, $dropdownY, $maxWidth, $dropdownHeight, ' ')
                            return $selectedMenuItem.Action
                        }
                    }
                }
                'Escape' {
                    $this.showingDropdown = $false
                    # Clear dropdown area
                    $this.terminal.FillArea($dropdownX, $dropdownY, $maxWidth, $dropdownHeight, ' ')
                    break
                }
                default {
                    # Check for hotkey match
                    $keyChar = [char]::ToUpper($key.KeyChar)
                    for ($i = 0; $i -lt $items.Count; $i++) {
                        if (-not $items[$i].Separator -and $items[$i].Enabled -and [char]::ToUpper($items[$i].Hotkey) -eq $keyChar) {
                            $this.showingDropdown = $false
                            $this.inMenuMode = $false
                            $this.selectedMenu = -1
                            # Clear dropdown area
                            $this.terminal.FillArea($dropdownX, $dropdownY, $maxWidth, $dropdownHeight, ' ')
                            return $items[$i].Action
                        }
                    }
                }
            }
        }

        return ""
    }

    # Main input handling loop
    [string] HandleInput() {
        while ($true) {
            # Redraw menu bar to reflect current state
            $this.DrawMenuBar()

            # Wait for key input
            $key = [Console]::ReadKey($true)

            if (-not $this.inMenuMode) {
                # Not in menu mode - check for Alt key or other global keys
                if ( ($key.Key -eq 'F10') -or (($key.Modifiers -band [System.ConsoleModifiers]::Alt) -ne 0) ) {
                    # Enter menu mode
                    $this.inMenuMode = $true
                    $this.selectedMenu = 0
                    continue
                }

                # Check for direct Alt+Letter combinations
                if ((($key.Modifiers -band [System.ConsoleModifiers]::Alt) -ne 0) -and [char]::IsLetter($key.KeyChar)) {
                    $keyChar = [char]::ToUpper($key.KeyChar)
                    for ($i = 0; $i -lt $this.menuOrder.Count; $i++) {
                        $menuName = $this.menuOrder[$i]
                        if ([char]::ToUpper($this.menus[$menuName].Hotkey) -eq $keyChar) {
                            # Open dropdown directly
                            return $this.ShowDropdown($menuName)
                        }
                    }
                }

                # Other global keys can be handled here
                if ($key.Key -eq 'Escape' -or ($key.Key -eq 'Q' -and (($key.Modifiers -band [System.ConsoleModifiers]::Control) -ne 0))) {
                    return "app:exit"
                }

                # Return to caller for other key handling
                return ""

            } else {
                # In menu mode - handle menu navigation
                switch ($key.Key) {
                    'LeftArrow' {
                        if ($this.selectedMenu -gt 0) {
                            $this.selectedMenu--
                        } else {
                            $this.selectedMenu = $this.menuOrder.Count - 1
                        }
                    }
                    'RightArrow' {
                        if ($this.selectedMenu -lt $this.menuOrder.Count - 1) {
                            $this.selectedMenu++
                        } else {
                            $this.selectedMenu = 0
                        }
                    }
                    'Enter' {
                        if ($this.selectedMenu -ge 0 -and $this.selectedMenu -lt $this.menuOrder.Count) {
                            $menuName = $this.menuOrder[$this.selectedMenu]
                            return $this.ShowDropdown($menuName)
                        }
                    }
                    'Escape' {
                        $this.inMenuMode = $false
                        $this.selectedMenu = -1
                    }
                    default {
                        # Check for menu hotkeys
                        $keyChar = [char]::ToUpper($key.KeyChar)
                        for ($i = 0; $i -lt $this.menuOrder.Count; $i++) {
                            $menuName = $this.menuOrder[$i]
                            if ([char]::ToUpper($this.menus[$menuName].Hotkey) -eq $keyChar) {
                                $this.selectedMenu = $i
                                return $this.ShowDropdown($menuName)
                            }
                        }
                    }
                }
            }
        }
        # Satisfy typed method requirement
        return ""
    }

    # Get friendly name for action (for display purposes)
    [string] GetActionDescription([string]$action) {
        $descriptions = @{
            'project:new' = 'Create New Project'
            'task:add' = 'Add New Task'
            'task:list' = 'List All Tasks'
            'task:search' = 'Search Tasks'
            'view:today' = 'Show Today View'
            'view:kanban' = 'Show Kanban Board'
            'app:exit' = 'Exit PMC'
            # Add more as needed
        }

        if ($descriptions.ContainsKey($action)) {
            return $descriptions[$action]
        }

        return $action
    }
}
