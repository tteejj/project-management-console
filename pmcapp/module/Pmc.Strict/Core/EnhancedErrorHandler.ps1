# PMC Enhanced Error Handler - Comprehensive error handling and recovery
# Implements Phase 3 error handling improvements

Set-StrictMode -Version Latest

# Error classification and severity levels
enum PmcErrorSeverity {
    Info = 0
    Warning = 1
    Error = 2
    Critical = 3
    Fatal = 4
}

enum PmcErrorCategory {
    Validation = 1
    Security = 2
    Performance = 3
    Data = 4
    Network = 5
    System = 6
    User = 7
    Configuration = 8
}

# Enhanced error object with context and recovery options
class PmcEnhancedError {
    [string] $Id
    [datetime] $Timestamp
    [PmcErrorSeverity] $Severity
    [PmcErrorCategory] $Category
    [string] $Message
    [string] $DetailedMessage
    [object] $Exception
    [hashtable] $Context = @{}
    [string[]] $RecoveryOptions = @()
    [bool] $IsRecoverable = $true
    [string] $Source
    [string] $StackTrace

    PmcEnhancedError([PmcErrorSeverity]$severity, [PmcErrorCategory]$category, [string]$message) {
        $this.Id = [Guid]::NewGuid().ToString("N")[0..7] -join ""
        $this.Timestamp = [datetime]::Now
        $this.Severity = $severity
        $this.Category = $category
        $this.Message = $message
        $this.Source = (Get-PSCallStack)[1].Command
    }

    [void] SetException([System.Exception]$exception) {
        $this.Exception = $exception
        $this.DetailedMessage = $exception.ToString()
        $this.StackTrace = $exception.StackTrace

        # Auto-classify based on exception type
        $this.ClassifyFromException($exception)
    }

    [void] ClassifyFromException([System.Exception]$exception) {
        switch ($exception.GetType().Name) {
            'UnauthorizedAccessException' {
                $this.Category = [PmcErrorCategory]::Security
                $this.Severity = [PmcErrorSeverity]::Error
            }
            'ArgumentException' {
                $this.Category = [PmcErrorCategory]::Validation
                $this.Severity = [PmcErrorSeverity]::Warning
            }
            'TimeoutException' {
                $this.Category = [PmcErrorCategory]::Performance
                $this.Severity = [PmcErrorSeverity]::Warning
                $this.RecoveryOptions += "Retry operation"
            }
            'FileNotFoundException' {
                $this.Category = [PmcErrorCategory]::Data
                $this.Severity = [PmcErrorSeverity]::Error
                $this.RecoveryOptions += "Check file path", "Create missing file"
            }
            'OutOfMemoryException' {
                $this.Category = [PmcErrorCategory]::System
                $this.Severity = [PmcErrorSeverity]::Critical
                $this.IsRecoverable = $false
            }
            default {
                $this.Category = [PmcErrorCategory]::System
                $this.Severity = [PmcErrorSeverity]::Error
            }
        }
    }

    [void] AddContext([string]$key, [object]$value) {
        $this.Context[$key] = $value
    }

    [void] AddRecoveryOption([string]$option) {
        $this.RecoveryOptions += $option
    }

    [hashtable] ToHashtable() {
        return @{
            Id = $this.Id
            Timestamp = $this.Timestamp
            Severity = $this.Severity.ToString()
            Category = $this.Category.ToString()
            Message = $this.Message
            DetailedMessage = $this.DetailedMessage
            Source = $this.Source
            Context = $this.Context
            RecoveryOptions = $this.RecoveryOptions
            IsRecoverable = $this.IsRecoverable
        }
    }
}

# Error recovery strategies
class PmcErrorRecoveryManager {
    hidden [hashtable] $_recoveryStrategies = @{}

    PmcErrorRecoveryManager() {
        $this.InitializeRecoveryStrategies()
    }

