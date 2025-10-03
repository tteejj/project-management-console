# PMC Unified Initializer - Centralized initialization for all enhanced systems
# Implements Phase 4 unified initialization and integration

Set-StrictMode -Version Latest

# Unified initialization orchestrator
class PmcUnifiedInitializer {
    hidden [hashtable] $_initializationStatus = @{}
    hidden [hashtable] $_dependencies = @{}
    hidden [hashtable] $_configuration = @{}
    hidden [bool] $_isInitialized = $false
    hidden [datetime] $_initStartTime
    hidden [System.Collections.Generic.List[string]] $_initializationOrder

    PmcUnifiedInitializer() {
        $this._initializationOrder = [System.Collections.Generic.List[string]]::new()
        $this.SetupDependencies()
        $this.LoadConfiguration()
    }

    [void] SetupDependencies() {
        # Define initialization order and dependencies
        $this._dependencies = @{
            'SecureState' = @{
                Dependencies = @()
                InitFunction = 'Initialize-PmcSecureState'
                Description = 'Secure state management system'
                Critical = $true
            }
            'Security' = @{
                Dependencies = @('SecureState')
                InitFunction = 'Initialize-PmcSecuritySystem'
                Description = 'Security and input validation'
                Critical = $true
            }
            'Debug' = @{
                Dependencies = @('SecureState')
                InitFunction = 'Initialize-PmcDebugSystem'
                Description = 'Debug and logging system'
                Critical = $false
            }
            'Performance' = @{
                Dependencies = @('SecureState', 'Debug')
                InitFunction = 'Initialize-PmcPerformanceOptimizer'
                Description = 'Performance monitoring and optimization'
                Critical = $false
            }
            'ErrorHandler' = @{
                Dependencies = @('SecureState', 'Debug')
                InitFunction = 'Initialize-PmcEnhancedErrorHandler'
                Description = 'Enhanced error handling and recovery'
                Critical = $false
            }
            'DataValidator' = @{
                Dependencies = @('SecureState', 'ErrorHandler')
                InitFunction = 'Initialize-PmcEnhancedDataValidator'
                Description = 'Data validation and sanitization'
                Critical = $true
            }
            'QueryEngine' = @{
                Dependencies = @('SecureState', 'Performance', 'DataValidator')
                InitFunction = 'Initialize-PmcEnhancedQueryEngine'
                Description = 'Enhanced query language engine'
                Critical = $false
            }
            'CommandProcessor' = @{
                Dependencies = @('SecureState', 'Security', 'Performance', 'ErrorHandler', 'DataValidator')
                InitFunction = 'Initialize-PmcEnhancedCommandProcessor'
                Description = 'Enhanced command processing pipeline'
                Critical = $false
            }
            'Screen' = @{
                Dependencies = @('SecureState', 'Debug')
                InitFunction = 'Initialize-PmcScreen'
                Description = 'Screen management system'
                Critical = $false
            }
            # Input multiplexer removed in strict modal architecture
            'DifferentialRenderer' = @{
                Dependencies = @('SecureState', 'Screen', 'Performance')
                InitFunction = 'Initialize-PmcDifferentialRenderer'
                Description = 'Flicker-free screen rendering'
                Critical = $false
            }
            'UnifiedDataViewer' = @{
                Dependencies = @('SecureState', 'Screen', 'QueryEngine', 'DifferentialRenderer')
                InitFunction = 'Initialize-PmcUnifiedDataViewer'
                Description = 'Real-time data display system'
                Critical = $false
            }
            'Theme' = @{
                Dependencies = @('SecureState')
                InitFunction = 'Initialize-PmcThemeSystem'
                Description = 'Theme and styling system'
                Critical = $false
            }
        }
    }

    [void] LoadConfiguration() {
        # Load initialization configuration
        $this._configuration = @{
            SkipNonCritical = $false
            MaxInitTime = 30000  # 30 seconds max
            ParallelInit = $false  # For future enhancement
            LogLevel = 2
            FailFast = $true  # Stop on critical component failure
        }

        # Try to load user configuration
        try {
            if (Get-Command Get-PmcConfig -ErrorAction SilentlyContinue) {
                $userConfig = Get-PmcConfig -Section 'Initialization' -ErrorAction SilentlyContinue
                if ($userConfig) {
                    foreach ($key in $userConfig.Keys) {
                        $this._configuration[$key] = $userConfig[$key]
                    }
                }
            }
        } catch {
            Write-PmcDebug -Level 2 -Category 'UnifiedInitializer' -Message "Could not load user initialization config: $_"
        }
    }

