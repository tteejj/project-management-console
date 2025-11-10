# FullNotesEditor - Detailed Analysis & Enhancement Plan

**Date**: 2025-11-10
**Source**: `/home/teej/_tui/praxis-main/simpletaskpro/Core/FullNotesEditor.ps1`
**Purpose**: Port FullNotesEditor to PMC ConsoleUI with enhancements

---

## Executive Summary

**FullNotesEditor** is a production-ready, feature-rich multiline text editor with:
- Gap buffer for efficient editing
- 100-level undo/redo
- Auto-save and crash recovery
- Word navigation (Ctrl+Left/Right)
- Selection support (partial implementation)

**Dependencies** (all portable, no complexity):
1. **GapBuffer** - 331 lines, pure PowerShell, no dependencies
2. **UniversalBackupManager** - 245 lines, optional (can simplify)
3. **VT** - 162 lines, ANSI/VT100 escape sequences (PMC already has similar)

**Assessment**: Dependencies are **simple and portable**. Not complex at all.

---

## Dependency Analysis

### 1. GapBuffer.ps1 (331 lines)

**Purpose**: Efficient text storage optimized for insertions/deletions at cursor position

#### How Gap Buffer Works
```
Text: "Hello World"
Cursor after "Hello"

Memory layout:
[H][e][l][l][o][_][_][_][_][_][W][o][r][l][d]
              ↑                ↑
          gap start        gap end
```

When you type at cursor: characters fill the gap (O(1) operation)
When you move cursor: gap moves to new position (O(n) operation, but amortized O(1))

**Key Features**:
- ✅ `Insert(position, text)` - O(1) at cursor, O(n) elsewhere
- ✅ `Delete(position, count)` - O(1) deletion
- ✅ `GetChar(position)` - O(1) character access
- ✅ `GetText(start, count)` - Extract substring
- ✅ Auto-grow buffer when gap fills up
- ✅ Statistics tracking (debugging)

**No External Dependencies**: Pure PowerShell, uses only `[char[]]` and `[array]::Copy()`

**Port Difficulty**: ⭐ Easy - just copy the file
**Lines**: 331

---

### 2. UniversalBackupManager.ps1 (245 lines)

**Purpose**: Bulletproof auto-save and backup system

#### Key Features
- ✅ **Atomic saves**: Write to `.tmp`, then rename (never corrupt files)
- ✅ **Auto-save on exit**: Registers PowerShell exit handlers
- ✅ **Backup versioning**: Keep N versions of backups
- ✅ **Hash validation**: Verify backup integrity (SHA256)
- ✅ **Crash recovery**: Auto-save before PowerShell exits
- ✅ **Multiple data types**: tasks, notes, settings, etc.

**External Dependencies**: None - uses only PowerShell built-ins

**Simplification Options**:
1. **Option A**: Port entire system (245 lines) - full features
2. **Option B**: Extract only `AtomicSave()` method (~50 lines) - minimal
3. **Option C**: Use PMC's existing Storage.ps1 (already has atomic save patterns)

**Recommendation**: **Option C** - PMC already has `../src/Storage.ps1` with similar patterns. Just add auto-save registration.

**Port Difficulty**: ⭐⭐ Moderate - or skip if using existing PMC Storage
**Lines**: 245 (or ~50 for minimal version)

---

### 3. VT.ps1 (162 lines)

**Purpose**: ANSI/VT100 escape sequences for terminal control

#### Key Features
- ✅ Cursor movement: `MoveTo(x, y)`, `MoveUp/Down/Left/Right(n)`
- ✅ Cursor visibility: `Show()`, `Hide()`
- ✅ Colors: `RGB(r,g,b)`, `RGBBG(r,g,b)` (24-bit true color)
- ✅ Styles: `Bold()`, `Italic()`, `Underline()`, `Reset()`
- ✅ Screen: `Clear()`, `ClearLine()`, `ClearToEnd()`
- ✅ Box drawing: `TL()`, `TR()`, `H()`, `V()` (Unicode box chars)
- ✅ Gradients: `VerticalGradient()`, `HorizontalGradient()`

