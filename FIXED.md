# FIXED - TUI Now Rendering

## Root Causes Found and Fixed:

### 1. LoadData() Failing Silently
**Problem:** TaskListScreen.LoadData() was dot-sourcing Storage.ps1 which failed because it needs other PMC functions
**Fix:** Removed all dot-source lines - module is already imported in Start-PmcTUI.ps1

### 2. ANSI Content Parsing Broken
**Problem:** Content between position markers includes color codes (ESC[38;2;r;g;bm). My parser was looking for next ESC[ which stopped at color codes, truncating content
**Fix:** Use the matches array index to find next POSITION marker (ESC[row;colH), not just any ESC[

## Changes Made:

**File:** `/home/teej/pmc/module/Pmc.Strict/consoleui/Start-PmcTUI.ps1`
- Added: `Import-Module Pmc.Strict.psd1` before loading screens

**File:** `/home/teej/pmc/module/Pmc.Strict/consoleui/screens/TaskListScreen.ps1`
- Removed: All `. "$PSScriptRoot/../../src/Storage.ps1"` lines (5 instances)
- Functions are available from module import

**File:** `/home/teej/pmc/module/Pmc.Strict/consoleui/PmcApplication.ps1`
- Fixed: `_WriteAnsiToEngine()` to use matches array indexing instead of IndexOf

## Confirmed Working:

```
Task List
Home → Tasks
────────────────────────────────────────────────────────────────────
> !2 [pmc] #1 Test task 1 - implement feature X
  !1 [pmc] #2 Test task 2 - fix bug in parser
  [pmc] #3 Test task 3 - write documentation
Up/Down: Select | A: Add | E: Edit | C: Complete | D: Delete | Esc: Back
3 active tasks
```

All 3 tasks render with:
- Priority indicators (!2, !1)
- Project tags [pmc]
- Task IDs and descriptions
- Cursor on selected task
- Color-coded ANSI output
- SpeedTUI differential rendering active

## To Run:

```bash
cd /home/teej/pmc
pwsh /home/teej/pmc/module/Pmc.Strict/consoleui/Start-PmcTUI.ps1
```

SpeedTUI BeginFrame/WriteAt/EndFrame working correctly.