    [void] ComputeInitializationOrder() {
        $this._initializationOrder.Clear()
        $completed = @{}
        $remaining = @($this._dependencies.Keys | Where-Object { $_ })

        # Topological sort to handle dependencies
        while ($remaining.Count -gt 0) {
            $progress = $false

            foreach ($component in @($remaining)) {
                $deps = $this._dependencies[$component].Dependencies
                $canInit = $true

                foreach ($dep in $deps) {
                    if (-not $completed.ContainsKey($dep)) {
                        $canInit = $false
                        break
                    }
                }

                if ($canInit) {
                    $this._initializationOrder.Add($component)
                    $completed[$component] = $true
                    $remaining = @($remaining | Where-Object { $_ -ne $component })
                    $progress = $true
                }
            }

            if (-not $progress -and $remaining.Count -gt 0) {
                $cyclicDeps = $remaining -join ', '
                throw "Cyclic dependencies detected in initialization: $cyclicDeps"
            }
        }

        Write-PmcDebug -Level 3 -Category 'UnifiedInitializer' -Message "Computed initialization order" -Data @{
            Order = $this._initializationOrder
            Count = $this._initializationOrder.Count
        }
    }

    [hashtable] InitializeAllSystems() {
        if ($this._isInitialized) {
            return @{ Success = $true; Message = "Already initialized"; AlreadyInitialized = $true }
        }

        $this._initStartTime = [datetime]::Now
        $results = @{
            Success = $true
            ComponentResults = @{}
            TotalDuration = 0
            CriticalFailures = @()
            NonCriticalFailures = @()
            SkippedComponents = @()
        }

        try {
            # Compute initialization order
            $this.ComputeInitializationOrder()

            Write-PmcDebug -Level 1 -Category 'UnifiedInitializer' -Message "Starting unified initialization" -Data @{
                ComponentCount = $this._initializationOrder.Count
                Configuration = $this._configuration
            }

            # Initialize each component in order
            foreach ($component in $this._initializationOrder) {
                $componentResult = $this.InitializeComponent($component)
                $results.ComponentResults[$component] = $componentResult

                if (-not $componentResult.Success) {
                    $isCritical = $this._dependencies[$component].Critical

                    if ($isCritical) {
                        $results.CriticalFailures += $component
                        if ($this._configuration.FailFast) {
                            $results.Success = $false
                            $results.Message = "Critical component '$component' failed to initialize"
                            break
                        }
                    } else {
                        $results.NonCriticalFailures += $component
                    }
                }
            }

            # Check timeout
            $elapsed = ([datetime]::Now - $this._initStartTime).TotalMilliseconds
            if ($elapsed -gt $this._configuration.MaxInitTime) {
                $results.Success = $false
                $results.Message = "Initialization timeout exceeded ($elapsed ms)"
            }

            $results.TotalDuration = $elapsed
            $this._isInitialized = $results.Success

            if ($results.Success) {
                Write-PmcDebug -Level 1 -Category 'UnifiedInitializer' -Message "Unified initialization completed successfully" -Data @{
                    Duration = $elapsed
                    ComponentCount = $this._initializationOrder.Count
                    Failures = $results.NonCriticalFailures.Count
                }
            } else {
                Write-PmcDebug -Level 1 -Category 'UnifiedInitializer' -Message "Unified initialization failed" -Data @{
                    Duration = $elapsed
                    CriticalFailures = $results.CriticalFailures
                    Message = $results.Message
                }
            }

        } catch {
            $results.Success = $false
            $results.Message = "Initialization exception: $_"
            Write-PmcDebug -Level 1 -Category 'UnifiedInitializer' -Message "Initialization exception: $_"
        }

        return $results
    }

    [hashtable] InitializeComponent([string]$component) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = @{
            Success = $false
            Message = ""
            Duration = 0
            Skipped = $false
        }

