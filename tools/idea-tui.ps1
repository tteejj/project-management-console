# Standalone multi-pane TUI for IDEA Macro Builder
# Uses PMC TUI components (module/Pmc.Strict) for screen and drawing
# Panes: [1] Steps, [2] Editor, [3] Preview

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Load PMC TUI (Pmc.Strict)
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$pmcModule = Join-Path $repoRoot 'module/Pmc.Strict/Pmc.Strict.psm1'
if (-not (Test-Path -LiteralPath $pmcModule)) {
    Write-Host "PMC TUI not found at $pmcModule" -ForegroundColor Red
    exit 1
}
try {
    Import-Module -Force -Name $pmcModule -ErrorAction Stop
} catch {
    Write-Host "Failed to load PMC TUI module: $_" -ForegroundColor Red
    exit 1
}

# Fallback for terminal dimensions if not exported by module
if (-not (Get-Command Get-PmcTerminalDimensions -ErrorAction SilentlyContinue)) {
    function Get-PmcTerminalDimensions {
        [pscustomobject]@{ Width = [Console]::WindowWidth; Height = [Console]::WindowHeight }
    }
}

# Load generator
. $repoRoot/tools/idea-gen.ps1

$steps = New-Object System.Collections.ArrayList
$sel = 0; $activePane = 0
$macroName = 'Macro1'

# Seed with a default step so the UI shows content immediately
[void]$steps.Add(@{ Type='CreateVirtualField'; Name='F1'; DataType='NUM'; Equation='AMOUNT*1.05'; Decimals=2 })

# Action Library (built-in actions)
$library = @(
    @{ Display='Add Calculated Field'; Type='CreateVirtualField' },
    @{ Display='Add Editable Field';   Type='AddEditableField'   },
    @{ Display='Extract Database';     Type='Extraction'         },
    @{ Display='Summarize';            Type='Summarize'          },
    @{ Display='Require Fields';       Type='AssertFieldsExist'  },
    @{ Display='Switch Active DB';     Type='SwitchActive'       }
)
$libSel = 0

