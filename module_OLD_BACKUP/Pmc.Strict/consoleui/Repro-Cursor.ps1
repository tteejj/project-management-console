
# Repro-Cursor.ps1
using namespace System.Collections.Generic

# Mock PraxisVT
class PraxisVT {
    static [string] MoveTo([int]$x, [int]$y) { return "" }
    static [string] ClearToEnd() { return "" }
    static [string] ShowCursor() { return "" }
    static [string] RGBBG([int]$r, [int]$g, [int]$b) { return "" }
    static [string] Reset() { return "" }
}

# Import files
. "$PSScriptRoot/helpers/GapBuffer.ps1"
. "$PSScriptRoot/widgets/TextAreaEditor.ps1"

$editor = [TextAreaEditor]::new()
$editor.SetBounds(0, 6, 80, 20)
$editor.SetText("abc")

Write-Host "Initial State:"
Write-Host "Cursor: $($editor.CursorX), $($editor.CursorY)"
Write-Host "Line Count: $($editor.GetLineCount())"
Write-Host "Line 0: '$($editor.GetLine(0))'"
Write-Host "Line 1: '$($editor.GetLine(1))'"

# Mock Engine
$engine = [PSCustomObject]@{
    Writes = [System.Collections.Generic.List[string]]::new()
    WriteAt = { param($x, $y, $char, $fg, $bg) 
        $this.Writes.Add("WriteAt($x, $y, '$char')") 
    }
    Width = 80
    Height = 24
}

$editor.RenderToEngine($engine)

Write-Host "`nRender Output (First 5 writes):"
$engine.Writes | Select-Object -First 5

# Check where 'a' was written
$aWrite = $engine.Writes | Where-Object { $_ -like "*'a')*" }
Write-Host "`n'a' written at: $aWrite"

# Check where cursor was written
$cursorWrite = $engine.Writes | Where-Object { $_ -like "*[30;47m*" }
Write-Host "Cursor written at: $cursorWrite"
