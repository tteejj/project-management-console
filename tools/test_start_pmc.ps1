Param()

# Test harness for start-pmc.ps1 and its used components
# Produces human-readable diagnostics for static and runtime checks.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Result {
    param(
        [ValidateSet('OK','WARN','FAIL','INFO')] [string]$Level,
        [string]$Area,
        [string]$Message,
        [string]$Detail = ''
    )
    $prefix = "[$Level] $Area - $Message"
    if ([string]::IsNullOrWhiteSpace($Detail)) { $prefix }
    else { "${prefix}: $Detail" }
}

function Try-Run {
    param(
        [string]$Area,
        [scriptblock]$Action,
        [string]$OnSuccess = 'OK',
        [string]$OnFail = 'FAIL'
    )
    try {
        $result = & $Action
        if ($result -is [string]) { New-Result -Level 'OK' -Area $Area -Message $result }
        else { New-Result -Level $OnSuccess -Area $Area -Message 'Check passed' }
    } catch {
        New-Result -Level $OnFail -Area $Area -Message 'Check failed' -Detail ($_.ToString())
    }
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $repoRoot

$startScript = Join-Path $repoRoot 'start-pmc.ps1'
$pmcScript   = Join-Path $repoRoot 'pmc.ps1'
$moduleManifest = Join-Path $repoRoot 'module/Pmc.Strict/Pmc.Strict.psd1'
$moduleRoot  = Split-Path $moduleManifest -Parent

# 1) Existence checks
if (Test-Path $startScript) { New-Result OK 'FILES' "Found start-pmc.ps1" $startScript } else { New-Result FAIL 'FILES' 'Missing start-pmc.ps1' $startScript }
if (Test-Path $pmcScript)   { New-Result OK 'FILES' "Found pmc.ps1" $pmcScript } else { New-Result FAIL 'FILES' 'Missing pmc.ps1' $pmcScript }
if (Test-Path $moduleManifest) { New-Result OK 'FILES' 'Found Pmc.Strict module manifest' $moduleManifest } else { New-Result FAIL 'FILES' 'Missing Pmc.Strict module manifest' $moduleManifest }

# 2) Static analysis: dot-sourcing + exit hazard
$pmcContent = if (Test-Path $pmcScript) { Get-Content $pmcScript -Raw } else { '' }
$startContent = if (Test-Path $startScript) { Get-Content $startScript -Raw } else { '' }
if ($startContent -match "(?m)^\s*\.\s+\./pmc\.ps1\b") {
    if ($pmcContent -match "(?m)^\s*exit\s+\d+") {
        New-Result WARN 'SEMANTICS' 'Dot-sourcing pmc.ps1 while pmc.ps1 calls exit' 'exit in a dot-sourced script terminates the entire session; post-call code in start-pmc.ps1 will not run'
    } else {
        New-Result INFO 'SEMANTICS' 'Dot-sourcing pmc.ps1 detected' 'Consider invocation (call) vs. dot-sourcing implications'
    }
} else {
    New-Result INFO 'SEMANTICS' 'pmc.ps1 not dot-sourced by start-pmc.ps1' 'Launcher may be invoking differently than expected'
}

# 3) Import module and verify key function availability
Try-Run 'MODULE' { Import-Module $moduleManifest -Force -ErrorAction Stop; 'Module imported' }

$requiredFromPmc = @(
    'Invoke-PmcCommand','Test-PmcInputSafety','Get-PmcState','Write-PmcStyled',
    'Enable-PmcInteractiveMode','Initialize-PmcScreen','Write-PmcDebug','Update-PmcHeaderStatus',
    'Clear-CommandOutput','Read-PmcCommand','Disable-PmcInteractiveMode','Clear-PmcContentArea',
    'Hide-PmcCursor','Get-PmcContentBounds','Set-PmcInputPrompt','Reset-PmcScreen',
    'Initialize-PmcDebugSystem','Initialize-PmcSecuritySystem','Initialize-PmcThemeSystem',
    'Set-PmcSecurityLevel','Set-PmcConfigProvider','Get-PmcDebugStatus','Get-PmcSecurityStatus',
    'Show-PmcData','Ensure-PmcUniversalDisplay','Register-PmcUniversalCommands'
)

foreach ($fn in $requiredFromPmc) {
    if (Get-Command $fn -ErrorAction SilentlyContinue) {
        New-Result OK 'FUNCTION' "Found $fn"
    } else {
        New-Result FAIL 'FUNCTION' "Missing $fn"
    }
}

# 4) Ensure-PmcUniversalDisplay behavior
if (Get-Command Ensure-PmcUniversalDisplay -ErrorAction SilentlyContinue) {
    try {
        $ok = Ensure-PmcUniversalDisplay
        if ($ok) { New-Result OK 'UNIV-DISPLAY' 'Ensure-PmcUniversalDisplay returned $true' }
        else { New-Result WARN 'UNIV-DISPLAY' 'Ensure-PmcUniversalDisplay returned $false' }
    } catch {
        New-Result FAIL 'UNIV-DISPLAY' 'Ensure-PmcUniversalDisplay threw' $_.Exception.Message
    }
}

# 5) Runtime check: start-pmc.ps1 -Help should not hang; verify exit path stops further code due to dot-sourced exit
try {
    $cmd = ". '$startScript' -Help; 'AFTER-HELP'"
    $helpOut = & pwsh -NoProfile -NoLogo -Command $cmd 2>&1
    $helpText = [string]::Join("`n", $helpOut)
    if ($helpText -match 'PMC - Project Management Console') {
        New-Result OK 'RUNTIME' 'start-pmc.ps1 -Help printed PMC help'
    } else {
        New-Result FAIL 'RUNTIME' 'start-pmc.ps1 -Help did not print expected help' $helpText
    }
    if ($helpText -notmatch 'AFTER-HELP') {
        New-Result WARN 'RUNTIME' 'Post-call code after pmc.ps1 did not run' 'Likely due to exit in pmc.ps1 while dot-sourced'
    } else {
        New-Result INFO 'RUNTIME' 'Post-call code ran after -Help' 'Dot-sourcing may not be exiting the session as expected'
    }
} catch {
    New-Result FAIL 'RUNTIME' 'start-pmc.ps1 -Help invocation failed' ($_.ToString())
}

# 6) Runtime check: start-pmc.ps1 -NoInteractive should return error about interactive requirement
try {
    $tmp = $env:TEMP
    if ([string]::IsNullOrWhiteSpace($tmp)) { $tmp = $env:TMPDIR }
    if ([string]::IsNullOrWhiteSpace($tmp)) { $tmp = '/tmp' }
    $outPath = Join-Path $tmp 'pmc_stdout.txt'
    $errPath = Join-Path $tmp 'pmc_stderr.txt'
    $proc = Start-Process pwsh -ArgumentList @('-NoProfile','-NoLogo','-File', $startScript, '-NoInteractive') -NoNewWindow -PassThru -Wait -RedirectStandardOutput $outPath -RedirectStandardError $errPath
    $stdout = Get-Content $outPath -Raw -ErrorAction SilentlyContinue
    $stderr = Get-Content $errPath -Raw -ErrorAction SilentlyContinue
    if ($proc.ExitCode -ne 0) {
        New-Result OK 'RUNTIME' 'start-pmc.ps1 -NoInteractive exited non-zero (expected)'
    } else {
        New-Result WARN 'RUNTIME' 'start-pmc.ps1 -NoInteractive exited 0' 'Expected a non-zero exit due to interactive requirement'
    }
    if ($stdout -match 'Interactive mode is required') {
        New-Result OK 'RUNTIME' 'Non-interactive mode rejected with message'
    } else {
        New-Result WARN 'RUNTIME' 'Non-interactive message not detected' ($stdout + $stderr)
    }
} catch {
    New-Result FAIL 'RUNTIME' 'start-pmc.ps1 -NoInteractive failed' ($_.ToString())
}

# 6b) Control: direct pmc.ps1 -NoInteractive exit code
try {
    $p2 = Start-Process pwsh -ArgumentList @('-NoProfile','-NoLogo','-File', $pmcScript, '-NoInteractive') -NoNewWindow -PassThru -Wait
    if ($p2.ExitCode -ne 0) { New-Result OK 'RUNTIME' 'pmc.ps1 -NoInteractive exited non-zero (expected)' }
    else { New-Result WARN 'RUNTIME' 'pmc.ps1 -NoInteractive exited 0' }
} catch {
    New-Result FAIL 'RUNTIME' 'pmc.ps1 -NoInteractive failed' ($_.ToString())
}

# 7) Portability checks
New-Result INFO 'PORTABILITY' 'Shebang uses pwsh' "Start script requires PowerShell 7+ (uses '??' in pmc.ps1)"

# 8) Config presence is optional; verify defaults path resolves
$configDefault = Join-Path $repoRoot 'config.json'
if (Test-Path $configDefault) { New-Result INFO 'CONFIG' 'config.json present' $configDefault } else { New-Result INFO 'CONFIG' 'config.json missing; pmc.ps1 will use defaults' $configDefault }

# 9) Verify module exports include Ensure-PmcUniversalDisplay and other key functions
try {
    $psm1 = Join-Path $moduleRoot 'Pmc.Strict.psm1'
    if (Test-Path $psm1) {
        $exportsText = Get-Content $psm1 -Raw
        foreach ($must in @('Ensure-PmcUniversalDisplay','Invoke-PmcCommand','Test-PmcInputSafety','Show-PmcData')) {
            if ($exportsText -match [Regex]::Escape($must)) {
                New-Result OK 'EXPORTS' "$must exported"
            } else {
                New-Result FAIL 'EXPORTS' "$must not exported from module"
            }
        }
    } else {
        New-Result FAIL 'EXPORTS' 'Module PSM1 missing' $psm1
    }
} catch {
    New-Result FAIL 'EXPORTS' 'Error verifying exports' ($_.ToString())
}

# 10) Summary hint
New-Result INFO 'SUMMARY' 'Analysis complete' 'Scan includes file presence, module import, function availability, and guarded runtime checks'