function Render {
    Initialize-PmcScreen | Out-Null
    $dims = Get-PmcTerminalDimensions
    $W = $dims.Width; $H = $dims.Height
    Set-PmcHeader -Title 'IDEA Macro Builder' -Status 'Arrows: move • Enter: add/edit • Tab: switch • F5: save • F6: publish • Esc: quit' | Out-Null
    Clear-PmcContentArea 2

    $colW = [Math]::Max(20,[int]($W/3))
    $h = $H-6

    # Library Box (left)
    $libX=0; $libW=$colW
    Write-PmcAtPosition -X $libX -Y 2 -Text ('┌' + ('─' * ($libW-2)) + '┐')
    for($i=1;$i -lt $h-1;$i++){ Write-PmcAtPosition -X $libX -Y (2+$i) -Text ('│' + (' ' * ($libW-2)) + '│') }
    Write-PmcAtPosition -X $libX -Y (2+$h-1) -Text ('└' + ('─' * ($libW-2)) + '┘')
    Write-PmcAtPosition -X ($libX+2) -Y 2 -Text 'Action Library (Enter to add)'

    # Steps Box (middle)
    $stX=$colW; $stW=$colW
    Write-PmcAtPosition -X $stX -Y 2 -Text ('┌' + ('─' * ($stW-2)) + '┐')
    for($i=1;$i -lt $h-1;$i++){ Write-PmcAtPosition -X $stX -Y (2+$i) -Text ('│' + (' ' * ($stW-2)) + '│') }
    Write-PmcAtPosition -X $stX -Y (2+$h-1) -Text ('└' + ('─' * ($stW-2)) + '┘')
    Write-PmcAtPosition -X ($stX+2) -Y 2 -Text 'Selected Actions (↑/↓, D delete, E edit)'

    # Editor Box (right)
    $edX=($colW*2); $edW=($W-($colW*2))
    Write-PmcAtPosition -X $edX -Y 2 -Text ('┌' + ('─' * ($edW-2)) + '┐')
    for($i=1;$i -lt $h-1;$i++){ Write-PmcAtPosition -X $edX -Y (2+$i) -Text ('│' + (' ' * ($edW-2)) + '│') }
    Write-PmcAtPosition -X $edX -Y (2+$h-1) -Text ('└' + ('─' * ($edW-2)) + '┘')
    Write-PmcAtPosition -X ($edX+2) -Y 2 -Text 'Action Editor (Enter to edit/save)'

    # Library render (left)
    $maxLibRows = $h-2
    for($i=0;$i -lt [Math]::Min($library.Count,$maxLibRows);$i++){
        $item=$library[$i]
        $marker = if(($activePane -eq 0) -and ($i -eq $libSel)){ '>' } else { ' ' }
        $line = ("{0} {1}" -f $marker, $item.Display)
        $line = $line.Substring(0,[Math]::Min($line.Length,$libW-2))
        Write-PmcAtPosition -X ($libX+1) -Y (3+$i) -Text $line
    }

    # Steps render (middle)
    $maxRows = $h-2
    for($i=0;$i -lt [Math]::Min($steps.Count,$maxRows);$i++){
        $s=$steps[$i]
        $marker = if(($activePane -eq 1) -and ($i -eq $sel)){ '>' } else { ' ' }
        $desc = switch ($s.Type) {
            'CreateVirtualField' { "Add Calculated Field: $($s.Name) [$($s.DataType)]" }
            'AddEditableField'   { "Add Editable Field: $($s.Name) [$($s.DataType)]" }
            'Extraction'         { "Extract Database (Keys: $(@($s.Keys)-join ', '))" }
            'Summarize'          { "Summarize (Group: $(@($s.GroupBy)-join ', '))" }
            'AssertFieldsExist'  { "Require Fields: $(@($s.Fields)-join ', ')" }
            'SwitchActive'       { "Switch Active DB: $($s.Use)" }
            default              { $s.Type }
        }
        $line = ("{0} {1}" -f $marker, $desc)
        $line = $line.Substring(0,[Math]::Min($line.Length,$stW-2))
        Write-PmcAtPosition -X ($stX+1) -Y (3+$i) -Text $line
    }

    # Editor render (right)
    if($steps.Count -gt 0){
        $s=$steps[$sel]
        $rows=@()
        switch ($s.Type) {
            'CreateVirtualField' {
                $rows += "Step: Add Calculated Field (new field)"
                $rows += "Name: $($s.Name)"
                $rows += "DataType: $($s.DataType)"
                $rows += "Equation: $($s.Equation)"
                $rows += "Tip: Use IDEA @FUNCTIONS in Equation"
                if ($s.DataType -eq 'NUM') { $rows += "Decimals: $($s.Decimals)" }
                if ($s.DataType -eq 'CHAR') { $rows += "Length: $($s.Length)" }
                if ($s.DataType -eq 'DATE') { $rows += "Mask: $($s.Mask)" }
                $ia = $s['InputAlias'];  if ($ia)  { $rows += "InputAlias: $ia" }
                $oa = $s['OutputAlias']; if ($oa) { $rows += "OutputAlias: $oa" }
            }
            'Extraction' {
                $rows += "Step: Extract Database (indexed copy)"
                $rows += "Keys: $(@($s.Keys)-join ',')"
                $rows += "Suffix: $($s.OutputSuffix)"
                $ia = $s['InputAlias'];  if ($ia)  { $rows += "InputAlias: $ia" }
                $oa = $s['OutputAlias']; if ($oa) { $rows += "OutputAlias: $oa" }
            }
            'Summarize' {
                $rows += "Step: Summarize (new database)"
                $rows += "GroupBy: $(@($s.GroupBy)-join ',')"
                $rows += "Sum: $(@($s.Sum)-join ',')"
                $rows += "Suffix: $($s.OutputSuffix)"
                $ia = $s['InputAlias'];  if ($ia)  { $rows += "InputAlias: $ia" }
                $oa = $s['OutputAlias']; if ($oa) { $rows += "OutputAlias: $oa" }
            }
            'AddEditableField' {
                $rows += "Step: Add Editable Field (blank)"
                $rows += "Name: $($s.Name)"
                $rows += "DataType: $($s.DataType)"
                if ($s.DataType -eq 'NUM') { $rows += "Decimals: $($s.Decimals)" }
                if ($s.DataType -eq 'CHAR') { $rows += "Length: $($s.Length)" }
                if ($s.Default) { $rows += "Default: $($s.Default)" }
                $ia = $s['InputAlias'];  if ($ia)  { $rows += "InputAlias: $ia" }
                $oa = $s['OutputAlias']; if ($oa) { $rows += "OutputAlias: $oa" }
            }
            'AssertFieldsExist' {
                $rows += "Step: Require Fields"
                $rows += "Fields: $(@($s.Fields)-join ',')"
                $ia = $s['InputAlias'];  if ($ia)  { $rows += "InputAlias: $ia" }
                $oa = $s['OutputAlias']; if ($oa) { $rows += "OutputAlias: $oa" }
            }
            'SwitchActive' {
                $rows += "Step: Switch Active DB"
                $rows += "Use: $($s.Use)"
                $oa = $s['OutputAlias']; if ($oa) { $rows += "OutputAlias: $oa" }
            }
        }
        for($i=0;$i -lt [Math]::Min($rows.Count,$h-2);$i++){
            $line = ($rows[$i])
            if ($line.Length -gt ($edW-2)) { $line = $line.Substring(0,$edW-2) }
            Write-PmcAtPosition -X ($edX+1) -Y (3+$i) -Text $line
        }
    }

    # (no preview pane)
}

