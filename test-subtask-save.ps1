# Direct test of subtask save logic
Import-Module ./module/Pmc.Strict/Pmc.Strict.psd1 -Force

Write-Host "Loading data..." -ForegroundColor Cyan
$data = Get-PmcAllData

Write-Host "Tasks available:" -ForegroundColor Yellow
$data.tasks | ForEach-Object { Write-Host "  Task #$($_.id): $($_.text)" }

Write-Host "`nTrying to add subtask to task #2..." -ForegroundColor Cyan
$dataTask = $data.tasks | Where-Object { $_.id -eq 2 }

if ($dataTask) {
    Write-Host "Found task #2: $($dataTask.text)" -ForegroundColor Green

    $newSubtask = [PSCustomObject]@{
        text = "Test subtask from script"
        completed = $false
        created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }

    # Add subtask property
    if (-not $dataTask.PSObject.Properties['subtasks']) {
        Write-Host "Adding subtasks property..." -ForegroundColor Yellow
        $dataTask | Add-Member -MemberType NoteProperty -Name 'subtasks' -Value @($newSubtask) -Force
    } else {
        Write-Host "Appending to existing subtasks..." -ForegroundColor Yellow
        $updatedSubtasks = @($dataTask.subtasks) + @($newSubtask)
        $dataTask.subtasks = $updatedSubtasks
    }

    Write-Host "Task now has $(@($dataTask.subtasks).Count) subtasks" -ForegroundColor Green
    Write-Host "Saving..." -ForegroundColor Cyan

    Save-PmcData -Data $data -Action "Test: Added subtask to task #2"

    Write-Host "`nVerifying save..." -ForegroundColor Cyan
    $reloadedData = Get-PmcAllData
    $reloadedTask = $reloadedData.tasks | Where-Object { $_.id -eq 2 }

    if ($reloadedTask.PSObject.Properties['subtasks']) {
        Write-Host "✓ Subtasks property exists!" -ForegroundColor Green
        Write-Host "  Count: $(@($reloadedTask.subtasks).Count)" -ForegroundColor Cyan
        foreach ($sub in $reloadedTask.subtasks) {
            Write-Host "  - $($sub.text)" -ForegroundColor White
        }
    } else {
        Write-Host "✗ Subtasks property NOT FOUND after save!" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Task #2 not found!" -ForegroundColor Red
}
