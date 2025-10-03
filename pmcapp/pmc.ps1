# Command line argument parsing must appear before any executable statements
param(
    [switch]$CLI,
    [switch]$Debug1,
    [switch]$Debug2,
    [switch]$Debug3,
    [string]$Config = $null,
    [string]$SecurityLevel = 'balanced',
    [switch]$Help
)

# Default to FakeTUI mode, use -CLI to force command line
$UseFakeTUI = -not $CLI.IsPresent

Set-StrictMode -Version Latest

$ErrorActionPreference = 'Continue'

if ($Help) {
    Write-Host @"
PMC - Project Management Console

Usage: pmc.ps1 [options]

Options:
  -CLI               Force command line interface (FakeTUI is default)
  -Debug1            Enable basic debug logging (commands, errors)
  -Debug2            Enable detailed debug logging (parsing, validation, storage)
  -Debug3            Enable verbose debug logging (UI rendering, completion details)
  -Config <path>     Use specific config file path
  -SecurityLevel <level>  Set security level: permissive, balanced, strict (default: balanced)
  -Help              Show this help message

Interactive Features:
  - Tab: Visual completion menus with arrow key navigation
  - Ghost text: Real-time parameter hints during typing
  - Professional keyboard shortcuts (Ctrl+A, Ctrl+E, etc.)
  - Command history with Up/Down arrows and Ctrl+R search

Commands:
  help               Show available commands
  exit, quit, q      Exit PMC

Examples:
  pmc.ps1 -Interactive -Debug2
  pmc.ps1 -SecurityLevel strict -Debug1
"@ -ForegroundColor Green
    exit 0
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleManifest = Join-Path $root 'module/Pmc.Strict/Pmc.Strict.psd1'
if (-not (Test-Path $moduleManifest)) { Write-Host "Strict module not found at $moduleManifest" -ForegroundColor Red; exit 1 }

try {
    $loaded = Import-Module $moduleManifest -Force -ErrorAction Stop -PassThru
    # Module loading message already displayed by module itself
} catch {
    Write-Host "✗ Failed to import PMC module: $_" -ForegroundColor Red
    exit 1
}

# Verify core functions are available
if (-not (Get-Command Invoke-PmcCommand -ErrorAction SilentlyContinue)) {
    Write-Host "✗ PMC core functions not available after import" -ForegroundColor Red
    exit 1
}
if (-not (Get-Command Test-PmcInputSafety -ErrorAction SilentlyContinue)) {
    Write-Host "✗ PMC security functions not available after import" -ForegroundColor Red
    exit 1
}

# Ensure Universal Display is loaded and shortcuts are registered (loader owns this)
try {
    $udPath = Join-Path $root 'module/Pmc.Strict/src/UniversalDisplay.ps1'
    if (-not (Get-Command Show-PmcData -ErrorAction SilentlyContinue)) {
        if (Test-Path $udPath) {
            Write-Host "  Loading UniversalDisplay.ps1 (startup)..." -ForegroundColor Gray
            . $udPath
            Write-Host "  ✓ UniversalDisplay.ps1 loaded (startup)" -ForegroundColor Green
        } else {
            throw "UniversalDisplay.ps1 not found at $udPath"
        }
    }
    # Register-PmcUniversalCommands is now handled during module loading
} catch {
    Write-Host "✗ Universal Display initialization failed: $_" -ForegroundColor Red
    exit 1
}

# Universal Display is loaded by the module itself; no host-side initialization here.

# Simple config provider that reads/writes ./config.json next to this script
$configPath = if ($Config) { $Config } else { Join-Path $root 'config.json' }

function Get-StrictConfig {
    if (Test-Path $configPath) {
        return (Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable)
    }
    # Enhanced defaults with new systems
    return @{
        Display = @{
            Theme = @{ Enabled=$true; Hex='#33aaff'; UseTrueColor=$true; Global=$true; PreserveAlerts=$true }
            Icons = @{ Mode='emoji' } # 'emoji' or 'ascii'
            RefreshOnCommand = $true
            ShowBannerOnRefresh = $true
        }
        Behavior = @{ SafePathsStrict=$true; EnableCsvLedger=$true; WhatIf=$false; MaxUndoLevels=10; MaxBackups=3; ReportRichCsv=$false }
        Paths = @{ AllowedWriteDirs = @() }
        Debug = @{ Level=0; LogPath='debug.log'; MaxSize='10MB'; RedactSensitive=$true; IncludePerformance=$false }
        Security = @{ AllowedWritePaths=@('./','./reports/','./backups/','./exports/','./excel_input/','./excel_output/'); MaxFileSize='100MB'; MaxMemoryUsage='500MB'; ScanForSensitiveData=$true; RequirePathWhitelist=$true; AuditAllFileOps=$true }
        Interactive = @{ Enabled=$false; GhostText=$true; CompletionMenus=$true }
        Excel = @{
            SourceFolder = './excel_input'
            DestinationPath = './excel_output.xlsm'
            SourceSheet = 'SVI-CAS'
            DestSheet = 'Output'
            ID2FieldName = 'CASNumber'
            AllowedExtensions = @('.xlsm', '.xlsx')
            MaxFileSize = '50MB'
            Mappings = @(
                @{ Field='RequestDate';    SourceCell='W23'; DestCell='B2'  }
                @{ Field='AuditType';      SourceCell='W78'; DestCell='B3'  }
                @{ Field='AuditorName';    SourceCell='W10'; DestCell='B4'  }
                @{ Field='TPName';         SourceCell='W3';  DestCell='B5'  }
                @{ Field='TPEmailAddress'; SourceCell='X3';  DestCell='B6'  }
                @{ Field='TPPhoneNumber';  SourceCell='Y3';  DestCell='B7'  }
                @{ Field='TaxID';          SourceCell='W13'; DestCell='B8'  }
                @{ Field='CASNumber';      SourceCell='G17'; DestCell='B9'  }
            )
        }
    }
}

function Set-StrictConfig($cfg) { $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8 }

Set-PmcConfigProvider -Get { Get-StrictConfig } -Set { param($cfg) Set-StrictConfig $cfg }

# Initialize systems based on command line flags (after config provider is set)
$debugLevel = 0
if ($Debug3) { $debugLevel = 3 }
elseif ($Debug2) { $debugLevel = 2 }
elseif ($Debug1) { $debugLevel = 1 }

Initialize-PmcDebugSystem -Level $debugLevel
# Now that config provider is ready, update debug settings from config
try { Update-PmcDebugFromConfig } catch { Write-Host "Note: Update-PmcDebugFromConfig not available" -ForegroundColor Yellow }
if ($debugLevel -gt 0) { Write-Host "✓ Debug logging enabled (Level $debugLevel)" -ForegroundColor Green }

# Initialize security system from config, then apply requested profile
Initialize-PmcSecuritySystem
# Now that config provider is ready, update security settings from config
try { Update-PmcSecurityFromConfig } catch { Write-Host "Note: Update-PmcSecurityFromConfig not available" -ForegroundColor Yellow }

# Set security level
Set-PmcSecurityLevel -Level $SecurityLevel
Write-Host "✓ Security level: $SecurityLevel" -ForegroundColor Green

# Initialize theme/display system (capabilities + styles)
Initialize-PmcThemeSystem

function Show-StrictHelp {
    if (Get-Command Show-PmcSmartHelp -ErrorAction SilentlyContinue) {
        Show-PmcSmartHelp
    } elseif (Get-Command Pmc-ShowHelpUI -ErrorAction SilentlyContinue) {
        Pmc-ShowHelpUI
    } else {
        # Fallback to raw data if interactive help not available
        Write-Host "Available commands:" -ForegroundColor Green
        $rows = @()
        if (Get-Command Get-PmcHelp -ErrorAction SilentlyContinue) {
            # Get raw data directly if the function exists
            $commandMap = Get-Variable -Name 'PmcCommandMap' -Scope Script -ErrorAction SilentlyContinue
            if ($commandMap) {
                foreach ($d in ($commandMap.Value.Keys | Sort-Object)) {
                    foreach ($a in ($commandMap.Value[$d].Keys | Sort-Object)) {
                        Write-Host ("  {0} {1}" -f $d, $a) -ForegroundColor Cyan
                    }
                }
            }
        }
    }
}

function Show-SystemStatus {
    Write-PmcStyled -Style 'Title' -Text "`nPMC System Status:"

    # Debug status
    $debugStatus = Get-PmcDebugStatus
    Write-PmcStyled -Style 'Body' -Text "  Debug: " -NoNewline
    if ($debugStatus.Enabled) {
        Write-PmcStyled -Style 'Success' -Text "Level $($debugStatus.Level) → $($debugStatus.LogPath)"
    } else {
        Write-PmcStyled -Style 'Muted' -Text "Disabled"
    }

    # Security status
    $securityStatus = Get-PmcSecurityStatus
    Write-PmcStyled -Style 'Body' -Text "  Security: " -NoNewline
    if ($securityStatus.PathWhitelistEnabled) {
        Write-PmcStyled -Style 'Success' -Text "Active ($(($securityStatus.AllowedWritePaths).Count) allowed paths)"
    } else {
        Write-PmcStyled -Style 'Warning' -Text "Permissive mode"
    }

    # Interactive status
    if ($Interactive) {
        $interactiveStatus = Get-PmcInteractiveStatus
        Write-PmcStyled -Style 'Body' -Text "  Interactive: " -NoNewline
        if ($interactiveStatus) {
            Write-PmcStyled -Style 'Success' -Text "Available"
        } else {
            Write-PmcStyled -Style 'Warning' -Text "PSReadLine required"
        }
    }

    # Memory usage
    $memoryMB = [Math]::Round($securityStatus.CurrentMemoryUsage / 1MB, 1)
    $limitMB = [Math]::Round($securityStatus.MaxMemoryUsage / 1MB, 1)
    Write-PmcStyled -Style 'Info' -Text "  Memory: $memoryMB MB / $limitMB MB"

    # Theme / Display
    try {
        $disp = Get-PmcState -Section 'Display'
        $theme = $disp.Theme
        $caps = $disp.Capabilities
        Write-PmcStyled -Style 'Body' -Text ("  Theme: {0}" -f ($theme.Hex ?? '#33aaff'))
        Write-PmcStyled -Style 'Muted' -Text ("  Capabilities: ANSI={0} TrueColor={1} TTY={2} NoColor={3}" -f $caps.AnsiSupport, $caps.TrueColorSupport, $caps.IsTTY, $caps.NoColor)
    } catch {
        Write-PmcStyled -Style 'Warning' -Text "  Theme: Display state unavailable"
    }

    Write-Host ""
}

# Enhanced shell with interactive support
function Show-PmcBanner {
    Write-PmcStyled -Style 'Title' -Text "pmc — enhanced project management console"
    Write-PmcStyled -Style 'Muted' -Text "Type 'help' for commands, 'status' for system info, 'exit' to quit."
}


function Start-PmcShell {
    # Launch FakeTUI if not in CLI mode
    if ($UseFakeTUI) {
        try {
            Write-Host "Starting PMC FakeTUI (integrated)..." -ForegroundColor Green

            # Use the module-exposed integrated app entrypoint
            if (-not (Get-Command Start-PmcFakeTUI -ErrorAction SilentlyContinue)) {
                throw "Start-PmcFakeTUI not available from module"
            }

            # Extra debug trace around GUI start
            try { Write-PmcDebug -Level 1 -Category 'GUI' -Message 'Start-PmcFakeTUI dispatch' } catch {}
            Start-PmcFakeTUI

            Write-Host "FakeTUI exited" -ForegroundColor Green
            return
        } catch {
            # Log detailed error for diagnostics
            try { Write-PmcDebug -Level 1 -Category 'GUI' -Message ("Integrated GUI failed: {0}" -f $_.ToString()) } catch {}
            Write-Host "Failed to start FakeTUI (integrated): $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Falling back to CLI mode..." -ForegroundColor Yellow
            $script:UseFakeTUI = $false
        }
    }

    # CLI mode - need interactive shell
    $Interactive = $true

    if ($Interactive) {
        try {
            $ok = Enable-PmcInteractiveMode
            if (-not $ok) { throw "Interactive mode not available" }

            # Initialize persistent screen layout
                if (Get-Command Initialize-PmcScreen -ErrorAction SilentlyContinue) {
                    Initialize-PmcScreen -Title "pmc — enhanced project management console"
                    Write-PmcDebug -Level 2 -Category 'SHELL' -Message "Persistent screen layout initialized"
                    if (Get-Command Update-PmcHeaderStatus -ErrorAction SilentlyContinue) {
                        Update-PmcHeaderStatus -Title "pmc — enhanced project management console"
                    }
                } else {
                # Fallback to old banner system
                if (Get-Command Clear-CommandOutput -ErrorAction SilentlyContinue) {
                    Clear-CommandOutput
                }
                Show-PmcBanner
                Write-Host ""
            }
        } catch {
            Write-PmcDebug -Level 2 -Category 'SHELL' -Message "Interactive init failed: $_"
            Write-PmcStyled -Style 'Error' -Text ("Interactive mode failed to start: {0}" -f $_)
            exit 1
        }
    }

    while ($true) {
        try {
            # Refresh header status each loop
            if ($Interactive -and (Get-Command Update-PmcHeaderStatus -ErrorAction SilentlyContinue)) {
                Update-PmcHeaderStatus -Title "pmc — enhanced project management console"
            }
            # Use Console.ReadKey for interactive input (NO fallback)
            if ($Interactive) {
                if (Get-Command Read-PmcCommand -ErrorAction SilentlyContinue) {
                    $line = Read-PmcCommand
                } else {
                    Write-PmcStyled -Style 'Error' -Text "Interactive command reader not available; aborting."
                    exit 1
                }
            } else {
                Write-Host "Interactive mode is required. Remove -NoInteractive." -ForegroundColor Red
                exit 1
            }
        } catch {
            Write-PmcDebug -Level 1 -Category 'SHELL' -Message "Input error: $_"
            break
        }

        if ($null -eq $line) { break }
        $line = $line.Trim()
        if (-not $line) { continue }

        # Check input safety
        if (-not (Test-PmcInputSafety -Input $line -InputType 'command')) {
            Write-PmcStyled -Style 'Error' -Text "Input rejected for security reasons"
            continue
        }

        switch -Regex ($line) {
            '^(?i)(exit|quit|q)$' {
                if ($Interactive) {
                    # Clean up screen management
                    if (Get-Command Reset-PmcScreen -ErrorAction SilentlyContinue) {
                        Reset-PmcScreen
                    }
                    Disable-PmcInteractiveMode
                }
                break
            }
            '^(?i)status$' { Show-SystemStatus; continue }
            '^(?i)debug\s+(on|off|\d+)$' {
                $debugArg = $matches[1]
                if ($debugArg -eq 'off') {
                    Initialize-PmcDebugSystem -Level 0
                    Write-PmcStyled -Style 'Warning' -Text "Debug logging disabled"
                } elseif ($debugArg -eq 'on') {
                    Initialize-PmcDebugSystem -Level 1
                    Write-PmcStyled -Style 'Success' -Text "Debug logging enabled (Level 1)"
                } elseif ($debugArg -match '^\d+$') {
                    $level = [Math]::Min([int]$debugArg, 3)
                    Initialize-PmcDebugSystem -Level $level
                    Write-PmcStyled -Style 'Success' -Text ("Debug logging set to Level {0}" -f $level)
                }
                continue
            }
            '^(?i)interactive\s+(on|off|enable|disable)$' {
                $interactiveArg = $matches[1]
                if (($interactiveArg -eq 'on' -or $interactiveArg -eq 'enable') -and -not $Interactive) {
                    try {
                        Enable-PmcInteractiveMode
                        $Interactive = $true
                        Write-PmcStyled -Style 'Success' -Text "Interactive mode enabled"
                    } catch {
                        Write-PmcStyled -Style 'Error' -Text ("Failed to enable interactive mode: {0}" -f $_)
                    }
                } elseif (($interactiveArg -eq 'off' -or $interactiveArg -eq 'disable') -and $Interactive) {
                    try {
                        Disable-PmcInteractiveMode
                        $Interactive = $false
                        Write-PmcStyled -Style 'Warning' -Text "Interactive mode disabled"
                    } catch {
                        Write-PmcStyled -Style 'Error' -Text ("Failed to disable interactive mode: {0}" -f $_)
                    }
                }
                continue
            }
            default {
                try {
                    # Clear content area for command output, preserving header/input areas
                    if (Get-Command Clear-PmcContentArea -ErrorAction SilentlyContinue) {
                        Clear-PmcContentArea
                        Hide-PmcCursor
                        # Move cursor to top-left of content area so static renderers print visibly
                        try {
                            $cb = Get-PmcContentBounds
                            if ($cb) {
                                $row = [int]$cb.Y + 1
                                $col = [int]$cb.X + 1
                                Write-Host ("`e[${row};${col}H") -NoNewline
                            }
                        } catch {}
                    } elseif (Get-Command Clear-CommandOutput -ErrorAction SilentlyContinue) {
                        Clear-CommandOutput
                    }

                    # Execute command - output will appear in content area
                    Invoke-PmcCommand -Buffer $line

                    # Restore input prompt after command execution
                    if (Get-Command Set-PmcInputPrompt -ErrorAction SilentlyContinue) {
                        Set-PmcInputPrompt -Prompt "pmc> "
                        # Update header after potential context changes (debug, focus, security)
                        if (Get-Command Update-PmcHeaderStatus -ErrorAction SilentlyContinue) {
                            Update-PmcHeaderStatus -Title "pmc — enhanced project management console"
                        }
                    } else {
                        # Fallback spacing
                        Write-Host ""
                    }
                } catch {
                    Write-PmcStyled -Style 'Error' -Text ("Error: {0}" -f $_)
                    # Restore prompt even on error
                    if (Get-Command Set-PmcInputPrompt -ErrorAction SilentlyContinue) {
                        Set-PmcInputPrompt -Prompt "pmc> "
                    }
                }
            }
        }
    }
}

# Start the enhanced shell
Start-PmcShell
