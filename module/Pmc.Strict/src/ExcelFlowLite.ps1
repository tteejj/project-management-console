# ExcelFlowLite.ps1 - Minimal interactive path picker + config hooks for Excel flow

Set-StrictMode -Version Latest

function Get-PmcXFlowConfig {
    $data = Get-PmcData
    if (-not $data.PSObject.Properties['excelFlow']) {
        $data | Add-Member -NotePropertyName excelFlow -NotePropertyValue @{ config=@{}; runs=@() } -Force
    } else {
        if (-not ($data.excelFlow -is [hashtable])) { try { $data.excelFlow = @{} + $data.excelFlow } catch { $data.excelFlow = @{} } }
        if (-not $data.excelFlow.PSObject.Properties['config']) { $data.excelFlow['config'] = @{} }
        if (-not $data.excelFlow.PSObject.Properties['runs']) { $data.excelFlow['runs'] = @() }
    }
    return $data
}

function Set-PmcXFlowConfigValue {
    param(
        [Parameter(Mandatory)] [string]$Key,
        [Parameter(Mandatory)] [string]$Value
    )
    $data = Get-PmcXFlowConfig
    $data.excelFlow.config[$Key] = $Value
    Save-PmcData -Data $data -Action ("xflow:set:{0}" -f $Key)
}

function Invoke-PmcPathPicker {
    param(
        [string]$StartDir = '.',
        [ValidateSet('File','Directory')] [string]$Pick = 'File',
        [string[]]$Extensions = @(),
        [string]$Title = 'Select Path'
    )

    # Resolve and validate starting directory
    $current = $StartDir
    try { if (-not (Test-Path $current)) { $current = (Get-Location).Path } } catch { $current = (Get-Location).Path }

    while ($true) {
        # Gather entries
        $rows = @()

        # Parent directory entry when possible
        try {
            $root = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($current))
        } catch { $root = $current }
        if ($current -ne $root) {
            $parent = Split-Path $current -Parent
            $rows += [pscustomobject]@{
                Name = '..'
                Type = 'Dir'
                Size = ''
                Modified = ''
                Path = $parent
            }
        }

        # Directories first
        try {
            $dirs = Get-ChildItem -LiteralPath $current -Directory -ErrorAction SilentlyContinue | Sort-Object Name
            foreach ($d in $dirs) {
                $rows += [pscustomobject]@{
                    Name = $d.Name
                    Type = 'Dir'
                    Size = ''
                    Modified = $d.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
                    Path = $d.FullName
                }
            }
        } catch {}

        # Files
        try {
            $files = Get-ChildItem -LiteralPath $current -File -ErrorAction SilentlyContinue
            if ($Extensions -and @($Extensions).Count -gt 0) {
                # Normalize extensions list to regex
                $patterns = @()
                foreach ($pat in $Extensions) {
                    if ([string]::IsNullOrWhiteSpace($pat)) { continue }
                    $esc = [Regex]::Escape($pat.Trim())
                    $esc = $esc.Replace('\\*', '.*').Replace('\\?', '.')
                    $patterns += "^$esc$"
                }
                $files = $files | Where-Object { $name = $_.Name; $patterns | Where-Object { $name -match $_ } }
            }
            $files = $files | Sort-Object Name
            foreach ($f in $files) {
                $rows += [pscustomobject]@{
                    Name = $f.Name
                    Type = 'File'
                    Size = $f.Length
                    Modified = $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
                    Path = $f.FullName
                }
            }
        } catch {}

        # Add a cancel row to allow exit without selection
        $rows = ,([pscustomobject]@{ Name='[Cancel]'; Type='Action'; Size=''; Modified=''; Path='' }) + $rows

        # Columns configuration
        $cols = @{
            Name     = @{ Header='Name';     Width=38; Alignment='Left' }
            Type     = @{ Header='Type';     Width=6;  Alignment='Left' }
            Size     = @{ Header='Size';     Width=10; Alignment='Right' }
            Modified = @{ Header='Modified'; Width=16; Alignment='Center' }
        }

        # Render interactively using the grid renderer (pattern from HelpUI)
        $displayTitle = "{0} — {1}" -f $Title, $current
        try {
            Write-PmcStyled -Style 'Title' -Text ("`n$displayTitle")
            $winW = [PmcTerminalService]::GetWidth()
            Write-PmcStyled -Style 'Border' -Text ("─" * [Math]::Max(20, $winW))
            $renderer = [PmcGridRenderer]::new($cols, @('help'), @{})
            $renderer.StartInteractive($rows)
            $selectedIndex = [int]$renderer.SelectedRow
        } catch {
            $selectedIndex = 1
        }

        if ($selectedIndex -lt 0 -or $selectedIndex -ge @($rows).Count) { return '' }
        $sel = $rows[$selectedIndex]
        if ($sel.Name -eq '[Cancel]') { return '' }

        if ($sel.Type -eq 'Dir') {
            if ($Pick -eq 'Directory') { return [string]$sel.Path }
            # Drill into directory and refresh
            $current = [string]$sel.Path
            continue
        }

        if ($sel.Type -eq 'File') {
            if ($Pick -eq 'File') { return [string]$sel.Path }
            # If picking a directory but file selected, stay in loop
            continue
        }
    }
}

