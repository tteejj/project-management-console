# TabPanel.ps1 - Tabbed interface widget for organizing fields into logical groups
#
# Usage:
#   $tabPanel = [TabPanel]::new()
#   $tabPanel.AddTab('Identity', @(
#       @{Name='ID1'; Label='ID1'; Value='12345'}
#       @{Name='ID2'; Label='ID2'; Value='ABC-2024'}
#   ))
#   $tabPanel.AddTab('Request', @(...))
#
#   # Navigation
#   $tabPanel.NextTab()       # Tab key
#   $tabPanel.PrevTab()       # Shift+Tab
#   $tabPanel.SelectTab(2)    # Number keys 1-6
#   $tabPanel.NextField()     # Down arrow
#   $tabPanel.PrevField()     # Up arrow
#
#   # Rendering
#   $output = $tabPanel.Render()

using namespace System.Collections.Generic
using namespace System.Text

Set-StrictMode -Version Latest

# Load PmcWidget base class
if (-not ([System.Management.Automation.PSTypeName]'PmcWidget').Type) {
    . "$PSScriptRoot/PmcWidget.ps1"
}

<#
.SYNOPSIS
Tabbed interface widget for organizing many fields into logical groups

.DESCRIPTION
TabPanel provides a tab-based navigation interface for displaying and editing
grouped fields. Perfect for forms with many fields that need organization.

Features:
- Multiple tabs with labels
- Keyboard navigation (Tab/Shift+Tab, arrow keys, number keys)
- Inline field editing
- Theme integration
- Visual tab indicators (active, inactive)
- Field highlighting and selection
- Scrolling within tabs if needed

.EXAMPLE
$tabs = [TabPanel]::new()
$tabs.AddTab('General', @(
    @{Name='name'; Label='Name'; Value='John Doe'}
    @{Name='email'; Label='Email'; Value='john@example.com'}
))
$tabs.AddTab('Details', @(...))
$output = $tabs.Render()
#>
class TabPanel : PmcWidget {
    # === Tab Structure ===
    [List[hashtable]]$Tabs = [List[hashtable]]::new()
    [int]$CurrentTabIndex = 0
    [int]$SelectedFieldIndex = 0  # Field index within current tab

    # === Display Configuration ===
    [int]$TabBarHeight = 2        # Rows for tab bar
    [int]$ContentPadding = 2      # Padding inside content area
    [int]$LabelWidth = 22         # Width for field labels
    [bool]$ShowTabNumbers = $true # Show [1] [2] [3] on tabs

    # === Events ===
    [scriptblock]$OnTabChanged = {}      # Called when tab changes: param($tabIndex)
    [scriptblock]$OnFieldSelected = {}   # Called when field selected: param($field)
    [scriptblock]$OnFieldEdit = {}       # Called when field edited: param($field, $newValue)

    # === Constructor ===
    TabPanel() : base("TabPanel") {
        $this.Width = 80
        $this.Height = 25
        $this.CanFocus = $true
    }

    # === Tab Management ===

    <#
    .SYNOPSIS
    Add a new tab with fields

    .PARAMETER name
    Tab name/label

    .PARAMETER fields
    Array of field hashtables: @{Name=''; Label=''; Value=''; Type='text'}
    #>
    [void] AddTab([string]$name, [array]$fields) {
        $tab = @{
            Name = $name
            Fields = $fields
            ScrollOffset = 0
        }
        $this.Tabs.Add($tab)
    }

    <#
    .SYNOPSIS
    Get current tab
    #>
    [hashtable] GetCurrentTab() {
        if ($this.Tabs.Count -eq 0) {
            return $null
        }
        return $this.Tabs[$this.CurrentTabIndex]
    }

    <#
    .SYNOPSIS
    Get currently selected field
    #>
    [hashtable] GetCurrentField() {
        $tab = $this.GetCurrentTab()
        if ($null -eq $tab -or $tab.Fields.Count -eq 0) {
            return $null
        }

        if ($this.SelectedFieldIndex -ge 0 -and $this.SelectedFieldIndex -lt $tab.Fields.Count) {
            return $tab.Fields[$this.SelectedFieldIndex]
        }

        return $null
    }

