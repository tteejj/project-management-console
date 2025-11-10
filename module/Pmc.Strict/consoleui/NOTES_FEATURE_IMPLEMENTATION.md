# Notes Feature Implementation

## Overview

A complete notes management feature has been added to the PMC TUI application. This feature allows users to create, edit, and manage text notes with full text editor capabilities.

## Files Created

### 1. NoteService.ps1
**Location**: `consoleui/services/NoteService.ps1`

**Purpose**: Singleton service for managing notes with CRUD operations

**Features**:
- Create, read, update, delete notes
- File-based storage in `notes/` directory
- Metadata management (title, tags, word count, line count, timestamps)
- Atomic file saves (write to temp, then rename)
- Event callbacks for data changes (OnNoteAdded, OnNoteUpdated, OnNoteDeleted)
- JSON metadata storage in `notes/notes_metadata.json`

**API**:
```powershell
$service = [NoteService]::GetInstance()

# CRUD operations
$note = $service.CreateNote("My Note", @("tag1", "tag2"))
$notes = $service.GetAllNotes()
$note = $service.GetNote($noteId)
$service.UpdateNoteMetadata($noteId, @{ title = "New Title" })
$service.DeleteNote($noteId)

# Content operations
$content = $service.LoadNoteContent($noteId)
$service.SaveNoteContent($noteId, $content)

# Event handlers
$service.OnNoteAdded = { param($note) Write-Host "Added: $($note.title)" }
```

### 2. NotesMenuScreen.ps1
**Location**: `consoleui/screens/NotesMenuScreen.ps1`

**Purpose**: List view screen for all notes (extends StandardListScreen)

**Features**:
- Display notes in a sortable, searchable list
- Columns: Title, Modified date, Line count, Word count, Tags
- Inline editor for add/edit note metadata (title, tags)
- Delete notes with confirmation
- Press Enter to open note in editor
- Auto-refresh when notes change
- Keyboard shortcuts (Add, Edit, Delete, Open)

**Menu Registration**:
- Registered in Tools menu with hotkey 'N'
- Auto-discovered by MenuRegistry

### 3. NoteEditorScreen.ps1
**Location**: `consoleui/screens/NoteEditorScreen.ps1`

**Purpose**: Full-screen text editor for note content (extends PmcScreen)

**Features**:
- Full-featured text editing via TextAreaEditor widget
- Breadcrumb header showing note title
- Status bar with cursor position, line/word/character counts
- Modified indicator (*)
- Auto-save on exit
- Keyboard shortcuts:
  - Ctrl+S: Save
  - Esc: Save and go back
  - Ctrl+Z: Undo
  - Ctrl+Y: Redo
  - All TextAreaEditor shortcuts (see TextAreaEditor.ps1)

**Layout**:
```
┌─ MenuBar (1 line)
├─ Header/Breadcrumb (3 lines)
├─ TextAreaEditor (remaining height - 1)
└─ Footer/Shortcuts (1 line)
```

### 4. Test-NotesFeature.ps1
**Location**: `consoleui/Test-NotesFeature.ps1`

**Purpose**: Unit tests for notes functionality

**Tests**:
- NoteService creation and CRUD operations
- Note content save/load
- Metadata updates
- Screen class loading
- Menu registration

## Integration Points

### Data Layer
- **Storage**: Notes are stored in `<PMC_ROOT>/notes/` directory
  - Individual note files: `<noteId>.txt`
  - Metadata file: `notes_metadata.json`
- **NoteService**: Handles all file I/O and metadata management
- **Atomic saves**: Uses temp file + rename pattern (same as tasks.json)

### Menu System
- **Menu**: Tools > Notes (hotkey: N)
- **Auto-discovery**: MenuRegistry automatically discovers and registers NotesMenuScreen
- **Access**: F10 → Tools → Notes, or Alt+T then N

### Widget Integration
- **TextAreaEditor**: Added to widget loading in Start-PmcTUI.ps1
- **UniversalList**: Used by NotesMenuScreen for list display
- **InlineEditor**: Used by NotesMenuScreen for add/edit dialogs

### Screen Architecture
- **NotesMenuScreen**: Extends StandardListScreen (list-based pattern)
- **NoteEditorScreen**: Extends PmcScreen (custom content pattern)
- Both screens use shared MenuBar, Header, Footer widgets

## Usage

### Starting the TUI
```bash
cd /home/teej/pmc/module/Pmc.Strict/consoleui
pwsh Start-PmcTUI.ps1
```

### Accessing Notes
1. **Via Menu**: Press F10, navigate to Tools → Notes
2. **Via Hotkey**: Alt+T, then N

### Managing Notes
- **Add**: Press 'A' in notes list, enter title and tags
- **Edit**: Select note, press 'E', edit metadata
- **Open**: Select note, press Enter or 'O'
- **Delete**: Select note, press 'D'

### Editing Notes
- **Save**: Ctrl+S (saves without exiting)
- **Exit**: Esc (saves and returns to list)
- **Undo/Redo**: Ctrl+Z / Ctrl+Y
- **Full editing**: See TextAreaEditor.ps1 for all shortcuts

## Future Enhancements

### Phase 2: Attach to Projects/Tasks
- Add `notes` array to projects in tasks.json
- Add `notes` array to tasks in tasks.json
- Update NotesMenuScreen to filter by parent (project/task)
- Add "Add Note" button to ProjectInfoScreen
- Add note indicator column to TaskListScreen

### Phase 3: Additional Features
- Full-text search across all notes
- Note templates
- Note linking (wiki-style [[links]])
- Export notes (markdown, PDF)
- Note categories/folders
- Attachments support
- Note sharing/collaboration

## File Structure

```
consoleui/
├── services/
│   └── NoteService.ps1           # CRUD + file management
├── screens/
│   ├── NotesMenuScreen.ps1       # List view
│   └── NoteEditorScreen.ps1      # Edit view
├── widgets/
│   └── TextAreaEditor.ps1        # Text editor widget
├── Test-NotesFeature.ps1         # Unit tests
└── Start-PmcTUI.ps1              # Added TextAreaEditor to widget loading

<PMC_ROOT>/
└── notes/
    ├── notes_metadata.json       # Note metadata
    ├── <noteId1>.txt             # Note content files
    ├── <noteId2>.txt
    └── ...
```

## Testing

Run unit tests:
```bash
cd /home/teej/pmc/module/Pmc.Strict/consoleui
pwsh Test-NotesFeature.ps1
```

Expected output:
- ✓ NoteService singleton created
- ✓ Note created
- ✓ Content saved/loaded
- ✓ Stats calculated
- ✓ Metadata updated
- ✓ Screen classes loaded
- ✓ Test note deleted

## Known Issues

None currently. The feature is fully functional and ready for use.

## Implementation Notes

1. **Singleton Pattern**: NoteService uses thread-safe singleton with double-checked locking
2. **Event-Driven**: NoteService fires events on data changes; screens auto-refresh
3. **Atomic Saves**: Both metadata and note content use atomic save pattern
4. **Gap Buffer**: TextAreaEditor uses gap buffer for efficient editing
5. **Menu Discovery**: MenuRegistry auto-discovers RegisterMenuItems() methods
6. **Lazy Loading**: NoteEditorScreen is loaded only when needed (dynamic dot-sourcing)

## Summary

The notes feature is fully implemented and integrated into the PMC TUI application. It provides a complete note-taking experience with list management and full-featured text editing. The implementation follows the existing architecture patterns (StandardListScreen, PmcScreen, services, widgets) and is ready for production use.

Future work can focus on attaching notes to projects/tasks and adding advanced features like search, templates, and linking.
