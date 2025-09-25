# PMC Performance Optimizer - System-wide performance monitoring and optimization
# Implements Phase 3 performance improvements

Set-StrictMode -Version Latest

# Performance monitoring and metrics collection
class PmcPerformanceMonitor {
    hidden [hashtable] $_metrics = @{}
    hidden [hashtable] $_operationCounters = @{}
    hidden [System.Collections.Generic.Queue[object]] $_recentOperations
    hidden [int] $_maxRecentOperations = 100
    hidden [datetime] $_startTime = [datetime]::Now

    PmcPerformanceMonitor() {
        $this._recentOperations = [System.Collections.Generic.Queue[object]]::new()
    }

    [void] RecordOperation([string]$operation, [long]$durationMs, [bool]$success, [hashtable]$metadata = @{}) {
        # Update operation counters
        if (-not $this._operationCounters.ContainsKey($operation)) {
            $this._operationCounters[$operation] = @{
                Count = 0
                TotalMs = 0
                Successes = 0
                Failures = 0
                MinMs = [long]::MaxValue
                MaxMs = 0
                AvgMs = 0
                RecentAvgMs = 0
                P95Ms = 0
                Durations = [System.Collections.Generic.List[long]]::new()
            }
        }

        $counter = $this._operationCounters[$operation]
        $counter.Count++
        $counter.TotalMs += $durationMs

        if ($success) { $counter.Successes++ } else { $counter.Failures++ }

        $counter.MinMs = [Math]::Min($counter.MinMs, $durationMs)
        $counter.MaxMs = [Math]::Max($counter.MaxMs, $durationMs)
        $counter.AvgMs = [Math]::Round($counter.TotalMs / $counter.Count, 2)

        # Track durations for percentile calculations
        $counter.Durations.Add($durationMs)
        if ($counter.Durations.Count -gt 1000) {
            # Keep only recent 1000 measurements
            $counter.Durations.RemoveRange(0, $counter.Durations.Count - 1000)
        }

        # Calculate P95
        if ($counter.Durations.Count -gt 5) {
            $sorted = $counter.Durations | Sort-Object
            $p95Index = [Math]::Floor($sorted.Count * 0.95)
            $counter.P95Ms = $sorted[$p95Index]
        }

        # Record recent operation
        $recentOp = @{
            Operation = $operation
            Timestamp = [datetime]::Now
            Duration = $durationMs
            Success = $success
            Metadata = $metadata
        }

        $this._recentOperations.Enqueue($recentOp)
        if ($this._recentOperations.Count -gt $this._maxRecentOperations) {
            $this._recentOperations.Dequeue() | Out-Null
        }

        # Update recent average (last 10 operations)
        $recent = @($this._recentOperations | Where-Object { $_.Operation -eq $operation } | Select-Object -Last 10)
        if ($recent.Count -gt 0) {
            $counter.RecentAvgMs = [Math]::Round(($recent | Measure-Object Duration -Average).Average, 2)
        }
    }

    [hashtable] GetOperationStats([string]$operation) {
        if ($this._operationCounters.ContainsKey($operation)) {
            return $this._operationCounters[$operation].Clone()
        }
        return @{}
    }

    [hashtable] GetAllStats() {
        $totalOperations = ($this._operationCounters.Values | Measure-Object Count -Sum).Sum
        $totalSuccesses = ($this._operationCounters.Values | Measure-Object Successes -Sum).Sum
        $overallSuccessRate = if ($totalOperations -gt 0) { [Math]::Round(($totalSuccesses * 100.0) / $totalOperations, 2) } else { 0 }
        $uptime = [datetime]::Now - $this._startTime

        return @{
            TotalOperations = $totalOperations
            OverallSuccessRate = $overallSuccessRate
            UptimeMinutes = [Math]::Round($uptime.TotalMinutes, 2)
            OperationTypes = $this._operationCounters.Count
            Operations = $this._operationCounters.Clone()
        }
    }

    [object[]] GetRecentOperations([int]$count = 20) {
        return @($this._recentOperations | Select-Object -Last $count)
    }

    [hashtable] GetSlowOperations([int]$thresholdMs = 1000) {
        $slow = @{}
        foreach ($op in $this._operationCounters.GetEnumerator()) {
            if ($op.Value.MaxMs -gt $thresholdMs -or $op.Value.P95Ms -gt $thresholdMs) {
                $slow[$op.Key] = $op.Value
            }
        }
        return $slow
    }

    [void] Reset() {
        $this._operationCounters.Clear()
        $this._recentOperations.Clear()
        $this._startTime = [datetime]::Now
    }
}

# Memory usage optimization
class PmcMemoryOptimizer {
    hidden [hashtable] $_memoryStats = @{}
    hidden [datetime] $_lastGC = [datetime]::Now

