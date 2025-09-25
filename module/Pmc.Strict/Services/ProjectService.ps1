Set-StrictMode -Version Latest

class PmcProjectService {
    hidden $_state
    hidden $_logger

    PmcProjectService([object]$stateManager, [object]$logger) {
        $this._state = $stateManager
        $this._logger = $logger
    }

    [pscustomobject] AddProject([string]$Name, [string]$Description) {
        $data = Get-PmcData
        if (-not $data.projects) { $data.projects = @() }

        # If exists, update description
        $existing = @($data.projects | Where-Object { $_.name -eq $Name })
        if ($existing.Count -gt 0) {
            $existing[0].description = $Description
            Save-PmcData $data
            return $existing[0]
        }

        $proj = [pscustomobject]@{
            name = $Name
            description = $Description
            status = 'active'
            created = (Get-Date).ToString('o')
        }
        $data.projects += $proj
        Save-PmcData $data
        return $proj
    }

    [object[]] GetProjects() {
        $data = Get-PmcData
        return ,@($data.projects)
    }
}

function New-PmcProjectService { param($StateManager,$Logger) return [PmcProjectService]::new($StateManager,$Logger) }

function Add-PmcProject {
    param([PmcCommandContext]$Context)
    $svc = Get-PmcService -Name 'ProjectService'
    if (-not $svc) { throw 'ProjectService not available' }
    $name = ''
    $desc = ''
    if (@($Context.FreeText).Count -gt 0) { $name = [string]$Context.FreeText[0] }
    if (@($Context.FreeText).Count -gt 1) { $desc = ($Context.FreeText | Select-Object -Skip 1) -join ' ' }
    $res = $svc.AddProject($name,$desc)
    Write-PmcStyled -Style 'Success' -Text ("✓ Project ensured: {0}" -f $res.name)
    return $res
}

function Get-PmcProjectList {
    $svc = Get-PmcService -Name 'ProjectService'
    if (-not $svc) { throw 'ProjectService not available' }
    return $svc.GetProjects()
}

Export-ModuleMember -Function Add-PmcProject, Get-PmcProjectList, New-PmcProjectService

