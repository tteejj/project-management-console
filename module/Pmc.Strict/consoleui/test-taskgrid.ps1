#!/usr/bin/env pwsh
# Test TaskGridScreen instantiation

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    Write-Host "Loading dependencies..."

    # Load all grid classes in correct order
    . "$PSScriptRoot/widgets/GridCell.ps1"
    . "$PSScriptRoot/widgets/CellEditor.ps1"
    . "$PSScriptRoot/widgets/CellEditorRegistry.ps1"
    . "$PSScriptRoot/widgets/ThemedCellRenderer.ps1"
    . "$PSScriptRoot/widgets/GridChangeTracker.ps1"
    . "$PSScriptRoot/widgets/EditableGrid.ps1"

    Write-Host "✓ Grid widgets loaded"

    # Load base classes
    . "$PSScriptRoot/base/StandardListScreen.ps1"
    . "$PSScriptRoot/screens/GridScreen.ps1"

    Write-Host "✓ Base classes loaded"

    # Load TaskGridScreen
    . "$PSScriptRoot/screens/TaskGridScreen.ps1"

    Write-Host "✓ TaskGridScreen loaded"

    # Try to instantiate
    $screen = [TaskGridScreen]::new()

    Write-Host "✓ TaskGridScreen instantiated successfully"
    Write-Host "  ScreenTitle: $($screen.ScreenTitle)"
    Write-Host "  AllowAdd: $($screen.AllowAdd)"
    Write-Host "  AllowEdit: $($screen.AllowEdit)"
    Write-Host "  AllowDelete: $($screen.AllowDelete)"

    # Test GetColumns
    $columns = $screen.GetColumns()
    Write-Host "✓ GetColumns() returned $($columns.Count) columns"

    # Test GetEditableColumns
    $editableColumns = $screen.GetEditableColumns()
    Write-Host "✓ GetEditableColumns() returned: $($editableColumns -join ', ')"

    Write-Host ""
    Write-Host "SUCCESS: All TaskGridScreen tests passed!" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
    exit 1
}
