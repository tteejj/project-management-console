# Excel.ps1 - Excel T2020 integration for ConsoleUI
# Copied from src/Excel.ps1 and adapted for standalone use

Set-StrictMode -Version Latest

# =============================
# Editable Configuration Section
# =============================

# Global configuration variables (user-editable)
$Global:ExcelT2020_SourceFolder = Join-Path $HOME 'excel_input'
$Global:ExcelT2020_DestinationPath = Join-Path $HOME 'excel_output.xlsm'
$Global:ExcelT2020_DestSheetName = 'Output'
$Global:ExcelT2020_SourceSheetName = 'SVI-CAS'

# Field mappings: copy from SourceSheet:SourceCell to DestSheet:DestCell
# ACTUAL mappings from original Excel.ps1 - use UI to add more fields as needed
$Global:ExcelT2020_Mappings = @(
    @{ Field='RequestDate';    SourceCell='W23'; DestCell='B2'; IncludeInTxt=$true }
    @{ Field='AuditType';      SourceCell='W78'; DestCell='B3'; IncludeInTxt=$true }
    @{ Field='AuditorName';    SourceCell='W10'; DestCell='B4'; IncludeInTxt=$true }
    @{ Field='TPName';         SourceCell='W3';  DestCell='B5'; IncludeInTxt=$true }
    @{ Field='TPEmailAddress'; SourceCell='X3';  DestCell='B6'; IncludeInTxt=$true }
    @{ Field='TPPhoneNumber';  SourceCell='Y3';  DestCell='B7'; IncludeInTxt=$true }
    @{ Field='TaxID';          SourceCell='W13'; DestCell='B8'; IncludeInTxt=$true }
    @{ Field='CASNumber';      SourceCell='G17'; DestCell='B9'; IncludeInTxt=$true }
)

# Logging and summary storage
$Global:ExcelT2020_LogPath = Join-Path $HOME 'excel_t2020.log'
$Global:ExcelT2020_SummaryPath = Join-Path $HOME 'excel_t2020_summary.json'
$Global:ExcelT2020_TxtExportPath = Join-Path $HOME 'excel_t2020_export.txt'

# =============================
# Excel COM Management
# =============================

$script:ExcelApp = $null

function New-ExcelApp {
    if ($script:ExcelApp -ne $null) { return $script:ExcelApp }
    try {
        $app = New-Object -ComObject Excel.Application
        $app.Visible = $false
        $app.DisplayAlerts = $false
        $script:ExcelApp = $app
        return $script:ExcelApp
    } catch {
        throw "Excel COM is not available. Ensure Excel is installed. Error: $_"
    }
}

function Close-ExcelApp {
    if ($script:ExcelApp -ne $null) {
        try { $script:ExcelApp.Quit() } catch {}
        try { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($script:ExcelApp) } catch {}
        $script:ExcelApp = $null
    }
}

function Open-Workbook {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [switch]$ReadOnly
    )
    $app = New-ExcelApp
    if (-not (Test-Path $Path)) { throw "Workbook not found: $Path" }
    try { return $app.Workbooks.Open($Path, $false, [bool]$ReadOnly) } catch { throw "Failed to open workbook '$Path': $_" }
}

function Save-Workbook {
    param([Parameter(Mandatory)] $Workbook)
    try { $Workbook.Save() } catch { throw "Failed to save workbook: $_" }
}

function Close-Workbook {
    param([Parameter(Mandatory)] $Workbook)
    try { $Workbook.Close($false) } catch {}
}

function Get-Worksheet {
    param(
        [Parameter(Mandatory)] $Workbook,
        [Parameter(Mandatory)] [string]$Name
    )
    try { return $Workbook.Worksheets.Item($Name) } catch { throw "Worksheet '$Name' not found in '$($Workbook.Name)'." }
}

function Get-WorksheetNames {
    param([Parameter(Mandatory)] $Workbook)
    try {
        $names = @()
        foreach ($ws in $Workbook.Worksheets) {
            $names += $ws.Name
        }
        return $names
    } catch {
        throw "Failed to enumerate worksheets: $_"
    }
}

# =============================
# Core T2020 Operations
# =============================

function Copy-CellValue {
    param(
        [Parameter(Mandatory)] $SourceSheet,
        [Parameter(Mandatory)] [string]$SourceCell,
        [Parameter(Mandatory)] $DestSheet,
        [Parameter(Mandatory)] [string]$DestCell
    )
    $srcRange = $SourceSheet.Range($SourceCell)
    $dstRange = $DestSheet.Range($DestCell)

    $val = $srcRange.Value2
    if ($null -eq $val -or $val -eq '') {
        $dstRange.Value2 = ''
    } else {
        $srcRange.Copy() | Out-Null
        $dstRange.PasteSpecial(-4163) | Out-Null  # xlPasteValues
        (New-ExcelApp).CutCopyMode = 0
    }
}

