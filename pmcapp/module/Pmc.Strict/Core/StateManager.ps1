# PMC Secure State Management System
# Replaces scattered script variables with thread-safe, validated state access

Set-StrictMode -Version Latest

# Security policy for state access validation
class PmcSecurityPolicy {
    [hashtable] $AllowedSections = @{
        'Config' = @('Read', 'Write')
        'Security' = @('Read', 'Write')
        'Debug' = @('Read', 'Write')
        'Display' = @('Read', 'Write')
        'Interactive' = @('Read', 'Write')
        'Commands' = @('Read', 'Write')
        'Tasks' = @('Read', 'Write')
        'Projects' = @('Read', 'Write')
        'Time' = @('Read', 'Write')
        'Help' = @('Read', 'Write')
        'UndoRedo' = @('Read', 'Write')
        'Cache' = @('Read', 'Write')
        'Focus' = @('Read', 'Write')
        'Analytics' = @('Read', 'Write')
    }

    [void] ValidateStateAccess([string]$section, [string]$key, [string]$operation) {
        if ([string]::IsNullOrWhiteSpace($section)) {
            throw "State section cannot be null or empty"
        }

        if ([string]::IsNullOrWhiteSpace($key)) {
            throw "State key cannot be null or empty"
        }

        if (-not $this.AllowedSections.ContainsKey($section)) {
            throw "Access denied: Section '$section' is not allowed"
        }

        if ($operation -notin $this.AllowedSections[$section]) {
            throw "Access denied: Operation '$operation' not allowed on section '$section'"
        }

        # Additional security checks
        if ($key.Contains('..') -or $key.Contains('/') -or $key.Contains('\')) {
            throw "Security violation: Invalid characters in state key '$key'"
        }
    }

    [void] ValidateStateValue([object]$value, [string]$section = '') {
        if ($null -eq $value) {
            return  # null values are allowed
        }

        # Allow scriptblocks only for config providers
        if ($value -is [scriptblock]) {
            if ($section -ne 'Config') {
                throw "Security violation: Cannot store scriptblocks in state (except Config section)"
            }
        }

        # Check for potentially dangerous string content
        if ($value -is [string]) {
            $dangerousPatterns = @(
                'Invoke-Expression', 'iex', 'cmd.exe', 'powershell.exe',
                'Start-Process', 'New-Object.*ComObject'
            )
            foreach ($pattern in $dangerousPatterns) {
                if ($value -match $pattern) {
                    throw "Security violation: Potentially dangerous content detected in state value"
                }
            }
        }
    }
}

# Thread-safe, secure state manager
class PmcSecureStateManager {
    hidden [hashtable] $_state = @{}
    hidden [System.Threading.ReaderWriterLockSlim] $_lock
    hidden [PmcSecurityPolicy] $_security
    hidden [bool] $_initialized = $false

    PmcSecureStateManager() {
        $this._lock = [System.Threading.ReaderWriterLockSlim]::new()
        $this._security = [PmcSecurityPolicy]::new()
        $this.InitializeDefaultSections()
        $this._initialized = $true
    }

    [void] InitializeDefaultSections() {
        # Initialize all allowed sections with empty hashtables
        foreach ($section in $this._security.AllowedSections.Keys) {
            $this._state[$section] = @{}
        }
    }

    [object] GetState([string]$section, [string]$key) {
        if (-not $this._initialized) {
            throw "State manager not initialized"
        }

        $this._security.ValidateStateAccess($section, $key, 'Read')

        $this._lock.EnterReadLock()
        try {
            if (-not $this._state.ContainsKey($section)) {
                return $null
            }
            return $this._state[$section][$key]
        } finally {
            $this._lock.ExitReadLock()
        }
    }

    [void] SetState([string]$section, [string]$key, [object]$value) {
        if (-not $this._initialized) {
            throw "State manager not initialized"
        }

        $this._security.ValidateStateAccess($section, $key, 'Write')
        $this._security.ValidateStateValue($value, $section)

        $this._lock.EnterWriteLock()
        try {
            if (-not $this._state.ContainsKey($section)) {
                $this._state[$section] = @{}
            }
            $this._state[$section][$key] = $value
        } finally {
            $this._lock.ExitWriteLock()
        }
    }

