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
    $cfg = $null
    try { $cfg = & $providers.Get } catch { $cfg = $null }

    # Fallback to reading config.json from PMC root if provider returns nothing
    if (-not $cfg -or ($cfg -is [hashtable] -and $cfg.Keys.Count -eq 0) -or ($cfg.PSObject.Properties.Count -eq 0)) {
        try {
            $root = Get-PmcRootPath
            $path = Join-Path $root 'config.json'
            if (Test-Path $path) {
                $raw = Get-Content -Path $path -Raw -Encoding UTF8
                if ($raw) { $cfg = $raw | ConvertFrom-Json }
            }
        } catch { $cfg = $null }
    }

    if (-not $cfg) { $cfg = @{} }
    return $cfg
}

function Save-PmcConfig {
    param($cfg)
    $providers = Get-PmcConfigProviders
    if ($providers.Set) {
        try { & $providers.Set $cfg; return } catch {
            # Custom config provider failed - fall back to default
        }
    }
    # Default: write to standalone root/config.json
    try {
        try { $root = Get-PmcRootPath } catch { $root = (Split-Path $PSScriptRoot -Parent) }
        $path = Join-Path $root 'config.json'
        $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $path -Encoding UTF8
    } catch {
        # Default config file save failed - settings not persisted
    }
}

# Basic config schema validation and normalization
function Get-PmcDefaultConfig {
    return @{
        Display = @{ Theme = @{ Enabled=$true; Hex='#33aaff' }; Icons=@{ Mode='ascii' } }
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

function Show-PmcConfig {
    param($Context)
    $cfg = Get-PmcConfig

    Write-PmcStyled -Style 'Header' -Text "`nPMC CONFIGURATION`n"
    Write-PmcStyled -Style 'Subheader' -Text "Data Path:"
    Write-PmcStyled -Style 'Info' -Text "  $($cfg.Storage.DataPath)"
    Write-PmcStyled -Style 'Subheader' -Text "`nDisplay Settings:"
    Write-PmcStyled -Style 'Info' -Text "  Icons: $($cfg.Display.Icons.Mode)"
    Write-PmcStyled -Style 'Subheader' -Text "`nSecurity Level:"
    Write-PmcStyled -Style 'Info' -Text "  $($cfg.Security.Level)"
}

function Edit-PmcConfig {
    param($Context)
    Write-PmcStyled -Style 'Warning' -Text 'Config editing not yet implemented'
    Write-PmcStyled -Style 'Info' -Text 'Use: Show-PmcConfig to view current settings'
}

function Set-PmcConfigValue {
    param($Context)
    Write-PmcStyled -Style 'Warning' -Text 'Config value setting not yet implemented'
    Write-PmcStyled -Style 'Info' -Text 'Manual config editing required'
}

function Reload-PmcConfig {
    param($Context)
    # Force reload config
    $Script:PmcConfig = $null
    $cfg = Get-PmcConfig
    # Re-apply runtime systems from config
    try {
        $lvl = try { [int]$cfg.Debug.Level } catch { 0 }
        Initialize-PmcDebugSystem -Level $lvl
    } catch {}
    try { Initialize-PmcSecuritySystem } catch {}
    try { Initialize-PmcThemeSystem } catch {}
    try { Ensure-PmcUniversalDisplay } catch {}
    Write-PmcStyled -Style 'Success' -Text 'OK: Configuration reloaded and systems re-initialized'
}

function Set-PmcIconMode {
    param($Context)

    $mode = 'emoji'
    if ($Context.FreeText.Count -gt 0) {
        $mode = $Context.FreeText[0].ToLower()
    }

    if ($mode -notin @('ascii', 'emoji')) {
        Write-PmcStyled -Style 'Error' -Text 'Icon mode must be: ascii or emoji'
        return
    }

    $cfg = Get-PmcConfig
    $cfg.Display.Icons.Mode = $mode
    Save-PmcConfig $cfg
    Write-PmcStyled -Style 'Success' -Text "OK: Icon mode set to: $mode"
}

# Export config functions
Export-ModuleMember -Function Get-PmcConfig, Validate-PmcConfig, Show-PmcConfig, Edit-PmcConfig, Set-PmcConfigValue, Reload-PmcConfig, Set-PmcIconMode
