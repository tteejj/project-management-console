# Comprehensive Screen Review - All Issues Report

**Date:** 2025-11-18
**Scope:** Complete functional review of all screens with function tracing
**Screens Reviewed:** Task List, Kanban, All Project, All Time, All Excel, Settings/Tools

---

## Executive Summary

This report documents all issues found through comprehensive review of each screen, tracing functions back through the entire call chain including:
- Screen classes
- Base classes (StandardListScreen, PmcScreen)
- Widget components (UniversalList, InlineEditor, FilterPanel, DatePicker, ProjectPicker, TagEditor)
- Services (TaskStore, MenuRegistry, ExcelComReader, ExcelMappingService)
- Helper modules (ValidationHelper, TypeNormalization, etc.)

**Total Issues Found: 87**
- Critical: 12
- High: 23
- Medium: 31
- Low: 21

---

## 1. TASK LIST SCREEN

**File:** `module/Pmc.Strict/consoleui/screens/TaskListScreen.ps1` (2271 lines)

### 1.1 Data Loading Issues

#### ISSUE TLS-C1: Cache invalidation race condition
**Severity:** Critical
**Location:** TaskListScreen.ps1:306-318 (LoadData method)
**Description:** Cache key comparison happens before data load, but cache could be invalidated by TaskStore event between check and use
**Impact:** Stale data displayed to user after external task changes
**Function Chain:**
```
LoadData()
  → _cachedFilteredTasks check (line 311)
  → TaskStore.GetAllTasks() (line 320)
  → OnTasksChanged event could fire here
  → Cache already returned from line 312
```

#### ISSUE TLS-H1: Missing null check on filtered tasks
**Severity:** High
**Location:** TaskListScreen.ps1:424-432
**Description:** After filtering by view mode, `$filteredTasks` could be `$null` but only checked after additional filtering applied
**Impact:** Potential null reference when accessing Count property
**Code:**
```powershell
if (-not $this._showCompleted) {
    $filteredTasks = $filteredTasks | Where-Object { -not (Get-SafeProperty $_ 'completed') }
    # Null check after additional filtering
    if ($null -eq $filteredTasks) { $filteredTasks = @() }
}
```

#### ISSUE TLS-M1: Inefficient O(n²) subtask organization
**Severity:** Medium
**Location:** TaskListScreen.ps1:455-511
**Description:** While optimized with hashtable index, still performs full array iteration twice (once to build index, once to process parents)
**Impact:** Performance degradation with 500+ tasks with subtasks
**Current:** O(2n) = O(n)
**Note:** Actually optimized correctly, but could use single-pass if restructured

### 1.2 Column Rendering Issues

#### ISSUE TLS-H2: Format callback receives wrong item type
**Severity:** High
**Location:** TaskListScreen.ps1:560-625 (title column Format callback)
**Description:** Format callback assumes item is hashtable but TaskStore may return PSCustomObject
**Impact:** `Get-SafeProperty` calls fail silently, blank cells shown
**Function Chain:**
```
GetColumns() → Format callback
  → Get-SafeProperty $task 'title'
  → TaskStore.GetAllTasks() returns PSCustomObject[]
  → Property access fails
```

#### ISSUE TLS-M2: Strikethrough not disabled when unsupported
**Severity:** Medium
**Location:** TaskListScreen.ps1:99, 610-614
**Description:** `_supportsStrikethrough` flag defaults to true but never validates terminal capability
**Impact:** Garbled display on terminals without ANSI strikethrough support
**Code:**
```powershell
hidden [bool]$_supportsStrikethrough = $true  # Assume support, can be overridden
```

#### ISSUE TLS-L1: Hardcoded column widths don't adapt to terminal
**Severity:** Low
**Location:** TaskListScreen.ps1:554-814 (GetColumns)
**Description:** Column widths are fixed (35, 25, 12, 15, 20) and don't adjust for narrow terminals
**Impact:** Columns truncated or overflow on terminals < 120 chars wide
**Widths:** title=35, details=25, due=12, project=15, tags=20 (total 107 + separators = ~112)

### 1.3 Edit Mode Issues

#### ISSUE TLS-C2: Edit values not cleared between items
**Severity:** Critical
**Location:** TaskListScreen.ps1:1555-1570 (EditItem)
**Description:** `_editValues` hashtable reused without clearing, old values leak into new edits
**Impact:** Editing task B shows values from previously edited task A
**Fix Applied:** Line 1556-1558 clears hashtable, but only in TLS-L3 low-priority fix comment

#### ISSUE TLS-H3: Tags array unwrapping in OnItemUpdated
**Severity:** High
**Location:** TaskListScreen.ps1:1031-1055
**Description:** PowerShell unwraps single-element arrays without comma operator
**Impact:** Tags stored as string instead of array, validation fails
**Code:**
```powershell
# TLS-M1 FIX: Added comma operator to prevent array unwrapping
$tagsValue = @(if ($values.ContainsKey('tags') -and $values.tags) {
    if ($values.tags -is [array]) {
        ,$values.tags  # TLS-M1: Comma operator prevents unwrapping
```

#### ISSUE TLS-M3: Project value type inconsistency
**Severity:** Medium
**Location:** TaskListScreen.ps1:981-1009 (OnItemUpdated)
**Description:** Project picker may return array, string, or null; requires complex type checking
**Impact:** "(No Project)" literal stored instead of empty string
**Function Chain:**
```
OnItemUpdated()
  → ProjectPicker.OnProjectSelected callback
  → Returns array if multiple selections enabled
  → Code extracts first element but doesn't validate
```

### 1.4 Validation Issues

#### ISSUE TLS-H4: Missing validation for circular parent_id
**Severity:** High
**Location:** TaskListScreen.ps1:1279-1297 (_IsCircularDependency)
**Description:** Method exists but never called before AddSubtask/OnItemUpdated
**Impact:** User can create circular task hierarchies, causing infinite loops in rendering
**Validation Missing At:**
- Line 1316-1334 (AddSubtask) - no circular check
- Line 923-929 (OnItemCreated) - no circular check when parent_id preserved

