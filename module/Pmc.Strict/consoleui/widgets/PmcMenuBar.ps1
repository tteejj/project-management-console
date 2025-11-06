# PmcMenuBar - Top-level navigation menu with dropdown support
# Full keyboard navigation, hotkeys, and dropdown menus

using namespace System.Collections.Generic
using namespace System.Text

<#
.SYNOPSIS
Menu item within a dropdown menu

.DESCRIPTION
Represents a single item in a dropdown menu with:
- Display label
- Hotkey character
- Action scriptblock
- Enabled/disabled state
- Separator flag
#>
class PmcMenuItem {
    [string]$Label = ""
    [char]$Hotkey = [char]0
    [scriptblock]$Action = $null
    [bool]$Enabled = $true
    [bool]$IsSeparator = $false
    [string]$Description = ""  # Optional hint text

    PmcMenuItem([string]$label, [char]$hotkey, [scriptblock]$action) {
        $this.Label = $label
        $this.Hotkey = $hotkey
        $this.Action = $action
    }

    # Constructor for separator
    static [PmcMenuItem] Separator() {
        $item = [PmcMenuItem]::new("", [char]0, $null)
        $item.IsSeparator = $true
        return $item
    }
}

<#
.SYNOPSIS
Top-level menu containing dropdown items

.DESCRIPTION
Represents a menu in the menu bar (e.g., "File", "Edit", "View")
#>
class PmcMenu {
    [string]$Title = ""
    [char]$Hotkey = [char]0
    [List[PmcMenuItem]]$Items

    PmcMenu([string]$title, [char]$hotkey) {
        $this.Title = $title
        $this.Hotkey = $hotkey
        $this.Items = [List[PmcMenuItem]]::new()
    }

    [PmcMenu] AddItem([string]$label, [char]$hotkey, [scriptblock]$action) {
        $this.Items.Add([PmcMenuItem]::new($label, $hotkey, $action))
        return $this
    }

    [PmcMenu] AddSeparator() {
        $this.Items.Add([PmcMenuItem]::Separator())
        return $this
    }
}

<#
.SYNOPSIS
Menu bar widget with dropdown menus

.DESCRIPTION
PmcMenuBar provides:
- Top-level horizontal menu bar
- Dropdown menus on activation
- Full keyboard navigation (arrows, hotkeys)
- Themed rendering
- Event callbacks

.EXAMPLE
$menuBar = [PmcMenuBar]::new()
$menuBar.AddMenu('File', 'F', @(
    [PmcMenuItem]::new('New', 'N', { Write-Host "New!" })
    [PmcMenuItem]::new('Open', 'O', { Write-Host "Open!" })
    [PmcMenuItem]::Separator()
    [PmcMenuItem]::new('Exit', 'X', { exit })
))
#>
class PmcMenuBar : PmcWidget {
    # === Properties ===
    [List[PmcMenu]]$Menus
    [int]$SelectedMenuIndex = -1        # Which menu is selected (hover)
    [int]$SelectedItemIndex = -1        # Which item in dropdown is selected
    [bool]$IsActive = $false            # Menu bar has focus
    [bool]$DropdownVisible = $false     # Dropdown is showing

    # === Events ===
    [scriptblock]$OnMenuItemSelected = $null

    # === Cached Render Data ===
    hidden [List[int]]$_menuXPositions = [List[int]]::new()  # X position of each menu
    hidden [int]$_dropdownWidth = 0
    hidden [string]$_cachedMenuBar = ""

    # === Previous Dropdown Tracking (for clearing) ===
    hidden [int]$_prevDropdownX = -1
    hidden [int]$_prevDropdownY = -1
    hidden [int]$_prevDropdownWidth = 0
    hidden [int]$_prevDropdownHeight = 0

    # === Constructor ===
    PmcMenuBar() : base("MenuBar") {
        $this.Menus = [List[PmcMenu]]::new()
        $this.CanFocus = $true

        # Default size (will be set by layout manager)
        $this.Width = 80
        $this.Height = 1
    }

    # === Menu Management ===

    <#
    .SYNOPSIS
    Add a menu to the menu bar

