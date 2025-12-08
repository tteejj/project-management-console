# Comprehensive Debug Logging Summary

## Overview
This document describes all comprehensive debug logging added to trace the execution flow for all 6 critical bugs reported in the TUI.

## The 6 Critical Bugs
1. **Changes not saving** - Task edits not persisting to disk
2. **Padding being highlighted** - Row padding gets background color
3. **Highlight bleeding** - Selection highlight bleeds into next row
4. **ESC not escaping menu** - ESC key doesn't close menu properly
5. **Widget closes editor** - Clicking/pressing widget in edit mode closes editor
6. **Only selected line visible** - All other tasks disappear when editing

---

## Debug Log Files

### 1. `/tmp/pmc-flow-debug.log`
**Purpose**: Trace ENTER key press and complete edit flow

**Logged in**:
- `StandardListScreen.EditItem()` - Starting edit operation
- `StandardListScreen.OnItemActivated()` - ENTER key activation
- `StandardListScreen.RenderContent()` - Rendering with editor state
- `TaskListScreen.OnItemUpdated()` - Update callback execution
- `UniversalList.HandleInput()` - ENTER key handling in list

**Key Debug Points**:
- `[EditItem] ShowInlineEditor = true` - Editor opened
- `[EditItem] LayoutMode = horizontal` - Layout set before SetFields()
- `[OnItemUpdated] START item=$id` - Update started
- `[OnItemUpdated] Store.UpdateTask returned: $success` - Save result
- `[OnItemUpdated] LoadData() completed` - Data reloaded

**Traces Issue #1 (Changes not saving)**: Shows if Store.UpdateTask succeeds and LoadData completes

---

### 2. `/tmp/pmc-edit-debug.log`
**Purpose**: Trace edit mode rendering and row highlighting

**Logged in**:
- `UniversalList._RenderRow()` - Each row rendering
- `UniversalList.SkipRowHighlight` callback - Determining which rows skip highlight
- Row highlight color application
- Row padding and reset sequences

**Key Debug Points**:
- `UniversalList: Checking SkipRowHighlight for row $i` - Check callback
- `UniversalList: SkipRowHighlight callback returned: $skipRowHighlight` - Result
- `ROW $i HIGHLIGHT: isSelected=true, appending BG=... FG=...` - Highlight applied
- `SKIPPING row highlight, using edit mode colors` - Edit mode activated
- `ROW $i - After append, rowBuilder.Length=$len` - Track builder size

**Traces Issues #3, #6 (Highlight bleeding, Only selected line visible)**:
- Issue #3: Shows if highlight is properly reset at row end
- Issue #6: Shows SkipRowHighlight callback behavior for all rows

---

### 3. `/tmp/pmc-widget-debug.log`
**Purpose**: Trace widget interaction and editor state changes

**Logged in**:
- `InlineEditor.HandleInput()` - Every key pressed in editor
- Field widget expansion/collapse
- Widget completion detection
- Field value updates

**Key Debug Points**:
- `[InlineEditor.HandleInput] START Key=$key Expanded=$field ShowFieldWidgets=$show` - Input start
- `[InlineEditor.HandleInput] Widget is expanded, routing input to field widget` - Widget active
- `[InlineEditor.HandleInput] Calling widget.HandleInput()` - Input forwarded
- `[InlineEditor.HandleInput] widget.HandleInput() returned: $handled` - Widget result
- `[InlineEditor.HandleInput] Widget marked complete, collapsing` - Widget closed
- `[InlineEditor.HandleInput] Collapsing widget, setting _showFieldWidgets=false` - State reset

**Traces Issue #5 (Widget closes editor)**: Shows widget interaction flow and whether NeedsClear flag is set

---

### 4. `/tmp/pmc-esc-debug.log`
**Purpose**: Trace ESC key handling and menu activation/deactivation

**Logged in**:
- `StandardListScreen` - ESC/F10 key detection and menu activation
- `PmcMenuBar.HandleKeyPress()` - Menu ESC handling
- Menu activation and deactivation
- Dropdown visibility changes

**Key Debug Points**:
- `[StandardListScreen] ESC/F10 pressed: MenuBar=$exists IsActive=$active ShowEditor=$edit ShowFilter=$filter` - ESC detected
- `[StandardListScreen] ESC/F10 activating menu` - Menu activated
- `[MenuBar] ESC in dropdown mode - hiding dropdown` - Dropdown closed
- `[MenuBar] ESC in menu bar mode - deactivating` - Menu deactivated

**Traces Issue #4 (ESC not escaping menu)**: Shows complete ESC key flow through menu system

---

### 5. `/tmp/pmc-padding-debug.log`
**Purpose**: Trace row padding and final color reset sequences

**Logged in**:
- `UniversalList._RenderRow()` padding section
- Padding calculation
- Reset sequences before/after padding
- Clear-to-EOL (ANSI `[K`) sequence

**Key Debug Points**:
- `ROW ${i} PADDING: currentX=$x contentWidth=$w listWidth=$l padding=$p builderLen=$b` - Padding calc
- `ROW ${i} PADDING: Appending RESET before padding` - Reset before padding
- `ROW ${i} PADDING: After padding append, builderLen=$b` - After padding
- `ROW ${i}: Appending final RESET and clear-to-EOL, builderLen=$b` - Final reset

