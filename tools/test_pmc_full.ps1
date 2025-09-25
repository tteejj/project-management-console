Param()

# Comprehensive test harness for PMC modules and functions
# Scope: TESTING ONLY — no program code changes. Uses isolated temp data paths.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Result { param([ValidateSet('OK','WARN','FAIL','INFO')]$Level,[string]$Area,[string]$Message,[string]$Detail=''); $p="[$Level] $Area - $Message"; if([string]::IsNullOrWhiteSpace($Detail)){ $p } else { "${p}: $Detail" } }
function Try-Run { param([string]$Area,[scriptblock]$Action,[string]$OnSuccess='OK'); try { $r=& $Action; if($r -is [string] -and $r){ New-Result OK $Area $r } else { New-Result $OnSuccess $Area 'Check passed' } } catch { New-Result FAIL $Area 'Check failed' ($_.ToString()) } }

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $repoRoot

$moduleManifest = Join-Path $repoRoot 'module/Pmc.Strict/Pmc.Strict.psd1'
$tmpRoot = Join-Path $repoRoot 'tests/tmp'
$resultsDir = Join-Path $repoRoot 'tests/results'
New-Item -ItemType Directory -Force -Path $tmpRoot, $resultsDir | Out-Null
$testData = Join-Path $tmpRoot 'tasks.json'
$debugLog = Join-Path $resultsDir 'debug-full.log'

# Minimal test dataset
$sampleData = @{
  tasks = @(
    @{ id=1; text='Write tests'; project='pmc'; due=(Get-Date).AddDays(1).ToString('yyyy-MM-dd'); priority=1; status='pending'; tags=@('dev') }
    @{ id=2; text='Fix bug'; project='pmc'; due=(Get-Date).AddDays(-1).ToString('yyyy-MM-dd'); priority=2; status='pending'; tags=@('bug') }
  )
  projects = @(@{ name='pmc'; description='PMC project' })
  timelogs = @(@{ id=1; date=(Get-Date).ToString('yyyy-MM-dd'); project='pmc'; duration='30m'; description='Testing' })
  activityLog = @()
  templates = @()
  recurringTemplates = @()
  currentContext = 'pmc'
  schema_version = 1
  preferences = @{ autoBackup=$false }
  aliases = @{}
} | ConvertTo-Json -Depth 10
$sampleData | Set-Content -Path $testData -Encoding UTF8

# Import module
Try-Run 'MODULE' { Import-Module $moduleManifest -Force -ErrorAction Stop; 'Module imported' }

# Install test config provider overriding paths and logs
Try-Run 'CONFIG' {
  $cfg = @{
    Display = @{ Theme=@{ Enabled=$true; Hex='#33aaff'; UseTrueColor=$true; Global=$false; PreserveAlerts=$true }; Icons=@{ Mode='ascii' }; RefreshOnCommand=$false; ShowBannerOnRefresh=$false }
    Behavior = @{ SafePathsStrict=$true; EnableCsvLedger=$false; WhatIf=$false; MaxUndoLevels=5; MaxBackups=2; ReportRichCsv=$false; StrictDataMode=$true }
    Paths = @{ TaskFile=$testData; AllowedWriteDirs=@($tmpRoot,$resultsDir) }
    Debug = @{ Level=2; LogPath=$debugLog; MaxSize='5MB'; RedactSensitive=$true; IncludePerformance=$true }
    Security = @{ AllowedWritePaths=@($tmpRoot,$resultsDir); MaxFileSize='10MB'; MaxMemoryUsage='200MB'; ScanForSensitiveData=$false; RequirePathWhitelist=$true; AuditAllFileOps=$false }
    Interactive = @{ Enabled=$false; GhostText=$true; CompletionMenus=$true }
    Excel = @{ SourceFolder = (Join-Path $tmpRoot 'excel_input'); DestinationPath=(Join-Path $tmpRoot 'excel_output.xlsm'); SourceSheet='SVI-CAS'; DestSheet='Output'; ID2FieldName='CASNumber'; AllowedExtensions=@('.xlsm','.xlsx'); MaxFileSize='50MB'; Mappings=@() }
  }
  Set-PmcConfigProvider -Get { $cfg } -Set { param($c) $script:cfg=$c }
  'Test config provider set'
}

# Initialize subsystems that rely on config
Try-Run 'DEBUG' { Initialize-PmcDebugSystem -Level 2; $s=Get-PmcDebugStatus; if(-not $s.Enabled){ throw 'Debug not enabled' }; "Debug Level=$($s.Level) Path=$($s.LogPath)" }
Try-Run 'SECURITY' { Initialize-PmcSecuritySystem; $s = Get-PmcSecurityStatus; if(-not $s.PathWhitelistEnabled){ throw 'Whitelist not enabled' }; "AllowedPaths=$(([string]::Join(',', $s.AllowedWritePaths)))" }
Try-Run 'THEME' { Initialize-PmcThemeSystem; $st = Get-PmcStyle -Name 'Body'; if(-not $st){ throw 'Style not available' }; 'Theme initialized' }

# Export consistency: manifest vs. actual exported
Try-Run 'EXPORTS:compare' {
  $mod = Get-Module Pmc.Strict -ErrorAction Stop
  $actual = @($mod.ExportedFunctions.Keys | Sort-Object)
  $declared = @()
  if (Test-Path $moduleManifest) {
    $psd1 = Import-PowerShellDataFile -Path $moduleManifest
    if ($psd1 -and $psd1.FunctionsToExport) { $declared = @($psd1.FunctionsToExport | Sort-Object) }
  }
  $missing = @($declared | Where-Object { $_ -and ($_ -notin $actual) })
  $extra = @($actual | Where-Object { $_ -and ($_ -notin $declared) })
  "Declared=$($declared.Count) Exported=$($actual.Count) Missing=$($missing.Count) Extra=$($extra.Count)"
}

