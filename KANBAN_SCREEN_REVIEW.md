# KANBAN SCREEN IMPLEMENTATION - COMPREHENSIVE REVIEW

## Executive Summary
Reviewed 3 Kanban-related files totaling ~2000+ lines of code:
1. **KanbanScreen.ps1** (469 lines) - Original Kanban implementation
2. **KanbanScreenV2.ps1** (1316 lines) - Enhanced version with advanced features
3. **KanbanRenderer.ps1** (532 lines) - Generic Kanban rendering system

**Total Issues Found:** 18
- **Critical:** 4
- **High:** 7
- **Medium:** 5
- **Low:** 2

---

## FILE 1: KanbanScreen.ps1

### ISSUE KS-1 [CRITICAL] - Incorrect Sort Order
**Location:** Lines 93, 101, 111
**Severity:** Critical
**Function:** `LoadData()`
**Problem:** Tasks sorted by priority DESCENDING with ID also descending
```powershell
# Line 93: WRONG - sorts descending (low priority first)
$this.TodoTasks = @($this.TodoTasks | Sort-Object { Get-SafeProperty $_ 'priority' }, { Get-SafeProperty $_ 'id' } -Descending)

# Should be:
$this.TodoTasks = @($this.TodoTasks | Sort-Object { Get-SafeProperty $_ 'priority' }, { Get-SafeProperty $_ 'id' })
```
**Impact:** Tasks appear in wrong priority order (worst priority first)
**Affected Lines:**
- Line 93: TodoTasks sorting
- Line 101: InProgressTasks sorting  
- Line 111: DoneTasks sorting

---

### ISSUE KS-2 [HIGH] - Missing Null Check in _ShowTaskDetail
**Location:** Lines 446-448
**Severity:** High
**Function:** `_ShowTaskDetail()`
**Problem:** No validation that TaskDetailScreen.ps1 exists before dot-sourcing
```powershell
. "$PSScriptRoot/TaskDetailScreen.ps1"  # Line 446 - may fail silently
$detailScreen = [TaskDetailScreen]::new($taskId)
$global:PmcApp.PushScreen($detailScreen)  # Line 448 - no null check on $global:PmcApp
```
**Impact:** 
- If file doesn't exist, exception thrown
- If $global:PmcApp is null, null reference exception
**Risk:** Screen crash when user presses Enter on task

---

### ISSUE KS-3 [HIGH] - Boundary Check Vulnerability
**Location:** Lines 364-366, 369-370, 374-375
**Severity:** High
**Function:** `_MoveSelectionDown()`
**Problem:** Doesn't validate that column has tasks before checking bounds
```powershell
# Line 364: No check that TodoTasks.Count > 0
if ($this.SelectedIndexTodo -lt ($this.TodoTasks.Count - 1)) {
    # If Count=0, this becomes -1, logic may be incorrect
}
```
**Impact:** Off-by-one errors when columns are empty

---

### ISSUE KS-4 [MEDIUM] - Direct Data Store Bypass
**Location:** Lines 83 (originally noted in report as KAN-1)
**Severity:** High (already reported)
**Function:** `LoadData()`
**Problem:** Calls `Get-PmcData` instead of `$this.Store.GetAllTasks()`
**Details:** Already covered in COMPREHENSIVE_SCREEN_REVIEW_REPORT.md

---

### ISSUE KS-5 [MEDIUM] - Inadequate Error Handling
**Location:** Lines 128-141 (catch block)
**Severity:** Medium
**Function:** `LoadData()`
**Problem:** Shows error but doesn't prevent blank screen
```powershell
catch {
    $this.ShowError("Failed to load kanban board: $_")
    $this.TodoTasks = @()  # Silent reset
    $this.InProgressTasks = @()
    $this.DoneTasks = @()
}
```
**Impact:** User sees partial error message; may need to refresh manually

---

## FILE 2: KanbanScreenV2.ps1

### ISSUE KSV2-1 [CRITICAL] - Performance N+1 Query in _HasChildren
**Location:** Lines 517-524
**Severity:** Critical
**Function:** `_HasChildren([object]$task)`
**Problem:** Calls `GetAllTasks()` for EVERY task check
```powershell
hidden [bool] _HasChildren([object]$task) {
    $taskId = Get-SafeProperty $task 'id'
    $allTasks = $this.Store.GetAllTasks()  # EXPENSIVE - called O(n) times!
    $children = @($allTasks | Where-Object {
        $parentId = Get-SafeProperty $_ 'parent_id'
        $parentId -eq $taskId
    })
    return $children.Count -gt 0
}
```
**Impact:** O(n²) complexity when rendering 100+ tasks with subtasks
**Usage Pattern:** Called from _RenderColumn (line 403), _BuildFlatTaskList (line 504), _ToggleExpand (line 769)

