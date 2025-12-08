# PMC TUI Architecture - Quick Reference Guide

**Document Purpose**: One-page overview of key architectural concepts
**For**: Developers new to the codebase or needing quick lookups
**Last Updated**: 2025-11-13

---

## Quick Stats

| Metric | Value |
|--------|-------|
| Total Lines | ~116,000 PowerShell |
| ConsoleUI Size | ~68,000 lines |
| Core Classes | 87+ classes |
| Screen Classes | 40+ screens |
| Widget Classes | 12+ widgets |
| Service Classes | 8 services |
| Helper Classes | 7+ helpers |
| Entry Point | Start-PmcTUI.ps1 |
| Main App Class | PmcApplication |
| Base Screen Class | PmcScreen |
| Base Widget Class | PmcWidget (extends SpeedTUI Component) |
| Data Store | TaskStore (singleton, observable) |
| Framework | SpeedTUI (vendored in lib/) |

---

## Directory Quick Map

```
consoleui/
├── Start-PmcTUI.ps1        ← ENTRY POINT (bootstrap & main loop)
├── PmcApplication.ps1      ← App event loop & screen stack
├── PmcScreen.ps1           ← Base for all screens
├── ServiceContainer.ps1    ← DI container
│
├── base/                   ← Base classes (List, Form, Dashboard)
├── screens/                ← 40 concrete screen implementations
├── widgets/                ← 12+ UI widgets
├── services/               ← 8 business logic services
├── helpers/                ← 7 utility classes
├── theme/                  ← Theme management
├── layout/                 ← Layout calculations
└── tests/                  ← Manual test scripts
```

---

## Initialization Sequence (Critical!)

1. **Load Module**: Pmc.Strict.psm1 (src/ files)
2. **Load Deps**: DepsLoader.ps1 (type normalization, templates)
3. **Load Framework**: SpeedTUILoader.ps1 (OptimizedRenderEngine, Component)
4. **Load Helpers**: helpers/ (ConfigCache, ValidationHelper, etc.)
5. **Load Services**: services/ (TaskStore, MenuRegistry, etc.)
6. **Load Widgets**: widgets/ (PmcWidget, UniversalList, TextInput, etc.)
7. **Load Base Classes**: base/ (StandardListScreen, StandardFormScreen)
8. **Load Container**: ServiceContainer.ps1
9. **Load Application**: PmcApplication.ps1
10. **Load Initial Screen**: TaskListScreen.ps1
11. **Register Services**: In dependency order (Theme → Application)
12. **Run Event Loop**: PmcApplication.Run()

**Critical**: Services registered in **dependency order** (no circular deps).

---

## Core Architecture Patterns

### Pattern 1: Three-Layer Service Access (Hybrid DI)

```powershell
# 1. SINGLETON (core services)
$store = [TaskStore]::GetInstance()
$theme = [PmcThemeManager]::GetInstance()

# 2. DI CONTAINER (screen creation)
$screen = $container.Resolve('TaskListScreen')

# 3. GLOBALS (convenience)
$global:PmcApp.PushScreen($screen)
$global:PmcContainer.Resolve('Service')
```

**Why?** Single-user tool, no multi-instance complexity needed.

### Pattern 2: Screen Stack Navigation

```powershell
# Navigate forward
$app.PushScreen($newScreen)  # Saves current screen, activates new one

# Navigate back
$app.PopScreen()             # Restores previous screen

# Replace entire stack
$app.SetRootScreen($screen)  # Clear history, start fresh
```

### Pattern 3: Observable Event-Driven Data

```powershell
# TaskStore fires events on data changes
$store.OnTasksChanged = { param($tasks) $this.RefreshUI() }

# When you modify data:
$store.UpdateTask($id, $changes)  # Auto-fires event, saves to disk
```

### Pattern 4: Dual Constructors (PowerShell Limitation)

```powershell
# Every screen has TWO constructors:

# Legacy (no DI)
TaskListScreen() : base("TaskList", "Task List") { }

# DI-enabled
TaskListScreen([object]$container) : base("TaskList", "Task List", $container) { }

# Why? PowerShell classes don't support optional constructor params
```

---

## Key Classes at a Glance

### Application Classes

| Class | Purpose | File |
|-------|---------|------|
| PmcApplication | Event loop, screen stack, rendering | PmcApplication.ps1 |
| ServiceContainer | Dependency injection | ServiceContainer.ps1 |
| PmcScreen | Base screen, lifecycle management | PmcScreen.ps1 |

