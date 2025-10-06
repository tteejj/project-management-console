# PMC FakeTUI Application - Integrated version with real screens

# Reuse the main FakeTUI application implementation
. "$PSScriptRoot/FakeTUIApp.ps1"

class PmcFakeTUIAppIntegrated {
    [PmcFakeTUIApp] $Inner

    PmcFakeTUIAppIntegrated() {
        Write-Host "Initializing PMC FakeTUI Integrated Application..." -ForegroundColor Green
        $this.Inner = [PmcFakeTUIApp]::new()
        Write-Host "PMC FakeTUI initialized successfully" -ForegroundColor Green
    }

    [void] Initialize() { $this.Inner.Initialize() }
    [void] Run() { $this.Inner.Run() }
    [void] Shutdown() { $this.Inner.Shutdown() }
}