        try {
            $config = $this._dependencies[$component]

            # Check if we should skip non-critical components
            if ($this._configuration.SkipNonCritical -and -not $config.Critical) {
                $result.Skipped = $true
                $result.Success = $true
                $result.Message = "Skipped (non-critical)"
                return $result
            }

            Write-PmcDebug -Level 2 -Category 'UnifiedInitializer' -Message "Initializing component: $component" -Data @{
                Description = $config.Description
                Critical = $config.Critical
                Dependencies = $config.Dependencies
            }

            # Check if initialization function exists
            $initFunction = $config.InitFunction
            if (-not (Get-Command $initFunction -ErrorAction SilentlyContinue)) {
                $result.Message = "Initialization function '$initFunction' not found"
                return $result
            }

            # Call initialization function
            & $initFunction

            $result.Success = $true
            $result.Message = "Initialized successfully"
            $this._initializationStatus[$component] = @{
                Status = 'Initialized'
                Timestamp = [datetime]::Now
                Duration = $stopwatch.ElapsedMilliseconds
            }

        } catch {
            $result.Message = "Initialization failed: $_"
            $this._initializationStatus[$component] = @{
                Status = 'Failed'
                Timestamp = [datetime]::Now
                Duration = $stopwatch.ElapsedMilliseconds
                Error = $_.ToString()
            }
        } finally {
            $stopwatch.Stop()
            $result.Duration = $stopwatch.ElapsedMilliseconds
        }

        return $result
    }

    [hashtable] GetInitializationStatus() {
        return @{
            IsInitialized = $this._isInitialized
            ComponentStatus = $this._initializationStatus.Clone()
            InitializationOrder = $this._initializationOrder.ToArray()
            Configuration = $this._configuration.Clone()
            InitStartTime = $this._initStartTime
        }
    }

    [void] ResetInitialization() {
        $this._isInitialized = $false
        $this._initializationStatus.Clear()
        $this._initializationOrder.Clear()
    }

    [bool] IsComponentInitialized([string]$component) {
        return $this._initializationStatus.ContainsKey($component) -and
               $this._initializationStatus[$component].Status -eq 'Initialized'
    }

    [void] SetConfiguration([string]$key, [object]$value) {
        $this._configuration[$key] = $value
    }
}

# Command integration system for enhanced/legacy interop
class PmcCommandIntegrator {
    hidden [hashtable] $_commandMappings = @{}
    hidden [hashtable] $_enhancementStatus = @{}

    PmcCommandIntegrator() {
        $this.SetupCommandMappings()
    }

    [void] SetupCommandMappings() {
        # Map legacy commands to enhanced equivalents where available
        $this._commandMappings = @{
            'Invoke-PmcCommand' = @{
                Enhanced = 'Invoke-PmcEnhancedCommand'
                Fallback = 'Invoke-PmcCommand'
                UseEnhanced = $true
                WrapLegacy = $true
            }
            'Invoke-PmcQuery' = @{
                Enhanced = 'Invoke-PmcEnhancedQuery'
                Fallback = 'Invoke-PmcQuery'
                UseEnhanced = $true
                WrapLegacy = $true
            }
            'Test-PmcData' = @{
                Enhanced = 'Test-PmcEnhancedData'
                Fallback = $null
                UseEnhanced = $true
                WrapLegacy = $false
            }
        }
    }

    [void] IntegrateEnhancedSystems() {
        # Create wrapper functions that route to enhanced systems when available
        foreach ($mapping in $this._commandMappings.GetEnumerator()) {
            $legacyCommand = $mapping.Key
            $config = $mapping.Value

            if ($config.UseEnhanced -and $config.WrapLegacy) {
                $this.CreateCommandWrapper($legacyCommand, $config)
            }
        }
    }

    [void] CreateCommandWrapper([string]$legacyCommand, [hashtable]$config) {
        # This would ideally create dynamic function wrappers
        # For now, we'll track the mapping for manual integration
        $this._enhancementStatus[$legacyCommand] = @{
            Enhanced = $config.Enhanced
            Available = (Get-Command $config.Enhanced -ErrorAction SilentlyContinue) -ne $null
            Integrated = $false
            LastCheck = [datetime]::Now
        }
    }

    [hashtable] GetIntegrationStatus() {
        return $this._enhancementStatus.Clone()
    }
}

