# Config provider indirection - now uses centralized state

function Set-PmcConfigProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)] [scriptblock]$Get,
        [Parameter(Position=1)] [scriptblock]$Set
    )
    Set-PmcConfigProviders -Get $Get -Set $Set
}

function Get-PmcConfig {
    $providers = Get-PmcConfigProviders
    try { return & $providers.Get } catch { return @{} }
}

function Save-PmcConfig {
    param($cfg)
    $providers = Get-PmcConfigProviders
    if ($providers.Set) {
        try { & $providers.Set $cfg; return } catch {
            # Custom config provider failed - fall back to default
        }
    }
    # Default: write to pmc/config.json near module root
    try {
        $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $path = Join-Path $root 'config.json'
        $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $path -Encoding UTF8
    } catch {
        # Default config file save failed - settings not persisted
    }
}

# Basic config schema validation and normalization
function Get-PmcDefaultConfig {
    return @{
        Display = @{ Theme = @{ Enabled=$true; Hex='#33aaff' }; Icons=@{ Mode='emoji' } }
        Debug = @{ Level=0; LogPath='debug.log'; MaxSize='10MB'; RedactSensitive=$true; IncludePerformance=$false }
        Security = @{ AllowedWritePaths=@('./','./reports/','./backups/'); MaxFileSize='100MB'; MaxMemoryUsage='500MB'; ScanForSensitiveData=$true; RequirePathWhitelist=$true; AuditAllFileOps=$true }
        Behavior = @{ StrictDataMode = $true; SafePathsStrict = $true; MaxBackups = 3; MaxUndoLevels = 10; WhatIf = $false }
    }
}

function Test-PmcConfigSchema {
    $cfg = Get-PmcConfig
    $errors = @(); $warnings=@()
    # Display.Theme.Hex
    try { $hex = [string]$cfg.Display.Theme.Hex; if (-not ($hex -match '^#?[0-9a-fA-F]{6}$')) { $warnings += 'Display.Theme.Hex invalid; using default' } } catch { $warnings += 'Display.Theme.Hex missing' }
    # Icons mode
    try { $mode = [string]$cfg.Display.Icons.Mode; if ($mode -notin @('ascii','emoji')) { $warnings += 'Display.Icons.Mode must be ascii|emoji' } } catch { $warnings += 'Display.Icons.Mode missing' }
    # Debug level
    try { $lvl = [int]$cfg.Debug.Level; if ($lvl -lt 0 -or $lvl -gt 3) { $warnings += 'Debug.Level out of range (0-3)' } } catch { $warnings += 'Debug.Level missing' }
    # Security paths
    try { if (-not ($cfg.Security.AllowedWritePaths -is [System.Collections.IEnumerable])) { $warnings += 'Security.AllowedWritePaths must be an array' } } catch { $warnings += 'Security.AllowedWritePaths missing' }
    return [pscustomobject]@{ IsValid = ($errors.Count -eq 0); Errors=$errors; Warnings=$warnings }
}

function Normalize-PmcConfig {
    $cfg = Get-PmcConfig
    $def = Get-PmcDefaultConfig
    foreach ($k in $def.Keys) {
        if (-not $cfg.ContainsKey($k)) { $cfg[$k] = $def[$k]; continue }
        foreach ($k2 in $def[$k].Keys) {
            if (-not $cfg[$k].ContainsKey($k2)) { $cfg[$k][$k2] = $def[$k][$k2] }
        }
    }
    # Normalize hex
    try { if ($cfg.Display.Theme.Hex -and -not ($cfg.Display.Theme.Hex.ToString().StartsWith('#'))) { $cfg.Display.Theme.Hex = '#' + $cfg.Display.Theme.Hex } } catch {}
    # Icons mode default
    try { if (-not $cfg.Display.Icons.Mode) { $cfg.Display.Icons.Mode = 'emoji' } } catch {}
    Save-PmcConfig $cfg
    return $cfg
}

function Validate-PmcConfig { param([PmcCommandContext]$Context)
    $result = Test-PmcConfigSchema
    if (-not $result.IsValid -or $result.Warnings.Count -gt 0) {
        Write-PmcStyled -Style 'Warning' -Text 'Config issues detected:'
        foreach ($w in $result.Warnings) { Write-PmcStyled -Style 'Muted' -Text ('  - ' + $w) }
    } else {
        Write-PmcStyled -Style 'Success' -Text 'Config looks good.'
    }
}

# Explicitly export the function to ensure it's available
Export-ModuleMember -Function Get-PmcConfig

# Removed inline config editor per request
