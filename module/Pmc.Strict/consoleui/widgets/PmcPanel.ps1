# PmcPanel - Container widget with border and title
# Provides grouped content areas with visual boundaries

using namespace System.Text
using namespace System.Collections.Generic

Set-StrictMode -Version Latest

<#
.SYNOPSIS
Panel widget - container with border, title, and optional scrolling

.DESCRIPTION
PmcPanel provides:
- Border with customizable style (single, double, heavy, rounded)
- Optional title in border
- Content area with automatic padding
- Optional scroll support
- Child widget container

.EXAMPLE
$panel = [PmcPanel]::new("Settings")
$panel.SetBorderStyle('rounded')
$panel.SetPadding(2)
#>
class PmcPanel : PmcWidget {
    # === Properties ===
    [string]$PanelTitle = ""
    [string]$BorderStyle = 'single'  # 'single', 'double', 'heavy', 'rounded'
    [int]$PaddingLeft = 1
    [int]$PaddingTop = 1
    [int]$PaddingRight = 1
    [int]$PaddingBottom = 1
    [bool]$ShowTitle = $true
    [bool]$ShowBorder = $true

    # Content
    [string]$ContentText = ""        # Simple text content (alternative to children)
    [string]$ContentAlign = 'left'   # 'left', 'center', 'right'

    # === Constructor ===
    PmcPanel() : base("Panel") {
        $this.Width = 40
        $this.Height = 10
    }

    PmcPanel([string]$title) : base("Panel") {
        $this.PanelTitle = $title
        $this.Width = 40
        $this.Height = 10
    }

    PmcPanel([string]$title, [int]$width, [int]$height) : base("Panel") {
        $this.PanelTitle = $title
        $this.Width = $width
        $this.Height = $height
    }

    # === Configuration ===

    <#
    .SYNOPSIS
    Set border style

