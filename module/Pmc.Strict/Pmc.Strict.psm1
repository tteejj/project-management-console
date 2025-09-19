# Pmc.Strict module - strict domain-action engine

# NOTE: Completions use plain strings; no PmcCompletionItem class is used anymore.

enum PmcCompletionMode {
    Domain      # Completing domain names (task, project, time)
    Action      # Completing actions (add, list, done)
    Arguments   # Completing arguments (@project, due:date, p1)
    FreeText    # No completions available
}

class PmcEditorState {
    [string] $Buffer = ""
    [int] $CursorPos = 0
    [bool] $InCompletion = $false
    [string] $OriginalBuffer = ""
    [string[]] $Completions = @()
    [int] $CompletionIndex = -1
    [PmcCompletionMode] $Mode = [PmcCompletionMode]::Domain
    [string] $CurrentToken = ""
    [int] $TokenStart = 0
    [int] $TokenEnd = 0

    # History and undo/redo
    [string[]] $History = @()
    [int] $HistoryIndex = -1
    [string[]] $UndoStack = @()
    [string[]] $RedoStack = @()
    [int] $MaxUndoItems = 50
    [int] $MaxHistoryItems = 100
}

# Dot-source internal components with debug tracing
Write-Host "Loading Pmc.Strict module..." -ForegroundColor Green

try {
    Write-Host "  Loading Types.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Types.ps1
    Write-Host "  ✓ Types.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Types.ps1 failed: $_" -ForegroundColor Red
    throw
}

# Ensure centralized state is available before any consumer
try {
    Write-Host "  Loading State.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/State.ps1
    Write-Host "  ✓ State.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ State.ps1 failed: $_" -ForegroundColor Red
    throw
}

# Config providers and helpers before Debug/Security which consult config
try {
    Write-Host "  Loading Config.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Config.ps1
    Write-Host "  ✓ Config.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Config.ps1 failed: $_" -ForegroundColor Red
    throw
}

# Now load Debug and Security modules (no auto-init inside files)
try {
    Write-Host "  Loading Debug.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Debug.ps1
    Write-Host "  ✓ Debug.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Debug.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Security.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Security.ps1
    Write-Host "  ✓ Security.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Security.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Storage.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Storage.ps1
    Write-Host "  ✓ Storage.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Storage.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading UI.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/UI.ps1
    Write-Host "  ✓ UI.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ UI.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Resolvers.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Resolvers.ps1
    Write-Host "  ✓ Resolvers.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Resolvers.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading CommandMap.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/CommandMap.ps1
    Write-Host "  ✓ CommandMap.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ CommandMap.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Schemas.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Schemas.ps1
    Write-Host "  ✓ Schemas.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Schemas.ps1 failed: $_" -ForegroundColor Red
    throw
}

## moved earlier

try {
    Write-Host "  Loading Execution.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Execution.ps1
    Write-Host "  ✓ Execution.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Execution.ps1 failed: $_" -ForegroundColor Red
    throw
}


