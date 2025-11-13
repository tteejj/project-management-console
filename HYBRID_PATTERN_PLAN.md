# Hybrid DI + Globals Pattern - Implementation Plan

## Pattern Definition

### Global Singletons (Application-Level)
**Use `$global:Pmc.*` for:**
- Application reference (used everywhere)
- Logger (logging from anywhere)
- Theme manager (theming everywhere)

```powershell
$global:Pmc = @{
    App = $null              # PmcApplication instance
    Logger = $null           # LoggingService instance
    Theme = $null            # PmcThemeManager instance
    Container = $null        # ServiceContainer reference
}
```

**Access pattern:**
```powershell
$global:Pmc.App.NavigateTo($screen)
$global:Pmc.Logger.Write('INFO', 'message')
$global:Pmc.Theme.GetColor('Primary')
```

### DI Container (Business Services)
**Use `$container.Resolve()` for:**
- TaskStore, NoteService, CommandService
- ChecklistService, PreferencesService
- MenuRegistry, ExcelMappingService
- Any service passed to class constructors

```powershell
# Register in ServiceContainer
$container.RegisterSingleton('TaskStore', { [TaskStore]::new() })
$container.RegisterSingleton('NoteService', { [NoteService]::new() })

# Resolve in classes
class MyScreen {
    [TaskStore] $TaskStore

    MyScreen([ServiceContainer] $container) {
        $this.TaskStore = $container.Resolve('TaskStore')
    }
}
```

---

## Service Classification

### Global Services (3)
| Service | Reason | Usage Count |
|---------|--------|-------------|
| PmcApplication | App reference used everywhere | ~100+ |
| LoggingService | Logging from anywhere | ~100+ |
| PmcThemeManager | Theming used in all widgets | ~50+ |

### DI Services (8)
| Service | Reason | GetInstance Count |
|---------|--------|-------------------|
| TaskStore | Business logic, passed to screens | 20 in 15 files |
| NoteService | Business logic | 5-10 |
| CommandService | Business logic | 5-10 |
| ChecklistService | Business logic | 5-10 |
| PreferencesService | Business logic | 5-10 |
| MenuRegistry | Screen-specific | 5-10 |
| ExcelMappingService | Feature-specific | 2-3 |
| ExcelComReader | Feature-specific | 1-2 |

---

## Migration Tasks

### Phase 1: Setup Global Structure
**File:** `Start-PmcTUI.ps1`

```powershell
# Initialize global structure EARLY
$global:Pmc = @{
    App = $null
    Logger = $null
    Theme = $null
    Container = $null
}

# After services loaded, initialize
$global:Pmc.Logger = [LoggingService]::new($global:PmcTuiLogFile)
$global:Pmc.Theme = [PmcThemeManager]::new()  # Remove GetInstance, use constructor

# After container created
$global:Pmc.Container = $container

# After app created
$global:Pmc.App = $app
```

### Phase 2: Remove GetInstance() Methods
**Files to modify (8):**
- ✅ LoggingService.ps1 (already doesn't have GetInstance)
- ❌ PmcThemeManager.ps1 - Remove GetInstance, make constructible
- ❌ TaskStore.ps1 - Remove GetInstance
- ❌ NoteService.ps1 - Remove GetInstance
- ❌ CommandService.ps1 - Remove GetInstance
- ❌ ChecklistService.ps1 - Remove GetInstance
- ❌ PreferencesService.ps1 - Remove GetInstance
- ❌ MenuRegistry.ps1 - Remove GetInstance
- ❌ ExcelMappingService.ps1 - Remove GetInstance

**Pattern:**
```powershell
# REMOVE:
static [TaskStore] GetInstance() {
    if ($null -eq [TaskStore]::_instance) {
        [TaskStore]::_instance = [TaskStore]::new()
    }
    return [TaskStore]::_instance
}

# Keep constructor as-is (already public)
TaskStore() {
    # ...
}
```

### Phase 3: Register All Services in Container
**File:** `ServiceContainer.ps1` or setup script

```powershell
# Register all DI services as singletons
$container.RegisterSingleton('TaskStore', {
    [TaskStore]::new()
})

$container.RegisterSingleton('NoteService', {
    [NoteService]::new()
})

$container.RegisterSingleton('CommandService', {
    [CommandService]::new()
})

$container.RegisterSingleton('ChecklistService', {
    [ChecklistService]::new()
})

$container.RegisterSingleton('PreferencesService', {
    [PreferencesService]::new()
})

$container.RegisterSingleton('MenuRegistry', {
    [MenuRegistry]::new()
})

$container.RegisterSingleton('ExcelMappingService', {
    [ExcelMappingService]::new()
})
```

### Phase 4: Update All GetInstance() Callers

**TaskStore: 20 occurrences in 15 files**
```powershell
# BEFORE:
$store = [TaskStore]::GetInstance()

# AFTER (in classes with $container):
$this.TaskStore = $container.Resolve('TaskStore')

# AFTER (in standalone scripts):
$store = $global:Pmc.Container.Resolve('TaskStore')
```

**Files to update:**
- Start-PmcTUI.ps1
- ServiceContainer.ps1 (2 calls)
- PmcApplication.ps1 (2 calls)
- base/StandardDashboard.ps1
- base/StandardFormScreen.ps1
- base/StandardListScreen.ps1
- screens/WeeklyTimeReportScreen.ps1 (2 calls)
- screens/BlockedTasksScreen.ps1
- screens/ExcelImportScreen.ps1
- services/TaskStore.ps1 (2 internal calls)
- widgets/ProjectPicker.ps1 (2 calls)
- tests/TestTaskListScreen.ps1

**PmcThemeManager: 5 occurrences in 5 files**
```powershell
# BEFORE:
$theme = [PmcThemeManager]::GetInstance()

# AFTER (everywhere):
$theme = $global:Pmc.Theme
```

**Files to update:**
- Start-PmcTUI.ps1
- theme/PmcThemeManager.ps1 (internal)
- tests/DemoScreen.ps1
- screens/TimeListScreen.ps1
- widgets/TestWidgetScreen.ps1

---

## Widget Rendering Migration

### Current Pattern (OnRender → StringBuilder)
```powershell
class PmcFooter : PmcWidget {
    [string] OnRender() {
        $sb = [StringBuilder]::new(512)
        $sb.Append($this.BuildMoveTo(0, $this.Y))
        $sb.Append($this.GetThemedAnsi('Border'))
        $sb.Append("Footer text")
        return $sb.ToString()
    }
}
```

### New Pattern (RenderToBuffer)
```powershell
class PmcFooter : PmcWidget {
    [void] RenderToBuffer([OptimizedRenderEngine] $engine) {
        $ansi = $this.GetThemedAnsi('Border')
        $engine.WriteAt($this.X, $this.Y, "$ansi`Footer text")
    }
}
```

### Widgets to Migrate (26)
**Base classes (migrate first, others inherit):**
1. PmcWidget.ps1 - Add RenderToBuffer() method
2. PmcPanel.ps1 - Override RenderToBuffer()

**Simple widgets (low complexity):**
3. PmcFooter.ps1
4. PmcHeader.ps1
5. PmcStatusBar.ps1
6. PmcMenuBar.ps1

**Medium complexity:**
7-20. Various list/form widgets (14 widgets)

**Complex widgets:**
21-26. UniversalList, InlineEditor, FilterPanel, etc. (6 widgets)

### Screen Rendering Update
**File:** `PmcScreen.ps1`

```powershell
# REMOVE:
[string] Render() {
    # Returns ANSI string
}

