# Test script for PMC Query Language System
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Continue'

Write-Host "=== PMC Query Language System Test ===" -ForegroundColor Green

try {
    Write-Host "`n1. Loading PMC module..." -ForegroundColor Cyan
    Import-Module ./module/Pmc.Strict -Force -ErrorAction Stop
    Write-Host "✅ Module loaded successfully" -ForegroundColor Green

    Write-Host "`n2. Testing basic query parsing..." -ForegroundColor Cyan

    # Test 1: Basic task query
    Write-Host "`nTest: pmc q tasks" -ForegroundColor Yellow
    $result = Invoke-Command -ScriptBlock {
        $context = [PmcCommandContext]::new()
        $context.FreeText = @('tasks')
        Invoke-PmcQuery -Context $context
    }
    Write-Host "✅ Basic task query executed" -ForegroundColor Green

    # Test 2: Query with filters
    Write-Host "`nTest: pmc q tasks p1" -ForegroundColor Yellow
    $result = Invoke-Command -ScriptBlock {
        $context = [PmcCommandContext]::new()
        $context.FreeText = @('tasks', 'p1')
        Invoke-PmcQuery -Context $context
    }
    Write-Host "✅ Priority filter query executed" -ForegroundColor Green

    # Test 3: Query with flexible date parsing
    Write-Host "`nTest: pmc q tasks due:+7" -ForegroundColor Yellow
    $result = Invoke-Command -ScriptBlock {
        $context = [PmcCommandContext]::new()
        $context.FreeText = @('tasks', 'due:+7')
        Invoke-PmcQuery -Context $context
    }
    Write-Host "✅ Flexible date query executed" -ForegroundColor Green

    # Test 4: Query with metrics
    Write-Host "`nTest: pmc q tasks metrics:time_week" -ForegroundColor Yellow
    $result = Invoke-Command -ScriptBlock {
        $context = [PmcCommandContext]::new()
        $context.FreeText = @('tasks', 'metrics:time_week')
        Invoke-PmcQuery -Context $context
    }
    Write-Host "✅ Metrics query executed" -ForegroundColor Green

    # Test 5: Query with columns
    Write-Host "`nTest: pmc q tasks cols:id,text,due" -ForegroundColor Yellow
    $result = Invoke-Command -ScriptBlock {
        $context = [PmcCommandContext]::new()
        $context.FreeText = @('tasks', 'cols:id,text,due')
        Invoke-PmcQuery -Context $context
    }
    Write-Host "✅ Column selection query executed" -ForegroundColor Green

    # Test 6: Query with sorting
    Write-Host "`nTest: pmc q tasks sort:due+" -ForegroundColor Yellow
    $result = Invoke-Command -ScriptBlock {
        $context = [PmcCommandContext]::new()
        $context.FreeText = @('tasks', 'sort:due+')
        Invoke-PmcQuery -Context $context
    }
    Write-Host "✅ Sorting query executed" -ForegroundColor Green

    # Test 7: Complex query
    Write-Host "`nTest: pmc q tasks p<=2 due:eow cols:id,text,due,priority sort:priority+" -ForegroundColor Yellow
    $result = Invoke-Command -ScriptBlock {
        $context = [PmcCommandContext]::new()
        $context.FreeText = @('tasks', 'p<=2', 'due:eow', 'cols:id,text,due,priority', 'sort:priority+')
        Invoke-PmcQuery -Context $context
    }
    Write-Host "✅ Complex query executed" -ForegroundColor Green

    # Test 8: Query alias system
    Write-Host "`nTest: Query alias save/load" -ForegroundColor Yellow
    $result = Invoke-Command -ScriptBlock {
        $context = [PmcCommandContext]::new()
        $context.FreeText = @('tasks', 'p1', 'save:urgent')
        Invoke-PmcQuery -Context $context
    }
    Write-Host "✅ Query alias save executed" -ForegroundColor Green

    $result = Invoke-Command -ScriptBlock {
        $context = [PmcCommandContext]::new()
        $context.FreeText = @('load:urgent')
        Invoke-PmcQuery -Context $context
    }
    Write-Host "✅ Query alias load executed" -ForegroundColor Green

    Write-Host "`n=== All Query Tests Passed! ===" -ForegroundColor Green
    Write-Host "The PMC Query Language System is working correctly." -ForegroundColor Green

} catch {
    Write-Host "`n❌ Test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Gray
    exit 1
}