    [hashtable] GetMemoryStats() {
        $before = [GC]::GetTotalMemory($false)

        return @{
            TotalMemoryMB = [Math]::Round($before / 1MB, 2)
            Generation0Collections = [GC]::CollectionCount(0)
            Generation1Collections = [GC]::CollectionCount(1)
            Generation2Collections = [GC]::CollectionCount(2)
            LastGCMinutesAgo = [Math]::Round(([datetime]::Now - $this._lastGC).TotalMinutes, 2)
        }
    }

    [void] ForceGarbageCollection() {
        $before = [GC]::GetTotalMemory($false)
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        [GC]::Collect()
        $after = [GC]::GetTotalMemory($false)

        $this._lastGC = [datetime]::Now
        $freed = $before - $after

        Write-PmcDebug -Level 2 -Category 'PerformanceOptimizer' -Message "Garbage collection completed" -Data @{
            FreedMB = [Math]::Round($freed / 1MB, 2)
            BeforeMB = [Math]::Round($before / 1MB, 2)
            AfterMB = [Math]::Round($after / 1MB, 2)
        }
    }

    [bool] ShouldRunGC() {
        # Run GC if it's been more than 10 minutes and memory is high
        $stats = $this.GetMemoryStats()
        return $stats.LastGCMinutesAgo -gt 10 -and $stats.TotalMemoryMB -gt 100
    }
}

# Cache management for performance optimization
class PmcGlobalCache {
    hidden [hashtable] $_cache = @{}
    hidden [hashtable] $_cacheStats = @{}
    hidden [int] $_maxSize = 200
    hidden [int] $_defaultTTLMinutes = 15

    [void] Set([string]$key, [object]$value, [int]$ttlMinutes = 0) {
        if ($ttlMinutes -eq 0) { $ttlMinutes = $this._defaultTTLMinutes }

        # Evict if at capacity
        if ($this._cache.Count -ge $this._maxSize) {
            $this.EvictExpired()
            if ($this._cache.Count -ge $this._maxSize) {
                $this.EvictOldest()
            }
        }

        $this._cache[$key] = @{
            Value = $value
            Timestamp = [datetime]::Now
            LastAccess = [datetime]::Now
            TTLMinutes = $ttlMinutes
            AccessCount = 0
        }

        if (-not $this._cacheStats.ContainsKey($key)) {
            $this._cacheStats[$key] = @{ Sets = 0; Gets = 0; Hits = 0; Misses = 0 }
        }
        $this._cacheStats[$key].Sets++
    }

    [object] Get([string]$key) {
        $this._cacheStats[$key] = $this._cacheStats.ContainsKey($key) ? $this._cacheStats[$key] : @{ Sets = 0; Gets = 0; Hits = 0; Misses = 0 }
        $this._cacheStats[$key].Gets++

        if ($this._cache.ContainsKey($key)) {
            $entry = $this._cache[$key]
            $age = ([datetime]::Now - $entry.Timestamp).TotalMinutes

            if ($age -lt $entry.TTLMinutes) {
                $entry.LastAccess = [datetime]::Now
                $entry.AccessCount++
                $this._cacheStats[$key].Hits++
                return $entry.Value
            } else {
                $this._cache.Remove($key)
            }
        }

        $this._cacheStats[$key].Misses++
        return $null
    }

    [void] Remove([string]$key) {
        $this._cache.Remove($key)
    }

    [void] EvictExpired() {
        $expired = @()
        foreach ($entry in $this._cache.GetEnumerator()) {
            $age = ([datetime]::Now - $entry.Value.Timestamp).TotalMinutes
            if ($age -gt $entry.Value.TTLMinutes) {
                $expired += $entry.Key
            }
        }
        foreach ($key in $expired) {
            $this._cache.Remove($key)
        }
    }

    [void] EvictOldest() {
        $oldest = $null
        $oldestTime = [datetime]::MaxValue

        foreach ($entry in $this._cache.GetEnumerator()) {
            if ($entry.Value.LastAccess -lt $oldestTime) {
                $oldestTime = $entry.Value.LastAccess
                $oldest = $entry.Key
            }
        }

        if ($oldest) {
            $this._cache.Remove($oldest)
        }
    }

    [hashtable] GetStats() {
        $totalGets = ($this._cacheStats.Values | Measure-Object Gets -Sum).Sum
        $totalHits = ($this._cacheStats.Values | Measure-Object Hits -Sum).Sum
        $hitRate = if ($totalGets -gt 0) { [Math]::Round(($totalHits * 100.0) / $totalGets, 2) } else { 0 }

        return @{
            Size = $this._cache.Count
            MaxSize = $this._maxSize
            TotalGets = $totalGets
            TotalHits = $totalHits
            HitRate = $hitRate
            KeyStats = $this._cacheStats.Clone()
        }
    }