    [hashtable] GetSection([string]$section) {
        if (-not $this._initialized) {
            throw "State manager not initialized"
        }

        $this._security.ValidateStateAccess($section, 'SectionAccess', 'Read')

        $this._lock.EnterReadLock()
        try {
            if (-not $this._state.ContainsKey($section)) {
                return @{}
            }
            # Return a copy to prevent external modification
            return $this._state[$section].Clone()
        } finally {
            $this._lock.ExitReadLock()
        }
    }

    [void] SetSection([string]$section, [hashtable]$data) {
        if (-not $this._initialized) {
            throw "State manager not initialized"
        }

        $this._security.ValidateStateAccess($section, 'SectionAccess', 'Write')

        # Validate all values in the section
        foreach ($key in $data.Keys) {
            $this._security.ValidateStateValue($data[$key], $section)
        }

        $this._lock.EnterWriteLock()
        try {
            $this._state[$section] = $data.Clone()
        } finally {
            $this._lock.ExitWriteLock()
        }
    }

    [void] ClearSection([string]$section) {
        if (-not $this._initialized) {
            throw "State manager not initialized"
        }

        $this._security.ValidateStateAccess($section, 'SectionAccess', 'Write')

        $this._lock.EnterWriteLock()
        try {
            $this._state[$section] = @{}
        } finally {
            $this._lock.ExitWriteLock()
        }
    }

    [hashtable] GetSnapshot() {
        if (-not $this._initialized) {
            throw "State manager not initialized"
        }

        $this._lock.EnterReadLock()
        try {
            $snapshot = @{}
            foreach ($section in $this._state.Keys) {
                $snapshot[$section] = $this._state[$section].Clone()
            }
            return $snapshot
        } finally {
            $this._lock.ExitReadLock()
        }
    }

    [void] Dispose() {
        if ($this._lock) {
            $this._lock.Dispose()
        }
    }
}

# Global instance (will be initialized by main module)
$Script:SecureStateManager = $null

# Backward-compatible API functions that route through secure manager
function Get-PmcState {
    param(
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][string]$Key
    )

    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized. Call Initialize-PmcSecureState first."
    }

    return $Script:SecureStateManager.GetState($Section, $Key)
}

function Set-PmcState {
    param(
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][string]$Key,
        [Parameter(Mandatory=$true)][object]$Value
    )

    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized. Call Initialize-PmcSecureState first."
    }

    $Script:SecureStateManager.SetState($Section, $Key, $Value)
}

function Update-PmcStateSection {
    param(
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][hashtable]$Updates
    )

    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized. Call Initialize-PmcSecureState first."
    }

    # Get current section data
    $currentData = $Script:SecureStateManager.GetSection($Section)

    # Apply updates
    foreach ($key in $Updates.Keys) {
        $currentData[$key] = $Updates[$key]
    }

    # Set updated section
    $Script:SecureStateManager.SetSection($Section, $currentData)
}

function Initialize-PmcSecureState {
    [CmdletBinding()]
    param()

    if ($Script:SecureStateManager) {
        Write-Warning "PMC State Manager already initialized"
        return
    }

    try {
        $Script:SecureStateManager = [PmcSecureStateManager]::new()
        Write-Verbose "PMC Secure State Manager initialized successfully"

        # Migrate existing state if it exists (backward compatibility)
        if (Get-Variable -Name 'PmcGlobalState' -Scope Script -ErrorAction SilentlyContinue) {
            Write-Verbose "Migrating existing state to secure manager"
            $oldState = Get-Variable -Name 'PmcGlobalState' -Scope Script -ValueOnly

            foreach ($section in $oldState.Keys) {
                if ($oldState[$section] -is [hashtable]) {
                    $Script:SecureStateManager.SetSection($section, $oldState[$section])
                }
            }

            # Remove old state variable
            Remove-Variable -Name 'PmcGlobalState' -Scope Script -Force -ErrorAction SilentlyContinue
        }

    } catch {
        Write-Error "Failed to initialize PMC Secure State Manager: $_"
        throw
    }
}

function Reset-PmcSecureState {
    [CmdletBinding()]
    param()

    if ($Script:SecureStateManager) {
        $Script:SecureStateManager.Dispose()
        $Script:SecureStateManager = $null
    }

    Initialize-PmcSecureState
}

# Additional helper functions for common state operations
function Get-PmcStateSection {
    param([Parameter(Mandatory=$true)][string]$Section)

    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized"
    }

    return $Script:SecureStateManager.GetSection($Section)
}

function Set-PmcStateSection {
    param(
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][hashtable]$Data
    )

    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized"
    }

    $Script:SecureStateManager.SetSection($Section, $Data)
}

