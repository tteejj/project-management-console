# PMC TUI - Comprehensive Architectural Analysis

**Project**: PMC (Project Management Console) - Terminal User Interface
**Architecture**: SpeedTUI-based VT100/ANSI rendering with PowerShell OOP
**Codebase Size**: ~68,000 lines of PowerShell code
**Current Version**: Modular multi-screen TUI with dependency injection
**Last Updated**: 2025-11-13

---

## EXECUTIVE SUMMARY

PMC TUI is a sophisticated, feature-rich terminal user interface for project management. It employs:
- **VT100/ANSI rendering** via vendored SpeedTUI framework
- **PowerShell OOP** with 87+ classes and inheritance hierarchies
- **Hybrid DI + Singleton + Globals** pattern for pragmatic single-user architecture
- **Event-driven observable data model** (TaskStore as central state)
- **40+ specialized screen classes** with 3 base templates (List, Form, Dashboard)
- **12+ widget components** extending SpeedTUI's Component class

The architecture balances **pragmatism** (single-user tool) with **maintainability** (clear patterns and layer separation).

---

## 1. OVERALL DIRECTORY STRUCTURE

```
/home/teej/pmc/
├── module/Pmc.Strict/          # Main PowerShell module
│   ├── src/                     # Core PMC functions and business logic (50+ files)
│   │   ├── Types.ps1            # Type definitions
│   │   ├── Config.ps1           # Configuration management
│   │   ├── State.ps1            # Centralized state management
│   │   ├── Tasks.ps1            # Task operations
│   │   ├── Projects.ps1         # Project operations
│   │   ├── Storage.ps1          # Data persistence
│   │   ├── Interactive.ps1      # Command-line REPL (67KB!)
│   │   ├── Theme.ps1            # Theme system
│   │   ├── Help.ps1             # Help system
│   │   └── ... (30+ more utilities)
│   │
│   ├── consoleui/               # NEW modular TUI architecture (68KB total)
│   │   ├── Start-PmcTUI.ps1     # Entry point & bootstrapping
│   │   ├── PmcApplication.ps1   # Main application class
│   │   ├── PmcScreen.ps1        # Base screen class
│   │   ├── ServiceContainer.ps1 # DI container
│   │   ├── SpeedTUILoader.ps1   # Load SpeedTUI framework
│   │   ├── DepsLoader.ps1       # Load dependencies
│   │   │
│   │   ├── base/                # Base classes (3 files)
│   │   │   ├── StandardListScreen.ps1    # List base class
│   │   │   ├── StandardFormScreen.ps1    # Form base class
│   │   │   └── StandardDashboard.ps1     # Dashboard base class
│   │   │
│   │   ├── screens/             # Concrete screen classes (40 files)
│   │   │   ├── TaskListScreen.ps1        # Main task view (1179 lines)
│   │   │   ├── ProjectListScreen.ps1     # Project list
│   │   │   ├── TaskDetailScreen.ps1      # Task detail view
│   │   │   ├── KanbanScreen.ps1          # Kanban board
│   │   │   ├── ThemeEditorScreen.ps1     # Theme customization
│   │   │   └── ... (35+ other screens)
│   │   │
│   │   ├── widgets/             # UI components (12+ widget classes)
│   │   │   ├── PmcWidget.ps1             # Base widget class
│   │   │   ├── UniversalList.ps1         # Data list with sorting/filtering
│   │   │   ├── InlineEditor.ps1          # Form field editor
│   │   │   ├── TextInput.ps1             # Text input widget
│   │   │   ├── DatePicker.ps1            # Date picker widget
│   │   │   ├── FilterPanel.ps1           # Dynamic filter builder
│   │   │   ├── PmcMenuBar.ps1            # Menu bar (F10)
│   │   │   ├── PmcHeader.ps1             # Screen header
│   │   │   ├── PmcFooter.ps1             # Keyboard shortcuts footer
│   │   │   ├── PmcStatusBar.ps1          # Status messages
│   │   │   ├── ProjectPicker.ps1         # Project selector
│   │   │   ├── TagEditor.ps1             # Tag input
│   │   │   └── ... (more specialized widgets)
│   │   │
│   │   ├── services/            # Business logic services (8 files)
│   │   │   ├── TaskStore.ps1             # Observable data store (singleton)
│   │   │   ├── MenuRegistry.ps1          # Dynamic menu system
│   │   │   ├── CommandService.ps1        # Command execution
│   │   │   ├── ChecklistService.ps1      # Checklist operations
│   │   │   ├── NoteService.ps1           # Note operations
│   │   │   ├── ExcelMappingService.ps1   # Excel import mapping
│   │   │   ├── PreferencesService.ps1    # User preferences
│   │   │   └── ExcelComReader.ps1        # Excel COM interop
│   │   │
│   │   ├── helpers/             # Utility classes & functions (7 files)
│   │   │   ├── ConfigCache.ps1           # Config caching
│   │   │   ├── Constants.ps1             # Global constants
│   │   │   ├── DataBindingHelper.ps1     # Data binding utilities
│   │   │   ├── GapBuffer.ps1             # Text buffer (for editors)
│   │   │   ├── ValidationHelper.ps1      # Input validation
│   │   │   ├── ShortcutRegistry.ps1      # Keyboard shortcuts
│   │   │   └── TypeNormalization.ps1     # Type conversions
│   │   │
│   │   ├── theme/               # Theme system
│   │   │   └── PmcThemeManager.ps1       # Theme management
│   │   │
│   │   ├── layout/              # Layout system
│   │   │   └── PmcLayoutManager.ps1      # Layout calculations
│   │   │
│   │   ├── deps/                # ConsoleUI-specific dependencies
│   │   │   ├── PmcTemplate.ps1           # Template definitions
│   │   │   ├── HelpContent.ps1           # Help text
│   │   │   └── Project.ps1               # Project utilities
│   │   │
│   │   ├── config/              # Configuration files
│   │   │   └── ExcelImportMapping.json   # Excel column mappings
│   │   │
│   │   └── tests/               # Manual test scripts (9 files)
│   │       ├── TestTaskListScreen.ps1
│   │       ├── TestTextInput.ps1
│   │       ├── TestUniversalList.ps1
│   │       └── ... (demo & test screens)
│   │
│   ├── Pmc.Strict.psm1          # Module manifest & loader
│   ├── Pmc.Strict.psd1          # Module definition
│   └── ... (other module files)
│
├── lib/SpeedTUI/                # Vendored UI framework
│   ├── Core/
│   │   ├── Component.ps1        # Base widget class
│   │   ├── OptimizedRenderEngine.ps1  # Differential rendering
│   │   ├── EnhancedRenderEngine.ps1   # Extended rendering
│   │   ├── CellBuffer.ps1       # Cell-based buffer
│   │   ├── SimplifiedTerminal.ps1     # Terminal control
│   │   └── ... (logging, performance monitoring)
│   └── BorderHelper.ps1         # Box drawing helpers
│
└── config.json                  # Application configuration
```

