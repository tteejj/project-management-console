# GridChangeTracker.ps1
# Change tracking and undo/redo support for EditableGrid

# Represents a single change operation
class GridChange {
    [DateTime]$Timestamp
    [string]$ChangeType      # 'edit', 'insert', 'delete'
    [string]$RowId
    [string]$ColumnName
    [object]$OldValue
    [object]$NewValue
    [hashtable]$Metadata = @{}

    GridChange([string]$type, [string]$rowId, [string]$columnName, [object]$oldValue, [object]$newValue) {
        $this.Timestamp = Get-Date
        $this.ChangeType = $type
        $this.RowId = $rowId
        $this.ColumnName = $columnName
        $this.OldValue = $oldValue
        $this.NewValue = $newValue
    }

    # Create inverse change for undo
    [GridChange] CreateInverse() {
        return [GridChange]::new($this.ChangeType, $this.RowId, $this.ColumnName, $this.NewValue, $this.OldValue)
    }

    # Get description for UI
    [string] GetDescription() {
        switch ($this.ChangeType) {
            'edit' {
                return "Edit $($this.ColumnName) in row $($this.RowId)"
            }
            'insert' {
                return "Insert row $($this.RowId)"
            }
            'delete' {
                return "Delete row $($this.RowId)"
            }
            default {
                return "Change in row $($this.RowId)"
            }
        }
        # Fallback return
        return "Change in row $($this.RowId)"
    }
}

# Tracks changes with undo/redo capability
class GridChangeTracker {
    hidden [System.Collections.Generic.List[GridChange]]$_undoStack
    hidden [System.Collections.Generic.List[GridChange]]$_redoStack
    [int]$MaxUndoLevels = 100
    [bool]$IsEnabled = $true

    # Constructor
    GridChangeTracker() {
        $this._undoStack = [System.Collections.Generic.List[GridChange]]::new()
        $this._redoStack = [System.Collections.Generic.List[GridChange]]::new()
    }

    # Track a cell edit
    [void] TrackEdit([string]$rowId, [string]$columnName, [object]$oldValue, [object]$newValue) {
        if (-not $this.IsEnabled) {
            return
        }

        # Don't track if values are the same
        if ($this._ValuesAreEqual($oldValue, $newValue)) {
            return
        }

        $change = [GridChange]::new('edit', $rowId, $columnName, $oldValue, $newValue)
        $this._PushUndo($change)
    }

    # Track a row insertion
    [void] TrackInsert([string]$rowId, [hashtable]$rowData) {
        if (-not $this.IsEnabled) {
            return
        }

        $change = [GridChange]::new('insert', $rowId, '', $null, $rowData)
        $this._PushUndo($change)
    }

    # Track a row deletion
    [void] TrackDelete([string]$rowId, [hashtable]$rowData) {
        if (-not $this.IsEnabled) {
            return
        }

        $change = [GridChange]::new('delete', $rowId, '', $rowData, $null)
        $this._PushUndo($change)
    }

    # Can undo?
    [bool] CanUndo() {
        return $this._undoStack.Count -gt 0
    }

    # Can redo?
    [bool] CanRedo() {
        return $this._redoStack.Count -gt 0
    }

    # Undo last change - returns change to apply
    [GridChange] Undo() {
        if (-not $this.CanUndo()) {
            return $null
        }

        $change = $this._undoStack[$this._undoStack.Count - 1]
        $this._undoStack.RemoveAt($this._undoStack.Count - 1)

        # Push inverse onto redo stack
        $inverseChange = $change.CreateInverse()
        $this._redoStack.Add($inverseChange)

        # Trim redo stack if needed
        if ($this._redoStack.Count -gt $this.MaxUndoLevels) {
            $this._redoStack.RemoveAt(0)
        }

        return $change.CreateInverse()
    }

    # Redo last undone change - returns change to apply
    [GridChange] Redo() {
        if (-not $this.CanRedo()) {
            return $null
        }

        $change = $this._redoStack[$this._redoStack.Count - 1]
        $this._redoStack.RemoveAt($this._redoStack.Count - 1)

        # Push inverse onto undo stack
        $inverseChange = $change.CreateInverse()
        $this._undoStack.Add($inverseChange)

        return $change.CreateInverse()
    }