**External Dependencies**: None

**PMC ConsoleUI Already Has**: Similar VT100 functionality
- Check: Does PMC have a VT or ANSI class?
- If yes: Use existing
- If no: Port this file (162 lines, simple)

**Port Difficulty**: ⭐ Trivial - PMC likely already has this
**Lines**: 162 (or use PMC's existing implementation)

---

## FullNotesEditor Feature Breakdown

### Current Features (What It Has)

| Feature | Status | Implementation |
|---------|--------|----------------|
| **Text Storage** | ✅ Complete | GapBuffer with line indexing |
| **Cursor Movement** | ✅ Complete | Arrow keys, Home/End, PgUp/PgDn |
| **Word Navigation** | ✅ Complete | Ctrl+Left/Right (word boundaries) |
| **Text Editing** | ✅ Complete | Insert, Delete, Backspace, Enter, Tab |
| **Undo/Redo** | ✅ Complete | 100-level snapshot stack |
| **Scrolling** | ✅ Complete | Horizontal + Vertical |
| **Auto-save** | ✅ Complete | On focus loss, on exit |
| **Crash Recovery** | ✅ Complete | UniversalBackupManager integration |
| **Selection** | ⚠️ Partial | Structure exists, rendering stubbed |
| **Copy/Paste** | ❌ Missing | Not implemented |
| **Cut** | ❌ Missing | Not implemented |
| **Find/Replace** | ❌ Missing | Not implemented |
| **Block Select** | ❌ Missing | Not implemented |

### Missing Features (What Needs to Be Added)

#### 1. Block Selection (Rectangular Selection)
**Current**: Only line-based selection (partial)
**Needed**: Rectangular/column selection (like Vim visual block mode)

**Implementation**:
```powershell
# Selection modes
enum SelectionMode {
    None
    Stream      # Normal selection (character-based)
    Line        # Line-based selection
    Block       # Rectangular/column selection
}

[SelectionMode]$SelectionMode = [SelectionMode]::None
[int]$SelectionAnchorX = 0  # Where selection started
[int]$SelectionAnchorY = 0
[int]$SelectionEndX = 0     # Where selection ends
[int]$SelectionEndY = 0

# Start selection
[void] StartSelection([SelectionMode]$mode) {
    $this.SelectionMode = $mode
    $this.SelectionAnchorX = $this.CursorX
    $this.SelectionAnchorY = $this.CursorY
    $this.SelectionEndX = $this.CursorX
    $this.SelectionEndY = $this.CursorY
}

# Extend selection (as cursor moves)
[void] ExtendSelection() {
    if ($this.SelectionMode -ne [SelectionMode]::None) {
        $this.SelectionEndX = $this.CursorX
        $this.SelectionEndY = $this.CursorY
    }
}

# Get selected text (stream mode)
[string] GetSelectedText() {
    if ($this.SelectionMode -eq [SelectionMode]::None) {
        return ""
    }

    $startLine = [Math]::Min($this.SelectionAnchorY, $this.SelectionEndY)
    $endLine = [Math]::Max($this.SelectionAnchorY, $this.SelectionEndY)
    $startCol = [Math]::Min($this.SelectionAnchorX, $this.SelectionEndX)
    $endCol = [Math]::Max($this.SelectionAnchorX, $this.SelectionEndX)

    if ($this.SelectionMode -eq [SelectionMode]::Stream) {
        # Stream selection (normal)
        $text = ""
        for ($line = $startLine; $line -le $endLine; $line++) {
            $lineText = $this.GetLine($line)
            if ($line -eq $startLine -and $line -eq $endLine) {
                # Single line
                $text += $lineText.Substring($startCol, $endCol - $startCol)
            } elseif ($line -eq $startLine) {
                # First line
                $text += $lineText.Substring($startCol) + "`n"
            } elseif ($line -eq $endLine) {
                # Last line
                $text += $lineText.Substring(0, $endCol)
            } else {
                # Middle lines
                $text += $lineText + "`n"
            }
        }
        return $text
    }
    elseif ($this.SelectionMode -eq [SelectionMode]::Block) {
        # Block selection (rectangular)
        $lines = @()
        for ($line = $startLine; $line -le $endLine; $line++) {
            $lineText = $this.GetLine($line)
            if ($startCol -lt $lineText.Length) {
                $extractEnd = [Math]::Min($endCol, $lineText.Length)
                $lines += $lineText.Substring($startCol, $extractEnd - $startCol)
            } else {
                $lines += ""
            }
        }
        return $lines -join "`n"
    }

    return ""
}