    [void] Clear() {
        $this._cache.Clear()
        $this._cacheStats.Clear()
    }
}

# Main performance optimizer class
class PmcPerformanceOptimizer {
    hidden [PmcPerformanceMonitor] $_monitor
    hidden [PmcMemoryOptimizer] $_memoryOptimizer
    hidden [PmcGlobalCache] $_cache
    hidden [hashtable] $_optimizationRules = @{}
    hidden [bool] $_autoOptimizationEnabled = $true

    PmcPerformanceOptimizer() {
        $this._monitor = [PmcPerformanceMonitor]::new()
        $this._memoryOptimizer = [PmcMemoryOptimizer]::new()
        $this._cache = [PmcGlobalCache]::new()
        $this.InitializeOptimizationRules()
    }

    [void] InitializeOptimizationRules() {
        # Rule: Slow commands should be cached more aggressively
        $this._optimizationRules['slow_command_caching'] = {
            param($stats)
            $slowCommands = $stats.Operations.GetEnumerator() | Where-Object { $_.Value.AvgMs -gt 500 }
            foreach ($cmd in $slowCommands) {
                Write-PmcDebug -Level 2 -Category 'PerformanceOptimizer' -Message "Slow command detected: $($cmd.Key)" -Data @{ AvgMs = $cmd.Value.AvgMs }
            }
        }

        # Rule: High memory usage should trigger GC
        $this._optimizationRules['memory_management'] = {
            param($stats)
            if ($this._memoryOptimizer.ShouldRunGC()) {
                $this._memoryOptimizer.ForceGarbageCollection()
            }
        }

        # Rule: Low cache hit rate should increase TTL
        $this._optimizationRules['cache_optimization'] = {
            param($stats)
            $cacheStats = $this._cache.GetStats()
            if ($cacheStats.HitRate -lt 50 -and $cacheStats.TotalGets -gt 20) {
                Write-PmcDebug -Level 2 -Category 'PerformanceOptimizer' -Message "Low cache hit rate detected" -Data @{ HitRate = $cacheStats.HitRate }
            }
        }
    }

    [void] RecordOperation([string]$operation, [long]$durationMs, [bool]$success, [hashtable]$metadata = @{}) {
        $this._monitor.RecordOperation($operation, $durationMs, $success, $metadata)

        # Auto-optimization
        if ($this._autoOptimizationEnabled) {
            $this.RunOptimizationRules()
        }
    }

    [void] RunOptimizationRules() {
        try {
            $stats = $this._monitor.GetAllStats()
            foreach ($rule in $this._optimizationRules.Values) {
                & $rule $stats
            }
        } catch {
            Write-PmcDebug -Level 1 -Category 'PerformanceOptimizer' -Message "Optimization rule error: $_"
        }
    }

    [object] GetFromCache([string]$key) {
        return $this._cache.Get($key)
    }

    [void] SetCache([string]$key, [object]$value, [int]$ttlMinutes = 0) {
        $this._cache.Set($key, $value, $ttlMinutes)
    }

    [hashtable] GetPerformanceReport() {
        $monitorStats = $this._monitor.GetAllStats()
        $memoryStats = $this._memoryOptimizer.GetMemoryStats()
        $cacheStats = $this._cache.GetStats()
        $slowOps = $this._monitor.GetSlowOperations(500)
        $recentOps = $this._monitor.GetRecentOperations(10)

        return @{
            Summary = @{
                TotalOperations = $monitorStats.TotalOperations
                SuccessRate = $monitorStats.OverallSuccessRate
                UptimeMinutes = $monitorStats.UptimeMinutes
                MemoryMB = $memoryStats.TotalMemoryMB
                CacheHitRate = $cacheStats.HitRate
                SlowOperationCount = $slowOps.Count
            }
            Monitor = $monitorStats
            Memory = $memoryStats
            Cache = $cacheStats
            SlowOperations = $slowOps
            RecentOperations = $recentOps
        }
    }

    [void] EnableAutoOptimization() {
        $this._autoOptimizationEnabled = $true
    }

    [void] DisableAutoOptimization() {
        $this._autoOptimizationEnabled = $false
    }

    [void] ClearAllCaches() {
        $this._cache.Clear()
    }

    [void] Reset() {
        $this._monitor.Reset()
        $this._cache.Clear()
    }
}

# Global instance
$Script:PmcPerformanceOptimizer = $null

function Initialize-PmcPerformanceOptimizer {
    if ($Script:PmcPerformanceOptimizer) {
        Write-Warning "PMC Performance Optimizer already initialized"
        return
    }

    $Script:PmcPerformanceOptimizer = [PmcPerformanceOptimizer]::new()
    Write-PmcDebug -Level 2 -Category 'PerformanceOptimizer' -Message "Performance optimizer initialized"
}

