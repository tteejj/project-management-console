# InlineEditor.ps1 - Multi-field composer widget for inline editing
# THE KEY WIDGET - Composes multiple input types into a single editor
#
# Usage:
#   $fields = @(
#       @{ Name='text'; Label='Task'; Type='text'; Value='Buy milk'; Required=$true }
#       @{ Name='due'; Label='Due Date'; Type='date'; Value=[DateTime]::Today }
#       @{ Name='project'; Label='Project'; Type='project'; Value='personal' }
#       @{ Name='priority'; Label='Priority'; Type='number'; Value=3; Min=0; Max=5 }
#       @{ Name='tags'; Label='Tags'; Type='tags'; Value=@('urgent') }
#   )
#
#   $editor = [InlineEditor]::new()
#   $editor.SetFields($fields)
#   $editor.SetPosition(5, 5)
#   $editor.OnConfirmed = { param($values) Write-Host "Saved: $($values | ConvertTo-Json)" }
#
#   # Render loop
#   while (-not $editor.IsConfirmed -and -not $editor.IsCancelled) {
#       $ansiOutput = $editor.Render()
#       Write-Host $ansiOutput -NoNewline
#       $key = [Console]::ReadKey($true)
#       $editor.HandleInput($key)
#   }

using namespace System
using namespace System.Collections.Generic
using namespace System.Text

# Load PmcWidget base class and field widgets
if (-not ([System.Management.Automation.PSTypeName]'PmcWidget').Type) {
    . "$PSScriptRoot/PmcWidget.ps1"
}

# Load field widgets
. "$PSScriptRoot/TextInput.ps1"
. "$PSScriptRoot/DatePicker.ps1"
. "$PSScriptRoot/ProjectPicker.ps1"
. "$PSScriptRoot/TagEditor.ps1"

<#
.SYNOPSIS
Multi-field inline editor that composes existing widgets into a unified editor

.DESCRIPTION
Features:
- Compose multiple field types: text, date, project, number, tags
- Tab/Shift+Tab to cycle between fields
- Enter to confirm all changes (validates all fields)
- Esc to cancel
- Visual field list with labels
- Field validation with error display
- OnFieldChanged event for each field change
- OnConfirmed event with all field values
- Smart layout - fields stack vertically
- Focus indicators for active field
- Required field validation

Field Types:
- text: Single-line text input (uses TextInput widget)
- date: Date picker (uses DatePicker widget)
- project: Project picker (uses ProjectPicker widget)
- tags: Tag editor (uses TagEditor widget)
- number: Number input with visual slider (custom inline widget)

.EXAMPLE
$fields = @(
    @{ Name='text'; Label='Task'; Type='text'; Value='Buy milk'; Required=$true }
    @{ Name='due'; Label='Due Date'; Type='date'; Value=[DateTime]::Today }
    @{ Name='project'; Label='Project'; Type='project'; Value='personal' }
    @{ Name='priority'; Label='Priority'; Type='number'; Value=3; Min=0; Max=5 }
    @{ Name='tags'; Label='Tags'; Type='tags'; Value=@('urgent') }
)
$editor = [InlineEditor]::new()
$editor.SetFields($fields)
$values = $editor.GetValues()
#>
class InlineEditor : PmcWidget {
    # === Public Properties ===
    [string]$Title = "Edit"                    # Editor title

    # === Event Callbacks ===
    [scriptblock]$OnFieldChanged = {}          # Called when field changes: param($fieldName, $value)
    [scriptblock]$OnConfirmed = {}             # Called when Enter pressed: param($allValues)
    [scriptblock]$OnCancelled = {}             # Called when Esc pressed
    [scriptblock]$OnValidationFailed = {}      # Called when validation fails: param($errors)

    # === State Flags ===
    [bool]$IsConfirmed = $false                # True when Enter pressed and validated
    [bool]$IsCancelled = $false                # True when Esc pressed