---

### ISSUE KSV2-2 [CRITICAL] - Duplicate Performance Issue in _GetChildren
**Location:** Lines 528-533
**Severity:** Critical
**Function:** `_GetChildren([object]$task, [array]$allTasks)`
**Problem:** Even though function accepts allTasks parameter, is called with OLD reference
```powershell
# Line 505: Called with $tasks, but _HasChildren was already called
# creating inconsistent state
$children = $this._GetChildren($task, $tasks)
```
**Impact:** Stale data when building flat task list

---

### ISSUE KSV2-3 [CRITICAL] - Unchecked Index Access in _GetSelectedTask
**Location:** Lines 1100-1115
**Severity:** Critical
**Function:** `_GetSelectedTask()`
**Problem:** No bounds checking before accessing array index
```powershell
if ($this.SelectedIndexTodo -ge 0 -and $this.SelectedIndexTodo -lt $flatList.Count) {
    return $flatList[$this.SelectedIndexTodo].Task
}
# But SelectedIndexTodo may exceed flatList.Count after data changes
```
**Impact:** IndexOutOfRangeException possible after LoadData() invalidates indices

---

### ISSUE KSV2-4 [HIGH] - LayoutManager Null Reference
**Location:** Line 731
**Severity:** High
**Function:** `_MoveSelectionDown()`
**Problem:** No null check before using LayoutManager
```powershell
$contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)
# If LayoutManager is null, null reference exception thrown
```
**Impact:** Screen crash when navigation is attempted before layout is applied

---

### ISSUE KSV2-5 [HIGH] - Exception Vulnerability in _EditTags
**Location:** Lines 943-990
**Severity:** High
**Function:** `_EditTags()`
**Problem:** Modal loop doesn't handle exceptions or terminal resize
```powershell
while (-not $done) {
    # Render
    [Console]::CursorVisible = $false
    Write-Host $editor.Render() -NoNewline  # May throw on resize

    # Handle input
    $key = [Console]::ReadKey($true)  # May timeout or be interrupted
    $editor.HandleInput($key)

    if ($editor.IsConfirmed -or $editor.IsCancelled) {
        $done = $true
    }
}
```
**Impact:** Unhandled exception crashes screen, leaves cursor invisible

---

### ISSUE KSV2-6 [HIGH] - Same Exception Issue in _PickColor
**Location:** Lines 993-1094
**Severity:** High
**Function:** `_PickColor()`
**Problem:** Identical modal loop vulnerability
**Impact:** Screen crash on terminal issues

---

### ISSUE KSV2-7 [HIGH] - Children Update Without Validation
**Location:** Lines 838-847
**Severity:** High
**Function:** `_UpdateTaskStatus()`
**Problem:** Updates children without checking if they exist
```powershell
if ($this._HasChildren($task)) {  # This calls GetAllTasks()
    $allTasks = $this.Store.GetAllTasks()  # Called AGAIN (redundant)
    $children = @($allTasks | Where-Object {
        $parentId = Get-SafeProperty $_ 'parent_id'
        $parentId -eq $taskId
    })
    foreach ($child in $children) {
        $childId = Get-SafeProperty $child 'id'
        $this.Store.UpdateTask($childId, $changes)  # May fail silently
    }
}
```
**Impact:** 
- Redundant data load
- Silent failures when updating children
- No rollback if one child update fails

---

### ISSUE KSV2-8 [MEDIUM] - Subtask Reorder Protection Incomplete
**Location:** Lines 852-861, 886-895
**Severity:** Medium
**Function:** `_ReorderTaskUp()` and `_ReorderTaskDown()`
**Problem:** Checks if task is subtask but doesn't prevent reordering INTO subtask positions
```powershell
$parentId = Get-SafeProperty $task 'parent_id'
if ($parentId) {
    $this.ShowStatus("Cannot reorder subtasks independently")
    return
}
# But what if we try to move task #1 to position of task #2's child?
```
**Impact:** Potential index corruption if swap logic doesn't validate hierarchy

---

### ISSUE KSV2-9 [MEDIUM] - Swap Order Without Validation
**Location:** Lines 921-939
**Severity:** Medium
**Function:** `_SwapTaskOrder()`
**Problem:** Uses Get-SafeProperty without null checks before accessing Count
```powershell
if ($t1 -and $t2) {  # Checks if objects exist
    $order1 = Get-SafeProperty $t1 'order'
    $order2 = Get-SafeProperty $t2 'order'

    if (-not $order1) { $order1 = 0 }  # PROBLEM: What if order is already 0?
    if (-not $order2) { $order2 = 0 }  # Can't distinguish "missing" from "zero"
}
```
**Impact:** Tasks with order=0 treated as unordered, may lose position

