#!/usr/bin/env pwsh
# Test PMC Data Loading Issue

Set-StrictMode -Version Latest

Write-Host "=== PMC Data Loading Debug ===" -ForegroundColor Yellow

# Import module
Get-Module Pmc.Strict | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module ./module/Pmc.Strict -Force -DisableNameChecking | Out-Null

Write-Host "Module loaded successfully" -ForegroundColor Green

# Check task file path
Write-Host "`nTesting task file path..." -ForegroundColor Yellow
try {
    $taskPath = Get-PmcTaskFilePath
    Write-Host "Task file path: $taskPath" -ForegroundColor Gray

    if (Test-Path $taskPath) {
        $fileInfo = Get-Item $taskPath
        Write-Host "File exists: $($fileInfo.Length) bytes" -ForegroundColor Green

        # Try to read the file directly
        $content = Get-Content $taskPath -Raw -ErrorAction SilentlyContinue
        if ($content) {
            Write-Host "File content length: $($content.Length) characters" -ForegroundColor Gray

            # Try to parse JSON
            try {
                $jsonData = $content | ConvertFrom-Json
                Write-Host "JSON parsed successfully" -ForegroundColor Green
                Write-Host "Task count: $($jsonData.tasks.Count)" -ForegroundColor Gray
                Write-Host "Project count: $($jsonData.projects.Count)" -ForegroundColor Gray
            } catch {
                Write-Host "JSON parsing failed: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "File is empty or unreadable" -ForegroundColor Red
        }
    } else {
        Write-Host "File does not exist - will be created" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Task file path failed: $_" -ForegroundColor Red
}

# Test data loading with timeout
Write-Host "`nTesting data loading with timeout..." -ForegroundColor Yellow
$job = Start-Job -ScriptBlock {
    Import-Module $using:PWD/module/Pmc.Strict -Force -DisableNameChecking
    Get-PmcAllData
}

$timeout = 10 # seconds
$result = Wait-Job $job -Timeout $timeout

if ($result) {
    $data = Receive-Job $job
    Remove-Job $job

    if ($data) {
        Write-Host "✓ Data loaded successfully" -ForegroundColor Green
        Write-Host "Task count: $(if ($data.tasks) { $data.tasks.Count } else { 0 })" -ForegroundColor Gray
        Write-Host "Project count: $(if ($data.projects) { $data.projects.Count } else { 0 })" -ForegroundColor Gray
    } else {
        Write-Host "✗ Data loading returned null" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Data loading timed out after $timeout seconds" -ForegroundColor Red
    Stop-Job $job -ErrorAction SilentlyContinue
    Remove-Job $job -ErrorAction SilentlyContinue
}

Write-Host "`n=== Debug Complete ===" -ForegroundColor Green