    # === Private State ===
    hidden [List[hashtable]]$_fields = [List[hashtable]]::new()      # Field definitions
    hidden [hashtable]$_fieldWidgets = @{}                           # Widget instances keyed by field name
    hidden [int]$_currentFieldIndex = 0                              # Currently focused field
    hidden [string[]]$_validationErrors = @()                        # Current validation errors
    hidden [bool]$_showFieldWidgets = $false                         # Whether to show expanded field widget
    hidden [string]$_expandedFieldName = ""                          # Name of currently expanded field

    # === Constructor ===
    InlineEditor() : base("InlineEditor") {
        $this.Width = 70
        $this.Height = 25
        $this.CanFocus = $true
    }

    # === Public API Methods ===

    <#
    .SYNOPSIS
    Configure the fields for this editor

    .PARAMETER fields
    Array of hashtables with field definitions:
    - Name: Field identifier (required)
    - Label: Display label (required)
    - Type: Field type: text, date, project, number, tags (required)
    - Value: Initial value (optional)
    - Required: Whether field is required (optional, default $false)
    - Min/Max: For number type (optional)
    - MaxLength: For text type (optional)
    - Placeholder: For text type (optional)
    #>
    [void] SetFields([hashtable[]]$fields) {
        $this._fields.Clear()
        $this._fieldWidgets.Clear()
        $this._currentFieldIndex = 0
        $this._validationErrors = @()

        if ($null -eq $fields -or $fields.Count -eq 0) {
            return
        }

        foreach ($fieldDef in $fields) {
            # Validate field definition
            if (-not $fieldDef.ContainsKey('Name')) {
                throw "Field definition missing 'Name' property"
            }
            if (-not $fieldDef.ContainsKey('Label')) {
                throw "Field definition missing 'Label' property"
            }
            if (-not $fieldDef.ContainsKey('Type')) {
                throw "Field definition missing 'Type' property"
            }

            # Add to fields list
            $this._fields.Add($fieldDef)

            # Create widget instance for this field
            $this._CreateFieldWidget($fieldDef)
        }

        # Calculate required height based on field count
        $this.Height = 6 + ($this._fields.Count * 3) + 3  # Header + fields + footer + padding
    }

    <#
    .SYNOPSIS
    Get all field values as hashtable

    .OUTPUTS
    Hashtable with field names as keys and current values as values
    #>
    [hashtable] GetValues() {
        $values = @{}

        foreach ($field in $this._fields) {
            $fieldName = $field.Name
            $fieldType = $field.Type

            $value = $this._GetFieldValue($fieldName, $fieldType)
            $values[$fieldName] = $value
        }

        return $values
    }

    <#
    .SYNOPSIS
    Get value of a specific field

    .PARAMETER name
    Field name

    .OUTPUTS
    Field value or $null if field not found
    #>
    [object] GetField([string]$name) {
        $field = $this._fields | Where-Object { $_.Name -eq $name } | Select-Object -First 1

        if ($null -eq $field) {
            return $null
        }

        return $this._GetFieldValue($name, $field.Type)
    }

    <#
    .SYNOPSIS
    Set focus to a specific field by index

    .PARAMETER fieldIndex
    Zero-based field index
    #>
    [void] SetFocus([int]$fieldIndex) {
        if ($fieldIndex -ge 0 -and $fieldIndex -lt $this._fields.Count) {
            $this._currentFieldIndex = $fieldIndex
            $this._showFieldWidgets = $false
            $this._expandedFieldName = ""
        }
    }

    <#
    .SYNOPSIS
    Handle keyboard input

    .PARAMETER keyInfo
    ConsoleKeyInfo from [Console]::ReadKey($true)

    .OUTPUTS
    True if input was handled, False otherwise
    #>
    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        Write-PmcTuiLog "InlineEditor.HandleInput: Key=$($keyInfo.Key) Expanded=$($this._expandedFieldName)" "DEBUG"

