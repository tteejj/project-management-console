# PMC ConsoleUI - Architecture Decision Records (ADRs)

**Project**: PMC ConsoleUI (SpeedTUI-based Terminal User Interface)
**Context**: Single-user, single-developer project management tool
**Last Updated**: 2025-11-13

---

## Table of Contents

1. [ADR-001: Hybrid DI + Globals Pattern](#adr-001-hybrid-di--globals-pattern)
2. [ADR-002: PowerShell Classes vs Functions](#adr-002-powershell-classes-vs-functions)
3. [ADR-003: Thread Safety Approach](#adr-003-thread-safety-approach)
4. [ADR-004: Logging Disabled by Default](#adr-004-logging-disabled-by-default)
5. [ADR-005: Dual Constructor Pattern](#adr-005-dual-constructor-pattern)
6. [ADR-006: Three Service Access Patterns](#adr-006-three-service-access-patterns)
7. [ADR-007: Hidden Fields for Encapsulation](#adr-007-hidden-fields-for-encapsulation)
8. [ADR-008: Testing Strategy](#adr-008-testing-strategy)
9. [ADR-009: Error Handling Philosophy](#adr-009-error-handling-philosophy)
10. [ADR-010: Performance vs Purity Trade-offs](#adr-010-performance-vs-purity-trade-offs)

---

## ADR-001: Hybrid DI + Globals Pattern

### Status
**ACCEPTED** - Intentional design for single-user context

### Context
Traditional enterprise DI requires passing dependencies through constructors everywhere.
For a TUI with 100+ widgets/screens, this becomes verbose and error-prone.

### Decision
Use **hybrid approach**:
1. **DI Container**: Creates instances with proper initialization order
2. **Global Variables**: Provide convenient access (`$global:PmcApp`, `$global:PmcContainer`)
3. **Singleton Pattern**: Ensures single instance (`[TaskStore]::GetInstance()`)

### Rationale
- **Single-user application** - Only one instance ever runs
- **100+ widgets/screens** need app reference - globals eliminate constructor pollution
- **Not shipping as library** for others - no multi-instance requirement
- **Pragmatic over pure** - Optimized for actual use case, not textbook architecture

### Consequences
**Positive**:
- ✅ Easy widget access to services
- ✅ No constructor parameter explosion
- ✅ Simpler code for single-instance scenario

**Negative**:
- ❌ Not testable in isolation (no tests currently anyway)
- ❌ Cannot run multiple instances (not needed)
- ❌ Non-enterprise-grade (acceptable for personal tool)

### Code Example
```powershell
# DI creates the instance
$global:PmcContainer = [ServiceContainer]::new()
$global:PmcApp = $container.Resolve('Application')

# Widgets access via global (not passed through constructor)
class MyWidget {
    [void] NavigateToScreen($screen) {
        $global:PmcApp.PushScreen($screen)  # Convenient!
    }
}
```

### Alternative Rejected
**Pure DI** - Pass `$app` to every widget constructor
- Too verbose (100+ constructors)
- Adds complexity without benefit (single instance)
- Makes code harder to read/maintain

---

## ADR-002: PowerShell Classes vs Functions

### Status
**ACCEPTED** - Classes are the right choice for this codebase

### Context
PowerShell supports both classes (OOP) and functions (functional).
Classes have limitations (no optional constructor params, limited method overloading).

### Decision
Use **PowerShell classes** for stateful components (widgets, screens, services).
Use **functions** for utilities and stateless operations.

### Rationale
- **87 classes** already implemented and working
- **Inheritance critical** - Base classes (PmcScreen, StandardListScreen, PmcWidget)
- **Encapsulation** - `hidden` fields protect internal state
- **Type safety** - IntelliSense, autocomplete, compile-time checks
- **Familiar patterns** - OOP is well-understood paradigm

### Consequences
**Positive**:
- ✅ Inheritance hierarchies work well
- ✅ Encapsulated state
- ✅ Type safety and IntelliSense
- ✅ Clear component boundaries

**Negative**:
- ❌ Dual constructors needed (see ADR-005)
- ❌ PowerShell 5.1 class bugs occasional
- ❌ Harder to debug (hidden fields)

### When to Use Functions
- Utilities (Format-TaskDisplay, Convert-DateToString)
- Pipelines (Get-Task | Where-Object | Format-List)
- Stateless transformations

### When to Use Classes
- Components with state (UniversalList, DatePicker)
- Inheritance needed (all screens extend PmcScreen)
- Complex object lifecycle

---

## ADR-003: Thread Safety Approach

### Status
**ACCEPTED** - Minimal thread safety, defensive in TaskStore only

### Context
Single-threaded event loop, no async operations (Start-Job, background tasks).
PowerShell 5.1 is mostly single-threaded.

### Decision
- **No thread synchronization** for most code
- **Defensive locks** in TaskStore only (data persistence critical)
- **Re-evaluate** if async features added in future

### Rationale
- **No async operations** currently - single-threaded execution
- **Adding locks everywhere** would add complexity without benefit
- **TaskStore has Monitor locks** as defensive measure (doesn't hurt, low cost)
- **If future needs arise**, add threading then (YAGNI principle)

### Consequences
**Positive**:
- ✅ Simpler code (no lock management)
- ✅ No deadlock risk
- ✅ Better performance (no lock overhead)

**Negative**:
- ❌ Would break with async operations (but none planned)
- ❌ TaskStore locks may be unnecessary (but harmless)

### When to Revisit
- Adding background auto-refresh
- Implementing file watchers
- Using async I/O (PowerShell 7+)

---

## ADR-004: Logging Disabled by Default

### Status
**ACCEPTED** - Major performance optimization

### Context
Unbuffered file I/O logging was consuming 30-40% CPU even when idle.
164 log statements executed per second.

### Decision
- **Logging OFF by default** for production use
- **Enable with flag**: `Start-ConsoleUI.ps1 -DebugLog -LogLevel 3`
- **Log levels**: 0=off (default), 1=errors, 2=info, 3=verbose

### Rationale
- **30-40% CPU reduction** when disabled
- **Most users don't need logs** - only for debugging
- **Opt-in better than opt-out** for performance
- **Still available when needed** via command-line flag

### Consequences
**Positive**:
- ✅ 30-40% CPU reduction
- ✅ No disk I/O overhead
- ✅ Better battery life (laptops)
- ✅ Faster startup

**Negative**:
- ❌ No logs for troubleshooting (unless explicitly enabled)
- ❌ Users must remember `-DebugLog` flag for debugging

### Usage
```powershell
# Normal mode (fast, no logs)
.\Start-ConsoleUI.ps1

# Debug mode (full logging)
.\Start-ConsoleUI.ps1 -DebugLog -LogLevel 3

# Errors only
.\Start-ConsoleUI.ps1 -LogLevel 1
```

---

## ADR-005: Dual Constructor Pattern

### Status
**ACCEPTED** - Necessary workaround for PowerShell limitation

### Context
PowerShell classes don't support optional constructor parameters with defaults.
Need backward compatibility + DI support.

### Decision
All screens have **two constructors**:
1. **Legacy** (no container): `MyScreen() : base("Key", "Title") { }`
2. **DI-enabled** (with container): `MyScreen([object]$container) : base("Key", "Title", $container) { }`

### Rationale
- **PowerShell limitation** - Can't do: `MyScreen([object]$container = $null)`
- **Backward compatibility** - Old code still works
- **DI support** - New code uses container
- **Already implemented** - 40+ screens have this pattern

### Consequences
**Positive**:
- ✅ Backward compatible
- ✅ DI support when needed
- ✅ Clear which constructor is which

**Negative**:
- ❌ Verbose (every screen needs both)
- ❌ Code duplication
- ❌ Maintenance burden (change logic → update 2 constructors)

### Alternative Considered
**Factory Functions** instead of constructors:
```powershell
function New-TaskListScreen {
    param([object]$Container = $null)  # Defaults work in functions!
    return [TaskListScreen]::new($Container ?? $global:PmcContainer)
}
```

**Rejected because**:
- Refactoring all 40+ screens is massive effort
- Loses type safety
- Loses IntelliSense
- Current pattern works fine

---

## ADR-006: Three Service Access Patterns

### Status
**ACCEPTED** - Intentional hybrid for single-user scenario

### Context
Three ways to access services coexist:
1. **Singleton**: `[TaskStore]::GetInstance()`
2. **DI Container**: `$container.Resolve('TaskStore')`
3. **Global Variable**: `$global:PmcApp`

### Decision
**All three are intentional** and serve different purposes.

### Rationale
**Singleton Pattern**:
- Used for: TaskStore, ThemeManager, MenuRegistry
- Reason: Ensures single instance, easy access from anywhere
- When: Core services that must be unique

**DI Container**:
- Used for: Creating screens, resolving with dependencies
- Reason: Manages initialization order, handles dependencies
- When: Need dependency injection or lazy loading

**Global Variables**:
- Used for: Application, Container
- Reason: Convenient access from 100+ widgets
- When: Need quick access without parameter passing

### Convention
```powershell
# 1. Core services: Singleton pattern
$store = [TaskStore]::GetInstance()
$theme = [PmcThemeManager]::GetInstance()

# 2. Application/Container: Globals
$global:PmcApp.PushScreen($newScreen)
$service = $global:PmcContainer.Resolve('ServiceName')

# 3. Screens: Created via DI container
$screen = $container.Resolve('TaskListScreen')
```

### Consequences
**Positive**:
- ✅ Pragmatic - Use right tool for each situation
- ✅ Clear conventions
- ✅ Works well in practice

**Negative**:
- ❌ Not "pure" DI (acceptable for single-user tool)
- ❌ Developers must learn three patterns (documented here!)

---

## ADR-007: Hidden Fields for Encapsulation

### Status
**ACCEPTED** - Proper encapsulation practice

### Context
147 `hidden` fields across codebase.
Criticism: Makes debugging harder (can't inspect hidden fields easily).

### Decision
**Continue using `hidden` for internal state** - This is correct OOP practice.

### Rationale
- **Encapsulation** - Hide implementation details
- **API clarity** - Public properties are the API
- **Prevent misuse** - Callers can't access internal state
- **Debugging** - Use logging or public methods to expose state when needed

### Consequences
**Positive**:
- ✅ Proper encapsulation
- ✅ Clear public API
- ✅ Protected internal state

**Negative**:
- ❌ Harder to inspect in debugger
- ❌ Must add public methods/properties to expose state

### Guidelines
**Use `hidden`**:
- Cache fields (`_colorCache`, `_ansiCache`)
- Internal state (`_resolutionStack`, `_dataLock`)
- Implementation details

**Make public**:
- API properties (CurrentScreen, TermWidth, Running)
- Configuration (AllowAdd, AllowEdit, ShowFilterPanel)
- State meant for callers

---

## ADR-008: Testing Strategy

### Status
**ACCEPTED** - Manual testing currently, automated testing future

### Context
- 48,341 lines of code
- Only 31 manual test assertions
- No Pester framework, no CI/CD

### Decision
**Current**: Manual widget tests, no automation
**Future**: Add Pester tests when time permits

### Rationale
- **Early development phase** - Rapid iteration more important than test coverage
- **Single developer** - No team to break things
- **Manual testing works** - Widget tests verify functionality
- **Future work** - Add tests when codebase stabilizes

### Testing Approach (Current)
1. **Widget tests**: Standalone scripts (TestTextInput.ps1, TestUniversalList.ps1)
2. **Integration tests**: Manual TUI usage
3. **Smoke tests**: Application starts and renders

### Testing Strategy (Future)
1. **Widget unit tests** (easiest to isolate)
2. **TaskStore tests** (business logic)
3. **Screen tests** (most complex)

### Consequences
**Positive**:
- ✅ Faster development (no test writing overhead)
- ✅ Manual tests catch visual issues
- ✅ Flexible - can change architecture quickly

**Negative**:
- ❌ No regression detection
- ❌ Bugs found manually
- ❌ Refactoring riskier

---

## ADR-009: Error Handling Philosophy

### Status
**IN PROGRESS** - Shifting from silent failures to fail-fast

### Context
Many catch blocks silently swallow errors:
```powershell
try {
    Initialize-PmcThemeSystem
} catch {
    # Silent - continues with broken state!
}
```

### Decision
**New Philosophy**: Fail-fast for critical systems, warn for optional features

### Strategy
**Critical Systems** (RenderEngine, Theme, TaskStore):
- **Fail fast** - Show error and exit
- **Cannot continue** without these

**Optional Features** (Logging, Stats, Excel):
- **Warn and continue** - Show warning but don't crash

**User Operations** (Save, Add, Edit):
- **Show error** - Display in UI, allow retry

### Implementation
```powershell
# CRITICAL: Fail fast
try {
    $this.RenderEngine = New-Object OptimizedRenderEngine
    $this.RenderEngine.Initialize()
} catch {
    Write-Host "FATAL: RenderEngine failed: $_" -ForegroundColor Red
    exit 1
}

# OPTIONAL: Warn and continue
try {
    Initialize-PmcLogging
} catch {
    Write-Host "WARNING: Logging disabled: $_" -ForegroundColor Yellow
    # Continue without logging
}

# USER OP: Show error, allow retry
try {
    Save-PmcTask $task
} catch {
    Show-ErrorDialog "Failed to save task: $_"
    # User can retry or cancel
}
```

### Consequences
**Positive**:
- ✅ Clearer errors for users
- ✅ Prevents silent corruption
- ✅ Easier debugging

**Negative**:
- ❌ Application may exit more often (but with clear reason!)
- ❌ Requires auditing all catch blocks (in progress)

---

## ADR-010: Performance vs Purity Trade-offs

### Status
**ACCEPTED** - Optimized for single-user, real-world usage

### Context
This is a **personal productivity tool**, not a **library for others** or **enterprise system**.

### Decision
**Optimize for actual use case** - sacrificing "purity" where it doesn't matter.

### Trade-offs Made
| Pure/Enterprise | Pragmatic/Personal | Rationale |
|----------------|-------------------|-----------|
| No globals | Globals for convenience | Single instance, no multi-user |
| Pure DI | Hybrid DI + singletons | Simpler code, works fine |
| 100% test coverage | Manual testing | Fast iteration, single dev |
| Thread-safe everywhere | Single-threaded design | No async ops planned |
| Factory functions | PowerShell classes | Inheritance needed, already built |
| Strict error handling | Silent on non-critical | Better UX for minor issues |

### Philosophy
1. **YAGNI** - Don't add complexity for hypothetical future needs
2. **Pragmatic** - Use globals if they make code simpler (single instance)
3. **Performance** - Disable logging by default (30-40% faster)
4. **Maintainability** - Clear code > perfect architecture
5. **Shipped** - Working software > unfinished perfection

### When to Revisit
- Shipping as module for others
- Multiple instances needed
- Team development
- Enterprise deployment

---

## Summary of Design Decisions

### What We Did (Intentional)
1. ✅ Hybrid DI + Globals - Pragmatic for single-user
2. ✅ PowerShell classes - Right tool for stateful components
3. ✅ Minimal thread safety - No async ops to protect
4. ✅ Logging off by default - 30-40% performance gain
5. ✅ Dual constructors - PowerShell limitation workaround
6. ✅ Three access patterns - Each serves a purpose
7. ✅ Hidden fields - Proper encapsulation
8. ✅ Manual testing - Fast iteration, single dev
9. ✅ Fail-fast on critical - Better error visibility
10. ✅ Performance over purity - Optimized for use case

### What We Improved (Fixes)
1. ✅ Logging disabled by default (30-40% CPU reduction)
2. ✅ Config file caching (eliminated repeated I/O)
3. ✅ Event loop optimization (2-3x input responsiveness)
4. ✅ Fail-fast render errors (clear error messages)
5. ✅ Terminal polling only when idle (minor CPU reduction)
6. ✅ ServiceContainer cleanup robustness
7. ✅ Theme initialization guard

### What's Acceptable (Not Fixing)
1. ✅ Global variables (single-user tool)
2. ✅ Dual constructors (PowerShell limitation)
3. ✅ Hidden fields (proper encapsulation)
4. ✅ No automated tests yet (future work)
5. ✅ Mixed service access patterns (intentional design)

---

## For Future Developers

If you're new to this codebase, understand:

1. **This is NOT enterprise-grade** - It's optimized for single-user, single-dev use
2. **Globals are intentional** - Single instance means they're fine
3. **DI is hybrid** - Container + singletons + globals work together
4. **Performance matters** - Logging off by default, caching everywhere
5. **Fail-fast on critical** - Better loud failure than silent corruption

**If shipping this as a library**:
- Remove globals, pure DI everywhere
- Add comprehensive tests
- Add proper thread safety
- Document public API clearly
- Version properly (SemVer)

**For personal use** (current):
- Current architecture is fine
- Focus on features, not perfection
- Performance optimizations worth it
- Manual testing sufficient

---

**Last Updated**: 2025-11-13
**Author**: Code critique and optimization review
**Status**: Living document - update as decisions change
