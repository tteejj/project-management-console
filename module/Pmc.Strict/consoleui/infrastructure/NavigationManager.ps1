# NavigationManager.ps1 - Screen Navigation and History Management
#
# Provides screen transition management with:
# - NavigateTo($screenName) - Push current screen, show new screen
# - GoBack() - Pop history, return to previous screen
# - Replace($screenName) - Replace current without adding to history
# - ClearHistory() - Start fresh
# - GetHistory() - See navigation stack
# - Event: OnNavigated($from, $to)
# - Integration with PmcApplication
#
# Usage:
#   $nav = [NavigationManager]::new($pmcApp)
#   $nav.NavigateTo('TaskList')
#   # ... user presses Esc
#   $nav.GoBack()  # Return to previous screen

using namespace System
using namespace System.Collections.Generic

<#
.SYNOPSIS
Navigation history entry

.DESCRIPTION
Stores information about a screen in the navigation history
#>
class NavigationEntry {
    [string]$ScreenName
    [DateTime]$Timestamp
    [hashtable]$State  # Optional state to restore

    NavigationEntry([string]$screenName) {
        $this.ScreenName = $screenName
        $this.Timestamp = Get-Date
        $this.State = @{}
    }

    NavigationEntry([string]$screenName, [hashtable]$state) {
        $this.ScreenName = $screenName
        $this.Timestamp = Get-Date
        $this.State = $state
    }
}

<#
.SYNOPSIS
Manages screen navigation and history

.DESCRIPTION
NavigationManager provides:
- Screen transition management
- Navigation history stack
- Back navigation support
- Screen replacement without history
- State preservation during navigation
- Navigation events
- Integration with PmcApplication

.EXAMPLE
$nav = [NavigationManager]::new($pmcApp)
$nav.OnNavigated = { param($from, $to) Write-Host "Navigated from $from to $to" }
$nav.NavigateTo('TaskList')
$nav.NavigateTo('TaskDetail')
$nav.GoBack()  # Returns to TaskList
#>
class NavigationManager {
    # === Configuration ===
    hidden [object]$_application  # PmcApplication instance
    hidden [Stack[NavigationEntry]]$_history = [Stack[NavigationEntry]]::new()
    [string]$CurrentScreen = ""
    [int]$MaxHistorySize = 50

    # === Events ===
    [scriptblock]$OnNavigated = {}      # Fired after navigation: { param($from, $to) }
    [scriptblock]$OnNavigating = {}     # Fired before navigation: { param($from, $to) }
    [scriptblock]$OnBackNavigation = {} # Fired on back: { param($to) }

    # === State ===
    [string]$LastError = ""
    [bool]$CanGoBack = $false

    # === Constructor ===
    NavigationManager([object]$application) {
        if ($null -eq $application) {
            throw "Application instance is required"
        }
        $this._application = $application
    }

    # === Navigation Methods ===

    <#
    .SYNOPSIS
    Navigate to a new screen

    .PARAMETER screenName
    Name of the screen to navigate to

    .PARAMETER state
    Optional state hashtable to pass to the new screen

    .OUTPUTS
    True if navigation succeeded, False otherwise

