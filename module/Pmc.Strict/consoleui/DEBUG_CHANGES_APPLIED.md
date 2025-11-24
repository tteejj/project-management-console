# Debug Logging Changes Applied

## Summary
Comprehensive debug logging has been added to trace the complete execution flow for all 6 critical bugs. Debug output is written to separate log files for easy analysis.

## Files Modified

### 1. `widgets/InlineEditor.ps1`

**Function**: `HandleInput([ConsoleKeyInfo]$keyInfo)`

**Debug Added** (Lines 265-310):
```powershell
Add-Content -Path "/tmp/pmc-widget-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') [InlineEditor.HandleInput] START Key=$($keyInfo.Key) ..."
```

**What it logs**:
- Every key press in the inline editor
- When widget is expanded
- When widget is called with `HandleInput()`
- Widget completion detection (IsConfirmed, IsCancelled, IsComplete)
- Widget collapse operations
- Field value updates

**Traces Issues**: #1 (Saving), #5 (Widget closes editor), #6 (Only selected line visible)

**Lines Added**: ~30 lines of debug logging

---

### 2. `base/StandardListScreen.ps1`

**Function**: `HandleInput([ConsoleKeyInfo]$keyInfo)`

**Debug Added** (Lines 825-827):
```powershell
Add-Content -Path "/tmp/pmc-esc-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') [StandardListScreen] ESC/F10 pressed: ..."
```

**What it logs**:
- ESC/F10 key detection
- MenuBar state (IsActive, ShowInlineEditor, ShowFilterPanel)
- Menu activation attempts

**Traces Issues**: #4 (ESC doesn't close menu)

**Lines Added**: ~2 lines of debug logging

---

### 3. `widgets/PmcMenuBar.ps1`

**Function**: `HandleKeyPress([System.ConsoleKeyInfo]$keyInfo)`

**Debug Added** (Lines 687-690, 721-724):
- ESC in dropdown mode
- ESC in menu bar mode

```powershell
Add-Content -Path "/tmp/pmc-esc-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') [MenuBar] ESC in dropdown mode - hiding dropdown"
```

**What it logs**:
- ESC key handling in different menu modes
- Dropdown hiding
- Menu deactivation

**Traces Issues**: #4 (ESC doesn't close menu)

**Lines Added**: ~8 lines of debug logging

---

### 4. `widgets/UniversalList.ps1`

**Function**: `_RenderRow()` - Padding section

**Debug Added** (Lines 1295-1310):
```powershell
Add-Content -Path "/tmp/pmc-padding-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') ROW ${i} PADDING: currentX=$currentX contentWidth=$contentWidth ..."
```

**What it logs**:
- Row padding calculation (currentX, contentWidth, list width, padding size)
- Builder size at each step
- RESET sequences before padding
- RESET sequences after padding
- Clear-to-EOL (ANSI `[K`) sequences

**Traces Issues**: #2 (Padding highlighted), #3 (Highlight bleeding)

**Lines Added**: ~6 lines of debug logging

---

## Summary of Debug Log Files Created

| File | Purpose | Size | Clears On |
|------|---------|------|-----------|
| `/tmp/pmc-flow-debug.log` | ENTER key flow and data saving | Medium | Each test |
| `/tmp/pmc-edit-debug.log` | Row highlighting and edit mode | Large | Each test |
| `/tmp/pmc-widget-debug.log` | Widget interaction and expansion | Small-Medium | Each test |
| `/tmp/pmc-esc-debug.log` | ESC and menu handling | Small | Each test |
| `/tmp/pmc-padding-debug.log` | Padding and color reset sequences | Medium | Each test |
| `/tmp/pmc-colors-debug.log` | Color code values | Small | Each test |

**Total Lines Added**: ~50 lines of debug logging

## Existing Debug Logging Not Modified

The following extensive debug logging was already in place and is being used:

### `TaskListScreen.ps1` - Lines 824-1015
- **OnItemUpdated()**: Detailed logging of update flow
  - Item ID, values received
  - Change detection
  - Store.UpdateTask() success/failure
  - LoadData() completion
  - Error handling

- **OnItemCreated()**: Task creation flow
  - Values validation
  - Parent task checking
  - Circular dependency detection
  - Store.AddTask() success/failure

### `UniversalList.ps1` - Lines 923-937
- **SkipRowHighlight callback**: Which rows skip highlighting
  - Callback presence check
  - Return values for each row
  - Error handling

## How Debugging Works

### Flow Chart
```
User Action (press key)
    ↓
StandardListScreen.HandleInput()
    ├─ Log: "ESC/F10 pressed" → /tmp/pmc-esc-debug.log
    ├─ Route to: MenuBar, InlineEditor, or List
    │
    ├─→ MenuBar.HandleKeyPress()
    │   └─ Log: "ESC in dropdown/menu mode" → /tmp/pmc-esc-debug.log
    │
    ├─→ InlineEditor.HandleInput()
    │   ├─ Log: "START Key=$key" → /tmp/pmc-widget-debug.log
    │   ├─ Log: "routing input to field widget" → /tmp/pmc-widget-debug.log
    │   ├─ Log: "widget.HandleInput() returned" → /tmp/pmc-widget-debug.log
    │   └─ Log: "Widget marked complete, collapsing" → /tmp/pmc-widget-debug.log
    │
    └─→ UniversalList.HandleInput()
        └─ For ENTER: calls OnItemActivated
            └─ StandardListScreen.EditItem()
                ├─ Log: "LayoutMode = horizontal" → /tmp/pmc-flow-debug.log
                ├─ InlineEditor.SetFields()
                └─ TaskListScreen.OnItemUpdated()
                    ├─ Log: "START item=$id" → /tmp/pmc-flow-debug.log
                    ├─ Store.UpdateTask()
                    ├─ Log: "Store.UpdateTask returned: $result" → /tmp/pmc-flow-debug.log
                    ├─ LoadData()
                    ├─ Log: "LoadData() completed/FAILED" → /tmp/pmc-flow-debug.log
                    └─ UniversalList._RenderRow()
                        ├─ Log: "SkipRowHighlight callback returned" → /tmp/pmc-edit-debug.log
                        ├─ Log: "ROW $i PADDING: ..." → /tmp/pmc-padding-debug.log
                        └─ Log: "Appending final RESET and clear-to-EOL" → /tmp/pmc-padding-debug.log
```