**Traces Issues #2, #3 (Padding highlighted, Highlight bleeding)**:
- Issue #2: Shows if padding has background color (no reset)
- Issue #3: Shows if clear-to-EOL is applied at row end

---

### 6. `/tmp/pmc-colors-debug.log`
**Purpose**: Trace color code application and theme values

**Logged in**:
- `UniversalList._RenderRow()` - Color code values
- Theme color retrieval
- Highlight background/foreground colors
- Normal text colors

**Key Debug Points**:
- `highlightBg='...' len=$len highlightFg='...' len=$len` - Color codes
- Shows actual ANSI escape sequences being used
- Helps verify colors are correctly formatted

**Traces Issues #2, #3 (Padding/Highlight issues)**: Shows color codes being applied

---

## How to Use These Debug Logs

### Running the TUI with Debug Logging

1. **Using the debug script**:
   ```bash
   bash run-debug-tui.sh
   ```
   This will:
   - Clear all debug logs
   - Start the TUI
   - Display all debug logs when you exit

2. **Manual testing**:
   - `rm -f /tmp/pmc-*-debug.log` - Clear logs
   - Start TUI normally
   - Perform the action you want to debug
   - Exit TUI
   - `tail -f /tmp/pmc-*-debug.log` - View logs

### Debugging Each Issue

**Issue #1 (Changes not saving)**:
1. Clear logs: `rm -f /tmp/pmc-flow-debug.log`
2. Start TUI, edit a task, press ENTER
3. Check `/tmp/pmc-flow-debug.log`:
   - Look for `Store.UpdateTask returned: True/False`
   - Look for `LoadData() completed` vs `LoadData() FAILED`
   - If False or FAILED, data isn't saving

**Issue #2 (Padding highlighted)**:
1. Clear logs: `rm -f /tmp/pmc-padding-debug.log /tmp/pmc-edit-debug.log`
2. Start TUI, edit a task
3. Check `/tmp/pmc-padding-debug.log`:
   - Look for `Appending RESET before padding`
   - If missing, padding will have background
   - Check `clear-to-EOL` is being appended

**Issue #3 (Highlight bleeding)**:
1. Clear logs: `rm -f /tmp/pmc-padding-debug.log /tmp/pmc-edit-debug.log`
2. Start TUI, select a task (don't edit yet)
3. Check logs for highlight colors at row end
4. Then edit task and check if next row is affected

**Issue #4 (ESC not escaping menu)**:
1. Clear logs: `rm -f /tmp/pmc-esc-debug.log`
2. Start TUI, press ESC to open menu
3. Press ESC again to close menu
4. Check `/tmp/pmc-esc-debug.log`:
   - Should see "ESC pressed" entries
   - Should see "hiding dropdown" or "deactivating"

**Issue #5 (Widget closes editor)**:
1. Clear logs: `rm -f /tmp/pmc-widget-debug.log /tmp/pmc-flow-debug.log`
2. Start TUI, edit a task
3. Press ENTER on a date/project field to expand widget
4. Press a key in the widget
5. Check `/tmp/pmc-widget-debug.log`:
   - Should see "routing input to field widget"
   - Should NOT immediately see "collapsing widget"
   - Check if NeedsClear is set correctly

**Issue #6 (Only selected line visible)**:
1. Clear logs: `rm -f /tmp/pmc-edit-debug.log`
2. Start TUI, edit a task
3. Check `/tmp/pmc-edit-debug.log`:
   - Look for `SkipRowHighlight callback returned` for EACH row
   - Should only be true for edited row
   - Should be false for all other rows
   - If all false or all true, that's the problem

---

## Debug Logging Architecture

### Flow
```
User presses key
  ↓
StandardListScreen.HandleInput()
  ↓ [Debug: ESC/F10 detection]
MenuBar.HandleKeyPress() OR InlineEditor.HandleInput() OR UniversalList.HandleInput()
  ↓ [Debug: Key routing]
Specific handler (EditItem, OnItemActivated, etc.)
  ↓ [Debug: Operation execution]
Render phase
  ↓ [Debug: Padding, highlighting, colors]
Output to screen
```

### Log Correlation
- All logs use timestamp format: `HH:mm:ss.fff`
- Cross-reference timestamps across logs to see complete flow
- Look for gaps (missing logs) to find bottlenecks

---

## Important Notes

1. **Log files grow quickly** - They log EVERY operation, including renders
   - For long TUI sessions, log files can get large
   - Clear logs frequently during debugging

2. **Performance impact** - Debug logging adds I/O overhead
   - Don't use in production
   - Disable by commenting out `Add-Content` lines if needed

3. **Thread safety** - All logs use `Add-Content` which is thread-safe
   - Safe to run with multiple key presses

4. **Log rotation** - Consider clearing logs before major test scenarios
   - Keeps logs focused on specific issue

---

## Next Steps

1. **Run TUI with comprehensive logging**
2. **Reproduce each bug while logging**
3. **Analyze logs to identify root cause**
4. **Fix root cause**
5. **Verify fix with logs**
6. **Disable/remove debug logging before final commit**

---

Generated: November 22, 2025
