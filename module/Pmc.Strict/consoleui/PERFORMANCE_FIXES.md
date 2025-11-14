# ConsoleUI Performance Fixes - Implementation Plan

**Date**: 2025-11-13
**Status**: In Progress
**Priority**: High - Performance improvements for single-user scenario

---

## Overview

Based on code review, implementing targeted performance optimizations that provide
high ROI without over-engineering for single-user, single-dev use case.

**Expected Results**:
- 40-50% CPU reduction
- 2-3x input responsiveness improvement
- Fewer silent failures
- Better resource management

---

## Implementation Plan

### HIGH PRIORITY FIXES (12 hours total)

#### Fix 1: Logging Off by Default (~1 hour)
**Problem**: Unbuffered file I/O on every operation (164 locations)
**Impact**: 30-40% CPU overhead

**Changes**:
- `Start-PmcTUI.ps1`: Add `-DebugLog` switch parameter
- Only initialize `$global:PmcTuiLogFile` when flag present
- Add `-LogLevel` parameter (0=off, 1=errors, 2=info, 3=verbose)

**Files Modified**:
- `Start-PmcTUI.ps1`

**Usage**:
```powershell
# Normal: No logging (default)
./run-tui.sh

# Debug: Full logging
./run-tui.sh -DebugLog -LogLevel 3
```

---

#### Fix 2: Config File Caching (~2 hours)
**Problem**: Reads config.json from disk repeatedly
**Impact**: Unnecessary file I/O bottleneck

**Changes**:
- Create `helpers/ConfigCache.ps1`
- Implement file timestamp-based cache invalidation
- Replace `Get-PmcConfig` calls with cached version

**Files Modified**:
- `helpers/ConfigCache.ps1` (NEW)
- `Start-PmcTUI.ps1` (use ConfigCache)
- Any screens reading config directly

**Implementation**:
```powershell
class ConfigCache {
    static [hashtable]$_cache = $null
    static [datetime]$_lastLoad = [datetime]::MinValue

    static [hashtable] GetConfig([string]$path) {
        $fileModified = (Get-Item $path).LastWriteTime
        if ($null -eq [ConfigCache]::_cache -or $fileModified -gt [ConfigCache]::_lastLoad) {
            [ConfigCache]::_cache = Get-Content $path | ConvertFrom-Json -AsHashtable
            [ConfigCache]::_lastLoad = [datetime]::Now
        }
        return [ConfigCache]::_cache
    }
}
```

---

#### Fix 3: Theme Color Caching (~2 hours)
**Problem**: Hex-to-RGB conversion on every render (60+ times/second)
**Impact**: 10-15% render time reduction

**Changes**:
- `theme/PmcThemeManager.ps1`: Add color cache hashtable
- Cache converted ANSI sequences
- Invalidate cache on theme change

**Files Modified**:
- `theme/PmcThemeManager.ps1`

**Implementation**:
```powershell
class PmcThemeManager {
    hidden [hashtable]$_colorCache = @{}

    [string] GetColorSequence([string]$hexColor) {
        if ($this._colorCache.ContainsKey($hexColor)) {
            return $this._colorCache[$hexColor]
        }

        $rgb = $this._ConvertHexToRgb($hexColor)
        $sequence = "`e[38;2;$($rgb.R);$($rgb.G);$($rgb.B)m"
        $this._colorCache[$hexColor] = $sequence
        return $sequence
    }

    [void] ClearCache() { $this._colorCache.Clear() }
}
```

---

#### Fix 4: Fail-Fast Error Handling (~4 hours)
**Problem**: Silent failures in critical systems lead to corrupt state
**Impact**: Fewer mysterious bugs, clearer error messages

**Changes**:
- Critical systems (Theme, RenderEngine, TaskStore): Exit on failure
- Optional features (Logging, Stats): Warn but continue
- User operations (Save, Add): Show error dialog, allow retry

**Files Modified**:
- `PmcApplication.ps1` (render errors)
- `Start-PmcTUI.ps1` (initialization errors)
- `services/TaskStore.ps1` (data errors)

**Pattern**:
```powershell
# CRITICAL: Fail fast
try {
    $this.RenderEngine = New-Object OptimizedRenderEngine
    $this.RenderEngine.Initialize()
} catch {
    Write-Host "FATAL: RenderEngine initialization failed: $_" -ForegroundColor Red
    Write-Host "Cannot continue. Exiting." -ForegroundColor Red
    exit 1
}

