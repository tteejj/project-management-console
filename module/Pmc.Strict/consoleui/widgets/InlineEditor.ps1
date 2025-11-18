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

Set-StrictMode -Version Latest

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
    [string]$LayoutMode = "vertical"           # "vertical" (default) or "horizontal" (compact inline mode)

    # === Event Callbacks ===
    [scriptblock]$OnFieldChanged = {}          # Called when field changes: param($fieldName, $value)
    [scriptblock]$OnConfirmed = {}             # Called when Enter pressed: param($allValues)
    [scriptblock]$OnCancelled = {}             # Called when Esc pressed
    [scriptblock]$OnValidationFailed = {}      # Called when validation fails: param($errors)

    # === State Flags ===
    [bool]$IsConfirmed = $false                # True when Enter pressed and validated
    [bool]$IsCancelled = $false                # True when Esc pressed
    [bool]$NeedsClear = $false                 # True when field widget was closed and screen needs clear

    # === Private State ===
    hidden [List[hashtable]]$_fields = [List[hashtable]]::new()      # Field definition
    hidden [hashtable]$_fieldWidgets = @{}                           # Widget instances keyed by field name
    hidden [hashtable]$_datePickerWidgets = @{}                      # DatePicker instances for date fields (kept separate from TextInput)
    hidden [int]$_currentFieldIndex = 0                              # Currently focused field
    hidden [string[]]$_validationErrors = @()                        # Current validation errors
    hidden [hashtable]$_fieldErrors = @{}                            # H-UI-3: Per-field validation errors for real-time display
    hidden [bool]$_showFieldWidgets = $false                         # Whether to show expanded field widget
    hidden [string]$_expandedFieldName = ""                          # Name of currently expanded field
    hidden [bool]$_datePickerMode = $false                           # True when DatePicker is active (not TextInput)

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
        # Note: Old widget references cleared from dictionaries
        # PowerShell GC will clean up. Widgets don't register external event handlers.
        $this._fieldWidgets.Clear()
        $this._datePickerWidgets.Clear()
        $this._currentFieldIndex = 0
        $this._validationErrors = @()
        $this._datePickerMode = $false

        # Reset state flags
        $this.IsConfirmed = $false
        $this.IsCancelled = $false

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

        # Add Save button as last field
        $saveButton = @{
            Name = '__save_button__'
            Label = ''
            Type = 'button'
            ButtonText = 'Save'
        }
        $this._fields.Add($saveButton)

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
        Write-PmcTuiLog "GetValues: Starting, _fields count=$($this._fields.Count)" "DEBUG"
        $values = @{}

        foreach ($field in $this._fields) {
            $fieldName = $field.Name
            $fieldType = $field.Type

            Write-PmcTuiLog "GetValues: Processing field=$fieldName type=$fieldType" "DEBUG"

            # Skip button fields
            if ($fieldType -eq 'button') {
                continue
            }

            $value = $this._GetFieldValue($fieldName, $fieldType)
            Write-PmcTuiLog "GetValues: Field $fieldName value=$value" "DEBUG"
            $values[$fieldName] = $value
        }

        Write-PmcTuiLog "GetValues: Returning hashtable with $($values.Keys.Count) keys: $($values.Keys -join ', ')" "DEBUG"
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
            $this._datePickerMode = $false
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
                $this._datePickerMode = $false
                return $true
            }

            # Get the appropriate widget based on mode
            $widget = $null
            $field = $this._fields | Where-Object { $_.Name -eq $this._expandedFieldName } | Select-Object -First 1

            if ($field.Type -eq 'date' -and $this._datePickerMode) {
                # Use DatePicker when in DatePicker mode
                $widget = $this._datePickerWidgets[$this._expandedFieldName]
            } else {
                # Use normal widget
                $widget = $this._fieldWidgets[$this._expandedFieldName]
            }

            # Check for widget-specific completion
            $handled = $widget.HandleInput($keyInfo)

            # Check if widget confirmed or cancelled
            # PmcFilePicker uses IsComplete instead of IsConfirmed/IsCancelled
            $isComplete = $false
            if ($widget.PSObject.Properties['IsComplete']) {
                $isComplete = $widget.IsComplete
            } elseif ($widget.PSObject.Properties['IsConfirmed']) {
                $isComplete = $widget.IsConfirmed -or $widget.IsCancelled
            }

            if ($isComplete) {
                # For date fields in DatePicker mode, update TextInput with selected date
                if ($field.Type -eq 'date' -and $this._datePickerMode) {
                    # Get selected date from DatePicker
                    $selectedDate = if ($widget.IsConfirmed) { $widget.GetSelectedDate() } else { $null }

                    if ($selectedDate) {
                        # Update the TextInput widget (which is still stored in _fieldWidgets)
                        $textWidget = $this._fieldWidgets[$this._expandedFieldName]
                        $textWidget.SetText($selectedDate.ToString('yyyy-MM-dd'))
                        # Update field value
                        $field.Value = $selectedDate
                    }
                }

                # For folder fields, update TextInput with selected path
                if ($field.Type -eq 'folder' -and $widget.PSObject.Properties['IsComplete'] -and $widget.IsComplete) {
                    Write-PmcTuiLog "InlineEditor: Folder picker complete - Result=$($widget.Result) SelectedPath='$($widget.SelectedPath)'" "DEBUG"

                    # Get selected path from FilePicker
                    $selectedPath = if ($widget.Result) { $widget.SelectedPath } else { '' }

                    Write-PmcTuiLog "InlineEditor: Setting folder field value to '$selectedPath'" "DEBUG"

                    # Recreate TextInput and restore it
                    $textWidget = [TextInput]::new()
                    $textWidget.MaxLength = 255
                    $textWidget.Placeholder = 'Press Enter to browse...'
                    $textWidget.SetText($selectedPath)

                    # Restore TextInput in place of FilePicker
                    $this._fieldWidgets[$this._expandedFieldName] = $textWidget

                    # Update field value
                    $field.Value = $selectedPath

                    Write-PmcTuiLog "InlineEditor: Folder field updated - field.Value='$($field.Value)'" "DEBUG"
                }

                # Collapse widget
                $this._showFieldWidgets = $false
                $this._datePickerMode = $false
                $this.NeedsClear = $true  # Request full screen clear to remove widget

                # Get value from widget and update field BEFORE collapsing
                # Only for widgets that have IsConfirmed property (not PmcFilePicker which uses Result)
                if ($widget.PSObject.Properties['IsConfirmed'] -and $widget.IsConfirmed) {
                    # For tags, get tags directly from TagEditor
                    if ($field.Type -eq 'tags') {
                        $field.Value = $widget.GetTags()
                    }
                    # For project, get selected project
                    elseif ($field.Type -eq 'project') {
                        $field.Value = $widget.GetSelectedProject()
                    }

                    $this._InvokeCallback($this.OnFieldChanged, @($this._expandedFieldName, $field.Value))
                }

                # For PmcFilePicker, trigger callback if Result is true
                if ($field.Type -eq 'folder' -and $widget.PSObject.Properties['Result'] -and $widget.Result) {
                    $this._InvokeCallback($this.OnFieldChanged, @($this._expandedFieldName, $field.Value))
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

                # For Button type - validate and save
                if ($currentField.Type -eq 'button') {
                    if ($this._ValidateAllFields()) {
                        Write-PmcTuiLog "InlineEditor: Save button pressed - Saving form" "DEBUG"
                        $this.IsConfirmed = $true
                        $values = $this.GetValues()
                        $this._InvokeCallback($this.OnConfirmed, $values)
                        return $true
                    } else {
                        Write-PmcTuiLog "InlineEditor: Validation FAILED - Errors: $($this._validationErrors -join ', ')" "ERROR"
                        $this._InvokeCallback($this.OnValidationFailed, $this._validationErrors)
                        return $true
                    }
                }

                # For Date/Project/Folder fields - expand the widget (NOT tags, tags is inline text now)
                if ($currentField.Type -eq 'date' -or $currentField.Type -eq 'project' -or $currentField.Type -eq 'folder') {
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
                $step = if ($currentField.ContainsKey('Step')) { $currentField.Step } else { 1 }
                $currentValue = $this._GetFieldValue($currentField.Name, 'number')
                if ($null -eq $currentValue) { $currentValue = $min }

                if ($keyInfo.Key -eq 'LeftArrow' -and $currentValue -gt $min) {
                    $this._SetFieldValue($currentField.Name, $currentValue - $step)
                    return $true
                }

                if ($keyInfo.Key -eq 'RightArrow' -and $currentValue -lt $max) {
                    $this._SetFieldValue($currentField.Name, $currentValue + $step)
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

            # Text, Textarea, Date, and Tags fields - pass input to widget (except Tab/Up/Down for navigation)
            if ($currentField.Type -eq 'text' -or $currentField.Type -eq 'textarea' -or $currentField.Type -eq 'date' -or $currentField.Type -eq 'tags') {
                # Don't pass navigation keys to widget - let InlineEditor handle them
                if ($keyInfo.Key -eq 'Tab' -or $keyInfo.Key -eq 'UpArrow' -or $keyInfo.Key -eq 'DownArrow') {
                    return $false  # Let InlineEditor handle navigation
                }

                # Clear validation errors when user starts editing a field
                # This prevents stale error messages from appearing while the user is actively typing
                # Skip for navigation and submission keys
                if ($keyInfo.Key -ne 'Enter') {
                    $this._validationErrors = @()
                }

                if (-not $this._fieldWidgets.ContainsKey($currentField.Name)) {
                    return $false
                }

                $widget = $this._fieldWidgets[$currentField.Name]
                # Handle input for TextInput
                if ($widget.GetType().Name -eq 'TextInput') {
                    $handled = $widget.HandleInput($keyInfo)

                    # H-UI-3: Real-time validation - validate after each keystroke
                    if ($handled -and $keyInfo.Key -ne 'Enter' -and $keyInfo.Key -ne 'Escape') {
                        $this._ValidateFieldRealtime($currentField)
                    }

                    return $handled
                }
                return $false
            }

            # Project/Tags fields - press Enter/Space/F2 to expand widget
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
            # Get the appropriate widget based on mode
            $field = $this._fields | Where-Object { $_.Name -eq $this._expandedFieldName } | Select-Object -First 1

            $widget = $null
            if ($field.Type -eq 'date' -and $this._datePickerMode) {
                # Render DatePicker when in DatePicker mode
                if ($this._datePickerWidgets.ContainsKey($this._expandedFieldName)) {
                    $widget = $this._datePickerWidgets[$this._expandedFieldName]
                }
            } else {
                # Render normal widget
                if ($this._fieldWidgets.ContainsKey($this._expandedFieldName)) {
                    $widget = $this._fieldWidgets[$this._expandedFieldName]
                }
            }

            if ($null -ne $widget) {
                # Check if widget is PmcFilePicker (needs terminal dimensions)
                if ($widget.GetType().Name -eq 'PmcFilePicker') {
                    # Get terminal size
                    try {
                        $termWidth = [Console]::WindowWidth
                        $termHeight = [Console]::WindowHeight
                    } catch {
                        $termWidth = 120
                        $termHeight = 40
                    }

                    if ($global:PmcTuiLogFile) {
                        Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] InlineEditor: Rendering PmcFilePicker with termWidth=$termWidth, termHeight=$termHeight"
                    }

                    # Force full redraw for FilePicker every frame to avoid diff issues
                    $this.NeedsClear = $true

                    $output = $widget.Render($termWidth, $termHeight)

                    if ($global:PmcTuiLogFile) {
                        Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] InlineEditor: PmcFilePicker render returned length=$($output.Length)"
                    }

                    return $output
                } else {
                    return $widget.Render()
                }
            }

            # Widget doesn't exist - fall through to render normal form
            $this._showFieldWidgets = $false
            $this._expandedFieldName = ""
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
            # H-UI-3: Show red border if field has validation error
            $hasError = $this._fieldErrors.ContainsKey($field.Name)
            if ($hasError) {
                $sb.Append($errorColor)
            } else {
                $sb.Append($borderColor)
            }
            $sb.Append($this.GetBoxChar('single_vertical'))

            # Label
            $label = Get-SafeProperty $field 'Label'
            $isRequired = Get-SafeProperty $field 'Required' $false
            if ($isRequired) {
                $label += " *"
            }

            $sb.Append($this.BuildMoveTo($this.X + 2, $rowY))
            if ($hasError) {
                # H-UI-3: Red text for invalid field label
                $sb.Append($errorColor)
            } elseif ($isFocused) {
                $sb.Append($primaryColor)
            } else {
                $sb.Append($mutedColor)
            }
            $sb.Append($this.PadText($label + ":", 20, 'left'))

            # Value display - for text/date fields, render the TextInput widget inline
            $sb.Append($this.BuildMoveTo($this.X + 22, $rowY))

            if (($field.Type -eq 'text' -or $field.Type -eq 'textarea' -or $field.Type -eq 'date' -or $field.Type -eq 'tags') -and $isFocused -and $this._fieldWidgets.ContainsKey($field.Name)) {
                # Render TextInput widget inline for focused text/textarea/date/tags fields
                $widget = $this._fieldWidgets[$field.Name]
                if ($widget.GetType().Name -eq 'TextInput') {
                    $sb.Append($textColor)
                    $text = $widget.GetText()
                    $cursorPos = $widget._cursorPosition

                    # Show text with cursor
                    if ($cursorPos -le $text.Length) {
                        $beforeCursor = $text.Substring(0, $cursorPos)
                        $atCursor = if ($cursorPos -lt $text.Length) { $text.Substring($cursorPos, 1) } else { " " }
                        $afterCursor = if ($cursorPos -lt $text.Length - 1) { $text.Substring($cursorPos + 1) } else { "" }

                        $sb.Append($beforeCursor)
                        $sb.Append($highlightBg)
                        $sb.Append("`e[30m")
                        $sb.Append($atCursor)
                        $sb.Append($reset)
                        $sb.Append($textColor)
                        $sb.Append($afterCursor)
                    } else {
                        $sb.Append($text)
                    }
                    $sb.Append($reset)
                } else {
                    # Not a TextInput, show preview
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
                }
            } else {
                # Not focused or not text/date field - show preview
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
            }

            # Right border
            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $rowY))
            if ($hasError) {
                $sb.Append($errorColor)
            } else {
                $sb.Append($borderColor)
            }
            $sb.Append($this.GetBoxChar('single_vertical'))

            $currentRow++

            # Spacing row (H-UI-3: show error message below field if invalid)
            $sb.Append($this.BuildMoveTo($this.X, $this.Y + $currentRow))
            if ($hasError) {
                $sb.Append($errorColor)
            } else {
                $sb.Append($borderColor)
            }
            $sb.Append($this.GetBoxChar('single_vertical'))

            # H-UI-3: Display per-field error message
            if ($hasError) {
                $errorMsg = $this._fieldErrors[$field.Name]
                $sb.Append($this.BuildMoveTo($this.X + 2, $this.Y + $currentRow))
                $sb.Append($errorColor)
                $sb.Append($this.TruncateText($errorMsg, $this.Width - 4))
            } else {
                $sb.Append(" " * ($this.Width - 2))
            }

            $sb.Append($this.BuildMoveTo($this.X + $this.Width - 1, $this.Y + $currentRow))
            if ($hasError) {
                $sb.Append($errorColor)
            } else {
                $sb.Append($borderColor)
            }
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
        $helpText = "Tab: Next | Enter on Save button | Esc: Cancel"
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

            'textarea' {
                # For now, use TextInput with larger size for multi-line text
                # TODO: Integrate full TextAreaEditor when dependency loading is resolved
                $widget = [TextInput]::new()
                $widget.SetPosition($this.X + 5, $this.Y + 5)
                $widget.SetSize(60, 5)  # Taller than regular text input
                $widget.Label = $fieldDef.Label

                if ($value) {
                    # Replace newlines with a visible separator for single-line display
                    $displayValue = $value.ToString() -replace "`n", " | "
                    $widget.SetText($displayValue)
                }

                if ($fieldDef.ContainsKey('MaxLength')) {
                    $widget.MaxLength = $fieldDef.MaxLength
                } else {
                    $widget.MaxLength = 5000  # Default larger limit for textarea
                }

                $widget.Placeholder = 'Separate items with  | '
            }

            'date' {
                # For inline editing, use TextInput (user can type dates like "2025-11-15" or "+3")
                # DatePicker is created on-demand when user presses Enter
                $widget = [TextInput]::new()
                $widget.MaxLength = 20

                if ($value) {
                    if ($value -is [DateTime]) {
                        $widget.SetText($value.ToString('yyyy-MM-dd'))
                    } else {
                        $widget.SetText($value.ToString())
                    }
                } else {
                    $widget.SetText('')
                }

                $widget.Placeholder = 'yyyy-MM-dd or +days'

                # Wire up text change callback to update field value
                $editor = $this
                $field = $fieldDef
                $widget.OnTextChanged = {
                    param($newText)
                    # Update the field value when text changes
                    $editor._SetFieldValue($field.Name, $newText)
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
                # Tags use simple text input with comma-separated values
                $widget = [TextInput]::new()
                $widget.MaxLength = 100
                $widget.Placeholder = 'tag1, tag2, tag3'

                if ($value -and $value -is [array]) {
                    # Convert array to comma-separated string
                    $widget.SetText($value -join ', ')
                } elseif ($value) {
                    $widget.SetText($value.ToString())
                } else {
                    $widget.SetText('')
                }

                # Wire up callback to save changes
                $editor = $this
                $field = $fieldDef
                $widget.OnTextChanged = {
                    param($newText)
                    $editor._SetFieldValue($field.Name, $newText)
                }
            }

            'folder' {
                # Folder picker - use TextInput for inline display
                $widget = [TextInput]::new()
                $widget.MaxLength = 255
                $widget.Placeholder = 'Press Enter to browse...'

                if ($value) {
                    $widget.SetText($value.ToString())
                } else {
                    $widget.SetText('')
                }

                # Wire up callback
                $editor = $this
                $field = $fieldDef
                $widget.OnTextChanged = {
                    param($newText)
                    $editor._SetFieldValue($field.Name, $newText)
                }
            }

            'number' {
                # Number is handled inline (no separate widget)
                # Store value in field definition
                if (-not $fieldDef.ContainsKey('Value')) {
                    $fieldDef.Value = if ($fieldDef.ContainsKey('Min')) { $fieldDef.Min } else { 0 }
                }
            }

            'button' {
                # Button is handled inline (no separate widget)
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

            'textarea' {
                $widget = $this._fieldWidgets[$fieldName]
                # Convert pipe-separated items back to newline-separated
                $text = $widget.GetText()
                return $text -replace '\s*\|\s*', "`n"
            }

            'date' {
                $widget = $this._fieldWidgets[$fieldName]
                # Date fields use TextInput for inline editing
                if ($widget.GetType().Name -eq 'TextInput') {
                    $dateText = $widget.GetText().Trim().ToLower()
                    if ([string]::IsNullOrWhiteSpace($dateText)) {
                        return $null
                    }

                    # Parse relative dates like "+7" or "-3"
                    if ($dateText -match '^([+-])(\d+)$') {
                        $sign = $matches[1]
                        $days = [int]$matches[2]
                        if ($sign -eq '+') {
                            return [DateTime]::Now.AddDays($days)
                        } else {
                            return [DateTime]::Now.AddDays(-$days)
                        }
                    }

                    # Special keywords
                    if ($dateText -eq 'today' -or $dateText -eq 't') {
                        return [DateTime]::Today
                    }
                    if ($dateText -eq 'tomorrow' -or $dateText -eq 'tom') {
                        return [DateTime]::Today.AddDays(1)
                    }
                    if ($dateText -eq 'yesterday') {
                        return [DateTime]::Today.AddDays(-1)
                    }
                    if ($dateText -eq 'eom') {
                        # End of current month
                        $now = [DateTime]::Now
                        return [DateTime]::new($now.Year, $now.Month, [DateTime]::DaysInMonth($now.Year, $now.Month))
                    }
                    if ($dateText -eq 'eoy') {
                        # End of current year
                        return [DateTime]::new([DateTime]::Now.Year, 12, 31)
                    }
                    if ($dateText -eq 'som') {
                        # Start of current month
                        $now = [DateTime]::Now
                        return [DateTime]::new($now.Year, $now.Month, 1)
                    }

                    # Parse YYYYMMDD format (20251125)
                    if ($dateText -match '^\d{8}$') {
                        try {
                            $year = [int]$dateText.Substring(0, 4)
                            $month = [int]$dateText.Substring(4, 2)
                            $day = [int]$dateText.Substring(6, 2)
                            return [DateTime]::new($year, $month, $day)
                        } catch {
                            # Invalid date, fall through
                        }
                    }

                    # Parse YYMMDD format (251125)
                    if ($dateText -match '^\d{6}$') {
                        try {
                            $year = 2000 + [int]$dateText.Substring(0, 2)
                            $month = [int]$dateText.Substring(2, 2)
                            $day = [int]$dateText.Substring(4, 2)
                            return [DateTime]::new($year, $month, $day)
                        } catch {
                            # Invalid date, fall through
                        }
                    }

                    # Parse absolute dates (standard formats)
                    try {
                        return [DateTime]::Parse($dateText)
                    } catch {
                        return $null
                    }
                } else {
                    # DatePicker (if still using old approach)
                    return $widget.GetSelectedDate()
                }
            }

            'project' {
                $widget = $this._fieldWidgets[$fieldName]
                return $widget.GetSelectedProject()
            }

            'tags' {
                # Tags are stored as comma-separated text in TextInput
                $widget = $this._fieldWidgets[$fieldName]
                $tagsText = $widget.GetText()

                if ([string]::IsNullOrWhiteSpace($tagsText)) {
                    return @()
                }

                # Split by comma and trim
                $tags = $tagsText -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

                # H-VAL-5: Validate tags match pattern ^[a-zA-Z0-9_-]+$
                $validTags = @()
                foreach ($tag in $tags) {
                    if ($tag -match '^[a-zA-Z0-9_-]+$') {
                        $validTags += $tag
                    }
                    else {
                        Write-PmcTuiLog "InlineEditor: Invalid tag '$tag' - must contain only letters, numbers, underscore, or hyphen" "WARNING"
                    }
                }

                return @($validTags)
            }

            'folder' {
                # Folder path stored as text in TextInput (or PmcFilePicker if still expanded)
                $widget = $this._fieldWidgets[$fieldName]
                if ($widget.GetType().Name -eq 'PmcFilePicker') {
                    # Still showing picker - return current path
                    return $widget.CurrentPath
                } else {
                    # TextInput - return text
                    return $widget.GetText()
                }
            }

            'number' {
                $field = $this._fields | Where-Object { $_.Name -eq $fieldName } | Select-Object -First 1
                if ($field.ContainsKey('Value')) {
                    return $field.Value
                } else {
                    return 0
                }
            }

            'button' {
                return $null
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
                # Show raw text from TextInput if it exists
                if ($this._fieldWidgets.ContainsKey($fieldName)) {
                    $widget = $this._fieldWidgets[$fieldName]
                    if ($widget.GetType().Name -eq 'TextInput') {
                        $text = $widget.GetText()
                        if (-not [string]::IsNullOrWhiteSpace($text)) {
                            return $text
                        }
                    }
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

            'button' {
                $buttonText = if ($field.ContainsKey('ButtonText')) { $field.ButtonText } else { 'Button' }
                return "[ $buttonText ]"
            }

            'folder' {
                if ([string]::IsNullOrWhiteSpace($value)) {
                    return "(no folder)"
                }
                return $value
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

            # Text, Textarea, Tags, Number, and Button fields are handled inline (no expansion)
            if ($field.Type -eq 'text' -or $field.Type -eq 'textarea' -or $field.Type -eq 'tags' -or $field.Type -eq 'number' -or $field.Type -eq 'button') {
                return
            }

            # For folder fields, create PmcFilePicker on demand
            if ($field.Type -eq 'folder') {
                # Load PmcFilePicker if not already loaded
                . "$PSScriptRoot/PmcFilePicker.ps1"

                # Get current value from TextInput widget
                $textWidget = $this._fieldWidgets[$field.Name]
                $currentPath = $textWidget.GetText()

                # Create FilePicker using Add-Type to avoid parse-time type dependency
                $filePickerType = 'PmcFilePicker' -as [Type]
                $filePicker = $filePickerType::new($currentPath, $true)  # true = directories only
                $filePicker.Width = 70
                $filePicker.Height = 20

                # Replace the TextInput with FilePicker temporarily
                $this._fieldWidgets[$field.Name] = $filePicker

                $this._expandedFieldName = $field.Name
                $this._showFieldWidgets = $true
                $this.NeedsClear = $true  # Force full screen redraw to show all items correctly

                $filePicker.IsComplete = $false
                $filePicker.Result = $false
                return
            }

            # For date fields, create DatePicker on demand (if not already created)
            if ($field.Type -eq 'date') {
                # Get current value from TextInput widget (which stays in _fieldWidgets)
                $textWidget = $this._fieldWidgets[$field.Name]
                $currentText = $textWidget.GetText()

                # Create or reuse DatePicker (stored separately)
                if (-not $this._datePickerWidgets.ContainsKey($field.Name)) {
                    # Create DatePicker in CALENDAR mode (not text mode)
                    $datePicker = [DatePicker]::new()
                    $datePicker.SetPosition($this.X + 5, $this.Y + 5)
                    $datePicker.SetSize(35, 14)

                    # Force calendar mode (not text input mode)
                    $datePicker._isCalendarMode = $true

                    # Store DatePicker separately
                    $this._datePickerWidgets[$field.Name] = $datePicker
                }

                # Get the DatePicker
                $datePicker = $this._datePickerWidgets[$field.Name]

                # Parse current text value to DateTime if possible
                if (-not [string]::IsNullOrWhiteSpace($currentText)) {
                    try {
                        $parsedDate = [DateTime]::Parse($currentText)
                        $datePicker.SetDate($parsedDate)
                    } catch {
                        # Invalid date, use today
                        $datePicker.SetDate([DateTime]::Now)
                    }
                } else {
                    # No text, use today
                    $datePicker.SetDate([DateTime]::Now)
                }

                # Set mode to DatePicker
                $this._datePickerMode = $true

                # Reset DatePicker state
                $datePicker.IsConfirmed = $false
                $datePicker.IsCancelled = $false
            }

            $this._expandedFieldName = $field.Name
            $this._showFieldWidgets = $true

            # Reset widget state for non-date fields
            if ($field.Type -ne 'date') {
                $widget = $this._fieldWidgets[$field.Name]
                $widget.IsConfirmed = $false
                $widget.IsCancelled = $false
            }
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
    H-UI-3: Validate a single field in real-time (as user types)
    #>
    hidden [void] _ValidateFieldRealtime([hashtable]$field) {
        $fieldName = $field.Name
        $fieldType = $field.Type
        $isRequired = if ($field.ContainsKey('Required')) { $field.Required } else { $false }

        # Get current value
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
                $this._fieldErrors[$fieldName] = "$($field.Label) is required"
                return
            }
        }

        # Type-specific validation
        if ($fieldType -eq 'number' -and $null -ne $value) {
            $min = if ($field.ContainsKey('Min')) { $field.Min } else { [int]::MinValue }
            $max = if ($field.ContainsKey('Max')) { $field.Max } else { [int]::MaxValue }

            if ($value -lt $min) {
                $this._fieldErrors[$fieldName] = "$($field.Label) must be >= $min"
                return
            }

            if ($value -gt $max) {
                $this._fieldErrors[$fieldName] = "$($field.Label) must be <= $max"
                return
            }
        }

        # Field is valid - remove error
        $this._fieldErrors.Remove($fieldName)
    }

    <#
    .SYNOPSIS
    Invoke callback safely
    #>
    hidden [void] _InvokeCallback([scriptblock]$callback, $arg) {
        if ($null -ne $callback -and $callback -ne {}) {
            try {
                if ($null -ne $arg) {
                    # Use Invoke-Command with -ArgumentList to pass single arg without array wrapping
                    Invoke-Command -ScriptBlock $callback -ArgumentList (,$arg)
                } else {
                    & $callback
                }
            } catch {
                # Log callback errors but DON'T rethrow - callbacks must never crash the app
                if (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue) {
                    Write-PmcTuiLog "InlineEditor callback error: $($_.Exception.Message)" "ERROR"
                    Write-PmcTuiLog "Callback code: $($callback.ToString())" "ERROR"
                    Write-PmcTuiLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
                }
                # DON'T rethrow - form submission callbacks must not crash
            }
        }
    }
}
