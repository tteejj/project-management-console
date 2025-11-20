# CellEditor.ps1
# Base class and implementations for cell editors in EditableGrid

# Base class for all cell editors
class CellEditor {
    [string]$EditorType       # Type of editor (text, number, checkbox, widget)
    [hashtable]$Options = @{} # Editor-specific options

    # Constructor
    CellEditor([string]$type) {
        $this.EditorType = $type
    }

    # Handle key input - returns $true if key was handled
    [bool] HandleKey([GridCell]$cell, [System.ConsoleKeyInfo]$key) {
        # Base implementation - override in derived classes
        return $false
    }

    # Validate cell value - returns hashtable with IsValid and Error
    [hashtable] Validate([object]$value) {
        # Base implementation - always valid
        return @{ IsValid = $true; Error = $null }
    }

    # Format value for display
    [string] FormatDisplay([object]$value) {
        if ($null -eq $value) {
            return ""
        }
        return $value.ToString()
    }

    # Format value for editing
    [string] FormatEdit([object]$value) {
        if ($null -eq $value) {
            return ""
        }
        return $value.ToString()
    }

    # Can this editor handle this column type?
    [bool] CanEdit([string]$columnName, [object]$value) {
        return $true
    }
}

# Text editor - handles string input
class TextCellEditor : CellEditor {
    [int]$MaxLength = 0       # 0 = unlimited
    [string]$Pattern = ""     # Regex pattern for validation (empty = no validation)
    [bool]$AllowEmpty = $true # Allow empty strings

    TextCellEditor() : base("text") {
    }

    [bool] HandleKey([GridCell]$cell, [System.ConsoleKeyInfo]$key) {
        $keyChar = $key.KeyChar
        $keyCode = $key.Key

        switch ($keyCode) {
            'Backspace' {
                $cell.DeleteCharBeforeCursor()
                return $true
            }
            'Delete' {
                $cell.DeleteCharAfterCursor()
                return $true
            }
            'LeftArrow' {
                $cell.MoveCursorLeft()
                return $true
            }
            'RightArrow' {
                $cell.MoveCursorRight()
                return $true
            }
            'Home' {
                $cell.MoveCursorToStart()
                return $true
            }
            'End' {
                $cell.MoveCursorToEnd()
                return $true
            }
            default {
                # Handle printable characters
                if ([char]::IsControl($keyChar) -eq $false) {
                    # Check MaxLength
                    $currentText = $cell.GetEditValue()
                    if ($this.MaxLength -gt 0 -and $currentText.Length -ge $this.MaxLength) {
                        return $true  # Ignore input if at max length
                    }

                    $cell.InsertTextAtCursor([string]$keyChar)
                    return $true
                }
            }
        }

        return $false
    }

    [hashtable] Validate([object]$value) {
        $strValue = if ($null -eq $value) { "" } else { $value.ToString() }

        # Check if empty is allowed
        if (-not $this.AllowEmpty -and [string]::IsNullOrWhiteSpace($strValue)) {
            return @{ IsValid = $false; Error = "Value cannot be empty" }
        }

        # Check pattern if specified
        if ($this.Pattern -ne "" -and $strValue -ne "") {
            if ($strValue -notmatch $this.Pattern) {
                return @{ IsValid = $false; Error = "Value does not match required pattern" }
            }
        }

        # Check max length
        if ($this.MaxLength -gt 0 -and $strValue.Length -gt $this.MaxLength) {
            return @{ IsValid = $false; Error = "Value exceeds maximum length of $($this.MaxLength)" }
        }

        return @{ IsValid = $true; Error = $null }
    }
}

# Number editor - handles numeric input only
class NumberCellEditor : CellEditor {
    [double]$MinValue = [double]::MinValue
    [double]$MaxValue = [double]::MaxValue
    [bool]$AllowDecimals = $true
    [bool]$AllowNegative = $true

    NumberCellEditor() : base("number") {
    }

    [bool] HandleKey([GridCell]$cell, [System.ConsoleKeyInfo]$key) {
        $keyChar = $key.KeyChar
        $keyCode = $key.Key

        switch ($keyCode) {
            'Backspace' {
                $cell.DeleteCharBeforeCursor()
                return $true
            }
            'Delete' {
                $cell.DeleteCharAfterCursor()
                return $true
            }
            'LeftArrow' {
                $cell.MoveCursorLeft()
                return $true
            }
            'RightArrow' {
                $cell.MoveCursorRight()
                return $true
            }
            'Home' {
                $cell.MoveCursorToStart()
                return $true
            }
            'End' {
                $cell.MoveCursorToEnd()
                return $true
            }
            default {
                # Only allow numeric characters, minus sign, and decimal point
                if ([char]::IsDigit($keyChar)) {
                    $cell.InsertTextAtCursor([string]$keyChar)
                    return $true
                }

                # Allow minus sign at start if negative numbers allowed
                if ($keyChar -eq '-' -and $this.AllowNegative -and $cell.CursorPos -eq 0) {
                    $currentText = $cell.GetEditValue()
                    if (-not $currentText.StartsWith('-')) {
                        $cell.InsertTextAtCursor('-')
                    }
                    return $true
                }

                # Allow decimal point if decimals allowed and not already present
                if ($keyChar -eq '.' -and $this.AllowDecimals) {
                    $currentText = $cell.GetEditValue()
                    if (-not $currentText.Contains('.')) {
                        $cell.InsertTextAtCursor('.')
                    }
                    return $true
                }
            }
        }

        return $false
    }