# OPTIONAL: Warn and continue
try {
    Initialize-PmcLogging
} catch {
    Write-Host "WARNING: Logging disabled: $_" -ForegroundColor Yellow
    # Continue without logging
}
```

---

#### Fix 5: Event Loop Optimization (~2 hours)
**Problem**: Sleeps 16-100ms every iteration, even with pending input
**Impact**: 2-3x input responsiveness improvement

**Changes**:
- `PmcApplication.ps1`: Drain input queue before rendering
- Adaptive sleep based on activity
- Process all available keypresses in batch

**Files Modified**:
- `PmcApplication.ps1` (Run method)

**Implementation** (Option C):
```powershell
while ($this.Running -and $this.ScreenStack.Count -gt 0) {
    $hadInput = $false

    # Process ALL available input before rendering
    while ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)

        # Global keys (Ctrl+Q)
        if ($key.Modifiers -eq [ConsoleModifiers]::Control -and $key.Key -eq 'Q') {
            $this.Stop()
            continue
        }

        # Pass to screen
        if ($this.CurrentScreen -and $this.CurrentScreen.PSObject.Methods['HandleKeyPress']) {
            $handled = $this.CurrentScreen.HandleKeyPress($key)
            if ($handled) { $hadInput = $true }
        }
    }

    if ($hadInput) { $this.IsDirty = $true }

    # Terminal resize check (every 20 iterations)
    if ($iteration % 20 -eq 0) {
        $currentWidth = [Console]::WindowWidth
        $currentHeight = [Console]::WindowHeight
        if ($currentWidth -ne $this.TermWidth -or $currentHeight -ne $this.TermHeight) {
            $this._HandleTerminalResize($currentWidth, $currentHeight)
        }
    }
    $iteration++

    # Render if dirty
    if ($this.IsDirty) {
        $this._RenderCurrentScreen()
        $iteration = 0
    }

    # Adaptive sleep: shorter when active, longer when idle
    if ($this.IsDirty) {
        Start-Sleep -Milliseconds 16  # ~60 FPS when rendering
    } else {
        Start-Sleep -Milliseconds 100  # ~10 FPS when idle
    }
}
```

---

### MEDIUM PRIORITY FIXES (Optional)

#### Fix 6: Terminal Polling Optimization (~1 hour)
**Problem**: Polls terminal size every 20 iterations regardless of activity
**Impact**: Minor CPU reduction

**Changes**:
- Only check terminal size when idle (no rendering)
- Reduces console API calls

**Files Modified**:
- `PmcApplication.ps1` (Run method)

**Implementation**:
```powershell
# Check terminal size only when idle
if (-not $this.IsDirty) {
    $currentWidth = [Console]::WindowWidth
    $currentHeight = [Console]::WindowHeight
    if ($currentWidth -ne $this.TermWidth -or $currentHeight -ne $this.TermHeight) {
        $this._HandleTerminalResize($currentWidth, $currentHeight)
    }
}
```

---

## Architectural Decisions

### Hybrid DI + Globals Pattern (ACCEPTED)

**Decision**: Continue using hybrid approach for single-user context

**Rationale**:
- Single user, single developer, single instance
- Globals provide convenient access (e.g., `$global:PmcApp`)
- DI container creates instances with dependencies
- Singletons ensure single instance (e.g., `[TaskStore]::GetInstance()`)

**Trade-offs**:
- ✅ Convenient access from widgets/screens
- ✅ Works perfectly for single-instance scenario
- ❌ Not testable in isolation (acceptable - no tests yet)
- ❌ Cannot run multiple instances (not needed)

**Convention**:
```powershell
# 1. Core services: Use Singleton pattern
$store = [TaskStore]::GetInstance()

