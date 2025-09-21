# IDEA Macro/Function Generator (scaffold)
# Generates CaseWare IDEA 12 custom functions (.ideafunc) and macros (.iss)
# Usage examples are in docs/IDEA_GENERATOR.md

param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-IdeaLocalLibraryPath {
    <#
      Attempts to locate the IDEA Local Library folder.
      Returns a hashtable with Keys: Path, FunctionsPath, MacrosPath.
      Note: Detection uses best-effort; adjust as needed on your workstation.
    #>
    $paths = @()

    # Common EN/FR public locations
    $paths += 'C:\Users\Public\Documents\My IDEA Documents\Local Library'
    $paths += 'C:\Users\Public\Documents\Mes documents IDEA\Bibliothèque locale'

    # Current user Documents EN/FR
    $docs = [Environment]::GetFolderPath('MyDocuments')
    if ($docs) {
        $paths += (Join-Path $docs 'My IDEA Documents\Local Library')
        $paths += (Join-Path $docs 'Mes documents IDEA\Bibliothèque locale')
    }

    foreach ($p in $paths) {
        if (Test-Path -LiteralPath $p) {
            $func = Join-Path $p 'Custom Functions'
            $mac = Join-Path $p 'Macros.ILB'
            return @{ Path = $p; FunctionsPath = $func; MacrosPath = $mac }
        }
    }

    # As a last resort, return the first user EN path (may not exist yet)
    $fallback = (Join-Path $docs 'My IDEA Documents\Local Library')
    return @{ Path = $fallback; FunctionsPath = (Join-Path $fallback 'Custom Functions'); MacrosPath = (Join-Path $fallback 'Macros.ILB') }
}

function New-IdeaDirectoriesIfMissing {
    param(
        [Parameter(Mandatory)] [hashtable] $Lib
    )
    foreach ($key in 'Path','FunctionsPath','MacrosPath') {
        $target = $Lib[$key]
        if (-not (Test-Path -LiteralPath $target)) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        }
    }
}

function Write-FileUtf16Le {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Content
    )
    $enc = [System.Text.Encoding]::Unicode # UTF-16 LE with BOM
    [IO.File]::WriteAllText($Path, $Content, $enc)
}

function New-IdeaCustomFunction {
    <#
      .SYNOPSIS
      Writes a .ideafunc XML file for IDEA Custom Function (VBScript).

      .PARAMETER Name
      Function name.

      .PARAMETER OutputType
      One of: Character|Numeric|Date

      .PARAMETER Parameters
      Array of hashtables: @{ Type='Character'|'Numeric'|'Date'; Name='...'; Help='...' }

      .PARAMETER Body
      VBScript function and helpers inside FunctionBody (without XML escaping).

      .PARAMETER Author
      Author name to embed.

      .PARAMETER Category
      Category string (defaults to Uncategorized).

      .PARAMETER Destination
      Optional explicit output path. Defaults to IDEA Local Library Custom Functions.
    #>
    param(
        [Parameter(Mandatory)] [string] $Name,
        [ValidateSet('Character','Numeric','Date')] [string] $OutputType = 'Character',
        [Parameter(Mandatory)] [hashtable[]] $Parameters,
        [Parameter(Mandatory)] [string] $Body,
        [string] $Author = $env:USERNAME,
        [string] $Category = 'Uncategorized',
        [string] $Destination
    )

    $date = (Get-Date).ToString('yyyy-MM-dd')

    # Escape XML special chars in FunctionBody
    $escapedBody = $Body -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'

    $xml = @"
<?xml version="1.0" encoding="utf-16"?>
<Function xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.caseware-idea.com/">
  <Author>$Author</Author>
  <DateModified>$date</DateModified>
  <FunctionName>$Name</FunctionName>
  <Help />
  <OutputType>$OutputType</OutputType>
  <ScriptType>VbScript</ScriptType>
  <Category>$Category</Category>
  <FunctionBody>$escapedBody</FunctionBody>
  <Parameters>
"@

    foreach ($p in $Parameters) {
        $ptype = $p.Type
        $pname = $p.Name
        $phelp = $p.Help
        $xml += @"
    <Parameter>
      <Type>$ptype</Type>
      <Name>$pname</Name>
      <Help>$phelp</Help>
    </Parameter>
"@
    }

    $xml += @"
  </Parameters>
</Function>
"@

    if (-not $Destination) {
        $lib = Get-IdeaLocalLibraryPath
        New-IdeaDirectoriesIfMissing $lib
        $Destination = Join-Path $lib.FunctionsPath ("$Name.ideafunc")
    }

    Write-FileUtf16Le -Path $Destination -Content $xml
    return $Destination
}

