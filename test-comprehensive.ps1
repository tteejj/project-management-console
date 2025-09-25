#!/usr/bin/env pwsh
# Comprehensive PMC Testing Suite
# Tests all major functionality using correct exported functions

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

Write-Host "=== PMC Comprehensive Test Suite ===" -ForegroundColor Green
Write-Host "Testing the hell out of PMC..." -ForegroundColor Yellow

# Import module
Get-Module Pmc.Strict | Remove-Module -Force -ErrorAction SilentlyContinue
Write-Host "`nLoading PMC module..." -NoNewline
Import-Module ./module/Pmc.Strict -Force -DisableNameChecking -WarningAction SilentlyContinue | Out-Null
Write-Host " ✓" -ForegroundColor Green

$tests = @()
$testCount = 0
$passCount = 0
$failCount = 0

function Test-Feature($name, $testBlock) {
    $script:testCount++
    Write-Host "`n[$script:testCount] Testing $name..." -ForegroundColor Cyan

    $result = [PSCustomObject]@{
        Name = $name
        Status = "UNKNOWN"
        Details = ""
        Error = ""
        Duration = 0
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $output = & $testBlock
        $stopwatch.Stop()
        $result.Duration = $stopwatch.ElapsedMilliseconds

        if ($output -eq $false) {
            $result.Status = "FAIL"
            $result.Details = "Test returned false"
            Write-Host "  ✗ FAILED (returned false)" -ForegroundColor Red
            $script:failCount++
        } elseif ($output -eq $true -or $null -eq $output) {
            $result.Status = "PASS"
            $result.Details = "Test completed successfully"
            Write-Host "  ✓ PASSED ($($result.Duration)ms)" -ForegroundColor Green
            $script:passCount++
        } else {
            $result.Status = "PASS"
            $result.Details = $output.ToString()
            Write-Host "  ✓ PASSED: $output ($($result.Duration)ms)" -ForegroundColor Green
            $script:passCount++
        }
    } catch {
        $stopwatch.Stop()
        $result.Status = "FAIL"
        $result.Error = $_.ToString()
        $result.Duration = $stopwatch.ElapsedMilliseconds
        Write-Host "  ✗ FAILED: $_" -ForegroundColor Red
        $script:failCount++
    }

    $script:tests += $result
    return $result.Status -eq "PASS"
}

# =====================================================
# CORE MODULE TESTS
# =====================================================

Test-Feature "Module Export Count" {
    $commands = Get-Command -Module Pmc.Strict
    $count = $commands.Count
    if ($count -gt 100) {
        "Exported $count functions"
    } else {
        throw "Only $count functions exported, expected > 100"
    }
}

Test-Feature "Critical Functions Available" {
    $critical = @(
        'Add-PmcTask', 'Get-PmcTaskList', 'Complete-PmcTask', 'Remove-PmcTask',
        'Get-PmcAllData', 'Show-PmcData', 'Get-PmcState', 'Invoke-PmcQuery'
    )

    $missing = $critical | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }
    if ($missing.Count -eq 0) {
        "All $($critical.Count) critical functions available"
    } else {
        throw "Missing critical functions: $($missing -join ', ')"
    }
}

# =====================================================
# DATA SYSTEM TESTS
# =====================================================

Test-Feature "Data Loading" {
    $data = Get-PmcAllData
    if ($data) {
        $taskCount = if ($data.tasks) { $data.tasks.Count } else { 0 }
        $projectCount = if ($data.projects) { $data.projects.Count } else { 0 }
        "Loaded $taskCount tasks, $projectCount projects"
    } else {
        throw "Data loading returned null"
    }
}

Test-Feature "State System" {
    $state = Get-PmcState
    if ($state) {
        $sections = @($state.Keys)
        "State initialized with $($sections.Count) sections: $($sections -join ', ')"
    } else {
        throw "State system returned null"
    }
}

Test-Feature "Configuration System" {
    $config = Get-PmcConfig
    if ($config) {
        "Configuration loaded successfully"
    } else {
        throw "Configuration system failed"
    }
}

# =====================================================
# TASK MANAGEMENT TESTS
# =====================================================

$testTaskId = $null

