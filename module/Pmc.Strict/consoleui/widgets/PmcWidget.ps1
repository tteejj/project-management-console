# PmcWidget - Base class for all PMC widgets
# Extends SpeedTUI Component with PMC-specific theme and layout integration

using namespace System.Collections.Generic
using namespace System.Text

Set-StrictMode -Version Latest

# SpeedTUI framework must be loaded before this file
# (loaded by PmcApplication.ps1 or Start-PmcTUI.ps1)
# This check ensures Component class is available
if (-not ([System.Management.Automation.PSTypeName]'Component').Type) {
    throw "SpeedTUI Component class not found. Ensure SpeedTUILoader.ps1 is loaded before PmcWidget.ps1"
}

<#
.SYNOPSIS
Base class for all PMC widgets extending SpeedTUI Component

.DESCRIPTION
PmcWidget provides the foundation for all PMC UI components:
- Integration with PMC's theme system (single hex → full palette derivation)
- Layout constraint support (named regions, percentage-based positioning)
- Box drawing with full Unicode character set
- Performance optimizations (string caching, pre-computation)
- Unified event handling
- State management hooks

.EXAMPLE
# Example: Custom widget implementation
# class MyCustomWidget : PmcWidget {
#     [string] OnRender() {
#         $sb = Get-PooledStringBuilder
#         $color = $this.GetThemedColor('Primary')
#         # ... build your output
#         return $sb.ToString()
#     }
# }
#>
class PmcWidget : Component {
    # === PMC-Specific Properties ===
    [string]$Name = ""                    # Widget name for debugging
    [hashtable]$LayoutConstraints = @{}   # Named region constraints

    # === Theme Integration ===
    hidden [hashtable]$_pmcTheme = $null        # Cached PMC theme
    hidden [hashtable]$_pmcStyleTokens = $null  # Cached style tokens
    hidden [bool]$_themeInitialized = $false

    # === Box Drawing Characters ===
    hidden [hashtable]$_boxChars = @{
        # Single line
        'single_horizontal' = '─'
        'single_vertical' = '│'
        'single_topleft' = '┌'
        'single_topright' = '┐'
        'single_bottomleft' = '└'
        'single_bottomright' = '┘'
        'single_cross' = '┼'
        'single_t_down' = '┬'
        'single_t_up' = '┴'
        'single_t_right' = '├'
        'single_t_left' = '┤'

        # Double line
        'double_horizontal' = '═'
        'double_vertical' = '║'
        'double_topleft' = '╔'
        'double_topright' = '╗'
        'double_bottomleft' = '╚'
        'double_bottomright' = '╝'
        'double_cross' = '╬'
        'double_t_down' = '╦'
        'double_t_up' = '╩'
        'double_t_right' = '╠'
        'double_t_left' = '╣'

        # Heavy line
        'heavy_horizontal' = '━'
        'heavy_vertical' = '┃'
        'heavy_topleft' = '┏'
        'heavy_topright' = '┓'
        'heavy_bottomleft' = '┗'
        'heavy_bottomright' = '┛'

        # Rounded
        'rounded_topleft' = '╭'
        'rounded_topright' = '╮'
        'rounded_bottomleft' = '╰'
        'rounded_bottomright' = '╯'
    }

    # === Constructor ===
    PmcWidget() : base() {
        $this.Name = $this.GetType().Name
        $this._EnsureThemeInitialized()
    }

    PmcWidget([string]$name) : base() {
        $this.Name = $name
        $this._EnsureThemeInitialized()
    }

    # === Theme System Methods ===

    <#
    .SYNOPSIS
    Ensure PMC theme system is loaded
    #>
    hidden [void] _EnsureThemeInitialized() {
        if ($this._themeInitialized) { return }

        try {
            # Get PMC theme state
            $displayState = Get-PmcState -Section 'Display'
            if ($displayState) {
                $this._pmcTheme = $displayState.Theme
                $this._pmcStyleTokens = $displayState.Styles
            }

            # Fallback to defaults if state not available
            if (-not $this._pmcTheme) {
                $this._pmcTheme = @{
                    PaletteName = 'default'
                    Hex = '#33aaff'
                    TrueColor = $true
                }
            }

            if (-not $this._pmcStyleTokens) {
                $this._pmcStyleTokens = @{
                    Title = @{ Fg = '#33aaff' }
                    Body = @{ Fg = '#CCCCCC' }
                    Border = @{ Fg = '#666666' }
                }
            }

            $this._themeInitialized = $true
        } catch {
            # Fallback - widget still functional with defaults
            if (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue) {
                Write-PmcTuiLog "Theme initialization failed: $($_.Exception.Message)" "ERROR"
                Write-PmcTuiLog "Stack: $($_.ScriptStackTrace)" "DEBUG"
            }
            $this._themeInitialized = $true
        }
    }