function Extract-T2020Fields {
    param(
        [Parameter(Mandatory)] [string]$SourcePath,
        [string]$SourceSheetName = $Global:ExcelT2020_SourceSheetName,
        [array] $Mappings        = $Global:ExcelT2020_Mappings
    )
    $srcWb = $null
    try {
        $srcWb = Open-Workbook -Path $SourcePath -ReadOnly
        $wsSrc = Get-Worksheet -Workbook $srcWb -Name $SourceSheetName
        $data = [ordered]@{}
        foreach ($m in $Mappings) {
            $val = $wsSrc.Range($m.SourceCell).Value2
            $data[$m.Field] = $val
        }
        return @{ Success=$true; Data=$data }
    } catch {
        return @{ Success=$false; Error="Extract failed: $_" }
    } finally {
        if ($srcWb) { Close-Workbook -Workbook $srcWb }
    }
}

function Copy-T2020ForFile {
    param(
        [Parameter(Mandatory)] [string]$SourcePath,
        [Parameter(Mandatory)] [string]$DestinationPath,
        [string]$SourceSheetName = $Global:ExcelT2020_SourceSheetName,
        [string]$DestSheetName   = $Global:ExcelT2020_DestSheetName,
        [array] $Mappings        = $Global:ExcelT2020_Mappings
    )
    $srcWb = $null; $dstWb = $null
    try {
        $srcWb = Open-Workbook -Path $SourcePath -ReadOnly
        $dstWb = Open-Workbook -Path $DestinationPath

        $wsSrc = Get-Worksheet -Workbook $srcWb -Name $SourceSheetName
        $wsDst = Get-Worksheet -Workbook $dstWb -Name $DestSheetName

        foreach ($m in $Mappings) {
            Copy-CellValue -SourceSheet $wsSrc -SourceCell $m.SourceCell -DestSheet $wsDst -DestCell $m.DestCell
        }

        Save-Workbook -Workbook $dstWb
        return @{ Success=$true; Message="Copied $($Mappings.Count) fields from '$SourcePath' to '$DestinationPath'" }
    } catch {
        return @{ Success=$false; Error="Copy failed: $_" }
    } finally {
        if ($srcWb) { Close-Workbook -Workbook $srcWb }
        if ($dstWb) { Close-Workbook -Workbook $dstWb }
    }
}

function Export-T2020ToTxt {
    param(
        [Parameter(Mandatory)] [hashtable]$Data,
        [string]$OutputPath = $Global:ExcelT2020_TxtExportPath,
        [array]$Mappings = $Global:ExcelT2020_Mappings
    )
    try {
        $lines = @()
        $lines += "T2020 Export - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $lines += "=" * 60
        $lines += ""

        # Only include fields marked with IncludeInTxt=$true
        foreach ($mapping in $Mappings) {
            if ($mapping.IncludeInTxt -eq $true) {
                $fieldName = $mapping.Field
                if ($Data.ContainsKey($fieldName)) {
                    $value = if ($Data[$fieldName]) { $Data[$fieldName] } else { "(empty)" }
                    $lines += "$($fieldName): $value"
                }
            }
        }

        $lines += ""
        $lines += "=" * 60
        $lines += "End of Export"

        $lines | Set-Content -Path $OutputPath -Encoding UTF8
        return @{ Success=$true; Path=$OutputPath }
    } catch {
        return @{ Success=$false; Error="Txt export failed: $_" }
    }
}

