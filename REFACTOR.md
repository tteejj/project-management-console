# PMC Architectural Refactoring Plan

## Executive Summary

This document outlines a comprehensive plan to refactor PMC's architecture while preserving its core strengths: CLI-first philosophy, sophisticated query language, and advanced tab completion. The refactoring addresses deep architectural problems identified through multiple code reviews while maintaining full backward compatibility.

## Background: Why Refactor?

### Critical Issues Identified

#### Architectural Problems
- **Massive Coupling**: 40+ files dot-sourced into single scope with direct script-variable access
- **State Anarchy**: Multiple modules maintain independent script variables despite "centralized" state
- **God Functions**: `Invoke-PmcCommand` and `Invoke-PmcQuery` handle too many responsibilities
- **Fragile Parsing**: Regex-based command parsing prone to errors and hard to extend
- **Blocking UI**: Interactive mode takes over entire console, preventing concurrent operations

#### Security Vulnerabilities
- **Missing Input Sanitization**: Commands processed without proper validation
- **Path Safety Gaps**: Inconsistent application of `Test-PmcPathSafety`
- **Resource Exhaustion**: No limits on memory usage or execution time
- **Error Suppression**: Try/catch blocks often swallow errors silently
- **Audit Trail Gaps**: Insufficient logging of security-relevant operations

#### Style and Maintenance Issues
- **Set-StrictMode**: Only 18 of 44 modules enforce strict mode
- **Export Inconsistency**: 29 files with commented `Export-ModuleMember` lines
- **Missing Data APIs**: Functions call undefined helpers like `Get-PmcAllData`
- **Direct Write-Host**: 257 instances bypass styled output system
- **Code Debt Comments**: "HACK" and debug comments in production code

### PMC's Core Strengths (Must Preserve)

#### CLI-First Philosophy
- Command line remains primary interface
- Enhanced display supplements, never replaces CLI
- All functionality accessible via keyboard

#### Sophisticated Query Language
```powershell
q tasks p1 due:today @project    # High priority, due today, specific project
q tasks overdue group:status     # Overdue tasks grouped by status
q projects with:tasks sort:name  # Projects with related task data
```

#### Advanced Tab Completion
- Fuzzy matching with subsequence ranking
- Context-aware completion (domain → action → arguments)
- Ghost text preview of completions
- Real-time parameter hints

#### Domain-Action Model
```powershell
task add "New task" @project p1 due:tomorrow
project list --archived
time report week @webapp
```

#### Security Model
- Path whitelisting with `Test-PmcPathSafety`
- Input validation and sanitization
- Resource limits and monitoring
- Audit logging for security events

## The Solution: PMC Evolution

Instead of replacing PMC with an external framework, we evolve PMC using proven architectural patterns while preserving its unique strengths.

### Design Principles

1. **Preserve User Experience**: All existing commands and syntax remain unchanged
2. **Security First**: Every change must maintain or improve security posture
3. **Incremental Migration**: Each phase delivers working functionality
4. **Backward Compatibility**: Old and new systems coexist during transition
5. **CLI-Centric**: Enhanced display augments, never replaces command line

### Technical Architecture

#### New Component Structure
```
PMC Secure Foundation
├── PmcSecureStateManager     # Thread-safe, validated state access
├── PmcSecureFileManager      # Path-validated file operations
├── PmcSecureCommandProcessor # Input-sanitized command execution
└── PmcAuditLogger           # Security event logging

PMC Enhanced UI
├── PmcScreenManager         # Multi-region layout management
├── PmcInputMultiplexer      # Context-aware input routing
├── PmcDifferentialRenderer  # Flicker-free screen updates
└── PmcDataViewer           # Non-blocking data display

PMC Core Logic (Enhanced)
├── PmcQueryEngine          # Improved query parsing and execution
├── PmcCommandProcessor     # Enhanced domain-action processing
├── PmcCompletionEngine     # Faster, more accurate completions
└── PmcDomainServices       # Decoupled business logic
```

## Implementation Plan

### Phase 1: Foundation & Cleanup (Week 1-2)

#### 1.1 Code Cleanup and Backup Strategy

**Backup Creation**
```bash
# Create comprehensive backup with clear labeling
zip -r "pmc_backup_pre_refactor_$(date +%Y%m%d_%H%M).zip" \
    module/ \
    *.ps1 \
    *.json \
    *.md \
    --exclude="*.log" \
    --exclude="debug.log" \
    --exclude="*.tmp"

# Move to archive directory to prevent search pollution
mkdir -p archives/
mv pmc_backup_*.zip archives/
```