try {
    Write-Host "  Loading Help.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Help.ps1
    Write-Host "  ✓ Help.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Help.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Interactive.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Interactive.ps1
    Write-Host "  ✓ Interactive.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Interactive.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Dependencies.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Dependencies.ps1
    Write-Host "  ✓ Dependencies.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Dependencies.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Focus.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Focus.ps1
    Write-Host "  ✓ Focus.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Focus.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading UndoRedo.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/UndoRedo.ps1
    Write-Host "  ✓ UndoRedo.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ UndoRedo.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Views.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Views.ps1
    Write-Host "  ✓ Views.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Views.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Aliases.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Aliases.ps1
    Write-Host "  ✓ Aliases.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Aliases.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Analytics.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Analytics.ps1
    Write-Host "  ✓ Analytics.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Analytics.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Theme.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Theme.ps1
    Write-Host "  ✓ Theme.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Theme.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Excel.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Excel.ps1
    Write-Host "  ✓ Excel.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Excel.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading ImportExport.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/ImportExport.ps1
    Write-Host "  ✓ ImportExport.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ ImportExport.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Shortcuts.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Shortcuts.ps1
    Write-Host "  ✓ Shortcuts.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Shortcuts.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Review.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Review.ps1
    Write-Host "  ✓ Review.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Review.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading HelpUI.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/HelpUI.ps1
    Write-Host "  ✓ HelpUI.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ HelpUI.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading TaskEditor.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/TaskEditor.ps1
    Write-Host "  ✓ TaskEditor.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ TaskEditor.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading ProjectWizard.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/ProjectWizard.ps1
    Write-Host "  ✓ ProjectWizard.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ ProjectWizard.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading PraxisVT.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/PraxisVT.ps1
    Write-Host "  ✓ PraxisVT.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ PraxisVT.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading PraxisStringBuilder.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/PraxisStringBuilder.ps1
    Write-Host "  ✓ PraxisStringBuilder.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ PraxisStringBuilder.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading FieldSchemas.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/FieldSchemas.ps1
    Write-Host "  ✓ FieldSchemas.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ FieldSchemas.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading QuerySpec.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/QuerySpec.ps1
    Write-Host "  ✓ QuerySpec.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ QuerySpec.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading Query.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/Query.ps1
    Write-Host "  ✓ Query.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Query.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading PraxisFrameRenderer.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/PraxisFrameRenderer.ps1
    Write-Host "  ✓ PraxisFrameRenderer.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ PraxisFrameRenderer.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading DataDisplay.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/DataDisplay.ps1
    Write-Host "  ✓ DataDisplay.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ DataDisplay.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading UniversalDisplay.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/UniversalDisplay.ps1
    Write-Host "  ✓ UniversalDisplay.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ UniversalDisplay.ps1 failed: $_" -ForegroundColor Red
    throw
}

Write-Host "Pmc.Strict module loaded successfully!" -ForegroundColor Green

# Register universal command shortcuts so single-word routes map to the grid views
Write-Host "  Registering universal command shortcuts..." -ForegroundColor Gray
Register-PmcUniversalCommands
Write-Host "  ✓ Universal shortcuts registered" -ForegroundColor Green

# Ensure required public functions are exported (override narrow exports in sub-files)
Export-ModuleMember -Function `
    Invoke-PmcCommand, `
    Get-PmcSchema, `
    Get-PmcFieldSchema, Get-PmcFieldSchemasForDomain, `
    Invoke-PmcQuery, `
    Get-PmcHelp, `
    Set-PmcConfigProvider, `
    Ensure-PmcUniversalDisplay, `
    Write-PmcDebug, `
    Get-PmcDebugStatus, `
    Show-PmcDebugLog, `
    Measure-PmcOperation, `
    Initialize-PmcDebugSystem, `
    Initialize-PmcSecuritySystem, `
    Initialize-PmcThemeSystem, `
    Write-PmcStyled, Show-PmcHeader, Show-PmcSeparator, Show-PmcTable, `
    Test-PmcInputSafety, `
    Test-PmcPathSafety, `
    Invoke-PmcSecureFileOperation, `
    Protect-PmcUserInput, `
    Get-PmcSecurityStatus, `
    Set-PmcSecurityLevel, `
    Enable-PmcInteractiveMode, `
    Disable-PmcInteractiveMode, `
    Get-PmcInteractiveStatus, `
    Show-PmcSmartHelp, `
    Show-PmcHelpDomain, `
    Show-PmcHelpCommand, `
    Show-PmcHelpUI, `
    Show-PmcCommandBrowser, `
    Show-PmcHelpExamples, `
    Show-PmcHelpGuide, `
    Invoke-PmcTaskEditor, `
    Invoke-PmcProjectWizard, `
    Show-PmcAgenda, `
    Show-PmcTodayTasks, `
    Show-PmcOverdueTasks, `
    Show-PmcUpcomingTasks, `
    Show-PmcBlockedTasks, `
    Show-PmcTasksWithoutDueDate, `
    Show-PmcProjectsView, `
    Show-PmcDataGrid, Show-PmcCustomGrid, `
    Show-PmcData
try {
    Write-Host "  Loading ComputedFields.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/ComputedFields.ps1
    Write-Host "  ✓ ComputedFields.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ ComputedFields.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading QueryEvaluator.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/QueryEvaluator.ps1
    Write-Host "  ✓ QueryEvaluator.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ QueryEvaluator.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    Write-Host "  Loading KanbanRenderer.ps1..." -ForegroundColor Gray
    . $PSScriptRoot/src/KanbanRenderer.ps1
    Write-Host "  ✓ KanbanRenderer.ps1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  ✗ KanbanRenderer.ps1 failed: $_" -ForegroundColor Red
    throw
}
