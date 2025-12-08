# Service Integration Reference

## Overview
Screens interact with services for data persistence and business logic. This document describes the contracts and patterns for service integration.

---

## TaskStore Service

**Location**: `services/TaskStore.ps1`

**Purpose**: Central data store for all task-related operations

### Responsibilities
- Load tasks from JSON file
- Maintain in-memory task collection
- Provide CRUD operations
- Save tasks to disk
- Manage task relationships (dependencies, notes, time entries)

### Key Methods

#### Task Operations
```powershell
# Retrieve tasks
[array]GetAllTasks()
[object]GetTaskById([string]$id)
[array]GetTasksByProject([string]$projectId)
[array]GetTasksByStatus([string]$status)

# Mutate tasks
[void]AddTask([object]$task)
[void]UpdateTask([object]$task)
[void]DeleteTask([string]$id)

# Persistence
[void]Save()  # CRITICAL: Must call after any mutation
[void]Load()  # Called automatically on init
```

#### Project Operations
```powershell
[array]GetProjects()
[object]GetProjectById([string]$id)
[void]AddProject([object]$project)
[void]UpdateProject([object]$project)
```

#### Dependency Operations
```powershell
[void]AddDependency([string]$taskId, [string]$dependsOnId)
[void]RemoveDependency([string]$taskId, [string]$dependsOnId)
[array]GetTaskDependencies([string]$taskId)
```

#### Notes Operations
```powershell
[array]GetTaskNotes([string]$taskId)
[void]AddNote([string]$taskId, [object]$note)
[void]UpdateNote([string]$taskId, [string]$noteId, [object]$note)
[void]DeleteNote([string]$taskId, [string]$noteId)
```

#### Time Tracking Operations
```powershell
[array]GetTimeEntries([string]$taskId)
[void]AddTimeEntry([string]$taskId, [object]$entry)
[void]DeleteTimeEntry([string]$taskId, [string]$entryId)
[object]GetActiveTimer()
[void]StartTimer([string]$taskId)
[void]StopTimer()
```

### Usage Pattern

```powershell
class MyScreen : PmcScreen {
    [void]SomeOperation() {
        # 1. Access via app instance
        $taskStore = $this.app.taskStore

        # 2. Read data
        $task = $taskStore.GetTaskById($this.State.TaskId)

        # 3. Modify
        $task.Status = "Done"

        # 4. Update
        $taskStore.UpdateTask($task)

        # 5. MUST SAVE
        $taskStore.Save()
    }
}
```

### Critical Rules

1. **Always call Save()** after mutations
   ```powershell
   $taskStore.UpdateTask($task)
   $taskStore.Save()  # REQUIRED
   ```

2. **Access via app instance**
   ```powershell
   # RIGHT
   $this.app.taskStore.GetAllTasks()

   # WRONG - don't create new instances
   $store = [TaskStore]::new()
   ```

3. **Reload data in Initialize()**
   ```powershell
   [void]Initialize() {
       parent::Initialize()
       $this.tasks = $this.app.taskStore.GetAllTasks()
       # Data is fresh every time screen shown
   }
   ```

### Task Object Structure

```powershell
@{
    Id = [string]        # Unique identifier (GUID)
    Title = [string]     # Task title
    Status = [string]    # "Todo", "InProgress", "Done", etc.
    Priority = [int]     # 1-5
    ProjectId = [string] # Associated project ID
    Description = [string]
    DueDate = [datetime]
    CreatedDate = [datetime]
    CompletedDate = [datetime]
    Tags = [array]       # Array of strings
    Dependencies = [array]  # Array of task IDs
    Notes = [array]      # Array of note objects
    TimeEntries = [array] # Array of time entry objects
    # ... other fields
}
```

---

## PreferencesService

**Location**: `services/PreferencesService.ps1`

**Purpose**: Store and retrieve user preferences

### Key Methods

```powershell
[object]GetPreference([string]$key, [object]$defaultValue)
[void]SetPreference([string]$key, [object]$value)
[void]Save()
[void]Load()
```

### Common Preferences

- `LastViewedProject` - Recently selected project
- `DefaultTaskStatus` - Default status for new tasks
- `ListSortOrder` - Sort preference for task lists
- `FilterSettings` - Saved filter configurations
- `ViewMode` - Current view mode (list, kanban, etc.)

### Usage Pattern

```powershell
class MyScreen : PmcScreen {
    [void]Initialize() {
        parent::Initialize()

        # Get preference with default
        $sortOrder = $this.app.preferencesService.GetPreference("SortOrder", "Title")

        # Apply preference
        $this.sortBy = $sortOrder
    }

    [void]OnSortChange($newSort) {
        # Save preference
        $this.app.preferencesService.SetPreference("SortOrder", $newSort)
        $this.app.preferencesService.Save()
    }
}
```

---

## ExcelComReader

**Location**: `services/ExcelComReader.ps1`

**Purpose**: Import tasks from Excel files via COM interop

### Key Methods

```powershell
[void]OpenWorkbook([string]$path)
[array]GetWorksheets()
[array]ReadRange([string]$worksheetName, [string]$range)
[void]Close()
```

### Usage Pattern