function Get-PmcPerformanceOptimizer {
    if (-not $Script:PmcPerformanceOptimizer) {
        Initialize-PmcPerformanceOptimizer
    }
    return $Script:PmcPerformanceOptimizer
}

function Measure-PmcOperation {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Operation,

        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [hashtable]$Metadata = @{}
    )

    $optimizer = Get-PmcPerformanceOptimizer
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $success = $false
    $result = $null

    try {
        $result = & $ScriptBlock
        $success = $true
    } catch {
        $success = $false
        throw
    } finally {
        $stopwatch.Stop()
        $optimizer.RecordOperation($Operation, $stopwatch.ElapsedMilliseconds, $success, $Metadata)
    }

    return $result
}

function Get-PmcPerformanceReport {
    param(
        [switch]$Detailed
    )

    $optimizer = Get-PmcPerformanceOptimizer
    $report = $optimizer.GetPerformanceReport()

    Write-Host "PMC Performance Report" -ForegroundColor Green
    Write-Host "=====================" -ForegroundColor Green
    Write-Host ""

    # Summary
    Write-Host "System Summary:" -ForegroundColor Yellow
    Write-Host "  Total Operations: $($report.Summary.TotalOperations)"
    Write-Host "  Success Rate: $($report.Summary.SuccessRate)%"
    Write-Host "  Uptime: $($report.Summary.UptimeMinutes) minutes"
    Write-Host "  Memory Usage: $($report.Summary.MemoryMB) MB"
    Write-Host "  Cache Hit Rate: $($report.Summary.CacheHitRate)%"
    Write-Host "  Slow Operations: $($report.Summary.SlowOperationCount)"
    Write-Host ""

    if ($Detailed) {
        # Top operations by count
        if ($report.Monitor.Operations.Count -gt 0) {
            Write-Host "Top Operations (by count):" -ForegroundColor Yellow
            $top = $report.Monitor.Operations.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | Select-Object -First 10
            Write-Host "Operation".PadRight(20) + "Count".PadRight(8) + "Avg(ms)".PadRight(10) + "P95(ms)".PadRight(10) + "Success%" -ForegroundColor Cyan
            Write-Host ("-" * 60) -ForegroundColor Gray
            foreach ($op in $top) {
                $successRate = [Math]::Round(($op.Value.Successes * 100.0) / $op.Value.Count, 1)
                Write-Host ($op.Key.PadRight(20) +
                          $op.Value.Count.ToString().PadRight(8) +
                          $op.Value.AvgMs.ToString().PadRight(10) +
                          $op.Value.P95Ms.ToString().PadRight(10) +
                          "$successRate%")
            }
            Write-Host ""
        }

        # Slow operations
        if ($report.SlowOperations.Count -gt 0) {
            Write-Host "Slow Operations (>500ms):" -ForegroundColor Red
            foreach ($op in $report.SlowOperations.GetEnumerator()) {
                Write-Host "  $($op.Key): Avg $($op.Value.AvgMs)ms, Max $($op.Value.MaxMs)ms, P95 $($op.Value.P95Ms)ms"
            }
            Write-Host ""
        }

        # Memory details
        Write-Host "Memory Details:" -ForegroundColor Yellow
        Write-Host "  Gen 0 Collections: $($report.Memory.Generation0Collections)"
        Write-Host "  Gen 1 Collections: $($report.Memory.Generation1Collections)"
        Write-Host "  Gen 2 Collections: $($report.Memory.Generation2Collections)"
        Write-Host "  Last GC: $($report.Memory.LastGCMinutesAgo) minutes ago"
        Write-Host ""

        # Cache details
        Write-Host "Cache Details:" -ForegroundColor Yellow
        Write-Host "  Size: $($report.Cache.Size) / $($report.Cache.MaxSize)"
        Write-Host "  Total Gets: $($report.Cache.TotalGets)"
        Write-Host "  Total Hits: $($report.Cache.TotalHits)"
        Write-Host ""
    }
}

function Clear-PmcPerformanceCaches {
    $optimizer = Get-PmcPerformanceOptimizer
    $optimizer.ClearAllCaches()
    Write-Host "All performance caches cleared" -ForegroundColor Green
}

function Reset-PmcPerformanceStats {
    $optimizer = Get-PmcPerformanceOptimizer
    $optimizer.Reset()
    Write-Host "Performance statistics reset" -ForegroundColor Green
}

Export-ModuleMember -Function Initialize-PmcPerformanceOptimizer, Get-PmcPerformanceOptimizer, Measure-PmcOperation, Get-PmcPerformanceReport, Clear-PmcPerformanceCaches, Reset-PmcPerformanceStats