# Delete selected text
[void] DeleteSelection() {
    if ($this.SelectionMode -eq [SelectionMode]::None) {
        return
    }

    # Get selection bounds
    $startLine = [Math]::Min($this.SelectionAnchorY, $this.SelectionEndY)
    $endLine = [Math]::Max($this.SelectionAnchorY, $this.SelectionEndY)
    $startCol = [Math]::Min($this.SelectionAnchorX, $this.SelectionEndX)
    $endCol = [Math]::Max($this.SelectionAnchorX, $this.SelectionEndX)

    if ($this.SelectionMode -eq [SelectionMode]::Stream) {
        # Delete stream selection
        # Calculate buffer positions and delete range
        $startPos = $this.GetPositionFromLineCol($startLine, $startCol)
        $endPos = $this.GetPositionFromLineCol($endLine, $endCol)
        $this._gapBuffer.Delete($startPos, $endPos - $startPos)
        $this._lineIndexDirty = $true

        # Move cursor to start of deleted region
        $this.CursorY = $startLine
        $this.CursorX = $startCol
    }
    elseif ($this.SelectionMode -eq [SelectionMode]::Block) {
        # Delete block selection (delete from each line)
        for ($line = $endLine; $line -ge $startLine; $line--) {
            $lineText = $this.GetLine($line)
            if ($startCol -lt $lineText.Length) {
                $deleteCount = [Math]::Min($endCol - $startCol, $lineText.Length - $startCol)
                $pos = $this.GetPositionFromLineCol($line, $startCol)
                $this._gapBuffer.Delete($pos, $deleteCount)
            }
        }
        $this._lineIndexDirty = $true

        # Move cursor to top-left of block
        $this.CursorY = $startLine
        $this.CursorX = $startCol
    }

    $this.ClearSelection()
    $this.Modified = $true
}
```

**Keyboard Shortcuts**:
- `Shift+Arrow`: Stream selection
- `Ctrl+Shift+Arrow`: Block selection
- `Escape`: Clear selection

---

#### 2. Copy/Paste

**Implementation**:
```powershell
[void] Copy() {
    $selectedText = $this.GetSelectedText()
    if (-not [string]::IsNullOrEmpty($selectedText)) {
        Set-Clipboard -Value $selectedText
    }
}

[void] Cut() {
    $selectedText = $this.GetSelectedText()
    if (-not [string]::IsNullOrEmpty($selectedText)) {
        Set-Clipboard -Value $selectedText
        $this.DeleteSelection()
    }
}

[void] Paste() {
    try {
        $clipboardText = Get-Clipboard -Raw
        if (-not [string]::IsNullOrEmpty($clipboardText)) {
            # If there's a selection, delete it first
            if ($this.SelectionMode -ne [SelectionMode]::None) {
                $this.DeleteSelection()
            }

            # Insert clipboard text at cursor
            $position = $this.GetPositionFromLineCol($this.CursorY, $this.CursorX)
            $this._gapBuffer.Insert($position, $clipboardText)
            $this._lineIndexDirty = $true
            $this.Modified = $true

            # Move cursor to end of pasted text
            # (Calculate new position based on pasted text)
            $lines = $clipboardText -split "`n"
            if ($lines.Count -gt 1) {
                $this.CursorY += $lines.Count - 1
                $this.CursorX = $lines[-1].Length
            } else {
                $this.CursorX += $clipboardText.Length
            }

            $this.EnsureCursorVisible()
        }
    } catch {
        # Clipboard access may fail - ignore
    }
}
```

**Keyboard Shortcuts**:
- `Ctrl+C`: Copy
- `Ctrl+X`: Cut
- `Ctrl+V`: Paste

---

#### 3. Find/Replace

**Implementation**:
```powershell
# Find state
[string]$FindText = ""
[int]$FindIndex = 0  # Current match index
[bool]$FindCaseSensitive = $false