    [void] InitializeRecoveryStrategies() {
        # File not found recovery
        $this._recoveryStrategies['FileNotFound'] = {
            param($error, $context)
            $filePath = $context.FilePath
            if ($filePath) {
                # Try to create directory if it doesn't exist
                $directory = Split-Path $filePath -Parent
                if ($directory -and -not (Test-Path $directory)) {
                    try {
                        New-Item -Path $directory -ItemType Directory -Force | Out-Null
                        return @{ Success = $true; Message = "Created missing directory: $directory" }
                    } catch {
                        return @{ Success = $false; Message = "Failed to create directory: $_" }
                    }
                }
            }
            return @{ Success = $false; Message = "Cannot recover from file not found" }
        }

        # Network timeout recovery
        $this._recoveryStrategies['NetworkTimeout'] = {
            param($error, $context)
            $retryCount = $context.RetryCount ?? 0
            if ($retryCount -lt 3) {
                Start-Sleep -Seconds ([Math]::Pow(2, $retryCount))  # Exponential backoff
                return @{ Success = $true; Message = "Retry after backoff (attempt $($retryCount + 1))" }
            }
            return @{ Success = $false; Message = "Max retries exceeded" }
        }

        # Memory pressure recovery
        $this._recoveryStrategies['MemoryPressure'] = {
            param($error, $context)
            try {
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()
                [GC]::Collect()
                return @{ Success = $true; Message = "Forced garbage collection" }
            } catch {
                return @{ Success = $false; Message = "Garbage collection failed: $_" }
            }
        }

        # Data corruption recovery
        $this._recoveryStrategies['DataCorruption'] = {
            param($error, $context)
            $backupPath = $context.BackupPath
            if ($backupPath -and (Test-Path $backupPath)) {
                try {
                    $originalPath = $context.FilePath
                    Copy-Item $backupPath $originalPath -Force
                    return @{ Success = $true; Message = "Restored from backup: $backupPath" }
                } catch {
                    return @{ Success = $false; Message = "Failed to restore from backup: $_" }
                }
            }
            return @{ Success = $false; Message = "No backup available for recovery" }
        }
    }

    [hashtable] AttemptRecovery([PmcEnhancedError]$error) {
        $strategy = $null

        # Determine recovery strategy based on error characteristics
        switch ($error.Category) {
            ([PmcErrorCategory]::Data) {
                if ($error.Message -match "not found|missing") {
                    $strategy = $this._recoveryStrategies['FileNotFound']
                } elseif ($error.Message -match "corrupt|invalid") {
                    $strategy = $this._recoveryStrategies['DataCorruption']
                }
            }
            ([PmcErrorCategory]::Network) {
                if ($error.Message -match "timeout") {
                    $strategy = $this._recoveryStrategies['NetworkTimeout']
                }
            }
            ([PmcErrorCategory]::System) {
                if ($error.Message -match "memory|OutOfMemory") {
                    $strategy = $this._recoveryStrategies['MemoryPressure']
                }
            }
        }

        if ($strategy) {
            try {
                return & $strategy $error $error.Context
            } catch {
                return @{ Success = $false; Message = "Recovery strategy failed: $_" }
            }
        }

        return @{ Success = $false; Message = "No recovery strategy available" }
    }
}

# Error aggregation and analysis
class PmcErrorAnalyzer {
    hidden [System.Collections.Generic.List[PmcEnhancedError]] $_errorHistory
    hidden [hashtable] $_errorPatterns = @{}
    hidden [int] $_maxHistorySize = 1000

    PmcErrorAnalyzer() {
        $this._errorHistory = [System.Collections.Generic.List[PmcEnhancedError]]::new()
    }

    [void] RecordError([PmcEnhancedError]$error) {
        $this._errorHistory.Add($error)

        # Maintain history size
        if ($this._errorHistory.Count -gt $this._maxHistorySize) {
            $this._errorHistory.RemoveRange(0, $this._errorHistory.Count - $this._maxHistorySize)
        }

        # Update error patterns
        $this.UpdateErrorPatterns($error)
    }