    .EXAMPLE
    $nav.NavigateTo('TaskList')
    $nav.NavigateTo('TaskDetail', @{ taskId = '123' })
    #>
    [bool] NavigateTo([string]$screenName, [hashtable]$state = $null) {
        if ([string]::IsNullOrWhiteSpace($screenName)) {
            $this.LastError = "Screen name cannot be empty"
            return $false
        }

        # Check if screen is registered
        if (-not [ScreenRegistry]::IsRegistered($screenName)) {
            $this.LastError = "Screen '$screenName' is not registered"
            return $false
        }

        # Fire navigating event
        $this._InvokeCallback($this.OnNavigating, @($this.CurrentScreen, $screenName))

        # Save current screen to history (if not empty)
        if (-not [string]::IsNullOrWhiteSpace($this.CurrentScreen)) {
            $entry = [NavigationEntry]::new($this.CurrentScreen)

            # Try to save screen state if screen has SaveState method
            try {
                if ($null -ne $this._application.CurrentScreen -and
                    $this._application.CurrentScreen.PSObject.Methods['SaveState']) {
                    $entry.State = $this._application.CurrentScreen.SaveState()
                }
            }
            catch {
                # Ignore state save errors
            }

            $this._history.Push($entry)

            # Enforce max history size
            if ($this._history.Count -gt $this.MaxHistorySize) {
                $this._TrimHistory()
            }
        }

        # Create and show new screen
        try {
            $newScreen = [ScreenRegistry]::Create($screenName)
            if ($null -eq $newScreen) {
                $this.LastError = "Failed to create screen '$screenName'"
                return $false
            }

            # Restore state if provided
            if ($null -ne $state -and $newScreen.PSObject.Methods['RestoreState']) {
                try {
                    $newScreen.RestoreState($state)
                }
                catch {
                    # Ignore state restore errors
                }
            }

            # Set as current screen in application
            $oldScreen = $this.CurrentScreen
            $this.CurrentScreen = $screenName
            $this._application.SetScreen($newScreen)

            # Update CanGoBack flag
            $this.CanGoBack = $this._history.Count -gt 0

            # Fire navigated event
            $this._InvokeCallback($this.OnNavigated, @($oldScreen, $screenName))

            $this.LastError = ""
            return $true
        }
        catch {
            $this.LastError = "Navigation error: $($_.Exception.Message)"
            return $false
        }
    }

    <#
    .SYNOPSIS
    Go back to the previous screen in history

    .OUTPUTS
    True if navigation succeeded, False otherwise

    .EXAMPLE
    $nav.GoBack()
    #>
    [bool] GoBack() {
        if ($this._history.Count -eq 0) {
            $this.LastError = "No navigation history"
            return $false
        }

        try {
            # Pop previous screen from history
            $entry = $this._history.Pop()

            # Fire back navigation event
            $this._InvokeCallback($this.OnBackNavigation, $entry.ScreenName)

            # Create and show previous screen
            $previousScreen = [ScreenRegistry]::Create($entry.ScreenName)
            if ($null -eq $previousScreen) {
                $this.LastError = "Failed to create previous screen '$($entry.ScreenName)'"
                return $false
            }

            # Restore state
            if ($entry.State.Count -gt 0 -and $previousScreen.PSObject.Methods['RestoreState']) {
                try {
                    $previousScreen.RestoreState($entry.State)
                }
                catch {
                    # Ignore state restore errors
                }
            }

            # Set as current screen
            $oldScreen = $this.CurrentScreen
            $this.CurrentScreen = $entry.ScreenName
            $this._application.SetScreen($previousScreen)

            # Update CanGoBack flag
            $this.CanGoBack = $this._history.Count -gt 0

            # Fire navigated event
            $this._InvokeCallback($this.OnNavigated, @($oldScreen, $entry.ScreenName))

            $this.LastError = ""
            return $true
        }
        catch {
            $this.LastError = "Back navigation error: $($_.Exception.Message)"
            return $false
        }
    }

    <#
    .SYNOPSIS
    Replace current screen without adding to history

    .PARAMETER screenName
    Name of the screen to replace with

    .PARAMETER state
    Optional state hashtable to pass to the new screen

    .OUTPUTS
    True if replacement succeeded, False otherwise