        # If a field widget is expanded, route input to it
        if ($this._showFieldWidgets -and -not [string]::IsNullOrWhiteSpace($this._expandedFieldName)) {
            # Safety: Allow Escape to force-close expanded widget even if widget doesn't handle it
            if ($keyInfo.Key -eq 'Escape') {
                $this._showFieldWidgets = $false
                $this._expandedFieldName = ""
                return $true
            }

            $widget = $this._fieldWidgets[$this._expandedFieldName]

            # Check for widget-specific completion
            $handled = $widget.HandleInput($keyInfo)

            # Check if widget confirmed or cancelled
            if ($widget.IsConfirmed -or $widget.IsCancelled) {
                # Collapse widget
                $this._showFieldWidgets = $false

                # Get value from widget and update field
                if ($widget.IsConfirmed) {
                    $field = $this._fields | Where-Object { $_.Name -eq $this._expandedFieldName } | Select-Object -First 1
                    $newValue = $this._GetFieldValue($this._expandedFieldName, $field.Type)
                    $this._InvokeCallback($this.OnFieldChanged, @($this._expandedFieldName, $newValue))
                }

                $this._expandedFieldName = ""
                return $true
            }

            return $handled
        }

        # Enter key behavior depends on current field
        if ($keyInfo.Key -eq 'Enter') {
            # Check current field type
            if ($this._currentFieldIndex -ge 0 -and $this._currentFieldIndex -lt $this._fields.Count) {
                $currentField = $this._fields[$this._currentFieldIndex]

                # For Date/Project/Tags fields - expand the widget
                if ($currentField.Type -eq 'date' -or $currentField.Type -eq 'project' -or $currentField.Type -eq 'tags') {
                    Write-PmcTuiLog "InlineEditor: Enter on $($currentField.Type) field - expanding widget" "DEBUG"
                    $this._ExpandCurrentField()
                    return $true
                }

                # For other fields - move to next field (or validate if last field)
                if ($this._currentFieldIndex -eq $this._fields.Count - 1) {
                    # Last field - validate and confirm
                    if ($this._ValidateAllFields()) {
                        Write-PmcTuiLog "InlineEditor: Validation passed, confirming" "DEBUG"
                        $this.IsConfirmed = $true
                        $values = $this.GetValues()
                        $this._InvokeCallback($this.OnConfirmed, $values)
                        return $true
                    } else {
                        # Validation failed - show errors and stay open
                        Write-PmcTuiLog "InlineEditor: Validation FAILED - Errors: $($this._validationErrors -join ', ')" "ERROR"
                        $this._InvokeCallback($this.OnValidationFailed, $this._validationErrors)
                        return $true
                    }
                } else {
                    # Not last field - move to next
                    $this._MoveToNextField()
                    return $true
                }
            }

            # No field selected - validate and confirm
            if ($this._ValidateAllFields()) {
                $this.IsConfirmed = $true
                $values = $this.GetValues()
                $this._InvokeCallback($this.OnConfirmed, $values)
                return $true
            }
            return $true
        }

        if ($keyInfo.Key -eq 'Escape') {
            $this.IsCancelled = $true
            $this._InvokeCallback($this.OnCancelled, $null)
            return $true
        }

        # Tab - move to next field
        if ($keyInfo.Key -eq 'Tab') {
            if ($keyInfo.Modifiers -band [ConsoleModifiers]::Shift) {
                # Shift+Tab - previous field
                $this._MoveToPreviousField()
            } else {
                # Tab - next field
                $this._MoveToNextField()
            }
            return $true
        }

        # Up/Down arrows - navigate fields
        if ($keyInfo.Key -eq 'UpArrow') {
            $this._MoveToPreviousField()
            return $true
        }

        if ($keyInfo.Key -eq 'DownArrow') {
            $this._MoveToNextField()
            return $true
        }