    <#
    .SYNOPSIS
    Get color for a specific role from PMC theme system

    .PARAMETER role
    Color role: Primary, Border, Text, Muted, Error, Warning, Success, Bright, Header, etc.

    .OUTPUTS
    Hex color string (e.g., "#33aaff") or empty string if not found

    .EXAMPLE
    $color = $this.GetThemedColor('Primary')  # Returns "#33aaff" (or current theme color)
    #>
    [string] GetThemedColor([string]$role) {
        $this._EnsureThemeInitialized()
        if ($this._pmcStyleTokens -and $this._pmcStyleTokens.ContainsKey($role)) {
            $style = $this._pmcStyleTokens[$role]
            if ($style.Fg) { return $style.Fg }
        }
        try {
            $palette = Get-PmcColorPalette
            if ($palette.ContainsKey($role)) {
                $rgb = $palette[$role]
                if ($rgb.R -ne $null) {
                    return ("#{0:X2}{1:X2}{2:X2}" -f $rgb.R, $rgb.G, $rgb.B)
                }
            }
        } catch {
            if (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue) {
                Write-PmcTuiLog "GetThemedColor palette lookup failed for role '$role': $($_.Exception.Message)" "DEBUG"
            }
        }
        $result = switch ($role) {
            'Primary' { if ($this._pmcTheme.Hex) { $this._pmcTheme.Hex } else { '#33aaff' } }
            'Border' { '#666666' }
            'Text' { '#CCCCCC' }
            'Muted' { '#888888' }
            'Error' { '#FF4444' }
            'Warning' { '#FFAA00' }
            'Success' { '#44FF44' }
            default { '#CCCCCC' }
        }
        return $result
    }

    <#
    .SYNOPSIS
    Get ANSI color sequence for a specific role

    .PARAMETER role
    Color role (Primary, Border, Text, etc.)

    .PARAMETER background
    If true, returns background color sequence instead of foreground

    .OUTPUTS
    ANSI escape sequence string (e.g., "`e[38;2;51;170;255m")

    .EXAMPLE
    $sb.Append($this.GetThemedAnsi('Primary'))
    $sb.Append("Important Text")
    $sb.Append("`e[0m")
    #>
    [string] GetThemedAnsi([string]$role, [bool]$background = $false) {
        $hex = $this.GetThemedColor($role)
        if ([string]::IsNullOrEmpty($hex)) { return '' }

        # Parse hex to RGB
        $hex = $hex.TrimStart('#')
        if ($hex.Length -ne 6) { return '' }

        try {
            $r = [Convert]::ToInt32($hex.Substring(0, 2), 16)
            $g = [Convert]::ToInt32($hex.Substring(2, 2), 16)
            $b = [Convert]::ToInt32($hex.Substring(4, 2), 16)

            if ($background) {
                return "`e[48;2;${r};${g};${b}m"
            } else {
                return "`e[38;2;${r};${g};${b}m"
            }
        } catch {
            return ''
        }
    }

    # === Box Drawing Methods ===

    <#
    .SYNOPSIS
    Get box-drawing character by name

    .PARAMETER charName
    Character name (e.g., 'single_horizontal', 'double_topleft', 'rounded_topleft')

    .OUTPUTS
    Unicode box-drawing character
    #>
    [string] GetBoxChar([string]$charName) {
        if ($this._boxChars.ContainsKey($charName)) {
            return $this._boxChars[$charName]
        }
        return ''
    }

    <#
    .SYNOPSIS
    Build a horizontal line with specified style

    .PARAMETER width
    Width in characters

    .PARAMETER style
    Line style: 'single' (default), 'double', 'heavy'

    .OUTPUTS
    String containing repeated horizontal line character
    #>
    [string] BuildHorizontalLine([int]$width, [string]$style = 'single') {
        $char = $this.GetBoxChar("${style}_horizontal")
        if ([string]::IsNullOrEmpty($char)) {
            $char = '─'
        }
        return $char * $width
    }

    <#
    .SYNOPSIS
    Build a box border string (top, middle, or bottom line)

    .PARAMETER width
    Width in characters (total, including corners)

    .PARAMETER position
    'top', 'middle', 'bottom'

    .PARAMETER style
    Border style: 'single', 'double', 'heavy', 'rounded'