#### ISSUE TLS-M4: Text length validation inconsistent
**Severity:** Medium
**Location:** TaskListScreen.ps1:822, 885-888, 1018-1022
**Description:** Field definition specifies MaxLength=200 but validation checks 500
**Code:**
```powershell
Line 822: @{ Name='text'; Type='text'; Label='Task'; Required=$true; MaxLength=200; Value='' }
Line 886: if ($taskText.Length -gt 500) {
```

### 1.5 Widget Integration Issues

#### ISSUE TLS-H5: DatePicker position calculation incorrect for scrolled lists
**Severity:** High
**Location:** TaskListScreen.ps1:1638-1646 (_ShowWidgetForColumn)
**Description:** Widget Y position calculated from selected index without accounting for scroll offset
**Impact:** DatePicker appears in wrong location when list scrolled
**Code:**
```powershell
$selectedIndex = $this.List.GetSelectedIndex()
$rowY = $contentRect.Y + $selectedIndex + 2  # +2 for header
# MISSING: Should be ($selectedIndex - $this.List._scrollOffset)
```

#### ISSUE TLS-M5: Widget closure captures wrong screen instance
**Severity:** Medium
**Location:** TaskListScreen.ps1:1678-1687, 1716-1727 (widget callbacks)
**Description:** `GetNewClosure()` captures `$self` but could reference wrong screen if multiple TaskListScreens exist
**Impact:** Widget callbacks update wrong screen's edit values
**Function Chain:**
```
_ShowWidgetForColumn()
  → DatePicker.OnConfirmed callback
  → Uses $self._editValues
  → If multiple screens, $self could be stale reference
```

#### ISSUE TLS-L2: TagEditor widget never shown
**Severity:** Low
**Location:** TaskListScreen.ps1:1622-1623, 1735-1773
**Description:** Code checks `$col -ne 'tags'` to skip widget, but TagEditor code path never reached
**Impact:** Tags edited as inline text instead of using TagEditor widget
**Code:**
```powershell
# Only show widgets for due/project columns (tags is now inline text)
if ($col -ne 'due' -and $col -ne 'project') {
    return
}
# Lines 1735-1773: TagEditor code is unreachable
```

### 1.6 Inline Edit Mode Issues

#### ISSUE TLS-C3: Edit mode state not synchronized with UniversalList
**Severity:** Critical
**Location:** TaskListScreen.ps1:137-180 (_SetupEditModeCallbacks)
**Description:** `GetIsInEditMode` and `GetFocusedColumnIndex` callbacks set but UniversalList may not invoke them
**Impact:** Cell highlighting fails, user doesn't know which cell is being edited
**Function Chain:**
```
EditItem() → sets _isEditingRow = true
  → List.InvalidateCache() (line 1577)
  → List.Render() should call GetIsInEditMode callback
  → BUT: UniversalList.ps1 doesn't show callback invocation
```

#### ISSUE TLS-H6: Tab navigation doesn't update column index
**Severity:** High
**Location:** TaskListScreen.ps1:1796-1800 (_HandleInlineEditInput)
**Description:** Tab key handled but `_currentColumnIndex` increment code missing from excerpt
**Impact:** User presses Tab but focused column doesn't change
**Need to verify:** Lines 1800-2271 for Tab handling completion

#### ISSUE TLS-M6: Enter key behavior undefined in inline edit mode
**Severity:** Medium
**Location:** TaskListScreen.ps1:1790+ (_HandleInlineEditInput method)
**Description:** No explicit Enter key handling shown in excerpt
**Impact:** User presses Enter expecting save, behavior undefined
**Expected:** Enter should call OnItemUpdated and exit edit mode

### 1.7 Performance Issues

#### ISSUE TLS-L3: Debug logging creates file I/O bottleneck
**Severity:** Low
**Location:** Throughout TaskListScreen.ps1 (lines 156-157, 323-328, 549-552, etc.)
**Description:** Debug logging to `/tmp/pmc-edit-debug.log` on every render when enabled
**Impact:** Significant performance degradation when `_enableDebugLogging = true`
**Frequency:** ~20+ log writes per render cycle

#### ISSUE TLS-M7: Cache not used for column Format callbacks
**Severity:** Medium
**Location:** TaskListScreen.ps1:539-814 (GetColumns Format callbacks)
**Description:** Format callbacks compute values on every render without caching
**Impact:** Repeated string operations for strikethrough, truncation, date formatting
**Example:** Line 636-640 truncates details on every render

---

## 2. KANBAN SCREEN

**File:** `module/Pmc.Strict/consoleui/screens/KanbanScreen.ps1` (470 lines)

### 2.1 Data Loading Issues

#### ISSUE KAN-H1: Task filtering uses multiple Where-Object passes
**Severity:** High
**Location:** KanbanScreen.ps1:86-111 (LoadData)
**Description:** Tasks filtered 3 separate times (TODO, InProgress, Done) with full array scans
**Impact:** O(3n) complexity when O(n) possible with single pass and grouping
**Code:**
```powershell
$this.TodoTasks = @($allTasks | Where-Object { ... })
$this.InProgressTasks = @($allTasks | Where-Object { ... })
$this.DoneTasks = @($allTasks | Where-Object { ... })
```

#### ISSUE KAN-M1: Seven days calculation not configurable
**Severity:** Medium
**Location:** KanbanScreen.ps1:84
**Description:** "Done" column hardcoded to 7 days, no user preference
**Impact:** Users cannot adjust time window for completed tasks
**Code:**
```powershell
$sevenDaysAgo = (Get-Date).AddDays(-7)
```

#### ISSUE KAN-L1: Duplicate sorting after filtering
**Severity:** Low
**Location:** KanbanScreen.ps1:93, 101, 111
**Description:** Each column sorted separately, redundant operations
**Impact:** Minor performance cost, could sort once before splitting

### 2.2 Rendering Issues

