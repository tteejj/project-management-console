# Notes Editor Implementation Analysis

**Date**: 2025-11-10
**Purpose**: Analyze existing PowerShell multiline text editor implementations to guide PMC ConsoleUI development

---

## Found Implementations

### 1. FullNotesEditor (SimpleTaskPro - Praxis)
**Location**: `/home/teej/_tui/praxis-main/simpletaskpro/Core/FullNotesEditor.ps1`

**Architecture**: Full-featured, production-ready editor with advanced features

#### Key Features
- **Gap Buffer** text storage (efficient insertions/deletions)
- **Line indexing** for fast line operations
- **Undo/redo** with 100-level stack
- **Selection support** (visual highlighting)
- **Auto-save** and backup system
- **Atomic file saves** (write to temp, then rename)
- **Crash recovery** (auto-save on focus loss/exit)
- **Word-based navigation** (Ctrl+Left/Right)
- **Universal backup manager** integration
- **Horizontal + vertical scrolling**
- **Tab width** configuration (converts to spaces)

#### Technical Implementation
```powershell
class FullNotesEditor {
    hidden [GapBuffer]$_gapBuffer           # Efficient text storage
    hidden [ArrayList]$_lineStarts          # Line index for O(1) line access
    [int]$CursorX, $CursorY                 # Cursor position (line/col)
    [int]$ScrollOffsetY, $ScrollOffsetX     # Viewport offset
    [bool]$HasSelection                     # Selection state
    [ArrayList]$_undoStack, $_redoStack     # Undo/redo
}
```

**Text Storage**: Gap buffer - optimized for insertions at cursor position
**Line Access**: Maintains line start positions for fast `GetLine(index)`
**Cursor Movement**: Line/column based (like traditional editors)
**Rendering**: VT100 escape sequences, manual cursor positioning

#### Strengths
✅ Production-ready, battle-tested code
✅ Efficient data structures (gap buffer)
✅ Complete undo/redo system
✅ Auto-save and crash recovery
✅ Word navigation (Ctrl+arrows)
✅ Professional backup system

#### Weaknesses
⚠️ Depends on `GapBuffer` class (needs to be ported)
⚠️ Depends on `UniversalBackupManager` (heavy dependency)
⚠️ Depends on `VT` class for rendering
⚠️ More complex than needed for basic notes

#### Best For
- **Production use** where reliability is critical
- **Large documents** (gap buffer handles large files efficiently)
- **Advanced editing** features (selection, undo/redo)

---

### 2. SimpleTextEditor (Alcar/XP)
**Location**: `/home/teej/Downloads/_XP-main/_XP-main/alcar/Screens/SimpleTextEditor.ps1`

**Architecture**: Lightweight, straightforward editor with core features

#### Key Features
- **ArrayList** text storage (one string per line)
- **Basic navigation** (arrows, home/end, page up/down)
- **Horizontal + vertical scrolling**
- **Simple rendering** (VT100 escape sequences)
- **File load/save** operations
- **Modified tracking** with status bar
- **Tab support** (inserts 4 spaces)
- **Extends Screen class** (integrates with framework)

#### Technical Implementation
```powershell
class SimpleTextEditor : Screen {
    [ArrayList]$Lines                       # Each line = one string
    [int]$CursorX, $CursorY                # Cursor position
    [int]$ScrollY, $ScrollX                # Scroll offset
    [string]$FileName                       # File path
    [bool]$Modified                         # Dirty flag
}
```

**Text Storage**: ArrayList of strings (one per line) - simple, direct
**Line Access**: Direct array indexing `$Lines[$index]`
**Cursor Movement**: Line/column based
**Rendering**: VT100 with inverted colors for cursor

#### Strengths
✅ Simple, easy to understand
✅ No external dependencies (just `Screen` base class)
✅ Lightweight (minimal memory overhead)
✅ Clean code structure
✅ Integrates well with screen framework

#### Weaknesses
⚠️ No undo/redo
⚠️ No selection support
⚠️ No auto-save
⚠️ No backup system
⚠️ Inefficient for large edits (string concatenation)

#### Best For
- **Simple notes** (small to medium text)
- **Quick implementation** (minimal code)
- **Integration** with existing screen frameworks

---

