# CellEditorRegistry.ps1
# Factory for creating and managing cell editors in EditableGrid

class CellEditorRegistry {
    # Registry of column -> editor mappings
    hidden [hashtable]$_columnEditors = @{}

    # Default editors by type
    hidden [TextCellEditor]$_defaultTextEditor
    hidden [NumberCellEditor]$_defaultNumberEditor
    hidden [CheckboxCellEditor]$_defaultCheckboxEditor

    # Constructor
    CellEditorRegistry() {
        # Initialize default editors
        $this._defaultTextEditor = [TextCellEditor]::new()
        $this._defaultNumberEditor = [NumberCellEditor]::new()
        $this._defaultCheckboxEditor = [CheckboxCellEditor]::new()
    }

    # Register a custom editor for a column
    [void] RegisterEditor([string]$columnName, [CellEditor]$editor) {
        if ($null -eq $editor) {
            throw "Editor cannot be null"
        }
        $this._columnEditors[$columnName] = $editor
    }

    # Register a text editor with options
    [void] RegisterTextEditor([string]$columnName, [hashtable]$options = @{}) {
        $editor = [TextCellEditor]::new()

        if ($options.ContainsKey('MaxLength')) {
            $editor.MaxLength = $options['MaxLength']
        }
        if ($options.ContainsKey('Pattern')) {
            $editor.Pattern = $options['Pattern']
        }
        if ($options.ContainsKey('AllowEmpty')) {
            $editor.AllowEmpty = $options['AllowEmpty']
        }

        $this._columnEditors[$columnName] = $editor
    }

    # Register a number editor with options
    [void] RegisterNumberEditor([string]$columnName, [hashtable]$options = @{}) {
        $editor = [NumberCellEditor]::new()

        if ($options.ContainsKey('MinValue')) {
            $editor.MinValue = $options['MinValue']
        }
        if ($options.ContainsKey('MaxValue')) {
            $editor.MaxValue = $options['MaxValue']
        }
        if ($options.ContainsKey('AllowDecimals')) {
            $editor.AllowDecimals = $options['AllowDecimals']
        }
        if ($options.ContainsKey('AllowNegative')) {
            $editor.AllowNegative = $options['AllowNegative']
        }

        $this._columnEditors[$columnName] = $editor
    }

    # Register a checkbox editor with options
    [void] RegisterCheckboxEditor([string]$columnName, [hashtable]$options = @{}) {
        $editor = [CheckboxCellEditor]::new()

        if ($options.ContainsKey('TrueDisplay')) {
            $editor.TrueDisplay = $options['TrueDisplay']
        }
        if ($options.ContainsKey('FalseDisplay')) {
            $editor.FalseDisplay = $options['FalseDisplay']
        }

        $this._columnEditors[$columnName] = $editor
    }

    # Register a widget editor with options
    [void] RegisterWidgetEditor([string]$columnName, [string]$widgetType, [scriptblock]$factory = $null) {
        $editor = [WidgetCellEditor]::new($widgetType)

        if ($null -ne $factory) {
            $editor.WidgetFactory = $factory
        }

        $this._columnEditors[$columnName] = $editor
    }

    # Get editor for a column (returns registered or default)
    [CellEditor] GetEditor([string]$columnName, [object]$value = $null) {
        # Check if custom editor registered for this column
        if ($this._columnEditors.ContainsKey($columnName)) {
            return $this._columnEditors[$columnName]
        }

        # Infer editor from value type
        if ($null -ne $value) {
            if ($value -is [bool]) {
                return $this._defaultCheckboxEditor
            }
            if ($value -is [int] -or $value -is [double] -or $value -is [decimal]) {
                return $this._defaultNumberEditor
            }
        }

        # Default to text editor
        return $this._defaultTextEditor
    }

    # Check if column has custom editor
    [bool] HasEditor([string]$columnName) {
        return $this._columnEditors.ContainsKey($columnName)
    }

    # Remove custom editor for column (revert to default)
    [void] UnregisterEditor([string]$columnName) {
        $this._columnEditors.Remove($columnName)
    }

    # Clear all custom editors
    [void] ClearEditors() {
        $this._columnEditors.Clear()
    }

    # Get all registered column names
    [string[]] GetRegisteredColumns() {
        return $this._columnEditors.Keys
    }

    # Create a pre-configured registry for task list
    static [CellEditorRegistry] CreateTaskListRegistry() {
        $registry = [CellEditorRegistry]::new()

        # Title - text with max length
        $registry.RegisterTextEditor('title', @{ MaxLength = 200; AllowEmpty = $false })

        # Details - text with no max length
        $registry.RegisterTextEditor('details', @{ AllowEmpty = $true })

        # Due date - widget editor
        $registry.RegisterWidgetEditor('due', 'date', $null)

        # Project - widget editor
        $registry.RegisterWidgetEditor('project', 'project', $null)

        # Tags - widget editor
        $registry.RegisterWidgetEditor('tags', 'tags', $null)

        # Priority - number editor (1-5)
        $registry.RegisterNumberEditor('priority', @{
            MinValue = 1
            MaxValue = 5
            AllowDecimals = $false
            AllowNegative = $false
        })

        # Status - text with validation
        $registry.RegisterTextEditor('status', @{
            Pattern = '^(TODO|IN_PROGRESS|DONE|BLOCKED)$'
            AllowEmpty = $false
        })

        return $registry
    }

    # Create a pre-configured registry for project list
    static [CellEditorRegistry] CreateProjectListRegistry() {
        $registry = [CellEditorRegistry]::new()

        # Name - text with max length
        $registry.RegisterTextEditor('name', @{ MaxLength = 100; AllowEmpty = $false })

        # Description - text with no max length
        $registry.RegisterTextEditor('description', @{ AllowEmpty = $true })

        # Active - checkbox
        $registry.RegisterCheckboxEditor('active', @{
            TrueDisplay = '[X] Active'
            FalseDisplay = '[ ] Inactive'
        })

        return $registry
    }

    # Create a pre-configured registry for context list
    static [CellEditorRegistry] CreateContextListRegistry() {
        $registry = [CellEditorRegistry]::new()

        # Name - text with max length
        $registry.RegisterTextEditor('name', @{ MaxLength = 100; AllowEmpty = $false })

        # Description - text with no max length
        $registry.RegisterTextEditor('description', @{ AllowEmpty = $true })

        return $registry
    }
}