    [hashtable] Validate([object]$value) {
        $strValue = if ($null -eq $value) { "" } else { $value.ToString() }

        # Empty is valid (converts to 0)
        if ([string]::IsNullOrWhiteSpace($strValue)) {
            return @{ IsValid = $true; Error = $null }
        }

        # Try parse as number
        $numValue = 0.0
        if (-not [double]::TryParse($strValue, [ref]$numValue)) {
            return @{ IsValid = $false; Error = "Value is not a valid number" }
        }

        # Check range
        if ($numValue -lt $this.MinValue) {
            return @{ IsValid = $false; Error = "Value must be at least $($this.MinValue)" }
        }
        if ($numValue -gt $this.MaxValue) {
            return @{ IsValid = $false; Error = "Value must be at most $($this.MaxValue)" }
        }

        return @{ IsValid = $true; Error = $null }
    }

    [string] FormatDisplay([object]$value) {
        if ($null -eq $value -or $value -eq "") {
            return "0"
        }
        $numValue = 0.0
        if ([double]::TryParse($value.ToString(), [ref]$numValue)) {
            if ($this.AllowDecimals) {
                return $numValue.ToString("0.##")
            } else {
                return ([int]$numValue).ToString()
            }
        }
        return "0"
    }
}

# Checkbox editor - handles boolean toggle with Space
class CheckboxCellEditor : CellEditor {
    [string]$TrueDisplay = "[X]"
    [string]$FalseDisplay = "[ ]"

    CheckboxCellEditor() : base("checkbox") {
    }

    [bool] HandleKey([GridCell]$cell, [System.ConsoleKeyInfo]$key) {
        $keyCode = $key.Key

        # Space or Enter toggles checkbox
        if ($keyCode -eq 'Spacebar' -or $keyCode -eq 'Enter') {
            $currentValue = $cell.EditValue
            $boolValue = $this._ParseBool($currentValue)
            $cell.SetEditValue(-not $boolValue)
            return $true
        }

        return $false
    }

    [hashtable] Validate([object]$value) {
        # Checkboxes are always valid (boolean)
        return @{ IsValid = $true; Error = $null }
    }

    [string] FormatDisplay([object]$value) {
        $boolValue = $this._ParseBool($value)
        return if ($boolValue) { $this.TrueDisplay } else { $this.FalseDisplay }
    }

    [string] FormatEdit([object]$value) {
        return $this.FormatDisplay($value)
    }

    hidden [bool] _ParseBool([object]$value) {
        if ($null -eq $value) {
            return $false
        }
        if ($value -is [bool]) {
            return $value
        }
        $strValue = $value.ToString().ToLower()
        return $strValue -in @('true', 'yes', '1', 'x', 'checked')
    }
}

# Widget editor - launches popup widgets (DatePicker, ProjectPicker, TagEditor)
class WidgetCellEditor : CellEditor {
    [string]$WidgetType       # Type of widget to launch (date, project, tags)
    [scriptblock]$WidgetFactory  # Factory function to create widget instance

    WidgetCellEditor([string]$widgetType) : base("widget") {
        $this.WidgetType = $widgetType
    }

    [bool] HandleKey([GridCell]$cell, [System.ConsoleKeyInfo]$key) {
        $keyCode = $key.Key

        # Enter or Space launches the widget
        if ($keyCode -eq 'Enter' -or $keyCode -eq 'Spacebar') {
            # Widget launch will be handled by EditableGrid
            # This editor just signals that widget should be launched
            return $true
        }

        # Allow basic text editing as fallback
        $keyChar = $key.KeyChar
        switch ($keyCode) {
            'Backspace' {
                $cell.DeleteCharBeforeCursor()
                return $true
            }
            'Delete' {
                $cell.DeleteCharAfterCursor()
                return $true
            }
            'LeftArrow' {
                $cell.MoveCursorLeft()
                return $true
            }
            'RightArrow' {
                $cell.MoveCursorRight()
                return $true
            }
            default {
                # Allow typing for text-based widget types (e.g., tags)
                if ([char]::IsControl($keyChar) -eq $false) {
                    $cell.InsertTextAtCursor([string]$keyChar)
                    return $true
                }
            }
        }

        return $false
    }

    [hashtable] Validate([object]$value) {
        # Widget-specific validation can be added here
        # For now, accept any value from widget
        return @{ IsValid = $true; Error = $null }
    }

    [string] FormatDisplay([object]$value) {
        if ($null -eq $value) {
            return ""
        }

        # Format based on widget type
        switch ($this.WidgetType) {
            'date' {
                if ($value -is [DateTime]) {
                    return $value.ToString('yyyy-MM-dd')
                }
                return $value.ToString()
            }
            'tags' {
                if ($value -is [array]) {
                    return ($value -join ', ')
                }
                return $value.ToString()
            }
            default {
                return $value.ToString()
            }
        }

        # Fallback return (should never reach here but satisfies strict mode)
        return $value.ToString()
    }
}
