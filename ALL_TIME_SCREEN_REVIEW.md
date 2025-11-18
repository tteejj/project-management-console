# All Time Screen Implementation Review
## Complete Analysis of Time-Related Screens in Project Management Console

**Review Date:** 2025-11-18  
**Status:** Comprehensive review complete  
**Important Note:** There is no dedicated "All Time" screen. The time-related functionality is split across three screens:
1. **TimeListScreen** - Main time tracking list with CRUD operations
2. **TimeReportScreen** - Summary report grouped by project
3. **WeeklyTimeReportScreen** - Weekly breakdown with daily columns

---

## Executive Summary

**Total Issues Found:** 13 issues across time-related screens  
**Critical Issues:** 2  
**High Priority Issues:** 3  
**Medium Priority Issues:** 5  
**Low Priority Issues:** 3  

### Key Problems Identified:
1. Inconsistent Invoke-Expression usage (security risk)
2. Missing error handling in dialog loops
3. Incomplete feature implementations
4. Type conversion without proper validation
5. Null reference potential in date parsing

---

## DETAILED ANALYSIS BY SCREEN

### 1. TIME LIST SCREEN (TimeListScreen.ps1)
**Primary File:** `/home/user/project-management-console/module/Pmc.Strict/consoleui/screens/TimeListScreen.ps1`  
**Lines of Code:** 495 total

#### ISSUE TLS-1 [CRITICAL]: Invoke-Expression in GetCustomActions
- **Location:** `TimeListScreen.ps1:386`
- **Function:** `GetCustomActions() -> W key callback`
- **Problem:** Uses Invoke-Expression for object instantiation
- **Code:**
```powershell
@{ Key='w'; Label='Week Report'; Callback={
    . "$PSScriptRoot/WeeklyTimeReportScreen.ps1"
    $screen = Invoke-Expression '[WeeklyTimeReportScreen]::new()'  # DANGEROUS!
    $self.App.PushScreen($screen)
}.GetNewClosure() }
```
- **Impact:** Security vulnerability - code injection possible if class name becomes variable
- **Severity:** CRITICAL
- **Fix:** Replace with direct instantiation: `$screen = [WeeklyTimeReportScreen]::new()`

#### ISSUE TLS-2 [HIGH]: Inconsistent Instantiation Pattern
- **Location:** `TimeListScreen.ps1:386 vs 487`
- **Function:** GetCustomActions() vs HandleKeyPress()
- **Problem:** Same screen instantiated differently in two places
- **Code Location 1 (Line 386 - GetCustomActions):**
```powershell
$screen = Invoke-Expression '[WeeklyTimeReportScreen]::new()'  # WRONG
```
- **Code Location 2 (Line 487 - HandleKeyPress):**
```powershell
$screen = [WeeklyTimeReportScreen]::new()  # CORRECT
```
- **Impact:** Inconsistent code patterns, maintenance burden
- **Severity:** HIGH
- **Trace:**
  - TimeListScreen.HandleKeyPress() -> 'W' key
  - TimeListScreen.GetCustomActions() -> 'w' key callback
  - Both route to same screen but use different instantiation methods

#### ISSUE TLS-3 [MEDIUM]: Date Parsing Error Handling
- **Location:** `TimeListScreen.ps1:99-113`
- **Function:** `LoadItems()`
- **Problem:** DateTime parsing with improper error handling and fallback
- **Code:**
```powershell
$dateStr = ''
if ($entry.ContainsKey('date') -and $entry.date) {
    try {
        if ($entry.date -is [DateTime]) {
            $dateStr = $entry.date.ToString('yyyy-MM-dd')
        } else {
            # Try to parse as DateTime
            $parsedDate = [DateTime]::Parse($entry.date)
            $dateStr = $parsedDate.ToString('yyyy-MM-dd')
        }
    } catch {
        Write-PmcTuiLog "TimeListScreen.LoadItems: Failed to parse date '$($entry.date)': $_" "WARNING"
        $dateStr = ''  # Falls back to empty string
    }
}
```
- **Impact:** 
  - Empty string grouping key loses data context
  - All unparseable dates grouped together incorrectly
  - No user notification of problematic entries
