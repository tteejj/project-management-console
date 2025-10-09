<#!
Email-Safe Self-Extracting Installer (Single-File, Text-Only)

Usage (Windows):
  - Save this file (with payload appended) as ConsoleUI-Installer.ps1.txt
  - Open PowerShell (pwsh or powershell), cd to the target install folder
  - Run:  pwsh .\ConsoleUI-Installer.ps1.txt -ScriptPath .\ConsoleUI-Installer.ps1.txt
           or
          powershell -ExecutionPolicy Bypass .\ConsoleUI-Installer.ps1.txt -ScriptPath .\ConsoleUI-Installer.ps1.txt
           or
          Get-Content .\ConsoleUI-Installer.ps1.txt -Raw | Invoke-Expression

By default, files are extracted relative to the current directory.
Use -Target to override the destination directory.

This installer reads its own file, scans markers:
  ### BEGIN FILE path=<relative> sha256=<hex> len=<bytes>
  <base64 lines>
  ### END FILE
and writes each file to disk, verifying SHA-256.
!#>

[CmdletBinding()]
param(
    [string]$Target = '.',
    [string]$ScriptPath,
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Help,
    [switch]$Readme
)

function Write-Info($m){ Write-Host $m -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Write-Err($m){ Write-Host $m -ForegroundColor Red }
function Write-Ok($m){ Write-Host $m -ForegroundColor Green }


$ReadmeText = @"
ConsoleUI Email Installer (Text‑Only)

What this is
- A single PowerShell script (this file) that unpacks a set of files contained
  inside it (as Base64) into the folder you run it in.

Requirements
- Windows with PowerShell (pwsh 7+ recommended; Windows PowerShell works too).

How to install
1) Save this file as: ConsoleUI-Installer.ps1.txt
2) Create/open the folder where you want the files installed.
3) Open PowerShell and cd to that folder.
4) Run one of:
   - pwsh .\ConsoleUI-Installer.ps1.txt -ScriptPath .\ConsoleUI-Installer.ps1.txt
   - powershell -ExecutionPolicy Bypass .\ConsoleUI-Installer.ps1.txt -ScriptPath .\ConsoleUI-Installer.ps1.txt
   - Or: Get-Content .\ConsoleUI-Installer.ps1.txt -Raw | Invoke-Expression

Options
-Target "C:\\\path\\to\\folder"  Change the destination (default: current folder)
-ScriptPath <path>              Explicit path to this installer (usually auto-detected)
-DryRun                         Preview; don't write files
-Force                          Overwrite files even if they already exist
-Help or -Readme                Show this guide and exit

After install (start ConsoleUI)
- From the install folder, run:
  pwsh -File module\Pmc.Strict\consoleui\ConsoleUI.ps1 -Start

Integrity
- Files are stored as Base64 and verified with SHA‑256 before writing.
"@

if ($Help -or $Readme) { Write-Host $ReadmeText -ForegroundColor Cyan; exit 0 }

function Join-PathSafe {
    param([string]$Base,[string]$Rel)
    # Normalize path separators to platform style
    $relFixed = $Rel -replace '[\\/]+', [IO.Path]::DirectorySeparatorChar
    # Just use Join-Path - don't call GetFullPath as it causes path accumulation bugs
    return (Join-Path $Base $relFixed)
}

