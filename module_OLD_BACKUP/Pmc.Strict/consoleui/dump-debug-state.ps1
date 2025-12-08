# dump-debug-state.ps1 - Capture TUI debug state for analysis
# Usage: pwsh dump-debug-state.ps1

$ErrorActionPreference = "Continue"

Write-Host "=== PMC TUI Debug State Dump ===" -ForegroundColor Cyan
Write-Host ""

# 1. Find latest log file
$moduleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$logDir = Join-Path $moduleRoot ".pmc-data/logs"

if (Test-Path $logDir) {
    $latestLog = Get-ChildItem $logDir -Filter "pmc-tui-*.log" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($latestLog) {
        Write-Host "Latest Log: $($latestLog.FullName)" -ForegroundColor Green
        Write-Host "Log Size: $([math]::Round($latestLog.Length / 1KB, 2)) KB" -ForegroundColor Green
        Write-Host "Last Modified: $($latestLog.LastWriteTime)" -ForegroundColor Green
        Write-Host ""

        # Show last 100 lines
        Write-Host "=== Last 100 Log Lines ===" -ForegroundColor Yellow
        Get-Content $latestLog.FullName -Tail 100 | ForEach-Object {
            if ($_ -match '\[ERROR\]') {
                Write-Host $_ -ForegroundColor Red
            } elseif ($_ -match '\[RENDER\]') {
                Write-Host $_ -ForegroundColor Cyan
            } elseif ($_ -match '\[LIFECYCLE\]') {
                Write-Host $_ -ForegroundColor Magenta
            } else {
                Write-Host $_
            }
        }
        Write-Host ""

        # Count key events
        $content = Get-Content $latestLog.FullName -Raw
        $renderCalls = ([regex]::Matches($content, "BeginFrame")).Count
        $writeAtCalls = ([regex]::Matches($content, "WriteAt\(\d+,\d+\)")).Count
        $errors = ([regex]::Matches($content, "\[ERROR\]")).Count
        $lifecycles = ([regex]::Matches($content, "\[LIFECYCLE\]")).Count

        Write-Host "=== Event Counts ===" -ForegroundColor Yellow
        Write-Host "  BeginFrame calls: $renderCalls" -ForegroundColor $(if ($renderCalls -eq 0) { "Red" } else { "Green" })
        Write-Host "  WriteAt calls: $writeAtCalls" -ForegroundColor $(if ($writeAtCalls -eq 0) { "Red" } else { "Green" })
        Write-Host "  Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
        Write-Host "  Lifecycle events: $lifecycles" -ForegroundColor $(if ($lifecycles -eq 0) { "Red" } else { "Green" })
        Write-Host ""

        # Extract rendering issues
        Write-Host "=== Rendering Issues ===" -ForegroundColor Yellow
        $renderErrors = $content -split "`n" | Where-Object { $_ -match 'ERROR.*render' -or $_ -match 'WriteAt.*null' }
        if ($renderErrors.Count -gt 0) {
            $renderErrors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        } else {
            Write-Host "  No rendering errors found" -ForegroundColor Green
        }
        Write-Host ""

        # Check for common issues
        Write-Host "=== Common Issues Check ===" -ForegroundColor Yellow
        $issues = @()

        if ($renderCalls -eq 0) {
            $issues += "NO RENDER CALLS - BeginFrame never called"
        }
        if ($writeAtCalls -eq 0) {
            $issues += "NO WRITE CALLS - No content written to render engine"
        }
        if ($content -match "content is null/empty") {
            $issues += "NULL CONTENT - Widgets returning null/empty content"
        }
        if ($content -match "RenderContent\(\) returned null/empty") {
            $issues += "EMPTY RENDER - Screen's RenderContent() not generating output"
        }
        if ($content -match "content unchanged \(cached\)") {
            $cachedCount = ([regex]::Matches($content, "content unchanged")).Count
            if ($cachedCount -gt $writeAtCalls) {
                $issues += "EXCESSIVE CACHING - Content cached, no updates rendered ($cachedCount cached vs $writeAtCalls writes)"
            }
        }

        if ($issues.Count -gt 0) {
            foreach ($issue in $issues) {
                Write-Host "  [!] $issue" -ForegroundColor Red
            }
        } else {
            Write-Host "  No obvious issues detected" -ForegroundColor Green
        }
        Write-Host ""

    } else {
        Write-Host "No log files found in $logDir" -ForegroundColor Red
    }
} else {
    Write-Host "Log directory not found: $logDir" -ForegroundColor Red
}

# 2. Check for other debug logs
Write-Host "=== Other Debug Logs ===" -ForegroundColor Yellow
$debugLogs = @(
    "/tmp/pmc-edit-debug.log"
    "/tmp/pmc-colors-debug.log"
    "/tmp/pmc-list-render-error.log"
)

foreach ($log in $debugLogs) {
    if (Test-Path $log) {
        $size = (Get-Item $log).Length
        Write-Host "  Found: $log ($(([math]::Round($size / 1KB, 2))) KB)" -ForegroundColor Green
        Write-Host "    Last 5 lines:" -ForegroundColor Gray
        Get-Content $log -Tail 5 | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
    }
}
Write-Host ""

# 3. Terminal info
Write-Host "=== Terminal Info ===" -ForegroundColor Yellow
try {
    Write-Host "  Width: $([Console]::WindowWidth)" -ForegroundColor Green
    Write-Host "  Height: $([Console]::WindowHeight)" -ForegroundColor Green
    Write-Host "  Encoding: $([Console]::OutputEncoding.EncodingName)" -ForegroundColor Green
    Write-Host "  LANG: $($env:LANG)" -ForegroundColor Green
} catch {
    Write-Host "  Could not read terminal info: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== Debug State Dump Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "To run TUI with debugging: pwsh Start-PmcTUI.ps1" -ForegroundColor Yellow
Write-Host "To view live logs: tail -f $logDir/pmc-tui-*.log" -ForegroundColor Yellow