- **Severity:** MEDIUM
- **Recommendation:** Log count of failed parses and show warning if significant

#### ISSUE TLS-4 [HIGH]: Potential Null Reference in Duration Calculation
- **Location:** `TimeListScreen.ps1:177-184`
- **Function:** `LoadItems() -> duration formatting`
- **Problem:** Assumes minutes exists and is numeric
- **Code:**
```powershell
$minutes = [int][Math]::Floor($entry.minutes / 60)  # Crashes if entry.minutes is null or string
$mins = [int]($entry.minutes % 60)
$entry['duration'] = "{0:D2}:{1:D2}" -f $hours, $mins
```
- **Impact:** NullReferenceException or type mismatch could crash screen
- **Severity:** HIGH
- **Trace:**
  1. LoadItems() -> foreach entry
  2. $entry.minutes might be missing or wrong type
  3. Line 177: [Math]::Floor() throws if null
  4. Screen crashes with no error message to user

#### ISSUE TLS-5 [MEDIUM]: Aggregation Logic Complexity
- **Location:** `TimeListScreen.ps1:96-169`
- **Function:** `LoadItems() -> grouping and aggregation`
- **Problem:** Complex nested logic for grouping entries
- **Details:**
  - Multiple passes over data
  - String concatenation for task/notes aggregation (fragile)
  - Grouping key format: `"$dateStr|$project|$timecode"` (could be brittle)
- **Potential Issues:**
  - If date parsing fails, all entries with empty date grouped together
  - Task names with pipes (|) in them break grouping
  - Notes concatenation could create very long strings
- **Severity:** MEDIUM
- **Recommendation:** Validate grouping key has no special characters

#### ISSUE TLS-6 [MEDIUM]: ShowDetailDialog Potential Infinite Loop Protection
- **Location:** `TimeListScreen.ps1:413-448`
- **Function:** `ShowDetailDialog()`
- **Problem:** Dialog render loop with timeout but no escape guarantee
- **Code:**
```powershell
$maxIterations = 120000  # 120000 * 50ms = 100 minutes max
$iterations = 0

while (-not $dialog.IsComplete -and $iterations -lt $maxIterations) {
    $iterations++
    # ... render and input handling ...
    if ($key.Key -eq 'Escape' -or ($key.Modifiers -band [ConsoleModifiers]::Control)) {
        $dialog.IsComplete = $true
        break
    }
    Start-Sleep -Milliseconds 50
}
```
- **Issues:**
  - 100-minute timeout is extremely long (should be 1-5 minutes)
  - No visual feedback if timeout occurs
  - Dialog blocks entire application during interaction
- **Severity:** MEDIUM
- **Fix:** Reduce maxIterations to 3600 (3 minutes) and show warning message

#### ISSUE TLS-7 [LOW]: Missing Null Check on Dialog Creation
- **Location:** `TimeListScreen.ps1:411`
- **Function:** `ShowDetailDialog()`
- **Problem:** TimeEntryDetailDialog created without error handling
- **Code:**
```powershell
$dialog = [TimeEntryDetailDialog]::new($title, $item.original_entries)
# Could fail if class not loaded
```
- **Severity:** LOW
- **Fix:** Wrap in try-catch

#### ISSUE TLS-8 [MEDIUM]: OnItemUpdated Doesn't Refresh After Update
- **Location:** `TimeListScreen.ps1:349`
- **Function:** `OnItemUpdated()`
- **Code:**
```powershell
if ($success) {
    $this.SetStatusMessage("Time entry updated", "success")
    $this.LoadData()  # Reloads ALL data - inefficient for large datasets
} else {
    $this.SetStatusMessage("Failed to update time entry: $($this.Store.LastError)", "error")
}
```
- **Impact:** 
  - LoadData() reloads entire dataset even though only one entry changed
  - Performance issue with 1000+ time entries
  - Visual glitch if scroll position changes