function Edit-SelectedStep {
    if ($steps.Count -eq 0) { return }
    $s = $steps[$sel]
    switch ($s.Type) {
        'CreateVirtualField' {
            Show-PmcCursor
            Set-PmcInputPrompt -Prompt 'Name: '
            $s.Name = Read-Host
            Set-PmcInputPrompt -Prompt 'DataType (NUM|CHAR|DATE): '
            $s.DataType = (Read-Host).ToUpper()
            Set-PmcInputPrompt -Prompt 'Equation: '
            $s.Equation = Read-Host
            switch ($s.DataType) {
                'NUM'  { Set-PmcInputPrompt -Prompt 'Decimals: '; $s.Decimals = [int](Read-Host) ; $s.Length=$null; $s.Mask=$null }
                'CHAR' { Set-PmcInputPrompt -Prompt 'Length: ';   $s.Length   = [int](Read-Host) ; $s.Decimals=$null; $s.Mask=$null }
                'DATE' { Set-PmcInputPrompt -Prompt 'Mask: ';     $s.Mask     = Read-Host        ; $s.Decimals=$null; $s.Length=$null }
                default { }
            }
            Set-PmcInputPrompt -Prompt 'InputAlias (optional): ';  $s['InputAlias'] = Read-Host
            Set-PmcInputPrompt -Prompt 'OutputAlias (optional): '; $s['OutputAlias'] = Read-Host
            Hide-PmcCursor
        }
        'Extraction' {
            Show-PmcCursor
            Set-PmcInputPrompt -Prompt 'Keys (comma-separated): '
            $keys = Read-Host
            $s.Keys = @($keys -split ',\s*' | ?{$_})
            Set-PmcInputPrompt -Prompt 'Output suffix: '
            $s.OutputSuffix = Read-Host
            Set-PmcInputPrompt -Prompt 'InputAlias (optional): ';  $s['InputAlias'] = Read-Host
            Set-PmcInputPrompt -Prompt 'OutputAlias (optional): '; $s['OutputAlias'] = Read-Host
            Hide-PmcCursor
        }
        'Summarize' {
            Show-PmcCursor
            Set-PmcInputPrompt -Prompt 'GroupBy (comma-separated): '
            $g = Read-Host
            $s.GroupBy = @($g -split ',\s*' | ?{$_})
            Set-PmcInputPrompt -Prompt 'Sum fields (comma-separated): '
            $sum = Read-Host
            $s.Sum = @($sum -split ',\s*' | ?{$_})
            Set-PmcInputPrompt -Prompt 'Output suffix: '
            $s.OutputSuffix = Read-Host
            Set-PmcInputPrompt -Prompt 'InputAlias (optional): ';  $s['InputAlias'] = Read-Host
            Set-PmcInputPrompt -Prompt 'OutputAlias (optional): '; $s['OutputAlias'] = Read-Host
            Hide-PmcCursor
        }
        'AddEditableField' {
            Show-PmcCursor
            Set-PmcInputPrompt -Prompt 'Name: '; $s.Name = Read-Host
            Set-PmcInputPrompt -Prompt 'DataType (NUM|CHAR|DATE): '; $s.DataType = (Read-Host).ToUpper()
            switch ($s.DataType) {
                'NUM'  { Set-PmcInputPrompt -Prompt 'Decimals: '; $s.Decimals = [int](Read-Host) ; $s.Length=$null }
                'CHAR' { Set-PmcInputPrompt -Prompt 'Length: ';   $s.Length   = [int](Read-Host) ; $s.Decimals=$null }
            }
            Set-PmcInputPrompt -Prompt 'Default value/equation (optional): '; $s.Default = Read-Host
            Set-PmcInputPrompt -Prompt 'InputAlias (optional): ';  $s['InputAlias'] = Read-Host
            Set-PmcInputPrompt -Prompt 'OutputAlias (optional): '; $s['OutputAlias'] = Read-Host
            Hide-PmcCursor
        }
        'AssertFieldsExist' {
            Show-PmcCursor
            Set-PmcInputPrompt -Prompt 'Fields (comma-separated): '
            $f = Read-Host
            $s.Fields = @($f -split ',\s*' | ?{$_})
            Set-PmcInputPrompt -Prompt 'InputAlias (optional): ';  $s['InputAlias'] = Read-Host
            Set-PmcInputPrompt -Prompt 'OutputAlias (optional): '; $s['OutputAlias'] = Read-Host
            Hide-PmcCursor
        }
        'SwitchActive' {
            Show-PmcCursor
            Set-PmcInputPrompt -Prompt 'Use alias: '; $s.Use = Read-Host
            Set-PmcInputPrompt -Prompt 'OutputAlias (optional): '; $s['OutputAlias'] = Read-Host
            Hide-PmcCursor
        }
    }
}