## Comparison Table

| Feature                  | FullNotesEditor      | SimpleTextEditor     | PMC Needs          |
|--------------------------|----------------------|----------------------|--------------------|
| **Text Storage**         | Gap Buffer           | ArrayList[string]    | ArrayList (simple) |
| **Undo/Redo**            | ✅ 100 levels        | ❌ No                | ✅ Yes (nice-to-have) |
| **Selection**            | ✅ Yes               | ❌ No                | ⚠️ Optional        |
| **Auto-save**            | ✅ Advanced          | ❌ No                | ✅ Yes (required)  |
| **Backup**               | ✅ Universal system  | ❌ No                | ⚠️ Basic (optional)|
| **Word Navigation**      | ✅ Ctrl+arrows       | ❌ No                | ⚠️ Nice-to-have    |
| **Scrolling**            | ✅ Both axes         | ✅ Both axes         | ✅ Yes             |
| **Dependencies**         | GapBuffer, VT, Backup| Screen, VT           | Minimal            |
| **Code Complexity**      | High (672 lines)     | Low (442 lines)      | Medium             |
| **Best Use Case**        | Large docs, advanced | Simple notes         | Notes & checklists |

---

## Recommendation for PMC ConsoleUI

### Hybrid Approach: "SimpleTextEditor+"

Take **SimpleTextEditor** as the base and selectively add features from **FullNotesEditor**:

#### Core (from SimpleTextEditor)
- ✅ ArrayList text storage (simple, sufficient for notes)
- ✅ Basic navigation (arrows, home/end, page up/down)
- ✅ Horizontal/vertical scrolling
- ✅ File load/save
- ✅ Modified tracking
- ✅ Integrates with PmcWidget/Screen base class

#### Enhanced Features (from FullNotesEditor)
- ✅ **Auto-save** (simpler version - save to .txt.tmp, then rename)
- ✅ **Basic undo** (simple text snapshot stack, limit to 20 levels)
- ⚠️ **Word navigation** (Ctrl+Left/Right) - optional, nice-to-have
- ❌ **Selection** - skip for v1 (can add later)
- ❌ **Gap buffer** - skip (overkill for notes)
- ❌ **Universal backup** - skip (too complex)

#### PMC-Specific Additions
- ✅ **Word/line count** display in status bar
- ✅ **Integration with NoteService** (save to notes/ directory)
- ✅ **Breadcrumb navigation** (show parent project/task)
- ✅ **Tags display** (optional) in header
- ✅ **Ctrl+S explicit save** prompt
- ✅ **Esc to exit** with save prompt if modified

---

## Proposed Implementation: TextAreaEditor

### Class Structure

```powershell
class TextAreaEditor : PmcWidget {
    # Text storage (simple)
    [System.Collections.ArrayList]$Lines

    # Cursor and viewport
    [int]$CursorX = 0
    [int]$CursorY = 0
    [int]$ScrollY = 0
    [int]$ScrollX = 0

    # State
    [bool]$Modified = $false
    [string]$FilePath = ""

    # Undo (simple snapshot stack)
    hidden [System.Collections.ArrayList]$_undoStack
    [int]$MaxUndoLevels = 20

    # Settings
    [int]$TabWidth = 4
    [bool]$WordWrap = $false  # Start with false, add later

    # Display
    [int]$ViewportWidth
    [int]$ViewportHeight

    # Methods
    [void] LoadFromFile([string]$path)
    [void] SaveToFile([string]$path)
    [void] InsertChar([char]$c)
    [void] InsertLine()
    [void] Backspace()
    [void] Delete()
    [void] MoveCursor([ConsoleKey]$key)
    [void] Undo()
    [void] SaveUndoState()
    [string] Render()
    [bool] HandleInput([ConsoleKeyInfo]$key)
}
```

### Key Design Decisions

1. **Text Storage**: `ArrayList[string]` (one line per entry)
   - Simple, proven, sufficient for notes
   - No gap buffer complexity
   - Direct line indexing

2. **Undo System**: Snapshot-based (not incremental)
   - Save full text on edits
   - Limit to 20 snapshots (memory constraint)
   - Simple, reliable

3. **Auto-save**: On Ctrl+S + on exit
   - Atomic write (temp file → rename)
   - No complex backup system
   - Save prompt if modified on Esc