- **Severity:** MEDIUM
- **Recommendation:** Just call $this.RefreshList() or update data in-place

#### ISSUE TLS-9 [INFO]: Good Hour Range Validation
- **Location:** `TimeListScreen.ps1:251-258, 314-321`
- **Functions:** `OnItemCreated()` and `OnItemUpdated()`
- **Status:** ✓ CORRECTLY validates hour ranges
- **Code:**
```powershell
if ($hoursValue -le 0) {
    $this.SetStatusMessage("Hours must be greater than 0", "error")
    return
}
if ($hoursValue -gt 24) {
    $this.SetStatusMessage("Hours must be 24 or less", "error")
    return
}
```
- **Note:** This was improved from the original comprehensive review

---

### 2. TIME REPORT SCREEN (TimeReportScreen.ps1)
**File:** `/home/user/project-management-console/module/Pmc.Strict/consoleui/screens/TimeReportScreen.ps1`  
**Lines of Code:** 341

#### ISSUE TRP-1 [CRITICAL]: Invoke-Expression in HandleKeyPress
- **Location:** `TimeReportScreen.ps1:321`
- **Function:** `HandleKeyPress() -> 'W' key`
- **Problem:** Uses Invoke-Expression for object instantiation
- **Code:**
```powershell
if ($keyInfo.Key -eq ([ConsoleKey]::W)) {
    . "$PSScriptRoot/WeeklyTimeReportScreen.ps1"
    $screen = Invoke-Expression '[WeeklyTimeReportScreen]::new()'  # DANGEROUS!
    $global:PmcApp.PushScreen($screen)
    return $true
}
```
- **Impact:** Security vulnerability - potential code injection
- **Severity:** CRITICAL
- **Fix:** Replace with: `$screen = [WeeklyTimeReportScreen]::new()`

#### ISSUE TRP-2 [MEDIUM]: Grouping by Project Name Only
- **Location:** `TimeReportScreen.ps1:91`
- **Function:** `LoadData()`
- **Problem:** Assumes project name is unique identifier
- **Code:**
```powershell
$grouped = $timelogs | Group-Object -Property project | Sort-Object Name
```
- **Impact:** 
  - If multiple projects have same name (unlikely but possible)
  - No aggregation by project ID
  - May show duplicate project names
- **Severity:** MEDIUM
- **Recommendation:** Group by ID if available, fallback to name

#### ISSUE TRP-3 [MEDIUM]: No Handle for Zero Time Entries
- **Location:** `TimeReportScreen.ps1:82-87`
- **Function:** `LoadData()`
- **Problem:** Silent handling of empty data
- **Code:**
```powershell
if ($timelogs.Count -eq 0) {
    $this.ProjectSummaries = @()
    $this.TotalMinutes = 0
    $this.TotalHours = 0
    $this.ShowStatus("No time entries to report")
    return
}
```
- **Impact:** User might not see report data and be confused
- **Severity:** MEDIUM (but acceptable for empty state)
- **Note:** _RenderEmptyState() handles this appropriately

#### ISSUE TRP-4 [LOW]: Inefficient Math for Hours Conversion
- **Location:** `TimeReportScreen.ps1:98, 109`
- **Function:** `LoadData()`
- **Problem:** Repeated calculation of hours from minutes
- **Code:**
```powershell
$minutes = ($group.Group | Measure-Object -Property minutes -Sum).Sum
$hours = [Math]::Round($minutes / 60.0, 2)  # Calculated here
$this.TotalMinutes += $minutes

# ...later...
$this.TotalHours = [Math]::Round($this.TotalMinutes / 60.0, 2)  # Recalculated
```
- **Impact:** Slight performance impact, inconsistent rounding
- **Severity:** LOW
- **Recommendation:** Calculate TotalHours after summing TotalMinutes

---

### 3. WEEKLY TIME REPORT SCREEN (WeeklyTimeReportScreen.ps1)
**File:** `/home/user/project-management-console/module/Pmc.Strict/consoleui/screens/WeeklyTimeReportScreen.ps1`  
**Lines of Code:** 410