function Set-PmcXFlowSourcePathInteractive {
    param([PmcCommandContext]$Context)
    try {
        $data = Get-PmcXFlowConfig
        $start = (Get-Location).Path
        if ($data.excelFlow.config.ContainsKey('SourceFile')) {
            try { $start = Split-Path [string]$data.excelFlow.config.SourceFile -Parent } catch {}
        }
        $path = Invoke-PmcPathPicker -StartDir $start -Pick 'File' -Extensions @('*.xls','*.xlsx','*.xlsm') -Title 'Select Source Excel Workbook'
        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-PmcStyled -Style 'Warning' -Text 'No source file selected.'
            return
        }
        Set-PmcXFlowConfigValue -Key 'SourceFile' -Value $path
        Write-PmcStyled -Style 'Success' -Text ("SourceFile set: {0}" -f $path)
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Source selection failed: {0}" -f $_)
    }
}

function Set-PmcXFlowDestPathInteractive {
    param([PmcCommandContext]$Context)
    try {
        $data = Get-PmcXFlowConfig
        $start = (Get-Location).Path
        if ($data.excelFlow.config.ContainsKey('DestFile')) {
            try { $start = Split-Path [string]$data.excelFlow.config.DestFile -Parent } catch {}
        } elseif ($data.excelFlow.config.ContainsKey('SourceFile')) {
            try { $start = Split-Path [string]$data.excelFlow.config.SourceFile -Parent } catch {}
        }
        $path = Invoke-PmcPathPicker -StartDir $start -Pick 'File' -Extensions @('*.xls','*.xlsx','*.xlsm') -Title 'Select Destination Excel Workbook'
        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-PmcStyled -Style 'Warning' -Text 'No destination file selected.'
            return
        }
        Set-PmcXFlowConfigValue -Key 'DestFile' -Value $path
        Write-PmcStyled -Style 'Success' -Text ("DestFile set: {0}" -f $path)
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Destination selection failed: {0}" -f $_)
    }
}

function Get-PmcXFlowConfigData {
    # Returns current config without inventing field mappings
    $data = Get-PmcXFlowConfig
    return $data.excelFlow.config
}

function Save-PmcXFlowConfigData {
    param([hashtable]$Config)
    $data = Get-PmcXFlowConfig
    $data.excelFlow.config = $Config
    Save-PmcData -Data $data -Action 'xflow:save-config'
}

function New-XFlowWorkbook {
    param([string]$Path)
    try {
        $app = $null
        try { $app = New-ExcelApp } catch { $app = $null }
        if (-not $app) { $app = New-Object -ComObject Excel.Application }
        $app.Visible = $false; $app.DisplayAlerts = $false
        $wb = $app.Workbooks.Add()
        $wb.SaveAs($Path)
        return $wb
    } catch { throw "Failed to create workbook: $_" }
}

