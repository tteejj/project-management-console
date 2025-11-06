#!/usr/bin/env pwsh

Import-Module /home/teej/pmc/module/Pmc.Strict/Pmc.Strict.psd1 -Force 2>&1 | Out-Null

Write-Host "=== Testing FieldSchema Normalization (used by TaskListScreen) ==="

Write-Host "`n1. Testing DUE DATE field..."
$schema = Get-PmcFieldSchema -Domain 'task' -Field 'due'
Write-Host "   Hint: $($schema.Hint)"

$tests = @(
    @{ Input = '+7';        Expected = (Get-Date).AddDays(7).ToString('yyyy-MM-dd') }
    @{ Input = '20251115';  Expected = '2025-11-15' }
    @{ Input = 'today';     Expected = (Get-Date).Date.ToString('yyyy-MM-dd') }
    @{ Input = 'eom';       Expected = $null }  # Will calc dynamically
)

foreach ($test in $tests) {
    try {
        $normalized = & $schema.Normalize $test.Input
        $display = & $schema.DisplayFormat $normalized

        Write-Host "   '$($test.Input)' → normalized: '$normalized' → display: '$display'"

        if ($test.Expected -and $normalized -ne $test.Expected) {
            Write-Host "     WARNING: Expected '$($test.Expected)'" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   '$($test.Input)' → ERROR: $_" -ForegroundColor Red
    }
}

Write-Host "`n2. Testing PRIORITY field..."
$schema = Get-PmcFieldSchema -Domain 'task' -Field 'priority'
Write-Host "   Hint: $($schema.Hint)"

$tests = @('P2', '2', 'P1', '3')

foreach ($input in $tests) {
    try {
        $normalized = & $schema.Normalize $input
        $display = & $schema.DisplayFormat $normalized
        Write-Host "   '$input' → normalized: '$normalized' → display: '$display'"
    } catch {
        Write-Host "   '$input' → ERROR: $_" -ForegroundColor Red
    }
}

Write-Host "`n3. Testing invalid inputs (should error)..."
try {
    $normalized = & (Get-PmcFieldSchema -Domain 'task' -Field 'priority').Normalize 'P9'
    Write-Host "   'P9' → '$normalized' (should have errored!)" -ForegroundColor Red
} catch {
    Write-Host "   'P9' → ERROR (expected): $_" -ForegroundColor Green
}

Write-Host "`n=== Test Complete ==="