**Legacy Code Identification**
- Identify all `.backup` files and unused modules
- Zip legacy code: `zip archives/legacy_code_$(date +%Y%m%d).zip old_backup/ *.backup`
- Remove from main directory to clean search results

**Dependency Audit**
- Map all script variable dependencies across modules
- Identify circular dependencies and coupling points
- Document public API surface for each module

#### 1.2 Secure State Management Implementation

**Replace Script Variables**
```powershell
# NEW: Thread-safe, validated state manager
class PmcSecureStateManager {
    hidden [hashtable] $_state = @{}
    hidden [System.Threading.ReaderWriterLockSlim] $_lock
    hidden [PmcSecurityPolicy] $_security

    [object] GetState([string]$section, [string]$key) {
        $this._security.ValidateStateAccess($section, $key, 'Read')
        $this._lock.EnterReadLock()
        try {
            return $this._state[$section][$key]
        } finally {
            $this._lock.ExitReadLock()
        }
    }

    [void] SetState([string]$section, [string]$key, [object]$value) {
        $this._security.ValidateStateAccess($section, $key, 'Write')
        $this._security.ValidateStateValue($value)
        $this._lock.EnterWriteLock()
        try {
            if (-not $this._state.ContainsKey($section)) {
                $this._state[$section] = @{}
            }
            $this._state[$section][$key] = $value
        } finally {
            $this._lock.ExitWriteLock()
        }
    }
}
```

**Migration Strategy**
- Replace `$Script:PmcGlobalState` with `PmcSecureStateManager` instance
- Update all `Get-PmcState`/`Set-PmcState` calls to use secure manager
- Add validation to prevent unauthorized state access
- Maintain existing APIs for backward compatibility

#### 1.3 Security Hardening

**Input Sanitization Layer**
```powershell
class PmcInputSanitizer {
    [string] SanitizeCommandInput([string]$input) {
        # Remove potentially dangerous characters
        $input = $input -replace '[`$;&|<>]', ''

        # Validate length
        if ($input.Length -gt 1000) {
            throw "Input too long"
        }

        # Check for injection patterns
        $dangerousPatterns = @(
            'Invoke-Expression', 'iex', 'cmd.exe', 'powershell.exe'
        )
        foreach ($pattern in $dangerousPatterns) {
            if ($input -match $pattern) {
                throw "Potentially dangerous input detected: $pattern"
            }
        }

        return $input.Trim()
    }
}
```

**Enhanced Path Safety**
```powershell
class PmcSecureFileManager {
    [PmcPathValidator] $PathValidator
    [PmcAuditLogger] $AuditLogger

    [string] SecureReadFile([string]$path) {
        $validatedPath = $this.PathValidator.ValidatePath($path, 'Read')
        $this.AuditLogger.LogFileAccess($validatedPath, 'Read')

        try {
            return Get-Content $validatedPath -Raw -ErrorAction Stop
        } catch {
            $this.AuditLogger.LogFileError($validatedPath, 'Read', $_)
            throw
        }
    }
}
```

### Phase 2: Enhanced Display System (Week 3-4)

#### 2.1 Non-Blocking Screen Manager

**Multi-Region Layout**
```powershell
class PmcScreenManager {
    [PmcScreenRegions] $Regions         # Header/Content/Input/Status
    [PmcInputMultiplexer] $InputHandler # Context-aware key routing
    [PmcDifferentialRenderer] $Renderer # Efficient screen updates

    [void] StartNonBlockingSession() {
        # Background input capture
        $inputJob = Start-Job -ScriptBlock {
            while ($true) {
                $key = [Console]::ReadKey($true)
                # Send key event to main thread
                $global:KeyEventQueue.Enqueue($key)
            }
        }

        # Main event loop (non-blocking)
        while ($this.Active) {
            $this.ProcessKeyEvents()
            $this.ProcessDataUpdates()
            $this.Renderer.RenderIfNeeded()
            Start-Sleep -Milliseconds 16  # ~60fps
        }

        # Cleanup
        $inputJob | Stop-Job | Remove-Job
    }
}
```

**Context-Aware Input Routing**
```powershell
class PmcInputMultiplexer {
    [PmcInputContext] $CommandLineContext   # Primary: always gets Escape, Ctrl+*
    [PmcInputContext] $GridNavigationContext # Secondary: arrows when browsing
    [PmcInputContext] $InlineEditContext    # Tertiary: cell editing