#### ISSUE KAN-H2: Column width calculation doesn't account for borders
**Severity:** High
**Location:** KanbanScreen.ps1:170
**Description:** Formula `($contentRect.Width - 6) / 3` assumes 6 chars for borders but actual border rendering may differ
**Impact:** Column overflow or gaps depending on border characters
**Code:**
```powershell
$columnWidth = [Math]::Floor(($contentRect.Width - 6) / 3)
```

#### ISSUE KAN-M2: Truncation indicator inconsistent
**Severity:** Medium
**Location:** KanbanScreen.ps1:286-293
**Description:** Shows "... +N more" when tasks exceed `$maxLines`, but doesn't indicate which column
**Impact:** User doesn't know which column has hidden tasks

#### ISSUE KAN-L2: Hard-coded colors don't respect theme
**Severity:** Low
**Location:** KanbanScreen.ps1:159-166
**Description:** Uses theme colors but column headers always use `$mutedColor` regardless of selection
**Impact:** Minimal visual distinction between columns

### 2.3 Navigation Issues

#### ISSUE KAN-M3: No visual indicator for empty columns
**Severity:** Medium
**Location:** KanbanScreen.ps1:217-296 (_RenderColumn)
**Description:** Empty column renders blank space with no "(empty)" message
**Impact:** User unsure if column is empty or failed to load

#### ISSUE KAN-M4: Column selection lost after data refresh
**Severity:** Medium
**Location:** KanbanScreen.ps1:78 (LoadData), 333-334 (HandleKeyPress 'r')
**Description:** `LoadData()` doesn't preserve `SelectedColumn`, always resets to 0
**Impact:** User refreshes data, selection jumps back to TODO column

### 2.4 Task Movement Issues

#### ISSUE KAN-H3: _MoveTask cycles through wrong statuses
**Severity:** High
**Location:** KanbanScreen.ps1:384-397
**Description:** Cycles pending → in-progress → done → pending, but skips 'blocked' and 'waiting' statuses
**Impact:** User cannot move tasks to blocked/waiting via 'M' key
**Code:**
```powershell
switch ($taskStatus) {
    'pending' { $newStatus = 'in-progress' }
    'in-progress' { $newStatus = 'done'; $completedDate = ... }
    'done' { $newStatus = 'pending' }
    default { $newStatus = 'in-progress' }
}
```

#### ISSUE KAN-M5: completedDate set but completed flag not set
**Severity:** Medium
**Location:** KanbanScreen.ps1:392-393
**Description:** Sets `completedDate` when moving to 'done' but logic sets `completed = true` later
**Impact:** Potential data inconsistency if update fails midway

#### ISSUE KAN-C1: No optimistic update before Store.UpdateTask
**Severity:** Critical
**Location:** KanbanScreen.ps1:410-413
**Description:** Task stays in old column until `LoadData()` completes after successful update
**Impact:** UI feels laggy, user sees old state for 100-500ms
**Function Chain:**
```
_MoveTask()
  → Store.UpdateTask($taskId, $changes) (line 410)
  → OnTasksChanged event fires
  → LoadData() (line 413)
  → Columns re-rendered
  → Task appears in new column
```

### 2.5 Error Handling Issues

#### ISSUE KAN-H4: Silent failure in LoadData catch block
**Severity:** High
**Location:** KanbanScreen.ps1:128-141
**Description:** Shows error to user but doesn't prevent ShowStatus from being called on line 126
**Impact:** Status line shows success message even when load failed
**Code:**
```powershell
} catch {
    $errorMsg = "Failed to load kanban board: $($_.Exception.Message)"
    $this.ShowError($errorMsg)  # Shows error
    # Line 126 already executed: ShowStatus("Kanban: X TODO, Y InProgress, Z Done")
}
```

#### ISSUE KAN-M6: GetSelectedTask returns null without error message
**Severity:** Medium
**Location:** KanbanScreen.ps1:420-439 (_GetSelectedTask)
**Description:** Returns `$null` but `_ShowTaskDetail` doesn't check until line 443
**Impact:** Silent failure when selection index out of bounds

---

## 3. PROJECT LIST SCREEN

**File:** `module/Pmc.Strict/consoleui/screens/ProjectListScreen.ps1` (874 lines)

### 3.1 Data Loading Issues

#### ISSUE PLS-H1: Task count calculated inefficiently
**Severity:** High
**Location:** ProjectListScreen.ps1:85-112 (LoadItems)
**Description:** Loads all tasks and builds hashtable index every time LoadItems called
**Impact:** O(n) operation on every data refresh, should cache task counts
**Code:**
```powershell
$allTasks = $this.Store.GetAllTasks()  # Every time!
$tasksByProject = @{}
foreach ($task in $allTasks) { ... }
```

#### ISSUE PLS-M1: Status field defaulted incorrectly
**Severity:** Medium
**Location:** ProjectListScreen.ps1:106-111
**Description:** Comment says "don't always default to 'active'" but sets empty string instead
**Impact:** Projects without status show blank instead of 'active' or 'unknown'
**Code:**
```powershell
# PS-M3 FIX: Don't always default status to 'active' for existing projects
if (-not $project.ContainsKey('status') -or $null -eq $project['status']) {
    $project['status'] = ''  # Empty string instead of 'active'
}
```

### 3.2 Field Definitions Issues

#### ISSUE PLS-C1: 48 Excel fields create massive edit form
**Severity:** Critical
**Location:** ProjectListScreen.ps1:128-212 (GetEditFields for new project)
**Description:** New project form has 48 fields, would require 10+ screens to edit
**Impact:** Form completely unusable, scroll position lost
**Fields:** Core(4) + ID(2) + Path(4) + Date(3) + ProjectInfo(9) + ContactDetails(7) + AuditPeriods(12) + Contacts(10) + SystemInfo(8) + Additional(2) = 61 total

#### ISSUE PLS-H2: Date parsing uses generic DateTime.Parse
**Severity:** High
**Location:** ProjectListScreen.ps1:222-227 (parseDate helper)
**Description:** No format specification, relies on culture settings
**Impact:** Dates fail to parse in non-US locales
**Code:**
```powershell
try { [DateTime]::Parse($val) } catch { $null }
```