function New-IdeaRegexFunctionRegfExample {
    <#
      Creates the regf.ideafunc example (regex function) based on provided VBScript.
    #>
    $vb = @'
Option Explicit

Function regf(input_string As String,regex_pattern As String,capture_group As Double) As String
    On Error GoTo ErrorHandler

    Dim RE As Object, allMatches As Object
    Dim results() As String
    Dim count As Integer, i As Integer

    If Len(input_string) = 0 Then regf = "": Exit Function
    If Len(regex_pattern) = 0 Then regf = "": Exit Function
    If capture_group < 0 Then capture_group = 0

    Set RE = CreateObject("vbscript.regexp")
    RE.Pattern = regex_pattern
    RE.Global = True
    RE.IgnoreCase = False
    RE.MultiLine = False

    Set allMatches = RE.Execute(input_string)
    count = allMatches.Count
    If count = 0 Then regf = "": Exit Function

    ReDim results(count - 1)
    For i = 0 To count - 1
        If capture_group = 0 Then
            results(i) = allMatches(i).Value
        ElseIf allMatches(i).SubMatches.Count >= capture_group Then
            results(i) = allMatches(i).SubMatches(capture_group - 1)
        Else
            results(i) = ""
        End If
    Next

    regf = JoinArray(results, "|")
    Exit Function

ErrorHandler:
    regf = ""
    On Error Resume Next
    Set allMatches = Nothing
    Set RE = Nothing
End Function

Private Function JoinArray(arr() As String, sep As String) As String
    Dim i As Integer, result As String
    result = ""
    For i = LBound(arr) To UBound(arr)
        If Len(arr(i)) > 0 Then
            If Len(result) = 0 Then
                result = arr(i)
            Else
                result = result & sep & arr(i)
            End If
        End If
    Next
    JoinArray = result
End Function
'@

    $params = @(
        @{ Type='Character'; Name='input_string';   Help='field/text' },
        @{ Type='Character'; Name='regex_pattern';  Help='regex pattern' },
        @{ Type='Numeric';   Name='capture_group';  Help='capture group num' }
    )

    $out = New-IdeaCustomFunction -Name 'regf' -OutputType 'Character' -Parameters $params -Body $vb -Category 'Text'
    Write-Host "Created: $out"
    return $out
}

