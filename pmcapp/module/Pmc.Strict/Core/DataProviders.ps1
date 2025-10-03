# Core data providers for Unified UI (pure data, no UI writes)

Set-StrictMode -Version Latest

function Get-PmcTasksData {
    try {
        $root = Get-PmcDataAlias
        $items = @()
        if ($root -and $root.PSObject.Properties['tasks']) { $items = @($root.tasks) }
        return ,$items
    } catch {
        Write-PmcDebug -Level 1 -Category 'DataProviders' -Message ("Get-PmcTasksData failed: {0}" -f $_)
        return @()
    }
}

function Get-PmcProjectsData {
    try {
        $root = Get-PmcDataAlias
        $items = @()
        if ($root -and $root.PSObject.Properties['projects']) { $items = @($root.projects) }
        return ,$items
    } catch {
        Write-PmcDebug -Level 1 -Category 'DataProviders' -Message ("Get-PmcProjectsData failed: {0}" -f $_)
        return @()
    }
}

function Get-PmcTimeLogsData {
    try {
        $root = Get-PmcDataAlias
        $items = @()
        if ($root -and $root.PSObject.Properties['timelogs']) { $items = @($root.timelogs) }
        return ,$items
    } catch {
        Write-PmcDebug -Level 1 -Category 'DataProviders' -Message ("Get-PmcTimeLogsData failed: {0}" -f $_)
        return @()
    }
}

Export-ModuleMember -Function Get-PmcTasksData, Get-PmcProjectsData, Get-PmcTimeLogsData