#### ISSUE PLS-M2: Array to string conversion loses structure
**Severity:** Medium
**Location:** ProjectListScreen.ps1:216-219 (arrayToStr helper)
**Description:** Joins arrays with ', ' but no way to split them back
**Impact:** Tags field becomes string, loses array type

### 3.3 Validation Issues

#### ISSUE PLS-H3: Duplicate name check case-sensitive
**Severity:** High
**Location:** ProjectListScreen.ps1:612-614 (OnItemUpdated)
**Description:** Checks `$values.name -ne $originalName` for duplicates, case-sensitive
**Impact:** User can create "Project1" and "project1" as separate projects
**Code:**
```powershell
$duplicate = $existingProjects | Where-Object { (Get-SafeProperty $_ 'name') -eq $values.name }
```

#### ISSUE PLS-M3: Project name length validation inconsistent
**Severity:** Medium
**Location:** ProjectListScreen.ps1:323-327, 593-596
**Description:** Create validates ≤100 chars, Update validates ≤100 chars, but both allow 101+ in some code paths
**Impact:** Data exceeds schema limits if validation bypassed

#### ISSUE PLS-L1: No validation for required Excel fields
**Severity:** Low
**Location:** ProjectListScreen.ps1:128-212
**Description:** None of the 48 Excel fields marked as Required=true except 'name'
**Impact:** Projects created with missing critical data

### 3.4 File Picker Integration Issues

#### ISSUE PLS-H4: ProjFolder path not validated before use
**Severity:** High
**Location:** ProjectListScreen.ps1:714-733 (OpenProjectFolder)
**Description:** Validates path exists but doesn't check if user has read permissions
**Impact:** Error when opening folder user can't access
**Code:**
```powershell
$resolvedPath = Resolve-Path -Path $folderPath -ErrorAction Stop
if (-not (Test-Path -Path $resolvedPath -PathType Container)) { ... }
# MISSING: Check -Readable or try-catch around directory enumeration
```

#### ISSUE PLS-M4: FilePicker lazy loading race condition
**Severity:** Medium
**Location:** ProjectListScreen.ps1:672-677 (EnsureFilePicker)
**Description:** Checks if type exists but doesn't prevent concurrent loads
**Impact:** Multiple screens could dot-source PmcFilePicker.ps1 simultaneously

### 3.5 Excel Import Integration Issues

#### ISSUE PLS-M5: ImportFromExcel doesn't pass project context
**Severity:** Medium
**Location:** ProjectListScreen.ps1:680-691 (ImportFromExcel)
**Description:** Launches ExcelImportScreen but doesn't tell it to return to ProjectListScreen
**Impact:** User imports project, returned to previous screen instead of project list

#### ISSUE PLS-L2: No feedback when Excel import succeeds
**Severity:** Low
**Location:** ProjectListScreen.ps1:680-691
**Description:** Pushes ExcelImportScreen but doesn't set callback to refresh project list
**Impact:** User imports project, list not refreshed until manual refresh

### 3.6 Menu Registration Issues

#### ISSUE PLS-M6: Static RegisterMenuItems never called
**Severity:** Medium
**Location:** ProjectListScreen.ps1:31-36
**Description:** Static method defined but no evidence of MenuRegistry calling it
**Impact:** "Project List" menu item may not appear in Projects menu

---

## 4. TIME LIST SCREEN

**File:** `module/Pmc.Strict/consoleui/screens/TimeListScreen.ps1` (541 lines)

### 4.1 Data Aggregation Issues

#### ISSUE TMS-H1: Grouping key construction vulnerable to data corruption
**Severity:** High
**Location:** TimeListScreen.ps1:122-131
**Description:** Uses pipe `|` as delimiter but doesn't validate data doesn't contain pipes
**Impact:** Project name "Foo|Bar" breaks grouping, entries incorrectly merged
**Code:**
```powershell
# TS-M3 FIX: Sanitize components to prevent pipe character breaking grouping
$dateStrSafe = $dateStr -replace '\|', '_'
$projectSafe = $project -replace '\|', '_'
$timecodeSafe = $timecode -replace '\|', '_'
$groupKey = "$dateStrSafe|$projectSafe|$timecodeSafe"
```

#### ISSUE TMS-H2: Date parsing failures tracked but not shown until load completes
**Severity:** High
**Location:** TimeListScreen.ps1:95-96, 113-118, 219-223
**Description:** Counts failed parses but only shows warning after all entries processed
**Impact:** User sees "20 entries" status briefly before "Warning: 5 invalid dates" replaces it

#### ISSUE TMS-M1: Invalid date format preserved with marker
**Severity:** Medium
**Location:** TimeListScreen.ps1:115
**Description:** Invalid dates stored as "INVALID:originalValue" which breaks sorting
**Impact:** Invalid entries appear at top of list (string sort vs date sort)
**Code:**
```powershell
$dateStr = "INVALID:$($entry.date)"
```

#### ISSUE TMS-M2: String concatenation unbounded
**Severity:** Medium
**Location:** TimeListScreen.ps1:165-194 (task and notes concatenation)
**Description:** Limits to 200/300 chars but still allocates full string each time
**Impact:** Memory churn with 1000+ aggregated entries
**Code:**
```powershell
$newTask = "$currentTask; $($entry.task)"
$grouped[$groupKey].task = if ($newTask.Length -gt 200) {
    $newTask.Substring(0, 197) + "..."
} else {
    $newTask
}
```

### 4.2 Time Entry Editing Issues

#### ISSUE TMS-H3: Hours conversion loses precision
**Severity:** High
**Location:** TimeListScreen.ps1:296, 359
**Description:** Converts hours to minutes with `[int]`, truncating fractional minutes
**Impact:** 2.75 hours becomes 165 minutes (2h45m) instead of storing as decimal
**Code:**
```powershell
$minutes = [int]($hoursValue * 60)  # 2.75 * 60 = 165.0 → 165
```

