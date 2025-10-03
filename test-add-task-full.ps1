#!/usr/bin/env pwsh

# Load PMC
Import-Module ./module/Pmc.Strict -Force

Write-Host "Testing add task with 'test'..." -ForegroundColor Cyan

try {
    $data = Get-PmcAllData
    Write-Host "✓ Got data, tasks count: $($data.tasks.Count)" -ForegroundColor Green

    $newId = if ($data.tasks.Count -gt 0) {
        ($data.tasks | ForEach-Object { [int]$_.id } | Measure-Object -Maximum).Maximum + 1
    } else { 1 }
    Write-Host "✓ New ID will be: $newId" -ForegroundColor Green

    $newTask = [PSCustomObject]@{
        id = $newId
        text = "test"
        status = 'active'
        priority = 'medium'
        project = 'inbox'
        due = $null
        created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }
    Write-Host "✓ Created task object" -ForegroundColor Green

    $data.tasks += $newTask
    Write-Host "✓ Added to tasks array" -ForegroundColor Green

    Save-PmcData -Data $data -Action "Added task $newId"
    Write-Host "✓ Saved successfully!" -ForegroundColor Green

    Write-Host "`n✓ Task 'test' added successfully!" -ForegroundColor Green

} catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
