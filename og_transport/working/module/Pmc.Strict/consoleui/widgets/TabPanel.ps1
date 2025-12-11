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

    [void] RenderToEngine([object]$engine) {
        # Use clipping if available
        if ($engine.PSObject.Methods['PushClip']) {
            $engine.PushClip($this.X, $this.Y, $this.Width, $this.Height)
        }

        # Render to string (reusing existing logic for now)
        # TODO: Refactor _RenderTabBar and _RenderContent to write directly to engine for perf
        $ansiOutput = $this.Render()
        
        # Parse and write to engine
        # Reuse logic from PmcScreen or implement simple parser here
        $pattern = "`e\[(\d+);(\d+)H"
        $matches = [regex]::Matches($ansiOutput, $pattern)

        if ($matches.Count -eq 0) {
            if ($ansiOutput) {
                $engine.WriteAt(0, 0, $ansiOutput)
            }
        } else {
            for ($i = 0; $i -lt $matches.Count; $i++) {
                $match = $matches[$i]
                $row = [int]$match.Groups[1].Value
                $col = [int]$match.Groups[2].Value
                # Convert 1-based ANSI to 0-based engine coords
                $x = $col - 1
                $y = $row - 1

                $startIndex = $match.Index + $match.Length
                if ($i + 1 -lt $matches.Count) {
                    $endIndex = $matches[$i + 1].Index
                } else {
                    $endIndex = $ansiOutput.Length
                }

                $content = $ansiOutput.Substring($startIndex, $endIndex - $startIndex)
                if ($content) {
                    $engine.WriteAt($x, $y, $content)
                }
            }
        }

        if ($engine.PSObject.Methods['PopClip']) {
            $engine.PopClip()
        }
    }

    [string] Render() {
        $sb = [StringBuilder]::new(4096)

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ========== TabPanel.Render START =========="
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel: X=$($this.X) Y=$($this.Y) Width=$($this.Width) Height=$($this.Height)"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel: TabBarHeight=$($this.TabBarHeight) ContentPadding=$($this.ContentPadding) LabelWidth=$($this.LabelWidth)"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel: CurrentTabIndex=$($this.CurrentTabIndex) SelectedFieldIndex=$($this.SelectedFieldIndex)"
        }

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
        $tabBarOutput = $this._RenderTabBar($tabActiveBg, $tabActiveText, $tabInactiveBg, $tabInactiveText, $reset)
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel: Tab bar rendered, length=$($tabBarOutput.Length)"
        }
        $sb.Append($tabBarOutput)

        # Render content area
        $contentOutput = $this._RenderContent($borderColor, $labelColor, $valueColor, $selectBg, $selectText, $reset)
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel: Content rendered, length=$($contentOutput.Length)"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ========== TabPanel.Render END (total=$($sb.Length + $contentOutput.Length)) =========="
        }
        $sb.Append($contentOutput)

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
            $label = $(if ($this.ShowTabNumbers) { "[$($i+1)] $($tab.Name)" } else { $tab.Name })
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
        $separatorY = $this.Y + 1
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel._RenderTabBar: Separator at Y=$separatorY X=$($this.X) Width=$($this.Width)"
        }
        $sb.Append($this.BuildMoveTo($this.X, $separatorY))
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
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel._RenderContent: No current tab"
            }
            return $sb.ToString()
        }

        $contentY = $this.Y + $this.TabBarHeight
        $visibleRows = $this.Height - $this.TabBarHeight - 2

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel._RenderContent: Tab='$($tab.Name)' Fields=$($tab.Fields.Count) ScrollOffset=$($tab.ScrollOffset)"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel._RenderContent: contentY=$contentY (Y=$($this.Y) + TabBarHeight=$($this.TabBarHeight))"
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel._RenderContent: visibleRows=$visibleRows (Height=$($this.Height) - TabBarHeight=$($this.TabBarHeight) - 2)"
        }

        # Render fields
        $startIndex = $tab.ScrollOffset
        $endIndex = [Math]::Min($startIndex + $visibleRows, $tab.Fields.Count)

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel._RenderContent: Rendering fields $startIndex to $endIndex"
        }

        $row = 0
        for ($i = $startIndex; $i -lt $endIndex; $i++) {
            $field = $tab.Fields[$i]
            $isSelected = ($i -eq $this.SelectedFieldIndex)

            $y = $contentY + $row + 1
            $x = $this.X + $this.ContentPadding

            if ($global:PmcTuiLogFile) {
                $debugPrefix = $(if ($i -eq 0) { "FIRST" } else { "Field" })
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel._RenderContent: $debugPrefix field[$i] '$($field.Label)' Y=$y X=$x (contentY=$contentY + row=$row + 1) selected=$isSelected"
            }

            # Move to field position (no pre-clear needed - we'll fill the entire row)
            $sb.Append($this.BuildMoveTo($x, $y))

            if ($global:PmcTuiLogFile -and $i -le 2) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel._RenderContent: Rendering at position ($x,$y)"
            }

            # Render label
            $label = $field.Label
            if ($label.Length -gt $this.LabelWidth - 2) {
                $label = $label.Substring(0, $this.LabelWidth - 5) + "..."
            }

            # Calculate widths
            $maxValueWidth = $this.Width - $this.LabelWidth - ($this.ContentPadding * 2)
            $value = $(if ($null -ne $field.Value) { [string]$field.Value } else { "(empty)" })

            # Build the complete row content
            if ($isSelected) {
                # Selected field - highlight entire row from left padding to right edge
                $sb.Append($selectBg)
                $sb.Append($selectText)

                # Label (padded to LabelWidth)
                $sb.Append($label.PadRight($this.LabelWidth))

                # Value (truncate if needed, then pad to fill remaining width)
                if ($value.Length -gt $maxValueWidth) {
                    $value = $value.Substring(0, $maxValueWidth - 3) + "..."
                }
                $sb.Append($value.PadRight($maxValueWidth))

                $sb.Append($reset)
            } else {
                # Normal field - label in muted color, value in field color
                $sb.Append($labelColor)
                $sb.Append($label.PadRight($this.LabelWidth))
                $sb.Append($reset)

                $sb.Append($valueColor)
                if ($value.Length -gt $maxValueWidth) {
                    $value = $value.Substring(0, $maxValueWidth - 3) + "..."
                }
                # Pad value to fill to edge (clears old content from other tabs)
                $sb.Append($value.PadRight($maxValueWidth))
                $sb.Append($reset)
            }

            $row++
        }

        # Clear any remaining rows in content area (fixes artifacts when switching tabs)
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel._RenderContent: Clearing remaining rows from $row to $visibleRows"
        }
        $bgColor = $this.GetThemedBg('Background.Primary', $this.Width, 0)
        for ($i = $row; $i -lt $visibleRows; $i++) {
            $y = $contentY + $i + 1
            $sb.Append($this.BuildMoveTo($this.X, $y))
            $sb.Append($bgColor)
            $sb.Append(' ' * $this.Width)  # Fill with background color
            $sb.Append($reset)
            if ($global:PmcTuiLogFile -and $i -lt ($row + 3)) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] TabPanel._RenderContent: Cleared remaining row at Y=$y with background"
            }
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