    .OUTPUTS
    String containing full border line with corners

    .EXAMPLE
    $topLine = $this.BuildBoxBorder(40, 'top', 'single')      # "┌──────────────────────────────────────┐"
    $bottomLine = $this.BuildBoxBorder(40, 'bottom', 'rounded')  # "╰──────────────────────────────────────╯"
    #>
    [string] BuildBoxBorder([int]$width, [string]$position, [string]$style = 'single') {
        if ($width -lt 2) { return '' }

        $leftChar = ''
        $rightChar = ''
        $horizChar = $this.GetBoxChar("${style}_horizontal")

        # Handle rounded style (special case - uses single for horizontal)
        if ($style -eq 'rounded') {
            $horizChar = $this.GetBoxChar('single_horizontal')
            switch ($position) {
                'top' {
                    $leftChar = $this.GetBoxChar('rounded_topleft')
                    $rightChar = $this.GetBoxChar('rounded_topright')
                }
                'bottom' {
                    $leftChar = $this.GetBoxChar('rounded_bottomleft')
                    $rightChar = $this.GetBoxChar('rounded_bottomright')
                }
                default {
                    $leftChar = $this.GetBoxChar('single_vertical')
                    $rightChar = $this.GetBoxChar('single_vertical')
                }
            }
        } else {
            switch ($position) {
                'top' {
                    $leftChar = $this.GetBoxChar("${style}_topleft")
                    $rightChar = $this.GetBoxChar("${style}_topright")
                }
                'bottom' {
                    $leftChar = $this.GetBoxChar("${style}_bottomleft")
                    $rightChar = $this.GetBoxChar("${style}_bottomright")
                }
                default {
                    $leftChar = $this.GetBoxChar("${style}_vertical")
                    $rightChar = $this.GetBoxChar("${style}_vertical")
                }
            }
        }

        $innerWidth = $width - 2
        return $leftChar + ($horizChar * $innerWidth) + $rightChar
    }

    # === Layout Constraint Methods ===

    <#
    .SYNOPSIS
    Apply layout constraints to calculate actual position and size

    .PARAMETER termWidth
    Terminal width in characters

    .PARAMETER termHeight
    Terminal height in characters

    .DESCRIPTION
    Supports percentage-based positioning and sizing:
    - X/Y: Can be integers or strings like "10%" or "CENTER"
    - Width/Height: Can be integers or strings like "50%" or "FILL"
    #>
    [void] ApplyLayoutConstraints([int]$termWidth, [int]$termHeight) {
        if (-not $this.LayoutConstraints -or $this.LayoutConstraints.Count -eq 0) {
            return
        }

        $newX = $this.X
        $newY = $this.Y
        $newWidth = $this.Width
        $newHeight = $this.Height

        # Process X constraint
        if ($this.LayoutConstraints.ContainsKey('X')) {
            $xConstraint = $this.LayoutConstraints['X']
            if ($xConstraint -is [string]) {
                if ($xConstraint -match '^(\d+)%$') {
                    $pct = [int]$Matches[1]
                    $newX = [Math]::Floor($termWidth * $pct / 100.0)
                } elseif ($xConstraint -eq 'CENTER') {
                    $newX = [Math]::Floor(($termWidth - $newWidth) / 2.0)
                }
            } else {
                $newX = [int]$xConstraint
            }
        }

        # Process Y constraint
        if ($this.LayoutConstraints.ContainsKey('Y')) {
            $yConstraint = $this.LayoutConstraints['Y']
            if ($yConstraint -is [string]) {
                if ($yConstraint -match '^(\d+)%$') {
                    $pct = [int]$Matches[1]
                    $newY = [Math]::Floor($termHeight * $pct / 100.0)
                } elseif ($yConstraint -match '^BOTTOM-(\d+)$') {
                    $offset = [int]$Matches[1]
                    $newY = $termHeight - $offset
                } elseif ($yConstraint -eq 'BOTTOM') {
                    $newY = $termHeight - 1
                }
            } else {
                $newY = [int]$yConstraint
            }
        }

        # Process Width constraint
        if ($this.LayoutConstraints.ContainsKey('Width')) {
            $widthConstraint = $this.LayoutConstraints['Width']
            if ($widthConstraint -is [string]) {
                if ($widthConstraint -match '^(\d+)%$') {
                    $pct = [int]$Matches[1]
                    $newWidth = [Math]::Floor($termWidth * $pct / 100.0)
                } elseif ($widthConstraint -eq 'FILL') {
                    $newWidth = $termWidth - $newX
                }
            } else {
                $newWidth = [int]$widthConstraint
            }
        }

        # Process Height constraint
        if ($this.LayoutConstraints.ContainsKey('Height')) {
            $heightConstraint = $this.LayoutConstraints['Height']
            if ($heightConstraint -is [string]) {
                if ($heightConstraint -match '^(\d+)%$') {
                    $pct = [int]$Matches[1]
                    $newHeight = [Math]::Floor($termHeight * $pct / 100.0)
                } elseif ($heightConstraint -eq 'FILL') {
                    $newHeight = $termHeight - $newY
                }
            } else {
                $newHeight = [int]$heightConstraint
            }
        }

        # Apply calculated bounds (uses SpeedTUI's methods)
        $this.SetPosition($newX, $newY)
        $this.SetSize($newWidth, $newHeight)
    }