    # === Navigation ===

    [void] NextTab() {
        if ($this.Tabs.Count -eq 0) { return }

        $oldIndex = $this.CurrentTabIndex
        $this.CurrentTabIndex = ($this.CurrentTabIndex + 1) % $this.Tabs.Count
        $this.SelectedFieldIndex = 0  # Reset to first field in new tab

        if ($oldIndex -ne $this.CurrentTabIndex) {
            $this._InvokeCallback($this.OnTabChanged, $this.CurrentTabIndex)
        }
    }

    [void] PrevTab() {
        if ($this.Tabs.Count -eq 0) { return }

        $oldIndex = $this.CurrentTabIndex
        $this.CurrentTabIndex--
        if ($this.CurrentTabIndex -lt 0) {
            $this.CurrentTabIndex = $this.Tabs.Count - 1
        }
        $this.SelectedFieldIndex = 0

        if ($oldIndex -ne $this.CurrentTabIndex) {
            $this._InvokeCallback($this.OnTabChanged, $this.CurrentTabIndex)
        }
    }

    [void] SelectTab([int]$index) {
        if ($index -ge 0 -and $index -lt $this.Tabs.Count) {
            $oldIndex = $this.CurrentTabIndex
            $this.CurrentTabIndex = $index
            $this.SelectedFieldIndex = 0

            if ($oldIndex -ne $this.CurrentTabIndex) {
                $this._InvokeCallback($this.OnTabChanged, $this.CurrentTabIndex)
            }
        }
    }

    [void] NextField() {
        $tab = $this.GetCurrentTab()
        if ($null -eq $tab -or $tab.Fields.Count -eq 0) { return }

        $this.SelectedFieldIndex++
        if ($this.SelectedFieldIndex -ge $tab.Fields.Count) {
            $this.SelectedFieldIndex = $tab.Fields.Count - 1
        }

        # Auto-scroll if needed
        $this._EnsureFieldVisible()

        $field = $this.GetCurrentField()
        if ($field) {
            $this._InvokeCallback($this.OnFieldSelected, $field)
        }
    }

    [void] PrevField() {
        $tab = $this.GetCurrentTab()
        if ($null -eq $tab -or $tab.Fields.Count -eq 0) { return }

        $this.SelectedFieldIndex--
        if ($this.SelectedFieldIndex -lt 0) {
            $this.SelectedFieldIndex = 0
        }

        # Auto-scroll if needed
        $this._EnsureFieldVisible()

        $field = $this.GetCurrentField()
        if ($field) {
            $this._InvokeCallback($this.OnFieldSelected, $field)
        }
    }

    hidden [void] _EnsureFieldVisible() {
        $tab = $this.GetCurrentTab()
        if ($null -eq $tab) { return }

        $visibleRows = $this.Height - $this.TabBarHeight - 4  # Tab bar + padding

        # If selected field is above visible area
        if ($this.SelectedFieldIndex -lt $tab.ScrollOffset) {
            $tab.ScrollOffset = $this.SelectedFieldIndex
        }

        # If selected field is below visible area
        if ($this.SelectedFieldIndex -ge ($tab.ScrollOffset + $visibleRows)) {
            $tab.ScrollOffset = $this.SelectedFieldIndex - $visibleRows + 1
        }
    }

    # === Input Handling ===

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        if ($keyInfo.Key -eq 'Tab') {
            if ($keyInfo.Modifiers -band [ConsoleModifiers]::Shift) {
                $this.PrevTab()
            } else {
                $this.NextTab()
            }
            return $true
        }

        if ($keyInfo.Key -eq 'UpArrow') {
            $this.PrevField()
            return $true
        }

        if ($keyInfo.Key -eq 'DownArrow') {
            $this.NextField()
            return $true
        }

        if ($keyInfo.Key -eq 'PageDown') {
            # Jump 10 fields down
            for ($i = 0; $i -lt 10; $i++) {
                $this.NextField()
            }
            return $true
        }

        if ($keyInfo.Key -eq 'PageUp') {
            # Jump 10 fields up
            for ($i = 0; $i -lt 10; $i++) {
                $this.PrevField()
            }
            return $true
        }

