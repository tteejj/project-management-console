# PMC + SpeedTUI Architecture Design Document
**Version:** 1.0
**Date:** 2025-11-05
**Status:** Design Phase - For Review

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Design Principles](#design-principles)
3. [Component Hierarchy](#component-hierarchy)
4. [Base Class Architecture](#base-class-architecture)
5. [State Management Strategy](#state-management-strategy)
6. [Rendering Pipeline](#rendering-pipeline)
7. [Screen Classification & Mapping](#screen-classification--mapping)
8. [Implementation Roadmap](#implementation-roadmap)
9. [Code Examples](#code-examples)
10. [Validation Checklist](#validation-checklist)

---

## Executive Summary

### Goals
- **Replace** PMC's flickering terminal engine with SpeedTUI's differential renderer
- **Create proper base classes** that reduce code duplication by 80%
- **Support all 58 existing screens** with minimal custom code
- **Enable future extensibility** through clean architecture

### Key Decisions
1. **Use SpeedTUI's Component base** - battle-tested, performant
2. **Model-View-Update pattern** for state management (predictable, testable)
3. **3-level hierarchy max** - avoid deep nesting
4. **Virtual scrolling everywhere** - handle large datasets
5. **Composition over inheritance** - flexible screen building

### Non-Goals
- ❌ Backwards compatibility with old PmcSimpleTerminal
- ❌ Supporting both FakeTUI and ConsoleUI simultaneously
- ❌ Preserving scroll/selection state between view switches (for now)

---

## Design Principles

### 1. **Separation of Concerns**
```
Data Layer       → Storage, business logic (Keep as-is)
   ↓
State Layer      → App state, UI state (NEW: PmcAppState)
   ↓
Component Layer  → SpeedTUI components (NEW: Base classes)
   ↓
Render Layer     → SpeedTUI renderer (IMPORT: RenderEngine)
   ↓
Terminal Layer   → SpeedTUI terminal (IMPORT: Terminal)
```

### 2. **Container vs Leaf Components**
- **Containers**: Layout children, no direct rendering
  - `PmcScreen` (base for all screens)
  - `PmcPanel` (bordered sections)
  - `PmcSplitView` (multi-pane layouts)

- **Leaves**: Render content, interactive
  - `PmcTaskList` (virtual scrolling list)
  - `PmcForm` (input fields)
  - `PmcButton` (clickable button)
  - `PmcTable` (data grid)

### 3. **Shallow Hierarchies**
```
✅ GOOD (3 levels):
PmcApp
└── TaskListScreen (PmcScreen)
    ├── PmcPanel (header)
    └── PmcTaskList (content)

❌ BAD (7 levels):
PmcApp
└── MainContainer
    └── ScreenContainer
        └── TaskListScreen
            └── ContentContainer
                └── ListWrapper
                    └── PmcTaskList
```

### 4. **Immutable State Updates**
```powershell
# ❌ BAD - Mutating state
$app.State.Tasks += $newTask
$app.RefreshScreen()

# ✅ GOOD - Immutable update
$newState = $app.State.Clone()
$newState.Tasks += $newTask
$app.SetState($newState)  # Auto-invalidates affected components
```

### 5. **Performance First**
- Virtual scrolling for lists >50 items
- Double buffering at terminal level
- Component-level dirty tracking
- Pre-compute expensive calculations
- StringBuilder pooling
- String caching (spaces, ANSI sequences)

---

## Component Hierarchy

### Overall Structure
```
SpeedTUI Component (base class - from SpeedTUI)
    │
    ├─→ PmcComponent (PMC-specific base)
    │   │
    │   ├─→ PmcContainer (layout only)
    │   │   │
    │   │   ├─→ PmcScreen (all screens inherit)
    │   │   ├─→ PmcPanel (bordered sections)
    │   │   ├─→ PmcSplitView (2-pane layouts)
    │   │   └─→ PmcFlexBox (flexible layouts)
    │   │
    │   └─→ PmcLeaf (interactive widgets)
    │       │
    │       ├─→ PmcTaskList (virtual list)
    │       ├─→ PmcForm (input fields)
    │       ├─→ PmcTable (data grid)
    │       ├─→ PmcButton (clickable)
    │       ├─→ PmcInput (text field)
    │       ├─→ PmcLabel (static text)
    │       └─→ PmcChart (visualizations)
    │
    └─→ Concrete Screens (inherit PmcScreen)
        │
        ├─→ TaskListScreen
        ├─→ ProjectListScreen
        ├─→ KanbanScreen
        ├─→ TaskWizardScreen
        └─→ ... (58 screens total)
```

### Why This Structure?

**SpeedTUI Component** (unchanged)
- Provides: lifecycle, rendering, focus, caching
- We don't modify this

**PmcComponent** (our adapter)
- Adds: PMC-specific services (data access, navigation)
- Provides: common PMC helpers (DrawHeader, ShowError)

**PmcContainer vs PmcLeaf**
- **Container**: Has children, manages layout
- **Leaf**: No children, renders content

**PmcScreen** (base for all screens)
- Handles: navigation, data loading, lifecycle
- Provides: header/footer, error dialogs, confirmation

**Concrete Screens**
- Override: `BuildUI()`, `LoadData()`, `HandleAction()`
- That's it - everything else is inherited

---

## Base Class Architecture

### 1. PmcComponent (Adapter Layer)

```powershell
class PmcComponent : Component {
    # Services (dependency injection)
    [PmcDataService]$DataService
    [PmcNavigationService]$NavigationService
    [PmcThemeService]$ThemeService

    # Common state
    [bool]$IsLoading = $false
    [string]$ErrorMessage = ""

    PmcComponent() : base() {
        # Initialize services
        $this.DataService = [PmcDataService]::GetInstance()
        $this.NavigationService = [PmcNavigationService]::GetInstance()
        $this.ThemeService = [PmcThemeService]::GetInstance()

        # Apply PMC theme
        $this.SetTheme("pmc-default")
    }

    # === PMC HELPERS ===

    [void] ShowError([string]$message) {
        # Show error dialog (modal)
        $dialog = [PmcErrorDialog]::new($message)
        # ... show dialog ...
    }

    [void] ShowConfirm([string]$message, [scriptblock]$onConfirm) {
        # Show confirmation dialog
        $dialog = [PmcConfirmDialog]::new($message, $onConfirm)
        # ... show dialog ...
    }

    [void] NavigateTo([string]$screenName) {
        $this.NavigationService.NavigateTo($screenName)
    }

    [void] NavigateBack() {
        $this.NavigationService.GoBack()
    }
}
```

**Why?**
- All PMC components get services automatically
- Common UI patterns (error, confirm) available everywhere
- Navigation abstracted from implementation
- Theme management centralized

### 2. PmcScreen (Base for All Screens)

```powershell
class PmcScreen : PmcComponent {
    # Identity
    [string]$ScreenTitle = ""
    [string]$ScreenKey = ""

    # Lifecycle hooks (override in subclasses)
    [scriptblock]$OnEnter = {}
    [scriptblock]$OnExit = {}
    [scriptblock]$OnRefresh = {}

    # Layout areas
    hidden [int]$_headerHeight = 3
    hidden [int]$_footerHeight = 2
    hidden [int]$_contentY
    hidden [int]$_contentHeight

    PmcScreen([string]$key, [string]$title) : base() {
        $this.ScreenKey = $key
        $this.ScreenTitle = $title
        $this.CanFocus = $false  # Screens don't need focus (children do)

        # Calculate layout (will be recalculated on resize)
        $this._CalculateLayout()

        # Build UI (override in subclass)
        $this.BuildUI()
    }

    # === ABSTRACT METHODS (Override these) ===

    [void] BuildUI() {
        # Override to add components
        # Example:
        # $taskList = [PmcTaskList]::new()
        # $this.AddChild($taskList)
    }

    [void] LoadData() {
        # Override to load screen data
        # Example:
        # $data = $this.DataService.GetAllTasks()
        # $this.TaskList.SetItems($data)
    }

    [string] GetFooterText() {
        # Override for custom footer
        return "Esc: Back | F10: Menu"
    }

    # === LIFECYCLE ===

    [void] Enter() {
        # Called when screen becomes visible
        $this.LoadData()

        if ($this.OnEnter) {
            & $this.OnEnter $this
        }

        $this.Invalidate()
    }

    [void] Exit() {
        # Called when leaving screen
        if ($this.OnExit) {
            & $this.OnExit $this
        }
    }

    [void] Refresh() {
        # Called to reload data
        $this.LoadData()

        if ($this.OnRefresh) {
            & $this.OnRefresh $this
        }

        $this.Invalidate()
    }

    # === RENDERING ===

    [string] OnRender() {
        $sb = Get-PooledStringBuilder 2048

        # Render header
        $sb.Append($this._RenderHeader())

        # Children render themselves (content area)
        # (Component base class handles this automatically)

        # Render footer
        $sb.Append($this._RenderFooter())

        # Loading overlay
        if ($this.IsLoading) {
            $sb.Append($this._RenderLoadingOverlay())
        }

        # Error overlay
        if (-not [string]::IsNullOrEmpty($this.ErrorMessage)) {
            $sb.Append($this._RenderErrorOverlay())
        }

        $result = $sb.ToString()
        Return-PooledStringBuilder $sb
        return $result
    }

    hidden [string] _RenderHeader() {
        $sb = Get-PooledStringBuilder 512

        # Move to top
        $sb.Append([InternalVT100]::MoveTo(0, 0))

        # Title (centered)
        $titleX = ($this.Width - $this.ScreenTitle.Length) / 2
        $sb.Append([InternalVT100]::MoveTo($titleX, 1))
        $sb.Append([InternalVT100]::Cyan())
        $sb.Append([InternalVT100]::Bold())
        $sb.Append($this.ScreenTitle)
        $sb.Append([InternalVT100]::Reset())

        # Horizontal line
        $sb.Append([InternalVT100]::MoveTo(0, 2))
        $sb.Append([InternalStringCache]::GetSpaces(1))  # Left padding
        $sb.Append("─" * ($this.Width - 2))

        $result = $sb.ToString()
        Return-PooledStringBuilder $sb
        return $result
    }

    hidden [string] _RenderFooter() {
        $sb = Get-PooledStringBuilder 256

        $footerY = $this.Height - 2
        $footerText = $this.GetFooterText()

        # Horizontal line
        $sb.Append([InternalVT100]::MoveTo(0, $footerY))
        $sb.Append("─" * ($this.Width - 2))

        # Footer text (centered)
        $textX = ($this.Width - $footerText.Length) / 2
        $sb.Append([InternalVT100]::MoveTo($textX, $footerY + 1))
        $sb.Append([InternalVT100]::Dim())
        $sb.Append($footerText)
        $sb.Append([InternalVT100]::Reset())

        $result = $sb.ToString()
        Return-PooledStringBuilder $sb
        return $result
    }

    hidden [void] _CalculateLayout() {
        $this._contentY = $this._headerHeight
        $this._contentHeight = $this.Height - $this._headerHeight - $this._footerHeight
    }

    [void] OnBoundsChanged() {
        ([Component]$this).OnBoundsChanged()
        $this._CalculateLayout()

        # Update children bounds to fit content area
        foreach ($child in $this.Children) {
            $child.SetPosition(1, $this._contentY)
            $child.SetSize($this.Width - 2, $this._contentHeight)
        }
    }
}
```

**Why PmcScreen?**
- ✅ Every screen gets header/footer automatically
- ✅ Lifecycle hooks (Enter/Exit/Refresh) standardized
- ✅ Loading/error overlays built-in
- ✅ Content area calculated automatically
- ✅ Children positioned in content area
- ✅ Only 3 methods to override: `BuildUI()`, `LoadData()`, `GetFooterText()`

### 3. PmcListScreen (Specialized for Lists)

```powershell
class PmcListScreen : PmcScreen {
    [PmcTaskList]$List  # The list widget

    # State
    [array]$Items = @()
    [int]$SelectedIndex = 0

    # Filtering/Sorting
    [string]$FilterText = ""
    [string]$SortBy = "default"

    PmcListScreen([string]$key, [string]$title) : base($key, $title) {
    }

    [void] BuildUI() {
        # Create list widget
        $this.List = [PmcTaskList]::new()
        $this.List.SetPosition(1, $this._contentY)
        $this.List.SetSize($this.Width - 2, $this._contentHeight)
        $this.List.CanFocus = $true

        # Hook up events
        $this.List.OnItemSelected = {
            param($item)
            $this.HandleItemSelected($item)
        }

        $this.AddChild($this.List)
    }

    [void] LoadData() {
        # Override in subclass
        # Example:
        # $this.Items = $this.DataService.GetAllTasks()
        # $this.List.SetItems($this.Items)
    }

    # === ABSTRACT METHODS ===

    [void] HandleItemSelected([object]$item) {
        # Override to handle Enter key on item
    }

    [array] FormatItems([array]$items) {
        # Override for custom formatting
        return $items
    }

    # === FILTERING/SORTING ===

    [void] ApplyFilter([string]$text) {
        $this.FilterText = $text
        $this._RefreshList()
    }

    [void] ApplySort([string]$sortBy) {
        $this.SortBy = $sortBy
        $this._RefreshList()
    }

    hidden [void] _RefreshList() {
        $filtered = $this._FilterItems($this.Items)
        $sorted = $this._SortItems($filtered)
        $formatted = $this.FormatItems($sorted)
        $this.List.SetItems($formatted)
    }

    hidden [array] _FilterItems([array]$items) {
        if ([string]::IsNullOrWhiteSpace($this.FilterText)) {
            return $items
        }

        return $items | Where-Object {
            $_.Text -like "*$($this.FilterText)*"
        }
    }

    hidden [array] _SortItems([array]$items) {
        switch ($this.SortBy) {
            'priority' { return $items | Sort-Object -Property Priority }
            'duedate' { return $items | Sort-Object -Property DueDate }
            default { return $items }
        }
    }

    [string] GetFooterText() {
        return "↑↓: Navigate | Enter: Select | F: Filter | S: Sort | Esc: Back"
    }

    [bool] HandleKeyPress([System.ConsoleKeyInfo]$key) {
        # Handle list-specific keys
        switch ($key.KeyChar) {
            'f' {
                $this._ShowFilterDialog()
                return $true
            }
            's' {
                $this._ShowSortDialog()
                return $true
            }
        }

        # Let base handle rest
        return ([PmcScreen]$this).HandleKeyPress($key)
    }
}
```

**Why PmcListScreen?**
- ✅ Handles 40% of PMC screens (all list views)
- ✅ Filtering/sorting built-in
- ✅ Virtual scrolling handled by PmcTaskList widget
- ✅ Only 2 methods to override: `LoadData()`, `HandleItemSelected()`
- ✅ Selection state managed automatically

### 4. PmcFormScreen (Specialized for Forms)

```powershell
class PmcFormScreen : PmcScreen {
    [PmcForm]$Form  # The form widget
    [hashtable]$FieldDefinitions = @{}

    PmcFormScreen([string]$key, [string]$title) : base($key, $title) {
    }

    [void] BuildUI() {
        # Create form widget
        $this.Form = [PmcForm]::new()
        $this.Form.SetPosition(1, $this._contentY)
        $this.Form.SetSize($this.Width - 2, $this._contentHeight)
        $this.Form.CanFocus = $true

        # Define fields (override in subclass)
        $this.DefineFields()

        # Build form from definitions
        foreach ($fieldDef in $this.FieldDefinitions.Values) {
            $this.Form.AddField(
                $fieldDef.Name,
                $fieldDef.Label,
                $fieldDef.Type,
                $fieldDef.Required,
                $fieldDef.Validator
            )
        }

        # Hook up submit
        $this.Form.OnSubmit = {
            param($values)
            $this.HandleSubmit($values)
        }

        $this.AddChild($this.Form)
    }

    # === ABSTRACT METHODS ===

    [void] DefineFields() {
        # Override to add fields
        # Example:
        # $this.AddField('text', 'Task description', 'text', $true, { ValidateNotEmpty $_ })
        # $this.AddField('duedate', 'Due date', 'date', $false, { ValidateDate $_ })
    }

    [void] HandleSubmit([hashtable]$values) {
        # Override to save data
    }

    # === FIELD HELPERS ===

    [void] AddField([string]$name, [string]$label, [string]$type, [bool]$required, [scriptblock]$validator) {
        $this.FieldDefinitions[$name] = @{
            Name = $name
            Label = $label
            Type = $type
            Required = $required
            Validator = $validator
        }
    }

    [void] SetFieldValue([string]$name, [object]$value) {
        $this.Form.SetFieldValue($name, $value)
    }

    [object] GetFieldValue([string]$name) {
        return $this.Form.GetFieldValue($name)
    }

    [string] GetFooterText() {
        return "Tab: Next field | Enter: Submit | Esc: Cancel"
    }
}
```

**Why PmcFormScreen?**
- ✅ Handles 30% of PMC screens (add/edit forms)
- ✅ Field validation built-in
- ✅ Tab navigation automatic
- ✅ Only 2 methods to override: `DefineFields()`, `HandleSubmit()`
- ✅ Real-time validation support

---

## State Management Strategy

### Model-View-Update Pattern (Elm Architecture)

```powershell
# === MODEL (Immutable State) ===

class PmcAppState {
    [string]$CurrentView = "main"
    [string]$PreviousView = ""

    # Data
    [array]$AllTasks = @()
    [array]$AllProjects = @()
    [array]$AllTimeLogs = @()

    # UI State
    [hashtable]$ScreenState = @{}  # Per-screen state (scroll, selection, filter)

    # Config
    [hashtable]$Config = @{}
    [string]$Theme = "default"

    # Clone for immutability
    [PmcAppState] Clone() {
        $newState = [PmcAppState]::new()
        $newState.CurrentView = $this.CurrentView
        $newState.PreviousView = $this.PreviousView
        $newState.AllTasks = $this.AllTasks.Clone()
        $newState.AllProjects = $this.AllProjects.Clone()
        $newState.AllTimeLogs = $this.AllTimeLogs.Clone()
        $newState.ScreenState = $this.ScreenState.Clone()
        $newState.Config = $this.Config.Clone()
        $newState.Theme = $this.Theme
        return $newState
    }
}

# === MESSAGES (Events) ===

class PmcMessage {
    [string]$Type
    [hashtable]$Payload

    PmcMessage([string]$type, [hashtable]$payload) {
        $this.Type = $type
        $this.Payload = $payload
    }
}

# Message types (constants)
class PmcMsgType {
    static [string]$TaskAdded = "TaskAdded"
    static [string]$TaskEdited = "TaskEdited"
    static [string]$TaskDeleted = "TaskDeleted"
    static [string]$TaskCompleted = "TaskCompleted"
    static [string]$ViewChanged = "ViewChanged"
    static [string]$FilterChanged = "FilterChanged"
    static [string]$SortChanged = "SortChanged"
}

# === UPDATE (Pure Function) ===

function Update-PmcState {
    param([PmcAppState]$State, [PmcMessage]$Msg)

    $newState = $State.Clone()

    switch ($Msg.Type) {
        ([PmcMsgType]::TaskAdded) {
            $newTask = $Msg.Payload.Task
            $newState.AllTasks += $newTask

            # Save to disk
            Save-PmcData -Tasks $newState.AllTasks
        }

        ([PmcMsgType]::TaskCompleted) {
            $taskId = $Msg.Payload.TaskId
            $task = $newState.AllTasks | Where-Object { $_.Id -eq $taskId }
            if ($task) {
                $task.Status = 'completed'
                $task.CompletedDate = Get-Date

                # Save to disk
                Save-PmcData -Tasks $newState.AllTasks
            }
        }

        ([PmcMsgType]::ViewChanged) {
            $newState.PreviousView = $newState.CurrentView
            $newState.CurrentView = $Msg.Payload.ViewName
        }

        ([PmcMsgType]::FilterChanged) {
            $screenKey = $Msg.Payload.ScreenKey
            if (-not $newState.ScreenState.ContainsKey($screenKey)) {
                $newState.ScreenState[$screenKey] = @{}
            }
            $newState.ScreenState[$screenKey].FilterText = $Msg.Payload.FilterText
        }
    }

    return $newState
}

# === APPLICATION (Orchestrator) ===

class PmcApplication {
    [PmcAppState]$State
    [hashtable]$Screens = @{}
    [PmcScreen]$CurrentScreen

    [Application]$SpeedTUIApp  # SpeedTUI application

    PmcApplication() {
        # Initialize state
        $this.State = [PmcAppState]::new()
        $this.State.Config = Get-PmcConfig

        # Load initial data
        $data = Get-PmcAllData
        $this.State.AllTasks = $data.tasks
        $this.State.AllProjects = $data.projects

        # Register screens
        $this.RegisterScreens()

        # Initialize SpeedTUI
        $this.SpeedTUIApp = [Application]::new("PMC Console")

        # Navigate to initial screen
        $this.NavigateTo("main")
    }

    [void] RegisterScreens() {
        # Register all screens
        $this.Screens["tasklist"] = [TaskListScreen]::new("tasklist", "All Tasks")
        $this.Screens["projectlist"] = [ProjectListScreen]::new("projectlist", "Projects")
        $this.Screens["kanban"] = [KanbanScreen]::new("kanban", "Kanban Board")
        # ... register all 58 screens ...
    }

    [void] Dispatch([PmcMessage]$msg) {
        # Update state
        $this.State = Update-PmcState $this.State $msg

        # Notify current screen
        if ($this.CurrentScreen) {
            $this.CurrentScreen.Refresh()
        }

        # Handle view changes
        if ($msg.Type -eq [PmcMsgType]::ViewChanged) {
            $this.NavigateTo($this.State.CurrentView)
        }
    }

    [void] NavigateTo([string]$screenKey) {
        # Exit current screen
        if ($this.CurrentScreen) {
            $this.CurrentScreen.Exit()
        }

        # Get new screen
        $this.CurrentScreen = $this.Screens[$screenKey]
        if (-not $this.CurrentScreen) {
            throw "Screen not found: $screenKey"
        }

        # Enter new screen
        $this.CurrentScreen.Enter()

        # Set as SpeedTUI root
        $this.SpeedTUIApp.SetRoot($this.CurrentScreen)
    }

    [void] Run() {
        # Start SpeedTUI main loop
        $this.SpeedTUIApp.Run()
    }
}
```

**Why Model-View-Update?**
- ✅ **Predictable**: Same input → same output
- ✅ **Testable**: Pure functions, easy to test
- ✅ **Debuggable**: State changes are explicit messages
- ✅ **Time-travel**: Can replay messages for debugging
- ✅ **Undo/Redo**: Store message history, replay for undo

---

## Rendering Pipeline

### Frame Rendering Flow

```
1. User Input (key press)
      ↓
2. Dispatch Message
      ↓
3. Update-PmcState() → new state
      ↓
4. CurrentScreen.Refresh()
      ↓
5. Screen.LoadData() → update widgets
      ↓
6. Widgets.Invalidate() → mark dirty
      ↓
7. SpeedTUI Render Loop
      ↓
8. Component.Render() (only dirty components)
      ↓
9. RenderEngine.EndFrame() → differential update
      ↓
10. Terminal writes changes (single atomic write)
```

### Performance Optimizations

**1. Dirty Tracking (Component Level)**
```powershell
# Only render components marked dirty
if (-not $this._needsRedraw) {
    return $this._cachedRenderResult  # FAST PATH
}
```

**2. Virtual Scrolling (List Level)**
```powershell
# Only render visible items
$visibleSlice = $this.Items[$scrollOffset..($scrollOffset + $visibleCount)]
foreach ($item in $visibleSlice) {
    $this.RenderItem($item)
}
```

**3. Differential Rendering (Terminal Level)**
```powershell
# Only write changed cells
$changes = Compare-Buffers $frontBuffer $backBuffer
foreach ($change in $changes) {
    Write-AtPosition $change.X $change.Y $change.Text
}
```

**4. Pre-computation (Layout Level)**
```powershell
# Calculate once, reuse
[void] OnBoundsChanged() {
    $this._borderTop = "┌" + ("─" * ($this.Width - 2)) + "┐"
    $this._borderBottom = "└" + ("─" * ($this.Width - 2)) + "┘"
}
```

---

## Screen Classification & Mapping

### List Screens (40%) → PmcListScreen

| Current Screen | Base Class | Custom Code Needed |
|----------------|------------|--------------------|
| TaskListScreen | PmcListScreen | LoadData(), HandleItemSelected() |
| ProjectListScreen | PmcListScreen | LoadData(), HandleItemSelected() |
| TimeListScreen | PmcListScreen | LoadData(), HandleItemSelected() |
| TodayViewScreen | PmcListScreen | LoadData() (filtered) |
| OverdueViewScreen | PmcListScreen | LoadData() (filtered) |
| ... 8 more list screens | PmcListScreen | ~2 methods each |

**Code Reduction**: 350 lines → 30 lines per screen (90% reduction)

### Form Screens (30%) → PmcFormScreen

| Current Screen | Base Class | Custom Code Needed |
|----------------|------------|--------------------|
| TaskAddScreen | PmcFormScreen | DefineFields(), HandleSubmit() |
| TaskEditScreen | PmcFormScreen | DefineFields(), HandleSubmit(), LoadData() |
| ProjectEditScreen | PmcFormScreen | DefineFields(), HandleSubmit(), LoadData() |
| ... 7 more form screens | PmcFormScreen | ~2-3 methods each |

**Code Reduction**: 140 lines → 25 lines per screen (82% reduction)

### Specialized Screens (30%) → PmcScreen (custom)

| Current Screen | Base Class | Custom Code Needed |
|----------------|------------|--------------------|
| KanbanScreen | PmcScreen | BuildUI(), LoadData(), custom render, 2D nav |
| ProjectWizardScreen | PmcScreen | BuildUI(), multi-step logic, state accumulation |
| DependencyGraphScreen | PmcScreen | BuildUI(), graph rendering, tree structure |
| BurndownChartScreen | PmcScreen | BuildUI(), chart rendering, bar graphs |
| CalendarScreen | PmcScreen | BuildUI(), grid layout, date calculations |

**Code Reduction**: 200 lines → 100 lines per screen (50% reduction)

### Dashboard/Report Screens → PmcScreen (mostly inherited)

| Current Screen | Base Class | Custom Code Needed |
|----------------|------------|--------------------|
| AgendaViewScreen | PmcScreen | LoadData(), custom layout |
| WeekViewScreen | PmcScreen | LoadData(), calendar grid |
| ProjectStatsScreen | PmcScreen | LoadData(), stats display |

**Code Reduction**: 180 lines → 60 lines per screen (67% reduction)

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1)
1. Import SpeedTUI core files
2. Implement PmcComponent base
3. Implement PmcScreen base
4. Create PmcAppState and message system
5. Implement Update-PmcState function
6. Test with one simple screen (InfoDialog)

**Deliverable**: Hello World screen with proper architecture

### Phase 2: List Infrastructure (Week 2)
1. Implement PmcTaskList widget (virtual scrolling)
2. Implement PmcListScreen base
3. Port TaskListScreen (first production screen)
4. Port TodayViewScreen (test filtering)
5. Port ProjectListScreen (test different data type)

**Deliverable**: 3 working list screens, virtual scrolling tested

### Phase 3: Form Infrastructure (Week 3)
1. Implement PmcForm widget (field management)
2. Implement PmcFormScreen base
3. Port TaskAddScreen (first form)
4. Port TaskEditScreen (test edit mode)
5. Port ProjectEditScreen (test different fields)

**Deliverable**: 3 working form screens, validation tested

### Phase 4: Specialized Screens (Weeks 4-5)
1. Port KanbanScreen (2D navigation, multi-column)
2. Port ProjectWizardScreen (multi-step wizard)
3. Port DependencyGraphScreen (tree rendering)
4. Port CalendarScreen (grid layout)

**Deliverable**: Complex screens working, patterns established

### Phase 5: Remaining Screens (Weeks 6-7)
1. Port all remaining list screens (batch migration)
2. Port all remaining form screens (batch migration)
3. Port dashboard/report screens
4. Port utility screens (backup, settings)

**Deliverable**: All 58 screens ported

### Phase 6: Polish & Optimization (Week 8)
1. Performance tuning (all screens <10ms)
2. Theme refinement
3. Error handling improvements
4. Loading indicators
5. Keyboard shortcut conflicts resolution

**Deliverable**: Production-ready application

---

## Code Examples

### Example 1: TaskListScreen (Simple List)

```powershell
class TaskListScreen : PmcListScreen {
    TaskListScreen() : base("tasklist", "All Tasks") {
        # That's it for constructor!
    }

    [void] LoadData() {
        # Load from data service
        $this.Items = $this.DataService.GetAllTasks()

        # Update list widget
        $this.List.SetItems($this.Items)
    }

    [void] HandleItemSelected([object]$item) {
        # Navigate to detail view
        $this.NavigateTo("taskdetail?id=$($item.Id)")
    }

    [array] FormatItems([array]$items) {
        # Custom formatting (optional)
        return $items | ForEach-Object {
            @{
                Id = $_.Id
                Text = "[$($_.Status)] $($_.Text)"
                Priority = $_.Priority
                DueDate = $_.DueDate
            }
        }
    }

    [bool] HandleKeyPress([System.ConsoleKeyInfo]$key) {
        # Screen-specific hotkeys
        switch ($key.KeyChar) {
            'a' {
                $this.NavigateTo("taskadd")
                return $true
            }
            'd' {
                $this._MarkSelectedTaskDone()
                return $true
            }
        }

        # Let base handle rest (filter, sort, navigation)
        return ([PmcListScreen]$this).HandleKeyPress($key)
    }

    [string] GetFooterText() {
        return "↑↓: Navigate | Enter: Details | A: Add | D: Done | F: Filter | Esc: Back"
    }

    # Private helper
    hidden [void] _MarkSelectedTaskDone() {
        $task = $this.List.GetSelectedItem()
        if ($task) {
            $msg = [PmcMessage]::new([PmcMsgType]::TaskCompleted, @{ TaskId = $task.Id })
            $this.Dispatch($msg)
        }
    }
}
```

**Lines of code**: ~40 lines
**Old implementation**: ~350 lines
**Reduction**: 89%

### Example 2: TaskAddScreen (Simple Form)

```powershell
class TaskAddScreen : PmcFormScreen {
    TaskAddScreen() : base("taskadd", "Add New Task") {
    }

    [void] DefineFields() {
        $this.AddField('text', 'Description', 'text', $true, {
            param($value)
            if ([string]::IsNullOrWhiteSpace($value)) {
                return "Description is required"
            }
            return $null  # Valid
        })

        $this.AddField('duedate', 'Due Date', 'date', $false, {
            param($value)
            if ([string]::IsNullOrWhiteSpace($value)) {
                return $null  # Optional field
            }
            if (-not [DateTime]::TryParse($value, [ref]$null)) {
                return "Invalid date format"
            }
            return $null  # Valid
        })

        $this.AddField('priority', 'Priority', 'select', $false, {
            param($value)
            if ($value -notin @('high', 'medium', 'low', '')) {
                return "Invalid priority"
            }
            return $null  # Valid
        })
    }

    [void] HandleSubmit([hashtable]$values) {
        # Create task
        $newTask = @{
            Id = [Guid]::NewGuid().ToString()
            Text = $values['text']
            DueDate = if ($values['duedate']) { [DateTime]::Parse($values['duedate']) } else { $null }
            Priority = if ($values['priority']) { $values['priority'] } else { 'medium' }
            Status = 'active'
            CreatedDate = Get-Date
        }

        # Dispatch message
        $msg = [PmcMessage]::new([PmcMsgType]::TaskAdded, @{ Task = $newTask })
        $this.Dispatch($msg)

        # Show success message
        $this.ShowConfirm("Task added successfully. Return to task list?", {
            $this.NavigateTo("tasklist")
        })
    }
}
```

**Lines of code**: ~35 lines
**Old implementation**: ~140 lines
**Reduction**: 75%

### Example 3: KanbanScreen (Complex Custom)

```powershell
class KanbanScreen : PmcScreen {
    # Widgets
    [PmcSplitView]$SplitView
    [PmcTaskList]$TodoList
    [PmcTaskList]$InProgressList
    [PmcTaskList]$DoneList

    # State
    [int]$SelectedColumn = 0

    KanbanScreen() : base("kanban", "Kanban Board") {
    }

    [void] BuildUI() {
        # Create 3-way split
        $this.SplitView = [PmcSplitView]::new(3, 'Horizontal')
        $this.SplitView.SetPosition(1, $this._contentY)
        $this.SplitView.SetSize($this.Width - 2, $this._contentHeight)

        # Todo column
        $this.TodoList = [PmcTaskList]::new()
        $this.TodoList.Title = "TODO"
        $this.TodoList.CanFocus = $true
        $this.SplitView.AddPane($this.TodoList)

        # In Progress column
        $this.InProgressList = [PmcTaskList]::new()
        $this.InProgressList.Title = "IN PROGRESS"
        $this.InProgressList.CanFocus = $true
        $this.SplitView.AddPane($this.InProgressList)

        # Done column
        $this.DoneList = [PmcTaskList]::new()
        $this.DoneList.Title = "DONE"
        $this.DoneList.CanFocus = $true
        $this.SplitView.AddPane($this.DoneList)

        $this.AddChild($this.SplitView)

        # Set initial focus
        $this._UpdateFocus()
    }

    [void] LoadData() {
        $allTasks = $this.DataService.GetAllTasks()

        # Partition tasks by status
        $todo = $allTasks | Where-Object { $_.Status -eq 'active' -and -not $_.InProgress }
        $inProgress = $allTasks | Where-Object { $_.InProgress }
        $done = $allTasks | Where-Object { $_.Status -eq 'completed' }

        $this.TodoList.SetItems($todo)
        $this.InProgressList.SetItems($inProgress)
        $this.DoneList.SetItems($done)
    }

    [bool] HandleKeyPress([System.ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'LeftArrow' {
                if ($this.SelectedColumn -gt 0) {
                    $this.SelectedColumn--
                    $this._UpdateFocus()
                }
                return $true
            }
            'RightArrow' {
                if ($this.SelectedColumn -lt 2) {
                    $this.SelectedColumn++
                    $this._UpdateFocus()
                }
                return $true
            }
        }

        # Handle number keys for moving tasks
        if ($key.KeyChar -in @('1', '2', '3')) {
            $targetColumn = [int]$key.KeyChar - 1
            $this._MoveSelectedTask($targetColumn)
            return $true
        }

        return ([PmcScreen]$this).HandleKeyPress($key)
    }

    [string] GetFooterText() {
        return "←→: Switch column | ↑↓: Navigate | 1-3: Move task | Esc: Back"
    }

    hidden [void] _UpdateFocus() {
        # Clear all focus
        $this.TodoList.HasFocus = $false
        $this.InProgressList.HasFocus = $false
        $this.DoneList.HasFocus = $false

        # Set focus on selected column
        switch ($this.SelectedColumn) {
            0 { $this.TodoList.HasFocus = $true }
            1 { $this.InProgressList.HasFocus = $true }
            2 { $this.DoneList.HasFocus = $true }
        }

        $this.Invalidate()
    }

    hidden [void] _MoveSelectedTask([int]$targetColumn) {
        # Get current list
        $currentList = $this._GetCurrentList()
        $task = $currentList.GetSelectedItem()

        if (-not $task) { return }

        # Update task status
        $newStatus = switch ($targetColumn) {
            0 { 'active'; $task.InProgress = $false }
            1 { 'active'; $task.InProgress = $true }
            2 { 'completed'; $task.InProgress = $false }
        }
        $task.Status = $newStatus

        # Dispatch update
        $msg = [PmcMessage]::new([PmcMsgType]::TaskEdited, @{ Task = $task })
        $this.Dispatch($msg)
    }

    hidden [PmcTaskList] _GetCurrentList() {
        switch ($this.SelectedColumn) {
            0 { return $this.TodoList }
            1 { return $this.InProgressList }
            2 { return $this.DoneList }
        }
    }
}
```

**Lines of code**: ~120 lines
**Old implementation**: ~200 lines
**Reduction**: 40%
**But**: Much cleaner architecture, reusable widgets, easier to maintain

---

## Validation Checklist

Before moving to implementation, validate this design:

### Architecture Review
- [ ] Base class hierarchy is clear and shallow (3 levels max)
- [ ] Container vs Leaf separation is enforced
- [ ] State management pattern is well-defined
- [ ] Rendering pipeline is understood
- [ ] Performance optimizations are identified

### Coverage Verification
- [ ] All 58 screens can map to a base class
- [ ] Complex screens (Kanban, Wizard) are supportable
- [ ] Edge cases (dialogs, overlays) are handled
- [ ] Navigation flow is preserved
- [ ] Data loading patterns are compatible

### Developer Experience
- [ ] Screen creation is simple (3-5 methods to override)
- [ ] Common patterns are built-in (filtering, sorting, validation)
- [ ] Error handling is straightforward
- [ ] Debugging will be easier (message log, state inspection)
- [ ] Testing is possible (pure functions, component isolation)

### Performance Goals
- [ ] Virtual scrolling for all lists
- [ ] Dirty tracking at component level
- [ ] Differential rendering at terminal level
- [ ] Pre-computation of expensive operations
- [ ] Target: <10ms frame time for 95% of screens

### Migration Path
- [ ] Phase 1 deliverables are clear
- [ ] Each phase builds on previous
- [ ] Rollback is possible at each phase
- [ ] Testing checkpoints defined
- [ ] Timeline is realistic (8 weeks)

---

## Next Steps

1. **Review this document** with stakeholders
2. **Validate architecture** with a proof-of-concept
3. **Implement Phase 1** (foundation)
4. **Test with one screen** (TaskListScreen or InfoDialog)
5. **Iterate on design** based on learnings
6. **Proceed with Phase 2** once confident

---

## Appendix A: Key Design Questions to Answer

Before implementation, ensure these are answered:

1. **How do we handle modals/dialogs?**
   - Overlay components? Separate screen stack?

2. **How do we handle async operations?**
   - Loading indicators? Message-based async?

3. **How do we handle screen state persistence?**
   - Save scroll position between views?

4. **How do we handle global hotkeys?**
   - Application-level key handler?

5. **How do we handle themes?**
   - Use SpeedTUI's theme system? Custom?

6. **How do we handle window resize?**
   - Recalculate layouts? Redraw everything?

**Document answers before coding.**

---

**END OF DESIGN DOCUMENT**
