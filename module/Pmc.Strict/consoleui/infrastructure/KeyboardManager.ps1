# KeyboardManager.ps1 - Global Keyboard Shortcut System
#
# Provides comprehensive keyboard shortcut management with:
# - Register global shortcuts (Ctrl+Q quit, Ctrl+N new task, etc.)
# - Register screen-specific shortcuts (E edit, D delete on list screens)
# - Handle key events (try global first, then screen-specific)
# - Show help (list all shortcuts)
# - Support modifiers (Ctrl, Alt, Shift)
# - Priority system (global vs screen-specific)
# - Conflict detection
#
# Usage:
#   $km = [KeyboardManager]::new()
#
#   # Global shortcuts
#   $km.RegisterGlobal([ConsoleKey]::Q, [ConsoleModifiers]::Control, { $app.Stop() }, "Quit")
#   $km.RegisterGlobal([ConsoleKey]::N, [ConsoleModifiers]::Control, { $nav.NavigateTo('AddTask') }, "New Task")
#
#   # Screen-specific
#   $km.RegisterScreen('TaskList', [ConsoleKey]::E, $null, { $screen.EditSelectedItem() }, "Edit")
#   $km.RegisterScreen('TaskList', [ConsoleKey]::D, $null, { $screen.DeleteSelectedItem() }, "Delete")
#
#   # Handle key
#   $handled = $km.HandleKey($key, $currentScreenName)

using namespace System
using namespace System.Collections.Generic

<#
.SYNOPSIS
Keyboard shortcut registration

.DESCRIPTION
Contains information about a registered keyboard shortcut
#>
class KeyboardShortcut {
    [ConsoleKey]$Key
    [ConsoleModifiers]$Modifiers
    [scriptblock]$Action
    [string]$Description
    [string]$ScreenName  # Empty for global shortcuts

    KeyboardShortcut([ConsoleKey]$key, [ConsoleModifiers]$modifiers, [scriptblock]$action, [string]$description, [string]$screenName) {
        $this.Key = $key
        $this.Modifiers = $modifiers
        $this.Action = $action
        $this.Description = $description
        $this.ScreenName = $screenName
    }

    [string] GetKeyString() {
        $parts = @()

        if ($this.Modifiers -band [ConsoleModifiers]::Control) {
            $parts += "Ctrl"
        }
        if ($this.Modifiers -band [ConsoleModifiers]::Alt) {
            $parts += "Alt"
        }
        if ($this.Modifiers -band [ConsoleModifiers]::Shift) {
            $parts += "Shift"
        }

        $parts += $this.Key.ToString()

        return $parts -join "+"
    }
}

<#
.SYNOPSIS
Manages global and screen-specific keyboard shortcuts

.DESCRIPTION
KeyboardManager provides:
- Global shortcut registration (always active)
- Screen-specific shortcut registration (active when screen is current)
- Key event handling with priority system
- Shortcut conflict detection
- Help text generation
- Modifier support (Ctrl, Alt, Shift)
- Action execution with error handling

.EXAMPLE
$km = [KeyboardManager]::new()
$km.RegisterGlobal([ConsoleKey]::Q, [ConsoleModifiers]::Control, { exit }, "Quit")
$km.RegisterScreen('TaskList', [ConsoleKey]::E, $null, { Edit-Task }, "Edit")
$handled = $km.HandleKey($keyInfo, 'TaskList')
#>
class KeyboardManager {
    # === Shortcut Storage ===
    hidden [List[KeyboardShortcut]]$_globalShortcuts = [List[KeyboardShortcut]]::new()
    hidden [Dictionary[string, List[KeyboardShortcut]]]$_screenShortcuts = [Dictionary[string, List[KeyboardShortcut]]]::new()

    # === State ===
    [string]$LastError = ""
    [int]$GlobalShortcutCount = 0
    [int]$ScreenShortcutCount = 0

    # === Events ===
    [scriptblock]$OnShortcutExecuted = {}  # Fired after shortcut execution: { param($shortcut) }
    [scriptblock]$OnShortcutError = {}     # Fired on execution error: { param($shortcut, $error) }

    # === Constructor ===
    KeyboardManager() {
        # Initialize with common defaults if needed
    }

    # === Registration Methods ===

    <#
    .SYNOPSIS
    Register a global keyboard shortcut

    .PARAMETER key
    Console key

    .PARAMETER modifiers
    Console modifiers (Ctrl, Alt, Shift, or combination)

    .PARAMETER action
    Scriptblock to execute when shortcut is pressed

    .PARAMETER description
    Human-readable description

    .OUTPUTS
    True if registration succeeded, False otherwise