        # Left/Right arrows - adjust number fields inline
        if ($this._currentFieldIndex -ge 0 -and $this._currentFieldIndex -lt $this._fields.Count) {
            $currentField = $this._fields[$this._currentFieldIndex]

            if ($currentField.Type -eq 'number') {
                $min = if ($currentField.ContainsKey('Min')) { $currentField.Min } else { 0 }
                $max = if ($currentField.ContainsKey('Max')) { $currentField.Max } else { 10 }
                $currentValue = $this._GetFieldValue($currentField.Name, 'number')
                if ($null -eq $currentValue) { $currentValue = $min }

                if ($keyInfo.Key -eq 'LeftArrow' -and $currentValue -gt $min) {
                    $this._SetFieldValue($currentField.Name, $currentValue - 1)
                    return $true
                }

                if ($keyInfo.Key -eq 'RightArrow' -and $currentValue -lt $max) {
                    $this._SetFieldValue($currentField.Name, $currentValue + 1)
                    return $true
                }
            }
        }

        # Space or F2 - expand current field widget (DatePicker, ProjectPicker, etc.)
        if ($keyInfo.Key -eq 'Spacebar' -or $keyInfo.Key -eq 'F2') {
            $this._ExpandCurrentField()
            return $true
        }

        # For all fields with widgets, allow direct typing (inline editing)
        if ($this._currentFieldIndex -ge 0 -and $this._currentFieldIndex -lt $this._fields.Count) {
            $currentField = $this._fields[$this._currentFieldIndex]

            # Text fields - pass input to widget (except Tab/Up/Down for navigation)
            if ($currentField.Type -eq 'text') {
                # Don't pass navigation keys to widget - let InlineEditor handle them
                if ($keyInfo.Key -eq 'Tab' -or $keyInfo.Key -eq 'UpArrow' -or $keyInfo.Key -eq 'DownArrow') {
                    return $false  # Let InlineEditor handle navigation
                }

                if (-not $this._fieldWidgets.ContainsKey($currentField.Name)) {
                    return $false
                }

                $widget = $this._fieldWidgets[$currentField.Name]
                return $widget.HandleInput($keyInfo)
            }

            # Date/Project/Tags fields - press Space or F2 to expand widget
            # Tab/Up/Down to navigate through without expanding
        }