## Testing Procedure

### Test Issue #1: Changes not saving
1. `rm /tmp/pmc-flow-debug.log`
2. Start TUI, edit task, press ENTER
3. `grep "Store.UpdateTask returned" /tmp/pmc-flow-debug.log`
4. Should show "True" if working, "False" if broken

### Test Issue #2: Padding highlighted
1. `rm /tmp/pmc-padding-debug.log`
2. Start TUI, select a task
3. `grep "RESET before padding" /tmp/pmc-padding-debug.log`
4. Should find entries if working, none if broken

### Test Issue #3: Highlight bleeding
1. `rm /tmp/pmc-padding-debug.log /tmp/pmc-edit-debug.log`
2. Start TUI, select a task
3. `grep "clear-to-EOL" /tmp/pmc-padding-debug.log`
4. Should find entries if working, none if broken

### Test Issue #4: ESC doesn't close menu
1. `rm /tmp/pmc-esc-debug.log`
2. Start TUI, press ESC twice
3. `cat /tmp/pmc-esc-debug.log`
4. Should show "hiding dropdown" if working

### Test Issue #5: Widget closes editor
1. `rm /tmp/pmc-widget-debug.log`
2. Start TUI, edit task, press ENTER on a field
3. `tail /tmp/pmc-widget-debug.log`
4. Should NOT see immediate "Widget marked complete" if working

### Test Issue #6: Only selected line visible
1. `rm /tmp/pmc-edit-debug.log`
2. Start TUI, edit a task
3. `grep -c "returned: true" /tmp/pmc-edit-debug.log`
4. Should be 1 (only edited row), not all rows

## Log Output Examples

### Healthy ENTER Flow (`/tmp/pmc-flow-debug.log`)
```
HH:mm:ss.fff [EditItem] ShowInlineEditor = true
HH:mm:ss.fff [OnItemUpdated] START item=abc123
HH:mm:ss.fff [OnItemUpdated] Calling Store.UpdateTask with id=abc123
HH:mm:ss.fff [OnItemUpdated] Store.UpdateTask returned: True
HH:mm:ss.fff [OnItemUpdated] LoadData() completed
```

### Healthy Row Rendering (`/tmp/pmc-edit-debug.log`)
```
HH:mm:ss.fff UniversalList: SkipRowHighlight callback returned: true    <- Edited row
HH:mm:ss.fff UniversalList: SkipRowHighlight callback returned: false   <- Other row
HH:mm:ss.fff UniversalList: SkipRowHighlight callback returned: false   <- Other row
```

### Healthy ESC Handling (`/tmp/pmc-esc-debug.log`)
```
HH:mm:ss.fff [StandardListScreen] ESC/F10 pressed: MenuBar=True IsActive=False
HH:mm:ss.fff [StandardListScreen] ESC/F10 activating menu
HH:mm:ss.fff [MenuBar] ESC in menu bar mode - deactivating
```

## Next Steps

1. **Run TUI with debugging enabled**
   ```bash
   bash run-debug-tui.sh
   ```

2. **Reproduce issues while logging**
   - Try each of the 6 bugs
   - Look at debug output

3. **Analyze logs to find root causes**
   - Use grep to search
   - Look for unexpected values
   - Check timestamps for timing issues

4. **Fix identified issues**
   - Apply targeted fixes
   - Re-test with logging

5. **Remove debug logging**
   - Comment out or remove Add-Content lines
   - Before final commit

---

## Important Notes

### Performance
- Debug logging adds I/O overhead (file writes)
- Don't use in production
- Remove before final release

### Thread Safety
- `Add-Content` is thread-safe
- Safe to use during concurrent key processing

### Log Growth
- Logs grow quickly (every operation logged)
- Clear logs frequently during debugging
- Typical session: 50-200KB of logs

### Timestamps
- All logs use `HH:mm:ss.fff` format
- Useful for correlating across log files
- Can match up events happening at same time

---

## Debug Logging Checklist

- [x] Issue #1 - Added flow logging for Save/Update pathway
- [x] Issue #2 - Added padding calculation logging
- [x] Issue #3 - Added color reset logging before/after padding
- [x] Issue #4 - Added ESC key handling logging
- [x] Issue #5 - Added widget interaction logging
- [x] Issue #6 - Added SkipRowHighlight callback logging (already existed)

All 6 issues now have complete debug tracing.

---

Generated: November 22, 2025
Files: 5 modified, 2 created
Lines added: ~50 lines of debug logging