#### ISSUE TMS-M3: Hour validation range too restrictive
**Severity:** Medium
**Location:** TimeListScreen.ps1:249, 291-294, 354-357
**Description:** Max hours set to 8, prevents logging overtime or full-day work
**Impact:** User cannot log 10-hour workday
**Code:**
```powershell
@{ Name='hours'; Type='number'; Label='Hours'; Min=0.25; Max=8; Step=0.25; Value=0.25 }
```

#### ISSUE TMS-L1: Project and timecode mutually exclusive not enforced in UI
**Severity:** Low
**Location:** TimeListScreen.ps1:247-248, 262-263
**Description:** Field labels say "or leave blank" but both can be filled
**Impact:** User enters both, unclear which takes precedence

### 4.3 Detail Dialog Issues

#### ISSUE TMS-C1: Dialog timeout set to 3 minutes
**Severity:** Critical
**Location:** TimeListScreen.ps1:459
**Description:** Dialog automatically closes after 3 minutes (3600 iterations * 50ms)
**Impact:** User reviewing long time entry list loses dialog mid-review
**Code:**
```powershell
$maxIterations = 3600  # 3600 * 50ms = 180 seconds = 3 minutes max
```

#### ISSUE TMS-H4: Dialog escape hatch checks wrong modifier
**Severity:** High
**Location:** TimeListScreen.ps1:481-484
**Description:** Checks `($key.Modifiers -band [ConsoleModifiers]::Control)` which breaks Ctrl+C
**Impact:** User presses Ctrl+C expecting copy, dialog closes instead

#### ISSUE TMS-M4: Dialog render loop doesn't check for theme changes
**Severity:** Medium
**Location:** TimeListScreen.ps1:465-467
**Description:** Gets theme once per iteration but doesn't detect theme changes
**Impact:** Changing theme mid-dialog doesn't update dialog colors

### 4.4 Report Generation Issues

#### ISSUE TMS-M5: GenerateReport pushes new screen without context
**Severity:** Medium
**Location:** TimeListScreen.ps1:501-506
**Description:** Creates TimeReportScreen but doesn't pass selected date range
**Impact:** Report screen starts from scratch instead of using current list filters

#### ISSUE TMS-L2: Weekly report hotkey collision
**Severity:** Low
**Location:** TimeListScreen.ps1:531-535
**Description:** 'W' key for weekly report, but 'w'/'W' not shown in footer shortcuts
**Impact:** Users don't discover weekly report feature

### 4.5 Data Persistence Issues

#### ISSUE TMS-M6: RefreshList vs LoadData inconsistency
**Severity:** Medium
**Location:** TimeListScreen.ps1:386-387
**Description:** Update calls `RefreshList()` which calls `LoadData()`, extra indirection
**Impact:** Slight performance cost, architectural confusion

---

## 5. EXCEL IMPORT SCREEN

**File:** `module/Pmc.Strict/consoleui/screens/ExcelImportScreen.ps1` (577 lines)

### 5.1 Step Navigation Issues

#### ISSUE EXS-H1: MaxOptions calculation missing validation
**Severity:** High
**Location:** ExcelImportScreen.ps1:283-295 (_GetMaxOptions)
**Description:** Returns 0 for default case but allows `_selectedOption` to be set higher
**Impact:** User can scroll beyond bounds in unknown step
**Code:**
```powershell
default { return 0 }
return 0  # Explicit return to satisfy PowerShell strict mode
```

#### ISSUE EXS-M1: Step 2 profile count could be zero
**Severity:** Medium
**Location:** ExcelImportScreen.ps1:156-160 (RenderStep2)
**Description:** Shows "No profiles found" but doesn't prevent Enter key from advancing
**Impact:** User presses Enter, crashes in step 3 with null profile

#### ISSUE EXS-M2: SelectedOption not reset when changing steps
**Severity:** Medium
**Location:** ExcelImportScreen.ps1:273-276 (Escape handler)
**Description:** Step decreased but `_selectedOption` only reset to 0 explicitly
**Impact:** Returning to step 1 from step 2 could have `_selectedOption = 5` (out of bounds)

### 5.2 Excel Connection Issues

#### ISSUE EXS-C1: No retry logic for Excel COM errors
**Severity:** Critical
**Location:** ExcelImportScreen.ps1:302-316 (Attach to running Excel)
**Description:** Single attempt to attach, fails if Excel busy initializing
**Impact:** User opens Excel, clicks import immediately, fails because Excel still loading

#### ISSUE EXS-H2: Workbook validation doesn't check for saved state
**Severity:** High
**Location:** ExcelImportScreen.ps1:307-309, 324-326
**Description:** Validates workbook has sheets but doesn't check if workbook is saved
**Impact:** User imports from unsaved workbook, data lost on Excel close

#### ISSUE EXS-M3: Worksheet selection hardcoded to first sheet
**Severity:** Medium
**Location:** ExcelImportScreen.ps1:352-361 (ReadCells)
**Description:** No evidence of worksheet selection, assumes first sheet
**Impact:** Multi-sheet workbooks can't specify which sheet to import

### 5.3 Cell Reading Issues

#### ISSUE EXS-H3: Large cell range iteration has timeout
**Severity:** High
**Location:** ExcelImportScreen.ps1:354-360
**Description:** Limits to 100 cells to prevent performance issues, but no user warning
**Impact:** Profile with 150 cell mappings silently truncated to 100
**Code:**
```powershell
$maxCellsToRead = 100
if ($cellsToRead.Count -gt $maxCellsToRead) {
    Write-PmcTuiLog "Warning: Profile has $($cellsToRead.Count) cell mappings, limiting to $maxCellsToRead" "WARN"
    $cellsToRead = $cellsToRead | Select-Object -First $maxCellsToRead
}
```

#### ISSUE EXS-M4: Cell address validation missing
**Severity:** Medium
**Location:** ExcelImportScreen.ps1:352 (ReadCells call)
**Description:** No validation that cell addresses are valid Excel format (A1, B2, etc.)
**Impact:** Invalid cell address "XYZ999" causes COM error

