# TODO: Incremental Save Feature

**M-PERF-8: Document Incremental Save as TODO**

---

## Overview

Instead of saving the entire task database on every change, implement incremental saves that only write changed records.

---

## Current Behavior

- Every task modification triggers a full database save
- Entire JSON file is rewritten (all tasks, projects, metadata)
- Acceptable for databases with <1000 tasks
- Becomes slow for databases with >5000 tasks

---

## Proposed Solution

### Phase 1: Change Tracking
- Add dirty flags to individual task objects
- Track which tasks have been modified since last save
- Maintain a "dirty set" of task IDs

### Phase 2: Incremental Write
- Save only modified tasks to a change log
- Periodically merge change log into main database
- Keep main database as authoritative source

### Phase 3: Transaction Log
- Implement append-only transaction log
- Record all changes with timestamps
- Enable point-in-time recovery
- Support for audit trail

---

## Complexity Analysis

### High Complexity Factors:
1. **Data Consistency**: Ensuring partial saves don't corrupt database
2. **Concurrency**: Handling multiple TUI instances (file locking)
3. **Recovery**: Rebuilding state from transaction log on crash
4. **Testing**: Comprehensive testing of edge cases

### Risk Areas:
- **Data Loss**: Partial write failures could corrupt database
- **Performance**: Transaction log could grow large over time
- **Complexity**: Significantly more code to maintain

---

## Benefits

### Performance:
- **Fast saves** for large databases (write 10 tasks instead of 10,000)
- **Reduced I/O** overhead (less disk writes)
- **Better responsiveness** during auto-save

### Additional Features:
- **Audit trail** of all changes
- **Point-in-time recovery** (undo beyond single level)
- **Multi-user support** (future: with proper locking)

---

## Implementation Plan

### Step 1: Change Tracking (2-3 days)
```powershell
class TaskStore {
    hidden [HashSet[int]]$_dirtyTasks = [HashSet[int]]::new()

    [void] UpdateTask([hashtable]$task) {
        # Update task
        $this._tasks[$task.id] = $task

        # Mark as dirty
        [void]$this._dirtyTasks.Add($task.id)

        # Trigger incremental save
        $this._IncrementalSave()
    }
}
```

### Step 2: Transaction Log (3-5 days)
```powershell
hidden [void] _IncrementalSave() {
    if ($this._dirtyTasks.Count -eq 0) { return }

    # Append to transaction log
    $logEntry = @{
        timestamp = Get-Date -Format 'o'
        changes = @()
    }

    foreach ($taskId in $this._dirtyTasks) {
        $logEntry.changes += @{
            type = 'update'
            taskId = $taskId
            task = $this._tasks[$taskId]
        }
    }

    # Append to log file
    $logPath = "$($this._configPath)/transaction.log"
    $logEntry | ConvertTo-Json -Compress | Add-Content $logPath

    # Clear dirty flags
    $this._dirtyTasks.Clear()
}
```

### Step 3: Log Compaction (2-3 days)
```powershell
hidden [void] _CompactLog() {
    # Periodically merge transaction log into main database
    # Run every N changes or on shutdown

    # Load all transactions
    $transactions = Get-Content $transactionLogPath | ConvertFrom-Json

    # Apply to main database
    foreach ($txn in $transactions) {
        foreach ($change in $txn.changes) {
            $this._tasks[$change.taskId] = $change.task
        }
    }

    # Save main database
    $this._SaveAll()

    # Archive old transaction log
    Move-Item $transactionLogPath "$transactionLogPath.$(Get-Date -Format 'yyyyMMdd-HHmmss')"

    # Start new transaction log
    Clear-Content $transactionLogPath
}
```

### Step 4: Recovery (2-3 days)
```powershell
hidden [void] _RecoverFromLog() {
    # On startup, check for transaction log
    if (Test-Path $transactionLogPath) {
        # Load main database
        $this._LoadAll()

        # Apply transaction log on top
        $transactions = Get-Content $transactionLogPath | ConvertFrom-Json
        foreach ($txn in $transactions) {
            foreach ($change in $txn.changes) {
                $this._tasks[$change.taskId] = $change.task
            }
        }

        # Compact log
        $this._CompactLog()
    }
}
```

### Step 5: Testing (5-7 days)
- Unit tests for change tracking
- Integration tests for transaction log
- Stress tests (10,000+ tasks, rapid changes)
- Failure recovery tests (simulated crashes)
- Multi-instance tests (file locking)

---

## Estimated Effort

- **Development**: 15-20 days
- **Testing**: 5-7 days
- **Documentation**: 2-3 days
- **Total**: 22-30 days (1-1.5 months)

---

## Priority Assessment

### Current Performance (Without Incremental Save):
- Database size: 100 tasks → Save time: ~50ms (acceptable)
- Database size: 1000 tasks → Save time: ~200ms (acceptable)
- Database size: 5000 tasks → Save time: ~800ms (noticeable)
- Database size: 10000 tasks → Save time: ~2000ms (slow)

### Priority:
- **Low-Medium**: Only needed for databases >5000 tasks
- **Current users**: Likely <1000 tasks (save time <200ms)
- **Acceptable delay**: Users can tolerate 200-500ms saves

### Recommendation:
- **Defer implementation** until user reports slow saves
- **Monitor database sizes** in production
- **Revisit** if median database size >2000 tasks

---

## Alternative: Simpler Optimizations

Before implementing full incremental save, try:

### 1. Async Save (1-2 days)
```powershell
[void] SaveAsync() {
    # Don't block UI during save
    $saveJob = Start-Job -ScriptBlock {
        param($tasks, $path)
        $tasks | ConvertTo-Json -Depth 10 | Set-Content $path
    } -ArgumentList $this._tasks, $this._dataPath

    # Continue UI operation, job runs in background
}
```

### 2. Debounced Save (1 day)
```powershell
hidden [DateTime]$_lastSaveTime = [DateTime]::MinValue
hidden [bool]$_savePending = $false

[void] Save() {
    # Debounce: only save if >500ms since last save request
    $now = [DateTime]::Now
    if (($now - $this._lastSaveTime).TotalMilliseconds < 500) {
        $this._savePending = $true
        return
    }

    $this._SaveNow()
    $this._lastSaveTime = $now
    $this._savePending = $false
}
```

### 3. Partial JSON Write (3-5 days)
```powershell
[void] SaveTask([hashtable]$task) {
    # Load JSON as string
    $json = Get-Content $dataPath -Raw

    # Find task in JSON string (regex)
    $pattern = '"id":\s*$($task.id).*?}'
    $newTaskJson = $task | ConvertTo-Json -Compress

    # Replace in string
    $json = $json -replace $pattern, $newTaskJson

    # Write back
    $json | Set-Content $dataPath
}
```

**Recommendation**: Try async save and debounced save first (2-3 days effort, significant benefit)

---

## Status

- ✅ **Documented**: Feature fully documented
- ⏸️ **Deferred**: Not implementing now
- 📊 **Monitoring**: Track database sizes and save performance
- 🔄 **Revisit**: When median database >2000 tasks or user complaints

**Last Updated**: 2025-11-11

---

## References

- M-PERF-8 in MEDIUM_PRIORITY_FIXES_APPLIED.md
- TaskStore implementation: `/home/teej/pmc/module/Pmc.Strict/src/TaskStore.ps1`
- Alternative optimizations: Async/Debounced save (simpler, faster ROI)