        return $false
    }

    <#
    .SYNOPSIS
    Render the inline editor

    .OUTPUTS
    ANSI string ready for display
    #>
    [string] Render() {
        $sb = [StringBuilder]::new(4096)

        # Colors from theme
        $borderColor = $this.GetThemedAnsi('Border', $false)
        $textColor = $this.GetThemedAnsi('Text', $false)
        $primaryColor = $this.GetThemedAnsi('Primary', $false)
        $mutedColor = $this.GetThemedAnsi('Muted', $false)
        $errorColor = $this.GetThemedAnsi('Error', $false)
        $successColor = $this.GetThemedAnsi('Success', $false)
        $highlightBg = $this.GetThemedAnsi('Primary', $true)
        $reset = "`e[0m"

        # If a field widget is expanded, render it instead of the form
        if ($this._showFieldWidgets -and -not [string]::IsNullOrWhiteSpace($this._expandedFieldName)) {
            $widget = $this._fieldWidgets[$this._expandedFieldName]
            return $widget.Render()
        }

        # Draw top border
        $sb.Append($this.BuildMoveTo($this.X, $this.Y))
        $sb.Append($borderColor)
        $sb.Append($this.BuildBoxBorder($this.Width, 'top', 'single'))

        # Title
        $titleText = " $($this.Title) "
        $titlePos = 2
        $sb.Append($this.BuildMoveTo($this.X + $titlePos, $this.Y))
        $sb.Append($primaryColor)
        $sb.Append($titleText)

        # Field count
        $countText = "($($this._fields.Count) fields)"
        $sb.Append($this.BuildMoveTo($this.X + $this.Width - $countText.Length - 2, $this.Y))
        $sb.Append($mutedColor)
        $sb.Append($countText)

        $currentRow = 1

        # Render each field
        for ($i = 0; $i -lt $this._fields.Count; $i++) {
            $field = $this._fields[$i]
            $isFocused = ($i -eq $this._currentFieldIndex)

            # Field row
            $rowY = $this.Y + $currentRow

            # Label row
            $sb.Append($this.BuildMoveTo($this.X, $rowY))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            # Label
            $label = $field.Label
            $isRequired = $false
            if ($field -is [hashtable] -and $field.ContainsKey('Required')) {
                $isRequired = $field.Required
            } elseif ($field.PSObject.Properties['Required']) {
                $isRequired = $field.Required
            }
            if ($isRequired) {
                $label += " *"
            }

            $sb.Append($this.BuildMoveTo($this.X + 2, $rowY))
            if ($isFocused) {
                $sb.Append($primaryColor)
            } else {
                $sb.Append($mutedColor)
            }
            $sb.Append($this.PadText($label + ":", 20, 'left'))

            # Value preview
            $sb.Append($this.BuildMoveTo($this.X + 22, $rowY))
            if ($isFocused) {
                $sb.Append($highlightBg)
                $sb.Append("`e[30m")
            } else {
                $sb.Append($textColor)
            }

            $valuePreview = $this._GetFieldValuePreview($field)
            $sb.Append($this.PadText($valuePreview, $this.Width - 24, 'left'))

            if ($isFocused) {
                $sb.Append($reset)
            }

            # Right border
            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $rowY))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))

            $currentRow++

            # Spacing row
            $sb.Append($this.BuildMoveTo($this.X, $this.Y + $currentRow))
            $sb.Append($borderColor)
            $sb.Append($this.GetBoxChar('single_vertical'))
            $sb.Append(" " * ($this.Width - 2))
            $sb.Append($this.GetBoxChar('single_vertical'))

            $currentRow++
        }

        # Help text row
        $helpRowY = $this.Y + $currentRow
        $sb.Append($this.BuildMoveTo($this.X, $helpRowY))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))

        $sb.Append($this.BuildMoveTo($this.X + 2, $helpRowY))
        $sb.Append($mutedColor)
        $helpText = "Tab: Next | Space: Edit | Enter: Save | Esc: Cancel"
        $sb.Append($this.TruncateText($helpText, $this.Width - 4))

        $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $helpRowY))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))

        $currentRow++

        # Validation errors row
        $errorRowY = $this.Y + $currentRow
        $sb.Append($this.BuildMoveTo($this.X, $errorRowY))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))

        if ($this._validationErrors.Count -gt 0) {
            $sb.Append($this.BuildMoveTo($this.X + 2, $errorRowY))
            $sb.Append($errorColor)
            $errorMsg = $this._validationErrors[0]  # Show first error
            $sb.Append($this.TruncateText($errorMsg, $this.Width - 4))
        } else {
            $sb.Append(" " * ($this.Width - 2))
        }

        $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $errorRowY))
        $sb.Append($borderColor)
        $sb.Append($this.GetBoxChar('single_vertical'))

        $currentRow++

        # Bottom border
        $sb.Append($this.BuildMoveTo($this.X, $this.Y + $currentRow))
        $sb.Append($borderColor)
        $sb.Append($this.BuildBoxBorder($this.Width, 'bottom', 'single'))

        $sb.Append($reset)
        return $sb.ToString()
    }

    # === Private Helper Methods ===

    <#
    .SYNOPSIS
    Create widget instance for a field
    #>
    hidden [void] _CreateFieldWidget([hashtable]$fieldDef) {
        $fieldName = $fieldDef.Name
        $fieldType = $fieldDef.Type
        $value = if ($fieldDef.ContainsKey('Value')) { $fieldDef.Value } else { $null }

        $widget = $null

        switch ($fieldType) {
            'text' {
                $widget = [TextInput]::new()
                $widget.SetPosition($this.X + 5, $this.Y + 5)
                $widget.SetSize(60, 3)
                $widget.Label = $fieldDef.Label

                if ($value) {
                    $widget.SetText($value)
                }

                if ($fieldDef.ContainsKey('MaxLength')) {
                    $widget.MaxLength = $fieldDef.MaxLength
                }

                if ($fieldDef.ContainsKey('Placeholder')) {
                    $widget.Placeholder = $fieldDef.Placeholder
                }
            }

            'date' {
                $widget = [DatePicker]::new()
                $widget.SetPosition($this.X + 5, $this.Y + 5)
                $widget.SetSize(35, 14)

                if ($value -and $value -is [DateTime]) {
                    $widget.SetDate($value)
                }
            }

            'project' {
                $widget = [ProjectPicker]::new()
                $widget.SetPosition($this.X + 5, $this.Y + 5)
                $widget.SetSize(35, 12)
                $widget.Label = $fieldDef.Label

                if ($value) {
                    $widget.SetSearchText($value)
                }
            }

            'tags' {
                $widget = [TagEditor]::new()
                $widget.SetPosition($this.X + 5, $this.Y + 5)
                $widget.SetSize(60, 8)
                $widget.Label = $fieldDef.Label

                if ($value -and $value -is [array]) {
                    $widget.SetTags($value)
                }
            }

            'number' {
                # Number is handled inline (no separate widget)
                # Store value in field definition
                if (-not $fieldDef.ContainsKey('Value')) {
                    $fieldDef.Value = if ($fieldDef.ContainsKey('Min')) { $fieldDef.Min } else { 0 }
                }
            }

            default {
                throw "Unsupported field type: $fieldType"
            }
        }

        if ($widget) {
            $this._fieldWidgets[$fieldName] = $widget
        }
    }

    <#
    .SYNOPSIS
    Get current value of a field
    #>
    hidden [object] _GetFieldValue([string]$fieldName, [string]$fieldType) {
        switch ($fieldType) {
            'text' {
                $widget = $this._fieldWidgets[$fieldName]
                return $widget.GetText()
            }

            'date' {
                $widget = $this._fieldWidgets[$fieldName]
                return $widget.GetSelectedDate()
            }

            'project' {
                $widget = $this._fieldWidgets[$fieldName]
                return $widget.GetSelectedProject()
            }

            'tags' {
                $widget = $this._fieldWidgets[$fieldName]
                return $widget.GetTags()
            }

            'number' {
                $field = $this._fields | Where-Object { $_.Name -eq $fieldName } | Select-Object -First 1
                if ($field.ContainsKey('Value')) {
                    return $field.Value
                } else {
                    return 0
                }
            }

            default {
                return $null
            }
        }
        # Fallback (should never reach here)
        return $null
    }

    <#
    .SYNOPSIS
    Set field value (for inline editing)
    #>
    hidden [void] _SetFieldValue([string]$fieldName, [object]$value) {
        # Find the field
        $field = $this._fields | Where-Object { $_.Name -eq $fieldName } | Select-Object -First 1
        if ($null -eq $field) {
            return
        }

        # Update the field's Value property
        $field.Value = $value
    }

    <#
    .SYNOPSIS
    Get preview string for field value
    #>
    hidden [string] _GetFieldValuePreview([hashtable]$field) {
        $fieldName = $field.Name
        $fieldType = $field.Type
        $value = $this._GetFieldValue($fieldName, $fieldType)

        switch ($fieldType) {
            'text' {
                if ([string]::IsNullOrWhiteSpace($value)) {
                    return "(empty)"
                }
                return $value
            }

            'date' {
                if ($value -is [DateTime]) {
                    return $value.ToString("yyyy-MM-dd (ddd)")
                }
                return "(no date)"
            }

            'project' {
                if ([string]::IsNullOrWhiteSpace($value)) {
                    return "(no project)"
                }
                return $value
            }

            'tags' {
                if ($null -eq $value -or $value.Count -eq 0) {
                    return "(no tags)"
                }
                return "[" + ($value -join "] [") + "]"
            }

            'number' {
                $min = if ($field.ContainsKey('Min')) { $field.Min } else { 0 }
                $max = if ($field.ContainsKey('Max')) { $field.Max } else { 10 }
                $val = if ($null -ne $value) { $value } else { $min }

                # Build visual slider
                $range = $max - $min
                $position = if ($range -gt 0) { [Math]::Floor(($val - $min) / $range * 10) } else { 0 }
                $slider = "[" + ("-" * $position) + "●" + ("-" * (10 - $position)) + "] $val"
                return $slider
            }

            default {
                return "(unknown)"
            }
        }
        # Fallback (should never reach here)
        return "(unknown)"
    }

    <#
    .SYNOPSIS
    Move to next field
    #>
    hidden [void] _MoveToNextField() {
        if ($this._currentFieldIndex -lt ($this._fields.Count - 1)) {
            $this._currentFieldIndex++
            $this._validationErrors = @()
        } else {
            # Wrap to first field
            $this._currentFieldIndex = 0
        }
    }

    <#
    .SYNOPSIS
    Move to previous field
    #>
    hidden [void] _MoveToPreviousField() {
        if ($this._currentFieldIndex -gt 0) {
            $this._currentFieldIndex--
            $this._validationErrors = @()
        } else {
            # Wrap to last field
            $this._currentFieldIndex = $this._fields.Count - 1
        }
    }

    <#
    .SYNOPSIS
    Expand current field's widget
    #>
    hidden [void] _ExpandCurrentField() {
        if ($this._currentFieldIndex -ge 0 -and $this._currentFieldIndex -lt $this._fields.Count) {
            $field = $this._fields[$this._currentFieldIndex]

            # Number fields are handled inline
            if ($field.Type -eq 'number') {
                # Show number adjustment UI (TODO: implement arrow key adjustment)
                return
            }

            $this._expandedFieldName = $field.Name
            $this._showFieldWidgets = $true

            # Reset widget state
            $widget = $this._fieldWidgets[$field.Name]
            $widget.IsConfirmed = $false
            $widget.IsCancelled = $false
        }
    }

    <#
    .SYNOPSIS
    Validate all fields

    .OUTPUTS
    True if all fields valid, False otherwise
    #>
    hidden [bool] _ValidateAllFields() {
        $this._validationErrors = @()

        foreach ($field in $this._fields) {
            $fieldName = $field.Name
            $fieldType = $field.Type
            $isRequired = if ($field.ContainsKey('Required')) { $field.Required } else { $false }

            $value = $this._GetFieldValue($fieldName, $fieldType)

            # Check required fields
            if ($isRequired) {
                $isEmpty = $false

                switch ($fieldType) {
                    'text' {
                        $isEmpty = [string]::IsNullOrWhiteSpace($value)
                    }
                    'date' {
                        $isEmpty = ($null -eq $value)
                    }
                    'project' {
                        $isEmpty = [string]::IsNullOrWhiteSpace($value)
                    }
                    'tags' {
                        $isEmpty = ($null -eq $value -or $value.Count -eq 0)
                    }
                    'number' {
                        $isEmpty = ($null -eq $value)
                    }
                }

                if ($isEmpty) {
                    $this._validationErrors += "$($field.Label) is required"
                }
            }

            # Type-specific validation
            if ($fieldType -eq 'number' -and $null -ne $value) {
                $min = if ($field.ContainsKey('Min')) { $field.Min } else { [int]::MinValue }
                $max = if ($field.ContainsKey('Max')) { $field.Max } else { [int]::MaxValue }

                if ($value -lt $min) {
                    $this._validationErrors += "$($field.Label) must be >= $min"
                }

                if ($value -gt $max) {
                    $this._validationErrors += "$($field.Label) must be <= $max"
                }
            }
        }

        return $this._validationErrors.Count -eq 0
    }

    <#
    .SYNOPSIS
    Invoke callback safely
    #>
    hidden [void] _InvokeCallback([scriptblock]$callback, $args) {
        if ($null -ne $callback -and $callback -ne {}) {
            try {
                if ($null -ne $args) {
                    & $callback $args
                } else {
                    & $callback
                }
            } catch {
                # Silently ignore callback errors
            }
        }
    }
}