---

## 2. INITIALIZATION FLOW & ENTRY POINTS

### Entry Point Chain

```
user runs:
  .\Start-PmcTUI.ps1 or . Start-PmcTUI; Start-PmcTUI
      ↓
  [1] Load PMC module (Pmc.Strict.psm1)
      └─ Loads 50+ src files with business logic
      ↓
  [2] Load dependencies (DepsLoader.ps1)
      └─ Type normalization, templates, help, Excel
      ↓
  [3] Load SpeedTUI framework (SpeedTUILoader.ps1)
      └─ Component class, RenderEngine, Logger, PerformanceMonitor
      ↓
  [4] Load PraxisVT (ANSI/VT100 helpers)
      ↓
  [5] Load helpers/services (ConfigCache, DataBindingHelper, etc.)
      ↓
  [6] Load widgets (PmcWidget base + 12+ concrete widgets)
      ↓
  [7] Load base classes (StandardListScreen, StandardFormScreen, etc.)
      ↓
  [8] Load ServiceContainer (DI container)
      ↓
  [9] Load PmcApplication (main app controller)
      ↓
  [10] Load TaskListScreen (initial screen)
      ↓
  Start-PmcTUI function:
      └─ Create ServiceContainer
      └─ Register all services in dependency order
      └─ Create PmcApplication
      └─ Push initial screen
      └─ Run event loop (PmcApplication.Run())
```

### Critical Initialization Points

**Start-PmcTUI.ps1** (Lines 251-449):
- Creates global ServiceContainer
- Registers services in correct dependency order
- Creates PmcApplication
- Launches initial screen
- Runs main event loop

**ServiceContainer Registration Order**:
1. Theme (no dependencies)
2. ThemeManager (depends on Theme)
3. Config (no dependencies) - CACHED for performance
4. TaskStore (depends on Theme)
5. MenuRegistry (depends on Theme)
6. Application (depends on Theme)
7. CommandService, ChecklistService, NoteService (no dependencies)
8. ExcelMappingService, PreferencesService (no dependencies)
9. Screen factories (depend on Application, TaskStore, etc.)

**Key Observation**: Services are registered in **dependency order** to prevent circular dependencies. Logging is **disabled by default** (performance optimization).

---

## 3. CORE ARCHITECTURAL PATTERNS

### 3.1 Hybrid Dependency Injection Pattern

PMC uses a **pragmatic hybrid** approach (see ARCHITECTURE_DECISIONS.md):

```
Three ways to access services:

1. SINGLETON PATTERN (for core services)
   $store = [TaskStore]::GetInstance()
   $theme = [PmcThemeManager]::GetInstance()
   └─ Ensures single instance, accessible from anywhere

2. DI CONTAINER (for screen/service creation)
   $container.Register('TaskStore', { ... }, $true)
   $screen = $container.Resolve('TaskListScreen')
   └─ Manages initialization order, handles dependencies

3. GLOBAL VARIABLES (for convenience)
   $global:PmcApp.PushScreen($screen)
   $global:PmcContainer.Resolve('Service')
   └─ Quick access from 100+ widgets without parameter passing
```

**Why This Design?**
- Single-user application (only one instance needed)
- 87+ classes don't need enterprise-grade pure DI
- Singletons ensure unique services
- Globals eliminate "constructor parameter explosion"
- Container manages initialization order

### 3.2 Screen Navigation & Stack-Based Model

```
PmcApplication manages screen stack:

  PushScreen(screen)
  ├─ Deactivate current screen
  ├─ Clear terminal
  ├─ Initialize new screen
  ├─ Apply layout
  └─ Activate screen (OnEnter)
      ↓ Event loop renders & gets input

  PopScreen()
  ├─ Exit current screen
  ├─ Restore previous screen
  └─ Re-enter previous screen
```

All screens inherit from **PmcScreen** base class which provides:
- Standard widgets (MenuBar, Header, Footer, StatusBar)
- Layout management
- Lifecycle methods (OnEnter, OnExit, LoadData)
- Render orchestration
- Input handling delegation