    [void] UpdateErrorPatterns([PmcEnhancedError]$error) {
        $key = "$($error.Category):$($error.Severity)"
        if (-not $this._errorPatterns.ContainsKey($key)) {
            $this._errorPatterns[$key] = @{
                Count = 0
                FirstSeen = $error.Timestamp
                LastSeen = $error.Timestamp
                Messages = @{}
                Sources = @{}
            }
        }

        $pattern = $this._errorPatterns[$key]
        $pattern.Count++
        $pattern.LastSeen = $error.Timestamp

        # Track message frequency
        if (-not $pattern.Messages.ContainsKey($error.Message)) {
            $pattern.Messages[$error.Message] = 0
        }
        $pattern.Messages[$error.Message]++

        # Track source frequency
        if (-not $pattern.Sources.ContainsKey($error.Source)) {
            $pattern.Sources[$error.Source] = 0
        }
        $pattern.Sources[$error.Source]++
    }

    [hashtable] GetErrorSummary([int]$hoursBack = 24) {
        $cutoff = [datetime]::Now.AddHours(-$hoursBack)
        $recentErrors = $this._errorHistory | Where-Object { $_.Timestamp -gt $cutoff }

        $summary = @{
            TotalErrors = $recentErrors.Count
            BySeverity = @{}
            ByCategory = @{}
            TopSources = @{}
            TopMessages = @{}
            RecoveryRate = 0
        }

        # Group by severity
        $recentErrors | Group-Object Severity | ForEach-Object {
            $summary.BySeverity[$_.Name] = $_.Count
        }

        # Group by category
        $recentErrors | Group-Object Category | ForEach-Object {
            $summary.ByCategory[$_.Name] = $_.Count
        }

        # Top sources
        $recentErrors | Group-Object Source | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
            $summary.TopSources[$_.Name] = $_.Count
        }

        # Top messages
        $recentErrors | Group-Object Message | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
            $summary.TopMessages[$_.Name] = $_.Count
        }

        # Calculate recovery rate
        $recoverableErrors = $recentErrors | Where-Object { $_.IsRecoverable }
        if ($recoverableErrors.Count -gt 0) {
            $summary.RecoveryRate = [Math]::Round(($recoverableErrors.Count * 100.0) / $recentErrors.Count, 2)
        }

        return $summary
    }

    [PmcEnhancedError[]] GetRecentErrors([int]$count = 20) {
        return $this._errorHistory | Select-Object -Last $count
    }

    [hashtable] GetErrorPatterns() {
        return $this._errorPatterns.Clone()
    }

    [void] ClearHistory() {
        $this._errorHistory.Clear()
        $this._errorPatterns.Clear()
    }
}

# Main enhanced error handler
class PmcEnhancedErrorHandler {
    hidden [PmcErrorRecoveryManager] $_recoveryManager
    hidden [PmcErrorAnalyzer] $_analyzer
    hidden [hashtable] $_errorHandlers = @{}
    hidden [bool] $_autoRecoveryEnabled = $true
    hidden [hashtable] $_stats = @{
        TotalErrors = 0
        RecoveredErrors = 0
        UnrecoverableErrors = 0
    }

    PmcEnhancedErrorHandler() {
        $this._recoveryManager = [PmcErrorRecoveryManager]::new()
        $this._analyzer = [PmcErrorAnalyzer]::new()
        $this.InitializeErrorHandlers()
    }

    [void] InitializeErrorHandlers() {
        # Critical error handler
        $this._errorHandlers[[PmcErrorSeverity]::Critical] = {
            param($error)
            Write-PmcDebug -Level 1 -Category 'ErrorHandler' -Message "CRITICAL ERROR: $($error.Message)" -Data $error.Context
            # Could trigger alerts, notifications, etc.
        }

        # Warning handler
        $this._errorHandlers[[PmcErrorSeverity]::Warning] = {
            param($error)
            Write-PmcDebug -Level 2 -Category 'ErrorHandler' -Message "Warning: $($error.Message)" -Data $error.Context
        }
    }