# ADD:
[void] RenderToEngine([OptimizedRenderEngine] $engine) {
    # MenuBar
    if ($this.MenuBar) {
        $this.MenuBar.RenderToBuffer($engine)
    }

    # Header
    if ($this.Header) {
        $this.Header.RenderToBuffer($engine)
    }

    # Content (override in derived classes)
    $this.RenderContent($engine)

    # Footer
    if ($this.Footer) {
        $this.Footer.RenderToBuffer($engine)
    }

    # StatusBar
    if ($this.StatusBar) {
        $this.StatusBar.RenderToBuffer($engine)
    }
}

# Override in derived classes:
[void] RenderContent([OptimizedRenderEngine] $engine) {
    # Screen-specific content rendering
}
```

---

## Implementation Order

### Week 1: Service Migration
**Day 1:** Setup global structure + remove GetInstance() methods (8 files)
**Day 2:** Register services in container
**Day 3:** Update GetInstance() callers (20 files)
**Day 4:** Update PmcThemeManager callers (5 files)
**Day 5:** Testing, bug fixes

### Week 2: Widget Migration
**Day 1:** Update PmcWidget + PmcPanel base classes
**Day 2:** Migrate simple widgets (4 widgets)
**Day 3:** Migrate medium widgets (7 widgets)
**Day 4:** Migrate medium widgets continued (7 widgets)
**Day 5:** Migrate complex widgets (6 widgets)

### Week 3: Screen Migration
**Day 1:** Update PmcScreen base class
**Day 2:** Update StandardListScreen, StandardFormScreen, StandardDashboard
**Day 3:** Update remaining screens (inherit from base)
**Day 4:** Testing
**Day 5:** Bug fixes, polish

---

## Success Criteria

✅ **Zero GetInstance() methods remain**
✅ **All services use DI or globals (no mixing)**
✅ **All widgets use RenderToBuffer (no OnRender strings)**
✅ **All screens use RenderToEngine**
✅ **OptimizedRenderEngine differential rendering works**
✅ **No performance regression**

---

## Breaking Changes

### For Service Access:
```powershell
# OLD:
$store = [TaskStore]::GetInstance()

# NEW (in classes):
class MyScreen {
    [TaskStore] $TaskStore
    MyScreen([ServiceContainer] $container) {
        $this.TaskStore = $container.Resolve('TaskStore')
    }
}

# NEW (in scripts):
$store = $global:Pmc.Container.Resolve('TaskStore')
```

### For Theme Access:
```powershell
# OLD:
$theme = [PmcThemeManager]::GetInstance()

# NEW:
$theme = $global:Pmc.Theme
```

### For Widget Rendering:
```powershell
# OLD:
[string] OnRender() {
    return $ansiString
}

# NEW:
[void] RenderToBuffer([OptimizedRenderEngine] $engine) {
    $engine.WriteAt($x, $y, $content)
}
```

---

## Files Modified Summary

**Services (8 files):**
- PmcThemeManager.ps1
- TaskStore.ps1
- NoteService.ps1
- CommandService.ps1
- ChecklistService.ps1
- PreferencesService.ps1
- MenuRegistry.ps1
- ExcelMappingService.ps1

**Service Callers (~25 files):**
- All screens/widgets that call GetInstance()

**Widgets (26 files):**
- All widget files to use RenderToBuffer

**Screens (~40 files):**
- All screen files to use RenderToEngine

**Core (3 files):**
- Start-PmcTUI.ps1 (global initialization)
- PmcApplication.ps1 (remove old rendering path)
- PmcScreen.ps1 (new rendering method)

**Total: ~100 files** (manageable with systematic approach)