### 3.3 Event-Driven Observable Data Model

**TaskStore** (TaskStore.ps1) implements the Observable pattern:

```
TaskStore (Singleton)
├─ In-memory caching of tasks, projects, time logs
├─ CRUD operations (Add, Update, Delete, Get)
├─ Event callbacks:
│  ├─ OnTaskAdded
│  ├─ OnTaskUpdated
│  ├─ OnTaskDeleted
│  ├─ OnTasksChanged (fires after any task change)
│  ├─ OnProjectAdded/Updated/Deleted
│  ├─ OnTimeLogAdded/Updated/Deleted
│  └─ OnDataChanged (global event)
├─ Auto-persistence (calls Set-PmcAllData after modifications)
├─ Rollback on save failure
└─ Validation rules before persistence

When screen modifies data:
  1. Call store.AddTask/UpdateTask/DeleteTask
  2. Store fires event (e.g., OnTasksChanged)
  3. Subscribed screens refresh their UI automatically
  4. Store saves to disk via Set-PmcAllData
```

### 3.4 Three-Layer Rendering System

```
Layer 1: SPEEDTUI (Rendering Engine)
├─ OptimizedRenderEngine: Differential cell-based rendering
│  ├─ BeginFrame()     ─ Start frame
│  ├─ WriteAt(x,y,str)─ Write content at position
│  └─ EndFrame()       ─ Apply changes (only deltas)
└─ CellBuffer: 2D character/attribute buffer

Layer 2: PMC WIDGETS (Component layer)
├─ Extend SpeedTUI's Component class
├─ Render content to ANSI strings
├─ Handle widget-specific input
└─ Provide theme/layout integration

Layer 3: PMC SCREENS (Composition layer)
├─ Compose widgets (MenuBar, Header, Content, Footer, StatusBar)
├─ Orchestrate widget rendering
├─ Handle screen-level input & navigation
└─ Manage screen lifecycle
```

### 3.5 Input Handling Flow

```
PmcApplication.Run() event loop:
  [Loop iteration]
  ├─ While [Console]::KeyAvailable:
  │  ├─ Read key press
  │  ├─ Check global shortcuts (Ctrl+Q = exit)
  │  └─ Pass to CurrentScreen.HandleKeyPress(key)
  │     └─ Screen routes to widgets or handles directly
  │        └─ Widget handles input, returns true if handled
  │
  ├─ If input was processed, mark IsDirty=true
  ├─ Check terminal resize (only when idle)
  ├─ If IsDirty, call _RenderCurrentScreen()
  │  ├─ Request clear if needed
  │  ├─ BeginFrame on RenderEngine
  │  ├─ Call screen.RenderToEngine(engine) or screen.Render()
  │  └─ EndFrame (differential rendering)
  │
  └─ Sleep (16ms when rendering, 100ms when idle)
```

---

## 4. MAIN CLASSES & THEIR RELATIONSHIPS

### 4.1 Core Application Classes

```
PmcApplication (PmcApplication.ps1)
├─ Properties:
│  ├─ RenderEngine (OptimizedRenderEngine)
│  ├─ LayoutManager (PmcLayoutManager)
│  ├─ ThemeManager (PmcThemeManager)
│  ├─ Container (ServiceContainer for DI)
│  ├─ ScreenStack (Stack of screens)
│  ├─ CurrentScreen (active screen)
│  ├─ TermWidth/TermHeight (terminal dimensions)
│  └─ IsDirty (render flag)
│
├─ Methods:
│  ├─ PushScreen(screen)     ─ Navigate to screen
│  ├─ PopScreen()            ─ Return to previous
│  ├─ SetRootScreen(screen)  ─ Replace entire stack
│  ├─ Run()                  ─ Main event loop (handles input/render)
│  ├─ Stop()                 ─ Exit application
│  └─ RequestRender()        ─ Schedule redraw

└─ Initialization:
   ├─ Create OptimizedRenderEngine
   ├─ Create PmcLayoutManager
   ├─ Resolve ThemeManager from container
   ├─ Initialize screen stack
   └─ Get terminal size
```

### 4.2 Base Screen Classes