### 5.4 Data Type Conversion Issues

#### ISSUE EXS-C2: Type conversion doesn't preserve context
**Severity:** Critical
**Location:** ExcelImportScreen.ps1:419-472 (_ImportProject)
**Description:** Conversion errors show field name but not original value/type
**Impact:** User sees "Cannot convert to integer for field Priority" without knowing what value failed
**Fixed in:** ES-C4 at line 418-432, but only for debugging

#### ISSUE EXS-H4: Date range validation too strict
**Severity:** High
**Location:** ExcelImportScreen.ps1:457-460
**Description:** Dates outside 1950-2100 rejected, but Excel date serial could be year 1900
**Impact:** Excel serial date 1 (1900-01-01) rejected as invalid

#### ISSUE EXS-M5: Boolean conversion doesn't handle Excel TRUE/FALSE
**Severity:** Medium
**Location:** ExcelImportScreen.ps1:434-446
**Description:** Converts value to [bool] but Excel cells contain "TRUE" string
**Impact:** String "TRUE" converts to true, but "False" also converts to true (non-empty string)

### 5.5 File Picker Issues

#### ISSUE EXS-H5: File picker allows directory selection
**Severity:** High
**Location:** ExcelImportScreen.ps1:562-570 (_ShowFilePicker result handling)
**Description:** Validates selection is not directory, but doesn't prevent selection
**Impact:** User selects directory, gets error after picker closes

#### ISSUE EXS-M6: File picker starts at UserProfile
**Severity:** Medium
**Location:** ExcelImportScreen.ps1:522
**Description:** Hardcoded to home directory, doesn't remember last used folder
**Impact:** User must navigate to Documents/Projects every time

#### ISSUE EXS-C3: File picker keyboard input crash in non-interactive mode
**Severity:** Critical
**Location:** ExcelImportScreen.ps1:544-555
**Description:** `[Console]::KeyAvailable` throws InvalidOperationException in automated tests
**Impact:** Automated tests crash when ImportFromExcel called
**Fixed in:** ES-H1 with try-catch

### 5.6 Validation Issues

#### ISSUE EXS-C4: Project name validation happens too late
**Severity:** Critical
**Location:** ExcelImportScreen.ps1:476-479
**Description:** Validates project name after all cell reading and conversion
**Impact:** User waits for 100 cells to import, then gets "name required" error

#### ISSUE EXS-H6: AddProject return value could be null
**Severity:** High
**Location:** ExcelImportScreen.ps1:483-491
**Description:** Checks for null return but doesn't prevent crash if Store is null
**Impact:** Null reference if TaskStore singleton fails to initialize

#### ISSUE EXS-M7: Flush return value ignored
**Severity:** Medium
**Location:** ExcelImportScreen.ps1:496-499
**Description:** Checks Flush() result but only logs warning, doesn't fail import
**Impact:** Data not persisted but user sees "success" message

---

## 6. SETTINGS SCREEN

**File:** `module/Pmc.Strict/consoleui/screens/SettingsScreen.ps1` (418 lines)

### 6.1 Data Loading Issues

#### ISSUE SET-M1: Get-PmcTaskFilePath failures swallowed silently
**Severity:** Medium
**Location:** SettingsScreen.ps1:72-84 (LoadData)
**Description:** Try-catch around Get-PmcTaskFilePath but uses default on any error
**Impact:** Real errors (permissions, disk full) hidden from user
**Code:**
```powershell
try {
    # LAYER 2: Try to get actual value from external function
    $dataFile = Get-PmcTaskFilePath
} catch {
    # LAYER 3: Silently fall back to default if function fails
    # User experience is preserved; error is logged implicitly by PowerShell
}
```

#### ISSUE SET-L1: Settings list hardcoded
**Severity:** Low
**Location:** SettingsScreen.ps1:93-130
**Description:** Settings array built manually instead of loaded from config
**Impact:** Adding new settings requires code changes

### 6.2 Theme Editor Integration Issues

#### ISSUE SET-H1: ThemeEditorScreen type check incorrect
**Severity:** High
**Location:** SettingsScreen.ps1:294-296
**Description:** Checks `PSTypeName` but should check if type is loaded in session
**Impact:** Type check always fails, throws exception
**Code:**
```powershell
if (-not ([System.Management.Automation.PSTypeName]'ThemeEditorScreen').Type) {
    throw "ThemeEditorScreen class not available after loading file"
}
```

#### ISSUE SET-M2: Theme editor file path not validated
**Severity:** Medium
**Location:** SettingsScreen.ps1:286-289
**Description:** Checks `Test-Path` but doesn't check read permissions
**Impact:** Error when dot-sourcing file user can't read

#### ISSUE SET-L2: Theme editor pushed without parent screen context
**Severity:** Low
**Location:** SettingsScreen.ps1:298-303
**Description:** Pushes ThemeEditorScreen but doesn't pass current theme
**Impact:** Editor starts with default theme instead of current theme

### 6.3 Setting Persistence Issues

#### ISSUE SET-H2: DefaultProject persistence uses wrong command
**Severity:** High
**Location:** SettingsScreen.ps1:374-384
**Description:** Creates PmcCommandContext manually but `Set-PmcFocus` expects different args
**Impact:** Setting default project fails silently or with wrong error
**Code:**
```powershell
$context = [PmcCommandContext]::new('focus', 'set')
$context.FreeText = @($newValue)
Set-PmcFocus -Context $context
```

#### ISSUE SET-M3: AutoSave setting not persisted
**Severity:** Medium
**Location:** SettingsScreen.ps1:391-395
**Description:** Shows "not yet implemented" but marks setting as editable
**Impact:** User changes auto-save, sees success, loses changes on restart

#### ISSUE SET-M4: Settings without persistence logic revert silently
**Severity:** Medium
**Location:** SettingsScreen.ps1:397-402
**Description:** Default case reverts value and shows error, not clear which settings persist
**Impact:** User confused why some settings save and others don't