[int] FindNext([string]$searchText, [bool]$caseSensitive = $false) {
    $this.FindText = $searchText
    $this.FindCaseSensitive = $caseSensitive

    # Start searching from current cursor position
    $startPos = $this.GetPositionFromLineCol($this.CursorY, $this.CursorX) + 1
    $bufferText = $this._gapBuffer.GetText()

    $comparison = if ($caseSensitive) {
        [StringComparison]::Ordinal
    } else {
        [StringComparison]::OrdinalIgnoreCase
    }

    $foundIndex = $bufferText.IndexOf($searchText, $startPos, $comparison)

    if ($foundIndex -ge 0) {
        # Convert buffer position to line/col
        $lineCol = $this.GetLineColFromPosition($foundIndex)
        $this.CursorY = $lineCol.Line
        $this.CursorX = $lineCol.Col

        # Select the found text
        $this.StartSelection([SelectionMode]::Stream)
        $this.SelectionEndX = $this.CursorX + $searchText.Length
        $this.SelectionEndY = $this.CursorY

        $this.EnsureCursorVisible()
        return $foundIndex
    }

    return -1  # Not found
}

[void] ReplaceSelection([string]$replacementText) {
    if ($this.SelectionMode -ne [SelectionMode]::None) {
        $this.DeleteSelection()
        $position = $this.GetPositionFromLineCol($this.CursorY, $this.CursorX)
        $this._gapBuffer.Insert($position, $replacementText)
        $this._lineIndexDirty = $true
        $this.Modified = $true
    }
}

[int] ReplaceAll([string]$searchText, [string]$replacementText, [bool]$caseSensitive = $false) {
    $count = 0

    while ($true) {
        # Move cursor to start
        $this.CursorY = 0
        $this.CursorX = 0

        $foundIndex = $this.FindNext($searchText, $caseSensitive)
        if ($foundIndex -lt 0) {
            break  # No more matches
        }

        $this.ReplaceSelection($replacementText)
        $count++

        # Move cursor past replacement to avoid infinite loop
        $this.CursorX += $replacementText.Length
    }

    return $count
}

# Helper: Convert buffer position to line/col
hidden [hashtable] GetLineColFromPosition([int]$position) {
    if ($this._lineIndexDirty) {
        $this.BuildLineIndex()
    }

    for ($line = 0; $line -lt $this._lineStarts.Count; $line++) {
        $lineStart = $this._lineStarts[$line]
        $lineEnd = if ($line + 1 -lt $this._lineStarts.Count) {
            $this._lineStarts[$line + 1]
        } else {
            $this._gapBuffer.GetLength()
        }

        if ($position -ge $lineStart -and $position -lt $lineEnd) {
            return @{
                Line = $line
                Col = $position - $lineStart
            }
        }
    }

    return @{ Line = 0; Col = 0 }
}
```

**UI Integration**:
Create `FindReplaceDialog` screen:
```
┌─ Find & Replace ─────────────────────────────────────┐
│ Find:    [search text_______________________]        │
│ Replace: [replacement text__________________]        │
│                                                       │
│ [ ] Case sensitive                                   │
│                                                       │
│ [Find Next] [Replace] [Replace All]                  │
└──────────────────────────────────────────────────────┘
  Ctrl+F: Find Next | Ctrl+H: Replace | Esc: Cancel