function Get-OrAddWorksheet {
    param([Parameter(Mandatory)] $Workbook,[Parameter(Mandatory)][string]$Name)
    try { return $Workbook.Worksheets.Item($Name) } catch {
        try { $ws = $Workbook.Worksheets.Add(); $ws.Name = $Name; return $ws } catch { throw "Failed to get or create sheet '$Name': $_" }
    }
}

function Export-XFlowToJson {
    param([hashtable]$Data,[string]$OutPath)
    $obj = @{ ExportTimestamp=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); FieldCount=$Data.Count; Data=$Data }
    $safe = Get-PmcSafePath $OutPath
    $dir = Split-Path $safe -Parent; if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $obj | ConvertTo-Json -Depth 10 | Set-Content -Path $safe -Encoding UTF8
    return $safe
}

function Export-XFlowToCsv {
    param([hashtable]$Data,[string]$OutPath)
    $headers = $Data.Keys | Sort-Object
    $vals = @(); foreach ($h in $headers) { $v = if ($Data[$h]) { $Data[$h].ToString() } else { '' }; if ($v -match ',|"|`n') { $v = '"' + $v.Replace('"','""') + '"' }; $vals += $v }
    $lines = @(); $lines += ($headers -join ','); $lines += ($vals -join ',')
    $safe = Get-PmcSafePath $OutPath
    $dir = Split-Path $safe -Parent; if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $lines | Set-Content -Path $safe -Encoding UTF8
    return $safe
}

function Show-PmcXFlowPreview {
    param([PmcCommandContext]$Context)
    $max = 10; try { if ($Context.Args.ContainsKey('max')) { $max = [int]$Context.Args['max'] } } catch {}
    $dry = $false; try { $dry = $Context.Args.ContainsKey('dry') } catch {}
    $cfg = Get-PmcXFlowConfigData
    if (-not $cfg.FieldMappings -or @($cfg.FieldMappings.Keys).Count -eq 0) { Write-PmcStyled -Style 'Warning' -Text 'No FieldMappings configured. Import mappings first.'; return }

    if ($dry) {
        Write-PmcStyled -Style 'Title' -Text 'XFlow Preview (dry)'
        Write-PmcStyled -Style 'Border' -Text ("─" * 50)
        $names = $cfg.FieldMappings.Keys | Select-Object -First $max
        foreach ($n in $names) {
            $map = $cfg.FieldMappings[$n]
            $cell = $map.Cell
            $srcSheet = if ($map.PSObject.Properties['Sheet'] -and $map.Sheet) { [string]$map.Sheet } else { [string]$cfg.SourceSheet }
            Write-Host ("  {0,-20} {1,-12} {2,-10} {3}" -f $n, $srcSheet, $cell, '(dry)')
        }
        return
    }

    if (-not $cfg.SourceFile) { Write-PmcStyled -Style 'Warning' -Text 'No SourceFile configured. Use xflow browse-source.'; return }
    if (-not (Test-Path $cfg.SourceFile)) { Write-PmcStyled -Style 'Error' -Text ("Source file not found: {0}" -f $cfg.SourceFile); return }

    $srcWb = $null
    try {
        $srcWb = Open-Workbook -Path $cfg.SourceFile -ReadOnly
        $sheetCache = @{}
        $names = $cfg.FieldMappings.Keys | Select-Object -First $max
        Write-PmcStyled -Style 'Title' -Text ("XFlow Preview - {0}" -f (Split-Path $cfg.SourceFile -Leaf))
        Write-PmcStyled -Style 'Border' -Text ("─" * 50)
        foreach ($n in $names) {
            $map = $cfg.FieldMappings[$n]
            $cell = $map.Cell
            $srcSheet = if ($map.PSObject.Properties['Sheet'] -and $map.Sheet) { [string]$map.Sheet } else { [string]$cfg.SourceSheet }
            if (-not $sheetCache.ContainsKey($srcSheet)) { $sheetCache[$srcSheet] = Get-Worksheet -Workbook $srcWb -Name $srcSheet }
            $wsSrc = $sheetCache[$srcSheet]
            $val = $null; try { $val = $wsSrc.Range($cell).Value2 } catch {}
            $short = if ($val) { $s=$val.ToString(); if ($s.Length -gt 50) { $s.Substring(0,47)+'...' } else { $s } } else { '' }
            Write-Host ("  {0,-20} {1,-12} {2,-10} {3}" -f $n, $srcSheet, $cell, $short)
        }
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Preview failed: {0}" -f $_)
    } finally {
        if ($srcWb) { Close-Workbook -Workbook $srcWb }
        Close-ExcelApp
    }
}