    # Get undo stack description for UI
    [string[]] GetUndoHistory() {
        $history = @()
        for ($i = $this._undoStack.Count - 1; $i -ge 0; $i--) {
            $change = $this._undoStack[$i]
            $history += "$($change.Timestamp.ToString('HH:mm:ss')) - $($change.GetDescription())"
        }
        return $history
    }

    # Get redo stack description for UI
    [string[]] GetRedoHistory() {
        $history = @()
        for ($i = $this._redoStack.Count - 1; $i -ge 0; $i--) {
            $change = $this._redoStack[$i]
            $history += "$($change.Timestamp.ToString('HH:mm:ss')) - $($change.GetDescription())"
        }
        return $history
    }

    # Clear all history
    [void] Clear() {
        $this._undoStack.Clear()
        $this._redoStack.Clear()
    }

    # Clear redo stack (called when new change is made)
    [void] ClearRedo() {
        $this._redoStack.Clear()
    }

    # Get total number of tracked changes
    [int] GetChangeCount() {
        return $this._undoStack.Count
    }

    # Get changes for a specific row
    [GridChange[]] GetChangesForRow([string]$rowId) {
        $changes = @()
        foreach ($change in $this._undoStack) {
            if ($change.RowId -eq $rowId) {
                $changes += $change
            }
        }
        return $changes
    }

    # Check if row has unsaved changes
    [bool] HasChanges([string]$rowId) {
        foreach ($change in $this._undoStack) {
            if ($change.RowId -eq $rowId) {
                return $true
            }
        }
        return $false
    }

    # Mark all changes as saved (clear undo stack but keep change metadata)
    [void] MarkAllSaved() {
        $this._undoStack.Clear()
        $this._redoStack.Clear()
    }

    # Create savepoint to rollback to
    [int] CreateSavepoint() {
        return $this._undoStack.Count
    }

    # Rollback to savepoint
    [void] RollbackToSavepoint([int]$savepointIndex) {
        while ($this._undoStack.Count -gt $savepointIndex) {
            $this._undoStack.RemoveAt($this._undoStack.Count - 1)
        }
        $this._redoStack.Clear()
    }

    # Helper: Push change onto undo stack
    hidden [void] _PushUndo([GridChange]$change) {
        $this._undoStack.Add($change)

        # Trim undo stack if exceeds max
        if ($this._undoStack.Count -gt $this.MaxUndoLevels) {
            $this._undoStack.RemoveAt(0)
        }

        # Clear redo stack when new change is made
        $this._redoStack.Clear()
    }

    # Helper: Compare values for equality
    hidden [bool] _ValuesAreEqual([object]$val1, [object]$val2) {
        # Both null = equal
        if ($null -eq $val1 -and $null -eq $val2) {
            return $true
        }

        # One null = not equal
        if ($null -eq $val1 -or $null -eq $val2) {
            return $false
        }

        # Compare as strings
        return $val1.ToString() -eq $val2.ToString()
    }

    # Create a batch change group (for multi-cell operations)
    [GridChangeBatch] BeginBatch([string]$description) {
        return [GridChangeBatch]::new($this, $description)
    }
}

# Batch change group for atomic multi-cell operations
class GridChangeBatch {
    hidden [GridChangeTracker]$_tracker
    [string]$Description
    [System.Collections.Generic.List[GridChange]]$Changes
    [DateTime]$StartTime

    GridChangeBatch([GridChangeTracker]$tracker, [string]$description) {
        $this._tracker = $tracker
        $this.Description = $description
        $this.Changes = [System.Collections.Generic.List[GridChange]]::new()
        $this.StartTime = Get-Date
    }

    # Add change to batch
    [void] AddChange([string]$rowId, [string]$columnName, [object]$oldValue, [object]$newValue) {
        $change = [GridChange]::new('edit', $rowId, $columnName, $oldValue, $newValue)
        $change.Metadata['BatchDescription'] = $this.Description
        $this.Changes.Add($change)
    }

    # Commit batch (push all changes to tracker)
    [void] Commit() {
        foreach ($change in $this.Changes) {
            $this._tracker._PushUndo($change)
        }
    }

    # Rollback batch (discard all changes)
    [void] Rollback() {
        $this.Changes.Clear()
    }
}