#### ISSUE WTR-1 [HIGH]: Unsafe DateTime Cast Without Error Handling
- **Location:** `WeeklyTimeReportScreen.ps1:176`
- **Function:** `LoadData() -> day index calculation`
- **Problem:** Direct cast without try-catch
- **Code:**
```powershell
$logDate = [datetime]$log.date  # Can throw if date format is invalid
$dayIndex = ($logDate.DayOfWeek.value__ + 6) % 7
```
- **Impact:** If log.date is invalid format, screen crashes
- **Severity:** HIGH
- **Trace:**
  1. LoadData() called
  2. Foreach $log in $weekLogs
  3. Line 176: [datetime] cast throws on invalid format
  4. Screen crashes

#### ISSUE WTR-2 [MEDIUM]: No Validation of Day Index Calculation
- **Location:** `WeeklyTimeReportScreen.ps1:177-186`
- **Function:** `LoadData() -> day aggregation`
- **Problem:** Switch statement on calculated dayIndex without bounds check
- **Code:**
```powershell
$dayIndex = ($logDate.DayOfWeek.value__ + 6) % 7  # Returns 0-6
switch ($dayIndex) {
    0 { $this.ProjectSummaries[$key].Mon += $hours }
    1 { $this.ProjectSummaries[$key].Tue += $hours }
    2 { $this.ProjectSummaries[$key].Wed += $hours }
    3 { $this.ProjectSummaries[$key].Thu += $hours }
    4 { $this.ProjectSummaries[$key].Fri += $hours }
    # No default - what about Sat/Sun?
}
```
- **Impact:** 
  - If date is Saturday or Sunday, hours are silently dropped
  - No warning to user about lost data
  - Weekly report shows incomplete hours
- **Severity:** MEDIUM
- **Recommendation:** Add warning or include weekend columns

#### ISSUE WTR-3 [MEDIUM]: Hardcoded Monday-Friday Only
- **Location:** `WeeklyTimeReportScreen.ps1:122-133`
- **Function:** `LoadData() -> week loop`
- **Problem:** Only processes Monday-Friday (5 days)
- **Code:**
```powershell
for ($d = 0; $d -lt 5; $d++) {  # Only 5 days, Mon-Fri
    $dayDate = $this.WeekStart.AddDays($d).ToString('yyyy-MM-dd')
    # ...
}
```
- **Impact:**
  - Weekend time entries completely ignored
  - No way to log time on Saturday/Sunday
  - Report is incomplete for 7-day operations
- **Severity:** MEDIUM
- **Recommendation:** Make it 7-day week or make configurable

#### ISSUE WTR-4 [MEDIUM]: Plural Logic Could Be Clearer
- **Location:** `WeeklyTimeReportScreen.ps1:109-115`
- **Function:** `LoadData() -> week indicator formatting`
- **Problem:** Complex plural logic could be simplified
- **Code:**
```powershell
if ($this.WeekOffset -lt 0) {
    $weeks = [Math]::Abs($this.WeekOffset)
    $plural = if ($weeks -gt 1) { 's' } else { '' }
    $this.WeekIndicator = " ($weeks week$plural ago)"
} else {
    $plural = if ($this.WeekOffset -gt 1) { 's' } else { '' }
    $this.WeekIndicator = " ($($this.WeekOffset) week$plural from now)"
}
```
- **Impact:** Minor - just readability
- **Severity:** LOW
- **Note:** Logic is correct, just verbose

#### ISSUE WTR-5 [LOW]: Missing Null Check on Hash Initialization
- **Location:** `WeeklyTimeReportScreen.ps1:151-172`
- **Function:** `LoadData() -> project summary initialization`
- **Problem:** Assumes $log.id1, $log.project exist
- **Code:**
```powershell
if (-not $this.ProjectSummaries.ContainsKey($key)) {
    $name = ''
    $id1 = ''
    if ($log.id1) {  # Could be null
        $id1 = $log.id1
        $name = $log.project  # Could be null
    } else {
        $name = $log.project  # Could be null
        if (-not $name) { $name = 'Unknown' }  # Only fallback here
    }
    # ...
}
```
- **Impact:** 'Unknown' might be used inconsistently
- **Severity:** LOW
- **Recommendation:** Add explicit null/empty checks

