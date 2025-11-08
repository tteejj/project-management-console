# PMC TUI Base Architecture

**Version:** 1.0
**Last Updated:** 2025-11-07
**Status:** Complete

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Component Relationships](#component-relationships)
4. [Core Components](#core-components)
5. [Developer Guide](#developer-guide)
6. [API Reference](#api-reference)
7. [Examples](#examples)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Overview

The PMC TUI Base Architecture provides a complete foundation for building terminal-based user interfaces with PowerShell. It combines:

- **SpeedTUI Framework** - Low-level rendering engine with VT100 support
- **Observable Data Layer** - TaskStore for centralized state management
- **Base Screen Classes** - Reusable screen templates (List, Form, Dashboard)
- **Navigation System** - Screen transitions with history and state preservation
- **Keyboard Management** - Global and screen-specific shortcuts
- **Validation System** - Schema-based validation for PMC entities
- **Widget System** - Reusable UI components

### Key Features

- **Event-Driven Architecture**: Components communicate via events and callbacks
- **Separation of Concerns**: Data, UI, and navigation are cleanly separated
- **Reusable Components**: Base classes eliminate boilerplate code
- **Type Safety**: PowerShell classes with strong typing
- **State Preservation**: Navigation history with state snapshots
- **Extensibility**: Easy to add new screens, validators, and shortcuts

### Technology Stack

- **PowerShell 7+** (PowerShell Core)
- **SpeedTUI Framework** (VT100 terminal rendering)
- **PMC Module** (Task management backend)
- **.NET System.Collections.Generic** (Efficient data structures)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PmcApplication                              │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  ApplicationBootstrapper                                       │ │
│  │  - Loads all dependencies in correct order                     │ │
│  │  - Initializes services and managers                           │ │
│  │  - Registers screens and shortcuts                             │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Infrastructure Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │ScreenRegistry│  │NavigationMgr │  │   KeyboardManager       │  │
│  │- Register    │  │- History     │  │   - Global shortcuts    │  │
│  │- Create      │  │- Navigate    │  │   - Screen shortcuts    │  │
│  │- Query       │  │- GoBack      │  │   - Handle keys         │  │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Data Layer                                   │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  TaskStore (Singleton)                                         │ │
│  │  - Load/Save via Get-PmcAllData / Set-PmcAllData             │ │
│  │  - In-memory caching (tasks, projects, timelogs)             │ │
│  │  - CRUD operations (Add, Update, Delete, Get)                │ │
│  │  - Event-driven updates (OnTaskAdded, OnTaskUpdated, etc.)   │ │
│  │  - Rollback on save failure                                   │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Presentation Layer                            │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐  │
│  │StandardListScreen│  │StandardFormScreen│  │StandardDashboard│  │
│  │- Item rendering  │  │- Field editing   │  │- Panel layout   │  │
│  │- Selection       │  │- Validation      │  │- Metrics        │  │
│  │- Filtering       │  │- Save/Cancel     │  │- Widgets        │  │
│  │- Keyboard nav    │  │- Keyboard nav    │  │- Auto-refresh   │  │
│  └──────────────────┘  └──────────────────┘  └─────────────────┘  │
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Widget System (PmcWidget, PmcPanel, PmcHeader, etc.)        │ │
│  │  - Reusable UI components with layout and rendering          │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        Helper Layer                                 │
│  ┌────────────────────┐  ┌──────────────────────────────────────┐  │
│  │ValidationHelper    │  │  DataBindingHelper                   │  │
│  │- Test-TaskValid    │  │  - Bind-DataToList                   │  │
│  │- Test-ProjectValid │  │  - Update-ListFromStore              │  │
│  │- Schema validation │  │  - Sync-ScreenState                  │  │
│  └────────────────────┘  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Component Relationships

### Data Flow

```
User Input → KeyboardManager → Screen → TaskStore → PMC Backend
                                  ↓           ↓
                            RenderEngine ← Events
```

1. **User Input**: Keyboard events captured by PmcApplication
2. **KeyboardManager**: Routes keys to global or screen-specific handlers
3. **Screen**: Handles input, updates TaskStore
4. **TaskStore**: Persists changes, fires events
5. **Events**: Screens subscribe to TaskStore events
6. **RenderEngine**: Screens request re-render on data changes

### Event Flow

```
TaskStore Events:
  - OnTaskAdded(task)
  - OnTaskUpdated(task)
  - OnTaskDeleted(id)
  - OnTasksChanged(tasks)
  ↓
Subscribed Screens:
  - Receive event
  - Update local state
  - Request re-render
```

### Navigation Flow

```
User Action → NavigationManager.NavigateTo('ScreenName')
                      ↓
              1. Save current screen state
              2. Push to history stack
              3. ScreenRegistry.Create('ScreenName')
              4. PmcApplication.SetScreen(newScreen)
              5. Fire OnNavigated event
```

---

## Core Components

### 1. TaskStore (services/TaskStore.ps1)

**Purpose**: Centralized observable data store for PMC data.

**Responsibilities**:
- Load data from PMC backend (`Get-PmcAllData`)
- Maintain in-memory cache of tasks, projects, time logs
- Provide CRUD operations with automatic persistence
- Fire events on data changes for reactive UI updates
- Handle rollback on save failures

**Key Methods**:
- `GetInstance()` - Singleton accessor
- `LoadData()` - Load from backend
- `SaveData()` - Persist to backend
- `AddTask($task)` - Add task with validation
- `UpdateTask($id, $changes)` - Update task
- `DeleteTask($id)` - Delete task
- `GetAllTasks()` - Query tasks
- Similar methods for projects and time logs

**Events**:
- `OnTaskAdded` - Fired after task added
- `OnTaskUpdated` - Fired after task updated
- `OnTaskDeleted` - Fired after task deleted
- `OnTasksChanged` - Fired after any task change
- Similar events for projects and time logs

**Example**:
```powershell
$store = [TaskStore]::GetInstance()

# Subscribe to changes
$store.OnTaskAdded = {
    param($task)
    Write-Host "New task: $($task.text)"
    $this.RefreshUI()
}

# Add task
$store.AddTask(@{
    text = 'Buy milk'
    project = 'personal'
    priority = 3
})
```

### 2. ValidationHelper (helpers/ValidationHelper.ps1)

**Purpose**: Centralized validation for PMC entities.

**Responsibilities**:
- Validate tasks (required fields, types, ranges)
- Validate projects (uniqueness, required fields)
- Validate time logs (task existence, positive duration)
- Schema-based validation for custom entities
- Return detailed error messages

**Key Functions**:
- `Test-TaskValid($task)` - Validate task
- `Test-ProjectValid($project, $existingProjects)` - Validate project
- `Test-TimeLogValid($timelog, $taskExists)` - Validate time log
- `Get-ValidationErrors($data, $schema)` - Generic schema validation
- `Test-FieldValid($fieldName, $value, $schema)` - Single field validation

**Example**:
```powershell
$result = Test-TaskValid @{
    text = 'Complete project'
    priority = 3
    due = (Get-Date).AddDays(7)
}

if (-not $result.IsValid) {
    Write-Host "Validation errors:"
    foreach ($error in $result.Errors) {
        Write-Host "  - $error"
    }
}
```

### 3. ScreenRegistry (infrastructure/ScreenRegistry.ps1)

**Purpose**: Central registry for screen types and navigation.

**Responsibilities**:
- Register screen classes by name
- Create screen instances on demand
- Organize screens by category (Tasks, Projects, Reports, Settings)
- Validate registrations
- Provide discovery methods

**Key Methods**:
- `Register($name, $type, $category, $description)` - Register screen
- `Create($name, $args)` - Create screen instance
- `GetAllScreens()` - List all registered screens
- `GetByCategory($category)` - Filter by category
- `IsRegistered($name)` - Check registration

**Example**:
```powershell
# Register screens
[ScreenRegistry]::Register('TaskList', [TaskListScreen], 'Tasks', 'View tasks')
[ScreenRegistry]::Register('AddTask', [AddTaskScreen], 'Tasks', 'Add task')

# Create screen
$screen = [ScreenRegistry]::Create('TaskList')

# Query
$taskScreens = [ScreenRegistry]::GetByCategory('Tasks')
```

### 4. NavigationManager (infrastructure/NavigationManager.ps1)

**Purpose**: Manage screen transitions and history.

**Responsibilities**:
- Navigate between screens
- Maintain navigation history stack
- Support back navigation
- Preserve and restore screen state
- Fire navigation events

**Key Methods**:
- `NavigateTo($screenName, $state)` - Navigate forward
- `GoBack()` - Navigate back in history
- `Replace($screenName, $state)` - Replace without history
- `ClearHistory()` - Clear navigation stack
- `GetHistory()` - View history

**Events**:
- `OnNavigating($from, $to)` - Before navigation
- `OnNavigated($from, $to)` - After navigation
- `OnBackNavigation($to)` - On back navigation

**Example**:
```powershell
$nav = [NavigationManager]::new($app)

# Subscribe to events
$nav.OnNavigated = {
    param($from, $to)
    Write-Host "Navigated from $from to $to"
}

# Navigate
$nav.NavigateTo('TaskList')
$nav.NavigateTo('TaskDetail', @{ taskId = '123' })
$nav.GoBack()  # Returns to TaskList
```

### 5. KeyboardManager (infrastructure/KeyboardManager.ps1)

**Purpose**: Global keyboard shortcut system.

**Responsibilities**:
- Register global shortcuts (always active)
- Register screen-specific shortcuts (active when screen is current)
- Handle key events with priority system
- Detect conflicts
- Generate help text

**Key Methods**:
- `RegisterGlobal($key, $modifiers, $action, $description)` - Global shortcut
- `RegisterScreen($screenName, $key, $modifiers, $action, $description)` - Screen shortcut
- `HandleKey($keyInfo, $currentScreenName)` - Handle key press
- `GetHelpText($screenName)` - Generate help text

**Example**:
```powershell
$km = [KeyboardManager]::new()

# Global shortcuts
$km.RegisterGlobal([ConsoleKey]::Q, [ConsoleModifiers]::Control, {
    $app.Stop()
}, "Quit application")

# Screen shortcuts
$km.RegisterScreen('TaskList', [ConsoleKey]::E, $null, {
    $screen.EditSelectedItem()
}, "Edit selected task")

# Handle key
$keyInfo = [Console]::ReadKey($true)
$handled = $km.HandleKey($keyInfo, 'TaskList')
if (-not $handled) {
    $screen.HandleKeyPress($keyInfo)
}
```

### 6. DataBindingHelper (helpers/DataBindingHelper.ps1)

**Purpose**: Simplify data binding between TaskStore and UI.

**Responsibilities**:
- Bind TaskStore data to screen properties
- Update UI when store changes
- Sync screen state with store
- Handle filtering and sorting

**Key Functions**:
- `Bind-DataToList($screen, $store, $dataType)` - Bind store to list screen
- `Update-ListFromStore($screen, $store, $dataType)` - Refresh list
- `Sync-ScreenState($screen, $store)` - Two-way sync

**Example**:
```powershell
# Bind TaskStore to TaskListScreen
Bind-DataToList -screen $taskListScreen -store $store -dataType 'tasks'

# Store will automatically update screen when tasks change
```

### 7. Base Screen Classes (base/)

#### StandardListScreen (base/StandardListScreen.ps1)

**Purpose**: Base class for list-based screens (e.g., TaskListScreen, ProjectListScreen).

**Features**:
- Item rendering with selection
- Keyboard navigation (Up/Down, PageUp/PageDown, Home/End)
- Filtering and searching
- Sorting
- Bulk operations
- Action menu

**Key Properties**:
- `Items` - List of items to display
- `SelectedIndex` - Currently selected item
- `FilterText` - Current filter
- `SortField` - Field to sort by
- `SortDescending` - Sort direction

**Key Methods**:
- `RenderList()` - Render list to terminal
- `HandleKeyPress($key)` - Handle keyboard input
- `GetSelectedItem()` - Get current selection
- `RefreshItems()` - Reload items from store
- `ApplyFilter($text)` - Filter items

**Events**:
- `OnItemSelected($item)` - Item selected
- `OnItemActivated($item)` - Item activated (Enter)
- `OnFilterChanged($text)` - Filter changed

#### StandardFormScreen (base/StandardFormScreen.ps1)

**Purpose**: Base class for form-based screens (e.g., AddTaskScreen, EditTaskScreen).

**Features**:
- Field-based editing
- Validation on save
- Cancel with confirmation
- Keyboard navigation between fields
- Support for text, number, date, select fields

**Key Properties**:
- `Fields` - List of form fields
- `CurrentFieldIndex` - Currently focused field
- `Data` - Form data hashtable
- `Validator` - Validation function

**Key Methods**:
- `RenderForm()` - Render form to terminal
- `HandleKeyPress($key)` - Handle keyboard input
- `Save()` - Save form data
- `Cancel()` - Cancel and return
- `ValidateData()` - Validate form data

**Events**:
- `OnSave($data)` - Form saved
- `OnCancel()` - Form cancelled
- `OnValidationError($errors)` - Validation failed

#### StandardDashboard (base/StandardDashboard.ps1)

**Purpose**: Base class for dashboard screens with multiple panels.

**Features**:
- Multi-panel layout
- Auto-refresh at intervals
- Metrics and statistics
- Widget composition
- Keyboard shortcuts

**Key Properties**:
- `Panels` - List of dashboard panels
- `RefreshInterval` - Auto-refresh interval (seconds)
- `LastRefresh` - Last refresh timestamp

**Key Methods**:
- `RenderDashboard()` - Render all panels
- `RefreshData()` - Reload dashboard data
- `AddPanel($panel)` - Add panel to dashboard
- `RemovePanel($name)` - Remove panel

**Events**:
- `OnRefresh()` - Dashboard refreshed
- `OnPanelAdded($panel)` - Panel added
- `OnPanelRemoved($name)` - Panel removed

### 8. ApplicationBootstrapper (infrastructure/ApplicationBootstrapper.ps1)

**Purpose**: Bootstrap entire application.

**Responsibilities**:
- Load all dependencies in correct order
- Initialize services (TaskStore, etc.)
- Initialize managers (Navigation, Keyboard)
- Register screens
- Configure global shortcuts
- Return configured application

**Key Functions**:
- `Start-PmcApplication($startScreen, $loadSampleData, $config)` - Bootstrap app
- `Get-BootstrapDiagnostics()` - Get diagnostic info

**Loading Order**:
1. SpeedTUI framework
2. PMC module
3. Dependencies
4. Helpers
5. Theme
6. Layout
7. Widgets
8. Base classes
9. Infrastructure
10. Services
11. Screens
12. Initialize services
13. Register screens
14. Register shortcuts
15. Navigate to start screen

**Example**:
```powershell
. "$PSScriptRoot/infrastructure/ApplicationBootstrapper.ps1"

$app = Start-PmcApplication -StartScreen 'TaskList'
# Application is now running
```

---

## Developer Guide

### Creating a New Screen

#### Step 1: Choose Base Class

Determine which base class fits your screen:
- **StandardListScreen**: List of items (tasks, projects, etc.)
- **StandardFormScreen**: Form for creating/editing entities
- **StandardDashboard**: Dashboard with multiple panels
- **PmcScreen**: Custom screen (no base class)

#### Step 2: Define Screen Class

```powershell
# TaskListScreen.ps1 - Example list screen

using namespace System

class TaskListScreen : StandardListScreen {
    # === Dependencies ===
    [object]$Store

    # === Constructor ===
    TaskListScreen([object]$store) {
        $this.Store = $store
        $this.ScreenTitle = "Task List"
        $this.ItemTypeName = "task"

        # Subscribe to store changes
        $this.Store.OnTasksChanged = {
            param($tasks)
            $this.RefreshItems()
        }
    }

    # === Initialize ===
    [void] Initialize([object]$renderEngine) {
        # Call base initialization
        ([StandardListScreen]$this).Initialize($renderEngine)

        # Load initial data
        $this.RefreshItems()
    }

    # === Data Loading ===
    [void] RefreshItems() {
        $tasks = $this.Store.GetAllTasks()
        $this.Items = $tasks
        $this.RequestRender()
    }

    # === Item Rendering ===
    [string] RenderItem([hashtable]$item, [int]$index, [bool]$isSelected) {
        $prefix = if ($isSelected) { ">" } else { " " }
        $check = if ($item.completed) { "[✓]" } else { "[ ]" }
        $priority = "P$($item.priority)"
        $text = $item.text

        return "$prefix $check $priority $text"
    }

    # === Actions ===
    [void] OnItemActivated([hashtable]$item) {
        # Navigate to task detail
        $this.Navigation.NavigateTo('TaskDetail', @{ taskId = $item.id })
    }

    # === Cleanup ===
    [void] OnDispose() {
        # Unsubscribe from events
        $this.Store.OnTasksChanged = {}
        ([StandardListScreen]$this).OnDispose()
    }
}
```

#### Step 3: Register Screen

```powershell
# In ApplicationBootstrapper.ps1 or separate registration file

[ScreenRegistry]::Register(
    'TaskList',           # Screen name
    [TaskListScreen],     # Screen class
    'Tasks',              # Category
    'View and manage tasks'  # Description
)
```

#### Step 4: Register Screen Shortcuts

```powershell
# Register screen-specific shortcuts
$keyManager.RegisterScreen('TaskList', [ConsoleKey]::A, $null, {
    $this.Navigation.NavigateTo('AddTask')
}, "Add new task")

$keyManager.RegisterScreen('TaskList', [ConsoleKey]::E, $null, {
    $item = $this.GetSelectedItem()
    if ($item) {
        $this.Navigation.NavigateTo('EditTask', @{ taskId = $item.id })
    }
}, "Edit selected task")

$keyManager.RegisterScreen('TaskList', [ConsoleKey]::D, $null, {
    $item = $this.GetSelectedItem()
    if ($item) {
        $this.Store.DeleteTask($item.id)
    }
}, "Delete selected task")
```

### Using Base Classes

#### StandardListScreen Example

```powershell
class MyListScreen : StandardListScreen {
    MyListScreen() {
        $this.ScreenTitle = "My List"
        $this.ItemTypeName = "item"
    }

    [void] RefreshItems() {
        # Load items from store
        $this.Items = $store.GetAllItems()
    }

    [string] RenderItem([hashtable]$item, [int]$index, [bool]$isSelected) {
        # Render single item
        $prefix = if ($isSelected) { ">" } else { " " }
        return "$prefix $($item.name)"
    }

    [void] OnItemActivated([hashtable]$item) {
        # Handle Enter key on item
        Write-Host "Activated: $($item.name)"
    }
}
```

#### StandardFormScreen Example

```powershell
class MyFormScreen : StandardFormScreen {
    MyFormScreen() {
        $this.ScreenTitle = "Add Item"

        # Define form fields
        $this.AddField('name', 'Name', 'text', $true)
        $this.AddField('description', 'Description', 'text', $false)
        $this.AddField('priority', 'Priority', 'number', $true, @{ min = 0; max = 5 })
        $this.AddField('status', 'Status', 'select', $true, @{
            options = @('active', 'pending', 'completed')
        })
    }

    [void] OnSave([hashtable]$data) {
        # Validate
        $result = Test-ItemValid $data
        if (-not $result.IsValid) {
            $this.ShowErrors($result.Errors)
            return
        }

        # Save to store
        $store.AddItem($data)

        # Navigate back
        $this.Navigation.GoBack()
    }

    [void] OnCancel() {
        # Confirm before canceling
        if ($this.ConfirmCancel()) {
            $this.Navigation.GoBack()
        }
    }
}
```

#### StandardDashboard Example

```powershell
class MyDashboard : StandardDashboard {
    MyDashboard([object]$store) {
        $this.Store = $store
        $this.ScreenTitle = "Dashboard"
        $this.RefreshInterval = 30  # Auto-refresh every 30 seconds

        # Add panels
        $this.AddPanel($this.CreateTaskPanel())
        $this.AddPanel($this.CreateProjectPanel())
        $this.AddPanel($this.CreateMetricsPanel())
    }

    [object] CreateTaskPanel() {
        $panel = [PmcPanel]::new()
        $panel.Title = "Tasks"
        $panel.Width = 40
        $panel.Height = 10
        return $panel
    }

    [void] RefreshData() {
        # Reload dashboard data
        $stats = $this.Store.GetStatistics()
        $this.UpdateMetrics($stats)
        $this.RequestRender()
    }
}
```

### Widget Integration

Screens can use widgets for common UI elements:

```powershell
class MyScreen : PmcScreen {
    [object]$Header
    [object]$Panel
    [object]$StatusBar

    MyScreen() {
        # Create widgets
        $this.Header = [PmcHeader]::new()
        $this.Header.Title = "My Screen"

        $this.Panel = [PmcPanel]::new()
        $this.Panel.Title = "Content"

        $this.StatusBar = [PmcStatusBar]::new()
    }

    [void] Render() {
        # Render widgets
        $this.Header.Render($this.RenderEngine)
        $this.Panel.Render($this.RenderEngine)
        $this.StatusBar.Render($this.RenderEngine)
    }
}
```

### Event Handling

#### Subscribe to TaskStore Events

```powershell
$store = [TaskStore]::GetInstance()

# Single event
$store.OnTaskAdded = {
    param($task)
    Write-Host "Task added: $($task.text)"
    $this.RefreshItems()
}

# Multiple events
$store.OnTaskUpdated = { param($task) $this.RefreshItems() }
$store.OnTaskDeleted = { param($id) $this.RefreshItems() }

# Unsubscribe on cleanup
[void] OnDispose() {
    $store.OnTaskAdded = {}
    $store.OnTaskUpdated = {}
    $store.OnTaskDeleted = {}
}
```

#### Subscribe to Navigation Events

```powershell
$nav.OnNavigated = {
    param($from, $to)
    Write-Host "Navigated from $from to $to"
    $this.UpdateBreadcrumb($from, $to)
}

$nav.OnBackNavigation = {
    param($to)
    Write-Host "Navigated back to $to"
}
```

### Navigation

#### Navigate Forward

```powershell
# Simple navigation
$nav.NavigateTo('TaskList')

# With state
$nav.NavigateTo('TaskDetail', @{
    taskId = '123'
    returnTo = 'TaskList'
})
```

#### Navigate Back

```powershell
# Go back
if ($nav.CanGoBack) {
    $nav.GoBack()
}
```

#### Replace Current Screen

```powershell
# Replace without adding to history
$nav.Replace('Login')
```

### Keyboard Shortcuts

#### Global Shortcuts (Always Active)

```powershell
$km.RegisterGlobal([ConsoleKey]::Q, [ConsoleModifiers]::Control, {
    $app.Stop()
}, "Quit application")

$km.RegisterGlobal([ConsoleKey]::F1, [ConsoleModifiers]::None, {
    $helpText = $km.GetHelpText($nav.CurrentScreen)
    Write-Host $helpText
    [Console]::ReadKey($true) | Out-Null
}, "Show help")
```

#### Screen-Specific Shortcuts

```powershell
# Active only when TaskList is current screen
$km.RegisterScreen('TaskList', [ConsoleKey]::A, $null, {
    $nav.NavigateTo('AddTask')
}, "Add task")

$km.RegisterScreen('TaskList', [ConsoleKey]::E, $null, {
    $item = $screen.GetSelectedItem()
    if ($item) {
        $nav.NavigateTo('EditTask', @{ taskId = $item.id })
    }
}, "Edit task")
```

---

## API Reference

### TaskStore API

#### Constructor
```powershell
# Singleton - use GetInstance()
$store = [TaskStore]::GetInstance()
```

#### Methods

##### Data Loading
- `[bool] LoadData()` - Load data from backend
- `[bool] ReloadData()` - Reload data (discards in-memory changes)
- `[bool] SaveData()` - Save all data to backend

##### Task Operations
- `[array] GetAllTasks()` - Get all tasks
- `[hashtable] GetTask([string]$id)` - Get task by ID
- `[bool] AddTask([hashtable]$task)` - Add task
- `[bool] UpdateTask([string]$id, [hashtable]$changes)` - Update task
- `[bool] DeleteTask([string]$id)` - Delete task
- `[array] GetTasksByProject([string]$projectName)` - Filter by project
- `[array] SearchTasks([string]$searchText)` - Search tasks
- `[array] GetTasksByPriority([int]$min, [int]$max)` - Filter by priority

##### Project Operations
- `[array] GetAllProjects()` - Get all projects
- `[hashtable] GetProject([string]$name)` - Get project by name
- `[bool] AddProject([hashtable]$project)` - Add project
- `[bool] UpdateProject([string]$name, [hashtable]$changes)` - Update project
- `[bool] DeleteProject([string]$name)` - Delete project

##### Time Log Operations
- `[array] GetAllTimeLogs()` - Get all time logs
- `[array] GetTimeLogsForTask([string]$taskId)` - Get logs for task
- `[bool] AddTimeLog([hashtable]$timelog)` - Add time log
- `[bool] DeleteTimeLog([string]$id)` - Delete time log

##### Batch Operations
- `[int] AddTasks([hashtable[]]$tasks)` - Add multiple tasks

##### Utilities
- `[hashtable] GetStatistics()` - Get data statistics

#### Properties
- `[bool]$IsLoaded` - Whether data is loaded
- `[bool]$IsSaving` - Whether save is in progress
- `[string]$LastError` - Last error message

#### Events
- `$OnTaskAdded` - Fired after task added: `{ param($task) }`
- `$OnTaskUpdated` - Fired after task updated: `{ param($task) }`
- `$OnTaskDeleted` - Fired after task deleted: `{ param($id) }`
- `$OnTasksChanged` - Fired after any task change: `{ param($tasks) }`
- Similar events for projects and time logs
- `$OnDataChanged` - Fired after any data change: `{ }`
- `$OnLoadError` - Fired on load error: `{ param($error) }`
- `$OnSaveError` - Fired on save error: `{ param($error) }`

### ValidationHelper API

#### Task Validation
```powershell
[ValidationResult] Test-TaskValid([hashtable]$task)
```

**Returns**: `ValidationResult` with `IsValid`, `Errors`, `FieldErrors`

**Example**:
```powershell
$result = Test-TaskValid @{ text = 'Test'; priority = 3 }
if (-not $result.IsValid) {
    foreach ($error in $result.Errors) {
        Write-Host $error
    }
}
```

#### Project Validation
```powershell
[ValidationResult] Test-ProjectValid([hashtable]$project, [array]$existingProjects)
```

#### Time Log Validation
```powershell
[ValidationResult] Test-TimeLogValid([hashtable]$timelog, [scriptblock]$taskExists)
```

#### Schema-Based Validation
```powershell
[string[]] Get-ValidationErrors([hashtable]$data, [hashtable]$schema)
```

**Schema Format**:
```powershell
$schema = @{
    fieldName = @{
        Required = $true/$false
        Type = 'string'/'int'/'bool'/'datetime'/'array'
        Min = 0            # For int
        Max = 100          # For int
        MinLength = 1      # For string
        MaxLength = 200    # For string
        Pattern = '^...$'  # Regex for string
        Validator = { param($value) return $true/$false }  # Custom
    }
}
```

**Example**:
```powershell
$schema = @{
    name = @{ Required = $true; Type = 'string'; MaxLength = 50 }
    age = @{ Required = $false; Type = 'int'; Min = 0; Max = 120 }
    email = @{
        Required = $true
        Type = 'string'
        Validator = { param($value) return $value -match '^[\w\.\-]+@[\w\.\-]+\.\w+$' }
    }
}

$errors = Get-ValidationErrors @{ name = 'John'; age = 30; email = 'john@example.com' } $schema
```

### ScreenRegistry API

#### Registration
```powershell
[bool] [ScreenRegistry]::Register(
    [string]$name,
    [type]$type,
    [string]$category,
    [string]$description
)
```

**Example**:
```powershell
[ScreenRegistry]::Register('TaskList', [TaskListScreen], 'Tasks', 'View tasks')
```

#### Creation
```powershell
[object] [ScreenRegistry]::Create([string]$name, [object[]]$args)
```

**Example**:
```powershell
$screen = [ScreenRegistry]::Create('TaskList')
```

#### Queries
```powershell
[array] [ScreenRegistry]::GetAllScreens()
[array] [ScreenRegistry]::GetByCategory([string]$category)
[ScreenRegistration] [ScreenRegistry]::GetRegistration([string]$name)
[bool] [ScreenRegistry]::IsRegistered([string]$name)
```

#### Categories
```powershell
[array] [ScreenRegistry]::GetCategories()
[bool] [ScreenRegistry]::AddCategory([string]$category)
```

**Default Categories**: Tasks, Projects, Reports, Settings, Other

### NavigationManager API

#### Navigation
```powershell
[bool] NavigateTo([string]$screenName, [hashtable]$state)
[bool] GoBack()
[bool] Replace([string]$screenName, [hashtable]$state)
```

#### History
```powershell
[void] ClearHistory()
[array] GetHistory()
[int] GetDepth()
```

#### Properties
- `[string]$CurrentScreen` - Current screen name
- `[bool]$CanGoBack` - Whether can go back
- `[int]$MaxHistorySize` - Max history entries (default: 50)
- `[string]$LastError` - Last error message

#### Events
- `$OnNavigating` - Before navigation: `{ param($from, $to) }`
- `$OnNavigated` - After navigation: `{ param($from, $to) }`
- `$OnBackNavigation` - On back: `{ param($to) }`

### KeyboardManager API

#### Registration
```powershell
[bool] RegisterGlobal(
    [ConsoleKey]$key,
    [ConsoleModifiers]$modifiers,
    [scriptblock]$action,
    [string]$description
)

[bool] RegisterScreen(
    [string]$screenName,
    [ConsoleKey]$key,
    [ConsoleModifiers]$modifiers,
    [scriptblock]$action,
    [string]$description
)
```

**Modifiers**:
- `[ConsoleModifiers]::Control`
- `[ConsoleModifiers]::Alt`
- `[ConsoleModifiers]::Shift`
- `[ConsoleModifiers]::None`

**Example**:
```powershell
$km.RegisterGlobal([ConsoleKey]::Q, [ConsoleModifiers]::Control, {
    $app.Stop()
}, "Quit")

$km.RegisterScreen('TaskList', [ConsoleKey]::E, [ConsoleModifiers]::None, {
    $screen.EditSelectedItem()
}, "Edit")
```

#### Key Handling
```powershell
[bool] HandleKey([System.ConsoleKeyInfo]$keyInfo, [string]$currentScreenName)
```

**Returns**: `$true` if key was handled, `$false` otherwise

#### Queries
```powershell
[array] GetGlobalShortcuts()
[array] GetScreenShortcuts([string]$screenName)
[array] GetAllShortcuts()
[string] GetHelpText([string]$screenName)
```

#### Unregistration
```powershell
[bool] UnregisterGlobal([ConsoleKey]$key, [ConsoleModifiers]$modifiers)
[bool] UnregisterScreen([string]$screenName, [ConsoleKey]$key, [ConsoleModifiers]$modifiers)
```

### StandardListScreen API

#### Abstract Methods (Must Override)
```powershell
[void] RefreshItems()
[string] RenderItem([hashtable]$item, [int]$index, [bool]$isSelected)
```

#### Optional Overrides
```powershell
[void] OnItemActivated([hashtable]$item)
[void] OnItemSelected([hashtable]$item)
[bool] ShouldShowItem([hashtable]$item)
```

#### Built-in Methods
```powershell
[hashtable] GetSelectedItem()
[void] SetSelectedIndex([int]$index)
[void] ApplyFilter([string]$text)
[void] ApplySort([string]$field, [bool]$descending)
[void] HandleKeyPress([ConsoleKeyInfo]$key)
```

#### Properties
- `[array]$Items` - List of items
- `[int]$SelectedIndex` - Selected item index
- `[string]$FilterText` - Current filter
- `[string]$SortField` - Sort field
- `[bool]$SortDescending` - Sort direction
- `[string]$ScreenTitle` - Screen title
- `[string]$ItemTypeName` - Item type name (for messages)

#### Built-in Keyboard Shortcuts
- `↑` / `k` - Move selection up
- `↓` / `j` - Move selection down
- `PageUp` - Move up one page
- `PageDown` - Move down one page
- `Home` - Go to first item
- `End` - Go to last item
- `Enter` - Activate selected item
- `/` - Start filtering
- `Escape` - Clear filter

### StandardFormScreen API

#### Field Management
```powershell
[void] AddField([string]$name, [string]$label, [string]$type, [bool]$required, [hashtable]$options)
[void] SetFieldValue([string]$name, $value)
[$value] GetFieldValue([string]$name)
```

**Field Types**:
- `text` - Text input
- `number` - Number input
- `date` - Date input
- `select` - Dropdown selection
- `checkbox` - Boolean checkbox

#### Abstract Methods (Must Override)
```powershell
[void] OnSave([hashtable]$data)
[void] OnCancel()
```

#### Optional Overrides
```powershell
[ValidationResult] ValidateData([hashtable]$data)
[void] OnFieldChanged([string]$fieldName, $value)
```

#### Built-in Methods
```powershell
[void] Save()
[void] Cancel()
[bool] ConfirmCancel()
[void] ShowErrors([array]$errors)
[void] HandleKeyPress([ConsoleKeyInfo]$key)
```

#### Properties
- `[array]$Fields` - Form fields
- `[int]$CurrentFieldIndex` - Focused field
- `[hashtable]$Data` - Form data
- `[string]$ScreenTitle` - Screen title
- `[bool]$IsDirty` - Whether data changed

#### Built-in Keyboard Shortcuts
- `Tab` - Next field
- `Shift+Tab` - Previous field
- `Enter` - Save form
- `Escape` - Cancel form

### StandardDashboard API

#### Panel Management
```powershell
[void] AddPanel([object]$panel)
[void] RemovePanel([string]$name)
[object] GetPanel([string]$name)
```

#### Abstract Methods (Must Override)
```powershell
[void] RefreshData()
```

#### Optional Overrides
```powershell
[void] OnRefresh()
```

#### Built-in Methods
```powershell
[void] StartAutoRefresh()
[void] StopAutoRefresh()
[void] HandleKeyPress([ConsoleKeyInfo]$key)
```

#### Properties
- `[array]$Panels` - Dashboard panels
- `[int]$RefreshInterval` - Auto-refresh interval (seconds)
- `[DateTime]$LastRefresh` - Last refresh timestamp
- `[string]$ScreenTitle` - Screen title

#### Built-in Keyboard Shortcuts
- `F5` - Manual refresh
- `Space` - Toggle auto-refresh

---

## Examples

### Complete TaskListScreen Example

```powershell
# TaskListScreen.ps1

using namespace System

. "$PSScriptRoot/../base/StandardListScreen.ps1"
. "$PSScriptRoot/../services/TaskStore.ps1"

class TaskListScreen : StandardListScreen {
    # === Dependencies ===
    [object]$Store
    [object]$Navigation

    # === Constructor ===
    TaskListScreen([object]$store, [object]$navigation) {
        $this.Store = $store
        $this.Navigation = $navigation

        # Configuration
        $this.ScreenTitle = "Task List"
        $this.ItemTypeName = "task"
        $this.SortField = "priority"
        $this.SortDescending = $true

        # Subscribe to store events
        $this.Store.OnTasksChanged = {
            param($tasks)
            $this.RefreshItems()
        }
    }

    # === Initialization ===
    [void] Initialize([object]$renderEngine) {
        # Call base initialization
        ([StandardListScreen]$this).Initialize($renderEngine)

        # Load initial data
        $this.RefreshItems()

        # Register shortcuts
        $this.RegisterShortcuts()
    }

    # === Data Loading ===
    [void] RefreshItems() {
        $tasks = $this.Store.GetAllTasks()

        # Apply client-side filters
        if (-not [string]::IsNullOrWhiteSpace($this.FilterText)) {
            $filterLower = $this.FilterText.ToLower()
            $tasks = $tasks | Where-Object {
                $_.text.ToLower().Contains($filterLower)
            }
        }

        # Apply sort
        if (-not [string]::IsNullOrWhiteSpace($this.SortField)) {
            $tasks = $tasks | Sort-Object -Property $this.SortField -Descending:$this.SortDescending
        }

        $this.Items = $tasks
        $this.RequestRender()
    }

    # === Item Rendering ===
    [string] RenderItem([hashtable]$item, [int]$index, [bool]$isSelected) {
        $prefix = if ($isSelected) { ">" } else { " " }
        $check = if ($item.completed) { "[✓]" } else { "[ ]" }
        $priority = "P$($item.priority)"

        # Color based on priority
        $color = switch ($item.priority) {
            5 { "`e[31m" }  # Red
            4 { "`e[33m" }  # Yellow
            3 { "`e[37m" }  # White
            default { "`e[90m" }  # Gray
        }
        $reset = "`e[0m"

        $text = $item.text
        if ($text.Length -gt 50) {
            $text = $text.Substring(0, 47) + "..."
        }

        # Due date indicator
        $dueInfo = ""
        if ($item.due) {
            $daysUntilDue = ($item.due - (Get-Date)).Days
            if ($daysUntilDue -lt 0) {
                $dueInfo = "`e[31m[OVERDUE]`e[0m"
            } elseif ($daysUntilDue -eq 0) {
                $dueInfo = "`e[33m[TODAY]`e[0m"
            } elseif ($daysUntilDue -le 3) {
                $dueInfo = "`e[33m[DUE SOON]`e[0m"
            }
        }

        return "$prefix $check $color$priority$reset $text $dueInfo"
    }

    # === Actions ===
    [void] OnItemActivated([hashtable]$item) {
        # Navigate to task detail on Enter
        $this.Navigation.NavigateTo('TaskDetail', @{ taskId = $item.id })
    }

    [void] OnItemSelected([hashtable]$item) {
        # Update status bar when selection changes
        $this.UpdateStatusBar($item)
    }

    # === Custom Actions ===
    [void] AddTask() {
        $this.Navigation.NavigateTo('AddTask')
    }

    [void] EditTask() {
        $item = $this.GetSelectedItem()
        if ($item) {
            $this.Navigation.NavigateTo('EditTask', @{ taskId = $item.id })
        }
    }

    [void] DeleteTask() {
        $item = $this.GetSelectedItem()
        if ($item) {
            # Confirm deletion
            if ($this.ConfirmDelete($item.text)) {
                $this.Store.DeleteTask($item.id)
            }
        }
    }

    [void] ToggleComplete() {
        $item = $this.GetSelectedItem()
        if ($item) {
            $this.Store.UpdateTask($item.id, @{
                completed = -not $item.completed
            })
        }
    }

    [bool] ConfirmDelete([string]$taskText) {
        Write-Host "`nDelete task: $taskText? (y/n) " -NoNewline
        $response = [Console]::ReadKey($true)
        return $response.KeyChar -eq 'y'
    }

    [void] UpdateStatusBar([hashtable]$item) {
        if ($null -ne $this.StatusBar) {
            $project = if ($item.project) { $item.project } else { "none" }
            $this.StatusBar.SetText("Project: $project | Priority: $($item.priority)")
        }
    }

    # === Shortcut Registration ===
    [void] RegisterShortcuts() {
        $km = $this.App.Keyboard

        $km.RegisterScreen('TaskList', [ConsoleKey]::A, [ConsoleModifiers]::None, {
            $this.AddTask()
        }, "Add task")

        $km.RegisterScreen('TaskList', [ConsoleKey]::E, [ConsoleModifiers]::None, {
            $this.EditTask()
        }, "Edit task")

        $km.RegisterScreen('TaskList', [ConsoleKey]::D, [ConsoleModifiers]::None, {
            $this.DeleteTask()
        }, "Delete task")

        $km.RegisterScreen('TaskList', [ConsoleKey]::Spacebar, [ConsoleModifiers]::None, {
            $this.ToggleComplete()
        }, "Toggle complete")

        $km.RegisterScreen('TaskList', [ConsoleKey]::P, [ConsoleModifiers]::None, {
            $this.ToggleSort()
        }, "Toggle sort by priority")
    }

    [void] ToggleSort() {
        if ($this.SortField -eq "priority") {
            $this.SortDescending = -not $this.SortDescending
        } else {
            $this.SortField = "priority"
            $this.SortDescending = $true
        }
        $this.RefreshItems()
    }

    # === Cleanup ===
    [void] OnDispose() {
        # Unsubscribe from events
        $this.Store.OnTasksChanged = {}

        # Call base cleanup
        ([StandardListScreen]$this).OnDispose()
    }
}
```

### Complete AddTaskScreen Example

```powershell
# AddTaskScreen.ps1

using namespace System

. "$PSScriptRoot/../base/StandardFormScreen.ps1"
. "$PSScriptRoot/../services/TaskStore.ps1"
. "$PSScriptRoot/../helpers/ValidationHelper.ps1"

class AddTaskScreen : StandardFormScreen {
    # === Dependencies ===
    [object]$Store
    [object]$Navigation

    # === Constructor ===
    AddTaskScreen([object]$store, [object]$navigation) {
        $this.Store = $store
        $this.Navigation = $navigation

        # Configuration
        $this.ScreenTitle = "Add Task"

        # Define form fields
        $this.DefineFields()
    }

    # === Field Definition ===
    [void] DefineFields() {
        # Text (required)
        $this.AddField('text', 'Task Description', 'text', $true, @{
            placeholder = 'Enter task description'
        })

        # Project (optional)
        $projects = $this.Store.GetAllProjects() | ForEach-Object { $_.name }
        $this.AddField('project', 'Project', 'select', $false, @{
            options = $projects
            allowEmpty = $true
        })

        # Priority (required)
        $this.AddField('priority', 'Priority', 'number', $true, @{
            min = 0
            max = 5
            default = 3
        })

        # Due date (optional)
        $this.AddField('due', 'Due Date', 'date', $false, @{
            format = 'yyyy-MM-dd'
            allowEmpty = $true
        })

        # Tags (optional)
        $this.AddField('tags', 'Tags', 'text', $false, @{
            placeholder = 'tag1, tag2, tag3'
            help = 'Comma-separated tags'
        })

        # Status (required)
        $this.AddField('status', 'Status', 'select', $true, @{
            options = @('todo', 'in-progress', 'blocked')
            default = 'todo'
        })
    }

    # === Validation ===
    [ValidationResult] ValidateData([hashtable]$data) {
        # Parse tags from comma-separated string
        if ($data.ContainsKey('tags') -and -not [string]::IsNullOrWhiteSpace($data.tags)) {
            $data.tags = $data.tags -split ',' | ForEach-Object { $_.Trim() }
        } else {
            $data.tags = @()
        }

        # Use ValidationHelper
        return Test-TaskValid $data
    }

    # === Save Handler ===
    [void] OnSave([hashtable]$data) {
        # Validate
        $result = $this.ValidateData($data)
        if (-not $result.IsValid) {
            $this.ShowErrors($result.Errors)
            return
        }

        # Add to store
        if ($this.Store.AddTask($data)) {
            Write-Host "`nTask added successfully!" -ForegroundColor Green
            Start-Sleep -Milliseconds 500

            # Navigate back to task list
            $this.Navigation.GoBack()
        } else {
            $this.ShowErrors(@($this.Store.LastError))
        }
    }

    # === Cancel Handler ===
    [void] OnCancel() {
        # Confirm if data changed
        if ($this.IsDirty) {
            if ($this.ConfirmCancel()) {
                $this.Navigation.GoBack()
            }
        } else {
            $this.Navigation.GoBack()
        }
    }

    # === Field Change Handler ===
    [void] OnFieldChanged([string]$fieldName, $value) {
        # React to field changes
        if ($fieldName -eq 'project') {
            # Could update available tags based on project
            $this.RefreshTagSuggestions($value)
        }
    }

    [void] RefreshTagSuggestions([string]$project) {
        # Get tags used in this project
        if (-not [string]::IsNullOrWhiteSpace($project)) {
            $projectTasks = $this.Store.GetTasksByProject($project)
            $commonTags = $projectTasks | ForEach-Object { $_.tags } | Group-Object | Sort-Object Count -Descending | Select-Object -First 5 -ExpandProperty Name

            if ($commonTags) {
                $tagField = $this.GetField('tags')
                $tagField.Options.suggestions = $commonTags
            }
        }
    }

    # === Cleanup ===
    [void] OnDispose() {
        ([StandardFormScreen]$this).OnDispose()
    }
}
```

### Complete DashboardScreen Example

```powershell
# DashboardScreen.ps1

using namespace System

. "$PSScriptRoot/../base/StandardDashboard.ps1"
. "$PSScriptRoot/../services/TaskStore.ps1"
. "$PSScriptRoot/../widgets/PmcPanel.ps1"

class DashboardScreen : StandardDashboard {
    # === Dependencies ===
    [object]$Store
    [object]$Navigation

    # === Constructor ===
    DashboardScreen([object]$store, [object]$navigation) {
        $this.Store = $store
        $this.Navigation = $navigation

        # Configuration
        $this.ScreenTitle = "Dashboard"
        $this.RefreshInterval = 30  # Auto-refresh every 30 seconds

        # Create panels
        $this.CreatePanels()

        # Subscribe to store events
        $this.Store.OnDataChanged = {
            $this.RefreshData()
        }
    }

    # === Panel Creation ===
    [void] CreatePanels() {
        # Task summary panel
        $taskPanel = $this.CreateTaskSummaryPanel()
        $this.AddPanel($taskPanel)

        # Project panel
        $projectPanel = $this.CreateProjectPanel()
        $this.AddPanel($projectPanel)

        # Recent activity panel
        $activityPanel = $this.CreateActivityPanel()
        $this.AddPanel($activityPanel)

        # Metrics panel
        $metricsPanel = $this.CreateMetricsPanel()
        $this.AddPanel($metricsPanel)
    }

    [object] CreateTaskSummaryPanel() {
        $panel = [PmcPanel]::new()
        $panel.Name = "TaskSummary"
        $panel.Title = "Task Summary"
        $panel.Width = 40
        $panel.Height = 10
        $panel.X = 0
        $panel.Y = 2
        return $panel
    }

    [object] CreateProjectPanel() {
        $panel = [PmcPanel]::new()
        $panel.Name = "Projects"
        $panel.Title = "Projects"
        $panel.Width = 40
        $panel.Height = 10
        $panel.X = 42
        $panel.Y = 2
        return $panel
    }

    [object] CreateActivityPanel() {
        $panel = [PmcPanel]::new()
        $panel.Name = "Activity"
        $panel.Title = "Recent Activity"
        $panel.Width = 40
        $panel.Height = 10
        $panel.X = 0
        $panel.Y = 14
        return $panel
    }

    [object] CreateMetricsPanel() {
        $panel = [PmcPanel]::new()
        $panel.Name = "Metrics"
        $panel.Title = "Metrics"
        $panel.Width = 40
        $panel.Height = 10
        $panel.X = 42
        $panel.Y = 14
        return $panel
    }

    # === Data Refresh ===
    [void] RefreshData() {
        # Get statistics
        $stats = $this.Store.GetStatistics()

        # Update task summary panel
        $taskPanel = $this.GetPanel("TaskSummary")
        if ($taskPanel) {
            $taskPanel.Content = $this.RenderTaskSummary($stats)
        }

        # Update project panel
        $projectPanel = $this.GetPanel("Projects")
        if ($projectPanel) {
            $projectPanel.Content = $this.RenderProjects()
        }

        # Update activity panel
        $activityPanel = $this.GetPanel("Activity")
        if ($activityPanel) {
            $activityPanel.Content = $this.RenderRecentActivity()
        }

        # Update metrics panel
        $metricsPanel = $this.GetPanel("Metrics")
        if ($metricsPanel) {
            $metricsPanel.Content = $this.RenderMetrics($stats)
        }

        # Update last refresh timestamp
        $this.LastRefresh = Get-Date

        # Request re-render
        $this.RequestRender()
    }

    [string] RenderTaskSummary([hashtable]$stats) {
        $lines = @()
        $lines += "Total Tasks:     $($stats.taskCount)"
        $lines += "Pending:         $($stats.pendingTaskCount)"
        $lines += "Completed:       $($stats.completedTaskCount)"
        $lines += ""

        # Priority breakdown
        $allTasks = $this.Store.GetAllTasks()
        $byPriority = $allTasks | Group-Object -Property priority | Sort-Object Name -Descending

        $lines += "By Priority:"
        foreach ($group in $byPriority) {
            $lines += "  P$($group.Name): $($group.Count)"
        }

        return $lines -join "`n"
    }

    [string] RenderProjects() {
        $lines = @()
        $projects = $this.Store.GetAllProjects()

        if ($projects.Count -eq 0) {
            $lines += "No projects"
        } else {
            foreach ($project in $projects) {
                $taskCount = ($this.Store.GetTasksByProject($project.name)).Count
                $lines += "$($project.name): $taskCount tasks"
            }
        }

        return $lines -join "`n"
    }

    [string] RenderRecentActivity() {
        $lines = @()
        $allTasks = $this.Store.GetAllTasks()

        # Get recently modified tasks
        $recentTasks = $allTasks | Sort-Object -Property modified -Descending | Select-Object -First 5

        if ($recentTasks.Count -eq 0) {
            $lines += "No recent activity"
        } else {
            foreach ($task in $recentTasks) {
                $timeAgo = $this.GetTimeAgo($task.modified)
                $lines += "$timeAgo: $($task.text)"
            }
        }

        return $lines -join "`n"
    }

    [string] RenderMetrics([hashtable]$stats) {
        $lines = @()

        # Completion rate
        $completionRate = if ($stats.taskCount -gt 0) {
            [math]::Round(($stats.completedTaskCount / $stats.taskCount) * 100, 1)
        } else {
            0
        }

        $lines += "Completion Rate: $completionRate%"
        $lines += ""

        # Average priority
        $allTasks = $this.Store.GetAllTasks()
        $avgPriority = if ($allTasks.Count -gt 0) {
            [math]::Round(($allTasks | Measure-Object -Property priority -Average).Average, 1)
        } else {
            0
        }

        $lines += "Avg Priority: $avgPriority"
        $lines += ""

        # Overdue tasks
        $now = Get-Date
        $overdueTasks = $allTasks | Where-Object {
            $_.due -and $_.due -lt $now -and -not $_.completed
        }

        $lines += "Overdue Tasks: $($overdueTasks.Count)"

        return $lines -join "`n"
    }

    [string] GetTimeAgo([DateTime]$timestamp) {
        $diff = (Get-Date) - $timestamp

        if ($diff.TotalMinutes -lt 1) {
            return "just now"
        } elseif ($diff.TotalHours -lt 1) {
            $minutes = [math]::Floor($diff.TotalMinutes)
            return "$minutes min ago"
        } elseif ($diff.TotalDays -lt 1) {
            $hours = [math]::Floor($diff.TotalHours)
            return "$hours hour$(if($hours -gt 1){'s'}) ago"
        } else {
            $days = [math]::Floor($diff.TotalDays)
            return "$days day$(if($days -gt 1){'s'}) ago"
        }
    }

    # === Cleanup ===
    [void] OnDispose() {
        # Unsubscribe from events
        $this.Store.OnDataChanged = {}

        # Call base cleanup
        ([StandardDashboard]$this).OnDispose()
    }
}
```

---

## Best Practices

### State Management

#### Use TaskStore as Single Source of Truth

**Good**:
```powershell
# Screen loads data from TaskStore
[void] RefreshItems() {
    $this.Items = $this.Store.GetAllTasks()
}

# Screen modifies data through TaskStore
[void] DeleteTask() {
    $this.Store.DeleteTask($taskId)
    # Store fires event, screen auto-refreshes
}
```

**Bad**:
```powershell
# Don't maintain separate state
$this.localTasks = $tasks  # WRONG - out of sync with store
```

#### Subscribe to Store Events

```powershell
# Subscribe in constructor
TaskListScreen() {
    $this.Store.OnTasksChanged = {
        param($tasks)
        $this.RefreshItems()
    }
}

# Unsubscribe in cleanup
[void] OnDispose() {
    $this.Store.OnTasksChanged = {}
}
```

### Error Handling

#### Always Validate Before Saving

```powershell
[void] OnSave([hashtable]$data) {
    # Validate first
    $result = Test-TaskValid $data
    if (-not $result.IsValid) {
        $this.ShowErrors($result.Errors)
        return
    }

    # Then save
    if (-not $this.Store.AddTask($data)) {
        $this.ShowErrors(@($this.Store.LastError))
        return
    }

    # Navigate back on success
    $this.Navigation.GoBack()
}
```

#### Handle Store Errors

```powershell
# Check return value
if (-not $store.AddTask($task)) {
    Write-Host "Error: $($store.LastError)" -ForegroundColor Red
}

# Or subscribe to error events
$store.OnSaveError = {
    param($error)
    Write-Host "Save failed: $error" -ForegroundColor Red
}
```

### Performance Optimization

#### Minimize Re-renders

```powershell
# Request render only when needed
[void] RefreshItems() {
    $this.Items = $this.Store.GetAllTasks()
    $this.RequestRender()  # Single render at end
}

# Don't render on every data change
# WRONG:
$this.Items = $data
$this.RequestRender()  # Don't do this in loop
```

#### Use Batch Operations

```powershell
# Good - single save
$tasksToAdd = @()
foreach ($row in $excelData) {
    $tasksToAdd += @{ text = $row.text; project = $row.project }
}
$store.AddTasks($tasksToAdd)  # Batch operation

# Bad - multiple saves
foreach ($row in $excelData) {
    $store.AddTask(@{ text = $row.text })  # Many saves
}
```

### Memory Management

#### Always Implement OnDispose

```powershell
class MyScreen : StandardListScreen {
    [void] OnDispose() {
        # Unsubscribe from events
        $this.Store.OnTasksChanged = {}
        $this.Store.OnTaskDeleted = {}

        # Dispose timers
        if ($this.AutoRefreshTimer) {
            $this.AutoRefreshTimer.Stop()
            $this.AutoRefreshTimer.Dispose()
        }

        # Call base cleanup
        ([StandardListScreen]$this).OnDispose()
    }
}
```

#### Clear References

```powershell
[void] OnDispose() {
    # Clear large collections
    $this.Items = @()
    $this.Cache = $null

    # Clear event handlers
    $this.OnItemSelected = {}
}
```

### Testing Strategies

#### Unit Test Components Separately

```powershell
# Test ValidationHelper
. "$PSScriptRoot/tests/TestValidationHelper.ps1"
Test-ValidationHelper

# Test ScreenRegistry
. "$PSScriptRoot/tests/TestScreenRegistry.ps1"
Test-ScreenRegistry

# Test NavigationManager
. "$PSScriptRoot/tests/TestNavigationManager.ps1"
Test-NavigationManager
```

#### Integration Test with TaskStore

```powershell
# Create test store
[TaskStore]::ResetInstance()
$store = [TaskStore]::GetInstance()

# Add test data
$store.AddTask(@{ text = 'Test task'; priority = 3 })

# Test screen
$screen = [TaskListScreen]::new($store, $nav)
$screen.RefreshItems()

# Assert
if ($screen.Items.Count -ne 1) {
    throw "Expected 1 item, got $($screen.Items.Count)"
}
```

### Code Organization

#### Group Related Code

```powershell
class MyScreen {
    # === Dependencies (top) ===
    [object]$Store
    [object]$Navigation

    # === Constructor ===
    MyScreen() { }

    # === Initialization ===
    [void] Initialize() { }

    # === Data Operations ===
    [void] LoadData() { }
    [void] SaveData() { }

    # === UI Rendering ===
    [void] Render() { }
    [string] RenderItem() { }

    # === Event Handlers ===
    [void] OnItemSelected() { }

    # === Actions ===
    [void] DeleteItem() { }

    # === Helpers (private) ===
    hidden [void] UpdateStatusBar() { }

    # === Cleanup (bottom) ===
    [void] OnDispose() { }
}
```

#### Use Descriptive Names

```powershell
# Good
[void] RefreshTasksFromStore()
[void] NavigateToTaskDetail([string]$taskId)
[bool] ConfirmDeleteTask([string]$taskText)

# Bad
[void] Refresh()  # Refresh what?
[void] GoTo([string]$id)  # Go where?
[bool] Confirm([string]$text)  # Confirm what?
```

---

## Troubleshooting

### Common Issues

#### TaskStore Returns Null

**Symptom**: `$store.GetAllTasks()` returns null or empty array when you expect data.

**Causes**:
1. Data not loaded from backend
2. Get-PmcAllData not working
3. Store not initialized

**Solutions**:
```powershell
# Check if store loaded
$store = [TaskStore]::GetInstance()
if (-not $store.IsLoaded) {
    Write-Host "Store not loaded. Loading now..."
    $store.LoadData()
}

# Check for errors
if (-not [string]::IsNullOrWhiteSpace($store.LastError)) {
    Write-Host "Store error: $($store.LastError)"
}

# Verify backend data
$backendData = Get-PmcAllData
if ($null -eq $backendData -or $null -eq $backendData.tasks) {
    Write-Host "No data from PMC backend"
}
```

#### Screen Not Registered

**Symptom**: `NavigateTo('MyScreen')` fails with "Screen not registered" error.

**Causes**:
1. Screen not registered in ScreenRegistry
2. Typo in screen name
3. Registration happened after navigation

**Solutions**:
```powershell
# Check registration
if ([ScreenRegistry]::IsRegistered('MyScreen')) {
    Write-Host "Screen is registered"
} else {
    Write-Host "Screen NOT registered"
}

# List all registered screens
$allScreens = [ScreenRegistry]::GetAllScreens()
foreach ($screen in $allScreens) {
    Write-Host "  - $($screen.Name)"
}

# Register if missing
[ScreenRegistry]::Register('MyScreen', [MyScreen], 'Other', 'My screen')
```

#### Navigation History Lost

**Symptom**: `GoBack()` fails or returns to wrong screen.

**Causes**:
1. Used `Replace()` instead of `NavigateTo()`
2. History was cleared
3. MaxHistorySize reached

**Solutions**:
```powershell
# Check if can go back
if ($nav.CanGoBack) {
    Write-Host "Can go back, depth: $($nav.GetDepth())"
} else {
    Write-Host "Cannot go back (no history)"
}

# View history
$history = $nav.GetHistory()
foreach ($entry in $history) {
    Write-Host "  - $($entry.ScreenName) at $($entry.Timestamp)"
}

# Increase max history size if needed
$nav.MaxHistorySize = 100
```

#### Keyboard Shortcuts Not Working

**Symptom**: Pressing keyboard shortcut does nothing.

**Causes**:
1. Shortcut not registered
2. Screen name mismatch
3. Global shortcut overrides screen shortcut
4. Key not handled properly

**Solutions**:
```powershell
# Check if shortcut registered
$globalShortcuts = $km.GetGlobalShortcuts()
$screenShortcuts = $km.GetScreenShortcuts('TaskList')

Write-Host "Global shortcuts: $($globalShortcuts.Count)"
Write-Host "Screen shortcuts: $($screenShortcuts.Count)"

# Print all shortcuts
foreach ($shortcut in $globalShortcuts) {
    Write-Host "  Global: $($shortcut.GetKeyString()) - $($shortcut.Description)"
}

foreach ($shortcut in $screenShortcuts) {
    Write-Host "  Screen: $($shortcut.GetKeyString()) - $($shortcut.Description)"
}

# Test key handling
$keyInfo = [Console]::ReadKey($true)
$handled = $km.HandleKey($keyInfo, $nav.CurrentScreen)
Write-Host "Key handled: $handled"
```

#### Validation Always Fails

**Symptom**: Validation fails even with valid data.

**Causes**:
1. Missing required fields
2. Wrong data types
3. Invalid field values
4. Schema mismatch

**Solutions**:
```powershell
# Test validation
$task = @{
    text = 'Test task'
    priority = 3
}

$result = Test-TaskValid $task
if (-not $result.IsValid) {
    Write-Host "Validation failed:"
    foreach ($error in $result.Errors) {
        Write-Host "  - $error"
    }

    # Check field-specific errors
    foreach ($fieldName in $result.FieldErrors.Keys) {
        Write-Host "  Field '$fieldName':"
        foreach ($error in $result.FieldErrors[$fieldName]) {
            Write-Host "    - $error"
        }
    }
}

# Check data types
Write-Host "text type: $($task.text.GetType().Name)"
Write-Host "priority type: $($task.priority.GetType().Name)"
```

### Debug Techniques

#### Enable Verbose Logging

```powershell
# In ApplicationBootstrapper
$VerbosePreference = 'Continue'
Start-PmcApplication -StartScreen 'TaskList' -Verbose
```

#### Inspect Store State

```powershell
$store = [TaskStore]::GetInstance()

# Get statistics
$stats = $store.GetStatistics()
Write-Host "Tasks: $($stats.taskCount)"
Write-Host "Projects: $($stats.projectCount)"
Write-Host "Last loaded: $($stats.lastLoaded)"
Write-Host "Last saved: $($stats.lastSaved)"

# Check specific data
$tasks = $store.GetAllTasks()
Write-Host "First task: $($tasks[0] | ConvertTo-Json)"
```

#### Check Navigation State

```powershell
$nav = [NavigationManager]::new($app)

# Print statistics
$stats = $nav.GetStatistics()
Write-Host "Current screen: $($stats.currentScreen)"
Write-Host "History depth: $($stats.historyDepth)"
Write-Host "Can go back: $($stats.canGoBack)"

# Print history
$nav.PrintHistory()
```

#### Test Component Isolation

```powershell
# Test ValidationHelper in isolation
. "$PSScriptRoot/helpers/ValidationHelper.ps1"
$result = Test-TaskValid @{ text = 'Test'; priority = 3 }
Write-Host "Valid: $($result.IsValid)"

# Test ScreenRegistry in isolation
. "$PSScriptRoot/infrastructure/ScreenRegistry.ps1"
[ScreenRegistry]::Register('Test', [object], 'Other', 'Test')
Write-Host "Registered: $([ScreenRegistry]::IsRegistered('Test'))"
```

### Performance Profiling

#### Measure Render Time

```powershell
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$screen.Render()
$stopwatch.Stop()
Write-Host "Render time: $($stopwatch.ElapsedMilliseconds)ms"
```

#### Measure Store Operations

```powershell
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$tasks = $store.GetAllTasks()
$stopwatch.Stop()
Write-Host "GetAllTasks time: $($stopwatch.ElapsedMilliseconds)ms"

$stopwatch.Restart()
$store.AddTask(@{ text = 'Test' })
$stopwatch.Stop()
Write-Host "AddTask time: $($stopwatch.ElapsedMilliseconds)ms"
```

#### Profile Navigation

```powershell
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$nav.NavigateTo('TaskList')
$stopwatch.Stop()
Write-Host "Navigation time: $($stopwatch.ElapsedMilliseconds)ms"
```

---

## Conclusion

The PMC TUI Base Architecture provides a complete, production-ready foundation for building terminal-based user interfaces. By following this guide and using the provided base classes, you can rapidly develop new screens with minimal boilerplate code while maintaining consistency and quality.

**Key Takeaways**:
- Use TaskStore for centralized state management
- Inherit from StandardListScreen, StandardFormScreen, or StandardDashboard
- Subscribe to store events for reactive UI updates
- Register screens in ScreenRegistry
- Use NavigationManager for screen transitions
- Register keyboard shortcuts in KeyboardManager
- Always validate data before saving
- Implement OnDispose for proper cleanup
- Test components in isolation

**Next Steps**:
1. Run the test suite to verify your setup
2. Create your first screen using a base class
3. Register the screen and shortcuts
4. Test navigation and data persistence
5. Expand with additional screens as needed

For questions or issues, consult the test files for working examples and the API reference for detailed method signatures.

---

**Document Version:** 1.0
**Last Updated:** 2025-11-07
**Status:** Complete and Tested