function New-IdeaMacroFromSpec {
    <#
      .SYNOPSIS
      Generate an IDEAScript (.iss) macro from a declarative spec.

      .DESCRIPTION
      Spec model (PowerShell hashtable):
        @{ Name = 'My Macro'; Language = 'EN'|'FR'|'BOTH'; Steps = @(
             @{ Type='CreateVirtualField'; Name='F1'; DataType='NUM'; Decimals=2; Equation='AMOUNT*1.05' },
             @{ Type='Extraction'; Keys=@('BATCH','ENTRY'); OutputSuffix='Indexed' },
             @{ Type='Summarize'; GroupBy=@('BATCH'); Sum=@('F1'); OutputSuffix='ByBatch' }
           ) }

      The generator injects the steps into a base .iss template and ensures prior names can be referenced later.
    #>
    param(
        [Parameter(Mandatory)] [hashtable] $Spec,
        [string] $Destination
    )

    $name = $Spec.Name
    if (-not $name) { throw 'Spec.Name is required' }

    $lang = $Spec.Language
    if (-not $lang) { $lang = 'EN' }

    $steps = @($Spec.Steps)
    $stepsBody = New-Object System.Text.StringBuilder
    $aliasDecl = New-Object System.Text.StringBuilder

    # Collect alias names referenced by steps
    $aliasNames = @()
    foreach ($s in $steps) {
        $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
        $ia = if ($s -and $s.ContainsKey('InputAlias'))  { $s['InputAlias']  } else { $null }
        $us = if ($s -and $s.ContainsKey('Use'))         { $s['Use']         } else { $null }
        if ($oa) { $aliasNames += $oa }
        if ($ia) { $aliasNames += $ia }
        if ($us) { $aliasNames += $us }
    }
    $aliasNames = $aliasNames | Sort-Object -Unique | Where-Object { $_ -and $_.Trim().Length -gt 0 }

    # Emit alias variable declarations
    foreach ($a in $aliasNames) {
        [void]$aliasDecl.AppendLine("    Dim fn_$a As String")
        [void]$aliasDecl.AppendLine("    Dim db_$a As Object")
    }

    # Helpers to inject alias handling
    function Add-InputAliasBlock {
        param([hashtable]$Step)
        $ia = if ($Step -and $Step.ContainsKey('InputAlias')) { $Step['InputAlias'] } else { $null }
        if ($ia) {
            [void]$stepsBody.AppendLine("$indent If (db_$ia Is Nothing) Then")
            [void]$stepsBody.AppendLine(("{0}     MsgBox ""Alias '{1}' is not set."": Exit Sub" -f $indent, $ia))
            [void]$stepsBody.AppendLine("$indent End If")
            [void]$stepsBody.AppendLine("$indent Set db = db_$ia")
            [void]$stepsBody.AppendLine("$indent filename = fn_$ia")
        }
    }

    function Add-OutputAliasBlock {
        param([string]$Alias,[bool]$ProducesDb)
        if ([string]::IsNullOrWhiteSpace($Alias)) { return }
        if ($ProducesDb) {
            [void]$stepsBody.AppendLine("$indent fn_$Alias = newDBName")
            [void]$stepsBody.AppendLine("$indent Set db_$Alias = db")
        } else {
            [void]$stepsBody.AppendLine("$indent fn_$Alias = filename")
            [void]$stepsBody.AppendLine("$indent Set db_$Alias = db")
        }
    }

    # Emit IDEAScript tasks for each step
    $indent = '               '
    foreach ($s in $steps) {
        switch ($s.Type) {
            'CreateVirtualField' {
                Add-InputAliasBlock $s
                $fname = $s.Name
                $dtype = $s.DataType
                $eq    = $s.Equation
                $dec   = if ($s.Decimals -ne $null) { [int]$s.Decimals } else { $null }
                $len   = if ($s.Length  -ne $null) { [int]$s.Length  } else { $null }
                $mask  = $s.Mask

                switch ($dtype) {
                    'NUM'  { if ($dec  -eq $null) { throw "CreateVirtualField(NUM) requires Decimals" } }
                    'CHAR' { if ($len  -eq $null) { throw "CreateVirtualField(CHAR) requires Length" } }
                    'DATE' { if ([string]::IsNullOrWhiteSpace($mask)) { throw "CreateVirtualField(DATE) requires Mask" } }
                    default { throw "Unsupported DataType: $dtype (use NUM|CHAR|DATE)" }
                }
                [void]$stepsBody.AppendLine("$indent Set task = db.TableManagement")
                [void]$stepsBody.AppendLine("$indent Set newtabledef = db.TableDef")
                [void]$stepsBody.AppendLine("$indent Set fld = newtabledef.NewField")
                [void]$stepsBody.AppendLine(("{0} fld.Equation = ""{1}""" -f $indent, $eq))
                [void]$stepsBody.AppendLine(("{0} fld.Name = ""{1}""" -f $indent, $fname))
                [void]$stepsBody.AppendLine("$indent fld.Type = WI_EDIT_$(if($dtype -eq 'NUM'){'NUM'}elseif($dtype -eq 'CHAR'){'CHAR'}else{'DATE'})")
                if ($dtype -eq 'NUM')  { [void]$stepsBody.AppendLine(("{0} fld.Decimals = {1}" -f $indent, $dec)) }
                if ($dtype -eq 'CHAR') { [void]$stepsBody.AppendLine(("{0} fld.Length = {1}" -f $indent, $len)) }
                if ($dtype -eq 'DATE') { [void]$stepsBody.AppendLine(("{0} fld.Picture = ""{1}""" -f $indent, $mask)) }
                [void]$stepsBody.AppendLine("$indent task.AppendField fld")
                [void]$stepsBody.AppendLine("$indent task.PerformTask")
                [void]$stepsBody.AppendLine("$indent Set task = Nothing: Set fld = Nothing")
                $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
                Add-OutputAliasBlock -Alias $oa -ProducesDb:$false
            }
            'AddEditableField' {
                Add-InputAliasBlock $s
                $fname = $s.Name
                $dtype = $s.DataType
                $def   = if ($s.Default -ne $null) { [string]$s.Default } else { '' }
                $dec   = if ($s.Decimals -ne $null) { [int]$s.Decimals } else { $null }
                $len   = if ($s.Length  -ne $null) { [int]$s.Length  } else { $null }
                switch ($dtype) {
                    'NUM'  { if ($dec  -eq $null) { throw "AddEditableField(NUM) requires Decimals" } }
                    'CHAR' { if ($len  -eq $null) { throw "AddEditableField(CHAR) requires Length" } }
                    'DATE' { }
                    default { throw "Unsupported DataType: $dtype (use NUM|CHAR|DATE)" }
                }
                [void]$stepsBody.AppendLine("$indent Set task = db.TableManagement")
                [void]$stepsBody.AppendLine("$indent Set newtabledef = db.TableDef")
                [void]$stepsBody.AppendLine("$indent Set fld = newtabledef.NewField")
                if ($def -ne '') { [void]$stepsBody.AppendLine(("{0} fld.Equation = ""{1}""" -f $indent, $def)) } else { [void]$stepsBody.AppendLine("$indent fld.Equation = """) }
                [void]$stepsBody.AppendLine(("{0} fld.Name = ""{1}""" -f $indent, $fname))
                [void]$stepsBody.AppendLine("$indent fld.Type = WI_EDIT_$(if($dtype -eq 'NUM'){'NUM'}elseif($dtype -eq 'CHAR'){'CHAR'}else{'DATE'})")
                if ($dtype -eq 'NUM')  { [void]$stepsBody.AppendLine(("{0} fld.Decimals = {1}" -f $indent, $dec)) }
                if ($dtype -eq 'CHAR') { [void]$stepsBody.AppendLine(("{0} fld.Length = {1}" -f $indent, $len)) }
                [void]$stepsBody.AppendLine("$indent task.AppendField fld")
                [void]$stepsBody.AppendLine("$indent task.PerformTask")
                [void]$stepsBody.AppendLine("$indent Set task = Nothing: Set fld = Nothing")
                $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
                Add-OutputAliasBlock -Alias $oa -ProducesDb:$false
            }
            'Extraction' {
                Add-InputAliasBlock $s
                $keys = @($s.Keys)
                $suffix = $s.OutputSuffix
                [void]$stepsBody.AppendLine("$indent Set task = db.Extraction")
                [void]$stepsBody.AppendLine("$indent task.IncludeAllFields")
                foreach ($k in $keys) { [void]$stepsBody.AppendLine(("{0} task.AddKey ""{1}"", ""A""" -f $indent, $k)) }
                [void]$stepsBody.AppendLine(("{0} newDBName = Client.UniqueFileName(ireplace(filename, "".IMD"", "" {1}.IMD""))" -f $indent, $suffix))
                [void]$stepsBody.AppendLine(('{0} task.AddExtraction newDBName, "", ""' -f $indent))
                [void]$stepsBody.AppendLine("$indent task.PerformTask 1, db.Count: Set task = Nothing")
                [void]$stepsBody.AppendLine("$indent Set db = Client.OpenDatabase(newDBName)")
                [void]$stepsBody.AppendLine("$indent filename = newDBName")
                $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
                Add-OutputAliasBlock -Alias $oa -ProducesDb:$true
            }
            'Summarize' {
                Add-InputAliasBlock $s
                $groupBy = @($s.GroupBy)
                $sum     = @($s.Sum)
                $suffix  = $s.OutputSuffix
                [void]$stepsBody.AppendLine("$indent Set task = db.Summarization")
                foreach ($g in $groupBy) { [void]$stepsBody.AppendLine(("{0} task.AddFieldToSummarize ""{1}""" -f $indent, $g)) }
                foreach ($f in $sum)     { [void]$stepsBody.AppendLine(("{0} task.AddFieldToTotal ""{1}""" -f $indent, $f)) }
                [void]$stepsBody.AppendLine(("{0} newDBName = Client.UniqueFileName(ireplace(filename, "".IMD"", "" {1}.IMD""))" -f $indent, $suffix))
                [void]$stepsBody.AppendLine("$indent task.OutputDBName = newDBName")
                [void]$stepsBody.AppendLine("$indent task.CreatePercentField = FALSE")
                [void]$stepsBody.AppendLine("$indent task.StatisticsToInclude = SM_COUNT + SM_SUM")
                [void]$stepsBody.AppendLine("$indent task.PerformTask: Set task = Nothing")
                [void]$stepsBody.AppendLine("$indent Set db = Client.OpenDatabase(newDBName)")
                [void]$stepsBody.AppendLine("$indent filename = newDBName")
                $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
                Add-OutputAliasBlock -Alias $oa -ProducesDb:$true
            }
            'AssertFieldsExist' {
                Add-InputAliasBlock $s
                $fields = @($s.Fields)
                if ($fields.Count -eq 0) { throw 'AssertFieldsExist requires Fields' }
                $arr = ($fields -join "|")
                [void]$stepsBody.AppendLine("$indent Dim tdef As Object, fld As Object, i As Integer, nm As String, ok As Integer")
                [void]$stepsBody.AppendLine("$indent Set tdef = db.TableDef")
                [void]$stepsBody.AppendLine(("{0} For Each nm In Split(""{1}"", ""|"")" -f $indent, $arr))
                [void]$stepsBody.AppendLine("$indent     ok = 0")
                [void]$stepsBody.AppendLine("$indent     For i = 1 To tdef.Count")
                [void]$stepsBody.AppendLine("$indent         Set fld = tdef.GetFieldAt(i)")
                [void]$stepsBody.AppendLine("$indent         If UCase(fld.Name) = UCase(nm) Then ok = 1: Exit For")
                [void]$stepsBody.AppendLine("$indent     Next")
                [void]$stepsBody.AppendLine("$indent     If ok = 0 Then MsgBox ""Missing field: "" & nm: Exit Sub")
                [void]$stepsBody.AppendLine("$indent Next")
                [void]$stepsBody.AppendLine("$indent Set fld = Nothing: Set tdef = Nothing")
                $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
                Add-OutputAliasBlock -Alias $oa -ProducesDb:$false
            }
            'SwitchActive' {
                $use = if ($s -and $s.ContainsKey('Use')) { $s['Use'] } else { $null }
                if (-not $use) { throw 'SwitchActive requires Use=<alias>' }
                [void]$stepsBody.AppendLine("$indent If (db_$use Is Nothing) Then")
                [void]$stepsBody.AppendLine(("{0}     MsgBox ""Alias '{1}' is not set."": Exit Sub" -f $indent, $use))
                [void]$stepsBody.AppendLine("$indent End If")
                [void]$stepsBody.AppendLine("$indent Set db = db_$use")
                [void]$stepsBody.AppendLine("$indent filename = fn_$use")
                $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
                Add-OutputAliasBlock -Alias $oa -ProducesDb:$false
            }
            default { throw "Unsupported step type: $($s.Type)" }
        }
    }

    $stepsText = $stepsBody.ToString()

    $iss = @"
Option Explicit

Sub Main
    Dim pm As Object, coll As Object, filename As String
    Dim db As Object, task As Object, newtabledef As Object, fld As Object
    Dim newDBName As String

    Set pm = Client.ProjectManagement
    Set coll = pm.Databases

    On Error Resume Next
    filename = Client.CurrentDatabase.Name
    If Err.Number <> 0 Then
        MsgBox "No active database. Open a database and rerun.": Exit Sub
    End If
    On Error GoTo 0

    Set db = Client.OpenDatabase(filename)

${aliasDecl.ToString()}$stepsText

    Client.RefreshFileExplorer
    Set db = Nothing: Set task = Nothing: Set pm = Nothing: Set coll = Nothing
End Sub
"@

    if (-not $Destination) {
        $lib = Get-IdeaLocalLibraryPath
        New-IdeaDirectoriesIfMissing $lib
        $Destination = Join-Path $lib.MacrosPath ("$name.iss")
    }

    Write-FileUtf16Le -Path $Destination -Content $iss
    Write-Host "Created macro: $Destination"
    return $Destination
}

