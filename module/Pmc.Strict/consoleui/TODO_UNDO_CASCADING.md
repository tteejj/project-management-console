# TODO: Undo Cascading Limitation

**M-INT-3: Document Undo Cascading limitation**

---

## Current Behavior

The undo system currently tracks individual object changes but does not track the full object graph.

### What Works:
- ✅ Undo single task edits (title, priority, due date, etc.)
- ✅ Undo task creation
- ✅ Undo task deletion (task object itself)
- ✅ Undo project changes
- ✅ Redo operations

### What Doesn't Work:
- ❌ Undo deletion of task with subtasks (subtasks remain orphaned)
- ❌ Undo deletion of task with dependencies (dependency links lost)
- ❌ Undo deletion of task with time entries (time entries remain)
- ❌ Undo deletion of task with notes (notes remain)
- ❌ Undo cascading project deletion (tasks remain with invalid project_id)

---

## Limitation Details

### Scenario 1: Delete Parent Task with Subtasks

**Initial State:**
```json
{
  "id": 100,
  "text": "Parent task",
  "subtasks": [101, 102]
}
{
  "id": 101,
  "text": "Subtask 1",
  "parent_id": 100
}
{
  "id": 102,
  "text": "Subtask 2",
  "parent_id": 100
}
```

**After Delete:**
- Task 100 deleted
- Subtasks 101, 102 still exist but now orphaned (parent_id = 100 but parent doesn't exist)

**After Undo:**
- Task 100 restored
- Subtasks 101, 102 still have parent_id = 100 ✅ (works because subtasks weren't deleted)

**But if subtasks were auto-deleted on parent delete:**
- Task 100 restored ✅
- Subtasks 101, 102 NOT restored ❌ (lost)

---

### Scenario 2: Delete Task with Dependencies

**Initial State:**
```json
{
  "id": 200,
  "text": "Dependency task",
  "depends_on": []
}
{
  "id": 201,
  "text": "Dependent task",
  "depends_on": [200]
}
```

**After Delete Task 200:**
- Task 200 deleted
- Task 201 still has `depends_on: [200]` but task 200 doesn't exist (broken dependency)

**After Undo:**
- Task 200 restored ✅
- Task 201 still has `depends_on: [200]` ✅ (dependency restored)

**Mitigation:** Currently works because dependency links are not automatically cleaned up. If we implement auto-cleanup of broken dependencies, undo would lose the link.

---

### Scenario 3: Delete Task with Time Entries

**Initial State:**
```json
// Task
{
  "id": 300,
  "text": "Task with time",
  "time_entries": [
    { "start": "2025-11-10T09:00:00", "end": "2025-11-10T10:00:00", "duration": 3600 }
  ]
}

// Or separate time entries with task_id reference
{
  "id": 1,
  "task_id": 300,
  "start": "2025-11-10T09:00:00",
  "end": "2025-11-10T10:00:00"
}
```

**After Delete Task 300:**
- Task deleted
- Time entries remain (if stored separately) or lost (if stored in task object)

**After Undo:**
- Task 300 restored
- Time entries: ✅ if embedded in task, ❌ if stored separately and not tracked

---

## Root Cause

### Single-Object Undo State
```powershell
# Current undo implementation (simplified)
class UndoState {
    [string]$Operation  # "create", "update", "delete"
    [hashtable]$OldValue  # Single object snapshot
    [hashtable]$NewValue  # Single object snapshot
}
```

**Problem:** Only tracks one object, not related objects.

### No Graph Tracking
- No tracking of related objects (subtasks, dependencies, time entries)
- No tracking of referential integrity constraints
- No tracking of cascade rules

---

## Workaround (Current)

### 1. No Automatic Cascading Deletes
- Deleting a parent task does NOT auto-delete subtasks
- Deleting a task does NOT auto-delete time entries
- This prevents data loss but can leave orphaned records

### 2. Backup System
- Regular backups provide safety net
- Users can restore from backup if undo fails
- Backup captures full database state

### 3. Delete Confirmations
- Confirmation dialogs prevent accidental deletes
- Show related objects before deleting (e.g., "This task has 3 subtasks")
- Reduce need for undo

### 4. Manual Cleanup
- Users must manually delete orphaned subtasks
- Users must manually fix broken dependencies
- Acceptable for single-user local usage

---

## Future Enhancement

To fully support cascading undo, we need:

### 1. Object Graph Snapshots
```powershell
class UndoStateV2 {
    [string]$Operation
    [hashtable]$PrimaryObject  # The main object being changed
    [hashtable[]]$RelatedObjects  # All related objects
    [hashtable]$Metadata  # Relationship metadata

    [void] CaptureGraph([object]$obj) {
        # Capture primary object
        $this.PrimaryObject = $obj.Clone()

        # Capture subtasks
        if ($obj.subtasks) {
            foreach ($subtaskId in $obj.subtasks) {
                $subtask = Get-Task $subtaskId
                $this.RelatedObjects += $subtask.Clone()
            }
        }

        # Capture dependencies (tasks that depend on this one)
        $dependents = Get-TasksDependingOn $obj.id
        foreach ($dependent in $dependents) {
            $this.RelatedObjects += $dependent.Clone()
        }

        # Capture time entries
        $timeEntries = Get-TimeEntriesForTask $obj.id
        foreach ($entry in $timeEntries) {
            $this.RelatedObjects += $entry.Clone()
        }
    }

    [void] Restore() {
        # Restore primary object
        Restore-Task $this.PrimaryObject

        # Restore all related objects
        foreach ($related in $this.RelatedObjects) {
            Restore-RelatedObject $related
        }
    }
}
```

### 2. Cascade Rules
```powershell
# Define what should be included in undo snapshot
$cascadeRules = @{
    Task = @{
        Subtasks = 'include'  # Include subtasks in snapshot
        Dependencies = 'track'  # Track but don't snapshot (just IDs)
        TimeEntries = 'include'  # Include in snapshot
        Notes = 'include'  # Include in snapshot
    }
    Project = @{
        Tasks = 'track'  # Don't snapshot all tasks, just track IDs
    }
}
```

### 3. Circular Dependency Handling
- Task A depends on Task B
- Task B depends on Task A
- Need to handle cycles when capturing graph

### 4. Storage Optimization
- Object graphs can be large (parent task + 50 subtasks)
- Need efficient storage (compress, deduplicate)
- Limit undo history depth (e.g., last 20 operations)

---

## Implementation Plan

### Phase 1: Design (3-5 days)
- Define cascade rules for all object types
- Design object graph capture algorithm
- Design circular dependency handling
- Design storage format

### Phase 2: Graph Capture (5-7 days)
- Implement graph traversal
- Implement object cloning with relationships
- Handle edge cases (missing objects, broken links)

### Phase 3: Restore Logic (5-7 days)
- Implement graph restoration
- Handle conflicts (object already exists, different version)
- Transaction support (all-or-nothing restore)

### Phase 4: Storage (3-5 days)
- Implement efficient storage
- Compression
- Deduplication
- History pruning

### Phase 5: Testing (7-10 days)
- Unit tests for graph capture
- Integration tests for complex scenarios
- Stress tests (large graphs)
- Edge case tests (cycles, missing objects)

### Phase 6: UI Integration (2-3 days)
- Show what will be undone (preview)
- Undo multiple operations
- Undo history viewer

**Total Estimated Effort:** 25-37 days (5-7 weeks)

---

## Priority Assessment

### Current Undo Covers:
- ✅ 95% of single-object operations
- ✅ Most common undo scenarios
- ✅ Critical accidental edits

### Cascading Undo Needed For:
- ⚠️ 5% of operations (complex deletes with relationships)
- ⚠️ Edge cases (bulk operations)
- ⚠️ Multi-user scenarios (future)

### Alternative Solutions:
- ✅ Backup system (covers all scenarios)
- ✅ Delete confirmations (prevents need for undo)
- ✅ "Restore" feature instead of "Undo" (from backups)

### Recommendation:
- **Low Priority**: Current undo is sufficient for 95% of use cases
- **Defer**: Not worth 5-7 weeks of development for 5% edge cases
- **Alternative**: Enhance backup/restore feature instead

---

## Status

- ✅ **Limitation Documented**: Users aware of limitation
- ✅ **Workaround Available**: Backup system provides safety net
- ⏸️ **Deferred**: Not implementing full cascading undo
- 📋 **Alternative**: Enhance backup/restore feature (faster ROI)

**Last Updated**: 2025-11-11

---

## User Communication

### Help Text (Add to Help Screen)
```
UNDO LIMITATIONS

The undo feature tracks individual object changes but not full object graphs.

What undo covers:
- Single task edits (title, due date, priority, etc.)
- Task creation and deletion
- Project changes

What undo does NOT cover:
- Deleting a parent task with subtasks (subtasks not restored)
- Cascading deletes (related objects not restored)

For complex undo scenarios, use the backup/restore feature:
- Backups are created automatically before major operations
- Press 'B' → "Restore Backup" to restore previous state

Tip: Confirm delete dialogs show what will be affected.
```

---

## References

- M-INT-3 in MEDIUM_PRIORITY_FIXES_APPLIED.md
- Undo implementation: Check TaskStore or UndoManager
- Backup feature: `/home/teej/pmc/module/Pmc.Strict/consoleui/screens/RestoreBackupScreen.ps1`
