# TestValidationHelper.ps1 - Comprehensive tests for ValidationHelper
#
# Tests all validation functions with:
# - Valid cases
# - Invalid cases (missing fields, wrong types, out of range)
# - Edge cases (null, empty, boundary values)
# - Custom validators
# - Schema validation
#
# Usage:
#   . "$PSScriptRoot/../helpers/ValidationHelper.ps1"
#   . "$PSScriptRoot/TestValidationHelper.ps1"
#   Test-ValidationHelper

# Load ValidationHelper
$helpersPath = Join-Path (Split-Path -Parent $PSScriptRoot) "helpers"
. (Join-Path $helpersPath "ValidationHelper.ps1")

<#
.SYNOPSIS
Run all validation helper tests

.DESCRIPTION
Executes comprehensive test suite for ValidationHelper functions

.OUTPUTS
Test results summary
#>
function Test-ValidationHelper {
    Write-Host "=== ValidationHelper Test Suite ===" -ForegroundColor Cyan
    Write-Host ""

    $totalTests = 0
    $passedTests = 0
    $failedTests = 0

    # Test-TaskValid
    Write-Host "Testing Test-TaskValid..." -ForegroundColor Yellow

    # Valid task - minimal
    $result = Test-TaskValid @{ text = 'Buy milk' }
    $totalTests++
    if ($result.IsValid) {
        $passedTests++
        Write-Host "  [PASS] Valid task (minimal)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Valid task (minimal): $($result.Errors -join ', ')" -ForegroundColor Red
    }

    # Valid task - full
    $result = Test-TaskValid @{
        text = 'Complete project'
        project = 'work'
        priority = 3
        due = (Get-Date).AddDays(7)
        tags = @('urgent', 'important')
        completed = $false
        status = 'in-progress'
    }
    $totalTests++
    if ($result.IsValid) {
        $passedTests++
        Write-Host "  [PASS] Valid task (full)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Valid task (full): $($result.Errors -join ', ')" -ForegroundColor Red
    }

    # Invalid task - missing text
    $result = Test-TaskValid @{ priority = 3 }
    $totalTests++
    if (-not $result.IsValid -and $result.Errors -match 'text.*required') {
        $passedTests++
        Write-Host "  [PASS] Invalid task (missing text)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid task (missing text)" -ForegroundColor Red
    }

    # Invalid task - priority out of range (too low)
    $result = Test-TaskValid @{ text = 'Test'; priority = -1 }
    $totalTests++
    if (-not $result.IsValid -and $result.Errors -match 'Priority.*between 0 and 5') {
        $passedTests++
        Write-Host "  [PASS] Invalid task (priority < 0)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid task (priority < 0)" -ForegroundColor Red
    }

    # Invalid task - priority out of range (too high)
    $result = Test-TaskValid @{ text = 'Test'; priority = 10 }
    $totalTests++
    if (-not $result.IsValid -and $result.Errors -match 'Priority.*between 0 and 5') {
        $passedTests++
        Write-Host "  [PASS] Invalid task (priority > 5)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid task (priority > 5)" -ForegroundColor Red
    }

    # Invalid task - wrong type (priority)
    $result = Test-TaskValid @{ text = 'Test'; priority = 'high' }
    $totalTests++
    if (-not $result.IsValid -and $result.Errors -match 'Priority.*integer') {
        $passedTests++
        Write-Host "  [PASS] Invalid task (priority wrong type)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid task (priority wrong type)" -ForegroundColor Red
    }

    # Invalid task - invalid status
    $result = Test-TaskValid @{ text = 'Test'; status = 'invalid-status' }
    $totalTests++
    if (-not $result.IsValid -and $result.Errors -match 'Status must be one of') {
        $passedTests++
        Write-Host "  [PASS] Invalid task (invalid status)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid task (invalid status)" -ForegroundColor Red
    }

    Write-Host ""

    # Test-ProjectValid
    Write-Host "Testing Test-ProjectValid..." -ForegroundColor Yellow

    # Valid project
    $result = Test-ProjectValid @{ name = 'MyProject'; description = 'Test project'; status = 'active' }
    $totalTests++
    if ($result.IsValid) {
        $passedTests++
        Write-Host "  [PASS] Valid project" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Valid project: $($result.Errors -join ', ')" -ForegroundColor Red
    }

    # Invalid project - missing name
    $result = Test-ProjectValid @{ description = 'No name' }
    $totalTests++
    if (-not $result.IsValid -and $result.Errors -match 'name.*required') {
        $passedTests++
        Write-Host "  [PASS] Invalid project (missing name)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid project (missing name)" -ForegroundColor Red
    }

    # Invalid project - duplicate name
    $existing = @(@{ name = 'ExistingProject' })
    $result = Test-ProjectValid @{ name = 'ExistingProject' } -existingProjects $existing
    $totalTests++
    if (-not $result.IsValid -and $result.Errors -match 'already exists') {
        $passedTests++
        Write-Host "  [PASS] Invalid project (duplicate name)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid project (duplicate name)" -ForegroundColor Red
    }

    # Invalid project - invalid status
    $result = Test-ProjectValid @{ name = 'Test'; status = 'invalid-status' }
    $totalTests++
    if (-not $result.IsValid -and $result.Errors -match 'Status must be one of') {
        $passedTests++
        Write-Host "  [PASS] Invalid project (invalid status)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid project (invalid status)" -ForegroundColor Red
    }

    Write-Host ""

    # Test-TimeLogValid
    Write-Host "Testing Test-TimeLogValid..." -ForegroundColor Yellow

    # Valid time log
    $result = Test-TimeLogValid @{ taskId = 'task-123'; duration = 30 }
    $totalTests++
    if ($result.IsValid) {
        $passedTests++
        Write-Host "  [PASS] Valid time log" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Valid time log: $($result.Errors -join ', ')" -ForegroundColor Red
    }

    # Invalid time log - missing taskId
    $result = Test-TimeLogValid @{ duration = 30 }
    $totalTests++
    if (-not $result.IsValid -and $result.Errors -match 'taskId.*required') {
        $passedTests++
        Write-Host "  [PASS] Invalid time log (missing taskId)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid time log (missing taskId)" -ForegroundColor Red
    }

    # Invalid time log - missing duration
    $result = Test-TimeLogValid @{ taskId = 'task-123' }
    $totalTests++
    if (-not $result.IsValid -and $result.Errors -match 'duration.*required') {
        $passedTests++
        Write-Host "  [PASS] Invalid time log (missing duration)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid time log (missing duration)" -ForegroundColor Red
    }

    # Invalid time log - negative duration
    $result = Test-TimeLogValid @{ taskId = 'task-123'; duration = -10 }
    $totalTests++
    if (-not $result.IsValid -and $result.Errors -match 'duration.*greater than 0') {
        $passedTests++
        Write-Host "  [PASS] Invalid time log (negative duration)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid time log (negative duration)" -ForegroundColor Red
    }

    # Invalid time log - task does not exist
    $taskExistsCheck = { param($taskId) return $false }
    $result = Test-TimeLogValid @{ taskId = 'nonexistent'; duration = 30 } -taskExists $taskExistsCheck
    $totalTests++
    if (-not $result.IsValid -and $result.Errors -match 'does not exist') {
        $passedTests++
        Write-Host "  [PASS] Invalid time log (task does not exist)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid time log (task does not exist)" -ForegroundColor Red
    }

    Write-Host ""

    # Get-ValidationErrors (schema-based validation)
    Write-Host "Testing Get-ValidationErrors..." -ForegroundColor Yellow

    # Valid data
    $schema = @{
        name = @{ Required = $true; Type = 'string'; MaxLength = 50 }
        age = @{ Required = $false; Type = 'int'; Min = 0; Max = 120 }
    }
    $errors = Get-ValidationErrors @{ name = 'John'; age = 30 } $schema
    $totalTests++
    if ($errors.Count -eq 0) {
        $passedTests++
        Write-Host "  [PASS] Valid data (schema)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Valid data (schema): $($errors -join ', ')" -ForegroundColor Red
    }

    # Invalid - required field missing
    $errors = Get-ValidationErrors @{ age = 30 } $schema
    $totalTests++
    if ($errors.Count -gt 0 -and $errors -match 'name.*required') {
        $passedTests++
        Write-Host "  [PASS] Invalid data (missing required field)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid data (missing required field)" -ForegroundColor Red
    }

    # Invalid - wrong type
    $errors = Get-ValidationErrors @{ name = 'John'; age = 'thirty' } $schema
    $totalTests++
    if ($errors.Count -gt 0 -and $errors -match 'age.*type') {
        $passedTests++
        Write-Host "  [PASS] Invalid data (wrong type)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid data (wrong type)" -ForegroundColor Red
    }

    # Invalid - value too large
    $errors = Get-ValidationErrors @{ name = 'John'; age = 150 } $schema
    $totalTests++
    if ($errors.Count -gt 0 -and $errors -match 'age.*at most') {
        $passedTests++
        Write-Host "  [PASS] Invalid data (value too large)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid data (value too large)" -ForegroundColor Red
    }

    # Invalid - string too long
    $errors = Get-ValidationErrors @{ name = 'A' * 100; age = 30 } $schema
    $totalTests++
    if ($errors.Count -gt 0 -and $errors -match 'name.*at most') {
        $passedTests++
        Write-Host "  [PASS] Invalid data (string too long)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Invalid data (string too long)" -ForegroundColor Red
    }

    # Custom validator
    $schema = @{
        email = @{
            Required = $true
            Type = 'string'
            Validator = { param($value) return $value -match '^[\w\.\-]+@[\w\.\-]+\.\w+$' }
        }
    }
    $errors = Get-ValidationErrors @{ email = 'invalid-email' } $schema
    $totalTests++
    if ($errors.Count -gt 0 -and $errors -match 'custom validation') {
        $passedTests++
        Write-Host "  [PASS] Custom validator (invalid)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Custom validator (invalid)" -ForegroundColor Red
    }

    $errors = Get-ValidationErrors @{ email = 'test@example.com' } $schema
    $totalTests++
    if ($errors.Count -eq 0) {
        $passedTests++
        Write-Host "  [PASS] Custom validator (valid)" -ForegroundColor Green
    } else {
        $failedTests++
        Write-Host "  [FAIL] Custom validator (valid): $($errors -join ', ')" -ForegroundColor Red
    }

    Write-Host ""

    # Summary
    Write-Host "=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "Total Tests:  $totalTests" -ForegroundColor White
    Write-Host "Passed:       $passedTests" -ForegroundColor Green
    Write-Host "Failed:       $failedTests" -ForegroundColor Red
    Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor $(if ($failedTests -eq 0) { 'Green' } else { 'Yellow' })
    Write-Host ""

    return @{
        Total = $totalTests
        Passed = $passedTests
        Failed = $failedTests
        SuccessRate = ($passedTests / $totalTests) * 100
    }
}

# Run tests if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Test-ValidationHelper
}