    # === Terminal Resize Handling ===

    <#
    .SYNOPSIS
    Handle terminal resize events

    .DESCRIPTION
    Override from Component to add layout constraint recalculation
    #>
    [void] OnTerminalResize([int]$newWidth, [int]$newHeight) {
        # Recalculate constraints
        $this.ApplyLayoutConstraints($newWidth, $newHeight)

        # Call base implementation (handles children, invalidation)
        ([Component]$this).OnTerminalResize($newWidth, $newHeight)
    }

    # === Utility Methods ===

    <#
    .SYNOPSIS
    Build a VT100 cursor position sequence

    .PARAMETER x
    X coordinate (column, 0-based)

    .PARAMETER y
    Y coordinate (row, 0-based)

    .OUTPUTS
    ANSI escape sequence to move cursor
    #>
    [string] BuildMoveTo([int]$x, [int]$y) {
        # VT100 uses 1-based coordinates
        $col = $x + 1
        $row = $y + 1
        return "`e[${row};${col}H"
    }

    <#
    .SYNOPSIS
    Get cached spaces string (performance optimization)

    .PARAMETER count
    Number of spaces

    .OUTPUTS
    String of spaces
    #>
    [string] GetSpaces([int]$count) {
        if ($count -le 0) { return '' }
        return (" " * $count)
    }

    <#
    .SYNOPSIS
    Truncate text to fit width with ellipsis

    .PARAMETER text
    Text to truncate

    .PARAMETER maxWidth
    Maximum width

    .OUTPUTS
    Truncated text with ellipsis if needed
    #>
    [string] TruncateText([string]$text, [int]$maxWidth) {
        if ([string]::IsNullOrEmpty($text)) { return '' }
        if ($text.Length -le $maxWidth) { return $text }
        if ($maxWidth -le 1) { return '…' }
        return $text.Substring(0, $maxWidth - 1) + '…'
    }

    <#
    .SYNOPSIS
    Pad text to specified width

    .PARAMETER text
    Text to pad

    .PARAMETER width
    Target width

    .PARAMETER align
    Alignment: 'left' (default), 'center', 'right'

    .OUTPUTS
    Padded text
    #>
    [string] PadText([string]$text, [int]$width, [string]$align = 'left') {
        if ([string]::IsNullOrEmpty($text)) { return (" " * $width) }
        if ($text.Length -ge $width) { return $text.Substring(0, $width) }
        $padding = $width - $text.Length
        $result = switch ($align) {
            'center' {
                $leftPad = [Math]::Floor($padding / 2.0)
                $rightPad = $padding - $leftPad
                (" " * $leftPad) + $text + (" " * $rightPad)
            }
            'right' { (" " * $padding) + $text }
            default { $text + (" " * $padding) }
        }
        return $result
    }

    <#
    .SYNOPSIS
    L-POL-1: Truncate help text to fit narrow terminals

    .PARAMETER text
    Help text to truncate

    .PARAMETER maxWidth
    Maximum width (defaults to terminal width - 10)

    .OUTPUTS
    Truncated string with ellipsis if needed
    #>
    [string] TruncateHelpText([string]$text, [int]$maxWidth = -1) {
        if ($maxWidth -lt 0) {
            # L-POL-1: Detect terminal width and reserve space for borders
            $termWidth = if ([Console]::WindowWidth -gt 0) {
                [Console]::WindowWidth
            } else {
                80  # Fallback to standard width
            }
            $maxWidth = $termWidth - 10
        }

        if ($text.Length -le $maxWidth) {
            return $text
        }

        # Truncate with ellipsis
        return $text.Substring(0, $maxWidth - 3) + "..."
    }
}

# Classes and functions are exported automatically in PowerShell 5.1+

