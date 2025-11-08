# ConsoleUI DepsLoader - loads dependencies from src/ (primary) and deps/ (ConsoleUI-specific only)
# Eliminates duplication by using src/ as single source of truth

param()

# Paths
$depsDir = Join-Path $PSScriptRoot 'deps'
$srcDir = Join-Path $PSScriptRoot '../src'  # Pmc.Strict/consoleui/../src = Pmc.Strict/src

# Verify paths exist
if (-not (Test-Path $srcDir)) {
    throw "Source directory not found: $srcDir"
}
if (-not (Test-Path $depsDir)) {
    throw "Deps directory not found: $depsDir"
}

# Neutralize Export-ModuleMember calls in copied files
function Export-ModuleMember { param([Parameter(ValueFromRemainingArguments=$true)]$args) }

# Load core primitives and rendering helpers first (from src/)
. (Join-Path $srcDir 'PraxisVT.ps1')
. (Join-Path $srcDir 'PraxisStringBuilder.ps1')
. (Join-Path $srcDir 'TerminalDimensions.ps1')
. (Join-Path $srcDir 'PraxisFrameRenderer.ps1')

# Core types/config/state/security/ui/storage/time (from src/)
. (Join-Path $srcDir 'Types.ps1')
. (Join-Path $srcDir 'Config.ps1')
. (Join-Path $srcDir 'Debug.ps1')
. (Join-Path $srcDir 'Security.ps1')
. (Join-Path $srcDir 'State.ps1')
. (Join-Path $srcDir 'UI.ps1')
. (Join-Path $srcDir 'Storage.ps1')
. (Join-Path $srcDir 'Time.ps1')

# Schema support (from src/)
. (Join-Path $srcDir 'FieldSchemas.ps1')

# Template system (from src/)
. (Join-Path $srcDir 'TemplateDisplay.ps1')

# ConsoleUI-specific PmcTemplate class (UNIQUE to deps/)
. (Join-Path $depsDir 'PmcTemplate.ps1')

# Display systems (from src/)
. (Join-Path $srcDir 'DataDisplay.ps1')
. (Join-Path $srcDir 'UniversalDisplay.ps1')

# Help content (UNIQUE to deps/ - curated for ConsoleUI)
. (Join-Path $depsDir 'HelpContent.ps1')

# Help UI (from src/)
. (Join-Path $srcDir 'HelpUI.ps1')

# Analytics + Theme (from src/)
. (Join-Path $srcDir 'Analytics.ps1')
. (Join-Path $srcDir 'Theme.ps1')

# Project utility function (UNIQUE to deps/)
. (Join-Path $depsDir 'Project.ps1')

# Excel integration (from src/, optional - will load if Excel is available)
try {
    . (Join-Path $srcDir 'Excel.ps1')
    # Initialize field mappings from disk or defaults
    if (Get-Command Initialize-ExcelT2020Mappings -ErrorAction SilentlyContinue) {
        Initialize-ExcelT2020Mappings
    }
} catch {
    Write-Host "Excel integration not available (Excel COM not installed)" -ForegroundColor Yellow
}

Write-Host "ConsoleUI deps loaded (from src/ + deps/ unique files)" -ForegroundColor Green
