Set-StrictMode -Version Latest

class PmcSecureFileManager {
    [bool] ValidatePath([string]$Path, [string]$Operation) {
        try { return (Test-PmcPathSafety -Path $Path -Operation $Operation) } catch { return $false }
    }

    [bool] ValidateContent([string]$Content, [string]$Type) {
        try { return (Test-PmcInputSafety -Input $Content -InputType $Type) } catch { return $true }
    }

    [void] WriteFile([string]$Path, [string]$Content) {
        if (-not $this.ValidatePath($Path,'write')) { throw "Path not allowed: $Path" }
        if (-not $this.ValidateContent($Content,'json')) { throw "Content failed safety validation" }
        Invoke-PmcSecureFileOperation -Path $Path -Operation 'write' -Content $Content
    }

    [string] ReadFile([string]$Path) {
        if (-not $this.ValidatePath($Path,'read')) { throw "Path not allowed: $Path" }
        return (Get-Content -Path $Path -Raw -Encoding UTF8)
    }
}

function Get-PmcSecureFileManager {
    if (-not $Script:PmcSecureFileManager) { $Script:PmcSecureFileManager = [PmcSecureFileManager]::new() }
    return $Script:PmcSecureFileManager
}

function Sanitize-PmcCommandInput { param([string]$Text) return (Protect-PmcUserInput -Input $Text) }

Export-ModuleMember -Function Get-PmcSecureFileManager, Sanitize-PmcCommandInput