# 2. Application state: Use globals
$global:PmcApp.PushScreen($screen)

# 3. Screens: Created via DI container
$screen = $container.Resolve('TaskListScreen')
```

---

### Thread Safety (NOT NEEDED)

**Decision**: No additional thread safety measures

**Rationale**:
- Single-threaded event loop
- No async operations (`Start-Job`, background tasks)
- PowerShell 5.1 is mostly single-threaded
- TaskStore has defensive locks (keep as-is, doesn't hurt)

**When to revisit**:
- Adding background auto-refresh
- Adding file watchers
- Adding async I/O

---

### Classes vs Functions (KEEP CLASSES)

**Decision**: Continue using PowerShell classes

**Rationale**:
- 87 classes already implemented
- Inheritance critical (`: PmcScreen`, `: StandardListScreen`)
- Widgets need encapsulated state
- Type safety and IntelliSense
- Refactoring to functions = rewrite entire app

**Acceptable Trade-offs**:
- Dual constructors verbose (but already written)
- No optional constructor parameters (workaround exists)
- PowerShell class limitations (manageable)

---

## Testing Strategy

**Current Status**: Minimal testing (31 manual assertions)

**Future Plan** (when ready):
1. Widget tests (easiest to isolate)
2. TaskStore tests (business logic)
3. Screen tests (most complex)

**Not required for performance fixes** - testing remains future work.

---

## Performance Benchmarks

### Before Fixes (Baseline)
- Event loop latency: 16-100ms
- CPU usage (idle): ~15-20%
- CPU usage (active): ~40-60%
- Config reads: Multiple per second
- Theme conversions: 60+ per second

### After Fixes (Expected)
- Event loop latency: 1-5ms
- CPU usage (idle): ~5-8% (logging off, better sleep)
- CPU usage (active): ~20-30% (caching, optimizations)
- Config reads: Once, then cached
- Theme conversions: Once per color, then cached

**Total Improvement**: 40-50% CPU reduction, 2-3x responsiveness

---

## Implementation Order

1. ✅ Document plan (this file)
2. Fix 1: Logging off by default
3. Fix 5: Event loop optimization (biggest responsiveness win)
4. Fix 4: Fail-fast errors (prevent corruption)
5. Fix 2: Config caching
6. Fix 3: Theme caching
7. Fix 6: Terminal polling (optional)
8. Test and verify
9. Commit and push

---

## Files to Modify

### NEW FILES:
- `PERFORMANCE_FIXES.md` (this file)
- `helpers/ConfigCache.ps1`

### MODIFIED FILES:
- `Start-PmcTUI.ps1` (logging flags, config cache)
- `PmcApplication.ps1` (event loop, error handling, terminal polling)
- `theme/PmcThemeManager.ps1` (color cache)
- `services/TaskStore.ps1` (error handling)

### TOTAL: 6 files modified/created

---

## Rollback Plan

All changes are non-breaking:
- Logging: Default OFF (can enable with flag)
- Caching: Transparent (invalidates on file change)
- Event loop: Same behavior, better performance
- Error handling: Fail fast vs silent (safer)

If issues occur:
1. Git revert specific commits
2. Falls back to previous behavior
3. No data corruption risk

---

## Success Criteria

- [ ] Application starts with logging OFF by default
- [ ] Can enable logging with `-DebugLog` flag
- [ ] Config file read only once (cached)
- [ ] Theme colors converted only once (cached)
- [ ] Event loop processes all input before rendering
- [ ] Critical errors exit with clear message
- [ ] CPU usage reduced by 40-50%
- [ ] Input responsiveness noticeably improved
- [ ] No regressions in functionality

---

## Notes

- Optimize for single-user, single-dev scenario (don't over-engineer)
- Pragmatic trade-offs acceptable (hybrid DI, globals, no tests yet)
- Focus on high-ROI fixes (performance, stability)
- Document decisions for future reference
- Keep it simple and maintainable