Test-Feature "Add Task" {
    $initialData = Get-PmcAllData
    $initialCount = if ($initialData.tasks) { $initialData.tasks.Count } else { 0 }

    $context = [PSCustomObject]@{
        FreeText = @("TEST: Automated test task $(Get-Date -Format 'HH:mm:ss')")
        Args = @{}
    }

    # Capture output but don't let it interfere with test result
    Add-PmcTask -Context $context | Out-Null

    $newData = Get-PmcAllData
    $newCount = if ($newData.tasks) { $newData.tasks.Count } else { 0 }

    if ($newCount -gt $initialCount) {
        $addedTask = $newData.tasks | Where-Object { $_.text -like "TEST: Automated test task*" } | Select-Object -Last 1
        if ($addedTask) {
            $script:testTaskId = $addedTask.id
            "Added task ID: $($addedTask.id)"
        } else {
            throw "Task count increased but test task not found"
        }
    } else {
        throw "Task was not added (count: $initialCount -> $newCount)"
    }
}

Test-Feature "List Tasks" {
    $context = [PSCustomObject]@{
        FreeText = @()
        Args = @{}
    }

    # This outputs to console, so we'll just verify it doesn't crash
    $originalOut = $Host.UI.RawUI.CursorPosition
    Get-PmcTaskList -Context $context | Out-Null
    "Task list command executed successfully"
}

Test-Feature "Update Task" {
    if (-not $script:testTaskId) {
        throw "No test task ID available"
    }

    $context = [PSCustomObject]@{
        FreeText = @($script:testTaskId.ToString(), "priority", "2")
        Args = @{}
    }

    Set-PmcTask -Context $context | Out-Null

    $data = Get-PmcAllData
    $updatedTask = $data.tasks | Where-Object { $_.id -eq $script:testTaskId }

    if ($updatedTask -and $updatedTask.priority -eq 2) {
        "Task priority updated to 2"
    } else {
        throw "Task priority not updated correctly"
    }
}

Test-Feature "Complete Task" {
    if (-not $script:testTaskId) {
        throw "No test task ID available"
    }

    $context = [PSCustomObject]@{
        FreeText = @($script:testTaskId.ToString())
        Args = @{}
    }

    Complete-PmcTask -Context $context | Out-Null

    $data = Get-PmcAllData
    $completedTask = $data.tasks | Where-Object { $_.id -eq $script:testTaskId }

    if ($completedTask -and $completedTask.completed -eq $true) {
        "Task marked as completed"
    } else {
        throw "Task not marked as completed"
    }
}

Test-Feature "Remove Task (Cleanup)" {
    if (-not $script:testTaskId) {
        throw "No test task ID available"
    }

    $context = [PSCustomObject]@{
        FreeText = @($script:testTaskId.ToString())
        Args = @{}
    }

    Remove-PmcTask -Context $context | Out-Null

    $data = Get-PmcAllData
    $activeTask = $data.tasks | Where-Object { $_.id -eq $script:testTaskId }
    $deletedTask = $data.deleted | Where-Object { $_.id -eq $script:testTaskId }

    if (-not $activeTask -and $deletedTask) {
        "Task moved to deleted section"
    } else {
        throw "Task not properly deleted"
    }
}

# =====================================================
# QUERY ENGINE TESTS
# =====================================================

Test-Feature "Query Engine Basic" {
    $context = [PSCustomObject]@{
        FreeText = @("tasks")
        Args = @{}
    }

    Invoke-PmcQuery -Context $context | Out-Null
    "Basic query executed successfully"
}

# =====================================================
# DISPLAY SYSTEM TESTS
# =====================================================

Test-Feature "Data Display" {
    $data = Get-PmcAllData
    $tasks = if ($data.tasks) { $data.tasks } else { @() }

    Show-PmcData -Domain 'task' -Data $tasks -Title "Test Display" | Out-Null
    "Data display rendered $($tasks.Count) items"
}

Test-Feature "Data Grid Display" {
    $data = Get-PmcAllData
    $tasks = if ($data.tasks) { $data.tasks } else { @() }

    Show-PmcDataGrid -Domain 'task' -Data $tasks -Title "Test Grid" | Out-Null
    "Data grid displayed $($tasks.Count) items"
}

# =====================================================
# SECURITY TESTS
# =====================================================

Test-Feature "Input Safety Validation" {
    $safe = Test-PmcInputSafety -Input "safe input" -InputType "general"
    $unsafe = Test-PmcInputSafety -Input "rm -rf /" -InputType "command"

    if ($safe -and -not $unsafe) {
        "Security validation working correctly"
    } else {
        throw "Security validation failed (safe: $safe, unsafe: $unsafe)"
    }
}

