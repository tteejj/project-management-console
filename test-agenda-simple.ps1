# Test agenda in non-interactive mode
$VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'

try {
    Import-Module ./module/Pmc.Strict -Force -ErrorAction Stop
    Write-Host "Module loaded successfully"

    # Test non-interactive agenda
    $ctx = [PmcCommandContext]::new('agenda', '')
    Show-PmcAgenda -Context $ctx
    Write-Host "Agenda completed successfully"

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host "$($_.ScriptStackTrace)"
}