    [PmcEnhancedError] HandleError([System.Exception]$exception, [hashtable]$context = @{}) {
        $error = [PmcEnhancedError]::new([PmcErrorSeverity]::Error, [PmcErrorCategory]::System, $exception.Message)
        $error.SetException($exception)

        foreach ($key in $context.Keys) {
            $error.AddContext($key, $context[$key])
        }

        return $this.ProcessError($error)
    }

    [PmcEnhancedError] HandleError([PmcErrorSeverity]$severity, [PmcErrorCategory]$category, [string]$message, [hashtable]$context = @{}) {
        $error = [PmcEnhancedError]::new($severity, $category, $message)

        foreach ($key in $context.Keys) {
            $error.AddContext($key, $context[$key])
        }

        return $this.ProcessError($error)
    }

    [PmcEnhancedError] ProcessError([PmcEnhancedError]$error) {
        $this._stats.TotalErrors++

        # Record for analysis
        $this._analyzer.RecordError($error)

        # Execute severity-specific handler
        if ($this._errorHandlers.ContainsKey($error.Severity)) {
            try {
                & $this._errorHandlers[$error.Severity] $error
            } catch {
                Write-PmcDebug -Level 1 -Category 'ErrorHandler' -Message "Error handler failed: $_"
            }
        }

        # Attempt recovery if enabled and error is recoverable
        if ($this._autoRecoveryEnabled -and $error.IsRecoverable) {
            $recoveryResult = $this._recoveryManager.AttemptRecovery($error)
            if ($recoveryResult.Success) {
                $this._stats.RecoveredErrors++
                $error.AddContext("RecoveryResult", $recoveryResult.Message)
                Write-PmcDebug -Level 2 -Category 'ErrorHandler' -Message "Error recovered: $($recoveryResult.Message)" -Data @{ ErrorId = $error.Id }
            } else {
                $this._stats.UnrecoverableErrors++
                $error.AddContext("RecoveryAttempt", $recoveryResult.Message)
            }
        } else {
            $this._stats.UnrecoverableErrors++
        }

        return $error
    }

    [hashtable] GetErrorStats() {
        $summary = $this._analyzer.GetErrorSummary(24)
        $patterns = $this._analyzer.GetErrorPatterns()

        return @{
            OverallStats = $this._stats.Clone()
            RecentSummary = $summary
            ErrorPatterns = $patterns
            RecoveryRate = if ($this._stats.TotalErrors -gt 0) {
                [Math]::Round(($this._stats.RecoveredErrors * 100.0) / $this._stats.TotalErrors, 2)
            } else { 0 }
        }
    }

    [PmcEnhancedError[]] GetRecentErrors([int]$count = 20) {
        return $this._analyzer.GetRecentErrors($count)
    }

    [void] EnableAutoRecovery() {
        $this._autoRecoveryEnabled = $true
    }

    [void] DisableAutoRecovery() {
        $this._autoRecoveryEnabled = $false
    }

    [void] ClearErrorHistory() {
        $this._analyzer.ClearHistory()
        $this._stats = @{
            TotalErrors = 0
            RecoveredErrors = 0
            UnrecoverableErrors = 0
        }
    }
}

# Global instance
$Script:PmcEnhancedErrorHandler = $null

function Initialize-PmcEnhancedErrorHandler {
    if ($Script:PmcEnhancedErrorHandler) {
        Write-Warning "PMC Enhanced Error Handler already initialized"
        return
    }

    $Script:PmcEnhancedErrorHandler = [PmcEnhancedErrorHandler]::new()
    Write-PmcDebug -Level 2 -Category 'ErrorHandler' -Message "Enhanced error handler initialized"
}

function Get-PmcEnhancedErrorHandler {
    if (-not $Script:PmcEnhancedErrorHandler) {
        Initialize-PmcEnhancedErrorHandler
    }
    return $Script:PmcEnhancedErrorHandler
}