### Base Classes (Inheritance Templates)

| Class | Used By | Purpose |
|-------|---------|---------|
| StandardListScreen | TaskListScreen, ProjectListScreen | Pre-built list UI (UniversalList, FilterPanel, InlineEditor) |
| StandardFormScreen | TaskFormScreen, SettingsScreen | Pre-built form UI (InlineEditor with save) |
| StandardDashboard | MainDashboard, StatsScreen | Pre-built dashboard (grid layout, panels) |

### Key Services

| Service | Pattern | Purpose |
|---------|---------|---------|
| TaskStore | Singleton | In-memory data cache + observable events + auto-save |
| MenuRegistry | Singleton | Dynamic menu registration + navigation |
| ThemeManager | Singleton | Theme colors + palette derivation |
| CommandService | Singleton | Command execution |
| ChecklistService | Singleton | Task checklist management |

### Key Widgets

| Widget | Base | Purpose |
|--------|------|---------|
| UniversalList | PmcWidget | Sortable, filterable data table |
| InlineEditor | PmcWidget | Multi-field form with validation |
| TextInput | PmcWidget | Single-line text field |
| DatePicker | PmcWidget | Calendar date selection |
| FilterPanel | PmcWidget | Dynamic filter builder |
| PmcMenuBar | PmcWidget | F10 menu bar |

---

## Rendering Pipeline

```
Input comes in
      ↓
PmcApplication.Run() event loop
      ↓
CurrentScreen.HandleKeyPress(key)
      ↓
If state changed, mark IsDirty=true
      ↓
_RenderCurrentScreen()
      ├─ RenderEngine.BeginFrame()
      ├─ screen.RenderToEngine(engine) OR
      │  screen.Render() → _WriteAnsiToEngine()
      ├─ RenderEngine.EndFrame() [differential rendering]
      └─ IsDirty = false
      ↓
Terminal displays changes
```

**Key Optimization**: Differential rendering - only write changed cells.

---

## Input Handling Pipeline

```
[Console]::KeyAvailable → Read key
      ↓
Check global shortcuts (Ctrl+Q = exit)
      ↓
CurrentScreen.HandleKeyPress(key)
      ├─ Pass to MenuBar if F10
      ├─ Pass to content widgets
      └─ Handle directly or navigate to new screen
      ↓
If handled, mark IsDirty=true
      ↓
Next render cycle shows changes
```

**Optimization**: Drain ALL available input before rendering (2-3x faster input response).

---

## ServiceContainer Dependency Graph

```
Theme (no deps)
  ↓
ThemeManager (deps: Theme)
  ↓
Config (cached, no deps)
  ↓
TaskStore (deps: Theme)
MenuRegistry (deps: Theme)
Application (deps: Theme)
  ↓
CommandService (no deps)
ChecklistService (no deps)
NoteService (no deps)
  ↓
Screen factories (deps: Application, TaskStore, Theme)
```

**Critical**: Theme is required by many services, loaded first.

---

## How to Add a New Screen

1. **Create screen class** extending StandardListScreen or StandardFormScreen
   ```powershell
   class MyScreen : StandardListScreen {
       MyScreen() : base("MyKey", "My Title") {}
       
       [void] LoadData() {
           # Override to load your data
       }
       
       [array] GetColumns() {
           # Return @( @{Name='field'; Label='Label'; Width=10} )
       }
       
       [array] GetEditFields($item) {
           # Return field definitions for add/edit form
       }
   }
   ```

2. **Register in ServiceContainer** (Start-PmcTUI.ps1)
   ```powershell
   $container.Register('MyScreen', {
       param($container)
       return [MyScreen]::new($container)
   }, $false)
   ```

3. **Add menu item** (TaskListScreen or MenuRegistry)
   ```powershell
   $registry.AddMenuItem('Tasks', 'My Screen', 'M', {
       . "$PSScriptRoot/screens/MyScreen.ps1"
       $global:PmcApp.PushScreen([MyScreen]::new())
   })
   ```

---

## Performance Tips

| Optimization | Benefit | Notes |
|--------------|---------|-------|
| Logging disabled by default | 30-40% CPU reduction | Use `-DebugLog -LogLevel 3` to enable |
| Differential rendering | 70-80% less terminal I/O | OptimizedRenderEngine only writes changed cells |
| Config caching | 30% faster config access | ConfigCache wrapper |
| Input draining | 2-3x faster input response | Drain all input before rendering |
| Lazy screen loading | Faster startup | Only pre-load TaskListScreen |
| Event loop sleep timing | Balanced responsiveness | 16ms rendering, 100ms idle |