function Get-IdeaMacroFromSpecContent {
    <#
      Returns the .iss macro content as a string (no file writes).
    #>
    param(
        [Parameter(Mandatory)] [hashtable] $Spec
    )

    $name = $Spec.Name
    if (-not $name) { throw 'Spec.Name is required' }
    $steps = @($Spec.Steps)
    $stepsBody = New-Object System.Text.StringBuilder
    $aliasDecl = New-Object System.Text.StringBuilder
    $indent = '               '

    # Collect alias names referenced by steps
    $aliasNames = @()
    foreach ($s in $steps) {
        $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
        $ia = if ($s -and $s.ContainsKey('InputAlias'))  { $s['InputAlias']  } else { $null }
        $us = if ($s -and $s.ContainsKey('Use'))         { $s['Use']         } else { $null }
        if ($oa) { $aliasNames += $oa }
        if ($ia) { $aliasNames += $ia }
        if ($us) { $aliasNames += $us }
    }
    $aliasNames = $aliasNames | Sort-Object -Unique | Where-Object { $_ -and $_.Trim().Length -gt 0 }
    foreach ($a in $aliasNames) {
        [void]$aliasDecl.AppendLine("    Dim fn_$a As String")
        [void]$aliasDecl.AppendLine("    Dim db_$a As Object")
    }

    function Add-InputAliasBlock2 { param([hashtable]$Step)
        $ia = if ($Step -and $Step.ContainsKey('InputAlias')) { $Step['InputAlias'] } else { $null }
        if ($ia) {
            [void]$stepsBody.AppendLine("$indent If (db_$ia Is Nothing) Then")
            [void]$stepsBody.AppendLine(("{0}     MsgBox ""Alias '{1}' is not set."": Exit Sub" -f $indent, $ia))
            [void]$stepsBody.AppendLine("$indent End If")
            [void]$stepsBody.AppendLine("$indent Set db = db_$ia")
            [void]$stepsBody.AppendLine("$indent filename = fn_$ia")
        }
    }
    function Add-OutputAliasBlock2 { param([string]$Alias,[bool]$ProducesDb)
        if ([string]::IsNullOrWhiteSpace($Alias)) { return }
        if ($ProducesDb) {
            [void]$stepsBody.AppendLine("$indent fn_$Alias = newDBName")
            [void]$stepsBody.AppendLine("$indent Set db_$Alias = db")
        } else {
            [void]$stepsBody.AppendLine("$indent fn_$Alias = filename")
            [void]$stepsBody.AppendLine("$indent Set db_$Alias = db")
        }
    }

    foreach ($s in $steps) {
        switch ($s.Type) {
            'CreateVirtualField' {
                Add-InputAliasBlock2 $s
                $fname = $s.Name; $dtype=$s.DataType; $eq=$s.Equation
                $dec = if ($s.Decimals -ne $null) { [int]$s.Decimals } else { $null }
                $len = if ($s.Length  -ne $null) { [int]$s.Length  } else { $null }
                $mask= $s.Mask
                switch ($dtype) {
                    'NUM'  { if ($dec  -eq $null) { throw "CreateVirtualField(NUM) requires Decimals" } }
                    'CHAR' { if ($len  -eq $null) { throw "CreateVirtualField(CHAR) requires Length" } }
                    'DATE' { if ([string]::IsNullOrWhiteSpace($mask)) { throw "CreateVirtualField(DATE) requires Mask" } }
                    default { throw "Unsupported DataType: $dtype (use NUM|CHAR|DATE)" }
                }
                [void]$stepsBody.AppendLine("$indent Set task = db.TableManagement")
                [void]$stepsBody.AppendLine("$indent Set newtabledef = db.TableDef")
                [void]$stepsBody.AppendLine("$indent Set fld = newtabledef.NewField")
                [void]$stepsBody.AppendLine(("{0} fld.Equation = ""{1}""" -f $indent, $eq))
                [void]$stepsBody.AppendLine(("{0} fld.Name = ""{1}""" -f $indent, $fname))
                [void]$stepsBody.AppendLine("$indent fld.Type = WI_EDIT_$(if($dtype -eq 'NUM'){'NUM'}elseif($dtype -eq 'CHAR'){'CHAR'}else{'DATE'})")
                if ($dtype -eq 'NUM')  { [void]$stepsBody.AppendLine(("{0} fld.Decimals = {1}" -f $indent, $dec)) }
                if ($dtype -eq 'CHAR') { [void]$stepsBody.AppendLine(("{0} fld.Length = {1}" -f $indent, $len)) }
                if ($dtype -eq 'DATE') { [void]$stepsBody.AppendLine(("{0} fld.Picture = ""{1}""" -f $indent, $mask)) }
                [void]$stepsBody.AppendLine("$indent task.AppendField fld")
                [void]$stepsBody.AppendLine("$indent task.PerformTask")
                [void]$stepsBody.AppendLine("$indent Set task = Nothing: Set fld = Nothing")
                $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
                Add-OutputAliasBlock2 -Alias $oa -ProducesDb:$false
            }
            'AddEditableField' {
                Add-InputAliasBlock2 $s
                $fname = $s.Name; $dtype=$s.DataType; $def = if ($s.Default){[string]$s.Default}else{''}
                $dec = if ($s.Decimals -ne $null) { [int]$s.Decimals } else { $null }
                $len = if ($s.Length  -ne $null) { [int]$s.Length  } else { $null }
                switch ($dtype) {
                    'NUM'  { if ($dec  -eq $null) { throw "AddEditableField(NUM) requires Decimals" } }
                    'CHAR' { if ($len  -eq $null) { throw "AddEditableField(CHAR) requires Length" } }
                    'DATE' { }
                    default { throw "Unsupported DataType: $dtype (use NUM|CHAR|DATE)" }
                }
                [void]$stepsBody.AppendLine("$indent Set task = db.TableManagement")
                [void]$stepsBody.AppendLine("$indent Set newtabledef = db.TableDef")
                [void]$stepsBody.AppendLine("$indent Set fld = newtabledef.NewField")
                if ($def -ne '') { [void]$stepsBody.AppendLine(("{0} fld.Equation = ""{1}""" -f $indent, $def)) } else { [void]$stepsBody.AppendLine("$indent fld.Equation = """) }
                [void]$stepsBody.AppendLine(("{0} fld.Name = ""{1}""" -f $indent, $fname))
                [void]$stepsBody.AppendLine("$indent fld.Type = WI_EDIT_$(if($dtype -eq 'NUM'){'NUM'}elseif($dtype -eq 'CHAR'){'CHAR'}else{'DATE'})")
                if ($dtype -eq 'NUM')  { [void]$stepsBody.AppendLine(("{0} fld.Decimals = {1}" -f $indent, $dec)) }
                if ($dtype -eq 'CHAR') { [void]$stepsBody.AppendLine(("{0} fld.Length = {1}" -f $indent, $len)) }
                [void]$stepsBody.AppendLine("$indent task.AppendField fld")
                [void]$stepsBody.AppendLine("$indent task.PerformTask")
                [void]$stepsBody.AppendLine("$indent Set task = Nothing: Set fld = Nothing")
                Add-OutputAliasBlock2 -Alias $s.OutputAlias -ProducesDb:$false
            }
            'Extraction' {
                Add-InputAliasBlock2 $s
                $keys = @($s.Keys); $suffix = $s.OutputSuffix
                [void]$stepsBody.AppendLine("$indent Set task = db.Extraction")
                [void]$stepsBody.AppendLine("$indent task.IncludeAllFields")
                foreach ($k in $keys) { [void]$stepsBody.AppendLine(("{0} task.AddKey ""{1}"", ""A""" -f $indent, $k)) }
                [void]$stepsBody.AppendLine(("{0} newDBName = Client.UniqueFileName(ireplace(filename, "".IMD"", "" {1}.IMD""))" -f $indent, $suffix))
                [void]$stepsBody.AppendLine(('{0} task.AddExtraction newDBName, "", ""' -f $indent))
                [void]$stepsBody.AppendLine("$indent task.PerformTask 1, db.Count: Set task = Nothing")
                [void]$stepsBody.AppendLine("$indent Set db = Client.OpenDatabase(newDBName)")
                [void]$stepsBody.AppendLine("$indent filename = newDBName")
                $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
                Add-OutputAliasBlock2 -Alias $oa -ProducesDb:$true
            }
            'Summarize' {
                Add-InputAliasBlock2 $s
                $groupBy=@($s.GroupBy); $sum=@($s.Sum); $suffix=$s.OutputSuffix
                [void]$stepsBody.AppendLine("$indent Set task = db.Summarization")
                foreach ($g in $groupBy) { [void]$stepsBody.AppendLine(("{0} task.AddFieldToSummarize ""{1}""" -f $indent, $g)) }
                foreach ($f in $sum)     { [void]$stepsBody.AppendLine(("{0} task.AddFieldToTotal ""{1}""" -f $indent, $f)) }
                [void]$stepsBody.AppendLine(("{0} newDBName = Client.UniqueFileName(ireplace(filename, "".IMD"", "" {1}.IMD""))" -f $indent, $suffix))
                [void]$stepsBody.AppendLine("$indent task.OutputDBName = newDBName")
                [void]$stepsBody.AppendLine("$indent task.CreatePercentField = FALSE")
                [void]$stepsBody.AppendLine("$indent task.StatisticsToInclude = SM_COUNT + SM_SUM")
                [void]$stepsBody.AppendLine("$indent task.PerformTask: Set task = Nothing")
                [void]$stepsBody.AppendLine("$indent Set db = Client.OpenDatabase(newDBName)")
                [void]$stepsBody.AppendLine("$indent filename = newDBName")
                $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
                Add-OutputAliasBlock2 -Alias $oa -ProducesDb:$true
            }
            'AssertFieldsExist' {
                Add-InputAliasBlock2 $s
                $fields = @($s.Fields); if ($fields.Count -eq 0) { throw 'AssertFieldsExist requires Fields' }
                $arr = ($fields -join "|")
                [void]$stepsBody.AppendLine("$indent Dim tdef As Object, fld As Object, i As Integer, nm As String, ok As Integer")
                [void]$stepsBody.AppendLine("$indent Set tdef = db.TableDef")
                [void]$stepsBody.AppendLine(("{0} For Each nm In Split(""{1}"", ""|"")" -f $indent, $arr))
                [void]$stepsBody.AppendLine("$indent     ok = 0")
                [void]$stepsBody.AppendLine("$indent     For i = 1 To tdef.Count")
                [void]$stepsBody.AppendLine("$indent         Set fld = tdef.GetFieldAt(i)")
                [void]$stepsBody.AppendLine("$indent         If UCase(fld.Name) = UCase(nm) Then ok = 1: Exit For")
                [void]$stepsBody.AppendLine("$indent     Next")
                [void]$stepsBody.AppendLine("$indent     If ok = 0 Then MsgBox ""Missing field: "" & nm: Exit Sub")
                [void]$stepsBody.AppendLine("$indent Next")
                [void]$stepsBody.AppendLine("$indent Set fld = Nothing: Set tdef = Nothing")
                $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
                Add-OutputAliasBlock2 -Alias $oa -ProducesDb:$false
            }
            'SwitchActive' {
                $use = if ($s -and $s.ContainsKey('Use')) { $s['Use'] } else { $null }; if (-not $use) { throw 'SwitchActive requires Use=<alias>' }
                [void]$stepsBody.AppendLine("$indent If (db_$use Is Nothing) Then")
                [void]$stepsBody.AppendLine(("{0}     MsgBox ""Alias '{1}' is not set."": Exit Sub" -f $indent, $use))
                [void]$stepsBody.AppendLine("$indent End If")
                [void]$stepsBody.AppendLine("$indent Set db = db_$use")
                [void]$stepsBody.AppendLine("$indent filename = fn_$use")
                $oa = if ($s -and $s.ContainsKey('OutputAlias')) { $s['OutputAlias'] } else { $null }
                Add-OutputAliasBlock2 -Alias $oa -ProducesDb:$false
            }
            default { throw "Unsupported step type: $($s.Type)" }
        }
    }

    $stepsText = $stepsBody.ToString()
    $iss = @"
Option Explicit

Sub Main
    Dim pm As Object, coll As Object, filename As String
    Dim db As Object, task As Object, newtabledef As Object, fld As Object
    Dim newDBName As String

    Set pm = Client.ProjectManagement
    Set coll = pm.Databases

    On Error Resume Next
    filename = Client.CurrentDatabase.Name
    If Err.Number <> 0 Then
        MsgBox "No active database. Open a database and rerun.": Exit Sub
    End If
    On Error GoTo 0

    Set db = Client.OpenDatabase(filename)

${aliasDecl.ToString()}$stepsText

    Client.RefreshFileExplorer
    Set db = Nothing: Set task = Nothing: Set pm = Nothing: Set coll = Nothing
End Sub
"@
    return $iss
}

function New-IdeaDemo {
    <#
      Creates a demo regex function (regf) and a demo macro that:
        - Creates a virtual NUM field F1 = AMOUNT*1.05
        - Extracts with keys BATCH,ENTRY
        - Summarizes by BATCH with SUM(F1)
    #>
    $func = New-IdeaRegexFunctionRegfExample

    $spec = @{ Name='PMC_Demo_Macro'; Language='EN'; Steps=@(
        @{ Type='CreateVirtualField'; Name='F1'; DataType='NUM'; Decimals=2; Equation='AMOUNT*1.05' },
        @{ Type='Extraction'; Keys=@('BATCH','ENTRY'); OutputSuffix='Indexed' },
        @{ Type='Summarize'; GroupBy=@('BATCH'); Sum=@('F1'); OutputSuffix='ByBatch' }
    )}
    $macro = New-IdeaMacroFromSpec -Spec $spec
    [pscustomobject]@{ Function=$func; Macro=$macro }
}

if ($MyInvocation.InvocationName -eq '.') {
    # Script dot-sourced; do nothing.
} else {
    Write-Host "Loaded idea-gen.ps1. Try: New-IdeaDemo" -ForegroundColor Cyan
}