    .EXAMPLE
    $km.RegisterGlobal([ConsoleKey]::Q, [ConsoleModifiers]::Control, { exit }, "Quit application")
    #>
    [bool] RegisterGlobal([ConsoleKey]$key, [ConsoleModifiers]$modifiers, [scriptblock]$action, [string]$description) {
        if ($null -eq $action) {
            $this.LastError = "Action cannot be null"
            return $false
        }

        # Check for conflicts
        $existing = $this._globalShortcuts | Where-Object {
            $_.Key -eq $key -and $_.Modifiers -eq $modifiers
        }

        if ($existing) {
            $this.LastError = "Global shortcut already registered: $($existing.GetKeyString())"
            return $false
        }

        $shortcut = [KeyboardShortcut]::new($key, $modifiers, $action, $description, "")
        $this._globalShortcuts.Add($shortcut)
        $this.GlobalShortcutCount = $this._globalShortcuts.Count
        $this.LastError = ""

        return $true
    }

    <#
    .SYNOPSIS
    Register a screen-specific keyboard shortcut

    .PARAMETER screenName
    Screen name (must match registered screen)

    .PARAMETER key
    Console key

    .PARAMETER modifiers
    Console modifiers (can be $null for no modifiers)

    .PARAMETER action
    Scriptblock to execute when shortcut is pressed

    .PARAMETER description
    Human-readable description

    .OUTPUTS
    True if registration succeeded, False otherwise

    .EXAMPLE
    $km.RegisterScreen('TaskList', [ConsoleKey]::E, $null, { Edit-Task }, "Edit selected task")
    #>
    [bool] RegisterScreen([string]$screenName, [ConsoleKey]$key, [ConsoleModifiers]$modifiers, [scriptblock]$action, [string]$description) {
        if ([string]::IsNullOrWhiteSpace($screenName)) {
            $this.LastError = "Screen name cannot be empty"
            return $false
        }

        if ($null -eq $action) {
            $this.LastError = "Action cannot be null"
            return $false
        }

        # Ensure screen shortcut list exists
        if (-not $this._screenShortcuts.ContainsKey($screenName)) {
            $this._screenShortcuts[$screenName] = [List[KeyboardShortcut]]::new()
        }

        # Check for conflicts within this screen
        $existing = $this._screenShortcuts[$screenName] | Where-Object {
            $_.Key -eq $key -and $_.Modifiers -eq $modifiers
        }

        if ($existing) {
            $this.LastError = "Screen shortcut already registered for '$screenName': $($existing.GetKeyString())"
            return $false
        }

        $shortcut = [KeyboardShortcut]::new($key, $modifiers, $action, $description, $screenName)
        $this._screenShortcuts[$screenName].Add($shortcut)
        $this.ScreenShortcutCount++
        $this.LastError = ""

        return $true
    }

    <#
    .SYNOPSIS
    Unregister a global shortcut

    .PARAMETER key
    Console key

    .PARAMETER modifiers
    Console modifiers

    .OUTPUTS
    True if unregistration succeeded, False otherwise
    #>
    [bool] UnregisterGlobal([ConsoleKey]$key, [ConsoleModifiers]$modifiers) {
        $shortcut = $this._globalShortcuts | Where-Object {
            $_.Key -eq $key -and $_.Modifiers -eq $modifiers
        } | Select-Object -First 1

        if ($null -eq $shortcut) {
            $this.LastError = "Global shortcut not found"
            return $false
        }

        $this._globalShortcuts.Remove($shortcut)
        $this.GlobalShortcutCount = $this._globalShortcuts.Count
        $this.LastError = ""

        return $true
    }

    <#
    .SYNOPSIS
    Unregister a screen-specific shortcut

    .PARAMETER screenName
    Screen name

    .PARAMETER key
    Console key

    .PARAMETER modifiers
    Console modifiers

    .OUTPUTS
    True if unregistration succeeded, False otherwise
    #>
    [bool] UnregisterScreen([string]$screenName, [ConsoleKey]$key, [ConsoleModifiers]$modifiers) {
        if (-not $this._screenShortcuts.ContainsKey($screenName)) {
            $this.LastError = "No shortcuts registered for screen '$screenName'"
            return $false
        }

        $shortcut = $this._screenShortcuts[$screenName] | Where-Object {
            $_.Key -eq $key -and $_.Modifiers -eq $modifiers
        } | Select-Object -First 1

        if ($null -eq $shortcut) {
            $this.LastError = "Screen shortcut not found"
            return $false
        }

        $this._screenShortcuts[$screenName].Remove($shortcut)
        $this.ScreenShortcutCount--
        $this.LastError = ""

        return $true
    }

    # === Key Handling ===

    <#
    .SYNOPSIS
    Handle a key press event

    .PARAMETER keyInfo
    ConsoleKeyInfo object from Console.ReadKey()

    .PARAMETER currentScreenName
    Name of the current screen (for screen-specific shortcuts)

    .OUTPUTS
    True if key was handled by a shortcut, False otherwise

