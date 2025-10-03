# PSReadLine-only input engine for PMC
# No fallbacks - if PSReadLine doesn't work, we crash

Set-StrictMode -Version Latest

# Module-level state
$Script:PmcPSReadLineInitialized = $false

function Get-PmcCompletions {
    param(
        [string]$Buffer
    )

    $tokens = $Buffer.Trim() -split '\s+' | Where-Object { $_ }

    $commandMap = $Script:PmcCommandMap
    if (-not $commandMap) { return @() }

    $completions = @()

    if ($tokens.Count -eq 0) {
        $domains = @($commandMap.Keys) + @('help', 'exit', 'quit', 'status')
        $completions = $domains | Sort-Object
    }
    elseif ($tokens.Count -eq 1) {
        $domains = @($commandMap.Keys) + @('help', 'exit', 'quit', 'status')
        $filter = $tokens[0]
        $completions = $domains | Where-Object { $_ -like "$filter*" } | Sort-Object
    }
    elseif ($tokens.Count -eq 2) {
        $domain = $tokens[0]
        if ($commandMap.ContainsKey($domain)) {
            $actions = @($commandMap[$domain].Keys)
            $filter = $tokens[1]
            $completions = $actions | Where-Object { $_ -like "$filter*" } | Sort-Object
        }
    }

    return $completions
}

function Initialize-PmcPSReadLine {
    Write-PmcDebug -Level 1 -Category 'PSREADLINE' -Message "Starting PSReadLine initialization"

    # Import PSReadLine - crash if not available
    Import-Module PSReadLine -Force -ErrorAction Stop
    Write-PmcDebug -Level 1 -Category 'PSREADLINE' -Message "PSReadLine module imported"

    # Configure PSReadLine for PMC
    Set-PSReadLineOption -PredictionSource None
    Set-PSReadLineOption -BellStyle None
    Write-PmcDebug -Level 1 -Category 'PSREADLINE' -Message "PSReadLine options configured"

    # Set up custom tab completion with extensive debug logging
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
        try {
            Write-PmcDebug -Level 1 -Category 'TAB' -Message "Tab key handler triggered"

            # Get current line buffer
            $line = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

            Write-PmcDebug -Level 1 -Category 'TAB' -Message "Buffer state retrieved" -Data @{ Line = $line; Cursor = $cursor }

            # Use AST-based completion system
            $completions = @()
            if (Get-Command Get-PmcCompletionsFromAst -ErrorAction SilentlyContinue) {
                Write-PmcDebug -Level 1 -Category 'TAB' -Message "Using AST-based completion"
                try {
                    $completions = Get-PmcCompletionsFromAst -Buffer $line -CursorPos $cursor
                    Write-PmcDebug -Level 1 -Category 'TAB' -Message "AST completions generated" -Data @{ Count = $completions.Count }
                } catch {
                    Write-PmcDebug -Level 1 -Category 'TAB' -Message "AST completion failed: $_" -Data @{ Line = $line; Cursor = $cursor }
                    Write-PmcStyled -Style 'Error' -Text "AST completion failed: $_"
                    return
                }
            } else {
                Write-PmcDebug -Level 1 -Category 'TAB' -Message "AST completion not available - using default tab"
                [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
                return
            }

            # Handle completions

            if ($completions.Count -eq 0) {
                Write-PmcDebug -Level 1 -Category 'TAB' -Message "No completions found - using default tab"
                [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
            } elseif ($completions.Count -eq 1) {
                Write-PmcDebug -Level 1 -Category 'TAB' -Message "Single completion - replacing line" -Data @{ Completion = $completions[0] }
                [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($completions[0])
            } else {
                Write-PmcDebug -Level 1 -Category 'TAB' -Message "Multiple completions - using default tab menu" -Data @{ CompletionCount = $completions.Count }
                [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
            }
        } catch {
            Write-PmcDebug -Level 1 -Category 'TAB' -Message "Tab completion error" -Data @{ Error = $_.ToString() }
            [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
        }
    }
    Write-PmcDebug -Level 1 -Category 'PSREADLINE' -Message "Tab completion handler registered"
}

function Read-PmcCommand {
    # Initialize PSReadLine on first use - crash if it fails
    if (-not $Script:PmcPSReadLineInitialized) {
        Initialize-PmcPSReadLine
        $Script:PmcPSReadLineInitialized = $true
    }

    Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Reading command with Read-Host"

    # Use Read-Host - tab completion will be handled manually if needed
    $input = Read-Host -Prompt "pmc"

    Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Input received" -Data @{ Input = $input }

    # Basic tab completion simulation - check for completion requests
    if ($input -and $input.EndsWith("?")) {
        # User requested help with "command?"
        $cleanInput = $input.TrimEnd("?").Trim()
        if ($cleanInput) {
            $tokens = $cleanInput -split '\s+' | Where-Object { $_ }
            if ($tokens.Count -eq 1) {
                try {
                    $commandMap = $null
                    if (Get-Variable -Name 'PmcCommandMap' -Scope Script -ErrorAction SilentlyContinue) {
                        $commandMap = (Get-Variable -Name 'PmcCommandMap' -Scope Script).Value
                    }

                    if ($commandMap -and $commandMap.Keys) {
                        $domains = @($commandMap.Keys) + @('help', 'exit', 'quit', 'status')
                        $matches = $domains | Where-Object { $_ -like "$($tokens[0])*" }
                        if ($matches -and $matches.Count -gt 0) {
                            Write-Host "Available completions for '$($tokens[0])': $($matches -join ', ')" -ForegroundColor Yellow
                            Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Showing help completions" -Data @{ Prefix = $tokens[0]; Matches = $matches }
                        }
                    }
                } catch {
                    Write-PmcDebug -Level 1 -Category 'INPUT' -Message "Error in help completion" -Data @{ Error = $_.ToString() }
                }
            }
        }
        return ""  # Don't process the help request as a command
    }

    return $input
}

# Compatibility functions
function Enable-PmcInteractiveMode {
    Initialize-PmcPSReadLine
    return $true
}

function Disable-PmcInteractiveMode {
    # Nothing to clean up
}

function Get-PmcInteractiveStatus {
    return @{
        Enabled = $true
        Features = @("PSReadLine", "TabCompletion", "History")
        Engine = "PSReadLine"
        PSReadLineAvailable = $true
    }
}