function Ensure-Dir {
    param([string]$Path)
    $dir = [System.IO.Path]::GetDirectoryName($Path)
    if ([string]::IsNullOrWhiteSpace($dir)) { return }
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

function Get-SHA256Hex {
    param([byte[]]$Bytes)
    $sha=[System.Security.Cryptography.SHA256]::Create()
    try { $h=$sha.ComputeHash($Bytes) } finally { $sha.Dispose() }
    ($h | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Decode-Base64 { param([string]$Text) [System.Convert]::FromBase64String($Text) }

function Extract-Payload {
    param([string]$SelfPath,[string]$Dest,[switch]$Dry,[switch]$Overwrite)

    Write-Info "Installer: extracting to '$Dest'"
    $all = Get-Content -Path $SelfPath -Raw -Encoding UTF8 -ErrorAction Stop
    $re = "(?ms)### BEGIN FILE path=(?<path>[^\r\n]+) sha256=(?<sha>[0-9a-fA-F]{64}) len=(?<len>\d+)\s+(?<b64>.*?)### END FILE"
    $matches = [System.Text.RegularExpressions.Regex]::Matches($all, $re)
    if ($matches.Count -eq 0) { Write-Err "No payload markers found."; return 1 }

    $ok=0; $fail=0
    foreach ($m in $matches) {
        $rel = $m.Groups['path'].Value.Trim()
        $sha = $m.Groups['sha'].Value.Trim().ToLower()
        $declared = [int64]$m.Groups['len'].Value
        $b64 = ($m.Groups['b64'].Value -replace "\s+", "")
        try { $bytes = Decode-Base64 $b64 } catch { Write-Err "Decode failed for ${rel}: $_"; $fail++; continue }
        if ($bytes.LongLength -ne $declared) { Write-Warn ("Length mismatch for {0}: declared={1}, actual={2}" -f $rel,$declared,$bytes.LongLength) }
        $calc = Get-SHA256Hex $bytes
        if ($calc -ne $sha) { Write-Err ("SHA256 mismatch for {0}: expected={1} got={2}" -f $rel,$sha,$calc); $fail++; continue }

        $fullPath = Join-PathSafe $Dest $rel
        if ($Dry) { Write-Host "[DRY] write $fullPath"; $ok++; continue }
        try {
            Ensure-Dir $fullPath
            if ((Test-Path $fullPath) -and -not $Overwrite) {
                try {
                    $existing = [System.IO.File]::ReadAllBytes($fullPath)
                    if ($existing -and $existing.Length -gt 0) {
                        $exSha = Get-SHA256Hex $existing
                        if ($exSha -eq $sha) { Write-Ok "Unchanged: $rel"; $ok++; continue }
                    }
                } catch {
                    # If we can't read existing file, just overwrite it
                }
            }
            [System.IO.File]::WriteAllBytes($fullPath, $bytes)
            Write-Ok "Wrote $rel"; $ok++
        } catch { Write-Err ("Write failed for {0}: {1}" -f $rel,$_); $fail++ }
    }

    Write-Host ("Done. OK={0} Fail={1}" -f $ok,$fail) -ForegroundColor Gray
    return ([int]$fail)
}

# Get path to this script - try multiple methods for reliability
$self = $null

# Try explicit parameter first
if ($ScriptPath -and (Test-Path $ScriptPath)) {
    $self = [System.IO.Path]::GetFullPath($ScriptPath)
}

# Try built-in variables
if (-not $self) {
    if ($PSCommandPath) { $self = $PSCommandPath }
    elseif ($MyInvocation.MyCommand.Path) { $self = $MyInvocation.MyCommand.Path }
    elseif ($MyInvocation.MyCommand.Definition -and (Test-Path $MyInvocation.MyCommand.Definition)) {
        $self = $MyInvocation.MyCommand.Definition
    }
}

# Last resort: look in current directory for common installer names
if (-not $self -or -not (Test-Path $self)) {
    $commonNames = @('ConsoleUI-Installer.ps1.txt', 'ConsoleUI-Installer.ps1', $MyInvocation.MyCommand.Name)
    foreach ($name in $commonNames) {
        if ($name) {
            $guessPath = Join-Path $PWD $name
            if (Test-Path $guessPath) {
                $self = $guessPath
                Write-Warn "Auto-detected installer at: $guessPath"
                break
            }
        }
    }
}

if (-not $self -or -not (Test-Path $self)) {
    Write-Err "Cannot determine installer script path."
    Write-Host ""
    Write-Host "Try one of these methods:" -ForegroundColor Yellow
    Write-Host "  1. Run with explicit path parameter:"
    Write-Host "     pwsh .\ConsoleUI-Installer.ps1.txt -ScriptPath .\ConsoleUI-Installer.ps1.txt" -ForegroundColor Cyan
    Write-Host "  2. Or use Invoke-Command:"
    Write-Host "     Get-Content .\ConsoleUI-Installer.ps1.txt -Raw | Invoke-Expression" -ForegroundColor Cyan
    exit 2
}

# Determine destination: if user specified -Target, use it; otherwise use installer's directory
$scriptDir = Split-Path -Parent ([System.IO.Path]::GetFullPath($self))
if ($PSBoundParameters.ContainsKey('Target')) {
    $destRoot = [System.IO.Path]::GetFullPath($Target)
} else {
    $destRoot = $scriptDir
}

$rc = Extract-Payload -SelfPath $self -Dest $destRoot -Dry:$DryRun -Overwrite:$Force
if ($rc -eq 0 -and -not $DryRun) {
    Write-Host ""; Write-Ok "Install completed. Next:"
    Write-Host "  pwsh start.ps1" -ForegroundColor Yellow
}
exit $rc

### BEGIN PAYLOAD
# The packer will append file blocks like:
# ### BEGIN FILE path=module\Pmc.Strict\consoleui\ConsoleUI.ps1 sha256=<hex> len=<bytes>
# <base64 data wrapped to ~76 cols>
# ### END FILE
