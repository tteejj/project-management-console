#!/usr/bin/env pwsh
# PMC CRUD Operations Test
# Tests core task, project, and time management functionality

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "=== PMC CRUD Operations Test ===" -ForegroundColor Green

# Import module
Get-Module Pmc.Strict | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module ./module/Pmc.Strict -Force -DisableNameChecking

$testResults = @()

function Add-TestResult {
    param($Name, $Status, $Details = "", $Error = "")
    $testResults += [PSCustomObject]@{
        Test = $Name
        Status = $Status
        Details = $Details
        Error = $Error
        Timestamp = Get-Date
    }
}

try {
    # Get initial state
    $initialData = Get-PmcAllData
    $initialTaskCount = if ($initialData.tasks) { $initialData.tasks.Count } else { 0 }
    $initialProjectCount = if ($initialData.projects) { $initialData.projects.Count } else { 0 }

    Write-Host "Initial state: $initialTaskCount tasks, $initialProjectCount projects" -ForegroundColor Gray

    # Test 1: Add Task
    Write-Host "`n1. Testing Add-PmcTask..." -ForegroundColor Yellow
    try {
        # Create a test context for adding a task
        $context = [PSCustomObject]@{
            FreeText = @("Test task from automated testing")
            Args = @{}
        }

        # Add task
        $output = Add-PmcTask -Context $context 2>&1

        # Verify task was added
        $newData = Get-PmcAllData
        $newTaskCount = if ($newData.tasks) { $newData.tasks.Count } else { 0 }

        if ($newTaskCount -gt $initialTaskCount) {
            $addedTask = $newData.tasks | Where-Object { $_.text -eq "Test task from automated testing" } | Select-Object -First 1
            if ($addedTask) {
                Add-TestResult -Name "Add Task" -Status "PASS" -Details "Task added successfully, ID: $($addedTask.id)"
                Write-Host "✓ Task added: ID $($addedTask.id)" -ForegroundColor Green
            } else {
                Add-TestResult -Name "Add Task" -Status "FAIL" -Details "Task count increased but task not found"
                Write-Host "✗ Task added but not found" -ForegroundColor Red
            }
        } else {
            Add-TestResult -Name "Add Task" -Status "FAIL" -Details "Task count did not increase"
            Write-Host "✗ Task was not added" -ForegroundColor Red
        }
    } catch {
        Add-TestResult -Name "Add Task" -Status "FAIL" -Error $_.ToString()
        Write-Host "✗ Add task failed: $_" -ForegroundColor Red
    }

    # Test 2: List Tasks
    Write-Host "`n2. Testing Get-PmcTaskList..." -ForegroundColor Yellow
    try {
        $context = [PSCustomObject]@{
            FreeText = @()
            Args = @{}
        }

        # Capture the output (it goes to console)
        $output = Get-PmcTaskList -Context $context 2>&1

        # Verify we can get tasks
        $data = Get-PmcAllData
        $activeTasks = $data.tasks | Where-Object { -not $_.completed }

        Add-TestResult -Name "List Tasks" -Status "PASS" -Details "Listed $($activeTasks.Count) active tasks"
        Write-Host "✓ Listed $($activeTasks.Count) active tasks" -ForegroundColor Green
    } catch {
        Add-TestResult -Name "List Tasks" -Status "FAIL" -Error $_.ToString()
        Write-Host "✗ List tasks failed: $_" -ForegroundColor Red
    }

    # Test 3: Update Task
    Write-Host "`n3. Testing Set-PmcTask..." -ForegroundColor Yellow
    try {
        $data = Get-PmcAllData
        $testTask = $data.tasks | Where-Object { $_.text -eq "Test task from automated testing" } | Select-Object -First 1

        if ($testTask) {
            $context = [PSCustomObject]@{
                FreeText = @($testTask.id.ToString(), "priority", "2")
                Args = @{}
            }

            $output = Set-PmcTask -Context $context 2>&1

            # Verify update
            $updatedData = Get-PmcAllData
            $updatedTask = $updatedData.tasks | Where-Object { $_.id -eq $testTask.id }

            if ($updatedTask -and $updatedTask.priority -eq 2) {
                Add-TestResult -Name "Update Task" -Status "PASS" -Details "Task priority updated to 2"
                Write-Host "✓ Task priority updated" -ForegroundColor Green
            } else {
                Add-TestResult -Name "Update Task" -Status "FAIL" -Details "Priority not updated"
                Write-Host "✗ Task priority not updated" -ForegroundColor Red
            }
        } else {
            Add-TestResult -Name "Update Task" -Status "SKIP" -Details "No test task found to update"
            Write-Host "⚠ No test task found to update" -ForegroundColor Yellow
        }
    } catch {
        Add-TestResult -Name "Update Task" -Status "FAIL" -Error $_.ToString()
        Write-Host "✗ Update task failed: $_" -ForegroundColor Red
    }

    # Test 4: Complete Task
    Write-Host "`n4. Testing Complete-PmcTask..." -ForegroundColor Yellow
    try {
        $data = Get-PmcAllData
        $testTask = $data.tasks | Where-Object { $_.text -eq "Test task from automated testing" } | Select-Object -First 1

        if ($testTask) {
            $context = [PSCustomObject]@{
                FreeText = @($testTask.id.ToString())
                Args = @{}
            }

            $output = Complete-PmcTask -Context $context 2>&1

            # Verify completion
            $updatedData = Get-PmcAllData
            $completedTask = $updatedData.tasks | Where-Object { $_.id -eq $testTask.id }

            if ($completedTask -and $completedTask.completed -eq $true) {
                Add-TestResult -Name "Complete Task" -Status "PASS" -Details "Task marked as completed"
                Write-Host "✓ Task marked as completed" -ForegroundColor Green
            } else {
                Add-TestResult -Name "Complete Task" -Status "FAIL" -Details "Task not marked as completed"
                Write-Host "✗ Task not marked as completed" -ForegroundColor Red
            }
        } else {
            Add-TestResult -Name "Complete Task" -Status "SKIP" -Details "No test task found to complete"
            Write-Host "⚠ No test task found to complete" -ForegroundColor Yellow
        }
    } catch {
        Add-TestResult -Name "Complete Task" -Status "FAIL" -Error $_.ToString()
        Write-Host "✗ Complete task failed: $_" -ForegroundColor Red
    }

    # Test 5: Remove Task (cleanup)
    Write-Host "`n5. Testing Remove-PmcTask..." -ForegroundColor Yellow
    try {
        $data = Get-PmcAllData
        $testTask = $data.tasks | Where-Object { $_.text -eq "Test task from automated testing" } | Select-Object -First 1

        if ($testTask) {
            $context = [PSCustomObject]@{
                FreeText = @($testTask.id.ToString())
                Args = @{}
            }

            $output = Remove-PmcTask -Context $context 2>&1

            # Verify removal
            $updatedData = Get-PmcAllData
            $removedTask = $updatedData.tasks | Where-Object { $_.id -eq $testTask.id }
            $deletedTask = $updatedData.deleted | Where-Object { $_.id -eq $testTask.id }

            if (-not $removedTask -and $deletedTask) {
                Add-TestResult -Name "Remove Task" -Status "PASS" -Details "Task moved to deleted"
                Write-Host "✓ Task moved to deleted" -ForegroundColor Green
            } else {
                Add-TestResult -Name "Remove Task" -Status "FAIL" -Details "Task not properly deleted"
                Write-Host "✗ Task not properly deleted" -ForegroundColor Red
            }
        } else {
            Add-TestResult -Name "Remove Task" -Status "SKIP" -Details "No test task found to remove"
            Write-Host "⚠ No test task found to remove" -ForegroundColor Yellow
        }
    } catch {
        Add-TestResult -Name "Remove Task" -Status "FAIL" -Error $_.ToString()
        Write-Host "✗ Remove task failed: $_" -ForegroundColor Red
    }

    # Test 6: Data Persistence
    Write-Host "`n6. Testing data persistence..." -ForegroundColor Yellow
    try {
        $dataPath = Get-PmcTaskFilePath
        $fileExists = Test-Path $dataPath

        if ($fileExists) {
            $fileInfo = Get-Item $dataPath
            $fileSize = $fileInfo.Length

            Add-TestResult -Name "Data Persistence" -Status "PASS" -Details "Data file exists: $dataPath ($fileSize bytes)"
            Write-Host "✓ Data file exists: $fileSize bytes" -ForegroundColor Green
        } else {
            Add-TestResult -Name "Data Persistence" -Status "FAIL" -Details "Data file not found: $dataPath"
            Write-Host "✗ Data file not found" -ForegroundColor Red
        }
    } catch {
        Add-TestResult -Name "Data Persistence" -Status "FAIL" -Error $_.ToString()
        Write-Host "✗ Data persistence test failed: $_" -ForegroundColor Red
    }

} catch {
    Add-TestResult -Name "CRUD Operations" -Status "FAIL" -Error $_.ToString()
    Write-Host "✗ CRITICAL: CRUD operations failed: $_" -ForegroundColor Red
}

