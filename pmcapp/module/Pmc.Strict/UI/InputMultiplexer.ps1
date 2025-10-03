# PMC Input Multiplexer - Context-Aware Key Routing
# Enables simultaneous command line + navigation without blocking

Set-StrictMode -Version Latest

# Input contexts that can handle different types of keys
enum PmcInputContext {
    CommandLine      # Primary: command input and processing
    GridNavigation   # Secondary: arrow keys, selection in data grids
    InlineEdit       # Tertiary: cell editing within grids
    Modal            # Special: modal dialog input
}

# Input routing configuration
class PmcInputRoutingConfig {
    [hashtable] $ContextPriority = @{
        'Escape' = [PmcInputContext]::CommandLine
        'Ctrl' = [PmcInputContext]::CommandLine
        'Alt' = [PmcInputContext]::CommandLine
        'F1-F12' = [PmcInputContext]::CommandLine
    }

    [hashtable] $GridNavigationKeys = @{
        'UpArrow' = $true
        'DownArrow' = $true
        'LeftArrow' = $true
        'RightArrow' = $true
        'PageUp' = $true
        'PageDown' = $true
        'Home' = $true
        'End' = $true
        'Enter' = $true
    }

    [hashtable] $EditingKeys = @{
        'Backspace' = $true
        'Delete' = $true
        'Insert' = $true
        'Tab' = $true
    }
}

# State for tracking current input mode
class PmcInputState {
    [PmcInputContext] $ActiveContext = [PmcInputContext]::CommandLine
    [bool] $GridBrowseMode = $false          # True when user is actively browsing grid
    [bool] $InlineEditMode = $false          # True when editing a grid cell
    [bool] $ModalActive = $false             # True when modal dialog is open
    [string] $LastCommand = ""               # Last command entered
    [datetime] $LastActivity = [datetime]::Now

    # Command line state
    [string] $CommandBuffer = ""
    [int] $CommandCursorPos = 0

    # Grid state
    [int] $GridSelectedRow = 0
    [int] $GridSelectedColumn = 0
    [string] $GridEditingValue = ""
    [int] $GridEditCursorPos = 0

    [void] Reset() {
        $this.ActiveContext = [PmcInputContext]::CommandLine
        $this.GridBrowseMode = $false
        $this.InlineEditMode = $false
        $this.ModalActive = $false
        $this.CommandBuffer = ""
        $this.CommandCursorPos = 0
    }

    [void] ActivateGridBrowse() {
        $this.GridBrowseMode = $true
        $this.ActiveContext = [PmcInputContext]::GridNavigation
        $this.LastActivity = [datetime]::Now
    }

    [void] ActivateInlineEdit([string]$initialValue) {
        $this.InlineEditMode = $true
        $this.GridEditingValue = $initialValue
        $this.GridEditCursorPos = $initialValue.Length
        $this.ActiveContext = [PmcInputContext]::InlineEdit
        $this.LastActivity = [datetime]::Now
    }

    [void] ReturnToCommandLine() {
        $this.GridBrowseMode = $false
        $this.InlineEditMode = $false
        $this.ActiveContext = [PmcInputContext]::CommandLine
        $this.LastActivity = [datetime]::Now
    }
}

# Main input multiplexer class
class PmcInputMultiplexer {
    hidden [PmcInputRoutingConfig] $_config
    hidden [PmcInputState] $_state
    hidden [hashtable] $_handlers = @{}
    hidden [bool] $_initialized = $false

    # Event handlers for different contexts
    [scriptblock] $CommandLineHandler = $null
    [scriptblock] $GridNavigationHandler = $null
    [scriptblock] $InlineEditHandler = $null
    [scriptblock] $ModalHandler = $null

    PmcInputMultiplexer() {
        $this._config = [PmcInputRoutingConfig]::new()
        $this._state = [PmcInputState]::new()
        $this.InitializeDefaultHandlers()
        $this._initialized = $true
    }

