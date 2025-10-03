# PMC FakeTUI Simple Terminal - Minimal terminal control for static UI
# Based on SpeedTUI SimplifiedTerminal but adapted for PMC's needs

. "$PSScriptRoot/PerformanceCore.ps1"

<#
.SYNOPSIS
Simple terminal class for PMC FakeTUI - no framework complexity
.DESCRIPTION
Provides minimal terminal control with:
- Direct console output (no batching/frames)
- Static drawing operations
- Performance optimizations from cached strings
- Simple positioning and colors
.EXAMPLE
$terminal = [PmcSimpleTerminal]::GetInstance()
$terminal.Initialize()
$terminal.WriteAt(10, 5, "Hello World")
$terminal.DrawBox(5, 3, 20, 8)
#>
class PmcSimpleTerminal {
    # Singleton instance
    static [PmcSimpleTerminal]$Instance = $null

    # Basic state
    [int]$Width
    [int]$Height
    [bool]$CursorVisible = $true

    # Private constructor
    hidden PmcSimpleTerminal() {
        $this.UpdateDimensions()
    }

    # Get singleton instance
    static [PmcSimpleTerminal] GetInstance() {
        if ($null -eq [PmcSimpleTerminal]::Instance) {
            [PmcSimpleTerminal]::Instance = [PmcSimpleTerminal]::new()
        }
        return [PmcSimpleTerminal]::Instance
    }

    # Initialize terminal for FakeTUI mode
    [void] Initialize() {
        # Clear screen
        [Console]::Clear()

        # Hide cursor for cleaner display
        try {
            [Console]::CursorVisible = $false
            $this.CursorVisible = $false
        } catch {
            # Ignore cursor control errors
        }

        # Update dimensions
        $this.UpdateDimensions()

        # Position at top-left
        [Console]::SetCursorPosition(0, 0)
    }

    # Cleanup and restore terminal state
    [void] Cleanup() {
        # Restore cursor
        try {
            [Console]::CursorVisible = $true
            $this.CursorVisible = $true
        } catch {
            # Ignore cursor control errors
        }

        # Clear screen
        [Console]::Clear()
    }

    # Update terminal dimensions
    [void] UpdateDimensions() {
        try {
            $this.Width = [Console]::WindowWidth
            $this.Height = [Console]::WindowHeight
        } catch {
            # Fallback dimensions
            $this.Width = 120
            $this.Height = 30
        }
    }

    # Clear entire screen
    [void] Clear() {
        [Console]::Clear()
        [Console]::SetCursorPosition(0, 0)
    }

    # Write text at position (basic)
    [void] WriteAt([int]$x, [int]$y, [string]$text) {
        if ([string]::IsNullOrEmpty($text)) { return }

        # Bounds check
        if ($x -lt 0 -or $y -lt 0 -or $x -ge $this.Width -or $y -ge $this.Height) {
            return
        }

        # Clip text if too long
        $maxLength = $this.Width - $x
        if ($text.Length -gt $maxLength) {
            $text = $text.Substring(0, $maxLength)
        }

        # Position and write
        [Console]::SetCursorPosition($x, $y)
        [Console]::Write($text)
    }

    # Write colored text at position
    [void] WriteAtColor([int]$x, [int]$y, [string]$text, [string]$foreground, [string]$background = "") {
        if ([string]::IsNullOrEmpty($text)) { return }

        # Bounds check
        if ($x -lt 0 -or $y -lt 0 -or $x -ge $this.Width -or $y -ge $this.Height) {
            return
        }

        # Clip text if too long
        $maxLength = $this.Width - $x
        if ($text.Length -gt $maxLength) {
            $text = $text.Substring(0, $maxLength)
        }

        # Build colored text using cached sequences
        $colored = $foreground
        if (-not [string]::IsNullOrEmpty($background)) {
            $colored += $background
        }
        $colored += $text + [PmcVT100]::Reset()

        # Position and write
        [Console]::SetCursorPosition($x, $y)
        [Console]::Write($colored)
    }

    # Write RGB colored text
    [void] WriteAtRGB([int]$x, [int]$y, [string]$text, [int]$r, [int]$g, [int]$b) {
        $color = [PmcVT100]::RGB($r, $g, $b)
        $this.WriteAtColor($x, $y, $text, $color, "")
    }

