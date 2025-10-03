Set-StrictMode -Version Latest

function Show-PmcQueryFields {
    [CmdletBinding()] param(
        [Parameter(Mandatory=$true)][ValidateSet('task','project','timelog')][string]$Domain,
        [switch]$Json
    )
    $schemas = Get-PmcFieldSchemasForDomain -Domain $Domain
    $rows = @()
    foreach ($name in ($schemas.Keys | Sort-Object)) {
        $s = $schemas[$name]
        $type = if ($s.PSObject.Properties['Type']) { [string]$s.Type } else { 'string' }
        $ops = @(':','=','>','<','>=','<=','~','exists')
        if ($type -eq 'date' -or $name -eq 'due') { $ops += @('today','tomorrow','overdue','+N','eow','eom') }
        $rows += [pscustomobject]@{
            Field = $name
            Type = $type
            Operators = ($ops -join ', ')
            Example = switch ($name) {
                'project' { '@inbox' }
                'tags'    { '#urgent' }
                'priority'{ 'p<=2' }
                'due'     { 'due:today' }
                default   { "$name:value" }
            }
        }
    }
    if ($Json) { $rows | ConvertTo-Json -Depth 5; return }
    Show-PmcDataGrid -Domains @("$Domain-fields") -Columns @{
        Field=@{Header='Field';Width=18}
        Type=@{Header='Type';Width=10}
        Operators=@{Header='Operators';Width=40}
        Example=@{Header='Example';Width=20}
    } -Data $rows -Title ("Fields — {0}" -f $Domain)
}

function Show-PmcQueryColumns {
    [CmdletBinding()] param(
        [Parameter(Mandatory=$true)][ValidateSet('task','project','timelog')][string]$Domain,
        [switch]$Json
    )
    $defaults = Get-PmcDefaultColumns -DataType $Domain
    $schemas = Get-PmcFieldSchemasForDomain -Domain $Domain
    $rows = @()
    # Default columns first
    foreach ($k in $defaults.Keys) {
        $cfg = $defaults[$k]
        $rows += [pscustomobject]@{
            Column=$k; Header=[string]$cfg.Header; Default=$true; Sortable=$true; Editable=($cfg.Editable -eq $true)
        }
    }
    # Other fields available
    foreach ($name in $schemas.Keys) {
        if ($rows | Where-Object { $_.Column -eq $name }) { continue }
        $s = $schemas[$name]
        $rows += [pscustomobject]@{
            Column=$name; Header=$name; Default=$false; Sortable=$true; Editable=($s.Editable -eq $true)
        }
    }
    if ($Json) { $rows | ConvertTo-Json -Depth 5; return }
    Show-PmcDataGrid -Domains @("$Domain-columns") -Columns @{
        Column=@{Header='Column';Width=18}
        Header=@{Header='Header';Width=20}
        Default=@{Header='Default';Width=8}
        Sortable=@{Header='Sortable';Width=8}
        Editable=@{Header='Editable';Width=8}
    } -Data $rows -Title ("Columns — {0}" -f $Domain)
}

function Show-PmcQueryValues {
    [CmdletBinding()] param(
        [Parameter(Mandatory=$true)][ValidateSet('task','project','timelog')][string]$Domain,
        [Parameter(Mandatory=$true)][string]$Field,
        [int]$Top=50,
        [string]$StartsWith,
        [switch]$Json
    )
    $data = switch ($Domain) {
        'task'    { if (Get-Command Get-PmcTasksData -ErrorAction SilentlyContinue)    { Get-PmcTasksData }    else { @() } }
        'project' { if (Get-Command Get-PmcProjectsData -ErrorAction SilentlyContinue) { Get-PmcProjectsData } else { @() } }
        'timelog' { if (Get-Command Get-PmcTimeLogsData -ErrorAction SilentlyContinue) { Get-PmcTimeLogsData } else { @() } }
    }
    $values = @()
    foreach ($row in $data) {
        if ($null -eq $row) { continue }
        if ($row.PSObject.Properties[$Field]) {
            $v = $row."$Field"
            if ($v -is [System.Collections.IEnumerable] -and -not ($v -is [string])) {
                foreach ($x in $v) { if ($null -ne $x) { $values += [string]$x } }
            } else {
                if ($null -ne $v) { $values += [string]$v }
            }
        }
    }
    $distinct = @($values | Where-Object { $_ -and $_.Trim() -ne '' } | Select-Object -Unique | Sort-Object)
    if ($StartsWith) { $distinct = @($distinct | Where-Object { $_.ToLower().StartsWith($StartsWith.ToLower()) }) }
    $distinct = @($distinct | Select-Object -First $Top)
    $rows = @(); foreach ($v in $distinct) { $rows += [pscustomobject]@{ Value=$v } }
    if ($Json) { $rows | ConvertTo-Json -Depth 5; return }
    Show-PmcDataGrid -Domains @("$Domain-values") -Columns @{ Value=@{Header='Value';Width=50} } -Data $rows -Title ("Values — {0}.{1}" -f $Domain,$Field)
}

function Show-PmcQueryDirectives {
    [CmdletBinding()] param(
        [ValidateSet('task','project','timelog')][string]$Domain,
        [switch]$Json
    )
    $rows = @()
    $rows += [pscustomobject]@{ Directive='cols';      Syntax='cols:id,text,project';         Notes='Select display columns' }
    $rows += [pscustomobject]@{ Directive='sort';      Syntax='sort:due+ | sort:priority-';  Notes='Field+ asc, Field- desc' }
    $rows += [pscustomobject]@{ Directive='group';     Syntax='group:project';                Notes='Grouping (display; planned)' }
    $rows += [pscustomobject]@{ Directive='limit';     Syntax='limit:50';                     Notes='Max items' }
    $rows += [pscustomobject]@{ Directive='shorthand'; Syntax='@project #tag p<=2 due:today'; Notes='Helpers for common filters' }
    if ($Json) { $rows | ConvertTo-Json -Depth 5; return }
    Show-PmcDataGrid -Domains @('query-directives') -Columns @{
        Directive=@{Header='Directive';Width=12}
        Syntax=@{Header='Syntax';Width=40}
        Notes=@{Header='Notes';Width=40}
    } -Data $rows -Title 'Query Directives'
}

Export-ModuleMember -Function Show-PmcQueryFields, Show-PmcQueryColumns, Show-PmcQueryValues, Show-PmcQueryDirectives

