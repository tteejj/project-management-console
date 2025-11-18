# Unimplemented Features & TODOs
## Project Management Console - Features Requiring Implementation or Removal

**Generated:** 2025-11-18
**Source:** Comprehensive screen review

This document lists all incomplete features, TODOs, and stubs found during the comprehensive code review. These items require a decision: either implement them fully or remove the UI elements to avoid confusing users.

---

## Summary

**Total Items:** 5
- **Incomplete Features:** 4 (exposed to users via UI)
- **TODOs in Code:** 1 (internal, not user-facing)

---

## 1. KANBAN SCREEN - Task Detail View (KAN-4)

**Status:** Incomplete
**Priority:** LOW
**Location:** `KanbanScreen.ps1:371-380`

### Description
Pressing Enter on a task in Kanban view shows a message but does not open any detail screen.

### Current Code
```powershell
hidden [void] _ShowTaskDetail() {
    $task = $this._GetSelectedTask()
    if ($task) {
        $taskId = Get-SafeProperty $task 'id'
        $this.ShowStatus("TODO: Show detail for task $taskId")
        # TODO: Push detail screen when implemented
    }
}
```

### User Impact
- User sees "Enter" as an available action in footer
- Pressing Enter shows status message "TODO: Show detail for task X"
- Creates expectation of functionality that doesn't exist

### Options
1. **Implement:** Create TaskDetailScreen and push it
2. **Remove:** Remove Enter key handler and footer hint
3. **Defer:** Add to backlog, update message to "Detail view coming soon"

### Recommendation
**Remove** the Enter key hint from footer until TaskDetailScreen is implemented. The current behavior is confusing.

---

## 2. PROJECT SCREEN - Excel Import Feature (PRJ-3, PRJ-4, EXC-6)

**Status:** Partially Implemented / Unreachable Code
**Priority:** HIGH (users can see menu item)
**Locations:**
- `ProjectListScreen.ps1:629-749` (unreachable code after early return)
- `ExcelImportScreen.ps1:282` (file picker not implemented)

### Description
The "Import from Excel" menu item exists but has multiple implementation issues:

1. **ProjectListScreen** - Shows error message "Excel import file picker needs async implementation..." and returns
2. **Unreachable code** - 120 lines of Excel parsing code after the return statement
3. **ExcelImportScreen** - File picker option (#2) not implemented

### Current Code (ProjectListScreen)
```powershell
[void] ImportFromExcel() {
    # ...file picker code...
    $this.SetStatusMessage("Excel import file picker needs async implementation...", "warning")
    return  # RETURNS HERE

    # H-ERR-2: Wrap file operations in try-catch for proper error handling
    try {
        if (-not (Test-Path $excelPath)) {  # NEVER REACHED
            $this.SetStatusMessage("File not found: $excelPath", "error")
            return
        }
    }
    # ... 100+ lines of unreachable code ...
}
```

### Current Code (ExcelImportScreen)
```powershell
// Step 1: Option 1 works (attach to running Excel)
if ($this._selectedOption -eq 0) {
    $this._reader.AttachToRunningExcel()  // WORKS
} else {
    $this._errorMessage = "File picker not implemented. Please use option 1."  // BROKEN
}
```

### User Impact
- **High confusion:** Menu item exists and seems functional
- **ProjectListScreen:** Shows "needs async implementation" message
- **ExcelImportScreen:** Option 1 (attach to running Excel) WORKS
- **ExcelImportScreen:** Option 2 (file picker) shows error message

### Options
1. **Implement file picker** - Complete the async file picker implementation
2. **Remove unreachable code** - Clean up the dead code in ProjectListScreen
3. **Hide incomplete option** - Remove Option 2 from ExcelImportScreen
4. **Remove menu item** - Hide "Import from Excel" until fully implemented

### Recommendation
**Two-phase approach:**
1. **Immediate:** Remove unreachable code in ProjectListScreen.ps1 (lines 631-749)
2. **Short-term:** Either implement file picker OR remove Option 2 from ExcelImportScreen
3. **Note:** ExcelImportScreen Option 1 (attach to running Excel) is fully functional and can be used

---

## 3. PROJECT SCREEN - Unreachable Error Handling (PRJ-3)

**Status:** Dead Code
**Priority:** LOW (code cleanup)
**Location:** `ProjectListScreen.ps1:629-749`

### Description
See PRJ-4 above - this is the unreachable code after the early return.

### Recommendation
**Remove** lines 631-749 in ProjectListScreen.ps1 as they are unreachable and misleading.

---

## 4. EXCEL IMPORT SCREEN - File Picker Option (EXC-6)

**Status:** Incomplete
**Priority:** MEDIUM
**Location:** `ExcelImportScreen.ps1:282`

### Description
The Excel Import wizard shows two options:
1. **Option 1: Attach to running Excel** - ✅ WORKS
2. **Option 2: Browse for Excel file** - ❌ NOT IMPLEMENTED

### Current Code
```powershell
if ($this._selectedOption -eq 0) {
    $this._reader.AttachToRunningExcel()  // Option 1 - WORKS
    $this._step = 2
    $this._selectedOption = 0
} else {
    $this._errorMessage = "File picker not implemented. Please use option 1."  // Option 2 - BROKEN
}
```

### User Impact
- User sees 2 options but only 1 works
- Error message clearly states "not implemented"
- Workaround exists (Option 1)

### Options
1. **Implement file picker:** Add PmcFilePicker integration
2. **Hide Option 2:** Only show "Attach to running Excel"
3. **Update message:** Change to "Browse option coming soon - use Option 1"

### Recommendation
**Hide Option 2** until file picker is implemented. Update the UI to only show Option 1 with clear instructions.

---

## 5. TIME SCREEN - UpdateTimeLog Support (TIM-3)

**Status:** Uncertain / May Not Be Supported
**Priority:** MEDIUM
**Location:** `TimeListScreen.ps1:317-327`

### Description
Comment notes that time logs may not support update operations in PMC.

### Current Code
```powershell
# Time logs typically don't support update in PMC - might need to delete and re-add
# For now, try to update by ID if it exists
if ($item.ContainsKey('id')) {
    $success = $this.Store.UpdateTimeLog($item.id, $changes)
    if ($success) {
        $this.SetStatusMessage("Time entry updated", "success")
    } else {
        $this.SetStatusMessage("Failed to update time entry: $($this.Store.LastError)", "error")
    }
}
```

### User Impact
- Edit functionality may fail
- Error message shown: "Failed to update time entry"
- Unclear if this is a bug or by design

### Investigation Needed
1. Check if `TaskStore.UpdateTimeLog()` is implemented
2. Determine if time logs should be immutable (delete+re-add pattern)
3. Update UI accordingly (hide Edit or implement delete+re-add)

### Recommendation
**Investigate and decide:**
- If UpdateTimeLog works → Remove the comment
- If it doesn't work → Implement delete+re-add pattern OR disable Edit action for time entries

---

## Implementation Priority

### High Priority (User-Facing Issues)
1. **PRJ-4:** Remove unreachable code and clarify Excel import status
2. **EXC-6:** Hide non-functional file picker option
3. **TIM-3:** Investigate and fix time log editing

### Medium Priority (UX Improvements)
4. **KAN-4:** Remove Enter key hint or implement detail view

### Low Priority (Code Cleanup)
5. **PRJ-3:** Remove dead code (same as PRJ-4)

---

## Recommendations Summary

### Immediate Actions (Next Sprint)
1. **Remove unreachable code** in ProjectListScreen.ps1 (lines 631-749)
2. **Hide Option 2** in ExcelImportScreen (file picker)
3. **Remove Enter hint** from KanbanScreen footer

### Short-term Actions (1-2 Sprints)
4. **Investigate time log editing** - determine correct pattern
5. **Implement file picker** OR document it as a backlog item

### Long-term Actions (Backlog)
6. **Implement TaskDetailScreen** for Kanban detail view
7. **Complete Excel import** with file browser support

---

## Testing Recommendations

For each implemented feature:
1. **Happy path:** Verify feature works as intended
2. **Error cases:** Verify error messages are clear and helpful
3. **UI consistency:** Ensure shortcuts/menu items match actual functionality
4. **Documentation:** Update user guide with new features

For each removed feature:
5. **UI cleanup:** Verify no remnants in menus/footers
6. **Code cleanup:** Verify no dead code remains
7. **Error handling:** Verify graceful fallback if accessed via old paths

---

## Appendix: Code Locations

### Files with TODOs/Incomplete Features
```
module/Pmc.Strict/consoleui/screens/KanbanScreen.ps1:371
module/Pmc.Strict/consoleui/screens/ProjectListScreen.ps1:629-749
module/Pmc.Strict/consoleui/screens/ExcelImportScreen.ps1:282
module/Pmc.Strict/consoleui/screens/TimeListScreen.ps1:317
```

### Search Commands
```bash
# Find all TODO comments
grep -r "TODO:" module/Pmc.Strict/consoleui/screens/

# Find "not implemented" messages
grep -r "not implemented" module/Pmc.Strict/consoleui/screens/

# Find "needs implementation" messages
grep -r "needs.*implementation" module/Pmc.Strict/consoleui/screens/
```

---

**End of Document**