    # Write with RGB background
    [void] WriteAtRGBBg([int]$x, [int]$y, [string]$text, [int]$fgR, [int]$fgG, [int]$fgB, [int]$bgR, [int]$bgG, [int]$bgB) {
        $fgColor = [PmcVT100]::RGB($fgR, $fgG, $fgB)
        $bgColor = [PmcVT100]::BgRGB($bgR, $bgG, $bgB)
        $this.WriteAtColor($x, $y, $text, $fgColor, $bgColor)
    }

    # Fill rectangular area with spaces (for clearing regions)
    [void] FillArea([int]$x, [int]$y, [int]$width, [int]$height, [char]$ch = ' ') {
        if ($width -le 0 -or $height -le 0) { return }

        # Use cached spaces for performance
        $line = if ($ch -eq ' ') {
            [PmcStringCache]::GetSpaces($width)
        } else {
            [string]::new($ch, $width)
        }

        for ($row = 0; $row -lt $height; $row++) {
            $currentY = $y + $row
            if ($currentY -ge $this.Height) { break }
            $this.WriteAt($x, $currentY, $line)
        }
    }

    # Draw a box using cached box drawing characters
    [void] DrawBox([int]$x, [int]$y, [int]$width, [int]$height) {
        if ($width -lt 2 -or $height -lt 2) { return }
        if ($x + $width -gt $this.Width -or $y + $height -gt $this.Height) { return }

        # Use cached box drawing characters
        $tl = [PmcStringCache]::GetBoxDrawing("topleft")
        $tr = [PmcStringCache]::GetBoxDrawing("topright")
        $bl = [PmcStringCache]::GetBoxDrawing("bottomleft")
        $br = [PmcStringCache]::GetBoxDrawing("bottomright")
        $h = [PmcStringCache]::GetBoxDrawing("horizontal")
        $v = [PmcStringCache]::GetBoxDrawing("vertical")

        # Use cached horizontal line for performance
        $topLine = $tl + ([PmcStringCache]::GetSpaces($width - 2).Replace(' ', $h)) + $tr
        $bottomLine = $bl + ([PmcStringCache]::GetSpaces($width - 2).Replace(' ', $h)) + $br

        # Draw top border
        $this.WriteAt($x, $y, $topLine)

        # Draw side borders
        for ($row = 1; $row -lt $height - 1; $row++) {
            $this.WriteAt($x, $y + $row, $v)
            $this.WriteAt($x + $width - 1, $y + $row, $v)
        }

        # Draw bottom border
        $this.WriteAt($x, $y + $height - 1, $bottomLine)
    }

    # Draw a filled box with optional border
    [void] DrawFilledBox([int]$x, [int]$y, [int]$width, [int]$height, [bool]$border = $true) {
        # Fill the area first
        $this.FillArea($x, $y, $width, $height, ' ')

        # Draw border if requested
        if ($border) {
            $this.DrawBox($x, $y, $width, $height)
        }
    }

    # Clear a rectangular region
    [void] ClearRegion([int]$x, [int]$y, [int]$width, [int]$height) {
        $this.FillArea($x, $y, $width, $height, ' ')
    }

    # Set cursor position
    [void] SetCursorPosition([int]$x, [int]$y) {
        if ($x -ge 0 -and $y -ge 0 -and $x -lt $this.Width -and $y -lt $this.Height) {
            [Console]::SetCursorPosition($x, $y)
        }
    }

    # Show/hide cursor
    [void] ShowCursor([bool]$visible) {
        try {
            [Console]::CursorVisible = $visible
            $this.CursorVisible = $visible
        } catch {
            # Ignore cursor control errors
        }
    }

    # Helper method to draw a separator line
    [void] DrawHorizontalLine([int]$x, [int]$y, [int]$length) {
        if ($length -le 0) { return }

        $h = [PmcStringCache]::GetBoxDrawing("horizontal")
        $line = [PmcStringCache]::GetSpaces($length).Replace(' ', $h)
        $this.WriteAt($x, $y, $line)
    }

    # Helper method to draw a vertical line
    [void] DrawVerticalLine([int]$x, [int]$y, [int]$length) {
        if ($length -le 0) { return }

        $v = [PmcStringCache]::GetBoxDrawing("vertical")
        for ($i = 0; $i -lt $length; $i++) {
            $this.WriteAt($x, $y + $i, $v)
        }
    }
}

# Export the terminal instance getter
function Get-PmcTerminal {
    return [PmcSimpleTerminal]::GetInstance()
}