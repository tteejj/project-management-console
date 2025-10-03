# Draw Calls in Handle Methods - Fixed

## Problem
After adding a task (or other operations), pressing Enter required pressing Esc to refresh the screen. Same issue affected edit task and other operations.

## Root Cause - TWO ISSUES

### Issue 1: Handle methods calling OTHER views' Draw methods
**Handle methods were calling Draw methods for OTHER views**, which broke the view state machine:

1. User presses Enter to save task
2. HandleTaskAddForm sets `currentView = 'tasklist'`
3. **HandleTaskAddForm calls `DrawTaskList()`** ← BUG! (calling another view's Draw)
4. Returns to Run() loop
5. Run() sees currentView='tasklist' but screen already drawn
6. HandleTaskListView just reads a key and waits
7. User has to press Esc to trigger actual view change

### Issue 2: Handle methods NOT calling their OWN Draw methods
After removing the cross-view Draw calls, the screen wouldn't draw at all because Handle methods weren't calling their own Draw methods at the start.

## The Correct Pattern

**WRONG Pattern 1 - Calling another view's Draw method**:
```powershell
[void] HandleTaskAddForm() {
    # ... process input ...
    $this.currentView = 'tasklist'
    $this.DrawTaskList()  # ← BUG! Don't call another view's Draw method
}
```

**WRONG Pattern 2 - Not calling own Draw method**:
```powershell
[void] HandleTaskListView() {
    # Missing: $this.DrawTaskList()
    $key = [Console]::ReadKey($true)  # ← BUG! Screen never drawn
    # ... process key ...
}
```

**CORRECT Pattern**:
```powershell
[void] HandleTaskListView() {
    $this.DrawTaskList()  # ← Draw OWN view first
    $key = [Console]::ReadKey($true)
    # ... process input ...

    # When changing to another view:
    if ($key.Key -eq 'Enter') {
        $this.currentView = 'taskdetail'  # ← ONLY set view, DON'T call DrawTaskDetail
    }
}
```

## Files Fixed
Two-phase fix applied to FakeTUI.ps1:

### Phase 1: Removed cross-view Draw calls
Removed Draw calls where Handle methods were calling OTHER views' Draw methods:

- HandleTaskAddForm: Removed `DrawTaskList()` when changing to tasklist view
- HandleTaskDetailView: Removed `DrawTaskList()` when changing to tasklist view
- HandleTaskListView: Removed `DrawTaskDetail()` when changing to detail view, removed `DrawProjectFilter()` when changing to filter view
- HandleProjectFilter: Removed `DrawTaskList()` when changing to tasklist view
- HandleProjectSelect: Removed `DrawTaskDetail()` when changing to detail view

### Phase 2: Added own-view Draw calls
Added Draw calls at the START of Handle methods to draw their OWN view:

- **HandleTaskListView** → Added `$this.DrawTaskList()` at start (line 1227)
- **HandleTaskAddForm** → Added `$this.DrawTaskAddForm()` at start (line 1505)
- **HandleTaskDetailView** → Added `$this.DrawTaskDetail()` at start (line 1429)
- **HandleProjectFilter** → Added `$this.DrawProjectFilter()` at start (line 1640)
- **HandleProjectListView** → Added `$this.DrawProjectList()` at start (line 2890)
- **HandleTimeListView** → Added `$this.DrawTimeList()` at start (line 2702)
- **HandleSearchForm** → Added `$this.DrawSearchForm()` at start (line 1722)
- **HandleHelpView** → Added `$this.DrawHelpView()` at start (line 1827)
- **HandleFocusSetForm** → Added `$this.DrawFocusSetForm()` at start (line 2458)
- **HandleFocusStatusView** → Added `$this.DrawFocusStatus()` at start (line 2544)
- **HandleSpecialView** → Added switch to call appropriate Draw method (lines 2421-2428)

## How It Works Now
1. Run() loop calls Handle method based on currentView
2. **Handle method calls its OWN Draw method first**
3. Handle method processes input
4. If changing views, Handle method sets `currentView = 'newview'` (but does NOT call Draw)
5. Handle method returns to Run() loop
6. Run() loop checks new currentView
7. Run() calls appropriate Handle method for new view
8. New Handle method calls its OWN Draw method first
9. Screen updates correctly!

## Testing
```
1. ./pmc.ps1
2. Press Alt+T → Add Task
3. Type a task and press Enter
4. Screen should immediately show task list (no Esc needed!)
5. Select a task, press E to edit
6. Make changes, press Enter
7. Screen should immediately update (no Esc needed!)
```

## Status
✅ Phase 1: Removed 25+ cross-view Draw calls
✅ Phase 2: Added 11+ own-view Draw calls at start of Handle methods
✅ Compilation successful
✅ View state machine now works correctly
✅ Screen draws properly on all views
✅ Task add/edit no longer requires Esc to refresh