    .EXAMPLE
    $keyInfo = [Console]::ReadKey($true)
    $handled = $km.HandleKey($keyInfo, 'TaskList')
    if (-not $handled) {
        # Let screen handle key
        $screen.HandleKeyPress($keyInfo)
    }
    #>
    [bool] HandleKey([System.ConsoleKeyInfo]$keyInfo, [string]$currentScreenName) {
        # Try global shortcuts first (higher priority)
        $globalShortcut = $this._globalShortcuts | Where-Object {
            $_.Key -eq $keyInfo.Key -and $_.Modifiers -eq $keyInfo.Modifiers
        } | Select-Object -First 1

        if ($null -ne $globalShortcut) {
            return $this._ExecuteShortcut($globalShortcut)
        }

        # Try screen-specific shortcuts
        if (-not [string]::IsNullOrWhiteSpace($currentScreenName) -and
            $this._screenShortcuts.ContainsKey($currentScreenName)) {

            $screenShortcut = $this._screenShortcuts[$currentScreenName] | Where-Object {
                $_.Key -eq $keyInfo.Key -and $_.Modifiers -eq $keyInfo.Modifiers
            } | Select-Object -First 1

            if ($null -ne $screenShortcut) {
                return $this._ExecuteShortcut($screenShortcut)
            }
        }

        # Key not handled
        return $false
    }

    <#
    .SYNOPSIS
    Execute a shortcut action
    #>
    hidden [bool] _ExecuteShortcut([KeyboardShortcut]$shortcut) {
        try {
            & $shortcut.Action
            $this._InvokeCallback($this.OnShortcutExecuted, $shortcut)
            return $true
        }
        catch {
            $this.LastError = "Shortcut execution error: $($_.Exception.Message)"
            $this._InvokeCallback($this.OnShortcutError, @($shortcut, $_.Exception.Message))
            return $false
        }
    }

    # === Query Methods ===

    <#
    .SYNOPSIS
    Get all global shortcuts

    .OUTPUTS
    Array of KeyboardShortcut objects
    #>
    [array] GetGlobalShortcuts() {
        return $this._globalShortcuts.ToArray()
    }

    <#
    .SYNOPSIS
    Get shortcuts for a specific screen

    .PARAMETER screenName
    Screen name

    .OUTPUTS
    Array of KeyboardShortcut objects
    #>
    [array] GetScreenShortcuts([string]$screenName) {
        if ($this._screenShortcuts.ContainsKey($screenName)) {
            return $this._screenShortcuts[$screenName].ToArray()
        }
        return @()
    }

    <#
    .SYNOPSIS
    Get all shortcuts (global + all screens)

    .OUTPUTS
    Array of KeyboardShortcut objects
    #>
    [array] GetAllShortcuts() {
        $all = [List[KeyboardShortcut]]::new($this._globalShortcuts)

        foreach ($screenShortcuts in $this._screenShortcuts.Values) {
            $all.AddRange($screenShortcuts)
        }

        return $all.ToArray()
    }

    # === Help Generation ===

    <#
    .SYNOPSIS
    Generate help text for all shortcuts

    .PARAMETER screenName
    Optional screen name to include screen-specific shortcuts

    .OUTPUTS
    Formatted help text string

    .EXAMPLE
    $helpText = $km.GetHelpText('TaskList')
    Write-Host $helpText
    #>
    [string] GetHelpText([string]$screenName = "") {
        $lines = @()
        $lines += "Keyboard Shortcuts:"
        $lines += ""

        # Global shortcuts
        if ($this._globalShortcuts.Count -gt 0) {
            $lines += "Global:"
            foreach ($shortcut in $this._globalShortcuts) {
                $keyStr = $shortcut.GetKeyString().PadRight(15)
                $lines += "  $keyStr  $($shortcut.Description)"
            }
            $lines += ""
        }

        # Screen-specific shortcuts
        if (-not [string]::IsNullOrWhiteSpace($screenName) -and
            $this._screenShortcuts.ContainsKey($screenName)) {

            $lines += "$screenName Screen:"
            foreach ($shortcut in $this._screenShortcuts[$screenName]) {
                $keyStr = $shortcut.GetKeyString().PadRight(15)
                $lines += "  $keyStr  $($shortcut.Description)"
            }
        }

        return $lines -join "`n"
    }

    # === Helper Methods ===

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
            }
            catch {
                # Silently ignore callback errors
            }
        }
    }

    # === Statistics ===

    <#
    .SYNOPSIS
    Get keyboard manager statistics

    .OUTPUTS
    Hashtable with statistics
    #>
    [hashtable] GetStatistics() {
        return @{
            globalShortcuts = $this._globalShortcuts.Count
            screenShortcuts = $this.ScreenShortcutCount
            totalShortcuts = $this._globalShortcuts.Count + $this.ScreenShortcutCount
            registeredScreens = $this._screenShortcuts.Keys.Count
            lastError = $this.LastError
        }
    }
}