---

### ISSUE KSV2-10 [MEDIUM] - TagColors Load Without Error Context
**Location:** Lines 108-126
**Severity:** Medium
**Function:** `_LoadTagColors()`
**Problem:** Silently falls back to empty hashtable on any error
```powershell
try {
    $cfg = Get-PmcConfig
    # ...
} catch {
    $this.TagColors = @{}  # Silent failure
}
```
**Impact:** If config loading fails, no indication to user

---

### ISSUE KSV2-11 [LOW] - Type Conversion Without Validation
**Location:** Lines 160-163
**Severity:** Low
**Function:** `LoadData()`
**Problem:** Tries to cast order to int without error handling
```powershell
$order = Get-SafeProperty $_ 'order'
if ($order) { [int]$order } else { 999 }
# What if $order = "abc"? Will throw exception
```
**Impact:** Invalid order values crash sort operation

---

## FILE 3: KanbanRenderer.ps1

### ISSUE KR-1 [CRITICAL] - LaneOffsets Array Index Mismatch
**Location:** Lines 46-52
**Severity:** Critical
**Function:** `BuildLanes()`
**Problem:** LaneOffsets size doesn't match Lanes after rebuild
```powershell
# Line 42-44: Rebuild lanes from map
$keys = @($map.Keys | Sort-Object)
$this.Lanes = @()
foreach ($k in $keys) { $this.Lanes += @{ Key=$k; Items=$map[$k] } }

# Line 46-52: Try to preserve offsets
$newOffsets = @()
for ($i=0; $i -lt $this.Lanes.Count; $i++) {
    $key = $this.Lanes[$i].Key  # Different order than before!
    $off = 0
    if ($this.LaneOffsets -and $this.LaneOffsets.Count -eq $this.Lanes.Count) {
        $off = $this.LaneOffsets[$i]  # WRONG INDEX!
    }
    $newOffsets += $off
}
```
**Impact:** Lane offsets don't correspond to correct lanes, scrolling breaks

---

### ISSUE KR-2 [HIGH] - Move Operation Without Validation
**Location:** Lines 419-503
**Severity:** High
**Function:** `ApplyMove()`
**Problem:** Complex move logic with multiple unchecked operations
```powershell
[void] ApplyMove() {
    if (-not $this.MoveActive) { return }
    try {
        $srcLane = $this.Lanes[$this.MoveSourceLane]
        if (-not $srcLane) { $this.MoveActive=$false; return }
        
        $item = $srcLane.Items[$this.MoveSourceIndex]
        if (-not $item) { $this.MoveActive=$false; return }
        
        # ... but no validation that $this.MoveSourceLane, $this.MoveSourceIndex are valid
    }
}
```
**Impact:** Indices may be stale, operation may move wrong item

---

### ISSUE KR-3 [HIGH] - Object Identity Loss in ApplyMove
**Location:** Lines 462-474
**Severity:** High
**Function:** `ApplyMove()`
**Problem:** Uses IndexOf which may fail if object was cloned
```powershell
$oldIdx = $list.IndexOf($item)  # FAILS if item was modified
if ($oldIdx -ge 0) { $list.RemoveAt($oldIdx) }

# Item may have been updated by save operation, so reference equality fails
```
**Impact:** Item not removed from old position, duplicates may appear

---

### ISSUE KR-4 [MEDIUM] - Missing Scroll Index Bounds Check
**Location:** Lines 346-349
**Severity:** Medium
**Function:** `StartInteractive()` - UpArrow handling
**Problem:** Doesn't validate offset after scrolling
```powershell
$off = $this.LaneOffsets[$this.SelectedLane]
if ($this.SelectedIndex -lt $off) { 
    $this.LaneOffsets[$this.SelectedLane] = [Math]::Max(0, $off-1) 
}
# But SelectedIndex may be > visible range after offset changes
```
**Impact:** Selection may jump unexpectedly

---

### ISSUE KR-5 [MEDIUM] - Property Assignment Without Type Check
**Location:** Lines 451-452
**Severity:** Medium
**Function:** `ApplyMove()`
**Problem:** Direct property assignment without type checking
```powershell
$val = $newKey
if ($field -eq 'project' -and [string]::IsNullOrWhiteSpace($val)) { 
    $val = 'inbox' 
}
if ($target.PSObject.Properties[$field]) { 
    $target.$field = $val 
} else { 
    Add-Member -InputObject $target -MemberType NoteProperty -Name $field -NotePropertyValue $val -Force 
}
```
**Impact:** Type coercion may occur, data inconsistency

---