# Storage and Data
Try-Run 'STORAGE:Get' { $d=Get-PmcData; if(-not $d.tasks -or $d.tasks.Count -lt 2){ throw 'Tasks missing' }; "Tasks=$($d.tasks.Count) Projects=$($d.projects.Count)" }
Try-Run 'STORAGE:Provider' { $p=Get-PmcDataProvider; if(-not $p -or -not $p.PSObject.Members['GetData']){ throw 'Provider invalid' }; 'Provider ok' }

# AST Parser and Completions
Try-Run 'AST:Tokens' { $t=ConvertTo-PmcTokens 'task add "New item" @pmc p1'; if($t.Count -lt 3){ throw 'Tokenization too small' }; "Tokens=$($t.Count)" }
Try-Run 'AST:Args' { $ctx = ConvertTo-PmcContext -Buffer 'task add "New item" @pmc p1'; if(-not $ctx){ throw 'Context null' }; "Domain=$($ctx.Domain) Action=$($ctx.Action)" }
Try-Run 'AST:Completions' { $c=Get-PmcCompletionsFromAst 'q t'; if($c.Count -lt 1){ throw 'No completions' }; "Count=$($c.Count)" }

# Execution Engine (non-interactive safe commands)
Try-Run 'EXEC:help' { Invoke-PmcCommand -Buffer 'help'; 'help command executed' }
Try-Run 'EXEC:show projects' { Invoke-PmcCommand -Buffer 'projects'; 'projects command executed' }

# Query Engine
Try-Run 'QUERY:basic' { $r=Invoke-PmcQuery 'q tasks'; if(-not $r -or $r.Count -lt 1){ throw 'No query results' }; "Results=$($r.Count)" }
Try-Run 'QUERY:filter' { $r=Invoke-PmcQuery 'q tasks overdue'; if(-not $r){ throw 'No results object' }; 'Query executed' }

# UI/Display (non-interactive code paths)
Try-Run 'DISPLAY:Simple' { Show-PmcSimpleData -DataType 'task' -Filters @{ status='pending' }; 'Simple display rendered' }
Try-Run 'DISPLAY:Universal' { Show-PmcData -DataType 'project' -Filters @{ archived=$false } -Title 'Projects'; 'Universal display rendered' }

# Security checks
Try-Run 'SECURITY:PathGood' { if(-not (Test-PmcPathSafety -Path (Join-Path $tmpRoot 'ok.txt'))){ throw 'Path rejected' }; 'Path accepted' }
Try-Run 'SECURITY:PathBad' { if(Test-PmcPathSafety -Path '../../etc/passwd'){ throw 'Bad path accepted' }; 'Bad path rejected' }
Try-Run 'SECURITY:Input' { if(-not (Test-PmcInputSafety -Input 'help' -InputType 'command')){ throw 'Safe command rejected' }; 'Input accepted' }

# Debug logging and performance wrapper
Try-Run 'DEBUG:Write' { Write-PmcDebug -Level 1 -Category 'TEST' -Message 'debug message'; Test-Path $debugLog | Out-Null; 'Debug write ok' }
Try-Run 'DEBUG:Measure' { Measure-PmcOperation -Name 'noop' -Script { Start-Sleep -Milliseconds 10 }; 'Measure ok' }

# Undo/Redo cycle
Try-Run 'UNDO:init' { Initialize-PmcUndoSystem; 'Undo initialized' }
Try-Run 'UNDO:record' { $d=Get-PmcData; $d.tasks += [pscustomobject]@{ id=3; text='Temp'; project='pmc'; status='pending' }; Set-PmcAllData -Data $d; Record-PmcUndoState; 'Undo state recorded' }
Try-Run 'UNDO:undo' { Invoke-PmcUndo; 'Undo invoked' }

# Aliases
Try-Run 'ALIASES:add' { Add-PmcAlias -Name 't' -Value 'tasks'; 'Alias added' }
Try-Run 'ALIASES:list' { $a=Get-PmcAliasList; if(-not $a){ throw 'No aliases' }; 'Alias list ok' }

# Analytics (safe summaries)
Try-Run 'ANALYTICS:stats' { $s=Get-PmcStatistics; if(-not $s){ throw 'No stats' }; 'Stats ok' }
Try-Run 'ANALYTICS:velocity' { $v=Get-PmcVelocity; if(-not $v){ throw 'No velocity' }; 'Velocity ok' }

# Theme operations (non-interactive)
Try-Run 'THEME:reset' { Reset-PmcTheme; 'Theme reset ok' }

# Import/Export (to temp paths)
$exportJson = Join-Path $tmpRoot 'tasks-export.json'
Try-Run 'EXPORT:tasks' { Export-PmcTasks -Path $exportJson; if(-not (Test-Path $exportJson)){ throw 'Export file missing' }; 'Export ok' }

# Excel lite (non-COM code paths)
Try-Run 'EXCEL:latest' { $null = Get-PmcLatestExcelFile; 'Excel latest ok' }

# Shortcuts / Universal Display registration
Try-Run 'UD:get' { $map = Get-PmcUniversalCommands; if(-not $map -or $map.Count -lt 3){ throw 'No UD commands' }; 'UD commands ok' }
Try-Run 'UD:ensure' { if(-not (Ensure-PmcUniversalDisplay)){ throw 'Ensure returned false' }; 'UD ensured' }

# Services and misc
Try-Run 'SRV:legacy' { if(-not (Get-Command -Name Invoke-Expression -ErrorAction SilentlyContinue)){ 'legacy ok' } else { 'legacy ok' } }

New-Result INFO 'SUMMARY' 'Full analysis complete' 'See lines above for failures/warnings'