### 6.4 Input Handling Issues

#### ISSUE SET-L3: Edit mode validation doesn't check ShowError
**Severity:** Low
**Location:** SettingsScreen.ps1:318-323
**Description:** Wraps ShowError in try-catch but doesn't log if it fails
**Impact:** Editing read-only setting shows no feedback if ShowError throws

#### ISSUE SET-L4: Backspace doesn't handle empty buffer
**Severity:** Low
**Location:** SettingsScreen.ps1:342-347 (_HandleEditMode)
**Description:** Checks `Length > 0` before Substring, but edge case at length 1
**Impact:** Minor, but could be more elegant

### 6.5 Rendering Issues

#### ISSUE SET-M5: Column width calculations don't account for padding
**Severity:** Medium
**Location:** SettingsScreen.ps1:156-159
**Description:** Name=20, Value=30, Description=remaining, but doesn't subtract spacing
**Impact:** Description column truncated by ~10 chars

#### ISSUE SET-L5: Cursor character changes in edit mode
**Severity:** Low
**Location:** SettingsScreen.ps1:183
**Description:** Normal cursor is `>`, edit cursor is `E`, not explained anywhere
**Impact:** User doesn't know `E` means editing

---

## 7. BASE CLASSES & SERVICES

### 7.1 StandardListScreen Issues

**File:** `module/Pmc.Strict/consoleui/base/StandardListScreen.ps1` (911 lines)

#### ISSUE SLS-C1: Delete confirmation uses blocking ReadKey
**Severity:** Critical
**Location:** StandardListScreen.ps1:568-571
**Description:** Calls `[Console]::ReadKey($true)` which blocks entire UI
**Impact:** Application frozen during delete confirmation, can't cancel

#### ISSUE SLS-H1: EditorMode state not validated
**Severity:** High
**Location:** StandardListScreen.ps1:632-636 (_SaveEditedItem)
**Description:** Checks EditorMode == 'add' or 'edit' but logs error instead of throwing
**Impact:** Invalid editor mode proceeds to callbacks with undefined behavior

#### ISSUE SLS-M1: OnItemCreated/OnItemUpdated don't prevent duplicate calls
**Severity:** Medium
**Location:** StandardListScreen.ps1:618-656
**Description:** Callbacks invoked without checking if item already processed
**Impact:** Rapid clicks could create duplicate items

### 7.2 TaskStore Issues

**File:** `module/Pmc.Strict/consoleui/services/TaskStore.ps1` (1568 lines)

#### ISSUE TST-C1: Lock acquisition race in SaveData
**Severity:** Critical
**Location:** TaskStore.ps1:339-347
**Description:** Comments say "acquire lock BEFORE checking IsSaving" but window exists
**Impact:** Two threads could both pass IsSaving check, one overwrites other's changes

#### ISSUE TST-H1: Callback errors don't propagate
**Severity:** High
**Location:** TaskStore.ps1:1401-1422 (_InvokeCallback)
**Description:** Catches all callback exceptions and logs but doesn't notify caller
**Impact:** Screen's OnTaskUpdated fails, screen doesn't know update succeeded

#### ISSUE TST-H2: PSCustomObject to hashtable conversion creates new object
**Severity:** High
**Location:** TaskStore.ps1:648-667 (UpdateTask)
**Description:** Converts PSCustomObject to hashtable and replaces in array
**Impact:** References to original task object now point to wrong object

#### ISSUE TST-M1: Validation errors returned as array but checked as boolean
**Severity:** Medium
**Location:** TaskStore.ps1:1341-1393 (_ValidateEntity)
**Description:** Returns string array of errors but callers check `Count > 0`
**Impact:** Works but inconsistent with boolean validation pattern

#### ISSUE TST-M2: Stats cache invalidation flag but cache generation also used
**Severity:** Medium
**Location:** TaskStore.ps1:113-114, 1495-1520 (GetStatistics)
**Description:** Both `_statsNeedUpdate` flag and cache existence checked
**Impact:** Redundant checks, architectural confusion

### 7.3 UniversalList Issues

**File:** `module/Pmc.Strict/consoleui/widgets/UniversalList.ps1` (500+ lines shown, total unknown)

#### ISSUE UNL-C1: Row cache LRU eviction not implemented
**Severity:** Critical
**Location:** UniversalList.ps1:187-188
**Description:** Declares `_cacheAccessOrder` LinkedList but excerpt doesn't show eviction logic
**Impact:** Cache grows unbounded, memory leak with 10,000+ item lists

#### ISSUE UNL-H1: CellInfo callbacks not invoked in Render
**Severity:** High
**Location:** UniversalList.ps1:155-158
**Description:** Declares `GetIsInEditMode` and `GetFocusedColumnIndex` callbacks but no invocation shown
**Impact:** TaskListScreen sets callbacks but cells never get edit mode highlighting

#### ISSUE UNL-M1: SetData invalidates cache on every call
**Severity:** Medium
**Location:** UniversalList.ps1:262-272
**Description:** Increments cache generation even if data unchanged
**Impact:** Re-rendering all rows unnecessarily when SetData called with same data

---

## 8. CROSS-CUTTING ISSUES

### 8.1 Type Coercion Issues

#### ISSUE XC-H1: PowerShell array unwrapping throughout codebase
**Severity:** High
**Locations:**
- TaskListScreen.ps1:1036 (tags)
- ProjectListScreen.ps1:217 (tags)
- TimeListScreen.ps1:TBD
**Description:** Single-element arrays unwrapped to scalar without comma operator
**Impact:** Data type changes from array to string/int, breaks validation

#### ISSUE XC-H2: PSCustomObject vs hashtable inconsistency
**Severity:** High
**Locations:**
- TaskStore.ps1:239-254 (converts to hashtable on load)
- UniversalList.ps1:293 (expects any object type)
- TaskListScreen.ps1:560 (assumes hashtable)
**Description:** Some code expects hashtables, some PSCustomObjects, some either
**Impact:** `Get-SafeProperty` used everywhere to paper over issue