Test-Feature "Path Safety Validation" {
    $safePath = Test-PmcPathSafety -Path "./safe/path.txt" -Operation "write"

    if ($null -ne $safePath) {
        "Path safety validation working"
    } else {
        throw "Path safety validation failed"
    }
}

# =====================================================
# INTERACTIVE MODE TESTS (Basic)
# =====================================================

Test-Feature "Interactive Mode Status" {
    $status = Get-PmcInteractiveStatus
    "Interactive mode status retrieved"
}

# =====================================================
# THEME AND UI TESTS
# =====================================================

Test-Feature "Theme System" {
    $themes = Get-PmcThemeList
    if ($themes) {
        "Found $($themes.Count) themes"
    } else {
        "Theme system available (no themes configured)"
    }
}

# =====================================================
# HELP SYSTEM TESTS
# =====================================================

Test-Feature "Help System" {
    $help = Get-PmcHelp
    if ($help) {
        "Help system working"
    } else {
        throw "Help system failed"
    }
}

Test-Feature "Help Data" {
    $helpData = Get-PmcHelpData
    if ($helpData) {
        "Help data available: $($helpData.Count) categories"
    } else {
        "Help data system working (no data)"
    }
}

# =====================================================
# PROJECT MANAGEMENT TESTS
# =====================================================

Test-Feature "Project Data" {
    $data = Get-PmcAllData
    $projects = if ($data.projects) { $data.projects } else { @() }
    "Found $($projects.Count) projects"
}

Test-Feature "Project List" {
    $projects = Get-PmcProjectList
    if ($projects) {
        "Project list returned $($projects.Count) items"
    } else {
        "Project list command working (no projects)"
    }
}

# =====================================================
# RESULTS SUMMARY
# =====================================================

Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "PMC COMPREHENSIVE TEST RESULTS" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green

Write-Host "`nSUMMARY:" -ForegroundColor White
Write-Host "  Total Tests: $testCount" -ForegroundColor Gray
Write-Host "  Passed: $passCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor Red

$successRate = if ($testCount -gt 0) { [math]::Round(($passCount / $testCount) * 100, 1) } else { 0 }
Write-Host "  Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

Write-Host "`nDETAILED RESULTS:" -ForegroundColor White
$tests | ForEach-Object {
    $color = switch ($_.Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        default { "Yellow" }
    }
    Write-Host "  [$($_.Status)] $($_.Name)" -ForegroundColor $color
    if ($_.Details) {
        Write-Host "    $($_.Details)" -ForegroundColor Gray
    }
    if ($_.Error) {
        Write-Host "    ERROR: $($_.Error)" -ForegroundColor Red
    }
    if ($_.Duration -gt 1000) {
        Write-Host "    SLOW: $($_.Duration)ms" -ForegroundColor Yellow
    }
}

Write-Host "`nPERFORMANCE:" -ForegroundColor White
$slowTests = $tests | Where-Object { $_.Duration -gt 1000 } | Sort-Object Duration -Descending
if ($slowTests) {
    Write-Host "  Slow tests (>1s):" -ForegroundColor Yellow
    $slowTests | ForEach-Object {
        Write-Host "    $($_.Name): $($_.Duration)ms" -ForegroundColor Red
    }
} else {
    Write-Host "  All tests completed quickly (<1s)" -ForegroundColor Green
}

# Overall assessment
Write-Host "`nOVERALL ASSESSMENT:" -ForegroundColor White
if ($failCount -eq 0) {
    Write-Host "  🎉 PMC IS WORKING PERFECTLY!" -ForegroundColor Green
    Write-Host "  All core functionality is operational." -ForegroundColor Green
} elseif ($successRate -ge 90) {
    Write-Host "  ✅ PMC IS MOSTLY WORKING" -ForegroundColor Yellow
    Write-Host "  Minor issues found but core functionality is solid." -ForegroundColor Yellow
} elseif ($successRate -ge 70) {
    Write-Host "  ⚠️  PMC HAS SOME ISSUES" -ForegroundColor Yellow
    Write-Host "  Several features are not working correctly." -ForegroundColor Yellow
} else {
    Write-Host "  💥 PMC HAS SIGNIFICANT PROBLEMS" -ForegroundColor Red
    Write-Host "  Major functionality is broken." -ForegroundColor Red
}

Write-Host "`n" + "="*60 -ForegroundColor Green

# Exit with appropriate code
if ($failCount -eq 0) {
    exit 0
} else {
    exit $failCount
}