```

**Keyboard Shortcuts**:
- `Ctrl+F`: Open find dialog / find next
- `Ctrl+H`: Open find/replace dialog
- `F3`: Find next
- `Shift+F3`: Find previous

---

#### 4. Enhanced Selection Rendering

**Current Issue**: `RenderLineWithSelection()` is stubbed (just shows text)

**Enhanced Implementation**:
```powershell
[void] RenderLineWithSelection([System.Text.StringBuilder]$sb, [string]$text, [int]$lineIndex) {
    if ($this.SelectionMode -eq [SelectionMode]::None) {
        [void]$sb.Append($text)
        return
    }

    $startLine = [Math]::Min($this.SelectionAnchorY, $this.SelectionEndY)
    $endLine = [Math]::Max($this.SelectionAnchorY, $this.SelectionEndY)
    $startCol = [Math]::Min($this.SelectionAnchorX, $this.SelectionEndX)
    $endCol = [Math]::Max($this.SelectionAnchorX, $this.SelectionEndX)

    # Check if this line is in selection range
    if ($lineIndex -lt $startLine -or $lineIndex -gt $endLine) {
        # Line not selected
        [void]$sb.Append($text)
        return
    }

    if ($this.SelectionMode -eq [SelectionMode]::Stream) {
        # Stream selection rendering
        if ($lineIndex -eq $startLine -and $lineIndex -eq $endLine) {
            # Single line selection
            $before = $text.Substring(0, [Math]::Min($startCol, $text.Length))
            $selected = if ($startCol -lt $text.Length) {
                $text.Substring($startCol, [Math]::Min($endCol - $startCol, $text.Length - $startCol))
            } else { "" }
            $after = if ($endCol -lt $text.Length) {
                $text.Substring($endCol)
            } else { "" }

            [void]$sb.Append($before)
            [void]$sb.Append([VT]::RGBBG(100, 150, 200))  # Selection background
            [void]$sb.Append($selected)
            [void]$sb.Append([VT]::Reset())
            [void]$sb.Append($after)
        }
        elseif ($lineIndex -eq $startLine) {
            # First line of multi-line selection
            $before = $text.Substring(0, [Math]::Min($startCol, $text.Length))
            $selected = if ($startCol -lt $text.Length) {
                $text.Substring($startCol)
            } else { "" }

            [void]$sb.Append($before)
            [void]$sb.Append([VT]::RGBBG(100, 150, 200))
            [void]$sb.Append($selected)
            [void]$sb.Append([VT]::Reset())
        }
        elseif ($lineIndex -eq $endLine) {
            # Last line of multi-line selection
            $selected = if ($endCol -gt 0) {
                $text.Substring(0, [Math]::Min($endCol, $text.Length))
            } else { "" }
            $after = if ($endCol -lt $text.Length) {
                $text.Substring($endCol)
            } else { "" }

            [void]$sb.Append([VT]::RGBBG(100, 150, 200))
            [void]$sb.Append($selected)
            [void]$sb.Append([VT]::Reset())
            [void]$sb.Append($after)
        }
        else {
            # Middle line (fully selected)
            [void]$sb.Append([VT]::RGBBG(100, 150, 200))
            [void]$sb.Append($text)
            [void]$sb.Append([VT]::Reset())
        }
    }
    elseif ($this.SelectionMode -eq [SelectionMode]::Block) {
        # Block selection rendering
        $before = if ($startCol -gt 0) {
            $text.Substring(0, [Math]::Min($startCol, $text.Length))
        } else { "" }

        $selected = if ($startCol -lt $text.Length) {
            $extractEnd = [Math]::Min($endCol, $text.Length)
            $text.Substring($startCol, $extractEnd - $startCol)
        } else { "" }

        $after = if ($endCol -lt $text.Length) {
            $text.Substring($endCol)
        } else { "" }

        [void]$sb.Append($before)
        [void]$sb.Append([VT]::RGBBG(100, 150, 200))
        [void]$sb.Append($selected)
        [void]$sb.Append([VT]::Reset())
        [void]$sb.Append($after)
    }
}
```

**Visual Appearance**:
```
Normal text here [SELECTED TEXT] more normal text
                  ^^^^^^^^^^^^
                  Blue background