function Invoke-PmcXFlowRun {
    param([PmcCommandContext]$Context)
    $args = $Context.Args
    $whatIf = $args.ContainsKey('whatif')
    $noExcel = $args.ContainsKey('noexcel') -or $args.ContainsKey('noexcelexport')
    $dry = $args.ContainsKey('dry')
    $format = $null; if ($args.ContainsKey('format')) { $format = [string]$args['format'] }
    $valuesPath = $null; if ($args.ContainsKey('values')) { $valuesPath = [string]$args['values'] }

    $cfg = Get-PmcXFlowConfigData
    if (-not $cfg.FieldMappings -or @($cfg.FieldMappings.Keys).Count -eq 0) { Write-PmcStyled -Style 'Warning' -Text 'No FieldMappings configured. Import mappings first.'; return }

    $start = Get-Date
    $srcWb = $null; $dstWb = $null
    $extracted = @{}
    $errors = @()

    try {
        if ($dry) {
            # Build synthetic extraction values
            $provided = $null
            if ($valuesPath -and (Test-Path $valuesPath)) {
                try {
                    $raw = Get-Content -Path $valuesPath -Raw | ConvertFrom-Json -AsHashtable
                    if ($raw.ContainsKey('Data')) { $provided = $raw['Data'] } else { $provided = $raw }
                } catch { $provided = $null; $errors += "Failed to parse values file: $valuesPath" }
            }
            foreach ($field in $cfg.FieldMappings.Keys) {
                if ($provided -and $provided.ContainsKey($field)) {
                    $extracted[$field] = $provided[$field]
                } else {
                    $m = $cfg.FieldMappings[$field]
                    $srcSheet = if ($m.PSObject.Properties['Sheet'] -and $m.Sheet) { [string]$m.Sheet } else { [string]$cfg.SourceSheet }
                    $cell = $m.Cell
                    $extracted[$field] = ("<{0}!{1}>" -f $srcSheet, $cell)
                }
            }
        } else {
            if (-not $cfg.SourceFile) { Write-PmcStyled -Style 'Warning' -Text 'No SourceFile configured. Use xflow browse-source.'; return }
            if (-not (Test-Path $cfg.SourceFile)) { Write-PmcStyled -Style 'Error' -Text ("Source file not found: {0}" -f $cfg.SourceFile); return }
            if ($whatIf) { Write-PmcStyled -Style 'Info' -Text 'WhatIf: extracting values (no writes).' }
            $srcWb = Open-Workbook -Path $cfg.SourceFile -ReadOnly
            $srcSheets = @{}
            foreach ($field in $cfg.FieldMappings.Keys) {
                $map = $cfg.FieldMappings[$field]
                $cell = $map.Cell
                $srcSheet = if ($map.PSObject.Properties['Sheet'] -and $map.Sheet) { [string]$map.Sheet } else { [string]$cfg.SourceSheet }
                try {
                    if (-not $srcSheets.ContainsKey($srcSheet)) { $srcSheets[$srcSheet] = Get-Worksheet -Workbook $srcWb -Name $srcSheet }
                    $wsSrc = $srcSheets[$srcSheet]
                    $val = $wsSrc.Range($cell).Value2
                } catch { $val=$null; $errors += "Read failed: $field $srcSheet!$cell" }
                $extracted[$field] = $val
            }

            if (-not $noExcel -and $cfg.DestFile) {
                if (-not $whatIf) {
                    if (Test-Path $cfg.DestFile) { $dstWb = Open-Workbook -Path $cfg.DestFile } else { $dstWb = New-XFlowWorkbook -Path $cfg.DestFile }
                    $dstSheets = @{}
                    foreach ($field in $cfg.FieldMappings.Keys) {
                        $map = $cfg.FieldMappings[$field]
                        $dest = $map.DestCell
                        $dstSheetName = if ($map.PSObject.Properties['DestSheet'] -and $map.DestSheet) { [string]$map.DestSheet } else { [string]$cfg.DestSheet }
                        if ($dest -and $dest.Trim().Length -gt 0) {
                            try {
                                if (-not $dstSheets.ContainsKey($dstSheetName)) { $dstSheets[$dstSheetName] = Get-OrAddWorksheet -Workbook $dstWb -Name $dstSheetName }
                                $wsDst = $dstSheets[$dstSheetName]
                                $wsDst.Range($dest).Value2 = $extracted[$field]
                            } catch { $errors += "Write failed: $field $dstSheetName!$dest" }
                        }
                    }
                    try { Save-Workbook -Workbook $dstWb } catch { $errors += "Save failed: $($cfg.DestFile)" }
                } else {
                    Write-PmcStyled -Style 'Info' -Text ("WhatIf: would update destination workbook: {0}" -f $cfg.DestFile)
                }
            }
        }

        # Optional text export
        $exportPath = $null
        if ($format) {
            $ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
            switch ($format.ToUpper()) {
                'CSV' { $exportPath = Export-XFlowToCsv -Data $extracted -OutPath ("exports/ExcelDataExport_{0}.csv" -f $ts) }
                'JSON' { $exportPath = Export-XFlowToJson -Data $extracted -OutPath ("exports/ExcelDataExport_{0}.json" -f $ts) }
                default { Write-PmcStyled -Style 'Warning' -Text ("Unsupported format: {0} (use csv|json)" -f $format) }
            }
        }

        # Record run
        $data = Get-PmcXFlowConfig
        $run = [ordered]@{
            Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            SourceFile = if ($cfg.SourceFile) { $cfg.SourceFile } else { '(dry)' }
            DestFile = if ($cfg.DestFile) { $cfg.DestFile } else { '' }
            FieldCount = $cfg.FieldMappings.Count
            Success = ($errors.Count -eq 0)
            Errors = $errors
            DurationMs = [int]((Get-Date) - $start).TotalMilliseconds
            ExportPath = $exportPath
            DryRun = $dry
        }
        $data.excelFlow['latestExtract'] = $extracted
        if (-not $data.excelFlow.PSObject.Properties['runs'] -or -not $data.excelFlow.runs) { $data.excelFlow['runs'] = @() }
        $data.excelFlow.runs += $run
        if (@($data.excelFlow.runs).Count -gt 20) { $data.excelFlow.runs = $data.excelFlow.runs[-20..-1] }
        Save-PmcData -Data $data -Action 'xflow:run'

        if ($run.Success) {
            Write-PmcStyled -Style 'Success' -Text ("XFlow {0} run completed. {1} fields." -f ($dry ? 'dry' : 'live'), $run.FieldCount)
            if ($exportPath) { Write-PmcStyled -Style 'Info' -Text ("Text export: {0}" -f $exportPath) }
        } else {
            Write-PmcStyled -Style 'Warning' -Text ("XFlow completed with errors: {0}" -f ($errors -join '; '))
        }
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Run failed: {0}" -f $_)
    } finally {
        if ($srcWb) { try { Close-Workbook -Workbook $srcWb } catch {} }
        if ($dstWb) { try { Close-Workbook -Workbook $dstWb } catch {} }
        try { Close-ExcelApp } catch {}
    }
}

