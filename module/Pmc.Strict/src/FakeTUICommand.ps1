# PMC FakeTUI Command Implementation
# Provides the Start-PmcFakeTUI function for the command system

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

        # Load FakeTUI integrated components
        . $PSScriptRoot/../FakeTUI/FakeTUIAppIntegrated.ps1 -ErrorAction Stop

        # Create and run the integrated app
        $app = [PmcFakeTUIAppIntegrated]::new()
        $app.Initialize()
        $app.Run()
        $app.Shutdown()

        Write-Host "PMC FakeTUI exited." -ForegroundColor Green

    } catch {
        Write-Host "Failed to start PMC FakeTUI: $($_.Exception.Message)" -ForegroundColor Red
        if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
            Write-PmcDebug -Level 1 -Category 'FakeTUI' -Message "Failed to start FakeTUI: $_"
        }

        # Fallback to simple version if integrated fails
        Write-Host "Attempting fallback to basic FakeTUI..." -ForegroundColor Yellow
        try {
            . $PSScriptRoot/../FakeTUI/FakeTUI.ps1 -ErrorAction Stop
            $basicApp = [PmcFakeTUIApp]::new()
            $basicApp.Initialize()
            $basicApp.Run()
            $basicApp.Shutdown()
        } catch {
            Write-Host "Fallback also failed: $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    }
}

Export-ModuleMember -Function Start-PmcFakeTUI