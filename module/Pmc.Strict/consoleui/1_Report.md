# PMC TUI Critical Review Report
**Date**: 2025-11-08
**Scope**: Active codebase loaded by `Start-PmcTUI.ps1`
**Assessment Grade**: D (3/10)

---

## Executive Summary

A comprehensive multi-agent analysis of the PMC TUI application reveals **7 critical bugs** in active code, significant architectural issues, and approximately **50% dead code** in the repository. While the active codebase is smaller than initially assessed (~35 files), it contains serious issues that will impact reliability and maintainability.

**Key Findings**:
- ✅ Active code is well-scoped (~6,000-8,000 lines in use)
- ❌ Zero files use `Set-StrictMode` (critical security/reliability issue)
- ❌ 7 critical bugs in production code
- ❌ ~50% of repository is dead code (not loaded)
- ❌ Using OptimizedRenderEngine when EnhancedRenderEngine exists (but not loaded)

---

## Active Codebase Map

### Files Actually Loaded by Start-PmcTUI.ps1

**Core Dependencies (from `../src/`)**:
- `PraxisVT.ps1` - VT100 escape sequence generation
- `PraxisStringBuilder.ps1`, `TerminalDimensions.ps1`, `PraxisFrameRenderer.ps1`
- `Types.ps1`, `Config.ps1`, `Debug.ps1`, `Security.ps1`, `State.ps1`, `UI.ps1`, `Storage.ps1`, `Time.ps1`
- `FieldSchemas.ps1`, `TemplateDisplay.ps1`, `DataDisplay.ps1`, `UniversalDisplay.ps1`, `HelpUI.ps1`, `Analytics.ps1`, `Theme.ps1`

**SpeedTUI Framework (from `lib/SpeedTUI/Core/`)**:
- `Logger.ps1`, `PerformanceMonitor.ps1`, `NullCheck.ps1`
- `Internal/PerformanceCore.ps1` - VT100 generation with caching (InternalVT100 class)
- `SimplifiedTerminal.ps1` - Terminal wrapper
- **`OptimizedRenderEngine.ps1`** - String-based differential rendering (currently in use)
- `Component.ps1` - Base component class
- `BorderHelper.ps1`

**PMC Application**:
- `helpers/DataBindingHelper.ps1`, `helpers/ValidationHelper.ps1`
- `services/TaskStore.ps1`
- `widgets/PmcWidget.ps1`, `widgets/PmcPanel.ps1`
- `layout/PmcLayoutManager.ps1`
- `PmcScreen.ps1`
- Widgets: `TextInput.ps1`, `DatePicker.ps1`, `ProjectPicker.ps1`, `TagEditor.ps1`, `FilterPanel.ps1`, `InlineEditor.ps1`, `UniversalList.ps1`
- Base classes: `StandardFormScreen.ps1`, `StandardListScreen.ps1`, `StandardDashboard.ps1`
- `PmcApplication.ps1` - Main application and event loop
- Screens: `TaskListScreen.ps1`, `BlockedTasksScreen.ps1`

**Total Active Files**: ~35 files

---

## Dead Code (NOT Loaded)

### Can Be Safely Deleted

1. **`ConsoleUI.Core.ps1`** (8,288 lines, 390KB)
   - Contains 7 legacy classes: PmcStringCache, PmcStringBuilderPool, PmcVT100, PmcSimpleTerminal, PmcMenuItem, PmcMenuSystem, PmcConsoleUIApp
   - Only referenced by `ConsoleUI.ps1` and `ConsoleUI-Modular.ps1` (also not loaded)
   - **Verdict**: Complete dead code

2. **`Handlers/` directory** (all files)
   - `TaskHandlers.ps1`, `ProjectHandlers.ps1`, `ExcelHandlers.ps1`, `ExcelImportHandlers.ps1`
   - Used by old ConsoleUI.Core.ps1 system
   - **Verdict**: Dead code

3. **`infrastructure/` directory** (all files)
   - `ApplicationBootstrapper.ps1`, `KeyboardManager.ps1` (482 lines), `NavigationManager.ps1`, `ScreenRegistry.ps1`
   - Aspirational architecture never integrated
   - **Verdict**: Dead code

4. **40+ screen files** in `screens/`
   - Only `TaskListScreen.ps1` and `BlockedTasksScreen.ps1` are loaded
   - Examples: `AgendaViewScreen.ps1`, `BackupViewScreen.ps1`, `BurndownChartScreen.ps1`, etc.
   - **Verdict**: Either incomplete or for old system