#### ISSUE WTR-6 [INFO]: Good Name Truncation
- **Location:** `WeeklyTimeReportScreen.ps1:302-305`
- **Function:** `_RenderReport() -> name formatting`
- **Status:** ✓ CORRECTLY truncates long project names
- **Code:**
```powershell
$name = $d.Name
if ($name.Length -gt 20) {
    $name = $name.Substring(0, 17) + "..."
}
```

---

## CROSS-CUTTING ISSUES (Affecting Multiple Time Screens)

### CC-TM-1 [CRITICAL]: Invoke-Expression Security Risk
**Affected Screens:**
- TimeListScreen.ps1:386 (GetCustomActions)
- TimeReportScreen.ps1:321 (HandleKeyPress)

**Problem:** Two instances of dangerous Invoke-Expression usage

**Recommended Fix:** All instances should use direct instantiation
```powershell
# BEFORE (dangerous)
$screen = Invoke-Expression '[WeeklyTimeReportScreen]::new()'

# AFTER (safe)
$screen = [WeeklyTimeReportScreen]::new()
```

### CC-TM-2 [HIGH]: Type Conversion Without Validation
**Affected Screens:**
- TimeListScreen (LoadItems, OnItemCreated, OnItemUpdated)
- WeeklyTimeReportScreen (LoadData)

**Problem:** Multiple places assume numeric/datetime conversions succeed

**Examples:**
- TimeListScreen.ps1:177 - `[Math]::Floor($entry.minutes / 60)` 
- WeeklyTimeReportScreen.ps1:176 - `[datetime]$log.date`

### CC-TM-3 [MEDIUM]: Date Parsing Consistency
**Affected Screens:**
- TimeListScreen (LoadItems)
- WeeklyTimeReportScreen (LoadData)

**Problem:** Different approaches to date string formatting

**TimeListScreen:**
```powershell
if ($entry.date -is [DateTime]) {
    $dateStr = $entry.date.ToString('yyyy-MM-dd')
} else {
    $parsedDate = [DateTime]::Parse($entry.date)
    $dateStr = $parsedDate.ToString('yyyy-MM-dd')
}
```

**WeeklyTimeReportScreen:**
```powershell
$logDate = [datetime]$log.date  # Direct cast, no try-catch
$dateStr = if ($_.date -is [DateTime]) {
    $_.date.ToString('yyyy-MM-dd')
} else {
    $_.date
}
```

---

## FUNCTION CALL TRACE

### Complete Call Chain for Time Report Generation

```
TimeListScreen.GenerateReport()
    -> [Load TimeReportScreen.ps1]
    -> Create: [TimeReportScreen]::new()
    -> App.PushScreen($screen)
        
[TimeReportScreen lifecycle]
    -> OnEnter()
        -> LoadData()
            -> TaskStore.GetAllTimeLogs()
                -> Monitor.Enter/Exit (thread-safe)
                -> Return $this._data.timelogs.ToArray()
            -> Group-Object -Property project
            -> For each group:
                -> Measure-Object -Property minutes -Sum
                -> Calculate hours (minutes / 60)
            -> RenderEngine.RequestClear()
    -> RenderContent()
        -> _RenderReport() [for non-empty case]
            -> Build ANSI string with colors
            -> Display table with headers/rows/totals
```

### Complete Call Chain for Weekly Report

