# PMC Differential Renderer - Flicker-free screen updates
# Only updates changed screen regions for smooth, responsive UI

Set-StrictMode -Version Latest

# Represents a single character cell on the screen
class PmcScreenCell {
    [char] $Character = ' '
    [string] $ForegroundColor = ''
    [string] $BackgroundColor = ''
    [bool] $Bold = $false
    [bool] $Italic = $false
    [bool] $Underline = $false

    PmcScreenCell() {}

    PmcScreenCell([char]$char) {
        $this.Character = $char
    }

    PmcScreenCell([char]$char, [string]$fg, [string]$bg) {
        $this.Character = $char
        $this.ForegroundColor = $fg
        $this.BackgroundColor = $bg
    }

    [bool] Equals([object]$other) {
        if ($null -eq $other) { return $false }
        return ($this.Character -eq $other.Character -and
                $this.ForegroundColor -eq $other.ForegroundColor -and
                $this.BackgroundColor -eq $other.BackgroundColor -and
                $this.Bold -eq $other.Bold -and
                $this.Italic -eq $other.Italic -and
                $this.Underline -eq $other.Underline)
    }

    [string] ToAnsiString() {
        $ansi = ""

        # Build ANSI escape sequence
        $codes = @()

        if ($this.Bold) { $codes += "1" }
        if ($this.Italic) { $codes += "3" }
        if ($this.Underline) { $codes += "4" }

        if ($this.ForegroundColor) {
            switch ($this.ForegroundColor.ToLower()) {
                'black' { $codes += "30" }
                'red' { $codes += "31" }
                'green' { $codes += "32" }
                'yellow' { $codes += "33" }
                'blue' { $codes += "34" }
                'magenta' { $codes += "35" }
                'cyan' { $codes += "36" }
                'white' { $codes += "37" }
                'gray' { $codes += "90" }
                'brightred' { $codes += "91" }
                'brightgreen' { $codes += "92" }
                'brightyellow' { $codes += "93" }
                'brightblue' { $codes += "94" }
                'brightmagenta' { $codes += "95" }
                'brightcyan' { $codes += "96" }
                'brightwhite' { $codes += "97" }
                default {
                    # Try to parse as RGB hex color
                    if ($this.ForegroundColor.StartsWith('#') -and $this.ForegroundColor.Length -eq 7) {
                        $r = [Convert]::ToInt32($this.ForegroundColor.Substring(1,2), 16)
                        $g = [Convert]::ToInt32($this.ForegroundColor.Substring(3,2), 16)
                        $b = [Convert]::ToInt32($this.ForegroundColor.Substring(5,2), 16)
                        $codes += "38;2;$r;$g;$b"
                    }
                }
            }
        }

        if ($this.BackgroundColor) {
            switch ($this.BackgroundColor.ToLower()) {
                'black' { $codes += "40" }
                'red' { $codes += "41" }
                'green' { $codes += "42" }
                'yellow' { $codes += "43" }
                'blue' { $codes += "44" }
                'magenta' { $codes += "45" }
                'cyan' { $codes += "46" }
                'white' { $codes += "47" }
                'gray' { $codes += "100" }
                'brightred' { $codes += "101" }
                'brightgreen' { $codes += "102" }
                'brightyellow' { $codes += "103" }
                'brightblue' { $codes += "104" }
                'brightmagenta' { $codes += "105" }
                'brightcyan' { $codes += "106" }
                'brightwhite' { $codes += "107" }
                default {
                    # Try to parse as RGB hex color
                    if ($this.BackgroundColor.StartsWith('#') -and $this.BackgroundColor.Length -eq 7) {
                        $r = [Convert]::ToInt32($this.BackgroundColor.Substring(1,2), 16)
                        $g = [Convert]::ToInt32($this.BackgroundColor.Substring(3,2), 16)
                        $b = [Convert]::ToInt32($this.BackgroundColor.Substring(5,2), 16)
                        $codes += "48;2;$r;$g;$b"
                    }
                }
            }
        }

        if ($codes.Count -gt 0) {
            $ansi = "`e[$($codes -join ';')m"
        }

        return "$ansi$($this.Character)"
    }

    [string] ToString() {
        return $this.Character
    }
}

# Screen buffer that tracks all character cells
class PmcScreenBuffer {
    hidden [object] $_buffer
    hidden [int] $_width
    hidden [int] $_height
    hidden [bool] $_initialized = $false

    PmcScreenBuffer([int]$width, [int]$height) {
        $this._width = $width
        $this._height = $height
        $this.InitializeBuffer()
        $this._initialized = $true
    }