    [void] InitializeDefaultHandlers() {
        # Default command line handler (processes commands)
        $this.CommandLineHandler = {
            param([ConsoleKeyInfo]$key, [PmcInputState]$state)

            switch ($key.Key) {
                'Enter' {
                    if ($state.CommandBuffer.Trim()) {
                        # Process command
                        $this.ProcessCommand($state.CommandBuffer)
                        $state.CommandBuffer = ""
                        $state.CommandCursorPos = 0
                    }
                }
                'Backspace' {
                    if ($state.CommandCursorPos -gt 0) {
                        $state.CommandBuffer = $state.CommandBuffer.Remove($state.CommandCursorPos - 1, 1)
                        $state.CommandCursorPos--
                    }
                }
                'LeftArrow' {
                    if ($state.CommandCursorPos -gt 0) {
                        $state.CommandCursorPos--
                    }
                }
                'RightArrow' {
                    if ($state.CommandCursorPos -lt $state.CommandBuffer.Length) {
                        $state.CommandCursorPos++
                    }
                }
                'Tab' {
                    # Tab completion
                    $this.HandleTabCompletion($state)
                }
                default {
                    if ([char]::IsControl($key.KeyChar)) {
                        return  # Skip control characters
                    }
                    # Insert character at cursor position
                    $state.CommandBuffer = $state.CommandBuffer.Insert($state.CommandCursorPos, $key.KeyChar)
                    $state.CommandCursorPos++
                }
            }

            # Render updated command line
            $this.RenderCommandLine($state)
        }

        # Default grid navigation handler
        $this.GridNavigationHandler = {
            param([ConsoleKeyInfo]$key, [PmcInputState]$state)

            switch ($key.Key) {
                'UpArrow' { $this.MoveGridSelection(0, -1) }
                'DownArrow' { $this.MoveGridSelection(0, 1) }
                'LeftArrow' { $this.MoveGridSelection(-1, 0) }
                'RightArrow' { $this.MoveGridSelection(1, 0) }
                'Enter' { $this.ActivateGridEdit() }
                'F2' { $this.ActivateGridEdit() }
                'Escape' { $state.ReturnToCommandLine(); $this.RenderPrompt() }
                default {
                    # Alphanumeric keys start quick search or edit
                    if ([char]::IsLetterOrDigit($key.KeyChar)) {
                        $state.ActivateInlineEdit([string]$key.KeyChar)
                        $this.RenderInlineEdit($state)
                    }
                }
            }
        }

        # Default inline edit handler
        $this.InlineEditHandler = {
            param([ConsoleKeyInfo]$key, [PmcInputState]$state)

            switch ($key.Key) {
                'Enter' {
                    # Commit edit
                    $this.CommitInlineEdit($state.GridEditingValue)
                    $state.GridBrowseMode = $true
                    $state.InlineEditMode = $false
                    $state.ActiveContext = [PmcInputContext]::GridNavigation
                }
                'Escape' {
                    # Cancel edit
                    $state.GridBrowseMode = $true
                    $state.InlineEditMode = $false
                    $state.ActiveContext = [PmcInputContext]::GridNavigation
                }
                'Backspace' {
                    if ($state.GridEditCursorPos -gt 0) {
                        $state.GridEditingValue = $state.GridEditingValue.Remove($state.GridEditCursorPos - 1, 1)
                        $state.GridEditCursorPos--
                    }
                }
                default {
                    if ([char]::IsControl($key.KeyChar)) {
                        return  # Skip control characters
                    }
                    # Insert character
                    $state.GridEditingValue = $state.GridEditingValue.Insert($state.GridEditCursorPos, $key.KeyChar)
                    $state.GridEditCursorPos++
                }
            }

            $this.RenderInlineEdit($state)
        }
    }

    # Main input routing logic
    [PmcInputContext] RouteKey([ConsoleKeyInfo]$key) {
        if (-not $this._initialized) {
            throw "Input multiplexer not initialized"
        }

        # Priority routing: certain keys always go to command line
        if ($this.IsCommandLinePriorityKey($key)) {
            $this._state.ReturnToCommandLine()
            return [PmcInputContext]::CommandLine
        }

        # Modal has highest priority when active
        if ($this._state.ModalActive) {
            return [PmcInputContext]::Modal
        }

        # Route based on current state and key type
        if ($this._state.InlineEditMode) {
            return [PmcInputContext]::InlineEdit
        }

        if ($this._state.GridBrowseMode -and $this.IsGridNavigationKey($key)) {
            return [PmcInputContext]::GridNavigation
        }

        # Default: everything goes to command line (preserve CLI-first)
        return [PmcInputContext]::CommandLine
    }