```
PmcScreen (PmcScreen.ps1) - Base for ALL screens
├─ Properties:
│  ├─ ScreenKey (identifier)
│  ├─ ScreenTitle (display name)
│  ├─ Container (ServiceContainer)
│  ├─ MenuBar, Header, Footer, StatusBar (standard widgets)
│  ├─ ContentWidgets (list of screen-specific widgets)
│  ├─ IsActive (current state)
│  ├─ RenderEngine (reference to engine)
│  └─ NeedsClear (full screen clear flag)
│
├─ Lifecycle Methods:
│  ├─ OnEnter()      ─ Called when screen becomes active
│  ├─ OnExit()       ─ Called when screen deactivates
│  ├─ LoadData()     ─ Override to load screen data
│  ├─ Initialize()   ─ Called by app before first render
│  └─ ApplyLayout()  ─ Called to layout widgets
│
├─ Rendering:
│  ├─ RenderToEngine(engine)  ─ New pattern: write to engine
│  └─ Render()                ─ Legacy pattern: return ANSI string
│
└─ Input:
   └─ HandleKeyPress(key)     ─ Process keyboard input


StandardListScreen (base/StandardListScreen.ps1) - For list-based screens
├─ Extends: PmcScreen
├─ Provides:
│  ├─ UniversalList widget (columns, sorting, filtering)
│  ├─ FilterPanel widget (dynamic filters)
│  ├─ InlineEditor widget (add/edit forms)
│  └─ TaskStore integration (auto-CRUD)
│
├─ Abstract Methods (override in subclasses):
│  ├─ LoadData()              ─ Load list data
│  ├─ GetColumns()            ─ Define columns
│  └─ GetEditFields(item)     ─ Define edit form
│
├─ Concrete Methods:
│  ├─ RefreshList()           ─ Reload data
│  ├─ HandleItemActivated()   ─ Item selection
│  └─ HandleAction()          ─ Add/Edit/Delete/Custom
│
└─ Examples: TaskListScreen, ProjectListScreen, TimeListScreen


StandardFormScreen (base/StandardFormScreen.ps1) - For form-based screens
├─ Extends: PmcScreen
├─ Provides:
│  ├─ InlineEditor widget (multi-field form)
│  ├─ TaskStore integration (save on submit)
│  └─ Validation framework
│
├─ Abstract Methods:
│  ├─ GetFields()             ─ Define form fields
│  └─ OnSubmit(values)        ─ Handle form submission
│
└─ Examples: TaskFormScreen, ProjectFormScreen, SettingsScreen


StandardDashboard (base/StandardDashboard.ps1) - For dashboard/overview screens
├─ Extends: PmcScreen
├─ Provides:
│  ├─ Grid-based layout
│  ├─ Multiple content panels
│  └─ Summary statistics
│
└─ Examples: MainDashboard, ProjectStatsScreen, TimeReportScreen
```

### 4.3 Widget Classes (UI Components)

```
PmcWidget (widgets/PmcWidget.ps1) - Base for all PMC widgets
├─ Extends: SpeedTUI Component
├─ Properties:
│  ├─ Name (widget identifier)
│  ├─ LayoutConstraints (named regions)
│  ├─ Theme integration
│  └─ Box drawing characters
│
└─ Methods:
   ├─ OnRender()         ─ Render widget content
   └─ HandleInput(key)   ─ Process input


UniversalList (widgets/UniversalList.ps1)
├─ Extends: PmcWidget
├─ Features:
│  ├─ Column-based display
│  ├─ Row selection
│  ├─ Sorting (click column header)
│  ├─ Filtering (dynamic filter panel)
│  ├─ Virtual scrolling
│  ├─ Search functionality
│  └─ Multi-select mode
│
└─ Used by: TaskListScreen, ProjectListScreen, TimeListScreen, etc.


InlineEditor (widgets/InlineEditor.ps1)
├─ Extends: PmcWidget
├─ Features:
│  ├─ Multi-field form editing
│  ├─ Validation before submission
│  ├─ Field types (text, date, number, select, checkbox)
│  ├─ Tab/Shift+Tab navigation
│  ├─ Enter to submit, Esc to cancel
│  └─ Dynamic field visibility
│
└─ Used by: All form-based screens


TextInput (widgets/TextInput.ps1)
├─ Extends: PmcWidget
├─ Features:
│  ├─ Single-line text input
│  ├─ Cursor navigation (arrows, Home/End)
│  ├─ Insert/delete/backspace
│  ├─ Copy/paste
│  ├─ Validation
│  └─ History (undo/redo)
│
└─ Composed by: InlineEditor for text fields


DatePicker (widgets/DatePicker.ps1)
├─ Extends: PmcWidget
├─ Features:
│  ├─ Calendar widget
│  ├─ Month/year navigation
│  ├─ Date selection
│  └─ Quick jump (today, next week, etc.)


FilterPanel (widgets/FilterPanel.ps1)
├─ Extends: PmcWidget
├─ Features:
│  ├─ Dynamic filter builder
│  ├─ Field selectors
│  ├─ Operator selection (=, <, >, contains)
│  ├─ Value input
│  ├─ Add/remove filters
│  └─ Apply/reset


PmcMenuBar (widgets/PmcMenuBar.ps1)
├─ Extends: PmcWidget
├─ Features:
│  ├─ Top menu bar (F10 to activate)
│  ├─ Menu categories (Tasks, Projects, Time, Tools, Options, Help)
│  ├─ Menu navigation (arrow keys)
│  ├─ Hotkey shortcuts
│  └─ Dynamic menu registration (MenuRegistry)


PmcHeader, PmcFooter, PmcStatusBar (widgets/)
├─ Extend: PmcWidget
├─ Usage:
│  ├─ Header: Screen title, breadcrumb
│  ├─ Footer: Keyboard shortcuts legend
│  └─ StatusBar: Current status messages


ProjectPicker, TagEditor (widgets/)
├─ Extend: PmcWidget
├─ Features:
│  ├─ ProjectPicker: Select project from list
│  └─ TagEditor: Multi-tag input with completion
```

### 4.4 Service Classes

