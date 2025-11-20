# ThemedCellRenderer.ps1
# Theme-aware cell rendering for EditableGrid

class ThemedCellRenderer {
    [PmcThemeManager]$ThemeManager
    [hashtable]$RenderOptions = @{}

    # Constructor
    ThemedCellRenderer([PmcThemeManager]$themeManager) {
        if ($null -eq $themeManager) {
            throw "ThemeManager cannot be null"
        }
        $this.ThemeManager = $themeManager
    }

    # Render a cell with theme styling
    [string] RenderCell([GridCell]$cell, [int]$width, [bool]$isSelected, [bool]$isEditing) {
        if ($null -eq $cell) {
            return $this._PadOrTruncate("", $width)
        }

        # Get cell content
        $content = if ($isEditing) {
            $cell.GetEditValue()
        } else {
            $cell.GetDisplayValue()
        }

        # Get theme colors based on cell state
        $colors = $this._GetCellColors($cell, $isSelected, $isEditing)

        # Apply validation styling if cell has error
        if ($cell.ValidationError) {
            $colors = $this._GetErrorColors()
        }

        # Apply dirty indicator if cell is modified
        $dirtyIndicator = if ($cell.IsDirty) { "*" } else { "" }

        # Format content with padding
        $paddedContent = $this._PadOrTruncate($content, $width - $dirtyIndicator.Length)

        # Build output with ANSI codes
        $output = ""
        $output += $colors.Bg        # Background color
        $output += $colors.Fg        # Foreground color
        $output += $paddedContent
        $output += $dirtyIndicator
        $output += [PraxisVT]::Reset()

        return $output
    }

    # Render cell with cursor for editing
    [string] RenderCellWithCursor([GridCell]$cell, [int]$width, [bool]$isSelected) {
        if ($null -eq $cell -or -not $cell.IsEditing) {
            return $this.RenderCell($cell, $width, $isSelected, $false)
        }

        # Get edit content
        $content = $cell.GetEditValue()
        $cursorPos = $cell.CursorPos

        # Get theme colors
        $colors = $this._GetCellColors($cell, $isSelected, $true)

        # Split content at cursor position
        $before = if ($cursorPos -gt 0) {
            $content.Substring(0, [Math]::Min($cursorPos, $content.Length))
        } else {
            ""
        }

        $cursorChar = if ($cursorPos -lt $content.Length) {
            $content[$cursorPos]
        } else {
            " "  # Cursor at end shows space
        }

        $after = if ($cursorPos + 1 -lt $content.Length) {
            $content.Substring($cursorPos + 1)
        } else {
            ""
        }

        # Pad or truncate to fit width
        $totalContent = $before + $cursorChar + $after
        $dirtyIndicator = if ($cell.IsDirty) { "*" } else { "" }
        $availableWidth = $width - $dirtyIndicator.Length

        if ($totalContent.Length -gt $availableWidth) {
            # Truncate - keep cursor visible
            $halfWidth = [int]($availableWidth / 2)
            $start = [Math]::Max(0, $cursorPos - $halfWidth)
            $end = [Math]::Min($content.Length, $start + $availableWidth)
            $before = $content.Substring($start, $cursorPos - $start)
            $cursorChar = if ($cursorPos -lt $content.Length) { $content[$cursorPos] } else { " " }
            $after = if ($cursorPos + 1 -lt $end) { $content.Substring($cursorPos + 1, $end - $cursorPos - 1) } else { "" }
        }

        # Pad if needed
        $remainingSpace = $availableWidth - ($before.Length + 1 + $after.Length)
        if ($remainingSpace -gt 0) {
            $after += " " * $remainingSpace
        }

        # Build output with cursor highlighting
        $output = ""
        $output += $colors.Bg + $colors.Fg
        $output += $before
        $output += $this._GetCursorHighlight()  # Reverse video for cursor
        $output += $cursorChar
        $output += $colors.Bg + $colors.Fg  # Restore colors
        $output += $after
        $output += $dirtyIndicator
        $output += [PraxisVT]::Reset()

        return $output
    }