    [PmcInputContext] RouteKey([ConsoleKeyInfo]$key) {
        # Command line has priority for escape sequences
        if ($key.Key -eq 'Escape' -or ($key.Modifiers -band 'Control')) {
            return $this.CommandLineContext
        }

        # Grid navigation when explicitly in browse mode
        if ($this.GridBrowseMode -and $key.Key -in @('UpArrow','DownArrow','Enter')) {
            return $this.GridNavigationContext
        }

        # Default: everything to command line (preserve CLI-first)
        return $this.CommandLineContext
    }
}
```

#### 2.2 Enhanced Data Display

**Unified Data Viewer**
```powershell
class PmcDataViewer {
    [PmcDataGrid] $Grid                # Enhanced grid component
    [PmcQueryRenderer] $QueryRenderer  # Render query results
    [PmcLiveUpdater] $LiveUpdater     # Real-time data updates

    [void] ShowQueryResults([string]$query, [object[]]$data) {
        # Preserve existing query display logic
        $columns = $this.DetermineColumnsFromQuery($query)
        $this.Grid.SetData($data, $columns)

        # Enable live updates if data changes
        $this.LiveUpdater.MonitorData($data)
    }
}
```

### Phase 3: Enhanced Core Logic (Week 5-6)

#### 3.1 Improved Query Engine

**Structured Query Processing**
```powershell
class PmcQueryEngine {
    [PmcQueryLexer] $Lexer       # Tokenize query string
    [PmcQueryParser] $Parser     # Parse to AST
    [PmcQueryExecutor] $Executor # Execute against data

    [object[]] ExecuteQuery([string]$queryString) {
        # Parse query (preserve existing syntax)
        $tokens = $this.Lexer.Tokenize($queryString)
        $ast = $this.Parser.Parse($tokens)

        # Execute with enhanced error handling
        try {
            return $this.Executor.Execute($ast)
        } catch [PmcQueryException] {
            # Provide helpful error messages
            Write-PmcStyled -Style 'Error' -Text "Query error: $($_.Message)"
            Write-PmcStyled -Style 'Hint' -Text $_.HelpText
            return @()
        }
    }
}
```

**Enhanced Command Processing**
```powershell
class PmcCommandProcessor {
    [PmcTokenizer] $Tokenizer             # Parse command line
    [PmcDomainResolver] $DomainResolver   # Resolve domains
    [PmcActionResolver] $ActionResolver   # Resolve actions
    [PmcSecureExecutor] $Executor         # Execute securely

    [object] ProcessCommand([string]$commandLine) {
        # Sanitize input
        $sanitized = $this.InputSanitizer.SanitizeCommandInput($commandLine)

        # Parse command (preserve existing syntax)
        $tokens = $this.Tokenizer.Tokenize($sanitized)
        $context = $this.CreateContext($tokens)

        # Execute with audit logging
        return $this.Executor.ExecuteWithAudit($context)
    }
}
```

#### 3.2 Enhanced Tab Completion

**Improved Completion Engine**
```powershell
class PmcCompletionEngine {
    [PmcContextAnalyzer] $ContextAnalyzer   # Understand user input
    [PmcFuzzyMatcher] $FuzzyMatcher         # Enhanced fuzzy matching
    [PmcCompletionCache] $Cache             # Performance optimization

    [string[]] GetCompletions([string]$buffer, [int]$cursorPos) {
        # Analyze context
        $context = $this.ContextAnalyzer.AnalyzeInput($buffer, $cursorPos)

        # Get appropriate completions
        switch ($context.Type) {
            'Domain' { return $this.GetDomainCompletions($context) }
            'Action' { return $this.GetActionCompletions($context) }
            'Argument' { return $this.GetArgumentCompletions($context) }
            'Project' { return $this.GetProjectCompletions($context) }
            'Query' { return $this.GetQueryCompletions($context) }
        }

        return @()
    }
}
```

### Phase 4: Final Integration & Cleanup (Week 7-8)

#### 4.1 Module Consolidation

**Clean Module Structure**
```
module/Pmc.Strict/
├── Core/              # Pure business logic
│   ├── StateManager.ps1
│   ├── SecurityManager.ps1
│   └── AuditLogger.ps1
├── Commands/          # Command processing
│   ├── CommandProcessor.ps1
│   ├── QueryEngine.ps1
│   └── CompletionEngine.ps1
├── UI/               # User interface
│   ├── ScreenManager.ps1
│   ├── DataViewer.ps1
│   └── InputHandler.ps1
├── Services/         # Domain services
│   ├── TaskService.ps1
│   ├── ProjectService.ps1
│   └── TimeService.ps1
└── Storage/          # Data persistence
    ├── FileManager.ps1
    └── DataValidator.ps1
