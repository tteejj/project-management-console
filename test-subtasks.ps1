# Test subtasks functionality
Import-Module ./module/Pmc.Strict/Pmc.Strict.psd1 -Force

$data = Get-PmcAllData

# Find a test task
$testTask = $data.tasks | Select-Object -First 1

if ($testTask) {
    # Add subtasks property if it doesn't exist
    if (-not $testTask.PSObject.Properties['subtasks']) {
        $testTask | Add-Member -MemberType NoteProperty -Name 'subtasks' -Value @()
    }

    # Add test subtasks
    $testTask.subtasks = @(
        [PSCustomObject]@{
            text = "First subtask"
            completed = $false
            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
        [PSCustomObject]@{
            text = "Second subtask"
            completed = $true
            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
        [PSCustomObject]@{
            text = "Third subtask"
            completed = $false
            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
    )

    Save-PmcData -Data $data -Action "Added test subtasks"

    Write-Host "✓ Added 3 test subtasks to task #$($testTask.id)" -ForegroundColor Green
    Write-Host "  Task: $($testTask.text)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Subtasks:" -ForegroundColor Yellow
    foreach ($sub in $testTask.subtasks) {
        $status = if ($sub.completed) { "[✓]" } else { "[ ]" }
        Write-Host "  $status $($sub.text)" -ForegroundColor White
    }
} else {
    Write-Host "No tasks found for testing" -ForegroundColor Red
}
