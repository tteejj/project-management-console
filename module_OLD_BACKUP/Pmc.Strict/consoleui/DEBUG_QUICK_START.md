# Debug Quick Start Guide

## The 6 Issues Being Debugged

1. ✅ **Changes not saving** → `/tmp/pmc-flow-debug.log`
2. ✅ **Padding highlighted** → `/tmp/pmc-padding-debug.log`
3. ✅ **Highlight bleeding** → `/tmp/pmc-padding-debug.log` + `/tmp/pmc-edit-debug.log`
4. ✅ **ESC doesn't close menu** → `/tmp/pmc-esc-debug.log`
5. ✅ **Widget closes editor** → `/tmp/pmc-widget-debug.log`
6. ✅ **Only selected line visible** → `/tmp/pmc-edit-debug.log`

## Fastest Way to Debug

### Option 1: Use the debug script
```bash
cd /home/teej/pmc/module/Pmc.Strict/consoleui
bash run-debug-tui.sh
```
This automatically:
- Clears logs
- Starts TUI
- Displays all logs on exit

### Option 2: Manual (more control)
```bash
# Clear logs
rm -f /tmp/pmc-*-debug.log

# Start TUI
pwsh
. ./Start-PmcTUI.ps1

# Exit TUI when done

# View specific log
tail /tmp/pmc-flow-debug.log
```

## What Each Log Contains

| Log File | What It Shows | For Issue |
|----------|--------------|-----------|
| `/tmp/pmc-flow-debug.log` | ENTER key → Save → Reload | #1 (Saving) |
| `/tmp/pmc-padding-debug.log` | Row padding calculation & color reset | #2, #3 (Padding/Bleeding) |
| `/tmp/pmc-edit-debug.log` | Row highlighting in edit mode | #3, #6 (Bleeding/Visible) |
| `/tmp/pmc-esc-debug.log` | ESC key flow through menus | #4 (Menu ESC) |
| `/tmp/pmc-widget-debug.log` | Field widget interaction | #5 (Widget closes editor) |
| `/tmp/pmc-colors-debug.log` | Color codes applied | #2, #3 (Visual issues) |

## Debugging Each Issue in 30 Seconds

### Issue #1: Changes not saving
```bash
rm /tmp/pmc-flow-debug.log
# Edit a task, press ENTER
grep "Store.UpdateTask returned" /tmp/pmc-flow-debug.log
# If "True" and LoadData succeeds → working
# If "False" or LoadData fails → not working
```

### Issue #2: Padding highlighted
```bash
rm /tmp/pmc-padding-debug.log
# Start TUI, select a task to see highlight
grep "RESET before padding" /tmp/pmc-padding-debug.log
# If FOUND → padding should be normal
# If NOT FOUND → padding will be highlighted
```

### Issue #3: Highlight bleeding
```bash
rm /tmp/pmc-padding-debug.log
# Select a task to see highlight
grep "clear-to-EOL" /tmp/pmc-padding-debug.log
# If FOUND → bleeding should be prevented
# If NOT FOUND → highlight will bleed to next row
```

### Issue #4: ESC doesn't close menu
```bash
rm /tmp/pmc-esc-debug.log
# Press ESC to open menu, press ESC to close
tail /tmp/pmc-esc-debug.log
# Should see "hiding dropdown" or "deactivating"
# If not → ESC not working
```

### Issue #5: Widget closes editor
```bash
rm /tmp/pmc-widget-debug.log
# Edit task, press ENTER on a field to expand it
# Type something in the widget
tail /tmp/pmc-widget-debug.log
# Should NOT see "Widget marked complete, collapsing"
# If you do → widget is closing prematurely
```

### Issue #6: Only selected line visible
```bash
rm /tmp/pmc-edit-debug.log
# Edit a task and look at screen
grep "SkipRowHighlight callback returned" /tmp/pmc-edit-debug.log
# Count how many "true" vs "false" you see
# Should be: 1 true (edited row), rest false (other rows)
# If all true or all false → that's the problem
```

## Log Output Examples

### Healthy `/tmp/pmc-flow-debug.log`
```
11:22:33.456 [EditItem] ShowInlineEditor = true
11:22:34.123 [OnItemUpdated] START item=12345
11:22:34.456 [OnItemUpdated] Store.UpdateTask returned: True
11:22:34.789 [OnItemUpdated] LoadData() completed
```

### Healthy `/tmp/pmc-edit-debug.log`
```
11:22:35.100 UniversalList: SkipRowHighlight callback returned: true   <- Edited row
11:22:35.101 UniversalList: SkipRowHighlight callback returned: false  <- Other row
11:22:35.102 UniversalList: SkipRowHighlight callback returned: false  <- Other row
```

### Healthy `/tmp/pmc-esc-debug.log`
```
11:22:36.100 [StandardListScreen] ESC/F10 activating menu
11:22:37.200 [MenuBar] ESC in dropdown mode - hiding dropdown
```

## Understanding Debug Output

All logs use format: `HH:mm:ss.fff [COMPONENT] Message`

Example: `11:22:33.456 [InlineEditor.HandleInput] Widget marked complete`

- **Time**: When it happened
- **Component**: Which code file/function
- **Message**: What happened

## Common Patterns

### Saving not working
```
Store.UpdateTask returned: False  ← Problem here
OR
LoadData() FAILED: <error>       ← Problem here
```

### Padding/highlight issues
```
NO "RESET before padding"         ← Problem here
OR
NO "clear-to-EOL"                 ← Problem here
```

### Widget closing editor
```
Widget marked complete            ← Too early?
Collapsing widget                 ← Unexpected?
```

### Menu not responding
```
ESC/F10 pressed but no subsequent logs → Not reaching handler
No "hiding dropdown" message      → Dropdown not closing
```

## Tips

1. **Search is your friend**: Use `grep` to find specific messages
   ```bash
   grep "returned: False" /tmp/pmc-flow-debug.log
   grep "RESET" /tmp/pmc-padding-debug.log
   ```

2. **Use timestamps**: Find related entries across files
   ```bash
   # Find what happened at 11:22:35
   grep "11:22:35" /tmp/pmc-*.log
   ```

3. **Count occurrences**: Identify patterns
   ```bash
   grep "SkipRowHighlight" /tmp/pmc-edit-debug.log | wc -l
   ```

4. **Filter noise**: Focus on specific issue
   ```bash
   grep -v "After padding append" /tmp/pmc-padding-debug.log
   ```

## If You Still Have Issues

1. **Run with ALL logs enabled** (they all are by default)
2. **Perform action slowly** - Type slowly, wait between keys
3. **Check multiple logs** - Some issues span multiple logs
4. **Look for ERROR entries** - Any ERROR entries are important
5. **Check timestamps** - Verify logs are from current run

## Disabling Debug Logging

To remove debug logging before committing:

Search for `Add-Content -Path "/tmp/pmc-` and `Add-Content -Path "/tmp/pmc-` in these files:
- `widgets/UniversalList.ps1`
- `widgets/InlineEditor.ps1`
- `widgets/PmcMenuBar.ps1`
- `base/StandardListScreen.ps1`
- `screens/TaskListScreen.ps1`

Remove those lines or comment them out with `#`.
