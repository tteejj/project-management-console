# Minimal test of agenda path
$VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'

try {
    Write-Host "Loading module..."
    Import-Module ./module/Pmc.Strict -Force -ErrorAction Stop

    Write-Host "Testing field schemas..."
    $schemas = Get-PmcFieldSchemasForDomain 'task'
    Write-Host "Field schemas loaded: $($schemas.Keys.Count) fields"

    Write-Host "Testing Show-PmcData..."
    # This is what Show-PmcAgendaInteractive calls
    Show-PmcData -DataType "task" -Filters @{
        "status" = "pending"
        "due_range" = "overdue_and_today"
    } -Title "Test Agenda"

    Write-Host "SUCCESS: All tests passed"

} catch {
    Write-Host "ERROR at: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Category: $($_.CategoryInfo.Category)" -ForegroundColor Yellow
    Write-Host "Stack: $($_.ScriptStackTrace)" -ForegroundColor Gray
}