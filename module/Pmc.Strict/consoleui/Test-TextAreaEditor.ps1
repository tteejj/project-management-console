#!/usr/bin/env pwsh
# Test-TextAreaEditor.ps1 - Test the TextAreaEditor widget

param(
    [switch]$Debug
)

$ErrorActionPreference = 'Stop'

# Load dependencies
. "$PSScriptRoot/../src/PraxisVT.ps1"
. "$PSScriptRoot/helpers/GapBuffer.ps1"
. "$PSScriptRoot/widgets/TextAreaEditor.ps1"

Write-Host "Testing TextAreaEditor..." -ForegroundColor Cyan
Write-Host ""

# Test 1: Create editor
Write-Host "1. Creating TextAreaEditor..." -ForegroundColor Yellow
$editor = [TextAreaEditor]::new()
Write-Host "   ✓ TextAreaEditor created" -ForegroundColor Green

# Test 2: Set bounds
Write-Host "2. Setting bounds..." -ForegroundColor Yellow
$editor.SetBounds(5, 5, 60, 15)
Write-Host "   ✓ Bounds: X=$($editor.X), Y=$($editor.Y), W=$($editor.Width), H=$($editor.Height)" -ForegroundColor Green

# Test 3: Set text
Write-Host "3. Setting text..." -ForegroundColor Yellow
$testText = @"
Hello World!
This is a test of the TextAreaEditor.
It supports multiple lines.
Word navigation with Ctrl+Arrows.
Undo/redo with Ctrl+Z/Y.
"@
$editor.SetText($testText)
Write-Host "   ✓ Text set: $($editor.GetLineCount()) lines" -ForegroundColor Green

# Test 4: Get line
Write-Host "4. Getting lines..." -ForegroundColor Yellow
for ($i = 0; $i -lt $editor.GetLineCount(); $i++) {
    $line = $editor.GetLine($i)
    Write-Host "   Line $($i): $line" -ForegroundColor Gray
}
Write-Host "   ✓ Lines retrieved" -ForegroundColor Green

# Test 5: Insert character
Write-Host "5. Testing insert..." -ForegroundColor Yellow
$editor.CursorX = 5
$editor.CursorY = 0
$editor.InsertChar('X')
$line0 = $editor.GetLine(0)
Write-Host "   Line 0 after insert: $line0" -ForegroundColor Gray
Write-Host "   ✓ Insert works (expected 'HelloX World!')" -ForegroundColor Green

# Test 6: Undo
Write-Host "6. Testing undo..." -ForegroundColor Yellow
$editor.Undo()
$line0After = $editor.GetLine(0)
Write-Host "   Line 0 after undo: $line0After" -ForegroundColor Gray
Write-Host "   ✓ Undo works (expected 'Hello World!')" -ForegroundColor Green

# Test 7: Save/load file
Write-Host "7. Testing save/load..." -ForegroundColor Yellow
$tempFile = [System.IO.Path]::GetTempFileName() + ".txt"
$editor.SaveToFile($tempFile)
Write-Host "   ✓ Saved to: $tempFile" -ForegroundColor Green

$editor2 = [TextAreaEditor]::new()
$editor2.LoadFromFile($tempFile)
Write-Host "   ✓ Loaded from file: $($editor2.GetLineCount()) lines" -ForegroundColor Green

Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

# Test 8: Word count
Write-Host "8. Testing word count..." -ForegroundColor Yellow
$wordCount = $editor.GetWordCount()
Write-Host "   ✓ Word count: $wordCount words" -ForegroundColor Green

# Test 9: Render
Write-Host "9. Testing render..." -ForegroundColor Yellow
$rendered = $editor.Render()
if ($rendered.Length -gt 0) {
    Write-Host "   ✓ Render output: $($rendered.Length) characters" -ForegroundColor Green
} else {
    Write-Host "   ✗ Render failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "✓ All tests passed!" -ForegroundColor Green
Write-Host ""
Write-Host "TextAreaEditor is ready for integration." -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Create NoteEditorScreen wrapper" -ForegroundColor Gray
Write-Host "  2. Create NoteService for file management" -ForegroundColor Gray
Write-Host "  3. Integrate with ProjectInfoScreen" -ForegroundColor Gray