```
TimeListScreen.HandleKeyPress('W')
    -> . "$PSScriptRoot/WeeklyTimeReportScreen.ps1"
    -> Create: [WeeklyTimeReportScreen]::new()  // SHOULD NOT USE Invoke-Expression
    -> $this.App.PushScreen($screen)

[WeeklyTimeReportScreen lifecycle]
    -> OnEnter()
        -> LoadData()
            -> Get current week based on WeekOffset
            -> Calculate $this.WeekStart (Monday)
            -> TaskStore.GetAllTimeLogs()
            -> Filter logs for Mon-Fri only
            -> For each log:
                -> Parse date: [datetime]$log.date  // RISK: No error handling
                -> Calculate day index: ($logDate.DayOfWeek.value__ + 6) % 7
                -> Switch $dayIndex (0-4 only, Sat/Sun lost!)
                -> Aggregate hours by project/day
            -> RenderEngine.RequestClear()
    -> RenderContent()
        -> _RenderReport()
            -> Display week header with offset indicator
            -> Display table with columns: Mon, Tue, Wed, Thu, Fri, Total
```

---

## ISSUES SUMMARY TABLE

| ID | Screen | Location | Issue | Severity |
|----|--------|----------|-------|----------|
| TLS-1 | TimeListScreen | 386 | Invoke-Expression in callback | CRITICAL |
| TLS-2 | TimeListScreen | 386 vs 487 | Inconsistent instantiation | HIGH |
| TLS-3 | TimeListScreen | 99-113 | Date parsing fallback logic | MEDIUM |
| TLS-4 | TimeListScreen | 177-184 | Null reference in minutes | HIGH |
| TLS-5 | TimeListScreen | 96-169 | Aggregation complexity | MEDIUM |
| TLS-6 | TimeListScreen | 413-448 | Long dialog timeout | MEDIUM |
| TLS-7 | TimeListScreen | 411 | No error handling on dialog creation | LOW |
| TLS-8 | TimeListScreen | 349 | Inefficient LoadData after update | MEDIUM |
| TRP-1 | TimeReportScreen | 321 | Invoke-Expression in key handler | CRITICAL |
| TRP-2 | TimeReportScreen | 91 | Group by name only | MEDIUM |
| TRP-3 | TimeReportScreen | 82-87 | Silent empty state | MEDIUM |
| TRP-4 | TimeReportScreen | 98, 109 | Inefficient hours calculation | LOW |
| WTR-1 | WeeklyTimeReportScreen | 176 | Unsafe datetime cast | HIGH |
| WTR-2 | WeeklyTimeReportScreen | 177-186 | No weekend support | MEDIUM |
| WTR-3 | WeeklyTimeReportScreen | 122-133 | Hardcoded Mon-Fri | MEDIUM |
| WTR-4 | WeeklyTimeReportScreen | 109-115 | Complex plural logic | LOW |
| WTR-5 | WeeklyTimeReportScreen | 151-172 | Missing null checks | LOW |

---

## RECOMMENDATIONS BY PRIORITY

### IMMEDIATE (Next Sprint)

1. **Fix Invoke-Expression Security Issues** (TLS-1, TRP-1)
   - Replace both instances with direct instantiation
   - Search entire codebase for other Invoke-Expression usage
   - Estimated effort: 1 hour

2. **Add DateTime Error Handling** (WTR-1)
   - Wrap `[datetime]$log.date` in try-catch
   - Add logging of failed conversions
   - Estimated effort: 1 hour

3. **Standardize Date Parsing** (TLS-3, WTR-1)
   - Use consistent approach across all time screens
   - Recommend: Try-catch with fallback to original value
   - Estimated effort: 2 hours

### SHORT-TERM (1-2 Sprints)

4. **Fix Null Reference Issues** (TLS-4, WTR-5)
   - Add explicit null checks before type operations
   - Use Get-SafeProperty helper function
   - Estimated effort: 2 hours

5. **Improve Dialog Timeout** (TLS-6)
   - Reduce maxIterations to 3600 (3 minutes)
   - Add timeout warning message
   - Estimated effort: 1 hour

6. **Add Weekend Support** (WTR-2, WTR-3)
   - Extend weekly report to 7 days
   - Add Saturday/Sunday columns
   - Estimated effort: 3 hours