```
TaskStore (services/TaskStore.ps1)
├─ Pattern: Singleton
├─ Features:
│  ├─ In-memory cache (tasks, projects, timelogs)
│  ├─ CRUD operations
│  ├─ Event callbacks (OnTaskAdded, OnTaskUpdated, etc.)
│  ├─ Auto-persistence to disk
│  ├─ Rollback on failure
│  ├─ Validation rules
│  └─ Thread-safe with locks
│
└─ Public Methods:
   ├─ GetInstance()              ─ Get singleton
   ├─ LoadData()                 ─ Load from disk
   ├─ GetTask(id), GetAllTasks() ─ Query
   ├─ AddTask, UpdateTask, DeleteTask ─ CRUD
   ├─ QueryTasks(filter)         ─ Advanced queries
   └─ Flush(), HasPendingChanges ─ Persistence


MenuRegistry (services/MenuRegistry.ps1)
├─ Pattern: Singleton
├─ Features:
│  ├─ Dynamic menu item registration
│  ├─ Menu categories (Tasks, Projects, Time, Tools, Options, Help)
│  ├─ Item ordering
│  └─ Lazy menu loading (screens register their items)
│
└─ Methods:
   ├─ GetInstance()                    ─ Get singleton
   ├─ AddMenuItem(menu, label, hotkey) ─ Register item
   └─ GetMenuItems(menu)               ─ Retrieve menu items


ChecklistService, NoteService, CommandService
├─ Pattern: Singleton
├─ Purpose:
│  ├─ ChecklistService: Task checklists
│  ├─ NoteService: Task notes
│  └─ CommandService: Command execution
│
└─ Access: [ChecklistService]::GetInstance(), etc.


ExcelMappingService, PreferencesService
├─ Pattern: Singleton
├─ Purpose:
│  ├─ ExcelMappingService: Import mappings
│  └─ PreferencesService: User preferences


ExcelComReader
├─ Pattern: Utility class
├─ Purpose: Read Excel files via COM interface
```

### 4.5 Helper Classes

```
ConfigCache (helpers/ConfigCache.ps1)
├─ Pattern: Cache wrapper
├─ Purpose: Cache config.json to avoid repeated file I/O
│  └─ 30% performance improvement


ServiceContainer (ServiceContainer.ps1)
├─ Pattern: Dependency Injection Container
├─ Features:
│  ├─ Service registration with factories
│  ├─ Singleton vs instance lifetime
│  ├─ Circular dependency detection
│  ├─ Logging of resolution chain
│  └─ Type safety
│
└─ Methods:
   ├─ Register(name, factory, singleton)
   └─ Resolve(name)


ValidationHelper, DataBindingHelper
├─ Purpose: Utility functions for validation and binding


GapBuffer (helpers/GapBuffer.ps1)
├─ Purpose: Efficient text editing buffer
├─ Used by: TextInput widget


PmcLayoutManager (layout/PmcLayoutManager.ps1)
├─ Purpose: Calculate widget positions and sizes
├─ Features:
│  ├─ Named regions (MenuBar, Header, Content, Footer)
│  ├─ Percentage-based sizing
│  ├─ Auto-spacing
│  └─ Terminal resize handling


PmcThemeManager (theme/PmcThemeManager.ps1)
├─ Pattern: Singleton
├─ Purpose: Manage theme colors and styles
├─ Features:
│  ├─ Load/save theme configurations
│  ├─ Derive color palettes from single hex color
│  ├─ Apply themes to widgets
│  └─ Theme caching
```

---

## 5. UI/RENDERING SYSTEM STRUCTURE

### 5.1 SpeedTUI Framework Integration

PMC is built **on top of** the SpeedTUI framework:

```
                    User input (keyboard)
                           ↓
                    PmcApplication.Run()
                    (event loop)
                           ↓
                    CurrentScreen.HandleKeyPress(key)
                           ↓
                    [Render cycle if state changed]
                           ↓
                    OptimizedRenderEngine
                    ├─ BeginFrame()      (clear cell buffer)
                    ├─ WriteAt(x,y,str)  (write ANSI content)
                    └─ EndFrame()        (apply differential rendering)
                           ↓
                    Terminal output (ANSI/VT100 codes)
                           ↓
                    User sees rendered screen
```

### 5.2 Rendering Flow

```
_RenderCurrentScreen():
  ├─ Check if screen requests full clear (NeedsClear flag)
  │  └─ RenderEngine.RequestClear()
  │
  ├─ RenderEngine.BeginFrame()  ─ Start new frame
  │
  ├─ Call screen rendering:
  │  ├─ IF screen has RenderToEngine():
  │  │  └─ screen.RenderToEngine(engine)  ─ Direct engine access
  │  └─ ELSE (legacy):
  │     ├─ ansiOutput = screen.Render()
  │     └─ _WriteAnsiToEngine(ansiOutput)  ─ Parse and write
  │
  ├─ RenderEngine.EndFrame()   ─ Apply differential rendering
  │  └─ Write only changed cells to terminal
  │
  └─ Clear IsDirty flag
```

### 5.3 ANSI/VT100 Escape Sequences

PMC uses standard ANSI escape codes:

