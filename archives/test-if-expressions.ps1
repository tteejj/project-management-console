# Test different inline if expressions to find the problematic one
$ErrorActionPreference = 'Stop'

Write-Host "Testing simple inline if..."
$test1 = if ($true) { "yes" } else { "no" }
Write-Host "Simple inline if: OK"

Write-Host "Testing assignment inline if..."
try {
    $test2 = if ($true) { "yes" } else { "no" }
    Write-Host "Assignment inline if: OK"
} catch {
    Write-Host "Assignment inline if: FAILED - $($_.Exception.Message)"
}

Write-Host "Testing nested inline if..."
try {
    $test3 = if ($true) { if ($true) { "yes" } else { "maybe" } } else { "no" }
    Write-Host "Nested inline if: OK"
} catch {
    Write-Host "Nested inline if: FAILED - $($_.Exception.Message)"
}

Write-Host "Testing complex inline if..."
try {
    $v = 120
    $result = if ($v -match '^\d+$') { $mins=[int]$v; if ($mins -ge 60) { '{0}h {1}m' -f ([int]($mins/60)), ($mins%60) } else { $mins.ToString() + 'm' } } else { [string]$v }
    Write-Host "Complex inline if: OK - $result"
} catch {
    Write-Host "Complex inline if: FAILED - $($_.Exception.Message)"
}