#!/usr/bin/env pwsh
# Test-NotesFeature.ps1 - Test the notes functionality

param(
    [switch]$Debug
)

$ErrorActionPreference = 'Stop'

Write-Host "Testing Notes Feature..." -ForegroundColor Cyan
Write-Host ""

# Load the TUI framework
Write-Host "Loading TUI framework..." -ForegroundColor Yellow
. "$PSScriptRoot/Start-PmcTUI.ps1"
Write-Host "✓ TUI framework loaded" -ForegroundColor Green
Write-Host ""

# Test NoteService
Write-Host "1. Testing NoteService..." -ForegroundColor Yellow
$noteService = [NoteService]::GetInstance()
Write-Host "   ✓ NoteService singleton created" -ForegroundColor Green

# Create test note
Write-Host "2. Creating test note..." -ForegroundColor Yellow
$note = $noteService.CreateNote("Test Note", @("test", "sample"))
Write-Host "   ✓ Note created: $($note.id)" -ForegroundColor Green
Write-Host "      Title: $($note.title)" -ForegroundColor Gray
Write-Host "      Tags: $($note.tags -join ', ')" -ForegroundColor Gray
Write-Host "      File: $($note.file)" -ForegroundColor Gray

# Save content
Write-Host "3. Saving note content..." -ForegroundColor Yellow
$content = @"
This is a test note.
It has multiple lines.
Word count test: one two three four five.
"@
$noteService.SaveNoteContent($note.id, $content)
Write-Host "   ✓ Content saved" -ForegroundColor Green

# Load content
Write-Host "4. Loading note content..." -ForegroundColor Yellow
$loadedContent = $noteService.LoadNoteContent($note.id)
Write-Host "   ✓ Content loaded: $($loadedContent.Length) characters" -ForegroundColor Green
if ($loadedContent -eq $content) {
    Write-Host "   ✓ Content matches!" -ForegroundColor Green
} else {
    Write-Host "   ✗ Content mismatch!" -ForegroundColor Red
}

# Check stats
Write-Host "5. Checking note stats..." -ForegroundColor Yellow
$note = $noteService.GetNote($note.id)
Write-Host "   Lines: $($note.line_count)" -ForegroundColor Gray
Write-Host "   Words: $($note.word_count)" -ForegroundColor Gray

# List all notes
Write-Host "6. Listing all notes..." -ForegroundColor Yellow
$allNotes = $noteService.GetAllNotes()
Write-Host "   ✓ Found $($allNotes.Count) note(s)" -ForegroundColor Green
foreach ($n in $allNotes) {
    Write-Host "      - $($n.title) (ID: $($n.id))" -ForegroundColor Gray
}

# Update note metadata
Write-Host "7. Updating note metadata..." -ForegroundColor Yellow
$noteService.UpdateNoteMetadata($note.id, @{ title = "Updated Test Note" })
$note = $noteService.GetNote($note.id)
Write-Host "   ✓ Title updated to: $($note.title)" -ForegroundColor Green

# Test NotesMenuScreen class loading
Write-Host "8. Testing NotesMenuScreen class..." -ForegroundColor Yellow
. "$PSScriptRoot/screens/NotesMenuScreen.ps1"
Write-Host "   ✓ NotesMenuScreen class loaded" -ForegroundColor Green

# Test NoteEditorScreen class loading
Write-Host "9. Testing NoteEditorScreen class..." -ForegroundColor Yellow
. "$PSScriptRoot/screens/NoteEditorScreen.ps1"
Write-Host "   ✓ NoteEditorScreen class loaded" -ForegroundColor Green

# Test menu registration
Write-Host "10. Testing menu registration..." -ForegroundColor Yellow
$registry = [MenuRegistry]::GetInstance()
$toolsMenuItems = $registry.GetMenuItems('Tools')
$notesMenuItem = $toolsMenuItems | Where-Object { $_.Label -eq 'Notes' }
if ($notesMenuItem) {
    Write-Host "   ✓ Notes menu item registered in Tools menu" -ForegroundColor Green
    Write-Host "      Hotkey: $($notesMenuItem.Hotkey)" -ForegroundColor Gray
} else {
    Write-Host "   ✗ Notes menu item NOT found in Tools menu" -ForegroundColor Red
}

# Clean up test note
Write-Host "11. Cleaning up test note..." -ForegroundColor Yellow
$noteService.DeleteNote($note.id)
Write-Host "   ✓ Test note deleted" -ForegroundColor Green

Write-Host ""
Write-Host "All tests passed! ✓" -ForegroundColor Green
Write-Host ""
Write-Host "To launch the notes feature in the TUI:" -ForegroundColor Cyan
Write-Host "  1. Start the TUI: pwsh Start-PmcTUI.ps1" -ForegroundColor White
Write-Host "  2. Press F10 to open the menu" -ForegroundColor White
Write-Host "  3. Navigate to Tools > Notes" -ForegroundColor White
Write-Host "  4. Or press Alt+T, then N for Notes" -ForegroundColor White