7. **Optimize Update Refresh** (TLS-8)
   - Replace LoadData with RefreshList or targeted update
   - Estimated effort: 1 hour

### LONG-TERM (Backlog)

8. Refactor aggregation logic for clarity (TLS-5)
9. Add project grouping by ID when available (TRP-2)
10. Improve error reporting for missing data

---

## TESTING RECOMMENDATIONS

### Unit Tests
- [ ] Date parsing with various formats
- [ ] Hours to minutes conversion
- [ ] Day index calculation for date math
- [ ] Grouping logic with edge cases (empty dates, duplicate projects)

### Integration Tests
- [ ] Load time entries with invalid dates
- [ ] Generate report with no data
- [ ] Navigate weeks forward and backward
- [ ] Aggregate entries across date/project/timecode

### Performance Tests
- [ ] Load 1000+ time entries
- [ ] Render weekly report with 100+ projects
- [ ] Memory usage during aggregation

### Security Tests
- [ ] Prevent code injection via class names
- [ ] Validate all user inputs
- [ ] Test with special characters in project names

---

## DETAILED ISSUE REMEDIATION

### CRITICAL ISSUES

#### 1. TLS-1 & TRP-1: Invoke-Expression Usage

**Current Code (DANGEROUS):**
```powershell
$screen = Invoke-Expression '[WeeklyTimeReportScreen]::new()'
```

**Fixed Code:**
```powershell
$screen = [WeeklyTimeReportScreen]::new()
```

**Locations to Fix:**
- `/home/user/project-management-console/module/Pmc.Strict/consoleui/screens/TimeListScreen.ps1:386`
- `/home/user/project-management-console/module/Pmc.Strict/consoleui/screens/TimeReportScreen.ps1:321`

---

### HIGH PRIORITY ISSUES

#### 2. WTR-1: Unsafe DateTime Cast

**Current Code (RISKY):**
```powershell
$logDate = [datetime]$log.date
$dayIndex = ($logDate.DayOfWeek.value__ + 6) % 7
```

**Fixed Code:**
```powershell
$logDate = $null
try {
    $logDate = [datetime]$log.date
} catch {
    Write-PmcTuiLog "Failed to parse log date: $($log.date)" "WARNING"
    continue  # Skip this log
}
$dayIndex = ($logDate.DayOfWeek.value__ + 6) % 7
```

---

#### 3. TLS-4: Null Reference in Minutes Calculation

**Current Code (RISKY):**
```powershell
$minutes = [int][Math]::Floor($entry.minutes / 60)
$mins = [int]($entry.minutes % 60)
```

**Fixed Code:**
```powershell
$entryMinutes = if ($entry.ContainsKey('minutes') -and $null -ne $entry.minutes) {
    try { [int]$entry.minutes } catch { 0 }
} else { 0 }

$hours = [int][Math]::Floor($entryMinutes / 60)
$mins = [int]($entryMinutes % 60)
```

---

#### 4. TLS-2: Inconsistent Instantiation

**Fix:** Use direct instantiation in GetCustomActions callback

**Location:** `/home/user/project-management-console/module/Pmc.Strict/consoleui/screens/TimeListScreen.ps1:386`

**Change from:**
```powershell
$screen = Invoke-Expression '[WeeklyTimeReportScreen]::new()'
```

**Change to:**
```powershell
$screen = [WeeklyTimeReportScreen]::new()
```

---

## CONCLUSION

The time-related screens show good architectural patterns with proper use of TaskStore singleton and thread-safe operations. However, there are critical security issues (Invoke-Expression) and several data handling problems that need attention:

**Strengths:**
- Proper TaskStore integration
- Thread-safe CRUD operations
- Good error handling in some areas
- Proper event-driven updates

**Weaknesses:**
- Invoke-Expression usage (security risk)
- Type conversion without validation
- No Saturday/Sunday support
- Date parsing inconsistency
- Long timeout on dialog

**Overall Assessment:** The code needs immediate fixes for security and data integrity, but the foundation is solid.

---

**End of Review Report**