```
Cursor movement:   ESC[row;colH     (1-based coordinates)
Colors:            ESC[38;5;Nm      (256-color)
Attributes:        ESC[1m           (bold), ESC[4m (underline)
Clear:             ESC[2J           (full), ESC[2K (line)
Hide cursor:       ESC[?25l
Show cursor:       ESC[?25h
Reset:             ESC[0m

Example:
  `e[1;1H`e[31mHello`e[0m  ─ Red "Hello" at (1,1)
  `e[38;5;200mMagenta Text`e[0m
```

### 5.4 Cell-Based Rendering

OptimizedRenderEngine uses a **cell buffer** for efficiency:

```
Cell Buffer (2D array):
  [0,0] [0,1] [0,2] ...
  [1,0] [1,1] [1,2] ...
  ...

Each cell contains:
  ├─ Character
  ├─ Foreground color
  └─ Background color

Differential rendering:
  ├─ Only write cells that changed
  └─ Skip unchanged cells (massive speedup)
```

---

## 6. INPUT HANDLING & KEYBOARD MANAGEMENT

### 6.1 Global Shortcuts

```
Ctrl+Q  ─ Exit application
F10     ─ Open menu
Esc     ─ Back/Cancel (usually)
```

### 6.2 Screen-Level Input

```
screen.HandleKeyPress(key)
├─ Returns true if handled, false otherwise
├─ Screen can:
│  ├─ Pass to MenuBar (F10)
│  ├─ Pass to content widgets
│  ├─ Handle directly (arrows, Esc, etc.)
│  └─ Navigate to new screen
│
└─ Common patterns:
   ├─ List screens: arrows for selection, Enter to select
   ├─ Form screens: Tab for field navigation, Enter to submit
   └─ Detail screens: PgUp/PgDn for scrolling
```

### 6.3 Widget-Level Input

```
widget.HandleInput(key)
├─ TextInput:  Character input, cursor navigation
├─ UniversalList: Row selection (arrows), column sorting
├─ DatePicker: Month/year navigation, date selection
├─ InlineEditor: Field navigation (Tab), field input
└─ FilterPanel: Add/remove filters, value input
```

### 6.4 Keyboard Shortcuts Registry

**ShortcutRegistry.ps1** manages dynamic shortcuts:

```
$registry.RegisterShortcut('TaskList', 'A', 'Add task', { ... })
$registry.RegisterShortcut('TaskList', 'E', 'Edit selected', { ... })
$registry.RegisterShortcut('TaskList', 'D', 'Delete selected', { ... })
```

---

## 7. CONFIGURATION & STATE MANAGEMENT

### 7.1 Configuration Hierarchy

```
Configuration sources (in priority order):
  1. Runtime overrides (set-pmc-config)
  2. config.json (project root)
     └─ Cached via ConfigCache for performance
  3. Defaults (hardcoded in code)

Example config.json:
  {
    "theme": { "primary": "0055FF", ... },
    "taskStore": { "autoSave": true, ... },
    "excel": { "sheetName": "Tasks", ... }
  }
```

### 7.2 State Management

PMC uses **Get-PmcState / Set-PmcState** (centralized):

```
State sections:
  ├─ Display
  │  ├─ Theme colors
  │  ├─ Terminal dimensions
  │  └─ UI state (selected item, scroll position)
  │
  ├─ TaskStore
  │  ├─ Tasks, projects, time logs (in-memory cache)
  │  └─ Pending changes flag
  │
  ├─ Session
  │  ├─ Current screen
  │  ├─ Navigation history
  │  └─ User preferences
  │
  └─ Debug
     └─ Log file path, log level
```

### 7.3 Data Persistence

```
Get-PmcAllData()  ─ Load from tasks.json/projects.json/etc.
                     ↓
                 In-memory TaskStore cache
                     ↓
Set-PmcAllData()  ─ Save to disk (called auto-save)

Critical: TaskStore.HasPendingChanges flag tracks modifications
On exit:  PmcApplication.Run() finally block flushes pending data
```

---

## 8. DEPENDENCY INJECTION & SERVICE LOCATOR

### 8.1 ServiceContainer

Located in `ServiceContainer.ps1` (158 lines):

```powershell
class ServiceContainer {
    hidden [hashtable]$_factories       # Service -> factory scriptblock
    hidden [hashtable]$_singletons      # Service -> cached instance
    hidden [hashtable]$_isSingleton     # Service -> bool
    hidden [List[string]]$_resolutionStack  # For circular dependency detection

    [void] Register([string]$name, [scriptblock]$factory, [bool]$singleton)
    [object] Resolve([string]$name)
}
```

### 8.2 Service Dependency Graph

```
Graph of dependencies (from Start-PmcTUI.ps1):

  Theme ──────┐
             ├─→ ThemeManager
             │
             ├─→ TaskStore
             │
             ├─→ MenuRegistry
             │
             └─→ Application

  Config (cached)

  CommandService, ChecklistService, NoteService (no deps)

  ExcelMappingService, PreferencesService (no deps)

  Screen factories (depend on Application, TaskStore, Theme)
```

### 8.3 Factory Pattern for Lazy Loading

```powershell
# Services are registered with factories (scriptblocks)
$container.Register('TaskListScreen', {
    param($container)
    $null = $container.Resolve('Theme')
    $null = $container.Resolve('TaskStore')
    return [TaskListScreen]::new($container)
}, $false)  # Not singleton - create new instance each time

# When screen is needed:
$screen = $container.Resolve('TaskListScreen')
# Factory is invoked, dependencies resolved in order
```

---

## 9. MODULE ORGANIZATION & BOUNDARIES

### 9.1 Layer Breakdown

```
[Presentation Layer - 40 screens]
  TaskListScreen, ProjectListScreen, KanbanScreen, etc.
  ├─ Compose widgets from widget layer
  ├─ Inherit from base classes (StandardListScreen, etc.)
  └─ Use services from service layer

[Widget Layer - 12+ widgets]
  UniversalList, InlineEditor, TextInput, DatePicker, FilterPanel, etc.
  ├─ Extend PmcWidget (extends SpeedTUI Component)
  ├─ Render ANSI output
  ├─ Handle widget-specific input
  └─ Can access services via globals

[Service Layer - 8 services]
  TaskStore, MenuRegistry, ChecklistService, etc.
  ├─ Provide business logic
  ├─ Manage observable state
  ├─ Implement singletons
  └─ Persist to disk

[Infrastructure Layer]
  PmcApplication: Main event loop & screen stack
  PmcScreen: Base screen class
  ServiceContainer: DI container
  PmcThemeManager: Theme management
  PmcLayoutManager: Layout calculations

[Framework Layer - SpeedTUI]
  OptimizedRenderEngine: Differential rendering
  Component: Base widget class
  CellBuffer: 2D cell array
  Logger: Logging utility
```

### 9.2 Module Boundaries

```
PMC (Pmc.Strict module):
  └─ src/ - Core business logic
     ├─ Tasks, Projects, Storage, State, Config
     ├─ Interactive REPL
     ├─ Theme, Help, UI utilities
     └─ Used by both ConsoleUI and other commands

ConsoleUI (consoleui/ subdirectory):
  ├─ Completely separate from older INTERACTIVE mode
  ├─ New modular TUI architecture
  ├─ Screens, widgets, services
  └─ Isolated in consoleui/ to prevent interference
```

### 9.3 Encapsulation & Hidden Fields

PMC uses **hidden fields** extensively (147 hidden fields):

```powershell
class Example {
    # Public API - callers use this
    [string]$ScreenTitle = ""

    # Internal implementation - hidden from callers
    hidden [hashtable]$_internalCache = @{}
    hidden [object]$_dataLock = [object]::new()

    # Why? 
    # 1. Prevents accidental misuse
    # 2. Allows refactoring internal state
    # 3. Clear separation between API and implementation
    # 4. But harder to inspect in debugger
}
```

---

## 10. TEST COVERAGE & QUALITY ASSURANCE

### 10.1 Current Approach

- **Manual testing** via test scripts (9 test files)
  - TestTextInput.ps1
  - TestUniversalList.ps1
  - TestFilterPanel.ps1
  - etc.

- **No automated test framework** (no Pester integration)
  - 48,341 lines of code
  - Only 31 manual test assertions
  - Rapid iteration prioritized over test coverage

### 10.2 Testing Strategy

**Current**:
1. Widget tests (isolated, easiest to test)
2. Integration tests (manual TUI usage)
3. Smoke tests (application starts)

**Future**:
1. Add Pester unit tests for widgets
2. Add TaskStore tests (business logic)
3. Add screen integration tests

### 10.3 Known Fragile Areas

(From REGRESSION_CHECKLIST.md):
- Menu cursor movement
- Form input validation
- Data persistence on exit
- List sorting and filtering
- Theme color application
- Terminal resize handling
- Closure variable capture (.GetNewClosure())

---

## 11. DESIGN PATTERNS USED

### 11.1 Creational Patterns

**Singleton Pattern**:
- TaskStore, ThemeManager, MenuRegistry
- `[ClassName]::GetInstance()` returns single instance

**Factory Pattern**:
- ServiceContainer registers factories for services
- Lazy evaluation of dependencies

**Builder Pattern**:
- InlineEditor builds forms from field definitions
- UniversalList builds from column definitions

### 11.2 Structural Patterns

**Adapter Pattern**:
- PmcWidget adapts SpeedTUI Component for PMC use
- Adds theme integration, layout constraints

**Composite Pattern**:
- PmcScreen composes widgets (MenuBar, Header, Footer, etc.)
- Widgets can contain other widgets

**Decorator Pattern**:
- PmcLayoutManager decorates widget positioning
- PmcThemeManager decorates widget styling

### 11.3 Behavioral Patterns

**Observer Pattern**:
- TaskStore fires events (OnTaskAdded, OnTaskUpdated, etc.)
- Screens subscribe to store changes

**Template Method Pattern**:
- PmcScreen defines lifecycle (OnEnter, LoadData, Render, OnExit)
- Subclasses override specific methods

**State Pattern**:
- Screens have lifecycle states (inactive, active, loading, etc.)
- Behavior changes based on state

**Strategy Pattern**:
- Multiple rendering strategies (RenderToEngine vs Render)
- Multiple input handling strategies per screen type

---

## 12. PERFORMANCE OPTIMIZATIONS

### 12.1 Rendering Optimizations

**OptimizedRenderEngine**:
- Differential rendering (only write changed cells)
- Cell buffer for 2D character positioning
- Impact: Reduced terminal I/O by 70-80%

**Lazy Screen Loading**:
- Only TaskListScreen pre-loaded
- Other screens loaded on-demand via MenuRegistry
- Impact: Faster startup time

### 12.2 CPU Optimizations

**Disabled Logging by Default**:
- Was consuming 30-40% CPU even when idle
- Now opt-in via `-DebugLog -LogLevel 3`
- Impact: 30-40% CPU reduction

**Config Caching**:
- ConfigCache eliminates repeated file I/O
- Caches config.json in memory
- Impact: 30% faster config access

**Input Draining**:
- Event loop drains ALL available input before rendering
- Prevents input lag from sleep delays
- Impact: 2-3x input responsiveness improvement

**Terminal Polling Optimization**:
- Only check for terminal resize when idle
- Skip resize checks during active rendering
- Impact: Minor CPU reduction

**Event Loop Sleep Timing**:
- 16ms sleep when rendering (60 FPS)
- 100ms sleep when idle (10 FPS)
- Balanced: Responsiveness vs battery life

### 12.3 Memory Optimizations

**String Caching**:
- Reuse common ANSI sequences
- Cache theme colors
- Cache box drawing characters

**Object Pooling**:
- StringBuilders pooled/reused
- Reduced garbage collection

---

## 13. KNOWN LIMITATIONS & FUTURE WORK

### 13.1 Limitations

1. **Single-user focused** - No multi-instance, no thread safety
2. **Global variables** - Not enterprise-grade pure DI
3. **Dual constructors** - PowerShell class limitation
4. **No automated tests** - Manual testing only
5. **Limited async** - Single-threaded event loop
6. **PowerShell 5.1 class bugs** - Occasional issues with complex inheritance
7. **Terminal size limit** - Assumes 80+ width, 24+ height
8. **No font control** - Terminal font/size set by user

### 13.2 Future Improvements

1. **Pester test suite** - Add automated testing
2. **Plugin system** - Allow user-created screens
3. **Async operations** - Background refresh, file watchers
4. **Better error recovery** - Graceful degradation
5. **Performance monitoring** - Real-time CPU/memory stats
6. **Accessibility** - Screen reader support
7. **Mouse support** - Click selection, drag operations
8. **Customizable keybindings** - User-defined shortcuts

---

## 14. CRITICAL SUCCESS FACTORS

### 14.1 What Works Well

1. ✅ **Clear screen hierarchy** (PmcScreen → StandardListScreen → TaskListScreen)
2. ✅ **Observable data model** (TaskStore events)
3. ✅ **Theme system integration** (single hex → full palette)
4. ✅ **Performance-optimized rendering** (differential, lazy load)
5. ✅ **Pragmatic DI approach** (hybrid model for single-user)
6. ✅ **Modular screens** (40 independent screen classes)
7. ✅ **Reusable widgets** (UniversalList, InlineEditor)
8. ✅ **Responsive input handling** (non-blocking key loop)

### 14.2 What Needs Attention

1. ⚠️ **No automated tests** - Manual testing only
2. ⚠️ **Hidden fields debugging** - Hard to inspect state
3. ⚠️ **Dual constructors** - Maintenance burden
4. ⚠️ **Global variables** - Not pure DI
5. ⚠️ **Documentation gaps** - Some patterns undocumented
6. ⚠️ **Error handling inconsistency** - Mix of fail-fast and silent failures
7. ⚠️ **Logging disabled by default** - Makes troubleshooting harder

---

## 15. ARCHITECTURE DECISIONS

Key decisions documented in **ARCHITECTURE_DECISIONS.md**:

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| Hybrid DI + Globals | Single-user tool, simpler code | Not enterprise-grade |
| PowerShell classes | Inheritance critical, type safety | Dual constructors required |
| Minimal thread safety | No async operations planned | Would break with async |
| Logging disabled by default | 30-40% CPU reduction | No logs unless explicit |
| Dual constructors | PowerShell limitation workaround | Code duplication |
| Three service patterns | Each serves a purpose | Complex for newcomers |
| Hidden fields | Proper encapsulation | Harder debugging |
| Manual testing | Fast iteration | No regression detection |
| Fail-fast on critical | Prevents silent corruption | May exit more often |
| Performance over purity | Optimized for use case | Not "textbook" architecture |

---

## 16. SUMMARY & RECOMMENDATIONS

### 16.1 Architecture Quality

**Strengths**:
- Clean layer separation (presentation, widgets, services, infrastructure)
- Well-designed base classes (PmcScreen, StandardListScreen)
- Strong event-driven data model (TaskStore)
- Good performance optimizations in place
- Pragmatic design for actual use case

**Weaknesses**:
- No automated tests (single largest gap)
- Global variables (pragmatic but not pure)
- Limited documentation (CLAUDE.md and ARCHITECTURE_DECISIONS.md help)
- Debugging hidden fields is difficult

### 16.2 For New Developers

1. Read ARCHITECTURE_DECISIONS.md first (understand philosophy)
2. Study PmcScreen base class (foundation for all screens)
3. Look at TaskListScreen example (complete screen implementation)
4. Review StandardListScreen (pattern for list-based screens)
5. Examine UniversalList widget (reusable UI component)
6. Understand TaskStore (observable data model)
7. Run manual tests to see components in action

### 16.3 For Future Development

**High Priority**:
- Add Pester test suite (biggest gap)
- Document public APIs clearly
- Standardize error handling

**Medium Priority**:
- Consider pure DI if shipping as library
- Add more logging/debugging aids
- Improve error messages

**Low Priority**:
- Refactor hidden fields only if needed
- Replace dual constructors only if feasible
- Add async support only if needed

---

## Appendix: File Size Reference

```
Core Infrastructure:
  Start-PmcTUI.ps1        456 lines (bootstrap)
  PmcApplication.ps1      547 lines (event loop)
  PmcScreen.ps1          ~400 lines (base screen)
  ServiceContainer.ps1    158 lines (DI container)

Largest Screens:
  TaskListScreen.ps1     1179 lines (main screen)
  ProjectListScreen.ps1   609 lines
  BlockedTasksScreen.ps1  569 lines
  TaskDetailScreen.ps1    546 lines

Key Services:
  TaskStore.ps1          ~600 lines (observable data)
  MenuRegistry.ps1       ~200 lines (menu system)

Widgets:
  UniversalList.ps1      ~400 lines
  InlineEditor.ps1       ~350 lines
  TextInput.ps1          ~250 lines

Total ConsoleUI: ~68,000 lines
Total PMC Module: ~48,000 lines
Grand Total: ~116,000 lines
```

---

**Document Version**: 1.0
**Generated**: 2025-11-13
**Analysis Scope**: Complete PMC TUI codebase
**Coverage**: Directory structure, entry points, classes, patterns, services, rendering, input, config, DI, modules, testing, performance, limitations, success factors