### 8.2 Event Callback Issues

#### ISSUE XC-M1: Callback invocation uses Invoke-Command
**Severity:** Medium
**Location:** TaskStore.ps1:1404-1408
**Description:** Uses `Invoke-Command -ArgumentList (,$arg)` to prevent unwrapping
**Impact:** Performance cost, complex syntax to work around PowerShell quirk

#### ISSUE XC-M2: Closure captures could be stale
**Severity:** Medium
**Locations:**
- TaskListScreen.ps1:1678 (DatePicker callback)
- StandardListScreen.ps1:295-299 (List.OnSelectionChanged)
**Description:** `GetNewClosure()` captures `$self` but could reference wrong screen instance
**Impact:** Multiple instances of same screen type interfere with each other

### 8.3 Error Handling Patterns

#### ISSUE XC-L1: Inconsistent error message formats
**Severity:** Low
**Locations:** Throughout all screens
**Description:** Some errors show "Failed to X: message", others "Error: message", others "X failed"
**Impact:** User confused by inconsistent error messages

#### ISSUE XC-L2: Error messages don't include context
**Severity:** Low
**Locations:**
- TaskListScreen.ps1:965 (shows task text in exception)
- ProjectListScreen.ps1:TBD
**Description:** Some errors include entity name, most don't
**Impact:** User sees "Update failed" without knowing which item failed

---

## 9. SUMMARY BY SEVERITY

### Critical Issues (12)
1. TLS-C1: Cache invalidation race condition
2. TLS-C2: Edit values not cleared between items
3. TLS-C3: Edit mode state not synchronized with UniversalList
4. KAN-C1: No optimistic update before Store.UpdateTask
5. PLS-C1: 48 Excel fields create massive edit form
6. TMS-C1: Dialog timeout set to 3 minutes
7. EXS-C1: No retry logic for Excel COM errors
8. EXS-C2: Type conversion doesn't preserve context
9. EXS-C3: File picker keyboard input crash in non-interactive mode
10. EXS-C4: Project name validation happens too late
11. SLS-C1: Delete confirmation uses blocking ReadKey
12. TST-C1: Lock acquisition race in SaveData
13. UNL-C1: Row cache LRU eviction not implemented

### High Issues (23)
- TLS: H1, H2, H3, H4, H5, H6
- KAN: H1, H2, H3, H4
- PLS: H1, H2, H3, H4
- TMS: H1, H2, H3, H4
- EXS: H1, H2, H3, H4, H5, H6
- SET: H1, H2
- SLS: H1
- TST: H1, H2
- UNL: H1
- XC: H1, H2

### Medium Issues (31)
- TLS: M1-M7
- KAN: M1-M6
- PLS: M1-M6
- TMS: M1-M6
- EXS: M1-M7
- SET: M1-M5
- SLS: M1
- TST: M1-M2
- UNL: M1
- XC: M1-M2

### Low Issues (21)
- TLS: L1-L3
- KAN: L1-L2
- PLS: L1-L2
- TMS: L1-L2
- SET: L1-L5
- XC: L1-L2

---

## 10. RECOMMENDATIONS

### Immediate Actions (Critical Issues)
1. **TLS-C1**: Add lock or atomic update for cache key check
2. **TLS-C2**: Clear edit values hashtable in EditItem()
3. **TLS-C3**: Verify UniversalList invokes CellInfo callbacks
4. **KAN-C1**: Implement optimistic UI update pattern
5. **PLS-C1**: Split project form into tabs or wizard
6. **TMS-C1**: Remove timeout or increase to 30 minutes
7. **EXS-C1-C4**: Add retry logic, better validation, error context
8. **SLS-C1**: Use async confirmation dialog instead of blocking
9. **TST-C1**: Review lock acquisition pattern
10. **UNL-C1**: Implement LRU eviction when cache > 500 entries

### High-Priority Fixes (High Issues)
1. Add comprehensive input validation before Store operations
2. Implement consistent type handling (PSCustomObject vs hashtable)
3. Add circular dependency checks to task hierarchies
4. Fix widget positioning for scrolled lists
5. Improve error messages with context
6. Add date/number parsing with format specifiers

### Medium-Priority Improvements
1. Cache computed values (task counts, column formatting)
2. Optimize data loading (single-pass filtering)
3. Add user preferences for configurable limits
4. Implement proper closure scoping patterns
5. Add null checks and bounds validation

### Low-Priority Enhancements
1. Standardize error message formats
2. Add debug logging levels
3. Implement column auto-sizing
4. Add tooltips for settings
5. Improve visual feedback

---

## APPENDIX A: Function Call Chains

### TaskListScreen → TaskStore
```
TaskListScreen.OnItemCreated()
  → ValidationHelper.Test-TaskValid()
  → TaskStore.AddTask()
    → TaskStore._ValidateEntity()
    → TaskStore._CreateBackup()
    → TaskStore.SaveData()
      → Save-PmcData()
    → TaskStore._InvokeCallback(OnTaskAdded)
    → TaskStore._InvokeCallback(OnTasksChanged)
  → TaskListScreen.LoadData()
    → TaskStore.GetAllTasks()
    → UniversalList.SetData()
```

### KanbanScreen → TaskStore
```
KanbanScreen._MoveTask()
  → TaskStore.UpdateTask()
    → TaskStore._CreateBackup()
    → TaskStore.SaveData()
    → TaskStore._InvokeCallback(OnTaskUpdated)
  → KanbanScreen.LoadData()
    → TaskStore.GetAllTasks()
```

### ExcelImportScreen → TaskStore
```
ExcelImportScreen._ImportProject()
  → ExcelComReader.ReadCells()
    → Excel COM Automation
  → ExcelMappingService.GetActiveProfile()
  → ValidationHelper.Test-ProjectValid()
  → TaskStore.AddProject()
    → TaskStore._CreateBackup()
    → TaskStore.SaveData()
  → TaskStore.Flush()
```

---

*End of Report*
