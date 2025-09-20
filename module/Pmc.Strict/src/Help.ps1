# PMC Help System - REWRITTEN FROM SCRATCH
# Minimal clean implementation using ONLY universal display

function Get-PmcSchema {
    param([string]$Domain,[string]$Action)
    $key = "$($Domain.ToLower()) $($Action.ToLower())"
    if ($Script:PmcParameterMap.ContainsKey($key)) { return $Script:PmcParameterMap[$key] }
    return @()
}

function Get-PmcHelp {
    param([PmcCommandContext]$Context)
    # Route to clean help system
    Show-PmcSmartHelp -Context $Context
}

# Get-PmcHelpData moved to main module scope where $Script:PmcHelpContent is accessible

# ALL OTHER HELP FUNCTIONS DELETED - use universal display system only