```powershell
class ExcelImportScreen : PmcScreen {
    [void]ImportTasks([string]$filePath) {
        $excel = $this.app.excelReader

        try {
            $excel.OpenWorkbook($filePath)
            $sheets = $excel.GetWorksheets()

            # Read data
            $data = $excel.ReadRange($sheets[0], "A1:E100")

            # Convert to tasks
            foreach ($row in $data) {
                $task = @{
                    Title = $row[0]
                    Description = $row[1]
                    # ... map columns
                }
                $this.app.taskStore.AddTask($task)
            }

            $this.app.taskStore.Save()
        }
        finally {
            $excel.Close()
        }
    }
}
```

### Important Notes

- COM interop requires Excel installed
- Always close workbook in `finally` block
- Handle COM exceptions gracefully

---

## Application State

**Location**: `PmcApplication.ps1`

The `$this.app` reference provides access to:

```powershell
$this.app.taskStore          # TaskStore instance
$this.app.preferencesService # PreferencesService instance
$this.app.excelReader        # ExcelComReader instance
$this.app.currentScreen      # Currently displayed screen
$this.app.screenStack        # Navigation stack
$this.app.isRunning          # Application running state
```

### Navigation via App

```powershell
# Navigate to new screen
$nextScreen = [TaskDetailScreen]::new($this.app)
$this.NavigateTo($nextScreen)  # Uses app's navigation

# Navigate back
$this.NavigateBack()  # Uses app's screen stack
```

---

## Screen-to-Screen Communication

### Via State Property
```powershell
# Source screen
$detailScreen = [TaskDetailScreen]::new($this.app)
$detailScreen.State.TaskId = $selectedTaskId
$detailScreen.State.Mode = "edit"
$this.NavigateTo($detailScreen)

# Target screen
[void]Initialize() {
    parent::Initialize()
    $taskId = $this.State.TaskId
    $mode = $this.State.Mode
    $this.LoadTask($taskId)
}
```

### Via Service State
```powershell
# Source screen saves to preferences
$this.app.preferencesService.SetPreference("SelectedTask", $taskId)
$this.app.preferencesService.Save()

# Target screen reads from preferences
[void]Initialize() {
    parent::Initialize()
    $taskId = $this.app.preferencesService.GetPreference("SelectedTask", $null)
    if ($taskId) {
        $this.LoadTask($taskId)
    }
}
```

---

## Service Initialization

Services are initialized in `PmcApplication`:

```powershell
# In PmcApplication.ps1
[void]Initialize() {
    $this.taskStore = [TaskStore]::new()
    $this.taskStore.Load()

    $this.preferencesService = [PreferencesService]::new()
    $this.preferencesService.Load()

    $this.excelReader = [ExcelComReader]::new()
}
```

Screens should **never** create service instances directly.

---

## Common Integration Patterns

### Pattern: List Screen with Data Reload

```powershell
class TaskListScreen : StandardListScreen {
    [void]Initialize() {
        parent::Initialize()
        $this.LoadData()
    }

    [void]LoadData() {
        $tasks = $this.app.taskStore.GetAllTasks()
        $this.items = $tasks | ForEach-Object {
            @{
                Id = $_.Id
                Display = "$($_.Title) [$($_.Status)]"
                Data = $_
            }
        }
    }
}
```

### Pattern: Form Screen with Save

```powershell
class TaskEditFormScreen : PmcScreen {
    [void]Initialize() {
        parent::Initialize()
        $taskId = $this.State.TaskId
        $task = $this.app.taskStore.GetTaskById($taskId)
        $this.textInput.Value = $task.Title
    }

    [void]OnSubmit() {
        $taskId = $this.State.TaskId
        $task = $this.app.taskStore.GetTaskById($taskId)
        $task.Title = $this.textInput.Value

        $this.app.taskStore.UpdateTask($task)
        $this.app.taskStore.Save()  # CRITICAL

        $this.NavigateBack()
    }
}
```

### Pattern: Preference-Driven Behavior

```powershell
class ConfigurableListScreen : StandardListScreen {
    [void]Initialize() {
        parent::Initialize()

        # Load preference
        $sortOrder = $this.app.preferencesService.GetPreference("TaskSortOrder", "Title")

        # Apply to data loading
        $this.LoadData($sortOrder)
    }

    [void]OnSortChange($newOrder) {
        # Save preference
        $this.app.preferencesService.SetPreference("TaskSortOrder", $newOrder)
        $this.app.preferencesService.Save()

        # Reload with new sort
        $this.LoadData($newOrder)
    }
}
```

---

## Anti-Patterns

### ❌ Forgetting to Save
```powershell
$task.Status = "Done"
$this.app.taskStore.UpdateTask($task)
# Missing Save() - changes lost
```

### ❌ Creating Service Instances
```powershell
# WRONG
$store = [TaskStore]::new()
$store.Load()

# RIGHT
$this.app.taskStore.GetAllTasks()
```

### ❌ Not Reloading Data
```powershell
[void]Initialize() {
    parent::Initialize()
    # Missing data reload - shows stale data
}
```

### ❌ Direct File Access
```powershell
# WRONG - bypassing service
$tasks = Get-Content "tasks.json" | ConvertFrom-Json

# RIGHT - using service
$tasks = $this.app.taskStore.GetAllTasks()
```

---

## To Be Documented
- Service error handling patterns
- Transaction/rollback patterns (if any)
- Service extension points
- Testing with mock services