    .PARAMETER title
    Menu title (e.g., "File")

    .PARAMETER hotkey
    Hotkey character (e.g., 'F')

    .PARAMETER items
    Array of PmcMenuItem objects

    .EXAMPLE
    $menuBar.AddMenu('File', 'F', @(
        [PmcMenuItem]::new('Exit', 'X', { exit })
    ))
    #>
    [PmcMenuBar] AddMenu([string]$title, [char]$hotkey, [array]$items) {
        $menu = [PmcMenu]::new($title, $hotkey)
        foreach ($item in $items) {
            $menu.Items.Add($item)
        }
        $this.Menus.Add($menu)
        $this.InvalidateRenderCache()
        return $this
    }

    # === Navigation ===

    <#
    .SYNOPSIS
    Activate the menu bar (show first menu or highlight bar)
    #>
    [void] Activate() {
        $this.IsActive = $true
        if ($this.Menus.Count -gt 0) {
            $this.SelectedMenuIndex = 0
        }
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Deactivate the menu bar
    #>
    [void] Deactivate() {
        $this.IsActive = $false
        $this.DropdownVisible = $false
        $this.SelectedMenuIndex = -1
        $this.SelectedItemIndex = -1
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Show dropdown for currently selected menu
    #>
    [void] ShowDropdown() {
        if ($this.SelectedMenuIndex -ge 0 -and $this.SelectedMenuIndex -lt $this.Menus.Count) {
            $this.DropdownVisible = $true
            $this.SelectedItemIndex = 0
            # Skip separators
            $this._SelectNextEnabledItem()
            $this.Invalidate()
        }
    }

    <#
    .SYNOPSIS
    Hide dropdown
    #>
    [void] HideDropdown() {
        $this.DropdownVisible = $false
        $this.SelectedItemIndex = -1
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Move selection to next menu
    #>
    [void] SelectNextMenu() {
        if ($this.Menus.Count -eq 0) { return }
        $this.SelectedMenuIndex = ($this.SelectedMenuIndex + 1) % $this.Menus.Count
        $this.SelectedItemIndex = -1
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Move selection to previous menu
    #>
    [void] SelectPreviousMenu() {
        if ($this.Menus.Count -eq 0) { return }
        $this.SelectedMenuIndex--
        if ($this.SelectedMenuIndex -lt 0) {
            $this.SelectedMenuIndex = $this.Menus.Count - 1
        }
        $this.SelectedItemIndex = -1
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Move selection to next item in dropdown
    #>
    [void] SelectNextItem() {
        if (-not $this.DropdownVisible -or $this.SelectedMenuIndex -lt 0) { return }
        $menu = $this.Menus[$this.SelectedMenuIndex]
        if ($menu.Items.Count -eq 0) { return }

        $this.SelectedItemIndex = ($this.SelectedItemIndex + 1) % $menu.Items.Count
        $this._SelectNextEnabledItem()
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Move selection to previous item in dropdown
    #>
    [void] SelectPreviousItem() {
        if (-not $this.DropdownVisible -or $this.SelectedMenuIndex -lt 0) { return }
        $menu = $this.Menus[$this.SelectedMenuIndex]
        if ($menu.Items.Count -eq 0) { return }

        $this.SelectedItemIndex--
        if ($this.SelectedItemIndex -lt 0) {
            $this.SelectedItemIndex = $menu.Items.Count - 1
        }
        $this._SelectPreviousEnabledItem()
        $this.Invalidate()
    }

    # Skip separators and disabled items
    hidden [void] _SelectNextEnabledItem() {
        if ($this.SelectedMenuIndex -lt 0) { return }
        $menu = $this.Menus[$this.SelectedMenuIndex]
        $attempts = 0
        while ($attempts -lt $menu.Items.Count) {
            $item = $menu.Items[$this.SelectedItemIndex]
            if (-not $item.IsSeparator -and $item.Enabled) { break }
            $this.SelectedItemIndex = ($this.SelectedItemIndex + 1) % $menu.Items.Count
            $attempts++
        }
    }

    hidden [void] _SelectPreviousEnabledItem() {
        if ($this.SelectedMenuIndex -lt 0) { return }
        $menu = $this.Menus[$this.SelectedMenuIndex]
        $attempts = 0
        while ($attempts -lt $menu.Items.Count) {
            $item = $menu.Items[$this.SelectedItemIndex]
            if (-not $item.IsSeparator -and $item.Enabled) { break }
            $this.SelectedItemIndex--
            if ($this.SelectedItemIndex -lt 0) {
                $this.SelectedItemIndex = $menu.Items.Count - 1
            }
            $attempts++
        }
    }

    <#
    .SYNOPSIS
    Execute currently selected menu item
    #>
    [bool] ExecuteSelectedItem() {
        if (-not $this.DropdownVisible -or $this.SelectedMenuIndex -lt 0 -or $this.SelectedItemIndex -lt 0) {
            return $false
        }

        $menu = $this.Menus[$this.SelectedMenuIndex]
        if ($this.SelectedItemIndex -ge $menu.Items.Count) {
            return $false
        }

        $item = $menu.Items[$this.SelectedItemIndex]
        if ($item.IsSeparator -or -not $item.Enabled) {
            return $false
        }

        # Execute action
        if ($item.Action) {
            & $item.Action
        }

        # Fire event
        if ($this.OnMenuItemSelected) {
            & $this.OnMenuItemSelected $this $menu $item
        }

        # Close dropdown
        $this.HideDropdown()
        $this.Deactivate()

        return $true
    }

    # === Rendering ===

    [string] OnRender() {
        $sb = [System.Text.StringBuilder]::new(1024)

        # Clear previous dropdown area if it exists
        if ($this._prevDropdownHeight -gt 0) {
            $clearOutput = $this._ClearPreviousDropdown()
            $sb.Append($clearOutput)
        }

        # Render menu bar
        $menuBarLine = $this._RenderMenuBar()
        $sb.Append($menuBarLine)

        # Render dropdown if visible
        if ($this.DropdownVisible -and $this.SelectedMenuIndex -ge 0) {
            $dropdown = $this._RenderDropdown()
            $sb.Append($dropdown)
        } else {
            # No dropdown visible - reset tracking
            $this._prevDropdownHeight = 0
        }

        $result = $sb.ToString()

        return $result
    }

    hidden [string] _RenderMenuBar() {
        $sb = [System.Text.StringBuilder]::new(512)

        # Get colors
        $bgColor = $this.GetThemedAnsi('Border', $true)
        $fgColor = $this.GetThemedAnsi('Text', $false)
        $highlightBg = $this.GetThemedAnsi('Primary', $true)
        $highlightFg = $this.GetThemedAnsi('Text', $false)
        $reset = "`e[0m"

        # Position cursor
        $sb.Append($this.BuildMoveTo($this.X, $this.Y))

        # Background for entire bar
        $sb.Append($bgColor)
        $sb.Append($this.GetSpaces($this.Width))
        $sb.Append($reset)

        # Render menus
        $sb.Append($this.BuildMoveTo($this.X, $this.Y))
        $sb.Append($bgColor)

        $this._menuXPositions.Clear()
        $currentX = 1  # Start with 1 space padding

        for ($i = 0; $i -lt $this.Menus.Count; $i++) {
            $menu = $this.Menus[$i]
            $this._menuXPositions.Add($currentX)

            # Highlight if selected
            if ($i -eq $this.SelectedMenuIndex -and $this.IsActive) {
                $sb.Append($highlightBg)
                $sb.Append($highlightFg)
            } else {
                $sb.Append($fgColor)
            }

            # Format: " File(F) "
            $menuText = " $($menu.Title)"
            if ($menu.Hotkey -ne [char]0) {
                $menuText += "($($menu.Hotkey))"
            }
            $menuText += " "

            $sb.Append($menuText)
            $currentX += $menuText.Length

            # Reset to normal bar color
            if ($i -eq $this.SelectedMenuIndex -and $this.IsActive) {
                $sb.Append($bgColor)
            }
        }

        $sb.Append($reset)

        $result = $sb.ToString()
        
        return $result
    }

    hidden [string] _RenderDropdown() {
        if ($this.SelectedMenuIndex -lt 0 -or $this.SelectedMenuIndex -ge $this.Menus.Count) {
            return ""
        }

        $menu = $this.Menus[$this.SelectedMenuIndex]
        if ($menu.Items.Count -eq 0) {
            return ""
        }

        $sb = [System.Text.StringBuilder]::new(1024)

        # Calculate dropdown position (below selected menu)
        $dropdownX = $this.X + $this._menuXPositions[$this.SelectedMenuIndex]
        $dropdownY = $this.Y + 1

        # Calculate dropdown width (longest item + padding)
        $maxWidth = 10
        foreach ($item in $menu.Items) {
            if (-not $item.IsSeparator) {
                $itemWidth = $item.Label.Length + 6  # " Label (H) "
                if ($itemWidth -gt $maxWidth) {
                    $maxWidth = $itemWidth
                }
            }
        }
        $this._dropdownWidth = [Math]::Min($maxWidth, $this.Width - $dropdownX - 2)

        # Colors
        $bgColor = $this.GetThemedAnsi('Border', $true)
        $fgColor = $this.GetThemedAnsi('Text', $false)
        $borderColor = $this.GetThemedAnsi('Border', $false)
        $selectedBg = $this.GetThemedAnsi('Primary', $true)
        $selectedFg = $this.GetThemedAnsi('Text', $false)
        $mutedColor = $this.GetThemedAnsi('Muted', $false)
        $reset = "`e[0m"

        # Top border
        $sb.Append($this.BuildMoveTo($dropdownX, $dropdownY))
        $sb.Append($borderColor)
        $sb.Append($this.BuildBoxBorder($this._dropdownWidth, 'top', 'single'))
        $sb.Append($reset)

        # Items
        $currentY = $dropdownY + 1
        for ($i = 0; $i -lt $menu.Items.Count; $i++) {
            $item = $menu.Items[$i]

            $sb.Append($this.BuildMoveTo($dropdownX, $currentY))

            if ($item.IsSeparator) {
                # Separator line
                $sb.Append($borderColor)
                $vertChar = $this.GetBoxChar('single_vertical')
                $horizChar = $this.GetBoxChar('single_horizontal')
                $sb.Append($vertChar)
                $sb.Append($horizChar * ($this._dropdownWidth - 2))
                $sb.Append($vertChar)
                $sb.Append($reset)
            } else {
                # Regular item
                $isSelected = ($i -eq $this.SelectedItemIndex)

                # Border + background
                $sb.Append($borderColor)
                $sb.Append($this.GetBoxChar('single_vertical'))
                $sb.Append($reset)

                if ($isSelected) {
                    $sb.Append($selectedBg)
                    $sb.Append($selectedFg)
                } else {
                    $sb.Append($bgColor)
                    $sb.Append($fgColor)
                }

                # Item text: " Label (H) "
                $itemText = " $($item.Label)"
                if ($item.Hotkey -ne [char]0) {
                    $itemText += " ($($item.Hotkey))"
                }

                # Pad to dropdown width
                $innerWidth = $this._dropdownWidth - 2
                $itemText = $this.PadText($itemText, $innerWidth, 'left')

                # Gray out if disabled
                if (-not $item.Enabled) {
                    $sb.Append($mutedColor)
                }

                $sb.Append($itemText)
                $sb.Append($reset)

                # Right border
                $sb.Append($borderColor)
                $sb.Append($this.GetBoxChar('single_vertical'))
                $sb.Append($reset)
            }

            $currentY++
        }

        # Bottom border
        $sb.Append($this.BuildMoveTo($dropdownX, $currentY))
        $sb.Append($borderColor)
        $sb.Append($this.BuildBoxBorder($this._dropdownWidth, 'bottom', 'single'))
        $sb.Append($reset)

        # Save current dropdown dimensions for clearing next time
        $this._prevDropdownX = $dropdownX
        $this._prevDropdownY = $dropdownY
        $this._prevDropdownWidth = $this._dropdownWidth
        $this._prevDropdownHeight = $currentY - $dropdownY + 1  # +1 for bottom border

        $result = $sb.ToString()

        return $result
    }

    hidden [string] _ClearPreviousDropdown() {
        if ($this._prevDropdownHeight -le 0) {
            return ""
        }

        $sb = [System.Text.StringBuilder]::new(512)
        $spaces = $this.GetSpaces($this._prevDropdownWidth)

        # Clear each line of the previous dropdown
        for ($i = 0; $i -lt $this._prevDropdownHeight; $i++) {
            $y = $this._prevDropdownY + $i
            $sb.Append($this.BuildMoveTo($this._prevDropdownX, $y))
            $sb.Append($spaces)
        }

        return $sb.ToString()
    }

    # === Input Handling ===

    [bool] HandleKeyPress([System.ConsoleKeyInfo]$keyInfo) {
        $key = $keyInfo.Key
        $char = $keyInfo.KeyChar

        # Handle Alt+hotkey even when not active (to activate menu)
        if ($keyInfo.Modifiers -band [ConsoleModifiers]::Alt) {
            if ($this._HandleMenuHotkey($char)) {
                $this.Activate()  # Ensure menu is active
                return $true
            }
        }

        # Normal menu operations require IsActive
        if (-not $this.IsActive) {
            return $false
        }

        # Dropdown navigation
        if ($this.DropdownVisible) {
            switch ($key) {
                'UpArrow' {
                    $this.SelectPreviousItem()
                    return $true
                }
                'DownArrow' {
                    $this.SelectNextItem()
                    return $true
                }
                'LeftArrow' {
                    $this.HideDropdown()
                    $this.SelectPreviousMenu()
                    $this.ShowDropdown()
                    return $true
                }
                'RightArrow' {
                    $this.HideDropdown()
                    $this.SelectNextMenu()
                    $this.ShowDropdown()
                    return $true
                }
                'Enter' {
                    return $this.ExecuteSelectedItem()
                }
                'Escape' {
                    $this.HideDropdown()
                    return $true
                }
                default {
                    # Check hotkeys
                    if ($this._HandleItemHotkey($char)) {
                        return $true
                    }
                }
            }
        } else {
            # Menu bar navigation
            switch ($key) {
                'LeftArrow' {
                    $this.SelectPreviousMenu()
                    return $true
                }
                'RightArrow' {
                    $this.SelectNextMenu()
                    return $true
                }
                'DownArrow' {
                    $this.ShowDropdown()
                    return $true
                }
                'Enter' {
                    $this.ShowDropdown()
                    return $true
                }
                'Escape' {
                    $this.Deactivate()
                    return $true
                }
                default {
                    # Check menu hotkeys
                    if ($this._HandleMenuHotkey($char)) {
                        return $true
                    }
                }
            }
        }

        return $false
    }

    hidden [bool] _HandleMenuHotkey([char]$char) {
        if ($char -eq [char]0) { return $false }
        $charUpper = [char]::ToUpper($char)

        for ($i = 0; $i -lt $this.Menus.Count; $i++) {
            $menu = $this.Menus[$i]
            if ([char]::ToUpper($menu.Hotkey) -eq $charUpper) {
                $this.SelectedMenuIndex = $i
                $this.ShowDropdown()
                return $true
            }
        }
        return $false
    }

    hidden [bool] _HandleItemHotkey([char]$char) {
        if ($char -eq [char]0 -or $this.SelectedMenuIndex -lt 0) { return $false }
        $charUpper = [char]::ToUpper($char)

        $menu = $this.Menus[$this.SelectedMenuIndex]
        for ($i = 0; $i -lt $menu.Items.Count; $i++) {
            $item = $menu.Items[$i]
            if (-not $item.IsSeparator -and $item.Enabled -and [char]::ToUpper($item.Hotkey) -eq $charUpper) {
                $this.SelectedItemIndex = $i
                return $this.ExecuteSelectedItem()
            }
        }
        return $false
    }
}

# Classes exported automatically in PowerShell 5.1+