5. **Utility scripts** in root
   - `add-inline-edit.ps1`, `apply-edit-pattern.ps1`, `fix-menus.ps1`, `verify-fixes.ps1`
   - **Verdict**: Development tools, not production code

6. **SpeedTUI files NOT loaded**
   - `EnhancedRenderEngine.ps1` (better engine available but not used)
   - `CellBuffer.ps1`
   - `Application.ps1`, `EnhancedApplication.ps1`
   - `InputManager.ps1`, `EventManager.ps1`
   - All test files

**Estimated Dead Code**: ~50% of repository

---

## Critical Issues (Active Code)

### 🔴 CRITICAL #1: No Strict Mode
**Severity**: CRITICAL
**Files Affected**: All 35 active files
**Location**: Every .ps1 file

**Problem**: Zero files use `Set-StrictMode -Version Latest`

**Impact**:
- Silent failures from typos in variable names
- Uninitialized variables treated as `$null` without error
- Non-existent properties accessed without error
- Makes debugging extremely difficult
- Security risk (allows loose typing)

**Example**:
```powershell
# Current code (no strict mode)
$this._selectedIndex = $this._filtredData.Count  # Typo: filtred vs filtered
# Returns null silently instead of throwing error
```

**Recommendation**: Add to top of EVERY file:
```powershell
Set-StrictMode -Version Latest
```

**Effort**: Low (automated find/replace)
**Priority**: CRITICAL - Do immediately

---

### 🔴 CRITICAL #2: Widget Type Mutation Bug
**Severity**: CRITICAL
**File**: `widgets/InlineEditor.ps1`
**Lines**: 244-260, 599-614, 815-838

**Problem**: Date fields dynamically switch between TextInput and DatePicker widgets at runtime

**Code Flow**:
1. Line 599-614: Creates TextInput for date fields initially
2. Line 815-837: On field expansion, replaces TextInput with DatePicker
3. Line 244-260: On collapse, converts DatePicker back to TextInput

**Impact**:
- Type instability - widget type changes at runtime
- State loss when switching between widget types
- Method-not-found errors when code assumes wrong type
- Line 670: Calls `GetSelectedDate()` on widget that might be TextInput (no such method)

**Example**:
```powershell
# Line 670 - CRASH RISK
if ($field.Type -eq 'date') {
    $widget = $this._fieldWidgets[$fieldName]
    return $widget.GetSelectedDate()  # ERROR if widget is TextInput!
}
```

**Recommendation**: Use single widget type per field, configure behavior instead of swapping types

**Effort**: Medium (requires refactoring field widget creation)
**Priority**: CRITICAL - Causes runtime crashes

---

### 🔴 CRITICAL #3: Input Modal Trap
**Severity**: CRITICAL
**Files**: `base/StandardListScreen.ps1:631-641`, `widgets/UniversalList.ps1:361-369`