    # Handle a key press by routing to appropriate context
    [void] HandleKey([ConsoleKeyInfo]$key) {
        if (-not $this._initialized) {
            throw "Input multiplexer not initialized"
        }

        $context = $this.RouteKey($key)
        # Debug removed
        $this._state.ActiveContext = $context
        $this._state.LastActivity = [datetime]::Now

        # Execute appropriate handler
        try {
            switch ($context) {
                ([PmcInputContext]::CommandLine) {
                    if ($this.CommandLineHandler) {
                        & $this.CommandLineHandler $key $this._state
                    }
                }
                ([PmcInputContext]::GridNavigation) {
                    if ($this.GridNavigationHandler) {
                        & $this.GridNavigationHandler $key $this._state
                    }
                }
                ([PmcInputContext]::InlineEdit) {
                    if ($this.InlineEditHandler) {
                        & $this.InlineEditHandler $key $this._state
                    }
                }
                ([PmcInputContext]::Modal) {
                    if ($this.ModalHandler) {
                        & $this.ModalHandler $key $this._state
                    }
                }
            }
        } catch {
            Write-PmcDebug -Level 1 -Category 'InputMultiplexer' -Message "Handler error in context $context" -Data @{ Error = $_.ToString() }
            # Fallback to command line on error
            $this._state.ReturnToCommandLine()
        }
        # Debug removed
    }

    # Utility methods for key classification
    [bool] IsCommandLinePriorityKey([ConsoleKeyInfo]$key) {
        # Escape always returns to command line
        if ($key.Key -eq 'Escape') { return $true }

        # Ctrl combinations go to command line
        if ($key.Modifiers -band [ConsoleModifiers]::Control) { return $true }

        # Alt combinations go to command line
        if ($key.Modifiers -band [ConsoleModifiers]::Alt) { return $true }

        # Function keys go to command line
        if ($key.Key -ge [ConsoleKey]::F1 -and $key.Key -le [ConsoleKey]::F24) { return $true }

        return $false
    }

    [bool] IsGridNavigationKey([ConsoleKeyInfo]$key) {
        return $this._config.GridNavigationKeys.ContainsKey($key.Key.ToString())
    }

    # State management
    [PmcInputState] GetState() { return $this._state }

    [void] SetGridBrowseMode([bool]$enabled) {
        if ($enabled) {
            $this._state.ActivateGridBrowse()
        } else {
            $this._state.ReturnToCommandLine()
        }
    }

    [void] ResetState() { $this._state.Reset() }

    # Placeholder methods for rendering and command processing (to be implemented)
    [void] ProcessCommand([string]$command) {
        # Will integrate with existing Invoke-PmcCommand
        Write-PmcDebug -Level 2 -Category 'InputMultiplexer' -Message "Processing command: $command"
    }

    [void] HandleTabCompletion([PmcInputState]$state) {
        # Will integrate with existing completion engine
        Write-PmcDebug -Level 3 -Category 'InputMultiplexer' -Message "Tab completion requested"
    }

    [void] RenderCommandLine([PmcInputState]$state) {
        # Will integrate with screen manager
        Write-PmcDebug -Level 3 -Category 'InputMultiplexer' -Message "Rendering command line"
    }

    [void] RenderPrompt() {
        Write-PmcDebug -Level 3 -Category 'InputMultiplexer' -Message "Rendering prompt"
    }

    [void] MoveGridSelection([int]$deltaX, [int]$deltaY) {
        $this._state.GridSelectedRow += $deltaY
        $this._state.GridSelectedColumn += $deltaX
        Write-PmcDebug -Level 3 -Category 'InputMultiplexer' -Message "Grid selection moved to ($($this._state.GridSelectedColumn), $($this._state.GridSelectedRow))"
    }

    [void] ActivateGridEdit() {
        $this._state.ActivateInlineEdit("")
        Write-PmcDebug -Level 3 -Category 'InputMultiplexer' -Message "Grid edit activated"
    }

    [void] RenderInlineEdit([PmcInputState]$state) {
        Write-PmcDebug -Level 3 -Category 'InputMultiplexer' -Message "Rendering inline edit: '$($state.GridEditingValue)'"
    }

    [void] CommitInlineEdit([string]$value) {
        Write-PmcDebug -Level 2 -Category 'InputMultiplexer' -Message "Committing inline edit: '$value'"
    }
}

# Global instance for use by screen manager
$Script:PmcInputMultiplexer = $null

function Initialize-PmcInputMultiplexer {
    if ($Script:PmcInputMultiplexer) {
        Write-Warning "PMC Input Multiplexer already initialized"
        return
    }

    $Script:PmcInputMultiplexer = [PmcInputMultiplexer]::new()
    Write-PmcDebug -Level 2 -Category 'InputMultiplexer' -Message "Input multiplexer initialized"
}

function Get-PmcInputMultiplexer {
    if (-not $Script:PmcInputMultiplexer) {
        Initialize-PmcInputMultiplexer
    }
    return $Script:PmcInputMultiplexer
}

Export-ModuleMember -Function Initialize-PmcInputMultiplexer, Get-PmcInputMultiplexer