    [void] InitializeBuffer() {
        $this._buffer = @()
        for ($y = 0; $y -lt $this._height; $y++) {
            $row = @()
            for ($x = 0; $x -lt $this._width; $x++) {
                $row += [PmcScreenCell]::new()
            }
            $this._buffer += ,$row
        }
    }


    [void] Resize([int]$newWidth, [int]$newHeight) {
        if ($newWidth -eq $this._width -and $newHeight -eq $this._height) {
            return  # No change needed
        }

        $oldBuffer = $this._buffer
        $this._width = $newWidth
        $this._height = $newHeight
        $this.InitializeBuffer()

        # Copy existing content where possible
        if ($oldBuffer) {
            $copyHeight = [Math]::Min($oldBuffer.Length, $this._height)
            for ($y = 0; $y -lt $copyHeight; $y++) {
                $copyWidth = [Math]::Min($oldBuffer[$y].Length, $this._width)
                for ($x = 0; $x -lt $copyWidth; $x++) {
                    $this._buffer[$y][$x] = $oldBuffer[$y][$x]
                }
            }
        }
    }

    [object] GetCell([int]$x, [int]$y) {
        if (-not $this._initialized -or $x -lt 0 -or $y -lt 0 -or $x -ge $this._width -or $y -ge $this._height) {
            return [PmcScreenCell]::new()
        }
        return $this._buffer[$y][$x]
    }

    [void] SetCell([int]$x, [int]$y, [object]$cell) {
        if (-not $this._initialized -or $x -lt 0 -or $y -lt 0 -or $x -ge $this._width -or $y -ge $this._height) {
            return  # Out of bounds
        }
        $this._buffer[$y][$x] = $cell
    }

    [void] SetText([int]$x, [int]$y, [string]$text) {
        $this.SetText($x, $y, $text, '', '')
    }

    [void] SetText([int]$x, [int]$y, [string]$text, [string]$foregroundColor, [string]$backgroundColor) {
        if (-not $this._initialized -or $y -lt 0 -or $y -ge $this._height) {
            return
        }

        for ($i = 0; $i -lt $text.Length; $i++) {
            $cellX = $x + $i
            if ($cellX -ge $this._width) { break }

            $cell = [PmcScreenCell]::new($text[$i], $foregroundColor, $backgroundColor)
            $this.SetCell($cellX, $y, $cell)
        }
    }

    [void] Clear() {
        if (-not $this._initialized) { return }

        for ($y = 0; $y -lt $this._height; $y++) {
            for ($x = 0; $x -lt $this._width; $x++) {
                $this._buffer[$y][$x] = [PmcScreenCell]::new()
            }
        }
    }

    [void] ClearRegion([int]$x, [int]$y, [int]$width, [int]$height) {
        if (-not $this._initialized) { return }

        $endX = [Math]::Min($x + $width, $this._width)
        $endY = [Math]::Min($y + $height, $this._height)

        for ($row = $y; $row -lt $endY; $row++) {
            for ($col = $x; $col -lt $endX; $col++) {
                $this._buffer[$row][$col] = [PmcScreenCell]::new()
            }
        }
    }

    [int] GetWidth() { return $this._width }
    [int] GetHeight() { return $this._height }
}

# Change tracking for efficient updates
class PmcScreenDiff {
    [hashtable] $ChangedRegions = @{}  # Key: "x,y", Value: PmcScreenCell
    [bool] $FullRefresh = $false

    [void] AddChange([int]$x, [int]$y, [object]$cell) {
        $key = "$x,$y"
        $this.ChangedRegions[$key] = $cell
    }

    [void] Clear() {
        $this.ChangedRegions.Clear()
        $this.FullRefresh = $false
    }

    [bool] HasChanges() {
        return $this.FullRefresh -or $this.ChangedRegions.Count -gt 0
    }
}

# Main differential renderer class
class PmcDifferentialRenderer {
    hidden [object] $_frontBuffer    # Currently displayed
    hidden [object] $_backBuffer     # Being prepared
    hidden [PmcScreenDiff] $_diff
    hidden [bool] $_initialized = $false
    hidden [string] $_lastAnsiState = ""
    hidden [int] $_lastCursorX = -1
    hidden [int] $_lastCursorY = -1
    hidden [int] $_desiredCursorX = -1
    hidden [int] $_desiredCursorY = -1

    # Performance tracking
    hidden [datetime] $_lastRender = [datetime]::Now
    hidden [int] $_renderCount = 0
    hidden [double] $_totalRenderTime = 0

    PmcDifferentialRenderer([int]$width, [int]$height) {
        $this._frontBuffer = [PmcScreenBuffer]::new($width, $height)
        $this._backBuffer = [PmcScreenBuffer]::new($width, $height)
        $this._diff = [PmcScreenDiff]::new()
        $this._initialized = $true
    }