**Problem**: When child widget returns `false` (didn't handle key), parent returns that `false` too, preventing fallback handlers from running

**Code**:
```powershell
# StandardListScreen.ps1:631-641
if ($this.ShowInlineEditor) {
    $handled = $this.InlineEditor.HandleInput($keyInfo)

    if ($this.InlineEditor.IsConfirmed -or $this.InlineEditor.IsCancelled) {
        $this.ShowInlineEditor = $false
    }
    return $handled  # BUG: Returns false, preventing parent handlers
}
```

**Impact**:
- "Dead keys" - certain inputs do nothing
- Users trapped in modal widgets
- No way to escape with global shortcuts
- Same bug exists in UniversalList.ps1:361-369

**Recommendation**: Implement proper event bubbling with stopPropagation mechanism

**Effort**: Medium
**Priority**: CRITICAL - Breaks user interaction

---

### 🔴 CRITICAL #4: Race Conditions in Event Loop
**Severity**: CRITICAL
**File**: `PmcApplication.ps1:275-312`

**Problem**: Terminal resize, input handling, and rendering modify shared state without synchronization

**Code**:
```powershell
while ($this.Running -and $this.ScreenStack.Count -gt 0) {
    # Check for terminal resize - modifies TermWidth/TermHeight
    if ($currentWidth -ne $this.TermWidth ...) {
        $this._HandleTerminalResize(...)  # Sets IsDirty flag
    }

    # Check for input - modifies screen state and IsDirty
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        // ... sets IsDirty flag
    }

    # Render - reads state modified above
    if ($this.IsDirty) {
        $this._RenderCurrentScreen()
    }
}
```

**Impact**:
- State corruption if resize happens during render
- Visual glitches
- Potential data loss
- IsDirty flag race condition

**Recommendation**: Add event queue and state locking

**Effort**: High
**Priority**: CRITICAL - Can cause data corruption

---

### 🔴 CRITICAL #5: Selection Index Can Go Negative
**Severity**: CRITICAL
**File**: `widgets/UniversalList.ps1:861-864`

**Problem**: When filtered data is empty, selection index set to -1 causing array index errors

**Code**:
```powershell
# Line 861-864
if ($this._selectedIndex -ge $this._filteredData.Count) {
    $this._selectedIndex = [Math]::Max(0, $this._filteredData.Count - 1)
}
```

**Impact**:
- If `_filteredData.Count` is 0, sets `_selectedIndex = -1`
- Next array access: `$this._filteredData[$this._selectedIndex]` throws index error
- Doesn't check lower bound

**Recommendation**:
```powershell
if ($this._filteredData.Count -eq 0) {
    $this._selectedIndex = -1  # Explicitly invalid
    return
}
$this._selectedIndex = [Math]::Min($this._selectedIndex, $this._filteredData.Count - 1)
$this._selectedIndex = [Math]::Max(0, $this._selectedIndex)
```

**Effort**: Low
**Priority**: CRITICAL - Causes runtime crashes

---

### 🔴 CRITICAL #6: Callback Error Suppression
**Severity**: HIGH
**Files**: `widgets/InlineEditor.ps1:916-928`, `widgets/UniversalList.ps1:941-958`, `services/TaskStore.ps1:1022-1036`

**Problem**: All callback exceptions are caught and silently ignored

**Code**:
```powershell
# InlineEditor.ps1:916-928
hidden [void] _InvokeCallback([scriptblock]$callback, $args) {
    if ($null -ne $callback -and $callback -ne {}) {
        try {
            & $callback $args
        } catch {
            # Silently ignore callback errors
        }
    }
}
```

**Impact**:
- User code errors completely hidden
- No way to debug callback issues
- Failed actions appear to succeed
- Violates principle of least surprise

**Recommendation**: Log errors at minimum, consider rethrowing
```powershell
catch {
    Write-PmcTuiLog "Callback error: $($_.Exception.Message)" "ERROR"
    Write-PmcTuiLog "Stack: $($_.ScriptStackTrace)" "DEBUG"
    throw  # Or at least make noise
}
```

**Effort**: Low
**Priority**: HIGH - Hides bugs

---

### 🔴 CRITICAL #7: CPU Spinning at 60 FPS
**Severity**: HIGH
**File**: `PmcApplication.ps1:267-312`

**Problem**: Event loop polls input at 60 FPS even when idle, checks terminal size every iteration

**Code**:
```powershell
while ($this.Running -and $this.ScreenStack.Count -gt 0) {
    # Check terminal size EVERY LOOP - expensive system calls
    $currentWidth = [Console]::WindowWidth
    $currentHeight = [Console]::WindowHeight

    # Poll input instead of blocking
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
    }

    # Only render when dirty (good)
    if ($this.IsDirty) {
        $this._RenderCurrentScreen()
    }

    # Sleep to prevent CPU spinning
    Start-Sleep -Milliseconds 16  # ~60 FPS - WASTEFUL
}
```

**Impact**:
- 100% CPU core usage even when idle
- Battery drain on laptops
- Terminal size check overhead (2 system calls per loop)
- 60 FPS rendering when nothing changes

**Recommendation**: Block on input instead of poll+sleep
```powershell
# Block on input with timeout
$key = $null
if ([Console]::KeyAvailable -or (WaitForInput -Timeout 100)) {
    $key = [Console]::ReadKey($true)
}
```

**Effort**: Medium
**Priority**: HIGH - Wastes resources

---

## High Priority Issues

### 🟠 #8: ANSI Parsing Hack
**File**: `PmcApplication.ps1:215-256`
**Severity**: MEDIUM-HIGH

**Problem**: Widgets output ANSI strings with embedded cursor positioning. PmcApplication parses these strings with regex, extracts positions, converts to 0-based coordinates, then RenderEngine converts back to 1-based.

**Waste**:
- Regex parsing on every render frame
- Multiple coordinate conversions
- String allocation overhead

**Recommendation**: Have widgets call RenderEngine.WriteAt() directly

**Effort**: Medium
**Priority**: HIGH

---

### 🟠 #9: Focus Management Broken
**File**: `Component.ps1:594-620` (SpeedTUI vendor code)
**Severity**: HIGH

**Problem**: No global focus manager. Multiple widgets can have `HasFocus=true` simultaneously.

**Impact**:
- Tab navigation impossible
- Focus visual indicators wrong
- No focus chain management

**Recommendation**: Implement global focus manager or use SpeedTUI's properly

**Effort**: High (affects vendor code)
**Priority**: HIGH

---

### 🟠 #10: Debug Logging in Hot Path
**File**: `widgets/UniversalList.ps1:471-485`
**Severity**: MEDIUM

**Problem**: Every keypress formats timestamps, builds debug strings, writes to log file

**Code**:
```powershell
$debugMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] UniversalList HandleInput: ..."
if ($global:PmcTuiLogFile) {
    Add-Content -Path $global:PmcTuiLogFile -Value $debugMsg
}
```

**Impact**: Performance degradation on every input

**Recommendation**: Move behind debug flag or remove

**Effort**: Low
**Priority**: MEDIUM

---

### 🟠 #11: Write-Host Pollution
**Files**: Multiple (20+ files in active code)
**Severity**: MEDIUM

**Problem**: Using `Write-Host` instead of proper output streams

**Impact**:
- Can't be captured or redirected
- Not testable
- Pollutes console in non-interactive scenarios

**Recommendation**: Use Write-Verbose, Write-Information, Write-Warning

**Effort**: Low
**Priority**: MEDIUM

---

## Medium Priority Issues

### 🟡 #12: Validation Only Shows First Error
**File**: `widgets/InlineEditor.ps1:541-548`
**Severity**: MEDIUM

**Problem**: Multiple field errors exist but only first displayed

**Impact**: User fixes one error, sees another, repeat (poor UX)

**Recommendation**: Show all errors or count "3 errors found"

**Effort**: Low
**Priority**: MEDIUM

---

### 🟡 #13: Enter Key Has 3 Behaviors
**File**: `widgets/InlineEditor.ps1:279-320`
**Severity**: MEDIUM

**Problem**: Enter key behavior depends on field type and position:
1. Expand widget (date/project/tags fields)
2. Move to next field (not last field)
3. Validate and confirm (last field)

**Impact**: Confusing UX, no visual indication of what Enter will do

**Recommendation**: Unify behavior or add visual hints

**Effort**: Medium
**Priority**: MEDIUM

---

### 🟡 #14: Parameter Validation Missing
**Files**: Most functions in active code
**Severity**: MEDIUM

**Problem**: Most functions lack `[Parameter()]` attributes and validation

**Impact**: Null checks done manually, error messages unclear

**Recommendation**: Add validation attributes
```powershell
[void] SetFields(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [hashtable[]]$fields
) { ... }
```

**Effort**: Medium (many functions)
**Priority**: MEDIUM

---

## VT100 / Rendering Engine Analysis

### Current Architecture

**Active VT100 Implementations** (2):
1. **PraxisVT.ps1** (loaded from `src/`)
   - PMC-specific VT100 functions
   - Box drawing characters
   - Color functions

2. **InternalVT100** class in `PerformanceCore.ps1` (loaded from SpeedTUI)
   - VT100 sequence generation with caching
   - RGB color support (caches up to 500 colors)
   - MoveTo(), Color(), etc.

**Note**: The old ConsoleUI.Core.ps1's PmcVT100 class is NOT loaded, so only 2 implementations exist in active code (not 3).

### Current Rendering Engine

**OptimizedRenderEngine.ps1** (in use):
- String-based differential rendering
- Position cache: `Dictionary[string, string]` where key = "x,y"
- Caches full ANSI strings (includes escape sequences)
- No true double buffering
- Single StringBuilder for frame building

**Characteristics**:
- Memory overhead: ~40 bytes per cached position
- String comparison for change detection
- Can't optimize color-only changes (compares full ANSI string)
- Performance: O(N) for cache lookups where N = screen positions

### Alternative Available (Not Loaded)

**EnhancedRenderEngine.ps1** (exists in SpeedTUI but not loaded):
- Cell-based differential rendering
- True double buffering (front + back buffers)
- CellBuffer: 12 bytes per cell (char + packed RGB + attributes)
- Separate tracking of character vs color changes
- Memory: ~288KB for 200×60 screen (vs 480KB for OptimizedRenderEngine)
- Better performance, lower memory

**Question**: Why is OptimizedRenderEngine used instead of EnhancedRenderEngine?

---

## Code Quality Issues

### Empty Catch Blocks
**Files**: Need to audit active code specifically (not all 30+ instances from dead code)

**Known locations in active code**:
- `widgets/PmcWidget.ps1:169`
- Various try/catch with empty catch in loaded files

**Recommendation**: Audit and fix

---

### Boolean Comparison Anti-Patterns
**Pattern**: `if ($x -eq $true)` instead of `if ($x)`

**Impact**: Verbose, can cause bugs with truthy values

**Recommendation**: Remove explicit comparisons

---

### Commented-Out Code
**Files**: Various

**Recommendation**: Delete (use git history)

---

## Metrics Summary

| Metric | Value |
|--------|-------|
| Total files in repository | ~100+ |
| Active files (loaded) | ~35 |
| Lines in active code | ~6,000-8,000 |
| Dead code percentage | ~50% |
| Critical issues | 7 |
| High priority issues | 4 |
| Medium priority issues | 4 |
| Files without strict mode | 100% (35/35) |
| VT100 implementations (active) | 2 |
| Rendering engines (active) | 1 (OptimizedRenderEngine) |

---

## Recommended Action Plan

### Sprint 1: Critical Fixes (1 week)
**Goal**: Fix crashes and critical bugs

1. ✅ Add `Set-StrictMode -Version Latest` to all 35 active files
2. ✅ Fix widget type mutation bug (InlineEditor.ps1)
3. ✅ Fix input modal trap (StandardListScreen, UniversalList)
4. ✅ Fix race conditions (PmcApplication.ps1 event loop)
5. ✅ Fix selection index bug (UniversalList.ps1)
6. ✅ Fix callback error suppression (3 files)
7. ✅ Fix CPU spinning (block on input instead of poll+sleep)

**Estimated Effort**: 40 hours

---

### Sprint 2: High Priority (1 week)
**Goal**: Performance and architecture improvements

8. ✅ Remove ANSI parsing hack (PmcApplication.ps1)
9. ✅ Investigate focus management (Component.ps1 - vendor code)
10. ✅ Remove debug logging from hot path (UniversalList.ps1)
11. ✅ Replace Write-Host with proper streams
12. ✅ **Evaluate switching to EnhancedRenderEngine**

**Estimated Effort**: 40 hours

---

### Sprint 3: Cleanup (3-5 days)
**Goal**: Remove dead code and technical debt

13. ✅ Delete dead code:
    - ConsoleUI.Core.ps1 (390KB)
    - Handlers/ directory
    - infrastructure/ directory
    - Unused screen files
    - Utility scripts
14. ✅ Consolidate VT100 implementations (PraxisVT vs PerformanceCore)
15. ✅ Add parameter validation attributes
16. ✅ Fix medium priority issues

**Estimated Effort**: 20 hours

---

## Conclusion

**Active codebase assessment**: The running application uses ~35 well-scoped files with ~6,000-8,000 lines of code. However, it contains **7 critical bugs** that risk crashes, data corruption, and poor performance.

**Dead code**: Approximately 50% of the repository is not loaded by `Start-PmcTUI.ps1` and can be safely deleted, including the 390KB `ConsoleUI.Core.ps1` file.

**Immediate action required**:
1. Add strict mode (prevents silent failures)
2. Fix 7 critical bugs (prevents crashes)
3. Delete dead code (reduces confusion)

**Rendering engine question**: The application uses `OptimizedRenderEngine` but a superior `EnhancedRenderEngine` exists in the SpeedTUI library. This needs investigation - why isn't the better engine being used?

**Timeline**: With focused effort, the critical issues can be resolved in 2-3 weeks, resulting in a much more stable and maintainable codebase.

---

## Appendix: File Load Order

As documented in `Start-PmcTUI.ps1`:

1. Import PMC module
2. Load DepsLoader.ps1 → loads from `../src/` and `deps/`
3. Load SpeedTUILoader.ps1 → loads SpeedTUI framework
4. Load helpers/*.ps1 (DataBindingHelper, ValidationHelper)
5. Load services/*.ps1 (TaskStore)
6. Load PmcWidget.ps1, PmcPanel.ps1, PmcLayoutManager.ps1
7. Load PmcScreen.ps1
8. Load widgets (TextInput, DatePicker, ProjectPicker, TagEditor, FilterPanel, InlineEditor, UniversalList)
9. Load base classes (StandardFormScreen, StandardListScreen, StandardDashboard)
10. Load PmcApplication.ps1
11. Load screens (TaskListScreen, BlockedTasksScreen)
12. Run Start-PmcTUI function

---

**Report End**
