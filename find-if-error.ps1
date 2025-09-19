# Script to find the exact location of the "if" error
$ErrorActionPreference = 'Stop'

try {
    Write-Host "Loading module with full error details..."
    Import-Module ./module/Pmc.Strict -Force

    # Override the error handling to capture more details
    $originalErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    # Capture all errors in a variable
    $errorDetails = @()

    # Add error event handler
    $errorHandler = {
        param($sender, $e)
        if ($e.Exception.Message -like "*if*not recognized*") {
            $errorDetails += @{
                Message = $e.Exception.Message
                StackTrace = $e.Exception.StackTrace
                ScriptStackTrace = $e.ScriptStackTrace
                InvocationInfo = $e.InvocationInfo
                TimeStamp = Get-Date
            }
        }
    }

    # Try to run the agenda command with error trapping
    try {
        Show-PmcAgendaInteractive 2>&1 | Out-Null
    } catch {
        if ($_.Exception.Message -like "*if*not recognized*") {
            Write-Host "FOUND THE ERROR!" -ForegroundColor Red
            Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "At: $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Cyan
            Write-Host "Position: $($_.InvocationInfo.PositionMessage)" -ForegroundColor Gray
            Write-Host "Stack trace:" -ForegroundColor Magenta
            Write-Host $_.ScriptStackTrace -ForegroundColor Gray
        } else {
            Write-Host "Different error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

} catch {
    Write-Host "Setup error: $($_.Exception.Message)" -ForegroundColor Red
}