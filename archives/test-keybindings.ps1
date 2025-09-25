Import-Module ./module/Pmc.Strict -Force

# Create a test grid renderer to check key bindings
$columns = @{
    "Task" = @{ Header = "Task"; Width = $null }
    "Priority" = @{ Header = "P"; Width = 3 }
}

$testData = @(
    [PSCustomObject]@{ Task = "Test task 1"; Priority = 1 }
    [PSCustomObject]@{ Task = "Test task 2"; Priority = 2 }
)

$renderer = [PmcGridRenderer]::new($columns, @("task"), @{})
$renderer.CurrentData = $testData

Write-Host "Key bindings configured:"
foreach ($key in $renderer.KeyBindings.Keys | Sort-Object) {
    Write-Host "  $key -> $($renderer.KeyBindings[$key])"
}

Write-Host "`nNavigation Mode: $($renderer.NavigationMode)"
Write-Host "Selected Row: $($renderer.SelectedRow)"

# Test StartCellEdit directly
Write-Host "`nTesting StartCellEdit()..."
try {
    $renderer.StartCellEdit()
} catch {
    Write-Host "Error: $_"
}