function Import-PmcXFlowMappingsFromFile {
    param([PmcCommandContext]$Context)
    $args = $Context.Args
    if (-not $args.ContainsKey('path')) { Write-PmcStyled -Style 'Info' -Text "Usage: xflow import-mappings path:<settings.json>"; return }
    $path = [string]$args['path']
    if (-not (Test-Path $path)) { Write-PmcStyled -Style 'Error' -Text ("File not found: {0}" -f $path); return }
    try {
        $json = Get-Content -Path $path -Raw | ConvertFrom-Json -AsHashtable
        $spec = $null
        if ($json.ContainsKey('ExcelMappings')) { $spec = $json['ExcelMappings'] }
        else { $spec = $json }
        if (-not $spec -or -not $spec.ContainsKey('FieldMappings')) { Write-PmcStyled -Style 'Error' -Text 'No FieldMappings section found.'; return }

        $cfg = Get-PmcXFlowConfigData
        # Copy top-level fields if available
        foreach ($k in @('SourceFile','DestFile','SourceSheet','DestSheet')) { if ($spec.ContainsKey($k) -and $spec[$k]) { $cfg[$k] = [string]$spec[$k] } }

        # Exact FieldMappings transfer (no invention)
        $out = @{}
        foreach ($fname in $spec.FieldMappings.Keys) {
            $m = $spec.FieldMappings[$fname]
            $entry = @{}
            foreach ($mk in @('Sheet','Cell','DestCell','DestSheet')) {
                if ($m.PSObject.Properties[$mk] -and $m[$mk]) { $entry[$mk] = [string]$m[$mk] }
            }
            $out[$fname] = $entry
        }
        $cfg['FieldMappings'] = $out
        Save-PmcXFlowConfigData -Config $cfg
        Write-PmcStyled -Style 'Success' -Text ("Imported {0} field mappings from {1}" -f $out.Keys.Count, $path)
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Import failed: {0}" -f $_)
    }
}