    # Get the back buffer for drawing operations
    [PmcScreenBuffer] GetDrawBuffer() {
        return $this._backBuffer
    }

    # Resize both buffers
    [void] Resize([int]$newWidth, [int]$newHeight) {
        if (-not $this._initialized) { return }

        $this._frontBuffer.Resize($newWidth, $newHeight)
        $this._backBuffer.Resize($newWidth, $newHeight)
        $this._diff.FullRefresh = $true
    }

    # Calculate differences between front and back buffers
    [void] CalculateDifferences() {
        if (-not $this._initialized) { return }

        $this._diff.Clear()

        $width = $this._backBuffer.GetWidth()
        $height = $this._backBuffer.GetHeight()

        for ($y = 0; $y -lt $height; $y++) {
            for ($x = 0; $x -lt $width; $x++) {
                $frontCell = $this._frontBuffer.GetCell($x, $y)
                $backCell = $this._backBuffer.GetCell($x, $y)

                if (-not $frontCell.Equals($backCell)) {
                    $this._diff.AddChange($x, $y, $backCell)
                }
            }
        }
    }

    # Render only the differences to the console
    [void] RenderDifferences() {
        if (-not $this._initialized -or -not $this._diff.HasChanges()) {
            return
        }

        $startTime = Get-Date

        try {
            if ($this._diff.FullRefresh) {
                $this.RenderFullScreen()
            } else {
                $this.RenderChangedCells()
            }

            # Swap buffers
            $temp = $this._frontBuffer
            $this._frontBuffer = $this._backBuffer
            $this._backBuffer = $temp

            $this._diff.Clear()

        } finally {
            # Performance tracking
            $renderTime = ((Get-Date) - $startTime).TotalMilliseconds
            $this._totalRenderTime += $renderTime
            $this._renderCount++
            $this._lastRender = Get-Date

            Write-PmcDebug -Level 3 -Category 'DifferentialRenderer' -Message "Render completed" -Data @{
                RenderTime = "$([Math]::Round($renderTime, 2))ms"
                ChangedCells = $this._diff.ChangedRegions.Count
                FullRefresh = $this._diff.FullRefresh
            }
            # Position the real cursor if requested
            if ($this._desiredCursorX -ge 0 -and $this._desiredCursorY -ge 0) {
                $this.MoveCursor($this._desiredCursorX, $this._desiredCursorY)
                # ensure cursor visible at prompt
                Write-Host "`e[?25h" -NoNewline
            }
        }
    }

    [void] RenderFullScreen() {
        # Clear screen and reset cursor
        Write-Host "`e[2J`e[H" -NoNewline
        Write-Host "`e[?25l" -NoNewline  # Hide cursor

        $this._lastAnsiState = ""
        $this._lastCursorX = 0
        $this._lastCursorY = 0

        $width = $this._backBuffer.GetWidth()
        $height = $this._backBuffer.GetHeight()

        for ($y = 0; $y -lt $height; $y++) {
            $this.MoveCursor(0, $y)
            $lineOutput = ""

            for ($x = 0; $x -lt $width; $x++) {
                $cell = $this._backBuffer.GetCell($x, $y)
                $lineOutput += $cell.ToAnsiString()
            }

            Write-Host $lineOutput -NoNewline
        }

        Write-Host "`e[0m" -NoNewline  # Reset all formatting
        $this._lastAnsiState = ""
    }

    [void] RenderChangedCells() {
        # Group adjacent changes into runs for efficiency
        $sortedChanges = $this._diff.ChangedRegions.GetEnumerator() | Sort-Object {
            $coords = $_.Key.Split(',')
            [int]$coords[1] * 10000 + [int]$coords[0]  # Sort by row, then column
        }

        $currentRow = -1
        $rowChanges = @()

        foreach ($change in $sortedChanges) {
            $coords = $change.Key.Split(',')
            $x = [int]$coords[0]
            $y = [int]$coords[1]

            if ($y -ne $currentRow) {
                # Process previous row
                if ($rowChanges.Count -gt 0) {
                    $this.RenderRowChanges($currentRow, $rowChanges)
                }

                # Start new row
                $currentRow = $y
                $rowChanges = @()
            }

            $rowChanges += @{ X = $x; Cell = $change.Value }
        }

        # Process final row
        if ($rowChanges.Count -gt 0) {
            $this.RenderRowChanges($currentRow, $rowChanges)
        }

        Write-Host "`e[0m" -NoNewline  # Reset formatting
        $this._lastAnsiState = ""
    }

