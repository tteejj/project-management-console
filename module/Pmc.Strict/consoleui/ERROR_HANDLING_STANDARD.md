# PMC TUI Error Handling Standard

## Overview

This document defines the standard error handling patterns for the PMC TUI codebase to ensure consistency, reliability, and maintainability.

## Error Handling Patterns

### Pattern 1: Data Operations (TaskStore, etc.)

**Use Case:** Database operations, file I/O, data validation

**Pattern:** Return boolean + LastError property

```powershell
[bool] AddTask([hashtable]$taskData) {
    try {
        # Validate input
        $validationErrors = $this._ValidateEntity('task', $taskData)
        if ($validationErrors.Count -gt 0) {
            $this.LastError = "Validation failed: $($validationErrors -join ', ')"
            return $false
        }

        # Perform operation
        $this._data.tasks += $taskData

        # Save changes
        if (-not $this.SaveData()) {
            $this.LastError = "Failed to save data"
            return $false
        }

        return $true
    }
    catch {
        $this.LastError = "Error adding task: $($_.Exception.Message)"
        Write-PmcTuiLog "AddTask failed: $_" "ERROR"
        return $false
    }
}
```

**Key Points:**
- Return `$true` on success, `$false` on failure
- Set `$this.LastError` with user-friendly message
- Log detailed errors to `Write-PmcTuiLog` with "ERROR" level
- Catch all exceptions to prevent application crashes
- Callers check return value: `if (-not $store.AddTask($data)) { ... }`

---

### Pattern 2: UI Operations (Screens, Widgets)

**Use Case:** User interactions, rendering, input handling

**Pattern:** Return void or object + Set status message

```powershell
[void] OnItemCreated([hashtable]$values) {
    try {
        $success = $this.Store.AddTask($values)
        if ($success) {
            $this.SetStatusMessage("Task added successfully", "success")
            $this.RefreshList()
        } else {
            $this.SetStatusMessage("Failed to add task: $($this.Store.LastError)", "error")
        }
    }
    catch {
        Write-PmcTuiLog "OnItemCreated exception: $_" "ERROR"
        $this.SetStatusMessage("Unexpected error: $($_.Exception.Message)", "error")
    }
}
```

**Key Points:**
- Don't return bool - use status messages for user feedback
- Always catch exceptions to prevent crashes
- Use `SetStatusMessage()` with type: "success", "error", "warning", "info"
- Log exceptions with `Write-PmcTuiLog`
- UI should never throw - always recover gracefully

---

### Pattern 3: Validation Functions

**Use Case:** Input validation, data checking

**Pattern:** Return array of error messages (empty = success)

```powershell
hidden [array] _ValidateEntity([string]$entityType, [hashtable]$data) {
    $errors = @()

    $schema = $this._schemas[$entityType]
    if (-not $schema) {
        $errors += "Unknown entity type: $entityType"
        return $errors
    }

    # Check required fields
    foreach ($field in $schema.required) {
        if (-not $data.ContainsKey($field) -or $null -eq $data[$field]) {
            $errors += "Missing required field: $field"
        }
    }

    # Check field types
    foreach ($field in $data.Keys) {
        if ($schema.types.ContainsKey($field)) {
            $expectedType = $schema.types[$field]
            if (-not $this._ValidateType($data[$field], $expectedType)) {
                $errors += "Invalid type for $field: expected $expectedType"
            }
        }
    }

    return $errors
}
```

**Key Points:**
- Return array of error strings
- Empty array means validation passed
- Caller checks: `$errors = $this._Validate($data); if ($errors.Count -gt 0) { ... }`
- Don't throw exceptions from validation
- Collect ALL errors, don't stop at first one

---

### Pattern 4: Critical Initialization

**Use Case:** Application startup, module loading, essential setup

**Pattern:** Throw exceptions + Try-catch at top level

```powershell
# In Start-PmcTUI.ps1 or constructors

try {
    # Critical initialization
    Import-Module "$PSScriptRoot/../Pmc.Strict.psd1" -Force -ErrorAction Stop
    Write-PmcTuiLog "PMC module loaded" "INFO"
} catch {
    Write-PmcTuiLog "Failed to load PMC module: $_" "ERROR"
    Write-PmcTuiLog $_.ScriptStackTrace "ERROR"
    throw  # Re-throw to stop execution
}

# Cleanup in finally
finally {
    Write-Host "`e[?25h"  # Show cursor
    Write-Host "`e[0m"    # Reset colors
}
```

**Key Points:**
- Only use `throw` for truly critical failures
- Always have try-catch at entry points
- Always have finally for cleanup (cursor, terminal reset)
- Log before throwing
- Include stack trace in logs

---

### Pattern 5: Background Operations

**Use Case:** Async operations, callbacks, event handlers

**Pattern:** Log errors, update UI state, never crash

```powershell
$this.OnDataChanged = {
    try {
        $this.RefreshList()
    }
    catch {
        Write-PmcTuiLog "OnDataChanged callback failed: $_" "ERROR"
        $this.SetStatusMessage("Failed to refresh", "error")
        # Don't throw - event handler must not crash
    }
}.GetNewClosure()
```

**Key Points:**
- Never throw from callbacks/event handlers
- Always try-catch
- Log errors
- Update UI to show error state
- Continue operation if possible

---

## Common Anti-Patterns to Avoid

### ❌ Silent Failures
```powershell
# BAD
[void] DoSomething() {
    if (-not $this.Store.SaveData()) {
        # Nothing - user has no idea it failed!
    }
}
```

### ❌ Throwing from UI Operations
```powershell
# BAD
[void] OnButtonClick() {
    if (-not $this.ValidateInput()) {
        throw "Invalid input"  # Crashes the app!
    }
}
```

### ❌ Not Catching Exceptions
```powershell
# BAD
[bool] LoadData() {
    $data = Get-Content $path | ConvertFrom-Json  # Can throw!
    $this._data = $data
    return $true
}
```

### ❌ Generic Error Messages
```powershell
# BAD
$this.LastError = "Error occurred"  # Not helpful!

# GOOD
$this.LastError = "Failed to save task: File is read-only"
```

---

## Error Logging Guidelines

### Levels

- **ERROR**: Operation failed, user impacted, needs attention
- **WARNING**: Unexpected but recovered, might indicate problem
- **INFO**: Normal operations, milestones, state changes
- **DEBUG**: Detailed flow for troubleshooting

### Format

```powershell
Write-PmcTuiLog "ComponentName: What happened and why" "LEVEL"
```

### Examples

```powershell
Write-PmcTuiLog "TaskStore: Failed to save data - disk full" "ERROR"
Write-PmcTuiLog "TaskListScreen: No tasks found, showing empty state" "INFO"
Write-PmcTuiLog "InlineEditor: Field validation failed - date in past" "WARNING"
Write-PmcTuiLog "UniversalList: HandleInput - Key=$($keyInfo.Key) SelectedIndex=$($this.SelectedIndex)" "DEBUG"
```

---

## Testing Error Paths

All error handlers should be tested by:
1. Invalid input
2. Missing files
3. Corrupt data
4. Null/empty values
5. Type mismatches

---

## Summary Checklist

- [ ] Data operations return bool + set LastError
- [ ] UI operations never throw, always show status
- [ ] Validation returns error arrays
- [ ] Critical init throws with cleanup in finally
- [ ] Callbacks/handlers never throw
- [ ] All exceptions caught and logged
- [ ] Error messages are user-friendly
- [ ] Logs include component name and context