function Export-PmcXFlowText {
    param([PmcCommandContext]$Context)
    $format = 'CSV'; if ($Context.Args.ContainsKey('format')) { $format = [string]$Context.Args['format'] }
    $data = Get-PmcXFlowConfig
    if (-not $data.excelFlow.PSObject.Properties['latestExtract'] -or -not $data.excelFlow.latestExtract) { Write-PmcStyled -Style 'Warning' -Text 'No latest extract found. Run xflow run first.'; return }
    $extracted = $data.excelFlow.latestExtract
    $ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
    switch ($format.ToUpper()) {
        'CSV'  { $out = Export-XFlowToCsv -Data $extracted -OutPath ("exports/ExcelDataExport_{0}.csv" -f $ts) }
        'JSON' { $out = Export-XFlowToJson -Data $extracted -OutPath ("exports/ExcelDataExport_{0}.json" -f $ts) }
        default { Write-PmcStyled -Style 'Warning' -Text ("Unsupported format: {0} (use csv|json)" -f $format); return }
    }
    Write-PmcStyled -Style 'Success' -Text ("Exported {0} fields to {1}" -f $extracted.Keys.Count, $out)
}

function Set-PmcXFlowLatestFromFile {
    param([PmcCommandContext]$Context)
    if (-not $Context.Args.ContainsKey('values')) { Write-PmcStyled -Style 'Info' -Text "Usage: xflow set-latest values:<path.json>"; return }
    $path = [string]$Context.Args['values']
    if (-not (Test-Path $path)) { Write-PmcStyled -Style 'Error' -Text ("File not found: {0}" -f $path); return }
    try {
        $raw = Get-Content -Path $path -Raw | ConvertFrom-Json -AsHashtable
        $dict = if ($raw.ContainsKey('Data')) { $raw['Data'] } else { $raw }
        if (-not ($dict -is [hashtable])) { Write-PmcStyled -Style 'Error' -Text 'Values JSON must be an object or contain a Data object.'; return }
        $data = Get-PmcXFlowConfig
        $data.excelFlow['latestExtract'] = $dict
        Save-PmcData -Data $data -Action 'xflow:set-latest'
        Write-PmcStyled -Style 'Success' -Text ("latestExtract set from {0}. Fields: {1}" -f $path, $dict.Keys.Count)
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Failed to set latest: {0}" -f $_)
    }
}