    [void] RenderRowChanges([int]$row, [array]$changes) {
        # Group adjacent cells into runs
        $runs = @()
        $currentRun = $null

        foreach ($change in ($changes | Sort-Object X)) {
            if ($null -eq $currentRun -or $change.X -ne ($currentRun.EndX + 1)) {
                # Start new run
                if ($currentRun) { $runs += $currentRun }
                $currentRun = @{
                    StartX = $change.X
                    EndX = $change.X
                    Cells = @($change.Cell)
                }
            } else {
                # Extend current run
                $currentRun.EndX = $change.X
                $currentRun.Cells += $change.Cell
            }
        }

        if ($currentRun) { $runs += $currentRun }

        # Render each run
        foreach ($run in $runs) {
            $this.MoveCursor($run.StartX, $row)

            $runOutput = ""
            foreach ($cell in $run.Cells) {
                $runOutput += $cell.ToAnsiString()
            }

            Write-Host $runOutput -NoNewline
        }
    }

    [void] MoveCursor([int]$x, [int]$y) {
        if ($x -ne $this._lastCursorX -or $y -ne $this._lastCursorY) {
            Write-Host "`e[$($y + 1);$($x + 1)H" -NoNewline
            $this._lastCursorX = $x
            $this._lastCursorY = $y
        }
    }

    # Main render method - calculates differences and renders
    [void] Render() {
        if (-not $this._initialized) { return }

        $this.CalculateDifferences()
        $this.RenderDifferences()

        # After flushing text, place the hardware cursor if requested
        if ($this._desiredCursorX -ge 0 -and $this._desiredCursorY -ge 0) {
            try {
                $this.MoveCursor($this._desiredCursorX, $this._desiredCursorY)
            } catch { }
        }
    }

    # Force a full screen refresh
    [void] ForceFullRefresh() {
        $this._diff.FullRefresh = $true
        $this.Render()
    }

    # Performance statistics
    [hashtable] GetPerformanceStats() {
        $avgRenderTime = if ($this._renderCount -gt 0) { $this._totalRenderTime / $this._renderCount } else { 0 }

        return @{
            RenderCount = $this._renderCount
            TotalRenderTime = $this._totalRenderTime
            AverageRenderTime = [Math]::Round($avgRenderTime, 2)
            LastRender = $this._lastRender
            BufferSize = "$($this._frontBuffer.GetWidth())x$($this._frontBuffer.GetHeight())"
        }
    }

    # Cleanup
    [void] ShowCursor() {
        Write-Host "`e[?25h" -NoNewline
    }

    [void] HideCursor() {
        Write-Host "`e[?25l" -NoNewline
    }

    [void] Reset() {
        Write-Host "`e[2J`e[H`e[0m`e[?25h" -NoNewline
        $this._lastAnsiState = ""
        $this._lastCursorX = -1
        $this._lastCursorY = -1
    }

    [void] SetDesiredCursor([int]$x, [int]$y) {
        $this._desiredCursorX = [Math]::Max(0, $x)
        $this._desiredCursorY = [Math]::Max(0, $y)
    }
}

# Global instance
$Script:PmcDifferentialRenderer = $null

function Initialize-PmcDifferentialRenderer {
    param(
        [int]$Width = 120,
        [int]$Height = 30
    )

    if ($Script:PmcDifferentialRenderer) {
        Write-Warning "PMC Differential Renderer already initialized"
        return
    }

    try {
        # Get actual terminal dimensions if possible
        if ([Console]::WindowWidth -gt 0) {
            $Width = [Console]::WindowWidth
            $Height = [Console]::WindowHeight
        }
    } catch {
        Write-PmcDebug -Level 2 -Category 'DifferentialRenderer' -Message "Could not get terminal dimensions, using defaults"
    }

    $Script:PmcDifferentialRenderer = [PmcDifferentialRenderer]::new($Width, $Height)
    Write-PmcDebug -Level 2 -Category 'DifferentialRenderer' -Message "Differential renderer initialized ($Width x $Height)"
}

function Get-PmcDifferentialRenderer {
    if (-not $Script:PmcDifferentialRenderer) {
        Initialize-PmcDifferentialRenderer
    }
    return $Script:PmcDifferentialRenderer
}

function Reset-PmcDifferentialRenderer {
    if ($Script:PmcDifferentialRenderer) {
        $Script:PmcDifferentialRenderer.Reset()
        $Script:PmcDifferentialRenderer = $null
    }
}

Export-ModuleMember -Function Initialize-PmcDifferentialRenderer, Get-PmcDifferentialRenderer, Reset-PmcDifferentialRenderer