function Invoke-T2020Batch {
    param(
        [string]$SourceFolder = $Global:ExcelT2020_SourceFolder,
        [string]$DestinationPath = $Global:ExcelT2020_DestinationPath,
        [string]$SourcePattern = '*.xlsm',
        [switch]$WhatIf,
        [switch]$ExportTxt
    )
    if (-not (Test-Path $SourceFolder)) { throw "Source folder not found: $SourceFolder" }
    $files = Get-ChildItem -Path $SourceFolder -Filter $SourcePattern -File | Sort-Object Name
    if ($files.Count -eq 0) { return @{ Success=$true; Message='No files found'; Processed=0 } }

    $processed = 0
    $summary = @()
    $latestData = $null

    foreach ($f in $files) {
        if ($WhatIf) {
            Write-Host "Would copy from '$($f.FullName)' to '$DestinationPath'" -ForegroundColor Yellow
            continue
        }
        $extract = Extract-T2020Fields -SourcePath $f.FullName
        $res = Copy-T2020ForFile -SourcePath $f.FullName -DestinationPath $DestinationPath
        $ok = ($res.Success -and $extract.Success)
        $processed += [int]$ok

        if ($ok -and $extract.Success) {
            $latestData = $extract.Data
        }

        $record = [ordered]@{
            Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            Source    = $f.FullName
            Destination = $DestinationPath
            Count     = $Global:ExcelT2020_Mappings.Count
            Success   = $ok
            Error     = if ($ok) { '' } else { ($res.Error ?? $extract.Error) }
            Fields    = if ($extract.Success) { $extract.Data } else { @{} }
        }
        $summary += $record
        try {
            "$($record.Timestamp) | $($record.Source) -> $($record.Destination) | Count=$($record.Count) | Success=$($record.Success) | $($record.Error)" | Add-Content -Path $Global:ExcelT2020_LogPath -Encoding UTF8
        } catch {}
    }

    # Export to txt if requested and we have data
    if ($ExportTxt -and $latestData) {
        $txtResult = Export-T2020ToTxt -Data $latestData
        if ($txtResult.Success) {
            Write-Host "Exported to txt: $($txtResult.Path)" -ForegroundColor Green
        }
    }

    # Persist JSON summary (append)
    try {
        $existing = @()
        if (Test-Path $Global:ExcelT2020_SummaryPath) {
            $existing = Get-Content $Global:ExcelT2020_SummaryPath -Raw | ConvertFrom-Json
        }
        $all = @()
        if ($existing) { $all += $existing }
        $all += $summary
        ($all | ConvertTo-Json -Depth 10) | Set-Content -Path $Global:ExcelT2020_SummaryPath -Encoding UTF8
    } catch {}

    return @{ Success=$true; Processed=$processed; Summary=$summary; LatestData=$latestData }
}

function Set-ExcelT2020Config {
    param(
        [string]$SourceFolder,
        [string]$DestinationPath,
        [string]$SourceSheetName,
        [string]$DestSheetName,
        [string]$TxtExportPath
    )
    if ($PSBoundParameters.ContainsKey('SourceFolder'))     { $Global:ExcelT2020_SourceFolder = $SourceFolder }
    if ($PSBoundParameters.ContainsKey('DestinationPath'))  { $Global:ExcelT2020_DestinationPath = $DestinationPath }
    if ($PSBoundParameters.ContainsKey('SourceSheetName'))  { $Global:ExcelT2020_SourceSheetName = $SourceSheetName }
    if ($PSBoundParameters.ContainsKey('DestSheetName'))    { $Global:ExcelT2020_DestSheetName = $DestSheetName }
    if ($PSBoundParameters.ContainsKey('TxtExportPath'))    { $Global:ExcelT2020_TxtExportPath = $TxtExportPath }
}

# =============================
# Field Mapping Persistence
# =============================

$Global:ExcelT2020_MappingsPath = Join-Path $HOME 'excel_t2020_mappings.json'

function Save-ExcelT2020Mappings {
    <#
    .SYNOPSIS
    Saves current field mappings to disk for persistence across sessions
    #>
    param(
        [string]$Path = $Global:ExcelT2020_MappingsPath
    )
    try {
        $data = @{
            version = 1
            timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            mappings = $Global:ExcelT2020_Mappings
        }
        ($data | ConvertTo-Json -Depth 10) | Set-Content -Path $Path -Encoding UTF8
        return @{ Success=$true; Path=$Path }
    } catch {
        return @{ Success=$false; Error="Failed to save mappings: $_" }
    }
}

function Load-ExcelT2020Mappings {
    <#
    .SYNOPSIS
    Loads field mappings from disk, merging with defaults if needed
    #>
    param(
        [string]$Path = $Global:ExcelT2020_MappingsPath
    )
    try {
        if (-not (Test-Path $Path)) {
            return @{ Success=$false; Error="No saved mappings found at $Path" }
        }

        $data = Get-Content $Path -Raw | ConvertFrom-Json
        if ($data.mappings -and $data.mappings.Count -gt 0) {
            # Convert JSON objects back to hashtables with proper types
            $loadedMappings = @()
            foreach ($m in $data.mappings) {
                $loadedMappings += @{
                    Field = [string]$m.Field
                    SourceCell = [string]$m.SourceCell
                    DestCell = [string]$m.DestCell
                    IncludeInTxt = [bool]$m.IncludeInTxt
                }
            }
            $Global:ExcelT2020_Mappings = $loadedMappings
            return @{ Success=$true; Count=$loadedMappings.Count; Path=$Path }
        } else {
            return @{ Success=$false; Error="No mappings found in file" }
        }
    } catch {
        return @{ Success=$false; Error="Failed to load mappings: $_" }
    }
}

function Initialize-ExcelT2020Mappings {
    <#
    .SYNOPSIS
    Initializes mappings by loading from disk or using defaults
    #>
    $result = Load-ExcelT2020Mappings
    if (-not $result.Success) {
        # Use defaults already set in $Global:ExcelT2020_Mappings
        # Optionally save defaults for next time
        Save-ExcelT2020Mappings | Out-Null
    }
}