function Add-Step {
    Show-PmcCursor
    Set-PmcInputPrompt -Prompt 'Add Step (1=Add Calculated Field, 2=Extract Database, 3=Summarize, 4=Add Editable Field, 5=Require Fields, 6=Switch Active DB): '
    $c = Read-Host
    switch ($c) {
        '1' {
            Set-PmcInputPrompt -Prompt 'Name: '
            $name = Read-Host
            Set-PmcInputPrompt -Prompt 'DataType (NUM|CHAR|DATE): '
            $dt = (Read-Host).ToUpper()
            Set-PmcInputPrompt -Prompt 'Equation: '
            $eq = Read-Host
            $step = @{ Type='CreateVirtualField'; Name=$name; DataType=$dt; Equation=$eq }
            switch($dt){
                'NUM'  { Set-PmcInputPrompt -Prompt 'Decimals: '; $step.Decimals = [int](Read-Host) }
                'CHAR' { Set-PmcInputPrompt -Prompt 'Length: ';   $step.Length   = [int](Read-Host) }
                'DATE' { Set-PmcInputPrompt -Prompt 'Mask: ';     $step.Mask     = Read-Host }
            }
            [void]$steps.Add($step)
        }
        '2' {
            Set-PmcInputPrompt -Prompt 'Keys (comma-separated): '
            $keys = Read-Host
            Set-PmcInputPrompt -Prompt 'Output suffix: '
            $sfx = Read-Host
            [void]$steps.Add(@{ Type='Extraction'; Keys=@($keys -split ',\s*' | ?{$_}); OutputSuffix=$sfx })
        }
        '3' {
            Set-PmcInputPrompt -Prompt 'GroupBy (comma-separated): '
            $gb = Read-Host
            Set-PmcInputPrompt -Prompt 'Sum fields (comma-separated): '
            $sm = Read-Host
            Set-PmcInputPrompt -Prompt 'Output suffix: '
            $sfx = Read-Host
            [void]$steps.Add(@{ Type='Summarize'; GroupBy=@($gb -split ',\s*' | ?{$_}); Sum=@($sm -split ',\s*' | ?{$_}); OutputSuffix=$sfx })
        }
        '4' {
            # AddEditableField
            Set-PmcInputPrompt -Prompt 'Name: '; $name = Read-Host
            Set-PmcInputPrompt -Prompt 'DataType (NUM|CHAR|DATE): '; $dt = (Read-Host).ToUpper()
            $step = @{ Type='AddEditableField'; Name=$name; DataType=$dt }
            switch($dt){
                'NUM'  { Set-PmcInputPrompt -Prompt 'Decimals: '; $step.Decimals = [int](Read-Host) }
                'CHAR' { Set-PmcInputPrompt -Prompt 'Length: ';   $step.Length   = [int](Read-Host) }
            }
            Set-PmcInputPrompt -Prompt 'Default value/equation (optional): '; $step.Default = Read-Host
            [void]$steps.Add($step)
        }
        '5' {
            # AssertFieldsExist
            Set-PmcInputPrompt -Prompt 'Fields (comma-separated): '
            $f = Read-Host
            [void]$steps.Add(@{ Type='AssertFieldsExist'; Fields=@($f -split ',\s*' | ?{$_}) })
        }
        '6' {
            Set-PmcInputPrompt -Prompt 'Use alias: '
            $ua = Read-Host
            [void]$steps.Add(@{ Type='SwitchActive'; Use=$ua })
        }
    }
    $global:sel = [Math]::Max(0,$steps.Count-1)
    Hide-PmcCursor
}