    # Render column header with theme
    [string] RenderHeader([string]$headerText, [int]$width, [bool]$isActiveColumn) {
        $colors = $this._GetHeaderColors($isActiveColumn)

        $paddedText = $this._PadOrTruncate($headerText, $width)

        $output = ""
        $output += $colors.Bg
        $output += $colors.Fg
        $output += $paddedText
        $output += [PraxisVT]::Reset()

        return $output
    }

    # Get colors for cell based on state
    hidden [hashtable] _GetCellColors([GridCell]$cell, [bool]$isSelected, [bool]$isEditing) {
        $theme = $this.ThemeManager.CurrentTheme

        if ($isEditing) {
            # Editing: use accent colors
            return @{
                Fg = $theme.ColorMap.AccentFG
                Bg = $theme.ColorMap.AccentBG
            }
        }

        if ($isSelected) {
            # Selected but not editing: use selection colors
            return @{
                Fg = $theme.ColorMap.SelectedFG
                Bg = $theme.ColorMap.SelectedBG
            }
        }

        # Normal: use list colors
        return @{
            Fg = $theme.ColorMap.ListFG
            Bg = $theme.ColorMap.ListBG
        }
    }

    # Get colors for error state
    hidden [hashtable] _GetErrorColors() {
        $theme = $this.ThemeManager.CurrentTheme
        return @{
            Fg = $theme.ColorMap.ErrorFG
            Bg = $theme.ColorMap.ErrorBG
        }
    }

    # Get highlight background color for edit mode non-focused cells
    [string] GetHighlightBg() {
        return $this.ThemeManager.GetAnsiSequence('Highlight', $true)
    }

    # Get colors for header
    hidden [hashtable] _GetHeaderColors([bool]$isActive) {
        $theme = $this.ThemeManager.CurrentTheme

        if ($isActive) {
            return @{
                Fg = $theme.ColorMap.AccentFG
                Bg = $theme.ColorMap.AccentBG
            }
        }

        return @{
            Fg = $theme.ColorMap.HeaderFG
            Bg = $theme.ColorMap.HeaderBG
        }
    }

    # Get cursor highlight (reverse video)
    hidden [string] _GetCursorHighlight() {
        return "`e[7m"  # Reverse video
    }

    # Pad or truncate string to exact width
    hidden [string] _PadOrTruncate([string]$text, [int]$width) {
        if ($null -eq $text) {
            $text = ""
        }

        if ($text.Length -gt $width) {
            # Truncate with ellipsis
            if ($width -gt 3) {
                return $text.Substring(0, $width - 3) + "..."
            } else {
                return $text.Substring(0, $width)
            }
        } elseif ($text.Length -lt $width) {
            # Pad with spaces
            return $text + (" " * ($width - $text.Length))
        } else {
            return $text
        }
    }

    # Render row separator line
    [string] RenderSeparator([int]$totalWidth, [string]$style = 'single') {
        $theme = $this.ThemeManager.CurrentTheme
        $colors = @{
            Fg = $theme.ColorMap.BorderFG
            Bg = $theme.ColorMap.BorderBG
        }

        $char = switch ($style) {
            'single' { '─' }
            'double' { '═' }
            'thick'  { '━' }
            default  { '─' }
        }

        $output = ""
        $output += $colors.Fg + $colors.Bg
        $output += $char * $totalWidth
        $output += [PraxisVT]::Reset()

        return $output
    }

    # Render vertical separator between columns
    [string] RenderVerticalSeparator() {
        $theme = $this.ThemeManager.CurrentTheme
        $colors = @{
            Fg = $theme.ColorMap.BorderFG
            Bg = $theme.ColorMap.BorderBG
        }

        return $colors.Fg + $colors.Bg + "│" + [PraxisVT]::Reset()
    }

    # Render validation error message
    [string] RenderValidationError([string]$errorMessage, [int]$width) {
        if ([string]::IsNullOrWhiteSpace($errorMessage)) {
            return ""
        }

        $colors = $this._GetErrorColors()
        $paddedMessage = $this._PadOrTruncate(" ! $errorMessage", $width)

        $output = ""
        $output += $colors.Fg + $colors.Bg
        $output += $paddedMessage
        $output += [PraxisVT]::Reset()

        return $output
    }
}
