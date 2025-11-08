# TaskStore.ps1 - Centralized Observable Data Store for PMC TUI
#
# SINGLETON pattern - provides centralized data access with:
# - Load data once from Get-PmcAllData
# - In-memory caching (tasks, projects, time logs)
# - CRUD operations (Add, Update, Delete, Get)
# - Event-driven updates (OnTaskAdded, OnTaskUpdated, OnTaskDeleted, etc.)
# - Auto-persistence via Set-PmcAllData
# - Thread-safe operations
# - Validation and error handling
# - Rollback on save failure
#
# Usage:
#   $store = [TaskStore]::GetInstance()
#
#   # CRUD operations
#   $task = $store.GetTask($id)
#   $allTasks = $store.GetAllTasks()
#   $store.AddTask($task)        # Fires OnTaskAdded, persists
#   $store.UpdateTask($id, $changes)  # Fires OnTaskUpdated, persists
#   $store.DeleteTask($id)       # Fires OnTaskDeleted, persists
#
#   # Subscribe to changes
#   $store.OnTaskAdded = { param($task) $this.RefreshUI() }
#   $store.OnTaskUpdated = { param($task) $this.RefreshUI() }
#   $store.OnTaskDeleted = { param($id) $this.RefreshUI() }
#
# The store automatically persists changes to disk and provides
# rollback capabilities if persistence fails.

using namespace System
using namespace System.Collections.Generic
using namespace System.Threading

Set-StrictMode -Version Latest

<#
.SYNOPSIS
Centralized observable data store for PMC data with event-driven updates

.DESCRIPTION
TaskStore provides:
- Singleton instance for centralized data access
- In-memory caching of tasks, projects, time logs
- CRUD operations with automatic persistence
- Event callbacks for data changes (OnTaskAdded, OnTaskUpdated, etc.)
- Validation before persistence
- Rollback on save failure
- Thread-safe operations with locking
- Query methods (filtering, searching)
- Batch operations for performance

.EXAMPLE
$store = [TaskStore]::GetInstance()
$store.OnTaskAdded = { param($task) Write-Host "New task: $($task.text)" }
$store.AddTask(@{ text='Buy milk'; project='personal'; priority=3 })
#>
class TaskStore {
    # === Singleton Instance ===
    static hidden [TaskStore]$_instance = $null
    static hidden [object]$_instanceLock = [object]::new()

    # === Data Storage ===
    hidden [hashtable]$_data = @{
        tasks = @()
        projects = @()
        timelogs = @()
        settings = @{}
        metadata = @{
            lastLoaded = $null
            lastSaved = $null
            version = "1.0"
        }
    }

    # === Backup for Rollback ===
    hidden [hashtable]$_dataBackup = $null

    # === Thread Safety ===
    hidden [object]$_dataLock = [object]::new()

    # === Event Callbacks - Tasks ===
    [scriptblock]$OnTaskAdded = {}
    [scriptblock]$OnTaskUpdated = {}
    [scriptblock]$OnTaskDeleted = {}
    [scriptblock]$OnTasksChanged = {}  # Fired after any task change

    # === Event Callbacks - Projects ===
    [scriptblock]$OnProjectAdded = {}
    [scriptblock]$OnProjectUpdated = {}
    [scriptblock]$OnProjectDeleted = {}
    [scriptblock]$OnProjectsChanged = {}

    # === Event Callbacks - Time Logs ===
    [scriptblock]$OnTimeLogAdded = {}
    [scriptblock]$OnTimeLogUpdated = {}
    [scriptblock]$OnTimeLogDeleted = {}
    [scriptblock]$OnTimeLogsChanged = {}

    # === Event Callbacks - Global ===
    [scriptblock]$OnDataChanged = {}   # Fired after any data change
    [scriptblock]$OnLoadError = {}     # Fired when load fails
    [scriptblock]$OnSaveError = {}     # Fired when save fails

    # === State Flags ===
    [bool]$IsLoaded = $false
    [bool]$IsSaving = $false
    [string]$LastError = ""

    # === Validation Rules ===
    hidden [hashtable]$_validationRules = @{
        task = @{
            required = @('text')
            types = @{
                text = 'string'
                project = 'string'
                priority = 'int'
                due = 'datetime'
                tags = 'array'
                completed = 'bool'
            }
        }
        project = @{
            required = @('name')
            types = @{
                name = 'string'
                description = 'string'
                status = 'string'
            }
        }
        timelog = @{
            required = @('taskId', 'duration')
            types = @{
                taskId = 'string'
                duration = 'int'
                timestamp = 'datetime'
            }
        }
    }