function Save-Macro {
    $dir = './out'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $spec = @{ Name=$macroName; Language='EN'; Steps=@($steps) }
    $dest = Join-Path $dir ("$macroName.iss")
    try {
        New-IdeaMacroFromSpec -Spec $spec -Destination $dest | Out-Null
        Set-PmcHeader -Title 'IDEA Macro Builder' -Status ("Saved: $dest") | Out-Null
        return $dest
    }
    catch { return $null }
}

function Publish-Macro {
    $spec = @{ Name=$macroName; Language='EN'; Steps=@($steps) }
    try {
        New-IdeaMacroFromSpec -Spec $spec | Out-Null
        Set-PmcHeader -Title 'IDEA Macro Builder' -Status 'Published to Local Library' | Out-Null
        return $true
    } catch { return $false }
}

[Console]::CursorVisible = $false
try {
    Render
    while ($true) {
        $k = [Console]::ReadKey($true)
        switch ($k.Key) {
            'Tab'       { $activePane = ($activePane+1)%3; Render }
            'LeftArrow' { $activePane = [Math]::Max(0,$activePane-1); Render }
            'RightArrow'{ $activePane = [Math]::Min(2,$activePane+1); Render }
            'Escape'    { break }
            'F5'        { $p=Save-Macro; Render }
            'F6'        { $ok=Publish-Macro; Render }
            'A'         { if($activePane -eq 1){ Add-Step; Render } }
            'D'         { if($activePane -eq 1 -and $steps.Count -gt 0){ $steps.RemoveAt($sel); $sel=[Math]::Max(0,$sel-1); Render } }
            'E'         { if($activePane -eq 1 -and $steps.Count -gt 0){ Edit-SelectedStep; Render } }
            'UpArrow'   { if($activePane -eq 0){ $libSel=[Math]::Max(0,$libSel-1); Render } elseif($activePane -eq 1){ $sel=[Math]::Max(0,$sel-1); Render } }
            'DownArrow' { if($activePane -eq 0){ $libSel=[Math]::Min([Math]::Max(0,$library.Count-1),$libSel+1); Render } elseif($activePane -eq 1){ $sel=[Math]::Min([Math]::Max(0,$steps.Count-1),$sel+1); Render } }
            'Enter'     {
                if ($activePane -eq 0) {
                    $item = $library[$libSel]
                    switch ($item.Type) {
                        'CreateVirtualField' { [void]$steps.Add(@{ Type='CreateVirtualField'; Name='NewField'; DataType='NUM'; Equation='0'; Decimals=0 }) }
                        'AddEditableField'   { [void]$steps.Add(@{ Type='AddEditableField'; Name='NewField'; DataType='NUM'; Decimals=0; Default='0' }) }
                        'Extraction'         { [void]$steps.Add(@{ Type='Extraction'; Keys=@(); OutputSuffix='Indexed' }) }
                        'Summarize'          { [void]$steps.Add(@{ Type='Summarize'; GroupBy=@(); Sum=@(); OutputSuffix='Summary' }) }
                        'AssertFieldsExist'  { [void]$steps.Add(@{ Type='AssertFieldsExist'; Fields=@() }) }
                        'SwitchActive'       { [void]$steps.Add(@{ Type='SwitchActive'; Use='' }) }
                    }
                    $sel=[Math]::Max(0,$steps.Count-1); $activePane=2; Edit-SelectedStep; Render
                } elseif ($activePane -eq 1 -and $steps.Count -gt 0) {
                    Edit-SelectedStep; Render
                } elseif ($activePane -eq 2 -and $steps.Count -gt 0) {
                    Edit-SelectedStep; Render
                }
            }
            default { }
        }
    }
} finally {
    [Console]::CursorVisible = $true
}