    .EXAMPLE
    $nav.Replace('Login')  # Replace current screen without adding to history
    #>
    [bool] Replace([string]$screenName, [hashtable]$state = $null) {
        if ([string]::IsNullOrWhiteSpace($screenName)) {
            $this.LastError = "Screen name cannot be empty"
            return $false
        }

        # Check if screen is registered
        if (-not [ScreenRegistry]::IsRegistered($screenName)) {
            $this.LastError = "Screen '$screenName' is not registered"
            return $false
        }

        # Fire navigating event
        $this._InvokeCallback($this.OnNavigating, @($this.CurrentScreen, $screenName))

        # Create and show new screen (without adding current to history)
        try {
            $newScreen = [ScreenRegistry]::Create($screenName)
            if ($null -eq $newScreen) {
                $this.LastError = "Failed to create screen '$screenName'"
                return $false
            }

            # Restore state if provided
            if ($null -ne $state -and $newScreen.PSObject.Methods['RestoreState']) {
                try {
                    $newScreen.RestoreState($state)
                }
                catch {
                    # Ignore state restore errors
                }
            }

            # Set as current screen
            $oldScreen = $this.CurrentScreen
            $this.CurrentScreen = $screenName
            $this._application.SetScreen($newScreen)

            # Fire navigated event
            $this._InvokeCallback($this.OnNavigated, @($oldScreen, $screenName))

            $this.LastError = ""
            return $true
        }
        catch {
            $this.LastError = "Replace error: $($_.Exception.Message)"
            return $false
        }
    }

    <#
    .SYNOPSIS
    Clear navigation history

    .EXAMPLE
    $nav.ClearHistory()
    #>
    [void] ClearHistory() {
        $this._history.Clear()
        $this.CanGoBack = $false
    }

    <#
    .SYNOPSIS
    Get navigation history

    .OUTPUTS
    Array of NavigationEntry objects (most recent first)

    .EXAMPLE
    $history = $nav.GetHistory()
    foreach ($entry in $history) {
        Write-Host "$($entry.ScreenName) at $($entry.Timestamp)"
    }
    #>
    [array] GetHistory() {
        return $this._history.ToArray()
    }

    <#
    .SYNOPSIS
    Get current navigation depth

    .OUTPUTS
    Number of entries in history

    .EXAMPLE
    $depth = $nav.GetDepth()
    #>
    [int] GetDepth() {
        return $this._history.Count
    }

    # === Helper Methods ===

    <#
    .SYNOPSIS
    Trim history to max size (removes oldest entries)
    #>
    hidden [void] _TrimHistory() {
        while ($this._history.Count -gt $this.MaxHistorySize) {
            # Convert to array, reverse, remove last, reverse back, rebuild stack
            $entries = $this._history.ToArray()
            [Array]::Reverse($entries)
            $trimmed = $entries | Select-Object -First ($this.MaxHistorySize)
            [Array]::Reverse($trimmed)

            $this._history.Clear()
            foreach ($entry in $trimmed) {
                $this._history.Push($entry)
            }
        }
    }

    <#
    .SYNOPSIS
    Invoke callback safely
    #>
    hidden [void] _InvokeCallback([scriptblock]$callback, $args) {
        if ($null -ne $callback -and $callback -ne {}) {
            try {
                if ($null -ne $args) {
                    & $callback @args
                } else {
                    & $callback
                }
            }
            catch {
                # Silently ignore callback errors
            }
        }
    }

    # === Diagnostics ===

    <#
    .SYNOPSIS
    Get navigation statistics

    .OUTPUTS
    Hashtable with navigation statistics
    #>
    [hashtable] GetStatistics() {
        return @{
            currentScreen = $this.CurrentScreen
            historyDepth = $this._history.Count
            canGoBack = $this.CanGoBack
            maxHistorySize = $this.MaxHistorySize
            lastError = $this.LastError
        }
    }

    <#
    .SYNOPSIS
    Print navigation history (for debugging)
    #>
    [void] PrintHistory() {
        Write-Host "Navigation History (depth: $($this._history.Count)):"
        $index = 0
        foreach ($entry in $this._history.ToArray()) {
            Write-Host "  [$index] $($entry.ScreenName) at $($entry.Timestamp)"
            $index++
        }
    }
}
