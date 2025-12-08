# Fix all screens missing parent HandleKeyPress call
# This script adds the critical parent delegation pattern to all affected screens

Set-StrictMode -Version Latest

$screens = @(
    "DepAddFormScreen.ps1"
    "DepRemoveFormScreen.ps1"
    "DepShowFormScreen.ps1"
    "FocusClearScreen.ps1"
    "BurndownChartScreen.ps1"
    "KanbanScreen.ps1"
    "MultiSelectModeScreen.ps1"
    "ProjectInfoScreen.ps1"
    "ProjectStatsScreen.ps1"
    "TimeDeleteFormScreen.ps1"
    "TimeListScreen.ps1"
    "TimerStartScreen.ps1"
    "WeeklyTimeReportScreen.ps1"
    "FocusStatusScreen.ps1"
    "HelpViewScreen.ps1"
    "TimeReportScreen.ps1"
    "TimerStatusScreen.ps1"
    "TimerStopScreen.ps1"
    "BackupViewScreen.ps1"
    "BlockedTasksScreen.ps1"
    "ChecklistEditorScreen.ps1"
    "ClearBackupsScreen.ps1"
    "CommandLibraryScreen.ps1"
    "RedoViewScreen.ps1"
    "RestoreBackupScreen.ps1"
    "UndoViewScreen.ps1"
)

$fix = @"
        # CRITICAL: Call parent FIRST for MenuBar, F10, Alt+keys, content widgets
        `$handled = ([PmcScreen]`$this).HandleKeyPress(`$keyInfo)
        if (`$handled) { return `$true }

"@

$count = 0
$skipped = 0

foreach ($screen in $screens) {
    $path = Join-Path "screens" $screen

    if (-not (Test-Path $path)) {
        Write-Host "SKIP: $screen (not found)" -ForegroundColor Yellow
        $skipped++
        continue
    }

    $content = Get-Content $path -Raw

    # Check if already fixed
    if ($content -match 'Call parent FIRST for MenuBar') {
        Write-Host "SKIP: $screen (already fixed)" -ForegroundColor Green
        $skipped++
        continue
    }

    # Find HandleKeyPress and add parent call after method signature
    if ($content -match '(?s)(\[bool\] HandleKeyPress\([^\)]+\)\s*\{)(\s*)') {
        $newContent = $content -replace '(?s)(\[bool\] HandleKeyPress\([^\)]+\)\s*\{)(\s*)', "`$1`n$fix`$2"
        Set-Content $path -Value $newContent -NoNewline
        Write-Host "FIXED: $screen" -ForegroundColor Cyan
        $count++
    } else {
        Write-Host "WARN: $screen (no HandleKeyPress found)" -ForegroundColor Magenta
    }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor White
Write-Host "Fixed: $count" -ForegroundColor Cyan
Write-Host "Skipped: $skipped" -ForegroundColor Yellow
Write-Host "Total: $($screens.Count)" -ForegroundColor White