    # === Constructor (Private) ===
    TaskStore() {
        # Private constructor for singleton
        $this._InitializeStore()
    }

    # === Singleton Pattern ===

    <#
    .SYNOPSIS
    Get the singleton instance of TaskStore

    .OUTPUTS
    TaskStore singleton instance
    #>
    static [TaskStore] GetInstance() {
        if ($null -eq [TaskStore]::_instance) {
            [Monitor]::Enter([TaskStore]::_instanceLock)
            try {
                if ($null -eq [TaskStore]::_instance) {
                    [TaskStore]::_instance = [TaskStore]::new()
                    [TaskStore]::_instance.LoadData()
                }
            }
            finally {
                [Monitor]::Exit([TaskStore]::_instanceLock)
            }
        }

        return [TaskStore]::_instance
    }

    <#
    .SYNOPSIS
    Reset the singleton instance (for testing)
    #>
    static [void] ResetInstance() {
        [Monitor]::Enter([TaskStore]::_instanceLock)
        try {
            [TaskStore]::_instance = $null
        }
        finally {
            [Monitor]::Exit([TaskStore]::_instanceLock)
        }
    }

    # === Data Loading ===

    <#
    .SYNOPSIS
    Initialize the store
    #>
    hidden [void] _InitializeStore() {
        $this._data.tasks = [System.Collections.ArrayList]::new()
        $this._data.projects = [System.Collections.ArrayList]::new()
        $this._data.timelogs = [System.Collections.ArrayList]::new()
        $this.IsLoaded = $false
    }

    <#
    .SYNOPSIS
    Load data from Get-PmcAllData