---

## Common Development Tasks

### Debug a Screen Rendering Issue

1. Enable logging: `Start-PmcTUI -DebugLog -LogLevel 3`
2. Look for "RenderCurrentScreen" messages in log
3. Check screen.Render() or screen.RenderToEngine() output
4. Verify widget content
5. Check ANSI positioning codes

### Add Input Handler to Screen

```powershell
[bool] HandleKeyPress([System.ConsoleKeyInfo]$key) {
    switch ($key.Key) {
        'A' {
            # Handle 'A' key
            return $true  # Mark as handled
        }
        'Escape' {
            $global:PmcApp.PopScreen()
            return $true
        }
    }
    # Let base class handle it
    return ([PmcScreen]$this).HandleKeyPress($key)
}
```

### Subscribe to Data Changes

```powershell
$store = [TaskStore]::GetInstance()
$store.OnTasksChanged = {
    param($tasks)
    # $tasks = array of changed tasks
    $this.RefreshUI()
}.GetNewClosure()  # CRITICAL: Use GetNewClosure() for closures!
```

### Register a Menu Item

```powershell
$registry = $container.Resolve('MenuRegistry')
$registry.AddMenuItem('Tasks', 'Label', 'H', {
    # Action code here
    $global:PmcApp.PushScreen($screen)
})
```

---

## Architecture Decision Summary

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| Hybrid DI | Single-user tool simplification | Not enterprise-grade |
| PowerShell classes | Inheritance needed | Dual constructors required |
| Global variables | Eliminate param explosion | Less pure |
| Logging off by default | 30-40% CPU reduction | Must enable for debugging |
| Observable data model | Screen auto-refresh on changes | Requires event subscription |
| Cell-based differential rendering | 70-80% less I/O | More complex buffering |
| Manual testing only | Fast iteration | No regression detection |
| Hidden fields | Proper encapsulation | Harder to debug |

---

## Debugging Quick Tips

| Issue | Quick Fix |
|-------|-----------|
| Screen not updating | Check IsDirty flag, call RequestRender() |
| Input not working | Verify HandleKeyPress returns true |
| Data not persisting | Check TaskStore.HasPendingChanges |
| Menu items not showing | Verify MenuRegistry.AddMenuItem called |
| Widget not rendering | Check RenderToEngine or Render method |
| Terminal corruption | Call NeedsClear=true, then RequestRender() |
| Theme colors wrong | Verify PmcThemeManager initialized |
| Performance issues | Check logging enabled (30-40% CPU!), check render frequency |

---

## File Organization Best Practices

- **One class per file** (except base/ which may have related classes)
- **Screens in screens/** (TaskListScreen.ps1, ProjectListScreen.ps1, etc.)
- **Widgets in widgets/** (TextInput.ps1, DatePicker.ps1, etc.)
- **Services in services/** (TaskStore.ps1, MenuRegistry.ps1, etc.)
- **Helpers in helpers/** (ConfigCache.ps1, ValidationHelper.ps1, etc.)
- **Base classes in base/** (StandardListScreen.ps1, StandardFormScreen.ps1)
- **Tests in tests/** (TestTaskListScreen.ps1, TestTextInput.ps1)

---

## Key Files to Study First

1. **PmcScreen.ps1** (400 lines) - Foundation for all screens
2. **Start-PmcTUI.ps1** (456 lines) - Bootstrap & event loop
3. **TaskListScreen.ps1** (1179 lines) - Complete screen example
4. **StandardListScreen.ps1** (300+ lines) - Pattern for list screens
5. **TaskStore.ps1** (600+ lines) - Observable data model
6. **UniversalList.ps1** (400+ lines) - Reusable list widget
7. **ServiceContainer.ps1** (158 lines) - DI implementation

---

## Resources

- **ARCHITECTURE_DECISIONS.md** - Explains 10 key design decisions
- **PMC_ARCHITECTURE_ANALYSIS.md** - Comprehensive 1279-line analysis
- **SCREEN_PATTERNS.md** (.claude/docs/) - Screen implementation patterns
- **WIDGET_CONTRACTS.md** (.claude/docs/) - Widget API reference
- **COMMON_FIXES.md** (.claude/docs/) - Recurring issues & solutions

---

**Questions?** Check the relevant documentation in `.claude/docs/` or review existing implementations.