# Global instances
$Script:PmcUnifiedInitializer = $null
$Script:PmcCommandIntegrator = $null

function Initialize-PmcUnifiedSystems {
    param(
        [hashtable]$Configuration = @{}
    )

    if (-not $Script:PmcUnifiedInitializer) {
        $Script:PmcUnifiedInitializer = [PmcUnifiedInitializer]::new()
        $Script:PmcCommandIntegrator = [PmcCommandIntegrator]::new()
    }

    # Apply any user configuration
    foreach ($config in $Configuration.GetEnumerator()) {
        $Script:PmcUnifiedInitializer.SetConfiguration($config.Key, $config.Value)
    }

    # Initialize all systems
    $result = $Script:PmcUnifiedInitializer.InitializeAllSystems()

    # If successful, integrate command systems
    if ($result.Success) {
        try {
            $Script:PmcCommandIntegrator.IntegrateEnhancedSystems()
            Write-PmcDebug -Level 2 -Category 'UnifiedInitializer' -Message "Command integration completed"
        } catch {
            Write-PmcDebug -Level 1 -Category 'UnifiedInitializer' -Message "Command integration failed: $_"
        }
    }

    return $result
}

function Get-PmcInitializationStatus {
    if (-not $Script:PmcUnifiedInitializer) {
        return @{ Error = "Unified initializer not created" }
    }

    $status = $Script:PmcUnifiedInitializer.GetInitializationStatus()

    if ($Script:PmcCommandIntegrator) {
        $status.CommandIntegration = $Script:PmcCommandIntegrator.GetIntegrationStatus()
    }

    return $status
}

function Show-PmcInitializationReport {
    $status = Get-PmcInitializationStatus

    if ($status.ContainsKey('Error')) {
        Write-Host "PMC Initialization Status: $($status.Error)" -ForegroundColor Red
        return
    }

    Write-Host "PMC Unified System Initialization Report" -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host ""

    # Overall status
    $statusColor = if ($status.IsInitialized) { "Green" } else { "Red" }
    $statusText = if ($status.IsInitialized) { "INITIALIZED" } else { "NOT INITIALIZED" }
    Write-Host "Overall Status: $statusText" -ForegroundColor $statusColor

    if ($status.InitStartTime) {
        $elapsed = ([datetime]::Now - $status.InitStartTime).TotalSeconds
        Write-Host "Runtime: $([Math]::Round($elapsed, 1)) seconds"
    }

    Write-Host ""

    # Component status
    if ($status.ComponentStatus.Count -gt 0) {
        Write-Host "Component Status:" -ForegroundColor Yellow
        Write-Host "Component".PadRight(20) + "Status".PadRight(15) + "Duration(ms)" -ForegroundColor Cyan
        Write-Host ("-" * 45) -ForegroundColor Gray

        foreach ($order in $status.InitializationOrder) {
            if ($status.ComponentStatus.ContainsKey($order)) {
                $comp = $status.ComponentStatus[$order]
                $statusColor = if ($comp.Status -eq 'Initialized') { "Green" } else { "Red" }

                Write-Host ($order.PadRight(20) +
                          $comp.Status.PadRight(15) +
                          $comp.Duration.ToString()) -ForegroundColor $statusColor
            }
        }
        Write-Host ""
    }

    # Command integration status
    if ($status.CommandIntegration) {
        Write-Host "Command Integration:" -ForegroundColor Yellow
        foreach ($cmd in $status.CommandIntegration.GetEnumerator()) {
            $integrationStatus = if ($cmd.Value.Available) { "Available" } else { "Missing" }
            $color = if ($cmd.Value.Available) { "Green" } else { "Yellow" }
            Write-Host "  $($cmd.Key): $integrationStatus" -ForegroundColor $color
        }
    }
}

function Reset-PmcInitialization {
    if ($Script:PmcUnifiedInitializer) {
        $Script:PmcUnifiedInitializer.ResetInitialization()
        Write-Host "PMC initialization reset" -ForegroundColor Green
    }
}

Export-ModuleMember -Function Initialize-PmcUnifiedSystems, Get-PmcInitializationStatus, Show-PmcInitializationReport, Reset-PmcInitialization