    .OUTPUTS
    True if load succeeded, False otherwise
    #>
    [bool] LoadData() {
        Write-PmcTuiLog "TaskStore.LoadData: Starting" "DEBUG"
        [Monitor]::Enter($this._dataLock)
        try {
            try {
                # Call Get-PmcAllData to load from disk
                Write-PmcTuiLog "TaskStore.LoadData: Calling Get-PmcAllData" "DEBUG"
                $pmcData = Get-PmcAllData
                Write-PmcTuiLog "TaskStore.LoadData: Get-PmcAllData returned, has tasks: $($null -ne $pmcData.tasks), count: $($pmcData.tasks.Count)" "DEBUG"

                if ($null -eq $pmcData) {
                    $this.LastError = "Get-PmcAllData returned null"
                    Write-PmcTuiLog "TaskStore.LoadData: ERROR - Get-PmcAllData returned null" "ERROR"
                    $this._InvokeCallback($this.OnLoadError, $this.LastError)
                    return $false
                }

                # Extract data sections
                if ($pmcData.tasks) {
                    $this._data.tasks = [System.Collections.ArrayList]::new()
                    foreach ($task in $pmcData.tasks) {
                        [void]$this._data.tasks.Add($task)
                    }
                    Write-PmcTuiLog "TaskStore.LoadData: Loaded $($this._data.tasks.Count) tasks" "DEBUG"
                } else {
                    $this._data.tasks = [System.Collections.ArrayList]::new()
                    Write-PmcTuiLog "TaskStore.LoadData: No tasks in data, initialized empty list" "DEBUG"
                }

                if ($pmcData.projects) {
                    $this._data.projects = [System.Collections.ArrayList]::new()
                    foreach ($project in $pmcData.projects) {
                        [void]$this._data.projects.Add($project)
                    }
                } else {
                    $this._data.projects = [System.Collections.ArrayList]::new()
                }

                if ($pmcData.timelogs) {
                    $this._data.timelogs = [System.Collections.ArrayList]::new()
                    foreach ($log in $pmcData.timelogs) {
                        [void]$this._data.timelogs.Add($log)
                    }
                } else {
                    $this._data.timelogs = [System.Collections.ArrayList]::new()
                }

                if ($pmcData.settings) {
                    $this._data.settings = $pmcData.settings
                } else {
                    $this._data.settings = @{}
                }

                $this._data.metadata.lastLoaded = Get-Date
                $this.IsLoaded = $true
                $this.LastError = ""

                return $true
            }
            catch {
                $this.LastError = "Failed to load data: $($_.Exception.Message)"
                Write-PmcTuiLog "TaskStore.LoadData: EXCEPTION: $($_.Exception.Message)" "ERROR"
                Write-PmcTuiLog "TaskStore.LoadData: Stack trace: $($_.ScriptStackTrace)" "ERROR"
                $this._InvokeCallback($this.OnLoadError, $this.LastError)
                return $false
            }
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Reload data from disk (discards in-memory changes)

    .OUTPUTS
    True if reload succeeded, False otherwise
    #>
    [bool] ReloadData() {
        return $this.LoadData()
    }

    # === Data Persistence ===

    <#
    .SYNOPSIS
    Save all data to disk via Set-PmcAllData

    .OUTPUTS
    True if save succeeded, False otherwise
    #>
    [bool] SaveData() {
        if ($this.IsSaving) {
            $this.LastError = "Save already in progress"
            Write-PmcTuiLog "SaveData: Already saving, returning false" "ERROR"
            return $false
        }

        [Monitor]::Enter($this._dataLock)
        try {
            $this.IsSaving = $true

            try {
                # Create backup before save
                $this._CreateBackup()

                # Build data structure for Set-PmcAllData
                $dataToSave = @{
                    tasks = $this._data.tasks.ToArray()
                    projects = $this._data.projects.ToArray()
                    timelogs = $this._data.timelogs.ToArray()
                    settings = $this._data.settings
                }

                Write-PmcTuiLog "SaveData: Calling Set-PmcAllData with $($dataToSave.tasks.Count) tasks" "DEBUG"
                # Call Set-PmcAllData to persist
                Set-PmcAllData -Data $dataToSave

                $this._data.metadata.lastSaved = Get-Date
                $this.LastError = ""

                # Clear backup on successful save
                $this._dataBackup = $null

                Write-PmcTuiLog "SaveData: Success" "DEBUG"
                return $true
            }
            catch {
                $this.LastError = "Failed to save data: $($_.Exception.Message)"
                Write-PmcTuiLog "SaveData: Exception: $($_.Exception.Message)" "ERROR"
                Write-PmcTuiLog "SaveData: Stack trace: $($_.ScriptStackTrace)" "ERROR"
                $this._InvokeCallback($this.OnSaveError, $this.LastError)

                # Rollback to backup
                $this._Rollback()

                return $false
            }
        }
        finally {
            $this.IsSaving = $false
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Create backup of current data for rollback
    #>
    hidden [void] _CreateBackup() {
        $this._dataBackup = @{
            tasks = [System.Collections.ArrayList]$this._data.tasks.Clone()
            projects = [System.Collections.ArrayList]$this._data.projects.Clone()
            timelogs = [System.Collections.ArrayList]$this._data.timelogs.Clone()
            settings = $this._data.settings.Clone()
        }
    }

    <#
    .SYNOPSIS
    Rollback to backup data
    #>
    hidden [void] _Rollback() {
        if ($null -ne $this._dataBackup) {
            $this._data.tasks = $this._dataBackup.tasks
            $this._data.projects = $this._dataBackup.projects
            $this._data.timelogs = $this._dataBackup.timelogs
            $this._data.settings = $this._dataBackup.settings
            $this._dataBackup = $null
        }
    }

    # === Task CRUD Operations ===

    <#
    .SYNOPSIS
    Get all tasks

    .OUTPUTS
    Array of task hashtables
    #>
    [array] GetAllTasks() {
        [Monitor]::Enter($this._dataLock)
        try {
            $tasks = $this._data.tasks.ToArray()
            Write-PmcTuiLog "GetAllTasks: Returning $($tasks.Count) tasks" "DEBUG"
            return $tasks
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Get task by ID

    .PARAMETER id
    Task ID

    .OUTPUTS
    Task hashtable or $null if not found
    #>
    [hashtable] GetTask([string]$id) {
        [Monitor]::Enter($this._dataLock)
        try {
            $task = $this._data.tasks | Where-Object { $_.id -eq $id } | Select-Object -First 1
            return $task
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Add a new task

    .PARAMETER task
    Task hashtable (must include 'text' field minimum)

    .OUTPUTS
    True if add succeeded, False otherwise
    #>
    [bool] AddTask([hashtable]$task) {
        Write-PmcTuiLog "AddTask: Starting with task keys: $($task.Keys -join ', ')" "DEBUG"
        [Monitor]::Enter($this._dataLock)
        try {
            # Validate task
            $validationErrors = $this._ValidateEntity($task, 'task')
            if ($validationErrors.Count -gt 0) {
                $this.LastError = "Task validation failed: $($validationErrors -join ', ')"
                Write-PmcTuiLog "AddTask: Validation FAILED: $($validationErrors -join ', ')" "ERROR"
                return $false
            }
            Write-PmcTuiLog "AddTask: Validation passed" "DEBUG"

            # Generate ID if not present
            if (-not $task.ContainsKey('id') -or [string]::IsNullOrEmpty($task.id)) {
                $task.id = [Guid]::NewGuid().ToString()
            }

            # Add default status fields if not present
            if (-not $task.ContainsKey('completed')) {
                $task.completed = $false
            }
            if (-not $task.ContainsKey('status')) {
                $task.status = 'pending'
            }

            # Add timestamps
            $now = Get-Date
            if (-not $task.ContainsKey('created')) {
                $task.created = $now
            }
            $task.modified = $now

            # Add to collection
            $this._data.tasks.Add($task)
            Write-PmcTuiLog "AddTask: Added to collection, total tasks=$($this._data.tasks.Count)" "DEBUG"

            # Persist
            if (-not $this.SaveData()) {
                Write-PmcTuiLog "AddTask: SaveData FAILED" "ERROR"
                return $false
            }
            Write-PmcTuiLog "AddTask: SaveData succeeded" "DEBUG"

            # Fire events
            $this._InvokeCallback($this.OnTaskAdded, $task)
            $this._InvokeCallback($this.OnTasksChanged, $this._data.tasks.ToArray())
            $this._InvokeCallback($this.OnDataChanged, $null)

            Write-PmcTuiLog "AddTask: Success" "DEBUG"
            return $true
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Update an existing task

    .PARAMETER id
    Task ID

    .PARAMETER changes
    Hashtable of fields to update

    .OUTPUTS
    True if update succeeded, False otherwise
    #>
    [bool] UpdateTask([string]$id, [hashtable]$changes) {
        [Monitor]::Enter($this._dataLock)
        try {
            # Find task
            $task = $this._data.tasks | Where-Object { $_.id -eq $id } | Select-Object -First 1

            if ($null -eq $task) {
                $this.LastError = "Task not found: $id"
                return $false
            }

            # Apply changes
            foreach ($key in $changes.Keys) {
                $task[$key] = $changes[$key]
            }

            # Update modified timestamp
            $task.modified = Get-Date

            # Validate updated task
            $validationErrors = $this._ValidateEntity($task, 'task')
            if ($validationErrors.Count -gt 0) {
                $this.LastError = "Task validation failed: $($validationErrors -join ', ')"
                $this._Rollback()
                return $false
            }

            # Persist
            if (-not $this.SaveData()) {
                return $false
            }

            # Fire events
            $this._InvokeCallback($this.OnTaskUpdated, $task)
            $this._InvokeCallback($this.OnTasksChanged, $this._data.tasks.ToArray())
            $this._InvokeCallback($this.OnDataChanged, $null)

            return $true
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Delete a task by ID

    .PARAMETER id
    Task ID

    .OUTPUTS
    True if delete succeeded, False otherwise
    #>
    [bool] DeleteTask([string]$id) {
        [Monitor]::Enter($this._dataLock)
        try {
            # Find task index
            $index = -1
            for ($i = 0; $i -lt $this._data.tasks.Count; $i++) {
                if ($this._data.tasks[$i].id -eq $id) {
                    $index = $i
                    break
                }
            }

            if ($index -eq -1) {
                $this.LastError = "Task not found: $id"
                return $false
            }

            # Remove task
            $this._data.tasks.RemoveAt($index)

            # Persist
            if (-not $this.SaveData()) {
                return $false
            }

            # Fire events
            $this._InvokeCallback($this.OnTaskDeleted, $id)
            $this._InvokeCallback($this.OnTasksChanged, $this._data.tasks.ToArray())
            $this._InvokeCallback($this.OnDataChanged, $null)

            return $true
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    # === Project CRUD Operations ===

    <#
    .SYNOPSIS
    Get all projects

    .OUTPUTS
    Array of project hashtables
    #>
    [array] GetAllProjects() {
        [Monitor]::Enter($this._dataLock)
        try {
            return $this._data.projects.ToArray()
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Get project by name

    .PARAMETER name
    Project name

    .OUTPUTS
    Project hashtable or $null if not found
    #>
    [hashtable] GetProject([string]$name) {
        [Monitor]::Enter($this._dataLock)
        try {
            $project = $this._data.projects | Where-Object { $_.name -eq $name } | Select-Object -First 1
            return $project
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Add a new project

    .PARAMETER project
    Project hashtable (must include 'name' field minimum)

    .OUTPUTS
    True if add succeeded, False otherwise
    #>
    [bool] AddProject([hashtable]$project) {
        [Monitor]::Enter($this._dataLock)
        try {
            # Validate project
            $validationErrors = $this._ValidateEntity($project, 'project')
            if ($validationErrors.Count -gt 0) {
                $this.LastError = "Project validation failed: $($validationErrors -join ', ')"
                return $false
            }

            # Check for duplicate name
            $existing = $this._data.projects | Where-Object { $_.name -eq $project.name }
            if ($existing) {
                $this.LastError = "Project already exists: $($project.name)"
                return $false
            }

            # Add timestamps
            $now = Get-Date
            if (-not $project.ContainsKey('created')) {
                $project.created = $now
            }
            $project.modified = $now

            # Add to collection
            $this._data.projects.Add($project)

            # Persist
            if (-not $this.SaveData()) {
                return $false
            }

            # Fire events
            $this._InvokeCallback($this.OnProjectAdded, $project)
            $this._InvokeCallback($this.OnProjectsChanged, $this._data.projects.ToArray())
            $this._InvokeCallback($this.OnDataChanged, $null)

            return $true
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Update an existing project

    .PARAMETER name
    Project name

    .PARAMETER changes
    Hashtable of fields to update

    .OUTPUTS
    True if update succeeded, False otherwise
    #>
    [bool] UpdateProject([string]$name, [hashtable]$changes) {
        [Monitor]::Enter($this._dataLock)
        try {
            # Find project
            $project = $this._data.projects | Where-Object { $_.name -eq $name } | Select-Object -First 1

            if ($null -eq $project) {
                $this.LastError = "Project not found: $name"
                return $false
            }

            # Apply changes
            foreach ($key in $changes.Keys) {
                $project[$key] = $changes[$key]
            }

            # Update modified timestamp
            $project.modified = Get-Date

            # Validate updated project
            $validationErrors = $this._ValidateEntity($project, 'project')
            if ($validationErrors.Count -gt 0) {
                $this.LastError = "Project validation failed: $($validationErrors -join ', ')"
                $this._Rollback()
                return $false
            }

            # Persist
            if (-not $this.SaveData()) {
                return $false
            }

            # Fire events
            $this._InvokeCallback($this.OnProjectUpdated, $project)
            $this._InvokeCallback($this.OnProjectsChanged, $this._data.projects.ToArray())
            $this._InvokeCallback($this.OnDataChanged, $null)

            return $true
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Delete a project by name

    .PARAMETER name
    Project name

    .OUTPUTS
    True if delete succeeded, False otherwise
    #>
    [bool] DeleteProject([string]$name) {
        [Monitor]::Enter($this._dataLock)
        try {
            # Find project index
            $index = -1
            for ($i = 0; $i -lt $this._data.projects.Count; $i++) {
                if ($this._data.projects[$i].name -eq $name) {
                    $index = $i
                    break
                }
            }

            if ($index -eq -1) {
                $this.LastError = "Project not found: $name"
                return $false
            }

            # Remove project
            $this._data.projects.RemoveAt($index)

            # Persist
            if (-not $this.SaveData()) {
                return $false
            }

            # Fire events
            $this._InvokeCallback($this.OnProjectDeleted, $name)
            $this._InvokeCallback($this.OnProjectsChanged, $this._data.projects.ToArray())
            $this._InvokeCallback($this.OnDataChanged, $null)

            return $true
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    # === Time Log CRUD Operations ===

    <#
    .SYNOPSIS
    Get all time logs

    .OUTPUTS
    Array of time log hashtables
    #>
    [array] GetAllTimeLogs() {
        [Monitor]::Enter($this._dataLock)
        try {
            return $this._data.timelogs.ToArray()
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Get time logs for a specific task

    .PARAMETER taskId
    Task ID

    .OUTPUTS
    Array of time log hashtables
    #>
    [array] GetTimeLogsForTask([string]$taskId) {
        [Monitor]::Enter($this._dataLock)
        try {
            $logs = $this._data.timelogs | Where-Object { $_.taskId -eq $taskId }
            return if ($logs) { $logs } else { @() }
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Add a new time log

    .PARAMETER timelog
    Time log hashtable (must include 'taskId' and 'duration')

    .OUTPUTS
    True if add succeeded, False otherwise
    #>
    [bool] AddTimeLog([hashtable]$timelog) {
        [Monitor]::Enter($this._dataLock)
        try {
            # Validate time log
            $validationErrors = $this._ValidateEntity($timelog, 'timelog')
            if ($validationErrors.Count -gt 0) {
                $this.LastError = "Time log validation failed: $($validationErrors -join ', ')"
                return $false
            }

            # Generate ID if not present
            if (-not $timelog.ContainsKey('id') -or [string]::IsNullOrEmpty($timelog.id)) {
                $timelog.id = [Guid]::NewGuid().ToString()
            }

            # Add timestamp if not present
            if (-not $timelog.ContainsKey('timestamp')) {
                $timelog.timestamp = Get-Date
            }

            # Add to collection
            $this._data.timelogs.Add($timelog)

            # Persist
            if (-not $this.SaveData()) {
                return $false
            }

            # Fire events
            $this._InvokeCallback($this.OnTimeLogAdded, $timelog)
            $this._InvokeCallback($this.OnTimeLogsChanged, $this._data.timelogs.ToArray())
            $this._InvokeCallback($this.OnDataChanged, $null)

            return $true
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Delete a time log by ID

    .PARAMETER id
    Time log ID

    .OUTPUTS
    True if delete succeeded, False otherwise
    #>
    [bool] DeleteTimeLog([string]$id) {
        [Monitor]::Enter($this._dataLock)
        try {
            # Find time log index
            $index = -1
            for ($i = 0; $i -lt $this._data.timelogs.Count; $i++) {
                if ($this._data.timelogs[$i].id -eq $id) {
                    $index = $i
                    break
                }
            }

            if ($index -eq -1) {
                $this.LastError = "Time log not found: $id"
                return $false
            }

            # Remove time log
            $this._data.timelogs.RemoveAt($index)

            # Persist
            if (-not $this.SaveData()) {
                return $false
            }

            # Fire events
            $this._InvokeCallback($this.OnTimeLogDeleted, $id)
            $this._InvokeCallback($this.OnTimeLogsChanged, $this._data.timelogs.ToArray())
            $this._InvokeCallback($this.OnDataChanged, $null)

            return $true
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    # === Query Methods ===

    <#
    .SYNOPSIS
    Get tasks by project

    .PARAMETER projectName
    Project name

    .OUTPUTS
    Array of task hashtables
    #>
    [array] GetTasksByProject([string]$projectName) {
        [Monitor]::Enter($this._dataLock)
        try {
            $tasks = $this._data.tasks | Where-Object { $_.project -eq $projectName }
            return if ($tasks) { $tasks } else { @() }
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Search tasks by text

    .PARAMETER searchText
    Search query

    .OUTPUTS
    Array of task hashtables
    #>
    [array] SearchTasks([string]$searchText) {
        [Monitor]::Enter($this._dataLock)
        try {
            $searchLower = $searchText.ToLower()
            $tasks = $this._data.tasks | Where-Object {
                $_.text.ToLower().Contains($searchLower)
            }
            return if ($tasks) { $tasks } else { @() }
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Get tasks by priority range

    .PARAMETER minPriority
    Minimum priority (inclusive)

    .PARAMETER maxPriority
    Maximum priority (inclusive)

    .OUTPUTS
    Array of task hashtables
    #>
    [array] GetTasksByPriority([int]$minPriority, [int]$maxPriority) {
        [Monitor]::Enter($this._dataLock)
        try {
            $tasks = $this._data.tasks | Where-Object {
                $_.priority -ge $minPriority -and $_.priority -le $maxPriority
            }
            return if ($tasks) { $tasks } else { @() }
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    # === Validation ===

    <#
    .SYNOPSIS
    Validate an entity against rules

    .PARAMETER entity
    Entity hashtable to validate

    .PARAMETER entityType
    Entity type ('task', 'project', 'timelog')

    .OUTPUTS
    Array of validation error messages (empty if valid)
    #>
    hidden [string[]] _ValidateEntity([hashtable]$entity, [string]$entityType) {
        $errors = @()

        if (-not $this._validationRules.ContainsKey($entityType)) {
            $errors += "Unknown entity type: $entityType"
            return $errors
        }

        $rules = $this._validationRules[$entityType]

        # Check required fields
        foreach ($field in $rules.required) {
            if (-not $entity.ContainsKey($field) -or [string]::IsNullOrEmpty($entity[$field])) {
                $errors += "Required field missing: $field"
            }
        }

        # Check field types
        foreach ($field in $rules.types.Keys) {
            if ($entity.ContainsKey($field) -and $null -ne $entity[$field]) {
                $expectedType = $rules.types[$field]
                $value = $entity[$field]

                $isValid = switch ($expectedType) {
                    'string' { $value -is [string] }
                    'int' { $value -is [int] }
                    'bool' { $value -is [bool] }
                    'datetime' { $value -is [DateTime] }
                    'array' { $value -is [array] }
                    default { $true }
                }

                if (-not $isValid) {
                    $errors += "Field '$field' has invalid type (expected $expectedType)"
                }
            }
        }

        return $errors
    }

    # === Helper Methods ===

    <#
    .SYNOPSIS
    Invoke callback safely
    #>
    hidden [void] _InvokeCallback([scriptblock]$callback, $arg) {
        if ($null -ne $callback -and $callback -ne {}) {
            try {
                if ($null -ne $arg) {
                    # Use Invoke-Command with -ArgumentList to pass single arg without array wrapping
                    Invoke-Command -ScriptBlock $callback -ArgumentList $arg
                } else {
                    & $callback
                }
            }
            catch {
                # Log callback errors and rethrow so user sees them
                if (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue) {
                    Write-PmcTuiLog "TaskStore callback error: $($_.Exception.Message)" "ERROR"
                    Write-PmcTuiLog "Callback code: $($callback.ToString())" "ERROR"
                    Write-PmcTuiLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
                }
                throw  # Rethrow so it crashes and you see it
            }
        }
    }

    # === Batch Operations ===

    <#
    .SYNOPSIS
    Add multiple tasks in a single transaction

    .PARAMETER tasks
    Array of task hashtables

    .OUTPUTS
    Number of tasks successfully added
    #>
    [int] AddTasks([hashtable[]]$tasks) {
        [Monitor]::Enter($this._dataLock)
        try {
            $addedCount = 0
            $this._CreateBackup()

            foreach ($task in $tasks) {
                # Validate task
                $validationErrors = $this._ValidateEntity($task, 'task')
                if ($validationErrors.Count -gt 0) {
                    continue  # Skip invalid tasks
                }

                # Generate ID if not present
                if (-not $task.ContainsKey('id') -or [string]::IsNullOrEmpty($task.id)) {
                    $task.id = [Guid]::NewGuid().ToString()
                }

                # Add timestamps
                $now = Get-Date
                if (-not $task.ContainsKey('created')) {
                    $task.created = $now
                }
                $task.modified = $now

                # Add to collection
                $this._data.tasks.Add($task)
                $addedCount++
            }

            # Persist once for all tasks
            if ($addedCount -gt 0) {
                if ($this.SaveData()) {
                    # Fire events once
                    $this._InvokeCallback($this.OnTasksChanged, $this._data.tasks.ToArray())
                    $this._InvokeCallback($this.OnDataChanged, $null)
                } else {
                    return 0
                }
            }

            return $addedCount
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }

    <#
    .SYNOPSIS
    Get data statistics

    .OUTPUTS
    Hashtable with data statistics
    #>
    [hashtable] GetStatistics() {
        [Monitor]::Enter($this._dataLock)
        try {
            $stats = @{
                taskCount = $this._data.tasks.Count
                projectCount = $this._data.projects.Count
                timeLogCount = $this._data.timelogs.Count
                completedTaskCount = ($this._data.tasks | Where-Object { $_.completed }).Count
                pendingTaskCount = ($this._data.tasks | Where-Object { -not $_.completed }).Count
                lastLoaded = $this._data.metadata.lastLoaded
                lastSaved = $this._data.metadata.lastSaved
            }
            return $stats
        }
        finally {
            [Monitor]::Exit($this._dataLock)
        }
    }
}