function Write-PmcEnhancedError {
    param(
        [Parameter(ParameterSetName='Exception', Mandatory=$true)]
        [System.Exception]$Exception,

        [Parameter(ParameterSetName='Manual', Mandatory=$true)]
        [PmcErrorSeverity]$Severity,

        [Parameter(ParameterSetName='Manual', Mandatory=$true)]
        [PmcErrorCategory]$Category,

        [Parameter(ParameterSetName='Manual', Mandatory=$true)]
        [string]$Message,

        [hashtable]$Context = @{}
    )

    $handler = Get-PmcEnhancedErrorHandler

    if ($PSCmdlet.ParameterSetName -eq 'Exception') {
        return $handler.HandleError($Exception, $Context)
    } else {
        return $handler.HandleError($Severity, $Category, $Message, $Context)
    }
}

function Get-PmcErrorReport {
    param(
        [switch]$Detailed,
        [int]$RecentCount = 20
    )

    $handler = Get-PmcEnhancedErrorHandler
    $stats = $handler.GetErrorStats()
    $recentErrors = $handler.GetRecentErrors($RecentCount)

    Write-Host "PMC Error Analysis Report" -ForegroundColor Red
    Write-Host "========================" -ForegroundColor Red
    Write-Host ""

    # Overall statistics
    Write-Host "Overall Statistics:" -ForegroundColor Yellow
    Write-Host "  Total Errors: $($stats.OverallStats.TotalErrors)"
    Write-Host "  Recovered: $($stats.OverallStats.RecoveredErrors)"
    Write-Host "  Unrecoverable: $($stats.OverallStats.UnrecoverableErrors)"
    Write-Host "  Recovery Rate: $($stats.RecoveryRate)%"
    Write-Host ""

    # Recent summary (last 24 hours)
    Write-Host "Recent Activity (24h):" -ForegroundColor Yellow
    Write-Host "  Total: $($stats.RecentSummary.TotalErrors)"

    if ($stats.RecentSummary.BySeverity.Count -gt 0) {
        Write-Host "  By Severity:"
        foreach ($severity in $stats.RecentSummary.BySeverity.GetEnumerator()) {
            Write-Host "    $($severity.Key): $($severity.Value)"
        }
    }

    if ($stats.RecentSummary.ByCategory.Count -gt 0) {
        Write-Host "  By Category:"
        foreach ($category in $stats.RecentSummary.ByCategory.GetEnumerator()) {
            Write-Host "    $($category.Key): $($category.Value)"
        }
    }
    Write-Host ""

    if ($Detailed) {
        # Top error sources
        if ($stats.RecentSummary.TopSources.Count -gt 0) {
            Write-Host "Top Error Sources:" -ForegroundColor Yellow
            foreach ($source in $stats.RecentSummary.TopSources.GetEnumerator()) {
                Write-Host "  $($source.Key): $($source.Value)"
            }
            Write-Host ""
        }

        # Recent errors
        if ($recentErrors.Count -gt 0) {
            Write-Host "Recent Errors:" -ForegroundColor Yellow
            foreach ($error in $recentErrors) {
                $timeAgo = [Math]::Round(([datetime]::Now - $error.Timestamp).TotalMinutes, 1)
                Write-Host "  [$($error.Severity)] $($error.Message) ($($timeAgo)m ago)" -ForegroundColor Red
                if ($error.RecoveryOptions.Count -gt 0) {
                    Write-Host "    Recovery: $($error.RecoveryOptions -join ', ')" -ForegroundColor Green
                }
            }
        }
    }
}

function Clear-PmcErrorHistory {
    $handler = Get-PmcEnhancedErrorHandler
    $handler.ClearErrorHistory()
    Write-Host "Error history cleared" -ForegroundColor Green
}

Export-ModuleMember -Function Initialize-PmcEnhancedErrorHandler, Get-PmcEnhancedErrorHandler, Write-PmcEnhancedError, Get-PmcErrorReport, Clear-PmcErrorHistory