```

---

## Complete Feature Comparison

| Feature | Current FullNotesEditor | Enhanced Version | Complexity |
|---------|-------------------------|------------------|------------|
| Gap Buffer | ✅ | ✅ | Low (copy file) |
| Line Indexing | ✅ | ✅ | Low (copy file) |
| Cursor Movement | ✅ | ✅ | Low (copy file) |
| Word Navigation | ✅ | ✅ | Low (copy file) |
| Undo/Redo | ✅ 100 levels | ✅ 100 levels | Low (copy file) |
| Auto-save | ✅ | ✅ | Low (adapt to PMC) |
| Scrolling | ✅ | ✅ | Low (copy file) |
| **Stream Selection** | ⚠️ Partial | ✅ **Complete** | Medium (+150 lines) |
| **Block Selection** | ❌ | ✅ **NEW** | Medium (+150 lines) |
| **Copy** | ❌ | ✅ **NEW** | Low (+10 lines) |
| **Cut** | ❌ | ✅ **NEW** | Low (+15 lines) |
| **Paste** | ❌ | ✅ **NEW** | Medium (+30 lines) |
| **Find** | ❌ | ✅ **NEW** | Medium (+80 lines) |
| **Replace** | ❌ | ✅ **NEW** | Medium (+50 lines) |
| **Find/Replace UI** | ❌ | ✅ **NEW** | Medium (+100 lines) |

**Total New Code**: ~535 lines for all enhancements

---

## Port Plan for PMC ConsoleUI

### Phase 1: Core Dependencies (1-2 hours)
1. ✅ Copy `GapBuffer.ps1` to `widgets/` or `helpers/` (331 lines)
2. ✅ Check if PMC has VT100 class
   - If no: Copy `VT.ps1` to `helpers/` (162 lines)
   - If yes: Adapt FullNotesEditor to use PMC's VT class
3. ✅ Backup system:
   - Option A: Copy UniversalBackupManager (245 lines)
   - Option B: Adapt to use PMC's `../src/Storage.ps1`
   - **Recommendation**: Option B

### Phase 2: Core Editor (2-3 hours)
1. ✅ Copy `FullNotesEditor.ps1` to `widgets/TextAreaEditor.ps1`
2. ✅ Rename class to `TextAreaEditor`
3. ✅ Adapt to extend `PmcWidget` instead of standalone
4. ✅ Replace VT calls with PMC's rendering system (if different)
5. ✅ Replace backup calls with PMC's storage system
6. ✅ Test basic editing (insert, delete, cursor movement)

### Phase 3: Selection Enhancements (2-3 hours)
1. ✅ Implement stream selection (`Shift+Arrow`)
2. ✅ Implement block selection (`Ctrl+Shift+Arrow`)
3. ✅ Enhance `RenderLineWithSelection()` (visual highlighting)
4. ✅ Test selection rendering

### Phase 4: Copy/Paste (1 hour)
1. ✅ Implement `Copy()` (Ctrl+C)
2. ✅ Implement `Cut()` (Ctrl+X)
3. ✅ Implement `Paste()` (Ctrl+V)
4. ✅ Test clipboard integration

### Phase 5: Find/Replace (2-3 hours)
1. ✅ Implement `FindNext()`, `FindPrevious()`
2. ✅ Implement `ReplaceSelection()`, `ReplaceAll()`
3. ✅ Create `FindReplaceDialog` screen
4. ✅ Wire up Ctrl+F, Ctrl+H shortcuts
5. ✅ Test find/replace

### Phase 6: Integration (2-3 hours)
1. ✅ Create `NoteEditorScreen` wrapper
2. ✅ Create `NoteService` (file I/O)
3. ✅ Integrate with `ProjectInfoScreen`
4. ✅ Create `NotesMenuScreen`
5. ✅ Test end-to-end workflow

**Total Estimate**: 10-15 hours for complete implementation with all enhancements

---

## File Structure

```
consoleui/
  helpers/
    GapBuffer.ps1              # 331 lines (dependency)
    VT100.ps1                  # 162 lines (or use existing)

  widgets/
    TextAreaEditor.ps1         # ~700 lines (FullNotesEditor + enhancements)
    FindReplaceDialog.ps1      # ~150 lines (find/replace UI)

  screens/
    NoteEditorScreen.ps1       # ~200 lines (wrapper + breadcrumb)
    NotesMenuScreen.ps1        # ~150 lines (list notes)

  services/
    NoteService.ps1            # ~250 lines (CRUD + file I/O)

  Total: ~1,943 lines for complete notes system