function Clear-PmcStateSection {
    param([Parameter(Mandatory=$true)][string]$Section)

    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized"
    }

    $Script:SecureStateManager.ClearSection($Section)
}

function Get-PmcStateSnapshot {
    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized"
    }

    return $Script:SecureStateManager.GetSnapshot()
}

# Legacy compatibility functions (convenience wrappers)
function Get-PmcDebugState {
    $section = Get-PmcStateSection -Section 'Debug'
    # Convert hashtable to object with properties for backward compatibility
    $state = [PSCustomObject]@{
        Level = if ($section.ContainsKey('Level')) { $section['Level'] } else { 0 }
        LogPath = if ($section.ContainsKey('LogPath')) { $section['LogPath'] } else { 'debug.log' }
        SessionId = if ($section.ContainsKey('SessionId')) { $section['SessionId'] } else { [System.Guid]::NewGuid().ToString() }
        Enabled = if ($section.ContainsKey('Enabled')) { $section['Enabled'] } else { $false }
    }
    return $state
}

function Get-PmcHelpState {
    return Get-PmcState -Section 'HelpUI' -Key 'HelpState'
}

function Get-PmcCommandCategories {
    return Get-PmcState -Section 'HelpUI' -Key 'CommandCategories'
}

function Set-PmcDebugState {
    param([hashtable]$State)
    Set-PmcStateSection -Section 'Debug' -Data $State
}

function Set-PmcHelpState {
    param([object]$State)
    Set-PmcState -Section 'HelpUI' -Key 'HelpState' -Value $State
}

function Set-PmcCommandCategories {
    param([object]$Categories)
    Set-PmcState -Section 'HelpUI' -Key 'CommandCategories' -Value $Categories
}

# Config provider functions (missing from refactor)
function Get-PmcConfigProviders {
    $section = Get-PmcStateSection -Section 'Config'
    return @{
        Get = if ($section.ContainsKey('ProviderGet')) { $section['ProviderGet'] } else { { @{} } }
        Set = if ($section.ContainsKey('ProviderSet')) { $section['ProviderSet'] } else { $null }
    }
}

function Set-PmcConfigProviders {
    param([scriptblock]$Get, [scriptblock]$Set)
    Set-PmcState -Section 'Config' -Key 'ProviderGet' -Value $Get
    if ($Set) { Set-PmcState -Section 'Config' -Key 'ProviderSet' -Value $Set }
}

# Security state functions (missing from refactor)
function Get-PmcSecurityState {
    $section = Get-PmcStateSection -Section 'Security'
    # Convert hashtable to object with properties for backward compatibility
    $state = [PSCustomObject]@{
        InputValidationEnabled = if ($section.ContainsKey('InputValidationEnabled')) { $section['InputValidationEnabled'] } else { $true }
        PathWhitelistEnabled = if ($section.ContainsKey('PathWhitelistEnabled')) { $section['PathWhitelistEnabled'] } else { $true }
        ResourceLimitsEnabled = if ($section.ContainsKey('ResourceLimitsEnabled')) { $section['ResourceLimitsEnabled'] } else { $true }
        AllowedWritePaths = if ($section.ContainsKey('AllowedWritePaths')) { $section['AllowedWritePaths'] } else { @() }
        MaxFileSize = if ($section.ContainsKey('MaxFileSize')) { $section['MaxFileSize'] } else { 100MB }
        MaxMemoryUsage = if ($section.ContainsKey('MaxMemoryUsage')) { $section['MaxMemoryUsage'] } else { 500MB }
    }
    return $state
}

# Simple wrapper function to satisfy missing calls
function Update-PmcStateSection {
    param([string]$Section, [hashtable]$Data)
    if ($Data) {
        Set-PmcStateSection -Section $Section -Data $Data
    }
}

# Export functions for use by other modules
Export-ModuleMember -Function Get-PmcState, Set-PmcState, Update-PmcStateSection, Initialize-PmcSecureState, Reset-PmcSecureState, Get-PmcStateSection, Set-PmcStateSection, Clear-PmcStateSection, Get-PmcStateSnapshot, Get-PmcDebugState, Set-PmcDebugState, Get-PmcHelpState, Set-PmcHelpState, Get-PmcCommandCategories, Set-PmcCommandCategories, Get-PmcConfigProviders, Set-PmcConfigProviders, Get-PmcSecurityState