        if ($keyInfo.Key -eq 'Home') {
            $this.SelectedFieldIndex = 0
            $tab = $this.GetCurrentTab()
            if ($tab) {
                $tab.ScrollOffset = 0
            }
            return $true
        }

        if ($keyInfo.Key -eq 'End') {
            $tab = $this.GetCurrentTab()
            if ($tab -and $tab.Fields.Count -gt 0) {
                $this.SelectedFieldIndex = $tab.Fields.Count - 1
                $this._EnsureFieldVisible()
            }
            return $true
        }

        # Number keys 1-9 to jump to tabs
        if ($this.ShowTabNumbers -and $keyInfo.KeyChar -match '[1-9]') {
            $tabNum = [int]$keyInfo.KeyChar - [int][char]'1'  # 0-based index
            $this.SelectTab($tabNum)
            return $true
        }

        return $false
    }

    # === Rendering ===

    [string] Render() {
        $sb = [StringBuilder]::new(4096)

        if ($this.Tabs.Count -eq 0) {
            return $this._RenderEmpty()
        }

        # Colors from theme
        $tabActiveBg = $this.GetThemedBg('Background.TabActive', $this.Width, 0)
        $tabActiveText = $this.GetThemedFg('Foreground.TabActive')
        $tabInactiveBg = $this.GetThemedBg('Background.TabInactive', $this.Width, 0)
        $tabInactiveText = $this.GetThemedFg('Foreground.TabInactive')
        $borderColor = $this.GetThemedFg('Border.Widget')
        $labelColor = $this.GetThemedFg('Foreground.Muted')
        $valueColor = $this.GetThemedFg('Foreground.Field')
        $selectBg = $this.GetThemedBg('Background.RowSelected', $this.Width, 0)
        $selectText = $this.GetThemedFg('Foreground.RowSelected')
        $reset = "`e[0m"

        # Render tab bar
        $sb.Append($this._RenderTabBar($tabActiveBg, $tabActiveText, $tabInactiveBg, $tabInactiveText, $reset))

        # Render content area
        $sb.Append($this._RenderContent($borderColor, $labelColor, $valueColor, $selectBg, $selectText, $reset))

        return $sb.ToString()
    }

    hidden [string] _RenderTabBar($activeBg, $activeText, $inactiveBg, $inactiveText, $reset) {
        $sb = [StringBuilder]::new(512)

        # Top line of tab bar
        $sb.Append($this.BuildMoveTo($this.X, $this.Y))

        $currentX = $this.X
        for ($i = 0; $i -lt $this.Tabs.Count; $i++) {
            $tab = $this.Tabs[$i]
            $isActive = ($i -eq $this.CurrentTabIndex)

            # Tab label with optional number
            $label = if ($this.ShowTabNumbers) { "[$($i+1)] $($tab.Name)" } else { $tab.Name }
            $tabWidth = $label.Length + 4  # Padding

            # Position cursor
            $sb.Append($this.BuildMoveTo($currentX, $this.Y))

            # Render tab
            if ($isActive) {
                $sb.Append($activeBg)
                $sb.Append($activeText)
                $sb.Append(" $label ")
                $sb.Append($reset)
            } else {
                $sb.Append($inactiveBg)
                $sb.Append($inactiveText)
                $sb.Append(" $label ")
                $sb.Append($reset)
            }

            $currentX += $tabWidth
        }

        # Fill rest of line
        $remaining = $this.Width - ($currentX - $this.X)
        if ($remaining -gt 0) {
            $sb.Append($inactiveBg)
            $sb.Append(' ' * $remaining)
            $sb.Append($reset)
        }

        # Separator line
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + 1))
        $borderColor = $this.GetThemedFg('Border.Widget')
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_horizontal') * $this.Width)
        $sb.Append($reset)

        return $sb.ToString()
    }

    hidden [string] _RenderContent($borderColor, $labelColor, $valueColor, $selectBg, $selectText, $reset) {
        $sb = [StringBuilder]::new(4096)

        $tab = $this.GetCurrentTab()
        if ($null -eq $tab) {
            return $sb.ToString()
        }

        $contentY = $this.Y + $this.TabBarHeight
        $visibleRows = $this.Height - $this.TabBarHeight - 2

        # Render fields
        $startIndex = $tab.ScrollOffset
        $endIndex = [Math]::Min($startIndex + $visibleRows, $tab.Fields.Count)

        $row = 0
        for ($i = $startIndex; $i -lt $endIndex; $i++) {
            $field = $tab.Fields[$i]
            $isSelected = ($i -eq $this.SelectedFieldIndex)

            $y = $contentY + $row + 1
            $x = $this.X + $this.ContentPadding

            # Move to position
            $sb.Append($this.BuildMoveTo($x, $y))

            # Render label
            $label = $field.Label
            if ($label.Length -gt $this.LabelWidth - 2) {
                $label = $label.Substring(0, $this.LabelWidth - 5) + "..."
            }

            if ($isSelected) {
                # Selected field - highlight entire row
                $sb.Append($selectBg)
                $sb.Append($selectText)
                $sb.Append($label.PadRight($this.LabelWidth))
            } else {
                # Normal field
                $sb.Append($labelColor)
                $sb.Append($label.PadRight($this.LabelWidth))
                $sb.Append($reset)
            }

            # Render value
            $value = if ($null -ne $field.Value) { [string]$field.Value } else { "(empty)" }
            $maxValueWidth = $this.Width - $this.LabelWidth - ($this.ContentPadding * 2) - 2
            if ($value.Length -gt $maxValueWidth) {
                $value = $value.Substring(0, $maxValueWidth - 3) + "..."
            }

            if ($isSelected) {
                $sb.Append($value.PadRight($maxValueWidth))
                $sb.Append($reset)
            } else {
                $sb.Append($valueColor)
                $sb.Append($value)
                $sb.Append($reset)
            }

            $row++
        }

        # Show scroll indicators if needed
        if ($tab.ScrollOffset -gt 0) {
            # Up arrow
            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 3, $contentY + 1))
            $sb.Append($borderColor)
            $sb.Append("↑")
            $sb.Append($reset)
        }

        if ($endIndex -lt $tab.Fields.Count) {
            # Down arrow
            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 3, $this.Y + $this.Height - 2))
            $sb.Append($borderColor)
            $sb.Append("↓")
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    hidden [string] _RenderEmpty() {
        $sb = [StringBuilder]::new(256)

        $msg = "No tabs configured"
        $x = $this.X + [Math]::Floor(($this.Width - $msg.Length) / 2)
        $y = $this.Y + [Math]::Floor($this.Height / 2)

        $sb.Append($this.BuildMoveTo($x, $y))
        $mutedColor = $this.GetThemedFg('Foreground.Muted')
        $reset = "`e[0m"
        $sb.Append($mutedColor)
        $sb.Append($msg)
        $sb.Append($reset)

        return $sb.ToString()
    }

    # === Helper Methods ===

    hidden [void] _InvokeCallback([scriptblock]$callback, $arg) {
        if ($null -ne $callback -and $callback -ne {}) {
            try {
                if ($null -ne $arg) {
                    & $callback $arg
                } else {
                    & $callback
                }
            } catch {
                # Silently ignore callback errors
            }
        }
    }

    <#
    .SYNOPSIS
    Update a field value
    #>
    [void] UpdateFieldValue([string]$fieldName, $newValue) {
        $tab = $this.GetCurrentTab()
        if ($null -eq $tab) { return }

        foreach ($field in $tab.Fields) {
            if ($field.Name -eq $fieldName) {
                $oldValue = $field.Value
                $field.Value = $newValue
                $this._InvokeCallback($this.OnFieldEdit, @($field, $newValue))
                break
            }
        }
    }

    <#
    .SYNOPSIS
    Get all field values from all tabs as hashtable
    #>
    [hashtable] GetAllValues() {
        $values = @{}

        foreach ($tab in $this.Tabs) {
            foreach ($field in $tab.Fields) {
                $values[$field.Name] = $field.Value
            }
        }

        return $values
    }
}

# Export
Export-ModuleMember -Variable @()