```

---

## Risk Assessment

**Low Risk**:
- ✅ Gap buffer is proven, production-tested
- ✅ Code is clean, well-structured
- ✅ No complex external dependencies
- ✅ All PowerShell built-ins

**Medium Risk**:
- ⚠️ Clipboard integration (`Get-Clipboard`, `Set-Clipboard`)
  - May not work in all terminals
  - **Mitigation**: Graceful fallback if clipboard fails
- ⚠️ Performance with very large files (>10K lines)
  - Gap buffer helps, but line indexing may slow down
  - **Mitigation**: Warn user if file exceeds 5K lines

**Testing Checklist**:
- [ ] Basic editing (type, delete, backspace)
- [ ] Cursor movement (arrows, home/end, page up/down)
- [ ] Word navigation (Ctrl+arrows)
- [ ] Undo/redo (Ctrl+Z, Ctrl+Y)
- [ ] Stream selection (Shift+arrows)
- [ ] Block selection (Ctrl+Shift+arrows)
- [ ] Copy/paste (Ctrl+C/V)
- [ ] Cut (Ctrl+X)
- [ ] Find (Ctrl+F)
- [ ] Replace (Ctrl+H)
- [ ] Replace all
- [ ] Auto-save on exit
- [ ] File load/save
- [ ] Large file (1000 lines)

---

## Keyboard Shortcuts (Complete List)

### Navigation
- `↑↓←→`: Move cursor
- `Ctrl+←→`: Word navigation
- `Home`: Start of line
- `End`: End of line
- `Ctrl+Home`: Start of document
- `Ctrl+End`: End of document
- `PgUp`/`PgDn`: Page up/down

### Editing
- `Enter`: New line
- `Backspace`: Delete before cursor
- `Delete`: Delete at cursor
- `Tab`: Insert spaces (4 spaces)

### Selection
- `Shift+Arrows`: Stream selection
- `Ctrl+Shift+Arrows`: Block selection (rectangular)
- `Ctrl+A`: Select all
- `Esc`: Clear selection

### Clipboard
- `Ctrl+C`: Copy
- `Ctrl+X`: Cut
- `Ctrl+V`: Paste

### Undo/Redo
- `Ctrl+Z`: Undo
- `Ctrl+Y`: Redo

### Find/Replace
- `Ctrl+F`: Find
- `Ctrl+H`: Replace
- `F3`: Find next
- `Shift+F3`: Find previous

### File
- `Ctrl+S`: Save
- `Esc`: Exit (with save prompt if modified)

---

## Next Steps

1. ✅ Review this analysis
2. ⏳ Decide on backup system approach (UniversalBackupManager vs PMC Storage)
3. ⏳ Check if PMC has VT100 class
4. ⏳ Begin Phase 1: Port dependencies
5. ⏳ Begin Phase 2: Port core editor
6. ⏳ Implement enhancements (selection, copy/paste, find/replace)

---

**Conclusion**: FullNotesEditor is an excellent foundation. Dependencies are simple and portable. With enhancements (block select, copy/paste, find/replace), this will be a professional-grade text editor suitable for notes, checklists, and any multiline text editing needs in PMC ConsoleUI.