```

**Remove Deprecated Code**
```bash
# Archive old implementations
zip archives/deprecated_modules_$(date +%Y%m%d).zip \
    module/Pmc.Strict/src/Views.ps1.backup \
    module/Pmc.Strict/src/Help.ps1.backup \
    old_backup/

# Remove from active codebase
rm -rf old_backup/
rm module/Pmc.Strict/src/*.backup
```

#### 4.2 Export and API Cleanup

**Consistent Export Strategy**
- Single source of truth in `Pmc.Strict.psd1`
- Remove all commented `Export-ModuleMember` lines
- Document public API clearly
- Hide internal implementation details

**Missing API Implementation**
```powershell
# Add missing data wrappers to Storage.ps1
function Get-PmcAllData { return Get-PmcData }
function Set-PmcAllData { param($data, $action='') Save-PmcData $data }
function Save-StrictData { param($data, $action='') Save-PmcData $data }
```

#### 4.3 Final Security Audit

**Security Checklist**
- [ ] All user input sanitized before processing
- [ ] All file operations use path validation
- [ ] All commands logged for audit trail
- [ ] Resource limits enforced
- [ ] Error handling prevents information leakage
- [ ] No dynamic script execution paths
- [ ] All script variables replaced with secure state

**Performance Validation**
- [ ] Screen rendering under 16ms (60fps)
- [ ] Tab completion under 100ms
- [ ] Query execution under 1s for typical datasets
- [ ] Memory usage under configured limits
- [ ] No memory leaks in long-running sessions

## Success Criteria

### Functional Requirements (Must Work)
- ✅ All existing commands work unchanged
- ✅ Query language syntax preserved
- ✅ Tab completion behavior maintained
- ✅ Data import/export compatibility
- ✅ Configuration settings preserved

### Performance Requirements
- ✅ Command response time ≤ 100ms
- ✅ Query execution ≤ 1s for 1000+ tasks
- ✅ Screen updates ≤ 16ms (60fps)
- ✅ Memory usage under limits
- ✅ No blocking operations in UI

### Security Requirements
- ✅ Input validation on all user data
- ✅ Path safety on all file operations
- ✅ Audit logging for security events
- ✅ Resource limits enforced
- ✅ No privilege escalation paths

### Architectural Requirements
- ✅ Zero script-level variables
- ✅ Proper module boundaries
- ✅ Event-driven communication
- ✅ Thread-safe state management
- ✅ Testable, maintainable code

## Risk Mitigation

### Technical Risks
- **Console API Compatibility**: Test across different terminals and PowerShell versions
- **Threading Complexity**: Use well-tested patterns, avoid over-engineering
- **Performance Regression**: Profile before/after, maintain performance benchmarks

### Migration Risks
- **Feature Regression**: Comprehensive testing of all existing functionality
- **User Disruption**: Maintain feature flags to switch between old/new systems
- **Data Corruption**: Backup data before migration, validate data integrity

### Timeline Risks
- **Scope Creep**: Focus on architecture first, features second
- **Integration Issues**: Test integration continuously throughout phases
- **Resource Constraints**: Prioritize core stability over advanced features

## Rollback Strategy

### Phase-Level Rollback
Each phase maintains the ability to revert to the previous state:
- Phase 1: Can revert to original script variable system
- Phase 2: Can disable enhanced UI, fall back to original display
- Phase 3: Can revert to original command/query processing
- Phase 4: Can restore old module structure

### Data Protection
- Automatic backups before each phase
- Data migration validation
- Ability to restore from any backup point
- No destructive changes without user confirmation

### Emergency Procedures
```bash
# Emergency rollback to pre-refactor state
cd /home/teej/pmc
unzip archives/pmc_backup_pre_refactor_*.zip
# System restored to original state
```

## Conclusion

This refactoring plan addresses PMC's deep architectural problems while preserving everything that makes it special. The result will be a system that is secure, maintainable, and extensible while retaining its CLI-first philosophy and sophisticated feature set.

The phased approach ensures that PMC remains functional throughout the refactoring process, with each phase delivering measurable improvements to stability and performance.