4. **Rendering**: Use SpeedTUI/VT100 (already in PMC)
   - Cursor shown via `[VT]::MoveTo()`
   - Line-by-line rendering
   - Status bar at bottom

5. **Integration**: Extends `PmcWidget`
   - Works within screen framework
   - Uses `HandleInput()` pattern
   - Compatible with existing navigation

---

## Implementation Files Needed

### 1. Core Widget
**File**: `widgets/TextAreaEditor.ps1`
- Core text editing functionality
- Based on SimpleTextEditor architecture
- Adds simple undo from FullNotesEditor

### 2. Note Editor Screen
**File**: `screens/NoteEditorScreen.ps1`
- Wraps TextAreaEditor
- Shows breadcrumb (project/task name)
- Status bar with word/line count
- Save prompt on exit

### 3. Notes Menu Screen
**File**: `screens/NotesMenuScreen.ps1`
- List notes for project/task
- Add/delete operations
- Navigate to NoteEditorScreen

### 4. Service Layer
**File**: `services/NoteService.ps1`
- CRUD operations
- File I/O (load/save .txt files)
- Metadata management (word count, modified date)
- Integration with tasks.json

---

## Code to Port/Adapt

### From SimpleTextEditor (primary base)
- ✅ Core class structure
- ✅ `InsertText()` method
- ✅ `HandleBackspace()` / `HandleDelete()`
- ✅ `HandleEnter()` (line splitting)
- ✅ `MoveCursor()` navigation
- ✅ `EnsureCursorVisible()` scrolling
- ✅ `LoadFile()` / `SaveFile()`
- ✅ `RenderTextArea()` / `RenderCursor()`

### From FullNotesEditor (selective features)
- ✅ `SaveUndoState()` / `Undo()` (simplified)
- ✅ `AtomicSave()` (temp file → rename pattern)
- ✅ `GetWordCount()` / `GetLineCount()` (statistics)
- ✅ `MoveCursorWordLeft()` / `MoveCursorWordRight()` (optional)
- ❌ Skip: GapBuffer, Selection, UniversalBackupManager

### PMC-Specific (new code)
- ✅ Integration with NoteService
- ✅ Breadcrumb display (parent project/task)
- ✅ Save prompt dialog
- ✅ Tags display (if applicable)

---

## Next Steps

1. ✅ **Create TextAreaEditor.ps1** based on SimpleTextEditor
2. ✅ **Add simple undo** (snapshot stack from FullNotesEditor)
3. ✅ **Add auto-save** (atomic write pattern)
4. ✅ **Create NoteEditorScreen.ps1** (wraps widget)
5. ✅ **Create NoteService.ps1** (file I/O + metadata)
6. ✅ **Test standalone** (verify editing works)
7. ✅ **Integrate with ProjectInfoScreen** (notes section)
8. ✅ **Create NotesMenuScreen** (list notes)

---

## Estimated Complexity

- **TextAreaEditor**: ~400 lines (based on SimpleTextEditor + undo)
- **NoteEditorScreen**: ~150 lines (wrapper + status bar)
- **NotesMenuScreen**: ~100 lines (list view)
- **NoteService**: ~200 lines (CRUD + file I/O)

**Total**: ~850 lines for complete notes system

**Time Estimate**:
- TextAreaEditor: 2-3 hours
- Screens: 1-2 hours
- Service: 1 hour
- Integration: 1 hour
- Testing: 1 hour
**Total**: ~6-8 hours

---

## Risk Assessment

**Low Risk**:
- ✅ Code is proven (both implementations are production-tested)
- ✅ No complex dependencies (just VT100 + ArrayList)
- ✅ Simple text storage (no database, no serialization complexity)

**Medium Risk**:
- ⚠️ Undo system (snapshot-based may use memory for large docs)
- ⚠️ Performance with very long lines (string concatenation)

**Mitigations**:
- Limit undo stack to 20 levels
- Limit line length to 2000 chars (same as Read tool)
- Warn user if doc exceeds 1000 lines

---

**Conclusion**: Use SimpleTextEditor as base, add selective features from FullNotesEditor (undo, auto-save), integrate with PMC services.