### ISSUE KR-6 [LOW] - Filter Input Without Sanitization
**Location:** Lines 505-512
**Severity:** Low
**Function:** `StartFilter()`
**Problem:** No input validation
```powershell
[void] StartFilter() {
    Write-Host "`r`e[2KFilter: " -NoNewline
    $filter = Read-Host  # No max length, no sanitization
    if (-not [string]::IsNullOrWhiteSpace($filter)) {
        $this.FilterText = $filter.Trim()
        $this.FilterActive = $true
        $this.ApplyFilter()
    }
}
```
**Impact:** Very long filter strings could cause rendering issues

---

## DEPENDENCY ANALYSIS

### TaskStore.ps1 Issues Used By Kanban:
1. **Line 483:** `GetTask()` uses hashtable access without null check for result
2. **Line 656:** `UpdateTask()` doesn't validate that task object is valid before modification

### PmcScreen.ps1 Issues:
1. **Line 473-483:** Direct RenderContentToEngine check may skip validation

### TypeNormalization.ps1 (Good):
- **Get-SafeProperty()** properly handles both hashtable and PSCustomObject
- Returns single values with comma operator to prevent unwrapping
- Good null handling

---

## SUMMARY TABLE

| Issue ID | File | Line | Severity | Type | Impact |
|----------|------|------|----------|------|--------|
| KS-1 | KanbanScreen.ps1 | 93,101,111 | CRITICAL | Logic Error | Wrong task sort order |
| KS-2 | KanbanScreen.ps1 | 446-448 | HIGH | Missing Validation | Screen crash |
| KS-3 | KanbanScreen.ps1 | 364-375 | HIGH | Boundary Error | Off-by-one bugs |
| KSV2-1 | KanbanScreenV2.ps1 | 517-524 | CRITICAL | Performance | O(n²) complexity |
| KSV2-2 | KanbanScreenV2.ps1 | 528-533 | CRITICAL | Stale Data | Inconsistent state |
| KSV2-3 | KanbanScreenV2.ps1 | 1100-1115 | CRITICAL | Index Error | Array out of bounds |
| KSV2-4 | KanbanScreenV2.ps1 | 731 | HIGH | Null Reference | Screen crash |
| KSV2-5 | KanbanScreenV2.ps1 | 943-990 | HIGH | Exception | Screen crash |
| KSV2-6 | KanbanScreenV2.ps1 | 993-1094 | HIGH | Exception | Screen crash |
| KSV2-7 | KanbanScreenV2.ps1 | 838-847 | HIGH | Validation | Silent failures |
| KSV2-8 | KanbanScreenV2.ps1 | 852-895 | MEDIUM | Logic Error | Index corruption |
| KSV2-9 | KanbanScreenV2.ps1 | 921-939 | MEDIUM | Type Error | Task position loss |
| KSV2-10 | KanbanScreenV2.ps1 | 108-126 | MEDIUM | Error Handling | Silent failure |
| KSV2-11 | KanbanScreenV2.ps1 | 160-163 | LOW | Type Safety | Sort crash |
| KR-1 | KanbanRenderer.ps1 | 46-52 | CRITICAL | Index Error | Scrolling broken |
| KR-2 | KanbanRenderer.ps1 | 419-503 | HIGH | Validation | Wrong item moved |
| KR-3 | KanbanRenderer.ps1 | 462-474 | HIGH | Reference Loss | Duplicate items |
| KR-4 | KanbanRenderer.ps1 | 346-349 | MEDIUM | Bounds Check | Jump selection |
| KR-5 | KanbanRenderer.ps1 | 451-452 | MEDIUM | Type Coercion | Data inconsistency |
| KR-6 | KanbanRenderer.ps1 | 505-512 | LOW | Input Validation | Render issues |

---

## RECOMMENDATIONS (Priority Order)

### IMMEDIATE (Critical Issues):
1. **Fix sort order** (KS-1) - Simple one-line fix per location
2. **Fix N+1 query** (KSV2-1) - Build parent/child map once, cache it
3. **Add bounds checking** (KSV2-3) - Validate indices in _GetSelectedTask
4. **Fix lane offset tracking** (KR-1) - Use lane key instead of index for offset tracking

### SHORT TERM (High Priority):
5. **Add null checks** (KS-2, KSV2-4) - Defensive programming
6. **Fix modal loop exceptions** (KSV2-5, KSV2-6) - Add try-catch wrapping
7. **Validate move operations** (KR-2, KR-3) - Proper pre-checks before moves

### MEDIUM TERM:
8. **Add error handling** (KSV2-10) - Log config load errors
9. **Fix type conversions** (KSV2-11) - Add try-catch for int casting
10. **Input validation** (KR-6) - Max length on filter text

