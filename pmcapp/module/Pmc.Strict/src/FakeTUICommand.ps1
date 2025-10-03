# PMC FakeTUI Command Implementation
# Provides the Start-PmcFakeTUI function for the command system

# Integrated FakeTUI components are preloaded by Pmc.Strict.psm1

function Start-PmcFakeTUI {
    <#
    .SYNOPSIS
    Launch PMC's FakeTUI interface
    .DESCRIPTION
    Starts the lightweight TUI-like interface for PMC with keyboard-driven
    menu navigation and integration with existing CLI commands and real data.
    #>
    [CmdletBinding()]
    param()

    try {
        Write-Host "Starting PMC FakeTUI with integrated screens..." -ForegroundColor Green

        # All components were loaded at module import.

        # Create and run the integrated app
        $app = [PmcFakeTUIAppIntegrated]::new()
        $app.Initialize()
        $app.Run()
        $app.Shutdown()

        Write-Host "PMC FakeTUI exited." -ForegroundColor Green

    } catch {
        Write-Host "Failed to start PMC FakeTUI (integrated): $($_.Exception.Message)" -ForegroundColor Red
        if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
            Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Failed to start integrated FakeTUI: $_"
        }
        # No fallback in pmcapp: integrated app is the single TUI
        throw
    }
}

Export-ModuleMember -Function Start-PmcFakeTUI
