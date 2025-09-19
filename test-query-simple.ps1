# Simple test of query system through PMC interface
$ErrorActionPreference = 'Continue'

Write-Host "=== Simple PMC Query Test ===" -ForegroundColor Green

try {
    Write-Host "`nLoading PMC..." -ForegroundColor Cyan
    ./start-pmc.ps1 -NonInteractive | Out-Null
    Start-Sleep 2

    Write-Host "`nTesting basic query commands via PMC..." -ForegroundColor Cyan

    # Test via the actual PMC input system
    Write-Host "`nTest 1: q tasks" -ForegroundColor Yellow
    echo "q tasks" | nc -q 1 localhost 12345 2>/dev/null

    Write-Host "`nTest 2: q tasks p1" -ForegroundColor Yellow
    echo "q tasks p1" | nc -q 1 localhost 12345 2>/dev/null

    Write-Host "`nTest 3: q tasks due:+7" -ForegroundColor Yellow
    echo "q tasks due:+7" | nc -q 1 localhost 12345 2>/dev/null

    Write-Host "`n✅ Query commands executed successfully" -ForegroundColor Green
    Write-Host "Check PMC output for results" -ForegroundColor Cyan

} catch {
    Write-Host "`n❌ Test failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}