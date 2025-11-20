# GridCell.ps1
# Cell model for EditableGrid - encapsulates cell state, validation, and edit lifecycle

class GridCell {
    # Core properties
    [string]$RowId              # Unique identifier for the row (e.g., task ID)
    [string]$ColumnName         # Column name (e.g., 'title', 'due', 'priority')
    [object]$OriginalValue      # Original value from data source
    [object]$EditValue          # Current edit value (may differ from original)

    # Edit state
    [bool]$IsEditing = $false   # True when cell is actively being edited
    [bool]$IsDirty = $false     # True when EditValue differs from OriginalValue
    [int]$CursorPos = 0         # Cursor position within edit string (0-based)

    # Validation
    [string]$ValidationError = $null  # Validation error message if any
    [bool]$IsValid = $true      # True when EditValue passes validation

    # Metadata
    [hashtable]$Metadata = @{}  # Additional cell metadata (e.g., column width, type)

    # Constructor
    GridCell([string]$rowId, [string]$columnName, [object]$value) {
        $this.RowId = $rowId
        $this.ColumnName = $columnName
        $this.OriginalValue = $value
        $this.EditValue = $value
        $this.IsDirty = $false
        $this.IsValid = $true
    }

    # Start editing this cell
    [void] BeginEdit() {
        $this.IsEditing = $true
        # Initialize EditValue from OriginalValue if not already set
        if ($null -eq $this.EditValue) {
            $this.EditValue = $this.OriginalValue
        }
        # ALWAYS set EditValue to OriginalValue when starting edit to preserve existing text
        $this.EditValue = $this.OriginalValue
        # Position cursor at end of text
        if ($this.EditValue -is [string]) {
            $this.CursorPos = $this.EditValue.Length
        } else {
            $this.CursorPos = 0
        }
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') GridCell.BeginEdit: EditValue='$($this.EditValue)' CursorPos=$($this.CursorPos)"
    }

    # Commit edit with validation
    [bool] CommitEdit([scriptblock]$validator = $null) {
        # Run validator if provided
        if ($null -ne $validator) {
            try {
                $result = & $validator $this.EditValue $this.OriginalValue
                if ($result -is [hashtable]) {
                    $this.IsValid = $result.IsValid
                    $this.ValidationError = $result.Error
                } else {
                    # Assume bool return means IsValid
                    $this.IsValid = $result
                    $this.ValidationError = if ($result) { $null } else { "Validation failed" }
                }
            } catch {
                $this.IsValid = $false
                $this.ValidationError = $_.Exception.Message
            }
        }

        # Only commit if valid
        if ($this.IsValid) {
            $this.OriginalValue = $this.EditValue
            $this.IsDirty = $false
            $this.IsEditing = $false
            $this.ValidationError = $null
            return $true
        }

        return $false
    }

    # Cancel edit and revert to original value
    [void] CancelEdit() {
        $this.EditValue = $this.OriginalValue
        $this.IsDirty = $false
        $this.IsEditing = $false
        $this.ValidationError = $null
        $this.CursorPos = 0
    }

    # Update edit value and mark dirty if changed
    [void] SetEditValue([object]$value) {
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') GridCell.SetEditValue: OLD='$($this.EditValue)' NEW='$value'"
        $this.EditValue = $value
        $this.IsDirty = $this._ValuesAreDifferent($this.EditValue, $this.OriginalValue)

        # Update cursor position if string
        if ($value -is [string]) {
            $this.CursorPos = [Math]::Min($this.CursorPos, $value.Length)
        }
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') GridCell.SetEditValue: AFTER EditValue='$($this.EditValue)' CursorPos=$($this.CursorPos)"
    }

    # Get display value (formatted for rendering)
    [string] GetDisplayValue() {
        if ($null -eq $this.EditValue) {
            return ""
        }

        # If there's a display formatter in metadata, use it
        if ($this.Metadata.ContainsKey('DisplayFormatter')) {
            $formatter = $this.Metadata['DisplayFormatter']
            try {
                return & $formatter $this.EditValue
            } catch {
                # Fallback to string conversion
                return $this.EditValue.ToString()
            }
        }

        # Default: convert to string
        if ($this.EditValue -is [string]) {
            return $this.EditValue
        } else {
            return $this.EditValue.ToString()
        }
    }