# Test Results Summary
Write-Host "`n=== CRUD OPERATIONS TEST RESULTS ===" -ForegroundColor Green
$passCount = ($testResults | Where-Object Status -eq "PASS").Count
$warnCount = ($testResults | Where-Object Status -eq "WARN").Count
$skipCount = ($testResults | Where-Object Status -eq "SKIP").Count
$failCount = ($testResults | Where-Object Status -eq "FAIL").Count

Write-Host "PASSED: $passCount" -ForegroundColor Green
Write-Host "SKIPPED: $skipCount" -ForegroundColor Yellow
Write-Host "WARNED: $warnCount" -ForegroundColor Yellow
Write-Host "FAILED: $failCount" -ForegroundColor Red

Write-Host "`nDetailed Results:" -ForegroundColor Gray
$testResults | ForEach-Object {
    $color = switch ($_.Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "SKIP" { "Yellow" }
        "FAIL" { "Red" }
    }
    Write-Host "[$($_.Status)] $($_.Test): $($_.Details)" -ForegroundColor $color
    if ($_.Error) {
        Write-Host "  Error: $($_.Error)" -ForegroundColor Red
    }
}

# Overall result
if ($failCount -eq 0) {
    Write-Host "`n🎉 CRUD OPERATIONS TEST PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n💥 CRUD OPERATIONS TEST FAILED" -ForegroundColor Red
    exit 1
}