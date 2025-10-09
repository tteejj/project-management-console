param(
  [string]$SourceRoot = "module\Pmc.Strict\consoleui",
  [string]$Output = "ConsoleUI-Installer.ps1.txt",
  [string]$Template = "tools\EmailInstaller.Template.ps1",
  [string]$Launcher = "start.ps1",
  [int]$Wrap = 76
)
function Get-SHA256Hex {
  param([byte[]]$Bytes)
  $sha=[System.Security.Cryptography.SHA256]::Create()
  try {$h=$sha.ComputeHash($Bytes)} finally {$sha.Dispose()}
  ($h|ForEach-Object{$_.ToString('x2')}) -join ''
}
function Wrap-Base64 {
  param([string]$b64,[int]$Width=76)
  $sb = New-Object System.Text.StringBuilder
  for($i=0; $i -lt $b64.Length; $i+=$Width){
    [void]$sb.AppendLine($b64.Substring($i,[Math]::Min($Width,$b64.Length-$i)))
  }
  $sb.ToString()
}
function Add-FileToPackage {
  param([string]$FilePath, [string]$DestPath, [string]$OutputFile)
  $bytes = [IO.File]::ReadAllBytes($FilePath)
  $sha = Get-SHA256Hex $bytes
  $b64 = [Convert]::ToBase64String($bytes)
  $b64Wrapped = Wrap-Base64 $b64 $Wrap
  Add-Content -Path $OutputFile -Value ("### BEGIN FILE path={0} sha256={1} len={2}" -f $DestPath,$sha,$bytes.LongLength)
  Add-Content -Path $OutputFile -Value $b64Wrapped
  Add-Content -Path $OutputFile -Value "### END FILE"
  Add-Content -Path $OutputFile -Value ""
}

if(-not (Test-Path $Template)){ throw "Template not found: $Template" }
if(-not (Test-Path $Launcher)){ throw "Launcher not found: $Launcher" }

Copy-Item -Force $Template $Output
Add-Content -Path $Output -Value ""

# Add launcher first
Add-FileToPackage -FilePath $Launcher -DestPath "start.ps1" -OutputFile $Output

# Add config files if they exist
if (Test-Path "module/config.json") {
  Add-FileToPackage -FilePath "module/config.json" -DestPath "config.json" -OutputFile $Output
}
if (Test-Path "module/tasks.json") {
  Add-FileToPackage -FilePath "module/tasks.json" -DestPath "tasks.json" -OutputFile $Output
}

# Add all consoleui files with relative paths (no prefix, flat extraction)
$rootFull = [IO.Path]::GetFullPath($SourceRoot)
$files = Get-ChildItem -Path $rootFull -File -Recurse | Where-Object {
  $_.Name -notmatch '\\.(log|lock|tmp)$'
}

$totalFiles = 1  # start.ps1
if (Test-Path "module/config.json") { $totalFiles++ }
if (Test-Path "module/tasks.json") { $totalFiles++ }

foreach($f in $files){
  # Get relative path from source root (this preserves subdirectories like deps/, Handlers/)
  $relPath = $f.FullName.Substring($rootFull.Length).TrimStart('\', '/') -replace '/', '\'
  Add-FileToPackage -FilePath $f.FullName -DestPath $relPath -OutputFile $Output
  $totalFiles++
}

Write-Host "Wrote $Output with $totalFiles files" -ForegroundColor Green
