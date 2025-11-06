#!/usr/bin/env pwsh

Import-Module /home/teej/pmc/module/Pmc.Strict/Pmc.Strict.psd1 -Force
. /home/teej/pmc/module/Pmc.Strict/consoleui/DepsLoader.ps1
. /home/teej/pmc/module/Pmc.Strict/consoleui/SpeedTUILoader.ps1
. /home/teej/pmc/module/Pmc.Strict/consoleui/PmcApplication.ps1
. /home/teej/pmc/module/Pmc.Strict/consoleui/PmcScreen.ps1
. /home/teej/pmc/module/Pmc.Strict/consoleui/screens/TaskListScreen.ps1

Write-Host "=== Testing Field Editing with FieldSchemas ==="

$app = [PmcApplication]::new()
$screen = [TaskListScreen]::new()
$screen.TermWidth = 80
$screen.TermHeight = 24
$screen.RenderEngine = $app.RenderEngine
$screen.LayoutManager = $app.LayoutManager

Write-Host "`n1. Loading tasks..."
$screen.LoadData()
Write-Host "   Tasks loaded: $($screen.Tasks.Count)"

if ($screen.Tasks.Count -gt 0) {
    $task = $screen.Tasks[0]
    Write-Host "`n2. Original task:"
    Write-Host "   ID: $($task.id)"
    Write-Host "   Text: $($task.text)"
    Write-Host "   Priority: $($task.priority)"
    Write-Host "   Due: $($task.due)"

    Write-Host "`n3. Testing due date with '+7' format..."
    try {
        $schema = Get-PmcFieldSchema -Domain 'task' -Field 'due'
        Write-Host "   Schema hint: $($schema.Hint)"

        $normalized = & $schema.Normalize '+7'
        Write-Host "   '+7' normalized to: $normalized"

        $display = & $schema.DisplayFormat $normalized
        Write-Host "   Display format: $display"
    } catch {
        Write-Host "   ERROR: $_"
    }

    Write-Host "`n4. Testing due date with 'yyyymmdd' format..."
    try {
        $normalized = & $schema.Normalize '20251115'
        Write-Host "   '20251115' normalized to: $normalized"

        $display = & $schema.DisplayFormat $normalized
        Write-Host "   Display format: $display"
    } catch {
        Write-Host "   ERROR: $_"
    }

    Write-Host "`n5. Testing priority with 'P2' format..."
    try {
        $schema = Get-PmcFieldSchema -Domain 'task' -Field 'priority'
        Write-Host "   Schema hint: $($schema.Hint)"

        $normalized = & $schema.Normalize 'P2'
        Write-Host "   'P2' normalized to: $normalized"

        $display = & $schema.DisplayFormat $normalized
        Write-Host "   Display format: $display"
    } catch {
        Write-Host "   ERROR: $_"
    }

    Write-Host "`n6. Testing _UpdateField with due date '+7'..."
    try {
        $screen._UpdateField('due', '+7')
        Write-Host "   Updated task due: $($screen.Tasks[0].due)"
    } catch {
        Write-Host "   ERROR: $_"
    }

    Write-Host "`n7. Testing _UpdateField with priority 'P2'..."
    try {
        $screen._UpdateField('priority', 'P2')
        Write-Host "   Updated task priority: $($screen.Tasks[0].priority)"
    } catch {
        Write-Host "   ERROR: $_"
    }

    Write-Host "`n8. Final task state:"
    $task = $screen.Tasks[0]
    Write-Host "   ID: $($task.id)"
    Write-Host "   Text: $($task.text)"
    Write-Host "   Priority: $($task.priority)"
    Write-Host "   Due: $($task.due)"
}

Write-Host "`n=== Test Complete ==="