    # Get edit value (raw value for editing)
    [string] GetEditValue() {
        if ($null -eq $this.EditValue) {
            return ""
        }

        # If there's an edit formatter in metadata, use it
        if ($this.Metadata.ContainsKey('EditFormatter')) {
            $formatter = $this.Metadata['EditFormatter']
            try {
                return & $formatter $this.EditValue
            } catch {
                # Fallback to string conversion
                return $this.EditValue.ToString()
            }
        }

        # Default: convert to string for editing
        if ($this.EditValue -is [string]) {
            return $this.EditValue
        } else {
            return $this.EditValue.ToString()
        }
    }

    # Insert text at cursor position
    [void] InsertTextAtCursor([string]$text) {
        if (-not $this.IsEditing) {
            return
        }

        $currentText = $this.GetEditValue()
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') GridCell.InsertTextAtCursor: text='$text' currentText='$currentText' CursorPos=$($this.CursorPos)"
        $before = $currentText.Substring(0, $this.CursorPos)
        $after = $currentText.Substring($this.CursorPos)
        $newText = $before + $text + $after

        $this.SetEditValue($newText)
        $this.CursorPos += $text.Length
        Add-Content -Path "/tmp/pmc-edit-debug.log" -Value "$(Get-Date -Format 'HH:mm:ss.fff') GridCell.InsertTextAtCursor: newText='$newText' newCursorPos=$($this.CursorPos)"
    }

    # Delete character at cursor position (Backspace)
    [void] DeleteCharBeforeCursor() {
        if (-not $this.IsEditing -or $this.CursorPos -eq 0) {
            return
        }

        $currentText = $this.GetEditValue()
        if ($currentText.Length -eq 0) {
            return
        }

        $before = $currentText.Substring(0, $this.CursorPos - 1)
        $after = if ($this.CursorPos -lt $currentText.Length) {
            $currentText.Substring($this.CursorPos)
        } else {
            ""
        }

        $this.SetEditValue($before + $after)
        $this.CursorPos = [Math]::Max(0, $this.CursorPos - 1)
    }

    # Delete character after cursor position (Delete key)
    [void] DeleteCharAfterCursor() {
        if (-not $this.IsEditing) {
            return
        }

        $currentText = $this.GetEditValue()
        if ($currentText.Length -eq 0 -or $this.CursorPos -ge $currentText.Length) {
            return
        }

        $before = $currentText.Substring(0, $this.CursorPos)
        $after = if ($this.CursorPos + 1 -lt $currentText.Length) {
            $currentText.Substring($this.CursorPos + 1)
        } else {
            ""
        }

        $this.SetEditValue($before + $after)
        # CursorPos stays same after Delete
    }

    # Move cursor left
    [void] MoveCursorLeft() {
        if ($this.IsEditing) {
            $this.CursorPos = [Math]::Max(0, $this.CursorPos - 1)
        }
    }

    # Move cursor right
    [void] MoveCursorRight() {
        if ($this.IsEditing) {
            $currentText = $this.GetEditValue()
            $this.CursorPos = [Math]::Min($currentText.Length, $this.CursorPos + 1)
        }
    }

    # Move cursor to start
    [void] MoveCursorToStart() {
        if ($this.IsEditing) {
            $this.CursorPos = 0
        }
    }

    # Move cursor to end
    [void] MoveCursorToEnd() {
        if ($this.IsEditing) {
            $currentText = $this.GetEditValue()
            $this.CursorPos = $currentText.Length
        }
    }

    # Helper: Compare values considering null and type differences
    hidden [bool] _ValuesAreDifferent([object]$val1, [object]$val2) {
        # Both null = same
        if ($null -eq $val1 -and $null -eq $val2) {
            return $false
        }

        # One null = different
        if ($null -eq $val1 -or $null -eq $val2) {
            return $true
        }

        # Compare as strings for simplicity
        return $val1.ToString() -ne $val2.ToString()
    }

    # Helper: Create snapshot for undo/redo
    [hashtable] CreateSnapshot() {
        return @{
            RowId = $this.RowId
            ColumnName = $this.ColumnName
            OriginalValue = $this.OriginalValue
            EditValue = $this.EditValue
            IsDirty = $this.IsDirty
            IsEditing = $this.IsEditing
            CursorPos = $this.CursorPos
        }
    }

    # Helper: Restore from snapshot
    [void] RestoreSnapshot([hashtable]$snapshot) {
        $this.OriginalValue = $snapshot.OriginalValue
        $this.EditValue = $snapshot.EditValue
        $this.IsDirty = $snapshot.IsDirty
        $this.IsEditing = $snapshot.IsEditing
        $this.CursorPos = $snapshot.CursorPos
    }
}
