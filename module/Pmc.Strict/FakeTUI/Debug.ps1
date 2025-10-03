# FakeTUI Debug Logger
# Simple debug logging system for troubleshooting

$Script:DebugLogPath = "$PSScriptRoot/faketui-debug.log"
$Script:DebugEnabled = $true

function Write-FakeTUIDebug {
    param(
        [string]$Message,
        [string]$Category = "INFO"
    )

    if (-not $Script:DebugEnabled) { return }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Category] $Message"

    try {
        Add-Content -Path $Script:DebugLogPath -Value $logEntry -ErrorAction SilentlyContinue
    } catch {
        # Silently fail if can't write to log
    }
}

function Clear-FakeTUIDebugLog {
    try {
        if (Test-Path $Script:DebugLogPath) {
            Remove-Item $Script:DebugLogPath -Force
        }
        Write-FakeTUIDebug "Debug log initialized" "SYSTEM"
    } catch {}
}

function Get-FakeTUIDebugLog {
    param([int]$Lines = 50)

    if (Test-Path $Script:DebugLogPath) {
        Get-Content $Script:DebugLogPath -Tail $Lines
    } else {
        Write-Host "No debug log found at: $Script:DebugLogPath" -ForegroundColor Yellow
    }
}

# Initialize log on load
Clear-FakeTUIDebugLog