    .PARAMETER style
    Border style: 'single', 'double', 'heavy', 'rounded'
    #>
    [void] SetBorderStyle([string]$style) {
        $this.BorderStyle = $style
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Set padding (all sides)

    .PARAMETER padding
    Padding in characters
    #>
    [void] SetPadding([int]$padding) {
        $this.PaddingLeft = $padding
        $this.PaddingTop = $padding
        $this.PaddingRight = $padding
        $this.PaddingBottom = $padding
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Set padding (individual sides)
    #>
    [void] SetPadding([int]$left, [int]$top, [int]$right, [int]$bottom) {
        $this.PaddingLeft = $left
        $this.PaddingTop = $top
        $this.PaddingRight = $right
        $this.PaddingBottom = $bottom
        $this.Invalidate()
    }

    <#
    .SYNOPSIS
    Set simple text content

    .PARAMETER text
    Text to display in panel

    .PARAMETER align
    Alignment: 'left', 'center', 'right'
    #>
    [void] SetContent([string]$text, [string]$align = 'left') {
        $this.ContentText = $text
        $this.ContentAlign = $align
        $this.Invalidate()
    }

    # === Rendering ===

    [string] OnRender() {
        $sb = [System.Text.StringBuilder]::new(1024)

        # Colors from new theme system
        $borderColor = $this.GetThemedFg('Border.Widget')
        $titleColor = $this.GetThemedFg('Foreground.Title')
        $textColor = $this.GetThemedFg('Foreground.Row')
        $reset = "`e[0m"

        if ($this.ShowBorder) {
            # Top border with title
            $sb.Append($this._RenderTopBorder($borderColor, $titleColor, $reset))

            # Side borders (if height > 2)
            if ($this.Height -gt 2) {
                for ($row = 1; $row -lt ($this.Height - 1); $row++) {
                    $sb.Append($this._RenderMiddleLine($row, $borderColor, $textColor, $reset))
                }
            }

            # Bottom border
            if ($this.Height -gt 1) {
                $sb.Append($this._RenderBottomBorder($borderColor, $reset))
            }
        } else {
            # No border - just render content
            $sb.Append($this._RenderContentNoBorder($textColor, $reset))
        }

        # Render children (offset by border + padding)
        # Children handled by base Component.Render()

        $result = $sb.ToString()
        
        return $result
    }

    hidden [string] _RenderTopBorder([string]$borderColor, [string]$titleColor, [string]$reset) {
        $sb = [System.Text.StringBuilder]::new(256)

        $sb.Append($this.BuildMoveTo($this.X, $this.Y))
        $sb.Append($borderColor)

        if ($this.ShowTitle -and $this.PanelTitle) {
            # Title in border: ┌─ Title ─────┐
            $leftCorner = $this.GetBoxChar("$($this.BorderStyle)_topleft")
            $rightCorner = $this.GetBoxChar("$($this.BorderStyle)_topright")
            $horizChar = $this.GetBoxChar("$($this.BorderStyle)_horizontal")

            $titleText = " $($this.PanelTitle) "
            $remainingWidth = $this.Width - 2 - $titleText.Length

            if ($remainingWidth -gt 0) {
                $sb.Append($leftCorner)
                $sb.Append($horizChar)
                $sb.Append($titleColor)
                $sb.Append($titleText)
                $sb.Append($borderColor)
                $sb.Append($horizChar * $remainingWidth)
                $sb.Append($rightCorner)
            } else {
                # Title too long, just draw border
                $sb.Append($this.BuildBoxBorder($this.Width, 'top', $this.BorderStyle))
            }
        } else {
            # No title, simple top border
            $sb.Append($this.BuildBoxBorder($this.Width, 'top', $this.BorderStyle))
        }

        $sb.Append($reset)

        $result = $sb.ToString()
        
        return $result
    }

    hidden [string] _RenderMiddleLine([int]$row, [string]$borderColor, [string]$textColor, [string]$reset) {
        $sb = [System.Text.StringBuilder]::new(256)

        $sb.Append($this.BuildMoveTo($this.X, $this.Y + $row))
        $sb.Append($borderColor)

        $vertChar = $this.GetBoxChar("$($this.BorderStyle)_vertical")

        # Left border
        $sb.Append($vertChar)

        # Content area
        $contentWidth = $this.Width - 2  # Minus left and right borders

        # Check if this row should show content
        if ($this.ContentText) {
            $contentRow = $row - $this.PaddingTop
            $lines = $this.ContentText -split "`n"
            if ($contentRow -ge 0 -and $contentRow -lt $lines.Count) {
                $line = $lines[$contentRow]
                $innerWidth = $contentWidth - $this.PaddingLeft - $this.PaddingRight

                $sb.Append($textColor)
                $sb.Append($this.GetSpaces($this.PaddingLeft))
                $sb.Append($this.PadText($line, $innerWidth, $this.ContentAlign))
                $sb.Append($this.GetSpaces($this.PaddingRight))
                $sb.Append($borderColor)
            } else {
                # Empty line
                $sb.Append($this.GetSpaces($contentWidth))
            }
        } else {
            # No content
            $sb.Append($this.GetSpaces($contentWidth))
        }

        # Right border
        $sb.Append($vertChar)
        $sb.Append($reset)

        $result = $sb.ToString()
        
        return $result
    }

    hidden [string] _RenderBottomBorder([string]$borderColor, [string]$reset) {
        $sb = [System.Text.StringBuilder]::new(256)

        $sb.Append($this.BuildMoveTo($this.X, $this.Y + $this.Height - 1))
        $sb.Append($borderColor)
        $sb.Append($this.BuildBoxBorder($this.Width, 'bottom', $this.BorderStyle))
        $sb.Append($reset)

        $result = $sb.ToString()
        
        return $result
    }

    hidden [string] _RenderContentNoBorder([string]$textColor, [string]$reset) {
        if (-not $this.ContentText) { return "" }

        $sb = [System.Text.StringBuilder]::new(512)

        $lines = $this.ContentText -split "`n"
        for ($i = 0; $i -lt [Math]::Min($lines.Count, $this.Height); $i++) {
            $sb.Append($this.BuildMoveTo($this.X, $this.Y + $i))
            $sb.Append($textColor)
            $sb.Append($this.PadText($lines[$i], $this.Width, $this.ContentAlign))
            $sb.Append($reset)
        }

        $result = $sb.ToString()
        
        return $result
    }

    # === Helper Methods ===

    <#
    .SYNOPSIS
    Get content area bounds (excluding border and padding)

    .OUTPUTS
    Hashtable with X, Y, Width, Height of usable content area
    #>
    [hashtable] GetContentBounds() {
        $borderOffset = if ($this.ShowBorder) { 1 } else { 0 }

        return @{
            X = $this.X + $borderOffset + $this.PaddingLeft
            Y = $this.Y + $borderOffset + $this.PaddingTop
            Width = $this.Width - (2 * $borderOffset) - $this.PaddingLeft - $this.PaddingRight
            Height = $this.Height - (2 * $borderOffset) - $this.PaddingTop - $this.PaddingBottom
        }
    }

    <#
    .SYNOPSIS
    Create simple info panel

    .PARAMETER title
    Panel title

    .PARAMETER content
    Panel content text

    .OUTPUTS
    Configured PmcPanel
    #>
    static [PmcPanel] CreateInfoPanel([string]$title, [string]$content) {
        $panel = [PmcPanel]::new($title)
        $panel.SetContent($content, 'left')
        $panel.SetBorderStyle('single')
        return $panel
    }

    <#
    .SYNOPSIS
    Create emphasized panel with double border

    .PARAMETER title
    Panel title

    .OUTPUTS
    Configured PmcPanel
    #>
    static [PmcPanel] CreateEmphasisPanel([string]$title) {
        $panel = [PmcPanel]::new($title)
        $panel.SetBorderStyle('double')
        return $panel
    }
}

# Classes exported automatically in PowerShell 5.1+
# Classes exported automatically in PowerShell 5.1+
